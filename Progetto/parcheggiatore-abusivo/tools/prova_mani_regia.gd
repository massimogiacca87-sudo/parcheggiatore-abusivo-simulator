extends Node
## **'E mmane d''a regia, 'n città** (0.65).
##
## Il capo: *«Si è perso l'utilizzo delle mani in prima persona come gesti
## quando fai parcheggiare le auto.»* `foto_mani` guarda i gesti su un
## pavimento vuoto; questa li **gioca**: in piazza, con una macchina vera
## in coda, si comincia la regia col tasto [E] del cliente e si premono i
## tasti veri (`Input.action_press`), come farebbe il giocatore.
##
## Controlla che:
##   1. prima della regia le mani non ci siano;
##   2. appena parte la regia salgano, e ogni tasto dia il suo gesto
##      (A sinistra, D destra, S frena, W avanti, niente = aspetta);
##   3. col fierro in mano, durante la regia il fierro sparisca;
##   4. la botta (`directing_bump`) faccia il gesto della botta;
##   5. con [F] («mettila ccà») parta il dito per terra, e a regia finita
##      le mani scendano e il fierro torni.
##
## Con xvfb (`/tmp/provaxc.sh prova_mani_regia 300`) fa anche tre fotografie
## in /tmp/regia_*.png.


var storte: int = 0
var _pl: Node3D = null
var _mani: Node3D = null
var _foto: bool = false


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_foto = DisplayServer.get_name() != "headless"
	for _i in range(120):
		await get_tree().process_frame
	get_tree().paused = false
	# Con la finestra (xvfb) c'è ancora la schermata del titolo davanti, che
	# si mangia i tasti: via.
	if _foto:
		for n in _tutte(get_tree().root):
			var sc = n.get_script()
			if sc != null and (sc as Script).resource_path.get_file() in [
					"caricamento.gd", "intro_screen.gd"]:
				n.queue_free()
		await get_tree().process_frame
		get_tree().paused = false
	GameManager.giornata = 2
	GameManager.start_shift()
	GameManager.tipo_giornata = "normale"
	_pl = get_tree().get_first_node_in_group("player") as Node3D
	_mani = _pl.get("_mani_fp")
	if _mani == null:
		male("'o giocatore nun tene 'e mmane d''a regia")
		_fine()
		return
	_metti_giocatore(Vector3(31, 0, 30))
	await _aspetta(1.0)

	print("=== 1. PRIMMA D''A REGIA ===")
	if _mani.visible:
		male("'e mmane se vedono pure senza regia")

	# Una macchina in coda nella piazza di casa.
	var auto: Node3D = null
	var t := 0.0
	while auto == null and t < 120.0:
		await _aspetta(0.5)
		t += 0.5
		for c in get_tree().get_nodes_in_group("cars"):
			if is_instance_valid(c) and int(c.get("state")) == 1 \
					and str(c.get("zona_id")) == "piazza":
				auto = c
				break
	if auto == null:
		male("nisciuna machina in coda 'n piazza doppo %.0f secunne" % t)
		_fine()
		return
	print("  machina in coda doppo %.1f s" % t)

	# Il fierro in mano, per vedere se scende.
	GameManager.armi["mazza"] = true
	GameManager.arma_in_mano = "mazza"
	_pl.call("_aggiorna_arma_vista")
	var arma: Node3D = _pl.get("_arma_fp")

	# Ci si mette accanto, girati verso di lei, e si preme [E].
	var fianco: Vector3 = auto.global_position + auto.global_transform.basis.x * 3.2
	_metti_giocatore(fianco)
	var d: Vector3 = auto.global_position - _pl.global_position
	_pl.rotation.y = atan2(-d.x, -d.z)
	auto.call("player_interact")
	if not auto.call("is_being_directed"):
		male("[E] ncopp''a machina nun ha fatto partì 'a regia")
		_fine()
		return
	_pl.set("directing_car", auto)

	print("=== 2. 'E GESTE ===")
	await _aspetta(0.6)
	if not _mani.visible:
		male("è partita 'a regia e 'e mmane nun se vedono")
	_controlla_gesto("aspetta", "niente tasti")
	await _foto_se("aspetta")
	for prova in [["move_left", "sinistra"], ["move_right", "destra"],
			["move_down", "frena"], ["move_up", "avanti"]]:
		Input.action_press(str(prova[0]))
		await _aspetta(0.45)
		_controlla_gesto(str(prova[1]), str(prova[0]))
		if str(prova[1]) == "sinistra":
			await _foto_se("sinistra")
		Input.action_release(str(prova[0]))
		await _aspetta(0.2)

	print("=== 3. 'O FIERRO SCENNE ===")
	if arma != null:
		var rig: Node3D = arma.get("_rig")
		if rig != null and rig.visible:
			male("durante 'a regia 'o fierro se vede ancora")

	print("=== 4. 'A BOTTA ===")
	GameManager.directing_bump.emit(1)
	await _aspetta(0.1)
	if str(_mani.get("_lampo")) != "botta":
		male("'a botta nun fa 'o gesto d''a botta (lampo='%s')" % str(_mani.get("_lampo")))
	await _aspetta(1.0)

	print("=== 5. METTILA CCÀ ===")
	Input.action_press("park_here")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("park_here")
	var visto_mettila: bool = str(_mani.get("_lampo")) == "mettila"
	await _aspetta(0.2)
	await _foto_se("fine")
	if not visto_mettila and str(_mani.get("_lampo")) not in ["mettila", "bravo", "sconfitto"]:
		male("[F] nun fa nisciun gesto (lampo='%s')" % str(_mani.get("_lampo")))
	# Si aspetta 2,5 secondi **del gioco**, non dell'orologio: con xvfb il
	# disegno è lento, Godot perde passi di fisica e il tempo del gioco va
	# più piano di quello vero (misurato: mezzo secondo ogni due e mezzo).
	var t0: float = float(_mani.get("_t"))
	var vero := 0.0
	while float(_mani.get("_t")) - t0 < 2.5 and _mani.visible and vero < 20.0:
		await _aspetta(0.25)
		vero += 0.25
	await _aspetta(0.5)
	if auto.call("is_being_directed"):
		male("doppo [F] 'a machina se sta ancora dirigenno")
	if _mani.visible:
		male("regia fernuta e 'e mmane stanno ancora 'n aria (vuole=%s su=%.2f lampo='%s' pausa=%s dirige=%s)" % [
			str(_mani.get("_vuole")), float(_mani.get("_su")), str(_mani.get("_lampo")),
			str(get_tree().paused), str(_pl.get("directing_car"))])
	if arma != null:
		var rig2: Node3D = arma.get("_rig")
		if rig2 != null and not rig2.visible:
			male("regia fernuta e 'o fierro nun è turnato")
	_fine()


