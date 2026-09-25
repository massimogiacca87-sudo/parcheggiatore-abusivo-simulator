extends Node3D
## Cummissiune3D — 'e ppacche 'a purtà 'a n'ata parte
##
## Il regista delle commissioni: guarda la lista che tiene il GameManager e
## mette a terra due segni, uno dove si ritira e uno dove si consegna.
##
## **Perché sono la risposta a "che ci faccio con tutta questa città".**
## Il lavoro si fa dentro alla piazza, e per tre versioni la mappa è stata
## un bel posto che il gioco ti diceva di non attraversare. Una commissione
## non è un altro modo di fare soldi — rende più o meno quanto sei minuti
## di lavoro pulito — è **un motivo per essere da un'altra parte**: e
## mentre ci vai passi per il mercato, per Spaccanapoli, sotto allo stadio.
##
## Il segno è un cerchio di luce a terra con una colonna che si vede da
## lontano e un cartello che dice cos'è. Non c'è una freccia che ti guida:
## c'è la mappa (M), e c'è la città. Guardare dove sei è parte del gioco.

const Tex := preload("res://scripts/textures.gd")

const LAYER_CAR := 4
const RAGGIO: float = 2.2

var _segni: Dictionary = {}   # id commissione -> Node3D


func _ready() -> void:
	name = "Cummissiune"
	add_to_group("cummissiune")
	GameManager.commissioni_cambiate.connect(_rifai)
	GameManager.lavoretti_cambiati.connect(_rifai)
	_rifai()


func _rifai() -> void:
	for k in _segni.keys():
		var n = _segni[k]
		if is_instance_valid(n):
			n.queue_free()
	_segni.clear()
	for c in GameManager.commissioni:
		var stato: String = str(c["stato"])
		if stato == "fatta" or stato == "persa":
			continue
		var dove: Vector3 = Vector3(c["da"]) if stato == "aperta" \
			else Vector3(c["a"])
		var ritiro: bool = stato == "aperta"
		var n := _segno(c, dove, ritiro)
		add_child(n)
		_segni[str(c["id"])] = n

	# **'O pacco d''a bacheca.** Stesso segno, stessa colonna di luce: uno
	# solo alla volta, quello che sto portando adesso, e sta dove va
	# consegnato. Il ritiro non ha bisogno di un segno — il pacco te lo
	# danno alla bacheca stessa quando accetti.
	var l: Dictionary = GameManager.lavoretto_in_corso()
	# Il pacco, il caffè e la guardia hanno tutti un posto dove andare, e
	# il segno è lo stesso. Gli stemmi no: quelli si portano al garage, che
	# ha già la sua insegna che si accende.
	if not l.is_empty() and str(l.get("tipo", "")) in ["pacco", "caffe",
			"guardia"]:
		var np := _segno({"id": str(l["id"]), "nome": str(l["nome"]),
			"nome_a": str(l["nome_a"]), "paga": int(l["paga"])},
			Vector3(l["a"]), false)
		np.lid = str(l["id"])
		add_child(np)
		_segni["lav_" + str(l["id"])] = np


func _segno(c: Dictionary, dove: Vector3, ritiro: bool) -> Node3D:
	var root := StaticBody3D.new()
	root.name = "Segno_" + str(c["id"])
	root.position = dove
	root.collision_layer = LAYER_CAR
	root.collision_mask = 0
	root.set_script(preload("res://scripts/punto_cummissione.gd"))
	root.cid = str(c["id"])
	root.ritiro = ritiro
	var cs := CollisionShape3D.new()
	var cy := CylinderShape3D.new()
	cy.radius = RAGGIO
	cy.height = 3.0
	cs.shape = cy
	cs.position = Vector3(0, 1.5, 0)
	root.add_child(cs)

	var tinta: Color = Color(1.0, 0.82, 0.32) if ritiro \
		else Color(0.42, 0.92, 0.55)

	# Il disco a terra.
	var disco := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = RAGGIO
	cm.bottom_radius = RAGGIO
	cm.height = 0.02
	disco.mesh = cm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(tinta.r, tinta.g, tinta.b, 0.30)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = tinta
	m.emission_energy_multiplier = 0.9
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disco.material_override = m
	disco.position = Vector3(0, 0.04, 0)
	root.add_child(disco)

	# La colonna di luce: si vede da cento metri e non copre niente.
	var col := MeshInstance3D.new()
	var cm2 := CylinderMesh.new()
	cm2.top_radius = 0.34
	cm2.bottom_radius = 0.62
	cm2.height = 7.0
	col.mesh = cm2
	var m2 := StandardMaterial3D.new()
	m2.albedo_color = Color(tinta.r, tinta.g, tinta.b, 0.10)
	m2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m2.cull_mode = BaseMaterial3D.CULL_DISABLED
	col.material_override = m2
	col.position = Vector3(0, 3.5, 0)
	root.add_child(col)

	var l := Label3D.new()
	l.text = ("RITIRA — %s" % str(c["nome"])) if ritiro \
		else ("CONSEGNA — %s" % str(c["nome_a"]))
	l.font_size = 40
	l.pixel_size = 0.0038
	l.modulate = tinta
	l.outline_size = 10
	l.outline_modulate = Color(0.06, 0.06, 0.08)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = Vector3(0, 2.4, 0)
	root.add_child(l)
	return root
