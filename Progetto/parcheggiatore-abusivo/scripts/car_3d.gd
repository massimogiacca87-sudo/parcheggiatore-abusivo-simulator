extends CharacterBody3D
## Car3D
## Cliente motorizzato. Ciclo: ARRIVING -> WAITING -> DIRECTING (regia a
## gesti: l'autista esegue i tuoi comandi) -> PARKED -> l'autista SCENDE
## dall'auto (driver_3d.gd) e si avvia all'uscita: è lì che lo fermi per
## farti pagare. L'auto parcheggiata resta esposta: furto dello stemma (E,
## solo auto di lusso) e vandalismo (F), con danni visibili progressivi.

## RUBATA e' arrivata alla 0.45 insieme ai furti su commissione. Sta in
## fondo apposta: in giro ci sono confronti scritti a numero (`c.state == 1`,
## `c.state <= 2`), e un valore nuovo in mezzo li avrebbe rotti tutti in
## silenzio.
enum State { ARRIVING, WAITING, DIRECTING, PARKED, LEAVING, RUBATA }

const DriverScript := preload("res://scripts/driver_3d.gd")
const Gente := preload("res://scripts/gente.gd")
const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const Tex := preload("res://scripts/textures.gd")
const Models := preload("res://scripts/models.gd")
const AutoVarieScript := preload("res://scripts/auto_varie.gd")

## Personalità del cliente: cambiano il gioco, non solo il colore.
## - turista: paga il DOPPIO, ma capisce i gesti al contrario (A/D invertiti)
## - tirchio: quasi mai paga di sua volontà, e serve un pugno in più
## - fretta: pazienza e tempo dimezzati, guida più veloce, paga bonus
const PERSONALITIES := ["normale", "turista", "tirchio", "fretta"]

const CAR_TYPES := {
	"economica": {
		"color": Color(0.62, 0.62, 0.58), "tip_min": 1, "tip_max": 3, "pay_mod": 0.08,
		"body_size": Vector3(1.55, 0.55, 3.1), "cabin_size": Vector3(1.25, 0.48, 1.5), "cabin_z": 0.4,
	},
	"berlina": {
		"color": Color(0.2, 0.35, 0.7), "tip_min": 3, "tip_max": 5, "pay_mod": 0.0,
		"body_size": Vector3(1.7, 0.6, 3.8), "cabin_size": Vector3(1.35, 0.5, 1.7), "cabin_z": -0.1,
	},
	"lusso": {
		"color": Color(0.1, 0.1, 0.12), "tip_min": 5, "tip_max": 10, "pay_mod": -0.15,
		"body_size": Vector3(1.8, 0.62, 4.2), "cabin_size": Vector3(1.4, 0.5, 1.8), "cabin_z": -0.15,
	},
	# 'O macchinone: quello del guappo. È il tipo che paga di più e che si
	# arrabbia di più, ed è l'unico che monta SEMPRE lo stemma — è tutto il
	# senso di averlo in strada.
	"bmw": {
		"color": Color(0.12, 0.12, 0.14), "tip_min": 6, "tip_max": 12,
		"pay_mod": -0.2,
		"body_size": Vector3(2.05, 0.66, 4.55),
		"cabin_size": Vector3(1.55, 0.52, 1.9), "cabin_z": -0.2,
	},
}

## **Diciassette carrozzerie, e non piu' tre.**
##
## Per una ventina di versioni in piazza si sono viste sempre le stesse due
## o tre macchine, e non perche' non ce ne fossero altre: in `Models/` c'era
## un pacchetto con dieci carrozzerie diverse che nessuno aveva mai aperto,
## e in `assets/models/` ce n'erano altre sette (`auto_pack_1..7`) importate
## mesi fa e mai collegate a niente. Diciassette modelli buoni, e il gioco
## ne usava tre.
##
## Adesso ogni tipo pesca da una lista, e la lista e' fatta per taglia: le
## utilitarie sono corte, le berline medie, e sotto "lusso" ci vanno il
## coupé, il SUV e la sportiva. Il pick-up e il monovolume stanno con le
## berline perche' in una piazza napoletana quelli sono, appunto, macchine
## normali.
##
## La BMW rotta e' stata **tolta**: il file non aveva ne' normali ne'
## materiali (per questo si vedeva bianca e a scaglie), e con diciassette
## modelli sani non valeva la pena di ricostruirla a mano. Il tipo "bmw"
## resta e pesca dalle carrozzerie grosse.
## **Quali sono dentro e quali no, e perché.**
##
## `tools/prova_modelli.gd` carica ogni modello, ne misura l'ingombro e
## guarda che materiali ha. Ha bocciato quattro cose:
##
##   car_economica, car_berlina, car_lusso   nessun materiale
##   car_coupe                               larga 3,73 m (sta di sghembo)
##
## I tre `.obj` sono nel gioco dalla 0.14 e **non hanno mai avuto un
## materiale**: per questo si vedevano bianche: la verniciatura di
## `Models.tint` cerca il materiale "body" e su di loro non trovava niente.
## Il coupé del pacchetto sta ruotato nel file di partenza e il raddrizzamento
## automatico non lo prende: si rifara' con calma.
##
## Restano **sedici modelli buoni**, tutti misurati.
## **Ventotto modelli, non più sedici.**
##
## La 0.46 ne ha portati dodici nuovi, e la fascia in cui cade ognuno non è
## un capriccio: è quanto costa la macchina nella vita vera, perché è
## quello che decide la mancia. 'A Punto e l'AE86 stanno in economica
## perché sono le macchine che uno di quel quartiere guida davvero; Urus,
## M8, Porsche e P1 stanno in bmw perché sono quelle che, quando arrivano
## in piazza, il parcheggiatore si tira su la coppola.
const MODELLI := {
	# 'A 500 sta cca' e ce sta pe' dritto: è la macchina più corta della
	# città (2,97 contro i 4,30 di media) e in un posto auto ci balla.
	#
	# **E cinche d''o Car Pack** (0.59): `car_economica` (una due volumi
	# corta, 3,31), `car_berlina` (la berlina a tre volumi), `car_lusso`
	# (il SUV bianco), `car_coupe2` e `car_sportiva2`. Sono tutte dello
	# stesso autore e dello stesso stile, e vanno ognuna nella fascia del
	# suo prezzo: la SUV nel lusso, la sportiva arancione con le BMW.
	"economica": ["car_utilitaria", "car_compatta",
		"auto_pack_1", "auto_pack_2", "auto_pack_3",
		"car_punto", "car_ae86", "car_generica", "car_500", "car_economica"],
	"berlina": ["car_berlina2", "car_familiare", "car_monovolume",
		"car_pickup", "auto_pack_4", "auto_pack_5",
		"car_generica", "car_mercedes", "car_gtr", "car_e46", "car_berlina"],
	"lusso": ["car_suv", "car_fuoristrada", "auto_pack_6", "auto_pack_7",
		"car_urus", "car_mustang", "car_bmw", "car_lusso", "car_coupe2"],
	# **'A E46 sta cca' e nun int'ê llusso**, che è il punto di tutta la
	# fascia: il tipo che parcheggia in doppia fila e ti guarda male non
	# guida una supercar da centomila euro, guida una berlina tedesca di
	# vent'anni fa tenuta lucida. Quella macchina lì.
	"bmw": ["car_sportiva", "car_bmw", "car_e46", "car_m8", "car_porsche",
		"car_p1", "car_urus", "car_gtr", "car_sportiva2"],
}

## Il modello di QUESTA macchina: scelto una volta sola alla nascita.
var _modello_scelto: String = ""

# Stemmi delle auto di lusso: collezionabili, rubabili, rivendibili da 'O Zio.
const EMBLEMS := [
	# 0.61: 25/18/20 → 10/7/8. Uno stemma si stacca in tre secondi, e un
	# quarto di giornata in tre secondi era il furto d'auto in piccolo.
	{"name": "Cavallino Sfrenato", "value": 10, "color": Color(0.95, 0.78, 0.1)},
	{"name": "Tridente d'Argento", "value": 7, "color": Color(0.8, 0.82, 0.88)},
	{"name": "Stella a Quattro Punte", "value": 8, "color": Color(0.9, 0.9, 0.95)},
]

# Verniciature possibili per tipo. Servono a non riempire la piazza di
# cloni identici, ma pescate da una tavolozza credibile: lasciando il colore
# libero uscivano utilitarie fucsia e berline di lusso viola.
const PAINTS := {
	"economica": [
		Color(0.86, 0.84, 0.79), Color(0.78, 0.24, 0.20), Color(0.55, 0.66, 0.72),
		Color(0.85, 0.70, 0.25), Color(0.42, 0.55, 0.42), Color(0.70, 0.72, 0.74),
	],
	"berlina": [
		Color(0.16, 0.26, 0.52), Color(0.30, 0.32, 0.35), Color(0.18, 0.34, 0.28),
		Color(0.55, 0.18, 0.20), Color(0.74, 0.75, 0.76), Color(0.36, 0.28, 0.22),
	],
	"lusso": [
		Color(0.07, 0.07, 0.09), Color(0.13, 0.15, 0.22), Color(0.22, 0.06, 0.09),
		Color(0.20, 0.21, 0.23), Color(0.09, 0.16, 0.14),
	],
	# La BMW del quartiere è nera, bianca o grigio canna di fucile. Mai un
	# colore allegro: non sarebbe la stessa macchina.
	"bmw": [
		Color(0.05, 0.05, 0.06), Color(0.86, 0.87, 0.88), Color(0.22, 0.23, 0.26),
		Color(0.10, 0.12, 0.20),
	],
}

const SOLICIT_HEAT: float = 6.0
const VANDALIZE_HEAT: float = 20.0
## Rubare lo stemma dal cofano e' la cosa piu' vistosa che si possa fare
## in mezzo alla strada: uno chinato su una macchina che non e' la sua, con
## le mani sul cofano. Vale piu' di una vandalizzata.
const STEAL_HEAT: float = 24.0
const DRIVE_SPEED: float = 2.6
const MAX_DAMAGE: int = 3

# --- Regia a gesti ---
const DIRECTING_MAX_SPEED: float = 3.0
const DIRECTING_BRAKE: float = 7.0
const DIRECTING_FRICTION: float = 2.0
const DIRECTING_TURN_RATE: float = 2.0
const DIRECTING_MIN_SPEED_TO_TURN: float = 0.1
const DIRECTING_TIME_LIMIT: float = 40.0
const PARK_TRIGGER_DIST: float = 1.6
const PARK_TRIGGER_ALIGN_DEG: float = 50.0
const PARK_TRIGGER_SPEED: float = 1.1
const ASSIST_DURATION: float = 0.9
const BUMP_COOLDOWN: float = 0.6
const MAX_BUMPS_BEFORE_GIVEUP: int = 8
const CAUTION_DISTANCE: float = 1.7
const CAUTION_SPEED_CAP: float = 0.9

const SHOUTS_GO := ["VAI VAI VAI!", "VIEN VIEN VIEN!", "AVANT', VAI!"]
const SHOUTS_STOP := ["ASPETT' ASPETT'!", "FERMT' FERMT'!", "STATT' FERMO!"]
const SHOUTS_LEFT := ["A SINIST'! GIR GIR GIR!", "GIRA A SINISTRA! GIR!"]
const SHOUTS_RIGHT := ["A DEST'! GIR GIR GIR!", "GIRA A DESTRA! GIR!"]
const DRIVER_REPLIES := ["Accussì?", "Aggio capito, aggio capito...", "Va buo', va buo'...", "Statt' calmo!", "E mo' vengo!"]
const DRIVER_CAUTION := "OINÈ, 'O MURO! 'O MURO!"
const DRIVER_ASSIST := "Va buo', mo' ce penso io!"
const DRIVER_RAGE_BUMPS := "MA CHE M'HÊ FATTO FÀ! ME NE VACO!"
const DRIVER_RAGE_TIME := "E QUANTO CE VO'?! ME NE VACO!"
const DRIVER_CAR_DAMAGED := "A MACCHINA MIA!!!"

# --- Parcheggio abusivo (fuori dalle strisce) ---
## Quello che grida il parcheggiatore quando piazza l'auto dove capita.
const SHOUTS_ABUSIVO := [
	"NUN TE PREOCCUPÀ!", "STAI NA FAVOLA!", "STAI NA BOMBA!",
	"STATTE SENZA PENSIER!", "LASSA STÀ, CE PENZO IO!",
	"STAMM' A POSTO ACCUSSÌ!",
]
## E quello che risponde l'autista, che tanto convinto non è.
const DRIVER_DOUBT := [
	"Ma qua se pò?", "E si m'a fanno 'a multa?", "Mah... me fido, neh?",
	"Guagliò, vedi che t'a faccio pagà a te...",
]
const DRIVER_MULTA_RAGE := [
	"MA CHE È STA MULTA?!", "GUAGLIÓ! VIENI CCÀ!", "M'HÊ FATTO PIGLIÀ 'A MULTA!",
]
## Ogni quanto un vigile può accorgersi dell'auto piazzata male.
const MULTA_CHECK_EVERY: float = 3.0
## Distanza entro cui il vigile "vede" l'auto abusiva.
const MULTA_SIGHT: float = 11.0

# --- Investimenti ---
## Sotto questa velocità l'auto non fa male: ci si può appoggiare.
const RUN_OVER_MIN_SPEED: float = 0.7
## Quanto vicino deve stare il player al fianco dell'auto per prenderla.
const RUN_OVER_RADIUS: float = 1.5
const RUN_OVER_COOLDOWN: float = 1.6

var state: int = State.ARRIVING
## Il colore della carrozzeria. Serve ai furti su commissione, che chiedono
## "'na berlina nera" e devono poter dire se questa lo e'.
var colore: Color = Color(0.6, 0.6, 0.6)
var car_type: String = "economica"
var forced_type: String = "" # per test/zone future: forza il tipo prima di add_child
var personality: String = "normale"
var forced_personality: String = ""
## Si dint'â machina ce sta uno d''e clienti fisse (vedi `gente.gd`), chisto
## è ll'id suio. Vacante vò dì 'nu sconosciuto comme a primma.
var cliente_id: String = ""
var waiting_point: Vector3
var exit_point: Vector3
var assigned_spot: Node = null
var minigame_score: float = 0.0
var paid: bool = false # il cliente ha pagato (normale o forzato)

var has_emblem: bool = false
var emblem_info: Dictionary = {}
var damage_level: int = 0

## Vero se questo cliente arriva nella piazza dove sta il salotto: e' li'
## che radio, piante e luminarie fanno effetto. Lo scrive chi crea l'auto.
var piazza_curata: bool = false

## 'N quale piazza sta. Serve ô carattere d''a piazza (0.55): 'o mercato
## paga poco, 'o stadio assaje. 'O scrive chi 'a crea.
var zona_id: String = "piazza"

var _patience_time: float = 0.0
var _parked_time: float = 0.0
var _damage_registered: bool = false
## Una vendetta per auto: rigarla tre volte non fa girare la voce tre volte.
var _vendetta_contata: bool = false
## Stesso principio per il rapporto col cliente fisso: una macchina, un
## tradimento.
var _rapporto_rutto: bool = false
var _driver: Node = null

var _drive_speed: float = 0.0
var _directing_time_left: float = 0.0
var _bump_count: int = 0
var _bump_cooldown: float = 0.0

var _reaction_time: float = 0.25
var _base_reaction_time: float = 0.25 # immutabile: vedi _start_parking
var _wobble_amp: float = 0.1
var _ai_throttle: float = 0.0
var _ai_brake: float = 0.0
var _ai_steer: float = 0.0
var _time_alive: float = 0.0
var _reply_timer: float = 0.0
var _caution_reply_cd: float = 0.0

var _assist_active: bool = false
var _assist_time: float = 0.0
var _assist_from_pos: Vector3
var _assist_from_rot: float = 0.0
var _assist_target_rot: float = 0.0
var _assist_align_ratio: float = 0.0
var _assist_dist_ratio: float = 0.0

var _visual_root: Node3D
var _body_mesh_node: MeshInstance3D
## Modello 3D esterno, quando c'è (assets/models/car_*.obj). Se è null
## l'auto è quella costruita a scatole qui dentro.
var _custom_model: Node3D = null

## I perni delle ruote, ognuno col suo raggio. Girano di `spazio / raggio`:
## e' la formula del rotolamento senza slittamento, ed e' l'unica che fa
## sembrare l'auto appoggiata per terra invece che trascinata.
var _ruote: Array = []
var _giro_ruote: float = 0.0
var _model_size: Vector3 = Vector3.ZERO
var _emblem_node: Node3D = null # contiene i pezzi della silhouette
var _emblem_root: Node3D = null
var _emblem_spin: float = 0.0
var _emblem_base_y: float = 0.0
var _bubble: Node3D = null
var _honk_cd: float = 0.0
var _smoke_particles: CPUParticles3D = null

# --- Parcheggio abusivo ---
## Vero se l'auto è stata piazzata fuori dalle strisce col tasto SPAZIO.
var parked_abusive: bool = false
## Vero se un vigile le ha appiccicato la multa sul parabrezza.
var has_multa: bool = false
var _multa_node: Node3D = null
var _multa_cd: float = MULTA_CHECK_EVERY
## La moneta si lancia una volta sola per auto: vedi `_check_multa`.
var _multa_decisa: bool = false
var _multabile: bool = false
## Vero se lo stemma è stato staccato senza che il padrone vedesse: è
## quello che lo fa tornare indietro a chiedere conto.
var _stemma_sparito: bool = false
## Idem per le botte alla carrozzeria. **Prima non esisteva**, e rigare una
## macchina di nascosto non produceva assolutamente niente: nessuno se ne
## accorgeva, mai, nemmeno il proprietario che ci risaliva sopra.
var _scassata_ammuccione: bool = false
## Vero mentre l'autista sta tornando all'auto per scoprire la multa.
var _multa_confronto: bool = false
var _run_over_cd: float = 0.0

