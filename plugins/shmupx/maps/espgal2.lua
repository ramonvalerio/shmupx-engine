-- Espgaluda II (Cave CV1000, SH-3, espgal2). Endereços achados com partidas automáticas no ShmupX Engine
-- e conferidos com a tela (placar e naves), em duas partidas seguidas. A RAM do CV1000 tem 8 MB: as
-- variáveis do jogador ficam juntas perto de 0xc37d6f0.
return {
	cpu = ":maincpu",
	fields = {
		-- Placar do jogador 1: inteiro de 32 bits (na tela, o contador "rola" até o valor).
		score = { addr = 0xc37d70c, type = "u32" },
		-- Naves de reserva: 3 no começo, desce a cada morte; em 0 o jogador ainda joga com a última nave.
		lives = { addr = 0xc37d6ff, type = "u8" },
		-- Jogador 1 em partida: 1 da escolha da personagem até o fim da partida, 0 no título e depois.
		p1 = { addr = 0xc37d6fc, type = "u8" },
		-- Fase: 0 a 5 (são 6); vai a 6 quando o chefe final cai.
		stage = { addr = 0xc37d39b, type = "u8" },
		-- Personagem: 0 Ageha, 1 Tateha, 2 Asagi (o nome aparece na tela de escolha).
		character = { addr = 0xc37d704, type = "u8" },
	},
	-- Personagem (tools/mapping/nave-dump.lua, conferida na tela CHARACTER SELECT).
	ship = function(v) return ({ [0] = 'Ageha', 'Tateha', 'Asagi' })[v.character] end,
	-- Começo da run: jogador 1 em partida (a partir da escolha da personagem).
	starts = function(v) return v.p1 == 1 end,
	start_frames = 10,
	-- Run segue enquanto o jogador 1 estiver em partida.
	playing = function(v) return v.p1 == 1 end,
	-- Fim da run: saiu da partida sem naves de reserva (a última caiu).
	gameover = function(v) return v.p1 == 0 and v.lives == 0 and v.stage < 6 end,
	-- Zerou: o chefe final caiu (fase 6). Vem antes do gameover: zerar na última nave também tem
	-- reservas em 0.
	cleared = function(v) return v.stage >= 6 end,
}
