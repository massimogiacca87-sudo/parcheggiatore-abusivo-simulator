extends Node
## 'E partite virtuale: 'e quote hann'a essere oneste.
##
## Un banco scritto male non si vede giocando dieci partite: si vede dopo
## diecimila, quando uno si accorge che scommettere è la strada più veloce
## per fare soldi — e da lì in poi il gioco non è più un gioco di
## parcheggiatori.
##
## Quindi qui non si prova che la partita "funzioni": si prova che
##
##   1. **'e probabilità fanno uno** — se i tre esiti non sommano a 1 il
##      modello è rotto in partenza;
##   2. **'a squadra cchiù forte vence 'e cchiù, ma nun sempe** — se
##      vincesse sempre non sarebbe una scommessa, se vincesse come le
##      altre le forze non servirebbero a niente;
##   3. **'e gol asciuti combaciano cu 'e probabilità** — diecimila
##      partite vere contro il conto teorico: se le due colonne si
##      allontanano, il motore e le quote stanno raccontando due partite
##      diverse, e il giocatore paga la differenza;
##   4. **'o banco se piglia ll'otto pe' ciento** — né di più (rapina) né
##      di meno (macchina da soldi). È l'unico numero che rende la sala
##      una scelta e non un exploit;
##   5. **'a cronaca torna cu 'o risultato** — i gol raccontati devono
##      essere esattamente quelli del punteggio finale. Un tabellone che
##      dice 2–1 dopo aver mostrato tre gol è il difetto che fa scrivere
##      "il gioco bara".

const Partita := preload("res://scripts/partita_virtuale.gd")

