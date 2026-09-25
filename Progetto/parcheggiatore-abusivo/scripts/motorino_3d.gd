extends CharacterBody3D
## Motorino3D
## Il motorino di quartiere: 3-4 persone sopra, nessun casco, clacson a
## palla e nessuna intenzione di rallentare. Sfreccia lungo il largo ogni
## 30-45 secondi: se ti prende, ti stende (stordimento, schermo che trema,
## e loro che ti insultano pure).

const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const Human := preload("res://scripts/human_builder.gd")
const Tex := preload("res://scripts/textures.gd")
const Models := preload("res://scripts/models.gd")

const SPEED: float = 15.0
const WARNING_TIME: float = 1.6 # secondi di rombo/clacson prima di partire
const HIT_RADIUS: float = 1.75
const HIT_HALF_LENGTH: float = 1.2 # tolleranza lungo la direzione di marcia
const SHIRT_COLORS := [
	Color(0.85, 0.25, 0.3), Color(0.2, 0.5, 0.8), Color(0.95, 0.8, 0.2),
	Color(0.3, 0.7, 0.4), Color(0.7, 0.35, 0.75), Color(0.95, 0.95, 0.95),
]
const INSULTS := [
	"LEVATE 'A MIEZ'!!", "OINÈ, SCANSATE!!", "MA CHE FAI 'NCOPP' 'A STRADA?!",
	"AAAAH! GUAGLIÓ!!", "STATT' ATTIENT'!!",
]

var target_x: float = 0.0
var _warning: float = WARNING_TIME
var _hit_done: bool = false
var _prev_pos: Vector3
var _visual_root: Node3D
var _wheels: Array = []
var _riders: Array = []
var _bubble: Node3D
var _time: float = 0.0
var _honk_cd: float = 0.0
# Dove si siedono i passeggeri. I valori di default sono tarati sul
# motorino a scatole; col modello 3D esterno vengono ricalcolati sulla sella.
# `_rider_y` è la quota del **bacino** di chi sta seduto: la sella della
# Vespa sta a 0,77–0,83 (misurata a fette di dieci centimetri), e il bacino
# sta un palmo sopra alla sella, non dentro.
var _rider_y: float = 0.72
var _rider_front_z: float = -0.30
var _rider_spacing: float = 0.42
## I guagliuni ncopp'ô motorino so' guagliuni: un metro e sessanta.
var _rider_alt: float = 1.66


func _ready() -> void:
	add_to_group("motorini")
	collision_layer = 0 # non blocca nessuno: è un pericolo, non un ostacolo
	collision_mask = 0


## from_left: da che lato entra. z: la corsia su cui sfreccia.
## `origine`: vedi la nota in cat_3d.gd. La piazza dentro alla citta' e'
## spostata, e i punti locali non sono piu' quelli del mondo.
func setup(zone_width: float, z: float, from_left: bool,
		origine: Vector3 = Vector3.ZERO) -> void:
	global_position = origine + Vector3(
		-3.0 if from_left else zone_width + 3.0, 0.0, z)
	target_x = origine.x + (zone_width + 4.0 if from_left else -4.0)
	# forward = (−sinθ, 0, −cosθ): −90° guarda verso +X, +90° verso −X
	rotation.y = deg_to_rad(-90.0) if from_left else deg_to_rad(90.0)
	_prev_pos = global_position
	_build_visual()
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 2.5, 0)
	add_child(_bubble)
	_bubble.say(INSULTS[randi() % INSULTS.size()], 3.0)
	# Il passaggio vero del motorino: parte subito col preavviso, così il
	# rombo cresce mentre arriva ed è quello a dirti da che parte guardare.
	SoundManager.play("moto_pass", -2.0, randf_range(0.97, 1.05), 0.0)
	SoundManager.play("honk", -6.0, 1.35)
	GameManager.avvisa_strada("MOTORINO!! SCANSATI!")
	GameManager.screen_shake.emit(0.15)


