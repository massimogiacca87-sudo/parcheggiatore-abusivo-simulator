#!/usr/bin/env python3
"""Provini: mette tante foto piccole in un foglio solo, con il numero sopra.

uso: python3 tools/foto_provino.py '/tmp/vet_*.png' /tmp/provino_vetrine [colonne] [per_foglio]
Scrive /tmp/provino_vetrine_1.png, _2.png, ... (per guardarle tutte in poche
immagini invece che una per una).
"""
import glob
import sys

from PIL import Image, ImageDraw

schema = sys.argv[1]
uscita = sys.argv[2]
colonne = int(sys.argv[3]) if len(sys.argv) > 3 else 4
per_foglio = int(sys.argv[4]) if len(sys.argv) > 4 else 12

foto = sorted(glob.glob(schema))
if not foto:
    print("nisciuna foto")
    sys.exit(1)
L, A = 640, 380
for f0 in range(0, len(foto), per_foglio):
    gruppo = foto[f0:f0 + per_foglio]
    righe = (len(gruppo) + colonne - 1) // colonne
    foglio = Image.new("RGB", (colonne * L, righe * A), (20, 20, 24))
    d = ImageDraw.Draw(foglio)
    for i, f in enumerate(gruppo):
        im = Image.open(f).convert("RGB").resize((L, A))
        x, y = (i % colonne) * L, (i // colonne) * A
        foglio.paste(im, (x, y))
        d.rectangle([x, y, x + 64, y + 26], fill=(0, 0, 0))
        d.text((x + 6, y + 6), f.split("_")[-1].split(".")[0], fill=(255, 220, 90))
    nome = "%s_%d.png" % (uscita, f0 // per_foglio + 1)
    foglio.save(nome)
    print(nome)
