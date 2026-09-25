#!/usr/bin/env python3
"""Ritaglia il pacchetto di auto e ne fa dieci modelli pronti per il gioco.

**Il problema.** In `Models/` c'era da settimane un pacchetto con dieci
carrozzerie diverse — compatta, coupé, familiare, monovolume, pick-up,
SUV… — e nel gioco si vedevano sempre le stesse tre macchine, perché
nessuno l'aveva mai aperto. Questo script lo apre.

**Cosa fa, per ognuna delle dieci.**

1. Trova le quattro ruote che le appartengono: nel file stanno tutte
   sparse in una fila, ma ognuna e' gia' al posto suo *rispetto al corpo*,
   quindi si prendono quelle che cadono dentro all'ingombro del corpo
   allargato di mezzo metro.
2. La porta all'origine, con le gomme che toccano terra.
3. La gira col muso verso **+Y di Blender**, che esportato diventa **−Z di
   Godot** — la direzione in cui il gioco fa camminare tutto.
4. Rinomina i materiali in `body`, `glass`, `optics`, `tire`: sono i nomi
   che `models.gd` cerca per verniciare la carrozzeria di un colore
   diverso a ogni auto e per lasciare scuri i vetri e nere le gomme. Con i
   nomi originali (`Body.006`) il gioco verniciava anche le ruote.
5. La esporta in `assets/models/`.

**Come si capisce dove sta il muso.** Non si deduce: si guarda dove sta il
vetro. In una macchina il parabrezza sta al centro e il lunotto in fondo,
quindi il baricentro del vetro cade **dietro** al baricentro della
carrozzeria. E' una regola che regge per tutte e dieci, ed e' stata
verificata a occhio su un foglio di contatto renderizzato.
"""
import bpy, bmesh, os, sys, math
from mathutils import Vector

FBX = '/tmp/autopack/generic-passenger-car-pack/source/fab.fbx'
FUORI = os.path.join(os.path.dirname(os.path.dirname(
    os.path.abspath(__file__))), 'assets', 'models')

## Le dieci carrozzerie, col nome che avranno nel gioco e la lunghezza a
## cui vanno tagliate. Le misure sono quelle vere di quelle macchine, non
## quelle del file: il pacchetto e' modellato a caso fra i 3,6 e i 5,8 m.
AUTO = [
    ('Compact Body',   'car_compatta',   3.55),
    ('Coupe Body',     'car_coupe',      4.30),
    ('Hatchback Body', 'car_utilitaria', 3.90),
    ('minivan body',   'car_monovolume', 4.60),
    ('Offroad Body',   'car_fuoristrada', 4.25),
    ('Pickup Body',    'car_pickup',     5.10),
    ('Sedan Body',     'car_berlina2',   4.65),
    ('Sport body',     'car_sportiva',   4.35),
    ('SUV Body',       'car_suv',        4.75),
    ('Wagon Body',     'car_familiare',  4.70),
]


def mat(nome, colore, metallico=0.0, ruvido=0.7):
    m = bpy.data.materials.new(nome)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get('Principled BSDF')
    if bsdf:
        bsdf.inputs['Base Color'].default_value = (*colore, 1.0)
        bsdf.inputs['Metallic'].default_value = metallico
        bsdf.inputs['Roughness'].default_value = ruvido
    return m


def ingombro(o):
    """Angoli minimo e massimo dell'oggetto in coordinate del mondo."""
    punti = [o.matrix_world @ Vector(c) for c in o.bound_box]
    mn = Vector((min(p.x for p in punti), min(p.y for p in punti),
                 min(p.z for p in punti)))
    mx = Vector((max(p.x for p in punti), max(p.y for p in punti),
                 max(p.z for p in punti)))
    return mn, mx


def centroide_materiale(o, pezzo):
    """Baricentro dei vertici che usano un materiale il cui nome contiene
    `pezzo`. Serve a capire da che parte sta il muso."""
    indici = [i for i, m in enumerate(o.data.materials)
              if m and pezzo.lower() in m.name.lower()]
    if not indici:
        return None
    somma = Vector((0, 0, 0))
    n = 0
    for poly in o.data.polygons:
        if poly.material_index in indici:
            somma += o.matrix_world @ poly.center
            n += 1
    return somma / n if n else None


def centroide_tetto(o, quota=0.88):
    """Baricentro del dodici per cento piu' alto della carrozzeria: il
    tetto. E' il modo piu' netto di capire dove sta il davanti."""
    punti = [o.matrix_world @ Vector(v.co) for v in o.data.vertices]
    if not punti:
        return None
    zs = sorted(p.z for p in punti)
    soglia = zs[int(len(zs) * quota)]
    alti = [p for p in punti if p.z >= soglia]
    if not alti:
        return None
    somma = Vector((0, 0, 0))
    for p in alti:
        somma += p
    return somma / len(alti)


