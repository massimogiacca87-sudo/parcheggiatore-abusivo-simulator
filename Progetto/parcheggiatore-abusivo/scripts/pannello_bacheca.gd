extends CanvasLayer
## PannelloBacheca — 'e ffatiche e 'e ccase
##
## Due schede, e non è una scelta di comodo: sono le due velocità con cui
## si guarda alla giornata. **'E LAVORE** è oggi — roba che scade stasera,
## paga subito, rischio subito. **'E CASE** sono i mesi — un numero grosso
## in fondo alla pagina che per venti giorni non puoi permetterti e che è
## tutto il motivo per cui la sera torni a contare.
##
## Sta insieme al pannello di casa (`pannello_casa.gd`) come stile: fondo
## scuro, poche righe, bottoni che dicono già il numero. Qui non si
## ottimizza, si sceglie.

const LARGH: float = 720.0

var bacheca: Node = null

var _fondo: ColorRect
var _pannello: PanelContainer
var _titolo: Label
var _schede: HBoxContainer
var _lista: VBoxContainer
var _pie: Label
var _aperto: bool = false
var _scheda: String = "lavore"


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_costruisci()
	GameManager.lavoretti_cambiati.connect(_aggiorna)


func _costruisci() -> void:
	_fondo = ColorRect.new()
	_fondo.color = Color(0, 0, 0, 0.66)
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_fondo)

	_pannello = PanelContainer.new()
	_pannello.set_anchors_preset(Control.PRESET_CENTER)
	_pannello.custom_minimum_size = Vector2(LARGH, 0)
	_pannello.position = Vector2(-LARGH * 0.5, -270)
	# **'O fondo ha 'a essere chino.** Quello di serie di Godot è
	# semitrasparente: nella prima foto si leggeva il muro giallo del
	# palazzo attraverso i prezzi delle case.
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.09, 0.08, 0.11, 0.985)
	st.border_color = Color(0.62, 0.50, 0.30)
	st.set_border_width_all(2)
	st.set_corner_radius_all(6)
	_pannello.add_theme_stylebox_override("panel", st)
	add_child(_pannello)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 22)
	m.add_theme_constant_override("margin_right", 22)
	m.add_theme_constant_override("margin_top", 18)
	m.add_theme_constant_override("margin_bottom", 18)
	_pannello.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)

	_titolo = Label.new()
	_titolo.text = "'A BACHECA"
	_titolo.add_theme_font_size_override("font_size", 26)
	v.add_child(_titolo)

	_schede = HBoxContainer.new()
	_schede.add_theme_constant_override("separation", 8)
	v.add_child(_schede)

	v.add_child(HSeparator.new())

	_lista = VBoxContainer.new()
	_lista.add_theme_constant_override("separation", 8)
	v.add_child(_lista)

	_pie = Label.new()
	_pie.modulate = Color(0.72, 0.70, 0.66)
	_pie.text = "[ESC] pe' chiudere"
	v.add_child(_pie)


func aperto() -> bool:
	return _aperto


func apri() -> void:
	_aperto = true
	visible = true
	get_tree().paused = true
	GameManager.piglia_o_mouse(false)
	_aggiorna()


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


# ---------------------------------------------------------------------------

func _aggiorna() -> void:
	if not _aperto:
		return
	_titolo.text = "'A BACHECA — %s · 'e %s" % [
		str(bacheca.nome_zona) if bacheca != null else "'a piazza",
		GameManager.orologio()]
	_svuota(_schede)
	_bottone_scheda("'E LAVORE 'E OGGE", "lavore")
	_bottone_scheda("'E CASE", "case")
	_svuota(_lista)
	if _scheda == "case":
		_disegna_case()
	else:
		_disegna_lavore()


func _bottone_scheda(testo: String, id: String) -> void:
	var b := Button.new()
	b.text = testo
	b.custom_minimum_size = Vector2(200, 34)
	b.disabled = (_scheda == id)
	b.pressed.connect(func():
		_scheda = id
		_aggiorna())
	_schede.add_child(b)


# --- 'E lavore ---

