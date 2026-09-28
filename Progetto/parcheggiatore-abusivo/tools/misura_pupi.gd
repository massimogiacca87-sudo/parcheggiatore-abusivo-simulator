extends SceneTree
## **Quanto costa 'na folla 'e pupe** (0.66).
##
## Quaranta persone a caso (corporature, capelli, facce, colletti, cinture,
## catenine, gonne, come le pesca il gioco) in un quadrato di 12 × 12 metri
## davanti alla camera, con la luce del sole e le sue ombre, e si leggono le
## chiamate di disegno e i triangoli del fotogramma. Col pupo che sta nel
## gioco, o con un altro:
##
##   godot --path . --rendering-driver opengl3 --script res://tools/misura_pupi.gd -- [pupo.scn]
##
## Serve a confrontare il pupo vecchio e quello nuovo a parità di scena.

const Human := preload("res://scripts/human_builder.gd")

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0 and a[0] != "":
		Human._scena = load(a[0])
	seed(66)
	var mondo := Node3D.new()
	get_root().add_child(mondo)
	var sole := DirectionalLight3D.new()
	sole.rotation_degrees = Vector3(-42, -128, 0)
	sole.shadow_enabled = true
	mondo.add_child(sole)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	we.environment = env
	mondo.add_child(we)
	var corpi := ["normale", "panzone", "magro", "femmina"]
	for i in range(40):
		var c: String = corpi[i % 4]
		var o := {"corpo": c}
		if c == "femmina":
			o["gonna"] = i % 8 < 4
		var p: Dictionary = Human.build(Color(randf(), randf(), randf()),
			Color(0.2, 0.2, 0.25), "", randf_range(1.6, 1.85), o)
		var r: Node3D = p["root"]
		r.position = Vector3(-6.0 + (i % 8) * 1.7, 0.0, 3.0 + (i / 8) * 2.4)
		r.rotation.y = PI
		mondo.add_child(r)
	var cam := Camera3D.new()
	cam.fov = 70
	mondo.add_child(cam)
	cam.look_at_from_position(Vector3(0, 2.2, -4.0), Vector3(0, 1.0, 8.0), Vector3.UP)
	cam.current = true
	for _k in range(20):
		await process_frame
	var dc := 0
	var prim := 0
	for _k in range(10):
		await process_frame
		dc += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		prim += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print("  MISURA %s: %d chiamate, %d triangoli per fotogramma (40 persone)" % [
		a[0] if a.size() > 0 and a[0] != "" else "pupo del gioco", dc / 10, prim / 10])
	quit()
