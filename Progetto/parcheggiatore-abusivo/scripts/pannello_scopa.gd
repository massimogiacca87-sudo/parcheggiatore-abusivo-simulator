extends CanvasLayer
## PannelloScopa — 'a partita vera
##
## La scopa si gioca a schermo intero: le carte del vecchio (coperte) in
## alto, il tavolo in mezzo, la tua mano sotto, e a destra **'o tabellone**.
##
## ## Chello ca s'è cagnato ê 0.50
##
## 1. **Nun se ne asceva cchiù**: a fine partita il bottone usciva dallo
##    schermo ed ESC non funzionava. Adesso a partita finita le carte si
##    nascondono, resta il tabellone, ed ESC chiude sempre.
## 2. **Nun se vedeva chello ca s'era pigliato**: c'è la striscia
##    dell'ultima presa (carta calata → carte prese), con un'animazione corta.
## 3. **'A presa se sceglie cliccanno**: clicchi la carta in mano, le carte
##    del tavolo che puoi prendere si accendono di giallo, clicchi quelle.
##
## ## Chello ca s'è cagnato ê 0.62
##
## Il capo: *«Migliora il minigioco di scopa con carte a miglior risoluzione,
## tabella punteggi. Spiega al giocatore che vincendo ha sbloccato la sfida
## col prossimo maestro di scopa»*.
##
## 1. **'E ccarte grosse.** Le carte vengono dall'atlante HD
##    (`assets/ui/carte_hd.png`, 240x390 per carta, fatto da
##    `tools/carte_hd.py` dalla scansione del capo) e il dorso è disegnato
##    (`carta_retro.png`), non più un rettangolo rosso. La carta sotto al
##    mouse si alza un poco.
## 2. **'O tabellone.** A destra, sempre a schermo: carte, denari,
##    settebello, primiera e scope, tu contro lui, con chi sta avanti
##    acceso d'oro, e i punti *«si fernesse mo'»*. A fine partita diventa
##    la tabella vera, voce per voce, con chi ha preso il punto.
## 3. **'O turneo.** In alto la scala dei cinque maestri (battuti, questo,
##    i prossimi col lucchetto). Quando vinci la prima volta, la schermata
##    finale dice chiaro **chi hai sbloccato, dove sta e quanto si gioca** —
##    e lo ripete il cartello quando ti alzi dal tavolo.
##
## ## E po' ce sta Don Gennaro, ca **bara**
##
## L'ultimo del torneo si cambia una carta in mano quando gli conviene. Ma
## si vede: si tocca la coppola, tossisce, si sistema la manica. Se premi
## [F] mentre lo sta facendo, l'hai beccato: la carta te la dà, e la mano la
## perde lui. Se lo accusi a vuoto, sono cinque euro di figura.

const Carte := preload("res://scripts/carte.gd")
const Motore := preload("res://scripts/scopa_motore.gd")
const US := preload("res://scripts/ui_stile.gd")
const CittaS := preload("res://scripts/citta_3d.gd")

## La carta a grandezza 1: 96x156, stesso rapporto della carta vera.
const CARTA_W: float = 96.0
const CARTA_H: float = 156.0
## Le scale sono pensate per lo schermo base del progetto (1152x648): la
## finestra più grande ingrandisce tutto insieme (`canvas_items`).
const S_LUI: float = 0.46
const S_TAVOLO: float = 0.8
const S_ULTIMA: float = 0.38
const S_MANO: float = 0.96
const PAUSA_IA: float = 1.5
const FINESTRA_ACCUSA: float = 2.6
const TABELLONE_L: float = 262.0

## Quanto dura l'animazione dell'ultima presa.
const PRESA_ANIM: float = 0.45

const GIALLO := Color(1.0, 0.84, 0.22)
const VERDE := Color(0.42, 0.94, 0.48)
const PANNO := Color(0.10, 0.36, 0.20)
const PANNO_SCURO := Color(0.03, 0.14, 0.08)

signal chiusa(vinto: bool)

var sfidante: Dictionary = {}
var puntata: int = 0

var _m: ScopaMotore
var _fondo: Control
var _gioco: VBoxContainer
var _riga_alto: HBoxContainer
var _riga_tavolo: HBoxContainer
var _riga_mano: HBoxContainer
var _sep_tavolo: Control
var _titolo: Label
var _sotto_titolo: Label
var _turneo: VBoxContainer
var _stato: Label
var _bolla: Label
var _fine: VBoxContainer
var _punti: Label
var _ultima: HBoxContainer
var _tabellone: PanelContainer
var _tab_griglia: GridContainer
var _tab_piede: Label
var _tab_mazzo: Label

var _attesa: float = 0.0
var _tocca_a_lui: bool = false
var _bloccato: bool = false
var _finita: bool = false

# --- 'a scelta d''a presa --------------------------------------------------
## Quale carta della mano è stata cliccata (−1 = nessuna).
var _carta_scelta: int = -1
## Tutte le prese che quella carta potrebbe fare.
var _opzioni: Array = []
## Le carte del tavolo già cliccate, che fanno parte della presa in corso.
var _presi: Array = []

# --- 'a mbroglia d''o Nonno ------------------------------------------------
var _bara_ora: bool = false
var _bara_tempo: float = 0.0
var _bara_carta: int = -1
var _accuse_sbagliate: int = 0

# --- 'o turneo -------------------------------------------------------------
## Vero se questa partita, vinta, sblocca il prossimo (cioè non l'avevi
## ancora battuto). Si decide all'inizio: dopo `scopa_esito` è già vero.
var _prima_vota: bool = false


