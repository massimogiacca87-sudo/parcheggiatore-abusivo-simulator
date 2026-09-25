extends CharacterBody3D
## Vigile3D
## Il vigile urbano pattuglia tra alcuni punti. Si insospettisce solo se ti
## sta guardando davvero: devi essere entro il suo cono visivo frontale, a
## distanza utile e senza muri di mezzo. Alle spalle o dietro un angolo sei
## al sicuro. A sospetto massimo parte l'inseguimento — e se ti prende TI
## ARRESTA: cauzione e fine turno. Prenderlo a pugni è oltraggio a pubblico
## ufficiale: sospetto al massimo all'istante e inseguimento furioso.

const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const Human := preload("res://scripts/human_builder.gd")
const Tex := preload("res://scripts/textures.gd")
const KO := preload("res://scripts/knockout.gd")

const LAYER_WORLD := 1

const PATROL_SPEED: float = 2.9
const CHASE_SPEED: float = 5.6
## Il vigile guarda più lontano e più largo di prima: nella piazza nuova
## (34×54 m) con 9 m di vista e 55° di cono non ti vedeva praticamente mai.
## Da quindici a venti metri: la piazza e' 34 per 54, e con quindici metri
## il vigile ne teneva d'occhio meno di un quarto. Misurato: ti vedeva
## davvero il 7,8% del tempo.
const SIGHT_RADIUS: float = 20.0
const FOV_HALF_ANGLE_DEG: float = 72.0
## E ogni tanto si volta a guardarsi intorno, anche se cammina dritto: è
## la cosa che lo rende davvero fastidioso.
const SCAN_PERIOD: float = 5.5      # quanto dura un giro d'occhiate completo
const SCAN_HALF_ANGLE_DEG: float = 42.0
const CATCH_RADIUS: float = 1.5
const CHASE_COOLDOWN: float = 3.0
const LOSE_SIGHT_TIME: float = 5.5

# --- Le mani addosso ---
## Prima di portarti in guardina te ne dà un paio. Se sei già malmesso,
## il pestaggio del vigile è quello che ti manda all'ospedale.
const BEAT_HITS: int = 2
const BEAT_DAMAGE: float = 14.0
const BEAT_INTERVAL: float = 0.55
const SAY_BEAT := ["FERMO!", "STATTE FERMO!", "E MO' VIENI CU' MMÈ!"]

# --- Quanto regge, e cosa succede quando non regge più ---
## Il vigile NON si stende come gli altri: ha troppi punti perché ci si
## riesca prima che chiami i rinforzi. È il muro contro cui si scopre che
## menare tutti non è una strategia.
const MAX_HP: int = 22
## A quanti pugni presi prende la radio. Molto prima di finire i punti.
const RADIO_AT_HITS: int = 4
const SAY_RADIO := ["CENTRALE! CENTRALE! AGGRESSIONE!",
	"MO' CHIAMMO 'E CARABINIERI!", "UNITÀ IN PIAZZA, SUBITO!"]
const SAY_TAKE_HIT := ["MA CHE FAI?!", "PUBBLICO UFFICIALE!", "TE COSTA CARO!"]

# --- 'A ronda: chiacchiere e cafe' ------------------------------------
##
## **Il vigile non e' un radar: e' uno che fa il suo turno.**
##
## Prima camminava avanti e indietro senza fermarsi mai, con il cono visivo
## sempre acceso: l'unico modo di lavorare era stargli dietro le spalle, e
## siccome si guardava intorno anche quello non bastava. Non era un
## avversario, era un metronomo.
##
## Adesso ogni tanto si ferma: o si mette a chiacchierare con qualcuno che
## passa, o va al bar a pigliarsi 'o cafe'. Mentre e' fermo NON guarda —
## e' li' che si lavora. Aspettare che si distragga e' diventata la
## meccanica, invece di girargli attorno.
## **Stava fermo il 42% del tempo.** Fra una chiacchiera e un caffe' era
## cieco quasi per meta' turno, e la "finestra per lavorare" non era una
## finestra: era la regola. Adesso le pause sono piu' rade e piu' corte —
## resta il momento buono, ma bisogna aspettarlo.
const PAUSA_OGNI_MIN: float = 30.0
const PAUSA_OGNI_MAX: float = 52.0
const CHIACCHIERA_DURATA: float = 7.0
const CAFFE_DURATA_VIG: float = 11.0
const DISTRATTO_DURATA: float = 40.0   # quando i guagliuni lo chiamano
const SAY_CAFFE := ["Nu cafè, Gennarì. Ristretto.",
	"Ah, chisto sì ca è cafè.", "Manco 'o tiempo 'e piglià fiato..."]
const SAY_CHIACCHIERE := ["E che ve dico, signò...", "Eh, 'o traffico...",
	"Chillo pure oggi sta llà.", "'A giornata è longa."]

# --- Quando ti viene a parlare ----------------------------------------
## Sopra questa soglia di sospetto smette di guardare e ti viene incontro.
const SOGLIA_PARLA: float = 42.0
const RAGGIO_PARLATA: float = 2.0
const AVVICINA_SPEED: float = 3.6
## Dopo che ti ha creduto, per un po' non ti rompe piu'.
## La risposta che gli fa pieta' compra mezzo minuto, non tre quarti.
const PIETA_DURATA: float = 30.0

## **Le risposte.** Una sola funziona, ed e' quella che funziona davvero
## in strada: mettergli davanti la famiglia. Non azzera il sospetto — lui
## sa benissimo quello che stai facendo — ma ti lascia in pace.
const RISPOSTE := [
	{"text": "Nun è pe' mme, è pp''e ccriature",
	 "reply": "...Va buo'. Ma nun te facesse vedé n'ata vota.", "buona": true},
	{"text": "Sto solo aspettanno a n'amico",
	 "reply": "E chist'amico tene quaranta machine?", "buona": false},
	{"text": "Ma qua' abusivo, songo 'o custode",
	 "reply": "Ah sì? E 'o tesserino addò sta?", "buona": false},
	{"text": "Vattenne, ca me staje facenno perdere tiempo",
	 "reply": "Bravo. Mo' vedimmo chi perde 'o tiempo.", "buona": false},
]

