# Treino em dupla online (`-shmupx_netplay`)

Dois jogadores, cada um no seu PC, jogam o mesmo jogo como jogador 1 e jogador 2. Só no modo treino: a
dupla não vale ranking nem gasta ficha. O Client abre o motor nos dois PCs depois que o convite é aceito.

## Como funciona

O motor roda o jogo nos dois PCs ao mesmo tempo e troca só os controles (rollback, como no GGPO):

1. A cada quadro o motor lê o controle local e já o envia ao parceiro (antes de refazer quadros, para
   chegar mais cedo), guarda o estado da máquina e trava nas portas as entradas dos dois jogadores. A
   entrada do parceiro que ainda não chegou é prevista (a última que chegou).
2. Quando a entrada real chega e difere da prevista, o motor volta ao estado daquele quadro e refaz os
   quadros seguintes sem mostrar, sem som e sem esperar (no máximo 8 quadros). A tela é desenhada na
   memória mesmo assim: vários drivers mudam estado do jogo ao desenhar (rolagem, buffer de sprites).
3. O controle local entra no mesmo ponto que no jogo offline. O atraso de rede (`-shmupx_netplay_delay`)
   é 0 em conexões até ~130 ms de ida e volta; acima disso o motor põe 1 a 4 quadros para os rollbacks
   não ficarem longos.
4. Quem está na frente desacelera um pouco a cada quadro (até 4,5 ms), sem pular quadros: os dois
   ficam no mesmo quadro sem engasgo.
5. A cada 30 quadros confirmados os dois comparam o CRC do estado inteiro. Se divergir (desync), o
   anfitrião manda o estado dele e o convidado carrega e refaz os quadros até o presente.
6. O começo da partida usa o mesmo envio: o convidado começa do estado do anfitrião (NVRAM, relógio e o
   resto iguais). Antes disso os dois lados executam os timers do instante zero da máquina, para o estado
   inicial não levar evento pendente. DIP switches ficam no padrão, sem NVRAM salva, sem save state,
   pausa, menu, reset ou avanço rápido.
7. Todo carregamento de estado descarta os eventos pendentes das linhas de entrada das CPUs (IRQ, RESET):
   eles são da linha do tempo descartada e não entram no save state. Sem isso a fila da linha ficava
   presa e a linha só voltava a funcionar ao encher (32 eventos), em momentos diferentes nos dois PCs.

O som dos quadros refeitos não vai para a placa de som (o jogador já ouviu esse trecho).

## Opções

| Opção | O quê |
|---|---|
| `-shmupx_netplay host\|guest` | anfitrião (jogador 1, quem convidou) ou convidado (jogador 2) |
| `-shmupx_netplay_port N` | porta UDP local (0 = qualquer uma) |
| `-shmupx_netplay_peer a:p,b:p` | endereços do parceiro (rede local, IP público visto pelo STUN); o primeiro que responde vale |
| `-shmupx_netplay_key K` | chave da sessão (pacotes de outra sessão são ignorados) |
| `-shmupx_netplay_delay N` | atraso local em quadros (-1 = automático) |
| `-shmupx_netplay_autoinput` | testes: entradas geradas no lugar do controle |
| `-shmupx_netplay_simulate d,j,p` | testes: atraso de ida (ms), variação (ms) e perda (%) simulados |
| `-shmupx_synctest N` | teste de determinismo (abaixo) |

Os dois motores precisam ser do mesmo build e ter os mesmos ROMs (o motor confere no aperto de mão).

## Eventos para o Client

Linhas `SHMUPX_NETPLAY {json}` na saída padrão:

- `connecting`, `connected` (`peer`, `rtt`), `state_send`, `running` (`delay`, `rtt`);
- `stats` a cada 5 s: `rtt`, `rollbacks`, `resimulated`, `max_rollback`, `stall_ms`, `desyncs`, `ahead`;
- `unstable` / `stable` (sem pacotes há 2,5 s), `desync` e `resynced`;
- `ended` com `reason`: `partner_left`, `timeout`, `connect_failed`, `version_mismatch`, `rom_mismatch`,
  `local_exit`, `no_save_state` e outros; `summary` no fim.

## Certificação de um jogo

Um jogo só entra no treino em dupla depois de passar nos dois testes:

