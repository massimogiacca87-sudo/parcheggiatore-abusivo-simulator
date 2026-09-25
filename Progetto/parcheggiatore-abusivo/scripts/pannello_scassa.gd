extends CanvasLayer
## PannelloScassa — 'o minigioco d''o scasso (0.57)
##
## Il capo: *«Si rubano le auto con un minigioco di tempismo e abilità che è
## più difficile in base all'auto da rubare»*.
##
## **'O cursore ca corre, e tu ca 'o firme.** Una barra, un cursore che va
## avanti e indietro, una finestra verde. Premi e il cursore si ferma: se sta
## dentro alla finestra lo spillo cade e passi al prossimo, se sta fuori è un
## errore. Tre-sei spille secondo la macchina, due errori e la serratura si
## blocca.
##
## È il minigioco più vecchio che esista e va bene così: si capisce senza
## spiegazioni, al primo colpo, che è l'unica cosa che conta per una cosa che
## fai mentre stai in mezzo alla strada con due carabinieri a settanta metri.
##
## **Chello ca 'o rende 'nu gioco e no 'nu dado**, che sono le tre aggiunte
## sopra la barra:
##
##   1. **'o centro d'oro** — dentro alla finestra verde ce n'è una più
##      stretta, dorata. Non serve a passare (passi uguale col verde): serve
##      a **pagare di più**. Chi tira al centro guadagna, chi tira al bordo
##      no, e tutti e due rubano la macchina. Una differenza di bravura che
##      non ti chiude la porta in faccia.
##   2. **'e spille rotte** — le tacche rosse. Se ci fermi sopra il furto
##      finisce lì, subito, senza appello. Da sole cambiano il gioco: con una
##      tacca rossa non puoi più "aspettare il giro comodo", perché il giro
##      comodo passa da lì.
##   3. **'o tiempo** — sei secondi per spillo, e la barra di sotto che
##      scende. Aspettare non è gratis.
##
## ---
##
## **'O munno nun se ferma.** Questa è la scelta che conta, e va contro a
## tutti gli altri pannelli del gioco: la bacheca, il lotto, la scopa, la
## casa — tutti fanno `get_tree().paused = true`, e va bene, perché stai
## seduto o stai leggendo un foglio.
##
## Qui no. Qui stai **piegato ncopp'a 'na machina ca nun è 'a toja, mmiezo
## â strada**. Se il mondo si fermasse, il vigile si fermerebbe con lui, e la
## tensione del furto — che è tutto quello che il furto ha — sarebbe finta.
## Quindi l'albero continua a girare, il vigile cammina davvero, e se ti
## arriva addosso mentre stai al terzo spillo hai perso davvero.
##
## Fermo resta **solo 'o player**, con `set_physics_process(false)`: lo stesso
## interruttore che usa `car_3d.arrubba()` quando sali al volante, e per la
## stessa ragione — uno che ha le mani dentro a una serratura non cammina, non
## tira pugni e non raccoglie niente.

const ORO := Color(0.96, 0.80, 0.34)
const CREMA := Color(0.93, 0.91, 0.87)
const SPENTO := Color(0.62, 0.60, 0.58)
const VERDE := Color(0.42, 0.86, 0.46)
const ROSSO := Color(0.92, 0.32, 0.26)

const LARGH: float = 640.0
const ALT_BARRA: float = 54.0

signal finito(vinto: bool, ori: int)

var _fondo: ColorRect
var _pannello: PanelContainer
var _titolo: Label
var _barra: Control
var _tempo_riga: ColorRect
var _sotto: Label
var _spille_riga: Label

## 'A serratura 'e sta vota (da `GameManager.scasso_pe`).
var _ric: Dictionary = {}
var _aperto: bool = false
var _finito: bool = false

## 0..1 ncopp'â barra.
var _cursore: float = 0.0
var _verso: float = 1.0
var _zona_da: float = 0.0
var _zona_a: float = 0.0
var _rotte: Array = []      # ognuna: {"da": float, "a": float}
var _spillo: int = 0
var _errori: int = 0
var _ori: int = 0
var _resta: float = 0.0
var _lampo: float = 0.0     # verde o rosso appena premuto
var _lampo_buono: bool = false
var _rng := RandomNumberGenerator.new()
## Da quanto 'nu vigile te sta guardanno mentre scasse.
const VISTO_MAX: float = 1.2
var _visto: float = 0.0

var _player: Node = null


func _ready() -> void:
	layer = 64
	# **`PROCESS_MODE_ALWAYS` serve pure ccà**, anche se non mettiamo in
	# pausa niente: se qualcun altro mette in pausa l'albero mentre stai
	# scassando (la pausa vera col tasto Esc, per dire), il cursore deve
	# fermarsi ma il pannello deve restare vivo per potersi chiudere.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_rng.randomize()
	_costruisci()


