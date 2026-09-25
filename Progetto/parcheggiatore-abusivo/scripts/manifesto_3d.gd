extends StaticBody3D
## Manifesto
## Uno dei sei manifesti attaccati ai muri del quartiere.
##
## Non sono scenografia: sono la collezione. Stanno appiccicati in posti
## dove uno non passa per caso — dietro a un cassonetto, sotto a un
## ponteggio, dall'altra parte di un furgone fermo da tre mesi — e per
## prenderli bisogna trovarli e fotografarli.
##
## Il riparo davanti non è un abbellimento: è la meccanica. Ogni manifesto
## nasce con qualcosa piantato davanti che lo copre da dove il giocatore
## passerebbe normalmente. Se lo vedi, vuol dire che ti sei girato apposta.
##
## Perché fotografarli invece di raccoglierli: raccogliere una cosa
## attaccata a un muro non ha senso, e comunque il manifesto deve restare lì
## dopo — è del quartiere, non tuo. Fotografandolo resta al suo posto e ti
## resta il ricordo, che è esattamente come funzionano gli easter egg.

const Tex := preload("res://scripts/textures.gd")

## Larghezza e altezza del foglio, in metri. Un manifesto vero attaccato a un
## muro napoletano è circa così: poco meno di un metro, all'altezza degli
## occhi di chi passa.
const LATO: float = 0.92
const ALTEZZA_CENTRO: float = 1.66

## Da quanto lontano smette di essere disegnato. Sono oggetti piccoli e
## nascosti: oltre i quaranta metri non li vedresti comunque.
const DISTANZA_VISTA: float = 44.0

var id: String = ""
var titolo: String = ""
var sotto: String = ""
var texture_path: String = ""
var riparo: String = "cassonetto"

var _foglio: MeshInstance3D
var _mat: StandardMaterial3D


## La città chiama questa prima di aggiungerlo all'albero.
func configura(dati: Dictionary, tipo_riparo: String) -> void:
	id = str(dati.get("id", ""))
	titolo = str(dati.get("titolo", ""))
	sotto = str(dati.get("sotto", ""))
	texture_path = str(dati.get("file", ""))
	riparo = tipo_riparo


func _ready() -> void:
	add_to_group("manifesti")
	collision_layer = 1
	collision_mask = 0
	_muro()
	_carta()
	_collisione_foglio()
	match riparo:
		"cassonetto": _cassonetto()
		"casse": _casse()
		"ponteggio": _ponteggio()
		"furgone": _furgone()
		_: _cassonetto()
	_luce()
	_aggiorna_stato()
	if not GameManager.manifesto_fotografato.is_connected(_on_fotografato):
		GameManager.manifesto_fotografato.connect(_on_fotografato)


# ---------------------------------------------------------------------------
# Il muro e la carta
# ---------------------------------------------------------------------------

## Un pezzo di muro cieco dietro al manifesto. Serve a due cose: dare al
## foglio una superficie credibile su cui stare, e chiudere il posto da
## dietro così l'unico modo di vederlo è girare intorno al riparo.
func _muro() -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(4.2, 4.6, 0.5)
	m.mesh = bm
	m.position = Vector3(0, 2.3, -0.3)
	m.material_override = Tex.mondo("muro_crema", Color(0.86, 0.82, 0.74), 0.94)
	_lontano(m)
	add_child(m)

	var f := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(4.2, 4.6, 0.5)
	f.shape = bx
	f.position = Vector3(0, 2.3, -0.3)
	add_child(f)

	# Lo zoccolo scrostato in basso: un muro di vicolo non è mai pulito
	# fino a terra.
	var z := MeshInstance3D.new()
	var zm := BoxMesh.new()
	zm.size = Vector3(4.3, 0.9, 0.56)
	z.mesh = zm
	z.position = Vector3(0, 0.45, -0.3)
	z.material_override = Tex.flat(Color(0.42, 0.40, 0.36), 0.96)
	_lontano(z)
	add_child(z)


