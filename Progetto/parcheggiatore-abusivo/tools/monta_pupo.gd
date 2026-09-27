extends SceneTree
## **'O trapianto d''o pupo.**
##
## Il file sorgente dello scheletro e delle quarantatré animazioni
## (`UAL1_Standard.glb`) sta solo sul computer del capo, e `pupo.glb` non
## esiste più dalla 0.58: il pupo vive solo come `pupo.scn`. Quindi il
## corpo nuovo non si esporta *con* le animazioni: si fa in Blender sullo
## scheletro tirato fuori da `pupo.scn`, e poi si **trapianta** qui —
## le mesh nuove sullo scheletro vecchio, accanto all'`AnimationPlayer`
## vecchio. Le clip non passano da nessuna conversione: restano quelle,
## byte per byte.
##
## **I legami si ricalcolano.** Blender, importando, gira le ossa a modo
## suo (il rollio), e l'esportatore scrive i legami (bind pose) rispetto a
## quelle ossa girate. Sullo scheletro vecchio quei legami sarebbero
## sbagliati. Ma la posa di riposo del corpo, in metri, è la stessa: quindi
## per ogni osso si prende dove sta il vertice a riposo nella scena nuova e
## si scrive il legame che lo rimette lì con l'osso vecchio.
##
##   godot --headless --path . --script res://tools/monta_pupo.gd -- \
##       <pupo_nuovo.glb> [res://assets/models/pupo.scn]
##
## Senza secondo argomento scrive `res://assets/models/pupo.scn`. Il
## vecchio si trova sempre in `pupo.scn` (o in `pupo_vecchio.scn`, se c'è:
## così il trapianto si può rifare quante volte si vuole partendo dallo
## stesso scheletro).

const PUPO := "res://assets/models/pupo.scn"
## Il riquadro di tutte le pose, nello spazio dello scheletro (metri del
## file, pupo alto 1,79): ±1,9 attorno ai piedi, da sotto terra a sopra le
## braccia alzate.
const INGOMBRO := AABB(Vector3(-1.9, -0.3, -1.9), Vector3(3.8, 2.7, 3.8))
const VECCHIO := "res://assets/models/pupo_vecchio.scn"


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.is_empty():
		push_error("manca il .glb nuovo")
		quit(1)
		return
	var glb: String = a[0]
	var uscita: String = a[1] if a.size() > 1 else PUPO
	var sorgente: String = VECCHIO if ResourceLoader.exists(VECCHIO) else PUPO

	var vecchio: Node3D = (load(sorgente) as PackedScene).instantiate()
	var sk_v: Skeleton3D = vecchio.find_children("*", "Skeleton3D", true, false)[0]

	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	var err := doc.append_from_file(glb, st)
	if err != OK:
		push_error("nun se legge %s (%d)" % [glb, err])
		quit(1)
		return
	var nuovo: Node3D = doc.generate_scene(st)
	var sk_n: Skeleton3D = nuovo.find_children("*", "Skeleton3D", true, false)[0]

	# Le mesh vecchie se ne vanno.
	for c in sk_v.get_children():
		if c is MeshInstance3D:
			sk_v.remove_child(c)
			c.free()

	var da_scena_n: Transform3D = _a_radice(sk_n, nuovo)
	var da_scena_v: Transform3D = _a_radice(sk_v, vecchio)
	var tri_tot := 0
	var nomi: Array = []
	for mi in nuovo.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var skin_n: Skin = m.skin
		var skin_v := Skin.new()
		if skin_n != null:
			for i in skin_n.get_bind_count():
				var nome: String = str(skin_n.get_bind_name(i))
				if nome == "":
					nome = sk_n.get_bone_name(skin_n.get_bind_bone(i))
				var bn: int = sk_n.find_bone(nome)
				var bv: int = sk_v.find_bone(nome)
				if bn < 0 or bv < 0:
					push_warning("osso %s nun ce sta" % nome)
					continue
				# Dove porta il vertice a riposo, nella radice della scena nuova…
				var riposo_n: Transform3D = da_scena_n * sk_n.get_bone_global_rest(bn) \
					* skin_n.get_bind_pose(i)
				# …e il legame che ce lo porta con l'osso vecchio.
				var legame: Transform3D = (da_scena_v * sk_v.get_bone_global_rest(bv)) \
					.affine_inverse() * riposo_n
				skin_v.add_named_bind(nome, legame)
		# **'O pupo 'nterra perdeva 'a capa.** Godot decide se disegnare una
		# mesh skinnata dal suo riquadro a riposo, cioè in piedi: la testa di
		# uno disteso sta un metro e mezzo più in là, fuori dal riquadro, e
		# veniva scartata (restavano i baffi, che per caso ci cadevano
		# dentro). Un riquadro fisso che contiene tutte le pose delle
		# quarantatré clip — in piedi, disteso, seduto, a braccia aperte —
		# vale per tutti i pezzi, e costa niente.
		m.mesh.custom_aabb = INGOMBRO
		var copia := MeshInstance3D.new()
		copia.name = m.name
		copia.mesh = m.mesh
		copia.skin = skin_v
		sk_v.add_child(copia)
		copia.owner = vecchio
		copia.skeleton = NodePath("..")
		nomi.append(str(m.name))
		for s in m.mesh.get_surface_count():
			var arr: Array = m.mesh.surface_get_arrays(s)
			var idx = arr[Mesh.ARRAY_INDEX]
			tri_tot += (idx.size() if idx != null else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3

	nomi.sort()
	print("  pezzi: ", nomi)
	print("  triangoli (tutti i pezzi, tutti i corpi): ", tri_tot)
	var ps := PackedScene.new()
	err = ps.pack(vecchio)
	if err != OK:
		push_error("pack %d" % err)
		quit(1)
		return
	err = ResourceSaver.save(ps, uscita, ResourceSaver.FLAG_COMPRESS)
	print("  salvato ", uscita, " → ", err)
	vecchio.free()
	nuovo.free()
	quit(0 if err == OK else 1)


## La trasformazione di `n` rispetto a `radice`, risalendo i genitori.
func _a_radice(n: Node, radice: Node) -> Transform3D:
	var t := Transform3D()
	while n != null and n != radice:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t
