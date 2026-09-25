#!/usr/bin/env python3
"""Pipeline di conversione modelli -> assets/models/*.glb

Estrae auto, barche e il Castel dell'Ovo dai pack scaricati, applica le
trasformazioni del grafo di scena, orienta (muso/prua verso -Z, alto +Y,
origine a terra al centro), scala in metri veri, decima entro budget e
assegna materiali con i nomi che models.gd riconosce.
"""
import os, sys, json, math
import numpy as np
import trimesh
from trimesh.visual.material import PBRMaterial
from PIL import Image

OUT = "/home/claude/parcheggiatore-abusivo/assets/models"
SRC_CARS = "/tmp/nuovi/glb/cars.glb"
SRC_BOATS = "/tmp/nuovi/glb/boats.glb"
SRC_FISH = "/tmp/nuovi/glb/fishing.glb"
SRC_SAIL = "/tmp/nuovi/sail_src2/Velero low poly/SailBoat.glb"
SRC_SAIL_TEX = "/tmp/nuovi/sail_src2/Velero low poly"
SRC_CAST = "/tmp/claude-0/-home-claude/49ac95d1-b5fb-5d47-81ad-fe30c0296e44/scratchpad/w/castello_ptv.glb"
SRC_CAST_TEX = "/tmp/nuovi/castel_src2/CAS/castello"

# colori piatti (albedo) per i materiali senza texture
COLORS = {
    "body":   (205, 205, 210),
    "glass":  ( 30,  38,  52),
    "wheel":  (145, 150, 158),
    "tire":   ( 26,  26,  30),
    "light":  (255, 232, 170),
    "vela":   (238, 238, 232),
    "asta":   (120, 122, 128),
    "sedile": (150, 110,  70),
    "barile": (120,  85,  55),
    "muro":   (198, 186, 165),
}


def load_instances(path):
    """Carica una scena applicando le matrici mondo del grafo (NON concatena
    alla cieca: trimesh.util.concatenate(scene.geometry.values()) ignora le
    trasformazioni e ammucchia tutto sull'origine)."""
    s = trimesh.load(path, process=False)
    if isinstance(s, trimesh.Trimesh):
        return [("mesh", s, None)]
    out = []
    for node in s.graph.nodes_geometry:
        T, gname = s.graph.get(node)
        geo = s.geometry[gname]
        if not isinstance(geo, trimesh.Trimesh) or len(geo.faces) == 0:
            continue
        m = geo.copy()
        m.apply_transform(T)
        mat = getattr(getattr(geo, "visual", None), "material", None)
        out.append((node, m, getattr(mat, "name", None)))
    return out


def ctr(m, ax):
    return (m.bounds[0][ax] + m.bounds[1][ax]) / 2.0


def decimate(mesh, target):
    """Riduce a <= target triangoli conservando la forma."""
    if len(mesh.faces) <= target or target < 4:
        return mesh
    try:
        r = mesh.simplify_quadric_decimation(face_count=int(target))
        if r is not None and len(r.faces) > 0:
            return r
    except Exception:
        pass
    try:
        import fast_simplification as fs
        v, f = fs.simplify(np.asarray(mesh.vertices, dtype=np.float32),
                           np.asarray(mesh.faces, dtype=np.int32),
                           target_reduction=1.0 - target / len(mesh.faces))
        return trimesh.Trimesh(vertices=v, faces=f, process=False)
    except Exception as e:
        print("   ! decimazione fallita:", e)
        return mesh


def flat_material(name, rgb=None):
    r, g, b = rgb if rgb is not None else COLORS.get(name, COLORS["body"])
    metal, rough = 0.0, 0.75
    if name == "glass":
        metal, rough = 0.9, 0.08
    elif name == "wheel":
        metal, rough = 0.85, 0.28
    elif name == "tire":
        rough = 0.95
    elif name == "body":
        metal, rough = 0.15, 0.42
    return PBRMaterial(name=name,
                       baseColorFactor=[r / 255, g / 255, b / 255, 1.0],
                       metallicFactor=metal, roughnessFactor=rough)


def detect_bow(meshes):
    """Restituisce il versore orizzontale che punta verso la prua/il muso.
    La prua e' l'estremita' dove lo scafo si restringe."""
    v = np.vstack([m.vertices for m in meshes])
    lo, hi = v.min(0), v.max(0)
    keep = v[:, 1] < lo[1] + 0.45 * (hi[1] - lo[1])   # solo lo scafo
    if keep.sum() > 50:
        v = v[keep]
    lo, hi = v.min(0), v.max(0)
    la = 0 if (hi[0] - lo[0]) >= (hi[2] - lo[2]) else 2   # asse lungo
    ca = 2 - la
    edges = np.linspace(lo[la], hi[la], 11)
    w = []
    for i in range(10):
        sel = v[(v[:, la] >= edges[i]) & (v[:, la] <= edges[i + 1])]
        w.append(np.ptp(sel[:, ca]) if len(sel) > 2 else np.nan)
    w = np.array(w)
    head = np.nanmean(w[:2])
    tail = np.nanmean(w[-2:])
    d = np.zeros(3)
    d[la] = -1.0 if head < tail else 1.0
    return d


