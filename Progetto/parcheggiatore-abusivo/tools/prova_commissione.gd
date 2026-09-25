extends Node
## 'O giro d''o cliente: scenne, va a fà 'a spesa, torna, e se ne va.
##
## Questa prova nasce da un difetto che il capo ha visto giocando e che
## nessuna delle ventitré prove di prima poteva vedere: **il giro non
## finiva mai.** La macchina chiamava indietro l'autista perché c'era un
## danno, l'autista faceva la scenata, la macchina rimetteva il contatore
## a mezzo secondo — e siccome il danno stava ancora lì, mezzo secondo
## dopo ne chiamava un altro. Per sempre, con un cliente perso contato a
## ogni giro.
##
## È un difetto di **forma**, non di numeri: nessuna quantità era
## sbagliata: era il grafo degli stati ad avere un anello. E un anello si
## trova in un modo solo — facendo girare il giro fino in fondo e
## contando quante volte passa dallo stesso punto.
##
## Quindi qui si simula la sosta intera, a passi grossi, e si controllano
## tre cose:
##
##   1. che finisca — sempre, in tutti e quattro i casi (pulita, multa,
##      stemma, riga);
##   2. che l'autista sia **uno solo** dall'inizio alla fine;
##   3. che la macchina se ne vada, cioè che il posto torni libero.

const Driver := preload("res://scripts/driver_3d.gd")
const Gente := preload("res://scripts/gente.gd")

## Quanto tempo di gioco si lascia al giro prima di dichiararlo bloccato.
## Una sosta lunga è un minuto e mezzo; tre minuti sono il doppio abbondante.
const PAZIENZA: float = 180.0
const PASSO: float = 0.1

var storte: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	GameManager.start_shift()

	_prova_negozie()
	await _prova_giro("pulita", {})
	await _prova_giro("multa", {"has_multa": true})
	await _prova_giro("stemma", {"_stemma_sparito": true})
	await _prova_giro("riga", {"_scassata_ammuccione": true})
	await _prova_tutte_nzieme()

	print("=== storte: %d ===" % storte)
	get_tree().quit()


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


# ---------------------------------------------------------------------------

## 'E negozie: ce stanno, e stanno addò se pò stà.
func _prova_negozie() -> void:
	print("=== 'E NEGOZIE ===")
	var Citta = load("res://scripts/citta_3d.gd")
	var negozi: Array = get_tree().get_nodes_in_group("negozi")
	print("  %d vetrine dint'ô gruppo" % negozi.size())
	if negozi.size() < 20:
		male("troppo poche vetrine: %d" % negozi.size())
		var citta := get_tree().get_first_node_in_group("citta")
		if citta:
			for v in citta.get("_vetrine_scartate"):
				print("    scartata %s ang %d: %s" % [str((v[0] as Vector3).round()), int(v[1]), " ".join(PackedStringArray(v[2]))])

	# Ognuna deve avere il punto dove ci si ferma, e quel punto deve
	# essere un posto in cui una persona ci può stare: non in mezzo alla
	# corsia libera di una strada, non dentro al varco delle auto. È lo
	# stesso controllo delle bancarelle (0.53) e dei vicini (0.54).
	var senza := 0
	var storte_corsia := 0
	var storte_varco := 0
	for n in negozi:
		if not n.has_meta("punto"):
			senza += 1
			continue
		var p: Vector3 = n.get_meta("punto")
		if Citta.in_corsia(p, Vector3(0.7, 1.8, 0.7)):
			storte_corsia += 1
			if storte_corsia <= 3:
				print("    'n miezo â strada: %s (%.0f, %.0f)"
					% [n.get_meta("nome", "?"), p.x, p.z])
		if Citta.dentro_varco(p):
			storte_varco += 1
			if storte_varco <= 3:
				print("    dint'ô varco: %s (%.0f, %.0f)"
					% [n.get_meta("nome", "?"), p.x, p.z])
	if senza > 0:
		male("%d vetrine senza 'o punto addò se sta" % senza)
	if storte_corsia > 0:
		male("%d vetrine cu 'o punto 'n miezo â strada" % storte_corsia)
	if storte_varco > 0:
		male("%d vetrine cu 'o punto dint'ô varco" % storte_varco)

	# **E ognuna d''e quatte piazze adda tené 'o negozio suio vicino.**
	# Se il più vicino sta a quarantacinque metri, ogni cliente attraversa
	# mezza città per comprare il pane e la sosta dura il doppio.
	print("  %-22s 'o cchiu' vicino" % "piazza")
	for piazza in [["'a piazza toia", Vector3(31, 0, 30)],
			["'o stadio", Vector3(136, 0, 33)],
			["'o mercato", Vector3(39, 0, 123)],
			["'a cornetteria", Vector3(124, 0, 123)]]:
		var meglio := 9999.0
		var quale := "-"
		for n in negozi:
			var d: float = Vector3(piazza[1]).distance_to(
				(n as Node3D).global_position)
			if d < meglio:
				meglio = d
				quale = str(n.get_meta("nome", "?"))
		print("  %-22s %.0f m (%s)" % [piazza[0], meglio, quale])
		if meglio > Driver.NEGOZIO_PORTATA:
			male("%s: 'o negozio cchiu' vicino sta a %.0f m, cchiu' 'e %.0f"
				% [piazza[0], meglio, Driver.NEGOZIO_PORTATA])


