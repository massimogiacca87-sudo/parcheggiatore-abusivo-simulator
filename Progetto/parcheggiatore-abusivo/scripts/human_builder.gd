extends Node
class_name HumanBuilder
## HumanBuilder — 'o costruttore d''e personagge
##
## **Chello ca è cagnato ê 0.48, e pecché.**
##
## Fino alla 0.47 il corpo era una manciata di capsule montate su uno
## scheletro scritto da me, e le animazioni della libreria venivano
## *ritargettate* — tradotte da uno scheletro all'altro. Da lì venivano
## tutti i guai delle animazioni: le spalle storte, la clip "parla" che
## usciva a T, ogni clip nuova da misurare prima di accenderla.
##
## Adesso il verso è l'opposto. Il personaggio **è** il manichino della
## libreria di animazione (`assets/models/pupo.glb`), vestito e con la
## faccia dipinta da `tools/build_personaggi.py`, e si porta dietro le sue
## **quarantatré animazioni** già fatte per quello scheletro: camminata,
## corsa, sedersi, parlare, prendere una botta, cadere morto. Non c'è più
## niente da tradurre, quindi non c'è più niente che possa venire storto.
##
## L'interfaccia è rimasta la stessa, perché la chiamano quaranta posti:
##   root   : Node3D da appendere al personaggio
##   anim   : Animator (null se si usa un modello esterno)
##   bones  : Dictionary nome → BoneAttachment3D (head, chest, hand_l, hand_r)
##   legs   : [] — non serve più, l'andatura la fa l'AnimationTree
##   arms   : [attacco mano sx, attacco mano dx] — ci si appende la paletta,
##            la borsetta, il telefonino
##   head   : BoneAttachment3D della testa (occhiali, cappelli, coppola)

const Tex := preload("res://scripts/textures.gd")
const Models := preload("res://scripts/models.gd")
const AnimatorScript := preload("res://scripts/animator.gd")

const PUPO := "res://assets/models/pupo.scn"

## L'altezza del pupo nel file, in metri. Serve a scalare: chi chiede
## un personaggio alto 1,16 (una criatura) deve averlo alto 1,16.
const ALTEZZA_BASE := 1.79

## **'E quatto corporature.** `pupo.glb` porta dentro quattro corpi diversi
## appesi allo stesso scheletro: si accende quello che serve e gli altri tre
## si buttano. Costa un pelo di memoria in più (le mesh stanno tutte nel
## file) e zero disegno: a schermo ne va uno solo.
const CORPI := ["normale", "panzone", "magro", "femmina"]

const SKIN_TONES := [
	Color(0.91, 0.75, 0.60), Color(0.86, 0.68, 0.52),
	Color(0.78, 0.60, 0.44), Color(0.68, 0.50, 0.36),
]
const HAIR_COLORS := [
	Color(0.09, 0.07, 0.06), Color(0.17, 0.11, 0.07),
	Color(0.31, 0.20, 0.12), Color(0.52, 0.48, 0.44),
	Color(0.74, 0.72, 0.70),
]

## **'E facce d''o pupo nuovo** (0.66).
##
## Fino alla 0.65 il pupo aveva una faccia sola: due palle bianche, due
## stecchette per sopracciglia e una per bocca, e una calotta di capelli
## uguale per tutti — uomini, donne, guaglioni e nonne. Da vicino erano
## tutti fratelli. Il pupo nuovo porta dentro al file **tanti pezzi quanti
## sono i modi di avere una faccia a Napoli**, e ognuno si accende come i
## baffi: si tiene quello scelto, gli altri si buttano prima che il corpo
## entri in scena (non costano niente a schermo).
##
## I pezzi di geometria (oggetti nel file, `<pezzo>_<variante>`):
const CAPELLI := ["corti", "gellati", "ricci", "sfumati", "stempiati",
	"signora", "tuppo", "lunghi"]
const PALPEBRE := ["sveglie", "stanche", "arraggiate", "furbe"]
const SOPRACCIGLIA := ["dritte", "arraggiate", "preoccupate", "scettiche",
	"sottili"]
const NASI := ["piccolo", "grosso", "aquilino"]
## I pezzi dipinti (strati della faccia, `assets/textures/pupo/`): la
## bocca, la barba e le rughe si disegnano sulla pelle dallo shader
## `pupo_faccia.gdshader`. `""` = niente.
const BOCCHE := ["dritta", "cazzimma", "sorriso", "storta", "preoccupata",
	"rossetto"]
const BARBE := ["", "sfatta", "pizzetto", "barba", "basette"]
const RUGHE := ["", "stanco", "vecchio", "vecchia", "arraggiato"]
## I pezzi che dipendono dalla corporatura (il colletto del panzone non
## entra sul sicco): nel file si chiamano `<pezzo>_<corporatura>`, e si
## accendono con `opts[<pezzo>] = true`.
const EXTRA_CORPO := ["colletto", "cintura", "catenina"]
## Gli occhi: quasi tutti scuri, come in via Toledo.
const OCCHI := [
	Color(0.20, 0.12, 0.07), Color(0.20, 0.12, 0.07), Color(0.28, 0.17, 0.09),
	Color(0.28, 0.17, 0.09), Color(0.36, 0.28, 0.14), Color(0.26, 0.34, 0.20),
	Color(0.30, 0.40, 0.50),
]
const TEX_PUPO := "res://assets/textures/pupo/"
## I file degli strati, **scritti per intero** (BIBBIA, regola 8):
## `prova_asset` cerca i nomi nel testo, e un nome costruito con `%s` per
## lei è una texture che il gioco non usa.
const TEX_BOCCHE := {
	"dritta": "bocca_dritta.png", "cazzimma": "bocca_cazzimma.png",
	"sorriso": "bocca_sorriso.png", "storta": "bocca_storta.png",
	"preoccupata": "bocca_preoccupata.png", "rossetto": "bocca_rossetto.png",
}
const TEX_BARBE := {
	"sfatta": "barba_sfatta.png", "pizzetto": "barba_pizzetto.png",
	"barba": "barba_barba.png", "basette": "barba_basette.png",
}
const TEX_RUGHE := {
	"stanco": "rughe_stanco.png", "vecchio": "rughe_vecchio.png",
	"vecchia": "rughe_vecchia.png", "arraggiato": "rughe_arraggiato.png",
}
const SHADER_FACCIA := "res://assets/shaders/pupo_faccia.gdshader"

## Il caso delle facce ha il suo dado: il gioco non semina il caso globale,
## ma chi costruisce la città sì usa i suoi, e una faccia in più non deve
## spostare niente a nessuno.
static var _dado_facce: RandomNumberGenerator = null

## Le ossa a cui il gioco appende roba. A sinistra il nome che usa il
## gioco, a destra quello vero dello scheletro Unreal.
## **`arms` so' 'e mmane, no 'e spalle.** Dalla 0.48 in poi `parts["arms"]`
## contiene gli attacchi delle **mani**: chi ci appendeva le mostrine se le
## ritrovava in mano, e infatti il vigile portava i gradi sui polsi. Le
## spalle adesso hanno il loro attacco.
const ATTACCHI := {
	"head": "Head", "chest": "spine_03",
	"hand_l": "hand_l", "hand_r": "hand_r",
	"spalla_l": "upperarm_l", "spalla_r": "upperarm_r",
}

static var _scena: PackedScene = null


