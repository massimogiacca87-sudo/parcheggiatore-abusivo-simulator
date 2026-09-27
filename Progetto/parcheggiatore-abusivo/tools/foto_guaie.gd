extends Node
## 'E fote d''a scala d''e guaie (0.65).
##
## `CASO=suocera` (Donna Cuncetta ncopp''o lietto), `CASO=cacciato` (la
## porta chiusa coi cartoni, e l'HUD col debito), `CASO=fernuta` (la
## schermata finale). Le foto in /tmp/guaie_*.png.
##
## I guai si accendono **prima** che nasca la città (qui, nel `_ready`
## dell'autoload): il vascio li guarda quando si costruisce.

var _t := 0.0
var _n := 0
var _pronto := false
var _cam: Camera3D = null
var _caso := "suocera"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_caso = OS.get_environment("CASO")
	if _caso == "":
		_caso = "suocera"
	var gm := GameManager
	gm.giornata = 6
	gm.giorni_debbito = 4
	gm.gradino_fatto = 4
	gm.suocera_in_casa = true
	gm.luce_staccata = true
	gm.gas_staccato = true
	if _caso != "suocera":
		gm.giorni_debbito = 5
		gm.gradino_fatto = 5
		gm.cacciato_e_casa = true


func _process(d: float) -> void:
	if not _pronto:
		_pronto = true
		for n in _tutte(get_tree().root):
			if n is CanvasLayer and n.has_method("_on_menu_gioca"):
				(n as CanvasLayer).visible = false
				break
		get_tree().paused = false
		GameManager.start_shift()
		GameManager.intro_active = false
		GameManager.spese_aperte.append({"id": "x", "tipo": "fitto",
			"nome": "'O fitto d''a casa", "importo": 164, "base": 140,
			"giorno": 4, "desc": "", "grave": true})
		GameManager.money = 23
		GameManager.money_changed.emit(23)
		_cam = Camera3D.new()
		_cam.fov = 70
		get_tree().root.add_child(_cam)
		return
	_t += d
	if _t < 1.2:
		return
	_t = 0.0
	_n += 1
	var v := get_tree().get_first_node_in_group("vascio")
	if v == null:
		return
	match _caso:
		"suocera":
			var dentro: Node3D = v.get_node_or_null("Dentro")
			var pl := get_tree().get_first_node_in_group("player")
			if _n == 1:
				v.call("entra", pl)
				var c: Vector3 = dentro.global_position
				_cam.look_at_from_position(c + Vector3(-0.6, 1.5, 0.9),
					c + Vector3(1.4, 0.7, -1.3), Vector3.UP)
				_cam.current = true
			elif _n == 3:
				await _scatta("suocera")
				get_tree().quit()
		"cacciato":
			if _n == 1:
				# L'HUD col debito, dalla telecamera del giocatore.
				var pl2 := get_tree().get_first_node_in_group("player")
				(pl2.get("camera") as Camera3D).current = true
				GameManager.famiglia_cambiata.emit()
			elif _n == 3:
				await _scatta("hud", true)
				var porta: Vector3 = v.call("punto_porta")
				_cam.look_at_from_position(porta + Vector3(2.4, 1.5, -1.0),
					porta + Vector3(0.0, 0.6, 1.2), Vector3.UP)
				_cam.current = true
			elif _n == 5:
				await _scatta("porta")
				get_tree().quit()
		"fernuta":
			if _n == 2:
				GameManager.partita_persa.emit({"giornate": 11, "piazze": 2,
					"soldi": 4, "dovuto": 729, "finale": GameManager.FINALE[0],
					"conseguenze": [GameManager.SCALA[6]["fatto"],
						"Donna Cuncetta s'è pigliata €2 'a dint''a giacca. «P''o lotto. Si vinco, 'e ddongo 'e criature.»"]})
			elif _n == 4:
				await _scatta("fernuta", true)
				get_tree().quit()


func _scatta(nome: String, cu_hud: bool = false) -> void:
	if not cu_hud:
		for n in _tutte(get_tree().root):
			if n is CanvasLayer:
				(n as CanvasLayer).visible = false
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/guaie_%s.png" % nome)
	print("  foto: /tmp/guaie_%s.png" % nome)


func _tutte(n: Node) -> Array:
	var fore: Array = [n]
	for c in n.get_children():
		fore.append_array(_tutte(c))
	return fore
