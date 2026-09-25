extends CharacterBody3D
## PlayerFPS
## Il parcheggiatore abusivo in prima persona. Movimento WASD + mouse look,
## sprint, e un raycast dalla camera per rilevare l'auto più vicina a cui
## si può fare qualcosa (parcheggiare, bussare, inseguire, danneggiare).

const LAYER_WORLD := 1
const LAYER_CAR := 4

const Human := preload("res://scripts/human_builder.gd")
const Tex := preload("res://scripts/textures.gd")
const Models := preload("res://scripts/models.gd")
const ArmaFp := preload("res://scripts/arma_fp.gd")

const WALK_SPEED: float = 4.8 # la piazza è grande: si cammina un po' più svelti
const SPRINT_SPEED: float = 8.2
const STEP_INTERVAL: float = 0.46 # secondi fra un passo e l'altro, a passo normale
const MOUSE_SENSITIVITY: float = 0.0028
## Fin dove arriva il fischio, e quanto ti fa notare.
const FISCHIO_RAGGIO: float = 26.0
const FISCHIO_HEAT: float = 4.0
## Quanto piu' veloce si va col caffè in corpo.
const CAFFE_SPINTA: float = 1.35
## Quanti gradi al secondo fa lo stick destro spinto a fondo. Il mouse va a
## pixel, il joypad va a tempo: sono due leggi diverse e vanno tenute
## separate, altrimenti su un PC a 144 fps la camera del pad corre il doppio.
const STICK_SENSITIVITY_DEG: float = 210.0
## Curva di risposta dello stick. Con 1.0 (lineare) mirare e' impossibile:
## ogni millimetro di stick e' uno strappo. Elevando a 2.2 il centro dello
## stick diventa lento e preciso e i bordi restano veloci.
const STICK_CURVE: float = 2.2
const INTERACT_RANGE: float = 3.0
const PALETTA_RANGE: float = 9.0 # con la paletta comandi le auto da lontano
const GRAVITY: float = 18.0
const JUMP_SPEED: float = 6.4
## **Salire sulle cose.**
##
## Il salto arriva a poco più di un metro: il tetto di un'utilitaria sta a
## uno e sei, quello di un furgone a uno e nove. Risultato: un vicolo con
## due macchine in doppia fila era un muro, e l'unico modo di passare era
## fare il giro dall'altro capo del quartiere.
##
## Invece di alzare il salto (che avrebbe reso il personaggio una cavalletta
## dappertutto) si aggiunge l'appiglio: premi SPAZIO davanti a un ostacolo
## alto meno di due metri e ci si sale sopra, con un movimento breve. Il
## salto normale resta quello di prima. Vale per le auto, per il cassone del
## furgone, per le bancarelle e per i cassonetti — tutto quello che tappava
## un passaggio adesso si scavalca.
const APPIGLIO_MAX: float = 2.0   # quanto in alto ci si tira su
const APPIGLIO_MIN: float = 0.45  # sotto a questo si sale camminando
const APPIGLIO_DURATA: float = 0.28
## Accovacciato: si va piano e si sta bassi. Serve per avvicinarsi alle
## signore senza farsi notare — e per fare scena.
const CROUCH_SPEED: float = 2.3
const CROUCH_HEAD_Y: float = 1.02
const STAND_HEAD_Y: float = 1.6
const PITCH_LIMIT_DEG: float = 85.0

signal prompt_changed(text: String)
signal shop_focus_changed(kind: String) # "", "zio", "bazar", "tabacchi"

const PUNCH_RANGE: float = 2.4

var head: Node3D
var camera: Camera3D
var current_target: Node = null
var directing_car: Node = null # != null mentre il player sta dirigendo un'auto
var _seduto: bool = false # sulla sedia sdraio del salotto
var _sedia: Node3D = null # quale sedia (per restare appoggiati lì)
var _spiccio: float = 0.0 # 'e centesime ca t'hanno lassato, ancora sciose

# Mani in prima persona
var _hands_root: Node3D
## Le ossa vere delle mani: ci si appendono la paletta e la sigaretta.
var _osso_mano_l: Node3D
var _osso_mano_r: Node3D
var _paletta: Node3D
## 'O fierro ca tiene 'n mano, si ne tiene uno (0.58).
var _arma_vista: Node3D
var _arma_mo: String = ""
## Il fierro che vedi tu, appeso alla telecamera (0.61). Vedi `arma_fp.gd`.
var _arma_fp: Node3D = null
var _punch_timer: float = 0.0
var _step_cd: float = 0.0
## Accovacciato (C). Letto anche da fuori: le signore si accorgono meno di
## uno che sta basso.
var is_crouching: bool = false
var _crouch_blend: float = 0.0
# Il corpo visibile del personaggio (petto, pancia, gambe, scarpe) e quello
# che ci si mette addosso.
var _body_root: Node3D
var _body_legs: Array = []
var _body_arms: Array = []
var _body_phase: float = 0.0
var _body_anim: Node = null
var _cosmetics_root: Node3D
# --- Piazzamento decorazioni ---
var _placing_id: String = ""
var _place_ghost: Node3D = null
const PLACE_MAX_DIST: float = 7.0
## Ingombro indicativo di ogni decorazione, per il fantasma verde.
const DECOR_FOOTPRINT := {
	"sedia": Vector3(0.8, 1.0, 0.9),
	"ombrellone": Vector3(2.2, 2.4, 2.2),
	"tavolino": Vector3(0.8, 0.8, 0.8),
	"radio": Vector3(0.4, 0.3, 0.3),
	"piante": Vector3(0.7, 1.2, 0.7),
	"luminarie": Vector3(3.0, 0.4, 3.0),
}
## **La camicia del parcheggiatore.**
##
## Era bianco panna (0.86). In prima persona il petto occupa il fondo dello
## schermo per tutta la partita, e un panno quasi bianco sotto il sole della
## piazza andava in saturazione: veniva fuori una lastra bianca senza
## pieghe ne' ombre, che era la cosa piu' brutta dell'inquadratura.
##
## Azzurro da lavoro slavato: rimane chiaro abbastanza da leggersi in
## ombra, ma sta dentro all'esposizione e le pieghe si vedono.
const SHIRT_COLOR := Color(0.46, 0.53, 0.61)
const PANTS_COLOR := Color(0.22, 0.24, 0.3)
const SKIN_COLOR := Color(0.84, 0.65, 0.5)
## Di quanto il busto arretra rispetto alla posizione naturale.
##
## **'O calo 'e diciotto centimetre nun serve cchiù.** C'era per tenere il
## petto sotto alla telecamera quando la testa del modello era ancora
## accesa: senza, la camera finiva dentro al collo. Adesso la testa si
## cancella (`senza_testa`), quindi il corpo può stare alla sua altezza
## vera — e infatti deve, se no guardandosi in giù le spalle stanno trenta
## centimetri più in basso di dove uno se le aspetta.
##
## L'arretramento invece resta: la camera va DAVANTI al petto, se no
## guardandosi in giù si vede una parete a venticinque centimetri.
const BODY_OFFSET := Vector3(0.0, -0.04, 0.13)
var _hands_time: float = 0.0
var _shake: float = 0.0
var _knocked: float = 0.0 # secondi di stordimento dopo un investimento
var _knock_push: Vector3 = Vector3.ZERO

# Sigaretta
const SMOKE_DURATION: float = 12.0
const SMOKE_COOL_BONUS: float = 6.0 # sospetto extra che scende al secondo mentre fumi
var _smoking: float = 0.0
## Letto da fuori (Borrelli): mentre fumi la sua furia scende molto più in
## fretta. Uno che si fuma 'na sigaretta non sta lavorando.
var is_smoking: bool = false
var _cig_root: Node3D
var _cig_ember: MeshInstance3D
var _cig_smoke: CPUParticles3D
var _puff_timer: float = 0.0
# --- 'A presa: quando un carabiniere ti mette le mani addosso ---
## Quanti secondi hai per scioglierti prima delle manette.
const PRESA_DURATA: float = 2.6
## Quanto vale un colpo di tasto. Sette colpi e sei libero.
const PRESA_SPINTA: float = 0.15
## **'A terza presa nun se scioglie.** Vedi `GameManager.registra_fermo()`.
## Dura meno, perche' martellare un tasto che non serve a niente e' una
## punizione stupida: un secondo e mezzo basta a far capire che stavolta e'
## andata storta, e poi si va dentro.
const PRESA_SECCA: float = 1.5
var _presa_secca: bool = false
var _inchiodato: bool = false
var _posto_fisso: Vector3 = Vector3.ZERO
var _presa_t: float = 0.0
var _presa_forza: float = 0.0
var _presa_chi: Node = null
var _appiglio_t: float = 0.0
var _appiglio_da: Vector3
var _appiglio_a: Vector3


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	# Il player è solido contro mondo E auto/persone: niente più passare
	# attraverso le macchine.
	collision_mask = LAYER_WORLD | LAYER_CAR
	_build_body()
	GameManager.piglia_o_mouse(true)
	# NB: connessioni a metodi nominati, MAI a lambda. Il GameManager è un
	# autoload che sopravvive al cambio scena: una lambda resterebbe
	# agganciata anche dopo che questo nodo è stato liberato, e alla prima
	# emissione il gioco crasherebbe su un'istanza morta.
	GameManager.screen_shake.connect(_on_screen_shake)
	GameManager.upgrade_purchased.connect(_on_upgrade_purchased)


func _build_body() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.7
	shape.shape = capsule
	shape.position = Vector3(0, 0.85, 0)
	add_child(shape)

	head = Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 1.6, 0)
	add_child(head)

	camera = Camera3D.new()
	camera.current = true
	camera.fov = 80.0
	# Il piano di taglio lontano: di serie Godot lo mette a 4000, ma il
	# Vesuvio sta a 260 metri con una base larga 400 e va tenuto dentro
	# insieme al mare, che arriva a trecento.
	camera.far = 1200.0
	head.add_child(camera)

	_build_hands()
	_build_body_model()


## **'E ccose ca 'o giocatore tene 'n mano.**
##
## Non costruisce più mani: quelle sono del corpo. Costruisce la paletta e
## la sigaretta e le appende alle **ossa vere** delle mani, che è il motivo
## per cui adesso seguono la camminata, il pugno e tutto il resto senza che
## nessuno le muova a mano.
func _build_hands() -> void:
	# Un nodo che resta appeso alla camera: ci va la roba che deve stare
	# ferma davanti all'occhio a prescindere dal corpo (per ora niente, ma
	# il fumo della sigaretta ci si appoggia quando il corpo non c'è).
	_hands_root = Node3D.new()
	_hands_root.position = Vector3(0, -0.26, -0.52)
	camera.add_child(_hands_root)
	_arma_fp = ArmaFp.new()
	_arma_fp.name = "ArmaFp"
	camera.add_child(_arma_fp)


## Si chiama dopo il corpo, perché ha bisogno delle ossa delle mani.
func _appende_a_ll_ossa(bones: Dictionary) -> void:
	_osso_mano_r = bones.get("hand_r")
	_osso_mano_l = bones.get("hand_l")
	_build_paletta()
	_build_arma()
	_build_sigaretta()


# ---------------------------------------------------------------------------
# Il corpo del parcheggiatore
# ---------------------------------------------------------------------------

