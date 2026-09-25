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
func _tri(n: Node) -> int:
	var k := 0
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m: Mesh = (mi as MeshInstance3D).mesh
		if m == null: continue
		for s in m.get_surface_count():
			var arr: Array = m.surface_get_arrays(s)
			var idx = arr[Mesh.ARRAY_INDEX]
			k += (idx.size() if idx != null else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return k
func _initialize() -> void:
	var d := DirAccess.open("res://psx")
	var nomi: Array = []
	for f in d.get_files():
		if f.ends_with(".glb"): nomi.append(f)
	nomi.sort()
	for f in nomi:
		var s: PackedScene = load("res://psx/" + f)
		var n := s.instantiate()
		var a := _aabb(n)
		var mats := 0
		print("%-34s size (%.2f, %.2f, %.2f) pos (%.2f, %.2f, %.2f) tri %d meshes %d" % [f, a.size.x, a.size.y, a.size.z, a.position.x, a.position.y, a.position.z, _tri(n), n.find_children("*", "MeshInstance3D", true, false).size()])
		n.free()
	quit()
