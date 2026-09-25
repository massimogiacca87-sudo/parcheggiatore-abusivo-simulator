"""napoli.py — la cassetta degli attrezzi per modellare la roba del gioco.

## Perché non si usa `bpy.ops`

Blender qui gira come **modulo Python** (`import bpy`), non come programma
con la finestra aperta. In quella modalità gli operatori che dipendono dal
contesto — `object.join`, `object.transform_apply`, tutto quello che agisce
sulla "selezione" — non hanno un contesto vero da cui leggere, e Blender
non se ne lamenta: **crasha con un segmentation fault**. L'ho scoperto al
terzo script.

Quindi qui dentro non si tocca `bpy.ops` se non per esportare. Si costruisce
tutto con **bmesh**, che è l'API di basso livello: si creano vertici e
facce, si smussa, si suddivide, e alla fine si scrive la mesh. Un oggetto
solo, una mesh sola, nessuna selezione da gestire.

## Gli assi

Blender lavora con **Z in alto**. glTF (e quindi Godot) vuole **Y in alto**,
e l'esportatore converte da sé. La regola che tengo in tutti i modelli:

    Blender  +Z  →  Godot  +Y   (su)
    Blender  +Y  →  Godot  -Z   (avanti: -Z è l'avanti di Godot)
    Blender  +X  →  Godot  +X   (destra)

Cioè: **si modella guardando verso +Y**, con l'origine appoggiata a terra
al centro dell'ingombro (o dove serve montarlo, per la roba che si indossa).

Misurato, non dedotto: un modello con una punta lunga verso Blender -Y
esce in Godot con la punta a +Z. Quindi il muso va verso +Y in Blender.

## Le misure

Sempre in metri veri. Una coppola è larga 28 cm perché una coppola è larga
28 cm: se le misure sono vere, il modello si innesta nel gioco senza
doverlo riscalare a occhio, e sta insieme al resto senza sembrare un
giocattolo.
"""

import bpy
import bmesh
import math
from mathutils import Vector, Matrix, Euler


# ---------------------------------------------------------------------------
# Scena e materiali
# ---------------------------------------------------------------------------

def nuova_scena():
    """Svuota tutto. Si chiama UNA volta, all'inizio dello script.

    Attenzione: `read_factory_settings` cancella anche i materiali già
    creati, e le variabili Python che li puntavano restano lì come
    riferimenti morti (`StructRNA has been removed`). Per questo la cache
    dei materiali si svuota insieme alla scena.
    """
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _MATERIALI.clear()


_MATERIALI = {}


def materiale(nome, colore, ruvidezza=0.75, metallico=0.0, emissione=None,
              alpha=1.0):
    """Un materiale PBR semplice. glTF esporta base color, metallic,
    roughness ed emission: tutto quello che serve, e Godot li legge.

    `colore` è (r, g, b) in 0..1 — **sRGB**, cioè il colore come lo vedi,
    non lineare.
    """
    chiave = (nome, colore, ruvidezza, metallico, emissione, alpha)
    if chiave in _MATERIALI:
        return _MATERIALI[chiave]
    m = bpy.data.materials.new(nome)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (colore[0], colore[1],
                                               colore[2], alpha)
    bsdf.inputs["Roughness"].default_value = ruvidezza
    bsdf.inputs["Metallic"].default_value = metallico
    if emissione is not None:
        bsdf.inputs["Emission Color"].default_value = (
            emissione[0], emissione[1], emissione[2], 1.0)
        bsdf.inputs["Emission Strength"].default_value = 1.0
    if alpha < 1.0:
        m.blend_method = 'BLEND'
    _MATERIALI[chiave] = m
    return m


# ---------------------------------------------------------------------------
# Pezzi: ognuno ritorna un bmesh nuovo, già nel posto giusto
# ---------------------------------------------------------------------------

def _bm():
    return bmesh.new()


def cubo(dim=(1, 1, 1), pos=(0, 0, 0), rot=(0, 0, 0)):
    bm = _bm()
    bmesh.ops.create_cube(bm, size=1.0)
    _piazza(bm, dim, pos, rot)
    return bm


