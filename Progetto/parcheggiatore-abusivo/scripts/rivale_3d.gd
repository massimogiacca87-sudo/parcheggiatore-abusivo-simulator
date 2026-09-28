extends CharacterBody3D
## Rivale
## Un altro parcheggiatore abusivo. Ha la sua zona, e la sua zona non è la
## tua.
##
## Per ora non si può ancora prendergliela — le meccaniche di conquista
## vengono dopo. Quello che fa adesso è **esserci**: cammina il suo giro,
## e se entri nel suo territorio ti si mette davanti, ti dice quello che
## c'è da dire, e più resti più si scalda. Se resti troppo, mena.
##
## Serve a una cosa sola, ma importante: far capire, senza scritte, che le
## altre zone appartengono a qualcuno.

const Human := preload("res://scripts/human_builder.gd")
const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const KO := preload("res://scripts/knockout.gd")
const Tex := preload("res://scripts/textures.gd")

enum Stato { GIRO, AVVISA, MINACCIA, MENA, STESO }

## Quanto lontano si accorge di te, e da quanto vicino comincia a rompere.
const VISTA: float = 18.0
const DISTANZA_AVVISO: float = 12.0
const DISTANZA_FACCIA: float = 2.6
const VELOCITA_GIRO: float = 2.0
const VELOCITA_ADDOSSO: float = 4.6

## Quanto ci mette a passare dal "che ci fai qua" alle mani.
const PAZIENZA_AVVISO: float = 6.0
const PAZIENZA_MINACCIA: float = 8.0
const DANNO: float = 11.0

## Quanto tiene aperta la trattativa dopo che ha detto il prezzo. Sei
## secondi: il tempo di leggere la cifra e decidere, non tanto da doverla
## riaprire ogni volta.
const DURATA_TRATTATIVA: float = 6.0

## Quello che dice quando gli chiedi la piazza. Il prezzo ci va dentro
## col %d — non è un dettaglio: sentirselo dire da lui vale più che
## leggerlo in un prompt.
const FRASI_TRATTATIVA: Array[String] = [
	"'A piazza mia? Songo diece anne ca stongo ccà. €%d e nun se ne parla cchiù.",
	"Uh, 'o guaglione. Vuò 'a piazza? €%d, e vide ca te sto facenno 'nu piacere.",
	"Se pò fà. €%d 'nzieme, e ogne juorno 'a percentuale. Sì o no?",
	"Chesta piazza rènne. Pe' €%d t''a lasso, ma nun me venì a chiagnere doppo.",
]
const OGNI_BOTTA: float = 1.0

## **Quaranta punti di salute, e sono tanti apposta.**
##
## Erano quattro: quattro pugni e il parcheggiatore della zona stava a
## terra. Che è troppo poco per uno che dovrebbe rappresentare "questa
## piazza appartiene a qualcuno" — e adesso che la piazza si può prendere
## davvero, quattro pugni la renderebbero gratis.
##
## A mani nude fai un punto per colpo e lui te ne toglie undici al secondo:
## non ce la fai, e non ci devi fare. Con la mazza sono quattordici colpi,
## col curtiello sette, col fierro tre. Cioe': o paghi, o vai dal ferraro.
const MAX_HP: int = 40

const SALUTI := [
	"Uè. E chi sî tu?",
	"Guagliò, ccà stongo io.",
	"Chesta è 'a zona mia.",
	"T'aggio mai visto, tu.",
]
const AVVISI := [
	"Vattenne va', ca è meglio.",
	"Ccà nun tiene niente 'a fa'.",
	"Gira 'a capa e te ne vaje.",
	"Nun me fa' perdere 'a pacienza.",
]
const MINACCE := [
	"T'aggio ditto 'e te ne ì!",
	"Mo' me staje facenno arraggià overo.",
	"Ancora ccà stai?!",
	"'A vuò fernì o t''a faccio fernì?",
]
const BOTTE := [
	"Té!", "Chist'è!", "Impara!", "Vattenne!",
]
const CONGEDO := [
	"Bravo. E nun turnà.",
	"Accussì me piace.",
	"'A prossima nun so' accussì gentile.",
]

