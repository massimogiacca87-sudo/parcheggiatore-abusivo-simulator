extends Node
## **'E ccose nove d''a 0.61, provate dint'â città vera.**
##
## Il panaro, Gennarino 'o Nuovo, il turista spierzo, i testimoni e il
## fierro in prima persona. Non si guarda che il codice giri: si guarda che
## **i soldi arrivino** dove devono arrivare, che è la cosa che il capo
## guarda giocando.

var storte: int = 0


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func bbuono(msg: String) -> void:
	print("  ok: %s" % msg)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(120):
		await get_tree().process_frame
	get_tree().paused = false
	GameManager.start_shift()
	GameManager.giornata = 3
	GameManager.tipo_giornata = "normale"
	GameManager.zone_mie = ["piazza", "stadio", "mercato", "cornetteria"]
	GameManager.money = 500
	await _prova_panaro()
	await _prova_gennarino()
	await _prova_turista()
	_prova_testimoni()
	await _prova_fierro()
	print("=== storte: %d ===" % storte)
	get_tree().quit()


func _aspetta(s: float) -> void:
	var t := 0.0
	while t < s:
		await get_tree().process_frame
		t += get_process_delta_time()
		GameManager.shift_time_left = maxf(GameManager.shift_time_left, 200.0)


func _pl() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D


func _prova_panaro() -> void:
	print("=== 'O PANARO ===")
	var p = get_tree().root.find_child("Panaro", true, false)
	if p == null:
		male("'o panaro nun ce sta")
		return
	print("  appiso a %s" % str((p as Node3D).global_position.round()))
	# Prima che faccia il programma suo della giornata, se no lo azzera.
	p.set("_giornata", GameManager.giornata)
	p.set("_richiesta", p.RICHIESTE[0])
	p.set("_meta_cesto", 0.0)
	await _aspetta(6.0)
	var corpo = p.get("_corpo")
	if int(corpo.collision_layer) != 4:
		male("'o panaro è sciso ma nun se pò agganciare (strato %d)" % corpo.collision_layer)
	# Il cesto deve stare a terra e fuori dal muro.
	var cesto: Node3D = p.get("_cesto")
	print("  'o cesto sta a %s" % str(cesto.global_position))
	if cesto.global_position.y > 0.5:
		male("'o cesto nun è arrivato a terra")
	GameManager.cigarettes = 10
	var prima: int = GameManager.money
	print("  prompt: %s" % corpo.get_interact_prompt(Vector3.ZERO))
	corpo.player_interact()
	if GameManager.money != prima + 7:
		male("'e sorde d''o panaro nun so' arrivate (%d → %d)" % [prima, GameManager.money])
	elif GameManager.cigarettes != 5:
		male("'e sigarette nun so' state levate")
	else:
		bbuono("cinche sigarette → €7")


func _prova_gennarino() -> void:
	print("=== GENNARINO 'O NUOVO ===")
	var g = get_tree().root.find_child("GennarinoONuovo", true, false)
	if g == null:
		male("Gennarino nun ce sta")
		return
	GameManager.dipendenti.erase("piazza")
	GameManager.zona_corrente = "piazza"
	g.set("_visto_oggi", GameManager.giornata)
	g.call("_arriva")
	await _aspetta(70.0)
	var fase: int = int(g.get("_fase"))
	print("  fase %d, tasca €%d, cliente %d, sta a %s" % [fase, int(g.get("_tasca")),
		int(g.get("_clienti")), str((g as Node3D).global_position.round())])
	for c in get_tree().get_nodes_in_group("cars"):
		if str(c.get("zona_id")) == "piazza":
			print("    machina stato %d a %s" % [int(c.get("state")), str((c as Node3D).global_position.round())])
	print("    in_servizio %s, zona_corrente '%s'" % [str(GameManager.in_servizio), GameManager.zona_corrente])
	if fase == 0:
		male("Gennarino nun è arrivato")
	if int(g.get("_clienti")) < 1:
		male("Gennarino nun ha posteggiato manco 'na machina in 70 secondi")
	# Lo assumi.
	var tasca: int = int(g.get("_tasca"))
	g.call("player_interact")
	g.call("answer", 2)
	if not GameManager.ha_dipendente("piazza"):
		male("assumerlo nun ha funzionato")
	else:
		var d: Dictionary = GameManager.dipendente("piazza")
		print("  assunto: %s, cassa €%d" % [str(d.get("nome")), int(d.get("cassa", 0))])
		if int(d.get("cassa", 0)) < tasca:
			male("'a tasca soja nun è passata dint'â cassa")
		else:
			bbuono("assunto gratis, cu 'a tasca dint'â cassa")
	await _aspetta(1.0)
	if int(g.get("_fase")) != 5 and int(g.get("_fase")) != 0:
		male("doppo assunto nun se ne va (fase %d)" % int(g.get("_fase")))


func _prova_turista() -> void:
	print("=== 'O TURISTA SPIERZO ===")
	var t = get_tree().root.find_child("TuristaSpierzo", true, false)
	if t == null:
		male("'o turista nun ce sta")
		return
	var pl := _pl()
	pl.global_position = Vector3(31, 1, 30)
	await _aspetta(0.5)
	t.set("_visto_oggi", GameManager.giornata)
	t.call("_compare")
	if not bool(t.get("_attivo")):
		male("'o turista nun è comparso")
		return
	var meta: Dictionary = t.get("_meta")
	print("  vò ì a %s, sta a %s" % [str(meta.get("nome")), str((t as Node3D).global_position.round())])
	t.call("player_interact")
	t.call("answer", 0)
	if not bool(t.get("_segue")):
		male("nun te vène appriesso")
	await _aspetta(2.0)
	var d0: float = (t as Node3D).global_position.distance_to(pl.global_position)
	print("  doppo 2 secondi sta a %.1f m 'a te" % d0)
	# Si porta il giocatore alla piazza, a piedi finti.
	var mp: Vector3 = t.get("_meta_p")
	var prima: int = GameManager.money
	pl.global_position = mp + Vector3(2, 1, 2)
	await _aspetta(4.0)
	if GameManager.money <= prima:
		male("arrivati a %s ma 'a mancia nun è arrivata" % str(meta.get("nome")))
	else:
		bbuono("mancia €%d" % (GameManager.money - prima))


func _prova_testimoni() -> void:
	print("=== CHI TE VEDE ===")
	var n: int = GameManager.testimoni(_pl().global_position)
	print("  mo' te vedono %d persone (peso %.1f)" % [n, GameManager.peso_testimoni(n)])
	if GameManager.peso_testimoni(0) >= 1.0:
		male("senza testimoni nun costa meno")
	if GameManager.peso_testimoni(20) > 2.0:
		male("cu vinte testimoni costa cchiù d''o doppio")


func _prova_fierro() -> void:
	print("=== 'O FIERRO 'N MANO ===")
	var pl := _pl()
	var fp = pl.get("_arma_fp")
	if fp == null:
		male("nun ce sta 'o fierro 'n primma perzona")
		return
	for a in ["cric", "mazza", "curtiello", "fierro", "kalash", ""]:
		GameManager.armi[a] = true
		GameManager.arma_in_mano = a
		pl.call("_aggiorna_arma_vista")
		await get_tree().process_frame
		var si_vede: bool = fp.visible
		if (a == "") == si_vede:
			male("'%s': visibile %s" % [a, str(si_vede)])
		if a != "":
			fp.call("colpo")
			await _aspetta(0.1)
			if float(fp.get("_t_colpo")) < 0.0:
				male("'%s': 'o colpo nun parte" % a)
	bbuono("cinque fierre, cinque colpi")