# ---------------------------------------------------------------------------
# Aprì e chiudere
# ---------------------------------------------------------------------------

func apri(tipo: String, nome_auto: String, player: Node) -> void:
	if _aperto:
		return
	_ric = GameManager.scasso_pe(tipo, _rng)
	_player = player
	_aperto = true
	_finito = false
	_spillo = 0
	_errori = 0
	_ori = 0
	_cursore = 0.0
	_verso = 1.0
	_lampo = 0.0
	_visto = 0.0
	visible = true
	# **'O munno cammina, 'o player no.**
	if _player != null and is_instance_valid(_player):
		_player.set_physics_process(false)
		if _player.has_method("azzera_moto"):
			_player.azzera_moto()
	GameManager.piglia_o_mouse(false)
	_titolo.text = "SCASSA — %s (%s)" % [nome_auto, str(_ric["nomme"])]
	_nova_spilla()
	SoundManager.play("pop", -14.0, 0.7)


func chiudi(vinto: bool) -> void:
	if not _aperto:
		return
	_aperto = false
	visible = false
	if _player != null and is_instance_valid(_player):
		# **Nun 'o risveglio si sta guidanno.** Se ha vinto, `arrubba()` lo
		# rimette a sedere e gli spegne di nuovo la fisica: riaccendergliela
		# qui in mezzo lo farebbe cadere dalla macchina per un fotogramma —
		# e in questo progetto un fotogramma di fisica sbagliata è un bug che
		# si vede (la 0.45, 'o player a bordo ca restava 'nderra).
		if not vinto:
			_player.set_physics_process(true)
			if _player.has_method("azzera_moto"):
				_player.azzera_moto()
	_player = null
	GameManager.piglia_o_mouse(true)
	finito.emit(vinto, _ori)


# ---------------------------------------------------------------------------
# 'O gioco
# ---------------------------------------------------------------------------

## Una spilla nuova: la finestra si sposta, le tacche rosse pure, e il
## cursore riparte da dove sta. Non da zero: ripartire sempre da sinistra
## renderebbe il tempismo una cosa da contare a memoria.
func _nova_spilla() -> void:
	var z: float = float(_ric["zona"])
	# **'A finestra nun tocca maje 'o bordo.** Se la zona buona finisse contro
	# il muro della barra, il cursore ci rimbalzerebbe dentro e restarci
	# sarebbe gratis: mezzo secondo fermo sul bordo e hai vinto.
	var margine: float = 0.06 + z * 0.5
	var centro: float = _rng.randf_range(margine, 1.0 - margine)
	_zona_da = centro - z * 0.5
	_zona_a = centro + z * 0.5

	_rotte.clear()
	var quante: int = int(_ric["rotte"])
	var giri: int = 0
	while _rotte.size() < quante and giri < 60:
		giri += 1
		var w: float = 0.055
		var c: float = _rng.randf_range(w, 1.0 - w)
		# Non sopra alla finestra buona (se no non si può vincere) e non
		# attaccata: serve un dito di spazio per infilarsi.
		if c > _zona_da - 0.07 and c < _zona_a + 0.07:
			continue
		var sovrapposta := false
		for r in _rotte:
			if absf(float(r["da"]) + w - c) < w * 2.6:
				sovrapposta = true
				break
		if sovrapposta:
			continue
		_rotte.append({"da": c - w, "a": c + w})

	_resta = float(_ric["secunne"])
	_aggiorna_scritte()


