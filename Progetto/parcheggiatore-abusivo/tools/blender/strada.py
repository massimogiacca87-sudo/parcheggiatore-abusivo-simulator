"""La roba che sta per strada, e che messa insieme fa il quartiere.

Un mondo credibile non e' fatto di oggetti belli sparsi a caso: e' fatto di
oggetti **che stanno insieme**. Un cestino da solo e' un cestino; un
cestino con accanto tre cassette della frutta impilate, un motorino
appoggiato al muro e un cassonetto mezzo aperto e' un angolo di Napoli.

Questi tre pezzi servono a questo. Sono i piu' ripetuti della citta', e
sono anche quelli che il giocatore sfiora camminando.

    sedia da bar     46 x 46 x 84 cm
    motorino fermo   1,72 di lunghezza, 1,06 di altezza
    cassette         pila da tre, 52 x 34 x 78
"""

import sys
import os
import math

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import napoli as N

USCITA = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                      "..", "..", "assets", "models")


def _out(nome):
    return os.path.normpath(os.path.join(USCITA, nome + ".glb"))


def tinte():
    return {
        "vimini": N.materiale("vimini", (0.70, 0.55, 0.32), 0.88),
        "vimini_scuro": N.materiale("vimini_scuro", (0.48, 0.34, 0.18), 0.90),
        "alluminio": N.materiale("alluminio_bar", (0.74, 0.75, 0.77), 0.32, 0.85),
        "carena": N.materiale("carena", (0.62, 0.66, 0.70), 0.35, 0.20),
        "sella": N.materiale("sella", (0.10, 0.10, 0.11), 0.70),
        "gomma": N.materiale("gomma", (0.09, 0.09, 0.10), 0.88),
        "cromo": N.materiale("cromo_moto", (0.84, 0.85, 0.88), 0.16, 1.0),
        "faro": N.materiale("faro", (0.94, 0.92, 0.80), 0.15,
                            emissione=(0.20, 0.19, 0.14)),
        "targa": N.materiale("targa", (0.92, 0.91, 0.88), 0.40),
        "cassa_verde": N.materiale("cassa_verde", (0.22, 0.46, 0.26), 0.72),
        "cassa_rossa": N.materiale("cassa_rossa", (0.66, 0.22, 0.18), 0.72),
        "cassa_gialla": N.materiale("cassa_gialla", (0.80, 0.66, 0.16), 0.72),
        "arancia": N.materiale("arancia", (0.92, 0.52, 0.10), 0.62),
        "limone": N.materiale("limone", (0.92, 0.84, 0.20), 0.60),
    }


# ---------------------------------------------------------------------------
# 'A seggia d''o bar
# ---------------------------------------------------------------------------

def sedia_bar(_=None):
    """La sedia di vimini intrecciato dei bar, con la struttura di
    alluminio. Quella che sta fuori a ogni bar d'Italia.

    L'intreccio non e' una texture: sono otto stecche orizzontali e sei
    verticali sullo schienale, che a due metri leggono come vimini e
    costano trecento triangoli.
    """
    mod = N.Modello("sedia_bar")
    t = tinte()

    L = 0.44   # larghezza
    P = 0.42   # profondita'
    H = 0.44   # altezza seduta

    # Le quattro gambe, leggermente svasate, e le due traverse.
    for sx in (-1, 1):
        for sy in (-1, 1):
            x0 = sx * (L / 2 - 0.03)
            y0 = sy * (P / 2 - 0.03)
            bm = N.tubo([(x0 * 1.14, y0 * 1.14, 0.005),
                         (x0, y0, H)], 0.016, 6)
            N.tutto_morbido(bm)
            mod.add(bm, t["alluminio"])
        # Traversa laterale.
        bm2 = N.tubo([(sx * (L / 2 - 0.03), -P / 2 + 0.03, 0.18),
                      (sx * (L / 2 - 0.03), P / 2 - 0.03, 0.18)], 0.011, 6)
        N.tutto_morbido(bm2)
        mod.add(bm2, t["alluminio"])

    # La seduta: cornice piu' intreccio.
    for sy in (-1, 1):
        bm = N.tubo([(-L / 2 + 0.03, sy * (P / 2 - 0.03), H),
                     (L / 2 - 0.03, sy * (P / 2 - 0.03), H)], 0.014, 6)
        N.tutto_morbido(bm)
        mod.add(bm, t["alluminio"])
    for i in range(7):
        y = -P / 2 + 0.05 + i * (P - 0.10) / 6.0
        mod.add(N.cubo((L - 0.06, 0.026, 0.012), (0, y, H + 0.008)),
                t["vimini"] if i % 2 == 0 else t["vimini_scuro"])
    for i in range(6):
        x = -L / 2 + 0.05 + i * (L - 0.10) / 5.0
        mod.add(N.cubo((0.022, P - 0.06, 0.010), (x, 0, H + 0.020)),
                t["vimini_scuro"])

    # Lo schienale: due montanti che continuano le gambe posteriori, e
    # l'intreccio in mezzo.
    for sx in (-1, 1):
        bm = N.tubo([(sx * (L / 2 - 0.03), P / 2 - 0.03, H),
                     (sx * (L / 2 - 0.04), P / 2 + 0.01, 0.62),
                     (sx * (L / 2 - 0.05), P / 2 + 0.03, 0.83)], 0.015, 6)
        N.tutto_morbido(bm)
        mod.add(bm, t["alluminio"])
    bmt = N.tubo([(-L / 2 + 0.05, P / 2 + 0.03, 0.83),
                  (L / 2 - 0.05, P / 2 + 0.03, 0.83)], 0.015, 6)
    N.tutto_morbido(bmt)
    mod.add(bmt, t["alluminio"])
    for i in range(5):
        z = 0.52 + i * 0.072
        mod.add(N.cubo((L - 0.10, 0.012, 0.024),
                       (0, P / 2 + 0.015 + i * 0.004, z)),
                t["vimini"] if i % 2 == 0 else t["vimini_scuro"])

    mod.appoggia()
    return N.esporta(mod, _out("sedia_bar"))


