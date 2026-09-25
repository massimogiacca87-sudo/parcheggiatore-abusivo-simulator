extends RigidBody3D
## Pallone3D — 'o Super Santos
##
## In un angolo della piazza c'è una porta disegnata fra due cassette e un
## Super Santos, quello arancione da due euro col quale è cresciuta mezza
## Italia. Ci cammini contro e parte; se lo prendi al volo parte più forte e
## più alto. Se entra, è gol.
##
## ## Perché adesso è un corpo rigido vero
##
## Prima la fisica era scritta a mano: posizione più velocità per delta,
## gravità costante, rimbalzo sul piano y = raggio. Funzionava per un
## campetto vuoto, ma aveva un difetto grosso — **il pallone attraversava
## tutto**. Muri, auto in sosta, cassonetti, palazzi. In una piazza aperta si
## notava poco; in un quartiere di vicoli da quattro metri, dove il pallone
## dovrebbe rimbalzare da un muro all'altro, era la cosa che rovinava il
## gioco.
##
## Rifarlo a mano voleva dire riscrivere il rilevamento delle collisioni,
## cioè riscrivere male quello che il motore fa già bene. Adesso è un
## `RigidBody3D` con una sfera e un materiale fisico: rimbalza contro
## qualunque cosa abbia un collider, rotola da solo, si ferma da solo.
##
## Le tre cose che ho dovuto aggiungere sopra alla fisica del motore, e il
## perché:
##
##   1. **Tetto alla velocità.** Un calcio al volo dava impulsi tali da far
##      passare il pallone attraverso un muro fra un fotogramma e l'altro.
##      C'è la `continuous_cd`, ma sopra una certa velocità non basta.
##   2. **Soglia di quiete.** Un corpo rigido su un piano perfetto continua
##      a strisciare per sempre con velocità millimetriche. Sotto una certa
##      soglia lo si ferma di netto.
##   3. **Ritorno a casa.** Se finisce fuori dalla piazza o si incastra, dopo
##      un po' torna al centro: senza, dopo un tiro sbagliato l'attività
##      finiva lì.

const Tex := preload("res://scripts/textures.gd")

const RAGGIO: float = 0.215          # un pallone di gomma vero
const MASSA: float = 0.42

## **Quanto forte parte** — e qui sta il rifacimento d''a 0.56.
##
## Il capo: *«Migliora la fisica del pallone con cui giocano i ragazzini, al
## momento è difficile controllarlo e segnare.»*
##
## Il difetto non era la fisica del motore, che era già giusta: era che
## **ogni contatto era una cannonata**. Qualunque cosa facessi — ci
## camminavi contro piano piano, gli passavi accanto — partivano 6,2 metri
## al secondo e **2,4 di alzo**: il pallone schizzava per aria e finiva a
## dieci metri. Con un rimbalzo del genere non lo porti da nessuna parte, e
## la porta la becchi per sbaglio.
##
## Adesso il tocco **vale quanto ci metti dentro**:
##
## * fermo o quasi → `TOCCO`, una spinta da niente, quasi senza alzo: il
##   pallone rotola davanti a te e te lo porti appresso;
## * a passo normale → in mezzo;
## * di corsa → `CALCIO` pieno, che è il tiro;
## * in salto o in aria → `CALCIO_AL_VOLO`, la botta, e quella sì che vola.
##
## L'alzo non è più una costante: è una frazione della forza. Una spinta da
## fermo alza il pallone di dieci centimetri, una botta al volo lo manda
## sopra la testa. È la stessa regola per tutti e quattro i casi, ed è il
## motivo per cui adesso si riesce a **condurre** il pallone.
const TOCCO: float = 2.6
const CALCIO: float = 6.6
const CALCIO_AL_VOLO: float = 10.2
## L'alzo è una frazione della forza, non un numero a sé: 0,17 vuol dire che
## un tocco da 2,6 alza 0,44 (rotola) e una botta da 10 alza 1,7 (vola).
const ALZO_QUOTA: float = 0.17
const ALZO_QUOTA_AL_VOLO: float = 0.46
## Mezzo secondo fra un tocco e l'altro. Prima erano tre decimi, e col
## giocatore appiccicato al pallone partivano tre calci di fila in direzioni
## diverse: sembrava che scappasse.
const RICARICA_CALCIO: float = 0.46

