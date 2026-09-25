extends StaticBody3D
## TreCarte3D — 'o gioco d''e tre carte
##
## Una cassetta della frutta rivoltata, tre carte napoletane a faccia in giù
## e uno che le mescola gridando «addò sta 'o rre». È la truffa di strada
## più vecchia di Napoli, ed è qui per quello che è: un modo divertente di
## perdere i soldi che ti sei appena fatto in piazza.
##
## ## Come funziona da giocare
##
## `E` per puntare. Le carte si girano un secondo — vedi qual è la buona —
## poi si rivoltano e cominciano gli scambi, sempre più veloci. Alla fine
## premi `1`, `2` o `3` per la carta che hai seguito.
##
## ## La cosa importante: gli scambi sono VERI
##
## `_ordine` è un array di tre indici, e ogni scambio scambia davvero due
## caselle di quell'array insieme alle carte a schermo. Se segui la carta
## con gli occhi e non sbagli, hai *trovato* la carta giusta: non è una
## finta animazione con l'esito già scritto.
##
## Poi però c'è `PROB_TRUCCO`, ed è il punto di tutto il minigioco. Il
## compare, un istante prima che tu scelga, fa sparire la buona nel palmo e
## te la mette da un'altra parte. Perché è così che funziona il gioco vero:
## **al gioco delle tre carte non si vince**, e un minigioco onesto sarebbe
## stato una bugia più grande del trucco.
##
## Due correttivi, perché una truffa perfetta non è divertente per nessuno:
##
##   1. **La prima partita la vinci sempre.** È l'aggancio vero: il compare
##      ti lascia vincere la prima per farti puntare la seconda.
##   2. Il trucco scatta solo se avevi indovinato. Se avevi già sbagliato
##      da solo, non serve barare, e la carta che si scopre è quella dove
##      stava davvero — se no uno sospetta che le carte non esistano.
##
## ## 'O palo
##
## Se c'è un vigile nel raggio di quindici metri il banco si smonta da solo
## e non si può giocare: le tre carte a Napoli si smontano in due secondi,
## ed è metà del motivo per cui la cassetta della frutta è quella giusta.

const CarteScript := preload("res://scripts/carte.gd")
const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const HumanBuilderScript := preload("res://scripts/human_builder.gd")
const Tex := preload("res://scripts/textures.gd")
const Models := preload("res://scripts/models.gd")

enum Stato { FERMO, MOSTRA, MESCOLA, SCEGLI, ESITO, PALO }

const PUNTATA: int = 3
const VINCITA: int = 7
const CALORE: float = 2.5     # giocare per strada ti fa notare un po'

## Quanto spesso il compare bara, quando avevi indovinato.
const PROB_TRUCCO: float = 0.62

const DURATA_MOSTRA: float = 1.5
const DURATA_SCAMBIO_DA: float = 0.42   # il primo scambio, lento
const DURATA_SCAMBIO_A: float = 0.16    # gli ultimi, svelti
const SCAMBI: int = 7
const DURATA_ESITO: float = 3.2
const PALO_RAGGIO: float = 15.0

const POSTI := [Vector3(-0.19, 0.0, 0.0), Vector3(0.0, 0.0, 0.0),
	Vector3(0.19, 0.0, 0.0)]
const ALTEZZA_TAVOLO: float = 0.52

## **Si cerca 'O RE, non la donna.**
##
## Nel gioco delle tre carte inglese la carta buona è la regina — si chiama
## proprio *find the lady*. Ma nel mazzo napoletano la regina NON ESISTE: le
## figure sono fante, cavallo e re. La carta buona qui è sempre stata il re
## di denari (vedi `_build_carte`); era solo il compare che chiedeva della
## donna, e cercare una carta che nel mazzo non c'è è la cosa più sbagliata
## che potesse dire.
const SAY_RICHIAMO := [
	"Uè guagliò, addò sta 'o rre?",
	"Trova 'o rre e pigliate 'e sorde!",
	"Facile facile, 'o vide pure 'a casa toia!",
	"Tre carte, una sola vence: 'o rre!",
]
const SAY_VINTO := ["Mannaggia... hê vinciuto tu.", "Bravo! Mo' 'n'ata vota!",
	"Hê visto ca era facile?"]
