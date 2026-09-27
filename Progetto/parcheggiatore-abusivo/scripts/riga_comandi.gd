extends PanelContainer
## **'A riga d''e comandi** (0.62): il suggerimento «premi [E] per…».
##
## Il capo: *«Alza un po' le scritte dei tasti da premere (es. premi G per
## rubare lo stemma) perché stanno davanti ad altri elementi UI»*.
##
## Fino alla 0.61 era una `Label` a novanta pixel dal fondo, larga 640, in
## mezzo a tre bussole e alla barra delle armi: davanti a un'auto con lo
## stemma la frase ("[E] scassa… · G: ruba lo stemma… · F: danneggia…")
## era lunga il doppio della riga e finiva sopra a tutto il resto.
##
## Adesso sta **sotto al mirino** (dove l'occhio già guarda), dentro a una
## pillola scura, e ogni tasto è un tastino disegnato. Se le azioni sono
## più di una e non ci stanno su una riga, ne va una per riga.
##
## Si usa come la Label di prima: `riga.text = "…"`. Vuoto = sparisce.

const US := preload("res://scripts/ui_stile.gd")

## Oltre questa larghezza (in pixel) le azioni vanno una per riga.
const LARGHEZZA_MAX: float = 1100.0
## 0.66: da 17 a 15 (e l'HUD intero ora si rimpicciolisce con lo schermo).
const CORPO: int = 15

var text: String = "":
	set = _metti

var _dentro: VBoxContainer


func _ready() -> void:
	add_theme_stylebox_override("panel",
		US.pillola(Color(US.ORO.r, US.ORO.g, US.ORO.b, 0.30), 0.76))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_dentro = VBoxContainer.new()
	_dentro.add_theme_constant_override("separation", 3)
	_dentro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dentro)
	visible = false
	if text != "":
		_ridisegna()


func _metti(t: String) -> void:
	if t == text:
		return
	text = t
	if _dentro != null:
		_ridisegna()


func _ridisegna() -> void:
	for c in _dentro.get_children():
		_dentro.remove_child(c)
		c.queue_free()
	visible = text.strip_edges() != ""
	if not visible:
		return
	var pz: Array = US.pezzi(text)
	# Una riga sola se ci sta davvero (misurata col carattere vero, più
	# lo spazio dei tastini); se no un'azione per riga.
	var f: Font = US.font_testo()
	var largo: float = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		CORPO).x + 30.0 * float(pz.size())
	# La larghezza di chi la contiene (la radice dell'HUD, 0.66), non dello
	# schermo: la radice è scalata e le sue coordinate non sono quelle.
	var schermo: float = 1280.0
	if get_parent() is Control:
		schermo = (get_parent() as Control).size.x
	elif is_inside_tree():
		schermo = get_viewport_rect().size.x
	var una_riga: bool = largo <= minf(schermo - 120.0, LARGHEZZA_MAX)
	var riga := _riga_nova()
	for p in pz:
		match str(p[0]):
			"sep":
				if una_riga:
					var pun := US.etichetta("·", CORPO, US.TESTO_2)
					pun.add_theme_constant_override("outline_size", 0)
					riga.add_child(pun)
				else:
					riga = _riga_nova()
			"t":
				riga.add_child(US.tasto(str(p[1]), CORPO))
			"s":
				var l := US.etichetta(str(p[1]), CORPO, US.TESTO)
				l.add_theme_constant_override("outline_size", 0)
				riga.add_child(l)


func _riga_nova() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 7)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dentro.add_child(h)
	return h