## **'A mira** (0.56).
##
## Segnare con una palla di gomma, in prima persona, senza mirino, mirando
## col corpo, è più difficile di quanto sembri: basta mezzo metro di
## scarto sul punto d'impatto e il tiro va a finire sul muro. Quindi il
## tiro si **piega verso la porta** — ma solo se già ci stavi puntando, e
## solo se sei abbastanza vicino da poterci arrivare.
##
## Non è barare: è quello che fanno tutti i giochi di calcio arcade, e
## senza, in un campetto di piazza, non segneresti mai.
const MIRA_DISTANZA: float = 24.0   # oltre, sei fuori tiro: nessun aiuto
const MIRA_CONO: float = 0.62       # quanto larga la mira (cos ≈ 52°)
const MIRA_FORZA: float = 0.55      # quanto piega, al massimo

## Oltre questa velocità il pallone comincia a bucare i muri: si tronca.
const VELOCITA_MASSIMA: float = 22.0
## Sotto questa, è fermo. Se no striscia in eterno.
const QUIETE: float = 0.22
const FERMO_PER: float = 0.35

const RESET_DOPO: float = 16.0
const LONTANO_DA_CASA: float = 26.0

const SAY_GOAL := ["GOOOOL!", "MA CHE TIRO!", "'O CAMPIONE!", "GOOOL 'E CAPA!"]

var home: Vector3
var goal_center: Vector3
var goal_width: float = 3.2
var goal_height: float = 2.0
## Da che parte si entra. Al campetto della piazza si tira verso −Z, che è
## il caso normale; i guaglioni invece hanno le porte di zainetti messe
## lungo X, e senza questo il gol da quella parte non si contava proprio.
var goal_normale: Vector3 = Vector3(0, 0, -1)

## **'E gol se pavano sulo si 'o pallone ll'hê tuccato tu.**
##
## Quando il pallone sta nel campetto dei guaglioni, quelli tirano ogni
## dieci secondi — e se ogni loro gol pagasse, bastava mettersi a guardare
## per fare più soldi che a lavorare. Vale quello che hai toccato per
## ultimo tu: è la stessa regola del calcio vero, e si spiega da sola.
var _tuo: bool = false

var _mesh: MeshInstance3D
var _kick_cd: float = 0.0
var _fermo_da: float = 0.0
var _lontano_da: float = 0.0


func _ready() -> void:
	add_to_group("palloni")
	mass = MASSA
	# Il pallone collide col mondo (1) e con le auto e la gente (4), ma non
	# fa parte di nessuno dei due: sta sul suo strato.
	collision_layer = 8
	collision_mask = 1 | 4
	# Senza questa, un tiro forte lo fa passare attraverso un muro sottile
	# fra un fotogramma e l'altro.
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 4
	# L'attrito angolare è quello che lo fa rallentare rotolando; quello
	# lineare quasi niente, se no sembra che rotoli nella sabbia.
	linear_damp = 0.22
	angular_damp = 0.55
	physics_material_override = _materiale()
	_build_visual()
	_build_collisione()


## Rimbalzo e attrito. Un Super Santos è gomma dura gonfiata poco: rimbalza
## bene ma non come una palla da basket.
func _materiale() -> PhysicsMaterial:
	var m := PhysicsMaterial.new()
	m.bounce = 0.62
	m.friction = 0.55
	m.rough = true
	return m


func setup(start: Vector3, goal_pos: Vector3) -> void:
	home = start + Vector3(0, RAGGIO + 0.05, 0)
	goal_center = goal_pos
	global_position = home


