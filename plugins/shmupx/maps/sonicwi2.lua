-- Aero Fighters 2 / Sonic Wings 2 (Neo Geo, sonicwi2). Endereços achados com partidas automáticas no
-- ShmupX Engine e conferidos com a tela (placar) e com o ranking do jogo (placar final).
return {
	extends = "neogeo",
	fields = {
		-- Placar do jogador 1: 4 bytes BCD (00 01 56 00 = 15600).
		score = { addr = 0x10e436, type = "bcd32" },
		-- Naves de reserva: 2 no começo, desce a cada morte; -1 quando a última nave cai
		-- (também -1 na escolha de nave, antes de a partida começar).
		lives = { addr = 0x10e43f, type = "s8" },
		-- Estado do jogo: 3 com a nave em jogo (2/16 na escolha de nave, 0/16 no continue).
		state = { addr = 0x10f20d, type = "u8" },
	},
	-- Começo da run: partida da BIOS (não a demonstração) com a nave em jogo.
	starts = function(v) return v.mode == 2 and v.state == 3 and v.lives >= 0 end,
	-- Ao apertar start, a BIOS entra em partida com o estado da demonstração ainda em 3 por alguns quadros.
	start_frames = 10,
	-- Run segue enquanto a BIOS estiver em partida (troca de fase não encerra).
	playing = function(v) return v.mode == 2 end,
	-- Fim da run: a última nave caiu (tela de continue).
	gameover = function(v) return v.mode == 2 and v.lives < 0 end,
}
