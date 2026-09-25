#!/usr/bin/env python3
"""'A tinta 'e Pandazole (0.59).

L'atlante dei colori del pacchetto Pandazole e' fatto di colori pieni da
cartone animato: messi in una citta' fatta di fotografie di intonaco,
tufo e basolato, i pezzi sembravano giocattoli appoggiati sopra. Qui si
abbassa la saturazione di un quinto abbondante e si scurisce appena, cosi'
la frutta resta frutta e il cassonetto resta blu, ma parlano la stessa
lingua dei muri.

Uso: python3 tools/tinge_pandazole.py originale.png uscita.png
"""
import sys
import colorsys
from PIL import Image

SATURAZIONE = 0.76
LUCE = 0.95

def main(da, a):
    im = Image.open(da).convert("RGB")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            hh, ss, vv = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
            ss *= SATURAZIONE
            vv *= LUCE
            r2, g2, b2 = colorsys.hsv_to_rgb(hh, ss, vv)
            px[x, y] = (int(round(r2 * 255)), int(round(g2 * 255)), int(round(b2 * 255)))
    im.save(a)

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
