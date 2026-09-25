#!/usr/bin/env python3
"""I due passanti fermi, ricostruiti dalla sorgente.

**Perche' esiste questo file.** I due modelli erano stati convertiti a mano
e decimati "tanto sono comparse": `passante_b` e' passato da 2.434 a 1.100
triangoli, cioe' meno della meta'. Su una macchina la decimazione quadrica
si nota poco; su una PERSONA si nota subito, perche' l'occhio conosce la
forma a memoria. Il risultato era una signora fatta a coriandoli: le gambe
sparivano, la gonna si apriva in triangoli sospesi, la faccia si bucava.

Qui non si decima proprio. Duemilaquattrocento triangoli per un personaggio
fermo all'angolo sono niente — meno di una delle auto in sosta — e la
differenza fra "una persona" e "un ammasso di schegge" vale mille volte quel
mezzo migliaio di triangoli risparmiato.
"""
import io
import os
import subprocess
import sys
import tempfile
import zipfile

import numpy as np
import trimesh
from PIL import Image
from trimesh.visual.material import PBRMaterial

SRC = "/root/.claude/uploads/49ac95d1-b5fb-5d47-81ad-fe30c0296e44"
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                   "assets", "models")

# nome finale, zip sorgente, altezza vera in metri
PASSANTI = [
    ("passante_a.glb", "bb425b79-business_man.zip", 1.82),
    ("passante_b.glb", "575180fd-business_man_2.zip", 1.78),
]


def _estrai(zip_path, dove):
    with zipfile.ZipFile(zip_path) as z:
        z.extractall(dove)
    # Alcuni pacchetti hanno un secondo zip dentro a source/.
    for radice, _, files in os.walk(dove):
        for f in files:
            if f.lower().endswith(".zip"):
                with zipfile.ZipFile(os.path.join(radice, f)) as z2:
                    z2.extractall(os.path.join(radice, "dentro"))
    modello = None
    texture = None
    for radice, _, files in os.walk(dove):
        for f in files:
            p = os.path.join(radice, f)
            low = f.lower()
            if low.endswith((".obj", ".fbx", ".glb", ".gltf")) and modello is None:
                modello = p
            elif low.endswith((".png", ".jpg", ".jpeg")) and texture is None:
                texture = p
    return modello, texture


def _carica(path):
    if path.lower().endswith(".fbx"):
        conv = path + ".glb"
        subprocess.run(["assimp", "export", path, conv, "-ptv"],
                       check=True, capture_output=True)
        path = conv
    return trimesh.load(path, force="mesh")


def main():
    for nome, zip_name, alt in PASSANTI:
        with tempfile.TemporaryDirectory() as tmp:
            modello, texture = _estrai(os.path.join(SRC, zip_name), tmp)
            if modello is None:
                print(f"  {nome}: sorgente non trovata"); continue
            m = _carica(modello)
            # In piedi, faccia verso -Z (la convenzione dei rig del gioco).
            b = m.bounds
            h = b[1][1] - b[0][1]
            if h < max(b[1][0] - b[0][0], b[1][2] - b[0][2]):
                # Sdraiato: alcune sorgenti FBX escono con Z in alto.
                R = trimesh.transformations.rotation_matrix(-np.pi / 2, [1, 0, 0])
                m.apply_transform(R)
                b = m.bounds
                h = b[1][1] - b[0][1]
            S = np.eye(4) * (alt / h)
            S[3, 3] = 1.0
            m.apply_transform(S)
            b = m.bounds
            T = np.eye(4)
            T[:3, 3] = [-(b[0][0] + b[1][0]) / 2.0, -b[0][1],
                        -(b[0][2] + b[1][2]) / 2.0]
            m.apply_transform(T)

            uv = getattr(m.visual, "uv", None)
            if texture is not None and uv is not None:
                im = Image.open(texture).convert("RGBA")
                im.thumbnail((512, 512), Image.LANCZOS)
                buf = io.BytesIO()
                im.save(buf, format="PNG", optimize=True)
                buf.seek(0)
                m.visual = trimesh.visual.TextureVisuals(
                    uv=uv, material=PBRMaterial(
                        name="pelle_e_vestito", baseColorTexture=Image.open(buf),
                        baseColorFactor=[255, 255, 255, 255],
                        metallicFactor=0.0, roughnessFactor=0.9))
            sc = trimesh.Scene()
            sc.add_geometry(m, geom_name="corpo", node_name="corpo")
            dst = os.path.join(OUT, nome)
            sc.export(dst)
            e = m.extents
            print(f"  {nome:<18} tri={len(m.faces):<6} "
                  f"{e[0]:.2f} x {e[1]:.2f} x {e[2]:.2f} m  "
                  f"{os.path.getsize(dst)/1024:.0f} kB")


if __name__ == "__main__":
    sys.exit(main())
