-- license:GPL-2.0-or-later
-- Modo captura (Configurações › Controle no ShmupX Client): o Client abre o motor escondido, sem
-- jogo (sistema ___empty, -video none -background_input -keyboardprovider dinput) e com
-- SHMUPX_CAPTURA=1. Cada tecla, botão ou direção apertada sai como
--
--   SHMUPX {"ev":"input","code":"JOYCODE_1_BUTTON3","label":"Joy 1 Button 3","device":"<id>","device_name":"..."}
--
-- com o código exato do MAME (o Client grava no arquivo de controles, -ctrlr). "device" só vem em
-- controles (JOYCODE_n): o id do aparelho, para o arquivo prender o código a ele (mapdevice).
-- Ao soltar, sai SHMUPX {"ev":"release","code":"JOYCODE_1_BUTTON3"} (o Client anima o gabinete).
--
-- Lê teclas, botões, direcionais (HAT), START/SELECT e os eixos como botões: a alavanca principal
-- (X/Y) e também gatilhos e alavancas analógicas (Z, RX, RY, RZ, sliders), porque em muitos arcade
-- sticks e controles XInput os botões 7 e 8 são gatilhos (eixos).
--
-- Ruído: o que já está apertado quando a tela abre (gatilho que repousa no fim do curso, botão
-- segurado) só vale depois de soltar. O que liga e desliga mais rápido do que uma pessoa consegue
-- (adaptador com defeito, eixo oscilando) é ignorado até ficar 2 s quieto.
return function(emit)
	local input = manager.machine.input

	local watched = {} -- { code, token, device }
	local seen = {}
	local function watch(code, device)
		local token = input:code_to_token(code)
		if not token or token == '' or seen[token] then return end
		seen[token] = true
		watched[#watched + 1] = { code = code, token = token, device = device }
	end
	-- Código de um eixo como botão; só vale se o MAME conhecer o token (senão devolve outro código).
	local function watch_token(token, device)
		local code = input:code_from_token(token)
		if input:code_to_token(code) == token then watch(code, device) end
	end

	local keyboards = input.device_classes['keyboard']
	if keyboards then
		for _, dev in pairs(keyboards.devices) do
			for _, item in pairs(dev.items) do watch(item.code) end
		end
	end
	local joysticks = input.device_classes['joystick']
	if joysticks then
		for index, dev in pairs(joysticks.devices) do
			for _, item in pairs(dev.items) do
				local token = item.token
				local joy = string.format('JOYCODE_%d_%s', index, token)
				if token == 'XAXIS' then
					watch_token(joy .. '_LEFT_SWITCH', dev)
					watch_token(joy .. '_RIGHT_SWITCH', dev)
				elseif token == 'YAXIS' then
					watch_token(joy .. '_UP_SWITCH', dev)
					watch_token(joy .. '_DOWN_SWITCH', dev)
				elseif token:match('AXIS') or token:match('^SLIDER') then
					-- gatilhos e alavancas analógicas, nos dois sentidos
					watch_token(joy .. '_POS_SWITCH', dev)
					watch_token(joy .. '_NEG_SWITCH', dev)
				else
					-- botões, direcional (HAT) e START/SELECT
					watch(item.code, dev)
				end
			end
		end
	end

	local CALIBRATE = 1.5    -- segundos iniciais: o que já está apertado só vale depois de soltar
	local HOLD = 2           -- quadros seguidos apertado para valer
	local WINDOW = 20        -- janela (quadros) para contar trocas
	local NOISY = 12         -- trocas na janela para ser ruído (~18 apertos por segundo: ninguém aperta assim)
	local QUIET = 120        -- quadros sem trocar para o ruído voltar a valer
	local frame = 0
	local started = emu.osd_ticks()
	local per_second = emu.osd_ticks_per_second()
	local calibrating = true
	-- pressed: lido agora; held: quadros seguidos apertado; sent: o aperto já saiu (ou não deve sair
	-- até soltar); down: saiu "input" e ainda não saiu "release"; changes: quadros das trocas recentes
	local state = {}
	for _, w in ipairs(watched) do
		state[w.token] = { pressed = false, held = 0, sent = false, down = false, ignored = false, last_change = 0, changes = {} }
	end

	return emu.add_machine_frame_notifier(function ()
		frame = frame + 1
		if calibrating and (emu.osd_ticks() - started) / per_second >= CALIBRATE then
			calibrating = false
			emit({ { 'ev', 'capture_ready' } })
		end
		for i = 1, #watched do
			local w = watched[i]
			local s = state[w.token]
			local pressed = input:code_pressed(w.code)
			if pressed ~= s.pressed then
				s.pressed = pressed
				s.last_change = frame
				local changes = s.changes
				changes[#changes + 1] = frame
				while changes[1] and changes[1] <= frame - WINDOW do table.remove(changes, 1) end
				if #changes >= NOISY then s.ignored = true end
				if not pressed then
					s.held, s.sent = 0, false
					if s.down then
						s.down = false
						emit({ { 'ev', 'release' }, { 'code', w.token } })
					end
				end
			elseif s.ignored and frame - s.last_change >= QUIET then
				s.ignored, s.changes = false, {}
			end
			-- já apertado ao abrir a tela: espera soltar
			if pressed and calibrating then s.sent = true end
			if pressed and not s.ignored and not s.sent then
				s.held = s.held + 1
				if s.held >= HOLD then
					s.sent, s.down = true, true
					local fields = { { 'ev', 'input' }, { 'code', w.token }, { 'label', input:code_name(w.code) } }
					if w.device then
						fields[#fields + 1] = { 'device', w.device.id }
						fields[#fields + 1] = { 'device_name', w.device.name }
					end
					emit(fields)
				end
			end
		end
	end)
end
