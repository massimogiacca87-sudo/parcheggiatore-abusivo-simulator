extends Node2D
## Prova minima: 'o Pointer Lock se dà sulo dint'a 'nu gesto?
##
## Due strade, quelle vere del gioco:
##   * dint'ô `_ready()`, comm'era primma d''a 0.56b;
##   * dint'ô manico d''o click, comm'è mo'.
## 'A risposta 'a dà 'o browser, no chisto file.

var _righe: Label


func _ready() -> void:
	_righe = Label.new()
	_righe.position = Vector2(20, 20)
	_righe.add_theme_font_size_override("font_size", 22)
	add_child(_righe)
	# COMM'ERA PRIMMA: se chiede fore 'a 'nu gesto.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_scrive("doppo _ready()")


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		# COMM'È MO': se chiede dint'ô click.
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		_scrive("doppo 'o click")


func _scrive(quanno: String) -> void:
	var m := Input.get_mouse_mode()
	_righe.text = "%s: mouse_mode = %d (CAPTURED = %d)" % [
		quanno, m, Input.MOUSE_MODE_CAPTURED]
	print(_righe.text)
