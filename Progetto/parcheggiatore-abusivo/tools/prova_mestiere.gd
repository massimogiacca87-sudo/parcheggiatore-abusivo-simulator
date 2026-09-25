extends Node
## 'E mestiere d''e passante: se veco 'a differenza?
##
## La domanda non è se la tabella è scritta bene — quella si legge. La
## domanda è se **su nove persone in vista se ne vedono almeno quattro
## diverse**, che è il numero che decide se una strada sembra abitata o
## sembra un fondale con lo stesso pupo incollato nove volte.
##
## Si misura la cosa vera: si tirano mille passanti e si guarda cosa esce.
## Un mestiere che compare una volta su duecento è un mestiere che il
## giocatore non vedrà mai, e allora tanto vale non averlo scritto.
##
## Poi si controllano le due cose che si rompono in silenzio: che la
## velocità del mestiere finisca davvero addosso al passante (un turista
## che cammina come un operaio è un manichino con la maglietta a fiori), e
## che le battute siano sue e non tutte uguali.

const Passante := preload("res://scripts/passante_3d.gd")

var storte: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame

	_prova_tavola()
	_prova_quanto_esceno()
	await _prova_velocita()
	await _prova_che_dice()
	await _prova_costruzione()

	print("=== storte: %d ===" % storte)
	get_tree().quit()


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func _prova_tavola() -> void:
	print("=== 'A TAVOLA ===")
	var viste: Array[String] = []
	var cose: Array[String] = []
	for m in Passante.MESTIERE:
		for k in ["id", "peso", "veloce", "ferma", "camicia", "pantalone",
				"cosa", "dice"]:
			if not m.has(k):
				male("%s: manca '%s'" % [m.get("id", "?"), k])
		var id := str(m["id"])
		if viste.has(id):
			male("mestiere ddoje vote: %s" % id)
		viste.append(id)
		if float(m["peso"]) <= 0.0:
			male("%s pesa zero: nun esce maje" % id)
		# Le due che contano davvero. Un moltiplicatore fuori da questa
		# forbice non è "un mestiere diverso": è uno che corre o uno fermo.
		if float(m["veloce"]) < 0.6 or float(m["veloce"]) > 1.6:
			male("%s va a %.2f: nun è cchiù 'na camminata" % [id, m["veloce"]])
		if float(m["ferma"]) < 0.3 or float(m["ferma"]) > 3.0:
			male("%s se ferma %.2f vote" % [id, m["ferma"]])
		if Array(m["camicia"]).is_empty():
			male("%s nun tene culore" % id)
		if Array(m["dice"]).size() < 2 and str(m["cosa"]) == "":
			male("%s nun tene né voce né cose 'n mano" % id)
		if str(m["cosa"]) != "":
			cose.append(str(m["cosa"]))
	print("  %d mestiere" % Passante.MESTIERE.size())
	# Sagome diverse: se cinque mestieri portano tutti la busta, da venti
	# metri sono cinque volte la stessa persona.
	var diverse := {}
	for c in cose:
		diverse[c] = true
	print("  %d cose 'n mano deverse ncopp'a %d" % [diverse.size(), cose.size()])
	if diverse.size() < 4:
		male("sulo %d sagome deverse" % diverse.size())
	# E le velocità devono spanciare: se stanno tutte fra 0,95 e 1,05 la
	# tabella c'è ma non si vede.
	var vmin := 9.0
	var vmax := 0.0
	for m2 in Passante.MESTIERE:
		vmin = minf(vmin, float(m2["veloce"]))
		vmax = maxf(vmax, float(m2["veloce"]))
	print("  velocità 'a %.2f a %.2f" % [vmin, vmax])
	if vmax / vmin < 1.4:
		male("tutte 'e mestiere vanno â stessa velocità")


