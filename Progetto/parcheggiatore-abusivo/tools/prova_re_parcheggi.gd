extends Node
## **'O Rre d''e Parcheggi, giocato** (0.64).
##
## Quattro sfide nella città vera, una per ogni esito: cinque macchine (la
## piazza in omaggio), tre (il guaglione), due (niente), una (le mazzate).
## Per ognuna: il Rre arriva da solo quando è ora (terzo giorno, in servizio
## da quaranta secondi), si fa avanti, si accetta con [E], parte il conto
## alla rovescia, la musica e il tic tac, le macchine arrivano di corsa, si
## posteggiano (la regia a gesti si salta: la macchina si mette sul posto,
## dritta e ferma), e a tempo scaduto si guarda cosa ha lasciato.
##
## In più: fuori dalle strisce (F) non conta, e durante la sfida il
## rubinetto normale della piazza sta chiuso.

var storte: int = 0
var _pl: Node3D = null
var _re: Node = null


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(120):
		await get_tree().process_frame
	get_tree().paused = false
	GameManager.giornata = 3
	GameManager.re_prossimo_juorno = 3
	GameManager.start_shift()
	GameManager.tipo_giornata = "normale"
	GameManager.money = 100
	_pl = get_tree().get_first_node_in_group("player") as Node3D
	_re = get_tree().root.find_child("ReParcheggi", true, false)
	if _re == null:
		male("'o Rre nun ce sta dint'â città")
		_fine()
		return
	_metti_giocatore(Vector3(31, 0, 30))
	await _aspetta(1.0)

	print("=== 0. PRIMMA D''O TIEMPO NUN VENE ===")
	_re.set("_turno_visto", 5.0)
	await _aspetta(1.5)
	if int(_re.get("stato")) != 0:
		male("'o Rre è venuto primma d''e quaranta secunne")
	GameManager.giornata = 2
	_re.set("_turno_visto", 99.0)
	await _aspetta(1.5)
	if int(_re.get("stato")) != 0:
		male("'o Rre è venuto 'o secondo juorno")
	GameManager.giornata = 3

	print("=== 1. CINCHE MACHINE: 'NA PIAZZA ===")
	var primma_zone: Array = GameManager.zone_mie.duplicate()
	var r1: Dictionary = await _sfida(5, false)
	if r1.get("contate", 0) < 5:
		male("cinche machine posteggiate, ma 'o Rre ne ha contate %d" % r1.get("contate", 0))
	if GameManager.zone_mie.size() != primma_zone.size() + 1:
		male("nisciuna piazza 'n omaggio: %s" % str(GameManager.zone_mie))
	if GameManager.re_prossimo_juorno != -1:
		male("battuto, e torna 'o juorno %d" % GameManager.re_prossimo_juorno)
	print("  zone mo': %s" % str(GameManager.zone_mie))

	print("=== 2. TRE MACHINE: 'NU GUAGLIONE ===")
	GameManager.dipendenti.erase("piazza")
	GameManager.re_prossimo_juorno = GameManager.giornata
	var r2: Dictionary = await _sfida(3, true)
	if r2.get("contate", 0) != 3:
		male("tre machine e ne ha contate %d (una fore d''e strisce nun vale)" % r2.get("contate", 0))
	if not GameManager.ha_dipendente("piazza"):
		male("tre machine e nisciun guaglione: %s" % str(GameManager.dipendenti.keys()))
	else:
		print("  guaglione: %s" % str(GameManager.dipendente("piazza").get("nome", "")))

	print("=== 3. DOJE: NIENTE ===")
	GameManager.re_prossimo_juorno = GameManager.giornata
	var soldi_primma: int = GameManager.money
	var ossa_primma: float = GameManager.health
	var r3: Dictionary = await _sfida(2, false)
	if r3.get("contate", 0) != 2:
		male("doje machine e ne ha contate %d" % r3.get("contate", 0))
	if GameManager.money != soldi_primma:
		male("doje machine e m'ha dato €%d" % (GameManager.money - soldi_primma))
	if r3.get("menato", false):
		male("doje machine e m'ha menato")
	if GameManager.re_prossimo_juorno != GameManager.giornata + GameManager.RE_RIVINCITA_DOPPO:
		male("doje machine: 'a rivincita è 'o juorno %d" % GameManager.re_prossimo_juorno)

	print("=== 4. UNA: MAZZATE ===")
	GameManager.re_prossimo_juorno = GameManager.giornata
	GameManager.health = GameManager.HEALTH_MAX
	var r4: Dictionary = await _sfida(1, false, true)
	if r4.get("contate", 0) != 1:
		male("una machina e ne ha contate %d" % r4.get("contate", 0))
	if not r4.get("menato", false):
		male("una machina e nun m'ha menato")
	if GameManager.health <= 0.0 or GameManager.hospitalized:
		male("'o Rre m'ha mannato all'ospedale")
	print("  ossa doppo 'e mazzate: %.0f / %.0f" % [GameManager.health, GameManager.HEALTH_MAX])
	_fine()


