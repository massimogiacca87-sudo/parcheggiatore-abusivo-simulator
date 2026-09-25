extends Node3D
## Mergellina — 'o lungomare
##
## La striscia a nord della città: la carreggiata di Via Caracciolo, la
## passeggiata coi platani e le panchine, il muraglione, e oltre il
## muraglione il mare aperto col Castel dell'Ovo sullo scoglio.
##
## ## Come è disposta, dal centro verso il largo
##
## ```
##   z = 0      il bordo della città (dove finiscono gli isolati)
##   z = -1     cordolo e marciapiede lato monte
##   z = -13    carreggiata, dodici metri, due sensi
##   z = -20    passeggiata, sette metri: palme, panchine, lampioni
##   z = -20.6  'o muraglione, alto un metro e dieci
##   z < -21    mare
## ```
##
## ## Perché il mare è un piano solo e non una griglia animata
##
## La tentazione, con un mare, è fare una griglia di vertici e muoverli con
## un seno nel vertex shader. Costa: per avere onde che si leggono da riva
## servono vertici ogni mezzo metro, e su trecento metri per centosessanta
## sono trecentomila vertici che si ricalcolano a ogni fotogramma, per un
## risultato che a livello degli occhi — che è dove sta la telecamera di
## questo gioco — è quasi indistinguibile da un piano piatto.
##
## Da riva l'acqua non si vede in sezione: si vede dall'alto, di scorcio. E
## di scorcio quello che dice "acqua" non è la forma, sono i riflessi e il
## disegno che scorre. Quelli li fa lo shader su un piano di due triangoli.
##
## L'unico posto dove si vedrebbe la differenza è il profilo dell'orizzonte,
## e lì c'è la foschia.

const Tex := preload("res://scripts/textures.gd")
const Models := preload("res://scripts/models.gd")

## I confini della striscia, in metri. `Z_*` sono negativi: si va verso il
## largo allontanandosi dallo zero.
const Z_CITTA: float = 0.0
const Z_STRADA: float = -13.0
const Z_PASSEGGIATA: float = -20.0
const Z_MURAGLIONE: float = -20.6
const Z_MARE: float = -21.0
## Quanto è profondo il mare disegnato. Oltre c'è la foschia e poi il cielo.
## Allargato per il golfo: l'acqua adesso deve arrivare fino ai due capi e
## alle isole, che stanno a novecento metri. Con i vecchi 520 x 300 il mare
## finiva a meta' strada e dall'alto si vedeva il bordo del piano.
const MARE_PROFONDITA: float = 1150.0
const MARE_LARGHEZZA: float = 2400.0

const ALT_MURAGLIONE: float = 1.10

## Il Castel dell'Ovo. Sta al largo davanti alla parte di ponente, così
## uscendo dal belvedere della piazza te lo trovi sulla sinistra e non
## esattamente in mezzo — e soprattutto non addosso al promontorio dello
## stadio, che sta al largo dalla parte opposta.
const CASTELLO_POS := Vector3(62.0, 0.0, -98.0)
## Lunghezza a cui scalarlo. Il modello vero è 221 m: qui sarebbe più largo
## di tutta la città. A 150 m resta un monumento — alto venticinque metri,
## che da riva è il doppio di un palazzo — senza mangiarsi l'orizzonte.
const CASTELLO_LUNGHEZZA: float = 150.0

## Le barche: posizione, verso in gradi, quale modello, quanto è lunga.
const BARCHE := [
	[52.0, -46.0, 74.0, "barca_1", 6.0],
	[128.0, -38.0, 250.0, "barca_1", 5.4],
	[24.0, -66.0, 200.0, "barca_3", 13.0],
	[160.0, -58.0, 20.0, "barca_2", 9.0],
	[70.0, -78.0, 300.0, "barca_2", 8.0],
	[176.0, -92.0, 160.0, "barca_4", 22.0],
	[8.0, -110.0, 110.0, "barca_5", 21.0],
	[142.0, -136.0, 260.0, "barca_4", 20.0],
	[46.0, -150.0, 40.0, "barca_5", 19.0],
]

var _mare: MeshInstance3D
var _barche: Array = []


func _ready() -> void:
	name = "Mergellina"
	_build_mare()
	_build_strada()
	_build_passeggiata()
	_build_muraglione()
	_build_castello()
	_build_barche()
	_build_piscatore()


