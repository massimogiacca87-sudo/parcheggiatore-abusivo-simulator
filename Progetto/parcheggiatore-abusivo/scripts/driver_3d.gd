extends CharacterBody3D
## Driver3D
## L'autista sceso dall'auto dopo il parcheggio: cammina (con gambe vere)
## verso l'uscita. Fermalo (E) per farti pagare: paga oppure rifiuta. Se
## rifiuta, puoi prenderlo a pugni (tasto sinistro) finché non sgancia un
## pagamento forzato — con tanto di slow-motion — poi scappa.

## **`CONFRONTO` è 'nu stato nuovo, e ce vò.**
##
## Prima il confronto per lo stemma si apriva lasciando lo stato su
## `RETURNING`. Ma è proprio `_do_return()` che lo apre, e `_do_return()`
## gira **a ogni fotogramma**: quello dopo il dialogo era già aperto, la
## distanza dalla macchina era ancora sotto i 2,4 metri, e ripartiva il
## controllo — che stavolta non trovava più il flag e passava dritto a
## all'inseguimento diretto. Il pannello delle risposte
## compariva e spariva nello stesso fotogramma.
##
## Un confronto è uno stato: sta fermo, ti guarda in faccia e aspetta.
##
## **E po' te cerca (0.52).** Fino alla 0.51 il confronto si apriva
## appena l'autista arrivava alla macchina, dovunque stessi tu: potevi
## essere dall'altra parte della citta' e ti compariva il pannello delle
## risposte addosso. Adesso c'e' uno stato in mezzo — `CERCA` — in cui gira
## per la piazza a cercarti, e il dialogo si apre **solo quando ti arriva
## vicino**. Se non ti trova, dopo un po' se ne va sconfitto.
## **'A 0.55: ll'autista nun se ne va cchiù. Va a fà 'e commissiune.**
##
## Fino alla 0.54 c'erano **due** autisti per ogni macchina, e nessuno dei
## due era una persona. Il primo scendeva, camminava verso l'uscita della
## piazza e **spariva** appena ci arrivava; poi, se trovavi la multa o
## rigavi la fiancata, ne nasceva un **secondo** dal nulla, all'uscita,
## che tornava indietro incazzato. Due comparse con la stessa faccia, e in
## mezzo una macchina che stava lì da sola.
##
## Il difetto grosso però era un altro, ed è quello che il capo ha visto:
## quel giro **non finiva mai**. La macchina chiamava indietro l'autista
## perché c'era un danno; l'autista faceva la scenata e chiamava
## `multa_confronto_finita()`; quella rimetteva il contatore a mezzo
## secondo — ma il danno era ancora lì, e mezzo secondo dopo la macchina
## chiamava un altro autista. All'infinito, con un cliente perso contato a
## ogni giro.
##
## Adesso l'autista è **uno solo e vive quanto la sosta**:
##
##   EXITING → SPESA (cammina fino a un negozio) → ASPETTA (ci sta dentro)
##   → TORNA (rientra alla macchina) → e qui guarda:
##       * tutto a posto  → SAGLIE, monta e la macchina se ne va;
##       * multa, stemma o riga → CERCA, e parte il confronto che c'era già.
##
## Il giro è chiuso per costruzione: **c'è una sola uscita di scena** e
## passa da `l_autista_ha_fernuto()`, che manda via la macchina. Non esiste
## uno stato da cui si possa tornare indietro a rifare la stessa scenata.
enum State { EXITING, SPESA, ASPETTA, TORNA, SAGLIE, FLEEING, RETURNING,
	HUNTING, CALMING, CONFRONTO, CERCA }

const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const Human := preload("res://scripts/human_builder.gd")
const KO := preload("res://scripts/knockout.gd")
const Gente := preload("res://scripts/gente.gd")

const WALK_SPEED: float = 1.7
const FLEE_SPEED: float = 5.0
const RETURN_SPEED: float = 3.2
## Oltre a questi metri la macchina non è più "la sua macchina parcheggiata
## là": è una macchina che sta scappando, e a piedi non si rincorre.
const CALMA_LUNTANO: float = 30.0
const EXIT_PAUSE: float = 1.2
const PUNCH_HEAT: float = 10.0
## Quanti cazzotti regge prima di stendersi. Poi si rialza da solo e scappa.
const MAX_HP: int = 8
const KO_HEAT: float = 30.0

# --- L'autista che torna e trova la multa ---
const HUNT_SPEED: float = 5.4       # più veloce di te che cammini, più lento di te che corri
const HUNT_DURATION: float = 15.0   # quanto ti sta dietro prima di rassegnarsi
const HUNT_REACH: float = 1.9       # a che distanza le mani arrivano
const HUNT_HIT_EVERY: float = 1.1   # secondi fra uno schiaffo e l'altro
const HUNT_DAMAGE: float = 9.0      # ossa che ti costa ogni schiaffo
const HUNT_GIVE_UP_DIST: float = 17.0 # se scappi così lontano, lascia perdere

const SAY_MULTA_FOUND := ["MA CHE È STA MULTA?!", "M'HÊ FATTO PIGLIÀ 'A MULTA!",
	"GUARDA CHE M'HÊ COMBINATO!"]
const SAY_HUNT := ["VIENI CCÀ, GUAGLIÓ!", "MO' T'ACCONCIO IO!", "FIERMATE!",
	"'A MULTA M'A PAGHE TU!"]
const SAY_HUNT_HIT := ["TIÈ!", "E TIÈ N'ATA VOTA!", "TE STA BUONO!"]
const SAY_HUNT_GIVEUP := ["Va' va'... mannaggia a te.", "T'aggio 'a truvà, sà?",
	"Curre curre, tanto ce vedimmo."]

const SAY_PAY := ["Tiè, bravo guaglió!", "Ecco a te, mastro!", "Teccà, e statte buono."]
const SAY_REFUSE := ["Nun te pavo, scè!", "E chi t'ha chiamato?!", "Parcheggiatore abusivo? PE' CARITÀ!"]
const SAY_REFUSE_TIRCHIO := "'E sorde? QUALI SORDE?!"
const SAY_REFUSE_AGAIN := "T'aggio ditto NO!"
const SAY_PUNCHED := ["AHIA!", "MAMMA MIA!", "AIUTO! AIUTO!"]
const SAY_FORCED := "VA BUO', VA BUO', TIÈ!"

## **'E ddoje 'e notte: 'o cliente 'nzallanuto.**
##
## La fascia della nottata paga quasi il doppio, e il motivo non può
## restare scritto solo in una tabella di numeri: dev'essere in faccia a
## chi scende dalla macchina. Chi torna a casa alle due tiene il vino in
## corpo, tira fuori il portafoglio senza guardarci dentro, e ti chiama
## professore. È l'ora più redditizia del gioco e adesso si sente pure.
const SAY_PAY_NOTTE := [
	"Tiè, professò… e pigliatìlle tutte quante!",
	"Uè… uè bello 'e mammà… teccà, nun me cuntà 'e resto.",
	"Chesta è pe' te. Cchiù 'e chesto nun te pozzo dà… o forse sì?",
	"Bravo 'o guaglione! Chist'è ll'unico ca fatica a chest'ora!",
]
const SAY_REFUSE_NOTTE := [
	"Aspiè… aspiè ca mo' m'arricordo addò tengo 'o puórtafoglio…",
	"E che ora è? …E allora nun te pavo, ca è tardi!",
	"Io a te t'aggio già pagato. …No? …Mah.",
]
const SAY_CRIME := "UÈ! CHE STAI FACENNO?!"

