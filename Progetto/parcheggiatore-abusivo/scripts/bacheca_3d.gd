extends StaticBody3D
## Bacheca3D — 'o pannello 'e sughero addò stanno appise 'e ffatiche
##
## **Perché.** Fino alla 0.44b tutto quello che c'era da fare veniva
## addosso al giocatore: le auto arrivavano, le commissioni comparivano, i
## vecchi stavano seduti ad aspettare. Non c'era un posto dove uno *va a
## cercarsi* il lavoro — e senza quel posto la città è un nastro
## trasportatore, non un quartiere.
##
## La bacheca è quel posto. Un pannello di sughero in un angolo della
## piazza, con sopra i foglietti attaccati con le puntine, e due colonne:
## i lavorielli di oggi e le case in vendita. Le due cose insieme perché
## sono la stessa cosa a due velocità — come si campa oggi, e perché.
##
## Il pannello vero (la lista, i prezzi, i bottoni) sta in
## `pannello_bacheca.gd`: qui c'è solo il legno e chi lo guarda.

const Tex := preload("res://scripts/textures.gd")
const PannelloBacheca := preload("res://scripts/pannello_bacheca.gd")
const Models := preload("res://scripts/models.gd")

const LAYER_WORLD := 1
const LAYER_CAR := 4   # lo stesso su cui pesca il raggio dell'interazione

var zona_id: String = ""
var nome_zona: String = ""

var _pannello: CanvasLayer = null
var _foglietti: Node3D = null
## Il nodo inclinato come la tavola: ci stanno sopra foglietti e scritte.
var _tavola: Node3D = null


func _ready() -> void:
	add_to_group("bacheche")
	collision_layer = LAYER_CAR
	collision_mask = 0
	_costruisci()
	GameManager.lavoretti_cambiati.connect(_rifai_foglietti)


## L'inclinazione d''o pannello d''o modello nuovo: è una bacheca a
## cavalletto, e la tavola sta appoggiata all'indietro di una ventina di
## gradi. Foglietti e scritte devono seguirla, se no restano per aria.
const PANNELLO_GIRO := 0.32
## Dove sta il centro della tavola, in metri dal piede.
const PANNELLO_CENTRO := Vector3(0.0, 1.02, -0.14)


func _costruisci() -> void:
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	# Largo e profondo: una bacheca la si guarda da davanti, ma uno ci
	# arriva di sbieco, e un collider sottile lo si manca.
	bx.size = Vector3(1.5, 1.7, 1.3)
	cs.shape = bx
	cs.position = Vector3(0, 0.85, -0.15)
	add_child(cs)

	# **'A bacheca mo è 'nu modello, no quatt'e scatole.**
	#
	# Il capo: *"La bacheca non esiste, è solo un raggio luminoso."* Quella
	# vecchia era due pali e due pannelli fatti a mano, e da lontano — con
	# la sua etichetta gialla accesa sopra — si leggeva davvero solo come
	# un bagliore. Questo è il modello che ha messo lui nella cartella: una
	# bacheca a cavalletto vera, con la cornice e il pannello di sughero.
	var modello: Node3D = Models.spawn("bacheca")
	if modello != null:
		add_child(modello)
		_tinge(modello)
	else:
		# Se il modello manca il gioco non deve restare senza bacheca.
		var legno := Tex.flat(Color(0.34, 0.22, 0.14), 0.8)
		for sx in [-0.62, 0.62]:
			_box(Vector3(0.09, 1.60, 0.09), Vector3(sx, 0.80, 0), legno)
		_box(Vector3(1.36, 1.00, 0.07), Vector3(0, 1.05, -0.10), legno)
		_box(Vector3(1.24, 0.90, 0.03), Vector3(0, 1.05, -0.14),
			Tex.flat(Color(0.72, 0.55, 0.34), 0.94))
	_solido(Vector3(0.9, 1.6, 0.7), Vector3(0, 0.80, 0.10))

	# Tutto quello che si appunta sta su questo nodo, che è inclinato come
	# la tavola: così i foglietti ci stanno **sopra** invece che davanti.
	_tavola = Node3D.new()
	_tavola.position = PANNELLO_CENTRO
	_tavola.rotation.x = -PANNELLO_GIRO
	add_child(_tavola)

	# 'O titolo, scritto a pennarello ncopp'â cornice.
	var l := Label3D.new()
	l.text = "LAVORE E CASE"
	l.font_size = 34
	l.pixel_size = 0.0026
	l.modulate = Color(0.16, 0.12, 0.09)
	l.outline_size = 0
	l.position = Vector3(0, 0.44, -0.035)
	l.rotation.y = PI
	_tavola.add_child(l)

	var s := Label3D.new()
	s.text = "[E]"
	s.font_size = 40
	s.pixel_size = 0.0034
	s.modulate = Color(1.0, 0.86, 0.40)
	s.outline_size = 10
	s.outline_modulate = Color(0.10, 0.08, 0.06)
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.position = Vector3(0, 1.92, 0)
	add_child(s)

	_foglietti = Node3D.new()
	_tavola.add_child(_foglietti)
	_rifai_foglietti()


