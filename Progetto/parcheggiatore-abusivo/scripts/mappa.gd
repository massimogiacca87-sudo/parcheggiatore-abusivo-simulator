extends Control
## 'A chiantina — la mappa della città, tasto M
##
## **Perché serviva.** La città è centonovanta metri per centosettantadue,
## dieci quartieri, quattro zone da lavorare e i vicoli larghi quattro
## metri: dentro non si capisce dove si sta. Il nome della strada in basso a
## sinistra dice *dove sei*, ma non dice *dove sta il resto* — e la prima
## cosa che uno vuole sapere è da che parte è la piazza sua.
##
## **Come è disegnata.** Non è un'immagine: si ridisegna a ogni frame dalle
## STESSE costanti da cui è costruita la città — `ISOLATI`, `STRADE`,
## `SLARGHI`, `ZONE`, i rettangoli dei quartieri, il terrapieno del Vomero.
## Quindi non può andare fuori sincrono: se domani si sposta un vicolo, la
## mappa lo sa da sola. È lo stesso motivo per cui la pianta la calcola
## `tools/pianta.py` invece di scriverla a mano.
##
## L'orientamento è quello vero: il mare in alto (z negativo), la collina in
## basso a destra. Nord in alto, come tutte le mappe.
##
## ---------------------------------------------------------------------
##
## **Come è stata rifatta (0.45), e perché.** La prima versione disegnava
## *tutto insieme*: undici nomi di quartiere, quattro nomi di strada, tre
## righe di testo per ognuna delle quattro zone, più un pallino con
## didascalia per ogni vecchio, ogni guaglione, ogni commissione e ogni
## landmark. Trenta scritte su una carta di seicento pixel, tutte dello
## stesso peso, tutte una sopra all'altra. Il giudizio del capo è stato
## "non si capisce un cazzo", ed era giusto.
##
## Tre regole, adesso:
##
## 1. **Le scritte non si sovrappongono mai.** Non è più una speranza: ogni
##    etichetta viene *chiesta* con una priorità (`_chiedi`), e alla fine
##    `_piazza_etichette` le sistema in ordine di importanza provando
##    quattro posizioni intorno al segno. Quella che non trova posto non si
##    disegna — meglio un'informazione in meno che due illeggibili.
## 2. **Le forme si distinguono al buio.** Prima era tutto un pallino
##    colorato: casa, vecchio, guaglione, consegna. Adesso ogni cosa ha una
##    sagoma sua (`_icona`), e la stessa funzione disegna la legenda — così
##    il segno sulla carta e il segno nella legenda non possono divergere.
## 3. **Una cosa sola comanda.** Se sto portando una consegna, o se sono le
##    quattro e devo tornare, quella diventa il *fine* della mappa: cerchio
##    che pulsa, filo tratteggiato che parte da te, metri che mancano, e il
##    riquadro grosso in cima al pannello. Tutto il resto si fa da parte.
##
## Il pannello a destra si porta via il testo lungo (prezzi, legenda, dove
## stai) che prima stava stampato sopra ai vicoli.

const Tex := preload("res://scripts/textures.gd")

## Margine intorno a tutto.
const MARGINE: float = 22.0
## Larghezza del pannello di destra. Sotto i 980 pixel di schermo il
## pannello si stringe; sotto gli 820 sparisce e resta la sola carta.
const PANNELLO_L: float = 292.0
const PANNELLO_MIN: float = 232.0

var _citta: Node = null
var _player: Node3D = null
var _font: Font
var _tempo: float = 0.0

# Le etichette chieste in questo frame, e lo spazio già occupato. Si
# svuotano all'inizio di ogni `_draw`.
var _etichette: Array = []
var _presi: Array[Rect2] = []
## I rettangoli dei **segni** (le icone), tenuti a parte da quelli delle
## scritte. Servono separati per una ragione precisa: un'etichetta puo'
## ignorare il segno **suo** (se no si boccia da sola), ma non deve poter
## ignorare la scritta di un altro. Tenendo tutto in una lista sola, il
## nome del quartiere si infilava sotto alla didascalia del pacco ogni
## volta che l'ancora del quartiere cadeva dentro a quel riquadro.
var _segni_presi: Array[Rect2] = []

# Colori. Tenuti insieme qui perché una mappa si legge per contrasto, non
# per bellezza: la strada è il chiaro, l'isolato è il pieno scuro, e fra i
# due ci deve stare abbastanza differenza da vedersi con la coda
# dell'occhio mentre uno corre.
const C_VELO := Color(0.04, 0.04, 0.06, 0.93)
const C_CARTA := Color(0.985, 0.965, 0.905)
const C_ISOLATO := Color(0.63, 0.57, 0.485)
const C_MARE := Color(0.36, 0.58, 0.72)
const C_COLLINA := Color(0.78, 0.71, 0.50)
const C_INK := Color(0.13, 0.11, 0.09)
const C_BORDO := Color(0.24, 0.19, 0.14)

const C_MIA := Color(0.16, 0.66, 0.32)
const C_ALTRUI := Color(0.78, 0.22, 0.18)
const C_CASA := Color(1.0, 0.66, 0.22)
const C_URGENTE := Color(1.0, 0.34, 0.30)
const C_CONSEGNA := Color(0.22, 0.80, 0.42)
const C_RITIRO := Color(0.98, 0.78, 0.24)
const C_TU := Color(0.12, 0.40, 0.95)
const C_PACCO := Color(1.0, 0.56, 0.20)
const C_GARAGE := Color(0.58, 0.72, 1.0)
const C_BACHECA := Color(0.86, 0.70, 0.44)

## Le tinte dei quartieri. Tre e basta, a rotazione: servono a far vedere
## dove finisce uno e comincia l'altro, non a colorare. Undici tinte
## diverse — come stava prima — sono un arcobaleno, e un arcobaleno non è
## una gerarchia.
const TINTE := [
	Color(0.96, 0.88, 0.68),
	Color(0.80, 0.90, 0.82),
	Color(0.87, 0.85, 0.94),
]


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	# 0.62: il carattere del gioco (Poppins), non quello di fabbrica.
	_font = UiStile.font_grassetto()
	if _font == null:
		_font = ThemeDB.fallback_font