def cilindro(raggio=0.5, altezza=1.0, lati=16, pos=(0, 0, 0), rot=(0, 0, 0),
             chiuso=True, raggio2=None):
    """Cilindro con l'asse su Z. `raggio2` diverso = tronco di cono."""
    bm = _bm()
    bmesh.ops.create_cone(bm, cap_ends=chiuso, cap_tris=False,
                          segments=lati,
                          radius1=raggio,
                          radius2=raggio if raggio2 is None else raggio2,
                          depth=altezza)
    _piazza(bm, (1, 1, 1), pos, rot)
    return bm


def sfera(raggio=0.5, suddivisioni=3, pos=(0, 0, 0), scala=(1, 1, 1)):
    bm = _bm()
    bmesh.ops.create_icosphere(bm, subdivisions=suddivisioni, radius=raggio)
    _piazza(bm, scala, pos, (0, 0, 0))
    return bm


def uvsfera(raggio=0.5, seg=16, anelli=8, pos=(0, 0, 0), scala=(1, 1, 1)):
    bm = _bm()
    bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=anelli,
                              radius=raggio)
    _piazza(bm, scala, pos, (0, 0, 0))
    return bm


def toro(raggio=0.5, spessore=0.1, seg=20, lati=10, pos=(0, 0, 0),
         rot=(0, 0, 0)):
    """Un anello. Blender non ha un create_torus in bmesh.ops: si fa a mano
    ruotando un cerchietto lungo il giro, che è poi cosa fa lui."""
    bm = _bm()
    verts = []
    for i in range(seg):
        a = 2 * math.pi * i / seg
        anello = []
        for j in range(lati):
            b = 2 * math.pi * j / lati
            r = raggio + spessore * math.cos(b)
            anello.append(bm.verts.new((r * math.cos(a), r * math.sin(a),
                                        spessore * math.sin(b))))
        verts.append(anello)
    for i in range(seg):
        i2 = (i + 1) % seg
        for j in range(lati):
            j2 = (j + 1) % lati
            bm.faces.new((verts[i][j], verts[i2][j], verts[i2][j2],
                          verts[i][j2]))
    bm.normal_update()
    _piazza(bm, (1, 1, 1), pos, rot)
    return bm


def tubo(punti, raggio=0.02, lati=8, chiudi=True):
    """Un tubo che segue una spezzata nello spazio.

    E' l'attrezzo piu' usato di tutti: telai di sedie, stecche, ringhiere,
    manici, corrimano, tubi del gas sulle facciate. Prima li facevo a
    cilindri separati e si vedeva — un telaio fatto di quattro cilindri che
    si toccano agli angoli ha i buchi negli angoli, e da vicino sembra
    smontato.

    Il trasporto della sezione usa un "vettore su" fisso invece del frame
    di Frenet: sui tubi da piazza (che non si avvitano su se stessi) e'
    identico e non degenera nei tratti dritti.
    """
    bm = _bm()
    P = [Vector(p) for p in punti]
    if len(P) < 2:
        return bm
    anelli = []
    for i, p in enumerate(P):
        if i == 0:
            d = (P[1] - P[0])
        elif i == len(P) - 1:
            d = (P[-1] - P[-2])
        else:
            d = (P[i + 1] - P[i - 1])
        d.normalize()
        su = Vector((0, 0, 1))
        if abs(d.dot(su)) > 0.97:
            su = Vector((0, 1, 0))
        a = d.cross(su).normalized()
        b = d.cross(a).normalized()
        anello = []
        for k in range(lati):
            t = 2 * math.pi * k / lati
            anello.append(bm.verts.new(
                p + a * (raggio * math.cos(t)) + b * (raggio * math.sin(t))))
        anelli.append(anello)
    for i in range(len(anelli) - 1):
        for k in range(lati):
            k2 = (k + 1) % lati
            bm.faces.new((anelli[i][k], anelli[i + 1][k],
                          anelli[i + 1][k2], anelli[i][k2]))
    if chiudi:
        bm.faces.new(list(reversed(anelli[0])))
        bm.faces.new(anelli[-1])
    bm.normal_update()
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    return bm


def piano(dim=(1, 1), pos=(0, 0, 0), rot=(0, 0, 0)):
    bm = _bm()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=0.5)
    _piazza(bm, (dim[0], dim[1], 1), pos, rot)
    return bm


