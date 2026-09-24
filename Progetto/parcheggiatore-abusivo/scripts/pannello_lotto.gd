extends CanvasLayer
## PannelloLotto — 'o banco d''o lotto
##
## **'A smorfia è 'a schedina.** La realtà del lotto non è la matematica —
## quella sta in `lotto.gd` — è **la griglia**: novanta numeri, e ognuno col
## suo nome. A Napoli non si punta sul 47, si punta su *'o muorto*.
##
## ## Chello ca s'è cagnato ê 0.62
##
## Il capo: *«Migliora il gioco del lotto al tabaccaio, non si capisce
## niente, non si capisce come vi si accede né come funziona»*.
##
## Aveva ragione su tutt'e due, e il secondo era peggio di quanto sembrasse:
##
## 1. **Comme se trase.** Il lotto stava sul tasto [2] del tabaccaio, dentro
##    a una riga di ottanta lettere, e il tabaccaio c'era in una piazza
##    sola. Adesso sta anche **in ogni bar** ([2]), il bancone e il bar
##    hanno l'insegna LOTTO, e il prompt lo dice per primo.
## 2. **Comme se joca.** Il pannello non spiegava niente e **usciva dallo
##    schermo** (novanta bottoni da 100x34 più il resto: a 648 di altezza i
##    bottoni per giocare non si vedevano). Adesso è in tre colonne:
##      - a sinistra **comme se joca** in quattro passi (quello che stai
##        facendo si accende), la tabella delle **quote** con la
##        probabilità vera accanto, e l'ultima estrazione della tua ruota
##        in palline;
##      - in mezzo la **ruota** e la **griglia** (numeri grossi; la smorfia
##        del numero sotto al mouse si legge nella riga sotto);
##      - a destra **'a schedina**, di carta: cosa hai giocato, quanto
##        metti, quanto pagherebbe, e il bottone GIOCA.
## 3. **Comm'è ghiuta.** L'esito della sera prima non lo diceva nessuno:
##    l'estrazione si faceva, i soldi (se c'erano) entravano, e basta.
##    Adesso l'esito sta nel riepilogo della sera e qui, sotto alla
##    schedina, giocata per giocata.

const Lotto := preload("res://scripts/lotto.gd")
const US := preload("res://scripts/ui_stile.gd")

const ORO := Color(0.95, 0.78, 0.34)
const CREMA := Color(0.93, 0.91, 0.87)
const SPENTO := Color(0.66, 0.63, 0.60)
const VERDE := Color(0.55, 0.92, 0.60)
const ROSSO := Color(1.0, 0.52, 0.45)
const CARTA := Color(0.97, 0.94, 0.86)
const INCHIOSTRO := Color(0.16, 0.12, 0.09)
const BLU_LOTTO := Color(0.13, 0.36, 0.72)

## La probabilità vera di fare la sorte su una ruota, "1 su N".
const PROBABILITA := [0, 18, 400, 11748, 511038, 43949268]

signal chiuso()

var _fondo: ColorRect
var _soldi: Label
var _passi: Array = []
var _palline: HBoxContainer
var _ultima_dida: Label
var _ritardi: Label
var _bot_ruote: Dictionary = {}
var _griglia: GridContainer
var _bot_num: Array = []
var _smorfia_sotto: Label
var _sch_ruota: Label
var _sch_numeri: VBoxContainer
var _sch_sorte: Label
var _sch_paga: Label
var _bot_punt: Dictionary = {}
var _bot_gioca: Button
var _esito: Label
var _aperte: Label
var _ajere: Label

var _scelti: Array = []
var _ruota: String = "Napoli"
var _puntata: int = 2
var _aperto: bool = false


func _ready() -> void:
	layer = 62
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_costruisci()
	GameManager.lotto_cagnato.connect(_aggiorna)


# ---------------------------------------------------------------------------
# Uno sulo pe' tutta 'a partita
# ---------------------------------------------------------------------------

static var _unico: CanvasLayer = null


