extends Node3D
## JurnataVista — chello ca se vede d''e ghiornate speciale
##
## **'A 0.52 ha miso 'e nummere, chesta ce mette 'a faccia.**
##
## Il capo: *"La 0.52 ha messo i numeri delle giornate speciali. Adesso
## vanno viste: è la cosa più vistosa che manca."* Aveva ragione, e la
## nota che avevo scritto io in fondo alle note della 0.52 diceva la
## stessa cosa: *"i numeri cambiano, la gente cambia, il biglietto lo dice
## — ma la pioggia non si vede"*.
##
## Un moltiplicatore che nessuno vede è un moltiplicatore di cui nessuno
## si fida. Uno legge sul biglietto che oggi piove, esce, e trova la
## stessa piazza asciutta e assolata di ieri: da lì in poi il biglietto
## diventa una decorazione, e con lui tutto il sistema.
##
## **Quattro giornate, quattro cose diverse da fare.**
##
##   * **'a pioggia** è un effetto continuo, e l'unico che ha bisogno di
##     seguire il giocatore: la pioggia si disegna attorno alla testa, non
##     sulla città (venti ettari di gocce sarebbero un milione di
##     particelle per tre che se ne vedono);
##   * **'o mercato** è roba ferma: bancarelle in più, messe una volta
##     all'inizio e mai più toccate;
##   * **'a prucessione** è una cosa che *passa*: nasce, attraversa, e se
##     ne va — e mentre passa la piazza è chiusa davvero;
##   * **'a partita** non si vede per niente: **si sente**. È un boato dal
##     bar, e l'unica giornata in cui la cosa giusta da fare non era
##     disegnare.
##
## Sta in un nodo suo e non dentro alla città perché è roba che vive un
## giorno: si costruisce la mattina, si butta la sera, e la città non deve
## sapere niente di come è fatta.

const Tex := preload("res://scripts/textures.gd")
const Human := preload("res://scripts/human_builder.gd")
const RobbaPanda := preload("res://scripts/robba_panda.gd")
const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")

# --- 'A pioggia ------------------------------------------------------------
## Quanto è larga la cassa di pioggia attorno al giocatore. Diciotto metri
## bastano: oltre, le gocce sono più piccole di un pixel.
const PIOGGIA_LARGO: float = 18.0
const PIOGGIA_ALTO: float = 12.0
## Quante gocce. Milleseicento sembrano poche scritte così, ma in una
## cassa di diciotto metri sono un acquazzone: la pioggia si legge dalla
## **velocità** delle strisce, non da quante ce ne sono.
const PIOGGIA_QUANTE: int = 1600
const PIOGGIA_VELOCITA: float = 15.0

# --- 'A prucessione --------------------------------------------------------
## Ogni quanto esce la processione, e quanto ci mette ad attraversare.
const PROCESSIONE_OGNI: float = 95.0
const PROCESSIONE_PASSO: float = 0.85
const PROCESSIONE_QUANTI: int = 14

# --- 'A partita ------------------------------------------------------------
## Ogni quanto, più o meno, succede qualcosa al bar.
const PARTITA_OGNI_MIN: float = 22.0
const PARTITA_OGNI_MAX: float = 48.0

var _pioggia: GPUParticles3D = null
var _pioggia_cpu: CPUParticles3D = null
var _giocatore: Node3D = null
var _statua: Node3D = null
var _processione: Array = []
var _proc_t: float = 0.0
var _proc_attiva: bool = false
var _proc_da: Vector3
var _proc_a: Vector3
var _partita_t: float = 0.0
var _gol_casa: int = 0
var _gol_fore: int = 0
var _rng := RandomNumberGenerator.new()

## Il centro della piazza del giocatore: la processione ci passa in mezzo.
var centro_piazza: Vector3 = Vector3(31, 0, 30)


func _ready() -> void:
	add_to_group("jurnata_vista")
	_rng.randomize()
	match GameManager.tipo_giornata:
		"pioggia":
			_fa_chiovere()
		"mercato":
			_apre_o_mercato()
		"processione":
			_prepara_prucessione()
		"partita":
			_partita_t = _rng.randf_range(PARTITA_OGNI_MIN, PARTITA_OGNI_MAX)
	set_process(GameManager.e_speciale())


