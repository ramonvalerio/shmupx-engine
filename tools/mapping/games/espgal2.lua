-- Espgaluda II (Cave CV1000, SH-3): RAM 0xc000000-0xc7fffff (8 MB). Para descobrir, guarde a RAM bem
-- espaçada (300 quadros) ou só a faixa 0xc370000-0xc38ffff, onde ficam placar, naves e estado.
return { coin = {":PORT_C", "Coin 1"}, start = {":PORT_C", "1 Player Start"}, fire = {":PORT_D", "P1 Button 1"},
	left = {":PORT_D", "P1 Left"}, right = {":PORT_D", "P1 Right"}, ram = {{0xc370000, 0xc38ffff}},
	times = { coin = 1200, start = 1400, play = 2000 } }
