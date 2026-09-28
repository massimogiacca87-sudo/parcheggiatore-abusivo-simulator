#!/usr/bin/env python3
"""'E facce d''o pupo (0.66): bocche, barbe, rughe, stoffe, ciocche e iride.

Il pupo nuovo ha la faccia liscia di Schedule I: gli occhi a palla, le
palpebre grosse, il naso e le sopracciglia sono geometria. Tutto il resto si
**dipinge** sulla pelle dallo shader `pupo_faccia.gdshader`:

    colore = pelle x bocca.rgb x rughe.rgb      (bianco = non cambia niente)
    colore = mix(colore, peli, barba.r)         (nero = niente peli)

Qui si disegnano, a mano ma col computer, gli strati di quella faccia: la
linea della bocca (dritta, 'a cazzimma, 'o sorriso, storta, preoccupata, 'o
rossetto d''a signora), le barbe (sfatta, pizzetto, piena, basette) e le
rughe (stanco, vecchio, vecchia, arraggiato). Più le trame grigie che
moltiplicano le tinte scelte dal gioco: la stoffa della camicia, quella dei
cazune, le ciocche dei capelli e l'iride.

**Il contratto delle UV della faccia** (fissato, al pixel): 256x256,
proiezione piatta da davanti, (0,0) in alto a sinistra. Una finestra di
0,26 m centrata sul centro della testa: u = 0.5 + x/0.26, v = 0.5 - (z-zc)/0.26.
Occhi a (85.7, 116.2) e (170.3, 116.2), naso a (128, 146), bocca a (128, 189),
mento a py 251. **Il quadratino 16x16 in alto a sinistra è neutro**: ci
finiscono tutte le facce della nuca e dei lati.

I tratti si disegnano a 4x come campi di distanza (bordi puliti, spessore che
si affusola) e si riducono con la media: niente sfocature, niente scalini.
Tutto col seme fisso: rilanciato, dà gli stessi file al byte.

Uso: python3 tools/genera_pupo_texture.py [--senza-anteprime]
     (scrive in assets/textures/pupo/, le anteprime in
     _claude_tmp/grafica/texture/)
"""
import argparse
from math import comb
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

QUI = Path(__file__).resolve().parent
PROGETTO = QUI.parent
USCITA = PROGETTO / "assets" / "textures" / "pupo"
ANTEPRIME = PROGETTO.parent.parent / "_claude_tmp" / "grafica" / "texture"

LATO = 256          # la faccia
S = 4               # si disegna a 4x e si riduce
SEME = 66066

# ---- Il contratto delle UV (pixel della texture 256) -------------------
OCCHI_XY = ((85.7, 116.2), (170.3, 116.2))
R_OCCHIO = 24.0
R_PALPEBRA = 28.0
NASO = (128.0, 146.0)
BOCCA = (128.0, 189.0)
MEZZO = 128.0       # lo specchio: x -> 256 - x (pixel i <-> 255 - i)

# ---- I colori dei tratti (moltiplicano la pelle: bruni caldi, mai grigi)
LINEA = (0.38, 0.22, 0.20)          # la linea della bocca
LINEA_SCURA = (0.31, 0.16, 0.15)    # il contorno della bocca aperta
DENTRO = (0.36, 0.15, 0.15)         # la bocca aperta
LENGUA = (0.60, 0.30, 0.30)
LABBRO = (0.82, 0.68, 0.64)         # l'ombra sotto al labbro di sotto
FOSSETTA = (0.64, 0.46, 0.42)
ROSSETTO = (0.78, 0.22, 0.26)
ROSSETTO_SU = (0.70, 0.18, 0.23)    # il labbro di sopra, un filo in ombra
ROSSETTO_BORDO = (0.56, 0.13, 0.17)
ROSSETTO_LUCE = (0.90, 0.46, 0.48)
ROSSETTO_TAGLIO = (0.36, 0.10, 0.12)
RUGA_FORTE = (0.64, 0.48, 0.42)
RUGA = (0.72, 0.56, 0.50)
RUGA_LEGGERA = (0.80, 0.66, 0.60)
BORSA = (0.88, 0.76, 0.72)          # il gonfio sotto all'occhio

# griglia fine: centri dei pixel a 4x, in coordinate della texture 256
_C = (np.arange(LATO * S, dtype=np.float32) + 0.5) / S
GX, GY = np.meshgrid(_C, _C)


# =========================================================================
#  Attrezzi di disegno
# =========================================================================

def curva(*ctrl, passo=0.35):
    """Una curva di Bézier (qualsiasi grado) campionata ogni `passo` px."""
    p = np.asarray(ctrl, np.float64)
    grado = len(p) - 1
    lung = float(np.sum(np.hypot(*np.diff(p, axis=0).T)))
    n = max(2, int(lung / passo) + 1)
    t = np.linspace(0.0, 1.0, n)[:, None]
    return sum(comb(grado, i) * (1 - t) ** (grado - i) * t ** i * p[i]
               for i in range(grado + 1))


def catena(*pezzi):
    """Più curve una dopo l'altra (il punto di giunzione una volta sola)."""
    out = [pezzi[0]]
    for q in pezzi[1:]:
        out.append(q[1:])
    return np.concatenate(out)


def specchio(pts):
    q = np.array(pts, np.float64)
    q[:, 0] = 2 * MEZZO - q[:, 0]
    return q


def fuso(n_o_pts, r_mezzo, r_capo, r_coda=None, forma=0.6):
    """I raggi lungo un tratto: pieno in mezzo, affusolato ai capi."""
    n = n_o_pts if isinstance(n_o_pts, int) else len(n_o_pts)
    if r_coda is None:
        r_coda = r_capo
    t = np.linspace(0.0, 1.0, n)
    base = r_capo + (r_coda - r_capo) * t
    return base + (r_mezzo - base) * np.sin(np.pi * t) ** forma


def alfa_tratto(pts, raggi):
    """Copertura (0..1, a 4x) di un tratto a spessore variabile: unione di
    capsule, ognuna col suo raggio che cambia lungo il segmento."""
    pts = np.asarray(pts, np.float32)
    raggi = np.broadcast_to(np.asarray(raggi, np.float32), (len(pts),))
    a = np.zeros((LATO * S, LATO * S), np.float32)
    for i in range(len(pts) - 1):
        p0, p1 = pts[i], pts[i + 1]
        r0, r1 = float(raggi[i]), float(raggi[i + 1])
        m = max(r0, r1) + 1.0
        x0 = max(0, int((min(p0[0], p1[0]) - m) * S))
        x1 = min(LATO * S, int((max(p0[0], p1[0]) + m) * S) + 2)
        y0 = max(0, int((min(p0[1], p1[1]) - m) * S))
        y1 = min(LATO * S, int((max(p0[1], p1[1]) + m) * S) + 2)
        if x1 <= x0 or y1 <= y0:
            continue
        X = GX[y0:y1, x0:x1]
        Y = GY[y0:y1, x0:x1]
        d = p1 - p0
        l2 = float(d @ d) or 1e-9
        t = np.clip(((X - p0[0]) * d[0] + (Y - p0[1]) * d[1]) / l2, 0.0, 1.0)
        dist = np.hypot(X - (p0[0] + t * d[0]), Y - (p0[1] + t * d[1]))
        cov = np.clip((r0 + t * (r1 - r0) - dist) * S + 0.5, 0.0, 1.0)
        np.maximum(a[y0:y1, x0:x1], cov, out=a[y0:y1, x0:x1])
    return a


def alfa_poligono(pts):
    """Copertura (a 4x) di un poligono pieno."""
    im = Image.new("L", (LATO * S, LATO * S), 0)
    ImageDraw.Draw(im).polygon([(x * S - 0.5, y * S - 0.5) for x, y in pts],
                               fill=255)
    return np.asarray(im, np.float32) / 255.0


