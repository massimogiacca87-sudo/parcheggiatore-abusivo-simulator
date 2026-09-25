extends Node
## **'E fote d''a 0.60**: la galera nuova, la roba PSX nuova e i posti
## toccati, uno scatto per cosa. Le prove dicono se una cosa sta dentro a
## un'altra; se una grata sta *sulla finestra* o tre metri più giù lo dice
## solo una fotografia.
##
## Uso: `/tmp/foto.sh foto_sessanta 400` → `/tmp/60_<nome>.png`.
## Con `SOLO=galera,segge` si fanno solo quegli scatti; con `NOTTE=1` si
## mette l'orologio a notte fonda (le lampade della galera accese).
## Gli scatti sono `[nome, occhio, dove guarda]` in coordinate del mondo,
## oppure `[nome, "gruppo", nome del gruppo, distanza, altezza]` per le
## cose che si fanno trovare (la bancarella, le segge, il bagno chimico).

const SCATTI := [
	["galera_portone", Vector3(139.0, 4.9, 152.7), Vector3(144.5, 5.4, 156.0)],
	["galera_fronte", Vector3(144.0, 4.6, 152.2), Vector3(144.0, 6.6, 156.0)],
	["galera_strada", Vector3(124.0, 5.0, 154.0), Vector3(146.0, 6.5, 155.6)],
	["galera_via_bassa", Vector3(118.0, 1.7, 171.0), Vector3(146.0, 9.0, 166.0)],
	["galera_levante", Vector3(157.6, 1.7, 171.2), Vector3(155.0, 8.0, 160.0)],
	["galera_dall_alto", Vector3(126.0, 24.0, 150.0), Vector3(146.0, 10.0, 161.0)],
	["vecchia_galera", Vector3(169.0, 1.7, 165.5), Vector3(178.0, 6.0, 150.0)],
	["segge", "gruppo", "segge_fore", 3.0, 1.4],
	["signora", "gruppo", "signore_assettate", -2.6, 1.3],
	["bancarella_libri", Vector3(87.2, 1.7, 76.3), Vector3(84.3, 0.9, 78.2)],
	["bancarella_libri2", Vector3(52.2, 1.7, 102.8), Vector3(54.8, 0.9, 100.5)],
	["bagno_chimico", "gruppo", "bagni_chimici", 5.0, 2.0],
	["garage", "gruppo", "garage", -5.0, 2.0],
	["bar", Vector3(42.3, 1.6, 22.6), Vector3(45.2, 1.2, 24.6)],
	["scommesse", "gruppo", "scommesse", 3.2, 1.9],
	["armiere", Vector3(142.6, 1.8, 111.0), Vector3(143.6, 1.3, 114.5)],
	["ringhiere", Vector3(12.0, 1.7, 76.0), Vector3(120.0, 7.0, 76.0)],
	["ringhiere_corso", Vector3(78.0, 1.7, 8.0), Vector3(78.0, 7.0, 120.0)],
	["tetti", Vector3(60.0, 40.0, 40.0), Vector3(90.0, 10.0, 90.0)],
	["tetti_vicino", Vector3(84.0, 22.0, 70.0), Vector3(96.0, 14.0, 84.0)],
	["vascio_fore", Vector3(11.8, 1.6, 42.0), Vector3(9.3, 1.3, 38.8)],
]

var _t := 0.0
var _n := 0
var _pronto := false
var _cam: Camera3D = null
var _lista: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var solo: String = OS.get_environment("SOLO")
	for s in SCATTI:
		if solo == "" or solo.split(",").has(str(s[0])):
			_lista.append(s)


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
		var quanto: float = 0.04 if OS.get_environment("NOTTE") == "1" else 0.88
		GameManager.shift_time_left = GameManager.shift_duration * quanto
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
	var i: int = (_n - 2) / 2
	if _n < 2:
		return
	if i >= _lista.size():
		get_tree().quit()
		return
	if _n % 2 == 0:
		_prepara(_lista[i])
	else:
		await _scatta(str(_lista[i][0]))


func _prepara(s: Array) -> void:
	if s[1] is Vector3:
		_mira(s[1], s[2])
		return
	var g: Node3D = get_tree().get_first_node_in_group(str(s[2]))
	if g == null:
		print("  foto: nisciuno dint'ô gruppo %s" % str(s[2]))
		_mira(Vector3(0, 60, 0), Vector3(1, 0, 1))
		return
	var p: Vector3 = g.global_position
	# Si guarda dal davanti della cosa (il suo +Z), un po' di lato.
	var f: Vector3 = g.global_transform.basis.z
	f.y = 0.0
	if f.length() < 0.1:
		f = Vector3(0, 0, 1)
	f = f.normalized().rotated(Vector3.UP, 0.45)
	_mira(p + f * float(s[3]) + Vector3(0, float(s[4]), 0), p + Vector3(0, 0.7, 0))


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
	var suff: String = "_notte" if OS.get_environment("NOTTE") == "1" else ""
	img.save_png("/tmp/60_%s%s.png" % [nome, suff])
	print("  foto: /tmp/60_%s%s.png" % [nome, suff])
