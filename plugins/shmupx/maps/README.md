# Mapas de memória

Um arquivo por ROM (`<rom>.lua`), devolvendo uma tabela:

```lua
return {
  cpu = ":maincpu",            -- CPU padrão dos campos
  fields = {
    score   = { addr = 0x10a000, type = "bcd32" },
    lives   = { addr = 0x10a010, type = "u8" },
    credits = { addr = 0x10fdb0, type = "bcd8" },
  },
  -- Opcional: game over a partir dos valores do quadro.
  gameover = function(v) return v.lives == 0 and v.credits == 0 end,
}
```

Tipos: `u8`, `u16`, `u32`, `bcd8`, `bcd16`, `bcd32`. Campos aceitam `cpu`, `space` (padrão `program`),
`scale` e `offset`.