func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	_costruisci()


func avvia(chi: Dictionary, quanto: int) -> void:
	sfidante = chi
	puntata = quanto
	_prima_vota = not GameManager.scopa_battuti.has(str(chi.get("id", "")))
	_m = Motore.new()
	_m.nuova_partita(0)
	_finita = false
	_bloccato = false
	_attesa = 0.0
	_tocca_a_lui = false
	_accuse_sbagliate = 0
	_bara_ora = false
	_scorda_scelta()
	_mostra_gioco(true)
	_svuota(_fine)
	_svuota(_ultima)
	visible = true
	get_tree().paused = true
	GameManager.piglia_o_mouse(false)
	_titolo.text = str(chi.get("nome", ""))
	_sotto_titolo.text = "%d anne  ·  se joca €%d" % [int(chi.get("eta", 70)), quanto]
	_disegna_turneo()
	_dice(str(chi.get("dice", "")))
	SoundManager.ui("ui_apri")
	_ridisegna()


# ---------------------------------------------------------------------------
# 'A faccia
# ---------------------------------------------------------------------------

func _costruisci() -> void:
	# Il panno verde: un gradiente radiale, chiaro al centro e scuro sui
	# bordi, come sotto a una lampada.
	var panno := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, PANNO.lightened(0.08))
	g.set_color(1, PANNO_SCURO)
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.55)
	gt.fill_to = Vector2(1.05, 1.1)
	gt.width = 256
	gt.height = 256
	panno.texture = gt
	panno.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panno.stretch_mode = TextureRect.STRETCH_SCALE
	panno.set_anchors_preset(Control.PRESET_FULL_RECT)
	panno.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panno)
	_fondo = panno
	# La cornice di legno tutto attorno.
	var legno := Panel.new()
	legno.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sl := StyleBoxFlat.new()
	sl.draw_center = false
	sl.border_color = Color(0.30, 0.17, 0.08)
	sl.set_border_width_all(10)
	sl.shadow_color = Color(0, 0, 0, 0.0)
	legno.add_theme_stylebox_override("panel", sl)
	legno.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(legno)

	var fuori := MarginContainer.new()
	fuori.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lato in ["left", "right"]:
		fuori.add_theme_constant_override("margin_" + lato, 26)
	fuori.add_theme_constant_override("margin_top", 16)
	fuori.add_theme_constant_override("margin_bottom", 14)
	fuori.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fuori)

	var colonna := VBoxContainer.new()
	colonna.add_theme_constant_override("separation", 8)
	colonna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fuori.add_child(colonna)

	# --- La testata: chi, quanto, e 'o turneo ---------------------------
	var testa := HBoxContainer.new()
	testa.add_theme_constant_override("separation", 18)
	testa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	colonna.add_child(testa)
	var chi := VBoxContainer.new()
	chi.add_theme_constant_override("separation", -2)
	chi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	testa.add_child(chi)
	_titolo = US.etichetta("", 26, US.ORO_CHIARO)
	_titolo.add_theme_font_override("font", US.font_titolo())
	chi.add_child(_titolo)
	_sotto_titolo = US.etichetta("", 15, Color(0.86, 0.92, 0.86))
	chi.add_child(_sotto_titolo)
	# 'A voce d''o viecchio sta 'ncoppa, 'mmiezo: accussì nun se mangia
	# n'altezza sana d''o tavulo.
	var mezzo := CenterContainer.new()
	mezzo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mezzo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	testa.add_child(mezzo)
	_bolla = US.etichetta("", 16, Color(1.0, 0.9, 0.66))
	_bolla.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bolla.add_theme_constant_override("outline_size", 0)
	_bolla.add_theme_stylebox_override("normal",
		US.box(Color(0, 0, 0, 0.32), Color(1, 1, 1, 0.1), 1, 14, 16.0, 5.0))
	mezzo.add_child(_bolla)

	# --- Il corpo: il gioco a sinistra, il tabellone a destra ------------
	var corpo := HBoxContainer.new()
	corpo.add_theme_constant_override("separation", 18)
	corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corpo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	colonna.add_child(corpo)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corpo.add_child(v)
	_gioco = v

	# Le sue carte, coperte. Piccole: non c'è niente da guardare.
	_riga_alto = _riga(v, -14, S_LUI)

	var sep := HBoxContainer.new()
	sep.alignment = BoxContainer.ALIGNMENT_CENTER
	sep.add_theme_constant_override("separation", 10)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(3):
		if i == 1:
			var t := US.etichetta("'O TAVULO", 13, Color(0.72, 0.9, 0.74), true)
			t.add_theme_constant_override("outline_size", 0)
			sep.add_child(t)
		else:
			var linea := ColorRect.new()
			linea.color = Color(0.72, 0.9, 0.74, 0.35)
			linea.custom_minimum_size = Vector2(150, 1)
			linea.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			linea.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sep.add_child(linea)
	v.add_child(sep)
	_sep_tavolo = sep
	_riga_tavolo = _riga(v, 8, S_TAVOLO)

	# 'A striscia 'e ll'ultima presa.
	_ultima = HBoxContainer.new()
	_ultima.alignment = BoxContainer.ALIGNMENT_CENTER
	_ultima.add_theme_constant_override("separation", 5)
	_ultima.custom_minimum_size = Vector2(0, CARTA_H * S_ULTIMA + 4)
	_ultima.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_ultima)

	_stato = US.etichetta("", 17, Color(1, 1, 1))
	_stato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Va a capo: una frase lunga non deve allargare la colonna fino a
	# spingere il tabellone fuori dallo schermo.
	_stato.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stato.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(_stato)

	_riga_mano = _riga(v, 12, S_MANO)

	_punti = US.etichetta("", 13, Color(0.8, 0.9, 0.82))
	_punti.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_punti.visible = false
	v.add_child(_punti)

	_fine = VBoxContainer.new()
	_fine.alignment = BoxContainer.ALIGNMENT_CENTER
	_fine.add_theme_constant_override("separation", 10)
	_fine.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_fine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_fine)

	# A destra: 'o turneo (i cinque maestri, uno sotto all'altro) e sotto
	# 'o tabellone.
	var destra := VBoxContainer.new()
	destra.add_theme_constant_override("separation", 12)
	destra.alignment = BoxContainer.ALIGNMENT_CENTER
	destra.custom_minimum_size = Vector2(TABELLONE_L, 0)
	destra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corpo.add_child(destra)
	_turneo = VBoxContainer.new()
	_turneo.add_theme_constant_override("separation", 4)
	_turneo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	destra.add_child(_turneo)
	_costruisci_tabellone(destra)


