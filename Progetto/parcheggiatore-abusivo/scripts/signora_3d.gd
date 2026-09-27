extends CharacterBody3D
## Signora3D — attività secondaria: il borseggio
##
## Ogni tanto attraversa la piazza una signora del quartiere con la borsa
## sottobraccio. Se le si arriva dietro **accovacciati (C)** e si clicca, si
## apre il minigioco della barra: un cursore va avanti e indietro su una
## striscia rossa con dei tratti verdi, e va fermato sul verde.
##
## Avvicinarsi in piedi non funziona: si gira, ti vede e stringe la borsa.
## Sbagliare il colpo è peggio che non provarci — strilla, e allora sì che
## i vigili si girano.

enum State { WALKING, ALERT, ROBBED, FLEEING }

const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const Human := preload("res://scripts/human_builder.gd")
const Tex := preload("res://scripts/textures.gd")
const KO := preload("res://scripts/knockout.gd")

const WALK_SPEED: float = 1.5
const FLEE_SPEED: float = 3.6
## Da quanto lontano si può tentare il colpo.
const STEAL_RANGE: float = 2.3
## Quanto deve stare dietro il player perché lei non lo veda: 1 = proprio
## dietro le spalle, 0 = di fianco. In piedi la soglia è molto più severa.
const BEHIND_DOT_CROUCHED: float = 0.05
const BEHIND_DOT_STANDING: float = 0.72
## Ogni quanto controlla se le stai addosso in piedi.
const NOTICE_EVERY: float = 0.4
const ALERT_TIME: float = 4.0 # secondi in cui tiene la borsa stretta

const STEAL_HEAT: float = 18.0
const FAIL_HEAT: float = 45.0
## Regge poco: è una signora. Stenderla è la cosa più vigliacca del gioco e
## il gioco te lo fa pesare.
const MAX_HP: int = 4
const KO_HEAT: float = 70.0

const SAY_IDLE := [
	"…e chillo m'ha ditto ca turnava…", "Mannaggia 'a spesa quant'è cara.",
	"Assunta! ASSUNTA! Songh'io!", "'Sti guagliune 'e mo'…",
	"E che ce vò, nu poco 'e rispetto.",
]
const SAY_ALERT := ["Uè, guagliò, che vuò?", "Statte accorto, sà!",
	"Ma addò vai accussì appricciecato?"]
const SAY_ROBBED := ["…e mo' addò sta 'o portafoglio?", "Uh, Maronna."]
const SAY_CAUGHT := ["AAAAH! 'O MARIUOLO!!", "AIUTO! M'ANNO ARRUBBATO!",
	"GUARDIE! GUARDIE!! 'O MARIUOLO!"]

var path_from: Vector3
var path_to: Vector3
var purse_value: int = 0

var _state: int = State.WALKING
var _visual_root: Node3D
var _bubble: Node3D
var _legs: Array = []
var _arms: Array = []
var _anim: Node = null
var _purse: Node3D = null
var _walk_phase: float = 0.0
var _idle_cd: float = 0.0
var _notice_cd: float = 0.0
var _alert_left: float = 0.0
var _minigame_open: bool = false
var hp: int = MAX_HP
var _ko: Dictionary = KO.make_state()


func _ready() -> void:
	add_to_group("signore")
	# Stesso layer di autisti e vigili: così il raggio di interazione del
	# player la becca.
	collision_layer = 4
	collision_mask = 0
	purse_value = randi_range(3, 9)
	_build_collision()
	_build_visual()
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 2.1, 0)
	add_child(_bubble)
	_idle_cd = randf_range(3.0, 7.0)


func setup(from_pos: Vector3, to_pos: Vector3) -> void:
	path_from = from_pos
	path_to = to_pos
	global_position = from_pos


func _build_collision() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.7
	shape.shape = capsule
	shape.position = Vector3(0, 0.85, 0)
	add_child(shape)


func _build_visual() -> void:
	_visual_root = Node3D.new()
	add_child(_visual_root)

	var dress_colors := [
		Color(0.42, 0.25, 0.38), Color(0.25, 0.34, 0.45),
		Color(0.5, 0.34, 0.26), Color(0.32, 0.38, 0.3),
	]
	var dress: Color = dress_colors[randi() % dress_colors.size()]
	var parts := Human.build(dress, dress.darkened(0.25), "signora", 1.62, {
		"hair": Color(0.72, 0.72, 0.70), # capelli bianchi, cotonati
		"corpo": "femmina",
		"belly": randf_range(0.5, 0.9),
		"bald": false, "moustache": false,
	})
	_visual_root.add_child(parts["root"])
	_legs = parts["legs"]
	_arms = parts["arms"]
	_anim = parts.get("anim", null)
	if _arms.is_empty():
		return # modello esterno

	_build_purse(dress)


