-- license:GPL-2.0-or-later
-- ShmupX: contador do modo Caravan, desenhado pelo próprio motor por cima do jogo.
--
-- Com SHMUPX_CARAVAN_SEGUNDOS (o Client passa na partida Caravan), mostra no canto superior direito
-- da janela um contador regressivo no estilo dos placares de arcade (TIME 04'59"83: TIME no
-- vermelho e os números no ciano do ShmupX), com as imagens de caravana/*.png (fonte do ShmupX
-- Client; tools/caravana_glifos.py). Conta o tempo emulado a partir do início da partida
-- (run_start; jogo sem mapa de memória: do primeiro quadro), então não corre com o jogo pausado nem
-- sofre com engasgos do PC.
--
-- No zero: registra o fim da partida na telemetria (abort, com a velocidade até ali: a pausa que
-- vem depois não entra na conta), pausa o jogo e mostra no meio da tela o cartão do jogador (avatar
-- e nick, PNG gerado pelo Client em SHMUPX_JOGADOR_CARTAO), TEMPO ESGOTADO, os pontos e as vidas
-- perdidas; RESULT_SECONDS depois, fecha o jogo. O placar feito até ali vale.
--
--   SHMUPX {"ev":"caravan_end","frame":18001,"seconds":300}   o tempo do Caravan acabou
--
-- Custo: algumas texturas carregadas uma vez e ~10 quads por quadro na camada de interface do MAME,
-- a mesma dos menus (sem janela por cima do jogo, sem cópia de imagem).
--
-- hooks.finish(frame): encerra a partida na telemetria; hooks.result(): pontos, vidas perdidas
-- (nil quando o jogo não tem o campo no mapa de memória).
return function(path, emit, hooks)
	local total = tonumber(os.getenv('SHMUPX_CARAVAN_SEGUNDOS') or '')
	if not total or total <= 0 then return nil end

	local caravana = { total = total }
	local textures = nil -- nome -> { tex, bitmap, w, h }
	local started_at, finished = nil, false
	local result, result_ticks, exiting = nil, nil, false

	-- Contador: dígito com 5,5% da altura da janela (mínimo 22 px), colados como no arcade.
	local DIGIT_HEIGHT, MIN_DIGIT_PX, MARGIN, ADVANCE = 0.055, 22, 0.02, 0.82
	-- Resultado: dígitos com 9% da altura da janela, no meio da tela.
	local RESULT_DIGIT_HEIGHT, RESULT_SECONDS = 0.09, 6
	local WARN_SECONDS = 10
	local WHITE, RED = 0xffffffff, 0xffff4a52
	local PANEL_BORDER, PANEL_FILL = 0xff57fcff, 0xe60b0d10

	local FILES = {
		["'"] = 'minutos', ['"'] = 'segundos', ['.'] = 'ponto', ['-'] = 'traco',
		time = 'time', tempo_esgotado = 'tempo_esgotado', pontos = 'pontos', vidas_perdidas = 'vidas_perdidas' }
	for d = 0, 9 do FILES[tostring(d)] = tostring(d) end

	local function load_png(file_path)
		local file = io.open(file_path, 'rb')
		if not file then return nil end
		local data = file:read('a')
		file:close()
		local ok, bitmap = pcall(emu.bitmap_argb32.load, data)
		if not ok then return nil end
		return { tex = manager.machine.render:texture_alloc(bitmap), bitmap = bitmap, w = bitmap.width, h = bitmap.height }
	end

	local function load_textures()
		local render = manager.machine.render
		local loaded = {}
		-- Cartão do jogador (opcional): sem ele, a tela final mostra só o resultado.
		local card_path = os.getenv('SHMUPX_JOGADOR_CARTAO')
		if card_path and card_path ~= '' then loaded.card = load_png(card_path) end
		for key, name in pairs(FILES) do
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
			loaded[key] = { tex = render:texture_alloc(bitmap), bitmap = bitmap, w = bitmap.width, h = bitmap.height }
		end
		return loaded
	end

	local function remaining()
		if finished then return 0 end
		if not started_at then return total end
		return math.max(0, total - (emu.time() - started_at))
	end

	-- 299.83 -> 04'59"83
	local function time_text(seconds)
		local cs = math.floor(seconds * 100 + 0.5)
		return string.format("%02d'%02d\"%02d", cs // 6000, (cs // 100) % 60, cs % 100)
	end

	-- 7517367 -> 7.517.367; sem valor -> -
	local function number_text(n)
		if n == nil then return '-' end
		local s = tostring(math.max(0, math.floor(n)))
		return (s:reverse():gsub('(%d%d%d)', '%1.'):reverse():gsub('^%.', ''))
	end

	-- Largura em px de uma linha de caracteres na escala dada.
	local function line_width(chars, scale)
		local width = 0
		for i = 1, #chars do
			width = width + textures[chars:sub(i, i)].w * scale * (i < #chars and ADVANCE or 1)
		end
		return width
	end

	-- Desenha uma linha de caracteres a partir de (x, y) em px; devolve a altura usada.
	local function draw_line(container, tw, th, chars, x, y, scale, color)
		local h = 0
		for i = 1, #chars do
			local g = textures[chars:sub(i, i)]
			local w, gh = g.w * scale, g.h * scale
			container:draw_quad(g.tex, x / tw, y / th, (x + w) / tw, (y + gh) / th, color)
			x = x + w * ADVANCE
			h = math.max(h, gh)
		end
		return h
	end

	local function draw_image(container, tw, th, key, x, y, scale)
		local g = textures[key]
		container:draw_quad(g.tex, x / tw, y / th, (x + g.w * scale) / tw, (y + g.h * scale) / th, WHITE)
		return g.w * scale, g.h * scale
	end

	function caravana.reset()
		started_at, finished, result, result_ticks, exiting = nil, false, nil, nil, false
		if not textures then textures = load_textures() end
	end

	-- A partida começou: o tempo começa a correr (uma vez por jogo aberto).
	function caravana.start()
		if not started_at and not finished then started_at = emu.time() end
	end

	-- A cada quadro: no fim do tempo, encerra a partida, pausa o jogo e mostra o resultado.
	function caravana.tick(frame)
		if finished or not started_at or remaining() > 0 then return end
		finished = true
		emit({ { 'ev', 'caravan_end' }, { 'frame', frame }, { 'seconds', total } })
		if hooks and hooks.finish then hooks.finish(frame) end
		local score, lives_lost = nil, nil
		if hooks and hooks.result then score, lives_lost = hooks.result() end
		result = { score = score, lives_lost = lives_lost }
		result_ticks = emu.osd_ticks()
		emu.pause()
	end

	-- Contador no canto superior direito.
	local function draw_counter(container, tw, th)
		local left = remaining()
		local color = WHITE
		-- Últimos segundos: vermelho, piscando duas vezes por segundo.
		if left <= WARN_SECONDS and left > 0 and math.floor(left * 4) % 2 == 0 then color = RED end
		local scale = math.max(MIN_DIGIT_PX, th * DIGIT_HEIGHT) / textures['0'].h
		local chars = time_text(left)
		local x = tw * (1 - MARGIN) - line_width(chars, scale)
		local y = th * MARGIN
		local _, label_h = draw_image(container, tw, th, 'time', x, y, scale)
		draw_line(container, tw, th, chars, x, y + label_h * 0.92, scale, color)
	end

	-- Resultado no meio da tela: TEMPO ESGOTADO, PONTOS e VIDAS PERDIDAS.
	local function draw_result(container, tw, th)
		local scale = math.max(MIN_DIGIT_PX * 1.5, th * RESULT_DIGIT_HEIGHT) / textures['0'].h
		local label_scale = scale * 0.8
		local score_text, lives_text = number_text(result.score), number_text(result.lives_lost)
		local gap = textures['0'].h * scale * 0.35
		local rows = {}
		if textures.card then
			-- Cartão com a altura de um dígito e meio do resultado, seguido de um espaço.
			rows[#rows + 1] = { kind = 'image', key = 'card', scale = textures['0'].h * scale * 1.1 / textures.card.h }
			rows[#rows + 1] = { kind = 'gap' }
		end
		for _, row in ipairs({
			{ kind = 'image', key = 'tempo_esgotado', scale = label_scale },
			{ kind = 'gap' },
			{ kind = 'image', key = 'pontos', scale = label_scale * 0.75 },
			{ kind = 'line', chars = score_text },
			{ kind = 'gap' },
			{ kind = 'image', key = 'vidas_perdidas', scale = label_scale * 0.75 },
			{ kind = 'line', chars = lives_text },
		}) do rows[#rows + 1] = row end
		local width, height = 0, 0
		for _, row in ipairs(rows) do
			if row.kind == 'image' then
				local g = textures[row.key]
				width = math.max(width, g.w * row.scale)
				height = height + g.h * row.scale
			elseif row.kind == 'line' then
				width = math.max(width, line_width(row.chars, scale))
				height = height + textures['0'].h * scale
			else
				height = height + gap
			end
		end
		local pad = gap
		local x1, y1 = (tw - width) / 2 - pad, (th - height) / 2 - pad
		local x2, y2 = (tw + width) / 2 + pad, (th + height) / 2 + pad
		container:draw_box(x1 / tw, y1 / th, x2 / tw, y2 / th, PANEL_BORDER, PANEL_FILL)
		local y = y1 + pad
		for _, row in ipairs(rows) do
			if row.kind == 'image' then
				local g = textures[row.key]
				local _, h = draw_image(container, tw, th, row.key, (tw - g.w * row.scale) / 2, y, row.scale)
				y = y + h
			elseif row.kind == 'line' then
				y = y + draw_line(container, tw, th, row.chars, (tw - line_width(row.chars, scale)) / 2, y, scale, WHITE)
			else
				y = y + gap
			end
		end
	end

	-- Desenho (emu.register_frame_done): continua com o jogo pausado.
	function caravana.draw()
		if not textures then return end
		local target = manager.machine.render.ui_target
		local container = manager.machine.render.ui_container
		local tw, th = target.width, target.height
		if tw <= 0 or th <= 0 then return end
		draw_counter(container, tw, th)
		if result then
			draw_result(container, tw, th)
			-- Depois de mostrar o resultado, fecha o jogo (o Client então valida a run).
			if not exiting and (emu.osd_ticks() - result_ticks) / emu.osd_ticks_per_second() >= RESULT_SECONDS then
				exiting = true
				manager.machine:exit()
			end
		end
	end

	return caravana
end
