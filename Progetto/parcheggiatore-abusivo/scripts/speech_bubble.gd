extends Node3D
## SpeechBubble — 'o fummetto
##
## **Pecché s'è rifatto 'a capo (0.50).**
##
## Il giudizio del capo era: *"a volte sono enormi, a volte minuscoli, a
## volte sforano il balloon"*. Tutti e tre i difetti hanno la stessa
## origine, ed è una riga sola: **la misura del fumetto era indovinata,
## non misurata.**
##
##     var w := clampf(0.30 + t.length() * 0.095, 0.60, 2.26)
##     var righe := ceil(t.length() / 20.2)
##
## Cioè: quanto è largo dipende da **quante lettere ci sono**. Ma le lettere
## non sono larghe uguali — `"Mmmm"` occupa il doppio di `"illi"` — e
## soprattutto il testo poi va a capo da solo con `autowrap`, che spezza
## dove capitano gli **spazi**, non ogni 20,2 caratteri. Quindi:
##
##   * frase corta con parole larghe → il testo esce dal bianco;
##   * frase lunga con parole strette → il bianco è il doppio del testo;
##   * una parola sola lunghissima → una riga contata, tre righe disegnate,
##     e le ultime due finiscono fuori dal fondo.
##
## Adesso il testo si **misura davvero**, con lo stesso font, la stessa
## dimensione e le stesse regole di andata a capo che userà il Label3D:
## `Font.get_multiline_string_size()` restituisce il rettangolo esatto che
## il testo occuperà. Il fondo si taglia su quel rettangolo più un margine,
## e non può sbagliare — perché non sta più stimando niente.
##
## Le altre due cose che sono cambiate:
##
##   * **un bordo scuro**, che è quello che rende un rettangolo bianco un
##     fumetto invece che un cartello;
##   * **un tetto al numero di righe**: oltre tre, la frase si tronca con i
##     puntini. Un personaggio di passaggio non deve tenere un comizio, e un
##     fumetto alto quattro righe copre la faccia di chi parla.

## **'A parola ca nun se pò spezzà (0.51).**
##
## La misura della 0.50 era giusta per ogni frase del gioco tranne una
## famiglia: quelle con dentro **una parola sola più larga del fumetto**.
## Il motivo è che i due conti usavano regole di andata a capo diverse:
##
##   * la misura chiedeva `BREAK_WORD_BOUND | BREAK_MANDATORY` — "vai a
##     capo agli spazi" — e una parola senza spazi le restava tutta su una
##     riga: tre metri e venti di larghezza, una riga sola;
##   * il `Label3D`, con `AUTOWRAP_WORD_SMART`, quella parola la **spezza
##     a metà** quando non ci sta, e ne fa due righe.
##
## Risultato: il bianco veniva tagliato largo il doppio e alto la metà del
## nero.
##
## La regola giusta non si indovina: sta scritta in `label_3d.cpp`, ed è
## **quella e nessun'altra**. `AUTOWRAP_WORD_SMART` vale
## `BREAK_WORD_BOUND | BREAK_ADAPTIVE | BREAK_MANDATORY`, e Godot ci
## aggiunge sempre `BREAK_TRIM_EDGE_SPACES`. Non è `BREAK_GRAPHEME_BOUND`
## — quello è `AUTOWRAP_ARBITRARY`, che spezza in mezzo alle parole
## *sempre*, e a provarlo il fumetto veniva **più largo** del disegnato,
## perché riempiva le righe fino all'orlo.
##
## Adesso i due conti fanno letteralmente la stessa operazione, e
## `tools/prova_fummetto.gd` lo dimostra confrontando il quad bianco con
## l'ingombro vero che Godot dichiara per il testo (`Label3D.get_aabb()`).
const SPEZZA := TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND \
	| TextServer.BREAK_ADAPTIVE | TextServer.BREAK_TRIM_EDGE_SPACES