func _riga(sotto: Control, sep: int, scala: float) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", sep)
	h.custom_minimum_size = Vector2(0, CARTA_H * scala + 10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sotto.add_child(h)
	return h


## **'O tabellone**: sempre a destra, si aggiorna a ogni mossa.
func _costruisci_tabellone(dove: Control) -> void:
	var p := PanelContainer.new()
	var st := US.box(Color(0.03, 0.10, 0.06, 0.78), Color(US.ORO.r, US.ORO.g,
		US.ORO.b, 0.45), 2, 14, 16.0, 14.0)
	p.add_theme_stylebox_override("panel", st)
	p.custom_minimum_size = Vector2(TABELLONE_L, 0)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dove.add_child(p)
	_tabellone = p
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	var t := US.etichetta("'O TABELLONE", 17, US.ORO_CHIARO)
	t.add_theme_font_override("font", US.font_titolo())
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	_tab_griglia = GridContainer.new()
	_tab_griglia.columns = 3
	_tab_griglia.add_theme_constant_override("h_separation", 10)
	_tab_griglia.add_theme_constant_override("v_separation", 6)
	_tab_griglia.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_tab_griglia)
	var filo := ColorRect.new()
	filo.color = Color(1, 1, 1, 0.12)
	filo.custom_minimum_size = Vector2(0, 1)
	filo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(filo)
	_tab_piede = US.etichetta("", 15, Color(1, 1, 1), true)
	_tab_piede.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tab_piede.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_tab_piede)
	_tab_mazzo = US.etichetta("", 12, Color(0.72, 0.84, 0.76))
	_tab_mazzo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tab_mazzo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_tab_mazzo)
	var aiuto := US.etichetta(
		"Nu punto pe': cchiù ccarte, cchiù denare, 'o settebello, 'a primera, e ogni scopa.",
		11, Color(0.66, 0.78, 0.7))
	aiuto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aiuto.custom_minimum_size = Vector2(TABELLONE_L - 32, 0)
	aiuto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(aiuto)


## Riscrive il tabellone: `voci` = [[nome, tu, isso, chi_sta_avanti]].
func _scrivi_tabellone(voci: Array, finale: bool) -> void:
	for c in _tab_griglia.get_children():
		_tab_griglia.remove_child(c)
		c.queue_free()
	for h in ["", "TU", "ISSO"]:
		var l := US.etichetta(h, 12, Color(0.7, 0.86, 0.74), true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size = Vector2(56 if h != "" else 104, 0)
		_tab_griglia.add_child(l)
	for v in voci:
		var nome := US.etichetta(str(v[0]), 15, Color(0.92, 0.94, 0.9))
		nome.custom_minimum_size = Vector2(104, 0)
		_tab_griglia.add_child(nome)
		for k in [1, 2]:
			var chi_avanti: int = int(v[3])
			var acceso: bool = (chi_avanti == 0 and k == 1) \
				or (chi_avanti == 1 and k == 2)
			var n := US.etichetta(str(v[k]), 16,
				US.ORO_CHIARO if acceso else Color(0.8, 0.84, 0.8), acceso)
			n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			n.custom_minimum_size = Vector2(56, 0)
			if acceso:
				n.add_theme_stylebox_override("normal",
					US.box(Color(US.ORO.r, US.ORO.g, US.ORO.b, 0.22),
					Color(0, 0, 0, 0), 0, 8, 4.0, 0.0))
			_tab_griglia.add_child(n)
	var _f := finale


func _carta_nodo(indice: int, coperta: bool, scala: float = 1.0) -> Control:
	var t := TextureRect.new()
	t.custom_minimum_size = Vector2(CARTA_W * scala, CARTA_H * scala)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.texture = Carte.retro_hd() if coperta else Carte.texture_hd(indice)
	if t.texture == null:
		var c2 := ColorRect.new()
		c2.color = Carte.RETRO_TINTA if coperta else Color(0.94, 0.92, 0.86)
		c2.set_anchors_preset(Control.PRESET_FULL_RECT)
		c2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.add_child(c2)
		if not coperta:
			var l := Label.new()
			l.text = Motore.nome_carta(indice).replace(" ", "\n")
			l.set_anchors_preset(Control.PRESET_FULL_RECT)
			l.modulate = Color(0.1, 0.1, 0.1)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			t.add_child(l)
	return t


## L'ombra sotto a una carta: un rettangolo scuro sfumato, spostato in giù.
func _ombra(scala: float) -> Panel:
	var o := Panel.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0.0)
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = int(8 * scala) + 2
	s.shadow_offset = Vector2(0, 4 * scala)
	s.set_corner_radius_all(int(10 * scala))
	o.add_theme_stylebox_override("panel", s)
	o.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return o


