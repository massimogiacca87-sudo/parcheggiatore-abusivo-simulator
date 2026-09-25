extends Node
## 'E fote 'e chello ca vede 'o giocatore.
##
## Serve a due punti del capo: le mani in prima persona ("non mi piacciono e
## sono al contrario") e la telecamera ("sta sulla testa del personaggio e
## se si abbassa gli si vede in testa"). Tutti e due si giudicano solo
## guardando lo schermo del gioco, non un render in Blender.
##
## Come `foto_pupi.gd`: la scena principale è vuota (vedi `/tmp/foto.sh`),
## il gioco parte in pausa quindi ci vuole `PROCESS_MODE_ALWAYS`, e ogni
## scatto rispegne HUD e telecamere altrui.

const PlayerScript := preload("res://scripts/player_fps.gd")

var _t := 0.0
var _n := 0
var _pulito := false
var _pl: CharacterBody3D = null
var _cam: Camera3D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	var mondo := Node3D.new()
	add_child(mondo)

	var suolo := StaticBody3D.new()
	suolo.collision_layer = 1
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(60, 1, 60)
	cs.shape = bs
	cs.position = Vector3(0, -0.5, 0)
	suolo.add_child(cs)
	var vis := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 60)
	vis.mesh = pm
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.40, 0.38, 0.36)
	vis.material_override = mt
	suolo.add_child(vis)
	mondo.add_child(suolo)

	# Un muro davanti, per avere qualcosa a fuoco dietro alle mani.
	var muro := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(14, 5, 0.4)
	muro.mesh = bm
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color(0.72, 0.58, 0.44)
	muro.material_override = mm
	muro.position = Vector3(0, 2.5, -5.0)
	mondo.add_child(muro)

	var luce := DirectionalLight3D.new()
	luce.rotation_degrees = Vector3(-46, 24, 0)
	luce.light_energy = 1.3
	mondo.add_child(luce)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.58, 0.65, 0.74)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.66, 0.72)
	env.ambient_light_energy = 0.9
	we.environment = env
	mondo.add_child(we)

	_pl = PlayerScript.new()
	_pl.position = Vector3(0, 0.2, 0)
	mondo.add_child(_pl)
	await get_tree().process_frame
	await get_tree().process_frame
	_cam = _pl.get("camera")
	print("  giocatore in piedi, camera=", _cam != null)


func _process(d: float) -> void:
	if not _pulito:
		for n in get_tree().root.get_children():
			if n == self:
				continue
			if n is Node3D:
				(n as Node3D).visible = false
			_spegni(n)
		_pulito = true
	_t += d
	if _t < 0.8:
		return
	_t = 0.0
	_n += 1
	var testa: Node3D = _pl.get("head") if _pl != null else null
	match _n:
		1:
			_scatta("dritto")
		2:
			# Sguardo in giù: è la prova della telecamera. Se la testa del
			# modello sta ancora lì, qui si vede.
			if testa != null:
				testa.rotation.x = deg_to_rad(-62.0)
			_t = 0.55
		3:
			_scatta("guarda_giu")
		4:
			if testa != null:
				testa.rotation.x = deg_to_rad(-88.0)
			_t = 0.55
		5:
			_scatta("guarda_pieri")
		6:
			if testa != null:
				testa.rotation.x = 0.0
			for nome in ["_throw_punch", "punch", "_punch"]:
				if _pl.has_method(nome):
					_pl.call(nome)
					break
			_t = 0.16
		7:
			_scatta("cazzotto")
			_t = 0.14
		8:
			# Il secondo colpo: dev'essere il sinistro, non il destro.
			for nome in ["_throw_punch", "punch", "_punch"]:
				if _pl.has_method(nome):
					_pl.call(nome)
					break
			_t = 0.16
		9:
			_scatta("cazzotto_2")
			await get_tree().create_timer(0.4).timeout
			get_tree().quit()


func _spegni(n: Node) -> void:
	for c in n.get_children():
		if c is CanvasLayer:
			(c as CanvasLayer).visible = false
		if c is CanvasItem:
			(c as CanvasItem).visible = false
		_spegni(c)


func _scatta(nome: String) -> void:
	for n in get_tree().root.get_children():
		if n != self:
			_spegni(n)
	if _cam != null:
		_cam.make_current()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/pov_%s.png" % nome)
	print("  foto: /tmp/pov_%s.png" % nome)
