extends CanvasLayer
## PannelloScopa — 'a partita vera
##
## La scopa si gioca a schermo intero, col mazzo napoletano ritagliato
## dall'atlante che c'era già. Le carte del vecchio (coperte) in alto, il
## tavolo in mezzo, la tua mano sotto.
##
## ## Chello ca s'è cagnato ê 0.50
##
## Il capo ha segnalato tre cose, e tutte e tre erano difetti veri.
##
## **1. Nun se ne asceva cchiù.** A fine partita il tabellone dei punti si
## scrive dentro a `_punti`, che è una `Label` **dentro alla stessa colonna**
## delle tre file di carte. Sette righe di conteggio sono duecento pixel in
## più: la colonna cresce, e siccome è centrata cresce **da tutte e due le
## parti** — il bottone "Vabbuo'", che sta in fondo, esce dal bordo basso
## dello schermo. Non è che non si vedeva: non c'era proprio più modo di
## cliccarlo. E l'unica altra via d'uscita, ESC, era disattivata dalla prima
## riga di `_unhandled_input`: `if not visible or _finita: return`. Cioè
## proprio quando serviva.
##
## Adesso: a partita finita **le file di carte si nascondono** (non servono
## più a niente) e resta il tabellone da solo, che ci sta comodo; ed ESC
## chiude sempre, in qualunque momento.
##
## **2. Nun se vedeva chello ca s'era pigliato.** Le carte sparivano dal
## tavolo e comparivano in un contatore. Adesso c'è la striscia dell'**ultima
## presa**: la carta calata, la freccia, le carte prese, e di chi sono. Entra
## con un'animazione corta — mezzo secondo — perché una presa che appare e
## basta non si legge, e una presa lenta annoia.
##
## **3. 'A presa se sceglie cliccanno.** Prima, quando una carta poteva
## prendere in più modi, comparivano dei **bottoni di testo** — "Sette +
## Quattro" — e dovevi leggere il nome delle carte per capire cosa stavi
## facendo, con le carte vere disegnate venti centimetri più su. Adesso si
## fa come sul tavolo vero: **clicchi la carta in mano, e le carte che puoi
## prendere si accendono di giallo. Clicchi quelle, e le pigli.**
##
## ## E po' ce sta Don Gennaro, ca **bara**
##
## L'ultimo del torneo si cambia una carta in mano quando gli conviene. Ma
## si vede: si tocca la coppola, tossisce, si sistema la manica. Se premi
## [F] mentre lo sta facendo, l'hai beccato: la carta te la dà, e la mano la
## perde lui. Se lo accusi a vuoto, sono cinque euro di figura.

const Carte := preload("res://scripts/carte.gd")
const Motore := preload("res://scripts/scopa_motore.gd")

const CARTA_W: float = 84.0
const CARTA_H: float = 136.0
const PAUSA_IA: float = 1.5
const FINESTRA_ACCUSA: float = 2.6

## Quanto dura l'animazione dell'ultima presa.
const PRESA_ANIM: float = 0.45

const GIALLO := Color(1.0, 0.84, 0.22)
const VERDE := Color(0.42, 0.94, 0.48)

signal chiusa(vinto: bool)

var sfidante: Dictionary = {}
var puntata: int = 0

var _m: ScopaMotore
var _fondo: ColorRect
var _colonna: VBoxContainer
var _riga_alto: HBoxContainer
var _riga_tavolo: HBoxContainer
var _riga_mano: HBoxContainer
var _sep_tavolo: Label
var _titolo: Label
var _stato: Label
var _bolla: Label
var _fine: VBoxContainer
var _punti: Label
var _ultima: HBoxContainer

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


func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	_costruisci()


func avvia(chi: Dictionary, quanto: int) -> void:
	sfidante = chi
	puntata = quanto
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
	_titolo.text = "%s, %d anne  —  se joca €%d" \
		% [str(chi.get("nome", "")), int(chi.get("eta", 70)), quanto]
	_dice(str(chi.get("dice", "")))
	_ridisegna()


# ---------------------------------------------------------------------------
# 'A faccia
# ---------------------------------------------------------------------------

