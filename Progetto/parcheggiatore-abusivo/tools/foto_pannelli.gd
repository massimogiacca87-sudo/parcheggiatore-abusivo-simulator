extends Node
## 'E fote d''e pannielle (0.62): tutti quelli che non sono l'HUD.
##
## Il capo ha chiesto di rivedere **l'intera** interfaccia. L'HUD, la scopa,
## il lotto e la mappa hanno le loro foto; questa fotografa il resto, uno
## per volta, dentro al gioco vero (tema, font, scala 1280x720):
## negozio, riepilogo della giornata, bacheca, casa, partite, scasso,
## tutoriale e schermata d'inizio.
##   DEBUG_SIM=1 /tmp/foto.sh foto_pannelli 260   (SOLO=negozio,casa)
## Le foto finiscono in /tmp/pan_*.png.

const PannelloBacheca := preload("res://scripts/pannello_bacheca.gd")
const PannelloCasa := preload("res://scripts/pannello_casa.gd")
const PannelloPartite := preload("res://scripts/pannello_partite.gd")
const PannelloScassa := preload("res://scripts/pannello_scassa.gd")
const Tutoriale := preload("res://scripts/tutoriale.gd")
const Intro := preload("res://scripts/intro_screen.gd")

var _pl: Node3D = null
var _hud: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(60):
		await get_tree().process_frame
	get_tree().paused = false
	GameManager.intro_active = false
	GameManager.giornata = 4
	GameManager.money = 214
	GameManager.money_changed.emit(214)
	_pl = get_tree().get_first_node_in_group("player") as Node3D
	_hud = get_tree().root.find_child("HUD", true, false)
	_pl.set_physics_process(false)
	var solo := OS.get_environment("SOLO")

	if solo == "" or "negozio" in solo:
		for kind in ["zio", "bazar", "tabacchi"]:
			_hud.call("set_shop_visible", kind)
			await _aspetta(8)
			await _scatta("negozio_" + kind)
			_hud.call("set_shop_visible", "")
			await _aspetta(4)

	if solo == "" or "bacheca" in solo:
		var b := PannelloBacheca.new()
		get_tree().root.add_child(b)
		await _aspetta(3)
		b.apri()
		await _aspetta(10)
		await _scatta("bacheca")
		b.queue_free()
		await _aspetta(4)

	if solo == "" or "casa" in solo:
		GameManager.prepara_giornata()
		var c := PannelloCasa.new()
		get_tree().root.add_child(c)
		await _aspetta(3)
		c.apri_consegna()
		await _aspetta(10)
		await _scatta("casa")
		c.queue_free()
		await _aspetta(4)

	if solo == "" or "partite" in solo:
		var p := PannelloPartite.new()
		get_tree().root.add_child(p)
		await _aspetta(3)
		p.apri()
		await _aspetta(10)
		await _scatta("partite")
		# (0.64) Pure a partita in corso e a partita finita: il tabellone ha
		# tre facce, e se ne fotografava una sola.
		p.call("_scegli", 0, "1")
		await _aspetta(4)
		await _scatta("partite_scelta")
		p.call("_via")
		await get_tree().create_timer(4.0, true, false, true).timeout
		await _scatta("partite_gioco")
		await get_tree().create_timer(7.0, true, false, true).timeout
		await _scatta("partite_fine")
		p.chiudi()
		p.queue_free()
		await _aspetta(4)

	if solo == "" or "scassa" in solo:
		var s := PannelloScassa.new()
		get_tree().root.add_child(s)
		await _aspetta(3)
		s.apri("berlina", "'na berlina grigia", _pl)
		await _aspetta(20)
		await _scatta("scassa")
		s.queue_free()
		get_tree().paused = false
		await _aspetta(4)

	if solo == "" or "tutoriale" in solo:
		var t := Tutoriale.new()
		get_tree().root.add_child(t)
		await _aspetta(3)
		t.apri()
		await _aspetta(12)
		await _scatta("tutoriale")
		t.queue_free()
		get_tree().paused = false
		await _aspetta(4)

	if solo == "" or "intro" in solo:
		var i := Intro.new()
		get_tree().root.add_child(i)
		await _aspetta(40)
		await _scatta("intro")
		i.queue_free()
		get_tree().paused = false
		await _aspetta(4)

	if solo == "" or "riepilogo" in solo:
		GameManager.end_shift()
		await _aspetta(20)
		await _scatta("riepilogo")

	print("FOTO PANNIELLE FATTE")
	get_tree().quit()


func _aspetta(n: int) -> void:
	for _i in range(n):
		await get_tree().process_frame


func _scatta(nome: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/pan_%s.png" % nome)
	print("  foto ", nome)
