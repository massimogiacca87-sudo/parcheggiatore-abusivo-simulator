extends StaticBody3D
## Signora d''e spighe
## Il carrettino delle pannocchie alla brace, con la signora dietro che
## rigira le spighe e ti chiama mentre passi.
##
## Non vende niente di utile al mestiere: serve a far vivere il mercato, e
## il fumo della brace è la cosa che si vede da più lontano di tutto il
## quartiere. Di notte la brace è l'unica cosa calda in mezzo al blu.

const Tex := preload("res://scripts/textures.gd")
const Human := preload("res://scripts/human_builder.gd")
const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")

const RICHIAMI := [
	"Spighe! Spighe alla brace!",
	"Guagliò, 'na spiga?",
	"Càvere càvere!",
	"Doje euro 'a spiga, ancora càvera!",
	"E chi 'e ffa comme a me?",
]

const PREZZO: int = 2

var _bubble: Node3D
var _anim: Node = null
var _brace: Array = []
var _fumo: GPUParticles3D
var _detto: float = 0.0
var _t: float = 0.0
var _spighe: Array = []


func _ready() -> void:
	add_to_group("spighe")
	collision_layer = 1
	collision_mask = 0
	_costruisci()
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 2.6, 0)
	add_child(_bubble)


func _costruisci() -> void:
	# Il carretto: piano, gambe, ruote.
	var piano := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.4, 0.14, 1.2)
	piano.mesh = bm
	piano.position = Vector3(0, 0.9, 0)
	piano.material_override = Tex.flat(Color(0.48, 0.34, 0.22), 0.9)
	add_child(piano)

	var forma := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.4, 1.0, 1.2)
	forma.shape = box
	forma.position = Vector3(0, 0.5, 0)
	add_child(forma)

	for dx in [-1.0, 1.0]:
		var ruota := MeshInstance3D.new()
		var rm := CylinderMesh.new()
		rm.top_radius = 0.34
		rm.bottom_radius = 0.34
		rm.height = 0.1
		ruota.mesh = rm
		ruota.rotation.z = deg_to_rad(90)
		ruota.position = Vector3(dx, 0.34, 0.5)
		ruota.material_override = Tex.flat(Color(0.14, 0.13, 0.13), 0.8)
		add_child(ruota)

	# La brace: un letto di carboni che pulsano.
	var vasca := MeshInstance3D.new()
	var vm := BoxMesh.new()
	vm.size = Vector3(1.5, 0.18, 0.8)
	vasca.mesh = vm
	vasca.position = Vector3(-0.2, 1.02, 0)
	vasca.material_override = Tex.flat(Color(0.16, 0.15, 0.15), 0.8)
	add_child(vasca)

	for i in range(9):
		var carbone := MeshInstance3D.new()
		var cm := BoxMesh.new()
		cm.size = Vector3(0.14, 0.06, 0.14)
		carbone.mesh = cm
		carbone.position = Vector3(-0.82 + (i % 5) * 0.3, 1.11,
			-0.2 + float(i / 5) * 0.36)
		carbone.material_override = Tex.flat(
			Color(0.9, 0.35, 0.1), 0.9, 0.0, 2.0).duplicate()
		add_child(carbone)
		_brace.append(carbone)

	# Le spighe sulla griglia.
	for i in range(6):
		var sp := MeshInstance3D.new()
		var sm := CylinderMesh.new()
		sm.top_radius = 0.055
		sm.bottom_radius = 0.06
		sm.height = 0.4
		sp.mesh = sm
		sp.rotation.z = deg_to_rad(90)
		sp.position = Vector3(-0.8 + i * 0.26, 1.2, 0.0)
		sp.material_override = Tex.flat(Color(0.88, 0.72, 0.18), 0.85)
		add_child(sp)
		_spighe.append(sp)

	# L'ombrellone del carretto.
	var palo := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.04
	pm.bottom_radius = 0.04
	pm.height = 2.2
	palo.mesh = pm
	palo.position = Vector3(1.0, 1.9, -0.4)
	palo.material_override = Tex.flat(Color(0.3, 0.3, 0.32), 0.6)
	add_child(palo)
	var tenda := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.05
	tm.bottom_radius = 1.5
	tm.height = 0.5
	tenda.mesh = tm
	tenda.position = Vector3(1.0, 3.0, -0.4)
	tenda.material_override = Tex.flat(Color(0.8, 0.28, 0.24), 0.9)
	add_child(tenda)

	# Il fumo della brace.
	_fumo = GPUParticles3D.new()
	_fumo.position = Vector3(-0.2, 1.25, 0)
	_fumo.amount = 22
	_fumo.lifetime = 3.4
	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0.1, 1, 0)
	pmat.spread = 14.0
	pmat.initial_velocity_min = 0.35
	pmat.initial_velocity_max = 0.7
	pmat.gravity = Vector3(0.2, 0.25, 0)
	pmat.scale_min = 0.3
	pmat.scale_max = 0.9
	pmat.color = Color(0.85, 0.84, 0.8, 0.3)
	_fumo.process_material = pmat
	var qm := QuadMesh.new()
	qm.size = Vector2(0.6, 0.6)
	_fumo.draw_pass_1 = qm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.9, 0.89, 0.86, 0.22)
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	_fumo.material_override = fm
	add_child(_fumo)

	# La signora, dietro al carretto.
	var parts := Human.build(Color(0.42, 0.3, 0.36), Color(0.24, 0.2, 0.24),
		"spighe", 1.58, {
			"hair": Color(0.74, 0.73, 0.7),
			"belly": 0.75, "bald": false, "moustache": false,
			# (0.66) 'O viecchio d''e spighe.
			"capelli": "stempiati", "palpebre": "stanche",
			"sopracciglia": "dritte", "naso": "grosso", "bocca": "sorriso",
			"barba": "sfatta", "rughe": "vecchio", "cintura": true,
			"colletto": false, "catenina": false,
		})
	var corpo: Node3D = parts["root"]
	corpo.position = Vector3(0, 0, -1.1)
	corpo.rotation.y = PI
	add_child(corpo)
	_anim = parts.get("anim", null)
	# Tiene un braccio sulla griglia: rigira le spighe.
	if _anim != null:
		_anim.hold_bone("shoulder_r", Vector3(-52.0, 0.0, 0.0))
		_anim.hold_bone("elbow_r", Vector3(-64.0, 0.0, 0.0))