static func build(shirt_color: Color, pants_color: Color, model_name: String = "",
		height: float = 1.8, options: Dictionary = {}) -> Dictionary:
	if model_name != "":
		var custom := Models.spawn(model_name, height)
		if custom != null:
			var wrap := Node3D.new()
			wrap.add_child(custom)
			return {"root": wrap, "anim": null, "bones": {},
				"legs": [], "arms": [], "head": null}

	var opts := options.duplicate()
	# **'E cuorpe nuove** (0.59): chi chiede un modello che non è il pupo
	# della libreria passa di là. Vedi `_build_rig`.
	var modello_rig := str(opts.get("modello", ""))
	if modello_rig != "" and modello_rig != "pupo":
		var fatto := _build_rig(modello_rig, shirt_color, pants_color, height, opts)
		if not fatto.is_empty():
			return fatto
	if not opts.has("skin"):
		opts["skin"] = SKIN_TONES[randi() % SKIN_TONES.size()]
	if not opts.has("hair"):
		opts["hair"] = HAIR_COLORS[randi() % HAIR_COLORS.size()]
	var femmina: bool = _quale_corpo(opts) == "corpo_femmina"
	if not opts.has("bald"):
		opts["bald"] = randf() < 0.18 and not femmina
	if not opts.has("moustache"):
		opts["moustache"] = randf() < 0.32 and not femmina
	_scegli_faccia(opts, femmina, height < 1.45)

	if _scena == null:
		if not ResourceLoader.exists(PUPO):
			push_warning("pupo.glb nun ce sta: personaggio nun costruito")
			return {"root": Node3D.new(), "anim": null, "bones": {},
				"legs": [], "arms": [], "head": null}
		_scena = load(PUPO)

	var root := Node3D.new()
	root.name = "Pupo"
	var modello: Node3D = _scena.instantiate()
	# **'O manichino guarda a +Z, 'o gioco a −Z.**
	# In Blender la faccia sta verso −Y; l'esportatore glTF manda
	# (x, y, z) → (x, z, −y), quindi −Y diventa +Z. Il gioco invece usa
	# forward(θ) = (−sinθ, 0, −cosθ), cioè −Z. Mezzo giro e sono d'accordo.
	modello.rotation.y = PI
	var k: float = height / ALTEZZA_BASE
	modello.scale = Vector3.ONE * k
	root.add_child(modello)

	var scheletro: Skeleton3D = _trova_scheletro(modello)
	var suonatore: AnimationPlayer = _trova_player(modello)
	_scegli_pezzi(modello, opts)
	_vesti(modello, shirt_color, pants_color, opts)

	var bones := {}
	var head_att: Node3D = null
	if scheletro != null:
		for chiave in ATTACCHI:
			var osso: String = str(ATTACCHI[chiave])
			var idx: int = scheletro.find_bone(osso)
			if idx < 0:
				continue
			var att := BoneAttachment3D.new()
			att.name = "att_" + chiave
			att.bone_name = osso
			scheletro.add_child(att)
			bones[chiave] = att
			if chiave == "head":
				head_att = att

	var parti := {
		"root": root, "bones": bones, "head": head_att,
		"legs": [], "arms": [bones.get("hand_l"), bones.get("hand_r")],
		"scheletro": scheletro, "player": suonatore, "scala": k,
	}

	# **'A clip fissa** (0.59). Chi fa una cosa sola per tutta la partita —
	# chi guida il motorino, chi sta assettato a guardare — non ha bisogno
	# dell'albero delle animazioni: basta la clip giusta in ciclo, partita
	# da un punto a caso così due vicini non respirano insieme.
	var fissa := str(opts.get("clip", ""))
	if fissa != "" and suonatore != null:
		_clip_fissa(suonatore, fissa)
		parti["anim"] = null
		return parti

	if opts.get("animate", true) and suonatore != null:
		var anim: Node = AnimatorScript.new()
		anim.name = "Animator"
		root.add_child(anim)
		anim.setup(parti)
		parti["anim"] = anim
	else:
		parti["anim"] = null
	return parti


# ---------------------------------------------------------------------------
# 'E CUORPE NUOVE (0.59)
# ---------------------------------------------------------------------------
#
# Il capo ha portato due pacchetti di persone animate: gli *Animated Men*
# low poly (otto uomini, undici clip) e l'*Animated Human* di Quaternius
# (un corpo con sei vestiti, sette clip). Sono scheletri diversi da quello
# del pupo: altri nomi delle ossa, altre clip, altra scala nel file (cento
# volte e sessantanove volte più grandi, perché vengono da Blender in
# centimetri). Il resto del gioco non deve saperlo: chiede `build()` e
# riceve lo stesso dizionario di sempre — `root`, `anim`, `bones`.
#
# Tre cose da tradurre, e sono le tre cose che alla 0.47 avevano rovinato
# le animazioni quando si tentava di tradurre le clip da uno scheletro
# all'altro. Qui **non si traduce nessuna clip**: ogni corpo usa le sue.
# Si traducono solo i nomi:
#
# 1. **'e clip** — `set_speed(1.35)` sul pupo vuol dire `Walk`, sugli
#    omini pure, sull'umano pure; ma la corsa è `Sprint` sul pupo e `Run`
#    sugli altri, e chi si siede usa `Sitting_Idle` o `Sitting`. La tabella
#    `clip` di ogni scheletro la passa all'animatore.
# 2. **'e ossa** — la mano destra è `hand_r`, `Palm.R` o `RightHand`.
# 3. **'o verso d''e ossa** — ed è la parte sottile. Il gioco appende la
#    busta della spesa alla mano con uno spostamento *misurato sul pupo*
#    («sotto alla mano è +Y»). Sulle ossa degli altri scheletri +Y punta da
#    un'altra parte, e la busta usciva di lato, dritta come una bandiera.
#    Quindi fra l'osso e la roba appesa si mette un **adattatore**: un nodo
#    girato in modo che, a riposo, i suoi assi siano esattamente quelli
#    dell'osso del pupo nella stessa posa. Gli spostamenti scritti per il
#    pupo valgono così per tutti, senza toccare una riga di chi appende.
#    La posa di riferimento è la clip `Idle` al tempo zero, calcolata dalle
#    tracce (senza far girare niente): la posa di riposo dei file non va
#    bene, perché è una T in uno e una T storta di quarantatré gradi
#    nell'altro.

## Gli assi delle ossa d'aggancio del **pupo** nella clip `Idle` a t=0,
## nello spazio del modello grezzo (+Z davanti). Misurati da
## `tools/prova_adattatori.gd`.
const POSA_PUPO := {
	"head": [Vector3(0.998, 0.048, 0.046), Vector3(-0.059, 0.961, 0.270), Vector3(-0.031, -0.272, 0.962)],
	"chest": [Vector3(0.973, 0.001, 0.230), Vector3(-0.057, 0.970, 0.236), Vector3(-0.223, -0.243, 0.944)],
	"hand_l": [Vector3(-0.875, -0.244, -0.418), Vector3(0.029, -0.889, 0.457), Vector3(-0.483, 0.388, 0.785)],
	"hand_r": [Vector3(-0.985, 0.173, -0.007), Vector3(-0.154, -0.858, 0.489), Vector3(0.079, 0.483, 0.872)],
	"spalla_l": [Vector3(-0.903, -0.302, -0.307), Vector3(0.376, -0.900, -0.220), Vector3(-0.210, -0.314, 0.926)],
	"spalla_r": [Vector3(-0.864, 0.387, -0.322), Vector3(-0.210, -0.858, -0.469), Vector3(-0.458, -0.337, 0.823)],
}

