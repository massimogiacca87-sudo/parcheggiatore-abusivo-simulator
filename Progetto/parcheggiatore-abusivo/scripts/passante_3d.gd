extends CharacterBody3D
## Passante
## Gente che non c'entra niente con le macchine.
##
## Non sono clienti, non pagano, non ti servono: camminano, si fermano a
## parlare, tirano dritto. Servono a una cosa sola — che il quartiere non
## sembri uno studio televisivo in cui esisti solo tu e chi ti deve dei
## soldi. Un posto è vivo quando ci sta gente che ha altro da fare.
##
## Ognuno ha un giro suo fra punti sparsi per la città, e ogni tanto si
## ferma. Se due passanti si incontrano fermi, si parlano.

const Human := preload("res://scripts/human_builder.gd")
const Tex := preload("res://scripts/textures.gd")
const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const ChiacchiereScript := preload("res://scripts/chiacchiere.gd")
const KO := preload("res://scripts/knockout.gd")
const Cammino := preload("res://scripts/cammino.gd")

## **'A gente cammina, nun trotta.**
## Erano 1,5–2,6 metri al secondo. Due e sei sono **nove chilometri
## all'ora**: è una corsetta, non una passeggiata, e nel BlendSpace cadeva
## a metà strada fra la camminata e il `Jog` — mezzo passo e mezza
## corsetta, che è un'andatura che non esiste. Un uomo che cammina per
## strada fa 1,2–1,4; uno che ha fretta 1,6.
const VELOCITA_MIN: float = 1.05
const VELOCITA_MAX: float = 1.60

# ---------------------------------------------------------------------------
# 'E MESTIERE
# ---------------------------------------------------------------------------
#
# **Nove passanti tutte uguale nun so' nove passanti: so' uno stampato nove
# vote.**
#
# Fino alla 0.53 la differenza fra un passante e l'altro erano tre sorteggi:
# il colore della camicia, la pancia, e se era calvo. Su nove persone in
# vista, tre variabili piccole danno nove figure che l'occhio legge come una
# sola — e infatti la citta' sembrava piena e non sembrava viva.
#
# Il pezzo che mancava non era **quanta** gente c'e', era **che cosa fa**.
# Una strada di quartiere si riconosce perche' ci passano mestieri diversi:
# uno col grembiule bianco che torna dal forno, uno in tuta blu con la
# cassetta, il prete, la signora con le buste, il turista che si ferma ogni
# tre metri a guardare in alto. Sono differenze che si vedono **da venti
# metri**, prima di distinguere una faccia, e sono quelle che contano.
#
# Ogni mestiere decide quattro cose: come e' vestito, cosa porta in mano,
# **quanto va veloce** e **quanto si ferma**. Le ultime due sono le piu'
# importanti e le meno vistose: un turista che cammina come un operaio e'
# ancora un manichino con la maglietta a fiori.
#
#   peso    quanto e' comune (si sommano, non fanno per forza 1)
#   veloce  moltiplicatore sulla velocita' base
#   ferma   moltiplicatore sulla sosta
const MESTIERE := [
	{
		"id": "quartiere", "peso": 30.0, "veloce": 1.0, "ferma": 1.0,
		"camicia": [Color(0.82, 0.80, 0.74), Color(0.32, 0.42, 0.56),
			Color(0.66, 0.34, 0.32), Color(0.36, 0.46, 0.36)],
		"pantalone": Color(0.22, 0.24, 0.30), "cosa": "busta",
		"dice": ["'A spesa nun se pò cchiù fa'.", "Ha chiuvuto tutt''a notte.",
			"E chille m'ha fatto aspettà n'ora!"],
	},
	{
		# Cammina piano, si ferma sempre, e guarda in alto: e' l'unico che
		# in una via si comporta come se fosse un museo.
		"id": "turista", "peso": 11.0, "veloce": 0.74, "ferma": 2.2,
		"camicia": [Color(0.92, 0.86, 0.34), Color(0.36, 0.76, 0.72),
			Color(0.92, 0.52, 0.32)],
		"pantalone": Color(0.78, 0.74, 0.62), "cosa": "machinetta",
		"dice": ["Ooooh! Beautiful!", "Excuse me… pizza? PIZZA?",
			"Is this Spaccanapoli? Ja?"],
	},
	{
		"id": "operaio", "peso": 13.0, "veloce": 1.18, "ferma": 0.6,
		"camicia": [Color(0.20, 0.34, 0.58), Color(0.26, 0.40, 0.62)],
		"pantalone": Color(0.18, 0.28, 0.46), "cosa": "cassetta",
		"dice": ["Mo' arrivo, mo' arrivo!", "Chillo 'o tubo s'è rutto n'ata vota.",
			"E dalle 'na mano, no?"],
	},
	{
		# Grembiule bianco e la teglia: torna dal forno, e a Napoli e' la
		# figura piu' riconoscibile che ci sia.
		"id": "pizzaiuolo", "peso": 8.0, "veloce": 1.1, "ferma": 0.7,
		"camicia": [Color(0.94, 0.93, 0.90)],
		"pantalone": Color(0.90, 0.90, 0.88), "cosa": "teglia",
		"dice": ["'O furno sta acceso!", "Doje margherite, subito!",
			"Chi 'e vò cavere?"],
	},
	{
		"id": "prevete", "peso": 5.0, "veloce": 0.86, "ferma": 1.5,
		"camicia": [Color(0.10, 0.10, 0.12)],
		"pantalone": Color(0.09, 0.09, 0.11), "cosa": "",
		"dice": ["Pace e bene.", "Dominus vobiscum.",
			"E figlio mio, pregate 'nu poco."],
	},
	{
		"id": "studente", "peso": 12.0, "veloce": 1.34, "ferma": 0.5,
		"camicia": [Color(0.24, 0.26, 0.32), Color(0.70, 0.24, 0.28),
			Color(0.30, 0.52, 0.40)],
		"pantalone": Color(0.24, 0.30, 0.44), "cosa": "zaino",
		"dice": ["Aggio 'a dà ll'esame, nun me parlà.", "Ma quanno maje!",
			"Frà, t'aggio scritto e nun m'hê risposto."],
	},
	{
		# Non fa niente e non ha fretta di farlo: e' quello appoggiato al
		# motorino che si gira a guardarti mentre lavori.
		"id": "guappo", "peso": 8.0, "veloce": 0.80, "ferma": 1.8,
		"camicia": [Color(0.10, 0.11, 0.13), Color(0.16, 0.14, 0.18)],
		"pantalone": Color(0.12, 0.12, 0.14), "cosa": "",
		"dice": ["Uè.", "…", "E tu che guarde?", "Overo? Overo overo?"],
	},
	{
		"id": "marenaro", "peso": 7.0, "veloce": 0.96, "ferma": 1.1,
		"camicia": [Color(0.30, 0.44, 0.56), Color(0.86, 0.86, 0.82)],
		"pantalone": Color(0.26, 0.28, 0.32), "cosa": "cascetta",
		"dice": ["Alice frische! Alice!", "'O mare stammatina steva bello.",
			"Doje chile? Te ne metto tre."],
	},
	{
		"id": "signora", "peso": 6.0, "veloce": 0.88, "ferma": 1.4,
		"camicia": [Color(0.62, 0.34, 0.48), Color(0.44, 0.30, 0.52),
			Color(0.72, 0.56, 0.34)],
		"pantalone": Color(0.30, 0.26, 0.30), "cosa": "busta",
		"dice": ["Mia figlia s'è laureata, sai?", "Uh, Maronna mia.",
			"'Sti guagliune 'e mo'…"],
	},
]