## Chi è e che zona tiene. Li mette la città quando lo crea.
var nome: String = "Ciruzzo"
var zona_id: String = ""
## Il nome della piazza, non del parcheggiatore: serve a scriverlo nelle
## frasi e nel riepilogo quando la zona cambia padrone.
var nome_zona: String = ""
var zona_min: Vector3 = Vector3.ZERO
var zona_max: Vector3 = Vector3.ZERO

var stato: int = Stato.GIRO
## **I punti di un rivale, e perche' crescono.**
##
## Il primo che affronti ne ha quaranta: con la mazza (sette danni) sono sei
## colpi, che si fanno arretrando fra l'uno e l'altro. Ma la seconda piazza
## costa il doppio della prima e la terza il triplo, e sarebbe strano che il
## padrone della terza si stendesse con la stessa fatica del primo. Quindi
## ogni piazza che hai gia' preso rende il prossimo piu' duro di quindici
## punti: chi ne ha tre addosso ne trova uno da settanta, che con la mazza
## sono dieci colpi e con la mazza non ce la fai piu'. E' il modo in cui il
## gioco ti dice di andare dal ferraro a comprare qualcosa di meglio.
var hp_max: int = MAX_HP
var hp: int = MAX_HP

var _visual: Node3D
var _anim: Node = null
var _bubble: Node3D
var _ko: Dictionary = KO.make_state()
var _giro: Array = []
var _giro_idx: int = 0
var _attesa: float = 0.0
var _pazienza: float = 0.0
var _botta_cd: float = 0.0
var _detto: float = 0.0
## Quanto resta della trattativa aperta. Sopra zero, il prossimo [E] compra.
var _tratta: float = 0.0
## Quanti pugni a mani nude ha incassato: serve solo per dirtelo, la prima
## volta, che cosi' non ci arrivi.
var _a_vuoto: int = 0
var _targhetta: Label3D


func _ready() -> void:
	add_to_group("rivali")
	collision_layer = 4
	collision_mask = 1
	_build_visual()
	_build_collision()
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 2.2, 0)
	add_child(_bubble)
	_calcola_giro()


## La città gli assegna nome e confini. Il giro di ronda si ricava dai
## confini: quattro punti dentro alla zona, che è quello che fa uno che
## controlla un posto — non sta fermo, ci gira intorno.
func configura(id: String, nome_suo: String, dal: Vector3, al: Vector3,
		nome_della_zona: String = "") -> void:
	zona_id = id
	nome = nome_suo
	nome_zona = nome_della_zona if nome_della_zona != "" else id
	zona_min = dal
	zona_max = al
	hp_max = MAX_HP + 15 * maxi(0, GameManager.zone_mie.size() - 1)
	hp = hp_max
	_calcola_giro()
	if _targhetta:
		_targhetta.text = nome


## **'O secondo rivale nun era cchiù tuosto d''o primmo** (0.64): la forza
## si contava una volta sola, a città costruita, quando le piazze tue erano
## ancora una. La città la richiama quando una zona cambia padrone. Chi sta
## già facendo a botte (o è a terra) si tiene i punti che ha: non si
## ricarica in mezzo a una lite.
func ricalcola_forza() -> void:
	var nuovo: int = MAX_HP + 15 * maxi(0, GameManager.zone_mie.size() - 1)
	if stato == Stato.STESO or stato == Stato.MENA:
		hp_max = maxi(hp_max, nuovo)
		return
	var era_pieno: bool = hp >= hp_max
	hp_max = nuovo
	if era_pieno:
		hp = hp_max
	else:
		hp = mini(hp, hp_max)


func _calcola_giro() -> void:
	if zona_max == Vector3.ZERO:
		return
	# Sette metri di margine e non quattro: le piazzette nuove sono piccole
	# e hanno la loro roba addosso ai bordi (la cornetteria, le bancarelle),
	# e con quattro metri il giro di ronda ci passava dentro.
	var m := 7.0
	_giro = [
		Vector3(zona_min.x + m, 0.0, zona_min.z + m),
		Vector3(zona_max.x - m, 0.0, zona_min.z + m),
		Vector3(zona_max.x - m, 0.0, zona_max.z - m),
		Vector3(zona_min.x + m, 0.0, zona_max.z - m),
	]