## Gli scheletri. `altezza` è dalla pianta del piede alla cima della testa,
## in unità del file (si misura con `prova_adattatori`).
const RIG := {
	"omo": {
		"altezza": 4.74,
		"ossa": {"head": "Head", "chest": "Torso", "hand_l": "Palm.L",
			"hand_r": "Palm.R", "spalla_l": "UpperArm.L", "spalla_r": "UpperArm.R"},
		# **'E mosse d''o pupo** (0.62): quello che il pacchetto non ha
		# (parlare, accovacciarsi, incassare, indicare, guidare) viene dalla
		# libreria `ual`, tradotta da `tools/retarget_ual.gd`.
		"clip": {"idle": "Idle", "walk": "Walk", "jog": "ual/Jog_Fwd", "run": "Run",
			"crouch": "ual/Crouch_Idle", "crouch_walk": "ual/Crouch_Fwd",
			"morto": "Death", "seduto": "Sitting",
			"seduto_parla": "ual/Sitting_Talking", "parla": "ual/Idle_Talking",
			"punch": "Punch", "jab": "ual/Punch_Jab", "pugno": "Punch",
			"pugno_sinistro": "ual/Punch_Jab", "coltellata": "SwordSlash",
			"colpo": "ual/Hit_Chest", "colpo_capa": "ual/Hit_Head",
			"point": "ual/Interact", "shrug": "ual/PickUp_Table",
			"guida": "ual/Driving", "applaude": "Clapping",
			"lavora": "ual/Fixing_Kneeling"},
		"ual": "res://assets/models/omo_ual.res",
	},
	# (0.62) 'E cuorpe 'e fore: vedi `QUAT`. L'altezza è dalla pianta del
	# piede a `Head_end` nella `Idle_Neutral` (misurata: 1,83).
	"quat": {
		"altezza": 1.83,
		"ossa": {"head": "Head", "chest": "Chest", "hand_l": "Wrist.L",
			"hand_r": "Wrist.R", "spalla_l": "UpperArm.L", "spalla_r": "UpperArm.R"},
		"clip": {"idle": "Idle_Neutral", "walk": "Walk", "jog": "ual/Jog_Fwd",
			"run": "Run", "crouch": "ual/Crouch_Idle", "crouch_walk": "ual/Crouch_Fwd",
			"morto": "Death", "seduto": "ual/Sitting_Idle",
			"seduto_parla": "ual/Sitting_Talking", "parla": "ual/Idle_Talking",
			"punch": "Punch_Right", "jab": "Punch_Left", "pugno": "Punch_Right",
			"pugno_sinistro": "Punch_Left", "coltellata": "ual/Sword_Attack",
			"colpo": "HitRecieve", "colpo_capa": "HitRecieve_2",
			"point": "Interact", "shrug": "ual/PickUp_Table",
			"guida": "ual/Driving", "applaude": "Wave",
			"lavora": "ual/Fixing_Kneeling"},
		"ual": "res://assets/models/quat_ual.res",
	},
	"umano_q": {
		"altezza": 5.24,
		"ossa": {"head": "Head", "chest": "Spine2", "hand_l": "LeftHand",
			"hand_r": "RightHand", "spalla_l": "LeftArm", "spalla_r": "RightArm"},
		# **`Fermo`, no `Idle`** (0.60): vedi `_prepara_fermo`. **E dalla
		# 0.62 manco `Fermo`**: 'o riposo vero è l'`Idle` d''o pupo, tradotto
		# (`ual/Idle`). `Fermo` resta per misurare gli adattatori delle mani.
		"clip": {"idle": "ual/Idle", "walk": "Walk", "jog": "ual/Jog_Fwd", "run": "Run",
			"crouch": "ual/Crouch_Idle", "crouch_walk": "ual/Crouch_Fwd",
			"morto": "Death", "seduto": "ual/Sitting_Idle",
			"seduto_parla": "ual/Sitting_Talking", "parla": "ual/Idle_Talking",
			"punch": "Punch", "jab": "ual/Punch_Jab", "pugno": "Punch",
			"pugno_sinistro": "ual/Punch_Jab", "coltellata": "ual/Sword_Attack",
			"colpo": "ual/Hit_Chest", "colpo_capa": "ual/Hit_Head",
			"point": "ual/Interact", "shrug": "ual/PickUp_Table",
			"guida": "ual/Driving", "applaude": "ual/Idle_Talking",
			"lavora": "Working"},
		"ual": "res://assets/models/umano_q_ual.res",
	},
}

## **'E cuorpe 'e fore** (0.62, asset esterni). Sei persone animate dalla
## biblioteca esterna (Poly Pizza, Quaternius "Ultimate Animated Character
## Pack", CC0): il signore in giacca e cravatta, il ragazzo in maglietta,
## l'operaio col casco giallo, il contadino col cappello di paglia e due
## donne. Stesso scheletro per tutti e sei (`CharacterArmature`, parente di
## quello degli omini), 24 clip loro — e le mosse del pupo tradotte da
## `tools/retarget_ual.gd` in `quat_ual.res`. Sono le prime **donne** che
## non sono il pupo: i pacchetti della 0.59 erano di soli uomini.
##
## I file restano nella biblioteca (`assets/esterni/modelli/npc_animati/`);
## le clip hanno il prefisso `CharacterArmature|`, che si toglie la prima
## volta che il corpo si costruisce (`_alias_quat`).
const QUAT := {
	"quat_giacca": "res://assets/esterni/modelli/npc_animati/Business_Man_JFrLIKqvCH.glb",
	"quat_maglietta": "res://assets/esterni/modelli/npc_animati/Casual_Character_kZ3DmIoGip.glb",
	"quat_operaio": "res://assets/esterni/modelli/npc_animati/Worker_Yg2bQZO6Hj.glb",
	"quat_cafone": "res://assets/esterni/modelli/npc_animati/Farmer_7pn3R6hPvE.glb",
	"quat_donna_verde": "res://assets/esterni/modelli/npc_animati/Animated_Woman_nIItLV9nxS.glb",
	"quat_donna_bionda": "res://assets/esterni/modelli/npc_animati/Animated_Woman_qJ2gsTUBHL.glb",
}
const QUAT_DONNE := ["quat_donna_verde", "quat_donna_bionda"]
## Le clip che girano in tondo (il file le ha tutte "una volta sola").
const QUAT_CICLI := ["Idle", "Idle_Neutral", "Walk", "Run", "Run_Back",
	"Run_Left", "Run_Right", "Idle_Sword", "Idle_Gun", "Wave"]

static var _librerie_ual: Dictionary = {}


## Aggiunge al corpo la libreria delle mosse del pupo tradotte (0.62).
static func _aggiungi_ual(ap: AnimationPlayer, percorso: String) -> void:
	if ap == null or percorso == "" or ap.has_animation_library("ual"):
		return
	if not _librerie_ual.has(percorso):
		_librerie_ual[percorso] = load(percorso) if ResourceLoader.exists(percorso) else null
	var lib: AnimationLibrary = _librerie_ual[percorso]
	if lib != null:
		ap.add_animation_library("ual", lib)


