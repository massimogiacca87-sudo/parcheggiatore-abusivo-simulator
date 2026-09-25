extends Node
## Fote d''e ffasce: 'a UI 'ncoppa, 'a bacheca e 'o fummetto.
##
## Tre cose nuove della 0.51 che non si giudicano leggendo il codice:
##
##   * il nome della fascia scritto sotto al giorno, in alto a destra —
##     va guardato per sapere se sta stretto o se va a capo;
##   * il consiglio sulla bacheca, che cambia con l'ora;
##   * il fumetto, che il capo ha chiesto di ricontrollare: qui si mette
##     alla prova con la frase più lunga che il gioco può dire.

const Hud := preload("res://scripts/hud.gd")
const PannelloBacheca := preload("res://scripts/pannello_bacheca.gd")
const SpeechBubble := preload("res://scripts/speech_bubble.gd")

var _t := 0.0
var _n := 0
var _pulito := false
var _hud: CanvasLayer = null
var _bac: CanvasLayer = null
var _cam: Camera3D = null
var _mondo: Node3D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	await get_tree().process_frame


func _process(d: float) -> void:
	if not _pulito:
		for n in get_tree().root.get_children():
			if n == self:
				continue
			if n is Node3D:
				(n as Node3D).visible = false
			_spegni(n)
		_pulito = true
		GameManager.giornata = 3
		GameManager.start_shift()
		GameManager.crea_lavoretti()
	_t += d
	if _t < 0.6:
		return
	_t = 0.0
	_n += 1
	match _n:
		1:
			_hud = Hud.new()
			get_tree().root.add_child(_hud)
			_t = 0.4
		2:
			_ora(13.0); _scatta("hud_controra")
		3:
			_ora(16.0); _scatta("hud_ttre")
		4:
			_ora(22.0); _scatta("hud_rristorante")
		5:
			_ora(26.0); _scatta("hud_nuttata")
		6:
			if _hud:
				_hud.visible = false
			_bac = PannelloBacheca.new()
			get_tree().root.add_child(_bac)
			_ora(16.0)
			_bac.call("apri")
			_t = 0.45
		7:
			_scatta("bacheca_ttre")
		8:
			_ora(22.0)
			_bac.call("apri")
			_t = 0.45
		9:
			_scatta("bacheca_rristorante")
		10:
			_ora(26.0)
			_bac.call("apri")
			_t = 0.45
		11:
			_scatta("bacheca_nuttata")
		12:
			if _bac:
				_bac.visible = false
			_scena_fummetto()
			_t = 0.6
		13:
			_scatta("fummetto")
			await get_tree().create_timer(0.4).timeout
			get_tree().quit()


## Sposta l'orologio a un'ora precisa (12..28) muovendo il cronometro.
func _ora(h: float) -> void:
	GameManager.shift_time_left = GameManager.shift_duration \
		* (1.0 - (h - 12.0) / GameManager.ORE_DI_GIORNATA)
	GameManager.shift_time_changed.emit(GameManager.shift_time_left)
	GameManager._passo_fasce()
	print("  ora %s -> %s" % [GameManager.orologio(), GameManager.fascia_nome()])


## Tre fumetti a tre distanze diverse, con la frase più lunga del gioco.
func _scena_fummetto() -> void:
	_mondo = Node3D.new()
	get_tree().root.add_child(_mondo)
	_cam = Camera3D.new()
	_mondo.add_child(_cam)
	_cam.global_position = Vector3(0, 1.7, 0)
	_cam.look_at_from_position(Vector3(0, 1.7, 0), Vector3(0, 1.5, -6), Vector3.UP)
	_cam.current = true
	var luce := DirectionalLight3D.new()
	_mondo.add_child(luce)
	luce.rotation = Vector3(-0.9, 0.5, 0)
	var frasi := [
		["Tiè.", Vector3(-1.6, 1.7, -2.4)],
		["Mezzanotte. Poche machine — ma chi scenne mo' tene 'o vino 'n cuorpo e paga 'o doppio.",
			Vector3(0.4, 1.8, -4.2)],
		["Aspiè… aspiè ca mo' m'arricordo addò tengo 'o puórtafoglio…",
			Vector3(2.6, 1.7, -8.0)],
	]
	for f in frasi:
		var b = SpeechBubble.new()
		_mondo.add_child(b)
		b.global_position = f[1]
		b.say(str(f[0]), 30.0)


func _spegni(n: Node) -> void:
	for c in n.get_children():
		if c is CanvasLayer and c != _hud and c != _bac:
			(c as CanvasLayer).visible = false
		if c is CanvasItem:
			(c as CanvasItem).visible = false
		_spegni(c)


func _scatta(nome: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/fa_%s.png" % nome)
	print("  foto: /tmp/fa_%s.png" % nome)
