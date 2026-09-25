extends SceneTree
func _initialize() -> void:
	var mondo := Node3D.new()
	get_root().add_child(mondo)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.6, 0.65)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.9, 0.9, 0.9)
	env.environment = e
	mondo.add_child(env)
	var sole := DirectionalLight3D.new()
	sole.rotation_degrees = Vector3(-50, 20, 0)
	mondo.add_child(sole)
	var nomi := ["chair_mp_3", "chair_mp_4", "chair_mp_5", "sofa_3", "armchair_2", "tv_mp_1", "wardrobe_mp_1_2", "toilet_cabin_mp_1", "bedside_table_1", "lamp_2_on", "table_large_3", "pc_speaker_1_left"]
	var x := 0.0
	for n in nomi:
		var m: Node3D = (load("res://psx/%s.glb" % n) as PackedScene).instantiate()
		m.position = Vector3(x, 0, 0)
		mondo.add_child(m)
		# freccia rossa verso +Z
		var f := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.08, 0.02, 0.9)
		f.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1, 0, 0)
		f.material_override = mat
		f.position = Vector3(x, 0.01, 0.9)
		mondo.add_child(f)
		var l := Label3D.new()
		l.text = n
		l.pixel_size = 0.004
		l.position = Vector3(x, 2.8, 0)
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		mondo.add_child(l)
		x += 2.6
	var cam := Camera3D.new()
	mondo.add_child(cam)
	cam.look_at_from_position(Vector3(x * 0.5 - 1.3, 6.0, 9.0), Vector3(x * 0.5 - 1.3, 0.5, 0), Vector3.UP)
	cam.fov = 70
	cam.current = true
	for _k in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("/tmp/psx_verso.png")
	quit()