## Gli otto uomini low poly (quattro vestiti, due modi di fare le facce).
const OMINI := ["omo_casual", "omo_maniche", "omo_camicia", "omo_giacca",
	"omo_casual_liscio", "omo_maniche_liscio", "omo_camicia_liscio",
	"omo_giacca_liscio"]
## Le sei tinte dell'umano di Quaternius (tre di pelle chiara, tre scura).
const TINTE_UMANO := 6

static var _scene_rig: Dictionary = {}
static var _adattatori: Dictionary = {}   # "modello:chiave" → Basis


static func rig_di(modello: String) -> String:
	if modello.begins_with("quat_"):
		return "quat"
	return "umano_q" if modello.begins_with("umano_q") else "omo"


## Le clip dei corpi `quat` senza il prefisso `CharacterArmature|`, e i
## cicli accesi. La libreria è quella del file, condivisa da tutti i corpi
## dello stesso modello: si sistema una volta sola.
static func _alias_quat(ap: AnimationPlayer) -> void:
	if ap == null or not ap.has_animation_library(""):
		return
	var lib: AnimationLibrary = ap.get_animation_library("")
	if lib.has_animation("Idle_Neutral"):
		return
	for nome in lib.get_animation_list():
		var n: String = str(nome)
		var k: int = n.find("|")
		if k < 0:
			continue
		var corto: String = n.substr(k + 1)
		if lib.has_animation(corto):
			continue
		var a: Animation = lib.get_animation(n)
		if QUAT_CICLI.has(corto):
			a.loop_mode = Animation.LOOP_LINEAR
		lib.add_animation(corto, a)


## I vestiti dei corpi `quat`: sono disegnati, e restano i loro. Si cambia
## solo il colore del pezzo grande — la giacca del signore, la maglietta del
## ragazzo — così due signori in giacca non sono gemelli.
const QUAT_TINTA := {"Suit": "pantaloni", "White": "camicia"}


static func _vesti_quat(m: Node3D, modello: String, camicia: Color,
		pantaloni: Color) -> void:
	if not (modello == "quat_giacca" or modello == "quat_maglietta"):
		return
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var me: Mesh = (mi as MeshInstance3D).mesh
		if me == null:
			continue
		for k in me.get_surface_count():
			var mat: Material = me.surface_get_material(k)
			if not (mat is StandardMaterial3D) or not QUAT_TINTA.has(mat.resource_name):
				continue
			var nuovo: StandardMaterial3D = (mat as StandardMaterial3D).duplicate()
			var quale: String = str(QUAT_TINTA[mat.resource_name])
			nuovo.albedo_color = (pantaloni if quale == "pantaloni" else camicia)
			(mi as MeshInstance3D).set_surface_override_material(k, nuovo)


static func _build_rig(modello: String, camicia: Color, pantaloni: Color,
		height: float, opts: Dictionary) -> Dictionary:
	var percorso := "res://assets/models/%s.scn" % modello
	if QUAT.has(modello):
		percorso = str(QUAT[modello])
	if not _scene_rig.has(modello):
		if not ResourceLoader.exists(percorso):
			return {}
		_scene_rig[modello] = load(percorso)
	var ps: PackedScene = _scene_rig[modello]
	if ps == null:
		return {}
	var id_rig := rig_di(modello)
	var rig: Dictionary = RIG[id_rig]
	var root := Node3D.new()
	root.name = "Pupo"
	var m: Node3D = ps.instantiate()
	# Guardano a +Z come il pupo: mezzo giro.
	m.rotation.y = PI
	var k: float = height / float(rig["altezza"])
	m.scale = Vector3.ONE * k
	root.add_child(m)
	var scheletro: Skeleton3D = _trova_scheletro(m)
	var suonatore: AnimationPlayer = _trova_player(m)
	if id_rig == "umano_q" and suonatore != null:
		_prepara_fermo(suonatore)
	if id_rig == "quat":
		_alias_quat(suonatore)
	_aggiungi_ual(suonatore, str(rig.get("ual", "")))
	if id_rig == "omo":
		_vesti_omo(m, camicia, pantaloni, opts)
	elif id_rig == "quat":
		_vesti_quat(m, modello, camicia, pantaloni)
	else:
		_vesti_umano(m, camicia, pantaloni, opts)

	var bones := {}
	var head_att: Node3D = null
	if scheletro != null:
		var ossa: Dictionary = rig["ossa"]
		for chiave in ossa:
			var osso: String = str(ossa[chiave])
			var idx: int = scheletro.find_bone(osso)
			if idx < 0:
				continue
			var att := BoneAttachment3D.new()
			att.name = "att_" + str(chiave)
			att.bone_name = osso
			scheletro.add_child(att)
			var ad := Node3D.new()
			ad.name = "adattatore"
			ad.transform = Transform3D(_adattatore(modello, str(chiave), m,
				scheletro, suonatore, osso), Vector3.ZERO)
			att.add_child(ad)
			bones[chiave] = ad
			if chiave == "head":
				head_att = ad

	var parti := {
		"root": root, "bones": bones, "head": head_att,
		"legs": [], "arms": [bones.get("hand_l"), bones.get("hand_r")],
		"scheletro": scheletro, "player": suonatore, "scala": k,
		"rig": id_rig, "clip": rig["clip"],
	}
	var fissa := str(opts.get("clip", ""))
	if fissa != "" and suonatore != null:
		# Il nome della clip arriva col nome del pupo (`Driving`,
		# `Sitting_Idle`): si traduce con la stessa tabella dell'animatore.
		# Se invece è già il nome di una clip di questo corpo (`Working`
		# dell'umano, `Clapping` degli omini) si usa quella.
		var nome_clip: String = fissa if suonatore.has_animation(fissa) \
			else _clip_nome_rig(fissa, rig["clip"])
		_clip_fissa(suonatore, nome_clip)
		parti["anim"] = null
		return parti
	if opts.get("animate", true) and suonatore != null:
		var anim: Node = AnimatorScript.new()
		anim.name = "Animator"
		root.add_child(anim)
		anim.setup(parti)
		parti["anim"] = anim
	else:
		parti["anim"] = null
	return parti


## Una clip chiesta col nome del pupo, tradotta per un altro scheletro.
static func _clip_nome_rig(clip_pupo: String, mappa: Dictionary) -> String:
	for chiave in AnimatorScript.CLIP:
		if str(AnimatorScript.CLIP[chiave]) == clip_pupo and mappa.has(chiave):
			return str(mappa[chiave])
	return str(mappa.get("idle", "Idle"))


