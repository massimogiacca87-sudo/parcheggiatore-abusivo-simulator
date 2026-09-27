extends Node3D
## **'E mmane 'n primma perzona** (0.65)
##
## ## Il problema
##
## Il capo: *«Si è perso l'utilizzo delle mani in prima persona come gesti
## quando fai parcheggiare le auto. Crea di nuovo le animazioni a gesti
## quando muovi un'auto.»*
##
## Fino alla 0.53 le mani c'erano: due braccia a scatole appese alla
## telecamera. Alla 0.54 sono state buttate perché il corpo del giocatore è
## un modello vero con le braccia sue, e le braccia erano diventate quattro.
## Il ragionamento era giusto per il corpo e sbagliato per la regia: con le
## braccia vere a mezzo metro di lato (fuori dall'inquadratura, misurato da
## `prova_braccia`), durante la manovra non si vedeva più **niente** — la
## meccanica più tua del gioco si faceva guardando una macchina e leggendo
## una scritta gialla.
##
## ## La risposta
##
## La stessa di `arma_fp.gd` (0.61): le mani che vedi tu **non sono** quelle
## del corpo. Sono un modellino appeso alla telecamera, **visibile solo
## mentre dirigi un'auto** (quando non dirigi, sparisce e torna il fierro se
## ce l'hai in mano). Così le braccia non tornano a essere quattro: il corpo
## le sue le tiene sotto all'inquadratura, e queste esistono solo quando
## servono.
##
## Ogni mano è fatta a pezzi veri — palmo, quattro dita da due falangi, il
## pollice — così un gesto è una **posa della mano**, non una scatola che si
## sposta: il dito che indica, il palmo aperto che dice «fermo», le dita che
## chiamano «vieni, vieni».
##
## ## I gesti (uno per tasto, come le grida)
##
##   * **nisciuno tasto** — «aspetta»: le mani su, pronte, che respirano;
##   * **W** — «vieni, vieni, vieni!»: tutt'e ddoje 'e palme verso di te, le
##     dita che chiamano;
##   * **S** — «FERMO!»: le palme spinte avanti, dita aperte;
##   * **A / D** — «gira!»: il braccio da quella parte che indica col dito,
##     l'altra mano che fa il volante;
##   * **F** — «mettila ccà»: il dito che punta per terra, due volte;
##   * **la botta** — le mani all'aria, «Mamma d''o Carmene!»;
##   * **il park-assist** — «piano, piano»: palme in giù che battono l'aria;
##   * **fatto** — il pollice su; **andato via** — le palme al cielo.
##
## Con la paletta in tasca la mano destra la tiene, e il gesto lo fa la
## paletta: si sventola per chiamare, si pianta davanti per fermare, si
## inclina per girare.
##
## ## Perché è piccolo
##
## Come il fierro: tutto è in scala vera e poi rimpicciolito a `SCALA`, così
## sta dentro alla capsula del giocatore e non entra nei muri.

const Tex := preload("res://scripts/textures.gd")

const SCALA: float = 0.42
const PELLE := Color(0.84, 0.65, 0.5)
## Il colore della camicia del giocatore (`player_fps.SHIRT_COLOR`): la
## manica del fierro è la stessa.
const MANICA := Color(0.46, 0.53, 0.61)
## Dove sta la spalla, in metri veri rispetto all'occhio (x per la mano
## destra; la sinistra è a specchio). Fuori dall'inquadratura.
const SPALLA := Vector3(0.21, -0.50, 0.16)
## Quanto è lungo l'avambraccio, dal polso al gomito.
const AVAMBRACCIO: float = 0.27

## Le dita: [x della base per la mano destra, falange 1, falange 2,
## larghezza]. Dall'indice al mignolo. Il pollice è a parte.
const DITA := [
	[0.030, 0.045, 0.040, 0.019],
	[0.010, 0.050, 0.043, 0.020],
	[-0.010, 0.046, 0.040, 0.019],
	[-0.029, 0.036, 0.031, 0.017],
]

## Quanto si chiude ogni falange a pugno pieno (radianti).
const CHIUDE_1: float = 1.50
const CHIUDE_2: float = 1.65

