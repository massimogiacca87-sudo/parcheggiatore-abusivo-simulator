extends CharacterBody3D
## **Don Gaetano 'o Prufessore** — 'o cchiù viecchio parcheggiatore d''a zona.
##
## Il capo, chiudendo il punto 4: *«Se vuoi puoi anche aggiungere un
## personaggio tutorial al quale è possibile chiedere delucidazioni su
## meccaniche del gioco.»*
##
## Il tutorial di questo gioco sta in tre posti, e sono tre posti diversi
## apposta:
##
## 1. **'O pannello** (tasto T, dalla 0.52): sei pagine, tutto scritto. È
##    per chi lo va a cercare, e chi lo va a cercare è chi già gioca.
## 2. **'E cunziglie 'e ll'ata gente** (`Chiacchiere.CUNZIGLIE`, 0.56): una
##    riga alla volta, e solo quando quella riga serve adesso. È per chi
##    non sa nemmeno che c'è qualcosa da sapere.
## 3. **Chisto ccà**: uno a cui puoi **chiedere**. Ed è la differenza: gli
##    altri due parlano quando decidono loro, lui risponde quando vuoi tu.
##
## Non è un manuale con le gambe. È un vecchio seduto su una sedia di
## plastica davanti al bar, che ha fatto questo mestiere per trent'anni e
## adesso guarda gli altri farlo. Quello che sa te lo dice come lo direbbe
## uno così: prima la cosa, poi il motivo, e mai più di tre righe. Le
## risposte lunghe stanno nel pannello; lui ti dà quella che ti serve
## adesso, e la dà come si dà un consiglio, non come si spiega una regola.
##
## Perché non è un elenco solo: perché **quattro voci per volta** è quanto
## sta nel pannello delle risposte (`GameManager.boss_dialogue_opened`), e
## quel pannello c'è già, funziona già ed è quello con cui il giocatore ha
## già parlato a Borrelli, al vigile e ai guaglioni. Una quarta voce fa
## girare pagina, e si gira finché non hai chiesto tutto.

const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const Human := preload("res://scripts/human_builder.gd")
const Tex := preload("res://scripts/textures.gd")

## Quanto resta a schermo una risposta sua.
const QUANTO_DICE: float = 9.0

## **'O programma d''o curso.** Ogni voce: come si chiede, e cosa risponde.
## L'ordine è quello in cui servono davvero, non quello dell'alfabeto:
## prima come si campa, poi come non ci si fa arrestare, poi come si cresce.
const LEZIONE := [
	{"dimanna": "Comme se fa 'a mancia?",
	 "dice": "Fischia [F] quanno uno cerca 'o posto, e po' 'o faje manuvrà cu 'e braccia. Quanno s'è mise buono, ce vaje 'nnanze e chiéde. 'A mancia se dà a chi ha fatto quaccosa, no a chi sta llà."},
	{"dimanna": "E si chillo nun pava?",
	 "dice": "Nun 'o ffà pavà 'e forza, ca chillo se ricorda 'a faccia toia. Meglio perdere dieci euro ogge e truvà 'a stessa machina dimane. Chi te vò bene pava ogne vota."},
	{"dimanna": "'O vigile, comme 'o tratto?",
	 "dice": "Nun 'o guardà 'nfaccia: guarda **addó** guarda isso. Quanno se piglia 'o cafè o se mette a chiacchiarià, nun vede niente — chille so' 'e minute buone. E 'e vinte smonta e se ne va 'a casa."},
	{"dimanna": "Quanno so' 'e minute buone?",
	 "dice": "'A matina se fatica assaje e se piglia poco. Doppo 'e sette 'a gente esce pe' magnà, e chi esce pe' magnà tene 'o portafoglio apierto. E 'a sera 'o vigile nun ce sta."},
	{"dimanna": "Chisti pugne me stancano.",
	 "dice": "E certo: sette pugne e sî fernuto. 'O sciato torna chiano chiano, 'nu cafè te ne rimette 'a meta' e 'a nuttata tutto quanto. Piglia 'nu fierro 'a ll'armiere: cu chillo nun te stanche."},
	{"dimanna": "'E stemme 'e ll'auto?",
	 "dice": "'O Zio t''e ccatta, e pava bbuono. Ma chella è 'a cosa cchiù vistosa ca puó fà: uno chinato ncopp'ô cofano 'e n'ata machina se vede 'a cinquanta metre. E nun t''e ffà vedé manco quanno 'e vinne."},
	{"dimanna": "Che m'accatto pe' primma cosa?",
	 "dice": "'A coppola. Dudece euro, e 'a gente te parla n'ata manera — pure chi te pava. Doppo 'e piante e 'a radio p''a piazza toia. 'E luminarie so' care, ma 'a sera s''e ppagano 'a sole."},
	{"dimanna": "Comme me piglio n'ata piazza?",
	 "dice": "Cu 'e sorde, o cu 'e mmane. Cu 'e sorde è cchiù caro e nun se scorda nisciuno; cu 'e mmane è cchiù ampresso e po' 'a sera te vene a truvà chi 'a teneva. Pienzace primma."},
	{"dimanna": "E 'a famiglia?",
	 "dice": "'A sera se torna a casa e se consegna. Chello ca nun cunzigne, tua moglie 'o ssape 'o stesso. E si nun cunzigne maje, 'nu juorno t'arape 'a porta e nun ce stanno cchiù."},
	{"dimanna": "Quacche cosa ca nisciuno dice?",
	 "dice": "Doje. 'A signora d''e nummere nun è pazza, e 'na vota ncopp'a vinte t'azzecca 'a cinquina. E 'e guagliune cu 'o pallone: si nzerti 'nu gol dint'â porta lloro, quaccuno te dà 'nu poco 'e sorde — quatto vote 'o juorno, po' basta."},
]

