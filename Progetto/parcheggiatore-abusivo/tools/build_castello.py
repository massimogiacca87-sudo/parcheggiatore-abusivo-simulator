#!/usr/bin/env python3
"""Castel dell'Ovo: dal .dae di SketchUp al .glb con texture."""
import sys, os, json, subprocess
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np, trimesh
from build_models import load_instances, finalize, rot_y, tex, OUT, SRC_CAST, SRC_CAST_TEX

BUDGET = 9000
DAE = "/tmp/nuovi/castel_src2/CAS/castello.dae"
# il .dae di SketchUp arriva dentro CAS.rar: p7zip non sa scompattarlo
# ("Unsupported Method"), ci vuole unar. Qui lo si ripassa ad assimp con
# -ptv, che applica le trasformazioni del grafo e l'unita' di misura.
if not os.path.exists(SRC_CAST) and os.path.exists(DAE):
    subprocess.run(["assimp", "export", DAE, SRC_CAST, "-ptv"], check=True,
                   stdout=subprocess.DEVNULL)
inst = load_instances(SRC_CAST)
main = max(inst, key=lambda t: len(t[1].faces))[1]
print("mesh principale:", len(main.faces), "tri")

# asse lungo dell'isolotto su Z, con il pontile (lato terra) verso +Z
main.apply_transform(rot_y(-(42.3 + 180.0)))

# via il pontile di collegamento e lo sperone piatto in coda: resta il monumento
vz = main.vertices[main.faces][:, :, 2]          # tutti i vertici del triangolo
keep = np.where((vz.min(axis=1) > -46.0) & (vz.max(axis=1) < 179.0))[0]
main = main.submesh([keep], append=True)
print("dopo il taglio:", len(main.faces), "tri  uv:",
      None if main.visual.uv is None else main.visual.uv.shape)

texture = tex(os.path.join(SRC_CAST_TEX, "material_2.png"), 512, 88)
report = []
# budget alto: la decimazione la fa gltf-transform, che conserva le UV
finalize([("castello_muro", main, texture)], "castel_dellovo.glb",
         budget=10 ** 9, rot=None, auto_bow=False, scale=1.0, report=report)

path = os.path.join(OUT, "castel_dellovo.glb")
n = report[0]["tri"]
if n > BUDGET:
    ratio = 1.0 - BUDGET / float(n)
    tmp = "/tmp/cast_simpl.glb"
    subprocess.run(["gltf-transform", "weld", path, tmp], check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run(["gltf-transform", "simplify", tmp, path,
                    "--ratio", str(round(1.0 - ratio, 4)), "--error", "0.004",
                    "--lock-border", "false"], check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

m = trimesh.load(path, process=False)
tot = trimesh.util.concatenate([g for g in m.geometry.values()]) if hasattr(m, "geometry") else m
b = tot.bounds
sz = b[1] - b[0]
print(f"  castel_dellovo.glb     tri={len(tot.faces):<6} "
      f"{sz[0]:.2f} x {sz[1]:.2f} x {sz[2]:.2f} m  ymin={b[0][1]:+.4f}  "
      f"{os.path.getsize(path)/1024:.1f} kB")
