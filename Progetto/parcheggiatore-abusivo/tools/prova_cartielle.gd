extends Node
## 'E cartielle nun hann'a ascì 'a fore ô schermo.
##
## `event_banner` è la riga arancione che compare a mezzo schermo quando
## succede qualcosa. Fino alla 0.50 era un `Label` largo 800 pixel a corpo
## 28 **senza andare a capo**: diciotto messaggi del gioco erano più lunghi
## di così e la coda della frase usciva dal bordo. Il difetto non si vedeva
## provando, perché i cartelli corti — che sono la maggioranza — stavano
## dentro.
##
## Questa prova non guarda il numero di lettere: **misura il testo col
## font vero**, come fa Godot per disegnarlo, e controlla che stia in due
## righe della larghezza vera. È l'unico modo di saperlo per davvero, ed è
## la stessa cura già usata per i fumetti nella 0.50.

const Hud := preload("res://scripts/hud.gd")

## Le misure vere del cartello, copiate da `hud.gd`. Se cambiano là e non
## qua, la prova diventa bugiarda: per questo il primo controllo è che il
## Label costruito davvero abbia queste misure.
const LARGHEZZA: float = 1100.0
const RIGHE_MAX: int = 2

var _male: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	print("=== 'E CARTIELLE ===")

	var hud = Hud.new()
	add_child(hud)
	await get_tree().process_frame
	var banner: Label = hud.get("event_banner")
	if banner == null:
		print("  nun se trova 'o banner: STORTO")
		_male += 1
		print("=== %d storte ===" % _male)
		get_tree().quit()
		return

	# 1. Le misure del Label sono quelle che questa prova crede.
	_verifica("'o cartiello è largo %d" % int(LARGHEZZA),
		absf(banner.size.x - LARGHEZZA) < 1.0)
	_verifica("va a capo 'a sulo",
		banner.autowrap_mode != TextServer.AUTOWRAP_OFF)

	# 2. Ogni frase che il gioco può stampare, misurata col font vero.
	var frasi: Array = _tutte_e_frasi()
	var font: Font = banner.get_theme_font("font")
	var fuori := 0
	var peggio: float = 0.0
	var peggiore := ""
	for f in frasi:
		var testo: String = str(f)
		var corpo: int = hud.call("_corpo_cartiello", testo.length())
		var m: Vector2 = font.get_multiline_string_size(testo,
			HORIZONTAL_ALIGNMENT_CENTER, LARGHEZZA, corpo, -1,
			TextServer.BREAK_WORD_BOUND | TextServer.BREAK_MANDATORY)
		# **L'altezza di una riga non è il corpo del carattere.** Ci stanno
		# dentro anche lo spazio sopra e sotto, e cambiano da font a font:
		# contare le righe come `m.y / corpo` dava tre righe pure a
		# "OSPEDALE!". Si misura una riga vera con lo stesso font e lo
		# stesso corpo, e si divide per quella.
		var h1: float = font.get_multiline_string_size("Ajj",
			HORIZONTAL_ALIGNMENT_CENTER, LARGHEZZA, corpo, -1,
			TextServer.BREAK_WORD_BOUND | TextServer.BREAK_MANDATORY).y
		var righe: int = int(round(m.y / maxf(h1, 1.0)))
		if m.x > LARGHEZZA + 1.0 or righe > RIGHE_MAX:
			fuori += 1
			print("    FORE: (%d righe, %d px) %s" % [righe, int(m.x), testo])
		if m.x > peggio:
			peggio = m.x
			peggiore = testo
	_verifica("tutt''e %d frase stanno dinto (fore: %d)" % [frasi.size(), fuori],
		fuori == 0)
	print("  'a cchiù longa: %d px ncopp'a %d  ->  %s" % [
		int(peggio), int(LARGHEZZA), peggiore])

	# 3. Le cinque frasi delle fasce, che sono nuove della 0.51.
	for f in GameManager.FASCE:
		var t: String = str(f["detto"])
		_verifica("fascia %-16s (%2d lettere)" % [str(f["nome"]), t.length()],
			t.length() <= 56)

	print("=== %d storte ===" % _male)
	get_tree().quit()


## Tutte le frasi che finiscono nel cartello, raccolte dai sorgenti. Si
## leggono i file invece di elencarle a mano: una frase nuova entra nella
## prova da sola, che è il solo modo perché una prova così resti vera.
func _tutte_e_frasi() -> Array:
	var fuori: Array = []
	var da_vedere: Array = ["res://scripts"]
	while not da_vedere.is_empty():
		var cartella: String = str(da_vedere.pop_back())
		var d := DirAccess.open(cartella)
		if d == null:
			continue
		d.list_dir_begin()
		var n := d.get_next()
		while n != "":
			if d.current_is_dir():
				if not n.begins_with("."):
					da_vedere.append("%s/%s" % [cartella, n])
			elif n.ends_with(".gd"):
				fuori.append_array(_frasi_dint_a("%s/%s" % [cartella, n]))
			n = d.get_next()
		d.list_dir_end()
	return fuori


## Le stringhe letterali passate a `event_started.emit("...")`. I `%s` e i
## `%d` si sostituiscono con un riempitivo lungo quanto basta: un nome
## proprio e un numero a tre cifre sono il caso vero e proprio.
func _frasi_dint_a(percorso: String) -> Array:
	var t := FileAccess.get_file_as_string(percorso)
	if t.is_empty():
		return []
	var fuori: Array = []
	var re := RegEx.new()
	re.compile("event_started\\.emit\\(\\s*\"((?:[^\"\\\\]|\\\\.)*)\"")
	for m in re.search_all(t):
		var s: String = m.get_string(1)
		s = s.replace("\\n", " ").replace("\\\"", "\"")
		s = s.replace("%%", "%")
		s = s.replace("%s", "Peppino 'o Sicco")
		s = s.replace("%d", "480")
		s = s.replace("%.1f", "48.0").replace("%.2f", "48.00")
		fuori.append(s)
	return fuori


func _verifica(che: String, ok: bool) -> void:
	if not ok:
		_male += 1
	print("  %-52s %s" % [che, "OK" if ok else "STORTO"])
