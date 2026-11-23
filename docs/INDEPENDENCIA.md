# Independência e licenças

O ShmupX Engine usa trabalho de outros autores (MAME, GroovyMAME, Switchres, Groovy MiSTer). Estas regras
garantem que o ShmupX possa ser comercializado sem problema e sem ficar preso a eles.

## Os direitos não podem ser retirados

As licenças GPL-2.0+ e BSD-3 valem para sempre sobre o código já publicado. Se um autor mudar de licença,
parar o projeto ou apagar o repositório, a versão que o ShmupX já tem continua livre para usar, modificar
e vender, desde que as condições abaixo sejam cumpridas (descumprir a GPL encerra a permissão).

## Condições (checklist de cada versão distribuída)

- [ ] Fonte completa da versão publicada: tag do `shmupx-engine` + release `upstream-<tag>` com a fonte do
      GroovyMAME usada.
- [ ] `COPYING` e `legal/` dentro do pacote do motor.
- [ ] Avisos de copyright mantidos nos arquivos (BSD-3: `drawnogpu.cpp`, `input_mister.cpp`).
- [ ] Motor rodando como programa separado do Client (nunca embutido como biblioteca).
- [ ] Nome próprio (ShmupX Engine); "MAME" e "MiSTer" só como referência e compatibilidade.
- [ ] Créditos visíveis no Client (Sobre o ShmupX Engine).
- [ ] Core Groovy MiSTer: o Client baixa a versão oficial do autor e mostra licença e link da fonte.

## Sem dependência

- **Fonte guardada aqui:** o workflow `mirror-upstream` copia a fonte exata do GroovyMAME para uma release
  deste repositório. O build não depende do GitHub de origem.
- **Atualizar é opcional:** a base só muda quando o ShmupX quiser (`upstream.env`).
- **O que é do ShmupX fica separado:** o plugin de telemetria usa só a API Lua padrão do MAME, os mapas de
  memória são arquivos próprios e o Client fala com o motor por um protocolo próprio (linhas `SHMUPX {...}`
  na saída padrão). Trocar a base (MAME oficial ou outro emulador que fale o mesmo protocolo) não mexe no
  Client nem nos mapas. A única parte exclusiva do GroovyMAME é a saída de vídeo para a MiSTer.

Isto é uma leitura técnica das licenças, não parecer jurídico.
