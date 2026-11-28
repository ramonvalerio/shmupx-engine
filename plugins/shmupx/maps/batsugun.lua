-- Batsugun (Toaplan, GP9001; mesma placa do Grind Stormer). Endereços achados com partidas automáticas
-- no ShmupX Engine e conferidos com a tela (placar 160, 680, 2580, 4040) e com as trocas de fase.
return {
	cpu = ":maincpu",
	fields = {
		-- Placar do jogador 1: 4 bytes BCD (00 00 40 40 = 4040). A demonstração também escreve aqui.
		score = { addr = 0x101096, type = "bcd32" },
		-- Naves do jogador 1, contando a que está em jogo: 3 no começo, 0 quando a última cai.
		lives = { addr = 0x10139b, type = "s8" },
		-- Estado do jogo: 1 título, 2 ranking, 4 com crédito, 5 demonstração, 7 em partida,
		-- 8 continue/game over, 11 escolha da nave.
		mode = { addr = 0x1011fd, type = "u8" },
	},
	-- Começo da run: em partida com as naves postas (a escolha da nave é o estado 11).
	starts = function(v) return v.mode == 7 and v.lives > 0 end,
	start_frames = 10,
	-- Run segue enquanto o jogo estiver em partida (morte e troca de fase não mudam o estado).
	playing = function(v) return v.mode == 7 end,
	-- Fim da run: a última nave caiu (o jogo passa ao continue/game over, estado 8).
	gameover = function(v) return v.lives <= 0 or v.mode == 8 end,
}