func _build_visual() -> void:
	_visual_root = Node3D.new()
	add_child(_visual_root)

	# Se c'è la Vespa vera in assets/models si monta quella e si saltano
	# scocca, scudo, manubrio e ruote fatti a scatole. I passeggeri invece
	# restano quelli procedurali: vanno solo alzati alla sella del modello.
	var custom := Models.spawn_by_length("motorino")
	if custom != null:
		_visual_root.add_child(custom)
		Models.polish_vehicle(custom)
		var size := Models.size_of(custom)
		# La Vespa è lunga 1,85 m: quattro adulti a grandezza naturale la
		# coprivano tutta e finivano con le gambe dentro l'asfalto. Si
		# rimpiccioliscono un filo, si stringono e si spostano indietro
		# sulla sella, così il motorino si vede ancora.
		_rider_alt = 1.56
		_rider_y = 0.86
		_rider_front_z = 0.12
		_rider_spacing = 0.27
		_build_riders()
		return

	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.55, 0.12, 0.12)
	frame_mat.metallic = 0.5
	frame_mat.roughness = 0.35

	# Scocca
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.34, 0.3, 1.5)
	body.mesh = body_mesh
	body.position = Vector3(0, 0.52, 0)
	body.material_override = frame_mat
	_visual_root.add_child(body)

	# Scudo anteriore (davanti = -Z locale)
	var shield := MeshInstance3D.new()
	var shield_mesh := BoxMesh.new()
	shield_mesh.size = Vector3(0.34, 0.6, 0.08)
	shield.mesh = shield_mesh
	shield.position = Vector3(0, 0.75, -0.72)
	shield.material_override = frame_mat
	_visual_root.add_child(shield)

	# Manubrio
	var bar := MeshInstance3D.new()
	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(0.6, 0.05, 0.05)
	bar.mesh = bar_mesh
	bar.position = Vector3(0, 1.05, -0.6)
	var bar_mat := StandardMaterial3D.new()
	bar_mat.albedo_color = Color(0.1, 0.1, 0.12)
	bar.material_override = bar_mat
	_visual_root.add_child(bar)

	# Faro acceso
	var lamp := MeshInstance3D.new()
	var lamp_mesh := SphereMesh.new()
	lamp_mesh.radius = 0.09
	lamp_mesh.height = 0.18
	lamp.mesh = lamp_mesh
	lamp.position = Vector3(0, 0.85, -0.78)
	var lamp_mat := StandardMaterial3D.new()
	lamp_mat.albedo_color = Color(1.0, 0.97, 0.8)
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color(1.0, 0.9, 0.6)
	lamp_mat.emission_energy_multiplier = 2.2
	lamp.material_override = lamp_mat
	_visual_root.add_child(lamp)

	# Ruote
	var wheel_mat := StandardMaterial3D.new()
	wheel_mat.albedo_color = Color(0.05, 0.05, 0.05)
	for wz in [-0.62, 0.62]:
		var wheel := MeshInstance3D.new()
		var wheel_mesh := CylinderMesh.new()
		wheel_mesh.top_radius = 0.26
		wheel_mesh.bottom_radius = 0.26
		wheel_mesh.height = 0.11
		wheel.mesh = wheel_mesh
		wheel.rotation.z = deg_to_rad(90)
		wheel.position = Vector3(0, 0.26, wz)
		wheel.material_override = wheel_mat
		_visual_root.add_child(wheel)
		_wheels.append(wheel)

	_build_riders()


## 3 o 4 passeggeri, rigorosamente senza casco, uno appiccicato all'altro.
## i = 0 è quello dietro di tutti, l'ultimo è chi guida.
func _build_riders() -> void:
	var n_riders := 3 + (randi() % 2)
	for i in range(n_riders):
		_build_rider(_rider_front_z + (n_riders - 1 - i) * _rider_spacing, i)


