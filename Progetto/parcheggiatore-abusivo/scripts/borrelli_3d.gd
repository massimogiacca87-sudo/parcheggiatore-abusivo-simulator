extends CharacterBody3D
## Borrelli3D — il boss di fine turno
##
## Nell'ultimo minuto arriva LUI: giacca di lino a righine, occhiali tondi,
## barba sale e pepe, e una lista di insulti. Non mena nessuno: ti INSEGUE
## e ti RIPRENDE — col telefonino in mano — e ogni volta che ti raggiunge il
## sospetto dei vigili schizza.
##
## Come si vince: NON menandolo. Bisogna scappare e fumarsi una sigaretta
## finché non si sfoga (la "furia" scende), e quando finalmente si ferma
## bisogna parlargli e trovare la risposta giusta. Le altre tre lo fanno
## ripartire più incazzato di prima.
##
## Se in assets/models/ esiste "borrelli" viene usato quel modello al posto
## di questo, che è comunque una caricatura, non un ritratto.

enum State { ARRIVING, CHASING, WAITING_TALK, TALKING, LEAVING }

## Da quanto sta fermo a parlare. Serve al timeout: vedi `_physics_process`.
var _t_parlata: float = 0.0

const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const Human := preload("res://scripts/human_builder.gd")
const Tex := preload("res://scripts/textures.gd")
const Models := preload("res://scripts/models.gd")

## Più lento di te ANCHE se cammini (4,8): a 5,2 non gli si scappava, perché
## lui attraversa le auto e i cordoli mentre tu ci sbatti contro.
const CHASE_SPEED: float = 4.2
const ARRIVE_SPEED: float = 3.4
const REACH: float = 2.2         # a che distanza ti riprende col telefonino
const CATCH_EVERY: float = 3.0   # ogni quanto può riprenderti
const CATCH_HEAT: float = 16.0   # quanto sospetto ti costa finire nel video
const TALK_RANGE: float = 3.4    # da quanto lontano si può parlare, quando è calmo

# --- La furia ---
const FURIA_MAX: float = 100.0
const FURIA_TALK_THRESHOLD: float = 34.0 # sotto questa soglia si ferma e ascolta
const FURIA_DECAY: float = 2.8           # al secondo, solo scappando
const FURIA_DECAY_SMOKING: float = 11.0  # al secondo, mentre ti fumi 'na sigaretta
## Scappare da solo non basta: senza fumare la furia si ferma qui sopra, e
## la soglia del dialogo resta irraggiungibile. Prima bastava aspettare 24
## secondi e lui si calmava da solo — così l'incontro si risolveva senza che
## il giocatore facesse niente.
const FURIA_FLOOR_NO_SMOKE: float = 44.0
## Sotto i 6 metri non si sfoga: gli devi stare lontano.
const FURIA_SAFE_DISTANCE: float = 6.0
const FURIA_ON_CATCH: float = 14.0       # ogni volta che ti riprende si ricarica
const FURIA_ON_WRONG_ANSWER: float = 45.0
const FURIA_ON_PUNCH: float = 60.0       # menarlo è la mossa peggiore che c'è

const INSULTS := [
	"CIALTRONE!", "VERGOGNA!", "PARASSITA!", "SCIACALLO!",
	"ABUSIVO! ABUSIVO!", "TE STONGO RIPRENNENNO!",
	"QUESTA È CAMORRA SPICCIOLA!", "STO CHIAMANDO 'E VIGILI!",
]
const SAY_ARRIVE := "TE STONGO CERCANNO DA 'NA MEZZ'ORA!"
const SAY_CATCH := ["SEI IN DIRETTA!", "TUTTI TE STANNO A VEDÈ!", "SORRIDI, ABUSIVO!"]
const SAY_CALM := "Va bene. Parla. Ma dimme 'a verità."
const SAY_WRONG := ["AH, ACCUSSÌ RISPUNNE?!", "PEGGIO PE' TTE!", "MO' NUN TE LASSO CCHIÙ!"]
const SAY_PUNCHED := "AGGRESSIONE! AVITE VISTO TUTTI!"
const SAY_DEFEAT := "…'E ccriature. Mannaggia. Va', vattenne."