const SAY_IDLE := [
	"Trent'anne aggio fatto. Trenta.",
	"Mo' me guardo 'e ate, e me sta bbuono accussì.",
	"'O mestiere è tutto dint'ê ccape, no dint'ê mmane.",
	"Uè guagliò. Si te serve, sto ccà.",
	"'A città cagna, 'o mestiere no.",
]
const SAY_SALUTO := [
	"Assettate 'nu momento. Che vuó sapé?",
	"Dimme, guagliò.",
	"E parla, ca nun tengo n'atu ciento anne.",
]
const SAY_ADDIO := [
	"Va', va'. E statte accuorto.",
	"Mo' vattenne a fatecà, ca 'e machine nun aspettano.",
	"Bravo. Mo' 'o ssaje.",
]

## Quante voci stanno nel pannello. La quarta è sempre «n'ata cosa» o
## «basta accussì», quindi di domande ne entrano tre per pagina.
const PE_PAGINA: int = 3

var _bubble: Node3D
var _visual_root: Node3D
var _idle_cd: float = 0.0
var _pagina: int = 0
var _aperto: bool = false


func _ready() -> void:
	add_to_group("maestro")
	collision_layer = 4
	collision_mask = 0
	_build_collision()
	_build_visual()
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 2.1, 0)
	add_child(_bubble)
	_idle_cd = randf_range(6.0, 14.0)


func _build_collision() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.7
	shape.shape = capsule
	shape.position = Vector3(0, 0.85, 0)
	add_child(shape)


func _build_visual() -> void:
	_visual_root = Node3D.new()
	add_child(_visual_root)
	# Vecchio, basso, panza, capelli bianchi — e **la coppola**, che è la
	# cosa che dice chi è prima ancora che apra bocca: è l'oggetto che in
	# questo gioco vuol dire «sono del quartiere».
	var parts := Human.build(Color(0.42, 0.40, 0.36), Color(0.22, 0.23, 0.26),
		"", 1.63, {
			"belly": 0.72, "bald": true, "moustache": true,
			"hair": Color(0.88, 0.88, 0.86),
			# (0.66) Il maestro: ha visto tutto, e ci ride sopra.
			"palpebre": "stanche", "sopracciglia": "dritte", "naso": "grosso",
			"bocca": "sorriso", "barba": "", "rughe": "vecchio",
			"colletto": true, "cintura": true, "catenina": false,
		})
	_visual_root.add_child(parts["root"])
	if not parts["bones"].is_empty() and parts["head"] != null:
		_a_coppola(parts["head"])
	_a_sedia()


## **'A coppola.** Nel gioco la coppola non è un cappello: è la cosa che
## dice «songo 'e ccà». Addosso a lui vuol dire che ci è nato, in questo
## mestiere, e si vede prima che apra bocca.
##
## Gli assi della testa sono misurati, non indovinati (`tools/prova_manella`):
## **giù è −Y, 'nnanze è +Z**. Il visierino va davanti, cioè verso +Z — la
## stessa riga che nella 0.51 era sbagliata e teneva la visiera del vigile
## appiccicata alla nuca.
func _a_coppola(testa: Node3D) -> void:
	var panno := Tex.flat(Color(0.30, 0.28, 0.24), 0.86)
	var calotta := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 0.152
	cm.height = 0.304
	cm.radial_segments = 14
	cm.rings = 7
	cm.is_hemisphere = true
	calotta.mesh = cm
	calotta.position = Vector3(0, 0.132, 0.006)
	calotta.scale = Vector3(1.03, 0.52, 1.08)
	calotta.material_override = panno
	testa.add_child(calotta)

	var visiera := MeshInstance3D.new()
	var vm := BoxMesh.new()
	vm.size = Vector3(0.19, 0.018, 0.10)
	visiera.mesh = vm
	visiera.position = Vector3(0, 0.128, 0.150)
	visiera.material_override = panno
	testa.add_child(visiera)


