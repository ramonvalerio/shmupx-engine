-- license:GPL-2.0-or-later
-- ShmupX: lê da memória do jogo, a cada quadro, os campos do mapa do jogo (plugins/shmupx/maps/<rom>.lua)
-- e manda ao Client só o que mudou, uma linha JSON por evento na saída padrão:
--
--   SHMUPX {"ev":"start","rom":"sonicwi2","map":"ok","frame":0}     jogo carregado
--   SHMUPX {"ev":"run_start","frame":1328}                         partida começou
--   SHMUPX {"ev":"field","name":"score","value":12340,"frame":5120}  campo mudou (só durante a run)
--   SHMUPX {"ev":"gameover","frame":7566,"speed":100.002}           fim da run (velocidade média, %)
--   SHMUPX {"ev":"abort","frame":9000,"speed":99.998}              partida sumiu sem game over
--
-- O evento start traz "ranked": true quando o motor roda com -shmupx_ranked (opções travadas).
--
-- Custo por quadro: algumas leituras de memória e comparações, sem alocação quando nada muda.
local exports = {
	name = 'shmupx',
	version = '0.1.0',
	description = 'ShmupX telemetry',
	license = 'GPL-2.0-or-later',
	author = { name = 'ShmupX' } }

local shmupx = exports

local frame_subscription, reset_subscription, stop_subscription

function shmupx.set_folder(path)
	shmupx.path = path
end

