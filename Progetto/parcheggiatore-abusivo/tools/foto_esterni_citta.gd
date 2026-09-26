extends Node
## **'E fote d''a robba 'e fore, dint'â città** (0.62, asset esterni).
##
## Ogni cosa nuova della biblioteca `assets/esterni/` messa in gioco si
## guarda qui, al posto suo: l'asfalto PBR, il muro con la muffa della
## Sanità, i tombini, le macchie d'olio, le colature, i motorini
## parcheggiati, le sedie dei bar, la gente nuova, le macchine nuove.
## (La lezione della 0.62: *se non l'ho visto in una foto, non è fatto*.)
##
## Uso: `/tmp/foto.sh foto_esterni_citta 400` → `/tmp/est_<nome>.png`.
## `SOLO=asfalto,muffa` per farne solo alcune, `NOTTE=1` per la notte,
## `PREFISSO=prima` per salvarle come `/tmp/prima_<nome>.png` (serve a
## fotografare la stessa inquadratura su una copia vecchia e confrontare).
##
## Gli scatti sono `[nome, occhio, dove guarda]` in coordinate del mondo, o
## `[nome, "cerca", funzione]`: la funzione trova la cosa nella città e
## torna `[occhio, mira]` (le posizioni scritte a mano invecchiano con la
## pianta — trappola 30).

const SCATTI := [
	["asfalto_decumano", Vector3(96.0, 1.7, 61.5), Vector3(112.0, 0.0, 64.0)],
	["asfalto_marina", Vector3(30.0, 1.6, 93.2), Vector3(44.0, 0.0, 96.5)],
	["asfalto_alto", Vector3(118.0, 9.0, 58.0), Vector3(128.0, 0.0, 64.0)],
	["muffa", "cerca", "_cerca_muffa"],
	["tombino", "cerca", "_cerca_tombino"],
	["olio", "cerca", "_cerca_olio"],
	["colatura", "cerca", "_cerca_colatura"],
	["graffito", "cerca", "_cerca_graffito"],
	["gomme", "cerca", "_cerca_gomme"],
	["motorini", "cerca", "_cerca_motorini"],
	["sedie_bar", "cerca", "_cerca_sedie_bar"],
	["coni", "cerca", "_cerca_coni"],
	["cassette", "cerca", "_cerca_cassette"],
	["ngombranti", "cerca", "_cerca_ngombranti"],
]

const Citta := preload("res://scripts/citta_3d.gd")

var _t := 0.0
var _n := 0
var _pronto := false
var _cam: Camera3D = null
var _lista: Array = []
var _citta: Node3D = null


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
		var quanto: float = 0.04 if OS.get_environment("NOTTE") == "1" else 0.84
		GameManager.shift_time_left = GameManager.shift_duration * quanto
		_cam = Camera3D.new()
		_cam.fov = 62
		get_tree().root.add_child(_cam)
		_cam.current = true
		_citta = get_tree().get_first_node_in_group("citta")
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
	if _citta == null:
		_citta = get_tree().get_first_node_in_group("citta")
	if s[1] is Vector3:
		_mira(s[1], s[2])
		return
	var dove = call(str(s[2]))
	if dove == null or (dove as Array).is_empty():
		print("  foto %s: NUN L'AGGIU TRUVATO" % s[0])
		_mira(Vector3(0, 60, 0), Vector3(1, 0, 1))
		return
	_mira(dove[0], dove[1])


# ---------------------------------------------------------------------------
# 'E ricerche
# ---------------------------------------------------------------------------

## Tutte le posizioni del mondo delle istanze di un gruppo (MultiMesh) il
## cui nome comincia con `prefisso`.
func _istanze(prefisso: String) -> Array:
	var fore: Array = []
	if _citta == null:
		return fore
	for c in _citta.get_children():
		if not (c is MultiMeshInstance3D) or not str(c.name).begins_with(prefisso):
			continue
		var mm: MultiMesh = (c as MultiMeshInstance3D).multimesh
		for k in mm.instance_count:
			fore.append((c as Node3D).global_transform * mm.get_instance_transform(k))
	return fore


## Da che parte sta la strada, vista da `p`: la direzione orizzontale (fra
## le quattro) in cui si esce prima dal palazzo e poi si hanno `quanto`
## metri liberi. Torna `[direzione, metri per uscire]`.
func _uscita(p: Vector3, quanto: float) -> Array:
	var meglio: Array = [Vector3(0, 0, 1), 0.0]
	var dm := INF
	for v in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var d := 0.0
		while d < 14.0 and Citta.dint_ô_palazzo(p + v * d, 0.0):
			d += 0.25
		if d >= 14.0:
			continue
		var libero := true
		var k := 0.5
		while k <= quanto:
			if Citta.dint_ô_palazzo(p + v * (d + k), 0.0):
				libero = false
				break
			k += 0.5
		if libero and d < dm:
			dm = d
			meglio = [v, d]
	return meglio