func _process(delta: float) -> void:
	if _pioggia_cpu != null and is_instance_valid(_pioggia_cpu):
		_segui_o_giocatore()
	match GameManager.tipo_giornata:
		"processione":
			_passo_prucessione(delta)
		"partita":
			_passo_partita(delta)
		"mercato":
			_passo_vociare(delta)


# ---------------------------------------------------------------------------
# 'A PIOGGIA
# ---------------------------------------------------------------------------
#
# **'A pioggia se disegna attuorno â capa, no ncopp'â città.**
#
# La città è duecento metri per centottanta. Una cassa di pioggia grande
# quanto lei, alla densità che serve perché si veda, sarebbe un milione di
# gocce — e novecentonovantamila starebbero dietro alle spalle del
# giocatore o dentro ai palazzi. Invece la cassa è larga diciotto metri e
# **segue la testa**: quello che si vede è identico, e le gocce sono
# milleseicento.
#
# Il trucco funziona perché la pioggia non ha una posizione nel mondo: una
# goccia vale l'altra. Con una processione non si potrebbe fare.

func _fa_chiovere() -> void:
	var p := CPUParticles3D.new()
	p.amount = PIOGGIA_QUANTE
	p.lifetime = PIOGGIA_ALTO / PIOGGIA_VELOCITA
	p.preprocess = p.lifetime          # si comincia con l'acquazzone già in aria
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(PIOGGIA_LARGO * 0.5, 0.1,
		PIOGGIA_LARGO * 0.5)
	p.direction = Vector3(0.08, -1, 0.04)
	p.spread = 1.5
	p.gravity = Vector3(0, -2.0, 0)
	p.initial_velocity_min = PIOGGIA_VELOCITA
	p.initial_velocity_max = PIOGGIA_VELOCITA * 1.15
	p.scale_amount_min = 1.0
	p.scale_amount_max = 1.0

	# La goccia è una strisciolina verticale, non una pallina: a quindici
	# metri al secondo l'occhio vede la scia, e una sfera sembra grandine.
	var goccia := BoxMesh.new()
	goccia.size = Vector3(0.014, 0.34, 0.014)
	p.mesh = goccia
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.72, 0.80, 0.92, 0.55)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.disable_receive_shadows = true
	m.no_depth_test = false
	p.material_override = m
	p.position = Vector3(0, PIOGGIA_ALTO, 0)
	add_child(p)
	_pioggia_cpu = p

	# **'O schizzo 'nterra.** Senza, la pioggia attraversa il selciato e
	# sparisce: sono le gocce che rimbalzano a dire che l'acqua tocca
	# qualcosa. Poche e piccole, ma cambiano tutto.
	var s := CPUParticles3D.new()
	s.amount = 260
	s.lifetime = 0.22
	s.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	s.emission_box_extents = Vector3(PIOGGIA_LARGO * 0.45, 0.02,
		PIOGGIA_LARGO * 0.45)
	s.direction = Vector3(0, 1, 0)
	s.spread = 32.0
	s.gravity = Vector3(0, -14.0, 0)
	s.initial_velocity_min = 0.9
	s.initial_velocity_max = 1.8
	var sm := SphereMesh.new()
	sm.radius = 0.017
	sm.height = 0.034
	sm.radial_segments = 4
	sm.rings = 2
	s.mesh = sm
	var m2 := StandardMaterial3D.new()
	m2.albedo_color = Color(0.80, 0.86, 0.95, 0.40)
	m2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	s.material_override = m2
	s.position = Vector3(0, 0.03, 0)
	add_child(s)

	GameManager.avvisa_strada("Ha accummenciato a chiòvere.")


