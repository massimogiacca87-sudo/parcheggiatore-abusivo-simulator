#!/usr/bin/env python3
"""Pianta della citta': isolati, vicoli, piazzette.

Si definiscono le STRADE e le PIAZZE; tutto il resto e' costruito. Il
programma rasterizza, ricava gli isolati come rettangoli massimali, verifica
che lo spazio calpestabile sia tutto collegato, disegna la pianta e sputa
fuori la costante GDScript da incollare in `citta_3d.gd`.

Si lavora qui e non direttamente in GDScript perche' una pianta si giudica
guardandola, e provare una variante costa due secondi invece di un export.

La misura che conta piu' di tutte e' la larghezza dei vicoli: 4-6 metri con
palazzi da sedici significa camminare in fondo a un canyon, che e' la cosa
che fa dire "questa e' Napoli". Sopra i dieci metri diventa periferia.
"""

from PIL import Image, ImageDraw
from collections import deque

W, H = 190, 172
PASSO = 1  # metri per cella della griglia

# --- Le strade, in rettangoli (x0, z0, x1, z1) -----------------------------
STRADE = [
    # =====================================================================
    # 'E DECUMANE — le tre strade lunghe che tagliano la citta' da un capo
    # all'altro.
    #
    # E' la cosa che rende Napoli riconoscibile su una pianta prima ancora
    # che dal vero: il centro antico e' ancora la griglia greca, tre strade
    # dritte parallele est-ovest (i decumani) tagliate a pettine da tante
    # traverse strettissime (i cardini). Non e' una maglia regolare come
    # quella americana — e' una maglia SBILANCIATA: pochissime strade
    # lunghe, e moltissime corte e strette.
    #
    # Prima la mappa aveva sette strade nord-sud e sei est-ovest, tutte piu'
    # o meno alla stessa distanza. Era una scacchiera. Adesso le lunghe
    # est-ovest restano tre e i cardini raddoppiano: la differenza si vede
    # camminando, perche' una strada lunga la percorri e le traverse le
    # attraversi.
    # =====================================================================
    (0, 60, 190, 67),       # 'o Decumano Maggiore — Via 'e sotto, 7 m
    (0, 92, 190, 99),       # Via Marina, la strada bassa
    # **Spaccanapoli.** Quattro metri per centonovanta, perfettamente
    # dritta, da un bordo all'altro della mappa senza un solo scarto. E' la
    # strada piu' famosa di Napoli e la si riconosce da una cosa sola: ci
    # entri e ne vedi il fondo. Qui e' l'unica via che attraversa tutto,
    # ed e' anche la piu' stretta delle tre. Non e' un errore: e' proprio
    # quello il punto.
    # Sta a z 74-78 e non piu' vicino a Via Marina: fra le due ci vogliono
    # almeno dodici metri, se no la striscia di isolati in mezzo scende
    # sotto ai cinque metri, il pianificatore la butta via, e le due strade
    # si fondono in un unico piazzale largo quindici metri. Che e'
    # esattamente il contrario di Spaccanapoli.
    (0, 74, 190, 78),

    # --- le altre trasversali, corte ---
    (0, 0, 190, 5),         # la fascia a mare
    (0, 124, 190, 128),
    (0, 152, 190, 156),
    (0, 168, 190, 172),     # via bassa
    (51, 22, 110, 26),      # traversa alta, fra piazza e piazzale
    (51, 40, 110, 44),      # traversa bassa
    (0, 30, 13, 34),        # traversina di ponente

    # =====================================================================
    # 'E CARDINE — le traverse strette, a pettine sui decumani.
    #
    # Sono passate da sette a dodici, e stanno molto piu' vicine fra loro:
    # nella fascia centrale il passo scende da venticinque metri a dodici.
    # Dodici metri di passo con vicoli da quattro vuol dire isolati da otto
    # metri di fronte — cioe' palazzi stretti e alti, che e' esattamente la
    # proporzione dei Quartieri e del centro antico.
    # =====================================================================
    (9, 5, 13, 172),        # vicolo di ponente
    (26, 62, 30, 172),      # cardine dietro 'a piazza (solo a sud)
    (51, 5, 55, 172),       # vicolo dietro la piazza
    (63, 5, 67, 172),       # cardine 'e mieze
    (74, 0, 82, 172),       # 'O Corso: la piu' larga, e resta 8 m
    (90, 5, 94, 172),       # cardine d''o cuorpo 'e Napule
    (103, 5, 107, 172),
    (116, 56, 120, 172),    # cardine 'e levante
    (129, 56, 133, 172),    # sotto al piazzale la maglia continua
    (155, 56, 159, 172),
    (166, 67, 170, 172),    # cardine d''o Vommero
    (179, 5, 183, 172),     # vicolo di levante

    # --- vicoli ciechi ---
    #
    # Sono rimasti due. Prima erano cinque, ma tre di quelli sono diventati
    # cardini veri: una citta' con cinque vicoli ciechi su dodici traverse
    # non e' Napoli, e' un labirinto. A Napoli i vicoli ciechi ci sono, ma
    # sono l'eccezione — la regola e' che si passa sempre.
    #
    # Finiscono DUE METRI prima dell'isolato successivo, cosi' il
    # rettangolo dell'isolato si richiude sopra e in fondo al vicolo c'e'
    # una facciata vera invece di un muro invisibile.
    (140, 100, 144, 116),   # 'o vico d''o ferraro
    (20, 158, 24, 166),
]

