-- Carrier Air Wing (CPS1, cawing). Endereços achados com partidas automáticas no ShmupX Engine e
-- conferidos com a tela (placar, tela de continue e título), inclusive na troca de fase.
-- Quadros seguidos fora da partida, na última fase, sem a tela de continue (ver cleared).
local fora = 0

return {
	cpu = ":maincpu",
	fields = {
		-- Placar do jogador 1: 4 bytes BCD (00 00 22 00 = 2200), como aparece na tela.
		score = { addr = 0xff83a8, type = "bcd32" },
		-- Jogador 1 em partida: 2 do start até o avião cair (0 no título e na tela de continue).
		p1 = { addr = 0xff8380, type = "u8" },
		-- Tela de continue: 2 com a contagem CONTINUE na tela (4 ao continuar, e o placar volta a 0).
		cont = { addr = 0xff8383, type = "u8" },
		-- Fase do jogo: 0x18 em partida, 0x0a na tela de continue, 0 no título. Quando o avião cai, p1
		-- zera um quadro antes de a tela de continue acender; a fase ainda está em 0x18 nesse quadro.
		fase = { addr = 0xff03f6, type = "u8" },
		-- Fase: 0 a 9 (são 10; a 9 é a última).
		stage = { addr = 0xff8501, type = "u8" },
	},
	-- Começo da run: jogador 1 em partida.
	starts = function(v) return v.p1 == 2 end,
	start_frames = 10,
	-- Run segue enquanto o jogador 1 estiver em partida (o jogo tem barra de combustível, não naves).
	playing = function(v) return v.p1 == 2 or v.fase == 0x18 end,
	-- Fim da run: o avião caiu e a tela de continue apareceu (sem ficha no ranked, não há continue).
	gameover = function(v) return v.cont == 2 end,
	-- Fase alcançada (coluna PROGRESSO): 0 a 9 na memória, Stage 1 a 10 na tela.
	progress = function(v) return v.stage <= 9 and v.stage + 1 or nil end,
	-- Zerou: na última fase, o jogador sai da partida (o final) e o continue não aparece. No game over
	-- o continue aparece 1 quadro depois; no final, só uns 40 s depois. Por isso vale 1 s seguido.
	cleared = function(v)
		if v.stage == 9 and v.p1 ~= 2 and v.cont == 0 then fora = fora + 1 else fora = 0 end
		return fora >= 60
	end,
}
