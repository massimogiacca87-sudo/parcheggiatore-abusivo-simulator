extends CharacterBody3D
## **'O turista spierzo** (0.61)
##
## Una volta ogni tanto, per strada, uno con la cartina aperta al contrario e
## lo zaino davanti ti ferma: *«Scusi! Excuse me! Piazzale… Stadio?»*. È
## un'attività piccola, e sta qui per due motivi:
##
## 1. **Ti fa attraversare la città con uno scopo**, che è la cosa che la
##    roadmap chiedeva da tre versioni («la traversata a piedi è la cosa che
##    costa più tempo di gioco»): se la devi fare, almeno qualcuno ti paga.
## 2. **È napoletano**: accompagnare il forestiero, spiegargli la città a
##    gesti, e farsi dare la mancia alla fine.
##
## Quattro risposte:
##
##   1. **L'accompagni.** Ti segue; sopra alla piazza dove vuole andare si
##      accende una colonna di luce. Se ci arrivate prima che si stufi
##      (tre minuti) ti dà una mancia vera, e la voce gira bene.
##   2. **Gli indichi la strada** a gesti: due euro, e se ne va da solo.
##   3. **Gli dici di tenere il portafoglio in tasca**: un euro e un sorriso.
##   4. **«Nun parlo inglese.»** Se ne va.

const Human := preload("res://scripts/human_builder.gd")
const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const Tex := preload("res://scripts/textures.gd")
const Passo := preload("res://scripts/passo.gd")
const Citta := preload("res://scripts/citta_3d.gd")

const VELOCITA: float = 4.4
const PAZIENZA: float = 180.0
const ARRIVATO_A: float = 9.0

const CHIAMMA := [
	"Scusi! Excuse me! Per favore!",
	"Sorry… sorry! Tu… aiuto?",
	"Hello! Parla English? Un po'?",
]
const DOVE := "%s? Where is? Dove?"
const SEGUE := [
	"Okay, okay! I follow you!",
	"Bellissimo! Andiamo!",
	"You are very kind, grazie!",
]
const ASPETTA := [
	"Wait! Aspetta! Too fast!",
	"Hey! Piano, piano!",
]
const GRAZIE := [
	"Grazie mille! Bellissima Napoli!",
	"Thank you, my friend! Tieni, tieni!",
	"Wonderful! Tu sei molto gentile!",
]
const STUFO := [
	"Too long… I take a taxi. Bye.",
	"Mamma mia… no. Basta. Taxi!",
]
const SPIEGATO := [
	"Dritto, poi a destra… okay! Grazie!",
	"Ah, là! Thank you!",
]

var _attivo: bool = false
var _segue: bool = false
var _meta: Dictionary = {}
var _meta_p: Vector3 = Vector3.ZERO
var _t: float = 0.0
var _parla: float = 0.0
var _visto_oggi: int = -1
var _quanno: float = -1.0
var _chiamato: bool = false
var _parlando: bool = false
var _via: Vector3 = Vector3.ZERO
var _se_ne_va: float = 0.0
var _ntuppato: float = 0.0
var _d_prima: float = 1e9

var _visual: Node3D
var _anim: Node = null
var _bubble: Node3D
var _colonna: MeshInstance3D = null


func _ready() -> void:
	add_to_group("turisti_spierze")
	collision_layer = 0
	collision_mask = 1
	var f := CollisionShape3D.new()
	var c := CapsuleShape3D.new()
	c.radius = 0.34
	c.height = 1.7
	f.shape = c
	f.position = Vector3(0, 0.85, 0)
	add_child(f)
	_visual = Node3D.new()
	add_child(_visual)
	# Camicia a fiori (gialla), pantaloncini chiari, calzini bianchi: il
	# forestiero si riconosce da trenta metri, come nella vita.
	var parts := Human.build(Color(0.95, 0.8, 0.25), Color(0.85, 0.8, 0.66),
		"", 1.84, {"belly": 0.3, "hair": Color(0.85, 0.72, 0.45),
			"moustache": false, "bald": false, "skin": Color(0.95, 0.72, 0.62)})
	_visual.add_child(parts["root"])
	_anim = parts.get("anim", null)
	# La cartina: un foglio bianco aperto davanti alla pancia.
	var carta := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.46, 0.32, 0.01)
	carta.mesh = bm
	carta.material_override = Tex.flat(Color(0.93, 0.93, 0.86), 0.9)
	carta.position = Vector3(0, 1.1, -0.34)
	carta.rotation.x = deg_to_rad(-35)
	_visual.add_child(carta)
	# Lo zaino, davanti (così glielo rubano meno).
	var zaino := MeshInstance3D.new()
	var zb := BoxMesh.new()
	zb.size = Vector3(0.32, 0.4, 0.18)
	zaino.mesh = zb
	zaino.material_override = Tex.flat(Color(0.15, 0.45, 0.62), 0.9)
	zaino.position = Vector3(0, 1.25, 0.2)
	_visual.add_child(zaino)
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 2.2, 0)
	add_child(_bubble)
	_sparisce()


