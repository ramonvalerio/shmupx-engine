-- Ketsui: Kizuna Jigoku Tachi (PGM, ket). Endereços achados com partidas automáticas no ShmupX Engine e
-- conferidos com a tela (placar e naves), inclusive nas trocas de fase.
return {
	cpu = ":maincpu",
	fields = {
		-- Placar do jogador 1: inteiro de 32 bits, como aparece na tela.
		score = { addr = 0x81a63e, type = "u32" },
		-- Naves de reserva: 2 no começo, desce a cada morte; -1 quando a última nave cai.
		lives = { addr = 0x812473, type = "s8" },
		-- Modo do jogo: 2 em partida (da escolha de nave até o game over), 8 no título, na demonstração
		-- e no game over. No meio da partida passa um tempo em 1 (o jogo continua).
		mode = { addr = 0x80101b, type = "u8" },
		-- Fim do jogo: 0x20 em partida, 0xff do fim do chefe final até o texto do final. O game over
		-- não muda (o modo vai a 8 nos dois casos, por isso não serve).
		fim = { addr = 0x80108b, type = "u8" },
		-- Nave escolhida: 0 Type-A, 1 Type-B (esquerda/direita na tela de escolha).
		ship_type = { addr = 0x812402, type = "u8" },
	},
	-- Nave (tools/mapping/nave-dump.lua, conferida na tela).
	ship = function(v) return ({ [0] = 'Type-A', 'Type-B' })[v.ship_type] end,
	-- Começo da run: partida (não a demonstração) com as naves postas.
	starts = function(v) return v.mode == 2 and v.lives >= 0 end,
	start_frames = 10,
	-- Run segue enquanto o jogo estiver em partida (modo 2, ou 1 no trecho do meio da partida).
	playing = function(v) return v.mode == 2 or v.mode == 1 end,
	-- Fim da run: a última nave caiu (o modo só sai de 2 uns 2 s depois).
	gameover = function(v) return v.lives < 0 end,
	-- Zerou: o chefe final caiu e o final começou.
	cleared = function(v) return v.mode == 2 and v.fim == 0xff end,
}