func _costruisci() -> void:
	_fondo = ColorRect.new()
	_fondo.color = Color(0.06, 0.16, 0.10, 0.97)
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_fondo)

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 6)
	v.offset_left = 40
	v.offset_right = -40
	v.offset_top = 18
	v.offset_bottom = -18
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(v)
	_colonna = v

	_titolo = Label.new()
	_titolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titolo.add_theme_font_size_override("font_size", 24)
	v.add_child(_titolo)

	_bolla = Label.new()
	_bolla.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bolla.modulate = Color(1.0, 0.88, 0.60)
	_bolla.add_theme_font_size_override("font_size", 19)
	v.add_child(_bolla)

	# Le sue carte, coperte. Piccole: non c'è niente da guardare.
	_riga_alto = _riga(v, 5, 0.62)

	_sep_tavolo = Label.new()
	_sep_tavolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sep_tavolo.text = "─────────────  'O TAVULO  ─────────────"
	_sep_tavolo.modulate = Color(0.6, 0.8, 0.65)
	v.add_child(_sep_tavolo)
	_riga_tavolo = _riga(v, 7, 0.86)

	# 'A striscia 'e ll'ultima presa.
	_ultima = HBoxContainer.new()
	_ultima.alignment = BoxContainer.ALIGNMENT_CENTER
	_ultima.add_theme_constant_override("separation", 6)
	_ultima.custom_minimum_size = Vector2(0, CARTA_H * 0.50 + 8)
	v.add_child(_ultima)

	_stato = Label.new()
	_stato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stato.add_theme_font_size_override("font_size", 19)
	v.add_child(_stato)

	_riga_mano = _riga(v, 9, 1.0)

	_punti = Label.new()
	_punti.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_punti)

	_fine = VBoxContainer.new()
	_fine.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(_fine)


func _riga(sotto: Control, sep: int, scala: float) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", sep)
	h.custom_minimum_size = Vector2(0, CARTA_H * scala + 6)
	sotto.add_child(h)
	return h


## **'A cornice gialla.** Una carta "che si può prendere" deve dirlo da
## sola: niente scritte, niente legenda. Il bordo si disegna con uno
## `StyleBoxFlat` senza riempimento su un `Panel` più grande della carta,
## così la cornice sta **attorno** e non copre la figura.
func _cornice(colore: Color, spessore: int) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(colore.r, colore.g, colore.b, 0.16)
	sb.border_color = colore
	sb.set_border_width_all(spessore)
	sb.set_corner_radius_all(6)
	sb.set_expand_margin_all(float(spessore) + 2.0)
	p.add_theme_stylebox_override("panel", sb)
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _carta_nodo(indice: int, coperta: bool, scala: float = 1.0) -> Control:
	var t := TextureRect.new()
	t.custom_minimum_size = Vector2(CARTA_W * scala, CARTA_H * scala)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if coperta:
		t.texture = null
		var c := ColorRect.new()
		c.color = Carte.RETRO_TINTA
		c.set_anchors_preset(Control.PRESET_FULL_RECT)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.add_child(c)
	else:
		t.texture = Carte.texture(indice)
		if t.texture == null:
			var c2 := ColorRect.new()
			c2.color = Color(0.94, 0.92, 0.86)
			c2.set_anchors_preset(Control.PRESET_FULL_RECT)
			c2.mouse_filter = Control.MOUSE_FILTER_IGNORE
			t.add_child(c2)
			var l := Label.new()
			l.text = Motore.nome_carta(indice).replace(" ", "\n")
			l.set_anchors_preset(Control.PRESET_FULL_RECT)
			l.modulate = Color(0.1, 0.1, 0.1)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			t.add_child(l)
	return t


## Una carta cliccabile, con la sua eventuale cornice.
func _bottone_carta(indice: int, scala: float, colore: Color,
		premuto: Callable) -> Control:
	var b := Button.new()
	b.custom_minimum_size = Vector2(CARTA_W * scala, CARTA_H * scala)
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	var c := _carta_nodo(indice, false, scala)
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.add_child(c)
	if colore.a > 0.0:
		b.add_child(_cornice(colore, 4))
	if premuto.is_valid():
		b.pressed.connect(premuto)
	else:
		b.disabled = true
	return b


func _ridisegna() -> void:
	for r in [_riga_alto, _riga_tavolo, _riga_mano]:
		for c in r.get_children():
			c.queue_free()

	for _i in range(_m.mani[1].size()):
		_riga_alto.add_child(_carta_nodo(0, true, 0.62))

	# --- 'O tavulo: chi si può prendere si accende ---------------------
	var accendibili := _tavolo_accendibile()
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
		_riga_tavolo.add_child(_bottone_carta(carta, 0.86, colore, azione))

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
		_riga_mano.add_child(_bottone_carta(carta2, 1.0, col, az))

	var mio: int = _m.prese[0].size()
	var suo: int = _m.prese[1].size()
	_punti.text = "'E ccarte mie: %d (%d scope)   ·   'e ssoie: %d (%d scope)   ·   mazzo: %d" \
		% [mio, _m.scope[0], suo, _m.scope[1], _m.mazzo.size()]
	_aggiorna_stato()


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
		return
	if _carta_scelta < 0:
		_stato.text = "Tocca a te. Clicca 'na carta d''a mano."
		return
	if _opzioni.is_empty():
		_stato.text = ""
		return
	var quante: int = _tavolo_accendibile().size()
	if _presi.is_empty():
		_stato.text = "Cu 'o %s: clicca 'e ccarte gialle ca vuo' piglià  ·  [clic 'a carta toia] pe' cagnà idea" \
			% Motore.nome_carta(_carta_scelta)
	else:
		_stato.text = "Ne manca ancora %d  ·  [clic 'a carta verde] pe' lassarla" \
			% maxi(1, quante)


