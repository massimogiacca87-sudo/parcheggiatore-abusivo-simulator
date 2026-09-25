extends Node
## Sonda (0.60): **pecché 'o guagliuno s'è piantato?**
##
## `prova_ntuppate` dice *dove* un ragazzino del largo resta fermo a voler
## camminare, non *perché*. Questa sonda guarda solo i ragazzini, per
## `DURATA_SONDA` secondi (300 se non si dice), e quando uno sta fermo tre
## secondi con le gambe accese stampa tutto quello che il passo e il
## campetto sanno di lui: se è il più vicino alla palla, a che distanza, se
## sta seguendo una strada della griglia, da che parte sta girando, il
## conto della valvola, e se il passo dritto verso la palla è chiuso.

const Passo := preload("res://scripts/passo.gd")

var _storia: Dictionary = {}
var _gia: Dictionary = {}
var _t := 0.0
var _ogni := 0.0
var _durata := 300.0
var _piantati := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.get_environment("DURATA_SONDA") != "":
		_durata = float(OS.get_environment("DURATA_SONDA"))
	for _i in range(90):
		await get_tree().process_frame
	get_tree().paused = false
	GameManager.start_shift()


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_t += delta
	_ogni += delta
	if _t > _durata:
		print("=== piantati: %d ===" % _piantati)
		print("=== storte: 0 ===")
		get_tree().quit()
		return
	if _ogni < 0.5:
		return
	_ogni = 0.0
	for b in get_tree().get_nodes_in_group("bambini"):
		var ragazzi: Array = b.get("_ragazzi")
		var palla_n: Node3D = b.get("_palla")
		if ragazzi == null or palla_n == null:
			continue
		var palla: Vector3 = palla_n.position
		var vicino := -1
		var min_d := INF
		for i in ragazzi.size():
			var d: float = (ragazzi[i]["nodo"] as Node3D).position.distance_to(palla)
			if d < min_d:
				min_d = d
				vicino = i
		for i in ragazzi.size():
			var r: Dictionary = ragazzi[i]
			var n: Node3D = r["nodo"]
			var a = r.get("anim")
			var vuole := false
			if a != null:
				var v = a.get("_richiesta")
				if v == null:
					v = a.get("_velocita")
				vuole = v != null and float(v) > 0.5
			var st: Array = _storia.get(n, [])
			st.append([_t, n.global_position, vuole])
			while st.size() > 0 and _t - float(st[0][0]) > 3.01:
				st.pop_front()
			_storia[n] = st
			if st.size() < 6:
				continue
			var tutti := true
			for e in st:
				if not bool(e[2]):
					tutti = false
			var mosso: float = ((st[st.size() - 1][1] as Vector3) - (st[0][1] as Vector3)).length()
			if not tutti or mosso >= 0.3:
				_gia.erase(n)
				continue
			if _gia.has(n):
				continue
			_gia[n] = true
			_piantati += 1
			var g: Vector3 = n.global_position
			var palla_g: Vector3 = palla_n.global_position
			var dritto: Vector3 = g.move_toward(Vector3(palla_g.x, g.y, palla_g.z), 0.06)
			print("PIANTATO t=%.0f  #%d %s  a %s (locale %s)  palla %s (locale %s)  dist %.2f" % [
				_t, i, "VICINO" if i == vicino else "altro",
				str(g.snapped(Vector3.ONE * 0.1)), str(n.position.snapped(Vector3.ONE * 0.1)),
				str(palla_g.snapped(Vector3.ONE * 0.1)), str(palla.snapped(Vector3.ONE * 0.1)),
				n.position.distance_to(palla)])
			print("    r: %s" % str(_senza_nodi(r)))
			print("    passo: strada %s  i %s  per %s  gira %s  blocco %s  meta %s  meglio %s  passi %s" % [
				str(n.get_meta(Passo.STRADA, null)), str(n.get_meta(Passo.STRADA_I, null)),
				str(n.get_meta(Passo.STRADA_PER, null)), str(n.get_meta(Passo.GIRA, null)),
				str(n.get_meta(Passo.BLOCCO, null)), str(n.get_meta(Passo.META, null)),
				str(n.get_meta(Passo.MEGLIO, null)), str(n.get_meta(Passo.PASSI, null))])
			print("    chiuso qui %s  chiuso dritto verso palla %s  palla_fore %s  rot %.2f" % [
				str(Passo._chiuso(g, 0.34)), str(Passo._chiuso(dritto, 0.34)),
				str(b.get("_palla_fore")), n.rotation.y])
			var altri := ""
			for k in ragazzi.size():
				altri += " #%d %s" % [k, str((ragazzi[k]["nodo"] as Node3D).position.snapped(Vector3.ONE * 0.1))]
			print("    tutti:%s" % altri)
			var giro := ""
			for e in st:
				giro += " %.1fs %s" % [float(e[0]), str((e[1] as Vector3).snapped(Vector3.ONE * 0.1))]
			print("    finestra:%s" % giro)


func _senza_nodi(r: Dictionary) -> Dictionary:
	var fore := {}
	for k in r:
		if r[k] is Object:
			continue
		fore[k] = r[k]
	return fore
