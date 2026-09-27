extends Node
## **'E cristiane d''a storia, cu 'a rrobba lloro** (0.66).
##
## `foto_personaggi.gd` fotografa il pupo nudo; questo fotografa i
## personaggi **come li costruisce il gioco**, col loro script: il casco del
## vigile, il basco del carabiniere, la corona e gli occhiali del Re, la
## coppola del maestro, lo scialle della signora del lotto, la giacca di
## Borrelli. È la prova che la testa nuova non fa galleggiare (o sprofondare)
## niente di quello che ci sta appeso.
##
## Gira come autoload dentro al gioco vero (vedi `tools/sh/foto.sh`):
##   Foto="*res://scripts/_foto_storia.gd"
## Le foto vanno in `FOTO_DIR` (variabile d'ambiente) o in /tmp.

const SCRIPTS := [
	["vigile", "res://scripts/vigile_3d.gd"],
	["carabiniere", "res://scripts/sbirro_3d.gd"],
	["rre", "res://scripts/re_parcheggi_3d.gd"],
	["borrelli", "res://scripts/borrelli_3d.gd"],
	["maestro", "res://scripts/maestro_3d.gd"],
	["lotto", "res://scripts/signora_lotto_3d.gd"],
	["gennarino", "res://scripts/nuovo_abusivo_3d.gd"],
	["signora", "res://scripts/signora_3d.gd"],
	["rivale", "res://scripts/rivale_3d.gd"],
	["tre_carte", "res://scripts/tre_carte_3d.gd"],
]

var _dir := "/tmp"
var _cam: Camera3D = null
var _chi: Array = []
var _pulito := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dir = OS.get_environment("FOTO_DIR") if OS.get_environment("FOTO_DIR") != "" else "/tmp"
	DirAccess.make_dir_recursive_absolute(_dir)
	await get_tree().process_frame
	await get_tree().process_frame
	var mondo := Node3D.new()
	mondo.name = "StudioFoto"
	add_child(mondo)
	var suolo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 30)
	suolo.mesh = pm
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.45, 0.43, 0.40)
	suolo.material_override = sm
	mondo.add_child(suolo)
	var muro := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(40, 6, 0.3)
	muro.mesh = bm
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color(0.78, 0.66, 0.46)
	muro.material_override = mm
	muro.position = Vector3(0, 3, 3.0)
	mondo.add_child(muro)
	var sole := DirectionalLight3D.new()
	sole.rotation_degrees = Vector3(-42, -128, 0)
	sole.light_energy = 1.15
	sole.light_color = Color(1.0, 0.96, 0.88)
	sole.shadow_enabled = true
	mondo.add_child(sole)
	var rimbalzo := DirectionalLight3D.new()
	rimbalzo.rotation_degrees = Vector3(38, 52, 0)
	rimbalzo.light_energy = 0.36
	rimbalzo.light_color = Color(0.98, 0.88, 0.74)
	mondo.add_child(rimbalzo)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.68, 0.86)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.68, 0.78)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 2.4
	env.tonemap_exposure = 0.92
	we.environment = env
	mondo.add_child(we)
	_cam = Camera3D.new()
	_cam.fov = 40
	mondo.add_child(_cam)

	var x := -float(SCRIPTS.size() - 1) * 0.5 * 1.3
	for s in SCRIPTS:
		var sc: Script = load(str(s[1]))
		var n: Node3D = sc.new()
		mondo.add_child(n)
		n.global_position = Vector3(x, 0.0, 0.0)
		# Guardano la macchina (che sta a −Z): il davanti di una persona è −Z.
		n.rotation.y = 0.0
		# Fermi: niente cervello, l'animazione sì.
		n.set_physics_process(false)
		_chi.append([str(s[0]), n])
		x += 1.3
	print("  ", _chi.size(), " cristiane d''a storia")


func _process(_d: float) -> void:
	if not _pulito:
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
			if n is Node and not (n is Node3D):
				n.process_mode = Node.PROCESS_MODE_DISABLED
		_pulito = true
		_scatta_tutto.call_deferred()


func _spegni(n: Node) -> void:
	for c in n.get_children():
		if c is CanvasLayer:
			(c as CanvasLayer).visible = false
		if c is CanvasItem:
			(c as CanvasItem).visible = false
		_spegni(c)


func _scatta_tutto() -> void:
	for _k in range(40):
		await get_tree().process_frame
	# Tenerli fermi dove li si è messi (qualcuno si sposta da solo in _ready).
	for c in _chi:
		var n: Node3D = c[1]
		n.set_physics_process(false)
	var x0: float = -float(SCRIPTS.size() - 1) * 0.5 * 1.3
	await _foto(Vector3(0, 1.6, -9.5), Vector3(0, 1.0, 0), "storia_fila", 52.0)
	for i in range(_chi.size()):
		var nome: String = _chi[i][0]
		var n: Node3D = _chi[i][1]
		n.global_position = Vector3(x0 + 1.3 * i, 0.0, 0.0)
		var cima: float = 1.55
		await _foto(n.global_position + Vector3(0.35, cima + 0.05, -1.25),
			n.global_position + Vector3(0.0, cima, 0.0), "storia_" + nome, 40.0)
		await _foto(n.global_position + Vector3(1.3, cima, -0.2),
			n.global_position + Vector3(0.0, cima, 0.0), "storia_" + nome + "_profilo", 40.0)
	get_tree().quit()


func _foto(da: Vector3, a: Vector3, nome: String, fov: float) -> void:
	for n in get_tree().root.get_children():
		if n != self:
			_spegni(n)
	_cam.fov = fov
	_cam.look_at_from_position(da, a, Vector3.UP)
	_cam.make_current()
	for _k in range(3):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var p := "%s/%s.png" % [_dir, nome]
	get_viewport().get_texture().get_image().save_png(p)
	print("  foto: ", p)
