extends SceneTree
## I vertici sopra a una quota (per trovare 'o cartello d''o taxi).

func _initialize() -> void:
	await process_frame
	var nome := OS.get_environment("SONDA")
	var y0 := float(OS.get_environment("Y0"))
	var n: Node3D = (load("res://assets/models/%s.scn" % nome) as PackedScene).instantiate()
	root.add_child(n)
	await process_frame
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		if m.mesh == null:
			continue
		var t: Transform3D = n.global_transform.affine_inverse() * m.global_transform
		for i in m.mesh.get_surface_count():
			var v: PackedVector3Array = m.mesh.surface_get_arrays(i)[Mesh.ARRAY_VERTEX]
			var box := AABB()
			var primo := true
			for x in v:
				var p: Vector3 = t * x
				if p.y < y0:
					continue
				if primo:
					box = AABB(p, Vector3.ZERO)
					primo = false
				else:
					box = box.expand(p)
			if not primo:
				var mat: Material = m.get_active_material(i)
				print("%s %s: %s  size %s" % [m.name, mat.resource_name if mat else "-", str(box.position.snapped(Vector3.ONE*0.01)), str(box.size.snapped(Vector3.ONE*0.01))])
	quit()
