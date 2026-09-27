extends CharacterBody3D
## Sbirro3D — 'o carabiniere a piede
##
## **Che cosa fa, e cosa NON fa.**
##
## Arriva quando hai le stelle addosso (vedi `GameManager.crimine()`), ti
## punta e ti viene dietro. Non è un boss e non è una trappola: è una
## seccatura che ti costringe a smettere di fare quello che stavi facendo.
##
## Per questo va **piano**: tre metri e mezzo al secondo contro i quattro e
## otto del tuo passo e gli otto e due di corsa. Correre basta sempre per
## staccarlo. Il costo non è il rischio di essere preso — è che mentre
## scappi non stai posteggiando, e il turno scorre lo stesso.
##
## Se però ti fai prendere (perché sei in un vicolo cieco, perché stavi
## menando qualcun altro, perché non te ne sei accorto) **ti afferra**: da lì
## sono due secondi e mezzo di colluttazione a tasto, e se non ti sciogli ti
## ammanetta e il turno finisce in caserma.
##
## Nota sul modo in cui insegue: va in linea retta. Non c'è pathfinding in
## questo gioco e non serve, perché il punto non è che ti prenda — è che si
## veda arrivare in fondo alla strada.

const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const Human := preload("res://scripts/human_builder.gd")
const Tex := preload("res://scripts/textures.gd")

const LAYER_WORLD := 1

## Lento di proposito. Il player cammina a 4.8 e corre a 8.2.
const VELOCITA: float = 3.5
## Da qui in poi allunga le mani.
const PRESA_RAGGIO: float = 1.45
## Fin dove ti vede. Oltre, gira a vuoto verso l'ultimo punto noto.
const VISTA: float = 34.0
## Quanto ci mette a rinunciare quando non ti vede più.
const RESA: float = 9.0
const FISCHIO_OGNI: float = 3.2
## **Si puo' menare pure a loro.** Trenta punti: a mani nude (due danni) sono
## quindici colpi mentre gli altri ti arrivano addosso, cioe' non si fa. Col
## fierro sono due colpi. E' l'ultima cosa sensata da fare in questo gioco,
## e infatti costa due stelle e mezza a botta.
const MAX_HP: int = 30

const SAY_ARRIVO := ["CARABINIERI! FIERMATE!", "ALT! FIERMATE 'LLOCO!",
	"NUN TE MUÓVERE!"]
const SAY_INSEGUE := ["FIERMATE!", "ADDÒ VAJE?!", "TANTO T'ACCHIAPPO!",
	"È INUTILE CA CURRE!"]
## Quello che dicono quando la centrale li richiama: non "t'ho perso", ma
## "non ti cerchiamo più". Sono due cose diverse e il giocatore le deve
## sentire diverse — la prima vuol dire che ti stanno ancora cercando.
const FRASI_LASCIA := [
	"Centrale, ccà nun ce sta niente. Rientriamo.",
	"Lassa sta'. Nun è isso.",
	"Va buo', pe' stavota. Jammo.",
]
const SAY_PERSO := ["S'è squagliato...", "Addò s'è mmiso?",
	"Mannaggia. Sarrà pe' n'ata vota."]
const SAY_PRESA := ["FIERMO! MANE 'NNANZE!", "T'AGGIO PIGLIATO!",
	"E MO' VIENE CU' MMÈ!"]

enum Stato { ARRIVO, CACCIA, CERCA, PRESA, RESA }

var _stato: int = Stato.ARRIVO
var _visual: Node3D
var _bubble: Node3D
var _legs: Array = []
var _anim: Node = null
var _passo: float = 0.0
var _fischio: float = 0.0
var _perso: float = 0.0
var _ultimo_visto: Vector3 = Vector3.ZERO
var _detto: float = 0.0
var _presa_attiva: bool = false
var hp: int = MAX_HP
var _steso: float = 0.0


func _ready() -> void:
	add_to_group("sbirri")
	add_to_group("carabinieri_a_piede")
	collision_layer = 4
	collision_mask = LAYER_WORLD
	_build_visual()
	var f := CollisionShape3D.new()
	var c := CapsuleShape3D.new()
	c.radius = 0.38
	c.height = 1.9
	f.shape = c
	f.position = Vector3(0, 0.95, 0)
	add_child(f)
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 2.3, 0)
	add_child(_bubble)
	_bubble.say(SAY_ARRIVO[randi() % SAY_ARRIVO.size()], 2.6)
	SoundManager.play("fischio_vigile", -3.0, 0.9)


