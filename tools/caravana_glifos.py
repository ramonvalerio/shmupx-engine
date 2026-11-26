"""Gera as imagens do contador do Caravan (plugins/shmupx/caravana/*.png).

O contador fica no estilo dos placares de arcade: o rótulo TIME no vermelho do ShmupX e os dígitos
grandes em branco, sólidos e com contorno escuro, na fonte do ShmupX Client (Share Tech). Padrão do
painel de resultado: rótulo em azul (ciano do ShmupX) e valor em branco.
Também gera os textos do cartão de resultado (GAME MODE, PONTOS, VIDAS PERDIDAS, em português e inglês).
O plugin desenha cada caractere como uma textura (sem custo de fonte a cada quadro).

Uso: python tools/caravana_glifos.py <ShareTech-Regular.ttf>
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

SAIDA = Path(__file__).resolve().parent.parent / "plugins" / "shmupx" / "caravana"
ALTURA_DIGITO = 128  # px do dígito (o plugin escala para o tamanho da janela)
CONTORNO = 9
# As cores sólidas do ShmupX Client: o ciano (--cyan) nos números e o vermelho nos rótulos de destaque.
CIANO = (0x57, 0xFC, 0xFF)
VERMELHO = (0xFD, 0x48, 0x51)
BRANCO = (0xF0, 0xFC, 0xFF)
DIGITO_TOPO = DIGITO_BASE = (255, 255, 255)
ROTULO_TOPO = ROTULO_BASE = VERMELHO
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
    glifo(".", fonte_digito, DIGITO_TOPO, DIGITO_BASE).save(SAIDA / "ponto.png", optimize=True)
    glifo("-", fonte_digito, DIGITO_TOPO, DIGITO_BASE).save(SAIDA / "traco.png", optimize=True)
    glifo("TIME", fonte_rotulo, ROTULO_TOPO, ROTULO_BASE).save(SAIDA / "time.png", optimize=True)
    # Resultado do fim do Caravan (o jogo pausa e mostra os pontos e as vidas perdidas).
    # Modo da partida: o rótulo GAME MODE em ciano e o modo grande em branco, como os números.
    for nome, texto in (("caravan", "CARAVAN"), ("hiscore", "HI-SCORE"), ("hiscore_1cc", "HI-SCORE/1CC")):
        glifo(texto, fonte_digito, DIGITO_TOPO, DIGITO_BASE).save(SAIDA / f"valor_{nome}.png", optimize=True)
    # Rótulos do resultado em azul, no idioma do Client (SHMUPX_IDIOMA: pt ou en): caravana/<idioma>/.
    textos = {
        "pt": {"game_mode": "MODO DE JOGO", "pontos": "PONTOS", "vidas_perdidas": "VIDAS PERDIDAS"},
        "en": {"game_mode": "GAME MODE", "pontos": "POINTS", "vidas_perdidas": "LIVES LOST"},
    }
    for idioma, rotulos in textos.items():
        (SAIDA / idioma).mkdir(exist_ok=True)
        for nome, texto in rotulos.items():
            glifo(texto, fonte_rotulo, CIANO, CIANO).save(SAIDA / idioma / f"{nome}.png", optimize=True)
    print(f"glifos em {SAIDA}")


if __name__ == "__main__":
    main()