# ---------------------------------------------------------------------------
# 'O motorino fermo
# ---------------------------------------------------------------------------

def motorino_fermo(_=None):
    """Uno scooter parcheggiato sul cavalletto, inclinato.

    Sta sul cavalletto laterale, quindi **pende di otto gradi**: e' quel
    dettaglio a farlo leggere come parcheggiato invece che come un modello
    appoggiato per terra. Guarda verso +Y come tutto il resto.
    """
    mod = N.Modello("motorino_fermo")
    t = tinte()

    # Le due ruote.
    for y, r in ((0.60, 0.20), (-0.58, 0.20)):
        ruota = N.cilindro(r, 0.09, 16, (0, y, r), rot=(0, 90, 0))
        N.tutto_morbido(ruota)
        mod.add(ruota, t["gomma"])
        cerchio = N.cilindro(r * 0.55, 0.10, 12, (0, y, r), rot=(0, 90, 0))
        N.tutto_morbido(cerchio)
        mod.add(cerchio, t["cromo"])

    # La pedana e la scocca: il corpo dello scooter, basso e panciuto.
    pedana = N.cubo((0.30, 0.52, 0.10), (0, 0.02, 0.30))
    N.smussa(pedana, 0.030, 2)
    mod.add(pedana, t["carena"])
    corpo = N.cubo((0.32, 0.60, 0.34), (0, -0.32, 0.44))
    N.smussa(corpo, 0.055, 3)
    mod.add(corpo, t["carena"])
    scudo = N.cubo((0.34, 0.16, 0.52), (0, 0.40, 0.52), rot=(-16, 0, 0))
    N.smussa(scudo, 0.045, 3)
    mod.add(scudo, t["carena"])

    # Sella lunga, quella da due.
    sella = N.cubo((0.28, 0.62, 0.11), (0, -0.24, 0.68), rot=(-4, 0, 0))
    N.smussa(sella, 0.045, 3)
    mod.add(sella, t["sella"])

    # Sterzo, manubrio e specchietti.
    mod.add(N.tutto_morbido(N.cilindro(0.028, 0.44, 8, (0, 0.52, 0.76),
                                       rot=(-14, 0, 0))), t["cromo"])
    manubrio = N.tubo([(-0.28, 0.50, 0.96), (0, 0.53, 0.99),
                       (0.28, 0.50, 0.96)], 0.017, 6)
    N.tutto_morbido(manubrio)
    mod.add(manubrio, t["cromo"])
    for sx in (-1, 1):
        mod.add(N.tutto_morbido(N.cilindro(0.010, 0.16, 6,
                                           (sx * 0.26, 0.49, 1.06))),
                t["cromo"])
        mod.add(N.tutto_morbido(N.cilindro(0.048, 0.016, 10,
                                           (sx * 0.26, 0.47, 1.14),
                                           rot=(80, 0, 0))), t["cromo"])
    # Faro e forcella.
    mod.add(N.tutto_morbido(N.uvsfera(0.075, 12, 8, (0, 0.60, 0.84),
                                      scala=(1.0, 0.55, 0.85))), t["faro"])
    for sx in (-1, 1):
        mod.add(N.tutto_morbido(N.cilindro(0.018, 0.44, 6,
                                           (sx * 0.055, 0.58, 0.40),
                                           rot=(-10, 0, 0))), t["cromo"])
    # Parafango davanti.
    mod.add(N.tutto_morbido(N.cilindro(0.235, 0.11, 12, (0, 0.60, 0.26),
                                       rot=(0, 90, 0))), t["carena"])
    # Targa e bauletto.
    mod.add(N.cubo((0.19, 0.02, 0.13), (0, -0.62, 0.44), rot=(-12, 0, 0)),
            t["targa"])
    bau = N.cubo((0.28, 0.30, 0.22), (0, -0.48, 0.86))
    N.smussa(bau, 0.040, 2)
    mod.add(bau, t["sella"])
    # Il cavalletto.
    mod.add(N.tutto_morbido(N.cilindro(0.014, 0.30, 6, (-0.16, -0.20, 0.13),
                                       rot=(0, 26, 0))), t["cromo"])

    mod.appoggia()
    # **L'inclinazione del cavalletto.** Otto gradi verso sinistra: e' il
    # dettaglio che dice "parcheggiato". Si applica alla fine, dopo aver
    # appoggiato, e poi si riappoggia perche' inclinandolo la ruota entra
    # sotto terra.
    import bmesh
    from mathutils import Matrix
    for bm, _m in mod.pezzi:
        bmesh.ops.rotate(bm, verts=bm.verts[:], cent=(0, 0, 0),
                         matrix=Matrix.Rotation(math.radians(8), 3, 'Y'))
    mod.appoggia(centra=False)
    return N.esporta(mod, _out("motorino_fermo"))


