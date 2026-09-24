extends Node
## Sonda (0.62): che fine fanno i vigili durante la giornata?
## Stampa ogni pochi secondi quanti sono, dove stanno, in che stato.

var _t := 0.0
var _passo := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(40):
		await get_tree().process_frame
	get_tree().paused = false
	GameManager.intro_active = false
	Engine.time_scale = float(OS.get_environment("SCALA")) if OS.get_environment("SCALA") != "" else 4.0
	_stampa()


func _process(d: float) -> void:
	_t += d / maxf(Engine.time_scale, 0.01)
	if _t < 2.0:
		return
	_t = 0.0
	_passo += 1
	_stampa()
	if _passo >= int(OS.get_environment("PASSI") if OS.get_environment("PASSI") != "" else "40"):
		print("=== fernuto ===")
		get_tree().quit()


func _stampa() -> void:
	var vv := get_tree().get_nodes_in_group("vigili")
	var righe: Array = []
	for v in vv:
		if not is_instance_valid(v):
			continue
		var p: Vector3 = (v as Node3D).global_position
		var zona := str(v.get_parent().name)
		var pts: Array = v.get("patrol_points")
		var idx: int = int(v.get("_patrol_idx"))
		var tg: Vector3 = pts[idx] if idx < pts.size() else Vector3.ZERO
		righe.append("%s st=%d ch=%s (%.1f,%.1f,%.1f) meta#%d(%.1f,%.1f) blocco=%s strada=%s gira=%s tp=%.1f" % [zona, int(v.get("stato")),
			str(v.get("_chasing")), p.x, p.y, p.z, idx, tg.x, tg.z, str(v.get_meta(&"passo_blocco", -1)),
			str(v.has_meta(&"passo_strada")), str(v.get_meta(&"passo_gira", -1)), float(v.get("_t_pausa"))])
	print("[%s h%.1f] vigili=%d  %s" % [GameManager.orologio(), GameManager.ora_d_o_juorno(),
		vv.size(), " | ".join(righe)])
