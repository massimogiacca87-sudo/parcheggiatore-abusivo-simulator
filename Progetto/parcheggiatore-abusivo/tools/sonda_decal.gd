extends Node
## Sonda (0.62): i gruppi delle decalcomanie, quanti sono e dove stanno.
const Citta := preload("res://scripts/citta_3d.gd")
var _t := 0.0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _process(d: float) -> void:
	_t += d
	if _t < 4.0:
		return
	set_process(false)
	var c: Node3D = get_tree().get_first_node_in_group("citta")
	var conti := {}
	var fuori_muro := 0
	for n in c.get_children():
		if n is MultiMeshInstance3D and str(n.name).begins_with("Gruppo_decal_"):
			var tipo: String = str(n.name).substr(13)
			var k: int = tipo.find("_q")
			if k > 0:
				tipo = tipo.substr(0, k)
			var mm: MultiMesh = (n as MultiMeshInstance3D).multimesh
			conti[tipo] = int(conti.get(tipo, 0)) + mm.instance_count
			if tipo.begins_with("colatura") or tipo.begins_with("graffito"):
				for i in mm.instance_count:
					var t: Transform3D = (n as Node3D).global_transform * mm.get_instance_transform(i)
					var f: Vector3 = t.basis.z.normalized()
					if not Citta.dint_ô_palazzo(t.origin - f * 0.12, 0.0):
						fuori_muro += 1
						if fuori_muro < 4:
							var vicino := INF
							var qual: Vector3
							for v in c._split_posti:
								var dd: float = Vector2((v[0] as Vector3).x, (v[0] as Vector3).z).distance_to(Vector2(t.origin.x, t.origin.z))
								if dd < vicino:
									vicino = dd
									qual = v[0]
							print("   split cchiù vicino: %s a %.2f; nodo %s pos %s ist %s" % [str(qual), vicino, n.name, str((n as Node3D).global_position), str(mm.get_instance_transform(i).origin)])
						if fuori_muro < 8:
							print("   fuori: %s %s f=%s  avanti dentro=%s  1m dietro=%s" % [tipo, str(t.origin.snapped(Vector3.ONE*0.01)), str(f.snapped(Vector3.ONE*0.01)),
								Citta.dint_ô_palazzo(t.origin + f * 0.12, 0.0), Citta.dint_ô_palazzo(t.origin - f * 1.0, 0.0)])
			var mat := (n as MultiMeshInstance3D).material_override as StandardMaterial3D
			if conti[tipo] == mm.instance_count:
				print("  %s: mat %s tex %s vista %.0f" % [tipo, mat != null,
					str(mat.albedo_texture.get_size()) if mat and mat.albedo_texture else "-",
					(n as GeometryInstance3D).visibility_range_end])
	print("CONTI ", conti)
	print("fuori dal muro: ", fuori_muro)
	print("meta: tombini %s colature %s umidi %s tag %s posti %s" % [c.get_meta(&"tombini_messi", -1),
		c.get_meta(&"colature_split", -1), c.get_meta(&"colature_muro", -1),
		c.get_meta(&"graffiti_tag", -1), c.get_meta(&"macchie_posti", -1)])
	for nome in ["condizionatore", "condizionatore2"]:
		var tot := AABB()
		var primo := true
		for pz in c._pezzi_modello(nome):
			var a: AABB = (pz["trasf"] as Transform3D) * (pz["mesh"] as Mesh).get_aabb()
			print("   pezzo %s: %s" % [nome, str(a)])
			tot = a if primo else tot.merge(a)
			primo = false
		print("  %s: centro %s ngombro %s" % [nome, str(c._centro_modello(nome)), str(tot)])
	print("split posti: ", c._split_posti.size())
	var senza := 0
	var visti := {}
	var doppi := 0
	for v in c._split_posti:
		var pp: Vector3 = v[0]
		var ff: Vector3 = v[1]
		if not Citta.dint_ô_palazzo(pp - ff * 0.12, 0.0):
			senza += 1
			if senza < 4:
				print("   split senza muro: ", pp, ff)
		var k := str(pp.snapped(Vector3.ONE * 0.05))
		if visti.has(k):
			doppi += 1
		visti[k] = true
	print("split senza muro: %d, doppi: %d" % [senza, doppi])
	get_tree().quit()