func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	# Nero con la banda rossa: è l'uniforme che si riconosce da lontano
	# anche a quattro poligoni.
	var parts := Human.build(Color(0.08, 0.09, 0.15), Color(0.06, 0.07, 0.12),
		"carabiniere", 1.86, {"moustache": true, "bald": true,
		# 'A banda rossa sulla coscia, che adesso è geometria pesata sulle
		# ossa della gamba e non due bastoni appesi al torace.
		"banda": true, "corpo": "normale",
		# (0.66) 'O carabiniere: arraggiato, colletto della divisa.
		"palpebre": "arraggiate", "sopracciglia": "arraggiate",
		"naso": "grosso", "bocca": "storta", "barba": "",
		"rughe": "arraggiato", "colletto": true, "cintura": true,
		"catenina": false})
	_visual.add_child(parts["root"])
	_legs = parts["legs"]
	_anim = parts.get("anim", null)
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

	var testa: Node3D = parts["head"]
	# Il basco.
	var basco := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.168
	bm.bottom_radius = 0.152
	bm.height = 0.105
	bm.radial_segments = 14
	basco.mesh = bm
	basco.position = Vector3(0.025, 0.235, 0)
	basco.rotation.z = 0.17
	basco.material_override = Tex.flat(Color(0.05, 0.05, 0.08), 0.85)
	testa.add_child(basco)

	var fiamma := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(0.075, 0.075, 0.02)
	fiamma.mesh = fm
	fiamma.position = Vector3(-0.03, 0.245, -0.145)
	fiamma.material_override = Tex.flat(Color(0.85, 0.15, 0.14), 0.4, 0.3)
	testa.add_child(fiamma)

	# Le bande rosse adesso stanno nel modello (`banda_rossa` in
	# pupo.glb): pesate sulle ossa delle gambe, quindi si piegano col
	# ginocchio. Qui restano la bandoliera bianca e il cinturone, che sono
	# l'altra metà di quello che rende riconoscibile una divisa da lontano.
	var petto: Node3D = parts["bones"].get("chest", _visual)
	var bianco := Tex.flat(Color(0.94, 0.94, 0.92), 0.6)
	var tracolla := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(0.075, 0.56, 0.30)
	tracolla.mesh = tm
	tracolla.position = Vector3(-0.055, -0.09, 0)
	tracolla.rotation.z = -0.42
	tracolla.material_override = bianco
	petto.add_child(tracolla)

	var cinto := MeshInstance3D.new()
	var cm2 := BoxMesh.new()
	cm2.size = Vector3(0.34, 0.075, 0.26)
	cinto.mesh = cm2
	cinto.position = Vector3(0, -0.30, 0)
	cinto.material_override = bianco
	petto.add_child(cinto)

	# 'E gradi ncopp'ê spalle — **e stavolta ncopp'ê spalle overo.**
	for chiave in ["spalla_l", "spalla_r"]:
		var sp: Node3D = parts["bones"].get(chiave, null)
		if sp == null:
			continue
		var gr := MeshInstance3D.new()
		var gm2 := SphereMesh.new()
		gm2.radius = 0.055
		gm2.height = 0.11
		gm2.radial_segments = 8
		gm2.rings = 4
		gr.mesh = gm2
		gr.scale = Vector3(1.0, 0.42, 1.0)
		gr.material_override = Tex.flat(Color(0.88, 0.80, 0.34), 0.3, 0.7)
		sp.add_child(gr)


## Menare a un carabiniere. Non lo ferma: lo stende, e intanto il quartiere
## chiama tutti gli altri.
func receive_punch(danno: int = 1) -> void:
	# **'A reazione, no 'o blocco.** Il colpo si vede addosso (clip
	# `Hit_Chest`/`Hit_Head` sopra alla locomozione) ma non toglie il
	# controllo: vedi `Animator.reagisci_colpo`.
	if _anim != null and _anim.has_method("reagisci_colpo"):
		_anim.reagisci_colpo(randf() < 0.4)
	if _steso > 0.0:
		return
	hp -= maxi(1, danno)
	GameManager.nemico_colpito.emit("'O carabiniere", maxi(0, hp), MAX_HP)
	GameManager.crimine(2.5)
	GameManager.add_heat(GameManager.HEAT_MAX)
	SoundManager.pugno(0.0)
	GameManager.screen_shake.emit(0.6)
	if hp <= 0:
		_steso = 14.0
		_presa_attiva = false
		_stato = Stato.RESA
		_bubble.say("Aah... centrale... aggio bisogno...", 4.0)
		_visual.rotation.z = deg_to_rad(82.0)
		_visual.position.y = -0.55
		GameManager.event_started.emit(
			"HÊ STISO 'NU CARABINIERE. MO' SO' CAZZE.")
	else:
		_bubble.say("PUBBLICO UFFICIALE!!", 2.0)