func _segui_o_giocatore() -> void:
	if _giocatore == null or not is_instance_valid(_giocatore):
		_giocatore = get_tree().get_first_node_in_group("player") as Node3D
	if _giocatore == null or not is_instance_valid(_giocatore):
		# **Si nun ce sta 'o giocatore, se va appriesso â camera.** Serve
		# nelle prove (dove il giocatore non c'e') ma non solo: la pioggia
		# deve stare dove si guarda, e il giocatore e la camera sono la
		# stessa cosa tranne nei momenti in cui non lo sono.
		_giocatore = get_viewport().get_camera_3d()
		if _giocatore == null:
			return
	# **Sulo x e z.** Se seguisse anche l'altezza, salendo su un muretto la
	# pioggia salirebbe con te e resteresti sempre a dodici metri dal
	# cielo: il quartiere sotto resterebbe asciutto.
	var dove: Vector3 = _giocatore.global_position
	global_position = Vector3(dove.x, 0.0, dove.z)


# ---------------------------------------------------------------------------
# 'O MERCATO
# ---------------------------------------------------------------------------
#
# Le bancarelle fisse della Via d''e Spighe stanno già nella città e non si
# toccano. Queste sono **quelle in più**: il giorno di mercato le
# bancarelle escono anche fuori dal quartiere loro, lungo il Corso e nella
# piazza — che è esattamente come funziona, il mercato non sta dentro a un
# recinto, si allarga.

## **Nun ce ne stanno dint'â piazza toia, e ce sta 'nu motivo.**
##
## Le prime che avevo messo stavano a x=22, cioè otto metri dentro al bordo
## della tua piazza — in mezzo ai posti auto. Una bancarella con il
## collider piantata dove deve fermarsi una berlina non è "la strada che si
## stringe": è una macchina che non si può più posteggiare, cioè il gioco
## che si rompe il giorno di mercato. Il mercato si allarga **sulle
## strade** (il Corso e il largo di tramontana), non sul posto di lavoro.
const POSTI_MERCATO := [
	# lungo 'o Corso, 'e ddoje file
	[74.0, 34.0], [74.0, 42.0], [74.0, 50.0], [74.0, 58.0],
	[86.0, 38.0], [86.0, 46.0], [86.0, 54.0], [86.0, 62.0],
	# e cchiù ncoppa, addò 'o Corso se fa largo
	[74.0, 68.0], [86.0, 70.0],
	# 'o largo 'e tramontana
	[100.0, 132.0], [108.0, 132.0], [116.0, 132.0],
]

const TELI := [Color(0.75, 0.25, 0.22), Color(0.22, 0.42, 0.60),
	Color(0.85, 0.70, 0.25), Color(0.30, 0.50, 0.32)]


func _apre_o_mercato() -> void:
	for i in range(POSTI_MERCATO.size()):
		var p: Array = POSTI_MERCATO[i]
		_bancarella(Vector3(float(p[0]), 0.0, float(p[1])), i)
	_monta_gruppi_panda()
	GameManager.avvisa_strada(
		"Oggi ce sta 'o mercato: 'a via s'è chiena 'e bancarelle.")


func _bancarella(base: Vector3, i: int) -> void:
	# Un nodo per bancarella, e non solo per ordine: è da qui che parte la
	# voce (vedi `_passo_vociare`). Senza un nodo con una posizione, il
	# fumetto non saprebbe da dove uscire.
	var posto := Node3D.new()
	posto.position = base
	add_child(posto)
	_banche.append(posto)

	var banco := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.6, 0.8, 1.4)
	banco.mesh = bm
	banco.position = base + Vector3(0, 0.4, 0)
	banco.material_override = Tex.flat(Color(0.45, 0.32, 0.2), 0.9)
	add_child(banco)

	var telo := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(3.0, 0.12, 1.8)
	telo.mesh = tm
	telo.position = base + Vector3(0, 2.25, 0)
	telo.material_override = Tex.flat(TELI[i % TELI.size()], 0.9)
	add_child(telo)

	for dx in [-1.3, 1.3]:
		for dz in [-0.8, 0.8]:
			var palo := MeshInstance3D.new()
			var pm := BoxMesh.new()
			pm.size = Vector3(0.07, 2.25, 0.07)
			palo.mesh = pm
			palo.position = base + Vector3(dx, 1.12, dz)
			palo.material_override = Tex.flat(Color(0.3, 0.3, 0.32), 0.6)
			add_child(palo)

	# Le cassette sopra al banco: quattro scatole di due colori e il banco
	# smette di essere un tavolo.
	# **Dalla 0.59 so' cascette overe** (vedi `RobbaPanda.cascetta_chiena`):
	# la cassetta di legno, il letto del colore della frutta, e la frutta
	# sopra. Le scatole restano se i modelli mancano.
	if ResourceLoader.exists("res://assets/models/cascetta_2.mesh"):
		var rng := RandomNumberGenerator.new()
		rng.seed = 7300 + i * 13
		for k in range(4):
			var f: String = str(FRUTTA_BANCARELLA[(i * 4 + k) % FRUTTA_BANCARELLA.size()])
			for pz in RobbaPanda.cascetta_chiena(f, base + Vector3(-0.9 + k * 0.6, 0.8, 0.0),
					PI * 0.5 + rng.randf_range(-0.06, 0.06), rng):
				if pz.has("letto"):
					var chiave: String = (pz["letto"] as Color).to_html(false)
					if not _gruppi_letto.has(chiave):
						_gruppi_letto[chiave] = [pz["letto"], []]
					(_gruppi_letto[chiave][1] as Array).append(pz["t"])
				else:
					var nome: String = str(pz["nome"])
					if not _gruppi_panda.has(nome):
						_gruppi_panda[nome] = []
					(_gruppi_panda[nome] as Array).append(pz["t"])
	else:
		_scatole_d_o_banco(base)

	_muro_d_a_bancarella(base)