## La borsa sottobraccio: è quella che devi guardare, ed è quella che
## sparisce quando ci riesci.
##
## (0.64) **'A borsa sta dritta, e 'o braccio se punta.** Prima la borsa era
## figlia della mano, trentaquattro centimetri "sopra" il polso, e il braccio
## si teneva con `hold_bone` — che sul pupo congela la posa di riposo: in
## foto la signora aveva il braccio piegato all'indietro e la borsa che le
## galleggiava dietro la spalla. Adesso il braccio si **punta** (vedi
## `animator.punta_osso`) e la borsa è figlia del corpo, dritta: la mano
## le presta solo la posizione, con un `RemoteTransform3D` a metà
## avambraccio. Il contenuto della borsa sta tredici centimetri più giù, così
## i manici passano sopra al braccio e la borsa ci pende sotto.
func _build_purse(dress: Color) -> void:
	_purse = Node3D.new()
	_visual_root.add_child(_purse)
	var porta := RemoteTransform3D.new()
	porta.position = Vector3(0, -0.13, 0.0)
	porta.update_rotation = false
	porta.update_scale = false
	_arms[1].add_child(porta)
	porta.remote_path = porta.get_path_to(_purse)
	_braccio_borsa(false)

	var giu := Node3D.new()
	giu.position = Vector3(0, -0.15, 0)
	_purse.add_child(giu)
	var leather := Tex.flat(dress.darkened(0.55), 0.6)
	var gold := Tex.flat(Color(0.85, 0.68, 0.25), 0.25, 0.9)

	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.24, 0.19, 0.11)
	body.mesh = body_mesh
	body.material_override = leather
	giu.add_child(body)

	var flap := MeshInstance3D.new()
	var flap_mesh := BoxMesh.new()
	flap_mesh.size = Vector3(0.25, 0.07, 0.12)
	flap.mesh = flap_mesh
	flap.position = Vector3(0, 0.07, 0)
	flap.material_override = leather
	giu.add_child(flap)

	var clasp := MeshInstance3D.new()
	var clasp_mesh := BoxMesh.new()
	clasp_mesh.size = Vector3(0.05, 0.04, 0.02)
	clasp.mesh = clasp_mesh
	clasp.position = Vector3(0, 0.035, -0.062)
	clasp.material_override = gold
	giu.add_child(clasp)

	# Manico
	for sx in [-1.0, 1.0]:
		var strap := MeshInstance3D.new()
		var strap_mesh := BoxMesh.new()
		strap_mesh.size = Vector3(0.02, 0.13, 0.02)
		strap.mesh = strap_mesh
		strap.position = Vector3(sx * 0.07, 0.15, 0)
		strap.rotation.z = deg_to_rad(-sx * 14.0)
		strap.material_override = leather
		giu.add_child(strap)


## Senza borsa il braccio torna a dondolare con la camminata.
func _lascia_braccio() -> void:
	if _anim != null and _anim.has_method("lascia_osso"):
		_anim.lascia_osso("shoulder_r")
		_anim.lascia_osso("elbow_r")


## Il braccio della borsa. Normale: il braccio giù lungo il fianco e
## l'avambraccio avanti, la borsa che ci pende sotto. Stretta: l'avambraccio
## di traverso davanti al petto, la borsa addosso.
func _braccio_borsa(stretta: bool) -> void:
	if _anim == null or not _anim.has_method("punta_osso"):
		return
	if stretta:
		_anim.punta_osso("shoulder_r", Vector3(0.10, -0.80, -0.59))
		_anim.punta_osso("elbow_r", Vector3(-0.86, 0.30, -0.41))
	else:
		_anim.punta_osso("shoulder_r", Vector3(0.10, -0.97, 0.17))
		_anim.punta_osso("elbow_r", Vector3(-0.12, -0.22, -0.97))


# ---------------------------------------------------------------------------
# Comportamento
# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _ko["down"]:
		KO.tick(_ko, _visual_root, delta)
		return
	if _minigame_open:
		return # tutto fermo mentre si gioca la barra

	match _state:
		State.WALKING:
			_step_toward(path_to, WALK_SPEED, delta)
			_chatter(delta)
			_check_noticed(delta)
		State.ALERT:
			_alert_left -= delta
			_animate_walk(0.0)
			_face_player()
			if _alert_left <= 0.0:
				_state = State.WALKING
				# **'A borsa se molla.** `_go_alert()` sovrascrive la posa
				# del braccio con quella "borsa stretta al petto", e
				# uscendo da ALERT nessuno rimetteva i valori da
				# camminata: la signora finiva il giro col braccio
				# incollato addosso, in barba al prompt che dice "aspetta
				# ca se n''o scorda".
				_braccio_borsa(false)
		State.ROBBED:
			_step_toward(path_to, WALK_SPEED, delta)
			_chatter(delta)
		State.FLEEING:
			_step_toward(path_to, FLEE_SPEED, delta)


