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
	# L'arredo ha un seme suo: se domani le decalcomanie cambiano, i
	# motorini restano dove stanno.
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 62003
	# (I motorini davanti ai bassi sono usciti prima di entrare: i bassi
	# stanno nei vicoli da quattro metri, e un motorino lungo quasi due
	# metri contro il muro lì tappa il passaggio — `prova_ntuppate`.)
	_motorini_ô_marciappiede(c, rng2)
	_coni_ê_cantieri(c, rng2)
	_segge_vienna(c, rng2)
	_ai_cassonetti(c, rng2)
	_segge_ufficio(c, rng2)


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
	# La foto del rattoppo è cemento chiaro: sull'asfalto scuro veniva un
	# quadrato bianco. Il rattoppo vero è asfalto più nuovo, cioè più scuro.
	m_rattoppo.albedo_color = Color(0.52, 0.51, 0.50, 0.85)
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


# ---------------------------------------------------------------------------
# L'arredo: motorini, coni, sedie, bidoni, casse
# ---------------------------------------------------------------------------
#
# Tutti modelli di Poly Pizza (nomi da gioco in `Models.ESTERNI`). Ogni
# pezzo si mette solo se c'è posto (`_sta_libero`, `_scatola_libera`), se
# può avere un corpo (`_puo_avere_corpo`: fuori dalla corsia e dai varchi)
# e poi il corpo ce l'ha (`_solido`). Si guarda da sessanta metri.

const MOTORINI := ["vespa", "scooter_bianco", "scooter_blu", "vespa"]
const MOTORINO_DIM := Vector3(0.72, 1.15, 1.85)
const CONI := ["cono_grande", "cono_striato", "cono_basso"]
const VIENNA_DIM := Vector3(0.46, 0.9, 0.5)
const CASCETTA_DIM := Vector3(0.56, 0.26, 0.47)
const BIDONE_DIM := Vector3(0.62, 0.95, 0.62)
const CASSA_DIM := Vector3(0.56, 0.56, 0.56)
const UFFICIO_DIM := Vector3(0.68, 1.05, 0.76)


## Il pezzo ci sta? Le domande della città, tutte. I perché dei no si
## contano in `rifiuti` (li stampa `sonda_decal`).
static var rifiuti: Dictionary = {}


static func _no(perche: String) -> bool:
	rifiuti[perche] = int(rifiuti.get(perche, 0)) + 1
	return false


static func _ce_sta(c: Node3D, p: Vector3, dim: Vector3, giro: float) -> bool:
	if not _dint_a_mappa(c, p):
		return _no("mappa")
	var r: float = maxf(dim.x, dim.z) * 0.5
	var perche: String = c._perche_nun_sta(p, r, minf(r, 0.4))
	if perche != "":
		return _no("libero:" + perche)
	if not c._scatola_libera(p, dim, giro):
		return _no("scatola")
	if not c._puo_avere_corpo(p + Vector3(0, dim.y * 0.5, 0), dim, giro):
		return _no("corpo")
	return true


static func _dint_a_mappa(c: Node3D, p: Vector3) -> bool:
	return p.x > 1.0 and p.x < float(c.LARGHEZZA) - 1.0 \
		and p.z > 1.0 and p.z < float(c.PROFONDITA) - 1.0


## Quanto sta sotto all'origine il modello (i motorini di Poly Pizza hanno
## l'origine a mezz'altezza: messi a terra così, affondavano di mezzo
## metro nell'asfalto — prima foto dei motorini).
static var _sotto: Dictionary = {}


static func _base(c: Node3D, nome: String) -> float:
	if _sotto.has(nome):
		return _sotto[nome]
	var y := INF
	for pz in c._pezzi_modello(nome):
		var a: AABB = (pz["trasf"] as Transform3D) * (pz["mesh"] as Mesh).get_aabb()
		y = minf(y, a.position.y)
	var fore: float = 0.0 if y == INF else y
	_sotto[nome] = fore
	return fore


static func _metti(c: Node3D, nome: String, p: Vector3, giro: float,
		dim: Vector3, gruppo: String) -> bool:
	if not Models.has_model(nome):
		return false
	if not c._panda_c(nome, p - Vector3(0, _base(c, nome), 0), giro, gruppo, 60.0):
		return false
	c._solido(p + Vector3(0, dim.y * 0.5, 0), dim, giro)
	return true


