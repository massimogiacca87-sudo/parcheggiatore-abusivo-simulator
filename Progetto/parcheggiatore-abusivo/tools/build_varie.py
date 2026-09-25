"""'O rimanente: 'o motorino, 'o bar, l'armiere, l'arco d''o vicolo.

Ognuno di questi arriva in un formato diverso e con un difetto diverso, e
il commento sopra a ogni funzione dice qual è. È la parte noiosa del lavoro
sui modelli comprati, ed è anche quella che, se la salti, ti ritrovi in
piazza una macchina bianca senza normali per venti build.

    python3 tools/build_varie.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy                                    # noqa: E402
import blender_comune as C                    # noqa: E402

FONTE = "/tmp/mod"
USCITA = os.path.join(os.path.dirname(os.path.dirname(
    os.path.abspath(__file__))), "assets", "models")


def motorino():
    """'O motorino nuovo. Arriva in `.3DS`, che è un formato del 1990 e
    che Godot non apre: si converte qui una volta sola.

    Il vecchio `motorino.obj` resta dov'è — quello è la Vespa ferma
    parcheggiata, questo è lo scooter che ti passa addosso."""
    # **'O 3DS Blender nun 'o sape cchiù apri'.** L'importatore c'era fino
    # alla 3.x, nella build che gira qui non c'è più, e non si può
    # nemmeno riabilitare (il modulo `io_scene_3ds` non è installato).
    # Si passa da `assimp`, che il 3DS lo legge ancora e lo sputa in OBJ:
    #     assimp export 92motor-scooter.3DS scooter.obj
    obj = os.path.join(FONTE, "92motor-scooter/scooter.obj")
    if not os.path.exists(obj):
        os.system('assimp export "%s" "%s" >/dev/null 2>&1' % (
            os.path.join(FONTE, "92motor-scooter/92motor-scooter.3DS"), obj))
    if not os.path.exists(obj):
        print("  !! motorino: assimp non ha convertito il 3DS")
        return
    C.pulisci()
    C.importa(obj)
    C.butta_piccoli(4)
    C.raddrizza(su="Z", avanti="-Y")
    C.in_metri(lunghezza=1.85)
    C.a_terra()
    C.rinomina_materiali()
    C.alleggerisci(4000)
    C.riduci_texture(512)
    C.esporta(os.path.join(USCITA, "scooter.glb"))


def fucile():
    """Pe' ll'armiere. Uno scan vero di un fucile da caccia arrugginito:
    a due metri di distanza dietro a un banco non serve la normale da 16
    mega, serve la sagoma."""
    C.pulisci()
    C.importa(os.path.join(FONTE,
              "rusty-italian-hunting-shotgun/source/x/model/model.dae"))
    C.attacca_texture(os.path.join(FONTE,
        "rusty-italian-hunting-shotgun/textures/shottygunny_albedo.jpeg"))
    C.butta_piccoli(4)
    C.raddrizza(su="Z", avanti="-Y")
    C.in_metri(lunghezza=1.15)
    C.a_terra()
    C.alleggerisci(2500)
    C.riduci_texture(512)
    C.esporta(os.path.join(USCITA, "fucile.glb"))


def bar_colazione():
    """'A culazione: cappuccino, cornetti, bicchieri, tazze.

    Il modello arriva a scala sbagliata — un cappuccino largo due metri e
    ottanta — e con un piano da nove metri sotto che è lo sfondo dello
    studio fotografico. Si butta il piano e si porta la tazza alla misura
    di una tazza."""
    C.pulisci()
    C.importa(os.path.join(FONTE, "italian-breakfast/source/ItalianBreakfast.fbx"))
    # `Plane.002` è lo sfondo (25.088 triangoli di niente), `tabble` il
    # tavolo da vetrina: al banco di 'O Zio il tavolo ce l'abbiamo già.
    C.butta(["plane", "tabble", "smoke"])
    C.butta_piccoli(8)
    # Nove materiali (cacao, cappuccino, croisant, glassCup...) e nove PNG
    # che si chiamano quasi come loro: si accoppiano per somiglianza.
    C.texture_da_cartella(os.path.join(FONTE, "italian-breakfast/textures"))
    if not C.mesh_scena():
        print("  !! colazione: non è rimasto niente")
        return
    C.raddrizza(su="Z", avanti="-Y")
    C.in_metri(altezza=0.26)      # il gruppo intero alto come una caraffa
    C.a_terra()
    C.alleggerisci(4000)
    C.riduci_texture(256)
    C.esporta(os.path.join(USCITA, "colazione.glb"))


def macchina_caffe():
    """'A machinetta d''o bar. Cinquanta mega di `.blend` con texture da
    10K: qui diventa un oggetto da mezzo metro che sta su un banco."""
    d = os.path.join(FONTE, "italian-coffee-machine/source")
    b = [os.path.join(d, f) for f in os.listdir(d) if f.endswith(".blend")]
    if not b:
        print("  !! macchina caffè: nessun .blend")
        return
    C.pulisci()
    C.importa(b[0])
    C.butta(["plane", "floor", "ground", "backdrop", "studio", "camera",
             "light", "area", "sun"])
    C.butta_piccoli(8)
    if not C.mesh_scena():
        print("  !! macchina caffè: non è rimasto niente")
        return
    C.raddrizza(su="Z", avanti="-Y")
    C.in_metri(altezza=0.52)
    C.a_terra()
    C.alleggerisci(5000)
    C.riduci_texture(384)
    C.esporta(os.path.join(USCITA, "macchina_caffe.glb"))


def panino():
    """'O panino d''o bar. Cinquanta kilobyte di FBX e undici mega di
    texture: la texture è tutta la sostanza, quindi si tiene a 512."""
    C.pulisci()
    C.importa(os.path.join(FONTE,
              "italian-sandwich-scan-lowpoly/source/x/SwandwichLOW.fbx"))
    C.butta_piccoli(4)
    C.raddrizza(su="Z", avanti="-Y")
    C.in_metri(lunghezza=0.16)
    C.a_terra()
    C.riduci_texture(384)
    C.esporta(os.path.join(USCITA, "panino.glb"))


def arco():
    """L'arco d''o vicolo. È uno scan vero da centotrentadue mega e
    duecentomila triangoli: alleggerito a quattromila diventa il pezzo che
    a Napoli ti dice che stai entrando in un quartiere vecchio."""
    p = os.path.join(FONTE,
                     "medieval-arch-13th-century-rawscan/source/x/arco/arco.obj")
    if not os.path.exists(p):
        print("  !! arco: non trovato")
        return
    C.pulisci()
    C.importa(p)
    # Il `.mtl` dice `map_Kd arco.jpg` ma il file sta in `textures/`:
    # Blender non lo trova e lo scan viene fuori bianco.
    C.attacca_texture(os.path.join(os.path.dirname(p), "textures", "arco.jpg"))
    C.raddrizza(su="Z", avanti="-Y")
    C.in_metri(altezza=5.20)
    C.a_terra()
    C.alleggerisci(4000)
    C.riduci_texture(1024)
    C.esporta(os.path.join(USCITA, "arco_vicolo.glb"))


def vaso_antico():
    """'A giara. Un'anfora scansionata: sta bene sul banco dell'antiquario
    o in un angolo di piazza."""
    d = os.path.join(FONTE, "hydria-apothecary-vase/source/x")
    p = None
    for r, _dirs, files in os.walk(d):
        for f in files:
            if f.lower().endswith(".obj"):
                p = os.path.join(r, f)
    if p is None:
        print("  !! giara: non trovata")
        return
    C.pulisci()
    C.importa(p)
    C.attacca_texture(os.path.join(FONTE,
        "hydria-apothecary-vase/textures/KGZ_5919_Waza_typu_hydria_4K.jpeg"))
    C.raddrizza(su="Z", avanti="-Y")
    C.in_metri(altezza=0.46)
    C.a_terra()
    C.alleggerisci(2000)
    C.riduci_texture(512)
    C.esporta(os.path.join(USCITA, "giara.glb"))


if __name__ == "__main__":
    for f in (motorino, fucile, bar_colazione, macchina_caffe, panino,
              arco, vaso_antico):
        try:
            f()
        except Exception as e:                       # noqa: BLE001
            print("  !! %s: %s" % (f.__name__, e))