## Il mestiere sorteggiato, per la battuta e per il resto.
var mestiere: Dictionary = {}


static func _pesca_mestiere() -> Dictionary:
	var tot: float = 0.0
	for m in MESTIERE:
		tot += float(m["peso"])
	var r: float = randf() * tot
	for m in MESTIERE:
		r -= float(m["peso"])
		if r <= 0.0:
			return m
	return MESTIERE[0]


## Cosa si dicono fra loro passando. Niente che riguardi te: è proprio il
## punto.
const CHIACCHIERE := [
	"…e allora dico: ma tu 'o ssaje o nun 'o ssaje?",
	"Mia figlia s'è laureata, sai?",
	"'A spesa nun se pò cchiù fa'.",
	"Nun me parlà d''o Napule, nun me parlà.",
	"Aggio ditto a mammà ca vengo dimane.",
	"'O caldo… 'o caldo nun se sopporta.",
	"Ma chi t'ha visto e chi t'ha canusciuto.",
	"Statte buono, ce vedimmo.",
	"Ha chiuvuto tutt''a notte.",
	"E chille m'ha fatto aspettà n'ora!",
]

var tappe: Array = []

var _visual: Node3D
var _anim: Node = null
var _bubble: Node3D
var _idx: int = 0
## **'A strada** (0.59): i punti dove si gira per arrivare alla tappa,
## calcolati da `cammino.gd`. Prima si andava in linea d'aria.
var _strada: PackedVector3Array = PackedVector3Array()
var _i_strada: int = 0
## Per capire se si è piantato: dove stava all'ultimo controllo, da quanti
## controlli di fila non si muove, e quante strade nuove ha già provato.
var _ultimo_punto: Vector3 = Vector3.INF
var _conto_fermo: float = 0.0
var _secondi_fermo: int = 0
var _tentativi: int = 0
var _sosta: float = 0.0
var _velocita: float = 2.0
var _chiacchiera: float = 0.0