## Apre il banco del lotto da qualunque posto (tabaccaio, bar). Il pannello
## si costruisce la prima volta e poi resta appeso alla radice.
static func apri_da(chi: Node) -> CanvasLayer:
	if _unico == null or not is_instance_valid(_unico):
		_unico = load("res://scripts/pannello_lotto.gd").new()
		_unico.name = "PannelloLotto"
		chi.get_tree().root.add_child(_unico)
	_unico.apri()
	return _unico


func apri() -> void:
	_aperto = true
	visible = true
	_scelti.clear()
	_esito.text = ""
	get_tree().paused = true
	GameManager.piglia_o_mouse(false)
	SoundManager.ui("ui_apri")
	_aggiorna()


func chiudi() -> void:
	if not _aperto:
		return
	_aperto = false
	visible = false
	get_tree().paused = false
	GameManager.piglia_o_mouse(true)
	SoundManager.ui("ui_chiudi")
	chiuso.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not _aperto:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		chiudi()


# ---------------------------------------------------------------------------
# 'A costruzione
# ---------------------------------------------------------------------------

func _costruisci() -> void:
	_fondo = ColorRect.new()
	_fondo.color = Color(0.02, 0.03, 0.06, 0.82)
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_fondo)

	var pan := PanelContainer.new()
	pan.set_anchors_preset(Control.PRESET_FULL_RECT)
	pan.offset_left = 14
	pan.offset_right = -14
	pan.offset_top = 12
	pan.offset_bottom = -12
	var st := US.box(Color(0.07, 0.08, 0.11, 0.98),
		Color(BLU_LOTTO.r, BLU_LOTTO.g, BLU_LOTTO.b, 0.9), 3, 16, 16.0, 12.0)
	st.shadow_color = Color(0, 0, 0, 0.5)
	st.shadow_size = 16
	pan.add_theme_stylebox_override("panel", st)
	add_child(pan)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	pan.add_child(col)

	# --- Testata ------------------------------------------------------------
	var testa := HBoxContainer.new()
	testa.add_theme_constant_override("separation", 12)
	col.add_child(testa)
	var logo := PanelContainer.new()
	logo.add_theme_stylebox_override("panel", US.box(BLU_LOTTO, Color(1, 1, 1, 0.9),
		2, 8, 12.0, 2.0))
	var lt := US.etichetta("LOTTO", 22, Color(1, 1, 1))
	lt.add_theme_font_override("font", US.font_titolo())
	lt.add_theme_constant_override("outline_size", 0)
	logo.add_child(lt)
	testa.add_child(logo)
	var tt := US.etichetta("'O banco d''o lotto", 22, ORO)
	tt.add_theme_font_override("font", US.font_titolo())
	testa.add_child(tt)
	var spinta := Control.new()
	spinta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	testa.add_child(spinta)
	testa.add_child(US.figura("euro", 20, ORO))
	_soldi = US.etichetta("", 20, ORO, true)
	testa.add_child(_soldi)
	var esci := Button.new()
	esci.text = "Chiudi  [Esc]"
	esci.custom_minimum_size = Vector2(150, 36)
	esci.pressed.connect(chiudi)
	testa.add_child(esci)

	# --- Tre colonne --------------------------------------------------------
	var corpo := HBoxContainer.new()
	corpo.add_theme_constant_override("separation", 14)
	corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(corpo)

	corpo.add_child(_colonna_sinistra())
	corpo.add_child(_colonna_mezzo())
	corpo.add_child(_colonna_destra())


