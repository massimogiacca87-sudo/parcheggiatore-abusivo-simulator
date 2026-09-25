extends SceneTree
func _aabb(n: Node) -> AABB:
	var tot := AABB()
	var primo := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null: continue
		var t := Transform3D()
		var x: Node = m
		while x != null and x != n:
			t = (x as Node3D).transform * t
			x = x.get_parent()
		var a: AABB = t * m.mesh.get_aabb()
		if primo: tot = a; primo = false
		else: tot = tot.merge(a)
	return tot
func _initialize() -> void:
	var mondo := Node3D.new()
	get_root().add_child(mondo)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.6, 0.65)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.9, 0.9, 0.9)
	e.ambient_light_energy = 0.8
	env.environment = e
	mondo.add_child(env)
	var sole := DirectionalLight3D.new()
	sole.rotation_degrees = Vector3(-40, 30, 0)
	mondo.add_child(sole)
	var d := DirAccess.open("res://psx")
	var nomi: Array = []
	for f in d.get_files():
		if f.ends_with(".glb"): nomi.append(f)
	nomi.sort()
	var da: int = int(OS.get_environment("DA"))
	var quanti: int = 40
	var col: int = 8
	for i in range(quanti):
		if da + i >= nomi.size(): break
		var f: String = nomi[da + i]
		var n: Node3D = (load("res://psx/" + f) as PackedScene).instantiate()
		var a := _aabb(n)
		var k: float = 1.6 / maxf(0.01, maxf(a.size.x, maxf(a.size.y, a.size.z)))
		n.scale = Vector3.ONE * k
		var cx: float = float(i % col) * 2.2
		var cy: float = -float(i / col) * 2.4
		n.position = Vector3(cx, cy, 0) - (a.get_center()) * k
		n.rotation.y = 0.5
		mondo.add_child(n)
		var l := Label3D.new()
		l.text = "%s\n%.2fx%.2fx%.2f" % [f.get_basename(), a.size.x, a.size.y, a.size.z]
		l.position = Vector3(cx, cy - 1.05, 0.5)
		l.pixel_size = 0.0045
		l.font_size = 28
		mondo.add_child(l)
	var cam := Camera3D.new()
	mondo.add_child(cam)
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 12.5
	cam.position = Vector3(7.7, -4.9, 20)
	cam.current = true
	for _k in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("/tmp/psx_foglio_%d.png" % da)
	quit()
