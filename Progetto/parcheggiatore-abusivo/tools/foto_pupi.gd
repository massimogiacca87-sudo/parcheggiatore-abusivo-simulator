extends Node
## Quattro foto d''e pupe dinto ô gioco: fermo, cammina, seduto, 'nterra.
##
## Le prove in Blender dicono com'è fatto il modello; questa dice come si
## vede **davvero**, con la luce del gioco, il materiale di Godot e le
## animazioni accese. È l'unica che conta.

const Human := preload("res://scripts/human_builder.gd")

var _t := 0.0
var _n := 0
var _pupi: Array = []
var _pulito := false
var _detto := false
var _cam: Camera3D = null


func _ready() -> void:
	# **'A prova nun girava pecché 'o gioco steva 'nzerrato.** Il gioco
	# parte in pausa (schermata di caricamento), e un autoload che eredita
	# il modo di elaborazione si ferma con lui: `_process` non veniva
	# chiamato **mai**, e la prova restava lì a guardare.
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	await get_tree().process_frame
	var mondo := Node3D.new()
	add_child(mondo)

	# Terra e cielo, che se no si vede solo il nero.
	var suolo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	suolo.mesh = pm
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.42, 0.40, 0.38)
	suolo.material_override = mt
	mondo.add_child(suolo)

	var luce := DirectionalLight3D.new()
	luce.rotation_degrees = Vector3(-48, 38, 0)
	luce.light_energy = 1.25
	mondo.add_child(luce)
	var amb := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.60, 0.66, 0.74)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.66, 0.72)
	env.ambient_light_energy = 0.85
	amb.environment = env
	mondo.add_child(amb)

	var cam := Camera3D.new()
	cam.fov = 55
	mondo.add_child(cam)
	# Il gioco guarda verso −Z, quindi i pupi danno le spalle a +Z: per
	# vederli in faccia la macchina sta davanti, cioè a −Z.
	cam.position = Vector3(0.0, 1.45, -4.3)
	cam.look_at(Vector3(0.0, 0.95, 0.0))
	cam.current = true
	_cam = cam

	# Cinque tipi diversi, in fila, come stanno in piazza.
	var tipi := [
		{"corpo": "magro", "belly": 0.15, "moustache": false, "bald": false},
		{"corpo": "normale", "belly": 0.45, "moustache": true, "bald": false},
		{"corpo": "panzone", "belly": 0.8, "moustache": true, "bald": true},
		{"corpo": "femmina", "belly": 0.4, "moustache": false, "bald": false},
		{"corpo": "normale", "belly": 0.4, "moustache": false, "bald": false},
	]
	var camicie := [
		Color(0.86, 0.84, 0.78), Color(0.35, 0.48, 0.62),
		Color(0.72, 0.28, 0.26), Color(0.52, 0.30, 0.46),
		Color(0.90, 0.86, 0.40),
	]
	var alt := [1.72, 1.80, 1.76, 1.63, 1.34]
	for i in range(tipi.size()):
		var o: Dictionary = tipi[i]
		var parti: Dictionary = Human.build(camicie[i],
			Color(0.24, 0.26, 0.32), "", float(alt[i]), o)
		var r: Node3D = parti["root"]
		r.position = Vector3(-2.6 + 1.3 * i, 0.0, 0.0)
		mondo.add_child(r)
		_pupi.append(parti)
	print("  ", _pupi.size(), " pupe ncopp'â scena")


func _process(d: float) -> void:
	# **'A città se ne va 'a mmiez'ê piede.** L'autoload gira accanto alla
	# scena principale, che costruisce mezza Napoli: sotto al renderer
	# software un fotogramma ci mette dei secondi e la prova non arriva mai
	# in fondo. Non si può *cancellare* (l'albero si chiude dietro), ma si
	# può spegnere: invisibile e ferma.
	if not _pulito:
		# Si spegne **tutto** quello che sta appeso alla radice e non è
		# roba nostra: la scena del gioco e, soprattutto, la schermata di
		# caricamento, che è un CanvasLayer disegnato sopra ogni cosa — le
		# prime foto erano cinque copie del cartello del titolo.
		for n in get_tree().root.get_children():
			if n == self:
				continue
			if n is Node3D:
				(n as Node3D).visible = false
			if n is CanvasItem:
				(n as CanvasItem).visible = false
			if n is CanvasLayer:
				(n as CanvasLayer).visible = false
			_spegni(n)
		_pulito = true
	_t += d
	if _n == 0 and _t > 0.05 and not _detto:
		_detto = true
		print("  _process gira, delta=", d)
	if _t < 0.9:
		return
	_t = 0.0
	_n += 1
	match _n:
		1:
			_scatta("fermo")
		2:
			for p in _pupi:
				if p.get("anim") != null:
					p["anim"].set_speed(1.4)
			_t = 0.55           # mezzo passo, non il fotogramma zero
		3:
			_scatta("cammina")
		4:
			for p in _pupi:
				if p.get("anim") != null:
					p["anim"].set_speed(5.6)
			_t = 0.4
		5:
			_scatta("corre")
		6:
			for p in _pupi:
				var a = p.get("anim")
				if a == null:
					continue
				a.set_speed(0.0)
				a.knock_down()
			_t = 0.5
		7:
			_scatta("nterra")
		8:
			for i in range(_pupi.size()):
				var a = _pupi[i].get("anim")
				if a == null:
					continue
				a.revive()
				if i % 2 == 0:
					a.sit()
				else:
					a.action("parla")
			_t = 0.5
		9:
			_scatta("seduto")
		10:
			# Un primo piano, che è come si vede quando parli con uno.
			if _cam != null:
				_cam.position = Vector3(-0.05, 1.30, -1.55)
				_cam.look_at(Vector3(-0.05, 1.15, 0.0))
			for p in _pupi:
				var a2 = p.get("anim")
				if a2 != null:
					a2.stand()
					a2.set_speed(0.0)
			_t = 0.5
		11:
			_scatta("faccia")
			await get_tree().create_timer(0.4).timeout
			get_tree().quit()


## Spegne ogni CanvasLayer/CanvasItem appeso sotto a `n`, a qualunque
## profondità: la schermata di caricamento sta dentro a un autoload.
func _spegni(n: Node) -> void:
	for c in n.get_children():
		if c is CanvasLayer:
			(c as CanvasLayer).visible = false
		if c is CanvasItem:
			(c as CanvasItem).visible = false
		_spegni(c)


func _scatta(nome: String) -> void:
	# **Ogni vota, no 'na vota sola.** L'HUD e la telecamera del gioco
	# nascono dopo di noi: spegnerli una volta in `_ready` non basta, se lo
	# riprendono al primo fotogramma utile.
	for n in get_tree().root.get_children():
		if n != self:
			_spegni(n)
	if _cam != null:
		_cam.make_current()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/gioco_%s.png" % nome)
	print("  foto: /tmp/gioco_%s.png" % nome)
