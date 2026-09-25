extends SceneTree
## **L'umano di Quaternius fermo, da vicino** (0.60).
##
## Tre umani con la clip `Idle` del pacchetto (com'era fino alla 0.59) e tre
## con l'animatore, cioè con `Fermo` (0.60), girati di tre quarti.
## Uso: xvfb-run godot4 --path . --script res://tools/foto_umano_fermo.gd
## Variabili: LATO=1 per la vista di fianco, OUT per il nome del file.
const Human := preload("res://scripts/human_builder.gd")

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
	var x := -4.0
	# Girati di tre quarti verso la camera: di spalle non si capisce niente.
	# I primi tre con la clip `Idle` del pacchetto (com'era fino alla 0.59),
	# gli altri tre con l'animatore, cioè con `Fermo`.
	var modelli := ["umano_q", "umano_q", "umano_q", "umano_q", "umano_q", "umano_q"]
	var tempi := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	var gente: Array = []
	for i in modelli.size():
		var opts := {"modello": modelli[i]} if modelli[i] != "pupo" else {}
		if i < 3:
			opts["clip"] = "Idle"
		var p: Dictionary = Human.build(Color(0.3, 0.4, 0.6), Color(0.2, 0.2, 0.22), "", 1.76, opts)
		var r: Node3D = p["root"]
		mondo.add_child(r)
		r.position = Vector3(x, 0, 0)
		r.rotation.y = PI + 0.5
		gente.append([p, float(tempi[i])])
		var l := Label3D.new()
		l.text = "prima (Idle)" if i < 3 else "dopo (Fermo)"
		l.position = Vector3(x, 2.05, 0)
		l.pixel_size = 0.004
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		mondo.add_child(l)
		x += 1.6
	# Si lascia girare un secondo e mezzo: l'animatore parte da solo.
	var aspetta: float = float(OS.get_environment("ASPETTA")) if OS.get_environment("ASPETTA") != "" else 1.5
	await create_timer(aspetta).timeout
	var cam := Camera3D.new()
	mondo.add_child(cam)
	if OS.get_environment("LATO") == "1":
		cam.look_at_from_position(Vector3(12.0, 1.0, 0.0), Vector3(0.0, 1.0, 0.0), Vector3.UP)
	else:
		cam.look_at_from_position(Vector3(0.0, 1.0, 12.0), Vector3(0.0, 1.0, 0.0), Vector3.UP)
	cam.fov = 55
	# Ortografica: da lontano con la prospettiva uno di lato sembra a
	# mezzo passo anche quando sta dritto.
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 3.2 if OS.get_environment("LATO") == "1" else 5.4
	cam.current = true
	for _k in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	var out := OS.get_environment("OUT")
	if out == "":
		out = "/tmp/60_umano_fermo.png"
	get_root().get_texture().get_image().save_png(out)
	quit()
