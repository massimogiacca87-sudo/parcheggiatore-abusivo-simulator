extends CanvasLayer
## PannelloPartite — 'o tabellone d''a sala scommesse
##
## **'A schermata è chella d''o screenshot d''o capo**, e ricopiarla non è
## nostalgia: è che quella disposizione funziona. In alto le due squadre
## col punteggio in due caselle, una chiara e una rossa, così il risultato
## si legge da tre metri. Sotto, una **fascia sola** con la cronaca — una
## riga per volta, grossa — perché in dieci secondi non si legge una lista,
## si legge una frase. Poi la barra del possesso, e in fondo l'arbitro, il
## tempo e il nome del campo.
##
## Le linguette in alto e in basso ci sono e non si toccano: fanno parte
## del ricordo di quello schermo, e un tabellone senza linguette non
## sembra un tabellone. Quella accesa è sempre *'A PARTITA*.
##
## **Novanta minute 'n nove secunne.** Il cronometro sale da 0 a 90 in
## `DURATA` secondi; quando passa sopra il minuto di un fatto, la fascia
## cambia riga e (se è un gol) il punteggio scatta. La partita non è
## "calcolata alla fine e mostrata": è **già decisa in partenza** — il
## motore la risolve tutta prima che parta il cronometro — e questo è
## voluto, perché la scommessa dev'essere chiusa prima del fischio
## d'inizio e nessuna animazione può cambiarla.

const Partita := preload("res://scripts/partita_virtuale.gd")

const LARGH: float = 900.0
const ALT: float = 470.0
## Quanto dura la partita a schermo, in secondi.
const DURATA: float = 9.0
## Quanto resta ferma la fascia su una riga di cronaca, al minimo.
const FASCIA_MIN: float = 0.9

const BLU := Color(0.13, 0.13, 0.42)
const BLU_CHIARO := Color(0.24, 0.24, 0.58)
const ROSSO := Color(0.72, 0.10, 0.10)
const CREMA := Color(0.96, 0.95, 0.92)
const ORO := Color(0.98, 0.82, 0.22)
const VERDE := Color(0.30, 0.52, 0.28)
const SPENTO := Color(0.70, 0.70, 0.78)

enum Fase { SCHEDINA, PARTITA, FINE }

var _fondo: ColorRect
var _corpo: Panel
var _nome_casa: Label
var _nome_fore: Label
var _gol_casa: Label
var _gol_fore: Label
var _tempo_lab: Label
var _data_lab: Label
var _torneo_lab: Label
var _fascia: Panel
var _fascia_lab: Label
var _poss_cornice: ColorRect
var _poss_casa: ColorRect
var _poss_fore: ColorRect
var _poss_lab_c: Label
var _poss_lab_f: Label
var _arbitro_lab: Label
var _tiempo_lab: Label
var _campo_lab: Label
var _lista: VBoxContainer
var _azioni: HBoxContainer
var _avviso: Label

var _fase: int = Fase.SCHEDINA
var _cartellone: Array = []
var _scelta: int = -1
var _segno: String = ""
var _puntata: int = 2
var _partita: Dictionary = {}
var _t: float = 0.0
var _prossimo: int = 0
var _fascia_t: float = 0.0
var _aperto: bool = false
var _rng := RandomNumberGenerator.new()

## Quanto si può puntare a colpo. Cinque tagli, come i bottoni della sala.
##
## **'O taglio cchiù piccolo è dduje euro, e ce sta 'nu motivo.** La
## vincita si tronca all'euro (`floori`), perché il gioco non ha centesimi:
## un euro giocato su una quota 1,57 pagherebbe 1,57 → **1**, cioè uno
## vince e non prende niente. A due euro il minimo diventa 3, e la cosa
## sta in piedi.
##
## Il troncamento è anche il motivo per cui **puntare poco conviene meno**:
## a 25 euro la quota 1,57 rende 1,56 vere, a 2 euro rende 1,50. È una
## sgarberia del banco, ed è la stessa che fanno le sale vere.
const TAGLI := [2, 5, 10, 25, 50]


func _ready() -> void:
	layer = 63
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_rng.randomize()
	_costruisci()


