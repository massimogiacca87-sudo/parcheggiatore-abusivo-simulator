extends RefCounted
class_name RobbaCummissione
## **'A robba d''e cummissiune** (0.62): le cose che si portano.
##
## Il capo: *«Migliora le quest secondarie aggiungendo un personaggio che si
## avvicina e te la affida realisticamente (es. un portapizze che ti affida
## le pizze da consegnare perché a lui hanno rubato il motorino), gli
## oggetti del caso (esempio le pizze in caso di consegna pizze)»*.
##
## Ogni commissione ha la sua roba: le pizze nei cartoni, la busta della
## spesa, il pacco con lo scotch, la busta gialla, le chiavi col portachiavi,
## la torta col fiocco, il mazzo di fiori, il sacchetto della farmacia. La
## stessa funzione la costruisce in mano al committente, in mano al
## giocatore (in prima persona) e in mano a chi la riceve: misure vere, da
## tenere con due mani (35-45 cm la roba grossa, pochi centimetri le chiavi).
##
## I pezzi sono fatti di scatole e cilindri quando il pacchetto non ha il
## modello giusto (i cartoni della pizza, la torta, i fiori), e usano i
## modelli PSX quando c'è (la pizza dentro al cartone aperto, le chiavi, la
## busta della spesa, la medicina, il foglio).

const Tex := preload("res://scripts/textures.gd")
const Models := preload("res://scripts/models.gd")

## La roba di ogni tipo di commissione, col nome da dire.
const NOMI := {
	"pizze": "'e ppizze", "spesa": "'a spesa", "pacco": "'o pacco",
	"busta": "'a busta", "chiave": "'e cchiave", "torta": "'a torta",
	"sciure": "'e sciure", "medicina": "'a medicina",
}


static func costruisci(tipo: String) -> Node3D:
	var r := Node3D.new()
	r.name = "Robba_" + tipo
	match tipo:
		"pizze":
			_pizze(r)
		"spesa":
			_spesa(r)
		"pacco":
			_pacco(r)
		"busta":
			_busta(r)
		"chiave":
			_chiave(r)
		"torta":
			_torta(r)
		"sciure":
			_sciure(r)
		"medicina":
			_medicina(r)
		_:
			_pacco(r)
	return r


static func _scatola(dove: Node3D, dim: Vector3, pos: Vector3, col: Color,
		rough: float = 0.85) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = dim
	m.mesh = b
	m.position = pos
	m.material_override = Tex.flat(col, rough)
	dove.add_child(m)
	return m


static func _scritta(dove: Node3D, t: String, pos: Vector3, col: Color,
		px: float = 0.0016) -> void:
	var l := Label3D.new()
	l.text = t
	l.font_size = 64
	l.pixel_size = px
	l.modulate = col
	l.outline_size = 0
	l.position = pos
	l.rotation.x = -PI * 0.5
	l.double_sided = false
	dove.add_child(l)


## Due cartoni della pizza uno sopra all'altro, con la scritta.
static func _pizze(r: Node3D) -> void:
	var cart := Color(0.86, 0.80, 0.66)
	for i in range(2):
		var y: float = 0.025 + 0.052 * i
		_scatola(r, Vector3(0.34, 0.048, 0.34), Vector3(0, y, 0), cart)
		# Il bordino più scuro del coperchio.
		_scatola(r, Vector3(0.345, 0.006, 0.345), Vector3(0, y + 0.024, 0),
			cart.darkened(0.12))
	_scritta(r, "PIZZA", Vector3(0, 0.106, 0.02), Color(0.78, 0.12, 0.10))
	_scritta(r, "d''a Sanità", Vector3(0, 0.106, -0.07), Color(0.2, 0.35, 0.18), 0.0009)


static func _spesa(r: Node3D) -> void:
	var o := Models.spawn("sacchetto_2")
	if o != null:
		o.scale = Vector3.ONE * (0.42 / 0.525)
		r.add_child(o)
		# Due cose che spuntano: il pane e una bottiglia.
		var p := Models.spawn("pane")
		if p != null:
			p.position = Vector3(0.04, 0.34, 0.0)
			p.rotation = Vector3(0.0, 0.3, 1.2)
			r.add_child(p)
		return
	_scatola(r, Vector3(0.3, 0.36, 0.18), Vector3(0, 0.18, 0), Color(0.92, 0.9, 0.84))


static func _pacco(r: Node3D) -> void:
	var cart := Color(0.66, 0.50, 0.32)
	_scatola(r, Vector3(0.34, 0.24, 0.28), Vector3(0, 0.12, 0), cart)
	# Lo scotch a croce.
	_scatola(r, Vector3(0.345, 0.006, 0.06), Vector3(0, 0.243, 0), Color(0.78, 0.66, 0.44), 0.4)
	_scatola(r, Vector3(0.06, 0.006, 0.285), Vector3(0, 0.244, 0), Color(0.78, 0.66, 0.44), 0.4)
	_scritta(r, "FRAGILE", Vector3(0.0, 0.25, 0.09), Color(0.7, 0.1, 0.1), 0.0008)


