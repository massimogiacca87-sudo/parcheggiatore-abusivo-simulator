extends StaticBody3D
## DecoroUtile — i mobili del salotto che si usano davvero
##
## Sedia e tavolino non sono decorazione: sono due verbi. Ma il gioco
## aggancia i bersagli con un raggio fisico e col gruppo, quindi un mobile
## fatto di soli `MeshInstance3D` non lo si può guardare né premere [E].
##
## Questo nodo è quel corpo: un cilindro invisibile appoggiato sopra al
## mobile, nel gruppo `decoro`, con le due funzioni che il player si aspetta
## di trovare (`get_interact_prompt` e `player_interact`). La zona ne mette
## uno dentro l'holder della decorazione, così se il giocatore la sposta si
## sposta pure il punto dove si può premere.

const LAYER_WORLD: int = 1

## "sedia" oppure "tavolino".
var id: String = ""

## Solo per il tavolino: quanto manca alla prossima tazzulella.
var _cafe_pronto: float = 0.0

## Quale copia e', dentro a `GameManager.placed_decor`. Serve a poterla
## raccogliere: senza, "togli questa sedia" non saprebbe quale.
var indice: int = -1


func setup(quale: String, altezza: float, raggio: float,
		quale_copia: int = -1) -> void:
	id = quale
	indice = quale_copia
	name = "usa_%s_%d" % [quale, maxi(0, quale_copia)]
	collision_layer = LAYER_WORLD
	collision_mask = 0
	add_to_group("decoro")

	var forma := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.height = altezza
	cil.radius = raggio
	forma.shape = cil
	forma.position = Vector3(0, altezza * 0.5, 0)
	add_child(forma)

	if id == "radio":
		set_process(false)
	elif id == "tavolino":
		# La prima tazzulella sta già lì quando compri il tavolino: se no i
		# primi cinquanta secondi sembra rotto.
		_cafe_pronto = 0.0
		set_process(true)
	else:
		set_process(false)


func _process(delta: float) -> void:
	if _cafe_pronto > 0.0:
		_cafe_pronto = maxf(0.0, _cafe_pronto - delta)


func get_interact_prompt(_da: Vector3) -> String:
	match id:
		"sedia":
			return "[E] assettate nu poco"
		"tavolino":
			if _cafe_pronto > 0.0:
				return "'A machinetta sta ancora saglienno (%ds)" % int(ceil(_cafe_pronto))
			return "[E] piglia 'a tazzulella 'e cafè  ·  [F] 'o piglie 'n mano"
		"radio":
			if GameManager.radio_traccia == "":
				return "[E] appicce 'a radio  ·  [F] 'o piglie 'n mano"
			return "[E] cagna canzone (%s)  ·  [F] 'o piglie 'n mano" \
				% GameManager.radio_nome()
		"ombrellone":
			return "[F] piglia ll'ombrellone e miettelo n'ata parte"
		"piante":
			return "[F] piglia 'e piante e miettele n'ata parte"
	return ""


func player_interact() -> void:
	match id:
		"sedia":
			var player := get_tree().get_first_node_in_group("player")
			if player and player.has_method("assettate"):
				player.assettate(self)
		"radio":
			# Un giro di manopola. L'ultimo scatto la spegne e la musica
			# torna a farla la regia, secondo l'ora e la situazione.
			var t := GameManager.radio_avanti()
			SoundManager.play("pop", -10.0, 1.25 if t != "" else 0.75)
			GameManager.event_started.emit(
				"Radio: %s" % GameManager.radio_nome())
		"tavolino":
			if _cafe_pronto > 0.0:
				return
			_cafe_pronto = GameManager.TAVOLINO_ATTESA
			# Stesso caffè del banco del bar — spinta, calma e ossa — ma
			# senza pagarlo e senza attraversare la piazza. È il senso dei
			# diciotto euro: il bar te lo porti a casa.
			GameManager.caffe_al_banco()
			GameManager.event_started.emit("Cafè d''o tavulino tujo. Aggratis.")


## **[F] la raccoglie.**
##
## Adesso che se ne possono avere piu' d'una e che ognuna va dove la metti
## tu, doveva esserci il modo di ripensarci: appoggiata storta, restava
## storta per sempre. Con [F] torna nello zaino e la riappoggi dove vuoi —
## senza ricomprarla.
func player_vandalize() -> void:
	if indice < 0:
		return
	var tolto := GameManager.togli_decor(indice)
	if tolto == "":
		return
	SoundManager.play("pop", -8.0, 1.35)
	GameManager.event_started.emit("Ripigliata. Sta dint''o zaino [I].")
