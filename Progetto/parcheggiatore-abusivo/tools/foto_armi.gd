extends Node
## 'E fote d''e fierre 'n mano (0.61): ogni arma ferma e a metà colpo.
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
	if _t < 0.7 or _occupato:
		return
	_t = 0.0
	_occupato = true
	var armi := ["cric", "mazza", "curtiello", "fierro", "kalash"]
	for a in armi:
		GameManager.armi[a] = true
		GameManager.arma_in_mano = a
		_pl.call("_aggiorna_arma_vista")
		await get_tree().create_timer(0.5).timeout
		await _scatta(a)
		var fp = _pl.get("_arma_fp")
		fp.call("colpo")
		if not (a in ["fierro", "kalash"]):
			await get_tree().create_timer(0.1).timeout
			await _scatta(a + "_colpo1")
			await get_tree().create_timer(0.07).timeout
			await _scatta(a + "_colpo2")
		await get_tree().create_timer(0.12 if a in ["fierro", "kalash"] else 0.05).timeout
		if a in ["fierro", "kalash"]:
			# la scia, come nel gioco
			var cam: Camera3D = _cam
			load("res://scripts/arma_fp.gd").scia(_pl.get_parent(),
				fp.call("bocca_nel_mondo"), cam.global_position - cam.global_transform.basis.z * 5.0 + Vector3(0, 0.5, 0), false)
			fp.call("colpo")
			await get_tree().create_timer(0.02).timeout
		await _scatta(a + "_colpo")
	get_tree().quit()


var _occupato := false


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
	img.save_png("/tmp/arma_%s.png" % nome)
	print("  foto: /tmp/arma_%s.png" % nome)
