extends CanvasLayer
## IntroScreen
## Schermata iniziale: titolo, quattro passi del ciclo di gioco e i comandi.
## Tiene il gioco in pausa finché il giocatore non preme INVIO (o clicca).
## Alla prima partita mostra il tutorial completo; dalle successive, solo il
## cartello breve — chi ha già capito non deve rileggere tutto ogni volta.

const Pad := preload("res://scripts/joypad.gd")

signal dismissed()

const BG := Color(0.06, 0.05, 0.08, 0.93)
const PANEL_BG := Color(0.11, 0.09, 0.13, 0.98)
const GOLD := Color(1.0, 0.83, 0.33)
const CREAM := Color(0.95, 0.93, 0.88)
const DIM := Color(0.72, 0.68, 0.66)

## Il ciclo di gioco, passo per passo: titolo, tasto, spiegazione.
const STEPS := [
	["1. Chiamale", "E", "Guardá 'a machina che arriva e falla accostà:\nmirala e schiaccia E."],
	["2. Falla parcheggià", "W A S D", "W = vien', S = ferm', A e D = gira. Cchiù è pulito,\ncchiù piglie. Oppure F: 'a pianti addò capita —\nma è multa."],
	["3. Fatte pagà", "E", "Va' addu 'o padrone e busse. Si fa 'o sordo…\nvide tu (click sinistro)."],
	["4. E po' 'e ccose 'e fianco", "C", "'E stemme se svitano ('E). 'E signore se\nborzeggiano (accuóvate cu 'o C e clicca). E ce\nstanno 'o pallone, 'o zaino (I) e seje manifeste\nannascunnute 'a fotografà."],
	["5. Vide 'e nun murì", "X", "Chiunque se stenne 'e cazzotte. Si 'e HP toie\nfenisceno, vaje 'o spitale — e quanno mine a\nquaccheduno, 'ncoppa vide 'e HP suoje."],
	["6. 'E stelle", "—", "Mine â gente pe' niente? 'Ncoppa a destra\ns'appicciano 'e stelle e veneno 'e carabinieri.\nVanno chiano: curre, annascuónnete, e se ne\nvanno. Si t'acchiappano, mena p''e te sciògliere."],
	["7. Se fatica sulo 'n piazza", "M", "'E machine arrivano SULO dint'â piazza toia. Cu M\ns'arape 'a chiantina e p''e strade ce stanno 'e\ncartielle. E 'a notte arriva Borrelli."],
	["8. Nun tiene niente", "—", "Nè sorde, nè sigarette, nè gilet: tutto s''adda\ncumprà. 'E ssigarette 'o tabaccaio, 'e ffierre 'o\nferraro — sta in fondo a 'nu vico ciec' 'e ll'est."],
	["9. 'E ppiazze se pigliano", "E", "S'accatta (€1000 + €50 'o juorno) o s''a piglie a\nmazzate: cu 'e mmane spuoglie nun ce prove manco.\nE ogne piazza ca tiene, 'o prossimo è cchiù tuosto."],
	["10. Parla cu tuttuquante", "E", "Cu 'a gente se parla (E), e pure cu 'e ccose:\nfuntanelle, banche d''o mercato, panchine — e\n'nnanz'â Maronna te faje 'o segno d''a croce."],
]

## Etichette corte apposta: stanno su quattro colonne, altrimenti la lista
## non entra più nello schermo insieme ai cinque passi.
const CONTROLS := [
	["Cammina", "W A S D"],
	["Corri", "SHIFT"],
	["Salta", "SPAZIO"],
	["Accovacciati", "C"],
	["Guarda", "Mouse"],
	["Interagisci", "E"],
	["Pugno · scippo", "Click sx"],
	["Mettila ccà · danneggia", "F"],
	["Sigaretta", "X"],
	["Fischietto", "Q"],
	["Caffè", "R"],
	["Zaino", "I"],
	["'A chiantina", "M"],
	["Compra", "1 – 6"],
	["Cagna 'e fierre", "G"],
	["Pausa", "ESC"],
]

## Gli stessi comandi, ma col joypad. I nomi dei tasti li mette Joypad, che
## sa se e' un PlayStation o un Xbox.
static func _controlli_pad() -> Array:
	return [
		["Cammina", "Stick sx"],
		["Guarda", "Stick dx"],
		["Corri", Pad.tasto("sprint")],
		["Salta", Pad.tasto("jump")],
		["Accovacciati", Pad.tasto("crouch")],
		["Interagisci", Pad.tasto("interact")],
		["Pugno · scippo", Pad.tasto("punch")],
		["Mettila ccà · danneggia", Pad.tasto("vandalize")],
		["Sigaretta", Pad.tasto("smoke")],
		["Fischietto", Pad.tasto("fischio")],
		["Caffè", Pad.tasto("caffe")],
		["Zaino", Pad.tasto("inventory")],
		["'A chiantina", Pad.tasto("mappa")],
		["Cagna 'e fierre", Pad.tasto("arma")],
		["Scegli / compra", "Croce dir. + " + Pad.tasto("jump")],
		["Pausa", Pad.tasto("ui_cancel")],
	]