## **'E motorini ô marciappiede.** Sulle strade larghe, fra una macchina e
## l'altra, i motorini stanno in fila contro il cordolo, a due o tre: come
## a Napoli, dove un buco di un metro è un posto. Di punta non ci stanno:
## la carreggiata del Decumano è larga quattro metri e due, e la corsia
## libera se ne prende due e due.
static func _motorini_ô_marciappiede(c: Node3D, rng: RandomNumberGenerator) -> void:
	var messi := 0
	for s in c.STRADE:
		var x0: float = float(s[0])
		var z0: float = float(s[1])
		var x1: float = float(s[2])
		var z1: float = float(s[3])
		var w: float = x1 - x0
		var l: float = z1 - z0
		if minf(w, l) <= 5.5:
			continue
		var lungo_z: bool = l > w
		var corsa: float = l if lungo_z else w
		var larga: float = w if lungo_z else l
		var mezzo: float = (x0 + x1) * 0.5 if lungo_z else (z0 + z1) * 0.5
		var inizio: float = z0 if lungo_z else x0
		var t: float = rng.randf_range(8.0, 20.0)
		while t < corsa - 6.0:
			var lato: float = 1.0 if rng.randf() < 0.5 else -1.0
			var trasv: float = mezzo + lato * (larga * 0.5 - 1.4 - MOTORINO_DIM.x * 0.5 - 0.06)
			var giro: float = 0.0 if lungo_z else PI * 0.5
			var quanti: int = rng.randi_range(1, 3)
			for k in range(quanti):
				var lungo_t: float = t + float(k) * 2.0
				var p := Vector3(trasv, 0.0, inizio + lungo_t) if lungo_z \
					else Vector3(inizio + lungo_t, 0.0, trasv)
				var g: float = giro + (PI if rng.randf() < 0.5 else 0.0) \
					+ rng.randf_range(-0.06, 0.06)
				var nome: String = MOTORINI[rng.randi() % MOTORINI.size()]
				if not _strada_bbona(c, p):
					_no("strada")
					continue
				if _ce_sta(c, p, MOTORINO_DIM, g):
					if _metti(c, nome, p, g, MOTORINO_DIM, "esterni_" + nome):
						messi += 1
			t += rng.randf_range(14.0, 26.0)
	c.set_meta(&"motorini_strada", messi)


## Due coni per testa di cantiere, sul lato della strada: chi arriva vede
## prima i coni e poi la transenna.
static func _coni_ê_cantieri(c: Node3D, rng: RandomNumberGenerator) -> void:
	var messi := 0
	for ci in c._cantieri_info:
		var centro: Vector3 = ci[0]
		var lungo: Vector3 = ci[1]
		var muro: Vector3 = ci[2]
		for verso in [-1.0, 1.0]:
			for k in range(2):
				# In fila sulla linea della transenna e poi verso il muro:
				# dalla parte della strada c'è la corsia libera.
				var p: Vector3 = centro + lungo * (verso * (4.4 + float(k) * 0.8)) \
					+ muro * (0.1 + float(k) * 0.4)
				var nome: String = CONI[(messi + k) % CONI.size()]
				var dim := Vector3(0.45, 0.7, 0.45)
				if _ce_sta(c, p, dim, 0.0):
					if _metti(c, nome, p, rng.randf_range(-PI, PI), dim, "esterni_cono"):
						messi += 1
	c.set_meta(&"coni_cantieri", messi)


## **'A seggia 'e Vienna e 'a cascetta pe' tavulino.** Davanti a qualche
## basso, dove non ci sono già le sedie: una sedia da bar di legno curvato
## (quelle che i bar buttano e i vicini si prendono) e accanto due
## cassette della frutta una sopra l'altra, con sopra il caffè.
static func _segge_vienna(c: Node3D, rng: RandomNumberGenerator) -> void:
	var messe := 0
	for v in c._vasci_fore:
		if messe >= 12:
			break
		if rng.randf() > 0.3:
			continue
		var porta: Vector3 = v[0]
		var fen: Vector3 = v[1]
		var fuori: Vector3 = v[2]
		var lungo: Vector3 = (fen - porta).normalized()
		var giro: float = atan2(fuori.x, fuori.z)
		# Oltre la finestra (le sedie di `RobbaPsx` stanno sotto).
		var p: Vector3 = fen + lungo * 1.15 + fuori * 0.5
		var g: float = giro + rng.randf_range(-0.4, 0.4)
		if not _ce_sta(c, p, VIENNA_DIM, g):
			continue
		var tav: Vector3 = p + lungo * 0.72 + fuori * 0.05
		var g_t: float = giro + rng.randf_range(-0.2, 0.2)
		if not _ce_sta(c, tav, CASCETTA_DIM, g_t):
			continue
		_metti(c, "seggia_vienna", p, g, VIENNA_DIM, "esterni_seggia_vienna")
		var giu := Vector3(0, _base(c, "cascetta_frutta"), 0)
		c._panda_c("cascetta_frutta", tav - giu, g_t, "esterni_cascetta", 45.0)
		c._panda_c("cascetta_frutta", tav + Vector3(0, CASCETTA_DIM.y, 0) - giu,
			g_t + rng.randf_range(-0.15, 0.15), "esterni_cascetta_sopra", 45.0)
		c._solido(tav + Vector3(0, CASCETTA_DIM.y, 0),
			Vector3(CASCETTA_DIM.x, CASCETTA_DIM.y * 2.0, CASCETTA_DIM.z), g_t)
		if Models.has_model("tazzulella") and rng.randf() < 0.7:
			c._panda("tazzulella", tav + Vector3(0.05, CASCETTA_DIM.y * 2.0 + 0.01, 0.0),
				rng.randf_range(-PI, PI), "esterni_tazzulella", 30.0)
		messe += 1
	c.set_meta(&"segge_vienna", messe)