local function emit(fields)
	local parts = {}
	for _, kv in ipairs(fields) do
		local k, v = kv[1], kv[2]
		if type(v) == 'string' then
			v = '"' .. v:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
		elseif type(v) == 'boolean' then
			v = v and 'true' or 'false'
		elseif math.type(v) == 'float' then
			v = string.format('%.3f', v)
		else
			v = tostring(v)
		end
		parts[#parts + 1] = '"' .. k .. '":' .. v
	end
	io.stdout:write('SHMUPX {' .. table.concat(parts, ',') .. '}\n')
	io.stdout:flush()
end

-- Leitores por tipo: inteiros na ordem da CPU (o MAME já cuida do endian) e BCD (placar de arcade).
local function bcd(value, digits)
	local out, mult = 0, 1
	for _ = 1, digits do
		out = out + (value & 0xf) * mult
		value = value >> 4
		mult = mult * 10
	end
	return out
end

local readers = {
	u8 = function(space, addr) return space:read_u8(addr) end,
	s8 = function(space, addr) local v = space:read_u8(addr); return v >= 128 and v - 256 or v end,
	u16 = function(space, addr) return space:read_u16(addr) end,
	u32 = function(space, addr) return space:read_u32(addr) end,
	bcd8 = function(space, addr) return bcd(space:read_u8(addr), 2) end,
	bcd16 = function(space, addr) return bcd(space:read_u16(addr), 4) end,
	bcd32 = function(space, addr) return bcd(space:read_u32(addr), 8) end,
}

local function load_map(rom)
	local file = shmupx.path .. '/maps/' .. rom .. '.lua'
	local chunk = loadfile(file)
	if not chunk then return nil end
	local ok, map = pcall(chunk)
	if not ok or type(map) ~= 'table' then
		emu.print_error('shmupx: mapa inválido para ' .. rom)
		return nil
	end
	-- extends = 'neogeo': campos comuns da placa (maps/_neogeo.lua); os do jogo têm prioridade.
	if map.extends then
		local base = load_map('_' .. map.extends)
		if base then
			for name, f in pairs(base.fields or {}) do
				map.fields = map.fields or {}
				if map.fields[name] == nil then map.fields[name] = f end
			end
			map.cpu = map.cpu or base.cpu
		end
	end
	return map
end

-- Monta a lista de campos já resolvida (espaço de memória e leitor), para o quadro só ler e comparar.
local function prepare(map)
	local fields = {}
	for name, f in pairs(map.fields or {}) do
		local cpu = manager.machine.devices[f.cpu or map.cpu or ':maincpu']
		local space = cpu and cpu.spaces[f.space or 'program']
		local read = readers[f.type or 'u8']
		if space and read then
			fields[#fields + 1] = {
				name = name, space = space, read = read, addr = f.addr,
				scale = f.scale or 1, offset = f.offset or 0, last = nil }
		else
			emu.print_error('shmupx: campo ' .. name .. ' sem CPU/espaço/tipo válido')
		end
	end
	return fields
end

-- Estado da run: começa quando o mapa diz que a partida começou (starts, ou playing), segue enquanto
-- playing for verdadeiro e termina no game over (gameover) ou
-- quando a partida some sem game over (abort: reset, volta ao título). Fora de uma run (boot, título,
-- demonstração automática) nada é enviado, só lido.
function shmupx.startplugin()
	local fields, starts, playing, gameover, frame, running = nil, nil, nil, nil, 0, false
	-- starts precisa valer por start_frames quadros seguidos (descarta valores de transição de tela)
	local start_frames, start_count = 1, 0
	local values = {} -- reaproveitada a cada quadro

	-- Velocidade média da run: tempo emulado / tempo real (100 = velocidade original da placa).
	local run_emu, run_ticks = 0, 0
	local function run_speed()
		local real = (emu.osd_ticks() - run_ticks) / emu.osd_ticks_per_second()
		if real <= 0 then return 0.0 end
		return (emu.time() - run_emu) / real * 100.0
	end

	local function ranked()
		local entry = manager.options.entries['shmupx_ranked']
		return entry ~= nil and entry:value() == true
	end

	local function send_field(f, v)
		emit({ { 'ev', 'field' }, { 'name', f.name }, { 'value', v }, { 'frame', frame } })
	end

	reset_subscription = emu.add_machine_reset_notifier(function ()
		frame, running, start_count = 0, false, 0
		local rom = emu.romname()
		local map = load_map(rom)
		fields = map and prepare(map) or nil
		playing = map and map.playing or nil
		starts = map and (map.starts or map.playing) or nil
		start_frames, start_count = map and map.start_frames or 1, 0
		gameover = map and map.gameover or nil
		emit({ { 'ev', 'start' }, { 'rom', rom }, { 'map', map and 'ok' or 'missing' }, { 'ranked', ranked() }, { 'frame', frame } })
	end)

	frame_subscription = emu.add_machine_frame_notifier(function ()
		frame = frame + 1
		if not fields then return end
		for i = 1, #fields do
			local f = fields[i]
			values[f.name] = f.read(f.space, f.addr) * f.scale + f.offset
		end

		if running then
			for i = 1, #fields do
				local f = fields[i]
				local v = values[f.name]
				if v ~= f.last then
					f.last = v
					send_field(f, v)
				end
			end
			if gameover and gameover(values) then
				running = false
				emit({ { 'ev', 'gameover' }, { 'frame', frame }, { 'speed', run_speed() } })
			elseif playing and not playing(values) then
				running = false
				emit({ { 'ev', 'abort' }, { 'frame', frame }, { 'speed', run_speed() } })
			end
		elseif (starts == nil) or starts(values) then
			start_count = start_count + 1
			if start_count < start_frames then return end
			running, start_count = true, 0
			run_emu, run_ticks = emu.time(), emu.osd_ticks()
			emit({ { 'ev', 'run_start' }, { 'frame', frame - start_frames + 1 } })
			for i = 1, #fields do
				local f = fields[i]
				f.last = values[f.name]
				send_field(f, f.last)
			end
		else
			start_count = 0
		end
	end)

	stop_subscription = emu.add_machine_stop_notifier(function ()
		if running then emit({ { 'ev', 'abort' }, { 'frame', frame }, { 'speed', run_speed() } }) end
		emit({ { 'ev', 'stop' }, { 'frame', frame } })
		fields, starts, playing, gameover, running = nil, nil, nil, nil, false
	end)
end

return exports