## Le risposte. L'unica che funziona è la B: è l'unica che non è
## un'aggressione né una pernacchia.
const ANSWERS := [
	{"key": "A", "text": "Borrè, fatt' 'e cazz' tuoje", "right": false,
		"reply": "'E CAZZI MIEJE?! STO FACENNO 'O DOVERE MIO!"},
	{"key": "B", "text": "Ma nun è pe' mme… è pp''e ccriature", "right": true,
		"reply": SAY_DEFEAT},
	{"key": "C", "text": "Borrè, va' cacà", "right": false,
		"reply": "MALEDUCATO! E STO PURE RIPRENNENNO!"},
	{"key": "D", "text": "Mò te vatt' proprio, Borrè", "right": false,
		"reply": "MINACCE! CHIAMMO 'A POLIZIA MO' PROPRIO!"},
]

## **'O cafè.**
##
## La quinta risposta esce solo se ti becca vicino al bar, e allora è
## un'altra cosa: non è una scusa, è un invito. Borrelli è uno che si
## sfoga in mezzo alla strada gridando "abusivo" — davanti a un banco, con
## una tazzulella in mano, non si può gridare. È l'unico modo di vincerlo
## senza mentirgli, e costa un euro.
##
## Il raggio è dodici metri: quanto basta perché "sei al bar" sia una cosa
## vera e non una coincidenza.
const RAGGIO_BAR: float = 12.0
const COSTO_CAFFE: int = 1
const RISPOSTA_CAFFE := {
	"key": "E", "text": "Borrè, t''o piglie nu cafè? Offro io (€1)",
	"right": true,
	"reply": "…E vabbuo'. Ma sulo pecché sto 'e passaggio. Ristretto.",
}

var state: int = State.ARRIVING
var furia: float = FURIA_MAX

var _visual_root: Node3D
var _bubble: Node3D
var _legs: Array = []
var _arms: Array = []
var _head: Node3D = null
var _anim: Node = null
var _walk_phase: float = 0.0
var _catch_cd: float = 0.0
var _insult_cd: float = 0.0
var _target_point: Vector3
var _leave_point: Vector3
var _phone: Node3D = null
var _answered: bool = false


func _ready() -> void:
	add_to_group("borrelli")
	# Stesso layer degli autisti: serve perché il raggio di interazione del
	# player lo becchi (per parlargli, o per fare la sciocchezza di menarlo).
	collision_layer = 4
	collision_mask = 0
	_build_collision()
	_build_visual()
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 2.35, 0)
	add_child(_bubble)


func _build_collision() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.95
	shape.shape = capsule
	shape.position = Vector3(0, 0.98, 0)
	add_child(shape)


## entry: da dove entra. leave: dove se ne va quando l'hai convinto.
func setup(entry: Vector3, leave: Vector3) -> void:
	global_position = entry
	_leave_point = leave
	_target_point = entry
	_say(SAY_ARRIVE)
	SoundManager.play("fischio_vigile", -3.0, 0.85)
	GameManager.screen_shake.emit(0.5)
	GameManager.event_started.emit("È ARRIVATO BORRELLI! SCAPPA E FATTE 'NA SIGARETTA!")
	GameManager.boss_state_changed.emit(furia, true)
	# Da adesso il cronometro del turno è fermo: si finisce quando finisce lui.
	GameManager.start_boss_phase()


func _say(text: String) -> void:
	if _bubble:
		_bubble.say(text, 2.6)
	GameManager.directing_gesture.emit(text, true)


# ---------------------------------------------------------------------------
# La caricatura
# ---------------------------------------------------------------------------

func _build_visual() -> void:
	_visual_root = Node3D.new()
	add_child(_visual_root)

	# Camicia bianca sotto, pantaloni scuri.
	var parts := Human.build(Color(0.95, 0.95, 0.93), Color(0.17, 0.18, 0.22),
		"borrelli", 1.82, {
			"skin": Color(0.83, 0.66, 0.53),
			"hair": Color(0.42, 0.40, 0.38), # sale e pepe
			"belly": 0.35,
			"bald": false,
			"moustache": false,
		})
	_visual_root.add_child(parts["root"])
	_legs = parts["legs"]
	_arms = parts["arms"]
	_head = parts["head"]
	_anim = parts.get("anim", null)

	if _head == null:
		return # è stato montato un modello 3D esterno: niente da aggiungere

	_build_face()
	_build_jacket(parts["root"])
	_build_phone()