func _build_rider(z: float, _idx: int) -> void:
	var shirt: Color = SHIRT_COLORS[randi() % SHIRT_COLORS.size()]
	# Chi sta dietro sta un dito più in alto: oltre la sella (che finisce a
	# z 0,6) c'è il portapacchi, e l'ultimo ci sta appollaiato sopra.
	var su: float = maxf(0.0, z - 0.5) * 0.25
	var parts := Human.in_sella(shirt, Color(0.2, 0.22, 0.3),
		_rider_alt + randf_range(-0.05, 0.05), _rider_y + su, z,
		{"bald": false})
	var body: Node3D = parts["root"]
	_visual_root.add_child(body)
	_riders.append(body)

	# Casco? Manco per sogno. Al massimo gli occhiali da sole.
	if parts["head"] != null and randf() < 0.4:
		var shades := MeshInstance3D.new()
		var shades_mesh := BoxMesh.new()
		shades_mesh.size = Vector3(0.24, 0.05, 0.05)
		shades.mesh = shades_mesh
		shades.position = Vector3(0, 0.16, -0.11)
		shades.material_override = Tex.flat(Color(0.04, 0.04, 0.05), 0.15, 0.5)
		parts["head"].add_child(shades)


func _physics_process(delta: float) -> void:
	if _visual_root == null: # setup() non ancora chiamato
		return
	_time += delta

	# Fase di preavviso: il motorino è ancora fuori campo e romba/strombazza,
	# così hai il tempo di capire da che parte arriva e toglierti di mezzo.
	if _warning > 0.0:
		_warning -= delta
		_honk_cd -= delta
		if _honk_cd <= 0.0:
			_honk_cd = 0.6
			SoundManager.play("honk", -9.0, randf_range(1.3, 1.5))
		return

	_prev_pos = global_position
	global_position.x = move_toward(global_position.x, target_x, SPEED * delta)
	var moved: float = absf(global_position.x - _prev_pos.x)

	# Ruote che girano e sobbalzo da asfalto sconnesso
	for w in _wheels:
		w.rotation.y += moved * 4.0
	_visual_root.position.y = sin(_time * 22.0) * 0.025
	_visual_root.rotation.z = sin(_time * 7.0) * 0.05

	_honk_cd -= delta
	if _honk_cd <= 0.0:
		_honk_cd = randf_range(0.7, 1.1)
		SoundManager.play("honk", -11.0, randf_range(1.25, 1.5))

	_check_hit()

	if absf(global_position.x - target_x) < 0.1:
		queue_free()


## Se il player non si scansa, lo prende in pieno.
## A 15 m/s il motorino avanza 25 cm per tick di fisica: non basta guardare
## la distanza puntuale, bisogna controllare tutto il segmento percorso in
## questo frame — altrimenti a velocità alta lo "attraversa" senza toccarlo.
func _check_hit() -> void:
	if _hit_done:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var p := Vector2(player.global_position.x, player.global_position.z)
	var a := Vector2(_prev_pos.x, _prev_pos.z)
	var b := Vector2(global_position.x, global_position.z)

	# Distanza dal segmento a→b (il tratto percorso in questo frame),
	# esteso un po' in avanti per tenere conto dell'ingombro del mezzo.
	var ab := b - a
	var len_sq := ab.length_squared()
	var t: float = 0.0
	if len_sq > 0.0001:
		t = clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
	var closest := a + ab * t
	var dist: float = p.distance_to(closest)
	# Tolleranza extra davanti al muso
	if dist > HIT_RADIUS:
		var nose := b + (ab.normalized() * HIT_HALF_LENGTH if len_sq > 0.0001 else Vector2.ZERO)
		if p.distance_to(nose) > HIT_RADIUS:
			return

	_hit_done = true
	SoundManager.play("bump", 0.0, 0.8)
	GameManager.screen_shake.emit(1.0)
	GameManager.avvisa_strada("T'HANNO PIGLIATO IN PIENO!")
	# Era la botta piu' cara del gioco: ventotto punti, mezza barra. Adesso
	# nove: si sente, la camera cade, quello ti urla dietro — ma non ti
	# rovina la giornata. Il motorino va evitato, non temuto.
	GameManager.damage_player(9.0, "T'ha pigliato 'o motorino", global_position)
	if _bubble:
		_bubble.say(INSULTS[randi() % INSULTS.size()], 2.0)
	if player.has_method("knock_down"):
		var d: Vector3 = player.global_position - global_position
		d.y = 0.0
		var push: Vector3 = d.normalized() if d.length() > 0.01 else Vector3(0, 0, 1)
		# Spinta anche in avanti, nel senso di marcia: ti "porta via"
		push = (push + Vector3(ab.x, 0, ab.y).normalized() * 1.2).normalized()
		player.knock_down(push)
