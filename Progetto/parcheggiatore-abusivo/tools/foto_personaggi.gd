extends SceneTree
## **'E facce d''e cristiane, prima e dopo.**
##
## La fila dei pupi come li costruisce il gioco (magro, normale coi baffi,
## panzone pelato, femmina, guaglione) e i corpi di fuori (omini, quat,
## umano), di giorno e di sera; poi i primi piani a un metro e mezzo, che è
## la distanza a cui ci si parla. Serve a guardare i personaggi prima di
## toccarli e dopo averli toccati, con la luce e i materiali del gioco.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x760 \
##       --script res://tools/foto_personaggi.gd -- <cartella> <prefisso> [pupo.scn]
##
## Col terzo argomento si prova un pupo che non è ancora quello del gioco
## (per esempio quello appena uscito da `monta_pupo.gd` in `_claude_tmp`).

const Human := preload("res://scripts/human_builder.gd")

var _dir := "/tmp"
var _pre := "pers"
var _mondo: Node3D
var _cam: Camera3D
var _sole: DirectionalLight3D
var _env: Environment
var _gente: Array = []


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() >= 1:
		_dir = a[0]
	if a.size() >= 2:
		_pre = a[1]
	if a.size() >= 3 and a[2] != "":
		Human._scena = load(a[2])
		print("  pupo di prova: ", a[2])
	DirAccess.make_dir_recursive_absolute(_dir)
	_mondo = Node3D.new()
	get_root().add_child(_mondo)
	# La luce e il cielo della città (`citta_3d._build_luce`), copiati:
	# un personaggio si giudica con la luce in cui lo vedrà il giocatore.
	var we := WorldEnvironment.new()
	_env = Environment.new()
	var sky := Sky.new()
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = load("res://assets/shaders/cielo.gdshader")
	sky_mat.set_shader_parameter("col_zenit", Color(0.10, 0.32, 0.72))
	sky_mat.set_shader_parameter("col_cielo", Color(0.35, 0.58, 0.85))
	sky_mat.set_shader_parameter("col_orizzonte", Color(0.82, 0.86, 0.88))
	sky_mat.set_shader_parameter("col_terra", Color(0.30, 0.29, 0.27))
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	_env.background_mode = Environment.BG_SKY
	_env.sky = sky
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	_env.ambient_light_energy = 0.45
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.tonemap_white = 2.4
	_env.tonemap_exposure = 0.92
	_env.adjustment_enabled = true
	_env.adjustment_saturation = 1.08
	_env.adjustment_contrast = 1.05
	we.environment = _env
	_mondo.add_child(we)
	_sole = DirectionalLight3D.new()
	_sole.rotation_degrees = Vector3(-42, -128, 0)
	_sole.light_energy = 1.15
	_sole.light_color = Color(1.0, 0.96, 0.88)
	_sole.shadow_enabled = true
	_sole.light_specular = 0.5
	_mondo.add_child(_sole)
	var rimbalzo := DirectionalLight3D.new()
	rimbalzo.rotation_degrees = Vector3(38, 52, 0)
	rimbalzo.light_energy = 0.36
	rimbalzo.light_color = Color(0.98, 0.88, 0.74)
	_mondo.add_child(rimbalzo)
	var suolo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 30)
	suolo.mesh = pm
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.45, 0.43, 0.40)
	sm.roughness = 0.95
	suolo.material_override = sm
	_mondo.add_child(suolo)
	# Un muro di tufo dietro, che la faccia contro il cielo non si giudica.
	var muro := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(40, 6, 0.3)
	muro.mesh = bm
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color(0.78, 0.66, 0.46)
	mm.roughness = 1.0
	muro.material_override = mm
	muro.position = Vector3(0, 3, 3.0)
	_mondo.add_child(muro)

	# La fila: [modello, camicia, pantaloni, altezza, opzioni, cammina?]
	# Sette tipi di Napoli col pupo, poi quattro corpi di fuori per
	# confronto. Le opzioni della faccia (0.66) il pupo vecchio le ignora.
	var chi: Array = [
		# 'O guappo: sicco, ingellato, cazzimma, catenina sulla camicia aperta.
		["", Color(0.93, 0.92, 0.88), Color(0.12, 0.12, 0.14), 1.76,
			{"corpo": "magro", "moustache": false, "bald": false,
			"skin": Color(0.78, 0.60, 0.44), "hair": Color(0.09, 0.07, 0.06),
			"capelli": "gellati", "palpebre": "furbe", "sopracciglia": "scettiche",
			"naso": "aquilino", "bocca": "cazzimma", "barba": "sfatta", "rughe": "",
			"colletto": true, "catenina": true, "cintura": true}, false],
		# 'O panzone d''o bar: stempiato, baffoni, occhi stanchi.
		["", Color(0.35, 0.48, 0.62), Color(0.22, 0.22, 0.26), 1.72,
			{"corpo": "panzone", "moustache": true, "bald": false,
			"skin": Color(0.86, 0.68, 0.52), "hair": Color(0.62, 0.60, 0.57),
			"capelli": "stempiati", "palpebre": "stanche", "sopracciglia": "dritte",
			"naso": "grosso", "bocca": "sorriso", "barba": "", "rughe": "vecchio",
			"cintura": true}, false],
		# 'A signora: messa in piega, rossetto, gonna.
		["", Color(0.62, 0.22, 0.30), Color(0.20, 0.18, 0.22), 1.62,
			{"corpo": "femmina", "skin": Color(0.91, 0.75, 0.60),
			"hair": Color(0.17, 0.11, 0.07), "capelli": "signora",
			"palpebre": "sveglie", "sopracciglia": "sottili", "naso": "piccolo",
			"bocca": "rossetto", "rughe": "", "gonna": true}, false],
		# 'O guaglione: sfumatura, pizzetto, cammina.
		["", Color(0.90, 0.55, 0.18), Color(0.16, 0.20, 0.34), 1.70,
			{"corpo": "magro", "moustache": false, "bald": false,
			"skin": Color(0.86, 0.68, 0.52), "hair": Color(0.09, 0.07, 0.06),
			"capelli": "sfumati", "palpebre": "sveglie", "sopracciglia": "dritte",
			"naso": "piccolo", "bocca": "dritta", "barba": "pizzetto", "rughe": ""}, true],
		# 'O carabiniere: arraggiato, baffi, banda rossa, cammina.
		["", Color(0.08, 0.09, 0.15), Color(0.06, 0.07, 0.12), 1.82,
			{"corpo": "normale", "moustache": true, "bald": false, "banda": true,
			"skin": Color(0.86, 0.68, 0.52), "hair": Color(0.09, 0.07, 0.06),
			"capelli": "corti", "palpebre": "arraggiate", "sopracciglia": "arraggiate",
			"naso": "grosso", "bocca": "storta", "barba": "", "rughe": "arraggiato",
			"cintura": true}, true],
		# 'A nonna: tuppo bianco, vestita 'e nero.
		["", Color(0.13, 0.12, 0.15), Color(0.10, 0.10, 0.12), 1.56,
			{"corpo": "femmina", "skin": Color(0.86, 0.68, 0.52),
			"hair": Color(0.80, 0.79, 0.77), "capelli": "tuppo",
			"palpebre": "stanche", "sopracciglia": "preoccupate", "naso": "piccolo",
			"bocca": "preoccupata", "rughe": "vecchia", "gonna": true}, false],
		# 'O riccio: barba, sorriso.
		["", Color(0.30, 0.50, 0.35), Color(0.30, 0.28, 0.24), 1.78,
			{"corpo": "normale", "moustache": false, "bald": false,
			"skin": Color(0.68, 0.50, 0.36), "hair": Color(0.09, 0.07, 0.06),
			"capelli": "ricci", "palpebre": "stanche", "sopracciglia": "dritte",
			"naso": "grosso", "bocca": "sorriso", "barba": "barba", "rughe": "stanco"}, false],
		["omo_camicia", Color(0.70, 0.25, 0.22), Color(0.2, 0.22, 0.28), 1.76, {}, false],
		["quat_giacca", Color(0.20, 0.20, 0.24), Color(0.2, 0.2, 0.24), 1.78, {}, false],
		["quat_donna_verde", Color.WHITE, Color.WHITE, 1.64, {}, false],
		["umano_q", Color(0.3, 0.5, 0.35), Color(0.45, 0.4, 0.3), 1.74, {}, false],
	]
	var x := -float(chi.size() - 1) * 0.5 * 1.0
	for c in chi:
		var opts: Dictionary = (c[4] as Dictionary).duplicate()
		if str(c[0]) != "":
			opts["modello"] = c[0]
		var parti: Dictionary = Human.build(c[1], c[2], "", float(c[3]), opts)
		var nodo := Node3D.new()
		nodo.position = Vector3(x, 0, 0)
		# Il gioco guarda a −Z: per averli in faccia li si gira verso −Z,
		# dove sta la macchina.
		_mondo.add_child(nodo)
		nodo.add_child(parti["root"])
		_gente.append([parti.get("anim"), bool(c[5]), nodo])
		x += 1.0
	for _k in range(3):
		await process_frame
	for g in _gente:
		if g[0] != null and bool(g[1]):
			g[0].set_speed(1.35)
	_cam = Camera3D.new()
	_mondo.add_child(_cam)
	_cam.fov = 50
	_cam.current = true
	for _k in range(30):
		await process_frame

	await _foto(Vector3(0, 1.6, -9.0), Vector3(0, 0.95, 0), "fila")
	# I pupi da vicino: tre alla volta, poi le facce una per una.
	await _foto(Vector3(-4.0, 1.35, -3.6), Vector3(-4.0, 1.0, 0), "pupi_a")
	await _foto(Vector3(-1.0, 1.35, -3.6), Vector3(-1.0, 1.0, 0), "pupi_b")
	await _foto(Vector3(3.5, 1.35, -3.6), Vector3(3.5, 1.0, 0), "fore")
	for i in range(7):
		var n: Node3D = _gente[i][2]
		var h: float = float(chi[i][3]) * 0.86
		await _foto(n.position + Vector3(0.25, h + 0.04, -0.95),
			n.position + Vector3(0.0, h - 0.01, 0.0), "faccia_%d" % i, 40.0)
	# Di profilo e da dietro, che è come li si vede in strada.
	var n1: Node3D = _gente[1][2]
	await _foto(n1.position + Vector3(1.6, 1.4, 0.2), n1.position + Vector3(0, 1.0, 0), "profilo")
	await _foto(n1.position + Vector3(0.9, 1.5, 2.0), n1.position + Vector3(0, 1.0, 0), "dietro")
	# Di sera, sotto a un lampione.
	_sole.light_energy = 0.12
	_sole.light_color = Color(0.5, 0.55, 0.8)
	rimbalzo.light_energy = 0.05
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color(0.05, 0.06, 0.10)
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.22, 0.24, 0.34)
	_env.ambient_light_energy = 0.5
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.78, 0.46)
	lamp.light_energy = 2.4
	lamp.omni_range = 9.0
	lamp.shadow_enabled = true
	lamp.position = Vector3(-1.0, 3.6, -1.6)
	_mondo.add_child(lamp)
	await _foto(Vector3(-1.0, 1.55, -4.2), Vector3(-1.0, 1.05, 0), "sera")
	quit()


func _foto(da: Vector3, a: Vector3, nome: String, fov: float = 50.0) -> void:
	_cam.fov = fov
	_cam.look_at_from_position(da, a, Vector3.UP)
	for _k in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	var p := "%s/%s_%s.png" % [_dir, _pre, nome]
	get_root().get_texture().get_image().save_png(p)
	print("  foto: ", p)