var _rng_parla := RandomNumberGenerator.new()
var _parlato: float = 0.0

## **'E ppassante mo cadono.**
##
## Il capo: "i png non muoiono dopo che li picchi". Aveva ragione — un
## passante colpito diceva "AAAH! Aiuto!" e **si metteva a correre**, e
## potevi rincorrerlo e menarlo per tutta la giornata senza che succedesse
## niente. Tre pugni e uno resta a terra: non è un pugile, è uno che
## tornava dalla spesa.
##
## E resta a terra per sempre (`0.0` = non si rialza). Un passante steso in
## mezzo alla strada è una cosa che il giocatore deve **vedere**, se no
## menare non costa niente.
const COLPI_PRIMA_CADE: int = 3
var _hp: int = COLPI_PRIMA_CADE
var _ko: Dictionary = KO.make_state()


func _ready() -> void:
	add_to_group("passanti")
	# Perché ci si possa parlare col tasto E: il player aggancia i bersagli
	# per gruppo, e "attivita" è quello che si può interrogare senza aprire
	# il pannello di un negozio.
	add_to_group("attivita")
	_rng_parla.randomize()
	collision_layer = 4
	collision_mask = 1
	# **'O cuorpo ca nun teneva** (0.59). Fino alla 0.58 qui non c'era
	# nessuna forma di collisione: il passante era un `CharacterBody3D` che
	# per il motore fisico non esisteva. Non sbatteva contro niente, e
	# siccome non toccava mai terra la gravità lo tirava giù senza fine —
	# due secondi dopo essere nato camminava **sotto** alla città, e
	# `prova_ntuppate` ne ha trovati a cinquanta chilometri di profondità.
	# Quelli che si vedevano per strada erano quelli appena nati.
	var forma := CollisionShape3D.new()
	var capsula := CapsuleShape3D.new()
	capsula.radius = 0.26
	capsula.height = 1.70
	forma.shape = capsula
	forma.position = Vector3(0, 0.85, 0)
	add_child(forma)
	floor_snap_length = 0.35
	_velocita = randf_range(VELOCITA_MIN, VELOCITA_MAX)
	_costruisci()
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 2.1, 0)
	add_child(_bubble)
	_idx = randi() % maxi(tappe.size(), 1)
	_sosta = randf_range(0.0, 4.0)
	# Chi nasce dentro a un palazzo (la città lo mette a tre metri da una
	# tappa, a caso) si sposta nella cella libera più vicina. Si fa a fine
	# fotogramma: la posizione la scrive chi lo crea, dopo `add_child`.
	_esci_se_dinto.call_deferred()


func _esci_se_dinto() -> void:
	var p: Vector3 = global_position
	var q: Vector3 = Cammino.vicino_libero(p)
	global_position = Vector3(q.x, maxf(p.y, 0.05), q.z)


## **'A voce d''o passante.**
##
## Un quartiere pieno di gente che apre e chiude fumetti in silenzio e' un
## quartiere di pesci. Non serve doppiare le battute: basta un verso, e il
## verso giusto e' quasi sempre lo stesso — uno che ti saluta. Ogni tanto
## invece esce un rutto, ed e' l'unica cosa che serve per far ridere.
##
## Il volume scende con la distanza: a venti metri e' una voce lontana che
## dice che il quartiere e' abitato, a tre e' uno che ti parla.
func _verso_di_bocca() -> void:
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null or not (pl is Node3D):
		return
	var d: float = global_position.distance_to((pl as Node3D).global_position)
	if d > 22.0:
		return
	var vol: float = lerpf(-6.0, -26.0, clampf(d / 22.0, 0.0, 1.0))
	var r: float = randf()
	if r < 0.10:
		SoundManager.play_uno(["rutto", "ruttino"], vol)
	elif r < 0.34:
		SoundManager.play_uno(["saluto", "saluto2"], vol,
			randf_range(0.86, 1.14))


