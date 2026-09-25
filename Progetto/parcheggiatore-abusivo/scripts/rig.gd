extends Node
class_name Rig
## Rig
## Lo scheletro dei personaggi: una gerarchia di giunti veri (bacino, spina,
## torace, collo, spalle, gomiti, polsi, anche, ginocchia, caviglie) con la
## geometria appesa sopra.
##
## Prima ogni personaggio era una manciata di scatole appese a due soli perni
## (un'anca e una spalla per lato) e la "camminata" era un `sin()` scritto a
## mano dentro ogni script. Con la gerarchia completa le stesse scatole
## diventano animabili da un AnimationPlayer: le ginocchia si piegano, i
## gomiti si piegano, il busto ruota sul passo. Non è una mesh skinnata —
## sono parti rigide, come in un Lego — ma le animazioni sono keyframe veri,
## interpolati e mescolati da un AnimationTree.
##
## Nomi dei giunti (sono anche i nomi dei nodi, e quindi i percorsi delle
## tracce di animazione):
##   hips → spine → chest → neck → head
##                       → shoulder_l → elbow_l → hand_l
##                       → shoulder_r → elbow_r → hand_r
##        → thigh_l → knee_l → foot_l
##        → thigh_r → knee_r → foot_r

const Tex := preload("res://scripts/textures.gd")

## Proporzioni di riferimento, in metri, per un personaggio alto 1,80.
## Tutto viene poi scalato da `build()` sull'altezza richiesta.
## Altezza del rig a scala 1: bacino + spina + torace + collo + testa +
## calotta. Va tenuta in pari con le costanti qui sotto, altrimenti tutti i
## personaggi risultano più bassi (o più alti) di quello che chiedono.
const REF_HEIGHT := 1.88

## Il bacino sta abbastanza in alto da far poggiare la scarpa sull'asfalto:
## 0,97 = 0,06 (attacco anca) + 0,44 (coscia) + 0,43 (tibia) + 0,04 (caviglia).
const HIP_Y := 0.97
const SPINE_Y := 0.18
const CHEST_Y := 0.22
const NECK_Y := 0.20
## Larghezza di mezza spalla. Era 0,285 — cioè spalle larghe 57 cm PIÙ i
## deltoidi, quasi 70: la misura di un armadio, non di una persona alta
## 1,88 (la vera è intorno ai 46 cm da deltoide a deltoide).
## Larghezza di mezza spalla. Era 0,285 — spalle larghe 57 cm PIÙ i
## deltoidi, quasi settanta: la misura di un armadio. Da deltoide a
## deltoide una persona alta 1,88 sta sui 47 cm, che con la pallina di
## spalla da 7,2 vuol dire 0,175 per lato.
const SHOULDER_X := 0.205
const SHOULDER_Y := 0.115
const UPPER_ARM := 0.29
const FOREARM := 0.27
const THIGH_X := 0.11
const THIGH := 0.44
const SHIN := 0.43


