extends Node
## **'E mure: chi 'e passa e chi no** (0.56, punto 8).
##
## Il capo: *«Occhio che molti png attraversano i muri, succede ad esempio ai
## bambini che giocano ma anche ai guidatori quando vanno via.»*
##
## Questa prova sta in tre pezzi, e sono tre pezzi diversi apposta:
##
## 1. **'A geometria** — `dint_ô_palazzo` e `fore_d_ô_palazzo` da sole,
##    senza gioco intorno. Se sbagliano queste, sbaglia tutto il resto e non
##    si capisce perché.
## 2. **'O passo** — mille camminate dritte attraverso la città intera, a
##    tutte le velocità, e nessuna deve finire dentro a un palazzo. È la
##    prova che conta: il bug era esattamente questo, uno che cammina dritto
##    verso una meta che sta dall'altra parte di un isolato.
## 3. **'A gente overa** — il gioco gira davvero per un po' e ogni tanto si
##    guarda dove stanno tutti. Perché una funzione giusta chiamata da
##    nessuno non serve a niente, e il modo di scoprirlo è guardare la
##    città mentre cammina.
##
## Il terzo pezzo è quello che la 0.55 mi avrebbe risparmiato, se l'avessi
## scritto allora: *quanno 'na cosa nun se vede, 'o primmo suspetto è 'a
## prova* — ma il secondo sospetto è che la prova non guardi la cosa vera.

const Citta := preload("res://scripts/citta_3d.gd")
const Ostacoli := preload("res://scripts/ostacoli.gd")
const Cammino := preload("res://scripts/cammino.gd")

var storte: int = 0
var _rng := RandomNumberGenerator.new()


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 20560
	await get_tree().process_frame

	_prova_geometria()
	_prova_passo()
	await _prova_a_gente()

	print("=== storte: %d ===" % storte)
	get_tree().quit()


# ---------------------------------------------------------------------------
# 1. 'A geometria
# ---------------------------------------------------------------------------

func _prova_geometria() -> void:
	print("=== 'A GEOMETRIA ===")
	print("  %d isolate" % Citta.ISOLATI.size())

	# Il centro di ogni isolato sta dentro: se no la tabella non dice quello
	# che crediamo che dica.
	var dinto := 0
	for b in Citta.ISOLATI:
		var c := Vector3((float(b[0]) + float(b[2])) * 0.5, 0.0,
			(float(b[1]) + float(b[3])) * 0.5)
		if Citta.dint_ô_palazzo(c):
			dinto += 1
		else:
			male("'o centro 'e ll'isolato %s nun sta dint'a isso" % str(b))
	print("  %d/%d centre dint'ô palazzo" % [dinto, Citta.ISOLATI.size()])

	# E ognuno di quei centri, spinto fuori, dev'essere fuori davvero.
	var fore := 0
	for b in Citta.ISOLATI:
		var c := Vector3((float(b[0]) + float(b[2])) * 0.5, 0.0,
			(float(b[1]) + float(b[3])) * 0.5)
		var f: Vector3 = Citta.fore_d_ô_palazzo(c, 0.40)
		# Un isolato può stare attaccato a un altro: allora il primo passo
		# ti mette dentro al vicino, e ne serve un secondo. Tre bastano e
		# avanzano per qualunque punto della pianta.
		for _i in range(3):
			f = Citta.fore_d_ô_palazzo(f, 0.40)
		if Citta.dint_ô_palazzo(f, 0.30):
			male("spignenno 'o centro 'e %s resta 'ncastrato a %s"
				% [str(b), str(f.round())])
		else:
			fore += 1
	print("  %d/%d ne escono" % [fore, Citta.ISOLATI.size()])

	# E la piazza di casa, che è il posto dove si lavora, non dev'essere
	# dentro a niente: se lo fosse, tutta la città sarebbe murata.
	for p in [Vector3(31, 0, 30), Vector3(78, 0, 95), Vector3(143.6, 0, 114.5)]:
		if Citta.dint_ô_palazzo(p):
			male("%s sta dint'a 'nu palazzo, e nun ce puo' sta" % str(p))
	print("  'e piazze so' libbere")


# ---------------------------------------------------------------------------
# 2. 'O passo
# ---------------------------------------------------------------------------