func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	# Ogni rivale ha la sua divisa: camicia sgargiante e faccia sua, così
	# si riconoscono a distanza e non sembrano tutti lo stesso.
	var camicie := [
		Color(0.72, 0.24, 0.22), Color(0.20, 0.36, 0.56),
		Color(0.28, 0.46, 0.30), Color(0.55, 0.42, 0.16),
		Color(0.44, 0.24, 0.46),
	]
	var c: Color = camicie[abs(nome.hash()) % camicie.size()]
	var parts := Human.build(c, Color(0.16, 0.16, 0.2), "rivale", 1.79, {
		"belly": randf_range(0.25, 0.85),
		"moustache": randf() < 0.55,
		# (0.66) 'O rivale te guarda storto, sempe.
		"palpebre": "arraggiate", "sopracciglia": "arraggiate",
		"bocca": "storta",
		# Il gilet: se lo mettono anche loro, ed è il segnale che sono del
		# mestiere. Colore diverso dal tuo, che il tuo è giallo.
		# (0.66) È un pezzo del pupo, cucito sulla maglia e animato con
		# lei: la capsula appesa al petto la tagliava a dente di sega.
		"gilet": true, "gilet_colore": Color(0.95, 0.42, 0.12),
		"catenina": false,
	})
	_visual.add_child(parts["root"])
	_anim = parts.get("anim", null)

	_targhetta = Label3D.new()
	_targhetta.text = nome
	_targhetta.position = Vector3(0, 2.55, 0)
	_targhetta.font_size = 52
	_targhetta.pixel_size = 0.0022
	_targhetta.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_targhetta.modulate = Color(1.0, 0.6, 0.35)
	_targhetta.outline_size = 16
	_visual.add_child(_targhetta)


func _build_collision() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.9
	shape.shape = capsule
	shape.position = Vector3(0, 0.95, 0)
	add_child(shape)


func _di(testo: String) -> void:
	if _bubble:
		_bubble.say(testo, 2.2)
	_detto = 2.6


func _physics_process(delta: float) -> void:
	if stato == Stato.STESO:
		if KO.tick(_ko, _visual, delta):
			stato = Stato.GIRO
			hp = hp_max
			_pazienza = 0.0
		return

	_detto = maxf(0.0, _detto - delta)
	_botta_cd = maxf(0.0, _botta_cd - delta)
	_tratta = maxf(0.0, _tratta - delta)
	_lavora(delta)

	# Se la piazza è passata a te, lui smette di fare il padrone: continua
	# il suo giro e basta. Restare in stato MENA dentro a una zona che non
	# è più sua vorrebbe dire prenderle a casa propria.
	if GameManager.zona_mia(zona_id) and stato != Stato.STESO:
		stato = Stato.GIRO

	var pl := get_tree().get_first_node_in_group("player")
	var dentro := false
	var dist := INF
	if pl != null and is_instance_valid(pl):
		dist = global_position.distance_to(pl.global_position)
		dentro = _dentro_alla_zona(pl.global_position)

	match stato:
		Stato.GIRO:
			_fai_il_giro(delta)
			if dentro and dist < VISTA and not GameManager.zona_mia(zona_id):
				stato = Stato.AVVISA
				_pazienza = PAZIENZA_AVVISO
				_di(SALUTI[randi() % SALUTI.size()])
		Stato.AVVISA:
			_addosso(pl, delta, DISTANZA_AVVISO)
			if not dentro:
				_lascia_perdere()
				return
			_pazienza -= delta
			if _detto <= 0.0 and randf() < delta * 0.5:
				_di(AVVISI[randi() % AVVISI.size()])
			if _pazienza <= 0.0:
				stato = Stato.MINACCIA
				_pazienza = PAZIENZA_MINACCIA
				_di(MINACCE[randi() % MINACCE.size()])
		Stato.MINACCIA:
			_addosso(pl, delta, DISTANZA_FACCIA)
			if not dentro:
				_lascia_perdere()
				return
			_pazienza -= delta
			if _detto <= 0.0 and randf() < delta * 0.7:
				_di(MINACCE[randi() % MINACCE.size()])
			if _pazienza <= 0.0:
				stato = Stato.MENA
				GameManager.event_started.emit(
					"%s s'è scucciato 'e t''o ddicere cu 'e bbuone" % nome)
		Stato.MENA:
			_addosso(pl, delta, DISTANZA_FACCIA)
			if not dentro:
				_lascia_perdere()
				return
			if dist <= DISTANZA_FACCIA + 0.6 and _botta_cd <= 0.0:
				_botta_cd = OGNI_BOTTA
				_di(BOTTE[randi() % BOTTE.size()])
				SoundManager.pugno(-2.0)
				GameManager.screen_shake.emit(0.5)
				GameManager.damage_player(DANNO,
					"T'ha menato %s: chella nun è zona toia" % nome,
					global_position)
				if _anim != null:
					_anim.action("punch")


