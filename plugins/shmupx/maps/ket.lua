-- Ketsui: Kizuna Jigoku Tachi (PGM, ket). Endereços achados com partidas automáticas no ShmupX Engine e
-- conferidos com a tela (placar e naves), inclusive nas trocas de fase.
return {
	cpu = ":maincpu",
	fields = {
		-- Placar do jogador 1: inteiro de 32 bits, como aparece na tela.
		score = { addr = 0x81a63e, type = "u32" },
		-- Naves de reserva: 2 no começo, desce a cada morte; -1 quando a última nave cai.
		lives = { addr = 0x812473, type = "s8" },
		-- Modo do jogo: 2 em partida (da escolha de nave até o game over), 8 no título e na demonstração.
		mode = { addr = 0x80101b, type = "u8" },
	},
	-- Começo da run: partida (não a demonstração) com as naves postas.
	starts = function(v) return v.mode == 2 and v.lives >= 0 end,
	start_frames = 10,
	-- Run segue enquanto o jogo estiver em partida (troca de fase não muda o modo).
	playing = function(v) return v.mode == 2 end,
	-- Fim da run: a última nave caiu (o modo só sai de 2 uns 2 s depois).
	gameover = function(v) return v.lives < 0 end,
}
