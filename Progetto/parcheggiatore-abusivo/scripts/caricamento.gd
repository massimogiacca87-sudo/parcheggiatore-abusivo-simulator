extends CanvasLayer
## 'A schermata 'e caricamento — due pagine
##
## Sta davanti a tutto mentre la città si costruisce, e fa tre cose:
## dice che il gioco è partito (prima erano cinque secondi di schermo nero
## in cui non si capiva se fosse crashato), mostra le due illustrazioni, e
## soprattutto **spiega il gioco** — che è il posto giusto per farlo, perché
## uno legge mentre aspetta, non mentre ha già un cliente che strombazza.
##
## **Perché due pagine e non una.** Il tutorial è lungo: mestiere, vigile,
## carabinieri, piazze, comandi. Su una schermata sola o si scrive piccolo
## (e non si legge) o si taglia (e non si capisce). Due pagine, una per
## illustrazione: la prima è il mestiere, la seconda è la città.
##
## **Perché il testo sta in basso e non a lato.** Le due illustrazioni
## hanno la faccia del personaggio a metà altezza e il marchio in alto a
## destra: l'unica fascia che si può coprire senza rovinare l'immagine è il
## terzo basso. Che è anche dove le immagini hanno già stampato sopra un
## testo finto e un bollino "v0.XX" — quelli il pannello li copre, ed è
## voluto: il numero di versione vero lo scrive il gioco, che lo sa.

signal comincia

## **Due liste, e non una: è qui che nasceva il doppione.**
##
## Prima ce n'era una sola, `PAGINE`, usata per due cose diverse: le
## locandine d'apertura *e* lo sfondo delle pagine del tutorial. Finché
## erano due e due tornava; poi il tutorial è passato a tre pagine, e per
## farci stare il terzo sfondo ho aggiunto una riga alla lista — con il
## risultato che l'apertura mostrava **tre locandine**, cioè la prima due
## volte. Il difetto era esattamente lì: una lista con due padroni.
##
## `LOCANDINE` sono i manifesti d'apertura, e sono due.
const LOCANDINE := [
	"res://assets/splash_1.jpg",
	"res://assets/splash_2.jpg",
]

const ORO := Color(1.0, 0.84, 0.36)
const CREMA := Color(0.96, 0.94, 0.90)
const FONDO := Color(0.055, 0.05, 0.075)
const VERSIONE := "v0.66"

## **'O tutoriale, rifatto 'a capo ê 0.50.**
##
## Il giudizio del capo: *"al momento si sovrappongono e non si capisce
## niente… fallo più schematico e sintetico, in italiano magari, deve essere
## comprensibile a chiunque"*.
##
## Il difetto non era il contenuto, era la forma. Le pagine erano **due
## colonne di prosa lunga**, in corpo 14, stampate sopra a un'illustrazione
## piena di dettagli, sotto a un velo semitrasparente. Tre cose che
## remano contro la lettura tutte insieme: righe lunghe, testo piccolo,
## fondo mosso. E se la finestra era stretta le due colonne si
## avvicinavano finché non si toccavano.
##
## Adesso: **schermo nero**, una colonna sola, corpo grande, e ogni riga è
## una coppia — a sinistra il tasto o la cosa, a destra cosa fa. Chi legge
## non deve seguire un discorso: deve poter saltare alla riga che gli
## serve. E l'italiano è italiano, non napoletano: il napoletano sta nel
## gioco, non nelle istruzioni.
##
## Le illustrazioni restano dove hanno senso: **da sole**, durante il
## caricamento, senza niente sopra.
const Tutoriale := preload("res://scripts/tutoriale.gd")

## **'E ppagine nun stanno cchiù ccà (0.52).** Stanno in `tutoriale.gd`, e
## le legge pure il menu di pausa: due tutorial sarebbero due cose che
## divergono — si aggiunge una meccanica, si aggiorna una delle due, e da
## lì in poi il gioco spiega due giochi diversi.
const TESTI := Tutoriale.PAGINE

var _sfondo: TextureRect
var _pannello: Control
var _barra: ProgressBar
var _stato: Label
var _invito: Label
var _pagina: int = 0
var _pronto: bool = false
var _lampo: float = 0.0
var _obiettivo: float = 0.0
var _accetta: bool = false