func _costruisci() -> void:
	if mestiere.is_empty():
		mestiere = _pesca_mestiere()
	var camicie: Array = mestiere["camicia"]
	var anziano: bool = randf() < 0.35
	var femmina: bool = randf() < 0.34
	# Tre mestieri hanno un sesso solo, e non per gusto: un prete donna o
	# un pizzaiolo in gonna sarebbero due figure che a Napoli non si
	# incontrano, e la citta' smetterebbe di somigliare a se stessa.
	match str(mestiere["id"]):
		"prevete", "pizzaiuolo", "marenaro", "guappo":
			femmina = false
		"signora":
			femmina = true
			anziano = true
		"studente":
			anziano = false
	# La velocità la decide il mestiere: è la differenza che si legge da
	# lontano prima di qualsiasi vestito.
	_velocita *= float(mestiere["veloce"])
	# **A Napoli 'e panzune so' assaje.**
	#
	# Prima la pancia si tirava a sorte uniforme fra 0,1 e 0,95, e siccome
	# il corpo panzone parte da 0,62 ne usciva un panzone ogni tre. Il capo
	# dice — e ha ragione, basta scendere in strada — che in un vicolo di
	# Napoli sono molti di più. Adesso la sorte è a tre scaglioni pesati:
	# quasi metà della gente è panzuta, un sesto è secca, il resto sta in
	# mezzo.
	var dado: float = randf()
	var pancia: float
	if dado < 0.46:
		pancia = randf_range(0.66, 0.96)      # 'o panzone
	elif dado < 0.84:
		pancia = randf_range(0.28, 0.58)      # normale
	else:
		pancia = randf_range(0.04, 0.20)      # 'o sicco
	_visual = Node3D.new()
	add_child(_visual)
	var opts := {
		# Una su tre è una donna; per gli altri la corporatura la
		# sceglie la pancia (magro / normale / panzone).
		"corpo": "femmina" if femmina else "",
		"belly": pancia,
		"bald": (not femmina) and anziano and randf() < 0.6,
		"moustache": (not femmina) and randf() < 0.35,
		"hair": Color(0.76, 0.75, 0.72) if anziano \
			else Color(0.14, 0.11, 0.08),
	}
	var cuorpo: String = _che_cuorpo(femmina)
	if cuorpo != "":
		opts["modello"] = cuorpo
	var parts := Human.build(
		camicie[randi() % camicie.size()],
		mestiere["pantalone"],
		"",
		randf_range(1.58, 1.86),
		opts)
	_visual.add_child(parts["root"])
	if GameManager.tipo_giornata == "pioggia":
		_ombrello()
	_anim = parts.get("anim", null)

	_cosa_porta(parts.get("bones", {}))


## **'E cuorpe nuove p''e passanti** (0.59).
##
## Fino alla 0.58 tutti i passanti erano **lo stesso pupo** con la camicia
## di un altro colore: da vicino si vedeva che era la stessa faccia, lo
## stesso naso, lo stesso taglio di capelli, trenta volte. Il capo ha
## portato due pacchetti di persone animate — otto uomini in quattro
## vestiti (maglietta e pantaloncini, maniche lunghe, camicia, giacca e
## cravatta) e l'umano di Quaternius — e adesso sei uomini su dieci ne
## prendono uno. Il vestito lo sceglie il mestiere, come il colore: il
## guappo porta la giacca, il prete pure (nera), il pizzaiolo la camicia,
## il turista i pantaloncini, l'operaio le maniche lunghe o la maglietta
## dell'umano. Le donne restano del pupo: i due pacchetti sono di soli
## uomini.
##
## **E dalla 0.62 'e cuorpe 'e fore** (vedi `HumanBuilder.QUAT`): il signore
## in giacca per il guappo e lo studente, il ragazzo in maglietta per il
## quartiere e il turista, l'operaio col casco per l'operaio, il contadino
## col cappello per chi vende al mercato. E due donne, finalmente: una
## donna su tre non è più il pupo.
const CUORPE_MESTIERE := {
	"quartiere": ["casual", "maniche", "camicia", "umano", "quat_maglietta"],
	"turista": ["casual", "umano", "quat_maglietta"],
	"operaio": ["maniche", "umano", "quat_operaio", "quat_operaio"],
	"pizzaiuolo": ["camicia"],
	"prevete": ["giacca"],
	"studente": ["casual", "maniche", "umano", "quat_giacca"],
	"guappo": ["giacca", "camicia", "quat_giacca"],
	"marenaro": ["casual", "maniche", "quat_cafone"],
}


func _che_cuorpo(femmina: bool) -> String:
	if femmina:
		if randf() < 0.36:
			return str(Human.QUAT_DONNE[randi() % Human.QUAT_DONNE.size()])
		return ""
	if randf() < 0.4:
		return ""
	var scelte: Array = CUORPE_MESTIERE.get(str(mestiere.get("id", "")), [])
	if scelte.is_empty():
		return ""
	var c: String = str(scelte[randi() % scelte.size()])
	if c == "umano":
		return "umano_q"
	if c.begins_with("quat_"):
		return c
	return "omo_" + c + ("_liscio" if randf() < 0.5 else "")