var state: int = State.EXITING
var car: Node = null
var exit_point: Vector3

var _asked: bool = false
var _refused: bool = false
var _punches: int = 0
var _exit_timer: float = EXIT_PAUSE
var _stagger: float = 0.0
var _visual_root: Node3D
var _shirt_color: Color
var _bubble: Node3D
var _walk_phase: float = 0.0
var _hunt_left: float = 0.0
var _hunt_hit_cd: float = 0.0
var hp: int = MAX_HP
var _ko: Dictionary = KO.make_state()
var _legs: Array = []
var _arms: Array = []
var _head: Node3D = null
var _anim: Node = null


func _ready() -> void:
	add_to_group("drivers")
	collision_layer = 4
	collision_mask = 0
	_shirt_color = [
		Color(0.7, 0.3, 0.25), Color(0.25, 0.5, 0.3), Color(0.6, 0.55, 0.2),
		Color(0.35, 0.35, 0.6), Color(0.55, 0.3, 0.5),
	][randi() % 5]
	_build_visual()
	_build_collision()
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 2.2, 0)
	add_child(_bubble)
	SoundManager.play("portiera", -3.0)


func setup(owner_car: Node, exit_pos: Vector3) -> void:
	car = owner_car
	exit_point = exit_pos
	_saluta_si_te_canosce()


# ---------------------------------------------------------------------------
# 'O cliente fisso: chi tene 'nu nomme
# ---------------------------------------------------------------------------
#
# **'A differenza sta dint'ê primme tre parole.**
#
# Un autista qualunque scende e non dice niente: aspetta che gli chiedi i
# soldi. Uno che ti conosce **parla per primo**, e quello che dice è
# l'unica cosa che ti fa capire, prima di aprire bocca tu, se la volta
# scorsa gli hai fatto il piacere o il danno. È tutto il sistema in una
# frase sola: se te lo devi ricordare guardando una barra, non funziona.

## Chi sta dint'â machina, si tene 'nu nomme.
func _cliente_id() -> String:
	if car == null or not is_instance_valid(car):
		return ""
	return str(car.cliente_id)


func _nomme() -> String:
	var id: String = _cliente_id()
	if id == "":
		return "'O padrone d''a machina"
	var c: Dictionary = Gente.cliente(id)
	return str(c["nome"]) if not c.is_empty() else "'O padrone d''a machina"


func _saluta_si_te_canosce() -> void:
	var id: String = _cliente_id()
	if id == "":
		return
	var testo: String = Gente.saluto(id, GameManager.visto_quante(id),
		GameManager.rapporto(id))
	if testo == "":
		return
	# Mezzo secondo: prima si sente la portiera, poi parla. Insieme sono
	# due cose che si accavallano e non si legge niente.
	await get_tree().create_timer(0.55).timeout
	if is_instance_valid(self):
		_say("%s: %s" % [_nomme(), testo])


## Comme t'hà trattato tu 'e isso, si tene 'nu nomme.
func _rapporto_mosso(quanto: float) -> void:
	var id: String = _cliente_id()
	if id != "":
		GameManager.muove_rapporto(id, quanto)


## Siamo nella fascia della nottata? Si chiede al GameManager e non
## all'orologio del cielo: l'ora è una sola dalla 0.51, e questa è quella.
func _e_nuttata() -> bool:
	return GameManager.fascia_indice() >= 4


func _say(text: String) -> void:
	if _bubble:
		_bubble.say(text)
	GameManager.directing_gesture.emit(text, true)


func _build_visual() -> void:
	_visual_root = Node3D.new()
	add_child(_visual_root)

	var parts := Human.build(_shirt_color, Color(0.22, 0.22, 0.28), "driver", 1.8)
	_visual_root.add_child(parts["root"])
	_legs = parts["legs"]
	_arms = parts["arms"]
	_head = parts["head"]
	_anim = parts.get("anim", null)


func _build_collision() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.9
	shape.shape = capsule
	shape.position = Vector3(0, 0.95, 0)
	add_child(shape)


func _physics_process(delta: float) -> void:
	# Steso: non fa più niente finché non si rialza.
	if _ko["down"]:
		if KO.tick(_ko, _visual_root, delta):
			state = State.FLEEING # appena in piedi, se ne scappa
		return
	if _stagger > 0.0:
		_stagger -= delta
		return

	match state:
		State.EXITING:
			_exit_timer -= delta
			if _exit_timer <= 0.0:
				_parte_p_a_spesa()
		State.SPESA:
			_va_ô_negozio(delta)
		State.ASPETTA:
			_dint_ô_negozio(delta)
		State.TORNA:
			_torna_â_machina(delta)
		State.SAGLIE:
			_saglie_e_se_ne_va(delta)
		State.FLEEING:
			# Scappa: la macchina se la scorda. Appena arriva all'uscita
			# sparisce, e `_despawn` manda via la macchina lo stesso —
			# altrimenti resterebbe posteggiata lì per sempre.
			_step_toward(exit_point, FLEE_SPEED, delta)
		State.RETURNING:
			_do_return(delta)
		State.HUNTING:
			_do_hunt(delta)
		State.CONFRONTO:
			_do_confronto(delta)
		State.CERCA:
			_do_cerca(delta)
		State.CALMING:
			# Se n'è fatta una ragione: torna alla macchina e se ne va.
			if car == null or not is_instance_valid(car):
				_despawn_silent()
				return
			# **E si 'a machina se ne sta ghienno cu te ncoppa** (0.57): la
			# meta di questo stato è la macchina, e da quando esiste il
			# furto la macchina può essere a duecento metri e in
			# movimento. Senza questa riga l'autista se la inseguirebbe a
			# piedi per tutta la città, per sempre.
			if car.global_position.distance_to(global_position) > CALMA_LUNTANO:
				_despawn_silent()
				return
			var back: Vector3 = car.global_position
			global_position = Passo.verso(self, back, FLEE_SPEED * delta)
			_face_toward(back)
			_animate_walk(FLEE_SPEED * delta)
			if global_position.distance_to(back) < 2.0:
				# `_despawn_silent` chiama gia' `l_autista_ha_fernuto()`,
				# che fa ripartire la macchina. Prima qui si chiamava
				# `multa_confronto_finita()`, che invece rimetteva il
				# contatore della sosta — ed e' esattamente il giro che
				# non finiva mai.
				_despawn_silent()


