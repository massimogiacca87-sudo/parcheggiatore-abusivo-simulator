extends SceneTree
## FILA="modello:clip@t,..." → una fila di pose ferme, vista di fianco.

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
	var suolo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 30)
	suolo.mesh = pm
	mondo.add_child(suolo)
	var voci := OS.get_environment("FILA").split(",")
	var x := -float(voci.size() - 1) * 0.5 * 1.3
	for v in voci:
		var mod := v.split(":")[0]
		var resto := v.split(":")[1]
		var clip := resto.split("@")[0]
		var t := float(resto.split("@")[1])
		var m: Node3D = (load("res://assets/models/%s.scn" % mod) as PackedScene).instantiate()
		var alt := 5.24 if mod == "umano_q" else (1.79 if mod == "pupo" else 4.74)
		m.scale = Vector3.ONE * (1.76 / alt)
		m.rotation.y = -PI * 0.5
		m.position = Vector3(x, 0, 0)
		mondo.add_child(m)
		var ap: AnimationPlayer = m.find_children("*", "AnimationPlayer", true, false)[0]
		ap.play(clip)
		ap.seek(t * ap.current_animation_length, true)
		ap.pause()
		var l := Label3D.new()
		l.text = "%s\n%s %.2f" % [mod.replace("omo_", ""), clip, t]
		l.position = Vector3(x, 2.1, 0)
		l.pixel_size = 0.004
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		mondo.add_child(l)
		x += 1.3
	var cam := Camera3D.new()
	mondo.add_child(cam)
	cam.look_at_from_position(Vector3(0, 1.3, -7.0), Vector3(0, 0.9, 0), Vector3.UP)
	cam.fov = 60
	cam.current = true
	for _k in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(OS.get_environment("OUT"))
	quit()