## **'A cornice.** Una carta "che si può prendere" deve dirlo da sola:
## niente scritte, niente legenda. Il bordo sta **attorno** alla carta.
func _cornice(colore: Color, spessore: int) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(colore.r, colore.g, colore.b, 0.0)
	sb.border_color = colore
	sb.set_border_width_all(spessore)
	sb.set_corner_radius_all(10)
	sb.set_expand_margin_all(float(spessore) + 2.0)
	sb.shadow_color = Color(colore.r, colore.g, colore.b, 0.45)
	sb.shadow_size = 8
	p.add_theme_stylebox_override("panel", sb)
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## Una carta cliccabile, con l'ombra, la cornice e il sollevamento quando
## ci passi sopra col mouse.
func _bottone_carta(indice: int, scala: float, colore: Color,
		premuto: Callable) -> Control:
	var b := Button.new()
	b.custom_minimum_size = Vector2(CARTA_W * scala, CARTA_H * scala)
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.set_meta(&"ui_muto", true)
	var vuoto := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(st, vuoto)
	var dentro := Control.new()
	dentro.set_anchors_preset(Control.PRESET_FULL_RECT)
	dentro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(dentro)
	dentro.add_child(_ombra(scala))
	# La cornice sta DIETRO alla carta: il bordo esce fuori (expand margin)
	# e il bagliore non tinge di giallo la figura.
	if colore.a > 0.0:
		dentro.add_child(_cornice(colore, 4))
	var c := _carta_nodo(indice, false, scala)
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	dentro.add_child(c)
	if premuto.is_valid():
		b.pressed.connect(premuto)
		b.mouse_entered.connect(func():
			var tw := dentro.create_tween()
			tw.tween_property(dentro, "position:y", -10.0 * scala, 0.09)
			SoundManager.ui("ui_hover"))
		b.mouse_exited.connect(func():
			var tw := dentro.create_tween()
			tw.tween_property(dentro, "position:y", 0.0, 0.12))
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		b.disabled = true
	return b


func _ridisegna() -> void:
	for r in [_riga_alto, _riga_tavolo, _riga_mano]:
		for c in r.get_children():
			r.remove_child(c)
			c.queue_free()

	for _i in range(_m.mani[1].size()):
		var w := Control.new()
		w.custom_minimum_size = Vector2(CARTA_W * S_LUI, CARTA_H * S_LUI)
		w.mouse_filter = Control.MOUSE_FILTER_IGNORE
		w.add_child(_ombra(S_LUI))
		var c := _carta_nodo(0, true, S_LUI)
		c.set_anchors_preset(Control.PRESET_FULL_RECT)
		w.add_child(c)
		_riga_alto.add_child(w)

	# --- 'O tavulo: chi si può prendere si accende ---------------------
	var accendibili := _tavolo_accendibile()
	if _m.tavolo.is_empty():
		var vuoto := US.etichetta("'o tavulo è vacante", 15, Color(0.7, 0.86, 0.74))
		vuoto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_riga_tavolo.add_child(vuoto)
	for c in _m.tavolo:
		var carta: int = c
		var colore := Color(0, 0, 0, 0)
		var azione := Callable()
		if _presi.has(carta):
			colore = VERDE
			azione = func(): _clicca_tavolo(carta)
		elif accendibili.has(carta):
			colore = GIALLO
			azione = func(): _clicca_tavolo(carta)
		_riga_tavolo.add_child(_bottone_carta(carta, S_TAVOLO, colore, azione))

	# --- 'A mano toia ---------------------------------------------------
	var giocabile: bool = not (_bloccato or _finita or _m.turno != 0)
	for c in _m.mani[0]:
		var carta2: int = c
		var col := Color(0, 0, 0, 0)
		if carta2 == _carta_scelta:
			col = GIALLO
		var az := Callable()
		if giocabile:
			az = func(): _clicca_mano(carta2)
		_riga_mano.add_child(_bottone_carta(carta2, S_MANO, col, az))

	_aggiorna_tabellone()
	_aggiorna_stato()


## Il tabellone durante la partita: i conti di adesso.
func _aggiorna_tabellone() -> void:
	var c0: int = _m.prese[0].size()
	var c1: int = _m.prese[1].size()
	var d0: int = _m.denari(0)
	var d1: int = _m.denari(1)
	var s0: bool = _m.prese[0].has(Motore.SETTEBELLO)
	var s1: bool = _m.prese[1].has(Motore.SETTEBELLO)
	var p0: int = _m.primiera(0)
	var p1: int = _m.primiera(1)
	var voci := [
		["Carte", c0, c1, _avanti(c0, c1)],
		["Denare", d0, d1, _avanti(d0, d1)],
		["Settebello", "✓" if s0 else "–", "✓" if s1 else "–",
			0 if s0 else (1 if s1 else -1)],
		["Primera", p0, p1, _avanti(p0, p1)],
		["Scope", _m.scope[0], _m.scope[1], _avanti(_m.scope[0], _m.scope[1])],
	]
	_scrivi_tabellone(voci, false)
	var p: Dictionary = _m.punteggio()
	_tab_piede.text = "Si fernesse mo':  tu %d — isso %d" % [
		int(p["punti"][0]), int(p["punti"][1])]
	_tab_mazzo.text = "Mazzo: %d carte  ·  %s" % [_m.mazzo.size(),
		"tocca a te" if _m.turno == 0 else "tocca a isso"]
	# Il vecchio conto in fondo (nascosto): resta per le prove.
	_punti.text = "'E ccarte mie: %d (%d scope)   ·   'e ssoie: %d (%d scope)   ·   mazzo: %d" \
		% [c0, _m.scope[0], c1, _m.scope[1], _m.mazzo.size()]


