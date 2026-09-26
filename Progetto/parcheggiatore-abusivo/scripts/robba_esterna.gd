extends RefCounted
## **'A robba 'e fore** (0.62) — gli asset esterni messi in città.
##
## La biblioteca `assets/esterni/` (materiali Poly Haven, decalcomanie
## ambientCG, modelli Poly Pizza, suoni Freesound, icone Kenney) l'ha
## preparata un'altra sessione ed è rimasta fuori dal gioco fino a qui.
## Questo file mette in città quello che di lei **non c'era già**: molti
## pezzi della biblioteca sono gli stessi pacchetti Quaternius che il capo
## aveva dato nella 0.59 (le auto del Car Pack, gli Animated Men, l'umano),
## e un doppione non si mette — vedi `ASSET-ESTERNI.md`, «Cosa è entrato».
##
## Le regole sono quelle di `robba_psx.gd` e valgono tutte: si mette per
## ultimo, **col suo seme** (così la città è la stessa a ogni partita e
## niente di quello che c'era si sposta), solo dove c'è posto, e ogni cosa
## solida ha un corpo (`_solido`). I nomi dei file si scrivono per intero
## (`prova_asset` li cerca nel testo).
##
## **'E decalcomanie** sono quad piatti, non nodi `Decal`: il `Decal` di
## Godot non esiste nel renderer Compatibility, cioè nella build web, e
## centinaia di nodi sarebbero centinaia di chiamate. Qui sono istanze di
## MultiMesh come tutto l'arredo (gruppi `decal_*`, a quadretti e spenti
## oltre i sessanta metri), due centimetri sopra alla superficie su cui
## stanno: meno sfarfalla, di più galleggia.

const Models := preload("res://scripts/models.gd")
const Quartieri := preload("res://scripts/quartieri.gd")

## Le decalcomanie da gioco (512 px con l'alfa dentro), ricavate dagli
## originali 2K da `tools/prepara_esterni.py`.
const DECAL := {
	"tombino_ghisa": "res://assets/textures/decal/tombino_ghisa.png",
	"tombino_ghisa_n": "res://assets/textures/decal/tombino_ghisa_n.png",
	"tombino_grata": "res://assets/textures/decal/tombino_grata.png",
	"tombino_grata_n": "res://assets/textures/decal/tombino_grata_n.png",
	"rattoppo": "res://assets/textures/decal/rattoppo.png",
	"rattoppo_n": "res://assets/textures/decal/rattoppo_n.png",
	"gomme": "res://assets/textures/decal/gomme.png",
	"macchia_olio": "res://assets/textures/decal/macchia_olio.png",
	"colatura_split": "res://assets/textures/decal/colatura_split.png",
	"colatura_muro": "res://assets/textures/decal/colatura_muro.png",
	"graffito_tag": "res://assets/textures/decal/graffito_tag.png",
}

## Quanto si stacca una decalcomania dalla sua superficie.
const STACCO_TERRA: float = 0.02
const STACCO_MURO: float = 0.03
## Il manto delle strade sta a 1 cm, il marciapiede a 16.
const Y_STRADA: float = 0.01
const Y_MARCIAPIEDE: float = 0.16

static var _piano: PlaneMesh = null
static var _quad: QuadMesh = null
static var _materiali: Dictionary = {}


static func metti(c: Node3D) -> void:
	if not ResourceLoader.exists(str(DECAL["tombino_ghisa"])):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 62001
	_strade(c, rng)
	_colature_split(c, rng)
	_mure(c, rng)


# ---------------------------------------------------------------------------
# I materiali e i pezzi
# ---------------------------------------------------------------------------

static func _mat(nome: String, morbida: bool, ruvido: float = 0.9,
		metallo: float = 0.0) -> StandardMaterial3D:
	if _materiali.has(nome):
		return _materiali[nome]
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(str(DECAL[nome]))
	if morbida:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	else:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.45
	m.roughness = ruvido
	m.metallic = metallo
	var n_nome: String = nome + "_n"
	if DECAL.has(n_nome):
		m.normal_enabled = true
		m.normal_texture = load(str(DECAL[n_nome]))
		m.normal_scale = 1.0
	# Pittura e sporco su intonaco: niente lampo del sole (come i murales).
	if nome.begins_with("colatura") or nome.begins_with("graffito"):
		m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.cull_mode = BaseMaterial3D.CULL_BACK
	_materiali[nome] = m
	return m


