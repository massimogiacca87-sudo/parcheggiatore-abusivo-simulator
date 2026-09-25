extends Node
## Perché 'e piazze nove nun trovano 'a coda (0.61).
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(120):
		await get_tree().physics_frame
	var mondo := get_viewport().get_world_3d()
	var citta = load("res://scripts/citta_3d.gd")
	for z in citta.ZONE:
		var r: Array = z["rect"]
		print("== ", z["id"], " ", r)
		var spots := []
		for s in get_tree().get_nodes_in_group("parking_spots"):
			var p: Vector3 = (s as Node3D).global_position
			if p.x >= r[0] - 6 and p.x <= r[2] + 6 and p.z >= r[1] - 6 and p.z <= r[3] + 6:
				spots.append(p.round())
		print("  posti: ", spots.size(), " ", spots)
		for ix in range(5):
			for iz in range(3):
				var p := Vector3(lerpf(r[0] + 6.0, r[2] - 6.0, (float(ix) + 0.5) / 5.0), 0.0,
					lerpf(r[1] + 5.0, r[3] - 5.0, (float(iz) + 0.5) / 3.0))
				var q := PhysicsShapeQueryParameters3D.new()
				var box := BoxShape3D.new()
				box.size = Vector3(2.4, 1.4, 4.8)
				q.shape = box
				q.transform = Transform3D(Basis(), Vector3(p.x, 0.8, p.z))
				q.collision_mask = 1 | 4
				var hit := mondo.direct_space_state.intersect_shape(q, 4)
				var chi := []
				for h in hit:
					var c = h["collider"]
					chi.append(str(c.name) + "@" + str(c.get_parent().name if c.get_parent() else ""))
				print("   ", p.round(), " ", "LIBERO" if hit.is_empty() else str(chi))
	get_tree().quit()