## Il modello vero del personaggio, appeso al corpo e non alla camera:
## guardando in giù ci si vede il petto, la pancia, le gambe e le scarpe, e
## le gambe camminano davvero. La testa non si costruisce (la camera sta
## esattamente lì dentro e si vedrebbe l'interno del cranio).
func _build_body_model() -> void:
	_body_root = Node3D.new()
	add_child(_body_root)

	var parts := Human.build(SHIRT_COLOR, PANTS_COLOR, "", 1.78, {
		"skin": SKIN_COLOR,
		"hair": Color(0.12, 0.09, 0.07),
		"belly": 0.35,
		"bald": false,
		"moustache": false,
		# La testa non si costruisce proprio: la camera sta esattamente lì
		# dentro, e prima si vedeva il proprio cranio in mezzo allo schermo.
		"senza_testa": true,
	})
	_body_root.add_child(parts["root"])
	_body_legs = parts["legs"]
	_body_arms = parts["arms"]
	_body_anim = parts.get("anim", null)

	# Il busto arretra un filo, così guardando in giù si vede il petto
	# dall'alto invece che da dentro.
	parts["root"].position = BODY_OFFSET

	# **'E braccia vere so' ll'uniche braccia (0.54).** Qui ci stava
	# `for arm in _body_arms: arm.visible = false`, che non nascondeva
	# niente: `_body_arms` sono i `BoneAttachment3D` delle mani, non le
	# braccia — e un braccio dentro a una mesh skinnata non è un nodo che
	# si spegne. Adesso non c'è più niente da nascondere.
	_appende_a_ll_ossa(parts["bones"])

	_cosmetics_root = Node3D.new()
	_cosmetics_root.position = BODY_OFFSET
	_body_root.add_child(_cosmetics_root)
	_refresh_cosmetics()



## Gilet, occhiali, borsello, coppola: si vedono addosso al modello.
## Si ricostruisce tutto da capo a ogni acquisto — sono quattro oggetti,
## costa meno che tenerne traccia uno per uno.
func _refresh_cosmetics() -> void:
	if _cosmetics_root == null:
		return
	for child in _cosmetics_root.get_children():
		child.queue_free()

	if GameManager.has_upgrade("gilet"):
		_build_gilet()
	if GameManager.has_upgrade("borsello"):
		_build_borsello()
	# Occhiali e coppola stanno sulla testa, che in prima persona è nascosta:
	# si vedono solo nell'anteprima dell'inventario. Il gilet e il borsello
	# invece si vedono guardandosi in giù, ed è quello che conta.


# ---------------------------------------------------------------------------
# Quello che si porta addosso: prima il modello, poi le scatole
# ---------------------------------------------------------------------------
#
# Gilet, borsello e paletta si vedono da vicinissimo — i primi due
# guardandosi in giu', la paletta sta in mano a mezzo metro dagli occhi —
# e finora erano parallelepipedi. Adesso ognuno ha il suo modello, fatto in
# Blender, con l'origine gia' nel punto in cui va attaccato.
#
# La geometria a scatole resta come rete di sicurezza: se un domani il
# pacchetto dei modelli non c'e', il parcheggiatore ha lo stesso il gilet
# addosso invece di girare mezzo nudo.
func _indossa(nome: String, dove: Node3D, pos: Vector3,
		rot: Vector3 = Vector3.ZERO) -> Node3D:
	var n := Models.spawn(nome)
	if n == null:
		return null
	n.position = pos
	n.rotation = rot
	dove.add_child(n)
	return n


func _build_gilet() -> void:
	# Il centro del gilet sta all'altezza del petto, non del collo: a
	# 1,16 il modello arrivava sopra alle spalle e sembrava un collare.
	if _indossa("gilet", _cosmetics_root, Vector3(0, 1.02, -0.02)) != null:
		return
	var hi_vis := Tex.flat(Color(0.95, 0.85, 0.12), 0.85)
	var band := Tex.flat(Color(0.9, 0.9, 0.92), 0.25, 0.7)

	# I due davanti, con lo spacco in mezzo
	for sx in [-1.0, 1.0]:
		var front := MeshInstance3D.new()
		var fm := BoxMesh.new()
		fm.size = Vector3(0.17, 0.52, 0.05)
		front.mesh = fm
		front.position = Vector3(sx * 0.15, 1.16, -0.15)
		front.material_override = hi_vis
		_cosmetics_root.add_child(front)

		var side := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(0.05, 0.52, 0.3)
		side.mesh = sm
		side.position = Vector3(sx * 0.25, 1.16, -0.01)
		side.material_override = hi_vis
		_cosmetics_root.add_child(side)

	var back := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.5, 0.54, 0.05)
	back.mesh = bm
	back.position = Vector3(0, 1.16, 0.14)
	back.material_override = hi_vis
	_cosmetics_root.add_child(back)

	# Le bande catarifrangenti
	for y in [1.05, 1.28]:
		var strip := MeshInstance3D.new()
		var stm := BoxMesh.new()
		stm.size = Vector3(0.53, 0.06, 0.33)
		strip.mesh = stm
		strip.position = Vector3(0, y, -0.005)
		strip.material_override = band
		_cosmetics_root.add_child(strip)


## Il borsello a tracolla: sta sul fianco e si vede guardandosi in giù.
func _build_borsello() -> void:
	if _indossa("borsello", _cosmetics_root, Vector3(0.185, 0.92, -0.06),
			Vector3(0, deg_to_rad(-14), 0)) != null:
		return
	var leather := Tex.flat(Color(0.28, 0.18, 0.12), 0.6)
	var buckle := Tex.flat(Color(0.82, 0.68, 0.3), 0.25, 0.9)

	var pouch := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.2, 0.16, 0.1)
	pouch.mesh = pm
	pouch.position = Vector3(0.22, 0.92, -0.1)
	pouch.material_override = leather
	_cosmetics_root.add_child(pouch)

	var flap := MeshInstance3D.new()
	var flm := BoxMesh.new()
	flm.size = Vector3(0.21, 0.06, 0.11)
	flap.mesh = flm
	flap.position = Vector3(0.22, 1.0, -0.1)
	flap.material_override = leather
	_cosmetics_root.add_child(flap)

	var clip := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(0.05, 0.035, 0.02)
	clip.mesh = cm
	clip.position = Vector3(0.22, 0.97, -0.155)
	clip.material_override = buckle
	_cosmetics_root.add_child(clip)

	# Tracolla in diagonale sul petto
	var strap := MeshInstance3D.new()
	var stm := BoxMesh.new()
	stm.size = Vector3(0.05, 0.62, 0.03)
	strap.mesh = stm
	strap.position = Vector3(0.06, 1.2, -0.15)
	strap.rotation.z = deg_to_rad(28)
	strap.material_override = leather
	_cosmetics_root.add_child(strap)


## Le gambe che camminano davvero, guardandosi in giù.
func _animate_body(delta: float, moving: bool, speed: float) -> void:
	if _body_anim == null:
		return
	_body_anim.set_speed(speed if moving else 0.0)
	_body_anim.set_crouching(is_crouching)
	# L'accovacciata del rig abbassa il bacino di 34 cm, la camera scende di
	# 58: la differenza la mette il corpo, altrimenti guardando in giù il
	# petto resterebbe più in alto degli occhi.
	_body_root.position.y = -0.24 * _crouch_blend


func _on_screen_shake(amount: float) -> void:
	_shake = maxf(_shake, amount)
	# Col joypad il tremore dello schermo si sente anche in mano. Si aggancia
	# qui perche' `screen_shake` e' gia' il segnale che il gioco emette per
	# ogni botta: pugni, urti, multe, il motorino. Un posto solo, tutte le
	# occasioni.
	if not Input.get_connected_joypads().is_empty():
		var forza: float = clampf(amount, 0.0, 1.0)
		Input.start_joy_vibration(Input.get_connected_joypads()[0],
			forza * 0.55, forza, minf(0.12 + forza * 0.28, 0.4))


func _on_upgrade_purchased(id: String) -> void:
	if id == "paletta" and _paletta:
		_paletta.visible = true
	if id in GameManager.COSMETIC_IDS:
		_refresh_cosmetics()


## La sigaretta tra le dita della mano sinistra: brace accesa e filo di fumo.
func _build_sigaretta() -> void:
	_cig_root = Node3D.new()
	_cig_root.position = Vector3(0.02, 0.05, -0.08)
	_cig_root.rotation.x = deg_to_rad(-12)
	# La sigaretta sta nell'osso della mano sinistra: si accende, si porta
	# alla bocca e si abbassa **con il braccio**, senza che nessuno la
	# muova. Se l'osso non c'è (corpo non costruito) resta appesa alla
	# camera, che è meglio di non esistere.
	if _osso_mano_l != null and is_instance_valid(_osso_mano_l):
		_osso_mano_l.add_child(_cig_root)
	else:
		_hands_root.add_child(_cig_root)

	var stick := MeshInstance3D.new()
	var stick_mesh := CylinderMesh.new()
	stick_mesh.top_radius = 0.008
	stick_mesh.bottom_radius = 0.008
	stick_mesh.height = 0.09
	stick.mesh = stick_mesh
	stick.rotation.x = deg_to_rad(90)
	stick.position = Vector3(0, 0, -0.045)
	var paper := StandardMaterial3D.new()
	paper.albedo_color = Color(0.95, 0.94, 0.9)
	stick.material_override = paper
	_cig_root.add_child(stick)

	_cig_ember = MeshInstance3D.new()
	var ember_mesh := SphereMesh.new()
	ember_mesh.radius = 0.009
	ember_mesh.height = 0.018
	_cig_ember.mesh = ember_mesh
	_cig_ember.position = Vector3(0, 0, -0.092)
	var ember_mat := StandardMaterial3D.new()
	ember_mat.albedo_color = Color(1.0, 0.4, 0.1)
	ember_mat.emission_enabled = true
	ember_mat.emission = Color(1.0, 0.35, 0.08)
	ember_mat.emission_energy_multiplier = 3.0
	_cig_ember.material_override = ember_mat
	_cig_root.add_child(_cig_ember)

	_cig_smoke = CPUParticles3D.new()
	_cig_smoke.amount = 14
	_cig_smoke.lifetime = 1.8
	_cig_smoke.direction = Vector3(0, 1, 0)
	_cig_smoke.spread = 14.0
	_cig_smoke.initial_velocity_min = 0.15
	_cig_smoke.initial_velocity_max = 0.3
	_cig_smoke.gravity = Vector3(0, 0.25, 0)
	_cig_smoke.scale_amount_min = 0.02
	_cig_smoke.scale_amount_max = 0.07
	var puff := SphereMesh.new()
	puff.radius = 0.5
	puff.height = 1.0
	var smoke_mat := StandardMaterial3D.new()
	smoke_mat.albedo_color = Color(0.85, 0.85, 0.85, 0.25)
	smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff.material = smoke_mat
	_cig_smoke.mesh = puff
	_cig_smoke.position = Vector3(0, 0.01, -0.1)
	_cig_root.add_child(_cig_smoke)

	_cig_root.visible = false


## Accende una sigaretta, se ne hai.
## Il fischietto: due dita in bocca e la piazza si gira. Richiama tutte le
## auto in attesa entro il raggio — quelle in arrivo tagliano verso di te,
## quelle ferme si rimettono buone.
func _fischia() -> void:
	if not GameManager.has_upgrade("fischietto"):
		prompt_changed.emit("Nun tiene 'o fischietto — se compra 'a 'O Zio")
		return
	if not GameManager.fischia():
		return
	SoundManager.play("whistle", -2.0, randf_range(0.98, 1.06))
	if _body_anim != null:
		_body_anim.action("point")
	var richiamate := 0
	for car in get_tree().get_nodes_in_group("cars"):
		if not is_instance_valid(car) or not car.has_method("richiamata_dal_fischio"):
			continue
		if global_position.distance_to(car.global_position) > FISCHIO_RAGGIO:
			continue
		if car.richiamata_dal_fischio(global_position):
			richiamate += 1
	if richiamate > 0:
		GameManager.directing_gesture.emit("FIIIIII! 'O POSTO STA CCÀ!", true)
		# Farsi sentire e' anche farsi notare: il vigile alza la testa.
		GameManager.add_heat(FISCHIO_HEAT)
	else:
		GameManager.directing_gesture.emit("FIIIIII!", true)


