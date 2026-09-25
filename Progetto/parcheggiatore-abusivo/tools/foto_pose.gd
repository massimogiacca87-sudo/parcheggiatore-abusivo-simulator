extends Node
## Fote d''e pose (0.59): chi prima stava in croce, visto con l'occhio.
##
## `prova_croce` dice che nessuno ha più le braccia stese di lato. Non dice
## se chi sta sulla Vespa ci sta **sopra** o dentro, né se i vecchi della
## scopa hanno il sedere sulla sedia o due palmi sotto. Quello lo dice la
## fotografia.

var _t := 0.0
var _n := 0
var _pronto := false
var _cam: Camera3D = null
var _moto: Node3D = null


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
		GameManager.tipo_giornata = "normale"
		GameManager.intro_active = false
		GameManager.shift_time_left = GameManager.shift_duration * 0.88
		_cam = Camera3D.new()
		get_tree().root.add_child(_cam)
		_cam.current = true
		return
	_t += d
	if _t < 1.0:
		return
	_t = 0.0
	_n += 1
	match _n:
		1: print("  se aspetta ca 'a città s'apara")
		2: _guarda_â_vespa()
		3: await _scatta("vespa_citta")
		4: _guarda_ô_motorino()
		5: await _scatta("motorino_piazza")
		6: _guarda_â_scopa()
		7: await _scatta("scopa")
		8: _guarda_ô_gruppo("signore", 2.6, 1.5)
		9: await _scatta("signora")
		10: _guarda_ô_gruppo("vigili", 3.0, 1.6)
		11: await _scatta("vigile")
		12: _guarda_ô_tavulo()
		13: await _scatta("tavulo_scopa")
		_: get_tree().quit()


func _guarda_â_vespa() -> void:
	var m: Node3D = get_tree().get_first_node_in_group("motorini_citta")
	if m == null:
		print("  NUN CE STANNO VESPE")
		return
	# Si ferma a metà strada e si fa vedere.
	m.set("_attesa", 0.0)
	m.set("_t", 0.5)
	m.set("_velocita", 0.0001)
	var mezzo: Node3D = m.get("_mezzo")
	if mezzo == null:
		return
	mezzo.visible = true
	await get_tree().process_frame
	var p: Vector3 = mezzo.global_position
	var lato: Vector3 = mezzo.global_transform.basis.x
	print("  vespa a %s" % str(p.round()))
	_mira(p + lato * 2.6 + Vector3(0, 1.2, -0.4), p + Vector3(0, 0.85, 0))


func _guarda_ô_motorino() -> void:
	var z := get_tree().root.find_child("ZoneVicolo", true, false) as Node3D
	if z == null:
		print("  NUN CE STA 'A PIAZZA")
		return
	z.call("_spawn_motorino")
	await get_tree().process_frame
	var ms := get_tree().get_nodes_in_group("motorini")
	if ms.is_empty():
		print("  'O MOTORINO NUN È NATO")
		return
	_moto = ms[ms.size() - 1]
	_moto.set("_warning", 0.0)
	var w: float = float(z.get("width"))
	_moto.global_position.x = z.global_position.x + w * 0.5
	await get_tree().process_frame
	await get_tree().process_frame
	_moto.process_mode = Node.PROCESS_MODE_DISABLED
	var p: Vector3 = _moto.global_position
	_mira(p + Vector3(0.0, 1.3, 3.0), p + Vector3(0, 0.9, 0))


func _guarda_â_scopa() -> void:
	var s: Node3D = get_tree().get_first_node_in_group("scopa")
	if s == null:
		print("  NUN CE STA 'A SCOPA")
		return
	var p: Vector3 = s.global_position
	print("  scopa a %s" % str(p.round()))
	_mira(p + Vector3(2.4, 1.55, 1.6), p + Vector3(0, 0.55, 0))


func _guarda_ô_tavulo() -> void:
	var s: Node3D = get_tree().get_first_node_in_group("tavoli_scopa")
	if s == null:
		print("  NUN CE STA 'O TAVULO")
		return
	var p: Vector3 = s.global_position
	_mira(p + Vector3(2.2, 1.5, 2.0), p + Vector3(0, 0.6, 0.4))


func _guarda_ô_gruppo(gruppo: String, lontano: float, alto: float) -> void:
	var s: Node3D = get_tree().get_first_node_in_group(gruppo)
	if s == null:
		print("  NUN CE STA NISCIUNO 'E %s" % gruppo)
		return
	var p: Vector3 = s.global_position
	var f: Vector3 = -s.global_transform.basis.z
	print("  %s a %s" % [gruppo, str(p.round())])
	_mira(p + f * lontano + Vector3(0.6, alto, 0.0), p + Vector3(0, 1.0, 0))


func _tutte(n: Node) -> Array:
	var fore: Array = [n]
	for c in n.get_children():
		fore.append_array(_tutte(c))
	return fore


func _mira(occhio: Vector3, meta: Vector3) -> void:
	_cam.look_at_from_position(occhio, meta, Vector3.UP)
	_cam.current = true


func _scatta(nome: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/59_%s.png" % nome)
	print("  foto: /tmp/59_%s.png" % nome)