# --- 'O turno: quanno smonta ---------------------------------------------
##
## **«'A sera dopo le 20.00 va via, quindi conviene lavorare di sera.»**
##
## È la richiesta che cambia di più il gioco fra tutte quelle della 0.56, e
## non perché tolga un ostacolo: perché **dà una forma alla giornata**.
## Prima le sedici ore erano tutte uguali — stesso vigile, stesso rischio,
## stessa mancia — e l'unica ragione per restare fuori la sera era la fascia
## oraria delle mance. Adesso alle otto lui stacca, se ne va a casa a piedi
## come chiunque altro, e da lì in poi la piazza è tua: si può lavorare
## sporco, tirare via le multe, fischiare a voce alta.
##
## E in cambio la sera è quando arrivano gli altri — Borrelli, il boss di
## capitolo, i carabinieri se esageri. Non è che il rischio sparisce: cambia
## di mano, e diventa un rischio più grosso e più raro.
##
## Se ti sta inseguendo quando suona l'ora, l'inseguimento lo finisce: uno
## non molla a metà perché è finito il turno.
const ORA_SMONTA: float = 20.0
const SAY_SMONTA := ["Bonasera. Ie pe' oggi aggio fatto.",
	"E mo' basta. 'A famiglia m'aspetta.",
	"Ce vedimmo dimane, guagliò. E statte accuorto."]
## Quanto ci mette a sparire dalla piazza dopo che ha salutato.
const SMONTA_CAMMINA: float = 22.0

# --- Che stai facendo con quella macchina --------------------------------
##
## **«A volte mi passa proprio davanti mentre sto gestendo un'auto e non se
## ne fotte proprio.»**
##
## Aveva ragione ed era un buco vero: tutto il sospetto del gioco nasceva da
## **eventi** — il fischio, lo stemma, la multa stracciata, il pugno — cioè
## da cose che succedono in un istante. Ma il mestiere del parcheggiatore
## abusivo non è un istante: è **stare lì venti secondi a far manovrare uno
## con le braccia**, in mezzo alla strada, davanti a tutti. Quello, che è la
## cosa più vistosa che fai in tutta la giornata, per il vigile non esisteva.
##
## Adesso esiste: finché ti vede dirigere una macchina, il sospetto sale da
## solo, un po' per ogni secondo. Otto punti al secondo non sono tanti —
## servono cinque secondi buoni per fare quanto uno stemma — ma sono
## continui, e cambiano il modo di lavorare: o aspetti che si giri, o ti
## prendi il posto dall'altra parte della piazza, o paghi i guaglioni.
const VEDE_REGIA: float = 8.0
## Quanto lontano dal giocatore deve stare la macchina perché si capisca che
## la stai dirigendo tu.
const REGIA_VICINO: float = 12.0
const SAY_REGIA := ["Ma chi t'ha dato 'o permesso?",
	"Uè! E chi sî, 'o padrone d''a strada?",
	"Te sto guardanno, sa'?", "Chella machina nun è 'a toia."]

enum Stato { RONDA, CHIACCHIERA, CAFFE, DISTRATTO, AVVICINA, PARLA, MULTA,
	SMONTA }

var stato: int = Stato.RONDA
var _t_stato: float = 0.0
var _t_pausa: float = 0.0
var _pieta: float = 0.0
var _meta_pausa: Vector3 = Vector3.ZERO
var _t_caffe: float = 0.0
var _risposto: bool = false

var patrol_points: Array = []
var _patrol_idx: int = 0
var _chasing: bool = false
var _cooldown: float = 0.0
var _lost_sight_timer: float = 0.0
var _visual_root: Node3D
var _walk_phase: float = 0.0
var _legs: Array = []
var _arms: Array = []
var _anim: Node = null
var _bubble: Node3D
var _scan_time: float = 0.0   # oscillazione della testa in pattuglia
var _beat_left: int = 0       # manate ancora da dare prima dell'arresto
var _beat_cd: float = 0.0
var hp: int = MAX_HP
var _hits_taken: int = 0
var _radio_called: bool = false
var _ko: Dictionary = KO.make_state()


func _ready() -> void:
	add_to_group("vigili")
	collision_layer = 4 # come auto e autisti: il raggio di interazione lo becca
	collision_mask = 0
	_build_visual()
	_build_collision()
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 2.3, 0)
	add_child(_bubble)
	# Non si aggancia piu' a `player_caught`: a sospetto pieno adesso il
	# vigile viene a fare la multa (stato MULTA), non a inseguirti. La
	# corsa gli resta solo se gli metti le mani addosso.
	_t_pausa = randf_range(PAUSA_OGNI_MIN, PAUSA_OGNI_MAX)


func _build_collision() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.9
	shape.shape = capsule
	shape.position = Vector3(0, 0.95, 0)
	add_child(shape)


func _say(text: String) -> void:
	if _bubble:
		_bubble.say(text)
	GameManager.directing_gesture.emit(text, true)


func get_interact_prompt(_from_position: Vector3) -> String:
	if _chasing:
		return ""
	return "Chist'è 'o vigile. Miéglio nun te fa' nutà… (o no?)"


## Pugno al vigile: oltraggio a pubblico ufficiale. Pessima idea, e non
## migliora insistendo — è l'unico personaggio che NON si può stendere.
## Ha 14 punti, ma alla quarta manata prende la radio e chiama i carabinieri,
## e da lì non c'è più niente da fare se non scappare dalla piazza.
func receive_punch(danno: int = 1) -> void:
	# **'A reazione, no 'o blocco.** Il colpo si vede addosso (clip
	# `Hit_Chest`/`Hit_Head` sopra alla locomozione) ma non toglie il
	# controllo: vedi `Animator.reagisci_colpo`.
	if _anim != null and _anim.has_method("reagisci_colpo"):
		_anim.reagisci_colpo(randf() < 0.4)
	if _ko["down"]:
		return
	GameManager.register_punch()
	SoundManager.pugno(0.0)
	GameManager.screen_shake.emit(0.6)
	# Il danno dell'arma conta anche qui. Prima era un punto fisso: dare
	# una mazzata di ferro a un vigile faceva lo stesso effetto di uno
	# schiaffo, e le armi comprate a caro prezzo non servivano a niente
	# contro l'unico che te le viene a cercare.
	hp -= maxi(1, danno)
	_hits_taken += 1
	GameManager.nemico_colpito.emit("'O vigile", maxi(0, hp), MAX_HP)

	if _hits_taken == 1:
		_say("OLTRAGGIO A PUBBLICO UFFICIALE!!")
		SoundManager.play("fischio_vigile", 0.0, 1.15)
	else:
		_say(SAY_TAKE_HIT[randi() % SAY_TAKE_HIT.size()])

	GameManager.add_heat(GameManager.HEAT_MAX) # inseguimento immediato
	# Pubblico ufficiale: due manate e hai gia' due stelle addosso.
	GameManager.crimine(2.6)

	# **E adesso ti insegue.**
	#
	# Quando il vigile e' stato rifatto, `player_caught` e' stato scollegato
	# (a sospetto pieno adesso fa la multa, non la corsa) — e con quello se
	# n'e' andata l'ULTIMA chiamata a `_start_chase`. Risultato: gli potevi
	# tirare pugni in faccia e lui restava li' impalato a incassare, magari
	# appoggiato al banco del bar. Un pugno a un pubblico ufficiale lo deve
	# far partire, e lo deve staccare da qualunque cosa stesse facendo.
	if stato != Stato.RONDA:
		stato = Stato.RONDA
		_t_stato = 0.0
		if GameManager.dialogo_con == self:
			GameManager.dialogo_con = null
			GameManager.boss_dialogue_closed.emit()
	if not _chasing:
		_start_chase()

	if _hits_taken >= RADIO_AT_HITS and not _radio_called:
		_call_reinforcements()
	elif hp <= 0:
		# Non dovrebbe succedere (la radio arriva prima), ma se uno ci
		# riesce davvero: cade, e i carabinieri arrivano lo stesso.
		KO.lay_down(_ko, _visual_root, 0.0)
		_chasing = false
		if not _radio_called:
			_call_reinforcements()