## Il caffè del bar, bevuto in piedi. Toglie sospetto, rimette in sesto e
## per un quarto di minuto si corre come a vent'anni.
func _bevi_caffe() -> void:
	if GameManager.caffe <= 0:
		prompt_changed.emit("Nun tiene cchiù cafè — se piglia 'o tabaccaio")
		return
	if not GameManager.bevi_caffe():
		return
	SoundManager.play("sorso_caffe", -5.0)
	prompt_changed.emit("Ah! Chisto sì ca è cafè.")


# ---------------------------------------------------------------------------
# 'A sedia sdraio
# ---------------------------------------------------------------------------

## Lo chiama il corpo invisibile appoggiato sulla sedia quando premi [E].
## Premuto una seconda volta ti rialza: la sedia è un interruttore, non una
## trappola.
func assettate(sedia: Node3D) -> void:
	if _seduto:
		_alzate()
		return
	_seduto = true
	_sedia = sedia
	velocity = Vector3.ZERO
	SoundManager.play("pop", -14.0, 0.7)
	prompt_changed.emit("Assettato. Movite (o [E]) pe' t'alzà.")


func _alzate() -> void:
	if not _seduto:
		return
	_seduto = false
	_sedia = null
	head.position.y = STAND_HEAD_Y
	prompt_changed.emit("")


## Un secondo di riposo. Si sta fermi davvero — velocità azzerata, testa
## bassa come la sedia — e nel frattempo il quartiere si dimentica di te.
func _riposa(delta: float) -> void:
	velocity = Vector3.ZERO
	move_and_slide()
	head.position.y = lerpf(head.position.y, CROUCH_HEAD_Y - 0.18,
		clampf(delta * 8.0, 0.0, 1.0))

	# Ti alzi al primo comando di movimento: nessuno deve restare
	# incastrato su una sdraio perché non trova il tasto giusto.
	if Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down") \
			or Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") \
			or Input.is_action_just_pressed("jump") \
			or Input.is_action_just_pressed("interact") \
			or Input.is_action_just_pressed("punch"):
		_alzate()
		return
	# E ti alzi da solo se la sedia sparisce (spostata, o piazza rifatta).
	if _sedia == null or not is_instance_valid(_sedia):
		_alzate()
		return

	GameManager.cool_down(GameManager.SEDIA_CALMA * delta)
	GameManager.heal_player(GameManager.SEDIA_OSSA * delta)
	# **'O spicciariello** (0.56). Chi ti vede seduto lì davanti come un
	# custode qualunque, ogni tanto ti lascia una monetina. Si accumula a
	# frazioni e si incassa a euro interi: se no `add_money` verrebbe
	# chiamato sessanta volte al secondo per niente.
	_spiccio += GameManager.SEDIA_SPICCIO * delta
	if _spiccio >= 1.0:
		var quanto: int = int(_spiccio)
		_spiccio -= float(quanto)
		GameManager.add_money(quanto)
		SoundManager.play("coin", -16.0, randf_range(1.1, 1.3))


func _light_cigarette() -> void:
	if _smoking > 0.0:
		return
	if not GameManager.consume_cigarette():
		SoundManager.play("fail", -12.0, 1.2)
		prompt_changed.emit("Pacchetto vuoto — passa dal tabaccaio")
		return
	_smoking = SMOKE_DURATION
	is_smoking = true
	_cig_root.visible = true
	_cig_smoke.emitting = true
	SoundManager.play("pop", -14.0, 0.7)
	# Non è medicina, ma nel quartiere funziona: una tirata rimette in sesto.
	GameManager.heal_player(18.0)
	GameManager.directing_gesture.emit("Ah... mo' se ragiona.", true)


## La paletta da posteggiatore: manico + disco rosso/bianco nella mano
## destra. Visibile solo se l'hai comprata da 'O Zio.
# ---------------------------------------------------------------------------
# 'O FIERRO 'N MANO (0.58)
# ---------------------------------------------------------------------------
#
# **Nun se vedeva.** Dalla 0.56 si comprano cinque armi dall'armiere, si
# scorrono con [G], cambiano il danno, cambiano il fiato che costa un colpo
# e cambiano perfino l'animazione del pugno — e **in mano non c'era
# niente**. Compravi il coltello da ottanta euro e il gioco ti rispondeva
# con una scritta.
#
# Una cosa che hai pagato e che non vedi è una cosa che non credi di avere:
# è lo stesso ragionamento per cui alla 0.56 ogni oggetto del banchetto ha
# dovuto avere un effetto visibile invece che "meno danno che non prendi".
#
# **Tre su cinque, e se dice pecché.** Il pacchetto PSX ha un coltello, una
# pistola, un manganello e un gomito di tubo — che è esattamente la forma di
# un cric. Non ha un kalash, e quello resta come stava: è l'arma più cara e
# più rara del gioco, e chi arriva a milleduecento euro se la immagina da
# solo.

## Quale modello va 'n mano p'ogni fierro, e comme sta girato.
## 'E gradi stanno ccà pecché sti rotazioni se correggeno guardanno 'na
## fotografia, no facenno cunte: 'a mano r tene 'o sotto ncopp'ô sujo +Y
## (mesurato 'a `prova_manella`, 0.54), e ogni modello d''o pacchetto tene
## 'o luongo sujo ncopp'a n'asse diverso.
const ARMA_MODELLO := {
	"cric": ["tubo_angolo", Vector3(-90, 0, 0), Vector3(0.02, 0.04, -0.10)],
	"mazza": ["manganello", Vector3(0, 0, 0), Vector3(0.0, 0.03, -0.08)],
	"curtiello": ["curtiello", Vector3(0, 0, 0), Vector3(0.0, 0.02, -0.06)],
	"fierro": ["fierro", Vector3(0, -90, 0), Vector3(0.0, 0.03, -0.07)],
}


func _build_arma() -> void:
	_arma_vista = Node3D.new()
	if _osso_mano_r != null and is_instance_valid(_osso_mano_r):
		_osso_mano_r.add_child(_arma_vista)
	else:
		_hands_root.add_child(_arma_vista)
	_aggiorna_arma_vista()


## Si chiama quando cambia l'arma in mano. Ricostruisce solo se è cambiata
## davvero: `cambia_arma` passa da qui a ogni pressione di [G], e rifare il
## nodo a ogni giro vorrebbe dire un `load()` per pressione.
func _aggiorna_arma_vista() -> void:
	if _arma_vista == null or not is_instance_valid(_arma_vista):
		return
	var mo: String = str(GameManager.arma_in_mano)
	if _arma_fp != null:
		_arma_fp.mostra(mo)
	if mo == _arma_mo:
		return
	_arma_mo = mo
	for c in _arma_vista.get_children():
		c.queue_free()
	if not ARMA_MODELLO.has(mo):
		return
	var r: Array = ARMA_MODELLO[mo]
	var m := Models.spawn(str(r[0]))
	if m == null:
		return
	var g: Vector3 = r[1]
	m.rotation = Vector3(deg_to_rad(g.x), deg_to_rad(g.y), deg_to_rad(g.z))
	m.position = r[2]
	_arma_vista.add_child(m)
	# **Sul corpo getta solo l'ombra** (0.61): quella che vedi tu è
	# `_arma_fp`. Se no guardandoti in giù ne vedevi due.
	_solo_ombra(m)


func _solo_ombra(n: Node) -> void:
	if n is GeometryInstance3D:
		(n as GeometryInstance3D).cast_shadow = \
			GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	for c in n.get_children():
		_solo_ombra(c)


func _build_paletta() -> void:
	_paletta = Node3D.new()
	_paletta.position = Vector3(0, 0.03, -0.06)
	if _osso_mano_r != null and is_instance_valid(_osso_mano_r):
		_osso_mano_r.add_child(_paletta)
	else:
		_hands_root.add_child(_paletta)

	# Il modello ha l'origine in fondo al manico, dove la stringe la mano,
	# e si sviluppa lungo il suo +Y (in Godot: verso l'alto). In mano
	# dev'essere puntata AVANTI, quindi si corica di novanta gradi.
	var m := Models.spawn("paletta")
	if m != null:
		m.rotation.x = deg_to_rad(-90)
		_paletta.add_child(m)
		_paletta.visible = GameManager.has_upgrade("paletta")
		return

	var handle := MeshInstance3D.new()
	var handle_mesh := CylinderMesh.new()
	handle_mesh.top_radius = 0.012
	handle_mesh.bottom_radius = 0.012
	handle_mesh.height = 0.22
	handle.mesh = handle_mesh
	handle.rotation.x = deg_to_rad(90)
	handle.position = Vector3(0, 0, -0.11)
	var handle_mat := StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.15, 0.15, 0.17)
	handle.material_override = handle_mat
	_paletta.add_child(handle)

	var disc := MeshInstance3D.new()
	var disc_mesh := CylinderMesh.new()
	disc_mesh.top_radius = 0.075
	disc_mesh.bottom_radius = 0.075
	disc_mesh.height = 0.012
	disc.mesh = disc_mesh
	disc.rotation.x = deg_to_rad(90)
	disc.position = Vector3(0, 0, -0.24)
	var disc_mat := StandardMaterial3D.new()
	disc_mat.albedo_color = Color(0.85, 0.12, 0.12)
	disc_mat.emission_enabled = true
	disc_mat.emission = Color(0.9, 0.15, 0.1)
	disc_mat.emission_energy_multiplier = 0.35
	disc.material_override = disc_mat
	_paletta.add_child(disc)

	var stripe := MeshInstance3D.new()
	var stripe_mesh := BoxMesh.new()
	stripe_mesh.size = Vector3(0.15, 0.02, 0.028)
	stripe.mesh = stripe_mesh
	stripe.position = Vector3(0, 0, -0.247)
	var stripe_mat := StandardMaterial3D.new()
	stripe_mat.albedo_color = Color(0.95, 0.95, 0.92)
	stripe.material_override = stripe_mat
	_paletta.add_child(stripe)

	_paletta.visible = GameManager.has_upgrade("paletta")


## **'E mmane.**
##
## Erano due scatole: un parallelepipedo da nove centimetri per il palmo e
## uno piu' piccolo per il polsino. In prima persona sono la cosa che si
## guarda piu' di ogni altra — stanno in fondo allo schermo per tutta la
## partita — e due scatole le riconosci come due scatole al primo secondo.
##
## Adesso sono mani vere: palmo con l'eminenza tenar (il cuscinetto alla
## base del pollice, che e' quello che da' alla mano la forma di mano e non
## di guanto da forno), quattro dita da tre falangi ciascuna piu' il
## pollice da due, nocche, unghie e polso.
##
## **Le proporzioni sono quelle di una mano vera**, in centimetri: medio da
## cinque piu' tre piu' due, indice e anulare appena piu' corti, mignolo
## tre e mezzo. Non e' pignoleria — se le dita sono tutte uguali la mano
## sembra un rastrello, ed e' il primo errore che si fa.
##
## Ogni falange e' appesa a un perno alla sua articolazione, quindi la mano
## si **chiude davvero**: `chiudi(t)` piega tutte e tre le falangi di ogni
## dito, con la prima che piega meno e l'ultima di piu', che e' come si
## chiude un pugno. Serve al pugno e alla presa dei carabinieri.
##
## Costo: una ventina di pezzi per mano, capsule da sei lati. Tremila
## triangoli in tutto per l'unico oggetto che il giocatore ha sempre a
## trenta centimetri dagli occhi.