## **Chello ca tene 'n mano.**
##
## Quattro scatole e un cilindro, e da venti metri sono quattro mestieri.
## La cassetta blu dell'operaio, la teglia larga del pizzaiolo, la cassetta
## piatta del pescivendolo, lo zaino dello studente: sono tutte forme
## diverse **in silhouette**, che è l'unico modo in cui si leggono a quella
## distanza. Il colore serve da vicino; la forma serve da lontano.
func _cosa_porta(bones: Dictionary) -> void:
	var cosa := str(mestiere["cosa"])
	if cosa == "" or not bones.has("hand_r"):
		return
	# Il quartiere porta la busta solo metà delle volte: chi torna dal bar
	# non ha niente in mano, ed è giusto così.
	if cosa == "busta" and randf() < 0.42:
		return

	var m := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	var tinta := Color(0.9, 0.9, 0.86)
	# **Sott'â mano è +Y, no −Y.** Misurato con `prova_manella`: sull'osso
	# `hand_r` l'asse lungo è la X (verso le dita) e il basso del mondo è
	# **+Y** (0,85 di prodotto scalare). Con −0,26 la busta della spesa
	# saliva all'altezza della spalla — ed era così da quando esiste, solo
	# che una busta chiara sopra a una spalla non la nota nessuno; una
	# cassetta degli attrezzi blu sì.
	var giu: float = 0.26
	match cosa:
		"busta":
			mesh.size = Vector3(0.30, 0.40, 0.18)
			tinta = [Color(0.9, 0.9, 0.86), Color(0.85, 0.3, 0.25),
				Color(0.3, 0.5, 0.75)][randi() % 3]
		"cassetta":
			# La cassetta degli attrezzi: bassa, larga, e pende dalla mano.
			mesh.size = Vector3(0.40, 0.20, 0.22)
			tinta = Color(0.18, 0.26, 0.44)
			giu = 0.22
		"teglia":
			# Le teglie sono impilate e si portano per il bordo, giu' lungo
			# il fianco: alte e strette, non un vassoio orizzontale.
			mesh.size = Vector3(0.40, 0.30, 0.40)
			tinta = Color(0.42, 0.40, 0.38)
			giu = 0.30
		"cascetta":
			mesh.size = Vector3(0.46, 0.13, 0.32)
			tinta = Color(0.86, 0.84, 0.78)
			giu = 0.26
		"zaino":
			# Lo zaino non sta in mano: sta sulla schiena, e per questo si
			# attacca allo `spine_02` invece che alla mano.
			mesh.size = Vector3(0.32, 0.40, 0.18)
			tinta = [Color(0.72, 0.24, 0.26), Color(0.22, 0.30, 0.52),
				Color(0.26, 0.30, 0.28)][randi() % 3]
			m.mesh = mesh
			m.material_override = Tex.flat(tinta, 0.85)
			# **'O petto e 'a capa nun tèneno 'o stesso verso.**
			#
			# Sull'osso della testa il davanti è −Z: la visiera del casco
			# del vigile sta a z = −0,158, ed è la faccia. Ho dato per
			# scontato che valesse anche per `spine_03`, e lo zaino è
			# uscito **sul petto** — un marsupio rosso in mezzo allo
			# sterno, visibilissimo nella prima foto. Su questo rig le due
			# ossa hanno assi diversi: qui dietro è −Z.
			m.position = Vector3(0.0, -0.13, -0.16)
			if bones.has("chest"):
				bones["chest"].add_child(m)
			return
		"machinetta":
			# La macchina fotografica al collo: piccola, nera, e sta ferma
			# sul petto — che su questo osso è +Z (vedi lo zaino sopra).
			mesh.size = Vector3(0.13, 0.09, 0.07)
			tinta = Color(0.08, 0.08, 0.09)
			m.mesh = mesh
			m.material_override = Tex.flat(tinta, 0.4, 0.6)
			m.position = Vector3(0.0, -0.04, 0.15)
			if bones.has("chest"):
				bones["chest"].add_child(m)
			return
	m.mesh = mesh
	m.position = Vector3(0, giu, 0)
	m.material_override = Tex.flat(tinta, 0.9)
	bones["hand_r"].add_child(m)
	# **E 'o braccio nun se tocca.**
	#
	# Qui c'era `hold_bone("shoulder_r", ...)` con due torsioni piccole,
	# ereditate dalla busta della spesa, e sembravano innocue. Non lo
	# sono: `hold_bone` scrive la posa **dopo** l'AnimationTree, quindi
	# non piega il braccio a partire dalla camminata — lo **congela**, e
	# lo congela vicino alla posa di riposo del rig, che è a braccia
	# aperte. In foto uscivano tre persone con la cassetta appesa alla
	# spalla e il braccio disteso di lato: la posa a T con un attrezzo
	# sopra.
	#
	# E' la stessa cosa che ha fatto scartare le braccia in prima persona
	# in questa stessa versione (vedi il fondo di `player_fps.gd`), e ci
	# sono ricascato lo stesso, nello stesso file, il giorno dopo. Adesso
	# l'affare pende dalla mano e la mano la muove la camminata: oscilla
	# insieme al passo, che e' anche l'unica cosa giusta.


