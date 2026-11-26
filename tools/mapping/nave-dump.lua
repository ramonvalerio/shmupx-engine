-- Descoberta do endereço da nave/personagem: põe ficha, aperta start, faz os toques da variante na tela
-- de escolha (SHMUPX_VARIANT, ex.: "D,N,B2": baixo, nada, botão 2) e confirma com o tiro. Já em
-- partida, guarda a RAM quatro vezes (ram_1..4.bin) e uma tela (shot.raw). O endereço da nave é
-- o byte igual nas duas cópias da mesma variante e diferente entre variantes (find_nave.py compara).
-- A configuração da placa é a de games/<rom>.lua (a mesma do autoplay-dump.lua).
--
--   SHMUPX_DISCOVER_CFG=tools/mapping/games/<rom>.lua SHMUPX_DISCOVER_OUT=<pasta> SHMUPX_VARIANT=R,B2 \
--     shmupx-engine <rom> -rompath <roms> -video none -sound none -nothrottle -skip_gameinfo \
--     -nvram_directory <vazia> -cfg_directory <vazia> -autoboot_script tools/mapping/nave-dump.lua
if SHMUPX_NAVE_SUB then return end
local cfg = dofile(os.getenv("SHMUPX_DISCOVER_CFG"))
local out_dir = os.getenv("SHMUPX_DISCOVER_OUT")
local variant = os.getenv("SHMUPX_VARIANT") or ""
local ports = manager.machine.ioport.ports
local function field(spec)
	local p = ports[spec[1]]
	return p and p.fields[spec[2]] or error("sem campo " .. spec[1] .. " / " .. spec[2])
end
local coin, start, fire = field(cfg.coin), field(cfg.start), field(cfg.fire)
local pad = cfg.fire[1]
local keys = {
	L = field({ cfg.left[1], "P1 Left" }), R = field({ cfg.left[1], "P1 Right" }),
	U = field({ cfg.left[1], "P1 Up" }), D = field({ cfg.left[1], "P1 Down" }),
	B1 = fire,
}
-- Botões 2 e 3: só onde a placa tem (o nome do campo varia, ex.: Neo Geo).
for n = 2, 3 do
	local ok, f = pcall(field, { pad, "P1 Button " .. n })
	if ok then keys["B" .. n] = f end
end
local space = manager.machine.devices[cfg.cpu or ":maincpu"].spaces["program"]
local t = cfg.times or { coin = 600, start = 800, play = 1300 }
-- SHMUPX_STATE=1: parte do estado inicial ranked (states/<rom>/shmupx_ranked.sta, tela de start com 1
-- crédito, -state_directory states): sem ficha, start logo.
-- O estado é carregado pelo próprio script (com -state o autoboot não roda), no 5º quadro.
local from_state = os.getenv("SHMUPX_STATE") ~= nil
if from_state then t = { coin = -100, start = 70, play = 910 } end
local taps = {}
for token in variant:gmatch("[^,]+") do taps[#taps + 1] = token end
-- Toques da variante só com a tela de escolha já aberta (SHMUPX_TAP_AT: quadros depois do start).
local tap_from = t.start + tonumber(os.getenv("SHMUPX_TAP_AT") or "150")
local confirm_from = tap_from + #taps * 40 + 20
local frame = 0

local function press(f, from, len)
	if frame == from then f:set_value(1) elseif frame == from + len then f:set_value(0) end
end

local function dump(n)
	local f = io.open(out_dir .. "/ram_" .. n .. ".bin", "wb")
	for _, r in ipairs(cfg.ram) do f:write(space:read_range(r[1], r[2], 8)) end
	f:close()
end

SHMUPX_NAVE_SUB = emu.add_machine_frame_notifier(function()
	frame = frame + 1
	if from_state and frame == 5 then manager.machine:load("shmupx_ranked") end
	press(coin, t.coin, 6)
	press(start, t.start, 6)
	-- N: nenhum toque (as variantes ficam do mesmo tamanho e a confirmação cai no mesmo quadro)
	for i, token in ipairs(taps) do if keys[token] then press(keys[token], tap_from + (i - 1) * 40, 6) end end
	-- confirmar a escolha (nave, tipo) com o tiro, como o autoplay
	for i = 0, 8 do press(fire, confirm_from + i * 60, 6) end
	if frame > t.play then
		fire:set_value((frame // 4) % 2)
		local phase = (frame // 120) % 4
		keys.L:set_value(phase == 1 and 1 or 0)
		keys.R:set_value(phase == 3 and 1 or 0)
	end
	local every = tonumber(os.getenv("SHMUPX_SHOTS_EVERY") or "0")
	if every > 0 and frame >= t.start and frame <= t.play and frame % every == 0 then
		local scr = manager.machine.screens[cfg.screen or ":screen"]
		local f = io.open(out_dir .. "/seq" .. string.format("%05d", frame) .. "_" .. scr.width .. "x" .. scr.height .. ".raw", "wb")
		f:write(scr:pixels()); f:close()
	end
	if frame == tap_from - 1 or frame == confirm_from - 1 then
		local scr = manager.machine.screens[cfg.screen or ":screen"]
		local name = frame == tap_from - 1 and "sel" or "conf"
		local f = io.open(out_dir .. "/" .. name .. "_" .. scr.width .. "x" .. scr.height .. ".raw", "wb")
		f:write(scr:pixels()); f:close()
	end
	if frame == t.play + 400 then dump(1) end
	-- mais cópias em quadros ímpares/pares: descarta o que pisca (ex.: laser disparando)
	if frame == t.play + 401 then dump(3) end
	if frame == t.play + 553 then dump(4) end
	if frame == t.play + 700 then
		-- SHMUPX_KEEP=1: segue jogando depois das cópias (para ver um campo ao longo da partida)
		if os.getenv("SHMUPX_KEEP") then return end
		dump(2)
		local scr = manager.machine.screens[cfg.screen or ":screen"]
		local f = io.open(out_dir .. "/shot_" .. scr.width .. "x" .. scr.height .. ".raw", "wb")
		f:write(scr:pixels()); f:close()
		manager.machine:exit()
	end
end)
