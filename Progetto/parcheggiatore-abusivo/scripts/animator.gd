extends Node
class_name Animator
## Animator — 'o motore d''e pose, ncopp'ê animazioni vere
##
## **Chello ca è cagnato ê 0.48.**
##
## Prima questo file conteneva **ottocento righe di animazioni scritte a
## mano**: camminata, corsa, pugno, parlata, tutte costruite keyframe per
## keyframe su uno scheletro mio, più un pezzo di codice che provava a
## tradurre le clip della libreria di cattura su quello scheletro. Il
## risultato erano spalle storte, pose a T e un difetto nuovo a ogni clip.
##
## Adesso il personaggio **è** il manichino della libreria, e le clip sono
## le sue: si accendono e basta. Questo file è diventato quello che doveva
## essere — un cambio di marce sopra a un `AnimationTree`.
##
## L'interfaccia è rimasta identica, perché la chiamano da quaranta posti:
## `set_speed`, `set_crouching`, `knock_down`, `revive`, `sit`, `stand`,
## `action`, `hold_bone`, `release_bone`.

## Le clip che servono, col nome che hanno **dentro a Godot**.
##
## Attenzione: nel file si chiamano `Idle_Loop`, `Walk_Loop`, `Sprint_Loop`.
## L'importatore di Godot riconosce il suffisso `_Loop`, lo **toglie dal
## nome** e accende il ciclo da solo. Chi cerca `Idle_Loop` non trova
## niente e si ritrova tutti fermi in posa di riposo.
const CLIP := {
	"idle": "Idle",
	"walk": "Walk",
	"jog": "Jog_Fwd",
	"run": "Sprint",
	"crouch": "Crouch_Idle",
	"crouch_walk": "Crouch_Fwd",
	"morto": "Death01",
	"seduto": "Sitting_Idle",
	"seduto_parla": "Sitting_Talking",
	"parla": "Idle_Talking",
	# **'E pugne d''o giocatore (0.54).**
	#
	# `player_fps.gd` chiamava `action("pugno")` e `action("coltellata")`, e
	# nessuna delle due stava in questa tabella: `action()` esce subito
	# quando la chiave non c'è, quindi **il corpo del giocatore non tirava
	# nessun pugno**. Si muovevano solo le due mani finte appese alla
	# camera, ed è metà del motivo per cui il capo ha chiesto di rifare le
	# animazioni dei pugni: non erano fatte male, non c'erano.
	#
	# Adesso ci sono, e sono tre clip vere invece di una: il destro, il
	# sinistro e la stoccata col coltello. Chi mena due volte di fila vede
	# due colpi **diversi**, che è quello che distingue una scazzottata da
	# un tasto premuto due volte.
	"punch": "Punch_Cross",
	"jab": "Punch_Jab",
	"pugno": "Punch_Cross",
	"pugno_sinistro": "Punch_Jab",
	"coltellata": "Sword_Attack",
	"colpo": "Hit_Chest",
	"colpo_capa": "Hit_Head",
	"point": "Interact",
	"shrug": "PickUp_Table",
	"guida": "Driving",
}

## Quali vanno in ciclo. Le altre — la morte, il pugno, il colpo preso —
## devono finire e restare ferme: una morte che riparte da capo è un
## personaggio che si rialza e ricade per sempre.
const CICLICHE := ["Idle", "Walk", "Jog_Fwd", "Sprint", "Crouch_Idle",
	"Crouch_Fwd", "Sitting_Idle", "Sitting_Talking", "Idle_Talking",
	"Driving", "Push", "Swim_Fwd", "Swim_Idle", "Walk_Formal",
	"Pistol_Idle", "Sword_Idle", "Spell_Simple_Idle", "Idle_Torch"]

## **'E velocità d''e ppassi.**
##
## È il numero che alla 0.47 ha rovinato tutte le animazioni: il punto della
## camminata stava a 2,6 m/s mentre la gente cammina a 1,5, e il
## `BlendSpace` mescolava il 58% di posa ferma dentro a ogni passo. Qui ci
## sono le velocità vere: si cammina a 1,35, si va di fretta a 3, si corre
## a 6.
## `V_SVELTO` non c'è più: era la quota del secondo punto della camminata,
## quello che sfasava il ciclo contro se stesso (vedi `_costruisci`).
const V_CAMMINA := 1.35
const V_TROTTA := 3.6
const V_CORSA := 6.5

