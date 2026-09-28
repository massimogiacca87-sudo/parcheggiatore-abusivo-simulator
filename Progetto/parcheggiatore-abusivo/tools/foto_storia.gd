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
## Si lancia senza toccare `project.godot` (vedi `tools/lancia_foto.gd`):
##   godot --path . --rendering-driver opengl3 --resolution 1280x760 \
##       --script res://tools/lancia_foto.gd -- res://tools/foto_storia.gd
## Le foto vanno in `FOTO_DIR` (variabile d'ambiente) o in /tmp. Con
## `FOTO_CHI=vigile,maestro` si fotografano solo quelli.
##
## **Comme se fotografa na faccia** (0.66, dopo il giudizio del revisore):
##
##   * **Niente fumetti.** Il carabiniere entra gridando «FIERMATE!», e il
##     fumetto — che si ingrandisce con la distanza per restare leggibile —
##     copriva la faccia a lui e ai vicini. Si spengono i fumetti e tutte le
##     scritte 3D, si fermano i cervelli dei personaggi (così non ne aprono
##     altri) e si aspetta che la gesticolata del parlare finisca.
##   * **La macchina si mette davanti alla faccia, non davanti al posto.**
##     Il davanti si legge dall'osso della testa (+Z), quindi il magliaro
##     che sta girato dietro al suo banco si fotografa lo stesso di faccia.
##   * **Ad altezza d'occhi, a un metro e trenta**: di fronte, di tre
##     quarti e di profilo. Mentre se ne fotografa uno gli altri si
##     nascondono, così la macchina non finisce mai dentro al vicino.
##   * Per chi porta la bandoliera (vigile, carabiniere) anche il busto,
##     di fronte e di profilo.

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
## Chi porta roba sul busto: di questi si fotografa pure il petto.
const COL_BUSTO := ["vigile", "carabiniere"]
## Gli occhi sull'osso della testa del pupo (centro del bulbo, misurato).
const OCCHI := Vector3(0.0, 0.101, 0.13)
const DISTANZA := 1.3
const PASSO_FILA := 1.3
const PASSO_FOTO := 3.0

var _dir := "/tmp"
var _cam: Camera3D = null
var _chi: Array = []
var _pulito := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dir = OS.get_environment("FOTO_DIR") if OS.get_environment("FOTO_DIR") != "" else "/tmp"
	DirAccess.make_dir_recursive_absolute(_dir)
	var solo: PackedStringArray = OS.get_environment("FOTO_CHI").split(",", false)
	await get_tree().process_frame
	await get_tree().process_frame
	var mondo := Node3D.new()
	mondo.name = "StudioFoto"
	add_child(mondo)
	var suolo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 40)
	suolo.mesh = pm
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.45, 0.43, 0.40)
	suolo.material_override = sm
	mondo.add_child(suolo)
	var muro := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(60, 6, 0.3)
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

	var tutti: Array = []
	for s in SCRIPTS:
		if solo.is_empty() or solo.has(str(s[0])):
			tutti.append(s)
	var x := -float(tutti.size() - 1) * 0.5 * PASSO_FILA
	for s in tutti:
		var sc: Script = load(str(s[1]))
		var n: Node3D = sc.new()
		mondo.add_child(n)
		n.global_position = Vector3(x, 0.0, 0.0)
		# Guardano la macchina (che sta a −Z): il davanti di una persona è −Z.
		n.rotation.y = 0.0
		# Fermi subito: niente cervello (che apre fumetti e sposta la gente),
		# l'animazione sì. Il Re e Gennarino nascono nascosti (compaiono al
		# loro momento): qui si accendono.
		_ferma(n)
		n.visible = true
		_chi.append([str(s[0]), n])
		x += PASSO_FILA
	_zittisci()
	print("  ", _chi.size(), " cristiane d''a storia")


## Niente cervello: né `_process` né `_physics_process`, né timer propri.
## L'Animator (che è un nodo a parte) continua, ed è quello che si vuole.
func _ferma(n: Node) -> void:
	n.set_process(false)
	n.set_physics_process(false)


## **Zitti tutti.** Spegne i fumetti (lo script `speech_bubble.gd`) e ogni
## `Label3D` (le targhette, il cartone di Gennarino resta: è una Label3D
## ma è roba sua, non un fumetto — quindi si spengono solo quelle col
## cartellone sempre girato verso la macchina).
func _zittisci() -> void:
	for c in _chi:
		_zittisci_nodo(c[1])


