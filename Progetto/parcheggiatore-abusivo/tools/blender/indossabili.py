"""Gli attrezzi del mestiere: quello che si compra da 'O Zio e si porta
addosso.

Sono sei, e sono quelli che il giocatore guarda piu' da vicino di tutti:
il gilet e il borsello si vedono guardandosi in giu' in prima persona, la
paletta sta in mano a mezzo metro dagli occhi, e coppola e occhiali stanno
in faccia a ogni passante che incontri.

Fino a ieri erano scatole: il gilet erano cinque parallelepipedi gialli, il
borsello tre, la paletta un cilindro con sopra un disco. Qui sono modelli
veri, e restano poveri di poligoni perche' ce ne sono decine a schermo
insieme (ogni passante col suo).

## L'origine di ognuno

Ogni pezzo si attacca a un punto preciso del personaggio, e l'origine del
modello e' **quel punto**, non il centro dell'ingombro. Cosi' chi lo monta
scrive una posizione sola e non deve indovinare scostamenti:

    gilet       centro del torace
    borsello    centro della borsa (sta sul fianco destro)
    coppola     centro del giro-testa, all'altezza della fronte
    occhiali    ponte del naso
    fischietto  centro del corpo del fischietto
    paletta     dove la stringe la mano, in fondo al manico
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
        "hi_vis": N.materiale("hi_vis", (0.93, 0.80, 0.08), 0.85),
        "catarifrangente": N.materiale("catarifrangente", (0.88, 0.89, 0.92),
                                       0.22, 0.35,
                                       emissione=(0.10, 0.10, 0.11)),
        "cuoio": N.materiale("cuoio", (0.26, 0.16, 0.10), 0.62),
        "cuoio_chiaro": N.materiale("cuoio_chiaro", (0.38, 0.25, 0.15), 0.60),
        "ottone": N.materiale("ottone", (0.78, 0.62, 0.24), 0.28, 0.9),
        "cromo": N.materiale("cromo", (0.86, 0.87, 0.89), 0.14, 1.0),
        "nero_opaco": N.materiale("nero_opaco", (0.08, 0.08, 0.09), 0.55),
        "panno_grigio": N.materiale("panno_grigio", (0.30, 0.31, 0.33), 0.88),
        "panno_scuro": N.materiale("panno_scuro", (0.20, 0.21, 0.23), 0.90),
        "lente": N.materiale("lente", (0.05, 0.06, 0.09), 0.10, 0.15,
                             alpha=0.86),
        "plastica_rossa": N.materiale("plastica_rossa", (0.74, 0.14, 0.12), 0.42),
        "plastica_bianca": N.materiale("plastica_bianca", (0.90, 0.89, 0.86), 0.40),
        "zip": N.materiale("zip", (0.62, 0.63, 0.66), 0.30, 0.85),
    }


# ---------------------------------------------------------------------------
# 'O gilet
# ---------------------------------------------------------------------------

def gilet(_=None):
    """Il gilet catarifrangente fasullo. Non e' un blocco giallo: e' un
    panno che **avvolge** il torace, aperto davanti, con lo spacco in
    mezzo, le due bande grigie e la zip.

    Costruito come un guscio: si genera l'anello del busto (un'ellisse
    schiacciata) a piu' quote, si salta il settore davanti dove c'e'
    l'apertura, e si ispessisce. Un cilindro tagliato, insomma — che e'
    esattamente cos'e' un gilet.
    """
    import bmesh
    mod = N.Modello("gilet")
    t = tinte()

    # Semiassi del busto. Misurati sul manichino del gioco, non su una
    # persona: il personaggio e' piu' stretto di un uomo vero, e un gilet
    # da quaranta centimetri di larghezza gli stava addosso come un barile.
    RX, RY = 0.150, 0.108

    APERTURA = math.radians(26)   # mezzo spacco davanti

    def guscio(a0, a1, mat, z0, z1, gonfio=1.0):
        bm = bmesh.new()
        seg = 10
        anelli = []
        for z in (z0, z1):
            k = 1.0 + 0.10 * math.cos(math.pi * (z - z0) / max(z1 - z0, 1e-6))
            fila = []
            for i in range(seg + 1):
                a = a0 + (a1 - a0) * i / seg
                fila.append(bm.verts.new((RX * k * gonfio * math.sin(a),
                                          -RY * k * gonfio * math.cos(a), z)))
            anelli.append(fila)
        for i in range(seg):
            bm.faces.new((anelli[0][i], anelli[0][i + 1],
                          anelli[1][i + 1], anelli[1][i]))
        bm.normal_update()
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
        bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=0.014)
        N.tutto_morbido(bm)
        mod.add(bm, mat)

    # Il corpo del gilet: dal lato destro dello spacco fino al sinistro,
    # girando dietro. Diviso in fasce per poterci mettere le bande.
    fasce = [(-0.25, -0.18, "hi_vis"), (-0.18, -0.11, "catarifrangente"),
             (-0.11, 0.02, "hi_vis"), (0.02, 0.09, "catarifrangente"),
             (0.09, 0.20, "hi_vis")]
    for z0, z1, mat in fasce:
        guscio(APERTURA, 2 * math.pi - APERTURA, t[mat], z0, z1)

    # Le spalline: due strisce che passano sopra le spalle e chiudono il
    # davanti. Senza, il gilet sembra un tubo infilato.
    for lato in (-1, 1):
        bm = N.tubo([
            (lato * 0.062, -RY * 0.94, 0.185),
            (lato * 0.106, -RY * 0.30, 0.232),
            (lato * 0.110, RY * 0.35, 0.226),
            (lato * 0.070, RY * 0.92, 0.178),
        ], 0.018, 6)
        N.tutto_morbido(bm)
        mod.add(bm, t["hi_vis"])

    # La zip davanti, nello spacco.
    mod.add(N.cubo((0.010, 0.012, 0.44), (0, -RY - 0.004, -0.025)), t["zip"])
    mod.add(N.tutto_morbido(N.cilindro(0.010, 0.020, 8,
                                       (0, -RY - 0.010, 0.03))), t["ottone"])
    return N.esporta(mod, _out("gilet"))


# ---------------------------------------------------------------------------
# 'O borsello
# ---------------------------------------------------------------------------

def borsello(_=None):
    """Il borsello a tracolla, quello di cuoio con la patta e la fibbia.
    L'origine sta al centro della borsa, che e' il punto in cui va appesa
    al fianco.
    """
    mod = N.Modello("borsello")
    t = tinte()

    corpo = N.cubo((0.150, 0.070, 0.122))
    N.smussa(corpo, 0.014, 3)
    mod.add(corpo, t["cuoio"])

    # La patta che ricade davanti, un po' piu' larga del corpo.
    patta = N.cubo((0.160, 0.018, 0.072), (0, -0.030, 0.032), rot=(-14, 0, 0))
    N.smussa(patta, 0.008, 2)
    mod.add(patta, t["cuoio_chiaro"])
    # La fibbia e la linguetta.
    mod.add(N.cubo((0.030, 0.016, 0.030), (0, -0.050, 0.006)), t["ottone"])
    mod.add(N.cubo((0.020, 0.010, 0.044), (0, -0.046, -0.010)),
            t["cuoio_chiaro"])
    # Le cuciture: due cordoncini lungo il bordo.
    for z in (-0.070, 0.068):
        mod.add(N.tubo([(-0.088, -0.040, z), (0.088, -0.040, z)],
                       0.0035, 5), t["cuoio_chiaro"])

    # La tracolla: un nastro che sale in diagonale verso la spalla
    # opposta. Non e' completa (sparirebbe dentro al petto): e' il pezzo
    # che si vede, cioe' quello che esce dalla borsa.
    bm = N.tubo([
        (0.005, -0.010, 0.072),
        (-0.030, -0.030, 0.24),
        (-0.085, -0.020, 0.42),
        (-0.130, 0.030, 0.54),
    ], 0.014, 6)
    N.tutto_morbido(bm)
    mod.add(bm, t["cuoio"])
    mod.add(N.cubo((0.030, 0.030, 0.014), (0.004, -0.014, 0.080),
                   rot=(0, 0, 0)), t["ottone"])
    return N.esporta(mod, _out("borsello"))


# ---------------------------------------------------------------------------
# 'A coppola
# ---------------------------------------------------------------------------

def coppola(_=None):
    """La coppola: calotta morbida schiacciata in avanti, visierina corta e
    la cucitura del bottoncino in cima.

    Fatta come mezza sfera schiacciata e **spostata indietro**, che e' il
    modo in cui una coppola sta in testa: davanti scende sulla fronte,
    dietro sta gonfia sulla nuca.
    """
    import bmesh
    mod = N.Modello("coppola")
    t = tinte()

    calotta = N.uvsfera(0.108, 18, 10, (0, 0.012, 0.012),
                        scala=(1.0, 1.10, 0.62))
    # Si taglia via la meta' sotto: una coppola e' un guscio, e i vertici
    # sotto al giro-testa spuntano dentro alla faccia.
    bmesh.ops.bisect_plane(calotta, geom=calotta.verts[:] + calotta.edges[:] +
                           calotta.faces[:], plane_co=(0, 0, 0.0),
                           plane_no=(0, 0, -1), clear_inner=True)
    bmesh.ops.holes_fill(calotta, edges=calotta.edges[:])
    N.tutto_morbido(calotta)
    mod.add(calotta, t["panno_grigio"])

    # La visiera: un ventaglio piatto che scende un po'.
    bm = bmesh.new()
    centro = bm.verts.new((0, -0.085, 0.008))
    orlo = []
    for i in range(9):
        a = math.radians(-72 + 144 * i / 8)
        r = 0.082
        orlo.append(bm.verts.new((r * math.sin(a),
                                  -0.085 - r * math.cos(a) * 0.86,
                                  0.008 - 0.022 * math.cos(a))))
    for i in range(8):
        bm.faces.new((centro, orlo[i], orlo[i + 1]))
    bm.normal_update()
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=0.008)
    N.tutto_morbido(bm)
    mod.add(bm, t["panno_scuro"])

    # Il bottoncino in cima e la fascia interna che si vede sul davanti.
    mod.add(N.tutto_morbido(N.uvsfera(0.012, 8, 5, (0, 0.012, 0.070))),
            t["panno_scuro"])
    fascia = N.toro(0.100, 0.009, 20, 6, (0, 0.012, 0.006))
    N.tutto_morbido(fascia)
    mod.add(fascia, t["panno_scuro"])
    return N.esporta(mod, _out("coppola"))


# ---------------------------------------------------------------------------
# ll'occhiali
# ---------------------------------------------------------------------------

def occhiali(_=None):
    """Occhiali da sole: due lenti tonde leggermente curve, ponte e aste.
    L'origine sta sul ponte, cioe' sulla radice del naso.
    """
    import bmesh
    mod = N.Modello("occhiali")
    t = tinte()

    for lato in (-1, 1):
        cx = lato * 0.036
        # La lente: un disco leggermente bombato in avanti.
        bm = bmesh.new()
        centro = bm.verts.new((cx, -0.010, 0))
        orlo = []
        seg = 14
        for i in range(seg):
            a = 2 * math.pi * i / seg
            orlo.append(bm.verts.new((cx + 0.026 * math.cos(a), 0,
                                      0.022 * math.sin(a))))
        for i in range(seg):
            bm.faces.new((centro, orlo[i], orlo[(i + 1) % seg]))
        bm.normal_update()
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
        bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=0.004)
        N.tutto_morbido(bm)
        mod.add(bm, t["lente"])
        # La montatura intorno.
        cerchio = N.toro(0.027, 0.004, 16, 6, (cx, 0.001, 0), rot=(90, 0, 0))
        # Schiacciata come le lenti.
        import mathutils
        bmesh.ops.scale(cerchio, vec=mathutils.Vector((1.0, 1.0, 0.85)),
                        verts=cerchio.verts[:],
                        space=mathutils.Matrix.Translation(
                            (-cx, -0.001, 0)))
        N.tutto_morbido(cerchio)
        mod.add(cerchio, t["nero_opaco"])
        # L'asta che va verso l'orecchio.
        ast = N.tubo([(lato * 0.062, 0.004, 0.004),
                      (lato * 0.070, 0.045, 0.006),
                      (lato * 0.068, 0.098, 0.000),
                      (lato * 0.064, 0.116, -0.016)], 0.0045, 6)
        N.tutto_morbido(ast)
        mod.add(ast, t["nero_opaco"])

    # Il ponte sopra al naso.
    ponte = N.tubo([(-0.012, -0.002, 0.010), (0, -0.006, 0.014),
                    (0.012, -0.002, 0.010)], 0.0045, 6)
    N.tutto_morbido(ponte)
    mod.add(ponte, t["nero_opaco"])
    return N.esporta(mod, _out("occhiali"))


# ---------------------------------------------------------------------------
# 'O fischietto
# ---------------------------------------------------------------------------

def fischietto(_=None):
    """Il fischietto d'arbitro, col cordino. Sta appeso al collo, quindi
    l'origine e' il corpo del fischietto e il cordino sale verso l'alto.
    """
    mod = N.Modello("fischietto")
    t = tinte()

    corpo = N.cubo((0.020, 0.048, 0.017))
    N.smussa(corpo, 0.006, 3)
    N.tutto_morbido(corpo)
    mod.add(corpo, t["cromo"])
    # La camera tonda, che e' quella che fa il fischio.
    camera = N.cilindro(0.014, 0.020, 12, (0, 0.020, -0.002), rot=(0, 90, 0))
    N.tutto_morbido(camera)
    mod.add(camera, t["cromo"])
    # Il bocchino.
    mod.add(N.tutto_morbido(N.cubo((0.014, 0.020, 0.009),
                                   (0, -0.032, 0.001))), t["cromo"])
    # Il taglio sopra.
    mod.add(N.cubo((0.012, 0.010, 0.004), (0, 0.001, 0.010)),
            t["nero_opaco"])
    # L'anellino e il cordino.
    anello = N.toro(0.008, 0.002, 10, 5, (0, 0.032, 0.008), rot=(0, 90, 0))
    N.tutto_morbido(anello)
    mod.add(anello, t["cromo"])
    cordino = N.tubo([(0, 0.036, 0.012), (0.004, 0.050, 0.10),
                      (0.002, 0.030, 0.20)], 0.0035, 5)
    N.tutto_morbido(cordino)
    mod.add(cordino, t["plastica_rossa"])
    return N.esporta(mod, _out("fischietto"))


# ---------------------------------------------------------------------------
# 'A paletta
# ---------------------------------------------------------------------------

def paletta(_=None):
    """La paletta da posteggiatore: manico, impugnatura zigrinata, disco
    bianco e rosso con la banda catarifrangente.

    L'origine sta **in fondo al manico**, dove la stringe la mano: cosi'
    chi la monta la attacca all'osso della mano e basta.
    """
    mod = N.Modello("paletta")
    t = tinte()

    # Impugnatura di gomma, con tre anelli.
    imp = N.cilindro(0.017, 0.10, 12, (0, 0, 0.05), raggio2=0.015)
    N.smussa(imp, 0.004, 2)
    N.tutto_morbido(imp)
    mod.add(imp, t["nero_opaco"])
    for z in (0.028, 0.052, 0.076):
        a = N.toro(0.018, 0.0028, 12, 5, (0, 0, z))
        N.tutto_morbido(a)
        mod.add(a, t["nero_opaco"])
    # Asta cromata.
    asta = N.cilindro(0.010, 0.13, 10, (0, 0, 0.160))
    N.tutto_morbido(asta)
    mod.add(asta, t["cromo"])

    # Il disco: bianco davanti, con la corona rossa e la banda.
    disco = N.cilindro(0.082, 0.012, 24, (0, 0, 0.285))
    N.smussa(disco, 0.003, 2)
    N.tutto_morbido(disco)
    mod.add(disco, t["plastica_rossa"])
    for dz in (-0.008, 0.008):
        faccia = N.cilindro(0.058, 0.004, 24, (0, 0, 0.285 + dz))
        N.tutto_morbido(faccia)
        mod.add(faccia, t["plastica_bianca"])
    corona = N.toro(0.076, 0.007, 24, 6, (0, 0, 0.285))
    N.tutto_morbido(corona)
    mod.add(corona, t["catarifrangente"])
    return N.esporta(mod, _out("paletta"))


# ---------------------------------------------------------------------------

def tutti():
    N.nuova_scena()
    return [f() for f in (gilet, borsello, coppola, occhiali, fischietto,
                          paletta)]


if __name__ == "__main__":
    for r in tutti():
        print("%-42s  %5d vert  %5d tri  %d mat" % (
            os.path.basename(r["file"]), r["vertici"], r["triangoli"],
            r["materiali"]))
