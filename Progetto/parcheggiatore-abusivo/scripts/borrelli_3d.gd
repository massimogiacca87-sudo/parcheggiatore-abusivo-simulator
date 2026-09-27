extends CharacterBody3D
## Borrelli3D — il boss di fine turno
##
## Nell'ultimo minuto arriva LUI: giacca di lino a righine, occhiali tondi,
## barba sale e pepe, e una lista di insulti. Non mena nessuno: ti INSEGUE
## e ti RIPRENDE — col telefonino in mano — e ogni volta che ti raggiunge il
## sospetto dei vigili schizza.
##
## Come si vince: NON menandolo — e dalla 0.63 non si può proprio: ti sta
## riprendendo col telefonino, e pugni, mazze e pistole non vanno a segno
## (lo fanno solo arrabbiare di più, e il video gira). Bisogna **fare finta
## di niente**: una sigaretta, un caffè, e stargli lontano, finché non si
## sfoga (la "furia" scende). Quando finalmente si ferma, gli si parla e
## gli si spiega che è per le criature. Le altre risposte lo fanno
## ripartire più incazzato di prima.
##
## Quando arriva lo decide il GameManager (`boss_stasera` e
## `forse_chiamma_borrelli`): la sera, o quando il vigile chiama i
## carabinieri.
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
## **Fa' finta 'e niente, ma luntano** (0.63). Sigaretta o caffè ti fanno
## sembrare uno in pausa, ma se gli stai addosso col telefonino in faccia
## la scena resta la stessa: vicino, la furia scende a meno della metà.
const FURIA_DECAY_CALMO_VICINO: float = 4.5
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
	GameManager.event_started.emit(
		"È ARRIVATO BORRELLI! Fa' finta 'e niente: sigaretta, cafè, e statte luntano.")
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

	# (0.64) La giacca di lino è la "maglia" del pupo stesso, e sopra ci
	# vanno solo lo spacco con la camicia bianca e i revers. Prima era un
	# cassone di parallelepipedi misurato sul corpo della 0.47, che non c'è
	# più: largo il doppio del busto, girava attorno al pupo come una scatola.
	var parts := Human.build(LINO, Color(0.17, 0.18, 0.22),
		"borrelli", 1.82, {
			"skin": Color(0.83, 0.66, 0.53),
			"hair": Color(0.42, 0.40, 0.38), # sale e pepe
			"belly": 0.35,
			"bald": false,
			"moustache": false,
			# (0.66) Sempre indignato, sempre col telefonino in mano.
			"capelli": "gellati", "palpebre": "sveglie",
			"sopracciglia": "arraggiate", "naso": "aquilino",
			"bocca": "storta", "barba": "", "rughe": "arraggiato",
			"colletto": true, "cintura": true, "catenina": false,
		})
	_visual_root.add_child(parts["root"])
	_legs = parts["legs"]
	_arms = parts["arms"]
	_head = parts["head"]
	_anim = parts.get("anim", null)

	if _head == null:
		return # è stato montato un modello 3D esterno: niente da aggiungere

	_build_face()
	_build_jacket(parts)
	_build_phone()


const LINO := Color(0.74, 0.75, 0.77)


