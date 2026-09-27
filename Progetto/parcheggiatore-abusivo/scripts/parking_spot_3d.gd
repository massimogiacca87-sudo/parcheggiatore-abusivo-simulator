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

## **'E strisce blu** (0.64): il Comune ha pittato questo posto. Vedi
## `strisce_blu.gd` e `GameManager` («'E STRISCE BLU»). Si ripittano di
## bianco col pennello: [E] fermo accanto, `GameManager.PITTURA_TEMPO`.
var blu: bool = false
var _pittanno: float = -1.0
var _scritta_pittura: Label3D = null

const BIANCO := Color(0.9, 0.9, 0.85)
const BLU := Color(0.12, 0.36, 0.86)

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


## Blu o bianco. Nel gruppo `strisce_blu` finché è blu: è quello che il
## mirino del giocatore aggancia per pittarlo (vedi GRUPPI_BERSAGLIO).
func metti_blu(b: bool) -> void:
	blu = b
	if b:
		add_to_group("strisce_blu")
	elif is_in_group("strisce_blu"):
		remove_from_group("strisce_blu")
	_pittanno = -1.0
	if _scritta_pittura:
		_scritta_pittura.visible = false
	_update_visual()


func get_interact_prompt(_da: Vector3) -> String:
	if not blu:
		return ""
	if not is_free:
		return "Striscia blu — cu 'na machina ncoppa nun se pitta"
	if _pittanno >= 0.0:
		return "Staje pittanno 'e janco… %d%%" % int(100.0 * _pittanno / GameManager.PITTURA_TEMPO)
	if GameManager.pittura <= 0:
		return "Striscia blu d''o Comune — ce vò 'a pittura janca c''o pennello (Bazar, €%d)" \
			% GameManager.PITTURA_COSTO
	return "Striscia blu — [E] pittala 'e janco (%d passat%s 'n sacca)" % [
		GameManager.pittura, "a" if GameManager.pittura == 1 else "e"]


func player_interact() -> void:
	if not blu or _pittanno >= 0.0 or not is_free:
		return
	if GameManager.pittura <= 0:
		SoundManager.play("fail", -10.0, 0.9)
		GameManager.event_started.emit(
			"Senza pittura janca nun se fa niente: 'o Bazar tene 'o barattolo c''o pennello.")
		return
	_pittanno = 0.0
	SoundManager.play("pennellata", -4.0)
	if _scritta_pittura == null:
		_scritta_pittura = Label3D.new()
		_scritta_pittura.position = Vector3(0, 1.1, 0)
		_scritta_pittura.font_size = 40
		_scritta_pittura.pixel_size = 0.004
		_scritta_pittura.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_scritta_pittura.outline_size = 12
		_scritta_pittura.modulate = Color(1, 1, 1)
		add_child(_scritta_pittura)
	_scritta_pittura.visible = true


func _pitta(delta: float) -> void:
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	# Chi se ne va a metà lascia la striscia a metà: si ricomincia.
	if pl == null or pl.global_position.distance_to(global_position) > 3.6 \
			or not is_free:
		_pittanno = -1.0
		if _scritta_pittura:
			_scritta_pittura.visible = false
		_update_visual()
		return
	_pittanno += delta
	var k: float = clampf(_pittanno / GameManager.PITTURA_TEMPO, 0.0, 1.0)
	if _scritta_pittura:
		_scritta_pittura.text = "Pittanno… %d%%" % int(k * 100.0)
	_line_material.albedo_color = BLU.lerp(BIANCO, k)
	_line_material.emission = _line_material.albedo_color
	# 'O pennello se sente: una passata ogni tre quarti di secondo.
	if int(_pittanno / 0.75) != int((_pittanno - delta) / 0.75):
		SoundManager.play("pennellata", -7.0, randf_range(0.92, 1.1))
	if _pittanno >= GameManager.PITTURA_TEMPO:
		if GameManager.pitta_posto(zona_id, indice):
			SoundManager.play("success", -6.0, 1.1)
			metti_blu(false)
		else:
			metti_blu(blu)


func _process(delta: float) -> void:
	if _pittanno >= 0.0:
		_pitta(delta)
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
	if is_in_group("strisce_blu"):
		remove_from_group("strisce_blu")
	blu = false


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
		var c: Color = BLU if blu else BIANCO
		_line_material.albedo_color = c
		_line_material.emission = c
		_fill_material.albedo_color = Color(0.2, 0.4, 1.0, 0.12) if blu \
			else Color(1, 1, 1, 0.06)
		_beacon.visible = false
	else:
		_line_material.albedo_color = Color(1.0, 0.7, 0.15)
		_line_material.emission = Color(1.0, 0.6, 0.1)
		_fill_material.albedo_color = Color(1.0, 0.7, 0.15, 0.12)
		_beacon_time = 0.0
