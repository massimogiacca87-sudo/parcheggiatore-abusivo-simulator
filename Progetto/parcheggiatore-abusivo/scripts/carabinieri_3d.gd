extends StaticBody3D
## Carabinieri3D — la pattuglia che il vigile chiama quando lo meni troppo
##
## Il vigile ha troppi punti per essere steso: molto prima che finiscano
## prende la radio e chiama i rinforzi. Da lì parte questa: entra dal fondo
## della piazza a sirena spiegata, ti punta, e quando ti arriva addosso il
## turno finisce con l'arresto — che qui costa più del solito, perché al
## verbale ci aggiungono l'aggressione a pubblico ufficiale.
##
## L'unica via d'uscita è **uscire dalla piazza col furgone dietro**: se
## resti fuori dal loro raggio abbastanza a lungo se ne vanno. Ma nel
## frattempo non stai lavorando.

const Tex := preload("res://scripts/textures.gd")
const Models := preload("res://scripts/models.gd")
const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")

## **'A pattuglia jeva cchiù chiano 'e te.**
##
## Il capo: "è troppo facile fuggire dai carabinieri". Aveva ragione e il
## conto lo diceva: il furgone andava a 6,2 metri al secondo, il giocatore
## di corsa ne fa **8,2**. Bastava premere shift e tenere dritto, e in
## quattro secondi eri fuori dai trenta metri.
##
## Adesso il furgone va a 7,9 — appena sotto la corsa piena, quindi in
## rettilineo ti sta attaccato e ti stanca, ma tagliando per i vicoli lo
## semini lo stesso. È la differenza fra "impossibile" e "difficile".
const DRIVE_SPEED: float = 7.9
const CATCH_RADIUS: float = 2.6
const GIVE_UP_TIME: float = 42.0     # quanto ti stanno dietro prima di lasciar perdere
const GIVE_UP_DISTANCE: float = 45.0 # se sei più lontano di così, il timer scorre
## **'A radio se sentette pe' tutt''o turno.**
##
## Suonava **ogni 1,15 secondi**, sempre, allo stesso volume, per tutti i
## ventisei secondi dell'inseguimento: un metronomo. Il capo l'ha detto
## chiaro — "è troppo fastidioso, ed è continuo e costante".
##
## Una radio della polizia vera gracchia ogni tanto, non a tempo. Adesso
## esce a intervalli **irregolari** fra i quattro e i nove secondi, e il
## volume scende con la distanza: da lontano è un rumore che dice che ti
## stanno cercando, da vicino è la voce che ti sta addosso.
const SIREN_MIN: float = 4.0
const SIREN_MAX: float = 9.0

## La pattuglia si puo' fermare a mazzate. Non e' realismo, e' equilibrio:
## finora l'arrivo dei carabinieri era una condanna senza appello, e l'unica
## risposta era correre. Con sessanta punti di scocca il furgone non lo
## fermi a mani nude (tre di danno: venti colpi, e ti prendono prima), ne'
## col curtiello — ci vuole 'o fierro o 'o Kalash. Cioe' e' esattamente il
## premio per chi ha speso i soldi delle armi grosse.
const MAX_HP: int = 60

const SAY := ["ALT! CARABINIERI!", "FERMO DOVE SEI!", "SCENDI 'A 'LLOCO!"]

var _visual: Node3D
## Se la scocca è la gazzella del Car Pack (le misure di banda e
## lampeggianti sono le sue) o una delle riserve.
var _gazzella: bool = false
var _bubble: Node3D
var _lights: Array = []       # i due lampeggianti sul tetto
var _light_time: float = 0.0
var _siren_cd: float = 0.0
var _left: float = GIVE_UP_TIME
var _done: bool = false
var hp: int = MAX_HP


func _ready() -> void:
	add_to_group("carabinieri")
	# Il furgone e' un corpo solido: prima era un Node3D senza collisioni,
	# gli si passava attraverso e non lo si poteva colpire. Sta sul livello
	# del mondo con maschera zero, cosi' ferma il player e le pallottole ma
	# non insegue niente per conto suo.
	collision_layer = 1
	collision_mask = 0
	var forma := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.7, 1.3, 3.6)
	forma.shape = box
	forma.position = Vector3(0, 0.8, 0)
	add_child(forma)
	_build_visual()
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 2.9, 0)
	add_child(_bubble)
	_bubble.say(SAY[0], 3.0)
	SoundManager.play("radio_polizia", -2.0, 1.0)
	GameManager.screen_shake.emit(0.6)


func setup(entry: Vector3) -> void:
	global_position = entry


