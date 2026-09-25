extends Node
## L'osse nun se rifanno 'a sole.
##
## Il capo: *"L'hp non sale da sola, bisogna mangiare un cornetto black and
## white disponibile però solo di notte alla cornetteria."*
##
## Due cose da dimostrare, e la prima è quella che si rompe in silenzio:
##
##   1. **'o fiatone nun ce sta cchiù** — si prendono le mazzate, si aspetta
##      un minuto senza fare niente, e le ossa devono stare **ferme dove
##      stanno**. Se risalissero anche di un punto, tutto il resto (il
##      cornetto, la spiga, il caffè) diventerebbe decorazione: basterebbe
##      girare l'angolo e contare fino a dieci;
##   2. **'o cornetto rimette 'n piede overo** — costa cinque euro, ne
##      rimette sessanta, e non si può comprare se stai già bene o se non
##      tieni i soldi.
##
## Che sia **solo di notte** lo decide `aperta`, che è la stessa manopola
## che alza la serranda: non c'è un secondo orologio da tenere in riga.

const Cornetteria := preload("res://scripts/cornetteria_3d.gd")

var _male: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	GameManager.giornata = 3
	GameManager.start_shift()

	print("=== 'O FIATONE NUN CE STA CCHIÙ ===")
	GameManager.health = 20.0
	var primma: float = GameManager.health
	# Un minuto pieno senza prenderle: e' molto piu' dei sette secondi che
	# bastavano al vecchio fiatone.
	for i in range(120):
		GameManager._process(0.5)
	print("  20  'e ossa, 'nu minuto fermo  ->  %.1f" % GameManager.health)
	_verifica("ll'osse nun so' saglite manco 'e n'unnece",
		absf(GameManager.health - primma) < 0.01)

	print("=== 'O CORNETTO ===")
	var c = Cornetteria.new()
	add_child(c)
	await get_tree().process_frame

	c.set("aperta", false)
	GameManager.money = 50
	GameManager.health = 10.0
	c.player_interact()
	_verifica("'e juorno è chiuso: nun se vénne niente",
		absf(GameManager.health - 10.0) < 0.01 and GameManager.money == 50)

	c.set("aperta", true)
	GameManager.money = 2
	c.player_interact()
	_verifica("senza 'e cinche euro nun se piglia",
		absf(GameManager.health - 10.0) < 0.01 and GameManager.money == 2)

	GameManager.money = 50
	c.player_interact()
	var atteso: float = minf(GameManager.HEALTH_MAX,
		10.0 + Cornetteria.CORNETTO_OSSA)
	print("  cu 'a notte e cinche euro: 10 -> %.1f (sorde: %d)" % [
		GameManager.health, GameManager.money])
	_verifica("'o cornetto rimette 'n piede",
		absf(GameManager.health - atteso) < 0.01)
	_verifica("e se pava", GameManager.money == 45)

	GameManager.health = GameManager.HEALTH_MAX
	GameManager.money = 50
	c.player_interact()
	_verifica("chi sta buono nun 'o pò accattà", GameManager.money == 50)

	# E che sia **il più forte** di tutti: piu' d''o cafè e d''a spiga.
	print("=== CHI RIMETTE 'E CCHIÙ ===")
	print("  cornetto %d · colazione 22 · spiga 14 · cafè %d" % [
		int(Cornetteria.CORNETTO_OSSA), int(GameManager.CAFFE_OSSA)])
	_verifica("'o cornetto è 'o cchiù forte",
		Cornetteria.CORNETTO_OSSA > 22.0
		and Cornetteria.CORNETTO_OSSA > GameManager.CAFFE_OSSA)

	print("=== %d storte ===" % _male)
	get_tree().quit()


func _verifica(che: String, ok: bool) -> void:
	if not ok:
		_male += 1
	print("  %-50s %s" % [che, "OK" if ok else "STORTO"])