## Quanto sta alto il bacino quando uno è **assettato**, in frazione
## dell'altezza. Misurato sulla clip `Sitting_Idle`: 0,542 su un pupo alto
## 1,78. Serve a chi mette un personaggio su una sedia: la radice va
## abbassata di questo per far cadere il sedere sulla seduta.
const BACINO_SEDUTO := 0.3045
## E questo è dove sta in piedi: 0,873 su 1,78.
const BACINO_IN_PIEDI := 0.4904

## Le ossa, col nome che usa il gioco a sinistra e quello vero dello
## scheletro Unreal a destra. Serve a `hold_bone`, che è chiamato con i
## nomi vecchi da mezza dozzina di personaggi.
const OSSA := {
	"hips": "pelvis", "spine": "spine_01", "chest": "spine_03",
	"neck": "neck_01", "head": "Head",
	"shoulder_l": "upperarm_l", "shoulder_r": "upperarm_r",
	"elbow_l": "lowerarm_l", "elbow_r": "lowerarm_r",
	"hand_l": "hand_l", "hand_r": "hand_r",
	"thigh_l": "thigh_l", "thigh_r": "thigh_r",
	"knee_l": "calf_l", "knee_r": "calf_r",
	"foot_l": "foot_l", "foot_r": "foot_r",
}

var _parti: Dictionary = {}
var _scheletro: Skeleton3D = null
var _player: AnimationPlayer = null
var _tree: AnimationTree = null
var _playback: AnimationNodeStateMachinePlayback = null
var _pronto: bool = false

var _velocita: float = 0.0
var _accucciato: bool = false
var _seduto: bool = false
var _seduto_parla: bool = false
var _steso: bool = false
## Le ossa tenute ferma a mano: nome vero → quaternione.
var _tenute: Dictionary = {}
## Le ossa puntate (0.64): nome vero → direzione nel verso del personaggio.
## Vedi `punta_osso`.
var _puntate: Dictionary = {}


## **'E clip d''e cuorpe nuove** (0.59). Il pupo usa la tabella `CLIP`;
## gli omini e l'umano di Quaternius portano la loro (`HumanBuilder.RIG`),
## con le stesse chiavi e i nomi delle loro clip. Le librerie dei corpi
## nuovi hanno già i cicli giusti: `_sistema_cicli` serve solo al pupo.
var _mappa: Dictionary = {}
var _rig: String = "pupo"


func setup(parti: Dictionary) -> void:
	_parti = parti
	_scheletro = parti.get("scheletro", null) as Skeleton3D
	_player = parti.get("player", null) as AnimationPlayer
	_mappa = parti.get("clip", {})
	_rig = str(parti.get("rig", "pupo"))
	if is_inside_tree():
		_costruisci()


func _ready() -> void:
	# Le ossa tenute a mano si scrivono DOPO che l'albero ha messo la posa:
	# con una priorità alta questo nodo gira per ultimo nel frame.
	process_priority = 100
	if not _pronto:
		_costruisci()


