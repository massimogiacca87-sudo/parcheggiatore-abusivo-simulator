extends StaticBody3D
## Bazar3D — "TUTTO PE' 'A CASA"
## Il negozio di casalinghi e cineserie della piazza: qui si comprano le
## decorazioni (sedia, ombrellone, tavolino, radio, piante, luminarie) che
## compaiono davvero nel tuo angolo di piazza. Tasti 1-6 guardando il negozio.

const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const Tex := preload("res://scripts/textures.gd")

const SAY_SOLD := ["Bellissimo, 'na bellezza!", "Guagliò, hê fatto 'affare.", "Te lo 'ncarto? No? Va buo'."]
const SAY_NO_MONEY := "Prima 'e sorde, poi 'a merce."
const SAY_HAVE := "Già ce l'hê! Vuò 'o bis?"

var _bubble: Node3D


func _ready() -> void:
	add_to_group("shop")
	add_to_group("bazar")
	collision_layer = 1
	collision_mask = 0
	_build_visual()
	_build_collision()
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 3.2, 0)
	add_child(_bubble)


func _say(text: String) -> void:
	if _bubble:
		_bubble.say(text)
	GameManager.directing_gesture.emit("« Bazar »: %s" % text, true)


func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or player.get("current_target") != self:
		return
	# Come da 'O Zio: l'elenco e' quello di GameManager, non una copia.
	for i in GameManager.DECOR_IDS.size():
		if Input.is_action_just_pressed("buy_%d" % (i + 1)):
			_try_buy(str(GameManager.DECOR_IDS[i]))
			return
	# (0.64) L'ultima voce: 'a pittura janca, tasto 7.
	if Input.is_action_just_pressed("buy_%d" % (GameManager.DECOR_IDS.size() + 1)):
		_compra_pittura()


## Compra la voce numero `indice` del listino. La usa il joypad.
func compra_voce(indice: int) -> void:
	if indice == GameManager.DECOR_IDS.size():
		_compra_pittura()
		return
	if indice < 0 or indice >= GameManager.DECOR_IDS.size():
		return
	_try_buy(str(GameManager.DECOR_IDS[indice]))


const SAY_PITTURA := ["'O janco d''o Comune, overo: nun se ne va manco cu 'a pioggia.",
	"Pittura e pennello. Ma che hê 'a pittà, 'e strisce?", "Cchiù janco d''o janco."]


## **'A pittura janca c''o pennello** (0.64). Sta qui perché il bazar vende
## tutto pe' 'a casa, e un barattolo di vernice è tutto pe' 'a casa. Serve a
## ripittare di bianco le strisce blu del Comune (vedi 'E STRISCE BLU).
func _compra_pittura() -> void:
	if not GameManager.scegli_in_negozio("pittura"):
		SoundManager.play("pop", -12.0, 1.15)
		_say("Pittura janca c''o pennello, €%d: %d passate, 'nu posto pe' passata."
			% [GameManager.PITTURA_COSTO, GameManager.PITTURA_PASSATE])
		return
	if GameManager.accatta_pittura():
		SoundManager.play("kaching")
		_say(SAY_PITTURA[randi() % SAY_PITTURA.size()])
		GameManager.event_started.emit("Pittura janca: %d passate 'n sacca." % GameManager.pittura)
	else:
		SoundManager.play("fail", -8.0, 0.9)
		_say(SAY_NO_MONEY)


func _try_buy(item_id: String) -> void:
	# Le decorazioni non si "possiedono": se ne accumulano copie. Il
	# negozio dice basta solo al tetto.
	if GameManager.decor_possedute(item_id) >= GameManager.DECOR_MAX_COPIE:
		GameManager.scegli_in_negozio(item_id)
		_say(SAY_HAVE)
		return
	# Primo tasto: la scheda. Secondo tasto sullo stesso oggetto: si compra.
	if not GameManager.scegli_in_negozio(item_id):
		SoundManager.play("pop", -12.0, 1.15)
		var info: Dictionary = GameManager.UPGRADES[item_id]
		_say("%s, €%d. %s" % [str(info["name"]), int(info["cost"]),
			str(info["desc"])])
		return
	if GameManager.buy_upgrade(item_id):
		SoundManager.play("kaching")
		_say(SAY_SOLD[randi() % SAY_SOLD.size()])
	else:
		SoundManager.play("fail", -8.0, 0.9)
		_say(SAY_NO_MONEY)