func _disegna_lavore() -> void:
	var in_corso: Dictionary = GameManager.lavoretto_in_corso()
	if not in_corso.is_empty():
		# **Uno per volta.** Due pacchi in mano non sono un gioco, sono una
		# lista della spesa: l'unica cosa che si può fare qui è mollare
		# quello che si sta facendo.
		_riga("STAJE FACENNO", str(in_corso["nome"]),
			str(in_corso["testo"]), Color(1.0, 0.84, 0.34))
		_bottone("Lascia perdere stu lavoro", func():
			GameManager.molla_lavoretto()
			_aggiorna())
		return

	# **'O cunziglio ncopp'â bacheca.**
	#
	# Dalla 0.51 le ore hanno un carattere: alle tre non arriva nessuno,
	# alle dieci di sera la piazza rende da sola. La bacheca è il posto
	# dove quella scelta si fa, quindi è qui che va detta — se no il
	# giocatore il numero non lo vede mai, e il sistema resta un segreto
	# fra il codice e sé stesso.
	# **'A jurnata speciale se legge primma 'e tutto (0.52).** La bacheca
	# è il posto dove si decide come spendere la giornata, e il consiglio
	# giusto dipende prima da che giorno è e poi da che ora è.
	if GameManager.e_speciale():
		_riga("", GameManager.giornata_nome().to_upper(),
			"%s  %s" % [GameManager.biglietto(),
				GameManager.cunziglio_d_a_jurnata()],
			Color(1.0, 0.72, 0.86))

	var fa: int = GameManager.fascia_indice()
	var ora: String = GameManager.fascia_nome()
	if fa <= 1:
		_riga("", "Chest'è ll'ora bbona pe' 'nu lavoretto",
			"Sta correnno %s: 'n piazza nun se fatica, 'o tiempo tuoje mo' vale 'e cchiù ccà." % ora,
			Color(0.98, 0.86, 0.42))
	elif fa >= 4:
		_riga("", "Mo' 'a piazza pava 'o doppio",
			"Sta correnno %s: poche machine, ma chi vene lassa 'o doppio. Nu lavoretto mo' te costa cchiù 'e chello ca rende." % ora,
			Color(0.72, 0.80, 1.0))
	else:
		_riga("", "'A piazza sta caminanno",
			"Sta correnno %s: 'e mmacchine arrivano fitte. Piglia 'nu lavoretto sulo si te serve overo." % ora,
			Color(0.78, 0.86, 0.82))

	var quanti := 0
	for l in GameManager.lavoretti:
		if str(l["stato"]) != "offerto":
			continue
		quanti += 1
		var titolo: String = str(l["nome"])
		var sotto := ""
		var col := Color(0.86, 0.90, 0.94)
		titolo = "%s  ·  €%d" % [titolo, int(l["paga"])]
		match str(l["tipo"]):
			"pacco":
				sotto = "Piglia %s 'a %s e portalo 'a %s. %s" % [
					str(l["roba"]), str(l["nome_da"]), str(l["nome_a"]),
					str(l["testo"])]
				col = Color(0.98, 0.82, 0.38)
			"caffe":
				sotto = "Piglia %s 'a %s e portalo 'a %s — e tiene sulo %d secunne. %s" % [
					str(l["roba"]), str(l["nome_da"]), str(l["nome_a"]),
					int(l.get("tempo", 60)), str(l["testo"])]
				col = Color(0.94, 0.68, 0.34)
			"stemme":
				sotto = "Stacca %d stemme 'a 'e mmacchine e portale ô garage. %s" % [
					int(l.get("quanti", 2)), str(l["testo"])]
				col = Color(0.72, 0.86, 1.0)
			"guardia":
				sotto = "Va' 'a %s e statte llà %d secunne senza fa' 'ncazzà a nisciuno. %s" % [
					str(l["nome_a"]), int(l.get("secondi", 60)),
					str(l["testo"])]
				col = Color(0.74, 0.94, 0.78)
			_:
				sotto = str(l["testo"])
		_riga("", titolo, sotto, col)
		var lid: String = str(l["id"])
		_bottone("Piglio chisto", func():
			if GameManager.accetta_lavoretto(lid):
				SoundManager.play("pop", -8.0, 1.15)
				chiudi()
			else:
				_aggiorna())

	if quanti == 0:
		_riga("", "Oggi nun ce sta niente.",
			"Torna dimane matina: 'e ffoglie 'e cagnano tutt''e juorne.",
			Color(0.74, 0.72, 0.68))