## La frutta delle bancarelle del giorno di mercato: in giro sulla lista,
## così ogni banco ne ha quattro diverse.
const FRUTTA_BANCARELLA := ["arancia", "pummarola", "limone", "mela",
	"mulignana", "peperone", "patana", "friariello", "uva", "banana",
	"cepolla", "mandarino", "carota", "pera", "aglio", "cetriolo"]
var _gruppi_panda: Dictionary = {}
var _gruppi_letto: Dictionary = {}


## Tutti i pezzi delle bancarelle in un MultiMesh per forma (e uno per
## colore di letto): tredici banchi con quattro cassette piene fanno
## trecento pezzi, e trecento nodi per un giorno di mercato non si spendono.
func _monta_gruppi_panda() -> void:
	for nome in _gruppi_panda:
		var mesh: Mesh = load("res://assets/models/%s.mesh" % nome)
		if mesh == null:
			continue
		_un_gruppo(mesh, _gruppi_panda[nome], null)
	var cubo := BoxMesh.new()
	for chiave in _gruppi_letto:
		var voce: Array = _gruppi_letto[chiave]
		_un_gruppo(cubo, voce[1], Tex.flat(voce[0], 0.8))
	_gruppi_panda.clear()
	_gruppi_letto.clear()


func _un_gruppo(mesh: Mesh, lista: Array, mat: Material) -> void:
	var centro := Vector3.ZERO
	for t in lista:
		centro += (t as Transform3D).origin
	centro /= float(maxi(1, lista.size()))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = lista.size()
	for k in range(lista.size()):
		var t: Transform3D = lista[k]
		t.origin -= centro
		mm.set_instance_transform(k, t)
	var n := MultiMeshInstance3D.new()
	n.multimesh = mm
	n.position = centro
	if mat != null:
		n.material_override = mat
	n.visibility_range_end = 70.0
	n.visibility_range_end_margin = 6.0
	add_child(n)


func _scatole_d_o_banco(base: Vector3) -> void:
	for k in range(4):
		var c := MeshInstance3D.new()
		var cm := BoxMesh.new()
		cm.size = Vector3(0.5, 0.22, 0.4)
		c.mesh = cm
		c.position = base + Vector3(-0.9 + k * 0.6, 0.91, 0.0)
		c.material_override = Tex.flat(
			Color(0.86, 0.62, 0.20) if k % 2 == 0 else Color(0.52, 0.66, 0.28),
			0.85)
		add_child(c)


func _muro_d_a_bancarella(base: Vector3) -> void:
	# **'A via se stregne.** La bancarella non è solo grafica: ha un muro.
	# È quello che il capo ha chiesto — *"la strada stretta che cambia dove
	# passano le macchine"* — e si ottiene con un collider, non con un
	# disegno.
	var muro := StaticBody3D.new()
	muro.collision_layer = 1
	muro.collision_mask = 0
	muro.position = base
	add_child(muro)
	var f := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(2.8, 2.4, 1.6)
	f.shape = b
	f.position = Vector3(0, 1.2, 0)
	muro.add_child(f)


