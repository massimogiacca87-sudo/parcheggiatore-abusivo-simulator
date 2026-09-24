extends Node
## 'E fote d''o HUD (0.62): la piazza con l'interfaccia accesa, davanti a
## una macchina parcheggiata (le scritte dei tasti), la chiantina, lo zaino.
##
## Si lancia con DEBUG_SIM=1 così non passa per il caricamento:
##   DEBUG_SIM=1 /tmp/foto.sh foto_hud 200
## Le foto finiscono in /tmp/hud_*.png. `SOLO=mappa,zaino` per farne alcune.

var _pl: Node3D = null
var _hud: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(60):
		await get_tree().process_frame
	get_tree().paused = false
	GameManager.intro_active = false
	GameManager.giornata = 3
	GameManager.tipo_giornata = "normale"
	GameManager.money = 137
	GameManager.shift_time_left = GameManager.shift_duration * 0.7
	_pl = get_tree().get_first_node_in_group("player") as Node3D
	_hud = get_tree().root.find_child("HUD", true, false)
	var solo := OS.get_environment("SOLO")
	# Una macchina posteggiata davanti, con lo stemma: così si vede la riga
	# dei comandi con tre azioni.
	var CarScript = load("res://scripts/car_3d.gd")
	_pl.global_position = Vector3(31, 1, 30)
	_pl.rotation.y = 0.0
	(_pl.get("head") as Node3D).rotation.x = deg_to_rad(-16)
	for _i in range(20):
		await get_tree().physics_frame
	var car: Node3D = CarScript.new()
	get_tree().root.add_child(car)
	car.set("car_type", "berlina")
	car.set("state", 3)
	car.global_position = _pl.global_position + Vector3(0, -1, -3.0)
	car.rotation.y = PI * 0.5
	if not bool(car.get("has_emblem")):
		car.set("emblem_info", {"name": "Tridente d'Argento", "value": 30})
		car.set("has_emblem", true)
	GameManager.money = 137
	GameManager.money_changed.emit(137)
	GameManager.heat = 26.0
	GameManager.heat_changed.emit(26.0)
	GameManager.event_started.emit("'O cliente d''a Punto è turnato: t'ha lassato 'na mancia 'e tre euro e 'nu sorriso.")
	for _i in range(40):
		await get_tree().process_frame
	if solo == "" or "auto" in solo:
		# Il player si ferma, così la riga resta quella che scrivo io.
		_pl.set_physics_process(false)
		_hud.call("_on_prompt_changed", str(car.get_interact_prompt(_pl.global_position)))
		for _i in range(6):
			await get_tree().process_frame
		await _scatta("auto")
		_hud.call("_on_prompt_changed", "[E] 'o guide a gesti dint'ô posto")
		for _i in range(6):
			await get_tree().process_frame
		await _scatta("auto_corta")
		_pl.set_physics_process(true)
	if solo == "" or "stelle" in solo:
		GameManager.stelle = 2
		GameManager.stelle_cambiate.emit(2)
		for _i in range(10):
			await get_tree().process_frame
		await _scatta("stelle")
		GameManager.stelle = 0
		GameManager.stelle_cambiate.emit(0)
	car.queue_free()
	if solo == "" or "mappa" in solo:
		_hud.call("_toggle_mappa")
		for _i in range(10):
			await get_tree().process_frame
		await _scatta("mappa")
		_hud.call("_toggle_mappa")
	if solo == "" or "zaino" in solo:
		var ev := InputEventAction.new()
		ev.action = "inventory"
		ev.pressed = true
		Input.parse_input_event(ev)
		for _i in range(10):
			await get_tree().process_frame
		await _scatta("zaino")
		var ev2 := InputEventAction.new()
		ev2.action = "inventory"
		ev2.pressed = true
		Input.parse_input_event(ev2)
		for _i in range(5):
			await get_tree().process_frame
	if solo == "" or "pausa" in solo:
		_hud.call("_pause_game")
		for _i in range(10):
			await get_tree().process_frame
		await _scatta("pausa")
		_hud.call("_resume_game")
	get_tree().quit()


func _auto_parcheggiata() -> Node3D:
	var best: Node3D = null
	var bd := 1e9
	for c in get_tree().get_nodes_in_group("cars"):
		if not (c is Node3D) or not ("state" in c):
			continue
		if int(c.get("state")) != 3: # State.PARKED
			continue
		if not bool(c.get("has_emblem")):
			continue
		var d: float = (c as Node3D).global_position.distance_to(_pl.global_position)
		if d < bd:
			bd = d
			best = c
	return best


func _guarda_auto(car: Node3D) -> void:
	var cp := car.global_position
	var fw: Vector3 = car.global_transform.basis.z # il muso è −Z: +Z è il dietro
	var Citta = load("res://scripts/citta_3d.gd")
	var dir := -fw
	for k in range(16):
		if not Citta.dint_ô_palazzo(cp + dir * 3.2, 0.5):
			break
		dir = dir.rotated(Vector3.UP, TAU / 16.0)
	_pl.global_position = cp + dir * 3.0 + Vector3(0, 0.3, 0)
	var verso := (cp - _pl.global_position)
	verso.y = 0
	_pl.rotation.y = atan2(-verso.x, -verso.z)
	var head = _pl.get("head")
	if head is Node3D:
		(head as Node3D).rotation.x = deg_to_rad(-22)


func _scatta(nome: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/hud_%s.png" % nome)
	print("  foto: /tmp/hud_%s.png" % nome)
