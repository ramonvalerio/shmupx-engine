-- Campos comuns da Neo Geo (variáveis da BIOS, iguais em todos os jogos).
return {
	cpu = ":maincpu",
	fields = {
		-- BIOS_USER_MODE: 0 = inicialização, 1 = título/demonstração, 2 = partida.
		mode = { addr = 0x10fdaf, type = "u8" },
	},
}
