extends Node
## **'E piazze se pigliano, e po' faticano?** (0.64)
##
## Il capo: *«Assicurati innanzitutto che funziona il sistema di conquistare
## le altre piazze, con i soldi o con i pugni. Assicurati che una volta
## acquisite, funzionino esattamente come la tua: entrando in piazza
## cominciano ad arrivare auto da parcheggiare, esattamente come nella tua
## piazza di default.»*
##
## `prova_boss` e `prova_piazze` guardano i numeri; `prova_guagliune_vere`
## guarda il guaglione. Nessuna prova aveva mai fatto **il giocatore** in
## una piazza conquistata. Questa la gioca:
##
##   1. si compra il mercato dal rivale (due [E], come in partita) stando
##      in piazza sua;
##   2. si prende lo stadio a mazzate;
##   3. si compra la cornetteria;
##   4. in ognuna delle quattro piazze, casa compresa, il giocatore entra e
##      ci resta: si contano le auto che arrivano, quanto ci mette la prima,
##      quante se ne possono guidare dentro a un posto **di quella piazza**,
##      e quanti soldi lasciano gli autisti.
##
## Il confronto è con la piazza di casa, alla stessa ora: una piazza
## conquistata deve lavorare come quella (col suo carattere, ma senza buchi).

const DURATA: float = 100.0
## L'ora a cui si lavora: il pomeriggio, lontano dalla notte (la cornetteria
## di notte è un'altra piazza, e si guarda a parte).
const ORA_FRAZIONE: float = 0.62

var storte: int = 0
var _nate := {}
var _traccia := {}
var _pl: Node3D = null


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(120):
		await get_tree().process_frame
	get_tree().paused = false
	GameManager.start_shift()
	GameManager.money = 5000
	GameManager.health = GameManager.HEALTH_MAX
	_pl = get_tree().get_first_node_in_group("player") as Node3D
	if _pl == null:
		male("nun ce sta 'o giocatore")
		_fine()
		return

	print("=== 1. 'O MERCATO, ACCATTATO ===")
	await _compra("mercato")
	print("=== 2. 'O STADIO, A MAZZATE ===")
	await _mazzate("stadio")
	print("=== 3. 'A CORNETTERIA, ACCATTATA ===")
	await _compra("cornetteria")

	print("=== 4. SE FATICA? ===")
	var rese := {}
	for z in ["piazza", "mercato", "stadio", "cornetteria"]:
		rese[z] = await _fatica(z)
	var casa: Dictionary = rese["piazza"]
	for z in ["mercato", "stadio", "cornetteria"]:
		var r: Dictionary = rese[z]
		# Il carattere della piazza cambia il passo (il mercato ne fa di
		# più, la cornetteria di giorno di meno): la soglia lo tiene in conto.
		var atteso: float = float(casa["arrivate"]) * GameManager.carattere(z)["auto"]
		if float(r["arrivate"]) < maxf(2.0, atteso * 0.5):
			male("%s: so' arrivate %d machine contro %d d''a casa (me n'aspettavo almeno %.0f)"
				% [z, r["arrivate"], casa["arrivate"], maxf(2.0, atteso * 0.5)])
		if int(r["posteggiate"]) < 1:
			male("%s: nisciuna machina posteggiata" % z)
		if int(r["pavate"]) < 1:
			male("%s: nisciuno ha pavato" % z)
	_fine()


func _fine() -> void:
	print("=== storte: %d ===" % storte)
	get_tree().quit()


func _process(_d: float) -> void:
	for c in get_tree().get_nodes_in_group("cars"):
		if not c.has_meta("contata"):
			c.set_meta("contata", true)
			var z := str(c.get("zona_id"))
			_nate[z] = int(_nate.get(z, 0)) + 1


func _rect(z: String) -> Array:
	for zz in load("res://scripts/citta_3d.gd").ZONE:
		if str(zz["id"]) == z:
			return zz["rect"]
	return []


func _dentro(z: String, p: Vector3) -> bool:
	var r := _rect(z)
	return r.size() == 4 and p.x >= r[0] and p.x <= r[2] and p.z >= r[1] and p.z <= r[3]


