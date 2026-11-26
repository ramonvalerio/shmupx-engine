"""Gera as imagens do contador do Caravan (plugins/shmupx/caravana/*.png).

O contador fica no estilo dos placares de arcade: o rótulo TIME no ciano do ShmupX e os dígitos grandes
com degradê de branco para azul-claro e contorno escuro, na fonte do ShmupX Client (Share Tech).
O plugin desenha cada caractere como uma textura (sem custo de fonte a cada quadro).

Uso: python tools/caravana_glifos.py <ShareTech-Regular.ttf>
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

SAIDA = Path(__file__).resolve().parent.parent / "plugins" / "shmupx" / "caravana"
ALTURA_DIGITO = 128  # px do dígito (o plugin escala para o tamanho da janela)
CONTORNO = 9
DIGITO_TOPO, DIGITO_BASE = (255, 255, 255), (150, 190, 255)
# O ciano do ShmupX (--cyan do Client), sólido.
ROTULO_TOPO = ROTULO_BASE = (0x57, 0xFC, 0xFF)
CONTORNO_COR = (16, 14, 44, 255)


def degrade(tamanho, topo, base):
    largura, altura = tamanho
    img = Image.new("RGBA", tamanho)
    px = img.load()
    for y in range(altura):
        t = y / max(1, altura - 1)
        cor = tuple(round(a + (b - a) * t) for a, b in zip(topo, base)) + (255,)
        for x in range(largura):
            px[x, y] = cor
    return img


def glifo(texto, fonte, topo, base, largura_fixa=None):
    """Texto com contorno e preenchimento em degradê, na altura das maiúsculas/dígitos da fonte."""
    caixa = fonte.getbbox("0", stroke_width=CONTORNO)
    altura = caixa[3] - caixa[1]
    largura = largura_fixa or (fonte.getbbox(texto, stroke_width=CONTORNO)[2] - fonte.getbbox(texto, stroke_width=CONTORNO)[0])
    img = Image.new("RGBA", (largura, altura), (0, 0, 0, 0))
    desenho = ImageDraw.Draw(img)
    caixa_texto = fonte.getbbox(texto, stroke_width=CONTORNO)
    x = (largura - (caixa_texto[2] - caixa_texto[0])) // 2 - caixa_texto[0]
    y = -caixa[1]
    desenho.text((x, y), texto, font=fonte, fill=CONTORNO_COR, stroke_width=CONTORNO, stroke_fill=CONTORNO_COR)
    mascara = Image.new("L", img.size, 0)
    ImageDraw.Draw(mascara).text((x, y), texto, font=fonte, fill=255)
    img.paste(degrade(img.size, topo, base), (0, 0), mascara)
    return img


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    fonte_digito = ImageFont.truetype(sys.argv[1], round(ALTURA_DIGITO * 1.38))
    fonte_rotulo = ImageFont.truetype(sys.argv[1], round(ALTURA_DIGITO * 0.62))
    SAIDA.mkdir(parents=True, exist_ok=True)
    # Dígitos com a mesma largura: o contador não balança enquanto conta.
    largura_digito = max(fonte_digito.getbbox(d, stroke_width=CONTORNO)[2] - fonte_digito.getbbox(d, stroke_width=CONTORNO)[0] for d in "0123456789")
    for d in "0123456789":
        glifo(d, fonte_digito, DIGITO_TOPO, DIGITO_BASE, largura_digito).save(SAIDA / f"{d}.png", optimize=True)
    glifo("'", fonte_digito, DIGITO_TOPO, DIGITO_BASE).save(SAIDA / "minutos.png", optimize=True)
    glifo('"', fonte_digito, DIGITO_TOPO, DIGITO_BASE).save(SAIDA / "segundos.png", optimize=True)
    glifo("TIME", fonte_rotulo, ROTULO_TOPO, ROTULO_BASE).save(SAIDA / "time.png", optimize=True)
    print(f"glifos em {SAIDA}")


if __name__ == "__main__":
    main()