## **'O fermo 'e ll'umano** (0.60).
##
## La clip `Idle` del pacchetto di Quaternius non è una persona che aspetta:
## è uno **in guardia**. Ginocchia piegate, un piede avanti e uno dietro, il
## busto girato di tre quarti e le braccia staccate dai fianchi, come chi
## sta per fare a botte. Visto da vicino è la «posa rigida» segnata alla
## chiusura della 0.59: la gente ferma agli angoli sembrava pronta a menare.
##
## Una clip nuova non c'è, e tradurre l'`Idle` del pupo su questo scheletro
## è proprio la cosa che ha rovinato la 0.47 — quindi la posa si costruisce
## **con le clip di questo corpo**. La base è la camminata nel fotogramma
## in cui i due piedi stanno sotto al corpo (`FERMO_BASE_T`, misurato: le
## punte dei piedi a meno di un centimetro l'una dall'altra, tutte e due a
## terra), cioè un uomo dritto con le braccia giù. Sopra ci va la **vita**
## dell'`Idle`: non la sua posa, il suo *movimento* — per ogni osso la
## differenza fra l'`Idle` al tempo t e l'`Idle` al tempo zero, pesata
## (`FERMO_PESI`). La testa si guarda intorno quasi quanto nell'originale,
## il busto respira, le braccia dondolano appena; le gambe stanno ferme,
## perché un piede che scivola si vede più di tutto il resto.
##
## Si costruisce una volta e si aggiunge alla libreria del modello, che è
## condivisa da tutte le istanze: dal secondo umano in poi c'è già.
const FERMO_BASE_T: float = 0.567
const FERMO_PASSO: float = 0.1
const FERMO_PESI := {
	"Hips": 0.25, "Spine": 0.55, "Spine1": 0.55, "Spine2": 0.55,
	"Neck": 0.8, "Head": 0.8,
	"LeftShoulder": 0.45, "RightShoulder": 0.45,
	"LeftArm": 0.4, "RightArm": 0.4, "LeftForeArm": 0.4, "RightForeArm": 0.4,
	"LeftHand": 0.35, "RightHand": 0.35,
}


static func _prepara_fermo(ap: AnimationPlayer) -> void:
	if ap.has_animation("Fermo") or not ap.has_animation("Idle") \
			or not ap.has_animation("Walk"):
		return
	var idle: Animation = ap.get_animation("Idle")
	var walk: Animation = ap.get_animation("Walk")
	var f := Animation.new()
	f.length = idle.length
	f.loop_mode = Animation.LOOP_LINEAR
	for k in walk.get_track_count():
		var tipo: int = walk.track_get_type(k)
		var percorso: NodePath = walk.track_get_path(k)
		var nuova: int = f.add_track(tipo)
		f.track_set_path(nuova, percorso)
		if tipo == Animation.TYPE_POSITION_3D:
			f.position_track_insert_key(nuova, 0.0,
				walk.position_track_interpolate(k, FERMO_BASE_T))
		elif tipo == Animation.TYPE_SCALE_3D:
			f.scale_track_insert_key(nuova, 0.0,
				walk.scale_track_interpolate(k, FERMO_BASE_T))
		elif tipo == Animation.TYPE_ROTATION_3D:
			var base: Quaternion = walk.rotation_track_interpolate(k, FERMO_BASE_T)
			var osso: String = str(percorso.get_concatenated_subnames())
			var peso: float = float(FERMO_PESI.get(osso, 0.0))
			var ki: int = idle.find_track(percorso, Animation.TYPE_ROTATION_3D)
			if peso <= 0.0 or ki < 0:
				f.rotation_track_insert_key(nuova, 0.0, base)
				continue
			var zero: Quaternion = idle.rotation_track_interpolate(ki, 0.0)
			var t: float = 0.0
			while t <= f.length + 0.0001:
				var ora: Quaternion = idle.rotation_track_interpolate(ki,
					minf(t, idle.length))
				var scarto: Quaternion = (zero.inverse() * ora).normalized()
				var q: Quaternion = (base * Quaternion.IDENTITY.slerp(scarto,
					peso)).normalized()
				f.rotation_track_insert_key(nuova, t, q)
				t += FERMO_PASSO
		else:
			f.remove_track(nuova)
	var lib: AnimationLibrary = ap.get_animation_library(
		ap.find_animation_library(idle))
	if lib != null and not lib.has_animation("Fermo"):
		lib.add_animation("Fermo", f)


## **L'adattatore** di un osso: la rotazione (e la scala) da mettere fra
## l'osso e la roba appesa perché i suoi assi, nella posa `Idle` a t=0,
## coincidano con quelli dell'osso del pupo nella stessa posa. Si calcola
## una volta per modello e per osso e si tiene.
static func _adattatore(modello: String, chiave: String, m: Node3D,
		sk: Skeleton3D, ap: AnimationPlayer, osso: String) -> Basis:
	var k := modello + ":" + chiave
	if _adattatori.has(k):
		return _adattatori[k]
	var b := Basis()
	# La posa di riferimento è quella in cui il corpo sta **fermo**: per
	# l'umano di Quaternius dalla 0.60 è `Fermo`, non più `Idle`.
	var riposo: String = "Fermo" if ap != null and ap.has_animation("Fermo") else "Idle"
	# (0.62) I corpi `quat` stanno fermi in `Idle_Neutral` (la loro `Idle`
	# molleggia sulle gambe).
	if riposo == "Idle" and ap != null and ap.has_animation("Idle_Neutral"):
		riposo = "Idle_Neutral"
	if POSA_PUPO.has(chiave) and ap != null and ap.has_animation(riposo):
		var posa: Transform3D = posa_osso(m, sk, ap, ap.get_animation(riposo), osso)
		var s: float = posa.basis.get_scale().x
		var mia: Basis = posa.basis.orthonormalized()
		var assi: Array = POSA_PUPO[chiave]
		var voluta := Basis(assi[0], assi[1], assi[2]).orthonormalized()
		b = (mia.inverse() * voluta).scaled(Vector3.ONE / maxf(0.0001, s))
	_adattatori[k] = b
	return b


## Dove sta un osso, nello spazio del modello `m` (scala del file
## compresa), nella clip `anim` al tempo zero. Si calcola dalle tracce,
## risalendo la catena delle ossa: non serve che il modello stia
## nell'albero né che l'animazione giri.
static func posa_osso(m: Node3D, sk: Skeleton3D, ap: AnimationPlayer,
		anim: Animation, osso: String) -> Transform3D:
	var catena: Array = []
	var i: int = sk.find_bone(osso)
	while i >= 0:
		catena.push_front(i)
		i = sk.get_bone_parent(i)
	var nodo_t := Transform3D()
	var n: Node = sk
	while n != null and n != m:
		nodo_t = (n as Node3D).transform * nodo_t
		n = n.get_parent()
	var radice_anim: Node = ap.get_node_or_null(ap.root_node)
	var percorso_sk: String = str(radice_anim.get_path_to(sk)) if radice_anim else "Skeleton3D"
	var t := Transform3D()
	for b in catena:
		var nome := sk.get_bone_name(b)
		var rest: Transform3D = sk.get_bone_rest(b)
		var pos: Vector3 = rest.origin
		var rot: Quaternion = rest.basis.get_rotation_quaternion()
		var sc: Vector3 = rest.basis.get_scale()
		var traccia := NodePath(percorso_sk + ":" + nome)
		var tp := anim.find_track(traccia, Animation.TYPE_POSITION_3D)
		var tr := anim.find_track(traccia, Animation.TYPE_ROTATION_3D)
		var ts := anim.find_track(traccia, Animation.TYPE_SCALE_3D)
		if tp >= 0:
			pos = anim.position_track_interpolate(tp, 0.0)
		if tr >= 0:
			rot = anim.rotation_track_interpolate(tr, 0.0)
		if ts >= 0:
			sc = anim.scale_track_interpolate(ts, 0.0)
		t = t * Transform3D(Basis(rot).scaled(sc), pos)
	return nodo_t * t


