extends Node
class_name AutoVarie
## AutoVarie
## Altri mezzi, costruiti a scatole invece che presi da un modello.
##
## I tre modelli 3D che ci sono (utilitaria, berlina, lusso) sono tutti
## automobili normali, e in una strada di Napoli fatta solo di automobili
## normali manca metà del traffico: manca il furgone del corriere in doppia
## fila, manca l'Ape del fruttivendolo, manca il taxi bianco.
##
## Sono volutamente semplici — servono da arredo, non ci si sale — ma le
## proporzioni sono quelle giuste, ed è la sagoma che si riconosce da
## lontano, non il numero di poligoni.

const Tex := preload("res://scripts/textures.gd")

enum Tipo { FURGONE, APE, TAXI, STATION, MICRO }

const NOMI := ["furgone", "ape", "taxi", "station", "micro"]


static func costruisci(tipo: int, tinta: Color) -> Node3D:
	match tipo:
		Tipo.FURGONE: return _furgone(tinta)
		Tipo.APE: return _ape(tinta)
		Tipo.TAXI: return _taxi()
		Tipo.STATION: return _station(tinta)
		_: return _micro(tinta)


static func a_caso() -> Node3D:
	var tinte := [
		Color(0.72, 0.7, 0.66), Color(0.6, 0.16, 0.14), Color(0.16, 0.24, 0.4),
		Color(0.22, 0.36, 0.24), Color(0.5, 0.46, 0.16), Color(0.2, 0.2, 0.22),
		Color(0.78, 0.5, 0.15),
	]
	return costruisci(randi() % NOMI.size(), tinte[randi() % tinte.size()])


# ---------------------------------------------------------------------------