# ---------------------------------------------------------------------------
# Il mare
# ---------------------------------------------------------------------------

func _build_mare() -> void:
	_mare = MeshInstance3D.new()
	_mare.name = "Mare"
	var pm := PlaneMesh.new()
	pm.size = Vector2(MARE_LARGHEZZA, MARE_PROFONDITA)
	# Due suddivisioni non servono alla forma — il piano resta piatto — ma
	# senza, su un piano di trecento metri la nebbia volumetrica e la luce
	# si interpolano su due soli triangoli e si vedono le diagonali.
	pm.subdivide_width = 8
	pm.subdivide_depth = 8
	_mare.mesh = pm
	_mare.position = Vector3(LARGHEZZA_CITTA / 2.0, 0.18,
		Z_MARE - MARE_PROFONDITA / 2.0)

	var sh := load("res://assets/shaders/mare.gdshader")
	if sh != null:
		var m := ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("onde",
			_carica("res://assets/textures/mare_normale.jpg"))
		m.set_shader_parameter("schiuma",
			_carica("res://assets/textures/mare_schiuma.jpg"))
		# Dove finisce l'acqua e comincia la scogliera, e quanto in là si
		# vede ancora la schiuma della risacca.
		m.set_shader_parameter("riva_z", Z_MARE)
		m.set_shader_parameter("riva_metri", 7.0)
		_mare.material_override = m
	else:
		var f := StandardMaterial3D.new()
		f.albedo_color = Color(0.05, 0.24, 0.36)
		f.metallic = 0.4
		f.roughness = 0.12
		_mare.material_override = f
	add_child(_mare)


func _carica(p: String) -> Texture2D:
	return load(p) if ResourceLoader.exists(p) else null


## Quanto è larga la città. Si legge dal padre invece di riscriverla, così
## se un giorno la mappa cambia il lungomare la segue.
var LARGHEZZA_CITTA: float = 190.0


# ---------------------------------------------------------------------------
# La carreggiata
# ---------------------------------------------------------------------------

func _build_strada() -> void:
	var w: float = LARGHEZZA_CITTA + 40.0
	var cx: float = LARGHEZZA_CITTA / 2.0
	var l: float = Z_CITTA - Z_STRADA

	var asfalto := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(w, l)
	asfalto.mesh = pm
	asfalto.position = Vector3(cx, 0.02, (Z_CITTA + Z_STRADA) / 2.0)
	asfalto.material_override = Tex.ground("asfalto", Vector2(w, l), 8.0)
	add_child(asfalto)

	# La riga bianca in mezzo, tratteggiata.
	var bianco := Tex.flat(Color(0.88, 0.87, 0.82), 0.9)
	var zc: float = (Z_CITTA + Z_STRADA) / 2.0
	var x: float = -18.0
	while x < w - 18.0:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(2.6, 0.02, 0.18)
		m.mesh = bm
		m.position = Vector3(x, 0.04, zc)
		m.material_override = bianco
		add_child(m)
		x += 6.0

	# I due cordoli, che tengono ferma la carreggiata fra il marciapiede
	# lato monte e la passeggiata lato mare.
	var cordolo := Tex.mondo("marciapiede", Tex.TERRA, 0.94)
	for z in [Z_CITTA - 0.4, Z_STRADA + 0.4]:
		var c := MeshInstance3D.new()
		var cm := BoxMesh.new()
		cm.size = Vector3(w, 0.28, 0.8)
		c.mesh = cm
		c.position = Vector3(cx, 0.14, z)
		c.material_override = cordolo
		add_child(c)


# ---------------------------------------------------------------------------
# La passeggiata
# ---------------------------------------------------------------------------