## Righe extra sotto la lista comandi: le cose nuove che non stanno in una
## colonna sola.

var _root: Control
var _ready_to_close: bool = false
var _fade: float = 0.0


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.intro_active = true
	get_tree().paused = true
	GameManager.piglia_o_mouse(false)
	SoundManager.music_to_menu()
	_build()
	# Mezzo secondo di grazia: evita che un tasto premuto per sbaglio
	# nell'ultimo istante del caricamento salti subito la schermata.
	_ready_to_close = false


func _process(delta: float) -> void:
	_fade = minf(_fade + delta * 2.4, 1.0)
	_root.modulate.a = _fade
	if _fade >= 0.45:
		_ready_to_close = true


func _input(event: InputEvent) -> void:
	if not _ready_to_close:
		return
	var go := false
	if event is InputEventKey and event.pressed and not event.echo:
		go = true
	elif event is InputEventMouseButton and event.pressed:
		go = true
	elif event is InputEventJoypadButton and event.pressed:
		go = true # "premi un tasto qualsiasi" vale anche per il joypad
	if go:
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	GameManager.intro_active = false
	GameManager.tutorial_seen = true
	GameManager.save_game()
	get_tree().paused = false
	GameManager.piglia_o_mouse(true)
	SoundManager.music_to_gameplay()
	SoundManager.play("pop", -4.0)
	dismissed.emit()
	queue_free()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.modulate.a = 0.0
	add_child(_root)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)

	if GameManager.tutorial_seen:
		_build_short()
	else:
		_build_full()