func _costruisci() -> void:
	if _pronto or _player == null or _scheletro == null:
		return
	if _rig == "pupo":
		_sistema_cicli()

	# **'A camminata nun se metteva doje vote.**
	#
	# Qui c'erano cinque punti, e la camminata compariva **due volte**: a
	# 1,35 e a 3,0. L'idea era tenere il passo puro in tutta la fascia fra
	# le due, invece di sfumare subito verso la corsetta. In teoria è una
	# tecnica giusta. In Godot è un guasto, e il motivo sta scritto nella
	# documentazione di `AnimationNodeBlendSpace1D`:
	#
	#   > If `sync` is false, the blended animations' frame are **stopped**
	#   > when the blend value is zero.
	#
	# Cioè: quando il personaggio sta fermo o cammina piano, il secondo
	# nodo `Walk` ha peso zero e **il suo tempo si congela**. Riparte dopo,
	# da un fotogramma qualunque. Da quel momento le due copie della stessa
	# camminata girano **sfasate**, e a metà strada fra i due punti il
	# motore ne fa la media: gamba avanti mediata con gamba indietro fa
	# gamba ferma. Il risultato è un personaggio rigido che **scivola** —
	# che è esattamente quello che ha visto il capo: *"non sembrano usare
	# l'animazione di camminata"*. La usavano: la usavano due volte, contro
	# se stessa.
	#
	# Due cure, e servono tutte e due. La prima: un punto solo per clip,
	# niente più media di un ciclo con se stesso. La seconda: `sync = true`,
	# così nessun nodo si congela e le fasi non si perdono nemmeno fra clip
	# diverse.
	var loco := AnimationNodeBlendSpace1D.new()
	loco.min_space = 0.0
	loco.max_space = V_CORSA
	loco.sync = true
	loco.add_blend_point(_nodo("idle"), 0.0)
	loco.add_blend_point(_nodo("walk"), V_CAMMINA)
	loco.add_blend_point(_nodo("jog"), V_TROTTA)
	loco.add_blend_point(_nodo("run"), V_CORSA)

	var sm := AnimationNodeStateMachine.new()
	sm.add_node("loco", loco, Vector2(0, 0))
	sm.add_node("crouch", _nodo("crouch"), Vector2(0, 140))
	sm.add_node("morto", _nodo("morto"), Vector2(240, 70))
	sm.add_node("seduto", _nodo("seduto"), Vector2(-240, 70))
	sm.add_node("seduto_parla", _nodo("seduto_parla"), Vector2(-240, 150))
	sm.add_node("parla", _nodo("parla"), Vector2(0, -140))

	_lega(sm, "loco", "crouch", 0.22)
	_lega(sm, "crouch", "loco", 0.22)
	_lega(sm, "loco", "morto", 0.10)
	_lega(sm, "crouch", "morto", 0.10)
	_lega(sm, "seduto", "morto", 0.10)
	_lega(sm, "morto", "loco", 0.45)
	_lega(sm, "loco", "seduto", 0.45)
	_lega(sm, "seduto", "loco", 0.35)
	_lega(sm, "seduto", "seduto_parla", 0.35)
	_lega(sm, "seduto_parla", "seduto", 0.35)
	_lega(sm, "seduto_parla", "loco", 0.35)
	_lega(sm, "loco", "parla", 0.30)
	_lega(sm, "parla", "loco", 0.30)

	# Le azioni si sommano sopra allo stato: si può tirare un pugno mentre
	# si cammina senza che le gambe si fermino.
	var colpo := AnimationNodeOneShot.new()
	colpo.fadein_time = 0.08
	colpo.fadeout_time = 0.20
	colpo.mix_mode = AnimationNodeOneShot.MIX_MODE_BLEND

	var albero := AnimationNodeBlendTree.new()
	albero.add_node("states", sm, Vector2(0, 0))
	albero.add_node("azione", _nodo("punch"), Vector2(0, 170))
	albero.add_node("shot", colpo, Vector2(280, 60))
	albero.connect_node("shot", 0, "states")
	albero.connect_node("shot", 1, "azione")
	albero.connect_node("output", 0, "shot")

	_tree = AnimationTree.new()
	_tree.name = "Albero"
	add_child(_tree)
	_tree.tree_root = albero
	_tree.anim_player = _tree.get_path_to(_player)
	_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE
	_tree.active = true
	_playback = _tree.get("parameters/states/playback")
	# **'A macchina a stati vò essere appicciata.** Un
	# `AnimationNodeStateMachine` costruito a mano non parte da nessuno
	# stato: resta fuori da tutti, e il personaggio mostra la posa di
	# riposo dello scheletro — cioè **la posa a T**. Era esattamente quello
	# che si vedeva: chi stava seduto (che chiama `travel`) andava bene,
	# tutti gli altri stavano in croce.
	# **E si parte dallo stato giusto** (0.59). Chi chiama `sit()` prima che
	# l'animatore entri nell'albero — i vecchi della scopa si siedono mentre
	# il tavolino si costruisce — si segnava `_seduto` e basta: il
	# `travel` si saltava perché l'albero non c'era ancora, e poi qui si
	# partiva da "loco". Vecchi in piedi dentro alla sedia. Adesso lo stato
	# chiesto prima si rispetta, e ci si entra con `start` (senza la
	# transizione da in piedi, che non è mai successa).
	var primo := "loco"
	if _steso:
		primo = "morto"
	elif _seduto:
		primo = "seduto_parla" if _seduto_parla else "seduto"
	elif _accucciato:
		primo = "crouch"
	_playback.start(primo)
	_pronto = true
	_tree.set("parameters/states/loco/blend_position", _velocita)