# ---------------------------------------------------------------------------
# 'E commissiune: pecché uno lassa 'a machina
# ---------------------------------------------------------------------------
#
# **Nisciuno posteggia pe' posteggià.** Uno si ferma perché deve fare una
# cosa, e quella cosa ha una durata: è per questo che la macchina sta lì
# dieci minuti e non trenta secondi. Prima quella durata era un numero nel
# codice dell'auto (`_parked_time`) e non si vedeva da nessuna parte;
# adesso è **dove sta andando quello che è sceso**, e si vede benissimo —
# attraversa la piazza, entra dal fruttivendolo, e dopo un po' riesce.
#
# Serve anche a una cosa più pratica: ti dà **il tempo e il posto** per
# fermarlo. Un autista che cammina verso l'uscita e sparisce ti dà cinque
# secondi; uno che va a fare la spesa e torna ti passa davanti due volte.

## Quanto sta dentro al negozio, prima di tornare.
const SPESA_MIN: float = 14.0
const SPESA_MAX: float = 38.0
## Più lontano di così non ci va: uno posteggia vicino a dove deve andare.
const NEGOZIO_PORTATA: float = 55.0

## Quanto vuole starci in tutto, camminata compresa. Lo scrive la macchina
## in `_spawn_driver` e viene dai numeri di sempre.
var durata_spesa: float = 34.0

var _negozio: Node3D = null
var _punto_negozio: Vector3 = Vector3.ZERO
var _dentro: float = 0.0

const SAY_SPESA := [
	"Faccio 'nu minuto e torno.", "Vaco e vengo.",
	"Tengo 'a fà 'na cosa ccà 'nnanze.", "Duje minute, eh.",
]


## Sceglie il negozio e parte. Se in giro non ce n'è nessuno (zone nuove,
## prove), si ripiega sul vecchio comportamento — cammina verso l'uscita —
## così non resta mai piantato.
func _parte_p_a_spesa() -> void:
	_negozio = _scegli_negozio()
	if _negozio == null:
		_punto_negozio = exit_point
	else:
		_punto_negozio = _negozio.get_meta("punto", _negozio.global_position)
	state = State.SPESA
	if randf() < 0.45:
		_say(SAY_SPESA[randi() % SAY_SPESA.size()])


func _scegli_negozio() -> Node3D:
	var da: Vector3 = global_position
	var vicine: Array = []
	for n in get_tree().get_nodes_in_group("negozi"):
		if not (n is Node3D) or not is_instance_valid(n):
			continue
		var p: Vector3 = (n as Node3D).global_position
		if da.distance_to(p) <= NEGOZIO_PORTATA:
			vicine.append(n)
	if vicine.is_empty():
		return null
	return vicine[randi() % vicine.size()]


## **Quanto ce mette 'e cchiù primma 'e se ne fottere.**
##
## La regola più importante di tutto il giro dell'autista non è come
## cammina: è che **il giro fernisce sempe**. La 0.55 ci ha perso tre
## giorni sopra — il cliente che tornava all'infinito, la piazza che si
## riempiva di macchine senza padrone — e la lezione era già scritta:
## quando una macchina dipende da qualcuno che deve arrivare da qualche
## parte, quel qualcuno **deve** arrivarci, o il giro resta aperto per
## sempre.
##
## Dalla 0.56 chi cammina ha i muri (`Passo`), e i muri sono il modo più
## facile del mondo di non arrivare: basta una vetrina messa in un angolo,
## una piazza rifatta, un posto auto in un cortile. Quindi ogni gamba del
## giro ha il suo tetto: passato quello, **si fa finta di esserci
## arrivati** e si va avanti. Un autista che compare davanti alla vetrina
## invece di arrivarci camminando non se ne accorge nessuno; un autista che
## non ci arriva mai rompe la giornata.
##
## I numeri sono generosi: quaranta metri a passo d'uomo sono ventitré
## secondi, e nessun negozio sta a più di cinquantacinque metri
## (`NEGOZIO_PORTATA`).
const TETTO_CAMMENATA: float = 50.0

var _cammina_da: float = 0.0


func _va_ô_negozio(delta: float) -> void:
	var meta: Vector3 = _punto_negozio
	meta.y = global_position.y
	global_position = Passo.verso(self, meta, WALK_SPEED * delta)
	_face_toward(meta)
	_animate_walk(WALK_SPEED * delta)
	_cammina_da += delta
	if _cammina_da > TETTO_CAMMENATA:
		# Non ci è arrivato. Pazienza: la spesa la fa dov'è.
		_cammina_da = 0.0
		_dentro = clampf(durata_spesa * 0.5, SPESA_MIN, SPESA_MAX)
		state = State.ASPETTA
		return
	if global_position.distance_to(meta) < 0.8:
		# Quanto resta in bottega = quanto voleva starci in tutto, meno la
		# camminata di ritorno. Il negozio lontano si mangia il tempo, e
		# chi ce l'ha sotto casa se lo prende comodo.
		var ritorno: float = 0.0
		if car != null and is_instance_valid(car):
			ritorno = global_position.distance_to(car.global_position) \
				/ WALK_SPEED
		_dentro = clampf(durata_spesa - ritorno, SPESA_MIN, SPESA_MAX)
		_cammina_da = 0.0
		state = State.ASPETTA


func _dint_ô_negozio(delta: float) -> void:
	_animate_walk(0.0)
	# Guarda la vetrina: se sta davanti a un negozio, gli dà le spalle a
	# chi passa, che è quello che fa uno che guarda una vetrina.
	if _negozio != null and is_instance_valid(_negozio):
		_face_toward(_negozio.global_position)
	_dentro -= delta
	if _dentro <= 0.0:
		state = State.TORNA


func _torna_â_machina(delta: float) -> void:
	if car == null or not is_instance_valid(car):
		_despawn_silent()
		return
	var meta: Vector3 = car.global_position
	global_position = Passo.verso(self, meta, WALK_SPEED * delta)
	_face_toward(meta)
	_animate_walk(WALK_SPEED * delta)
	_cammina_da += delta
	# **E ccà 'o tetto è chello ca conta overo**: se non torna alla
	# macchina, quella macchina non se ne va più e il posto resta occupato
	# per tutta la giornata. Meglio farlo comparire accanto allo sportello.
	if _cammina_da > TETTO_CAMMENATA or global_position.distance_to(meta) < 2.6:
		_cammina_da = 0.0
		_arriva_â_machina()


## **'O momento ca decide tutto.** È tornato, e guarda la macchina: se c'è
## un foglietto sul parabrezza, se manca lo stemma, se c'è una riga sulla
## fiancata. Solo qui nasce il confronto — non prima, e non per chiunque.
func _arriva_â_machina() -> void:
	var motivo: String = _che_trova()
	if motivo == "":
		state = State.SAGLIE
		return
	if car != null and is_instance_valid(car):
		car.set("_multa_confronto", true)
	_derubato_ammuccione = motivo != "multa"
	_accummencia_a_cercà(motivo)


## Cosa c'è che non va, in ordine di quanto si vede. Vuoto = tutto a posto.
func _che_trova() -> String:
	if car == null or not is_instance_valid(car):
		return ""
	if bool(car.get("has_multa")):
		return "multa"
	if bool(car.get("_stemma_sparito")):
		return "stemma"
	if bool(car.get("_scassata_ammuccione")):
		return "scasso"
	return ""


const SAY_CIAO := [
	"Statte buono, guagliò.", "Ce vedimmo.", "Grazie, eh.", "Bonasera.",
]

