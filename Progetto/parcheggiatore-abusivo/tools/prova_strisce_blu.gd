extends Node
## **'E strisce blu, giocate** (0.64).
##
## Nella città vera, piazza di casa:
##   1. il Comune pittura le strisce: i posti diventano blu, spuntano i
##      parchimetri (fra due e quattro, fuori dai posti, non dentro ai muri);
##   2. un cliente posteggiato sul blu col parchimetro in piedi va a pagare
##      la macchinetta e a te dice di no;
##   3. si sfasciano i parchimetri: le monete cascano, e il conto scende;
##   4. col blu e i parchimetri rotti il cliente è «fuori dalle strisce»;
##   5. la pittura si compra al bazar (tasto 7) e i posti si ripittano uno a
##      uno, fermi accanto; finito tutto, 'a piazza torna toia;
##   6. lo stato passa per il salvataggio con gli indici interi;
##   7. il dado della mattina: mai il primo giorno, mai due piazze insieme,
##      e una volta su cinque.

var storte: int = 0
var _pl: Node3D = null


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(120):
		await get_tree().process_frame
	get_tree().paused = false
	GameManager.giornata = 4
	GameManager.start_shift()
	GameManager.strisce_blu.clear()
	GameManager.tipo_giornata = "normale"
	GameManager.money = 200
	GameManager.pittura = 0
	_pl = get_tree().get_first_node_in_group("player") as Node3D
	_metti_giocatore(Vector3(31, 0, 30))
	await _aspetta(1.0)

	print("=== 1. 'O COMUNE PITTA ===")
	var z: String = GameManager._forse_strisce_blu("piazza")
	if z != "piazza":
		male("_forse_strisce_blu nun ha pittato 'a piazza")
	await _aspetta(1.2)
	var posti := _posti("piazza")
	var blu := 0
	for s in posti:
		if s.get("blu") == true:
			blu += 1
	print("  %d posti, %d blu" % [posti.size(), blu])
	if blu != posti.size() or blu == 0:
		male("'e posti nun so' tutte blu: %d su %d" % [blu, posti.size()])
	var pm: Array = get_tree().get_nodes_in_group("parchimetri")
	print("  %d parchimetri: %s" % [pm.size(), str(pm.map(func(p): return (p as Node3D).global_position.snapped(Vector3(0.1, 0.1, 0.1))))])
	if pm.size() < 2 or pm.size() > 4:
		male("%d parchimetri (ne vulevo 2-4)" % pm.size())
	if GameManager.parchimetri_sani("piazza") != pm.size():
		male("'o GameManager conta %d parchimetri sani, 'n piazza ce ne stanno %d"
			% [GameManager.parchimetri_sani("piazza"), pm.size()])
	for p in pm:
		var q: Vector3 = (p as Node3D).global_position
		for s in posti:
			var sp: Vector3 = (s as Node3D).global_position
			if absf(sp.x - q.x) < 1.1 and absf(sp.z - q.z) < 2.2:
				male("parchimetro a %s dint'ô posto a %s" % [str(q), str(sp)])
	# Il cartello: si guarda il prompt.
	if pm.size() > 0 and str(pm[0].get_interact_prompt(Vector3.ZERO)).find("Parchimetro") < 0:
		male("'o parchimetro nun se presenta")

	print("=== 2. CHI POSTEGGIA SUL BLU PAVA 'A MACCHINETTA ===")
	var c1: Node = await _posteggia_una()
	if c1 == null:
		male("nun so' riuscito a posteggià 'na machina")
	else:
		if c1.get("pavato_parchimetro") != true:
			male("posteggiata sul blu cu 'o parchimetro sano, ma nun ha pavato 'a macchinetta")
		if float(c1.call("payment_chance")) > 0.0:
			male("cu 'o parchimetro pavato, 'a probabilità ca me pava è %.2f" % float(c1.call("payment_chance")))
		await _aspetta(0.6)
		var drv = c1.get("_driver")
		if drv == null or not is_instance_valid(drv):
			male("nisciun autista è sciso")
		else:
			var soldi0: int = GameManager.money
			drv.player_interact()
			if GameManager.money != soldi0:
				male("ha pavato 'o parchimetro e pure a me (€%d)" % (GameManager.money - soldi0))
			# Va alla macchinetta.
			var t := 0.0
			var arrivato := false
			while t < 25.0 and is_instance_valid(drv):
				await _aspetta(0.25)
				t += 0.25
				if drv.get("_pagato_macchinetta") == true:
					arrivato = true
					break
			if not arrivato:
				male("l'autista nun è ghiuto ô parchimetro")
			else:
				print("  l'autista è ghiuto a pavà 'a macchinetta in %.1f s" % t)

	print("=== 3. SE SFASCIANO 'E PARCHIMETRE ===")
	var soldi1: int = GameManager.money
	for p in pm:
		var colpi := 0
		while p.get("rotto") != true and colpi < 20:
			p.receive_punch(2)
			colpi += 1
			await _aspetta(0.05)
		if p.get("rotto") != true:
			male("'o parchimetro nun se sfascia manco cu venti cazzotti")
		elif colpi != 4:
			male("cu 'e mmane ce vonno %d cazzotti (ne aspettavo 4 da 2)" % colpi)
	await _aspetta(0.3)
	print("  monete cadute: €%d" % (GameManager.money - soldi1))
	if GameManager.money - soldi1 < pm.size() * GameManager.PARCHIMETRO_MONETE_MIN:
		male("'e monete d''e parchimetre nun so' arrivate")
	if GameManager.parchimetri_sani("piazza") != 0:
		male("sfasciate tutte, e ne restano %d sane" % GameManager.parchimetri_sani("piazza"))
	if not GameManager.strisce_blu_in("piazza"):
		male("sfasciate 'e parchimetre, ma 'e strisce blu so' sparite (e 'e posti nun so' ripittate)")
	GameManager.azzera_stelle()

	print("=== 4. BLU SENZA MACCHINETTA = FORE D''E STRISCE ===")
	var c2: Node = await _posteggia_una()
	if c2 != null:
		if c2.get("pavato_parchimetro") == true:
			male("parchimetre rotte, e dice ca ha pavato")
		if c2.get("parked_abusive") != true:
			male("striscia blu senza parchimetro, ma nun conta comme fore d''e strisce")

	print("=== 5. 'A PITTURA ===")
	var baz = get_tree().get_first_node_in_group("bazar")
	if baz == null:
		male("nun trovo 'o bazar")
	else:
		GameManager.money = 100
		baz.compra_voce(GameManager.DECOR_IDS.size())
		if GameManager.pittura != 0:
			male("'a pittura s'è accattata c''o primmo tasto")
		baz.compra_voce(GameManager.DECOR_IDS.size())
		if GameManager.pittura != GameManager.PITTURA_PASSATE:
			male("accattata, ma 'n sacca ce stanno %d passate" % GameManager.pittura)
		if GameManager.money != 100 - GameManager.PITTURA_COSTO:
			male("'a pittura è costata €%d" % (100 - GameManager.money))
	# Si ripittano tutti i posti liberi; quelli occupati si aspettano.
	var giri := 0
	while GameManager.strisce_blu_in("piazza") and giri < 60:
		giri += 1
		var fatto := false
		for s in _posti("piazza"):
			if s.get("blu") != true or s.get("is_free") != true:
				continue
			if GameManager.pittura <= 0:
				GameManager.money += GameManager.PITTURA_COSTO
				GameManager.accatta_pittura()
			_metti_giocatore((s as Node3D).global_position + Vector3(1.6, 0, 0))
			await _aspetta(0.1)
			s.player_interact()
			await _aspetta(GameManager.PITTURA_TEMPO + 0.4)
			if s.get("blu") == true:
				male("pittato pe' %.1f s e 'o posto è ancora blu" % (GameManager.PITTURA_TEMPO + 0.4))
			fatto = true
			break
		if not fatto:
			# Tutti i blu rimasti hanno una macchina sopra: si aspetta che se ne vadano.
			for c in get_tree().get_nodes_in_group("cars"):
				if is_instance_valid(c) and int(c.get("state")) == 3 and c.has_method("_depart"):
					c.call("_depart")
			await _aspetta(1.5)
	if GameManager.strisce_blu_in("piazza"):
		male("ripittato tutto, ma 'e strisce blu stanno ancora")
	var ancora_blu := 0
	for s in _posti("piazza"):
		if s.get("blu") == true:
			ancora_blu += 1
	if ancora_blu > 0:
		male("%d posti so' rimaste blu" % ancora_blu)
	print("  ripittato tutto in %d giri; pittura rimasta %d" % [giri, GameManager.pittura])

	print("=== 6. 'O SALVATAGGIO ===")
	GameManager.strisce_blu = {"mercato": {"dal": 3, "rotti": [1], "pittati": [0, 2], "parchimetri": 3}}
	GameManager.pittura = 4
	var d: Dictionary = JSON.parse_string(JSON.stringify(GameManager.stato_partita()))
	GameManager.strisce_blu = {}
	GameManager.pittura = 0
	GameManager.applica_stato(d)
	if not GameManager.strisce_blu_in("mercato"):
		male("'e strisce blu nun passano p''o salvataggio")
	elif not (1 in GameManager.strisce_blu["mercato"]["rotti"]) \
			or not GameManager.parchimetro_rotto("mercato", 1) \
			or GameManager.posto_blu("mercato", 2) or not GameManager.posto_blu("mercato", 1):
		male("doppo 'o salvataggio 'e nummere nun se trovano: %s" % str(GameManager.strisce_blu))
	if GameManager.pittura != 4:
		male("'a pittura doppo 'o salvataggio è %d" % GameManager.pittura)

	print("=== 7. 'O DADO D''A MATINA ===")
	var uscite := 0
	var prove := 4000
	for i in range(prove):
		GameManager.strisce_blu.clear()
		GameManager.giornata = 1
		if GameManager._forse_strisce_blu() != "":
			male("'o primmo juorno ce stanno 'e strisce blu")
			break
		GameManager.giornata = 5
		if GameManager._forse_strisce_blu() != "":
			uscite += 1
	var quota: float = float(uscite) / float(prove)
	print("  strisce blu 'a matina: %.1f%% (%d su %d)" % [quota * 100.0, uscite, prove])
	if absf(quota - GameManager.STRISCE_BLU_PROB) > 0.03:
		male("'a probabilità è %.3f invece 'e %.2f" % [quota, GameManager.STRISCE_BLU_PROB])
	GameManager.strisce_blu = {"piazza": {"dal": 5, "rotti": [], "pittati": [], "parchimetri": 2}}
	if GameManager._forse_strisce_blu() != "":
		male("doje piazze cu 'e strisce blu 'nzieme")
	GameManager.strisce_blu.clear()
	print("=== storte: %d ===" % storte)
	get_tree().quit()


