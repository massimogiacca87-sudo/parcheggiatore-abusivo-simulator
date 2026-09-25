extends Node3D
## Golfo — 'a forma 'e Napule vista 'a coppa
##
## ## Il problema
##
## La città giocabile è un rettangolo di 190 × 172 metri col mare che
## comincia a nord, dritto, su tutta la larghezza. Da terra funziona: vedi
## il lungomare e l'acqua, e basta. **Dall'inquadratura d'apertura no.**
## Da centoventi metri d'altezza si vede tutto il rettangolo, e quello che
## si legge è una scacchiera con una striscia blu davanti — che è
## qualunque città di mare, tranne Napoli.
##
## Napoli non è quadrata: **è appoggiata dentro a un golfo.** È la prima
## cosa che si riconosce di lei su una carta geografica, prima ancora dei
## decumani, ed è quello che questa apertura deve far vedere.
##
## ## Come è fatto
##
## Tre pezzi, tutti di sola scenografia — niente collisioni, niente
## interazione, niente che entri nell'area di gioco:
##
## 1. **'A costa.** Una polilinea che parte da sud-ovest, sale verso nord
##    disegnando il capo di ponente, scende fino alla riva della città (che
##    resta dritta, perché lì ci si cammina davvero), e risale a levante
##    disegnando l'altro braccio. La terra è il poligono fra questa
##    polilinea e un bordo esterno lontanissimo. L'acqua è quello che
##    resta in mezzo: una conca che entra nella terra, cioè un golfo.
##
## 2. **'A città che continua.** Palazzi finti sparsi sulla terra intorno,
##    fitti vicino alla riva e radi verso l'interno, tutti in un MultiMesh
##    solo. Servono a far finire la città in una città, invece che in un
##    bordo netto oltre il quale non c'è niente.
##
## 3. **'E colline.** Il Vomero e Posillipo alle spalle e a ponente, e il
##    Vesuvio sul braccio di levante. Sono i tre profili che chiudono la
##    cartolina: senza, il golfo è un golfo qualunque.
##
## ## Perché non si può camminare fin là
##
## Perché non c'è niente da fare, e costruirlo per davvero vorrebbe dire
## un'altra città. I muri invisibili della mappa restano dove stanno: il
## golfo si guarda, non si visita — esattamente come il Vesuvio, che sta
## lì da sempre e nessuno si è mai lamentato di non poterci salire.

const Tex := preload("res://scripts/textures.gd")
const VascioScript := preload("res://scripts/vascio_3d.gd")

## Il livello a cui sta la terra finta. Sotto all'asfalto della città
## (-0,08) di un paio di centimetri: così non lampeggiano l'uno contro
## l'altro dove si sovrappongono.
const Y_TERRA: float = -0.34

## **'A costa.** Punti (x, z) da ponente a levante. La riva della città
## (x da 0 a 190, z = -21) è l'unico tratto che deve coincidere col mondo
## vero: è dove finisce il muraglione di Mergellina.
##
## Tutto il resto è disegno. La regola che tiene: allontanandosi dalla
## città la costa sale verso z negativi, cioè si allontana da chi guarda —
## ed è quello che scava la conca. Le due punte (a −760 e a −690) sono i
## capi che chiudono il golfo all'orizzonte.
const COSTA := [
	Vector2(-980.0, -760.0),
	Vector2(-760.0, -600.0),
	Vector2(-560.0, -430.0),
	Vector2(-400.0, -280.0),
	Vector2(-280.0, -172.0),
	Vector2(-186.0, -104.0),
	Vector2(-112.0, -58.0),
	Vector2(-52.0, -31.0),
	Vector2(0.0, -21.0),
	Vector2(190.0, -21.0),
	Vector2(258.0, -27.0),
	Vector2(344.0, -48.0),
	Vector2(438.0, -88.0),
	Vector2(548.0, -158.0),
	Vector2(660.0, -262.0),
	Vector2(772.0, -404.0),
	Vector2(880.0, -580.0),
	Vector2(980.0, -790.0),
]

## Quanto è profonda la terra dietro alla costa (verso z positivi).
const TERRA_PROFONDITA: float = 1150.0

## L'isola in bocca al golfo: due scogli e via. È Capri, e non c'è bisogno
## di dirlo — a quella distanza è una sagoma azzurra, e la sagoma azzurra
## in fondo al golfo di Napoli è quella.
const ISOLE := [
	{"pos": Vector3(-330.0, 0.0, -880.0), "r": 78.0, "h": 96.0},
	{"pos": Vector3(-232.0, 0.0, -930.0), "r": 46.0, "h": 58.0},
	{"pos": Vector3(505.0, 0.0, -940.0), "r": 58.0, "h": 44.0},
]

