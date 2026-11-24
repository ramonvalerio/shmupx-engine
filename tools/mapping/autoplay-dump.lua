-- Descoberta de endereços: joga sozinho (ficha, start, tiro, anda de um lado para o outro) e guarda a
-- RAM a cada 30 quadros (ram.bin + frames.txt) e a tela a cada `shot` quadros (shot_<quadro>_<l>x<a>.raw,
-- ARGB de 32 bits). A configuração da placa vem de SHMUPX_DISCOVER_CFG (ver games/*.lua):
--
--   coin/start/fire/left/right = { porta, campo }   controles (manager.machine.ioport.ports)
--   ram = { { de, até }, ... }                       faixas da RAM principal a guardar
--   times = { coin, start, play }                    quadros da ficha, do start e do começo do tiro
--   shot = 300                                       intervalo das telas
--   trace = { { endereço, "u8"|"u16"|"u32" }, ... }  registro quadro a quadro (trace.txt), quando mudam
--   god = { endereço, valor, from = quadro }         só na descoberta: escreve o valor a cada quadro
--                                                    (vidas infinitas, para ver as trocas de fase)
--   dips = { { porta, campo, ajuste }, ... }         só na descoberta: DIP switches (ex.: invencibilidade)
-- O MAME roda o autoboot de novo em cada reset da máquina: uma cópia só.
if SHMUPX_DISCOVER_SUB then return end
local cfg = dofile(os.getenv("SHMUPX_DISCOVER_CFG"))
local out_dir = os.getenv("SHMUPX_DISCOVER_OUT")
local total = tonumber(os.getenv("SHMUPX_DISCOVER_FRAMES") or "21600")
local ports = manager.machine.ioport.ports
local function field(spec)
	local p = ports[spec[1]]
	return p and p.fields[spec[2]] or error("sem campo " .. spec[1] .. " / " .. spec[2])
end
local coin, start, fire = field(cfg.coin), field(cfg.start), field(cfg.fire)
local left, right = field(cfg.left), field(cfg.right)
local space = manager.machine.devices[cfg.cpu or ":maincpu"].spaces["program"]
local ram = io.open(out_dir .. "/ram.bin", "wb")
local log = io.open(out_dir .. "/frames.txt", "w")
local trace = cfg.trace and io.open(out_dir .. "/trace.txt", "w")
local tlast = {}
local readers = { u8 = "read_u8", u16 = "read_u16", u32 = "read_u32" }
local t = cfg.times or { coin = 600, start = 800, play = 1300 }
local shot = cfg.shot or 300
local frame = 0

local function press(f, from, len)
	if frame == from then f:set_value(1) elseif frame == from + len then f:set_value(0) end
end

SHMUPX_DISCOVER_SUB = emu.add_machine_frame_notifier(function()
	frame = frame + 1
	if frame == 2 and cfg.dips then
		for _, dsw in ipairs(cfg.dips) do
			local f = field(dsw)
			for v, name in pairs(f.settings) do if name == dsw[3] then f.user_value = v end end
		end
	end
	press(coin, t.coin, 6)
	press(start, t.start, 6)
	-- toques no tiro depois do start: passam pelas telas de escolha (nave, piloto)
	for i = 0, 6 do press(fire, t.start + 200 + i * 100, 6) end
	if frame > t.play then
		fire:set_value((frame // 4) % 2)
		local phase = (frame // 120) % 4
		left:set_value(phase == 1 and 1 or 0)
		right:set_value(phase == 3 and 1 or 0)
	end
	if cfg.god and frame > (cfg.god.from or 0) then space:write_u8(cfg.god[1], cfg.god[2]) end
	if trace then
		local parts, changed = {}, false
		for i, tr in ipairs(cfg.trace) do
			local v = space[readers[tr[2] or "u8"]](space, tr[1])
			if v ~= tlast[i] then changed = true; tlast[i] = v end
			parts[#parts + 1] = string.format("%x", v)
		end
		if changed then trace:write(frame, " ", table.concat(parts, " "), "\n") end
	end
	if frame % 30 == 0 then
		for _, r in ipairs(cfg.ram) do ram:write(space:read_range(r[1], r[2], 8)) end
		log:write(frame, "\n")
	end
	if frame % shot == 0 then
		local scr = manager.machine.screens[cfg.screen or ":screen"]
		local f = io.open(out_dir .. "/shot_" .. frame .. "_" .. scr.width .. "x" .. scr.height .. ".raw", "wb")
		f:write(scr:pixels()); f:close()
	end
	if frame >= total then
		ram:close(); log:close(); if trace then trace:close() end
		manager.machine:exit()
	end
end)
