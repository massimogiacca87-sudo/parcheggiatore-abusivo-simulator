extends Node
## 'O vicinato: stanno addò s'adda stà, e diceno chello ca serve?
##
## Questi quattro sono l'unica cosa del gioco che **non si muove mai**, e
## per questo hanno un difetto che gli altri non possono avere: se uno
## finisce in mezzo a un varco o dentro alla corsia libera di una strada,
## non è un fastidio che passa — è un muro piantato lì per sempre. È
## successo alla 0.53 con tre bancarelle del mercato messe dentro ai posti
## auto, e quella volta l'ho scoperto guardando una foto.
##
## Poi c'è la parte che decide se il vicinato serve a qualcosa: le quattro
## informazioni. Una notizia che si sbaglia sulla direzione, o che dice
## "nun ce sta niente" quando qualcosa c'è, è peggio di nessuna notizia —
## la paghi, ci credi, e vai dalla parte sbagliata.

const Gente := preload("res://scripts/gente.gd")
const Citta := preload("res://scripts/citta_3d.gd")
const Vicino := preload("res://scripts/vicino_3d.gd")

var storte: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame

	_prova_posti()
	await _prova_scambio()
	await _prova_nutizie()
	await _prova_frittata()
	await _prova_notte()

	print("=== storte: %d ===" % storte)
	get_tree().quit()


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


# ---------------------------------------------------------------------------

func _prova_posti() -> void:
	print("=== ADDÒ STANNO ===")
	if Citta.POSTI_VICINE.size() != Gente.VICINE.size():
		male("%d poste pe' %d vicine" % [Citta.POSTI_VICINE.size(),
			Gente.VICINE.size()])
	var viste: Array[String] = []
	for v in Citta.POSTI_VICINE:
		var id := str(v[0])
		if Gente.vicino(id).is_empty():
			male("'o posto è pe' '%s', ca nun sta dint'â tavola" % id)
		if viste.has(id):
			male("%s sta 'n duje poste" % id)
		viste.append(id)
		var p := Vector3(float(v[1]), 0.0, float(v[2]))
		# Un corpo con il collider: come una bancarella, come una macchina
		# in sosta. Le stesse due regole che valgono per tutto il resto.
		if Citta.dentro_varco(p):
			male("%s sta dint'ô varco d''e machine (%.0f, %.0f)"
				% [id, p.x, p.z])
		if Citta.in_corsia(p, Vector3(0.7, 1.8, 0.7)):
			male("%s sta 'n miezo â strada (%.0f, %.0f)" % [id, p.x, p.z])
		print("  %-11s (%.0f, %.0f) — fore d''e varche e d''a corsia"
			% [id, p.x, p.z])
	for w in Gente.VICINE:
		if not viste.has(str(w["id"])):
			male("%s nun sta 'n nisciuna parte d''a città" % w["id"])

	# E non tutti nello stesso angolo: quattro vicini a dieci metri l'uno
	# dall'altro sono un capannello, non un quartiere.
	for i in range(Citta.POSTI_VICINE.size()):
		for j in range(i + 1, Citta.POSTI_VICINE.size()):
			var a := Vector2(float(Citta.POSTI_VICINE[i][1]),
				float(Citta.POSTI_VICINE[i][2]))
			var b := Vector2(float(Citta.POSTI_VICINE[j][1]),
				float(Citta.POSTI_VICINE[j][2]))
			if a.distance_to(b) < 18.0:
				male("%s e %s stanno appiccicate (%.0f m)"
					% [Citta.POSTI_VICINE[i][0], Citta.POSTI_VICINE[j][0],
						a.distance_to(b)])


func _mette(id: String, pos: Vector3 = Vector3.ZERO) -> Node:
	var n = Vicino.new()
	n.setup(id, pos)
	add_child(n)
	await get_tree().process_frame
	return n


