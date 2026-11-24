-- Battle Garegga (Raizing): checagem de ROM longa, ficha em 3600. Vidas infinitas: god = { 0x101686, 2, from = 4100 }.
return { coin = {":SYS", "Coin 1"}, start = {":SYS", "1 Player Start"}, fire = {":IN1", "P1 Button 1"},
	left = {":IN1", "P1 Left"}, right = {":IN1", "P1 Right"}, ram = {{0x100000, 0x10ffff}},
	times = { coin = 3600, start = 3800, play = 4400 } }
