extends Node3D
## Monumento
## La scultura di Piazzale Tecchio, ricostruita dalla fotografia.
##
## È fatta di quattro cose che si riconoscono a colpo d'occhio, e sono
## quelle che contano perché sia *quella* e non un obelisco qualsiasi:
##
##   1. due sostegni verticali diversi fra loro — a sinistra un fascio di
##      pali tondi, a destra un pilastro piatto e largo;
##   2. il nastro a spirale che sale fra i due e ricade su sé stesso, con
##      la dentatura sul bordo esterno del giro grande;
##   3. due anelli che abbracciano il fascio di sinistra;
##   4. la vela bianca, l'unica cosa chiara di tutta la scultura.
##
## Il nastro non è una mesh curva: è una catena di conci dritti messi uno
## dietro l'altro lungo una spirale calcolata. A venti metri non si vede la
## differenza, e costa una frazione di una mesh generata a mano.
##
## Misure in metri, prese a occhio dalla foto usando lo stadio come righello
## (le gradinate del San Paolo sono alte circa venti metri).

const Tex := preload("res://scripts/textures.gd")

## Altezza dei sostegni.
const ALTEZZA: float = 26.0
## Quanto è distante il pilastro piatto dal fascio di pali.
const LUCE: float = 7.0

var _legno: StandardMaterial3D
var _ferro: StandardMaterial3D
var _pietra: Material
var _vela_mat: StandardMaterial3D


func _ready() -> void:
	_legno = Tex.flat(Color(0.42, 0.37, 0.31), 0.92).duplicate()
	_ferro = Tex.flat(Color(0.26, 0.25, 0.25), 0.6, 0.5).duplicate()
	_pietra = Tex.mondo("marciapiede", Tex.TERRA, 0.95)
	_vela_mat = Tex.flat(Color(0.93, 0.93, 0.9), 0.85).duplicate()

	_basamenti()
	_fascio_pali()
	_pilastro_piatto()
	_spirale()
	_anelli()
	_vela()


## I due zoccoli di pietra sbozzata su cui poggia tutto.
func _basamenti() -> void:
	for dx in [0.0, LUCE]:
		var z := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(3.4, 1.5, 3.0)
		z.mesh = bm
		z.position = Vector3(dx, 0.75, 0)
		z.material_override = _pietra
		add_child(z)
		# Il gradino inferiore, più largo.
		var g := MeshInstance3D.new()
		var gm := BoxMesh.new()
		gm.size = Vector3(4.4, 0.45, 4.0)
		g.mesh = gm
		g.position = Vector3(dx, 0.22, 0)
		g.material_override = _pietra
		add_child(g)

	var corpo := StaticBody3D.new()
	corpo.collision_layer = 1
	corpo.collision_mask = 0
	for dx in [0.0, LUCE]:
		var f := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = Vector3(4.4, 2.2, 4.0)
		f.shape = bx
		f.position = Vector3(dx, 1.1, 0)
		corpo.add_child(f)
	add_child(corpo)


## Il fascio di sinistra: tre pali tondi accostati, di altezze appena
## diverse, che è quello che gli dà l'aria di fascio e non di colonna.
func _fascio_pali() -> void:
	var offset := [Vector3(-0.5, 0, -0.35), Vector3(0.0, 0, 0.35),
		Vector3(0.5, 0, -0.1)]
	var alte := [ALTEZZA, ALTEZZA * 0.93, ALTEZZA * 0.86]
	for i in 3:
		var p := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.34
		cm.bottom_radius = 0.4
		cm.height = alte[i]
		cm.radial_segments = 12
		p.mesh = cm
		p.position = offset[i] + Vector3(0, 1.5 + alte[i] / 2.0, 0)
		p.material_override = _legno
		add_child(p)


## Il sostegno di destra: un pilastro a lastra, molto più largo che
## profondo. Nella foto è quello che regge il piede della spirale.
func _pilastro_piatto() -> void:
	var l := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.9, ALTEZZA, 0.62)
	l.mesh = bm
	l.position = Vector3(LUCE, 1.5 + ALTEZZA / 2.0, 0)
	l.material_override = _legno
	add_child(l)

	# La seconda lastra, un filo più bassa e sfalsata: da lontano fa
	# spessore, da vicino si vede che sono due.
	var l2 := MeshInstance3D.new()
	var bm2 := BoxMesh.new()
	bm2.size = Vector3(1.5, ALTEZZA * 0.9, 0.5)
	l2.mesh = bm2
	l2.position = Vector3(LUCE + 0.9, 1.5 + ALTEZZA * 0.45, -0.5)
	l2.material_override = _legno
	add_child(l2)

	# Il capitello: il pezzo che nella foto sporge in cima.
	var cap := MeshInstance3D.new()
	var cbm := BoxMesh.new()
	cbm.size = Vector3(2.4, 0.9, 1.1)
	cap.mesh = cbm
	cap.position = Vector3(LUCE - 0.2, 1.5 + ALTEZZA + 0.3, 0)
	cap.rotation.z = deg_to_rad(-8)
	cap.material_override = _legno
	add_child(cap)


