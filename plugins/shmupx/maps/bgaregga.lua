-- Battle Garegga (Raizing, bgaregga). Endereços achados com partidas automáticas no ShmupX Engine e
-- conferidos com a tela (placar e naves de reserva), inclusive nas trocas de fase.
return {
	cpu = ":maincpu",
	fields = {
		-- Placar do jogador 1: inteiro de 32 bits, como aparece na tela.
		score = { addr = 0x10166c, type = "u32" },
		-- Naves de reserva: 2 no começo, desce a cada morte; fica em 0 quando a última cai.
		lives = { addr = 0x101686, type = "s8" },
		-- Jogador 1 em partida: 0xff de apertar start até o fim do continue (0 na demonstração).
		p1 = { addr = 0x1000aa, type = "u8" },
		-- Contagem da tela CONTINUE?: 0 durante a partida; começa ~1 s depois da última nave cair.
		cont = { addr = 0x10002d, type = "u8" },
		-- Fase: 1 a 7 (a 7ª é a última).
		stage = { addr = 0x10a6b5, type = "u8" },
	},
	-- Começo da run: jogador 1 em partida, com a nave escolhida já em jogo.
	starts = function(v) return v.p1 == 0xff and v.lives > 0 and v.cont == 0 end,
	start_frames = 10,
	-- Run segue enquanto o jogador 1 estiver em partida (troca de fase não muda).
	playing = function(v) return v.p1 == 0xff end,
	-- Fim da run: sem naves de reserva e a tela CONTINUE? (sem ficha no ranked, não há continue).
	gameover = function(v) return v.cont ~= 0 and v.lives <= 0 end,
	-- Zerou: na 7ª fase, o jogador sai da partida sem passar pela tela de continue (depois do chefe
	-- final vêm os créditos, THE END e o ranking, ainda em partida). No game over, o continue aparece
	-- antes e a run já terminou.
	-- Fase alcançada (coluna PROGRESSO): já vem de 1 a 7.
	progress = function(v) return v.stage >= 1 and v.stage <= 7 and v.stage or nil end,
	cleared = function(v) return v.stage == 7 and v.p1 ~= 0xff and v.cont == 0 end,
}