func _scheda(larga: float = 0.0) -> Array:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", US.box(Color(1, 1, 1, 0.04),
		Color(1, 1, 1, 0.1), 1, 12, 12.0, 10.0))
	if larga > 0.0:
		p.custom_minimum_size = Vector2(larga, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	p.add_child(v)
	return [p, v]


func _titoletto(t: String) -> Label:
	var l := US.etichetta(t, 13, Color(0.62, 0.74, 0.95), true)
	return l


func _colonna_sinistra() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.custom_minimum_size = Vector2(262, 0)

	# 1. Comme se joca, in quattro passi.
	var s := _scheda()
	v.add_child(s[0])
	(s[1] as VBoxContainer).add_child(_titoletto("COMME SE JOCA"))
	var testi := [
		"Scigli 'a rota: 'a città addò se fa l'estrazione.",
		"Scigli 'a 1 a 5 nummere. 'A smorfia te dice che vonno dicere.",
		"Scigli quanto miette, 'a €1 a €20.",
		"GIOCA. Stasera, quanno vaje a durmì, se fa l'estrazione.",
	]
	for i in range(testi.size()):
		var riga := HBoxContainer.new()
		riga.add_theme_constant_override("separation", 8)
		var num := PanelContainer.new()
		num.add_theme_stylebox_override("panel", US.box(Color(1, 1, 1, 0.1),
			Color(0, 0, 0, 0), 0, 11, 7.0, 1.0))
		var nl := US.etichetta(str(i + 1), 14, Color(1, 1, 1), true)
		nl.add_theme_constant_override("outline_size", 0)
		num.add_child(nl)
		num.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		riga.add_child(num)
		var tl := US.etichetta(str(testi[i]), 12, CREMA)
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tl.custom_minimum_size = Vector2(200, 0)
		riga.add_child(tl)
		(s[1] as VBoxContainer).add_child(riga)
		_passi.append([num, tl])
	var regola := US.etichetta(
		"Se vence sulo si ESCENO TUTTE 'e nummere tuoje ncopp'â rota toia. L'esito sta dint'ô riepilogo d''a sera.",
		11, ORO)
	regola.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	regola.custom_minimum_size = Vector2(230, 0)
	(s[1] as VBoxContainer).add_child(regola)

	# 2. 'E quote.
	var q := _scheda()
	v.add_child(q[0])
	(q[1] as VBoxContainer).add_child(_titoletto("QUANTO PAVA €1"))
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 2)
	(q[1] as VBoxContainer).add_child(g)
	for n in range(1, 6):
		g.add_child(US.etichetta("%d · %s" % [n, Lotto.sorte(n)], 12, CREMA))
		var pl := US.etichetta("€%s" % _cifra(int(round(Lotto.QUOTE[n]))), 12, ORO, true)
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		g.add_child(pl)
		var pr := US.etichetta("1 su %s" % _cifra(int(PROBABILITA[n])), 12, SPENTO)
		pr.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		g.add_child(pr)

	# 3. L'ultima estrazione, in palline.
	var u := _scheda()
	v.add_child(u[0])
	_ultima_dida = _titoletto("")
	(u[1] as VBoxContainer).add_child(_ultima_dida)
	_palline = HBoxContainer.new()
	_palline.add_theme_constant_override("separation", 6)
	(u[1] as VBoxContainer).add_child(_palline)
	_ritardi = US.etichetta("", 12, ORO)
	_ritardi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ritardi.custom_minimum_size = Vector2(230, 0)
	(u[1] as VBoxContainer).add_child(_ritardi)
	return v