func _build_passeggiata() -> void:
	var w: float = LARGHEZZA_CITTA + 40.0
	var cx: float = LARGHEZZA_CITTA / 2.0
	var l: float = Z_STRADA - Z_PASSEGGIATA

	var lastre := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(w, l)
	lastre.mesh = pm
	lastre.position = Vector3(cx, 0.03, (Z_STRADA + Z_PASSEGGIATA) / 2.0)
	lastre.material_override = Tex.ground("marciapiede", Vector2(w, l), 3.4)
	add_child(lastre)

	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var x: float = -14.0
	var i := 0
	while x < LARGHEZZA_CITTA + 20.0:
		_palma(Vector3(x, 0.0, Z_PASSEGGIATA + 2.0), rng)
		if i % 2 == 0:
			_lampione(Vector3(x + 6.0, 0.0, Z_PASSEGGIATA + 1.4))
		if i % 3 == 1:
			_panchina(Vector3(x + 4.0, 0.0, Z_PASSEGGIATA + 3.4))
		x += 12.0
		i += 1


## Una palma. Tronco leggermente inclinato e sette foglie a raggiera: è la
## sagoma che dice "lungomare" da duecento metri, e nessun'altra pianta la
## dà. Le foglie sono quadrilateri piegati, non ventagli veri: da vicino si
## vede, ma sul lungomare non ci si va col naso attaccato.
func _palma(pos: Vector3, rng: RandomNumberGenerator) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = rng.randf_range(0.0, TAU)
	add_child(root)

	var h: float = rng.randf_range(6.0, 8.4)
	var corteccia := Tex.flat(Color(0.46, 0.39, 0.30), 0.96)
	# **Il tronco e' sottile.**
	#
	# La prima versione aveva raggio 0,30 — sessanta centimetri di diametro
	# — su tre soli segmenti da due metri l'uno. A schermo veniva fuori un
	# pilastro di cemento, non una palma: una palma da datteri vera ha il
	# fusto di venticinque-trenta centimetri, cioe' la meta'. E con tre
	# segmenti la curvatura non si vede, si vedono tre tubi accostati.
	#
	# Sei segmenti da un metro e un quarto, che si assottigliano salendo e
	# si inclinano un po' di piu' a ogni passo: cosi' il fusto fa la
	# curva morbida che hanno tutte le palme sul mare.
	const SEGMENTI := 6
	var seg: float = h / float(SEGMENTI)
	var piega: float = rng.randf_range(-0.055, 0.055)
	var y := 0.0
	var dx := 0.0
	for k in range(SEGMENTI):
		var r0: float = 0.17 - float(k) * 0.011
		var m := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.bottom_radius = r0
		cm.top_radius = r0 - 0.011
		cm.height = seg * 1.04    # un filo di sovrapposizione: niente fessure
		cm.radial_segments = 8
		m.mesh = cm
		m.position = Vector3(dx, y + seg / 2.0, 0)
		m.rotation.z = piega * float(k)
		m.material_override = corteccia
		root.add_child(m)
		dx += sin(piega * float(k)) * seg
		y += seg

	var cima := Vector3(dx, h, 0)
	var verde := Tex.flat(Color(0.20, 0.38, 0.17), 0.94)
	var verde2 := Tex.flat(Color(0.27, 0.47, 0.22), 0.94)

	# Le foglie: nove, lunghe due metri e mezzo, che partono dalla cima e
	# ricadono. Ognuna e' fatta di tre pezzi in fila sempre piu' inclinati
	# verso il basso — una sola scatola dritta resta una tavola, tre in
	# sequenza fanno la curva della fronda, che e' tutta la sagoma.
	for k in range(9):
		var a: float = TAU * float(k) / 9.0 + rng.randf_range(-0.14, 0.14)
		var ramo := Node3D.new()
		ramo.position = cima
		ramo.rotation.y = -a
		root.add_child(ramo)
		var caduta: float = rng.randf_range(0.22, 0.5)
		var d := 0.0
		var yy := 0.0
		for j in range(3):
			var lung := 0.95
			var f := MeshInstance3D.new()
			var qm := BoxMesh.new()
			# Si stringe verso la punta.
			qm.size = Vector3(0.42 - float(j) * 0.11, 0.045, lung)
			f.mesh = qm
			var inc: float = -caduta * float(j + 1)
			f.position = Vector3(0, yy - sin(caduta * float(j)) * lung * 0.5,
				d + lung * 0.5)
			f.rotation.x = inc
			f.material_override = verde if (k + j) % 2 == 0 else verde2
			ramo.add_child(f)
			d += lung * cos(inc)
			yy -= lung * sin(-inc) * 0.5

	# Il cuore centrale, che nasconde l'incastro delle foglie.
	var cuore := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.26
	sm.height = 0.5
	sm.radial_segments = 7
	sm.rings = 4
	cuore.mesh = sm
	cuore.position = cima
	cuore.material_override = verde
	root.add_child(cuore)

	# Il tronco è solido: su una passeggiata larga sette metri, una palma
	# che si attraversa si nota subito.
	_solido(pos + Vector3(0, 1.2, 0), Vector3(0.42, 2.4, 0.42))


