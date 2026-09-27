extends CanvasLayer
## **Fernuta** — 'a schermata d''o game over (0.65)
##
## Il settimo gradino della scala dei guai (vedi `GameManager`, «'A SCALA
## D''E GUAIE»): sette sere di fila a dormire con le spese da pagare, e la
## partita finisce. Il capo la voleva *«disastrosa ed esilarante»*: quindi
## non è una scritta rossa su fondo nero e basta. È il racconto dell'ultima
## mattina (le righe dei guai), quanto hai tenuto duro, e una riga di
## finale a caso — Nunzia che si sposa il vigile, il vascio affittato al
## turista americano — che è quella che uno racconta agli amici.
##
## Due tasti: si ricomincia da capo (giorno uno, zero euro, la famiglia
## intera), o si esce.

const US := preload("res://scripts/ui_stile.gd")

var _fine: Dictionary = {}


func mostra(fine: Dictionary) -> void:
	_fine = fine
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_costruisci()
	get_tree().paused = true
	GameManager.piglia_o_mouse(false)
	SoundManager.play("fail", -2.0, 0.8)


func _costruisci() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.04, 0.03, 0.035, 0.94)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fondo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var scheda := PanelContainer.new()
	scheda.custom_minimum_size = Vector2(720, 0)
	scheda.add_theme_stylebox_override("panel",
		US.box(Color(0.09, 0.07, 0.07, 0.96), Color(0.85, 0.25, 0.20, 0.6),
			2, 14, 30.0, 24.0))
	centro.add_child(scheda)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	scheda.add_child(v)

	var titolo := US.etichetta("FERNUTA.", 58, Color(1.0, 0.42, 0.34), true)
	titolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titolo.add_theme_font_override("font", US.font_titolo())
	v.add_child(titolo)

	var sotto := US.etichetta("Sette juorne senza pavà. 'A famiglia, 'a casa, 'a piazza: tutto perzo.",
		17, Color(1.0, 0.86, 0.72))
	sotto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sotto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sotto.custom_minimum_size = Vector2(660, 0)
	v.add_child(sotto)

	v.add_child(HSeparator.new())

	for riga in _fine.get("conseguenze", []):
		var l := US.etichetta("· " + str(riga), 14, Color(0.92, 0.86, 0.80))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(660, 0)
		v.add_child(l)

	var conti := US.etichetta(
		"Hê tenuto duro %d juorne.   Piazze: %d.   In sacca: €%d.   Ancora 'a pavà: €%d." % [
			int(_fine.get("giornate", 0)), int(_fine.get("piazze", 1)),
			int(_fine.get("soldi", 0)), int(_fine.get("dovuto", 0))],
		15, Color(0.80, 0.90, 0.78))
	conti.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	conti.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	conti.custom_minimum_size = Vector2(660, 0)
	v.add_child(conti)

	v.add_child(HSeparator.new())

	var finale := US.etichetta(str(_fine.get("finale", "")), 18,
		Color(1.0, 0.80, 0.40), true)
	finale.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finale.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	finale.custom_minimum_size = Vector2(660, 0)
	v.add_child(finale)

	var tasti := HBoxContainer.new()
	tasti.alignment = BoxContainer.ALIGNMENT_CENTER
	tasti.add_theme_constant_override("separation", 16)
	v.add_child(tasti)
	var da_capo := Button.new()
	da_capo.text = "Ricumincia da capo"
	da_capo.custom_minimum_size = Vector2(260, 46)
	da_capo.pressed.connect(_da_capo)
	tasti.add_child(da_capo)
	da_capo.call_deferred("grab_focus")
	if not OS.has_feature("web"):
		var esci := Button.new()
		esci.text = "Esci d''o gioco"
		esci.custom_minimum_size = Vector2(200, 46)
		esci.pressed.connect(_esci)
		tasti.add_child(esci)


func _da_capo() -> void:
	GameManager.ricomincia_da_capo()
	GameManager.salta_intro = false
	GameManager.dentro_casa = false
	get_tree().paused = false
	GameManager.piglia_o_mouse(true)
	queue_free()
	get_tree().reload_current_scene()


func _esci() -> void:
	get_tree().quit()