func _process(delta: float) -> void:
	_t += delta
	# La brace respira, e di notte respira di più.
	var notte: float = 1.0 if GameManager.notte else 0.55
	for i in _brace.size():
		var m = _brace[i].material_override
		if m is StandardMaterial3D:
			m.emission_energy_multiplier = notte * (1.6
				+ sin(_t * 2.4 + float(i)) * 0.6)
	# Le spighe girano piano sulla griglia.
	for i in _spighe.size():
		_spighe[i].rotation.x = _t * (0.8 + i * 0.12)

	_detto = maxf(0.0, _detto - delta)
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null or not is_instance_valid(pl):
		return
	if global_position.distance_to(pl.global_position) < 12.0 and _detto <= 0.0:
		_detto = randf_range(7.0, 12.0)
		if _bubble:
			_bubble.say(RICHIAMI[randi() % RICHIAMI.size()], 2.6)


func get_interact_prompt(_da: Vector3) -> String:
	if GameManager.money < PREZZO:
		return "SPIGHE ALLA BRACE — €%d 'a spiga (nun tiene manco chesto)" % PREZZO
	return "SPIGHE ALLA BRACE — [E] pigliatene una (€%d)" % PREZZO


func player_interact() -> void:
	if GameManager.money < PREZZO:
		if _bubble:
			_bubble.say("E cu che m''a pave?", 2.0)
		SoundManager.play("fail", -8.0, 0.9)
		return
	GameManager.money -= PREZZO
	GameManager.money_changed.emit(GameManager.money)
	GameManager.health = minf(100.0, GameManager.health + 14.0)
	GameManager.health_changed.emit(GameManager.health)
	SoundManager.play("coin")
	if _bubble:
		_bubble.say("Càvera càvera! Statte buono.", 2.4)
	GameManager.event_started.emit("'Na spiga alla brace: te sî rimmesso 'nzieme.")
