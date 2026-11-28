-- DoDonPachi Dai-Ou-Jou (Cave/AMI, PGM, ddp3). Endereços achados com partidas automáticas no ShmupX
-- Engine e conferidos com a tela (placar 16880 ... 251770) e com as trocas de fase (vidas infinitas).
return {
	cpu = ":maincpu",
	fields = {
		-- Placar do jogador 1: 4 bytes BCD sem o 0 final da tela (00 00 16 88 = 1688 → 16880); até
		-- 999.999.990, os 9 dígitos do placar na tela.
		score = { addr = 0x81b436, type = "bcd32", scale = 10 },
		-- Naves de reserva: 2 no começo, desce a cada morte; -1 quando a última cai (vem o CONTINUE?).
		-- Fora da partida fica em -1 (também 2 na demonstração).
		lives = { addr = 0x813271, type = "s8" },
		-- Quem joga: 0x11 o jogador (de apertar start até o fim da tela de game over), 0x10 a
		-- demonstração, 0 título e boot.
		mode = { addr = 0x8132bc, type = "u8" },
	},
	-- Começo da run: o jogador em partida com as naves postas.
	starts = function(v) return v.mode == 0x11 and v.lives >= 0 end,
	start_frames = 10,
	-- Run segue enquanto o jogador estiver em partida (morte e troca de fase não mudam).
	playing = function(v) return v.mode == 0x11 end,
	-- Fim da run: a última nave caiu (sem ficha no ranked, não há continue).
	gameover = function(v) return v.mode == 0x11 and v.lives < 0 end,
}
