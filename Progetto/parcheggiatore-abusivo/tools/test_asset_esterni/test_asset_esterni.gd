# Collaudo degli asset esterni (res://assets/esterni) e dei plugin (res://addons).
# Lancio: Godot --path <progetto> res://tools/test_asset_esterni/test_asset_esterni.tscn
# Carica tutto, monta gli shader su nodi veri per farli compilare, stampa un rapporto ed esce.
# La cartella tools/ è esclusa dall'export.
extends Node3D

const E := "res://assets/esterni/"
var errori: Array[String] = []
var frame := 0

func _ready() -> void:
	print("=== COLLAUDO ASSET ESTERNI ===")
	_plugin()
	_modelli()
	_materiali()
	_audio()
	_ui()
	_shader()

func _plugin() -> void:
	for c in ["BTPlayer", "BehaviorTree", "LimboHSM", "BTAction"]:
		_ok(ClassDB.class_exists(c), "LimboAI classe " + c)
	_ok(get_node_or_null("/root/Dialogic") != null, "Dialogic autoload presente")
	_ok(ResourceLoader.exists("res://addons/proton_scatter/src/scatter.gd"), "ProtonScatter script scatter.gd")
	var bt = ClassDB.instantiate("BTPlayer")
	_ok(bt != null, "LimboAI BTPlayer istanziabile")
	if bt: bt.free()

func _modelli() -> void:
	var n := 0
	var anim := {}
	for f in _files(E + "modelli", ["glb"]):
		var ps = load(f)
		if ps == null:
			errori.append("modello non caricato: " + f)
			continue
		var inst: Node = ps.instantiate()
		n += 1
		var ap := inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if ap:
			anim[f.get_file()] = ap.get_animation_list().size()
		inst.free()
	print("modelli .glb caricati: ", n, " | con animazioni: ", anim.size())
	for k in anim:
		print("   ", k, " -> ", anim[k], " animazioni")

func _materiali() -> void:
	var n := 0
	for f in _files(E + "materiali", ["jpg", "png", "hdr"]):
		if load(f) == null:
			errori.append("texture non caricata: " + f)
		else:
			n += 1
	print("texture/HDRI caricate: ", n)
	var glb = load(E + "materiali/decals/graffiti/graffiti_decals_karlwirbelwind.glb")
	_ok(glb != null, "graffiti .glb")

func _audio() -> void:
	var n := 0
	for f in _files(E + "audio", ["ogg"]):
		var s = load(f)
		if s == null or not (s is AudioStreamOggVorbis):
			errori.append("audio non caricato: " + f)
		else:
			n += 1
	print("audio .ogg caricati: ", n)

func _ui() -> void:
	var n := 0
	for f in _files(E + "ui", ["png", "svg", "ttf"]):
		if load(f) == null:
			errori.append("ui non caricata: " + f)
		else:
			n += 1
	print("file UI caricati: ", n)

func _shader() -> void:
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0, 2, 4)
	cam.look_at(Vector3.ZERO)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	var pano := PanoramaSkyMaterial.new()
	pano.panorama = load(E + "materiali/hdri/urban_street_01_2k.hdr")
	sky.sky_material = pano
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	env.environment = e
	add_child(env)
	var pavimento := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(20, 20)
	pavimento.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load(E + "materiali/asfalto/asphalt_02/asphalt_02_diff_2k.jpg")
	pavimento.material_override = mat
	add_child(pavimento)
	# pozzanghere: mesh a schermo intero figlia della camera
	var pud := MeshInstance3D.new()
	pud.set_script(load(E + "shader/pozzanghere/fullscreen_mesh.gd"))
	cam.add_child(pud)
	var sm := ShaderMaterial.new()
	sm.shader = load(E + "shader/pozzanghere/rain_puddles_ripples_ssr.gdshader")
	pud.material_override = sm
	_ok(pud.mesh != null, "fullscreen_mesh.gd ha creato la mesh")
	# post-process 2D
	var cl := CanvasLayer.new()
	add_child(cl)
	for s in ["vhs_grunge/vhs_scanline_glitch", "vhs_grunge/vhs_tape_effect", "vhs_grunge/chromatic_aberration_vignette", "vhs_grunge/film_grain", "lente_sporca/dirty_lens"]:
		var sh = load(E + "shader/" + s + ".gdshader")
		_ok(sh != null, "shader caricato " + s)
		var r := ColorRect.new()
		r.set_anchors_preset(Control.PRESET_FULL_RECT)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var m := ShaderMaterial.new()
		m.shader = sh
		r.material = m
		cl.add_child(r)

func _process(_d: float) -> void:
	frame += 1
	if frame == 90:
		print("=== ERRORI: ", errori.size(), " ===")
		for x in errori:
			print("   ", x)
		print("=== FINE COLLAUDO ===")
		get_tree().quit()

func _ok(cond: bool, what: String) -> void:
	if cond:
		print("OK  ", what)
	else:
		print("KO  ", what)
		errori.append(what)

func _files(dir: String, exts: Array) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for sub in d.get_directories():
		out.append_array(_files(dir + "/" + sub, exts))
	for f in d.get_files():
		if f.get_extension().to_lower() in exts:
			out.append(dir + "/" + f)
	return out