## Il percorso di arrivo e quello di uscita, e a che tappa siamo.
var _via_in: Array = []
var _via_out: Array = []
var _tappa: int = 1
## Da quanto l'auto non avanza. Serve al piano B: una macchina che striscia
## contro uno spigolo puo' restare incastrata per sempre, e una macchina
## incastrata sul varco tappa l'ingresso a tutte quelle dopo.
var _fermo_da: float = 0.0
var _ultima_pos: Vector3 = Vector3.ZERO


func _ready() -> void:
	add_to_group("cars")
	collision_layer = 4
	# Collide con il mondo E con le altre auto (e persone): gli incidenti
	# tra macchine sono reali, con danni visibili su entrambe.
	collision_mask = 1 | 4
	_pick_type()
	_build_visual()
	_build_collision()
	_patience_time = randf_range(6.0, 9.0) if personality == "fretta" else randf_range(10.0, 16.0)
	# **'A radio.** Chi aspetta con la musica aspetta di piu': quasi meta'
	# del tempo in piu' prima di incazzarsi e andarsene. Ventidue euro che
	# valgono un cliente perso ogni tanto — e un cliente perso e' dieci
	# euro di mancia piu' la reputazione.
	if piazza_curata:
		_patience_time *= GameManager.pazienza_cliente()

	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 2.6, 0)
	add_child(_bubble)


## L'autista (ancora al volante) dice qualcosa: fumetto 3D + riga sull'HUD.
func _say(text: String) -> void:
	if _bubble:
		_bubble.say(text)
	GameManager.directing_gesture.emit(text, true)


## Il fischietto del parcheggiatore. Un'auto che sta arrivando taglia dritto
## verso di lui invece di andare al suo punto d'attesa; una che gia' aspetta
## si rimette buona (la pazienza torna su) e si gira dalla sua parte.
##
## Non e' cortesia: e' che se non ti fai sentire tu, la macchina va dove
## vuole lei — e quando ci sara' un rivale in piazza, andra' da lui.
func richiamata_dal_fischio(dove: Vector3) -> bool:
	match state:
		State.ARRIVING:
			waiting_point = Vector3(dove.x, waiting_point.y, dove.z)
			_patience_time += 4.0
			if _bubble:
				_bubble.say("Eccomi, eccomi!", 1.3)
			return true
		State.WAITING:
			# Il fischio COMPRA TEMPO: nove secondi in piu' di pazienza.
			# E' questo che lo rende un attrezzo e non un effetto sonoro —
			# un cliente che se ne va e' un cliente perso, e con un fischio
			# lo tieni lì mentre finisci di sistemare l'altra macchina.
			_patience_time += 9.0
			_honk_cd = 3.5
			_face_toward(dove)
			if _bubble:
				_bubble.say("Uè, dimme tu!", 1.3)
			return true
	return false


## `via_ingresso` e `via_uscita` sono i percorsi: liste di punti che l'auto
## segue in fila. Il primo punto dell'ingresso e' anche dove nasce.
##
## Prima l'auto compariva dal niente a due metri dentro alla piazza, sul
## varco, e da li' puntava dritta al suo posto in coda. Due problemi: uno,
## non ARRIVAVA da nessuna parte — si materializzava mezza dentro al muro
## d'ingresso, che e' il "entrano dai muri" che si vedeva giocando; due, la
## linea retta fino alla coda passava attraverso qualunque cosa ci fosse in
## mezzo. Adesso nasce in mezzo alla strada, fuori dalla piazza, e ci entra
## girando.
func setup(entry: Vector3, wait_point: Vector3, exit: Vector3,
		via_ingresso: Array = [], via_uscita: Array = []) -> void:
	_via_in = via_ingresso.duplicate()
	_via_out = via_uscita.duplicate()
	global_position = _via_in[0] if not _via_in.is_empty() else entry
	if _via_in.size() > 1:
		_face_toward(_via_in[1])
	_tappa = 1
	waiting_point = wait_point
	exit_point = exit


## **Una macchina su tre porta uno che tiene 'o nomme.**
##
## Non di più, e la proporzione è la cosa importante. Se fossero tutti
## clienti fissi la piazza diventerebbe un paese di sei abitanti, e la
## sorpresa di vedere arrivare la Mercedes nera del dottore sparirebbe
## dentro alla ripetizione. Se fossero uno su dieci non li riconosceresti
## mai. Uno su tre vuol dire che in un turno ne passano due o tre, sempre
## diversi, e che quando torna quello di ieri te ne accorgi.
##
## Il cliente si prende da `GameManager.cliente_libbero()`, che tiene il
## conto di chi sta già in piazza: due Gennaro insieme sarebbero una
## macchina rotta, non una gag.
const CLIENTE_FISSO_OGNI: float = 0.34


func _piglia_cliente_fisso() -> bool:
	if forced_type != "" or forced_personality != "":
		return false # i test e le zone speciali comandano loro
	if randf() >= CLIENTE_FISSO_OGNI:
		return false
	var id: String = GameManager.cliente_libbero()
	if id == "":
		return false
	var c: Dictionary = Gente.cliente(id)
	if c.is_empty():
		return false
	cliente_id = id
	# La macchina è la sua faccia: stesso tipo, stesso colore, sempre.
	car_type = str(c["machina"])
	personality = str(c["personalita"])
	colore = c["colore"]
	# **E stesso modello** (0.59). Il tipo e il colore erano fissi, il
	# modello no: si pescava a sorte nella fascia, e la giardinetta grigia
	# di Gennaro una volta era una Punto e la volta dopo un pickup. Adesso
	# il modello viene dal nome (sempre lo stesso per la stessa persona), o
	# è scritto nella scheda — Peppe 'o Tassista arriva col taxi.
	if c.has("modello"):
		_modello_scelto = str(c["modello"])
	else:
		var lista: Array = MODELLI.get(car_type, [])
		if not lista.is_empty():
			_modello_scelto = str(lista[absi(hash(id)) % lista.size()])
	GameManager.cliente_arriva(id)
	return true


## Comme se chiamma chi sta dint'â machina. Vacante si è 'nu sconosciuto.
func nomme_cliente() -> String:
	if cliente_id == "":
		return ""
	var c: Dictionary = Gente.cliente(cliente_id)
	return str(c["nome"]) if not c.is_empty() else ""


func _pick_type() -> void:
	if _piglia_cliente_fisso():
		_regola_tipo()
		return
	if forced_type != "":
		car_type = forced_type
	else:
		# Più auto di lusso di prima: erano il 12% e in un turno da tre
		# minuti uno stemma non lo vedevi mai.
		var roll := randf()
		if roll < 0.42:
			car_type = "economica"
		elif roll < 0.72:
			car_type = "berlina"
		elif roll < 0.88:
			car_type = "lusso"
		else:
			# La BMW è il dodici per cento: abbastanza da vederne una ogni
			# due o tre minuti, non abbastanza da smettere di essere un
			# avvenimento quando arriva.
			car_type = "bmw"

	_regola_tipo()

	if forced_personality != "":
		personality = forced_personality
	else:
		var p_roll := randf()
		if p_roll < 0.6:
			personality = "normale"
		elif p_roll < 0.75:
			personality = "turista"
		elif p_roll < 0.9:
			personality = "tirchio"
		else:
			personality = "fretta"

	if personality == "fretta":
		_patience_time = 0.0 # verrà ridotta in _ready


## Comme guida e che porta ncoppa, dato 'o tipo 'e machina.
func _regola_tipo() -> void:
	match car_type:
		"economica":
			_base_reaction_time = 0.34
			_wobble_amp = 0.16
		"berlina":
			_base_reaction_time = 0.24
			_wobble_amp = 0.09
			# Una berlina su tre monta comunque uno stemma che vale la pena
			# di svitare: così di roba da fottere ce n'è quasi sempre.
			if randf() < 0.35:
				has_emblem = true
				emblem_info = EMBLEMS[randi() % EMBLEMS.size()]
		"bmw":
			# Guida svelta e non perdona: reagisce prima di tutti e non
			# ondeggia. E lo stemma ce l'ha sempre.
			_base_reaction_time = 0.18
			_wobble_amp = 0.05
			has_emblem = true
			emblem_info = EMBLEMS[randi() % EMBLEMS.size()]
		"lusso":
			_base_reaction_time = 0.15
			_wobble_amp = 0.03
			has_emblem = true
			emblem_info = EMBLEMS[randi() % EMBLEMS.size()]
	_reaction_time = _base_reaction_time


func _build_visual() -> void:
	_visual_root = Node3D.new()
	add_child(_visual_root)

	var info: Dictionary = CAR_TYPES[car_type]
	var body_size: Vector3 = info["body_size"]
	var half_len: float = body_size.z / 2.0
	var half_w: float = body_size.x / 2.0
	var body_top: float = 0.28 + body_size.y

	# Se esiste un modello 3D vero per questo tipo di auto, si usa quello.
	# I modelli in assets/models sono già tagliati sulla misura del gioco
	# (muso verso -Z, origine a terra), quindi si prendono così come sono:
	# scalarli qui li deformerebbe soltanto.
	if _modello_scelto == "":
		var lista: Array = MODELLI.get(car_type, [])
		if lista.is_empty():
			_modello_scelto = "car_" + car_type
		else:
			_modello_scelto = str(lista[randi() % lista.size()])
	var custom := Models.spawn_by_length(_modello_scelto)
	if custom != null:
		_visual_root.add_child(custom)
		_custom_model = custom
		_body_mesh_node = null

		# Vetri, cromature e gomme come si deve, e una verniciatura diversa
		# per ogni auto: altrimenti la piazza si riempie di cloni identici.
		Models.polish_vehicle(custom)
		colore = _random_paint()
		Models.tint(custom, ["body", "carroz", "scocca"], colore, 0.55, 0.3)

		if _modello_scelto == "car_taxi":
			AutoVarieScript.insegna_taxi(_visual_root)
		_model_size = Models.size_of(custom)
		# Le quattro ruote del modello stanno tutte dentro a una mesh sola:
		# si tagliano in quattro e ognuna prende il suo perno (vedi
		# `Models.stacca_ruote`).
		_ruote = Models.stacca_ruote(custom)
		_build_contact_shadow(_model_size)
		if has_emblem:
			# Lo stemma va sul cofano, non sul tetto: il cofano sta circa
			# a due terzi dell'altezza totale dell'auto.
			_build_emblem(_model_size.y * 0.6, _model_size.z / 2.0)
		return

	var paint := StandardMaterial3D.new()
	colore = _random_paint()
	paint.albedo_color = colore
	paint.metallic = 0.6
	paint.roughness = 0.28
	var glass := Tex.flat(Color(0.11, 0.15, 0.19), 0.06, 0.9)
	var chrome := Tex.flat(Color(0.82, 0.84, 0.88), 0.12, 1.0)
	var rubber := Tex.flat(Color(0.06, 0.06, 0.07), 0.95)
	var dark := Tex.flat(Color(0.09, 0.09, 0.1), 0.7)

	# --- Scocca in tre volumi: pianale, cofano, coda ---
	_body_mesh_node = MeshInstance3D.new()
	var lower := BoxMesh.new()
	lower.size = Vector3(body_size.x, body_size.y * 0.62, body_size.z)
	_body_mesh_node.mesh = lower
	_body_mesh_node.position = Vector3(0, 0.28 + body_size.y * 0.31, 0)
	_body_mesh_node.material_override = paint
	_visual_root.add_child(_body_mesh_node)

	# Fascia superiore più stretta: dà il "fianco" all'auto
	var belt := MeshInstance3D.new()
	var belt_mesh := BoxMesh.new()
	belt_mesh.size = Vector3(body_size.x * 0.94, body_size.y * 0.42, body_size.z * 0.98)
	belt.mesh = belt_mesh
	belt.position = Vector3(0, 0.28 + body_size.y * 0.72, 0)
	belt.material_override = paint
	_visual_root.add_child(belt)

	# Cofano leggermente inclinato
	var hood := MeshInstance3D.new()
	var hood_mesh := BoxMesh.new()
	hood_mesh.size = Vector3(body_size.x * 0.9, 0.1, body_size.z * 0.3)
	hood.mesh = hood_mesh
	hood.position = Vector3(0, body_top - 0.02, -half_len * 0.62)
	hood.rotation.x = deg_to_rad(-2.5)
	hood.material_override = paint
	_visual_root.add_child(hood)

	# --- Abitacolo: parabrezza inclinato, tetto, lunotto ---
	var cabin_size: Vector3 = info["cabin_size"]
	var cabin_z: float = info["cabin_z"]
	var roof := MeshInstance3D.new()
	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(cabin_size.x * 0.98, 0.09, cabin_size.z * 0.92)
	roof.mesh = roof_mesh
	roof.position = Vector3(0, body_top + cabin_size.y, cabin_z)
	roof.material_override = paint
	_visual_root.add_child(roof)

	var windshield := MeshInstance3D.new()
	var ws_mesh := BoxMesh.new()
	ws_mesh.size = Vector3(cabin_size.x * 0.95, cabin_size.y * 1.12, 0.06)
	windshield.mesh = ws_mesh
	windshield.position = Vector3(0, body_top + cabin_size.y * 0.5,
		cabin_z - cabin_size.z * 0.5)
	windshield.rotation.x = deg_to_rad(-26)
	windshield.material_override = glass
	_visual_root.add_child(windshield)

	var rear_glass := MeshInstance3D.new()
	var rg_mesh := BoxMesh.new()
	rg_mesh.size = Vector3(cabin_size.x * 0.95, cabin_size.y * 1.05, 0.06)
	rear_glass.mesh = rg_mesh
	rear_glass.position = Vector3(0, body_top + cabin_size.y * 0.5,
		cabin_z + cabin_size.z * 0.5)
	rear_glass.rotation.x = deg_to_rad(22)
	rear_glass.material_override = glass
	_visual_root.add_child(rear_glass)

	# Finestrini laterali con montante centrale
	for sx in [-1.0, 1.0]:
		var side_glass := MeshInstance3D.new()
		var sg_mesh := BoxMesh.new()
		sg_mesh.size = Vector3(0.05, cabin_size.y * 0.82, cabin_size.z * 0.94)
		side_glass.mesh = sg_mesh
		side_glass.position = Vector3(sx * cabin_size.x * 0.5, body_top + cabin_size.y * 0.52, cabin_z)
		side_glass.material_override = glass
		_visual_root.add_child(side_glass)

		var pillar := MeshInstance3D.new()
		var pillar_mesh := BoxMesh.new()
		pillar_mesh.size = Vector3(0.07, cabin_size.y * 0.85, 0.09)
		pillar.mesh = pillar_mesh
		pillar.position = Vector3(sx * cabin_size.x * 0.5, body_top + cabin_size.y * 0.5, cabin_z)
		pillar.material_override = paint
		_visual_root.add_child(pillar)

		# Specchietto retrovisore
		var mirror := MeshInstance3D.new()
		var mirror_mesh := BoxMesh.new()
		mirror_mesh.size = Vector3(0.16, 0.1, 0.06)
		mirror.mesh = mirror_mesh
		mirror.position = Vector3(sx * (half_w + 0.06), body_top + 0.12,
			cabin_z - cabin_size.z * 0.45)
		mirror.material_override = paint
		_visual_root.add_child(mirror)

		# Maniglia della portiera
		var handle := MeshInstance3D.new()
		var handle_mesh := BoxMesh.new()
		handle_mesh.size = Vector3(0.04, 0.05, 0.22)
		handle.mesh = handle_mesh
		handle.position = Vector3(sx * (half_w + 0.01), body_top - 0.16, cabin_z + 0.15)
		handle.material_override = chrome
		_visual_root.add_child(handle)

		# Linea di taglio delle portiere
		var seam := MeshInstance3D.new()
		var seam_mesh := BoxMesh.new()
		seam_mesh.size = Vector3(0.02, body_size.y * 0.75, 0.02)
		seam.mesh = seam_mesh
		seam.position = Vector3(sx * (half_w + 0.005), 0.28 + body_size.y * 0.45, cabin_z + cabin_size.z * 0.5)
		seam.material_override = dark
		_visual_root.add_child(seam)

	# --- Paraurti, fari, fanali, targa ---
	var head_mat := Tex.flat(Color(1.0, 0.98, 0.88), 0.1, 0.0, 1.6)
	var tail_mat := Tex.flat(Color(0.75, 0.1, 0.08), 0.2, 0.0, 1.0)
	var indicator := Tex.flat(Color(0.95, 0.6, 0.1), 0.2, 0.0, 0.5)

	for lx in [-1.0, 1.0]:
		var head := MeshInstance3D.new()
		var head_mesh := BoxMesh.new()
		head_mesh.size = Vector3(0.34, 0.16, 0.1)
		head.mesh = head_mesh
		head.position = Vector3(lx * body_size.x * 0.32, 0.28 + body_size.y * 0.62, -half_len + 0.03)
		head.material_override = head_mat
		_visual_root.add_child(head)

		var blink := MeshInstance3D.new()
		var blink_mesh := BoxMesh.new()
		blink_mesh.size = Vector3(0.12, 0.1, 0.08)
		blink.mesh = blink_mesh
		blink.position = Vector3(lx * (half_w - 0.1), 0.28 + body_size.y * 0.6, -half_len + 0.04)
		blink.material_override = indicator
		_visual_root.add_child(blink)

		var tail := MeshInstance3D.new()
		var tail_mesh := BoxMesh.new()
		tail_mesh.size = Vector3(0.3, 0.18, 0.09)
		tail.mesh = tail_mesh
		tail.position = Vector3(lx * body_size.x * 0.33, 0.28 + body_size.y * 0.62, half_len - 0.03)
		tail.material_override = tail_mat
		_visual_root.add_child(tail)

	for bz in [-half_len - 0.04, half_len + 0.04]:
		var bumper := MeshInstance3D.new()
		var bumper_mesh := BoxMesh.new()
		bumper_mesh.size = Vector3(body_size.x * 1.02, 0.22, 0.14)
		bumper.mesh = bumper_mesh
		bumper.position = Vector3(0, 0.42, bz)
		bumper.material_override = dark
		_visual_root.add_child(bumper)

	# Griglia anteriore
	var grille := MeshInstance3D.new()
	var grille_mesh := BoxMesh.new()
	grille_mesh.size = Vector3(body_size.x * 0.52, 0.14, 0.06)
	grille.mesh = grille_mesh
	grille.position = Vector3(0, 0.28 + body_size.y * 0.45, -half_len - 0.01)
	grille.material_override = dark
	_visual_root.add_child(grille)

	# Targa italiana: rettangolo bianco coi bordi blu
	for pz in [-half_len - 0.08, half_len + 0.08]:
		var plate := MeshInstance3D.new()
		var plate_mesh := BoxMesh.new()
		plate_mesh.size = Vector3(0.52, 0.11, 0.02)
		plate.mesh = plate_mesh
		plate.position = Vector3(0, 0.5, pz)
		plate.material_override = Tex.flat(Color(0.95, 0.95, 0.93), 0.4)
		_visual_root.add_child(plate)

		var eu := MeshInstance3D.new()
		var eu_mesh := BoxMesh.new()
		eu_mesh.size = Vector3(0.07, 0.11, 0.022)
		eu.mesh = eu_mesh
		eu.position = Vector3(-0.225, 0.5, pz)
		eu.material_override = Tex.flat(Color(0.05, 0.15, 0.6), 0.4)
		_visual_root.add_child(eu)

	# Tubo di scarico
	var exhaust := MeshInstance3D.new()
	var ex_mesh := CylinderMesh.new()
	ex_mesh.top_radius = 0.04
	ex_mesh.bottom_radius = 0.04
	ex_mesh.height = 0.14
	exhaust.mesh = ex_mesh
	exhaust.rotation.x = deg_to_rad(90)
	exhaust.position = Vector3(half_w * 0.55, 0.32, half_len + 0.05)
	exhaust.material_override = chrome
	_visual_root.add_child(exhaust)

	_build_contact_shadow(body_size)

	# --- Ruote con cerchione ---
	var wheel_z: float = half_len - 0.78
	for wx in [-1.0, 1.0]:
		for wz in [-wheel_z, wheel_z]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.31
			wheel_mesh.bottom_radius = 0.31
			wheel_mesh.height = 0.24
			wheel.mesh = wheel_mesh
			wheel.rotation.z = deg_to_rad(90)
			wheel.position = Vector3(wx * (half_w - 0.06), 0.31, wz)
			wheel.material_override = rubber
			# Il perno sta in mezzo fra l'auto e la ruota: la ruota ci sta
			# dentro col suo mezzo giro di posa (l'asse del cilindro deve
			# guardare di lato), il perno gira attorno alla X e basta.
			var perno_r := Node3D.new()
			perno_r.position = wheel.position
			wheel.position = Vector3.ZERO
			_visual_root.add_child(perno_r)
			perno_r.add_child(wheel)
			_ruote.append({"perno": perno_r, "raggio": 0.31,
				"riposo": Basis.IDENTITY})

			var rim := MeshInstance3D.new()
			var rim_mesh := CylinderMesh.new()
			rim_mesh.top_radius = 0.19
			rim_mesh.bottom_radius = 0.19
			rim_mesh.height = 0.26
			rim.mesh = rim_mesh
			rim.rotation.z = deg_to_rad(90)
			rim.position = Vector3(wx * (half_w - 0.05), 0.31, wz)
			rim.material_override = chrome
			_visual_root.add_child(rim)

			# Passaruota scuro, per staccare la ruota dalla carrozzeria
			var arch := MeshInstance3D.new()
			var arch_mesh := BoxMesh.new()
			arch_mesh.size = Vector3(0.06, 0.3, 0.78)
			arch.mesh = arch_mesh
			arch.position = Vector3(wx * (half_w + 0.005), 0.5, wz)
			arch.material_override = dark
			_visual_root.add_child(arch)

	# --- Dettagli per personalità ---
	match personality:
		"turista":
			var rack := MeshInstance3D.new()
			var rack_mesh := BoxMesh.new()
			rack_mesh.size = Vector3(cabin_size.x * 0.9, 0.04, cabin_size.z * 0.8)
			rack.mesh = rack_mesh
			rack.position = Vector3(0, body_top + cabin_size.y + 0.07, cabin_z)
			rack.material_override = dark
			_visual_root.add_child(rack)
			var lug_colors := [Color(0.8, 0.3, 0.3), Color(0.3, 0.5, 0.8)]
			for i in range(2):
				var lug := MeshInstance3D.new()
				var lug_mesh := BoxMesh.new()
				lug_mesh.size = Vector3(0.75, 0.26, 0.5)
				lug.mesh = lug_mesh
				lug.position = Vector3(0, body_top + cabin_size.y + 0.22, cabin_z + (i - 0.5) * 0.58)
				lug.rotation.y = randf_range(-0.1, 0.1)
				lug.material_override = Tex.flat(lug_colors[i], 0.8)
				_visual_root.add_child(lug)
		"tirchio":
			paint.albedo_color = paint.albedo_color.darkened(0.18)
			paint.metallic = 0.25
			paint.roughness = 0.75
			var rust_mat := Tex.flat(Color(0.45, 0.26, 0.13), 1.0)
			for i in range(4):
				var rust := MeshInstance3D.new()
				var rust_mesh := BoxMesh.new()
				rust_mesh.size = Vector3(0.26, 0.2, 0.3)
				rust.mesh = rust_mesh
				rust.position = Vector3(
					(half_w + 0.01) * (1.0 if i % 2 == 0 else -1.0),
					0.32 + randf_range(0.05, body_size.y * 0.7),
					randf_range(-half_len * 0.7, half_len * 0.7))
				rust.material_override = rust_mat
				_visual_root.add_child(rust)
		"fretta":
			var spoiler := MeshInstance3D.new()
			var spoiler_mesh := BoxMesh.new()
			spoiler_mesh.size = Vector3(body_size.x * 0.86, 0.05, 0.28)
			spoiler.mesh = spoiler_mesh
			spoiler.position = Vector3(0, body_top + 0.3, half_len - 0.3)
			spoiler.material_override = dark
			_visual_root.add_child(spoiler)
			for sx in [-1.0, 1.0]:
				var strut := MeshInstance3D.new()
				var strut_mesh := BoxMesh.new()
				strut_mesh.size = Vector3(0.05, 0.26, 0.08)
				strut.mesh = strut_mesh
				strut.position = Vector3(sx * body_size.x * 0.34, body_top + 0.16, half_len - 0.3)
				strut.material_override = dark
				_visual_root.add_child(strut)
			# Striscia sportiva sul cofano
			var stripe := MeshInstance3D.new()
			var stripe_mesh := BoxMesh.new()
			stripe_mesh.size = Vector3(0.18, 0.02, body_size.z * 0.55)
			stripe.mesh = stripe_mesh
			stripe.position = Vector3(0, body_top + 0.01, -half_len * 0.3)
			stripe.material_override = Tex.flat(Color(0.9, 0.9, 0.9), 0.4)
			_visual_root.add_child(stripe)

	# --- Dettagli per tipo ---
	if car_type == "lusso":
		for sx in [-1.0, 1.0]:
			var strip := MeshInstance3D.new()
			var strip_mesh := BoxMesh.new()
			strip_mesh.size = Vector3(0.03, 0.05, body_size.z * 0.8)
			strip.mesh = strip_mesh
			strip.position = Vector3(sx * half_w, 0.28 + body_size.y * 0.45, 0)
			strip.material_override = chrome
			_visual_root.add_child(strip)

	# Lo stemma non è più solo delle auto di lusso: ce l'ha anche una
	# berlina su tre, quindi si costruisce guardando has_emblem.
	if has_emblem:
		_build_emblem(body_top, half_len)



