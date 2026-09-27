extends Node3D
## **'O fierro 'n primma perzona** (0.61)
##
## ## Il problema
##
## Il capo, dopo una giornata intera: *«Le armi acquistate non si vedono
## bene in mano e non si capisce se si stanno usando o no.»*
##
## Dalla 0.58 l'arma stava appesa all'osso `hand_r` del corpo. Era giusto
## per chi ti guarda da fuori, e sbagliato per te: la mano del corpo sta
## all'altezza del fianco, cioè **sotto all'inquadratura**. Si vedeva solo
## guardandosi i piedi, e il colpo — che è un'animazione del corpo — si
## vedeva ancora meno. Premevi, la mazza non si muoveva, e l'unica prova
## che avevi menato era il suono.
##
## ## La risposta
##
## La stessa di tutti i giochi in prima persona dal 1993: l'arma che vedi
## tu **non è** quella del corpo. È un modellino appeso alla telecamera, in
## basso a destra, con la mano e un pezzo di manica, che:
##
##   * dondola quando cammini e respira quando stai fermo;
##   * scende e risale quando cambi arma (così il cambio si vede);
##   * **fa il colpo**: il cric e la mazza un fendente da destra a
##     sinistra, il curtiello una stoccata, la pistola rincula con la
##     vampata e la scia fino a dove ha colpito, il kalash uguale ma più
##     grosso.
##
## Il modello sul corpo resta (per l'ombra e per chi guarda da fuori), ma
## getta solo l'ombra: in prima persona se ne vedeva uno doppio.
##
## ## Perché è piccolo
##
## Tutto il modellino è costruito in scala vera e poi rimpicciolito a
## `SCALA`, tenendo le proporzioni: un oggetto grande la metà a metà
## distanza sembra identico, ma sta **dentro alla capsula del giocatore**
## (raggio 35 cm) e non entra mai nei muri quando ti ci appoggi.

const Models := preload("res://scripts/models.gd")
const Tex := preload("res://scripts/textures.gd")

const SCALA: float = 0.42
## Dove sta la mano a riposo, in metri veri davanti all'occhio.
const RIPOSO := Vector3(0.30, -0.27, -0.50)
## **'A spalla** (rispetto alla mano): il colpo ruota tutto il braccio
## attorno a lei. Al primo giro ruotava attorno al pugno, e nel fendente
## la manica si alzava di traverso sullo schermo come una sbarra.
const SPALLA := Vector3(0.20, -0.44, 0.72)
const PELLE := Color(0.84, 0.65, 0.5)
const MANICA := Color(0.46, 0.53, 0.61)

## Per ogni arma: modello, rotazione (gradi), spostamento dentro alla mano,
## scala del modello, tipo di colpo, e dove sta la bocca (per le armi da
## fuoco, nel sistema della mano).
##
## Le rotazioni vengono da una fotografia (`tools/foto_armi.gd`), non da un
## conto: ogni modello del pacchetto ha il lungo su un asse diverso.
## Il cric, la mazza e il curtiello si costruiscono a pezzi (`_costruisci`):
## nel pacchetto PSX il «cric» era un gomito di tubo idraulico e la mazza un
## manganello da poliziotto col manico laterale, e in prima persona — dove
## li guardi da trenta centimetri — si vedeva. Sul corpo restano quelli.
const ARMI := {
	"cric": {"modello": "", "rot": Vector3.ZERO,
		"pos": Vector3.ZERO, "scala": 1.0, "colpo": "fendente"},
	"mazza": {"modello": "", "rot": Vector3.ZERO,
		"pos": Vector3.ZERO, "scala": 1.0, "colpo": "fendente"},
	"curtiello": {"modello": "", "rot": Vector3.ZERO,
		"pos": Vector3.ZERO, "scala": 1.45, "colpo": "stoccata"},
	"fierro": {"modello": "fierro", "rot": Vector3(0, 90, 0),
		"pos": Vector3(-0.03, 0.02, 0.05), "scala": 1.1, "colpo": "sparo",
		"bocca": Vector3(-0.03, 0.10, -0.26)},
	"kalash": {"modello": "", "rot": Vector3.ZERO, "pos": Vector3.ZERO,
		"scala": 1.0, "colpo": "raffica", "bocca": Vector3(0.0, 0.07, -0.78)},
}