## Le dita, in metri: [nome, lunghezze delle tre falangi, raggio alla base,
## quanto sta in la' rispetto al centro del palmo, quanto e' avanzata].
const DITA := [
	["indice",  [0.045, 0.025, 0.020], 0.0092,  0.028, -0.004],
	["medio",   [0.050, 0.030, 0.022], 0.0096,  0.009,  0.000],
	["anulare", [0.046, 0.028, 0.020], 0.0090, -0.010, -0.003],
	["mignolo", [0.035, 0.020, 0.017], 0.0078, -0.028, -0.010],
]
# ---------------------------------------------------------------------------
# 'E mmane fente se ne so' ghiute (0.54)
# ---------------------------------------------------------------------------
#
# **'O guaste: 'o giocatore teneva quatte braccia.**
#
# Il capo: *"Il player ha le braccia fuori dal corpo che ha già le sue
# braccia. Rifai le braccia in pov e fai che ne abbia solo due."*
#
# Il corpo in prima persona è il modello vero, con le sue braccia dentro
# alla mesh; sopra ci stavano due mani finte appese alla camera. Quattro.
# E la riga che avrebbe dovuto togliere le prime era questa:
#
#     for arm in _body_arms:
#         arm.visible = false
#
# `_body_arms` non sono le braccia: sono i **`BoneAttachment3D` delle
# mani**, cioè due nodi vuoti agganciati alle ossa. Spegnerli nasconde i
# loro figli — niente — e la geometria del braccio resta, perché il corpo
# è **una mesh skinnata sola** e un braccio non è un nodo che si spegne.
#
# È lo stesso identico guasto delle divise della 0.50 (`parts["legs"]`) e
# della camera POV della stessa versione (`_hide_above()`): **codice che
# sembra girare, gira, e non fa niente**, perché lavora su una mesh unica
# come se fosse un albero di pezzi.
#
# La cura non è nascondere meglio: è **non avere due mani in più**. Le
# braccia adesso sono quelle del corpo, e con loro si guadagna tutto
# quello che le mani finte non potevano avere — i pugni sono le clip vere
# della libreria (`Punch_Cross` e `Punch_Jab`), la camminata muove le
# braccia da sola, e la paletta e la sigaretta stanno appese alle ossa
# delle mani invece che a due nodi che si muovono per conto loro.



func _unhandled_input(event: InputEvent) -> void:
	# Esc (pausa/menu) è gestito dall'HUD.
	#
	# **'O click ca se ripiglia 'o mouse** (0.56b). Sul browser il Pointer
	# Lock si concede soltanto dentro a un gesto dell'utente, e si perde da
	# solo ogni volta che si preme Esc — che è anche il tasto della pausa,
	# quindi succede spesso. Qui si rimette: se il gioco lo vuole preso e il
	# browser non gliel'ha dato, **il primo click lo riprende**.
	#
	# Sta in `_unhandled_input` e non in `_input` apposta: così un click su
	# un bottone dell'interfaccia — cioè con un pannello aperto, cioè con il
	# mouse che serve libero — non arriva mai qua dentro.
	if event is InputEventMouseButton and event.pressed:
		if GameManager.arripiglia_o_mouse():
			# Il click è servito a riprendersi il mouse e basta: se passasse
			# oltre, il giocatore darebbe un pugno per sbaglio appena torna
			# nel gioco.
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_ruota(-event.relative.x * MOUSE_SENSITIVITY,
			-event.relative.y * MOUSE_SENSITIVITY)


## Camera con lo stick destro. Va nel `_process` e non negli eventi perche'
## uno stick tenuto fermo in una posizione non genera eventi nuovi: continua
## a essere spinto, e la camera deve continuare a girare.
func _guarda_col_joypad(delta: float) -> void:
	if GameManager.intro_active or get_tree().paused:
		return
	var stick := Input.get_vector("guarda_sinistra", "guarda_destra",
		"guarda_su", "guarda_giu")
	if stick.length_squared() < 0.0004:
		return
	var k: float = deg_to_rad(STICK_SENSITIVITY_DEG) * delta
	_ruota(-_curva(stick.x) * k, -_curva(stick.y) * k)


## Risposta non lineare: mantiene il segno e schiaccia i valori piccoli.
func _curva(v: float) -> float:
	return signf(v) * pow(absf(v), STICK_CURVE)


func _ruota(yaw: float, pitch: float) -> void:
	rotate_y(yaw)
	head.rotation.x = clamp(head.rotation.x + pitch,
		deg_to_rad(-PITCH_LIMIT_DEG), deg_to_rad(PITCH_LIMIT_DEG))


## **Preso in pieno: mezzo secondo, non un secondo e mezzo.**
##
## Farsi mettere sotto era la cosa piu' fastidiosa del gioco: un secondo e
## mezzo per terra con la camera di traverso e nessun controllo, piu'
## ventotto punti di ossa. In una giornata da quattro minuti erano dieci
## secondi buttati e mezza barra della salute, per una cosa che spesso ti
## capita mentre stai facendo tutt'altro.
##
## Deve restare una cosa da evitare — la botta si sente, la camera cade, il
## motorino ti urla dietro — ma non deve rovinare la partita. Adesso e' poco
## piu' di mezzo secondo, e il danno e' un terzo.
const KNOCK_DURATA: float = 0.55

func knock_down(push_dir: Vector3) -> void:
	if _knocked > 0.0:
		return
	_knocked = KNOCK_DURATA
	_knock_push = push_dir.normalized() * 5.2
	if directing_car != null and is_instance_valid(directing_car):
		directing_car.release_control()
		directing_car = null
	prompt_changed.emit("")


func _physics_process(delta: float) -> void:
	# **Assettato ô tavulo: nun se scappa.**
	#
	# Il capo: "quando si gioca a scopa non si esce mai dal tavolo". E
	# aveva ragione — il pannello delle carte prendeva il mouse ma le
	# gambe restavano libere: si poteva attraversare la città con la
	# partita aperta, e il vecchio restava lì a giocare da solo.
	#
	# Adesso sedersi a un tavolo **inchioda**: la posizione è quella della
	# sedia, i comandi di movimento non arrivano, e ci si alza solo
	# chiudendo la partita.
	if _inchiodato:
		global_position = _posto_fisso
		velocity = Vector3.ZERO
		return
	# **'A presa.** Ha la precedenza su tutto, appiglio compreso: se ti
	# tengono per il braccio non ti arrampichi da nessuna parte. Si resta
	# fermi, si può ancora guardare in giro (la camera è nell'`_input`, non
	# qui) e si martella il tasto del pugno per sciogliersi.
	if _presa_t > 0.0:
		velocity = Vector3.ZERO
		move_and_slide()
		if Input.is_action_just_pressed("punch") \
				or Input.is_action_just_pressed("jump"):
			# Nella presa secca il tasto si sente ma non serve: si mena e
			# non succede niente, che e' esattamente la sensazione giusta.
			if not _presa_secca:
				_presa_forza += PRESA_SPINTA
			SoundManager.pugno(-8.0)
			GameManager.screen_shake.emit(0.18)
			if _body_anim != null:
				_body_anim.action("punch")
		_presa_t -= delta
		var quanto: float = PRESA_SECCA if _presa_secca else PRESA_DURATA
		GameManager.presa_stato.emit(
			clampf(_presa_forza, 0.0, 1.0), _presa_t / quanto)
		if not _presa_secca and _presa_forza >= 1.0:
			_liberati()
		elif _presa_t <= 0.0:
			_ammanettato()
		return
	# L'appiglio ha la precedenza su tutto: mentre ci si tira su non c'e'
	# ne' gravita' ne' comandi, sono tre decimi di secondo di animazione.
	if _appiglio_t > 0.0:
		_appiglio_t -= delta
		var k: float = clampf(1.0 - _appiglio_t / APPIGLIO_DURATA, 0.0, 1.0)
		# Prima si sale, poi si va avanti: cosi' non si striscia dentro al
		# fianco dell'ostacolo mentre si sale.
		var su: float = clampf(k * 1.7, 0.0, 1.0)
		var avanti: float = clampf((k - 0.35) / 0.65, 0.0, 1.0)
		global_position = Vector3(
			lerpf(_appiglio_da.x, _appiglio_a.x, avanti),
			lerpf(_appiglio_da.y, _appiglio_a.y, su),
			lerpf(_appiglio_da.z, _appiglio_a.z, avanti))
		velocity = Vector3.ZERO
		if _appiglio_t <= 0.0:
			velocity.y = -0.5
		return
	if _knocked > 0.0:
		_knocked -= delta
		velocity.x = _knock_push.x
		velocity.z = _knock_push.z
		_knock_push = _knock_push.lerp(Vector3.ZERO, clamp(delta * 3.0, 0.0, 1.0))
		if is_on_floor():
			velocity.y = -0.5
		else:
			velocity.y -= GRAVITY * delta
		move_and_slide()
		# La testa "cade" di lato e si rialza piano
		var fall: float = clamp(_knocked / KNOCK_DURATA, 0.0, 1.0)
		head.rotation.z = deg_to_rad(55.0) * fall
		head.position.y = STAND_HEAD_Y - 0.75 * fall
		if _knocked <= 0.0:
			head.rotation.z = 0.0
			head.position.y = STAND_HEAD_Y
			_crouch_blend = 0.0
		return

	# **'A sedia.** Finché stai seduto non lavori: non ti muovi, non dirigi
	# nessuno, non ti si aggancia niente. In cambio il sospetto cala tre
	# volte più in fretta di una sigaretta e le ossa si rimettono a posto
	# da sole. È il modo povero di curarsi: gratis, ma ti costa il tempo,
	# ed è esattamente il tempo in cui le auto arrivano lo stesso.
	if _seduto:
		_riposa(delta)
		return

	if directing_car != null and is_instance_valid(directing_car) and directing_car.is_being_directed():
		_handle_directing(delta)
		return
	if directing_car != null:
		directing_car = null # l'auto ha finito da sola (parcheggiata o andata via): il player riprende il controllo

	_handle_movement(delta)
	_keep_in_bounds()

	# Piazzamento: il fantasma segue lo sguardo, il click appoggia.
	if is_placing():
		_update_placing()
		if Input.is_action_just_pressed("punch"):
			_confirm_placing()
		_update_interaction()
		return

	_update_interaction()

	# La rotella scorre quello che tieni in mano, avanti e indietro; G fa
	# la stessa cosa in avanti, per chi il mouse non ce l'ha (o gioca col
	# pad). Sono tre modi per la stessa azione, e va bene cosi': la rotella
	# e' quella che si prova per prima.
	var passo_arma := 0
	if Input.is_action_just_pressed("arma_su"):
		passo_arma = -1
	elif Input.is_action_just_pressed("arma_giu"):
		passo_arma = 1
	elif Input.is_action_just_pressed("arma"):
		passo_arma = 1
	if passo_arma != 0 and not _pickpocket_open():
		GameManager.cambia_arma(passo_arma)
		_aggiorna_arma_vista()
		SoundManager.play("pop", -10.0, 1.2)
		GameManager.event_started.emit("Mo' tiene: %s" % GameManager.arma_nome())
	if Input.is_action_just_pressed("interact") and current_target and current_target.has_method("player_interact"):
		current_target.player_interact()
		if current_target.has_method("is_being_directed") and current_target.is_being_directed():
			directing_car = current_target
			prompt_changed.emit("W vai · S aspetta · A/D gira · F o SPAZIO = \"mettila ccà\" · E lassa sta'")

	if Input.is_action_just_pressed("vandalize") and current_target and current_target.has_method("player_vandalize"):
		current_target.player_vandalize()

	# **'O stemma s'è pigliato 'nu tasto sujo** (0.57). Prima stava su [E],
	# insieme a tutto il resto; da quando qualunque macchina parcheggiata si
	# può scassare, [E] è il furto dell'auto e lo stemma si stacca con [H].
	# Due gesti diversi sullo stesso oggetto vogliono due tasti, se no il
	# gioco decide per te quale dei due volevi fare.
	if Input.is_action_just_pressed("stemma") and current_target \
			and current_target.has_method("player_stemma"):
		current_target.player_stemma()

	if Input.is_action_just_pressed("punch") and not _pickpocket_open() \
			and not is_placing():
		# **'O tiempo fra 'nu colpo e n'ato, e 'o sciato** (0.56).
		#
		# Prima bastava `_punch_timer`, che a 0,62 secondi voleva dire
		# quasi due colpi al secondo: il tasto sinistro tenuto premuto era
		# la risposta a qualunque problema del gioco. Adesso ci sono due
		# freni, e fanno cose diverse — il tempo impedisce di **pigiare**,
		# il fiato impedisce di **continuare**.
		if _punch_timer > 0.0:
			pass
		elif not GameManager.pò_menà():
			_senza_sciato()
		else:
			_throw_punch()

	if Input.is_action_just_pressed("smoke"):
		_light_cigarette()

	if Input.is_action_just_pressed("fischio"):
		_fischia()

	if Input.is_action_just_pressed("caffe"):
		_bevi_caffe()

	# Fumare rilassa: il sospetto cala più in fretta finché tieni la
	# sigaretta in mano (sembri uno del quartiere in pausa, non uno al lavoro).
	if _smoking > 0.0:
		_smoking -= delta
		is_smoking = true
		GameManager.cool_down(SMOKE_COOL_BONUS * delta)
		_cig_ember.scale = Vector3.ONE * (1.0 + sin(_hands_time * 2.2) * 0.25)
		if _smoking <= 0.0:
			is_smoking = false
			_cig_root.visible = false
			_cig_smoke.emitting = false


