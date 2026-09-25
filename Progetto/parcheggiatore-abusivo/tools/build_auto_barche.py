#!/usr/bin/env python3
"""Estrae le auto distinte del pack e le 5 imbarcazioni."""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np, trimesh
from build_models import (load_instances, finalize, decimate, OUT,
                          SRC_CARS, SRC_BOATS, SRC_FISH, SRC_SAIL,
                          SRC_SAIL_TEX, tex)

report = []

# ------------------------------------------------------------------ AUTO
# Vetrina in centimetri: 7 auto distinte, duplicate su due file lungo Z.
# Teniamo la fila z>0 e raggruppiamo per X. Muso gia' verso -Z.
CAR_X = [-935.35, -623.63, -297.32, -5.71, 273.83, 545.08, 847.80]
CAR_NOTE = ["berlina sportiva", "coupe fastback", "crossover / SUV coupe",
            "supercar da pista con alettone", "berlina compatta",
            "sportiva con spoiler", "coupe sportiva ad alettone alto"]


def car_mat(node):
    p = node.split('.')[0].split('_')[0]
    return {"Window": "glass", "Tires": "tire", "Rims": "wheel"}.get(p, "body")


print("== AUTO ==")
inst = load_instances(SRC_CARS)
for i, x in enumerate(CAR_X):
    sel = [(n, m) for n, m, _ in inst
           if (m.bounds[0][2] + m.bounds[1][2]) / 2 > 0
           and abs((m.bounds[0][0] + m.bounds[1][0]) / 2 - x) < 115]
    groups = {}
    for n, m in sel:
        groups.setdefault(car_mat(n), []).append(m)
    parts = []
    # **Il budget triangoli, e perche' era sbagliato.**
    #
    # Le sette auto uscivano a milleduecento triangoli l'una. Sembrava un
    # numero generoso per una macchina low-poly — solo che la carrozzeria
    # del modello di partenza ne ha da sola quasi cinquemila, e la
    # decimazione quadrica per arrivare a mille scuce la mesh: il tetto si
    # apre, i passaruota si accartocciano, i cerchi si staccano dalle
    # gomme. Da lontano non si vedeva; adesso che ce ne sono ferme in ogni
    # strada e ci si sale pure sopra, si vede benissimo.
    #
    # Con quattromiladuecento la carrozzeria resta praticamente intatta e i
    # cerchi restano tondi. Sette auto passano da 8.400 a 29.400 triangoli
    # in tutto: su una citta' che ne disegna sessantamila non si sente, e
    # il pacchetto cresce di mezzo mega.
    for name, cap in (("body", None), ("glass", None), ("wheel", 620), ("tire", 460)):
        if name not in groups:
            continue
        merged = trimesh.util.concatenate([m.copy() for m in groups[name]])
        if cap:
            merged = decimate(merged, cap)
        parts.append((name, merged, None))
    info = finalize(parts, "auto_pack_%d.glb" % (i + 1), budget=4200,
                    rot=None, auto_bow=False, scale=0.01, report=report)
    info["cosa"] = CAR_NOTE[i]
    info["pezzi"] = len(sel)

# ---------------------------------------------------------------- BARCHE
print("== BARCHE ==")


def pick(inst, xbox, zbox):
    out = []
    for n, m, mt in inst:
        cx = (m.bounds[0][0] + m.bounds[1][0]) / 2
        cz = (m.bounds[0][2] + m.bounds[1][2]) / 2
        if xbox[0] - 5 <= cx <= xbox[1] + 5 and zbox[0] - 5 <= cz <= zbox[1] + 5:
            out.append((n, m, mt))
    return out


binst = [t for t in load_instances(SRC_BOATS) if not t[0].startswith('Plane.005')]
bscene = trimesh.load(SRC_BOATS, process=False)
SRC_COL = {}
for g in bscene.geometry.values():
    mat = getattr(getattr(g, "visual", None), "material", None)
    bc = getattr(mat, "baseColorFactor", None)
    if mat is not None and bc is not None:
        SRC_COL[mat.name] = tuple(int(c) for c in np.array(bc)[:3])

# La vetrina e' in cm, le barche sono lunghe lungo X: la prua la trova
# detect_bow() guardando dove lo scafo si restringe.
SEL = [
    ("barca_1.glb", ((-288, 373), (5467, 5756)), 6.6, "gommone con fuoribordo"),
    ("barca_3.glb", ((2903, 4354), (495, 936)), 14.5, "motobarca / pilotina con cabina"),
    ("barca_4.glb", ((-1092, 1273), (1502, 2094)), 23.6, "yacht a motore"),
]
for out_name, xbox, zbox, tgt, note in [(a, b[0], b[1], c, d) for a, b, c, d in SEL]:
    sel = pick(binst, xbox, zbox)
    order = sorted(sel, key=lambda t: -len(t[1].faces))
    parts = []
    for k, (n, m, mt) in enumerate(order):
        name = "body" if k == 0 else "body_%d" % (k + 1)
        parts.append((name, m, None, SRC_COL.get(mt)))
    info = finalize(parts, out_name, budget=2500, target_len=tgt, report=report)
    info["cosa"] = note
    info["pezzi"] = len(sel)

# --- barca a vela (ha texture vere) ---
sinst = load_instances(SRC_SAIL)
SAIL_MAT = {"Material.003": ("body", "Boat.png"), "Material.001": ("vela", None),
            "Asta": ("asta", None), "Material.004": ("sedile", None),
            "Material.005": ("sedile", None), "Barril": ("barile", None)}
parts, seen = [], {}
for n, m, mt in sinst:
    name, texfile = SAIL_MAT.get(mt, ("body", None))
    if name == "barile":
        m = decimate(m, 130)          # i barili erano 1182 tri l'uno
    seen[name] = seen.get(name, 0) + 1
    key = name if seen[name] == 1 else "%s_%d" % (name, seen[name])
    t = tex(os.path.join(SRC_SAIL_TEX, texfile)) if texfile else None
    parts.append((key, m, t))
info = finalize(parts, "barca_2.glb", budget=2500, target_len=8.3, report=report)
info["cosa"] = "barca a vela con barili"

# --- peschereccio ---
finst = load_instances(SRC_FISH)
FISH_MAT = {"Windows": "glass", "Light": "light",
            "Fishing_Ship": "body", "Boat_Interior": "body_2"}
parts = [(FISH_MAT.get(mt, "body"), m, None) for n, m, mt in finst]
info = finalize(parts, "barca_5.glb", budget=2500, target_len=22.0, report=report)
info["cosa"] = "peschereccio"

json.dump(report, open("/tmp/claude-0/-home-claude/49ac95d1-b5fb-5d47-81ad-fe30c0296e44/scratchpad/w/rep_ab.json", "w"), indent=1)
