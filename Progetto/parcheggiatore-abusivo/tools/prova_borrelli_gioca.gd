extends Node
## **Borrelli ncopp'â città** (0.63).
##
## `prova_borrelli` guarda i dadi; questa guarda il gioco, nella città
## vera (trappola 39: una prova che guarda i numeri non guarda il gioco).
##
##   1. **'o vigile mannato via tre vote** alza la radio: alla terza volta
##      parte una chiamata (pattuglia o Duttore);
##   2. **'a porta B**: con il dado a cento la chiamata porta Borrelli, che
##      compare davvero in città, **vicino al giocatore** (entro 35 m) e
##      ferma il cronometro;
##   3. **nun se pò tuccà**: un pugno vero del giocatore (con Borrelli nel
##      mirino) non va a segno — niente `colpo_a_segno` — e la furia sale;
##   4. **scappà sulo nun abbasta**: lontano, senza sigaretta né caffè, la
##      furia resta sopra alla soglia;
##   5. **'o cafè e 'a luntananza**: col caffè bevuto e a distanza si calma
##      e aspetta di parlare;
##   6. **'e ccriature**: si parla, si risponde B, se ne va e la giornata
##      finisce bene.

var storte: int = 0


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func ok(msg: String) -> void:
	print("  OK: %s" % msg)