## Pugno (tasto sinistro): parte sempre l'animazione; se nel mirino c'è un
## autista a portata, lo becca.
# ---------------------------------------------------------------------------
# Piazzare le decorazioni comprate al Bazar
# ---------------------------------------------------------------------------

## Entra in modalità piazzamento con l'oggetto scelto nello zaino. Da qui,
## un fantasma segue il punto che stai guardando e il click lo appoggia.
func start_placing(decor_id: String) -> void:
	_placing_id = decor_id
	if _place_ghost and is_instance_valid(_place_ghost):
		_place_ghost.queue_free()
	_place_ghost = _build_ghost(decor_id)
	get_parent().add_child(_place_ghost)
	_place_giro = 0.0
	prompt_changed.emit("Guarda addò 'a vuò · ROTELLA gira · CLICK appoggia · ESC lassa sta'")


## Di quanto e' stato girato l'oggetto con la rotella, rispetto a come sta
## girato il giocatore.
var _place_giro: float = 0.0


func cancel_placing() -> void:
	_placing_id = ""
	if _place_ghost and is_instance_valid(_place_ghost):
		_place_ghost.queue_free()
	_place_ghost = null
	prompt_changed.emit("")


func is_placing() -> bool:
	return _placing_id != ""


## Il fantasma: una sagoma verde trasparente della misura giusta, più una
## croce a terra. Non serve che sia il modello vero — serve che si capisca
## dove finirà e quanto spazio occupa.
func _build_ghost(decor_id: String) -> Node3D:
	var root := Node3D.new()
	var size: Vector3 = DECOR_FOOTPRINT.get(decor_id, Vector3(0.8, 1.0, 0.8))

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.95, 0.45, 0.36)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	# **Il fantasma e' l'oggetto vero, verniciato di verde.**
	#
	# Era una scatola con l'ingombro giusto: sapevi quanto spazio prendeva
	# ma non come sarebbe venuto, e soprattutto non da che parte era
	# girato. Adesso e' il modello, trasparente: vedi la sdraio prima di
	# appoggiarla, e vedi dove guarda.
	var vero := Models.spawn(decor_id if decor_id != "piante" else "pianta")
	if vero != null:
		_tinge_tutto(vero, mat)
		root.add_child(vero)
	else:
		var box := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = size
		box.mesh = bm
		box.position = Vector3(0, size.y * 0.5, 0)
		box.material_override = mat
		root.add_child(box)

	var pad := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(size.x + 0.3, size.z + 0.3)
	pad.mesh = pm
	pad.position = Vector3(0, 0.03, 0)
	var pad_mat := StandardMaterial3D.new()
	pad_mat.albedo_color = Color(0.2, 1.0, 0.4, 0.5)
	pad_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pad_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pad.material_override = pad_mat
	root.add_child(pad)
	return root


## Il fantasma segue il punto di terra che stai guardando, a distanza
## limitata: non si può piazzare una sedia dall'altra parte della piazza.
## Vernicia di verde ogni pezzo del fantasma, a qualunque profondita' stia.
func _tinge_tutto(nodo: Node, mat: Material) -> void:
	if nodo is MeshInstance3D:
		(nodo as MeshInstance3D).material_override = mat
	for c in nodo.get_children():
		_tinge_tutto(c, mat)


func _update_placing() -> void:
	if _place_ghost == null or not is_instance_valid(_place_ghost):
		return
	var from := camera.global_position
	var dir := -camera.global_transform.basis.z
	# Punto sul piano y=0 lungo lo sguardo. Se guardi in su o troppo dritto,
	# si mette semplicemente davanti ai piedi.
	var target: Vector3
	if dir.y < -0.05:
		var t: float = from.y / -dir.y
		target = from + dir * minf(t, PLACE_MAX_DIST)
	else:
		target = global_position + Vector3(dir.x, 0, dir.z).normalized() * 2.5
	target.y = 0.0
	# Mai troppo lontano da te
	var away: Vector3 = target - global_position
	away.y = 0.0
	if away.length() > PLACE_MAX_DIST:
		target = global_position + away.normalized() * PLACE_MAX_DIST
		target.y = 0.0
	# **La rotella gira l'oggetto.**
	#
	# Prima l'oggetto prendeva la direzione del giocatore e basta: per
	# girare una sdraio dovevi girarti tu, e siccome il fantasma segue lo
	# sguardo, girandoti si spostava pure. Adesso la rotella lo ruota di
	# quindici gradi per scatto e la posizione resta ferma.
	if Input.is_action_just_pressed("arma_su"):
		_place_giro += deg_to_rad(15.0)
	elif Input.is_action_just_pressed("arma_giu"):
		_place_giro -= deg_to_rad(15.0)
	elif Input.is_action_just_pressed("arma"):
		_place_giro += deg_to_rad(45.0)
	_place_ghost.global_position = target
	_place_ghost.rotation.y = rotation.y + _place_giro


func _confirm_placing() -> void:
	if _place_ghost == null or not is_instance_valid(_place_ghost):
		return
	var pos: Vector3 = _place_ghost.global_position
	var rot: float = _place_ghost.rotation.y
	var id := _placing_id
	cancel_placing()
	GameManager.place_decor(id, pos, rot)
	SoundManager.play("pop", -6.0, 0.9)
	GameManager.directing_gesture.emit("Ecco fatto. Sta bbuono llà.", false)


## Vero mentre è a schermo la barra del borseggio: in quel momento il click
## serve a fermare il cursore, non a menare.
func _pickpocket_open() -> bool:
	var hud := get_parent().get_node_or_null("HUD")
	return hud != null and hud.has_method("is_pickpocket_open") \
		and hud.is_pickpocket_open()


## Vero se a schermo c'e' un listino, lo zaino o il dialogo col boss.
##
## Serve al joypad: la croce/A e' insieme "salta" e "conferma", quindi senza
## questo controllo ogni acquisto veniva accompagnato da un saltello, e
## rispondere a Borrelli faceva fare un salto in faccia a Borrelli.
func _menu_aperto() -> bool:
	var hud := get_parent().get_node_or_null("HUD")
	return hud != null and hud.has_method("menu_open") and hud.menu_open()


## Menare, a mani nude o con quello che tieni in mano.
##
## Il colpo è sempre lo stesso gesto: cambia quanto fa male, da quanto
## lontano arriva e quanto rumore fa. Il rumore è la parte che conta —
## il calore che alza un colpo di pistola è otto volte quello di un pugno,
## ed è quello che rende comprare una piazza un'alternativa sensata anche
## quando il fierro ce l'hai già in tasca.
## **Perché i pugni non incatenano più.**
##
## Fino alla 0.44 il combattimento risolveva tutto: mezzo secondo di
## click ripetuti e chiunque — l'autista, il rivale, perfino il vigile —
## finiva per terra senza mai riuscire a rispondere. Un pugno ogni tre
## decimi, danno pieno ogni volta, e nessuna finestra in cui l'altro
## potesse fare qualcosa. Il risultato è che tutto il sistema del vigile
## — leggerlo, aspettarlo, mentirgli — si poteva saltare a mani nude.
##
## Due numeri e il problema sparisce:
##
## 1. **Il colpo è più lento**: 0,62 s invece di 0,30. Un pugno vero non
##    si tira due volte al secondo.
## 2. **I colpi in fila valgono sempre meno.** Il primo fa danno pieno, il
##    secondo il 62%, il terzo il 38%, il quarto il 24%. Non è una regola
##    astratta: è che uno che le sta prendendo si copre. Dopo due secondi
##    senza colpirlo il conto si azzera e si riparte da capo.
##
## Insieme vogliono dire che a mani nude un rivale non si stende più: gli
## si fa male, lui risponde, e a un certo punto conviene decidere se vale
## la pena. Che è esattamente la domanda che il gioco deve fare.
## **'O tiempo fra 'nu pugno e n'ato.**
##
## Era 0,62 — quasi due colpi al secondo, cioè il tasto sinistro tenuto
## premuto. Il capo: *"devi rallentare l'animazione del pugno del player
## in modo che non si possa spammare"*. Uno e un decimo è il tempo che ci
## mette davvero una clip di `Punch_Cross` a finire, e da qui il colpo si
## **vede** tutto invece di essere interrotto dal successivo.
##
## Le armi sono più svelte a modo loro: il coltello è una stoccata corta.
const PUNCH_CD: float = 1.10
## Quanto è più svelto chi tiene qualcosa in mano.
const PUNCH_CD_ARMA: float = 0.82

## 'O sciato a zero: nun se mena, e se dice pecché.
var _senza_sciato_cd: float = 0.0


func _senza_sciato() -> void:
	_punch_timer = 0.45
	if _senza_sciato_cd > 0.0:
		return
	_senza_sciato_cd = 3.5
	SoundManager.play_uno(["fiatone", "schiarisce"], -5.0)
	GameManager.event_started.emit("Nun tiene cchiù sciato. Piglia 'nu cafè.")