func _aspetta(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _metti_giocatore(p: Vector3) -> void:
	p.y = Collina.alzata(p.x, p.z) + 0.2
	_pl.global_position = p
	if _pl is CharacterBody3D:
		(_pl as CharacterBody3D).velocity = Vector3.ZERO


func _rivale(z: String) -> Node3D:
	return get_tree().root.find_child("Rivale_" + z, true, false) as Node3D


func _compra(z: String) -> void:
	var riv := _rivale(z)
	if riv == null:
		male("nun trovo 'o rivale d''o %s" % z)
		return
	# Il giocatore sta nella piazza del rivale, accanto a lui: è lì che si
	# tratta, e in partita non c'è altro modo.
	var accanto: Vector3 = riv.global_position + Vector3(1.4, 0, 0)
	if not _dentro(z, accanto):
		accanto = riv.global_position - Vector3(1.4, 0, 0)
	_metti_giocatore(accanto)
	await _aspetta(0.6)
	if GameManager.zona_corrente != z:
		male("%s: zona_corrente dice '%s'" % [z, GameManager.zona_corrente])
	if GameManager.in_servizio:
		male("%s: 'n servizio dint'â piazza 'e n'ato" % z)
	var prezzo: int = GameManager.prezzo_zona()
	var primma: int = GameManager.money
	riv.player_interact()
	await _aspetta(0.3)
	if GameManager.zona_mia(z):
		male("%s: s'è accattata c'un [E] sulo" % z)
	riv.player_interact()
	await _aspetta(0.6)
	if not GameManager.zona_mia(z):
		male("%s: doppo 'o secondo [E] nun è mia" % z)
		return
	if GameManager.money != primma - prezzo:
		male("%s: pavata €%d invece 'e €%d" % [z, primma - GameManager.money, prezzo])
	if not GameManager.affitti.has(z):
		male("%s: accattata senza affitto" % z)
	print("  %s accattata pe' €%d (affitto €%d)" % [z, prezzo, int(GameManager.affitti.get(z, 0))])
	# **'O punto d''o capo**: stai già dentro. Da adesso la piazza è tua e
	# ci sei in mezzo: il lavoro si deve accendere senza uscire e rientrare.
	if not GameManager.in_servizio:
		male("%s: accattata stanno dinto, ma nun so' 'n servizio (s'appiccia sulo ascenno e trasenno)" % z)
	if GameManager.piazza_corrente == "":
		male("%s: piazza_corrente vacante doppo l'acquisto" % z)
	_controlla_cartiello(z)


func _mazzate(z: String) -> void:
	var riv := _rivale(z)
	if riv == null:
		male("nun trovo 'o rivale d''o %s" % z)
		return
	var accanto: Vector3 = riv.global_position + Vector3(1.4, 0, 0)
	if not _dentro(z, accanto):
		accanto = riv.global_position - Vector3(1.4, 0, 0)
	_metti_giocatore(accanto)
	await _aspetta(0.6)
	GameManager.armi["mazza"] = true
	GameManager.arma_in_mano = "mazza"
	var danno: int = int(GameManager.ARMI["mazza"]["danno"])
	var colpi := 0
	while not GameManager.zona_mia(z) and colpi < 40:
		riv.receive_punch(danno)
		colpi += 1
		GameManager.health = GameManager.HEALTH_MAX
		await _aspetta(0.25)
	if not GameManager.zona_mia(z):
		male("%s: %d botte 'e mazza e 'a piazza nun è mia" % [z, colpi])
		return
	print("  %s pigliato cu %d botte 'e mazza (stelle: %d)" % [z, colpi, GameManager.stelle])
	if GameManager.stelle < 1:
		male("%s: pigliata a mazzate senza manco 'na stella" % z)
	if GameManager.affitti.has(z):
		male("%s: pigliata a mazzate e pure cu l'affitto" % z)
	if not GameManager.in_servizio:
		male("%s: pigliata stanno dinto, ma nun so' 'n servizio" % z)
	_controlla_cartiello(z)
	# Per la prova i carabinieri non servono: si ricomincia puliti.
	GameManager.azzera_stelle()
	for cc in get_tree().get_nodes_in_group("carabinieri"):
		cc.queue_free()


## Il cartello all'ingresso dice di chi è la piazza: dopo, deve dire «tu».
func _controlla_cartiello(z: String) -> void:
	var citta := get_tree().root.find_child("Citta3D", true, false)
	if citta == null:
		citta = get_tree().get_first_node_in_group("citta")
	if citta == null or not citta.has_method("cartiello_d_a_zona"):
		male("%s: nun trovo 'o cartiello d''a zona" % z)
		return
	var t: String = str(citta.cartiello_d_a_zona(z))
	var z_dict: Dictionary = citta.zona_per_id(z)
	if t.find(str(z_dict.get("padrone", "?"))) >= 0:
		male("%s: 'o cartiello dice ancora «%s»" % [z, t.replace("\n", " / ")])


## Il giocatore entra in piazza e ci lavora: ogni macchina che aspetta la
## guida dentro a un posto (la regia a gesti si salta: la macchina si mette
## sul posto, dritta e ferma, e il resto lo fa il gioco), e ogni autista
## che scende si ferma a pagare.
func _fatica(z: String) -> Dictionary:
	var r := _rect(z)
	# Si parte da fuori: in giro per la città, come chi arriva.
	_metti_giocatore(Vector3(90, 0, 88))
	await _aspetta(1.0)
	GameManager.shift_time_left = GameManager.shift_duration * ORA_FRAZIONE
	var dove := Vector3((r[0] + r[2]) * 0.5, 0.0, (r[1] + r[3]) * 0.5)
	var zz: Dictionary = {}
	for q in load("res://scripts/citta_3d.gd").ZONE:
		if str(q["id"]) == z:
			zz = q
	if zz.has("posto"):
		dove = zz["posto"]
	# Le macchine già in piazza (arrivate mentre stavo fuori) contano a parte.
	var gia := {}
	for c in get_tree().get_nodes_in_group("cars"):
		if str(c.get("zona_id")) == z:
			gia[c.get_instance_id()] = true
	var gia_da_servire := 0
	for c in get_tree().get_nodes_in_group("cars"):
		if str(c.get("zona_id")) == z and int(c.get("state")) <= 2:
			gia_da_servire += 1
	# **I posti murati** (0.64): allo stadio le auto d'arredo stavano sopra
	# alle strisce. Un posto acceso con un muro dentro è un posto dove la
	# regia a gesti va a sbattere: la prova li cerca col motore fisico.
	var posti := 0
	var murati := 0
	var spazio := get_viewport().find_world_3d().direct_space_state
	for s in get_tree().get_nodes_in_group("parking_spots"):
		var sp0: Vector3 = (s as Node3D).global_position
		if not _dentro(z, sp0):
			continue
		posti += 1
		var q := PhysicsShapeQueryParameters3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.9, 1.0, 4.0)
		q.shape = box
		q.transform = Transform3D(Basis(), Vector3(sp0.x, sp0.y + 0.75, sp0.z))
		q.collision_mask = 1
		for h in spazio.intersect_shape(q, 4):
			if not (h.get("collider") is CharacterBody3D):
				murati += 1
				print("    posto murato a %s: %s" % [str(sp0), str(h.get("collider"))])
				break
	print("  %-12s %d posti, %d murati" % [z, posti, murati])
	if murati > 0:
		male("%s: %d posti cu 'nu muro 'a dinto" % [z, murati])
	# Sei posti per piazza, tranne la cornetteria: lì il posto di mezzo della
	# fila di ponente è la corsia d'ingresso (`citta_3d.POSTI_SALTATI`), e
	# ne restano cinque — per una piazza che di giorno è un deserto e di
	# notte ne tiene due o tre alla volta, bastano.
	var minimo: int = 5 if z == "cornetteria" else 6
	if posti < minimo:
		male("%s: sulo %d posti" % [z, posti])
	_metti_giocatore(dove)
	await _aspetta(0.5)
	if GameManager.zona_corrente != z:
		male("%s: sto a %s ma zona_corrente dice '%s'" % [z, str(dove), GameManager.zona_corrente])
	if not GameManager.in_servizio:
		male("%s: dint'â piazza mia e nun so' 'n servizio" % z)
	var t := 0.0
	var prima_auto := -1.0
	var arrivate := 0
	var posteggiate := 0
	var pavate := 0
	var nun_posto := 0
	var soldi := 0
	var viste := {}
	var fatte := {}
	var chieste := {}
	var fuori_piazza := 0
	var perse := 0
	_traccia.clear()
	while t < DURATA:
		await _aspetta(0.5)
		t += 0.5
		GameManager.shift_time_left = GameManager.shift_duration * ORA_FRAZIONE
		GameManager.health = GameManager.HEALTH_MAX
		GameManager.azzera_stelle()
		# Il giocatore resta in piazza: se qualcosa lo spinge fuori, torna.
		if not _dentro(z, _pl.global_position):
			_metti_giocatore(dove)
		# Chi sparisce senza essere stato guidato: dove stava e che faceva.
		var vive := {}
		for c in get_tree().get_nodes_in_group("cars"):
			if str(c.get("zona_id")) == z and is_instance_valid(c):
				vive[c.get_instance_id()] = true
		for idp in _traccia.keys():
			if not vive.has(idp):
				var tr: Dictionary = _traccia[idp]
				if not fatte.has(idp):
					perse += 1
					print("    persa senza guida: stato %d a %s (aspettava a %s, nata a %s, %.0fs fa)"
						% [tr["stato"], str(tr["pos"]), str(tr["meta"]), str(tr["nata"]), t - float(tr["t0"])])
				_traccia.erase(idp)
		for c in get_tree().get_nodes_in_group("cars"):
			if str(c.get("zona_id")) != z or not is_instance_valid(c):
				continue
			var id: int = c.get_instance_id()
			if not _traccia.has(id):
				_traccia[id] = {"nata": (c as Node3D).global_position, "t0": t}
			_traccia[id]["stato"] = int(c.get("state"))
			_traccia[id]["pos"] = (c as Node3D).global_position.snapped(Vector3(0.1, 0.1, 0.1))
			_traccia[id]["meta"] = c.get("waiting_point")
			if not viste.has(id) and not gia.has(id):
				viste[id] = true
				arrivate += 1
				if prima_auto < 0.0:
					prima_auto = t
			var st: int = int(c.get("state"))
			if st == 1 and not fatte.has(id):
				# WAITING: [E] e si guida.
				c.player_interact()
				var spot = c.get("assigned_spot")
				if spot == null or not is_instance_valid(spot):
					nun_posto += 1
					fatte[id] = true
					continue
				var sp: Vector3 = (spot as Node3D).global_position
				if not _dentro(z, sp):
					fuori_piazza += 1
				(c as Node3D).global_position = Vector3(sp.x, c.global_position.y, sp.z)
				(c as Node3D).rotation.y = 0.0
				fatte[id] = true
			elif st == 3 and not chieste.has(id):
				# PARKED: l'autista è sceso. Si va a chiudere il conto.
				var drv = c.get("_driver")
				if drv != null and is_instance_valid(drv):
					var prima_s: int = GameManager.money
					drv.player_interact()
					chieste[id] = true
					posteggiate += 1
					if bool(c.get("paid")):
						pavate += 1
						soldi += GameManager.money - prima_s
	var stati := {}
	for c in get_tree().get_nodes_in_group("cars"):
		if str(c.get("zona_id")) == z:
			var k := "s%d%s" % [int(c.get("state")), "*" if fatte.has(c.get_instance_id()) else ""]
			stati[k] = int(stati.get(k, 0)) + 1
	print("    stati 'e mo': %s · guidate %d · perse senza guida %d" % [str(stati), fatte.size(), perse])
	var po = get_tree().root.find_child("Posteggio_" + z, true, false)
	if po:
		print("    entrata %s uscita %s coda %s" % [str(po.get("_entrata")), str(po.get("_uscita")), str(po.get("_coda"))])
	if perse > 2:
		male("%s: %d machine se ne so' ghiute senza essere guidate" % [z, perse])
	print("  %-12s (già 'n coda %d) arrivate %2d (prima doppo %4.1fs) · posteggiate %2d · pavate %2d · €%3d · senza posto %d · posto fore piazza %d · nate in tutto %d"
		% [z, gia_da_servire, arrivate, prima_auto, posteggiate, pavate, soldi, nun_posto,
		fuori_piazza, int(_nate.get(z, 0))])
	if arrivate == 0:
		male("%s: in %.0f secondi nun è arrivata manco 'na machina" % [z, DURATA])
	elif gia_da_servire == 0 and prima_auto > 8.0:
		# Entrando in una piazza vuota il primo cliente arriva subito, come a
		# casa: se tarda, al giocatore pare che la piazza sia rotta.
		male("%s: piazza vacante, e 'a primma machina è arrivata doppo %.0f secondi"
			% [z, prima_auto])
	if nun_posto > 0:
		male("%s: %d machine senza posto" % [z, nun_posto])
	if fuori_piazza > 0:
		male("%s: %d machine mannate a posteggià fore d''a piazza" % [z, fuori_piazza])
	return {"arrivate": arrivate, "posteggiate": posteggiate, "pavate": pavate,
		"soldi": soldi, "prima": prima_auto}
