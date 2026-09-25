extends Node
## Fote d''o lotto e d''e ppartite.
##
## Due pannelli nuovi e pieni di roba: novanta caselle da una parte, un
## tabellone intero dall'altra. O si guardano o non si sa se stanno in
## piedi — e in particolare se le novanta caselle della smorfia ci stanno
## davvero sullo schermo.

const PannelloLotto := preload("res://scripts/pannello_lotto.gd")
const PannelloPartite := preload("res://scripts/pannello_partite.gd")

var _t := 0.0
var _n := 0
var _pulito := false
var _lot: CanvasLayer = null
var _par: CanvasLayer = null


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
		GameManager.giornata = 4
		GameManager.start_shift()
		GameManager.money = 240
	_t += d
	if _t < 0.55:
		return
	_t = 0.0
	_n += 1
	match _n:
		1:
			_lot = PannelloLotto.new()
			get_tree().root.add_child(_lot)
			_lot.apri()
		2:
			_scatta("lotto_vacante")
		3:
			# Tre numeri scelti: si guarda la schedina col numero grosso.
			_lot.set("_scelti", [22, 47, 90])
			_lot.call("_aggiorna")
		4:
			_scatta("lotto_terno")
		5:
			# E dopo un'estrazione, per vedere i numeri usciti segnati.
			GameManager.lotto_giocate = [{"ruota": "Napoli",
				"numeri": [22, 47], "puntata": 5, "giornata": 4}]
			GameManager.estrai_lotto()
			_lot.call("_aggiorna")
		6:
			# **`_scatta()` è 'na coroutine.** Senza `await`, la riga dopo
			# spegne il pannello prima che la foto sia scattata, e viene
			# fuori lo sfondo vuoto.
			await _scatta("lotto_dopo_estrazione")
			_lot.visible = false
		7:
			_par = PannelloPartite.new()
			get_tree().root.add_child(_par)
			_par.apri()
		8:
			_scatta("partite_schedina")
		9:
			_par.call("_scegli", 0, "1")
		10:
			_scatta("partite_scelta")
		11:
			_par.call("_via")
			_t = 0.30
		12:
			_scatta("partite_meta")
			_t = 0.30
		13:
			_scatta("partite_meta2")
			# Si porta il cronometro alla fine a mano.
			_par.set("_t", 20.0)
			_t = 0.4
		14:
			_scatta("partite_fine")
			await get_tree().create_timer(0.4).timeout
			get_tree().quit()


func _spegni(n: Node) -> void:
	for c in n.get_children():
		if c is CanvasLayer and c != _lot and c != _par:
			(c as CanvasLayer).visible = false
		if c is CanvasItem:
			(c as CanvasItem).visible = false
		_spegni(c)


func _scatta(nome: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/sa_%s.png" % nome)
	print("  foto: /tmp/sa_%s.png" % nome)
