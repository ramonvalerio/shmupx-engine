-- Zed Blade / Operation Ragnarok (Neo Geo, zedblade). Endereços achados com partidas automáticas no
-- ShmupX Engine e conferidos com a tela (placar) e com o ranking do jogo (placar final).
return {
	extends = "neogeo",
	fields = {
		-- Placar do jogador 1: 4 bytes BCD (00 00 84 50 = 8450).
		score = { addr = 0x10024c, type = "bcd32" },
		-- Naves do jogador 1, contando a que está em jogo: 3 no começo, 0 quando a última cai.
		lives = { addr = 0x100229, type = "s8" },
		-- Fase: 0 a 7 (são 8); vai a 8 quando a última é vencida ("CONGRATULATIONS").
		stage = { addr = 0x109021, type = "u8" },
	},
	-- Começo da run: partida da BIOS (não a demonstração) com as naves postas.
	starts = function(v) return v.mode == 2 and v.lives > 0 end,
	start_frames = 10,
	-- Run segue enquanto a BIOS estiver em partida (troca de fase não encerra).
	playing = function(v) return v.mode == 2 end,
	-- Fim da run: a última nave caiu (o jogo vai para a tela de nome do ranking).
	gameover = function(v) return v.mode == 2 and v.lives <= 0 end,
	-- Zerou: a 8ª fase foi vencida (fase 8, na tela de CONGRATULATIONS), com nave de pé.
	cleared = function(v) return v.stage >= 8 and v.lives > 0 end,
}