func _sparisce() -> void:
	_attivo = false
	_segue = false
	_se_ne_va = 0.0
	visible = false
	collision_layer = 0
	global_position = Vector3(-60, -20, -60)
	_leva_colonna()
	if _parlando:
		_chiude_parlata()


func _programma() -> void:
	if _visto_oggi == GameManager.giornata:
		return
	_visto_oggi = GameManager.giornata
	_quanno = randf_range(13.0, 21.0) if randf() < 0.6 else -1.0
	_chiamato = false


## Compare a una quindicina di metri da te, in strada, girato verso di te.
func _compare() -> void:
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	if pl == null:
		return
	var base: Vector3 = pl.global_position
	var messo := false
	for i in range(10):
		var ang: float = randf() * TAU
		var p: Vector3 = base + Vector3(sin(ang), 0, cos(ang)) * randf_range(11.0, 17.0)
		p = Passo.fore(p)
		if Citta.dint_ô_palazzo(p, 0.4):
			continue
		if p.x < 2.0 or p.x > 188.0 or p.z < 2.0 or p.z > 170.0:
			continue
		p.y = base.y + 0.3
		global_position = p
		messo = true
		break
	if not messo:
		return
	_attivo = true
	_segue = false
	_chiamato = false
	_t = 0.0
	visible = true
	collision_layer = 4
	# Dove vuole andare: una piazza **diversa** da quella dove sta.
	var qui: String = GameManager.zona_corrente
	var altre: Array = []
	for z in Citta.ZONE:
		if str(z["id"]) != qui:
			altre.append(z)
	_meta = altre[randi() % altre.size()]
	var r: Array = _meta["rect"]
	_meta_p = Vector3((float(r[0]) + float(r[2])) * 0.5, 0.0,
		(float(r[1]) + float(r[3])) * 0.5)


func _physics_process(delta: float) -> void:
	if not GameManager.shift_active or GameManager.giornata_scaduta:
		if _attivo:
			_sparisce()
		return
	_programma()
	if not _attivo:
		if _quanno > 0.0 and GameManager.ora_d_o_juorno() >= _quanno:
			_quanno = -1.0
			_compare()
		return
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	else:
		velocity.y = 0.0
	velocity.x = 0.0
	velocity.z = 0.0
	_parla -= delta
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	if pl == null:
		move_and_slide()
		return
	var d_pl: float = global_position.distance_to(pl.global_position)
	if _parlando and d_pl > 6.0:
		_chiude_parlata()

	if _se_ne_va > 0.0:
		_se_ne_va -= delta
		_cammina(_via, delta, 2.2)
		if _se_ne_va <= 0.0:
			_sparisce()
		move_and_slide()
		return

	if not _segue:
		_t += delta
		_guarda(pl.global_position, delta)
		_ferma()
		if d_pl < 12.0 and not _chiamato:
			_chiamato = true
			_di(CHIAMMA[randi() % CHIAMMA.size()])
			GameManager.event_started.emit(
				"'Nu turista cu 'a cartina te sta chiammanno. [E] pe' sentì che vò.")
		# Se nessuno lo aiuta, dopo tre minuti se ne va da solo.
		if _t > PAZIENZA:
			_parte(STUFO[randi() % STUFO.size()])
		move_and_slide()
		return

	# Ti segue.
	_t += delta
	if global_position.distance_to(_meta_p) < ARRIVATO_A \
			or Vector2(pl.global_position.x - _meta_p.x,
				pl.global_position.z - _meta_p.z).length() < ARRIVATO_A * 0.8 \
				and d_pl < 10.0:
		_arrivati()
		move_and_slide()
		return
	if _t > PAZIENZA:
		_parte(STUFO[randi() % STUFO.size()])
		GameManager.event_started.emit("'O turista s'è stufato e s'è pigliato 'nu taxi.")
		move_and_slide()
		return
	if d_pl > 3.0:
		_cammina(pl.global_position, delta, VELOCITA if d_pl < 14.0 else VELOCITA * 1.25)
	else:
		_ferma()
		_guarda(pl.global_position, delta)
	if d_pl > 22.0 and _parla <= 0.0:
		_parla = 6.0
		_di(ASPETTA[randi() % ASPETTA.size()])
	# 'Ntuppato (un muro invisibile della piazza, un cantiere): se per sei
	# secondi non si avvicina, fa il giro largo e ricompare dietro a te.
	if d_pl > 8.0 and d_pl > _d_prima - 0.3:
		_ntuppato += delta
	else:
		_ntuppato = 0.0
	_d_prima = minf(_d_prima, d_pl) if _ntuppato > 0.0 else d_pl
	# Chi ti perde del tutto (sei salito su una macchina, sei corso via)
	# ti raggiunge lo stesso: si è fatto portare, e lo dice.
	if d_pl > 60.0 or _ntuppato > 6.0:
		_ntuppato = 0.0
		_d_prima = 1e9
		global_position = Passo.fore(pl.global_position
			- (pl.global_transform.basis.z * -1.0) * 4.0) + Vector3(0, 0.3, 0)
		_di("Taxi! Eccomi, eccomi!")
	move_and_slide()