func _aspetta(secondi: float) -> void:
	var fine: int = Time.get_ticks_msec() + int(secondi * 1000.0)
	while Time.get_ticks_msec() < fine:
		await get_tree().process_frame


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	get_tree().paused = false
	for _i in range(80):
		await get_tree().process_frame
	GameManager.intro_active = false
	var gm = GameManager
	if not gm.shift_active:
		gm.start_shift()
	gm.giornata = 3
	gm.shift_time_left = gm.shift_duration * 0.8
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	if pl == null:
		male("nessun giocatore")
		_fine()
		return

	var eventi: Array = []
	gm.event_started.connect(func(t): eventi.append(str(t)))

	# 1) Il vigile mandato via tre volte.
	print("=== 'O VIGILE MANNATO VIA ===")
	var vigili := get_tree().get_nodes_in_group("vigili")
	if vigili.is_empty():
		male("nessun vigile in città")
	else:
		var v = vigili[0]
		gm.borrelli_chiamate = 0
		gm.vigile_mannato_oggi = 0
		gm.boss_spawned = true      # la prima parte: solo la radio
		eventi.clear()
		v._mannato_via()
		v._mannato_via()
		var prima: int = eventi.size()
		v._mannato_via()
		var chiamato := false
		for t in eventi:
			if str(t).find("pattuglia") >= 0 or str(t).find("DUTTORE") >= 0:
				chiamato = true
		print("  eventi dopo due: %d, dopo tre: %s" % [prima, str(eventi)])
		if prima == 0 and chiamato and gm.vigile_mannato_oggi == 0:
			ok("alla terza volta chiama, e il conto riparte")
		else:
			male("il vigile mandato via tre volte non chiama")
		# La radio si ricarica: una seconda chiamata dopo il fermo.
		v._chiamata_cd = 0.0
		eventi.clear()
		v._chiamma_rinforzi()
		if eventi.size() > 0:
			ok("la radio chiama ancora dopo la prima volta")
		else:
			male("dopo la prima chiamata la radio è muta")
		gm.azzera_stelle()
		gm.heat = 0.0

	# 2) La porta B con il dado a cento.
	print("=== 'A PORTA B ===")
	gm.boss_spawned = false
	gm.boss_phase = false
	gm.borrelli_chiamate = 20
	if not gm.forse_chiamma_borrelli("prova: 'o vigile ha chiammato 'o Duttore"):
		male("con il dado a cento la chiamata non porta Borrelli")
	var b: Node3D = null
	var fine: int = Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < fine and b == null:
		b = get_tree().get_first_node_in_group("borrelli") as Node3D
		await get_tree().process_frame
	if b == null:
		male("Borrelli non è comparso")
		_fine()
		return
	await get_tree().process_frame
	var d0: float = b.global_position.distance_to(pl.global_position)
	print("  Borrelli nato a %.1f m dal giocatore, in %s" % [d0, str(b.global_position)])
	if d0 <= 35.0:
		ok("nasce vicino al giocatore")
	else:
		male("nasce a %.0f m, troppo lontano" % d0)
	if gm.boss_phase:
		ok("il cronometro si ferma")
	else:
		male("boss_phase spento")
	if gm.borrelli_chiamate == 0 and gm.borrelli_ultimo_juorno == 3:
		ok("i dadi ripartono da capo")
	else:
		male("i dadi non ripartono (%d, %d)" % [gm.borrelli_chiamate, gm.borrelli_ultimo_juorno])

	# 3) Il pugno non va a segno.
	print("=== NUN SE PÒ TUCCÀ ===")
	var colpi: Array = []
	gm.colpo_a_segno.connect(func(n): colpi.append(n))
	b.furia = 50.0
	var fronte: Vector3 = pl.global_position + Vector3(0.0, 0.0, -1.2)
	b.global_position = Vector3(fronte.x, b.global_position.y, fronte.z)
	pl.current_target = b
	gm.sciato = gm.SCIATO_MAX
	pl._throw_punch()
	await get_tree().process_frame
	b.receive_punch(9)
	print("  furia dopo due colpi: %.0f, colpi a segno: %d" % [b.furia, colpi.size()])
	if colpi.is_empty():
		ok("nessun colpo a segno")
	else:
		male("il colpo a Borrelli risulta a segno")
	if b.furia >= 99.0 and b.state == b.State.CHASING:
		ok("la furia sale e ti insegue")
	else:
		male("dopo il colpo furia %.0f stato %d" % [b.furia, b.state])
	pl.current_target = null

	# 4) Scappare senza niente non basta.
	print("=== SCAPPÀ SULO NUN ABBASTA ===")
	gm.caffe_boost = 0.0
	pl._smoking = 0.0
	pl.is_smoking = false
	await _tienilo_luntano(pl, b, 12.0, false)
	print("  dopo 12 s lontano, a mani vuote: furia %.0f" % b.furia)
	if b.furia >= b.FURIA_TALK_THRESHOLD and b.state == b.State.CHASING:
		ok("resta arrabbiato")
	else:
		male("si è calmato senza sigaretta né caffè")

	# 5) Il caffè e la distanza.
	print("=== 'O CAFÈ E 'A LUNTANANZA ===")
	gm.caffe = 1
	gm.bevi_caffe()
	var t0: int = Time.get_ticks_msec()
	await _tienilo_luntano(pl, b, 14.0, true)
	print("  col caffè: furia %.0f, stato %d, dopo %.1f s" % [b.furia, b.state,
		(Time.get_ticks_msec() - t0) / 1000.0])
	if b.state == b.State.WAITING_TALK:
		ok("col caffè e a distanza si calma e aspetta")
	else:
		male("col caffè non si calma (furia %.0f)" % b.furia)

	# 6) Le criature.
	print("=== 'E CCRIATURE ===")
	var vicino: Vector3 = b.global_position + Vector3(0.0, 0.0, 2.0)
	pl.global_position = Vector3(vicino.x, pl.global_position.y, vicino.z)
	await get_tree().physics_frame
	b.player_interact()
	if b.state != b.State.TALKING:
		male("non si riesce a parlargli (stato %d)" % b.state)
	else:
		var lista: Array = b._risposte()
		var idx := -1
		for i in range(lista.size()):
			if str(lista[i]["text"]).find("ccriature") >= 0:
				idx = i
		b.answer(idx)
		await _aspetta(0.5)
		if gm.boss_defeated and b.state == b.State.LEAVING:
			ok("'e ccriature lo convincono, e se ne va")
		else:
			male("la risposta delle criature non lo convince")

	_fine()


## Tiene il giocatore a quindici metri da lui, dalla parte opposta, per
## `secondi`. Se `basta_calmo`, esce appena lui si ferma ad aspettare.
func _tienilo_luntano(pl: Node3D, b: Node3D, secondi: float, basta_calmo: bool) -> void:
	var fine: int = Time.get_ticks_msec() + int(secondi * 1000.0)
	while Time.get_ticks_msec() < fine:
		var via: Vector3 = pl.global_position - b.global_position
		via.y = 0.0
		if via.length() < 0.1:
			via = Vector3(1, 0, 0)
		var q: Vector3 = b.global_position + via.normalized() * 15.0
		pl.global_position = Vector3(q.x, pl.global_position.y, q.z)
		pl.velocity = Vector3.ZERO
		if basta_calmo and b.state == b.State.WAITING_TALK:
			return
		await get_tree().physics_frame


func _fine() -> void:
	print("=== %d storte ===" % storte)
	get_tree().quit()