## Quanto dura ogni gesto che non dipende da un tasto tenuto.
const DURATE := {"botta": 0.85, "bravo": 1.3, "sconfitto": 1.3,
	"mettila": 0.9, "alzate": 0.35}

var _mani: Dictionary = {}       # "r"/"l" -> Dictionary coi nodi
var _stato: Dictionary = {}      # "r"/"l" -> posa corrente
var _gesto: String = ""          # il gesto tenuto (dal tasto)
var _lampo: String = ""          # il gesto a tempo (botta, bravo, ...)
var _t_lampo: float = 0.0
var _t: float = 0.0
var _su: float = 0.0             # 0 = sotto all'inquadratura, 1 = su
var _vuole: bool = false         # la regia è accesa
var _paletta: Node3D = null
var _cu_paletta: bool = false


func _ready() -> void:
	scale = Vector3.ONE * SCALA
	for lato in ["r", "l"]:
		_mani[lato] = _costruisci_mano(lato)
		_stato[lato] = _posa_pronte(lato, 0.0)
		_stato[lato]["pos"] += Vector3(0, -0.45, 0.1)
	_costruisci_paletta()
	visible = false
	GameManager.directing_bump.connect(_su_botta)
	GameManager.directing_ended.connect(_su_fine)


# ---------------------------------------------------------------------------
# 'A mano, fatta a pezzi
# ---------------------------------------------------------------------------
#
# Il sistema di una mano, a posa zero: **le dita verso +Y** (in su), **il
# palmo verso +Z** (verso l'occhio), il polso nell'origine. Per la destra il
# pollice sta a +X (alza la mano destra davanti alla faccia col palmo verso
# di te: il pollice sta a destra); la sinistra è a specchio.
#
# Chiudere un dito è ruotarlo attorno alla sua X: `Rx(θ)` porta il +Y verso
# il +Z, cioè verso il palmo.

func _costruisci_mano(lato: String) -> Dictionary:
	var s: float = 1.0 if lato == "r" else -1.0
	var pelle := Tex.flat(PELLE, 0.8)
	var pelle_scura := Tex.flat(PELLE.darkened(0.06), 0.8)
	var polso := Node3D.new()
	polso.name = "Mano_" + lato
	add_child(polso)

	var palmo := _scatola(polso, Vector3(0.086, 0.098, 0.030),
		Vector3(0.0, 0.050, 0.0), pelle)
	# Il cuscinetto sotto al pollice: senza, il palmo è una tavoletta.
	_scatola(polso, Vector3(0.036, 0.050, 0.014),
		Vector3(0.024 * s, 0.030, 0.014), pelle_scura)

	var dita: Array = []
	for d in DITA:
		var base := Node3D.new()
		base.position = Vector3(float(d[0]) * s, 0.098, 0.0)
		polso.add_child(base)
		var l1: float = float(d[1])
		var l2: float = float(d[2])
		var w: float = float(d[3])
		_scatola(base, Vector3(w, l1, 0.021), Vector3(0, l1 * 0.5, 0), pelle)
		var nocca := Node3D.new()
		nocca.position = Vector3(0, l1, 0)
		base.add_child(nocca)
		_scatola(nocca, Vector3(w * 0.92, l2, 0.019),
			Vector3(0, l2 * 0.5, 0), pelle)
		dita.append([base, nocca])

	# 'O pollice: parte dal lato del palmo, basso, inclinato verso fuori.
	var p_base := Node3D.new()
	p_base.position = Vector3(0.040 * s, 0.022, 0.010)
	polso.add_child(p_base)
	_scatola(p_base, Vector3(0.024, 0.040, 0.022), Vector3(0, 0.020, 0), pelle)
	var p_nocca := Node3D.new()
	p_nocca.position = Vector3(0, 0.040, 0)
	p_base.add_child(p_nocca)
	_scatola(p_nocca, Vector3(0.021, 0.032, 0.020), Vector3(0, 0.016, 0),
		pelle)

	# L'avambraccio e la manica non stanno nella mano: stanno fra il polso e
	# il gomito, e il gomito lo decide la posa. Si ridisegnano ogni
	# fotogramma (vedi `_braccio`).
	var avamb := _cilindro(Tex.flat(PELLE.darkened(0.03), 0.85), 0.030, 0.034)
	var manica := _cilindro(Tex.flat(MANICA, 0.9), 0.046, 0.056)
	for m in [avamb, manica]:
		add_child(m)
	_senza_ombra(polso)
	return {"lato": lato, "s": s, "polso": polso, "palmo": palmo,
		"dita": dita, "pollice": [p_base, p_nocca],
		"avamb": avamb, "manica": manica}


