# Mapeamento de memória de um jogo

Como os endereços dos mapas (`plugins/shmupx/maps/<rom>.lua`) são achados.

1. **Partida automática com cópias da RAM:** `autoplay-dump.lua` põe ficha, aperta start e atira sozinho;
   a cada 30 quadros guarda a RAM principal (`ram.bin`) e a cada 300 a tela (`shot_*.raw`). Os controles, a
   faixa de RAM e os tempos de cada placa ficam em `games/<rom>.lua` (para uma placa nova, listar os campos com
   `manager.machine.ioport.ports`). `trace` registra endereços quadro a quadro; `god` (vidas infinitas) e
   `dips` (ex.: invencibilidade de teste) servem só para ver as trocas de fase.

   ```sh
   SHMUPX_DISCOVER_CFG=tools/mapping/games/<rom>.lua SHMUPX_DISCOVER_OUT=<pasta> SHMUPX_DISCOVER_FRAMES=21600 \
     shmupx-engine <rom> -rompath <roms> -video none -sound none -nothrottle -skip_gameinfo \
     -nvram_directory <vazia> -cfg_directory <vazia> -autoboot_script tools/mapping/autoplay-dump.lua
   ```

2. **Ler a tela:** `shots.py` monta as capturas numa grade (`ROT=90` para os verticais); anotar placar, vidas e
   momentos (começo, mortes, game over, demonstração).
3. **Cruzar com a RAM:** `find.py` acha o placar pelos valores lidos na tela (BCD, binário, dígito por byte),
   as vidas (descidas de 1), o estado da partida (constante no jogo e diferente na demonstração) e mostra
   cada endereço ao longo do tempo.
4. **Mapa e teste:** escrever `maps/<rom>.lua` (campos, `starts`, `playing`, `gameover`) e rodar a partida
   automática com `-plugin shmupx`: só pode haver eventos dentro das runs de verdade.

5. **Estado inicial ranked:** `start-state.lua` liga o jogo com NVRAM e configurações novas, põe 1 ficha e
   salva `states/<rom>/shmupx_ranked.sta` na tela de start. Conferir a foto (CREDIT 1) e testar o som depois
   de carregar o estado (`-state shmupx_ranked` com `-wavwrite`): placa com save state incompleto no MAME fica
   muda ou errada (ex.: Taito F3, corrigida no `patches/0004`). Patch que muda o save state de uma placa
   obriga a gerar de novo o estado dela.
   Jogos de boot longo pedem a ficha mais tarde: `SHMUPX_STATE_COIN=1500` (Ketsui), `3600` (Battle Garegga).

   ```sh
   shmupx-engine <rom> -rompath <roms> -skip_gameinfo -nvram_directory <vazia> -cfg_directory <vazia> \
     -state_directory states -autoboot_script tools/mapping/start-state.lua
   ```

Regras do mapa: nada pode disparar no boot, no título nem na demonstração automática; o fim da run tem de
bater com a tela de continue/game over.
