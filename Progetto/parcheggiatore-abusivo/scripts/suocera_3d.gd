extends StaticBody3D
## **Donna Cuncetta** — 'a suocera (0.65)
##
## Il quarto gradino della scala dei guai (vedi `GameManager`, «'A SCALA
## D''E GUAIE»): quando si resta indietro con le spese per quattro sere di
## fila, la mamma di Nunzia si trasferisce nel vascio «pe' da' 'na mano».
## Si siede sul **tuo** letto e non se ne va finché non hai pagato tutto.
##
## Non si tocca e non si compra: parla. Ogni mattina ti prende qualche euro
## dalla giacca per il lotto (`_matina_d_e_guaie`), e mentre stai in casa
## commenta. È la conseguenza più comica della scala, e deve esserlo: il
## guaio vero arriva la sera dopo, quando la porta non si apre più.

var parti: Dictionary = {}
var bolla: Node3D = null

var _prossima: float = 0.0
var _t: float = 0.0

const FRASE := [
	"I' t''o dicevo a Nunzia: chisto è nu parcheggiatore, nun è nu marito.",
	"Stu lietto è tuosto. Dimane portame 'nu materasso buono, cu 'e sorde ca nun tiene.",
	"'A figlia mia s'avev''a spusà 'o salumiere. Almeno mo' magnavamo.",
	"Chesta è 'a casa d''a figlia mia. Tu ce staje 'n prestito.",
	"Aggio jucato 'o 17 e 'o 48. 'O 48 è 'o muorto che parla. Tu.",
	"Quanno paghe tutto me ne vaco. Ma fa' ampressa, ca 'a telenovela a Casoria 'a perdo.",
	"Ma tu 'e machine 'e posteggie o 'e ccunte?",
]


func _ready() -> void:
	add_to_group("suocera")
	_prossima = randf_range(3.0, 7.0)


func get_interact_prompt(_da: Vector3) -> String:
	return "Donna Cuncetta — [E] siente che dice"


func player_interact() -> void:
	dici(str(FRASE[randi() % FRASE.size()]), 4.2)


func dici(testo: String, durata: float = 3.6) -> void:
	if bolla != null and is_instance_valid(bolla) and bolla.has_method("say"):
		bolla.say(testo, durata)


func _process(delta: float) -> void:
	_t += delta
	var a = parti.get("anim", null)
	if a != null and a.has_method("sit") and a.has_method("is_sitting") \
			and not a.is_sitting():
		a.sit(true)
	if not GameManager.dentro_casa:
		return
	_prossima -= delta
	if _prossima <= 0.0:
		_prossima = randf_range(12.0, 20.0)
		dici(str(FRASE[randi() % FRASE.size()]))