func _lampione(pos: Vector3) -> void:
	var palo := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.bottom_radius = 0.09
	cm.top_radius = 0.07
	cm.height = 4.4
	cm.radial_segments = 8
	palo.mesh = cm
	palo.position = pos + Vector3(0, 2.2, 0)
	palo.material_override = Tex.flat(Color(0.16, 0.20, 0.22), 0.5, 0.4)
	add_child(palo)

	var globo := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.28
	sm.height = 0.56
	globo.mesh = sm
	globo.position = pos + Vector3(0, 4.55, 0)
	var vetro := StandardMaterial3D.new()
	vetro.albedo_color = Color(0.95, 0.92, 0.82)
	vetro.emission_enabled = true
	vetro.emission = Color(1.0, 0.90, 0.66)
	vetro.emission_energy_multiplier = 0.0
	globo.material_override = vetro
	add_child(globo)

	var luce := OmniLight3D.new()
	luce.position = pos + Vector3(0, 4.5, 0)
	luce.light_color = Color(1.0, 0.88, 0.68)
	luce.light_energy = 0.0
	luce.omni_range = 12.0
	luce.shadow_enabled = false
	luce.distance_fade_enabled = true
	luce.distance_fade_begin = 46.0
	luce.distance_fade_length = 14.0
	add_child(luce)
	# Il ciclo giorno/notte accende lampioni e vetri insieme: si registra
	# come fanno quelli della città.
	var citta := get_parent()
	if citta and citta.has_method("registra_lampione"):
		citta.registra_lampione(luce, globo)

	_solido(pos + Vector3(0, 1.2, 0), Vector3(0.3, 2.4, 0.3))


func _panchina(pos: Vector3) -> void:
	var legno := Tex.flat(Color(0.42, 0.30, 0.20), 0.92)
	var ghisa := Tex.flat(Color(0.14, 0.16, 0.17), 0.6, 0.35)
	for d in [-0.75, 0.75]:
		var g := MeshInstance3D.new()
		var gm := BoxMesh.new()
		gm.size = Vector3(0.1, 0.44, 0.5)
		g.mesh = gm
		g.position = pos + Vector3(d, 0.22, 0)
		g.material_override = ghisa
		add_child(g)
	var s := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(1.8, 0.09, 0.5)
	s.mesh = sm
	s.position = pos + Vector3(0, 0.46, 0)
	s.material_override = legno
	add_child(s)
	var sch := MeshInstance3D.new()
	var schm := BoxMesh.new()
	schm.size = Vector3(1.8, 0.42, 0.08)
	sch.mesh = schm
	# Lo schienale guarda la strada: chi si siede guarda il mare.
	sch.position = pos + Vector3(0, 0.7, 0.22)
	sch.material_override = legno
	add_child(sch)
	_solido(pos + Vector3(0, 0.45, 0), Vector3(1.9, 0.9, 0.6))


# ---------------------------------------------------------------------------
# 'O muraglione
# ---------------------------------------------------------------------------