## Il foglio vero e proprio, più la colla intorno.
func _carta() -> void:
	# Il bordo di colla e carta strappata: un rettangolo appena più grande,
	# scuro, dietro al foglio. È quello che fa sembrare il manifesto
	# *attaccato* e non appeso.
	var colla := MeshInstance3D.new()
	var cp := PlaneMesh.new()
	cp.size = Vector2(LATO + 0.11, LATO + 0.11)
	colla.mesh = cp
	colla.rotation.x = deg_to_rad(90)
	colla.position = Vector3(0, ALTEZZA_CENTRO, -0.038)
	colla.material_override = Tex.flat(Color(0.24, 0.22, 0.19), 0.98)
	_lontano(colla)
	add_child(colla)

	_mat = StandardMaterial3D.new()
	var tex: Texture2D = null
	if texture_path != "" and ResourceLoader.exists(texture_path):
		tex = load(texture_path)
	_mat.albedo_texture = tex
	_mat.roughness = 0.95
	_mat.metallic = 0.0
	# Un filo di emissione: di notte, in un vicolo senza lampione, un
	# manifesto stampato resterebbe una macchia nera e non lo troveresti
	# mai. Così invece si legge appena, come sotto a un riverbero.
	_mat.emission_enabled = true
	_mat.emission_texture = tex
	_mat.emission = Color(1, 1, 1)
	_mat.emission_energy_multiplier = 0.30

	_foglio = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(LATO, LATO)
	_foglio.mesh = pm
	_foglio.rotation.x = deg_to_rad(90)
	# Appena storto: nessuno attacca un manifesto con la livella.
	_foglio.rotation.z = deg_to_rad(randf_range(-2.2, 2.2))
	_foglio.position = Vector3(0, ALTEZZA_CENTRO, -0.028)
	_foglio.material_override = _mat
	_lontano(_foglio)
	add_child(_foglio)


## Il pezzo di muro davanti al foglio che il raggio dell'interazione deve
## colpire. Sta un dito più avanti della carta, così mirare al manifesto
## significa mirare a questo.
func _collisione_foglio() -> void:
	var f := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(LATO, LATO, 0.06)
	f.shape = bx
	f.position = Vector3(0, ALTEZZA_CENTRO, 0.0)
	add_child(f)


## Una lampadina piccola dentro al bugigattolo.
##
## Serve a un problema concreto: questi muri stanno quasi tutti in ombra —
## sono dietro a qualcosa, per costruzione — e un manifesto stampato al buio
## e' una macchia scura che non guardi nemmeno. Con una luce corta il foglio
## si stacca dal muro appena ti affacci, e di notte fa da richiamo.
##
## Costa poco: raggio quattro metri, niente ombre, e si spegne da sola oltre
## i venticinque metri.
func _luce() -> void:
	var l := OmniLight3D.new()
	l.light_energy = 1.15
	l.light_color = Color(1.0, 0.92, 0.78)
	l.omni_range = 4.2
	l.omni_attenuation = 1.4
	l.shadow_enabled = false
	l.distance_fade_enabled = true
	l.distance_fade_begin = 18.0
	l.distance_fade_length = 7.0
	l.position = Vector3(0, 2.55, 0.95)
	add_child(l)


func _lontano(n: GeometryInstance3D) -> void:
	n.visibility_range_end = DISTANZA_VISTA
	n.visibility_range_end_margin = 6.0


# ---------------------------------------------------------------------------
# I ripari: quello che sta davanti e lo copre
# ---------------------------------------------------------------------------

func _blocco(pos: Vector3, dim: Vector3, mat: Material, ang: float = 0.0) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = dim
	m.mesh = bm
	m.position = pos
	m.rotation.y = ang
	m.material_override = mat
	_lontano(m)
	add_child(m)

	var f := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = dim
	f.shape = bx
	f.position = pos
	f.rotation.y = ang
	add_child(f)


func _cassonetto() -> void:
	var lamiera := Tex.flat(Color(0.20, 0.34, 0.26), 0.75, 0.35)
	var plastica := Tex.flat(Color(0.14, 0.22, 0.18), 0.6, 0.2)
	_blocco(Vector3(0.15, 0.72, 1.35), Vector3(2.5, 1.44, 1.2), lamiera,
		deg_to_rad(4))
	# Il coperchio, mezzo aperto.
	var cop := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(2.5, 0.12, 1.25)
	cop.mesh = cm
	cop.position = Vector3(0.15, 1.62, 1.6)
	cop.rotation = Vector3(deg_to_rad(-22), deg_to_rad(4), 0)
	cop.material_override = plastica
	_lontano(cop)
	add_child(cop)
	# Le ruote e i sacchi buttati a fianco.
	for d in [-1.0, 1.0]:
		var sacco := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.34
		sm.height = 0.56
		sm.radial_segments = 8
		sm.rings = 5
		sacco.mesh = sm
		sacco.position = Vector3(0.15 + d * 1.55, 0.28, 1.1 + d * 0.3)
		sacco.material_override = Tex.flat(Color(0.12, 0.12, 0.13), 0.7)
		_lontano(sacco)
		add_child(sacco)


