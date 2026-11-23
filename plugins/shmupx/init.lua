-- license:GPL-2.0-or-later
-- ShmupX: lê da memória do jogo, a cada quadro, os campos do mapa do jogo (plugins/shmupx/maps/<rom>.lua)
-- e manda ao Client só o que mudou, uma linha JSON por evento na saída padrão:
--
--   SHMUPX {"ev":"start","rom":"sonicwi2","frame":0}
--   SHMUPX {"ev":"field","name":"score","value":12340,"frame":5120}
--   SHMUPX {"ev":"gameover","frame":90210}
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

function shmupx.startplugin()
	local fields, gameover, frame, over = nil, nil, 0, false
	local values = {} -- reaproveitada a cada quadro

	reset_subscription = emu.add_machine_reset_notifier(function ()
		frame, over = 0, false
		local rom = emu.romname()
		local map = load_map(rom)
		fields = map and prepare(map) or nil
		gameover = map and map.gameover or nil
		emit({ { 'ev', 'start' }, { 'rom', rom }, { 'map', map and 'ok' or 'missing' }, { 'frame', frame } })
	end)

	frame_subscription = emu.add_machine_frame_notifier(function ()
		frame = frame + 1
		if not fields then return end
		for i = 1, #fields do
			local f = fields[i]
			local v = f.read(f.space, f.addr) * f.scale + f.offset
			values[f.name] = v
			if v ~= f.last then
				f.last = v
				emit({ { 'ev', 'field' }, { 'name', f.name }, { 'value', v }, { 'frame', frame } })
			end
		end
		-- Game over: função do mapa sobre os valores do quadro (ex.: vidas = 0 e sem crédito).
		if gameover then
			local now = gameover(values) and true or false
			if now ~= over then
				over = now
				if over then emit({ { 'ev', 'gameover' }, { 'frame', frame } }) end
			end
		end
	end)

	stop_subscription = emu.add_machine_stop_notifier(function ()
		emit({ { 'ev', 'stop' }, { 'frame', frame } })
		fields, gameover = nil, nil
	end)
end

return exports
