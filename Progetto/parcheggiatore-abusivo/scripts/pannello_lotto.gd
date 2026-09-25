extends CanvasLayer
## PannelloLotto — 'o banco d''o lotto ncopp'ô tabaccaio
##
## **'A smorfia è 'a schedina.**
##
## Il capo ha chiesto il lotto *"in modo completo come nella realtà"*. La
## realtà del lotto non è la matematica — quella sta in `lotto.gd` — è
## **la griglia**: novanta caselle, e sotto a ogni numero il suo nome. A
## Napoli non si punta sul 47, si punta su *'o muorto*, e chi apre questo
## pannello deve poter cercare il numero che ha sognato invece della
## cifra.
##
## Quindi novanta caselle grandi abbastanza da leggerci due parole sotto,
## e la ruota e la puntata come due righe di bottoni sopra. Niente menu a
## tendina: un tabaccaio non ha i menu a tendina.
##
## **Chello ca se vede, e pecché.** Tre cose, in quest'ordine:
##
##   1. **l'estrazione 'e ajere** — è la prima cosa che uno guarda quando
##      entra al tabaccaio, prima ancora di decidere che giocare;
##   2. **'a schedina 'e mo'** — quanti numeri hai scelto, che sorte fa,
##      e **quanto pagherebbe**. Il numero grosso in giallo è la ragione
##      per cui uno gioca, e nasconderlo sarebbe disonesto in tutti e due
##      i sensi;
##   3. **'e giocate 'e stasera** — quelle già fatte, che si vedranno
##      all'estrazione della sera.

const Lotto := preload("res://scripts/lotto.gd")

const LARGH: float = 1060.0
const ORO := Color(0.95, 0.78, 0.34)
const CREMA := Color(0.93, 0.91, 0.87)
const SPENTO := Color(0.66, 0.63, 0.60)
const VERDE := Color(0.55, 0.92, 0.60)
const ROSSO := Color(1.0, 0.52, 0.45)

var _fondo: ColorRect
var _pannello: PanelContainer
var _titolo: Label
var _ultima: Label
var _ritardi: Label
var _griglia: GridContainer
var _bot_num: Array = []
var _riga_ruote: HBoxContainer
var _riga_punt: HBoxContainer
var _schedina: Label
var _aperte: Label
var _bot_gioca: Button
var _pie: Label

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


func apri() -> void:
	_aperto = true
	visible = true
	_scelti.clear()
	get_tree().paused = true
	GameManager.piglia_o_mouse(false)
	_aggiorna()