## Occhiali tondi scuri, barba sale e pepe, capelli mossi: i tre tratti che
## lo rendono riconoscibile senza doverne fare il ritratto.
func _build_face() -> void:
	var frame_mat := Tex.flat(Color(0.10, 0.09, 0.10), 0.35)
	var lens_mat := Tex.flat(Color(0.55, 0.62, 0.70, 0.42), 0.1, 0.5)
	lens_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var beard_mat := Tex.flat(Color(0.44, 0.42, 0.39), 0.95)
	var hair_mat := Tex.flat(Color(0.40, 0.38, 0.36), 0.95)

	# --- Occhiali: due cerchi spessi e il ponte ---
	for ex in [-0.058, 0.058]:
		var rim := MeshInstance3D.new()
		var rim_mesh := TorusMesh.new()
		rim_mesh.inner_radius = 0.034
		rim_mesh.outer_radius = 0.048
		rim_mesh.rings = 14
		rim_mesh.ring_segments = 8
		rim.mesh = rim_mesh
		rim.rotation.x = deg_to_rad(90)
		rim.position = Vector3(ex, 0.158, -0.118)
		rim.material_override = frame_mat
		_head.add_child(rim)

		var lens := MeshInstance3D.new()
		var lens_mesh := CylinderMesh.new()
		lens_mesh.top_radius = 0.036
		lens_mesh.bottom_radius = 0.036
		lens_mesh.height = 0.006
		lens.mesh = lens_mesh
		lens.rotation.x = deg_to_rad(90)
		lens.position = Vector3(ex, 0.158, -0.116)
		lens.material_override = lens_mat
		_head.add_child(lens)

		# Astina verso l'orecchio
		var arm := MeshInstance3D.new()
		var arm_mesh := BoxMesh.new()
		arm_mesh.size = Vector3(0.012, 0.01, 0.12)
		arm.mesh = arm_mesh
		arm.position = Vector3(ex * 1.75, 0.16, -0.05)
		arm.material_override = frame_mat
		_head.add_child(arm)

	var bridge := MeshInstance3D.new()
	var bridge_mesh := BoxMesh.new()
	bridge_mesh.size = Vector3(0.035, 0.011, 0.012)
	bridge.mesh = bridge_mesh
	bridge.position = Vector3(0, 0.163, -0.126)
	bridge.material_override = frame_mat
	_head.add_child(bridge)

	# --- Barba piena: guance, mento, e i baffi sopra il labbro ---
	var jaw := MeshInstance3D.new()
	var jaw_mesh := SphereMesh.new()
	jaw_mesh.radius = 0.118
	jaw_mesh.height = 0.2
	jaw.mesh = jaw_mesh
	jaw.position = Vector3(0, 0.055, -0.012)
	jaw.scale = Vector3(1.0, 0.85, 1.02)
	jaw.material_override = beard_mat
	_head.add_child(jaw)

	var chin := MeshInstance3D.new()
	var chin_mesh := BoxMesh.new()
	chin_mesh.size = Vector3(0.13, 0.075, 0.1)
	chin.mesh = chin_mesh
	chin.position = Vector3(0, 0.008, -0.075)
	chin.material_override = beard_mat
	_head.add_child(chin)

	var lip := MeshInstance3D.new()
	var lip_mesh := BoxMesh.new()
	lip_mesh.size = Vector3(0.095, 0.024, 0.032)
	lip.mesh = lip_mesh
	lip.position = Vector3(0, 0.068, -0.127)
	lip.material_override = beard_mat
	_head.add_child(lip)

	# --- Capelli mossi: qualche ciuffo invece di una calotta liscia ---
	for i in range(7):
		var t: float = float(i) / 6.0
		var tuft := MeshInstance3D.new()
		var tuft_mesh := SphereMesh.new()
		tuft_mesh.radius = 0.052
		tuft_mesh.height = 0.09
		tuft.mesh = tuft_mesh
		tuft.position = Vector3(
			lerpf(-0.1, 0.1, t),
			0.225 - absf(t - 0.5) * 0.06,
			0.02 + sin(t * PI) * -0.06)
		tuft.scale = Vector3(1.0, 0.8, 1.15)
		tuft.material_override = hair_mat
		_head.add_child(tuft)