func apri(citta: Node, player: Node3D) -> void:
	_citta = citta
	_player = player
	visible = true
	queue_redraw()


func chiudi() -> void:
	visible = false


func _process(d: float) -> void:
	if visible:
		_tempo += d
		queue_redraw()


## La misura dello schermo.
##
## Non si usa `size`: questo Control sta dentro a un CanvasLayer, quindi il
## suo genitore non e' un Control e gli ancoraggi non gli danno una misura
## affidabile prima del primo layout — al primo disegno la carta usciva
## grande venti pixel in un angolo. Il viewport la misura sempre giusta.
func _schermo() -> Vector2:
	return get_viewport_rect().size


## Quanto spazio si prende il pannello di destra, zero se non ci sta.
func _larghezza_pannello() -> float:
	var w: float = _schermo().x
	if w < 820.0:
		return 0.0
	if w < 980.0:
		return PANNELLO_MIN
	return PANNELLO_L


## Da metri di mondo a pixel di schermo.
##
## Il riquadro comprende anche la fascia di mare sopra alla città, se no il
## lungomare — che è mezzo quartiere — resterebbe fuori dalla carta.
func _telaio() -> Dictionary:
	var w: float = 190.0
	var l: float = 172.0
	var nord: float = -22.0
	if _citta != null:
		w = _citta.LARGHEZZA
		l = _citta.PROFONDITA
		nord = _citta.LIMITE_NORD - 3.0
	var mw: float = w
	var ml: float = l - nord
	var sc := _schermo()
	# In alto ci sta la testata, in basso la riga dei tasti.
	var alto: float = MARGINE + 34.0
	var basso: float = MARGINE + 22.0
	var pan: float = _larghezza_pannello()
	var libero := Vector2(
		sc.x - MARGINE * 2.0 - pan - (18.0 if pan > 0.0 else 0.0),
		sc.y - alto - basso)
	var s: float = minf(libero.x / mw, libero.y / ml)
	var org := Vector2(
		MARGINE + (libero.x - mw * s) / 2.0,
		alto + (libero.y - ml * s) / 2.0)
	return {"s": s, "org": org, "nord": nord, "w": w, "l": l}


func _p(t: Dictionary, x: float, z: float) -> Vector2:
	return Vector2(t["org"]) + Vector2(x, z - float(t["nord"])) * float(t["s"])


func _rett(t: Dictionary, r) -> Rect2:
	var a := _p(t, float(r[0]), float(r[1]))
	var b := _p(t, float(r[2]), float(r[3]))
	return Rect2(a, b - a)


func _carta_rect(t: Dictionary) -> Rect2:
	return Rect2(
		Vector2(t["org"]) - Vector2(14, 14),
		Vector2(float(t["w"]), float(t["l"]) - float(t["nord"]))
			* float(t["s"]) + Vector2(28, 28))


# ===========================================================================
# 'O DISEGNO
# ===========================================================================


func _draw() -> void:
	if _citta == null:
		return
	_etichette.clear()
	_presi.clear()
	_segni_presi.clear()
	var t := _telaio()

	draw_rect(Rect2(Vector2.ZERO, _schermo()), C_VELO)
	_disegna_fondo(t)
	_disegna_zone(t)

	var ob := _obiettivo()

	_disegna_strade(t)
	_disegna_quartieri(t)
	_disegna_landmark(t)
	_disegna_servizi(t)
	_disegna_guagliuni(t)
	_disegna_viecchie(t)
	_disegna_cummissiune(t, ob)
	_disegna_casa(t, ob)
	_disegna_filo(t, ob)

	_piazza_etichette(_carta_rect(t))
	# **Tu stai sopra a tutto** (0.62). Il segno del player veniva prima
	# delle scritte, e il nome della piazza — che si centra proprio dove
	# tu stai all'inizio della giornata — ci finiva sopra: la carta si
	# apriva e "Tu" non c'era.
	_disegna_player(t)

	_disegna_testate(t)
	if _larghezza_pannello() > 0.0:
		_disegna_pannello(ob)


## Carta, mare, quartieri, collina, isolati, strade. In quest'ordine: i
## pieni sopra alle tinte, il vuoto sopra ai pieni. È come si legge una
## pianta vera — la strada è quello che *resta*.
func _disegna_fondo(t: Dictionary) -> void:
	var carta := _carta_rect(t)
	draw_rect(carta.grow(3.0), Color(0, 0, 0, 0.35))
	draw_rect(carta, C_CARTA)

	# Il terrapieno del Vomero: sulla carta la collina si deve vedere che è
	# collina, e a un livello diverso dal resto.
	var coll := _rett(t, Collina.RECT)
	draw_rect(coll, C_COLLINA)

	for b in _citta.ISOLATI:
		draw_rect(_rett(t, b), C_ISOLATO)
	for s in _citta.STRADE:
		draw_rect(_rett(t, s), C_CARTA)
	for s2 in _citta.SLARGHI:
		draw_rect(_rett(t, s2), C_CARTA)

	# **Le tinte dei quartieri vanno SOPRA, non sotto.**
	#
	# Al primo giro stavano sotto agli isolati, con l'idea che si vedessero
	# nelle strade — come sulle piante vere. Nella foto non si vedeva
	# niente: le strade qui sono larghe quattro metri, cioe' tredici pixel,
	# e tredici pixel di tinta chiara sotto a un reticolo di isolati non
	# fanno un quartiere, fanno sporco. Sopra a tutto, al ventidue per
	# cento, si legge la campitura e si continuano a leggere gli isolati.
	var i: int = 0
	for k in Quartieri.ORDINE:
		var q: Dictionary = Quartieri.QUARTIERI[k]
		var r: Array = q["rect"]
		if r.is_empty():
			continue
		var tinta: Color = TINTE[i % TINTE.size()]
		draw_rect(_rett(t, r), Color(tinta.r, tinta.g, tinta.b, 0.22))
		i += 1

	# Il mare, sopra a tutto il resto: la fascia oltre z = 0.
	var mare := Rect2(carta.position,
		Vector2(carta.size.x, (0.0 - float(t["nord"])) * float(t["s"]) + 14.0))
	draw_rect(mare, C_MARE)
	# Due onde, che se no sembra un rettangolo blu e basta.
	for n in range(2):
		var y: float = mare.position.y + mare.size.y * (0.42 + 0.26 * float(n))
		var punti := PackedVector2Array()
		var x: float = mare.position.x + 8.0
		while x < mare.end.x - 8.0:
			punti.append(Vector2(x, y + sin(x * 0.09 + float(n)) * 2.0))
			x += 6.0
		if punti.size() > 1:
			draw_polyline(punti, Color(1, 1, 1, 0.16), 1.5)

	# Il bordo della collina, tratteggiato: è un dislivello, non un confine.
	draw_rect(coll, Color(0.46, 0.36, 0.20, 0.7), false, 1.5)
	# I confini dei quartieri.
	for k2 in Quartieri.ORDINE:
		var q2: Dictionary = Quartieri.QUARTIERI[k2]
		var r2: Array = q2["rect"]
		if r2.is_empty():
			continue
		draw_rect(_rett(t, r2), Color(0.36, 0.28, 0.20, 0.45), false, 1.0)

	draw_rect(carta, C_BORDO, false, 2.0)


