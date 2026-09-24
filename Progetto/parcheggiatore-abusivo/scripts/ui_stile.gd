extends RefCounted
class_name UiStile
## **'O stile d''a interfaccia** (0.62).
##
## Il capo: *«Rivedi l'intera UI per farla più leggibile e bella possibile»*.
##
## Il tema di progetto (`assets/ui/tema.tres`, generato da
## `tools/genera_tema.gd`) veste da solo bottoni, pannelli, barre e cursori.
## Qui ci sono i pezzi che un tema non sa fare: la scheda semitrasparente
## dell'HUD, la pillola dietro a una scritta, il **tasto** disegnato
## ([E] diventa un tastino vero), le icone del pacchetto *FREE modern ui
## elements* e le tre voci del carattere Poppins.
##
## Tutto statico: si chiama `UiStile.scheda()`, `UiStile.tasto("E")`, ecc.

const ORO := Color(0.93, 0.72, 0.31)
const ORO_CHIARO := Color(1.0, 0.86, 0.52)
const INK := Color(0.075, 0.08, 0.105, 0.93)
const TESTO := Color(0.965, 0.945, 0.905)
const TESTO_2 := Color(0.74, 0.71, 0.66)
const VERDE := Color(0.40, 0.86, 0.50)
const GIALLO := Color(1.0, 0.82, 0.30)
const ARANCIO := Color(1.0, 0.62, 0.30)
const ROSSO := Color(1.0, 0.38, 0.32)
const AZZURRO := Color(0.46, 0.76, 1.0)

const FONT_TESTO := "res://assets/ui/font_testo.tres"
const FONT_GRASSETTO := "res://assets/ui/font_grassetto.tres"
const FONT_TITOLO := "res://assets/ui/font_titolo.tres"
const ICONE := "res://assets/ui/icone/%s.png"

static var _cache: Dictionary = {}


static func _carica(p: String) -> Resource:
	if _cache.has(p):
		return _cache[p]
	var r: Resource = load(p) if ResourceLoader.exists(p) else null
	_cache[p] = r
	return r


static func font_testo() -> Font:
	return _carica(FONT_TESTO) as Font


static func font_grassetto() -> Font:
	return _carica(FONT_GRASSETTO) as Font


static func font_titolo() -> Font:
	return _carica(FONT_TITOLO) as Font


## L'icona bianca `nome` (128 px, si tinge con `modulate`). Null se manca.
static func icona(nome: String) -> Texture2D:
	return _carica(ICONE % nome) as Texture2D


## Uno `StyleBoxFlat` arrotondato con i margini dentro.
static func box(bg: Color, bordo: Color = Color(0, 0, 0, 0), spessore: int = 0,
		raggio: int = 10, margine_x: float = 10.0,
		margine_y: float = 6.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = bordo
	s.set_border_width_all(spessore)
	s.set_corner_radius_all(raggio)
	s.anti_aliasing = true
	s.corner_detail = 6
	s.content_margin_left = margine_x
	s.content_margin_right = margine_x
	s.content_margin_top = margine_y
	s.content_margin_bottom = margine_y
	return s


## La scheda dell'HUD: scura, mezza trasparente, col filo chiaro. Sta sopra
## al 3D e deve far leggere quello che c'è dentro senza nascondere la città.
static func scheda() -> StyleBoxFlat:
	var s := box(Color(0.05, 0.055, 0.075, 0.66), Color(1, 1, 1, 0.09), 1, 12,
		12.0, 9.0)
	s.shadow_color = Color(0, 0, 0, 0.25)
	s.shadow_size = 6
	return s


## La pillola dietro a una scritta a schermo (cartelli, frecce, prompt).
static func pillola(bordo: Color = Color(1, 1, 1, 0.12),
		alpha: float = 0.72) -> StyleBoxFlat:
	var s := box(Color(0.05, 0.055, 0.075, alpha), bordo, 1, 16, 16.0, 6.0)
	return s


## Veste una Label da pillola: sfondo scuro arrotondato dietro al testo.
static func a_pillola(l: Label, bordo: Color = Color(1, 1, 1, 0.12),
		alpha: float = 0.72) -> void:
	l.add_theme_stylebox_override("normal", pillola(bordo, alpha))


static func etichetta(testo: String, corpo: int = 16,
		colore: Color = TESTO, grassetto: bool = false) -> Label:
	var l := Label.new()
	l.text = testo
	l.add_theme_font_size_override("font_size", corpo)
	if grassetto:
		l.add_theme_font_override("font", font_grassetto())
	l.add_theme_color_override("font_color", colore)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func figura(nome: String, lato: float = 18.0,
		colore: Color = TESTO) -> TextureRect:
	var t := TextureRect.new()
	t.texture = icona(nome)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(lato, lato)
	t.modulate = colore
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return t


## Una barra sottile e arrotondata, col colore del pieno.
static func barra(colore: Color, alta: float = 9.0, massimo: float = 100.0) -> ProgressBar:
	var b := ProgressBar.new()
	b.min_value = 0.0
	b.max_value = massimo
	b.value = massimo
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, alta)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := box(Color(0.0, 0.0, 0.0, 0.45), Color(1, 1, 1, 0.08), 1,
		int(alta * 0.5), 0.0, 0.0)
	b.add_theme_stylebox_override("background", bg)
	colora_barra(b, colore)
	return b


