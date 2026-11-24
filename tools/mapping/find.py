"""Cruza o que se vê na tela com as cópias da RAM da descoberta (autoplay-dump.lua).

  find.py <pasta> <base> score Q:V,Q:V,...     placar com esses valores nesses quadros (BCD, binário BE/LE,
                                               dígito por byte; também com o 0 final fora: x10, x100)
  find.py <pasta> <base> byte Q:V,Q:V,...      byte com esses valores nesses quadros
  find.py <pasta> <base> lives DE ATÉ          bytes que só descem de 1 em 1 na partida (vidas)
  find.py <pasta> <base> flag JOGO DEMO        bytes constantes na partida e com outros valores na
                                               demonstração/título (janelas a-b, separadas por vírgula)
  find.py <pasta> <base> show END [N] [DE] [ATÉ]  valores de N bytes ao longo do tempo (só mudanças)

<base>: endereço do primeiro byte guardado (ex.: 100000 na Neo Geo). Quadros: múltiplos de 30.
"""
import sys

d, base, cmd = sys.argv[1], int(sys.argv[2], 16), sys.argv[3]
frames = [int(x) for x in open(d + "/frames.txt").read().split()]
data = open(d + "/ram.bin", "rb").read()
size = len(data) // len(frames)
snaps = [data[i * size:(i + 1) * size] for i in range(len(frames))]
index = {f: i for i, f in enumerate(frames)}


def snap(f):
    return snaps[index[f]]


def pairs(arg):
    return [tuple(map(int, p.split(":"))) for p in arg.split(",")]


def window(arg):
    spans = [tuple(map(int, w.split("-"))) for w in arg.split(",")]
    return [i for i, f in enumerate(frames) if any(a <= f <= b for a, b in spans)]


def bcd(bs):
    v = 0
    for x in bs:
        if (x >> 4) > 9 or (x & 15) > 9:
            return None
        v = v * 100 + (x >> 4) * 10 + (x & 15)
    return v


def digits(bs):
    v = 0
    for x in bs:
        if x > 9:
            return None
        v = v * 10 + x
    return v


FORMATS = [("bcd", n, bcd) for n in (2, 3, 4)] + [("digits", n, digits) for n in (6, 7, 8)] + [
    ("u32be", 4, lambda b: int.from_bytes(b, "big")), ("u32le", 4, lambda b: int.from_bytes(b, "little")),
    ("u16be", 2, lambda b: int.from_bytes(b, "big")), ("u16le", 2, lambda b: int.from_bytes(b, "little"))]

if cmd == "score":
    want = pairs(sys.argv[4])
    for off in range(size - 8):
        for name, n, fn in FORMATS:
            for div in (1, 10, 100):
                if all((got := fn(snap(f)[off:off + n])) is not None and got * div == v for f, v in want):
                    print(hex(base + off), name, n, "x", div)
elif cmd == "byte":
    want = pairs(sys.argv[4])
    for off in range(size):
        if all(snap(f)[off] == (v & 0xff) for f, v in want):
            print(hex(base + off))
elif cmd == "lives":
    idx = window(sys.argv[4] + "-" + sys.argv[5])
    for off in range(size):
        seq = [snaps[i][off] - 256 if snaps[i][off] >= 128 else snaps[i][off] for i in idx]
        changes = [(frames[idx[k]], seq[k - 1], seq[k]) for k in range(1, len(seq)) if seq[k] != seq[k - 1]]
        if 2 <= len(changes) <= 6 and all(a - b == 1 for _, a, b in changes) and 0 <= seq[0] <= 9:
            print(hex(base + off), seq[0], "->", changes)
elif cmd == "flag":
    play, demo = window(sys.argv[4]), window(sys.argv[5])
    for off in range(size):
        pv = {snaps[i][off] for i in play}
        dv = {snaps[i][off] for i in demo}
        if len(pv) <= 2 and len(dv) <= 3 and not pv & dv:
            print(hex(base + off), "jogo", sorted(pv), "demo", sorted(dv))
elif cmd == "show":
    off = int(sys.argv[4], 16) - base
    n = int(sys.argv[5]) if len(sys.argv) > 5 else 1
    lo = int(sys.argv[6]) if len(sys.argv) > 6 else 0
    hi = int(sys.argv[7]) if len(sys.argv) > 7 else 10 ** 9
    prev = None
    for i, f in enumerate(frames):
        cur = snaps[i][off:off + n].hex()
        if lo <= f <= hi and cur != prev:
            print(f, cur)
            prev = cur
else:
    sys.exit(__doc__)
