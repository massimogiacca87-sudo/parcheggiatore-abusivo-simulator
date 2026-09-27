extends StaticBody3D
## Parchimetro3D — 'a macchinetta d''o Comune (0.64)
##
## Arriva con le strisce blu (vedi `strisce_blu.gd`). Finché ne resta uno in
## piedi nella piazza, chi posteggia sulle strisce blu paga lui e non te.
## Si sfascia a cazzotti o col ferro: otto punti, cioè sette pugni a mani
## nude (e il fiato finisce), tre botte di cric, due di mazza.
##
## **Come si riconosce.** Non è una scatola grigia: è la colonnina che sta
## in tutte le strade d'Italia — il palo blu, il corpo grigio col tetto
## tondo blu, il display verde con la tariffa, la tastiera, la fessura
## delle monete, lo scontrino che esce sotto, e sopra il cartello blu con
## la **P** bianca, che si legge da in fondo alla piazza. Il davanti è +Z,
## come i pezzi dei pacchetti (vedi COME-RIPRENDERE, trappola 1).

const Tex := preload("res://scripts/textures.gd")
const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")

const HP_MAX: int = 8
const ALTO: float = 1.72

var zona_id: String = ""
var indice: int = -1
var rotto: bool = false
var hp: int = HP_MAX

var _testa: Node3D = null
var _cartello: Node3D = null
var _display: MeshInstance3D = null
var _display_mat: StandardMaterial3D = null
var _scritta: Label3D = null
var _grazie_t: float = 0.0
var _trema_t: float = 0.0


func _ready() -> void:
	add_to_group("parchimetri")
	collision_layer = 1
	collision_mask = 0
	_costruisci()
	var f := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(0.44, ALTO, 0.36)
	f.shape = b
	f.position = Vector3(0, ALTO * 0.5, 0)
	add_child(f)


## Il punto dove si mette chi paga: settantacinque centimetri davanti. Si
## calcola quando serve (a `_ready` la posizione può non esserci ancora).
func punto_pagamento() -> Vector3:
	return global_position + global_transform.basis.z * 0.75


## Se nasce già rotto (la piazza ce l'aveva ieri), si mette subito a terra
## senza botti né monete.
func metti_rotto() -> void:
	rotto = true
	hp = 0
	_posa_rotta()


# ---------------------------------------------------------------------------
# 'O modello
# ---------------------------------------------------------------------------