## La radio. Da qui in poi il turno è una fuga.
func _call_reinforcements() -> void:
	_radio_called = true
	_say(SAY_RADIO[randi() % SAY_RADIO.size()])
	SoundManager.play("fischio_vigile", 0.0, 0.7)
	GameManager.screen_shake.emit(0.8)
	GameManager.event_started.emit("HA CHIAMMATO 'E CARABINIERI! VATTENNE!")
	GameManager.reinforcements_called.emit()


func setup(points: Array) -> void:
	patrol_points = points
	if patrol_points.size() > 0:
		global_position = patrol_points[0]


func _build_visual() -> void:
	_visual_root = Node3D.new()
	add_child(_visual_root)

	var uniform := Color(0.12, 0.2, 0.42)
	# Pelato: sotto al casco i capelli non si vedono, e una calotta di
	# capelli dentro a un casco esce dai bordi.
	var parts := Human.build(uniform, Color(0.1, 0.15, 0.32), "vigile", 1.85,
		{"moustache": true, "bald": true, "corpo": "normale"})
	_visual_root.add_child(parts["root"])
	_legs = parts["legs"]
	_arms = parts["arms"]
	_anim = parts.get("anim", null)
	# **'O passo d''o vigile.** L'andatura formale della cattura di
	# movimento: busto dritto, passo corto, braccia contenute. Si riconosce
	# da in fondo alla piazza prima di vedere il berretto, ed e' esattamente
	# quello che serve a un personaggio che devi tenere d'occhio.
	if _anim != null and _anim.has_method("imposta_passo"):
		_anim.call_deferred("imposta_passo", "cammina_serio")
	# **Nun se guarda cchiù `legs`.**
	#
	# Qui c'era `if parts["legs"].is_empty(): return`, e il senso era: "se
	# è un modello 3D comprato, niente accessori procedurali sopra". Solo
	# che dalla 0.48 **`legs` è sempre vuoto** — le gambe non sono più
	# nodi separati, le muove l'AnimationTree — quindi la condizione era
	# sempre vera e questa funzione **usciva sempre qui**.
	#
	# Da due versioni il berretto, la visiera, lo stemma, le mostrine, la
	# bandoliera e la paletta non venivano costruiti proprio. È tutto il
	# motivo per cui, come dice il capo, "non sono molto riconoscibili":
	# non era che la divisa fosse brutta, è che non c'era.
	#
	# Il controllo giusto è sulle **ossa**: un modello esterno non ne ha,
	# e senza quelle non c'è dove appendere niente.
	if parts["bones"].is_empty():
		return

	var head_pivot: Node3D = parts["head"]

	# **'O casco janco d''o vigile urbano.**
	#
	# Il berretto c'era già, ma era **blu scuro sopra a una divisa blu
	# scura**: a dieci metri il vigile era una sagoma scura come tutte le
	# altre, e il capo ha ragione a dire che non si riconosce. Il vigile
	# urbano di Napoli d'estate porta il **casco bianco**, ed è quella
	# l'unica cosa che si vede da lontano — prima ancora della divisa,
	# prima della paletta.
	#
	# Bianco sopra, fascia blu sotto, visiera nera, stemma dorato: quattro
	# pezzi, e da in fondo alla piazza si capisce chi è.
	var cap := MeshInstance3D.new()
	var cap_mesh := SphereMesh.new()
	cap_mesh.radius = 0.148
	cap_mesh.height = 0.296
	cap_mesh.radial_segments = 16
	cap_mesh.rings = 8
	cap_mesh.is_hemisphere = true
	cap.mesh = cap_mesh
	cap.position = Vector3(0, 0.140, 0)
	cap.scale = Vector3(1.02, 0.70, 1.06)
	cap.material_override = Tex.flat(Color(0.95, 0.95, 0.93), 0.35, 0.15)
	head_pivot.add_child(cap)

	var fascia := MeshInstance3D.new()
	var fascia_mesh := CylinderMesh.new()
	fascia_mesh.top_radius = 0.152
	fascia_mesh.bottom_radius = 0.154
	fascia_mesh.height = 0.042
	fascia_mesh.radial_segments = 16
	fascia.mesh = fascia_mesh
	fascia.position = Vector3(0, 0.148, 0)
	fascia.scale = Vector3(1.0, 1.0, 1.05)
	fascia.material_override = Tex.flat(Color(0.07, 0.13, 0.34), 0.8)
	head_pivot.add_child(fascia)

	var visor := MeshInstance3D.new()
	var visor_mesh := BoxMesh.new()
	visor_mesh.size = Vector3(0.26, 0.022, 0.13)
	visor.mesh = visor_mesh
	# **'A visiera steva areto â capa.**
	#
	# Dalla 0.51 il casco del vigile aveva la visiera e lo stemma a
	# z negativa, e sull'osso `Head` di questo rig **il davanti è +Z**
	# (misurato in `prova_manella`: +Z → world-forward, 0,97). Cioè per
	# tre versioni il vigile ha girato la piazza con la visiera sulla
	# nuca. Non si nota mai perché il vigile lo si vede quasi sempre di
	# spalle o di tre quarti — e da dietro sembrava giusto.
	visor.position = Vector3(0, 0.140, 0.158)
	visor.rotation.x = deg_to_rad(7.0)
	visor.material_override = Tex.flat(Color(0.05, 0.05, 0.07), 0.4)
	head_pivot.add_child(visor)

	var badge := MeshInstance3D.new()
	var badge_mesh := BoxMesh.new()
	badge_mesh.size = Vector3(0.075, 0.062, 0.02)
	badge.mesh = badge_mesh
	badge.position = Vector3(0, 0.172, 0.148)
	badge.material_override = Tex.flat(Color(0.92, 0.80, 0.26), 0.2, 0.9, 0.4)
	head_pivot.add_child(badge)

	# Bandoliera bianca a tracolla, appesa al torace: adesso che il busto
	# ruota sul passo, se restasse attaccata alla radice resterebbe indietro.
	var chest_bone: Node3D = parts["bones"].get("chest", _visual_root)
	var strap := MeshInstance3D.new()
	var strap_mesh := BoxMesh.new()
	strap_mesh.size = Vector3(0.085, 0.58, 0.32)
	strap.mesh = strap_mesh
	strap.position = Vector3(0.06, -0.1, 0)
	strap.rotation.z = 0.45
	strap.material_override = Tex.flat(Color(0.93, 0.93, 0.9), 0.7)
	chest_bone.add_child(strap)

	# **'E mustrine 'ncopp'ê spalle, no 'ncopp'ê mmane.**
	#
	# Stavano appese a `parts["arms"]`, e dalla 0.48 `arms` **sono le
	# mani**: il vigile girava con due gradi d'oro attaccati ai polsi. Ci
	# è voluto un attacco nuovo (`spalla_l`/`spalla_r`, sull'osso del
	# braccio) perché ci fosse un posto giusto dove metterle.
	for chiave in ["spalla_l", "spalla_r"]:
		var sp: Node3D = parts["bones"].get(chiave, null)
		if sp == null:
			continue
		var epaulette := MeshInstance3D.new()
		var ep_mesh := SphereMesh.new()
		ep_mesh.radius = 0.062
		ep_mesh.height = 0.124
		ep_mesh.radial_segments = 8
		ep_mesh.rings = 4
		epaulette.mesh = ep_mesh
		epaulette.scale = Vector3(1.0, 0.38, 1.0)
		epaulette.material_override = Tex.flat(Color(0.90, 0.80, 0.32),
			0.3, 0.7)
		sp.add_child(epaulette)

	# **Chello ca 'nu vigile porta 'ncuollo** (0.58). Il blocchetto delle
	# multe e la penna sono gli attrezzi del suo mestiere — è con quelli
	# che dalla 0.56 ti scrive il verbale in dodici secondi e mezzo — e la
	# ricetrasmittente è **quella con cui chiama la pattuglia**. Erano tre
	# cose che il gioco faceva e che addosso a lui non si vedevano.
	var cintola: Node3D = parts["bones"].get("chest", _visual_root)
	for e in [
			["blocchetto_multe", Vector3(0.17, -0.22, 0.10), Vector3(0, 0, 74)],
			["penna", Vector3(0.14, -0.10, 0.13), Vector3(0, 0, 8)],
			["ricetrasmittente", Vector3(-0.17, -0.20, 0.09), Vector3(0, 0, -6)],
		]:
		var o := Models.spawn(str(e[0]))
		if o == null:
			continue
		o.position = e[1]
		var g: Vector3 = e[2]
		o.rotation = Vector3(deg_to_rad(g.x), deg_to_rad(g.y), deg_to_rad(g.z))
		cintola.add_child(o)

	# La paletta, appesa alla mano destra
	var paddle_root := Node3D.new()
	paddle_root.position = Vector3(0, -0.12, 0.02)
	var hand_r: Node3D = parts["bones"].get("hand_r", parts["arms"][1])
	hand_r.add_child(paddle_root)

	var handle := MeshInstance3D.new()
	var handle_mesh := CylinderMesh.new()
	handle_mesh.top_radius = 0.015
	handle_mesh.bottom_radius = 0.015
	handle_mesh.height = 0.2
	handle.mesh = handle_mesh
	handle.position = Vector3(0, -0.1, 0)
	handle.material_override = Tex.flat(Color(0.12, 0.12, 0.14), 0.5)
	paddle_root.add_child(handle)

	var disc := MeshInstance3D.new()
	var disc_mesh := CylinderMesh.new()
	disc_mesh.top_radius = 0.085
	disc_mesh.bottom_radius = 0.085
	disc_mesh.height = 0.014
	disc.mesh = disc_mesh
	disc.position = Vector3(0, -0.24, 0)
	disc.material_override = Tex.flat(Color(0.85, 0.12, 0.12), 0.4, 0.0, 0.3)
	paddle_root.add_child(disc)

	# Blocchetto delle multe nel taschino
	var pad := MeshInstance3D.new()
	var pad_mesh := BoxMesh.new()
	pad_mesh.size = Vector3(0.11, 0.15, 0.03)
	pad.mesh = pad_mesh
	pad.position = Vector3(-0.14, 1.06, -0.14)
	pad.material_override = Tex.flat(Color(0.93, 0.9, 0.8), 0.9)
	_visual_root.add_child(pad)