## La giacca di lino chiara a righine, aperta, sopra la camicia bianca.
## Le misure seguono il busto di human_builder (torace 0,50 largo a y=1,30;
## pancia a y=1,00; spalle a ±0,31 y=1,42), altrimenti la giacca esce dal
## corpo e sembra un cartone appoggiato davanti.
func _build_jacket(body_root: Node3D) -> void:
	var linen := Tex.flat(Color(0.76, 0.77, 0.78), 0.95)
	var linen_dark := Tex.flat(Color(0.50, 0.52, 0.55), 0.95)

	const TOP := 1.45      # sotto il colletto
	const BOTTOM := 0.92   # poco sotto la cintura
	var h: float = TOP - BOTTOM
	var mid: float = (TOP + BOTTOM) * 0.5

	# I due davanti, con in mezzo una bella fetta di camicia bianca.
	# Il pannello va da |x| 0,10 a |x| 0,26: 20 cm di camicia scoperta.
	const PANEL_W := 0.16
	const PANEL_CX := 0.18
	for sx in [-1.0, 1.0]:
		var front := MeshInstance3D.new()
		var front_mesh := BoxMesh.new()
		front_mesh.size = Vector3(PANEL_W, h, 0.045)
		front.mesh = front_mesh
		front.position = Vector3(sx * PANEL_CX, mid, -0.15)
		front.material_override = linen
		body_root.add_child(front)

		# Le righine SOLO sopra il pannello: prima corrivano da un fianco
		# all'altro e riempivano di grigio anche lo spacco della camicia.
		for i in range(4):
			var stripe := MeshInstance3D.new()
			var stripe_mesh := BoxMesh.new()
			stripe_mesh.size = Vector3(0.011, h - 0.02, 0.012)
			stripe.mesh = stripe_mesh
			stripe.position = Vector3(
				sx * PANEL_CX + (-0.054 + i * 0.036), mid, -0.172)
			stripe.material_override = linen_dark
			body_root.add_child(stripe)

		# Revers inclinato verso lo spacco
		var lapel := MeshInstance3D.new()
		var lapel_mesh := BoxMesh.new()
		lapel_mesh.size = Vector3(0.085, 0.24, 0.025)
		lapel.mesh = lapel_mesh
		lapel.rotation.z = deg_to_rad(sx * 14.0)
		lapel.position = Vector3(sx * 0.145, TOP - 0.13, -0.176)
		lapel.material_override = linen_dark
		body_root.add_child(lapel)

		# Fianco della giacca
		var side := MeshInstance3D.new()
		var side_mesh := BoxMesh.new()
		side_mesh.size = Vector3(0.05, h, 0.3)
		side.mesh = side_mesh
		side.position = Vector3(sx * 0.265, mid, -0.015)
		side.material_override = linen
		body_root.add_child(side)

	# Schiena
	var back := MeshInstance3D.new()
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(0.53, h, 0.05)
	back.mesh = back_mesh
	back.position = Vector3(0, mid, 0.145)
	back.material_override = linen
	body_root.add_child(back)

	# Maniche: coprono il braccio dalla spalla al gomito.
	for shoulder in _arms:
		var sleeve := MeshInstance3D.new()
		var sleeve_mesh := BoxMesh.new()
		sleeve_mesh.size = Vector3(0.145, 0.3, 0.165)
		sleeve.mesh = sleeve_mesh
		sleeve.position = Vector3(0, -0.15, 0)
		sleeve.material_override = linen
		shoulder.add_child(sleeve)