func _build_visual() -> void:
	_mesh = MeshInstance3D.new()
	var sfera := SphereMesh.new()
	sfera.radius = RAGGIO
	sfera.height = RAGGIO * 2.0
	sfera.radial_segments = 24
	sfera.rings = 14
	_mesh.mesh = sfera

	# La livrea vera del Super Santos: arancione, con le losanghe nere e la
	# scritta. La texture è la UV del modello originale; mappata su una sfera
	# le losanghe girano intorno all'equatore, che è dove stanno anche su un
	# pallone vero.
	var mat := StandardMaterial3D.new()
	var tex_path := "res://assets/textures/supersantos.jpg"
	if ResourceLoader.exists(tex_path):
		mat.albedo_texture = load(tex_path)
	else:
		mat.albedo_color = Color(0.92, 0.38, 0.10)
	mat.roughness = 0.68
	mat.metallic = 0.0
	_mesh.material_override = mat
	add_child(_mesh)

	# Ombra di contatto: un dischetto scuro che segue il pallone a terra.
	# Senza, quando è in aria non si capisce dove ricadrà.
	var ombra := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(RAGGIO * 2.3, RAGGIO * 2.3)
	ombra.mesh = pm
	ombra.name = "Ombra"
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0, 0, 0, 0.34)
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ombra.material_override = sm
	ombra.top_level = true      # non ruota col pallone
	add_child(ombra)


func _build_collisione() -> void:
	var f := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = RAGGIO
	f.shape = s
	add_child(f)


func _physics_process(delta: float) -> void:
	if _kick_cd > 0.0:
		_kick_cd -= delta
	_check_kick()
	_tetto_velocita()
	_quiete(delta)
	_ombra()
	_check_goal()
	_check_perso(delta)


## Nessuna velocità sopra il tetto: è l'unica cosa che impedisce a un tiro
## al volo di finire dentro a un palazzo.
func _tetto_velocita() -> void:
	var v := linear_velocity.length()
	if v > VELOCITA_MASSIMA:
		linear_velocity = linear_velocity / v * VELOCITA_MASSIMA


## Un corpo rigido su un piano non si ferma mai del tutto: continua a
## strisciare di un millimetro al secondo. Sotto la soglia lo si addormenta.
func _quiete(delta: float) -> void:
	if linear_velocity.length() < QUIETE and absf(linear_velocity.y) < QUIETE:
		_fermo_da += delta
		if _fermo_da > FERMO_PER:
			linear_velocity = Vector3.ZERO
			angular_velocity = Vector3.ZERO
	else:
		_fermo_da = 0.0


## L'ombra sta sempre a terra sotto al pallone, e si stringe quando il
## pallone è alto.
func _ombra() -> void:
	var o := get_node_or_null("Ombra")
	if o == null:
		return
	var h: float = maxf(0.0, global_position.y - RAGGIO)
	o.global_position = Vector3(global_position.x, home.y - RAGGIO + 0.02,
		global_position.z)
	var s: float = clampf(1.0 - h * 0.16, 0.35, 1.0)
	o.scale = Vector3(s, 1.0, s)
	var m: StandardMaterial3D = o.material_override
	if m:
		m.albedo_color.a = 0.34 * s


## Se il player ci finisce addosso, parte.
##
## La direzione non è "avanti": è la retta che va dal giocatore al centro
## del pallone, cioè dove l'hai colpito. Prenderlo di punta lo manda dritto,
## prenderlo di lato lo apre — ed è quello che rende soddisfacente calciare.
func _check_kick() -> void:
	if _kick_cd > 0.0:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return
	var d: Vector3 = global_position - player.global_position
	d.y = 0.0
	if d.length() > RAGGIO + 0.85:
		return

	var dir: Vector3 = d.normalized() if d.length() > 0.01 \
		else -player.global_transform.basis.z

	# **Quanto ci metti dentro.** La componente della tua velocità nella
	# direzione del pallone: se ci cammini contro piano è quasi zero, se ci
	# arrivi di corsa è tre metri e mezzo al secondo.
	var spinta: float = 0.0
	if player is CharacterBody3D:
		var pv: Vector3 = (player as CharacterBody3D).velocity
		spinta = maxf(0.0, Vector3(pv.x, 0, pv.z).dot(dir))
	var al_volo: bool = player.velocity.y > 0.5 or not player.is_on_floor()

	# Da fermo `TOCCO`, di corsa piena `CALCIO`. In mezzo, in mezzo.
	# 3,4 m/s è la camminata svelta del giocatore: a quella velocità il
	# tiro è già pieno.
	var quanto: float = clampf(spinta / 3.4, 0.0, 1.0)
	var forza: float = lerpf(TOCCO, CALCIO, quanto)
	var quota: float = ALZO_QUOTA
	if al_volo:
		forza = CALCIO_AL_VOLO
		quota = ALZO_QUOTA_AL_VOLO

	dir = _mira(dir, forza)
	linear_velocity = dir * forza + Vector3.UP * (forza * quota)
	# Un po' di effetto: gira intorno all'asse verticale secondo da che
	# parte l'hai preso. L'effetto a caso adesso è proporzionale alla
	# forza — se no un tocco da fermo partiva con una rotazione da
	# punizione e il pallone se ne andava per i fatti suoi.
	angular_velocity = Vector3.UP * randf_range(-1.0, 1.0) * quanto * 4.0 \
		+ Vector3.UP.cross(dir) * forza / RAGGIO * 0.35
	_kick_cd = RICARICA_CALCIO
	_tuo = true
	SoundManager.play("bump", -5.0 - (1.0 - quanto) * 7.0,
		1.05 if al_volo else lerpf(1.35, 1.15, quanto))
	GameManager.screen_shake.emit(0.10 if al_volo else 0.06 * quanto)