## Le alture. `pos` è il centro, `r` il raggio alla base, `h` l'altezza.
## **Le colline stanno LONTANE, e c'è un motivo preciso.**
##
## Al primo tentativo il Vomero stava a quaranta metri da ponente e duecento
## di raggio: sulla carta è dove sta davvero, ma un cono da centotrenta
## metri d'altezza appoggiato a filo del quartiere si mangia METÀ
## dell'inquadratura d'apertura — la città sparisce dietro a una gobba
## grigia. La regola che tengo adesso: il piede di ogni collina deve stare
## almeno ottanta metri fuori dal riquadro giocabile allargato. Da lontano
## fanno lo stesso mestiere (chiudono l'orizzonte) senza coprire niente.
const COLLINE := [
	# Posillipo: il capo di ponente, quello che chiude il golfo di fianco.
	{"pos": Vector3(-330.0, 0.0, -190.0), "r": 170.0, "h": 96.0,
		"col": Color(0.30, 0.35, 0.29)},
	{"pos": Vector3(-520.0, 0.0, -330.0), "r": 200.0, "h": 120.0,
		"col": Color(0.27, 0.32, 0.30)},
	# Il Vomero e i Camaldoli, alle spalle della città e ben distanti.
	{"pos": Vector3(-300.0, 0.0, 470.0), "r": 200.0, "h": 118.0,
		"col": Color(0.31, 0.34, 0.28)},
	{"pos": Vector3(520.0, 0.0, 520.0), "r": 220.0, "h": 106.0,
		"col": Color(0.29, 0.33, 0.29)},
	# La costa di levante che sale verso il vulcano.
	{"pos": Vector3(560.0, 0.0, 40.0), "r": 150.0, "h": 68.0,
		"col": Color(0.30, 0.34, 0.28)},
]

## Dove finisce il Vesuvio: sul braccio di levante, oltre la città, che è
## dove sta davvero. Prima era piantato a nord in mezzo all'acqua.
const VESUVIO_POS := Vector3(600.0, 0.0, -120.0)


func _ready() -> void:
	name = "Golfo"
	_build_terra()
	_build_colline()
	_build_isole()
	_build_citta_lontana()


# ---------------------------------------------------------------------------
# 'A terra
# ---------------------------------------------------------------------------

## Il poligono fra la costa e il bordo interno lontano. Si costruisce a
## strisce: per ogni coppia di punti della costa, due triangoli fino alla
## stessa x sul bordo di fondo. Una superficie sola, un materiale solo.
func _build_terra() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(COSTA.size() - 1):
		var a: Vector2 = COSTA[i]
		var b: Vector2 = COSTA[i + 1]
		var a2 := Vector2(a.x, a.y + TERRA_PROFONDITA)
		var b2 := Vector2(b.x, b.y + TERRA_PROFONDITA)
		_quad(st, a, b, b2, a2)
	st.generate_normals()

	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.position = Vector3(0, Y_TERRA, 0)
	var mat := StandardMaterial3D.new()
	# Un verde-ocra spento: da lontano la terra intorno a Napoli non è
	# verde prato, è polvere e tetti.
	mat.albedo_color = Color(0.47, 0.44, 0.35)
	mat.roughness = 1.0
	mi.material_override = mat
	# Non proietta ombra: è grande come mezza provincia e l'ombra di una
	# cosa così grande costa più di quanto valga.
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _quad(st: SurfaceTool, a: Vector2, b: Vector2, c: Vector2,
		d: Vector2) -> void:
	var va := Vector3(a.x, 0, a.y)
	var vb := Vector3(b.x, 0, b.y)
	var vc := Vector3(c.x, 0, c.y)
	var vd := Vector3(d.x, 0, d.y)
	for v in [va, vb, vc]:
		st.set_uv(Vector2(v.x * 0.01, v.z * 0.01))
		st.add_vertex(v)
	for v2 in [va, vc, vd]:
		st.set_uv(Vector2(v2.x * 0.01, v2.z * 0.01))
		st.add_vertex(v2)


# ---------------------------------------------------------------------------
# 'E colline e ll'isole
# ---------------------------------------------------------------------------