## Gli omini: ogni superficie porta il nome della sua zona nel file
## (`Skin`, `Shirt`, `Pants`…), come le superfici del pupo. Si vestono
## con i colori chiesti; gli occhi e la cravatta restano come sono.
static func _vesti_omo(m: Node3D, camicia: Color, pantaloni: Color,
		opts: Dictionary) -> void:
	var pelle := Color(opts.get("skin", SKIN_TONES[randi() % SKIN_TONES.size()]))
	var capelli := Color(opts.get("hair", HAIR_COLORS[randi() % HAIR_COLORS.size()]))
	var colori := {
		"Skin": pelle, "Hair": capelli, "Hair2": capelli.darkened(0.15),
		"Shirt": camicia, "Shirt2": camicia.lightened(0.25),
		"Pants": pantaloni, "Socks": Color(0.12, 0.12, 0.13),
		"Shoes": Color(0.10, 0.09, 0.09), "Details": camicia.darkened(0.35),
	}
	var lista: Array = []
	_mesh_di(m, lista)
	for mi in lista:
		var mesh_i: MeshInstance3D = mi
		if mesh_i.mesh == null:
			continue
		for i in range(mesh_i.mesh.get_surface_count()):
			var base: Material = mesh_i.mesh.surface_get_material(i)
			if base == null or not colori.has(base.resource_name):
				continue
			var mat := StandardMaterial3D.new()
			mat.albedo_color = colori[base.resource_name]
			mat.roughness = 0.85
			mesh_i.set_surface_override_material(i, mat)


## **L'umano di Quaternius, vestito dal gioco.**
##
## Le sei tinte del pacchetto sono sei **strisce di colore** su una
## texture di 32×32: righe 0-5 la pelle, 6-10 il nero (occhi, scarpe),
## 11-16 i capelli, 17-22 la maglia, 23-31 i pantaloni. Nient'altro: ogni
## faccia del modello pesca il colore da una riga. Quindi non serve
## scegliere fra sei vestiti: la striscia si **disegna** con i colori che
## chiede chi costruisce il personaggio — la maglia del mestiere, i
## pantaloni del mestiere, la pelle e i capelli come per il pupo — e
## l'umano di Quaternius si veste come tutti gli altri. Con `opts["tinta"]`
## (1-6) si prende invece una delle sei originali.
##
## Le strisce disegnate si tengono da parte per colori: due passanti dello
## stesso mestiere con la stessa pelle usano la stessa texture.
static var _strisce: Dictionary = {}
const RIGHE_UMANO := [[0, 6], [6, 11], [11, 17], [17, 23], [23, 32]]


static func _striscia_umano(colori: Array) -> Texture2D:
	var chiave := ""
	for c in colori:
		chiave += (c as Color).to_html(false)
	if _strisce.has(chiave):
		return _strisce[chiave]
	var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
	for i in range(RIGHE_UMANO.size()):
		var r: Array = RIGHE_UMANO[i]
		img.fill_rect(Rect2i(0, int(r[0]), 32, int(r[1]) - int(r[0])), colori[i])
	var tex := ImageTexture.create_from_image(img)
	_strisce[chiave] = tex
	return tex


static func _vesti_umano(m: Node3D, camicia: Color, pantaloni: Color,
		opts: Dictionary) -> void:
	var tex: Texture2D = null
	if opts.has("tinta"):
		var quale: int = (int(opts["tinta"]) - 1) % TINTE_UMANO
		tex = load("res://assets/models/umano_q_%d.png" % (quale + 1))
	else:
		var pelle := Color(opts.get("skin", SKIN_TONES[randi() % SKIN_TONES.size()]))
		var capelli := Color(opts.get("hair", HAIR_COLORS[randi() % HAIR_COLORS.size()]))
		if bool(opts.get("bald", false)):
			capelli = pelle.darkened(0.08)
		tex = _striscia_umano([pelle, Color(0.13, 0.12, 0.12), capelli,
			camicia, pantaloni])
	if tex == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.roughness = 0.85
	var lista: Array = []
	_mesh_di(m, lista)
	for mi in lista:
		var mesh_i: MeshInstance3D = mi
		if mesh_i.mesh == null:
			continue
		for i in range(mesh_i.mesh.get_surface_count()):
			mesh_i.set_surface_override_material(i, mat)


static func _clip_fissa(pl: AnimationPlayer, clip: String) -> void:
	if not pl.has_animation(clip):
		clip = "Idle"
	var a: Animation = pl.get_animation(clip)
	a.loop_mode = Animation.LOOP_LINEAR
	var da: float = randf() * a.length
	var avvia := func() -> void:
		pl.play(clip)
		pl.seek(da, true)
	if pl.is_inside_tree():
		avvia.call()
	else:
		pl.ready.connect(avvia, CONNECT_ONE_SHOT)


## **'Ncopp'ô motorino, assettate overo** (0.59).
##
## Fino alla 0.58 chi andava in motorino era costruito con `animate: false`
## e poi piegato a mano, osso per osso: coscia a 72 gradi, ginocchio a −84,
## spalla a −78. Erano i numeri dello scheletro fatto a mano della 0.47, e
## lo scheletro della 0.48 quelle ossa **non le dà più** (`bones` porta
## solo testa, petto, mani e spalle). Il codice chiedeva `bones["thigh_l"]`,
## non lo trovava, e non piegava niente — ma l'animazione l'aveva spenta
## lui. Risultato: tre guagliuni **in croce** ncopp'a una Vespa, e altri
## otto sui motorini che girano per la città. Li ha trovati `prova_croce`.
##
## Adesso stanno seduti con la clip `Driving` della libreria: gambe avanti,
## mani avanti sul manubrio (o sulla schiena di quello davanti), bacino
## sulla sella. I due numeri qui sotto sono misurati sulla clip, non scelti:
## a metà ciclo il bacino sta 0,54 sopra ai piedi e 0,31 dietro alla
## radice, su un pupo alto 1,79.
const BACINO_GUIDA := 0.3017
const DIETRO_GUIDA := 0.1732


## Un personaggio assettato col bacino in (0, `sella_y`, `sella_z`) del nodo
## a cui lo si appende, che guarda verso −Z.
static func in_sella(camicia: Color, pantaloni: Color, altezza: float,
		sella_y: float, sella_z: float, opts: Dictionary = {}) -> Dictionary:
	var o := opts.duplicate()
	o["clip"] = "Driving"
	var parti := build(camicia, pantaloni, "", altezza, o)
	var root: Node3D = parti["root"]
	root.position = Vector3(0.0, sella_y - BACINO_GUIDA * altezza,
		sella_z - DIETRO_GUIDA * altezza)
	return parti


