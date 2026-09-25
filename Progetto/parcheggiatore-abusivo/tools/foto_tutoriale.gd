extends Node
## Fote d''o tutoriale: se legge overo?
##
## Il tutorial è testo, e il testo o si legge o non si legge: non c'è modo
## di saperlo leggendo il codice. Qui si aprono tutte le pagine, una per
## una, e si fotografano — più il menu di pausa, che dalla 0.52 tiene un
## bottone in più e doveva crescere per farcelo stare.

const Tutoriale := preload("res://scripts/tutoriale.gd")
const Hud := preload("res://scripts/hud.gd")

var _t := 0.0
var _n := 0
var _pulito := false
var _tut: CanvasLayer = null
var _hud: CanvasLayer = null


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
		GameManager.start_shift()
	_t += d
	if _t < 0.5:
		return
	_t = 0.0
	_n += 1

	if _n == 1:
		_tut = Tutoriale.new()
		get_tree().root.add_child(_tut)
		_tut.apri()
		return
	# Una foto per pagina.
	var quante: int = Tutoriale.PAGINE.size()
	if _n >= 2 and _n <= quante + 1:
		var pag: int = _n - 2
		_tut.set("_pagina", pag)
		_tut.call("_disegna")
		await get_tree().process_frame
		_scatta("tut_%d" % (pag + 1))
		return
	if _n == quante + 2:
		_tut.visible = false
		_hud = Hud.new()
		get_tree().root.add_child(_hud)
		return
	if _n == quante + 3:
		_hud.call("_pause_game")
		return
	if _n == quante + 4:
		_scatta("tut_pausa")
		await get_tree().create_timer(0.4).timeout
		get_tree().quit()


func _spegni(n: Node) -> void:
	for c in n.get_children():
		if c is CanvasLayer and c != _tut and c != _hud:
			(c as CanvasLayer).visible = false
		if c is CanvasItem:
			(c as CanvasItem).visible = false
		_spegni(c)


func _scatta(nome: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/tu_%s.png" % nome)
	print("  foto: /tmp/tu_%s.png" % nome)