var _rig: Node3D          # la spalla: ruota tutto il braccio
var _mano: Node3D         # la mano con l'arma, in fondo al braccio
var _arma: Node3D         # solo l'arma, dentro alla mano
var _bocca: Node3D        # la punta della canna, per vampata e scia
var _vampata: Node3D
var _luce: OmniLight3D
var _id: String = ""

var _t_colpo: float = -1.0
var _colpo: String = ""
var _t_cambio: float = -1.0
var _passo: float = 0.0
var _respiro: float = 0.0
var _moto: float = 0.0     # 0 fermo, 1 cammina, ~1.7 corre
## (0.65) Vero mentre le mani della regia stanno davanti all'occhio: il
## fierro non si vede (lo scrive `player_fps._aggiorna_mani`).
var nascosta: bool = false


func _ready() -> void:
	scale = Vector3.ONE * SCALA
	_rig = Node3D.new()
	add_child(_rig)
	_rig.position = RIPOSO + SPALLA
	_mano = Node3D.new()
	_rig.add_child(_mano)
	_mano.position = -SPALLA
	_build_mano()
	_arma = Node3D.new()
	_mano.add_child(_arma)
	_bocca = Node3D.new()
	_mano.add_child(_bocca)
	_build_vampata()
	visible = false


# ---------------------------------------------------------------------------
# 'A mano e 'a manica
# ---------------------------------------------------------------------------

func _build_mano() -> void:
	var pugno := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.085, 0.095, 0.105)
	pugno.mesh = bm
	pugno.material_override = Tex.flat(PELLE, 0.8)
	pugno.position = Vector3(0.0, -0.01, 0.02)
	_mano.add_child(pugno)
	# Le nocche: una striscia un filo più chiara davanti, così il pugno
	# chiuso si legge come pugno e non come un dado.
	var nocche := MeshInstance3D.new()
	var nb := BoxMesh.new()
	nb.size = Vector3(0.088, 0.03, 0.04)
	nocche.mesh = nb
	nocche.material_override = Tex.flat(PELLE.lightened(0.08), 0.8)
	nocche.position = Vector3(-0.004, 0.03, -0.02)
	_mano.add_child(nocche)
	# Il pollice, sopra all'impugnatura.
	var pollice := MeshInstance3D.new()
	var pb := BoxMesh.new()
	pb.size = Vector3(0.03, 0.028, 0.07)
	pollice.mesh = pb
	pollice.material_override = Tex.flat(PELLE.darkened(0.05), 0.8)
	pollice.position = Vector3(-0.045, 0.035, 0.0)
	_mano.add_child(pollice)
	# L'avambraccio: dalla mano all'indietro e in basso, fino a fuori
	# dall'inquadratura. I cilindri si mettono **fra due punti** (vedi
	# `_fra`): con le rotazioni scritte a mano, al primo giro la manica
	# stava in piedi accanto alla mano come un barattolo.
	var polso := _fra(Vector3(0.0, -0.03, 0.05), Vector3(0.07, -0.16, 0.30),
		0.036, 0.042, Tex.flat(PELLE.darkened(0.04), 0.85))
	var manica := _fra(Vector3(0.05, -0.12, 0.24), Vector3(0.16, -0.36, 0.62),
		0.058, 0.072, Tex.flat(MANICA, 0.9))
	for m in [pugno, nocche, pollice, polso, manica]:
		(m as GeometryInstance3D).cast_shadow = \
			GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Un cilindro da `a` a `b`, figlio della mano.
