extends SceneTree
## Com'è girato un pezzo: fotografato da +Z (sinistra) e da −Z (destra),
## con un dado rosso sul +Z. FRONTE="nome1,nome2".

func _initialize() -> void:
	var mondo := Node3D.new()
	get_root().add_child(mondo)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.62, 0.7, 0.8)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.9, 0.9, 0.9)
	env.environment = e
	mondo.add_child(env)
	var sole := DirectionalLight3D.new()
	sole.rotation_degrees = Vector3(-45, 25, 0)
	mondo.add_child(sole)
	var nomi := OS.get_environment("FRONTE").split(",")
	var x := 0.0
	for n in nomi:
		for lato in [0, 1]:
			var mi := MeshInstance3D.new()
			mi.mesh = load("res://assets/models/%s.mesh" % n)
			mi.position = Vector3(x, 0, 0)
			mi.rotation.y = 0.0 if lato == 0 else PI
			mondo.add_child(mi)
			var dado := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.08, 0.08, 0.08)
			dado.mesh = bm
			var m := StandardMaterial3D.new()
			m.albedo_color = Color.RED
			dado.material_override = m
			dado.position = Vector3(0, 0.05, 0.6)
			mi.add_child(dado)
			x += 2.0
		x += 1.0
	var cam := Camera3D.new()
	mondo.add_child(cam)
	cam.look_at_from_position(Vector3(x * 0.5 - 1.5, 1.6, 6.0), Vector3(x * 0.5 - 1.5, 0.6, 0), Vector3.UP)
	cam.fov = 60
	cam.current = true
	for _k in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("/tmp/59_fronte.png")
	quit()
