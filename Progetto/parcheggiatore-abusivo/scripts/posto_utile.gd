extends StaticBody3D
## PostoUtile — le cose della strada con cui si può fare qualcosa
##
## **Il problema che risolve.** La città era piena di roba costruita bene e
## buona a niente: l'edicola votiva col lumino acceso, la fontanella che
## zampilla, le bancarelle del mercato col telo colorato. Tutta scenografia.
## Ci passi accanto, non succede niente, e dopo due giri smetti di guardarla.
##
## Un oggetto con cui si può fare *una cosa sola*, anche piccola, smette di
## essere fondale e diventa un posto. E la cosa piccola qui è quasi sempre la
## stessa — rimetterti in sesto — perché è l'unica risorsa che scarseggia
## davvero in un turno.
##
## **Perché un solo script per tutti.** Sono tutti la stessa meccanica con
## parole diverse: guardi, premi E, paghi (a volte), ti torna qualcosa,
## qualcuno dice una battuta, e per un po' non si ripete. Scriverne cinque
## uguali avrebbe voluto dire cinque posti dove sbagliare.

const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")

## Che roba è. Decide prompt, prezzo, effetto e battute.
##
## - `edicola`    l'edicola votiva: ti fai il segno della croce. È gratis, e
##                serve a calmarti — cioè a far scendere il sospetto. Non è
##                superstizione da gioco: uno fermo davanti a un'edicola con
##                le mani giunte non è uno che sta posteggiando abusivamente,
##                ed è esattamente per questo che funziona.
## - `fontanella` bevi. Poca roba, ma gratis e sempre lì.
## - `bancarella` compri quello che c'è sul banco. Costa poco e rende bene.
## - `panchina`   ti siedi un momento. Gratis, recupero lento.
## - `bar`        un caffe' al banco. Un euro, e per un quarto di minuto
##                si corre. E' anche il posto dove il vigile si ferma:
##                mentre lui sta a chiacchierare col barista, tu lavori.
@export var tipo: String = "edicola"
## Ogni quanti secondi si può rifare. Senza, ci si accampa davanti
## all'edicola e si va a sospetto zero per sempre.
@export var riposo: float = 22.0

const DATI := {
	"edicola": {
		"prompt": "'A Maronna — [E] fatte 'o segno d''a croce",
		"costo": 0, "hp": 6.0, "calore": -18.0,
		"dice": ["'A Maronna t'accumpagna.", "Salute a nuje.",
			"Signò, faccio chello ca pozzo.", "Nu poco 'e pace pure a me."],
		"evento": "Nu segno 'e croce. 'O core s'è calmato nu poco.",
	},
	"fontanella": {
		"prompt": "'A funtanella — [E] vive nu surzo",
		"costo": 0, "hp": 9.0, "calore": -6.0,
		"dice": ["Acqua 'e Napule.", "Ah, mo' sì.", "Fresca fresca."],
		"evento": "Nu surzo d'acqua: te sî arripigliato nu poco.",
	},
	"bancarella": {
		"prompt": "'O banco — [E] pigliate quaccosa (€%d)",
		"costo": 3, "hp": 13.0, "calore": 0.0,
		"dice": ["Tutto frisco 'e stammatina!", "Bella 'a frutta!",
			"Statte buono, guagliò."],
		"evento": "Nu poco 'e frutta: cchiù forte 'e primma.",
	},
	"bar": {
		"prompt": "'O bar — [E] nu cafe' ar banco (€%d)",
		"costo": 1, "hp": 12.0, "calore": -14.0,
		"dice": ["Nu cafe'! E ccà nun se scherza.",
			"Ristretto, comm'a Ddio cumanda.", "Zuccarato? Gia' fatto.",
			"Chisto te sceta pure 'e muorte."],
		"evento": "Cafe' ar banco: mo' se cammina buono.",
	},
	# **'O banco d''o bar, pe' s'appoggià** (0.64). Il posto accanto al
	# banco non aveva un tipo, e ricadeva sull'edicola: guardando di fianco
	# al bancone usciva «'A Maronna — fatte 'o segno d''a croce».
	"appoggio": {
		"prompt": "'O banco — [E] appoggiate nu mumento",
		"costo": 0, "hp": 4.0, "calore": -10.0,
		"dice": ["Nu mumento 'e pace.", "Ccà nisciuno te dice niente.",
			"'O barista te fa 'nu cenno.", "Se sta buono, appuggiate."],
		"evento": "Appuggiato ô banco: pare ca staje 'e passaggio.",
	},
	"panchina": {
		"prompt": "'A panchina — [E] assèttate nu momento",
		"costo": 0, "hp": 11.0, "calore": -9.0,
		"dice": ["Ah... 'e ccosce.", "Cinche minute e po' se torna.",
			"Chi se ferma è perduto. Ma pure chi cammina sempe."],
		"evento": "Cinche minute assettato. Se sta meglio.",
	},
}

