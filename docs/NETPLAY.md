# Treino em dupla online (`-shmupx_netplay`)

Dois jogadores, cada um no seu PC, jogam o mesmo jogo como jogador 1 e jogador 2. Só no modo treino: a
dupla não vale ranking nem gasta ficha. O Client abre o motor nos dois PCs depois que o convite é aceito.

## Como funciona

O motor roda o jogo nos dois PCs ao mesmo tempo e troca só os controles (rollback, como no GGPO):

1. A cada quadro o motor guarda o estado da máquina, lê o controle local e trava nas portas as entradas
   dos dois jogadores. A entrada do parceiro que ainda não chegou é prevista (a última que chegou).
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
   resto iguais). DIP switches ficam no padrão, sem NVRAM salva, sem save state, pausa, menu, reset ou
   avanço rápido.

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
   A cada 8 quadros o motor volta de 1 a 7 quadros, roda esses quadros com entradas erradas (como uma
   previsão errada da entrada do parceiro, às vezes com START ou COIN), carrega o estado de novo e refaz
   com as entradas certas, comparando o CRC de cada estado refeito com o da linha original, que nunca
   voltou. Pega também o que não entra no save state e "vaza" da linha descartada. Falha mostra o quadro e os itens do save state que divergiram
   (`{"event":"synctest","result":"fail",...,"items":"..."}`); sucesso, `"result":"ok"`.
2. **Teste longo entre dois motores**: anfitrião e convidado no mesmo PC (`127.0.0.1`), com
   `-shmupx_netplay_autoinput` e `-shmupx_netplay_simulate 40,10,2`, por 30 minutos: `desyncs` tem que
   ficar em 0, no máximo 5% dos rollbacks podem passar do tempo de um quadro (`slow_rollbacks`) e o
   percentil 95 do rollback (`rollback_p95_ms`) tem que caber no quadro. O resumo também traz o tempo
   médio para guardar o estado (`avg_save_ms`) e para refazer um quadro (`avg_resim_frame_ms`).

O script `tools/netplay/certificar.ps1` roda os dois.

## Situação dos jogos (2026-11-27)

Liberados para teste no Client (`NETPLAY_ROMS`): `sonicwi2`, `bgaregga`, `cawing`, `ddonpach` e
`grindstm`. Os cinco passaram no SyncTest e ficaram com 0 desync em 30 minutos entre dois motores
(rede simulada 40,10,2). Custo medido com o PC livre: guardar o estado 0,6 a 0,9 ms, refazer um quadro
1,2 a 2,3 ms (Grind Stormer é o mais pesado, no limite do quadro com rollbacks de 6 a 7 quadros).

Fora da dupla:

- `batsugun`: passa no SyncTest (inclusive com previsão errada e voltas a cada 2 quadros), mas diverge
  entre dois motores logo depois do START do jogador 1 (quadro 151), mesmo com a rede perfeita
  (`-shmupx_netplay_simulate 0,0,0`). Só o V25 (CPU de som) difere: `m_ip`, `m_prev_ip` e
  `m_totalcycles` (o convidado roda 100608 ciclos a menos no quadro 150, 3/8 de quadro; o V25 sai do
  reset por volta do quadro 148). Depois da ressincronia volta a divergir, então é estado fora do save
  state que difere entre os dois processos. Com duas divergências seguidas (a segunda ressincronia
  espera 2 s) o anfitrião trava (ACCESS VIOLATION), também no motor anterior. Para investigar: gravar o
  estado do V25 (`m_totalcycles`, `m_localtime`, `m_suspend`, fila da linha de RESET) a cada timeslice do
  quadro 150 nos dois lados. O Grind Stormer usa a mesma placa e não apresentou o problema.
- `dariusg`, `espgal2`, `mushisam`: falham no SyncTest. `truxton`, `zerowing`: sem save state.
