extends StaticBody3D
## Armiere3D — 'o ferraro
##
## In fondo a un vicolo cieco, dietro a un telo, uno che vende cose che non
## si vendono. Non ha insegna, non ha vetrina, e non sta su nessuna strada
## larga: ci si arriva solo se ci si infila apposta.
##
## ## Perché sta in un vicolo cieco
##
## È l'unico posto della mappa dove non passa nessuno per caso. Gli altri
## quattro vicoli ciechi non portano da nessuna parte — sono lì per fare
## quartiere. Questo ne riempie uno, e in cambio dà a quel vicolo l'unica
## cosa che gli mancava: un motivo per infilarcisi.
##
## ## A che servono le armi
##
## A una cosa sola: **prendersi una piazza senza pagarla.** I parcheggiatori
## delle altre zone hanno quaranta punti di salute; a mani nude ne togli uno
## per pugno mentre lui te ne dà nove ogni secondo, e il conto non torna mai.
## Col curtiello sono sette colpi, col fierro tre.
##
## Il prezzo è il sospetto: ogni colpo con un'arma alza il calore molto più
## di un pugno, e la pistola più di tutti. Comprare la zona costa mille euro
## ma non ti mette addosso i carabinieri — resta l'opzione sensata anche
## quando hai il fierro in tasca, ed è così che deve essere.

const Tex := preload("res://scripts/textures.gd")
const Models := preload("res://scripts/models.gd")
const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const HumanBuilderScript := preload("res://scripts/human_builder.gd")

const SAY_SALUTO := [
	"Uè. Che te serve?",
	"Dimme tu, ma parla chiano.",
	"Ccà nun ce sta niente. Che vuo'?",
	"Guarda e nun tuccà.",
]
const SAY_VENDUTO := [
	"Tie'. E nun m'hê visto maje.",
	"Statte accuorto, eh.",
	"Buon divertimento. O buona fortuna.",
	"Chest'è. 'O riesto tienatillo.",
]
const SAY_SQUATTRINATO := "E chi t''o dà a credito, 'o munno?"
const SAY_TENUTO := "Chesto già 'o tiene. Che vuo', 'o paro?"

var _bubble: Node3D
var _detto: float = 0.0


func _ready() -> void:
	add_to_group("attivita")
	add_to_group("armiere")
	collision_layer = 1
	collision_mask = 0
	_build_visual()
	_build_collisione()
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 2.2, 0.9)
	add_child(_bubble)


# ---------------------------------------------------------------------------
# Il banco
# ---------------------------------------------------------------------------

