extends Node3D
## **'O panaro 'e Donna Filumena** (0.61)
##
## Il panaro è il cestino che si cala dal balcone con la corda: dentro ci
## stanno i soldi e un biglietto, e chi passa sotto fa la commissione. A
## Napoli è un'istituzione, e in un gioco su chi lavora in strada mancava.
##
## Due volte al giorno Donna Filumena, affacciata sopra alla tua piazza,
## cala il panaro e chiama. Vuole una cosa che **hai già in tasca** o che
## si compra a due passi:
##
##   * **cinque sigarette** (il tabaccaio sta in ogni piazza);
##   * **'nu cafè** (il bar pure: il caffè si compra a giri).
##
## Glielo metti nel panaro, lei lo tira su e ti cala i soldi — un po' più
## del prezzo, e la voce che sei un bravo guaglione. Pochi euro: non è un
## mestiere, è il quartiere che ti conosce.

const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const Human := preload("res://scripts/human_builder.gd")
const Tex := preload("res://scripts/textures.gd")

const ALTEZZA: float = 7.2
## Il pavimento del balcone (0.64): il balcone lo costruisce la città
## (`citta_3d._build_personagge_nove`, lo stesso `_balcone` dei palazzi),
## con la mensola che finisce qui. Donna Filumena ci sta sopra.
const PAVIMENTO: float = ALTEZZA + 0.97
## Il panaro tirato su sta appeso fuori dalla ringhiera, sotto al corrimano.
const SU: float = PAVIMENTO + 0.5
## La ringhiera sta a 0,88 dal muro: corda e panaro passano appena fuori.
const FUORI: float = 1.0
const RICHIESTE := [
	{"id": "sigarette", "chiede": "Guagliò! M'accatte cinche sigarette? Mo' te calo 'e sorde!",
		"prompt": "cinche sigarette", "paga": 7},
	{"id": "cafe", "chiede": "Guagliò! Me puorte 'nu cafè d''o bar? Ca io nun pozzo scennere!",
		"prompt": "'nu cafè", "paga": 6},
]
const CHIAMMA := [
	"Guagliò! Guagliò! Aìzate 'a capa!",
	"Uè! Tu, c''a paletta! Ccà ncoppa!",
	"Giovanotto! 'O panaro, 'o panaro!",
]
const GRAZIE := [
	"Sî 'nu bravo guaglione. Tiè, e accattate 'na sfogliatella.",
	"'A Maronna t'accumpagna. 'E sorde stanno dint'ô panaro.",
	"Mammeta t'ha crisciuto bbuono.",
]

var _balcone: Node3D
var _nonna: Node3D
var _cesto: Node3D
var _corda: MeshInstance3D
var _corpo: StaticBody3D
var _bubble: Node3D
var _altezza_cesto: float = SU
var _meta_cesto: float = SU
var _richiesta: Dictionary = {}
var _orari: Array = []
var _giornata: int = -1
var _chiammato: float = 0.0


## Il panaro si appende a un muro: `verso` è la direzione in cui guarda la
## facciata (fuori dal palazzo).
func configura(verso: Vector3) -> void:
	rotation.y = atan2(verso.x, verso.z)


func _ready() -> void:
	_balcone = Node3D.new()
	add_child(_balcone)
	# Donna Filumena, affacciata (il balcone lo mette la città).
	var parts := Human.build(Color(0.34, 0.2, 0.36), Color(0.2, 0.18, 0.2), "",
		1.55, {"corpo": "femmina", "hair": Color(0.82, 0.82, 0.8), "belly": 0.5})
	_nonna = parts["root"]
	_nonna.position = Vector3(0.35, PAVIMENTO, 0.45)
	_nonna.rotation.y = PI
	_balcone.add_child(_nonna)
	_nonna.visible = false

	# Il panaro: un cestino di vimini con i manici, e la corda.
	_cesto = Node3D.new()
	add_child(_cesto)
	var fondo := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.22
	cm.bottom_radius = 0.17
	cm.height = 0.22
	fondo.mesh = cm
	fondo.material_override = Tex.flat(Color(0.62, 0.45, 0.22), 0.95)
	fondo.position = Vector3(0, 0.11, 0)
	_cesto.add_child(fondo)
	var manico := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.19
	tm.outer_radius = 0.215
	manico.mesh = tm
	manico.material_override = Tex.flat(Color(0.5, 0.36, 0.18), 0.95)
	manico.position = Vector3(0, 0.22, 0)
	manico.rotation.z = PI / 2.0
	_cesto.add_child(manico)
	_corda = MeshInstance3D.new()
	var co := CylinderMesh.new()
	co.top_radius = 0.008
	co.bottom_radius = 0.008
	co.height = 1.0
	_corda.mesh = co
	_corda.material_override = Tex.flat(Color(0.85, 0.8, 0.66), 0.9)
	add_child(_corda)
	_bubble = SpeechBubbleScript.new()
	add_child(_bubble)

	# Il corpo da agganciare con E: solo quando il panaro è giù.
	_corpo = preload("res://scripts/panaro_corpo.gd").new()
	_corpo.collision_layer = 0
	_corpo.collision_mask = 0
	_corpo.add_to_group("panari")
	_corpo.set_meta("panaro", self)
	var f := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(0.7, 1.2, 0.7)
	f.shape = bx
	f.position = Vector3(0, 0.6, 0)
	_corpo.add_child(f)
	_cesto.add_child(_corpo)
	_posa_cesto()