## Un colore dalla tavolozza del tipo, con un filo di variazione: due
## utilitarie bianche non devono essere bianche esattamente uguali.
func _random_paint() -> Color:
	# **'O cliente fisso tene sempe 'o stesso culore.** È l'unica cosa che
	# lo fa riconoscere da lontano, prima ancora di leggere il nome: la
	# giardinetta grigia di Gennaro, la Mercedes rossa scura del dottore.
	# Un colore a sorte gliela toglierebbe.
	if cliente_id != "":
		return colore
	var list: Array = PAINTS.get(car_type, PAINTS["berlina"])
	var base: Color = list[randi() % list.size()]
	return Color(
		clampf(base.r + randf_range(-0.04, 0.04), 0.0, 1.0),
		clampf(base.g + randf_range(-0.04, 0.04), 0.0, 1.0),
		clampf(base.b + randf_range(-0.04, 0.04), 0.0, 1.0))


## Ombra di contatto: una macchia scura sotto la scocca. Senza, l'auto
## sembra galleggiare sull'asfalto.
func _build_contact_shadow(body_size: Vector3) -> void:
	var shadow := MeshInstance3D.new()
	var shadow_mesh := PlaneMesh.new()
	shadow_mesh.size = Vector2(body_size.x * 1.15, body_size.z * 1.05)
	shadow.mesh = shadow_mesh
	shadow.position = Vector3(0, 0.03, 0)
	var shadow_mat := StandardMaterial3D.new()
	shadow_mat.albedo_color = Color(0, 0, 0, 0.38)
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow.material_override = shadow_mat
	_visual_root.add_child(shadow)


## Lo stemma sul cofano: la forma dipende dal "marchio".
## Lo stemma sul cofano: la forma dipende dal "marchio".
##
## Prima era alto 20 cm, appoggiato piatto sulla lamiera e immobile: su
## un'auto nera, a cinque metri, non lo vedeva nessuno. Adesso è il doppio,
## sta sospeso sopra il cofano, gira su sé stesso, ondeggia e ha sotto un
## anello luminoso che lo stacca da qualunque colore di carrozzeria.
func _build_emblem(body_top: float, half_len: float) -> void:
	_emblem_root = Node3D.new()
	_emblem_base_y = body_top + 0.32
	_emblem_root.position = Vector3(0, _emblem_base_y, -half_len + 0.5)
	_visual_root.add_child(_emblem_root)

	# Le tre forme: prima erano un prisma, un cilindro e una sfera, cioè
	# tre solidi qualunque. Adesso ognuna è una silhouette costruita a
	# pezzi, e si capisce che marchio hai svitato.
	_emblem_node = Node3D.new()
	match emblem_info["name"]:
		"Cavallino Sfrenato":
			_build_cavallino(_emblem_node)
		"Tridente d'Argento":
			_build_tridente(_emblem_node)
		_:
			_build_stella(_emblem_node)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = emblem_info["color"]
	mat.metallic = 1.0
	mat.roughness = 0.12
	mat.emission_enabled = true
	mat.emission = emblem_info["color"]
	# Brilla parecchio: è un collezionabile, deve chiamarti da lontano.
	mat.emission_energy_multiplier = 1.15
	for piece in _emblem_node.get_children():
		if piece is MeshInstance3D:
			piece.material_override = mat
	# Scudetto scuro dietro: stacca la silhouette dal cielo e dal cofano.
	var crest := MeshInstance3D.new()
	var crest_mesh := PrismMesh.new()
	crest_mesh.size = Vector3(0.34, 0.46, 0.03)
	crest_mesh.left_to_right = 0.5
	crest.mesh = crest_mesh
	crest.rotation.x = PI # punta in basso, come uno scudo
	crest.position = Vector3(0, 0.02, 0.035)
	var crest_mat := Tex.flat(Color(0.07, 0.07, 0.09), 0.35, 0.6)
	crest.material_override = crest_mat
	_emblem_node.add_child(crest)
	_emblem_root.add_child(_emblem_node)

	# Anello luminoso sotto: è quello che lo rende visibile anche su una
	# carrozzeria nera, dove il metallo lucido sparisce.
	var halo := MeshInstance3D.new()
	var halo_mesh := TorusMesh.new()
	halo_mesh.inner_radius = 0.2
	halo_mesh.outer_radius = 0.26
	halo_mesh.rings = 16
	halo_mesh.ring_segments = 8
	halo.mesh = halo_mesh
	halo.position = Vector3(0, -0.2, 0)
	var halo_mat := StandardMaterial3D.new()
	halo_mat.albedo_color = Color(1.0, 0.9, 0.35, 0.85)
	halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo_mat.emission_enabled = true
	halo_mat.emission = Color(1.0, 0.85, 0.3)
	halo_mat.emission_energy_multiplier = 2.0
	halo.material_override = halo_mat
	_emblem_root.add_child(halo)


## Mattoncino di comodo per comporre le silhouette degli stemmi.
func _emblem_bit(parent: Node3D, size: Vector3, pos: Vector3,
		rot_z: float = 0.0) -> void:
	var bit := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	bit.mesh = mesh
	bit.position = pos
	bit.rotation.z = rot_z
	parent.add_child(bit)


## Cavallino rampante: corpo, collo teso, testa, criniera, due zampe alzate
## davanti e la coda.
func _build_cavallino(root: Node3D) -> void:
	_emblem_bit(root, Vector3(0.1, 0.15, 0.05), Vector3(0.0, -0.02, 0.0))       # corpo
	_emblem_bit(root, Vector3(0.06, 0.14, 0.05), Vector3(0.035, 0.11, 0.0), deg_to_rad(-18)) # collo
	_emblem_bit(root, Vector3(0.09, 0.05, 0.05), Vector3(0.075, 0.185, 0.0))    # testa
	_emblem_bit(root, Vector3(0.04, 0.11, 0.04), Vector3(-0.01, 0.15, 0.0), deg_to_rad(22))  # criniera
	_emblem_bit(root, Vector3(0.035, 0.11, 0.04), Vector3(0.075, 0.03, 0.02), deg_to_rad(38))  # zampa anteriore alta
	_emblem_bit(root, Vector3(0.035, 0.1, 0.04), Vector3(0.06, -0.03, -0.02), deg_to_rad(62)) # seconda zampa
	_emblem_bit(root, Vector3(0.035, 0.12, 0.04), Vector3(-0.055, -0.05, 0.0), deg_to_rad(-26)) # zampa posteriore
	_emblem_bit(root, Vector3(0.05, 0.13, 0.04), Vector3(-0.065, 0.05, 0.0), deg_to_rad(34))  # coda


## Tridente: asta, traversa e tre punte.
func _build_tridente(root: Node3D) -> void:
	_emblem_bit(root, Vector3(0.035, 0.3, 0.035), Vector3(0, -0.06, 0))   # asta
	_emblem_bit(root, Vector3(0.24, 0.035, 0.035), Vector3(0, 0.07, 0))   # traversa
	for dx in [-0.1, 0.0, 0.1]:
		_emblem_bit(root, Vector3(0.032, 0.15, 0.032), Vector3(dx, 0.15, 0))
		var tip := MeshInstance3D.new()
		var tip_mesh := PrismMesh.new()
		tip_mesh.size = Vector3(0.055, 0.07, 0.035)
		tip.mesh = tip_mesh
		tip.position = Vector3(dx, 0.26, 0)
		root.add_child(tip)


## Stella a quattro punte: due losanghe incrociate, come i marchi tedeschi.
func _build_stella(root: Node3D) -> void:
	for angle in [0.0, PI / 2.0]:
		var ray := MeshInstance3D.new()
		var ray_mesh := PrismMesh.new()
		ray_mesh.size = Vector3(0.1, 0.19, 0.045)
		ray.mesh = ray_mesh
		ray.position = Vector3(0, 0.095, 0)
		var pivot := Node3D.new()
		pivot.rotation.z = angle
		pivot.add_child(ray)
		root.add_child(pivot)

		var ray2 := MeshInstance3D.new()
		ray2.mesh = ray_mesh
		ray2.position = Vector3(0, -0.095, 0)
		ray2.rotation.z = PI
		var pivot2 := Node3D.new()
		pivot2.rotation.z = angle
		pivot2.add_child(ray2)
		root.add_child(pivot2)


## Gira e ondeggia: il movimento è quello che ti fa girare la testa, molto
## più della lucentezza.
func _animate_emblem(delta: float) -> void:
	if _emblem_root == null or not is_instance_valid(_emblem_root):
		return
	_emblem_spin += delta
	_emblem_root.rotation.y = _emblem_spin * 1.7
	_emblem_root.position.y = _emblem_base_y + sin(_emblem_spin * 2.4) * 0.06


func _build_collision() -> void:
	# Hitbox unica e alta per tutti i tipi: garantisce che il raggio di
	# interazione (altezza occhi) becchi sempre l'auto.
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.8, 2.2, 4.0)
	shape.position = Vector3(0, 1.1, 0)
	shape.shape = box
	add_child(shape)