## Monta e se ne va. È **l'unica** porta d'uscita del giro: da qui la
## macchina riparte e l'autista sparisce, e non c'è nessuno stato che
## possa riportarlo indietro.
func _saglie_e_se_ne_va(delta: float) -> void:
	if car == null or not is_instance_valid(car):
		_despawn_silent()
		return
	var meta: Vector3 = car.global_position
	global_position = Passo.verso(self, meta, WALK_SPEED * delta)
	_face_toward(meta)
	_animate_walk(WALK_SPEED * delta)
	if global_position.distance_to(meta) < 1.5:
		if car.paid and randf() < 0.5:
			_say(SAY_CIAO[randi() % SAY_CIAO.size()])
		_despawn()


# ---------------------------------------------------------------------------
# L'autista che torna e trova la multa
# ---------------------------------------------------------------------------

## Chiamato da car_3d quando la sosta finisce e sul parabrezza c'è la multa.
## Questo autista non è quello di prima: è lo stesso cliente che rientra,
## e non ha ancora visto niente.
func start_return_for_multa() -> void:
	state = State.RETURNING
	_asked = true # niente prompt "chiedi i soldi": qui si è già oltre
	_say("Mo' me piglio 'a machina...")


## Torna perché gli manca lo stemma o perché la macchina è rigata: stessa
## camminata, altro finale. Cosa trova di preciso lo decide
## `_motivo_del_ritorno()` quando ci arriva.
func start_return_for_stemma() -> void:
	state = State.RETURNING
	_asked = true
	_derubato_ammuccione = true
	_say("Mo' me piglio 'a machina...")


func _do_return(delta: float) -> void:
	if car == null or not is_instance_valid(car):
		_despawn_silent()
		return
	var target: Vector3 = car.global_position
	global_position = Passo.verso(self, target, RETURN_SPEED * delta)
	_face_toward(target)
	_animate_walk(RETURN_SPEED * delta)
	if global_position.distance_to(target) < 2.4:
		_accummencia_a_cercà(_motivo_del_ritorno())


## Che cosa trova quando arriva alla macchina. La multa viene prima di
## tutto: è un foglietto bianco sul parabrezza, la vedi da dieci metri.
func _motivo_del_ritorno() -> String:
	if car != null and is_instance_valid(car):
		if bool(car.get("has_multa")):
			return "multa"
		if bool(car.get("_stemma_sparito")):
			return "stemma"
		if bool(car.get("_scassata_ammuccione")):
			return "scasso"
	return "stemma"


# ---------------------------------------------------------------------------
# 'O CONFRONTO: 'a multa, 'o stemma, 'a machina scassata
# ---------------------------------------------------------------------------
#
# **Chello ca nun funzionava.**
#
# Erano tre situazioni, e nessuna delle tre finiva in un dialogo:
#
#   * **'A multa** — l'autista tornava, vedeva il foglietto e partiva
#     direttamente a mazzate. Non c'era niente da dire e niente da fare:
#     una punizione che non si può nemmeno provare a evitare non insegna
#     niente, è solo una tassa con le mani.
#   * **'A machina scassata 'ammuccione** — se gli rigavi la macchina alle
#     spalle non succedeva **assolutamente niente**, mai. Il danno restava
#     lì e nessuno se ne accorgeva: rigare una macchina di nascosto era
#     gratis, e infatti alla 0.50 abbiamo dovuto inventarci un motivo
#     esterno (la nomma) per cui valesse la pena farlo.
#   * **'O stemma** — il dialogo c'era, ma durava un fotogramma (vedi la
#     nota sull'enum degli stati).
#
# Adesso sono la stessa cosa con tre facce: l'autista torna, trova quello
# che trova, e **te lo chiede**. Le risposte sono diverse per ognuna,
# perché sono tre accuse diverse — ma la struttura è una sola, e questo
# vuol dire che la prossima si aggiunge con quattro righe.
#
# Tre regole che valgono per tutti e tre:
#
#   1. **Chi t'ha pagato è più difficile da fregare.** Ti ha dato dei soldi
#      perché guardassi la macchina: "e che ne saccio" è una risposta che
#      si contraddice da sola.
#   2. **Dire la verità funziona sempre**, e costa. È l'unica risposta che
#      non può andare male, e infatti è quella che ti lascia con meno.
#   3. **Mandarlo a quel paese finisce sempre a mazzate.** Deve restare
#      possibile: è il gioco.

## Quanto aspetta una risposta prima di stancarsi. Senza, uno può aprire il
## dialogo e andarsene, e quello resta lì fermo per sempre.
const CONFRONTO_ATTESA: float = 14.0

# --- 'A cerca: te vene a truvà 'n piazza, e po' se stanca -------------------
#
# **Nu cliente 'ncazzato nun è nu segugio.**
#
# Il capo: *"ti cercano in piazza e poco fuori al massimo, ma dopo poco se
# ne vanno sconfitti se non ti trovano. Solo se ti si avvicinano si
# triggera il dialogo."*
#
# Sono tre numeri, e ognuno dice una cosa precisa sul personaggio:
#
#   * **`CERCA_PORTATA`** — fin dove si spinge. Trentadue metri dalla
#     macchina: la piazza e il primo pezzo di strada. Se stai più in là non
#     ti viene a prendere, perché è uno che deve tornare a casa a cena, non
#     un cacciatore di taglie;
#   * **`CERCA_DURATA`** — quanto ci prova. Ventotto secondi. Abbastanza da
#     costringerti a decidere (mi nascondo? esco allo scoperto e me la
#     gioco?), poco abbastanza da non diventare un assedio;
#   * **`CERCA_VICINO`** — da che distanza ti parla. Due metri e mezzo:
#     deve arrivarti addosso, non urlarti da mezza piazza.
#
# E la cosa che conta di più: **nascondersi funziona**. Se te ne vai e
# aspetti, quello se ne va sconfitto e la macchina se ne parte. Non è
# gratis — hai perso il tempo, e la piazza intanto lavorava senza di te —
# ma è una via d'uscita che prima non esisteva.
const CERCA_PORTATA: float = 32.0
const CERCA_DURATA: float = 28.0
const CERCA_VICINO: float = 2.5
const CERCA_PASSO: float = 2.6

## Quanto spesso, negando, quello se la piglia. Mezzo e mezzo: negare è una
## scommessa, non una risposta giusta.
const PROBABILITA_S_INCAZZA: float = 0.50
## E quanto peggiora se ti aveva pagato per guardargliela.
const PAGATO_S_INCAZZA_CCHIU: float = 0.35

const SAY_CERCA := [
	"Addò sta chillo d''e mmacchine?",
	"Uè! 'O parcheggiatore! Addò stai?",
	"Ma addò s'è ghiuto?",
	"Se n'è fuiuto. 'O ssapevo.",
]
const SAY_NUN_T_HA_TRUVATO := [
	"Vabbuo'. Fatte truvà n'ata vota, va'.",
	"Mannaggia. Se n'è ghiuto pure isso.",
	"E chi 'o trova cchiù. Meglio accussì.",
]

var _cerca_t: float = 0.0
var _cerca_detto: float = 0.0