## Godot non sa da solo quali clip vanno in ciclo: quelle della libreria
## hanno `_Loop` nel nome, e la morte no — una morte che riparte da capo è
## un personaggio che si rialza e ricade per sempre.
func _sistema_cicli() -> void:
	for nome in _player.get_animation_list():
		var a: Animation = _player.get_animation(nome)
		if a == null:
			continue
		a.loop_mode = Animation.LOOP_LINEAR if CICLICHE.has(str(nome)) \
			else Animation.LOOP_NONE


func _nodo(chiave: String) -> AnimationNodeAnimation:
	var n := AnimationNodeAnimation.new()
	n.animation = _clip(chiave)
	return n


## Il nome vero della clip per questo corpo.
func _clip(chiave: String) -> String:
	var nome: String = str(_mappa.get(chiave, CLIP.get(chiave, "Idle")))
	if _player != null and not _player.has_animation(nome):
		nome = "Idle"
	return nome


func _lega(sm: AnimationNodeStateMachine, da: String, a: String,
		tempo: float) -> void:
	var t := AnimationNodeStateMachineTransition.new()
	t.xfade_time = tempo
	t.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_SYNC
	t.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	sm.add_transition(da, a, t)


# ---------------------------------------------------------------------------
# L'interfaccia, quella di sempre
# ---------------------------------------------------------------------------

func is_ready() -> bool:
	return _pronto


func set_speed(speed: float) -> void:
	_richiesta = clampf(speed, 0.0, V_CORSA)
	_applica_velocita()


## **'E ccosce vanno cu 'e piere** (0.59).
##
## Chi chiama `set_speed` dice quanto *vorrebbe* andare: l'autista dice
## «cammino», il vigile dice «corro». Se davanti c'è un muro, un'auto in
## sosta o un altro corpo, il passo non avanza — ma le gambe continuavano a
## fare la camminata: un personaggio che **cammina sul posto** contro una
## facciata, che è il modo più vistoso di essere rotti. Adesso l'animatore
## misura da solo quanto si è spostato davvero il corpo, e le gambe vanno a
## quella velocità, non a quella chiesta. Chi è fermo sta fermo.
##
## Il margine (+15% e +15 cm/s) serve a chi parte: nel primo decimo di
## secondo la velocità misurata è ancora zero, e senza margine nessuno
## comincerebbe mai a camminare.
var _richiesta: float = 0.0
var _vel_reale: float = 0.0
var _ultima_pos: Vector3 = Vector3.INF


func _applica_velocita() -> void:
	var v: float = _richiesta
	if _ultima_pos != Vector3.INF:
		v = minf(v, _vel_reale * 1.15 + 0.15)
	_velocita = v
	if not _pronto:
		return
	_tree.set("parameters/states/loco/blend_position", _velocita)


func _misura_passo(delta: float) -> void:
	var corpo := get_parent() as Node3D
	if corpo == null or delta <= 0.0 or not corpo.is_inside_tree():
		return
	var p: Vector3 = corpo.global_position
	if _ultima_pos != Vector3.INF:
		var d: float = Vector2(p.x - _ultima_pos.x, p.z - _ultima_pos.z).length()
		# Un salto di mezzo metro in un fotogramma non è un passo: è uno
		# spostamento a mano (uno spawn, un teletrasporto). Non si conta.
		if d < 0.5:
			_vel_reale = lerpf(_vel_reale, d / delta, 1.0 - exp(-8.0 * delta))
	_ultima_pos = p
	if _richiesta > 0.0 or _velocita > 0.0:
		_applica_velocita()


func set_crouching(value: bool) -> void:
	if _accucciato == value:
		return
	_accucciato = value
	if not _pronto or _steso:
		return
	_playback.travel("crouch" if value else "loco")


func knock_down() -> void:
	_steso = true
	if _pronto:
		_playback.travel("morto")


func revive() -> void:
	_steso = false
	if _pronto:
		_playback.travel("loco")


func is_knocked() -> bool:
	return _steso


func sit(parlando: bool = false) -> void:
	_seduto = true
	_seduto_parla = parlando
	if _pronto:
		_playback.travel("seduto_parla" if parlando else "seduto")


func stand() -> void:
	_seduto = false
	if _pronto:
		_playback.travel("loco")


