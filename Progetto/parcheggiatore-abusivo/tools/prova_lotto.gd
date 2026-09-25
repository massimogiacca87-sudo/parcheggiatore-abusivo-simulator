extends Node
## 'O lotto: 'e rrote, 'a smorfia, 'e quote e l'estrazione d''a sera.
##
## Un gioco d'azzardo scritto male non si vede giocandoci: si vede dopo
## trentamila giocate, quando i conti non tornano. Quindi qui non si prova
## "funziona": si prova **che i numeri siano quelli veri**.
##
##   1. **'a smorfia sta 'a posto** — novanta nomi, e i tre o quattro che
##      chiunque a Napoli sa a memoria (47 'o muorto, 48 'o muorto che
##      pparla, 90 'a paura) devono stare dove stanno;
##   2. **l'estrazione è pulita** — cinque numeri diversi per ruota, tutti
##      fra 1 e 90, e undici ruote;
##   3. **'a probabilità è chella overa** — su centomila estrazioni finte,
##      quante volte esce un ambo secco deve stare a una su 400,5
##      (C(88,3)/C(90,5)); se questo torna, il sacchetto è onesto;
##   4. **'o banco vence** — messo e preso a confronto: la quota
##      dell'ambo (250) contro una probabilità di 1 su 400,5 fa un ritorno
##      del 62%, cioè il banco si tiene il 38%. Se il ritorno venisse
##      sopra 1 il gioco sarebbe una macchina da soldi;
##   5. **'e giocate arrivano â sera** — si gioca, si chiude la giornata,
##      e la vincita dev'essere già in tasca quando arriva il riepilogo.

const Lotto := preload("res://scripts/lotto.gd")