## **'A mira**: piega il tiro verso la porta, ma solo se ci stavi puntando.
##
## Tre condizioni, e devono valere tutte e tre:
##
## * la porta dev'esserci (fuori dal campetto non si aiuta nessuno);
## * devi essere **a tiro** — sotto i ventiquattro metri;
## * il tiro dev'essere **già indirizzato**, cioè dentro al cono: se calci
##   all'indietro o di lato, resta dove l'hai mandato.
##
## E quanto piega dipende da quanto ci eri vicino: un tiro quasi giusto
## diventa giusto, un tiro storto resta storto. Chi ha mirato bene se ne
## accorge appena; chi ha sbagliato non viene premiato.
static func mira_a(dir: Vector3, forza: float, da: Vector3,
		centro: Vector3) -> Vector3:
	if centro == Vector3.ZERO:
		return dir
	# Un tocco da fermo non si aiuta: stai conducendo, non tirando.
	if forza < TOCCO * 1.35:
		return dir
	var verso_porta: Vector3 = centro - da
	verso_porta.y = 0.0
	var quanto_lontano: float = verso_porta.length()
	if quanto_lontano < 0.5 or quanto_lontano > MIRA_DISTANZA:
		return dir
	verso_porta /= quanto_lontano
	var allineato: float = dir.dot(verso_porta)
	if allineato < MIRA_CONO:
		return dir
	# Da MIRA_CONO (bordo del cono, nessun aiuto) a 1 (perfetto).
	var dentro: float = (allineato - MIRA_CONO) / (1.0 - MIRA_CONO)
	return dir.lerp(verso_porta, MIRA_FORZA * dentro).normalized()


func _mira(dir: Vector3, forza: float) -> Vector3:
	return mira_a(dir, forza, global_position, goal_center)


## **'O gol** — e perché non si contava mai.
##
## Prima era un punto dentro a una scatola: «se in questo fotogramma il
## pallone sta a meno di settanta centimetri dalla linea, è gol». Sembra
## ragionevole e non lo è: il pallone può viaggiare a ventidue metri al
## secondo, cioè **trentasette centimetri per fotogramma**, e il tiro più
## bello della partita — quello forte, quello che entra all'incrocio —
## poteva saltare la scatola in volo e finire dietro alla rete senza che
## nessuno se ne accorgesse. **'O tiro cchiù bello era 'o cchiù facile 'a
## perdere.**
##
## Adesso non si guarda dove sta, si guarda **da dove a dove è passato**:
## se il segmento fra il fotogramma di prima e questo attraversa la bocca
## della porta, è gol — e a qualunque velocità vada. Si entra solo da
## davanti (da z maggiore verso z minore): un pallone che rimbalza sulla
## rete e torna fuori non segna due volte.
var _prima: Vector3 = Vector3.ZERO


