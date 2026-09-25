extends Node3D
## Cat3D
## Il gatto randagio del quartiere: ogni tanto attraversa il largo con la
## calma di chi è il vero padrone della zona. Solo scena, nessuna collisione.

var _speed: float = 2.6
var _target_x: float = 0.0
var _walk_phase: float = 0.0
var _legs: Array = []
var _tail: MeshInstance3D


## `origine` e' l'angolo della piazza nel mondo. Quando la piazza sta dentro
## alla citta' i suoi punti locali non coincidono piu' con quelli globali, e
## senza questo il gatto nasceva quattordici metri piu' in la', dentro a un
## palazzo.
func setup(zone_width: float, z: float, origine: Vector3 = Vector3.ZERO) -> void:
	var from_left := randf() < 0.5
	global_position = origine + Vector3(
		-0.8 if from_left else zone_width + 0.8, 0.0, z)
	_target_x = origine.x + (zone_width + 1.2 if from_left else -1.2)
	rotation.y = (PI / 2.0) if from_left else (-PI / 2.0) # forward = (−sinθ,0,−cosθ)
	_build_visual()
	SoundManager.play("meow", -6.0, randf_range(0.9, 1.15))


func _build_visual() -> void:
	var fur := StandardMaterial3D.new()
	var shade := randf_range(0.0, 1.0)
	if shade < 0.4:
		fur.albedo_color = Color(0.1, 0.1, 0.1) # nero, ovviamente
	elif shade < 0.7:
		fur.albedo_color = Color(0.75, 0.5, 0.25) # rosso
	else:
		fur.albedo_color = Color(0.6, 0.6, 0.62) # grigio

	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.16, 0.16, 0.42)
	body.mesh = body_mesh
	body.position = Vector3(0, 0.22, 0)
	body.material_override = fur
	add_child(body)

	var head := MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.14, 0.13, 0.14)
	head.mesh = head_mesh
	head.position = Vector3(0, 0.32, -0.26)
	head.material_override = fur
	add_child(head)

	for ex in [-0.045, 0.045]:
		var ear := MeshInstance3D.new()
		var ear_mesh := PrismMesh.new()
		ear_mesh.size = Vector3(0.05, 0.06, 0.03)
		ear.mesh = ear_mesh
		ear.position = Vector3(ex, 0.42, -0.26)
		ear.material_override = fur
		add_child(ear)

	_tail = MeshInstance3D.new()
	var tail_mesh := BoxMesh.new()
	tail_mesh.size = Vector3(0.04, 0.3, 0.04)
	_tail.mesh = tail_mesh
	_tail.position = Vector3(0, 0.38, 0.24)
	_tail.rotation.x = 0.4
	_tail.material_override = fur
	add_child(_tail)

	for lz in [-0.15, 0.15]:
		for lx in [-0.06, 0.06]:
			var leg := MeshInstance3D.new()
			var leg_mesh := BoxMesh.new()
			leg_mesh.size = Vector3(0.045, 0.16, 0.045)
			leg.mesh = leg_mesh
			leg.position = Vector3(lx, 0.08, lz)
			leg.material_override = fur
			add_child(leg)
			_legs.append(leg)


func _physics_process(delta: float) -> void:
	if _tail == null: # setup() non ancora chiamato
		return
	var step: float = _speed * delta
	global_position.x = move_toward(global_position.x, _target_x, step)
	_walk_phase += step * 14.0
	for i in _legs.size():
		_legs[i].rotation.x = sin(_walk_phase + (PI if i % 2 == 0 else 0.0)) * 0.6
	_tail.rotation.x = 0.4 + sin(_walk_phase * 0.35) * 0.25
	if absf(global_position.x - _target_x) < 0.05:
		queue_free()
