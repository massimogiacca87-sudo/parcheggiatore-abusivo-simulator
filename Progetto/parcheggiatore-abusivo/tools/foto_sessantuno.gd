extends Node
## 'E fote d''a 0.61: Gennarino 'o Nuovo, 'o turista spierzo, 'o panaro.
## Si guardano **nella città vera**, a mezza giornata.

var _cam: Camera3D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(90):
		await get_tree().process_frame
	for n in _tutte(get_tree().root):
		if n is CanvasLayer and n != null:
			(n as CanvasLayer).visible = false
	get_tree().paused = false
	GameManager.giornata = 3
	GameManager.start_shift()
	GameManager.tipo_giornata = "normale"
	GameManager.intro_active = false
	GameManager.shift_time_left = GameManager.shift_duration * 0.88
	GameManager.zone_mie = ["piazza", "stadio", "mercato", "cornetteria"]
	GameManager.zona_corrente = "piazza"
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	pl.global_position = Vector3(31, 1, 30)
	_cam = Camera3D.new()
	_cam.fov = 62
	get_tree().root.add_child(_cam)

	var g = get_tree().root.find_child("GennarinoONuovo", true, false)
	g.set("_visto_oggi", GameManager.giornata)
	g.call("_arriva")
	var t = get_tree().root.find_child("TuristaSpierzo", true, false)
	t.set("_visto_oggi", GameManager.giornata)
	t.call("_compare")
	var p = get_tree().root.find_child("Panaro", true, false)
	p.set("_giornata", GameManager.giornata)
	p.set("_richiesta", p.RICHIESTE[0])
	p.set("_meta_cesto", 0.0)
	await get_tree().create_timer(9.0).timeout

	print("  gennarino a %s fase %d" % [str((g as Node3D).global_position), int(g.get("_fase"))])
	(g as Node3D).global_position = Vector3(27, 0.2, 33)
	g.set("_fase", 2)
	g.set("_cerca", 99.0)
	await get_tree().create_timer(0.5).timeout
	await _guarda(g as Node3D, "gennarino", 3.2, 1.5)
	await _guarda(t as Node3D, "turista", 3.4, 1.5)
	# 'O panaro: da sotto, guardando in su.
	var pp: Vector3 = (p as Node3D).global_position
	var fuori: Vector3 = (p as Node3D).global_transform.basis.z
	print("  panaro a %s, fuori %s" % [str(pp), str(fuori)])
	_cam.look_at_from_position(pp + fuori * 5.5 + Vector3(0, 1.4, 0),
		pp + fuori * 0.7 + Vector3(0, 3.2, 0), Vector3.UP)
	_cam.current = true
	await _scatta("panaro")
	get_tree().quit()


func _guarda(n: Node3D, nome: String, d: float, h: float) -> void:
	var v: Node3D = n.get("_visual")
	var f: Vector3 = -v.global_transform.basis.z
	f.y = 0.0
	if f.length() < 0.1:
		f = Vector3(0, 0, 1)
	f = f.normalized().rotated(Vector3.UP, 0.4)
	var p: Vector3 = n.global_position
	# L'occhio non deve cadere dentro a un palazzo: si gira finché è fuori.
	var Citta = load("res://scripts/citta_3d.gd")
	for k in range(16):
		if not Citta.dint_ô_palazzo(p + f * d, 0.5):
			break
		f = f.rotated(Vector3.UP, TAU / 16.0)
	_cam.look_at_from_position(p + f * d + Vector3(0, h, 0), p + Vector3(0, 1.0, 0),
		Vector3.UP)
	_cam.current = true
	await _scatta(nome)


func _tutte(n: Node) -> Array:
	var fore: Array = [n]
	for c in n.get_children():
		fore.append_array(_tutte(c))
	return fore


func _scatta(nome: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/61_%s.png" % nome)
	print("  foto: /tmp/61_%s.png" % nome)