const RISPOSTE_STEMMA := [
	{"text": "L'aggio visto io: 'nu guaglione cu 'o muturino",
	 "reply": "…'Nu muturino. Mannaggia 'a miseria.", "esito": "bugia"},
	{"text": "Tècchete, s'era allentato e t''o tenevo io",
	 "reply": "Ah. …Vabbuo'. Grazie, va'.", "esito": "ridai"},
	{"text": "E che ne saccio? Io guardo 'e mmacchine, no 'e stemme",
	 "reply": "", "esito": "faccia_tosta"},
	{"text": "E chi t''o dice ca stive ccà? Vattenne",
	 "reply": "Ah sì? Mo' t''o ffaccio vedé io.", "esito": "rissa"},
]

const RISPOSTE_MULTA := [
	{"text": "'O vigile è passato mentre stevo 'a ll'ata parte. Me dispiace",
	 "reply": "…E vabbuo'. Nun è colpa toia. Mannaggia.", "esito": "scusa"},
	{"text": "Tècchete cinche euro pp''o disturbo",
	 "reply": "Uh. …Almeno tu sî galantomo. Statte buono.", "esito": "paga"},
	{"text": "T'aggio ditto io 'e nun 'a mettere llà",
	 "reply": "", "esito": "faccia_tosta"},
	{"text": "E che ne saccio? Vàttela a piglià cu 'o vigile",
	 "reply": "Cu tte me 'a piglio! Cu tte!", "esito": "rissa"},
]

const RISPOSTE_SCASSO := [
	{"text": "So' stati 'e guagliune cu 'o pallone. So' scappate 'a llà",
	 "reply": "…'E guagliune. Mannaggia 'e criature.", "esito": "bugia"},
	{"text": "È stata 'na machina ca è passata stretta. Nun aggio visto 'a targa",
	 "reply": "E certo. Ccà nun se passa, se strofina.", "esito": "bugia"},
	{"text": "Tècchete diece euro, accuncètella",
	 "reply": "…Vabbuo'. Almeno nun fai finta 'e niente.", "esito": "paga"},
	{"text": "E che vuo' 'a me? Io 'e mmacchine 'e poso, nun 'e guardo",
	 "reply": "", "esito": "faccia_tosta"},
]

## Vero quando gli hanno preso o rotto qualcosa senza che se ne accorgesse.
var _derubato_ammuccione: bool = false
var _confronto_aperto: bool = false
var _confronto_motivo: String = ""
var _confronto_t: float = 0.0


func _risposte_di(motivo: String) -> Array:
	match motivo:
		"multa": return RISPOSTE_MULTA
		"scasso": return RISPOSTE_SCASSO
	return RISPOSTE_STEMMA


func _apre_con(motivo: String) -> String:
	match motivo:
		"multa": return "Ueh. E chesta? Chesta che d'è?"
		"scasso": return "Ueh! 'A machina mia! Chi è stato?"
		"furto": return "'A MACHINA! ADDÒ STA 'A MACHINA MIA?!"
	return "Ueh. 'O stemma. Addò sta 'o stemma?"


func _avviso_di(motivo: String) -> String:
	match motivo:
		"multa": return "L'autista ha truvato 'a multa. Te vene a cercà."
		"scasso": return "L'autista ha visto 'a machina scassata. Te vene a cercà."
		"furto": return "'O padrone nun trova cchiù 'a machina. Sta chiammanno a tutte quante."
	return "'O padrone s'è accorto d''o stemma. Te vene a cercà."


## **T'hanno arrubbato 'a machina mentre stive â spesa** (0.57).
##
## La chiama `car_3d.arrubba()`. Non è un dialogo e non può esserlo: tu non
## sei lì, sei dentro alla macchina e stai già girando l'angolo. Quindi
## l'autista fa l'unica cosa sensata — comincia a cercarti urlando — e se
## non ti trova se ne va. Il costo vero del furto non è lui: sono le due
## stelle e i quattro punti di reputazione che ti ha già tolto il
## `GameManager`.
func t_hanno_arrubbato() -> void:
	_accummencia_a_cercà("furto")


## Arrivato alla macchina ha visto il guaio. Da qui non apre il dialogo:
## si mette a cercarti.
func _accummencia_a_cercà(motivo: String) -> void:
	if state == State.CERCA or _confronto_aperto:
		return
	state = State.CERCA
	_confronto_motivo = motivo
	_cerca_t = CERCA_DURATA
	_cerca_detto = 0.0
	_asked = true
	SoundManager.play("fail", -8.0, 0.9)
	_say(_apre_con(motivo))
	GameManager.event_started.emit(_avviso_di(motivo))


## Gira per la piazza a cercarti. Tre modi di finire: ti trova (dialogo),
## scade il tempo (se ne va), te ne sei andato troppo lontano (se ne va).
func _do_cerca(delta: float) -> void:
	if car == null or not is_instance_valid(car):
		_despawn_silent()
		return
	_cerca_t -= delta
	if _cerca_t <= 0.0:
		_nun_t_ha_truvato()
		return

	var pl := get_tree().get_first_node_in_group("player")
	var vicino := false
	if pl != null and is_instance_valid(pl) and pl is Node3D:
		var dove: Vector3 = (pl as Node3D).global_position
		# **'A portata se mesura 'a machina, no 'a isso.** Se no bastava
		# camminargli davanti per portarselo dietro mezza citta': lui si
		# allontana di un metro, e la portata si sposta con lui.
		var quanto_lontano: float = car.global_position.distance_to(dove)
		if quanto_lontano <= CERCA_PORTATA:
			var mira: Vector3 = dove
			mira.y = global_position.y
			global_position = Passo.verso(self, mira,
				CERCA_PASSO * delta)
			_face_toward(mira)
			_animate_walk(CERCA_PASSO * delta)
			vicino = global_position.distance_to(dove) <= CERCA_VICINO
		else:
			# Fuori portata: gli gira attorno alla macchina e basta.
			_gira_attuorno_â_machina(delta)
	else:
		_gira_attuorno_â_machina(delta)

	if vicino:
		_confronto(_confronto_motivo)
		return

	_cerca_detto -= delta
	if _cerca_detto <= 0.0:
		_cerca_detto = randf_range(4.5, 7.0)
		_bubble.say(SAY_CERCA[randi() % SAY_CERCA.size()], 2.2)


## Quando non ti vede: due passi attorno alla macchina, che è quello che
## fa uno che aspetta e si guarda intorno.
func _gira_attuorno_â_machina(delta: float) -> void:
	var centro: Vector3 = car.global_position
	var ang: float = (CERCA_DURATA - _cerca_t) * 0.6
	var mira := centro + Vector3(cos(ang) * 2.6, 0.0, sin(ang) * 2.6)
	mira.y = global_position.y
	global_position = Passo.verso(self, mira, CERCA_PASSO * delta)
	_face_toward(mira)
	_animate_walk(CERCA_PASSO * delta)