## I bidoni di ferro sul marciapiede delle strade larghe (i cestini che il
## Comune mette ogni tanto e che nessuno svuota), e accanto ai cassonetti,
## dove c'è posto, una cassa di legno buttata.
static func _ai_cassonetti(c: Node3D, rng: RandomNumberGenerator) -> void:
	var bidoni := 0
	var casse := 0
	for s in c.STRADE:
		var x0: float = float(s[0])
		var z0: float = float(s[1])
		var x1: float = float(s[2])
		var z1: float = float(s[3])
		var w: float = x1 - x0
		var l: float = z1 - z0
		if minf(w, l) <= 5.5:
			continue
		var lungo_z: bool = l > w
		var corsa: float = l if lungo_z else w
		var larga: float = w if lungo_z else l
		var mezzo: float = (x0 + x1) * 0.5 if lungo_z else (z0 + z1) * 0.5
		var inizio: float = z0 if lungo_z else x0
		var t: float = rng.randf_range(10.0, 30.0)
		while t < corsa - 5.0:
			var lato: float = 1.0 if rng.randf() < 0.5 else -1.0
			# Sul marciapiede, dalla parte della strada.
			var trasv: float = mezzo + lato * (larga * 0.5 - 1.05)
			var p := Vector3(trasv, 0.16, inizio + t) if lungo_z \
				else Vector3(inizio + t, 0.16, trasv)
			var g: float = rng.randf_range(-PI, PI)
			if _strada_bbona(c, p) and _ce_sta(c, p, BIDONE_DIM, g):
				if _metti(c, "bidone_ferro", p, g, BIDONE_DIM, "esterni_bidone"):
					bidoni += 1
			t += rng.randf_range(30.0, 55.0)
	for cs in c._cassonetti:
		if rng.randf() > 0.5:
			continue
		var p0: Vector3 = cs[0]
		var giro: float = float(cs[1])
		var lungo := Vector3(cos(giro), 0, -sin(giro))
		# Da vicino ci stanno già i sacchetti, l'ingombrante e la campana
		# (`_munnezza_attuorno`) e la roba PSX (`_munnezza_cchiu`, a tre-
		# cinque metri): la cassa va dove resta posto, fino a sei metri e
		# mezzo. Con solo i tre metri e mezzo di prima non ne entrava
		# nessuna (sonda_esterni, 0.62).
		for d in [2.1, -2.1, 2.8, -2.8, 3.5, -3.5, 5.5, -5.5, 6.5, -6.5]:
			var p: Vector3 = p0 + lungo * float(d)
			var g: float = giro + rng.randf_range(-0.3, 0.3)
			if not _ce_sta(c, p, CASSA_DIM, g):
				continue
			if _metti(c, "cassa_legno", p, g, CASSA_DIM, "esterni_cassa"):
				casse += 1
			break
	c.set_meta(&"bidoni_ferro", bidoni)
	c.set_meta(&"casse_legno", casse)


## **'A seggia 'e ll'ufficio** buttata contro un muro, vicino a una scena
## d'angolo: l'ingombrante di chi ha svuotato uno studio. Il posto lo trova
## `_posto_pe_scena`, come per i materassi.
static func _segge_ufficio(c: Node3D, rng: RandomNumberGenerator) -> void:
	var messe := 0
	var k := 0
	while messe < 3 and k < c.ANGOLI.size():
		var a: Array = c.ANGOLI[(k * 5 + 4) % c.ANGOLI.size()]
		k += 1
		var pezzi := [["seggia_ufficio", 0.0, UFFICIO_DIM.x * 0.5,
			UFFICIO_DIM.z * 0.5, 0.0, UFFICIO_DIM]]
		var posto: Dictionary = c._posto_pe_scena(Vector3(float(a[0]), 0.0,
			float(a[1]) - 3.0), pezzi)
		if posto.is_empty():
			continue
		var giro: float = float(posto["giro"])
		var fuori := Vector3(sin(giro), 0, cos(giro))
		var p: Vector3 = (posto["muro"] as Vector3) + fuori * (UFFICIO_DIM.z * 0.5 + 0.05)
		var g: float = giro + rng.randf_range(-0.9, 0.9)
		if not _ce_sta(c, p, UFFICIO_DIM, g):
			continue
		if _metti(c, "seggia_ufficio", p, g, UFFICIO_DIM, "esterni_seggia_ufficio"):
			messe += 1
	c.set_meta(&"segge_ufficio", messe)