## Il parapetto sul mare. È anche il muro invisibile del bordo nord della
## mappa — ma qui è visibile, e questo è il punto: uno capisce dove finisce
## il mondo perché c'è un muretto, non perché sbatte contro il vuoto.
func _build_muraglione() -> void:
	var w: float = LARGHEZZA_CITTA + 40.0
	var cx: float = LARGHEZZA_CITTA / 2.0
	var piperno := Tex.mondo("piperno", Color.WHITE, 0.94)

	var muro := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(w, ALT_MURAGLIONE, 0.55)
	muro.mesh = bm
	muro.position = Vector3(cx, ALT_MURAGLIONE / 2.0, Z_MURAGLIONE)
	muro.material_override = piperno
	add_child(muro)

	# Il coronamento: la lastra piatta su cui si appoggiano i gomiti.
	var cap := MeshInstance3D.new()
	var cmm := BoxMesh.new()
	cmm.size = Vector3(w, 0.13, 0.78)
	cap.mesh = cmm
	cap.position = Vector3(cx, ALT_MURAGLIONE + 0.06, Z_MURAGLIONE)
	cap.material_override = Tex.mondo("marciapiede", Tex.TERRA, 0.9)
	add_child(cap)

	# Sotto il muraglione, la scogliera: massi buttati alla rinfusa fino al
	# pelo dell'acqua. Senza, il muro esce dall'acqua come una parete di
	# piscina.
	var rng := RandomNumberGenerator.new()
	rng.seed = 991
	# **'E scoglie overe** (0.59). Erano centoquaranta scatole di piperno
	# girate storte: da riva passavano, dalla passeggiata — che è dove ci
	# si affaccia — erano mattoni. Adesso sono i cinque scogli e i due massi
	# del pacchetto Pandazole, girati e scalati a caso, in un gruppo per
	# forma (sette chiamate di disegno per tutta la scogliera). Le scatole
	# restano solo se i modelli non ci sono.
	if _scoglie_overe(rng):
		_solido(Vector3(cx, 1.5, Z_MURAGLIONE), Vector3(w + 40.0, 3.0, 0.9))
		return
	var pietra := Tex.mondo("piperno", Color(0.86, 0.84, 0.80), 0.96)
	var x: float = -18.0
	while x < LARGHEZZA_CITTA + 22.0:
		var m := MeshInstance3D.new()
		var mm := BoxMesh.new()
		var s: float = rng.randf_range(0.9, 1.9)
		mm.size = Vector3(s, s * 0.7, s * 0.8)
		m.mesh = mm
		m.position = Vector3(x, rng.randf_range(-0.1, 0.35),
			Z_MARE - rng.randf_range(0.2, 1.6))
		m.rotation = Vector3(rng.randf_range(-0.3, 0.3),
			rng.randf_range(0.0, TAU), rng.randf_range(-0.3, 0.3))
		m.material_override = pietra
		add_child(m)
		x += rng.randf_range(1.1, 2.3)

	# Il muro solido: qui finisce il mondo.
	_solido(Vector3(cx, 1.5, Z_MURAGLIONE), Vector3(w + 40.0, 3.0, 0.9))


## La scogliera coi modelli: un masso ogni metro e mezzo circa, a pelo
## d'acqua sotto al muraglione, e ogni tanto uno più grosso messo davanti.
func _scoglie_overe(rng: RandomNumberGenerator) -> bool:
	var forme := ["scoglio_1", "scoglio_2", "scoglio_3", "scoglio_4",
		"scoglio_5", "sasso_1", "sasso_2"]
	var mesh_di := {}
	for f in forme:
		var p := "res://assets/models/%s.mesh" % f
		if not ResourceLoader.exists(p):
			return false
		mesh_di[f] = load(p)
	var gruppi := {}
	var x: float = -18.0
	while x < LARGHEZZA_CITTA + 22.0:
		var f: String = str(forme[rng.randi() % forme.size()])
		var sc: float = rng.randf_range(0.9, 1.6)
		var b := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
		b = b * Basis(Vector3.RIGHT, rng.randf_range(-0.25, 0.25))
		b = b.scaled(Vector3.ONE * sc)
		var pos := Vector3(x, rng.randf_range(-0.55, -0.15),
			Z_MARE - rng.randf_range(0.1, 1.5))
		if not gruppi.has(f):
			gruppi[f] = []
		(gruppi[f] as Array).append(Transform3D(b, pos))
		x += rng.randf_range(1.0, 1.9)
	# Il grigio chiaro dell'atlante, sotto al sole di Mergellina, veniva
	# fuori bianco come neve: gli scogli veri del lungomare sono piperno e
	# tufo bagnato, scuri. Si moltiplica l'atlante per un grigio bruno.
	var pietra: StandardMaterial3D = null
	var base: Material = (mesh_di["scoglio_1"] as Mesh).surface_get_material(0)
	if base is StandardMaterial3D:
		pietra = (base as StandardMaterial3D).duplicate()
		pietra.albedo_color = Color(0.52, 0.49, 0.45)
	for f in gruppi:
		var lista: Array = gruppi[f]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh_di[f]
		mm.instance_count = lista.size()
		for i in range(lista.size()):
			mm.set_instance_transform(i, lista[i])
		var n := MultiMeshInstance3D.new()
		n.name = "Scoglie_" + str(f)
		n.multimesh = mm
		if pietra != null:
			n.material_override = pietra
		add_child(n)
	return true


