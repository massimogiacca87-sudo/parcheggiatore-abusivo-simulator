extends Node
## Sonda (0.62): che c'è attorno a un punto (env PX, PZ, R). Stampa i corpi
## solidi, i nodi con nome e le istanze dei gruppi batch vicini.
var _t := 0.0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _process(d: float) -> void:
	_t += d
	if _t < 4.0:
		return
	set_process(false)
	var px := float(OS.get_environment("PX")); var pz := float(OS.get_environment("PZ"))
	var r := float(OS.get_environment("R")) if OS.get_environment("R") != "" else 3.0
	var c = get_tree().get_first_node_in_group("citta")
	print("STRADE che contengono:")
	for s in c.STRADE:
		if px >= float(s[0]) and px <= float(s[2]) and pz >= float(s[1]) and pz <= float(s[3]):
			print("   ", s)
	for n in _tutte(get_tree().root):
		if n is Node3D and not (n is CollisionShape3D):
			var p: Vector3 = (n as Node3D).global_position
			if Vector2(p.x - px, p.z - pz).length() < r:
				var extra := ""
				if n is StaticBody3D:
					for ch in n.get_children():
						if ch is CollisionShape3D and ch.shape is BoxShape3D:
							extra += " box %s" % str(ch.shape.size)
				print("  %s  %s  %s gruppi=%s%s" % [n.get_path(), n.get_class(), str(p), str(n.get_groups()), extra])
		if n is MultiMeshInstance3D:
			var mm: MultiMesh = n.multimesh
			if mm == null: continue
			for i in mm.instance_count:
				var tr: Transform3D = (n as Node3D).global_transform * mm.get_instance_transform(i)
				if Vector2(tr.origin.x - px, tr.origin.z - pz).length() < r:
					print("  MM %s [%d] %s" % [n.name, i, str(tr.origin)])
	get_tree().quit()
func _tutte(n: Node) -> Array:
	var f: Array = [n]
	for ch in n.get_children():
		f.append_array(_tutte(ch))
	return f