func _colonna_mezzo() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	v.add_child(_titoletto("1 · 'A ROTA"))
	var gr := GridContainer.new()
	gr.columns = 6
	gr.add_theme_constant_override("h_separation", 4)
	gr.add_theme_constant_override("v_separation", 4)
	v.add_child(gr)
	for r in Lotto.RUOTE:
		var b := Button.new()
		b.text = str(r)
		b.custom_minimum_size = Vector2(72, 26)
		b.add_theme_font_size_override("font_size", 12)
		b.focus_mode = Control.FOCUS_NONE
		var nome := str(r)
		b.pressed.connect(func():
			_ruota = nome
			_aggiorna())
		gr.add_child(b)
		_bot_ruote[nome] = b

	v.add_child(_titoletto("2 · 'E NUMMERE (fino a cinche)"))
	_griglia = GridContainer.new()
	# Dieci per riga, come il tabellone vero: nove righe da dieci.
	_griglia.columns = 10
	_griglia.add_theme_constant_override("h_separation", 3)
	_griglia.add_theme_constant_override("v_separation", 2)
	v.add_child(_griglia)
	for n in range(1, Lotto.NUMERI + 1):
		var b := Button.new()
		b.text = str(n)
		b.custom_minimum_size = Vector2(44, 27)
		b.add_theme_font_size_override("font_size", 14)
		b.focus_mode = Control.FOCUS_NONE
		b.tooltip_text = Lotto.nome_numero(n)
		var nv: int = n
		b.pressed.connect(func(): _tocca(nv))
		b.mouse_entered.connect(func(): _mostra_smorfia(nv))
		_griglia.add_child(b)
		_bot_num.append(b)

	# La smorfia del numero sotto al mouse: grossa, perché è il motivo per
	# cui uno sceglie quel numero.
	_smorfia_sotto = US.etichetta("Passa cu 'o mouse ncopp'a 'nu nummero: 'a smorfia te dice che vo' dicere.",
		15, CREMA)
	_smorfia_sotto.add_theme_stylebox_override("normal", US.box(Color(1, 1, 1, 0.05),
		Color(1, 1, 1, 0.08), 1, 10, 12.0, 5.0))
	v.add_child(_smorfia_sotto)

	var az := HBoxContainer.new()
	az.add_theme_constant_override("separation", 8)
	v.add_child(az)
	# **'O nummero d''a smorfia a sorte.** Chi non conosce la smorfia non sa
	# da dove cominciare, e restare davanti a novanta caselle senza sapere
	# che fare è il modo più veloce per chiudere il pannello.
	var sogno := Button.new()
	sogno.text = "Damme tu tre nummere"
	sogno.custom_minimum_size = Vector2(200, 32)
	sogno.pressed.connect(_a_sciorte)
	az.add_child(sogno)
	var pulisci := Button.new()
	pulisci.text = "Scancella"
	pulisci.custom_minimum_size = Vector2(120, 32)
	pulisci.pressed.connect(func():
		_scelti.clear()
		_aggiorna())
	az.add_child(pulisci)
	return v


func _colonna_destra() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.custom_minimum_size = Vector2(252, 0)

	# 'A schedina: un foglietto di carta.
	var sch := PanelContainer.new()
	var st := US.box(CARTA, Color(0.62, 0.52, 0.36), 2, 6, 14.0, 12.0)
	st.shadow_color = Color(0, 0, 0, 0.4)
	st.shadow_size = 8
	st.shadow_offset = Vector2(2, 4)
	sch.add_theme_stylebox_override("panel", st)
	v.add_child(sch)
	var s := VBoxContainer.new()
	s.add_theme_constant_override("separation", 4)
	sch.add_child(s)
	var t := US.etichetta("'A SCHEDINA", 16, BLU_LOTTO)
	t.add_theme_font_override("font", US.font_titolo())
	t.add_theme_constant_override("outline_size", 0)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_child(t)
	_sch_ruota = _carta_riga("", 14, true)
	s.add_child(_sch_ruota)
	_sch_numeri = VBoxContainer.new()
	_sch_numeri.add_theme_constant_override("separation", 1)
	s.add_child(_sch_numeri)
	_sch_sorte = _carta_riga("", 14, true)
	s.add_child(_sch_sorte)
	s.add_child(_carta_riga("3 · QUANTO MIETTE", 12, true))
	var pr := HBoxContainer.new()
	pr.add_theme_constant_override("separation", 3)
	pr.alignment = BoxContainer.ALIGNMENT_CENTER
	s.add_child(pr)
	for q in [1, 2, 5, 10, 20]:
		var b := Button.new()
		b.text = "€%d" % q
		b.custom_minimum_size = Vector2(40, 26)
		b.add_theme_font_size_override("font_size", 12)
		b.focus_mode = Control.FOCUS_NONE
		var qv: int = q
		b.pressed.connect(func():
			_puntata = qv
			_aggiorna())
		pr.add_child(b)
		_bot_punt[q] = b
	_sch_paga = _carta_riga("", 15, true)
	_sch_paga.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sch_paga.custom_minimum_size = Vector2(210, 0)
	s.add_child(_sch_paga)

	_bot_gioca = Button.new()
	_bot_gioca.text = "4 · GIOCA"
	_bot_gioca.custom_minimum_size = Vector2(0, 44)
	_bot_gioca.add_theme_font_size_override("font_size", 18)
	var verde := US.box(Color(0.22, 0.62, 0.34), Color(0.5, 0.9, 0.6), 2, 10, 12.0, 6.0)
	var verde_h := US.box(Color(0.28, 0.72, 0.42), Color(0.8, 1.0, 0.8), 2, 10, 12.0, 6.0)
	_bot_gioca.add_theme_stylebox_override("normal", verde)
	_bot_gioca.add_theme_stylebox_override("hover", verde_h)
	_bot_gioca.add_theme_color_override("font_color", Color(1, 1, 1))
	_bot_gioca.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	_bot_gioca.pressed.connect(_gioca)
	v.add_child(_bot_gioca)

	_esito = US.etichetta("", 13, VERDE)
	_esito.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_esito.custom_minimum_size = Vector2(240, 0)
	v.add_child(_esito)

	var pe := _scheda()
	v.add_child(pe[0])
	(pe[1] as VBoxContainer).add_child(_titoletto("PE' STASERA"))
	_aperte = US.etichetta("", 12, CREMA)
	_aperte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aperte.custom_minimum_size = Vector2(220, 0)
	(pe[1] as VBoxContainer).add_child(_aperte)

	var aj := _scheda()
	v.add_child(aj[0])
	(aj[1] as VBoxContainer).add_child(_titoletto("COMM'È GHIUTA AJERE"))
	_ajere = US.etichetta("", 12, CREMA)
	_ajere.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ajere.custom_minimum_size = Vector2(220, 0)
	(aj[1] as VBoxContainer).add_child(_ajere)
	return v


