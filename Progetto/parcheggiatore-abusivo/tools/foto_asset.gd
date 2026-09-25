extends Node
## Foto degli asset rimessi in strada nella 0.57.
##
## Le misure le ha già prese `prova_asset`, ma una misura giusta non basta:
## il lampione può essere alto quattro metri e sessantacinque e avere la
## luce appesa dalla parte sbagliata del braccio. Qui si guarda.
##
## **E ll'inquadrature nun se 'nduvinano.** Il primo giro di foto l'avevo
## puntato a coordinate scelte a occhio, e sono uscite quattro fotografie di
## un muro: la telecamera stava dentro a un palazzo. Qui invece le cose si
## **cercano** — la sciarpa si fa dire dove sta da sé stessa — e il banco
## degli oggetti si costruisce fuori dalla città, dove non c'è niente che
## possa mettersi in mezzo.

const Models := preload("res://scripts/models.gd")

var _t := 0.0
var _n := 0
var _pulito := false
var _cam: Camera3D = null
var _palco: Node3D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(d: float) -> void:
	if not _pulito:
		_pulito = true
		get_tree().paused = false
		GameManager.giornata = 2
		GameManager.start_shift()
		GameManager.tipo_giornata = "normale"
		GameManager.shift_time_left = GameManager.shift_duration * 0.86
		_cam = Camera3D.new()
		add_child(_cam)
		_cam.current = true
		return
	_t += d
	if _t < 0.9:
		return
	_t = 0.0
	_n += 1
	match _n:
		1: _banco()
		2: await _scatta("banco")
		3: _addo_sta_a_sciarpa()
		4: await _scatta("sciarpa")
		_: get_tree().quit()


## I cinque modelli in fila su un palco vuoto, alla stessa distanza e con la
## stessa luce: uno accanto all'altro si vede subito se uno è fuori scala.
func _banco() -> void:
	_palco = Node3D.new()
	get_tree().root.add_child(_palco)
	var quale := ["lampione", "new_jersey", "barriera_lunga", "delimitatore",
		"giara"]
	var passo := 2.6
	for i in quale.size():
		var n := Models.spawn(str(quale[i]))
		if n == null:
			continue
		_palco.add_child(n)
		n.global_position = Vector3(600.0 + (float(i) - 2.0) * passo, 40.0,
			600.0)
	# Un uomo accanto, che è l'unico metro che si legge in fotografia.
	var pupo := Models.spawn("pupo", 1.75)
	if pupo != null:
		_palco.add_child(pupo)
		pupo.global_position = Vector3(600.0 + 3.1 * passo * 0.5, 40.0, 600.0)

	var l := DirectionalLight3D.new()
	l.light_energy = 1.3
	l.rotation_degrees = Vector3(-40.0, 140.0, 0.0)
	_palco.add_child(l)
	var amb := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.36, 0.40, 0.46)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.64, 0.66, 0.70)
	env.ambient_light_energy = 1.0
	_palco.add_child(amb)

	_mira(Vector3(600.0, 42.6, 609.0), Vector3(600.0, 41.4, 600.0))
	print("  banco 'e cinche modelle")


## **'A sciarpa se fa truvà.** Invece di scrivere una coordinata a mano si
## cerca nella città il quad che monta la texture della sciarpa, e ci si
## mette davanti. Se domani i balconi cambiano posto, la foto resta giusta.
func _addo_sta_a_sciarpa() -> void:
	if _palco != null and is_instance_valid(_palco):
		_palco.free()
		_palco = null
	var citta := get_tree().root.find_child("Citta", true, false)
	if citta == null:
		print("  NUN CE STA 'A CITTÀ")
		return
	var trovata: Node3D = null
	for n in _tutte(citta):
		if not (n is MeshInstance3D):
			continue
		var m: MeshInstance3D = n
		var mat := m.material_override as StandardMaterial3D
		if mat == null or mat.albedo_texture == null:
			continue
		if str(mat.albedo_texture.resource_path).contains("sciarpa"):
			trovata = m
			break
	if trovata == null:
		print("  NUN CE STANNO SCIARPE")
		return
	var p: Vector3 = trovata.global_position
	print("  sciarpa truvata a %s" % str(p.round()))
	# Da sotto e di sbieco, come la si vede camminando per strada.
	_mira(p + Vector3(2.6, -1.6, 2.6), p)


func _tutte(n: Node) -> Array:
	var fore: Array = [n]
	for c in n.get_children():
		fore.append_array(_tutte(c))
	return fore


func _mira(occhio: Vector3, mira: Vector3) -> void:
	_cam.global_position = occhio
	_cam.look_at_from_position(occhio, mira, Vector3.UP)
	_cam.current = true


func _spegni(n: Node) -> void:
	if n is CanvasLayer:
		(n as CanvasLayer).visible = false
	for c in n.get_children():
		_spegni(c)


func _scatta(nome: String) -> void:
	for n in get_tree().root.get_children():
		if n != self:
			_spegni(n)
	_cam.current = true
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/57_%s.png" % nome)
	print("  foto: /tmp/57_%s.png" % nome)