func _physics_process(delta: float) -> void:
	# Chi sta a terra ci resta: niente giro, niente chiacchiere.
	if bool(_ko["down"]):
		KO.tick(_ko, _visual, delta)
		velocity = Vector3.ZERO
		move_and_slide()
		return
	_parlato = maxf(0.0, _parlato - delta)
	_chiacchiera = maxf(0.0, _chiacchiera - delta)
	if tappe.is_empty():
		return

	if _sosta > 0.0:
		_sosta -= delta
		_cammina(delta, 0.0)
		if _chiacchiera <= 0.0 and randf() < delta * 0.35:
			_chiacchiera = randf_range(6.0, 14.0)
			if _bubble:
				_bubble.say(_che_dice(), 2.4)
			_verso_di_bocca()
		return

	var meta: Vector3 = tappe[_idx]
	if _strada.is_empty():
		_nuova_strada()
	# Si punta al prossimo angolo della strada, non alla tappa: la tappa sta
	# quasi sempre dietro a un isolato.
	var prossimo: Vector3 = meta
	if _i_strada < _strada.size():
		prossimo = _strada[_i_strada]
		var manca := Vector2(prossimo.x - global_position.x,
			prossimo.z - global_position.z).length()
		# Si passa all'angolo dopo quando si è vicini a questo **e da qui
		# l'angolo dopo si vede dritto** (0.59): passando al prossimo a ottanta
		# centimetri dall'angolo, la linea nuova tagliava lo spigolo di
		# quello che c'era da girare — una vetrina, una macchina — e il
		# passante ci restava appiccicato.
		if manca < 0.8 and _i_strada < _strada.size() - 1:
			var dopo: Vector3 = _strada[_i_strada + 1]
			if manca < 0.25 or Cammino.si_vede_da(global_position, dopo):
				_i_strada += 1
				prossimo = dopo
	prossimo.y = global_position.y
	_verso(prossimo)
	_cammina(delta, _velocita)
	_se_s_e_piantato(delta)
	if Vector2(meta.x - global_position.x, meta.z - global_position.z).length() < 1.2:
		_nuova_tappa()
		# Quanto si ferma lo decide il mestiere: il turista sta due volte
		# e mezza più fermo dell'operaio, e su una piazza si vede.
		_sosta = randf_range(1.5, 7.0) * float(mestiere.get("ferma", 1.0))


## Una tappa nuova, diversa da quella dove si sta. La strada si calcola al
## primo passo, non qui: chi si ferma a chiacchierare non ne ha bisogno
## subito, e magari intanto la griglia è cambiata.
func _nuova_tappa() -> void:
	if tappe.is_empty():
		return
	var prima: int = _idx
	for _i in range(8):
		_idx = randi() % tappe.size()
		if _idx != prima and Cammino.raggiungibile(tappe[_idx]):
			break
	_strada = PackedVector3Array()
	_i_strada = 0
	_tentativi = 0


func _nuova_strada() -> void:
	_strada = Cammino.strada(global_position, tappe[_idx])
	_i_strada = 0
	if _strada.is_empty():
		# Nessuna strada: la tappa non si raggiunge da qui (o si sta dentro
		# a qualcosa). Si esce nella cella libera più vicina e si punta
		# dritti; se non basta, il controllo del piantato cambia tappa.
		var q: Vector3 = Cammino.vicino_raggiungibile(global_position)
		if q.distance_to(global_position) > 0.05:
			global_position = Vector3(q.x, global_position.y, q.z)
			_strada = Cammino.strada(global_position, tappe[_idx])
			_i_strada = 0
			if not _strada.is_empty():
				return
		# **'A tappa ca nun se raggiunge cchiù** (0.59). La tappa si sceglie
		# fra quelle raggiungibili, ma la griglia cambia dopo (la rassegna
		# delle cose arriva un secondo e mezzo dopo la città): una tappa buona
		# alla nascita può finire dietro a un muro. Tirare dritto verso di lei
		# vuol dire spingere contro quel muro finché il controllo del
		# piantato non se ne accorge. Si cambia tappa subito.
		if not Cammino.raggiungibile(tappe[_idx]):
			_nuova_tappa()
			_strada = Cammino.strada(global_position, tappe[_idx])
			_i_strada = 0
			if not _strada.is_empty():
				return
		_strada.append(tappe[_idx])