func _fra(a: Vector3, b: Vector3, r_a: float, r_b: float,
		mat: Material, dove: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	# Il cilindro di Godot va da −h/2 (sotto, `bottom_radius`) a +h/2.
	cm.bottom_radius = r_a
	cm.top_radius = r_b
	cm.height = a.distance_to(b)
	cm.radial_segments = 8
	mi.mesh = cm
	mi.material_override = mat
	var y: Vector3 = (b - a).normalized()
	var x: Vector3 = y.cross(Vector3.FORWARD)
	if x.length() < 0.01:
		x = y.cross(Vector3.RIGHT)
	x = x.normalized()
	var z: Vector3 = x.cross(y).normalized()
	mi.transform = Transform3D(Basis(x, y, z), (a + b) * 0.5)
	(dove if dove != null else _mano).add_child(mi)
	return mi


func _build_vampata() -> void:
	_vampata = Node3D.new()
	_bocca.add_child(_vampata)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(1.0, 0.78, 0.32, 0.95)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Tre lame incrociate: da qualunque angolo si vede una stella.
	for i in range(3):
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.20, 0.07)
		q.mesh = qm
		q.material_override = mat
		q.rotation = Vector3(0, deg_to_rad(90), deg_to_rad(60.0 * i))
		q.position = Vector3(0, 0, -0.08)
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_vampata.add_child(q)
	var disco := MeshInstance3D.new()
	var dm := QuadMesh.new()
	dm.size = Vector2(0.13, 0.13)
	disco.mesh = dm
	disco.material_override = mat
	disco.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_vampata.add_child(disco)
	_luce = OmniLight3D.new()
	_luce.light_color = Color(1.0, 0.75, 0.4)
	_luce.omni_range = 6.0
	_luce.light_energy = 0.0
	_luce.shadow_enabled = false
	_bocca.add_child(_luce)
	_vampata.visible = false


# ---------------------------------------------------------------------------
# Che se tene 'n mano
# ---------------------------------------------------------------------------

func mostra(id: String) -> void:
	if id == _id:
		return
	_id = id
	for c in _arma.get_children():
		c.free()
	if not ARMI.has(id):
		visible = false
		return
	visible = true
	var d: Dictionary = ARMI[id]
	var m: Node3D = null
	if id == "kalash":
		m = _costruisci_kalash()
	elif str(d["modello"]) == "":
		m = _costruisci(id)
	else:
		m = Models.spawn(str(d["modello"]))
	if m != null:
		var r: Vector3 = d["rot"]
		m.rotation = Vector3(deg_to_rad(r.x), deg_to_rad(r.y), deg_to_rad(r.z))
		m.position = d["pos"]
		m.scale = Vector3.ONE * float(d["scala"])
		_arma.add_child(m)
		_senza_ombra(m)
	_bocca.position = d.get("bocca", Vector3(0, 0, -0.3))
	# E si vede che l'hai presa: scende e risale.
	_t_cambio = 0.0


func _senza_ombra(n: Node) -> void:
	if n is GeometryInstance3D:
		(n as GeometryInstance3D).cast_shadow = \
			GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children():
		_senza_ombra(c)


