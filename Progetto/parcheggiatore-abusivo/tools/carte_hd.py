#!/usr/bin/env python3
"""Le carte napoletane in alta definizione, per il tavolo della scopa (0.62).

Il capo: *«Migliora il minigioco di scopa con carte a miglior risoluzione»*.

L'atlante del 3D (`carte_napoletane.jpg`, celle da 104x168) era nato piccolo
per stare sotto un tetto di peso che non esiste più (la build adesso si
consegna a pezzi). Sul tavolo in 3D va ancora bene — le carte sono a un
metro — ma nel pannello della scopa una carta è alta 150-190 pixel, cioè
ingrandita, e si vedeva sfocata.

Questo script fa, dalla stessa scansione del capo
(`Texture/carte_napoletane___in_transparent_png_.png`, 4783x3029):

- `assets/ui/carte_hd.png`: atlante 10x4 con celle 240x390, angoli
  arrotondati trasparenti e un filo di bordo;
- `assets/ui/carta_retro.png`: il dorso, disegnato qui (rosso napoletano
  con la cornice e il rombo), della stessa misura.

Uso:  python3 tools/carte_hd.py /percorso/della/scansione.png
"""

import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

COLONNE, RIGHE = 10, 4
CW, CH = 240, 390
RAGGIO = 18
DEST = "assets/ui/carte_hd.png"
RETRO = "assets/ui/carta_retro.png"


def bande(profilo, quante):
	pieno = profilo > 0
	intervalli = []
	inizio = None
	for i, p in enumerate(pieno):
		if p and inizio is None:
			inizio = i
		elif not p and inizio is not None:
			intervalli.append((inizio, i))
			inizio = None
	if inizio is not None:
		intervalli.append((inizio, len(pieno)))
	intervalli.sort(key=lambda t: t[1] - t[0], reverse=True)
	intervalli = intervalli[:quante]
	intervalli.sort()
	return intervalli


def maschera_tonda(w, h, r, scala=4):
	m = Image.new("L", (w * scala, h * scala), 0)
	ImageDraw.Draw(m).rounded_rectangle((0, 0, w * scala - 1, h * scala - 1),
		r * scala, fill=255)
	return m.resize((w, h), Image.LANCZOS)


def carta(im, box):
	c = im.crop(box).convert("RGBA")
	# Fondo della carta: bianco caldo pieno (la scansione è trasparente
	# attorno, e dentro la carta il bianco è già bianco).
	fondo = Image.new("RGBA", c.size, (251, 249, 243, 255))
	fondo.alpha_composite(c)
	c = fondo.resize((CW, CH), Image.LANCZOS)
	c = c.filter(ImageFilter.UnsharpMask(radius=1.2, percent=60, threshold=2))
	# Bordo sottile grigio caldo, dentro all'angolo tondo.
	d = ImageDraw.Draw(c)
	d.rounded_rectangle((1, 1, CW - 2, CH - 2), RAGGIO - 1,
		outline=(120, 108, 92, 255), width=2)
	c.putalpha(maschera_tonda(CW, CH, RAGGIO))
	return c


def retro():
	s = 4
	w, h = CW * s, CH * s
	im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	d = ImageDraw.Draw(im)
	rosso = (168, 32, 34, 255)
	scuro = (112, 18, 22, 255)
	oro = (232, 190, 96, 255)
	d.rounded_rectangle((0, 0, w - 1, h - 1), RAGGIO * s, fill=(250, 246, 236, 255))
	m = 9 * s
	d.rounded_rectangle((m, m, w - 1 - m, h - 1 - m), (RAGGIO - 6) * s, fill=rosso)
	# Trama a rombi, ritagliata dentro al rosso.
	trama = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	dt = ImageDraw.Draw(trama)
	passo = 22 * s
	for y in range(-h, h * 2, passo):
		dt.line((m, y, w - m, y + (w - 2 * m)), fill=scuro, width=3 * s)
		dt.line((m, y + (w - 2 * m), w - m, y), fill=scuro, width=3 * s)
	taglio = Image.new("L", (w, h), 0)
	ImageDraw.Draw(taglio).rounded_rectangle((m, m, w - 1 - m, h - 1 - m),
		(RAGGIO - 6) * s, fill=255)
	trama.putalpha(Image.fromarray(np.minimum(np.asarray(trama.getchannel("A")),
		np.asarray(taglio))))
	im.alpha_composite(trama)
	d = ImageDraw.Draw(im)
	# Riquadro interno e rombo centrale.
	m2 = 22 * s
	d.rounded_rectangle((m2, m2, w - 1 - m2, h - 1 - m2), 10 * s, outline=oro,
		width=4 * s)
	cx, cy = w // 2, h // 2
	rw, rh = 62 * s, 96 * s
	d.polygon([(cx, cy - rh), (cx + rw, cy), (cx, cy + rh), (cx - rw, cy)],
		fill=rosso, outline=oro)
	d.polygon([(cx, cy - rh), (cx + rw, cy), (cx, cy + rh), (cx - rw, cy)],
		outline=oro, width=5 * s)
	rr = 26 * s
	d.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), fill=oro)
	rr2 = 17 * s
	d.ellipse((cx - rr2, cy - rr2, cx + rr2, cy + rr2), fill=scuro)
	im = im.resize((CW, CH), Image.LANCZOS)
	im.putalpha(Image.fromarray(np.minimum(np.asarray(im.getchannel("A")),
		np.asarray(maschera_tonda(CW, CH, RAGGIO)))))
	return im


def main():
	src = sys.argv[1] if len(sys.argv) > 1 else \
		"/mnt/user-data/uploads/Parcheggiatore Abusivo Simulator/Texture/carte_napoletane___in_transparent_png_.png"
	im = Image.open(src).convert("RGBA")
	a = np.asarray(im)
	inchiostro = (a[:, :, 3] > 40) & (a[:, :, :3].min(axis=2) < 250)
	# Le carte hanno il bordo: basta l'alfa per trovare i rettangoli.
	pieno = a[:, :, 3] > 40
	col = pieno.sum(axis=0)
	rig = pieno.sum(axis=1)
	col = np.where(col > pieno.shape[0] * 0.02, col, 0)
	rig = np.where(rig > pieno.shape[1] * 0.02, rig, 0)
	bx = bande(col, COLONNE)
	by = bande(rig, RIGHE)
	print(f"colonne {len(bx)} righe {len(by)}")
	if len(bx) != COLONNE or len(by) != RIGHE:
		# Ripiego: la scansione su fondo bianco (senza alfa).
		col = inchiostro.sum(axis=0)
		rig = inchiostro.sum(axis=1)
		bx = bande(np.where(col > 20, col, 0), COLONNE)
		by = bande(np.where(rig > 20, rig, 0), RIGHE)
		print(f"ripiego: colonne {len(bx)} righe {len(by)}")
		if len(bx) != COLONNE or len(by) != RIGHE:
			return 1
	atl = Image.new("RGBA", (CW * COLONNE, CH * RIGHE), (0, 0, 0, 0))
	for r, (y0, y1) in enumerate(by):
		for c, (x0, x1) in enumerate(bx):
			atl.alpha_composite(carta(im, (x0, y0, x1, y1)), (c * CW, r * CH))
	atl.save(DEST, optimize=True)
	retro().save(RETRO, optimize=True)
	import os
	print(f"{DEST} {atl.size} {os.path.getsize(DEST)//1024} kB; {RETRO}")
	return 0


if __name__ == "__main__":
	sys.exit(main())