# ---------------------------------------------------------------------------
# Le tre fasi
# ---------------------------------------------------------------------------
#
# **Prima le illustrazioni si vedevano a metà.** Il pannello del testo
# partiva a metà altezza e copriva tutto il terzo basso: due disegni fatti
# apposta, e di ognuno se ne vedeva la faccia e basta. Adesso prima si
# guardano — intere, senza niente sopra, con la barra di caricamento in
# fondo e nient'altro — e solo dopo esce il tutorial.
#
# E il tutorial non è più una tassa d'ingresso: si legge la prima volta,
# poi si va al menu, e da lì ci si torna quando si vuole.
enum Fase { LOCANDINA, MENU, TUTORIAL }

var _fase: int = Fase.LOCANDINA
var _locandina: int = 0
## Vero quando il tutorial è stato aperto dal menu: finito, si torna al
## menu invece di cominciare la partita.
var _dal_menu: bool = false


func _ready() -> void:
	layer = 220
	process_mode = Node.PROCESS_MODE_ALWAYS
	_costruisci()
	_mostra_locandina(0)


# ---------------------------------------------------------------------------
# Costruzione
# ---------------------------------------------------------------------------

func _costruisci() -> void:
	var fondo := ColorRect.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.color = FONDO
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)

	_sfondo = TextureRect.new()
	_sfondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	# COVER e non STRETCH: un'illustrazione deformata per riempire lo schermo
	# si vede sempre, e su un disegno fatto apposta si vede il doppio.
	_sfondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	# **Senza questo l'immagine esce dallo schermo.** Un TextureRect si
	# porta dietro la dimensione della texture come dimensione MINIMA: un
	# fondale da 1600x893 dentro a un canvas da 1152x648 non si rimpicciolisce
	# per via delle ancore — resta 1600x893 ancorato in alto a sinistra, e a
	# schermo si vede il 72% dell'immagine ingrandito. IGNORE_SIZE toglie il
	# minimo e lascia decidere alle ancore.
	_sfondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sfondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sfondo)

	# Il pannello del testo: una sfumatura che parte trasparente e chiude
	# quasi opaca in basso. Un rettangolo pieno taglierebbe l'immagine con
	# una riga netta; la sfumatura la fa sprofondare nel buio.
	_pannello = Control.new()
	_pannello.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pannello.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pannello)

	# La barra e le scritte di servizio, in fondo.
	_barra = ProgressBar.new()
	_barra.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_barra.position = Vector2(-320, -46)
	_barra.custom_minimum_size = Vector2(640, 10)
	_barra.size = Vector2(640, 10)
	_barra.min_value = 0.0
	_barra.max_value = 1.0
	_barra.value = 0.0
	_barra.show_percentage = false
	var pieno := StyleBoxFlat.new()
	pieno.bg_color = ORO
	pieno.set_corner_radius_all(3)
	var vuoto := StyleBoxFlat.new()
	vuoto.bg_color = Color(1, 1, 1, 0.14)
	vuoto.set_corner_radius_all(3)
	_barra.add_theme_stylebox_override("fill", pieno)
	_barra.add_theme_stylebox_override("background", vuoto)
	add_child(_barra)

	_stato = _scritta("Se sta apparecchiann''a città…", 14, CREMA,
		HORIZONTAL_ALIGNMENT_CENTER)
	_stato.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_stato.position = Vector2(-320, -34)
	_stato.size = Vector2(640, 20)
	_stato.modulate.a = 0.7
	add_child(_stato)

	_invito = _scritta("", 20, ORO, HORIZONTAL_ALIGNMENT_CENTER)
	_invito.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_invito.position = Vector2(-420, -34)
	_invito.size = Vector2(840, 28)
	_invito.visible = false
	add_child(_invito)

	# Il numero di versione, dove le immagini hanno il bollino finto.
	var ver := _scritta(VERSIONE, 13, ORO, HORIZONTAL_ALIGNMENT_RIGHT)
	ver.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ver.position = Vector2(-160, -22)
	ver.size = Vector2(146, 18)
	ver.modulate.a = 0.75
	add_child(ver)


