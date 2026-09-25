extends Node
## 'O vascio da dinto: la stanza vista da due angoli, prima col fondale
## acceso e poi spento, per capire se le colline lontane ci passano in mezzo.

var _t := 0.0
var _n := 0
var _pronto := false
var _cam: Camera3D = null
var _dentro: Node3D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(d: float) -> void:
	if not _pronto:
		_pronto = true
		for n in _tutte(get_tree().root):
			if n is CanvasLayer and n.has_method("_on_menu_gioca"):
				(n as CanvasLayer).visible = false
				break
		get_tree().paused = false
		GameManager.giornata = 3
		GameManager.start_shift()
		GameManager.intro_active = false
		_cam = Camera3D.new()
		_cam.fov = 70
		get_tree().root.add_child(_cam)
		_cam.current = true
		return
	_t += d
	if _t < 0.8:
		return
	_t = 0.0
	_n += 1
	if _dentro == null:
		var v := get_tree().get_first_node_in_group("vascio")
		if v:
			_dentro = v.get_node_or_null("Dentro")
			if _dentro:
				print("  DENTRO a ", _dentro.global_position)
	if _dentro == null:
		return
	var c: Vector3 = _dentro.global_position
	var scatti := [
		["a", Vector3(2.4, 1.6, 1.9), Vector3(-1.05, 0.8, 1.62), true],
		["b", Vector3(-2.2, 1.6, -1.8), Vector3(1.5, 0.8, 1.6), true],
		["c", Vector3(0.5, 1.6, -2.0), Vector3(2.9, 0.9, 1.0), true],
		["a_senza", Vector3(2.4, 1.6, 1.9), Vector3(-1.05, 0.8, 1.62), false],
		["b_senza", Vector3(-2.2, 1.6, -1.8), Vector3(1.5, 0.8, 1.6), false],
		["c_senza", Vector3(0.5, 1.6, -2.0), Vector3(2.9, 0.9, 1.0), false],
		# 0.60: la roba nova — 'a mensola cu 'a fotografia, 'a presa e
		# 'o 'nterruttore; 'o lietto cu 'o quaderno; 'a ragnatela.
		["d", Vector3(0.0, 1.5, -0.4), Vector3(3.1, 1.2, -0.3), true],
		["e", Vector3(0.6, 1.7, 0.4), Vector3(2.1, 0.6, -1.0), true],
		["f", Vector3(0.5, 1.5, 0.8), Vector3(-3.0, 2.3, -2.4), true],
	]
	var i: int = (_n - 2) / 2
	if _n < 2:
		return
	if i >= scatti.size():
		get_tree().quit()
		return
	var s: Array = scatti[i]
	if _n % 2 == 0:
		var citta := get_tree().get_first_node_in_group("citta")
		for nome in ["ColineLontane", "CaseLontane", "LuciLontane"]:
			var nd = citta.get_node_or_null(nome)
			if nd:
				nd.visible = bool(s[3])
		_cam.look_at_from_position(c + (s[1] as Vector3), c + (s[2] as Vector3), Vector3.UP)
		_cam.current = true
	else:
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		if str(s[0]) == "a":
			_sonda_raggio(Vector2(1000, 400))
			_sonda_raggio(Vector2(1150, 150))
		var img := get_viewport().get_texture().get_image()
		img.save_png("/tmp/vascio_%s.png" % str(s[0]))
		print("  foto: /tmp/vascio_%s.png" % str(s[0]))


func _tutte(n: Node) -> Array:
	var fore: Array = [n]
	for c in n.get_children():
		fore.append_array(_tutte(c))
	return fore


## Che cosa sta sul raggio che passa per un pixel: la prima mesh che la
## scatola tocca è quella che copre la fotografia.
func _sonda_raggio(px: Vector2) -> void:
	var o: Vector3 = _cam.project_ray_origin(px)
	var dir: Vector3 = _cam.project_ray_normal(px)
	print("  raggio da ", o, " verso ", dir)
	var visti := {}
	var dist := 0.05
	while dist < 12.0:
		var q: Vector3 = o + dir * dist
		for x in _tutte(get_tree().root):
			if x is GeometryInstance3D and (x as GeometryInstance3D).is_visible_in_tree():
				var g := x as GeometryInstance3D
				if visti.has(g):
					continue
				var box: AABB = g.global_transform * g.get_aabb()
				if box.size.length() > 200.0:
					continue
				if box.has_point(q):
					visti[g] = true
					print("    a %.2f m: %s  box %s + %s" % [dist, str(g.get_path()),
						str(box.position.snapped(Vector3.ONE * 0.01)), str(box.size.snapped(Vector3.ONE * 0.01))])
		dist += 0.1