func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)

	# La scocca: **la gazzella vera** (0.59), la macchina della polizia del
	# Car Pack portata a 4,25 metri, verniciata blu notte con la banda
	# rossa dell'Arma. Fino alla 0.58 si chiedeva `car_lusso`, che dalla
	# 0.46 non esisteva più: la pattuglia era **una scatola blu senza
	# ruote**, e nessuno se n'era accorto perché arriva di corsa e la
	# guardi scappando. Se il modello manca si prova la SUV, poi la scatola.
	var body := Models.spawn_by_length("car_carabinieri")
	_gazzella = body != null
	if body == null:
		body = Models.spawn_by_length("car_lusso")
	if body != null:
		_visual.add_child(body)
		Models.polish_vehicle(body)
		Models.tint(body, ["body", "carroz", "scocca"],
			Color(0.06, 0.08, 0.16), 0.5, 0.28)
	else:
		# Fallback a scatole, se un domani il modello non c'è più.
		var box := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.8, 1.2, 4.2)
		box.mesh = bm
		box.position = Vector3(0, 0.75, 0)
		box.material_override = Tex.flat(Color(0.06, 0.08, 0.16), 0.3, 0.5)
		_visual.add_child(box)

	_build_livery()
	_build_lightbar()


## La banda rossa lungo la fiancata e la scritta: quello che la rende
## riconoscibile a colpo d'occhio anche di lontano.
##
## Sulla gazzella le misure sono le sue (0.59): la fiancata sta a 0,90-0,94
## dal centro fra le ruote, la porta va da 0,3 a 0,86 d'altezza. La banda
## corre a metà porta, la scritta sopra, come sull'Alfa vera.
func _build_livery() -> void:
	var red := Tex.flat(Color(0.75, 0.08, 0.1), 0.5)
	var white := Tex.flat(Color(0.94, 0.94, 0.92), 0.6)
	var fianco: float = 0.955 if _gazzella else 0.9
	var y_banda: float = 0.50 if _gazzella else 0.78
	var y_scritta: float = 0.70 if _gazzella else 1.02
	var lunga: float = 3.0 if _gazzella else 3.3
	var z0: float = -0.1 if _gazzella else 0.0
	for sx in [-1.0, 1.0]:
		var band := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.04, 0.13, lunga)
		band.mesh = bm
		band.position = Vector3(sx * fianco, y_banda, z0)
		band.material_override = red
		_visual.add_child(band)

		var label := Label3D.new()
		label.text = "CARABINIERI"
		label.font_size = 26
		label.pixel_size = 0.0038
		label.modulate = Color(0.96, 0.96, 0.94)
		label.outline_size = 5
		label.outline_modulate = Color(0.04, 0.05, 0.1)
		label.position = Vector3(sx * (fianco + 0.03), y_scritta, z0)
		label.rotation.y = deg_to_rad(90.0) * sx
		_visual.add_child(label)

		# Fascia bianca sotto la banda rossa
		var strip := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(0.03, 0.05, lunga)
		strip.mesh = sm
		strip.position = Vector3(sx * (fianco + 0.005), y_banda - 0.09, z0)
		strip.material_override = white
		_visual.add_child(strip)


## I lampeggianti sul tetto: blu, e lampeggiano davvero.
##
## Sulla gazzella la barra del file sta a metà tetto (1,30-1,41 d'altezza,
## 0,34-0,59 in lunghezza) ed è **rossa e blu**, all'americana: la nostra la
## copre tutta, e sopra ci stanno i due blu dell'Arma.
func _build_lightbar() -> void:
	var y_barra: float = 1.36 if _gazzella else 1.44
	var z_barra: float = 0.465 if _gazzella else -0.15
	var bar := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.95, 0.14, 0.31) if _gazzella else Vector3(1.05, 0.09, 0.24)
	bar.mesh = bm
	bar.position = Vector3(0, y_barra, z_barra)
	bar.material_override = Tex.flat(Color(0.1, 0.1, 0.12), 0.5)
	_visual.add_child(bar)

	for sx in [-0.3, 0.3]:
		var dome := MeshInstance3D.new()
		var dm := BoxMesh.new()
		dm.size = Vector3(0.4, 0.14, 0.2)
		dome.mesh = dm
		dome.position = Vector3(sx * (0.85 if _gazzella else 1.0),
			y_barra + 0.08, z_barra)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.35, 0.95)
		mat.emission_enabled = true
		mat.emission = Color(0.25, 0.5, 1.0)
		mat.emission_energy_multiplier = 1.0
		dome.material_override = mat
		_visual.add_child(dome)

		var glow := OmniLight3D.new()
		glow.position = Vector3(sx, y_barra + 0.16, z_barra)
		glow.light_color = Color(0.3, 0.5, 1.0)
		glow.light_energy = 2.0
		glow.omni_range = 9.0
		glow.shadow_enabled = false
		_visual.add_child(glow)

		_lights.append({"mesh": dome, "light": glow, "phase": 0.0 if sx < 0 else PI})


