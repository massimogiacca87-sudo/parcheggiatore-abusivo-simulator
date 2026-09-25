extends CanvasLayer
## PannelloCasa — 'a consegna d''e sorde
##
## **La schermata più importante del gioco, e non ha nessun pulsante
## "compra".** Da 'O Zio si sceglie, qui si consegna: c'è un elenco di
## conti che ha deciso qualcun altro, c'è quello che hai in tasca, e c'è da
## decidere quanto ne lasci andare.
##
## Le scelte di disegno che contano:
##
## - **Le bollette stanno in ordine di gravità**, non di importo: 'a luce e
##   'o fitto sopra, perché sono quelle che fanno succedere le cose.
## - **I tasti sono pochi e grossi** e dicono già il numero: "Tutto quello
##   che ce vo' (€68)", "Tutto chello ca tengo (€41)". Nessuno slider da
##   trascinare: qui non si ottimizza, si decide.
## - **Quello che avanza lo tiene lei**, e l'umore sale. È l'unico modo
##   veloce di rimetterla di buonumore, e costa soldi veri.

const LARGH: float = 660.0

var _fondo: ColorRect
var _pannello: PanelContainer
var _titolo: Label
var _frase: Label
var _lista: Label
var _sacca: Label
var _bottoni: VBoxContainer
var _aperto: bool = false


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_costruisci()


func _costruisci() -> void:
	_fondo = ColorRect.new()
	_fondo.color = Color(0, 0, 0, 0.62)
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_fondo)

	_pannello = PanelContainer.new()
	_pannello.set_anchors_preset(Control.PRESET_CENTER)
	_pannello.custom_minimum_size = Vector2(LARGH, 0)
	_pannello.position = Vector2(-LARGH * 0.5, -250)
	add_child(_pannello)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_pannello.add_child(v)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 22)
	m.add_theme_constant_override("margin_right", 22)
	m.add_theme_constant_override("margin_top", 18)
	m.add_theme_constant_override("margin_bottom", 18)
	_pannello.remove_child(v)
	m.add_child(v)
	_pannello.add_child(m)

	_titolo = Label.new()
	_titolo.text = "'A CONSEGNA"
	_titolo.add_theme_font_size_override("font_size", 26)
	v.add_child(_titolo)

	_frase = Label.new()
	_frase.autowrap_mode = TextServer.AUTOWRAP_WORD
	_frase.custom_minimum_size = Vector2(LARGH - 60, 0)
	_frase.modulate = Color(1.0, 0.86, 0.62)
	v.add_child(_frase)

	var sep := HSeparator.new()
	v.add_child(sep)

	_lista = Label.new()
	_lista.autowrap_mode = TextServer.AUTOWRAP_WORD
	_lista.custom_minimum_size = Vector2(LARGH - 60, 0)
	v.add_child(_lista)

	_sacca = Label.new()
	_sacca.modulate = Color(0.82, 0.92, 0.78)
	v.add_child(_sacca)

	_bottoni = VBoxContainer.new()
	_bottoni.add_theme_constant_override("separation", 6)
	v.add_child(_bottoni)


func aperto() -> bool:
	return _aperto


## **Sempe 'mmiezo** (0.62). Il pannello partiva da 250 px sopra al centro
## e cresceva verso il basso: con due spese e sei bottoni l'ultimo
## («Vabbuo', mo' vengo») finiva sotto al bordo dello schermo. Adesso si
## rimette al centro ogni volta che cambia il contenuto, alto quanto serve.
func _process(_d: float) -> void:
	if not visible or _pannello == null:
		return
	var alto: float = _pannello.get_combined_minimum_size().y
	var vista: float = get_viewport().get_visible_rect().size.y
	alto = minf(alto, vista - 16.0)
	_pannello.offset_left = -LARGH * 0.5
	_pannello.offset_right = LARGH * 0.5
	_pannello.offset_top = -alto * 0.5
	_pannello.offset_bottom = alto * 0.5


# ---------------------------------------------------------------------------
# 'A consegna
# ---------------------------------------------------------------------------

func apri_consegna() -> void:
	_aperto = true
	visible = true
	get_tree().paused = true
	GameManager.piglia_o_mouse(false)
	_aggiorna()


func _aggiorna() -> void:
	var gm := GameManager
	# Se è tardi e non le hai ancora dato le sue, la prima cosa che vuole è
	# quella: la consegna delle bollette viene dopo.
	if gm.extra_richiesto <= 0 and not gm.extra_dato \
			and gm.ora_ritiro > 12.0:
		var d: Dictionary = gm.chiedi_extra()
		if not d.is_empty():
			_mostra_extra(d)
			return
	if gm.extra_richiesto > 0 and not gm.extra_dato:
		_mostra_extra({"quanto": gm.extra_richiesto,
			"scusa": "", "frase": gm.frase_moglie("tardi")})
		return
	_mostra_consegna()


