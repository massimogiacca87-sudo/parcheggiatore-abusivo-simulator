"""'E ddoje ultime: 'o Super Santos e 'a BMW E46.

Sono rimaste per ultime perché stavano nascoste — la palla dentro a un
`.blend` che si chiama `supersantos.blend` e basta, la E46 dentro al
pacchetto della città modulare, in mezzo a cinquecento pezzi di strada.

    python3 tools/build_extra.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy                                    # noqa: E402
import blender_comune as C                    # noqa: E402

FONTE = "/tmp/mod"
USCITA = os.path.join(os.path.dirname(os.path.dirname(
    os.path.abspath(__file__))), "assets", "models")


def super_santos():
    """**'O Super Santos.**

    Se c'è un oggetto solo che dice "strada italiana, pomeriggio, ragazzini"
    è questa: la palla di plastica arancione da due euro e cinquanta, con
    le stelle nere stampate sopra, che ogni tanto finisce sotto a una
    macchina e scoppia.

    **E po' s'è scarrupata pure chesta.** Convertita, misurata, alleggerita
    — e poi buttata, perché il Super Santos nel gioco **ci sta già**: alla
    0.29 avevo tirato fuori da questo stesso archivio la texture
    `supersantos.jpg` e l'avevo messa su una sfera procedurale. Il pallone
    dei ragazzini e quello che calcia il giocatore hanno la livrea vera —
    arancione, losanghe nere, scritta — da otto versioni.

    Il modello vero costa 4.864 triangoli e 300 KB; la sfera con la stessa
    texture ne costa 240 e 40 KB, e a due metri sono identici. Un modello
    che non aggiunge niente a quello che c'è già non si mette dentro solo
    perché sta nella cartella: si butta, come `car_bolla` alla 0.46.

    La funzione resta perché il confronto è il motivo, e se un giorno
    servisse un pallone sgonfio da appoggiare su un cornicione, il modello
    si rifà con una riga.
    """
    print("  -- super_santos: scartato, 'a livrea sta già dinto ô gioco")
    return
    b = os.path.join(FONTE, "super-santos/source/supersantos.blend")
    if not os.path.exists(b):
        print("  !! Super Santos: niente .blend")
        return
    C.pulisci()
    C.importa(b)
    C.butta(["plane", "ground", "floor", "backdrop", "studio", "camera",
             "light", "area", "sun", "lamp"])
    if not C.mesh_scena():
        print("  !! Super Santos: non è rimasto niente")
        return
    # La texture è **tutta** la palla: senza le stelle nere è un pallone
    # arancione qualunque. A 512 pesava 437 KB per una
    # palla che sta in un angolo di piazza: a 256 le stelle si vedono
    # lo stesso e costa un quarto.
    C.attacca_texture(os.path.join(FONTE,
        "super-santos/textures/santos_diffuse.png"))
    C.raddrizza(su="Z", avanti="-Y")
    C.in_metri(altezza=0.22)          # misura vera del Super Santos
    C.a_terra()
    C.alleggerisci(900)
    C.riduci_texture(256)
    C.esporta(os.path.join(USCITA, "super_santos.glb"))


def bmw_e46():
    """**'A E46.** Stava dentro al pacchetto della città modulare, appesa
    a un nodo che si chiama `BMW_E46.obj.cleaner.materialmerger.gles` —
    cioè il nome che ti resta addosso dopo tre conversioni automatiche.

    Serve perché la fascia "bmw" del gioco è quella del tipo che parcheggia
    in doppia fila e ti guarda male: una E46 nera è esattamente quella
    macchina, molto più di una supercar da centomila euro."""
    p = os.path.join(FONTE,
                     "neighbourhood-city-modular-lowpoly/source/Untitled.glb")
    if not os.path.exists(p):
        print("  !! E46: pacchetto non trovato")
        return
    C.pulisci()
    C.importa(p)
    # Trentasette mega di città modulare per una macchina: si tiene solo
    # l'oggetto appeso al nodo della BMW e si butta tutto il resto — le
    # strade, i palazzi, i marciapiedi, i seicento pezzi che non servono.
    voluti = set()
    for o in bpy.data.objects:
        p2 = o.parent
        while p2 is not None:
            if p2.name.startswith("BMW_E46"):
                voluti.add(o.name)
                break
            p2 = p2.parent
    if not voluti:
        print("  !! E46: nodo non trovato dentro al pacchetto")
        return
    for o in list(bpy.data.objects):
        if o.name not in voluti:
            bpy.data.objects.remove(o, do_unlink=True)
    C.raddrizza(su="Z", avanti="-Y")
    C.in_metri(lunghezza=4.47)        # E46 berlina, misura di serie
    C.a_terra()
    C.rinomina_materiali()
    # **'O materiale se chiamma `Standard_00FD5B` e chesto è nu problema.**
    #
    # Tutta la macchina — carrozzeria, vetri, gomme, fanali — sta sotto a un
    # materiale solo, e `Models.tint` cerca "body"/"carroz"/"scocca": non
    # trovando niente non verniciava, e ogni E46 usciva **dello stesso
    # colore**. Che di per sé sarebbe brutto e basta; il guaio vero è che
    # `colore_id()` il colore lo assegna lo stesso, quindi la bacheca poteva
    # ordinarti "'na E46 blu" e mandarti davanti a una grigia.
    #
    # La texture però è **in bianco e nero**: carrozzeria grigio medio,
    # gomme e vetri quasi neri, e due fanali rossi grandi come un'unghia.
    # `albedo_color` in Godot MOLTIPLICA la texture, quindi basta chiamare
    # il materiale `body` e la tinta viene giusta da sola: la scocca prende
    # il colore, le gomme restano nere perché nero per qualunque cosa fa
    # nero. È il caso fortunato, e vale la pena scriverlo perché con una
    # texture a colori questo trucco non funzionerebbe.
    for o in C.mesh_scena():
        for s in o.material_slots:
            if s.material is not None:
                s.material.name = "body"
    C.alleggerisci(4500)
    C.riduci_texture(384)
    C.esporta(os.path.join(USCITA, "car_e46.glb"))




def fiat_500():
	"""**'A Cinquecento.**

	Se una macchina sola deve dire "Italia", è questa — e a Napoli ce n'è
	una parcheggiata in ogni vicolo. Arriva come `Outlaw500_cables.fbx`:
	un modello da vetrina, con i cavi del motore modellati uno per uno e
	texture da 4K. Qui diventa una macchina da strada.
	"""
	p = os.path.join(FONTE, "fiat500/source/Outlaw500_cables.fbx")
	if not os.path.exists(p):
		print("  !! 500: nun truvata")
		return
	C.pulisci()
	C.importa(p)
	C.butta(["plane", "ground", "floor", "backdrop", "studio", "camera",
			 "light", "cable", "wire", "engine"])
	C.butta_piccoli(30)
	if not C.mesh_scena():
		print("  !! 500: nun è rimasto niente")
		return
	C.texture_da_cartella(os.path.join(FONTE, "fiat500/textures"))
	C.raddrizza(su="Z", avanti="-Y")
	# La 500 vera è lunga 2,97: è la macchina più corta della città, e si
	# deve vedere che in un posto auto ci sta larga.
	C.in_metri(lunghezza=2.97)
	C.a_terra()
	C.rinomina_materiali()
	C.alleggerisci(6000)
	C.riduci_texture(384)
	C.esporta(os.path.join(USCITA, "car_500.glb"))


if __name__ == "__main__":
	for f in (super_santos, bmw_e46, fiat_500):
		try:
			f()
		except Exception as e:                       # noqa: BLE001
			print("  !! %s: %s" % (f.__name__, e))
