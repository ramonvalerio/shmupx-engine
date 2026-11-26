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
-- perdidas. O jogo NÃO fecha sozinho: fica pausado até o jogador parar (PARAR JOGO). O placar feito
-- até ali vale. A mesma tela (FIM DE JOGO) aparece no game over de qualquer partida ranked
-- (Hi-Score e Caravan), pelo show_result.
--
--   SHMUPX {"ev":"caravan_end","frame":18001,"seconds":300}   o tempo do Caravan acabou
--
-- Custo: algumas texturas carregadas uma vez e ~10 quads por quadro na camada de interface do MAME,
-- a mesma dos menus (sem janela por cima do jogo, sem cópia de imagem).
--
-- Posição no ranking: com SHMUPX_POSICAO_ARQUIVO (o Client), o painel reserva uma linha abaixo do
-- título e a preenche com a imagem (medalha no top 3 e "1º LUGAR") quando o Client grava o arquivo,
-- o que acontece depois que o servidor aceita a run (a janela fica aberta, então ela chega a tempo).
--
-- Painel (de cima para baixo), com espaços iguais entre os blocos: cartão do jogador, a posição (RANK N,
-- rótulo azul e número branco), GAME MODE (ciano) com o modo grande em branco (CARAVAN, HI-SCORE ou
-- HI-SCORE/1CC quando zerou o jogo), PONTOS e, só no Caravan, VIDAS PERDIDAS (no Caravan quem perde
-- menos vidas fica na frente).
--
-- hooks.finish(frame): encerra a partida na telemetria; hooks.result(): pontos, vidas perdidas
-- (nil quando o jogo não tem o campo no mapa de memória); hooks.is_ranked(): partida ranked.
-- Sem SHMUPX_CARAVAN_SEGUNDOS não há contador nem fim por tempo, só a tela de resultado.
return function(path, emit, hooks)
	local total = tonumber(os.getenv('SHMUPX_CARAVAN_SEGUNDOS') or '')
	if total and total <= 0 then total = nil end

	local caravana = { total = total }
	local textures = nil -- nome -> { tex, bitmap, w, h }
	local started_at, finished = nil, false
	local result = nil

	-- Contador: dígito com 5,5% da altura da janela (mínimo 22 px), colados como no arcade.
	local DIGIT_HEIGHT, MIN_DIGIT_PX, MARGIN, ADVANCE = 0.055, 22, 0.02, 0.82
	-- Resultado: dígitos com 9% da altura da janela, no meio da tela.
	local RESULT_DIGIT_HEIGHT = 0.09
	local WARN_SECONDS = 10
	local WHITE, RED = 0xffffffff, 0xffff4a52
	-- Painel sem borda (borda transparente), com os tech elements da interface nos cantos superior
	-- direito e inferior esquerdo, como o painel DETALHES DO REGISTRO do Client.
	local PANEL_BORDER, PANEL_FILL = 0x00000000, 0xe60b0d10
	local CORNER_WIDTH = 0.5 -- largura dos cantos, como fração da largura do painel
	local CARD_HEIGHT = 1.7 -- altura do cartão (avatar e nick), em alturas de dígito do resultado
	local position_path = os.getenv('SHMUPX_POSICAO_ARQUIVO')
	if position_path == '' then position_path = nil end

	local FILES = {
		["'"] = 'minutos', ['"'] = 'segundos', ['.'] = 'ponto', ['-'] = 'traco',
		canto_superior_direito = 'canto_superior_direito', canto_inferior_esquerdo = 'canto_inferior_esquerdo',
		game_mode = 'game_mode', valor_caravan = 'valor_caravan', valor_hiscore = 'valor_hiscore', valor_hiscore_1cc = 'valor_hiscore_1cc',
		time = 'time', tempo_esgotado = 'tempo_esgotado', fim_de_jogo = 'fim_de_jogo', pontos = 'pontos', vidas_perdidas = 'vidas_perdidas' }
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
		if not total then return 0 end
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
		started_at, finished, result = nil, false, nil
		if textures then textures.position = nil end
		-- Imagens só com a tela de resultado ou o contador em uso (partida ranked ou Caravan).
		if not textures and (total or (hooks.is_ranked and hooks.is_ranked())) then textures = load_textures() end
	end

	-- A partida começou: o tempo começa a correr (uma vez por jogo aberto).
	function caravana.start()
		if not started_at and not finished then started_at = emu.time() end
	end

	-- A cada quadro: no fim do tempo, encerra a partida, pausa o jogo e mostra o resultado.
	function caravana.tick(frame)
		if not total or finished or not started_at or remaining() > 0 then return end
		finished = true
		emit({ { 'ev', 'caravan_end' }, { 'frame', frame }, { 'seconds', total } })
		if hooks and hooks.finish then hooks.finish(frame) end
		caravana.show_result('tempo_esgotado')
	end

	-- Pausa o jogo e mostra o resultado (title: tempo_esgotado ou fim_de_jogo). Não fecha o jogo.
	function caravana.show_result(title)
		if result or not textures then return end
		local score, lives_lost, cleared = nil, nil, false
		if hooks and hooks.result then score, lives_lost, cleared = hooks.result() end
		-- Modo: Caravan quando há tempo do Caravan; senão Hi-Score (e 1CC se zerou o jogo).
		local mode = total and 'valor_caravan' or (cleared and 'valor_hiscore_1cc' or 'valor_hiscore')
		result = { score = score, lives_lost = lives_lost, title = title, mode = mode }
		-- O Client encerra a run aqui (os dados já foram colhidos) e deixa a janela aberta.
		emit({ { 'ev', 'result' }, { 'title', title } })
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

	-- Resultado no meio da tela: cartão do jogador, FIM DE JOGO / TEMPO ESGOTADO, a posição no
	-- ranking, PONTOS e VIDAS PERDIDAS (rótulo azul, valor branco).
	local function draw_result(container, tw, th)
		local scale = math.max(MIN_DIGIT_PX * 1.5, th * RESULT_DIGIT_HEIGHT) / textures['0'].h
		local label_scale = scale * 0.8
		local digit_h = textures['0'].h * scale
		local score_text, lives_text = number_text(result.score), number_text(result.lives_lost)
		-- Blocos (RANK, GAME MODE, PONTOS e, no Caravan, VIDAS PERDIDAS) separados por espaços iguais.
		local gap = digit_h * 0.5
		local rows = {}
		if textures.card then
			rows[#rows + 1] = { kind = 'image', key = 'card', scale = digit_h * CARD_HEIGHT / textures.card.h }
			rows[#rows + 1] = { kind = 'gap' }
		end
		-- 1) Posição: a linha é reservada desde o começo (o painel não pula quando a imagem chega).
		if position_path then
			local pos_h = digit_h * 0.95
			if textures.position then
				rows[#rows + 1] = { kind = 'image', key = 'position', scale = pos_h / textures.position.h }
			else
				rows[#rows + 1] = { kind = 'space', height = pos_h }
			end
			rows[#rows + 1] = { kind = 'gap' }
		end
		-- 2) Modo da partida: rótulo em ciano e o valor grande em branco.
		rows[#rows + 1] = { kind = 'image', key = 'game_mode', scale = label_scale * 0.75 }
		rows[#rows + 1] = { kind = 'image', key = result.mode, scale = scale * 0.7 }
		rows[#rows + 1] = { kind = 'gap' }
		-- 3) Pontos.
		rows[#rows + 1] = { kind = 'image', key = 'pontos', scale = label_scale * 0.75 }
		rows[#rows + 1] = { kind = 'line', chars = score_text }
		-- 4) Vidas perdidas só no Caravan; no Hi-Score a informação não aparece.
		if result.mode == 'valor_caravan' then
			rows[#rows + 1] = { kind = 'gap' }
			rows[#rows + 1] = { kind = 'image', key = 'vidas_perdidas', scale = label_scale * 0.75 }
			rows[#rows + 1] = { kind = 'line', chars = lives_text }
		end

		local width, height = 0, 0
		for _, row in ipairs(rows) do
			if row.kind == 'image' then
				local g = textures[row.key]
				width = math.max(width, g.w * row.scale)
				height = height + g.h * row.scale
			elseif row.kind == 'line' then
				width = math.max(width, line_width(row.chars, scale))
				height = height + digit_h
			elseif row.kind == 'space' then
				height = height + row.height
			else
				height = height + gap
			end
		end
		local pad = gap * 1.4
		local x1, y1 = (tw - width) / 2 - pad, (th - height) / 2 - pad
		local x2, y2 = (tw + width) / 2 + pad, (th + height) / 2 + pad
		container:draw_box(x1 / tw, y1 / th, x2 / tw, y2 / th, PANEL_BORDER, PANEL_FILL)
		-- Cantos: superior direito e inferior esquerdo, na cor original das imagens.
		local corner_w = (x2 - x1) * CORNER_WIDTH
		local tr, bl = textures.canto_superior_direito, textures.canto_inferior_esquerdo
		container:draw_quad(tr.tex, (x2 - corner_w) / tw, y1 / th, x2 / tw, (y1 + corner_w * tr.h / tr.w) / th, WHITE)
		container:draw_quad(bl.tex, x1 / tw, (y2 - corner_w * bl.h / bl.w) / th, (x1 + corner_w) / tw, y2 / th, WHITE)

		local y = y1 + pad
		for _, row in ipairs(rows) do
			if row.kind == 'image' then
				local g = textures[row.key]
				local _, h = draw_image(container, tw, th, row.key, (tw - g.w * row.scale) / 2, y, row.scale)
				y = y + h
			elseif row.kind == 'line' then
				y = y + draw_line(container, tw, th, row.chars, (tw - line_width(row.chars, scale)) / 2, y, scale, WHITE)
			elseif row.kind == 'space' then
				y = y + row.height
			else
				y = y + gap
			end
		end
	end

	-- A posição no ranking chega depois (arquivo que o Client grava); olha de tempos em tempos.
	local position_check = 0
	local function poll_position()
		if not position_path or textures.position then return end
		position_check = position_check + 1
		if position_check % 20 ~= 1 then return end
		textures.position = load_png(position_path)
	end

	-- Desenho (emu.register_frame_done): continua com o jogo pausado.
	function caravana.draw()
		if not textures then return end
		local target = manager.machine.render.ui_target
		local container = manager.machine.render.ui_container
		local tw, th = target.width, target.height
		if tw <= 0 or th <= 0 then return end
		if total then draw_counter(container, tw, th) end
		if result then
			poll_position()
			draw_result(container, tw, th)
		end
	end

	return caravana
end
