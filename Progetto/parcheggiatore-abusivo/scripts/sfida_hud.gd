extends CanvasLayer
## SfidaHud — 'o cronometro d''a sfida d''o Rre (0.64)
##
## In alto al centro, sotto a dove sta la furia di Borrelli (che durante la
## sfida non c'è: aspetta). Tre cose e basta, perché si legge con la coda
## dell'occhio mentre si fa manovra: **quanto manca**, **quante ne hai
## messe**, e **dove stanno le soglie** (3 = 'nu guaglione, 5 = 'na piazza).
## Più una scritta grande al centro per il tre-due-uno e per com'è finita.
##
## La costruisce e la butta `re_parcheggi_3d.gd`: vive quanto la sfida.

var _pannello: PanelContainer
var _tempo: Label
var _conto: Label
var _barra: ProgressBar
var _soglie: Control
var _grande: Label
var _grande_t: float = 0.0
var _pulsa: float = 0.0

const MASSIMO := 6


func _ready() -> void:
	layer = 6
	_pannello = PanelContainer.new()
	var st := UiStile.box(Color(0.05, 0.055, 0.075, 0.82), UiStile.ORO, 2, 14, 16.0, 10.0)
	st.shadow_color = Color(0, 0, 0, 0.35)
	st.shadow_size = 8
	_pannello.add_theme_stylebox_override("panel", st)
	_pannello.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_pannello.custom_minimum_size = Vector2(470, 0)
	_pannello.position = Vector2(-235, 74)
	_pannello.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pannello)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pannello.add_child(col)

	var titolo := UiStile.etichetta("'A SFIDA D''O RRE D''E PARCHEGGI", 16, UiStile.ORO, true)
	titolo.add_theme_font_override("font", UiStile.font_titolo())
	titolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(titolo)

	var riga := HBoxContainer.new()
	riga.add_theme_constant_override("separation", 18)
	riga.alignment = BoxContainer.ALIGNMENT_CENTER
	riga.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(riga)
	_tempo = UiStile.etichetta("1:00", 46, UiStile.TESTO, true)
	_tempo.custom_minimum_size = Vector2(150, 0)
	_tempo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tempo.pivot_offset = Vector2(75, 30)
	riga.add_child(_tempo)
	_conto = UiStile.etichetta("0", 46, UiStile.ORO_CHIARO, true)
	_conto.custom_minimum_size = Vector2(70, 0)
	_conto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_conto.pivot_offset = Vector2(35, 30)
	riga.add_child(_conto)
	var poste := UiStile.etichetta("machine\nposteggiate", 14, UiStile.TESTO_2)
	riga.add_child(poste)

	_barra = UiStile.barra(UiStile.VERDE, 12.0, float(MASSIMO))
	_barra.value = 0.0
	col.add_child(_barra)
	# Le tacche delle soglie, disegnate sopra alla barra.
	_soglie = Control.new()
	_soglie.custom_minimum_size = Vector2(0, 16)
	_soglie.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_soglie)
	var spiega := UiStile.etichetta(
		"3 = 'nu guaglione ca fatica pe' te  ·  5 = 'na piazza 'n omaggio  ·  1 = mazzate",
		12, UiStile.TESTO_2)
	spiega.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(spiega)

	_grande = Label.new()
	_grande.set_anchors_preset(Control.PRESET_CENTER)
	_grande.custom_minimum_size = Vector2(900, 160)
	_grande.position = Vector2(-450, -200)
	_grande.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_grande.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_grande.add_theme_font_override("font", UiStile.font_titolo())
	_grande.add_theme_font_size_override("font_size", 84)
	_grande.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_grande.add_theme_constant_override("outline_size", 18)
	_grande.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_grande.pivot_offset = Vector2(450, 80)
	_grande.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grande.visible = false
	add_child(_grande)
	call_deferred("_metti_tacche")


func _metti_tacche() -> void:
	for c in _soglie.get_children():
		c.queue_free()
	var largo: float = _barra.size.x
	if largo <= 1.0:
		largo = 438.0
	for s in [1, 3, 5]:
		var x: float = largo * float(s) / float(MASSIMO)
		var tacca := ColorRect.new()
		tacca.color = UiStile.ROSSO if s == 1 else (UiStile.GIALLO if s == 3 else UiStile.ORO_CHIARO)
		tacca.size = Vector2(3, 10)
		tacca.position = Vector2(x - 1.5, 0)
		tacca.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_soglie.add_child(tacca)
		var n := UiStile.etichetta(str(s), 11, tacca.color, true)
		n.position = Vector2(x - 4, 1)
		_soglie.add_child(n)


func tempo(secondi: float) -> void:
	var s: int = int(ceil(maxf(0.0, secondi)))
	_tempo.text = "%d:%02d" % [s / 60, s % 60]
	var poco: bool = secondi <= 10.0
	_tempo.add_theme_color_override("font_color", UiStile.ROSSO if poco else UiStile.TESTO)


## Un secondo è passato: negli ultimi dieci il tempo pulsa.
func battito(secondi: float) -> void:
	if secondi <= 10.0:
		_pulsa = 0.25


func conta(n: int) -> void:
	_conto.text = str(n)
	_barra.value = float(mini(n, MASSIMO))
	UiStile.colora_barra(_barra, UiStile.ORO_CHIARO if n >= 5
		else (UiStile.GIALLO if n >= 3 else UiStile.VERDE))
	_conto.scale = Vector2(1.5, 1.5)


func grande(testo: String, colore: Color = UiStile.ORO_CHIARO, durata: float = 1.0) -> void:
	_grande.text = testo
	_grande.add_theme_color_override("font_color", colore)
	_grande.visible = true
	_grande.scale = Vector2(1.35, 1.35)
	_grande_t = durata


func nascondi_pannello() -> void:
	_pannello.visible = false


func _process(delta: float) -> void:
	if _grande_t > 0.0:
		_grande_t -= delta
		_grande.scale = _grande.scale.lerp(Vector2.ONE, 1.0 - exp(-10.0 * delta))
		if _grande_t <= 0.0:
			_grande.visible = false
	_conto.scale = _conto.scale.lerp(Vector2.ONE, 1.0 - exp(-8.0 * delta))
	if _pulsa > 0.0:
		_pulsa -= delta
		var k: float = 1.0 + 0.18 * maxf(0.0, _pulsa / 0.25)
		_tempo.scale = Vector2(k, k)
	else:
		_tempo.scale = Vector2.ONE
