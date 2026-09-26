extends Node
## **'E fotografie d''a robba 'e fore** (0.62, asset esterni).
##
## Prima di mettere in città un modello del pacchetto esterno lo si guarda
## (trappola 34: il nome non è la cosa). Qui i modelli di
## `assets/esterni/modelli/` stanno in fila su un palco vuoto, fuori dalla
## città, con un uomo accanto per la scala; e per ognuno si stampa
## l'ingombro vero e il centro, che servono a metterli per terra dritti.
##
## Uso: `/tmp/foto.sh foto_esterni 200` → `/tmp/est_*.png`.

const Models := preload("res://scripts/models.gd")

const D := "res://assets/esterni/modelli/"
const FILE := {
	"arredo": ["plastic_chair/Chair_Rlyhe93NNe", "plastic_chair/Chair_kLViSk9EhX",
		"plastic_chair/Office_Chair_UfKvrZBK6C", "traffic_cone/Traffic_Cone_lAx8JytxGD",
		"traffic_cone/Traffic_Cone_aDIrUbMbW3", "traffic_cone/Road_Cone_ZPhinXAGtY",
		"crate/Crate_3VGWnZPXmG", "crate/Cube_Crate_YAghI6GBls",
		"crate/Fruit_Crate_aXulVWHOeV", "trash_can/Trashcan_vlVx279xut",
		"trash_can/Trashcan_Small_i7HDuYDLkx", "trash_can/Trashcan_Large_eYNKnGlhon"],
	"motorini": ["scooter/Vespa_blGLclvvdEM", "scooter/Scooter_fPLXByG4Vx5",
		"scooter/low_poly_scooter_awXCP7LUcz6",
		"scooter/Cartoony_Purple_Motorcycle_j20srJUjpB"],
	"auto": ["utility_car/Car_unqqkULtRU", "utility_car/Stationwagon_vTTTjDoxhV",
		"utility_car/VIP_Susanne_s_car_KIfFi9Vh0O", "utility_car/SUV_xsMtZhBkxL",
		"utility_car/Sports_Car_1mkmFkAz5v", "utility_car/Sports_Car_OyqKvX9xNh",
		"utility_car/Police_Car_BwwnUrWGmV"],
	"gente": ["npc_animati/Business_Man_JFrLIKqvCH", "npc_animati/Casual_Character_kZ3DmIoGip",
		"npc_animati/Worker_Yg2bQZO6Hj", "npc_animati/Farmer_7pn3R6hPvE",
		"npc_animati/Animated_Woman_nIItLV9nxS", "npc_animati/Animated_Woman_qJ2gsTUBHL",
		"npc_animati/Man_HMnuH5geEG", "npc_animati/Man_in_Suit_mQnGoME1ez",
		"npc_animati/Woman_Casual_jpKRgGDxhk", "npc_animati/Character_Animated_DgOCW9ZCRJ",
		"npc_animati/Animated_Human_c3Ibh9I3udk"],
}

var _t := 0.0
var _n := 0
var _pulito := false
var _cam: Camera3D = null
var _palco: Node3D = null
var _gruppi: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_gruppi = FILE.keys()


func _process(d: float) -> void:
	if not _pulito:
		_pulito = true
		get_tree().paused = false
		_cam = Camera3D.new()
		add_child(_cam)
		_cam.current = true
		return
	_t += d
	if _t < 0.9:
		return
	_t = 0.0
	var i := _n / 2
	if i >= _gruppi.size():
		get_tree().quit()
		return
	if _n % 2 == 0:
		_banco(str(_gruppi[i]))
	else:
		await _scatta(str(_gruppi[i]))
	_n += 1


func _banco(gruppo: String) -> void:
	if _palco != null and is_instance_valid(_palco):
		_palco.free()
	_palco = Node3D.new()
	get_tree().root.add_child(_palco)
	var lista: Array = FILE[gruppo]
	var passo := 1.3 if gruppo == "arredo" else (2.2 if gruppo == "motorini" \
		else (5.0 if gruppo == "auto" else 1.4))
	print("=== %s ===" % gruppo)
	for i in lista.size():
		var path: String = D + str(lista[i]) + ".glb"
		var res = load(path)
		if res == null:
			print("  NUN SE CARICA: ", path)
			continue
		var n: Node3D = (res as PackedScene).instantiate()
		_palco.add_child(n)
		var x: float = 600.0 + (float(i) - float(lista.size() - 1) * 0.5) * passo
		n.global_position = Vector3(x, 40.0, 600.0)
		var box := Models._aabb_of(n)
		var ap := n.find_children("*", "AnimationPlayer", true, false)
		var clip := ""
		if not ap.is_empty():
			var a: AnimationPlayer = ap[0]
			clip = " clip=%d %s" % [a.get_animation_list().size(),
				str(Array(a.get_animation_list()).slice(0, 30))]
		print("  %-48s ngombro %s centro %s%s" % [lista[i],
			str(box.size.snapped(Vector3.ONE * 0.01)),
			str(box.get_center().snapped(Vector3.ONE * 0.01)), clip])
	var pupo := Models.spawn("pupo", 1.75)
	if pupo != null:
		_palco.add_child(pupo)
		pupo.global_position = Vector3(600.0 + (float(lista.size()) * 0.5 + 0.4) * passo,
			40.0, 600.0)
	var l := DirectionalLight3D.new()
	l.light_energy = 1.3
	l.rotation_degrees = Vector3(-40.0, 150.0, 0.0)
	_palco.add_child(l)
	var amb := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.36, 0.40, 0.46)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.64, 0.66, 0.70)
	env.ambient_light_energy = 1.0
	amb.environment = env
	_palco.add_child(amb)
	var largo: float = float(lista.size() + 1) * passo
	var alto: float = 1.2 if gruppo != "auto" else 1.6
	_cam.fov = 50.0
	var dist: float = largo * 0.95 + 2.0
	_cam.look_at_from_position(Vector3(600.0, 40.0 + alto + dist * 0.25, 600.0 + dist),
		Vector3(600.0 + passo * 0.5, 40.0 + alto * 0.6, 600.0), Vector3.UP)
	_cam.current = true


func _spegni(n: Node) -> void:
	if n is CanvasLayer:
		(n as CanvasLayer).visible = false
	for c in n.get_children():
		_spegni(c)


func _scatta(nome: String) -> void:
	for n in get_tree().root.get_children():
		if n != self and n != _palco:
			_spegni(n)
			if n is Node3D:
				(n as Node3D).visible = false
	_cam.current = true
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/est_%s.png" % nome)
	print("  foto /tmp/est_%s.png" % nome)
