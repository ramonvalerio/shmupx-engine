-- Andro Dunos (Visco, Neo Geo, androdun). Endereços achados com partidas automáticas no ShmupX Engine e
-- conferidos com a tela (placar 200, 700, 1450, 1900, 2850, 2950) e com as trocas de fase.
return {
	extends = "neogeo",
	fields = {
		-- Placar do jogador 1: inteiro de 32 bits, sem o 0 final da tela (0x127 = 295 → 2950).
		score = { addr = 0x100184, type = "u32", scale = 10 },
		-- Naves do jogador 1, contando a que está em jogo: 3 no começo, 0 quando a última cai.
		lives = { addr = 0x100343, type = "s8" },
	},
	-- Começo da run: partida da BIOS (não a demonstração) com as naves postas.
	starts = function(v) return v.mode == 2 and v.lives > 0 end,
	start_frames = 10,
	-- Run segue enquanto a BIOS estiver em partida (troca de fase não encerra).
	playing = function(v) return v.mode == 2 end,
	-- Fim da run: a última nave caiu (vem o GAME OVER).
	gameover = function(v) return v.mode == 2 and v.lives <= 0 end,
}