func _posa_cesto() -> void:
	_cesto.position = Vector3(0, _altezza_cesto, FUORI)
	# La corda va dal manico del panaro al corrimano, dove la tiene lei.
	var lung: float = maxf(0.05, PAVIMENTO + 0.9 - (_altezza_cesto + 0.22))
	(_corda.mesh as CylinderMesh).height = lung
	_corda.position = Vector3(0, _altezza_cesto + 0.22 + lung * 0.5, FUORI)
	_bubble.position = Vector3(0, ALTEZZA + 2.9, 0.75)


func _programma() -> void:
	if _giornata == GameManager.giornata:
		return
	_giornata = GameManager.giornata
	_orari = [randf_range(13.0, 16.5), randf_range(18.5, 22.5)]
	_richiesta = {}
	_meta_cesto = SU


func _process(delta: float) -> void:
	if not GameManager.shift_active:
		return
	_programma()
	_chiammato -= delta
	if _richiesta.is_empty() and not _orari.is_empty() \
			and GameManager.ora_d_o_juorno() >= float(_orari[0]) \
			and not GameManager.giornata_scaduta:
		_orari.pop_front()
		_richiesta = RICHIESTE[randi() % RICHIESTE.size()]
		_meta_cesto = 0.0
		_nonna.visible = true
		_chiammato = 0.0
	# Il cesto scende e sale piano, come una corda tirata a mano.
	if absf(_altezza_cesto - _meta_cesto) > 0.01:
		_altezza_cesto = move_toward(_altezza_cesto, _meta_cesto, delta * 1.6)
		_posa_cesto()
		if _altezza_cesto >= SU - 0.01 and _richiesta.is_empty():
			_nonna.visible = false
	_corpo.collision_layer = 4 if (not _richiesta.is_empty()
		and _altezza_cesto < 0.3) else 0
	# Chiama quando passi sotto.
	if not _richiesta.is_empty() and _chiammato <= 0.0:
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and pl is Node3D and global_position.distance_to(
				(pl as Node3D).global_position) < 22.0:
			_chiammato = 25.0
			_bubble.say(CHIAMMA[randi() % CHIAMMA.size()] + " " + str(_richiesta["chiede"]), 5.0)
			SoundManager.play("schiarisce", -8.0, 1.25)
			GameManager.event_started.emit(
				"Donna Filumena ha calato 'o panaro: vò %s." % str(_richiesta["prompt"]))


func prompt() -> String:
	if _richiesta.is_empty():
		return ""
	var ce: bool = _tengo()
	return "[E] Miette %s dint'ô panaro (€%d)" % [str(_richiesta["prompt"]),
		int(_richiesta["paga"])] if ce \
		else "'O panaro vò %s — nun 'o tiene (%s)" % [str(_richiesta["prompt"]),
			"tabbaccaro" if str(_richiesta["id"]) == "sigarette" else "bar"]


func _tengo() -> bool:
	match str(_richiesta.get("id", "")):
		"sigarette":
			return GameManager.cigarettes >= 5
		"cafe":
			return GameManager.caffe >= 1
	return false


func interagisci() -> void:
	if _richiesta.is_empty():
		return
	if not _tengo():
		_bubble.say("Nun 'o tiene? Va', va' a l'accattà, ca t'aspetto.", 3.0)
		return
	match str(_richiesta["id"]):
		"sigarette":
			GameManager.cigarettes -= 5
			GameManager.cigarettes_changed.emit(GameManager.cigarettes)
		"cafe":
			GameManager.caffe -= 1
			GameManager.caffe_changed.emit(GameManager.caffe)
	var paga: int = int(_richiesta["paga"])
	GameManager.add_money(paga)
	GameManager.add_reputation(1)
	SoundManager.play("coin", -4.0, 1.1)
	_bubble.say(GRAZIE[randi() % GRAZIE.size()], 4.0)
	GameManager.event_started.emit(
		"Donna Filumena t'ha calato €%d dint'ô panaro." % paga)
	_richiesta = {}
	_meta_cesto = SU