func _get_player() -> Node3D:
	return get_tree().get_first_node_in_group("player")


## Vero se il vigile sta guardando DAVVERO il player in questo istante:
## entro raggio, dentro il cono visivo frontale, e senza muri di mezzo.
## Usato da GameManager per capire se un'azione rischiosa del player viene
## "colta sul fatto".
func can_see_player() -> bool:
	var player := _get_player()
	if player == null:
		return false
	# **Fermo al bar o a chiacchierare, non vede niente.** E' tutta la
	# meccanica: la finestra per lavorare e' quella.
	if stato == Stato.CHIACCHIERA or stato == Stato.CAFFE \
			or stato == Stato.DISTRATTO or _ko["down"]:
		return false
	# E quando ha smontato non guarda più niente: sta tornando a casa.
	if stato == Stato.SMONTA:
		return false

	# **Sotto all'ombrellone non ti vede.**
	#
	# Venticinque euro per tre metri di piazza dove puoi chiedere i soldi,
	# strappare una multa o contare la giornata senza che conti come "colto
	# sul fatto". Non e' invisibilita': e' un posto dove stare mentre lui
	# passa, e sta dove l'hai messo tu — quindi conviene metterlo dove
	# lavori, non dove sta bello.
	if GameManager.sotto_ombrellone(player.global_position):
		return false

	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	if dist > SIGHT_RADIUS or dist < 0.001:
		return false

	var forward: Vector3 = -_visual_root.global_transform.basis.z
	forward.y = 0.0
	if forward.length() < 0.001:
		return false

	var angle_deg: float = rad_to_deg(forward.normalized().angle_to(to_player.normalized()))
	if angle_deg > FOV_HALF_ANGLE_DEG:
		return false

	return _has_line_of_sight(player)