func _prova_quanto_esceno() -> void:
	print("=== CHI ESCE ===")
	var conta := {}
	for i in range(4000):
		var m: Dictionary = Passante._pesca_mestiere()
		var id := str(m["id"])
		conta[id] = int(conta.get(id, 0)) + 1
	var chiavi: Array = conta.keys()
	chiavi.sort_custom(func(a, b): return int(conta[a]) > int(conta[b]))
	for k in chiavi:
		print("  %-11s %5.1f%%" % [k, float(conta[k]) / 40.0])
	if conta.size() != Passante.MESTIERE.size():
		male("ncopp'a 4000 nun so' asciute tutte quante")
	# **'A prova ca conta: nove 'n vista, quante facce?**
	#
	# Non basta che tutti escano ogni tanto: serve che in una manciata di
	# gente ce ne siano diversi. Si simula la piazza — nove passanti — e si
	# guarda quanti mestieri diversi ci sono dentro, mille volte.
	var somma := 0.0
	var peggio := 9
	for giro in range(1000):
		var visti := {}
		for i in range(9):
			visti[str(Passante._pesca_mestiere()["id"])] = true
		somma += visti.size()
		peggio = mini(peggio, visti.size())
	var media: float = somma / 1000.0
	print("  ncopp'a 9 'n vista: %.1f mestiere deverse (peggio caso %d)"
		% [media, peggio])
	if media < 4.0:
		male("nove passante danno sulo %.1f facce" % media)
	if peggio < 2:
		male("'nu giro cu 'nu mestiere sulo")


func _uno(id: String) -> Node:
	var p = Passante.new()
	for m in Passante.MESTIERE:
		if str(m["id"]) == id:
			p.mestiere = m
			break
	add_child(p)
	await get_tree().process_frame
	return p


func _prova_velocita() -> void:
	print("=== 'A VELOCITÀ ARRIVA ADDÒ SERVE ===")
	# Il pezzo che si rompe in silenzio: la tabella dice 0,74 e il passante
	# cammina a 1,3 lo stesso perché il moltiplicatore si è perso fra
	# `_ready` e `_costruisci`.
	var t = await _uno("turista")
	var o = await _uno("operaio")
	print("  turista %.2f m/s · operaio %.2f m/s" % [t._velocita, o._velocita])
	if t._velocita >= o._velocita:
		male("'o turista va comme a ll'operaio")
	if t._velocita > Passante.VELOCITA_MAX:
		male("'o turista sfonna 'o massimo: %.2f" % t._velocita)
	# E nessuno deve trottare: era il difetto della 0.49, e un
	# moltiplicatore nuovo lo può rifare.
	for id in ["studente", "operaio", "quartiere"]:
		var p = await _uno(id)
		if p._velocita > 2.2:
			male("%s trotta: %.2f m/s" % [id, p._velocita])
		p.queue_free()
	t.queue_free()
	o.queue_free()


func _prova_che_dice() -> void:
	print("=== CHE DICE ===")
	var p = await _uno("pizzaiuolo")
	var mie := 0
	var tutte := 0
	var deverse := {}
	for i in range(600):
		var t: String = p._che_dice()
		deverse[t] = true
		var e_mia := false
		for d in p.mestiere["dice"]:
			if t == str(d):
				e_mia = true
		if e_mia:
			mie += 1
		else:
			tutte += 1
	print("  %d d''o mestiere, %d 'e tuttuquante, %d frase deverse"
		% [mie, tutte, deverse.size()])
	# Due su tre sue: se fossero tutte sue diventa un disco, se fossero
	# tutte generiche il mestiere non si sente.
	var quota: float = float(mie) / 600.0
	if quota < 0.5 or quota > 0.8:
		male("'a quota d''e battute soie è %.2f" % quota)
	if deverse.size() < 8:
		male("sulo %d frase deverse: se sente 'a ripetizione" % deverse.size())
	p.queue_free()


func _prova_costruzione() -> void:
	print("=== SE COSTRUISCENO TUTTE ===")
	# Ogni mestiere deve arrivare in piedi con il suo affare in mano: un
	# osso sbagliato nella tabella non dà errore, dà un pupo senza niente.
	for m in Passante.MESTIERE:
		var id := str(m["id"])
		var p = await _uno(id)
		await get_tree().process_frame
		if p._visual == null or p._visual.get_child_count() == 0:
			male("%s nun s'è custruito" % id)
			continue
		if str(m["cosa"]) != "" and str(m["cosa"]) != "busta":
			# Cerca la mesh appesa da qualche parte sotto al corpo.
			if not _tene_chello_ca_porta(p):
				male("%s nun tene niente 'n mano" % id)
		print("  %-11s ok" % id)
		p.queue_free()


func _tene_chello_ca_porta(n: Node) -> bool:
	return _cerca_mesh(n, 0)


func _cerca_mesh(n: Node, prof: int) -> bool:
	if prof > 12:
		return false
	for f in n.get_children():
		if f is MeshInstance3D and (f as MeshInstance3D).mesh is BoxMesh:
			return true
		if _cerca_mesh(f, prof + 1):
			return true
	return false
