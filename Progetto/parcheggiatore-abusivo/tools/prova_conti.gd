extends Node
## **'E cunte d''a città** (0.59): quante istanze e quanti triangoli ci
## sono in ogni gruppo raggruppato (MultiMesh), e in tutto. Serve a sapere
## quanto costa la roba nuova prima di spargerla per mille balconi.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(60):
		await get_tree().process_frame
	var citta := get_tree().get_first_node_in_group("citta")
	var righe: Array = []
	var tot_tri := 0
	var tot_ist := 0
	var tot_mm := 0
	for c in citta.get_children():
		if not (c is MultiMeshInstance3D):
			continue
		var mm: MultiMesh = (c as MultiMeshInstance3D).multimesh
		if mm == null or mm.mesh == null:
			continue
		var tri := _tri(mm.mesh)
		righe.append([tri * mm.instance_count, str(c.name), mm.instance_count, tri,
			(c as GeometryInstance3D).visibility_range_end])
		tot_tri += tri * mm.instance_count
		tot_ist += mm.instance_count
		tot_mm += 1
	righe.sort_custom(func(a, b): return int(a[0]) > int(b[0]))
	for r in righe:
		print("  %-40s %5d × %5d = %8d tri  vista %.0f" % [r[1], r[2], r[3], r[0], r[4]])
	print("  --- tetto_/balcone_/panda: ---")
	var per_pref := {}
	for r in righe:
		var n: String = str(r[1]).trim_prefix("Gruppo_")
		var pref: String = n.split("_")[0]
		per_pref[pref] = int(per_pref.get(pref, 0)) + int(r[0])
	var chiavi := per_pref.keys()
	chiavi.sort_custom(func(a, b): return int(per_pref[a]) > int(per_pref[b]))
	for k in chiavi.slice(0, 30):
		print("  %-20s %9d tri" % [k, per_pref[k]])
	print("=== %d gruppi, %d istanze, %d triangoli ===" % [tot_mm, tot_ist, tot_tri])
	# **Quanti se ne disegnano davvero** (0.60). Il totale conta tutto quello
	# che esiste; da un punto della città Godot disegna solo i gruppi che
	# stanno dentro al loro raggio (`visibility_range_begin/end`). Da cinque
	# punti, senza contare l'inquadratura (che ne toglie altri).
	for punto in [Vector3(31, 1.7, 30), Vector3(78, 1.7, 63), Vector3(144, 1.7, 50),
			Vector3(30, 1.7, 111), Vector3(144, 4.7, 154)]:
		var vis := 0
		var gruppi := 0
		for c in citta.get_children():
			if not (c is MultiMeshInstance3D):
				continue
			var mmi := c as MultiMeshInstance3D
			if mmi.multimesh == null or mmi.multimesh.mesh == null:
				continue
			var d: float = (mmi.global_position).distance_to(punto)
			if mmi.visibility_range_end > 0.0 and d > mmi.visibility_range_end:
				continue
			if mmi.visibility_range_begin > 0.0 and d < mmi.visibility_range_begin:
				continue
			vis += _tri(mmi.multimesh.mesh) * mmi.multimesh.instance_count
			gruppi += 1
		print("  da %s: %d triangoli in %d gruppi dentro al raggio" % [str(punto), vis, gruppi])
	print("=== storte: 0 ===")
	get_tree().quit()


func _tri(m: Mesh) -> int:
	var n := 0
	for s in m.get_surface_count():
		var arr: Array = m.surface_get_arrays(s)
		var idx = arr[Mesh.ARRAY_INDEX]
		n += (idx.size() if idx != null else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return n
