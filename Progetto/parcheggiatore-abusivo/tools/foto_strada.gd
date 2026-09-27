extends Node
## **'A gente pe' mmiez'â via, vista cu ll'uocchie d''o giocatore** (0.66).
##
## Le altre foto dei personaggi li mettono in fila su un palco. Questa li
## prende dove stanno davvero: accende la giornata, aspetta che la città si
## riempia, poi si mette a tre metri da qualche passante, ad altezza
## d'occhi, con la luce e i materiali della città vera, e scatta.
##
## Gira come autoload dentro al gioco (vedi `tools/sh/foto.sh`); le foto
## vanno in `FOTO_DIR` o in /tmp.

var _dir := "/tmp"
var _t := 0.0
var _fatto := false
var _cam: Camera3D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var d := OS.get_environment("FOTO_DIR")
	_dir = d if d != "" else "/tmp"
	DirAccess.make_dir_recursive_absolute(_dir)


func _process(delta: float) -> void:
	if _fatto:
		return
	_t += delta
	if _t < 0.5:
		return
	_fatto = true
	_giro()


func _spegni_ui(n: Node) -> void:
	for c in n.get_children():
		if c is CanvasLayer:
			(c as CanvasLayer).visible = false
		_spegni_ui(c)


func _giro() -> void:
	get_tree().paused = false
	GameManager.giornata = 3
	GameManager.start_shift()
	# La città ci mette un po' a nascere e i passanti a uscire di casa.
	for _k in range(900):
		await get_tree().process_frame
		if get_tree().get_nodes_in_group("passanti").size() >= 12:
			break
	for _k in range(120):
		await get_tree().process_frame
	_cam = Camera3D.new()
	_cam.fov = 60
	add_child(_cam)
	var gente: Array = get_tree().get_nodes_in_group("passanti")
	print("  passanti in città: ", gente.size())
	var fatte := 0
	for p in gente:
		if fatte >= 10:
			break
		var n := p as Node3D
		if n == null or not n.is_inside_tree() or not n.visible:
			continue
		# Davanti a lui: il nodo del passante tiene il corpo girato di
		# mezzo giro (misurato con la prima foto, che li prendeva tutti di
		# spalle), quindi il davanti del nodo è +Z.
		var dav: Vector3 = n.global_transform.basis.z
		dav.y = 0.0
		if dav.length() < 0.1:
			continue
		dav = dav.normalized()
		var lato := Vector3(-dav.z, 0.0, dav.x)
		var occhio: Vector3 = n.global_position + dav * 2.6 + lato * 0.9 + Vector3(0, 1.62, 0)
		var mira: Vector3 = n.global_position + Vector3(0, 1.3, 0)
		_spegni_ui(get_tree().root)
		_cam.look_at_from_position(occhio, mira, Vector3.UP)
		_cam.make_current()
		for _k in range(3):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var f := "%s/strada_%d.png" % [_dir, fatte]
		get_viewport().get_texture().get_image().save_png(f)
		print("  foto: ", f)
		fatte += 1
	get_tree().quit()
