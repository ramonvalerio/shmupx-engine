# Patches do ShmupX

Mudanças sobre o GroovyMAME, aplicadas em ordem alfabética pelo build (`git apply`).
Nomes: `NNNN-descricao.patch`.

- `0000-emusync-sem-pch.patch`: `emusync.cpp` inclui `emu.h` (o build sem cabeçalho pré-compilado, por causa do ccache, precisa).
- `0001-shmupx-ranked.patch`: opção `-shmupx_ranked` e as travas da partida valendo ranking (ver `docs/RANKED.md`).
- `0002-shmupx-titulo-da-janela.patch`: a janela se chama `ShmupX Emulator - v1.0.0 | <jogo>`, sem a marca do MAME. A versão vem de `SHMUPX_EMULATOR_VERSION`.
- `0003-shmupx-ranked-estado-inicial.patch`: a partida ranked começa de `states/<jogo>/shmupx_ranked.sta` (o jogo na tela de start com 1 crédito); com ele carregado, ficha, nota e crédito de serviço não entram (sem continue) e os resets saem do painel (uma ficha, uma partida). Jogo sem esse arquivo começa do zero, com a ficha liberada.