def alfa_ellisse(cx, cy, rx, ry, morbido=0.0):
    """Copertura (a 4x) di un'ellisse; `morbido` = sfumatura in px."""
    d = np.hypot((GX - cx) / rx, (GY - cy) / ry)
    bordo = (1.0 - d) * min(rx, ry)          # ~distanza dal bordo, in px
    if morbido > 0:
        return np.clip(bordo / morbido + 0.5, 0.0, 1.0)
    return np.clip(bordo * S + 0.5, 0.0, 1.0)


def liscio(x, a, b):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def riduci(a):
    """Da 4x a 1x con la media (il filtro giusto per le coperture)."""
    if a.ndim == 3:
        return a.reshape(LATO, S, LATO, S, a.shape[2]).mean(axis=(1, 3))
    return a.reshape(LATO, S, LATO, S).mean(axis=(1, 3))


def sfuma(a, sigma, giro=False):
    """Sfocatura gaussiana separabile (sigma in pixel del campo). `giro` =
    il campo si ripete (per le trame), se no i bordi si allungano."""
    r = max(1, int(3 * sigma + 0.5))
    k = np.exp(-0.5 * (np.arange(-r, r + 1) / sigma) ** 2).astype(np.float32)
    k /= k.sum()
    out = np.asarray(a, np.float32)
    for asse in (0, 1):
        n = out.shape[asse]
        pad = [(0, 0), (0, 0)]
        pad[asse] = (r, r)
        p = np.pad(out, pad, mode="wrap" if giro else "edge")
        acc = np.zeros_like(out)
        for j, kj in enumerate(k):
            acc += kj * (p[j:j + n] if asse == 0 else p[:, j:j + n])
        out = acc
    return out


class Tela:
    """Una tela moltiplicativa a 4x: parte bianca, ogni tratto si stende
    sopra al precedente col suo colore."""

    def __init__(self):
        self.c = np.ones((LATO * S, LATO * S, 3), np.float32)
        self.nucleo = np.zeros((LATO * S, LATO * S), np.float32)

    def stendi(self, alfa, colore, forza=1.0, nucleo=True):
        a = (alfa * forza)[..., None]
        self.c += (np.asarray(colore, np.float32) - self.c) * a
        if nucleo:
            np.maximum(self.nucleo, alfa, out=self.nucleo)

    def tratto(self, pts, raggi, colore, forza=1.0, nucleo=True, doppio=False):
        """Un tratto; `doppio` = pure quello specchiato."""
        self.stendi(alfa_tratto(pts, raggi), colore, forza, nucleo)
        if doppio:
            self.stendi(alfa_tratto(specchio(pts), raggi), colore, forza, nucleo)

    def finita(self):
        return riduci(self.c)


def a_byte(a):
    return (np.clip(a, 0.0, 1.0) * 255.0 + 0.5).astype(np.uint8)


def salva(arr, nome):
    """Salva RGB (anche le grigie: così nessun rendering le legge rosse)."""
    arr = np.asarray(arr, np.float32)
    if arr.ndim == 2:
        arr = np.repeat(arr[..., None], 3, axis=2)
    USCITA.mkdir(parents=True, exist_ok=True)
    p = USCITA / nome
    Image.fromarray(a_byte(arr), "RGB").save(p, optimize=True)
    return p


# =========================================================================
#  Le bocche (RGB moltiplicativo: bianco = pelle com'è)
# =========================================================================

def bocca_dritta():
    """'A faccia 'e niente: una linea, appena più grossa in mezzo, con gli
    angoli che si chiudono di un filo."""
    t = Tela()
    p = curva((105, 190.0), (116, 188.7), (140, 188.7), (151, 190.0))
    t.tratto(p, fuso(p, 2.4, 1.0), LINEA)
    q = curva((119.5, 196.6), (128, 198.4), (136.5, 196.6))
    t.tratto(q, fuso(q, 1.1, 0.35), LABBRO)
    return t


def bocca_cazzimma():
    """'A cazzimma: il sorrisetto storto di chi ti sta sfottendo. A sinistra
    la bocca resta dritta, a destra sale e si chiude con la piega della
    guancia."""
    t = Tela()
    p = catena(curva((104.5, 191.2), (115, 191.3), (126, 190.7)),
               curva((126, 190.7), (139, 190.0), (147.5, 187.4), (152.8, 181.6)))
    n = len(p)
    tt = np.linspace(0, 1, n)
    r = np.interp(tt, [0.0, 0.12, 0.45, 0.80, 0.94, 1.0],
                  [0.9, 1.7, 2.45, 2.2, 1.7, 1.0])
    t.tratto(p, r, LINEA)
    # la piega della guancia che sale (la parentesi della cazzimma)
    q = curva((154.2, 176.5), (159.2, 182.0), (156.6, 189.0))
    t.tratto(q, fuso(q, 1.25, 0.4), FOSSETTA, nucleo=False)
    # il labbro di sotto, solo dal lato fermo
    q = curva((113, 197.4), (120, 198.8), (129, 197.8))
    t.tratto(q, fuso(q, 1.05, 0.35), LABBRO)
    return t


def bocca_sorriso():
    """'O sorriso aperto: una mezzaluna scura con la lingua in fondo, gli
    angoli che salgono e le due fossette."""
    t = Tela()
    su = curva((103, 183.0), (116, 186.8), (140, 186.8), (153, 183.0))
    giu = curva((153, 183.0), (150, 205.0), (106, 205.0), (103, 183.0))
    bordo = catena(su, giu)
    dentro = alfa_poligono(bordo)
    t.stendi(dentro, DENTRO)
    lengua = alfa_ellisse(128, 201.5, 14.0, 6.0) * dentro
    t.stendi(lengua, LENGUA)
    t.tratto(bordo, 1.0, LINEA_SCURA)
    # gli angoli che salgono un filo oltre la mezzaluna
    a = curva((103.4, 183.4), (101.2, 182.2), (100.0, 180.2))
    t.tratto(a, np.linspace(1.2, 0.45, len(a)), LINEA_SCURA, nucleo=False,
             doppio=True)
    # le fossette: due parentesi fuori dagli angoli
    f = curva((97.0, 176.5), (93.6, 183.5), (97.2, 190.5))
    t.tratto(f, fuso(f, 1.3, 0.4), FOSSETTA, nucleo=False, doppio=True)
    return t


def bocca_storta():
    """Scucciato: gli angoli in giù, uno più dell'altro, e il labbro di
    sotto che sporge."""
    t = Tela()
    p = curva((104.5, 196.2), (112, 187.2), (141, 186.2), (151.5, 193.2))
    t.tratto(p, fuso(p, 2.35, 0.95), LINEA)
    q = curva((120, 196.8), (128, 199.0), (136, 196.6))
    t.tratto(q, fuso(q, 1.15, 0.35), LABBRO)
    return t


def bocca_preoccupata():
    """'A linea ca trema (Schedule I): due onde, gli angoli in giù."""
    t = Tela()
    x = np.linspace(105.0, 151.0, 180)
    y = 189.6 - 2.3 * np.sin(2 * np.pi * (x - 105.0) / 23.0) \
        + 2.8 * ((x - 128.0) / 23.0) ** 2
    p = np.stack([x, y], axis=1)
    t.tratto(p, fuso(p, 1.9, 0.9, forma=0.25), LINEA)
    return t