## Costruisce lo scheletro e ci appende le scatole.
## Ritorna un Dictionary con: root, bones (nome → Node3D), head, e le liste
## legs/arms per compatibilità con il codice vecchio.
static func build(shirt_color: Color, pants_color: Color, height: float,
		options: Dictionary = {}) -> Dictionary:
	var root := Node3D.new()
	root.name = "Rig"
	var bones := {}
	var result := {"root": root, "bones": bones, "head": null,
		"legs": [], "arms": []}

	var skin_col: Color = options.get("skin", Color(0.86, 0.68, 0.54))
	var hair_col: Color = options.get("hair", Color(0.18, 0.12, 0.08))
	var belly: float = options.get("belly", 0.4)
	var bald: bool = options.get("bald", false)

	var shirt := Tex.flat(shirt_color, 0.9)
	var pants := Tex.flat(pants_color, 0.9)
	var skin := Tex.flat(skin_col, 0.75)
	var hair := Tex.flat(hair_col, 0.95)
	var shoes := Tex.flat(Color(0.09, 0.08, 0.08), 0.6)
	var dark := Tex.flat(Color(0.12, 0.12, 0.14), 0.8)

	# --- Catena centrale ---
	var hips := _bone(root, bones, "hips", Vector3(0, HIP_Y, 0))
	_box(hips, pants, Vector3(0.30 + belly * 0.05, 0.16, 0.21), Vector3(0, -0.04, 0))
	_box(hips, dark, Vector3(0.325 + belly * 0.07, 0.055, 0.235), Vector3(0, 0.035, 0)) # cintura

	var spine := _bone(hips, bones, "spine", Vector3(0, SPINE_Y, 0))
	# **'O busto rifatto cu 'e mmisure vere.**
	#
	# Prima era tre capsule enormi una dentro all'altra. `_arto` fa una
	# capsula alta `lunghezza + raggio * 2`, e nessuno se n'era accorto: la
	# pancia chiedeva 10 cm di lunghezza con 20 di raggio e ne usciva una
	# **capsula alta mezzo metro**, cioè un pallone che copriva il torace
	# intero. Il torace faceva lo stesso e arrivava sopra al mento — da lì
	# la testa appoggiata sulle spalle senza collo.
	#
	# Misure di riferimento per uno alto 1,88: spalle 46-49 cm da deltoide
	# a deltoide, torace 32 largo e 21 profondo, vita 28. La pancia si
	# aggiunge **davanti e in basso**, che è dove sta.
	#
	# E davanti vuol dire −z: forward(θ) = (−sinθ, 0, −cosθ). Prima la
	# spingeva a +z, e ogni panzone la portava sulla schiena.
	# L'addome: una capsula sola, sempre della stessa misura. La pancia NON
	# si fa gonfiando questa — gonfiandola veniva un uovo largo quanto il
	# torace attaccato davanti, e lo si vedeva come un pezzo staccato.
	_arto(spine, shirt, 0.128, 0.07, Vector3(0, -0.05, 0.0), 0.74, 1.02)
	# 'A panza vera: solo a chi ce l'ha, bassa e **davanti** (−z), e piccola
	# abbastanza da restare dentro alla sagoma del busto invece di uscirne.
	if belly > 0.42:
		var p_forza: float = (belly - 0.42) / 0.58
		_arto(spine, shirt, 0.098 + p_forza * 0.038, 0.05,
			Vector3(0, -0.10, -(0.045 + p_forza * 0.05)),
			1.05 + p_forza * 0.25, 1.0)
	var chest := _bone(spine, bones, "chest", Vector3(0, CHEST_Y, 0))
	# Il torace: due capsule basse e larghe invece di due altissime. La
	# prima e' la cassa toracica, la seconda la fascia delle spalle.
	_arto(chest, shirt, 0.150, 0.11, Vector3(0, -0.03, 0), 0.68, 1.06)
	_arto(chest, shirt, 0.140, 0.09, Vector3(0, 0.07, 0), 0.72, 1.22)
	# **'O colletto se magnava 'o cuollo.** Stava a 0,19 sopra al torace e
	# il collo attacca a 0,20: restava un centimetro di pelle, cioè niente.
	_box(chest, Tex.flat(shirt_color.lightened(0.22), 0.9),
		Vector3(0.24, 0.045, 0.20), Vector3(0, 0.14, 0))
	var neck := _bone(chest, bones, "neck", Vector3(0, NECK_Y, 0))
	_cyl(neck, skin, 0.072, 0.14, Vector3(0, -0.045, 0))

	var head := _bone(neck, bones, "head", Vector3(0, 0.06, 0))
	result["head"] = head
	_build_head(head, skin, hair, hair_col, bald, options)

	# --- Braccia: spalla → gomito → mano ---
	for side in [-1.0, 1.0]:
		var tag: String = "l" if side < 0.0 else "r"
		var shoulder := _bone(chest, bones, "shoulder_" + tag,
			Vector3(side * SHOULDER_X, SHOULDER_Y, 0))
		# Il deltoide: la pallina di spalla. Senza, il braccio spunta dal
		# torace come un manico infilato in un pupazzo.
		_giunto(shoulder, shirt, 0.074)
		# La capsula era lunga quanto tutto il braccio più i suoi due poli:
		# spuntava cinque centimetri SOPRA la spalla e, con la pallina del
		# deltoide, faceva una spallina da giacca anni Ottanta.
		_arto(shoulder, shirt, 0.060, UPPER_ARM - 0.11,
			Vector3(0, -UPPER_ARM * 0.52, 0), 0.92)

		var elbow := _bone(shoulder, bones, "elbow_" + tag, Vector3(0, -UPPER_ARM, 0))
		_giunto(elbow, skin, 0.052)
		_arto(elbow, skin, 0.049, FOREARM - 0.09,
			Vector3(0, -FOREARM * 0.52, 0), 0.86)

		var hand := _bone(elbow, bones, "hand_" + tag, Vector3(0, -FOREARM, 0))
		# La mano: palmo, blocco delle dita e pollice. Tre pezzi. A questa
		# scala (dieci centimetri) tre bastano — quello che si legge di una
		# mano che ciondola e' la sagoma, e la sagoma ha un pollice.
		_arto(hand, skin, 0.040, 0.045, Vector3(0, -0.042, 0), 0.55, 1.15)
		_arto(hand, skin, 0.031, 0.048, Vector3(0, -0.088, 0.004), 0.52, 1.05)
		_arto(hand, skin, 0.021, 0.030,
			Vector3(0.036 * -side, -0.052, 0.012), 0.9)
		result["arms"].append(shoulder)

	# --- Gambe: anca → ginocchio → piede ---
	for side in [-1.0, 1.0]:
		var tag: String = "l" if side < 0.0 else "r"
		var thigh := _bone(hips, bones, "thigh_" + tag,
			Vector3(side * THIGH_X, -0.06, 0))
		_giunto(thigh, pants, 0.088)
		# La coscia si assottiglia verso il ginocchio: due capsule
		# concentriche di raggio diverso lo fanno senza un mesh su misura.
		_arto(thigh, pants, 0.086, THIGH * 0.55, Vector3(0, -THIGH * 0.30, 0), 0.92)
		_arto(thigh, pants, 0.072, THIGH * 0.5, Vector3(0, -THIGH * 0.72, 0), 0.92)

		var knee := _bone(thigh, bones, "knee_" + tag, Vector3(0, -THIGH, 0))
		_giunto(knee, pants, 0.066)
		# Il polpaccio: grosso in alto, sottile alla caviglia.
		_arto(knee, pants, 0.070, SHIN * 0.42, Vector3(0, -SHIN * 0.26, -0.008), 0.90)
		_arto(knee, pants, 0.050, SHIN * 0.44, Vector3(0, -SHIN * 0.72, 0), 0.92)

		var foot := _bone(knee, bones, "foot_" + tag, Vector3(0, -SHIN, 0))
		# La scarpa poggia sopra la caviglia, non sotto: con l'origine a -0,05
		# il piede finiva dieci centimetri dentro l'asfalto.
		# Adesso sono due pezzi: il corpo della scarpa e la punta
		# arrotondata. Una scarpa a scatola e' l'ultima cosa che tradisce un
		# personaggio, perche' sta sempre nel campo visivo di chi guarda in
		# basso.
		_box(foot, shoes, Vector3(0.135, 0.085, 0.21), Vector3(0, 0.015, -0.04))
		_arto(foot, shoes, 0.062, 0.05, Vector3(0, 0.012, -0.145), 0.9, 1.05)
		result["legs"].append(thigh)

	# Scala tutto sull'altezza voluta
	var k: float = height / REF_HEIGHT
	if not is_equal_approx(k, 1.0):
		root.scale = Vector3.ONE * k
	return result


