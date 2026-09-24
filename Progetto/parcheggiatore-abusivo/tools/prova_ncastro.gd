extends Node
## **Nun se resta 'ncastrate** (0.62).
##
## Il capo: *«Fai in modo che il giocatore sempre e comunque possa saltare e
## arrampicarsi su ostacoli. Questo per evitare che si blocchi o si incastri
## tra auto, oggetti ecc.»*
##
## Quattro scene, tutte nel largo davanti a casa, con macchine vere:
##   A. davanti a un cofano, SPAZIO → sopra al cofano;
##   B. voltato di spalle ma camminando verso l'auto, SPAZIO → sopra;
##   C. dentro a due macchine che si toccano (nato incastrato), SPAZIO →
##      fuori, in un posto libero;
##   D. dentro, senza toccare niente ma spingendo avanti → dopo tre secondi
##      fuori da solo.

const CarScript := preload("res://scripts/car_3d.gd")

var storte: int = 0
var _pl: CharacterBody3D


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(90):
		await get_tree().process_frame
	get_tree().paused = false
	GameManager.intro_active = false
	_pl = get_tree().get_first_node_in_group("player") as CharacterBody3D

	await _scena_a()
	await _scena_b()
	await _scena_c()
	await _scena_d()
	print("=== storte: %d ===" % storte)
	get_tree().quit()


func _machina(p: Vector3, giro: float) -> Node3D:
	var c: Node3D = CarScript.new()
	get_tree().root.add_child(c)
	c.set("car_type", "berlina")
	c.set("state", CarScript.State.PARKED)
	c.global_position = p
	c.rotation.y = giro
	return c


func _metti(p: Vector3, giro: float) -> void:
	_pl.global_position = p
	_pl.rotation.y = giro
	_pl.velocity = Vector3.ZERO
	for _i in range(10):
		await get_tree().physics_frame


func _premi(azione: String) -> void:
	Input.action_press(azione)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(azione)


func _aspetta(frame: int) -> void:
	for _i in range(frame):
		await get_tree().physics_frame


const P := Vector3(31, 0, 30)


func _scena_a() -> void:
	print("=== A: davanti ô cofano ===")
	var c := _machina(P + Vector3(0, 0, -1.9), PI * 0.5)
	await _aspetta(10)
	await _metti(P, 0.0)
	var y0: float = _pl.global_position.y
	var sp := _pl.get_world_3d().direct_space_state
	for h in [0.4, 0.85, 1.35]:
		var da: Vector3 = _pl.global_position + Vector3(0, h, 0)
		var q := PhysicsRayQueryParameters3D.create(da, da + Vector3(0, 0, -1.3), 1 | 4)
		q.exclude = [_pl.get_rid()]
		print("  raggio a %.2f: %s" % [h, str(sp.intersect_ray(q).get("position", "niente"))])
	await _premi("jump")
	await _aspetta(40)
	var y1: float = _pl.global_position.y
	print("  y %.2f → %.2f (auto a %s)" % [y0, y1, str(c.global_position)])
	if y1 < y0 + 0.8:
		male("A: nun è sagliuto ncopp'â machina")
	c.free()
	await _metti(P, 0.0)


func _scena_b() -> void:
	print("=== B: 'e spalle, ma cammina verso 'a machina ===")
	var c := _machina(P + Vector3(0, 0, -2.2), PI * 0.5)
	await _aspetta(10)
	# Guarda a sud (+z), cammina all'indietro (verso −z, cioè l'auto).
	await _metti(P, PI)
	var y0: float = _pl.global_position.y
	Input.action_press("move_down")
	await _aspetta(15)
	await _premi("jump")
	await _aspetta(30)
	Input.action_release("move_down")
	var y1: float = _pl.global_position.y
	print("  y %.2f → %.2f" % [y0, y1])
	if y1 < y0 + 0.8:
		male("B: camminanno 'e spalle nun s'arrampica")
	c.free()
	await _metti(P, 0.0)


func _scena_c() -> void:
	print("=== C: nato 'ncastrato fra doje machine ===")
	var c1 := _machina(P + Vector3(-1.05, 0, 0), 0.0)
	var c2 := _machina(P + Vector3(1.05, 0, 0), 0.0)
	await _aspetta(10)
	_pl.global_position = P + Vector3(0, 0.2, 0)
	_pl.velocity = Vector3.ZERO
	await _aspetta(10)
	var da: Vector3 = _pl.global_position
	var dentro: bool = _pl.call("_incastrato")
	print("  incastrato: %s a %s" % [str(dentro), str(da)])
	await _premi("jump")
	await _aspetta(40)
	var a: Vector3 = _pl.global_position
	var libero: bool = not bool(_pl.call("_incastrato"))
	print("  dopo: %s  libero: %s" % [str(a), str(libero)])
	if not libero:
		male("C: SPAZIO nun l'ha liberato")
	c1.free()
	c2.free()
	await _metti(P, 0.0)


func _scena_d() -> void:
	print("=== D: 'ncastrato e spinge, senza SPAZIO ===")
	var c1 := _machina(P + Vector3(-1.0, 0, 0), 0.0)
	var c2 := _machina(P + Vector3(1.0, 0, 0), 0.0)
	await _aspetta(10)
	_pl.global_position = P + Vector3(0, 0.2, 0)
	_pl.rotation.y = PI * 0.5
	_pl.velocity = Vector3.ZERO
	Input.action_press("move_up")
	await _aspetta(60 * 4)
	Input.action_release("move_up")
	await _aspetta(20)
	var libero: bool = not bool(_pl.call("_incastrato"))
	print("  dopo quattro secondi: %s libero: %s" % [str(_pl.global_position), str(libero)])
	if not libero:
		male("D: dopo quattro secondi è ancora 'ncastrato")
	c1.free()
	c2.free()