## Vero quando il sospetto e' alto abbastanza da farlo muovere anche senza
## averti in vista. L'ombrellone continua a coprirti: e' quello che ha
## comprato il giocatore, e deve valere.
func _ti_sta_cercanno() -> bool:
	if GameManager.heat < SOGLIA_PARLA:
		return false
	var pl := _get_player()
	if pl == null or _ko["down"]:
		return false
	if stato == Stato.CHIACCHIERA or stato == Stato.CAFFE \
			or stato == Stato.DISTRATTO:
		return false
	if GameManager.sotto_ombrellone(pl.global_position):
		return false
	return global_position.distance_to(pl.global_position) < 25.0


func _physics_process(delta: float) -> void:
	if _ko["down"]:
		KO.tick(_ko, _visual_root, delta)
		return
	if _cooldown > 0.0:
		_cooldown -= delta

	# Il pestaggio prima dell'arresto: qualche secondo in cui le prendi e
	# basta, e se stavi già male finisce in ospedale invece che in guardina.
	if _beat_left > 0:
		_beat_cd -= delta
		if _beat_cd <= 0.0:
			_beat_cd = BEAT_INTERVAL
			_beat_left -= 1
			SoundManager.pugno(-1.0)
			if _anim != null:
				_anim.action("punch")
			GameManager.screen_shake.emit(0.7)
			_say(SAY_BEAT[randi() % SAY_BEAT.size()])
			GameManager.damage_player(BEAT_DAMAGE, "T'ha menato 'o vigile", global_position)
			if _beat_left <= 0:
				_finish_arrest()
		return

	_pieta = maxf(0.0, _pieta - delta)
	_t_stato += delta

	# **'E otto 'e sera smonta** (0.56, punto 9).
	if _smonta(delta):
		return
	# **E fino a che sta 'n servizio, te guarda 'e mane** (0.56, punto 9).
	_che_staje_facenno(delta)

	match stato:
		Stato.CHIACCHIERA:
			_gesticola(delta)
			if _t_stato >= CHIACCHIERA_DURATA:
				_torna_in_ronda()
			return
		Stato.CAFFE:
			# Il tetto duro: se per qualunque motivo non arriva al banco
			# (il bar demolito, un banco in un'altra piazza, una posizione
			# storta), dopo quaranta secondi molla e torna in ronda. Senza,
			# `_t_stato` si azzera a ogni passo e questo stato non finisce
			# mai — cioe' il vigile sparisce dalla partita.
			_t_caffe += delta
			if _t_caffe > 40.0:
				_torna_in_ronda()
				return
			# Ci va, e quando ci arriva ci resta appoggiato.
			if global_position.distance_to(_meta_pausa) > 1.0:
				var pr := global_position
				global_position = Passo.verso(self,
					_meta_pausa, PATROL_SPEED * delta)
				_animate_walk(global_position.distance_to(pr))
				_face_toward(_meta_pausa)
				_t_stato = 0.0
			else:
				_animate_walk(0.0)
				if _t_stato > 1.2 and _t_stato < 1.4:
					_say(SAY_CAFFE[randi() % SAY_CAFFE.size()])
				# Sotto la pioggia il caffe' dura il doppio: nessuno esce
				# dalla tenda finche' non spiove.
				var dura: float = CAFFE_DURATA_VIG
				if GameManager.tipo_giornata == "pioggia":
					dura *= 2.4
				if _t_stato >= dura:
					_torna_in_ronda()
			return
		Stato.DISTRATTO:
			_gesticola(delta)
			if _t_stato >= DISTRATTO_DURATA:
				_torna_in_ronda()
			return
		Stato.AVVICINA:
			_avvicinati(delta)
			return
		Stato.PARLA:
			_animate_walk(0.0)
			var p2 := _get_player()
			if p2 != null:
				_face_toward(p2.global_position)
			# **Il dialogo non puo' restare aperto per sempre.**
			#
			# Se il giocatore non risponde — apre la mappa, va in pausa, o
			# semplicemente se ne va — il vigile restava piantato in questo
			# stato e il pannello delle risposte non si chiudeva piu'. E
			# siccome quel pannello si mangia i tasti da 1 a 4, da li' in
			# poi non si poteva piu' comprare niente in nessun negozio.
			# Venti secondi, o venti metri, e la chiude lui.
			var lontano: bool = p2 != null \
				and global_position.distance_to(p2.global_position) > 20.0
			if _t_stato > 20.0 or lontano or p2 == null:
				if GameManager.dialogo_con == self:
					GameManager.dialogo_con = null
					GameManager.boss_dialogue_closed.emit()
				_say("E vabbuo'. Ma nun te facesse vedé.")
				_pieta = 8.0
				_torna_in_ronda()
			return
		Stato.MULTA:
			_avvicinati(delta)
			return

	if _chasing:
		_do_chase(_get_player(), delta)
		return

	# **Quando il sospetto sale, non ti insegue: ti viene a parlare.**
	#
	# E' la differenza fra un vigile e un poliziotto. Il vigile ti conosce,
	# sa benissimo chi sei, e la prima cosa che fa e' venirti a dire di
	# smetterla. La corsa e le manette non c'entrano niente col suo
	# mestiere — quelle sono dei carabinieri, e arrivano se meni la gente.
	# **Sopra la soglia ti viene a cercare, non aspetta di vederti.**
	#
	# Prima doveva AVERTI IN VISTA per decidere di venirti a parlare: e
	# siccome ti vedeva davvero l'otto per cento del tempo, quel momento non
	# arrivava quasi mai. Ma un vigile che ha deciso che sei un problema non
	# sta li' ad aspettare di incrociarti: ti viene a cercare.
	#
	# Restano due vie di scampo, ed e' giusto che restino: sotto
	# all'ombrellone non ti trova, e fuori da venticinque metri (cioe' fuori
	# dalla piazza) si fa i fatti suoi.
	if _pieta <= 0.0 and (can_see_player() or _ti_sta_cercanno()):
		if GameManager.heat >= GameManager.HEAT_MAX:
			stato = Stato.MULTA
			_t_stato = 0.0
			_say("Fermo llà. Mo' te faccio 'o verbale.")
			SoundManager.play("fischio_vigile", 0.0, 0.95)
			return
		if GameManager.heat >= SOGLIA_PARLA:
			stato = Stato.AVVICINA
			_t_stato = 0.0
			_say("Ueh, guagliò. Vien' ccà nu momento.")
			return

	_do_patrol(delta)

	# Ogni tanto si ferma: o chiacchiera, o va al bar.
	_t_pausa -= delta
	if _t_pausa <= 0.0:
		_inizia_pausa()