func chiudi() -> void:
	if not _aperto:
		return
	_aperto = false
	visible = false
	get_tree().paused = false
	GameManager.piglia_o_mouse(true)


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
	_fondo.color = Color(0, 0, 0, 0.70)
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_fondo)

	_pannello = PanelContainer.new()
	_pannello.set_anchors_preset(Control.PRESET_CENTER)
	_pannello.custom_minimum_size = Vector2(LARGH, 0)
	_pannello.position = Vector2(-LARGH * 0.5, -338)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.07, 0.10, 0.99)
	st.border_color = Color(0.62, 0.50, 0.30)
	st.set_border_width_all(2)
	st.set_corner_radius_all(6)
	_pannello.add_theme_stylebox_override("panel", st)
	add_child(_pannello)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20)
	m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 14)
	m.add_theme_constant_override("margin_bottom", 14)
	_pannello.add_child(m)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	m.add_child(col)

	_titolo = _scritta("'O LOTTO", 24, ORO)
	col.add_child(_titolo)

	_ultima = _scritta("", 14, CREMA)
	_ultima.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_ultima)

	# **'O quadernetto d''e ritardatarie**, sotto all'ultima estrazione:
	# è lì che guarda per primo chi gioca davvero.
	_ritardi = _scritta("", 14, ORO)
	_ritardi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_ritardi)

	col.add_child(_riga(ORO.darkened(0.5)))

	# --- 'A rota -------------------------------------------------------
	var lab_r := _scritta("'A ROTA", 13, SPENTO)
	col.add_child(lab_r)
	_riga_ruote = HBoxContainer.new()
	_riga_ruote.add_theme_constant_override("separation", 3)
	_riga_ruote.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(_riga_ruote)
	for r in Lotto.RUOTE:
		var b := Button.new()
		b.text = str(r)
		b.custom_minimum_size = Vector2(80, 26)
		b.add_theme_font_size_override("font_size", 12)
		var nome := str(r)
		b.pressed.connect(func():
			_ruota = nome
			_aggiorna())
		_riga_ruote.add_child(b)

	# --- 'E nummere ----------------------------------------------------
	var lab_n := _scritta("'E NUMMERE  ·  fino a cinche", 13, SPENTO)
	col.add_child(lab_n)
	_griglia = GridContainer.new()
	# Dieci per riga, come il tabellone vero: nove righe da dieci.
	_griglia.columns = 10
	_griglia.add_theme_constant_override("h_separation", 3)
	_griglia.add_theme_constant_override("v_separation", 3)
	col.add_child(_griglia)
	for n in range(1, Lotto.NUMERI + 1):
		var b := Button.new()
		# Novantacinque per trentaquattro: ci sta "'o muorto che pparla"
		# tagliato ma riconoscibile, e il nome intero sta nel tooltip. A
		# ottantotto si perdeva mezza smorfia.
		b.custom_minimum_size = Vector2(100, 34)
		b.add_theme_font_size_override("font_size", 10)
		b.clip_text = true
		b.tooltip_text = Lotto.nome_numero(n)
		var v: int = n
		b.pressed.connect(func(): _tocca(v))
		_griglia.add_child(b)
		_bot_num.append(b)

	col.add_child(_riga(ORO.darkened(0.5)))

	# --- 'A puntata ----------------------------------------------------
	_riga_punt = HBoxContainer.new()
	_riga_punt.add_theme_constant_override("separation", 6)
	_riga_punt.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(_riga_punt)
	var lab_p := _scritta("'A PUNTATA", 13, SPENTO)
	lab_p.custom_minimum_size = Vector2(96, 0)
	_riga_punt.add_child(lab_p)
	for q in [1, 2, 5, 10, 20]:
		var b := Button.new()
		b.text = "€%d" % q
		b.custom_minimum_size = Vector2(62, 28)
		var v: int = q
		b.pressed.connect(func():
			_puntata = v
			_aggiorna())
		_riga_punt.add_child(b)

	_schedina = _scritta("", 17, ORO)
	_schedina.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_schedina)

	var azioni := HBoxContainer.new()
	azioni.add_theme_constant_override("separation", 10)
	azioni.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(azioni)

	_bot_gioca = Button.new()
	_bot_gioca.text = "GIOCA"
	_bot_gioca.custom_minimum_size = Vector2(190, 34)
	_bot_gioca.pressed.connect(_gioca)
	azioni.add_child(_bot_gioca)

	var pulisci := Button.new()
	pulisci.text = "Scancella"
	pulisci.custom_minimum_size = Vector2(120, 34)
	pulisci.pressed.connect(func():
		_scelti.clear()
		_aggiorna())
	azioni.add_child(pulisci)

	# **'O nummero d''a smorfia a sorte.** È il bottone che un tabaccaio
	# vero non ha e che qui serve: chi non conosce la smorfia non sa da
	# dove cominciare, e restare davanti a novanta caselle senza sapere
	# che fare è il modo più veloce per chiudere il pannello.
	var sogno := Button.new()
	sogno.text = "Damme tu 'e nummere"
	sogno.custom_minimum_size = Vector2(190, 34)
	sogno.pressed.connect(_a_sciorte)
	azioni.add_child(sogno)

	var esci := Button.new()
	esci.text = "Vabbuo' [Esc]"
	esci.custom_minimum_size = Vector2(140, 34)
	esci.pressed.connect(chiudi)
	azioni.add_child(esci)

	_aperte = _scritta("", 14, CREMA)
	_aperte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_aperte)

	_pie = _scritta("L'estrazione se fa stasera, quanno chiude 'a jurnata.",
		12, SPENTO)
	col.add_child(_pie)


# ---------------------------------------------------------------------------
# 'A logica
# ---------------------------------------------------------------------------

func _tocca(n: int) -> void:
	if _scelti.has(n):
		_scelti.erase(n)
	elif _scelti.size() < 5:
		_scelti.append(n)
		_scelti.sort()
		SoundManager.play("pop", -12.0, 1.3)
	else:
		SoundManager.play("fail", -14.0, 1.1)
	_aggiorna()


## Cinque numeri a caso, che è come si gioca davvero quando non si è
## sognato niente.
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
		SoundManager.play("fail", -8.0, 0.9)
		_pie.text = str(esito.get("pecche", "Nun se pò."))
		_pie.add_theme_color_override("font_color", ROSSO)
		return
	SoundManager.play("coin", -4.0)
	_pie.text = "Giocato: %s 'e %s ncopp'a %s. Stasera se vede." % [
		str(esito.get("sorte", "")), "€%d" % _puntata, _ruota]
	_pie.add_theme_color_override("font_color", VERDE)
	_scelti.clear()
	_aggiorna()