## La finta macchina: il minimo che serve a un autista per fare il suo giro.
class FintaMachina extends Node3D:
	var paid: bool = false
	var has_multa: bool = false
	var _stemma_sparito: bool = false
	var _scassata_ammuccione: bool = false
	var _multa_confronto: bool = false
	var cliente_id: String = ""
	var personality: String = "normale"
	## Quante volte è stata dichiarata "libera": se diventa due, c'è
	## l'anello.
	var fernute: int = 0

	func l_autista_ha_fernuto() -> void:
		fernute += 1

	func payment_chance() -> float:
		return 0.0

	func payment_amount() -> int:
		return 3

	func punches_needed() -> int:
		return 2


func _prova_giro(nome: String, guaje: Dictionary) -> void:
	print("=== 'O GIRO: %s ===" % nome)
	var m := FintaMachina.new()
	add_child(m)
	m.global_position = Vector3(31, 0, 30)
	for k in guaje:
		m.set(k, guaje[k])

	var d = Driver.new()
	add_child(d)
	d.global_position = Vector3(32.4, 0, 30)
	d.setup(m, Vector3(31, 0, 52))
	d.durata_spesa = 20.0
	await get_tree().process_frame

	var t := 0.0
	var stati := {}
	while t < PAZIENZA and is_instance_valid(d) and m.fernute == 0:
		d._physics_process(PASSO)
		stati[int(d.state)] = true
		t += PASSO
		# Ogni tanto un giro vero, se no `await` non cede mai il controllo
		# e i nodi non si liberano.
		if fmod(t, 5.0) < PASSO:
			await get_tree().process_frame

	if m.fernute == 0:
		male("%s: 'o giro nun è fernuto dint'a %.0f seconde (stato %d)"
			% [nome, PAZIENZA, d.state if is_instance_valid(d) else -1])
	elif m.fernute > 1:
		male("%s: 'a machina s'è liberata %d vote" % [nome, m.fernute])
	else:
		print("  fernuto doppo %.0f s, passanno pe' %d state"
			% [t, stati.size()])

	# Il giro pulito non deve mai passare dagli stati del confronto: se ci
	# passa, vuol dire che tutti vengono a chiederti conto — che è la
	# seconda metà della segnalazione del capo.
	if nome == "pulita":
		for brutto in [Driver.State.CERCA, Driver.State.CONFRONTO,
				Driver.State.HUNTING]:
			if stati.has(int(brutto)):
				male("'nu cliente senza guaje t'è venuto a cercà")
		if not stati.has(int(Driver.State.ASPETTA)):
			male("nun s'è fermato maje ô negozio")
		if not stati.has(int(Driver.State.SAGLIE)):
			male("nun è muntato")
	else:
		if not stati.has(int(Driver.State.CERCA)):
			male("%s: nun t'ha cercato" % nome)

	if is_instance_valid(d):
		d.free()
	m.free()


## **'O caso ca ha fatto asci' pazzo 'o capo.**
##
## Tre guai insieme sulla stessa macchina. Prima il giro ricominciava da
## capo per ognuno: strappavi la multa, ne tornava uno per lo stemma, poi
## uno per la riga, poi di nuovo. Adesso è una scenata sola, e il motivo
## lo sceglie `_che_trova()` in ordine di quanto si vede.
func _prova_tutte_nzieme() -> void:
	print("=== TUTT''E TRE 'NZIEME ===")
	var m := FintaMachina.new()
	add_child(m)
	m.global_position = Vector3(31, 0, 30)
	m.has_multa = true
	m._stemma_sparito = true
	m._scassata_ammuccione = true

	var d = Driver.new()
	add_child(d)
	d.global_position = Vector3(32.4, 0, 30)
	d.setup(m, Vector3(31, 0, 52))
	d.durata_spesa = 16.0
	await get_tree().process_frame

	var t := 0.0
	while t < PAZIENZA and is_instance_valid(d) and m.fernute == 0:
		d._physics_process(PASSO)
		t += PASSO
		if fmod(t, 5.0) < PASSO:
			await get_tree().process_frame
	if m.fernute != 1:
		male("cu tre guaje 'a machina s'è liberata %d vote" % m.fernute)
	else:
		print("  'na scenata sola, e fernuto doppo %.0f s" % t)
	if is_instance_valid(d):
		d.free()
	m.free()
