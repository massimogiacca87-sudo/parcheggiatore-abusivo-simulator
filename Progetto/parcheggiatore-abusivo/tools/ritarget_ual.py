#!/usr/bin/env python3
"""Ritarget delle animazioni della Universal Animation Library sul rig del gioco.

Stessa matematica di `ritarget_mixamo.py` — si lavora in coordinate GLOBALI,
si toglie la posa di riposo della sorgente e si riporta nello spazio del
padre del gioco — con due differenze pratiche:

1. il file e' un **.glb** (binario, buffer incorporato) invece di un .gltf
   con il .bin di fianco;
2. dentro ci stanno **quarantatre** animazioni invece di una, e i nomi
   delle ossa sono quelli di Unreal (`pelvis`, `spine_01`, `thigh_l`...)
   invece di quelli di Mixamo.

Uso:
    python3 tools/ritarget_ual.py UAL1_Standard.glb Sitting_Idle_Loop seduto \
        --fps 18 --max 3.0
"""
import json, struct, sys, math, os

# Unreal -> gioco. La clavicola (`clavicle_l`) nel gioco non esiste: la sua
# rotazione viene assorbita dal calcolo in globale. Idem `spine_02`.
MAPPA = {
    "pelvis": "hips",
    "spine_01": "spine",
    "spine_03": "chest",
    "neck_01": "neck",
    "Head": "head",
    "upperarm_l": "shoulder_l",
    "lowerarm_l": "elbow_l",
    "hand_l": "hand_l",
    "upperarm_r": "shoulder_r",
    "lowerarm_r": "elbow_r",
    "hand_r": "hand_r",
    "thigh_l": "thigh_l",
    "calf_l": "knee_l",
    "foot_l": "foot_l",
    "thigh_r": "thigh_r",
    "calf_r": "knee_r",
    "foot_r": "foot_r",
}
PADRE = {
    "hips": None, "spine": "hips", "chest": "spine", "neck": "chest",
    "head": "neck",
    "shoulder_l": "chest", "elbow_l": "shoulder_l", "hand_l": "elbow_l",
    "shoulder_r": "chest", "elbow_r": "shoulder_r", "hand_r": "elbow_r",
    "thigh_l": "hips", "knee_l": "thigh_l", "foot_l": "knee_l",
    "thigh_r": "hips", "knee_r": "thigh_r", "foot_r": "knee_r",
}


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


def carica_glb(path):
    """Legge un .glb e ne ritorna (json, buffer binario)."""
    with open(path, "rb") as f:
        magic, ver, total = struct.unpack("<4sII", f.read(12))
        assert magic == b"glTF", "non e' un glb"
        g = None
        buf = b""
        while f.tell() < total:
            head = f.read(8)
            if len(head) < 8:
                break
            ln, tipo = struct.unpack("<II", head)
            dati = f.read(ln)
            if tipo == 0x4E4F534A:      # 'JSON'
                g = json.loads(dati)
            elif tipo == 0x004E4942:    # 'BIN\0'
                buf = dati
    return g, buf


def leggi(g, buf, idx):
    acc = g["accessors"][idx]
    bv = g["bufferViews"][acc["bufferView"]]
    off = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
    ncomp = {"SCALAR": 1, "VEC3": 3, "VEC4": 4}[acc["type"]]
    ct = acc["componentType"]
    assert ct == 5126, "solo float (trovato %d)" % ct
    vals = struct.unpack_from("<%df" % (acc["count"]*ncomp), buf, off)
    if ncomp == 1:
        return list(vals)
    return [vals[i*ncomp:(i+1)*ncomp] for i in range(acc["count"])]


def campiona(tempi, valori, t):
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


## Quanto e' alto il rig del gioco rispetto a quello della libreria. Il
## `pelvis` della UAL sta a 0,98 m in posa di riposo, il nostro a
## `Rig.HIP_Y` = 0,97: praticamente uguali, ma il fattore resta esplicito
## perche' se un giorno cambia l'altezza del rig si tocca solo qui.
SCALA_ALTEZZA = 1.0
## L'altezza dell'anca nel rig del gioco (Rig.HIP_Y).
HIP_Y = 0.97


