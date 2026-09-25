"""Le sei decorazioni del Bazar, modellate come si deve.

Fino a ieri erano scatole e cilindri scritti a mano dentro
`zone_vicolo_3d.gd`: la sedia sdraio erano sei parallelepipedi, l'ombrellone
un palo con otto prismi in cerchio, la radio un cubo con due dischetti. Da
lontano passavano; da vicino — e ci passi accanto tutto il turno, perche'
il salotto sta in mezzo alla piazza tua — si vedeva che erano primitive.

Qui sono modelli veri: tubolari piegati, tela che cede fra le stecche,
spicchi cuciti, vasi tornati. Restano poveri di poligoni (dai settecento ai
tremila triangoli l'uno) perche' e' roba di piazza, non di vetrina, e
perche' il gioco gira anche nel browser.

Misure vere, prese da roba vera:
    sedia sdraio    58 x 90 x 78 cm
    ombrellone      2,40 m di diametro, 2,35 di palo
    tavolino        piano 68 cm, alto 72
    radio           26 x 9 x 17 cm
    pianta in vaso  vaso 26 cm, pianta 75 cm totali
    luminaria       arcata da 14 m con 16 lampadine
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


# ---------------------------------------------------------------------------
# Le tinte
# ---------------------------------------------------------------------------

def tinte():
    return {
        "tela_blu": N.materiale("tela_blu", (0.16, 0.34, 0.58), 0.92),
        "tela_bianca": N.materiale("tela_bianca", (0.88, 0.86, 0.80), 0.92),
        "tela_rossa": N.materiale("tela_rossa", (0.72, 0.18, 0.16), 0.92),
        "tela_crema": N.materiale("tela_crema", (0.93, 0.90, 0.83), 0.92),
        "legno": N.materiale("legno", (0.56, 0.40, 0.24), 0.70),
        "legno_chiaro": N.materiale("legno_chiaro", (0.72, 0.58, 0.38), 0.68),
        "alluminio": N.materiale("alluminio", (0.72, 0.73, 0.75), 0.35, 0.85),
        "ferro": N.materiale("ferro", (0.22, 0.22, 0.24), 0.45, 0.75),
        "cromo": N.materiale("cromo", (0.86, 0.87, 0.89), 0.14, 1.0),
        "plastica_nera": N.materiale("plastica_nera", (0.10, 0.10, 0.11), 0.42),
        "plastica_avorio": N.materiale("plastica_avorio", (0.84, 0.79, 0.66), 0.44),
        "marmo": N.materiale("marmo", (0.86, 0.84, 0.79), 0.30),
        "terracotta": N.materiale("terracotta", (0.66, 0.34, 0.22), 0.85),
        "terra": N.materiale("terra", (0.20, 0.15, 0.11), 0.98),
        "foglia": N.materiale("foglia", (0.20, 0.42, 0.16), 0.80),
        "foglia_chiara": N.materiale("foglia_chiara", (0.31, 0.55, 0.20), 0.78),
        "cavo": N.materiale("cavo", (0.14, 0.14, 0.15), 0.60),
    }


# ---------------------------------------------------------------------------
# 'A sedia sdraio
# ---------------------------------------------------------------------------

def sedia(m):
    """Una sdraio da spiaggia: telaio di tubolare piegato e tela a righe.

    **Il telaio e' due tubi piegati, non otto cilindri.** Al primo giro
    l'avevo fatta con quattro cilindretti per fianco messi agli angoli
    giusti: da lontano passava, da vicino aveva i buchi in ogni piega e
    sembrava smontata. Adesso ogni fianco e' UN tubo solo che segue una
    spezzata — piede, gamba, seduta, schienale — e le pieghe sono pieghe.

    L'altro pezzo che la fa leggere e' **la tela che cede**. Una sdraio col
    telo teso dritto sembra una panca; quella vera fa la pancia sotto il
    peso, ed e' uno spostamento a seno sui vertici di mezzo.
    """
    import bmesh
    mod = N.Modello("sedia")
    t = tinte()

    # Il fianco, visto di lato (Y avanti, Z su). Il piede posteriore sta
    # dietro e in basso, si sale lungo lo schienale inclinato, si scende
    # sulla seduta e si finisce sul piede anteriore.
    fianco = [
        (0.30, 0.02),    # piede posteriore
        (0.30, 0.06),
        (0.34, 0.86),    # cima dello schienale
        (0.20, 0.50),    # snodo
        (-0.02, 0.44),   # seduta
        (-0.26, 0.42),   # bordo davanti
        (-0.30, 0.30),
        (-0.30, 0.02),   # piede anteriore
    ]
    for lato in (-1, 1):
        x = lato * 0.265
        punti = [(x, p[0], p[1]) for p in fianco]
        bm = N.tubo(punti, 0.017, 8)
        N.tutto_morbido(bm)
        mod.add(bm, t["alluminio"])
        for p in ((x, 0.30, 0.015), (x, -0.30, 0.015)):
            mod.add(N.tutto_morbido(N.cilindro(0.022, 0.03, 8, p)),
                    t["plastica_nera"])

    # Le traverse: quella davanti, quella dietro e quella in cima allo
    # schienale, che e' anche quella che tiene la tela.
    for y, z in ((-0.30, 0.06), (0.30, 0.06), (0.34, 0.86), (-0.26, 0.42)):
        bm = N.tubo([(-0.265, y, z), (0.265, y, z)], 0.014, 8)
        N.tutto_morbido(bm)
        mod.add(bm, t["alluminio"])

    # **La tela**, in due campate: seduta e schienale.
    def telo(a, b, righe, affondo):
        fatte = []
        for i in range(righe):
            u0 = i / righe
            u1 = (i + 1) / righe
            def punto(u):
                y = a[0] + (b[0] - a[0]) * u
                z = a[1] + (b[1] - a[1]) * u
                return y, z - affondo * math.sin(math.pi * u)
            y0, z0 = punto(u0)
            y1, z1 = punto(u1)
            bm = bmesh.new()
            v = [bm.verts.new(p) for p in [
                (-0.255, y0, z0), (0.255, y0, z0),
                (0.255, y1, z1), (-0.255, y1, z1)]]
            bm.faces.new(v)
            bm.normal_update()
            bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
            bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=0.008)
            fatte.append((bm, i % 2 == 0))
        return fatte

    for bm, blu in telo((-0.27, 0.425), (0.19, 0.495), 5, 0.030):
        mod.add(bm, t["tela_blu"] if blu else t["tela_bianca"])
    for bm, blu in telo((0.21, 0.515), (0.335, 0.845), 4, 0.022):
        mod.add(bm, t["tela_blu"] if blu else t["tela_bianca"])

    mod.appoggia()
    return N.esporta(mod, _out("sedia"))


# ---------------------------------------------------------------------------
# ll'ombrellone
# ---------------------------------------------------------------------------

def ombrellone(m):
    """Otto spicchi cuciti, non otto prismi.

    Il vecchio era fatto di `PrismMesh` messi in cerchio: da sotto si
    vedeva che erano otto cunei staccati. Qui ogni spicchio e' una vela
    vera — tesa fra due stecche e **incavata in mezzo**, come la tela di un
    ombrellone che ha preso la pioggia — e i bordi sono cuciti insieme.
    """
    import bmesh
    mod = N.Modello("ombrellone")
    t = tinte()

    R = 1.20      # raggio della tela
    H_TELA = 2.02  # quota della cima
    CADUTA = 0.46  # quanto scende il bordo rispetto alla cima
    INCAVO = 0.075 # quanto e' incavata la vela fra due stecche

    spicchi = 8
    for s in range(spicchi):
        a0 = 2 * math.pi * s / spicchi
        a1 = 2 * math.pi * (s + 1) / spicchi
        bm = bmesh.new()
        cima = bm.verts.new((0, 0, H_TELA))
        # Tre anelli lungo il raggio, cosi' la vela puo' incurvarsi.
        anelli = []
        for k in (0.34, 0.68, 1.0):
            r = R * k
            z = H_TELA - CADUTA * (k ** 1.7)
            fila = []
            for u in (0.0, 0.5, 1.0):
                a = a0 + (a1 - a0) * u
                # L'incavo e' massimo a meta' fra due stecche.
                giu = INCAVO * math.sin(math.pi * u) * k
                fila.append(bm.verts.new((r * math.cos(a), r * math.sin(a),
                                          z - giu)))
            anelli.append(fila)
        for u in range(2):
            bm.faces.new((cima, anelli[0][u], anelli[0][u + 1]))
        for k in range(2):
            for u in range(2):
                bm.faces.new((anelli[k][u], anelli[k + 1][u],
                              anelli[k + 1][u + 1], anelli[k][u + 1]))
        bm.normal_update()
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
        bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=0.012)
        N.tutto_morbido(bm)
        mod.add(bm, t["tela_rossa"] if s % 2 == 0 else t["tela_crema"])

        # La stecca sotto allo spicchio.
        z0 = H_TELA - 0.02
        z1 = H_TELA - CADUTA - 0.01
        ax = R * math.cos(a0)
        ay = R * math.sin(a0)
        stecca = bmesh.new()
        v = [stecca.verts.new(p) for p in [
            (0, 0, z0 - 0.012), (ax, ay, z1 - 0.012),
            (ax, ay, z1 + 0.006), (0, 0, z0 + 0.006)]]
        stecca.faces.new(v)
        stecca.normal_update()
        bmesh.ops.solidify(stecca, geom=stecca.faces[:], thickness=0.010)
        mod.add(stecca, t["legno_chiaro"])

    # Il palo in due tronchi con la giunzione, e la punta.
    mod.add(N.tutto_morbido(N.cilindro(0.024, 1.20, 12, (0, 0, 0.60))),
            t["legno_chiaro"])
    mod.add(N.tutto_morbido(N.cilindro(0.020, 0.95, 12, (0, 0, 1.62))),
            t["legno_chiaro"])
    mod.add(N.tutto_morbido(N.cilindro(0.030, 0.06, 12, (0, 0, 1.19))),
            t["ferro"])
    mod.add(N.tutto_morbido(N.uvsfera(0.032, 10, 6, (0, 0, H_TELA + 0.03))),
            t["legno"])

    # La base: un disco di cemento, che e' quello che tiene su un
    # ombrellone in piazza — di sabbia non ce n'e'.
    base = N.cilindro(0.24, 0.07, 20, (0, 0, 0.035), raggio2=0.27)
    N.smussa(base, 0.008, 2)
    N.tutto_morbido(base)
    mod.add(base, t["marmo"])

    mod.appoggia()
    return N.esporta(mod, _out("ombrellone"))


# ---------------------------------------------------------------------------
# 'O tavolino
# ---------------------------------------------------------------------------

def tavolino(m):
    """Tavolino da bar: piano tondo di marmo, gamba di ghisa a tre piedi.
    E sopra ci sta la tazzina, che e' la ragione per cui il tavolino esiste
    nel gioco — e va vista da lontano.
    """
    mod = N.Modello("tavolino")
    t = tinte()

    piano = N.cilindro(0.34, 0.028, 28, (0, 0, 0.706))
    N.smussa(piano, 0.006, 2)
    N.tutto_morbido(piano)
    mod.add(piano, t["marmo"])
    bordo = N.toro(0.336, 0.012, 28, 8, (0, 0, 0.700))
    N.tutto_morbido(bordo)
    mod.add(bordo, t["ferro"])

    # La colonna: si stringe a meta' come le gambe di ghisa vere.
    mod.add(N.tutto_morbido(N.cilindro(0.045, 0.30, 14, (0, 0, 0.20),
                                       raggio2=0.030)), t["ferro"])
    mod.add(N.tutto_morbido(N.cilindro(0.030, 0.36, 14, (0, 0, 0.52),
                                       raggio2=0.042)), t["ferro"])
    mod.add(N.tutto_morbido(N.cilindro(0.052, 0.03, 14, (0, 0, 0.685))),
            t["ferro"])

    # Tre piedi che si allargano.
    for i in range(3):
        a = 2 * math.pi * i / 3
        piede = N.cilindro(0.030, 0.24, 8,
                           (0.10 * math.cos(a), 0.10 * math.sin(a), 0.045),
                           rot=(0, 0, 0), raggio2=0.016)
        N.tutto_morbido(piede)
        mod.add(piede, t["ferro"])
        zoccolo = N.cubo((0.05, 0.16, 0.022),
                         (0.155 * math.cos(a), 0.155 * math.sin(a), 0.012),
                         rot=(0, 0, math.degrees(a)))
        N.smussa(zoccolo, 0.006, 2)
        mod.add(zoccolo, t["ferro"])

    # 'A tazzulella, col piattino e il manico.
    piattino = N.cilindro(0.055, 0.008, 16, (0.10, 0.04, 0.724))
    N.tutto_morbido(piattino)
    mod.add(piattino, t["plastica_avorio"])
    tazza = N.cilindro(0.030, 0.052, 14, (0.10, 0.04, 0.756), raggio2=0.026)
    N.tutto_morbido(tazza)
    mod.add(tazza, t["plastica_avorio"])
    caffe = N.cilindro(0.026, 0.004, 14, (0.10, 0.04, 0.778))
    mod.add(caffe, N.materiale("caffe", (0.16, 0.09, 0.05), 0.30))
    manico = N.toro(0.022, 0.005, 12, 6, (0.135, 0.04, 0.756), rot=(90, 0, 0))
    N.tutto_morbido(manico)
    mod.add(manico, t["plastica_avorio"])

    mod.appoggia()
    return N.esporta(mod, _out("tavolino"))


# ---------------------------------------------------------------------------
# 'A radio a transistor
# ---------------------------------------------------------------------------

def radio(m):
    """Una radio anni Settanta: cassa di plastica avorio, griglia forata,
    due manopole cromate, la scala parlante e l'antenna storta.

    La griglia e' fatta di fori veri (una matrice di cilindretti scuri
    incassati), non di una texture: sono duecento triangoli e sono quello
    che la fa leggere come una radio invece che come una scatola.
    """
    mod = N.Modello("radio")
    t = tinte()

    # **Piu' grande di una radiolina vera, e apposta.**
    #
    # A ventisei centimetri era giusta di misura e sbagliata di gioco: sul
    # tavolino spariva, e adesso che ci si preme [E] sopra per cambiare
    # canzone dev'essere una cosa che si vede e si mira da tre metri. Da
    # ventisei a quarantadue: e' un mangianastri, non una radiolina da
    # tasca, ed e' anche piu' napoletano.
    L, P, A = 0.42, 0.145, 0.255
    cassa = N.cubo((L, P, A), (0, 0, A / 2))
    N.smussa(cassa, 0.010, 3)
    mod.add(cassa, t["plastica_avorio"])

    # La faccia: pannello scuro incassato con la griglia dell'altoparlante.
    pannello = N.cubo((L - 0.036, 0.008, A - 0.036), (0, -P / 2 + 0.003,
                                                     A / 2))
    N.smussa(pannello, 0.003, 2)
    mod.add(pannello, t["plastica_nera"])
    for ix in range(9):
        for iz in range(11):
            x = -0.128 + ix * 0.030
            z = 0.058 + iz * 0.0145
            foro = N.cilindro(0.0055, 0.012, 6,
                              (x, -P / 2 + 0.001, z), rot=(90, 0, 0))
            mod.add(foro, N.materiale("griglia", (0.05, 0.05, 0.055), 0.9))

    # La scala parlante, in alto: vetrino chiaro con l'ago rosso.
    scala = N.cubo((0.24, 0.006, 0.040), (0.055, -P / 2 - 0.001, 0.206))
    mod.add(scala, N.materiale("scala", (0.90, 0.87, 0.72), 0.25,
                               emissione=(0.16, 0.14, 0.06)))
    mod.add(N.cubo((0.005, 0.008, 0.044), (0.085, -P / 2 - 0.004, 0.206)),
            N.materiale("ago", (0.80, 0.12, 0.10), 0.4))

    # Le due manopole, sul fianco destro.
    for z in (0.170, 0.082):
        man = N.cilindro(0.028, 0.026, 14, (L / 2 + 0.005, 0, z),
                         rot=(0, 90, 0))
        N.smussa(man, 0.004, 2)
        N.tutto_morbido(man)
        mod.add(man, t["cromo"])
        mod.add(N.cubo((0.005, 0.040, 0.005), (L / 2 + 0.019, 0, z)),
                t["plastica_nera"])

    # Il manico di cuoio in cima.
    for x in (-0.090, 0.090):
        mod.add(N.cubo((0.012, 0.012, 0.024), (x, 0, A + 0.008)),
                t["ferro"])
    arco = N.toro(0.090, 0.009, 18, 6, (0, 0, A + 0.016), rot=(90, 0, 0))
    N.tutto_morbido(arco)
    mod.add(arco, N.materiale("cuoio", (0.32, 0.20, 0.12), 0.75))

    # L'antenna, storta come tutte le antenne.
    mod.add(N.tutto_morbido(N.cilindro(0.0042, 0.44, 6,
                                       (-L / 2 + 0.03, 0.03, A + 0.21),
                                       rot=(-16, 0, 8))), t["cromo"])
    # Due piedini di gomma: appoggiata per terra non striscia sul selciato.
    for x2 in (-0.15, 0.15):
        for y2 in (-0.045, 0.045):
            mod.add(N.tutto_morbido(N.cilindro(0.014, 0.014, 8,
                                               (x2, y2, 0.007))),
                    t["plastica_nera"])

    mod.appoggia()
    return N.esporta(mod, _out("radio"))


# ---------------------------------------------------------------------------
# 'E piante
# ---------------------------------------------------------------------------

def pianta(m):
    """Una pianta in vaso di terracotta. Le foglie sono lame piegate messe
    a raggiera con inclinazioni diverse: e' il minimo che serve perche' non
    sembri un ciuffo di cartone, e costa duecento triangoli.
    """
    import bmesh
    mod = N.Modello("pianta")
    t = tinte()

    # Il vaso: alto quanto largo, come i vasi di terracotta veri. Al primo
    # giro era schiacciato (24 cm di altezza per 26 di bocca) e sembrava
    # una ciotola con dentro un ragno.
    vaso = N.cilindro(0.125, 0.34, 20, (0, 0, 0.17), raggio2=0.082)
    N.smussa(vaso, 0.006, 2)
    N.tutto_morbido(vaso)
    mod.add(vaso, t["terracotta"])
    orlo = N.cilindro(0.134, 0.030, 20, (0, 0, 0.332))
    N.smussa(orlo, 0.004, 2)
    N.tutto_morbido(orlo)
    mod.add(orlo, t["terracotta"])
    mod.add(N.cilindro(0.116, 0.02, 16, (0, 0, 0.326)), t["terra"])

    # Fusto e foglie.
    mod.add(N.tutto_morbido(N.cilindro(0.014, 0.22, 8, (0, 0, 0.44),
                                       raggio2=0.009)), t["foglia"])
    # Lunghezze e angoli irregolari: otto foglie tutte uguali disposte a
    # ventaglio perfetto sono una ruota di carro, non una pianta.
    rng = [(0, 44), (43, 34), (99, 50), (138, 31), (196, 41), (233, 28),
           (291, 47), (327, 37)]
    for i, (grado, lung) in enumerate(rng):
        a = math.radians(grado)
        L = lung / 100.0
        # Una foglia: lama lunga che si piega verso il basso.
        bm = bmesh.new()
        passi = 5
        sx, dx = [], []
        for k in range(passi + 1):
            u = k / passi
            larg = 0.040 * math.sin(math.pi * (0.15 + 0.85 * u)) + 0.005
            r = L * u
            # La piega: sale e poi ricade.
            z = 0.50 + 0.26 * math.sin(math.pi * u * 0.8) - 0.34 * u * u
            sx.append(bm.verts.new((r * math.cos(a) - larg * math.sin(a),
                                    r * math.sin(a) + larg * math.cos(a), z)))
            dx.append(bm.verts.new((r * math.cos(a) + larg * math.sin(a),
                                    r * math.sin(a) - larg * math.cos(a), z)))
        for k in range(passi):
            bm.faces.new((sx[k], dx[k], dx[k + 1], sx[k + 1]))
        bm.normal_update()
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
        bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=0.006)
        N.tutto_morbido(bm)
        mod.add(bm, t["foglia"] if i % 2 == 0 else t["foglia_chiara"])

    mod.appoggia()
    return N.esporta(mod, _out("pianta"))


# ---------------------------------------------------------------------------
# 'E luminarie
# ---------------------------------------------------------------------------

def luminaria(m):
    """Una campata di luminarie: il cavo che fa la catenaria e le lampadine
    appese col loro portalampada.

    Il modello e' **una campata sola**, lunga quattordici metri: la zona ne
    piazza tre affiancate, e tenerle separate vuol dire poterle appendere
    dove servono senza rifare il modello.
    """
    import bmesh
    mod = N.Modello("luminaria")
    t = tinte()

    CAMPATA = 14.0
    CADUTA = 0.9
    LAMPADE = 16

    def quota(u):
        # Catenaria approssimata con una parabola: a occhio non si
        # distinguono, e la parabola non ha coseni iperbolici da calcolare.
        return -CADUTA * 4.0 * u * (1.0 - u)

    # Il cavo: un tubo a sezione quadrata che segue la curva.
    bm = bmesh.new()
    passi = 26
    anelli = []
    for k in range(passi + 1):
        u = k / passi
        x = -CAMPATA / 2 + CAMPATA * u
        z = quota(u)
        s = 0.012
        anelli.append([bm.verts.new(p) for p in [
            (x, -s, z - s), (x, s, z - s), (x, s, z + s), (x, -s, z + s)]])
    for k in range(passi):
        for j in range(4):
            j2 = (j + 1) % 4
            bm.faces.new((anelli[k][j], anelli[k + 1][j],
                          anelli[k + 1][j2], anelli[k][j2]))
    bm.normal_update()
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    mod.add(bm, t["cavo"])

    colori = [
        ("lamp_oro", (1.0, 0.86, 0.42)),
        ("lamp_rossa", (1.0, 0.36, 0.30)),
        ("lamp_azzurra", (0.42, 0.80, 1.0)),
        ("lamp_verde", (0.52, 1.0, 0.48)),
    ]
    for i in range(LAMPADE):
        u = (i + 0.5) / LAMPADE
        x = -CAMPATA / 2 + CAMPATA * u
        z = quota(u)
        mod.add(N.tutto_morbido(N.cilindro(0.014, 0.045, 8,
                                           (x, 0, z - 0.030))), t["ferro"])
        nome, col = colori[i % len(colori)]
        bulbo = N.uvsfera(0.032, 10, 7, (x, 0, z - 0.082),
                          scala=(1.0, 1.0, 1.18))
        N.tutto_morbido(bulbo)
        mod.add(bulbo, N.materiale(nome, col, 0.22,
                                   emissione=(col[0] * 1.6, col[1] * 1.6,
                                              col[2] * 1.6)))

    return N.esporta(mod, _out("luminaria"))


# ---------------------------------------------------------------------------

def tutte():
    N.nuova_scena()
    fatti = []
    for f in (sedia, ombrellone, tavolino, radio, pianta, luminaria):
        fatti.append(f(None))
    return fatti


if __name__ == "__main__":
    for r in tutte():
        print("%-42s  %5d vert  %5d tri  %d mat" % (
            os.path.basename(r["file"]), r["vertici"], r["triangoli"],
            r["materiali"]))
