extends StaticBody3D
## Shop3D — Il banchetto di 'O Zio
## Il ricettatore di quartiere: compra tutti gli stemmi rubati, senza fare
## domande. Avvicinati e premi E per vendere l'intero inventario.

const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const Tex := preload("res://scripts/textures.gd")
const Human := preload("res://scripts/human_builder.gd")

const SAY_SOLD := ["Bello 'sto stemma! Affare fatto.", "E chi l'ha visto niente...", "Robba fina, guaglió."]
const SAY_EMPTY := "Nun tiene niente pe' mme. Torna quanno tiene 'a robba."
const SAY_UPGRADE := "Robba 'e prima qualità, fidati d''O Zio."
const SAY_NO_MONEY := "Senza sorde nun se canta 'a messa."

var _bubble: Node3D


func _ready() -> void:
	add_to_group("shop")
	collision_layer = 1 # layer mondo: il raggio di interazione lo colpisce
	collision_mask = 0
	_build_visual()
	_build_collision()
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(-0.7, 2.6, 0)
	add_child(_bubble)


func _say(text: String) -> void:
	if _bubble:
		_bubble.say(text)
	GameManager.directing_gesture.emit("« 'O Zio »: %s" % text, true)


## Acquisti al banchetto: tasti 1-6 mentre lo guardi.
##
## L'elenco NON e' piu' scritto a mano qui: si legge da GameManager.TOOL_IDS,
## che e' la stessa lista che l'interfaccia disegna a schermo. Prima erano
## due elenchi separati e si erano disallineati — il pannello scriveva
## "[4] Occhiali da Sole" e il tasto 4 comprava la sedia sdraio.
func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or player.get("current_target") != self:
		return
	for i in GameManager.TOOL_IDS.size():
		if Input.is_action_just_pressed("buy_%d" % (i + 1)):
			_try_buy(str(GameManager.TOOL_IDS[i]))
			return


## Compra la voce numero `indice` del listino (0 = la prima). La usa anche
## il joypad, che non ha i numeri e sceglie con la croce direzionale.
func compra_voce(indice: int) -> void:
	if indice < 0 or indice >= GameManager.TOOL_IDS.size():
		return
	_try_buy(str(GameManager.TOOL_IDS[indice]))


func _try_buy(upgrade_id: String) -> void:
	if GameManager.has_upgrade(upgrade_id):
		GameManager.scegli_in_negozio(upgrade_id) # si può comunque rileggere
		return
	# Primo tasto: si guarda. Secondo tasto sullo stesso oggetto: si paga.
	if not GameManager.scegli_in_negozio(upgrade_id):
		SoundManager.play("pop", -12.0, 1.15)
		var info: Dictionary = GameManager.UPGRADES[upgrade_id]
		_say("%s, €%d. %s" % [str(info["name"]), int(info["cost"]),
			str(info["desc"])])
		return
	if GameManager.buy_upgrade(upgrade_id):
		SoundManager.play("coin")
		_say(SAY_UPGRADE)
	else:
		SoundManager.play("fail", -8.0, 0.9)
		_say(SAY_NO_MONEY)


