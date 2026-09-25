extends Node
## Che forme solide ci stanno attorno a un punto (SONDA_X, SONDA_Z).

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(60):
		await get_tree().process_frame
	var p := Vector3(float(OS.get_environment("SONDA_X")), 0.8, float(OS.get_environment("SONDA_Z")))
	var spazio := get_viewport().get_world_3d().direct_space_state
	var palla := SphereShape3D.new()
	palla.radius = float(OS.get_environment("SONDA_R"))
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = palla
	q.collision_mask = 0xFFFF
	q.transform = Transform3D(Basis(), p)
	for h in spazio.intersect_shape(q, 32):
		var col: Object = h.get("collider")
		var sid: int = int(h.get("shape"))
		var desc := str(col)
		if col is CollisionObject3D:
			var owner_id: int = (col as CollisionObject3D).shape_find_owner(sid)
			var cs: Node = (col as CollisionObject3D).shape_owner_get_owner(owner_id)
			if cs is CollisionShape3D:
				var f := cs as CollisionShape3D
				var dim := ""
				if f.shape is BoxShape3D:
					dim = str((f.shape as BoxShape3D).size)
				desc = "%s/%s layer %d at %s size %s" % [str((col as Node).get_parent().name), str((col as Node).name), (col as CollisionObject3D).collision_layer, str(f.global_position.snapped(Vector3.ONE * 0.1)), dim]
		print("  ", desc)
	for n in get_tree().get_nodes_in_group("cars"):
		if (n as Node3D).global_position.distance_to(p) < 8.0:
			print("  CAR ", n.name, " ", (n as Node3D).global_position.round(), " stato ", n.get("state"))
	print("=== storte: 0 ===")
	get_tree().quit()
