extends Node
## Che c'è dentro a un posto auto? (0.64) `PX=… PZ=…`: stampa i corpi solidi
## che toccano la sagoma di un posto in quel punto, con la catena dei padri.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(120):
		await get_tree().process_frame
	get_tree().paused = false
	GameManager.start_shift()
	await get_tree().create_timer(2.0).timeout
	var px := float(OS.get_environment("PX"))
	var pz := float(OS.get_environment("PZ"))
	var spazio := get_viewport().find_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.9, 1.0, 4.0)
	q.shape = box
	q.transform = Transform3D(Basis(), Vector3(px, 0.88, pz))
	q.collision_mask = 1
	for h in spazio.intersect_shape(q, 8):
		var c: Node = h.get("collider")
		var catena := []
		var n: Node = c
		while n != null and catena.size() < 6:
			catena.append("%s(%s)" % [n.name, n.get_class()])
			n = n.get_parent()
		var forma := ""
		for ch in c.get_children():
			if ch is CollisionShape3D and (ch as CollisionShape3D).shape is BoxShape3D:
				forma = "box %s a %s" % [str(((ch as CollisionShape3D).shape as BoxShape3D).size),
					str((ch as Node3D).global_position)]
		print("  %s  %s  pos %s" % [" <- ".join(catena), forma, str((c as Node3D).global_position)])
	print("=== fernuto ===")
	get_tree().quit()
