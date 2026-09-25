"""L'arredo urbano e i pezzi delle facciate.

Due famiglie diverse, e vanno usate in due modi diversi:

## 1. I pezzi che si ripetono migliaia di volte

Il **balaustrino** e' uno solo, ma la citta' ne disegna qualche migliaio:
uno ogni sedici centimetri, su ogni balcone, su ogni palazzo. Non si puo'
istanziare un nodo per ognuno — e infatti il gioco li mette gia' tutti in
un MultiMesh solo. Il trucco e' che la mesh del MultiMesh **puo' essere
questa invece di un cubo**: stesse istanze, stesso costo di disegno, ma al
posto di uno stecchino quadrato c'e' un ferro battuto con la pancia.

E' il modo piu' economico che esista di migliorare una citta' intera: una
mesh da centoventi triangoli, moltiplicata per tremila, e le facciate
cambiano faccia senza toccare il numero di draw call.

## 2. I pezzi che ci sono a decine

Lampione, panchina, cestino, cassonetto, fontanella. Qui il modello si
istanzia normalmente, o si mette anche lui in un MultiMesh se il gioco lo
fa gia'.

## Le misure

    balaustrino  86 cm (l'altezza fra traversa e corrimano)
    lampione     5,20 m col globo
    panchina     1,80 x 0,62 x 0,84
    cestino      0,92 m
    cassonetto   1,25 x 1,05 x 1,30
    fontanella   1,15 m (quella a colonnina di ghisa)
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
        "ghisa": N.materiale("ghisa", (0.13, 0.14, 0.16), 0.58, 0.30),
        "ferro_verde": N.materiale("ferro_verde", (0.16, 0.22, 0.19), 0.62, 0.25),
        "legno_panca": N.materiale("legno_panca", (0.48, 0.31, 0.17), 0.78),
        "vetro_caldo": N.materiale("vetro_caldo", (1.0, 0.94, 0.76), 0.20,
                                   emissione=(1.0, 0.90, 0.62)),
        "plastica_verde": N.materiale("plastica_verde", (0.16, 0.34, 0.22), 0.60),
        "plastica_grigia": N.materiale("plastica_grigia", (0.30, 0.31, 0.30), 0.62),
        "acciaio": N.materiale("acciaio", (0.62, 0.63, 0.66), 0.34, 0.80),
        "ottone": N.materiale("ottone", (0.72, 0.56, 0.22), 0.30, 0.85),
        "pietra": N.materiale("pietra", (0.72, 0.70, 0.64), 0.92),
        "acqua": N.materiale("acqua", (0.55, 0.72, 0.80), 0.10, 0.0, alpha=0.6),
    }


# ---------------------------------------------------------------------------
# 'O balaustrino
# ---------------------------------------------------------------------------

def balaustrino(_=None):
    """Un ferro di ringhiera napoletana: dritto in alto e in basso, con la
    **pancia** in mezzo. È quella pancia che distingue una ringhiera di
    ferro battuto da una recinzione di cantiere, e da lontano è tutto
    quello che si vede.

    Sta in piedi da solo, alto 86 cm, con l'origine alla base: il codice
    delle facciate lo appoggia dove appoggiava lo stecchino.
    """
    import bmesh
    mod = N.Modello("balaustrino")
    t = tinte()

    H = 0.86
    # Il profilo del raggio lungo l'altezza: sottile agli estremi, gonfio
    # a metà. Due gonfiori invece di uno: quello grande sotto e uno più
    # piccolo sopra, come i ferri veri fatti a doppia voluta.
    def raggio(u):
        base = 0.016
        pancia = 0.028 * math.sin(math.pi * min(u / 0.62, 1.0)) if u < 0.62 else 0.0
        secondo = 0.016 * math.sin(math.pi * ((u - 0.62) / 0.38)) if u >= 0.62 else 0.0
        return base + pancia + secondo

    bm = bmesh.new()
    passi = 12
    lati = 6
    anelli = []
    for k in range(passi + 1):
        u = k / passi
        r = raggio(u)
        z = H * u
        anelli.append([bm.verts.new((r * math.cos(2 * math.pi * i / lati),
                                     r * math.sin(2 * math.pi * i / lati), z))
                       for i in range(lati)])
    for k in range(passi):
        for i in range(lati):
            j = (i + 1) % lati
            bm.faces.new((anelli[k][i], anelli[k + 1][i],
                          anelli[k + 1][j], anelli[k][j]))
    bm.faces.new(list(reversed(anelli[0])))
    bm.faces.new(anelli[-1])
    bm.normal_update()
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    N.tutto_morbido(bm)
    mod.add(bm, t["ghisa"])

    # I due collarini: gli anelli schiacciati sopra e sotto la pancia. Sono
    # il dettaglio che dice "battuto a mano" e costano ventiquattro facce.
    for z in (0.20, 0.56):
        anello = N.toro(0.030, 0.008, 8, 5, (0, 0, z))
        N.tutto_morbido(anello)
        mod.add(anello, t["ghisa"])
    return N.esporta(mod, _out("balaustrino"))


# ---------------------------------------------------------------------------
# 'O lampione
# ---------------------------------------------------------------------------

def lampione(_=None):
    """Il lampione di ghisa: base a plinto, fusto rastremato con le
    scanalature, braccio ricurvo e il globo. Quello vecchio era un cilindro
    con sopra una sfera.
    """
    mod = N.Modello("lampione")
    t = tinte()

    # Plinto: due gradini quadri, come tutti i lampioni di ghisa.
    base = N.cubo((0.34, 0.34, 0.10), (0, 0, 0.05))
    N.smussa(base, 0.012, 2)
    mod.add(base, t["ghisa"])
    base2 = N.cubo((0.26, 0.26, 0.09), (0, 0, 0.145))
    N.smussa(base2, 0.010, 2)
    mod.add(base2, t["ghisa"])
    coll = N.cilindro(0.115, 0.09, 12, (0, 0, 0.235), raggio2=0.085)
    N.tutto_morbido(coll)
    mod.add(coll, t["ghisa"])

    # Fusto in due tronchi con l'anello di giunzione.
    mod.add(N.tutto_morbido(N.cilindro(0.075, 2.1, 12, (0, 0, 1.33),
                                       raggio2=0.062)), t["ghisa"])
    anello = N.toro(0.072, 0.013, 12, 6, (0, 0, 2.38))
    N.tutto_morbido(anello)
    mod.add(anello, t["ghisa"])
    mod.add(N.tutto_morbido(N.cilindro(0.058, 1.6, 12, (0, 0, 3.20),
                                       raggio2=0.046)), t["ghisa"])

    # Il braccio ricurvo che porta il globo fuori dal palo. È la sagoma
    # che si riconosce controluce.
    braccio = N.tubo([
        (0, 0, 3.96), (0, 0.04, 4.24), (0, 0.20, 4.46),
        (0, 0.42, 4.56), (0, 0.60, 4.56),
    ], 0.032, 8)
    N.tutto_morbido(braccio)
    mod.add(braccio, t["ghisa"])

    # Il cappello e il globo.
    mod.add(N.tutto_morbido(N.cilindro(0.16, 0.10, 14, (0, 0.60, 4.60),
                                       raggio2=0.055)), t["ghisa"])
    globo = N.uvsfera(0.15, 14, 9, (0, 0.60, 4.40), scala=(1.0, 1.0, 1.15))
    N.tutto_morbido(globo)
    mod.add(globo, t["vetro_caldo"])
    mod.add(N.tutto_morbido(N.uvsfera(0.028, 8, 5, (0, 0.60, 4.24))),
            t["ghisa"])
    return N.esporta(mod, _out("lampione"))


# ---------------------------------------------------------------------------
# 'A panchina
# ---------------------------------------------------------------------------

def panchina(_=None):
    """Panchina da giardino pubblico: due fianchi di ghisa a voluta e le
    doghe di legno. Cinque per la seduta, quattro per lo schienale, con la
    fessura in mezzo — che è quello che la fa leggere come una panchina
    invece che come un blocco.
    """
    mod = N.Modello("panchina")
    t = tinte()

    L = 1.80
    for lato in (-1, 1):
        x = lato * (L / 2 - 0.07)
        # Il fianco: piede, gamba, seduta, montante dello schienale.
        bm = N.tubo([
            (x, -0.28, 0.01), (x, -0.26, 0.06), (x, -0.24, 0.40),
            (x, 0.00, 0.42), (x, 0.24, 0.44), (x, 0.28, 0.52),
            (x, 0.30, 0.86),
        ], 0.026, 8)
        N.tutto_morbido(bm)
        mod.add(bm, t["ghisa"])
        # Il piede posteriore e la voluta.
        bm2 = N.tubo([(x, 0.26, 0.01), (x, 0.26, 0.20), (x, 0.10, 0.41)],
                     0.022, 8)
        N.tutto_morbido(bm2)
        mod.add(bm2, t["ghisa"])
        for p in ((x, -0.27, 0.012), (x, 0.26, 0.012)):
            mod.add(N.cubo((0.075, 0.11, 0.024), p), t["ghisa"])

    # Le doghe della seduta.
    for i in range(5):
        y = -0.24 + i * 0.115
        d = N.cubo((L, 0.088, 0.030), (0, y, 0.435 + i * 0.004))
        N.smussa(d, 0.008, 2)
        mod.add(d, t["legno_panca"])
    # Quelle dello schienale, inclinate all'indietro.
    for i in range(4):
        z = 0.53 + i * 0.105
        d = N.cubo((L, 0.030, 0.088), (0, 0.28 + i * 0.012, z),
                   rot=(-8, 0, 0))
        N.smussa(d, 0.008, 2)
        mod.add(d, t["legno_panca"])
    return N.esporta(mod, _out("panchina"))


# ---------------------------------------------------------------------------
# 'O cestino
# ---------------------------------------------------------------------------

def cestino(_=None):
    """Il cestino della spazzatura: gabbia di stecche verticali appesa a un
    palo, col coperchietto a mezza luna. È il modello di cestino che sta in
    ogni piazza italiana.
    """
    mod = N.Modello("cestino")
    t = tinte()

    mod.add(N.tutto_morbido(N.cilindro(0.055, 0.03, 12, (0, 0, 0.015),
                                       raggio2=0.045)), t["ghisa"])
    mod.add(N.tutto_morbido(N.cilindro(0.032, 0.90, 10, (0, 0, 0.45))),
            t["ghisa"])

    # La gabbia: dodici stecche fra due cerchi.
    for i in range(12):
        a = 2 * math.pi * i / 12
        r = 0.135
        mod.add(N.tutto_morbido(N.cilindro(0.008, 0.36, 6,
                                           (0.13 + r * math.cos(a) * 0,
                                            0, 0)) if False else
                                N.cilindro(0.008, 0.36, 6,
                                           (r * math.cos(a) + 0.17,
                                            r * math.sin(a), 0.46))),
                t["ferro_verde"])
    for z in (0.30, 0.62):
        anello = N.toro(0.135, 0.011, 16, 6, (0.17, 0, z))
        N.tutto_morbido(anello)
        mod.add(anello, t["ferro_verde"])
    # Il fondo.
    mod.add(N.tutto_morbido(N.cilindro(0.135, 0.014, 16, (0.17, 0, 0.29))),
            t["ferro_verde"])
    # Il coperchio inclinato.
    cop = N.cilindro(0.155, 0.020, 16, (0.17, 0, 0.665), raggio2=0.125)
    N.tutto_morbido(cop)
    mod.add(cop, t["ferro_verde"])
    # Il braccetto che lo tiene al palo.
    mod.add(N.cubo((0.075, 0.030, 0.030), (0.075, 0, 0.60)), t["ghisa"])
    return N.esporta(mod, _out("cestino"))


# ---------------------------------------------------------------------------
# 'O cassonetto
# ---------------------------------------------------------------------------

def cassonetto(_=None):
    """Il cassonetto: cassa svasata di plastica, coperchio bombato che sta
    mezzo aperto (perché è sempre mezzo aperto), maniglie laterali e quattro
    ruote piroettanti.
    """
    mod = N.Modello("cassonetto")
    t = tinte()

    L, P, A = 1.24, 1.00, 1.05
    cassa = N.cubo((L, P, A), (0, 0, A / 2 + 0.11))
    # Svasata: si stringe verso il basso, come tutti i cassonetti.
    import bmesh
    from mathutils import Vector, Matrix
    for v in cassa.verts:
        if v.co.z < A / 2 + 0.11:
            v.co.x *= 0.84
            v.co.y *= 0.84
    N.smussa(cassa, 0.028, 2)
    mod.add(cassa, t["plastica_verde"])

    # Il bordo superiore, più chiaro.
    bordo = N.cubo((L + 0.04, P + 0.04, 0.055), (0, 0, A + 0.135))
    N.smussa(bordo, 0.014, 2)
    mod.add(bordo, t["plastica_grigia"])

    # Il coperchio, sollevato dietro come se non chiudesse.
    cop = N.cubo((L - 0.02, P - 0.02, 0.075), (0, 0.02, A + 0.20),
                 rot=(-13, 0, 0))
    N.smussa(cop, 0.020, 2)
    mod.add(cop, t["plastica_grigia"])
    # Il manico del coperchio.
    mod.add(N.tutto_morbido(N.cilindro(0.020, L * 0.5, 8,
                                       (0, -P / 2 + 0.04, A + 0.28),
                                       rot=(0, 90, 0))), t["plastica_grigia"])

    # Le maniglie laterali e la barra della presa del camion.
    for sx in (-1, 1):
        mod.add(N.tutto_morbido(N.cilindro(0.022, 0.30, 8,
                                           (sx * (L / 2 + 0.03), 0, A - 0.06),
                                           rot=(90, 0, 0))),
                t["plastica_grigia"])
    mod.add(N.tutto_morbido(N.cilindro(0.026, L * 0.7, 8,
                                       (0, -P / 2 - 0.05, 0.52),
                                       rot=(0, 90, 0))), t["acciaio"])

    # Quattro ruote.
    for sx in (-1, 1):
        for sy in (-1, 1):
            p = (sx * (L / 2 - 0.16), sy * (P / 2 - 0.16), 0.055)
            mod.add(N.tutto_morbido(N.cilindro(0.055, 0.045, 10, p,
                                               rot=(0, 90, 0))),
                    t["plastica_grigia"])
            mod.add(N.cubo((0.05, 0.06, 0.10),
                           (p[0], p[1], 0.14)), t["plastica_grigia"])
    return N.esporta(mod, _out("cassonetto"))


# ---------------------------------------------------------------------------
# 'A funtanella
# ---------------------------------------------------------------------------

def fontanella(_=None):
    """La fontanella di ghisa, quella a colonnina col mascherone e il
    getto che non si chiude mai. Sta in ogni piazza di Napoli e in nessun
    gioco.
    """
    mod = N.Modello("fontanella")
    t = tinte()

    # Vasca a terra e chiusino.
    vasca = N.cilindro(0.34, 0.10, 18, (0, 0, 0.05), raggio2=0.30)
    N.smussa(vasca, 0.010, 2)
    N.tutto_morbido(vasca)
    mod.add(vasca, t["pietra"])
    mod.add(N.tutto_morbido(N.cilindro(0.26, 0.02, 16, (0, 0, 0.095))),
            t["ghisa"])

    # La colonnina: base, fusto scanalato, capitello.
    mod.add(N.tutto_morbido(N.cilindro(0.135, 0.14, 12, (0, 0, 0.17),
                                       raggio2=0.105)), t["ghisa"])
    mod.add(N.tutto_morbido(N.cilindro(0.095, 0.78, 12, (0, 0, 0.63),
                                       raggio2=0.082)), t["ghisa"])
    for i in range(8):
        a = 2 * math.pi * i / 8
        mod.add(N.tutto_morbido(N.cilindro(0.010, 0.72, 5,
                                           (0.090 * math.cos(a),
                                            0.090 * math.sin(a), 0.63))),
                t["ghisa"])
    cap = N.cilindro(0.125, 0.10, 12, (0, 0, 1.06), raggio2=0.095)
    N.smussa(cap, 0.008, 2)
    N.tutto_morbido(cap)
    mod.add(cap, t["ghisa"])
    mod.add(N.tutto_morbido(N.uvsfera(0.048, 10, 6, (0, 0, 1.14))),
            t["ghisa"])

    # Il mascherone e il cannello, con l'acqua che scende.
    mod.add(N.tutto_morbido(N.uvsfera(0.070, 10, 7, (0, -0.085, 0.86),
                                      scala=(1.0, 0.7, 1.1))), t["ghisa"])
    cannello = N.tubo([(0, -0.10, 0.845), (0, -0.16, 0.835),
                       (0, -0.19, 0.805)], 0.017, 8)
    N.tutto_morbido(cannello)
    mod.add(cannello, t["ottone"])
    getto = N.cilindro(0.010, 0.68, 6, (0, -0.192, 0.46))
    N.tutto_morbido(getto)
    mod.add(getto, t["acqua"])
    return N.esporta(mod, _out("fontanella"))


# ---------------------------------------------------------------------------

def tutti():
    N.nuova_scena()
    return [f() for f in (balaustrino, lampione, panchina, cestino,
                          cassonetto, fontanella)]


if __name__ == "__main__":
    for r in tutti():
        print("%-42s  %5d vert  %5d tri  %d mat" % (
            os.path.basename(r["file"]), r["vertici"], r["triangoli"],
            r["materiali"]))