## Le mani che si muovono mentre parla o beve: senza, un vigile fermo
## sembra un manichino piantato in mezzo alla piazza.
func _gesticola(_delta: float) -> void:
	_animate_walk(0.0)
	if _anim != null and randf() < 0.012:
		_anim.action("shrug")


## **'O turno fernesce.** Torna `true` quando ha già preso in mano tutto lui
## e il resto del `_physics_process` non deve girare.
func _smonta(delta: float) -> bool:
	if stato == Stato.SMONTA:
		# Se ne va camminando verso l'uscita della piazza — e camminando
		# davvero, con i muri: `Passo` ci pensa.
		global_position = Passo.verso(self, _meta_pausa, PATROL_SPEED * delta)
		_animate_walk(PATROL_SPEED * delta)
		_face_toward(_meta_pausa)
		if _t_stato > SMONTA_CAMMINA \
				or global_position.distance_to(_meta_pausa) < 1.2:
			queue_free()
		return true
	if stato == Stato.PARLA or stato == Stato.MULTA:
		# Il verbale lo finisce: sparire a metà dialogo lascerebbe aperto
		# il pannello delle risposte, che si mangia i tasti da 1 a 4.
		return false
	if _chasing or _beat_left > 0:
		# Uno non molla l'inseguimento perché è finito il turno.
		return false
	if GameManager.ora_d_o_juorno() < ORA_SMONTA:
		return false
	stato = Stato.SMONTA
	_t_stato = 0.0
	_chasing = false
	# Se per caso stava parlando con te, il dialogo si chiude qui: un
	# pannello rimasto aperto dopo che l'interlocutore è sparito si mangia
	# i tasti da 1 a 4 per il resto della giornata.
	if GameManager.dialogo_con == self:
		GameManager.dialogo_con = null
		GameManager.boss_dialogue_closed.emit()
	# Se ne va da dove è entrato, o comunque lontano: l'ultimo punto di
	# pattuglia è il fondo della piazza, che va benissimo.
	_meta_pausa = global_position + Vector3(0, 0, -60.0)
	if not patrol_points.is_empty():
		_meta_pausa = patrol_points[patrol_points.size() - 1] \
			+ Vector3(0, 0, -34.0)
	_say(SAY_SMONTA[randi() % SAY_SMONTA.size()])
	SoundManager.play("pop", -10.0, 0.7)
	GameManager.avvisa_strada(
		"'O vigile ha smuntato. 'A piazza è 'a toia — fin'a dimane.")
	# E il sospetto si sgonfia: non c'è più nessuno a cui importi.
	GameManager.cool_down(GameManager.HEAT_MAX * 0.5)
	return true


## **Te vede fatecà**: il sospetto che sale da solo mentre dirigi.
func _che_staje_facenno(delta: float) -> void:
	if stato != Stato.RONDA:
		return
	var pl := _get_player()
	if pl == null or not can_see_player():
		return
	var dirige := false
	for c in get_tree().get_nodes_in_group("cars"):
		if not is_instance_valid(c) or not c.has_method("is_being_directed"):
			continue
		if not c.is_being_directed():
			continue
		if c.global_position.distance_to(pl.global_position) <= REGIA_VICINO:
			dirige = true
			break
	if not dirige:
		return
	GameManager.add_heat(VEDE_REGIA * delta)
	# E ogni tanto lo dice, se no non si capisce da dove viene il sospetto.
	if randf() < 0.35 * delta:
		_say(SAY_REGIA[randi() % SAY_REGIA.size()])


## Qualcuno gli ha fatto una cosa **davanti agli occhi**: si gira, lo dice,
## e il sospetto fa un salto. È il gancio che usano lo stemma rubato e la
## ricettazione (`car_3d._steal_emblem`, `shop_3d`).
func t_ha_visto(quanto: float, che_ddice: String) -> bool:
	if stato == Stato.SMONTA or _ko["down"] or not can_see_player():
		return false
	_say(che_ddice)
	SoundManager.play("fischio_vigile", -3.0, 1.0)
	GameManager.add_heat(quanto)
	return true


func _torna_in_ronda() -> void:
	stato = Stato.RONDA
	_t_stato = 0.0
	_t_caffe = 0.0
	# Con la pioggia le pause sono piu' fitte: uno che fa il giro sotto
	# l'acqua ci mette meno a decidere che e' ora del caffe'.
	var quanto: float = randf_range(PAUSA_OGNI_MIN, PAUSA_OGNI_MAX)
	if GameManager.tipo_giornata == "pioggia":
		quanto *= 0.45
	_t_pausa = quanto