## Le quattro zone da lavorare. La tua è verde, quelle degli altri sono
## rosse: è l'informazione più importante che c'è sulla carta, quindi è
## anche l'unica campitura forte.
func _disegna_zone(t: Dictionary) -> void:
	for z in _citta.ZONE:
		var mia: bool = GameManager.zona_mia(str(z["id"]))
		var col := C_MIA if mia else C_ALTRUI
		var r := _rett(t, z["rect"])
		draw_rect(r, Color(col.r, col.g, col.b, 0.26))
		draw_rect(r, col, false, 2.5)
		# Il prezzo non sta più sulla carta: sta nel pannello. Qui resta il
		# nome, e sotto una riga sola.
		var sotto: String = "'a toia" if mia else "€%d" % GameManager.prezzo_zona()
		_chiedi(r.get_center(), str(z["nome"]), 14, col.darkened(0.35), 80,
			sotto, true)


## **'A bacheca e 'o garage.** Due segni che stanno sempre lì e non cambiano
## mai: sono infrastruttura, non eventi. Per questo sono piccoli e senza
## didascalia — servono a sapere *dove sono*, non a chiamarti.
func _disegna_servizi(t: Dictionary) -> void:
	for b in get_tree().get_nodes_in_group("bacheche"):
		if not (b is Node3D):
			continue
		var v := _p(t, (b as Node3D).global_position.x,
			(b as Node3D).global_position.z)
		_icona("bacheca", v, C_BACHECA, 0.85)
	for g in get_tree().get_nodes_in_group("garage"):
		if not (g is Node3D):
			continue
		var v2 := _p(t, (g as Node3D).global_position.x,
			(g as Node3D).global_position.z)
		_icona("garage", v2, C_GARAGE, 0.85)


## I punti che si riconoscono: quelli per cui uno apre la mappa.
func _disegna_landmark(t: Dictionary) -> void:
	var punti := [
		[_citta.STADIO_CENTRO.x, _citta.STADIO_CENTRO.z + 21.0, "'O Stadio"],
		[float(_citta.POSTO_ARMIERE[0]), float(_citta.POSTO_ARMIERE[1]),
			"'O ferraro"],
		[95.0, -14.0, "Mergellina"],
		[65.0, 79.0, "'A funtana"],
	]
	for p in punti:
		var v := _p(t, float(p[0]), float(p[1]))
		_icona("posto", v, Color(0.98, 0.86, 0.34))
		_chiedi(v, str(p[2]), 12, C_INK, 50)


## **'A casa.**
##
## Alla fine della giornata la mappa si apre per una cosa sola: capire da
## che parte sta il vascio. Quando so' 'e quatto diventa il fine della
## carta e si prende il cerchio che pulsa.
func _disegna_casa(t: Dictionary, ob: Dictionary) -> void:
	var vascio := get_tree().get_first_node_in_group("vascio")
	if vascio == null:
		return
	var pos: Vector3 = vascio.PORTA_POS
	var v := _p(t, pos.x, pos.z)
	var urgente: bool = GameManager.giornata_scaduta
	var col := C_URGENTE if urgente else C_CASA
	if urgente or str(ob.get("tipo", "")) == "casa":
		_alone(v, col)
	_icona("casa", v, col, 1.2)
	var sotto: String = ""
	var dovuto: int = GameManager.spese_dovute()
	if dovuto > 0:
		sotto = "€%d 'a purtà" % dovuto
	_chiedi(v, "'A casa", 13, col.darkened(0.3), 95 if urgente else 70, sotto)


## **'E viecchie d''a scopa.** Cinque tavolini. Sulla carta si vede subito
## qual è quello che ti tocca adesso — gli altri stanno spenti, e senza
## nome: cinque didascalie per cinque vecchi erano cinque righe di troppo.
func _disegna_viecchie(t: Dictionary) -> void:
	var prossimo: String = GameManager.prossimo_sfidante()
	for n in get_tree().get_nodes_in_group("tavoli_scopa"):
		if not is_instance_valid(n) or not (n is Node3D):
			continue
		var sid: String = str(n.get("sfidante_id"))
		var v := _p(t, (n as Node3D).global_position.x,
			(n as Node3D).global_position.z)
		var battuto: bool = GameManager.scopa_battuti.has(sid)
		var col := Color(0.48, 0.45, 0.42)
		if sid == prossimo:
			col = Color(0.92, 0.80, 0.24)
		elif battuto:
			col = Color(0.30, 0.66, 0.40)
		_icona("scopa", v, col)
		if sid == prossimo:
			var d: Dictionary = GameManager.sfidante(sid)
			_chiedi(v, str(d.get("nome", "")), 12, col.darkened(0.35), 45,
				"scopa · €%d" % int(d.get("puntata", 5)))