func _build_visual() -> void:
	# Tavolo
	var table := MeshInstance3D.new()
	var table_mesh := BoxMesh.new()
	table_mesh.size = Vector3(0.9, 0.85, 2.0)
	table.mesh = table_mesh
	table.position = Vector3(0, 0.425, 0)
	var table_mat := StandardMaterial3D.new()
	table_mat.albedo_color = Color(0.45, 0.3, 0.18)
	table.material_override = table_mat
	add_child(table)

	# Tovaglia
	var cloth := MeshInstance3D.new()
	var cloth_mesh := BoxMesh.new()
	cloth_mesh.size = Vector3(0.95, 0.04, 2.05)
	cloth.mesh = cloth_mesh
	cloth.position = Vector3(0, 0.87, 0)
	var cloth_mat := StandardMaterial3D.new()
	cloth_mat.albedo_color = Color(0.7, 0.15, 0.15)
	cloth.material_override = cloth_mat
	add_child(cloth)

	# Pali e tendone a strisce
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.3, 0.3, 0.32)
	for pz in [-0.95, 0.95]:
		var pole := MeshInstance3D.new()
		var pole_mesh := CylinderMesh.new()
		pole_mesh.top_radius = 0.03
		pole_mesh.bottom_radius = 0.03
		pole_mesh.height = 2.1
		pole.mesh = pole_mesh
		pole.position = Vector3(0.35, 1.05, pz)
		pole.material_override = pole_mat
		add_child(pole)

	var awning_colors := [Color(0.85, 0.2, 0.2), Color(0.92, 0.9, 0.85)]
	for i in range(4):
		var strip := MeshInstance3D.new()
		var strip_mesh := BoxMesh.new()
		strip_mesh.size = Vector3(1.1, 0.03, 0.55)
		strip.mesh = strip_mesh
		strip.position = Vector3(0.1, 2.12, -0.825 + i * 0.55)
		strip.rotation.z = -0.18
		var strip_mat := StandardMaterial3D.new()
		strip_mat.albedo_color = awning_colors[i % 2]
		strip.material_override = strip_mat
		add_child(strip)

	# 'O Zio in persona, dietro il banco
	var zio_parts := Human.build(Color(0.22, 0.22, 0.26), Color(0.16, 0.16, 0.2),
		"zio", 1.78, {"moustache": true, "belly": 0.9, "bald": true})
	var zio_root: Node3D = zio_parts["root"]
	zio_root.position = Vector3(-0.75, 0, 0)
	zio_root.rotation.y = -PI / 2.0 # guarda verso il cliente (+X locale)
	add_child(zio_root)

	# Occhiali scuri: 'O Zio non guarda mai nessuno negli occhi
	if zio_parts["head"] != null:
		var glasses := MeshInstance3D.new()
		var glasses_mesh := BoxMesh.new()
		glasses_mesh.size = Vector3(0.26, 0.055, 0.05)
		glasses.mesh = glasses_mesh
		glasses.position = Vector3(0, 0.16, -0.115)
		glasses.material_override = Tex.flat(Color(0.04, 0.04, 0.05), 0.15, 0.5)
		zio_parts["head"].add_child(glasses)

		var chain := MeshInstance3D.new()
		var chain_mesh := TorusMesh.new()
		chain_mesh.inner_radius = 0.075
		chain_mesh.outer_radius = 0.09
		chain.mesh = chain_mesh
		chain.rotation.x = deg_to_rad(80)
		chain.position = Vector3(-0.75, 1.32, -0.06)
		chain.material_override = Tex.flat(Color(0.9, 0.78, 0.25), 0.15, 1.0, 0.3)
		add_child(chain)

	# Insegna luminosa
	var sign_node := MeshInstance3D.new()
	var sign_mesh := BoxMesh.new()
	sign_mesh.size = Vector3(0.08, 0.5, 1.9)
	sign_node.mesh = sign_mesh
	sign_node.position = Vector3(-1.1, 2.4, 0)
	var sign_mat := StandardMaterial3D.new()
	sign_mat.albedo_color = Color(0.95, 0.75, 0.15)
	sign_mat.emission_enabled = true
	sign_mat.emission = Color(1.0, 0.7, 0.1)
	sign_mat.emission_energy_multiplier = 1.2
	sign_node.material_override = sign_mat
	add_child(sign_node)


func _build_collision() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.6, 2.4, 2.2)
	shape.position = Vector3(-0.2, 1.2, 0)
	shape.shape = box
	add_child(shape)


func get_interact_prompt(_from_position: Vector3) -> String:
	# Il listino completo appare nel pannello dell'HUD: qui solo la riga chiave.
	var count := GameManager.emblem_count()
	if count > 0:
		return "E: vendi %d stemm%s (€%d) — listino qui a fianco" % [count, ("o" if count == 1 else "i"), GameManager.emblems_total_value()]
	return "'O Zio compra stemmi e vende robba buona (listino a fianco)"


func player_interact() -> void:
	# **Quanta robba staje vennenno**, prima che sparisca dall'inventario:
	# serve sotto, per capire quanto è grossa la ricettazione.
	var quanti: int = GameManager.emblem_count()
	var earned := GameManager.sell_all_emblems()
	if earned > 0:
		SoundManager.play("soldi", 0.0, 0.88)
		_say("%s (+€%d)" % [SAY_SOLD[randi() % SAY_SOLD.size()], earned])
		_si_te_vede_o_vigile(quanti)
	else:
		SoundManager.play("fail", -10.0, 0.9)
		_say(SAY_EMPTY)


## **Ricettazione 'nnanze ô vigile** (0.56, punto 9).
##
## Il capo: *«anche rubare e rivendere stemmi davanti a lui dovrebbe essere
## un problema»*. Rubare lo stemma davanti a lui adesso è flagranza (vedi
## `car_3d._steal_emblem`); rivenderlo è la metà esatta del reato, e finora
## non valeva niente — 'O Zio sta in mezzo alla strada come tutto il resto,
## e potevi svuotargli in mano dodici stemmi con il vigile a cinque metri.
##
## Quanto pesa dipende da quanti ne stai passando: uno è una cosa che si può
## raccontare, sei sono un mestiere. Sotto, però, non si va mai — il minimo
## è già abbastanza da farlo venire a parlare.
func _si_te_vede_o_vigile(quanti: int) -> void:
	var v = GameManager.nu_vigile_te_vede()
	if v == null or not v.has_method("t_ha_visto"):
		return
	var quanto: float = clampf(18.0 + float(quanti) * 9.0, 18.0,
		GameManager.HEAT_MAX)
	v.t_ha_visto(quanto, "E chisto che t'ha dato 'e sorde pe' fa'?")