func get_interact_prompt(_da: Vector3) -> String:
	if _steso > 0.0:
		return ""
	return "'O carabiniere. Nun ce sta niente 'a fa'."


func _physics_process(delta: float) -> void:
	if _steso > 0.0:
		_fermo()
		_steso -= delta
		if _steso <= 0.0:
			_visual.rotation.z = 0.0
			_visual.position.y = 0.0
			hp = MAX_HP
			_stato = Stato.CERCA
		return
	_detto = maxf(0.0, _detto - delta)
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null or not is_instance_valid(pl):
		return
	if GameManager.arrested or GameManager.hospitalized \
			or not GameManager.shift_active:
		_vattene()
		return

	# **Stelle a zero: si molla, punto.**
	#
	# Il controllo c'era solo dentro allo stato CERCA — cioè solo per chi
	# ti aveva già perso di vista. Chi era in CACCIA o stava ancora
	# arrivando continuava a inseguirti anche a fedina pulita, e siccome la
	# centrale ne manda uno nuovo appena uno se ne va, la sensazione era
	# che non la finissero mai. Adesso il controllo sta prima di tutto: se
	# non sei più ricercato, chiunque stia correndo si ferma, dice la sua e
	# se ne torna in caserma.
	#
	# L'unica eccezione è chi ti sta già tenendo per un braccio: quella
	# presa si risolve, in un senso o nell'altro.
	if GameManager.stelle <= 0 and _stato != Stato.PRESA:
		if _stato != Stato.RESA:
			_bubble.say(FRASI_LASCIA[randi() % FRASI_LASCIA.size()], 2.4)
			_vattene(false)
		return

	var mio := global_position
	var suo: Vector3 = pl.global_position
	var dist: float = Vector2(suo.x - mio.x, suo.z - mio.z).length()
	var vedo: bool = dist <= VISTA and _libero(pl)

	# È questa riga che tiene in piedi tutto il sistema delle stelle: finché
	# almeno un carabiniere ti vede, le stelle non scendono.
	if vedo:
		GameManager.segnala_vista(true)
		_ultimo_visto = suo
		_perso = 0.0
	else:
		_perso += delta

	match _stato:
		Stato.ARRIVO:
			if vedo:
				_stato = Stato.CACCIA
			elif _perso >= RESA or GameManager.stelle <= 0:
				# **Pure ARRIVO se stanca.** `_perso` si accumulava sempre ma
				# si leggeva solo in CERCA: un carabiniere appena nato che
				# non ti vedeva (perche' stai dentro casa, per dire)
				# camminava verso (300, 300) senza uscita possibile.
				_vattene()
			else:
				_verso(_ultimo_visto if _ultimo_visto != Vector3.ZERO else suo,
					delta)
		Stato.CACCIA:
			if not vedo:
				_stato = Stato.CERCA
				_bubble.say(SAY_PERSO[randi() % SAY_PERSO.size()], 2.2)
			else:
				_verso(suo, delta)
				_fischia(delta)
				if dist <= PRESA_RAGGIO:
					_afferra(pl)
		Stato.CERCA:
			if vedo:
				_stato = Stato.CACCIA
			elif _perso >= RESA or GameManager.stelle <= 0:
				_vattene()
			else:
				_verso(_ultimo_visto, delta)
		Stato.PRESA:
			_verso_fermo(suo)
		Stato.RESA:
			_fermo()


## Linea di vista: un muro in mezzo e non ti vede. È quello che rende
## sensato nascondersi dietro un angolo invece che correre in linea retta.
func _libero(pl: Node3D) -> bool:
	var spazio := get_world_3d().direct_space_state
	var da := global_position + Vector3(0, 1.5, 0)
	var a: Vector3 = pl.global_position + Vector3(0, 1.2, 0)
	var q := PhysicsRayQueryParameters3D.create(da, a, LAYER_WORLD)
	q.exclude = [get_rid()]
	return spazio.intersect_ray(q).is_empty()