func _physics_process(delta: float) -> void:
	_animate_lights(delta)
	if _done:
		return

	# **'A pattuglia s'e' fermata pure essa.** Era l'unico inseguitore senza
	# il blocco che hanno tutti gli altri: continuava a guidare e a suonare
	# la sirena durante il riepilogo di fine turno, da arrestato, e — la
	# peggiore — mentre stavi **dentro casa**, dove il player sta a (300,
	# 300): il furgone guidava per ventisei secondi verso un punto a
	# centosessanta metri fuori dalla citta' prima di arrendersi.
	if GameManager.arrested or GameManager.hospitalized \
			or GameManager.dentro_casa or not GameManager.shift_active:
		_give_up()
		return

	var player := get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return

	var target: Vector3 = player.global_position
	target.y = global_position.y
	# 'O furgone è largo: 'nu metro e mieze 'e orlo, se no smuzzeca ll'angule.
	global_position = Passo.verso(self, target, DRIVE_SPEED * delta,
		1.5)
	_face_toward(target)

	var dist: float = global_position.distance_to(player.global_position)

	_siren_cd -= delta
	if _siren_cd <= 0.0:
		_siren_cd = randf_range(SIREN_MIN, SIREN_MAX)
		# Da quaranta metri quasi non si sente; a cinque è addosso.
		var vol: float = lerpf(-11.0, -30.0,
			clampf(dist / 45.0, 0.0, 1.0))
		SoundManager.play("radio_polizia", vol, randf_range(0.88, 1.12))

	# Se riesci a stargli lontano abbastanza a lungo, se ne vanno.
	if dist > GIVE_UP_DISTANCE:
		_left -= delta
		if _left <= 0.0:
			_give_up()
		return

	if dist <= CATCH_RADIUS:
		_arrest()


func _animate_lights(delta: float) -> void:
	_light_time += delta
	for l in _lights:
		var on: float = 0.5 + 0.5 * sin(_light_time * 9.0 + l["phase"])
		var mat: StandardMaterial3D = l["mesh"].material_override
		mat.emission_energy_multiplier = 0.2 + on * 4.0
		l["light"].light_energy = 0.2 + on * 4.5


func _face_toward(target: Vector3) -> void:
	var dir: Vector3 = target - global_position
	dir.y = 0.0
	if dir.length() > 0.05:
		# forward(θ) = (−sinθ, 0, −cosθ): θ = atan2(−dir.x, −dir.z).
		_visual.rotation.y = atan2(-dir.x, -dir.z)


func _arrest() -> void:
	if _done:
		return
	_done = true
	# Come col vigile: ti girano la faccia e ti tolgono di mano tutto.
	# Uno che viene ammanettato non sta ancora dirigendo una macchina.
	var pl := get_tree().get_first_node_in_group("player")
	if pl != null and pl.has_method("guarda_verso"):
		pl.guarda_verso(self, true)
		pl.interrompi_tutto()
	_bubble.say("È FERNUTA. Sali.", 4.0)
	SoundManager.play("radio_polizia", -2.0)
	GameManager.screen_shake.emit(1.0)
	GameManager.arrest_by_carabinieri()


## Le mazzate al furgone. Quando la scocca cede se ne vanno — e stavolta
## non e' "pe' mo'", e' proprio finita.
func receive_punch(danno: int = 1) -> void:
	if _done:
		return
	hp -= maxi(1, danno)
	GameManager.nemico_colpito.emit("'A pattuglia", maxi(0, hp), MAX_HP)
	SoundManager.pugno(0.0)
	GameManager.screen_shake.emit(0.5)
	if hp <= 0:
		_done = true
		_bubble.say("'O motore!! Se n'è ghiuto 'o motore!", 3.0)
		GameManager.event_started.emit(
			"Hê fermato 'a pattuglia. Mo' cammina, primma ca ne vene n'ata.")
		queue_free()
		return
	_bubble.say(SAY[randi() % SAY.size()], 1.6)


func _give_up() -> void:
	_done = true
	_bubble.say("Pe' stavota è ghiuto bbuono.", 3.0)
	GameManager.event_started.emit("'E carabinieri se ne so' juti. Pe' mo'.")
	queue_free()
