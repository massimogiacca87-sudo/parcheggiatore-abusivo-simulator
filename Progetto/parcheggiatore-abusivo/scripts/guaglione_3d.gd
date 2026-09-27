extends CharacterBody3D
## Guaglione3D — chi posteggia al posto tuo
##
## ## Il problema
##
## Comprata la seconda piazza, il gioco ti chiedeva di stare in due posti
## insieme. Le auto arrivavano al mercato mentre tu stavi allo stadio, e la
## piazza che avevi pagato quattrocentocinquanta euro lavorava a vuoto: piu'
## ne compravi, piu' la partita diventava una corsa avanti e indietro fra
## quartieri, e meno ognuna rendeva. La conquista puniva chi la faceva.
##
## ## La risposta
##
## Un guaglione per piazza. Gli dai il posto, lui posteggia, tu vai a fare
## altro — e la sera passi a ritirare.
##
## Tre cose lo tengono onesto, cioe' impediscono che diventi "vinci da solo":
##
## 1. **Costa.** Settanta euro per convincerlo, quaranta ogni sera. Se una
##    sera non li hai, se ne vanno tutti: non si accumula debito.
## 2. **Rende meno di te.** Prende il 72% di quello che prenderesti tu. Un
##    padrone che sta al posto suo si fa pagare meglio di un dipendente, e
##    questo e' il motivo per cui conviene comunque lavorare una piazza di
##    persona invece di comprarsi il quartiere e guardare.
## 3. **I soldi non ti arrivano da soli.** Stanno in tasca a lui finche' non
##    passi a ritirarli. Quello che resta la' la sera, se lo tiene per un
##    quarto. E' quel quarto che rende il giro serale una scelta.
##
## ## Dove sta
##
## Uno per zona, in piedi in un angolo, con un cartello di cartone.
## Finche' non lo assumi non fa niente: aspetta. Assunto, cammina in tondo
## per la piazza e ogni tanto lo senti tintinnare — che e' lo stesso suono
## dei rivali, e vuol dire la stessa cosa: quel posto sta rendendo.

const Human := preload("res://scripts/human_builder.gd")
const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const Tex := preload("res://scripts/textures.gd")
const Passo := preload("res://scripts/passo.gd")

const LAYER_WORLD := 1
## Quando passeggia o se ne torna al posto suo.
const VELOCITA: float = 1.6
## **Quando va a pigliare 'na machina, corre** (0.61). Un metro e mezzo al
## secondo per attraversare un piazzale di sessanta metri erano quaranta
## secondi: il cliente se ne andava prima che arrivasse.
const VELOCITA_CORSA: float = 3.6
## Oltre questa distanza dal giocatore nessuno lo guarda: può fare le cose
## con meno cerimonie (vedi `_lavora`).
const FORE_VISTA: float = 45.0

const SALUTI := [
	"Guagliò, tiene bisogno 'e n'aiuto?",
	"Sto ccà 'a stammatina ca nun faccio niente.",
	"Damme 'na mano ca te dongo 'na mano.",
]
const ASSUNTO := [
	"Nun te preoccupà, ce penso io.",
	"'A piazza toja è 'nfaccia a me.",
	"Vattenne tranquillo, ce sto io.",
]
const RITIRO := [
	"Tutt'appost'. Chesti so'.",
	"Cuntà nun serve, so' tutte.",
	"Bella jurnata, ne'.",
]
const NIENTE := [
	"Ancora niente, guagliò. Damme tiempo.",
	"Mo' se movono, mo' se movono.",
]

var zona_id: String = ""
var nome_zona: String = ""
var zona_min: Vector3 = Vector3.ZERO
var zona_max: Vector3 = Vector3.ZERO

var _visual: Node3D
var _anim: Node = null
var _bubble: Node3D
var _targhetta: Label3D
var _cartello: Node3D
var _giro: Array = []
var _giro_idx: int = 0
var _attesa: float = 0.0
var _detto: float = 0.0
var _posto: Vector3 = Vector3.ZERO


func _ready() -> void:
	add_to_group("guagliuni")
	# Stesso strato dei rivali: il raggio dell'interazione lo becca, e il
	# player non ci cammina dentro.
	collision_layer = 4
	collision_mask = 1
	_build_visual()
	_build_collision()
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 2.2, 0)
	add_child(_bubble)
	GameManager.dipendenti_cambiati.connect(_aggiorna_cartello)
	_aggiorna_cartello()