## Da pixel di layout a metri.
const PIXEL_SIZE := 0.005
## A questa distanza il fumetto sta alla misura sua. Più vicino rimpicciolisce
## in proporzione, così quanto occupa a schermo non cambia.
const DIST_RIF: float = 3.2
## Quanto è largo al massimo, in pixel di layout: per PIXEL_SIZE fa 2,1 metri.
const LARGH_MAX: float = 420.0
const CORPO: int = 40
## Il margine bianco attorno al testo, in metri.
const MARGINE := Vector2(0.11, 0.075)
## Oltre questo numero di righe la frase si tronca.
const RIGHE_MAX: int = 3

var _label: Label3D
var _bg: MeshInstance3D
var _bordo: MeshInstance3D
var _tail: MeshInstance3D
var _timer: float = 0.0


func _ready() -> void:
	# Il bordo: lo stesso quad, un filo più grande e scuro, appena dietro.
	_bordo = MeshInstance3D.new()
	_bordo.mesh = QuadMesh.new()
	_bordo.material_override = _piatto(Color(0.13, 0.11, 0.10), 9)
	add_child(_bordo)

	# Sfondo bianco (quad billboard)
	_bg = MeshInstance3D.new()
	_bg.mesh = QuadMesh.new()
	_bg.material_override = _piatto(Color(0.98, 0.98, 0.96), 10)
	add_child(_bg)

	# Codina: un piccolo rombo bianco sotto il balloon
	_tail = MeshInstance3D.new()
	var tail_mesh := QuadMesh.new()
	tail_mesh.size = Vector2(0.14, 0.14)
	_tail.mesh = tail_mesh
	_tail.material_override = _piatto(Color(0.98, 0.98, 0.96), 10)
	add_child(_tail)

	# Testo nero sopra lo sfondo
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.font_size = CORPO
	_label.pixel_size = PIXEL_SIZE
	_label.outline_size = 0
	_label.width = LARGH_MAX
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.modulate = Color(0.08, 0.08, 0.08)
	_label.render_priority = 12
	add_child(_label)

	visible = false


## **'O guasto ca s'è visto sulo 'a luntano (0.51).**
##
## Questo è il difetto che restava dietro a *"a volte sforano il
## balloon"*, e la 0.50 non l'aveva preso perché non si vede mai da
## fermo a tre metri: **`billboard_mode` senza `billboard_keep_scale`
## butta via la scala del nodo.**
##
## Il fumetto si rimpicciolisce con la distanza (`_misura()` scrive
## `scale`), e il `Label3D` quella scala se la tiene. I tre quad — bianco,
## bordo, codina — no: il materiale li girava verso la camera *e li
## disegnava sempre alla misura base*. A tre metri e venti la scala vale
## 1 e tutto combacia; a cinque metri il testo era grosso il cinquanta per
## cento più del bianco che avrebbe dovuto contenerlo, e usciva da tutti e
## quattro i lati.
##
## Una proprietà. `tools/prova_fummetto.gd` adesso misura a cinque
## distanze diverse apposta, perché a una sola distanza il guasto non
## esisteva.
func _piatto(c: Color, priorita: int) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.no_depth_test = true
	m.render_priority = priorita
	return m


## Il font che userà davvero il Label3D. `Label3D.font` è vuoto finché non
## se ne assegna uno a mano, e in quel caso disegna col font di ripiego del
## tema: è quello che va misurato, se no si misura una cosa e se ne disegna
## un'altra.
func _font() -> Font:
	var f: Font = _label.font
	if f == null:
		f = ThemeDB.fallback_font
	return f


