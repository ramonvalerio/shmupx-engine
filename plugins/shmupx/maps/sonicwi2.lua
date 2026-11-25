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
		-- Fase: conta também as telas entre fases; 19 é a última (a sala do olho, com o chefe final).
		stage = { addr = 0x10e411, type = "u8" },
		-- Cena do final: 89 a 96 na tela "CONGRATULATIONS!" depois do chefe final (o piloto da nave:
		-- FS-X 89, F-15 90, F-117 91, A-10 92, F-14 93, YF-23 94, Rafale 95, Sea Harrier 96); 97/98
		-- quando o tempo do chefe acaba e ele foge (fim de jogo sem zerar, com qualquer nave).
		ending = { addr = 0x100623, type = "u8" },
		-- Nave escolhida pelo jogador 1 (nomes como aparecem na tela de escolha do jogo).
		ship = { addr = 0x10e465, type = "u8", labels = {
			[0] = "FS-X", [1] = "F-15", [2] = "A-10", [3] = "YF-23",
			[4] = "F-14", [5] = "F-117", [6] = "Rafale", [7] = "Sea Harrier FRS.2",
		} },
	},
	-- Começo da run: partida da BIOS (não a demonstração) com a nave em jogo.
	starts = function(v) return v.mode == 2 and v.state == 3 and v.lives >= 0 end,
	-- Ao apertar start, a BIOS entra em partida com o estado da demonstração ainda em 3 por alguns quadros.
	start_frames = 10,
	-- Run segue enquanto a BIOS estiver em partida (troca de fase não encerra).
	playing = function(v) return v.mode == 2 end,
	-- Fim da run: a última nave caiu (tela de continue) ou o tempo do chefe final acabou e ele fugiu
	-- (o jogo termina mesmo com naves sobrando).
	gameover = function(v)
		return v.mode == 2 and (v.lives < 0 or (v.stage == 19 and v.ending >= 97 and v.ending <= 98))
	end,
	-- Zerou: o chefe final morreu e o jogo mostra "CONGRATULATIONS!" (ainda em partida). Perder a
	-- última nave na fase final e continuar volta ao começo dela.
	cleared = function(v) return v.mode == 2 and v.stage == 19 and v.ending >= 89 and v.ending <= 96 end,
}
