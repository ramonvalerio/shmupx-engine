-- license:GPL-2.0-or-later
-- ShmupX: contador do modo Caravan, desenhado pelo próprio motor por cima do jogo.
--
-- Com SHMUPX_CARAVAN_SEGUNDOS (o Client passa na partida Caravan), mostra no canto superior direito
-- da janela um contador regressivo no estilo dos placares de arcade (TIME 04'59"83, TIME no ciano do ShmupX), com as imagens
-- de caravana/*.png (fonte do ShmupX Client; tools/caravana_glifos.py). Conta o tempo emulado a
-- partir do início da partida (run_start; jogo sem mapa de memória: do primeiro quadro), então não
-- corre com o jogo pausado nem sofre com engasgos do PC. No zero, fecha o jogo: o placar feito até
-- ali vale (a telemetria registra o fim como abort, com a velocidade da partida).
--
--   SHMUPX {"ev":"caravan_end","frame":18001,"seconds":300}   o tempo do Caravan acabou
--
-- Custo: algumas texturas carregadas uma vez e ~10 quads por quadro na camada de interface do MAME,
-- a mesma dos menus (sem janela por cima do jogo, sem cópia de imagem).
return function(path, emit)
	local total = tonumber(os.getenv('SHMUPX_CARAVAN_SEGUNDOS') or '')
	if not total or total <= 0 then return nil end

	local caravana = { total = total }
	local textures = nil -- caractere -> { tex, bitmap, w, h }
	local started_at, finished = nil, false

	-- Tamanho na tela: dígito com 5,5% da altura da janela (mínimo 22 px), colados como no arcade.
	local DIGIT_HEIGHT, MIN_DIGIT_PX, MARGIN, ADVANCE = 0.055, 22, 0.02, 0.82
	local WARN_SECONDS = 10
	local WHITE, RED = 0xffffffff, 0xffff4a52

	local function load_textures()
		local render = manager.machine.render
		local loaded = {}
		local files = { ["'"] = 'minutos', ['"'] = 'segundos', time = 'time' }
		for d = 0, 9 do files[tostring(d)] = tostring(d) end
		for char, name in pairs(files) do
			local file = io.open(path .. '/caravana/' .. name .. '.png', 'rb')
			if not file then
				emu.print_error('shmupx: caravana/' .. name .. '.png não encontrado')
				return nil
			end
			local data = file:read('a')
			file:close()
			local ok, bitmap = pcall(emu.bitmap_argb32.load, data)
			if not ok then
				emu.print_error('shmupx: caravana/' .. name .. '.png inválido')
				return nil
			end
			loaded[char] = { tex = render:texture_alloc(bitmap), bitmap = bitmap, w = bitmap.width, h = bitmap.height }
		end
		return loaded
	end

	local function remaining()
		if finished then return 0 end
		if not started_at then return total end
		return math.max(0, total - (emu.time() - started_at))
	end

	-- 299.83 -> 04'59"83
	local function text(seconds)
		local cs = math.floor(seconds * 100 + 0.5)
		return string.format("%02d'%02d\"%02d", cs // 6000, (cs // 100) % 60, cs % 100)
	end

	function caravana.reset()
		started_at, finished = nil, false
		if not textures then textures = load_textures() end
	end

	-- A partida começou: o tempo começa a correr (uma vez por jogo aberto).
	function caravana.start()
		if not started_at and not finished then started_at = emu.time() end
	end

	-- A cada quadro: no fim do tempo, fecha o jogo (o placar feito até ali vale).
	function caravana.tick(frame)
		if finished or not started_at or remaining() > 0 then return end
		finished = true
		emit({ { 'ev', 'caravan_end' }, { 'frame', frame }, { 'seconds', total } })
		manager.machine:exit()
	end

	-- Desenho (emu.register_frame_done): canto superior direito da janela, na camada de interface.
	function caravana.draw()
		if not textures then return end
		local target = manager.machine.render.ui_target
		local container = manager.machine.render.ui_container
		local tw, th = target.width, target.height
		if tw <= 0 or th <= 0 then return end
		local left = remaining()
		local color = WHITE
		-- Últimos segundos: vermelho, piscando duas vezes por segundo.
		if left <= WARN_SECONDS and left > 0 and math.floor(left * 4) % 2 == 0 then color = RED end
		local digit_px = math.max(MIN_DIGIT_PX, th * DIGIT_HEIGHT)
		local scale = digit_px / textures['0'].h
		local chars = text(left)
		-- Largura total para alinhar à direita.
		local width = 0
		for i = 1, #chars do
			local g = textures[chars:sub(i, i)]
			width = width + g.w * scale * (i < #chars and ADVANCE or 1)
		end
		local label = textures.time
		local label_h = label.h * scale
		local x = tw * (1 - MARGIN) - width
		local y = th * MARGIN
		container:draw_quad(label.tex, x / tw, y / th, (x + label.w * scale) / tw, (y + label_h) / th, WHITE)
		y = y + label_h * 0.92
		for i = 1, #chars do
			local g = textures[chars:sub(i, i)]
			local w, h = g.w * scale, g.h * scale
			container:draw_quad(g.tex, x / tw, y / th, (x + w) / tw, (y + h) / th, color)
			x = x + w * ADVANCE
		end
	end

	return caravana
end