func _scritta(testo: String, misura: int, colore: Color,
		allinea: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = testo
	l.add_theme_font_size_override("font_size", misura)
	l.add_theme_color_override("font_color", colore)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 4)
	l.horizontal_alignment = allinea
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _ricco(misura: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = false
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.add_theme_font_size_override("normal_font_size", misura)
	r.add_theme_font_size_override("bold_font_size", misura)
	r.add_theme_color_override("default_color", CREMA)
	r.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	r.add_theme_constant_override("outline_size", 4)
	r.add_theme_constant_override("line_separation", 3)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


# ---------------------------------------------------------------------------
# Le pagine
# ---------------------------------------------------------------------------

## Traduce le due marche del testo — [g]…[/g] per i tasti e le cifre,
## [b]…[/b] per le frasi che devono saltare all'occhio — in bbcode vero.
## Sono scritte così nella tabella perché il colore dell'oro sta qui e non
## va ripetuto dodici volte a mano.
func _bb(testo: String) -> String:
	var oro := ORO.to_html(false)
	return testo.replace("[g]", "[color=#%s][b]" % oro) \
		.replace("[/g]", "[/b][/color]")


## La locandina e basta: niente velo, niente testo, e l'immagine INTERA —
## `KEEP_ASPECT_CENTERED` invece di `COVERED`, così su uno schermo di
## proporzioni diverse si vede tutta con due bande scure invece di essere
## tagliata ai lati.
func _mostra_locandina(n: int) -> void:
	_fase = Fase.LOCANDINA
	_locandina = clampi(n, 0, LOCANDINE.size() - 1)
	if ResourceLoader.exists(str(LOCANDINE[_locandina])):
		_sfondo.texture = load(str(LOCANDINE[_locandina]))
	_sfondo.visible = true
	_sfondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_pannello.visible = false
	if _barra != null:
		_barra.visible = not _pronto
	if _stato != null:
		_stato.visible = not _pronto
	if _menu != null:
		_menu.visible = false
	_aggiorna_invito()


func _mostra_pagina(n: int) -> void:
	_fase = Fase.TUTORIAL
	_pannello.visible = true
	if _menu != null:
		_menu.visible = false
	# **Schermo nero.** L'illustrazione si spegne: il tutorial è testo, e il
	# testo su una fotografia non si legge — è metà del motivo per cui
	# prima "non si capiva niente".
	_sfondo.visible = false
	_pagina = clampi(n, 0, TESTI.size() - 1)
	# **'E ppagine se sovrapponevano, ed ecco pecché.**
	#
	# `queue_free()` non cancella: **mette in coda**. Il nodo resta
	# nell'albero — e quindi resta disegnato — fino alla fine del frame.
	# Se nello stesso frame se ne costruisce un altro, per almeno un
	# disegno ce ne sono due sovrapposti, e con due pagine di testo giallo
	# su nero il risultato è illeggibile. Con il tasto premuto due volte in
	# fretta capitava ancora più spesso.
	#
	# `remove_child()` invece stacca subito; il `queue_free()` dopo serve
	# solo a liberare la memoria.
	for c in _pannello.get_children():
		if c.name == "Testo":
			_pannello.remove_child(c)
			c.queue_free()
	# La barra di caricamento e la sua scritta non c'entrano niente con il
	# tutorial: durante il caricamento stanno sopra all'illustrazione, qui
	# starebbero sopra al testo.
	if _barra != null:
		_barra.visible = false
	if _stato != null:
		_stato.visible = false

	var dati: Dictionary = TESTI[_pagina]
	var testo := Control.new()
	testo.name = "Testo"
	testo.set_anchors_preset(Control.PRESET_FULL_RECT)
	testo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pannello.add_child(testo)

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 90
	col.offset_right = -90
	col.offset_top = 54
	col.offset_bottom = -76
	col.add_theme_constant_override("separation", 12)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	testo.add_child(col)

	var cap := _scritta("%d / %d   ·   %s" % [_pagina + 1, TESTI.size(),
		str(dati["titolo"])], 26, ORO)
	col.add_child(cap)

	var sopra := str(dati.get("sopra", ""))
	if sopra != "":
		var sl := _scritta(sopra, 17, CREMA)
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sl.custom_minimum_size = Vector2(0, 24)
		sl.modulate.a = 0.82
		col.add_child(sl)

	# La griglia: a sinistra la cosa, a destra cosa fa. Due colonne
	# **allineate**, non due colonne di prosa: si scorre con l'occhio.
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 26)
	g.add_theme_constant_override("v_separation", 11)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(g)
	for r in dati["righe"]:
		var k := _scritta(str(r[0]), 18, ORO, HORIZONTAL_ALIGNMENT_RIGHT)
		k.custom_minimum_size = Vector2(230, 0)
		g.add_child(k)
		var d := _scritta(str(r[1]), 18, CREMA)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(d)

	var chiusa := str(dati.get("chiusa", ""))
	if chiusa != "":
		var cl := _scritta(chiusa, 17, ORO, HORIZONTAL_ALIGNMENT_CENTER)
		cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cl.modulate.a = 0.9
		cl.custom_minimum_size = Vector2(0, 40)
		col.add_child(cl)

	_aggiorna_invito()


