extends Node
## 'E fote d''o HUD a cchiù grandezze 'e schermo.
##
## Il capo: *«La UI è troppo grande, occupa troppo spazio... controlla
## quanto è responsive»*. Questa foto fa la stessa scena (piazza, macchina
## con lo stemma davanti, un cartello, sospetto a metà) a più risoluzioni
## della finestra, e controlla anche che la riga dei comandi si spenga
## quando il giocatore non la aggiorna più (lo stemma rubato, il giocatore
## fermo).
##
## Variabili d'ambiente:
##   OUT=<cartella>        dove salvare i PNG (di serie user://foto_hud)
##   MISURE=1280x720,1920x1080   le risoluzioni (di serie cinque)
##   PREFISSO=prima        il prefisso dei file
##
## Stampa `=== N storte ===` come le prove: le storte sono le cose che
## escono dallo schermo o si sovrappongono, e la riga dei comandi rimasta
## accesa.

var _pl: Node3D = null
var _hud: Node = null
var _storte: int = 0


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
	var out := OS.get_environment("OUT")
	if out == "":
		out = ProjectSettings.globalize_path("user://foto_hud")
	DirAccess.make_dir_recursive_absolute(out)
	var pre := OS.get_environment("PREFISSO")
	if pre == "":
		pre = "hud"
	var misure := OS.get_environment("MISURE")
	if misure == "":
		misure = "1280x720,1366x768,1920x1080,1920x1200,2560x1440"

	# Due macchine posteggiate con lo stemma: una davanti, una a otto metri.
	var CarScript = load("res://scripts/car_3d.gd")
	_pl.global_position = Vector3(31, 1, 30)
	_pl.rotation.y = 0.0
	(_pl.get("head") as Node3D).rotation.x = deg_to_rad(-12)
	for _i in range(20):
		await get_tree().physics_frame
	var auto: Array = []
	for d in [Vector3(0, -1, -3.0), Vector3(8.0, -1, -3.0)]:
		var car: Node3D = CarScript.new()
		get_tree().root.add_child(car)
		car.set("car_type", "berlina")
		car.set("state", 3)
		car.global_position = _pl.global_position + d
		car.rotation.y = PI * 0.5
		car.set("emblem_info", {"name": "Tridente d'Argento", "value": 7,
			"color": Color(0.8, 0.82, 0.88)})
		car.set("has_emblem", true)
		auto.append(car)
	for _i in range(30):
		await get_tree().physics_frame
	# Da qui il giocatore sta fermo: la riga la scrivo io.
	_pl.set_physics_process(false)
	var riga_auto := "[E] scassa 'a machina (berlina · facile) · [G] arruobbe 'o stemma \"Tridente d'Argento\" · [F] danneggia l'auto"

	for m in misure.split(","):
		var p := m.split("x")
		if p.size() != 2:
			continue
		var w := int(p[0])
		var h := int(p[1])
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		DisplayServer.window_set_size(Vector2i(w, h))
		DisplayServer.window_set_position(Vector2i(0, 0))
		for _i in range(12):
			await get_tree().process_frame
		var vera: Vector2i = DisplayServer.window_get_size()
		# «pieno»: tutto quello che può stare a schermo insieme.
		GameManager.heat = 46.0
		GameManager.heat_changed.emit(46.0)
		GameManager.health = GameManager.HEALTH_MAX * 0.55
		GameManager.health_changed.emit(GameManager.health)
		GameManager.stelle = 2
		GameManager.stelle_cambiate.emit(2)
		GameManager.event_started.emit("'O cliente d''a Punto è turnato: t'ha lassato 'na mancia 'e tre euro.")
		_hud.call("_on_prompt_changed", riga_auto)
		for _i in range(10):
			await get_tree().process_frame
		_controlla(vera)
		await _scatta("%s/%s_pieno_%dx%d.png" % [out, pre, vera.x, vera.y])
		# «pulito»: niente sospetto, sano, niente cartelli, niente riga.
		GameManager.heat = 0.0
		GameManager.heat_changed.emit(0.0)
		GameManager.health = GameManager.HEALTH_MAX
		GameManager.health_changed.emit(GameManager.health)
		GameManager.stelle = 0
		GameManager.stelle_cambiate.emit(0)
		_hud.call("_on_prompt_changed", "")
		_hud.get("event_banner").text = ""
		_hud.set("_banner_time", 0.0)
		# Le cose appena cambiate restano accese qualche secondo: si aspetta.
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 5500:
			await get_tree().process_frame
		await _scatta("%s/%s_pulito_%dx%d.png" % [out, pre, vera.x, vera.y])

	# --- La riga dei comandi deve spegnersi -------------------------------
	var riga: Control = _hud.get("prompt_label")
	# Se nel frattempo è arrivato Borrelli, il dialogo ha la precedenza sulla
	# riga: si chiude, se no la prova non guarda niente.
	if _hud.has_method("_on_boss_dialogue_closed"):
		_hud.call("_on_boss_dialogue_closed")
	_hud.set("_dialogue_answers", [])
	# Il giocatore fermo (guida, scasso, presa, caduta) con la riga di un
	# bersaglio scritta per ultima: deve spegnersi da sola.
	if _pl.get("_riga_bersaglio") != null:
		_pl.set("_riga_bersaglio", riga_auto)
		_pl.set("_riga_passo", Engine.get_physics_frames())
		_pl.emit_signal("prompt_changed", riga_auto)
	print("riga appena scritta: visibile=", riga.visible)
	if not riga.visible:
		_storte += 1
		print("STORTA: la riga del bersaglio non si accende")
	for _i in range(12):
		await get_tree().physics_frame
	print("giocatore fermo: visibile=", riga.visible, " «", riga.get("text"), "»")
	if riga.visible:
		_storte += 1
		print("STORTA: col giocatore fermo la riga dei comandi resta accesa")
	_pl.set_physics_process(true)
	# Lo stemma della prima si stacca: la bussola non deve saltare subito
	# sulla seconda macchina.
	auto[0].call("player_stemma")
	for _i in range(20):
		await get_tree().physics_frame
	var bussola: String = str((_hud.get("emblem_pointer") as Label).text)
	print("dopo lo stemma, bussola: «", bussola, "»  riga: «", riga.get("text"), "»")
	if "stemma" in bussola:
		_storte += 1
		print("STORTA: dopo il furto la bussola dice ancora dello stemma")
	for c in auto:
		c.queue_free()
	# Il menu di pausa, col bottone nuovo della grandezza dell'HUD.
	_hud.call("_pause_game")
	for _i in range(10):
		await get_tree().process_frame
	await _scatta("%s/%s_pausa.png" % [out, pre])
	_hud.call("_resume_game")
	print("=== %d storte ===" % _storte)
	get_tree().quit()


