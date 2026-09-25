extends StaticBody3D
## Tabaccheria3D
## La tabaccheria della piazza, con la classica insegna a T bianca su fondo
## blu. Premi E per comprare un pacchetto; poi con il tasto della sigaretta
## (F1 / tasto "smoke") te ne accendi una e ti godi la pausa — il sospetto
## scende più in fretta mentre fumi, perché chi fuma appoggiato al muro
## sembra uno del quartiere e non un parcheggiatore all'opera.

const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const Tex := preload("res://scripts/textures.gd")
const Models := preload("res://scripts/models.gd")

const SAY_SOLD := ["Ecco 'o pacchetto.", "Dieci sigarette, tie'.", "E fumatill' 'e salute."]
const SAY_NO_MONEY := "E co' che me pave, cu 'e bottoni?"

var _bubble: Node3D


func _ready() -> void:
	add_to_group("shop")
	add_to_group("tabaccheria")
	collision_layer = 1
	collision_mask = 0
	_build_visual()
	_build_collision()
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 3.4, 0)
	add_child(_bubble)


func _say(text: String) -> void:
	if _bubble:
		_bubble.say(text)
	GameManager.directing_gesture.emit("« Tabaccaio »: %s" % text, true)


func _build_visual() -> void:
	# Vetrina con serranda alzata a metà e bancone
	var front := MeshInstance3D.new()
	var front_mesh := BoxMesh.new()
	front_mesh.size = Vector3(0.25, 1.2, 3.4)
	front.mesh = front_mesh
	front.position = Vector3(0, 2.85, 0)
	front.material_override = Tex.mondo("serranda", Color.WHITE, 0.6)
	add_child(front)

	var counter := MeshInstance3D.new()
	var counter_mesh := BoxMesh.new()
	counter_mesh.size = Vector3(0.7, 1.1, 3.2)
	counter.mesh = counter_mesh
	counter.position = Vector3(0.3, 0.55, 0)
	var counter_mat := StandardMaterial3D.new()
	counter_mat.albedo_color = Color(0.45, 0.3, 0.2)
	counter_mat.roughness = 0.7
	counter.material_override = counter_mat
	add_child(counter)

	# Piano del bancone in maiolica
	var top := MeshInstance3D.new()
	var top_mesh := BoxMesh.new()
	top_mesh.size = Vector3(0.8, 0.08, 3.3)
	top.mesh = top_mesh
	top.position = Vector3(0.3, 1.14, 0)
	top.material_override = Tex.mondo("maioliche", Color.WHITE, 0.4)
	add_child(top)

	# **'O banco d''o tabaccaio** (0.58). Il bancone era di maiolica e
	# vuoto, e un tabaccaio vuoto non vende niente. Otto cose sul piano:
	# sono precisamente quelle che in questo gioco si comprano lì — le
	# sigarette (0.44), il caffè, la schedina del lotto (0.52) — più gli
	# spiccioli di resto che restano sul marmo.
	var rng := RandomNumberGenerator.new()
	rng.seed = 9311
	for e in [
			["pacchetto_sigarette", Vector3(0.24, 1.19, -1.05)],
			["sigaretta", Vector3(0.36, 1.19, -0.72)],
			["accendino", Vector3(0.18, 1.19, -0.44)],
			["fiammifere", Vector3(0.34, 1.19, -0.18)],
			["svapo", Vector3(0.20, 1.19, 0.16)],
			["lecca_lecca", Vector3(0.36, 1.19, 0.52)],
			["tessera", Vector3(0.22, 1.19, 0.86)],
			["spicciulo", Vector3(0.38, 1.19, 1.12)],
			["mazzetta", Vector3(0.18, 1.19, 1.38)],
			["penna", Vector3(0.40, 1.19, -1.35)],
		]:
		var o := Models.spawn(str(e[0]))
		if o == null:
			continue
		o.position = e[1]
		o.rotation.y = rng.randf_range(0.0, TAU)
		add_child(o)

	# Interno buio dietro il bancone
	var back := MeshInstance3D.new()
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(0.2, 2.2, 3.4)
	back.mesh = back_mesh
	back.position = Vector3(-0.1, 1.35, 0)
	var back_mat := StandardMaterial3D.new()
	back_mat.albedo_color = Color(0.1, 0.09, 0.09)
	back.material_override = back_mat
	add_child(back)

	# L'insegna: T bianca su fondo blu, la cosa più riconoscibile d'Italia
	var sign_bg := MeshInstance3D.new()
	var sign_mesh := BoxMesh.new()
	sign_mesh.size = Vector3(0.12, 1.0, 1.0)
	sign_bg.mesh = sign_mesh
	sign_bg.position = Vector3(0.75, 3.5, 0)
	var sign_mat := StandardMaterial3D.new()
	sign_mat.albedo_color = Color(0.06, 0.15, 0.45)
	sign_mat.emission_enabled = true
	sign_mat.emission = Color(0.1, 0.2, 0.6)
	sign_mat.emission_energy_multiplier = 0.8
	sign_bg.material_override = sign_mat
	add_child(sign_bg)

	var white := StandardMaterial3D.new()
	white.albedo_color = Color(0.98, 0.98, 0.96)
	white.emission_enabled = true
	white.emission = Color(0.9, 0.9, 0.95)
	white.emission_energy_multiplier = 0.9
	# La "T": barra orizzontale + gambo verticale
	var bar := MeshInstance3D.new()
	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(0.06, 0.16, 0.62)
	bar.mesh = bar_mesh
	bar.position = Vector3(0.82, 3.78, 0)
	bar.material_override = white
	add_child(bar)

	var stem := MeshInstance3D.new()
	var stem_mesh := BoxMesh.new()
	stem_mesh.size = Vector3(0.06, 0.62, 0.16)
	stem.mesh = stem_mesh
	stem.position = Vector3(0.82, 3.42, 0)
	stem.material_override = white
	add_child(stem)

	for side in [-1.0, 1.0]:
		var label := Label3D.new()
		label.text = "TABACCHI"
		label.font_size = 44
		label.pixel_size = 0.004
		label.modulate = Color(0.95, 0.92, 0.8)
		label.outline_size = 6
		label.outline_modulate = Color(0.1, 0.1, 0.12)
		label.position = Vector3(0.62, 2.35, side * 0.02)
		label.rotation.y = deg_to_rad(90.0) * (-side)
		add_child(label)


