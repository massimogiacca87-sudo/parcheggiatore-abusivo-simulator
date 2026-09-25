extends Node
## Si arriva o no? Per ogni punto: cella libera, raggiungibile, e la strada
## verso una meta (SONDA_META="x,z").
const Cammino := preload("res://scripts/cammino.gd")
const Citta := preload("res://scripts/citta_3d.gd")
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(90):
		await get_tree().process_frame
	await get_tree().create_timer(2.0).timeout
	var meta := Vector3(105, 0, 139)
	for p in [Vector3(169, 0, 162), Vector3(168, 0, 160), Vector3(168, 0, 150), Vector3(168, 0, 130), Vector3(168, 0, 126), Vector3(157.5, 0, 140), Vector3(157.5, 0, 150), Vector3(78, 0, 12)]:
		var s: PackedVector3Array = Cammino.strada(p, meta)
		print("  %s libera %s raggiungibile %s strada %d punti" % [str(p), str(Cammino.libera(p)), str(Cammino.raggiungibile(p)), s.size()])
	const Ost := preload("res://scripts/ostacoli.gd")
	for o in Ost.tutte():
		if Vector2(float(o[0]) - 168.0, float(o[1]) - 158.0).length() < 9.0:
			print("    ostacolo a (%.1f, %.1f) mezzi %.2f x %.2f" % [float(o[0]), float(o[1]), float(o[2]), float(o[3])])
	# Chi è il corpo fisico lì?
	var spazio := get_viewport().get_world_3d().direct_space_state
	var palla := SphereShape3D.new()
	palla.radius = 0.6
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = palla
	q.collision_mask = 0xFFFF
	for c in [Vector3(175.0, 1.0, 150.0), Vector3(178.0, 1.0, 154.0)]:
		q.transform = Transform3D(Basis(), c)
		for h in spazio.intersect_shape(q, 8):
			var col: Object = h.get("collider")
			print("    corpo vicino a %s: %s (%s) script %s" % [str(c), str(col), (col as Node).get_path() if col is Node else "", str((col as Object).get_script().resource_path) if col.get_script() else "-"])
	const Ost2 := preload("res://scripts/ostacoli.gd")
	for z in range(128, 168, 2):
		var qq := Vector3(168.5, 0, float(z) + 0.5)
		var i: int = Ost2._chi(qq, 0.55)
		var b := Citta.dint_ô_palazzo(qq, 0.8)
		if i >= 0 or b:
			var ss: Array = Ost2.tutte()[i] if i >= 0 else []
			print("    chiuso %s: palazzo %s cosa %s" % [str(qq), str(b), str(ss)])
	print("=== storte: 0 ===")
	get_tree().quit()