const SAY_PERSO := ["Eh! Nun era chella!", "Vicino vicino... ma no.",
	"'A prossima 'a truove!", "Pare facile, eh?"]
const SAY_SQUATTRINATO := "E co' che punte, cu 'e figurine?"
const SAY_PALO := "'O PALO! Smammamm'!"

var _stato: int = Stato.FERMO
var _t: float = 0.0
var _ordine: Array[int] = [0, 1, 2]   # _ordine[posto] = quale carta ci sta
var _buona: int = 0                   # indice della carta vincente in _ordine
var _carte: Array[Node3D] = []
var _facce: Array[int] = []
var _scambi_fatti: int = 0
var _scambio_da: int = 0
var _scambio_a: int = 0
var _scambio_t: float = 0.0
var _scambio_durata: float = 0.3
var _scelta: int = -1
var _giocate: int = 0
var _vinte: int = 0
var _bubble: Node3D
var _richiamo_cd: float = 4.0
var _banco: Node3D


func _ready() -> void:
	add_to_group("attivita")
	add_to_group("tre_carte")
	collision_layer = 1
	collision_mask = 0
	_build_visual()
	_build_collisione()
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 2.1, -0.55)
	add_child(_bubble)
	_riposiziona(true)


# ---------------------------------------------------------------------------
# Costruzione
# ---------------------------------------------------------------------------

func _build_visual() -> void:
	_banco = Node3D.new()
	add_child(_banco)

	# La cassetta della frutta rivoltata: è il tavolo vero di questo gioco,
	# perché si prende sotto braccio e si scappa.
	var cassa := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(0.62, ALTEZZA_TAVOLO, 0.44)
	cassa.mesh = cm
	cassa.position = Vector3(0, ALTEZZA_TAVOLO * 0.5, 0)
	var legno := StandardMaterial3D.new()
	legno.albedo_color = Color(0.72, 0.62, 0.45)
	legno.roughness = 0.9
	cassa.material_override = legno
	_banco.add_child(cassa)

	# Le doghe: due liste chiare sui fianchi, che è quello che distingue una
	# cassetta da una scatola qualunque.
	for lato in [-1.0, 1.0]:
		for y in [0.14, 0.34]:
			var d := MeshInstance3D.new()
			var dm := BoxMesh.new()
			dm.size = Vector3(0.64, 0.06, 0.02)
			d.mesh = dm
			d.position = Vector3(0, y, lato * 0.225)
			var chiaro := StandardMaterial3D.new()
			chiaro.albedo_color = Color(0.86, 0.78, 0.6)
			chiaro.roughness = 0.9
			d.material_override = chiaro
			_banco.add_child(d)

	# Il panno verde sopra: serve a far scivolare le carte, e a far vedere
	# da lontano che lì si gioca.
	var panno := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.66, 0.012, 0.48)
	panno.mesh = pm
	panno.position = Vector3(0, ALTEZZA_TAVOLO + 0.006, 0)
	var verde := StandardMaterial3D.new()
	verde.albedo_color = Color(0.12, 0.34, 0.18)
	verde.roughness = 0.95
	panno.material_override = verde
	_banco.add_child(panno)

	# **'E sorde ncopp'ô panno** (0.60, PSX): il mazzetto del compare e le
	# monete di chi ha appena perso, dalla sua parte del tavolo. Senza soldi
	# sopra, le tre carte sono un solitario.
	for e in [
			["mazzetto", Vector3(0.21, 0.0, -0.15), 22.0],
			["banconota", Vector3(0.08, 0.0, -0.17), -38.0],
			["soldi_piegati", Vector3(-0.22, 0.0, -0.14), 70.0],
			["moneta", Vector3(-0.08, 0.0, -0.17), 0.0],
			["moneta", Vector3(-0.05, 0.0, -0.19), 0.0],
			["moneta", Vector3(-0.1, 0.004, -0.18), 0.0],
		]:
		var o := Models.spawn(str(e[0]))
		if o == null:
			continue
		o.position = (e[1] as Vector3) + Vector3(0, ALTEZZA_TAVOLO + 0.012, 0)
		o.rotation.y = deg_to_rad(float(e[2]))
		_banco.add_child(o)

	_build_carte()
	_build_compare()


