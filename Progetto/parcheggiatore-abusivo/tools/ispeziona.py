"""Guarda dentro a un modello e dice che ci sta.

Non serve a convertire niente: serve a decidere. Prima di questa passata i
modelli si aprivano a occhio in Godot e si scopriva a build fatta che uno
era storto, che un altro era da mezzo milione di triangoli e che un terzo
non aveva materiali. Qui si stampa tutto in una volta: nomi degli oggetti,
triangoli, misure, materiali, e se ci sono texture attaccate.

    /home/claude/blender/blender -b -P tools/ispeziona.py -- file1 file2 ...
"""
import sys
import os

import bpy


def pulisci():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def importa(path: str) -> bool:
    ext = os.path.splitext(path)[1].lower()
    try:
        if ext == ".fbx":
            bpy.ops.import_scene.fbx(filepath=path)
        elif ext in (".glb", ".gltf"):
            bpy.ops.import_scene.gltf(filepath=path)
        elif ext == ".obj":
            bpy.ops.wm.obj_import(filepath=path)
        elif ext == ".dae":
            bpy.ops.wm.collada_import(filepath=path)
        elif ext == ".blend":
            bpy.ops.wm.open_mainfile(filepath=path)
        elif ext in (".usd", ".usda", ".usdc", ".usdz"):
            bpy.ops.wm.usd_import(filepath=path)
        else:
            print("    formato non gestito:", ext)
            return False
    except Exception as e:  # noqa: BLE001
        print("    IMPORT FALLITO:", e)
        return False
    return True


def triangoli(ob) -> int:
    me = ob.data
    n = 0
    for p in me.polygons:
        n += max(1, len(p.vertices) - 2)
    return n


def guarda(path: str):
    print("=" * 74)
    print(path)
    pulisci()
    if not importa(path):
        return
    mesh = [o for o in bpy.data.objects if o.type == "MESH"]
    tot = sum(triangoli(o) for o in mesh)
    print("  oggetti mesh: %d   triangoli totali: %d" % (len(mesh), tot))
    # I materiali, con la texture attaccata se ce n'e' una.
    mats = {}
    for m in bpy.data.materials:
        img = ""
        if m.use_nodes:
            for n in m.node_tree.nodes:
                if n.type == "TEX_IMAGE" and n.image is not None:
                    img = n.image.name
                    break
        mats[m.name] = img
    print("  materiali (%d):" % len(mats))
    for k in sorted(mats)[:24]:
        print("      %-38s %s" % (k, mats[k] or "— nessuna texture"))
    if len(mats) > 24:
        print("      ... e altri %d" % (len(mats) - 24))
    # Gli oggetti, dal piu' grosso al piu' piccolo.
    righe = []
    for o in mesh:
        d = o.dimensions
        righe.append((triangoli(o), o.name, d.x, d.y, d.z))
    righe.sort(reverse=True)
    print("  oggetti:")
    for t, nome, dx, dy, dz in righe[:40]:
        print("      %7d tri  %-40s  %.2f x %.2f x %.2f" % (t, nome[:40], dx, dy, dz))
    if len(righe) > 40:
        print("      ... e altri %d oggetti" % (len(righe) - 40))


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    for p in args:
        guarda(p)