## **'O piantato.** Una volta al secondo si guarda quanto si è camminato.
## Due secondi fermi mentre si vorrebbe andare vuol dire che c'è qualcosa
## davanti che la griglia non conosce (un'auto che è appena parcheggiata,
## un altro passante, il giocatore): si ricalcola la strada da dove si sta.
## Al terzo tentativo si cambia tappa, e si esce da dove si è finiti.
func _se_s_e_piantato(delta: float) -> void:
	_conto_fermo += delta
	if _conto_fermo < 1.0:
		return
	_conto_fermo = 0.0
	var qui: Vector3 = global_position
	if _ultimo_punto == Vector3.INF:
		_ultimo_punto = qui
		return
	var fatto: float = Vector2(qui.x - _ultimo_punto.x, qui.z - _ultimo_punto.z).length()
	_ultimo_punto = qui
	if fatto > 0.25:
		_secondi_fermo = 0
		return
	# **Chi s'è piantato nun aspetta sei secondi** (0.59). Prima: due secondi
	# fermo per chiedere una strada nuova, e solo al terzo tentativo (sei
	# secondi) uno spostamento nella cella libera e una meta nuova. Sei
	# secondi di uno che spinge contro una panchina si vedono tutti. Adesso:
	# al primo secondo una strada nuova, al secondo un passo nella cella
	# libera più vicina e un'altra strada, al terzo si cambia meta.
	_secondi_fermo += 1
	match _secondi_fermo:
		1:
			_nuova_strada()
		2:
			# Prima fuori dalla cosa contro cui spinge (mezzo corpo di
			# margine), poi, se non basta, nella cella libera più vicina.
			var fuori: Vector3 = Passo.fore(qui, 0.5)
			if fuori.distance_to(qui) < 0.05:
				fuori = Cammino.vicino_raggiungibile(qui)
			if fuori.distance_to(qui) > 0.05:
				global_position = Vector3(fuori.x, qui.y, fuori.z)
			_nuova_strada()
		_:
			_secondi_fermo = 0
			var fuori2: Vector3 = Cammino.vicino_raggiungibile(qui)
			if fuori2.distance_to(qui) > 0.05:
				global_position = Vector3(fuori2.x, qui.y, fuori2.z)
			_nuova_tappa()


## **Due voci su tre so' 'e chelle d''o mestiere.**
##
## Non tutte: un elenco chiuso per mestiere si esaurisce in due minuti, e
## allora il pizzaiolo diventa un disco. Un terzo delle volte pesca dalle
## chiacchiere di tutti — che sono le cose che al quartiere si dicono a
## prescindere da cosa fai.
func _che_dice() -> String:
	var mie: Array = mestiere.get("dice", [])
	if mie.is_empty() or randf() < 0.34:
		return str(CHIACCHIERE[randi() % CHIACCHIERE.size()])
	return str(mie[randi() % mie.size()])


## **Si cammina verso 'o punto, no verso 'o naso** (0.59). Prima la
## velocità seguiva il davanti del modello, che si gira piano verso la meta
## (è quello che fa sembrare vera una curva). Con la strada a spigoli vuol
## dire allargare ogni curva di mezzo metro — e agli angoli degli isolati
## quel mezzo metro finiva dentro allo spigolo: sei passanti piantati negli
## angoli in due minuti. Adesso il corpo va dritto al punto e il modello lo
## segue girandosi con calma: la curva si vede lo stesso, lo spigolo no.
var _dir_voluta: Vector3 = Vector3.ZERO


func _cammina(delta: float, v: float) -> void:
	var avanti: Vector3 = -_visual.global_transform.basis.z if _visual \
		else -global_transform.basis.z
	if v > 0.0 and _dir_voluta.length_squared() > 0.5:
		avanti = _dir_voluta
	velocity.x = avanti.x * v
	velocity.z = avanti.z * v
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
	_dir_voluta = dir.normalized() if dir.length() > 0.05 else Vector3.ZERO
	if dir.length() > 0.05 and _visual:
		# forward(θ) = (−sinθ, 0, −cosθ): θ = atan2(−dir.x, −dir.z).
		_visual.rotation.y = lerp_angle(_visual.rotation.y,
			atan2(-dir.x, -dir.z),
			1.0 - exp(-6.0 * get_physics_process_delta_time()))


## Se li prendi a pugni scappano. Non fanno altro: non sono nemici, sono
## gente del quartiere.
## **Ci si parla.**
##
## Il tasto E era, fuori dalla piazza, un tasto morto: serviva a dirigere le
## auto e a comprare, e in mezzo alla strada non faceva niente. Adesso serve
## a parlare con la gente — che è la cosa che una città piena di passanti
## chiedeva da sé.
##
## Cosa ti dicono lo decide `chiacchiere.gd` in base a com'è messa la
## partita: il sospetto, l'ora, se stai lavorando, e se porti 'a coppola.
func get_interact_prompt(_da: Vector3) -> String:
	return "[E] parlace"