func _aggiorna_invito() -> void:
	if not _pronto:
		return
	if _fase == Fase.MENU:
		_invito.visible = false
		return
	_invito.visible = true
	if _fase == Fase.LOCANDINA:
		_invito.text = "Schiaccia nu tasto pe' cuntinuà  ▸"
		return
	_invito.text = "Schiaccia nu tasto pe' cuntinuà  ▸" \
		if _pagina < TESTI.size() - 1 else "Schiaccia nu tasto pe' ji' ô menù"


# ---------------------------------------------------------------------------
# 'O menù 'e ll'inizio
# ---------------------------------------------------------------------------

var _menu: Control = null
var _menu_box: VBoxContainer = null
var _menu_primo: Button = null
var _slot_box: VBoxContainer = null


func _costruisci_menu() -> void:
	if _menu != null:
		return
	_menu = Control.new()
	_menu.name = "Menu"
	_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_menu)

	# Un velo sopra tutta l'illustrazione: i bottoni devono staccarsi, e su
	# un disegno pieno di dettagli un bottone chiaro sparisce.
	var velo := ColorRect.new()
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.color = Color(0.03, 0.03, 0.05, 0.58)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu.add_child(velo)

	var pannello := PanelContainer.new()
	pannello.set_anchors_preset(Control.PRESET_CENTER)
	pannello.position = Vector2(-190, -170)
	pannello.custom_minimum_size = Vector2(380, 0)
	var stile := StyleBoxFlat.new()
	stile.bg_color = Color(0.07, 0.06, 0.09, 0.94)
	stile.border_color = ORO
	stile.set_border_width_all(2)
	stile.set_corner_radius_all(6)
	stile.set_content_margin_all(20)
	pannello.add_theme_stylebox_override("panel", stile)
	_menu.add_child(pannello)

	_menu_box = VBoxContainer.new()
	_menu_box.add_theme_constant_override("separation", 10)
	pannello.add_child(_menu_box)

	var tit := _scritta("PARCHEGGIATORE ABUSIVO", 20, ORO,
		HORIZONTAL_ALIGNMENT_CENTER)
	tit.custom_minimum_size = Vector2(340, 30)
	_menu_box.add_child(tit)

	_menu_primo = _bottone("Accummenciamo", _on_menu_gioca)
	_bottone("Carica 'na partita", _on_menu_carica)
	_bottone("'O tutoriale", _on_menu_tutorial)
	_bottone("Esci", func(): get_tree().quit())

	# La lista degli slot, nascosta finché non la si chiede.
	_slot_box = VBoxContainer.new()
	_slot_box.add_theme_constant_override("separation", 6)
	_slot_box.visible = false
	_menu_box.add_child(_slot_box)


func _bottone(testo: String, quando: Callable) -> Button:
	var b := Button.new()
	b.text = testo
	b.custom_minimum_size = Vector2(340, 40)
	b.add_theme_font_size_override("font_size", 16)
	b.pressed.connect(quando)
	_menu_box.add_child(b)
	return b


func _mostra_menu() -> void:
	_fase = Fase.MENU
	_costruisci_menu()
	_pannello.visible = false
	_menu.visible = true
	_slot_box.visible = false
	_sfondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_aggiorna_invito()
	if _menu_primo:
		_menu_primo.grab_focus()


func _on_menu_gioca() -> void:
	_fase = Fase.MENU
	set_process_input(false)
	# **Ccà se piglia 'o mouse, e ccà sulo** (0.56b).
	#
	# Questo è il primo click vero della partita, e sul browser il Pointer
	# Lock si concede **soltanto** dentro a un gesto dell'utente: la
	# richiesta che il giocatore faceva dentro al proprio `_ready()`, mentre
	# la scena si costruiva, il browser la buttava via in silenzio. Da un
	# handler di `pressed` invece passa.
	GameManager.piglia_o_mouse(true)
	comincia.emit()
	queue_free()


func _on_menu_tutorial() -> void:
	_dal_menu = true
	_accetta = true
	_mostra_pagina(0)