def bocca_rossetto():
    """'A signora: labbra piene col rossetto rosso scuro, l'arco di Cupido,
    il bordo più scuro e un filo di luce sul labbro di sotto."""
    t = Tela()
    arco = catena(curva((106.5, 189.3), (112, 184.8), (117.5, 181.4), (122.2, 181.6)),
                  curva((122.2, 181.6), (125.2, 182.0), (127.0, 183.8), (128.0, 183.9)))
    arco = np.concatenate([arco, specchio(arco[::-1])[1:]])
    taglio = curva((106.5, 189.3), (118, 190.6), (138, 190.6), (149.5, 189.3))
    sotto = curva((149.5, 189.3), (146.5, 199.2), (109.5, 199.2), (106.5, 189.3))
    labbro_su = np.concatenate([arco, taglio[::-1][1:]])
    labbro_giu = np.concatenate([taglio, sotto[1:]])
    t.stendi(alfa_poligono(labbro_giu), ROSSETTO)
    t.stendi(alfa_poligono(labbro_su), ROSSETTO_SU)
    t.stendi(alfa_ellisse(131.0, 194.2, 6.5, 1.7, morbido=1.6), ROSSETTO_LUCE,
             forza=0.85, nucleo=False)
    t.tratto(arco, 0.65, ROSSETTO_BORDO)
    t.tratto(sotto, 0.65, ROSSETTO_BORDO)
    t.tratto(taglio, fuso(taglio, 1.3, 0.55), ROSSETTO_TAGLIO)
    return t


BOCCHE = {
    "dritta": bocca_dritta, "cazzimma": bocca_cazzimma,
    "sorriso": bocca_sorriso, "storta": bocca_storta,
    "preoccupata": bocca_preoccupata, "rossetto": bocca_rossetto,
}


# =========================================================================
#  Le rughe (RGB moltiplicativo)
# =========================================================================

def _borse(t, colore_linea=RUGA, forza_gonfio=1.0, r_linea=1.05, doppia=False):
    """Le borse sotto agli occhi: una mezzaluna calda che sporge sotto la
    palpebra di sotto, chiusa da una linea. Il gonfio parte dal bordo della
    palpebra (28 px dal centro dell'occhio, dove resta neutro) e la linea lo
    chiude poco più in fuori: in fondo py ~144-150, ai lati sale fino a
    py ~132."""
    for i, (cx, cy) in enumerate(OCCHI_XY):
        segno = 1.0 if i == 0 else -1.0     # verso il naso
        # in coordinate polari attorno all'occhio: angolo 0 = verso il naso
        dx = (GX - cx) * segno
        dy = GY - cy
        r = np.hypot(dx, dy)
        th = np.degrees(np.arctan2(dy, dx))          # 90 = giù
        larga = np.clip(np.sin(np.radians(np.clip(th, 0, 180))), 0, 1)
        finestra = liscio(th, 28, 55) * (1 - liscio(th, 138, 158))
        spess = 5.0 * larga ** 1.5
        # parte neutro sul bordo della palpebra (lì attacca la geometria
        # color pelle: ogni differenza sarebbe una cucitura)
        dentro = liscio(r, R_PALPEBRA, R_PALPEBRA + 2.0) * \
            (1 - liscio(r, R_PALPEBRA + spess - 1.0, R_PALPEBRA + spess + 0.6))
        t.stendi(dentro * finestra, BORSA, forza=forza_gonfio, nucleo=False)
        # la linea: segue il bordo di fuori della mezzaluna
        ang = np.radians(np.linspace(40, 150, 90))
        rr = R_PALPEBRA + 5.0 * np.sin(ang) ** 1.5
        p = np.stack([cx + segno * rr * np.cos(ang), cy + rr * np.sin(ang)], 1)
        t.tratto(p, fuso(p, r_linea, 0.3, forma=0.8), colore_linea)
        if doppia:
            ang = np.radians(np.linspace(62, 132, 60))
            rr = R_PALPEBRA + 9.5 * np.sin(ang) ** 1.5
            p = np.stack([cx + segno * rr * np.cos(ang), cy + rr * np.sin(ang)], 1)
            t.tratto(p, fuso(p, r_linea * 0.75, 0.25, forma=0.8), RUGA_LEGGERA)


def _zampe(t, quante=3, colore=RUGA, r=1.0, lung=11.0):
    """Le zampe di gallina: ventaglio di rughe fuori dall'angolo dell'occhio."""
    angoli = {3: (-26, 0, 24), 2: (-16, 16)}[quante]
    for a in angoli:
        ar = np.radians(180 + a)
        # dall'angolo di fuori dell'occhio sinistro verso fuori
        cx, cy = OCCHI_XY[0]
        r0 = R_PALPEBRA + 2.5
        p0 = (cx + r0 * np.cos(ar), cy + r0 * np.sin(ar) * 0.9)
        l = lung * (1.0 if a == 0 else 0.85)
        p2 = (p0[0] + l * np.cos(ar), p0[1] + l * np.sin(ar))
        pm = ((p0[0] + p2[0]) / 2, (p0[1] + p2[1]) / 2 + 1.2 * np.sign(a))
        p = curva(p0, pm, p2)
        t.tratto(p, np.linspace(r, 0.3, len(p)) ** 0.9, colore, doppio=True)


def _naso_bocca(t, colore=RUGA, r=1.35, fino=198.0):
    """La piega naso-bocca: dall'ala del naso giù, fuori dall'angolo della
    bocca."""
    p = curva((106.0, 151.0), (95.5, 160.0), (93.5, 180.0), (98.5, fino))
    t.tratto(p, fuso(p, r, 0.35, 0.5, forma=0.5), colore, doppio=True)


def _fronte(t, file, colore=RUGA, r=1.25):
    """Rughe della fronte, un filo ondulate (py 50-70)."""
    for (y, x0, x1, fase) in file:
        x = np.linspace(x0, x1, 160)
        yy = y + 0.8 * np.sin((x - x0) / (x1 - x0) * 2 * np.pi + fase) \
            + 1.8 * ((x - 128) / 60.0) ** 2
        p = np.stack([x, yy], 1)
        t.tratto(p, fuso(p, r, 0.3, forma=0.7), colore)


def rughe_stanco():
    t = Tela()
    _borse(t, colore_linea=RUGA, forza_gonfio=1.0, r_linea=1.15)
    return t


def rughe_vecchio():
    t = Tela()
    _fronte(t, [(51.0, 94, 162, 0.3), (59.0, 86, 170, 2.1),
                (67.0, 96, 160, 4.0)], RUGA_FORTE, r=1.25)
    _zampe(t, 3, RUGA_FORTE, r=1.05, lung=12.0)
    _naso_bocca(t, RUGA_FORTE, r=1.5, fino=199.0)
    _borse(t, colore_linea=RUGA_FORTE, forza_gonfio=1.0, r_linea=1.1, doppia=True)
    return t


def rughe_vecchia():
    t = Tela()
    _fronte(t, [(59.0, 98, 158, 1.0)], RUGA, r=1.0)
    _zampe(t, 2, RUGA, r=0.9, lung=10.0)
    _naso_bocca(t, RUGA, r=1.15, fino=196.0)
    _borse(t, colore_linea=RUGA_LEGGERA, forza_gonfio=0.6, r_linea=0.9)
    return t


def rughe_arraggiato():
    t = Tela()
    s = curva((121.5, 83.0), (119.0, 92.0), (120.5, 101.5))
    t.tratto(s, fuso(s, 1.45, 0.4), RUGA_FORTE, doppio=True)
    _naso_bocca(t, RUGA_LEGGERA, r=1.2, fino=195.0)
    return t


RUGHE = {
    "stanco": rughe_stanco, "vecchio": rughe_vecchio,
    "vecchia": rughe_vecchia, "arraggiato": rughe_arraggiato,
}


# =========================================================================
#  Le barbe (maschera grigia: nero = pelle, bianco = peli)
# =========================================================================