def estrai(path, anim_nome, nome, fps=18, massimo=0.0, ciclica=False,
           scala_altezza=SCALA_ALTEZZA):
    g, buf = carica_glb(path)
    nodi = g["nodes"]
    per_nome = {n.get("name", ""): i for i, n in enumerate(nodi)}
    padre_di = {}
    for i, n in enumerate(nodi):
        for c in n.get("children", []):
            padre_di[c] = i

    anim = None
    for a in g["animations"]:
        if a.get("name") == anim_nome:
            anim = a
            break
    if anim is None:
        raise SystemExit("animazione '%s' non trovata" % anim_nome)

    tracce = {}
    t_max = 0.0
    for ch in anim["channels"]:
        if ch["target"]["path"] != "rotation":
            continue
        s = anim["samplers"][ch["sampler"]]
        tempi = leggi(g, buf, s["input"])
        tracce[ch["target"]["node"]] = (tempi, leggi(g, buf, s["output"]))
        t_max = max(t_max, tempi[-1])

    da, a_fin = 0.0, t_max
    if massimo > 0.0 and (a_fin - da) > massimo:
        a_fin = da + massimo

    def rot_riposo(i):
        return qnorm(tuple(nodi[i].get("rotation", [0, 0, 0, 1])))

    def rot_a(i, t):
        if i in tracce:
            tempi, valori = tracce[i]
            return qnorm(campiona(tempi, valori, t))
        return rot_riposo(i)

    def globale(i, fn):
        q = fn(i)
        p = padre_di.get(i)
        while p is not None:
            q = qmul(fn(p), q)
            p = padre_di.get(p)
        return q

    # --- 'A quota d''o bacino ------------------------------------------
    #
    # Le rotazioni da sole non bastano per una camminata: il bacino di uno
    # che cammina sale e scende due volte a passo, e senza quel saliscendi
    # il personaggio scivola invece di camminare. La traslazione del
    # `pelvis` sta nel file come qualunque altra traccia — si legge, si
    # toglie la posa di riposo, e si riscala sull'altezza del nostro rig.
    pos_tracce = {}
    for ch in anim["channels"]:
        if ch["target"]["path"] != "translation":
            continue
        s = anim["samplers"][ch["sampler"]]
        pos_tracce[ch["target"]["node"]] = (
            leggi(g, buf, s["input"]), leggi(g, buf, s["output"]))

    n_frame = max(2, int(round((a_fin - da) * fps)) + 1)
    fuori = {}
    for src, gioco in MAPPA.items():
        if src not in per_nome:
            continue
        i = per_nome[src]
        riposo_inv = qconj(globale(i, rot_riposo))
        seq = []
        for f in range(n_frame):
            t = da + (a_fin - da) * f / (n_frame - 1)
            seq.append(qmul(globale(i, lambda k: rot_a(k, t)), riposo_inv))
        # Una clip ciclica deve chiudere sul primo fotogramma, se no il
        # ritorno in loop e' uno scatto.
        if ciclica:
            seq[-1] = seq[0]
        fuori[gioco] = seq

    locali = {}
    for gioco, seq in fuori.items():
        p = PADRE[gioco]
        if p is None or p not in fuori:
            locali[gioco] = seq
        else:
            locali[gioco] = [qmul(qconj(gp), q)
                             for gp, q in zip(fuori[p], seq)]

    tenuti = {}
    for osso, seq in locali.items():
        massimo_ang = max(2.0 * math.acos(min(1.0, abs(q[3]))) for q in seq)
        if massimo_ang > math.radians(3.0):
            tenuti[osso] = seq

    # 'A quota d''o bacino, fotogramma pe' fotogramma.
    quote = []
    if "pelvis" in per_nome and per_nome["pelvis"] in pos_tracce:
        i = per_nome["pelvis"]
        tempi, valori = pos_tracce[i]
        # **La quota sta nella TERZA componente, non nella seconda.**
        #
        # Sembra un dettaglio e invece e' la differenza fra una camminata e
        # un personaggio che sprofonda nel marciapiede. Lo scheletro dentro
        # al file e' Z-up (convenzione Unreal) anche se il glTF e' Y-up: il
        # `pelvis` in posa di riposo sta a [0, 0.050, 0.917], e quel 0.917
        # e' l'altezza dell'anca. Misurato, non dedotto.
        riposo_h = nodi[i].get("translation", [0, 0, 0])[2]
        for f in range(n_frame):
            t = da + (a_fin - da) * f / (n_frame - 1)
            v = campiona(tempi, valori, t)
            # Si tiene lo SCOSTAMENTO dalla posa di riposo e lo si somma
            # alla quota del nostro rig: cosi' il saliscendi resta quello
            # vero della cattura e l'altezza resta la nostra.
            quote.append(HIP_Y + (v[2] - riposo_h) * scala_altezza)
        if ciclica and quote:
            quote[-1] = quote[0]
    return {"nome": nome, "durata": a_fin - da, "fps": fps, "ossa": tenuti,
            "quote": quote}


def gdscript(clip):
    righe = []
    q = clip.get("quote") or []
    if q:
        righe.append('\t\t"quote": PackedFloat32Array([%s]),'
                     % ", ".join("%.4f" % v for v in q))
    for osso, seq in sorted(clip["ossa"].items()):
        numeri = ", ".join("%.4f, %.4f, %.4f, %.4f" % qq for qq in seq)
        righe.append('\t\t"%s": PackedFloat32Array([%s]),' % (osso, numeri))
    return ('\t"%s": {\n\t\t"durata": %.3f,\n\t\t"fps": %d,\n%s\n\t},'
            % (clip["nome"], clip["durata"], clip["fps"], "\n".join(righe)))


if __name__ == "__main__":
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument("glb"); p.add_argument("anim"); p.add_argument("nome")
    p.add_argument("--fps", type=int, default=18)
    p.add_argument("--max", type=float, default=0.0)
    p.add_argument("--ciclica", action="store_true")
    p.add_argument("--lista", action="store_true")
    ns = p.parse_args()
    if ns.lista:
        g, _ = carica_glb(ns.glb)
        for a in g["animations"]:
            print(a.get("name"))
        raise SystemExit(0)
    c = estrai(ns.glb, ns.anim, ns.nome, ns.fps, ns.max, ns.ciclica)
    sys.stderr.write("%s: %d ossa, %.2fs, %d frame\n" % (
        ns.nome, len(c["ossa"]), c["durata"],
        int(round(c["durata"] * c["fps"])) + 1))
    print(gdscript(c))