## Le ruote rotolano.
##
## L'angolo si ricava dallo spazio percorso diviso il raggio: e' il
## rotolamento senza slittamento, e in pratica vuol dire che una ruota da
## 31 cm fa un giro ogni due metri scarsi. Il segno viene dal prodotto
## scalare fra lo spostamento e il muso, cosi' in retromarcia girano
## all'indietro come devono.
##
## L'asse e' la X locale dell'auto, e il perno la applica alla posa di
## riposo della ruota (`Basis(RIGHT, ang) * riposo`), che e' l'unico modo
## di farlo funzionare sia sui cilindri che ci mettiamo noi — girati di
## novanta gradi — sia sui pezzi ritagliati da un modello, che hanno una
## posa loro.
func _gira_ruote(delta: float) -> void:
	if _ruote.is_empty() or delta <= 0.0:
		return
	var v: Vector3 = velocity
	var avanti: Vector3 = -global_transform.basis.z
	var spazio: float = v.dot(avanti) * delta
	if absf(spazio) < 0.0002:
		return
	_giro_ruote += spazio
	for r in _ruote:
		var perno: Node3D = r["perno"]
		if not is_instance_valid(perno):
			continue
		# `Basis(RIGHT, ang) * riposo`, non `rotation = ...`: le ruote
		# ritagliate da un modello hanno una posa di riposo loro, e
		# scriverci sopra un Eulero la cancellerebbe.
		perno.basis = Basis(Vector3.RIGHT,
			_giro_ruote / float(r["raggio"])) * (r["riposo"] as Basis)


func _physics_process(delta: float) -> void:
	_time_alive += delta
	_guagliuno_arriva = maxf(0.0, _guagliuno_arriva - delta)
	_gira_ruote(delta)
	_check_run_over_player(delta)
	if has_emblem:
		_animate_emblem(delta)
	match state:
		State.ARRIVING:
			var meta_in: Vector3 = _prossima_tappa(_via_in, waiting_point)
			_guida_verso(meta_in, DRIVE_SPEED, delta)
			_face_toward(meta_in)
			if global_position.distance_to(waiting_point) < 0.8 \
					and _tappa > _via_in.size():
				state = State.WAITING
				# Arrivata: due colpi di clacson per chiamarti. Solo se stai
				# in piazza: il clacson è un richiamo, e un richiamo che ti
				# arriva mentre sei a tre quartieri di distanza è solo
				# rumore che ti fa sentire in colpa.
				if GameManager.in_servizio:
					SoundManager.play("horn_arrivo", -3.0,
						randf_range(0.95, 1.06))
				if _bubble:
					_bubble.say("Oh guagliò!", 1.4)
		State.WAITING:
			# Se il parcheggiatore non è in piazza, il cliente aspetta e
			# basta: non perde la pazienza e non strombazza. Perdere un
			# cliente perché eri a comprare le sigarette dall'altra parte
			# della città sarebbe una punizione per aver esplorato, e
			# posteggiare è un'attività che si fa DENTRO la piazza tua.
			if _pazienza_conta():
				_patience_time -= delta
				# Cliente spazientito: comincia a suonare il clacson.
				if _patience_time < 5.0:
					_honk_cd -= delta
					if _honk_cd <= 0.0:
						_honk_cd = randf_range(2.4, 3.6)
						SoundManager.play("horn_impaziente", -5.0,
							randf_range(0.92, 1.08))
						if _bubble:
							_bubble.say("PEEEE!", 0.9)
				if _patience_time <= 0.0:
					_give_up()
		State.DIRECTING:
			if _guagliuno_zona != "":
				_guida_guagliuno(delta)
			else:
				_process_directing(delta)
		State.PARKED:
			_check_multa(delta)
			_aspetta_ô_padrone(delta)
		State.RUBATA:
			_guida_player(delta)
		State.LEAVING:
			var meta_out: Vector3 = _prossima_tappa(_via_out, exit_point)
			_guida_verso(meta_out, DRIVE_SPEED, delta)
			_face_toward(meta_out)
			if global_position.distance_to(meta_out) < 0.8 \
					and _tappa > _via_out.size():
				queue_free()


## Il punto verso cui puntare adesso: la tappa corrente del percorso, e
## quando il percorso e' finito la meta vera.
func _prossima_tappa(via: Array, meta: Vector3) -> Vector3:
	while _tappa <= via.size():
		var p: Vector3 = via[_tappa - 1]
		p.y = global_position.y
		if global_position.distance_to(p) > 1.0:
			return p
		_tappa += 1
		_fermo_da = 0.0
	return meta


## Guida verso un punto RISPETTANDO le collisioni.
##
## Prima era `global_position.move_toward(...)`, cioe' si scriveva la
## posizione a mano: nessun muro, nessuna auto, niente. Passava attraverso
## tutto. Adesso e' `move_and_slide()` come nella fase di regia, che e'
## sempre stata l'unica parte del ciclo dell'auto a collidere davvero.
func _guida_verso(target: Vector3, speed: float, delta: float) -> void:
	var dir: Vector3 = target - global_position
	dir.y = 0.0
	var dist := dir.length()
	if dist > 0.01:
		dir /= dist
	# Rallenta arrivando, cosi' non sbatte sul punto di coda.
	var v: float = minf(speed, maxf(0.7, dist * 1.6))
	velocity.x = dir.x * v
	velocity.z = dir.z * v
	# Niente gravita': l'auto sta sempre appoggiata a terra e la fase di
	# regia non l'ha mai applicata. Applicandola qui il corpo non risultava
	# mai `is_on_floor()` (il fondo della scatola tocca il pavimento
	# esattamente, non lo compenetra), la velocita' verticale cresceva a ogni
	# frame, e dopo pochi secondi lo scivolamento contro il terreno si
	# mangiava tutto il movimento orizzontale: l'auto si piantava davanti al
	# varco e si arrendeva.
	velocity.y = 0.0
	move_and_slide()

	# Piano B: se resta incastrata, si salta alla tappa dopo; se e'
	# incastrata da troppo, si arrende e se ne va. Meglio un cliente perso
	# che una macchina ferma di traverso sul varco per tutta la partita.
	if global_position.distance_to(_ultima_pos) < 0.04:
		_fermo_da += delta
		if _fermo_da > 2.5:
			_fermo_da = 0.0
			_tappa += 1
			if _tappa > maxi(_via_in.size(), _via_out.size()) + 2:
				if state == State.ARRIVING and _nisciuno_guarda():
					# **Chi nun 'o vede, nun 'o sape** (0.61). Un'auto
					# incastrata in una piazza dove il giocatore non c'è
					# non è un problema da far vedere: è un cliente perso
					# per niente. La si mette in coda dov'è.
					var w: Vector3 = waiting_point
					w.y = global_position.y
					global_position = w
					velocity = Vector3.ZERO
				elif state == State.ARRIVING:
					_give_up()
				else:
					queue_free()
	else:
		_fermo_da = 0.0
	_ultima_pos = global_position


## Vero se il giocatore sta a più di quaranta metri.
func _nisciuno_guarda() -> bool:
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null or not (pl is Node3D):
		return true
	return global_position.distance_to((pl as Node3D).global_position) > 40.0


func _face_toward(target: Vector3) -> void:
	var dir: Vector3 = target - global_position
	dir.y = 0.0
	if dir.length() > 0.05:
		# forward(θ) = (−sinθ, 0, −cosθ), verificato empiricamente:
		# per guardare verso dir serve θ = atan2(−dir.x, −dir.z).
		rotation.y = atan2(-dir.x, -dir.z)


## **Chi aspetta, aspetta a chi?** (0.61)
##
## Prima bastava `in_servizio`, che è vero in **qualunque** piazza tua: stavi
## allo stadio, e al mercato — dove il guaglione camminava verso la
## macchina — il cliente perdeva la pazienza per colpa tua e se ne andava
## un passo prima che quello arrivasse. Adesso l'orologio corre solo se il
## parcheggiatore sta **in questa piazza**, e mai se il guaglione ha già
## detto «arrivo».
func _pazienza_conta() -> bool:
	if _guagliuno_arriva > 0.0:
		return false
	if not GameManager.in_servizio:
		return false
	if GameManager.zona_corrente != "" and GameManager.zona_corrente != zona_id:
		return false
	return true


## Il guaglione l'ha vista e sta venendo: per qualche secondo il cliente
## non si spazientisce. Lo rinnova lui a ogni passo.
var _guagliuno_arriva: float = 0.0


func guagliuno_arriva() -> void:
	_guagliuno_arriva = 1.5


func _give_up() -> void:
	GameManager.register_client_lost()
	_release_spot()
	state = State.LEAVING


## Libera il posto prenotato, se ne abbiamo uno. Va chiamato SEMPRE quando
## l'auto smette di puntare a quel posto: senza questo i posti restano
## occupati per sempre e dopo qualche minuto non se ne può più parcheggiare
## nessuna (il bug per cui "premo E e non succede niente").
## **Quanto lontano può stare un posto per contare come "posto di questa
## piazza".** Le piazze distano fra loro almeno ottanta metri; sessanta
## bastano a coprire la più grande (il piazzale dello stadio) e non
## arrivano mai a quella accanto. Senza questo limite, un'auto ferma al
## mercato con tutti i posti occupati veniva mandata a parcheggiare nella
## piazza iniziale.
const RAGGIO_POSTI: float = 60.0


func _any_free_spot() -> bool:
	for spot in get_tree().get_nodes_in_group("parking_spots"):
		if spot.is_free \
				and global_position.distance_to(spot.global_position) <= RAGGIO_POSTI:
			return true
	return false


func _release_spot() -> void:
	if assigned_spot and is_instance_valid(assigned_spot):
		if assigned_spot.occupying_car == self:
			assigned_spot.free_spot()
	assigned_spot = null


## Rete di sicurezza: qualunque sia il motivo per cui questa auto sparisce
## (queue_free, cambio scena, fine turno), il posto torna libero.
func _exit_tree() -> void:
	_release_spot()
	# E il cliente fisso torna disponibile: se non lo liberassi qui, dopo
	# sei macchine la piazza resterebbe senza nessuno che tiene un nome.
	if cliente_id != "":
		GameManager.cliente_se_ne_va(cliente_id)
	# **'O pannello d''o scasso nun se ne pò restà appiso.** Sta sulla
	# radice, non sotto a questo nodo: se la macchina sparisce mentre uno ci
	# sta lavorando dentro (la giornata finisce, l'auto se ne va), il
	# pannello resterebbe a schermo con il player congelato e nessuno che
	# possa chiuderlo. Chi apre una porta deve possedere anche il modo di
	# richiuderla — la stessa regola della cella della 0.56.
	if _scasso != null and is_instance_valid(_scasso):
		if _scasso.has_method("chiudi"):
			_scasso.chiudi(false)
		_scasso.queue_free()
		_scasso = null


## Fine sosta: l'auto se ne va. Se il cliente non ha mai pagato, il mancato
## incasso è già stato contato dall'autista quando è uscito di scena.
func _depart() -> void:
	_tappa = 1
	_fermo_da = 0.0
	_release_spot()
	collision_mask = 0
	state = State.LEAVING


# ---------------------------------------------------------------------------
# Danni visibili progressivi
# ---------------------------------------------------------------------------

## Applica un livello di danno con effetti visivi cumulativi:
## 1 = ammaccature e vernice rovinata, 2 = vetri incrinati, 3 = fumo dal cofano.
func apply_damage() -> void:
	if damage_level >= MAX_DAMAGE:
		return
	damage_level += 1

	if _custom_model != null:
		# Modello esterno: i colori stanno nelle superfici della mesh, non
		# in un material_override, quindi si passa di lì.
		Models.darken(_custom_model, 0.15)
	for child in _visual_root.get_children():
		if child is MeshInstance3D and child.material_override is StandardMaterial3D:
			# Duplica prima di scurire: alcuni materiali sono condivisi
			# (cache delle texture), modificarli in place annerirebbe
			# mezza piazza insieme all'auto.
			var mat: StandardMaterial3D = child.material_override.duplicate()
			mat.albedo_color = mat.albedo_color.darkened(0.15)
			child.material_override = mat

	var info: Dictionary = CAR_TYPES[car_type]
	var body_size: Vector3 = info["body_size"]
	if _model_size != Vector3.ZERO:
		body_size = Vector3(_model_size.x, _model_size.y - 0.28, _model_size.z)
	var dent_mat := StandardMaterial3D.new()
	dent_mat.albedo_color = Color(0.08, 0.08, 0.08)
	dent_mat.roughness = 1.0
	for i in range(2):
		var dent := MeshInstance3D.new()
		var dent_mesh := BoxMesh.new()
		dent_mesh.size = Vector3(randf_range(0.25, 0.4), randf_range(0.15, 0.3), randf_range(0.2, 0.35))
		dent.mesh = dent_mesh
		dent.position = Vector3(
			randf_range(-body_size.x / 2.0, body_size.x / 2.0),
			0.28 + randf_range(0.15, body_size.y),
			randf_range(-body_size.z / 2.0 * 0.85, body_size.z / 2.0 * 0.85))
		dent.material_override = dent_mat
		_visual_root.add_child(dent)

	if damage_level == 2:
		# Vetri incrinati: crepe bianche sottili sul parabrezza.
		var crack_mat := StandardMaterial3D.new()
		crack_mat.albedo_color = Color(0.95, 0.95, 0.95)
		var cabin_size: Vector3 = info["cabin_size"]
		var cabin_y: float = 0.28 + body_size.y + cabin_size.y / 2.0
		var cabin_front_z: float = info["cabin_z"] - cabin_size.z / 2.0
		for angle in [0.5, -0.6, 1.2]:
			var crack := MeshInstance3D.new()
			var crack_mesh := BoxMesh.new()
			crack_mesh.size = Vector3(0.35, 0.015, 0.015)
			crack.mesh = crack_mesh
			crack.position = Vector3(randf_range(-0.3, 0.3), cabin_y, cabin_front_z - 0.01)
			crack.rotation.z = angle
			crack.material_override = crack_mat
			_visual_root.add_child(crack)

	if damage_level >= MAX_DAMAGE and _smoke_particles == null:
		# Fumo VERO dal cofano: l'auto è ufficialmente "sfasciata".
		var half_len: float = body_size.z / 2.0
		_smoke_particles = CPUParticles3D.new()
		_smoke_particles.amount = 16
		_smoke_particles.lifetime = 1.6
		_smoke_particles.direction = Vector3(0, 1, 0)
		_smoke_particles.spread = 12.0
		_smoke_particles.initial_velocity_min = 0.5
		_smoke_particles.initial_velocity_max = 0.9
		_smoke_particles.gravity = Vector3(0, 0.4, 0)
		_smoke_particles.scale_amount_min = 0.15
		_smoke_particles.scale_amount_max = 0.4
		var puff_mesh := SphereMesh.new()
		puff_mesh.radius = 0.5
		puff_mesh.height = 1.0
		var smoke_mat := StandardMaterial3D.new()
		smoke_mat.albedo_color = Color(0.4, 0.4, 0.42, 0.4)
		smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		puff_mesh.material = smoke_mat
		_smoke_particles.mesh = puff_mesh
		_smoke_particles.position = Vector3(0, 0.28 + body_size.y + 0.2, -half_len + 0.5)
		add_child(_smoke_particles)
		_smoke_particles.emitting = true


# ---------------------------------------------------------------------------
# Regia a gesti (fase 2)
# ---------------------------------------------------------------------------

## Il parcheggiatore che si mette davanti alle ruote. Il controllo sta
## qui e non nel player perché è l'auto quella che si muove: dal lato del
## player una macchina che gli arriva addosso mentre lui è fermo non
## produce quasi mai una collisione di slide.
func _check_run_over_player(delta: float) -> void:
	if _run_over_cd > 0.0:
		_run_over_cd -= delta
		return
	var speed: float = absf(current_speed())
	if speed < RUN_OVER_MIN_SPEED:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return
	# Mentre stai dirigendo QUESTA auto sei tu a comandarla: se te la tiri
	# addosso è giusto che faccia male, ma con un raggio più stretto,
	# altrimenti ti falcia mentre le stai semplicemente accanto.
	var radius: float = RUN_OVER_RADIUS
	if player.get("directing_car") == self:
		radius *= 0.7

	var d: Vector3 = player.global_position - global_position
	d.y = 0.0
	# L'ingombro non è un cerchio: si guarda quanto è vicino al muso e ai
	# fianchi nello spazio locale dell'auto.
	var local := global_transform.basis.inverse() * d
	var half_len: float = (_model_size.z if _model_size != Vector3.ZERO
		else CAR_TYPES[car_type]["body_size"].z) * 0.5
	var half_w: float = (_model_size.x if _model_size != Vector3.ZERO
		else CAR_TYPES[car_type]["body_size"].x) * 0.5
	if absf(local.z) > half_len + radius or absf(local.x) > half_w + radius * 0.5:
		return

	# **Te sbatte sulo si t'acchiappa 'e muso** (0.56).
	#
	# Il capo: *"le auto ti buttano a terra solo se ti colpiscono bene di
	# faccia, non se le tocchi a malapena di lato o da dietro"*.
	#
	# Il controllo di prima guardava solo **se eri dentro all'ingombro**,
	# e da lì stendeva. Ma l'ingombro è tutta la macchina: passarle
	# accanto mentre manovra, o sfiorarle il paraurti posteriore, ti
	# buttava a terra come una Panda a cinquanta all'ora. Ed è la cosa che
	# più di ogni altra faceva sembrare le auto ostili invece che presenti
	# — in una piazza dove il tuo mestiere è **stare in mezzo alle
	# macchine**.
	#
	# Adesso si guardano due cose, e sono tutte e due geometria vera:
	#
	#   * **dove stai rispetto alla macchina**: davanti al muso (`local.z`
	#     negativo, verso −Z, che è il davanti) oppure di fianco;
	#   * **dove sta andando la macchina**: avanti o in retromarcia.
	#
	# Se ti prende col muso mentre va avanti — o col culo mentre fa
	# retromarcia — è un investimento, e vai a terra. Se le stai di lato o
	# te la tira dietro mentre va avanti, è una **spallata**: fa un po' di
	# male, la macchina strilla, e resti in piedi.
	var avanza: bool = current_speed() >= 0.0
	# Il muso sta a −Z: davanti alla macchina vuol dire `local.z` negativo.
	var davanti_ô_muso: bool = local.z < -half_len * 0.45
	var arreto: bool = local.z > half_len * 0.45
	var ncuollo: bool = (davanti_ô_muso and avanza) or (arreto and not avanza)
	# E comunque non di striscio: se sei fuori dalla larghezza della
	# carrozzeria, è il retrovisore che ti ha toccato.
	if absf(local.x) > half_w * 0.9:
		ncuollo = false

	_run_over_cd = RUN_OVER_COOLDOWN
	if not ncuollo:
		# 'Na spallata: nun se cade.
		SoundManager.play("bump", -8.0, 1.05)
		GameManager.screen_shake.emit(0.28)
		GameManager.damage_player(1.0 + speed * 0.4,
			"'Na machina t'ha strusciato", global_position)
		if _bubble:
			_bubble.say("Ohè! Statte attiento!", 1.4)
		return

	SoundManager.play("bump", -1.0, 0.75)
	GameManager.screen_shake.emit(0.8)
	if player.has_method("knock_down"):
		var push: Vector3 = d.normalized() if d.length() > 0.01 else Vector3(0, 0, 1)
		player.knock_down(push)
	# Un'auto in manovra va a passo d'uomo: la botta e' una spallata, non un
	# investimento. Da 9+5·v a 3+1,6·v.
	GameManager.damage_player(3.0 + speed * 1.6, "T'ha miso sotto na machina",
		global_position)
	if _bubble:
		_bubble.say("MA CHE FAI?! LEVATE!", 1.6)