def contorno_faccia(margine=4.0):
    """Dove sta la faccia (a 4x), con un margine: sopra la fascia degli
    zigomi larga fino alle orecchie, sotto la mascella che scende al mento
    (superellisse: la mascella di Schedule I è tonda ma piena)."""
    dx = np.abs(GX - MEZZO)
    dy = np.maximum(GY - 122.0, 0.0)
    rx, ry = 106.0 + margine, 129.0 + margine
    e = (dx / rx) ** 2.3 + (dy / ry) ** 2.3
    return np.clip((1.0 - e) * 40.0, 0.0, 1.0)


def linea_guance(dx, rumore=None):
    """Il bordo di sopra della barba, simmetrico: dalla basetta scende in
    diagonale verso l'angolo della bocca, e sotto al naso sta al labbro."""
    xs = [0, 19, 28, 36, 44, 56, 70, 84, 98, 112]
    ys = [156, 156, 161, 165, 165, 159, 150, 140, 129, 121]
    y = np.interp(dx, xs, ys).astype(np.float32)
    if rumore is not None:
        y = y + rumore
    return y


MANDORLA_MEZZA = 29.0     # mezza larghezza della bocca libera (px)


def mandorla_bordi(dx):
    """Il bordo di sopra e di sotto della mandorla della bocca libera."""
    t = np.clip(1.0 - (np.asarray(dx) / MANDORLA_MEZZA) ** 2, 0.0, 1.0)
    return 187.5 - 8.0 * t ** 0.35, 187.5 + 16.0 * t ** 0.55


def distanza_mandorla():
    """Distanza (px, a 4x) dal bordo della mandorla: negativa dentro.
    Si misura solo attorno alla bocca; lontano vale 99."""
    phi = np.linspace(-np.pi / 2, np.pi / 2, 400)
    xs = MEZZO + MANDORLA_MEZZA * np.sin(phi)
    su, giu = mandorla_bordi(xs - MEZZO)
    bordo = np.concatenate([np.stack([xs, su], 1), np.stack([xs[::-1], giu[::-1]], 1)])
    d = np.full((LATO * S, LATO * S), 99.0, np.float32)
    y0, y1, x0, x1 = 160 * S, 230 * S, 80 * S, 176 * S
    X = GX[y0:y1, x0:x1]
    Y = GY[y0:y1, x0:x1]
    m = np.full(X.shape, 1e9, np.float32)
    for bx, by in bordo:
        np.minimum(m, (X - bx) ** 2 + (Y - by) ** 2, out=m)
    m = np.sqrt(m)
    dxl = np.abs(X - MEZZO)
    s_su, s_giu = mandorla_bordi(dxl)
    dentro = (dxl < MANDORLA_MEZZA) & (Y > s_su) & (Y < s_giu)
    d[y0:y1, x0:x1] = np.where(dentro, -m, m)
    return d


def zona_libera_bocca(bocche_nucleo):
    """La bocca resta libera dai peli, qualunque bocca abbia la persona: una
    mandorla pulita a forma di labbra (px 99-157, py ~179-204), più un
    alone stretto (~1 px) attorno ai tratti di tutte le bocche che escono
    dalla mandorla (la punta della cazzimma, gli angoli del sorriso)."""
    dx = np.abs(GX - MEZZO)
    su, giu = mandorla_bordi(dx)
    d = np.minimum(GY - su, giu - GY)
    mandorla = liscio(d, -0.6, 0.9) * (dx < MANDORLA_MEZZA)
    u = np.zeros((LATO * S, LATO * S), np.float32)
    for a in bocche_nucleo:
        np.maximum(u, a, out=u)
    alone = liscio(sfuma(u, 0.6 * S), 0.03, 0.15)
    return np.maximum(mandorla, alone)


def _su_giro(a, n_out, asse):
    """Ingrandisce lungo un asse con la spline di Catmull-Rom, girando
    attorno ai bordi: il risultato si ripete esatto, senza cucitura."""
    n_in = a.shape[asse]
    pos = (np.arange(n_out) + 0.5) * n_in / n_out - 0.5
    i = np.floor(pos).astype(int)
    t = pos - i
    pesi = ((-t ** 3 + 2 * t ** 2 - t) / 2, (3 * t ** 3 - 5 * t ** 2 + 2) / 2,
            (-3 * t ** 3 + 4 * t ** 2 + t) / 2, (t ** 3 - t ** 2) / 2)
    forma = [1] * a.ndim
    forma[asse] = n_out
    out = 0.0
    for k, w in enumerate(pesi):
        out = out + w.reshape(forma) * np.take(a, (i - 1 + k) % n_in, axis=asse)
    return out


def rumore_periodico(h, w, gy, gx, rng):
    """Rumore liscio che si ripete senza cucitura (griglia gy x gx)."""
    g = rng.random((gy, gx))
    return _su_giro(_su_giro(g, w, 1), h, 0).astype(np.float32)


def puntini(rng, basso=0.35, alto=0.55):
    """'A barba 'e tre juorne: puntinato fitto a 256, valori fra basso e
    alto (distribuzione piatta, così la media non si sposta)."""
    n = rng.random((LATO, LATO)).astype(np.float32)
    n = (4 * n + np.roll(n, 1, 0) + np.roll(n, -1, 0)
         + np.roll(n, 1, 1) + np.roll(n, -1, 1)) / 8.0
    rango = np.empty(n.size, np.float32)
    rango[np.argsort(n, axis=None)] = np.linspace(0, 1, n.size)
    n = rango.reshape(n.shape) ** 1.3
    return basso + (alto - basso) * n


def barba_sfatta(libera, rng):
    dx = np.abs(GX - MEZZO)
    yb = linea_guance(dx)
    # sotto al naso il labbro di sopra comincia netto (5 px), sulle guance
    # sfuma lungo verso gli zigomi (16 px)
    sfumo = np.interp(dx, [0, 22, 44], [5.0, 5.0, 16.0]).astype(np.float32)
    guance = liscio(GY, yb - 2.5, yb + sfumo)
    # la basetta corta che la attacca ai capelli
    basetta = liscio(dx, 87, 95) * liscio(GY, 100.0, 122.0)
    campo = np.maximum(guance, basetta) * contorno_faccia(3.0) * (1 - libera)
    # attorno alle labbra la barba corta si dirada (niente scalino netto)
    campo *= liscio(distanza_mandorla(), 1.0, 4.5)
    # il mento e la mascella un filo più fitti delle guance alte
    fitto = 0.88 + 0.12 * liscio(GY, 175.0, 215.0)
    campo = riduci(campo * fitto)
    return campo * puntini(rng)


def barba_pizzetto(libera):
    """'O pizzetto netto: il baffetto sottile che gira attorno alla bocca
    (a 1,6 px dalla mandorla libera) e scende a chiudersi nel pizzo sul
    mento. Tutto un pezzo, bordi puliti."""
    d = distanza_mandorla()
    dx = np.abs(GX - MEZZO)
    stacco = 1.6
    # lo spessore dell'anello: il baffetto 5,8 px in mezzo che si assottiglia
    # verso gli angoli, i fili ai lati 2,8 px
    mezzo = np.clip(1.0 - (dx / 30.0) ** 2, 0.0, 1.0) * liscio(-(GY - 187.5), 1.0, 6.0)
    spess = 2.8 + 3.0 * mezzo
    anello = liscio(d, stacco - 0.3, stacco + 0.3) * \
        (1 - liscio(d, stacco + spess - 0.3, stacco + spess + 0.3))
    # il baffetto non sale oltre la metà del labbro di sopra
    anello *= 1 - liscio(170.5 - GY, -0.3, 0.3)
    # 'o pizzo: sotto la mandorla, largo 19 px per lato, tondo in fondo
    fondo = 239.0 - 10.0 * (dx / 16.0) ** 2
    lati = 21.0 - 7.0 * liscio(GY, 210.0, 240.0)
    pizzo = liscio(d, stacco - 0.3, stacco + 0.3) * liscio(lati - dx, -0.4, 0.4) \
        * liscio(fondo - GY, -0.4, 0.4) * liscio(GY, 187.5, 190.0)
    a = np.maximum(anello, pizzo) * (1 - libera)
    return riduci(a) * 0.9


