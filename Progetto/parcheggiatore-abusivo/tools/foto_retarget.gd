extends SceneTree
## Le clip del pupo tradotte sugli omini e sull'umano (0.62), una accanto
## all'altra: in alto il pupo (l'originale), in mezzo l'omo, sotto l'umano.
##   CLIP="Sitting_Idle,Idle_Talking,..." T=0.3 VISTA=fronte|fianco
##   xvfb-run godot4 --path . --script res://tools/foto_retarget.gd

func _initialize() -> void:
	var mondo := Node3D.new()
	get_root().add_child(mondo)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.62, 0.7, 0.8)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.75, 0.75)
	env.environment = e
	mondo.add_child(env)
	var sole := DirectionalLight3D.new()
	sole.rotation_degrees = Vector3(-45, 25, 0)
	mondo.add_child(sole)
	var pav := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	pav.mesh = pm
	mondo.add_child(pav)
	var clips: PackedStringArray = OS.get_environment("CLIP").split(",")
	var t: float = float(OS.get_environment("T")) if OS.get_environment("T") != "" else 0.3
	var righe := [["pupo", ""], ["omo_casual", "res://assets/models/omo_ual.res"],
		["umano_q", "res://assets/models/umano_q_ual.res"]]
	if OS.get_environment("CORPO") != "":
		var tutte := righe
		righe = []
		for r0 in tutte:
			if str(r0[0]) == OS.get_environment("CORPO"):
				righe.append(r0)
	var z := 0.0
	for r in righe:
		var x := -float(clips.size() - 1) * 0.9
		for clip in clips:
			var m: Node3D = (load("res://assets/models/%s.scn" % r[0]) as PackedScene).instantiate()
			var alt := 1.79
			if r[0] == "umano_q":
				alt = 5.24
				m.rotation.y = PI
			elif r[0] == "omo_casual":
				alt = 4.74
				m.rotation.y = PI
			m.scale = Vector3.ONE * (1.76 / alt)
			m.position = Vector3(x, 0, z)
			mondo.add_child(m)
			var ap: AnimationPlayer = m.find_children("*", "AnimationPlayer", true, false)[0]
			var nome: String = clip
			if str(r[1]) != "" and not clip.begins_with("!"):
				if not ap.has_animation_library("ual"):
					ap.add_animation_library("ual", load(str(r[1])))
				nome = "ual/" + clip
			elif clip.begins_with("!"):
				nome = clip.substr(1)
			if ap.has_animation(nome):
				ap.play(nome)
				ap.seek(t * ap.current_animation_length, true)
				ap.pause()
			var l := Label3D.new()
			l.text = "%s\n%s" % [clip, r[0]]
			l.position = Vector3(x, 2.1, z)
			l.pixel_size = 0.004
			l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			mondo.add_child(l)
			x += 1.8
		z += 2.4
	var cam := Camera3D.new()
	mondo.add_child(cam)
	var cx := 0.0
	var fianco: bool = OS.get_environment("VISTA") == "fianco"
	var larg: float = float(clips.size()) * 1.8
	if fianco:
		# Di tre quarti da destra: si vedono profilo e braccia.
		cam.look_at_from_position(Vector3(larg * 0.25, 1.5, larg * 0.62), Vector3(0, 0.85, 0), Vector3.UP)
	else:
		cam.look_at_from_position(Vector3(cx, 1.4, larg * 0.58 + 1.0), Vector3(cx, 0.85, 0), Vector3.UP)
	cam.fov = 60
	cam.current = true
	for _k in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	var nomef := "/tmp/rt_%s_%s.png" % [OS.get_environment("NOME"), "fianco" if fianco else "fronte"]
	get_root().get_texture().get_image().save_png(nomef)
	print("foto ", nomef)
	quit()