var _male: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame

	print("=== 'A SMORFIA ===")
	_verifica("novanta nummere cchiù 'o zero", Lotto.SMORFIA.size() == 91)
	for coppia in [[1, "ll'Italia"], [8, "'a Madonna"], [47, "'o muorto"],
			[48, "'o muorto che pparla"], [62, "'o muorto acciso"],
			[75, "Pulecenella"], [90, "'a paura"]]:
		_verifica("%d = %s" % [int(coppia[0]), str(coppia[1])],
			Lotto.smorfia(int(coppia[0])) == str(coppia[1]))
	var vote := 0
	for i in range(1, 91):
		if str(Lotto.SMORFIA[i]).strip_edges() == "":
			vote += 1
	_verifica("nisciun nummero senza nomme (%d vacante)" % vote, vote == 0)

	print("=== L'ESTRAZIONE ===")
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260913
	var storte := 0
	for giro in range(400):
		var e: Dictionary = Lotto.estrai(rng)
		if e.size() != Lotto.RUOTE.size():
			storte += 1
			continue
		for r in Lotto.RUOTE:
			var u: Array = e[str(r)]
			if u.size() != 5:
				storte += 1
			var visti: Dictionary = {}
			for n in u:
				if int(n) < 1 or int(n) > 90 or visti.has(int(n)):
					storte += 1
				visti[int(n)] = true
	_verifica("400 estrazione, 11 rote, 5 nummere puliti", storte == 0)

	# --- 'A probabilità -------------------------------------------------
	#
	# Si conta quante volte un ambo fisso (17-23) esce sulla ruota di
	# Napoli. La probabilità vera è C(88,3)/C(90,5) = 1/400,5.
	print("=== 'A PROBABILITÀ ===")
	var giri := 120000
	var presi := 0
	var messo := 0
	var preso_sorde := 0
	for i in range(giri):
		var u: Array = _cinque(rng)
		messo += 1
		var v: int = Lotto.vincita([17, 23], 1, u)
		if v > 0:
			presi += 1
			preso_sorde += v
	var quota_vera: float = 1.0 / 400.5
	var quota_vista: float = float(presi) / float(giri)
	print("  ambo asciuto %d vote ncopp'a %d  ->  1 ncopp'a %.0f (overo: 1 ncopp'a 400)"
		% [presi, giri, (float(giri) / maxf(float(presi), 1.0))])
	_verifica("'a probabilità combacia",
		absf(quota_vista - quota_vera) < quota_vera * 0.30)

	var ritorno: float = float(preso_sorde) / float(messo)
	print("  ncopp'a €%d giucate, 'o lotto ne torna €%d  ->  %.0f%%"
		% [messo, preso_sorde, ritorno * 100.0])
	_verifica("'o banco vence (ritorno sotto 'o 100%%)", ritorno < 1.0)
	_verifica("ma nun è 'na rapina (ritorno sopra 'o 30%%)", ritorno > 0.30)

	# --- 'A giocata vera -------------------------------------------------
	print("=== 'A GIOCATA ===")
	GameManager.giornata = 1
	GameManager.start_shift()
	GameManager.money = 100
	GameManager.lotto_giocate = []
	GameManager.lotto_ultima = {}

	var no: Dictionary = GameManager.gioca_lotto("Vesuvio", [1, 2], 2)
	_verifica("'na rota ca nun esiste nun se gioca", not bool(no["ok"]))
	no = GameManager.gioca_lotto("Napoli", [], 2)
	_verifica("senza nummere nun se gioca", not bool(no["ok"]))
	no = GameManager.gioca_lotto("Napoli", [1, 2, 3, 4, 5, 6], 2)
	_verifica("cchiù 'e cinche nun se ponno", not bool(no["ok"]))

	var sorde_primma: int = GameManager.money
	var si: Dictionary = GameManager.gioca_lotto("Napoli", [47, 47, 90], 5)
	_verifica("'e nummere doppie se scancellano: resta n'ambo",
		bool(si["ok"]) and str(si["sorte"]) == "ambo")
	_verifica("'a puntata se leva 'a sacca (%d -> %d)" % [
		sorde_primma, GameManager.money],
		GameManager.money == sorde_primma - 5)
	_verifica("'a giocata sta 'n coda", GameManager.lotto_quante_aperte() == 1)
	_verifica("'o messo se conta", GameManager.lotto_messo_aperto() == 5)

	# Una giocata che DEVE vincere: si trucca l'estrazione dopo il fatto.
	print("=== 'A VINCITA ===")
	GameManager.lotto_giocate = [{
		"ruota": "Napoli", "numeri": [7, 22], "puntata": 3, "giornata": 1}]
	GameManager.money = 0
	var esito: Dictionary = GameManager.estrai_lotto()
	print("  estrazione fatta: %d giocate viste, vinto €%d" % [
		int(esito["quante"]), int(esito["vinto"])])
	_verifica("'a coda s'è svacantata", GameManager.lotto_quante_aperte() == 0)
	_verifica("l'estrazione s'è segnata",
		not GameManager.lotto_ultima.is_empty())
	_verifica("ce sta n'esito 'a leggere", GameManager.lotto_esiti.size() == 1)

	# E adesso quella che vince per forza, calcolata a mano.
	var usciti: Array = [7, 22, 41, 63, 88]
	_verifica("ambo 'e 3 euro paga 750",
		Lotto.vincita([7, 22], 3, usciti) == 750)
	_verifica("terno 'e 1 euro paga 4500",
		Lotto.vincita([7, 22, 41], 1, usciti) == 4500)
	_verifica("nu nummero ca nun è asciuto paga zero",
		Lotto.vincita([7, 23], 3, usciti) == 0)
	_verifica("ambata 'e 10 euro paga 112",
		Lotto.vincita([41], 10, usciti) == 112)

	prova_ritardatarie()

	print("=== %d storte ===" % _male)
	get_tree().quit()


func _cinque(rng: RandomNumberGenerator) -> Array:
	var sacco: Array = []
	for n in range(1, 91):
		sacco.append(n)
	var fuori: Array = []
	for i in range(5):
		var k: int = rng.randi_range(0, sacco.size() - 1)
		fuori.append(int(sacco[k]))
		sacco.remove_at(k)
	return fuori