func _build_carte() -> void:
	# Tre carte a caso dal mazzo, ma una sola è quella buona: il
	# RE DI DENARI — quello con la faccia grossa, che si riconosce a colpo
	# d'occhio anche da un metro e mezzo. Le altre due sono due carte
	# basse di bastoni, che a rovescio sono identiche ma girate non si
	# confondono con la buona nemmeno con la coda dell'occhio.
	_facce = [CarteScript.indice(1, 10), CarteScript.indice(2, 3),
		CarteScript.indice(2, 5)]
	for i in range(3):
		var carta := Node3D.new()
		var faccia := MeshInstance3D.new()
		faccia.mesh = CarteScript.mesh(1.35)
		faccia.material_override = CarteScript.materiale(_facce[i])
		# La carta è distesa sul tavolo: il quad guarda in alto.
		faccia.rotation.x = -PI / 2.0
		carta.add_child(faccia)
		var retro := MeshInstance3D.new()
		retro.mesh = CarteScript.mesh(1.35)
		retro.material_override = CarteScript.retro()
		retro.rotation.x = -PI / 2.0
		retro.position.y = 0.001
		carta.add_child(retro)
		carta.position = Vector3(POSTI[i].x, ALTEZZA_TAVOLO + 0.02, 0)
		_banco.add_child(carta)
		_carte.append(carta)


## Il compare dietro al banco. Non cammina mai: sta lì, e le mani le muove
## il minigioco.
func _build_compare() -> void:
	var p := HumanBuilderScript.build(Color(0.16, 0.16, 0.18),
		Color(0.2, 0.2, 0.24), "", 1.74,
		{"belly": 0.35, "moustache": true})
	var g: Node3D = p["root"]
	# Sta DIETRO al banco, cioè a -Z: il giocatore arriva da +Z e deve
	# vedere le carte, non la schiena del compare.
	g.position = Vector3(0, 0, -0.62)
	# I rig guardano verso -Z quando la rotazione è zero, quindi per
	# guardare chi arriva bisogna girarlo di mezzo giro.
	g.rotation.y = PI
	add_child(g)


func _build_collisione() -> void:
	var f := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(0.9, 1.9, 1.5)
	f.shape = b
	f.position = Vector3(0, 0.95, -0.3)
	add_child(f)


# ---------------------------------------------------------------------------
# Interazione
# ---------------------------------------------------------------------------

func get_interact_prompt(_da: Vector3) -> String:
	match _stato:
		Stato.PALO:
			return "'O gioco d''e tre carte — smontato: sta passanno 'a guardia"
		Stato.MOSTRA:
			return "GUARDA BUONO: 'o rre sta llà"
		Stato.MESCOLA:
			return "Siguela cu ll'uocchie..."
		Stato.SCEGLI:
			return "SCEGLI: [1] · [2] · [3]"
		Stato.ESITO:
			return "..."
	return "'O gioco d''e tre carte — [E] punta €%d (ne pigli €%d)" % [
		PUNTATA, VINCITA]


func player_interact() -> void:
	if _stato == Stato.PALO:
		_say(SAY_PALO)
		return
	if _stato != Stato.FERMO:
		return
	if GameManager.money < PUNTATA:
		SoundManager.play("fail", -8.0, 0.9)
		_say(SAY_SQUATTRINATO)
		return
	if not GameManager.paga(PUNTATA):
		return
	GameManager.add_heat(CALORE)
	SoundManager.play("coin", -4.0)
	_giocate += 1
	_nuova_mano()


func _nuova_mano() -> void:
	_ordine = [0, 1, 2]
	_buona = 0
	_scelta = -1
	_scambi_fatti = 0
	_riposiziona(true)
	_mostra_facce(true)
	_stato = Stato.MOSTRA
	_t = DURATA_MOSTRA
	_say("Ecco 'o rre. Guardatillo buono!")