func _lascia_perdere() -> void:
	stato = Stato.GIRO
	_pazienza = 0.0
	_di(CONGEDO[randi() % CONGEDO.size()])


func _dentro_alla_zona(p: Vector3) -> bool:
	if zona_max == Vector3.ZERO:
		return false
	return p.x >= zona_min.x and p.x <= zona_max.x \
		and p.z >= zona_min.z and p.z <= zona_max.z


## Il giro di ronda: da un angolo all'altro della sua zona, con una sosta.
func _fai_il_giro(delta: float) -> void:
	if _giro.is_empty():
		_muovi(delta, 0.0)
		return
	if _attesa > 0.0:
		_attesa -= delta
		_muovi(delta, 0.0)
		return
	var meta: Vector3 = _giro[_giro_idx]
	meta.y = global_position.y
	_verso(meta)
	_muovi(delta, VELOCITA_GIRO)
	if global_position.distance_to(meta) < 1.4:
		_giro_idx = (_giro_idx + 1) % _giro.size()
		_attesa = randf_range(2.0, 5.0)


## Ti si mette davanti e ti resta davanti.
func _addosso(pl: Node3D, delta: float, distanza: float) -> void:
	if pl == null or not is_instance_valid(pl):
		_lascia_perdere()
		return
	var meta: Vector3 = pl.global_position
	meta.y = global_position.y
	_verso(meta)
	if global_position.distance_to(meta) > distanza:
		_muovi(delta, VELOCITA_ADDOSSO)
	else:
		_muovi(delta, 0.0)


func _muovi(delta: float, velocita: float) -> void:
	var avanti: Vector3 = -global_transform.basis.z
	if _visual:
		avanti = -_visual.global_transform.basis.z
	velocity.x = avanti.x * velocita
	velocity.z = avanti.z * velocita
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if _anim != null:
		_anim.set_speed(Vector2(velocity.x, velocity.z).length())


func _verso(meta: Vector3) -> void:
	var dir: Vector3 = meta - global_position
	dir.y = 0.0
	if dir.length() > 0.05 and _visual:
		# forward(θ) = (−sinθ, 0, −cosθ): θ = atan2(−dir.x, −dir.z).
		_visual.rotation.y = lerp_angle(_visual.rotation.y,
			atan2(-dir.x, -dir.z),
			1.0 - exp(-9.6 * get_physics_process_delta_time()))


## **Il rivale lavora davvero, e si sente.**
##
## Quando passi accanto a una piazza che non e' tua, ogni tanto senti il
## tintinnio degli spiccioli: e' lui che si e' fatto pagare. Non e' un
## dettaglio d'atmosfera — e' l'unico modo di far capire, senza scriverlo
## da nessuna parte, che quella piazza RENDE. Una piazza che costa
## quattrocentocinquanta euro va vista rendere prima di comprarla.
##
## Si sente solo se stai abbastanza vicino, e il volume scende con la
## distanza: a trenta metri e' un rumore lontano, a cinque e' uno che
## conta le monete accanto a te.
const INCASSO_OGNI_MIN: float = 11.0
const INCASSO_OGNI_MAX: float = 19.0
const INCASSO_DISTANZA: float = 34.0
const INCASSI := ["Grazie assaje, ne'.", "Statte buono!",
	"Ce vedimmo dimane.", "Bella jurnata."]

var _t_incasso: float = 6.0


func _lavora(delta: float) -> void:
	# Solo nelle piazze che non sono tue: se l'hai comprata, quello che
	# incassa sei tu.
	if GameManager.zona_mia(zona_id) or stato == Stato.STESO:
		return
	_t_incasso -= delta
	if _t_incasso > 0.0:
		return
	_t_incasso = randf_range(INCASSO_OGNI_MIN, INCASSO_OGNI_MAX)
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null or not (pl is Node3D):
		return
	var d: float = global_position.distance_to((pl as Node3D).global_position)
	if d > INCASSO_DISTANZA:
		return
	# Da -4 dB addosso a -26 dB in fondo alla strada.
	var vol: float = lerpf(-4.0, -26.0, clampf(d / INCASSO_DISTANZA, 0.0, 1.0))
	SoundManager.play("coin", vol, randf_range(0.94, 1.08))
	if d < 18.0:
		_di(INCASSI[randi() % INCASSI.size()])
	if _anim != null:
		_anim.action("point")


