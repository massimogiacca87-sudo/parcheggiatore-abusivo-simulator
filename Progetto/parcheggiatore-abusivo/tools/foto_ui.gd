extends Node
## Fote d''e schermate: 'a scopa e 'o tutoriale.
##
## Sono le due cose che il capo ha segnalato come illeggibili, e sono anche
## le due che non si possono giudicare leggendo il codice: o si guarda lo
## schermo o non si sa.

const PannelloScopa := preload("res://scripts/pannello_scopa.gd")
const Caricamento := preload("res://scripts/caricamento.gd")

var _t := 0.0
var _n := 0
var _pulito := false
var _sc: CanvasLayer = null
var _tut: CanvasLayer = null


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
	_t += d
	if _t < 0.7:
		return
	_t = 0.0
	_n += 1
	match _n:
		1:
			_sc = PannelloScopa.new()
			get_tree().root.add_child(_sc)
			_sc.avvia(GameManager.sfidante("ciccio"), 5)
			print("  scopa aperta")
		2:
			_scatta("scopa_mano")
		3:
			# Si clicca la prima carta della mano che può prendere qualcosa:
			# è lo stato che il capo ha chiesto — le carte del tavolo che si
			# accendono di giallo.
			_clicca_una_carta()
			_t = 0.35
		4:
			_scatta("scopa_scelta")
		5:
			# Si forza la fine partita per fotografare il tabellone e il
			# bottone: è lì che prima il bottone finiva fuori schermo.
			_finisci()
			_t = 0.45
		6:
			_scatta("scopa_fine")
		7:
			if _sc != null:
				_sc.visible = false
				get_tree().paused = false
			_tut = Caricamento.new()
			get_tree().root.add_child(_tut)
			_t = 0.5
		8:
			_apri_tutorial(0)
			_t = 0.4
		9:
			_scatta("tutorial_1")
		10:
			_apri_tutorial(1)
			_t = 0.4
		11:
			_scatta("tutorial_2")
		12:
			_apri_tutorial(4)
			_t = 0.4
		13:
			_scatta("tutorial_comandi")
			await get_tree().create_timer(0.4).timeout
			get_tree().quit()


func _apri_tutorial(n: int) -> void:
	if _tut == null:
		return
	_tut.call("_mostra_pagina", n)


func _clicca_una_carta() -> void:
	if _sc == null:
		return
	var m = _sc.get("_m")
	if m == null:
		return
	var Motore = load("res://scripts/scopa_motore.gd")
	for c in m.mani[0]:
		if not Motore.prese_possibili(int(c), m.tavolo).is_empty():
			_sc.call("_clicca_mano", int(c))
			print("  cliccata 'a carta ", Motore.nome_carta(int(c)))
			return
	print("  nisciuna carta piglia niente: se lassa 'a mano comm'è")


func _finisci() -> void:
	if _sc == null:
		return
	var m = _sc.get("_m")
	if m == null:
		return
	# Si svuotano le mani e il mazzo: il motore chiude da solo alla prossima
	# giocata, ma qui basta chiamare la chiusura.
	# 0.62: una partita vinta, per vedere il riquadro del turneo sbloccato.
	if OS.get_environment("SCOPA_VINTA") != "":
		var mie: Array = []
		var soie: Array = []
		for c in range(40):
			if c % 3 == 2:
				soie.append(c)
			else:
				mie.append(c)
		m.prese = [mie, soie]
		m.scope = [2, 1]
	_sc.call("_chiudi_partita")


func _spegni(n: Node) -> void:
	for c in n.get_children():
		if c is CanvasLayer and c != _sc and c != _tut:
			(c as CanvasLayer).visible = false
		if c is CanvasItem:
			(c as CanvasItem).visible = false
		_spegni(c)


func _scatta(nome: String) -> void:
	for n in get_tree().root.get_children():
		if n != self and n != _sc and n != _tut:
			_spegni(n)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/ui_%s.png" % nome)
	print("  foto: /tmp/ui_%s.png" % nome)