## Un cono schiacciato con pochi lati. A questa distanza il profilo è tutto
## quello che si vede, e un profilo a dodici facce da ottocento metri è
## indistinguibile da uno a duecento.
func _monte(pos: Vector3, r: float, h: float, col: Color,
		lati: int = 14) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.bottom_radius = r
	cm.top_radius = r * 0.14
	cm.height = h
	cm.radial_segments = lati
	mi.mesh = cm
	mi.position = pos + Vector3(0, h / 2.0 + Y_TERRA, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 1.0
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _build_colline() -> void:
	for c in COLLINE:
		_monte(c["pos"], float(c["r"]), float(c["h"]), c["col"])


## Le isole sono più azzurre delle colline: è la foschia sul mare, e senza
## quella differenza sembrano pezzi di terra staccati invece che isole
## lontane.
func _build_isole() -> void:
	for i in ISOLE:
		_monte(i["pos"], float(i["r"]), float(i["h"]),
			Color(0.34, 0.40, 0.52), 10)


# ---------------------------------------------------------------------------
# 'A città che continua
# ---------------------------------------------------------------------------
#
# Palazzi finti: cubi, tutti dentro a un MultiMesh solo, sparsi sulla terra
# ma **fuori dal rettangolo giocabile** e **dentro a una fascia lungo la
# costa**, perché è là che sta una città di mare. Più ci si allontana dalla
# riva, più si diradano e si abbassano: da una parte è vero, dall'altra fa
# sembrare la distanza più grande di quello che è.

const PALAZZI: int = 1800
## Quanto lontano dalla riva si continua a costruire.
const FASCIA: float = 420.0


func _build_citta_lontana() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260903

	var cubo := BoxMesh.new()
	cubo.size = Vector3(1, 1, 1)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.62, 0.57, 0.50)
	mat.roughness = 0.95
	cubo.material = mat

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = cubo
	# Prima si fissava il conto a PALAZZI e alla fine lo si riscriveva con
	# quelli messi davvero: ma cambiare `instance_count` **rialloca** il
	# buffer e butta le trasformazioni già scritte. Andava bene solo perché
	# si arrivava sempre a 1800 tondi. Adesso si raccolgono e si scrivono
	# una volta sola, alla fine.
	var posti: Array = []
	var colori: Array = []

	var messi := 0
	var tentativi := 0
	while messi < PALAZZI and tentativi < PALAZZI * 12:
		tentativi += 1
		var t: float = rng.randf()
		var i: int = clampi(int(t * float(COSTA.size() - 1)), 0,
			COSTA.size() - 2)
		var a: Vector2 = COSTA[i]
		var b: Vector2 = COSTA[i + 1]
		var lungo: Vector2 = a.lerp(b, rng.randf())
		# Quanto dentro, dalla riva: al quadrato, così è fitto sul mare e
		# rado verso l'interno.
		var k: float = rng.randf()
		var dentro: float = k * k * FASCIA + 12.0
		var p := Vector2(lungo.x, lungo.y + dentro)

		# Niente dentro all'area giocabile e niente a ridosso — ma il
		# margine è stretto: con settanta metri di rispetto per lato
		# restava una fascia di terra nuda tutt'intorno al quartiere, e la
		# città sembrava finire nel deserto invece che in un'altra città.
		if p.x > -34.0 and p.x < 226.0 and p.y > -34.0 and p.y < 206.0:
			continue
		# Niente sopra alle colline: un palazzo a mezza costa di un cono
		# resta appeso per aria.
		var su_monte := false
		for c in COLLINE:
			var cp: Vector3 = c["pos"]
			if Vector2(cp.x, cp.z).distance_to(p) < float(c["r"]) * 0.92:
				su_monte = true
				break
		if su_monte:
			continue

		var h: float = rng.randf_range(7.0, 22.0) * (1.0 - k * 0.45)
		var l: float = rng.randf_range(9.0, 22.0)
		var w: float = rng.randf_range(9.0, 22.0)
		var tr := Transform3D(Basis(), Vector3(p.x, Y_TERRA + h / 2.0, p.y))
		tr.basis = tr.basis.rotated(Vector3.UP, rng.randf_range(-0.3, 0.3))
		tr.basis = tr.basis.scaled(Vector3(l, h, w))
		# Le tinte di Napoli, sbiadite dalla distanza.
		var tinte := [
			Color(0.74, 0.66, 0.54), Color(0.70, 0.58, 0.46),
			Color(0.66, 0.62, 0.56), Color(0.76, 0.70, 0.58),
			Color(0.62, 0.55, 0.48),
		]
		var tinta: Color = tinte[rng.randi() % tinte.size()]
		# Niente palazzo finto addosso al vascio: la stanza di casa sta
		# fuori dalla pianta, cioè proprio qua in mezzo. Il controllo sta
		# DOPO tutte le estrazioni, così gli altri palazzi restano dove
		# stavano (la sequenza del generatore non cambia).
		if VascioScript.tocca_a_stanza(p, 0.5 * sqrt(l * l + w * w)):
			continue
		posti.append(tr)
		colori.append(tinta)
		messi += 1
	mm.instance_count = messi
	for n in messi:
		mm.set_instance_transform(n, posti[n])
		mm.set_instance_color(n, colori[n])

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Non serve disegnarli quando sei a terra dentro a un vicolo: si vedono
	# solo dall'alto e dal lungomare.
	mmi.visibility_range_end = 2400.0
	add_child(mmi)
