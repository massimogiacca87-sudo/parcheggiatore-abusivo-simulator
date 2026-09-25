extends SceneTree
## **'E mosse vere, dint'ô gioco** (0.62).
##
## `foto_retarget` fotografa le clip tradotte suonate a mano sul modello.
## Questa invece passa dalla strada che fa il gioco: `Human.build` con il
## corpo nuovo, l'animatore vero (AnimationTree, stati, gesti) e i comandi
## che danno i personaggi (`set_speed`, `sit`, `action`, `parla_per`).
## Se una riga della tabella `RIG` punta a una clip sbagliata, qui si vede
## un omino in posa a T.
##   xvfb-run godot4 --path . --script res://tools/foto_animatore.gd
##   (OUT=/tmp/anim.png, CORPI="omo_casual,umano_q,")

const Human := preload("res://scripts/human_builder.gd")

var STATI := ["fermo", "cammina", "corre", "parla", "seduto", "seduto_parla",
	"accucciato", "indica", "pugno", "colpo"]


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
	pm.size = Vector2(60, 30)
	pav.mesh = pm
	mondo.add_child(pav)
	var corpi: PackedStringArray = (OS.get_environment("CORPI")
		if OS.get_environment("CORPI") != "" else "omo_casual,umano_q,").split(",")
	if OS.get_environment("STATI") != "":
		STATI = Array(OS.get_environment("STATI").split(","))
	var z := 0.0
	var animatori: Array = []
	for corpo in corpi:
		var x := -float(STATI.size() - 1) * 0.6
		for stato in STATI:
			var opts := {"modello": corpo} if corpo != "" and corpo != "pupo" else {}
			var p: Dictionary = Human.build(Color(0.7, 0.3, 0.25), Color(0.2, 0.22, 0.3),
				"", 1.76, opts)
			var r: Node3D = p["root"]
			r.position = Vector3(x, 0, z)
			r.rotation.y = float(OS.get_environment("ROT")) if OS.get_environment("ROT") != "" else PI
			mondo.add_child(r)
			animatori.append([p.get("anim"), stato])
			var l := Label3D.new()
			l.text = "%s\n%s" % [stato, corpo if corpo != "" else "pupo"]
			l.position = Vector3(x, 2.1, z)
			l.pixel_size = 0.0035
			l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			mondo.add_child(l)
			x += 1.2
		z += 2.6
	for _k in range(3):
		await process_frame
	for v in animatori:
		var a = v[0]
		if a == null:
			continue
		match str(v[1]):
			"cammina":
				a.set_speed(1.5)
			"corre":
				a.set_speed(6.0)
			"parla":
				a.parla_per(10.0)
			"seduto":
				a.sit(false)
			"seduto_parla":
				a.sit(true)
			"accucciato":
				a.set_crouching(true)
	await create_timer(1.0).timeout
	for v in animatori:
		var a = v[0]
		if a == null:
			continue
		match str(v[1]):
			"indica":
				a.action("point")
			"pugno":
				a.action("punch")
			"colpo":
				a.reagisci_colpo(false)
	await create_timer(0.35).timeout
	var cam := Camera3D.new()
	mondo.add_child(cam)
	var larg: float = float(STATI.size()) * 1.2
	cam.look_at_from_position(Vector3(0, 1.9, larg * 0.52), Vector3(0, 0.8, 0), Vector3.UP)
	cam.fov = 62
	cam.current = true
	await process_frame
	await RenderingServer.frame_post_draw
	var out := OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp/anim.png"
	get_root().get_texture().get_image().save_png(out)
	print("foto ", out)
	quit()
