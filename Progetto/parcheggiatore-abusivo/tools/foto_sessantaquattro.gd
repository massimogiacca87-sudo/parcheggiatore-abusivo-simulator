extends Node
## 'E fote d''a 0.64: 'o parchimetro sano e sfasciato, 'e strisce blu
## dall'alto, e 'o cronometro d''a sfida a schermo. `SOLO=parchimetro,blu,
## sfida` per farne solo alcune. PNG in /tmp/64_*.png. 'O Rre da tutti i
## lati sta in `foto_modello.gd`.

var _cam: Camera3D = null
var _solo: PackedStringArray = []
## I pannelli che erano accesi prima della foto: si riaccendono solo quelli
## (prima si riaccendeva tutto, pure la schermata del titolo).
var _accesi: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(90):
		await get_tree().process_frame
	var s := OS.get_environment("SOLO")
	if s != "":
		_solo = s.split(",")
	_nascondi_ui(true)
	get_tree().paused = false
	GameManager.giornata = 3
	GameManager.start_shift()
	GameManager.tipo_giornata = "normale"
	GameManager.intro_active = false
	GameManager.shift_time_left = GameManager.shift_duration * 0.8
	GameManager.re_prossimo_juorno = 99
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	pl.global_position = Vector3(31, 1, 36)
	_cam = Camera3D.new()
	_cam.fov = 60
	get_tree().root.add_child(_cam)
	await get_tree().create_timer(2.0).timeout

	if _vuoi("parchimetro") or _vuoi("blu"):
		GameManager.giornata = 4
		GameManager._forse_strisce_blu("piazza")
		await get_tree().create_timer(1.5).timeout
		var pm: Array = get_tree().get_nodes_in_group("parchimetri")
		if pm.size() > 0 and _vuoi("parchimetro"):
			var p0: Node3D = pm[pm.size() - 1]
			var d: Vector3 = p0.global_transform.basis.z
			_cam.fov = 40
			_scatta_da(p0.global_position + d * 2.2 + Vector3(0.6, 1.5, 0),
				p0.global_position + Vector3(0, 1.2, 0), "parchimetro")
			await _scatta("parchimetro")
			_scatta_da(p0.global_position + d * 0.9 + Vector3(0, 1.45, 0),
				p0.global_position + Vector3(0, 1.4, 0), "parchimetro_display")
			await _scatta("parchimetro_display")
			for _k in range(4):
				p0.receive_punch(2)
			await get_tree().create_timer(0.25).timeout
			_scatta_da(p0.global_position + d * 2.2 + Vector3(0.6, 1.5, 0),
				p0.global_position + Vector3(0, 1.1, 0), "parchimetro_sfasciato")
			await _scatta("parchimetro_sfasciato")
			await get_tree().create_timer(2.5).timeout
			_scatta_da(p0.global_position + d * 2.2 + Vector3(0.6, 1.5, 0),
				p0.global_position + Vector3(0, 1.1, 0), "parchimetro_sfasciato_dopo")
			await _scatta("parchimetro_sfasciato_dopo")
			_cam.fov = 60
		if _vuoi("blu"):
			_scatta_da(Vector3(31, 16, 50), Vector3(31, 0, 28), "strisce_blu")
			await _scatta("strisce_blu")
			var spot: Node3D = null
			for sp in get_tree().get_nodes_in_group("parking_spots"):
				if str(sp.get("zona_id")) == "piazza" and sp.get("blu") == true and sp.get("is_free") == true:
					spot = sp
					break
			if spot != null:
				GameManager.pittura = 6
				pl.global_position = spot.global_position + Vector3(-1.8, 0.2, 0)
				spot.player_interact()
				await get_tree().create_timer(1.2).timeout
				_scatta_da(spot.global_position + Vector3(-3.5, 2.6, 2.5),
					spot.global_position, "pittanno")
				await _scatta("pittanno")

	if _vuoi("panaro"):
		# 'O balcone 'e Donna Filumena (0.64): quello vero della città, col
		# panaro calato.
		var pan = get_tree().root.find_child("Panaro", true, false)
		if pan != null:
			pan.set("_richiesta", pan.RICHIESTE[0])
			pan.set("_meta_cesto", 0.0)
			(pan.get("_nonna") as Node3D).visible = true
			await get_tree().create_timer(7.0).timeout
			var pp: Vector3 = (pan as Node3D).global_position
			var fuori: Vector3 = (pan as Node3D).global_transform.basis.z
			var lato: Vector3 = Vector3(fuori.z, 0, -fuori.x)
			_cam.fov = 55
			_scatta_da(pp + fuori * 6.5 + lato * 1.5 + Vector3(0, 1.6, 0),
				pp + fuori * 0.8 + Vector3(0, 5.0, 0), "panaro")
			await _scatta("panaro")
			_cam.fov = 40
			_scatta_da(pp + fuori * 4.0 + lato * 3.0 + Vector3(0, 7.5, 0),
				pp + fuori * 0.6 + Vector3(0, 8.6, 0), "panaro_balcone")
			await _scatta("panaro_balcone")
			_cam.fov = 60

	if _vuoi("pioggia"):
		# 'E pozzanghere d''o browser (0.64): solo col renderer Compatibility
		# (questo script gira con opengl3, cioè come la build web).
		GameManager.tipo_giornata = "pioggia"
		var jv = load("res://scripts/jurnata_vista.gd").new()
		jv.name = "JurnataVistaFoto"
		get_tree().root.find_child("Citta", true, false).add_child(jv)
		await get_tree().create_timer(2.0).timeout
		var pw = jv.find_child("PozzangheraWeb", true, false)
		print("  pozzanghere web: %s" % ("nisciuna" if pw == null
			else str((pw as MultiMeshInstance3D).multimesh.instance_count)))
		_cam.fov = 60
		if pw != null:
			var mm: MultiMesh = (pw as MultiMeshInstance3D).multimesh
			var t0: Transform3D = mm.get_instance_transform(0)
			print("  prima pozzanghera: %s, visibile %s, dentro %s" % [str(t0.origin),
				str((pw as Node3D).is_visible_in_tree()), str((pw as Node3D).global_transform.origin)])
			# Una di quelle della piazza di casa, da un metro e settanta.
			var t1: Transform3D = mm.get_instance_transform(mm.instance_count / 2)
			for i in range(mm.instance_count):
				var o: Vector3 = mm.get_instance_transform(i).origin
				if o.x > 18.0 and o.x < 44.0 and o.z > 38.0 and o.z < 58.0:
					t1 = mm.get_instance_transform(i)
					break
			_scatta_da(t1.origin + Vector3(0.0, 1.7, 4.5), t1.origin, "pioggia_vicino")
			await _scatta("pioggia_vicino")
		_scatta_da(Vector3(31, 2.2, 52), Vector3(31, 0, 36), "pioggia")
		await _scatta("pioggia")
		_scatta_da(Vector3(78, 2.0, 30), Vector3(80, 0, 50), "pioggia_corso")
		await _scatta("pioggia_corso")
		GameManager.tipo_giornata = "normale"
		jv.queue_free()

	if _vuoi("sfida"):
		GameManager.strisce_blu.clear()
		get_tree().call_group("parking_spots", "metti_blu", false)
		var re2 = get_tree().root.find_child("ReParcheggi", true, false)
		pl.global_position = Vector3(26, 0.3, 48)
		GameManager.re_prossimo_juorno = GameManager.giornata
		await get_tree().create_timer(0.8).timeout
		re2.call("_mostra", Vector3(29, 0, 44))
		re2.set("stato", 2)
		re2.call("_comincia")
		await get_tree().create_timer(4.2).timeout
		re2.set("_contate", 2)
		re2.get("_hud").conta(2)
		re2.set("_t", 43.4)
		await get_tree().create_timer(0.6).timeout
		_nascondi_ui(false)
		var cam_pl = pl.get("camera")
		if cam_pl != null:
			(cam_pl as Camera3D).current = true
			pl.rotation.y = 0.0
		await get_tree().create_timer(0.4).timeout
		await _scatta("sfida_hud")
		re2.set("_t", 8.4)
		await get_tree().create_timer(1.3).timeout
		await _scatta("sfida_hud_fine")
	get_tree().quit()


