extends Node
## **Chi se 'ntoppa, e addó** (0.59).
##
## Il capo: *«risolvi parecchi problemi di collisioni dei personaggi con
## l'ambiente»*. `prova_mure` (0.56) guarda una cosa sola — chi sta dentro a
## un palazzo — e lì i numeri sono buoni. Ma un personaggio si può rompere
## contro l'ambiente in altri due modi, e nessuna prova li guardava:
##
## 1. **dint'a robba** — sta *dentro* a una cosa solida che non è un
##    palazzo: un'auto in sosta, una panchina, un bidone, una bancarella. I
##    palazzi sono rettangoli scritti in una tabella e chi cammina li
##    conosce; le cose appoggiate in strada no.
## 2. **'ntuppato** — vuole andare da qualche parte e non ci va: sta contro
##    un muro o contro una macchina e spinge. È il difetto che si vede di
##    più, perché dura: uno che attraversa una panchina lo vedi un secondo,
##    uno piantato contro un portone lo vedi finché non cambi strada.
##
## La prova accende la città, apre la giornata e guarda tutti due volte al
## secondo per due minuti.

const Citta := preload("res://scripts/citta_3d.gd")

## Chi cammina, per gruppo. I passanti non stavano nemmeno nell'elenco di
## `prova_mure`: si muovono col motore fisico e quindi «non possono»
## entrare nei muri — ma possono restarci attaccati, ed è la stessa cosa.
const GRUPPI := ["passanti", "drivers", "vigili", "bambini", "carabinieri",
	"signore", "borrelli", "sbirri", "rivali", "guagliuni", "boss_capitolo"]

const DURATA: float = 120.0
const OGNI: float = 0.5
## Quanto deve restare fermo uno che vuole camminare per dire che è
## piantato: tre secondi. Meno è una frenata, un'esitazione, una curva.
const FERMO_PER: float = 3.0

var _visti: Dictionary = {}       # gruppo → campioni
var _in_robba: Dictionary = {}    # gruppo → campioni dentro a una cosa
var _in_muro: Dictionary = {}     # gruppo → campioni dentro a un palazzo
var _piantati: Dictionary = {}    # gruppo → quante volte piantato
var _dove_robba: Dictionary = {}  # nome del solido → volte
var _dove_muro: Dictionary = {}   # "gruppo (x, z)" → volte
var _storia: Dictionary = {}      # nodo → [[t, pos, vuole_camminare], ...]
var _gia_piantato: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(90):
		await get_tree().process_frame
	get_tree().paused = false
	GameManager.start_shift()
	# Con `DURATA_NTUPPATE=600` si guarda più a lungo (0.60): i piantati «una
	# volta ogni tanto» si trovano solo così.
	var durata: float = DURATA
	if OS.get_environment("DURATA_NTUPPATE") != "":
		durata = float(OS.get_environment("DURATA_NTUPPATE"))
	var t := 0.0
	while t < durata:
		await get_tree().create_timer(OGNI).timeout
		t += OGNI
		_guarda(t)
	var male := 0
	print("=== CHI SE 'NTOPPA (%d s, uno sguardo ogni %.1f s) ===" % [
		int(durata), OGNI])
	print("  %-14s %7s %9s %9s %9s" % ["gruppo", "sguardi", "dint'a robba",
		"dint'ô muro", "piantati"])
	for g in GRUPPI:
		var v: int = int(_visti.get(g, 0))
		if v == 0:
			continue
		var r: int = int(_in_robba.get(g, 0))
		var m: int = int(_in_muro.get(g, 0))
		var p: int = int(_piantati.get(g, 0))
		print("  %-14s %7d %9d %9d %9d" % [g, v, r, m, p])
		# Una soglia, non lo zero: un passo su cento dentro allo spigolo di
		# una panchina è l'arrotondamento di chi gira un angolo stretto. Un
		# personaggio piantato invece è sempre un difetto.
		if r * 100 > v * 1:
			male += 1
			print("    STORTO: %s dint'a robba %.1f%% d''e vote" % [g, 100.0 * r / v])
		if m > 0:
			male += 1
			print("    STORTO: %s dint'ô muro %d vote" % [g, m])
		if p > 0:
			male += 1
			print("    STORTO: %s piantati %d vote" % [g, p])
	if not _dove_robba.is_empty():
		print("  addó se 'ntoppano:")
		var ks: Array = _dove_robba.keys()
		ks.sort_custom(func(a, b): return int(_dove_robba[a]) > int(_dove_robba[b]))
		for k in ks.slice(0, 12):
			print("    %4d  %s" % [int(_dove_robba[k]), str(k)])
	if not _dove_muro.is_empty():
		print("  addó stanno dint'ô muro:")
		var km: Array = _dove_muro.keys()
		km.sort_custom(func(a, b): return int(_dove_muro[a]) > int(_dove_muro[b]))
		for k in km.slice(0, 16):
			print("    %4d  %s" % [int(_dove_muro[k]), str(k)])
	print("=== storte: %d ===" % male)
	get_tree().quit()