def barba_barba(libera, rng):
    dx = np.abs(GX - MEZZO)
    # bordo leggermente irregolare: la linea delle guance ondeggia di ~2 px
    # (un'onda lungo x, più un tremolio fine: pulito, non strappato)
    nodi = rng.normal(0.0, 1.0, 44)
    onda = np.interp(GX, np.linspace(-4, LATO + 4, 44), nodi)
    onda = sfuma(onda, 1.5 * S)
    onda = onda / (onda.std() + 1e-6) * 1.5
    fine = sfuma(rng.random((LATO * S, LATO * S)).astype(np.float32), 0.9 * S)
    fine = (fine - fine.mean()) / (fine.std() + 1e-6) * 0.5
    tremo = onda + fine
    yb = linea_guance(dx, tremo) - 2.0
    guance = liscio(GY, yb - 1.4, yb + 1.4)
    labbro = liscio(GY + tremo * 0.4, 155.5, 157.5) * (1 - liscio(dx, 20, 26))
    guance = np.maximum(guance, labbro)
    # la basetta piena fino ai capelli
    basetta = liscio(dx + tremo * 0.5, 84.5, 86.5) * liscio(GY, 60.0, 66.0)
    campo = np.maximum(guance, basetta) * contorno_faccia(4.0) * (1 - libera)
    campo = riduci(campo)
    # dentro non è una piastrella: un filo di pelo che varia
    var = rumore_periodico(LATO, LATO, 48, 48, rng)
    fine = rng.random((LATO, LATO)).astype(np.float32)
    val = 0.85 + 0.06 * (var - 0.5) + 0.04 * (fine - 0.5)
    # sul bordo i peli si diradano
    bordo = (campo > 0.02) & (campo < 0.98)
    val = np.where(bordo, val * (0.75 + 0.25 * fine), val)
    return campo * val


def barba_basette(libera):
    a = np.zeros((LATO * S, LATO * S), np.float32)
    for segno in (1, -1):
        def x(dx):
            return MEZZO - segno * dx
        # dentro si allarga scendendo, sotto il taglio in diagonale
        pts = [(x(109), 58.0), (x(88.5), 58.0), (x(87.0), 100.0),
               (x(82.5), 142.0), (x(81.5), 150.5), (x(84.0), 153.5),
               (x(104.0), 160.5), (x(107.0), 158.5), (x(109), 120.0)]
        np.maximum(a, alfa_poligono(pts), out=a)
    a = riduci(sfuma(a, 0.6 * S))
    return a * 0.9


# =========================================================================
#  Le trame (grigie, si ripetono)
# =========================================================================

def stoffa_camicia(rng, n=128):
    """Cotone: armatura tela fine, qualche filo più grosso (bave), rumore."""
    y, x = np.mgrid[0:n, 0:n].astype(np.float32)
    tela = 0.5 * np.cos(np.pi * x) * np.cos(np.pi * y)        # periodo 2 px
    tela2 = np.cos(2 * np.pi * x / 4) * np.cos(2 * np.pi * y / 4)
    trama = rumore_periodico(n, n, 64, 4, rng) - 0.5    # righe orizzontali
    ordito = rumore_periodico(n, n, 4, 64, rng) - 0.5   # righe verticali
    grana = rng.random((n, n)).astype(np.float32) - 0.5
    v = 0.94 + 0.014 * tela + 0.016 * tela2 + 0.035 * trama + 0.03 * ordito \
        + 0.03 * grana
    v = v - v.mean() + 0.94
    return np.clip(v, 0.84, 1.0)


def stoffa_cazune(rng, n=128):
    """Tela di jeans: la diagonale della saia (sale verso destra), i fili
    dell'ordito più o meno tinti (le righe verticali del denim), grana."""
    y, x = np.mgrid[0:n, 0:n].astype(np.float32)
    fase = (x + y) % 4.0                                  # saia 3/1, 4 px
    saia = np.where(fase < 1.0, -1.0, np.where(fase < 2.0, 0.0,
                    np.where(fase < 3.0, 0.6, 0.4)))
    saia = sfuma_periodica(saia, 0.45)
    ordito = rumore_periodico(n, n, 2, 96, rng) - 0.5
    bave = rumore_periodico(n, n, 6, 32, rng) - 0.5
    grana = rng.random((n, n)).astype(np.float32) - 0.5
    v = 0.905 + 0.055 * saia + 0.09 * ordito + 0.05 * bave + 0.03 * grana
    v = v - v.mean() + 0.905
    return np.clip(v, 0.80, 1.0)


def sfuma_periodica(a, sigma):
    """Sfocatura che rispetta la ripetizione."""
    return sfuma(a, sigma, giro=True)


def ciocche(rng, n=128):
    """'E ciocche: fasce verticali (lungo v) di capelli pettinati, ognuna
    tonda (più chiara in mezzo), divise da solchi più scuri; dentro, i fili
    fini. Tutto periodico: si ripete senza cucitura."""
    y, x = np.mgrid[0:n, 0:n].astype(np.float32)
    k = 10
    larghe = rng.uniform(0.6, 1.5, k)
    base = (np.cumsum(larghe) / larghe.sum() * n + rng.uniform(0, n)) % n
    base = np.sort(base)
    # le ciocche scendono quasi dritte: appena un'onda (periodica in u e v)
    f1, f2 = rng.uniform(0, 2 * np.pi, 2)
    uu = x + 0.65 * np.sin(2 * np.pi * y / n + 2 * np.pi * x / n + f1) \
        + 0.3 * np.sin(4 * np.pi * y / n + f2)
    uu = uu % n
    est = np.concatenate([[base[-1] - n], base, [base[0] + n]])
    j = np.searchsorted(est, uu, side="right") - 1
    sx, dx_ = est[j], est[j + 1]
    s = (uu - sx) / (dx_ - sx)                     # 0..1 dentro la ciocca
    idx = (j - 1) % k
    luce = rng.uniform(0.93, 1.03, k)
    tondo = 0.84 + 0.16 * np.sin(np.pi * s) ** 0.6
    v = tondo * luce[idx]
    # i solchi fra le ciocche, di profondità diverse (ognuno il suo)
    fondo = rng.uniform(0.08, 0.26, k)
    sx_d = uu - sx
    dx_d = dx_ - uu
    v = v - np.exp(-(sx_d / 1.0) ** 2) * fondo[idx] \
        - np.exp(-(dx_d / 1.0) ** 2) * fondo[(idx + 1) % k]
    # un solchetto leggero dentro a metà delle ciocche
    dove = rng.uniform(0.3, 0.7, k)
    quanto = rng.uniform(0.0, 0.07, k) * (rng.random(k) < 0.6)
    v = v - np.exp(-((s - dove[idx]) * (dx_ - sx) / 0.8) ** 2) * quanto[idx]
    # i fili fini dentro alla ciocca
    fili = rumore_periodico(1, n, 1, 56, rng)[0]
    fili = np.interp(uu, np.arange(n), fili, period=n)
    v = v + 0.05 * (fili - 0.5)
    # un respiro lungo v (la luce che scorre sulla ciocca)
    v = v + 0.025 * np.sin(2 * np.pi * y / n * 2 + x / n * 2 * np.pi * 3)
    # riporta nella gamma voluta: 0.62..1.0
    lo, hi = np.percentile(v, 0.3), np.percentile(v, 99.7)
    v = 0.62 + 0.38 * np.clip((v - lo) / (hi - lo), 0, 1)
    return v