## Tutto quello che si vede deve stare dentro allo schermo, e le schede non
## si devono sovrapporre fra loro.
func _controlla(vera: Vector2i) -> void:
	var schermo := get_viewport().get_visible_rect()
	var pezzi: Array = []
	for n in ["SchedaParcheggiatore", "SchedaJurnata", "CorniceMinimappa",
			"PilaBassa", "RigaComandi"]:
		var c := _hud.find_child(n, true, false) as Control
		if c == null or not c.is_visible_in_tree():
			continue
		var r := c.get_global_rect()
		if n == "PilaBassa":
			r = _rect_figli(c)
			if r.size == Vector2.ZERO:
				continue
		pezzi.append([n, r])
		if not schermo.encloses(r.grow(-1.0)):
			_storte += 1
			print("STORTA %dx%d: %s esce dallo schermo %s (schermo %s)" % [
				vera.x, vera.y, n, r, schermo])
	for i in range(pezzi.size()):
		for j in range(i + 1, pezzi.size()):
			if (pezzi[i][1] as Rect2).grow(-2.0).intersects((pezzi[j][1] as Rect2).grow(-2.0)):
				_storte += 1
				print("STORTA %dx%d: %s si sovrappone a %s" % [vera.x, vera.y,
					pezzi[i][0], pezzi[j][0]])
	var sx := _hud.find_child("SchedaParcheggiatore", true, false) as Control
	var dx := _hud.find_child("SchedaJurnata", true, false) as Control
	var mm := _hud.find_child("CorniceMinimappa", true, false) as Control
	var area := 0.0
	for c in [sx, dx, mm]:
		if c != null and c.is_visible_in_tree():
			var r: Rect2 = c.get_global_rect()
			area += r.size.x * r.size.y
	print("%dx%d: schede+minimappa = %.1f%% dello schermo  (sx %s, dx %s, mm %s)" % [
		vera.x, vera.y, 100.0 * area / (schermo.size.x * schermo.size.y),
		sx.get_global_rect().size if sx else Vector2.ZERO,
		dx.get_global_rect().size if dx else Vector2.ZERO,
		mm.get_global_rect().size if mm else Vector2.ZERO])


func _rect_figli(c: Control) -> Rect2:
	var r := Rect2()
	var primo := true
	for f in c.get_children():
		if f is Control and (f as Control).is_visible_in_tree():
			var g: Rect2 = (f as Control).get_global_rect()
			r = g if primo else r.merge(g)
			primo = false
	return r


func _scatta(file: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(file)
	print("  foto: ", file, "  ", img.get_size())