## La lista dei salvataggi, dentro allo stesso pannello: aprire una finestra
## nuova sopra al menu, in una schermata che è già una finestra sopra a
## un'illustrazione, sarebbe stato un pannello di troppo.
func _on_menu_carica() -> void:
	for c in _slot_box.get_children():
		c.queue_free()
	var qualcosa := false
	for i in range(GameManager.SLOT_MAX):
		if not GameManager.slot_pieno(i):
			continue
		qualcosa = true
		var b := Button.new()
		b.text = "%d.  %s" % [i + 1, GameManager.descrizione_slot(i)]
		b.custom_minimum_size = Vector2(340, 34)
		b.add_theme_font_size_override("font_size", 12)
		b.pressed.connect(_carica_slot.bind(i))
		_slot_box.add_child(b)
	if not qualcosa:
		var vuoto := _scritta("Nun ce sta nisciuna partita salvata.", 13,
			CREMA, HORIZONTAL_ALIGNMENT_CENTER)
		vuoto.custom_minimum_size = Vector2(340, 24)
		_slot_box.add_child(vuoto)
	_slot_box.visible = true


func _carica_slot(i: int) -> void:
	if not GameManager.carica_da_slot(i):
		return
	# La città è già in piedi, ma è stata costruita con le zone di partenza.
	# Si ricarica la scena così tutto — piazze tue, guagliuni, decorazioni —
	# nasce già giusto; e `salta_intro` fa saltare locandine e volata, che
	# chi carica una partita le ha già viste.
	GameManager.salta_intro = true
	set_process_input(false)
	get_tree().paused = false
	get_tree().reload_current_scene()


# ---------------------------------------------------------------------------
# Avanzamento
# ---------------------------------------------------------------------------

## Avanzamento, da 0 a 1. La barra ci va dietro morbida invece di saltarci:
## un salto secco fa sembrare che il numero sia finto (e lo sarebbe).
func passo(quanto: float, testo: String = "") -> void:
	_obiettivo = clampf(quanto, 0.0, 1.0)
	if testo != "" and _stato != null:
		_stato.text = testo


func pronto() -> void:
	_obiettivo = 1.0
	_pronto = true
	if _stato != null:
		_stato.text = "'A città è pronta."
	_aggiorna_invito()


func _process(delta: float) -> void:
	if _barra != null:
		_barra.value = move_toward(_barra.value, _obiettivo, delta * 0.9)
	if not _pronto:
		return
	if _barra != null and _barra.value < 0.999:
		return
	# Finito il caricamento la barra e lo stato spariscono: al loro posto
	# c'è l'invito che lampeggia, e basta.
	if _barra != null and _barra.visible:
		_barra.visible = false
		_stato.visible = false
		_invito.visible = true
	_accetta = true
	_lampo += delta * 2.6
	_invito.modulate.a = 0.58 + 0.42 * (0.5 + 0.5 * sin(_lampo))


func _input(event: InputEvent) -> void:
	if not _accetta:
		return
	var vale: bool = event is InputEventKey and event.pressed and not event.echo
	vale = vale or (event is InputEventMouseButton and event.pressed)
	vale = vale or (event is InputEventJoypadButton and event.pressed)
	if not vale:
		return
	# **Nel menu l'input NON si mangia.** Comandano i bottoni, e
	# `set_input_as_handled()` prima di questo controllo si divorava il
	# click prima che arrivasse al bottone: il menu sembrava morto.
	if _fase == Fase.MENU:
		return

	get_viewport().set_input_as_handled()

	if _fase == Fase.LOCANDINA:
		_accetta = false
		if _locandina < LOCANDINE.size() - 1:
			_mostra_locandina(_locandina + 1)
		else:
			# **'O tutoriale nun sta cchiù 'a miezo.**
			# Prima, alla prima partita, dopo le locandine partivano tre
			# pagine di spiegazioni obbligatorie. Il capo: *"il tutorial è
			# richiamabile dal menu iniziale quindi fai che si vedono solo
			# le splash images durante il caricamento"*. Giusto: durante il
			# caricamento uno guarda, non studia. Adesso si va dritti al
			# menu, e chi vuole leggere preme "'O tutoriale".
			GameManager.tutorial_seen = true
			_mostra_menu()
		_lampo = 0.0
		await get_tree().create_timer(0.30).timeout
		_accetta = true
		return

	if _pagina < TESTI.size() - 1:
		# Un attimo di guardia: senza, la stessa pressione che gira pagina
		# fa anche partire il gioco (il tasto genera premuto e rilasciato).
		_accetta = false
		_mostra_pagina(_pagina + 1)
		_lampo = 0.0
		await get_tree().create_timer(0.35).timeout
		_accetta = true
		return
	# Finito il tutorial si va sempre al menu: chi vuole giocare preme il
	# primo bottone, che ha già il fuoco.
	_accetta = false
	_dal_menu = false
	_mostra_menu()
	await get_tree().create_timer(0.30).timeout
	_accetta = true