## Una decalcomania stesa per terra: `p` è il punto della superficie
## (y compresa), `giro` il verso, `lx`/`lz` la misura.
static func _a_terra(c: Node3D, tipo: String, p: Vector3, giro: float,
		lx: float, lz: float, mat: Material) -> void:
	if _piano == null:
		_piano = PlaneMesh.new()
		_piano.size = Vector2(1.0, 1.0)
	var mi := MeshInstance3D.new()
	mi.mesh = _piano
	mi.material_override = mat
	mi.transform = Transform3D(Basis(Vector3.UP, giro) * Basis.from_scale(
		Vector3(lx, 1.0, lz)), p + Vector3(0, STACCO_TERRA, 0))
	c._batched("decal_" + tipo, mi)


## Una decalcomania appoggiata a un muro: `p` è sul muro, `fuori` la
## normale che esce dalla facciata, `centro_y` l'altezza del centro.
static func _a_muro(c: Node3D, tipo: String, p: Vector3, fuori: Vector3,
		larga: float, alta: float, mat: Material) -> void:
	if _quad == null:
		_quad = QuadMesh.new()
		_quad.size = Vector2(1.0, 1.0)
	var mi := MeshInstance3D.new()
	mi.mesh = _quad
	mi.material_override = mat
	# Il quad guarda a +Z: lo si gira verso `fuori` (convenzione PSX/quad).
	var giro: float = atan2(fuori.x, fuori.z)
	mi.transform = Transform3D(Basis(Vector3.UP, giro) * Basis.from_scale(
		Vector3(larga, alta, 1.0)), p + fuori * STACCO_MURO)
	c._batched("decal_" + tipo, mi)


# ---------------------------------------------------------------------------
# 'E strade: tombini, rattoppi, macchie d'olio, gomme americane
# ---------------------------------------------------------------------------

## Il punto sta sulla strada, e non in una piazza, in un varco, vicino al
## terrapieno del Vomero o dentro a un palazzo?
static func _strada_bbona(c: Node3D, p: Vector3) -> bool:
	if c.dint_ô_palazzo(p, 0.3) or c.dentro_varco(p):
		return false
	if c._vicino_â_collina(p, 2.5):
		return false
	for z in c.ZONE:
		var r: Array = z["rect"]
		if p.x >= float(r[0]) - 1.0 and p.x <= float(r[2]) + 1.0 \
				and p.z >= float(r[1]) - 1.0 and p.z <= float(r[3]) + 1.0:
			return false
	return true