## Il telefonino alzato: è quello che ti fa male, non le mani.
func _build_phone() -> void:
	if _arms.is_empty():
		return
	_phone = Node3D.new()
	_phone.position = Vector3(0, -0.36, -0.04)
	_arms[0].add_child(_phone)
	# Il braccio che regge il telefono resta alzato per tutta la scena: esce
	# dall'animazione e va in posa fissa, gomito piegato.
	if _anim != null:
		_anim.hold_bone("shoulder_l", Vector3(-72.0, 0.0, 0.0))
		_anim.hold_bone("elbow_l", Vector3(-46.0, 0.0, 0.0))

	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.075, 0.145, 0.014)
	body.mesh = body_mesh
	body.material_override = Tex.flat(Color(0.08, 0.08, 0.09), 0.3, 0.4)
	_phone.add_child(body)

	var screen := MeshInstance3D.new()
	var screen_mesh := BoxMesh.new()
	screen_mesh.size = Vector3(0.062, 0.125, 0.004)
	screen.mesh = screen_mesh
	screen.position = Vector3(0, 0, -0.009)
	var glow := Tex.flat(Color(0.35, 0.75, 1.0), 0.2)
	glow.emission_enabled = true
	glow.emission = Color(0.4, 0.8, 1.0)
	glow.emission_energy_multiplier = 1.4
	screen.material_override = glow
	_phone.add_child(screen)


# ---------------------------------------------------------------------------
# Comportamento
# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if state == State.LEAVING:
		_do_leave(delta)
		return
	if state == State.TALKING:
		_look_at_player(delta)
		# **'O dialogo ha 'a fernì da sulo.** Prima si usciva da TALKING solo
		# rispondendo o tirando un pugno: chi si allontanava senza premere
		# 1-4 restava col pannello a schermo per sempre, coi tasti dei
		# numeri mangiati (niente piu' acquisti in nessun negozio) e — molto
		# peggio — col cronometro del turno fermo, perche' `setup()` ha gia'
		# chiamato `start_boss_phase()`. La giornata non finiva piu'.
		# Il vigile questa protezione ce l'ha da tre versioni; lui no.
		_t_parlata += delta
		var pp := _get_player()
		var lontano: bool = pp == null or global_position.distance_to(
			pp.global_position) > TALK_RANGE * 3.0
		if _t_parlata > 20.0 or lontano:
			_chiude_parlata()
		return

	# **Dentro casa non se cammina appriesso a nisciuno.** L'interno del
	# vascio sta a (300, 300): la distanza diventa quattrocento metri, quindi
	# `far_enough` e' sempre vero e la furia si ferma al pavimento — sopra
	# la soglia del dialogo. Risultato: Borrelli non si calmava mai piu' e
	# intanto camminava fuori dalla mappa. Entrare in casa vale come
	# fumarsi 'na sigaretta: hai smesso di lavorare, e lui aspetta fuori.
	if GameManager.dentro_casa:
		_calma_int_casa(delta)
		return

	_update_furia(delta)

	match state:
		State.ARRIVING:
			# Entra in scena camminando, poi parte l'inseguimento.
			var p := _get_player()
			if p and global_position.distance_to(p.global_position) < 14.0:
				state = State.CHASING
			elif p:
				_step_toward(p.global_position, ARRIVE_SPEED, delta)
		State.CHASING:
			_do_chase(delta)
		State.WAITING_TALK:
			_look_at_player(delta)
			# Se si riscalda (gli hai risposto male) riparte.
			if furia > FURIA_TALK_THRESHOLD:
				state = State.CHASING


func _get_player() -> Node3D:
	return get_tree().get_first_node_in_group("player")


