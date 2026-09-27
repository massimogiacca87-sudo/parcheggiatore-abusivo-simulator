extends Node
## 'E quatte piazze viste 'a coppa (0.64): dove stanno i posti auto, le
## bancarelle, la cornetteria, lo stadio. Serve a mettere i posti nuovi
## dove ci sta spazio davvero. `SOLO=mercato,cornetteria` per sceglierne
## alcune; le foto vanno in /tmp/alto_<zona>.png.

var _cam: Camera3D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(90):
		await get_tree().process_frame
	for n in _tutte(get_tree().root):
		if n is CanvasLayer:
			(n as CanvasLayer).visible = false
	get_tree().paused = false
	GameManager.start_shift()
	GameManager.tipo_giornata = "normale"
	GameManager.intro_active = false
	GameManager.shift_time_left = GameManager.shift_duration * 0.9
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	pl.global_position = Vector3(90, 1, 88)
	_cam = Camera3D.new()
	_cam.fov = 60
	get_tree().root.add_child(_cam)
	await get_tree().create_timer(3.0).timeout
	var solo: String = OS.get_environment("SOLO")
	for z in load("res://scripts/citta_3d.gd").ZONE:
		var id := str(z["id"])
		if solo != "" and not (id in solo.split(",")):
			continue
		var r: Array = z["rect"]
		var c := Vector3((r[0] + r[2]) * 0.5, 0.0, (r[1] + r[3]) * 0.5)
		var lato: float = maxf(float(r[2] - r[0]), float(r[3] - r[1]))
		var h: float = lato * 0.95 + 6.0
		_cam.look_at_from_position(c + Vector3(0, h, 0.01), c, Vector3(0, 0, -1))
		_cam.current = true
		var posti := 0
		for s in get_tree().get_nodes_in_group("parking_spots"):
			var p: Vector3 = (s as Node3D).global_position
			if p.x >= r[0] and p.x <= r[2] and p.z >= r[1] and p.z <= r[3]:
				posti += 1
		print("  %s: rect %s, %d posti" % [id, str(r), posti])
		await _scatta("alto_" + id)
	get_tree().quit()


func _tutte(n: Node) -> Array:
	var fore: Array = [n]
	for c in n.get_children():
		fore.append_array(_tutte(c))
	return fore


func _scatta(nome: String) -> void:
	for _i in range(3):
		await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/%s.png" % nome)
	print("  foto: /tmp/%s.png" % nome)