## Occhiali tondi, barba sale e pepe, capelli mossi: i tre tratti che lo
## rendono riconoscibile senza doverne fare il ritratto.
##
## **'Nnanze è +Z.** Sull'osso della testa il davanti è +Z (misurato, vedi
## `maestro_3d.gd` e `POSA_PUPO`): fino alla 0.63 qui stava tutto a −Z, e
## Borrelli girava con gli occhiali e la barba **sulla nuca** — la faccia
## liscia davanti, e dietro un secondo viso. L'ha visto la prima foto da
## tutti i lati (`tools/foto_modello.gd`), dopo sei versioni.
func _build_face() -> void:
	var frame_mat := Tex.flat(Color(0.10, 0.09, 0.10), 0.35)
	var lens_mat := Tex.flat(Color(0.55, 0.62, 0.70, 0.35), 0.1, 0.5)
	lens_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var beard_mat := Tex.flat(Color(0.47, 0.45, 0.42), 0.95)
	var hair_mat := Tex.flat(Color(0.42, 0.40, 0.38), 0.95)

	# --- Occhiali: due cerchi spessi davanti agli occhi, il ponte, le aste ---
	for ex in [-0.052, 0.052]:
		var rim_mesh := TorusMesh.new()
		rim_mesh.inner_radius = 0.030
		rim_mesh.outer_radius = 0.041
		rim_mesh.rings = 16
		rim_mesh.ring_segments = 8
		_pezzo(_head, rim_mesh, Vector3(ex, OCCHI_Y, 0.142), frame_mat,
			Vector3(deg_to_rad(90), 0, 0))
		var lens_mesh := CylinderMesh.new()
		lens_mesh.top_radius = 0.031
		lens_mesh.bottom_radius = 0.031
		lens_mesh.height = 0.004
		_pezzo(_head, lens_mesh, Vector3(ex, OCCHI_Y, 0.140), lens_mat,
			Vector3(deg_to_rad(90), 0, 0))
		# L'asta, dal cerchio all'orecchio.
		var arm_mesh := BoxMesh.new()
		arm_mesh.size = Vector3(0.008, 0.008, 0.12)
		_pezzo(_head, arm_mesh, Vector3(signf(ex) * 0.09, OCCHI_Y + 0.004, 0.08), frame_mat)
	var bridge_mesh := BoxMesh.new()
	bridge_mesh.size = Vector3(0.03, 0.008, 0.008)
	_pezzo(_head, bridge_mesh, Vector3(0, OCCHI_Y + 0.006, 0.146), frame_mat)

	# --- Barba piena: guance e mascella, il mento, i baffi ---
	var jaw_mesh := SphereMesh.new()
	jaw_mesh.radius = 0.104
	jaw_mesh.height = 0.208
	jaw_mesh.radial_segments = 16
	jaw_mesh.rings = 8
	_pezzo(_head, jaw_mesh, Vector3(0, 0.036, 0.036), beard_mat, Vector3.ZERO,
		Vector3(1.0, 0.6, 1.0))
	var chin_mesh := SphereMesh.new()
	chin_mesh.radius = 0.05
	chin_mesh.height = 0.1
	_pezzo(_head, chin_mesh, Vector3(0, 0.002, 0.098), beard_mat, Vector3.ZERO,
		Vector3(1.1, 0.75, 0.75))
	var lip_mesh := BoxMesh.new()
	lip_mesh.size = Vector3(0.088, 0.022, 0.03)
	_pezzo(_head, lip_mesh, Vector3(0, 0.079, 0.126), beard_mat)

	# --- Capelli mossi: due file di ciuffi sopra la fronte e in cima ---
	for fila in [[0.058, 0.212], [-0.012, 0.226]]:
		for x in [-0.058, 0.0, 0.058]:
			var tuft_mesh := SphereMesh.new()
			tuft_mesh.radius = 0.047
			tuft_mesh.height = 0.094
			tuft_mesh.radial_segments = 10
			tuft_mesh.rings = 5
			_pezzo(_head, tuft_mesh, Vector3(x, fila[1] - absf(x) * 0.25, fila[0]),
				hair_mat, Vector3.ZERO, Vector3(1.0, 0.62, 1.05))


## L'altezza degli occhi sull'osso della testa del pupo.
const OCCHI_Y := 0.117