func _costruisci() -> void:
	var blu := Tex.flat(Color(0.09, 0.27, 0.62), 0.45, 0.35)
	var blu_scuro := Tex.flat(Color(0.12, 0.17, 0.26), 0.55, 0.55)
	var grigio := Tex.flat(Color(0.70, 0.72, 0.74), 0.4, 0.55)
	var nero := Tex.flat(Color(0.05, 0.05, 0.06), 0.6)
	var cemento := Tex.flat(Color(0.45, 0.44, 0.42), 0.9)

	_scatola(self, Vector3(0.38, 0.06, 0.32), Vector3(0, 0.03, 0), cemento)
	# 'O palo: quadro, blu scuro, con due bulloni alla base.
	_scatola(self, Vector3(0.13, 1.02, 0.13), Vector3(0, 0.57, 0), blu_scuro)
	for bx in [-0.12, 0.12]:
		_scatola(self, Vector3(0.04, 0.03, 0.04), Vector3(bx, 0.075, 0.1), nero)

	# 'A capa: tutto quello che si sfascia sta qui sotto.
	_testa = Node3D.new()
	_testa.name = "Testa"
	_testa.position = Vector3(0, 1.08, 0)
	add_child(_testa)
	_scatola(_testa, Vector3(0.40, 0.50, 0.28), Vector3(0, 0.25, 0), grigio)
	# 'O tetto tondo, blu.
	var tetto := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.2
	tm.bottom_radius = 0.2
	tm.height = 0.28
	tm.radial_segments = 16
	tetto.mesh = tm
	tetto.rotation.x = PI * 0.5
	tetto.position = Vector3(0, 0.5, 0)
	tetto.scale = Vector3(1.0, 1.0, 0.55)
	tetto.material_override = blu
	_testa.add_child(tetto)
	# 'A fascia blu d''o davanti, con la P piccola.
	_scatola(_testa, Vector3(0.36, 0.09, 0.012), Vector3(0, 0.44, 0.145), blu)
	var p_piccola := _scritta_3d("P", 44, Color(1, 1, 1), Vector3(-0.12, 0.44, 0.153))
	_testa.add_child(p_piccola)
	var parcheggio := _scritta_3d("PARCHEGGIO", 12, Color(1, 1, 1), Vector3(0.05, 0.44, 0.153))
	_testa.add_child(parcheggio)

	# 'O display verde c''a tariffa.
	_display = MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(0.24, 0.085, 0.012)
	_display.mesh = dm
	_display.position = Vector3(0, 0.33, 0.145)
	_display_mat = StandardMaterial3D.new()
	_display_mat.albedo_color = Color(0.45, 0.85, 0.55)
	_display_mat.emission_enabled = true
	_display_mat.emission = Color(0.35, 0.9, 0.5)
	_display_mat.emission_energy_multiplier = 0.9
	_display.material_override = _display_mat
	_testa.add_child(_display)
	_scritta = _scritta_3d("€ 1,50 / ora", 16, Color(0.05, 0.18, 0.08),
		Vector3(0, 0.33, 0.153))
	_testa.add_child(_scritta)

	# 'A tastiera: sei tasti grigi, uno verde e uno rosso.
	var tasto := Tex.flat(Color(0.30, 0.31, 0.33), 0.5)
	for r in range(2):
		for c in range(3):
			_scatola(_testa, Vector3(0.045, 0.03, 0.02),
				Vector3(-0.07 + 0.07 * c, 0.24 - 0.045 * r, 0.148), tasto)
	_scatola(_testa, Vector3(0.05, 0.035, 0.022), Vector3(0.14, 0.24, 0.148),
		Tex.flat(Color(0.15, 0.6, 0.25), 0.4))
	_scatola(_testa, Vector3(0.05, 0.035, 0.022), Vector3(0.14, 0.195, 0.148),
		Tex.flat(Color(0.75, 0.12, 0.1), 0.4))
	# 'A fessura d''e monete, e sotto 'o scontrino che esce.
	_scatola(_testa, Vector3(0.06, 0.012, 0.02), Vector3(0.13, 0.33, 0.15), nero)
	_scatola(_testa, Vector3(0.16, 0.022, 0.02), Vector3(0, 0.1, 0.148), nero)
	_scatola(_testa, Vector3(0.07, 0.05, 0.004), Vector3(0.02, 0.075, 0.16),
		Tex.flat(Color(0.97, 0.96, 0.92), 0.8))
	# L'adesivo giallo.
	_scatola(_testa, Vector3(0.12, 0.05, 0.004), Vector3(-0.1, 0.07, 0.146),
		Tex.flat(Color(0.95, 0.78, 0.12), 0.7))
	var paga := _scritta_3d("PAGARE\nQUI", 9, Color(0.1, 0.1, 0.1), Vector3(-0.1, 0.07, 0.149))
	_testa.add_child(paga)

	# 'O cartiello blu c''a P bianca, ncopp'a n'astina: è quello che si
	# vede da lontano.
	_cartello = Node3D.new()
	_cartello.position = Vector3(0, 0.62, 0)
	_testa.add_child(_cartello)
	_scatola(_cartello, Vector3(0.025, 0.2, 0.025), Vector3(0, 0.1, 0), blu_scuro)
	_scatola(_cartello, Vector3(0.30, 0.30, 0.02), Vector3(0, 0.34, 0), blu)
	# Il bordo bianco del cartello, davanti e dietro.
	var bordo := Tex.flat(Color(0.95, 0.95, 0.95), 0.6)
	for lato in [1.0, -1.0]:
		for e in [[Vector3(0.30, 0.02, 0.004), Vector3(0, 0.48, 0.012 * lato)],
				[Vector3(0.30, 0.02, 0.004), Vector3(0, 0.20, 0.012 * lato)],
				[Vector3(0.02, 0.30, 0.004), Vector3(0.14, 0.34, 0.012 * lato)],
				[Vector3(0.02, 0.30, 0.004), Vector3(-0.14, 0.34, 0.012 * lato)]]:
			_scatola(_cartello, e[0], e[1], bordo)
		var pg := _scritta_3d("P", 150, Color(1, 1, 1), Vector3(0, 0.34, 0.013 * lato))
		if lato < 0.0:
			pg.rotation.y = PI
		_cartello.add_child(pg)