func configura(id: String, nome_della_zona: String, dal: Vector3,
		al: Vector3) -> void:
	zona_id = id
	nome_zona = nome_della_zona
	zona_min = dal
	zona_max = al
	_posto = global_position
	var m := 6.0
	_giro = [
		Vector3(zona_min.x + m, 0.0, zona_min.z + m),
		Vector3(zona_max.x - m, 0.0, zona_min.z + m),
		Vector3(zona_max.x - m, 0.0, zona_max.z - m),
		Vector3(zona_min.x + m, 0.0, zona_max.z - m),
	]
	_aggiorna_cartello()


func _nome() -> String:
	var d: Dictionary = GameManager.dipendente(zona_id)
	return str(d.get("nome", "'O guaglione"))


func assunto() -> bool:
	return GameManager.ha_dipendente(zona_id)


# ---------------------------------------------------------------------------
# Aspetto
# ---------------------------------------------------------------------------

func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	var parts := Human.build(Color(0.86, 0.84, 0.78), Color(0.22, 0.24, 0.3),
		"guaglione_" + zona_id, 1.74, {"belly": 0.15, "moustache": false})
	_visual.add_child(parts["root"])
	_anim = parts.get("anim", null)

	_targhetta = Label3D.new()
	_targhetta.position = Vector3(0, 2.02, 0)
	_targhetta.font_size = 44
	_targhetta.pixel_size = 0.0032
	_targhetta.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_targhetta.modulate = Color(1.0, 0.88, 0.45)
	_targhetta.outline_size = 10
	add_child(_targhetta)

	# Il cartello di cartone: c'e' solo finche' cerca lavoro. E' il modo di
	# farsi vedere da lontano — un uomo in piedi in una piazza non dice
	# niente, un uomo con un cartello si nota dall'altro capo della strada.
	_cartello = Node3D.new()
	add_child(_cartello)
	var pezzo := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.62, 0.44, 0.03)
	pezzo.mesh = bm
	pezzo.position = Vector3(0.34, 1.02, 0.24)
	pezzo.rotation = Vector3(deg_to_rad(-14), deg_to_rad(-18), 0)
	pezzo.material_override = Tex.flat(Color(0.78, 0.68, 0.48), 0.95)
	_cartello.add_child(pezzo)
	var scritta := Label3D.new()
	scritta.text = "CERCO\nFATICA"
	scritta.font_size = 40
	scritta.pixel_size = 0.0026
	scritta.position = Vector3(0.34, 1.02, 0.27)
	scritta.rotation = Vector3(deg_to_rad(-14), deg_to_rad(-18), 0)
	scritta.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	scritta.modulate = Color(0.15, 0.12, 0.1)
	_cartello.add_child(scritta)


func _build_collision() -> void:
	var f := CollisionShape3D.new()
	var c := CapsuleShape3D.new()
	c.radius = 0.34
	c.height = 1.7
	f.shape = c
	f.position = Vector3(0, 0.85, 0)
	add_child(f)


func _aggiorna_cartello() -> void:
	if _cartello:
		_cartello.visible = not assunto()
	if _targhetta == null:
		return
	if assunto():
		var cassa: int = int(GameManager.dipendente(zona_id).get("cassa", 0))
		_targhetta.text = "%s  ·  €%d" % [_nome(), cassa]
		_targhetta.modulate = Color(0.6, 1.0, 0.6) if cassa > 0 \
			else Color(1.0, 0.88, 0.45)
	else:
		_targhetta.text = "cerca fatica"
		_targhetta.modulate = Color(0.85, 0.85, 0.85)


# ---------------------------------------------------------------------------
# 'O lavoro vero: va a piglià 'a machina e 'a posteggia
# ---------------------------------------------------------------------------
#
# **Prima non guidava.** L'incasso saliva da solo — un rubinetto dentro a
# `posteggio_3d.gd` che ogni sei-undici secondi trasformava un'auto in
# attesa in un'auto "parcheggiata", senza che quella si spostasse di un
# centimetro e senza che il guaglione si muovesse dalla ronda sua. Il
# giudizio del capo, alla prova: *"fai funzionare bene i ragazzi che si
# possono assumere: deve davvero guidare le auto"*. Aveva ragione — la
# piazza si riempiva di macchine ferme in mezzo alla strada con su scritto
# "parcheggiata".
#
# Adesso la faccenda ha quattro tempi, e si vedono tutti:
#
#   FERMO      sta al posto suo o gira 'a piazza
#   VERSO_AUTO cammina fino alla macchina in coda
#   A_BORDO    sparisce dentro all'abitacolo e 'a machina se ne va sola
#   TORNA      riappare accanto al posto e se ne torna indietro
#
# Il pezzo di guida sta dentro all'auto (`guagliuno_sale`), che è l'unica
# che sa manovrare. Qui c'è solo chi ci sale.

