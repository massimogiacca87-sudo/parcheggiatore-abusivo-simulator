extends CharacterBody3D
## Vicino3D — chi sta sempe llà e sape 'e ccose
##
## **'O vicinato fa 'na cosa, nun dice 'na cosa (0.55).**
##
## Alla 0.54 questi quattro erano bocche: dicevano dove stava il vigile,
## quante stelle avevi addosso, qual era il lavoretto che pagava di più.
## Il capo: *"le informazioni che ti danno le persone sono superflue"*.
##
## Aveva ragione, e il motivo vale la pena di scriverlo perché è facile
## rifare lo stesso errore. Quelle notizie erano **utili ma non
## memorabili**: ti cambiavano i trenta secondi dopo e poi sparivano, e
## dopo tre giorni erano una riga di HUD con una faccia davanti. Peggio:
## erano cose che il giocatore poteva **vedere da solo** girando l'angolo,
## e pagare due euro per sapere una cosa che stai per vedere gratis è un
## cattivo affare che si capisce subito.
##
## Adesso ognuno **fa** qualcosa, e sono le tre cose che qui scarseggiano:
##
##   * **Nunzia d''o bar** — 'o cafè: sospetto giù e ossa su, come al banco.
##   * **Totore 'o guardiano** — t'arape 'o purtone: quaranta secondi in
##     cui il quartiere smette di guardarti, e le stelle si sciolgono.
##   * **Rosa d''o vico** — 'a frittata dint'ô panaro: ossa, una volta al
##     giorno.
##   * **Mimmo 'o guaglione** — l'unica notizia rimasta, e resta perché
##     **porta da qualche parte**: sa dove sta oggi 'a Signora d''e nummere.
##
## **E chiedono.** Ognuno vuole un piacere piccolo — un caffè, una
## sigaretta, il pane, un gelato — e il piacere costa. Non è il prezzo:
## è quello che rende lo scambio uno scambio invece di un servizio. A chi
## ti vuole bene non si paga niente: sopra a +40 (`Gente.AMICO`) è gratis.
##
## Il rapporto è **lo stesso** dei clienti fissi
## (`GameManager.muove_rapporto`), e passa dentro al salvataggio: Rosa si
## ricorda di ieri.

const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const Human := preload("res://scripts/human_builder.gd")
const Tex := preload("res://scripts/textures.gd")
const Gente := preload("res://scripts/gente.gd")

## Quanto rimette in sesto 'a frittata 'e Rosa.
##
## Meno del cornetto della cornetteria (60) e **una volta al giorno sola**,
## e i due numeri vanno letti insieme. Il capo ha chiesto che le ossa non
## si rimettano da sole e che il cornetto sia la cura: se Rosa curasse
## quanto lui, o si potesse tornare da lei ogni due minuti, la regola
## sarebbe scritta in un file e disfatta in un altro. Così invece è la
## toppa di giornata — la trovi, la paghi, e poi fino a stasera ti tieni
## quello che hai.
const FRITTATA_OSSA: float = 26.0

## Quanto guadagna 'o rapporto ogni piacere fatto.
const PIACERE_RAPPORTO: float = 9.0

const SAY_IDLE := {
	"nunzia_bar": ["'O ccafè è pronto!", "Uè, ma chi s'è visto.",
		"Chillo 'o bar 'e Ciro fa schifo, sà."],
	"totore": ["…", "Mh.", "'Sti guagliune.", "Aggio visto tutto, io."],
	"rosa": ["GUAGLIÒÒÒ!", "Assuntì, m'e ppuorte 'e ppummarole?",
		"'O panaro sta ccà!"],
	"mimmo": ["Uè! Uè!", "Io saccio 'na cosa.", "Nun 'o dico a nisciuno, io."],
}

var vicino_id: String = ""

var _dati: Dictionary = {}
var _visual_root: Node3D
var _bubble: Node3D
var _anim: Node = null
var _idle_cd: float = 0.0
var _guarda_cd: float = 0.0
## Il piacere si fa una volta per giornata: se no uno resta lì a pigiare E
## e la posizione del vigile diventa una minimappa gratis.
var _fatto_oggi: int = -1
## Il primo [E] saluta e dice cosa vuole, il secondo chiude lo scambio.
var _salutato: bool = false


func _ready() -> void:
	add_to_group("vicine")
	collision_layer = 4
	collision_mask = 0
	_dati = Gente.vicino(vicino_id)
	_build_collision()
	_build_visual()
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 2.1, 0)
	add_child(_bubble)
	_idle_cd = randf_range(6.0, 16.0)


func setup(id: String, pos: Vector3) -> void:
	vicino_id = id
	position = pos


func _say(text: String) -> void:
	if _bubble:
		_bubble.say(text)


func _nomme() -> String:
	return str(_dati.get("nome", "'Nu vicino"))


# ---------------------------------------------------------------------------
# Comme se vede
# ---------------------------------------------------------------------------

func _build_collision() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.8
	shape.shape = capsule
	shape.position = Vector3(0, 0.9, 0)
	add_child(shape)


