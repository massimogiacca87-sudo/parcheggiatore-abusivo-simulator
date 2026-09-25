extends StaticBody3D
## Letto — 'o posto addò fernesce 'a jurnata
##
## **È l'unico modo di passare al giorno dopo**, e questa è la scelta di
## progetto che conta. Prima la giornata finiva da sola quando il
## cronometro arrivava a zero: il riepilogo ti cadeva addosso in mezzo a
## una manovra, e "domani" era una cosa che succedeva a te.
##
## Adesso domani lo decidi tu, e per deciderlo devi tornare a casa: cioè
## devi smettere di lavorare, attraversare il quartiere, entrare, e passare
## davanti a chi ti sta aspettando. Il letto è due metri più in là della
## moglie, e non è un caso.

var vascio: Node = null


func _ready() -> void:
	add_to_group("letto")


func get_interact_prompt(_da: Vector3) -> String:
	var scoperto: int = GameManager.spese_dovute()
	var extra: String = ""
	if scoperto > 0:
		extra = " · resta €%d 'a pavà" % scoperto
	if GameManager.giornata_scaduta:
		return "'O lietto — [E] va' a durmi'%s" % extra
	return "'O lietto — [E] va' a durmi' (so' 'e %s)%s" \
		% [GameManager.orologio(), extra]


func player_interact() -> void:
	if vascio == null or not is_instance_valid(vascio):
		return
	# Prima di dormire, se sei rientrato tardi, lei ha una cosa da dirti —
	# e da chiederti. Il pannello se ne accorge da solo.
	SoundManager.play("sbadiglio", -4.0)
	# Il riepilogo lo fa l'interfaccia, che si aggancia a `shift_ended`:
	# qui basta chiudere la giornata.
	GameManager.vai_a_dormire()