## Quanto va, in m/s. Serve al player per sapere se l'auto che l'ha
## toccato lo stava davvero mettendo sotto o era ferma.
func current_speed() -> float:
	match state:
		State.DIRECTING:
			return _drive_speed
		State.ARRIVING, State.LEAVING:
			return DRIVE_SPEED
		_:
			return 0.0


func is_being_directed() -> bool:
	return state == State.DIRECTING


func _start_parking() -> void:
	var best_spot = null
	var best_dist := RAGGIO_POSTI
	for spot in get_tree().get_nodes_in_group("parking_spots"):
		if spot.is_free:
			var d: float = global_position.distance_to(spot.global_position)
			if d < best_dist:
				best_dist = d
				best_spot = spot
	if best_spot == null:
		GameManager.directing_gesture.emit("Nun ce sta posto, guagliò!", true)
		return
	_release_spot() # se ne avevamo già uno prenotato, mollalo prima
	best_spot.reserve(self)
	assigned_spot = best_spot
	_drive_speed = 0.0
	_bump_count = 0
	_bump_cooldown = 0.0
	_ai_throttle = 0.0
	_ai_brake = 0.0
	_ai_steer = 0.0
	_assist_active = false
	_reply_timer = 0.0
	_caution_reply_cd = 0.0
	_directing_time_left = DIRECTING_TIME_LIMIT
	if personality == "fretta":
		_directing_time_left = 22.0 # ha fretta pure di essere parcheggiato
	# Sempre ricalcolato dal valore BASE: la stessa auto può essere diretta
	# più volte (E → molli → E), e moltiplicando ogni volta il tempo di
	# reazione finirebbe a zero, con lo sterzo impazzito.
	_reaction_time = _base_reaction_time
	if GameManager.has_upgrade("fischietto"):
		_reaction_time *= 0.65 # il fischietto "professionale" li sveglia
		_directing_time_left += 10.0
	_reaction_time = maxf(_reaction_time, 0.05)
	state = State.DIRECTING
	GameManager.directing_started.emit()
	if personality == "turista":
		_say("Scusi!! Left?? Right?? Io capire al contrario!!")


func release_control() -> void:
	# Se dentro ci sta 'o guaglione, la macchina non e' del giocatore e non
	# gliela puo' mollare: `interrompi_tutto()` la chiama a ogni fermata del
	# vigile, e senza questa riga bastava un controllo documenti dall'altra
	# parte della piazza per lasciare la manovra a meta'.
	if _guagliuno_zona != "":
		return
	if state == State.DIRECTING and not _assist_active:
		state = State.WAITING
		_drive_speed = 0.0
		velocity = Vector3.ZERO
		_patience_time = randf_range(10.0, 15.0)
		_release_spot() # il posto torna disponibile per un'altra auto
		GameManager.directing_released.emit()


func _process_directing(delta: float) -> void:
	if _assist_active:
		_process_assist(delta)
		return

	_directing_time_left -= delta
	if _bump_cooldown > 0.0:
		_bump_cooldown -= delta
	if _caution_reply_cd > 0.0:
		_caution_reply_cd -= delta

	_emit_gesture_shouts()

	# F (o SPAZIO): "lascia stà, mettila ccà". L'auto si pianta dov'è, fuori
	# dalle strisce. È il modo veloce di liberarsi di un cliente — e il modo
	# veloce di farsi mettere una multa addosso.
	# Durante la regia il tasto F non serve ad altro (il vandalismo funziona
	# solo sulle auto già parcheggiate), quindi qui vale come "fermate ccà".
	if Input.is_action_just_pressed("park_here") \
			or Input.is_action_just_pressed("vandalize"):
		_try_park_abusive()
		return

	var raw_throttle := Input.get_action_strength("move_up")
	var raw_brake := Input.get_action_strength("move_down")
	var raw_steer := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	if personality == "turista":
		raw_steer = -raw_steer # il turista capisce i gesti al contrario!
	var react_rate: float = 1.0 / _reaction_time
	_ai_throttle = move_toward(_ai_throttle, raw_throttle, delta * react_rate)
	_ai_brake = move_toward(_ai_brake, raw_brake, delta * react_rate * 1.6)
	_ai_steer = move_toward(_ai_steer, raw_steer, delta * react_rate)

	if _reply_timer > 0.0:
		_reply_timer -= delta
		if _reply_timer <= 0.0:
			_say(DRIVER_REPLIES[randi() % DRIVER_REPLIES.size()])

	if _ai_brake > 0.05:
		_drive_speed = move_toward(_drive_speed, 0.0, DIRECTING_BRAKE * _ai_brake * delta)
	else:
		var max_speed: float = DIRECTING_MAX_SPEED * (1.2 if personality == "fretta" else 1.0)
		var target_speed: float = max_speed * _ai_throttle
		var rate: float = 3.6 if target_speed > _drive_speed else DIRECTING_FRICTION
		_drive_speed = move_toward(_drive_speed, target_speed, rate * delta)

	if _drive_speed > CAUTION_SPEED_CAP and _wall_ahead():
		_drive_speed = move_toward(_drive_speed, CAUTION_SPEED_CAP, DIRECTING_BRAKE * delta)
		if _caution_reply_cd <= 0.0:
			_caution_reply_cd = 3.0
			_say(DRIVER_CAUTION)
			SoundManager.play("honk", -8.0, 1.25)

	var wobble: float = sin(_time_alive * 3.1) * _wobble_amp * clamp(_drive_speed / DIRECTING_MAX_SPEED, 0.0, 1.0)
	var effective_steer: float = _ai_steer + wobble

	if absf(_drive_speed) > DIRECTING_MIN_SPEED_TO_TURN and absf(effective_steer) > 0.01:
		rotation.y -= effective_steer * DIRECTING_TURN_RATE * delta

	var forward: Vector3 = -global_transform.basis.z
	velocity = forward * _drive_speed
	move_and_slide()

	if _bump_cooldown <= 0.0 and _drive_speed > 0.3:
		var bumped: Object = _get_bump_collider()
		if bumped != null:
			_bump_count += 1
			_bump_cooldown = BUMP_COOLDOWN
			_drive_speed *= 0.3
			GameManager.directing_bump.emit(_bump_count)
			SoundManager.play("bump", -2.0)
			GameManager.screen_shake.emit(0.3)
			_spawn_sparks()
			if bumped is Node and bumped.is_in_group("cars"):
				# Incidente tra auto: si ammaccano ENTRAMBE, e quella colpita
				# protesta col clacson.
				apply_damage()
				bumped.apply_damage()
				bumped.honk_protest()
			elif _bump_count == 3:
				apply_damage() # a furia di sbattere sui muri, la carrozzeria si segna
			if _bump_count >= MAX_BUMPS_BEFORE_GIVEUP:
				_say(DRIVER_RAGE_BUMPS)
				SoundManager.play("fail")
				_abort_directing()
				return

	var progress := _evaluate_parking_progress()
	progress["time_left"] = _directing_time_left
	GameManager.directing_update.emit(progress)

	if progress["distance_ok"] and progress["align_ok"] and progress["speed_ok"]:
		_start_assist(progress)
		return

	if _directing_time_left <= 0.0:
		_say(DRIVER_RAGE_TIME)
		SoundManager.play("fail")
		_abort_directing()


func _emit_gesture_shouts() -> void:
	var shout := ""
	if Input.is_action_just_pressed("move_up"):
		shout = SHOUTS_GO[randi() % SHOUTS_GO.size()]
		SoundManager.play("rev", -10.0)
	elif Input.is_action_just_pressed("move_down"):
		shout = SHOUTS_STOP[randi() % SHOUTS_STOP.size()]
	elif Input.is_action_just_pressed("move_left"):
		shout = SHOUTS_LEFT[randi() % SHOUTS_LEFT.size()]
	elif Input.is_action_just_pressed("move_right"):
		shout = SHOUTS_RIGHT[randi() % SHOUTS_RIGHT.size()]
	if shout != "":
		GameManager.directing_gesture.emit(shout, false)
		SoundManager.play("pop", -6.0, randf_range(0.95, 1.25))
		if randf() < 0.3 and _reply_timer <= 0.0:
			_reply_timer = 0.5


## Scintille sul punto dell'urto (davanti al muso).
func _spawn_sparks() -> void:
	var sparks := CPUParticles3D.new()
	sparks.amount = 14
	sparks.one_shot = true
	sparks.lifetime = 0.4
	sparks.explosiveness = 1.0
	sparks.direction = Vector3(0, 1, 0)
	sparks.spread = 70.0
	sparks.initial_velocity_min = 2.0
	sparks.initial_velocity_max = 4.5
	sparks.gravity = Vector3(0, -9.0, 0)
	sparks.scale_amount_min = 0.04
	sparks.scale_amount_max = 0.09
	sparks.mesh = BoxMesh.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.7, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.6, 0.1)
	mat.emission_energy_multiplier = 2.0
	sparks.mesh.material = mat
	sparks.position = Vector3(0, 0.6, -2.0)
	add_child(sparks)
	sparks.emitting = true
	# Si smaltisce da solo: nessun timer con closure da tenere vivo.
	var killer := Timer.new()
	killer.wait_time = 1.2
	killer.one_shot = true
	killer.autostart = true
	killer.timeout.connect(sparks.queue_free)
	sparks.add_child(killer)


func _wall_ahead() -> bool:
	# L'autista frena da solo se vede un ostacolo davanti: muri, ma anche
	# altre auto e persone (mask 1|4). Esclude se stesso dal raggio.
	var space_state := get_world_3d().direct_space_state
	var forward: Vector3 = -global_transform.basis.z
	var from: Vector3 = global_position + Vector3(0, 0.6, 0) + forward * 2.1
	var to: Vector3 = from + forward * CAUTION_DISTANCE
	var query := PhysicsRayQueryParameters3D.create(from, to, 1 | 4)
	query.exclude = [get_rid()]
	return not space_state.intersect_ray(query).is_empty()


## Ritorna il corpo contro cui si è urtato in questo frame (normale
## orizzontale = muro/auto, non il pavimento), oppure null.
func _get_bump_collider() -> Object:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if absf(collision.get_normal().y) < 0.5:
			return collision.get_collider()
	return null


## Clacson di protesta (auto colpita da un'altra auto).
func honk_protest() -> void:
	SoundManager.play("honk", -4.0, randf_range(0.85, 1.1))
	if _bubble:
		_bubble.say("PEEEE!", 1.0)


func _start_assist(progress: Dictionary) -> void:
	_assist_active = true
	_assist_time = 0.0
	_assist_from_pos = global_position
	_assist_from_rot = rotation.y
	_assist_target_rot = roundf(rotation.y / PI) * PI
	_assist_align_ratio = progress["align_ratio"]
	_assist_dist_ratio = progress["distance_ratio"]
	_drive_speed = 0.0
	velocity = Vector3.ZERO
	_say(DRIVER_ASSIST)


func _process_assist(delta: float) -> void:
	_assist_time += delta
	var t: float = clamp(_assist_time / ASSIST_DURATION, 0.0, 1.0)
	var smooth: float = t * t * (3.0 - 2.0 * t)
	if assigned_spot and is_instance_valid(assigned_spot):
		var target: Vector3 = assigned_spot.global_position
		target.y = global_position.y
		global_position = _assist_from_pos.lerp(target, smooth)
	rotation.y = lerp_angle(_assist_from_rot, _assist_target_rot, smooth)
	if t >= 1.0:
		_finish_parking()


func _evaluate_parking_progress() -> Dictionary:
	if assigned_spot == null or not is_instance_valid(assigned_spot):
		return {"distance_ratio": 0.0, "align_ratio": 0.0, "distance_ok": false, "align_ok": false, "speed_ok": false}

	var dist: float = Vector2(global_position.x, global_position.z).distance_to(
		Vector2(assigned_spot.global_position.x, assigned_spot.global_position.z))
	var forward: Vector3 = -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var angle_to_z: float = rad_to_deg(forward.angle_to(Vector3(0, 0, 1)))
	var align_error: float = min(angle_to_z, 180.0 - angle_to_z)

	var distance_ratio: float = clamp(1.0 - dist / PARK_TRIGGER_DIST, 0.0, 1.0)
	var align_ratio: float = clamp(1.0 - align_error / PARK_TRIGGER_ALIGN_DEG, 0.0, 1.0)

	return {
		"distance_ratio": distance_ratio,
		"align_ratio": align_ratio,
		"distance_ok": dist <= PARK_TRIGGER_DIST,
		"align_ok": align_error <= PARK_TRIGGER_ALIGN_DEG,
		"speed_ok": absf(_drive_speed) <= PARK_TRIGGER_SPEED,
	}


## **'A machina aspetta 'o padrone suio, e nun chiamma a nisciuno.**
##
## Fino alla 0.54 questa funzione non esisteva: la macchina contava i
## secondi e, quando finivano, o se ne andava da sola o **faceva nascere
## un secondo autista** all'uscita della piazza per venire a lamentarsi.
## Da lì il giro infinito — il secondo autista finiva la scenata, la
## macchina rimetteva il contatore a mezzo secondo, il danno era ancora
## lì, e ne nasceva un terzo. Per sempre, e con un cliente perso contato
## a ogni giro.
##
## Adesso la macchina **non decide niente**: sta ferma finché il suo
## autista — quello sceso all'inizio, che è andato a fare le commissioni —
## non torna e non fa quello che deve. Chi manda via l'auto è sempre lui,
## da `l_autista_ha_fernuto()`.
##
## Resta una rete di sicurezza, e serve: se l'autista si impianta contro
## un muro, o viene steso e il corpo resta lì, la macchina non deve
## occupare il posto per il resto della partita.
const SENZA_PADRONE_MAX: float = 240.0

var _senza_padrone: float = 0.0

func _aspetta_ô_padrone(delta: float) -> void:
	if _driver != null and is_instance_valid(_driver):
		_senza_padrone = 0.0
		return
	# Nessun autista vivo: o non è mai nato, o è morto per strada.
	_senza_padrone += delta
	if _senza_padrone > SENZA_PADRONE_MAX:
		_depart()


## L'autista ha finito: è montato, è scappato, o la scenata è chiusa.
## **È l'unica porta d'uscita della sosta**, e non rimette contatori.
func l_autista_ha_fernuto() -> void:
	_multa_confronto = false
	_driver = null
	if state == State.PARKED:
		_depart()


## SPAZIO durante la regia: l'auto si ferma dov'è e amen. Serve solo che
## sia quasi ferma e che non sia incastrata in mezzo a un muro o addosso a
## un'altra auto — per il resto, "stai na favola".
func _try_park_abusive() -> void:
	if absf(_drive_speed) > 2.0:
		GameManager.directing_gesture.emit("FERMT' PRIMA! (S per frenare)", false)
		return
	if _wall_ahead() and absf(_drive_speed) > 0.2:
		_say(DRIVER_CAUTION)
		return

	parked_abusive = true
	_release_spot() # il posto regolare, se ce l'aveva, torna libero

	GameManager.directing_gesture.emit(
		SHOUTS_ABUSIVO[randi() % SHOUTS_ABUSIVO.size()], false)
	_say(DRIVER_DOUBT[randi() % DRIVER_DOUBT.size()])

	# Punteggio più basso di un parcheggio fatto bene: la mancia ne risente,
	# ma hai risparmiato mezza manovra.
	minigame_score = clamp(0.45 - _bump_count * 0.06, 0.15, 0.6)
	velocity = Vector3.ZERO
	_drive_speed = 0.0
	_assist_active = false
	state = State.PARKED
	# Resta parcheggiata abbastanza perché un vigile ci passi davanti, ma
	# non così a lungo da tenere occupato il posto per mezzo turno.
	_parked_time = randf_range(30.0, 42.0)
	_multa_cd = MULTA_CHECK_EVERY
	GameManager.directing_ended.emit(minigame_score, false)
	SoundManager.play("pop", -4.0, 0.8)
	_spawn_driver()