## Sceglie la pausa: se in piazza c'e' il banco del bar ci va meta' delle
## volte, se no si ferma a chiacchierare con chi passa.
##
## **E si chiove, ce va quase sempe (0.53).** Il capo: *"il vigile che si
## mette al coperto invece di camminare sotto l'acqua come se niente
## fosse"*. La tabella della 0.52 diceva già che con la pioggia scrive
## meta' delle multe — ma il perche' non si vedeva: camminava sotto
## l'acqua identico a un giorno di sole, e uno pensava che il gioco avesse
## semplicemente deciso di essere piu' buono. Adesso la ragione sta in
## strada: sta sotto la tenda del bar col caffe' in mano, e le multe
## scendono perche' **non e' li' a guardare**.
func _inizia_pausa() -> void:
	var banchi := get_tree().get_nodes_in_group("banco_bar")
	var vicino: Node3D = null
	var dmin := 46.0
	for b in banchi:
		if b is Node3D and global_position.distance_to(b.global_position) < dmin:
			dmin = global_position.distance_to(b.global_position)
			vicino = b
	var chiove: bool = GameManager.tipo_giornata == "pioggia"
	if vicino != null and randf() < (0.92 if chiove else 0.55):
		stato = Stato.CAFFE
		_t_stato = 0.0
		_t_caffe = 0.0
		_meta_pausa = vicino.global_position
		return
	stato = Stato.CHIACCHIERA
	_t_stato = 0.0
	_say(SAY_CHIACCHIERE[randi() % SAY_CHIACCHIERE.size()])
	# Si gira verso il passante piu' vicino, se ce n'e' uno.
	var meglio: Node3D = null
	var dd := 9.0
	for g in ["passanti", "signore", "drivers"]:
		for n in get_tree().get_nodes_in_group(g):
			if n is Node3D and global_position.distance_to(n.global_position) < dd:
				dd = global_position.distance_to(n.global_position)
				meglio = n
	if meglio != null:
		_face_toward(meglio.global_position)


## I guagliuni del pallone lo chiamano: dieci euro ben spesi.
func distrai(secondi: float = DISTRATTO_DURATA) -> void:
	if _ko["down"]:
		return
	# **Chi 'o distrae ha 'a chiudere pure 'o dialogo.** Se i guagliuni lo
	# chiamavano mentre stava parlando con te, il pannello delle risposte
	# restava a schermo per il resto del turno: il timeout dei venti secondi
	# vive dentro `case Stato.PARLA` e non si raggiungeva piu', e `answer()`
	# rifiutava perche' lo stato era cambiato. I tasti 1-4 restavano
	# mangiati, cioe' niente piu' acquisti in nessun negozio.
	# `receive_punch()` questa pulizia la fa; qui mancava.
	if GameManager.dialogo_con == self:
		GameManager.dialogo_con = null
		GameManager.boss_dialogue_closed.emit()
	stato = Stato.DISTRATTO
	_t_stato = maxf(0.0, DISTRATTO_DURATA - secondi)
	_chasing = false
	_say("E chi ve manna, guagliù?! Mo' vengo!")


## Ti raggiunge per parlarti (o per farti il verbale).
func _avvicinati(delta: float) -> void:
	var p := _get_player()
	if p == null:
		_torna_in_ronda()
		return
	var d: float = global_position.distance_to(p.global_position)
	if d > RAGGIO_PARLATA:
		var pr := global_position
		global_position = Passo.verso(self,
			p.global_position, AVVICINA_SPEED * delta)
		_animate_walk(global_position.distance_to(pr))
		_face_toward(p.global_position)
		# Se scappi via davvero lontano, lascia perdere: non e' un
		# inseguimento, e' una richiesta di spiegazioni.
		if d > 26.0 or _t_stato > 22.0:
			_torna_in_ronda()
		return
	_animate_walk(0.0)
	_face_toward(p.global_position)
	if stato == Stato.MULTA:
		_fai_la_multa()
	else:
		_apri_dialogo()


## **Quando il sospetto arriva in fondo, non scrive: chiama.**
##
## Fino alla 0.44 il massimo che poteva succedere era un verbale da
## cinquanta euro — una brutta serata, non un guaio. E siccome il verbale
## chiudeva la faccenda, la barra piena era **la fine** di una tensione
## invece che l'inizio.
##
## Adesso a barra piena tira fuori la radio. Nel 95% dei casi chiama la
## pattuglia: due stelle addosso e i carabinieri per strada. Nel 5% chiama
## **Borrelli** — e quello è il momento in cui una giornata normale
## diventa la sera in cui è arrivato lui, con tre ore d'anticipo.
##
## Il cinque per cento è tarato apposta: raro abbastanza da essere un
## avvenimento, alto abbastanza che chi tira la corda tutti i giorni prima
## o poi ci sbatte.
## **'A probabilità sta dint'ô GameManager (0.53).** Era 0,05 qua dentro e
## il calendario faceva il resto; adesso che il calendario non c'è più, la
## tirata è una sola e sta in un posto solo — `GameManager.PROB_BORRELLI`,
## una su cento.
var _chiamata_fatta: bool = false


func _chiamma_rinforzi() -> void:
	if _chiamata_fatta:
		return
	_chiamata_fatta = true
	SoundManager.play("radio_polizia", -1.0)
	if GameManager.forse_chiamma_borrelli(
			"'O vigile ha chiammato 'O DUTTORE. Borrelli sta venenno."):
		_say("Pronto? Duttò… sta n'ata vota ccà.")
		return
	_say("Centrale? Mandàteme 'na pattuglia 'n piazza.")
	GameManager.event_started.emit(
		"'O vigile ha chiammato 'a pattuglia. Mo' songo affare 'e carabiniere.")
	# Due stelle: abbastanza da farli uscire, non tanto da farti sparare
	# addosso. E il sospetto si azzera: da qui in poi il problema e' un
	# altro, e restare col vigile addosso sarebbe una punizione doppia.
	GameManager.crimine(2.0 * GameManager.PUNTI_PER_STELLA)
	GameManager.heat = 0.0
	GameManager.heat_changed.emit(GameManager.heat)


func _apri_dialogo() -> void:
	stato = Stato.PARLA
	_t_stato = 0.0
	_risposto = false
	# **Si schiarisce la voce prima di parlare.** Uno che si avvicina per
	# farti una domanda scomoda non attacca a parlare: tossisce, si prende
	# il suo mezzo secondo. E' mezzo secondo che ti dice che sta arrivando
	# il momento, prima ancora di leggere la scritta.
	SoundManager.play_uno(["schiarisce", "tosse"], -5.0)
	# **Ti gira la faccia e ti toglie di mano quello che stavi facendo.**
	# Una conversazione in cui puoi continuare a dirigere una macchina non
	# e' una conversazione — e il vigile smetteva di essere un problema.
	var pl := get_tree().get_first_node_in_group("player")
	if pl != null and pl.has_method("guarda_verso"):
		pl.guarda_verso(self)
		pl.interrompi_tutto()
	_say("Allora? Che me cunte?")
	GameManager.dialogo_con = self
	GameManager.boss_dialogue_opened.emit(RISPOSTE)