# ---------------------------------------------------------------------------
# Il ciclo del gioco
# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_controlla_palo()
	if _stato == Stato.PALO:
		return

	match _stato:
		Stato.FERMO:
			_richiamo(delta)
		Stato.MOSTRA:
			_t -= delta
			if _t <= 0.0:
				_mostra_facce(false)
				_prossimo_scambio()
				_stato = Stato.MESCOLA
		Stato.MESCOLA:
			_anima_scambio(delta)
		Stato.SCEGLI:
			_leggi_scelta()
		Stato.ESITO:
			_t -= delta
			if _t <= 0.0:
				_mostra_facce(false)
				_riposiziona(true)
				_stato = Stato.FERMO


## Il richiamo del compare: ogni tanto strilla, ma solo se c'è qualcuno a
## portata d'orecchio. Un banco che grida da solo in un vicolo vuoto è
## soltanto un rumore che si ripete.
func _richiamo(delta: float) -> void:
	_richiamo_cd -= delta
	if _richiamo_cd > 0.0:
		return
	_richiamo_cd = randf_range(9.0, 16.0)
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null or not is_instance_valid(pl):
		return
	if global_position.distance_to(pl.global_position) > 12.0:
		return
	_say(SAY_RICHIAMO[randi() % SAY_RICHIAMO.size()])


func _prossimo_scambio() -> void:
	if _scambi_fatti >= SCAMBI:
		_stato = Stato.SCEGLI
		_say("E mo'… addò sta 'o rre?")
		return
	_scambio_da = randi() % 3
	_scambio_a = (_scambio_da + 1 + (randi() % 2)) % 3
	# Gli scambi accelerano: il primo si segue benissimo, l'ultimo quasi no.
	var f: float = float(_scambi_fatti) / float(SCAMBI - 1)
	_scambio_durata = lerpf(DURATA_SCAMBIO_DA, DURATA_SCAMBIO_A, f)
	_scambio_t = 0.0
	_scambi_fatti += 1


## Le due carte si scambiano di posto passando una sopra l'altra, con un
## arco: senza l'arco si compenetrano e si vede che sono due rettangoli.
func _anima_scambio(delta: float) -> void:
	_scambio_t += delta
	var u: float = clampf(_scambio_t / _scambio_durata, 0.0, 1.0)
	var s: float = smoothstep(0.0, 1.0, u)
	var pa: Vector3 = POSTI[_scambio_da]
	var pb: Vector3 = POSTI[_scambio_a]
	var arco: float = sin(u * PI) * 0.055
	_carte[_ordine[_scambio_da]].position = Vector3(
		lerpf(pa.x, pb.x, s), ALTEZZA_TAVOLO + 0.02 + arco, 0.0)
	_carte[_ordine[_scambio_a]].position = Vector3(
		lerpf(pb.x, pa.x, s), ALTEZZA_TAVOLO + 0.02, 0.0)

	if u < 1.0:
		return
	# Lo scambio è vero anche nei dati, non solo a schermo.
	var t: int = _ordine[_scambio_da]
	_ordine[_scambio_da] = _ordine[_scambio_a]
	_ordine[_scambio_a] = t
	_riposiziona(false)
	SoundManager.play("pop", -18.0, randf_range(1.3, 1.7))
	_prossimo_scambio()


func _leggi_scelta() -> void:
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null or pl.get("current_target") != self:
		return
	var scelta := -1
	if Input.is_action_just_pressed("buy_1"):
		scelta = 0
	elif Input.is_action_just_pressed("buy_2"):
		scelta = 1
	elif Input.is_action_just_pressed("buy_3"):
		scelta = 2
	if scelta < 0:
		return
	_scelta = scelta
	_risolvi()


