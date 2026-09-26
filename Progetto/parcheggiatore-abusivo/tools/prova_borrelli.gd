extends Node
## **Borrelli: 'e doje porte cu 'o dado ca cresce** (0.63).
##
## Il capo: *"Il boss di fine livello (Borrelli) non esce più. Voglio che
## appaia sempre in uno dei seguenti casi: A — 5% di possibilità alla fine
## di ogni giornata, che aumenta ogni giorno del 5%. Il primo giorno non
## può apparire. B — Dopo il primo giorno, quando il vigile chiama i
## Carabinieri c'è l'1% che chiama Borrelli invece, che aumenta del 10%
## ogni volta."*
##
## Qui si controllano i numeri, non la città (per quella c'è
## `prova_borrelli_gioca`):
##
##   1. **A**: giorno 1 zero; poi 5, 10, 15... per ogni giorno senza di
##      lui; a cento si ferma; quando viene riparte da cinque;
##   2. **A, tirata vera**: al giorno 3 su ventimila sere esce il dieci per
##      cento;
##   3. **B**: giorno 1 zero; poi 1, 11, 21... a ogni chiamata andata a
##      vuoto; quando esce, riparte dall'uno; e su tante partite la prima
##      chiamata esce l'uno per cento;
##   4. **nun se tira dduje vote**, e fuori dal turno non esce;
##   5. **'a violenza vista nun 'o chiamma cchiù**;
##   6. **si salva**: i due contatori sopravvivono a un salvataggio.