func _dice(t: String) -> void:
	_bolla.text = "« %s »" % t


## Accende o spegne tutta la roba del gioco. A partita finita si spegne: le
## carte non servono più e il tabellone dei punti ci sta comodo.
func _mostra_gioco(si: bool) -> void:
	for n in [_riga_alto, _sep_tavolo, _riga_tavolo, _ultima, _stato,
			_riga_mano, _punti]:
		if n != null:
			(n as CanvasItem).visible = si


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
		# Niente da prendere: la carta si cala e basta. Non c'è nessuna
		# scelta da fare, e chiedere un secondo clic per niente sarebbe
		# solo un clic in più.
		_scorda_scelta()
		_gioca_io(carta, [])
		return
	_carta_scelta = carta
	_opzioni = opz
	_presi = []
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

	# Restano valide solo le prese che contengono tutto quello che hai già
	# cliccato.
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
		# Non può succedere (si accendono solo le carte compatibili), ma se
		# succedesse si ricomincia invece di restare bloccati.
		_presi = []
		_ridisegna()
		return
	# Combacia esattamente con una presa valida? Allora si gioca.
	for o in buone:
		if (o as Array).size() == _presi.size():
			var presa: Array = _presi.duplicate()
			var c0: int = _carta_scelta
			_scorda_scelta()
			_gioca_io(c0, presa)
			return
	_ridisegna()


func _gioca_io(carta: int, presa: Array) -> void:
	var e: Dictionary = _m.gioca(0, carta, presa)
	_dopo_mossa(e)


func _dopo_mossa(e: Dictionary) -> void:
	if e.is_empty():
		return
	if not e["presa"].is_empty():
		SoundManager.play("pop", -6.0)
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
##
## Le carte sparivano dal tavolo e ricomparivano come un numero in fondo
## allo schermo. Chi gioca non riesce a tenere il conto di cosa è successo —
## soprattutto contro un avversario che muove da solo dopo un secondo e
## mezzo. Qui si vede: la carta calata, la freccia, quello che ha preso.
##
## L'animazione dura mezzo secondo. Serve a far capire che la striscia è
## **cambiata**: senza, una presa uguale alla precedente sembra la stessa.
func _mostra_presa(e: Dictionary) -> void:
	_svuota(_ultima)
	var chi := int(e.get("chi", 0))
	var presa: Array = e.get("presa", [])
	var calata := int(e.get("carta", -1))
	if calata < 0:
		return

	var eti := Label.new()
	eti.text = ("TU:  " if chi == 0 else "ISSO:  ")
	eti.modulate = Color(0.72, 0.86, 0.74) if chi == 0 \
		else Color(0.92, 0.78, 0.62)
	eti.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ultima.add_child(eti)
	_ultima.add_child(_carta_nodo(calata, false, 0.50))

	if presa.is_empty():
		var giu := Label.new()
		giu.text = "  ▾ l'ha lassata 'nterra"
		giu.modulate = Color(0.66, 0.72, 0.68)
		giu.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_ultima.add_child(giu)
	else:
		var fre := Label.new()
		fre.text = "  ▸  "
		fre.modulate = Color(1.0, 0.86, 0.35)
		fre.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_ultima.add_child(fre)
		for c in presa:
			_ultima.add_child(_carta_nodo(int(c), false, 0.50))
	if e.get("scopa", false):
		var sc := Label.new()
		sc.text = "  SCOPA!"
		sc.modulate = GIALLO
		sc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_ultima.add_child(sc)

	# L'animazione: la striscia entra da sotto e schiarisce.
	_ultima.modulate = Color(1, 1, 1, 0.0)
	_ultima.position.y = 14.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_ultima, "modulate:a", 1.0, PRESA_ANIM)
	tw.tween_property(_ultima, "position:y", 0.0, PRESA_ANIM) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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
	# Cerca nel mazzo una carta che gli farebbe fare presa adesso.
	var buona := -1
	for c in _m.mazzo:
		if not Motore.prese_possibili(c, _m.tavolo).is_empty():
			buona = c
			if c == Motore.SETTEBELLO:
				break
	if buona < 0:
		return
	# Scambio: la peggiore della mano torna nel mazzo.
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
	SoundManager.play("tosse", -8.0)