## **'E cummissiune.** Il giallo è dove si ritira, il verde dove si porta.
##
## Item 13 del capo: *quando prendi la missione di fare consegne ti esce
## sulla mappa dove portarlo*. Quella in mano non è un pallino come gli
## altri — è il fine della carta, e ce l'ha scritto quanto manca.
func _disegna_cummissiune(t: Dictionary, ob: Dictionary) -> void:
	for c in GameManager.commissioni:
		var stato: String = str(c["stato"])
		if stato == "fatta" or stato == "persa":
			continue
		var ritiro: bool = stato == "aperta"
		var pos: Vector3 = Vector3(c["da"]) if ritiro else Vector3(c["a"])
		var v := _p(t, pos.x, pos.z)
		var col := C_RITIRO if ritiro else C_CONSEGNA
		if not ritiro:
			_alone(v, col)
		_icona("ritiro" if ritiro else "consegna", v, col, 1.0 if ritiro else 1.25)
		if ritiro:
			_chiedi(v, "€%d" % int(c["paga"]), 12, col.darkened(0.45), 40,
				str(c["nome_a"]) if c.has("nome_a") else "")
		else:
			_chiedi(v, "CCÀ ▸ €%d" % int(c["paga"]), 13, col.darkened(0.45), 100,
				_quanto_manca(pos))

	# **'O pacco d''a bacheca.** Stesso rombo della consegna, colore suo:
	# e' la stessa azione (portare una cosa in un posto) con un rischio in
	# piu', e la mappa lo deve dire senza spiegarlo.
	var l: Dictionary = GameManager.lavoretto_in_corso()
	if not l.is_empty() and str(l["tipo"]) == "pacco":
		var pv: Vector3 = Vector3(l["a"])
		var vv := _p(t, pv.x, pv.z)
		_alone(vv, C_PACCO)
		_icona("consegna", vv, C_PACCO, 1.25)
		_chiedi(vv, "'O PACCO ▸ €%d" % int(l["paga"]), 13,
			C_PACCO.darkened(0.4), 110, _quanto_manca(pv))


## **'E guagliuni.**
##
## Ce n'è uno per piazza. Grigio = sta là col cartello e aspetta che
## qualcuno lo assuma; giallo = fatica per te e non ha ancora incassato;
## verde con la cifra = tiene 'e sorde in mano e ti conviene passare.
##
## È proprio per questo che stanno sulla carta: il giro serale a ritirare
## si progetta guardandola, non girando a caso. Ma la didascalia ce l'ha
## solo quello che ha qualcosa da darti — gli altri sono un segno e basta.
func _disegna_guagliuni(t: Dictionary) -> void:
	for g in get_tree().get_nodes_in_group("guagliuni"):
		if not is_instance_valid(g) or not (g is Node3D):
			continue
		var zid: String = str(g.get("zona_id"))
		var v := _p(t, (g as Node3D).global_position.x,
			(g as Node3D).global_position.z)
		var assunto: bool = GameManager.ha_dipendente(zid)
		var cassa: int = int(GameManager.dipendente(zid).get("cassa", 0))
		var col := Color(0.52, 0.50, 0.48)
		if assunto:
			col = Color(0.20, 0.68, 0.30) if cassa > 0 else Color(0.88, 0.70, 0.20)
		_icona("guaglione", v, col)
		if assunto and cassa > 0:
			_chiedi(v, "€%d 'a piglià" % cassa, 12, col.darkened(0.4), 60,
				str(GameManager.dipendente(zid).get("nome", "")))


## I nomi delle strade lunghe. Sono quattro e bastano: sono quelle che si
## percorrono, le traverse si attraversano e basta.
func _disegna_strade(t: Dictionary) -> void:
	var nomi := [
		[26.0, 63.5, "'o Decumano"],
		[26.0, 76.0, "Spaccanapoli"],
		[26.0, 95.5, "Via Marina"],
		[92.0, 116.0, "'O Corso"],
	]
	for n in nomi:
		var v := _p(t, float(n[0]), float(n[1]))
		_chiedi(v, str(n[2]), 11, Color(0.38, 0.29, 0.19), 15, "", true)


func _disegna_quartieri(t: Dictionary) -> void:
	for k in Quartieri.ORDINE:
		var q: Dictionary = Quartieri.QUARTIERI[k]
		var r: Array = q["rect"]
		if r.is_empty():
			continue
		# Il nome va in alto nel rettangolo, non al centro: al centro ci
		# finiscono le zone, i vecchi, i guagliuni. In alto c'è sempre posto.
		var c := _p(t, (float(r[0]) + float(r[2])) / 2.0,
			float(r[1]) + minf(9.0, (float(r[3]) - float(r[1])) * 0.14))
		_chiedi(c, str(q["nome"]).to_upper(), 12,
			Color(0.30, 0.24, 0.17, 0.95), 76, "", true)


## Tu: un triangolo che punta dove stai guardando, con l'alone bianco
## sotto perché è il segno che si cerca per primo ogni volta.
func _disegna_player(t: Dictionary) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var v := _p(t, _player.global_position.x, _player.global_position.z)
	# forward(θ) = (−sinθ, 0, −cosθ). Sulla carta la z va in giù, quindi la
	# direzione in pixel è (−sinθ, −cosθ) — la stessa, senza specchiature.
	var a: float = _player.rotation.y
	var dir := Vector2(-sin(a), -cos(a))
	var lato := Vector2(-dir.y, dir.x)

	# Il cono di vista: fa capire da che parte sei girato meglio della punta.
	var cono := PackedVector2Array([v,
		v + (dir * 1.0 + lato * 0.45).normalized() * 34.0,
		v + (dir * 1.0 - lato * 0.45).normalized() * 34.0])
	draw_colored_polygon(cono, Color(C_TU.r, C_TU.g, C_TU.b, 0.20))

	draw_circle(v, 11.0, Color(1, 1, 1, 0.85))
	var pt := PackedVector2Array([
		v + dir * 11.0, v - dir * 6.5 + lato * 7.0, v - dir * 6.5 - lato * 7.0])
	draw_colored_polygon(pt, C_TU)
	draw_polyline(PackedVector2Array([pt[0], pt[1], pt[2], pt[0]]),
		Color(1, 1, 1), 2.0)
	_segni_presi.append(Rect2(v - Vector2(13, 13), Vector2(26, 26)))