const CATENA_FINESTRA: float = 2.0
const CATENA_CALO := [1.0, 0.62, 0.38, 0.24, 0.16]

var _catena_su: Node = null
var _catena_n: int = 0
var _catena_t: float = 0.0


func _throw_punch() -> void:
	_punch_timer = PUNCH_CD_ARMA if GameManager.arma_in_mano != "" else PUNCH_CD
	GameManager.consuma_sciato(GameManager.sciato_colpo())
	# Il corpo tira il colpo insieme alle mani in prima persona: chi guarda
	# in giù mentre mena vede la spalla partire, non solo il guanto.
	#
	# E il colpo cambia con quello che tieni in mano: a mani nude e con la
	# mazza parte il diretto, col curtiello la stoccata bassa. Sono due
	# catture di movimento diverse, e si vede.
	# **Destro, sinistro, destro.** Un pugno solo ripetuto è un tasto
	# premuto due volte; due clip che si alternano sono una scazzottata.
	# Il conto si azzera da solo quando smetti (`_catena_t`), quindi il
	# primo colpo di ogni rissa è sempre il destro — che è quello che uno
	# tira per primo.
	if _body_anim != null:
		if GameManager.arma_in_mano == "curtiello":
			_body_anim.action("coltellata")
		else:
			_body_anim.action("pugno_sinistro" if _catena_n % 2 == 1 else "pugno")
	# E il fierro che vedi tu fa il colpo suo (0.61).
	if _arma_fp != null:
		_arma_fp.colpo()
	if GameManager.arma_in_mano != "" and not GameManager.arma_a_distanza():
		SoundManager.play("woosh", -6.0, 1.15 if GameManager.arma_in_mano == "curtiello" else 0.9)
	# E la camera rincula: mezzo grado di scatto all'indietro. È poco
	# apposta — un pugno non è uno sparo — ma senza, in prima persona il
	# colpo non si sente partire.
	GameManager.screen_shake.emit(0.22)

	var danno: int = GameManager.arma_danno()
	var portata: float = maxf(PUNCH_RANGE, GameManager.arma_portata())

	# Il calo dei colpi in fila. Vale solo per il corpo a corpo: sparare
	# ripetutamente non è "incatenare", è avere una pistola.
	if not GameManager.arma_a_distanza():
		if current_target != _catena_su or _catena_t <= 0.0:
			_catena_su = current_target
			_catena_n = 0
		_catena_t = CATENA_FINESTRA
		var k: float = float(CATENA_CALO[mini(_catena_n,
			CATENA_CALO.size() - 1)])
		_catena_n += 1
		danno = maxi(1, int(round(float(danno) * k)))

	if GameManager.arma_a_distanza():
		_spara(danno, portata)
		return

	if current_target and current_target.has_method("receive_punch") \
			and global_position.distance_to(current_target.global_position) \
				<= portata:
		current_target.receive_punch(danno)
		GameManager.colpo_a_segno.emit(danno)
		if danno > 1:
			SoundManager.pugno(-1.0)
			GameManager.add_heat(GameManager.arma_calore() * 0.35)
	else:
		# **Il pugno a vuoto ha un suono suo.** Sembra un dettaglio da
		# niente e invece e' informazione: senza, non si capisce se hai
		# mancato o se il gioco non ha registrato il click.
		SoundManager.vuoto()


## Il colpo a distanza. Non usa `current_target` come il pugno: quello è il
## bersaglio dell'interazione, che si aggancia solo a tre metri. Qui si
## spara un raggio dalla telecamera fino alla portata dell'arma, ed è quello
## che rende la pistola una cosa DIVERSA da una mazza lunga.
func _spara(danno: int, portata: float) -> void:
	var kalash: bool = GameManager.arma_in_mano == "kalash"
	SoundManager.play("sparo", 0.0 if kalash else -2.0, 0.78 if kalash else 1.0)
	GameManager.screen_shake.emit(0.75 if kalash else 0.45)
	# Sparare in mezzo alla strada è la cosa più rumorosa che ci sia in
	# questo gioco: mezzo quartiere ti ha sentito, anche se non ti ha visto.
	GameManager.add_heat(GameManager.arma_calore())
	# Uno sparo in mezzo a un vicolo lo sente tutto il quartiere, e non
	# serve nemmeno che ti abbiano visto: chi ha sentito chiama.
	GameManager.crimine(1.8)

	var spazio := get_world_3d().direct_space_state
	var da := camera.global_position
	var a := da - camera.global_transform.basis.z * portata
	var q := PhysicsRayQueryParameters3D.create(da, a, LAYER_WORLD | LAYER_CAR)
	q.exclude = [get_rid()]
	var r := spazio.intersect_ray(q)
	# **'A scia** (0.61): dalla bocca della canna fino a dove arriva il
	# colpo, e le scintille là. Mancare e colpire adesso si vedono.
	var fine: Vector3 = a
	if not r.is_empty() and r.has("position"):
		fine = r["position"]
	var c = null if r.is_empty() else r.get("collider")
	var preso: bool = c != null and c.has_method("receive_punch")
	var da_bocca: Vector3 = da
	if _arma_fp != null and _arma_fp.visible:
		da_bocca = _arma_fp.bocca_nel_mondo()
	ArmaFp.scia(get_parent(), da_bocca, fine, preso)
	if preso:
		c.receive_punch(danno)
		GameManager.colpo_a_segno.emit(danno)


