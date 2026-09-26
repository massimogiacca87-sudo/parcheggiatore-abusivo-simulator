"""L'arredo urbano: quello che fa sembrare una strada una strada.

**Perché conta più di dieci palazzi.** La città del gioco è costruita
bene — isolati, vicoli, quartieri con colori diversi — ma è **pulita**.
Una strada di Napoli non è pulita: ci stanno i coni della buca di tre anni
fa, la transenna che nessuno ha più tolto, i condizionatori appesi alle
facciate, le piante sui balconi, il lampione di ghisa accanto a quello di
alluminio perché li hanno cambiati a metà. Sono cose piccole, ma sono
**quelle che fanno la differenza fra un modello e un posto**.

Vengono tutte da un pacchetto solo — "neighbourhood city modular low
poly" — che è un GLB da trentanove mega con centottanta oggetti e
milleduecentottantasette materiali dentro. Qui se ne tirano fuori venti,
uno per volta, ognuno alleggerito e portato alla misura vera.

    python3 tools/build_arredo_urbano.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy                                    # noqa: E402
import blender_comune as C                    # noqa: E402

FONTE = "/tmp/mod/neighbourhood-city-modular-lowpoly/source/Untitled.glb"
USCITA = os.path.join(os.path.dirname(os.path.dirname(
    os.path.abspath(__file__))), "assets", "models")

## Che cosa si tira fuori, e come.
##
## `prefisso`  il nome dentro al GLB (basta l'inizio)
## `uscita`    come si chiamerà in assets/models
## `altezza`   la misura vera in metri: un cono stradale è alto 50 cm, un
##             lampione tre metri e mezzo. È l'unico numero che conta,
##             perché il pacchetto arriva in scala Unreal.
## `tetto`     quanti triangoli può costare
PEZZI = [
    # --- 'E llampiuncielle. Cinque stili diversi: il punto di averne
    # cinque è che una strada dove sono tutti uguali sembra un rendering.
    ("streetLights:victorianLight_double", "lamp_ghisa",     3.60,  900),
    ("streetLights:globeLight_triple",     "lamp_globo3",    3.40, 1000),
    ("streetLights:globeLight_single",     "lamp_globo1",    3.20,  700),
    ("streetLights:largeLight_small",      "lamp_stradale",  4.20,  600),
    ("streetLights:largeLight_longDouble", "lamp_doppio",    4.40,  700),
    ("streetLights:arcLight_style1",       "lamp_arco",      4.00,  700),
    # --- 'E ccose d''o cantiere. A Napoli un cantiere aperto è arredo
    # permanente, non un evento.
    ("SM_TrafficConeA",        "cono",           0.52,  300),
    ("SM_TrafficConeB",        "cono2",          0.44,  300),
    ("SM_TrafficDrum",         "bidone_cantiere", 0.95, 500),
    ("SM_BarricadeA",          "transenna",      1.05,  700),
    ("SM_BarricadeB",          "transenna2",     1.05,  700),
    ("SM_TrafficBarrierA",     "new_jersey",     1.10,  400),
    ("SM_TrafficBarrierC",     "barriera_lunga", 1.10,  600),
    ("SM_DelineatorPole",      "paletto",        1.15,  200),
    ("SM_Verticade",           "delimitatore",   1.05,  260),
    # --- 'O verde. Le piante in vaso vanno sui balconi, gli alberi in
    # piazza.
    ("Pot_9",                  "vaso_pianta",    1.10, 1400),
    ("Acer_large_3",           "albero",         6.20, 2200),
    ("Acer_small_1",           "alberello",      3.60,  600),
    ("Acer_small_2",           "alberello2",     3.40,  600),
    # --- 'E condizionature. Sono la cosa più napoletana di tutto il
    # pacchetto: una facciata senza split appesi storti non è una
    # facciata italiana degli anni Duemila.
    # (0.62) TOLTI: "Split_Ac" e "Window_AC" nel pacchetto sono appesi a
    # un palazzo in miniatura, e l'esportazione si portava dietro tutto il
    # palazzo (182 e 235 superfici). Lo split adesso lo costruisce
    # `citta_3d._condizionatore` con quattro scatole.
    # ("Split_Ac",               "condizionatore", 0.85, 1200),
    # ("Window_AC",              "condizionatore2", 0.60, 1000),
]


def uno(prefisso: str, uscita: str, altezza: float, tetto: int):
    C.pulisci()
    C.importa(FONTE)
    # Si tiene solo la prima copia: il pacchetto ne mette in scena
    # sedici uguali sparse per la strada, e a noi ne serve una.
    trovati = [o for o in bpy.data.objects
               if o.type == "MESH" and o.name.lower().startswith(prefisso.lower())]
    if not trovati:
        print("  !! %-24s non trovato" % prefisso[:24])
        return
    trovati.sort(key=lambda o: o.name)
    tieni = trovati[0].name
    for o in list(bpy.data.objects):
        if o.name != tieni:
            bpy.data.objects.remove(o, do_unlink=True)
    # Il GLB arriva già Y-su (glTF è Y-su per specifica), ma l'importatore
    # di Blender lo rimette Z-su: quindi si raddrizza come tutto il resto.
    C.raddrizza(su="Z", avanti="-Y")
    C.in_metri(altezza=altezza)
    C.a_terra()
    C.alleggerisci(tetto)
    # 256 pixel: un cono stradale a schermo è alto venti pixel, e con le
    # texture da 2K questo pacchetto pesava trenta mega per venti oggetti.
    C.riduci_texture(256)
    C.esporta(os.path.join(USCITA, uscita + ".glb"))


if __name__ == "__main__":
    for prefisso, uscita, altezza, tetto in PEZZI:
        try:
            uno(prefisso, uscita, altezza, tetto)
        except Exception as e:                        # noqa: BLE001
            print("  !! %s: %s" % (uscita, e))
