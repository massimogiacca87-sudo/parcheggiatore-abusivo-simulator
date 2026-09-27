extends Node
## Fote 'e 'nu personaggio da tutti i lati (0.64), per controllare che la
## roba montata sopra — occhiali, barba, corona, mantello — stia dove deve
## stare. Il davanti del gioco è −Z (vedi `human_builder.gd`): la foto
## "davanti" si scatta da −Z, e se ci si vede la nuca qualcosa è girato.
##
## `MODELLO=res://scripts/borrelli_3d.gd` (default 'o Rre, che sta già in
## città e si fa solo comparire). `NOME=` per il nome dei file.
## PNG in /tmp/mod_<nome>_<lato>.png.

const DOVE := Vector3(24.0, 0.0, 40.0)

var _cam: Camera3D = null
var _visibili: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(90):
		await get_tree().process_frame
	get_tree().paused = false
	GameManager.intro_active = false
	_nascondi_ui()
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	if pl != null:
		pl.global_position = Vector3(60, 1, 80)
	var percorso := OS.get_environment("MODELLO")
	if percorso == "":
		percorso = "res://scripts/re_parcheggi_3d.gd"
	var nome := OS.get_environment("NOME")
	if nome == "":
		nome = percorso.get_file().get_basename()
	var dove := DOVE
	dove.y = Collina.alzata(dove.x, dove.z)

	var tipo: Node3D = null
	var visual: Node3D = null
	if percorso.contains("re_parcheggi"):
		tipo = get_tree().root.find_child("ReParcheggi", true, false) as Node3D
		tipo.call("_mostra", dove)
		visual = tipo.get("_visual")
	elif percorso == "vigile_cafe":
		# 'O vigile d''o bar: lo costruisce la città, e si fa costruire qui.
		var citta := get_tree().root.find_child("Citta", true, false)
		citta.call("_vigile_ar_cafe", dove, dove + Vector3(0, 0, -5))
		tipo = citta.get_child(citta.get_child_count() - 1) as Node3D
	else:
		tipo = (load(percorso) as GDScript).new() as Node3D
		get_tree().current_scene.add_child(tipo)
		tipo.global_position = dove
		for campo in ["_visual_root", "_visual", "visual"]:
			if tipo.get(campo) is Node3D:
				visual = tipo.get(campo)
				break
	tipo.set_physics_process(false)
	# Chi guarda verso +Z (la signora delle spighe, dietro al carretto) si
	# gira di mezzo giro: la foto "davanti" si scatta sempre da −Z.
	if OS.get_environment("GIRA") != "":
		tipo.rotation.y = float(OS.get_environment("GIRA"))
	# (_process resta: lì vivono le cose che si muovono da sole, tipo la
	# lucetta del telefonino di Borrelli.)
	if visual != null:
		visual.rotation.y = 0.0
	_cam = Camera3D.new()
	_cam.fov = 45
	get_tree().root.add_child(_cam)
	await get_tree().create_timer(1.5).timeout

	var c: Vector3 = tipo.global_position
	var mezzo := c + Vector3(0, 1.05, 0)
	await _foto(nome, "davanti", c + Vector3(0, 1.4, -3.6), mezzo)
	await _foto(nome, "tre_quarti", c + Vector3(2.5, 1.6, -2.5), mezzo)
	await _foto(nome, "fianco", c + Vector3(3.6, 1.4, 0), mezzo)
	await _foto(nome, "dietro", c + Vector3(0.4, 1.5, 3.6), mezzo)
	await _foto(nome, "dietro_tre_quarti", c + Vector3(-2.5, 1.6, 2.5), mezzo)
	_cam.fov = 26
	await _foto(nome, "faccia", c + Vector3(0.0, 1.8, -1.7), c + Vector3(0, 1.66, 0))
	await _foto(nome, "faccia_fianco", c + Vector3(1.7, 1.8, -0.3), c + Vector3(0, 1.66, 0))
	# E mentre cammina: le braccia e le gambe non devono passare il vestito.
	_cam.fov = 45
	var anim = tipo.get("_anim")
	if anim != null and anim.has_method("set_speed"):
		anim.call("set_speed", 1.4)
		await get_tree().create_timer(0.55).timeout
		await _foto(nome, "cammina_fianco", c + Vector3(3.4, 1.3, -0.6), mezzo)
		await get_tree().create_timer(0.35).timeout
		await _foto(nome, "cammina_dietro", c + Vector3(0.6, 1.4, 3.4), mezzo)
	get_tree().quit()


func _nascondi_ui() -> void:
	for n in _tutte(get_tree().root):
		if n is CanvasLayer and (n as CanvasLayer).visible:
			_visibili.append(n)
			(n as CanvasLayer).visible = false


func _tutte(n: Node) -> Array:
	var fore: Array = [n]
	for c in n.get_children():
		fore.append_array(_tutte(c))
	return fore


func _foto(nome: String, lato: String, da: Vector3, verso: Vector3) -> void:
	_cam.look_at_from_position(da, verso, Vector3.UP)
	_cam.current = true
	for _i in range(4):
		await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/mod_%s_%s.png" % [nome, lato])
	print("  foto: /tmp/mod_%s_%s.png" % [nome, lato])