## Il fronte del negozio. Il bazar è quel posto dove la merce sta più fuori
## che dentro: bacinelle, scope, pentole appese, secchi impilati, e una
## girandola di roba di plastica colorata. Prima erano sette cubi colorati
## e tre cilindri, e si vedeva.
func _build_visual() -> void:
	_build_shopfront()
	_build_awning()
	_build_merce()
	_build_luce()
	_build_insegna()


## Vetrina con telaio, zoccolatura e serranda mezza tirata su.
func _build_shopfront() -> void:
	var frame_mat := Tex.flat(Color(0.16, 0.32, 0.22), 0.7)   # verde bottiglia
	var glass := Tex.flat(Color(0.32, 0.42, 0.45), 0.1, 0.75)
	glass.emission_enabled = true
	glass.emission = Color(1.0, 0.92, 0.7)
	glass.emission_energy_multiplier = 0.35

	# Il vetro, rientrato rispetto al telaio
	var window := MeshInstance3D.new()
	var win_mesh := BoxMesh.new()
	win_mesh.size = Vector3(0.1, 2.0, 3.6)
	window.mesh = win_mesh
	window.position = Vector3(0.02, 1.55, 0)
	window.material_override = glass
	add_child(window)

	# Telaio: montanti, architrave e zoccolo
	for sz in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.2, 2.6, 0.22)
		post.mesh = pm
		post.position = Vector3(0.1, 1.3, sz * 1.9)
		post.material_override = frame_mat
		add_child(post)

	var lintel := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(0.22, 0.26, 4.0)
	lintel.mesh = lm
	lintel.position = Vector3(0.1, 2.62, 0)
	lintel.material_override = frame_mat
	add_child(lintel)

	var kick := MeshInstance3D.new()
	var km := BoxMesh.new()
	km.size = Vector3(0.24, 0.55, 4.0)
	kick.mesh = km
	kick.position = Vector3(0.1, 0.28, 0)
	kick.material_override = frame_mat
	add_child(kick)

	# Montante centrale: due vetrine invece di una lastra sola
	var mullion := MeshInstance3D.new()
	var mm := BoxMesh.new()
	mm.size = Vector3(0.16, 2.0, 0.12)
	mullion.mesh = mm
	mullion.position = Vector3(0.09, 1.55, 0)
	mullion.material_override = frame_mat
	add_child(mullion)

	# Serranda mezza tirata su, con le doghe
	var shutter_mat := Tex.flat(Color(0.62, 0.63, 0.6), 0.5, 0.4)
	for i in range(5):
		var slat := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(0.06, 0.09, 3.9)
		slat.mesh = sm
		slat.position = Vector3(-0.02, 2.44 - i * 0.1, 0)
		slat.material_override = shutter_mat
		add_child(slat)


## Il tendone a strisce, con la mantovana ondulata e i tiranti.
func _build_awning() -> void:
	var colors := [Color(0.13, 0.42, 0.24), Color(0.95, 0.93, 0.88)]
	for i in range(8):
		var strip := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(1.5, 0.05, 0.52)
		strip.mesh = sm
		strip.position = Vector3(0.82, 3.02, -1.82 + i * 0.52)
		strip.rotation.z = -0.24
		var mat := Tex.flat(colors[i % 2], 0.95)
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		strip.material_override = mat
		add_child(strip)

		# Mantovana: il bordo smerlato che pende davanti
		var valance := MeshInstance3D.new()
		var vm := BoxMesh.new()
		vm.size = Vector3(0.03, 0.24, 0.5)
		valance.mesh = vm
		valance.position = Vector3(1.53, 2.72, -1.82 + i * 0.52)
		valance.material_override = strip.material_override
		add_child(valance)

	# Tiranti
	for sz in [-1.7, 1.7]:
		var rod := MeshInstance3D.new()
		var rm := CylinderMesh.new()
		rm.top_radius = 0.025
		rm.bottom_radius = 0.025
		rm.height = 1.75
		rod.mesh = rm
		rod.position = Vector3(0.8, 3.05, sz)
		rod.rotation.z = deg_to_rad(76)
		rod.material_override = Tex.flat(Color(0.35, 0.35, 0.37), 0.4, 0.6)
		add_child(rod)