func _build_visual() -> void:
	# Il telo teso davanti al fondo del vicolo: è quello che fa capire, da
	# lontano, che lì dietro c'è qualcosa e non solo un muro.
	var telo := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(3.4, 2.6, 0.08)
	telo.mesh = tm
	telo.position = Vector3(0, 1.5, -0.9)
	# Il telo è verde militare, non nero.
	#
	# Era Color(0.16, 0.17, 0.19), cioè quasi nero — e il ferraro davanti
	# aveva la camicia Color(0.14, 0.15, 0.17), cioè quasi lo stesso nero.
	# Il risultato era che dell'uomo si vedevano solo la testa pelata e le
	# mani: il resto spariva dentro al proprio fondale. Due cose scure una
	# davanti all'altra non sono due cose, sono una macchia.
	telo.material_override = Tex.flat(Color(0.22, 0.26, 0.21), 0.95)
	add_child(telo)

	# Il bancone: un asse su due cavalletti, con sopra un panno.
	var asse := MeshInstance3D.new()
	var am := BoxMesh.new()
	am.size = Vector3(2.6, 0.1, 0.8)
	asse.mesh = am
	asse.position = Vector3(0, 0.95, 0.2)
	asse.material_override = Tex.flat(Color(0.42, 0.32, 0.22), 0.94)
	add_child(asse)
	for d in [-1.05, 1.05]:
		var c := MeshInstance3D.new()
		var cm := BoxMesh.new()
		cm.size = Vector3(0.12, 0.9, 0.6)
		c.mesh = cm
		c.position = Vector3(d, 0.45, 0.2)
		c.material_override = Tex.flat(Color(0.22, 0.22, 0.24), 0.8)
		add_child(c)

	var panno := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(2.5, 0.02, 0.72)
	panno.mesh = pm
	panno.position = Vector3(0, 1.01, 0.2)
	panno.material_override = Tex.flat(Color(0.30, 0.08, 0.08), 0.96)
	add_child(panno)

	# La merce sul banco: quattro sagome, una per arma. Non sono modelli —
	# sono quattro volumi che si riconoscono dalla proporzione, che è
	# esattamente quanto serve su un tavolo visto da un metro e mezzo.
	# **La merce sta APPESA AL TELO, non sdraiata sul banco.**
	#
	# Sul piano non si vedeva. Il banco è alto un metro, la telecamera sta a
	# un metro e sette, e da lì il piano si guarda di taglio: una mazza
	# sdraiata è una linea di tre pixel, un coltello sparisce. Appese al
	# telo stanno a un metro e mezzo — cioè esattamente all'altezza degli
	# occhi — e si leggono tutt'e quattro senza avvicinarsi.
	#
	# È anche come sono fatte le bancarelle vere: sul piano ci sta quello
	# che si prende in mano, appeso quello che si deve vedere da lontano.
	# Appise ô telo, spannute ncopp'a Z ch'è 'o luongo d''o banco.
	_mazza(Vector3(-0.62, 1.88, -0.62))
	_coltello(Vector3(-0.62, 1.60, 0.10))
	_pistola(Vector3(-0.62, 1.60, 0.62))
	_kalash(Vector3(-0.62, 1.90, 1.16))

	# **'O fucile overo.** Uno scan vero di una doppietta arrugginita, che
	# è precisamente la cosa che un ferraro di quartiere tiene appesa al
	# telo: le altre quattro sagome sono volumi riconoscibili, questa è
	# l'unica che è proprio un fucile, ed è quella che fa credere alle
	# altre.
	if Models.has_model("fucile"):
		var f := Models.spawn("fucile")
		if f != null:
			f.position = Vector3(-0.62, 2.16, 0.0)
			f.rotation = Vector3(0.0, 0.0, PI * 0.5)
			add_child(f)

	# Sul piano restano un paio di cassette: il banco vuoto sembrava un
	# tavolo da ping pong.
	# **'E ccasse songo scese 'nterra** (0.58). Il modello vero è 72 × 40 ×
	# 55 contro i 42 × 26 × 34 della scatola che sostituiva: appoggiate sul
	# piano si mangiavano il banco intero e nascondevano tutta la merce —
	# si vede nella prima fotografia di prova, dove del banco restavano due
	# casse e basta. Sul piano ci va la roba piccola; le casse stanno per
	# terra di fianco, che è pure dove le tiene un ferraro vero.
	for d in [-1.62, 1.58]:
		var vera := Models.spawn("cascia_legno")
		if vera != null:
			vera.position = Vector3(d, 0.0, 0.34)
			vera.rotation.y = deg_to_rad(18.0 if d < 0.0 else -24.0)
			add_child(vera)
			# **E ncopp'ê ccasse, 'a roba grossa** (0.59): la mazza da
			# baseball e il piede di porco del pacchetto Pandazole, che sul
			# telo non ci stanno (sono lunghi quasi un metro) e sul banco
			# nemmeno. Di traverso sul coperchio, che è alto 0,36.
			var grossa := Models.spawn("mazza_baseball" if d < 0.0 else "piede_di_porco")
			if grossa != null:
				grossa.position = Vector3(d, 0.365, 0.34)
				grossa.rotation.y = deg_to_rad(58.0 if d < 0.0 else -52.0)
				add_child(grossa)
			continue
		var cassa := MeshInstance3D.new()
		var km := BoxMesh.new()
		km.size = Vector3(0.42, 0.26, 0.34)
		cassa.mesh = km
		cassa.position = Vector3(d, 0.13, 0.34)
		cassa.material_override = Tex.flat(Color(0.52, 0.42, 0.28), 0.94)
		add_child(cassa)

	# **'O banco se veste** (0.58). Un ferraro che vende solo quattro armi
	# in croce e niente altro non è un ferraro, è un espositore. Queste
	# nove cose non si comprano e non fanno niente: stanno lì perché è
	# quello che uno vede quando si avvicina davvero al banco, ed è la
	# differenza fra una bancarella e un cartello.
	# **'E assi d''o banco, mesurate e no 'nduvinate.** Il piano è
	# `Vector3(0.3, 1.14, 0)` grande `(0.8, 0.08, 3.3)`: **profondo 0,8
	# su X e lungo 3,3 su Z**. La prima volta avevo scritto la merce come
	# se fosse il contrario — sparsa su X e stretta su Z — e la
	# fotografia l'ha mostrata tutta sospesa a mezz'aria di fianco al
	# bancone, perché metà dei pezzi stava fuori dal piano.
	#
	# Il piano va da x −0,10 a 0,70 e da z −1,65 a 1,65; la merce sta
	# dentro, a y 1,19 (il piano finisce a 1,18).
	for r in [
			["chiuove", Vector3(0.22, 1.19, -1.34), Vector3(0, 40, 0)],
			["cartucce", Vector3(0.34, 1.19, -1.00), Vector3(0, 24, 0)],
			["cascia_munizioni", Vector3(0.24, 1.19, -0.66), Vector3(0, -12, 0)],
			["caricatore", Vector3(0.36, 1.19, -0.30), Vector3(0, 8, 0)],
			["silenziatore", Vector3(0.22, 1.19, 0.04), Vector3(0, 0, 0)],
			["cacciavite", Vector3(0.56, 1.19, 0.48), Vector3(0, 12, 0)],
			["grimaldello", Vector3(0.52, 1.19, 0.86), Vector3(0, -18, 0)],
			["sega", Vector3(0.44, 1.19, 1.30), Vector3(0, 6, 0)],
			# 'A sciabola è luonga 'nu metro e quatte e 'o luongo sujo sta
			# ncopp'a Z: appesa ô telo asceva 'a fore d''o telo stesso (s'è
			# visto dint'â seconda fotografia). Stesa ncopp'ô banco, ca è
			# luongo tre metre e trenta ncopp'ô stesso asse, ce trase.
			["sciabola", Vector3(0.28, 1.19, 0.10), Vector3(0, 0, 0)],
		]:
		var o := Models.spawn(str(r[0]))
		if o == null:
			continue
		o.position = r[1]
		var g: Vector3 = r[2]
		o.rotation = Vector3(deg_to_rad(g.x), deg_to_rad(g.y), deg_to_rad(g.z))
		add_child(o)

	# Il ferraro. Sta dietro al banco, e non si muove mai.
	var p := HumanBuilderScript.build(Color(0.74, 0.72, 0.66),
		Color(0.19, 0.19, 0.21), "", 1.82,
		# **`animate: true` e no `false`.** Con `false` l'Animator non si
		# costruisce proprio e lo scheletro resta nella posa di riposo
		# del rig, **che è la T**: il ferraro stava dietro al banco con
		# le braccia spalancate. Si vede nella prima fotografia di
		# prova, e non l'aveva mai beccato nessuno perché nessuno aveva
		# mai fotografato l'armiere da davanti. Con `true` fa l'idle e
		# sta fermo lo stesso.
		{"belly": 0.5, "bald": true, "moustache": false, "animate": true,
		# (0.66) 'O ferraro: barba e occhi 'e chi nun fa domande.
		"palpebre": "stanche", "sopracciglia": "arraggiate", "naso": "grosso",
		"bocca": "dritta", "barba": "barba", "rughe": "", "cintura": true,
		"colletto": false, "catenina": false})
	var g: Node3D = p["root"]
	g.position = Vector3(0, 0, -0.45)
	# I rig guardano verso -Z: mezzo giro per guardare chi arriva.
	g.rotation.y = PI
	add_child(g)

	# **'O neon ncopp'ô telo** (0.60, PSX): il tubo col riflettore
	# fissato in cima al telo, che illumina il banco. La luce vera resta la
	# lampadina qui sotto; il neon è quello che si vede.
	var neon := Models.spawn("lampada_neon")
	if neon != null:
		neon.position = Vector3(0.0, 2.84, -0.84)
		add_child(neon)

	# Una lampadina nuda appesa: l'unica luce del vicolo cieco.
	var luce := OmniLight3D.new()
	luce.position = Vector3(0, 2.5, 0.6)
	luce.light_color = Color(1.0, 0.86, 0.62)
	luce.light_energy = 1.1
	luce.omni_range = 6.5
	luce.shadow_enabled = false
	add_child(luce)


