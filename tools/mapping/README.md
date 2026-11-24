# Mapeamento de memória de um jogo

Como os endereços do Aero Fighters 2 (`plugins/shmupx/maps/sonicwi2.lua`) foram achados.

1. **Partida automática com cópias da RAM:** `autoplay-dump.lua` põe fichas, aperta start e atira sozinho;
   a cada 30 quadros guarda a RAM principal (`ram.bin`) e a cada 300 a tela (`shot_*.raw`). Os nomes dos
   controles e a faixa de RAM são da Neo Geo; para outra placa, listar os campos com
   `manager.machine.ioport.ports` e ajustar.

   ```sh
   SHMUPX_DISCOVER_OUT=<pasta> SHMUPX_DISCOVER_FRAMES=21600 \
     shmupx-engine <rom> -rompath <roms> -video none -sound none -nothrottle -skip_gameinfo \
     -str 400 -autoboot_script tools/mapping/autoplay-dump.lua
   ```

2. **Ler a tela:** montar as capturas lado a lado e anotar placar, vidas e momentos (começo, mortes,
   game over, demonstração).
3. **Cruzar com a RAM:** `analyze.py` procura fichas, vidas e placar; para o placar, comparar com os valores
   lidos na tela (BCD, binário, dígito por byte).
4. **Mapa e teste:** escrever `maps/<rom>.lua` (campos, `starts`, `playing`, `gameover`) e rodar a partida
   automática com `-plugin shmupx`: só pode haver eventos dentro das runs de verdade.

5. **Estado inicial ranked:** `start-state.lua` liga o jogo com NVRAM e configurações novas, põe 1 ficha e
   salva `states/<rom>/shmupx_ranked.sta` na tela de start. Conferir a foto (CREDIT 1) e testar o som depois
   de carregar o estado (`-state shmupx_ranked` com `-wavwrite`): placa com save state incompleto no MAME fica
   muda ou errada (ex.: Taito F3, corrigida no `patches/0004`). Patch que muda o save state de uma placa
   obriga a gerar de novo o estado dela.

   ```sh
   shmupx-engine <rom> -rompath <roms> -skip_gameinfo -nvram_directory <vazia> -cfg_directory <vazia>      -state_directory states -autoboot_script tools/mapping/start-state.lua
   ```

Regras do mapa: nada pode disparar no boot, no título nem na demonstração automática; o fim da run tem de
bater com a tela de continue/game over.
