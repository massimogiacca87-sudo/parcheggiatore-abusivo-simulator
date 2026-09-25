extends SceneTree
## Le misure dei modelli delle armi (0.61): lunghezza e asse lungo.
const Models := preload("res://scripts/models.gd")

func _aabb(n: Node, xf: Transform3D, acc: Array) -> void:
	var t := xf
	if n is Node3D:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var a: AABB = t * (n as MeshInstance3D).mesh.get_aabb()
		if acc.is_empty():
			acc.append(a)
		else:
			acc[0] = (acc[0] as AABB).merge(a)
	for c in n.get_children():
		_aabb(c, t, acc)

func _init() -> void:
	for nome in ["tubo_angolo", "manganello", "curtiello", "curtiello_piccolo", "fierro", "paletta"]:
		var m = Models.spawn(nome)
		if m == null:
			print(nome, " NULL")
			continue
		var acc := []
		_aabb(m, Transform3D(), acc)
		if acc.is_empty():
			print(nome, " senza mesh")
		else:
			var a: AABB = acc[0]
			print("%-18s pos %s size %s" % [nome, str(a.position), str(a.size)])
	quit()
