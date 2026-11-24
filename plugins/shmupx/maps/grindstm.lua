-- Grind Stormer (Toaplan, grindstm). Endereços achados com partidas automáticas no ShmupX Engine e
-- conferidos com a tela (placar), inclusive nas trocas de fase.
return {
	cpu = ":maincpu",
	fields = {
		-- Placar do jogador 1: 4 bytes BCD (00 00 37 60 = 3760).
		score = { addr = 0x100434, type = "bcd32" },
		-- Naves do jogador 1, contando a que está em jogo: 3 no começo, 0 quando a última cai.
		lives = { addr = 0x100641, type = "s8" },
		-- Estado do jogo: 1 título, 2 ranking, 4 com crédito e em partida, 5 demonstração, 7 game over.
		mode = { addr = 0x1005e3, type = "u8" },
	},
	-- Começo da run: partida (as naves só são postas ao apertar start; na demonstração o estado é 5).
	starts = function(v) return v.mode == 4 and v.lives > 0 end,
	start_frames = 10,
	-- Run segue enquanto o jogo estiver em partida (morte e troca de fase não mudam o estado).
	playing = function(v) return v.mode == 4 end,
	-- Fim da run: a última nave caiu.
	gameover = function(v) return v.mode == 4 and v.lives <= 0 end,
}
