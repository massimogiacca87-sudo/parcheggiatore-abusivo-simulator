extends StaticBody3D
## Criatura3D — 'e ffiglie
##
## Sono due, stanno per terra, e chiedono. È tutto quello che fanno, ed è
## tutto quello che devono fare: **il gioco parla di loro da tre versioni
## senza averli mai fatti vedere**, e adesso che ci sono la frase del
## tutorial — *"nun è pe' me, è pp' 'e ccriature"* — smette di essere una
## battuta e diventa una cosa che hai visto.
##
## Dargli un euro non conviene in nessun modo. Non sblocca niente, non alza
## nessuna statistica utile: alza solo l'umore della moglie di un paio di
## punti e ti fa sentire meglio. Se convenisse sarebbe un'altra meccanica
## da ottimizzare, e la cosa non funzionerebbe più.

const NOMI := ["Rusella", "Ciruzzo"]
const CHIEDE := [
	["Papà, m'accatte 'o gelato?", "Papà, quanno turne?",
	 "'A maestra ha ditto ca serve 'o quaderno.",
	 "Papà, 'o pallone s'è sgonfiato."],
	["Papà, me daje ciento lire?", "Papà, ce vaco pur'io cu tte?",
	 "Papà, 'a mamma ha ditto ca nun se po'.",
	 "Papà, damme 'a mano ca t'aggia fa' vede' 'na cosa."],
]
const GRAZIE := [
	["Grazie papà!!", "Uh, mo' m''o piglio!", "Sî 'o meglio!"],
	["Grazie papà! Nun 'o dico 'a mamma.", "Evviva!", "Mo' t''o ffaccio vede'."],
]

var vascio: Node = null
var parti: Dictionary = {}
var bolla: Node3D = null
var indice: int = 0

## **'O juorno, no 'nu booleano.** Le criature si costruiscono una volta
## sola quando nasce il vascio, e niente le tocca al cambio giornata: con un
## flag l'euro ai figli si poteva dare **una volta per partita**. Dal secondo
## giorno in poi il prompt restava "sta cuntenta accussi'" per sempre.
var _giorno_dato: int = -1
var _prossima: float = 0.0
var _t: float = 0.0


func _ready() -> void:
	add_to_group("criature")
	_prossima = randf_range(4.0, 12.0)
	_t = randf() * TAU


func nome() -> String:
	return NOMI[indice % NOMI.size()]


func get_interact_prompt(_da: Vector3) -> String:
	if _giorno_dato == GameManager.giornata:
		return "%s — sta cuntenta accussì" % nome()
	if GameManager.money < 1:
		return "%s — nun tiene manco n'euro" % nome()
	return "%s — [E] dalle n'euro" % nome()


func player_interact() -> void:
	if _giorno_dato == GameManager.giornata or GameManager.money < 1:
		return
	_giorno_dato = GameManager.giornata
	GameManager.money -= 1
	GameManager.money_changed.emit(GameManager.money)
	GameManager.umore_moglie = minf(100.0,
		GameManager.umore_moglie + 3.0)
	GameManager.famiglia_cambiata.emit()
	SoundManager.play("moneta1", -3.0)
	var g: Array = GRAZIE[indice % GRAZIE.size()]
	dici(str(g[randi() % g.size()]), 3.0)


func dici(testo: String, durata: float = 3.0) -> void:
	if bolla != null and is_instance_valid(bolla) and bolla.has_method("say"):
		bolla.say(testo, durata)


func _process(delta: float) -> void:
	# Giocano anche quando non ci sei: si dondolano piano, seduti per terra.
	_t += delta * 1.6
	var r = parti.get("root", null)
	if r != null and is_instance_valid(r):
		# **Nun stanno affunnate 'n terra.** `QUOTA_BACINO["seduto"] = 0.60`
		# e' nello spazio del rig NON scalato, ma il rig di una criatura di
		# 1,16 e' scalato di 1.16/1.88 = 0,617. Con −0.34 il bacino finiva a
		# +0.03, cioe' quattro centimetri sotto alle mattonelle, e le gambe
		# piegate bucavano il pavimento. −0.23 mette il bacino a ~0,14: la
		# quota di un bambino seduto per terra.
		r.position.y = -0.23 + sin(_t) * 0.012
		r.rotation.z = sin(_t * 0.7) * 0.06
		var a = parti.get("anim", null)
		if a != null and a.has_method("sit") and not a.is_sitting():
			a.sit(false)
	if not GameManager.dentro_casa:
		return
	_prossima -= delta
	if _prossima <= 0.0:
		_prossima = randf_range(13.0, 26.0)
		var c: Array = CHIEDE[indice % CHIEDE.size()]
		dici(str(c[randi() % c.size()]))
