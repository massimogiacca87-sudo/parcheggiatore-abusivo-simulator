"""'A bacheca nova, chella ca 'o capo ha miso dint'â cartella.

Il capo: *"La bacheca non esiste, è solo un raggio luminoso. Usa il modello
nuovo che ti ho messo."*

Quella vecchia era costruita a mano con dei parallelepipedi, e da lontano —
con la sua luce accesa sopra — si leggeva solo come un bagliore. Questa è un
modello vero fatto in Blockbench: novantasei vertici, tutta a scatole, ed è
esattamente lo stile giusto per questo gioco.

Arriva senza `.mtl`, quindi i colori vanno messi qui. Non ci sono nomi da
riconoscere (i materiali si chiamano con degli UUID), e allora si va per
**quota**: i pali sotto sono legno scuro, il pannello sopra è sughero, la
cornice attorno è legno chiaro.

    python3 tools/build_bacheca.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy                                    # noqa: E402
import blender_comune as C                    # noqa: E402

FONTE = "/tmp/bach/source/sign.obj"
USCITA = os.path.join(os.path.dirname(os.path.dirname(
    os.path.abspath(__file__))), "assets", "models", "bacheca.glb")

## Misure vere di una bacheca da piazza: alta un metro e ottanta col palo,
## il pannello largo un metro e trenta.
ALTEZZA = 1.62


def _mat(nome, colore, ruvido=0.9):
	m = bpy.data.materials.get(nome) or bpy.data.materials.new(nome)
	m.use_nodes = True
	b = m.node_tree.nodes.get("Principled BSDF")
	if b is not None:
		b.inputs["Base Color"].default_value = (*colore, 1.0)
		b.inputs["Roughness"].default_value = ruvido
		b.inputs["Metallic"].default_value = 0.0
	return m


def main():
	if not os.path.exists(FONTE):
		print("  !! bacheca: %s nun ce sta" % FONTE)
		return
	C.pulisci()
	C.importa(FONTE)
	# **L'assi giusti, truvate a furia 'e renderizzà.** Con `su="Z"` e
	# `avanti="-Y"` il pannello guarda verso Blender +Y, che l'esportatore
	# manda in Godot su −Z: cioè esattamente la direzione "avanti" del
	# gioco. Così la bacheca guarda dove la gira il codice, senza mezzo
	# giro di correzione.
	C.raddrizza(su="Z", avanti="-Y")
	C.in_metri(altezza=ALTEZZA)
	C.a_terra()

	ogg = C.mesh_scena()
	if not ogg:
		print("  !! bacheca: nun è rimasto niente")
		return

	# **'O modello arriva spaccato in dodici oggette.** Blockbench esporta
	# un `.obj` con un materiale per pezzo, e l'importatore ne fa dodici
	# mesh separate. Al primo giro coloravo solo la prima e le altre undici
	# restavano al grigio di scorta: in gioco la bacheca usciva **tutta
	# bianca**, che è più o meno il "raggio luminoso" da cui si partiva.
	mats = []
	for n, c, r in [("legno_bacheca", (0.44, 0.29, 0.17), 0.92),
			("palo_bacheca", (0.27, 0.18, 0.11), 0.94),
			("sughero", (0.74, 0.56, 0.33), 0.96)]:
		mats.append(_mat(n, c, r))

	# Il pannello di sughero è la faccia che guarda avanti ed è **infossata**
	# dentro alla cornice: si riconosce così, non per quota. La soglia si
	# calcola su TUTTI i pezzi insieme, se no ogni pezzo si crede il fronte.
	y_max = -1e9
	for o in ogg:
		for f in o.data.polygons:
			if f.normal.y > 0.5:
				c = sum((o.data.vertices[i].co for i in f.vertices),
					C.Vector((0, 0, 0))) / len(f.vertices)
				y_max = max(y_max, c.y)

	for o in ogg:
		o.data.materials.clear()
		for m in mats:
			o.data.materials.append(m)
		for f in o.data.polygons:
			c = sum((o.data.vertices[i].co for i in f.vertices),
				C.Vector((0, 0, 0))) / len(f.vertices)
			if f.normal.y > 0.5 and c.y < y_max - 0.015:
				f.material_index = 2
			elif c.z < 0.42:
				f.material_index = 1
			else:
				f.material_index = 0

	C.esporta(USCITA)


if __name__ == "__main__":
	main()
