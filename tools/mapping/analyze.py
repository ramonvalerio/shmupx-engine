"""Analisa as cópias da RAM (ram.bin, 64 KiB a cada 30 quadros) da descoberta."""
import sys

base = 0x100000
d = sys.argv[1]
data = open(d + "/ram.bin", "rb").read()
frames = [int(x) for x in open(d + "/frames.txt").read().split()]
n = len(frames)
snaps = [data[i * 65536:(i + 1) * 65536] for i in range(n)]
idx = {f: i for i, f in enumerate(frames)}


def at(frame):
    return snaps[max(0, min(n - 1, frame // 30 - 1))]


# Créditos: fichas em 600 e 700, start em 800.
print("== créditos (antes 590, depois da 1ª ficha 660, da 2ª 750, do start 900)")
a, b, c, e = at(570), at(660), at(750), at(900)
for off in range(65536):
    if b[off] == a[off] + 1 and c[off] == b[off] + 1 and e[off] == b[off]:
        print(hex(base + off), a[off], b[off], c[off], e[off])

# Vidas: na partida (depois do quadro 1500), poucos valores, só descidas de 1.
print("== vidas (descidas de 1, 2 a 5 mudanças)")
start = idx.get(1500, 49)
for off in range(65536):
    seq = [s[off] for s in snaps[start:]]
    changes = [(i, seq[i - 1], seq[i]) for i in range(1, len(seq)) if seq[i] != seq[i - 1]]
    if 1 <= len(changes) <= 5 and all(o - nw == 1 for _, o, nw in changes) and seq[0] <= 9:
        print(hex(base + off), "valores:", seq[0], "->", [(frames[start + i], nw) for i, _, nw in changes])


# Placar: 4 bytes BCD, nunca diminui na partida, muitas mudanças.
def bcd_ok(bs):
    return all((x >> 4) <= 9 and (x & 15) <= 9 for x in bs)


def bcd_val(bs):
    v = 0
    for x in bs:
        v = v * 100 + (x >> 4) * 10 + (x & 15)
    return v


print("== placar (BCD de 4 bytes, crescente)")
for off in range(0, 65536 - 4, 2):
    vals = []
    ok = True
    for s in snaps[start:]:
        bs = s[off:off + 4]
        if not bcd_ok(bs):
            ok = False
            break
        vals.append(bcd_val(bs))
    if not ok:
        continue
    ups = sum(1 for i in range(1, len(vals)) if vals[i] > vals[i - 1])
    downs = sum(1 for i in range(1, len(vals)) if vals[i] < vals[i - 1])
    if ups >= 10 and downs <= 1:
        print(hex(base + off), "ups", ups, "downs", downs, "amostra", vals[0], vals[len(vals) // 4], vals[len(vals) // 2], vals[-1])