## Cartello breve per chi ha già visto il tutorial.
func _build_short() -> void:
	var box := _panel(Vector2(-260, -122), Vector2(520, 244))
	_label(box, Vector2(0, 26), Vector2(520, 40),
		"PARCHEGGIATORE ABUSIVO", 30, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_label(box, Vector2(0, 68), Vector2(520, 26),
		"Simulator", 16, DIM, HORIZONTAL_ALIGNMENT_CENTER)
	var righe := "E = dirigi e bussa · F mentre dirigi = \"mettila ccà\"\nSPAZIO = salta · C = accovacciati · X = sigaretta\nClick = pugno e borseggio · I = zaino · 1-6 = compra"
	if Pad.collegato():
		righe = "%s = dirigi e bussa · %s = \"mettila ccà\" e danneggia\n%s = salta · %s = accovacciati · %s = sigaretta\n%s = pugno · %s = zaino · croce dir. + %s = compra" % [
			Pad.tasto("interact"), Pad.tasto("vandalize"), Pad.tasto("jump"),
			Pad.tasto("crouch"), Pad.tasto("smoke"), Pad.tasto("punch"),
			Pad.tasto("inventory"), Pad.tasto("jump")]
	_label(box, Vector2(0, 116), Vector2(520, 60), righe,
		15, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	_label(box, Vector2(0, 200), Vector2(520, 26),
		"Schiaccia nu tasto qualsiase pe' accummincià", 15, GOLD,
		HORIZONTAL_ALIGNMENT_CENTER)


## Tutorial completo della prima partita.
func _build_full() -> void:
	# I passi stanno su DUE colonne.
	#
	# Prima erano incolonnati uno sotto l'altro su meta' larghezza: con
	# sette passi la lista sforava il fondo dello schermo e l'elenco dei
	# comandi, che sta dopo, non si vedeva proprio — restava disegnato
	# sotto al bordo del monitor. Metterli affiancati usa lo spazio che
	# c'era gia' a destra e fa rientrare tutto con margine.
	const W := 940.0
	const COL := 452.0

	# L'altezza del pannello si CALCOLA, non si scrive.
	#
	# Era fissa a 618, ed e' gia' costato una volta: con sette passi
	# incolonnati la lista sforava lo schermo e i comandi finivano
	# disegnati sotto il bordo del monitor. Con un'altezza fissa lo stesso
	# guaio torna ogni volta che si aggiunge un passo — ed e' appena
	# successo, i passi adesso sono otto. Adesso si misura prima quanto
	# spazio vuole il testo, poi si fa il pannello.
	# `_altezze_colonne` restituisce gia' il fondo del contenuto, comandi
	# compresi: qui si aggiunge solo il margine. E si tiene dentro allo
	# schermo, che e' la ragione per cui tutto questo esiste.
	var alte := _altezze_colonne()
	var H: float = minf(maxf(alte[0], alte[1]) + 24.0,
		get_viewport().get_visible_rect().size.y - 16.0)
	var box := _panel(Vector2(-W / 2.0, -H / 2.0), Vector2(W, H))

	_label(box, Vector2(0, 12), Vector2(W, 40),
		"PARCHEGGIATORE ABUSIVO", 30, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_label(box, Vector2(0, 52), Vector2(W, 22),
		"Simulator — 'a piazza è 'a toia", 14, DIM,
		HORIZONTAL_ALIGNMENT_CENTER)

	_separator(box, 82.0, W, 0.7)

	var meta: int = int(ceil(float(STEPS.size()) / 2.0))
	var y := [94.0, 94.0]
	for i in STEPS.size():
		var step: Array = STEPS[i]
		var col: int = 0 if i < meta else 1
		var x: float = 34.0 + col * COL
		_label(box, Vector2(x, y[col]), Vector2(300, 24),
			str(step[0]), 17, GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		_key_chip(box, Vector2(x + 286.0, y[col]), str(step[1]))
		var body := str(step[2])
		var body_h := _text_height(body)
		_label(box, Vector2(x, y[col] + 23), Vector2(COL - 46.0, body_h),
			body, 13, CREAM, HORIZONTAL_ALIGNMENT_LEFT)
		y[col] += 23.0 + body_h + 8.0

	var fondo: float = maxf(y[0], y[1])
	_separator(box, fondo + 2.0, W, 0.5)

	# I comandi su quattro colonne sotto ai passi.
	var cy := fondo + 16.0
	var cols := 4
	var elenco: Array = _controlli_pad() if Pad.collegato() else CONTROLS
	var rows := int(ceil(float(elenco.size()) / float(cols)))
	for i in elenco.size():
		var col2: int = i % cols
		var row: int = i / cols
		var cx: float = 40.0 + col2 * 222.0
		var ry: float = cy + row * 21.0
		_label(box, Vector2(cx, ry), Vector2(110, 20),
			str(elenco[i][0]), 12, DIM, HORIZONTAL_ALIGNMENT_LEFT)
		_label(box, Vector2(cx + 114, ry), Vector2(90, 20),
			str(elenco[i][1]), 12, CREAM, HORIZONTAL_ALIGNMENT_LEFT)

	_label(box, Vector2(0, cy + rows * 21.0 + 12.0), Vector2(W, 28),
		"Schiaccia nu tasto qualsiase pe' accummincià 'o turno", 17, GOLD,
		HORIZONTAL_ALIGNMENT_CENTER)


## Quanto scende ciascuna delle due colonne dei passi, misurato con la
## stessa formula che usa il disegno. Se le due divergono, il pannello si
## taglia il testo da solo.
func _altezze_colonne() -> Array:
	var meta: int = int(ceil(float(STEPS.size()) / 2.0))
	var y := [94.0, 94.0]
	for i in STEPS.size():
		var col: int = 0 if i < meta else 1
		y[col] += 23.0 + _text_height(str(STEPS[i][2])) + 8.0
	# Sotto ai passi ci vanno ancora i comandi, su quattro colonne, e la
	# riga "premi un tasto".
	var elenco: Array = _controlli_pad() if Pad.collegato() else CONTROLS
	var righe: float = ceil(float(elenco.size()) / 4.0)
	var extra: float = 18.0 + righe * 21.0 + 40.0
	return [y[0] + extra, y[1] + extra]


func _separator(parent: Control, y: float, width: float, alpha: float) -> void:
	var sep := ColorRect.new()
	sep.position = Vector2(60, y)
	sep.size = Vector2(width - 120.0, 2)
	sep.color = Color(0.4, 0.33, 0.22, alpha)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(sep)


func _text_height(text: String) -> float:
	return text.split("\n").size() * 18.0


func _panel(offset: Vector2, size: Vector2) -> Panel:
	var p := Panel.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.position = offset
	p.size = size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 12
	p.add_theme_stylebox_override("panel", style)
	_root.add_child(p)
	return p


func _label(parent: Control, pos: Vector2, size: Vector2, text: String,
		font_size: int, color: Color, align: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = size
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


## Il tastino scuro col nome del comando.
func _key_chip(parent: Control, pos: Vector2, text: String) -> void:
	var chip := Panel.new()
	chip.position = pos
	chip.size = Vector2(maxf(52.0, text.length() * 11.0 + 20.0), 24)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.18, 0.14)
	style.border_color = Color(0.55, 0.47, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	chip.add_theme_stylebox_override("panel", style)
	parent.add_child(chip)

	var l := Label.new()
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.text = text
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", GOLD)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(l)
