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
-- Ruído: nos primeiros segundos ninguém mexe no controle (a tela acabou de abrir); o que mudar
-- nesse tempo (eixo que oscila sozinho, adaptador com defeito) é ignorado na sessão. Depois, o
-- que liga e desliga rápido demais também passa a ser ignorado.
return function(emit)
	local input = manager.machine.input

	local watched = {} -- { code, token, device }
	local seen = {}
	local function watch(code, device)
		local token = input:code_to_token(code)
		if seen[token] then return end
		seen[token] = true
		watched[#watched + 1] = { code = code, token = token, device = device }
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
				if token == 'XAXIS' then
					watch(input:code_from_token(string.format('JOYCODE_%d_XAXIS_LEFT_SWITCH', index)), dev)
					watch(input:code_from_token(string.format('JOYCODE_%d_XAXIS_RIGHT_SWITCH', index)), dev)
				elseif token == 'YAXIS' then
					watch(input:code_from_token(string.format('JOYCODE_%d_YAXIS_UP_SWITCH', index)), dev)
					watch(input:code_from_token(string.format('JOYCODE_%d_YAXIS_DOWN_SWITCH', index)), dev)
				elseif not token:match('AXIS') then
					-- botões, direcional (HAT) e START/SELECT; gatilhos e alavancas analógicas ficam de fora
					watch(item.code, dev)
				end
			end
		end
	end

	local CALIBRATE = 2.5    -- segundos iniciais: o que mudar aqui é ruído
	local HOLD = 2           -- quadros seguidos apertado para valer
	local WINDOW = 60        -- janela para contar trocas (ruído)
	local NOISY = 4          -- trocas na janela para considerar ruído
	local frame = 0
	local started = emu.osd_ticks()
	local per_second = emu.osd_ticks_per_second()
	local calibrating = true
	local noisy_devices = {}
	local state = {}         -- token -> { pressed, held, ignored, sent, changes = { frames } }
	-- down: o aperto saiu como "input" e ainda não saiu o "release"
	for _, w in ipairs(watched) do state[w.token] = { pressed = false, held = 0, ignored = false, sent = false, down = false, changes = {} } end

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
				local changes = s.changes
				changes[#changes + 1] = frame
				while changes[1] and changes[1] < frame - WINDOW do table.remove(changes, 1) end
				if #changes >= NOISY then s.ignored = true end
				if not pressed then
					s.held, s.sent = 0, false
					if s.down then
						s.down = false
						emit({ { 'ev', 'release' }, { 'code', w.token } })
					end
				end
			end
			if pressed and calibrating then
				-- controle mexendo sozinho na abertura: o aparelho inteiro é ruído na sessão; tecla: só até soltar
				if w.device then noisy_devices[w.device.id] = true else s.sent = true end
			end
			if pressed and not s.ignored and not s.sent and not (w.device and noisy_devices[w.device.id]) then
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
