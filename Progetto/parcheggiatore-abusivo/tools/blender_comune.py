"""Gli attrezzi comuni per portare un modello comprato dentro al gioco.

**Perché sta tutto qui.** Ogni pacchetto scaricato arriva con gli stessi
quattro problemi, sempre: è girato dalla parte sbagliata, non è in metri,
l'origine sta a caso, e i materiali si chiamano `Material.047`. Fino alla
0.45 ogni script di conversione se li risolveva per conto suo, e infatti
ognuno li risolveva in modo un po' diverso — la BMW è uscita bianca e senza
normali proprio così.

**Le regole del gioco**, che sono l'unica cosa che questi attrezzi
impongono:

- **Asse.** Godot è Y-su, Z-avanti negativo: `forward(θ) = (−sinθ, 0, −cosθ)`.
  Un veicolo deve avere il muso verso **−Z** e stare in piedi su **+Y**.
- **Origine.** A terra, al centro dell'impronta. Se l'origine sta in mezzo
  alla scocca, l'auto affonda nell'asfalto per mezzo metro.
- **Materiali.** `Models.polish_vehicle` e `Models.tint` riconoscono i
  materiali **dal nome**: body/carroz/scocca per la vernice, glass/window/
  vetro per i vetri, chrom/mirror/wheel/cerchi per le cromature, tire/gomm/
  rubber per le gomme, light/faro/lamp per i fari. Un materiale che si
  chiama `Material.047` non lo tocca nessuno, e resta grigio.

**Le trappole di Blender come modulo** (imparate a caro prezzo): gli
operatori che dipendono dal contesto — `object.join`, `transform_apply`,
`modifier_apply` — vanno in segfault. Qui non se ne usa nessuno: si
lavora sui dati (`bmesh`, matrici, `bpy.data.objects.remove`) e i
modificatori li applica l'esportatore glTF con `export_apply=True`.
"""
import math
import os
import re

import bpy
import bmesh
from mathutils import Matrix, Vector


# ---------------------------------------------------------------------------
# Aprire
# ---------------------------------------------------------------------------

def pulisci():
    """Scena vuota. Da chiamare prima di ogni modello."""
    bpy.ops.wm.read_factory_settings(use_empty=True)


def importa(path: str):
    ext = os.path.splitext(path)[1].lower()
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
    elif ext == ".3ds":
        # In Blender 4.2 l'importatore 3DS è tornato, ma sotto un nome
        # nuovo. Si prova quello e si ripiega sul vecchio.
        if hasattr(bpy.ops.import_scene, "max3ds"):
            bpy.ops.import_scene.max3ds(filepath=path)
        else:
            bpy.ops.import_scene.autodesk_3ds(filepath=path)
    else:
        raise RuntimeError("formato non gestito: " + ext)


def mesh_scena():
    return [o for o in bpy.data.objects if o.type == "MESH"]


def triangoli(ob=None) -> int:
    if ob is None:
        return sum(triangoli(o) for o in mesh_scena())
    return sum(max(1, len(p.vertices) - 2) for p in ob.data.polygons)


# ---------------------------------------------------------------------------
# Buttare
# ---------------------------------------------------------------------------

def tieni_solo(nomi):
    """Cancella tutto quello che non sta nella lista (confronto sul prefisso).

    Si cancella invece di selezionare perché l'esportazione `use_selection`
    ha bisogno di un contesto di vista che come modulo non c'è sempre.
    """
    voluti = [n.lower() for n in nomi]
    for o in list(bpy.data.objects):
        n = o.name.lower()
        if not any(n.startswith(v) for v in voluti):
            bpy.data.objects.remove(o, do_unlink=True)


def butta(nomi):
    """Il contrario: cancella quelli che corrispondono."""
    brutti = [n.lower() for n in nomi]
    for o in list(bpy.data.objects):
        n = o.name.lower()
        if any(b in n for b in brutti):
            bpy.data.objects.remove(o, do_unlink=True)


def butta_piccoli(soglia_tri: int = 3):
    for o in list(bpy.data.objects):
        if o.type == "MESH" and triangoli(o) < soglia_tri:
            bpy.data.objects.remove(o, do_unlink=True)


# ---------------------------------------------------------------------------
# Misurare e spostare
# ---------------------------------------------------------------------------