func apri() -> void:
	_aperto = true
	visible = true
	_fase = Fase.SCHEDINA
	_scelta = -1
	_segno = ""
	_cartellone = Partita.cartellone(_rng, 3)
	get_tree().paused = true
	GameManager.piglia_o_mouse(false)
	_disegna()


func chiudi() -> void:
	if not _aperto:
		return
	_aperto = false
	visible = false
	set_process(false)
	get_tree().paused = false
	GameManager.piglia_o_mouse(true)


func _unhandled_input(event: InputEvent) -> void:
	if not _aperto:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		# A partita in corso l'Esc non chiude: la scommessa è già pagata e
		# sparire a metà partita lascerebbe i soldi in mezzo al guado.
		if _fase == Fase.PARTITA:
			return
		chiudi()


# ---------------------------------------------------------------------------
# 'A costruzione: 'o tabellone se fa 'na vota sola
# ---------------------------------------------------------------------------

func _costruisci() -> void:
	_fondo = ColorRect.new()
	_fondo.color = Color(0, 0, 0, 0.74)
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_fondo)

	_corpo = Panel.new()
	_corpo.set_anchors_preset(Control.PRESET_CENTER)
	_corpo.position = Vector2(-LARGH * 0.5, -ALT * 0.5)
	_corpo.size = Vector2(LARGH, ALT)
	var st := StyleBoxFlat.new()
	st.bg_color = BLU
	st.border_color = BLU_CHIARO
	st.set_border_width_all(2)
	_corpo.add_theme_stylebox_override("panel", st)
	add_child(_corpo)

	# --- 'A capa: 'e ddoje squadre e 'o punteggio -----------------------
	_nome_casa = _fascetta(Vector2(14, 12), Vector2(330, 40), CREMA,
		Color(0.10, 0.10, 0.12), 24, HORIZONTAL_ALIGNMENT_LEFT)
	_gol_casa = _fascetta(Vector2(348, 12), Vector2(52, 40),
		Color(0.86, 0.86, 0.88), Color(0.10, 0.10, 0.12), 24)
	_nome_fore = _fascetta(Vector2(414, 12), Vector2(330, 40), ROSSO, CREMA,
		24, HORIZONTAL_ALIGNMENT_LEFT)
	_gol_fore = _fascetta(Vector2(748, 12), Vector2(52, 40),
		Color(0.86, 0.86, 0.88), Color(0.10, 0.10, 0.12), 24)

	# --- 'E linguette ----------------------------------------------------
	var voci := ["'A PARTITA", "'E NUMMERE", "'O CAMPO", "'O RESOCONTO"]
	for i in range(voci.size()):
		_linguetta(voci[i], Vector2(14 + i * 218, 62), Vector2(212, 26), i == 0)

	_tempo_lab = _scritta("PRIMMO TIEMPO", Vector2(0, 96), Vector2(LARGH, 22),
		18, ORO)
	_data_lab = _scritta("", Vector2(20, 122), Vector2(400, 18), 12,
		Color(0.55, 0.90, 0.92), HORIZONTAL_ALIGNMENT_LEFT)
	_torneo_lab = _scritta("CAMPIONATO D''E RRIONE", Vector2(LARGH - 420, 122),
		Vector2(400, 18), 12, Color(0.55, 0.90, 0.92),
		HORIZONTAL_ALIGNMENT_RIGHT)

	# --- 'O campo verde: 'o fondo d''a fascia ---------------------------
	var prato := ColorRect.new()
	prato.position = Vector2(14, 146)
	prato.size = Vector2(LARGH - 28, 208)
	prato.color = VERDE.darkened(0.25)
	_corpo.add_child(prato)
	# Le righe del campo, appena accennate: due strisce più chiare.
	for i in range(6):
		var r := ColorRect.new()
		r.position = Vector2(14, 146 + i * 36)
		r.size = Vector2(LARGH - 28, 18)
		r.color = VERDE.lightened(0.06)
		r.modulate.a = 0.5
		_corpo.add_child(r)

	# --- 'A fascia rossa d''a cronaca -----------------------------------
	_fascia = Panel.new()
	_fascia.position = Vector2(70, 196)
	_fascia.size = Vector2(LARGH - 140, 64)
	var sf := StyleBoxFlat.new()
	sf.bg_color = ROSSO
	_fascia.add_theme_stylebox_override("panel", sf)
	_corpo.add_child(_fascia)

	_fascia_lab = Label.new()
	_fascia_lab.position = Vector2(12, 6)
	_fascia_lab.size = Vector2(LARGH - 164, 52)
	_fascia_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fascia_lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_fascia_lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fascia_lab.add_theme_font_size_override("font_size", 21)
	_fascia_lab.add_theme_color_override("font_color", ORO)
	_fascia.add_child(_fascia_lab)

	# --- 'A schedina: 'a lista d''e partite, primma ca se joca ----------
	_lista = VBoxContainer.new()
	_lista.position = Vector2(34, 156)
	_lista.size = Vector2(LARGH - 68, 190)
	_lista.add_theme_constant_override("separation", 5)
	_corpo.add_child(_lista)

	# --- 'O possesso -----------------------------------------------------
	_poss_cornice = ColorRect.new()
	var cornice := _poss_cornice
	cornice.position = Vector2(150, 300)
	cornice.size = Vector2(LARGH - 300, 22)
	cornice.color = Color(0.06, 0.06, 0.10)
	_corpo.add_child(cornice)
	_poss_casa = ColorRect.new()
	_poss_casa.position = Vector2(152, 302)
	_poss_casa.size = Vector2((LARGH - 304) * 0.5, 18)
	_poss_casa.color = Color(0.90, 0.90, 0.92)
	_corpo.add_child(_poss_casa)
	_poss_fore = ColorRect.new()
	_poss_fore.position = Vector2(152 + (LARGH - 304) * 0.5, 302)
	_poss_fore.size = Vector2((LARGH - 304) * 0.5, 18)
	_poss_fore.color = ROSSO
	_corpo.add_child(_poss_fore)
	_poss_lab_c = _scritta("", Vector2(160, 302), Vector2(120, 18), 12,
		Color(0.10, 0.10, 0.12), HORIZONTAL_ALIGNMENT_LEFT)
	_poss_lab_f = _scritta("", Vector2(LARGH - 280, 302), Vector2(120, 18), 12,
		CREMA, HORIZONTAL_ALIGNMENT_RIGHT)

	_arbitro_lab = _scritta("", Vector2(20, 332), Vector2(430, 18), 12, ORO,
		HORIZONTAL_ALIGNMENT_LEFT)
	_tiempo_lab = _scritta("", Vector2(LARGH - 450, 332), Vector2(430, 18), 12,
		ORO, HORIZONTAL_ALIGNMENT_RIGHT)

	# --- 'E linguette 'e sotto ------------------------------------------
	var sotto := ["'E QUOTE", "'E GIUCATURE", "LL'ATE PARTITE", "'A CLASSIFICA",
		"'O BANCO"]
	for i in range(sotto.size()):
		_linguetta(sotto[i], Vector2(14 + i * 175, 362), Vector2(169, 24), false)

	_campo_lab = _scritta("", Vector2(0, 392), Vector2(LARGH, 22), 15,
		Color(0.80, 0.80, 0.86))

	_avviso = _scritta("", Vector2(0, 414), Vector2(LARGH, 20), 13, CREMA)

	_azioni = HBoxContainer.new()
	_azioni.position = Vector2(20, 434)
	_azioni.size = Vector2(LARGH - 40, 30)
	_azioni.alignment = BoxContainer.ALIGNMENT_CENTER
	_azioni.add_theme_constant_override("separation", 8)
	_corpo.add_child(_azioni)