1. **SyncTest** (determinismo): `shmupx-engine <jogo> -shmupx_synctest 7 -video none -sound none -str 600`.
   Começa como a partida (guarda e carrega o estado inicial). A cada 8 quadros o motor volta de 1 a 7
   quadros, roda esses quadros com entradas erradas (como uma previsão errada da entrada do parceiro, às
   vezes com START ou COIN), carrega o estado de novo no mesmo ponto em que a partida faz o rollback
   (logo depois do último quadro errado, sem assentar) e refaz com as entradas certas, comparando o CRC
   de cada estado refeito com o da linha original, que nunca voltou. Pega também o que não entra no save state e "vaza" da linha descartada. Falha mostra o quadro e os itens do save state que divergiram
   (`{"event":"synctest","result":"fail",...,"items":"..."}`); sucesso, `"result":"ok"`.
2. **Teste longo entre dois motores**: anfitrião e convidado no mesmo PC (`127.0.0.1`), com
   `-shmupx_netplay_autoinput` e `-shmupx_netplay_simulate 40,10,2`, por 30 minutos: `desyncs` tem que
   ficar em 0, no máximo 1% dos rollbacks podem passar do tempo de um quadro (`slow_rollbacks`) e o
   percentil 95 do rollback (`rollback_p95_ms`) tem que ficar em até 60% do quadro. O tempo do rollback
   conta o carregamento do estado e os quadros refeitos. O resumo também traz a mediana
   (`rollback_p50_ms`), o tempo médio para guardar o estado (`avg_save_ms`), para carregar
   (`avg_load_ms`) e para refazer um quadro (`avg_resim_frame_ms`), e quantos rollbacks houve de cada
   profundidade, de 1 a 8 quadros (`depths`).

O script `tools/netplay/certificar.ps1` roda os dois.

## Situação dos jogos (2026-11-27)

Liberados para teste no Client (`NETPLAY_ROMS`): `sonicwi2`, `bgaregga`, `cawing`, `ddonpach`,
`batsugun` e `grindstm`. Os seis passaram no SyncTest (600 s) e ficaram com 0 desync em 30 minutos
entre dois motores (rede simulada 40,10,2), no motor nativo para Linux, com os seis pares rodando ao
mesmo tempo num Ryzen 7 7840HS:

| Jogo | Quadros | Desyncs | Rollback médio (quadros) | p95 (ms) | p99 (ms) | Acima de um quadro | Guardar (ms) | Carregar (ms) | Refazer um quadro (ms) |
|---|---|---|---|---|---|---|---|---|---|
| `sonicwi2` | 106535 | 0 | 3,5 | 5 | 6 | 0,01% | 0,09 | 0,16 | 0,92 |
| `bgaregga` | 107348 | 0 | 3,5 | 8 | 8 | 0,01% | 0,15 | 0,31 | 1,35 |
| `cawing` | 107348 | 0 | 3,5 | 4 | 4 | 0,01% | 0,06 | 0,14 | 0,74 |
| `ddonpach` | 103592 | 0 | 3,5 | 6 | 6 | 0,01% | 0,14 | 0,27 | 0,92 |
| `batsugun` | 107348 | 0 | 3,5 | 9 | 10 | 0,02% | 0,15 | 0,33 | 1,80 |
| `grindstm` | 107348 | 0 | 3,5 | 6 | 7 | 0,01% | 0,15 | 0,33 | 1,08 |

Os tempos são o pior dos dois lados. O quadro tem 16,8 ms; o RTT medido ficou em 113 a 119 ms.

Fora da dupla:

- `dariusg`, `espgal2`, `mushisam`: falham no SyncTest. `truxton`, `zerowing`: sem save state.

### O que era o desync do Batsugun e do Grind Stormer

O estado inicial era guardado com eventos ainda pendentes nas filas das linhas de entrada (o RESET do
V25 e o IRQ 4 do 68000, postos no reset da máquina). O carregamento apagava o timer que esvazia a fila
e o evento ficava preso: a linha só funcionava quando a fila enchia (32 eventos). Como a fila não entra
no save state, cada rollback mudava a contagem, e o V25 saía do reset em momentos diferentes nos dois
PCs (quadro 151 no Batsugun, entre o 181 e o 210 no Grind Stormer). O SyncTest não pegava porque não
guardava e carregava o estado inicial como a partida.

A queda do anfitrião (ACCESS VIOLATION) vinha daí: solto do reset na hora errada, o V25 rodava código
inválido, passava do fim da fatia de tempo e adiantava os canais de som; o misturador lia antes do
começo do buffer. Com a linha de RESET certa isso não acontece; o reamostrador também ficou protegido.