def profilo(punti, spessore, pos=(0, 0, 0), rot=(0, 0, 0)):
    """Estrude un profilo chiuso (lista di (x, z)) lungo Y. Serve per le
    cose che hanno una sagoma di lato: la sedia sdraio, la paletta, il
    cornicione di un palazzo."""
    bm = _bm()
    a = [bm.verts.new((p[0], -spessore / 2.0, p[1])) for p in punti]
    b = [bm.verts.new((p[0], spessore / 2.0, p[1])) for p in punti]
    bm.faces.new(a)
    bm.faces.new(list(reversed(b)))
    n = len(punti)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((a[i], a[j], b[j], b[i]))
    bm.normal_update()
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    _piazza(bm, (1, 1, 1), pos, rot)
    return bm


def _piazza(bm, dim, pos, rot):
    m = Matrix.Translation(Vector(pos)) @ \
        Euler((math.radians(rot[0]), math.radians(rot[1]),
               math.radians(rot[2])), 'XYZ').to_matrix().to_4x4() @ \
        Matrix.Diagonal(Vector((dim[0], dim[1], dim[2], 1.0)))
    bmesh.ops.transform(bm, matrix=m, verts=bm.verts[:])


# ---------------------------------------------------------------------------
# Rifiniture
# ---------------------------------------------------------------------------

def smussa(bm, misura=0.01, segmenti=2, solo_spigoli=True, angolo=30.0):
    """Lo smusso è la differenza fra "un cubo" e "un oggetto". Un bordo
    perfettamente vivo non esiste in natura e la luce non ci si aggrappa:
    due millimetri di smusso su una scatola la fanno leggere come una cosa
    costruita invece che come una primitiva."""
    spigoli = bm.edges[:]
    if solo_spigoli:
        soglia = math.radians(angolo)
        spigoli = [e for e in bm.edges if e.is_manifold
                   and e.calc_face_angle(0.0) > soglia]
    if not spigoli:
        return bm
    bmesh.ops.bevel(bm, geom=spigoli, offset=misura, segments=segmenti,
                    profile=0.5, affect='EDGES', clamp_overlap=True)
    return bm


def suddividi(bm, tagli=1, morbido=True):
    """Suddivide e ammorbidisce: è il Catmull-Clark del modificatore
    Subdivision, ma applicato subito e senza modificatori (che vorrebbero
    un oggetto vero e un depsgraph)."""
    for _ in range(tagli):
        bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=1,
                                  use_grid_fill=True,
                                  smooth=1.0 if morbido else 0.0)
    return bm


def morbido(bm, angolo=40.0):
    """Segna le facce come lisce sopra a un certo angolo: le curve
    diventano curve invece che sfaccettature."""
    soglia = math.cos(math.radians(angolo))
    for f in bm.faces:
        vicini = [e.link_faces for e in f.edges]
        liscia = True
        for coppie in vicini:
            for g in coppie:
                if g is f:
                    continue
                if f.normal.dot(g.normal) < soglia:
                    liscia = False
        f.smooth = liscia
    return bm


def tutto_morbido(bm):
    for f in bm.faces:
        f.smooth = True
    return bm


def scala_a_misura(bm, larghezza=None, altezza=None, lunghezza=None):
    """Riscala uniformemente perché una delle tre misure sia quella data.
    Serve alla fine, quando il modello è fatto e va portato alla taglia
    vera senza rifare i conti su ogni pezzo."""
    mn, mx = ingombro(bm)
    dim = (mx[0] - mn[0], mx[1] - mn[1], mx[2] - mn[2])
    k = 1.0
    if larghezza and dim[0] > 1e-6:
        k = larghezza / dim[0]
    elif lunghezza and dim[1] > 1e-6:
        k = lunghezza / dim[1]
    elif altezza and dim[2] > 1e-6:
        k = altezza / dim[2]
    bmesh.ops.scale(bm, vec=Vector((k, k, k)), verts=bm.verts[:])
    return bm


def appoggia(bm, z=0.0):
    """Porta il punto più basso a `z` e centra su X e Y. È la posa che il
    gioco si aspetta: origine a terra, al centro dell'ingombro."""
    mn, mx = ingombro(bm)
    dx = -(mn[0] + mx[0]) / 2.0
    dy = -(mn[1] + mx[1]) / 2.0
    dz = z - mn[2]
    bmesh.ops.translate(bm, vec=Vector((dx, dy, dz)), verts=bm.verts[:])
    return bm


