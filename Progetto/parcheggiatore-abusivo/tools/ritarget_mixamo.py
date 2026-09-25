#!/usr/bin/env python3
"""Ritarget delle animazioni Mixamo sul rig procedurale del gioco.

Il gioco non ha uno Skeleton3D: ha una gerarchia di Node3D nudi
(scripts/rig.gd), tutti in posa di riposo con rotazione identita' e le
braccia lungo il corpo (asse -Y). Mixamo esporta invece uno scheletro in
T-pose, con le braccia lungo +-X e ogni osso con la sua rotazione di
riposo.

Il ritarget si fa in coordinate GLOBALI, che e' l'unico modo di non
dover indovinare gli assi:

    game_globale(osso) = mixamo_globale(osso) * inv(mixamo_riposo(osso))
    game_locale(osso)  = inv(game_globale(padre)) * game_globale(osso)

La prima riga toglie la posa di riposo di Mixamo, cioe' trasforma la
rotazione assoluta dell'osso in "di quanto e' ruotato rispetto a com'era
fermo". La seconda la riporta nello spazio del padre del gioco, che e'
quello che le tracce di animazione di Godot vogliono. Siccome nel gioco
la posa di riposo e' identita' ovunque, non serve altro.
"""
import json, struct, sys, math, os

# Mixamo -> gioco. Il "LeftShoulder" di Mixamo e' la clavicola e nel
# gioco non esiste: la sua rotazione viene assorbita dal calcolo in
# globale, che e' un altro motivo per farlo cosi'.
MAPPA = {
    "mixamorig:Hips": "hips",
    "mixamorig:Spine1": "spine",
    "mixamorig:Spine2": "chest",
    "mixamorig:Neck": "neck",
    "mixamorig:Head": "head",
    "mixamorig:LeftArm": "shoulder_l",
    "mixamorig:LeftForeArm": "elbow_l",
    "mixamorig:LeftHand": "hand_l",
    "mixamorig:RightArm": "shoulder_r",
    "mixamorig:RightForeArm": "elbow_r",
    "mixamorig:RightHand": "hand_r",
    "mixamorig:LeftUpLeg": "thigh_l",
    "mixamorig:LeftLeg": "knee_l",
    "mixamorig:LeftFoot": "foot_l",
    "mixamorig:RightUpLeg": "thigh_r",
    "mixamorig:RightLeg": "knee_r",
    "mixamorig:RightFoot": "foot_r",
}
# Il padre di ogni osso del gioco (per passare da globale a locale).
PADRE = {
    "hips": None, "spine": "hips", "chest": "spine", "neck": "chest",
    "head": "neck",
    "shoulder_l": "chest", "elbow_l": "shoulder_l", "hand_l": "elbow_l",
    "shoulder_r": "chest", "elbow_r": "shoulder_r", "hand_r": "elbow_r",
    "thigh_l": "hips", "knee_l": "thigh_l", "foot_l": "knee_l",
    "thigh_r": "hips", "knee_r": "thigh_r", "foot_r": "knee_r",
}

# ---------------------------------------------------------------- quaternioni
def qmul(a, b):
    ax, ay, az, aw = a; bx, by, bz, bw = b
    return (aw*bx + ax*bw + ay*bz - az*by,
            aw*by - ax*bz + ay*bw + az*bx,
            aw*bz + ax*by - ay*bx + az*bw,
            aw*bw - ax*bx - ay*by - az*bz)

def qconj(q):
    return (-q[0], -q[1], -q[2], q[3])

def qnorm(q):
    n = math.sqrt(sum(c*c for c in q)) or 1.0
    return tuple(c/n for c in q)

def qslerp(a, b, t):
    d = sum(x*y for x, y in zip(a, b))
    if d < 0.0:
        b = tuple(-c for c in b); d = -d
    if d > 0.9995:
        return qnorm(tuple(x + (y-x)*t for x, y in zip(a, b)))
    th = math.acos(max(-1.0, min(1.0, d)))
    s = math.sin(th)
    return tuple((math.sin((1-t)*th)*x + math.sin(t*th)*y)/s
                 for x, y in zip(a, b))

# ---------------------------------------------------------------- glTF
def leggi(g, buf, idx):
    acc = g["accessors"][idx]
    bv = g["bufferViews"][acc["bufferView"]]
    off = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
    ncomp = {"SCALAR": 1, "VEC3": 3, "VEC4": 4}[acc["type"]]
    assert acc["componentType"] == 5126, "solo float"
    vals = struct.unpack_from("<%df" % (acc["count"]*ncomp), buf, off)
    if ncomp == 1:
        return list(vals)
    return [vals[i*ncomp:(i+1)*ncomp] for i in range(acc["count"])]


