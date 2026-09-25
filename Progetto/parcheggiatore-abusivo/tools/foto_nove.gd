extends Node
## **'E fote d''a robba nova** (0.59): un giro per la città a guardare i
## pezzi di Pandazole, le macchine nuove e i cristiani nuovi, uno scatto
## per cosa. Si guarda con l'occhio quello che le prove non sanno dire: se
## la frutta sta nella cassetta o per aria, se l'operaio è inginocchiato
## davanti al muro o dentro al muro, se il cartello guarda la strada.

const VascioScript := preload("res://scripts/vascio_3d.gd")

var _t := 0.0
var _n := 0
var _pronto := false
var _cam: Camera3D = null
var _citta: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(d: float) -> void:
	if not _pronto:
		_pronto = true
		for n in _tutte(get_tree().root):
			if n is CanvasLayer and n.has_method("_on_menu_gioca"):
				(n as CanvasLayer).visible = false
				break
		get_tree().paused = false
		GameManager.giornata = 3
		GameManager.start_shift()
		GameManager.tipo_giornata = "normale"
		GameManager.intro_active = false
		GameManager.shift_time_left = GameManager.shift_duration * 0.88
		_cam = Camera3D.new()
		_cam.fov = 62
		get_tree().root.add_child(_cam)
		_cam.current = true
		return
	_t += d
	if _t < 0.8:
		return
	_t = 0.0
	_n += 1
	if _citta == null:
		_citta = get_tree().get_first_node_in_group("citta")
	var scatti := ["mercato", "frutta", "pizzeria", "ferramenta", "edicola",
		"cantiere", "tetti", "balconi", "munnezza", "lungomare",
		"piscatore", "vascio", "vascio2", "bar", "gazzella", "sosta",
		"passanti", "slargo", "cartello", "fiori"]
	var i: int = (_n - 2) / 2
	if _n < 2:
		return
	if i >= scatti.size():
		get_tree().quit()
		return
	if _n % 2 == 0:
		_prepara(str(scatti[i]))
	else:
		await _scatta(str(scatti[i]))


func _prepara(cosa: String) -> void:
	match cosa:
		"mercato":
			var b := _posto_utile("bancarella")
			if b:
				_mira(b.global_position + Vector3(2.4, 2.0, 2.4), b.global_position + Vector3(0, 0.8, 0))
		"frutta":
			_negozio("FRUTTA E VERDURA", 3.2, 1.7)
		"pizzeria":
			_negozio("PIZZERIA", 3.2, 1.7)
		"ferramenta":
			_negozio("FERRAMENTA", 3.4, 1.8)
		"edicola":
			_negozio("EDICOLA", 3.2, 1.7)
		"cantiere":
			var o: Node3D = get_tree().get_first_node_in_group("operai")
			if o:
				var p: Vector3 = o.global_position
				var f: Vector3 = -o.global_transform.basis.z
				_mira(p - f * 3.2 + Vector3(1.6, 1.8, 0.0), p + Vector3(0, 0.5, 0))
			else:
				print("  NISCIUN OPERAIO")
		"tetti":
			_mira(Vector3(118.0, 26.0, 150.0), Vector3(95.0, 10.0, 120.0))
		"balconi":
			_mira(Vector3(78.0, 1.7, 40.0), Vector3(74.0, 9.0, 50.0))
		"munnezza":
			var cs: Array = _citta.get("_cassonetti")
			if cs.is_empty():
				print("  NISCIUN CASSONETTO")
			else:
				var c: Vector3 = cs[0][0]
				var g: float = float(cs[0][1])
				var fuori := Vector3(sin(g), 0, cos(g))
				var lungo := Vector3(cos(g), 0, -sin(g))
				_mira(c + fuori * 4.2 + lungo * 1.5 + Vector3(0, 2.2, 0), c + lungo * 1.2 + Vector3(0, 0.5, 0))
		"lungomare":
			_mira(Vector3(70.0, 1.8, 3.8), Vector3(90.0, 2.0, 0.6))
		"piscatore":
			var m := _citta.get_node_or_null("Mergellina")
			var pis: Node3D = m.get_node_or_null("Piscatore") if m else null
			if pis:
				var p2: Vector3 = pis.global_position
				_mira(p2 + Vector3(3.4, 2.2, 3.0), p2 + Vector3(-0.6, 0.9, -1.2))
		"vascio":
			# Dall'angolo del letto verso il tavolo e la culla.
			var d0: Vector3 = VascioScript.DENTRO
			_mira(d0 + Vector3(-2.2, 1.6, -1.8), d0 + Vector3(1.5, 0.8, 1.6))
		"vascio2":
			# Dall'angolo della culla verso il tavolo apparecchiato: è lo
			# scatto dove un palazzo finto del golfo tagliava la stanza.
			var d1: Vector3 = VascioScript.DENTRO
			_mira(d1 + Vector3(2.4, 1.6, 1.9), d1 + Vector3(-1.05, 0.8, 1.62))
		"bar":
			# Il bar della città (il banco sta mezzo metro dietro al posto
			# utile, e la strada è verso +Z).
			var pbar := _posto_utile("bar")
			if pbar:
				var pb: Vector3 = pbar.global_position - Vector3(0, 0, 0.6)
				_mira(pb + Vector3(1.0, 1.9, 2.2), pb + Vector3(-0.1, 1.1, 0.25))
		"gazzella":
			_macchine_in_fila()
		"sosta":
			_mira(Vector3(78.0, 1.8, 26.0), Vector3(76.0, 0.6, 40.0))
		"passanti":
			var ps := get_tree().get_nodes_in_group("passanti")
			for pn in ps:
				var v = pn.get("_visual")
				if v is Node3D and (v as Node3D).get_child_count() > 0:
					var mod := str((v as Node3D).get_child(0).get_child(0).name)
					if mod != "Pupo":
						pass
			if not ps.is_empty():
				var pp: Node3D = ps[0]
				_mira(pp.global_position + Vector3(3.5, 1.8, 3.5), pp.global_position + Vector3(0, 1.0, 0))
		"slargo":
			_gruppo("Gruppo_slarghi_fioriera_1_0", Vector3(4.0, 2.4, 4.0))
		"cartello":
			_gruppo("Gruppo_cartelli_cartello_divieto_sosta_0", Vector3(2.6, 1.8, 2.6))
		"fiori":
			_negozio("FIORI", 3.0, 1.7)