static func _strade(c: Node3D, rng: RandomNumberGenerator) -> void:
	var m_ghisa := _mat("tombino_ghisa", false, 0.55, 0.35)
	var m_grata := _mat("tombino_grata", false, 0.6, 0.3)
	var m_rattoppo := _mat("rattoppo", true, 0.95)
	var m_olio := _mat("macchia_olio", true, 0.35)
	var m_gomme := _mat("gomme", false, 0.7)
	var tombini := 0
	for s in c.STRADE:
		var x0: float = float(s[0])
		var z0: float = float(s[1])
		var x1: float = float(s[2])
		var z1: float = float(s[3])
		var w: float = x1 - x0
		var l: float = z1 - z0
		var lungo_z: bool = l > w
		var stretta: bool = minf(w, l) <= 5.5
		var larga: float = w if lungo_z else l
		var corsa: float = l if lungo_z else w
		var mezzo: float = (x0 + x1) * 0.5 if lungo_z else (z0 + z1) * 0.5
		var inizio: float = z0 if lungo_z else x0
		var giro_strada: float = 0.0 if lungo_z else PI * 0.5
		var t: float = rng.randf_range(4.0, 12.0)
		while t < corsa - 3.0:
			# I tombini: fuori dall'asse (lì c'è la riga, o la canaletta del
			# vicolo), mai sul marciapiede.
			var lato: float = 1.0 if rng.randf() < 0.5 else -1.0
			var scosta: float = 0.95 if stretta else larga * 0.5 - 2.1
			var trasv: float = mezzo + lato * scosta
			var p := Vector3(trasv, Y_STRADA, inizio + t) if lungo_z \
				else Vector3(inizio + t, Y_STRADA, trasv)
			if _strada_bbona(c, p):
				var grata: bool = rng.randf() < 0.35
				var d: float = 0.8 if grata else 0.72
				_a_terra(c, "tombino_grata" if grata else "tombino_ghisa", p,
					rng.randf_range(-PI, PI), d, d, m_grata if grata else m_ghisa)
				tombini += 1
			t += rng.randf_range(15.0, 24.0)
		if stretta:
			continue
		# Sulle strade larghe (asfalto): i rattoppi in mezzo, le macchie
		# d'olio dove si parcheggia (accanto al marciapiede), le gomme
		# americane sul marciapiede.
		t = rng.randf_range(6.0, 20.0)
		while t < corsa - 4.0:
			var trasv2: float = mezzo + rng.randf_range(-1.0, 1.0) * (larga * 0.5 - 2.6)
			var p2 := Vector3(trasv2, Y_STRADA, inizio + t) if lungo_z \
				else Vector3(inizio + t, Y_STRADA, trasv2)
			if _strada_bbona(c, p2) and rng.randf() < 0.6:
				var lx: float = rng.randf_range(1.3, 2.6)
				_a_terra(c, "rattoppo", p2, giro_strada + rng.randf_range(-0.2, 0.2),
					lx, lx * rng.randf_range(0.7, 1.3), m_rattoppo)
			t += rng.randf_range(18.0, 34.0)
		t = rng.randf_range(2.0, 8.0)
		while t < corsa - 2.0:
			var lato3: float = 1.0 if rng.randf() < 0.5 else -1.0
			var trasv3: float = mezzo + lato3 * (larga * 0.5 - 2.5)
			var p3 := Vector3(trasv3, Y_STRADA, inizio + t) if lungo_z \
				else Vector3(inizio + t, Y_STRADA, trasv3)
			if _strada_bbona(c, p3) and rng.randf() < 0.4:
				var d3: float = rng.randf_range(0.9, 1.5)
				_a_terra(c, "olio", p3, rng.randf_range(-PI, PI), d3, d3 * 1.2, m_olio)
			t += rng.randf_range(6.0, 11.0)
		t = rng.randf_range(3.0, 10.0)
		while t < corsa - 2.0:
			var lato4: float = 1.0 if rng.randf() < 0.5 else -1.0
			var trasv4: float = mezzo + lato4 * (larga * 0.5 - 0.7)
			var p4 := Vector3(trasv4, Y_MARCIAPIEDE, inizio + t) if lungo_z \
				else Vector3(inizio + t, Y_MARCIAPIEDE, trasv4)
			if _strada_bbona(c, p4) and rng.randf() < 0.5:
				_a_terra(c, "gomme", p4, rng.randf_range(-PI, PI), 1.1, 1.1, m_gomme)
			t += rng.randf_range(9.0, 16.0)
	c.set_meta(&"tombini_messi", tombini)


## **'E macchie d'olio dint'ê posti auto** (le chiama la città un secondo
## dopo, quando le piazze hanno messo tutti i posti). Una macchia per posto,
## storta e mai al centro preciso: lì sotto c'è stata una macchina ogni
## giorno per anni.
static func macchie_posti(c: Node3D) -> void:
	if not ResourceLoader.exists(str(DECAL["macchia_olio"])):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 62002
	var m_olio := _mat("macchia_olio", true, 0.35)
	if _piano == null:
		_piano = PlaneMesh.new()
		_piano.size = Vector2(1.0, 1.0)
	var lista: Array = []
	var spot: Array = c.get_tree().get_nodes_in_group("parking_spots")
	# L'ordine dei nodi nel gruppo non è garantito: si mettono in fila per
	# posizione, così il caso dà la stessa macchia allo stesso posto.
	spot.sort_custom(func(a, b): return (a as Node3D).global_position.x * 1000.0 \
		+ (a as Node3D).global_position.z < (b as Node3D).global_position.x * 1000.0 \
		+ (b as Node3D).global_position.z)
	for s in spot:
		if not (s is Node3D) or not (s as Node3D).is_inside_tree():
			continue
		var g: Transform3D = (s as Node3D).global_transform
		if rng.randf() < 0.15:
			continue
		var off := Vector3(rng.randf_range(-0.35, 0.35), 0.0, rng.randf_range(-0.7, 0.7))
		var d: float = rng.randf_range(0.8, 1.3)
		var t := Transform3D(g.basis * Basis(Vector3.UP, rng.randf_range(-PI, PI)) \
			* Basis.from_scale(Vector3(d, 1.0, d * 1.25)),
			g * (off + Vector3(0, 0.018, 0)))
		lista.append({"mesh": _piano, "mat": m_olio, "trasf": t})
	if not lista.is_empty():
		c._flush_a_quadrette("decal_olio_posti", lista, "decal_")
	c.set_meta(&"macchie_posti", lista.size())