# ---------------------------------------------------------------------------
# 'E ddoje facce: 'a schedina e 'a partita
# ---------------------------------------------------------------------------

func _disegna() -> void:
	var giocando: bool = _fase != Fase.SCHEDINA
	_lista.visible = not giocando
	_fascia.visible = giocando
	_poss_cornice.visible = giocando
	_poss_casa.visible = giocando
	_poss_fore.visible = giocando
	# Le due caselle del punteggio: sulla schedina non c'e' niente da
	# segnare, e due rettangoli grigi vuoti accanto ai nomi sembrano un
	# pezzo di interfaccia che non ha caricato.
	_gol_casa.get_parent().visible = giocando
	_gol_fore.get_parent().visible = giocando
	_poss_lab_c.visible = giocando
	_poss_lab_f.visible = giocando
	_arbitro_lab.visible = giocando
	_tiempo_lab.visible = giocando

	if giocando:
		_disegna_partita()
	else:
		_disegna_schedina()


func _disegna_schedina() -> void:
	_nome_casa.text = "  SALA SCUMMESSE"
	_nome_fore.text = "  TIENE €%d" % GameManager.money
	_gol_casa.text = ""
	_gol_fore.text = ""
	_tempo_lab.text = "'E PARTITE 'E MO'"
	_data_lab.text = "juorno %d  ·  %s" % [GameManager.giornata,
		GameManager.orologio()]
	_campo_lab.text = "Se gioca 'n nove secunne. 'A scummessa se chiude primma d''o fischio."

	for c in _lista.get_children():
		_lista.remove_child(c)
		c.queue_free()

	for i in range(_cartellone.size()):
		var p: Dictionary = _cartellone[i]
		var riga := HBoxContainer.new()
		riga.add_theme_constant_override("separation", 6)
		_lista.add_child(riga)

		var nomi := Label.new()
		nomi.text = "%s  –  %s" % [str(p["casa"]["nome"]), str(p["fore"]["nome"])]
		nomi.custom_minimum_size = Vector2(360, 30)
		nomi.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nomi.add_theme_font_size_override("font_size", 15)
		nomi.add_theme_color_override("font_color", CREMA)
		riga.add_child(nomi)

		var segni := ["1", "X", "2"]
		for k in range(3):
			var b := Button.new()
			b.text = "%s  %.2f" % [segni[k], float(p["quote"][k])]
			b.custom_minimum_size = Vector2(118, 30)
			b.add_theme_font_size_override("font_size", 14)
			var ii: int = i
			var ss: String = segni[k]
			b.pressed.connect(func(): _scegli(ii, ss))
			if _scelta == i and _segno == segni[k]:
				b.add_theme_color_override("font_color", Color(0.12, 0.10, 0.03))
				var stb := StyleBoxFlat.new()
				stb.bg_color = ORO
				stb.set_corner_radius_all(3)
				b.add_theme_stylebox_override("normal", stb)
				b.add_theme_stylebox_override("hover", stb)
			riga.add_child(b)

	_rifa_azioni()
	if _scelta < 0:
		_avviso.text = "Sciglie 'na partita e 'nu segno: 1 = vence 'a casa, X = pareggio, 2 = vence 'o fore."
		_avviso.add_theme_color_override("font_color", SPENTO)
	else:
		var p: Dictionary = _cartellone[_scelta]
		var q: float = float(p["quote"][["1", "X", "2"].find(_segno)])
		_avviso.text = "%s – %s   ·   segno %s a %.2f   ·   €%d ne fanno €%d" % [
			str(p["casa"]["nome"]), str(p["fore"]["nome"]), _segno, q,
			_puntata, int(floor(float(_puntata) * q))]
		_avviso.add_theme_color_override("font_color", ORO)


