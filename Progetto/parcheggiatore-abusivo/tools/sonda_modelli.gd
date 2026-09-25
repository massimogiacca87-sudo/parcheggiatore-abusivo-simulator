extends SceneTree
## Stampa misure e materiali dei modelli dati in SONDA="a,b,c".

func _initialize() -> void:
	await process_frame
	for nome in OS.get_environment("SONDA").split(","):
		var p := "res://assets/models/%s.scn" % nome
		if not ResourceLoader.exists(p):
			p = "res://assets/models/%s.mesh" % nome
		var r = load(p)
		var n: Node3D
		if r is PackedScene:
			n = (r as PackedScene).instantiate()
		else:
			var mi := MeshInstance3D.new()
			mi.mesh = r
			n = mi
		root.add_child(n)
		await process_frame
		var tot := AABB()
		var primo := true
		var righe: Array = []
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var m: MeshInstance3D = mi
			var t: Transform3D = n.global_transform.affine_inverse() * m.global_transform
			for i in m.mesh.get_surface_count():
				var arr: Array = m.mesh.surface_get_arrays(i)
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var a := AABB(t * v[0], Vector3.ZERO)
				for x in v:
					a = a.expand(t * x)
				var mat: Material = m.get_active_material(i)
				var mn := mat.resource_name if mat != null else "-"
				righe.append("   %-18s %-22s pos %s size %s" % [m.name, mn, str(a.position.snapped(Vector3.ONE*0.01)), str(a.size.snapped(Vector3.ONE*0.01))])
				if primo:
					tot = a
					primo = false
				else:
					tot = tot.merge(a)
		print("%s: aabb pos %s size %s" % [nome, str(tot.position.snapped(Vector3.ONE*0.01)), str(tot.size.snapped(Vector3.ONE*0.01))])
		for r2 in righe:
			print(r2)
		n.queue_free()
	quit()