## Ogni tot secondi: se un vigile è vicino e ci vede, multa. La probabilità
## cresce se il vigile è proprio addosso all'auto.
## **'A multa nun è sicura: è quaranta ncopp'a cient'.**
##
## Prima il conto era solo sulla distanza: a tre metri dal vigile la
## probabilità era dell'85% **ogni tre secondi**. Che in pratica vuol dire
## certezza — un vigile che passa accanto a un'auto abusiva per dieci
## secondi la multa nel 99,99% dei casi. E una cosa che succede sempre non è
## un rischio, è una tassa: il giocatore smette di guardarla.
##
## Adesso la moneta si lancia **una volta sola per auto**, appena si
## posteggia abusiva: il quaranta per cento delle auto è multabile, il resto
## no, e non lo sarà mai per quanto ci giri intorno una pattuglia. La
## distanza continua a decidere **quando** arriva il foglietto, non **se**.
##
## Il risultato in mano al giocatore è quello che serve: il vigile che passa
## accanto alla macchina storta e tira dritto è una scena che adesso capita,
## e quando invece si ferma vuol dire qualcosa.
const MULTA_PROBABILITA: float = 0.40

func _check_multa(delta: float) -> void:
	if has_multa or not parked_abusive:
		return
	if not _multa_decisa:
		_multa_decisa = true
		# **E 'a jurnata ce mette 'o suio (0.52).** Col mercato i vigili
		# stanno in giro sul serio e le multe salgono del 45%; se piove o
		# c'e' 'a partita se ne stanno al bar e scendono a meta'.
		_multabile = randf() < MULTA_PROBABILITA * GameManager.multe_giornata()
	if not _multabile:
		return
	_multa_cd -= delta
	if _multa_cd > 0.0:
		return
	_multa_cd = MULTA_CHECK_EVERY

	var nearest := INF
	for vigile in get_tree().get_nodes_in_group("vigili"):
		if not is_instance_valid(vigile):
			continue
		nearest = minf(nearest, global_position.distance_to(vigile.global_position))
	if nearest > MULTA_SIGHT:
		return
	# Da lontano quasi niente, sotto i tre metri quasi sicura.
	var chance: float = clampf(1.0 - nearest / MULTA_SIGHT, 0.0, 1.0)
	chance = chance * chance * 0.85
	if randf() < chance:
		_give_multa()


## La multa: foglietto bianco sotto il tergicristallo, fischio, e un
## problema che ti torna indietro fra un minuto.
func _give_multa() -> void:
	if has_multa:
		return
	has_multa = true
	GameManager.register_multa()
	SoundManager.play("fischio_vigile", -8.0, 1.05)
	GameManager.event_started.emit("MULTA! L'auto abusiva se l'è beccata...")
	if _bubble:
		_bubble.say("MULTA!", 2.0)

	_multa_node = Node3D.new()
	var half_h: float = _model_size.y * 0.5 if _model_size != Vector3.ZERO \
		else CAR_TYPES[car_type]["body_size"].y + 0.55
	var half_len: float = _model_size.z * 0.5 if _model_size != Vector3.ZERO \
		else CAR_TYPES[car_type]["body_size"].z * 0.5
	_multa_node.position = Vector3(0.15, half_h + 0.28, -half_len * 0.28)
	_visual_root.add_child(_multa_node)

	var paper := MeshInstance3D.new()
	var paper_mesh := BoxMesh.new()
	paper_mesh.size = Vector3(0.2, 0.28, 0.012)
	paper.mesh = paper_mesh
	paper.rotation.x = deg_to_rad(-58)
	var paper_mat := Tex.flat(Color(0.96, 0.95, 0.9), 0.9)
	paper_mat.emission_enabled = true
	paper_mat.emission = Color(1.0, 1.0, 0.95)
	paper_mat.emission_energy_multiplier = 0.25
	paper.material_override = paper_mat
	_multa_node.add_child(paper)



# ===========================================================================
# 'O FURTO SU CUMMISSIONE — te 'a piglie e t''a puorte
# ===========================================================================
#
# **Perché questo furto e non un altro.** In bacheca c'è chi vuole una
# macchina precisa: un tipo, un colore. Tu quelle macchine le posteggi
# tutto il giorno. Non devi cercare niente, non devi forzare niente:
# **devi solo fare il lavoro tuo, e poi non restituire le chiavi.**
#
# È il furto più logico che potesse stare in questo gioco, ed è per questo
# che il capo l'ha chiesto proprio così: *"dopo che l'hai parcheggiata e il
# cliente è andato via, puoi rubarla e portarla in un garage"*.
#
# Le tre condizioni sono tutte e tre necessarie e si vedono tutte e tre:
# l'auto dev'essere **posteggiata** (non in coda), il padrone se ne dev'essere
# **andato**, e dev'essere **quella giusta**. Il prompt dice quale delle tre
# manca, se ne manca una.

## **Quanto va 'a machina rubata** — e perché adesso va il doppio.
##
## Alla 0.45 questi numeri erano metà: 8,5 m/s, cioè trenta all'ora. Erano
## giusti allora, perché il garage stava a venti metri e la guida era una
## manovra di parcheggio al contrario.
##
## Adesso il garage sta a **centoquarantotto metri** dall'altra parte della
## città, e il capo ha chiesto *«un sistema di guida semplice che permetta di
## spostarsi velocemente in città»*. A trenta all'ora quei
## centoquarantotto metri sono venti secondi di tasto avanti tenuto premuto:
## non è velocità, è una camminata seduti. A cinquanta con la sgasata a
## settanta sono otto secondi in cui devi davvero infilare due curve, ed è
## **più veloce che andarci a piedi** — che è tutto il senso della frase del
## capo: la macchina rubata non è solo merce, è il mezzo per attraversare la
## città.
##
## Il resto dei numeri serve a fare in modo che quella velocità si **guidi**
## invece di scivolare: il freno morde più dell'acceleratore (si inchioda
## meglio di come si parte, come tutte le macchine vere), e lo sterzo si
## chiude quando corri — a venti metri al secondo la stessa rotazione che ti
## fa girare l'angolo a passo d'uomo ti mette di traverso.
const RUBATA_VEL: float = 14.0
const RUBATA_VEL_SGASO: float = 19.5   # cu 'o Shift sotto
const RUBATA_RETRO: float = 5.0
const RUBATA_ACC: float = 9.5
const RUBATA_FRENO: float = 17.0
const RUBATA_STERZO: float = 1.95
## Quanto si chiude lo sterzo a velocità piena (moltiplicatore).
const RUBATA_STERZO_CHIUSO: float = 0.42
## 'O freno a mano (Ctrl): inchioda e lascia girare.
const RUBATA_MANELLA: float = 26.0
const RUBATA_MANELLA_STERZO: float = 1.45

## **'E botte se pavano.** Sbattere non è gratis e non è mortale: rallenti,
## si sente il colpo, il quartiere si gira, e la macchina vale meno quando la
## consegni. È il freno che tiene la guida una guida invece di un proiettile:
## a diciannove metri al secondo dentro a un vicolo di quattro, chi non
## frena in curva arriva al garage con una carcassa.
const URTO_SOTTO: float = 5.0          # sotto a questa velocità è uno strusciamento
const URTO_RIMBALZO: float = 0.34      # quanta velocità resta doppo 'a botta
const URTO_FRISCO: float = 0.55        # secondi fra una botta contata e l'altra
const URTO_CALORE: float = 5.0

var _pl_a_bordo: Node3D = null
## Quante botte serie s'è pigliata mentre 'a guidavi tu.
var _botte: int = 0
var _urto_frisco: float = 0.0
## 'O motore ca se sente saglì cu 'a velocità.
var _rombo_t: float = 0.0


## **'E cinche culure ca 'o gioco sape nummenà.**
##
## Stavano in `GameManager.COLORI_FURTO` e sono spariti con i furti su
## commissione alla 0.50: da allora questa funzione chiamava una costante
## **che non esiste più**. Non l'ha mai fatto crashare nessuno perché
## `machina_giusta()` tornava sempre falso e nessuno arrivava mai fin qui —
## codice morto che aspettava solo che qualcuno riaprisse la porta. La 0.57
## la riapre, quindi la tabella torna, e torna **dentro all'auto**: il
## colore di una macchina è roba della macchina, non del gestore di partita.
##
## La vernice è randomizzata con uno scarto sui tre canali, quindi non c'è
## nessun "rosso" esatto da confrontare: si prende il più vicino. È l'unico
## modo perché "'na machina rossa" voglia dire la stessa cosa per il gioco e
## per chi guarda.
const CULURE := [
	{"id": "gialla", "col": Color(0.86, 0.74, 0.20)},
	{"id": "rossa", "col": Color(0.72, 0.16, 0.14)},
	{"id": "nera", "col": Color(0.10, 0.10, 0.12)},
	{"id": "bianca", "col": Color(0.88, 0.88, 0.86)},
	{"id": "blu", "col": Color(0.16, 0.26, 0.58)},
	{"id": "grigia", "col": Color(0.55, 0.55, 0.55)},
]

func colore_id() -> String:
	var meglio := "grigia"
	var d_min: float = 1e9
	for c in CULURE:
		var k: Color = c["col"]
		var d: float = (Vector3(colore.r, colore.g, colore.b)
			- Vector3(k.r, k.g, k.b)).length()
		if d < d_min:
			d_min = d
			meglio = str(c["id"])
	return meglio


## Come la chiama chi la guarda: "'na berlina nera".
func nomma_machina() -> String:
	return "'na %s %s" % [car_type, colore_id()]


## Il padrone se n'è andato davvero: o non è mai sceso, o è già fuori scena.
func padrone_sparito() -> bool:
	return _driver == null or not is_instance_valid(_driver)


## Quanto lontano dev'essere l'autista perché tu ci possa mettere le mani.
const PADRONE_LUNTANO: float = 11.0

## **'A finestra d''o furto è 'a spesa** — e questa è la scoperta che ha
## rimesso in piedi tutta la 0.57.
##
## La prima versione del cancello diceva «posteggiata e padrone sparito».
## Sembra la condizione giusta e **non si verifica mai**: `_driver` si
## azzera solo dentro a `l_autista_ha_fernuto()`, che la riga dopo chiama
## `_depart()` e manda via la macchina. Cioè: nel momento esatto in cui
## l'auto diventa "senza padrone", smette anche di essere posteggiata. Un
## `and` fra due cose che si escludono a vicenda — la stessa identica
## famiglia del bug che teneva morto il furto dalla 0.50, riscritto da capo
## sei versioni dopo, da me, mentre stavo proprio aggiustando quello.
##
## La finestra vera il gioco ce l'aveva già da otto versioni e non se ne era
## accorto nessuno: **quanno 'o padrone se ne va a fa' 'a spesa**. Parcheggia,
## ti paga (o non ti paga), si allontana a piedi verso un negozio, e torna
## dopo tre quarti di minuto. Quella è la finestra, ed è perfetta perché non
## è un permesso astratto: è **una persona che si allontana e che tu vedi
## allontanarsi**, e quando torna ti trova con le mani nella serratura.
func padrone_luntano() -> bool:
	if padrone_sparito():
		return true
	# Undici metri: abbastanza da non averti addosso, abbastanza poco da
	# poterti tornare in faccia mentre stai ancora alla terza spilla.
	return _driver.global_position.distance_to(global_position) \
		> PADRONE_LUNTANO


## **Mo' se pò arrubbà qualunque machina posteggiata** (0.57).
##
## Fino alla 0.56 questa funzione chiedeva anche `machina_giusta()`, cioè
## che l'auto fosse quella di un lavoro della bacheca di tipo "furto". Quei
## lavori **sono stati tolti alla 0.50** perché non si riuscivano a fare
## (aspettare che passasse proprio 'na berlina nera è un'attesa, non una
## sfida). Il risultato è che da sei versioni `puoi_arrubba()` tornava
## **sempre falso**: il furto d'auto c'era, era scritto, era perfino
## commentato, e non si poteva fare.
##
## Il capo l'ha riaperto dal verso giusto: *«Si rubano le auto con un
## minigioco»*. Adesso la condizione non è più "è quella che ti hanno
## chiesto" — che dipende dalla sorte — ma **"è posteggiata, il padrone non
## c'è, e non tiene 'a multa ncopp'ô vetro"**, che dipende solo da quello
## che hai fatto tu. Quale macchina vale la pena lo decidi guardando il
## tipo: l'utilitaria si apre subito e paga poco, 'o macchinone è sei spille
## con due tacche rosse.
##
## 'A multa resta una porta chiusa apposta: una macchina segnalata ce
## l'hanno già negli occhi, e in ogni caso quel foglietto lì tu lo devi
## strappare, non ci devi salire sopra.
func puoi_arrubba() -> bool:
	return state == State.PARKED and padrone_luntano() and not has_multa \
		and GameManager.auto_guidata == null


## Ci sali. Da qui in poi la guidi tu.
func arrubba(pl: Node3D) -> bool:
	if not puoi_arrubba() or pl == null:
		return false
	GameManager.auto_guidata = self
	_pl_a_bordo = pl
	_release_spot()
	if _bubble:
		_bubble.say("!!!", 1.2)
	# **'O player nun cammina cchiù: guida.** Spegnergli il `_physics_process`
	# gli toglie in un colpo solo il movimento, la gravità, il raggio
	# dell'interazione e i pugni — che sono esattamente le cose che uno
	# seduto al volante non fa. La camera sta nell'`_unhandled_input`, quindi
	# ci si continua a guardare intorno, che invece serve.
	pl.set_physics_process(false)
	if pl.has_method("azzera_moto"):
		pl.azzera_moto()
	state = State.RUBATA
	_drive_speed = 0.0
	_botte = 0
	_urto_frisco = 0.0
	velocity = Vector3.ZERO
	# Rubare una macchina è un reato, e si vede: due stelle di partenza e
	# il sospetto al massimo. Non è una passeggiata.
	# **E chi te vede** (0.61): in un vicolo vuoto una stella e poco più, in
	# mezzo alla piazza piena fino a quattro.
	var visti: int = GameManager.testimoni(global_position)
	GameManager.crimine(GameManager.PUNTI_PER_STELLA * 2.0
		* GameManager.peso_testimoni(visti))
	GameManager.di_testimoni(visti)
	# **E si 'o padrone sta ancora ô quartiere, 'o ssaje ca 'o ddice.**
	#
	# Se la macchina era di un cliente che è andato a fare la spesa, quello
	# torna, non la trova, e ti viene a cercare. È il costo che non si vede
	# nella cassa: quattro punti di reputazione, cioè mezza giornata di
	# lavoro onesto, più uno che gira la piazza urlando il fatto tuo.
	if not padrone_sparito():
		GameManager.add_reputation(-4)
		if _driver.has_method("t_hanno_arrubbato"):
			_driver.t_hanno_arrubbato()
	GameManager.event_started.emit(
		"Sî ncoppa. Mo' portala ô garage 'e sott'ô stadio — [E] pe' scennere.")
	SoundManager.play("rev", -4.0)
	return true


func _guida_player(delta: float) -> void:
	var avanti: float = Input.get_action_strength("move_up") \
		- Input.get_action_strength("move_down")
	var sterzo: float = Input.get_action_strength("move_left") \
		- Input.get_action_strength("move_right")
	# **Tre pedali e basta.** Lo Shift è la sgasata (lo stesso tasto che a
	# piedi è la corsa: chi gioca non deve imparare un secondo comando per
	# la stessa idea), il Ctrl è il freno a mano.
	var sgaso: bool = Input.is_action_pressed("sprint")
	var manella: bool = Input.is_action_pressed("crouch")

	var tetto: float = RUBATA_VEL_SGASO if sgaso else RUBATA_VEL
	if manella:
		_drive_speed = move_toward(_drive_speed, 0.0, RUBATA_MANELLA * delta)
	elif avanti > 0.05:
		# Sopra al tetto normale non si accelera: si rallenta fino a lui. Così
		# mollare lo Shift decelera davvero invece di restare a diciannove.
		if _drive_speed > tetto:
			_drive_speed = move_toward(_drive_speed, tetto,
				RUBATA_FRENO * 0.5 * delta)
		else:
			_drive_speed = minf(tetto, _drive_speed + RUBATA_ACC * delta)
	elif avanti < -0.05:
		_drive_speed = maxf(-RUBATA_RETRO,
			_drive_speed - RUBATA_FRENO * delta)
	else:
		_drive_speed = move_toward(_drive_speed, 0.0,
			RUBATA_FRENO * 0.40 * delta)

	# **Lo sterzo funziona solo se ti muovi**, e meno da fermo che a
	# velocità: una macchina che gira su se stessa ferma è un carrello.
	#
	# E **si chiude quando corri**: a quattro metri al secondo giri quanto
	# vuoi, a diciannove la stessa rotazione ti metterebbe di traverso. È
	# l'unico pezzo di "fisica" di tutta la guida, e serve a fare in modo che
	# andare forte costi qualcosa — se no la sgasata sarebbe gratis e nessuno
	# rallenterebbe mai.
	if absf(_drive_speed) > 0.2:
		var v: float = absf(_drive_speed)
		var forza: float = clampf(v / 4.0, 0.30, 1.0)
		var stretta: float = lerpf(1.0, RUBATA_STERZO_CHIUSO,
			clampf((v - 4.0) / (RUBATA_VEL_SGASO - 4.0), 0.0, 1.0))
		if manella:
			stretta = RUBATA_MANELLA_STERZO
		rotation.y += sterzo * RUBATA_STERZO * delta * forza * stretta \
			* signf(_drive_speed)

	# forward(θ) = (−sinθ, 0, −cosθ)
	var fwd := Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))
	var voluta: float = _drive_speed
	velocity.x = fwd.x * _drive_speed
	velocity.z = fwd.z * _drive_speed
	velocity.y = 0.0
	move_and_slide()
	_gira_ruote(delta)
	_conta_a_botta(delta, voluta)
	_rombo(delta)

	# 'O player sta dinto: si riscrive la posizione dopo lo spostamento,
	# se no resta indietro di un fotogramma e si vede.
	#
	# **'A capa sta ncopp'ô posto 'e guida**, non al centro del cofano: un
	# metro e cinque d'altezza (l'occhio di uno seduto) e mezzo metro sulla
	# sinistra. Prima stava a 0,55 nel mezzo esatto della macchina, cioè
	# dentro al motore: si vedeva la strada, sì, ma da dentro a un blocco di
	# lamiera, e alla prima curva ti trovavi mezzo cofano davanti agli occhi.
	if _pl_a_bordo != null and is_instance_valid(_pl_a_bordo):
		_pl_a_bordo.global_position = global_position \
			+ global_transform.basis * POSTO_GUIDA
		_pl_a_bordo.velocity = Vector3.ZERO

	_guarda_garage()