func _build_visual() -> void:
	_visual_root = Node3D.new()
	add_child(_visual_root)
	var colore: Color = _dati.get("colore", Color(0.5, 0.5, 0.5))
	# Ognuno è fatto diverso: Mimmo è un ragazzino, Rosa e Nunzia due
	# donne, Totore un vecchio con la pancia. Sono quattro `Human.build`
	# con quattro opzioni diverse, e da lontano si riconoscono dalla
	# sagoma prima che dal colore.
	var opts := {}
	var alt := 1.72
	match vicino_id:
		"nunzia_bar":
			opts = {"corpo": "femmina", "hair": Color(0.16, 0.12, 0.1),
				"belly": 0.35}
			alt = 1.64
		"totore":
			opts = {"hair": Color(0.78, 0.78, 0.76), "belly": 0.9,
				"moustache": true, "bald": true}
			alt = 1.70
		"rosa":
			opts = {"corpo": "femmina", "hair": Color(0.66, 0.64, 0.6),
				"belly": 0.8}
			alt = 1.58
		"mimmo":
			opts = {"hair": Color(0.12, 0.1, 0.09), "belly": 0.0}
			alt = 1.32 # tene diece anne
	var parts := Human.build(colore, colore.darkened(0.45), "", alt, opts)
	_visual_root.add_child(parts["root"])
	_anim = parts.get("anim", null)
	# La targhetta sta **sopra alla sua testa**, non a un'altezza fissa:
	# con 2,42 per tutti, sopra a Mimmo (che è alto un metro e trenta) il
	# nome galleggiava un metro più in su, staccato da lui.
	_targa(alt + 0.34)


## 'O nomme scritto ncoppa â capa: senza, so' quatte passante fierme.
func _targa(alt: float) -> void:
	var l := Label3D.new()
	l.text = _nomme()
	l.font_size = 40
	l.pixel_size = 0.0032
	l.position = Vector3(0, alt, 0)
	# `billboard_keep_scale` è una bandiera del **materiale**
	# (`BaseMaterial3D`), non di Label3D: metterla qui non dà errore in
	# fase di scrittura e ne dà uno a ogni costruzione. È lo stesso nome
	# che alla 0.51 ha sistemato i fumetti, ed è per questo che ci sono
	# cascato — lì stava su `m`, che era il materiale dei tre quadrati.
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(1, 0.95, 0.8)
	l.outline_size = 14
	l.outline_modulate = Color(0, 0, 0, 0.85)
	l.no_depth_test = false
	# Da lontano sparisce: quattro targhette accese in mezzo alla piazza
	# sarebbero un menu, non un quartiere.
	l.visibility_range_end = 15.0
	l.visibility_range_end_margin = 3.0
	add_child(l)


## **'A notte se ne vanno a durmì** (0.55).
##
## Stavano fermi allo stesso metro ventiquattr'ore su ventiquattro, notte
## compresa: Rosa affacciata al vico alle tre di notte, Mimmo — che tiene
## dieci anni — in mezzo al largo all'una. Era la cosa che più di ogni
## altra li faceva sembrare arredamento invece che gente, perché **la
## differenza fra una persona e un cartonato è che la persona a un certo
## punto se ne va**.
##
## Adesso alla nottata (fascia 4) rientrano: non spariscono di colpo, si
## voltano verso il portone e si spengono. Chi li cerca dopo mezzanotte non
## li trova, ed è giusto — a quell'ora in strada restano 'o guardiano e 'a
## Signora, che è esattamente chi ci resterebbe davvero.
##
## Totore no: lui **è** il guardiano del palazzo, e la notte è il suo turno.
const DORMONO := {"nunzia_bar": true, "rosa": true, "mimmo": true}


func _dorme() -> bool:
	return DORMONO.has(vicino_id) and GameManager.fascia_indice() >= 4


func _process(delta: float) -> void:
	# Chi dorme non c'è: niente battute, niente [E], e non si vede.
	var fore: bool = not _dorme()
	if visible != fore:
		visible = fore
		# Il collider va spento insieme al corpo, se no resta un muro
		# invisibile in mezzo al vico — ed è il difetto peggiore di tutti,
		# perché non si vede e non si capisce.
		set_collision_layer_value(3, fore)
		if fore:
			_salutato = false
	if not fore:
		return
	_idle_cd -= delta
	if _idle_cd <= 0.0:
		_idle_cd = randf_range(9.0, 22.0)
		var voci: Array = SAY_IDLE.get(vicino_id, [])
		if not voci.is_empty() and randf() < 0.55:
			_say(str(voci[randi() % voci.size()]))
	# Si gira verso di te quando gli stai vicino: è il segnale che con
	# questo si può parlare, e costa una riga.
	_guarda_cd -= delta
	if _guarda_cd <= 0.0:
		_guarda_cd = 0.3
		var p := get_tree().get_first_node_in_group("player")
		if p != null and global_position.distance_to(p.global_position) < 7.0:
			var d: Vector3 = p.global_position - global_position
			d.y = 0.0
			if d.length() > 0.2:
				rotation.y = atan2(-d.x, -d.z)


