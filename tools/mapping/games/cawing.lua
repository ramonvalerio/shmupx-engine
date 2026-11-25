-- Carrier Air Wing (CPS1): RAM de trabalho 0xff0000-0xffffff. Ficha e start repetidos para ver continues.
return { coin = {":IN0", "Coin 1"}, start = {":IN0", "1 Player Start"}, fire = {":IN1", "P1 Button 1"},
	left = {":IN1", "P1 Left"}, right = {":IN1", "P1 Right"}, ram = {{0xff0000, 0xffffff}},
	times = { coin = 600, start = 800, play = 1300 } }
