-- Samurai Aces / Sengoku Ace (Psikyo 1ª geração). Endereços achados com partidas automáticas no
-- ShmupX Engine e conferidos com a tela (placar 500, 1000) e com as trocas de fase.
return {
	cpu = ":maincpu",
	fields = {
		-- Placar do jogador 1: inteiro de 32 bits (0x3e8 = 1000). A demonstração também escreve aqui.
		score = { addr = 0xfe1b08, type = "u32" },
		-- Naves do jogador 1, contando a que está em jogo: 3 no começo, 0 quando a última cai.
		lives = { addr = 0xfe1b05, type = "s8" },
		-- Estado do jogo: 2 título/demonstração, 5 com crédito, 4 escolha do personagem, 1 em partida
		-- (também na contagem do continue), 0 por uns 120 quadros em cada troca de fase (e no boot).
		mode = { addr = 0xfe0287, type = "u8" },
	},
	-- Começo da run: em partida com as naves postas.
	starts = function(v) return v.mode == 1 and v.lives > 0 end,
	start_frames = 10,
	-- Run segue enquanto o jogo estiver em partida; na troca de fase o estado passa por 0.
	playing = function(v) return v.mode == 1 or v.mode == 0 end,
	-- Fim da run: a última nave caiu (vem a contagem do continue).
	gameover = function(v) return v.mode == 1 and v.lives <= 0 end,
}