func _aspetta(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _metti_giocatore(p: Vector3) -> void:
	p.y = Collina.alzata(p.x, p.z) + 0.2
	_pl.global_position = p
	if _pl is CharacterBody3D:
		(_pl as CharacterBody3D).velocity = Vector3.ZERO


func _posti(zona: String) -> Array:
	var r: Array = []
	for s in get_tree().get_nodes_in_group("parking_spots"):
		if str(s.get("zona_id")) == zona:
			r.append(s)
	return r


## Aspetta un cliente in coda nella piazza di casa e lo mette in un posto.
func _posteggia_una() -> Node:
	_metti_giocatore(Vector3(31, 0, 30))
	var t := 0.0
	while t < 60.0:
		await _aspetta(0.25)
		t += 0.25
		GameManager.shift_time_left = maxf(GameManager.shift_time_left, GameManager.shift_duration * 0.6)
		for c in get_tree().get_nodes_in_group("cars"):
			if not is_instance_valid(c) or str(c.get("zona_id")) != "piazza":
				continue
			if int(c.get("state")) != 1:
				continue
			c.player_interact()
			var spot = c.get("assigned_spot")
			if spot == null or not is_instance_valid(spot):
				continue
			var sp: Vector3 = (spot as Node3D).global_position
			(c as Node3D).global_position = Vector3(sp.x, (c as Node3D).global_position.y, sp.z)
			(c as Node3D).rotation.y = 0.0
			var t2 := 0.0
			while t2 < 4.0 and int(c.get("state")) != 3:
				await _aspetta(0.2)
				t2 += 0.2
			if int(c.get("state")) == 3:
				return c
	return null
