extends Node
## Sonda (0.62): chi sta fermo come una statua?
##
## Il capo: *«Molti dei nuovi modelli che hai inserito non hanno
## animazioni»*. Qui si guarda ogni `Skeleton3D` della città due volte, a un
## secondo e mezzo di distanza: se nessun osso s'è mosso, quel corpo non ha
## un'animazione che gira. Si stampa chi è (lo script del padrone, il nome,
## il gruppo) e dove sta. In più si contano le persone fatte di mesh senza
## scheletro (modelli PSX o simili con "person/man/woman" nel nome).

var _prima: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(60):
		await get_tree().process_frame
	get_tree().paused = false
	GameManager.intro_active = false
	await get_tree().create_timer(3.0).timeout
	var sk: Array = []
	_tutti(get_tree().root, sk)
	for s in sk:
		_prima[s] = _impronta(s)
	await get_tree().create_timer(1.5).timeout
	var fermi: Dictionary = {}
	var mossi := 0
	for s in sk:
		if not is_instance_valid(s):
			continue
		var d: float = _differenza(_prima[s], _impronta(s))
		if d < 0.0005:
			var chi := _chi(s)
			fermi[chi] = int(fermi.get(chi, 0)) + 1
		else:
			mossi += 1
	print("scheletri: %d  mossi: %d  fermi: %d" % [sk.size(), mossi, sk.size() - mossi])
	var chiavi := fermi.keys()
	chiavi.sort()
	for k in chiavi:
		print("  FERMO x%d  %s" % [fermi[k], k])
	# Le persone senza scheletro.
	var mesh_persone: Dictionary = {}
	_persone_mesh(get_tree().root, mesh_persone)
	for k in mesh_persone:
		print("  MESH-PERSONA x%d  %s" % [mesh_persone[k], k])
	print("=== fernuto ===")
	get_tree().quit()


func _tutti(n: Node, fuori: Array) -> void:
	if n is Skeleton3D and (n as Skeleton3D).is_visible_in_tree():
		fuori.append(n)
	for c in n.get_children():
		_tutti(c, fuori)


func _impronta(s: Skeleton3D) -> PackedFloat32Array:
	var f := PackedFloat32Array()
	var n: int = mini(s.get_bone_count(), 30)
	for i in range(n):
		var q: Quaternion = s.get_bone_pose_rotation(i)
		f.append(q.x)
		f.append(q.y)
		f.append(q.z)
		f.append(q.w)
	return f


func _differenza(a: PackedFloat32Array, b: PackedFloat32Array) -> float:
	var d := 0.0
	for i in range(mini(a.size(), b.size())):
		d = maxf(d, absf(a[i] - b[i]))
	return d


## Chi è il padrone: il primo antenato con uno script, e il suo nome.
func _chi(s: Node) -> String:
	var n: Node = s
	while n != null:
		var sc = n.get_script()
		if sc != null and n != s:
			var gruppi: Array = []
			for g in n.get_groups():
				if not str(g).begins_with("_"):
					gruppi.append(str(g))
			return "%s [%s] %s" % [str(sc.resource_path).get_file(),
				",".join(gruppi), _nome_pulito(n.name)]
		n = n.get_parent()
	return "(senza script) " + str(s.get_path())


func _nome_pulito(n: String) -> String:
	var r := ""
	for ch in n:
		if ch >= "0" and ch <= "9":
			continue
		r += ch
	return r


func _persone_mesh(n: Node, fuori: Dictionary) -> void:
	if n is MeshInstance3D:
		var nome := str(n.name).to_lower()
		for w in ["person", "man_", "woman", "people", "human", "character",
				"guy", "lady", "girl", "boy", "worker", "npc"]:
			if nome.contains(w):
				fuori[str(n.name)] = int(fuori.get(str(n.name), 0)) + 1
				break
	for c in n.get_children():
		_persone_mesh(c, fuori)
