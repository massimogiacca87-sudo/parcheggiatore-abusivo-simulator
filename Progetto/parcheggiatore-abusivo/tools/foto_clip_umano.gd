extends SceneTree
## Le clip dell'umano di Quaternius e degli omini, ferme a un tempo dato.

func _initialize() -> void:
	var mondo := Node3D.new()
	get_root().add_child(mondo)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.62, 0.7, 0.8)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.8, 0.8)
	env.environment = e
	mondo.add_child(env)
	var sole := DirectionalLight3D.new()
	sole.rotation_degrees = Vector3(-45, 25, 0)
	mondo.add_child(sole)
	var righe := [["umano_q", ["Idle", "Walk", "Run", "Working", "Punch", "Death", "Jump"]],
		["omo_casual", ["Idle", "Walk", "Run", "Sitting", "Standing", "Clapping", "Punch", "Death"]]]
	var z := 0.0
	for r in righe:
		var x := -6.0
		for clip in r[1]:
			var m: Node3D = (load("res://assets/models/%s.scn" % r[0]) as PackedScene).instantiate()
			m.rotation.y = PI
			var alt := 5.24 if r[0] == "umano_q" else 4.74
			m.scale = Vector3.ONE * (1.76 / alt)
			m.position = Vector3(x, 0, z)
			mondo.add_child(m)
			var ap: AnimationPlayer = m.find_children("*", "AnimationPlayer", true, false)[0]
			ap.play(clip)
			ap.seek(float(OS.get_environment("T")) * ap.current_animation_length, true)
			ap.pause()
			var l := Label3D.new()
			l.text = clip
			l.position = Vector3(x, 2.0, z)
			l.pixel_size = 0.006
			l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			mondo.add_child(l)
			x += 1.7
		z += 3.0
	var cam := Camera3D.new()
	mondo.add_child(cam)
	cam.look_at_from_position(Vector3(float(OS.get_environment("CX")), 2.0, float(OS.get_environment("CZ"))), Vector3(float(OS.get_environment("CX")), 0.9, float(OS.get_environment("CZ")) + 6.0), Vector3.UP)
	cam.fov = 70
	cam.current = true
	for _k in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("/tmp/59_clip_%s.png" % OS.get_environment("T"))
	quit()
