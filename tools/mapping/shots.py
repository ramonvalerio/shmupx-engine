"""Monta as telas da descoberta (shot_*.raw, ARGB 32 bits) numa grade PNG para ler placar e vidas.

  shots.py <pasta> <saida.png> [de] [até] [colunas] [escala]   (ROT=90 no ambiente gira os jogos verticais)
"""
import sys, glob, re, os
import numpy as np
from PIL import Image, ImageDraw
d, outp = sys.argv[1], sys.argv[2]
lo = int(sys.argv[3]) if len(sys.argv) > 3 else 0
hi = int(sys.argv[4]) if len(sys.argv) > 4 else 10**9
cols = int(sys.argv[5]) if len(sys.argv) > 5 else 6
scale = float(sys.argv[6]) if len(sys.argv) > 6 else 1.0
items = []
for f in glob.glob(os.path.join(d, "shot_*.raw")):
    m = re.search(r"shot_(\d+)_(\d+)x(\d+)", f)
    fr, w, h = map(int, m.groups())
    if lo <= fr <= hi: items.append((fr, w, h, f))
items.sort()
imgs = []
for fr, w, h, f in items:
    a = np.frombuffer(open(f, "rb").read(), dtype=np.uint8)
    if a.size < w*h*4: continue
    a = a[:w*h*4].reshape(h, w, 4)
    im = Image.fromarray(a[:, :, [2, 1, 0]].copy())
    rot = int(os.environ.get("ROT", "0"))
    if rot: im = im.rotate(rot, expand=True)
    if scale != 1.0: im = im.resize((int(im.size[0]*scale), int(im.size[1]*scale)))
    ImageDraw.Draw(im).text((2, 2), str(fr), fill=(255, 255, 0))
    imgs.append(im)
if not imgs: sys.exit("nenhuma tela")
W, H = imgs[0].size
rows = (len(imgs) + cols - 1) // cols
g = Image.new("RGB", (W*cols, H*rows))
for i, im in enumerate(imgs): g.paste(im, ((i % cols)*W, (i//cols)*H))
g.save(outp)
print(len(imgs), "telas", g.size)