func say(t: String, duration: float = 2.4) -> void:
	var testo := _tronca(t)
	_label.text = testo

	# **'A misura vera.** Stesse regole del Label3D: stessa larghezza
	# massima, stesso corpo, stesso modo di andare a capo.
	var f := _font()
	var misura := Vector2(120.0, 44.0)
	if f != null:
		misura = f.get_multiline_string_size(testo,
			HORIZONTAL_ALIGNMENT_CENTER, LARGH_MAX, CORPO, -1, SPEZZA)
	var w: float = misura.x * PIXEL_SIZE + MARGINE.x * 2.0
	var h: float = misura.y * PIXEL_SIZE + MARGINE.y * 2.0
	# Un minimo c'è comunque: un "Ueh!" dentro a un fumetto grande quanto la
	# parola sembra un errore, non una battuta breve.
	w = maxf(w, 0.42)
	h = maxf(h, 0.26)

	(_bg.mesh as QuadMesh).size = Vector2(w, h)
	(_bordo.mesh as QuadMesh).size = Vector2(w + 0.035, h + 0.035)
	_bordo.position = Vector3(0, 0, -0.004)
	_label.position = Vector3(0, 0, 0.004)
	_tail.position = Vector3(0, -h * 0.5 - 0.045, 0.002)

	visible = true
	_timer = duration
	_misura()
	_gesticola()


## Tre righe e basta. Si taglia sulle parole, non a metà di una.
func _tronca(t: String) -> String:
	var f := _font()
	if f == null:
		return t
	var alta: float = f.get_height(CORPO)
	if alta <= 0.0:
		return t
	var quante := func(s: String) -> int:
		var m := f.get_multiline_string_size(s, HORIZONTAL_ALIGNMENT_CENTER,
			LARGH_MAX, CORPO, -1, SPEZZA)
		return int(round(m.y / alta))
	if quante.call(t) <= RIGHE_MAX:
		return t
	var parole := t.split(" ", false)
	var fin := ""
	for p in parole:
		var prova := (fin + " " + p).strip_edges() if fin != "" else str(p)
		if quante.call(prova + "…") > RIGHE_MAX:
			break
		fin = prova
	return (fin + "…") if fin != "" else t


## **Quanto è grosso dipende da quanto sta vicino.**
##
## Un fumetto è interfaccia travestita da oggetto: la misura giusta è
## quella che occupa sempre lo stesso pezzo di schermo. Dentro al vascio si
## parla a un metro di distanza, e alla misura fissa il balloon della
## mugliera copriva la stanza intera.
##
## Il taglio in basso è salito da 0,30 a 0,42: sotto al metro di distanza il
## fumetto smetteva di rimpicciolire e tornava a crescere sullo schermo —
## ed è il caso del vascio, dove si parla faccia a faccia.
func _misura() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var d: float = cam.global_position.distance_to(global_position)
	scale = Vector3.ONE * clampf(d / DIST_RIF, 0.42, 1.7)


## **Chi parla, gesticola.**
##
## È la riga che vale più di tutte quelle che si potevano scrivere: sta in
## un posto solo e vale per **ogni personaggio del gioco che apre bocca** —
## il vigile, l'autista, 'O Zio, i vecchi della scopa, la moglie, i
## bambini. Nessuno di loro ha dovuto essere toccato.
func _gesticola() -> void:
	# **Si cerca SOTTO, non sopra.** La prima versione risaliva l'albero
	# guardando i figli diretti di ogni genitore, e non trovava mai niente:
	# l'Animator sta a personaggio → _visual_root → Rig → Animator, cioè
	# **tre piani più giù**, non di fianco.
	var p: Node = get_parent()
	var giri := 0
	while p != null and giri < 3:
		var a: Node = p.find_child("Animator", true, false)
		if a != null and a.has_method("action"):
			if a.has_method("is_sitting") and a.is_sitting():
				return # da seduto ci pensa la clip "seduto_parla"
			a.action("parla")
			return
		p = p.get_parent()
		giri += 1


func _process(delta: float) -> void:
	if _timer > 0.0:
		_timer -= delta
		_misura()
		if _timer <= 0.0:
			visible = false
