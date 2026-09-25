extends Node
## Fote d''a 0.57: 'o pannello d''o scasso, 'o cruscotto, 'o garage.
##
## **Chello ca 'o codice nun po' dicere.** `prova_furto` ha misurato che il
## cursore resta dentro alla finestra centoquaranta millisecondi e che la
## zona buona non finisce mai sotto a una tacca rossa. Sono i numeri giusti
## e non dicono **se si legge**: se il verde e il rosso si distinguono, se il
## cursore si vede mentre corre, se la freccia del garage sta a schermo
## invece che sotto alla barra della vita. Quello lo dice una fotografia e
## niente altro — è la lezione delle tre righe dell'HUD della 0.56, che
## erano stampate una sopra all'altra e nessuna prova se n'era accorta.
##
## **E ll'inquadrature nun se 'nduvinano** (0.57, doppo 'a lezione 'e
## `foto_asset`): la macchina e il garage si **cercano** nella scena, non si
## scrivono a coordinate.

const PannelloScassa := preload("res://scripts/pannello_scassa.gd")
const CarScript := preload("res://scripts/car_3d.gd")

var _t := 0.0
var _n := 0
var _pronto := false
var _pan: CanvasLayer = null
var _hud: CanvasLayer = null
var _cam: Camera3D = null
var _machina: Node3D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(d: float) -> void:
	if not _pronto:
		_pronto = true
		# **Primma 'e tutto s'ha da levà 'a schermata 'e caricamento.**
		# Sta al layer 220, cioè sopra a qualunque pannello: la prima
		# infornata di fotografie è uscita tutta uguale, quattro copie
		# dell'illustrazione del menu, e il pannello del scasso stava
		# regolarmente sotto. Non era la fotografia a sbagliare: era la
		# schermata che nessuno aveva chiuso.
		#
		# **E se stuta, nun se fa clicca'.** Il primo tentativo chiamava
		# `_on_menu_gioca()` — il vero bottone «Accummenciamo» — e il motore
		# saltava per aria con un segnale 11, sia dritto che con
		# `call_deferred`: quella funzione si `queue_free()` addosso e fa
		# partire mezza partita, e farlo dal `_process` di un autoload sotto
		# a xvfb non regge.
		#
		# E soprattutto **non serviva**: la città sta già tutta costruita
		# dietro alla schermata (è per questo che `foto_asset` fotografa i
		# balconi senza aver mai toccato il menu). Bastava spegnere il
		# `CanvasLayer`, che sta al layer 220 e copriva tutto.
		for n in _tutte(get_tree().root):
			if n is CanvasLayer and n.has_method("_on_menu_gioca"):
				(n as CanvasLayer).visible = false
				print("  stutata 'a schermata 'e caricamento")
				break
		get_tree().paused = false
		GameManager.giornata = 3
		GameManager.start_shift()
		GameManager.tipo_giornata = "normale"
		GameManager.intro_active = false
		# Mezzogiorno passato: 0,88 è il valore giusto, 0,18 è l'una di
		# notte e fa uscire quattro fotografie nere ('o sbaglio 'e `foto_asset`).
		GameManager.shift_time_left = GameManager.shift_duration * 0.88
		_hud = _truova_hud()
		return
	_t += d
	if _t < 0.9:
		return
	_t = 0.0
	_n += 1
	match _n:
		# Un giro a vuoto: la partita si sta ancora costruendo.
		1: print("  se aspetta ca 'a città s'apara")
		2: _apre_o_pannello("economica", "'na economica janca")
		3: await _scatta("scasso_facile")
		4:
			_chiude_o_pannello()
			_apre_o_pannello("bmw", "'na bmw nera")
		5: await _scatta("scasso_tosto")
		6:
			_chiude_o_pannello()
			_mette_a_machina()
		7: await _scatta("cruscotto")
		8: _guarda_o_garage()
		9: await _scatta("garage")
		_: get_tree().quit()


# ---------------------------------------------------------------------------
# 'O pannello
# ---------------------------------------------------------------------------

func _apre_o_pannello(tipo: String, nomma: String) -> void:
	var pl := get_tree().get_first_node_in_group("player")
	_pan = PannelloScassa.new()
	get_tree().root.add_child(_pan)
	_pan.apri(tipo, nomma, pl)
	# Si fa correre qualche spilla, se no la fotografia esce sempre col
	# primo pallino e non si vede come sta messa la riga di stato.
	_pan.set("_spillo", 2)
	_pan.set("_errori", 1)
	_pan.set("_ori", 1)
	_pan.call("_aggiorna_scritte")
	print("  pannello apierto: %s" % tipo)