func _prova_scambio() -> void:
	print("=== 'O SCAMBIO ===")
	GameManager.rapporti = {}
	GameManager.giornata = 3
	GameManager.money = 0

	var n = await _mette("nunzia_bar")
	# Senza soldi: saluta, poi rifiuta, e non deve dare niente lo stesso.
	if n.get_interact_prompt(Vector3.ZERO) == "":
		male("nun se pò parlà")
	n.player_interact()          # 'o saluto
	n.player_interact()          # e mo' vò 'e sorde
	if n._gia_fatto():
		male("ha ditto 'a nutizia senza esser pagata")
	print("  senza sorde: nun dice niente")

	GameManager.money = 10
	n.player_interact()
	if not n._gia_fatto():
		male("l'hê pagata e nun ha ditto niente")
	if GameManager.money != 8:
		male("s'è pigliata €%d invece 'e 2" % (10 - GameManager.money))
	if GameManager.rapporto("nunzia_bar") <= 0.0:
		male("'o piacere nun ha fatto cagnà 'o rapporto")
	print("  pagata €2, rapporto %.1f" % GameManager.rapporto("nunzia_bar"))

	# Una volta al giorno: il secondo [E] nello stesso giorno non paga e
	# non dice. Se no la posizione del vigile diventa una minimappa gratis.
	var prima: int = GameManager.money
	n.player_interact()
	if GameManager.money != prima:
		male("l'ha pagata n'ata vota 'o stesso juorno")
	print("  'na vota â jurnata: 'o sicondo [E] nun fa niente")

	# Domani sì.
	GameManager.giornata = 4
	if n._gia_fatto():
		male("dimane se cride ancora ajere")
	print("  dimane se pò n'ata vota")

	# All'amico gratis, e senza doverlo salutare prima.
	GameManager.rapporti = {"nunzia_bar": {"visto": 9, "rap": 90.0}}
	GameManager.giornata = 5
	GameManager.money = 10
	var n2 = await _mette("totore")
	GameManager.rapporti["totore"] = {"visto": 9, "rap": 90.0}
	n2.player_interact()
	if GameManager.money != 10:
		male("s'è fatto pagà pure 'a ll'amico")
	if not n2._gia_fatto():
		male("ll'amico nun ha avuto 'a nutizia")
	print("  a ll'amico: gratis e 'n subito")
	n.queue_free()
	n2.queue_free()


## 'E nutizie so' addeventate **effette** (0.55): chello ca conta nun è
## cchiu' chello ca diceno, è chello ca fanno.
func _prova_nutizie() -> void:
	print("=== CHE FANNO ===")
	GameManager.rapporti = {}
	GameManager.giornata = 11
	GameManager.money = 50

	# Nunzia: 'o cafe' cala 'o sospetto.
	GameManager.heat = 80.0
	var n = await _mette("nunzia_bar")
	n.player_interact()
	n.player_interact()
	if GameManager.heat >= 80.0:
		male("'o cafe' 'e Nunzia nun cala 'o sospetto: %.0f" % GameManager.heat)
	print("  cafe': sospetto 80 -> %.0f" % GameManager.heat)
	n.queue_free()

	# Totore: 'o purtone scioglie 'e stelle.
	GameManager.giornata = 12
	GameManager.heat = 95.0
	GameManager.stelle = 2
	var t = await _mette("totore")
	t.player_interact()
	t.player_interact()
	if GameManager.stelle != 0:
		male("'o purtone nun ha sciuoveto 'e stelle: %d" % GameManager.stelle)
	if GameManager.heat >= 95.0:
		male("'o purtone nun cala 'o sospetto")
	print("  purtone: 2 stelle -> %d, sospetto 95 -> %.0f"
		% [GameManager.stelle, GameManager.heat])
	t.queue_free()

	# Mimmo: dice addo' sta 'a Signora, e adda dicere 'o posto d''o
	# GameManager — no 'nu posto 'nventato.
	GameManager.giornata = 13
	GameManager.money = 50
	GameManager.signora_posto = 2
	GameManager.signora_data = false
	var m = await _mette("mimmo")
	var detto: String = m._addo_sta_a_signora()
	var dove: Dictionary = GameManager.signora_dove()
	if detto.find(str(dove["nome"])) < 0:
		male("Mimmo nun dice 'o posto giusto: %s" % detto)
	print("  Mimmo: %s" % detto)
	# E si oggi nun esce, adda 'o dicere, no 'nventarse 'nu posto.
	GameManager.signora_posto = -1
	var vacante: String = m._addo_sta_a_signora()
	if vacante.find("nun s'è vista") < 0:
		male("senza Signora dice: %s" % vacante)
	print("  senza Signora: %s" % vacante)
	m.queue_free()
	GameManager.stelle = 0
	GameManager.heat = 0.0