# --- Gli spazi che restano liberi ------------------------------------------
PIAZZE = {
    "piazza":      (14, 6, 48, 60),      # la tua, invariata
    "stadio":      (110, 6, 178, 58),
    "mercato":     (15, 101, 48, 122),   # non piu' una piazza: 'a via d''o mercato
    "cornetteria": (134, 101, 154, 122),
}
# Spazi liberi che non sono zone di gioco.
SLARGHI = {
    "belvedere":   (16, 0, 48, 6),       # il golfo: qui non si costruisce mai
    "fontana":     (57, 70, 73, 89),
    "ragazzini":   (16, 130, 40, 148),
    "piazzetta":   (109, 130, 128, 148),
    "largo_est":   (160, 157, 178, 167),
}

MIN_LATO = 5   # sotto questa misura non e' un isolato, e' una scheggia


def mappa_isolati():
    """Griglia booleana: True dove va costruito."""
    g = [[True] * H for _ in range(W)]
    # Le piazze si allargano di un metro: un isolato appiccicato al bordo di
    # una piazza le mangerebbe il marciapiede.
    for x0, z0, x1, z1 in list(PIAZZE.values()) + list(SLARGHI.values()):
        for x in range(max(0, x0 - 1), min(W, x1 + 1)):
            for z in range(max(0, z0 - 1), min(H, z1 + 1)):
                g[x][z] = False
    # Le strade valgono ESATTE. Dare anche a loro il margine voleva dire
    # allargare ogni vicolo di due metri senza accorgersene: i 4 m dichiarati
    # diventavano 6, ed e' esattamente la differenza fra un vicolo e una via.
    for x0, z0, x1, z1 in STRADE:
        for x in range(max(0, x0), min(W, x1)):
            for z in range(max(0, z0), min(H, z1)):
                g[x][z] = False
    return g


def rettangoli(g):
    """Estrae rettangoli massimali dalle celle da costruire, con una
    passata avida: si parte dalla cella libera piu' in alto a sinistra, si
    allarga in x finche' si puo', poi in z."""
    preso = [[False] * H for _ in range(W)]
    fuori = []
    for x in range(W):
        for z in range(H):
            if not g[x][z] or preso[x][z]:
                continue
            x1 = x
            while x1 + 1 < W and g[x1 + 1][z] and not preso[x1 + 1][z]:
                x1 += 1
            z1 = z
            while z1 + 1 < H and all(
                    g[i][z1 + 1] and not preso[i][z1 + 1] for i in range(x, x1 + 1)):
                z1 += 1
            for i in range(x, x1 + 1):
                for j in range(z, z1 + 1):
                    preso[i][j] = True
            if x1 + 1 - x >= MIN_LATO and z1 + 1 - z >= MIN_LATO:
                fuori.append((x, z, x1 + 1, z1 + 1))
    return fuori


def calpestabile(blocchi):
    g = [[True] * H for _ in range(W)]
    for x0, z0, x1, z1 in blocchi:
        for x in range(x0, x1):
            for z in range(z0, z1):
                g[x][z] = False
    return g