func _scatola(padre: Node3D, dim: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = dim
	m.mesh = bm
	m.position = pos
	m.material_override = mat
	padre.add_child(m)
	return m


func _scritta_3d(testo: String, grandezza: int, colore: Color, pos: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = testo
	l.font_size = grandezza
	l.pixel_size = 0.0012
	l.modulate = colore
	l.outline_size = 0
	l.position = pos
	l.double_sided = false
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


# ---------------------------------------------------------------------------
# 'E botte
# ---------------------------------------------------------------------------

func get_interact_prompt(_da: Vector3) -> String:
	if rotto:
		return "Parchimetro sfasciato"
	return "Parchimetro d''o Comune — cazzotte o fierro p''o sfascià (%d/%d)" % [hp, HP_MAX]


func player_interact() -> void:
	if rotto:
		return
	# Con [E] non si fa niente: si sfascia coi colpi. Glielo dice lui.
	GameManager.event_started.emit(
		"'O parchimetro nun se convince: se sfascia. Cazzotte, cric, mazza…")


func receive_punch(danno: int = 1) -> void:
	if rotto:
		return
	hp -= maxi(1, danno)
	_trema_t = 0.35
	SoundManager.play("botta", -7.0, randf_range(1.15, 1.35))
	_scintille(6)
	# Si nota: è roba del Comune, e fa rumore di ferro.
	GameManager.report_risky_action(5.0)
	if hp <= 0:
		_sfascia()


func _sfascia() -> void:
	rotto = true
	hp = 0
	_posa_rotta()
	_scintille(22)
	_fumo()
	SoundManager.play("botta", -2.0, 0.8)
	SoundManager.play("monete_tante", -4.0)
	# 'E monete ca ce stevano dinto.
	var monete: int = randi_range(GameManager.PARCHIMETRO_MONETE_MIN,
		GameManager.PARCHIMETRO_MONETE_MAX)
	GameManager.add_money(monete)
	_pioggia_monete()
	GameManager.screen_shake.emit(0.35)
	# **Chi te vede?** Sfasciare una macchinetta del Comune sotto gli occhi
	# del vigile è una stella; senza nessuno è solo rumore.
	if GameManager.nu_vigile_te_vede() != null:
		GameManager.crimine(GameManager.PUNTI_PER_STELLA)
		GameManager.event_started.emit("T'ha visto 'o vigile sfascià 'o parchimetro!")
	else:
		GameManager.report_risky_action(14.0)
	GameManager.rompi_parchimetro(zona_id, indice)
	var restano: int = GameManager.parchimetri_sani(zona_id)
	if restano > 0:
		GameManager.event_started.emit(
			"Parchimetro sfasciato (+€%d 'e monete). Ne restano %d." % [monete, restano])
	elif GameManager.strisce_blu_in(zona_id):
		GameManager.event_started.emit(
			"Parchimetre tutte sfasciate (+€%d). Mo' 'e strisce: pittale 'e janco." % monete)


## La posa da rotto: la capa storta, il cartello piegato, il display nero.
func _posa_rotta() -> void:
	if _testa:
		_testa.rotation = Vector3(deg_to_rad(-24.0), deg_to_rad(8.0), deg_to_rad(17.0))
		_testa.position = Vector3(0.03, 1.02, 0.05)
	if _cartello:
		_cartello.rotation = Vector3(deg_to_rad(38.0), 0.0, deg_to_rad(-26.0))
	if _display_mat:
		_display_mat.albedo_color = Color(0.06, 0.07, 0.06)
		_display_mat.emission_enabled = false
	if _scritta:
		_scritta.text = "ERR"
		_scritta.modulate = Color(0.75, 0.15, 0.1)


## Chi posteggia sulle strisce blu viene a pagare: il display dice grazie.
func incassa() -> void:
	if rotto:
		return
	_grazie_t = 2.2
	if _scritta:
		_scritta.text = "GRAZIE"


func _process(delta: float) -> void:
	if _grazie_t > 0.0:
		_grazie_t -= delta
		if _grazie_t <= 0.0 and _scritta and not rotto:
			_scritta.text = "€ 1,50 / ora"
	if _trema_t > 0.0 and _testa and not rotto:
		_trema_t -= delta
		var k: float = _trema_t / 0.35
		_testa.rotation.z = sin(_trema_t * 70.0) * 0.08 * k
		if _trema_t <= 0.0:
			_testa.rotation.z = 0.0


func _scintille(quante: int) -> void:
	var s := CPUParticles3D.new()
	s.amount = quante
	s.one_shot = true
	s.lifetime = 0.45
	s.explosiveness = 1.0
	s.direction = Vector3(0, 1, 0.4)
	s.spread = 75.0
	s.initial_velocity_min = 1.8
	s.initial_velocity_max = 4.2
	s.gravity = Vector3(0, -9.0, 0)
	s.scale_amount_min = 0.03
	s.scale_amount_max = 0.07
	s.mesh = BoxMesh.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.75, 0.25)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.65, 0.15)
	mat.emission_energy_multiplier = 2.2
	(s.mesh as BoxMesh).material = mat
	s.position = Vector3(0, 1.35, 0.18)
	add_child(s)
	s.emitting = true
	_butta_dopo(s, 1.2)