# ---------------------------------------------------------------------------
# 'O scambio
# ---------------------------------------------------------------------------

func _amico() -> bool:
	return GameManager.rapporto(vicino_id) >= Gente.AMICO


func _gia_fatto() -> bool:
	return _fatto_oggi == GameManager.giornata


func get_interact_prompt(_from_position: Vector3) -> String:
	if _dati.is_empty() or _dorme():
		return ""
	if _gia_fatto():
		return "%s t'ha già ditto tutto pe' oggi" % _nomme()
	if _amico():
		return "[E] parla cu %s (nun vò niente)" % _nomme()
	if not _salutato:
		return "[E] parla cu %s" % _nomme()
	return "[E] %s pe' %s (€%d)" % [str(_dati["chiede"]), _nomme(),
		int(_dati["costo"])]


func player_interact() -> void:
	if _dati.is_empty() or _gia_fatto() or _dorme():
		return
	var b: Dictionary = _dati["battute"]

	# All'amico non si chiede niente: si dice e basta, subito.
	if _amico():
		_fatto_oggi = GameManager.giornata
		_say("%s: %s" % [_nomme(), str(b["amico"]) % _nutizia()])
		_effetto()
		SoundManager.play("coin", -10.0, 1.15)
		return

	if not _salutato:
		_salutato = true
		_say("%s: %s" % [_nomme(), str(b["saluto"])])
		return

	if not GameManager.paga(int(_dati["costo"])):
		SoundManager.play("fail", -9.0, 0.9)
		_say("%s: %s" % [_nomme(), str(b["senza"])])
		return

	_fatto_oggi = GameManager.giornata
	GameManager.muove_rapporto(vicino_id, PIACERE_RAPPORTO)
	SoundManager.play("coin", -6.0, 1.0)
	_say("%s: %s" % [_nomme(), str(b["pagato"]) % _nutizia()])
	_effetto()


## Chello ca succede overo, oltre â battuta.
##
## **Chesta è 'a parte ca alla 0.54 nun ce steva.** Prima il vicino diceva
## una frase e finiva lì: l'effetto *era* la frase. Adesso la frase è il
## contorno e qui succede la cosa — il caffè che ti calma, il portone che
## ti nasconde, la frittata che ti rimette in piedi.
func _effetto() -> void:
	match str(_dati["dice"]):
		"cafe":
			GameManager.caffe_al_banco()
		"ammuccia":
			_trase_ô_purtone()
		"ossa":
			GameManager.heal_player(FRITTATA_OSSA)


## **'O purtone 'e Totore.**
##
## Quaranta secondi in cui il quartiere smette di guardarti: il sospetto
## scende di brutto e le stelle, se ce ne sono, si sciolgono come se ti
## fossi infilato in un vicolo — perché è esattamente quello che hai
## fatto. È la cosa che mancava a chi si mette nei guai lontano da casa:
## un posto dove sparire che non sia la piazza tua.
const PURTONE_CALMA: float = 55.0

func _trase_ô_purtone() -> void:
	GameManager.cool_down(PURTONE_CALMA)
	if GameManager.stelle > 0:
		GameManager.azzera_stelle()


# ---------------------------------------------------------------------------
# 'E nutizie
# ---------------------------------------------------------------------------
#
# Ne è rimasta una sola, ed è l'unica che porta da qualche parte.

func _nutizia() -> String:
	match str(_dati["dice"]):
		"cafe": return _o_cafe()
		"ammuccia": return _o_purtone()
		"ossa": return _a_frittata_e_pane()
		"signora": return _addo_sta_a_signora()
	return "…"


func _o_cafe() -> String:
	return "Tiè, cavero cavero."


func _o_purtone() -> String:
	if GameManager.stelle > 0:
		return "Trase, va'. Ccà nun te vede nisciuno."
	return "'O purtone sta apierto. Si te serve, saje addò stà."


## **'O guaglione sape addò sta 'a Signora.**
##
## È l'unica notizia rimasta al vicinato, ed è rimasta per un motivo
## preciso: non ti dice una cosa che potresti vedere da solo girando
## l'angolo — ti dice **dove andare**. E quello che trovi quando ci vai
## vale una partita intera, una volta su venti.
func _addo_sta_a_signora() -> String:
	var dove: Dictionary = GameManager.signora_dove()
	if dove.is_empty():
		return "'A Signora oggi nun s'è vista. Certi juorne nun esce."
	if GameManager.signora_data:
		return "'A Signora t'ha già parlato, no? E allora che vuò 'a me."
	return "'A Signora d''e nummere oggi sta %s. Curre, primma ca se ne va." \
		% str(dove["nome"])


func _a_frittata_e_pane() -> String:
	if GameManager.health >= GameManager.HEALTH_MAX - 0.5:
		return "Tiè 'o ppane. E mangia, ca nun se sa maje."
	return "Tiè, ca t'aggio miso pure 'a frittata dint'ô panaro. Mangia."
