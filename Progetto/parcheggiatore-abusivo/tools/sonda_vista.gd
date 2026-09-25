extends Node
## Che mesh ci stanno addosso a un punto: per capire perché una fotografia
## esce tutta di un colore (la camera sta dentro a qualcosa).
## SONDA_PUNTI="x,y,z;x,y,z"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(60):
		await get_tree().process_frame
	var testo: String = OS.get_environment("SONDA_PUNTI")
	for pezzo in testo.split(";"):
		var n: PackedStringArray = pezzo.split(",")
		if n.size() < 3:
			continue
		var p := Vector3(float(n[0]), float(n[1]), float(n[2]))
		print("== punto ", p)
		var pila: Array = [get_tree().root]
		while not pila.is_empty():
			var x: Node = pila.pop_back()
			for k in x.get_children():
				pila.append(k)
			if x is GeometryInstance3D and (x as GeometryInstance3D).is_visible_in_tree():
				var g := x as GeometryInstance3D
				var box: AABB = g.global_transform * g.get_aabb()
				if box.grow(0.05).has_point(p):
					print("  ", g.get_path(), "  size ", box.size.snapped(Vector3.ONE * 0.01),
						"  pos ", box.position.snapped(Vector3.ONE * 0.01))
	print("=== storte: 0 ===")
	get_tree().quit()