func _acciaio(scuro: float = 0.0) -> StandardMaterial3D:
	return Tex.flat(Color(0.42, 0.43, 0.46).darkened(scuro), 0.32, 0.85)


## **'O ponte p''e ffierre d''o banco** (0.58).
##
## Le quattro armi sulla bancarella erano volumi riconoscibili fatti di
## scatole: una mazza cilindrica, un coltello di due parallelepipedi, una
## pistola di due, un kalash di sei. Da lontano passavano, e il banco
## dell'armiere sta in fondo a un vicolo cieco dove ci vai apposta e ci
## resti un minuto a scegliere.
##
## Adesso ognuna chiede prima il suo modello al pacchetto PSX. **Le scatole
## restano**, come per le auto dalla 0.14 e per il salotto dalla 0.55: un
## pacchetto di modelli che un domani non c'è non deve lasciare il ferraro
## dietro a un banco vuoto.
##
## `giro` è in gradi perché queste rotazioni si scrivono guardando la
## fotografia, e in gradi si correggono senza fare conti.
func _fierro_muntato(nome: String, p: Vector3, giro: Vector3) -> bool:
	var n := Models.spawn(nome)
	if n == null:
		return false
	n.position = p
	n.rotation = Vector3(deg_to_rad(giro.x), deg_to_rad(giro.y),
		deg_to_rad(giro.z))
	add_child(n)
	return true