func _risolvi() -> void:
	# Dove sta davvero la carta buona dopo tutti gli scambi.
	var posto_buono: int = _ordine.find(_buona)
	var indovinato: bool = (_scelta == posto_buono)

	# La prima partita si vince sempre: è l'aggancio.
	var prima: bool = _giocate <= 1
	var barato: bool = false
	if indovinato and not prima and randf() < PROB_TRUCCO:
		# Il compare fa sparire 'o rre nel palmo e lo rimette altrove.
		# Nei dati vuol dire: la carta buona diventa un'altra, e quella che
		# si scopre sotto il dito del giocatore è una perdente vera.
		var altro: int = (_scelta + 1 + (randi() % 2)) % 3
		var t: int = _ordine[_scelta]
		_ordine[_scelta] = _ordine[altro]
		_ordine[altro] = t
		barato = true
		indovinato = false

	if not indovinato and prima:
		# Al primo giro, se hai sbagliato tu, ti aiuta lui: sposta la buona
		# sotto al dito tuo. Serve a farti capire che si può vincere.
		var q: int = _ordine.find(_buona)
		var t2: int = _ordine[_scelta]
		_ordine[_scelta] = _ordine[q]
		_ordine[q] = t2
		indovinato = true

	_riposiziona(false)
	_mostra_facce(true)

	if indovinato:
		_vinte += 1
		GameManager.add_money(VINCITA)
		SoundManager.play("success", -4.0, 1.1)
		_say(SAY_VINTO[randi() % SAY_VINTO.size()])
		GameManager.event_started.emit("HÊ 'NDUVINATO! +€%d" % VINCITA)
	else:
		SoundManager.play("fail", -6.0, 0.85)
		_say(SAY_PERSO[randi() % SAY_PERSO.size()] if not barato
			else "Ah, chesta? Chesta nun era 'o rre...")
	_stato = Stato.ESITO
	_t = DURATA_ESITO


# ---------------------------------------------------------------------------
# Appoggio
# ---------------------------------------------------------------------------

## Rimette ogni carta al suo posto secondo `_ordine`. Con `subito` a falso
## si limita a riallineare dopo uno scambio.
func _riposiziona(_subito: bool) -> void:
	for posto in range(3):
		var c: Node3D = _carte[_ordine[posto]]
		c.position = Vector3(POSTI[posto].x, ALTEZZA_TAVOLO + 0.02, 0.0)


## Girare le carte: la faccia è il primo figlio, il retro il secondo, e uno
## dei due si nasconde. Non c'è una vera rotazione perché una carta di
## spessore zero che ruota su sé stessa sparisce per un fotogramma.
func _mostra_facce(scoperte: bool) -> void:
	for c in _carte:
		c.get_child(0).visible = scoperte
		c.get_child(1).visible = not scoperte


## Se passa un vigile il banco si smonta. Il tavolo sprofonda e le carte
## spariscono: due secondi e non c'è mai stato niente.
func _controlla_palo() -> void:
	var vicino := false
	for v in get_tree().get_nodes_in_group("vigili"):
		if not is_instance_valid(v):
			continue
		if global_position.distance_to(v.global_position) < PALO_RAGGIO:
			vicino = true
			break
	if vicino and _stato != Stato.PALO:
		if _stato == Stato.MOSTRA or _stato == Stato.MESCOLA \
				or _stato == Stato.SCEGLI:
			# Se ti aveva già preso i soldi te li ridà: fa parte del
			# personaggio, e a livello di gioco non si può perdere una
			# puntata per colpa di un vigile che passava di là.
			GameManager.add_money(PUNTATA)
		_stato = Stato.PALO
		_say(SAY_PALO)
		SoundManager.play("fail", -10.0, 1.4)
	elif not vicino and _stato == Stato.PALO:
		_stato = Stato.FERMO
		_richiamo_cd = 1.5
		_riposiziona(true)
		_mostra_facce(false)
	if _banco:
		# Il banco scende sotto terra invece di sparire di colpo: sparire di
		# colpo si nota, scendere in mezzo secondo sembra che l'abbia
		# raccolto.
		var giu: float = -1.2 if _stato == Stato.PALO else 0.0
		_banco.position.y = move_toward(_banco.position.y, giu,
			get_physics_process_delta_time() * 3.0)


func _say(t: String) -> void:
	if _bubble:
		_bubble.say(t, 2.6)
