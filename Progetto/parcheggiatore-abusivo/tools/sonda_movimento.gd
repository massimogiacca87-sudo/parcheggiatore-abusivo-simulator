extends Node
## Sonda (0.62): chi si muove per la città, e con che gambe?
##
## Per ogni nodo con uno script che si sposta (più di 0,3 m/s in due
## secondi) si guarda: ha uno scheletro? ha un Animator? e le gambe vanno
## (il blend della locomozione) o sta scivolando in posa ferma? Si stampa un
## riassunto per script.

var _pos: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(60):
		await get_tree().process_frame
	get_tree().paused = false
	GameManager.intro_active = false
	GameManager.start_shift()
	await get_tree().create_timer(6.0).timeout
	var tutti: Array = []
	_raccogli(get_tree().root, tutti)
	for n in tutti:
		_pos[n] = (n as Node3D).global_position
	var campioni: Dictionary = {}
	for k in range(4):
		await get_tree().create_timer(0.5).timeout
		for n in tutti:
			if not is_instance_valid(n):
				continue
			var d: float = (n as Node3D).global_position.distance_to(_pos[n])
			_pos[n] = (n as Node3D).global_position
			var chi: String = str(n.get_script().resource_path).get_file()
			if d / 0.5 < 0.3:
				continue
			var info: Dictionary = campioni.get(chi, {"mossi": 0, "senza_sk": 0,
				"scivola": 0, "esempio": ""})
			info["mossi"] = int(info["mossi"]) + 1
			var sk := _scheletro(n)
			if sk == null:
				info["senza_sk"] = int(info["senza_sk"]) + 1
				info["esempio"] = str(n.name)
			else:
				var an := _animatore(n)
				if an != null:
					var b = an.get("_velocita")
					if b != null and float(b) < 0.2:
						info["scivola"] = int(info["scivola"]) + 1
						info["esempio"] = "%s v=%.2f vera=%.2f" % [n.name, float(b), d / 0.5]
				else:
					var ap := _player(n)
					if ap == null or not ap.is_playing():
						info["scivola"] = int(info["scivola"]) + 1
						info["esempio"] = "%s (nessun player attivo)" % n.name
			campioni[chi] = info
	var chiavi := campioni.keys()
	chiavi.sort()
	for c in chiavi:
		var i: Dictionary = campioni[c]
		print("  %-26s mossi=%3d  senza_scheletro=%3d  scivola=%3d  %s" % [c,
			int(i["mossi"]), int(i["senza_sk"]), int(i["scivola"]), str(i["esempio"])])
	print("=== fernuto ===")
	get_tree().quit()


func _raccogli(n: Node, fuori: Array) -> void:
	if n is Node3D and n.get_script() != null and n != self:
		var p: String = str(n.get_script().resource_path)
		if not p.contains("citta_3d") and not p.contains("player_fps") \
				and not p.contains("golfo"):
			fuori.append(n)
	for c in n.get_children():
		_raccogli(c, fuori)


func _scheletro(n: Node) -> Skeleton3D:
	for c in n.find_children("*", "Skeleton3D", true, false):
		return c as Skeleton3D
	return null


func _animatore(n: Node) -> Node:
	for c in n.find_children("*", "Node", true, false):
		if c.get_script() != null and str(c.get_script().resource_path).ends_with("animator.gd"):
			return c
	return null


func _player(n: Node) -> AnimationPlayer:
	for c in n.find_children("*", "AnimationPlayer", true, false):
		return c as AnimationPlayer
	return null
