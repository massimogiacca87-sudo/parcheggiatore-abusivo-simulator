extends Node
## Come sceglie i varchi e la coda un posteggio (0.64). `ZONA=cornetteria`:
## stampa ogni varco provato (libero o no), ogni punto di coda (libero, sulle
## strisce) e quello che è stato scelto. Headless.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(120):
		await get_tree().process_frame
	get_tree().paused = false
	var z := OS.get_environment("ZONA")
	if z == "":
		z = "cornetteria"
	GameManager.zone_mie = ["piazza", "stadio", "mercato", "cornetteria"]
	GameManager.start_shift()
	await get_tree().create_timer(2.0).timeout
	var po = get_tree().root.find_child("Posteggio_" + z, true, false)
	var r: Array = po.rect
	var x0: float = r[0]
	var z0: float = r[1]
	var x1: float = r[2]
	var z1: float = r[3]
	print("rect ", r)
	for ix in range(5):
		for iz in range(4):
			var p := Vector3(lerpf(x0 + 6.0, x1 - 6.0, (float(ix) + 0.5) / 5.0), 0.0,
				lerpf(z0 + 5.0, z1 - 2.8, (float(iz) + 0.5) / 4.0))
			var cosa := ""
			var mondo: World3D = po.get_world_3d()
			var q := PhysicsShapeQueryParameters3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(2.4, 1.4, 4.8)
			q.shape = box
			q.transform = Transform3D(Basis(), Vector3(p.x, 0.8, p.z))
			q.collision_mask = 1 | 4
			for h in mondo.direct_space_state.intersect_shape(q, 8):
				var c = h.get("collider")
				cosa += " [%s %s]" % [c.name, c.get_parent().name if c.get_parent() else ""]
			print("coda %s libero=%s strisce=%s%s" % [str(p), str(po._libero(p)),
				str(po._ncopp_a_nu_posto(p)), cosa])
	var sp_zona: Array = []
	for s in get_tree().get_nodes_in_group("parking_spots"):
		if str(s.get("zona_id")) == z:
			sp_zona.append((s as Node3D).global_position)
	print("posti: ", sp_zona)
	var codine: Array = []
	for ix in range(5):
		for iz in range(4):
			var p2 := Vector3(lerpf(x0 + 6.0, x1 - 6.0, (float(ix) + 0.5) / 5.0), 0.0,
				lerpf(z0 + 5.0, z1 - 2.8, (float(iz) + 0.5) / 4.0))
			if po._libero(p2) and not po._ncopp_a_nu_posto(p2):
				codine.append(p2)
	for fuori in [4.0, 8.0]:
		for t in [0.5, 0.3, 0.7, 0.15, 0.85]:
			for v in [Vector3(x0 - fuori, 0, lerpf(z0, z1, t)), Vector3(x1 + fuori, 0, lerpf(z0, z1, t)),
					Vector3(lerpf(x0, x1, t), 0, z0 - fuori), Vector3(lerpf(x0, x1, t), 0, z1 + fuori)]:
				var lib: bool = po._libero(v)
				var rag := []
				for c in codine:
					rag.append("%s:%s/%s" % [str(c), "via" if po._via_libera(v, c) else "-",
						"strisce" if po._passa_pe_nu_posto(v, c, sp_zona) else "ok"])
				print("varco %s libero=%s  %s" % [str(v), str(lib), " ".join(rag)])
	po._scegli_varchi()
	print("entrata ", po._entrata, " uscita ", po._uscita, " coda ", po._coda)
	print("=== fernuto ===")
	get_tree().quit()