func _mostra_consegna() -> void:
	var gm := GameManager
	_titolo.text = "'A CONSEGNA — 'e %s" % gm.orologio()
	_frase.text = "« %s »" % gm.frase_moglie()

	var righe: Array = []
	var dovuto: int = gm.spese_dovute()
	if dovuto <= 0:
		righe.append("Nun ce sta niente 'a pavà. Pe' oggi.")
	else:
		for s in gm._ordine_spese():
			var rit: int = gm.giornata - int(s["giorno"])
			var coda := ""
			if rit > 0:
				coda = "   [%d juorne 'e ritardo]" % rit
			var segno := "!!" if bool(s["grave"]) else " ·"
			righe.append("%s  %-30s €%d%s"
				% [segno, str(s["nome"]), int(s["importo"]), coda])
			righe.append("      %s" % str(s.get("desc", "")))
		righe.append("")
		righe.append("   IN TUTTO: €%d" % dovuto)
	_lista.text = "\n".join(righe)
	_sacca.text = "In sacca tiene €%d.   Consegnato oggi: €%d." \
		% [gm.money, gm.consegnato_oggi]

	_svuota_bottoni()
	if dovuto > 0 and gm.money >= dovuto:
		_bottone("Tutto chello ca ce vo'  (€%d)" % dovuto,
			func(): _consegna(dovuto))
	if gm.money > 0:
		_bottone("Tutto chello ca tengo  (€%d)" % gm.money,
			func(): _consegna(gm.money))
	for taglio in [50, 20, 10]:
		if gm.money >= taglio and (dovuto > 0 or taglio <= gm.money):
			_bottone("Dalle €%d" % taglio, func(): _consegna(taglio))
	_bottone("Vabbuo', mo' vengo  [ESC]", chiudi)


func _consegna(quanto: int) -> void:
	var r: Dictionary = GameManager.consegna_a_moglie(quanto)
	var pezzi: Array = []
	for p in r.get("pagate", []):
		if bool(p.get("intera", false)):
			pezzi.append("%s pavata (€%d)" % [str(p["nome"]), int(p["importo"])])
		else:
			pezzi.append("%s, €%d ncopp''o cunto" % [str(p["nome"]), int(p["importo"])])
	if int(r.get("avanzo", 0)) > 0:
		pezzi.append("€%d s''e mette 'a parte." % int(r["avanzo"]))
	var moglie := get_tree().get_first_node_in_group("moglie")
	if moglie != null and moglie.has_method("dici"):
		if int(r.get("resta", 0)) <= 0:
			moglie.dici(GameManager.frase_moglie("bene"), 4.0)
		else:
			moglie.dici(GameManager.frase_moglie("poco"), 4.0)
	if not pezzi.is_empty():
		_frase.text = "« " + "  ".join(pezzi) + " »"
	_aggiorna()


# ---------------------------------------------------------------------------
# 'E spese personali
# ---------------------------------------------------------------------------

func _mostra_extra(d: Dictionary) -> void:
	var quanto: int = int(d.get("quanto", GameManager.extra_richiesto))
	_titolo.text = "'E SPESE SOIE — 'e %s" % GameManager.orologio()
	_frase.text = "« %s »" % str(d.get("frase", ""))
	var scusa: String = str(d.get("scusa", ""))
	var righe := ["Vo' €%d pe' essa." % quanto]
	if scusa != "":
		righe.append("Dice ca %s." % scusa)
	righe.append("")
	righe.append("Nun se tratta. O ce 'e ddaje o nun ce 'e ddaje.")
	_lista.text = "\n".join(righe)
	_sacca.text = "In sacca tiene €%d." % GameManager.money
	_svuota_bottoni()
	if GameManager.money >= quanto:
		_bottone("Tie', pigliatille  (€%d)" % quanto, func():
			GameManager.paga_extra()
			var m := get_tree().get_first_node_in_group("moglie")
			if m != null and m.has_method("dici"):
				m.dici("Bravo. Mo' va' a durmi'.", 3.4)
			_aggiorna())
	_bottone("Nun 'e ttengo, Nunzia", func():
		GameManager.rifiuta_extra()
		GameManager.extra_dato = true # chiesto e rifiutato: non lo richiede
		var m2 := get_tree().get_first_node_in_group("moglie")
		if m2 != null and m2.has_method("dici"):
			m2.dici("E certo. 'E sorde nun 'e ttiene maje pe' me.", 4.0)
		_aggiorna())


# ---------------------------------------------------------------------------

func _svuota_bottoni() -> void:
	for c in _bottoni.get_children():
		_bottoni.remove_child(c)
		c.queue_free()


func _bottone(testo: String, azione: Callable) -> void:
	var b := Button.new()
	b.text = testo
	b.custom_minimum_size = Vector2(LARGH - 60, 32)
	b.pressed.connect(azione)
	_bottoni.add_child(b)
	if _bottoni.get_child_count() == 1:
		b.call_deferred("grab_focus")


func chiudi() -> void:
	_aperto = false
	visible = false
	get_tree().paused = false
	GameManager.piglia_o_mouse(true)


func _unhandled_input(event: InputEvent) -> void:
	if not _aperto:
		return
	if event.is_action_pressed("ui_cancel"):
		chiudi()
		get_viewport().set_input_as_handled()