func _chiude_o_pannello() -> void:
	if _pan != null and is_instance_valid(_pan):
		_pan.chiudi(false)
		_pan.queue_free()
	_pan = null


# ---------------------------------------------------------------------------
# 'O cruscotto: 'na machina overo, guidata overo
# ---------------------------------------------------------------------------

func _mette_a_machina() -> void:
	# Si piglia una macchina vera della piazza, o se ne fa una se la piazza
	# non ne ha ancora mandate.
	for c in get_tree().get_nodes_in_group("cars"):
		if c is Node3D:
			_machina = c
			break
	if _machina == null:
		var c: Node = CarScript.new()
		get_tree().root.add_child(c)
		_machina = c as Node3D
		_machina.global_position = Vector3(40.0, 0.0, 70.0)
	_machina.set("state", CarScript.State.PARKED)
	_machina.set("has_multa", false)
	GameManager.auto_guidata = null
	var pl := get_tree().get_first_node_in_group("player")
	if pl != null:
		_machina.call("arrubba", pl)
	# Gli si dà un po' di velocità, se no il tachimetro segna zero e la
	# fotografia non prova niente.
	_machina.set("_drive_speed", 12.0)
	_machina.velocity = Vector3(0.0, 0.0, -12.0)
	print("  ncopp'â machina a %s" % str(_machina.global_position.round()))
	# La camera del gioco è quella del player, che sta seduto dentro: si
	# guarda da fuori e un filo dietro, per vedere insieme la macchina e il
	# cruscotto.
	_cam = Camera3D.new()
	get_tree().root.add_child(_cam)
	var da: Vector3 = _machina.global_position \
		+ _machina.global_transform.basis.z * 7.0 + Vector3(0.0, 3.4, 0.0)
	_cam.look_at_from_position(da, _machina.global_position, Vector3.UP)
	_cam.current = true


func _guarda_o_garage() -> void:
	var g: Node3D = null
	for n in get_tree().get_nodes_in_group("garage"):
		if n is Node3D:
			g = n
			break
	if g == null:
		print("  NUN CE STA 'O GARAGE")
		return
	print("  garage truvato a %s" % str(g.global_position.round()))
	if _machina != null and is_instance_valid(_machina):
		# La si mette davanti alla saracinesca, a otto metri: è la vista che
		# ha chi ci sta arrivando in macchina.
		_machina.global_position = g.global_position + Vector3(0.0, 0.0, 9.0)
	if _cam == null:
		_cam = Camera3D.new()
		get_tree().root.add_child(_cam)
	# **'O posto d''a telecamera se cerca, nun se 'nduveena.** L'avevo
	# scritto in cima a questo file e poi l'ho fatto lo stesso: (−4, 3, 13)
	# a occhio, e la prima fotografia è uscita col muro di un palazzo che
	# riempiva lo schermo. Adesso si prova un giro di punti davanti alla
	# saracinesca e si tiene il primo che non sta dentro a un palazzo — e
	# se domani il garage si sposta un'altra volta, la foto resta giusta.
	var Citta := load("res://scripts/citta_3d.gd")
	var mira: Vector3 = g.global_position + Vector3(0, 1.5, 0)
	var truvato := false
	for r in [9.0, 11.0, 13.0, 16.0]:
		for gradi in [0.0, 20.0, -20.0, 38.0, -38.0, 55.0, -55.0]:
			var a: float = deg_to_rad(gradi)
			# 'a saracinesca guarda verso +Z (GIRO_GARAGE = π).
			var p: Vector3 = g.global_position \
				+ Vector3(sin(a), 0.0, cos(a)) * r
			if Citta.dint_ô_palazzo(p, 0.6):
				continue
			_cam.look_at_from_position(p + Vector3(0, 3.2, 0), mira, Vector3.UP)
			print("  telecamera a %s (%.0f m, %.0f°)" % [str(p.round()), r,
				gradi])
			truvato = true
			break
		if truvato:
			break
	if not truvato:
		print("  NUN S'È TRUVATO 'NU PUNTO LIBBERO ATTUORNO Ô GARAGE")
	_cam.current = true


# ---------------------------------------------------------------------------
# Servizio
# ---------------------------------------------------------------------------

func _truova_hud() -> CanvasLayer:
	for n in _tutte(get_tree().root):
		if n is CanvasLayer and n.has_method("_cruscotto"):
			return n
	return null


func _tutte(n: Node) -> Array:
	var fore: Array = [n]
	for c in n.get_children():
		fore.append_array(_tutte(c))
	return fore


func _scatta(nome: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/57_%s.png" % nome)
	print("  foto: /tmp/57_%s.png" % nome)
