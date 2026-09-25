extends Node
## 'E divise 'e vigile e carabiniere, 'a vicino e 'a luntano.

const VigileScript := preload("res://scripts/vigile_3d.gd")
const SbirroScript := preload("res://scripts/sbirro_3d.gd")
const Human := preload("res://scripts/human_builder.gd")

var _t := 0.0
var _n := 0
var _pulito := false
var _cam: Camera3D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	var mondo := Node3D.new()
	add_child(mondo)

	var suolo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 60)
	suolo.mesh = pm
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.44, 0.42, 0.40)
	suolo.material_override = mt
	mondo.add_child(suolo)

	var luce := DirectionalLight3D.new()
	luce.rotation_degrees = Vector3(-48, 34, 0)
	luce.light_energy = 1.3
	mondo.add_child(luce)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.60, 0.66, 0.74)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.64, 0.68, 0.74)
	env.ambient_light_energy = 0.9
	we.environment = env
	mondo.add_child(we)

	_cam = Camera3D.new()
	_cam.fov = 52
	mondo.add_child(_cam)
	_cam.position = Vector3(0.0, 1.45, -3.6)
	_cam.look_at(Vector3(0.0, 1.05, 0.0))
	_cam.current = true

	# Un vigile, un carabiniere e un passante qualunque, per confronto.
	var v = VigileScript.new()
	mondo.add_child(v)
	v.global_position = Vector3(-1.1, 0.0, 0.0)
	var c = SbirroScript.new()
	mondo.add_child(c)
	c.global_position = Vector3(1.1, 0.0, 0.0)
	var q := Node3D.new()
	q.position = Vector3(0.0, 0.0, 1.4)
	mondo.add_child(q)
	var p: Dictionary = Human.build(Color(0.80, 0.78, 0.72),
		Color(0.26, 0.28, 0.34), "", 1.78, {"belly": 0.45})
	q.add_child(p["root"])
	print("  divise 'n scena")


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
	if _t < 0.9:
		return
	_t = 0.0
	_n += 1
	match _n:
		1:
			_scatta("divise_vicino")
		2:
			_cam.position = Vector3(0.0, 2.4, -11.0)
			_cam.look_at(Vector3(0.0, 1.0, 0.0))
			_t = 0.5
		3:
			_scatta("divise_luntano")
			await get_tree().create_timer(0.4).timeout
			get_tree().quit()


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
	img.save_png("/tmp/%s.png" % nome)
	print("  foto: /tmp/%s.png" % nome)