func _avanti(a: int, b: int) -> int:
	if a > b:
		return 0
	if b > a:
		return 1
	return -1


## Quali carte del tavolo, adesso, sono un passo valido della presa in corso.
func _tavolo_accendibile() -> Array:
	var fuori: Array = []
	if _carta_scelta < 0:
		return fuori
	for o in _opzioni:
		for c in o:
			if not _presi.has(c) and not fuori.has(c):
				fuori.append(c)
	return fuori


func _aggiorna_stato() -> void:
	if _finita:
		_stato.text = ""
		return
	if _m.turno != 0:
		_stato.text = "Sta penzanno…"
		_stato.modulate = Color(0.8, 0.86, 0.8)
		return
	_stato.modulate = Color(1, 1, 1)
	if _carta_scelta < 0:
		_stato.text = "Tocca a te: clicca 'na carta d''a mano."
		return
	if _opzioni.is_empty():
		_stato.text = ""
		return
	var quante: int = _tavolo_accendibile().size()
	if _presi.is_empty():
		_stato.text = "Cu 'o %s: clicca 'e ccarte gialle ca vuo' piglià (n'ata vota 'a toia pe' cagnà idea)" \
			% Motore.nome_carta(_carta_scelta)
	else:
		_stato.text = "Ne manca ancora %d  ·  clicca 'a verde pe' lassarla" \
			% maxi(1, quante)


func _dice(t: String) -> void:
	_bolla.text = "« %s »" % t


## Accende o spegne tutta la roba del gioco. A partita finita si spegne: le
## carte non servono più e la tabella finale ci sta comoda.
func _mostra_gioco(si: bool) -> void:
	for n in [_riga_alto, _sep_tavolo, _riga_tavolo, _ultima, _stato,
			_riga_mano]:
		if n != null:
			(n as CanvasItem).visible = si
	if _tabellone != null:
		_tabellone.visible = si
	# La colonna della fine si allarga da sola (EXPAND_FILL): durante la
	# partita deve sparire, se no si mangia l'altezza e la mano esce sotto.
	if _fine != null:
		_fine.visible = not si


# ---------------------------------------------------------------------------
# 'O turneo
# ---------------------------------------------------------------------------

## La scala dei cinque maestri, in alto a destra: battuti (spunta verde),
## quello di adesso (oro), i prossimi (lucchetto).
func _disegna_turneo() -> void:
	_svuota(_turneo)
	var qui: String = str(sfidante.get("id", ""))
	var l := US.etichetta("'O TURNEO D''A SCOPA", 13, Color(0.7, 0.86, 0.74), true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_turneo.add_child(l)
	for s in GameManager.SFIDANTI:
		var id: String = str(s["id"])
		var battuto: bool = GameManager.scopa_battuti.has(id)
		var chip := PanelContainer.new()
		var col := Color(0.4, 0.44, 0.42)
		var icona := "lucchetto"
		if id == qui:
			col = US.ORO
			icona = "stella"
		elif battuto:
			col = US.VERDE
			icona = "spunta"
		chip.add_theme_stylebox_override("panel", US.box(
			Color(col.r, col.g, col.b, 0.18), Color(col.r, col.g, col.b, 0.8),
			2 if id == qui else 1, 10, 8.0, 3.0))
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.custom_minimum_size = Vector2(TABELLONE_L, 0)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 5)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(h)
		h.add_child(US.figura(icona, 13, col.lerp(Color(1, 1, 1), 0.3)))
		var nome: String = "%s  ·  €%d" % [str(s["nome"]), int(s["puntata"])]
		var t := US.etichetta(nome, 13,
			col.lerp(Color(1, 1, 1), 0.45), id == qui)
		t.add_theme_constant_override("outline_size", 0)
		h.add_child(t)
		_turneo.add_child(chip)


## Il maestro che viene dopo `id` nella scala (vuoto se è l'ultimo).
static func dopo_di(id: String) -> Dictionary:
	var trovato := false
	for s in GameManager.SFIDANTI:
		if trovato:
			return s
		if str(s["id"]) == id:
			trovato = true
	return {}


## Dove sta il tavolino di un maestro, detto con il nome del quartiere.
static func dove_sta(id: String) -> String:
	for t in CittaS.TAVULE_SCOPA:
		if str(t["id"]) == id:
			var p: Vector3 = t["p"]
			return Quartieri.nome_di(p.x, p.z)
	return "'n coppa â chiantina"


# ---------------------------------------------------------------------------
# 'A partita
# ---------------------------------------------------------------------------

func _scorda_scelta() -> void:
	_carta_scelta = -1
	_opzioni = []
	_presi = []


## Clic su una carta della mano.
func _clicca_mano(carta: int) -> void:
	if _finita or _bloccato or _m.turno != 0:
		return
	# Ri-cliccare la carta scelta vuol dire cambiare idea.
	if carta == _carta_scelta:
		_scorda_scelta()
		_ridisegna()
		return
	var opz: Array = Motore.prese_possibili(carta, _m.tavolo)
	if opz.is_empty():
		# Niente da prendere: la carta si cala e basta.
		_scorda_scelta()
		_gioca_io(carta, [])
		return
	_carta_scelta = carta
	_opzioni = opz
	_presi = []
	SoundManager.ui("ui_click")
	_ridisegna()


