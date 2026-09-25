"""'E mmacchine nove d''a 0.46.

Dodici auto in più. Le sette del pacchetto "Ultimate Low Poly Car Pack 2"
arrivano tutte dentro a un FBX solo, sovrapposte all'origine — ma con una
gerarchia pulita: sette `Empty` col nome della macchina (M8, Urus, GTR,
Mustang, Porsche, Mercedes, P1GTR) e sotto a ognuno Body / Paint / Front /
Rear / Rims / Tires / Window. Ogni auto sta due volte nel file (la copia
`.001` è identica): si tiene la prima.

Le altre cinque vengono da file separati, e ognuna ha il suo difetto da
sistemare — la racing car si porta dietro la piattaforma da vetrina, l'AE86
è spezzata in sessantacinque pezzi, la Punto è un `.blend`.

    python3 tools/build_supercar.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy                                    # noqa: E402
import blender_comune as C                    # noqa: E402

FONTE = "/tmp/mod"
USCITA = os.path.join(os.path.dirname(os.path.dirname(
    os.path.abspath(__file__))), "assets", "models")

PACK = os.path.join(FONTE, "ultimate-low-poly-car-pack-2/source/UltimatePack2.fbx")

## Le sette del pacchetto, col nome che avranno nel gioco e la lunghezza
## vera in metri. Le misure sono quelle delle macchine di serie: una Urus
## è lunga 5,11 e una Mustang 4,79, e tenerle giuste conta perché il posto
## auto del gioco è 2,2 × 4,4 e ci si deve vedere che una ci sta stretta.
SETTE = [
    ("M8",       "car_m8",       4.87, (0.09, 0.10, 0.13)),
    ("Urus",     "car_urus",     5.11, (0.16, 0.16, 0.17)),
    ("GTR",      "car_gtr",      4.71, (0.62, 0.63, 0.66)),
    ("Mustang",  "car_mustang",  4.79, (0.58, 0.10, 0.10)),
    ("Porsche",  "car_porsche",  4.52, (0.86, 0.86, 0.84)),
    ("Mercedes", "car_mercedes", 4.93, (0.14, 0.16, 0.22)),
    ("P1GTR",    "car_p1",       4.59, (0.68, 0.14, 0.12)),
]


def _figli_di(nome: str):
    """I nomi delle mesh appese a quell'Empty."""
    fuori = []
    for o in bpy.data.objects:
        p = o.parent
        while p is not None:
            if p.name == nome:
                fuori.append(o.name)
                break
            p = p.parent
    return fuori


def una_del_pacco(empty: str, uscita: str, lunghezza: float, colore):
    C.pulisci()
    C.importa(PACK)
    voluti = set(_figli_di(empty))
    if not voluti:
        print("  !! %s: non trovato dentro al pacchetto" % empty)
        return
    for o in list(bpy.data.objects):
        if o.name not in voluti:
            bpy.data.objects.remove(o, do_unlink=True)
    # Il pacchetto è Z-su col muso verso −Y: è l'uscita standard di 3ds Max.
    C.raddrizza(su="Z", avanti="-Y")
    C.in_metri(lunghezza=lunghezza)
    C.a_terra()
    # I materiali del pacchetto si chiamano `Material.047`: qui non c'è
    # niente da riconoscere dal nome. Si va per oggetto — è l'unico
    # appiglio che questo file offre, e per fortuna è pulito.
    for o in C.mesh_scena():
        base = o.name.split(".")[0].lower()
        chiave = {"body": "body", "paint": "body", "window": "glass",
                  "tires": "tire", "rims": "chrome",
                  "front": "light", "rear": "light"}.get(base, "body")
        for s in o.material_slots:
            if s.material is not None:
                s.material.name = "%s_%s" % (chiave, base)
    C.tinta("body", colore, metallico=0.55, ruvido=0.30)
    C.tinta("glass", (0.10, 0.13, 0.17), metallico=0.20, ruvido=0.08)
    C.tinta("tire", (0.05, 0.05, 0.06), metallico=0.0, ruvido=0.92)
    C.tinta("chrome", (0.80, 0.82, 0.86), metallico=0.95, ruvido=0.14)
    C.tinta("light", (0.95, 0.93, 0.82), metallico=0.10, ruvido=0.20)
    C.alleggerisci(2600)
    C.esporta(os.path.join(USCITA, uscita + ".glb"))


def bmw_m3():
    """Nove­mila triangoli, materiali già con i nomi giusti (CarPaint,
    Window, Rims, Tires, RearLight) e le quattro ruote separate. È il
    modello meglio fatto del lotto — ed è anche il rimpiazzo di quello
    rotto che il capo ha visto bianco per venti build."""
    C.pulisci()
    C.importa(os.path.join(FONTE, "bmw-m3-low-poly-stylized/source/BMW M3.fbx"))
    C.butta(["cylinder"])          # due tubi di scarico sospesi per aria
    C.raddrizza(su="Z", avanti="-Y")
    C.in_metri(lunghezza=4.79)
    C.a_terra()
    n = C.rinomina_materiali()
    print("  materiali riconosciuti:", n)
    C.tinta("body", (0.10, 0.11, 0.14), metallico=0.6, ruvido=0.26)
    C.alleggerisci(6000)
    C.esporta(os.path.join(USCITA, "car_bmw.glb"))