func _scatola(sotto: Node3D, size: Vector3, pos: Vector3,
		mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sotto.add_child(mi)
	return mi


## Un cilindro alto un metro coi due raggi (sotto e sopra): la lunghezza
## gliela dà la trasformazione. I raggi si scrivono una volta sola, perché
## cambiare un `CylinderMesh` lo rifà da capo.
func _cilindro(mat: Material, r_a: float, r_b: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.bottom_radius = r_a
	cm.top_radius = r_b
	cm.height = 1.0
	cm.radial_segments = 8
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Mette il cilindro `mi` fra `a` e `b` (il raggio di sotto sta in `a`).
func _fra(mi: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var lung: float = maxf(a.distance_to(b), 0.001)
	var y: Vector3 = (b - a) / lung
	var x: Vector3 = y.cross(Vector3.FORWARD)
	if x.length() < 0.01:
		x = y.cross(Vector3.RIGHT)
	x = x.normalized()
	var z: Vector3 = x.cross(y).normalized()
	mi.transform = Transform3D(Basis(x, y * lung, z), (a + b) * 0.5)


func _senza_ombra(n: Node) -> void:
	if n is GeometryInstance3D:
		(n as GeometryInstance3D).cast_shadow = \
			GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children():
		_senza_ombra(c)


## **'A paletta 'n mano.** Nel pugno il manico passa **di traverso** (lungo
## la X della mano, dal mignolo al pollice), quindi si gira di novanta gradi.
##
## Non è il modello `paletta` del corpo: quello ha il disco **perpendicolare
## al manico** (misurato: 16,6 × 29,5 × 16,6 cm, il disco sta nel piano XZ),
## che sul fianco non si nota e in mano, a trenta centimetri dall'occhio,
## era un piattino da caffè in cima a un bastone. Questa ha il disco nel
## piano del manico, come quelle vere: rosso fuori, bianco dentro, da tutt'e
## ddoje 'e parte.
func _costruisci_paletta() -> void:
	_paletta = Node3D.new()
	_paletta.name = "PalettaFp"
	var pugno: Node3D = _mani["r"]["polso"]
	pugno.add_child(_paletta)
	_paletta.position = Vector3(-0.030, 0.062, 0.030)
	_paletta.rotation = Vector3(0, 0, deg_to_rad(-90))
	var manico := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.011
	cm.bottom_radius = 0.013
	cm.height = 0.26
	cm.radial_segments = 8
	manico.mesh = cm
	manico.material_override = Tex.flat(Color(0.12, 0.12, 0.13), 0.6)
	manico.position = Vector3(0, 0.08, 0)
	_paletta.add_child(manico)
	var fuori := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 0.078
	dm.bottom_radius = 0.078
	dm.height = 0.010
	dm.radial_segments = 20
	fuori.mesh = dm
	fuori.material_override = Tex.flat(Color(0.86, 0.10, 0.10), 0.5)
	fuori.rotation.x = deg_to_rad(90)
	fuori.position = Vector3(0, 0.27, 0)
	_paletta.add_child(fuori)
	var dentro := MeshInstance3D.new()
	var wm := CylinderMesh.new()
	wm.top_radius = 0.052
	wm.bottom_radius = 0.052
	wm.height = 0.013
	wm.radial_segments = 20
	dentro.mesh = wm
	dentro.material_override = Tex.flat(Color(0.95, 0.95, 0.93), 0.5)
	dentro.rotation.x = deg_to_rad(90)
	dentro.position = Vector3(0, 0.27, 0)
	_paletta.add_child(dentro)
	_senza_ombra(_paletta)
	_paletta.visible = false


# ---------------------------------------------------------------------------
# Chi comanda: il giocatore e i segnali della regia
# ---------------------------------------------------------------------------

## Lo chiama `player_fps` ogni fotogramma: `gesto` è quello del tasto tenuto
## («aspetta», «avanti», «frena», «sinistra», «destra», «piano»), o `""`
## quando non stai dirigendo niente.
func regia(gesto: String) -> void:
	var prima: bool = _vuole
	_vuole = gesto != ""
	if _vuole:
		_gesto = gesto
		if not prima:
			_cu_paletta = GameManager.has_upgrade("paletta")
			_paletta.visible = _cu_paletta
			visible = true


## Un gesto a tempo, che passa davanti a quello tenuto: «botta», «bravo»,
## «sconfitto», «mettila».
func lampo(nome: String) -> void:
	if not DURATE.has(nome):
		return
	_lampo = nome
	_t_lampo = 0.0
	# Il pollice su e le braccia al cielo si vedono anche a regia finita:
	# si accendono da soli se le mani erano già giù.
	if not visible:
		_cu_paletta = GameManager.has_upgrade("paletta")
		_paletta.visible = _cu_paletta
		visible = true


func _su_botta(_quante: int) -> void:
	if _vuole:
		lampo("botta")


func _su_fine(punti: float, andato: bool) -> void:
	if not visible and not _vuole:
		return
	if andato:
		lampo("sconfitto")
	elif punti >= 0.0:
		lampo("bravo")


## Vero mentre le mani stanno davanti all'occhio (anche solo per un
## pollice su a regia finita): il fierro si nasconde.
func in_vista() -> bool:
	return visible


# ---------------------------------------------------------------------------
# 'E ppose
# ---------------------------------------------------------------------------
#
# Una posa è: `pos` (il polso, in metri veri davanti all'occhio), `rot`
# (gradi, ordine YXZ di Godot: prima Z, poi X, poi Y), `dita` (quanto è
# chiuso ognuno: pollice, indice, medio, anulare, mignolo; 0 aperto, 1
# pugno). Si scrivono **per la mano destra**: la sinistra è a specchio
# (x, giro attorno a Y e giro attorno a Z cambiano segno).
#
# Le pose stanno nel terzo basso dello schermo e sui lati: in mezzo c'è la
# macchina che stai dirigendo, e un gesto che te la copre è un gesto
# sbagliato.

func _p(pos: Vector3, rot: Vector3, dita: Array) -> Dictionary:
	return {"pos": pos, "rot": rot, "dita": dita}


func _specchio(p: Dictionary, lato: String) -> Dictionary:
	if lato == "r":
		return p
	var pos: Vector3 = p["pos"]
	var rot: Vector3 = p["rot"]
	return {"pos": Vector3(-pos.x, pos.y, pos.z),
		"rot": Vector3(rot.x, -rot.y, -rot.z), "dita": p["dita"]}


func _mix(a: Dictionary, b: Dictionary, k: float) -> Dictionary:
	var dita: Array = []
	for i in range(5):
		dita.append(lerpf(float(a["dita"][i]), float(b["dita"][i]), k))
	return {"pos": (a["pos"] as Vector3).lerp(b["pos"], k),
		"rot": (a["rot"] as Vector3).lerp(b["rot"], k), "dita": dita}


func _onda(freq: float, fase: float = 0.0) -> float:
	return 0.5 + 0.5 * sin(_t * TAU * freq + fase)


func _liscio(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


const APERTE := [0.1, 0.05, 0.05, 0.08, 0.12]
const RILASSATE := [0.25, 0.18, 0.22, 0.28, 0.34]
const PUGNO := [0.55, 1.0, 1.0, 1.0, 1.0]
const INDICA := [0.6, 0.0, 0.95, 1.0, 1.0]
## Il pollice a −0,6 è **aperto di lato** (a 80 gradi dalle dita invece
## che a 35): senza, il pollice su era un pugno col pollice storto.
const POLLICE_SU := [-0.6, 1.0, 1.0, 1.0, 1.0]


## «Aspetta»: le mani su, di tre quarti, che respirano.
func _posa_pronte(lato: String, fase: float) -> Dictionary:
	var r := sin(_t * 1.7 + fase) * 0.006
	return _specchio(_p(Vector3(0.31, -0.29 + r, -0.50),
		Vector3(-8, -28, 12), RILASSATE), lato)


## La posa del gesto tenuto, per una mano.
func _posa_gesto(g: String, lato: String) -> Dictionary:
	var dx: bool = lato == "r"
	match g:
		"avanti":
			# «Vieni, vieni, vieni»: palma verso di te, e le dita — e tutta
			# la mano col polso — che tirano indietro. Le due mani vanno un
			# filo sfasate: fatto in coro sembra un robot.
			var k: float = _onda(2.6, 0.0 if dx else 0.9)
			var a := _p(Vector3(0.28, -0.27, -0.56), Vector3(-18, -18, 8),
				[0.15, 0.05, 0.05, 0.08, 0.12])
			var b := _p(Vector3(0.27, -0.25, -0.49), Vector3(38, -14, 6),
				[0.3, 0.55, 0.6, 0.62, 0.66])
			return _specchio(_mix(a, b, k), lato)
		"frena":
			# «FERMO!»: palma aperta verso la macchina (giro di 180 attorno
			# a Y: il palmo guarda avanti), spinta avanti e tenuta, con un
			# tremito che dice «fermo, fermo, fermo».
			var sp: float = sin(_t * TAU * 5.0) * 0.008
			return _specchio(_p(Vector3(0.25, -0.19 + sp, -0.62),
				Vector3(-6, 168, -6), [0.0, 0.0, 0.0, 0.0, 0.05]), lato)
		"sinistra", "destra":
			# Il braccio dalla parte dove deve girare **indica**; l'altro fa
			# il volante — la mano aperta che gira in tondo.
			var verso_dx: bool = g == "destra"
			if dx == verso_dx:
				var sw: float = sin(_t * TAU * 2.2)
				return _specchio(_p(Vector3(0.44 + sw * 0.03, -0.17, -0.47),
					Vector3(90, -8 + sw * 14, -92), INDICA), lato)
			# 'O volante: palma avanti, e la mano che torce avanti e
			# indietro come chi gira un volante grosso.
			var tor: float = sin(_t * TAU * 1.8) * 32.0
			return _specchio(_p(Vector3(0.20, -0.25, -0.56),
				Vector3(-6, 160, tor + (-12.0 if verso_dx == dx else 12.0)),
				[0.1, 0.1, 0.15, 0.2, 0.25]), lato)
		"piano":
			# «Piano, piano»: palme in giù (prima 180 attorno a Z, poi 90
			# attorno a X: le dita guardano avanti, il palmo la terra), che
			# battono l'aria.
			var k2: float = _onda(1.8, 0.0 if dx else PI)
			return _specchio(_p(Vector3(0.24, -0.30 + k2 * 0.05, -0.50),
				Vector3(112 - k2 * 16, -10, 180), APERTE), lato)
	return _posa_pronte(lato, 0.0 if dx else 1.3)


## La posa del gesto a tempo al punto `k` (0 → 1).
func _posa_lampo(g: String, lato: String, k: float) -> Dictionary:
	var dx: bool = lato == "r"
	match g:
		"botta":
			# «Mamma d''o Carmene!»: le mani all'aria, aperte, che tremano.
			var tr: float = sin(_t * TAU * 9.0) * 0.012 * (1.0 - k)
			return _specchio(_p(Vector3(0.34 + tr, -0.10, -0.50),
				Vector3(-4, -34, 38), [0.0, 0.0, 0.0, 0.0, 0.0]), lato)
		"bravo":
			# 'O pollice su, la destra sola. La sinistra scende.
			if dx:
				var pump: float = absf(sin(k * TAU * 1.5)) * 0.025
				return _p(Vector3(0.22, -0.20 + pump, -0.50),
					Vector3(0, -70, 78), POLLICE_SU)
			return _specchio(_p(Vector3(0.30, -0.75, -0.40),
				Vector3(-30, -20, 10), RILASSATE), lato)
		"sconfitto":
			# «E che ce pozzo fa'?»: palme al cielo, e poi giù.
			var giu: float = _liscio((k - 0.6) / 0.4) * 0.25
			return _specchio(_p(Vector3(0.30, -0.26 - giu, -0.48),
				Vector3(-80, -25, -10), APERTE), lato)
		"mettila":
			# «Mettila ccà!»: l'indice che pianta il punto per terra, due
			# volte; la sinistra a palma in giù.
			if dx:
				var colpo: float = absf(sin(k * TAU))
				return _p(Vector3(0.22, -0.15 - colpo * 0.06, -0.55),
					Vector3(-125, -10, 0), INDICA)
			return _specchio(_p(Vector3(0.26, -0.30, -0.50),
				Vector3(122, -10, 180), APERTE), lato)
	return _posa_pronte(lato, 0.0)


## **Con la paletta**, la destra è un pugno col manico dentro, e il gesto
## lo fa la paletta. Il pugno sta girato col pollice in su (+90 attorno a
## Z): così il manico, che passa di traverso nel pugno, sta in piedi.
func _posa_paletta(g: String, k_lampo: float) -> Dictionary:
	match g:
		"avanti":
			var k: float = _onda(2.4)
			return _p(Vector3(0.24, -0.27, -0.52),
				Vector3(-10 + k * 42, -20, 90), PUGNO)
		"frena":
			return _p(Vector3(0.18, -0.24, -0.62), Vector3(-12, -8, 90), PUGNO)
		"sinistra":
			var sw: float = _onda(2.0)
			return _p(Vector3(0.20, -0.26, -0.52),
				Vector3(-6, -14, 110 + sw * 40), PUGNO)
		"destra":
			var sw2: float = _onda(2.0)
			return _p(Vector3(0.30, -0.26, -0.52),
				Vector3(-6, -24, 70 - sw2 * 40), PUGNO)
		"piano":
			var k2: float = _onda(1.6)
			return _p(Vector3(0.24, -0.30 + k2 * 0.04, -0.52),
				Vector3(20 + k2 * 14, -20, 90), PUGNO)
		"botta":
			var tr: float = sin(_t * TAU * 9.0) * 12.0 * (1.0 - k_lampo)
			return _p(Vector3(0.30, -0.18, -0.52), Vector3(-6, -24, 90 + tr),
				PUGNO)
		"bravo":
			return _p(Vector3(0.22, -0.15, -0.54), Vector3(-10, -16, 90), PUGNO)
		"sconfitto":
			var giu: float = _liscio((k_lampo - 0.5) / 0.5) * 0.25
			return _p(Vector3(0.30, -0.30 - giu, -0.48),
				Vector3(10, -30, 150), PUGNO)
		"mettila":
			var colpo: float = absf(sin(k_lampo * TAU))
			return _p(Vector3(0.20, -0.26 - colpo * 0.05, -0.55),
				Vector3(-45 - colpo * 25, -10, 90), PUGNO)
	var r := sin(_t * 1.7) * 0.006
	return _p(Vector3(0.26, -0.27 + r, -0.52), Vector3(-6, -22, 90), PUGNO)


# ---------------------------------------------------------------------------
# Ogni fotogramma
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	var k_lampo: float = 0.0
	if _lampo != "":
		_t_lampo += delta
		k_lampo = _t_lampo / float(DURATE[_lampo])
		if k_lampo >= 1.0:
			_lampo = ""
	# Salgono quando comincia la regia, scendono quando finisce (a meno
	# che non ci sia ancora un gesto a tempo da far vedere).
	var vuole_su: bool = _vuole or _lampo != ""
	_su = move_toward(_su, 1.0 if vuole_su else 0.0,
		delta / float(DURATE["alzate"]))
	if _su <= 0.0 and not vuole_su:
		visible = false
		_paletta.visible = false
		return
	var giu: float = 1.0 - _liscio(_su)
	var morbido: float = 1.0 - exp(-delta * 16.0)
	for lato in ["r", "l"]:
		var bersaglio: Dictionary
		var g: String = _lampo if _lampo != "" else _gesto
		if lato == "r" and _cu_paletta:
			bersaglio = _posa_paletta(g, k_lampo)
			bersaglio["gomito"] = Vector3(0.35, -0.85, 0.40)
		elif _lampo != "":
			bersaglio = _posa_lampo(_lampo, lato, k_lampo)
		else:
			bersaglio = _posa_gesto(_gesto, lato)
		bersaglio["pos"] += Vector3(0, -0.42, 0.10) * giu
		bersaglio["rot"] += Vector3(-30, 0, 0) * giu
		_stato[lato] = _avvicina(_stato[lato], bersaglio, morbido)
		_applica(_mani[lato], _stato[lato])


## La posa corrente si avvicina a quella voluta senza saltarci: le
## rotazioni si mescolano come quaternioni (i gradi mescolati di traverso
## fanno fare alla mano il giro lungo).
func _avvicina(a: Dictionary, b: Dictionary, k: float) -> Dictionary:
	var qa: Quaternion = a.get("q", _quat(a["rot"]))
	var qb: Quaternion = _quat(b["rot"])
	var dita: Array = []
	for i in range(5):
		dita.append(lerpf(float(a["dita"][i]), float(b["dita"][i]), k))
	var ga: Vector3 = a.get("gomito", Vector3.ZERO)
	var gb: Vector3 = b.get("gomito", Vector3.ZERO)
	var g := Vector3.ZERO
	if gb != Vector3.ZERO:
		g = gb if ga == Vector3.ZERO else ga.lerp(gb, k)
	return {"pos": (a["pos"] as Vector3).lerp(b["pos"], k),
		"rot": b["rot"], "q": qa.slerp(qb, k).normalized(), "dita": dita,
		"gomito": g}


func _quat(gradi: Vector3) -> Quaternion:
	return Basis.from_euler(Vector3(deg_to_rad(gradi.x), deg_to_rad(gradi.y),
		deg_to_rad(gradi.z))).get_rotation_quaternion()


func _applica(m: Dictionary, p: Dictionary) -> void:
	var s: float = float(m["s"])
	var polso: Node3D = m["polso"]
	var q: Quaternion = p.get("q", _quat(p["rot"]))
	polso.transform = Transform3D(Basis(q), p["pos"])
	var dita: Array = p["dita"]
	for i in range(4):
		var c: float = float(dita[i + 1])
		(m["dita"][i][0] as Node3D).rotation = Vector3(c * CHIUDE_1, 0, 0)
		(m["dita"][i][1] as Node3D).rotation = Vector3(c * CHIUDE_2, 0, 0)
	# 'O pollice: a riposo inclinato verso fuori; chiudendosi passa sopra
	# al palmo (verso −X per la destra) e verso di lui (+Z).
	var cp: float = float(dita[0])
	(m["pollice"][0] as Node3D).rotation = Vector3(
		cp * 0.55, 0.0, s * (-0.62 + cp * 1.25))
	# La seconda falange si piega solo chiudendo: aperto di lato (cp < 0)
	# resta dritto, se no il pollice su era un uncino.
	var cp2: float = maxf(cp, 0.0)
	(m["pollice"][1] as Node3D).rotation = Vector3(cp2 * 0.9, 0.0, s * cp2 * 0.4)
	_braccio(m, polso.transform, p.get("gomito", Vector3.ZERO))


## L'avambraccio va dal polso al gomito, e il gomito sta **dietro alla
## mano**, dalla parte opposta alle dita, tirato un po' in giù e verso la
## spalla: così una mano che indica di lato ha il braccio che le viene
## dietro, e una mano alzata ha il braccio che scende.
##
## Una posa può dire da sola da che parte scende il braccio (`gomito`): il
## pugno con la paletta ha le dita di traverso, e col conto di sempre il
## braccio usciva orizzontale verso destra come una sbarra.
func _braccio(m: Dictionary, t: Transform3D, gomito: Vector3) -> void:
	var s: float = float(m["s"])
	var spalla := Vector3(SPALLA.x * s, SPALLA.y, SPALLA.z)
	var polso: Vector3 = t.origin
	var dita: Vector3 = t.basis.y.normalized()
	var verso_spalla: Vector3 = (spalla - polso).normalized()
	var dir: Vector3 = (-dita * 0.75 + verso_spalla * 0.55
		+ Vector3(0, -0.35, 0.2)).normalized()
	if gomito != Vector3.ZERO:
		dir = Vector3(gomito.x * s, gomito.y, gomito.z).normalized()
	# La manica va dritta fino a fuori dall'inquadratura. Al primo giro
	# c'era anche il braccio di sopra, dal gomito alla spalla: passava a
	# un palmo dall'occhio e in foto era un tubo azzurro grosso quanto
	# mezzo schermo.
	var fine_pelle: Vector3 = polso + dir * 0.075
	_fra(m["avamb"], polso + dir * 0.005, fine_pelle)
	_fra(m["manica"], fine_pelle, polso + dir * (AVAMBRACCIO + 0.30))