## Clic su una carta del tavolo: entra (o esce) dalla presa che stai
## componendo. Appena la presa combacia con una di quelle valide, si gioca.
func _clicca_tavolo(carta: int) -> void:
	if _finita or _bloccato or _m.turno != 0 or _carta_scelta < 0:
		return
	if _presi.has(carta):
		_presi.erase(carta)
	else:
		if not _tavolo_accendibile().has(carta):
			return
		_presi.append(carta)

	var buone: Array = []
	for o in _opzioni:
		var dentro := true
		for p in _presi:
			if not (o as Array).has(p):
				dentro = false
				break
		if dentro:
			buone.append(o)
	if buone.is_empty():
		_presi = []
		_ridisegna()
		return
	for o in buone:
		if (o as Array).size() == _presi.size():
			var presa: Array = _presi.duplicate()
			var c0: int = _carta_scelta
			_scorda_scelta()
			_gioca_io(c0, presa)
			return
	SoundManager.ui("ui_click")
	_ridisegna()


func _gioca_io(carta: int, presa: Array) -> void:
	var e: Dictionary = _m.gioca(0, carta, presa)
	_dopo_mossa(e)


func _dopo_mossa(e: Dictionary) -> void:
	if e.is_empty():
		return
	SoundManager.ui("ui_carta")
	if not e["presa"].is_empty():
		SoundManager.play("pop", -8.0)
	_mostra_presa(e)
	if e.get("scopa", false):
		SoundManager.play("vinto", -6.0)
		if int(e["chi"]) == 0:
			_dice("SCOPAAA!")
		else:
			_dice("Scopa. E chesta è 'a mia.")
	_ridisegna()
	if _m.finita:
		_chiudi_partita()
		return
	if _m.turno == 1:
		_tocca_a_lui = true
		_attesa = PAUSA_IA
		_bloccato = true


## **'A striscia 'e ll'ultima presa.**
func _mostra_presa(e: Dictionary) -> void:
	_svuota(_ultima)
	var chi := int(e.get("chi", 0))
	var presa: Array = e.get("presa", [])
	var calata := int(e.get("carta", -1))
	if calata < 0:
		return

	var eti := US.etichetta("TU" if chi == 0 else "ISSO", 14,
		Color(0.72, 0.95, 0.76) if chi == 0 else Color(1.0, 0.8, 0.62), true)
	eti.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	eti.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_ultima.add_child(eti)
	_ultima.add_child(_carta_nodo(calata, false, S_ULTIMA))

	if presa.is_empty():
		var giu := US.etichetta("  ▾ l'ha lassata 'nterra", 14, Color(0.7, 0.8, 0.72))
		giu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_ultima.add_child(giu)
	else:
		var fre := US.etichetta("  ▸  ", 20, Color(1.0, 0.86, 0.35))
		fre.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_ultima.add_child(fre)
		for c in presa:
			_ultima.add_child(_carta_nodo(int(c), false, S_ULTIMA))
	if e.get("scopa", false):
		var sc := US.etichetta("  SCOPA!", 20, GIALLO)
		sc.add_theme_font_override("font", US.font_titolo())
		sc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_ultima.add_child(sc)

	# L'animazione: la striscia entra da sotto e schiarisce.
	_ultima.modulate = Color(1, 1, 1, 0.0)
	var tw := create_tween()
	tw.tween_property(_ultima, "modulate:a", 1.0, PRESA_ANIM)


const BATTUTE := [
	"Mm. Chesta 'a tenevo 'a n'ora.",
	"E vabbuo'.", "Piano cu 'e mmane.", "Tu joche o pienze?",
	"'A scopa nun è fortuna, guagliò.", "Statte accuorto ô settebello.",
	"Aggio visto meglio.", "Chesta t''a facevo.",
]


func _process(delta: float) -> void:
	if not visible or _finita:
		return
	if _bara_ora:
		_bara_tempo -= delta
		if _bara_tempo <= 0.0:
			_bara_ora = false
			_aggiorna_stato()
	if not _tocca_a_lui:
		return
	_attesa -= delta
	if _attesa > 0.0:
		return
	_tocca_a_lui = false
	_bloccato = false
	_mossa_del_viecchio()


func _mossa_del_viecchio() -> void:
	var liv: int = int(sfidante.get("livello", 0))
	# **'A mbroglia.** Solo il Nonno, solo quando gli serve, e solo se non
	# l'hai appena beccato.
	if liv >= 4 and not GameManager.mazzo_del_nonno:
		_prova_a_barare()
	var mossa: Dictionary = _m.mossa_ia(liv)
	if mossa.is_empty():
		return
	if randf() < 0.28:
		_dice(str(BATTUTE[randi() % BATTUTE.size()]))
	var e: Dictionary = _m.gioca(1, int(mossa["carta"]), mossa["presa"])
	_dopo_mossa(e)


## Si cambia una carta in mano con una buona presa dal mazzo. E si vede.
func _prova_a_barare() -> void:
	if _bara_ora or _m.mazzo.is_empty() or _m.mani[1].is_empty():
		return
	if randf() > 0.34:
		return
	var buona := -1
	for c in _m.mazzo:
		if not Motore.prese_possibili(c, _m.tavolo).is_empty():
			buona = c
			if c == Motore.SETTEBELLO:
				break
	if buona < 0:
		return
	var peggio: int = _m.mani[1][0]
	for c in _m.mani[1]:
		if Motore.peso(c) < Motore.peso(peggio):
			peggio = c
	_m.mani[1].erase(peggio)
	_m.mazzo.erase(buona)
	_m.mani[1].append(buona)
	_m.mazzo.append(peggio)
	_bara_carta = buona
	_bara_ora = true
	_bara_tempo = FINESTRA_ACCUSA
	const TELL := ["…si tocca 'a coppola.", "…tosse, e move 'a manica.",
		"…se sistema 'o pulzino cu 'a mano sotto 'o tavulo.",
		"…guarda 'a n'ata parte e move 'e ccarte."]
	_stato.text = "%s  [F] pp''o ddicere" % str(TELL[randi() % TELL.size()])
	_stato.modulate = Color(1.0, 0.72, 0.5)
	SoundManager.play("tosse", -8.0)