func _vuoi(n: String) -> bool:
	return _solo.is_empty() or n in _solo


func _nascondi_ui(si: bool) -> void:
	if not si:
		for n in _accesi:
			if is_instance_valid(n) and not _schermata(n):
				(n as CanvasLayer).visible = true
		_accesi.clear()
		return
	for n in _tutte(get_tree().root):
		if n is CanvasLayer and n.name != "SfidaHud" and (n as CanvasLayer).visible:
			_accesi.append(n)
			(n as CanvasLayer).visible = false


## La schermata di caricamento e quella del titolo: in foto non ci vanno.
func _schermata(n: Node) -> bool:
	var sc = n.get_script()
	if sc == null:
		return false
	var f: String = (sc as Script).resource_path.get_file()
	return f in ["caricamento.gd", "intro_screen.gd"]


func _tutte(n: Node) -> Array:
	var fore: Array = [n]
	for c in n.get_children():
		fore.append_array(_tutte(c))
	return fore


func _scatta_da(da: Vector3, verso: Vector3, _nome: String) -> void:
	_cam.look_at_from_position(da, verso, Vector3.UP)
	_cam.current = true


func _scatta(nome: String) -> void:
	for _i in range(3):
		await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/64_%s.png" % nome)
	print("  foto: /tmp/64_%s.png" % nome)