## Parla da sola: è quello che la rende viva anche quando non la derubi.
func _chatter(delta: float) -> void:
	_idle_cd -= delta
	if _idle_cd <= 0.0:
		_idle_cd = randf_range(7.0, 14.0)
		if _bubble:
			_bubble.say(SAY_IDLE[randi() % SAY_IDLE.size()], 2.6)


## Se le stai attaccato IN PIEDI, prima o poi si gira e stringe la borsa.
func _check_noticed(delta: float) -> void:
	_notice_cd -= delta
	if _notice_cd > 0.0:
		return
	_notice_cd = NOTICE_EVERY
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return
	if global_position.distance_to(player.global_position) > STEAL_RANGE + 0.7:
		return
	if _is_behind(player):
		return
	_go_alert()


func _go_alert() -> void:
	if _state != State.WALKING:
		return
	_state = State.ALERT
	_alert_left = ALERT_TIME
	if _bubble:
		_bubble.say(SAY_ALERT[randi() % SAY_ALERT.size()], 2.0)
	# Si stringe la borsa al petto.
	_braccio_borsa(true)


## Vero se il player è abbastanza dietro di lei da non essere visto. La
## soglia dipende da com'è messo: accovacciato basta molto meno.
func _is_behind(player: Node3D) -> bool:
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	if to_player.length() < 0.01:
		return true
	var forward: Vector3 = -_visual_root.global_transform.basis.z
	forward.y = 0.0
	var dot: float = forward.normalized().dot(to_player.normalized())
	var crouched: bool = player.get("is_crouching") == true
	# dot vicino a -1 = alle spalle. Serve che sia sotto la soglia.
	return dot < (BEHIND_DOT_CROUCHED if crouched else -BEHIND_DOT_STANDING)


func _step_toward(target: Vector3, speed: float, delta: float) -> void:
	var t := target
	t.y = global_position.y
	var before := global_position
	global_position = Passo.verso(self, t, speed * delta)
	_face_toward(t)
	_animate_walk(global_position.distance_to(before))
	if global_position.distance_to(t) < 0.8:
		queue_free()


func _face_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		_face_toward(player.global_position)


func _face_toward(target: Vector3) -> void:
	var dir: Vector3 = target - global_position
	dir.y = 0.0
	if dir.length() > 0.05:
		# forward(θ) = (−sinθ, 0, −cosθ): θ = atan2(−dir.x, −dir.z).
		_visual_root.rotation.y = atan2(-dir.x, -dir.z)


func _animate_walk(moved: float) -> void:
	if _anim == null:
		return
	# Cammina piano, da signora: la velocità vera moltiplicata per poco meno
	# di uno, così l'andatura resta un passo e non diventa mai una corsa.
	_anim.set_speed(moved / maxf(get_physics_process_delta_time(), 0.0001) * 0.85)


# ---------------------------------------------------------------------------
# Il colpo
# ---------------------------------------------------------------------------

func get_interact_prompt(from_position: Vector3) -> String:
	if _state == State.ROBBED or _state == State.FLEEING:
		return ""
	if global_position.distance_to(from_position) > STEAL_RANGE:
		return ""
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return ""
	if _state == State.ALERT:
		return "T'ha visto: tene 'a borsa stretta. Aspiette ca se ne scorda."
	if not _is_behind(player):
		return "Miéttete 'a rieto e accuóvate [C] pe' ce pruvà"
	if player.get("is_crouching") != true:
		return "Accuóvate [C] e po' CLICCA pe' le sfilà 'a borsa"
	return "CLICCA pe' le sfilà 'a borsa"


## E non fa niente: il borseggio si fa col click (pugno), non con E.
func player_interact() -> void:
	pass


