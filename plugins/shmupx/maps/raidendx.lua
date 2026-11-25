-- Raiden DX (Seibu, V30, raidendx). Endereços achados com partidas automáticas no ShmupX Engine e
-- conferidos com a tela (placar e naves de reserva), em várias partidas seguidas.
return {
	cpu = ":maincpu",
	fields = {
		-- Placar do jogador 1: inteiro de 32 bits (a V30 é little-endian; o u32 já lê na ordem da CPU).
		score = { addr = 0xa55c, type = "u32" },
		-- Naves: 3 ao começar (a tela mostra as de reserva, uma a menos), desce a cada morte; 0 quando a
		-- última cai. Fica em 0 no título e na demonstração. O estado do jogo (0x82d) muda com o curso
		-- escolhido (Training, Novice, Expert), por isso a run segue pelas naves.
		lives = { addr = 0xa554, type = "u8" },
	},
	-- Começo da run: naves postas (a partida começou; o curso já foi escolhido ou está na escolha).
	starts = function(v) return v.lives >= 1 end,
	start_frames = 10,
	-- Run segue enquanto houver nave (troca de fase não zera o contador).
	playing = function(v) return v.lives >= 1 end,
	-- Fim da run: a última nave caiu (sem ficha no ranked, não há continue; o continue zera o placar).
	gameover = function(v) return v.lives == 0 end,
}