## **'O piscatore** (0.59). Uno che pesca dal muraglione, di spalle alla
## città: la canna appoggiata sul parapetto con la lenza che scende in
## acqua, il secchio, la corda arrotolata, il binocolo sul parapetto e un
## remo appoggiato al muro (la barca sua è una di quelle in rada). È uno
## degli otto uomini del pacchetto nuovo, fermo. Sta fra due palme dove non
## c'è né lampione né panchina, davanti al belvedere: dal belvedere lo si
## vede di spalle, col golfo davanti.
const POSTO_PISCATORE := Vector3(28.0, 0.0, -19.75)


func _build_piscatore() -> void:
	var p: Vector3 = POSTO_PISCATORE
	var Human = load("res://scripts/human_builder.gd")
	var parti: Dictionary = Human.build(Color(0.30, 0.36, 0.42),
		Color(0.24, 0.24, 0.22), "", 1.74,
		{"modello": "omo_maniche", "hair": Color(0.72, 0.72, 0.70)})
	var uomo: Node3D = parti.get("root")
	if uomo == null:
		return
	uomo.name = "Piscatore"
	uomo.position = p
	uomo.rotation.y = 0.0   # guarda il mare, cioè −Z
	add_child(uomo)
	_solido(p + Vector3(0, 0.9, 0), Vector3(0.6, 1.8, 0.6))
	# 'A canna: dal piede, appoggiata al parapetto, fino a un metro sopra
	# all'acqua. Poi la lenza giù dritta.
	# Il piede sta un palmo dietro a lui, e la canna poggia sullo **spigolo
	# del coronamento** dalla parte della passeggiata (−20,21): appoggiata
	# al centro del muro ci passava dentro.
	var canna_da: Vector3 = p + Vector3(0.45, 0.05, 0.25)
	var appoggio := Vector3(canna_da.x, ALT_MURAGLIONE + 0.13,
		Z_MURAGLIONE + 0.39)
	var dir: Vector3 = (appoggio - canna_da).normalized()
	var lunga: float = 3.6
	var punta: Vector3 = canna_da + dir * lunga
	var canna := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.008
	cm.bottom_radius = 0.02
	cm.height = lunga
	cm.radial_segments = 6
	canna.mesh = cm
	canna.material_override = Tex.flat(Color(0.14, 0.14, 0.16), 0.5, 0.3)
	canna.position = (canna_da + punta) * 0.5
	canna.basis = Basis(Quaternion(Vector3.UP, dir))
	add_child(canna)
	var lenza := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 0.003
	lm.bottom_radius = 0.003
	lm.height = punta.y + 0.2
	lm.radial_segments = 3
	lenza.mesh = lm
	lenza.material_override = Tex.flat(Color(0.85, 0.85, 0.82), 0.4)
	lenza.position = Vector3(punta.x, (punta.y - 0.2) * 0.5, punta.z)
	add_child(lenza)
	for e in [["secchio_2", Vector3(-0.55, 0.0, 0.05), 0.0],
			["corda", Vector3(0.95, 0.0, 0.35), 40.0],
			["binocolo", Vector3(-0.25, ALT_MURAGLIONE + 0.13, Z_MURAGLIONE - p.z), 10.0]]:
		var n := Models.spawn(str(e[0]))
		if n == null:
			continue
		n.position = p + (e[1] as Vector3)
		n.rotation.y = deg_to_rad(float(e[2]))
		add_child(n)
	# 'O rimmo appujato ô muraglione, quasi dritto.
	var remo := Models.spawn("remo")
	if remo != null:
		# Il remo è lungo sulla sua Z: si alza in piedi (Z → Y) e si
		# appoggia al muro con la punta verso il mare.
		# Il perno della mesh sta a metà remo: si alza di mezza lunghezza.
		remo.basis = Basis(Vector3.RIGHT, -PI * 0.5 - 0.28)
		remo.position = p + Vector3(1.6, 1.08, -0.25)
		add_child(remo)
	_lontano(uomo, 90.0)