func _rifa_azioni() -> void:
	for c in _azioni.get_children():
		_azioni.remove_child(c)
		c.queue_free()

	if _fase == Fase.PARTITA:
		return

	if _fase == Fase.SCHEDINA:
		var lab := Label.new()
		lab.text = "puntata:"
		lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lab.add_theme_font_size_override("font_size", 13)
		lab.add_theme_color_override("font_color", SPENTO)
		_azioni.add_child(lab)
		for q in TAGLI:
			var b := Button.new()
			b.text = "€%d" % q
			b.custom_minimum_size = Vector2(54, 28)
			var v: int = q
			b.pressed.connect(func():
				_puntata = v
				_disegna())
			if _puntata == q:
				var stb := StyleBoxFlat.new()
				stb.bg_color = ORO
				stb.set_corner_radius_all(3)
				b.add_theme_stylebox_override("normal", stb)
				b.add_theme_color_override("font_color", Color(0.12, 0.10, 0.03))
			_azioni.add_child(b)

		var gioca := Button.new()
		gioca.text = "SCOMMETTO E VEDIMMO"
		gioca.custom_minimum_size = Vector2(220, 28)
		gioca.disabled = _scelta < 0 or GameManager.money < _puntata
		gioca.pressed.connect(_via)
		_azioni.add_child(gioca)
	else:
		var ancora := Button.new()
		ancora.text = "N'ATA VOTA"
		ancora.custom_minimum_size = Vector2(180, 28)
		ancora.pressed.connect(func():
			_fase = Fase.SCHEDINA
			_scelta = -1
			_segno = ""
			_cartellone = Partita.cartellone(_rng, 3)
			_disegna())
		_azioni.add_child(ancora)

	var esci := Button.new()
	esci.text = "Vabbuo' [Esc]"
	esci.custom_minimum_size = Vector2(150, 28)
	esci.pressed.connect(chiudi)
	_azioni.add_child(esci)


