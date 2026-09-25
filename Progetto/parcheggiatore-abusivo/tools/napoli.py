#!/usr/bin/env python3
"""Prepara le texture di Napoli e Maradona per i muri della citta'.

Tre immagini vere, date da Massimo, piu' due generate qui.

## Le tre vere

- `murale_maradona.jpg` — il murale del dieci di spalle col cuore rosso.
  Va su un pannello verticale in un vicolo.
- `murale_pulcinella.jpg` — il Pulcinella coi tag intorno.
- `stencil_maradona.png` — la faccia in bianco e nero. Questa e' l'unica che
  serve **con la trasparenza**: e' uno stencil, la bomboletta lascia il nero
  e il muro sotto si vede. Il file di partenza e' un JPEG nero su bianco,
  quindi il canale alfa si ricava dalla luminanza invertita, ed e' anche il
  motivo per cui il ritaglio va fatto qui e non a occhio in Godot: un JPEG
  bianco appiccicato su un muro ocra sarebbe un rettangolo bianco.

## Le due generate

- `bandiera_napoli.png` — il gagliardetto azzurro delle bandierine tirate
  da un balcone all'altro. Piccolo, con l'alfa.
- `sciarpa_napoli.jpg` — la sciarpa a righe azzurre da stendere sui balconi.

Tutte quadrate o quasi, senza ombre dipinte: il sole ce lo mette il motore.
"""

import os
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SRC = "/root/.claude/uploads/49ac95d1-b5fb-5d47-81ad-fe30c0296e44"
DST = "assets/textures"

AZZURRO = (18, 106, 182)
AZZURRO_CHIARO = (42, 148, 226)


def _riquadra(im: Image.Image, lato_x: int, lato_y: int) -> Image.Image:
	"""Ritaglia al centro sul rapporto voluto e ridimensiona. Meglio
	tagliare che deformare: un murale schiacciato si nota subito."""
	r_vuole = lato_x / lato_y
	r_ha = im.width / im.height
	if r_ha > r_vuole:
		w = int(im.height * r_vuole)
		im = im.crop(((im.width - w) // 2, 0, (im.width + w) // 2, im.height))
	else:
		h = int(im.width / r_vuole)
		im = im.crop((0, (im.height - h) // 2, im.width, (im.height + h) // 2))
	return im.resize((lato_x, lato_y), Image.LANCZOS)


def murale_maradona() -> None:
	im = Image.open(f"{SRC}/dde38da5-image.jpg").convert("RGB")
	# Si taglia via la colonna di pietra a sinistra e il mattone a destra.
	# Nella foto originale ci sono, e in un gioco diventano un problema: il
	# pannello del murale finisce su un muro che ha GIA' la sua texture, e
	# due muri diversi uno dentro l'altro si vedono come un adesivo. Con il
	# ritaglio stretto resta l'intonaco chiaro, che si confonde molto meglio
	# con l'intonaco del palazzo su cui è appeso.
	im = im.crop((int(im.width * 0.13), int(im.height * 0.06),
		int(im.width * 0.87), int(im.height * 0.97)))
	_riquadra(im, 384, 512).save(f"{DST}/murale_maradona.jpg", quality=90,
		optimize=True)


def murale_pulcinella() -> None:
	im = Image.open(f"{SRC}/7f2ac384-image.jpg").convert("RGB")
	_riquadra(im, 512, 384).save(f"{DST}/murale_pulcinella.jpg", quality=90,
		optimize=True)


def stencil_maradona() -> None:
	im = Image.open(f"{SRC}/b9861d4e-image.jpg").convert("L")
	im = _riquadra(im, 256, 320)
	a = np.asarray(im).astype(np.float32) / 255.0
	# Nero pieno = vernice, bianco = muro nudo. La soglia morbida (invece di
	# un taglio netto) tiene il bordo antialiasato: uno stencil con i bordi
	# a scaletta si vede da dieci metri.
	alfa = np.clip((0.62 - a) / 0.24, 0.0, 1.0)
	rgb = np.zeros((im.height, im.width, 3), dtype=np.uint8)
	# Non nero assoluto: la vernice spray su intonaco resta un grigio molto
	# scuro, e il nero puro in un motore con luce indiretta sembra un buco.
	rgb[:, :, :] = (26, 24, 26)
	out = np.dstack([rgb, (alfa * 255).astype(np.uint8)])
	Image.fromarray(out, "RGBA").save(f"{DST}/stencil_maradona.png",
		optimize=True)


def bandiera_napoli() -> None:
	"""Il gagliardetto triangolare delle bandierine tese fra i balconi.
	Il triangolo sta nella meta' alta: sotto e' trasparente."""
	w, h = 128, 128
	im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	d = ImageDraw.Draw(im)
	d.polygon([(4, 4), (w - 4, 4), (w // 2, h - 6)], fill=AZZURRO + (255,))
	# Il tondino bianco con la N: da lontano e' un puntino chiaro, ed e'
	# esattamente quello che si vede di un gagliardetto vero.
	d.ellipse([w // 2 - 22, 20, w // 2 + 22, 64], fill=(244, 244, 240, 255))
	d.line([(w // 2 - 9, 56), (w // 2 - 9, 28), (w // 2 + 9, 56),
		(w // 2 + 9, 28)], fill=AZZURRO + (255,), width=6)
	im.save(f"{DST}/bandiera_napoli.png", optimize=True)


def sciarpa_napoli() -> None:
	"""La sciarpa a righe, stesa sulla ringhiera. Affiancabile in
	orizzontale: le righe corrono per il lungo."""
	w, h = 256, 256
	a = np.zeros((h, w, 3), dtype=np.float32)
	for y in range(h):
		# Righe azzurre di larghezza diversa: una sciarpa non e' un codice
		# a barre regolare.
		f = (y / h) * 7.0
		t = f - int(f)
		c = AZZURRO if int(f) % 2 == 0 else AZZURRO_CHIARO
		if t < 0.06 or t > 0.94:
			c = (232, 236, 240)
		a[y, :, :] = c
	# Grana di lana: rumore fine, piu' scuro nelle pieghe. Serve allo shader
	# dell'intonaco, che ricava il rilievo dalla luminanza.
	rng = np.random.default_rng(7)
	grana = rng.normal(0.0, 9.0, (h, w, 1))
	trama = np.sin(np.arange(w) * 1.7)[None, :, None] * 4.0
	a = np.clip(a + grana + trama, 0, 255).astype(np.uint8)
	im = Image.fromarray(a, "RGB").filter(ImageFilter.GaussianBlur(0.4))
	im.save(f"{DST}/sciarpa_napoli.jpg", quality=90, optimize=True)


def main() -> int:
	os.makedirs(DST, exist_ok=True)
	for f in (murale_maradona, murale_pulcinella, stencil_maradona,
			bandiera_napoli, sciarpa_napoli):
		f()
		nome = f.__name__
		for est in ("jpg", "png"):
			p = f"{DST}/{nome}.{est}"
			if os.path.exists(p):
				print(f"  {p}  {os.path.getsize(p) / 1024:.0f} kB")
	return 0


if __name__ == "__main__":
	sys.exit(main())