func _process(d: float) -> void:
	if not _aperto or _finito:
		return
	if _lampo > 0.0:
		_lampo = maxf(0.0, _lampo - d * 3.0)

	# **'O cursore se move cu 'o tiempo vero.** `_process` e non
	# `_physics_process`: il pannello deve girare anche se qualcuno ha messo
	# in pausa la fisica, e la barra è roba d'interfaccia.
	_cursore += _verso * float(_ric["vel"]) * d
	if _cursore >= 1.0:
		_cursore = 1.0
		_verso = -1.0
	elif _cursore <= 0.0:
		_cursore = 0.0
		_verso = 1.0

	_resta -= d
	if _resta <= 0.0:
		_sbagliato("Hê perzo 'o tiempo")
		return

	# **'O vigile te vede pure ccà**, ed è la ragione per cui il mondo non si
	# ferma. Ma **nun te piglia 'n tronco**: la prima fotografia di prova ha
	# beccato esattamente questo — il pannello si apriva e si richiudeva nel
	# fotogramma dopo, perché in piazza c'era un vigile e il controllo era
	# secco. Quello non è un rischio, è una porta che sbatte: non fai in
	# tempo a capire cos'è successo, e la lezione che impari è "il furto non
	# funziona", non "guardati intorno prima".
	#
	# Un secondo e due di sguardo, invece, è una cosa che si vede arrivare:
	# la riga sotto diventa rossa, e tu hai il tempo di mollare con Esc — che
	# non costa niente — invece di farti bloccare la serratura in mano.
	var v: Node = GameManager.nu_vigile_te_vede()
	if v == null:
		_visto = maxf(0.0, _visto - d * 1.6)
	else:
		_visto += d
		if _visto >= VISTO_MAX:
			_finito = true
			GameManager.scasso_fallito(1.4)
			if v.has_method("t_ha_visto"):
				v.t_ha_visto(1.0, "E CHE STAJE FACENNO LLOCO?!")
			GameManager.event_started.emit(
				"T'hanno visto cu 'e mmane dint'â serratura. Lassa sta'.")
			chiudi(false)
			return
	_avvisa_d_o_vigile(v != null)

	_barra.queue_redraw()
	_tempo_riga.size.x = LARGH * clampf(_resta / float(_ric["secunne"]),
		0.0, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if not _aperto or _finito:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_molla()
		return
	# Spazio, [E] o un click: tre modi di dire la stessa cosa, perché in
	# mezzo alla strada non si va a cercare il tasto giusto.
	var premuto: bool = event.is_action_pressed("jump") \
		or event.is_action_pressed("interact") \
		or event.is_action_pressed("ui_accept")
	if not premuto and event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		premuto = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	if not premuto:
		return
	get_viewport().set_input_as_handled()
	_firma()


## Hai premuto. Vediamo dove sta il cursore.
func _firma() -> void:
	for r in _rotte:
		if _cursore >= float(r["da"]) and _cursore <= float(r["a"]):
			_finito = true
			_lampo = 1.0
			_lampo_buono = false
			SoundManager.play("bump", -4.0, 0.7)
			GameManager.scasso_fallito(1.2)
			GameManager.event_started.emit(
				"Hê spezzato 'o ferro dint'â serratura. Chesta nun s'arape cchiù.")
			chiudi(false)
			return

	if _cursore < _zona_da or _cursore > _zona_a:
		_sbagliato("Fore")
		return

	# Preso. E se sta in mezzo al centro dorato, vale di più.
	var centro: float = (_zona_da + _zona_a) * 0.5
	var mezzo_oro: float = (_zona_a - _zona_da) * float(_ric["oro"]) * 0.5
	var oro: bool = absf(_cursore - centro) <= mezzo_oro
	if oro:
		_ori += 1
	_spillo += 1
	_lampo = 1.0
	_lampo_buono = true
	SoundManager.play("pop", -6.0, 1.45 if oro else 1.1)

	if _spillo >= int(_ric["spille"]):
		_finito = true
		GameManager.event_started.emit("Trasuta. Mo' è 'a toja — pe' mo'.")
		SoundManager.play("door", -6.0, 1.25)
		chiudi(true)
		return
	_nova_spilla()


func _sbagliato(pecche: String) -> void:
	_errori += 1
	_lampo = 1.0
	_lampo_buono = false
	SoundManager.play("fail", -12.0, 1.3)
	if _errori > int(_ric["errore_max"]):
		_finito = true
		GameManager.scasso_fallito(1.0)
		GameManager.event_started.emit(
			"%s. 'A serratura s'è bloccata e quaccheduno ha sentito." % pecche)
		chiudi(false)
		return
	_nova_spilla()


## Te ne vai senza rompere niente: l'auto resta aperta a un altro tentativo.
func _molla() -> void:
	_finito = true
	GameManager.event_started.emit("Hê lassato sta'. 'A machina nun sape niente.")
	chiudi(false)


# ---------------------------------------------------------------------------
# Chello ca se vede
# ---------------------------------------------------------------------------

func _costruisci() -> void:
	_fondo = ColorRect.new()
	# **Chiaro apposta.** Gli altri pannelli buttano il mondo a nero al
	# settanta per cento, perché quando leggi la bacheca il mondo non serve.
	# Qui serve: devi vedere se sta arrivando qualcuno mentre scassi, se no
	# la scelta di non mettere in pausa è una crudeltà e basta.
	_fondo.color = Color(0, 0, 0, 0.30)
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_fondo)

	_pannello = PanelContainer.new()
	_pannello.set_anchors_preset(Control.PRESET_CENTER)
	_pannello.custom_minimum_size = Vector2(LARGH + 44.0, 0)
	_pannello.position = Vector2(-(LARGH + 44.0) * 0.5, -140)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.07, 0.06, 0.08, 0.96)
	st.border_color = Color(0.58, 0.46, 0.26)
	st.set_border_width_all(2)
	st.set_corner_radius_all(6)
	_pannello.add_theme_stylebox_override("panel", st)
	add_child(_pannello)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 22)
	m.add_theme_constant_override("margin_right", 22)
	m.add_theme_constant_override("margin_top", 14)
	m.add_theme_constant_override("margin_bottom", 14)
	_pannello.add_child(m)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 9)
	m.add_child(col)

	_titolo = _scritta("SCASSA", 21, ORO)
	col.add_child(_titolo)

	_spille_riga = _scritta("", 15, CREMA)
	col.add_child(_spille_riga)

	_barra = Control.new()
	_barra.custom_minimum_size = Vector2(LARGH, ALT_BARRA)
	_barra.draw.connect(_disegna_barra)
	col.add_child(_barra)

	# 'O tiempo: 'na riga sola sotto â barra, ca se ne va.
	var culla := Control.new()
	culla.custom_minimum_size = Vector2(LARGH, 5)
	col.add_child(culla)
	_tempo_riga = ColorRect.new()
	_tempo_riga.color = ORO
	_tempo_riga.size = Vector2(LARGH, 5)
	culla.add_child(_tempo_riga)

	_sotto = _scritta(AJUTO, 13, SPENTO)
	col.add_child(_sotto)


