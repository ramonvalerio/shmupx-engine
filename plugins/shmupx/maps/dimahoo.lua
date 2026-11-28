-- Dimahoo (Eighting/Raizing, CPS2). Endereços achados com partidas automáticas no ShmupX Engine e
-- conferidos com a tela (placar 800, 1400 ... 10700) e com as trocas de fase. O jogo guarda o estado
-- da partida em 0x928000 (memória de vídeo da CPS2 usada como RAM), não em 0xff0000.
return {
	cpu = ":maincpu",
	fields = {
		-- Placar do jogador 1: inteiro de 32 bits, como aparece na tela.
		score = { addr = 0x92804a, type = "u32" },
		-- Naves de reserva: 2 no começo, desce a cada morte; 0 com a última nave em jogo.
		lives = { addr = 0x92804e, type = "s8" },
		-- Estado do jogo: 3 escolha do personagem, 5 em partida (até o fim da tela de game over),
		-- 6 demonstração, 0xac título.
		mode = { addr = 0x928041, type = "u8" },
		-- Jogador 1 em jogo: 1 de apertar start até a última nave cair, 0 depois.
		p1 = { addr = 0x928049, type = "u8" },
	},
	-- Começo da run: em partida com o jogador 1 em jogo.
	starts = function(v) return v.mode == 5 and v.p1 == 1 end,
	start_frames = 10,
	-- Run segue enquanto o jogo estiver em partida (morte e troca de fase não mudam o estado).
	playing = function(v) return v.mode == 5 end,
	-- Fim da run: a última nave caiu (o jogador 1 sai de jogo e vem o GAME OVER).
	gameover = function(v) return v.mode == 5 and v.p1 == 0 end,
}