def ae86():
    """Una Corolla hatchback: la macchina più anni Ottanta che ci sia, e
    per un vicolo di Napoli è perfetta. Arriva in sessantacinque pezzi
    separati, molti dei quali sono loghi da un millimetro."""
    C.pulisci()
    C.importa(os.path.join(FONTE, "low-poly-ae86-hatch/source/AE86Hatch.fbx"))
    C.butta(["badge", "truewin"])   # 3.100 triangoli di scritte invisibili
    C.butta_piccoli(10)
    C.raddrizza(su="Z", avanti="-Y")
    C.in_metri(lunghezza=4.20)
    C.a_terra()
    C.rinomina_materiali()
    C.alleggerisci(5000)
    C.esporta(os.path.join(USCITA, "car_ae86.glb"))


def generica():
    """Duemilacinquecento triangoli in una mesh sola, con otto materiali
    che si chiamano già Body, Window, Tires, Wheels, Lights, Bumpers. È
    la macchina più economica del lotto ed è pure fra le più utili."""
    C.pulisci()
    C.importa(os.path.join(FONTE, "auto low poly/Car-Model/Car.fbx"))
    C.raddrizza(su="Z", avanti="-Y")
    C.in_metri(lunghezza=4.30)
    C.a_terra()
    C.rinomina_materiali()
    C.tinta("body", (0.72, 0.70, 0.66), metallico=0.35, ruvido=0.40)
    C.esporta(os.path.join(USCITA, "car_generica.glb"))


def racing():
    """Stilizzata e **corta**, che è il motivo per cui va scalata sulla
    larghezza e non sulla lunghezza.

    Misurata: 2,16 di largo per 2,64 di lungo. Portandola a 3,90 di
    lunghezza — come si fa con tutte le altre — veniva larga 3,19, cioè
    un metro e mezzo più di un fuoristrada: in un vicolo da quattro metri
    non ci passava. Scalata sulla larghezza viene una macchinetta da due
    metri e mezzo, ed è quello che è: una bolla stilizzata, buona per la
    fascia economica.

    Si porta anche dietro la piattaforma grigia da vetrina — lo stesso
    difetto che aveva l'utilitaria alla 0.14, e si toglie allo stesso modo.
    """
    C.pulisci()
    C.importa(os.path.join(FONTE,
              "ba6w0ln4l2io-Low-Poly-Racing-Car-c/Low-Poly-Racing-Car.fbx"))
    C.butta(["platform", "lattice"])
    C.raddrizza(su="Z", avanti="-Y")
    C.in_metri(larghezza=1.82)
    C.a_terra()
    C.rinomina_materiali()
    # **E po' s'è lassata perdere.** Misurata bene: 2,16 di largo per 2,64
    # di lungo, cioè una macchina larga quanto è lunga. Portata a una
    # lunghezza credibile viene larga più di un fuoristrada e in un vicolo
    # da quattro metri non ci passa; tenuta corta è una macchina da due
    # metri e venti, che non esiste. Stessa decisione presa alla 0.45 per
    # `car_coupe`: un modello che non si può portare alla misura giusta si
    # butta, non si spinge dentro. Le altre undici bastano e avanzano.
    #
    # La funzione resta perché il conto sopra è il motivo, e un giorno
    # potrebbe servire come macchinina da luna park.
    print("  -- car_bolla: scartata, larga quanto lunga (vedi commento)")
    return


def punto():
    """**'A Punto.** Se una macchina sola dovesse rappresentare una strada
    di Napoli nel 1998, è questa. Arriva come `.blend`, quindi si apre il
    file invece di importarlo."""
    b = None
    d = os.path.join(FONTE, "free-1995-fiat-punto-gt/source")
    for f in os.listdir(d):
        if f.endswith(".blend"):
            b = os.path.join(d, f)
    if b is None:
        print("  !! Punto: nessun .blend")
        return
    C.pulisci()
    C.importa(b)
    C.butta(["plane", "ground", "floor", "backdrop", "studio", "light",
             "camera"])
    C.butta_piccoli(6)
    # **'A machina sta doje vote dinto ô file.** `Punto_GT` e
    # `punto_real_scale` sono due copie identiche da 35.168 e 35.166
    # triangoli, una sopra all'altra. Esportandole tutte e due il modello
    # pesava il doppio e le facce coincidenti sfarfallavano (z-fighting).
    C.butta(["punto_real_scale"])
    if not C.mesh_scena():
        print("  !! Punto: non è rimasto niente")
        return
    C.raddrizza(su="Z", avanti="-Y")
    C.in_metri(lunghezza=3.76)
    C.a_terra()
    C.rinomina_materiali()
    # Settantamila triangoli per una macchina che in piazza ce ne stanno
    # otto insieme sono troppi: si scende a diecimila. La Punto resta
    # comunque il modello più ricco del parco.
    C.alleggerisci(10000)
    C.esporta(os.path.join(USCITA, "car_punto.glb"))


if __name__ == "__main__":
    print("=== 'E sette d''o pacchetto ===")
    for empty, uscita, lung, col in SETTE:
        una_del_pacco(empty, uscita, lung, col)
    print("=== 'E ccinche 'a fore ===")
    for f in (bmw_m3, ae86, generica, racing, punto):
        try:
            f()
        except Exception as e:                       # noqa: BLE001
            print("  !! %s: %s" % (f.__name__, e))