# ---------------------------------------------------------------------------
# 'O Castel dell'Ovo
# ---------------------------------------------------------------------------

func _build_castello() -> void:
	var n := Models.spawn_by_length("castel_dellovo", CASTELLO_LUNGHEZZA)
	if n == null:
		return
	n.name = "CastelDellOvo"
	n.position = CASTELLO_POS
	# Di traverso rispetto alla riva: il castello vero è su un isolotto
	# lungo, e messo di punta sarebbe una torre invece che una fortezza.
	n.rotation.y = deg_to_rad(90.0)
	add_child(n)
	_lontano(n, 600.0)

	# Lo scoglio: il castello vero sta su un isolotto di tufo, e il modello
	# è stato tagliato al pelo dell'acqua. Senza uno scoglio sotto,
	# galleggia.
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var tufo := Tex.mondo("muro_tufo", Color(0.86, 0.82, 0.74), 0.97)
	for i in range(26):
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		var s: float = rng.randf_range(5.0, 13.0)
		bm.size = Vector3(s, rng.randf_range(2.0, 5.0), s * 0.8)
		m.mesh = bm
		var a: float = rng.randf_range(0.0, TAU)
		var r: float = rng.randf_range(0.0, 1.0)
		m.position = CASTELLO_POS + Vector3(
			cos(a) * r * 66.0, rng.randf_range(-1.2, 1.0), sin(a) * r * 22.0)
		m.rotation.y = rng.randf_range(0.0, TAU)
		m.material_override = tufo
		add_child(m)


# ---------------------------------------------------------------------------
# 'E barche
# ---------------------------------------------------------------------------

func _build_barche() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 313
	for b in BARCHE:
		var n := Models.spawn_by_length(str(b[3]), float(b[4]))
		if n == null:
			continue
		var p := Vector3(float(b[0]), 0.0, float(b[1]))
		n.position = p
		n.rotation.y = deg_to_rad(float(b[2]))
		add_child(n)
		_lontano(n, 340.0)
		# Ogni barca dondola per conto suo: stessa formula, fase diversa.
		# Con la fase in comune tutta la baia oscillerebbe all'unisono, che
		# è il modo più veloce per far capire che è finto.
		_barche.append({
			"nodo": n, "y": p.y, "fase": rng.randf_range(0.0, TAU),
			"ritmo": rng.randf_range(0.55, 0.95),
			"beccheggio": rng.randf_range(0.012, 0.03),
		})


## Il dondolio. Alzata di pochi centimetri e beccheggio di un grado o due:
## una barca ormeggiata in una giornata di bonaccia non fa di più, e
## esagerare la fa sembrare un cavallo a dondolo.
func _process(delta: float) -> void:
	var t := float(Time.get_ticks_msec()) / 1000.0
	for b in _barche:
		var n: Node3D = b["nodo"]
		if not is_instance_valid(n):
			continue
		var f: float = float(b["fase"]) + t * float(b["ritmo"])
		n.position.y = float(b["y"]) + sin(f) * 0.09
		n.rotation.x = sin(f * 0.83) * float(b["beccheggio"])
		n.rotation.z = cos(f * 0.61) * float(b["beccheggio"]) * 0.7


# ---------------------------------------------------------------------------
# Appoggio
# ---------------------------------------------------------------------------

func _solido(pos: Vector3, dim: Vector3) -> void:
	var b := StaticBody3D.new()
	b.collision_layer = 1
	b.collision_mask = 0
	var f := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = dim
	f.shape = bx
	f.position = pos
	b.add_child(f)
	add_child(b)


## Le cose grosse e lontane non hanno bisogno di sparire da vicino, ma
## devono sparire da lontanissimo: il castello si vede da tutta la città e
## non ha senso disegnarlo quando sei in un vicolo dietro a un palazzo.
func _lontano(n: Node, metri: float) -> void:
	var pila: Array = [n]
	while not pila.is_empty():
		var c: Node = pila.pop_back()
		if c is GeometryInstance3D:
			var g := c as GeometryInstance3D
			g.visibility_range_end = metri
			g.visibility_range_end_margin = metri * 0.1
		for f in c.get_children():
			pila.append(f)