func _accusa() -> void:
	if _finita:
		return
	if _bara_ora:
		_bara_ora = false
		# La carta pescata gliela togli e te la pigli tu.
		if _m.mani[1].has(_bara_carta):
			_m.mani[1].erase(_bara_carta)
			_m.prese[0].append(_bara_carta)
		_dice("…E vabbuo'. Sî sveglio. Pigliatella.")
		SoundManager.play("vinto", -5.0)
		_ridisegna()
		return
	_accuse_sbagliate += 1
	_dice("E che vaje dicenno? Joca, va'.")
	SoundManager.play("perso", -10.0)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		# **ESC chiude sempe.**
		#
		# Prima la prima riga era `if not visible or _finita: return`, cioè
		# ESC smetteva di funzionare **esattamente a partita finita** — che
		# è il momento in cui uno lo preme. A partita finita chiude e basta
		# (i conti sono già fatti); a partita in corso è una fuga, e la
		# puntata resta sul tavolo.
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
	var righe: Array = []
	for v in p["voci"]:
		var chi := int(v.get("chi", -1))
		var segno := "  "
		if chi == 0:
			segno = "→ "
		elif chi == 1:
			segno = " ←"
		righe.append("%s%-11s %3d — %-3d" % [segno, str(v["nome"]),
			int(v["a"]), int(v["b"])])
	var vinto: bool = _vinto_ora()

	# **'E ccarte se ne vanno.** È questo che libera lo spazio: con le tre
	# file accese, il tabellone spingeva il bottone fuori dallo schermo.
	_mostra_gioco(false)
	_svuota(_fine)

	var tab := Label.new()
	tab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tab.add_theme_font_size_override("font_size", 20)
	tab.text = "\n".join(righe) + "\n\nPUNTE:  tu %d  —  isso %d" \
		% [_mio_punti, _suo_punti]
	_fine.add_child(tab)

	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 30)
	if vinto:
		l.text = "HÊ VINTO. €%d" % (puntata * 2)
		l.modulate = Color(0.6, 1.0, 0.6)
		_dice(str(sfidante.get("vinto", "Bravo.")))
		SoundManager.play("vinto", -3.0)
	elif _patta_ora():
		l.text = "PATTA. 'A puntata torna."
		l.modulate = Color(1.0, 0.95, 0.6)
		_dice("Patta. Nun ha vinciuto nisciuno.")
	else:
		l.text = "HÊ PERZO €%d" % puntata
		l.modulate = Color(1.0, 0.55, 0.5)
		_dice("Te ll'avevo ditto. Turnate quanno hê 'mparato.")
		SoundManager.play("perso", -8.0)
	_fine.add_child(l)

	if _accuse_sbagliate > 0:
		var l2 := Label.new()
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l2.text = "%d accuse a vacante: −€%d 'e figura." \
			% [_accuse_sbagliate, _accuse_sbagliate * 5]
		l2.modulate = Color(1.0, 0.75, 0.6)
		_fine.add_child(l2)

	# Il bottone dentro a una riga centrata: da solo dentro alla colonna,
	# un `Button` si stira da un bordo all'altro dello schermo.
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


func _esci(vinto: bool, scappato: bool = false, patta: bool = false) -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
	GameManager.piglia_o_mouse(true)
	_svuota(_fine)
	_svuota(_ultima)
	_scorda_scelta()
	if _accuse_sbagliate > 0:
		GameManager.money = maxi(0, GameManager.money - _accuse_sbagliate * 5)
		GameManager.money_changed.emit(GameManager.money)
		_accuse_sbagliate = 0
	if patta:
		GameManager.add_money(puntata)   # la puntata torna
	elif scappato:
		GameManager.gioco_azzardo(-puntata)
		GameManager.event_started.emit("Sî scappato 'a tavola. 'A puntata resta 'a isso.")
	else:
		GameManager.scopa_esito(str(sfidante.get("id", "")), vinto, puntata)
	_finita = true
	chiusa.emit(vinto)


func _svuota(c: Control) -> void:
	if c == null:
		return
	for x in c.get_children():
		c.remove_child(x)
		x.queue_free()