def iride(rng, n=64):
    """L'iride: fibre chiare a raggiera, l'anello scuro al bordo, la
    pupilla nera. Moltiplica il colore degli occhi scelto dal gioco."""
    m = n * S
    c = (np.arange(m, dtype=np.float32) + 0.5) / m * 2.0 - 1.0
    X, Y = np.meshgrid(c, c)
    r = np.hypot(X, Y)
    th = np.arctan2(Y, X)
    # fibre: rumore periodico nell'angolo, a due scale
    def giro(k):
        v = rng.random(k)
        a = (th / (2 * np.pi) % 1.0) * k
        i0 = np.floor(a).astype(int) % k
        f = a - np.floor(a)
        return v[i0] * (1 - f) + v[(i0 + 1) % k] * f
    # le fibre: righe sottili a raggiera, che si spezzano lungo il raggio
    fibre = 0.45 * giro(72) + 0.55 * giro(160)
    rotte = 0.5 + 0.5 * np.sin(r * 11.0 + giro(36) * 7.0)
    fibre = fibre * (0.75 + 0.25 * rotte)
    fibre = (fibre - fibre.min()) / (fibre.max() - fibre.min())
    fibre2 = giro(23)
    # la collaretta (anello chiaro attorno alla pupilla) e le cripte
    v = 0.66 + 0.32 * fibre
    v = v + 0.10 * np.exp(-((r - 0.50) / 0.07) ** 2) * (0.6 + 0.4 * fibre2)
    v = v - 0.10 * np.exp(-((r - 0.70) / 0.10) ** 2) * (fibre2 > 0.62)
    v = np.clip(v, 0.65, 1.0)
    # l'anello scuro al bordo (limbo)
    limbo = liscio(r, 0.80, 0.97)
    v = v * (1 - limbo) + 0.30 * limbo
    # la pupilla, bordo morbido
    pup = 1 - liscio(r, 0.31, 0.37)
    v = v * (1 - pup)
    v = np.where(r > 0.97, 0.30, v)
    return v.reshape(n, S, n, S).mean(axis=(1, 3))


# =========================================================================
#  Genera
# =========================================================================

def controlla_angolo(arr, neutro, nome):
    a = a_byte(arr)
    ang = a[:16, :16]
    assert np.all(ang == neutro), f"{nome}: angolo 16x16 non neutro"


def genera():
    rng = np.random.default_rng(SEME)
    fatti = {}
    nuclei = []
    for nome, f in BOCCHE.items():
        t = f()
        arr = t.finita()
        controlla_angolo(arr, 255, nome)
        fatti["bocca_" + nome] = arr
        nuclei.append(t.nucleo)
        salva(arr, f"bocca_{nome}.png")
    libera = zona_libera_bocca(nuclei)
    barbe = {
        "sfatta": barba_sfatta(libera, rng),
        "pizzetto": barba_pizzetto(libera),
        "barba": barba_barba(libera, rng),
        "basette": barba_basette(libera),
    }
    for nome, arr in barbe.items():
        controlla_angolo(arr, 0, nome)
        fatti["barba_" + nome] = arr
        salva(arr, f"barba_{nome}.png")
    for nome, f in RUGHE.items():
        arr = f().finita()
        controlla_angolo(arr, 255, nome)
        fatti["rughe_" + nome] = arr
        salva(arr, f"rughe_{nome}.png")
    for nome, f in (("stoffa_camicia", stoffa_camicia),
                    ("stoffa_cazune", stoffa_cazune), ("ciocche", ciocche),
                    ("iride", iride)):
        arr = f(np.random.default_rng(SEME + len(nome)))
        fatti[nome] = arr
        salva(arr, f"{nome}.png")
    return fatti


# =========================================================================
#  Anteprime: la faccia come la fa lo shader, su un ovale di prova
# =========================================================================

PELLI = [(0.91, 0.75, 0.60), (0.86, 0.68, 0.52), (0.78, 0.60, 0.44),
         (0.68, 0.50, 0.36)]
PELI = [(0.09, 0.07, 0.06), (0.17, 0.11, 0.07), (0.31, 0.20, 0.12),
        (0.52, 0.48, 0.44), (0.74, 0.72, 0.70)]
OCCHI_COL = [(0.20, 0.12, 0.07), (0.28, 0.17, 0.09), (0.36, 0.28, 0.14),
             (0.26, 0.34, 0.20), (0.30, 0.40, 0.50)]
MURO = (0.89, 0.83, 0.65)


def lin(c):
    c = np.asarray(c, np.float32)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def srgb(c):
    c = np.clip(np.asarray(c, np.float32), 0, 1)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055)


def _m(a):
    """Copertura a 4x -> 1x."""
    return riduci(a)[..., None]


def _sopra(img, m, col):
    return img * (1 - m) + np.asarray(col, np.float32) * m


def testa_alfa():
    dx = np.abs(GX - MEZZO)
    dy = GY - 122.0
    e = (dx / 104.0) ** 2.3 + (np.abs(dy) / 129.0) ** 2.3
    return np.clip((1.0 - e) * 60.0, 0, 1)


def ombra_testa():
    """Luce di prova: da sopra a sinistra, come nelle foto del gioco."""
    y, x = np.mgrid[0:LATO, 0:LATO].astype(np.float32) + 0.5
    nx = (x - 128) / 118.0
    ny = (y - 122) / 140.0
    nz = np.sqrt(np.clip(1 - nx * nx - ny * ny, 0.02, 1))
    l = np.array([-0.35, -0.45, 0.82])
    l = l / np.linalg.norm(l)
    ndl = np.clip(nx * l[0] + ny * l[1] + nz * l[2], 0, 1)
    return (0.62 + 0.40 * ndl)[..., None]


def capelli_alfa(stile):
    dx = np.abs(GX - MEZZO)
    testa = testa_alfa()
    if stile == "stempiati":
        # solo ai lati e dietro: la pelata in mezzo
        lati = liscio(dx, 70, 78) * (1 - liscio(GY, 104, 110)) * liscio(GY, 30, 40)
        return lati * testa
    if stile == "signora":
        grande = alfa_ellisse(128, 92, 124, 104)
        riga = 42 + 118 * (dx / 100.0) ** 2.2 + 6 * np.sin(dx / 9.0)
        return grande * (1 - liscio(GY, riga - 1, riga + 1)) + \
            grande * liscio(dx, 92, 96) * (1 - liscio(GY, 168, 176))
    if stile == "tuppo":
        cap = alfa_ellisse(128, 104, 107, 116)
        riga = 42 + 70 * (dx / 104.0) ** 3
        cima = alfa_ellisse(128, 4, 30, 20)
        return np.clip(cap * (1 - liscio(GY, riga - 1, riga + 1)) + cima, 0, 1)
    if stile == "ricci":
        cap = alfa_ellisse(128, 104, 110, 122)
        for ang in np.linspace(-2.6, -0.54, 11):
            cap = np.maximum(cap, alfa_ellisse(128 + 104 * np.cos(ang),
                                               112 + 116 * np.sin(ang), 17, 17))
        riga = 44 + 5 * np.cos(dx / 5.0) + 60 * (dx / 104.0) ** 4
        return cap * (1 - liscio(GY, riga - 1, riga + 1))
    if stile == "gellati":
        cap = alfa_ellisse(128, 100, 108, 126)
        riga = 40 + 62 * (dx / 104.0) ** 4
        return cap * (1 - liscio(GY, riga - 1, riga + 1))
    # corti / sfumati
    cap = alfa_ellisse(128, 110, 107, 122)
    riga = 44 + 58 * (dx / 104.0) ** 4
    return cap * (1 - liscio(GY, riga - 1, riga + 1))


