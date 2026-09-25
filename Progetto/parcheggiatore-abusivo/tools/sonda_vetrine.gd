extends Node
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(30):
		await get_tree().process_frame
	var citta := get_tree().get_first_node_in_group("citta")
	print("  vetrine: ", get_tree().get_nodes_in_group("negozi").size())
	for v in citta.get("_vetrine_scartate"):
		var pos: Vector3 = v[0]
		var ang: float = deg_to_rad(float(v[1]))
		print("    scartata %s ang %d: %s" % [str(pos.round()), int(v[1]), " ".join(PackedStringArray(v[2]))])
		# Chi blocca la merce allo scorrimento 0
		var avanti := Vector3(sin(ang), 0.0, cos(ang))
		var c: Vector3 = pos + avanti * 0.9
		for e in citta.get("_ingombri"):
			if (e[0] as Vector2).distance_to(Vector2(c.x, c.z)) < 3.6:
				print("        ngombro a %s r %.2f dim %.2fx%.2f" % [str((e[0] as Vector2).snapped(Vector2.ONE * 0.1)), float(e[1]), float(e[2]) * 2.0, float(e[3]) * 2.0])
	print("=== storte: 0 ===")
	get_tree().quit()