## **Addò sta 'a capa 'e chi guida**, negli assi della macchina.
##
## E qui la convenzione va **letta nel file, non ricordata a memoria** —
## è la trappola che in questo progetto è già costata la visiera del vigile
## (0.51), la porta di casa (0.56) e la porta del campetto (0.56).
##
## La regola generale del gioco è che il davanti di un *nodo* è il suo +Z.
## **Questa macchina è l'eccezione**, e si vede da dove sono montati i fari:
## `head.position.z = -half_len` (riga 683). Il muso sta a **−Z**, ed è
## coerente con la guida, che spinge lungo `fwd = (−sinθ, 0, −cosθ)`, cioè
## `−basis.z`. Quindi "un filo più avanti" è **z negativo**.
##
## L'altra metà: `basis.x` è la **destra** (guardando lungo −Z, +X sta a
## destra), quindi il posto di guida — che in Italia sta a sinistra — è x
## negativo. Un metro e sei di altezza è l'occhio di uno seduto.
const POSTO_GUIDA := Vector3(-0.42, 1.06, -0.25)


## **'A botta.** `move_and_slide()` non dice "hai sbattuto": dice dove sei
## finito. La differenza fra la velocità che volevi e quella che ti è
## rimasta è l'urto, e si misura così invece di leggere le collisioni —
## perché strusciare un muro in curva genera collisioni a raffica senza che
## sia successo niente, mentre prenderlo in pieno toglie dieci metri al
## secondo in un fotogramma solo.
func _conta_a_botta(delta: float, voluta: float) -> void:
	_urto_frisco = maxf(0.0, _urto_frisco - delta)
	var vera: float = Vector2(velocity.x, velocity.z).length()
	var persa: float = absf(voluta) - vera
	if persa < URTO_SOTTO or _urto_frisco > 0.0:
		return
	_urto_frisco = URTO_FRISCO
	_botte += 1
	# Resta un terzo della velocità, col segno: se stavi andando in
	# retromarcia continui in retromarcia, solo molto più piano.
	_drive_speed *= URTO_RIMBALZO
	SoundManager.play("bump", -2.0, 0.85)
	GameManager.report_risky_action(URTO_CALORE)
	if _botte == 1:
		GameManager.event_started.emit(
			"Va chiano: ogni botta 'o sfasciacarrozze t''a leva 'a copp'ô prezzo.")


## Il motore che si sente salire. Non è un suono in loop — non ce n'è uno —
## è la sgasata ribattuta a intervalli che si accorciano con la velocità.
func _rombo(delta: float) -> void:
	var v: float = absf(_drive_speed)
	if v < 1.0:
		_rombo_t = 0.0
		return
	_rombo_t -= delta
	if _rombo_t > 0.0:
		return
	_rombo_t = lerpf(1.10, 0.42, clampf(v / RUBATA_VEL_SGASO, 0.0, 1.0))
	SoundManager.play("rev", -19.0 + v * 0.30,
		0.72 + 0.5 * clampf(v / RUBATA_VEL_SGASO, 0.0, 1.0), 0.03)


## **Sî arrivato ô garage?**
##
## Prima questa funzione usciva subito se non avevi in mano un lavoro della
## bacheca di tipo "furto" — lavori che non esistono dalla 0.50. Cioè: la
## consegna al garage era **scollegata da sei versioni**, e una macchina
## rubata si poteva solo guidare in giro finché non scendevi.
##
## Adesso il garage compra qualunque macchina, e quanto paga lo dice
## `GameManager.vinni_machina()`: il valore del tipo, **meno un terzo per
## ogni macchina già portata oggi**, meno le botte che le hai dato per
## strada, più la mano ferma sulle spille prese in pieno.
var ori_scasso: int = 0
var _garage_detto: int = 0

func _guarda_garage() -> void:
	for g in get_tree().get_nodes_in_group("garage"):
		if not (g is Node3D):
			continue
		var raggio: float = float(g.get("RAGGIO")) if g.get("RAGGIO") != null \
			else 5.5
		if global_position.distance_to((g as Node3D).global_position) > raggio:
			continue
		if GameManager.garage_chino():
			# Una volta sola ogni tanto: sta ferma davanti al garage e il
			# controllo gira a ogni fotogramma.
			var ora: int = Time.get_ticks_msec()
			if ora > _garage_detto:
				_garage_detto = ora + 6000
				GameManager.event_started.emit(
					"'O ricettatore: «'O piazzale è chino. Tre 'o juorno, nun ne piglio cchiù. Torna dimane.»")
				SoundManager.play("fail", -6.0, 0.9)
			return
		var paga: int = GameManager.vinni_machina(car_type,
			damage_level + _botte, ori_scasso)
		var coda: String = ""
		if _botte > 0:
			coda = " (%d bbotte: t'hanno levato 'o suojo)" % _botte
		elif ori_scasso > 0:
			coda = " (mano ferma: ce sta 'o suojo dinto)"
		GameManager.event_started.emit(
			"'A machina è trasuta ô garage. €%d%s." % [paga, coda])
		SoundManager.play("door", -2.0)
		_scinne_player(true)
		queue_free()
		return


## Scendi. `sparita` è vero quando l'auto sta per essere cancellata: in quel
## caso il player va messo di fianco, non addosso.
func _scinne_player(sparita: bool = false) -> void:
	GameManager.auto_guidata = null
	if _pl_a_bordo != null and is_instance_valid(_pl_a_bordo):
		var fianco: Vector3 = global_position \
			+ global_transform.basis.x * (2.0 if sparita else 1.8)
		fianco.y = global_position.y + 0.6
		_pl_a_bordo.global_position = fianco
		_pl_a_bordo.set_physics_process(true)
		if _pl_a_bordo.has_method("azzera_moto"):
			_pl_a_bordo.azzera_moto()
	_pl_a_bordo = null
	if not sparita:
		state = State.PARKED
		_parked_time = 999.0   # sta ferma addò l'hê lassata
		_drive_speed = 0.0
		velocity = Vector3.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if state != State.RUBATA:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_scinne_player()
		GameManager.event_started.emit("Sî sceso. 'A machina sta ancora ccà.")


## Lo chiama 'o GameManager quando la giornata finisce mentre guidi: il
## player dev'essere rimesso in piedi comunque vada, se no resta congelato.
func scinne_forzato() -> void:
	if state != State.RUBATA:
		return
	_scinne_player()


# ===========================================================================
# 'O GUAGLIONE 'A GUIDA DAVVERO
# ===========================================================================
#
# **Prima non la guidava.** La piazza chiamava `parcheggiata_dal_guaglione`
# ogni sei-undici secondi e l'auto passava a "parcheggiata" restando ferma
# in mezzo alla strada, dov'era in coda. Il capo, alla prova: *"fai
# funzionare bene i ragazzi che si possono assumere: deve davvero guidare
# le auto"*.
#
# Adesso il guaglione ci cammina fino, ci sale (`guagliuno_sale`), e da
# quel momento la macchina fa la stessa strada che farebbe se la
# dirigessi tu: si avvia verso il posto assegnato, e negli ultimi due
# metri usa la stessa manovra assistita della regia — quella che raddrizza
# e infila. Solo che alla fine i soldi vanno in tasca a lui, e l'autista
# non scende a cercare te.

## Quanto va piano il guaglione. Meno di un autista in fuga, piu' di una
## macchina diretta a gesti: uno che parcheggia per mestiere non ci mette
## mezz'ora e non tira sotto la gente.
const GUAGLIUNO_VEL: float = 3.4
## Oltre questo, dovunque stia, chiude la manovra dov'e' arrivato. Un posto
## dietro a un furgone non deve bloccare la piazza per sempre.
## (0.61: era 26 secondi — mezzo minuto di macchina ferma contro un
## lampione, moltiplicato per venti macchine, era metà della giornata.)
const GUAGLIUNO_MAX: float = 14.0
## Quanto può stare ferma senza avvicinarsi prima di chiudere la manovra.
const GUAGLIUNO_NTUPPO: float = 2.2

var _guagliuno_zona: String = ""
## Chi si prende i soldi, se non è un guaglione tuo (0.61: Gennarino 'o
## Nuovo, che ti posteggia le macchine sotto al naso). Deve avere `incassa`.
var _guagliuno_chi: Node = null
var _guagliuno_t: float = 0.0
var _guagliuno_fermo: float = 0.0
var _guagliuno_d: float = 1e9


## Il guaglione sale a bordo. Torna `false` se non c'e' posto: in quel caso
## quello resta in coda e lui se ne torna al posto suo.
func guagliuno_sale(zona: String, chi: Node = null) -> bool:
	if state != State.WAITING:
		return false
	var meglio = null
	var d_min: float = RAGGIO_POSTI
	for spot in get_tree().get_nodes_in_group("parking_spots"):
		if spot.is_free:
			var d: float = global_position.distance_to(spot.global_position)
			if d < d_min:
				d_min = d
				meglio = spot
	if meglio == null:
		return false
	_release_spot()
	meglio.reserve(self)
	assigned_spot = meglio
	_guagliuno_zona = zona
	_guagliuno_chi = chi
	_guagliuno_t = 0.0
	_guagliuno_fermo = 0.0
	_guagliuno_d = 1e9
	_drive_speed = 0.0
	_bump_count = 0
	_assist_active = false
	velocity = Vector3.ZERO
	state = State.DIRECTING
	_say("Vabbuo', miettela tu, ca io tengo 'e ccose 'a fa'.")
	return true


func _guida_guagliuno(delta: float) -> void:
	if _assist_active:
		_process_assist(delta)
		return
	if assigned_spot == null or not is_instance_valid(assigned_spot):
		_guagliuno_zona = ""
		state = State.WAITING
		_patience_time = randf_range(10.0, 15.0)
		return
	_guagliuno_t += delta
	var meta: Vector3 = assigned_spot.global_position
	meta.y = global_position.y
	var d: float = Vector2(global_position.x, global_position.z).distance_to(
		Vector2(meta.x, meta.z))
	# **'Ntuppata?** Se non si avvicina di un palmo per due secondi, il
	# guaglione fa quello che farebbe chiunque: la raddrizza da dove sta.
	if d < _guagliuno_d - 0.15:
		_guagliuno_d = d
		_guagliuno_fermo = 0.0
	else:
		_guagliuno_fermo += delta
	if d < 1.7 or _guagliuno_t > GUAGLIUNO_MAX \
			or _guagliuno_fermo > GUAGLIUNO_NTUPPO:
		# L'ultimo pezzo con la manovra assistita: e' la stessa che chiude
		# la regia del giocatore, e raddrizza l'auto dentro alle strisce.
		_assist_active = true
		_assist_time = 0.0
		_assist_from_pos = global_position
		_assist_from_rot = rotation.y
		_assist_target_rot = roundf(rotation.y / PI) * PI
		_assist_align_ratio = 0.75
		_assist_dist_ratio = 0.85
		_drive_speed = 0.0
		velocity = Vector3.ZERO
		return
	_guida_verso(meta, GUAGLIUNO_VEL, delta)
	_face_toward(meta)


## Fine manovra. Niente autista che scende a cercarti, niente punteggio di
## regia: 'a machina sta a posto e 'e sorde stanno 'n sacca 'o guaglione.
func _finito_dal_guagliuno() -> void:
	var zona: String = _guagliuno_zona
	_guagliuno_zona = ""
	if assigned_spot and is_instance_valid(assigned_spot):
		var target: Vector3 = assigned_spot.global_position
		# Se qualcosa l'ha sollevata (0.61: la capsula del guaglione), si
		# rimette alla quota del posto e non a mezz'aria.
		if absf(global_position.y - target.y) < 0.8:
			target.y = global_position.y
		global_position = target
		rotation.y = _assist_target_rot
	velocity = Vector3.ZERO
	_drive_speed = 0.0
	_assist_active = false
	parked_abusive = false
	# Lui non fa la regia a gesti: la mancia "della bella manovra" è poca.
	minigame_score = 0.4
	state = State.PARKED
	_parked_time = randf_range(18.0, 28.0)

	# **'A paga soja, no 'a toja** (0.61). Prima si usava `payment_chance()`,
	# cioè quella del giocatore: con la regia a 0,6 e il tirchio, la berlina
	# e le cose tue addosso che lui non tiene (coppola, fama), un cliente su
	# tre gli scappava. Lui non fa gesti e non mena: sta lì col cartello,
	# e chi si ferma da lui ha già deciso di pagare.
	var chi: Node = _guagliuno_chi
	_guagliuno_chi = null
	if randf() >= GameManager.paga_chi_guagliuno(zona, personality):
		_say("Nun tengo spicce, guagliò.")
		return
	if chi != null and is_instance_valid(chi) and chi.has_method("incassa"):
		chi.call("incassa", maxi(1, int(round(float(payment_amount()) * 0.8))))
		return
	var quanto: int = maxi(1, int(round(
		float(payment_amount()) * GameManager.resa_guagliuno(zona))))
	GameManager.dipendente_incassa(zona, quanto)
	GameManager.register_client_served()

	# Il volume scende con la distanza: a trenta metri e' un rumore lontano
	# che ti dice che laggiu' si sta lavorando, a cinque e' uno che conta le
	# monete accanto a te.
	var pl := get_tree().get_first_node_in_group("player")
	if pl != null and pl is Node3D:
		var dd: float = global_position.distance_to(
			(pl as Node3D).global_position)
		if dd < 40.0:
			SoundManager.play("moneta1",
				lerpf(-5.0, -26.0, clampf(dd / 40.0, 0.0, 1.0)),
				randf_range(0.94, 1.08))


## **La posteggia il guaglione, non tu.**
##
## Nessuna regia, nessun autista che scende, nessuna mancia da chiedere: la
## macchina si mette a posto, quello si fa pagare, e i soldi restano in
## tasca a lui finché non passi a ritirarli. Si sente il tintinnio — lo
## stesso dei rivali, e vuol dire la stessa cosa: quella piazza sta
## rendendo, e sta rendendo per te.
##
## Non è parcheggio abusivo: un dipendente che ti riempie la piazza di
## multe sarebbe un dipendente che ti costa, e la meccanica diventerebbe
## una trappola invece di una comodità.
## Il parametro si chiama `dove` e non `zona_id` apposta: dalla 0.55
## `zona_id` è un campo dell'auto, e un parametro con lo stesso nome lo
## nasconderebbe — senza errore, e con l'incasso che finisce nella piazza
## sbagliata solo quando i due valori non coincidono.
func parcheggiata_dal_guaglione(dove: String) -> void:
	if state != State.WAITING and state != State.ARRIVING:
		return
	parked_abusive = false
	minigame_score = 0.6
	velocity = Vector3.ZERO
	_drive_speed = 0.0
	_assist_active = false
	state = State.PARKED
	_parked_time = randf_range(16.0, 24.0)

	if randf() >= payment_chance():
		return # capita: pure a lui qualcuno non paga
	var quanto: int = maxi(1, int(round(
		float(payment_amount()) * GameManager.resa_guagliuno(dove))))
	GameManager.dipendente_incassa(dove, quanto)
	GameManager.register_client_served()

	# Il volume scende con la distanza: a trenta metri è un rumore lontano
	# che ti dice che laggiù si sta lavorando, a cinque è uno che conta le
	# monete accanto a te.
	var pl := get_tree().get_first_node_in_group("player")
	if pl != null and pl is Node3D:
		var d: float = global_position.distance_to((pl as Node3D).global_position)
		if d < 40.0:
			SoundManager.play("moneta1", lerpf(-5.0, -26.0, clampf(d / 40.0, 0.0, 1.0)),
				randf_range(0.94, 1.08))


func _finish_parking() -> void:
	if _guagliuno_zona != "":
		_finito_dal_guagliuno()
		return
	minigame_score = clamp(
		0.55 + _assist_align_ratio * 0.25 + _assist_dist_ratio * 0.2 - _bump_count * 0.08, 0.2, 1.0)

	if assigned_spot and is_instance_valid(assigned_spot):
		var target: Vector3 = assigned_spot.global_position
		target.y = global_position.y
		global_position = target
	velocity = Vector3.ZERO
	_drive_speed = 0.0
	_assist_active = false

	state = State.PARKED
	_parked_time = randf_range(24.0, 34.0)
	GameManager.directing_ended.emit(minigame_score, false)
	SoundManager.play("success")
	# **Un'auto messa dentro alle strisce ti fa sembrare uno che lavora.**
	#
	# Era la meta' mancante del sospetto: fino a ieri ogni cosa lo alzava e
	# solo la sigaretta e l'edicola lo abbassavano, quindi lavorare bene
	# non aveva nessun effetto sul vigile. Adesso ce l'ha — poco, ma ce
	# l'ha, e di piu' se lui ti sta guardando: davanti agli occhi suoi,
	# uno che indirizza una macchina nel posto giusto e' l'ultima persona
	# che gli fa venire voglia di scrivere.
	var visto := false
	for v in get_tree().get_nodes_in_group("vigili"):
		if v.has_method("can_see_player") and v.can_see_player():
			visto = true
			break
	GameManager.cool_down(9.0 if visto else 4.0)
	_spawn_driver()


