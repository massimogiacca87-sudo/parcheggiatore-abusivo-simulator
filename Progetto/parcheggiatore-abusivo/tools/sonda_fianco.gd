extends SceneTree
## Per ogni fascia di z, quanto è larga la macchina a una certa altezza.

func _initialize() -> void:
	await process_frame
	for nome in OS.get_environment("SONDA").split(","):
		var n: Node3D = (load("res://assets/models/%s.scn" % nome) as PackedScene).instantiate()
		root.add_child(n)
		await process_frame
		var y0 := float(OS.get_environment("Y0"))
		var y1 := float(OS.get_environment("Y1"))
		var fasce := {}
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var m: MeshInstance3D = mi
			if m.mesh == null or not str(m.name).begins_with("body"):
				continue
			var t: Transform3D = n.global_transform.affine_inverse() * m.global_transform
			for i in m.mesh.get_surface_count():
				var v: PackedVector3Array = m.mesh.surface_get_arrays(i)[Mesh.ARRAY_VERTEX]
				for x in v:
					var p: Vector3 = t * x
					if p.y < y0 or p.y > y1:
						continue
					var k := int(floor(p.z / 0.25))
					fasce[k] = maxf(float(fasce.get(k, 0.0)), absf(p.x))
		var ks := fasce.keys()
		ks.sort()
		var s := ""
		for k in ks:
			s += " %.2f:%.2f" % [k * 0.25, fasce[k]]
		print(nome, " y ", y0, "-", y1, s)
		n.queue_free()
	quit()