def rot_y(deg):
    return trimesh.transformations.rotation_matrix(math.radians(deg), [0, 1, 0])


def rot_to_minus_z(direction):
    """Rotazione attorno a Y che porta `direction` (orizzontale) su -Z."""
    ang = math.degrees(math.atan2(direction[0], -direction[2]))  # 0 se gia' -Z
    return rot_y(ang)


def finalize(parts, out_name, budget, target_len=None, rot=None,
             auto_bow=True, scale=1.0, report=None):
    """parts: lista di (matname, mesh, texture_or_None[, (r,g,b)]).
    Orienta, scala, centra a terra, decima e scrive il .glb."""
    meshes = [p[1] for p in parts]

    if rot is None and auto_bow:
        rot = rot_to_minus_z(detect_bow(meshes))
    if rot is not None:
        for m in meshes:
            m.apply_transform(rot)

    # ---- budget triangoli, distribuito per gruppo ----
    tot = sum(len(m.faces) for m in meshes)
    if tot > budget:
        # i gruppi "piccoli" (vetri, fari) restano; il resto scala in proporzione
        small = [i for i, m in enumerate(meshes) if len(m.faces) <= 80]
        fixed = sum(len(meshes[i].faces) for i in small)
        big = [i for i in range(len(meshes)) if i not in small]
        room = max(budget - fixed, 40)
        bigtot = sum(len(meshes[i].faces) for i in big) or 1
        for i in big:
            tgt = max(24, int(round(len(meshes[i].faces) * room / bigtot)))
            meshes[i] = decimate(meshes[i], tgt)
    # rifinitura: se ancora sopra, taglia il gruppo piu' grosso
    guard = 0
    while sum(len(m.faces) for m in meshes) > budget and guard < 12:
        i = int(np.argmax([len(m.faces) for m in meshes]))
        over = sum(len(m.faces) for m in meshes) - budget
        meshes[i] = decimate(meshes[i], max(24, len(meshes[i].faces) - over - 8))
        guard += 1

    allm = trimesh.util.concatenate([m.copy() for m in meshes])
    if target_len is not None:
        cur = allm.bounds[1][2] - allm.bounds[0][2]
        scale = target_len / cur
    if abs(scale - 1.0) > 1e-9:
        S = np.eye(4) * scale
        S[3, 3] = 1.0
        for m in meshes:
            m.apply_transform(S)
        allm = trimesh.util.concatenate([m.copy() for m in meshes])

    # origine: a terra, centrata sull'ingombro orizzontale
    b = allm.bounds
    off = np.array([-(b[0][0] + b[1][0]) / 2.0, -b[0][1], -(b[0][2] + b[1][2]) / 2.0])
    T = np.eye(4)
    T[:3, 3] = off
    for m in meshes:
        m.apply_transform(T)

    # ---- scena finale ----
    scene = trimesh.Scene()
    used = {}
    for p, m in zip(parts, meshes):
        matname, tex = p[0], p[2]
        rgb = p[3] if len(p) > 3 else None
        if len(m.faces) == 0:
            continue
        if tex is not None:
            uv = getattr(m.visual, "uv", None)
            m.visual = trimesh.visual.TextureVisuals(
                uv=uv, material=PBRMaterial(name=matname,
                                            baseColorTexture=tex,
                                            baseColorFactor=[255, 255, 255, 255],
                                            metallicFactor=0.0,
                                            roughnessFactor=0.85))
        else:
            m.visual = trimesh.visual.TextureVisuals(
                material=flat_material(matname, rgb))
        used[matname] = used.get(matname, 0) + 1
        scene.add_geometry(m, geom_name=f"{matname}_{used[matname]}",
                           node_name=f"{matname}_{used[matname]}")

    path = os.path.join(OUT, out_name)
    scene.export(path)
    fin = trimesh.util.concatenate([m.copy() for m in meshes])
    b = fin.bounds
    size = b[1] - b[0]
    info = dict(file=out_name, tri=int(sum(len(m.faces) for m in meshes)),
                L=round(float(size[0]), 2), A=round(float(size[1]), 2),
                P=round(float(size[2]), 2), ymin=round(float(b[0][1]), 4),
                kb=round(os.path.getsize(path) / 1024.0, 1))
    print(f"  {out_name:<22} tri={info['tri']:<6} "
          f"{info['L']:>6.2f} x {info['A']:>6.2f} x {info['P']:>6.2f} m  "
          f"ymin={info['ymin']:+.4f}  {info['kb']:>7.1f} kB")
    if report is not None:
        report.append(info)
    return info


def tex(path, size=512, quality=88, keep_alpha=False):
    im = Image.open(path)
    if not keep_alpha:
        im = im.convert("RGB")
    im.thumbnail((size, size), Image.LANCZOS)
    import io
    buf = io.BytesIO()
    if keep_alpha:
        im.save(buf, format="PNG", optimize=True)
    else:
        im.save(buf, format="JPEG", quality=quality, optimize=True)
    buf.seek(0)
    return Image.open(buf)