## La furia scende da sola, ma scende molto più in fretta se ti vede lì
## tranquillo a fumare: uno che si fuma 'na sigaretta non sta lavorando.
func _update_furia(delta: float) -> void:
	var p := _get_player()
	var smoking: bool = p != null and p.get("is_smoking") == true
	var far_enough: bool = p == null \
		or global_position.distance_to(p.global_position) > FURIA_SAFE_DISTANCE

	var rate := 0.0
	var floor_value := 0.0
	if smoking:
		rate = FURIA_DECAY_SMOKING # la sigaretta lo disarma comunque
	elif far_enough:
		rate = FURIA_DECAY
		floor_value = FURIA_FLOOR_NO_SMOKE # ma da solo non scende mai abbastanza

	var before := furia
	furia = maxf(floor_value, furia - rate * delta)
	if absf(before - furia) > 0.01:
		GameManager.boss_state_changed.emit(furia, true)

	# Anche mentre sta ancora entrando in scena: se il giocatore si accende
	# subito una sigaretta, Borrelli si sfoga prima ancora di raggiungerlo.
	if (state == State.CHASING or state == State.ARRIVING) \
			and furia <= FURIA_TALK_THRESHOLD:
		state = State.WAITING_TALK
		_say(SAY_CALM)
		SoundManager.play("pop", -6.0, 0.7)
		GameManager.event_started.emit("Borrelli s'è calmato: vai e PARLAGLI (E)")


## Sta dentro casa: Borrelli si ferma dov'e' e la furia scende come se ti
## stessi fumando una sigaretta. Non e' generosita': e' che uno che si e'
## ritirato non sta piu' facendo il parcheggiatore, ed e' esattamente
## quello che Borrelli voleva.
func _calma_int_casa(delta: float) -> void:
	velocity = Vector3.ZERO
	if _anim != null and _anim.has_method("set_speed"):
		_anim.set_speed(0.0)
	var prima := furia
	furia = maxf(0.0, furia - FURIA_DECAY_SMOKING * delta)
	if absf(prima - furia) > 0.01:
		GameManager.boss_state_changed.emit(furia, true)
	if (state == State.CHASING or state == State.ARRIVING) \
			and furia <= FURIA_TALK_THRESHOLD:
		state = State.WAITING_TALK
		_say(SAY_CALM)
		GameManager.event_started.emit(
			"Borrelli s'è calmato. T'aspetta fore.")


func _chiude_parlata() -> void:
	_t_parlata = 0.0
	if GameManager.dialogo_con == self:
		GameManager.dialogo_con = null
	GameManager.boss_dialogue_closed.emit()
	state = State.CHASING
	_say("E addò vaje? Nun avimmo fernuto.")


func _do_chase(delta: float) -> void:
	var p := _get_player()
	if p == null:
		return
	_step_toward(p.global_position, CHASE_SPEED, delta)

	_insult_cd -= delta
	if _insult_cd <= 0.0:
		_insult_cd = randf_range(2.2, 3.4)
		_say(INSULTS[randi() % INSULTS.size()])

	_catch_cd -= delta
	if global_position.distance_to(p.global_position) <= REACH and _catch_cd <= 0.0:
		_catch_cd = CATCH_EVERY
		_catch_player()


## Ti raggiunge: non ti tocca, ti riprende. Il danno è tutto sul sospetto —
## finisci nel video e mezza piazza si gira a guardare.
func _catch_player() -> void:
	_say(SAY_CATCH[randi() % SAY_CATCH.size()])
	SoundManager.play("fail", -3.0, 1.25)
	GameManager.screen_shake.emit(0.45)
	GameManager.add_heat(CATCH_HEAT)
	furia = minf(FURIA_MAX, furia + FURIA_ON_CATCH)
	GameManager.boss_state_changed.emit(furia, true)


func _step_toward(target: Vector3, speed: float, delta: float) -> void:
	var t := target
	t.y = global_position.y
	var before := global_position
	global_position = Passo.verso(self, t, speed * delta)
	_face_toward(t)
	_animate_walk(global_position.distance_to(before))


func _look_at_player(delta: float) -> void:
	var p := _get_player()
	if p:
		_face_toward(p.global_position)
	_animate_walk(0.0)


func _do_leave(delta: float) -> void:
	_step_toward(_leave_point, ARRIVE_SPEED, delta)
	if global_position.distance_to(_leave_point) < 1.5:
		queue_free()


func _face_toward(target: Vector3) -> void:
	var dir: Vector3 = target - global_position
	dir.y = 0.0
	if dir.length() > 0.05:
		# forward(θ) = (−sinθ, 0, −cosθ): θ = atan2(−dir.x, −dir.z).
		_visual_root.rotation.y = atan2(-dir.x, -dir.z)


