extends Node
## Fote d''a gente nova d''a 0.54.
##
## Le prove misurano i numeri: che i mestieri escano, che i vicini stiano
## fuori dalla corsia, che il rapporto salga. Nessuna di quelle risponde
## alla domanda che conta — **si vede?** Un pizzaiolo con la teglia
## attaccata all'osso sbagliato passa tutte le prove e in strada è uno che
## cammina con un vassoio dentro alla pancia.
##
## Quattro foto: i nove mestieri in fila, i quattro vicini in fila, e due
## in mezzo alla città vera.

const Human := preload("res://scripts/human_builder.gd")
const Passante := preload("res://scripts/passante_3d.gd")
const Vicino := preload("res://scripts/vicino_3d.gd")
const Citta := preload("res://scripts/citta_3d.gd")

var _t := 0.0
var _n := 0
var _pulito := false
var _cam: Camera3D = null
var _palco: Node3D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(d: float) -> void:
	if not _pulito:
		for n in get_tree().root.get_children():
			if n != self:
				_spegni(n)
		_pulito = true
		get_tree().paused = false
		GameManager.giornata = 3
		GameManager.start_shift()
		# **'A primma foto è asciuta cu ll'ombrelle.** La giornata si
		# sorteggia in `start_shift`, ed era uscita pioggia: nove calotte
		# nere sopra ai nove mestieri, e delle teglie e delle cassette non
		# si vedeva niente. Qui si guardano le persone, non il cielo.
		GameManager.tipo_giornata = "normale"
		GameManager.shift_time_left = GameManager.shift_duration * 0.86
		_cam = Camera3D.new()
		add_child(_cam)
		_cam.current = true
		return

	_t += d
	if _t < 0.6:
		return
	_t = 0.0
	_n += 1
	match _n:
		1: _fila_mestiere()
		2: await _scatta("mestiere")
		3: _fila_vicine()
		4: await _scatta("vicine")
		5: _da_vicino(["operaio", "pizzaiuolo", "marenaro"], false)
		6: await _scatta("mano_avanti")
		7: _da_vicino(["studente", "turista", "studente"], true)
		8: await _scatta("mano_dereto")
		9: _dint_a_citta(Vector3(50.0, 2.0, 55.0), Vector3(50.0, 1.4, 47.0))
		10: await _scatta("nunzia")
		11: _dint_a_citta(Vector3(31.0, 2.6, 46.0), Vector3(31.0, 1.3, 20.0))
		12: await _scatta("piazza")
		_: get_tree().quit()


## Tre da vicino, per guardare **dove sta appeso l'affare**. Con `dereto`
## la fila si gira: lo zaino si controlla solo di schiena.
func _da_vicino(ids: Array, dereto: bool) -> void:
	_pulisci_palco()
	for i in range(ids.size()):
		var p = Passante.new()
		for m in Passante.MESTIERE:
			if str(m["id"]) == str(ids[i]):
				p.mestiere = m
		_palco.add_child(p)
		p.global_position = Vector3(600.0 + (i - 1.0) * 0.95, 40.0, 600.0)
		p.rotation.y = 0.0 if dereto else PI
	_luce(Vector3(600.0, 42.0, 600.0))
	_cam.global_position = Vector3(600.0, 41.05, 602.6)
	_cam.look_at_from_position(_cam.global_position,
		Vector3(600.0, 40.95, 600.0), Vector3.UP)
	print("  tre 'a vicino (%s)" % ("'e spalle" if dereto else "'e faccia"))


func _pulisci_palco() -> void:
	if _palco != null and is_instance_valid(_palco):
		_palco.free()   # subito, non a fine frame: la foto è adesso
	_palco = Node3D.new()
	get_tree().root.add_child(_palco)


## I nove mestieri in fila, tutti alla stessa distanza e con la stessa
## luce: messi accanto si vede subito se due sono la stessa persona.
func _fila_mestiere() -> void:
	_pulisci_palco()
	var quante: int = Passante.MESTIERE.size()
	var passo := 1.25
	for i in range(quante):
		var p = Passante.new()
		p.mestiere = Passante.MESTIERE[i]
		_palco.add_child(p)
		p.global_position = Vector3(600.0 + (i - quante / 2.0) * passo, 40.0, 600.0)
		# Girati verso la camera, e fermi: qui si guarda la sagoma.
		p.rotation.y = PI
	_luce(Vector3(600.0, 42.0, 600.0))
	var largo: float = quante * passo
	_cam.global_position = Vector3(600.0 - passo * 0.5, 41.0, 600.0 + largo * 0.72)
	_cam.look_at_from_position(_cam.global_position,
		Vector3(600.0 - passo * 0.5, 40.85, 600.0), Vector3.UP)
	print("  fila 'e %d mestiere" % quante)


func _fila_vicine() -> void:
	_pulisci_palco()
	var ids := ["nunzia_bar", "totore", "rosa", "mimmo"]
	for i in range(ids.size()):
		var v = Vicino.new()
		v.vicino_id = ids[i]
		_palco.add_child(v)
		v.global_position = Vector3(600.0 + (i - 1.5) * 1.35, 40.0, 600.0)
		v.rotation.y = PI
		v.set_process(false)   # se no se girano verso 'o player
	_luce(Vector3(600.0, 42.0, 600.0))
	_cam.global_position = Vector3(600.0, 40.9, 604.4)
	_cam.look_at_from_position(_cam.global_position,
		Vector3(600.0, 40.7, 600.0), Vector3.UP)
	print("  fila 'e 4 vicine")


func _dint_a_citta(occhio: Vector3, mira: Vector3) -> void:
	if _palco != null and is_instance_valid(_palco):
		_palco.free()
		_palco = null
	_cam.global_position = occhio
	_cam.look_at_from_position(occhio, mira, Vector3.UP)
	_cam.current = true


func _luce(dove: Vector3) -> void:
	var l := DirectionalLight3D.new()
	l.light_energy = 1.25
	l.rotation_degrees = Vector3(-42.0, 138.0, 0.0)
	_palco.add_child(l)
	var amb := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.36, 0.40, 0.46)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.64, 0.68)
	env.ambient_light_energy = 0.9
	amb.environment = env
	_palco.add_child(amb)
	_palco.position = Vector3.ZERO
	var _d = dove


func _spegni(n: Node) -> void:
	if n is CanvasLayer:
		(n as CanvasLayer).visible = false
	for c in n.get_children():
		_spegni(c)


func _scatta(nome: String) -> void:
	# Le interfacce si rispengono a ogni scatto: la prima volta si spengono
	# prima che l'HUD sia costruito, e poi torna su da solo.
	for n in get_tree().root.get_children():
		if n != self:
			_spegni(n)
	_cam.current = true
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/ge_%s.png" % nome)
	print("  foto: /tmp/ge_%s.png" % nome)
