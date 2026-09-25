extends Node
## **Fote d''a 0.56: chello ca 'e prove nun ponno vedé.**
##
## Le prove di questa versione misurano tutto quello che è un numero — i
## secondi del vigile, la percentuale dei tiri in porta, i giorni di
## rientro di ogni oggetto del bazar. Nessuna di quelle risponde alla
## domanda che resta: **se vede?**
##
## Tre cose nuove hanno una faccia, e una faccia o è giusta o non lo è:
##
##  1. **Don Gaetano**, che è un personaggio nuovo e sta appoggiato al muro
##     accanto alla bacheca. Un vecchio con la coppola sulla nuca invece
##     che in fronte è esattamente l'errore che questo progetto ha già
##     fatto tre volte (la visiera del vigile, la 0.51: `+Z` sta davanti
##     per i nodi e dietro per chi guarda).
##  2. **'O campetto d''e guagliune**, che adesso ha una porta sola disegnata
##     col gesso e un Super Santos vero che rimbalza.
##  3. **'A barra d''o sciato e 'a versione 'n basso a destra**, che sono le
##     due cose dell'interfaccia che il capo ha chiesto per nome.

var _t := 0.0
var _n := 0
var _pulito := false
var _cam: Camera3D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(d: float) -> void:
	if not _pulito:
		_pulito = true
		get_tree().paused = false
		GameManager.giornata = 2
		GameManager.start_shift()
		# Mezzogiorno pieno e cielo sereno: qui si guardano le cose, non
		# l'ora. (Una foto uscita di notte non dice niente su una coppola.)
		GameManager.tipo_giornata = "normale"
		# **`shift_time_left` è chello ca RESTA**, no chello ca è passato: a
		# 0,18 la prima serie di foto è uscita all'una di notte, con Don
		# Gaetano nero su fondo nero. A 0,88 sono le due del pomeriggio.
		GameManager.shift_time_left = GameManager.shift_duration * 0.88
		_cam = Camera3D.new()
		add_child(_cam)
		_cam.current = true
		return

	_t += d
	if _t < 0.8:
		return
	_t = 0.0
	_n += 1
	match _n:
		1: _guarda("maestro")
		2: await _scatta("maestro", true)
		3: _guarda("maestro_faccia")
		4: await _scatta("maestro_faccia", true)
		5: _guarda("campetto")
		6: await _scatta("campetto", true)
		7: _guarda("campetto_alto")
		8: await _scatta("campetto_alto", true)
		9: _guarda("piazza")
		10: await _scatta("hud", false)   # ccà ll'interfaccia resta
		11: _sciato_a_meta()
		12: await _scatta("hud_sciato", false)
		_: get_tree().quit()


func _guarda(che: String) -> void:
	var don := get_tree().get_first_node_in_group("maestro")
	var campi: Array = get_tree().get_nodes_in_group("bambini")
	match che:
		"maestro":
			if don == null:
				print("  NUN CE STA DON GAETANO")
				return
			var p: Vector3 = (don as Node3D).global_position
			_mira(p + Vector3(-4.2, 1.9, 1.6), p + Vector3(0, 1.0, 0))
		"maestro_faccia":
			if don == null:
				return
			var p2: Vector3 = (don as Node3D).global_position
			# Da davanti e ad altezza d'occhi: è l'unica inquadratura in
			# cui si vede se la coppola sta in fronte o sulla nuca.
			_mira(p2 + Vector3(-1.45, 1.30, 0.1), p2 + Vector3(0, 1.24, 0))
		"campetto":
			if campi.is_empty():
				print("  NUN CE STANNO CAMPETTE")
				return
			var c: Vector3 = _largo(campi)
			_mira(c + Vector3(-7.0, 3.0, 7.0), c + Vector3(4.0, 0.5, 0))
		"campetto_alto":
			if campi.is_empty():
				return
			var c2: Vector3 = _largo(campi)
			_mira(c2 + Vector3(-6.0, 9.0, 0.0), c2 + Vector3(4.0, 0, 0))
		"piazza":
			_mira(Vector3(31.0, 2.4, 40.0), Vector3(31.0, 1.3, 18.0))


## **'O campetto d''o largo**, non quello della piazza. Sono tutti e due
## veri, ma quello della piazza sta in mezzo alle strisce e ai coni: in
## fotografia si vede il vigile e non si vede la porta. Quello del largo
## d''e guagliune — che dalla 0.56 sta finalmente **dentro** al largo e non
## un metro fuori, dentro al palazzo — è uno spiazzo aperto, ed è lì che si
## capisce cos'è.
## **'A barra d''o sciato se vede sulo quanno nun è chiena.** A cento su
## cento è una striscia piena come tutte le altre; a quaranta si capisce
## che cos'è e che sta scendendo — e questa versione l'ha aggiunta apposta.
func _sciato_a_meta() -> void:
	GameManager.sciato = GameManager.SCIATO_MAX * 0.38
	GameManager.sciato_cambiato.emit(GameManager.sciato)
	GameManager.add_heat(34.0)


func _largo(campi: Array) -> Vector3:
	var meglio: Vector3 = (campi[0] as Node3D).global_position
	for c in campi:
		if (c as Node3D).global_position.z > meglio.z:
			meglio = (c as Node3D).global_position
	return meglio


func _mira(occhio: Vector3, mira: Vector3) -> void:
	_cam.global_position = occhio
	_cam.look_at_from_position(occhio, mira, Vector3.UP)
	_cam.current = true


## **'A schermata 'e caricamento resta spenta 'e sempe.**
##
## Riaccendendo tutti i `CanvasLayer` per fotografare l'interfaccia si
## riaccendeva pure lei, ed essendo davanti a tutto la foto usciva con la
## copertina del gioco invece che con la barra del fiato. Si riconosce da
## sola: è l'unica che tiene la costante `VERSIONE` scritta dentro.
func _spegni(n: Node, quanto: bool) -> void:
	if n is CanvasLayer:
		var carta: bool = (n as Object).get_script() != null \
			and str((n as Object).get_script().resource_path).ends_with(
				"caricamento.gd")
		(n as CanvasLayer).visible = quanto and not carta
	for c in n.get_children():
		_spegni(c, quanto)


func _scatta(nome: String, senza_hud: bool) -> void:
	for n in get_tree().root.get_children():
		if n != self:
			_spegni(n, not senza_hud)
	_cam.current = true
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/56_%s.png" % nome)
	print("  foto: /tmp/56_%s.png" % nome)