var _cd: float = 0.0
var _bubble: Node3D = null


func _ready() -> void:
	add_to_group("attivita")
	add_to_group("posti_utili")
	collision_layer = 1
	collision_mask = 0


func _dati() -> Dictionary:
	return DATI.get(tipo, DATI["edicola"])


func get_interact_prompt(_da: Vector3) -> String:
	var d := _dati()
	if _cd > 0.0:
		return ""
	var costo: int = int(d["costo"])
	if costo > 0:
		if GameManager.money < costo:
			return "%s — nun tiene manco chesto" % str(d["prompt"]).split(" — ")[0]
		return str(d["prompt"]) % costo
	return str(d["prompt"])


func player_interact() -> void:
	if _cd > 0.0:
		return
	var d := _dati()
	var costo: int = int(d["costo"])
	if costo > 0:
		if GameManager.money < costo:
			SoundManager.play("fail", -10.0, 0.9)
			return
		GameManager.money -= costo
		GameManager.money_changed.emit(GameManager.money)
		SoundManager.soldi(costo, -4.0)
	else:
		SoundManager.play("pop", -12.0, 0.8)

	# **Ogni posto fa il suo rumore.** Il caffe' al banco si sorseggia, la
	# fontanella si beve, dalla bancarella si stappa qualcosa, e davanti
	# all'edicola votiva non si fa rumore per niente — e' l'unico posto
	# dove il silenzio e' il suono giusto.
	match tipo:
		"bar":
			SoundManager.play("sorso_caffe", -6.0)
		"fontanella":
			SoundManager.play("sorso", -7.0)
		"bancarella":
			SoundManager.play("bottiglia", -8.0)

	_cd = riposo
	# Il caffe' non e' solo ossa e sospetto: sono anche quindici secondi di
	# gambe buone. E' l'unico posto utile che cambia come ti muovi.
	if tipo == "bar":
		GameManager.caffe_al_banco()
	var hp: float = float(d["hp"])
	if hp > 0.0:
		GameManager.heal_player(hp)
	var cal: float = float(d["calore"])
	if cal < 0.0:
		GameManager.add_heat(cal)

	# Il segno della croce non lava solo il sospetto: davanti alla Maronna
	# non ci si presenta col fierro in mano, e chi ti vede se lo ricorda.
	if tipo == "edicola":
		GameManager.calma_le_stelle(0.5)

	if _bubble == null:
		_bubble = SpeechBubbleScript.new()
		_bubble.position = Vector3(0, 2.5, 0)
		add_child(_bubble)
	var frasi: Array = d["dice"]
	_bubble.say(str(frasi[randi() % frasi.size()]), 2.4)
	GameManager.event_started.emit(str(d["evento"]))


func _process(delta: float) -> void:
	if _cd > 0.0:
		_cd = maxf(0.0, _cd - delta)