# ---------------------------------------------------------------------------
# 'E cassette
# ---------------------------------------------------------------------------

def cassette(_=None):
    """Una pila di tre cassette della frutta, di colori diversi, con la
    piu' alta piena di arance. Sta davanti a ogni bottega, e nel gioco e'
    anche il tipo di cosa dietro cui si nascondono i manifesti.

    Le cassette sono aperte sopra: quattro pareti e un fondo, non un cubo.
    """
    mod = N.Modello("cassette")
    t = tinte()

    def cassa(z, giro, mat):
        L, P, A = 0.50, 0.33, 0.24
        sp = 0.016
        # Fondo.
        mod.add(N.cubo((L, P, sp), (0, 0, z + sp / 2), rot=(0, 0, giro)), mat)
        # Le quattro pareti, con le fessure fra le doghe.
        for i in range(2):
            zz = z + 0.07 + i * 0.09
            mod.add(N.cubo((L, sp, 0.06), (0, -P / 2 + sp / 2, zz),
                           rot=(0, 0, giro)), mat)
            mod.add(N.cubo((L, sp, 0.06), (0, P / 2 - sp / 2, zz),
                           rot=(0, 0, giro)), mat)
        for sx in (-1, 1):
            mod.add(N.cubo((sp, P, A - 0.02),
                           (sx * (L / 2 - sp / 2), 0, z + A / 2),
                           rot=(0, 0, giro)), mat)
        # I quattro montanti d'angolo.
        for sx in (-1, 1):
            for sy in (-1, 1):
                mod.add(N.cubo((0.030, 0.030, A),
                               (sx * (L / 2 - 0.02), sy * (P / 2 - 0.02),
                                z + A / 2), rot=(0, 0, giro)), mat)

    cassa(0.0, 0.0, t["cassa_verde"])
    cassa(0.245, 4.0, t["cassa_rossa"])
    cassa(0.490, -3.0, t["cassa_gialla"])

    # La frutta nella cassetta di sopra: nove palline, due file.
    import random
    rng = random.Random(7)
    for i in range(9):
        x = -0.18 + (i % 5) * 0.09
        y = -0.08 + (i // 5) * 0.13
        r = rng.uniform(0.036, 0.047)
        f = N.uvsfera(r, 8, 6, (x + rng.uniform(-0.01, 0.01),
                                y + rng.uniform(-0.01, 0.01),
                                0.52 + r))
        N.tutto_morbido(f)
        mod.add(f, t["arancia"] if i % 3 else t["limone"])

    mod.appoggia()
    return N.esporta(mod, _out("cassette"))


# ---------------------------------------------------------------------------

def tutti():
    N.nuova_scena()
    return [f() for f in (sedia_bar, motorino_fermo, cassette)]


if __name__ == "__main__":
    for r in tutti():
        print("%-42s  %5d vert  %5d tri  %d mat" % (
            os.path.basename(r["file"]), r["vertici"], r["triangoli"],
            r["materiali"]))