func _prova_frittata() -> void:
	print("=== 'A FRITTATA 'E ROSA ===")
	# La regola della 0.54 è che le ossa **non si rimettono da sole**. Rosa
	# è l'unica eccezione di giorno, ed è un'eccezione stretta: costa,
	# vale una volta al giorno, e cura meno del cornetto. Se uno di questi
	# tre pezzi salta, la regola è scritta in un file e disfatta in un
	# altro.
	const Cornetteria := preload("res://scripts/cornetteria_3d.gd")
	if Vicino.FRITTATA_OSSA >= Cornetteria.CORNETTO_OSSA:
		male("'a frittata cura quanto 'o cornetto: nun serve cchiù 'a nuttata")
	print("  frittata %.0f ossa < cornetto %.0f ossa"
		% [Vicino.FRITTATA_OSSA, Cornetteria.CORNETTO_OSSA])

	GameManager.rapporti = {}
	GameManager.giornata = 7
	GameManager.money = 20
	GameManager.health = 20.0
	var r = await _mette("rosa")
	r.player_interact()
	r.player_interact()
	var doppo: float = GameManager.health
	if not is_equal_approx(doppo, 20.0 + Vicino.FRITTATA_OSSA):
		male("ha curato %.1f invece 'e %.1f" % [doppo - 20.0,
			Vicino.FRITTATA_OSSA])
	print("  20 -> %.0f ossa, e €%d rimaste" % [doppo, GameManager.money])

	# E non due volte: se no si sta lì a mangiare pane e la nottata non
	# serve più a niente.
	var prima: float = GameManager.health
	r.player_interact()
	if GameManager.health > prima:
		male("s'è magnato 'na seconda frittata 'o stesso juorno")
	print("  'na frittata sola â jurnata")

	# Un'ora di gioco dopo, senza mangiare, le ossa devono stare ferme.
	# È la prova che la 0.54 non ha rimesso la cura automatica da una
	# porta di servizio.
	var q: float = GameManager.health
	for i in range(600):
		GameManager._process(0.1)
	if GameManager.health > q + 0.01:
		male("ll'ossa so' saglute 'a sole: %.1f -> %.1f" % [q,
			GameManager.health])
	print("  60 seconde senza magnà: ll'ossa stanno ferme a %.0f"
		% GameManager.health)
	r.queue_free()


## 'A notte se ne vanno a durmì (0.55): chi dorme nun se vede e nun se pò
## chiammà — e soprattutto nun adda lassà 'nu muro invisibile 'n miezo ô vico.
func _prova_notte() -> void:
	print("=== 'A NOTTE ===")
	GameManager.start_shift()
	var nomi := ["nunzia_bar", "totore", "rosa", "mimmo"]
	var fatte := {}
	for id in nomi:
		var n = await _mette(id)
		# Pieno giorno: ce stanno tutte quante.
		GameManager.shift_time_left = GameManager.shift_duration * 0.95
		n._process(0.1)
		var juorno: bool = n.visible
		var prompt_juorno: String = n.get_interact_prompt(Vector3.ZERO)
		# Nuttata.
		GameManager.shift_time_left = GameManager.shift_duration * 0.02
		n._process(0.1)
		var notte: bool = n.visible
		var prompt_notte: String = n.get_interact_prompt(Vector3.ZERO)
		fatte[id] = notte
		print("  %-11s juorno %s · notte %s"
			% [id, "ce sta" if juorno else "nun ce sta",
				"ce sta" if notte else "se n'è ghiuto"])
		if not juorno:
			male("%s nun ce sta manco 'e juorno" % id)
		if prompt_juorno == "":
			male("%s 'e juorno nun se pò chiammà" % id)
		if not notte and prompt_notte != "":
			male("%s dorme e se pò ancora chiammà" % id)
		# E il collider deve spegnersi insieme al corpo: un muro
		# invisibile in mezzo al vico è il difetto peggiore, perché non si
		# vede e non si capisce.
		if not notte and n.get_collision_layer_value(3):
			male("%s dorme ma 'o collider suio sta ancora llà" % id)
		n.queue_free()
	# Totore è il guardiano: la notte è il suo turno, e deve restare.
	if fatte.get("totore", false) != true:
		male("Totore 'o guardiano se ne va 'a notte: chillo è 'o turno suio")
	# Ma non devono restarci tutti, se no non è cambiato niente.
	var restate := 0
	for id in fatte:
		if fatte[id]:
			restate += 1
	if restate >= nomi.size():
		male("nun se ne va nisciuno: 'a notte è eguale ô juorno")
	print("  'a notte restano %d ncopp'a %d" % [restate, nomi.size()])