func _prova_passo() -> void:
	print("=== 'O PASSO ===")
	# `Passo.verso` vuole il nodo, non la posizione: si porta appresso il
	# ricordo di da che parte stava girando (vedi `Passo.GIRA`). Qui se ne
	# fa uno finto e lo si fa camminare.
	var pupo := Node3D.new()
	add_child(pupo)
	var dinto := 0
	var passe_dinto := 0
	var passe := 0
	var arrivate := 0
	var piantate := 0
	var lente := 0
	var prove := 400
	for _n in range(prove):
		# Si parte da un punto libero e si punta un altro punto libero, che
		# è esattamente quello che fa un guidatore che torna alla macchina.
		var da: Vector3 = _libbero()
		var a: Vector3 = _libbero()
		pupo.global_position = da
		if pupo.has_meta(Passo.GIRA):
			pupo.remove_meta(Passo.GIRA)
		var passo: float = _rng.randf_range(0.04, 0.22)  # 2,5 → 13 m/s
		var s_e_nfilato := false
		# **Tremila passi, no millequattrocento** (0.59). Da quando il passo
		# conosce i recinti delle piazze e l'anello dello stadio, chi prima
		# ci passava attraverso adesso ci gira intorno — e a quattro
		# centimetri per passo (il più lento dei sorteggi) centocinquanta
		# metri di giro sono quasi quattromila passi. Il conto dei passi
		# dentro ai muri resta quello: è lui che dice se il passo è sano.
		var arrivato := false
		var dove_prima: Vector3 = da
		var fermo := false
		for _i in range(3000):
			# Si guarda solo alla fine: fermo vuol dire che negli ultimi
			# seicento passi non si è spostato di mezzo metro.
			if _i == 2400:
				dove_prima = pupo.global_position
			pupo.global_position = Passo.verso(pupo, a, passo)
			var p: Vector3 = pupo.global_position
			passe += 1
			if Citta.dint_ô_palazzo(p, 0.30):
				# **Nun se conta "'na vota e basta", se conta quanto ce
				# resta.** Dalla valvola di sicurezza in poi (vedi
				# `Passo.BLOCCO_MAX`) chi ha una meta irraggiungibile
				# taglia il muro invece di restare piantato: succede, e
				# deve succedere. Quello che NON deve succedere è che
				# passare attraverso torni a essere il modo normale di
				# camminare — e quello si vede solo contando i passi.
				passe_dinto += 1
				if not s_e_nfilato:
					s_e_nfilato = true
					dinto += 1
			if Vector2(p.x - a.x, p.z - a.z).length() < 0.5:
				arrivate += 1
				arrivato = true
				break
		if not arrivato:
			fermo = pupo.global_position.distance_to(dove_prima) < 0.5
			if fermo:
				piantate += 1
				if piantate <= 12:
					print("  PIANTATO a %s (da %s a %s, passo %.2f)" % [
						str(pupo.global_position.snapped(Vector3.ONE * 0.1)),
						str(da.round()), str(a.round()), passo])
			else:
				lente += 1
	var quota: float = 100.0 * float(passe_dinto) / float(maxi(1, passe))
	print("  %d cammenate: %d toccano 'nu muro, %d arrivano, %d piantate, %d ancora 'e via"
		% [prove, dinto, arrivate, piantate, lente])
	print("  %d passe 'n tutto, %d dint'ô muro = %.2f%%"
		% [passe, passe_dinto, quota])
	# Prima della 0.56 questa quota era **tutto il tempo che serviva ad
	# attraversare un isolato**, cioè decine di passi per ogni camminata
	# che ci finiva contro. Sotto l'uno per cento vuol dire che passare
	# attraverso non è più un modo di camminare: è l'eccezione di chi non
	# aveva strada.
	if quota > 1.0:
		male("'o %.2f%% d''e passe sta dint'ê mure: troppo" % quota)
	# E non è che non passano perché non si muovono: almeno metà deve
	# arrivare a destinazione. Un muro che ferma tutti è peggio del bug.
	if arrivate < prove / 2:
		male("sulo %d ncopp'a %d arrivano: 'e mure 'e 'ncastrano"
			% [arrivate, prove])

	# Chi nasce dentro (uno spawn storto, 'na spinta) ne deve uscire.
	var salvate := 0
	for _n in range(200):
		var b: Array = Citta.ISOLATI[_rng.randi() % Citta.ISOLATI.size()]
		pupo.global_position = Vector3(
			_rng.randf_range(float(b[0]), float(b[2])), 0.0,
			_rng.randf_range(float(b[1]), float(b[3])))
		if pupo.has_meta(Passo.GIRA):
			pupo.remove_meta(Passo.GIRA)
		var a: Vector3 = _libbero()
		for _i in range(120):
			pupo.global_position = Passo.verso(pupo, a, 0.12)
			if not Citta.dint_ô_palazzo(pupo.global_position, 0.30):
				salvate += 1
				break
	print("  %d/200 ne escono si ce nasceno dinto" % salvate)
	if salvate < 190:
		male("sulo %d ncopp'a 200 ne escono: chi ce casca ce resta" % salvate)
	pupo.queue_free()


