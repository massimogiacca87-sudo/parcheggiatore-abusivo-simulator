extends CharacterBody3D
## SignoraLotto3D — 'a Signora d''e nummere
##
## **Nun te dice 'nfurmazione: te dà 'nu suonno.**
##
## Sta ferma in un posto diverso ogni giorno, vestita di scuro, e non
## chiede niente. Le parli una volta sola, ti dice cinque numeri e una
## ruota, e se ne sta zitta. Quasi sempre non esce niente.
##
## **Una volta su venti** quei cinque numeri sono esattamente quelli che
## escono stasera — e allora un euro sulla cinquina fa sei milioni. La
## tiratura sta in `GameManager.signora_numeri()`, e i numeri di stasera
## esistono dalla mattina (`_prepara_estrazione`): senza quello, questa
## non sarebbe una profezia ma una finta.
##
## **Nun se capisce quale vota è chella bbona**, ed è la cosa più
## importante di tutte. Le diciannove volte sbagliate hanno la stessa
## faccia, la stessa frase e la stessa ruota di quella giusta. Se si
## capisse, le altre diciannove sarebbero rumore; così invece sono attesa.
##
## Dove sta oggi te lo dice Mimmo 'o guaglione, ed è l'unica notizia del
## vicinato rimasta — perché è l'unica che porta da qualche parte.

const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const Human := preload("res://scripts/human_builder.gd")
const Tex := preload("res://scripts/textures.gd")
const Lotto := preload("res://scripts/lotto.gd")

const SAY_PRIMMA := [
	"Guagliò… viene ccà 'nu momento.",
	"T'aggio 'a dicere 'na cosa. Statte a sentì.",
	"Ce l'aggio cu te. Viene.",
]

## Quello che dice quando te li dà. Non cambia fra la volta giusta e le
## altre: è tutto il punto.
const SAY_NUMMERE := [
	"Stanotte aggio suonnato. Signate: %s. Ncopp'a %s.",
	"Chisti ccà: %s. 'A rota è %s. Nun 'e dicere a nisciuno.",
	"'E vvide? %s, ncopp'a %s. Mo' fa' chello ca vuò.",
]

const SAY_GIA := [
	"T'aggio già ditto tutto. Va', va'.",
	"Cchiù 'e chesto nun saccio.",
	"'E nummere so' chille. Nun ce ne stanno ate.",
]

const SAY_IDLE := [
	"…", "Mh.", "'O ssaccio, io.", "Stanotte aggio suonnato n'ata vota.",
	"'E nummere stanno dint'ê suonne, no dint'ê libbre.",
]

var _bubble: Node3D
var _visual_root: Node3D
var _idle_cd: float = 0.0
var _guarda_cd: float = 0.0
var _chiammato: bool = false


func _ready() -> void:
	add_to_group("signora_lotto")
	collision_layer = 4
	collision_mask = 0
	_build_collision()
	_build_visual()
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 2.05, 0)
	add_child(_bubble)
	_idle_cd = randf_range(5.0, 12.0)


func _build_collision() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.7
	shape.shape = capsule
	shape.position = Vector3(0, 0.85, 0)
	add_child(shape)


func _build_visual() -> void:
	_visual_root = Node3D.new()
	add_child(_visual_root)
	# Tutta scura, piccola, capelli bianchi: da lontano è una macchia nera
	# ferma in mezzo a gente che cammina, ed è così che la noti.
	var parts := Human.build(Color(0.13, 0.12, 0.15), Color(0.10, 0.10, 0.12),
		"", 1.54, {
			"corpo": "femmina", "hair": Color(0.86, 0.86, 0.84),
			"belly": 0.55,
		})
	_visual_root.add_child(parts["root"])
	_scialle()


## 'O scialle ncopp'ê spalle: due falde scure che la staccano dai passanti.
func _scialle() -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.46, 0.52, 0.30)
	m.mesh = bm
	m.position = Vector3(0.0, 1.16, 0.0)
	m.material_override = Tex.flat(Color(0.09, 0.08, 0.11), 0.95)
	_visual_root.add_child(m)


func _process(delta: float) -> void:
	var pl := get_tree().get_first_node_in_group("player")
	var vicino := false
	if pl != null and pl is Node3D:
		vicino = global_position.distance_to((pl as Node3D).global_position) < 9.0

	_guarda_cd -= delta
	if _guarda_cd <= 0.0 and vicino:
		_guarda_cd = 0.3
		var d: Vector3 = (pl as Node3D).global_position - global_position
		d.y = 0.0
		if d.length() > 0.2:
			rotation.y = atan2(-d.x, -d.z)

	# **Te chiamma essa.** Se aspettasse il tasto E, uno le passerebbe
	# davanti mille volte senza accorgersene: è una vecchia ferma in un
	# angolo, in una città piena di vecchie ferme negli angoli.
	if vicino and not _chiammato and not GameManager.signora_data:
		_chiammato = true
		_say(SAY_PRIMMA[randi() % SAY_PRIMMA.size()])
		return

	_idle_cd -= delta
	if _idle_cd <= 0.0:
		_idle_cd = randf_range(12.0, 26.0)
		if randf() < 0.5:
			_say(SAY_IDLE[randi() % SAY_IDLE.size()])


func _say(t: String) -> void:
	if _bubble:
		_bubble.say(t, 4.0)


func get_interact_prompt(_da: Vector3) -> String:
	if GameManager.signora_data:
		return "'A Signora t'ha già ditto 'e nummere"
	return "[E] siente chello ca te dice 'a Signora"


func player_interact() -> void:
	if GameManager.signora_data:
		_say(SAY_GIA[randi() % SAY_GIA.size()])
		return
	var d: Dictionary = GameManager.signora_numeri()
	if d.is_empty():
		return
	var numeri: Array = d["numeri"]
	var pezze: Array = []
	for n in numeri:
		pezze.append("%d" % int(n))
	_say(SAY_NUMMERE[randi() % SAY_NUMMERE.size()]
		% [" · ".join(pezze), str(d["ruota"])])
	SoundManager.play("stemmi", -6.0, 0.72)
	# Il cartello resta in alto, perché cinque numeri non si tengono a
	# mente guardando un fumetto che sparisce in quattro secondi.
	GameManager.event_started.emit(
		"'A Signora: %s — ncopp'a %s. Mo' curre ô tabaccaro."
		% [" · ".join(pezze), str(d["ruota"])])
	# **'A smorfia**, che è il modo in cui questi numeri si ricordano
	# davvero: nessuno si ricorda "47", tutti si ricordano 'o muorto.
	var nomi: Array = []
	for n in numeri:
		nomi.append(Lotto.smorfia(int(n)))
	GameManager.event_started.emit("Cioè: %s." % ", ".join(nomi))
