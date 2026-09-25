extends Node
## **'E guagliune faticano overo?** (0.61)
##
## Il capo, dopo una giornata intera: *«I waglioni che assumi per lavorare
## al posto tuo non funzionano, controlla che davvero fanno parcheggiare le
## auto e si prendono i soldi.»*
##
## `prova_guagliune` guarda i numeri (esperienza, umore, salvataggio) e li
## trova giusti da cinque versioni. Nessuno aveva mai guardato **la
## piazza**: questa prova assume un guaglione in ognuna delle quattro,
## allontana il giocatore, fa girare il tempo e conta — per ogni piazza —
## quante macchine arrivano, quante ne va a prendere, quante ne mette nelle
## strisce e quanti soldi gli restano in tasca.

const DURATA: float = 240.0

var storte: int = 0


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(120):
		await get_tree().process_frame
	get_tree().paused = false
	GameManager.start_shift()
	GameManager.zone_mie = ["piazza", "stadio", "mercato", "cornetteria"]
	GameManager.money = 9999
	for z in ["piazza", "stadio", "mercato", "cornetteria"]:
		GameManager.dipendenti.erase(z)
		if not GameManager.assumi(z, "Prova_" + z):
			male("nun s'è assunto a %s" % z)
	GameManager.dipendenti_cambiati.emit()
	# Il giocatore se ne va a casa d'altri: in mezzo alla città, lontano
	# da tutte e quattro le piazze.
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	if pl:
		pl.global_position = Vector3(90, 1, 88)

	var guagliuni := {}
	for g in get_tree().get_nodes_in_group("guagliuni"):
		guagliuni[str(g.get("zona_id"))] = g
	print("  %d guagliuni ncopp'â città" % guagliuni.size())

	var fasi := {}
	var ultima_fase := {}
	var bloccato := {}
	var ultimo_pos := {}
	for z in guagliuni:
		fasi[z] = [0, 0, 0, 0]
		ultima_fase[z] = 0
		bloccato[z] = 0.0
		ultimo_pos[z] = (guagliuni[z] as Node3D).global_position
	var t := 0.0
	var passo := 0.5
	var stampa := 0.0
	while t < DURATA:
		await get_tree().create_timer(passo, true, false, true).timeout
		t += passo
		GameManager.shift_time_left = maxf(GameManager.shift_time_left, 200.0)
		for z in guagliuni:
			var g: Node3D = guagliuni[z]
			var f: int = int(g.get("_fase"))
			if f != ultima_fase[z]:
				fasi[z][f] += 1
				ultima_fase[z] = f
			# Fermo sul posto mentre dovrebbe camminare?
			if f == 1 or f == 3:
				if g.global_position.distance_to(ultimo_pos[z]) < 0.05:
					bloccato[z] += passo
			ultimo_pos[z] = g.global_position
		stampa += passo
		if stampa >= 30.0:
			stampa = 0.0
			var riga := "  t=%3.0f" % t
			for z in guagliuni:
				riga += "  %s:€%d f%d" % [z, int(GameManager.dipendente(z).get("cassa", 0)),
					int(guagliuni[z].get("_fase"))]
			print(riga)
			for pn in ["Posteggio_stadio", "Posteggio_mercato", "Posteggio_cornetteria"]:
				var po = get_tree().root.find_child(pn, true, false)
				if po:
					print("    %s coda %s entrata %s misurato %s timer %.1f/%.1f nate %d"
						% [pn, str(po.get("_coda")), str(po.get("_entrata")),
						str(po.get("_misurato")), po.get("_timer").time_left,
						po.get("_timer").wait_time, _nate.get(pn.trim_prefix("Posteggio_"), 0)])

	print("=== COMME È GHIUTA ===")
	for z in guagliuni:
		var d: Dictionary = GameManager.dipendente(z)
		var auto := _auto_in(z)
		print("  %-12s cassa €%-4d clienti %-3d | parte %d, sale %d, torna %d | fermo mentre cammina %.0fs | auto: %s"
			% [z, int(d.get("cassa", 0)), int(d.get("clienti", 0)),
			fasi[z][1], fasi[z][2], fasi[z][3], bloccato[z], str(auto)])
		# 'A cornetteria 'e juorno è morta apposta (un'auto ogni quattro,
		# vedi `CARATTERE`): lì basta che ne faccia una.
		var minimo: int = 1 if z == "cornetteria" else 3
		if int(d.get("clienti", 0)) < minimo:
			male("%s: 'o guaglione ha servuto sulo %d clienti in %.0f secondi"
				% [z, int(d.get("clienti", 0)), DURATA])
		if bloccato[z] > DURATA * 0.25:
			male("%s: 'o guaglione è stato 'ntuppato %.0f secondi" % [z, bloccato[z]])

	# E 'a sera: se passi, te piglie 'a parte toia.
	for z in guagliuni:
		var prima: int = GameManager.money
		var cassa: int = int(GameManager.dipendente(z).get("cassa", 0))
		var preso: int = GameManager.ritira_cassa(z)
		if cassa > 0 and preso <= 0:
			male("%s: teneva €%d e nun m'ha dato niente" % [z, cassa])
		if GameManager.money != prima + preso:
			male("%s: 'e sorde nun so' arrivate 'n sacca" % z)
	print("=== storte: %d ===" % storte)
	get_tree().quit()


var _nate := {}


func _process(_d: float) -> void:
	for c in get_tree().get_nodes_in_group("cars"):
		if not c.has_meta("contata"):
			c.set_meta("contata", true)
			var z := str(c.get("zona_id"))
			_nate[z] = int(_nate.get(z, 0)) + 1


func _auto_in(z: String) -> Dictionary:
	var r: Array = []
	for zz in load("res://scripts/citta_3d.gd").ZONE:
		if str(zz["id"]) == z:
			r = zz["rect"]
	var conto := {}
	for c in get_tree().get_nodes_in_group("cars"):
		var p: Vector3 = (c as Node3D).global_position
		if r.size() == 4 and p.x >= r[0] and p.x <= r[2] and p.z >= r[1] and p.z <= r[3]:
			var s := str(int(c.get("state")))
			conto[s] = int(conto.get(s, 0)) + 1
	return conto
