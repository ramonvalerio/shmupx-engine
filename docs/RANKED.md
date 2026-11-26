# Modo ranking (`-shmupx_ranked`)

O ShmupX Client abre o motor com `-shmupx_ranked` nas partidas que valem ranking. O modo treino abre sem
a opção e tudo fica liberado.

Com a opção, o motor trava (prioridade máxima, nenhum INI ou argumento passa por cima):

| O quê | Como |
|---|---|
| Velocidade original | throttle ligado, velocidade 1.0, sem `refreshspeed`, sem frameskip; sincronia com o monitor só se a frequência dele for a do jogo (tolerância 0,05 Hz) |
| Sem estados salvos | `schedule_save/load` e `immediate_save/load` ignorados (teclas, menus, Lua, `-state`, `-autosave`); sem retrocesso |
| Uma ficha por partida | a partida começa de `states/<jogo>/shmupx_ranked.sta` (o jogo na tela de start com 1 crédito), o único estado que carrega. Com ele carregado, só os controles do jogador 1 valem (direcional, botões e Start 1): ficha, nota, crédito e modo de serviço, tilt, reset da placa, Start 2 e os controles dos outros jogadores ficam travados. O Client só abre o Ranked de um jogo que tem esse estado no pacote do motor |
| Configurações no padrão | DIP switches do `.cfg` ignorados (os controles continuam valendo); NVRAM nova a cada partida (dificuldade e vidas da BIOS não vêm de antes); BIOS padrão (nada de Unibios) |
| Sem ajuda externa | sem cheats, depurador, console Lua, `autoboot_script`/`autoboot_command`, servidor HTTP; só o plugin `shmupx` roda |
| Interface | só sair (Esc), reiniciar, foto da tela e FPS; sem menu (Tab), sliders (clock da CPU, velocidade), pausa, quadro a quadro, avanço rápido, frameskip |

A telemetria informa o modo e a velocidade real:

- `start` traz `"ranked": true`;
- `gameover` e `abort` trazem `"speed"`: velocidade média da run em % (tempo emulado / tempo real). O
  servidor recusa runs fora da faixa aceita (por exemplo, PC lento demais).

Os arquivos do motor (executável e plugins) são conferidos pelo Client antes da partida: um pacote
alterado não abre partida valendo ranking.