def costruisci():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=FBX)

    corpi = {o.name: o for o in bpy.data.objects if o.type == 'MESH'}
    ruote_tutte = [o for o in bpy.data.objects
                   if o.type == 'MESH' and o.name.lower().startswith('wheel')]

    m_body = mat('body', (0.55, 0.55, 0.57), 0.55, 0.32)
    m_glass = mat('glass', (0.08, 0.11, 0.15), 0.9, 0.06)
    m_optics = mat('optics', (0.92, 0.90, 0.80), 0.2, 0.2)
    m_tire = mat('tire_wheel', (0.07, 0.07, 0.08), 0.0, 0.95)

    os.makedirs(FUORI, exist_ok=True)
    fatte = []
    for nome_src, nome_out, lunghezza in AUTO:
        corpo = corpi.get(nome_src)
        if corpo is None:
            print('  manca:', nome_src)
            continue
        mn, mx = ingombro(corpo)
        # **Le ruote si riconoscono dal materiale, non dalla vicinanza.**
        #
        # Il primo tentativo le prendeva per prossimita': tutte quelle che
        # cadevano dentro all'ingombro del corpo. Nel file pero' le
        # macchine stanno in fila attaccate, e il SUV si prendeva le ruote
        # del pick-up — due ruote finivano sospese a mezz'aria e la
        # macchina risultava girata di venti gradi, perche' l'asse lo
        # danno proprio le ruote.
        #
        # Ogni ruota porta con se' la lista dei materiali del corpo a cui
        # appartiene (`Body.008` = SUV): quella e' l'appartenenza esatta.
        suo_mat = corpo.data.materials[0].name if corpo.data.materials else ''
        sue = []
        for r in ruote_tutte:
            if any(m and m.name == suo_mat for m in r.data.materials):
                sue.append(r)

        pezzi = [corpo] + sue
        # Copie, perche' l'originale serve anche alle altre auto.
        copie = []
        for o in pezzi:
            c = o.copy()
            c.data = o.data.copy()
            bpy.context.collection.objects.link(c)
            copie.append(c)

        # Materiali: la carrozzeria si vernicia, il vetro resta vetro, i
        # fari si accendono, le ruote restano nere.
        for c in copie:
            e_ruota = c.name.lower().startswith('wheel')
            nuovi = []
            for m in c.data.materials:
                n = (m.name if m else '').lower()
                if e_ruota:
                    nuovi.append(m_tire)
                elif 'glass' in n:
                    nuovi.append(m_glass)
                elif 'optic' in n:
                    nuovi.append(m_optics)
                else:
                    nuovi.append(m_body)
            # **Si sostituiscono gli slot, non si svuota la lista.**
            #
            # `materials.clear()` toglie tutte le cassette e con esse gli
            # indici: ogni faccia si ritrova col materiale zero, cioe' la
            # carrozzeria. Il vetro e i fari sparivano — misurato: nei
            # primi dieci file esportati c'erano due materiali invece di
            # quattro, e le macchine avevano i finestrini di lamiera.
            for i, m in enumerate(nuovi):
                c.data.materials[i] = m
            if e_ruota:
                c.name = 'wheel_' + nome_out
            # **Meno facce.** Il pacchetto e' modellato a cinquemila
            # triangoli a macchina, che per un gioco in cui ce ne stanno
            # sette a schermo e' uno spreco: la differenza fra 5.000 e
            # 1.200 a due metri di distanza non la vede nessuno, e il
            # pacchetto passa da tre megabyte a seicento kilobyte.
            #
            # Il modificatore NON si applica a mano (`modifier_apply` in
            # modalita' modulo fa saltare tutto): ci pensa l'esportatore
            # glTF, che valuta la scena col depsgraph.
            facce = len(c.data.polygons)
            bersaglio = 260 if e_ruota else 1100
            if facce > bersaglio:
                d = c.modifiers.new('taglia', 'DECIMATE')
                d.ratio = bersaglio / float(facce)

        # **Da che parte guarda, e di quanto e' storta.**
        #
        # Il primo tentativo guardava se l'ingombro era piu' lungo in X o
        # in Y, e assumeva che l'auto fosse dritta su un asse. Nel file
        # meta' delle carrozzerie sta **girata di sghembo** — la coupé ha
        # un ingombro di 4,73 x 2,82 che non e' ne' la lunghezza ne' la
        # larghezza vere — e il risultato erano dieci macchine ognuna
        # storta per conto suo. Si vede nel foglio di contatto.
        #
        # Il verso vero lo danno **le ruote**: la retta che passa fra
        # l'asse anteriore e quello posteriore E' l'asse della macchina,
        # senza approssimazioni. Si prende la direzione principale dei
        # quattro centri e la si porta su +Y.
        centri = [r.matrix_world.translation for r in sue]
        asse = None
        if len(centri) >= 3:
            mediana = sum(centri, Vector((0, 0, 0))) / len(centri)
            # Direzione di massima dispersione, sul piano: due componenti
            # bastano, e con quattro punti si fa a mano.
            sxx = sum((c.x - mediana.x) ** 2 for c in centri)
            syy = sum((c.y - mediana.y) ** 2 for c in centri)
            sxy = sum((c.x - mediana.x) * (c.y - mediana.y) for c in centri)
            ang = 0.5 * math.atan2(2.0 * sxy, sxx - syy)
            asse = Vector((math.cos(ang), math.sin(ang), 0.0))
        if asse is None:
            asse = Vector((0.0, 1.0, 0.0))
        # Quanto si deve girare perche' quell'asse diventi +Y.
        gira = math.pi * 0.5 - math.atan2(asse.y, asse.x)
        # E se cosi' il muso finisce dietro, mezzo giro in piu': il vetro
        # (parabrezza, lunotto, finestrini) sta sempre nella meta'
        # posteriore, quindi proiettato sull'asse dev'essere negativo.
        gc = centroide_tetto(corpo)
        cc = corpo.matrix_world.translation
        if gc is not None:
            avanti = Vector((math.cos(-gira + math.pi * 0.5),
                             math.sin(-gira + math.pi * 0.5), 0.0))
            # **'O tetto sta arreto ô muso.**
            #
            # Dopo la rotazione l'asse `avanti` finisce su +Y di Blender,
            # che esportato diventa −Z di Godot: la direzione in cui il
            # gioco fa camminare tutto. Il punto piu' alto di una macchina
            # e' il tetto, e il tetto sta sempre dietro al cofano — quindi
            # la proiezione del baricentro del tetto sull'asse dev'essere
            # NEGATIVA. Se e' positiva, mezzo giro.
            #
            # Il primo tentativo usava il baricentro del VETRO, che pero'
            # su un monovolume (finestrini per tutta la lunghezza) cade in
            # mezzo e non decide niente. Il tetto e' piu' netto: sui dieci
            # modelli lo scarto e' fra 27 e 64 centimetri, mai vicino a
            # zero.
            if (gc - cc).xy.dot(avanti.xy) > 0.0:
                gira += math.pi

        # Tutto dentro a un vuoto, cosi' si ruota e si scala in blocco.
        perno = bpy.data.objects.new('auto_' + nome_out, None)
        bpy.context.collection.objects.link(perno)
        centro = Vector(((mn.x + mx.x) * 0.5, (mn.y + mx.y) * 0.5, mn.z))
        for c in copie:
            c.parent = perno
            c.matrix_parent_inverse = perno.matrix_world.inverted()
        perno.location = -centro
        bpy.context.view_layer.update()

        contenitore = bpy.data.objects.new('car_' + nome_out, None)
        bpy.context.collection.objects.link(contenitore)
        perno.parent = contenitore
        contenitore.rotation_euler = (0, 0, gira)
        # Scala sulla lunghezza vera.
        dirz = Vector((math.cos(math.pi * 0.5 - gira),
                       math.sin(math.pi * 0.5 - gira), 0.0))
        proiez = [(corpo.matrix_world @ Vector(v.co)).xy.dot(dirz.xy)
                  for v in corpo.data.vertices]
        attuale = max(proiez) - min(proiez)
        contenitore.scale = (lunghezza / attuale,) * 3
        bpy.context.view_layer.update()

        for o in bpy.context.selected_objects:
            o.select_set(False)
        for c in copie:
            c.select_set(True)
        bpy.context.view_layer.objects.active = copie[0]
        percorso = os.path.join(FUORI, nome_out + '.glb')
        bpy.ops.export_scene.gltf(filepath=percorso, export_format='GLB',
                                  use_selection=True, export_yup=True,
                                  export_apply=True)
        tri = sum(len(c.data.polygons) for c in copie)
        print('  %-18s %.2f m  %d facce  %d pezzi'
              % (nome_out, lunghezza, tri, len(copie)))
        fatte.append(nome_out)

        for c in copie:
            bpy.data.objects.remove(c, do_unlink=True)
        bpy.data.objects.remove(perno, do_unlink=True)
        bpy.data.objects.remove(contenitore, do_unlink=True)
    return fatte


if __name__ == '__main__':
    print('== auto d''o pacchetto ==')
    f = costruisci()
    print('fatte %d auto' % len(f))