# ---------------------------------------------------------------------------
# 'A PRUCESSIONE
# ---------------------------------------------------------------------------
#
# **'Na prucessione è 'na cosa ca passa.** Non è un pezzo di scenografia:
# nasce da un lato della piazza, attraversa, e sparisce dall'altro. Mentre
# passa, la fila **è un muro** — i corpi hanno il collider — e quello è il
# "mezza piazza davvero chiusa" che il capo ha chiesto: non un
# moltiplicatore che dice che passano meno macchine, ma quattordici
# persone in fila indiana in mezzo alla strada.
#
# Poi se ne va, e la piazza torna. E dopo un minuto e mezzo ripassa,
# perché una processione che passa una volta sola in sette minuti di gioco
# è una cosa che quasi nessuno vede.

func _prepara_prucessione() -> void:
	_proc_t = 8.0
	GameManager.avvisa_strada(
		"Sta ascenno 'a prucessione. 'A piazza se chiude.")


func _passo_prucessione(delta: float) -> void:
	if not _proc_attiva:
		_proc_t -= delta
		if _proc_t <= 0.0:
			_esce_a_prucessione()
		return

	var fernuta := true
	for i in range(_processione.size()):
		var n: Node3D = _processione[i]
		if not is_instance_valid(n):
			continue
		var mira: Vector3 = _proc_a - (_proc_a - _proc_da).normalized() \
			* float(i) * 1.5
		var primma: Vector3 = n.global_position
		n.global_position = n.global_position.move_toward(mira,
			PROCESSIONE_PASSO * delta)
		# **Guardano addò vanno.** Senza, la fila cammina di traverso come
		# un banco di pesci spinto dalla corrente: `forward(θ) =
		# (−sinθ, 0, −cosθ)`, quindi `θ = atan2(−dx, −dz)`.
		var passo: Vector3 = n.global_position - primma
		if passo.length() > 0.001:
			n.rotation.y = atan2(-passo.x, -passo.z)
		# **E camminano overo** (0.59). La fila si spostava a passi di
		# `move_toward` e nessuno diceva alle gambe di muoversi: quattordici
		# devoti e quattro portatori che **scivolavano** in posa d'attesa
		# per cinquanta metri. Adesso ognuno dice al suo animatore quanto
		# va veloce, e fermo vuol dire fermo.
		for a in n.get_meta("anime", []):
			if is_instance_valid(a):
				a.set_speed(passo.length() / maxf(delta, 0.0001))
		if n.global_position.distance_to(mira) > 0.4:
			fernuta = false
	if fernuta:
		_se_ne_va_a_prucessione()


func _esce_a_prucessione() -> void:
	_proc_attiva = true
	var dritta: Vector3 = Vector3(1, 0, 0)
	_proc_da = centro_piazza - dritta * 26.0
	_proc_a = centro_piazza + dritta * 26.0
	SoundManager.play("folla", -9.0, 0.82)
	GameManager.avvisa_strada("Ecco 'a prucessione. Passa 'a Maronna.")

	# **'A statua 'nnanze.** È quella che fa capire in un colpo che cos'è
	# quella fila: senza, sono quattordici persone che camminano.
	# **`add_child()` primma, 'a posizione appriesso.** `global_position`
	# ncopp'a 'nu nodo ca nun sta ancora dint'a ll'albero nun vò dì niente:
	# Godot strilla `!is_inside_tree()` e 'a scrive dint'ô vuoto. La
	# processione partiva dall'origine del mondo invece che dal bordo
	# della piazza.
	_statua = _fa_a_statua()
	add_child(_statua)
	_statua.global_position = _proc_da
	_processione.append(_statua)

	for i in range(PROCESSIONE_QUANTI):
		var chi := _fa_nu_divoto(i)
		add_child(chi)
		chi.global_position = _proc_da - dritta * (1.5 * float(i + 1))
		_processione.append(chi)


func _se_ne_va_a_prucessione() -> void:
	for n in _processione:
		if is_instance_valid(n):
			n.queue_free()
	_processione.clear()
	_statua = null
	_proc_attiva = false
	_proc_t = PROCESSIONE_OGNI