static func _trova_scheletro(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n as Skeleton3D
	for c in n.get_children():
		var s := _trova_scheletro(c)
		if s != null:
			return s
	return null


static func _trova_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n as AnimationPlayer
	for c in n.get_children():
		var p := _trova_player(c)
		if p != null:
			return p
	return null


static func _mesh_di(n: Node, fuori: Array) -> void:
	if n is MeshInstance3D:
		fuori.append(n)
	for c in n.get_children():
		_mesh_di(c, fuori)


## Quale corpo. Se chi chiama lo dice (`corpo`), quello; se no lo decide la
## **pancia**, che mezzo gioco passa già da otto versioni — `belly` stava
## nelle opzioni fin da quando i personaggi erano capsule, e da allora non
## la leggeva più nessuno.
static func _quale_corpo(opts: Dictionary) -> String:
	var detto := str(opts.get("corpo", ""))
	if detto != "" and CORPI.has(detto):
		return "corpo_" + detto
	var pancia := float(opts.get("belly", 0.45))
	if pancia >= 0.62:
		return "corpo_panzone"
	if pancia <= 0.22:
		return "corpo_magro"
	return "corpo_normale"


## **Chi tene che faccia** (0.66). Riempie le opzioni della faccia che chi
## costruisce il personaggio non ha detto. Chi le dice (i personaggi della
## storia: 'o Rre, Borrelli, 'a signora d''o lotto) le tiene; per gli altri
## si pesca, con le probabilità di una strada di Napoli: tanti occhi
## scuri, tanti capelli corti o ingellati, un po' di barba sfatta, e i
## capelli bianchi che portano le rughe.
static func _scegli_faccia(opts: Dictionary, femmina: bool,
		bambino: bool = false) -> void:
	if _dado_facce == null:
		_dado_facce = RandomNumberGenerator.new()
		_dado_facce.randomize()
	var d := _dado_facce
	var capelli_col := Color(opts.get("hair", Color(0.16, 0.11, 0.08)))
	var bianco: bool = capelli_col.s < 0.25 and capelli_col.v > 0.40
	# **'E piccerille** (sotto a un metro e quarantacinque): niente barba,
	# niente rughe, niente baffi, occhi aperti, e i capelli da ragazzino.
	if bambino:
		bianco = false
		if not opts.has("capelli"):
			opts["capelli"] = "lunghi" if femmina else _pesca(d,
				["corti", "ricci", "sfumati"], [40, 30, 30])
		for k in ["barba", "rughe"]:
			if not opts.has(k):
				opts[k] = ""
		if not opts.has("palpebre"):
			opts["palpebre"] = "sveglie"
		if not opts.has("bocca"):
			opts["bocca"] = _pesca(d, ["sorriso", "dritta", "cazzimma"], [50, 30, 20])
		opts["moustache"] = false
	if not opts.has("capelli"):
		if femmina:
			opts["capelli"] = _pesca(d, ["tuppo", "signora"], [50, 50]) if bianco \
				else _pesca(d, ["lunghi", "signora", "tuppo"], [45, 35, 20])
		else:
			opts["capelli"] = _pesca(d, ["stempiati", "corti", "gellati"], [45, 35, 20]) \
				if bianco else _pesca(d, ["corti", "gellati", "ricci", "sfumati"],
				[35, 20, 20, 25])
	if not opts.has("palpebre"):
		opts["palpebre"] = _pesca(d, ["sveglie", "stanche", "furbe", "arraggiate"],
			[35, 35, 15, 15])
	if not opts.has("sopracciglia"):
		opts["sopracciglia"] = "sottili" if femmina and d.randf() < 0.7 else \
			_pesca(d, ["dritte", "preoccupate", "arraggiate", "scettiche"],
			[45, 15, 20, 20])
	if not opts.has("naso"):
		opts["naso"] = _pesca(d, ["piccolo", "grosso", "aquilino"],
			[75, 10, 15] if femmina or bambino else [35, 35, 30])
	if not opts.has("bocca"):
		opts["bocca"] = _pesca(d, ["dritta", "sorriso", "rossetto", "preoccupata"],
			[35, 25, 30, 10]) if femmina else _pesca(d, ["dritta", "cazzimma",
			"sorriso", "storta", "preoccupata"], [40, 20, 15, 15, 10])
	if not opts.has("barba"):
		opts["barba"] = "" if femmina else _pesca(d, ["", "sfatta", "pizzetto",
			"barba", "basette"], [45, 30, 10, 10, 5])
	if not opts.has("rughe"):
		if bianco:
			opts["rughe"] = "vecchia" if femmina else "vecchio"
		else:
			opts["rughe"] = _pesca(d, ["", "stanco", "arraggiato"], [70, 22, 8])
	if not opts.has("occhi"):
		opts["occhi"] = OCCHI[d.randi() % OCCHI.size()]
	# **'E peli nun so' sempe 'e capille** (0.66): sopracciglia, baffi e
	# barba di solito hanno il colore dei capelli. Chi porta il fazzoletto
	# ha i "capelli" del colore del fazzoletto: per lei i peli restano
	# scuri (o bianchi, se lo dice).
	if not opts.has("peli"):
		opts["peli"] = capelli_col
	# **'A rrobba 'e tutt''e juorne**: la cintura, il colletto, la
	# catenina d'oro col cornetto. Chi non dice niente ne pesca qualcuna.
	if not opts.has("cintura"):
		opts["cintura"] = d.randf() < (0.25 if femmina else 0.55)
	if not opts.has("colletto"):
		opts["colletto"] = d.randf() < (0.15 if femmina else 0.30)
	if not opts.has("catenina"):
		opts["catenina"] = d.randf() < (0.10 if femmina else 0.18)


static func _pesca(d: RandomNumberGenerator, cosa: Array, pesi: Array) -> String:
	var tot := 0.0
	for p in pesi:
		tot += float(p)
	var r: float = d.randf() * tot
	for i in range(cosa.size()):
		r -= float(pesi[i])
		if r <= 0.0:
			return str(cosa[i])
	return str(cosa[-1])


## Accende un corpo solo e butta gli altri, più capelli e baffi secondo le
## opzioni. Le mesh non stanno ancora nell'albero, quindi `free()` è
## immediato e sicuro.
##
## **Dalla 0.66** anche i pezzi della faccia: di ogni famiglia
## (`capelli_*`, `palpebre_*`, `sopracciglia_*`, `naso_*`) resta solo quello
## scelto, e i pezzi della corporatura (`colletto_panzone`,
## `cintura_magro`…) restano solo se chiesti e solo per il corpo giusto. Il
## pupo vecchio, che ha un `capelli` solo e nessuno di questi pezzi, passa
## di qua come prima.
static func _scegli_pezzi(modello: Node3D, opts: Dictionary) -> void:
	var voluto := _quale_corpo(opts)
	var corporatura: String = voluto.trim_prefix("corpo_")
	var pelato := bool(opts.get("bald", false))
	var baffi := bool(opts.get("moustache", false))
	var scelti := {
		"capelli": str(opts.get("capelli", "corti")),
		"palpebre": str(opts.get("palpebre", "sveglie")),
		"sopracciglia": str(opts.get("sopracciglia", "dritte")),
		"naso": str(opts.get("naso", "piccolo")),
	}
	# **`senza_testa` serve ô giocatore, e sulo a isso.**
	# In prima persona la telecamera sta dentro al cranio. Prima il cranio
	# si provava a nascondere da fuori con `_hide_above()`, che spegne i
	# `MeshInstance3D` posizionati sopra a una quota — e su una **mesh
	# skinnata unica** non spegne niente, perché la mesh è un nodo solo
	# appeso allo scheletro alla quota zero. Da lì la testa in mezzo allo
	# schermo. Adesso la testa è un oggetto e si butta.
	var senza_testa := bool(opts.get("senza_testa", false))
	## La banda rossa sulla coscia: solo chi porta la divisa.
	var banda := bool(opts.get("banda", false))
	var lista: Array = []
	_mesh_di(modello, lista)
	for mi in lista:
		var m: MeshInstance3D = mi
		var n: String = str(m.name)
		var butta := false
		var famiglia: String = n.get_slice("_", 0)
		var variante: String = n.substr(famiglia.length() + 1)
		if n.begins_with("corpo_"):
			butta = (n != voluto)
		elif n.begins_with("testa"):
			butta = senza_testa
		elif n == "capelli":
			butta = pelato or senza_testa
		elif famiglia == "capelli":
			butta = pelato or senza_testa or variante != scelti["capelli"]
		elif scelti.has(famiglia):
			butta = senza_testa or variante != scelti[famiglia]
		elif EXTRA_CORPO.has(famiglia):
			butta = variante != corporatura or not bool(opts.get(famiglia, false))
		elif n == "gonna":
			butta = not bool(opts.get("gonna", false))
		elif n.begins_with("baffi"):
			butta = (not baffi) or senza_testa
		elif n.begins_with("banda_rossa"):
			butta = not banda
		if butta:
			var p := m.get_parent()
			if p != null:
				p.remove_child(m)
			m.free()


## Veste il personaggio: ogni superficie della mesh porta il nome della sua
## zona (pelle, camicia, pantaloni, scarpe, capelli), e qui le si dà il
## colore. È una sovrascrittura per istanza, quindi due persone con la
## stessa mesh possono avere camicie diverse senza duplicare niente.
static func _vesti(modello: Node3D, camicia: Color, pantaloni: Color,
		opts: Dictionary) -> void:
	var pelle := Color(opts.get("skin", Color(0.86, 0.68, 0.54)))
	var capelli := Color(opts.get("hair", Color(0.16, 0.11, 0.08)))
	# **'A gonna e 'e cazette** (0.66): chi porta la gonna ha la gonna del
	# colore dei pantaloni, e sotto le calze (i tubi dei pantaloni, che
	# sotto al ginocchio restano scoperti): velate color pelle, o nere per
	# chi va vestita di scuro.
	var gonna := bool(opts.get("gonna", false))
	var calze: Color = pantaloni
	if gonna:
		calze = Color(opts.get("calze", pelle.darkened(0.12) if pantaloni.v > 0.25
			else Color(0.07, 0.07, 0.08)))
	var colori := {
		"pelle": pelle,
		"faccia": pelle,
		"camicia": camicia,
		"pantaloni": calze,
		"gonna": pantaloni,
		"scarpe": Color(opts.get("scarpe", Color(0.10, 0.09, 0.09))),
		"capelli": capelli,
		"peli": Color(opts.get("peli", capelli)),
		"iride": Color(opts.get("occhi", OCCHI[0])),
		"banda": Color(opts.get("banda_colore", Color(0.64, 0.09, 0.11))),
	}
	# **'O pelato nun se tegne cchiù.** Prima "togliere i capelli" voleva
	# dire tingerli color pelle: usciva una calotta di carne in testa, e
	# siccome sopracciglia e bocca usavano lo stesso materiale, il pelato
	# restava pure **senza faccia**. Adesso i capelli sono un oggetto e si
	# cancellano (`_scegli_pezzi`), e i tratti hanno il loro materiale.
	var ruvido := {
		"pelle": 0.72, "faccia": 0.72, "camicia": 0.92, "pantaloni": 0.92,
		"gonna": 0.92, "scarpe": 0.55, "capelli": 0.95, "peli": 0.95, "banda": 0.88,
		"iride": 0.30,
	}
	# La faccia si fa una volta per persona e si usa su tutte le superfici
	# `faccia` (sta tutta nella testa, ma non si sa mai).
	var faccia: Material = null
	var mesh_list: Array = []
	_mesh_di(modello, mesh_list)
	for mi in mesh_list:
		var m: MeshInstance3D = mi
		if m.mesh == null:
			continue
		for i in range(m.mesh.get_surface_count()):
			var base: Material = m.mesh.surface_get_material(i)
			var nome: String = ""
			if base != null:
				nome = str(base.resource_name)
			if nome == "":
				continue
			var chiave: String = nome.split(".")[0]
			if not colori.has(chiave):
				continue
			if chiave == "faccia":
				if faccia == null:
					faccia = _materiale_faccia(pelle,
						Color(opts.get("peli", capelli)), opts)
				m.set_surface_override_material(i, faccia)
				continue
			var mat := StandardMaterial3D.new()
			mat.albedo_color = colori[chiave]
			mat.roughness = float(ruvido.get(chiave, 0.9))
			mat.metallic = 0.0
			# 'O gel: i capelli tirati all'indietro luccicano.
			if chiave == "capelli" and str(opts.get("capelli", "")) == "gellati":
				mat.roughness = 0.42
			# **'A stoffa e 'e ciocche** (0.66): la tinta la decide il
			# gioco, la trama sta in una texture grigia che la moltiplica.
			var trama: Texture2D = _trama(chiave)
			if trama != null:
				mat.albedo_texture = trama
			m.set_surface_override_material(i, mat)


## Le texture grigie che danno la trama alla tinta: la stoffa della
## camicia, quella dei pantaloni, le ciocche dei capelli, l'iride. Mancano?
## Si tinge a colore pieno come prima.
const TRAME := {
	"camicia": "stoffa_camicia.png", "gonna": "stoffa_camicia.png",
	"pantaloni": "stoffa_cazune.png", "capelli": "ciocche.png",
	"iride": "iride.png",
}
static var _trame: Dictionary = {}


static func _trama(chiave: String) -> Texture2D:
	if not TRAME.has(chiave):
		return null
	return _tex_pupo(str(TRAME[chiave]))


static func _tex_pupo(file: String) -> Texture2D:
	if file == "":
		return null
	if not _trame.has(file):
		var p: String = TEX_PUPO + file
		_trame[file] = load(p) if ResourceLoader.exists(p) else null
	return _trame[file]


static var _shader_faccia: Shader = null


## **'A faccia dipinta** (0.66): la pelle della testa con sopra la bocca,
## la barba e le rughe scelte, disegnate dallo shader `pupo_faccia`. Senza
## shader (o su un pupo vecchio, che non ha la superficie `faccia`) si
## torna alla pelle liscia.
static func _materiale_faccia(pelle: Color, peli: Color,
		opts: Dictionary) -> Material:
	if _shader_faccia == null and ResourceLoader.exists(SHADER_FACCIA):
		_shader_faccia = load(SHADER_FACCIA)
	if _shader_faccia == null:
		var liscia := StandardMaterial3D.new()
		liscia.albedo_color = pelle
		liscia.roughness = 0.72
		return liscia
	var mat := ShaderMaterial.new()
	mat.shader = _shader_faccia
	mat.set_shader_parameter("pelle", pelle)
	mat.set_shader_parameter("peli", peli)
	var bocca: Texture2D = _tex_pupo(str(TEX_BOCCHE.get(str(opts.get("bocca", "dritta")),
		TEX_BOCCHE["dritta"])))
	var barba: Texture2D = _tex_pupo(str(TEX_BARBE.get(str(opts.get("barba", "")), "")))
	var rughe: Texture2D = _tex_pupo(str(TEX_RUGHE.get(str(opts.get("rughe", "")), "")))
	if bocca != null:
		mat.set_shader_parameter("tex_bocca", bocca)
	if barba != null:
		mat.set_shader_parameter("tex_barba", barba)
	if rughe != null:
		mat.set_shader_parameter("tex_rughe", rughe)
	return mat
