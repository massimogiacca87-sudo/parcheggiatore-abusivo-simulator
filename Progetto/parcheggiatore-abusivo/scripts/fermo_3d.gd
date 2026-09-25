extends StaticBody3D
## Fermo3D — uno che sta fermo per strada, e con cui si può parlare
##
## I dodici modelli appoggiati ai muri, agli angoli, davanti al bar. Prima
## erano geometria e basta: un modello e un collider messi lì dalla città.
## Adesso sono un nodo con un nome, una bolla sopra la testa e il tasto E.
##
## ## Perché sono un nodo separato dai passanti
##
## Un passante cammina, ha un rig animato e una vita sua. Questi non si
## muovono mai — sono modelli rigidi senza scheletro, e farli camminare li
## farebbe scivolare come statue su rotelle. La differenza non è cosmetica:
## è il motivo per cui esistono tutti e due. Chi cammina riempie la strada,
## chi sta fermo la abita.
##
## Le battute sono le stesse dei passanti (`chiacchiere.gd`): la voce del
## quartiere è una sola.

const ChiacchiereScript := preload("res://scripts/chiacchiere.gd")
const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")

var _bubble: Node3D
var _rng := RandomNumberGenerator.new()
var _parlato: float = 0.0
## Ogni tanto dice qualcosa da solo, se gli passi vicino. Non serve a niente
## di meccanico: serve a far capire che ci si può parlare, senza scriverlo.
var _spontaneo: float = 8.0


func _ready() -> void:
	add_to_group("attivita")
	add_to_group("gente_ferma")
	collision_layer = 1
	collision_mask = 0
	_rng.randomize()
	_spontaneo = _rng.randf_range(6.0, 20.0)

	var f := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(0.62, 1.8, 0.46)
	f.shape = b
	f.position = Vector3(0, 0.9, 0)
	add_child(f)

	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 2.05, 0)
	add_child(_bubble)


func get_interact_prompt(_da: Vector3) -> String:
	return "[E] parlace"


func player_interact() -> void:
	if _parlato > 0.0:
		if _bubble:
			_bubble.say("...", 1.0)
		return
	_parlato = 2.6
	var b: Dictionary = ChiacchiereScript.battuta(_rng, GameManager.notte)
	if _bubble:
		_bubble.say(str(b["testo"]), 3.0)
	ChiacchiereScript.suono(int(b["tono"]))


## Si puo' menare a chiunque, e quindi anche a chi sta appoggiato al muro
## a farsi i fatti suoi. Non si stende — scappa, e strilla. Il quartiere se
## lo ricorda: e' il crimine che fa salire le stelle piu' in fretta insieme
## alle signore.
func receive_punch(_danno: int = 1) -> void:
	if _scappa > 0.0:
		return
	_scappa = 9.0
	GameManager.violenza(1.1)
	GameManager.add_heat(18.0)
	GameManager.register_punch()
	SoundManager.pugno(-2.0)
	GameManager.screen_shake.emit(0.45)
	if _bubble:
		_bubble.say(SCAPPA[_rng.randi() % SCAPPA.size()], 2.6)
	GameManager.avvisa_strada("Hê menato a uno ca steva fattenno 'e fatte suoje.")


const SCAPPA := ["AAAH! AIUTO!", "MA CHE VUÓ?!", "CHIAMMATE 'E CARABINIERI!",
	"AIUTO! AIUTO!"]
var _scappa: float = 0.0


func _physics_process(delta: float) -> void:
	_parlato = maxf(0.0, _parlato - delta)
	if _scappa > 0.0:
		# Non ha le gambe per correre (e' un fermo), ma almeno si allontana
		# un poco e si volta dall'altra parte.
		_scappa -= delta
		var pl2 := get_tree().get_first_node_in_group("player")
		if pl2 != null and is_instance_valid(pl2):
			var via: Vector3 = global_position - pl2.global_position
			via.y = 0.0
			if via.length() > 0.1 and via.length() < 7.0:
				global_position += via.normalized() * delta * 1.6
		return
	_spontaneo -= delta
	if _spontaneo > 0.0:
		return
	_spontaneo = _rng.randf_range(14.0, 34.0)
	# Solo se sei abbastanza vicino da sentirlo: dodici persone che parlano
	# da sole in giro per la città sono dodici bolle che si aggiornano per
	# nessuno.
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null or not is_instance_valid(pl):
		return
	if global_position.distance_to(pl.global_position) > 9.0:
		return
	if _bubble and _parlato <= 0.0:
		var b: Dictionary = ChiacchiereScript.battuta(_rng, GameManager.notte)
		_bubble.say(str(b["testo"]), 2.4)
