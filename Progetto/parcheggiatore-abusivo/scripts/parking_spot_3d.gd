extends Node3D
## ParkingSpot3D
## Un posto auto con le strisce dipinte a terra (rettangolo bianco quando è
## libero, arancione quando è assegnato/occupato) e un segnale luminoso
## fluttuante che appare sopra il posto durante la regia, così è sempre
## chiaro a colpo d'occhio dove bisogna portare l'auto.

signal state_changed(is_free: bool)

const SPOT_W := 2.2
const SPOT_L := 4.4
const LINE_W := 0.09

var is_free: bool = true
var occupying_car: Node = null
## Di che piazza è, e che numero ha dentro alla piazza (0.64): le strisce
## blu si ricordano posto per posto quali hai già ripittato.
var zona_id: String = ""
var indice: int = -1
## Spento a città finita perché murato (una bancarella, un banco): non si
## disegna e non si assegna (0.64, vedi `posteggio_3d._spegni_posti_murati`).
var spento: bool = false

var _line_material: StandardMaterial3D
var _fill: MeshInstance3D
var _fill_material: StandardMaterial3D
var _beacon: MeshInstance3D
var _beacon_time: float = 0.0


func _ready() -> void:
	add_to_group("parking_spots")
	_build_visual()
	_update_visual()


func _build_visual() -> void:
	_line_material = StandardMaterial3D.new()
	_line_material.albedo_color = Color(0.9, 0.9, 0.85)
	_line_material.emission_enabled = true
	_line_material.emission = Color(0.9, 0.9, 0.85)
	_line_material.emission_energy_multiplier = 0.15

	# Rettangolo di strisce: due lunghe (asse Z) e due corte (asse X).
	for lx in [-SPOT_W / 2.0, SPOT_W / 2.0]:
		var line := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(LINE_W, 0.015, SPOT_L)
		line.mesh = mesh
		line.position = Vector3(lx, 0.02, 0)
		line.material_override = _line_material
		add_child(line)
	for lz in [-SPOT_L / 2.0, SPOT_L / 2.0]:
		var line := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(SPOT_W, 0.015, LINE_W)
		line.mesh = mesh
		line.position = Vector3(0, 0.02, lz)
		line.material_override = _line_material
		add_child(line)

	# Riempimento tenue, per leggere lo stato anche da lontano.
	_fill = MeshInstance3D.new()
	var fill_mesh := PlaneMesh.new()
	fill_mesh.size = Vector2(SPOT_W - 0.2, SPOT_L - 0.2)
	_fill.mesh = fill_mesh
	_fill.position = Vector3(0, 0.012, 0)
	_fill_material = StandardMaterial3D.new()
	_fill_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_fill_material.albedo_color = Color(1, 1, 1, 0.06)
	_fill.material_override = _fill_material
	add_child(_fill)

	# Segnale fluttuante: visibile solo quando il posto è assegnato.
	_beacon = MeshInstance3D.new()
	var beacon_mesh := PrismMesh.new()
	beacon_mesh.size = Vector3(0.5, 0.5, 0.5)
	_beacon.mesh = beacon_mesh
	_beacon.rotation.x = PI # punta verso il basso
	_beacon.position = Vector3(0, 2.4, 0)
	var beacon_mat := StandardMaterial3D.new()
	beacon_mat.albedo_color = Color(1.0, 0.75, 0.1)
	beacon_mat.emission_enabled = true
	beacon_mat.emission = Color(1.0, 0.7, 0.1)
	beacon_mat.emission_energy_multiplier = 1.8
	_beacon.material_override = beacon_mat
	_beacon.visible = false
	add_child(_beacon)


func _process(delta: float) -> void:
	# Il segnale si vede solo mentre l'auto assegnata è in regia: a manovra
	# finita (auto parcheggiata) sparisce.
	var should_show: bool = (
		not is_free
		and occupying_car != null
		and is_instance_valid(occupying_car)
		and occupying_car.has_method("is_being_directed")
		and occupying_car.is_being_directed()
	)
	_beacon.visible = should_show
	if should_show:
		_beacon_time += delta
		_beacon.position.y = 2.4 + sin(_beacon_time * 3.0) * 0.18
		_beacon.rotation.y += delta * 2.2


## Il posto sta sotto a qualcosa (0.64): non si disegna e non si dà a
## nessuno. Esce dal gruppo, così chi cerca un posto libero non lo vede.
func spegni() -> void:
	spento = true
	is_free = false
	occupying_car = null
	visible = false
	remove_from_group("parking_spots")


func reserve(car: Node) -> void:
	is_free = false
	occupying_car = car
	_update_visual()
	state_changed.emit(is_free)


func free_spot() -> void:
	is_free = true
	occupying_car = null
	_update_visual()
	state_changed.emit(is_free)


func _update_visual() -> void:
	if _line_material == null:
		return
	if is_free:
		_line_material.albedo_color = Color(0.9, 0.9, 0.85)
		_line_material.emission = Color(0.9, 0.9, 0.85)
		_fill_material.albedo_color = Color(1, 1, 1, 0.06)
		_beacon.visible = false
	else:
		_line_material.albedo_color = Color(1.0, 0.7, 0.15)
		_line_material.emission = Color(1.0, 0.6, 0.1)
		_fill_material.albedo_color = Color(1.0, 0.7, 0.15, 0.12)
		_beacon_time = 0.0