## Un punto della città dove si può stare. **E ca nun sta dint'a 'na
## cosa** (0.59): da quando il passo conosce le auto in sosta e le
## panchine, una meta scelta dentro a un cassonetto non si raggiunge — e
## giustamente. Contarla come camminata fallita misurava il sorteggio, non
## il passo.
func _libbero() -> Vector3:
	for _i in range(200):
		var p := Vector3(_rng.randf_range(2.0, 190.0), 0.0,
			_rng.randf_range(2.0, 170.0))
		if not Citta.dint_ô_palazzo(p, 0.6) and not Ostacoli.dentro(p, 0.5) \
				and Cammino.raggiungibile(p):
			return p
	return Vector3(31, 0, 30)


# ---------------------------------------------------------------------------
# 3. 'A gente overa
# ---------------------------------------------------------------------------

## I gruppi di chi cammina. Non ci sono i passanti né i guaglioni, che
## camminano col motore fisico e hanno già i muri loro; ci sono quelli che
## si spostano scrivendo la posizione, che erano il problema.
const CAMMENANTE := ["drivers", "vigili", "bambini", "carabinieri",
	"signore", "boss"]


func _prova_a_gente() -> void:
	print("=== 'A GENTE OVERA ===")
	get_tree().paused = false
	var visti := {}
	var storti := {}
	var quanti := 0
	for _i in range(1500):
		await get_tree().process_frame
		if _i % 12 != 0:
			continue
		for g in CAMMENANTE:
			for n in get_tree().get_nodes_in_group(g):
				if not (n is Node3D):
					continue
				# I guaglioni stanno **dint'ô** nodo del campetto: il nodo
				# del gruppo è il campo, non chi ci gioca. Guardando solo
				# quello si guarda il posto, non la gente — ed era
				# esattamente la gente che passava p''e mure.
				for chi in _pupe(n as Node3D):
					var p: Vector3 = chi.global_position
					# La casa sta a (300, 300), fuori dalla pianta: chi ci
					# entra non conta.
					if p.x > 220.0 or p.z > 200.0:
						continue
					visti[g] = int(visti.get(g, 0)) + 1
					quanti += 1
					if Citta.dint_ô_palazzo(p, 0.20):
						storti[g] = int(storti.get(g, 0)) + 1
	print("  %d guardate 'nzieme" % quanti)
	for g in CAMMENANTE:
		var v: int = int(visti.get(g, 0))
		var s: int = int(storti.get(g, 0))
		print("  %-14s %5d guardate, %4d dint'ô muro" % [g, v, s])
		if s > 0:
			male("'e %s stanno dint'ê mure %d vote ncopp'a %d" % [g, s, v])
	if quanti < 50:
		male("nun s'è visto nisciuno: 'a prova nun prova niente")


## Chi cammina dentro a un nodo. Per quasi tutti è il nodo stesso; per il
## campetto dei guaglioni sono i quattro ragazzini che ci stanno dentro.
func _pupe(n: Node3D) -> Array:
	if not n.is_in_group("bambini"):
		return [n]
	var fore: Array = []
	for c in n.get_children():
		# I ragazzini sono `Node3D` semplici; il pallone è un corpo rigido
		# e le porte sono mesh. Si guardano solo quelli che camminano.
		if c is Node3D and c.get_class() == "Node3D" \
				and c.get_child_count() > 0:
			fore.append(c)
	return fore if not fore.is_empty() else [n]
