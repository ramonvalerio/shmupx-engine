-- Descoberta de endereços: joga sozinho (fichas, start, tiro) e guarda a RAM a cada 30 quadros.
local out_dir = os.getenv("SHMUPX_DISCOVER_OUT")
local total = tonumber(os.getenv("SHMUPX_DISCOVER_FRAMES") or "21600")
local ports = manager.machine.ioport.ports
local coin = ports[":AUDIO_COIN"].fields["Coin 1"]
local start = ports[":edge:joy:START"].fields["1 Player Start"]
local fire = ports[":edge:joy:JOY1"].fields["P1 A"]
local left = ports[":edge:joy:JOY1"].fields["P1 Left"]
local right = ports[":edge:joy:JOY1"].fields["P1 Right"]
local space = manager.machine.devices[":maincpu"].spaces["program"]
local ram = io.open(out_dir .. "/ram.bin", "wb")
local log = io.open(out_dir .. "/frames.txt", "w")
local frame = 0

local function press(field, from, len)
	if frame == from then field:set_value(1) elseif frame == from + len then field:set_value(0) end
end

-- a inscrição precisa ficar referenciada, senão o coletor de lixo a remove
SHMUPX_DISCOVER_SUB = emu.add_machine_frame_notifier(function()
	frame = frame + 1
	press(coin, 600, 6)
	press(coin, 700, 6)
	press(start, 800, 6)
	press(fire, 1000, 6)
	press(fire, 1100, 6)
	press(fire, 1200, 6)
	if frame > 1300 then
		fire:set_value((frame // 4) % 2)
		-- anda de um lado para o outro devagar
		local phase = (frame // 120) % 4
		left:set_value(phase == 1 and 1 or 0)
		right:set_value(phase == 3 and 1 or 0)
	end
	if frame % 30 == 0 then
		ram:write(space:read_range(0x100000, 0x10ffff, 8))
		log:write(frame, "\n")
	end
	if frame % 300 == 0 then
		local scr = manager.machine.screens[":screen"]
		local px, w, h = scr:pixels()
		local f = io.open(out_dir .. "/shot_" .. frame .. "_" .. w .. "x" .. h .. ".raw", "wb")
		f:write(px); f:close()
	end
	if frame >= total then
		ram:close(); log:close()
		manager.machine:exit()
	end
end)