func is_sitting() -> bool:
	return _seduto


## Le vecchie varianti di andatura non servono più: la velocità sceglie da
## sola fra ferma, camminata, trotto e corsa. Resta la funzione perché la
## chiama del codice vecchio.
func imposta_passo(_quale: String) -> void:
	pass


## Un gesto sopra a quello che si sta facendo: pugno, indicare, parlare.
func action(nome: String) -> void:
	if not _pronto:
		return
	if nome == "parla":
		# La parlata non è un gesto da mezzo secondo: è uno stato, e
		# finisce quando il personaggio smette di parlare.
		parla_per(PARLA_DURATA)
		return
	var chiave: String = nome
	if not CLIP.has(chiave) and not _mappa.has(chiave):
		chiave = "point"
	var n := _tree.tree_root.get_node("azione") as AnimationNodeAnimation
	if n != null:
		n.animation = _clip(chiave)
	_tree.set("parameters/shot/request",
		AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


## **'A reazione ô cazzotto, senza restà 'nchiuvato.**
##
## Il capo chiede due cose che tirano in direzioni opposte: il personaggio
## deve **reagire** al pugno, ma non deve **bloccarsi**. Sono opposte perché
## il modo ovvio di far reagire qualcuno è mandarlo in uno stato "colpito" —
## e uno stato, per definizione, gli toglie il controllo finché non finisce.
## Con due pugni al secondo quello stato si riavvia sempre e il personaggio
## resta immobile a subire: lo stun-lock, che è la cosa che il capo aveva
## già fatto togliere alla 0.45.
##
## Qui non è uno stato: è il livello `OneShot` che sta **sopra** alla
## locomozione. La clip del colpo si somma al passo — il busto incassa
## mentre le gambe continuano a scappare — e quando finisce si spegne da
## sola. Il personaggio non perde un fotogramma di controllo.
##
## L'unico freno è il tempo di ricarica: sotto ai tre decimi la richiesta
## si ignora. Non serve alla logica (il OneShot si riavvierebbe senza
## problemi), serve **all'occhio**: una clip di reazione riavviata ogni
## decimo di secondo resta ferma sul primo fotogramma, e riavviarla di
## continuo è proprio l'aspetto dello stun-lock che vogliamo evitare.
const COLPO_OGNI: float = 0.30
var _colpo_pronto: float = 0.0

func reagisci_colpo(in_faccia: bool = false) -> void:
	if not _pronto or _steso:
		return
	var ora: float = float(Time.get_ticks_msec()) * 0.001
	if ora < _colpo_pronto:
		return
	_colpo_pronto = ora + COLPO_OGNI
	action("colpo_capa" if in_faccia else "colpo")


## Smette di parlare e torna in piedi normale.
func stop_parlata() -> void:
	_parla_t = 0.0
	if _pronto and not _seduto and not _steso:
		_playback.travel("loco")


# ---------------------------------------------------------------------------
# **'A parlata fernesce** (0.62)
# ---------------------------------------------------------------------------
#
# Il capo: *«Molti dei nuovi modelli non hanno animazioni»*. Una parte vera
# della ragione stava qui. Il fumetto (`speech_bubble._gesticola`) chiama
# `action("parla")`, che manda l'albero nello stato "parla" — e **nessuno lo
# tirava più fuori**: `stop_parlata()` non la chiamava nessun file. Ogni
# personaggio che aveva detto una frase restava per sempre nella clip della
# parlata, anche camminando: le gambe ferme e il corpo che scivolava per la
# strada. Sugli omini e sull'umano la parlata era l'`Idle` (non avevano una
# clip loro), quindi scivolavano **immobili**: la statua che cammina.
#
# Adesso la parlata dura quanto il fumetto, e finisce da sola; e appena il
# personaggio si muove davvero (più di 0,35 m/s) si torna alle gambe.
const PARLA_DURATA: float = 2.6
var _parla_t: float = 0.0
var _parla_seduto: bool = false


func parla_per(secondi: float) -> void:
	if not _pronto or _steso:
		return
	_parla_t = maxf(_parla_t, secondi)
	if _seduto:
		if not _seduto_parla:
			_parla_seduto = true
			_playback.travel("seduto_parla")
		return
	if _velocita > 0.35:
		return  # cammina: si parla camminando, le gambe vanno
	_playback.travel("parla")


func _passo_parlata(delta: float) -> void:
	if _parla_t <= 0.0 or not _pronto:
		return
	_parla_t -= delta
	var fine: bool = _parla_t <= 0.0
	if not _seduto and _velocita > 0.35:
		fine = true
	if not fine:
		return
	_parla_t = 0.0
	if _steso:
		return
	if _seduto:
		if _parla_seduto:
			_parla_seduto = false
			_playback.travel("seduto_parla" if _seduto_parla else "seduto")
		return
	if _playback.get_current_node() == "parla":
		_playback.travel("loco")


## Tiene un osso a una rotazione fissa, sopra all'animazione. Serve alla
## signora che stringe la borsa, a chi tiene il telefono all'orecchio, al
## vigile con la paletta.
func hold_bone(osso: String, euler_deg: Vector3, _peso: float = 1.0) -> void:
	var vero: String = str(OSSA.get(osso, osso))
	# `Quaternion` non si costruisce da un Vector3 di angoli: si passa da
	# una base.
	_tenute[vero] = Basis.from_euler(Vector3(
		deg_to_rad(euler_deg.x), deg_to_rad(euler_deg.y),
		deg_to_rad(euler_deg.z))).get_rotation_quaternion()


func release_bone(osso: String) -> void:
	_tenute.erase(str(OSSA.get(osso, osso)))


## **L'osso puntato** (0.64). `hold_bone` scrive una rotazione *locale*
## fissa, e sul pupo una rotazione locale fissa è la posa di riposo — a
## braccia aperte — più quei gradi: il braccio non va dove si pensava (vedi
## `passante_3d.gd`, e Borrelli col telefonino, che per sei versioni l'ha
## tenuto contro la coscia). Qui invece si dice **dove deve puntare** l'osso,
## nel verso del personaggio: avanti è −Z, su è +Y, la sua destra è +X.
## Ogni fotogramma, dopo l'animazione, l'osso viene girato quel tanto che
## basta a puntarci, partendo dalla posa che l'animazione gli ha dato: la
## torsione e tutto il resto restano vivi. Si puntano prima i padri (il
## braccio) e poi i figli (l'avambraccio), nell'ordine in cui si chiamano.
##
## Vale solo per il pupo, dove l'osso corre lungo il suo +Y (misurato:
## `POSA_PUPO` in `human_builder.gd`). Sugli altri scheletri il nome non si
## trova e non succede niente.
func punta_osso(osso: String, direzione: Vector3) -> void:
	var vero: String = str(OSSA.get(osso, osso))
	_puntate.erase(vero)
	_puntate[vero] = direzione.normalized()


func lascia_osso(osso: String) -> void:
	_puntate.erase(str(OSSA.get(osso, osso)))


func _process(delta: float) -> void:
	_misura_passo(delta)
	_passo_parlata(delta)
	if _scheletro == null:
		return
	for nome in _tenute:
		var i: int = _scheletro.find_bone(str(nome))
		if i < 0:
			continue
		_scheletro.set_bone_pose_rotation(i, _tenute[nome])
	if not _puntate.is_empty():
		_applica_puntate()


func _applica_puntate() -> void:
	var radice := _parti.get("root", null) as Node3D
	if radice == null or not radice.is_inside_tree():
		return
	# Dal verso del personaggio al verso dello scheletro (che dentro al
	# pupo sta girato di mezzo giro, e scalato).
	var verso: Basis = _scheletro.global_transform.basis.inverse() \
		* radice.global_transform.basis
	for nome in _puntate:
		var i: int = _scheletro.find_bone(str(nome))
		if i < 0:
			continue
		var voluta: Vector3 = (verso * (_puntate[nome] as Vector3)).normalized()
		var glob: Basis = _scheletro.get_bone_global_pose(i).basis.orthonormalized()
		var ora: Vector3 = glob.y.normalized()
		if ora.dot(voluta) > 0.99995:
			continue
		var girata: Basis = Basis(Quaternion(ora, voluta)) * glob
		var padre: int = _scheletro.get_bone_parent(i)
		var pb := Basis()
		if padre >= 0:
			pb = _scheletro.get_bone_global_pose(padre).basis.orthonormalized()
		_scheletro.set_bone_pose_rotation(i,
			(pb.inverse() * girata).orthonormalized().get_rotation_quaternion())