func _fumo() -> void:
	var f := CPUParticles3D.new()
	f.amount = 16
	f.lifetime = 1.8
	f.one_shot = true
	f.explosiveness = 0.6
	f.direction = Vector3(0, 1, 0)
	f.spread = 25.0
	f.initial_velocity_min = 0.4
	f.initial_velocity_max = 0.9
	f.gravity = Vector3(0, 0.3, 0)
	f.scale_amount_min = 0.12
	f.scale_amount_max = 0.3
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 6
	sm.rings = 3
	f.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.35, 0.36, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.material = mat
	f.position = Vector3(0, 1.4, 0)
	add_child(f)
	f.emitting = true
	_butta_dopo(f, 2.5)


func _pioggia_monete() -> void:
	var m := CPUParticles3D.new()
	m.amount = 14
	m.one_shot = true
	m.lifetime = 0.9
	m.explosiveness = 0.9
	m.direction = Vector3(0, 1, 1)
	m.spread = 50.0
	m.initial_velocity_min = 1.5
	m.initial_velocity_max = 3.2
	m.gravity = Vector3(0, -9.8, 0)
	var cm := CylinderMesh.new()
	cm.top_radius = 0.025
	cm.bottom_radius = 0.025
	cm.height = 0.006
	cm.radial_segments = 8
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.76, 0.3)
	mat.metallic = 0.8
	mat.roughness = 0.3
	cm.material = mat
	m.mesh = cm
	m.position = Vector3(0, 1.2, 0.2)
	add_child(m)
	m.emitting = true
	_butta_dopo(m, 1.5)


## Un timer che butta il nodo: niente lambda (trappola 9 vale per gli
## autoload, ma un timer figlio col `queue_free` diretto è il modo più pulito).
func _butta_dopo(n: Node, secondi: float) -> void:
	var t := Timer.new()
	t.wait_time = secondi
	t.one_shot = true
	t.autostart = true
	t.timeout.connect(n.queue_free)
	n.add_child(t)
