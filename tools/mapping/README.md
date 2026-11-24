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

Regras do mapa: nada pode disparar no boot, no título nem na demonstração automática; o fim da run tem de
bater com a tela de continue/game over.
