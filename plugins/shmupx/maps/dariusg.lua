-- Darius Gaiden (Taito F3, dariusg). Endereços achados com partidas automáticas no ShmupX Engine e
-- conferidos com a tela (placar e naves de reserva), inclusive nas trocas de zona.
return {
	cpu = ":maincpu",
	fields = {
		-- Placar do jogador 1: inteiro de 32 bits (o 0 final da tela faz parte do valor).
		score = { addr = 0x41b1d8, type = "u32" },
		-- Naves de reserva: 2 no começo, desce a cada morte; -1 quando a última nave cai.
		lives = { addr = 0x41b1dd, type = "s8" },
		-- Modo do jogo: 3/0x20 título e demonstração, 5 com crédito, 9 em partida, 0x11/0x12 game over.
		mode = { addr = 0x400081, type = "u8" },
	},
	-- Começo da run: partida (não a demonstração) com as naves já postas (vidas >= 0).
	starts = function(v) return v.mode == 9 and v.lives >= 0 end,
	-- Descarta os quadros de transição ao apertar start.
	start_frames = 10,
	-- Run segue enquanto o jogo estiver em partida (troca de zona não muda o modo).
	playing = function(v) return v.mode == 9 end,
	-- Fim da run: a última nave caiu (o modo vai a 0x12 no mesmo quadro).
	gameover = function(v) return v.lives < 0 end,
}
