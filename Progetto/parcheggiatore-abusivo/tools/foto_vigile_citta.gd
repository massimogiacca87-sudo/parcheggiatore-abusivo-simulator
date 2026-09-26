extends Node
## Fotografia (0.63): il vigile nella città vera, visto da vicino.
## Per ogni vigile: quante mesh visibili ha, dove sta, e una foto da 5 m.
## `/tmp/vig_N.png`.

var _cam: Camera3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(60):
		await get_tree().process_frame
	# Il gioco vero: si schiaccia un tasto finché non parte il turno (la
	# volata compresa), e intanto si contano i vigili.
	var f := 0
	while not GameManager.shift_active and f < 2400:
		if f % 40 == 0:
			for c in get_tree().current_scene.get_children():
				if c.has_method("_on_menu_gioca") and bool(c.get("_pronto")):
					print("  gioca! a f%d" % f)
					c._on_menu_gioca()
		if f % 100 == 0:
			print("f%d vigili=%d ora=%.2f pausa=%s" % [f, get_tree().get_nodes_in_group("vigili").size(), GameManager.ora_d_o_juorno(), str(get_tree().paused)])
		await get_tree().process_frame
		f += 1
	print("TURNO PARTITO a f%d, vigili=%d ora=%.2f" % [f, get_tree().get_nodes_in_group("vigili").size(), GameManager.ora_d_o_juorno()])
	for _i in range(60):
		await get_tree().process_frame
	get_tree().paused = false
	_cam = Camera3D.new()
	_cam.fov = 55
	get_tree().current_scene.add_child(_cam)
	for c in get_tree().current_scene.get_children():
		if c is CanvasLayer:
			c.visible = false
	_cam.current = true
	var vv := get_tree().get_nodes_in_group("vigili")
	print("VIGILI: %d" % vv.size())
	var n := 0
	for v in vv:
		var v3 := v as Node3D
		var mesh := 0
		var vis := 0
		for m in v3.find_children("*", "MeshInstance3D", true, false):
			mesh += 1
			if (m as MeshInstance3D).is_visible_in_tree():
				vis += 1
		print("  %s pos=%s visibile=%s mesh=%d vis=%d scala=%s" % [v3.get_parent().name,
			str(v3.global_position), str(v3.is_visible_in_tree()), mesh, vis,
			str(v3.get_child(0).scale if v3.get_child_count() > 0 else "")])
		get_tree().paused = true
		var fw: Vector3 = -v3.global_transform.basis.z
		var occhio: Vector3 = v3.global_position + Vector3(3.0, 1.7, 4.0)
		_cam.global_position = occhio
		_cam.look_at(v3.global_position + Vector3(0, 1.0, 0))
		for _i in range(6):
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("/tmp/vig_%d.png" % n)
		n += 1
		get_tree().paused = false
	print("=== fernuto ===")
	get_tree().quit()