enum Fase { FERMO, VERSO_AUTO, A_BORDO, TORNA }

## Ogni quanto si guarda intorno per vedere se c'è una macchina da fare.
const CERCA_OGNI: float = 1.4
## Da quanto vicino ci sale.
const SALE_A: float = 2.6
## Se dopo tanto non è riuscito ad arrivarci, lascia perdere: una macchina
## dietro a un muro non deve inchiodare il guaglione per tutta la giornata.
const PAZIENZA: float = 22.0

var _fase: int = Fase.FERMO
var _auto: Node3D = null
var _cerca: float = 0.0
var _da_quanto: float = 0.0


## La macchina più vicina, in coda, dentro alla piazza sua.
func _machina_da_fa() -> Node3D:
	var meglio: Node3D = null
	var d_min: float = 1e9
	for c in get_tree().get_nodes_in_group("cars"):
		if not is_instance_valid(c) or not (c is Node3D):
			continue
		# 1 = State.WAITING: sta ferma in coda e aspetta qualcuno.
		if int(c.get("state")) != 1:
			continue
		if not c.has_method("guagliuno_sale"):
			continue
		# **'E machine d''o Rre so' d''o capo** (0.64). La sfida è tua: il
		# guaglione guarda e fa il tifo, non te le posteggia lui.
		if c.get("sfida") == true:
			continue
		# **Senza posto libero nun ce se va** (0.61): al mercato, coi quattro
		# posti pieni, correva alla macchina, non trovava posto, tornava
		# indietro e ripartiva — sessanta volte in quattro minuti.
		if c.has_method("_any_free_spot") and not bool(c.call("_any_free_spot")):
			continue
		var p: Vector3 = (c as Node3D).global_position
		if p.x < zona_min.x or p.x > zona_max.x \
				or p.z < zona_min.z or p.z > zona_max.z:
			continue
		var d: float = global_position.distance_to(p)
		if d < d_min:
			d_min = d
			meglio = c as Node3D
	return meglio


