"""Rende un provino di un .glb, per guardarselo senza aprire il gioco.

Cycles su CPU con pochi campioni: su un modello da duemila triangoli sono
pochi secondi, e bastano per accorgersi che una gamba e' storta o che un
materiale e' venuto nero. EEVEE non si puo' usare — in Blender 4.2 vuole
una GPU, e qui non c'e'.
"""

import sys
import os
import math

import bpy
from mathutils import Vector


def _pulisci():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def _ingombro():
    mn = Vector((1e9, 1e9, 1e9))
    mx = Vector((-1e9, -1e9, -1e9))
    for o in bpy.context.scene.objects:
        if o.type != 'MESH':
            continue
        for v in o.bound_box:
            p = o.matrix_world @ Vector(v)
            for i in range(3):
                mn[i] = min(mn[i], p[i])
                mx[i] = max(mx[i], p[i])
    return mn, mx


def provino(glb, png, larghezza=560, altezza=460, campioni=24,
            angolo=38.0, alzo=24.0):
    _pulisci()
    bpy.ops.import_scene.gltf(filepath=glb)

    mn, mx = _ingombro()
    centro = (mn + mx) / 2.0
    raggio = max((mx - mn).length / 2.0, 0.15)

    scn = bpy.context.scene
    scn.render.engine = 'CYCLES'
    scn.cycles.device = 'CPU'
    scn.cycles.samples = campioni
    scn.cycles.use_denoising = True
    scn.render.resolution_x = larghezza
    scn.render.resolution_y = altezza
    scn.render.filepath = png
    scn.render.image_settings.file_format = 'PNG'
    scn.render.film_transparent = False

    # Fondo grigio chiaro, cosi' si vedono sia i pezzi scuri sia quelli
    # chiari (su bianco spariva la tela crema, su nero il ferro).
    mondo = bpy.data.worlds.new("W")
    scn.world = mondo
    mondo.use_nodes = True
    mondo.node_tree.nodes["Background"].inputs[0].default_value = (
        0.42, 0.44, 0.48, 1.0)
    mondo.node_tree.nodes["Background"].inputs[1].default_value = 1.1

    # Un piano d'appoggio: senza, gli oggetti galleggiano e non si capisce
    # dove sta il terreno. Fatto a mano e non con `primitive_plane_add`:
    # quell'operatore vuole un contesto vero e in modalita' modulo fa
    # saltare Blender con un segmentation fault.
    import bmesh
    bmp = bmesh.new()
    lato = raggio * 6
    vs = [bmp.verts.new(p) for p in [
        (centro.x - lato, centro.y - lato, mn.z - 0.001),
        (centro.x + lato, centro.y - lato, mn.z - 0.001),
        (centro.x + lato, centro.y + lato, mn.z - 0.001),
        (centro.x - lato, centro.y + lato, mn.z - 0.001)]]
    bmp.faces.new(vs)
    bmp.normal_update()
    mp = bpy.data.meshes.new("pavimento")
    bmp.to_mesh(mp)
    bmp.free()
    scn.collection.objects.link(bpy.data.objects.new("pavimento", mp))

    # Tre luci: chiave, riempimento e controluce. Con una sola, meta'
    # modello resta in ombra piena e non si giudica niente.
    for pos, energia, dim in (
            ((raggio * 3.4, -raggio * 3.0, raggio * 3.4), 900, raggio * 2),
            ((-raggio * 3.6, -raggio * 1.6, raggio * 1.6), 260, raggio * 3),
            ((0, raggio * 4.0, raggio * 2.4), 400, raggio * 2)):
        luce = bpy.data.lights.new("L", 'AREA')
        luce.energy = energia * max(raggio, 0.4) ** 2
        luce.size = dim
        ob = bpy.data.objects.new("L", luce)
        ob.location = centro + Vector(pos)
        d = (centro - ob.location).normalized()
        ob.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
        scn.collection.objects.link(ob)

    cam = bpy.data.cameras.new("C")
    cam.lens = 62
    camob = bpy.data.objects.new("C", cam)
    a = math.radians(angolo)
    e = math.radians(alzo)
    dist = raggio * 3.1
    camob.location = centro + Vector((
        dist * math.cos(e) * math.sin(a),
        -dist * math.cos(e) * math.cos(a),
        dist * math.sin(e)))
    d = (centro - camob.location).normalized()
    camob.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
    scn.collection.objects.link(camob)
    scn.camera = camob

    bpy.ops.render.render(write_still=True)
    return png


if __name__ == "__main__":
    for g in sys.argv[1:]:
        nome = os.path.splitext(os.path.basename(g))[0]
        provino(g, "/tmp/prov_%s.png" % nome)
        print("fatto", nome)
