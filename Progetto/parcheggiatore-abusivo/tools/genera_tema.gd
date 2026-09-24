extends SceneTree
## Genera `assets/ui/tema.tres`, il tema di tutta l'interfaccia (0.62).
##
## Il capo: *«Rivedi l'intera UI per farla più leggibile e bella possibile.
## Ti ho messo dei nuovi pack in cartella per la UI»*.
##
## Fino alla 0.61 il gioco non aveva un tema: ogni pannello si faceva i suoi
## `StyleBoxFlat` a mano, e tutto il resto (bottoni, barre, cursori del
## volume) usava il grigio di fabbrica di Godot col suo carattere. Qui si
## scrive un tema solo, che `project.godot` dà a tutti:
##
##   - il carattere è **Poppins** (dal pacchetto *Extra Clean UI*), con
##     DejaVu Sans dietro per le frecce, le stelle e i simboli che Poppins
##     non ha;
##   - pannelli scuri e caldi con il filo d'oro, bottoni che si accendono
##     d'oro sotto al mouse, barre arrotondate.
##
## Si rigenera con:
##   godot4 --headless --path . --script res://tools/genera_tema.gd

const INK := Color(0.075, 0.08, 0.105, 0.93)
const INK_2 := Color(0.12, 0.125, 0.16, 0.96)
const INK_3 := Color(0.17, 0.175, 0.22, 0.98)
const ORO := Color(0.93, 0.72, 0.31)
const ORO_TENUE := Color(0.93, 0.72, 0.31, 0.45)
const TESTO := Color(0.965, 0.945, 0.905)
const TESTO_2 := Color(0.74, 0.71, 0.66)
const SCURO := Color(0.09, 0.07, 0.05)