def collegato(g, partenza):
    i0, j0 = int(partenza[0]), int(partenza[1])
    if not g[i0][j0]:
        return None, 0
    visto = [[False] * H for _ in range(W)]
    coda = deque([(i0, j0)])
    visto[i0][j0] = True
    n = 1
    while coda:
        i, j = coda.popleft()
        for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            a, b = i + di, j + dj
            if 0 <= a < W and 0 <= b < H and g[a][b] and not visto[a][b]:
                visto[a][b] = True
                n += 1
                coda.append((a, b))
    return visto, n


PUNTI = {
    "start": (31, 28),
    "treno": (22, 163),
    "leggende": (181, 40),
    "teduccio": (65, 115),
    "maradona": (170, 115),
    "pino": (142, 79),
    "bud": (90, 140),
    "spighe": (20, 111),
    "cornett": (144, 104),
    "fontana": (65, 79),
    "corso_n": (78, 20),
    "marina_o": (30, 95),
}


def disegna(blocchi, visto, nome="/tmp/pianta.png"):
    S = 5
    im = Image.new("RGB", (W * S, H * S), (232, 226, 214))
    d = ImageDraw.Draw(im)
    for i in range(W):
        for j in range(H):
            if visto is not None and not visto[i][j]:
                continue
            d.rectangle([i * S, j * S, (i + 1) * S, (j + 1) * S],
                        fill=(208, 200, 184))
    for k, (x0, z0, x1, z1) in PIAZZE.items():
        d.rectangle([x0 * S, z0 * S, x1 * S, z1 * S], fill=(230, 216, 176),
                    outline=(150, 120, 60), width=2)
        d.text((x0 * S + 6, z0 * S + 6), k, fill=(90, 70, 20))
    for k, (x0, z0, x1, z1) in SLARGHI.items():
        d.rectangle([x0 * S, z0 * S, x1 * S, z1 * S], fill=(222, 214, 194),
                    outline=(180, 172, 150))
        d.text((x0 * S + 5, z0 * S + 5), k, fill=(140, 130, 100))
    for x0, z0, x1, z1 in blocchi:
        d.rectangle([x0 * S, z0 * S, x1 * S, z1 * S], fill=(122, 108, 98),
                    outline=(64, 56, 50))
    for nome_p, (px, pz) in PUNTI.items():
        d.ellipse([px * S - 5, pz * S - 5, px * S + 5, pz * S + 5],
                  fill=(220, 60, 40))
        d.text((px * S + 8, pz * S - 6), nome_p, fill=(170, 30, 20))
    im.save(nome)


def gdscript(blocchi):
    righe = []
    for x0, z0, x1, z1 in blocchi:
        righe.append("\t[%d, %d, %d, %d]," % (x0, z0, x1, z1))
    return "const ISOLATI := [\n" + "\n".join(righe) + "\n]\n"


if __name__ == "__main__":
    g = mappa_isolati()
    b = rettangoli(g)
    cal = calpestabile(b)
    visto, n = collegato(cal, PUNTI["start"])
    libere = sum(1 for i in range(W) for j in range(H) if cal[i][j])
    aree = [(x1 - x0) * (z1 - z0) for x0, z0, x1, z1 in b]
    print(f"isolati: {len(b)}   area costruita: {sum(aree)} m2 "
          f"({100.0 * sum(aree) / (W * H):.0f}% della mappa)")
    print(f"calpestabile: {libere} m2   raggiungibile dalla piazza: {n} "
          f"({100.0 * n / libere:.1f}%)")
    brutti = 0
    for nome_p, (px, pz) in PUNTI.items():
        stato = "OK" if cal[px][pz] and visto[px][pz] else (
            "MURATO" if not cal[px][pz] else "ISOLATO")
        if stato != "OK":
            brutti += 1
        print(f"  {nome_p:10s} ({px:4d},{pz:4d})  {stato}")
    if brutti:
        print(f"!! {brutti} punti da spostare")
    disegna(b, visto)
    with open("/tmp/isolati.gd", "w") as f:
        f.write(gdscript(b))
    print("pianta -> /tmp/pianta.png   costante -> /tmp/isolati.gd")