func _guarda(t: float) -> void:
	var spazio := get_viewport().get_world_3d().direct_space_state
	var palla := SphereShape3D.new()
	palla.radius = 0.12
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = palla
	q.collision_mask = 1
	q.collide_with_areas = false
	for g in GRUPPI:
		for n in get_tree().get_nodes_in_group(g):
			for chi in _pupe(n):
				var c: Node3D = chi
				if not c.is_inside_tree() or not c.is_visible_in_tree():
					continue
				var p: Vector3 = c.global_position
				# La casa sta fuori dalla pianta, e chi guida sta in macchina.
				if p.x > 220.0 or p.z > 200.0 or p.x < -30.0:
					continue
				if _dint_a_machina(c):
					continue
				_visti[g] = int(_visti.get(g, 0)) + 1
				if Citta.dint_ô_palazzo(p, 0.05):
					_in_muro[g] = int(_in_muro.get(g, 0)) + 1
					var km := "%s (%.0f, y %.1f, %.0f)" % [g, p.x, p.y, p.z]
					_dove_muro[km] = int(_dove_muro.get(km, 0)) + 1
				q.transform = Transform3D(Basis(), p + Vector3(0, 0.9, 0))
				var io: Array = [c.get_rid()] if c is CollisionObject3D else []
				q.exclude = io
				for h in spazio.intersect_shape(q, 8):
					var col: Object = h.get("collider")
					if col == null or not (col is Node):
						continue
					# Il tavolino della scopa contiene i suoi vecchi: chi sta
					# dentro al suo stesso nodo non conta.
					if (col as Node).is_ancestor_of(c) or c.is_ancestor_of(col as Node):
						continue
					_in_robba[g] = int(_in_robba.get(g, 0)) + 1
					var nome := _nome_di(col as Node, p)
					_dove_robba[nome] = int(_dove_robba.get(nome, 0)) + 1
					break
				_piantato(g, c, t)


## Chi vuole camminare e non cammina. Per i passanti si sa: se non stanno
## in sosta e non sono stesi, vogliono andare. Per gli altri si guarda
## l'animatore: se muove le gambe (velocità del passo sopra al mezzo metro
## al secondo) vuol camminare.
func _piantato(g: String, c: Node3D, t: float) -> void:
	var vuole := false
	if g == "passanti":
		var sosta = c.get("_sosta")
		var ko = c.get("_ko")
		var steso := false
		if ko is Dictionary:
			steso = bool((ko as Dictionary).get("down", false))
		vuole = sosta != null and float(sosta) <= 0.0 and not steso \
			and not (c.get("tappe") as Array).is_empty()
	else:
		# Si legge quanto *chiede* di andare (dalla 0.59 le gambe vanno alla
		# velocità vera, che per uno piantato è zero: guardando quella la
		# prova non vedrebbe più nessuno piantato).
		var a := c.find_child("Animator", true, false)
		if a != null:
			var v = a.get("_richiesta")
			if v == null:
				v = a.get("_velocita")
			vuole = v != null and float(v) > 0.5
	var st: Array = _storia.get(c, [])
	st.append([t, c.global_position, vuole])
	while st.size() > 0 and t - float(st[0][0]) > FERMO_PER + 0.01:
		st.pop_front()
	_storia[c] = st
	if st.size() < int(FERMO_PER / OGNI):
		return
	for e in st:
		if not bool(e[2]):
			_gia_piantato.erase(c)
			return
	# **Piantato è chi nun se move, no chi va e torna** (0.60). Fino alla
	# 0.59 si guardava solo il primo e l'ultimo campione della finestra:
	# un ragazzino che corre tre metri verso la palla, la vede rimessa in
	# mezzo e torna indietro finisce in tre secondi dov'era partito, e
	# risultava «piantato». Lo ha fatto vedere `sonda_guagliune`, che stampa
	# tutta la finestra: tutte e cinque le volte in cinque minuti erano
	# corse di andata e ritorno. Adesso è piantato chi resta **per tutta la
	# finestra** dentro a trenta centimetri dal punto di partenza, oppure
	# chi torna al punto di partenza senza essersene mai allontanato più di
	# un metro: quello è il tremolio contro uno spigolo, avanti e indietro,
	# che è proprio il caso che la prova deve prendere.
	var d_max := 0.0
	for e in st:
		var d: Vector3 = (e[1] as Vector3) - (st[0][1] as Vector3)
		d.y = 0.0
		d_max = maxf(d_max, d.length())
	var netto: Vector3 = (st[st.size() - 1][1] as Vector3) - (st[0][1] as Vector3)
	netto.y = 0.0
	if d_max < 0.30 or (netto.length() < 0.30 and d_max < 1.0):
		if not _gia_piantato.has(c):
			_gia_piantato[c] = true
			_piantati[g] = int(_piantati.get(g, 0)) + 1
			var extra := ""
			if g == "passanti":
				var strada = c.get("_strada")
				var ii = c.get("_i_strada")
				var tp: Array = c.get("tappe")
				var idx = c.get("_idx")
				if strada is PackedVector3Array and ii != null:
					var prossimo := Vector3.ZERO
					if int(ii) < (strada as PackedVector3Array).size():
						prossimo = (strada as PackedVector3Array)[int(ii)]
					extra = "  punto %d/%d %s tappa %s y %.2f" % [int(ii),
						(strada as PackedVector3Array).size(), str(prossimo.snapped(Vector3.ONE * 0.1)),
						str((tp[int(idx)] as Vector3)), c.global_position.y]
			if g == "bambini" and c.get_parent() != null:
				var palla = c.get_parent().get("_palla")
				if palla is Node3D:
					extra = "  palla a %s" % str((palla as Node3D).global_position.snapped(Vector3.ONE * 0.1))
			print("  PIANTATO  %-10s a (%.1f, %.1f) t=%.0f s  vicino: %s%s" % [g,
				c.global_position.x, c.global_position.z, t,
				_che_ce_vicino(c), extra])
	else:
		_gia_piantato.erase(c)