## Il filo fra te e il fine: tratteggiato, del colore del fine. Serve
## quando l'obiettivo sta dall'altra parte della città e in mezzo ci sono
## venti segni: il filo dice *quello lì*, senza doverlo leggere.
func _disegna_filo(t: Dictionary, ob: Dictionary) -> void:
	if ob.is_empty() or _player == null or not is_instance_valid(_player):
		return
	# Il furto senza macchina non ha una destinazione: il filo punterebbe
	# all'angolo della carta, che e' peggio di nessun filo.
	if str(ob.get("tipo", "")) == "cerca":
		return
	var a := _p(t, _player.global_position.x, _player.global_position.z)
	var p: Vector3 = ob["p"]
	var b := _p(t, p.x, p.z)
	if a.distance_to(b) < 26.0:
		return
	var col: Color = ob["col"]
	var d := (b - a).normalized()
	draw_dashed_line(a + d * 13.0, b - d * 10.0,
		Color(col.r, col.g, col.b, 0.75), 2.0, 7.0)


# ===========================================================================
# 'O FINE — l'unica cosa che comanda sulla carta
# ===========================================================================


## Che cosa devo fare *adesso*. Uno solo: se ce ne fossero due non
## sarebbe un fine, sarebbe un elenco.
##
## L'ordine è quello della fretta: la roba che tengo in mano scade, la
## giornata è già scaduta, e tutto il resto può aspettare.
func _obiettivo() -> Dictionary:
	# **'O lavoretto d''a bacheca vene primma 'e tutte cose.** Un pacco che
	# scotta e una macchina rubata sono le due sole cose del gioco che
	# possono finire male da sole, mentre cammini: hanno la precedenza su
	# una commissione e pure sull'ora di rientro.
	var l: Dictionary = GameManager.lavoretto_in_corso()
	if not l.is_empty():
		if str(l["tipo"]) == "pacco":
			var resta: int = int(maxf(0.0, float(l.get("scade", 0.0))))
			return {
				"tipo": "pacco", "p": Vector3(l["a"]), "col": C_PACCO,
				"titolo": "Porta 'o pacco",
				"dove": str(l["nome_a"]),
				"nota": "€%d · resta %d:%02d · statte accuorto ê divise" % [
					int(l["paga"]), resta / 60, resta % 60],
			}
		if bool(l.get("presa", false)):
			var g := _garage_cchiu_vicino()
			if g != Vector3.INF:
				return {
					"tipo": "garage", "p": g, "col": C_GARAGE,
					"titolo": "Portala ô garage",
					"dove": "'o garage cchiù vicino",
					"nota": "€%d appena trase dinto" % int(l["paga"]),
				}
		else:
			# Il furto non ha una destinazione finché non hai la macchina:
			# la mappa dice **che cosa cercare**, non dove andare, perché
			# quella macchina può arrivare in qualunque piazza.
			return {
				"tipo": "cerca", "p": Vector3.ZERO, "col": C_GARAGE,
				"titolo": "Cerca %s" % str(l["nome"]),
				"dove": "", "nota": "Posteggiala, aspetta ca 'o padrone se ne va, e sagliece ncoppa.",
			}
	var c: Dictionary = GameManager.commissione_in_mano()
	if not c.is_empty():
		# Il tempo che resta è la cosa che decide se ci provi o se lasci
		# perdere, quindi sta nel riquadro insieme alla paga.
		var resta: int = int(maxf(0.0, float(c.get("scade", 0.0))))
		return {
			"tipo": "consegna", "p": Vector3(c["a"]), "col": C_CONSEGNA,
			"titolo": "Porta '%s'" % str(c["nome"]),
			"dove": str(c["nome_a"]) if c.has("nome_a") else "",
			"nota": "€%d · resta %d:%02d" % [int(c["paga"]), resta / 60,
				resta % 60],
		}
	if GameManager.giornata_scaduta:
		var vascio := get_tree().get_first_node_in_group("vascio")
		if vascio != null:
			return {
				"tipo": "casa", "p": Vector3(vascio.PORTA_POS), "col": C_URGENTE,
				"titolo": "So' 'e quatto: vattenne 'a casa",
				"dove": "'o vascio",
				"nota": "'a mugliera t'aspetta",
			}
	return {}


## Il garage più vicino a te. `Vector3.INF` se non ce n'è nessuno costruito
## (non dovrebbe capitare — ce n'è uno per piazza — ma la mappa non deve
## morire per questo).
func _garage_cchiu_vicino() -> Vector3:
	if _player == null or not is_instance_valid(_player):
		return Vector3.INF
	var meglio := Vector3.INF
	var d_min: float = 1e9
	for g in get_tree().get_nodes_in_group("garage"):
		if not (g is Node3D):
			continue
		var p: Vector3 = (g as Node3D).global_position
		var d: float = _player.global_position.distance_to(p)
		if d < d_min:
			d_min = d
			meglio = p
	return meglio


func _quanto_manca(p: Vector3) -> String:
	if _player == null or not is_instance_valid(_player):
		return ""
	var d: float = Vector2(_player.global_position.x - p.x,
		_player.global_position.z - p.z).length()
	return "%d metri" % int(round(d))