static func _corpo(padre: Node3D, dim: Vector3, pos: Vector3,
		mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = dim
	m.mesh = bm
	m.position = pos
	m.material_override = mat
	padre.add_child(m)
	return m


static func _ruote(padre: Node3D, passo: float, larghezza: float,
		raggio: float) -> void:
	var gomma := Tex.flat(Color(0.07, 0.07, 0.08), 0.95)
	var cerchio := Tex.flat(Color(0.72, 0.72, 0.75), 0.3, 0.8)
	for dz in [-passo / 2.0, passo / 2.0]:
		for dx in [-larghezza / 2.0, larghezza / 2.0]:
			var r := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = raggio
			cm.bottom_radius = raggio
			cm.height = 0.18
			cm.radial_segments = 12
			r.mesh = cm
			r.rotation.z = deg_to_rad(90)
			r.position = Vector3(dx, raggio, dz)
			r.material_override = gomma
			padre.add_child(r)
			var c := MeshInstance3D.new()
			var cm2 := CylinderMesh.new()
			cm2.top_radius = raggio * 0.55
			cm2.bottom_radius = raggio * 0.55
			cm2.height = 0.2
			cm2.radial_segments = 10
			c.mesh = cm2
			c.rotation.z = deg_to_rad(90)
			c.position = Vector3(dx * 1.04, raggio, dz)
			c.material_override = cerchio
			padre.add_child(c)


static func _vetri() -> StandardMaterial3D:
	return Tex.flat(Color(0.08, 0.11, 0.15), 0.08, 0.85)


static func _fari(padre: Node3D, avanti: float, larghezza: float,
		h: float) -> void:
	var bianco := Tex.flat(Color(1.0, 0.96, 0.85), 0.2, 0.0, 1.1)
	var rosso := Tex.flat(Color(0.9, 0.16, 0.12), 0.3, 0.0, 0.8)
	for dx in [-larghezza / 2.0 + 0.16, larghezza / 2.0 - 0.16]:
		_corpo(padre, Vector3(0.26, 0.14, 0.08),
			Vector3(dx, h, -avanti / 2.0 - 0.02), bianco)
		_corpo(padre, Vector3(0.26, 0.14, 0.08),
			Vector3(dx, h, avanti / 2.0 + 0.02), rosso)


## Il furgone del corriere: alto, squadrato, sempre in doppia fila.
static func _furgone(tinta: Color) -> Node3D:
	var n := Node3D.new()
	var mat := Tex.flat(tinta, 0.45, 0.3)
	_corpo(n, Vector3(1.9, 1.5, 4.6), Vector3(0, 1.28, 0), mat)
	_corpo(n, Vector3(1.85, 0.75, 1.5), Vector3(0, 2.2, -1.5), mat)
	_corpo(n, Vector3(1.72, 0.62, 0.1), Vector3(0, 2.2, -2.24), _vetri())
	for dx in [-0.94, 0.94]:
		_corpo(n, Vector3(0.06, 0.55, 1.0), Vector3(dx, 2.16, -1.5), _vetri())
	# Le porte dietro, con la maniglia.
	_corpo(n, Vector3(0.05, 1.2, 0.05), Vector3(0, 1.3, 2.32),
		Tex.flat(Color(0.2, 0.2, 0.2), 0.5, 0.5))
	_ruote(n, 3.0, 1.86, 0.34)
	_fari(n, 4.6, 1.9, 1.0)
	return n


## L'Ape: tre ruote, cassone, e occupa un metro e mezzo di strada.
static func _ape(tinta: Color) -> Node3D:
	var n := Node3D.new()
	var mat := Tex.flat(tinta, 0.5, 0.25)
	# La cabina tonda davanti.
	var cab := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.62
	sm.height = 1.5
	sm.radial_segments = 12
	sm.rings = 8
	cab.mesh = sm
	cab.position = Vector3(0, 1.0, -0.9)
	cab.material_override = mat
	n.add_child(cab)
	_corpo(n, Vector3(1.0, 0.5, 0.08), Vector3(0, 1.2, -1.42), _vetri())
	# Il cassone dietro.
	_corpo(n, Vector3(1.25, 0.62, 1.7), Vector3(0, 0.78, 0.55), mat)
	_corpo(n, Vector3(1.3, 0.1, 1.75), Vector3(0, 1.1, 0.55),
		Tex.flat(tinta.darkened(0.3), 0.6))
	# Le cassette della frutta sopra.
	for i in range(3):
		_corpo(n, Vector3(0.5, 0.28, 0.4),
			Vector3(-0.3 + i * 0.32, 1.28, 0.2 + (i % 2) * 0.5),
			Tex.flat(Color(0.55, 0.4, 0.24), 0.92))
	# Una ruota davanti, due dietro.
	var gomma := Tex.flat(Color(0.07, 0.07, 0.08), 0.95)
	var davanti := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.26
	cm.bottom_radius = 0.26
	cm.height = 0.16
	cm.radial_segments = 10
	davanti.mesh = cm
	davanti.rotation.z = deg_to_rad(90)
	davanti.position = Vector3(0, 0.26, -1.35)
	davanti.material_override = gomma
	n.add_child(davanti)
	for dx in [-0.58, 0.58]:
		var r := MeshInstance3D.new()
		var cm2 := CylinderMesh.new()
		cm2.top_radius = 0.26
		cm2.bottom_radius = 0.26
		cm2.height = 0.16
		cm2.radial_segments = 10
		r.mesh = cm2
		r.rotation.z = deg_to_rad(90)
		r.position = Vector3(dx, 0.26, 0.75)
		r.material_override = gomma
		n.add_child(r)
	return n


## Il taxi: bianco, con la fascia e il cartello sul tetto.
##
## **Dalla 0.59 è quello del Car Pack**, verniciato di bianco: i taxi di
## Napoli sono bianchi, quello del pacchetto è giallo come a New York. Il
## cartello sul tetto nel file è della stessa tinta della carrozzeria, e
## col bianco sparirebbe: sopra ci va la scatola gialla di prima, con la
## scritta davanti e dietro. Se il modello non c'è, resta quello a scatole.
static func _taxi() -> Node3D:
	var modello := Models.spawn_by_length("car_taxi")
	if modello != null:
		Models.polish_vehicle(modello)
		Models.tint(modello, ["body"], Color(0.93, 0.93, 0.91), 0.3, 0.35)
		var t := Node3D.new()
		t.add_child(modello)
		insegna_taxi(t)
		return t
	var n := _berlina(Color(0.93, 0.93, 0.91))
	_corpo(n, Vector3(0.7, 0.26, 0.3), Vector3(0, 1.52, -0.2),
		Tex.flat(Color(0.95, 0.85, 0.2), 0.4, 0.0, 0.7))
	# La fascia laterale.
	for dx in [-0.88, 0.88]:
		_corpo(n, Vector3(0.03, 0.14, 3.2), Vector3(dx, 0.78, 0.1),
			Tex.flat(Color(0.9, 0.7, 0.1), 0.6))
	return n


## La scatola gialla col TAXI sopra al cartello del modello (che nel file
## è della tinta della carrozzeria e col bianco sparirebbe). Serve pure al
## taxi di Peppe, che è una macchina vera e non arredo (`car_3d.gd`).
static func insegna_taxi(padre: Node3D) -> void:
	_corpo(padre, Vector3(0.79, 0.15, 0.38), Vector3(0, 1.245, 0.085),
		Tex.flat(Color(0.95, 0.85, 0.2), 0.4, 0.0, 0.7))
	for dz in [-1.0, 1.0]:
		var scritta := Label3D.new()
		scritta.text = "TAXI"
		scritta.font_size = 30
		scritta.pixel_size = 0.004
		scritta.modulate = Color(0.08, 0.08, 0.1)
		scritta.outline_size = 0
		scritta.position = Vector3(0, 1.245, 0.085 + dz * 0.195)
		scritta.rotation.y = 0.0 if dz > 0.0 else PI
		padre.add_child(scritta)


static func _station(tinta: Color) -> Node3D:
	var n := _berlina(tinta)
	# Il baule allungato, che è quello che la fa station wagon.
	_corpo(n, Vector3(1.72, 0.62, 1.5), Vector3(0, 1.36, 1.2),
		Tex.flat(tinta, 0.4, 0.35))
	_corpo(n, Vector3(1.6, 0.5, 0.08), Vector3(0, 1.36, 1.95), _vetri())
	# Le barre portapacchi.
	for dx in [-0.6, 0.6]:
		_corpo(n, Vector3(0.07, 0.07, 1.9), Vector3(dx, 1.72, 0.9),
			Tex.flat(Color(0.25, 0.25, 0.27), 0.5, 0.5))
	return n


static func _micro(tinta: Color) -> Node3D:
	var n := Node3D.new()
	var mat := Tex.flat(tinta, 0.35, 0.4)
	_corpo(n, Vector3(1.52, 0.78, 2.5), Vector3(0, 0.68, 0), mat)
	_corpo(n, Vector3(1.42, 0.6, 1.6), Vector3(0, 1.3, -0.1), mat)
	_corpo(n, Vector3(1.3, 0.48, 0.08), Vector3(0, 1.3, -0.92), _vetri())
	_corpo(n, Vector3(1.3, 0.44, 0.08), Vector3(0, 1.3, 0.72), _vetri())
	for dx in [-0.72, 0.72]:
		_corpo(n, Vector3(0.06, 0.42, 1.3), Vector3(dx, 1.28, -0.1), _vetri())
	_ruote(n, 1.8, 1.5, 0.28)
	_fari(n, 2.5, 1.52, 0.72)
	return n


## Il corpo base condiviso da taxi e station wagon.
static func _berlina(tinta: Color) -> Node3D:
	var n := Node3D.new()
	var mat := Tex.flat(tinta, 0.35, 0.4)
	_corpo(n, Vector3(1.78, 0.62, 4.1), Vector3(0, 0.66, 0), mat)
	_corpo(n, Vector3(1.72, 0.34, 3.9), Vector3(0, 1.02, 0), mat)
	_corpo(n, Vector3(1.6, 0.58, 2.0), Vector3(0, 1.42, -0.2), mat)
	_corpo(n, Vector3(1.48, 0.46, 0.09), Vector3(0, 1.42, -1.14), _vetri())
	_corpo(n, Vector3(1.48, 0.44, 0.09), Vector3(0, 1.42, 0.78), _vetri())
	for dx in [-0.81, 0.81]:
		_corpo(n, Vector3(0.06, 0.4, 1.7), Vector3(dx, 1.4, -0.2), _vetri())
	# Paraurti e targa.
	for dz in [-2.06, 2.06]:
		_corpo(n, Vector3(1.8, 0.24, 0.12), Vector3(0, 0.5, dz),
			Tex.flat(Color(0.22, 0.22, 0.24), 0.7))
	_corpo(n, Vector3(0.5, 0.12, 0.04), Vector3(0, 0.5, 2.14),
		Tex.flat(Color(0.9, 0.9, 0.88), 0.6))
	_ruote(n, 2.5, 1.74, 0.32)
	_fari(n, 4.1, 1.78, 0.72)
	return n