func _casse() -> void:
	var legno := Tex.flat(Color(0.62, 0.48, 0.30), 0.92)
	var legno2 := Tex.flat(Color(0.54, 0.42, 0.26), 0.92)
	var pila := [
		[Vector3(-0.55, 0.30, 1.25), 0.06], [Vector3(0.55, 0.30, 1.3), -0.1],
		[Vector3(-0.5, 0.90, 1.28), -0.14], [Vector3(0.6, 0.90, 1.22), 0.11],
		[Vector3(0.0, 1.50, 1.3), 0.05], [Vector3(1.35, 0.30, 1.15), 0.2],
		[Vector3(1.3, 0.90, 1.2), -0.06], [Vector3(-1.4, 0.30, 1.2), -0.18],
	]
	var i := 0
	for c in pila:
		_blocco(c[0], Vector3(1.0, 0.58, 0.72),
			legno if i % 2 == 0 else legno2, float(c[1]))
		i += 1


func _ponteggio() -> void:
	var tubo := Tex.flat(Color(0.55, 0.53, 0.50), 0.5, 0.55)
	var tavola := Tex.flat(Color(0.66, 0.56, 0.38), 0.94)
	var telo := Tex.flat(Color(0.32, 0.42, 0.55), 0.9)
	# I montanti.
	for x in [-1.7, 0.0, 1.7]:
		for z in [0.8, 2.0]:
			var p := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.055
			cm.bottom_radius = 0.055
			cm.height = 4.4
			cm.radial_segments = 6
			p.mesh = cm
			p.position = Vector3(x, 2.2, z)
			p.material_override = tubo
			_lontano(p)
			add_child(p)
	# I traversi e l'impalcato: è l'impalcato che ti copre la vista.
	for h in [1.15, 2.45, 3.7]:
		var t := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(3.7, 0.07, 0.07)
		t.mesh = bm
		t.position = Vector3(0, h, 0.8)
		t.material_override = tubo
		_lontano(t)
		add_child(t)
	_blocco(Vector3(0, 2.42, 1.4), Vector3(3.8, 0.14, 1.5), tavola)
	# Il telo verde da cantiere, che è la cosa che davvero lo nasconde.
	var v := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(3.8, 4.4)
	v.mesh = pm
	v.rotation.x = deg_to_rad(90)
	v.position = Vector3(0, 2.2, 2.05)
	var tm: StandardMaterial3D = telo.duplicate()
	tm.cull_mode = BaseMaterial3D.CULL_DISABLED
	v.material_override = tm
	_lontano(v)
	add_child(v)


func _furgone() -> void:
	var lamiera := Tex.flat(Color(0.78, 0.76, 0.72), 0.55, 0.3)
	var vetro := Tex.flat(Color(0.10, 0.13, 0.17), 0.25, 0.7)
	var gomma := Tex.flat(Color(0.09, 0.09, 0.10), 0.9)
	var ang := deg_to_rad(6)
	# Cassone e cabina, messi di traverso davanti al muro ma sfalsati verso
	# sinistra: da destra resta un passaggio. Se il furgone chiudesse tutto
	# il manifesto sarebbe irraggiungibile, non nascosto — e un easter egg
	# che non si puo' prendere e' solo un errore.
	_blocco(Vector3(-0.75, 1.35, 2.6), Vector3(4.2, 2.1, 1.8), lamiera, ang)
	_blocco(Vector3(-3.3, 1.0, 2.8), Vector3(1.5, 1.5, 1.75), lamiera, ang)
	var p := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.06, 0.8, 1.5)
	p.mesh = pm
	p.position = Vector3(-3.98, 1.25, 2.8)
	p.material_override = vetro
	_lontano(p)
	add_child(p)
	for r in [Vector3(-3.1, 0.36, 3.4), Vector3(0.7, 0.36, 3.4)]:
		var w := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.36
		cm.bottom_radius = 0.36
		cm.height = 0.26
		cm.radial_segments = 10
		w.mesh = cm
		w.position = r
		w.rotation.z = deg_to_rad(90)
		w.material_override = gomma
		_lontano(w)
		add_child(w)


# ---------------------------------------------------------------------------
# L'interazione
# ---------------------------------------------------------------------------

func gia_preso() -> bool:
	return GameManager.manifesto_preso(id)


func get_interact_prompt(_da: Vector3) -> String:
	if gia_preso():
		return "%s — l'hê già fotografato" % titolo
	return "Nu manifesto… fallo 'na foto: premi E"


func player_interact() -> void:
	if gia_preso():
		return
	GameManager.fotografa_manifesto(id)


## Dopo la foto il foglio si stinge appena e smette di brillare: serve a
## riconoscere da lontano quelli già presi, senza doverci tornare sopra.
func _on_fotografato(quale: String, _titolo: String, _n: int, _tot: int) -> void:
	if quale == id:
		_aggiorna_stato()


func _aggiorna_stato() -> void:
	if _mat == null:
		return
	if gia_preso():
		_mat.emission_energy_multiplier = 0.0
		_mat.albedo_color = Color(0.62, 0.60, 0.58)
	else:
		_mat.emission_energy_multiplier = 0.30
		_mat.albedo_color = Color(1, 1, 1)