## Un giunto: un Node3D nudo con un nome, che è anche il pezzo di percorso
## usato dalle tracce di animazione.
static func _bone(parent: Node3D, bones: Dictionary, bone_name: String,
		pos: Vector3) -> Node3D:
	var b := Node3D.new()
	b.name = bone_name
	b.position = pos
	parent.add_child(b)
	bones[bone_name] = b
	return b


static func _box(parent: Node3D, mat: Material, size: Vector3,
		pos: Vector3) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	m.mesh = mesh
	m.position = pos
	m.material_override = mat
	parent.add_child(m)
	return m


## Un arto: una capsula, non una scatola.
##
## E' il cambio che ha fatto piu' differenza di tutti. Un braccio a
## parallelepipedo si riconosce come parallelepipedo da qualunque distanza:
## ha quattro spigoli vivi che prendono la luce tutti nello stesso modo e
## niente li smussa. Una capsula ha la sezione tonda, quindi ha un gradiente
## di luce lungo tutta la lunghezza, e i due poli chiudono l'arto invece di
## troncarlo.
##
## `piatto` schiaccia la sezione: un avambraccio non e' un tubo, e' un ovale.
static func _arto(parent: Node3D, mat: Material, raggio: float,
		lunghezza: float, pos: Vector3, piatto: float = 0.85,
		largo: float = 1.0) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = raggio
	mesh.height = lunghezza + raggio * 2.0
	# Otto lati e tre anelli: da vicino la capsula si legge come un prisma,
	# ed è metà del "sembra fatto di Lego". Dodici e quattro costano una
	# manciata di triangoli in più su un personaggio che ne ha poche
	# centinaia, e la luce ci scorre sopra invece di scalinare.
	mesh.radial_segments = 12
	mesh.rings = 4
	m.mesh = mesh
	m.position = pos
	m.scale = Vector3(largo, 1.0, piatto)
	m.material_override = mat
	parent.add_child(m)
	return m