## **'E fierre fatte a mano.** Tutti col manico nel pugno (l'origine) e il
## lungo verso −Z, cioè avanti e un filo in su.
func _costruisci(id: String) -> Node3D:
	var k := Node3D.new()
	var acciaio := Tex.flat(Color(0.52, 0.53, 0.55), 0.35)
	var scuro := Tex.flat(Color(0.12, 0.12, 0.13), 0.6)
	match id:
		"cric":
			# 'A chiave a croce d''e ggomme: due sbarre incrociate, quella
			# che stringi e quella che fa male.
			_fra(Vector3(0, 0.0, 0.10), Vector3(0, 0.10, -0.34), 0.012, 0.012,
				acciaio, k)
			_fra(Vector3(-0.17, 0.08, -0.26), Vector3(0.17, 0.08, -0.26),
				0.012, 0.012, acciaio, k)
			for p in [Vector3(0, 0.10, -0.34), Vector3(-0.17, 0.08, -0.26),
					Vector3(0.17, 0.08, -0.26)]:
				var t := MeshInstance3D.new()
				var bm := CylinderMesh.new()
				bm.top_radius = 0.022
				bm.bottom_radius = 0.022
				bm.height = 0.035
				t.mesh = bm
				t.material_override = scuro
				t.position = p
				k.add_child(t)
		"mazza":
			# Un pezzo di tubo innocente, col nastro nero dove si stringe.
			_fra(Vector3(0, -0.02, 0.10), Vector3(0, 0.20, -0.52), 0.019,
				0.019, acciaio, k)
			_fra(Vector3(0, -0.025, 0.11), Vector3(0, 0.03, -0.06), 0.023,
				0.023, scuro, k)
			var tappo := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.024
			sm.height = 0.04
			tappo.mesh = sm
			tappo.material_override = acciaio
			tappo.position = Vector3(0, 0.20, -0.52)
			k.add_child(tappo)
		"curtiello":
			# Manico di legno scuro, guardia, lama che luccica.
			var legno := Tex.flat(Color(0.30, 0.17, 0.08), 0.7)
			var lama := Tex.flat(Color(0.80, 0.82, 0.86), 0.18)
			_fra(Vector3(0, -0.01, 0.07), Vector3(0, 0.015, -0.05), 0.017,
				0.019, legno, k)
			var guardia := MeshInstance3D.new()
			var gb := BoxMesh.new()
			gb.size = Vector3(0.012, 0.05, 0.012)
			guardia.mesh = gb
			guardia.material_override = scuro
			guardia.position = Vector3(0, 0.017, -0.055)
			k.add_child(guardia)
			var l := MeshInstance3D.new()
			var lb := BoxMesh.new()
			lb.size = Vector3(0.006, 0.034, 0.17)
			l.mesh = lb
			l.material_override = lama
			l.position = Vector3(0, 0.026, -0.14)
			l.rotation.x = deg_to_rad(8)
			k.add_child(l)
			var punta := MeshInstance3D.new()
			var pm := PrismMesh.new()
			pm.size = Vector3(0.006, 0.034, 0.05)
			pm.left_to_right = 1.0
			punta.mesh = pm
			punta.material_override = lama
			punta.position = Vector3(0, 0.036, -0.245)
			punta.rotation = Vector3(deg_to_rad(8 - 90), 0, 0)
			k.add_child(punta)
	k.rotation.x = deg_to_rad(6)
	return k


## **'O kalash nun sta dint'ô pacchetto.** Si fa a pezzi: il castello di
## ferro, la canna, il calcio e il paramano di legno, il caricatore curvo.
## Sessanta centimetri di scatole — ma in mano, con la canna che punta
## avanti e il caricatore a banana, non lo confondi con niente.
func _costruisci_kalash() -> Node3D:
	var k := Node3D.new()
	var ferro := Tex.flat(Color(0.14, 0.14, 0.15), 0.45)
	var legno := Tex.flat(Color(0.45, 0.24, 0.10), 0.7)
	var pezzi := [
		# [dimensioni, posizione, materiale, rotazione x in gradi]
		[Vector3(0.055, 0.075, 0.30), Vector3(0, 0.07, -0.14), ferro, 0.0],
		[Vector3(0.022, 0.022, 0.40), Vector3(0, 0.08, -0.50), ferro, 0.0],
		[Vector3(0.05, 0.05, 0.19), Vector3(0, 0.07, -0.37), legno, 0.0],
		[Vector3(0.045, 0.07, 0.26), Vector3(0, 0.03, 0.14), legno, -8.0],
		[Vector3(0.035, 0.09, 0.05), Vector3(0, -0.01, -0.02), legno, 18.0],
		[Vector3(0.035, 0.12, 0.05), Vector3(0, -0.02, -0.16), ferro, 14.0],
		[Vector3(0.035, 0.08, 0.05), Vector3(0, -0.11, -0.19), ferro, 34.0],
		[Vector3(0.012, 0.04, 0.012), Vector3(0, 0.12, -0.64), ferro, 0.0],
	]
	for p in pezzi:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = p[0]
		mi.mesh = bm
		mi.position = p[1]
		mi.material_override = p[2]
		mi.rotation.x = deg_to_rad(float(p[3]))
		k.add_child(mi)
	return k