## Chiamato dall'HUD quando il giocatore sceglie (0..3).
func answer(indice: int) -> void:
	if stato != Stato.PARLA or _risposto:
		return
	if indice < 0 or indice >= RISPOSTE.size():
		return
	_risposto = true
	var scelta: Dictionary = RISPOSTE[indice]
	GameManager.boss_dialogue_closed.emit()
	GameManager.dialogo_con = null
	_say(str(scelta["reply"]))
	if bool(scelta["buona"]):
		# **Gli fa pena, e ti lascia stare. Ma la barra non si muove.**
		#
		# E' la parte importante: non e' un tasto per azzerare il sospetto,
		# se no si andrebbe avanti a farsi beccare apposta. Lui sa quello
		# che fai, semplicemente oggi chiude un occhio.
		_pieta = PIETA_DURATA
		SoundManager.play("pop", -8.0, 0.7)
		GameManager.event_started.emit(
			"'O vigile t'ha creduto. Pe' mo' te lassa sta' — ma 'o sospetto resta.")
		_torna_in_ronda()
		return
	SoundManager.play("fail", -6.0, 0.9)
	GameManager.add_heat(14.0)
	GameManager.event_started.emit("Risposta sbagliata: s'è 'nfastidito.")
	if GameManager.heat >= GameManager.HEAT_MAX:
		stato = Stato.MULTA
		_t_stato = 0.0
	else:
		_torna_in_ronda()


func _fai_la_multa() -> void:
	SoundManager.play("fail", -2.0, 0.75)
	GameManager.screen_shake.emit(0.5)
	var esito: String = GameManager.paga_multa()
	_say("Verbale fatto. " + esito)
	GameManager.event_started.emit("MULTA — " + esito)
	# **E dopo il verbale, la radio.** Il verbale da solo chiudeva la
	# faccenda: cinquanta euro e amici come prima. Adesso il verbale e' la
	# prima meta' — la seconda e' che chiama qualcuno.
	_chiamma_rinforzi()
	# Scritto il verbale, per lui la faccenda e' chiusa: il sospetto
	# riparte da meta' e lui torna a fare la ronda. Non e' un game over,
	# e' un costo.
	GameManager.cool_down(GameManager.HEAT_MAX * 0.62)
	_pieta = 12.0
	_torna_in_ronda()


func _has_line_of_sight(player: Node3D) -> bool:
	var space_state := get_world_3d().direct_space_state
	var from: Vector3 = global_position + Vector3(0, 1.4, 0)
	var to: Vector3 = player.global_position + Vector3(0, 1.0, 0)
	var query := PhysicsRayQueryParameters3D.create(from, to, LAYER_WORLD)
	var result := space_state.intersect_ray(query)
	return result.is_empty()


func _do_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		return
	var target: Vector3 = patrol_points[_patrol_idx]
	var before := global_position
	global_position = Passo.verso(self, target, PATROL_SPEED * delta)
	_animate_walk(global_position.distance_to(before))
	_face_toward(target)
	# Le occhiate a destra e a sinistra: la direzione di marcia resta quella,
	# ma il cono visivo spazza avanti e indietro. Passare dietro le spalle
	# di un vigile non è più una garanzia.
	_scan_time += delta
	var sweep: float = sin(_scan_time * TAU / SCAN_PERIOD)
	_visual_root.rotation.y += deg_to_rad(SCAN_HALF_ANGLE_DEG) * sweep
	if global_position.distance_to(target) < 0.3:
		_patrol_idx = (_patrol_idx + 1) % patrol_points.size()


## Camminata. `moved` è la distanza fatta nel frame: diviso il delta è la
## velocità, e il BlendSpace ci sceglie da solo passo o corsa.
func _animate_walk(moved: float) -> void:
	if _anim == null:
		return # modello 3D esterno
	_anim.set_speed(moved / maxf(get_physics_process_delta_time(), 0.0001))


func _do_chase(player: Node3D, delta: float) -> void:
	if player == null:
		_chasing = false
		return

	if _has_line_of_sight(player) and global_position.distance_to(player.global_position) <= SIGHT_RADIUS * 1.6:
		_lost_sight_timer = 0.0
	else:
		_lost_sight_timer += delta
		if _lost_sight_timer >= LOSE_SIGHT_TIME:
			_give_up_chase()
			return

	var before := global_position
	global_position = Passo.verso(self, player.global_position,
		CHASE_SPEED * delta)
	_animate_walk(global_position.distance_to(before))
	_face_toward(player.global_position)
	if global_position.distance_to(player.global_position) <= CATCH_RADIUS:
		_catch_player()


func _face_toward(target: Vector3) -> void:
	var dir: Vector3 = target - global_position
	dir.y = 0.0
	if dir.length() > 0.05:
		# forward(θ) = (−sinθ, 0, −cosθ): θ = atan2(−dir.x, −dir.z).
		# La vecchia formula era specchiata sull'asse X: il vigile guardava
		# dalla parte sbagliata nei tratti est-ovest della pattuglia (e con
		# lui il suo cono visivo).
		_visual_root.rotation.y = atan2(-dir.x, -dir.z)


func _start_chase() -> void:
	_chasing = true
	_lost_sight_timer = 0.0
	SoundManager.play("fischio_vigile", -4.0)
	GameManager.screen_shake.emit(0.3)


func _give_up_chase() -> void:
	_chasing = false
	_cooldown = CHASE_COOLDOWN
	GameManager.cool_down(GameManager.HEAT_MAX) # rientra in pattuglia con sospetto azzerato


func _catch_player() -> void:
	if _beat_left > 0:
		return
	_chasing = false
	_cooldown = CHASE_COOLDOWN
	SoundManager.play("fischio_vigile", 0.0, 0.9)
	GameManager.screen_shake.emit(0.8)
	_say("FIERMATE! Favorisca i documenti!")
	# **Non porta piu' nessuno in guardina.**
	#
	# L'arresto del vigile era un game over secco a meta' turno, e per una
	# cosa — posteggiare abusivo — che nella realta' finisce con un
	# foglietto. Adesso finisce con il foglietto pure qui: te ne da' una
	# per il disturbo e poi scrive. L'arresto resta, ma e' dei carabinieri,
	# e ci si arriva menando la gente.
	_beat_left = 1
	_beat_cd = 0.25


func _finish_arrest() -> void:
	if GameManager.hospitalized:
		return # è già finito in ambulanza
	_fai_la_multa()