func _posto_utile(tipo: String) -> Node3D:
	for n in get_tree().get_nodes_in_group("posti_utili"):
		if str(n.get("tipo")) == tipo:
			return n
	return null


func _negozio(nome: String, lontano: float, alto: float) -> void:
	for n in get_tree().get_nodes_in_group("negozi"):
		if str(n.get_meta("nome", "")) == nome:
			var p: Vector3 = (n as Node3D).global_position
			var f: Vector3 = (n as Node3D).global_transform.basis.z
			var lato: Vector3 = (n as Node3D).global_transform.basis.x
			# Dall'alto e da vicino: davanti alle botteghe del Corso ci
			# stanno le auto in sosta, e da lontano si fotografa la portiera.
			_mira(p + f * (lontano * 0.62) + lato * 0.9 + Vector3(0, alto + 0.9, 0),
				p + f * 1.0 + Vector3(0, 0.35, 0))
			print("  %s a %s" % [nome, str(p.round())])
			return
	print("  NUN CE STA %s" % nome)


func _gruppo(nome: String, da: Vector3) -> void:
	var g := _citta.get_node_or_null(nome) as MultiMeshInstance3D
	if g == null or g.multimesh.instance_count == 0:
		print("  NUN CE STA %s" % nome)
		return
	var p: Vector3 = g.global_transform * g.multimesh.get_instance_transform(0).origin
	print("  %s a %s" % [nome, str(p.round())])
	_mira(p + da, p + Vector3(0, 0.6, 0))


## Le macchine nuove in fila su un pezzo di strada: la gazzella, il taxi,
## e le cinque del Car Pack, per vederle col sole vero e i materiali del
## gioco.
func _macchine_in_fila() -> void:
	var dove := Vector3(60.0, 0.0, 2.5)
	var Models = load("res://scripts/models.gd")
	var AutoVarie = load("res://scripts/auto_varie.gd")
	var x := 0.0
	var car = load("res://scripts/carabinieri_3d.gd").new()
	get_tree().root.add_child(car)
	car.global_position = dove + Vector3(x, 0, 0)
	car.rotation.y = PI * 0.5
	car.set_physics_process(false)
	x += 5.0
	var taxi: Node3D = AutoVarie.costruisci(AutoVarie.Tipo.TAXI, Color.WHITE)
	get_tree().root.add_child(taxi)
	taxi.global_position = dove + Vector3(x, 0, 0)
	taxi.rotation.y = PI * 0.5
	x += 5.0
	for nome in ["car_economica", "car_berlina", "car_lusso", "car_coupe2", "car_sportiva2"]:
		var a: Node3D = Models.spawn_by_length(nome)
		if a == null:
			continue
		Models.polish_vehicle(a)
		Models.tint(a, ["body"], Color(0.55, 0.18, 0.2), 0.5, 0.3)
		get_tree().root.add_child(a)
		a.global_position = dove + Vector3(x, 0, 0)
		a.rotation.y = PI * 0.5
		x += 5.0
	# Dal lato del mare: dal lato delle case la camera finiva dentro a un
	# palazzo.
	_mira(dove + Vector3(6.0, 3.2, -7.0), dove + Vector3(12.0, 0.6, 0.0))


func _tutte(n: Node) -> Array:
	var fore: Array = [n]
	for c in n.get_children():
		fore.append_array(_tutte(c))
	return fore


func _mira(occhio: Vector3, meta: Vector3) -> void:
	_cam.look_at_from_position(occhio, meta, Vector3.UP)
	_cam.current = true


func _scatta(nome: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/59n_%s.png" % nome)
	print("  foto: /tmp/59n_%s.png" % nome)
