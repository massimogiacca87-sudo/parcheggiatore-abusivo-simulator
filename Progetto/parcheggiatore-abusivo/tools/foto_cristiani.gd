extends SceneTree
## **'A fila d''e cristiane** (0.59): il pupo, gli otto omini e l'umano di
## Quaternius uno accanto all'altro, con i colori che darebbe il gioco.
## Metà cammina e metà sta ferma: si vede subito chi scivola, chi sta in
## croce e chi ha la faccia di un altro stile.

const Human := preload("res://scripts/human_builder.gd")

var _gente: Array = []


func _initialize() -> void:
	var mondo := Node3D.new()
	get_root().add_child(mondo)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.62, 0.7, 0.8)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.72, 0.75)
	e.ambient_light_energy = 0.7
	env.environment = e
	mondo.add_child(env)
	var sole := DirectionalLight3D.new()
	sole.rotation_degrees = Vector3(-45, 25, 0)
	sole.shadow_enabled = true
	mondo.add_child(sole)
	var suolo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 30)
	suolo.mesh = pm
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.45, 0.43, 0.4)
	suolo.material_override = sm
	mondo.add_child(suolo)
	var chi: Array = [
		["pupo", Color(0.85, 0.3, 0.25), Color(0.2, 0.22, 0.3), {}],
		["pupo", Color(0.5, 0.6, 0.8), Color(0.25, 0.2, 0.3), {"corpo": "femmina"}],
	]
	var camicie := [Color(0.86, 0.84, 0.78), Color(0.25, 0.45, 0.7),
		Color(0.7, 0.25, 0.22), Color(0.3, 0.5, 0.35), Color(0.9, 0.75, 0.3),
		Color(0.2, 0.2, 0.24), Color(0.6, 0.55, 0.5), Color(0.45, 0.3, 0.5)]
	var i := 0
	for o in Human.OMINI:
		chi.append([o, camicie[i % camicie.size()], Color(0.2, 0.22, 0.28), {}])
		i += 1
	chi.append(["umano_q", Color(0.86, 0.84, 0.78), Color(0.22, 0.24, 0.3), {}])
	chi.append(["umano_q", Color(0.7, 0.25, 0.22), Color(0.15, 0.15, 0.17), {}])
	chi.append(["umano_q", Color(0.3, 0.5, 0.35), Color(0.45, 0.4, 0.3), {"bald": true}])
	chi.append(["umano_q", Color.WHITE, Color.WHITE, {"tinta": 1}])
	chi.append(["umano_q", Color.WHITE, Color.WHITE, {"tinta": 5}])
	var x := -float(chi.size()) * 0.5 * 1.1
	var n := 0
	for c in chi:
		var opts: Dictionary = (c[3] as Dictionary).duplicate()
		opts["modello"] = c[0]
		var parti: Dictionary = Human.build(c[1], c[2], "", 1.76, opts)
		var radice: Node3D = parti["root"]
		var nodo := Node3D.new()
		nodo.position = Vector3(x, 0, 0)
		mondo.add_child(nodo)
		nodo.add_child(radice)
		var l := Label3D.new()
		l.text = str(c[0]).replace("omo_", "")
		l.position = Vector3(x, 2.1 + 0.25 * (n % 2), 0)
		l.pixel_size = 0.005
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		mondo.add_child(l)
		_gente.append([parti.get("anim"), n % 2 == 1])
		x += 1.1
		n += 1
	for _k in range(3):
		await process_frame
	for g in _gente:
		if g[0] != null and bool(g[1]):
			g[0].set_speed(1.35)
	var cam := Camera3D.new()
	mondo.add_child(cam)
	cam.look_at_from_position(Vector3(0, 2.2, -9.5), Vector3(0, 1.0, 0), Vector3.UP)
	cam.fov = 70
	cam.current = true
	for _k in range(40):
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("/tmp/59_cristiani.png")
	cam.look_at_from_position(Vector3(4.5, 1.5, -3.2), Vector3(5.5, 1.0, 0), Vector3.UP)
	for _k in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("/tmp/59_cristiani_umano.png")
	cam.look_at_from_position(Vector3(-4.5, 1.5, -3.2), Vector3(-3.5, 1.0, 0), Vector3.UP)
	for _k in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("/tmp/59_cristiani_omini.png")
	quit()