# ---------------------------------------------------------------------------
# 'O colpo
# ---------------------------------------------------------------------------

## Il colpo parte. Lo chiama `player_fps._throw_punch`.
func colpo() -> void:
	if not ARMI.has(_id):
		return
	_colpo = str(ARMI[_id]["colpo"])
	_t_colpo = 0.0
	if _colpo == "sparo" or _colpo == "raffica":
		_vampata.visible = true
		_vampata.rotation.z = randf() * TAU
		_vampata.scale = Vector3.ONE * (1.6 if _colpo == "raffica" else 1.0)
		_luce.light_energy = 4.0 if _colpo == "raffica" else 2.6


## Dove sta la bocca della canna nel mondo: da lì parte la scia.
func bocca_nel_mondo() -> Vector3:
	return _bocca.global_position


## Quanto dura ogni colpo, in secondi.
const DURATE := {"fendente": 0.46, "stoccata": 0.34, "sparo": 0.22,
	"raffica": 0.26}


func _process(delta: float) -> void:
	if not visible:
		return
	_rig.visible = not nascosta
	_respiro += delta
	if _moto > 0.05:
		_passo += delta * (6.2 + 3.0 * maxf(0.0, _moto - 1.0))
	var ondeggia := Vector3(
		sin(_passo) * 0.012 * _moto,
		-absf(cos(_passo)) * 0.014 * _moto + sin(_respiro * 1.6) * 0.004,
		0.0)
	var pos: Vector3 = RIPOSO + ondeggia
	var rot := Vector3.ZERO

	# Il cambio d'arma: scende sotto all'inquadratura e risale.
	if _t_cambio >= 0.0:
		_t_cambio += delta
		var k: float = clampf(_t_cambio / 0.28, 0.0, 1.0)
		var giu: float = 1.0 - _liscio(k)
		pos.y -= 0.12 * giu
		rot.x -= deg_to_rad(22.0) * giu
		if k >= 1.0:
			_t_cambio = -1.0

	if _t_colpo >= 0.0:
		_t_colpo += delta
		var durata: float = float(DURATE.get(_colpo, 0.4))
		var k2: float = clampf(_t_colpo / durata, 0.0, 1.0)
		var o: Array = _posa_colpo(_colpo, k2)
		pos += o[0]
		rot += o[1]
		if _t_colpo > 0.075:
			_vampata.visible = false
		_luce.light_energy = maxf(0.0, _luce.light_energy - delta * 40.0)
		if k2 >= 1.0:
			_t_colpo = -1.0
			_vampata.visible = false
			_luce.light_energy = 0.0
	_rig.position = pos + SPALLA
	_rig.rotation = rot


func _liscio(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)