## Una pallina all'articolazione. Serve a due cose: riempie il vuoto che si
## apre quando il gomito o il ginocchio si piegano (due capsule staccate
## lasciano vedere il buco) e da' all'arto il rigonfiamento che ha davvero
## all'altezza del giunto.
static func _giunto(parent: Node3D, mat: Material, raggio: float,
		pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = raggio
	mesh.height = raggio * 2.0
	mesh.radial_segments = 10
	mesh.rings = 6
	m.mesh = mesh
	m.position = pos
	m.material_override = mat
	parent.add_child(m)
	return m


static func _cyl(parent: Node3D, mat: Material, radius: float, height: float,
		pos: Vector3) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.1
	mesh.height = height
	m.mesh = mesh
	m.position = pos
	m.material_override = mat
	parent.add_child(m)
	return m


## La faccia: cranio, naso, occhi, sopracciglia, orecchie, capelli, baffi.
static func _build_head(head: Node3D, skin: Material, hair: Material,
		hair_col: Color, bald: bool, options: Dictionary) -> void:
	var skull := MeshInstance3D.new()
	var skull_mesh := SphereMesh.new()
	skull_mesh.radius = 0.125
	skull_mesh.height = 0.29
	skull_mesh.radial_segments = 14
	skull_mesh.rings = 8
	skull.mesh = skull_mesh
	skull.position = Vector3(0, 0.11, 0)
	skull.material_override = skin
	head.add_child(skull)

	var nose := MeshInstance3D.new()
	var nose_mesh := BoxMesh.new()
	nose_mesh.size = Vector3(0.05, 0.06, 0.05)
	nose.mesh = nose_mesh
	nose.position = Vector3(0, 0.1, -0.13)
	nose.material_override = skin
	head.add_child(nose)

	var eye_mat := Tex.flat(Color(0.04, 0.04, 0.05), 0.3)
	for ex in [-0.055, 0.055]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.022
		eye_mesh.height = 0.044
		eye_mesh.radial_segments = 8
		eye_mesh.rings = 4
		eye.mesh = eye_mesh
		eye.position = Vector3(ex, 0.15, -0.108)
		eye.material_override = eye_mat
		head.add_child(eye)

		var brow := MeshInstance3D.new()
		var brow_mesh := BoxMesh.new()
		brow_mesh.size = Vector3(0.055, 0.014, 0.02)
		brow.mesh = brow_mesh
		brow.position = Vector3(ex, 0.19, -0.11)
		brow.material_override = hair
		head.add_child(brow)

		var ear := MeshInstance3D.new()
		var ear_mesh := BoxMesh.new()
		ear_mesh.size = Vector3(0.03, 0.06, 0.045)
		ear.mesh = ear_mesh
		ear.position = Vector3(ex * 2.2, 0.12, 0)
		ear.material_override = skin
		head.add_child(ear)

	if not bald:
		var top := MeshInstance3D.new()
		var top_mesh := SphereMesh.new()
		top_mesh.radius = 0.132
		top_mesh.height = 0.24
		top_mesh.radial_segments = 12
		top_mesh.rings = 6
		top.mesh = top_mesh
		top.position = Vector3(0, 0.16, 0.012)
		top.material_override = hair
		head.add_child(top)

		var nape := MeshInstance3D.new()
		var nape_mesh := BoxMesh.new()
		nape_mesh.size = Vector3(0.22, 0.1, 0.06)
		nape.mesh = nape_mesh
		nape.position = Vector3(0, 0.07, 0.11)
		nape.material_override = hair
		head.add_child(nape)

	if options.get("moustache", false):
		var m := MeshInstance3D.new()
		var mm := BoxMesh.new()
		mm.size = Vector3(0.09, 0.022, 0.03)
		m.mesh = mm
		m.position = Vector3(0, 0.055, -0.125)
		m.material_override = hair
		head.add_child(m)