def carica(path):
    g = json.load(open(path))
    buf = open(os.path.join(os.path.dirname(path),
                            g["buffers"][0]["uri"]), "rb").read()
    return g, buf


def campiona(tempi, valori, t):
    """Interpolazione lineare/slerp su una traccia campionata."""
    if t <= tempi[0]:
        return valori[0]
    if t >= tempi[-1]:
        return valori[-1]
    lo, hi = 0, len(tempi) - 1
    while hi - lo > 1:
        mid = (lo + hi) // 2
        if tempi[mid] <= t: lo = mid
        else: hi = mid
    k = (t - tempi[lo]) / max(1e-9, tempi[hi] - tempi[lo])
    a, b = valori[lo], valori[hi]
    if len(a) == 4:
        return qslerp(a, b, k)
    return tuple(x + (y-x)*k for x, y in zip(a, b))


def estrai(path, da, a, fps, nome):
    g, buf = carica(path)
    nodi = g["nodes"]
    per_nome = {n.get("name", ""): i for i, n in enumerate(nodi)}
    padre_di = {}
    for i, n in enumerate(nodi):
        for c in n.get("children", []):
            padre_di[c] = i

    anim = g["animations"][0]
    tracce = {}  # nodo -> {"rotation": (tempi, valori)}
    for ch in anim["channels"]:
        if ch["target"]["path"] != "rotation":
            continue
        s = anim["samplers"][ch["sampler"]]
        tracce[ch["target"]["node"]] = (
            leggi(g, buf, s["input"]), leggi(g, buf, s["output"]))

    def rot_riposo(i):
        return qnorm(tuple(nodi[i].get("rotation", [0, 0, 0, 1])))

    def rot_a(i, t):
        if i in tracce:
            tempi, valori = tracce[i]
            return qnorm(campiona(tempi, valori, t))
        return rot_riposo(i)

    def globale(i, t, fn):
        q = fn(i)
        p = padre_di.get(i)
        while p is not None:
            q = qmul(fn(p), q)
            p = padre_di.get(p)
        return q

    n_frame = max(2, int(round((a - da) * fps)) + 1)
    fuori = {}
    for mix, gioco in MAPPA.items():
        if mix not in per_nome:
            continue
        i = per_nome[mix]
        riposo_inv = qconj(globale(i, 0.0, rot_riposo))
        seq = []
        for f in range(n_frame):
            t = da + (a - da) * f / (n_frame - 1)
            seq.append(qmul(globale(i, t, lambda k: rot_a(k, t)), riposo_inv))
        fuori[gioco] = seq

    # Da globale a locale nello spazio del gioco.
    locali = {}
    for gioco, seq in fuori.items():
        p = PADRE[gioco]
        if p is None or p not in fuori:
            locali[gioco] = seq
        else:
            locali[gioco] = [qmul(qconj(gp), q)
                             for gp, q in zip(fuori[p], seq)]

    # Si buttano gli ossi che praticamente non si muovono: meno dati,
    # e soprattutto le tracce vuote non sovrascrivono la posa di base.
    tenuti = {}
    for osso, seq in locali.items():
        massimo = max(2.0 * math.acos(min(1.0, abs(q[3]))) for q in seq)
        if massimo > math.radians(4.0):
            tenuti[osso] = seq
    return {"nome": nome, "durata": a - da, "fps": fps, "ossa": tenuti}


def gdscript(clip):
    righe = []
    for osso, seq in sorted(clip["ossa"].items()):
        numeri = ", ".join("%.4f, %.4f, %.4f, %.4f" % q for q in seq)
        righe.append('\t\t"%s": PackedFloat32Array([%s]),' % (osso, numeri))
    return ('\t"%s": {\n\t\t"durata": %.3f,\n\t\t"fps": %d,\n%s\n\t},'
            % (clip["nome"], clip["durata"], clip["fps"], "\n".join(righe)))


if __name__ == "__main__":
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument("gltf"); p.add_argument("nome")
    p.add_argument("da", type=float); p.add_argument("a", type=float)
    p.add_argument("--fps", type=int, default=24)
    ns = p.parse_args()
    c = estrai(ns.gltf, ns.da, ns.a, ns.fps, ns.nome)
    sys.stderr.write("%s: %d ossa, %.2fs, %d frame\n" % (
        ns.nome, len(c["ossa"]), c["durata"],
        int(round(c["durata"] * c["fps"])) + 1))
    print(gdscript(c))
