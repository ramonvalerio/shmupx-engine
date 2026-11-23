# ShmupX Engine

Motor de emulação competitivo do ShmupX, baseado no [GroovyMAME](https://github.com/antonioginer/GroovyMAME)
e no [MAME](https://www.mamedev.org/). O ShmupX Client abre o motor como um programa separado para as
partidas de shmup.

Objetivos:

- **Atraso mínimo dos controles:** frame delay e sincronização do GroovyMAME, raw input, sem frameskip.
- **Velocidade original do jogo:** no modo ranking, nada de acelerar o jogo para casar com o monitor.
- **Partida limpa:** no modo ranking, sem save state, cheats, avanço rápido ou DIP switches fora do padrão.
- **Telemetria:** o plugin `shmupx` lê da memória do jogo placar, vidas, continues, créditos e game over,
  e manda os eventos ao Client (`plugins/shmupx`).
- **Leve:** só os drivers dos jogos do catálogo do ShmupX (`src/shmupx.flt`).

O motor não traz nenhum ROM: o jogador usa os dele.

## Estrutura

| Caminho | O quê |
|---|---|
| `upstream.env` | Tag do GroovyMAME usada como base |
| `src/shmupx.flt` | Drivers compilados |
| `patches/` | Mudanças do ShmupX sobre o GroovyMAME, aplicadas em ordem |
| `plugins/shmupx/` | Plugin de telemetria e os mapas de memória por jogo |
| `.github/workflows/build-windows.yml` | Build no GitHub Actions |

## Licença

GPL-2.0-or-later, como o MAME (ver `COPYING` e `legal/`). MAME é marca registrada de Gregory Ember; o
ShmupX Engine não é um produto do MAMEdev nem do GroovyMAME.
