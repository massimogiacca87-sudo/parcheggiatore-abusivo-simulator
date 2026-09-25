extends Node
## Borrelli nun tene cchiù 'nu calendario.
##
## Il capo: *"Borrelli arriva subito. Avevamo detto di lasciare un 1% di
## possibilità che spawni quando il vigile fa la multa o ti vedono che
## picchi qualcuno."*
##
## Quattro cose da dimostrare, e la prima è quella che il capo ha visto:
##
##   1. **'a notte nun 'o porta cchiù** — `boss_stasera()` dice sempre di
##      no, a qualunque giornata, con qualunque numero di piazze e con
##      qualunque incasso. Era questo che lo faceva arrivare subito: la
##      prima sera era `true` per costruzione;
##   2. **'o dado è uno ncopp'a ciento** — su centomila tirate deve uscire
##      l'uno per cento, non il cinque;
##   3. **nun se tira dduje vote** — se Borrelli è già in giro (o già in
##      scena) la tirata non si fa proprio: due Borrelli sono un bug che
##      si vede;
##   4. **fore d''o turno nun esce** — a giornata chiusa nessuno chiama
##      nessuno.

var _male: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame

	print("=== 'O CALENNARIO NUN CE STA CCHIÙ ===")
	var quante_vote := 0
	for g in range(1, 61):
		GameManager.giornata = g
		GameManager.zone_mie = ["a", "b", "c"]
		GameManager.money = 900
		GameManager.shift_start_money = 0     # 'na jurnata grossa assaje
		if GameManager.boss_stasera():
			quante_vote += 1
	_verifica("ncopp'a 60 sere Borrelli nun esce maje 'a sulo (%d)"
		% quante_vote, quante_vote == 0)
	GameManager.giornata = 1
	GameManager.zone_mie = ["a"]
	_verifica("manco 'a primma sera", not GameManager.boss_stasera())

	print("=== 'O DADO ===")
	_verifica("'a probabilità è ll'uno pe' ciento",
		absf(GameManager.PROB_BORRELLI - 0.01) < 0.0001)

	GameManager.start_shift()
	GameManager.boss_spawned = false
	GameManager.boss_phase = false
	var chiamate := 0
	var giri := 100000
	var visto := []
	GameManager.chiama_borrelli.connect(func(): visto.append(1))
	for i in range(giri):
		if GameManager.forse_chiamma_borrelli("prova"):
			chiamate += 1
		# Si rimette a posto: se no la prima uscita spegne tutte le altre.
		GameManager.boss_spawned = false
	var quota: float = float(chiamate) / float(giri)
	print("  ncopp'a %d tirate: %d chiammate  ->  %.2f%%" % [giri, chiamate,
		quota * 100.0])
	_verifica("esce ll'uno pe' ciento (e no 'o cinche)",
		absf(quota - 0.01) < 0.0025)
	_verifica("ogni chiammata manna 'o segnale",
		visto.size() == chiamate)

	print("=== NUN SE TIRA DDUJE VOTE ===")
	GameManager.boss_spawned = true
	var doppie := 0
	for i in range(5000):
		if GameManager.forse_chiamma_borrelli("prova"):
			doppie += 1
	_verifica("cu Borrelli già 'n giro nun se chiamma cchiù", doppie == 0)

	GameManager.boss_spawned = false
	GameManager.boss_phase = true
	doppie = 0
	for i in range(5000):
		if GameManager.forse_chiamma_borrelli("prova"):
			doppie += 1
	_verifica("e manco mentre ce staje parlanno 'nzieme", doppie == 0)

	print("=== FORE D''O TURNO ===")
	GameManager.boss_phase = false
	GameManager.shift_active = false
	var fore := 0
	for i in range(5000):
		if GameManager.forse_chiamma_borrelli("prova"):
			fore += 1
	_verifica("a jurnata chiusa nun chiamma nisciuno", fore == 0)

	print("=== %d storte ===" % _male)
	get_tree().quit()


func _verifica(che: String, ok: bool) -> void:
	if not ok:
		_male += 1
	print("  %-52s %s" % [che, "OK" if ok else "STORTO"])