## Il cerchio che pulsa sotto al fine.
func _alone(v: Vector2, col: Color) -> void:
	var f: float = fmod(_tempo, 1.6) / 1.6
	var r: float = 11.0 + f * 17.0
	draw_arc(v, r, 0.0, TAU, 28, Color(col.r, col.g, col.b, (1.0 - f) * 0.85), 2.5)
	draw_circle(v, 13.0, Color(col.r, col.g, col.b, 0.22))


# ===========================================================================
# 'E SEGNE — una sagoma per ogni cosa
# ===========================================================================


## Disegna il segno di `tipo` in `v`. È la stessa funzione che disegna la
## legenda nel pannello: se domani cambio la forma della casa, cambia in
## tutt'e due i posti, e non possono mentirsi a vicenda.
func _icona(tipo: String, v: Vector2, col: Color, scala: float = 1.0) -> void:
	var s: float = scala
	var nero := Color(0.10, 0.09, 0.07)
	match tipo:
		"casa":
			# Una casetta: muro e tetto a capanna.
			var b := Rect2(v - Vector2(4.6, -0.4) * s, Vector2(9.2, 6.6) * s)
			draw_rect(b.grow(1.4 * s), nero)
			draw_rect(b, col)
			var tetto := PackedVector2Array([
				v + Vector2(-6.6, 0.6) * s, v + Vector2(0, -6.4) * s,
				v + Vector2(6.6, 0.6) * s])
			draw_colored_polygon(tetto, nero)
			draw_colored_polygon(PackedVector2Array([
				v + Vector2(-5.0, 0.2) * s, v + Vector2(0, -5.0) * s,
				v + Vector2(5.0, 0.2) * s]), col)
		"scopa":
			# Una carta da gioco: rettangolino in piedi.
			var r := Rect2(v - Vector2(3.4, 4.6) * s, Vector2(6.8, 9.2) * s)
			draw_rect(r.grow(1.4 * s), nero)
			draw_rect(r, col)
			draw_rect(Rect2(v - Vector2(1.2, 1.2) * s, Vector2(2.4, 2.4) * s),
				nero)
		"guaglione":
			# Uno che sta in piedi: testa e spalle.
			draw_circle(v + Vector2(0, -3.2) * s, 3.4 * s, nero)
			draw_circle(v + Vector2(0, -3.2) * s, 2.2 * s, col)
			var sp := PackedVector2Array([
				v + Vector2(-4.4, 5.2) * s, v + Vector2(-3.0, -0.4) * s,
				v + Vector2(3.0, -0.4) * s, v + Vector2(4.4, 5.2) * s])
			draw_colored_polygon(sp, nero)
			draw_colored_polygon(PackedVector2Array([
				v + Vector2(-3.2, 4.4) * s, v + Vector2(-2.0, 0.4) * s,
				v + Vector2(2.0, 0.4) * s, v + Vector2(3.2, 4.4) * s]), col)
		"ritiro":
			# Un rombo: si piglia.
			_rombo(v, 6.6 * s, nero)
			_rombo(v, 4.4 * s, col)
		"consegna":
			# Un rombo con la crocetta dentro: si porta.
			_rombo(v, 7.4 * s, nero)
			_rombo(v, 5.4 * s, col)
			draw_line(v + Vector2(-2.2, 0) * s, v + Vector2(2.2, 0) * s, nero, 1.6)
			draw_line(v + Vector2(0, -2.2) * s, v + Vector2(0, 2.2) * s, nero, 1.6)
		"posto":
			draw_circle(v, 4.6 * s, nero)
			draw_circle(v, 2.4 * s, col)
		"bacheca":
			# Un pannello su due gambe.
			var b := Rect2(v - Vector2(5.0, 5.4) * s, Vector2(10.0, 7.2) * s)
			draw_rect(b.grow(1.4 * s), nero)
			draw_rect(b, col)
			draw_line(v + Vector2(-3.2, 1.8) * s, v + Vector2(-3.2, 5.4) * s,
				nero, 1.8 * s)
			draw_line(v + Vector2(3.2, 1.8) * s, v + Vector2(3.2, 5.4) * s,
				nero, 1.8 * s)
		"garage":
			# 'A saracinesca: un quadrato con le righe.
			var q2 := Rect2(v - Vector2(5.2, 4.6) * s, Vector2(10.4, 9.2) * s)
			draw_rect(q2.grow(1.4 * s), nero)
			draw_rect(q2, col)
			for k in range(3):
				draw_line(v + Vector2(-4.2, -2.2 + float(k) * 2.2) * s,
					v + Vector2(4.2, -2.2 + float(k) * 2.2) * s, nero, 1.2 * s)
		"zona_mia", "zona_altrui":
			var q := Rect2(v - Vector2(6, 5) * s, Vector2(12, 10) * s)
			draw_rect(q, Color(col.r, col.g, col.b, 0.30))
			draw_rect(q, col, false, 2.0)
		"tu":
			draw_circle(v, 7.0 * s, Color(1, 1, 1, 0.85))
			draw_colored_polygon(PackedVector2Array([
				v + Vector2(0, -7) * s, v + Vector2(-4.6, 4.4) * s,
				v + Vector2(4.6, 4.4) * s]), C_TU)
	# Il segno si prende il posto suo: nessuna scritta ci finisce sopra.
	_segni_presi.append(Rect2(v - Vector2(9, 9) * s, Vector2(18, 18) * s))


func _rombo(v: Vector2, r: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		v + Vector2(0, -r), v + Vector2(r, 0),
		v + Vector2(0, r), v + Vector2(-r, 0)]), col)


# ===========================================================================
# 'E SCRITTE — chieste prima, sistemate dopo
# ===========================================================================


## Chiede posto per un'etichetta vicino a `v`.
##
## `pri` è quanto conta: chi ha il numero più alto sceglie per primo, e chi
## non trova posto **non si disegna**. È tutta qui la differenza con la
## mappa di prima, che le stampava tutte dove capitava.
func _chiedi(v: Vector2, testo: String, misura: int, col: Color, pri: int,
		sotto: String = "", centrata: bool = false) -> void:
	if testo.is_empty():
		return
	_etichette.append({"v": v, "t": testo, "m": misura, "c": col, "pri": pri,
		"s": sotto, "cen": centrata})


