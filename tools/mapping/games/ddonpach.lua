-- DoDonPachi (Cave): RAM 0x100000-0x10ffff, tela vertical (:screen.0). Vidas infinitas na descoberta:
-- god = { 0x101965, 3, from = 2800 }.
return { coin = {":IN0", "Coin 1"}, start = {":IN0", "1 Player Start"}, fire = {":IN0", "P1 Button 1"},
	left = {":IN0", "P1 Left"}, right = {":IN0", "P1 Right"}, ram = {{0x100000, 0x10ffff}}, screen = ":screen.0",
	times = { coin = 900, start = 1100, play = 1700 } }