func _carta_riga(t: String, corpo: int, grassa: bool = false) -> Label:
	var l := US.etichetta(t, corpo, INCHIOSTRO, grassa)
	l.add_theme_constant_override("outline_size", 0)
	return l


# ---------------------------------------------------------------------------
# 'A logica
# ---------------------------------------------------------------------------

func _tocca(n: int) -> void:
	if _scelti.has(n):
		_scelti.erase(n)
		SoundManager.ui("ui_click")
	elif _scelti.size() < 5:
		_scelti.append(n)
		_scelti.sort()
		SoundManager.play("pop", -12.0, 1.3)
	else:
		SoundManager.ui("ui_errore")
		_esito.text = "Cchiù 'e cinche nummere nun se ponno. Levane uno."
		_esito.add_theme_color_override("font_color", ROSSO)
	_mostra_smorfia(n)
	_aggiorna()


func _mostra_smorfia(n: int) -> void:
	if _smorfia_sotto == null:
		return
	_smorfia_sotto.text = "%d  →  %s" % [n, Lotto.smorfia(n)]


## Tre numeri a caso, che è come si gioca davvero quando non si è sognato
## niente.
func _a_sciorte() -> void:
	_scelti.clear()
	while _scelti.size() < 3:
		var n: int = randi_range(1, Lotto.NUMERI)
		if not _scelti.has(n):
			_scelti.append(n)
	_scelti.sort()
	SoundManager.play("pop", -10.0, 0.9)
	_aggiorna()


func _gioca() -> void:
	var esito: Dictionary = GameManager.gioca_lotto(_ruota, _scelti, _puntata)
	if not bool(esito.get("ok", false)):
		SoundManager.ui("ui_errore")
		_esito.text = str(esito.get("pecche", "Nun se pò."))
		_esito.add_theme_color_override("font_color", ROSSO)
		return
	SoundManager.play("coin", -4.0)
	SoundManager.ui("ui_ok")
	_esito.text = "Giocato! %s ncopp'a %s pe' €%d. Stasera, quanno vaje a durmì, se vede." % [
		str(esito.get("sorte", "")).to_upper(), _ruota, _puntata]
	_esito.add_theme_color_override("font_color", VERDE)
	_scelti.clear()
	_aggiorna()