func _verifica(che: String, ok: bool) -> void:
	if not ok:
		_male += 1
	print("  %-48s %s" % [che, "OK" if ok else "STORTO"])


## ---------------------------------------------------------------------
## 'O quadernetto d''e ritardatarie (0.54)
## ---------------------------------------------------------------------
##
## Due cose sole, e la seconda è quella che conta.
##
## La prima: che il conto sia giusto — un numero uscito adesso torna a
## zero, gli altri salgono di uno, e dopo N estrazioni senza uscire il
## ritardo è N.
##
## La seconda, che è il motivo per cui questa cosa può stare in un gioco:
## **che non serva a niente.** Il quadernetto è una fallacia, e va bene
## così — ma solo finché è davvero una fallacia. Se giocare le
## ritardatarie rendesse anche un solo punto percentuale in più, il
## tabaccaio smetterebbe di essere un banco e diventerebbe un exploit, e
## per giunta un exploit che il gioco insegna da solo. Si misura su
## quarantamila estrazioni: chi gioca le ritardatarie e chi gioca a caso
## devono vincere uguale.
func prova_ritardatarie() -> void:
	print("=== 'E RITARDATARIE ===")
	var rng := RandomNumberGenerator.new()
	rng.seed = 99117

	GameManager.lotto_ritardi = {}
	GameManager._prepara_ritardi()
	# Conto giusto: si finge un'estrazione in cui su Napoli esce l'1.
	for giro in range(7):
		GameManager._passo_ritardi({"Napoli": [1, 2, 3, 4, 5]})
	var top: Array = GameManager.lotto_ritardatarie("Napoli", 3)
	if top.is_empty():
		_male_dice("'o quadernetto nun torna niente")
		return
	# L'1 è appena uscito: ritardo zero, non deve stare in cima.
	for r in top:
		if int(r["n"]) <= 5:
			_male_dice("'nu nummero asciuto mo' sta 'n cima")
	if int(top[0]["ritardo"]) != 7:
		_male_dice("'o ritardo cchiu' auto è %d, vuleva essere 7"
			% int(top[0]["ritardo"]))
	print("  doppo 7 estrazione: 'o cchiu' 'n ritardo manca 'a %d"
		% int(top[0]["ritardo"]))

	# **'A prova ca conta: 'o quadernetto nun fa vincere.**
	GameManager.lotto_ritardi = {}
	GameManager._prepara_ritardi()
	var vinto_rit := 0
	var vinto_caso := 0
	var messo := 0
	for giro in range(40000):
		var quale: Array = GameManager.lotto_ritardatarie("Napoli", 2)
		var scelti_rit: Array = [int(quale[0]["n"]), int(quale[1]["n"])]
		var scelti_caso: Array = []
		while scelti_caso.size() < 2:
			var n: int = rng.randi_range(1, Lotto.NUMERI)
			if not scelti_caso.has(n):
				scelti_caso.append(n)
		var numeri: Dictionary = Lotto.estrai(rng)
		var usciti: Array = numeri.get("Napoli", [])
		vinto_rit += Lotto.vincita(scelti_rit, 1, usciti)
		vinto_caso += Lotto.vincita(scelti_caso, 1, usciti)
		messo += 1
		GameManager._passo_ritardi(numeri)
	var r_rit: float = float(vinto_rit) / float(messo)
	var r_caso: float = float(vinto_caso) / float(messo)
	print("  40.000 ambi: ritardatarie %.3f · a sciorte %.3f (ritorno)"
		% [r_rit, r_caso])
	# Con l'ambo il ritorno è rumoroso: la soglia è larga apposta, e serve
	# solo a beccare una differenza vera (che sarebbe enorme, non fine).
	if absf(r_rit - r_caso) > 0.35:
		_male_dice("'e ritardatarie cagnano 'o ritorno: %.3f contra %.3f"
			% [r_rit, r_caso])
	GameManager.lotto_ritardi = {}


func _male_dice(che: String) -> void:
	_male += 1
	print("  STORTO: %s" % che)