func _articolo(tipo: String) -> String:
	match tipo:
		"economica": return "'na machinella"
		"berlina": return "'na berlina"
		"lusso": return "'nu fuoristrada"
		"bmw": return "'na machina 'e chelle bbone"
	return "'na machina"


# --- 'E case ---

func _disegna_case() -> void:
	var mia: Dictionary = GameManager.casa_mia()
	var prossima: Dictionary = GameManager.casa_prossima()
	for c in GameManager.CASE:
		var id: String = str(c["id"])
		var e_mia: bool = id == str(mia["id"])
		var comprabile: bool = not prossima.is_empty() \
			and id == str(prossima["id"])
		var col := Color(0.52, 0.52, 0.50)
		var testa := ""
		if e_mia:
			col = Color(0.55, 1.0, 0.62)
			testa = "CE STAJE MO'"
		elif comprabile:
			col = Color(1.0, 0.86, 0.42)
			testa = "'O PROSSIMO GRADINO"
		var titolo: String = "%s — %s" % [str(c["nome"]), str(c["dove"])]
		if int(c["prezzo"]) > 0:
			titolo += "  ·  €%s" % _sorde(int(c["prezzo"]))
		var sotto: String = str(c["desc"])
		if int(c["prezzo"]) > 0:
			sotto += "\nFitto: x%.2f  ·  Umore â matina: +%d  ·  Sopporta 'e guaje: x%.2f" % [
				float(c["fitto"]), int(c["umore"]), float(c["sopporta"])]
		_riga(testa, titolo, sotto, col)
		if comprabile:
			var prezzo: int = int(c["prezzo"])
			if GameManager.money >= prezzo:
				_bottone("Accàttala — €%s" % _sorde(prezzo), func():
					if GameManager.accatta_casa(id):
						chiudi())
			else:
				var manca: int = prezzo - GameManager.money
				_riga("", "", "Te mancano €%s." % _sorde(manca),
					Color(0.92, 0.52, 0.42))


## I numeri grossi col punto: "27.500" si legge, "27500" si conta.
func _sorde(n: int) -> String:
	var t: String = str(n)
	var fuori := ""
	var c := 0
	for i in range(t.length() - 1, -1, -1):
		fuori = t[i] + fuori
		c += 1
		if c % 3 == 0 and i > 0:
			fuori = "." + fuori
	return fuori


# ---------------------------------------------------------------------------

func _svuota(chi: Node) -> void:
	for c in chi.get_children():
		chi.remove_child(c)
		c.queue_free()


func _riga(testa: String, titolo: String, sotto: String, col: Color) -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	if not testa.is_empty():
		var t := Label.new()
		t.text = testa
		t.add_theme_font_size_override("font_size", 11)
		t.modulate = col
		v.add_child(t)
	if not titolo.is_empty():
		var l := Label.new()
		l.text = titolo
		l.add_theme_font_size_override("font_size", 17)
		l.modulate = col
		v.add_child(l)
	if not sotto.is_empty():
		var s := Label.new()
		s.text = sotto
		s.autowrap_mode = TextServer.AUTOWRAP_WORD
		s.custom_minimum_size = Vector2(LARGH - 60, 0)
		s.add_theme_font_size_override("font_size", 13)
		s.modulate = Color(col.r, col.g, col.b, 0.78)
		v.add_child(s)
	_lista.add_child(v)


func _bottone(testo: String, azione: Callable) -> void:
	var b := Button.new()
	b.text = testo
	b.custom_minimum_size = Vector2(LARGH - 60, 34)
	b.pressed.connect(azione)
	_lista.add_child(b)
	if _lista.get_child_count() <= 2:
		b.call_deferred("grab_focus")