const AJUTO := "[SPAZIO] o [E] o 'nu click pe' firmà 'o cursore   ·   [Esc] pe' lassà sta'"


## La riga di sotto cambia faccia quando un vigile ti sta guardando: è
## l'unico avviso che hai, e dev'essere impossibile non vederlo.
func _avvisa_d_o_vigile(guarda: bool) -> void:
	if not is_instance_valid(_sotto):
		return
	if not guarda and _visto <= 0.01:
		_sotto.text = AJUTO
		_sotto.add_theme_color_override("font_color", SPENTO)
		return
	_sotto.text = "'O VIGILE TE STA GUARDANNO — [Esc] mo', ca nun te costa niente"
	_sotto.add_theme_color_override("font_color",
		ROSSO.lerp(Color(1, 1, 1), 0.4 * (1.0 - _visto / VISTO_MAX)))


func _aggiorna_scritte() -> void:
	if not is_instance_valid(_spille_riga):
		return
	var punte: Array = []
	for i in range(int(_ric["spille"])):
		punte.append("●" if i < _spillo else "○")
	var err: String = ""
	if int(_ric["errore_max"]) > 0:
		var x: Array = []
		for i in range(int(_ric["errore_max"]) + 1):
			x.append("✕" if i < _errori else "·")
		err = "      sbaglie  %s" % " ".join(x)
	var oro_txt: String = ""
	if _ori > 0:
		oro_txt = "      'n chino ×%d" % _ori
	_spille_riga.text = "spille  %s%s%s" % [" ".join(punte), err, oro_txt]


func _disegna_barra() -> void:
	var w: float = LARGH
	var h: float = ALT_BARRA
	# 'O fondo.
	_barra.draw_rect(Rect2(0, 0, w, h), Color(0.14, 0.13, 0.15))
	_barra.draw_rect(Rect2(0, 0, w, h), Color(0.34, 0.31, 0.28), false, 2.0)

	# 'A zona bbona, e dint'a essa 'o centro d'oro.
	var zx: float = _zona_da * w
	var zw: float = (_zona_a - _zona_da) * w
	_barra.draw_rect(Rect2(zx, 2, zw, h - 4), Color(VERDE.r, VERDE.g, VERDE.b,
		0.30))
	_barra.draw_rect(Rect2(zx, 2, zw, h - 4), VERDE, false, 2.0)
	var co: float = (_zona_da + _zona_a) * 0.5 * w
	var ow: float = zw * float(_ric.get("oro", 0.3))
	_barra.draw_rect(Rect2(co - ow * 0.5, 2, ow, h - 4),
		Color(ORO.r, ORO.g, ORO.b, 0.55))

	# 'E spille rotte.
	for r in _rotte:
		var rx: float = float(r["da"]) * w
		var rw: float = (float(r["a"]) - float(r["da"])) * w
		_barra.draw_rect(Rect2(rx, 2, rw, h - 4),
			Color(ROSSO.r, ROSSO.g, ROSSO.b, 0.55))
		_barra.draw_line(Vector2(rx, 2), Vector2(rx + rw, h - 2), ROSSO, 2.0)
		_barra.draw_line(Vector2(rx + rw, 2), Vector2(rx, h - 2), ROSSO, 2.0)

	# 'O cursore.
	var cx: float = _cursore * w
	var c: Color = CREMA
	if _lampo > 0.0:
		c = (VERDE if _lampo_buono else ROSSO).lerp(CREMA, 1.0 - _lampo)
	_barra.draw_rect(Rect2(cx - 2.0, -4, 4.0, h + 8), c)


func _scritta(t: String, corpo: int, colore: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", corpo)
	l.add_theme_color_override("font_color", colore)
	return l
