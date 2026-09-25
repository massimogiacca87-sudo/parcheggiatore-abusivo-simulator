extends Node
## Fote d''e ghiornate speciale, dint'â città overa.
##
## Questa è l'unica prova che conta davvero per la 0.53, perché quello che
## il capo ha chiesto è **che si vedano**. Quindi qui la città si costruisce
## per intero, si mette la camera dove sta il giocatore, e si guarda.
##
## Una foto per giornata, dalla stessa posizione e con la stessa
## inquadratura: messe una accanto all'altra, o si vede la differenza o
## non si è fatto niente.

const Citta := preload("res://scripts/citta_3d.gd")
const JurnataVista := preload("res://scripts/jurnata_vista.gd")

## Da dove si guarda: in mezzo alla piazza, un filo alzati, verso il varco.
const OCCHIO := Vector3(31.0, 2.4, 44.0)
const MIRA := Vector3(31.0, 1.2, 14.0)

var _t := 0.0
var _n := 0
var _pulito := false
var _cam: Camera3D = null
var _jur: Node3D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	await get_tree().process_frame


func _process(d: float) -> void:
	if not _pulito:
		# Le interfacce si spengono: qui si guarda la strada.
		for n in get_tree().root.get_children():
			if n == self:
				continue
			_spegni(n)
		_pulito = true
		# **'O gioco parte 'n pausa** (schermata di caricamento). Senza
		# questa riga `GiornoNotte._process()` non gira mai, il cielo resta
		# quello di mezzogiorno e la pioggia non lo scurisce: la prima
		# foto di pioggia usciva con il sole.
		get_tree().paused = false
		GameManager.giornata = 4
		GameManager.start_shift()
		# Le due del pomeriggio: pieno giorno, così la differenza fra
		# sole e pioggia si vede tutta.
		GameManager.shift_time_left = GameManager.shift_duration * 0.88
		_cam = Camera3D.new()
		add_child(_cam)
		_cam.global_position = OCCHIO
		_cam.look_at_from_position(OCCHIO, MIRA, Vector3.UP)
		_cam.current = true
		return

	_t += d
	if _t < 0.7:
		return
	_t = 0.0
	_n += 1

	var giorni := ["mercato", "processione"]
	var quale: int = (_n - 1) / 3
	var passo: int = (_n - 1) % 3
	if quale >= giorni.size():
		get_tree().quit()
		return

	match passo:
		0:
			GameManager.tipo_giornata = giorni[quale]
			if _jur != null and is_instance_valid(_jur):
				_jur.queue_free()
			_jur = JurnataVista.new()
			_jur.centro_piazza = Vector3(31, 0, 30)
			get_tree().root.add_child(_jur)
			# La processione aspetta otto secondi prima di uscire: qui si
			# accorcia, che una foto non può aspettare.
			if giorni[quale] == "processione":
				_jur.set("_proc_t", 0.02)
			print("  jurnata: %s" % giorni[quale])
		1:
			# Un giro di _process per far partire quello che deve partire,
			# e per portare la processione a metà piazza.
			for i in range(28):
				_jur._process(0.5)
			_cam.current = true
			# La pioggia si mette attorno alla camera da sola, ma il
			# ciclo del cielo ha bisogno di un giro per accorgersi che
			# oggi piove: gli si chiede a mano.
			var ciclo := get_tree().root.find_child("GiornoNotte", true, false)
			if ciclo != null:
				ciclo.call("_applica", ciclo.get("avanzamento"))
		2:
			await _scatta(giorni[quale])


func _spegni(n: Node) -> void:
	if n is CanvasLayer:
		(n as CanvasLayer).visible = false
	for c in n.get_children():
		_spegni(c)


func _scatta(nome: String) -> void:
	_cam.current = true
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/ju_%s.png" % nome)
	print("  foto: /tmp/ju_%s.png" % nome)