## La posa del colpo al punto `k` (0 → 1): [spostamento, rotazione].
##
## Le rotazioni sono **attorno alla spalla**: +X alza la mano, +Y la porta
## a sinistra, +Z la inclina verso sinistra.
func _posa_colpo(tipo: String, k: float) -> Array:
	match tipo:
		"fendente":
			# Carica in alto a destra, cala in basso a sinistra, torna.
			# Pose trovate cercando dove finiscono mano e punta sullo
			# schermo (carica: mano a destra, punta in alto; botta: mano in
			# basso a sinistra, punta più in là): a occhio, la prima volta,
			# la botta usciva tutta sotto all'inquadratura.
			var carica := [Vector3(-0.05, 0.0, -0.05),
				Vector3(deg_to_rad(26), deg_to_rad(-30), deg_to_rad(14))]
			var botta := [Vector3(-0.05, 0.0, -0.05),
				Vector3(deg_to_rad(-6), deg_to_rad(38), deg_to_rad(-10))]
			if k < 0.30:
				var a: float = _liscio(k / 0.30)
				return [carica[0] * a, carica[1] * a]
			elif k < 0.52:
				var b: float = _liscio((k - 0.30) / 0.22)
				return [carica[0].lerp(botta[0], b), carica[1].lerp(botta[1], b)]
			else:
				var c: float = _liscio((k - 0.52) / 0.48)
				return [botta[0].lerp(Vector3.ZERO, c), botta[1].lerp(Vector3.ZERO, c)]
		"stoccata":
			var tira := [Vector3(0.0, -0.01, 0.05),
				Vector3(0, deg_to_rad(-4), 0)]
			var dentro := [Vector3(-0.06, 0.02, -0.15),
				Vector3(deg_to_rad(2), deg_to_rad(14), deg_to_rad(-4))]
			if k < 0.22:
				var a2: float = _liscio(k / 0.22)
				return [tira[0] * a2, tira[1] * a2]
			elif k < 0.45:
				var b2: float = _liscio((k - 0.22) / 0.23)
				return [tira[0].lerp(dentro[0], b2), tira[1].lerp(dentro[1], b2)]
			else:
				var c2: float = _liscio((k - 0.45) / 0.55)
				return [dentro[0].lerp(Vector3.ZERO, c2), dentro[1].lerp(Vector3.ZERO, c2)]
		"sparo", "raffica":
			# Il rinculo: un colpo secco indietro e in su, poi torna piano.
			var forza: float = 1.5 if tipo == "raffica" else 1.0
			var s2: float = (k / 0.12) if k < 0.12 else (1.0 - _liscio((k - 0.12) / 0.88))
			return [Vector3(0.0, 0.01, 0.07) * s2 * forza,
				Vector3(deg_to_rad(7), 0, deg_to_rad(-2)) * s2 * forza]
	return [Vector3.ZERO, Vector3.ZERO]


## Quanto ti stai movendo: 0 fermo, 1 a passo, di più di corsa.
func moto(quanto: float) -> void:
	_moto = lerpf(_moto, clampf(quanto, 0.0, 2.0), 0.2)


# ---------------------------------------------------------------------------
# 'A scia d''a botta
# ---------------------------------------------------------------------------

## Una riga gialla dalla bocca al punto colpito, che si spegne in un
## decimo di secondo, e una sbuffata di scintille dove arriva. Senza
## questa, sparare a sedici metri e mancare era identico a colpire.
static func scia(dove: Node, da: Vector3, a: Vector3, colpito: bool) -> void:
	var lung: float = da.distance_to(a)
	if lung < 0.2 or dove == null:
		return
	var riga := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.018, 0.018, lung)
	riga.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(1.0, 0.85, 0.45, 0.85)
	riga.material_override = mat
	riga.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dove.add_child(riga)
	riga.global_position = (da + a) * 0.5
	riga.look_at_from_position(riga.global_position, a, Vector3.UP
		if absf((a - da).normalized().y) < 0.98 else Vector3.RIGHT)
	var tw := riga.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.12)
	tw.tween_callback(riga.queue_free)

	var sc := CPUParticles3D.new()
	sc.one_shot = true
	sc.amount = 14 if colpito else 8
	sc.lifetime = 0.35
	sc.explosiveness = 1.0
	sc.spread = 70.0
	sc.direction = (da - a).normalized()
	sc.initial_velocity_min = 1.5
	sc.initial_velocity_max = 4.0
	sc.gravity = Vector3(0, -9.0, 0)
	var pm := SphereMesh.new()
	pm.radius = 0.015
	pm.height = 0.03
	var pmat := StandardMaterial3D.new()
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.albedo_color = Color(0.75, 0.1, 0.08) if colpito \
		else Color(1.0, 0.8, 0.4)
	pm.material = pmat
	sc.mesh = pm
	dove.add_child(sc)
	sc.global_position = a
	sc.emitting = true
	var tw2 := sc.create_tween()
	tw2.tween_interval(0.6)
	tw2.tween_callback(sc.queue_free)
