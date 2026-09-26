extends Node
## **'E fote d''e filtre** (0.62): ogni filtro dello schermo sulla stessa
## inquadratura (il Decumano di giorno), più la botta a metà e il menu di
## pausa col bottone nuovo. Uso: `/tmp/foto.sh foto_filtri 300` →
## `/tmp/filtro_*.png`. Con `NOTTE=1` di notte (la lente sporca si vede coi
## lampioni).

const SCATTI := ["nisciuno", "pellicola", "videocassetta", "lente_sporca", "botta", "soldi", "pausa"]

var _t := 0.0
var _n := 0
var _pronto := false
var _cam: Camera3D = null


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
		var quanto: float = 0.04 if OS.get_environment("NOTTE") == "1" else 0.84
		GameManager.shift_time_left = GameManager.shift_duration * quanto
		_cam = Camera3D.new()
		_cam.fov = 62
		get_tree().root.add_child(_cam)
		_cam.look_at_from_position(Vector3(96.0, 1.7, 61.5), Vector3(112.0, 1.0, 64.0),
			Vector3.UP)
		_cam.current = true
		return
	_t += d
	if _t < (0.25 if _n % 2 == 0 and _n >= 2 and (_n - 2) / 2 < SCATTI.size() and SCATTI[(_n - 2) / 2] == "soldi" else 0.8):
		return
	_t = 0.0
	_n += 1
	var i: int = (_n - 2) / 2
	if _n < 2:
		return
	if i >= SCATTI.size():
		get_tree().quit()
		return
	var f: Node = get_tree().get_first_node_in_group("filtri_schermo")
	if f == null:
		print("  NUN CE STANNO 'E FILTRE")
		get_tree().quit()
		return
	var nome: String = SCATTI[i]
	if _n % 2 == 0:
		_cam.current = true
		if nome == "botta":
			f.scelto = "nisciuno"
			f.applica()
			f._forza = 0.8
			f.set_process(false)
			f._botta.visible = true
			f._botta_mat.set_shader_parameter("forza", 0.8)
		elif nome == "soldi":
			f.set_process(true)
			f._forza = 0.0
			# Il borsello che si riempie e quello che si svuota (0.62).
			GameManager.money += 15
			GameManager.money_changed.emit(GameManager.money)
			GameManager.money -= 8
			GameManager.money_changed.emit(GameManager.money)
		elif nome == "pausa":
			f.set_process(true)
			f._forza = 0.0
			var hud := get_tree().root.find_child("HUD", true, false)
			if hud != null and hud.get("pause_panel") != null:
				hud.pause_panel.visible = true
		else:
			f.scelto = nome
			f.applica()
		return
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var suff: String = "_notte" if OS.get_environment("NOTTE") == "1" else ""
	img.save_png("/tmp/filtro_%s%s.png" % [nome, suff])
	print("  foto /tmp/filtro_%s%s.png" % [nome, suff])


func _tutte(n: Node) -> Array:
	var fore: Array = [n]
	for c in n.get_children():
		fore.append_array(_tutte(c))
	return fore
