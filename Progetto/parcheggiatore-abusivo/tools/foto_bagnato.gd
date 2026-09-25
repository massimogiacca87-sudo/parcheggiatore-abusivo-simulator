extends Node
## 'O selciato asciutto e 'o selciato bagnato, 'a stessa inquadratura.
##
## È l'unico modo di sapere se `Tex.bagna()` fa qualcosa: due foto dallo
## stesso punto, alla stessa ora, con la stessa luce. Se messe una accanto
## all'altra sono uguali, il lavoro non è stato fatto — e siccome la
## differenza è una rugosità e uno speculare, a occhio dentro al gioco è
## proprio il tipo di cosa su cui ci si convince da soli.
##
## Si guarda un pezzo di strada bagnata **con la luce di taglio**: un
## riflesso si vede dove la luce rimbalza verso la camera, e a mezzogiorno
## con il sole in cima non si vedrebbe niente nemmeno in un acquazzone
## vero.

const Citta := preload("res://scripts/citta_3d.gd")
const JurnataVista := preload("res://scripts/jurnata_vista.gd")
const Tex := preload("res://scripts/textures.gd")

## Il Corso guardato in lunghezza, occhio basso: così il selciato occupa
## mezzo fotogramma e il riflesso, se c'è, si vede.
const OCCHIO := Vector3(78.0, 1.7, 96.0)
const MIRA := Vector3(78.0, 0.9, 40.0)

var _t := 0.0
var _n := 0
var _pulito := false
var _cam: Camera3D = null
var _jur: Node3D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(d: float) -> void:
	if not _pulito:
		for n in get_tree().root.get_children():
			if n != self:
				_spegni(n)
		_pulito = true
		get_tree().paused = false
		GameManager.giornata = 6
		GameManager.start_shift()
		# Le sette di sera: sole basso, luce di taglio. È l'ora in cui una
		# strada bagnata si vede bagnata.
		GameManager.shift_time_left = GameManager.shift_duration * 0.42
		_cam = Camera3D.new()
		add_child(_cam)
		_cam.global_position = OCCHIO
		_cam.look_at_from_position(OCCHIO, MIRA, Vector3.UP)
		_cam.current = true
		return

	_t += d
	if _t < 0.8:
		return
	_t = 0.0
	_n += 1
	match _n:
		1:
			# **'O cunfronto adda cagnà 'na cosa sola.**
			#
			# Al primo giro mettevo "normale" contro "pioggia": ma la
			# pioggia cambia pure il cielo, la luce e la foschia, e le due
			# foto uscivano una di notte e una di giorno — cioè due
			# immagini che non dicono niente su quello che volevo
			# guardare. Qui piove in tutte e due, e l'unica cosa che
			# cambia è l'acqua per terra.
			GameManager.tipo_giornata = "pioggia"
			if _jur == null:
				_jur = JurnataVista.new()
				_jur.centro_piazza = Vector3(31, 0, 30)
				get_tree().root.add_child(_jur)
			_ciclo()
			Tex.bagna(0.0)
			print("  chiove ma 'o selciato è asciutto (bagnato=%.1f)" % Tex._bagnato)
		2:
			await _scatta("asciutto")
		3:
			_ciclo()
			Tex.bagna(1.0)
			print("  chiove e 'o selciato è bagnato (bagnato=%.1f)" % Tex._bagnato)
		4:
			await _scatta("bagnato")
		_:
			get_tree().quit()


## Il ciclo giorno/notte deve rifare un giro perché si accorga che oggi
## piove: è lui che chiama `Tex.bagna()`.
func _ciclo() -> void:
	# **E ll'ora se rimette a ogni scatto.** Al primo giro non lo facevo, e
	# fra la foto asciutta e quella bagnata passavano quattro secondi di
	# gioco: usciva una foto di giorno e una di notte, cioè due immagini
	# che non si possono confrontare per niente. Un confronto vale solo se
	# **cambia una cosa sola**, e qui quella cosa è l'acqua.
	GameManager.shift_time_left = GameManager.shift_duration * 0.42
	var c := get_tree().root.find_child("GiornoNotte", true, false)
	if c != null:
		c.call("_applica", c.get("avanzamento"))
		# **E po' se ferma.**
		#
		# `_applica` chiama `Tex.bagna()` a ogni fotogramma, quindi
		# qualunque cosa scrivessi io dopo veniva rimessa subito: la foto
		# "asciutta" era bagnata come l'altra, e le due immagini erano
		# identiche — il che mi aveva quasi convinto che la cosa non
		# funzionasse. Funzionava: era la prova a non isolare niente.
		c.process_mode = Node.PROCESS_MODE_DISABLED
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
	img.save_png("/tmp/ba_%s.png" % nome)
	print("  foto: /tmp/ba_%s.png" % nome)