func _cammina(meta: Vector3, delta: float, v: float) -> void:
	var prima := global_position
	var nuova: Vector3 = Passo.verso(self, meta, v * delta)
	nuova.y = global_position.y
	global_position = nuova
	var dir: Vector3 = nuova - prima
	dir.y = 0.0
	if dir.length() > 0.001:
		dir = dir.normalized()
		_visual.rotation.y = lerp_angle(_visual.rotation.y,
			atan2(-dir.x, -dir.z), 1.0 - exp(-10.0 * delta))
	if _anim != null and _anim.has_method("set_speed"):
		_anim.call("set_speed", v)


func _ferma() -> void:
	if _anim != null and _anim.has_method("set_speed"):
		_anim.call("set_speed", 0.0)


func _guarda(p: Vector3, delta: float) -> void:
	var d: Vector3 = p - global_position
	d.y = 0.0
	if d.length() > 0.2:
		_visual.rotation.y = lerp_angle(_visual.rotation.y,
			atan2(-d.x, -d.z), 1.0 - exp(-6.0 * delta))


func _di(t: String, durata: float = 3.2) -> void:
	if _bubble:
		_bubble.say(t, durata)


func _parte(frase: String) -> void:
	_di(frase)
	_segue = false
	_leva_colonna()
	_via = Passo.fore(global_position + Vector3(randf_range(-20, 20), 0,
		randf_range(-20, 20)))
	_se_ne_va = 7.0


func _arrivati() -> void:
	var mancia: int = randi_range(12, 22)
	# Chi ci mette poco è uno che conosce la città: un po' di più.
	if _t < 90.0:
		mancia += 5
	GameManager.add_money(mancia)
	GameManager.add_reputation(2)
	SoundManager.play("kaching", -4.0, 1.1)
	GameManager.event_started.emit(
		"'O turista è arrivato a %s. T'ha dato €%d, e l'ha ditto a tutte quante."
		% [str(_meta["nome"]), mancia])
	_parte(GRAZIE[randi() % GRAZIE.size()])


# ---------------------------------------------------------------------------
# 'A colonna 'e luce addò vò ì
# ---------------------------------------------------------------------------

func _metti_colonna() -> void:
	_leva_colonna()
	_colonna = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.9
	cm.bottom_radius = 0.9
	cm.height = 60.0
	cm.radial_segments = 12
	_colonna.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.85, 0.3, 0.32)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_colonna.material_override = mat
	_colonna.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_parent().add_child(_colonna)
	_colonna.global_position = _meta_p + Vector3(0, 30.0, 0)


func _leva_colonna() -> void:
	if _colonna != null and is_instance_valid(_colonna):
		_colonna.queue_free()
	_colonna = null


# ---------------------------------------------------------------------------
# 'O parlato
# ---------------------------------------------------------------------------

func get_interact_prompt(_da: Vector3) -> String:
	if not _attivo or _se_ne_va > 0.0:
		return ""
	if _segue:
		return "'O turista te vène appriesso: portalo a %s (colonna gialla)" \
			% str(_meta["nome"])
	return "[E] Siente che vò 'o turista cu 'a cartina"


func player_interact() -> void:
	if not _attivo or _segue or _se_ne_va > 0.0 or _parlando:
		return
	_di(DOVE % str(_meta["nome"]), 4.0)
	_parlando = true
	GameManager.dialogo_con = self
	GameManager.boss_dialogue_opened.emit([
		{"text": "Venite cu me, v'accumpagno io a %s." % str(_meta["nome"])},
		{"text": "È ddà, sempe deritto, po' a destra. (Gesti.)"},
		{"text": "Tenite 'o portafoglio astipato, ccà ce stanno 'e mariuole."},
		{"text": "Nun parlo inglese, dotto'."},
	])


func answer(index: int) -> void:
	if not _parlando:
		return
	_chiude_parlata()
	match index:
		0:
			_segue = true
			_t = 0.0
			_di(SEGUE[randi() % SEGUE.size()])
			_metti_colonna()
			GameManager.event_started.emit(
				"Puortalo a %s: 'a colonna gialla è addò vò ì. Tiene tre minute."
				% str(_meta["nome"]))
		1:
			GameManager.add_money(2)
			SoundManager.play("coin", -8.0, 1.2)
			_parte(SPIEGATO[randi() % SPIEGATO.size()])
		2:
			GameManager.add_money(1)
			GameManager.add_reputation(1)
			SoundManager.play("coin", -10.0, 1.3)
			_parte("Oh! Grazie, grazie! Tu sei onesto!")
		_:
			_parte("Oh… okay. Sorry.")


func _chiude_parlata() -> void:
	_parlando = false
	if GameManager.dialogo_con == self:
		GameManager.dialogo_con = null
	GameManager.boss_dialogue_closed.emit()