## La merce fuori: è questa che fa il bazar.
func _build_merce() -> void:
	# **'E culure d''a plastica erano culure 'e Lego.**
	#
	# Rosso puro, blu puro, giallo puro, a rugosità mezza: in mezzo a muri
	# fotografici quella roba non sembrava merce, sembrava un gioco da
	# bambini rovesciato in piazza. La plastica da due euro È colorata, ma
	# è colorata *sporca*: pigmento economico, stampata male, impolverata
	# dal traffico. Stessi colori, tirati giù di saturazione e alzati di
	# rugosità.
	var plastic := [
		Color(0.64, 0.25, 0.20), Color(0.21, 0.36, 0.54),
		Color(0.78, 0.63, 0.22), Color(0.26, 0.47, 0.33),
		Color(0.50, 0.33, 0.46), Color(0.74, 0.44, 0.20),
		Color(0.80, 0.78, 0.73), Color(0.34, 0.34, 0.36),
	]
	var metal := Tex.flat(Color(0.74, 0.75, 0.78), 0.28, 0.85)
	var wood := Tex.flat(Color(0.66, 0.48, 0.28), 0.9)

	# --- Torri di bacinelle impilate (il classico) ---
	for t in range(3):
		var base_z: float = -1.5 + t * 1.5
		var n: int = 4 + (t % 3)
		# **'Na torre 'e bacinelle è 'e nu culore sulo.** Prima il colore
		# cambiava a ogni pezzo e ne usciva una torre arcobaleno: le
		# bacinelle si comprano a stock, e uno stock è di un colore.
		var col_torre: Color = plastic[(t * 3 + 1) % plastic.size()]
		for i in range(n):
			var basin := MeshInstance3D.new()
			var bm := CylinderMesh.new()
			bm.top_radius = 0.3
			bm.bottom_radius = 0.22
			bm.height = 0.12
			bm.radial_segments = 14
			basin.mesh = bm
			basin.position = Vector3(1.15, 0.07 + i * 0.09, base_z)
			basin.rotation.y = randf_range(-0.3, 0.3)
			basin.material_override = Tex.flat(
				col_torre.darkened(float(i) * 0.035), 0.74)
			add_child(basin)

	# --- Secchi con dentro le scope e gli spazzoloni ---
	for sz in [-2.0, 2.05]:
		var bucket := MeshInstance3D.new()
		var bkm := CylinderMesh.new()
		bkm.top_radius = 0.26
		bkm.bottom_radius = 0.2
		bkm.height = 0.42
		bkm.radial_segments = 14
		bucket.mesh = bkm
		bucket.position = Vector3(1.35, 0.21, sz)
		bucket.material_override = Tex.flat(plastic[randi() % plastic.size()], 0.74)
		add_child(bucket)

		for i in range(4):
			var handle := MeshInstance3D.new()
			var hm := CylinderMesh.new()
			hm.top_radius = 0.022
			hm.bottom_radius = 0.022
			hm.height = 1.5
			handle.mesh = hm
			var lean := Vector3(randf_range(-0.1, 0.1), 0, randf_range(-0.1, 0.1))
			handle.position = Vector3(1.35, 0.95, sz) + lean * 3.0
			handle.rotation = Vector3(lean.z * 1.6, 0, -lean.x * 1.6)
			handle.material_override = wood
			add_child(handle)

			# Il ciuffo della scopa in cima o in fondo
			var head := MeshInstance3D.new()
			var hdm := BoxMesh.new()
			hdm.size = Vector3(0.3, 0.1, 0.09)
			head.mesh = hdm
			head.position = handle.position + Vector3(0, 0.78, 0)
			head.rotation = handle.rotation
			head.material_override = Tex.flat(
				plastic[(i + 2) % plastic.size()], 0.8)
			add_child(head)

	# --- Pentole appese sotto il tendone ---
	for i in range(6):
		var z: float = -1.6 + i * 0.62
		var pot := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.17 + (i % 3) * 0.03
		pm.bottom_radius = pm.top_radius * 0.85
		pm.height = 0.2
		pm.radial_segments = 14
		pot.mesh = pm
		pot.position = Vector3(1.35, 2.28 - (i % 2) * 0.18, z)
		pot.material_override = metal
		add_child(pot)

		var hook := MeshInstance3D.new()
		var km := CylinderMesh.new()
		km.top_radius = 0.012
		km.bottom_radius = 0.012
		km.height = 0.3
		hook.mesh = km
		hook.position = pot.position + Vector3(0, 0.24, 0)
		hook.material_override = metal
		add_child(hook)

	# --- Stendino con gli strofinacci colorati ---
	var wire := MeshInstance3D.new()
	var wm := CylinderMesh.new()
	wm.top_radius = 0.012
	wm.bottom_radius = 0.012
	wm.height = 3.4
	wire.mesh = wm
	wire.rotation.x = deg_to_rad(90)
	wire.position = Vector3(1.55, 1.72, 0)
	wire.material_override = Tex.flat(Color(0.3, 0.3, 0.32), 0.6)
	add_child(wire)

	for i in range(9):
		var cloth := MeshInstance3D.new()
		var cm := BoxMesh.new()
		cm.size = Vector3(0.02, 0.36, 0.26)
		cloth.mesh = cm
		cloth.position = Vector3(1.55, 1.53, -1.5 + i * 0.38)
		cloth.rotation.z = randf_range(-0.06, 0.06)
		var mat := Tex.flat(plastic[i % plastic.size()].lightened(0.25), 0.95)
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		cloth.material_override = mat
		add_child(cloth)

	# --- Cassette di roba mista a terra ---
	for i in range(3):
		var crate := MeshInstance3D.new()
		var cm2 := BoxMesh.new()
		cm2.size = Vector3(0.5, 0.32, 0.66)
		crate.mesh = cm2
		crate.position = Vector3(1.75, 0.16, -1.4 + i * 1.4)
		crate.rotation.y = randf_range(-0.2, 0.2)
		crate.material_override = wood
		add_child(crate)

		# Quello che spunta fuori dalla cassetta
		for k in range(4):
			var item := MeshInstance3D.new()
			var im := BoxMesh.new()
			im.size = Vector3(0.11, 0.2, 0.11)
			item.mesh = im
			item.position = crate.position + Vector3(
				randf_range(-0.14, 0.14), 0.24, randf_range(-0.22, 0.22))
			item.rotation.y = randf_range(0.0, TAU)
			item.material_override = Tex.flat(
				plastic[(i * 3 + k) % plastic.size()], 0.6)
			add_child(item)