## Non t'ha trovato. Se ne va sconfitto, e la macchina se ne parte: il
## guaio resta tuo (la nomma, il calore) ma le mazzate no.
func _nun_t_ha_truvato() -> void:
	_bubble.say(SAY_NUN_T_HA_TRUVATO[randi() % SAY_NUN_T_HA_TRUVATO.size()], 2.6)
	GameManager.event_started.emit("L'autista nun t'ha truvato. Se n'è ghiuto.")
	state = State.CALMING


func _confronto(motivo: String) -> void:
	if _confronto_aperto:
		return
	_confronto_aperto = true
	_confronto_motivo = motivo
	_confronto_t = CONFRONTO_ATTESA
	_derubato_ammuccione = false
	_asked = true
	state = State.CONFRONTO
	SoundManager.play("fail", -8.0, 0.9)
	_say(_apre_con(motivo))
	GameManager.event_started.emit(_avviso_di(motivo))
	var pl := get_tree().get_first_node_in_group("player")
	if pl != null and pl.has_method("guarda_verso"):
		pl.guarda_verso(self)
		pl.interrompi_tutto()
	GameManager.dialogo_con = self
	GameManager.boss_dialogue_opened.emit(_risposte_di(motivo))


## Sta fermo davanti a te e aspetta. Se te ne vai, si stanca.
func _do_confronto(delta: float) -> void:
	var pl := get_tree().get_first_node_in_group("player")
	if pl != null and is_instance_valid(pl) and pl is Node3D:
		_face_toward((pl as Node3D).global_position)
	_animate_walk(0.0)
	_confronto_t -= delta
	if _confronto_t > 0.0:
		return
	# Tempo scaduto: non gli hai risposto. Peggio per te.
	_chiudi_dialogo()
	_say("E manco me rispunne. Bravo.")
	_parte_a_mmazzate()


func _chiudi_dialogo() -> void:
	if not _confronto_aperto:
		return
	_confronto_aperto = false
	if GameManager.dialogo_con == self:
		GameManager.dialogo_con = null
	GameManager.boss_dialogue_closed.emit()


## Chiamato dall'HUD quando il giocatore sceglie (0..3).
func answer(indice: int) -> void:
	if not _confronto_aperto:
		return
	var risposte: Array = _risposte_di(_confronto_motivo)
	if indice < 0 or indice >= risposte.size():
		return
	var scelta: Dictionary = risposte[indice]
	_chiudi_dialogo()
	# **Chi t'ha pagato nun se fida d''a faccia tosta.** Uno che ti ha dato
	# dei soldi perché guardassi la macchina, e torna e la trova mezza
	# spogliata, la risposta "e che ne saccio" non se la beve: gli hai già
	# detto che stavi guardando.
	var t_aveva_pagato: bool = car != null and is_instance_valid(car) \
		and car.paid
	match str(scelta["esito"]):
		"ridai":
			_say(str(scelta["reply"]))
			GameManager.togli_uno_stemma()
			GameManager.add_heat(3.0)
			_pace()
		"scusa":
			# La scusa onesta funziona solo se **non** ti aveva pagato: chi
			# ha pagato si aspettava proprio che tu stessi lì a guardare.
			if t_aveva_pagato:
				_say("E io t'aggio pagato pecché guardasse! Pe' che ccosa t'aggio dato 'e sorde?")
				GameManager.add_heat(9.0)
				_parte_a_mmazzate()
			else:
				_say(str(scelta["reply"]))
				GameManager.add_heat(2.0)
				_pace()
		"paga":
			var quanto: int = 10 if _confronto_motivo == "scasso" else 5
			if GameManager.money < quanto:
				_say("E cu che me pave? Cu 'e bottone?")
				GameManager.add_heat(8.0)
				_parte_a_mmazzate()
			else:
				GameManager.money = maxi(0, GameManager.money - quanto)
				GameManager.money_changed.emit(GameManager.money)
				SoundManager.play("monete", -6.0)
				_say(str(scelta["reply"]))
				# Ti è costato, ma il quartiere se lo ricorda in bene.
				GameManager.add_reputation(2)
				_pace()
		"bugia":
			_say(str(scelta["reply"]))
			GameManager.add_heat(8.0)
			# Una bugia detta bene costa reputazione, non sangue: in un
			# quartiere piccolo le storie si incrociano.
			GameManager.add_reputation(-4)
			_pace()
		"faccia_tosta":
			# **Negà è 'na monetina (0.52).**
			#
			# Il capo: *"negare (50% di possibilità che si arrabbia e si
			# combatte)"*. Prima era deciso: se non ti aveva pagato la
			# faccia tosta funzionava **sempre**, ed era la risposta
			# giusta a tavolino — nessun motivo di sceglierne un'altra.
			# Adesso è mezzo e mezzo, e diventa una scommessa: risparmi i
			# soldi ma rischi le ossa.
			#
			# Chi ti ha pagato resta il caso duro (`+0.35`): gli hai già
			# detto che stavi guardando, e "e che ne saccio" non se lo
			# beve quasi mai. La regola della 0.51 non si perde, si
			# ammorbidisce.
			var s_incazza: float = PROBABILITA_S_INCAZZA
			if t_aveva_pagato:
				s_incazza += PAGATO_S_INCAZZA_CCHIU
			if randf() < s_incazza:
				if t_aveva_pagato:
					_say("Io t'aggio pagato pe' guardà 'a machina. E mo' che me cunte?")
					GameManager.add_heat(16.0)
				else:
					_say("Nun me piace comme parle, tu.")
					GameManager.add_heat(12.0)
				_parte_a_mmazzate()
			else:
				_say("Mah. Sarrà.")
				GameManager.add_heat(10.0)
				_pace()
		_:
			_say(str(scelta["reply"]))
			_parte_a_mmazzate()


## Se l'è bevuta (o si è rassegnato): torna alla macchina e se ne va.
func _pace() -> void:
	state = State.CALMING


func _parte_a_mmazzate() -> void:
	_chiudi_dialogo()
	_refused = true
	state = State.HUNTING
	_hunt_left = HUNT_DURATION
	_hunt_hit_cd = 0.7
	GameManager.add_heat(12.0)
	GameManager.event_started.emit("'O padrone s'è 'ncazzato overamente.")





