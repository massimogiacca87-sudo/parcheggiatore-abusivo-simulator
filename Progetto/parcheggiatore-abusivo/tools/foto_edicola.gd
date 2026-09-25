extends Node
## L'edicola votiva sul muro (0.59): due scatti, da tre metri davanti.
var _t := 0.0
var _n := 0
var _cam: Camera3D = null
var _ed: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(d: float) -> void:
	if _cam == null:
		for n in _tutte(get_tree().root):
			if n is CanvasLayer and n.has_method("_on_menu_gioca"):
				(n as CanvasLayer).visible = false
		get_tree().paused = false
		GameManager.start_shift()
		GameManager.intro_active = false
		_cam = Camera3D.new()
		_cam.fov = 62
		get_tree().root.add_child(_cam)
		return
	_t += d
	if _t < 1.0:
		return
	_t = 0.0
	_n += 1
	if _ed.is_empty():
		for n in _tutte(get_tree().root):
			if n is StaticBody3D and str(n.get("tipo")) == "edicola":
				_ed.append(n)
		print("  edicole: ", _ed.size())
	var i: int = (_n - 1) / 2
	if i >= mini(2, _ed.size()):
		get_tree().quit()
		return
	var e: Node3D = _ed[i]
	var fuori: Vector3 = e.global_transform.basis.z
	if _n % 2 == 1:
		_cam.look_at_from_position(e.global_position + fuori * 3.2 + Vector3(0.8, 1.7, 0), e.global_position + Vector3(0, 1.9, 0), Vector3.UP)
		_cam.current = true
	else:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("/tmp/59_edicola_%d.png" % i)
		print("  foto edicola %d a %s" % [i, str(e.global_position.round())])

func _tutte(n: Node) -> Array:
	var f: Array = [n]
	for c in n.get_children():
		f.append_array(_tutte(c))
	return f