## L'insegna dipinta sopra il tendone, coi prezzi scritti a mano di fianco.
## La luce del negozio. Il bazar sta sotto i palazzi del lato ovest e per
## mezza giornata è in ombra piena: senza una lampada, tutta la merce nuova
## si vedeva blu scuro e non serviva a niente averla fatta.
func _build_luce() -> void:
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(1.3, 2.55, 0)
	lamp.light_color = Color(1.0, 0.9, 0.72)
	lamp.light_energy = 3.2
	lamp.omni_range = 8.0
	lamp.omni_attenuation = 1.4
	lamp.shadow_enabled = false # in GL Compatibility le ombre omni costano care
	add_child(lamp)

	# Il neon sotto il tendone, che si vede acceso
	for sz in [-1.2, 1.2]:
		var tube := MeshInstance3D.new()
		var tm := CylinderMesh.new()
		tm.top_radius = 0.035
		tm.bottom_radius = 0.035
		tm.height = 1.5
		tube.mesh = tm
		tube.rotation.x = deg_to_rad(90)
		tube.position = Vector3(1.1, 2.62, sz)
		var glow := Tex.flat(Color(1.0, 0.96, 0.86), 0.3)
		glow.emission_enabled = true
		glow.emission = Color(1.0, 0.93, 0.75)
		glow.emission_energy_multiplier = 3.0
		tube.material_override = glow
		add_child(tube)


func _build_insegna() -> void:
	var board := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.12, 0.62, 4.0)
	board.mesh = bm
	board.position = Vector3(0.16, 3.32, 0)
	board.material_override = Tex.flat(Color(0.11, 0.28, 0.18), 0.9)
	add_child(board)

	for side in [-1.0, 1.0]:
		var label := Label3D.new()
		label.text = "TUTTO PE' 'A CASA"
		label.font_size = 40
		label.pixel_size = 0.004
		label.modulate = Color(0.99, 0.94, 0.72)
		label.outline_size = 7
		label.outline_modulate = Color(0.06, 0.16, 0.1)
		label.position = Vector3(0.24, 3.32, side * 0.02)
		label.rotation.y = deg_to_rad(90.0) * (-side)
		add_child(label)

		var sub := Label3D.new()
		sub.text = "casalinghi · plastica · ferramenta"
		sub.font_size = 20
		sub.pixel_size = 0.004
		sub.modulate = Color(0.9, 0.88, 0.78)
		sub.outline_size = 5
		sub.outline_modulate = Color(0.06, 0.16, 0.1)
		sub.position = Vector3(0.24, 3.02, side * 0.02)
		sub.rotation.y = deg_to_rad(90.0) * (-side)
		add_child(sub)


func _build_collision() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.6, 3.0, 4.2)
	shape.position = Vector3(0.4, 1.5, 0)
	shape.shape = box
	add_child(shape)


func get_interact_prompt(_from_position: Vector3) -> String:
	return "BAZAR — decorazioni per il tuo angolo di piazza (listino qui a fianco)"


func player_interact() -> void:
	_say("Guarda 'o listino, guagliò: tasti 1-6.")