# ---------------------------------------------------------------------------
# 'E mure: colature sotto agli split, umido, graffiti
# ---------------------------------------------------------------------------

## Sotto a ogni condizionatore (quasi) la riga scura dell'acqua che cola
## dal tubo: si vede da lontano, ed è il segno che quel palazzo è abitato.
static func _colature_split(c: Node3D, rng: RandomNumberGenerator) -> void:
	var m := _mat("colatura_split", true, 0.95)
	var messe := 0
	for v in c._split_posti:
		if rng.randf() < 0.3:
			continue
		var p: Vector3 = v[0]
		var fuori: Vector3 = v[1]
		var alta: float = rng.randf_range(1.3, 2.2)
		# Parte da sotto lo split (il modello ha l'origine alla base) e
		# scende.
		var centro: Vector3 = p + Vector3(0, -0.02 - alta * 0.5, 0)
		if centro.y - alta * 0.5 < 3.2:
			continue
		_a_muro(c, "colatura_split", centro, fuori, rng.randf_range(0.28, 0.42),
			alta, m)
		messe += 1
	c.set_meta(&"colature_split", messe)


## Chi sta troppo vicino a un murale, a uno stencil, a un manifesto, a un
## portone o a una bottega non si prende la roba sul muro.
static func _muro_bbuono(c: Node3D, p: Vector3) -> bool:
	for m in c.MURALES:
		if Vector2(float(m[0]), float(m[1])).distance_to(Vector2(p.x, p.z)) < 4.5:
			return false
	for s in c.STENCIL:
		if Vector2(float(s[0]), float(s[1])).distance_to(Vector2(p.x, p.z)) < 3.0:
			return false
	for q in c.POSTI_MANIFESTI:
		if Vector2(float(q[1]), float(q[2])).distance_to(Vector2(p.x, p.z)) < 3.5:
			return false
	if c._davanti_ô_portone(p, 2.2) or c._occupato_da_attivita(p, 3.2):
		return false
	return not c._vicino_â_collina(p, 2.0)


static func _mure(c: Node3D, rng: RandomNumberGenerator) -> void:
	var m_umido := _mat("colatura_muro", true, 0.95)
	var m_tag := _mat("graffito_tag", true, 0.9)
	var facce: Array = c._facciate_verso(Rect2(0, 0, c.LARGHEZZA, c.PROFONDITA),
		3.0, 7.0)
	var umidi := 0
	var tag := 0
	for f in facce:
		var ang: float = deg_to_rad(float(f[2]))
		var fuori := Vector3(sin(ang), 0.0, cos(ang))
		# Il punto di `_facciate_verso` sta venti centimetri fuori dal muro.
		var p := Vector3(float(f[0]), 0.0, float(f[1])) - fuori * 0.2
		if p.x < 1.0 or p.z < 1.0 or p.x > c.LARGHEZZA - 1.0 or p.z > c.PROFONDITA - 1.0:
			continue
		var lato := Vector3(fuori.z, 0.0, -fuori.x)
		if not c._facciata_dereto(p + fuori * 0.2, fuori, lato):
			continue
		var q: Dictionary = Quartieri.di(p.x, p.z)
		var popolare: bool = bool(q.get("panni", false))
		var tiro: float = rng.randf()
		if not _muro_bbuono(c, p):
			continue
		# L'umido: la colatura verde di muschio sotto al primo balcone, nei
		# quartieri dove si stendono i panni (quelli bassi e vecchi).
		if popolare and tiro < 0.22:
			var alta: float = rng.randf_range(1.6, 2.6)
			_a_muro(c, "colatura_muro", p + lato * rng.randf_range(-1.5, 1.5)
				+ Vector3(0, 4.2 - alta * 0.5, 0), fuori,
				rng.randf_range(1.2, 2.0), alta, m_umido)
			umidi += 1
		# I graffiti: a mano d'uomo, pochi, uno ogni tanto.
		elif tiro > 0.9 and tag < 14:
			var larga: float = rng.randf_range(1.5, 2.3)
			_a_muro(c, "graffito", p + lato * rng.randf_range(-1.0, 1.0)
				+ Vector3(0, rng.randf_range(1.3, 1.8), 0), fuori,
				larga, larga * 207.0 / 512.0, m_tag)
			tag += 1
	c.set_meta(&"colature_muro", umidi)
	c.set_meta(&"graffiti_tag", tag)