## **'A sedia 'e plastica, appuiata 'a llato.**
##
## All'inizio ce l'avevo messo **sopra**, e la prima foto ha detto subito
## che non andava: il rig di questo gioco sta in piedi, quindi quello che si
## vedeva era un vecchio ritto in mezzo a un parallelepipedo rosso.
## Sedere un rig per davvero vuol dire piegare le ossa, e le ossa di questo
## progetto si toccano solo dopo averle misurate — non per un soprammobile.
##
## Allora la sedia sta **accanto a lui**, vuota. Che è poi come stanno le
## sedie di plastica davanti ai bassi: ce n'è sempre una fuori, e chi
## comanda quella sedia sta in piedi lì a fianco. Dice la stessa cosa —
## *chisto ccà nun sta passanno, ce sta* — e non ha bisogno di mentire su
## come è fatto il personaggio.
func _a_sedia() -> void:
	var plastica := Tex.flat(Color(0.72, 0.24, 0.20), 0.75)
	for pezzo in [
			[Vector3(0.44, 0.05, 0.42), Vector3(0.78, 0.44, -0.30)],
			[Vector3(0.44, 0.42, 0.05), Vector3(0.78, 0.66, -0.50)]]:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = pezzo[0]
		m.mesh = bm
		m.position = pezzo[1]
		m.material_override = plastica
		_visual_root.add_child(m)
	for lato in [0.61, 0.95]:
		for z in [-0.12, -0.48]:
			var g := MeshInstance3D.new()
			var gm := BoxMesh.new()
			gm.size = Vector3(0.045, 0.44, 0.045)
			g.mesh = gm
			g.position = Vector3(lato, 0.22, z)
			g.material_override = plastica
			_visual_root.add_child(g)


func _process(delta: float) -> void:
	var pl := get_tree().get_first_node_in_group("player")
	if pl != null and pl is Node3D:
		var d: Vector3 = (pl as Node3D).global_position - global_position
		d.y = 0.0
		if d.length() < 9.0 and d.length() > 0.2:
			rotation.y = lerp_angle(rotation.y, atan2(-d.x, -d.z),
				1.0 - exp(-4.0 * delta))
	if _aperto:
		return
	_idle_cd -= delta
	if _idle_cd <= 0.0:
		_idle_cd = randf_range(14.0, 30.0)
		if randf() < 0.45:
			_say(SAY_IDLE[randi() % SAY_IDLE.size()])


func _say(t: String, quanto: float = 4.0) -> void:
	if _bubble:
		_bubble.say(t, quanto)


func get_interact_prompt(_da: Vector3) -> String:
	return "Don Gaetano 'o Prufessore — [E] dimannace 'na cosa"


func player_interact() -> void:
	if _aperto:
		return
	_aperto = true
	_pagina = 0
	_say(SAY_SALUTO[randi() % SAY_SALUTO.size()])
	GameManager.dialogo_con = self
	GameManager.boss_dialogue_opened.emit(_risposte())


## Le tre domande di questa pagina, più la voce per girare.
func _risposte() -> Array:
	var fore: Array = []
	var da: int = _pagina * PE_PAGINA
	for i in range(PE_PAGINA):
		var k: int = da + i
		if k < LEZIONE.size():
			fore.append({"text": str(LEZIONE[k]["dimanna"])})
	# L'ultima riga: se c'è ancora roba si gira pagina, se no si saluta.
	if da + PE_PAGINA < LEZIONE.size():
		fore.append({"text": "E che ata cosa?"})
	else:
		fore.append({"text": "Basta accussì, grazie."})
	return fore


func answer(i: int) -> void:
	var da: int = _pagina * PE_PAGINA
	var k: int = da + i
	# L'ultima riga della pagina: o gira, o chiude.
	if i >= PE_PAGINA or k >= LEZIONE.size():
		if da + PE_PAGINA < LEZIONE.size():
			_pagina += 1
			GameManager.boss_dialogue_opened.emit(_risposte())
		else:
			_chiude()
		return
	var voce: Dictionary = LEZIONE[k]
	_say(str(voce["dice"]), QUANTO_DICE)
	SoundManager.play("pop", -12.0, 0.88)
	# **E resta scritto 'ncoppa.** Una risposta di tre righe dentro a un
	# fumetto che sparisce non si legge: il fumetto la dice, il cartello in
	# alto la tiene lì mentre la leggi.
	GameManager.event_started.emit("Don Gaetano: %s" % str(voce["dice"]))
	# Il pannello resta aperto sulla stessa pagina: chi ha chiesto una cosa
	# di solito ne chiede due.
	GameManager.boss_dialogue_opened.emit(_risposte())


func _chiude() -> void:
	_aperto = false
	_say(SAY_ADDIO[randi() % SAY_ADDIO.size()])
	if GameManager.dialogo_con == self:
		GameManager.dialogo_con = null
	GameManager.boss_dialogue_closed.emit()