static func _busta(r: Node3D) -> void:
	_scatola(r, Vector3(0.26, 0.012, 0.18), Vector3(0, 0.006, 0), Color(0.86, 0.72, 0.42))
	# La patta: un triangolo schiacciato più scuro.
	var patta := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(0.26, 0.09, 0.004)
	patta.mesh = pm
	patta.rotation.x = -PI * 0.5
	patta.position = Vector3(0, 0.0135, -0.045)
	patta.material_override = Tex.flat(Color(0.78, 0.64, 0.36), 0.8)
	r.add_child(patta)
	# 'O sigillo 'e cera lacca.
	var s := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.016
	cm.bottom_radius = 0.016
	cm.height = 0.006
	s.mesh = cm
	s.position = Vector3(0, 0.016, 0.0)
	s.material_override = Tex.flat(Color(0.62, 0.08, 0.08), 0.4)
	r.add_child(s)


static func _chiave(r: Node3D) -> void:
	# Il portachiavi: un anello e tre chiavi, più grandi del vero perché in
	# mano si devono vedere.
	var anello := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.022
	tm.outer_radius = 0.028
	anello.mesh = tm
	anello.material_override = Tex.flat(Color(0.75, 0.75, 0.78), 0.3, 0.8)
	r.add_child(anello)
	var i := 0
	for n in ["chiave", "chiave2", "chiave3"]:
		var o := Models.spawn(n)
		if o == null:
			continue
		o.scale = Vector3.ONE * 1.8
		o.position = Vector3(-0.03 + 0.03 * i, -0.01, 0.07)
		o.rotation.y = -0.3 + 0.3 * i
		r.add_child(o)
		i += 1
	# 'O targhino d''o garage.
	_scatola(r, Vector3(0.05, 0.006, 0.07), Vector3(0.06, 0.0, -0.05), Color(0.9, 0.78, 0.2))


static func _torta(r: Node3D) -> void:
	_scatola(r, Vector3(0.30, 0.16, 0.30), Vector3(0, 0.08, 0), Color(0.97, 0.96, 0.95), 0.6)
	var nastro := Color(0.92, 0.36, 0.56)
	_scatola(r, Vector3(0.305, 0.165, 0.035), Vector3(0, 0.08, 0), nastro, 0.4)
	_scatola(r, Vector3(0.035, 0.165, 0.305), Vector3(0, 0.08, 0), nastro, 0.4)
	# Il fiocco: due ali e un nodo.
	for lato in [-1.0, 1.0]:
		var ala := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.035
		sm.height = 0.03
		ala.mesh = sm
		ala.position = Vector3(lato * 0.03, 0.172, 0)
		ala.scale = Vector3(1.2, 0.8, 0.7)
		ala.material_override = Tex.flat(nastro, 0.4)
		r.add_child(ala)
	_scritta(r, "Pasticceria", Vector3(0, 0.162, 0.1), Color(0.55, 0.2, 0.3), 0.0008)


static func _sciure(r: Node3D) -> void:
	# La carta a cono.
	var cono := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.10
	cm.bottom_radius = 0.02
	cm.height = 0.32
	cm.radial_segments = 10
	cono.mesh = cm
	cono.position = Vector3(0, 0.16, 0)
	var carta := Tex.flat(Color(0.96, 0.94, 0.86), 0.7)
	carta.cull_mode = BaseMaterial3D.CULL_DISABLED
	cono.material_override = carta
	r.add_child(cono)
	# Le foglie e i fiori.
	var colori := [Color(0.9, 0.12, 0.18), Color(0.98, 0.84, 0.2),
		Color(0.94, 0.4, 0.62), Color(0.9, 0.12, 0.18), Color(0.98, 0.98, 0.96),
		Color(0.94, 0.4, 0.62), Color(0.9, 0.12, 0.18)]
	for k in range(colori.size()):
		var a: float = TAU * float(k) / 6.0
		var rr: float = 0.0 if k == 6 else 0.055
		var f := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.04
		sm.height = 0.07
		sm.radial_segments = 8
		sm.rings = 4
		f.mesh = sm
		f.position = Vector3(cos(a) * rr, 0.33 + (0.02 if k == 6 else 0.0), sin(a) * rr)
		f.material_override = Tex.flat(colori[k], 0.6)
		r.add_child(f)
	for k in range(4):
		var a2: float = TAU * float(k) / 4.0 + 0.4
		_scatola(r, Vector3(0.02, 0.1, 0.06), Vector3(cos(a2) * 0.09, 0.29,
			sin(a2) * 0.09), Color(0.2, 0.5, 0.2), 0.8).rotation = Vector3(0.4, a2, 0.0)


static func _medicina(r: Node3D) -> void:
	# 'O sacchetto bianco d''a farmacia cu 'a croce verde.
	_scatola(r, Vector3(0.18, 0.24, 0.09), Vector3(0, 0.12, 0), Color(0.97, 0.97, 0.97), 0.7)
	_scatola(r, Vector3(0.06, 0.02, 0.092), Vector3(0, 0.15, 0), Color(0.1, 0.62, 0.3), 0.6)
	_scatola(r, Vector3(0.02, 0.06, 0.092), Vector3(0, 0.15, 0), Color(0.1, 0.62, 0.3), 0.6)
	var o := Models.spawn("medicine")
	if o != null:
		o.position = Vector3(0.0, 0.24, 0.0)
		r.add_child(o)