## La statua: una base, una figura in bianco e azzurro, e quattro portatori
## che la reggono. Non serve che sia bella, serve che si riconosca da
## lontano — e una macchia bianca e azzurra sopra alla folla si riconosce.
func _fa_a_statua() -> Node3D:
	var root := Node3D.new()

	var barella := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.6, 0.16, 1.1)
	barella.mesh = bm
	barella.position = Vector3(0, 1.35, 0)
	barella.material_override = Tex.flat(Color(0.42, 0.28, 0.16), 0.85)
	root.add_child(barella)

	var corpo := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.16
	cm.bottom_radius = 0.34
	cm.height = 1.15
	corpo.mesh = cm
	corpo.position = Vector3(0, 2.0, 0)
	corpo.material_override = Tex.flat(Color(0.30, 0.42, 0.78), 0.75)
	root.add_child(corpo)

	var capa := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.14
	hm.height = 0.28
	capa.mesh = hm
	capa.position = Vector3(0, 2.68, 0)
	capa.material_override = Tex.flat(Color(0.94, 0.90, 0.84), 0.6)
	root.add_child(capa)

	# L'aureola: un anello dorato che luccica. È il dettaglio che la fa
	# leggere come una statua e non come un manichino su un tavolo.
	var aureola := MeshInstance3D.new()
	var am := TorusMesh.new()
	am.inner_radius = 0.17
	am.outer_radius = 0.22
	aureola.mesh = am
	aureola.position = Vector3(0, 2.86, 0)
	var mo := StandardMaterial3D.new()
	mo.albedo_color = Color(0.98, 0.84, 0.32)
	mo.emission_enabled = true
	mo.emission = Color(0.98, 0.84, 0.32)
	mo.emission_energy_multiplier = 0.9
	aureola.material_override = mo
	root.add_child(aureola)

	# I quattro portatori, uno per angolo della barella. Dalla 0.59 in
	# camicia bianca (gli omini del pacchetto nuovo), come si porta una
	# statua, e con le gambe che camminano (vedi `_passo_prucessione`).
	var anime: Array = []
	for a in [Vector3(-0.7, 0, -0.5), Vector3(0.7, 0, -0.5),
			Vector3(-0.7, 0, 0.5), Vector3(0.7, 0, 0.5)]:
		var parts := Human.build(Color(0.92, 0.92, 0.90),
			Color(0.14, 0.14, 0.16), "", 1.74,
			{"modello": "omo_camicia" if a.x < 0.0 else "omo_camicia_liscio"})
		var u: Node3D = parts["root"]
		u.position = a
		root.add_child(u)
		if parts.get("anim") != null:
			anime.append(parts["anim"])
	root.set_meta("anime", anime)

	_muro_e_carne(root, Vector3(2.0, 2.0, 1.6))
	return root


func _fa_nu_divoto(i: int) -> Node3D:
	var root := Node3D.new()
	# Vestiti scuri, come si va a una processione.
	var tinte: Array[Color] = [Color(0.18, 0.18, 0.22), Color(0.24, 0.20, 0.20),
		Color(0.16, 0.20, 0.24), Color(0.30, 0.26, 0.24)]
	var camicia: Color = tinte[i % tinte.size()]
	# **'E divote nun so' tutte 'o stesso pupo** (0.59): una su tre è una
	# donna vestita di scuro, gli altri sono gli uomini del pacchetto nuovo
	# in giacca e cravatta — a una processione si va vestiti bene.
	var opts := {}
	if i % 3 == 0:
		opts["corpo"] = "femmina"
	else:
		opts["modello"] = ["omo_giacca", "omo_giacca_liscio", "omo_camicia",
			"omo_maniche"][i % 4]
	var parts := Human.build(camicia, Color(0.14, 0.14, 0.16), "",
		1.66 + float(i % 3) * 0.05, opts)
	root.add_child(parts["root"])
	# Le gambe: chi lo muove glielo dice (vedi `_passo_prucessione`).
	root.set_meta("anime", [parts["anim"]] if parts.get("anim") != null else [])

	# Una candela ogni tre: la fila si legge di notte, e di giorno è un
	# puntino caldo che si muove.
	if i % 3 == 0:
		var cera := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.02
		cm.bottom_radius = 0.02
		cm.height = 0.3
		cera.mesh = cm
		cera.position = Vector3(0.24, 1.2, 0.16)
		cera.material_override = Tex.flat(Color(0.94, 0.92, 0.84), 0.7)
		root.add_child(cera)
		var fiamma := OmniLight3D.new()
		fiamma.position = Vector3(0.24, 1.38, 0.16)
		fiamma.light_color = Color(1.0, 0.76, 0.42)
		fiamma.light_energy = 0.7
		fiamma.omni_range = 2.4
		root.add_child(fiamma)

	_muro_e_carne(root, Vector3(0.7, 1.8, 0.7))
	return root