func _aggiorna() -> void:
	if not is_instance_valid(_soldi):
		return
	_soldi.text = "%d" % GameManager.money

	# I quattro passi: si accende quello che tocca fare adesso.
	var passo: int = 1 if _scelti.is_empty() else 3
	for i in range(_passi.size()):
		var num: PanelContainer = _passi[i][0]
		var fatto: bool = i == 0 or (i == 1 and not _scelti.is_empty()) \
			or (i == 2 and not _scelti.is_empty())
		var ora: bool = i == passo or (i == 3 and not _scelti.is_empty())
		var c := Color(1, 1, 1, 0.1)
		if ora:
			c = ORO
		elif fatto:
			c = Color(0.3, 0.62, 0.4)
		num.add_theme_stylebox_override("panel", US.box(c, Color(0, 0, 0, 0), 0,
			11, 7.0, 1.0))

	# Le ruote e le puntate scelte si accendono.
	for r in _bot_ruote:
		_accendi(_bot_ruote[r], r == _ruota)
	for q in _bot_punt:
		_accendi(_bot_punt[q], int(q) == _puntata)

	# L'ultima estrazione della ruota scelta, in palline.
	for c in _palline.get_children():
		_palline.remove_child(c)
		c.queue_free()
	var u: Dictionary = GameManager.lotto_ultima
	var usciti_ieri: Array = []
	if u.is_empty():
		_ultima_dida.text = "ULTIMA ESTRAZIONE"
		var nessuna := US.etichetta("Ancora nisciuna. 'A primma è stasera.", 12, SPENTO)
		_palline.add_child(nessuna)
	else:
		usciti_ieri = Dictionary(u.get("numeri", {})).get(_ruota, [])
		_ultima_dida.text = "ULTIMA ESTRAZIONE · %s · juorno %d" % [
			_ruota.to_upper(), int(u.get("giornata", 0))]
		for n in usciti_ieri:
			_palline.add_child(_pallina(int(n)))

	# 'O quadernetto: 'e numere ca nun esceno 'a 'nu pezzo. È una fallacia
	# (la ruota non ricorda niente), ma è quella che fa giocare.
	var rit: Array = GameManager.lotto_ritardatarie(_ruota, 4)
	var ritardate: Array = []
	for r in rit:
		if int(r["ritardo"]) > 0:
			ritardate.append("%d (%d)" % [int(r["n"]), int(r["ritardo"])])
	_ritardi.text = "" if ritardate.is_empty() else \
		"Ritardatarie: %s" % "  ".join(ritardate)

	# La griglia.
	for i in range(_bot_num.size()):
		var n: int = i + 1
		var b: Button = _bot_num[i]
		if _scelti.has(n):
			b.add_theme_color_override("font_color", Color(0.15, 0.10, 0.04))
			b.add_theme_color_override("font_hover_color", Color(0.15, 0.10, 0.04))
			b.add_theme_stylebox_override("normal", US.box(ORO, ORO.lightened(0.3), 2, 8, 2.0, 2.0))
			b.add_theme_stylebox_override("hover", US.box(ORO.lightened(0.1), Color(1, 1, 1), 2, 8, 2.0, 2.0))
		elif usciti_ieri.has(n):
			b.add_theme_color_override("font_color", VERDE)
			b.remove_theme_color_override("font_hover_color")
			b.add_theme_stylebox_override("normal", US.box(Color(0.12, 0.2, 0.14, 0.95),
				Color(VERDE.r, VERDE.g, VERDE.b, 0.6), 1, 8, 2.0, 2.0))
			b.remove_theme_stylebox_override("hover")
		else:
			b.remove_theme_color_override("font_color")
			b.remove_theme_color_override("font_hover_color")
			b.remove_theme_stylebox_override("normal")
			b.remove_theme_stylebox_override("hover")

	# 'A schedina.
	_sch_ruota.text = "1 · Rota: %s" % _ruota.to_upper()
	for c in _sch_numeri.get_children():
		_sch_numeri.remove_child(c)
		c.queue_free()
	if _scelti.is_empty():
		var l := _carta_riga("2 · Clicca 'e nummere ncopp'â griglia", 13)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(210, 0)
		_sch_numeri.add_child(l)
		_sch_sorte.text = ""
		_sch_paga.text = ""
		_bot_gioca.disabled = true
	else:
		for n in _scelti:
			var l2 := _carta_riga("  %2d  %s" % [int(n), Lotto.smorfia(int(n))], 13)
			l2.clip_text = true
			l2.custom_minimum_size = Vector2(210, 0)
			_sch_numeri.add_child(l2)
		_sch_sorte.text = "Sorte: %s (%d nummer%s)" % [
			Lotto.sorte(_scelti.size()).to_upper(), _scelti.size(),
			"o" if _scelti.size() == 1 else "e"]
		_sch_paga.text = "Si escono tutte: pigli €%s" % _cifra(
			GameManager.lotto_sogno(_scelti, _puntata))
		_sch_paga.add_theme_color_override("font_color", Color(0.1, 0.42, 0.18))
		_bot_gioca.disabled = GameManager.money < _puntata
		_bot_gioca.text = "4 · GIOCA  €%d" % _puntata

	# Le giocate già fatte per stasera.
	var quante: int = GameManager.lotto_quante_aperte()
	if quante == 0:
		_aperte.text = "Nisciuna giocata pe' stasera."
		_aperte.add_theme_color_override("font_color", SPENTO)
	else:
		var voci: Array = []
		for g in GameManager.lotto_giocate:
			var nn: Array = []
			for n in g["numeri"]:
				nn.append(str(int(n)))
			voci.append("• %s  %s  (€%d)" % [str(g["ruota"]), "-".join(nn),
				int(g["puntata"])])
		_aperte.text = "\n".join(voci)
		_aperte.add_theme_color_override("font_color", CREMA)

	# Com'è andata la sera prima, giocata per giocata.
	_ajere.text = esiti_testo(false)