static func colora_barra(b: ProgressBar, colore: Color) -> void:
	if b == null:
		return
	var alta: float = maxf(b.custom_minimum_size.y, 6.0)
	var st := box(colore, Color(0, 0, 0, 0), 0, int(alta * 0.5), 0.0, 0.0)
	b.add_theme_stylebox_override("fill", st)


# ---------------------------------------------------------------------------
# 'E tasti
# ---------------------------------------------------------------------------

## Un tastino disegnato: il nome del tasto dentro a un riquadro chiaro con
## l'ombra sotto, come sulla tastiera vera. Si riconosce a colpo d'occhio
## anche in mezzo a una frase lunga.
static func tasto(nome: String, corpo: int = 15) -> PanelContainer:
	var p := PanelContainer.new()
	var s := box(Color(0.95, 0.93, 0.88, 0.97), Color(0.55, 0.48, 0.36, 1.0), 0,
		6, 7.0, 1.0)
	s.border_width_bottom = 3
	s.content_margin_bottom = 3.0
	p.add_theme_stylebox_override("panel", s)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var l := Label.new()
	l.text = nome
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font_grassetto())
	l.add_theme_font_size_override("font_size", corpo - 1)
	l.add_theme_color_override("font_color", Color(0.12, 0.1, 0.08))
	l.add_theme_constant_override("outline_size", 0)
	l.custom_minimum_size = Vector2(corpo * 0.9, 0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	return p


## Spezza un testo in pezzi di testo e tasti: `"[E] parla · [G] arruobbe"`
## → `[["t","E"], ["s"," parla"], ["sep"], ["t","G"], ["s"," arruobbe"]]`.
## Un tasto è quello che sta fra parentesi quadre ed è corto (fino a dodici
## lettere): "[clic 'a carta toia]" resta testo.
static func pezzi(testo: String) -> Array:
	var fuori: Array = []
	var segmenti := dividi(testo)
	var re := RegEx.new()
	re.compile("\\[([^\\]]{1,12})\\]")
	for si in range(segmenti.size()):
		if si > 0:
			fuori.append(["sep"])
		var seg: String = segmenti[si]
		var da := 0
		for m in re.search_all(seg):
			var prima := seg.substr(da, m.get_start() - da)
			if prima.strip_edges() != "":
				fuori.append(["s", prima.strip_edges()])
			fuori.append(["t", m.get_string(1)])
			da = m.get_end()
		var dopo := seg.substr(da)
		if dopo.strip_edges() != "":
			fuori.append(["s", dopo.strip_edges()])
	return fuori


## Divide su " · " solo fuori dalle parentesi: "(berlina · seria)" è un
## pezzo solo, non due azioni.
static func dividi(testo: String) -> PackedStringArray:
	var fuori := PackedStringArray()
	var fondo := 0
	var da := 0
	var i := 0
	while i < testo.length():
		var c := testo[i]
		if c == "(" or c == "[" or c == "«" or c == "\"":
			if c == "\"":
				fondo = 1 - fondo if fondo <= 1 else fondo
			else:
				fondo += 1
		elif c == ")" or c == "]" or c == "»":
			fondo = maxi(0, fondo - 1)
		elif fondo == 0 and testo.substr(i, 3) == " · ":
			fuori.append(testo.substr(da, i - da))
			da = i + 3
			i += 3
			continue
		i += 1
	fuori.append(testo.substr(da))
	return fuori