def faccia(tex, pelle, peli, bocca="dritta", barba="", rughe="", occhi=None,
           capelli="corti", palpebre="sveglie", ciglia="dritte", naso="piccolo",
           fondo=MURO):
    """La faccia di prova: 256x256 sRGB. Lo strato dipinto lo fa come lo
    shader (in lineare: le texture colore passano da sRGB, la barba no)."""
    occhi = occhi or OCCHI_COL[0]
    luce = ombra_testa()
    img = np.ones((LATO, LATO, 3), np.float32) * np.asarray(fondo, np.float32)
    pelle_l = lin(pelle)
    peli_l = lin(peli)
    # le orecchie, dietro
    for sx in (21.0, 235.0):
        m = _m(alfa_ellisse(sx, 132, 10, 19))
        img = _sopra(img, m, srgb(pelle_l * 0.78))
    # 'a faccia dipinta (lo shader)
    col = pelle_l * np.ones((LATO, LATO, 3), np.float32)
    col = col * lin(tex["bocca_" + bocca])
    if rughe:
        col = col * lin(tex["rughe_" + rughe])
    if barba:
        b = tex["barba_" + barba][..., None]
        col = col * (1 - b) + peli_l * b
    col = srgb(col * luce ** 2.2)
    img = _sopra(img, _m(testa_alfa()), col)
    # i capelli
    ca = _m(capelli_alfa(capelli))
    colc = srgb(peli_l * lin(np.repeat(_ciocche_faccia()[..., None], 3, 2)) * luce ** 2.2)
    img = _sopra(img, ca, colc)
    # il naso: ombra sotto, poi il naso
    img = _sopra(img, _m(alfa_ellisse(128, 153.5, 19, 4.5, morbido=4)) * 0.45,
                 srgb(pelle_l * 0.35))
    larg = {"piccolo": 1.0, "grosso": 1.25, "aquilino": 1.05}[naso]
    ponte = curva((128, 108), (128, 132))
    nm = np.maximum(alfa_tratto(ponte, np.linspace(5, 9 * larg, len(ponte))),
                    alfa_ellisse(128, 139.5, 14 * larg, 9.5))
    nm = np.maximum(nm, alfa_ellisse(128 - 13 * larg, 145, 6.8, 6))
    nm = np.maximum(nm, alfa_ellisse(128 + 13 * larg, 145, 6.8, 6))
    img = _sopra(img, _m(nm), srgb(pelle_l * 0.80 * luce ** 2.2))
    dentro_naso = np.maximum(alfa_ellisse(128, 138.5, 12.5 * larg, 8.0),
                             alfa_tratto(ponte, np.linspace(3.8, 7.5 * larg, len(ponte))))
    img = _sopra(img, _m(dentro_naso), srgb(pelle_l * 0.97 * luce ** 2.2))
    img = _sopra(img, _m(alfa_ellisse(124, 136, 5, 4, morbido=3)) * 0.5,
                 srgb(np.minimum(pelle_l * 1.25, 1)))
    # gli occhi (palla, iride, palpebre spesse)
    ir = Image.fromarray(a_byte(tex["iride"])).resize((22, 22), Image.LANCZOS)
    ir = np.asarray(ir, np.float32)[..., None] / 255.0
    for i, (cx, cy) in enumerate(OCCHI_XY):
        img = _sopra(img, _m(alfa_ellisse(cx, cy, R_PALPEBRA, R_PALPEBRA)),
                     srgb(pelle_l * 0.80))
        img = _sopra(img, _m(alfa_ellisse(cx, cy, R_OCCHIO, R_OCCHIO)),
                     (0.93, 0.92, 0.89))
        x0, y0 = int(round(cx - 11)), int(round(cy - 10))
        reg = img[y0:y0 + 22, x0:x0 + 22]
        disco = _m(alfa_ellisse(cx, cy + 1, 11, 11))[y0:y0 + 22, x0:x0 + 22]
        irc = srgb(lin(occhi) * lin(np.repeat(ir, 3, 2)) * 1.6)
        img[y0:y0 + 22, x0:x0 + 22] = reg * (1 - disco) + irc * disco
        img = _sopra(img, _m(alfa_ellisse(cx - 5, cy - 5, 3, 3)), (1, 1, 1))
        # palpebra di sopra: più o meno chiusa
        chiusa = {"sveglie": -9, "stanche": -1, "furbe": 1, "arraggiate": -4}[palpebre]
        pend = {"arraggiate": 0.22, "furbe": 0.0}.get(palpebre, 0.0)
        segno = 1 if i == 0 else -1
        bordo_y = cy + chiusa + pend * (GX - cx) * segno
        pal = alfa_ellisse(cx, cy, R_PALPEBRA - 0.5, R_PALPEBRA - 0.5) * \
            (1 - liscio(GY, bordo_y - 0.4, bordo_y + 0.4))
        img = _sopra(img, _m(pal), srgb(pelle_l * 0.88))
        lin_pal = alfa_ellisse(cx, cy, R_OCCHIO + 0.5, R_OCCHIO + 0.5) * \
            np.clip(1 - np.abs(GY - bordo_y) / 1.2, 0, 1)
        img = _sopra(img, _m(lin_pal), srgb(pelle_l * 0.30))
        # palpebra di sotto: un bordino
        sotto = alfa_ellisse(cx, cy, R_PALPEBRA - 0.5, R_PALPEBRA - 0.5) * \
            (1 - alfa_ellisse(cx, cy - 3, R_OCCHIO, R_OCCHIO - 1)) * liscio(GY, cy + 8, cy + 12)
        img = _sopra(img, _m(sotto), srgb(pelle_l * 0.84))
    # le sopracciglia
    forma = {"dritte": ((66, 80), (105, 79)), "arraggiate": ((66, 75), (106, 84)),
             "preoccupate": ((66, 83), (106, 74)), "sottili": ((66, 80), (104, 77)),
             "scettiche": ((66, 80), (105, 79))}[ciglia]
    rr = 2.4 if ciglia == "sottili" else 4.0
    for i in (0, 1):
        p = curva(forma[0], ((forma[0][0] + forma[1][0]) / 2, min(forma[0][1], forma[1][1]) - 3),
                  forma[1])
        if i == 1:
            p = specchio(p)
            if ciglia == "scettiche":
                p[:, 1] -= 5
        img = _sopra(img, _m(alfa_tratto(p, fuso(p, rr, rr * 0.75, forma=0.3))),
                     srgb(peli_l * 0.9))
    return np.clip(img, 0, 1)


_CIOCCHE_FACCIA = None


def _ciocche_faccia():
    global _CIOCCHE_FACCIA
    if _CIOCCHE_FACCIA is None:
        c = np.asarray(Image.open(USCITA / "ciocche.png").convert("L"),
                       np.float32) / 255.0
        _CIOCCHE_FACCIA = np.tile(c, (2, 2))
    return _CIOCCHE_FACCIA


def _font(sz):
    try:
        return ImageFont.load_default(size=sz)
    except TypeError:
        return ImageFont.load_default()


def tavola(celle, colonne, scritte=None, scala=1, fondo=(0.20, 0.18, 0.16),
           margine=8, alto_scritta=20):
    """Mette le immagini in griglia con le scritte sotto."""
    h, w = celle[0].shape[:2]
    h, w = h * scala, w * scala
    righe = (len(celle) + colonne - 1) // colonne
    H = righe * (h + margine + (alto_scritta if scritte else 0)) + margine
    W = colonne * (w + margine) + margine
    out = Image.new("RGB", (W, H), tuple(int(c * 255) for c in fondo))
    d = ImageDraw.Draw(out)
    f = _font(14)
    for k, c in enumerate(celle):
        r, q = divmod(k, colonne)
        x = margine + q * (w + margine)
        y = margine + r * (h + margine + (alto_scritta if scritte else 0))
        im = Image.fromarray(a_byte(c))
        if scala != 1:
            im = im.resize((w, h), Image.NEAREST)
        out.paste(im, (x, y))
        if scritte:
            d.text((x + 2, y + h + 2), scritte[k], fill=(235, 225, 200), font=f)
    return out


