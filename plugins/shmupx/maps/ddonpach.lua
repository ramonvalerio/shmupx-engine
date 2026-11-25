-- DoDonPachi (Cave, ddonpach). Endereços achados com partidas automáticas no ShmupX Engine e conferidos
-- com a tela (placar, naves e tela de continue), em várias partidas seguidas.
return {
	cpu = ":maincpu",
	fields = {
		-- Placar do jogador 1: 4 bytes BCD sem o último dígito (00 02 66 69 = 26690). Na tela, o último
		-- dígito conta os continues; no ranked não há continue, então é sempre 0.
		score = { addr = 0x10161e, type = "bcd32", scale = 10 },
		-- Naves: 3 no começo, desce a cada morte; 0 quando a última cai (tela de continue).
		lives = { addr = 0x101965, type = "u8" },
		-- Estado do jogador 1: 0x80 em partida (inclusive na escolha da nave), 0 no título e no continue.
		state = { addr = 0x100082, type = "u8" },
	},
	-- Começo da run: em partida com as naves já postas (na escolha da nave, o contador ainda está em 1).
	starts = function(v) return v.state == 0x80 and v.lives >= 2 end,
	start_frames = 10,
	-- Run segue enquanto o jogador 1 estiver em partida (troca de fase não muda o estado).
	playing = function(v) return v.state == 0x80 end,
	-- Fim da run: a última nave caiu (sem ficha no ranked, não há continue).
	gameover = function(v) return v.lives == 0 end,
}