func _fine() -> void:
	print("=== storte: %d ===" % storte)
	get_tree().quit()


func _aspetta(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _metti_giocatore(p: Vector3) -> void:
	p.y = Collina.alzata(p.x, p.z) + 0.2
	_pl.global_position = p
	if _pl is CharacterBody3D:
		(_pl as CharacterBody3D).velocity = Vector3.ZERO


## Una sfida intera. `quante`: quante macchine posteggiare (poi si sta
## fermi). `una_fore`: prima di cominciare a contare se ne mette una fuori
## dalle strisce (F), che non deve valere.
func _sfida(quante: int, una_fore: bool, guarda_mazzate: bool = false) -> Dictionary:
	var esito := {"contate": 0, "menato": false}
	# Si torna in piazza e si aspetta che venga.
	_metti_giocatore(Vector3(31, 0, 30))
	_re.set("_turno_visto", 99.0)
	_re.set("_guarda_t", 0.0)
	var t := 0.0
	while int(_re.get("stato")) == 0 and t < 6.0:
		await _aspetta(0.25)
		t += 0.25
		_tieni_juorno()
	if int(_re.get("stato")) == 0:
		male("'o Rre nun è venuto (re_oggi=%s, in_servizio=%s, zona=%s)" % [
			str(GameManager.re_oggi()), str(GameManager.in_servizio), GameManager.zona_corrente])
		return esito
	# Arriva e invita.
	t = 0.0
	while int(_re.get("stato")) == 1 and t < 30.0:
		await _aspetta(0.25)
		t += 0.25
		_tieni_juorno()
	if int(_re.get("stato")) != 2:
		male("'o Rre nun è arrivato a me in %.0f secunne (stato %d, a %.1f m)" % [t,
			int(_re.get("stato")), (_re as Node3D).global_position.distance_to(_pl.global_position)])
		return esito
	print("  arrivato in %.1f s, dice: «%s»" % [t, str(_re.get_interact_prompt(Vector3.ZERO))])
	_re.player_interact()
	if int(_re.get("stato")) != 3:
		male("accettata, ma nun parte 'o conto alla rovescia (stato %d)" % int(_re.get("stato")))
		return esito
	if not GameManager.re_sfida_attiva:
		male("'a sfida nun è attiva")
	await _aspetta(0.6)
	if get_tree().root.find_child("SfidaHud", true, false) == null:
		male("nun ce sta 'o cronometro a schermo")
	await _aspetta(3.0)
	if int(_re.get("stato")) != 4:
		male("doppo 'o tre-doje-una nun è partita 'a sfida (stato %d)" % int(_re.get("stato")))
	if SoundManager.brano() != "sfida":
		male("'a musica d''a sfida nun sona: %s" % SoundManager.brano())
	var messe := 0
	var fore_messa := false
	var viste_sfida := {}
	var guidate := {}
	var normali_nate := 0
	var nate_primma := {}
	for c in get_tree().get_nodes_in_group("cars"):
		nate_primma[c.get_instance_id()] = true
	var ossa0: float = GameManager.health
	t = 0.0
	while int(_re.get("stato")) == 4 and t < 70.0:
		await _aspetta(0.25)
		t += 0.25
		_tieni_juorno()
		for c in get_tree().get_nodes_in_group("cars"):
			if not is_instance_valid(c) or str(c.get("zona_id")) != "piazza":
				continue
			var id: int = c.get_instance_id()
			if c.get("sfida") == true:
				viste_sfida[id] = true
			elif not nate_primma.has(id):
				nate_primma[id] = true
				normali_nate += 1
			if int(c.get("state")) != 1 or guidate.has(id):
				continue
			if messe >= quante and not (una_fore and not fore_messa):
				continue
			c.player_interact()
			var spot = c.get("assigned_spot")
			if spot == null or not is_instance_valid(spot):
				continue
			guidate[id] = true
			if una_fore and not fore_messa:
				fore_messa = true
				(c as Node3D).rotation.y = 0.0
				c.call("_try_park_abusive")
				continue
			var sp: Vector3 = (spot as Node3D).global_position
			(c as Node3D).global_position = Vector3(sp.x, (c as Node3D).global_position.y, sp.z)
			(c as Node3D).rotation.y = 0.0
			messe += 1
	esito["contate"] = int(_re.call("conta_sfida"))
	print("  sfida fernuta doppo %.1f s: posteggiate %d, contate %d, machine d''o Rre %d, clienti normali nate %d"
		% [t, messe, esito["contate"], viste_sfida.size(), normali_nate])
	if viste_sfida.size() < mini(quante, 5):
		male("'o Rre ha mannato sulo %d machine" % viste_sfida.size())
	if normali_nate > 0:
		male("durante 'a sfida so' nate %d machine normali 'n piazza" % normali_nate)
	if GameManager.re_sfida_attiva and int(_re.get("stato")) != 4:
		male("'a sfida è fernuta ma re_sfida_attiva è ancora vero")
	# L'esito e, se tocca, le mazzate. Si contano le botte del Rre (non le
	# ossa: in piazza passa pure 'o motorino).
	t = 0.0
	var ha_menato := false
	while int(_re.get("stato")) in [5, 6] and t < 25.0:
		await _aspetta(0.25)
		t += 0.25
		_tieni_juorno()
		if int(_re.get("stato")) == 6:
			ha_menato = true
			if guarda_mazzate and _pl is CharacterBody3D:
				(_pl as CharacterBody3D).velocity = Vector3.ZERO
	if ha_menato and int(_re.get("_botte")) > 0:
		esito["menato"] = true
		print("  botte d''o Rre: %d, ossa %.0f → %.0f" % [int(_re.get("_botte")), ossa0, GameManager.health])
	# Se ne va, e sparisce.
	t = 0.0
	while int(_re.get("stato")) != 0 and t < 20.0:
		await _aspetta(0.25)
		t += 0.25
		_tieni_juorno()
	if int(_re.get("stato")) != 0:
		male("'o Rre nun se n'è ghiuto (stato %d)" % int(_re.get("stato")))
	if get_tree().root.find_child("SfidaHud", true, false) != null:
		male("'o cronometro è rimasto a schermo")
	for c in get_tree().get_nodes_in_group("cars"):
		if is_instance_valid(c) and c.get("sfida") == true and int(c.get("state")) <= 2:
			await _aspetta(2.0)
			if is_instance_valid(c) and int(c.get("state")) <= 2:
				male("'na machina d''o Rre è rimasta 'n piazza (stato %d)" % int(c.get("state")))
			break
	return esito


func _tieni_juorno() -> void:
	GameManager.shift_time_left = maxf(GameManager.shift_time_left, GameManager.shift_duration * 0.6)
	GameManager.azzera_stelle()