func _lavora(delta: float) -> bool:
	match _fase:
		Fase.FERMO:
			_cerca -= delta
			if _cerca > 0.0:
				return false
			_cerca = CERCA_OGNI
			var c := _machina_da_fa()
			if c == null:
				return false
			_auto = c
			_fase = Fase.VERSO_AUTO
			_da_quanto = 0.0
			_ntuppato = 0.0
			_d_meglio = 1e9
			if randf() < 0.4:
				_di(ARRIVO[randi() % ARRIVO.size()], 1.6)
			return true
		Fase.VERSO_AUTO:
			_da_quanto += delta
			if _auto == null or not is_instance_valid(_auto) \
					or int(_auto.get("state")) != 1 or _da_quanto > PAZIENZA:
				_auto = null
				_fase = Fase.FERMO
				_cerca = 0.4
				return true
			# «Arrivo, arrivo!»: finché corre verso di lei, il cliente non
			# si spazientisce.
			if _auto.has_method("guagliuno_arriva"):
				_auto.call("guagliuno_arriva")
			var meta: Vector3 = _auto.global_position
			var d: float = _piatto(global_position).distance_to(_piatto(meta))
			# **'Ntuppato.** Se per tre secondi non si avvicina di mezzo
			# metro — una bancarella, un'auto ferma di traverso, un angolo
			# che il passo non sa girare — fa il giro largo: riappare di
			# fianco alla macchina. Da lontano sempre, da vicino solo dopo
			# un po' di più: chi guarda lo deve vedere provarci.
			if d < _d_meglio - 0.5:
				_d_meglio = d
				_ntuppato = 0.0
			else:
				_ntuppato += delta
			var soglia: float = 3.0 if _lontano_d_o_giocatore() else 6.0
			if _ntuppato > soglia:
				_ntuppato = 0.0
				_d_meglio = 1e9
				var fianco: Vector3 = meta + (_auto as Node3D).global_transform.basis.x * 1.8
				fianco = Passo.fore(fianco)
				fianco.y = global_position.y
				global_position = fianco
				d = _piatto(global_position).distance_to(_piatto(meta))
			if d < SALE_A:
				if _auto.call("guagliuno_sale", zona_id):
					# Sale a bordo: da qui in poi il guaglione non si vede,
					# perché sta dentro alla macchina.
					_visual.visible = false
					if _cartello != null:
						_cartello.visible = false
					_targhetta.visible = false
					# **Dint'â machina nun tene cuorpo** (0.61): la capsula
					# appiccicata al centro dell'auto la spingeva in aria
					# (una macchina posteggiata a sette metri d'altezza).
					collision_layer = 0
					_fase = Fase.A_BORDO
					_da_quanto = 0.0
				else:
					_auto = null
					_fase = Fase.TORNA
					_da_quanto = 0.0
				return true
			var v: float = VELOCITA_CORSA
			if _lontano_d_o_giocatore():
				v *= 1.6
			_cammina_verso(meta, delta, v)
			return true
		Fase.A_BORDO:
			_da_quanto += delta
			velocity.x = 0.0
			velocity.z = 0.0
			# Resta appiccicato alla macchina: se il giocatore guarda, deve
			# vedere che quella si muove **con lui dentro**, non un guaglione
			# rimasto per strada.
			if _auto != null and is_instance_valid(_auto):
				global_position = _auto.global_position
				# 2 = State.DIRECTING: sta ancora manovrando.
				if int(_auto.get("state")) == 2 and _da_quanto < 25.0:
					return true
			_scinne()
			return true
		Fase.TORNA:
			# Prima di tornare al posto suo guarda se c'è un'altra macchina:
			# (0.61) prima faceva tutta la strada all'indietro e poi tutta
			# quella in avanti per la macchina accanto a dove stava.
			_cerca -= delta
			if _cerca <= 0.0:
				_cerca = CERCA_OGNI
				if _machina_da_fa() != null:
					_fase = Fase.FERMO
					_cerca = 0.0
					return true
			if _piatto(global_position).distance_to(_piatto(_posto)) < 1.2:
				_fase = Fase.FERMO
				_cerca = CERCA_OGNI
				return false
			_da_quanto += delta
			if _da_quanto > PAZIENZA * 1.5:
				# Non ci arriva: si rimette al posto suo e basta.
				global_position = _posto
				_fase = Fase.FERMO
				return false
			_cammina_verso(_posto, delta, VELOCITA * (1.6 if _lontano_d_o_giocatore() else 1.0))
			return true
	return false


const ARRIVO := [
	"Arrivo, arrivo!", "Ferma, dotto', ce penso io!", "Mo' vengo!",
	"Nun ve movite, ca ve 'a metto io!",
]

var _ntuppato: float = 0.0
var _d_meglio: float = 1e9


