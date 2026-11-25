-- Carrier Air Wing (CPS1, cawing). Endereços achados com partidas automáticas no ShmupX Engine e
-- conferidos com a tela (placar, tela de continue e título), inclusive na troca de fase.
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
	},
	-- Começo da run: jogador 1 em partida.
	starts = function(v) return v.p1 == 2 end,
	start_frames = 10,
	-- Run segue enquanto o jogador 1 estiver em partida (o jogo tem barra de combustível, não naves).
	playing = function(v) return v.p1 == 2 or v.fase == 0x18 end,
	-- Fim da run: o avião caiu e a tela de continue apareceu (sem ficha no ranked, não há continue).
	gameover = function(v) return v.cont == 2 end,
}