func player_interact() -> void:
	# Una battuta ogni tanto, non una raffica: premere E cinque volte di
	# fila non deve diventare una slot machine di frasi.
	if _parlato > 0.0:
		if _bubble:
			_bubble.say("...", 1.0)
		return
	_parlato = 2.6
	var b: Dictionary = ChiacchiereScript.battuta(_rng_parla, GameManager.notte)
	if _bubble:
		_bubble.say(str(b["testo"]), 3.0)
	ChiacchiereScript.suono(int(b["tono"]))
	# Chi ti manda a quel paese lo fa a voce alta, e a quel punto se ne va
	# per i fatti suoi invece di restare lì a fissarti.
	if int(b["tono"]) == ChiacchiereScript.Tono.OSTILE:
		_sosta = 0.0


func receive_punch(danno: int = 1) -> void:
	if bool(_ko["down"]):
		return
	GameManager.add_heat(16.0)
	# Uno che passava per i fatti suoi. E' il crimine che il quartiere
	# perdona di meno, perche' e' quello senza nessuna ragione.
	GameManager.violenza(1.0)
	SoundManager.pugno(-3.0)
	# **'A reazione, no 'o blocco.** Il colpo si vede addosso (clip
	# `Hit_Chest`/`Hit_Head` sopra alla locomozione) ma non toglie il
	# controllo: vedi `Animator.reagisci_colpo`.
	if _anim != null and _anim.has_method("reagisci_colpo"):
		_anim.reagisci_colpo(randf() < 0.4)
	_hp -= maxi(1, danno)
	if _hp <= 0:
		# **E resta 'n terra.** Prima un passante colpito scappava e basta:
		# lo potevi rincorrere e menare per tutta la giornata senza che
		# succedesse niente, e il gioco non ti diceva mai che avevi fatto
		# male a qualcuno. Adesso cade, ci resta, e il quartiere se ne
		# accorge — il calore sale del doppio.
		KO.lay_down(_ko, _visual, 0.0)
		GameManager.add_heat(22.0)
		GameManager.violenza(1.5)
		if _bubble:
			_bubble.say("…", 3.0)
		GameManager.avvisa_strada(
			"Hê stiso a uno ca passava. Mo t'hanno visto.")
		return
	if _bubble:
		_bubble.say("AAAH! Aiuto!", 2.4)
	_velocita = 5.2
	_sosta = 0.0
	_nuova_tappa()
	GameManager.avvisa_strada("Hê menato a uno ca passava. Bravo.")


## **L'ombrello (0.53).**
##
## Due pezzi: una calotta scura sopra alla testa e un bastoncino. Non
## serve che sia bello — un passante lo si vede da otto metri e per un
## secondo e mezzo — serve che da lontano la strada si legga come **una
## strada con gli ombrelli**, che e' la forma che ha una via napoletana
## quando piove.
##
## Uno su sei non ce l'ha: quello e' il tizio che e' uscito senza
## guardare il cielo, e senza di lui la fila di calotte nere sembrerebbe
## una parata invece di un acquazzone.
func _ombrello() -> void:
	if randf() < 0.17:
		return
	var tinte: Array[Color] = [
		Color(0.10, 0.10, 0.12), Color(0.12, 0.14, 0.22),
		Color(0.22, 0.10, 0.12), Color(0.14, 0.20, 0.16),
		Color(0.30, 0.28, 0.26),
	]
	var tinta: Color = tinte[randi() % tinte.size()]
	var alt: float = 1.92

	var calotta := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 0.52
	cm.height = 0.52
	# Mezza sfera: `is_hemisphere` taglia via la parte di sotto, che e'
	# quella che non si vede mai e che costerebbe la meta' dei triangoli.
	cm.is_hemisphere = true
	cm.radial_segments = 10
	cm.rings = 3
	calotta.mesh = cm
	calotta.position = Vector3(0.0, alt, 0.0)
	calotta.material_override = Tex.flat(tinta, 0.85)
	_visual.add_child(calotta)

	var manico := MeshInstance3D.new()
	var mm := CylinderMesh.new()
	mm.top_radius = 0.014
	mm.bottom_radius = 0.014
	mm.height = 0.62
	mm.radial_segments = 5
	manico.mesh = mm
	manico.position = Vector3(0.0, alt - 0.31, 0.0)
	manico.material_override = Tex.flat(Color(0.24, 0.18, 0.12), 0.7)
	_visual.add_child(manico)