func _piatto(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


func _lontano_d_o_giocatore() -> bool:
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null or not (pl is Node3D):
		return true
	return global_position.distance_to((pl as Node3D).global_position) > FORE_VISTA


## Scende dalla macchina: riappare di fianco a quella e cerca la prossima.
func _scinne() -> void:
	if _auto != null and is_instance_valid(_auto):
		var fianco: Vector3 = _auto.global_position \
			+ _auto.global_transform.basis.x * 1.5
		fianco = Passo.fore(fianco)
		fianco.y = _auto.global_position.y + 0.2
		global_position = fianco
	_auto = null
	collision_layer = 4
	_visual.visible = true
	_targhetta.visible = true
	_aggiorna_cartello()
	_fase = Fase.TORNA
	_cerca = 0.3
	_da_quanto = 0.0


## **Cammina cu 'o passo d''a città** (0.61). Prima andava dritto con la
## velocità e `move_and_slide`, e i muri li conosceva solo il motore
## fisico: una panchina o l'angolo di un palazzo lo fermavano sul posto
## finché non scadeva la pazienza. Adesso usa lo stesso passo di tutti gli
## altri che camminano (`Passo.verso`): conosce palazzi e cose e sa girarci
## intorno.
func _cammina_verso(meta: Vector3, delta: float, v: float = VELOCITA) -> void:
	var prima: Vector3 = global_position
	var nuova: Vector3 = Passo.verso(self, meta, v * delta)
	nuova.y = global_position.y
	global_position = nuova
	velocity.x = 0.0
	velocity.z = 0.0
	var dir: Vector3 = nuova - prima
	dir.y = 0.0
	if dir.length() > 0.001:
		dir = dir.normalized()
		# forward(θ) = (−sinθ, 0, −cosθ)
		_visual.rotation.y = lerp_angle(_visual.rotation.y,
			atan2(-dir.x, -dir.z), 1.0 - exp(-9.6 * delta))
	if _anim != null and _anim.has_method("set_speed"):
		_anim.call("set_speed", v)


# ---------------------------------------------------------------------------
# Il giro
# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_detto = maxf(0.0, _detto - delta)
	# **'A parlata se chiude 'a sola.** Stesso guasto che aveva il vigile:
	# uno apre il menu, si allontana senza premere niente, e i tasti 1-4
	# restano mangiati dall'interfaccia per tutta la giornata — cioe' non
	# si compra piu' niente in nessun negozio.
	if _parlando:
		var chi := get_tree().get_first_node_in_group("player")
		if chi == null or not (chi is Node3D) \
				or global_position.distance_to(
					(chi as Node3D).global_position) > 6.0:
			_chiude_parlata()
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	else:
		velocity.y = 0.0
	velocity.x = 0.0
	velocity.z = 0.0

	if not assunto():
		# Aspetta in piedi dove sta, girato verso il centro della piazza.
		move_and_slide()
		_forse_saluta()
		return

	# **'A sera se ferma** (0.61). Quando la giornata è finita (le quattro:
	# non arriva più nessuno) smette, torna al posto suo e ti aspetta coi
	# soldi in mano. È il giro serale del capo: *«ogni sera passi e ritiri
	# la tua parte»* — e per ritirarla bisogna sapere dove trovarlo.
	if GameManager.giornata_scaduta and _fase == Fase.FERMO:
		if _piatto(global_position).distance_to(_piatto(_posto)) > 1.2:
			_cammina_verso(_posto, delta, VELOCITA * 1.3)
		elif _anim != null and _anim.has_method("set_speed"):
			_anim.call("set_speed", 0.0)
		move_and_slide()
		_chiamma_p_a_cassa()
		return

	# **Prima 'a fatica, po' 'a passiata.** Se c'è una macchina da posteggiare
	# quella viene prima di tutto.
	if _lavora(delta):
		move_and_slide()
		return

	# Niente da fare: sta al posto suo, col cartello della cassa, e ogni
	# tanto fa due passi lì attorno. **Al posto suo**, non in giro per la
	# piazza (fino alla 0.60 faceva la ronda dei quattro angoli, e la sera
	# bisognava cercarlo).
	if _attesa > 0.0:
		_attesa -= delta
		move_and_slide()
		if _anim != null and _anim.has_method("set_speed"):
			_anim.call("set_speed", 0.0)
		_chiamma_p_a_cassa()
		return
	var meta: Vector3 = _posto + _giro_vicino[_giro_idx % _giro_vicino.size()]
	if _piatto(global_position).distance_to(_piatto(meta)) < 0.8:
		_giro_idx += 1
		_attesa = randf_range(4.0, 9.0)
		move_and_slide()
		return
	_cammina_verso(meta, delta, VELOCITA * 0.8)
	move_and_slide()


const _giro_vicino := [Vector3.ZERO, Vector3(2.2, 0, 0.8), Vector3.ZERO,
	Vector3(-1.4, 0, 2.0)]


## Quando ha soldi in mano e tu gli passi vicino, te lo dice lui.
func _chiamma_p_a_cassa() -> void:
	if _detto > 0.0:
		return
	var cassa: int = int(GameManager.dipendente(zona_id).get("cassa", 0))
	if cassa <= 0:
		return
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null or not (pl is Node3D):
		return
	var d: float = global_position.distance_to((pl as Node3D).global_position)
	if d > 14.0 or d < 2.0:
		return
	_detto = 18.0
	_di(CHIAMMA[randi() % CHIAMMA.size()] % cassa, 3.0)


const CHIAMMA := [
	"Guagliò! Ccà stanno €%d, viene a piglià 'a parte toja!",
	"Uè, capo! Tengo €%d 'n sacca pe' te!",
	"€%d, tutte cuntate. Passa, ca ce spartimmo.",
]


## Chi cerca lavoro si fa sentire quando gli passi accanto.
func _forse_saluta() -> void:
	if _detto > 0.0:
		return
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null or not (pl is Node3D):
		return
	if global_position.distance_to((pl as Node3D).global_position) > 9.0:
		return
	if not GameManager.zona_mia(zona_id):
		return
	_detto = 14.0
	_di(SALUTI[randi() % SALUTI.size()])


func _di(testo: String, durata: float = 2.6) -> void:
	if _bubble:
		_bubble.say(testo, durata)


# ---------------------------------------------------------------------------
# Interazione
# ---------------------------------------------------------------------------

## **'O parlato.**
##
## Prima si assumeva premendo E una volta sola, senza sapere niente:
## venticinque euro se ne andavano e comparivano due parole in un fumetto.
## Il capo l'ha chiesto esplicitamente — *"ti spiega tutto se ci vai a
## parlare e premendo il dialogo giusto lo puoi assumere"* — ed e' meglio
## cosi': un contratto e' una cosa che si contratta.
##
## Le prime due risposte non chiudono niente: si domanda, lui spiega, il
## menu resta aperto. La terza e' quella che firma. La quarta se ne va.
const DOMANDE := [
	{"text": "Ma tu che ffaje ccà tutt''o juorno?",
		"reply": "Aspetto a uno comm'a te. Io 'e mmacchine 'e ssaccio mettere: nate ccà dinto, 'e ssacc'ammo' 'e mettere dint'ê strisce pure 'e notte."},
	{"text": "E si te piglio, comme facimmo cu 'e sorde?",
		"reply": "Semplice: vincecinche euro mo', pe' me fa' venì. Po' ogni machina ca metto, 'e sorde 'e tengo io. 'A sera passe, m''e chiamme, e te dongo 'o settanta. 'O trenta se resta a me, ca pure i' aggia mangià."},
	{"text": "Vabbuò. Piglia sti venticinq'euro e fatica.", "assume": true},
	{"text": "Nun me serve nisciuno. Statte buono.", "chiude": true},
]

var _parlando: bool = false


func _apri_parlata() -> void:
	_parlando = true
	GameManager.dialogo_con = self
	GameManager.boss_dialogue_opened.emit(_risposte())


func _risposte() -> Array:
	var r: Array = []
	for d in DOMANDE:
		var v: Dictionary = (d as Dictionary).duplicate()
		if bool(v.get("assume", false)):
			if GameManager.money < GameManager.ASSUNZIONE_COSTO:
				v["text"] = "Te pigliasse, ma nun tengo €%d." % \
					GameManager.ASSUNZIONE_COSTO
		r.append(v)
	return r


## La chiama l'interfaccia quando premi 1..4.
func answer(index: int) -> void:
	if not _parlando:
		return
	var lista: Array = _risposte()
	if index < 0 or index >= lista.size():
		return
	var scelta: Dictionary = lista[index]

	if bool(scelta.get("assume", false)):
		_chiude_parlata()
		if GameManager.assumi(zona_id):
			SoundManager.play("kaching", -4.0, 1.0)
			_di(ASSUNTO[randi() % ASSUNTO.size()])
			GameManager.event_started.emit(
				"%s mo' fatica pe' te a %s. 'A sera passa a piglià 'e sorde: se tene 'o 30%%." % [
					_nome(), nome_zona])
		else:
			SoundManager.play("fail", -8.0, 0.9)
			_di("Servono €%d, guagliò. Torna quanno 'e tiene." % \
				GameManager.ASSUNZIONE_COSTO)
		_aggiorna_cartello()
		return

	if bool(scelta.get("chiude", false)):
		_chiude_parlata()
		_di("E vabbuò. Si cagne idea 'o ssaje addò sto.")
		return

	# Domanda: risponde e **resta aperto**. Un menu che si chiude a ogni
	# domanda costringe a rifare il giro per sentire l'altra meta'.
	_di(str(scelta.get("reply", "")), 5.0)
	GameManager.boss_dialogue_opened.emit(_risposte())


func _chiude_parlata() -> void:
	_parlando = false
	if GameManager.dialogo_con == self:
		GameManager.dialogo_con = null
	GameManager.boss_dialogue_closed.emit()


func get_interact_prompt(_da: Vector3) -> String:
	if not GameManager.zona_mia(zona_id):
		return "'A piazza nun è ancora 'a toja: nun 'o può assumere"
	if not assunto():
		return "[E] Parla c''o guaglione (te spiega comme funziona)"
	var cassa: int = int(GameManager.dipendente(zona_id).get("cassa", 0))
	if cassa > 0:
		# **'A quota nun è cchiù fissa (0.55):** scende con l'esperienza,
		# e chiederla al GameManager invece di scrivere il trenta per
		# cento qui è l'unico modo perché il prompt dica la verità.
		var mio: int = maxi(0, cassa - int(round(
			float(cassa) * GameManager.quota_guagliuno(zona_id))))
		return "[E] Piglia 'a parte toia 'a %s: €%d 'e €%d%s  ·  [F] mannalo 'a casa" % [
			_nome(), mio, cassa, _comme_sta()]
	return "%s sta faticanno. Ancora nun ha 'ncassato niente.%s  ·  [F] mannalo 'a casa" \
		% [_nome(), _comme_sta()]


## **Comme sta, e 'a quant''è ca fatica pe' te.**
##
## Due mezze frasi, e tutte e due servono a una cosa sola: che il
## giocatore **veda** che questo non è un distributore. L'esperienza si
## dice solo quando è cresciuta abbastanza da valere qualcosa; l'umore
## solo quando è basso — perché è l'unico momento in cui c'è qualcosa da
## fare, cioè passare a ritirare.
func _comme_sta() -> String:
	var pezze: Array = []
	var esp: float = GameManager.guagliuno_esperienza(zona_id)
	if esp >= 0.99:
		pezze.append("canosce 'a piazza meglio 'e te")
	elif esp > 0.35:
		pezze.append("s'è fatto pratico")
	var um: float = GameManager.umore_guagliuno(zona_id)
	if um <= GameManager.GUAGLIUNO_SE_NE_VA + 6.0:
		pezze.append("STA P''ASCÌ PAZZO: si nun passe, dimane nun 'o truove")
	elif um <= GameManager.GUAGLIUNO_BRONTOLA:
		pezze.append("nun è cuntento")
	if pezze.is_empty():
		return ""
	return "  (%s)" % " · ".join(pezze)


func player_interact() -> void:
	if not GameManager.zona_mia(zona_id):
		_di("Ccà nun cummanne tu, guagliò.")
		return
	if not assunto():
		_apri_parlata()
		return
	var preso: int = GameManager.ritira_cassa(zona_id)
	if preso > 0:
		SoundManager.play("coin", -3.0, 1.05)
		_di(RITIRO[randi() % RITIRO.size()])
		GameManager.event_started.emit(
			"Ritirati €%d 'a %s (isso s'è tenuto 'o 30%%)." % [preso, _nome()])
	else:
		_di(NIENTE[randi() % NIENTE.size()])
	_aggiorna_cartello()


## **[F] 'o mmanne 'a casa.**
##
## `GameManager.licenzia()` stava scritta, funzionante e commentata — *"e'
## un licenziamento, non una rapina"* — e **non la chiamava nessuno**: una
## volta assunto un guaglione te lo tenevi per sempre, anche se la piazza
## non rendeva più abbastanza per pagargli il trenta per cento.
##
## Due pressioni: la prima avvisa, la seconda manda. Un licenziamento su un
## tasto solo, accanto a "piglia 'a parte toia", si fa per sbaglio.
var _avvisato: float = 0.0


func player_vandalize() -> void:
	if not GameManager.zona_mia(zona_id) or not assunto():
		return
	var ora: float = float(Time.get_ticks_msec()) * 0.001
	if ora > _avvisato:
		_avvisato = ora + 4.0
		_di("Comme? Me staje mannanno? Schiaccia n'ata vota si è overo.")
		GameManager.event_started.emit(
			"[F] n'ata vota pe' mannà 'a casa a %s." % _nome())
		return
	_avvisato = 0.0
	var cassa: int = int(GameManager.dipendente(zona_id).get("cassa", 0))
	_di("E vabbuo'. Aggio capito.")
	GameManager.licenzia(zona_id)
	SoundManager.play("fail", -9.0, 0.95)
	GameManager.event_started.emit(
		"Hê mannato 'a casa a %s. %s" % [_nome(),
			("T'ha lassato €%d ca teneva 'n mano." % cassa) if cassa > 0
			else "Nun teneva niente 'n mano."])
