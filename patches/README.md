# Patches do ShmupX

Mudanças sobre o GroovyMAME, aplicadas em ordem alfabética pelo build (`git apply`).
Nomes: `NNNN-descricao.patch`.

- `0000-emusync-sem-pch.patch`: `emusync.cpp` inclui `emu.h` (o build sem cabeçalho pré-compilado, por causa do ccache, precisa).
- `0001-shmupx-ranked.patch`: opção `-shmupx_ranked` e as travas da partida valendo ranking (ver `docs/RANKED.md`).
- `0002-shmupx-titulo-da-janela.patch`: a janela se chama `ShmupX Emulator - v1.0.0 | <jogo>`, sem a marca do MAME. A versão vem de `SHMUPX_EMULATOR_VERSION`.
- `0003-shmupx-ranked-estado-inicial.patch`: a partida ranked começa de `states/<jogo>/shmupx_ranked.sta` (o jogo na tela de start com 1 crédito); com ele carregado, ficha, nota e crédito de serviço não entram (sem continue) e os resets saem do painel (uma ficha, uma partida). Jogo sem esse arquivo começa do zero, com a ficha liberada.
- `0004-shmupx-som-taito-f3-save-state.patch`: o som da Taito F3 (Darius Gaiden) volta depois de carregar um estado: o ESP ligado/parado entra no save state e o clock do pump e os volumes são reaplicados ao carregar (sem isso, o estado inicial ranked deixava o jogo mudo).
- `0005-shmupx-sem-tela-de-aviso.patch`: o jogo abre direto, sem a tela laranja de aviso do MAME (emulação imperfeita, ROM sem dump bom) que esperava uma tecla; na partida ranked ele vai direto para o estado inicial. O texto do aviso sai na saída de erro, que o Client grava no log.
- `0006-shmupx-duplo-clique-tela-cheia.patch`: dois cliques na janela do jogo alternam entre janela e tela cheia, como o Alt+Enter (no tempo e na distância de duplo clique do Windows). Com um menu do MAME aberto, o duplo clique continua sendo dos menus.