func _animate_walk(moved: float) -> void:
	if _anim == null:
		return # modello 3D esterno
	_anim.set_speed(moved / maxf(get_physics_process_delta_time(), 0.0001))


# ---------------------------------------------------------------------------
# Il dialogo
# ---------------------------------------------------------------------------

func get_interact_prompt(_from_position: Vector3) -> String:
	if state == State.WAITING_TALK:
		return "[E] parla cu Borrelli"
	if state == State.CHASING or state == State.ARRIVING:
		return "È troppo incazzato per ragionare — scappa e fumati 'na sigaretta"
	return ""


func player_interact() -> void:
	if state != State.WAITING_TALK:
		return
	var p := _get_player()
	if p and global_position.distance_to(p.global_position) > TALK_RANGE:
		return
	state = State.TALKING
	_answered = false
	GameManager.dialogo_con = self
	GameManager.boss_dialogue_opened.emit(_risposte())


## Le risposte di stavolta: le quattro di sempre, più il caffè se ci sta
## un banco a portata e un euro in tasca.
func _risposte() -> Array:
	var r: Array = ANSWERS.duplicate()
	if _vicino_ô_bar() and GameManager.money >= COSTO_CAFFE:
		r.append(RISPOSTA_CAFFE)
	return r


func _vicino_ô_bar() -> bool:
	for b in get_tree().get_nodes_in_group("banco_bar"):
		if b is Node3D and global_position.distance_to(
				(b as Node3D).global_position) < RAGGIO_BAR:
			return true
	return false


## Chiamato dall'HUD quando il giocatore sceglie (0..3).
func answer(index: int) -> void:
	if state != State.TALKING or _answered:
		return
	var lista: Array = _risposte()
	if index < 0 or index >= lista.size():
		return
	_answered = true
	var choice: Dictionary = lista[index]
	if str(choice.get("key", "")) == "E":
		# Il caffè si paga. Un euro, come al banco.
		GameManager.money = maxi(0, GameManager.money - COSTO_CAFFE)
		GameManager.money_changed.emit(GameManager.money)
		SoundManager.play("sorso_caffe", -6.0)
	GameManager.dialogo_con = null
	GameManager.boss_dialogue_closed.emit()
	_say(str(choice["reply"]))

	if choice["right"]:
		_defeated()
	else:
		SoundManager.play("fail", -2.0, 0.8)
		GameManager.screen_shake.emit(0.4)
		GameManager.register_boss_wrong_answer()
		furia = minf(FURIA_MAX, furia + FURIA_ON_WRONG_ANSWER)
		GameManager.boss_state_changed.emit(furia, true)
		GameManager.event_started.emit("Risposta sbagliata! S'è 'ncazzato n'ata vota!")
		state = State.CHASING
		_answered = false


## Menarlo è la cosa peggiore: non lo ferma, lo raddoppia.
func receive_punch(_danno: int = 1) -> void:
	# **'A reazione, no 'o blocco.** Il colpo si vede addosso (clip
	# `Hit_Chest`/`Hit_Head` sopra alla locomozione) ma non toglie il
	# controllo: vedi `Animator.reagisci_colpo`.
	if _anim != null and _anim.has_method("reagisci_colpo"):
		_anim.reagisci_colpo(randf() < 0.4)
	GameManager.register_punch()
	GameManager.report_risky_action(25.0)
	SoundManager.pugno(0.0)
	GameManager.screen_shake.emit(0.7)
	_say(SAY_PUNCHED)
	furia = minf(FURIA_MAX, furia + FURIA_ON_PUNCH)
	GameManager.boss_state_changed.emit(furia, true)
	if state == State.WAITING_TALK or state == State.TALKING:
		GameManager.boss_dialogue_closed.emit()
		state = State.CHASING


func _defeated() -> void:
	state = State.LEAVING
	SoundManager.play("success", -1.0)
	GameManager.boss_state_changed.emit(0.0, false)
	GameManager.event_started.emit("L'HÊ CUNVINTO. 'E ccriature vinceno sempe.")
	GameManager.defeat_boss()