def ingombro(bm):
    xs = [v.co.x for v in bm.verts]
    ys = [v.co.y for v in bm.verts]
    zs = [v.co.z for v in bm.verts]
    return (min(xs), min(ys), min(zs)), (max(xs), max(ys), max(zs))


# ---------------------------------------------------------------------------
# Montaggio ed export
# ---------------------------------------------------------------------------

class Modello:
    """Un modello è una lista di (bmesh, materiale). Si tiene tutto
    separato fino all'ultimo momento: ogni pezzo ha il suo materiale, e in
    export diventa una mesh sola con più superfici — che è esattamente
    quello che Godot si aspetta, e che gli permette di ritingere solo la
    carrozzeria lasciando stare i vetri."""

    def __init__(self, nome):
        self.nome = nome
        self.pezzi = []

    def add(self, bm, mat):
        self.pezzi.append((bm, mat))
        return self

    def tutti(self):
        return [p[0] for p in self.pezzi]

    def scala(self, k):
        for bm, _ in self.pezzi:
            bmesh.ops.scale(bm, vec=Vector((k, k, k)), verts=bm.verts[:])
        return self

    def ingombro(self):
        mn = [1e9, 1e9, 1e9]
        mx = [-1e9, -1e9, -1e9]
        for bm, _ in self.pezzi:
            a, b = ingombro(bm)
            for i in range(3):
                mn[i] = min(mn[i], a[i])
                mx[i] = max(mx[i], b[i])
        return tuple(mn), tuple(mx)

    def porta_a(self, larghezza=None, altezza=None, lunghezza=None):
        mn, mx = self.ingombro()
        dim = (mx[0] - mn[0], mx[1] - mn[1], mx[2] - mn[2])
        k = 1.0
        if larghezza and dim[0] > 1e-6:
            k = larghezza / dim[0]
        elif lunghezza and dim[1] > 1e-6:
            k = lunghezza / dim[1]
        elif altezza and dim[2] > 1e-6:
            k = altezza / dim[2]
        return self.scala(k)

    def appoggia(self, z=0.0, centra=True):
        mn, mx = self.ingombro()
        dx = -(mn[0] + mx[0]) / 2.0 if centra else 0.0
        dy = -(mn[1] + mx[1]) / 2.0 if centra else 0.0
        dz = z - mn[2]
        for bm, _ in self.pezzi:
            bmesh.ops.translate(bm, vec=Vector((dx, dy, dz)),
                                verts=bm.verts[:])
        return self

    def sposta(self, v):
        for bm, _ in self.pezzi:
            bmesh.ops.translate(bm, vec=Vector(v), verts=bm.verts[:])
        return self


def esporta(modello, percorso):
    """Scrive il .glb. Una mesh, una superficie per materiale.

    NON svuota la scena: cancellerebbe i materiali che il modello sta
    usando. Chi chiama fa `nuova_scena()` una volta sola all'inizio; qui
    si toglie solo l'oggetto precedente, se c'e'.
    """
    for o in list(bpy.context.scene.collection.objects):
        bpy.context.scene.collection.objects.unlink(o)
    mesh = bpy.data.meshes.new(modello.nome)
    ob = bpy.data.objects.new(modello.nome, mesh)
    bpy.context.scene.collection.objects.link(ob)

    unione = bmesh.new()
    indici = {}
    for bm, mat in modello.pezzi:
        if mat.name not in indici:
            indici[mat.name] = len(ob.data.materials)
            ob.data.materials.append(mat)
        idx = indici[mat.name]
        # Si copia il pezzo dentro all'unione tenendosi il materiale.
        tmp = bpy.data.meshes.new("_tmp")
        bm.to_mesh(tmp)
        for p in tmp.polygons:
            p.material_index = idx
        unione.from_mesh(tmp)
        bpy.data.meshes.remove(tmp)
    bmesh.ops.remove_doubles(unione, verts=unione.verts[:], dist=0.0001)
    unione.normal_update()
    unione.to_mesh(mesh)
    unione.free()

    bpy.ops.export_scene.gltf(filepath=percorso, export_format='GLB',
                              export_apply=False, export_yup=True,
                              export_materials='EXPORT')
    tri = sum(len(p.vertices) - 2 for p in mesh.polygons)
    return {"file": percorso, "vertici": len(mesh.vertices),
            "triangoli": tri, "materiali": len(mesh.materials)}
