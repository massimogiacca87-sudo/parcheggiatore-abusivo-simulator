#!/usr/bin/env python3
"""Genera le texture dei quartieri nuovi.

Sono SEGNAPOSTO, e vanno benissimo per giocare: intonaci, pietre e
pavimentazioni fatte con rumore multi-ottava piu' i motivi giusti (conci,
bugnato, basoli). Ma sono generate a codice, non fotografate, e si vede.

I prompt per rifarle con un generatore di immagini stanno in
`claude/TEXTURE-QUARTIERI.md`. Chi le rifa' deve solo salvare il file con lo
STESSO NOME in `assets/textures/` — il gioco non va toccato.

Requisiti per una sostituzione che funzioni:
  - quadrata, affiancabile senza cuciture (seamless/tileable);
  - una piastrella copre circa SEI METRI di muro vero, quindi la scala del
    dettaglio va pensata su quella misura;
  - la LUMINANZA fa da mappa di rilievo (lo shader ricava le normali dal
    chiaroscuro): le fughe e le crepe devono essere piu' scure del piano,
    o il muro esce piatto;
  - niente ombre "cotte" dentro alla texture, che il sole ce lo mette il
    gioco.
"""

import numpy as np
from PIL import Image

LATO = 384


def _rumore(dim, ottave=5, seme=0, persistenza=0.55, grana=4):
    """Rumore multi-ottava affiancabile: si somma rumore a frequenze
    raddoppiate, ognuna generata su una griglia che si richiude su se'
    stessa.

    `grana` e' la griglia dell'ottava piu' grossa. Partiva da 4, cioe' da
    macchie larghe un quarto di piastrella — un metro e mezzo di muro vero —
    e con quelle l'intonaco veniva a chiazze come una mimetica invece che a
    grana. Da 8 in su le macchie grosse spariscono e resta la materia."""
    rng = np.random.default_rng(seme)
    fuori = np.zeros((dim, dim), dtype=np.float64)
    ampiezza = 1.0
    totale = 0.0
    for o in range(ottave):
        n = grana * (2 ** o)
        base = rng.random((n, n))
        # si richiude: si ripete la prima riga/colonna in fondo
        base = np.pad(base, ((0, 1), (0, 1)), mode="wrap")
        campo = np.asarray(
            Image.fromarray((base * 255).astype(np.uint8)).resize(
                (dim + dim // n, dim + dim // n), Image.BICUBIC),
            dtype=np.float64)[:dim, :dim] / 255.0
        fuori += campo * ampiezza
        totale += ampiezza
        ampiezza *= persistenza
    fuori /= totale
    return (fuori - fuori.min()) / max(1e-6, fuori.max() - fuori.min())


def _conci(dim, righe, colonne, sfalsa=True, fuga=0.02, seme=1):
    """Maschera dei conci: 1 sul concio, 0 nella fuga. Torna anche un id per
    concio, che serve a dare a ognuno la sua tinta."""
    rng = np.random.default_rng(seme)
    m = np.ones((dim, dim))
    ids = np.zeros((dim, dim), dtype=np.int32)
    h = dim / righe
    fw = max(1, int(fuga * dim / max(righe, colonne) * 2))
    for r in range(righe):
        y0, y1 = int(r * h), int((r + 1) * h)
        m[y0:y0 + fw, :] = 0.0
        off = (0.5 if (sfalsa and r % 2) else 0.0)
        w = dim / colonne
        for c in range(colonne + 1):
            x = int(((c + off) * w) % dim)
            m[y0:y1, x:x + fw] = 0.0
            if x + fw > dim:
                m[y0:y1, 0:(x + fw) % dim] = 0.0
            ids[y0:y1, x:min(dim, x + int(w))] = rng.integers(0, 999)
    return m, ids


def _salva(nome, arr):
    arr = np.clip(arr, 0, 1)
    Image.fromarray((arr * 255).astype(np.uint8)).save(
        f"assets/textures/{nome}.jpg", quality=92, optimize=True)
    print(f"  {nome}.jpg")


def _colora(grigio, chiaro, scuro):
    """Da una mappa 0..1 a un'immagine RGB fra due tinte."""
    g = grigio[..., None]
    return np.array(scuro) * (1 - g) + np.array(chiaro) * g


# ---------------------------------------------------------------------------

def liberty():
    """'O Vommero: intonaco liscio, chiaro, perfetto. Bugne orizzontali
    finissime e nessuna crepa: e' il quartiere dove i muri li rifanno."""
    n = _rumore(LATO, ottave=6, seme=11, persistenza=0.40, grana=10)
    g = 0.52 + n * 0.30
    # Le fasce della bugnatura liscia. Vanno INCISE per davvero: e' l'unico
    # rilievo che ha un muro del Vomero, e se resta un'ombra da un decimo la
    # facciata esce bianca e piatta come un foglio.
    y = np.arange(LATO)[:, None]
    # I corsi della bugnatura liscia: uno ogni 96 px, cioe' circa un metro e
    # mezzo di muro vero. A 44 px cadevano ogni settanta centimetri e da
    # lontano diventavano una grattugia.
    banda = y % 96
    g -= ((banda < 4).astype(float)) * 0.34
    g += ((banda >= 4) & (banda < 10)).astype(float) * 0.07
    g += (_rumore(LATO, ottave=7, seme=12) - 0.5) * 0.16
    return _colora(g, (0.95, 0.92, 0.84), (0.52, 0.50, 0.45))


def liberty_verde():
    """La seconda tinta del Vomero: verde salvia chiaro, sempre pulito."""
    n = _rumore(LATO, ottave=6, seme=13, persistenza=0.40, grana=10)
    g = 0.50 + n * 0.30
    y = np.arange(LATO)[:, None]
    banda = y % 96
    g -= ((banda < 4).astype(float)) * 0.32
    g += ((banda >= 4) & (banda < 10)).astype(float) * 0.06
    g += (_rumore(LATO, ottave=7, seme=14) - 0.5) * 0.15
    return _colora(g, (0.83, 0.89, 0.79), (0.42, 0.52, 0.44))


def travertino():
    """Fuorigrotta razionalista: lastre di travertino grandi, squadrate,
    con la porosita' tipica."""
    m, ids = _conci(LATO, righe=6, colonne=4, sfalsa=False, fuga=0.03, seme=21)
    n = _rumore(LATO, ottave=6, seme=22, persistenza=0.55, grana=8)
    # i buchi del travertino: rumore stretto e scuro
    pori = (_rumore(LATO, ottave=7, seme=23, persistenza=0.75) < 0.34).astype(float)
    g = 0.58 + n * 0.26 - pori * 0.16
    g += ((ids % 7) - 3) / 55.0
    g = g * (0.45 + 0.55 * m)
    return _colora(g, (0.90, 0.87, 0.80), (0.40, 0.38, 0.34))


def tufo():
    """'A Sanita': conci di tufo giallo, sbrecciati, con le fughe larghe di
    malta e le colature di umidita'."""
    m, ids = _conci(LATO, righe=9, colonne=5, sfalsa=True, fuga=0.05, seme=31)
    n = _rumore(LATO, ottave=6, seme=32, persistenza=0.55, grana=8)
    g = 0.62 + n * 0.26
    g += ((ids % 11) - 5) / 110.0
    # colature verticali dall'alto
    col = _rumore(LATO, ottave=3, seme=33)
    scia = np.clip(col - 0.55, 0, 1) * 3.0
    scia = scia * np.linspace(1.0, 0.15, LATO)[:, None]
    g -= scia * 0.13
    g = g * (0.68 + 0.32 * m)
    return _colora(g, (0.90, 0.78, 0.46), (0.48, 0.40, 0.24))


def piperno():
    """La pietra lavica scura dei basamenti e dei portali. Serve dappertutto
    ma soprattutto nel centro antico."""
    m, ids = _conci(LATO, righe=7, colonne=3, sfalsa=True, fuga=0.035, seme=41)
    n = _rumore(LATO, ottave=6, seme=42, persistenza=0.66)
    # le inclusioni chiare del piperno
    chiazze = (_rumore(LATO, ottave=7, seme=43, persistenza=0.8) > 0.63).astype(float)
    g = 0.34 + n * 0.20 + chiazze * 0.14
    g += ((ids % 5) - 2) / 90.0
    g = g * (0.6 + 0.4 * m)
    return _colora(g, (0.58, 0.56, 0.55), (0.20, 0.19, 0.20))


def umbertino():
    """'A Riviera: intonaco grigio-verde con la bugnatura a fasce larghe,
    quello dei palazzi di fine Ottocento."""
    n = _rumore(LATO, ottave=6, seme=51, persistenza=0.48, grana=8)
    g = 0.66 + n * 0.20
    y = np.arange(LATO)[:, None]
    # bugnato: fasce alte 32 px con la fuga incisa
    banda = (y % 32)
    g -= ((banda < 3).astype(float)) * 0.16
    g += ((banda > 3) & (banda < 8)).astype(float) * 0.05
    macchie = np.clip(_rumore(LATO, ottave=4, seme=52) - 0.6, 0, 1) * 1.6
    g -= macchie * 0.12
    return _colora(g, (0.82, 0.83, 0.76), (0.48, 0.50, 0.46))


def scrostato():
    """'E Quartiere: intonaco caduto a chiazze, con sotto il mattone."""
    n = _rumore(LATO, ottave=6, seme=61, persistenza=0.52, grana=8)
    intonaco = 0.70 + n * 0.22
    # il mattone sotto
    mb, _ = _conci(LATO, righe=16, colonne=8, sfalsa=True, fuga=0.06, seme=62)
    mattone = 0.42 + _rumore(LATO, ottave=5, seme=63) * 0.18
    mattone = mattone * (0.55 + 0.45 * mb)
    # dove l'intonaco e' caduto
    # Quanto intonaco e' caduto. Con il 40% il muro veniva a chiazze grosse
    # come una mimetica, e siccome la piastrella si ripete tre volte in
    # altezza le chiazze si riconoscevano una per una: si vedeva il motivo
    # ripetersi. Al 18%, con i bordi sfumati invece che tagliati, resta un
    # intonaco rovinato invece di una macchia.
    buchi = _rumore(LATO, ottave=5, seme=64, persistenza=0.62, grana=6)
    caduto = np.clip((0.38 - buchi) / 0.09, 0.0, 1.0)
    bordo = np.clip(1.0 - np.abs(buchi - 0.38) / 0.06, 0.0, 1.0)
    g = intonaco * (1 - caduto) + mattone * caduto - bordo * 0.07
    a = _colora(g, (0.92, 0.86, 0.70), (0.55, 0.48, 0.36))
    # il mattone tira al rosso
    rosso = caduto[..., None] * np.array([0.11, -0.035, -0.07])
    return a + rosso


def basolato():
    """I basoli: lastroni di pietra lavica, grandi, consumati e lucidi."""
    m, ids = _conci(LATO, righe=5, colonne=5, sfalsa=True, fuga=0.045, seme=71)
    n = _rumore(LATO, ottave=6, seme=72, persistenza=0.62)
    g = 0.36 + n * 0.16
    g += ((ids % 9) - 4) / 80.0
    # il consumo al centro di ogni basolo
    g += (1 - m) * -0.10
    g = g * (0.62 + 0.38 * m)
    return _colora(g, (0.58, 0.58, 0.60), (0.19, 0.19, 0.21))


def cotto():
    """I coppi dei tetti a falda."""
    x = np.arange(LATO)[None, :]
    y = np.arange(LATO)[:, None]
    # file di coppi: onde orizzontali sfalsate
    onda = np.sin((x / LATO) * np.pi * 2 * 12 + (y // 32) * 1.6)
    n = _rumore(LATO, ottave=5, seme=81, persistenza=0.6)
    g = 0.55 + onda * 0.14 + n * 0.20
    g -= ((y % 32) < 3).astype(float) * 0.16
    a = _colora(g, (0.86, 0.55, 0.36), (0.42, 0.24, 0.16))
    return a


TUTTE = {
    "muro_liberty": liberty,
    "muro_liberty_verde": liberty_verde,
    "muro_travertino": travertino,
    "muro_tufo": tufo,
    "piperno": piperno,
    "muro_umbertino": umbertino,
    "muro_scrostato": scrostato,
    "basolato": basolato,
    "cotto": cotto,
}

if __name__ == "__main__":
    print("texture dei quartieri:")
    for nome, f in TUTTE.items():
        _salva(nome, f())