def scatola():
    """Il riquadro che contiene tutto, in coordinate di mondo."""
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for o in mesh_scena():
        for v in o.data.vertices:
            p = o.matrix_world @ v.co
            for i in range(3):
                lo[i] = min(lo[i], p[i])
                hi[i] = max(hi[i], p[i])
    return lo, hi


def applica_matrice(M: Matrix):
    """Trasforma tutti i vertici davvero, invece di ruotare i nodi.

    `transform_apply` va in segfault come modulo, quindi si scrive sui
    dati: si trasforma la mesh e si azzera la matrice dell'oggetto. Le
    normali le ricalcola Blender da sé all'esportazione.
    """
    for o in mesh_scena():
        me = o.data
        bm = bmesh.new()
        bm.from_mesh(me)
        bmesh.ops.transform(bm, matrix=(M @ o.matrix_world), verts=bm.verts)
        bm.to_mesh(me)
        bm.free()
        me.update()
        o.matrix_world = Matrix.Identity(4)


def raddrizza(su="Z", avanti="-Y"):
    """Porta il modello dagli assi suoi a quelli **di Blender**, che sono
    quelli da cui l'esportatore glTF sa arrivare a Godot.

    `su` e `avanti` dicono quali assi del **modello** fanno l'alto e il
    muso. Il caso più comune è un FBX Z-su con il muso verso −Y (`Z`,
    `-Y`), che è quello che esce da 3ds Max e da mezzo Sketchfab.

    **La catena degli assi, per intero — e il motivo per cui la prima
    versione era sbagliata.**

    Ci sono tre convenzioni in fila, non due:

        modello  →  Blender (Z su)  →  glTF (Y su)  →  Godot

    L'esportatore con `export_yup=True` fa il secondo passaggio da solo:
    Blender (x, y, z) diventa glTF (x, z, −y). Quindi **Blender +Z
    finisce in alto** e **Blender +Y finisce a −Z**, che è la direzione
    in avanti di Godot — `forward(θ) = (−sinθ, 0, −cosθ)`.

    Al primo giro questa funzione portava il modello direttamente alla
    convenzione di Godot (su su +Y, muso su −Z), e poi l'esportatore
    girava tutto un'altra volta: le dodici macchine nuove sono uscite
    con la lunghezza sull'asse Y, e `Models.spawn_by_length` — che la
    lunghezza la legge su Z — le scalava sull'altezza. Il collaudo
    `tools/prova_modelli.gd` le ha beccate tutte e dodici in un colpo.

    Quindi il bersaglio giusto è: **destra → +X, muso → +Y, su → +Z**.
    """
    assi = {"X": Vector((1, 0, 0)), "-X": Vector((-1, 0, 0)),
            "Y": Vector((0, 1, 0)), "-Y": Vector((0, -1, 0)),
            "Z": Vector((0, 0, 1)), "-Z": Vector((0, 0, -1))}
    u = assi[su]
    f = assi[avanti]
    r = f.cross(u)          # destra = avanti × su
    # La matrice manda: r → +X, f → +Y, u → +Z.
    M = Matrix((
        (r.x, f.x, u.x, 0.0),
        (r.y, f.y, u.y, 0.0),
        (r.z, f.z, u.z, 0.0),
        (0.0, 0.0, 0.0, 1.0),
    )).transposed()
    applica_matrice(M)


def in_metri(lunghezza: float = None, altezza: float = None,
             larghezza: float = None):
    """Scala perché una delle tre misure venga quella vera, in metri.

    Si lavora in assi Blender, cioè **dopo** `raddrizza`: X è la
    larghezza, Y la lunghezza, Z l'altezza.
    """
    lo, hi = scatola()
    d = hi - lo
    k = 1.0
    if lunghezza is not None and d.y > 1e-6:
        k = lunghezza / d.y
    elif altezza is not None and d.z > 1e-6:
        k = altezza / d.z
    elif larghezza is not None and d.x > 1e-6:
        k = larghezza / d.x
    if abs(k - 1.0) > 1e-6:
        applica_matrice(Matrix.Scale(k, 4))
    return k