func _pezzo(padre: Node3D, m: Mesh, pos: Vector3, mat: Material,
		rot: Vector3 = Vector3.ZERO, scala: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.position = pos
	mi.rotation = rot
	mi.scale = scala
	mi.material_override = mat
	padre.add_child(mi)
	return mi


## La giacca di lino chiara, aperta sulla camicia bianca. Il lino è già il
## colore del busto del pupo (vedi `_build_visual`): qui sopra, sull'osso
## del petto, vanno lo spacco bianco della camicia e i due revers, e sugli
## avambracci le maniche lunghe (il pupo le ha corte).
func _build_jacket(parts: Dictionary) -> void:
	var bones: Dictionary = parts.get("bones", {})
	var linen_dark := Tex.flat(Color(0.52, 0.54, 0.57), 0.95)
	var camicia := Tex.flat(Color(0.97, 0.97, 0.95), 0.8)
	var linen := Tex.flat(LINO, 0.95)
	var petto: Node3D = bones.get("chest", null)
	if petto != null:
		var v := BoxMesh.new()
		v.size = Vector3(0.075, 0.25, 0.02)
		_pezzo(petto, v, Vector3(0, 0.05, 0.118), camicia)
		for sx in [-1.0, 1.0]:
			var revers := BoxMesh.new()
			revers.size = Vector3(0.042, 0.23, 0.014)
			_pezzo(petto, revers, Vector3(sx * 0.054, 0.07, 0.126), linen_dark,
				Vector3(0, 0, deg_to_rad(-sx * 13.0)))
		# Le righine, solo sui due davanti vicino allo spacco, dove il busto
		# è quasi piatto (più in là girerebbero nell'aria).
		for sx in [-1.0, 1.0]:
			for k in range(2):
				var riga := BoxMesh.new()
				riga.size = Vector3(0.005, 0.2, 0.004)
				_pezzo(petto, riga, Vector3(sx * (0.088 + k * 0.024), 0.0, 0.121 - k * 0.006),
					linen_dark)
	# Le maniche lunghe: un osso tutto loro sull'avambraccio.
	var scheletro := parts.get("scheletro", null) as Skeleton3D
	if scheletro != null:
		for osso in ["lowerarm_l", "lowerarm_r"]:
			if scheletro.find_bone(osso) < 0:
				continue
			var att := BoneAttachment3D.new()
			att.bone_name = osso
			scheletro.add_child(att)
			var manica := CylinderMesh.new()
			manica.top_radius = 0.046
			manica.bottom_radius = 0.05
			manica.height = 0.2
			manica.radial_segments = 10
			_pezzo(att, manica, Vector3(0, 0.11, 0), linen)


## Il telefonino alzato davanti alla faccia: è quello che ti fa male, non le
## mani. Il braccio sinistro si **punta** (vedi `animator.punta_osso`): il
## braccio avanti e in giù, l'avambraccio su verso la faccia. Col vecchio
## `hold_bone` il braccio restava giù, e il telefono con lui.
func _build_phone() -> void:
	if _arms.is_empty() or _arms[0] == null:
		return
	_phone = Node3D.new()
	_phone.position = Vector3(0, 0.07, 0.02)
	(_arms[0] as Node3D).add_child(_phone)
	if _anim != null and _anim.has_method("punta_osso"):
		_anim.punta_osso("shoulder_l", Vector3(0.02, -0.36, -0.93))
		_anim.punta_osso("elbow_l", Vector3(0.36, 0.58, -0.73))

	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.075, 0.145, 0.014)
	_pezzo(_phone, body_mesh, Vector3.ZERO, Tex.flat(Color(0.08, 0.08, 0.09), 0.3, 0.4))
	var screen_mesh := BoxMesh.new()
	screen_mesh.size = Vector3(0.062, 0.125, 0.004)
	var glow := Tex.flat(Color(0.35, 0.75, 1.0), 0.2)
	glow.emission_enabled = true
	glow.emission = Color(0.4, 0.8, 1.0)
	glow.emission_energy_multiplier = 1.4
	_pezzo(_phone, screen_mesh, Vector3(0, 0, -0.009), glow)
	# Dietro, verso di te: l'obiettivo e la lucetta rossa che registra.
	var obiettivo := CylinderMesh.new()
	obiettivo.top_radius = 0.009
	obiettivo.bottom_radius = 0.009
	obiettivo.height = 0.006
	_pezzo(_phone, obiettivo, Vector3(-0.018, 0.052, 0.009),
		Tex.flat(Color(0.02, 0.02, 0.03), 0.1, 0.6), Vector3(deg_to_rad(90), 0, 0))
	var rec := SphereMesh.new()
	rec.radius = 0.006
	rec.height = 0.012
	var rosso := Tex.flat(Color(1.0, 0.1, 0.08), 0.3)
	rosso.emission_enabled = true
	rosso.emission = Color(1.0, 0.08, 0.05)
	rosso.emission_energy_multiplier = 3.0
	_rec = _pezzo(_phone, rec, Vector3(0.022, 0.056, 0.009), rosso)