## Il collider che rende la fila un muro. È la differenza fra una
## processione e una cartolina.
func _muro_e_carne(dove: Node3D, dim: Vector3) -> void:
	var b := StaticBody3D.new()
	b.collision_layer = 1
	b.collision_mask = 0
	dove.add_child(b)
	var f := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = dim
	f.shape = box
	f.position = Vector3(0, dim.y * 0.5, 0)
	b.add_child(f)


# ---------------------------------------------------------------------------
# 'A PARTITA
# ---------------------------------------------------------------------------
#
# **Chesta nun se vede: se sente.**
#
# È l'unica delle quattro in cui disegnare sarebbe stato lo sbaglio. Una
# partita, per chi sta in strada, è un boato che arriva da dietro una
# vetrina — e il fatto che tu **non** la vedi è tutto il punto: stai
# lavorando mentre il quartiere fa un'altra cosa.
#
# Il risultato si costruisce mentre la giornata va avanti, e il cartello
# lo dice come lo direbbe uno che passa davanti al bar.

const BOATO := [
	"GOOOL! 'O bar è asciuto pazzo. Se sente 'a ccà.",
	"Hanno segnato. 'A gente 'n copp'ê tavule.",
	"Boato d''o bar: 'nu gol.",
]
const MUGUGNO := [
	"'Nu strillo 'a dint'ô bar. Rigore contra.",
	"S'è sentuto 'nu «mannaggia» ca ha fatto tremmà 'e vitre.",
	"Palo. 'O bar s'è azzittuto tutto 'nzieme.",
]


## **'A partita fernesce.** Novanta minuti sono novanta minuti: dopo otto
## o nove cose successe al bar, l'arbitro fischia e il quartiere esce
## tutto insieme. Senza questa riga si arrivava a undici a due, che non è
## una partita, è una barzelletta — e soprattutto il boato non finiva mai,
## e un boato che non finisce smette di essere un boato.
const PARTITA_QUANTE: int = 9

var _fatte: int = 0
var _fernuta: bool = false


func _passo_partita(delta: float) -> void:
	if _fernuta:
		return
	_partita_t -= delta
	if _partita_t > 0.0:
		return
	_partita_t = _rng.randf_range(PARTITA_OGNI_MIN, PARTITA_OGNI_MAX)
	_fatte += 1
	if _fatte >= PARTITA_QUANTE:
		_fernisce_a_partita()
		return
	if _rng.randf() < 0.42:
		_gol_casa += 1
		SoundManager.play("urlo", -7.0, _rng.randf_range(0.94, 1.06))
		GameManager.avvisa_strada("%s  (%d-%d)" % [
			BOATO[_rng.randi() % BOATO.size()], _gol_casa, _gol_fore])
	else:
		if _rng.randf() < 0.45:
			_gol_fore += 1
		SoundManager.play("fail", -12.0, 0.8)
		GameManager.avvisa_strada("%s  (%d-%d)" % [
			MUGUGNO[_rng.randi() % MUGUGNO.size()], _gol_casa, _gol_fore])


func _fernisce_a_partita() -> void:
	_fernuta = true
	SoundManager.play("folla", -5.0, 1.0)
	var comme := "'nu pareggio"
	if _gol_casa > _gol_fore:
		comme = "hanno vinto"
	elif _gol_fore > _gol_casa:
		comme = "hanno perzo"
	GameManager.avvisa_strada(
		"Fernuta 'a partita: %d-%d, %s. Mo' scenne tutto 'o quartiere 'nzieme."
			% [_gol_casa, _gol_fore, comme])