func _zittisci_nodo(n: Node) -> void:
	for f in n.get_children():
		var sc: Script = f.get_script() as Script
		if sc != null and sc.resource_path.ends_with("speech_bubble.gd"):
			(f as Node3D).visible = false
			f.process_mode = Node.PROCESS_MODE_DISABLED
			continue
		if f is Label3D and (f as Label3D).billboard != BaseMaterial3D.BILLBOARD_DISABLED:
			(f as Label3D).visible = false
		_zittisci_nodo(f)


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


func _testa(n: Node) -> Node3D:
	var t: Node = n.find_child("att_head", true, false)
	return t as Node3D


func _scatta_tutto() -> void:
	# La gesticolata del parlare dura quanto il fumetto (2-3 secondi):
	# si aspetta che finisca, così nessuno è fotografato a bocca aperta e
	# braccia per aria.
	await get_tree().create_timer(3.5).timeout
	for c in _chi:
		var n: Node3D = c[1]
		_ferma(n)
		n.visible = true
		for f in n.get_children():
			if f is Node3D:
				(f as Node3D).visible = true
	_zittisci()
	var larghi: float = float(_chi.size() - 1) * PASSO_FILA
	await _foto(Vector3(0, 1.6, -maxf(6.0, larghi * 0.95 + 2.0)), Vector3(0, 1.0, 0),
		"storia_fila", 52.0)
	# Da lontano, come li vede il giocatore dall'altra parte della piazza.
	await _foto(Vector3(0, 2.4, -16.0), Vector3(0, 1.1, 0), "storia_lontano", 40.0)
	# Adesso uno alla volta, larghi, e gli altri nascosti.
	var x0: float = -float(_chi.size() - 1) * 0.5 * PASSO_FOTO
	for i in range(_chi.size()):
		var n: Node3D = _chi[i][1]
		n.global_position = Vector3(x0 + PASSO_FOTO * i, 0.0, 0.0)
	for i in range(_chi.size()):
		var nome: String = _chi[i][0]
		var n: Node3D = _chi[i][1]
		for j in range(_chi.size()):
			(_chi[j][1] as Node3D).visible = (j == i)
		for _k in range(3):
			await get_tree().process_frame
		var testa := _testa(n)
		var occhi: Vector3
		var avanti: Vector3
		if testa != null:
			var g: Transform3D = testa.global_transform
			occhi = g * OCCHI
			avanti = g.basis.z
		else:
			occhi = n.global_position + Vector3(0, 1.62, 0)
			avanti = -n.global_transform.basis.z
		avanti.y = 0.0
		if avanti.length() < 0.01:
			avanti = Vector3(0, 0, -1)
		avanti = avanti.normalized()
		# Si guarda un filo sopra agli occhi: dentro all'inquadratura
		# ci stanno cappello, faccia e colletto.
		var mira := occhi + Vector3(0, 0.03, 0)
		await _foto(occhi + avanti * DISTANZA, mira, "storia_" + nome, 30.0)
		var tre_quarti := avanti.rotated(Vector3.UP, deg_to_rad(40.0))
		await _foto(occhi + tre_quarti * DISTANZA, mira, "storia_" + nome + "_34", 30.0)
		var lato := avanti.rotated(Vector3.UP, deg_to_rad(90.0))
		await _foto(occhi + lato * DISTANZA, mira, "storia_" + nome + "_profilo", 30.0)
		if COL_BUSTO.has(nome):
			var petto := occhi + Vector3(0, -0.42, 0)
			await _foto(petto + avanti * 1.7, petto, "storia_" + nome + "_busto", 36.0)
			await _foto(petto + lato * 1.7, petto, "storia_" + nome + "_busto_profilo", 36.0)
			var dietro := avanti.rotated(Vector3.UP, deg_to_rad(180.0))
			await _foto(petto + dietro * 1.7, petto, "storia_" + nome + "_busto_dietro", 36.0)
	get_tree().quit()


func _foto(da: Vector3, a: Vector3, nome: String, fov: float) -> void:
	for n in get_tree().root.get_children():
		if n != self:
			_spegni(n)
	_zittisci()
	_cam.fov = fov
	_cam.look_at_from_position(da, a, Vector3.UP)
	_cam.make_current()
	for _k in range(3):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var p := "%s/%s.png" % [_dir, nome]
	get_viewport().get_texture().get_image().save_png(p)
	print("  foto: ", p)
