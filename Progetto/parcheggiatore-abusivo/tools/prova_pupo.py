"""Rende 'o pupo 'a quatto late, pe' vedé si è fatto buono.

    python3 tools/prova_pupo.py [corpo_normale] [/tmp/pupo]
"""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy
from mathutils import Vector

QUALE = sys.argv[1] if len(sys.argv) > 1 else "corpo_normale"
BASE = sys.argv[2] if len(sys.argv) > 2 else "/tmp/pupo"
GLB = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                   "assets", "models", "pupo.glb")

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=GLB)
for o in list(bpy.data.objects):
    if o.type == 'MESH' and o.name not in (QUALE, "capelli", "baffi"):
        bpy.data.objects.remove(o, do_unlink=True)

sc = bpy.context.scene
sc.render.engine = 'BLENDER_EEVEE_NEXT'
sc.render.resolution_x, sc.render.resolution_y = 620, 900
sc.render.film_transparent = False
sc.world = bpy.data.worlds.new("w")
sc.world.use_nodes = True
sc.world.node_tree.nodes["Background"].inputs[0].default_value = (.55,.57,.60,1)
sc.world.node_tree.nodes["Background"].inputs[1].default_value = 1.1

sole = bpy.data.objects.new("sole", bpy.data.lights.new("sole", 'SUN'))
sole.data.energy = 3.2
sole.rotation_euler = (math.radians(52), 0, math.radians(38))
sc.collection.objects.link(sole)

cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cam.data.lens = 62
sc.collection.objects.link(cam)
sc.camera = cam
mira = Vector((0, 0, 0.95))

VISTE = [("fronte", 0), ("tre_quarti", 35), ("fianco", 90)]
for nome, gradi in VISTE:
    a = math.radians(gradi)
    d = 3.15
    cam.location = mira + Vector((math.sin(a)*d, -math.cos(a)*d, 0.42))
    dirz = (cam.location - mira).normalized()
    cam.rotation_euler = dirz.to_track_quat('Z', 'Y').to_euler()
    sc.render.filepath = "%s_%s.png" % (BASE, nome)
    bpy.ops.render.render(write_still=True)
    print("  ->", sc.render.filepath)
