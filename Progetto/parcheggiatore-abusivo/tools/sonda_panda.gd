extends SceneTree
## Le misure di tutte le `.mesh` di Pandazole (base a quota zero).

func _initialize() -> void:
	var d := DirAccess.open("res://assets/models")
	var nomi: Array = []
	for f in d.get_files():
		if f.ends_with(".mesh"):
			nomi.append(f)
	nomi.sort()
	for f in nomi:
		var m: Mesh = load("res://assets/models/" + f)
		var a: AABB = m.get_aabb()
		print("%-24s %5.2f x %5.2f x %5.2f   base %.2f  centro (%.2f, %.2f)  tri %d" % [f.get_basename(),
			a.size.x, a.size.y, a.size.z, a.position.y, a.get_center().x, a.get_center().z,
			_tri(m)])
	quit()


func _tri(m: Mesh) -> int:
	var n := 0
	for s in m.get_surface_count():
		var arr: Array = m.surface_get_arrays(s)
		var idx = arr[Mesh.ARRAY_INDEX]
		n += (idx.size() if idx != null else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return n