func _fuori_da(p: Vector3, quanto: float) -> Vector3:
	return _uscita(p, quanto)[0]


## La prima istanza del gruppo che sta dentro alla pianta (e, se si vuole,
## vicino a un punto), guardata da `dist` metri e da `alto` metri.
func _guarda_gruppo(prefisso: String, dist: float, alto: float,
		mira_y: float = 0.5, vicino: Vector3 = Vector3.INF) -> Array:
	var tutte: Array = _istanze(prefisso)
	if tutte.is_empty():
		return []
	var migliore: Transform3D = tutte[0]
	if vicino != Vector3.INF:
		var dm := INF
		for t in tutte:
			var dd: float = (t as Transform3D).origin.distance_to(vicino)
			if dd < dm:
				dm = dd
				migliore = t
	var p: Vector3 = migliore.origin
	var v: Vector3 = _fuori_da(p, dist)
	var lato: Vector3 = v.rotated(Vector3.UP, 0.5)
	return [p + lato * dist + Vector3(0, alto, 0), p + Vector3(0, mira_y, 0)]


func _cerca_muffa() -> Array:
	# Il muro con la muffa si trova dal nome del gruppo: `_muro_semplice`
	# raggruppa per intonaco (`muro_<nome>_<tinta>`).
	if _citta == null:
		return []
	var nomi: Array = []
	for c in _citta.get_children():
		if c is MultiMeshInstance3D and str(c.name).contains("muffa"):
			nomi.append(str(c.name))
	print("  gruppi co' 'a muffa: ", nomi)
	for c in _citta.get_children():
		if not (c is MultiMeshInstance3D) or not str(c.name).begins_with("Gruppo_muro_muro_muffa"):
			continue
		var mm: MultiMesh = (c as MultiMeshInstance3D).multimesh
		for k in range(mm.instance_count):
			var t: Transform3D = (c as Node3D).global_transform * mm.get_instance_transform(k)
			var p: Vector3 = t.origin
			if p.x < 3.0 or p.z < 3.0:
				continue
			var u: Array = _uscita(p, 3.5)
			var v: Vector3 = u[0]
			var faccia: Vector3 = p + v * float(u[1])
			faccia.y = 3.5
			var occhio: Vector3 = faccia + v * 3.3 + v.rotated(Vector3.UP, PI * 0.5) * 2.5
			occhio.y = 1.7
			return [occhio, faccia + Vector3(0, 0.5, 0)]
	return []


func _cerca_tombino() -> Array:
	return _guarda_gruppo("Gruppo_decal_tombino", 3.2, 1.6, 0.0, Vector3(96, 0, 63))


func _cerca_olio() -> Array:
	return _guarda_gruppo("Gruppo_decal_olio", 3.4, 1.7, 0.0, Vector3(40, 0, 20))


func _cerca_colatura() -> Array:
	return _guarda_gruppo("Gruppo_decal_colatura_split", 4.0, 1.7, 1.2, Vector3(30, 0, 70))


func _cerca_graffito() -> Array:
	return _guarda_gruppo("Gruppo_decal_graffito", 4.5, 1.6, 0.4)


func _cerca_gomme() -> Array:
	return _guarda_gruppo("Gruppo_decal_gomme", 2.2, 1.5, 0.0, Vector3(45, 0, 24))


func _cerca_motorini() -> Array:
	return _guarda_gruppo("Gruppo_esterni_vespa", 3.4, 1.6, 0.6, Vector3(60, 0, 76))


func _cerca_sedie_bar() -> Array:
	return _guarda_gruppo("Gruppo_esterni_seggia_bar", 3.6, 1.7, 0.5)


func _cerca_coni() -> Array:
	return _guarda_gruppo("Gruppo_esterni_cono", 4.5, 1.8, 0.3)


func _cerca_cassette() -> Array:
	return _guarda_gruppo("Gruppo_esterni_cascetta", 2.8, 1.6, 0.3)


func _cerca_ngombranti() -> Array:
	return _guarda_gruppo("Gruppo_esterni_seggia_ufficio", 3.0, 1.6, 0.5)


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
	var pre: String = OS.get_environment("PREFISSO")
	if pre == "":
		pre = "est"
	var suff: String = "_notte" if OS.get_environment("NOTTE") == "1" else ""
	img.save_png("/tmp/%s_%s%s.png" % [pre, nome, suff])
	print("  foto: /tmp/%s_%s%s.png" % [pre, nome, suff])