func _mazza(p: Vector3) -> void:
	# 'A mazza 'e fierro è "un pezzo di tubo" — 'o dice 'a scheda soja dint'ô
	# GameManager — e dint'ô pacchetto 'nu piezzo 'e tubo ce sta overo.
	# 'O manganello e no 'o tubo: 'o tubo d''o pacchetto è luongo 'nu metro
	# e vinte e ncopp'ô banco pareva 'na canna 'e cannone (l'ha fatto vedé
	# 'a primma fotografia). 'O manganello sta a sessantaquattro, ch'è 'a
	# mesura giusta 'e 'na mazza ca se tene 'n mano — e mo' 'o piezzo ca
	# accatte è 'o stesso ca tiene 'n mano.
	if _fierro_muntato("manganello", p, Vector3(0, 0, 90)):
		return
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.028
	cm.bottom_radius = 0.032
	cm.height = 0.62
	cm.radial_segments = 8
	m.mesh = cm
	m.position = p
	m.rotation.z = PI / 2.0
	m.material_override = _acciaio(0.25)
	add_child(m)


func _coltello(p: Vector3) -> void:
	if _fierro_muntato("curtiello", p, Vector3(0, 90, 0)):
		return
	var lama := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.20, 0.012, 0.035)
	lama.mesh = bm
	lama.position = p
	lama.material_override = _acciaio(-0.1)
	add_child(lama)
	var manico := MeshInstance3D.new()
	var mm := BoxMesh.new()
	mm.size = Vector3(0.11, 0.028, 0.03)
	manico.mesh = mm
	manico.position = p + Vector3(-0.15, 0.0, 0.0)
	manico.material_override = Tex.flat(Color(0.16, 0.11, 0.08), 0.85)
	add_child(manico)


func _pistola(p: Vector3) -> void:
	if _fierro_muntato("fierro", p, Vector3(0, 90, 0)):
		return
	var canna := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(0.17, 0.045, 0.032)
	canna.mesh = cm
	canna.position = p + Vector3(0, 0.05, 0)
	canna.material_override = _acciaio(0.4)
	add_child(canna)
	var impugn := MeshInstance3D.new()
	var im := BoxMesh.new()
	im.size = Vector3(0.045, 0.10, 0.03)
	impugn.mesh = im
	impugn.position = p + Vector3(-0.05, 0.0, 0)
	impugn.rotation.z = -0.28
	impugn.material_override = Tex.flat(Color(0.12, 0.12, 0.13), 0.7)
	add_child(impugn)


