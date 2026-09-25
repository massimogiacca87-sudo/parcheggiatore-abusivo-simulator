#!/usr/bin/env python3
"""'E coppi (0.60): la texture dei tetti a falda, disegnata e non fotografata.

Fino alla 0.59 le falde usavano `tetti_italiani.jpg`, che doveva essere una
foto di coppi presa dall'alto e invece era un collage di fotografie aeree di
Venezia — palazzi, canali, barche, tutto rimpicciolito e ripetuto ogni due
metri e venti. Dalla strada non si vedeva quasi; dal Vomero, e in ogni foto
dall'alto, i tetti della città sembravano coriandoli.

Qui i coppi si disegnano: file di coppi (convessi, al sole) alternati ai
canali (concavi, in ombra), che scendono lungo la falda; ogni fila finisce
con l'ombra della fila di sopra che la copre; ogni coppo ha il suo colore di
cotto, qualcuno bruciato dal sole, qualcuno con il lichene grigio-giallo.
La texture si ripete senza cuciture (colonne e file sono un numero intero).

Il gioco la proietta dall'alto (`mappa_mondo`, vedi `intonaco.gdshader`),
quindi le colonne devono correre lungo la pendenza: `coppi.jpg` ha le
colonne verticali (per le falde che scendono lungo z), `coppi_x.jpg` è la
stessa girata di novanta gradi (per quelle che scendono lungo x).

Uso: python3 tools/genera_coppi.py   (scrive in assets/textures/)
"""
import math
import random

import numpy as np
from PIL import Image, ImageFilter

LATO = 1024
COLONNE = 16      # otto coppie coppo + canale su 2,2 m: 27 cm la coppia
FILE = 5          # cinque file da 44 cm
SEME = 60021

PALETTE = [
    (176, 84, 50), (160, 72, 44), (188, 98, 58), (146, 68, 46),
    (170, 90, 64), (154, 80, 52), (182, 104, 70), (138, 64, 42),
]


def rumore(shape, scala, rng):
    """Rumore liscio **che si ripete senza cucitura**: la griglia piccola si
    affianca tre volte per lato, si ingrandisce, e si tiene il riquadro di
    mezzo — così i bordi sanno cosa c'è dall'altra parte."""
    h, w = shape
    ph, pw = max(2, h // scala), max(2, w // scala)
    piccolo = np.tile(rng.random((ph, pw)), (3, 3))
    img = Image.fromarray((piccolo * 255).astype(np.uint8)).resize(
        (w * 3, h * 3), Image.BICUBIC)
    return np.asarray(img).astype(np.float32)[h:2 * h, w:2 * w] / 255.0


def main():
    rng = np.random.default_rng(SEME)
    rnd = random.Random(SEME)
    v, u = np.mgrid[0:LATO, 0:LATO].astype(np.float32)
    u /= LATO
    v /= LATO

    col = np.floor(u * COLONNE).astype(int)
    x = u * COLONNE - col                      # 0..1 dentro alla colonna
    coppo = (col % 2) == 1                     # le dispari stanno sopra

    # Ogni colonna ha la sua file un po' sfalsate (i coppi veri non sono
    # mai allineati al millimetro). Lo sfalsamento è in frazioni di fila,
    # quindi la texture resta ripetibile.
    sfal = np.array([rnd.uniform(-0.12, 0.12) for _ in range(COLONNE)],
                    dtype=np.float32)
    vv = v * FILE + sfal[col]
    fila = np.floor(vv).astype(int) % FILE
    y = vv - np.floor(vv)                      # 0 in cima al coppo

    # La forma: il coppo è una mezza canna al sole, il canale una mezza
    # canna rovesciata, più scura e un filo più larga di come si vede.
    s = np.sin(np.pi * x)
    luce_coppo = 0.62 + 0.42 * s + 0.10 * np.cos(np.pi * x)   # sole da un lato
    luce_canale = 0.40 + 0.22 * (1.0 - s) - 0.08 * np.cos(np.pi * x)
    luce = np.where(coppo, luce_coppo, luce_canale)
    # Il bordo del coppo proietta ombra nel canale accanto.
    bordo = np.where(coppo, 1.0, 0.72 + 0.28 * np.clip(np.abs(x - 0.5) * 2.2, 0, 1) ** 0.5)
    luce = luce * np.where(coppo, 1.0, 1.0) * np.where(coppo, 1.0, bordo)

    # La testa di ogni coppo: sotto alla fila di sopra c'è l'ombra, e il
    # labbro in fondo prende un filo di luce.
    ombra = 0.55 + 0.45 * np.clip(y / 0.14, 0, 1) ** 0.8
    labbro = 1.0 + 0.10 * np.clip((y - 0.93) / 0.07, 0, 1)
    luce = luce * ombra * labbro

    # Il colore di ogni coppo, dalla tavolozza del cotto.
    tinte = np.zeros((COLONNE, FILE, 3), dtype=np.float32)
    for c in range(COLONNE):
        for f in range(FILE):
            base = np.array(rnd.choice(PALETTE), dtype=np.float32)
            base *= rnd.uniform(0.86, 1.10)
            if rnd.random() < 0.12:            # bruciato
                base *= 0.72
            if rnd.random() < 0.10:            # sbiancato dal sole
                base = base * 0.8 + np.array([205, 170, 140]) * 0.2
            tinte[c, f] = base
    rgb = tinte[col, fila] * luce[..., None]

    # Il lichene e lo sporco: macchie grigio-gialle, soprattutto nei canali
    # dove l'acqua ristagna, e una grana fine su tutto.
    macchie = rumore((LATO, LATO), 48, rng)
    fini = rumore((LATO, LATO), 6, rng)
    lichene = np.clip((macchie - 0.70) * 3.5, 0, 1) * np.where(coppo, 0.45, 1.0)
    colore_lichene = np.array([118, 116, 86], dtype=np.float32)
    rgb = rgb * (1 - lichene[..., None] * 0.42) + colore_lichene * lichene[..., None] * 0.42
    rgb *= (0.90 + 0.20 * fini)[..., None]
    grana = rng.normal(0.0, 6.0, (LATO, LATO, 1)).astype(np.float32)
    rgb = np.clip(rgb + grana, 0, 255).astype(np.uint8)

    img = Image.fromarray(rgb, "RGB").filter(ImageFilter.GaussianBlur(0.6))
    img.save("assets/textures/coppi.jpg", quality=90)
    img.rotate(90, expand=True).save("assets/textures/coppi_x.jpg", quality=90)
    print("coppi.jpg e coppi_x.jpg: %d × %d" % (LATO, LATO))


if __name__ == "__main__":
    main()
