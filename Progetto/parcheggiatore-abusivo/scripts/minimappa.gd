extends "res://scripts/mappa.gd"
## **'A chiantina piccerella** (0.62): la minimappa in basso a destra.
##
## Il capo: *«puoi migliorare la mappa in game»*. La chiantina grande (tasto
## M) resta com'è — è quella che si apre per decidere dove andare. Questa è
## quella che si guarda **mentre si cammina**: un quadrato di centonovanta
## pixel con la città attorno a te per una cinquantina di metri, il nord in
## alto, e i segni che servono adesso — la casa, il fine (consegna, pacco,
## garage), i clienti che aspettano, e le divise che girano.
##
## È figlia di `mappa.gd`: stessa carta, stessi colori, stesse sagome. Cambia
## solo il telaio (centrato su di te e ingrandito) e cosa si disegna: niente
## scritte (a questa misura sarebbero sporco) e niente pannello.

const UiStileM := preload("res://scripts/ui_stile.gd")

## Pixel per metro. A 2,6 un quadrato di 190 pixel fa settantatré metri:
## la piazza intera e le traverse attorno.
const SCALA: float = 2.6
const LATO: float = 190.0

var _ogni: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	custom_minimum_size = Vector2(LATO, LATO)
	size = Vector2(LATO, LATO)
	_font = UiStileM.font_grassetto()
	visible = true


func aggancia(citta: Node, player: Node3D) -> void:
	_citta = citta
	_player = player


func _process(d: float) -> void:
	_tempo += d
	# Venti ridisegni al secondo bastano: la carta si muove piano.
	_ogni -= d
	if _ogni <= 0.0:
		_ogni = 0.05
		queue_redraw()


func _telaio() -> Dictionary:
	var w: float = 190.0
	var l: float = 172.0
	var nord: float = -22.0
	if _citta != null:
		w = _citta.LARGHEZZA
		l = _citta.PROFONDITA
		nord = _citta.LIMITE_NORD - 3.0
	var c := size * 0.5
	var px: float = 0.0
	var pz: float = 0.0
	if _player != null and is_instance_valid(_player):
		px = _player.global_position.x
		pz = _player.global_position.z
	var org := c - Vector2(px, pz - nord) * SCALA
	return {"s": SCALA, "org": org, "nord": nord, "w": w, "l": l}


func _draw() -> void:
	if _citta == null or _player == null or not is_instance_valid(_player):
		return
	# Dentro al vascio (che sta fuori dalla città) la carta non ha senso.
	if GameManager.dentro_casa:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.07, 0.06, 0.9))
		_scritta(Vector2(size.x * 0.5 - 38.0, size.y * 0.5 + 5.0),
			"'o vascio", 14, Color(0.95, 0.85, 0.66))
		return
	_etichette.clear()
	_presi.clear()
	_segni_presi.clear()
	var t := _telaio()
	draw_rect(Rect2(Vector2.ZERO, size), C_MARE)
	_disegna_fondo(t)
	_disegna_zone_mute(t)
	var ob := _obiettivo()
	_disegna_servizi(t)
	_disegna_guagliuni(t)
	_disegna_viecchie(t)
	_disegna_cummissiune(t, ob)
	_disegna_casa(t, ob)
	_disegna_clienti(t)
	_disegna_divise(t)
	_disegna_filo(t, ob)
	_bussola_bordo(t, ob)
	_disegna_player(t)
	# La N in alto: la carta non gira, lo dice lei.
	draw_circle(Vector2(size.x - 14.0, 14.0), 10.0, Color(0.06, 0.06, 0.08, 0.8))
	_scritta(Vector2(size.x - 18.5, 19.0), "N", 12, UiStileM.ORO_CHIARO)


## Le zone senza nomi: solo la campitura e il bordo.
func _disegna_zone_mute(t: Dictionary) -> void:
	for z in _citta.ZONE:
		var mia: bool = GameManager.zona_mia(str(z["id"]))
		var col := C_MIA if mia else C_ALTRUI
		var r := _rett(t, z["rect"])
		draw_rect(r, Color(col.r, col.g, col.b, 0.22))
		draw_rect(r, col, false, 2.0)


## I clienti che aspettano (solo in servizio: fuori non sono tuoi).
func _disegna_clienti(t: Dictionary) -> void:
	if not GameManager.in_servizio:
		return
	for car in get_tree().get_nodes_in_group("cars"):
		if not is_instance_valid(car) or not ("state" in car):
			continue
		if int(car.get("state")) != 1:  # WAITING
			continue
		var p: Vector3 = (car as Node3D).global_position
		var v := _p(t, p.x, p.z)
		var f: float = 0.5 + 0.5 * sin(_tempo * 6.0)
		draw_circle(v, 5.5, Color(0.1, 0.09, 0.07))
		draw_circle(v, 4.0, Color(1.0, 0.86, 0.3).lerp(Color(1, 1, 1), f * 0.4))


## Vigili (blu), carabinieri e sbirri (rosso): chi porta la divisa, entro
## quaranta metri. È la cosa che fa girare la testa nel gioco vero.
func _disegna_divise(t: Dictionary) -> void:
	var io: Vector3 = _player.global_position
	for gruppo in ["vigili", "carabinieri", "sbirri"]:
		var col := Color(0.32, 0.62, 1.0) if gruppo == "vigili" \
			else Color(1.0, 0.3, 0.26)
		for n in get_tree().get_nodes_in_group(gruppo):
			if not is_instance_valid(n) or not (n is Node3D):
				continue
			var p: Vector3 = (n as Node3D).global_position
			if p.distance_to(io) > 40.0:
				continue
			var v := _p(t, p.x, p.z)
			draw_circle(v, 5.0, Color(1, 1, 1, 0.9))
			draw_circle(v, 3.6, col)


## Se il fine (casa, consegna, garage) sta fuori dal quadrato, una freccetta
## sul bordo dice da che parte.
func _bussola_bordo(t: Dictionary, ob: Dictionary) -> void:
	var p: Vector3 = Vector3.INF
	var col := C_CASA
	if not ob.is_empty() and str(ob.get("tipo", "")) != "cerca":
		p = ob["p"]
		col = ob["col"]
	else:
		var vascio := get_tree().get_first_node_in_group("vascio")
		var dovuto: int = GameManager.spese_dovute()
		if vascio != null and (GameManager.giornata_scaduta
				or (dovuto > 0 and GameManager.money >= dovuto)):
			p = Vector3(vascio.PORTA_POS)
	if p == Vector3.INF:
		return
	var v := _p(t, p.x, p.z)
	var r := Rect2(Vector2(10, 10), size - Vector2(20, 20))
	if r.has_point(v):
		return
	var c := size * 0.5
	var d := (v - c).normalized()
	# Il punto sul bordo del quadrato lungo la direzione.
	var k: float = minf(absf((size.x * 0.5 - 12.0) / maxf(absf(d.x), 0.001)),
		absf((size.y * 0.5 - 12.0) / maxf(absf(d.y), 0.001)))
	var q := c + d * k
	var lato := Vector2(-d.y, d.x)
	draw_colored_polygon(PackedVector2Array([q + d * 8.0, q - d * 5.0 + lato * 6.5,
		q - d * 5.0 - lato * 6.5]), Color(0.08, 0.07, 0.06))
	draw_colored_polygon(PackedVector2Array([q + d * 6.0, q - d * 3.6 + lato * 4.6,
		q - d * 3.6 - lato * 4.6]), col)