func _build_collision() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.4, 3.2, 3.4)
	shape.position = Vector3(0.2, 1.6, 0)
	shape.shape = box
	add_child(shape)


func get_interact_prompt(_from_position: Vector3) -> String:
	var lot := ""
	var quante: int = GameManager.lotto_quante_aperte()
	if quante > 0:
		lot = " · [2] 'o lotto (tiene %d giocate pe' stasera)" % quante
	else:
		lot = " · [2] 'o lotto"
	return "TABACCHI — [E] sigarette €%d · [1] tre caffè €%d%s  (ne hai %d e %d)" % [
		GameManager.CIGARETTE_PACK_COST,
		GameManager.CAFFE_COST * GameManager.CAFFE_PER_GIRO,
		lot, GameManager.cigarettes, GameManager.caffe]


func player_interact() -> void:
	if GameManager.buy_cigarettes():
		SoundManager.play("coin")
		_say("%s (%d sigarette)" % [SAY_SOLD[randi() % SAY_SOLD.size()], GameManager.cigarettes])
	else:
		SoundManager.play("fail", -8.0, 0.9)
		_say(SAY_NO_MONEY)


## Il caffè si prende al banco: e' l'unico consumabile che si beve subito e
## si sente nelle gambe. Tre alla volta, che uno solo non basta mai.
# ---------------------------------------------------------------------------
# 'O LOTTO
# ---------------------------------------------------------------------------
#
# **'O tabaccaio è 'o banco d''o lotto**, e a Napoli non è un dettaglio: è
# metà del motivo per cui uno ci entra. Le sigarette le compri e te ne
# vai; la schedina la giochi e poi ci torni a vedere com'è andata, e nel
# frattempo ci pensi.
#
# Il pannello è uno solo per tutta la partita — si costruisce la prima
# volta che serve e resta appeso alla radice — perché dentro ci sono
# novanta bottoni e rifarli a ogni apertura è uno spreco che si sente.
const PannelloLotto := preload("res://scripts/pannello_lotto.gd")

static var _lotto_panel: CanvasLayer = null


func apri_lotto() -> void:
	if _lotto_panel == null or not is_instance_valid(_lotto_panel):
		_lotto_panel = PannelloLotto.new()
		_lotto_panel.name = "PannelloLotto"
		get_tree().root.add_child(_lotto_panel)
	_say("Dimme 'e nummere, guagliò.")
	_lotto_panel.apri()


func compra_voce(indice: int) -> void:
	if indice == 1:
		apri_lotto()
		return
	if indice != 0:
		return
	if GameManager.buy_caffe():
		SoundManager.play("coin")
		_say("Tre cafè! (ne tiene %d)" % GameManager.caffe)
	else:
		SoundManager.play("fail", -8.0, 0.9)
		_say(SAY_NO_MONEY)


func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or player.get("current_target") != self:
		return
	if Input.is_action_just_pressed("buy_1"):
		compra_voce(0)
	elif Input.is_action_just_pressed("buy_2"):
		compra_voce(1)