## Mentre si dirige un'auto, il player resta fermo sul posto (WASD passa al
## controllo dell'auto tramite car_3d.gd, che legge lo stesso Input diretto):
## qui si aggiorna solo la fisica minima (gravità) e si gestisce E per
## mollare la presa e tornare al controllo normale del player.
func _handle_directing(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if is_on_floor():
		velocity.y = -0.5
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()

	if Input.is_action_just_pressed("interact"):
		directing_car.release_control()
		# Durante il park-assist finale la presa non si può più mollare
		# (l'autista sta completando da solo): si sgancia solo se l'auto
		# è davvero tornata in attesa.
		if not directing_car.is_being_directed():
			directing_car = null
			prompt_changed.emit("")


## Paracadute: se malgrado i muri invisibili si finisce sotto il piano di
## calpestio o troppo fuori dai bordi, si torna al punto di partenza invece
## di cadere per sempre.
## Il paracadute. I muri invisibili della piazza reggono a qualunque spinta
## — misurato: otto direzioni a 40 m/s con salti, non si passa. Ma se ci si
## finisce oltre lo stesso (la botta del motorino, un angolo fra due
## collider, un'auto che ti incastra), prima si restava là fuori a
## camminare sul pavimento di riserva, perche' questo controllo tollerava
## sei metri di margine e scattava solo sotto quota −4.
##
## Adesso il margine e' un metro e mezzo e la correzione e' dolce: si viene
## rimessi al bordo piu' vicino, non catapultati al punto di partenza. Il
## teletrasporto resta solo per il caso vero di caduta.
const MARGINE_FUORI: float = 1.5
const QUOTA_CADUTA: float = -1.5

## **Quando qualcuno ti ferma, ti giri.**
##
## Prima il vigile arrivava, apriva il dialogo, e tu restavi girato
## dall'altra parte a dirigere una macchina mentre a schermo comparivano
## quattro risposte da scegliere. Adesso il gioco ti mette la faccia dove
## deve stare — verso chi ti sta parlando — e ti toglie di mano quello che
## stavi facendo: la macchina che stavi dirigendo la molli, l'oggetto che
## stavi appoggiando torna nello zaino, la corsa si ferma.
##
## Non è cortesia: è che una conversazione in cui puoi continuare a
## lavorare non è una conversazione, e il vigile smetteva di essere un
## problema.
func guarda_verso(chi: Node3D, brusco: bool = false) -> void:
	if chi == null or not is_instance_valid(chi):
		return
	var d: Vector3 = chi.global_position - global_position
	d.y = 0.0
	if d.length() < 0.05:
		return
	_mira_verso = atan2(-d.x, -d.z)
	# Anche la testa: chi ti parla è alto quanto te, quindi si guarda
	# dritto, non per terra.
	var occhio: float = camera.global_position.y - global_position.y
	var dislivello: float = (chi.global_position.y + 1.55) 		- (global_position.y + occhio)
	_mira_alto = clampf(atan2(dislivello, d.length()), -0.5, 0.5)
	_mira_tempo = 0.01 if brusco else 0.32


## Molla tutto: la macchina che stavi dirigendo, l'oggetto in mano, la
## corsa. Si chiama quando qualcuno ti mette le mani addosso.
## Inchioda il giocatore a un posto: sedersi a un tavolo, farsi ammanettare.
## `guarda` è il punto verso cui girarsi.
func siediti(dove: Vector3, guarda: Vector3) -> void:
	_inchiodato = true
	_posto_fisso = dove
	var d: Vector3 = guarda - dove
	if d.length() > 0.05:
		rotation.y = atan2(-d.x, -d.z)
	velocity = Vector3.ZERO


func alzati() -> void:
	_inchiodato = false


func sta_inchiodato() -> bool:
	return _inchiodato


func interrompi_tutto() -> void:
	if directing_car != null and is_instance_valid(directing_car):
		if directing_car.has_method("release_control"):
			directing_car.release_control()
		directing_car = null
	if is_placing():
		cancel_placing()
	if _seduto:
		_alzate()
	prompt_changed.emit("")


var _mira_verso: float = 0.0
var _mira_alto: float = 0.0
var _mira_tempo: float = 0.0


func _mira_forzata(delta: float) -> void:
	if _mira_tempo <= 0.0:
		return
	var k: float = clampf(delta / maxf(_mira_tempo, 0.001), 0.0, 1.0)
	rotation.y = lerp_angle(rotation.y, _mira_verso, k)
	camera.rotation.x = lerpf(camera.rotation.x, _mira_alto, k)
	_mira_tempo = maxf(0.0, _mira_tempo - delta)


func _keep_in_bounds() -> void:
	# **Dentro al vascio i confini non valgono.** L'interno di casa e'
	# costruito fuori dalla pianta della citta' (vedi vascio_3d.gd): senza
	# questa riga il controllo dei bordi ti riporterebbe in piazza un
	# fotogramma dopo essere entrato, e la porta di casa non si aprirebbe
	# mai.
	if GameManager.dentro_casa:
		return
	# I confini adesso sono quelli della citta', non della piazza: la
	# piazza e' solo il primo quartiere e uscirne e' proprio lo scopo.
	var citta := get_parent().get_node_or_null("Citta")
	var w: float
	var l: float
	var casa: Vector3
	# Il bordo verso il mare non e' zero: di la' c'e' il lungomare, e ci si
	# deve poter camminare. Lo dice la citta', che sa dove finisce la
	# passeggiata.
	var nord: float = -MARGINE_FUORI
	if citta != null:
		w = citta.LARGHEZZA
		l = citta.PROFONDITA
		casa = citta.get_player_start()
		nord = citta.LIMITE_NORD
	else:
		var zone := get_parent().get_node_or_null("ZoneVicolo")
		if zone == null:
			return
		w = zone.width
		l = zone.length
		casa = zone.get_player_start()
	var p := global_position

	if p.y < QUOTA_CADUTA:
		# Caduta vera: si torna in mezzo alla piazza.
		global_position = casa + Vector3(0, 0.6, 0)
		velocity = Vector3.ZERO
		prompt_changed.emit("Stavi asciuto fore 'a piazza. T'aggio riportato ccà.")
		return

	var dentro_x: float = clampf(p.x, -MARGINE_FUORI, w + MARGINE_FUORI)
	var dentro_z: float = clampf(p.z, nord, l + MARGINE_FUORI)
	if is_equal_approx(dentro_x, p.x) and is_equal_approx(dentro_z, p.z):
		return

	# Fuori dai bordi ma ancora in piedi: rientro morbido verso il campo,
	# senza togliere il controllo.
	global_position = Vector3(dentro_x, maxf(p.y, 0.2), dentro_z)
	velocity.x = 0.0
	velocity.z = 0.0
	prompt_changed.emit("E addò vaje? 'A piazza sta ccà.")


func _handle_movement(delta: float) -> void:
	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()

	var forward := -transform.basis.z
	var right := transform.basis.x
	var move_dir := (right * input_dir.x + forward * -input_dir.y)
	move_dir.y = 0.0
	if move_dir.length() > 0.001:
		move_dir = move_dir.normalized()

	# C tiene giù: accovacciato si va piano e la testa scende.
	is_crouching = Input.is_action_pressed("crouch")
	var speed: float = WALK_SPEED
	if is_crouching:
		speed = CROUCH_SPEED
	elif Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	# Il caffè in corpo si sente nelle gambe, ma non da accovacciato.
	if GameManager.caffe_boost > 0.0 and not is_crouching:
		speed *= CAFFE_SPINTA

	velocity.x = move_dir.x * speed
	velocity.z = move_dir.z * speed

	if is_on_floor():
		# SPAZIO: un saltello. Serve a scavalcare i cordoli, a schivare il
		# motorino all'ultimo e a tirare il pallone al volo.
		if Input.is_action_just_pressed("jump") and not is_crouching \
				and not _menu_aperto():
			if not _prova_appiglio():
				velocity.y = JUMP_SPEED
				SoundManager.play("pop", -16.0, 1.4)
		else:
			velocity.y = -0.5
	else:
		# Anche a mezz'aria: si salta contro il cofano e col secondo tocco
		# ci si tira su. E' il gesto che viene naturale a chi ci prova.
		if Input.is_action_just_pressed("jump") and not _menu_aperto():
			if _prova_appiglio():
				return
		velocity.y -= GRAVITY * delta

	_scalino(delta)
	move_and_slide()
	_update_crouch_pose(delta)
	_animate_body(delta, move_dir.length() > 0.1 and is_on_floor(), speed)
	_update_footsteps(delta,
		move_dir.length() > 0.1 and is_on_floor() and not is_crouching, speed)


## **'O scalino: salire sui gradini bassi senza saltare.**
##
## Un `CharacterBody3D` di Godot non ha lo step-up: qualunque faccia
## verticale e' un muro, che sia alta tre metri o sedici centimetri. In una
## citta' fatta di cordoli, soglie di negozio, gradinate, basi di
## lampione e cassette per terra, questo vuol dire decine di punti in cui
## semplicemente ti fermi — e non capisci perche', perche' l'ostacolo e'
## piu' basso della caviglia.
##
## Questa e' la funzione che mancava. Prima di muoversi si prova: se
## andando avanti si sbatte, ma alzandosi di trenta centimetri NON si
## sbatte piu' e sopra la testa c'e' spazio, allora quello non e' un muro —
## e' un gradino, e ci si sale. Trenta centimetri e' il massimo: piu' in su
## si comincia a scalare i muretti, che e' un altro mestiere (quello lo fa
## l'appiglio, con SPAZIO).
const SCALINO_MAX: float = 0.30

func _scalino(delta: float) -> void:
	if not is_on_floor():
		return
	var avanti := Vector3(velocity.x, 0.0, velocity.z)
	if avanti.length_squared() < 0.04:
		return
	# Quanto ci si muovera' in questo passo, piu' un dito di margine.
	var passo: Vector3 = avanti.normalized() * (avanti.length() * delta + 0.06)
	if not test_move(global_transform, passo):
		return   # strada libera: non c'e' niente da scavalcare
	var su := global_transform
	su.origin += Vector3(0, SCALINO_MAX, 0)
	# C'e' spazio sopra la testa? Se no si sta sotto a qualcosa, e alzarsi
	# vorrebbe dire incastrarsi.
	if test_move(global_transform, Vector3(0, SCALINO_MAX, 0)):
		return
	if test_move(su, passo):
		return   # e' un muro vero, non un gradino
	# E' un gradino. Si sale: la gravita' del frame dopo riappoggia i piedi.
	global_position.y += SCALINO_MAX


## La testa che scende e risale, morbida: senza interpolazione il passaggio
## fra in piedi e accovacciato è uno scatto che dà fastidio.
func _update_crouch_pose(delta: float) -> void:
	var target: float = 1.0 if is_crouching else 0.0
	_crouch_blend = move_toward(_crouch_blend, target, delta * 6.0)
	head.position.y = lerpf(STAND_HEAD_Y, CROUCH_HEAD_Y, _crouch_blend)


## I passi: tasche piene di monetine, e si sentono. Il passo si accorcia
## quando corri e il volume sale un po' con i soldi che hai addosso — a
## borsello vuoto tintinni molto meno.
func _update_footsteps(delta: float, walking: bool, speed: float) -> void:
	if not walking:
		# Fermo: il prossimo passo parte quasi subito, non a metà ciclo.
		_step_cd = minf(_step_cd, 0.12)
		return
	_step_cd -= delta
	if _step_cd > 0.0:
		return
	_step_cd = STEP_INTERVAL * (WALK_SPEED / maxf(speed, 0.1))
	# Da -20 dB a borsello vuoto fino a -9 dB quando sei carico.
	var loot: float = clampf(float(GameManager.money) / 60.0, 0.0, 1.0)
	# **'O borsello.** Gli spiccioli stanno chiusi invece che sciolti in
	# tasca: cammini quasi in silenzio anche con duecento euro addosso.
	# Non è solo estetica — il tintinnio è il segnale con cui il gioco dice
	# "sei carico", e chi porta il borsello quel segnale non lo dà.
	if GameManager.has_upgrade("borsello"):
		loot *= 0.25
	SoundManager.play("spiccioli", -20.0 + loot * 11.0,
		randf_range(0.9, 1.12), 0.04)


## Che tipo di negozio stiamo guardando (stringa vuota se nessuno).
func _shop_kind(node: Node) -> String:
	if node == null or not is_instance_valid(node):
		return ""
	if node.is_in_group("bazar"):
		return "bazar"
	if node.is_in_group("tabaccheria"):
		return "tabacchi"
	if node.is_in_group("shop"):
		return "zio"
	return ""


## **La lista dei bersagli agganciabili.**
##
## Qui dentro mancavano i rivali, ed e' il motivo per cui "non si possono
## toccare": tutta la meccanica per comprare o prendere una piazza era
## scritta e funzionante dentro a `rivale_3d.gd`, ma senza il gruppo in
## questa lista il raggio non lo agganciava mai. Niente scritta a schermo,
## niente E che facesse qualcosa, e nemmeno il pugno — che parte da
## `current_target` e quindi non trovava nessuno. Una meccanica intera
## invisibile per una riga.
##
## Ci sono anche i carabinieri, a piedi e in furgone, che avevano lo stesso
## identico problema.
## **La lista bianca dei bersagli, e perché è la riga più pericolosa del
## file.**
##
## Il raggio dell'interazione trova qualunque collider, ma poi `_bersaglio_
## valido` scarta tutto quello che non sta in uno di questi gruppi. È giusto
## che sia così — se no si "interagirebbe" con i muri — ma vuol dire che
## **una cosa nuova con cui si può parlare non funziona finché il suo gruppo
## non sta scritto qui dentro**, e non dà nessun errore: semplicemente non
## succede niente quando premi E.
##
## Nella 0.44 ci sono cascato in pieno: porta di casa, letto, moglie,
## criature, tavolini della scopa e segni delle commissioni erano tutti
## costruiti bene, rispondevano tutti a `get_interact_prompt`, e nessuno dei
## sei era agganciabile. Se aggiungi qualcosa di interattivo, la riga da
## toccare è questa.
const GRUPPI_BERSAGLIO: Array[StringName] = [
	&"cars", &"drivers", &"shop", &"vigili", &"borrelli", &"signore",
	&"manifesti", &"rivali", &"sbirri", &"carabinieri", &"attivita",
	&"decoro", &"guagliuni",
	# --- 'A casa e 'e ccose nove d''a 0.44 ---
	&"porte_casa", &"letto", &"moglie", &"criature",
	&"tavoli_scopa", &"punti_cummissione",
	# --- 'A bacheca e 'o garage d''a 0.45 ---
	# **Leggere il commento sopra prima di aggiungere una cosa nuova.** Un
	# oggetto interattivo che non sta in questa lista non da' nessun errore
	# e non fa niente: il raggio lo trova, `_bersaglio_valido()` lo butta, e
	# uno passa mezz'ora a cercare il bug nell'oggetto. E' successo con
	# tutt'e sei le cose della 0.44.
	&"bacheche", &"garage",
	# --- 'O vicinato d''a 0.54 ---
	&"vicine",
	# --- 'A Signora d''e nummere e 'e boss 'e capitolo (0.55) ---
	&"signora_lotto", &"boss_capitolo", &"maestro",
	# --- 'E perzone nove d''a 0.61 ---
	&"nuovi_abusivi", &"turisti_spierze", &"panari",
]

## Quanto si può essere storti col mirino e agganciare lo stesso. Il coseno
## di ~34°: abbastanza per perdonare un dislivello o una capa che si muove,
## poco perché non si agganci qualcuno che sta di lato.
const MIRA_LARGA: float = 0.83


static func _bersaglio_valido(n: Node) -> bool:
	for g in GRUPPI_BERSAGLIO:
		if n.is_in_group(g):
			return true
	return false


## Il ripiego quando il raggio non becca nessuno.
##
## Il raggio secco è preciso ma spietato: basta salire su un marciapiede e
## la telecamera passa SOPRA la testa del rivale (misurato: occhio a 1,97,
## capa del rivale a 1,88 — dieci centimetri, e la meccanica sparisce).
## Stessa storia guardando appena in su, o se quello si accovaccia.
##
## Allora: se il raggio non trova niente di agganciabile, si guarda chi c'è
## davvero lì davanti. Si prendono tutti i bersagli a portata, si tiene chi
## sta dentro al cono dello sguardo, e fra quelli il più centrato. Prima di
## darlo per buono si controlla che in mezzo non ci sia un muro — se no si
## parlerebbe con la gente attraverso le persiane.
func _bersaglio_vicino(reach: float) -> Node:
	var occhio := camera.global_position
	var avanti := -camera.global_transform.basis.z
	var migliore: Node = null
	var punteggio: float = MIRA_LARGA
	var spazio := get_world_3d().direct_space_state
	for g in GRUPPI_BERSAGLIO:
		for n in get_tree().get_nodes_in_group(g):
			if not (n is Node3D) or not is_instance_valid(n):
				continue
			# Si mira al petto, non ai piedi: l'origine di un pedone sta a
			# terra e da vicino risulterebbe sempre "sotto" allo sguardo.
			var centro: Vector3 = (n as Node3D).global_position + Vector3(0, 1.05, 0)
			var verso: Vector3 = centro - occhio
			var dist: float = verso.length()
			if dist > reach or dist < 0.001:
				continue
			var allineato: float = avanti.dot(verso / dist)
			if allineato <= punteggio:
				continue
			var q := PhysicsRayQueryParameters3D.create(occhio, centro, LAYER_WORLD)
			q.exclude = [get_rid()]
			var muro := spazio.intersect_ray(q)
			# Un pelo di tolleranza: il collider del bersaglio stesso non
			# deve contare come muro, e i muri sono su LAYER_WORLD.
			if muro and muro.has("collider") and muro["collider"] != n:
				continue
			punteggio = allineato
			migliore = n
	return migliore


func _update_interaction() -> void:
	var space_state := get_world_3d().direct_space_state
	var from := camera.global_position
	var reach: float = PALETTA_RANGE if GameManager.has_upgrade("paletta") else INTERACT_RANGE
	var to := from - camera.global_transform.basis.z * reach
	var query := PhysicsRayQueryParameters3D.create(from, to, LAYER_WORLD | LAYER_CAR)
	query.hit_from_inside = true # il player può trovarsi molto vicino/dentro l'ingombro del bersaglio
	query.exclude = [get_rid()]
	var result := space_state.intersect_ray(query)

	var target: Node = null
	if result and result.has("collider") and _bersaglio_valido(result["collider"]):
		target = result["collider"]
	else:
		target = _bersaglio_vicino(reach)

	var was_kind := _shop_kind(current_target)
	current_target = target
	var kind := _shop_kind(target)
	if kind != was_kind:
		shop_focus_changed.emit(kind)

	if target and target.has_method("get_interact_prompt"):
		prompt_changed.emit(target.get_interact_prompt(global_position))
	else:
		prompt_changed.emit("")


# ---------------------------------------------------------------------------
# Animazione delle mani in prima persona
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	_hands_time += delta
	if _arma_fp != null:
		# Si nasconde quando le mani servono ad altro: al volante, a
		# dirigere una macchina, seduto, al tavolo delle carte.
		_arma_fp.get_child(0).visible = not (_seduto or _inchiodato \
			or (directing_car != null) or GameManager.auto_guidata != null \
			or not is_physics_processing())
		var v: float = Vector2(velocity.x, velocity.z).length()
		_arma_fp.moto(v / WALK_SPEED if is_on_floor() else 0.3)
	_guarda_col_joypad(delta)
	if _punch_timer > 0.0:
		_punch_timer -= delta
	if _senza_sciato_cd > 0.0:
		_senza_sciato_cd -= delta
	# **Currere consuma sciato**, ma poco: una traversata della città
	# costa un pugno e mezzo, non la giornata.
	if Input.is_action_pressed("sprint") and not is_crouching \
			and Vector2(velocity.x, velocity.z).length() > 1.0:
		GameManager.consuma_sciato(GameManager.SCIATO_CORSA * delta)
	_mira_forzata(delta)
	if _catena_t > 0.0:
		_catena_t -= delta
		if _catena_t <= 0.0:
			_catena_n = 0
			_catena_su = null

	# Screen shake: la camera trema e si riassesta.
	if _shake > 0.001:
		camera.position = Vector3(
			randf_range(-1, 1) * _shake * 0.06,
			randf_range(-1, 1) * _shake * 0.06, 0)
		camera.rotation.z = randf_range(-1, 1) * _shake * 0.02
		_shake = maxf(0.0, _shake - delta * 2.2)
	else:
		camera.position = Vector3.ZERO
		camera.rotation.z = 0.0

	# **'E braccia mo' se moveno 'a sole.**
	#
	# Qui ci stavano centoventi righe che spostavano due mani finte a mano:
	# il diretto in tre tempi, la guardia, le dita che si chiudono, gli
	# strattoni della presa. Erano scritte bene e non servono più — le
	# braccia sono quelle del corpo, e le muove l'`Animator` con le clip
	# vere. Il pugno sta in `punch()`, la colluttazione nella clip della
	# presa, e la camminata muove le braccia perché è una camminata.


## Cerca un appoggio davanti a te e, se c'e', avvia la salita.
##
## Tre controlli in fila, tutti a raggio (costano niente e si fanno una
## volta per pressione del tasto):
##   1. davanti al petto c'e' qualcosa di solido, entro un metro?
##   2. quel qualcosa ha un tetto piatto fra mezzo metro e due metri?
##   3. lassu' ci si sta in piedi, o e' il sottotetto di un balcone?
## Se passano tutti e tre si registra il punto d'arrivo e ci pensa
## `_physics_process` a portarci il personaggio.
func _prova_appiglio() -> bool:
	var avanti := -global_transform.basis.z
	avanti.y = 0.0
	if avanti.length() < 0.01:
		return false
	avanti = avanti.normalized()
	var spazio := get_world_3d().direct_space_state
	var maschera: int = LAYER_WORLD | LAYER_CAR

	var petto := global_position + Vector3(0, 0.85, 0)
	var q := PhysicsRayQueryParameters3D.create(petto, petto + avanti * 1.0,
		maschera)
	q.exclude = [get_rid()]
	var muro := spazio.intersect_ray(q)
	if muro.is_empty():
		return false

	# Il punto d'arrivo sta mezzo metro oltre la faccia dell'ostacolo: se si
	# atterrasse sul filo, il primo passo si tornerebbe di sotto.
	var arrivo_xz: Vector3 = Vector3(muro["position"].x, 0.0, muro["position"].z) \
		+ avanti * 0.62
	var alto := Vector3(arrivo_xz.x, global_position.y + APPIGLIO_MAX + 0.4,
		arrivo_xz.z)
	var q2 := PhysicsRayQueryParameters3D.create(alto,
		alto - Vector3(0, APPIGLIO_MAX + 0.5, 0), maschera)
	q2.exclude = [get_rid()]
	var tetto := spazio.intersect_ray(q2)
	if tetto.is_empty():
		return false
	var y: float = tetto["position"].y
	var salita: float = y - global_position.y
	if salita < APPIGLIO_MIN or salita > APPIGLIO_MAX:
		return false
	# Un tetto troppo inclinato non e' un appoggio, e' uno scivolo.
	if tetto.has("normal") and Vector3(tetto["normal"]).y < 0.65:
		return false

	var testa := Vector3(arrivo_xz.x, y + 0.12, arrivo_xz.z)
	var q3 := PhysicsRayQueryParameters3D.create(testa,
		testa + Vector3(0, 1.6, 0), maschera)
	q3.exclude = [get_rid()]
	if not spazio.intersect_ray(q3).is_empty():
		return false

	_appiglio_da = global_position
	_appiglio_a = Vector3(arrivo_xz.x, y + 0.04, arrivo_xz.z)
	_appiglio_t = APPIGLIO_DURATA
	velocity = Vector3.ZERO
	SoundManager.play("pop", -14.0, 0.85)
	return true


# ---------------------------------------------------------------------------
# 'A presa d''e carabiniere
# ---------------------------------------------------------------------------

## Vero mentre uno sbirro ti tiene. Lo legge lo sbirro per non riafferrarti
## mentre sei già afferrato.
func in_presa() -> bool:
	return _presa_t > 0.0


## Ti hanno preso. Due secondi e mezzo di colluttazione: martella il click
## (o SPAZIO) sette volte e ti sciogli, se no ti ammanettano.
##
## Non è un quick-time event travestito: è la stessa cosa che fa il resto
## del gioco quando le mani servono davvero — si mena. Il tasto è quello.
func afferrato(chi: Node) -> void:
	if _presa_t > 0.0:
		return
	_presa_chi = chi
	# **'O terzo fermo.** Il GameManager tiene il conto e decide: se torna
	# `false` da questa presa non ci si scioglie, e non c'e' tasto che
	# tenga.
	_presa_secca = not GameManager.registra_fermo()
	_presa_t = PRESA_SECCA if _presa_secca else PRESA_DURATA
	_presa_forza = 0.0
	velocity = Vector3.ZERO
	if directing_car != null and is_instance_valid(directing_car):
		directing_car.release_control()
		directing_car = null
	GameManager.presa_iniziata.emit()
	# Anche l'arresto punta la freccia: ti prendono quasi sempre alle
	# spalle, ed e' proprio quando serve sapere da che parte sono.
	if chi is Node3D:
		GameManager.segnala_minaccia((chi as Node3D).global_position)
	if _presa_secca:
		GameManager.event_started.emit(
			"TRE FERMI. STAVOTA NUN TE SCIUOGLIE.")
		SoundManager.play("fail", -2.0, 0.55)
	else:
		GameManager.event_started.emit("T'HANNO PIGLIATO! SCIÒGLIETE!")
		SoundManager.play("fail", -4.0, 0.7)


func _liberati() -> void:
	_presa_t = 0.0
	_presa_forza = 0.0
	_presa_secca = false
	GameManager.presa_finita.emit()
	SoundManager.play("pop", -4.0, 1.4)
	GameManager.directing_gesture.emit("Statte accuorto!", false)
	# Un po' di spinta indietro: ci si scioglie e si scappa, non si resta lì.
	if _presa_chi != null and is_instance_valid(_presa_chi):
		if _presa_chi.has_method("presa_rotta"):
			_presa_chi.presa_rotta()
	_presa_chi = null


func _ammanettato() -> void:
	_presa_t = 0.0
	GameManager.presa_finita.emit()
	_presa_chi = null
	SoundManager.play("fail", 0.0, 0.5)
	GameManager.screen_shake.emit(1.0)
	# Il terzo fermo non e' un arresto come gli altri: la giornata si chiude
	# da sola e la sera non la giochi.
	if _presa_secca:
		_presa_secca = false
		GameManager.arresto_secco()
		return
	GameManager.arrest_by_carabinieri()



# ---------------------------------------------------------------------------
# 'E braccia dint'ô quadro: chello ca aggio pruvato e nun aggio fatto
# ---------------------------------------------------------------------------
#
# Tolte le mani finte, le braccia sono quelle del corpo — e un corpo fermo
# le tiene lungo i fianchi, cioè **fuori dall'inquadratura**. Guardando
# dritto non si vede più niente: è realistico, e in prima persona è una
# perdita, perché le mani sono il modo in cui il gioco ti dice che il
# personaggio sei tu.
#
# Ho provato a tenerle avanti con `hold_bone()`, e **non l'ho fatto**. Il
# perché è misurato, non opinabile: `tools/prova_braccia.gd` prova
# sistematicamente gli angoli di spalla e gomito e stampa dove finisce
# l'osso della mano rispetto all'occhio. Il meglio che si ottiene è
#
#     spalla z=85 · gomito x=60  ->  16 cm avanti, 10 sotto, **53 di lato**
#
# e cinquantatré centimetri di lato, a sedici di distanza, sono ben fuori
# dal campo visivo: la mano resta invisibile lo stesso. Portarla dentro
# vuole un terzo asse e una ricerca a tre parametri, e soprattutto vuole
# **una posa animata**, non una congelata: `hold_bone()` scrive la rotazione
# dopo l'`AnimationTree`, quindi un osso tenuto è un osso fermo — le
# braccia non seguirebbero più la camminata, e un braccio rigido che
# galleggia mentre il corpo cammina è peggio di un braccio che non si vede.
#
# La cosa giusta è una **clip di idle in prima persona** sul livello
# additivo, come si fa nei giochi veri. È lavoro da fare in Blender, non
# due costanti: sta nelle note della 0.54 come cosa che manca.
#
# Nel frattempo le braccia si vedono in tutti i momenti in cui contano —
# quando meni (le clip vere `Punch_Cross` e `Punch_Jab` le portano davanti
# alla faccia), quando dirigi, quando fumi, quando ti tengono — e
# guardando in giù ci si vede addosso. Che è già molto più di quattro
# braccia.