## Ti insegue e mena. Correre (SHIFT) basta per stargli davanti: il punto è
## che mentre scappi non stai lavorando, e il turno scorre lo stesso.
func _do_hunt(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	_hunt_left -= delta
	if _hunt_hit_cd > 0.0:
		_hunt_hit_cd -= delta

	if player == null or not is_instance_valid(player):
		_start_calming()
		return

	var dist: float = global_position.distance_to(player.global_position)
	if _hunt_left <= 0.0 or dist > HUNT_GIVE_UP_DIST:
		_start_calming()
		return

	var target: Vector3 = player.global_position
	target.y = global_position.y
	global_position = Passo.verso(self, target, HUNT_SPEED * delta)
	_face_toward(target)
	_animate_walk(HUNT_SPEED * delta)

	if dist <= HUNT_REACH and _hunt_hit_cd <= 0.0:
		_hunt_hit_cd = HUNT_HIT_EVERY
		_say(SAY_HUNT_HIT[randi() % SAY_HUNT_HIT.size()])
		SoundManager.pugno(-1.0)
		if _anim != null:
			_anim.action("punch")
		GameManager.screen_shake.emit(0.6)
		GameManager.damage_player(HUNT_DAMAGE, "T'ha menato l'autista d''a multa", global_position)
	elif _hunt_hit_cd <= 0.0 and randf() < delta * 0.5:
		_say(SAY_HUNT[randi() % SAY_HUNT.size()])


func _start_calming() -> void:
	_say(SAY_HUNT_GIVEUP[randi() % SAY_HUNT_GIVEUP.size()])
	state = State.CALMING


## Uscita di scena senza contare il cliente come perso.
func _despawn_silent() -> void:
	_lassa_a_machina()
	queue_free()


## **'A machina se ne va cu ll'autista, sempe.**
##
## Qualunque sia il motivo per cui questo nodo esce di scena — è montato e
## parte, è scappato dopo le botte, è stato steso, la scenata è finita —
## la macchina dev'essere avvisata. Senza, resta posteggiata per sempre:
## il posto non torna più libero e la piazza si riempie di relitti.
##
## È anche il punto in cui il giro si chiude: `l_autista_ha_fernuto()`
## manda via l'auto e basta, non rimette nessun contatore.
func _lassa_a_machina() -> void:
	if car != null and is_instance_valid(car) \
			and car.has_method("l_autista_ha_fernuto"):
		car.l_autista_ha_fernuto()


func _step_toward(target: Vector3, speed: float, delta: float) -> void:
	var before := global_position
	global_position = Passo.verso(self, target, speed * delta)
	var moved := global_position.distance_to(before)
	_face_toward(target)
	_animate_walk(moved)
	if global_position.distance_to(target) < 0.7:
		_despawn()


## Camminata. `moved` è la distanza percorsa nel frame: diviso il delta dà
## la velocità, che è quello che serve al BlendSpace per scegliere fra fermo,
## passo e corsa (e per mescolarli, quando sta in mezzo).
func _animate_walk(moved: float) -> void:
	if _anim == null:
		return # modello 3D esterno: non si anima a pezzi
	_anim.set_speed(moved / maxf(get_physics_process_delta_time(), 0.0001))


func _face_toward(target: Vector3) -> void:
	var dir: Vector3 = target - global_position
	dir.y = 0.0
	if dir.length() > 0.05:
		# forward(θ) = (−sinθ, 0, −cosθ): θ = atan2(−dir.x, −dir.z).
		_visual_root.rotation.y = atan2(-dir.x, -dir.z)


func _despawn() -> void:
	if car and is_instance_valid(car) and not car.paid:
		GameManager.register_client_lost()
	_lassa_a_machina()
	queue_free()


# ---------------------------------------------------------------------------
# Interazioni del player
# ---------------------------------------------------------------------------

func get_interact_prompt(_from_position: Vector3) -> String:
	if car == null or not is_instance_valid(car):
		return ""
	if car.paid:
		return ""
	if not _asked:
		# Col nome sopra, e non è un dettaglio: è la mezza riga che ti fa
		# ricordare, mentre hai il dito sulla E, che questo è quello che
		# ieri ti ha lasciato il resto giusto.
		var id: String = _cliente_id()
		if id == "":
			return "[E] chiure 'o cunto cu ll'autista"
		var comme := ""
		var r: float = GameManager.rapporto(id)
		if r >= Gente.AMICO:
			comme = " (uno 'e casa)"
		elif r <= Gente.NEMICO:
			comme = " (nun te pò vedé)"
		return "[E] chiure 'o cunto cu %s%s" % [_nomme(), comme]
	if _refused:
		return "Nun vò pagà… (click 'e sinistra: cazzotto)"
	return ""


func player_interact() -> void:
	if car == null or not is_instance_valid(car) or car.paid:
		return
	if not _asked:
		_asked = true
		# **Chiedere i soldi attaccato alla macchina si nota molto di piu'.**
		#
		# Uno che parla con una persona in mezzo alla piazza e' una
		# chiacchiera; uno che gli sta addosso alla portiera con la mano
		# aperta e' una richiesta di soldi, e si vede da trenta metri. Il
		# sospetto raddoppia se lo fai a ridosso dell'auto.
		var vicino_auto := false
		if car != null and is_instance_valid(car):
			vicino_auto = global_position.distance_to(car.global_position) < 3.4
		GameManager.report_risky_action(12.0 if vicino_auto else 6.0)
		if randf() < car.payment_chance():
			_pay(car.payment_amount(), false)
		else:
			_refused = true
			if _e_nuttata():
				_say(SAY_REFUSE_NOTTE[randi() % SAY_REFUSE_NOTTE.size()])
				SoundManager.play("fail", -7.0, 0.78)
			elif car.personality == "tirchio":
				_say(SAY_REFUSE_TIRCHIO)
				# 'O schiocco cu 'a lengua: 'o "no" napoletano, che si
				# sente prima di leggere la battuta.
				SoundManager.play("schiocco", -4.0)
			else:
				_say(SAY_REFUSE[randi() % SAY_REFUSE.size()])
				SoundManager.play("fail", -6.0, 0.85)
	elif _refused:
		_say(SAY_REFUSE_AGAIN)


func receive_punch(danno: int = 1) -> void:
	# **'A reazione, no 'o blocco.** Il colpo si vede addosso (clip
	# `Hit_Chest`/`Hit_Head` sopra alla locomozione) ma non toglie il
	# controllo: vedi `Animator.reagisci_colpo`.
	if _anim != null and _anim.has_method("reagisci_colpo"):
		_anim.reagisci_colpo(randf() < 0.4)
	if _ko["down"]:
		return
	hp -= maxi(1, danno)
	GameManager.nemico_colpito.emit(_nomme(), maxi(0, hp), MAX_HP)
	# E' una lite fra chi deve dare e chi deve avere: il quartiere ci mette
	# un po' prima di scandalizzarsi.
	# Menare un autista: conta solo se lo vedono, o se e' il terzo
	# in un minuto (vedi GameManager.violenza).
	GameManager.violenza(1.0)
	if hp <= 0:
		_go_down()
		return
	GameManager.register_punch()
	GameManager.report_risky_action(PUNCH_HEAT)
	SoundManager.pugno(0.0)
	GameManager.screen_shake.emit(0.45)
	_punches += 1
	_stagger = 0.35

	# Quello tornato per la multa non paga niente: le sta dando lui a te.
	# Un pugno lo rallenta appena e lo fa incazzare di più.
	if state == State.RETURNING or state == State.HUNTING or state == State.CALMING:
		_say(SAY_PUNCHED[randi() % SAY_PUNCHED.size()])
		if state != State.HUNTING:
			state = State.HUNTING
			_hunt_left = HUNT_DURATION
		else:
			_hunt_left += 4.0 # gliel'hai fatta più lunga
		return

	var player := get_tree().get_first_node_in_group("player")
	if player:
		var away: Vector3 = global_position - player.global_position
		away.y = 0.0
		if away.length() > 0.01:
			global_position += away.normalized() * 0.5

	var needed: int = car.punches_needed() if (car and is_instance_valid(car)) else 2
	if car and is_instance_valid(car) and not car.paid and _punches >= needed:
		# Il pugno decisivo: piccolo slow-motion da film di quartiere.
		GameManager.request_slow_motion(0.3, 0.25)
		_pay(maxi(1, int(car.payment_amount() * 0.5)), true)
		state = State.FLEEING
	else:
		_say(SAY_PUNCHED[randi() % SAY_PUNCHED.size()])
		if car == null or not is_instance_valid(car) or car.paid:
			state = State.FLEEING


## Steso per terra. Se non aveva ancora pagato, gli cadono di tasca un po'
## di spiccioli — ma stendere la gente in mezzo alla piazza si vede, e il
## sospetto schizza.
func _go_down() -> void:
	GameManager.register_punch()
	GameManager.report_risky_action(KO_HEAT)
	SoundManager.pugno(0.0)
	GameManager.request_slow_motion(0.35, 0.3)
	_say(KO.SAY_KO[randi() % KO.SAY_KO.size()])
	if car and is_instance_valid(car) and not car.paid:
		var dropped: int = maxi(1, int(car.payment_amount() * 0.6))
		GameManager.add_money(dropped)
		car.paid = true
		GameManager.register_forced_payment()
		GameManager.directing_gesture.emit(
			"L'hê stiso. 'E sorde so' cadute: +€%d" % dropped, false)
		_spawn_money_burst()
	KO.lay_down(_ko, _visual_root)


func _pay(amount: int, forced: bool) -> void:
	GameManager.add_money(amount)
	GameManager.register_client_served()
	_spawn_money_burst()
	if forced:
		GameManager.register_forced_payment()
		# **Pagare pecché l'hê menato nun è pagà.** Il rapporto scende di
		# ventidue: tre pagamenti a forza e uno che ti voleva bene diventa
		# uno che ti odia. È il prezzo vero del pagamento forzato, e fino
		# ad adesso non c'era: prendevi metà mancia e finiva lì.
		_rapporto_mosso(GameManager.RAPPORTO_FORZATO)
		_say(SAY_FORCED)
		SoundManager.play("soldi", -1.0, 0.92)
	else:
		_rapporto_mosso(GameManager.RAPPORTO_PAGATO)
		var voci: Array = SAY_PAY
		if _e_nuttata():
			voci = SAY_PAY_NOTTE
		_say("%s (+€%d)" % [voci[randi() % voci.size()], amount])
		SoundManager.play("soldi", -2.0, randf_range(0.98, 1.06))
	if car and is_instance_valid(car):
		car.paid = true


## Monetine che schizzano quando paga: la soddisfazione va vista.
func _spawn_money_burst() -> void:
	var burst := CPUParticles3D.new()
	burst.amount = 10
	burst.one_shot = true
	burst.lifetime = 0.7
	burst.explosiveness = 1.0
	burst.direction = Vector3(0, 1, 0)
	burst.spread = 45.0
	burst.initial_velocity_min = 2.5
	burst.initial_velocity_max = 4.0
	burst.gravity = Vector3(0, -9.8, 0)
	burst.scale_amount_min = 0.05
	burst.scale_amount_max = 0.08
	var coin_mesh := CylinderMesh.new()
	coin_mesh.top_radius = 0.5
	coin_mesh.bottom_radius = 0.5
	coin_mesh.height = 0.1
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.2)
	mat.metallic = 1.0
	mat.roughness = 0.2
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.2)
	mat.emission_energy_multiplier = 0.6
	coin_mesh.material = mat
	burst.mesh = coin_mesh
	burst.position = Vector3(0, 1.4, 0)
	add_child(burst)
	burst.emitting = true