def a_terra(centrato=True):
    """Origine a terra, al centro dell'impronta. In assi Blender il
    pavimento è Z, non Y."""
    lo, hi = scatola()
    dx = (lo.x + hi.x) * 0.5 if centrato else 0.0
    dy = (lo.y + hi.y) * 0.5 if centrato else 0.0
    applica_matrice(Matrix.Translation(Vector((-dx, -dy, -lo.z))))


# ---------------------------------------------------------------------------
# Materiali
# ---------------------------------------------------------------------------

## Come si chiamano le cose perché `models.gd` le riconosca.
CHIAVI = {
    "body": ["carpaint", "car paint", "paint", "body", "carroz", "scocca",
             "bodywork", "shell", "chassis"],
    "glass": ["glass", "window", "windshield", "vetro", "transparent"],
    "chrome": ["chrome", "chrom", "mirror", "rim", "cerchi", "metal",
               "steel", "specchio"],
    "tire": ["tire", "tyre", "gomm", "rubber", "wheel"],
    "light": ["light", "lamp", "faro", "headlight", "rearlight", "blinker",
              "daylight", "brake"],
}


def rinomina_materiali(extra=None):
    """Dà ai materiali i nomi che il gioco sa leggere.

    Torna quanti ne ha riconosciuti: se il numero è zero c'è qualcosa che
    non va e conviene guardare i nomi veri prima di esportare.
    """
    mappa = dict(CHIAVI)
    if extra:
        for k, v in extra.items():
            mappa.setdefault(k, [])
            mappa[k] = list(v) + list(mappa[k])
    fatti = 0
    for m in bpy.data.materials:
        n = m.name.lower()
        for chiave, pezzi in mappa.items():
            if any(p in n for p in pezzi):
                m.name = "%s_%s" % (chiave, re.sub(r"[^a-z0-9]+", "", n)[:12])
                fatti += 1
                break
    return fatti


def tinta(nome_materiale: str, colore, metallico=0.0, ruvido=0.6):
    """Forza il colore di un materiale. Serve quando il modello arriva
    senza texture e il grigio di serie lo fa sembrare rotto."""
    for m in bpy.data.materials:
        if nome_materiale.lower() in m.name.lower():
            m.diffuse_color = (colore[0], colore[1], colore[2], 1.0)
            m.metallic = metallico
            m.roughness = ruvido
            if m.use_nodes:
                for n in m.node_tree.nodes:
                    if n.type == "BSDF_PRINCIPLED":
                        n.inputs["Base Color"].default_value = (
                            colore[0], colore[1], colore[2], 1.0)
                        n.inputs["Metallic"].default_value = metallico
                        n.inputs["Roughness"].default_value = ruvido


# ---------------------------------------------------------------------------
# Alleggerire ed esportare
# ---------------------------------------------------------------------------

def alleggerisci(tetto_tri: int):
    """Mette un Decimate su ogni mesh perché il totale stia sotto al tetto.

    Il modificatore **non si applica qui**: `modifier_apply` va in
    segfault come modulo. Lo applica l'esportatore glTF con
    `export_apply=True`, che fa la stessa cosa e non crolla.
    """
    tot = triangoli()
    if tot <= tetto_tri:
        return 1.0
    r = max(0.02, tetto_tri / float(tot))
    for o in mesh_scena():
        if triangoli(o) < 60:
            continue    # sotto i sessanta triangoli decimare rompe e basta
        m = o.modifiers.new(name="Alleggerisci", type="DECIMATE")
        m.ratio = r
    return r


def attacca_texture(path: str, dentro_al_nome: str = ""):
    """Attacca a mano una texture ai materiali.

    **Perché serve.** Mezzo Sketchfab esporta l'OBJ con dentro
    `map_Kd arco.jpg` e poi mette il file in `textures/arco.jpg`. Blender
    cerca dove gli hanno detto, non lo trova, e importa il modello **senza
    texture**: il risultato è uno scan bianco che in gioco sembra un
    fantasma di gesso. È successo con l'arco, col fucile e con la giara, e
    non se n'era accorto nessuno finché non l'ho visto a schermo.

    `dentro_al_nome` limita ai materiali che contengono quella parola;
    vuoto vuol dire tutti.
    """
    if not os.path.exists(path):
        print("    !! texture non trovata:", path)
        return False
    img = bpy.data.images.load(path, check_existing=True)
    fatti = 0
    for m in bpy.data.materials:
        if dentro_al_nome and dentro_al_nome.lower() not in m.name.lower():
            continue
        m.use_nodes = True
        nodi = m.node_tree.nodes
        bsdf = None
        for n in nodi:
            if n.type == "BSDF_PRINCIPLED":
                bsdf = n
                break
        if bsdf is None:
            bsdf = nodi.new("ShaderNodeBsdfPrincipled")
            out = nodi.new("ShaderNodeOutputMaterial")
            m.node_tree.links.new(bsdf.outputs[0], out.inputs[0])
        tex = nodi.new("ShaderNodeTexImage")
        tex.image = img
        m.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        fatti += 1
    return fatti > 0