func _scegli(i: int, segno: String) -> void:
	_scelta = i
	_segno = segno
	SoundManager.play("pop", -12.0, 1.2)
	_disegna()


# ---------------------------------------------------------------------------
# 'A partita
# ---------------------------------------------------------------------------

func _via() -> void:
	if _scelta < 0 or _scelta >= _cartellone.size():
		return
	if not GameManager.paga(_puntata):
		SoundManager.play("fail", -8.0, 0.9)
		return
	GameManager.gioco_azzardo(-_puntata)
	var c: Dictionary = _cartellone[_scelta]
	_partita = Partita.gioca(c["casa"], c["fore"], _rng)
	_partita["quota"] = float(c["quote"][["1", "X", "2"].find(_segno)])
	_partita["segno"] = _segno
	_partita["puntata"] = _puntata
	_fase = Fase.PARTITA
	_t = 0.0
	_prossimo = 0
	_fascia_t = 0.0
	_fascia_lab.text = "SE COMMENCIA. FISCHIO 'E LL'ARBITRO."
	SoundManager.play("fischio_vigile", -12.0, 1.25)
	set_process(true)
	_disegna()


func _disegna_partita() -> void:
	var casa: String = str(_partita["casa"]["nome"])
	var fore: String = str(_partita["fore"]["nome"])
	_nome_casa.text = "  " + casa
	_nome_fore.text = "  " + fore
	_data_lab.text = "juorno %d  ·  %s" % [GameManager.giornata,
		GameManager.orologio()]
	_arbitro_lab.text = "ARBITRO — %s" % str(_partita["arbitro"])
	_tiempo_lab.text = "TIEMPO — %s" % str(_partita["tiempo"])
	_campo_lab.text = str(_partita["campo"]).to_upper()
	var poss: int = int(_partita["possesso"])
	var largo: float = LARGH - 304.0
	_poss_casa.size.x = largo * float(poss) / 100.0
	_poss_fore.position.x = 152.0 + _poss_casa.size.x
	_poss_fore.size.x = largo - _poss_casa.size.x
	_poss_lab_c.text = "%d%%" % poss
	_poss_lab_f.text = "%d%%" % (100 - poss)
	_rifa_azioni()