var _male: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	var gm = GameManager

	print("=== A — 'A SERA ===")
	gm.start_shift()
	gm.borrelli_ultimo_juorno = 0
	gm.borrelli_chiamate = 0
	var attese := [0.0, 0.05, 0.10, 0.15, 0.20]
	for g in range(1, 6):
		gm.giornata = g
		var p: float = gm.prob_borrelli_sera()
		print("  giorno %d: %.0f%%" % [g, p * 100.0])
		_verifica("giorno %d → %.0f%%" % [g, attese[g - 1] * 100.0],
			absf(p - attese[g - 1]) < 0.0001)
	gm.giornata = 40
	_verifica("al giorno 40 si ferma a cento", absf(gm.prob_borrelli_sera() - 1.0) < 0.0001)
	gm.giornata = 7
	gm.borrelli_venuto()
	_verifica("la sera che viene: il giorno dopo di nuovo zero",
		gm.prob_borrelli_sera() == 0.0)
	gm.giornata = 8
	_verifica("e il giorno dopo ancora cinque", absf(gm.prob_borrelli_sera() - 0.05) < 0.0001)

	# Tirata vera al giorno 3 (10%).
	var uscite := 0
	var sere := 20000
	for i in range(sere):
		gm.giornata = 3
		gm.borrelli_ultimo_juorno = 0
		gm.boss_spawned = false
		if gm.boss_stasera():
			uscite += 1
	var q: float = float(uscite) / float(sere)
	print("  giorno 3, %d sere: %.2f%%" % [sere, q * 100.0])
	_verifica("al giorno 3 esce il dieci per cento", absf(q - 0.10) < 0.01)
	gm.giornata = 1
	gm.borrelli_ultimo_juorno = 0
	uscite = 0
	for i in range(5000):
		if gm.boss_stasera():
			uscite += 1
	_verifica("il primo giorno mai", uscite == 0)

	print("=== B — 'A CHIAMMATA ===")
	gm.giornata = 1
	gm.borrelli_chiamate = 0
	gm.boss_spawned = false
	gm.boss_phase = false
	uscite = 0
	for i in range(3000):
		if gm.forse_chiamma_borrelli("prova"):
			uscite += 1
	_verifica("il primo giorno la chiamata non lo porta mai", uscite == 0)
	_verifica("e il primo giorno le chiamate non contano", gm.borrelli_chiamate == 0)

	gm.giornata = 4
	gm.borrelli_chiamate = 0
	var scala := [0.01, 0.11, 0.21, 0.31]
	for n in range(4):
		gm.borrelli_chiamate = n
		_verifica("chiamata %d → %.0f%%" % [n + 1, scala[n] * 100.0],
			absf(gm.prob_borrelli_chiamata() - scala[n]) < 0.0001)
	gm.borrelli_chiamate = 20
	_verifica("a venti chiamate si ferma a cento",
		absf(gm.prob_borrelli_chiamata() - 1.0) < 0.0001)

	# La prima chiamata di tante partite: esce l'uno per cento, e ogni
	# volta che va a vuoto il contatore sale.
	var giri := 100000
	uscite = 0
	var salite := 0
	var visto := []
	gm.chiama_borrelli.connect(func(): visto.append(1))
	for i in range(giri):
		gm.borrelli_chiamate = 0
		gm.boss_spawned = false
		if gm.forse_chiamma_borrelli("prova"):
			uscite += 1
			if gm.borrelli_chiamate != 0:
				salite += 1000
		elif gm.borrelli_chiamate == 1:
			salite += 1
	q = float(uscite) / float(giri)
	print("  prima chiamata, %d partite: %.2f%%" % [giri, q * 100.0])
	_verifica("la prima chiamata esce l'uno per cento", absf(q - 0.01) < 0.0025)
	_verifica("ogni chiamata a vuoto fa salire il dado", salite == giri - uscite)
	_verifica("ogni uscita manda il segnale", visto.size() == uscite)

	# Una partita intera: quante chiamate ci vogliono? In media ~4,5 (1 + 0,99 + 0,88 + 0,70 + 0,48 + ...).
	var somma := 0
	var partite := 5000
	for i in range(partite):
		gm.borrelli_chiamate = 0
		gm.boss_spawned = false
		var n := 0
		while true:
			n += 1
			if gm.forse_chiamma_borrelli("prova"):
				break
		somma += n
	var media: float = float(somma) / float(partite)
	print("  chiamate che servono, in media: %.2f" % media)
	_verifica("in media arriva verso la quinta chiamata (4,5)",
		media > 4.1 and media < 5.0)

	print("=== NUN SE TIRA DDUJE VOTE ===")
	gm.boss_spawned = true
	uscite = 0
	gm.giornata = 30
	for i in range(3000):
		gm.borrelli_chiamate = 20
		if gm.forse_chiamma_borrelli("prova") or gm.boss_stasera():
			uscite += 1
	_verifica("con Borrelli già in giro nessuna porta si apre", uscite == 0)
	gm.boss_spawned = false
	gm.shift_active = false
	for i in range(3000):
		gm.borrelli_chiamate = 20
		gm.borrelli_ultimo_juorno = 0
		if gm.forse_chiamma_borrelli("prova") or gm.boss_stasera():
			uscite += 1
	_verifica("a giornata chiusa nemmeno", uscite == 0)

	print("=== 'A VIULENZA ===")
	var testo: String = FileAccess.get_file_as_string(
		"res://scripts/autoload/game_manager.gd")
	var i0: int = testo.find("func violenza(")
	var i1: int = testo.find("\nfunc ", i0 + 10)
	var corpo: String = testo.substr(i0, i1 - i0)
	_verifica("la violenza vista non tira il dado di Borrelli",
		corpo.find("forse_chiamma_borrelli") < 0)

	print("=== SE SALVA ===")
	gm.borrelli_ultimo_juorno = 6
	gm.borrelli_chiamate = 2
	var d: Dictionary = gm.stato_partita() if gm.has_method("stato_partita") else {}
	if d.is_empty():
		print("  (niente stato_partita: si cerca a mano)")
		_verifica("le chiavi stanno nel salvataggio",
			testo.find("\"borrelli_ultimo_juorno\": borrelli_ultimo_juorno") >= 0
			and testo.find("\"borrelli_chiamate\": borrelli_chiamate") >= 0)
	else:
		gm.borrelli_ultimo_juorno = 0
		gm.borrelli_chiamate = 0
		gm.applica_stato(d)
		_verifica("dopo il caricamento: giorno 6, due chiamate",
			gm.borrelli_ultimo_juorno == 6 and gm.borrelli_chiamate == 2)

	print("=== %d storte ===" % _male)
	get_tree().quit()


func _verifica(che: String, ok: bool) -> void:
	if not ok:
		_male += 1
	print("  %-58s %s" % [che, "OK" if ok else "STORTO"])