func _initialize() -> void:
	var t := Theme.new()

	var regular: FontFile = load("res://assets/ui/fonts/Poppins-Regular.ttf")
	var black: FontFile = load("res://assets/ui/fonts/Poppins-Black.ttf")
	var dejavu: FontFile = load("res://assets/ui/fonts/DejaVuSans.ttf")
	var dejavu_b: FontFile = load("res://assets/ui/fonts/DejaVuSans-Bold.ttf")
	for f in [regular, black, dejavu, dejavu_b]:
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		f.hinting = TextServer.HINTING_LIGHT
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
		f.generate_mipmaps = false

	var testo := FontVariation.new()
	testo.base_font = regular
	testo.fallbacks = [dejavu]
	var grassetto := FontVariation.new()
	grassetto.base_font = regular
	grassetto.variation_embolden = 0.55
	grassetto.fallbacks = [dejavu_b]
	ResourceSaver.save(testo, "res://assets/ui/font_testo.tres")
	ResourceSaver.save(grassetto, "res://assets/ui/font_grassetto.tres")
	var titolo := FontVariation.new()
	titolo.base_font = black
	titolo.fallbacks = [dejavu_b]
	ResourceSaver.save(titolo, "res://assets/ui/font_titolo.tres")
	testo = load("res://assets/ui/font_testo.tres")
	grassetto = load("res://assets/ui/font_grassetto.tres")

	t.default_font = testo
	t.default_font_size = 16

	# --- Label -----------------------------------------------------------
	t.set_color("font_color", "Label", TESTO)
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.62))
	t.set_constant("outline_size", "Label", 3)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.0))
	t.set_constant("line_spacing", "Label", 1)

	# --- Panel / PanelContainer -----------------------------------------
	var pan := _box(INK, ORO_TENUE, 2, 14)
	pan.shadow_color = Color(0, 0, 0, 0.42)
	pan.shadow_size = 10
	pan.shadow_offset = Vector2(0, 4)
	pan.set_content_margin_all(14)
	t.set_stylebox("panel", "Panel", pan)
	t.set_stylebox("panel", "PanelContainer", pan)

	# --- Button ------------------------------------------------------------
	var b_norm := _box(INK_2, Color(1, 1, 1, 0.14), 2, 10)
	b_norm.content_margin_left = 16
	b_norm.content_margin_right = 16
	b_norm.content_margin_top = 8
	b_norm.content_margin_bottom = 8
	var b_hov := b_norm.duplicate() as StyleBoxFlat
	b_hov.bg_color = INK_3
	b_hov.border_color = ORO
	var b_pre := b_norm.duplicate() as StyleBoxFlat
	b_pre.bg_color = ORO
	b_pre.border_color = ORO.lightened(0.2)
	var b_dis := b_norm.duplicate() as StyleBoxFlat
	b_dis.bg_color = Color(INK_2.r, INK_2.g, INK_2.b, 0.55)
	b_dis.border_color = Color(1, 1, 1, 0.06)
	var b_foc := _box(Color(0, 0, 0, 0), ORO, 3, 10)
	b_foc.draw_center = false
	b_foc.set_expand_margin_all(2)
	t.set_stylebox("normal", "Button", b_norm)
	t.set_stylebox("hover", "Button", b_hov)
	t.set_stylebox("pressed", "Button", b_pre)
	t.set_stylebox("hover_pressed", "Button", b_pre)
	t.set_stylebox("disabled", "Button", b_dis)
	t.set_stylebox("focus", "Button", b_foc)
	t.set_font("font", "Button", grassetto)
	t.set_font_size("font_size", "Button", 16)
	t.set_color("font_color", "Button", TESTO)
	t.set_color("font_hover_color", "Button", Color(1.0, 0.93, 0.74))
	t.set_color("font_focus_color", "Button", Color(1.0, 0.93, 0.74))
	t.set_color("font_pressed_color", "Button", SCURO)
	t.set_color("font_hover_pressed_color", "Button", SCURO)
	t.set_color("font_disabled_color", "Button", Color(TESTO_2.r, TESTO_2.g, TESTO_2.b, 0.5))
	t.set_color("font_outline_color", "Button", Color(0, 0, 0, 0))
	t.set_constant("outline_size", "Button", 0)
	t.set_constant("h_separation", "Button", 8)

	# --- ProgressBar -------------------------------------------------------
	var pb_bg := _box(Color(0.03, 0.035, 0.05, 0.78), Color(1, 1, 1, 0.10), 1, 6)
	pb_bg.set_content_margin_all(0)
	var pb_fill := _box(Color(0.36, 0.82, 0.48), Color(0, 0, 0, 0), 0, 6)
	pb_fill.set_content_margin_all(0)
	t.set_stylebox("background", "ProgressBar", pb_bg)
	t.set_stylebox("fill", "ProgressBar", pb_fill)
	t.set_font_size("font_size", "ProgressBar", 11)
	t.set_color("font_color", "ProgressBar", TESTO)

	# --- HSlider (il volume) ----------------------------------------------
	var sl := _box(Color(0.03, 0.035, 0.05, 0.85), Color(1, 1, 1, 0.12), 1, 5)
	sl.content_margin_top = 4
	sl.content_margin_bottom = 4
	var sl_on := _box(ORO, Color(0, 0, 0, 0), 0, 5)
	sl_on.content_margin_top = 4
	sl_on.content_margin_bottom = 4
	t.set_stylebox("slider", "HSlider", sl)
	t.set_stylebox("grabber_area", "HSlider", sl_on)
	t.set_stylebox("grabber_area_highlight", "HSlider", sl_on)
	var pomo := _pomello(ORO)
	var pomo_on := _pomello(Color(1.0, 0.9, 0.62))
	t.set_icon("grabber", "HSlider", pomo)
	t.set_icon("grabber_highlight", "HSlider", pomo_on)

	# --- Scrollbar -----------------------------------------------------------
	var sc := _box(Color(0, 0, 0, 0.25), Color(0, 0, 0, 0), 0, 4)
	var sc_g := _box(Color(1, 1, 1, 0.22), Color(0, 0, 0, 0), 0, 4)
	var sc_gh := _box(ORO_TENUE, Color(0, 0, 0, 0), 0, 4)
	for cl in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", cl, sc)
		t.set_stylebox("grabber", cl, sc_g)
		t.set_stylebox("grabber_highlight", cl, sc_gh)
		t.set_stylebox("grabber_pressed", cl, sc_gh)

	# --- Tooltip ---------------------------------------------------------------
	var tip := _box(INK_2, ORO_TENUE, 1, 8)
	tip.set_content_margin_all(8)
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", TESTO)

	# --- LineEdit ---------------------------------------------------------------
	var le := _box(Color(0.03, 0.035, 0.05, 0.85), Color(1, 1, 1, 0.16), 2, 8)
	le.set_content_margin_all(8)
	var le_f := le.duplicate() as StyleBoxFlat
	le_f.border_color = ORO
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", le_f)

	var err := ResourceSaver.save(t, "res://assets/ui/tema.tres")
	print("tema salvato: %d" % err)
	quit()


func _box(bg: Color, bordo: Color, spessore: int, raggio: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = bordo
	s.set_border_width_all(spessore)
	s.set_corner_radius_all(raggio)
	s.anti_aliasing = true
	s.corner_detail = 6
	return s


func _pomello(c: Color) -> ImageTexture:
	var n := 18
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var r := n * 0.5
	for y in range(n):
		for x in range(n):
			var d := Vector2(x + 0.5 - r, y + 0.5 - r).length()
			var a := clampf(r - 0.5 - d, 0.0, 1.0)
			var bordo := clampf(r - 3.0 - d, 0.0, 1.0)
			var col := c.lerp(Color(1, 1, 1), 0.0) if bordo > 0.0 else Color(0.1, 0.08, 0.05)
			img.set_pixel(x, y, Color(col.r, col.g, col.b, a))
	return ImageTexture.create_from_image(img)