## L'esito delle giocate dell'ultima estrazione, riga per riga. La usa anche
## il riepilogo della sera (`corto` = senza i numeri usciti).
static func esiti_testo(corto: bool) -> String:
	var es: Array = GameManager.lotto_esiti
	if es.is_empty():
		return "Nisciuna giocata all'ultima estrazione."
	var righe: Array = []
	for e in es:
		var nn: Array = []
		var usciti: Array = e.get("usciti", [])
		for n in e.get("numeri", []):
			nn.append(("%d✓" if usciti.has(int(n)) else "%d") % int(n))
		var v: int = int(e.get("vinto", 0))
		var coda: String = ("VINTO €%s!" % _cifra_s(v)) if v > 0 else "niente"
		righe.append("• %s %s (€%d): %s" % [str(e.get("ruota", "")),
			"-".join(nn), int(e.get("puntata", 0)), coda])
	var _c := corto
	return "\n".join(righe)


func _accendi(b: Button, si: bool) -> void:
	if si:
		b.add_theme_stylebox_override("normal", US.box(BLU_LOTTO, Color(1, 1, 1, 0.8),
			2, 8, 6.0, 2.0))
		b.add_theme_color_override("font_color", Color(1, 1, 1))
	else:
		b.remove_theme_stylebox_override("normal")
		b.remove_theme_color_override("font_color")


func _pallina(n: int) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", US.box(Color(0.98, 0.97, 0.94),
		BLU_LOTTO, 3, 16, 4.0, 3.0))
	p.custom_minimum_size = Vector2(38, 32)
	var l := US.etichetta(str(n), 15, BLU_LOTTO, true)
	l.add_theme_constant_override("outline_size", 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	p.tooltip_text = Lotto.nome_numero(n)
	return p


## Le cifre grosse con i punti: "120.000" si legge, "120000" no.
func _cifra(n: int) -> String:
	return _cifra_s(n)


static func _cifra_s(n: int) -> String:
	var s := str(n)
	var fuori := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		fuori = s[i] + fuori
		c += 1
		if c % 3 == 0 and i > 0:
			fuori = "." + fuori
	return fuori