func _piazza_etichette(carta: Rect2) -> void:
	_etichette.sort_custom(func(a, b) -> bool:
		return int(a["pri"]) > int(b["pri"]))
	for e in _etichette:
		var testo: String = str(e["t"])
		var sotto: String = str(e["s"])
		var m: int = int(e["m"])
		var w: float = _font.get_string_size(testo, HORIZONTAL_ALIGNMENT_LEFT,
			-1, m).x
		if not sotto.is_empty():
			w = maxf(w, _font.get_string_size(sotto, HORIZONTAL_ALIGNMENT_LEFT,
				-1, m - 2).x)
		var h: float = float(m) + 4.0 + (float(m) + 1.0 if not sotto.is_empty()
			else 0.0)
		var v: Vector2 = e["v"]
		var candidati: Array = []
		if bool(e["cen"]):
			candidati = [
				Vector2(-w / 2.0, -h / 2.0),
				Vector2(-w / 2.0, -h - 12.0),
				Vector2(-w / 2.0, 12.0),
				Vector2(12.0, -h / 2.0),
			]
		else:
			# Prima i quattro lati, poi i quattro angoli. Gli angoli servono
			# nei posti affollati: senza, l'etichetta di Ciccio — che sta
			# sul bordo della piazza — si allontanava fino a finire dentro
			# al mare, e una scritta in mezzo all'acqua non si capisce a
			# quale segno appartenga.
			candidati = [
				Vector2(13.0, -h / 2.0),
				Vector2(-w - 13.0, -h / 2.0),
				Vector2(-w / 2.0, 13.0),
				Vector2(-w / 2.0, -h - 13.0),
				Vector2(10.0, 10.0),
				Vector2(-w - 10.0, 10.0),
				Vector2(10.0, -h - 10.0),
				Vector2(-w - 10.0, -h - 10.0),
			]
		var box := Rect2()
		var trovato: bool = false
		for c in candidati:
			var r := Rect2(v + (c as Vector2) - Vector2(4, 3),
				Vector2(w + 8, h + 6))
			if not carta.encloses(r):
				continue
			var libero: bool = true
			for q in _presi:
				if q.intersects(r):
					libero = false
					break
			if not libero:
				continue
			for p in _segni_presi:
				# **Il segno mio non mi da' fastidio.**
				#
				# Alla prima foto non usciva nemmeno una didascalia dei
				# segni — non 'A casa, non i guagliuni, non i vecchi — e
				# uscivano solo i nomi di zone e quartieri, che un segno
				# non ce l'hanno. Il motivo: `_icona` si prenota il posto
				# suo, e le quattro posizioni intorno all'ancora cadevano
				# tutt'e quattro dentro a quella prenotazione. Cioe' ogni
				# etichetta si bocciava da sola. Il rettangolo che contiene
				# l'ancora e' per definizione il segno di questa etichetta:
				# si salta.
				if p.has_point(v):
					continue
				if p.intersects(r):
					libero = false
					break
			if libero:
				box = r
				trovato = true
				break
		if not trovato:
			continue
		_presi.append(box)
		# La targhetta chiara sotto: senza, il nome sopra a un isolato
		# scuro non si legge, e con l'ombra sola si legge male.
		draw_rect(box, Color(0.995, 0.985, 0.945, 0.90))
		draw_rect(box, Color(0.30, 0.24, 0.18, 0.35), false, 1.0)
		var col: Color = e["c"]
		draw_string(_font, box.position + Vector2(4, float(m) + 1.0), testo,
			HORIZONTAL_ALIGNMENT_LEFT, -1, m, col)
		if not sotto.is_empty():
			draw_string(_font, box.position + Vector2(4, float(m) * 2.0 + 2.0),
				sotto, HORIZONTAL_ALIGNMENT_LEFT, -1, m - 2,
				Color(col.r, col.g, col.b, 0.78))


func _scritta(dove: Vector2, testo: String, misura: int, col: Color) -> void:
	draw_string(_font, dove + Vector2(1, 1), testo,
		HORIZONTAL_ALIGNMENT_LEFT, -1, misura, Color(0, 0, 0, 0.35))
	draw_string(_font, dove, testo, HORIZONTAL_ALIGNMENT_LEFT, -1, misura, col)


# ===========================================================================
# 'A TESTATA E 'O PANNELLO
# ===========================================================================


func _disegna_testate(t: Dictionary) -> void:
	var sc := _schermo()
	_scritta(Vector2(MARGINE, MARGINE + 10.0), "'A CHIANTINA 'E NAPULE", 21,
		Color(0.96, 0.93, 0.84))
	var chiudi_t := "[M] o [ESC] pe' chiudere"
	var l := _font.get_string_size(chiudi_t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	_scritta(Vector2(sc.x - MARGINE - l.x, sc.y - MARGINE + 4.0), chiudi_t, 13,
		Color(0.72, 0.70, 0.66))

	# La rosa dei venti, in un angolo della carta.
	var carta := _carta_rect(t)
	var c := Vector2(carta.end.x - 26.0, carta.position.y + 26.0)
	draw_circle(c, 15.0, Color(0.99, 0.97, 0.92, 0.88))
	draw_arc(c, 15.0, 0.0, TAU, 24, C_BORDO, 1.5)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(0, -11), c + Vector2(-4.5, 2), c + Vector2(4.5, 2)]),
		Color(0.70, 0.22, 0.18))
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(0, 11), c + Vector2(-4.5, 2), c + Vector2(4.5, 2)]),
		Color(0.30, 0.26, 0.22))
	_scritta(c + Vector2(-3.5, -13.0), "N", 10, C_INK)

	# La scala: quanti metri è quel pezzetto di riga.
	var s: float = float(t["s"])
	var metri: float = 50.0
	var lung: float = metri * s
	var base := Vector2(carta.position.x + 12.0, carta.end.y - 14.0)
	draw_line(base, base + Vector2(lung, 0), C_INK, 2.0)
	draw_line(base + Vector2(0, -4), base + Vector2(0, 4), C_INK, 2.0)
	draw_line(base + Vector2(lung, -4), base + Vector2(lung, 4), C_INK, 2.0)
	_scritta(base + Vector2(lung + 6.0, 4.0), "50 m", 11, C_INK)