def texture_da_cartella(cartella: str):
    """Cerca in una cartella una texture per ogni materiale, accoppiando
    per somiglianza di nome. È il caso dei modelli con dieci materiali —
    cappuccino, cornetto, bicchiere — e dieci PNG che si chiamano quasi
    come loro."""
    if not os.path.isdir(cartella):
        return 0
    files = []
    for f in os.listdir(cartella):
        if os.path.splitext(f)[1].lower() in (".png", ".jpg", ".jpeg"):
            files.append(f)
    fatti = 0
    for m in bpy.data.materials:
        base = re.sub(r"[^a-z0-9]+", "", m.name.lower())
        if not base:
            continue
        meglio = None
        for f in files:
            n = re.sub(r"[^a-z0-9]+", "", os.path.splitext(f)[0].lower())
            if base in n or n.startswith(base[:6]):
                meglio = f
                break
        if meglio is None:
            continue
        if attacca_texture(os.path.join(cartella, meglio), m.name):
            fatti += 1
    return fatti


def riduci_texture(lato_max: int = 256):
    """Rimpicciolisce le texture incorporate prima di esportare.

    **Il conto che me l'ha insegnato.** I coni stradali del pacchetto
    "neighbourhood city" pesavano 1,47 MB l'uno — non di geometria (416
    triangoli), ma perché si portavano dietro una diffuse e una normal da
    2048 pixel. Undici pezzi di arredo facevano trenta mega per roba che
    a schermo occupa venti pixel. A 256 il cono è identico e il file
    scende sotto ai cento kilobyte.

    Vale la regola generale: la risoluzione di una texture si sceglie da
    **quanto grande si vede l'oggetto**, non da quanto è grande il file
    che ti hanno dato.
    """
    for img in bpy.data.images:
        if img.size[0] <= lato_max and img.size[1] <= lato_max:
            continue
        if img.size[0] == 0 or img.size[1] == 0:
            continue
        k = lato_max / float(max(img.size))
        img.scale(max(4, int(img.size[0] * k)), max(4, int(img.size[1] * k)))


def spiana():
    """Via i genitori e via gli Empty: ogni mesh resta per conto suo con la
    matrice identità.

    È sicuro perché a questo punto `applica_matrice` ha già scritto le
    coordinate di mondo dentro ai vertici — i nodi non portano più
    informazione, portano solo guai. E il guaio l'ho visto: la macchinetta
    stilizzata era appesa a un Empty con dentro un fattore di scala, e in
    Godot usciva larga duecentocinquantasei metri. Il collaudo l'ha
    beccata subito perché una macchina larga come un isolato si nota.
    """
    for o in list(bpy.data.objects):
        if o.type != "MESH":
            bpy.data.objects.remove(o, do_unlink=True)
    for o in mesh_scena():
        o.parent = None
        o.matrix_basis = Matrix.Identity(4)
        o.matrix_world = Matrix.Identity(4)


def esporta(path: str):
    spiana()
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        export_apply=True,          # applica i Decimate senza operatori
        export_yup=True,
        export_materials="EXPORT",
        export_normals=True,
        export_texcoords=True,
        export_cameras=False,
        export_lights=False,
        export_animations=False,
    )
    kb = os.path.getsize(path) / 1024.0
    lo, hi = scatola()
    d = hi - lo
    # Si stampa larghezza × altezza × lunghezza, cioè come si legge una
    # macchina, e non nell'ordine degli assi di Blender.
    print("  → %-34s %6.0f KB  %5d tri  largh %.2f  alt %.2f  lung %.2f" % (
        os.path.basename(path), kb, triangoli(), d.x, d.z, d.y))