func _aggiorna() -> void:
	if not is_instance_valid(_titolo):
		return
	_titolo.text = "'O LOTTO   ·   tiene €%d" % GameManager.money

	# 1. L'ultima estrazione.
	var u: Dictionary = GameManager.lotto_ultima
	if u.is_empty():
		_ultima.text = "Ancora nun s'è fatta nisciun'estrazione. 'A primma è stasera."
		_ultima.add_theme_color_override("font_color", SPENTO)
	else:
		var num: Dictionary = u.get("numeri", {})
		var usciti: Array = num.get(_ruota, [])
		var righe: Array = []
		for n in usciti:
			righe.append("%d" % int(n))
		_ultima.text = "Ultima estrazione (juorno %d) ·  %s:  %s" % [
			int(u.get("giornata", 0)), _ruota, "   ".join(righe)]
		_ultima.add_theme_color_override("font_color", CREMA)

	# 1-bis. 'O quadernetto: 'e numere ca nun esceno 'a 'nu pezzo.
	#
	# È una fallacia — la ruota non si ricorda niente, e infatti qui il
	# ritardo **non cambia nemmeno di un millesimo** la probabilità. Ma
	# con novanta numeri tutti uguali la giocata non è una scelta: è un
	# dado. Questa riga è quello che i giocatori veri si scrivono a mano
	# su un foglio appeso al banco, ed è la ragione per cui uno dice
	# "gioco 'o 47, ca manca 'a novantadue estrazioni".
	var rit: Array = GameManager.lotto_ritardatarie(_ruota, 6)
	var ritardate: Array = []
	for r in rit:
		if int(r["ritardo"]) <= 0:
			continue
		ritardate.append("%d (%d)" % [int(r["n"]), int(r["ritardo"])])
	if ritardate.is_empty():
		_ritardi.text = "'O quadernetto d''e ritardatarie sta ancora vacante."
		_ritardi.add_theme_color_override("font_color", SPENTO)
	else:
		_ritardi.text = "Ritardatarie ncopp'a %s:  %s" % [_ruota,
			"   ".join(ritardate)]
		_ritardi.add_theme_color_override("font_color", ORO)

	# 2. La griglia. Il numero scelto si accende, e i numeri usciti
	#    l'ultima volta restano segnati: è quello che uno guarda per
	#    decidere ("chisto è asciuto ajere, mo' nun esce cchiù" — che è
	#    una sciocchezza, ma è la sciocchezza che fa giocare).
	var usciti_ieri: Array = []
	if not u.is_empty():
		usciti_ieri = Dictionary(u.get("numeri", {})).get(_ruota, [])
	for i in range(_bot_num.size()):
		var n: int = i + 1
		var b: Button = _bot_num[i]
		b.text = "%d %s" % [n, Lotto.smorfia(n)]
		if _scelti.has(n):
			b.add_theme_color_override("font_color", Color(0.15, 0.10, 0.04))
			b.add_theme_stylebox_override("normal", _riempi(ORO))
			b.add_theme_stylebox_override("hover", _riempi(ORO.lightened(0.1)))
		else:
			b.remove_theme_stylebox_override("normal")
			b.remove_theme_stylebox_override("hover")
			b.add_theme_color_override("font_color",
				VERDE if usciti_ieri.has(n) else CREMA)

	# 3. La schedina, col numero grosso.
	if _scelti.is_empty():
		_schedina.text = "Scegli 'e nummere ncopp'â griglia. Uno = ambata, dduje = ambo, tre = terno…"
		_schedina.add_theme_color_override("font_color", SPENTO)
		_bot_gioca.disabled = true
	else:
		var lista: Array = []
		for n in _scelti:
			lista.append(Lotto.nome_numero(int(n)))
		_schedina.text = "%s ncopp'a %s pe' €%d   →   si esce, pigli €%s" % [
			Lotto.sorte(_scelti.size()).to_upper(), _ruota, _puntata,
			_cifra(GameManager.lotto_sogno(_scelti, _puntata))]
		_schedina.add_theme_color_override("font_color", ORO)
		_bot_gioca.disabled = GameManager.money < _puntata

	# 4. Le giocate già fatte per stasera.
	var quante: int = GameManager.lotto_quante_aperte()
	if quante == 0:
		_aperte.text = ""
	else:
		var voci: Array = []
		for g in GameManager.lotto_giocate:
			var nn: Array = []
			for n in g["numeri"]:
				nn.append(str(int(n)))
			voci.append("%s ncopp'a %s pe' €%d" % [
				"-".join(nn), str(g["ruota"]), int(g["puntata"])])
		_aperte.text = "PE' STASERA (%d, €%d):   %s" % [quante,
			GameManager.lotto_messo_aperto(), "   ·   ".join(voci)]
		_aperte.add_theme_color_override("font_color", ORO.lightened(0.2))


## Le cifre grosse con i punti: "120.000" si legge, "120000" no.
func _cifra(n: int) -> String:
	var s := str(n)
	var fuori := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		fuori = s[i] + fuori
		c += 1
		if c % 3 == 0 and i > 0:
			fuori = "." + fuori
	return fuori


func _riempi(c: Color) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = c
	st.set_corner_radius_all(3)
	return st


func _riga(c: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = c
	r.custom_minimum_size = Vector2(0, 1)
	return r


func _scritta(t: String, corpo: int, colore: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", corpo)
	l.add_theme_color_override("font_color", colore)
	return l