## I foglietti veri: uno per lavoretto appeso. Servono a far vedere **da
## lontano** se la bacheca ha qualcosa — una bacheca vuota e una piena si
## devono distinguere senza premere niente.
func _rifai_foglietti() -> void:
	if _foglietti == null:
		return
	for c in _foglietti.get_children():
		c.queue_free()
	var i := 0
	for l in GameManager.lavoretti:
		if str(l["stato"]) != "offerto":
			continue
		# Un colore per tipo di lavoro: da lontano si vede che la bacheca
		# non ha tre volte lo stesso foglietto.
		var col := Color(0.96, 0.94, 0.86)
		match str(l["tipo"]):
			"caffe": col = Color(0.94, 0.86, 0.70)
			"stemme": col = Color(0.84, 0.88, 0.96)
			"guardia": col = Color(0.86, 0.94, 0.84)
		var f := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.30, 0.22, 0.006)
		f.mesh = bm
		f.material_override = Tex.flat(col, 0.95)
		f.position = Vector3(-0.40 + float(i) * 0.40,
			0.20 - float(i % 2) * 0.26, -0.035)
		f.rotation.z = randf_range(-0.09, 0.09)
		_foglietti.add_child(f)
		# 'A puntina.
		var p := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.014
		cm.bottom_radius = 0.014
		cm.height = 0.012
		p.mesh = cm
		p.material_override = Tex.flat(Color(0.80, 0.16, 0.14), 0.5)
		p.rotation.x = PI * 0.5
		p.position = f.position + Vector3(0, 0.10, -0.008)
		_foglietti.add_child(p)
		i += 1


## **'E culure d''a bacheca se mettono ccà, no dinto ô file.**
##
## Il modello arriva da Blockbench spaccato in dodici pezzi, e per quanto i
## materiali del `.glb` siano giusti (li ho controllati: `legno_bacheca` è
## marrone) in gioco usciva **bianca**. Invece di indagare su come Godot
## importa quel file, si scrive il colore qui: è una riga, non si può
## sbagliare, e per un oggetto solo non costa niente.
func _tinge(n: Node) -> void:
	var colori := {
		"legno_bacheca": Color(0.44, 0.29, 0.17),
		"palo_bacheca": Color(0.27, 0.18, 0.11),
		"sughero": Color(0.74, 0.56, 0.33),
	}
	if n is MeshInstance3D:
		var mi: MeshInstance3D = n
		if mi.mesh != null:
			for i in range(mi.mesh.get_surface_count()):
				var b: Material = mi.mesh.surface_get_material(i)
				var nome: String = str(b.resource_name) if b != null else ""
				var chiave: String = nome.split(".")[0]
				if not colori.has(chiave):
					continue
				var m := StandardMaterial3D.new()
				m.albedo_color = colori[chiave]
				m.roughness = 0.94
				mi.set_surface_override_material(i, m)
	for c in n.get_children():
		_tinge(c)


func _box(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi


func _solido(size: Vector3, pos: Vector3) -> void:
	var sb := StaticBody3D.new()
	sb.collision_layer = LAYER_WORLD
	sb.position = pos
	add_child(sb)
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = size
	cs.shape = bx
	sb.add_child(cs)


# ---------------------------------------------------------------------------
# Interazione
# ---------------------------------------------------------------------------

func get_interact_prompt(_da: Vector3) -> String:
	var in_corso: Dictionary = GameManager.lavoretto_in_corso()
	if not in_corso.is_empty():
		return "[E] 'A bacheca — staje già facenno '%s'" % str(in_corso["nome"])
	var quanti := 0
	for l in GameManager.lavoretti:
		if str(l["stato"]) == "offerto":
			quanti += 1
	if quanti <= 0:
		return "[E] 'A bacheca — oggi nun ce sta niente 'e nuovo"
	return "[E] 'A bacheca — %d lavore appise" % quanti


func player_interact() -> void:
	if _pannello == null or not is_instance_valid(_pannello):
		_pannello = PannelloBacheca.new()
		_pannello.bacheca = self
		get_tree().root.add_child(_pannello)
	_pannello.apri()
	SoundManager.play("pop", -10.0, 1.1)
	# Da adesso per strada non ti dicono più «hê visto 'a bacheca?»: l'hai
	# vista. Vedi `Chiacchiere.CUNZIGLIE`.
	GameManager.commissioni_viste += 1
