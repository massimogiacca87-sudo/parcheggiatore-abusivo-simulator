extends StaticBody3D
## Moglie3D — chi t'aspetta 'a casa
##
## **Non è un negoziante.** È la differenza che fa tutto: da 'O Zio compri,
## a lei consegni. Non c'è un listino, non c'è un affare da fare — c'è un
## conto che è già stato deciso da qualcun altro (la luce, il fitto, 'a
## scola) e tu porti quello che sei riuscito a mettere insieme.
##
## Tutto il suo carattere sta in tre cose:
##
## - **si gira quando entri**, sempre, e la frase che dice dipende dall'ora
##   e da quello che hai combinato — non è a caso;
## - **si ricorda**: `umore_moglie` sale e scende, e se scende troppo si
##   piglia i soldi dalla sacca da sola (e ha ragione lei);
## - **inventa**. Se rientri dopo l'una vuole qualcosa in più per sé, e la
##   scusa se la costruisce ogni volta diversa. Non è una tassa: è il
##   prezzo di una giornata tirata fino a tardi.

const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")

var vascio: Node = null
var parti: Dictionary = {}
var bolla: Node3D = null

var _prossima_frase: float = 0.0
var _guarda: Node3D = null


const CHIACCHIERE := [
	"'A cummara ha ditto ca damane chiove.",
	"'E criature hanno fatto 'e compite. Pe' na vota.",
	"Aggio miso 'o rraù. Nun 'o fa' fredda'.",
	"'O padrone 'e casa è passato. Ha ditto ca ripassa.",
	"'A televisione s'è rotta n'ata vota.",
	"Damme retta: chillu vigile nun è ammico tuoio.",
	"Nun me guarda' accussì. 'E sorde nun 'e ffaccio i'.",
]


func _ready() -> void:
	add_to_group("moglie")
	var a = parti.get("anim", null)
	if a != null and a.has_method("sit"):
		# Sta in piedi, ma gesticola: la clip "parla" della libreria è
		# fatta apposta per uno fermo che discute.
		pass
	_prossima_frase = randf_range(6.0, 14.0)


func get_interact_prompt(_da: Vector3) -> String:
	if GameManager.extra_richiesto > 0 and not GameManager.extra_dato:
		return "%s — [E] te vo' parla'" % nome()
	var dovuto: int = GameManager.spese_dovute()
	if dovuto <= 0:
		return "%s — [E] consegna 'e sorde (nun resta niente 'a pavà)" % nome()
	return "%s — [E] consegna 'e sorde (ce vonno €%d)" % [nome(), dovuto]


func nome() -> String:
	return "Nunzia"


func player_interact() -> void:
	if vascio == null or not is_instance_valid(vascio):
		return
	vascio.apri_consegna()


## Quando entri, si gira e dice la sua.
func saluta() -> void:
	var tono: String = GameManager.tono_moglie()
	if GameManager.ora_ritiro >= 0.0 and GameManager.ora_ritiro > 12.0:
		tono = "tardi"
	dici(GameManager.frase_moglie(tono), 5.0)
	var a = parti.get("anim", null)
	if a != null and a.has_method("action"):
		a.action("parla")


func dici(testo: String, durata: float = 3.4) -> void:
	if bolla != null and is_instance_valid(bolla) and bolla.has_method("say"):
		bolla.say(testo, durata)


func _process(delta: float) -> void:
	if not GameManager.dentro_casa:
		return
	# Si gira verso di te mentre stai dentro: non ti perde d'occhio.
	if _guarda == null or not is_instance_valid(_guarda):
		_guarda = get_tree().get_first_node_in_group("player")
	if _guarda != null:
		var d: Vector3 = _guarda.global_position - global_position
		d.y = 0.0
		if d.length() > 0.3:
			var voluto: float = atan2(-d.x, -d.z)
			rotation.y = lerp_angle(rotation.y, voluto, delta * 2.4)

	_prossima_frase -= delta
	if _prossima_frase <= 0.0:
		_prossima_frase = randf_range(11.0, 22.0)
		# Se c'è ancora da pagare non fa conversazione: lo ricorda.
		var resta: int = GameManager.spese_dovute()
		if resta > 0 and randf() < 0.55:
			dici("Manca ancora €%d, eh. Nun me l'aggio scurdato." % resta)
		else:
			dici(str(CHIACCHIERE[randi() % CHIACCHIERE.size()]))
		var a = parti.get("anim", null)
		if a != null and a.has_method("action"):
			a.action("parla")
