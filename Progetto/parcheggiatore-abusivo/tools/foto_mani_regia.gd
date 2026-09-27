extends Node
## 'E fote d''e mmane d''a regia (0.65): ogni gesto, fermo e a metà.
##
## Il capo: *«crea di nuovo le animazioni a gesti quando muovi un'auto»*.
## Un gesto si giudica solo guardando lo schermo del gioco: dove cade la
## mano, se copre la macchina, se il dito indica dalla parte giusta.
## Foto in /tmp/mani_*.png (`/tmp/foto.sh foto_mani_regia 200`).
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

	# Una macchina finta davanti, dove starebbe quella che dirigi: le mani
	# non la devono coprire.
	var auto := MeshInstance3D.new()
	var ab := BoxMesh.new()
	ab.size = Vector3(1.8, 1.4, 4.2)
	auto.mesh = ab
	var am := StandardMaterial3D.new()
	am.albedo_color = Color(0.7, 0.12, 0.1)
	auto.material_override = am
	auto.position = Vector3(0.3, 0.7, -5.5)
	mondo.add_child(auto)
	# Un muro davanti, per avere qualcosa a fuoco dietro alle mani.
	var muro := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(14, 5, 0.4)
	muro.mesh = bm
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color(0.72, 0.58, 0.44)
	muro.material_override = mm
	muro.position = Vector3(0, 2.5, -9.0)
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
		_pl.set_physics_process(false)
	if _mani != null:
		_mani.call("regia", _gesto)
	_t += d
	if _t < 0.7 or _occupato:
		return
	_occupato = true
	_mani = _pl.get("_mani_fp")
	var giro := [["aspetta", 0.8], ["avanti", 0.8], ["avanti", 0.19],
		["frena", 0.6], ["sinistra", 0.6], ["destra", 0.6],
		["piano", 0.6], ["piano", 0.28]]
	for pezzo in giro:
		await _fai(str(pezzo[0]), float(pezzo[1]))
	for l in ["botta", "bravo", "sconfitto", "mettila"]:
		_gesto = "aspetta"
		await get_tree().create_timer(0.4).timeout
		_mani.call("lampo", l)
		await get_tree().create_timer(0.3).timeout
		await _scatta(l)
	# Con la paletta in tasca.
	_gesto = ""
	await get_tree().create_timer(0.6).timeout
	GameManager.upgrades["paletta"] = true
	for pezzo in giro:
		await _fai(str(pezzo[0]), float(pezzo[1]), "pal_")
	for l in ["botta", "bravo"]:
		_gesto = "aspetta"
		await get_tree().create_timer(0.4).timeout
		_mani.call("lampo", l)
		await get_tree().create_timer(0.3).timeout
		await _scatta("pal_" + l)
	get_tree().quit()


var _occupato := false
var _mani: Node3D = null
var _gesto := ""
var _conto := 0


func _fai(g: String, attesa: float, pref: String = "") -> void:
	_gesto = g
	await get_tree().create_timer(attesa).timeout
	_conto += 1
	await _scatta("%s%s_%d" % [pref, g, _conto])



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
	img.save_png("/tmp/mani_%s.png" % nome)
	print("  foto: /tmp/mani_%s.png" % nome)