## L'autista scende dall'auto e si avvia verso l'uscita: è il momento di
## farsi pagare (o di fare altro...).
func _spawn_driver() -> void:
	var parent := get_parent()
	if parent == null or not is_inside_tree():
		return # l'auto sta già uscendo di scena: niente autista
	_driver = DriverScript.new()
	parent.add_child(_driver)
	var door_side: Vector3 = global_transform.basis.x
	_driver.global_position = global_position + door_side * 1.4
	_driver.setup(self, exit_point)
	# **`_parked_time` mo' è 'a durata d''a commissione.**
	#
	# Era quanto la macchina restava posteggiata, e lo decideva lei. Da
	# quando è l'autista a decidere quando si riparte (0.55), quel numero
	# sarebbe rimasto lì a non far niente — e una variabile che non fa
	# niente prima o poi qualcuno la legge credendo che serva. Adesso è
	# il **tempo totale che lui vuole starci**, camminata compresa: il
	# negozio vicino vuol dire più tempo in bottega, quello lontano meno.
	# Così la sosta dura quanto durava prima, ed è tarata sugli stessi
	# numeri di sempre (30-42 s per un cliente qualunque).
	_driver.durata_spesa = _parked_time


func _abort_directing() -> void:
	_assist_active = false
	GameManager.directing_ended.emit(0.0, true)
	GameManager.register_client_lost()
	_release_spot()
	collision_mask = 0
	state = State.LEAVING


# ---------------------------------------------------------------------------
# Pagamento (chiamato dall'autista a piedi) e interazioni sull'auto
# ---------------------------------------------------------------------------

func payment_chance() -> float:
	var info: Dictionary = CAR_TYPES[car_type]
	var chance: float = 0.55 + minigame_score * 0.3 + info["pay_mod"]
	if personality == "tirchio":
		chance -= 0.35 # il tirchio è tirchio
	# **'A coppola.**
	#
	# Costava dodici euro e la sua descrizione diceva, testualmente, "non
	# serve a niente, ma ci vuole". Era vero: nel codice non la leggeva
	# nessuno. Adesso vale otto punti percentuali sulla probabilita' che
	# l'autista paghi senza discutere — perche' uno con 'a coppola sembra
	# del quartiere, e al quartiere si paga.
	#
	# Otto punti sono pochi apposta: la coppola non deve risolvere il
	# gioco, deve farsi notare su venti clienti. Ma su venti clienti si
	# nota, e sono dodici euro.
	if GameManager.has_upgrade("coppola"):
		chance += 0.08
	# **'E piante.** Una piazza con tre vasi in fila non sembra un posto
	# occupato abusivamente: sembra un posto tenuto da qualcuno. E a
	# qualcuno che tiene il posto si paga piu' volentieri.
	if piazza_curata:
		chance += GameManager.bonus_pagamento()
	# **E chello ca te puorte 'ncuollo** (0.56): il gilet vale in tutte e
	# quattro le piazze, non solo sotto casa.
	chance += GameManager.bonus_arnese()
	# **'A nomma.** Chi sa che a te la macchina te la ritrova rigata,
	# discute molto meno. Vedi `GameManager.vendetta_fatta`.
	chance += GameManager.bonus_nomma()
	# **E chello ca 'o quartiere dice 'e te (0.55).** Non è la nomma —
	# quella è la paura. Questa è la stima: la media di come ti tratta chi
	# ti conosce, e vale per **tutti**, pure per chi non t'ha visto mai.
	# Vedi `GameManager.voce()`.
	chance += GameManager.bonus_voce()
	# **E chi te canosce.** Il rapporto vale al massimo venti punti in su e
	# quaranta in giù, e l'asimmetria è voluta: farsi voler bene aiuta,
	# farsi odiare **costa il doppio**. Uno che ti conosce e ti stima paga
	# più volentieri; uno a cui hai rigato la macchina la volta scorsa non
	# tira fuori niente, e tu lo sapevi quando l'hai rigata.
	if cliente_id != "":
		var r: float = GameManager.rapporto(cliente_id)
		chance += (r / 100.0) * (0.20 if r >= 0.0 else 0.40)
	return clamp(chance, 0.1, 0.95)


func payment_amount() -> int:
	var info: Dictionary = CAR_TYPES[car_type]
	var amount: int = randi_range(info["tip_min"], info["tip_max"])
	amount += int(round(amount * (0.5 * minigame_score)))
	match personality:
		"turista":
			amount *= 2 # il turista paga il doppio, beato lui
		"fretta":
			amount = int(ceil(amount * 1.5)) # la fretta si paga
	# **'E luminarie, 'a notte.** Sessanta euro sono il pezzo piu' caro del
	# Bazar, e di giorno non fanno niente: si accendono col buio, e col buio
	# la piazza diventa il posto dove la gente vuole fermarsi. Un quarto in
	# piu' di mancia, e le auto che arrivano piu' spesso (vedi
	# `GameManager.attesa_auto()`). Chi lavora di sera se le ripaga.
	if piazza_curata:
		amount = int(round(float(amount) * GameManager.bonus_mancia()))
	# Occhiali e borsello stanno addosso a te, quindi valgono ovunque.
	amount = int(round(float(amount) * GameManager.mancia_arnese()))
	# **E 'o posto conta.** Chi fa 'a spesa ô mercato conta 'e monete; chi
	# va ô stadio tene 'o portafoglio apierto. Vedi `GameManager.CARATTERE`.
	amount = int(round(float(amount) * GameManager.mancia_piazza(zona_id)))
	# E la voce che gira tocca la mancia di chiunque, non solo dei sei.
	amount = int(round(float(amount) * GameManager.mancia_voce()))
	# **'A mancia d''o cliente fisso.** Due moltiplicatori: quello suo di
	# carattere ('o Tedesco lascia il 45% in più e non se ne accorge, Donna
	# Assunta il 15% in meno perché conta le monete) e quello del rapporto,
	# che sopra a zero arriva a un terzo in più. Chi ti vuole bene lascia
	# il resto; chi ti odia, se paga, paga il minimo.
	if cliente_id != "":
		var c: Dictionary = Gente.cliente(cliente_id)
		if not c.is_empty():
			var m: float = float(c["mancia"])
			m *= 1.0 + clampf(GameManager.rapporto(cliente_id) / 100.0,
				-0.4, 1.0) * 0.33
			amount = int(round(float(amount) * maxf(0.4, m)))
	return maxi(1, amount)


## Quanti pugni servono per il pagamento forzato (il tirchio è più duro).
func punches_needed() -> int:
	return 3 if personality == "tirchio" else 2


func get_interact_prompt(_from_position: Vector3) -> String:
	match state:
		State.WAITING:
			if not _any_free_spot():
				return "Nun ce sta nu posto libbero: aspetta ca se ne libbera uno"
			return "[E] 'o guide a gesti dint'ô posto"
		State.PARKED:
			# **La multa ha la precedenza su tutto il resto.**
			#
			# Finché c'è un foglietto sul parabrezza, [E] serve a strapparlo.
			# Lo stemma può aspettare: se non lo togli in tempo, quando
			# l'autista torna trova il verbale e la giornata è rovinata, e
			# non c'è modo di rimediare dopo.
			if has_multa and not _multa_confronto:
				return "[E] straccia 'a multa 'a sotto ô tergicristallo"
			# **'O furto su cummissione ha 'a precedenza.** Se questa e'
			# proprio quella che t'hanno chiesto, tutto il resto — stemma,
			# vandalismo — non conta piu' niente: quella macchina vale
			# duecentosessanta euro e la stai per portare via.
			# **'O scasso se piglia [E], 'o stemma passa ncopp'a [G].**
			#
			# Fino alla 0.56 [E] su un'auto parcheggiata voleva dire "stacca
			# lo stemma", e il furto d'auto viveva sullo stesso tasto solo
			# nel caso — mai capitato — in cui fosse l'auto di una
			# commissione. Adesso che qualunque macchina si può scassare, i
			# due gesti si dividono: **[E] è 'a machina, [G] è 'o stemma.**
			# Lo stemma sta su un tasto suo perché è l'azione piccola, quella
			# da dieci euro che fai di passaggio; il furto è quella grossa, e
			# la grossa va sul tasto che uno preme senza pensarci.
			var parts: Array = []
			if puoi_arrubba():
				parts.append("[E] scassa 'a machina (%s · %s)" % [
					car_type, GameManager.scasso_nomme(car_type)])
			elif GameManager.auto_guidata != null:
				parts.append("'Na machina a vota, và")
			elif not padrone_luntano():
				parts.append("'O padrone sta ancora ccà vicino")
			if has_emblem:
				parts.append("G: ruba lo stemma \"%s\"" % emblem_info["name"])
			if damage_level < MAX_DAMAGE:
				parts.append("F: danneggia l'auto")
			return " · ".join(parts)
	return ""


func player_interact() -> void:
	match state:
		State.WAITING:
			_start_parking()
		State.PARKED:
			if has_multa and not _multa_confronto:
				_straccia_multa()
			elif puoi_arrubba():
				_apre_o_scasso()
		State.RUBATA:
			pass


## [H]: 'o stemma, ca mo' tene 'nu tasto sujo.
func player_stemma() -> void:
	if state == State.PARKED and has_emblem:
		_steal_emblem()


# ---------------------------------------------------------------------------
# 'O SCASSO (0.57)
# ---------------------------------------------------------------------------
#
# **'O pannello se costruisce ccà e se scassa ccà.** Un CanvasLayer per ogni
# macchina parcheggiata in città sarebbero ottanta pannelli invisibili che
# girano a vuoto; uno solo appeso alla radice sarebbe roba condivisa che
# sopravvive a chi l'ha aperta, e in questo progetto quello è già successo
# (la 0.49, 'o pannello d''a bacheca ca restava acceso). Quindi: si crea
# quando serve, si aggancia il segnale, si butta quando ha finito.

const PannelloScassa := preload("res://scripts/pannello_scassa.gd")

var _scasso: CanvasLayer = null

func _apre_o_scasso() -> void:
	if _scasso != null and is_instance_valid(_scasso):
		return
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null:
		return
	_scasso = PannelloScassa.new()
	_scasso.name = "PannelloScassa"
	get_tree().root.add_child(_scasso)
	_scasso.finito.connect(_scasso_fernuto)
	_scasso.apri(car_type, nomma_machina(), pl)
	# Mettere le mani su una serratura in mezzo alla strada si vede, anche
	# se poi non ci riesci. Mezza stella, e il quartiere si gira.
	GameManager.report_risky_action(9.0)


func _scasso_fernuto(vinto: bool, ori: int) -> void:
	if _scasso != null and is_instance_valid(_scasso):
		_scasso.queue_free()
	_scasso = null
	if not vinto:
		return
	# Il mondo ha continuato a girare mentre scassavi: può essere successo
	# di tutto, compreso che l'autista sia tornato o che ti abbiano messo
	# la multa. Si ricontrolla prima di salire.
	if not puoi_arrubba():
		GameManager.event_started.emit("'A machina nun se pò cchiù piglià.")
		return
	ori_scasso = ori
	var pl := get_tree().get_first_node_in_group("player")
	if pl != null and pl is Node3D:
		arrubba(pl as Node3D)


## **Strappare il verbale prima che torni l'autista.**
##
## Prima la multa era una condanna: il vigile passava, appiccicava il
## foglietto, e da quel momento il cliente sarebbe tornato incazzato di
## sicuro — senza che tu potessi fare niente. Una punizione che non si può
## evitare non insegna niente, è solo sfortuna.
##
## Adesso c'è una finestra: dal momento in cui il vigile scrive fino a
## quando l'autista torna (trenta-quaranta secondi) puoi andare all'auto e
## strapparlo. Non è gratis — sei uno che tocca un atto pubblico davanti a
## chi passa — ma è una cosa che dipende da te, ed è per questo che
## "mettila ccà" torna a essere una scommessa invece che una trappola.
const MULTA_STRACCIO_CALORE: float = 10.0

func _straccia_multa() -> void:
	if not has_multa or _multa_confronto:
		return
	has_multa = false
	if _multa_node != null and is_instance_valid(_multa_node):
		_multa_node.queue_free()
	_multa_node = null
	# Il contatore del riepilogo torna indietro: quella multa non l'ha
	# beccata nessuno.
	GameManager.annulla_multa()
	SoundManager.play("stemma", -4.0)
	GameManager.report_risky_action(MULTA_STRACCIO_CALORE)
	GameManager.event_started.emit(
		"Multa stracciata. 'O cliente nun ne sape niente.")
	if _bubble:
		_bubble.say("Chi s'è visto s'è visto.", 1.8)
	# Se il vigile ti guarda mentre lo fai, non la prende bene: il
	# foglietto l'aveva scritto lui.
	var v = GameManager.nu_vigile_te_vede()
	if v != null and v.has_method("t_ha_visto"):
		v.t_ha_visto(16.0, "E CHE STAJE FACENNO?!")


func player_vandalize() -> void:
	if state == State.PARKED and damage_level < MAX_DAMAGE:
		_do_vandalize()


func _steal_emblem() -> void:
	if not has_emblem:
		return
	has_emblem = false
	if _emblem_root and is_instance_valid(_emblem_root):
		_emblem_root.queue_free()
	_emblem_root = null
	_emblem_node = null
	GameManager.add_emblem(emblem_info["name"], emblem_info["value"])
	var visti: int = GameManager.testimoni(global_position)
	GameManager.report_risky_action(STEAL_HEAT * GameManager.peso_testimoni(visti))
	if visti >= 4:
		GameManager.di_testimoni(visti)
	SoundManager.play("stemmi", -2.0)
	# **E se 'o vigile stava guardanno, chella è 'a fine d''a jurnata**
	# (0.56, punto 9). Il capo: *«anche rubare e rivendere stemmi davanti a
	# lui dovrebbe essere un problema»*.
	#
	# Prima c'era già il raddoppio di `report_risky_action` — ventiquattro
	# punti invece di dodici — ma ventiquattro punti su cento, con lui che
	# non diceva niente e continuava a camminare, non si sentivano proprio:
	# rubavi lo stemma sotto il naso a un vigile e non succedeva **niente
	# che si vedesse**. Uno chinato sul cofano di una macchina che non è la
	# sua, con lo stemma in mano, davanti a un pubblico ufficiale, non è
	# un'aggravante: è flagranza. Sospetto al massimo, e da lì il verbale.
	var vig = GameManager.nu_vigile_te_vede()
	if vig != null and vig.has_method("t_ha_visto"):
		vig.t_ha_visto(GameManager.HEAT_MAX,
			"FERMO CU 'E MMANE! T'AGGIO VISTO!")
	# Il padrone reagisce **solo se ti vede** (vedi `driver_3d._me_vede`).
	# In tutti i casi la macchina resta senza stemma, e quello se lo
	# ritrova davanti quando torna.
	_stemma_sparito = true
	# Lo stemma pesa meno di una rigata (è roba, non è la macchina), ma
	# pesa: due stemmi a Peppe e Peppe smette di lasciarti le chiavi.
	if cliente_id != "" and not _rapporto_rutto:
		_rapporto_rutto = true
		GameManager.muove_rapporto(cliente_id, GameManager.RAPPORTO_DANNO * 0.6)
	if _driver and is_instance_valid(_driver):
		_driver.reagisci_si_me_vede()


func _do_vandalize() -> void:
	apply_damage()
	GameManager.report_risky_action(VANDALIZE_HEAT)
	SoundManager.play("bump", 0.0, 0.65)
	GameManager.screen_shake.emit(0.5)
	if not _damage_registered:
		_damage_registered = true
		GameManager.register_car_damaged()
	_say(DRIVER_CAR_DAMAGED)

	# **'A vendetta 'ncopp'a chi nun paga mo' serve a quaccosa.**
	#
	# Rigare la macchina di uno che ti ha rifiutato i soldi è la pubblicità
	# del mestiere: la macchina rigata resta lì per il resto della
	# giornata, e la gente della piazza la vede. Da lì i clienti dopo
	# discutono meno (vedi `GameManager.vendetta_fatta` e `payment_chance`).
	#
	# Rigare la macchina di uno che **ha pagato**, invece, non è una
	# vendetta: è vandalismo e basta, e non porta niente — giustamente.
	var rifiutato: bool = _driver != null and is_instance_valid(_driver) \
		and not paid and bool(_driver.get("_refused"))
	# La macchina resta rigata, e quello se la ritrova così quando torna:
	# da lì il confronto (vedi `driver_3d._motivo_del_ritorno`).
	_scassata_ammuccione = true

	# **E si era uno d''e tuoie, chillo se l'arricorda.** Trenta punti, una
	# volta sola per macchina: rigare tre volte non è tradire tre volte. È
	# la scelta che il sistema dei clienti fissi rende una scelta vera —
	# la vendetta ti dà la nomma con tutta la piazza e ti toglie **quello
	# lì**, e quello lì torna domani.
	if cliente_id != "" and not _rapporto_rutto:
		_rapporto_rutto = true
		GameManager.muove_rapporto(cliente_id, GameManager.RAPPORTO_DANNO)

	if rifiutato and not _vendetta_contata:
		_vendetta_contata = true
		var visto: bool = _qualcuno_guarda()
		GameManager.vendetta_fatta(visto)
		GameManager.event_started.emit(
			"Chillo nun ha pagato, e mo' 'a machina soia 'o dice a tuttu quante."
			if visto else "Fatta. Ma nun t'ha visto nisciuno.")

	if _driver and is_instance_valid(_driver):
		_driver.reagisci_si_me_vede()


## C'è qualcuno che sta guardando? Basta un passante o il padrone stesso a
## dieci metri: la voce parte da lì.
func _qualcuno_guarda() -> bool:
	if _driver != null and is_instance_valid(_driver):
		return true
	for g in ["passanti", "vigili", "signore"]:
		for n in get_tree().get_nodes_in_group(g):
			if n is Node3D and is_instance_valid(n) \
					and global_position.distance_to(
						(n as Node3D).global_position) < 12.0:
				return true
	return false