## Il nastro a spirale: due giri che si stringono, nel piano verticale
## della facciata. Ogni concio è un parallelepipedo orientato lungo la
## tangente della curva.
func _spirale() -> void:
	# Poco piu' di un giro, non due: con due giri il nastro si chiudeva su
	# se stesso e da lontano si leggeva come un bersaglio a cerchi
	# concentrici invece che come un nastro che sale. Nella foto e' una
	# grande "C" aperta che parte in basso a destra, scavalca in alto e
	# rientra: un giro e cinque centesimi.
	const CONCI := 46
	const GIRI := 1.06
	const R_INIZIO := 8.0
	const R_FINE := 2.3
	var centro := Vector3(LUCE * 0.42, 1.5 + ALTEZZA * 0.50, 0.0)

	var punti: Array = []
	for i in range(CONCI + 1):
		var t: float = float(i) / float(CONCI)
		# Parte sotto a destra e gira in senso antiorario.
		var ang: float = -PI * 0.42 + t * TAU * GIRI
		var r: float = lerpf(R_INIZIO, R_FINE, t * t)
		punti.append(centro + Vector3(cos(ang) * r, sin(ang) * r, 0.0))

	for i in range(CONCI):
		var a: Vector3 = punti[i]
		var b: Vector3 = punti[i + 1]
		var mezzo: Vector3 = (a + b) * 0.5
		var dir: Vector3 = b - a
		var lung: float = dir.length()
		if lung < 0.01:
			continue
		var t2: float = float(i) / float(CONCI)
		var concio := MeshInstance3D.new()
		var bm := BoxMesh.new()
		# Il nastro si assottiglia man mano che il giro si stringe.
		bm.size = Vector3(lung * 1.06, lerpf(1.65, 0.85, t2),
			lerpf(0.70, 0.46, t2))
		concio.mesh = bm
		concio.position = mezzo
		# Ruota il concio in modo che il lato lungo segua la tangente.
		concio.rotation.z = atan2(dir.y, dir.x)
		concio.material_override = _legno
		add_child(concio)

		# La dentatura: solo sul primo mezzo giro, sul bordo esterno.
		if t2 < 0.34 and i % 2 == 0:
			var fuori: Vector3 = (mezzo - centro).normalized()
			var dente := MeshInstance3D.new()
			var dm := BoxMesh.new()
			dm.size = Vector3(0.34, 0.42, 0.5)
			dente.mesh = dm
			dente.position = mezzo + fuori * 0.85
			dente.rotation.z = concio.rotation.z
			dente.material_override = _legno
			add_child(dente)

	# Il piede della spirale scende fino al pilastro di destra.
	var piede := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.9, 8.0, 0.55)
	piede.mesh = pm
	piede.position = Vector3(LUCE + 0.4, 1.5 + 5.0, 0.0)
	piede.rotation.z = deg_to_rad(6)
	piede.material_override = _legno
	add_child(piede)


## I due anelli intorno al fascio di pali.
func _anelli() -> void:
	for h in [0.40, 0.58]:
		var anello := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 1.15
		tm.outer_radius = 1.45
		tm.rings = 20
		tm.ring_segments = 8
		anello.mesh = tm
		anello.position = Vector3(0, 1.5 + ALTEZZA * h, 0)
		# Il toro nasce sdraiato: si mette in piedi, come nella foto.
		anello.rotation.x = deg_to_rad(90)
		anello.material_override = _ferro
		add_child(anello)


## La vela bianca: l'unica superficie chiara, e infatti nella foto è la
## prima cosa che si stacca dal legno.
func _vela() -> void:
	var v := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2.6, 6.4)
	v.mesh = pm
	v.position = Vector3(LUCE * 0.52, 1.5 + ALTEZZA * 0.42, -0.2)
	v.rotation = Vector3(deg_to_rad(90), 0, deg_to_rad(-7))
	_vela_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	v.material_override = _vela_mat
	add_child(v)

	# I tiranti che la tengono.
	for d in [-1.0, 1.0]:
		var cavo := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.05
		cm.bottom_radius = 0.05
		cm.height = 4.6
		cm.radial_segments = 6
		cavo.mesh = cm
		cavo.position = Vector3(LUCE * 0.52 + d * 1.6,
			1.5 + ALTEZZA * 0.52, -0.2)
		cavo.rotation.z = deg_to_rad(d * 18.0)
		cavo.material_override = _ferro
		add_child(cavo)