func _kalash(p: Vector3) -> void:
	# P''o kalash 'nu modello nun ce sta: resta 'e scatole, e va bbuono
	# accussì — è 'o piezzo cchiù caro e cchiù raro d''o banco.
	var corpo := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(0.52, 0.05, 0.032)
	corpo.mesh = cm
	corpo.position = p + Vector3(0, 0.06, 0)
	corpo.material_override = _acciaio(0.45)
	add_child(corpo)
	# Il caricatore ricurvo: è l'unica linea che rende un kalash
	# riconoscibile a colpo d'occhio, anche fatto di scatole.
	for i in range(3):
		var c := MeshInstance3D.new()
		var m2 := BoxMesh.new()
		m2.size = Vector3(0.05, 0.05, 0.028)
		c.mesh = m2
		c.position = p + Vector3(-0.02 + i * 0.012, 0.02 - i * 0.038, 0)
		c.rotation.z = 0.30 + i * 0.16
		c.material_override = Tex.flat(Color(0.22, 0.18, 0.12), 0.8)
		add_child(c)
	var calcio := MeshInstance3D.new()
	var km := BoxMesh.new()
	km.size = Vector3(0.16, 0.06, 0.03)
	calcio.mesh = km
	calcio.position = p + Vector3(-0.32, 0.05, 0)
	calcio.material_override = Tex.flat(Color(0.34, 0.22, 0.12), 0.88)
	add_child(calcio)


func _build_collisione() -> void:
	var f := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(3.2, 2.6, 1.9)
	f.shape = b
	f.position = Vector3(0, 1.3, -0.2)
	add_child(f)


# ---------------------------------------------------------------------------
# Comprare
# ---------------------------------------------------------------------------

## L'ordine dei tasti 1-4 corrisponde all'ordine sul banco, da sinistra a
## destra: chi guarda il banco e legge il prompt trova le stesse cose nello
## stesso ordine.
const VOCI := ["mazza", "curtiello", "fierro", "kalash"]


func get_interact_prompt(_da: Vector3) -> String:
	var righe: Array = []
	for i in range(VOCI.size()):
		var id: String = VOCI[i]
		var a: Dictionary = GameManager.ARMI[id]
		var tieni: bool = GameManager.armi.has(id)
		righe.append("[%d] %s %s" % [i + 1, str(a["nome"]),
			"(già tuo)" if tieni else "€%d" % int(a["costo"])])
	return "'O FERRARO — " + "  ·  ".join(righe)


func player_interact() -> void:
	_di(SAY_SALUTO[randi() % SAY_SALUTO.size()])


## I tasti 1-4 comprano. Stessa strada della tabaccheria: si ascolta solo
## quando il giocatore sta guardando QUESTO banco, se no premere 1 in mezzo
## alla strada comprerebbe una mazza.
func _physics_process(delta: float) -> void:
	_detto = maxf(0.0, _detto - delta)
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null or pl.get("current_target") != self:
		return
	for i in range(VOCI.size()):
		if Input.is_action_just_pressed("buy_%d" % (i + 1)):
			_compra(str(VOCI[i]))


func _compra(id: String) -> void:
	if GameManager.armi.has(id):
		_di(SAY_TENUTO)
		return
	if not GameManager.compra_arma(id):
		SoundManager.play("fail", -8.0, 0.9)
		_di(SAY_SQUATTRINATO)
		return
	SoundManager.play("kaching", -4.0, 0.95)
	_di(SAY_VENDUTO[randi() % SAY_VENDUTO.size()])
	GameManager.event_started.emit("Hê pigliato %s. (G p''o cagnà)"
		% str(GameManager.ARMI[id]["nome"]))


func _di(t: String) -> void:
	if _detto > 0.0:
		return
	_detto = 1.6
	if _bubble:
		_bubble.say(t, 2.6)