## Se gliele dai tu. Per ora stenderlo non ti dà la zona — quello arriva
## con le meccaniche di conquista — ma almeno smette di rompere.
func receive_punch(danno: int = 1) -> void:
	# **'A reazione, no 'o blocco.** Il colpo si vede addosso (clip
	# `Hit_Chest`/`Hit_Head` sopra alla locomozione) ma non toglie il
	# controllo: vedi `Animator.reagisci_colpo`.
	if _anim != null and _anim.has_method("reagisci_colpo"):
		_anim.reagisci_colpo(randf() < 0.4)
	if stato == Stato.STESO:
		return
	hp -= maxi(1, danno)
	# Se stavi trattando e gli tiri un pugno, la trattativa è chiusa: mo'
	# si fa a mazzate.
	_tratta = 0.0
	GameManager.nemico_colpito.emit(nome, maxi(0, hp), hp_max)
	GameManager.add_heat(9.0)
	# Fra parcheggiatori e' roba loro: nessuno chiama nessuno. Ma se ci si
	# accanisce in mezzo alla strada qualcuno alla fine il 112 lo fa.
	# Fra parcheggiatori e' roba loro: pesa meno di menare un passante,
	# ma se il vigile guarda e' una stella lo stesso.
	GameManager.violenza(0.6)
	SoundManager.pugno(-1.0)
	if hp <= 0:
		stato = Stato.STESO
		KO.lay_down(_ko, _visual, 999.0)
		_di("Ahi... va buo'... 'a zona è 'a toia...")
		_prendi_zona(false)
	else:
		# **Se lo picchi a mani nude te lo dice lui che non basta.**
		#
		# A mani nude il pugno toglie 2, e un rivale ne tiene 40 o piu': ci
		# vogliono venti colpi mentre lui te ne da' 11 al secondo, cioe' e'
		# una lotta persa. Ed e' voluto — la piazza si prende con un ferro
		# o coi soldi, non con le mani. Ma il giocatore lo capiva solo dopo
		# esserci finito in ospedale, e sembrava che il gioco fosse rotto.
		# Adesso alla seconda botta a vuoto glielo dice in faccia.
		if danno <= 2:
			_a_vuoto += 1
			if _a_vuoto == 2:
				_di("Cu 'e mmane?! Va' t'accatta 'nu fierro, guaglio'.")
				GameManager.event_started.emit(
					"A mani nude nun 'o stienne. Ce vò 'na mazza — o 'e sorde.")
			else:
				_di("Ah sì?! Mo' vide!")
		else:
			_di("Ah sì?! Mo' vide!")
		if stato == Stato.GIRO or stato == Stato.AVVISA:
			stato = Stato.MENA


func get_interact_prompt(_da: Vector3) -> String:
	if GameManager.zona_mia(zona_id):
		return ""
	if stato == Stato.STESO:
		return ""
	# **Il prezzo si scrive nel prompt.**
	#
	# Prima diceva solo "parlace d''a piazza": chi ci arrivava davanti non
	# sapeva ne' quanto costava ne' se se lo poteva permettere, e la
	# risposta la scopriva solo dopo aver premuto E. Adesso il cartellino
	# sta li' — e quando non bastano i soldi lo dice prima, non dopo.
	var prezzo: int = GameManager.prezzo_zona()
	var affitto: int = GameManager.affitto_zona()
	if GameManager.money < prezzo:
		return "%s — 'a piazza costa €%d + €%d 'o juorno. Te ne mancano €%d." \
			% [nome, prezzo, affitto, prezzo - GameManager.money]
	# Seconda parte della trattativa: ha già parlato, adesso aspetta.
	if _tratta > 0.0:
		return "%s aspetta 'a risposta — [E] mane 'ncoppa, €%d + €%d 'o juorno" \
			% [nome, prezzo, affitto]
	return "%s — [E] parlace d''a piazza (€%d + €%d 'o juorno)" \
		% [nome, prezzo, affitto]


