#!/usr/bin/env python3
"""Ritaglia le 40 carte napoletane dal foglio unico e ne fa un atlante.

Il foglio che mi e' stato dato e' una scansione 4783x3029 con le quaranta
carte su una griglia 10x4, su fondo bianco: coppe, denari, bastoni, spade,
dall'asso al re.

## Perche' un atlante e non quaranta file

Quaranta JPEG vogliono dire quaranta risorse importate, quaranta materiali e
quaranta cambi di stato della GPU per disegnare un ventaglio di carte. Un
solo atlante 1280x832 e' UNA texture: il ventaglio del gioco delle tre carte,
la mano dei vecchi che giocano a scopa e il mazzo sul tavolino usano tutti lo
stesso materiale, e cambia solo l'offset delle UV.

## Come trova le carte

Non divide in dieci per quattro a occhio: le carte sulla scansione non sono
perfettamente equidistanti e un ritaglio a passo fisso mangerebbe il bordo di
qualcuna. Proietta il non-bianco sulle due assi, trova le bande vuote, e da
quelle ricava i confini reali di ogni riga e colonna.
"""

import sys
import numpy as np
from PIL import Image

SORGENTE = "/root/.claude/uploads/49ac95d1-b5fb-5d47-81ad-fe30c0296e44/383d4039-image.png"
DESTINAZIONE = "assets/textures/carte_napoletane.jpg"

COLONNE, RIGHE = 10, 4
# Ogni cella dell'atlante. Le carte vere hanno un rapporto di circa 1:1,63;
# 104x168 ci sta vicino.
#
# La misura non e' estetica, e' il limite del pacchetto. L'atlante e'
# l'immagine piu' grande del gioco e a 128x208 pesava 1,39 MB compressi in
# Basis: da sola mandava la build di Windows sopra il tetto dei 30 MiB.
# A 104x168 scende a poco piu' di 900 kB.
#
# Sotto non si puo' scendere: la carta piu' grande a schermo e' quella dei
# rulli della slot, larga 15 cm e guardata da ottanta centimetri, che a
# 1152 pixel di larghezza occupa circa 150 pixel. Con celle da 96 la si
# vedrebbe sfocata proprio nel momento in cui la stai fissando.
CELLA_W, CELLA_H = 104, 168

# Sopra questa luminanza e' fondo bianco.
BIANCO = 244


def bande(profilo: np.ndarray, quante: int) -> list:
	"""Da un profilo di 'quanto inchiostro c'e' in questa riga/colonna'
	ricava gli intervalli occupati. Tiene i `quante` piu' larghi: le
	scansioni hanno sempre qualche granello di sporco che diventerebbe una
	banda sua."""
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


def main() -> int:
	im = Image.open(SORGENTE).convert("RGB")
	a = np.asarray(im).astype(np.int16)
	inchiostro = (a.min(axis=2) < BIANCO)

	# Un pixel isolato non fa una carta: si chiede almeno l'uno per cento
	# della dimensione opposta.
	col = inchiostro.sum(axis=0)
	rig = inchiostro.sum(axis=1)
	col = np.where(col > inchiostro.shape[0] * 0.01, col, 0)
	rig = np.where(rig > inchiostro.shape[1] * 0.01, rig, 0)

	bx = bande(col, COLONNE)
	by = bande(rig, RIGHE)
	print(f"colonne trovate: {len(bx)}  righe trovate: {len(by)}")
	if len(bx) != COLONNE or len(by) != RIGHE:
		print("griglia non riconosciuta, mi fermo", file=sys.stderr)
		return 1

	atlante = Image.new("RGB", (CELLA_W * COLONNE, CELLA_H * RIGHE),
		(250, 248, 243))
	for r, (y0, y1) in enumerate(by):
		for c, (x0, x1) in enumerate(bx):
			# Un pelo di margine intorno: il bordo nero della carta e'
			# sottile e senza margine si perde nel ricampionamento.
			m = 2
			carta = im.crop((max(0, x0 - m), max(0, y0 - m),
				min(im.width, x1 + m), min(im.height, y1 + m)))
			carta = carta.resize((CELLA_W, CELLA_H), Image.LANCZOS)
			atlante.paste(carta, (c * CELLA_W, r * CELLA_H))

	atlante.save(DESTINAZIONE, quality=92, optimize=True)
	import os
	kb = os.path.getsize(DESTINAZIONE) / 1024.0
	print(f"scritto {DESTINAZIONE}  {atlante.width}x{atlante.height}  {kb:.0f} kB")
	return 0


if __name__ == "__main__":
	sys.exit(main())