# ---------------------------------------------------------------------------
# 'O VOCIARE D''O MERCATO
# ---------------------------------------------------------------------------
#
# **'O mercato nun se sente**, diceva 'a nota d''a 0.53 — e ci è rimasta
# due versioni. C'erano tredici bancarelle col telo a colori e le cassette
# sopra, e attorno il silenzio: cioè un mercato fotografato, non un
# mercato.
#
# E il suono qui non è decorazione: **un mercato è una cosa che si sente
# prima di vederla.** Giri l'angolo del Corso e senti che da qualche parte
# c'è gente che urla i prezzi, e quello ti dice che oggi la via è diversa
# prima ancora che tu veda un telo.
#
# Come è fatto, e perché non serve nessun file audio nuovo: ogni tanto una
# bancarella **grida il suo prezzo** con un fumetto, e insieme parte il
# verso della folla che c'è già in libreria (`folla`), a un volume che
# scende con la distanza. Da venti metri è un brusio; da tre è uno che ti
# urla in faccia che le zucchine sono a un euro.

const VOCIARE_OGNI_MIN: float = 2.6
const VOCIARE_OGNI_MAX: float = 6.5
## Oltre questi metri non si sente: se no il mercato urla in tutta la città.
const VOCIARE_PORTATA: float = 34.0

const VOCIARE := [
	"'A zucchin'! 'A zucchin' bell''a zucchin'!",
	"Dumila lire 'o chilo! Dumila!",
	"Signò, vulite 'e pummarole? Fresche 'e stammatina!",
	"Aùnne aùnne aùnne! Tutto a 'n'euro!",
	"'E llimone 'e Surriento! Accattateve 'e llimone!",
	"Guagliò, viene ccà ca te faccio 'nu prezzo!",
	"Fresca 'a mulignana! Fresca!",
	"E chi 'o vò? Chi 'o vò? Ccà stongo!",
	"Doje casse p''o prezzo 'e una, signò!",
	"'O ppane cavero! Asciuto mo' 'a dinto ô furno!",
]

var _vociare_cd: float = 2.0


## Le bancarelle da cui può partire una voce: le riempie `_apre_o_mercato`.
var _banche: Array[Node3D] = []


func _passo_vociare(delta: float) -> void:
	if _banche.is_empty():
		return
	_vociare_cd -= delta
	if _vociare_cd > 0.0:
		return
	_vociare_cd = randf_range(VOCIARE_OGNI_MIN, VOCIARE_OGNI_MAX)

	var pl := get_tree().get_first_node_in_group("player")
	if pl == null or not (pl is Node3D):
		return
	var dove: Vector3 = (pl as Node3D).global_position

	# Grida la bancarella più vicina a te fra quelle che ti possono
	# sentire: gridare da una che sta dall'altra parte della città
	# vorrebbe dire una voce senza nessuno sotto.
	var scelta: Node3D = null
	var meglio: float = VOCIARE_PORTATA
	for b in _banche:
		if not is_instance_valid(b):
			continue
		var d: float = dove.distance_to(b.global_position)
		# Non proprio la più vicina: fra quelle a portata, una a sorte
		# vicino a te. Se no urla sempre la stessa.
		if d < meglio and randf() < 0.55:
			meglio = d
			scelta = b
	if scelta == null:
		return

	var bolla = SpeechBubbleScript.new()
	bolla.position = Vector3(0, 2.5, 0)
	scelta.add_child(bolla)
	bolla.say(VOCIARE[randi() % VOCIARE.size()], 3.2)
	# Il volume scende con la distanza: a trenta metri è un brusio, a tre
	# è uno che ti urla in faccia.
	var vol: float = lerpf(-9.0, -27.0, clampf(meglio / VOCIARE_PORTATA, 0.0, 1.0))
	SoundManager.play("folla", vol, randf_range(0.92, 1.08))
	if randf() < 0.3:
		SoundManager.play_uno(["saluto", "saluto2"], vol - 3.0,
			randf_range(0.88, 1.12))