func _process(delta: float) -> void:
	if _fase != Fase.PARTITA:
		return
	_t += delta
	var minuto: int = mini(Partita.MINUTI,
		int(round(_t / DURATA * float(Partita.MINUTI))))
	_tempo_lab.text = ("PRIMMO TIEMPO" if minuto < 45 else "SECONDO TIEMPO") \
		+ "   ·   %d'" % minuto

	_fascia_t = maxf(0.0, _fascia_t - delta)
	var fatti: Array = _partita["fatti"]
	while _prossimo < fatti.size() and int(fatti[_prossimo]["min"]) <= minuto:
		var f: Dictionary = fatti[_prossimo]
		_prossimo += 1
		_fascia_lab.text = "%d'   %s" % [int(f["min"]), str(f["testo"])]
		_fascia_t = FASCIA_MIN
		_gol_casa.text = str(int(f["casa"]))
		_gol_fore.text = str(int(f["fore"]))
		match str(f["che"]):
			"gol", "rigore":
				SoundManager.play("urlo", -6.0, randf_range(0.95, 1.08))
				GameManager.screen_shake.emit(0.35)
			"rosso":
				SoundManager.play("fischio_vigile", -10.0, 0.8)
			_:
				SoundManager.play("pop", -16.0, 1.1)
		break   # un fatto per fotogramma: se no due gol nello stesso
				# istante si mangiano a vicenda e se ne legge uno solo

	_gol_casa.text = str(_gol_visti(0))
	_gol_fore.text = str(_gol_visti(1))

	if _fascia_t <= 0.0 and _prossimo >= fatti.size() and minuto >= Partita.MINUTI:
		_fine()


## Quanti gol sono già stati mostrati: si contano i fatti già passati,
## così il tabellone non può mai dire più di quello che si è visto.
func _gol_visti(chi: int) -> int:
	var n: int = 0
	var fatti: Array = _partita["fatti"]
	for i in range(mini(_prossimo, fatti.size())):
		var f: Dictionary = fatti[i]
		if int(f["chi"]) == chi and (str(f["che"]) == "gol"
				or str(f["che"]) == "rigore"):
			n += 1
	return n


func _fine() -> void:
	_fase = Fase.FINE
	set_process(false)
	var gc: int = int(_partita["gol_casa"])
	var gf: int = int(_partita["gol_fore"])
	_gol_casa.text = str(gc)
	_gol_fore.text = str(gf)
	_tempo_lab.text = "FERNUTA   ·   90'"
	var vinto: bool = str(_partita["esito"]) == str(_partita["segno"])
	var presi: int = 0
	if vinto:
		presi = int(floor(float(_partita["puntata"]) * float(_partita["quota"])))
		GameManager.add_money(presi)
		GameManager.gioco_azzardo(presi)
		_fascia_lab.text = "HÊ 'NDUVINATO! %d–%d, segno %s: pigli €%d" % [
			gc, gf, str(_partita["segno"]), presi]
		SoundManager.play("soldi", -2.0, 1.05)
	else:
		_fascia_lab.text = "%d–%d. 'O segno era %s, tu avive ditto %s." % [
			gc, gf, str(_partita["esito"]), str(_partita["segno"])]
		SoundManager.play("fail", -6.0, 0.85)
	_avviso.text = "'O banco se piglia ll'otto pe' ciento 'e tutto chello ca passa 'a ccà."
	_avviso.add_theme_color_override("font_color", SPENTO)
	_rifa_azioni()


# ---------------------------------------------------------------------------
# Aiutine
# ---------------------------------------------------------------------------

func _fascetta(pos: Vector2, dim: Vector2, sfondo: Color, testo: Color,
		corpo: int, allinea: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var p := Panel.new()
	p.position = pos
	p.size = dim
	var st := StyleBoxFlat.new()
	st.bg_color = sfondo
	p.add_theme_stylebox_override("panel", st)
	_corpo.add_child(p)
	var l := Label.new()
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = allinea
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", corpo)
	l.add_theme_color_override("font_color", testo)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	return l


func _linguetta(testo: String, pos: Vector2, dim: Vector2, accesa: bool) -> void:
	var p := Panel.new()
	p.position = pos
	p.size = dim
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.42, 0.36, 0.14) if accesa else BLU_CHIARO
	st.border_color = ORO if accesa else BLU_CHIARO.lightened(0.12)
	st.set_border_width_all(1)
	p.add_theme_stylebox_override("panel", st)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_corpo.add_child(p)
	var l := Label.new()
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.text = testo
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", ORO if accesa else CREMA)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)


func _scritta(testo: String, pos: Vector2, dim: Vector2, corpo: int,
		colore: Color, allinea: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = testo
	l.position = pos
	l.size = dim
	l.horizontal_alignment = allinea
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", corpo)
	l.add_theme_color_override("font_color", colore)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_corpo.add_child(l)
	return l