func _controlla_gesto(atteso: String, tasto: String) -> void:
	var g: String = str(_mani.get("_gesto"))
	var v: bool = bool(_mani.get("_vuole"))
	print("  %-10s → gesto '%s'" % [tasto, g])
	if not v or g != atteso:
		male("cu %s aspettavo '%s', è venuto '%s' (regia=%s)" % [tasto, atteso, g, str(v)])


func _foto_se(nome: String) -> void:
	if not _foto:
		return
	var vero := 0.0
	while float(_mani.get("_su")) < 1.0 and vero < 10.0:
		await _aspetta(0.2)
		vero += 0.2
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/regia_%s.png" % nome)
	print("  foto: /tmp/regia_%s.png" % nome)


func _tutte(n: Node) -> Array:
	var fore: Array = [n]
	for c in n.get_children():
		fore.append_array(_tutte(c))
	return fore


func _fine() -> void:
	for a in ["move_left", "move_right", "move_up", "move_down", "park_here"]:
		Input.action_release(a)
	print("=== %d storte ===" % storte)
	get_tree().quit()


func _aspetta(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _metti_giocatore(p: Vector3) -> void:
	p.y = Collina.alzata(p.x, p.z) + 0.2
	_pl.global_position = p
	if _pl is CharacterBody3D:
		(_pl as CharacterBody3D).velocity = Vector3.ZERO