## **'A regola d''o gol, sola sola.**
##
## Sta fuori dal corpo rigido apposta: così si può provare senza far girare
## il motore fisico, e una prova che non deve aspettare la fisica è una
## prova che dice sempre la stessa cosa. Vedi `tools/prova_pallone.gd`.
static func gol(prima: Vector3, ora: Vector3, centro: Vector3,
		normale: Vector3, largh: float, alt: float) -> bool:
	# Quanto sta davanti alla linea, prima e adesso. `normale` punta verso
	# dentro la porta, quindi davanti è positivo e dentro è negativo.
	var d_prima: float = -normale.dot(prima - centro)
	var d_ora: float = -normale.dot(ora - centro)
	# Si entra da davanti e basta: un pallone che rimbalza sulla rete e
	# torna fuori non segna una seconda volta.
	if not (d_prima > 0.0 and d_ora <= 0.0):
		return false
	# Dove stava il pallone nell'istante in cui ha tagliato la linea.
	var dd: float = d_prima - d_ora
	var t: float = 0.0 if dd <= 0.00001 else d_prima / dd
	var taglio: Vector3 = prima.lerp(ora, t)
	# Quanto largo rispetto al centro: la traversa è Y, i pali sono la
	# direzione orizzontale perpendicolare alla normale.
	var palo: Vector3 = Vector3(-normale.z, 0.0, normale.x).normalized()
	var scarto: float = absf(palo.dot(taglio - centro))
	# Il raggio del pallone conta: entra anche se ci passa mezzo dentro,
	# come nel calcio vero il pallone è dentro quando ha passato la linea.
	if scarto > largh * 0.5 + RAGGIO:
		return false
	if taglio.y > alt + RAGGIO or taglio.y < -0.5:
		return false
	return true


func _check_goal() -> void:
	# `Vector3.ZERO` vuol dire «nun ce sta porta». Nella pianta di questa
	# città l'origine sta fuori dal mondo giocabile, quindi non è un
	# indirizzo che possa capitare per davvero.
	if goal_center == Vector3.ZERO:
		return
	var ora: Vector3 = global_position
	if _prima == Vector3.ZERO:
		_prima = ora
		return
	var era: Vector3 = _prima
	_prima = ora
	if gol(era, ora, goal_center, goal_normale, goal_width, goal_height):
		_score()


func _score() -> void:
	if not _tuo:
		# Gol dei guaglioni: si sente il grido, ma non paga.
		SoundManager.play("urlo", -12.0, 1.1)
		_torna_a_casa()
		return
	_tuo = false
	var pavato: int = GameManager.register_goal()
	SoundManager.play("success", -2.0, 1.15)
	GameManager.screen_shake.emit(0.35)
	var grido: String = SAY_GOAL[randi() % SAY_GOAL.size()]
	if pavato > 0:
		GameManager.event_started.emit(grido + "  (+€%d)" % pavato)
	else:
		# Il banco ha chiuso per oggi, ma il gol è gol: si grida lo stesso.
		GameManager.event_started.emit(grido
			+ "  (pe' oggi 'e sorde so' fernute)")
	_torna_a_casa()


## I guaglioni calciano da qui: stessa fisica, e il pallone smette di
## essere tuo.
func calcia_guagliuno(dir: Vector3, forza: float) -> void:
	_tuo = false
	_kick_cd = RICARICA_CALCIO
	linear_velocity = dir.normalized() * forza \
		+ Vector3.UP * (forza * ALZO_QUOTA)
	angular_velocity = Vector3.UP * randf_range(-3.0, 3.0)
	SoundManager.play("bump", -16.0, randf_range(1.2, 1.5))


## Se resta fermo lontano, se è finito fuori dal mondo o è caduto sotto al
## suolo, torna al campetto.
func _check_perso(delta: float) -> void:
	var lontano: float = global_position.distance_to(home)
	if global_position.y < -3.0 or lontano > LONTANO_DA_CASA * 2.0:
		_torna_a_casa()
		return
	if linear_velocity.length() > 0.4:
		_lontano_da = 0.0
		return
	if lontano > 3.5:
		_lontano_da += delta
		if _lontano_da > RESET_DOPO:
			_torna_a_casa()
	else:
		_lontano_da = 0.0


func _torna_a_casa() -> void:
	global_position = home
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	_lontano_da = 0.0
	_fermo_da = 0.0
	# Se no il salto dal fondo della rete al dischetto viene letto come un
	# passaggio sulla linea, e il gol si conta due volte.
	_prima = home