## Le forme solide entro un metro: nome, tipo e misura. Serve a capire
## contro che cosa si è piantato.
func _che_ce_vicino(c: Node3D) -> String:
	var spazio := get_viewport().get_world_3d().direct_space_state
	var palla := SphereShape3D.new()
	palla.radius = 0.9
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = palla
	q.collision_mask = 1
	q.transform = Transform3D(Basis(), c.global_position + Vector3(0, 0.9, 0))
	if c is CollisionObject3D:
		q.exclude = [c.get_rid()]
	var fore: Array = []
	for h in spazio.intersect_shape(q, 6):
		var col: Object = h.get("collider")
		if not (col is Node):
			continue
		var idx: int = int(h.get("shape", 0))
		var desc := str((col as Node).name)
		if col is CollisionObject3D:
			var owner_id: int = (col as CollisionObject3D).shape_find_owner(idx)
			var sh_owner = (col as CollisionObject3D).shape_owner_get_owner(owner_id)
			if sh_owner is CollisionShape3D:
				var sh: Shape3D = (sh_owner as CollisionShape3D).shape
				var pos: Vector3 = (sh_owner as CollisionShape3D).global_position
				if sh is BoxShape3D:
					desc += " box %s a (%.1f,%.1f,%.1f)" % [str((sh as BoxShape3D).size.snapped(Vector3.ONE * 0.1)), pos.x, pos.y, pos.z]
				else:
					desc += " %s a (%.1f,%.1f,%.1f)" % [sh.get_class(), pos.x, pos.y, pos.z]
		var par: Node = (col as Node).get_parent()
		if par != null:
			desc = str(par.name) + "/" + desc
		fore.append(desc)
	return "; ".join(fore) if not fore.is_empty() else "niente"


func _dint_a_machina(c: Node3D) -> bool:
	var n: Node = c.get_parent()
	while n != null:
		var sc: Script = n.get_script()
		if sc != null and str(sc.resource_path).ends_with("car_3d.gd"):
			return true
		n = n.get_parent()
	return false


func _nome_di(n: Node, dove: Vector3) -> String:
	var fore := str(n.name)
	var p: Node = n.get_parent()
	if p != null:
		fore = "%s/%s" % [str(p.name), fore]
	var s: Script = n.get_script()
	if s == null and p != null:
		s = p.get_script()
	if s != null:
		fore += " (%s)" % str(s.resource_path).get_file()
	# I solidi della città sono un corpo solo all'origine con la forma
	# spostata: la posizione del nodo non dice niente. Si scrive dove stava
	# chi ci è finito dentro, arrotondato al metro.
	fore += " vicino a (%.0f, %.0f)" % [dove.x, dove.z]
	return fore


## Chi cammina dentro a un nodo: per i ragazzini è ognuno di loro, non il
## campetto (vedi `prova_mure`).
func _pupe(n: Node) -> Array:
	if not (n is Node3D):
		return []
	if not n.is_in_group("bambini"):
		return [n]
	var fore: Array = []
	for c in n.get_children():
		if c is Node3D and c.get_class() == "Node3D" \
				and c.get_child_count() > 0:
			fore.append(c)
	return fore if not fore.is_empty() else [n]
