extends Node
## Fote d''o lotto (0.62): 'o pannello vacante, cu 'na schedina, e doppo
## 'na giocata. DEBUG_SIM=1 /tmp/foto.sh foto_lotto 120 → /tmp/lotto_*.png

const PannelloLotto := preload("res://scripts/pannello_lotto.gd")

var _p: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(40):
		await get_tree().process_frame
	GameManager.money = 180
	GameManager.intro_active = false
	# Un'estrazione vecchia, così il quadernetto non è vuoto.
	for _k in range(3):
		GameManager.estrai_lotto()
	GameManager.lotto_giocate.clear()
	_p = PannelloLotto.new()
	get_tree().root.add_child(_p)
	_p.apri()
	for _i in range(10):
		await get_tree().process_frame
	await _scatta("vuoto")
	_p.call("_tocca", 47)
	_p.call("_tocca", 90)
	_p.call("_tocca", 16)
	for _i in range(4):
		await get_tree().process_frame
	await _scatta("schedina")
	_p.call("_gioca")
	for _i in range(4):
		await get_tree().process_frame
	await _scatta("giocato")
	get_tree().quit()


func _scatta(nome: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/lotto_%s.png" % nome)
	print("  foto: /tmp/lotto_%s.png" % nome)
