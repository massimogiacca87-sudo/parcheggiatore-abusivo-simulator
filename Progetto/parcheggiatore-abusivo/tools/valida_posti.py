#!/usr/bin/env python3
"""Controlla che tutto quello che sta a coordinate fisse in `citta_3d.gd`
sia ancora dove deve stare, dopo un cambio di pianta.

## Perche' serve

La citta' e' fatta di due cose: una maglia di strade e isolati che si
GENERA (`pianta.py`), e un centinaio di oggetti piazzati a mano — murales,
stencil, tavoli, il ferraro, la gente ferma, i manifesti, le edicole
votive. Ogni volta che la maglia cambia, quelle coordinate scritte a mano
possono finire dentro a un muro, e non te ne accorgi finche' non ci passi
davanti in partita.

Questo script rilegge le costanti dal sorgente GDScript, rasterizza la
pianta nuova, e per ogni oggetto dice se sta ancora su terreno calpestabile
— e per quelli appesi a un muro, se dietro c'e' davvero un muro e davanti
c'e' spazio.
"""
import re, math, sys

SRC = "scripts/citta_3d.gd"
W, H = 190, 172


def costante(nome, testo):
    m = re.search(r'const %s := \[(.*?)\n\]' % nome, testo, re.S)
    if not m:
        return []
    fuori = []
    for r in re.finditer(r'\[\s*([-\d.]+)\s*,\s*([-\d.]+)\s*,\s*([-\d.]+)\s*,'
                         r'\s*([-\d.]+)\s*\]', m.group(1)):
        fuori.append([float(x) for x in r.groups()])
    return fuori


def leggi():
    t = open(SRC, encoding="utf-8").read()
    strade = costante("STRADE", t)
    slarghi = costante("SLARGHI", t)
    isolati = costante("ISOLATI", t)
    zone = []
    for m in re.finditer(r'"rect": \[([\d.]+), ([\d.]+), ([\d.]+), ([\d.]+)\]', t):
        zone.append([float(x) for x in m.groups()])
    return t, strade, slarghi, isolati, zone


def dentro(x, z, rs, m=0.0):
    return any(r[0] - m <= x <= r[2] + m and r[1] - m <= z <= r[3] + m
               for r in rs)


def main():
    t, strade, slarghi, isolati, zone = leggi()
    libero = strade + slarghi + zone
    print(f"strade={len(strade)} slarghi={len(slarghi)} "
          f"isolati={len(isolati)} zone={len(zone)}\n")

    guai = 0

    # --- 1. oggetti che devono stare su terreno calpestabile ---
    a_terra = []
    for nome, patt in [
        ("POSTI_SCOPA", r'const POSTI_SCOPA := \[(.*?)\n\]'),
        ("GENTE_FERMA", r'const GENTE_FERMA := \[(.*?)\n\]'),
    ]:
        m = re.search(patt, t, re.S)
        if not m:
            continue
        for r in re.finditer(r'\[\s*([-\d.]+)\s*,\s*([-\d.]+)\s*,', m.group(1)):
            a_terra.append((nome, float(r.group(1)), float(r.group(2))))
    for nome, patt in [
        ("POSTO_TRE_CARTE", r'const POSTO_TRE_CARTE := \[([-\d.]+), ([-\d.]+)'),
        ("POSTO_SCOMMESSE", r'const POSTO_SCOMMESSE := \[([-\d.]+), ([-\d.]+)'),
        ("POSTO_ARMIERE", r'const POSTO_ARMIERE := \[([-\d.]+), ([-\d.]+)'),
    ]:
        m = re.search(patt, t)
        if m:
            a_terra.append((nome, float(m.group(1)), float(m.group(2))))
    # i manifesti stanno in game_manager? no: POSTI_MANIFESTI e' qui
    m = re.search(r'const POSTI_MANIFESTI := \[(.*?)\n\]', t, re.S)
    if m:
        for r in re.finditer(r'\["(\w+)",\s*([-\d.]+),\s*([-\d.]+),', m.group(1)):
            a_terra.append(("manifesto_" + r.group(1),
                            float(r.group(2)), float(r.group(3))))

    print("--- oggetti a terra ---")
    for nome, x, z in a_terra:
        ok_l = dentro(x, z, libero)
        ok_i = dentro(x, z, isolati)
        if ok_i or not ok_l:
            guai += 1
            print(f"  !! {nome:26s} ({x:6.1f},{z:6.1f}) "
                  f"{'DENTRO A UN ISOLATO' if ok_i else 'FUORI DAL CALPESTABILE'}")
    print(f"  {len(a_terra)} controllati, {guai} da spostare")

    # --- 2. cose appese a un muro: dietro isolato, davanti libero ---
    muri = []
    for nome, patt, gi in [
        ("MURALES", r'const MURALES := \[(.*?)\n\]', (0, 1, 2)),
        ("STENCIL", r'const STENCIL := \[(.*?)\n\]', (0, 1, 2)),
    ]:
        m = re.search(patt, t, re.S)
        if not m:
            continue
        for r in re.finditer(
                r'\[\s*([-\d.]+),\s*([-\d.]+),\s*([-\d.]+),', m.group(1)):
            muri.append((nome, float(r.group(1)), float(r.group(2)),
                         float(r.group(3))))
    print("\n--- cose appese ai muri ---")
    g2 = 0
    for nome, x, z, ang in muri:
        th = math.radians(ang)
        fx, fz = math.sin(th), math.cos(th)
        davanti = dentro(x + fx * 1.0, z + fz * 1.0, libero)
        dietro = dentro(x - fx * 0.5, z - fz * 0.5, isolati)
        if not (davanti and dietro):
            g2 += 1
            print(f"  !! {nome:9s} ({x:6.1f},{z:6.1f}) {ang:5.0f}gr  "
                  f"davanti={'ok' if davanti else 'MURO'}  "
                  f"dietro={'ok' if dietro else 'VUOTO'}")
    print(f"  {len(muri)} controllati, {g2} da spostare")
    return guai + g2


def suggerisci(quanti, targets):
    """Per ogni bersaglio (x, z) trova il punto a muro valido piu' vicino."""
    t, strade, slarghi, isolati, zone = leggi()
    libero = strade + slarghi + zone
    cand = []
    for x0, z0, x1, z1 in isolati:
        for ang in (90, 270, 0, 180):
            if ang in (90, 270):
                x = (x1 + 0.1) if ang == 90 else (x0 - 0.1)
                fx = math.sin(math.radians(ang))
                zz = [z0 + 2 + i * 2 for i in range(int((z1 - z0 - 4) // 2) + 1)]
                for z in zz:
                    if dentro(x + fx, z, libero) and dentro(x + fx * 2.2, z, libero):
                        cand.append((round(x, 1), round(z, 1), ang))
            else:
                z = (z1 + 0.1) if ang == 0 else (z0 - 0.1)
                fz = math.cos(math.radians(ang))
                xx = [x0 + 2 + i * 2 for i in range(int((x1 - x0 - 4) // 2) + 1)]
                for x in xx:
                    if dentro(x, z + fz, libero) and dentro(x, z + fz * 2.2, libero):
                        cand.append((round(x, 1), round(z, 1), ang))
    for tx, tz in targets:
        c = min(cand, key=lambda k: (k[0] - tx) ** 2 + (k[1] - tz) ** 2)
        print(f"  ({tx},{tz}) -> [{c[0]}, {c[1]}, {c[2]}.0,]")


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "muri":
        suggerisci(0, [tuple(map(float, a.split(","))) for a in sys.argv[2:]])
    else:
        sys.exit(1 if main() else 0)