func _accusa() -> void:
	if _finita:
		return
	if _bara_ora:
		_bara_ora = false
		if _m.mani[1].has(_bara_carta):
			_m.mani[1].erase(_bara_carta)
			_m.prese[0].append(_bara_carta)
		_dice("…E vabbuo'. Sî sveglio. Pigliatella.")
		SoundManager.play("vinto", -5.0)
		_ridisegna()
		return
	_accuse_sbagliate += 1
	_dice("E che vaje dicenno? Joca, va'.")
	SoundManager.ui("ui_errore")


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		# **ESC chiude sempe.** A partita finita chiude e basta (i conti sono
		# già fatti); a partita in corso è una fuga, e la puntata resta sul
		# tavolo.
		if _finita:
			_esci(_vinto_ora(), false, _patta_ora())
		else:
			_esci(false, true)
		get_viewport().set_input_as_handled()
		return
	if _finita:
		return
	if event.is_action_pressed("vandalize"):   # [F]
		_accusa()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------
# 'A fine
# ---------------------------------------------------------------------------

var _mio_punti: int = 0
var _suo_punti: int = 0


func _vinto_ora() -> bool:
	return _mio_punti > _suo_punti


func _patta_ora() -> bool:
	return _mio_punti == _suo_punti


func _chiudi_partita() -> void:
	_finita = true
	_bloccato = true
	_scorda_scelta()
	var p: Dictionary = _m.punteggio()
	_mio_punti = int(p["punti"][0])
	_suo_punti = int(p["punti"][1])
	var vinto: bool = _vinto_ora()

	_mostra_gioco(false)
	_svuota(_fine)

	# --- Il risultato, grosso ---------------------------------------------
	var l := US.etichetta("", 36, Color(1, 1, 1))
	l.add_theme_font_override("font", US.font_titolo())
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if vinto:
		l.text = "HÊ VINTO!  +€%d" % (puntata * 2)
		l.add_theme_color_override("font_color", Color(0.62, 1.0, 0.62))
		_dice(str(sfidante.get("vinto", "Bravo.")))
		SoundManager.ui("ui_vittoria")
	elif _patta_ora():
		l.text = "PATTA. 'A puntata torna."
		l.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6))
		_dice("Patta. Nun ha vinciuto nisciuno.")
	else:
		l.text = "HÊ PERZO €%d" % puntata
		l.add_theme_color_override("font_color", Color(1.0, 0.56, 0.5))
		_dice("Te ll'avevo ditto. Turnate quanno hê 'mparato.")
		SoundManager.play("perso", -8.0)
	_fine.add_child(l)

	# --- 'A tabella finale, voce per voce -----------------------------------
	var tab := PanelContainer.new()
	tab.add_theme_stylebox_override("panel", US.box(Color(0.03, 0.10, 0.06, 0.8),
		Color(US.ORO.r, US.ORO.g, US.ORO.b, 0.45), 2, 14, 22.0, 14.0))
	tab.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fine.add_child(tab)
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 26)
	g.add_theme_constant_override("v_separation", 7)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tab.add_child(g)
	for h in ["", "TU", "ISSO", "'O PUNTO"]:
		var hl := US.etichetta(h, 13, Color(0.7, 0.86, 0.74), true)
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		g.add_child(hl)
	for v in p["voci"]:
		var chi := int(v.get("chi", -1))
		var nome := str(v["nome"])
		g.add_child(US.etichetta(nome, 17, Color(0.94, 0.96, 0.92)))
		for k in ["a", "b"]:
			var val = v[k]
			var txt: String = str(val)
			if nome == "Settebello":
				txt = "✓" if int(val) > 0 else "–"
			var acceso: bool = (chi == 0 and k == "a") or (chi == 1 and k == "b")
			var n := US.etichetta(txt, 18, US.ORO_CHIARO if acceso
				else Color(0.8, 0.84, 0.8), acceso)
			n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			g.add_child(n)
		var chi_t := "—"
		var chi_c := Color(0.7, 0.72, 0.7)
		if nome == "Scope":
			chi_t = "%d a te, %d a isso" % [int(v["a"]), int(v["b"])]
			chi_c = Color(0.86, 0.9, 0.86)
		elif chi == 0:
			chi_t = "a te"
			chi_c = Color(0.62, 1.0, 0.62)
		elif chi == 1:
			chi_t = "a isso"
			chi_c = Color(1.0, 0.66, 0.56)
		var ct := US.etichetta(chi_t, 15, chi_c)
		ct.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		g.add_child(ct)
	g.add_child(US.etichetta("PUNTE", 18, US.ORO_CHIARO, true))
	for val2 in [_mio_punti, _suo_punti]:
		var tl := US.etichetta(str(val2), 22, US.ORO_CHIARO, true)
		tl.add_theme_font_override("font", US.font_titolo())
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		g.add_child(tl)
	g.add_child(Control.new())

	if _accuse_sbagliate > 0:
		var l2 := US.etichetta("%d accuse a vacante: −€%d 'e figura."
			% [_accuse_sbagliate, _accuse_sbagliate * 5], 15, Color(1.0, 0.75, 0.6))
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_fine.add_child(l2)

	# --- 'O turneo: chi hai sbloccato --------------------------------------
	_fine.add_child(_riquadro_turneo(vinto))

	var riga := HBoxContainer.new()
	riga.alignment = BoxContainer.ALIGNMENT_CENTER
	_fine.add_child(riga)
	var b := Button.new()
	b.text = "Vabbuo'  [Esc]"
	b.custom_minimum_size = Vector2(280, 50)
	var patta: bool = _patta_ora()
	b.pressed.connect(func(): _esci(vinto, false, patta))
	riga.add_child(b)
	b.call_deferred("grab_focus")