def a_64(img):
    """Come si vede a 2 m: la faccia a 64 px, ingrandita a quadretti."""
    im = Image.fromarray(a_byte(img)).resize((64, 64), Image.BOX)
    return np.asarray(im.resize((192, 192), Image.NEAREST), np.float32) / 255.0


def anteprime(tex):
    ANTEPRIME.mkdir(parents=True, exist_ok=True)
    nomi_b = list(BOCCHE)
    # 1. le bocche su tutte e quattro le pelli (facce intere)
    celle, scr = [], []
    for b in nomi_b:
        for k, p in enumerate(PELLI):
            celle.append(faccia(tex, p, PELI[k % 3], bocca=b))
            scr.append(f"{b} / pelle {k}")
    tavola(celle, 4, scr).save(ANTEPRIME / "bocche_pelli.png")
    # 1b. zoom sulle bocche (pelle chiara e scura)
    celle, scr = [], []
    for b in nomi_b:
        for k in (0, 3):
            f = faccia(tex, PELLI[k], PELI[0], bocca=b)[150:222, 84:172]
            celle.append(f)
            scr.append(f"{b} / {k}")
    tavola(celle, 4, scr, scala=3).save(ANTEPRIME / "bocche_zoom.png")
    # 2. le barbe coi peli neri, castani e bianchi
    celle, scr = [], []
    for bb in ("sfatta", "pizzetto", "barba", "basette"):
        for k, (pl, pe) in enumerate(((PELLI[1], PELI[0]), (PELLI[3], PELI[2]),
                                      (PELLI[0], PELI[4]))):
            celle.append(faccia(tex, pl, pe, bocca="dritta", barba=bb,
                                rughe="vecchio" if k == 2 else ""))
            scr.append(f"{bb} / peli {['neri', 'castani', 'bianchi'][k]}")
    tavola(celle, 3, scr).save(ANTEPRIME / "barbe_peli.png")
    # 2b. zoom sulle barbe (mascella e bocca), peli neri su pelle chiara
    celle, scr = [], []
    for bb in ("sfatta", "pizzetto", "barba", "basette"):
        for bo in ("dritta", "sorriso"):
            f = faccia(tex, PELLI[0], PELI[0], bocca=bo, barba=bb)[120:256, 20:236]
            celle.append(f)
            scr.append(f"{bb} + {bo}")
    tavola(celle, 4, scr, scala=2).save(ANTEPRIME / "barbe_zoom.png")
    # 3. le rughe
    celle, scr = [], []
    for r in RUGHE:
        for k, (pl, pe) in enumerate(((PELLI[0], PELI[3]), (PELLI[3], PELI[4]))):
            celle.append(faccia(tex, pl, pe, bocca="dritta", rughe=r))
            scr.append(f"{r} / pelle {'chiara' if k == 0 else 'scura'}")
    tavola(celle, 4, scr).save(ANTEPRIME / "rughe.png")
    # 4. le otto facce napoletane
    tipi = [
        ("'o guappo", dict(pelle=PELLI[2], peli=PELI[0], bocca="cazzimma", barba="sfatta",
                           capelli="gellati", palpebre="furbe", ciglia="scettiche",
                           naso="aquilino")),
        ("'o panzone d''o bar", dict(pelle=PELLI[1], peli=PELI[3], bocca="sorriso",
                                     rughe="vecchio", capelli="stempiati", naso="grosso")),
        ("'a signora", dict(pelle=PELLI[0], peli=PELI[2], bocca="rossetto",
                            capelli="signora", ciglia="sottili", palpebre="stanche")),
        ("'o guaglione", dict(pelle=PELLI[1], peli=PELI[1], bocca="dritta",
                              barba="pizzetto", capelli="sfumati", palpebre="sveglie")),
        ("'o carabiniere", dict(pelle=PELLI[2], peli=PELI[0], bocca="storta",
                                rughe="arraggiato", capelli="corti", palpebre="arraggiate",
                                ciglia="arraggiate")),
        ("'a nonna", dict(pelle=PELLI[0], peli=PELI[4], bocca="preoccupata",
                          rughe="vecchia", capelli="tuppo", ciglia="preoccupate",
                          palpebre="stanche")),
        ("'o riccio", dict(pelle=PELLI[3], peli=PELI[0], bocca="sorriso", barba="barba",
                           capelli="ricci", naso="grosso")),
        ("'o stanco", dict(pelle=PELLI[1], peli=PELI[1], bocca="dritta", rughe="stanco",
                           capelli="corti", palpebre="stanche", ciglia="dritte")),
    ]
    celle, scr, piccole = [], [], []
    for k, (nome, o) in enumerate(tipi):
        o = dict(o)
        f = faccia(tex, o.pop("pelle"), o.pop("peli"), occhi=OCCHI_COL[k % 3], **o)
        celle.append(f)
        piccole.append(a_64(f))
        scr.append(nome)
    tavola(celle, 4, scr).save(ANTEPRIME / "tavola_facce.png")
    tavola(piccole, 4, scr).save(ANTEPRIME / "tavola_facce_64.png")
    # 5. le trame affiancate 2x2 (cuciture?)
    trame = []
    for nome in ("stoffa_camicia", "stoffa_cazune", "ciocche"):
        a = tex[nome]
        trame.append(np.repeat(np.tile(a, (2, 2))[..., None], 3, 2))
    tavola(trame, 3, ["camicia 2x2", "cazune 2x2", "ciocche 2x2"], scala=2) \
        .save(ANTEPRIME / "trame_2x2.png")
    tinte = []
    for col in ((0.93, 0.93, 0.92), (0.72, 0.16, 0.14), (0.20, 0.30, 0.55)):
        tinte.append(np.tile(tex["stoffa_camicia"], (2, 2))[..., None] * np.asarray(col))
    for col in ((0.18, 0.24, 0.40), (0.14, 0.14, 0.15), (0.45, 0.38, 0.28)):
        tinte.append(np.tile(tex["stoffa_cazune"], (2, 2))[..., None] * np.asarray(col))
    for col in PELI[:3] + PELI[4:]:
        tinte.append(np.tile(tex["ciocche"], (2, 2))[..., None] * np.asarray(col))
    tavola(tinte, 5, scala=1).save(ANTEPRIME / "trame_tinte.png")
    iri = [np.repeat(tex["iride"][..., None], 3, 2)]
    for col in OCCHI_COL:
        iri.append(srgb(lin(col) * lin(np.repeat(tex["iride"][..., None], 3, 2)) * 1.6))
    tavola(iri, 6, scala=3).save(ANTEPRIME / "iride.png")
    # 6. gli strati crudi
    crudi = [tex[k] for k in tex if k.startswith(("bocca_", "rughe_"))]
    crudi += [np.repeat(tex[k][..., None], 3, 2) for k in tex if k.startswith("barba_")]
    nomi = [k for k in tex if k.startswith(("bocca_", "rughe_"))] + \
        [k for k in tex if k.startswith("barba_")]
    tavola(crudi, 5, nomi).save(ANTEPRIME / "strati_crudi.png")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--senza-anteprime", action="store_true")
    args = ap.parse_args()
    tex = genera()
    for p in sorted(USCITA.glob("*.png")):
        print(f"{p.relative_to(PROGETTO)}  {Image.open(p).size}  {p.stat().st_size} B")
    if not args.senza_anteprime:
        anteprime(tex)
        print(f"anteprime in {ANTEPRIME}")


if __name__ == "__main__":
    main()