var _male: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	var rng := RandomNumberGenerator.new()
	rng.seed = 5220913

	print("=== 'E PROBABILITÀ ===")
	var storte := 0
	for i in range(Partita.SQUADRE.size()):
		for j in range(Partita.SQUADRE.size()):
			if i == j:
				continue
			var p: Array = Partita.probabilita(Partita.SQUADRE[i],
				Partita.SQUADRE[j])
			var somma: float = float(p[0]) + float(p[1]) + float(p[2])
			if absf(somma - 1.0) > 0.001:
				storte += 1
	_verifica("132 accoppiate, 'e tre esite fanno sempe uno", storte == 0)

	var forte: Dictionary = Partita.SQUADRE[4]    # FUORIGROTTA, forza 80
	var debbole: Dictionary = Partita.SQUADRE[5]  # BAGNULE, forza 66
	var pf: Array = Partita.probabilita(forte, debbole)
	var pd: Array = Partita.probabilita(debbole, forte)
	print("  %s (80) 'n casa cu %s (66):  1=%.0f%% X=%.0f%% 2=%.0f%%" % [
		str(forte["nome"]), str(debbole["nome"]),
		float(pf[0]) * 100.0, float(pf[1]) * 100.0, float(pf[2]) * 100.0])
	print("  e ô cuntrario:                      1=%.0f%% X=%.0f%% 2=%.0f%%" % [
		float(pd[0]) * 100.0, float(pd[1]) * 100.0, float(pd[2]) * 100.0])
	_verifica("'o cchiù forte 'n casa vence assaje 'e cchiù", float(pf[0]) > 0.55)
	_verifica("ma 'o debbole 'na speranza 'a tene", float(pf[2]) > 0.10)

	print("=== 'E QUOTE ===")
	var peggio: float = 0.0
	for i in range(Partita.SQUADRE.size()):
		for j in range(Partita.SQUADRE.size()):
			if i == j:
				continue
			var q: Array = Partita.quote(Partita.SQUADRE[i], Partita.SQUADRE[j])
			var somma_inversi: float = 0.0
			for x in q:
				somma_inversi += 1.0 / float(x)
			peggio = maxf(peggio, absf(somma_inversi - (1.0 + Partita.CRESTA)))
	print("  'a somma d''e ll'inverse s'alluntana ô massimo 'e %.4f 'a %.2f" % [
		peggio, 1.0 + Partita.CRESTA])
	_verifica("'o banco se piglia sempe ll'otto pe' ciento", peggio < 0.01)

	# --- Diecimila partite overe ----------------------------------------
	print("=== DIECEMILA PARTITE ===")
	var giri := 10000
	var vinte := [0, 0, 0]
	var gol_tutte := 0
	var carte_sbagliate := 0
	var messo := 0
	var preso := 0
	var q: Array = Partita.quote(forte, debbole)
	for i in range(giri):
		var m: Dictionary = Partita.gioca(forte, debbole, rng)
		match str(m["esito"]):
			"1": vinte[0] += 1
			"X": vinte[1] += 1
			_: vinte[2] += 1
		gol_tutte += int(m["gol_casa"]) + int(m["gol_fore"])
		# **'A cronaca adda cuntà 'e stessi gol d''o risultato.**
		var cc := 0
		var cf := 0
		for f in m["fatti"]:
			if str(f["che"]) == "gol" or str(f["che"]) == "rigore":
				if int(f["chi"]) == 0:
					cc += 1
				else:
					cf += 1
		if cc != int(m["gol_casa"]) or cf != int(m["gol_fore"]):
			carte_sbagliate += 1
		# Uno che gioca sempre "1", dieci euro per volta. Dieci e non uno
		# perche' la vincita si tronca all'euro: a un euro il troncamento
		# pesa piu' della cresta del banco e si misurerebbe quello.
		messo += 10
		if str(m["esito"]) == "1":
			preso += int(floor(10.0 * float(q[0])))
	_verifica("'a cronaca cunta 'e stessi gol d''o tabellone (%d storte)"
		% carte_sbagliate, carte_sbagliate == 0)
	print("  esite viste:  1=%.1f%%  X=%.1f%%  2=%.1f%%" % [
		float(vinte[0]) / giri * 100.0, float(vinte[1]) / giri * 100.0,
		float(vinte[2]) / giri * 100.0])
	print("  esite cuntate: 1=%.1f%%  X=%.1f%%  2=%.1f%%" % [
		float(pf[0]) * 100.0, float(pf[1]) * 100.0, float(pf[2]) * 100.0])
	for k in range(3):
		var visto: float = float(vinte[k]) / float(giri)
		_verifica("l'esito %s combacia (%.3f contro %.3f)" % [
			["1", "X", "2"][k], visto, float(pf[k])],
			absf(visto - float(pf[k])) < 0.025)
	print("  gol pe' partita: %.2f" % (float(gol_tutte) / float(giri)))
	_verifica("se fanno da 1,5 a 4 gol a partita",
		float(gol_tutte) / float(giri) > 1.5
		and float(gol_tutte) / float(giri) < 4.0)

	var ritorno: float = float(preso) / float(messo)
	print("  chi gioca sempe '1' a €10:  mette €%d, piglia €%d  ->  %.1f%%" % [
		messo, preso, ritorno * 100.0])
	_verifica("chi gioca perde (ritorno sotto 'o 100%%)", ritorno < 1.0)
	_verifica("ma nun 'o spuoglia (ritorno sopra 'o 80%%)", ritorno > 0.80)

	# E lo stesso a puntata grossa: piu' si punta, meno pesa il
	# troncamento, e il ritorno si avvicina al 92% che dicono le quote.
	var messo_g := 0
	var preso_g := 0
	for i in range(giri):
		var m: Dictionary = Partita.gioca(forte, debbole, rng)
		messo_g += 50
		if str(m["esito"]) == "1":
			preso_g += int(floor(50.0 * float(q[0])))
	var rit_g: float = float(preso_g) / float(messo_g)
	print("  e a €50 a bbotta:  %.1f%%  (cchiù t'avvicine ê quote)" % (rit_g * 100.0))
	_verifica("a puntata grossa 'o ritorno saglie ma resta sotto", 
		rit_g > ritorno and rit_g < 1.0)

	# --- 'O cartellone ---------------------------------------------------
	print("=== 'O CARTELLONE ===")
	var doppie := 0
	for i in range(500):
		var c: Array = Partita.cartellone(rng, 3)
		if c.size() != 3:
			doppie += 1
			continue
		var viste: Dictionary = {}
		for m in c:
			for chi in [str(m["casa"]["nome"]), str(m["fore"]["nome"])]:
				if viste.has(chi):
					doppie += 1
				viste[chi] = true
	_verifica("nisciuna squadra joca dduje vote 'o stesso juorno", doppie == 0)

	print("=== %d storte ===" % _male)
	get_tree().quit()


func _verifica(che: String, ok: bool) -> void:
	if not ok:
		_male += 1
	print("  %-52s %s" % [che, "OK" if ok else "STORTO"])