## **Comprare la piazza.**
##
## L'alternativa alle mazzate, e quella che il gioco preferisce: costa di
## più ma non ti lascia addosso i carabinieri, e il rivale continua a
## esistere invece di restare steso in mezzo alla strada.
##
## Il prezzo lo decide il GameManager e sale con quante piazze tieni già:
## mille per la prima in più, duemila per la seconda. Più l'affitto ogni
## giorno, che è la parte che conta davvero — la piazza non è un acquisto,
## è un abbonamento, e se smetti di renderla non ti conviene più.
func player_interact() -> void:
	if GameManager.zona_mia(zona_id) or stato == Stato.STESO:
		return
	var prezzo: int = GameManager.prezzo_zona()
	var affitto: int = GameManager.affitto_zona()
	if GameManager.money < prezzo:
		_di("Cu %d euro? Torna quanno tiene €%d 'nzieme." %
			[GameManager.money, prezzo])
		SoundManager.play("fail", -8.0, 0.9)
		GameManager.event_started.emit(
			"'A piazza 'e %s costa €%d + €%d 'o juorno. Nun 'e tiene."
			% [nome, prezzo, affitto])
		return

	# **Prima si parla, poi si paga.**
	#
	# Mille euro sono un terzo di una giornata buona, e prima se ne andavano
	# con un tasto premuto per sbaglio passandogli davanti. Adesso il primo
	# [E] è una chiacchierata: lui dice il prezzo, e resta in attesa per
	# qualche secondo. Il secondo [E] chiude. È anche il "parlarci" che
	# mancava — un rivale che ti tratta la piazza sembra una persona, uno
	# che te la vende in silenzio sembra un distributore automatico.
	if _tratta <= 0.0:
		_tratta = DURATA_TRATTATIVA
		_di(FRASI_TRATTATIVA[randi() % FRASI_TRATTATIVA.size()] % prezzo)
		SoundManager.play("pop", -12.0, 0.85)
		GameManager.event_started.emit(
			"%s vò €%d + €%d 'o juorno. Prieme n'ata vota [E] p'accunsentì."
			% [nome, prezzo, affitto])
		# **E adda dicere ch'è ca staje accattanno (0.55).**
		#
		# Da quando ogni piazza ha un carattere suo — quanto rende, quanti
		# vigili ci girano, se lavora di giorno o di notte — comprarla
		# senza saperlo sarebbe comprare a scatola chiusa. Non è una
		# sorpresa da tenersi: è **l'informazione su cui si decide**, e
		# uno che vende una piazza te la dice, se non altro per vantarsi.
		var c: Dictionary = GameManager.carattere(zona_id)
		GameManager.event_started.emit("%s: %s" % [nome_zona, str(c["che"])])
		return

	if not GameManager.paga(prezzo):
		return
	_tratta = 0.0
	SoundManager.play("kaching", -2.0, 0.95)
	_di("Overo?! E allora... 'a piazza è 'a toia. Ma me pave ogne juorno.")
	GameManager.acquisisci_zona(zona_id, nome_zona, true, affitto)
	_prendi_zona(true)


## Quello che succede in tutt'e due i casi: la zona cambia padrone, e lui
## smette di rompere.
func _prendi_zona(comprata: bool) -> void:
	if not GameManager.zona_mia(zona_id):
		# **Presa a mazzate: gratis di soldi, cara di stelle.**
		#
		# Non si paga affitto, e fin qui e' un vantaggio. Ma stendere un
		# uomo in mezzo alla strada e prendergli il posto non e' una cosa
		# che passa inosservata: sono due stelle secche, cioe' i
		# carabinieri addosso subito. E' quello che tiene in piedi la
		# scelta fra le due strade — se no comprare una piazza sarebbe
		# solo il modo scemo di fare quello che si puo' fare gratis.
		GameManager.acquisisci_zona(zona_id, nome_zona, false, 0)
		GameManager.crimine(GameManager.PUNTI_PER_STELLA * 2.0)
	stato = Stato.STESO if not comprata else Stato.GIRO
	_pazienza = 0.0
	GameManager.screen_shake.emit(0.4)
	GameManager.event_started.emit(
		("'A piazza 'e %s mo' è 'a toia. Ce se fatica." % nome) if comprata
		else ("Hê pigliato 'a piazza 'e %s cu 'e mmane. Statte accuorto." % nome))
