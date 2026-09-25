extends StaticBody3D
## PortaCasa — 'a porta d''o vascio, 'a fore e 'a dintro
##
## Lo stesso script per tutt'e due i versi. Fuori è la porta bassa nel
## vicolo dietro alla piazza; dentro è il pezzo di legno che ti riporta in
## strada. Cambia solo `verso_dentro`.

var vascio: Node = null
var verso_dentro: bool = true


func _ready() -> void:
	# Senza questo gruppo il raggio dell'interazione trova la porta e poi
	# la butta via: vedi GRUPPI_BERSAGLIO in player_fps.gd.
	add_to_group("porte_casa")


# **'O biglietto ncopp'â porta (0.52).**
#
# Il capo: *"il tipo di giornata si sa la mattina, dal biglietto sulla
# porta"*. È la riga che trasforma una giornata speciale da sorpresa a
# decisione: se leggi che oggi c'è il mercato **prima di uscire**, puoi
# scegliere di andare alla bacheca invece che in piazza. Se lo scopri
# quando sei già in piazza da un'ora, è solo una cosa che ti è capitata.
#
# Sta sulla porta e non in un pannello perché la porta la si attraversa
# per forza, e una cosa che si legge per forza non ha bisogno di un tasto.
func get_interact_prompt(_da: Vector3) -> String:
	if not verso_dentro:
		var big := ""
		if GameManager.e_speciale():
			big = "   ·   %s" % GameManager.biglietto()
		return "'A porta — [E] esce fore%s" % big
	if GameManager.giornata_scaduta:
		return "'A casa toia — [E] trase (so' 'e %s, t'aspettano)" \
			% GameManager.orologio()
	var dovuto: int = GameManager.spese_dovute()
	if dovuto > 0:
		return "'A casa toia — [E] trase · ce vonno ancora €%d" % dovuto
	return "'A casa toia — [E] trase"


func player_interact() -> void:
	if vascio == null or not is_instance_valid(vascio):
		return
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null:
		return
	if verso_dentro:
		vascio.entra(pl)
	else:
		vascio.esci(pl)