## 'A lucetta del REC lampeggia, e il telefono guarda sempre lui (lo schermo
## verso la faccia, l'obiettivo verso chi sta riprendendo).
var _rec: MeshInstance3D = null
var _rec_t: float = 0.0


func _process(delta: float) -> void:
	if _phone == null or _head == null or not is_instance_valid(_phone):
		return
	_rec_t += delta
	if _rec != null:
		_rec.visible = fmod(_rec_t, 1.0) < 0.6
	var occhi: Vector3 = _head.global_transform * Vector3(0, OCCHI_Y, 0.1)
	var qui: Vector3 = _phone.global_position
	if qui.distance_to(occhi) > 0.05:
		_phone.look_at(occhi, Vector3.UP)


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
	var far_enough: bool = p == null \
		or global_position.distance_to(p.global_position) > FURIA_SAFE_DISTANCE

	var rate := 0.0
	var floor_value := 0.0
	if fa_finta_e_niente():
		rate = FURIA_DECAY_SMOKING if far_enough else FURIA_DECAY_CALMO_VICINO
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


## **'A sigaretta o 'o cafè** (0.63): le due cose che fa uno del quartiere
## in pausa. Il caffè vale per tutto il quarto di minuto della sua spinta
## (`GameManager.caffe_boost`), da tasca o al banco.
func fa_finta_e_niente() -> bool:
	var p := _get_player()
	if p != null and p.get("is_smoking") == true:
		return true
	return GameManager.caffe_boost > 0.0


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
	# **'A collina** (0.63): adesso nasce vicino a te, anche al Vomero, e
	# senza questo camminava dentro al terrapieno.
	var y_giusta: float = Collina.alzata(global_position.x, global_position.z)
	if not GameManager.dentro_casa:
		global_position.y = move_toward(global_position.y, y_giusta, 6.0 * delta)
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
		return "È troppo incazzato pe' ragiona' — sigaretta, cafè, e statte luntano"
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


## **Nun se pò tuccà** (0.63). Il capo: *"Per battere Borrelli non
## funzionano le armi, perché ti riprende col telefono e non puoi
## picchiarlo."* Prima il colpo arrivava (si vedeva la reazione) e gli
## aumentava solo la furia. Adesso non arriva proprio: si scansa col
## telefonino alzato, e ogni tentativo finisce nel video — furia su,
## sospetto su, e nessun colpo a segno. Vale per pugni, mazze e pistole:
## passano tutti di qua.
const SAY_SCANSA := ["STO RIPRENNENNO TUTTO!", "NUN ME TUCCÀ! È TUTTO 'N DIRETTA!",
	"AGGRESSIONE! AVITE VISTO TUTTI!", "BRAVO, FALLO N'ATA VOTA. 'A GENTE VEDE."]
const SAY_TENTATIVO := "Nun 'o puo' tuccà: te sta riprennenno."


func receive_punch(_danno: int = 1) -> void:
	SoundManager.vuoto()
	GameManager.report_risky_action(25.0)
	GameManager.screen_shake.emit(0.3)
	_say(SAY_SCANSA[randi() % SAY_SCANSA.size()])
	GameManager.avvisa_strada(SAY_TENTATIVO)
	furia = minf(FURIA_MAX, furia + FURIA_ON_PUNCH)
	GameManager.boss_state_changed.emit(furia, true)
	if state == State.WAITING_TALK or state == State.TALKING:
		if GameManager.dialogo_con == self:
			GameManager.dialogo_con = null
		GameManager.boss_dialogue_closed.emit()
		state = State.CHASING


func _defeated() -> void:
	state = State.LEAVING
	SoundManager.play("success", -1.0)
	GameManager.boss_state_changed.emit(0.0, false)
	GameManager.event_started.emit("L'HÊ CUNVINTO. 'E ccriature vinceno sempe.")
	GameManager.defeat_boss()