## Ferma pure l'animazione, non solo il corpo.
func _fermo() -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if _anim != null and _anim.has_method("set_speed"):
		_anim.set_speed(0.0)


func _verso(meta: Vector3, delta: float) -> void:
	var d := Vector3(meta.x - global_position.x, 0.0, meta.z - global_position.z)
	if d.length() < 0.4:
		# **Arrivato = fermo, pure p''e ccosce.** L'Animator si tiene
		# l'ultima velocita' che gli hai dato: uscendo di qui senza
		# azzerarla, il carabiniere restava a marciare sul posto — fino a
		# nove secondi in CERCA, e da steso a terra pure, ruotato di
		# ottantadue gradi col ciclo di camminata addosso.
		_fermo()
		return
	d = d.normalized()
	velocity.x = d.x * VELOCITA
	velocity.z = d.z * VELOCITA
	velocity.y = -6.0
	move_and_slide()
	# forward(θ) = (−sinθ, 0, −cosθ): θ = atan2(−dir.x, −dir.z).
	_visual.rotation.y = atan2(-d.x, -d.z)
	_passo += delta * VELOCITA * 1.5
	# L'animatore vuole la VELOCITA', non la fase: `set_speed` decide da solo
	# se e' fermo, se cammina o se corre.
	if _anim != null:
		_anim.set_speed(VELOCITA)
	elif not _legs.is_empty():
		for i in _legs.size():
			var g: Node3D = _legs[i]
			if g != null:
				g.rotation.x = sin(_passo + float(i) * PI) * 0.5


func _verso_fermo(meta: Vector3) -> void:
	var d := Vector3(meta.x - global_position.x, 0.0, meta.z - global_position.z)
	if d.length() > 0.05:
		_visual.rotation.y = atan2(-d.x, -d.z)
	if _anim != null:
		_anim.set_speed(0.0)


func _fischia(delta: float) -> void:
	_fischio -= delta
	if _fischio > 0.0:
		return
	# **'O fischio nun se sona a tempo.** Era a intervallo fisso e sempre
	# alla stessa altezza: un metronomo che ti stava appresso. Un fischietto
	# vero lo soffia una persona che corre, quindi esce quando gli va e mai
	# uguale. E il volume scende con la distanza.
	_fischio = FISCHIO_OGNI * randf_range(0.75, 1.9)
	var pl_f := get_tree().get_first_node_in_group("player")
	var d_f: float = 12.0
	if pl_f != null and pl_f is Node3D:
		d_f = global_position.distance_to((pl_f as Node3D).global_position)
	SoundManager.play("fischio_vigile",
		lerpf(-11.0, -28.0, clampf(d_f / 34.0, 0.0, 1.0)),
		randf_range(0.92, 1.08))
	if _detto <= 0.0:
		_detto = 4.0
		_bubble.say(SAY_INSEGUE[randi() % SAY_INSEGUE.size()], 2.0)


## Le mani addosso. Da qui decide il giocatore: o si scioglie o va dentro.
func _afferra(pl: Node) -> void:
	if _presa_attiva or not pl.has_method("afferrato"):
		return
	if pl.call("in_presa"):
		return
	_presa_attiva = true
	_stato = Stato.PRESA
	_bubble.say(SAY_PRESA[randi() % SAY_PRESA.size()], 3.0)
	# A volume pieno era una sberla nelle orecchie: è un fischietto a
	# venti centimetri dalla faccia, non una sirena antiaerea.
	SoundManager.play("fischio_vigile", -8.0, 0.72)
	GameManager.screen_shake.emit(0.7)
	pl.call("afferrato", self)


## Lo chiama il player quando si è sciolto: lo sbirro resta indietro un
## momento, poi riprende la caccia.
func presa_rotta() -> void:
	_presa_attiva = false
	_stato = Stato.CERCA
	_perso = 0.0
	_bubble.say("Ah! Mannaggia!", 1.8)
	# Un passo indietro, se no ti riafferra nello stesso istante.
	var pl := get_tree().get_first_node_in_group("player")
	if pl != null and is_instance_valid(pl):
		var via: Vector3 = (global_position - pl.global_position).normalized()
		global_position += via * 2.2
	_stato = Stato.CACCIA


func _vattene(dillo: bool = true) -> void:
	if _stato == Stato.RESA:
		return
	_stato = Stato.RESA
	if dillo:
		_bubble.say(SAY_PERSO[randi() % SAY_PERSO.size()], 2.2)
	var t := get_tree().create_timer(2.4)
	t.timeout.connect(queue_free)
