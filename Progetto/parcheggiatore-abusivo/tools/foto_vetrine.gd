extends Node
## **'E vetrine, una per una** (0.64).
##
## La roadmap lo teneva aperto dalla 0.60: *«guardare in fotografia le
## trenta vetrine della 0.59 (le prove dicono che non toccano niente, ma
## nessuno le ha ancora viste tutte)»*. Questa le gira tutte: per ogni meta
## del gruppo `negozi` una foto da sette metri, all'altezza degli occhi,
## con il punto dove si ferma l'autista segnato da un paletto giallo.
## PNG in /tmp/vet_NN.png; `tools/foto_provino.py` le mette in provini.

var _cam: Camera3D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(90):
		await get_tree().process_frame
	get_tree().paused = false
	GameManager.intro_active = false
	for n in _tutte(get_tree().root):
		if n is CanvasLayer:
			(n as CanvasLayer).visible = false
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	if pl != null:
		pl.global_position = Vector3(95, 1, 150)
	_cam = Camera3D.new()
	_cam.fov = 74
	get_tree().root.add_child(_cam)
	var negozi: Array = get_tree().get_nodes_in_group("negozi")
	negozi.sort_custom(func(a, b):
		return (a as Node3D).global_position.x * 1000.0 + (a as Node3D).global_position.z \
			< (b as Node3D).global_position.x * 1000.0 + (b as Node3D).global_position.z)
	var paletto := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.06
	pm.bottom_radius = 0.06
	pm.height = 1.6
	paletto.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(1.0, 0.85, 0.1)
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paletto.material_override = gm
	get_tree().root.add_child(paletto)
	var i := 0
	for n in negozi:
		var nn := n as Node3D
		var punto: Vector3 = n.get_meta("punto", nn.global_position)
		var dove: Vector3 = nn.global_position
		# Da dove si guarda: sette metri davanti al punto, dalla parte
		# opposta al negozio (il verso lo dà il punto: sta davanti al vetro).
		var fuori: Vector3 = punto - dove
		fuori.y = 0.0
		if fuori.length() < 0.2:
			fuori = nn.global_transform.basis.z
			fuori.y = 0.0
		fuori = fuori.normalized()
		var lato := Vector3(fuori.z, 0.0, -fuori.x)
		var y: float = Collina.alzata(dove.x, dove.z)
		paletto.global_position = punto + Vector3(0, 0.8, 0)
		# Sulle strade strette sette metri stanno dentro al palazzo di
		# fronte: ci si avvicina finché l'occhio sta all'aperto.
		var Citta = load("res://scripts/citta_3d.gd")
		var indietro := 6.0
		var di_lato := 2.0
		while indietro > 1.5 and Citta.dint_ô_palazzo(punto + fuori * indietro + lato * di_lato, 0.4):
			indietro -= 0.5
			di_lato = minf(di_lato, indietro * 0.3)
		var occhio: Vector3 = punto + fuori * indietro + lato * di_lato + Vector3(0, y + 1.7 - punto.y, 0)
		# La città non conosce i palazzi della piazza di casa (li fa
		# `zone_vicolo_3d`): per quelli chiede al motore fisico. Un raggio
		# dal punto, all'altezza degli occhi, verso dove starebbe l'occhio;
		# se sbatte, l'occhio si ferma quaranta centimetri prima.
		var da := Vector3(punto.x, y + 1.7, punto.z)
		var spazio := get_viewport().world_3d.direct_space_state
		var raggio := PhysicsRayQueryParameters3D.create(da, occhio)
		var botta := spazio.intersect_ray(raggio)
		if not botta.is_empty():
			var fin: float = maxf(((botta["position"] as Vector3) - da).length() - 0.4, 1.2)
			occhio = da + (occhio - da).normalized() * fin
		_cam.look_at_from_position(occhio, dove + Vector3(0, y + 1.2, 0), Vector3.UP)
		_cam.current = true
		for _k in range(4):
			await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.resize(640, 380)
		img.save_png("/tmp/vet_%02d.png" % i)
		print("  foto: /tmp/vet_%02d.png  %s a (%.0f, %.0f)" % [i, str(n.get_meta("nome", "?")),
			dove.x, dove.z])
		i += 1
	get_tree().quit()


func _tutte(n: Node) -> Array:
	var fore: Array = [n]
	for c in n.get_children():
		fore.append_array(_tutte(c))
	return fore