## **'O riquadro d''o turneo** a fine partita.
##
## È la risposta a *«spiega al giocatore che vincendo ha sbloccato la sfida
## col prossimo maestro di scopa»*: chi è, quanti anni ha, dove sta, quanto
## si gioca, e che sulla chiantina è già segnato.
func _riquadro_turneo(vinto: bool) -> Control:
	var id: String = str(sfidante.get("id", ""))
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	var col := Color(0.6, 0.7, 0.64)
	var titolo := ""
	var righe: Array = []
	var prossimo: Dictionary = dopo_di(id)
	if vinto and _prima_vota:
		if prossimo.is_empty():
			col = US.ORO
			titolo = "HÊ VINTO 'O TURNEO!"
			righe = ["Don Gennaro te dà 'o mazzo suojo: nisciuno cchiù te po' fa' fesso.",
				"Premio: €%d." % int(sfidante.get("premio", 0))]
		else:
			col = US.VERDE
			titolo = "SFIDA SBLOCCATA: %s" % str(prossimo["nome"]).to_upper()
			righe = [
				"Mo' puoi sfidà a %s (%d anne): se joca €%d." % [
					str(prossimo["nome"]), int(prossimo["eta"]),
					int(prossimo["puntata"])],
				"'O truove a %s — sta segnato 'ncopp'â chiantina [M]." %
					dove_sta(str(prossimo["id"])),
			]
			if int(sfidante.get("premio", 0)) > 0:
				righe.append("E ce sta 'o premio: €%d." % int(sfidante["premio"]))
	elif vinto:
		titolo = "L'HÊ GIÀ BATTUTO"
		if prossimo.is_empty():
			righe = ["'O turneo l'hê già vinciuto. Chesta era pe' sfizio."]
		else:
			var dopo: String = GameManager.prossimo_sfidante()
			var pd: Dictionary = GameManager.sfidante(dopo)
			if pd.is_empty():
				righe = ["'O turneo l'hê già vinciuto."]
			else:
				righe = ["'O prossimo d''o turneo è %s, a %s." % [
					str(pd["nome"]), dove_sta(dopo)]]
	else:
		titolo = "'O TURNEO"
		if _prima_vota and not prossimo.is_empty():
			righe = ["Vence a %s pe' sbloccà 'o prossimo maestro: %s." % [
				str(sfidante.get("nome", "")), str(prossimo["nome"])]]
		else:
			righe = ["Vence a %s pe' ghì annanze." % str(sfidante.get("nome", ""))]
	p.add_theme_stylebox_override("panel", US.box(Color(col.r, col.g, col.b, 0.16),
		Color(col.r, col.g, col.b, 0.7), 2, 14, 22.0, 12.0))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(h)
	h.add_child(US.figura("sbloccato" if (vinto and _prima_vota) else "classifica",
		22, col.lerp(Color(1, 1, 1), 0.3)))
	var t := US.etichetta(titolo, 19, col.lerp(Color(1, 1, 1), 0.35))
	t.add_theme_font_override("font", US.font_titolo())
	h.add_child(t)
	for r in righe:
		var rl := US.etichetta(str(r), 16, Color(0.95, 0.96, 0.92))
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(rl)
	if vinto and _prima_vota:
		SoundManager.ui("ui_sblocco")
	return p


func _esci(vinto: bool, scappato: bool = false, patta: bool = false) -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
	GameManager.piglia_o_mouse(true)
	_svuota(_fine)
	_svuota(_ultima)
	_scorda_scelta()
	SoundManager.ui("ui_chiudi")
	if _accuse_sbagliate > 0:
		GameManager.money = maxi(0, GameManager.money - _accuse_sbagliate * 5)
		GameManager.money_changed.emit(GameManager.money)
		_accuse_sbagliate = 0
	var id: String = str(sfidante.get("id", ""))
	if patta:
		GameManager.add_money(puntata)   # la puntata torna
	elif scappato:
		GameManager.gioco_azzardo(-puntata)
		GameManager.event_started.emit("Sî scappato 'a tavola. 'A puntata resta 'a isso.")
	else:
		GameManager.scopa_esito(id, vinto, puntata)
		# Il cartello ripete la notizia quando ti alzi: la schermata finale
		# si chiude in fretta, e la cosa importante deve restare.
		if vinto and _prima_vota:
			var pr: Dictionary = dopo_di(id)
			if not pr.is_empty():
				GameManager.event_started.emit(
					"SFIDA SBLOCCATA: %s t'aspetta a %s. È segnato 'ncopp'â chiantina." % [
					str(pr["nome"]), dove_sta(str(pr["id"]))])
	_finita = true
	chiusa.emit(vinto)


func _svuota(c: Control) -> void:
	if c == null:
		return
	for x in c.get_children():
		c.remove_child(x)
		x.queue_free()
