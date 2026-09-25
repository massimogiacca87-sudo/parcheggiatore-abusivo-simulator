#!/usr/bin/env python3
"""Rimette a posto i nomi delle texture, che erano ruotati fra loro.

## Cosa era successo

Le ventisette texture fotografiche sono state generate una per una e salvate
in `assets/textures/` coi nomi che il gioco si aspetta. In quel passaggio
qualcuna e' finita sotto il nome sbagliato — e non a caso: sono tre CICLI
chiusi, cioe' l'immagine A e' finita sul nome di B, quella di B sul nome di
C e cosi' via fino a tornare ad A. E' la firma di un salvataggio fatto in
blocco con l'elenco disallineato di una posizione.

Il gioco non aveva modo di accorgersene: chiedeva "piperno" e riceveva
un'immagine valida, solo che era di maioliche. Il risultato a schermo era
esattamente quello che si vede in partita e che non tornava:

  - gli zoccoli di pietra dei palazzi e i portali erano piastrellati di
    maioliche azzurre;
  - i marciapiedi erano d'asfalto sbriciolato;
  - il salotto di maioliche della piazza era di sanpietrini grigi;
  - i palazzoni degli anni Settanta erano di lamiera arrugginita, e i
    magazzini del porto erano piastrellati a mosaico.

## Come si e' riconosciuto quale e' quale

Guardandole. Ma una in particolare toglie ogni dubbio: il file salvato come
`asfalto.jpg` e' fatto di blocchi scuri con dentro delle scaglie chiare
angolose. Non e' asfalto, e' la descrizione testuale del PIPERNO —
"scattered pale angular inclusions in the dark matrix" — cioe' proprio il
prompt con cui era stata generata.

## Nota

Si passa da nomi temporanei: essendo cicli chiusi, rinominare in ordine
sovrascriverebbe un file che serve ancora due passi dopo.

I `.import` vecchi vanno cancellati: contengono il percorso sorgente e
l'impronta del file, e Godot non rigenera la texture se li trova coerenti.
"""

import os
import sys

CARTELLA = "assets/textures"

## sorgente -> nome giusto. Tre cicli chiusi.
RINOMINE = {
	# --- pavimentazioni: un ciclo di quattro ---
	"asfalto.jpg": "piperno.jpg",
	"marciapiede.jpg": "asfalto.jpg",
	"maioliche.jpg": "marciapiede.jpg",
	"piperno.jpg": "maioliche.jpg",
	# `basolato.jpg` era gia' al posto suo: e' l'unica del gruppo che si
	# salva, ed e' il motivo per cui il ciclo e' di quattro e non di cinque.

	# --- intonaci: un altro ciclo di quattro ---
	"muro_ocra.jpg": "muro_terracotta.jpg",
	"muro_rosa.jpg": "muro_ocra.jpg",
	"muro_terracotta.jpg": "muro_scrostato.jpg",
	"muro_scrostato.jpg": "muro_rosa.jpg",

	# --- e uno scambio semplice ---
	"muro_porto.jpg": "muro_zona_nuova.jpg",
	"muro_zona_nuova.jpg": "muro_porto.jpg",
}


def main() -> int:
	if not os.path.isdir(CARTELLA):
		print(f"non trovo {CARTELLA} — lanciami dalla radice del progetto",
			file=sys.stderr)
		return 1

	mancanti = [s for s in RINOMINE if not os.path.exists(f"{CARTELLA}/{s}")]
	if mancanti:
		print("mancano:", ", ".join(mancanti), file=sys.stderr)
		print("probabilmente i nomi sono gia' stati sistemati.", file=sys.stderr)
		return 1

	# Passo uno: tutti in un nome temporaneo.
	for sorgente in RINOMINE:
		os.rename(f"{CARTELLA}/{sorgente}", f"{CARTELLA}/__tmp__{sorgente}")

	# Passo due: dal temporaneo al nome giusto.
	for sorgente, giusto in RINOMINE.items():
		os.rename(f"{CARTELLA}/__tmp__{sorgente}", f"{CARTELLA}/{giusto}")
		print(f"  {sorgente:26s} -> {giusto}")

	# I .import delle coinvolte vanno via: Godot li rifa' al prossimo import.
	tolti = 0
	for nome in set(RINOMINE.keys()) | set(RINOMINE.values()):
		p = f"{CARTELLA}/{nome}.import"
		if os.path.exists(p):
			os.remove(p)
			tolti += 1
	print(f"\ntolti {tolti} file .import: rilancia")
	print("  godot4 --headless --path . --import")
	return 0


if __name__ == "__main__":
	sys.exit(main())