## Il click del mouse su una signora: se le condizioni ci sono, parte la
## barra. Altrimenti si becca uno strillo.
func receive_punch(_danno: int = 1) -> void:
	if _ko["down"]:
		return
	# Menare una signora in mezzo alla strada e' la cosa peggiore che si
	# possa fare qui dentro, e infatti pesa piu' di tutte.
	GameManager.violenza(1.4)
	# Il click su una signora che ti ha già visto (o che stai guardando in
	# faccia) è un pugno vero, non un tentativo di borseggio.
	var pl := get_tree().get_first_node_in_group("player")
	var is_punch: bool = _state == State.ALERT or _state == State.FLEEING \
		or pl == null or not _is_behind(pl) or pl.get("is_crouching") != true
	if is_punch:
		hp -= 1
		if hp <= 0:
			_go_down()
			return

	if _minigame_open or _state == State.ROBBED or _state == State.FLEEING:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	if global_position.distance_to(player.global_position) > STEAL_RANGE:
		return

	if _state == State.ALERT or not _is_behind(player) \
			or player.get("is_crouching") != true:
		_caught()
		return

	_minigame_open = true
	GameManager.pickpocket_started.emit(self)


## Chiamato dall'HUD quando il giocatore si tira indietro senza provarci.
## Non e' un fallimento: la signora non si e' accorta di niente, e ci si
## puo' riprovare fra un momento.
func annulla_pickpocket() -> void:
	_minigame_open = false
	if _bubble:
		_bubble.say("...", 0.8)


## Chiamato dall'HUD quando il giocatore ferma il cursore.
func resolve_pickpocket(success: bool) -> void:
	_minigame_open = false
	if success:
		_state = State.ROBBED
		GameManager.add_money(purse_value)
		GameManager.register_pickpocket()
		GameManager.report_risky_action(STEAL_HEAT)
		SoundManager.play("soldi", -3.0, 1.12)
		GameManager.directing_gesture.emit(
			"Sfilata liscia liscia: +€%d" % purse_value, false)
		if _bubble:
			_bubble.say(SAY_ROBBED[randi() % SAY_ROBBED.size()], 2.4)
		if _purse and is_instance_valid(_purse):
			_purse.queue_free()
			_purse = null
		_lascia_braccio()
	else:
		_caught()


## Stesa per terra. È la cosa più vigliacca che si possa fare nel gioco, e
## infatti costa più di qualunque altra: 70 di sospetto in un colpo solo,
## cioè quasi tutta la barra.
func _go_down() -> void:
	_minigame_open = false
	GameManager.pickpocket_closed.emit()
	GameManager.register_punch()
	GameManager.report_risky_action(KO_HEAT)
	SoundManager.pugno(0.0)
	GameManager.event_started.emit("HÊ STISO 'NA SIGNORA. 'A piazza t'ha visto.")
	if _bubble:
		_bubble.say(KO.SAY_KO[randi() % KO.SAY_KO.size()], 4.0)
	if _purse and is_instance_valid(_purse):
		GameManager.add_money(purse_value)
		_purse.queue_free()
		_purse = null
	_lascia_braccio()
	KO.lay_down(_ko, _visual_root, 0.0) # non si rialza: resta lì
	_state = State.ROBBED


## Beccato: strilla, e uno strillo in mezzo alla piazza vale più di
## qualunque altra imprudenza.
func _caught() -> void:
	_minigame_open = false
	_state = State.FLEEING
	SoundManager.play("fail", 0.0, 1.35)
	GameManager.screen_shake.emit(0.5)
	GameManager.report_risky_action(FAIL_HEAT)
	# **E chiamma 'a pulizia: 'na stella secca** (0.56).
	#
	# Il capo: *"se fallisci il borseggio a una vecchietta, lei strilla e
	# chiama la polizia, guadagni una stella ricercato"*.
	#
	# Prima c'era solo il sospetto (45 punti, tanti): ma il sospetto è il
	# **vigile**, cioè uno che ti guarda male e prima o poi ti fa il
	# verbale. Uno strillo in mezzo alla piazza non è una cosa che si
	# guarda male: è una chiamata al 112, e quella porta i carabinieri.
	#
	# La differenza si sente subito: col sospetto puoi restare lì e
	# aspettare che scenda, con una stella addosso devi **scappare**. Ed è
	# giusto che tentare il colpo e sbagliarlo sia peggio che non provarci.
	var visti: int = GameManager.testimoni(global_position)
	GameManager.crimine(GameManager.PUNTI_PER_STELLA
		* maxf(1.0, GameManager.peso_testimoni(visti)))
	GameManager.event_started.emit(
		"T'HA BECCATO! Strilla, e ha chiammato 'a pulizia. Scappa!")
	if _bubble:
		_bubble.say(SAY_CAUGHT[randi() % SAY_CAUGHT.size()], 3.2)
	if _purse and is_instance_valid(_purse):
		_purse.queue_free()
		_purse = null
	_lascia_braccio()