func _disegna_pannello(ob: Dictionary) -> void:
	var sc := _schermo()
	var w: float = _larghezza_pannello()
	var r := Rect2(Vector2(sc.x - MARGINE - w, MARGINE + 34.0),
		Vector2(w, sc.y - MARGINE * 2.0 - 40.0))
	draw_rect(r, Color(0.10, 0.09, 0.11, 0.92))
	draw_rect(r, Color(0.52, 0.44, 0.32, 0.7), false, 1.5)

	var y: float = r.position.y + 22.0
	var x: float = r.position.x + 14.0
	var largo: float = w - 28.0

	# --- 'O fine. Il riquadro grosso: è la ragione per cui uno ha aperto
	# la mappa nove volte su dieci.
	if ob.is_empty():
		_scritta(Vector2(x, y), "NIENTE 'E URGENTE", 13,
			Color(0.62, 0.60, 0.56))
		y += 20.0
		_scritta(Vector2(x, y), "Faje chello ca vuo'.", 12,
			Color(0.52, 0.50, 0.47))
		y += 26.0
	else:
		var col: Color = ob["col"]
		var box := Rect2(Vector2(x - 6, y - 16), Vector2(largo + 12, 76))
		draw_rect(box, Color(col.r, col.g, col.b, 0.16))
		draw_rect(box, col, false, 1.5)
		_scritta(Vector2(x, y), "MO' T'HÊ 'A MOVERE", 11,
			Color(col.r, col.g, col.b, 0.85))
		y += 20.0
		for riga in _spezza(str(ob["titolo"]), largo, 14):
			_scritta(Vector2(x, y), riga, 14, Color(0.97, 0.95, 0.90))
			y += 17.0
		var dove: String = str(ob.get("dove", ""))
		if not dove.is_empty():
			_scritta(Vector2(x, y), "▸ %s · %s" % [dove, _quanto_manca(ob["p"])],
				12, col)
			y += 16.0
		_scritta(Vector2(x, y), str(ob.get("nota", "")), 11,
			Color(0.72, 0.70, 0.66))
		y += 30.0

	# --- 'E piazze: prezzi e padroni, che prima stavano stampati sopra ai
	# vicoli e coprivano mezza carta.
	_titolo_pannello(x, y, largo, "'E PIAZZE")
	y += 22.0
	for z in _citta.ZONE:
		var mia: bool = GameManager.zona_mia(str(z["id"]))
		var col2 := C_MIA if mia else C_ALTRUI
		_icona("zona_mia" if mia else "zona_altrui", Vector2(x + 7, y - 4), col2,
			0.62)
		_scritta(Vector2(x + 20, y), str(z["nome"]), 12,
			Color(0.92, 0.90, 0.86))
		y += 14.0
		var d: String = "'a toia" if mia else "'e %s · €%d + €%d 'o juorno" % [
			str(z["padrone"]), GameManager.prezzo_zona(),
			GameManager.affitto_zona()]
		_scritta(Vector2(x + 20, y), d, 11, Color(col2.r, col2.g, col2.b, 0.9))
		y += 19.0
	y += 8.0

	# --- 'A leggenda. Le sagome, disegnate dalla stessa funzione che le
	# disegna sulla carta.
	_titolo_pannello(x, y, largo, "CHE VONNO DÌ 'E SEGNE")
	y += 24.0
	var voci := [
		["tu", C_TU, "Tu"],
		["casa", C_CASA, "'O vascio tuoio"],
		["consegna", C_CONSEGNA, "Porta ccà 'a rrobba"],
		["ritiro", C_RITIRO, "Piglia 'na cummissione"],
		["guaglione", Color(0.20, 0.68, 0.30), "Guaglione: tene 'e sorde"],
		["guaglione", Color(0.52, 0.50, 0.48), "Guaglione: cerca fatica"],
		["scopa", Color(0.92, 0.80, 0.24), "'O viecchio ca t'aspetta"],
		["posto", Color(0.98, 0.86, 0.34), "Nu posto ca se canosce"],
		["bacheca", C_BACHECA, "'A bacheca d''e llavore"],
		["garage", C_GARAGE, "'O garage"],
	]
	for voce in voci:
		if y > r.end.y - 26.0:
			break
		_icona(str(voce[0]), Vector2(x + 8, y - 4), voce[1], 0.72)
		_scritta(Vector2(x + 22, y), str(voce[2]), 11,
			Color(0.84, 0.82, 0.78))
		y += 18.0


func _titolo_pannello(x: float, y: float, largo: float, testo: String) -> void:
	_scritta(Vector2(x, y), testo, 11, Color(0.86, 0.72, 0.40))
	var l := _font.get_string_size(testo, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
	draw_line(Vector2(x + l.x + 8.0, y - 4.0), Vector2(x + largo, y - 4.0),
		Color(0.50, 0.42, 0.30, 0.8), 1.0)


## Spezza una riga che non ci sta nel pannello. Senza, i nomi lunghi delle
## commissioni uscivano dal riquadro e finivano sulla carta.
func _spezza(testo: String, largo: float, misura: int) -> Array:
	var fuori: Array = []
	var riga: String = ""
	for parola in testo.split(" "):
		var prova: String = parola if riga.is_empty() else riga + " " + parola
		if _font.get_string_size(prova, HORIZONTAL_ALIGNMENT_LEFT, -1,
				misura).x > largo and not riga.is_empty():
			fuori.append(riga)
			riga = parola
		else:
			riga = prova
	if not riga.is_empty():
		fuori.append(riga)
	return fuori