## **Chi ti vede toccare la macchina sua non scappa: viene.**
##
## Prima scappava e basta, ed era la cosa sbagliata: rubare uno stemma
## sotto agli occhi del padrone non costava niente. Adesso ti insegue e
## te le dà — e sono sette punti di ossa a colpo su settantadue che ne
## hai. Il turista scappa lo stesso (non è casa sua, e ha una famiglia in
## macchina), ma gli altri tre caratteri no.
## **Ce sta 'a linea 'e vista.**
##
## Fino alla 0.49 `react_to_car_crime()` scattava sempre: staccavi lo
## stemma **alle spalle** del padrone, a otto metri, mentre lui guardava
## dall'altra parte, e quello si girava di scatto e ti veniva addosso. Il
## capo l'ha detto: *"i proprietari delle auto hanno linea di vista, non
## possono reagire se rubi lo stemma alle loro spalle"*.
##
## Due condizioni, tutte e due necessarie: deve essere **girato verso di
## te** (entro un cono di 100°) e non ci deve stare un muro in mezzo. Se
## sei fuori dal cono o dietro a qualcosa, non succede niente — sul
## momento.
##
## Ma la roba manca lo stesso, e prima o poi lui torna alla macchina: da lì
## nasce il **confronto**, che è la parte interessante.
const VISTA_ANGOLO: float = 50.0     # mezzo cono, in gradi
const VISTA_PORTATA: float = 22.0


func _me_vede(chi: Node3D) -> bool:
	if chi == null or not is_instance_valid(chi):
		return false
	var verso: Vector3 = chi.global_position - global_position
	verso.y = 0.0
	var d: float = verso.length()
	if d < 0.4:
		return true            # addosso: ti vede pure con gli occhi chiusi
	if d > VISTA_PORTATA:
		return false
	var avanti: Vector3 = -global_transform.basis.z
	avanti.y = 0.0
	if avanti.length() < 0.01:
		return false
	var cos_ang: float = avanti.normalized().dot(verso / d)
	if cos_ang < cos(deg_to_rad(VISTA_ANGOLO)):
		return false
	# E niente muri in mezzo.
	var spazio := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0, 1.5, 0),
		chi.global_position + Vector3(0, 1.3, 0), 1)
	q.exclude = [get_rid()]
	return spazio.intersect_ray(q).is_empty()


## Lo chiama l'auto quando le staccano lo stemma o la rigano. Se non ti
## vede, tace — e se lo segna.
func reagisci_si_me_vede() -> void:
	var pl := get_tree().get_first_node_in_group("player")
	if pl != null and pl is Node3D and _me_vede(pl as Node3D):
		react_to_car_crime()
		return
	_derubato_ammuccione = true


func react_to_car_crime() -> void:
	_say(SAY_CRIME)
	SoundManager.play("schiocco", -3.0)
	GameManager.add_heat(14.0)
	var pauroso: bool = car != null and is_instance_valid(car) \
		and car.personality == "turista"
	if pauroso or _ko["down"]:
		state = State.FLEEING
		return
	# Da qui in poi è una cosa fra voi due. Dura meno di una caccia da
	# multa — non è un verbale, è uno scatto di rabbia — ma basta a farti
	# capire che quello stemma l'hai pagato.
	_refused = true
	state = State.HUNTING
	_hunt_left = HUNT_DURATION * 0.7
	_hunt_hit_cd = 0.8
	GameManager.event_started.emit(
		"T'HA VISTO! 'O PADRONE D''A MACHINA TE VENE NCUOLLO!")
	_say("Ma che cazz' staje facenno?! Chella è 'a machina mia!")
