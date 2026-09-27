extends Node3D
## ZonePiazza (storicamente zone_vicolo_3d.gd)
## Costruttore procedurale delle zone. Genera "La Piazza" (zona di partenza)
## e "La Strada Principale" (sbloccabile) usando le texture fotografiche in
## assets/textures: intonaci veri sui palazzi, serrande e portoni al piano
## terra, manifesti strappati, salotto centrale in maioliche, asfalto e
## marciapiedi. Sul lato aperto si vedono il golfo, il Vesuvio e il cielo.

const CarScene := preload("res://scripts/car_3d.gd")
const Models := preload("res://scripts/models.gd")
const ParkingSpotScene := preload("res://scripts/parking_spot_3d.gd")
const VigileScene := preload("res://scripts/vigile_3d.gd")
const ShopScene := preload("res://scripts/shop_3d.gd")
const CatScene := preload("res://scripts/cat_3d.gd")
const MotorinoScene := preload("res://scripts/motorino_3d.gd")
const TabaccheriaScene := preload("res://scripts/tabaccheria_3d.gd")
const BarScene := preload("res://scripts/bar_piazza_3d.gd")
const BazarScene := preload("res://scripts/bazar_3d.gd")
const BorrelliScene := preload("res://scripts/borrelli_3d.gd")
const SignoraScene := preload("res://scripts/signora_3d.gd")
const PalloneScene := preload("res://scripts/pallone_3d.gd")
const CarabinieriScene := preload("res://scripts/carabinieri_3d.gd")
const Tex := preload("res://scripts/textures.gd")
const CicloScript := preload("res://scripts/giorno_notte.gd")
const UsoDecoro := preload("res://scripts/decoro_utile.gd")

const LAYER_WORLD := 1

const CLOTH_COLORS := [
	Color(0.9, 0.9, 0.95), Color(0.85, 0.4, 0.4), Color(0.4, 0.6, 0.85),
	Color(0.95, 0.85, 0.5), Color(0.5, 0.75, 0.5),
]

# Configurazione zona (vedi GameManager.ZONES)
var zone_display_name := "La Piazza"
var width := 34.0
var length := 54.0
var spots_right := 5
var spots_left := 4
var max_cars := 4
var _ciclo: Node = null
## Quanto manca all'arrivo del boss da quando e' calata la notte.
var _boss_fra: float = -1.0
var spawn_min := 7.0
var spawn_max := 13.0
var vigili_count := 1

var entry_point: Vector3
var exit_point: Vector3
var queue_points: Array = []
var parking_spots: Array = []
var player_start: Vector3
var player_start_rotation_y := 0.0

var _spawn_timer: Timer
var _cat_timer: Timer
var _signora_timer: Timer
var _motorino_timer: Timer
var _wave_timer: Timer
var _queue_cursor: int = 0
var _wave_fired: bool = false
var _wave_pending: int = 0
var _wave_next: float = 0.0
var _decor_anchor: Vector3
## Quando è valorizzato, le decorazioni si appendono qui invece che alla
## zona: serve a poterle spostare e rimuovere in blocco.
var _decor_holder: Node3D = null
var _gulls_root: Node3D = null
# Raccoglitori per il batching: invece di creare centinaia di nodi separati
# (una finestra, una persiana, una bandierina ciascuno) accumuliamo qui le
# posizioni e a fine costruzione creiamo pochi MultiMesh. Stessa resa a
# schermo, una frazione delle draw call — determinante nel browser.
var _batch_windows: Array = []
var _batch_frames: Array = []       # cornice in pietra attorno alle finestre
# **La finestra come buco, non come adesivo.**
#
# La versione vecchia era due piastre: il vetro davanti e una lastra di
# pietra dietro, che sporgeva di dodici centimetri tutt'intorno. Da lontano
# funzionava; da vicino era un rettangolo nero con un bordo chiaro, cioe'
# un adesivo. Adesso ci sono anche il vano scuro dietro al vetro (lo
# spessore del muro) e la mazzetta fatta di quattro listelli invece che di
# una lastra sola — perche' una lastra piena coprirebbe il vetro che sta
# dietro. In piu' la crociera, che e' il pezzo che fa dire "finestra" prima
# ancora di guardarla.
var _batch_reveals: Array = []      # il vano scuro dentro al muro
var _batch_bars_h: Array = []       # listelli orizzontali della mazzetta
var _batch_bars_v: Array = []       # listelli verticali
var _batch_cross_h: Array = []      # traversa del vetro
var _batch_cross_v: Array = []      # montante del vetro
var _batch_back_reveals: Array = []
var _batch_back_bars_h: Array = []
var _batch_back_bars_v: Array = []
var _batch_back_cross_h: Array = []
var _batch_back_cross_v: Array = []
var _batch_sills: Array = []        # davanzali
var _batch_back_windows: Array = [] # palazzi di fondo: vetro girato su Z
var _batch_back_frames: Array = []
var _batch_back_sills: Array = []
var _batch_shutters: Array = []
var _batch_flags_a: Array = []
var _batch_flags_b: Array = []
var _batch_cloths: Array = []
var _batch_cloth_colors: Array = []
var _gull_time: float = 0.0
var _gull_wings: Array = []


func configure(cfg: Dictionary) -> void:
	zone_display_name = cfg.get("name", zone_display_name)
	width = cfg.get("width", width)
	length = cfg.get("length", length)
	spots_right = cfg.get("spots_right", spots_right)
	spots_left = cfg.get("spots_left", spots_left)
	max_cars = cfg.get("max_cars", max_cars)
	spawn_min = cfg.get("spawn_min", spawn_min)
	spawn_max = cfg.get("spawn_max", spawn_max)
	vigili_count = cfg.get("vigili", vigili_count)


## Quando la piazza sta dentro alla citta' non e' piu' il mondo intero: e'
## un quartiere fra gli altri. Luce, panorama e muri di confine passano
## alla citta', altrimenti ce ne sarebbero cinque copie sovrapposte e non
## si potrebbe uscire dalla piazza per andare in giro.
var dentro_citta: bool = false


func _ready() -> void:
	entry_point = Vector3(width * 0.3, 0.0, length - 2.0)
	exit_point = entry_point
	player_start = Vector3(width * 0.5, 0.0, length * 0.42)
	GameManager.chiama_borrelli.connect(_borrelli_subito)
	GameManager.servizio_cambiato.connect(_su_servizio)

	if not dentro_citta:
		_build_lighting()
		_build_bounds()
	_build_ground()
	_build_buildings()
	if not dentro_citta:
		_build_panorama()
	_build_props()
	_build_parking_spots()
	_build_queue_points()
	_build_vigili()
	_build_spawner()
	_build_events()
	_flush_batches()


func get_player_start() -> Vector3:
	return player_start


## Da coordinate della piazza a coordinate del mondo.
##
## La piazza e' nata come mondo intero, con l'origine in un angolo: tutti i
## suoi punti notevoli — varco d'ingresso, coda, ronda del vigile — sono in
## quel sistema. Da quando sta dentro alla citta' e' spostata di (14, 6),
## ma chi nasce qui dentro si piazza con `global_position`, e passargli un
## punto locale voleva dire farlo comparire quattordici metri piu' a ovest e
## sei piu' a nord: cioe' FUORI dalla piazza, dentro agli isolati. Le auto
## arrivavano rasente al muro esterno di ponente e lo attraversavano, il
## vigile pattugliava un vicolo, e Borrelli usciva da dentro a un palazzo.
##
## Ogni volta che un punto di questa classe finisce in un `global_position`,
## deve passare da qui.
func _glob(p: Vector3) -> Vector3:
	return global_transform * p


## Il percorso con cui le auto entrano in piazza, in coordinate del mondo.
##
## Non nascono piu' sul varco: nascono in mezzo alla strada di sotto, a una
## quindicina di metri, e ci arrivano girando. Cosi' si vedono arrivare — che
## e' il punto — e non compaiono dal niente incastrate nel muro.
func percorso_ingresso() -> Array:
	if not dentro_citta:
		return [_glob(entry_point)]
	var varco: Vector3 = _glob(Vector3(entry_point.x, 0.0, length + 0.5))
	return [
		Vector3(varco.x + 17.0, 0.0, varco.z + 3.6),   # in mezzo alla strada
		Vector3(varco.x, 0.0, varco.z + 4.4),          # in asse col varco
		Vector3(varco.x, 0.0, varco.z - 3.0),          # dentro
	]


## Il percorso d'uscita: fuori dal varco e poi via dall'altra parte, cosi'
## chi esce non incrocia chi entra.
func percorso_uscita() -> Array:
	if not dentro_citta:
		return [_glob(exit_point)]
	var varco: Vector3 = _glob(Vector3(entry_point.x, 0.0, length + 0.5))
	return [
		Vector3(varco.x, 0.0, varco.z - 3.0),
		Vector3(varco.x, 0.0, varco.z + 4.4),
		Vector3(varco.x - 22.0, 0.0, varco.z + 3.6),
	]


# ---------------------------------------------------------------------------
# Luce e cielo
# ---------------------------------------------------------------------------

func _build_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -128, 0)
	# Energia contenuta: col cielo chiaro che fa già da luce ambientale,
	# più di così e i muri chiari si bruciano in bianco.
	sun.light_energy = 1.0
	sun.light_color = Color(1.0, 0.94, 0.82)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 75.0
	sun.shadow_blur = 1.4 # bordi meno duri, luce di fine giornata
	sun.shadow_bias = 0.04
	sun.light_specular = 0.4
	if _is_forward_plus():
		# Ombre a quattro fette invece di una: da vicino i bordi sono netti
		# e in fondo alla piazza non sfarfallano.
		sun.directional_shadow_mode = \
			DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		sun.directional_shadow_split_1 = 0.06
		sun.directional_shadow_split_2 = 0.16
		sun.directional_shadow_split_3 = 0.42
		sun.directional_shadow_blend_splits = true
		sun.directional_shadow_max_distance = 110.0
		# Il sole è largo mezzo grado: l'ombra si sfoca allontanandosi da
		# quello che la proietta, come nella realtà.
		sun.light_angular_distance = 0.6
		sun.shadow_blur = 1.0
		sun.light_specular = 0.7
	add_child(sun)

	# Luce di rimbalzo dal basso: senza, i sottotetti e i lati in ombra
	# diventano neri e piatti.
	var bounce := DirectionalLight3D.new()
	bounce.rotation_degrees = Vector3(38, 52, 0)
	bounce.light_energy = 0.28
	bounce.light_color = Color(0.72, 0.78, 0.9)
	bounce.shadow_enabled = false
	add_child(bounce)

	var env := WorldEnvironment.new()
	var environment := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.18, 0.42, 0.78)
	sky_mat.sky_horizon_color = Color(0.78, 0.82, 0.85)
	sky_mat.sky_curve = 0.12
	sky_mat.ground_bottom_color = Color(0.32, 0.3, 0.28)
	sky_mat.ground_horizon_color = Color(0.72, 0.72, 0.7)
	# Il sole disegnato nel cielo, coerente con la DirectionalLight
	sky_mat.sun_angle_max = 12.0
	sky_mat.sun_curve = 0.08
	sky.sky_material = sky_mat
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	# Ambientale bassa: prima sommava alla luce del sole e la piazza
	# risultava slavata, tutta bianca e senza contrasto.
	environment.ambient_light_energy = 0.45
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_white = 2.4 # più margine prima del bianco pieno
	environment.tonemap_exposure = 0.92
	environment.glow_enabled = true
	environment.glow_intensity = 0.22
	environment.glow_bloom = 0.02
	environment.glow_hdr_threshold = 1.1 # brilla solo quello che brilla davvero
	environment.fog_enabled = true
	# Foschia calda da giornata di scirocco, non grigio piombo.
	environment.fog_light_color = Color(0.88, 0.85, 0.76)
	environment.fog_light_energy = 0.9
	environment.fog_density = 0.0009
	environment.fog_sky_affect = 0.0
	environment.fog_aerial_perspective = 0.14
	# Da qui in giù: roba che esiste solo su Forward+ (Vulkan). Nel browser
	# gira GL Compatibility, dove SSAO e SSIL non esistono proprio e le
	# ombre morbide costano troppo — quindi si accendono a runtime, guardando
	# se c'è un RenderingDevice, invece che a colpi di #ifdef.
	if _is_forward_plus():
		# Occlusione ambientale: è quello che dà peso alle cose. Senza, le
		# auto sembrano adesivi appoggiati sull'asfalto e i sottoportici
		# non hanno profondità.
		environment.ssao_enabled = true
		environment.ssao_radius = 1.6
		environment.ssao_intensity = 2.4
		environment.ssao_power = 1.6
		environment.ssao_detail = 0.6
		environment.ssao_light_affect = 0.25
		environment.ssao_ao_channel_affect = 0.35
		# Luce indiretta a schermo: il muro giallo tinge di giallo l'asfalto
		# che ha davanti. È la cosa che più fa sembrare "vero" un vicolo.
		environment.ssil_enabled = true
		environment.ssil_radius = 3.2
		environment.ssil_intensity = 0.85
		environment.ssil_sharpness = 0.9
		environment.ssil_normal_rejection = 1.0
		# Riflessi a schermo: pozzanghere, cofani lucidi, vetrine.
		environment.ssr_enabled = true
		environment.ssr_max_steps = 32
		environment.ssr_fade_in = 0.2
		environment.ssr_fade_out = 2.4
		# Nebbia volumetrica: i raggi di sole fra i palazzi e nei vicoli.
		environment.volumetric_fog_enabled = true
		environment.volumetric_fog_density = 0.014
		environment.volumetric_fog_albedo = Color(0.92, 0.88, 0.8)
		environment.volumetric_fog_emission = Color(0.06, 0.05, 0.04)
		environment.volumetric_fog_length = 60.0
		environment.volumetric_fog_gi_inject = 0.6
		environment.glow_intensity = 0.3
	else:
		environment.ssao_enabled = false # non esiste in GL compatibility
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.08
	environment.adjustment_contrast = 1.05
	env.environment = environment
	add_child(env)

	# Il ciclo del giorno: da qui in poi sole, cielo, foschia e lampioni
	# non sono piu' costanti, li muove lui.
	_ciclo = CicloScript.new()
	_ciclo.name = "GiornoNotte"
	add_child(_ciclo)
	_ciclo.setup(sun, bounce, environment, sky_mat)
	_ciclo.notte_calata.connect(_on_notte_calata)

	# Il regolatore automatico: misura i fotogrammi nei primi secondi e
	# spegne gli effetti che il computer non regge.
	var q: Node = load("res://scripts/qualita.gd").new()
	q.name = "Qualita"
	add_child(q)
	q.setup(environment, sun)

	_build_clouds()
	_build_dust()


## Nuvole: cumuli fatti di gruppi di sfere schiacciate, piazzati molto in
## alto e MOLTO lontano, oltre i palazzi. Prima erano pannelli piatti
## billboard e a guardarli da vicino sembravano rettangoli bianchi che
## volavano: adesso sono volumi veri, sempre alla stessa distanza, e si
## leggono come nuvole.
func _build_clouds() -> void:
	var root := Node3D.new()
	root.name = "Nuvole"
	add_child(root)

	var rng := RandomNumberGenerator.new()
	rng.seed = 20250823

	var cloud_mat := StandardMaterial3D.new()
	cloud_mat.albedo_color = Color(1.0, 0.99, 0.97)
	cloud_mat.roughness = 1.0
	cloud_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	# Poco influenzate dalla luce diretta: le nuvole sono corpi diffusi
	cloud_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	var puff_mesh := SphereMesh.new()
	puff_mesh.radius = 1.0
	puff_mesh.height = 2.0
	# Abbastanza segmenti da non leggersi come poligoni: erano queste
	# sfere spigolose, viste isolate, i "cubi bianchi volanti".
	puff_mesh.radial_segments = 20
	puff_mesh.rings = 10

	var center := Vector3(width / 2.0, 0.0, length / 2.0)
	for i in range(10):
		var angle: float = rng.randf_range(0.0, TAU)
		# Molto lontane e molto in alto: da dentro la piazza si vedono
		# solo sopra i tetti, mai all'altezza dei palazzi.
		var dist: float = rng.randf_range(320.0, 520.0)
		var base := center + Vector3(cos(angle) * dist,
			rng.randf_range(150.0, 240.0), sin(angle) * dist)
		var scale_base: float = rng.randf_range(22.0, 40.0)

		# Il cumulo si costruisce attorno a un nucleo grosso: ogni bolla
		# successiva è piazzata abbastanza vicino da compenetrare sempre il
		# nucleo. Così non restano mai palle staccate a mezz'aria.
		var lobes := rng.randi_range(6, 9)
		for j in range(lobes):
			var lobe := MeshInstance3D.new()
			lobe.mesh = puff_mesh
			lobe.material_override = cloud_mat
			var r: float = scale_base
			var off := Vector3.ZERO
			if j > 0:
				r = scale_base * rng.randf_range(0.62, 0.95)
				# Distanza massima = raggio nucleo + raggio bolla - 30%
				# di sovrapposizione garantita.
				var reach: float = (scale_base + r) * 0.66
				off = Vector3(
					rng.randf_range(-reach, reach),
					rng.randf_range(-0.12, 0.22) * scale_base,
					rng.randf_range(-reach, reach) * 0.5)
			lobe.position = base + off
			# Schiacciate: le nuvole belle sono larghe, non sferiche
			lobe.scale = Vector3(r, r * rng.randf_range(0.52, 0.68), r * 0.85)
			root.add_child(lobe)


## Pulviscolo sospeso nell'aria: quando ci passa dentro un raggio di sole
## la piazza smette di sembrare vuota.
func _build_dust() -> void:
	var dust := CPUParticles3D.new()
	dust.amount = 45
	dust.lifetime = 18.0
	dust.preprocess = 7.0
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	# Il pulviscolo vola SOPRA la testa (dai 5 metri in su). Prima nasceva
	# anche all'altezza degli occhi e un granello a venti centimetri dalla
	# faccia si vedeva come un poligono bianco che svolazzava: erano quelli
	# i "cubi bianchi volanti".
	dust.emission_box_extents = Vector3(width * 0.5, 2.5, length * 0.5)
	dust.direction = Vector3(0.4, 1, 0.2)
	dust.spread = 40.0
	dust.initial_velocity_min = 0.06
	dust.initial_velocity_max = 0.22
	dust.gravity = Vector3(0.05, 0.02, 0)
	dust.scale_amount_min = 0.012
	dust.scale_amount_max = 0.03
	# Quadrato con dentro una macchiolina sfumata: anche ingrandito resta
	# un alone morbido, non un poligono con gli spigoli.
	var grain := QuadMesh.new()
	grain.size = Vector2(1.0, 1.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.94, 0.78, 0.30)
	mat.albedo_texture = _soft_dot_texture()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	grain.material = mat
	dust.mesh = grain
	dust.position = Vector3(width / 2.0, 7.5, length / 2.0)
	add_child(dust)
	dust.emitting = true


## Puntino bianco con i bordi sfumati, generato a mano: serve al pulviscolo
## per non avere contorni netti.
func _soft_dot_texture() -> ImageTexture:
	var size := 32
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := (size - 1) / 2.0
	for y in size:
		for x in size:
			var d: float = Vector2(x - c, y - c).length() / c
			var a: float = clampf(1.0 - d, 0.0, 1.0)
			a = a * a * a # caduta morbida verso il bordo
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


# ---------------------------------------------------------------------------
# Pavimentazione
# ---------------------------------------------------------------------------

## Muro invisibile tutto intorno alla piazza. I palazzi chiudono i lati
## lunghi ma lasciano dei varchi (l'imbocco delle auto, gli angoli, il lato
## di fondo aperto sul golfo): da lì si usciva e si cadeva nel vuoto.
##
## Va insieme al paracadute in player_fps.gd: se per qualche motivo si
## finisce comunque fuori o sotto, il giocatore viene rimesso in piazza.
func _build_bounds() -> void:
	const MARGIN := 1.0    # quanto stanno fuori dal bordo utile
	const HEIGHT := 24.0   # alti: non si scavalcano nemmeno saltando su un'auto
	const THICK := 2.0
	var cx: float = width / 2.0
	var cz: float = length / 2.0
	var walls := [
		# centro,                                    dimensioni
		[Vector3(-MARGIN - THICK / 2.0, HEIGHT / 2.0, cz), Vector3(THICK, HEIGHT, length + MARGIN * 4.0)],
		[Vector3(width + MARGIN + THICK / 2.0, HEIGHT / 2.0, cz), Vector3(THICK, HEIGHT, length + MARGIN * 4.0)],
		[Vector3(cx, HEIGHT / 2.0, -MARGIN - THICK / 2.0), Vector3(width + MARGIN * 4.0, HEIGHT, THICK)],
		[Vector3(cx, HEIGHT / 2.0, length + MARGIN + THICK / 2.0), Vector3(width + MARGIN * 4.0, HEIGHT, THICK)],
	]
	for w in walls:
		var body := StaticBody3D.new()
		body.collision_layer = LAYER_WORLD
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = w[1]
		shape.shape = box
		shape.position = w[0]
		body.add_child(shape)
		add_child(body)

	# Pavimento di riserva molto più largo del piazzale: se si scivola in un
	# angolo fra un collider e l'altro non si precipita comunque.
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = LAYER_WORLD
	floor_body.collision_mask = 0
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(width + 40.0, 1.0, length + 40.0)
	floor_shape.shape = floor_box
	floor_shape.position = Vector3(cx, -0.6, cz)
	floor_body.add_child(floor_shape)
	add_child(floor_body)


func _build_ground() -> void:
	# Asfalto su tutta la piazza
	var asphalt := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(width, length)
	asphalt.mesh = plane
	asphalt.position = Vector3(width / 2.0, 0.0, length / 2.0)
	asphalt.material_override = Tex.ground("asfalto", Vector2(width, length), 6.0)
	add_child(asphalt)

	# Il collider del selciato serve solo quando la piazza È il mondo. Dentro
	# alla città il terreno lo mette la città, e questo lastrone diventa un
	# doppione dannoso: è alto venti centimetri e finisce esattamente al
	# bordo della piazza, quindi i suoi fianchi sono quattro gradini
	# invisibili. Un'auto che entra dal varco ha il fondo della propria
	# scatola a quota zero, cioè esattamente sul filo del gradino: ci
	# sbatteva contro, si fermava e dopo dieci secondi si arrendeva. È il
	# motivo per cui metà dei clienti non entrava mai in piazza.
	if not dentro_citta:
		var body := StaticBody3D.new()
		body.collision_layer = LAYER_WORLD
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(width, 0.2, length)
		shape.shape = box
		shape.position = Vector3(width / 2.0, -0.1, length / 2.0)
		body.add_child(shape)
		add_child(body)

	# Marciapiedi lungo i quattro lati
	var walk_mat := Tex.mondo("marciapiede", Tex.TERRA, 0.9)
	_make_walkway(Vector3(1.6, 0.06, length / 2.0), Vector3(3.2, 0.12, length), walk_mat)
	_make_walkway(Vector3(width - 1.6, 0.06, length / 2.0), Vector3(3.2, 0.12, length), walk_mat)
	_make_walkway(Vector3(width / 2.0, 0.06, 1.6), Vector3(width - 6.4, 0.12, 3.2), walk_mat)

	# **'O salotto d''a piazza: piperno, no maioliche.**
	#
	# Qui c'era un tappeto di maioliche largo un terzo della piazza, e il
	# capo ha ragione: non ha senso. Le maioliche a Napoli stanno sui
	# chiostri, sulle cupole, sull'alzata di uno scalino, sul banco di un
	# bar — in posti piccoli, riparati e voluti. In mezzo a una piazza dove
	# passano le macchine non ce le metterebbe nessuno: si spaccano in una
	# settimana. E infatti il pavimento sembrava una tovaglia.
	#
	# Il salotto di una piazza napoletana è **lastricato di piperno**: la
	# pietra grigia scura di Napoli, tagliata in lastre grandi, messa dentro
	# al basolato che fa il resto della strada. Si legge come "qui non ci
	# passano le macchine" senza bisogno di nessun colore.
	var sq_w := width * 0.34
	var sq_l := length * 0.24
	var center := Vector3(width / 2.0, 0.0, length * 0.45)
	_make_walkway(center + Vector3(0, 0.06, 0), Vector3(sq_w + 1.0, 0.12, sq_l + 1.0), walk_mat)

	var lastrico := MeshInstance3D.new()
	var lastra := PlaneMesh.new()
	lastra.size = Vector2(sq_w, sq_l)
	lastrico.mesh = lastra
	lastrico.position = center + Vector3(0, 0.125, 0)
	lastrico.material_override = Tex.mondo("piperno",
		Color(0.80, 0.78, 0.76), 0.90)
	add_child(lastrico)

	# Il filo di basolato che gira attorno al lastricato: è il bordo che in
	# una piazza vera segna dove finisce il salotto e comincia la strada.
	for lato in range(4):
		var lungo: bool = lato < 2
		var l: float = (sq_w + 1.6) if lungo else (sq_l + 1.6)
		var off: float = ((sq_l + 1.6) * 0.5) if lungo else ((sq_w + 1.6) * 0.5)
		var segno: float = 1.0 if lato % 2 == 0 else -1.0
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(l, 0.14, 0.55) if lungo else Vector3(0.55, 0.14, l)
		b.mesh = bm
		b.position = center + Vector3(0, 0.13, 0) + (
			Vector3(0, 0, off * segno) if lungo else Vector3(off * segno, 0, 0))
		b.material_override = Tex.mondo("basolato", Color(0.72, 0.68, 0.62), 0.9)
		add_child(b)

	_decor_anchor = center + Vector3(sq_w * 0.5 + 1.8, 0.0, 0)


func _make_walkway(pos: Vector3, size: Vector3, mat: Material) -> void:
	var walk := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	walk.mesh = mesh
	walk.position = pos
	walk.material_override = mat
	add_child(walk)


# ---------------------------------------------------------------------------
# Palazzi
# ---------------------------------------------------------------------------

func _build_buildings() -> void:
	var seg := 9.0
	var n_side := int(length / seg)
	# Lati lunghi: palazzi alti che chiudono la piazza
	for i in range(n_side):
		var z0: float = i * seg
		var zc: float = z0 + seg / 2.0
		_make_building(Vector3(0.0, 0.0, zc), seg, true, i)
		_make_building(Vector3(width, 0.0, zc), seg, false, i + 2)

	# Lato di fondo (z=0): al centro si apre sul golfo.
	#
	# La descrizione della zona diceva da sempre "sul lato aperto si vedono
	# il golfo e il Vesuvio", ma la geometria non lo faceva: c'era una fila
	# continua di palazzi da sette metri e la montagna restava dietro, che
	# nessuno l'ha mai vista.
	#
	# L'apertura si calcola in metri, non a segmenti: con tre segmenti da
	# nove metri l'indice "centrale" cadeva a sinistra, e il Vesuvio — che
	# sta sulla destra — finiva esattamente dietro all'unico pezzo di muro
	# rimasto.
	# In citta' il lato di fondo e' il varco verso la strada: piu' largo,
	# perche' ci si deve passare a piedi e in macchina.
	var belv_da: float = width * (0.22 if dentro_citta else 0.30)
	var belv_a: float = width * (0.82 if dentro_citta else 0.74)
	if belv_da > 0.5:
		_make_back_building(Vector3(belv_da / 2.0, 0.0, 0.0), belv_da, 1)
	_make_belvedere(Vector3((belv_da + belv_a) / 2.0, 0.0, 0.0), belv_a - belv_da)
	if width - belv_a > 0.5:
		_make_back_building(Vector3((belv_a + width) / 2.0, 0.0, 0.0),
			width - belv_a, 2)

	# Lato d'ingresso (z=length): muro con il varco per le auto
	# Il varco è largo nove metri e non sette: un'auto che entra deve fare
	# una curva stretta arrivando dalla strada, e con sette metri strisciava
	# sullo spigolo del palazzo di destra.
	var gap_lo: float = entry_point.x - 4.5
	var gap_hi: float = entry_point.x + 4.5
	if gap_lo > 1.0:
		_make_back_building(Vector3(gap_lo / 2.0, 0.0, length), gap_lo, 3)
	_make_back_building(Vector3((gap_hi + width) / 2.0, 0.0, length), width - gap_hi, 0)


## Un palazzo su un lato lungo: intonaco vero, piano terra commerciale
## (serranda o portone), finestre, balconi.
func _make_building(base: Vector3, seg_len: float, is_left: bool, style: int) -> void:
	var height: float = [11.0, 13.5, 12.0, 14.5, 10.5][style % 5]
	var depth := 1.2
	var inward: float = 1.0 if is_left else -1.0
	var face_x: float = base.x + inward * depth * 0.5

	# Corpo del palazzo
	var wall := MeshInstance3D.new()
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(depth, height, seg_len)
	wall.mesh = wall_mesh
	wall.position = Vector3(base.x, height / 2.0, base.z)
	wall.material_override = Tex.facade(style, seg_len)
	add_child(wall)

	# Collider: chiude la piazza
	_make_wall_collider(Vector3(base.x, height / 2.0, base.z), Vector3(depth, height, seg_len))

	# Cornicione
	var cornice := MeshInstance3D.new()
	var cornice_mesh := BoxMesh.new()
	cornice_mesh.size = Vector3(depth + 0.35, 0.35, seg_len)
	cornice.mesh = cornice_mesh
	cornice.position = Vector3(base.x, height - 0.2, base.z)
	var cornice_mat := Tex.flat(Color(0.82, 0.79, 0.72))
	cornice.material_override = cornice_mat
	add_child(cornice)

	# Piano terra: alterna vetrina con serranda, portone e muro coi manifesti
	var kind: int = style % 3
	var front_x: float = face_x + inward * 0.02
	match kind:
		0:
			_make_shopfront(Vector3(front_x, 0.0, base.z), seg_len * 0.62, is_left)
		1:
			_make_portone(Vector3(front_x, 0.0, base.z), is_left)
			_make_posters(Vector3(front_x, 0.0, base.z + seg_len * 0.3), seg_len * 0.3, is_left)
		2:
			_make_posters(Vector3(front_x, 0.0, base.z), seg_len * 0.55, is_left)
			_make_portone(Vector3(front_x, 0.0, base.z + seg_len * 0.33), is_left)

	_build_roof_stuff(Vector3(base.x + inward * 0.2, height, base.z), seg_len, is_left)
	_build_downpipe(Vector3(face_x + inward * 0.05, 0.0, base.z + seg_len * 0.45), height, is_left)

	# Finestre e balconi ai piani superiori
	var floors := int((height - 4.0) / 3.2)
	for f in range(floors):
		var y: float = 4.6 + f * 3.2
		for dz in [-seg_len * 0.28, 0.0, seg_len * 0.28]:
			_make_window(Vector3(front_x, y, base.z + dz), is_left)
		if f == 0 or (f == 2 and style % 2 == 0):
			_make_balcony(Vector3(face_x + inward * 0.55, y - 0.75, base.z), is_left)


## Palazzo del fondo (asse X), più basso: lascia entrare il cielo.
## Il parapetto del belvedere: un muretto all'altezza della vita con sopra
## la ringhiera. Da qui si guarda il golfo — ed e' l'unico punto della
## piazza da cui il Vesuvio si vede tutto.
func _make_belvedere(base: Vector3, seg_len: float) -> void:
	if dentro_citta:
		return # e' un varco: non ci va nessun parapetto davanti
	var muretto := MeshInstance3D.new()
	var mm := BoxMesh.new()
	mm.size = Vector3(seg_len, 1.05, 0.85)
	muretto.mesh = mm
	muretto.position = Vector3(base.x, 0.52, base.z)
	muretto.material_override = Tex.mondo("marciapiede", Tex.TERRA, 0.9)
	add_child(muretto)

	var cimasa := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(seg_len, 0.12, 1.05)
	cimasa.mesh = cm
	cimasa.position = Vector3(base.x, 1.1, base.z)
	cimasa.material_override = Tex.flat(Color(0.62, 0.6, 0.56), 0.85)
	add_child(cimasa)

	# Ringhiera: montanti e corrimano, in ferro scuro.
	var ferro := Tex.flat(Color(0.14, 0.14, 0.16), 0.55, 0.6)
	var corri := MeshInstance3D.new()
	var rm := BoxMesh.new()
	rm.size = Vector3(seg_len, 0.07, 0.07)
	corri.mesh = rm
	corri.position = Vector3(base.x, 1.92, base.z)
	corri.material_override = ferro
	add_child(corri)
	var n := int(seg_len / 0.55)
	for i in range(n + 1):
		var x: float = base.x - seg_len / 2.0 + i * (seg_len / float(maxi(n, 1)))
		var palo := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.05, 0.82, 0.05)
		palo.mesh = pm
		palo.position = Vector3(x, 1.5, base.z)
		palo.material_override = ferro
		add_child(palo)


func _make_back_building(base: Vector3, seg_len: float, style: int) -> void:
	if seg_len <= 0.5:
		return
	var height: float = [7.5, 8.5, 6.8, 9.0][style % 4]
	var depth := 1.2

	var wall := MeshInstance3D.new()
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(seg_len, height, depth)
	wall.mesh = wall_mesh
	wall.position = Vector3(base.x, height / 2.0, base.z)
	wall.material_override = Tex.facade(style + 1, seg_len)
	add_child(wall)

	_make_wall_collider(Vector3(base.x, height / 2.0, base.z), Vector3(seg_len, height, depth))

	var cornice := MeshInstance3D.new()
	var cornice_mesh := BoxMesh.new()
	cornice_mesh.size = Vector3(seg_len, 0.3, depth + 0.3)
	cornice.mesh = cornice_mesh
	cornice.position = Vector3(base.x, height - 0.18, base.z)
	var cornice_mat := Tex.flat(Color(0.82, 0.79, 0.72))
	cornice.material_override = cornice_mat
	add_child(cornice)

	# Finestre rivolte verso la piazza
	var inward_z: float = 1.0 if base.z < length / 2.0 else -1.0
	var win_z: float = base.z + inward_z * (depth * 0.5 + 0.03)
	var floors := int((height - 3.0) / 3.0)
	for f in range(floors):
		var y: float = 3.4 + f * 3.0
		for dx in [-seg_len * 0.26, 0.0, seg_len * 0.26]:
			_make_back_window(Vector3(base.x + dx, y, win_z), inward_z)


## Roba sui tetti: antenne, parabole, comignoli, condizionatori, panni.
## Sono le cose che rendono uno skyline riconoscibile — e si vedono da tutta
## la piazza, quindi rendono parecchio.
func _build_roof_stuff(top: Vector3, seg_len: float, is_left: bool) -> void:
	var metal := Tex.flat(Color(0.62, 0.63, 0.65), 0.5, 0.6)
	var white := Tex.flat(Color(0.88, 0.88, 0.85), 0.7)
	var brick := Tex.flat(Color(0.55, 0.4, 0.34), 0.95)
	var inward: float = 1.0 if is_left else -1.0

	# Comignolo
	var chimney := MeshInstance3D.new()
	var ch_mesh := BoxMesh.new()
	ch_mesh.size = Vector3(0.5, 0.9, 0.5)
	chimney.mesh = ch_mesh
	chimney.position = top + Vector3(0, 0.45, -seg_len * 0.3)
	chimney.material_override = brick
	add_child(chimney)

	var cap := MeshInstance3D.new()
	var cap_mesh := BoxMesh.new()
	cap_mesh.size = Vector3(0.62, 0.08, 0.62)
	cap.mesh = cap_mesh
	cap.position = top + Vector3(0, 0.94, -seg_len * 0.3)
	cap.material_override = metal
	add_child(cap)

	# Antenna TV a stilo con i bracci
	var mast := MeshInstance3D.new()
	var mast_mesh := CylinderMesh.new()
	mast_mesh.top_radius = 0.02
	mast_mesh.bottom_radius = 0.03
	mast_mesh.height = 1.8
	mast.mesh = mast_mesh
	mast.position = top + Vector3(0, 0.9, seg_len * 0.15)
	mast.material_override = metal
	add_child(mast)
	for i in range(4):
		var arm := MeshInstance3D.new()
		var arm_mesh := BoxMesh.new()
		arm_mesh.size = Vector3(0.02, 0.02, 0.5 - i * 0.07)
		arm.mesh = arm_mesh
		arm.position = top + Vector3(0, 1.0 + i * 0.22, seg_len * 0.15)
		arm.material_override = metal
		add_child(arm)

	# Parabola satellitare
	var dish := MeshInstance3D.new()
	var dish_mesh := SphereMesh.new()
	dish_mesh.radius = 0.32
	dish_mesh.height = 0.3
	dish_mesh.is_hemisphere = true
	dish.mesh = dish_mesh
	dish.position = top + Vector3(inward * 0.3, 0.3, seg_len * 0.34)
	dish.rotation = Vector3(deg_to_rad(-55), deg_to_rad(inward * 30.0), 0)
	dish.material_override = white
	add_child(dish)

	# Condizionatore appeso in facciata
	var ac := MeshInstance3D.new()
	var ac_mesh := BoxMesh.new()
	ac_mesh.size = Vector3(0.4, 0.5, 0.7)
	ac.mesh = ac_mesh
	ac.position = Vector3(top.x + inward * 0.75, top.y - 3.2, top.z + seg_len * 0.28)
	ac.material_override = white
	add_child(ac)


## Pluviale che scende lungo la facciata: dettaglio piccolo, effetto grande.
func _build_downpipe(pos: Vector3, height: float, is_left: bool) -> void:
	var inward: float = 1.0 if is_left else -1.0
	var pipe_mat := Tex.flat(Color(0.45, 0.42, 0.38), 0.85)
	var pipe := MeshInstance3D.new()
	var pipe_mesh := CylinderMesh.new()
	pipe_mesh.top_radius = 0.08
	pipe_mesh.bottom_radius = 0.08
	pipe_mesh.height = height - 0.4
	pipe.mesh = pipe_mesh
	pipe.position = Vector3(pos.x + inward * 0.12, (height - 0.4) / 2.0, pos.z)
	pipe.material_override = pipe_mat
	add_child(pipe)

	# Collari di fissaggio
	for i in range(3):
		var collar := MeshInstance3D.new()
		var collar_mesh := BoxMesh.new()
		collar_mesh.size = Vector3(0.16, 0.05, 0.2)
		collar.mesh = collar_mesh
		collar.position = Vector3(pos.x + inward * 0.08, 2.0 + i * (height / 3.5), pos.z)
		collar.material_override = pipe_mat
		add_child(collar)


## Segnaletica: il cartello di divieto di sosta è irresistibile, in un gioco
## dove fai il parcheggiatore abusivo.
func _make_road_sign(pos: Vector3, kind: String) -> void:
	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.04
	pole_mesh.bottom_radius = 0.05
	pole_mesh.height = 2.4
	pole.mesh = pole_mesh
	pole.position = pos + Vector3(0, 1.2, 0)
	pole.material_override = Tex.flat(Color(0.65, 0.66, 0.68), 0.5, 0.5)
	add_child(pole)

	var disc := MeshInstance3D.new()
	var disc_mesh := CylinderMesh.new()
	disc_mesh.top_radius = 0.3
	disc_mesh.bottom_radius = 0.3
	disc_mesh.height = 0.04
	disc.mesh = disc_mesh
	disc.rotation.x = deg_to_rad(90)
	disc.position = pos + Vector3(0, 2.35, 0)
	if kind == "divieto":
		disc.material_override = Tex.flat(Color(0.15, 0.35, 0.75), 0.6)
		# Barra rossa diagonale
		var bar := MeshInstance3D.new()
		var bar_mesh := BoxMesh.new()
		bar_mesh.size = Vector3(0.52, 0.09, 0.05)
		bar.mesh = bar_mesh
		bar.position = pos + Vector3(0, 2.35, -0.03)
		bar.rotation.z = deg_to_rad(-45)
		bar.material_override = Tex.flat(Color(0.8, 0.12, 0.12), 0.6)
		add_child(bar)
		var ring := MeshInstance3D.new()
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = 0.26
		ring_mesh.outer_radius = 0.31
		ring.mesh = ring_mesh
		ring.rotation.x = deg_to_rad(90)
		ring.position = pos + Vector3(0, 2.35, -0.02)
		ring.material_override = Tex.flat(Color(0.8, 0.12, 0.12), 0.6)
		add_child(ring)
	else:
		disc.material_override = Tex.flat(Color(0.9, 0.9, 0.88), 0.6)
	add_child(disc)


func _make_bench(pos: Vector3, rot_y: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = rot_y
	add_child(root)

	var wood := Tex.flat(Color(0.5, 0.33, 0.19), 0.9)
	var iron := Tex.flat(Color(0.15, 0.16, 0.17), 0.6, 0.5)

	for i in range(3):
		var slat := MeshInstance3D.new()
		var slat_mesh := BoxMesh.new()
		slat_mesh.size = Vector3(1.8, 0.06, 0.14)
		slat.mesh = slat_mesh
		slat.position = Vector3(0, 0.45, -0.2 + i * 0.17)
		slat.material_override = wood
		root.add_child(slat)

	for i in range(3):
		var back := MeshInstance3D.new()
		var back_mesh := BoxMesh.new()
		back_mesh.size = Vector3(1.8, 0.14, 0.05)
		back.mesh = back_mesh
		back.position = Vector3(0, 0.66 + i * 0.17, 0.28)
		back.rotation.x = deg_to_rad(-12)
		back.material_override = wood
		root.add_child(back)

	for sx in [-0.78, 0.78]:
		var leg := MeshInstance3D.new()
		var leg_mesh := BoxMesh.new()
		leg_mesh.size = Vector3(0.08, 0.45, 0.6)
		leg.mesh = leg_mesh
		leg.position = Vector3(sx, 0.22, 0.05)
		leg.material_override = iron
		root.add_child(leg)


func _make_bin(pos: Vector3) -> void:
	# 'E quatte fuste d''o pacchetto: uno a sorte, accussì nun paren tutte
	# 'o stesso cestino stampato quatte vote.
	var quale: String = ["bidone", "bidone2", "bidone3", "bidone4"][
		randi() % 4]
	if _prop(quale, pos, randf_range(0.0, TAU)) != null:
		_prop_solido(pos, Vector3(0.78, 1.08, 0.78))
		return
	var body := MeshInstance3D.new()
	var body_mesh := CylinderMesh.new()
	body_mesh.top_radius = 0.26
	body_mesh.bottom_radius = 0.22
	body_mesh.height = 0.75
	body.mesh = body_mesh
	body.position = pos + Vector3(0, 0.75, 0)
	body.material_override = Tex.flat(Color(0.2, 0.35, 0.24), 0.7, 0.3)
	add_child(body)

	var post := MeshInstance3D.new()
	var post_mesh := CylinderMesh.new()
	post_mesh.top_radius = 0.04
	post_mesh.bottom_radius = 0.04
	post_mesh.height = 0.4
	post.mesh = post_mesh
	post.position = pos + Vector3(0, 0.2, 0)
	post.material_override = Tex.flat(Color(0.15, 0.16, 0.17), 0.6, 0.5)
	add_child(post)


## Tombini e chiazze d'olio sull'asfalto: rompono la monotonia del piano.
func _make_manhole(pos: Vector3) -> void:
	var lid := MeshInstance3D.new()
	var lid_mesh := CylinderMesh.new()
	lid_mesh.top_radius = 0.34
	lid_mesh.bottom_radius = 0.34
	lid_mesh.height = 0.03
	lid.mesh = lid_mesh
	lid.position = pos + Vector3(0, 0.02, 0)
	lid.material_override = Tex.flat(Color(0.28, 0.27, 0.26), 0.85, 0.35)
	add_child(lid)


func _make_oil_stain(pos: Vector3) -> void:
	var stain := MeshInstance3D.new()
	var stain_mesh := PlaneMesh.new()
	stain_mesh.size = Vector2(randf_range(0.8, 1.6), randf_range(0.8, 1.6))
	stain.mesh = stain_mesh
	stain.position = pos + Vector3(0, 0.016, 0)
	stain.rotation.y = randf() * TAU
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.05, 0.06, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.25
	mat.metallic = 0.4
	stain.material_override = mat
	add_child(stain)


## Gabbiani: sagome affusolate con ali a V che battono piano, non più
## scatolette bianche. Volano alti e larghi, così restano un dettaglio di
## sfondo e non oggetti che ti passano in faccia.
func _build_seagulls() -> void:
	_gulls_root = Node3D.new()
	_gulls_root.name = "Gabbiani"
	add_child(_gulls_root)

	var body_mat := Tex.flat(Color(0.96, 0.96, 0.94), 0.95)
	var tip_mat := Tex.flat(Color(0.35, 0.36, 0.38), 0.95)

	for i in range(4):
		var gull := Node3D.new()

		# Corpo affusolato (capsula) e testa
		var body := MeshInstance3D.new()
		var body_mesh := CapsuleMesh.new()
		body_mesh.radius = 0.07
		body_mesh.height = 0.42
		body.mesh = body_mesh
		body.rotation.x = deg_to_rad(90)
		body.material_override = body_mat
		gull.add_child(body)

		var head := MeshInstance3D.new()
		var head_mesh := SphereMesh.new()
		head_mesh.radius = 0.06
		head_mesh.height = 0.12
		head.mesh = head_mesh
		head.position = Vector3(0, 0.02, -0.24)
		head.material_override = body_mat
		gull.add_child(head)

		# Coda a cuneo
		var tail := MeshInstance3D.new()
		var tail_mesh := PrismMesh.new()
		tail_mesh.size = Vector3(0.16, 0.02, 0.2)
		tail.mesh = tail_mesh
		tail.rotation.x = deg_to_rad(-90)
		tail.position = Vector3(0, 0, 0.26)
		tail.material_override = body_mat
		gull.add_child(tail)

		# Ali: due segmenti per lato (interno + esterno con la punta scura),
		# su un perno, così possono battere.
		var wings: Array = []
		for wx in [-1.0, 1.0]:
			var pivot := Node3D.new()
			pivot.position = Vector3(wx * 0.06, 0.02, 0)
			gull.add_child(pivot)

			var inner := MeshInstance3D.new()
			var inner_mesh := BoxMesh.new()
			inner_mesh.size = Vector3(0.34, 0.018, 0.18)
			inner.mesh = inner_mesh
			inner.position = Vector3(wx * 0.17, 0, 0)
			inner.material_override = body_mat
			pivot.add_child(inner)

			var outer := MeshInstance3D.new()
			var outer_mesh := BoxMesh.new()
			outer_mesh.size = Vector3(0.3, 0.015, 0.12)
			outer.mesh = outer_mesh
			outer.position = Vector3(wx * 0.48, 0.015, 0.03)
			outer.rotation.z = deg_to_rad(-wx * 8.0)
			outer.material_override = body_mat
			pivot.add_child(outer)

			var tip := MeshInstance3D.new()
			var tip_mesh := BoxMesh.new()
			tip_mesh.size = Vector3(0.12, 0.014, 0.09)
			tip.mesh = tip_mesh
			tip.position = Vector3(wx * 0.66, 0.03, 0.05)
			tip.rotation.z = deg_to_rad(-wx * 12.0)
			tip.material_override = tip_mat
			pivot.add_child(tip)

			wings.append(pivot)

		gull.set_meta("radius", randf_range(26.0, 46.0))
		gull.set_meta("speed", randf_range(0.06, 0.12))
		gull.set_meta("phase", randf() * TAU)
		gull.set_meta("height", randf_range(30.0, 46.0))
		gull.set_meta("flap", randf_range(1.6, 2.6))
		_gull_wings.append(wings)
		_gulls_root.add_child(gull)


## Crea un unico nodo che disegna tutte le copie di una mesh.
func _make_batch(mesh: Mesh, material: Material, transforms: Array,
		colors: Array = []) -> void:
	if transforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not colors.is_empty()
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		if not colors.is_empty():
			mm.set_instance_color(i, colors[i])
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	node.material_override = material
	add_child(node)


## Costruisce i MultiMesh con tutto quello che è stato accumulato.
func _flush_batches() -> void:
	var win_mat := _window_material()
	var frame_mat := _frame_material()

	var buio_mat := Tex.flat(Color(0.03, 0.03, 0.04), 1.0)
	var croce_mat := Tex.flat(Color(0.94, 0.92, 0.87), 0.75)

	var win_mesh := BoxMesh.new()
	win_mesh.size = Vector3(0.04, 1.5, 0.95)
	_make_batch(win_mesh, win_mat, _batch_windows)

	var vano_mesh := BoxMesh.new()
	vano_mesh.size = Vector3(0.05, 1.56, 1.01)
	_make_batch(vano_mesh, buio_mat, _batch_reveals)

	# I quattro listelli: due orizzontali lunghi e due verticali.
	var bar_h := BoxMesh.new()
	bar_h.size = Vector3(0.14, 0.13, 1.27)
	_make_batch(bar_h, frame_mat, _batch_bars_h)
	var bar_v := BoxMesh.new()
	bar_v.size = Vector3(0.14, 1.80, 0.13)
	_make_batch(bar_v, frame_mat, _batch_bars_v)

	var cro_h := BoxMesh.new()
	cro_h.size = Vector3(0.05, 0.045, 0.95)
	_make_batch(cro_h, croce_mat, _batch_cross_h)
	var cro_v := BoxMesh.new()
	cro_v.size = Vector3(0.05, 1.5, 0.045)
	_make_batch(cro_v, croce_mat, _batch_cross_v)

	# La lastra piena di prima non serve piu': la sostituiscono i listelli.
	# L'array resta per non rompere chi ci scriveva dentro, ma e' vuoto.
	var frame_mesh := BoxMesh.new()
	frame_mesh.size = Vector3(0.07, 1.74, 1.19)
	_make_batch(frame_mesh, frame_mat, _batch_frames)

	var sill_mesh := BoxMesh.new()
	sill_mesh.size = Vector3(0.22, 0.09, 1.32)
	_make_batch(sill_mesh, frame_mat, _batch_sills)

	# Stesse cose, ruotate di 90°, per i palazzi di fondo
	var back_win_mesh := BoxMesh.new()
	back_win_mesh.size = Vector3(0.95, 1.5, 0.04)
	_make_batch(back_win_mesh, win_mat, _batch_back_windows)

	var back_vano := BoxMesh.new()
	back_vano.size = Vector3(1.01, 1.56, 0.05)
	_make_batch(back_vano, buio_mat, _batch_back_reveals)

	var bbar_h := BoxMesh.new()
	bbar_h.size = Vector3(1.27, 0.13, 0.14)
	_make_batch(bbar_h, frame_mat, _batch_back_bars_h)
	var bbar_v := BoxMesh.new()
	bbar_v.size = Vector3(0.13, 1.80, 0.14)
	_make_batch(bbar_v, frame_mat, _batch_back_bars_v)

	var bcro_h := BoxMesh.new()
	bcro_h.size = Vector3(0.95, 0.045, 0.05)
	_make_batch(bcro_h, croce_mat, _batch_back_cross_h)
	var bcro_v := BoxMesh.new()
	bcro_v.size = Vector3(0.045, 1.5, 0.05)
	_make_batch(bcro_v, croce_mat, _batch_back_cross_v)

	var back_frame_mesh := BoxMesh.new()
	back_frame_mesh.size = Vector3(1.19, 1.74, 0.07)
	_make_batch(back_frame_mesh, frame_mat, _batch_back_frames)

	var back_sill_mesh := BoxMesh.new()
	back_sill_mesh.size = Vector3(1.32, 0.09, 0.22)
	_make_batch(back_sill_mesh, frame_mat, _batch_back_sills)

	var shutter_mesh := BoxMesh.new()
	shutter_mesh.size = Vector3(0.1, 1.6, 0.28)
	_make_batch(shutter_mesh, Tex.flat(Color(0.22, 0.34, 0.24)), _batch_shutters)

	var flag_mesh := PrismMesh.new()
	flag_mesh.size = Vector3(0.36, 0.44, 0.02)
	var flag_a := Tex.flat(Color(0.05, 0.55, 0.9))
	flag_a.cull_mode = BaseMaterial3D.CULL_DISABLED
	var flag_b := Tex.flat(Color(0.97, 0.97, 0.95))
	flag_b.cull_mode = BaseMaterial3D.CULL_DISABLED
	_make_batch(flag_mesh, flag_a, _batch_flags_a)
	_make_batch(flag_mesh, flag_b, _batch_flags_b)

	var cloth_mesh := BoxMesh.new()
	cloth_mesh.size = Vector3(1.0, 1.0, 0.03)
	var cloth_mat := Tex.flat(Color.WHITE, 1.0)
	cloth_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	cloth_mat.vertex_color_use_as_albedo = true
	_make_batch(cloth_mesh, cloth_mat, _batch_cloths, _batch_cloth_colors)


func _make_wall_collider(center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = LAYER_WORLD
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	shape.position = center
	body.add_child(shape)
	add_child(body)


## Materiale delle finestre: uno solo, condiviso da tutta la piazza.
## Vetro di giorno: scuro e lucido, riflette il cielo. Prima aveva
## un'emissione calda forte e da lontano le finestre sembravano rettangoli
## beige incollati sul muro, non buchi nella facciata.
func _window_material() -> StandardMaterial3D:
	# Vetro dielettrico, non specchio metallico: con metallic 0.85 le
	# finestre erano specchietti che lampeggiavano a ogni passo. Con
	# metallic 0 e rugosita' 0.14 riflettono la volta del cielo — che e'
	# quello che si vede davvero da sotto — senza fare il lampo del sole.
	return Tex.flat(Color(0.055, 0.075, 0.105), 0.14, 0.0)


func _frame_material() -> StandardMaterial3D:
	return Tex.flat(Color(0.86, 0.83, 0.76), 0.85)


func _make_window(pos: Vector3, is_left: bool) -> void:
	# `inward` punta verso il centro della piazza, cioe' verso chi guarda:
	# e' il verso in cui la roba deve SPORGERE, e il verso opposto e' quello
	# in cui la finestra rientra nel muro.
	var inward: float = 1.0 if is_left else -1.0
	var fuori := Vector3(inward, 0, 0)
	# Dal fondo del muro verso l'esterno: vano scuro, vetro, crociera,
	# listelli a filo, davanzale che sporge.
	_batch_reveals.append(Transform3D(Basis(), pos - fuori * 0.09))
	_batch_windows.append(Transform3D(Basis(), pos - fuori * 0.045))
	_batch_cross_h.append(Transform3D(Basis(), pos - fuori * 0.035))
	_batch_cross_v.append(Transform3D(Basis(), pos - fuori * 0.035))
	for dy in [-0.855, 0.855]:
		_batch_bars_h.append(Transform3D(Basis(),
			pos + fuori * 0.035 + Vector3(0, dy, 0)))
	for dz in [-0.57, 0.57]:
		_batch_bars_v.append(Transform3D(Basis(),
			pos + fuori * 0.035 + Vector3(0, 0, dz)))
	_batch_sills.append(Transform3D(Basis(), pos + fuori * 0.08 + Vector3(0, -0.93, 0)))
	for dz2 in [-0.72, 0.72]:
		_batch_shutters.append(Transform3D(Basis(),
			pos + fuori * 0.09 + Vector3(0, 0, dz2)))


## Come _make_window ma per i palazzi di fondo, dove la facciata guarda
## lungo Z invece che lungo X.
func _make_back_window(pos: Vector3, inward_z: float) -> void:
	var fuori := Vector3(0, 0, inward_z)
	_batch_back_reveals.append(Transform3D(Basis(), pos - fuori * 0.09))
	_batch_back_windows.append(Transform3D(Basis(), pos - fuori * 0.045))
	_batch_back_cross_h.append(Transform3D(Basis(), pos - fuori * 0.035))
	_batch_back_cross_v.append(Transform3D(Basis(), pos - fuori * 0.035))
	for dy in [-0.855, 0.855]:
		_batch_back_bars_h.append(Transform3D(Basis(),
			pos + fuori * 0.035 + Vector3(0, dy, 0)))
	for dx in [-0.57, 0.57]:
		_batch_back_bars_v.append(Transform3D(Basis(),
			pos + fuori * 0.035 + Vector3(dx, 0, 0)))
	_batch_back_sills.append(Transform3D(Basis(),
		pos + fuori * 0.08 + Vector3(0, -0.93, 0)))


func _make_balcony(pos: Vector3, is_left: bool) -> void:
	var inward: float = 1.0 if is_left else -1.0
	var slab := MeshInstance3D.new()
	var slab_mesh := BoxMesh.new()
	slab_mesh.size = Vector3(1.3, 0.14, 4.0)
	slab.mesh = slab_mesh
	slab.position = pos
	var slab_mat := Tex.flat(Color(0.78, 0.75, 0.68))
	slab.material_override = slab_mat
	add_child(slab)

	# **La ringhiera si vede attraverso.**
	#
	# Era una lastra piena: quattro metri per novantacinque centimetri di
	# colore 0,12, cioe' nero. Sui palazzi della piazza — che e' il posto
	# dove si comincia e dove si passa piu' tempo — diventava una barra
	# nera sopra a ogni bottega, e nelle foto era la prima cosa che
	# saltava all'occhio. Anche i due fianchi erano lastre, 1,2 per 0,95.
	#
	# Una ringhiera di ferro e' quasi tutta aria. Adesso ci sono i due
	# orizzontali e i ferri verticali ogni sedici centimetri: dietro si
	# vede l'intonaco, e il balcone si legge per quello che e'.
	var rail_mat := Tex.flat(Color(0.13, 0.13, 0.14), 0.5, 0.6)
	var x_rail: float = inward * 0.6

	# Corrimano e traversa bassa lungo il fronte.
	for coppia in [[0.95, 0.07], [0.10, 0.05]]:
		var trav := MeshInstance3D.new()
		var tm := BoxMesh.new()
		tm.size = Vector3(0.09, float(coppia[1]), 4.0)
		trav.mesh = tm
		trav.position = pos + Vector3(x_rail, float(coppia[0]), 0)
		trav.material_override = rail_mat
		add_child(trav)

	# I ferri verticali del fronte.
	const PASSO_FERRI: float = 0.16
	var quanti: int = int(round(4.0 / PASSO_FERRI))
	for i in range(quanti + 1):
		var ferro := MeshInstance3D.new()
		var fm := BoxMesh.new()
		fm.size = Vector3(0.035, 0.9, 0.035)
		ferro.mesh = fm
		ferro.position = pos + Vector3(x_rail, 0.5,
			-2.0 + 4.0 * float(i) / float(quanti))
		ferro.material_override = rail_mat
		add_child(ferro)

	# I due fianchi: corrimano piu' tre ferri, non piu' un pannello.
	for dz in [-1.9, 1.9]:
		var cor := MeshInstance3D.new()
		var cm := BoxMesh.new()
		cm.size = Vector3(1.2, 0.07, 0.09)
		cor.mesh = cm
		cor.position = pos + Vector3(inward * 0.05, 0.95, dz)
		cor.material_override = rail_mat
		add_child(cor)
		for k in range(4):
			var f2 := MeshInstance3D.new()
			var f2m := BoxMesh.new()
			f2m.size = Vector3(0.035, 0.9, 0.035)
			f2.mesh = f2m
			f2.position = pos + Vector3(
				inward * (0.05 - 0.6 + 0.4 * float(k)), 0.5, dz)
			f2.material_override = rail_mat
			add_child(f2)

	# Piante e panni sul balcone
	for i in range(2):
		var plant := MeshInstance3D.new()
		var plant_mesh := SphereMesh.new()
		plant_mesh.radius = 0.22
		plant_mesh.height = 0.4
		plant.mesh = plant_mesh
		plant.position = pos + Vector3(inward * 0.35, 0.32, -1.1 + i * 2.2)
		plant.material_override = Tex.flat(Color(0.22, 0.52, 0.2))
		add_child(plant)


## **'A merce sta fore, ncopp'ê casce** (0.58).
##
## Il primo tentativo si chiamava «la merce dietro al vetro» e appoggiava
## sei oggetti a mezz'aria a quarantasei centimetri dalla facciata. La
## fotografia ha mostrato perché non poteva funzionare: **queste vetrine
## non hanno un vetro.** `_make_shopfront` costruisce una *serranda* —
## texture "serranda", lamiera ondulata — e dietro non c'è niente, perché
## dalla 0.44 il piano terra del quartiere è fatto di saracinesche
## abbassate. Avevo scritto "dietro al vetro" e c'era una persiana di
## metallo.
##
## La cosa giusta era già sotto gli occhi e sta in ogni strada di Napoli:
## **la merce sta fuori**, su due casse appoggiate al muro, mezzo metro
## dalla serranda. Così si vede (prima era nascosta da una lamiera), non
## sta in mezzo a nessuno, e non ha bisogno di un vetro che non esiste.
const MERCE := ["scatoletta", "scatoletta2", "scatoletta_arrugginita",
	"carne", "libro", "libro2", "libro3", "medicine", "benda",
	"curtiello_piccolo", "monitor", "televisore", "piatto", "bottiglia_vetro",
	"lattina", "cidi", "videocassetta", "sveglia", "torcia", "telefonino",
	"telefonino_viecchio", "documento", "cornice"]

## Quanto è alta 'a cascia ca fa 'a bancarella (`cascia_legno`: 0,72 × 0,40).
const CASCIA_NCOPPA: float = 0.40

func _merce_fore_ô_negozio(pos: Vector3, w: float, inward: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4517 + int(pos.z * 100.0) + int(pos.x * 7.0)
	# Non tutte le saracinesche sono aperte: due su tre restano chiuse e
	# mute, che è il ritmo vero di una strada — se ogni serranda avesse la
	# bancarella davanti, il vicolo sembrerebbe una fiera.
	if rng.randf() > 0.34:
		return
	var y0: float = pos.y + 0.12       # 'o marciapiede
	var zc: Array = [-w * 0.22, w * 0.22]
	for k in range(2):
		var c := Models.spawn("cascia_legno")
		if c == null:
			return
		c.position = pos + Vector3(inward * 0.52, 0.12, float(zc[k]))
		c.rotation.y = PI * 0.5
		# **'O nomme serve.** `Models.spawn` torna il nodo radice del .glb,
		# che si chiama come l'ha chiamato chi l'ha esportato — non
		# "cascia_legno". Senza un nome nostro, niente e nessuno riesce più
		# a ritrovare questa cassa nella scena: la prova delle fotografie
		# l'ha cercata e ha stampato NUN S'È TRUVATA 'NA BANCARELLA.
		c.name = "bancarella_%d" % k
		add_child(c)
	# Tre pezzi per cassa, appoggiati sopra.
	for i in range(6):
		var nome: String = str(MERCE[rng.randi() % MERCE.size()])
		var n := Models.spawn(nome)
		if n == null:
			continue
		n.position = pos + Vector3(inward * (0.40 + rng.randf() * 0.24),
			0.12 + CASCIA_NCOPPA,
			float(zc[i / 3]) + rng.randf_range(-0.22, 0.22))
		n.rotation.y = rng.randf_range(0.0, TAU)
		add_child(n)


## Vetrina con serranda abbassata: il piano terra del quartiere.
func _make_shopfront(pos: Vector3, w: float, is_left: bool) -> void:
	var inward: float = 1.0 if is_left else -1.0
	_merce_fore_ô_negozio(pos, w, inward)
	var shutter := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.1, 3.0, w)
	shutter.mesh = mesh
	shutter.position = pos + Vector3(0, 1.55, 0)
	shutter.material_override = Tex.mondo("serranda", Color.WHITE, 0.6)
	add_child(shutter)

	# Architrave
	var lintel := MeshInstance3D.new()
	var lintel_mesh := BoxMesh.new()
	lintel_mesh.size = Vector3(0.3, 0.45, w + 0.5)
	lintel.mesh = lintel_mesh
	lintel.position = pos + Vector3(inward * 0.08, 3.3, 0)
	var lintel_mat := StandardMaterial3D.new()
	lintel_mat.albedo_color = Color(0.35, 0.3, 0.28)
	lintel.material_override = lintel_mat
	add_child(lintel)


func _make_portone(pos: Vector3, is_left: bool) -> void:
	var inward: float = 1.0 if is_left else -1.0
	var door := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.14, 4.0, 2.6)
	door.mesh = mesh
	door.position = pos + Vector3(0, 2.05, 0)
	door.material_override = Tex.get_material("portone", Vector2(1, 1), 0.7)
	add_child(door)

	var step := MeshInstance3D.new()
	var step_mesh := BoxMesh.new()
	step_mesh.size = Vector3(0.7, 0.16, 2.9)
	step.mesh = step_mesh
	step.position = pos + Vector3(inward * 0.35, 0.08, 0)
	var step_mat := StandardMaterial3D.new()
	step_mat.albedo_color = Color(0.72, 0.7, 0.66)
	step.material_override = step_mat
	add_child(step)


func _make_posters(pos: Vector3, w: float, _is_left: bool) -> void:
	var posters := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.06, 2.4, w)
	posters.mesh = mesh
	posters.position = pos + Vector3(0, 1.7, 0)
	posters.material_override = Tex.mondo("manifesti", Color.WHITE, 0.95)
	add_child(posters)


# ---------------------------------------------------------------------------
# Panorama: il golfo e il Vesuvio oltre il lato basso
# ---------------------------------------------------------------------------

func _build_panorama() -> void:
	# Mare all'orizzonte, oltre i palazzi bassi del fondo
	var sea := MeshInstance3D.new()
	var sea_plane := PlaneMesh.new()
	sea_plane.size = Vector2(500, 260)
	sea.mesh = sea_plane
	sea.position = Vector3(width / 2.0, 1.0, -150.0)
	var sea_mat := StandardMaterial3D.new()
	sea_mat.albedo_color = Color(0.29, 0.45, 0.58)
	sea_mat.metallic = 0.5
	sea_mat.roughness = 0.25
	sea.material_override = sea_mat
	add_child(sea)

	# Il Vesuvio. Prima erano due cilindri appoggiati uno accanto all'altro,
	# piccoli e lontanissimi: da dentro la piazza si leggevano come due
	# gobbe grigie qualsiasi. Adesso ha il profilo vero — il cono col
	# cratere tagliato a destra e la cresta del Monte Somma a sinistra, piu'
	# bassa e seghettata — ed e' grande e alto abbastanza da vedersi sopra
	# ai tetti da qualunque punto della piazza.
	_build_vesuvio()
	_resto_panorama()


## Il profilo del Vesuvio, montato a fette di cono sovrapposte. Le fette
## sono poche e larghe: da due chilometri di distanza non serve altro, e
## quello che conta e' la sagoma.
func _build_vesuvio() -> void:
	# Alto 170 metri a 450 di distanza: sono venti gradi di cielo, che e' la
	# proporzione giusta perche' si legga come una montagna lontana e non
	# come un muro grigio piantato dietro ai palazzi. A 230 metri riempiva
	# mezza inquadratura e sembrava di stare a Ercolano.
	var root := Node3D.new()
	root.name = "Vesuvio"
	root.position = Vector3(width / 2.0 + 22.0, 0.0, -430.0)
	root.scale = Vector3.ONE * 2.4
	add_child(root)

	# Tre tinte: piu' chiara in alto (foschia), piu' scura in basso.
	# Tinte cariche: a quella distanza la foschia le schiarisce di suo, e se
	# partono già chiare la montagna sparisce nel cielo.
	var alta := _tinta_monte(Color(0.38, 0.45, 0.60))
	var media := _tinta_monte(Color(0.30, 0.37, 0.53))
	var bassa := _tinta_monte(Color(0.23, 0.29, 0.45))

	# --- Il gran cono ---
	# Fette: [raggio in basso, raggio in alto, altezza, quota della base]
	var fette := [
		[96.0, 74.0, 16.0, 0.0], [74.0, 54.0, 18.0, 16.0],
		[54.0, 36.0, 18.0, 34.0], [36.0, 24.0, 14.0, 52.0],
	]
	for i in fette.size():
		var f: Array = fette[i]
		var m := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.bottom_radius = f[0]
		cm.top_radius = f[1]
		cm.height = f[2]
		cm.radial_segments = 22
		m.mesh = cm
		m.position = Vector3(0, f[3] + f[2] / 2.0, 0)
		m.material_override = bassa if i == 0 else (media if i < 3 else alta)
		root.add_child(m)

	# Il cratere: un anello di orlo, e dentro l'ombra.
	var orlo := MeshInstance3D.new()
	var om := CylinderMesh.new()
	om.bottom_radius = 24.0
	om.top_radius = 21.0
	om.height = 5.0
	om.radial_segments = 22
	orlo.mesh = om
	orlo.position = Vector3(0, 68.0, 0)
	orlo.material_override = alta
	root.add_child(orlo)

	var dentro := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.bottom_radius = 15.0
	dm.top_radius = 18.0
	dm.height = 7.0
	dm.radial_segments = 18
	dentro.mesh = dm
	dentro.position = Vector3(0, 66.5, 0)
	dentro.material_override = _tinta_monte(Color(0.24, 0.29, 0.43))
	root.add_child(dentro)

	# --- Il Monte Somma: la cresta a sinistra, piu' bassa e spezzata ---
	var somma := Node3D.new()
	somma.position = Vector3(-62.0, 0.0, 10.0)
	root.add_child(somma)
	var creste := [
		[72.0, 40.0, 30.0, 0.0, 0.0], [46.0, 26.0, 14.0, 30.0, -8.0],
		[30.0, 14.0, 10.0, 44.0, 16.0],
	]
	for c in creste:
		var m2 := MeshInstance3D.new()
		var cm2 := CylinderMesh.new()
		cm2.bottom_radius = c[0]
		cm2.top_radius = c[1]
		cm2.height = c[2]
		cm2.radial_segments = 16
		m2.mesh = cm2
		m2.position = Vector3(c[4], c[3] + c[2] / 2.0, 0)
		m2.material_override = media if c[3] < 40.0 else alta
		somma.add_child(m2)

	# Il pennacchio: un filo di fumo che sale dal cratere e si allarga.
	var fumo := Node3D.new()
	fumo.position = Vector3(0, 72.0, 0)
	root.add_child(fumo)
	var fumo_mat := StandardMaterial3D.new()
	fumo_mat.albedo_color = Color(0.86, 0.86, 0.84, 0.5)
	fumo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fumo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fumo_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	for i in 4:
		var s2 := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 9.0 + i * 5.0
		sm.height = sm.radius * 1.6
		sm.radial_segments = 10
		sm.rings = 6
		s2.mesh = sm
		s2.position = Vector3(i * 7.0, i * 11.0, 0)
		s2.material_override = fumo_mat
		fumo.add_child(s2)


## Le montagne sono fondale: non vanno illuminate.
##
## Finche' il sole ci batteva sopra, il colore finale era albedo per luce
## per ambientale, e usciva sempre un crema slavato qualunque tinta ci si
## mettesse. Senza illuminazione il colore scritto qui e' esattamente
## quello che si vede — meno la foschia, che ci pensa lei a dare distanza.
func _tinta_monte(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


## Le colline dall'altra parte del golfo: servono solo a non lasciare
## l'orizzonte vuoto accanto al Vesuvio.
func _resto_panorama() -> void:
	var lontane := _tinta_monte(Color(0.42, 0.48, 0.60))
	for i in range(3):
		var hill := MeshInstance3D.new()
		var h_mesh := SphereMesh.new()
		h_mesh.radius = 45.0
		h_mesh.height = 46.0
		hill.mesh = h_mesh
		hill.position = Vector3(width / 2.0 - 118.0 - i * 55.0, 2.0, -150.0 - i * 12.0)
		hill.material_override = lontane
		add_child(hill)


# ---------------------------------------------------------------------------
# Arredo urbano
# ---------------------------------------------------------------------------

func _build_props() -> void:
	for zf in [0.16, 0.42, 0.68, 0.9]:
		_make_lamppost(Vector3(3.4, 0.12, length * zf))
		_make_lamppost(Vector3(width - 3.4, 0.12, length * zf))

	_make_dumpster(Vector3(4.2, 0.0, length - 6.0))
	_make_vespa(Vector3(width - 4.4, 0.12, length * 0.55))
	_make_vespa(Vector3(4.4, 0.12, length * 0.3))
	_make_fountain(Vector3(width / 2.0, 0.0, length * 0.72))
	_make_cone(Vector3(width - 6.0, 0.0, 6.2))
	_make_cone(Vector3(width - 6.0, 0.0, 7.4))

	# Segnaletica (il divieto di sosta, proprio dove lavori tu)
	_make_road_sign(Vector3(width - 3.6, 0.12, length * 0.24), "divieto")
	_make_road_sign(Vector3(3.6, 0.12, length * 0.8), "divieto")

	# Panchine e cestini attorno al salotto
	_make_bench(Vector3(width / 2.0 - 6.5, 0.12, length * 0.45), PI / 2.0)
	_make_bench(Vector3(width / 2.0 + 6.5, 0.12, length * 0.45), -PI / 2.0)
	_make_bin(Vector3(width / 2.0 - 5.2, 0.12, length * 0.38))
	# Il cestino stava a `length * 0.9`, cioè dentro al cassonetto (che sta
	# a `length - 6`): due recipienti della munnezza uno nell'altro
	# (`prova_ngombri`, 0.59). Un metro e mezzo più su è accanto, non dentro.
	_make_bin(Vector3(3.4, 0.12, length * 0.84))

	# 'O campetto: due cassette per pali, la rete disegnata sul muro, e un
	# pallone. È l'attività secondaria più stupida e più bella del gioco.
	_build_campetto()

	# Tombini e chiazze d'olio sull'asfalto
	for t in [[0.3, 0.3], [0.7, 0.55], [0.45, 0.82], [0.62, 0.18]]:
		_make_manhole(Vector3(width * t[0], 0.0, length * t[1]))

	# 'A munnezza d''o vicolo (0.58).
	#
	# **Se mette doppo, no mo'.** Deve sapere dove stanno il guaglione, la
	# bacheca, i vicini e i posti auto per non piantarcisi addosso, e in
	# questo momento metà di loro non esiste ancora: `_build_props()` gira
	# mentre la piazza si sta costruendo. Rimandata di un fotogramma, la
	# scena è completa e le si può chiedere chi c'è.
	call_deferred("_build_robba_psx")

	# **'O distributore automatico**, uno solo, appoggiato alla facciata di
	# ponente. Non si usa e non vende niente: è la macchina illuminata che
	# in un vicolo buio si vede da cinquanta metri, ed è l'unica cosa che
	# fa luce propria a mezzavia fra due lampioni.
	var d := _prop("distributore", Vector3(1.05, 0.12, length * 0.62),
		PI * 0.5)
	if d != null:
		_prop_solido(Vector3(1.05, 0.12, length * 0.62),
			Vector3(1.1, 2.0, 0.8))
	for i in range(7):
		_make_oil_stain(Vector3(randf_range(6.0, width - 6.0), 0.0, randf_range(5.0, length - 5.0)))

	_build_seagulls()
	_build_bandierine()
	_build_clotheslines()
	_build_edicola_votiva(Vector3(width - 1.4, 0.0, length * 0.34))

	# I tre negozi della piazza. Il "fronte" di ogni modello è il suo +X
	# locale: sui palazzi di sinistra resta com'è (guarda verso +X, cioè
	# verso il centro), su quelli di destra va girato di 180°.
	var shop = ShopScene.new()
	shop.position = Vector3(3.4, 0.12, length * 0.5)
	add_child(shop)

	var tabacchi = TabaccheriaScene.new()
	tabacchi.position = Vector3(width - 3.0, 0.0, length * 0.62)
	tabacchi.rotation.y = PI
	add_child(tabacchi)

	var bazar = BazarScene.new()
	bazar.position = Vector3(3.0, 0.0, length * 0.72)
	add_child(bazar)

	# **'O bar, uno pe' piazza (0.52).** Ce n'era uno solo in tutta la
	# citta': chi si comprava una piazza nuova restava senza caffe', e il
	# caffe' e' quello che abbassa il sospetto e rimette in forza. Sta sul
	# lato di destra, quindi girato di 180° come il tabaccaio.
	var bar = BarScene.new()
	bar.position = Vector3(width - 3.0, 0.0, length * 0.34)
	bar.rotation.y = PI
	add_child(bar)

	_build_decorations()


func _make_lamppost(pos: Vector3) -> void:
	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.06
	pole_mesh.bottom_radius = 0.09
	pole_mesh.height = 4.4
	pole.mesh = pole_mesh
	pole.position = pos + Vector3(0, 2.2, 0)
	pole.material_override = Tex.flat(Color(0.13, 0.14, 0.16), 0.45, 0.6)
	add_child(pole)

	var globe := MeshInstance3D.new()
	var globe_mesh := SphereMesh.new()
	globe_mesh.radius = 0.2
	globe_mesh.height = 0.4
	globe.mesh = globe_mesh
	globe.position = pos + Vector3(0, 4.55, 0)
	# Materiale suo, non quello condiviso della cache: l'emissione va
	# accesa e spenta lampione per lampione col calare del sole, e se il
	# materiale fosse in comune si accenderebbe mezza piazza.
	globe.material_override = Tex.flat(Color(1.0, 0.94, 0.75), 0.9, 0.0, 1.7).duplicate()
	add_child(globe)

	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 4.3, 0)
	light.light_color = Color(1.0, 0.86, 0.6)
	light.light_energy = 1.7
	light.omni_range = 11.0
	light.shadow_enabled = false
	add_child(light)
	if _ciclo:
		_ciclo.aggiungi_lampione(light, globe)


## **'O ponte p''a robba 'e strada** (0.58).
##
## Stessa regola che vale per le auto dalla 0.14 e per il salotto dalla
## 0.55: si chiede prima il modello, e le scatole restano sotto come rete.
## `giro` in gradi, che è come si correggono guardando una fotografia.
func _prop(nome: String, pos: Vector3, giro: float = 0.0) -> Node3D:
	var n := Models.spawn(nome)
	if n == null:
		return null
	n.position = pos
	n.rotation.y = giro
	add_child(n)
	return n


## Il corpo solido di un oggetto di strada. **Va messo lo stesso anche
## quando il modello c'è**: un modello importato porta la mesh, non il
## collider, e un bidone che si attraversa è peggio di un bidone di scatole
## — è la stessa famiglia del muro attraversabile di casa della 0.50.
##
## **E gira comm'a 'o modello** (0.59). Il modello si mette girato a caso,
## il corpo no: restava dritto. Per un bidone tondo non cambia niente; per
## il bastone da tenda (tre metri e dieci per dieci centimetri) e per il
## tubo (due metri e sessanta) il corpo stava di traverso rispetto a quello
## che si vedeva — si sbatteva contro l'aria, e si passava attraverso il
## tubo. `giro` è lo stesso angolo dato al modello.
func _prop_solido(pos: Vector3, mis: Vector3, giro: float = 0.0) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = LAYER_WORLD
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = mis
	shape.shape = box
	shape.position = pos + Vector3(0, mis.y * 0.5, 0)
	shape.rotation.y = giro
	body.add_child(shape)
	add_child(body)


func _make_dumpster(pos: Vector3) -> void:
	var bin := MeshInstance3D.new()
	var bin_mesh := BoxMesh.new()
	bin_mesh.size = Vector3(1.2, 1.2, 2.2)
	bin.mesh = bin_mesh
	bin.position = pos + Vector3(0, 0.6, 0)
	var bin_mat := StandardMaterial3D.new()
	bin_mat.albedo_color = Color(0.16, 0.38, 0.2)
	bin_mat.roughness = 0.75
	bin.material_override = bin_mat
	add_child(bin)

	var body := StaticBody3D.new()
	body.collision_layer = LAYER_WORLD
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.2, 1.2, 2.2)
	shape.shape = box
	shape.position = pos + Vector3(0, 0.6, 0)
	body.add_child(shape)
	add_child(body)


func _make_vespa(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = randf_range(-0.4, 0.4)
	add_child(root)

	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = [Color(0.65, 0.75, 0.8), Color(0.8, 0.75, 0.55), Color(0.7, 0.3, 0.3)][randi() % 3]
	body_mat.metallic = 0.55
	body_mat.roughness = 0.3

	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.35, 0.35, 1.2)
	body.mesh = body_mesh
	body.position = Vector3(0, 0.5, 0)
	body.material_override = body_mat
	root.add_child(body)

	var seat := MeshInstance3D.new()
	var seat_mesh := BoxMesh.new()
	seat_mesh.size = Vector3(0.3, 0.12, 0.5)
	seat.mesh = seat_mesh
	seat.position = Vector3(0, 0.72, 0.2)
	var seat_mat := StandardMaterial3D.new()
	seat_mat.albedo_color = Color(0.18, 0.15, 0.12)
	seat.material_override = seat_mat
	root.add_child(seat)

	var shield := MeshInstance3D.new()
	var shield_mesh := BoxMesh.new()
	shield_mesh.size = Vector3(0.32, 0.55, 0.06)
	shield.mesh = shield_mesh
	shield.position = Vector3(0, 0.72, -0.5)
	shield.material_override = body_mat
	root.add_child(shield)

	var wheel_mat := StandardMaterial3D.new()
	wheel_mat.albedo_color = Color(0.05, 0.05, 0.05)
	for wz in [-0.5, 0.5]:
		var wheel := MeshInstance3D.new()
		var wheel_mesh := CylinderMesh.new()
		wheel_mesh.top_radius = 0.18
		wheel_mesh.bottom_radius = 0.18
		wheel_mesh.height = 0.1
		wheel.mesh = wheel_mesh
		wheel.rotation.z = deg_to_rad(90)
		wheel.position = Vector3(0, 0.18, wz)
		wheel.material_override = wheel_mat
		root.add_child(wheel)


## Fontanella di piazza in pietra, con getto d'acqua.
## **'A fontana d''a piazza, cu 'e maioliche attuorno.**
##
## Alla 0.47 le maioliche sono uscite dal pavimento della piazza, dove non
## ci sono mai state: in mezzo a uno spiazzo dove passano le macchine si
## spaccano in una settimana, e infatti quel pavimento sembrava una
## tovaglia. Ma il posto giusto per le maioliche a Napoli esiste, ed è
## esattamente questo: **il giro di una fontana**. Piccolo, guardato da
## vicino, fatto apposta perché si guardi.
##
## Qui ce ne stanno due giri: la fascia sul bordo della vasca — che è
## quello che si vede stando in piedi accanto — e l'anello per terra
## attorno, che è quello che si vede arrivando.
##
## E la pietra non è più un grigio piatto: è piperno, la pietra di Napoli,
## la stessa del lastricato del salotto a due passi.
func _make_fountain(pos: Vector3) -> void:
	var stone := Tex.mondo("piperno", Color(0.84, 0.82, 0.80), 0.92)

	# L'anello di maioliche per terra: due metri e mezzo di raggio, appena
	# sopra al lastricato perché non sfarfalli.
	var anello := MeshInstance3D.new()
	var am := CylinderMesh.new()
	am.top_radius = 2.62
	am.bottom_radius = 2.62
	am.height = 0.04
	am.radial_segments = 20
	anello.mesh = am
	anello.position = pos + Vector3(0, 0.145, 0)
	anello.material_override = Tex.mondo("maioliche",
		Color(0.92, 0.91, 0.89), 0.55)
	add_child(anello)

	# Il cordolo di piperno che chiude l'anello: senza, il disco di
	# maioliche finisce di netto sull'asfalto e si legge come un adesivo.
	var cordolo := MeshInstance3D.new()
	var com := TorusMesh.new()
	com.inner_radius = 2.58
	com.outer_radius = 2.78
	com.rings = 20
	com.ring_segments = 6
	cordolo.mesh = com
	cordolo.position = pos + Vector3(0, 0.16, 0)
	cordolo.material_override = stone
	add_child(cordolo)

	var basin := MeshInstance3D.new()
	var basin_mesh := CylinderMesh.new()
	basin_mesh.top_radius = 1.5
	basin_mesh.bottom_radius = 1.7
	basin_mesh.height = 0.7
	basin_mesh.radial_segments = 20
	basin.mesh = basin_mesh
	basin.position = pos + Vector3(0, 0.35, 0)
	basin.material_override = stone
	add_child(basin)

	# 'A fascia 'e maioliche ncopp'ô bordo d''a vasca.
	var fascia := MeshInstance3D.new()
	var fam := CylinderMesh.new()
	fam.top_radius = 1.53
	fam.bottom_radius = 1.56
	fam.height = 0.34
	fam.radial_segments = 20
	fascia.mesh = fam
	fascia.position = pos + Vector3(0, 0.52, 0)
	fascia.material_override = Tex.mondo("maioliche",
		Color(0.90, 0.90, 0.88), 0.55)
	add_child(fascia)

	var water := MeshInstance3D.new()
	var water_mesh := CylinderMesh.new()
	water_mesh.top_radius = 1.35
	water_mesh.bottom_radius = 1.35
	water_mesh.height = 0.08
	water.mesh = water_mesh
	water.position = pos + Vector3(0, 0.68, 0)
	var water_mat := StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.3, 0.55, 0.6, 0.85)
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_mat.metallic = 0.6
	water_mat.roughness = 0.1
	water.material_override = water_mat
	add_child(water)

	var column := MeshInstance3D.new()
	var col_mesh := CylinderMesh.new()
	col_mesh.top_radius = 0.22
	col_mesh.bottom_radius = 0.3
	col_mesh.height = 1.5
	column.mesh = col_mesh
	col_mesh.radial_segments = 14
	column.position = pos + Vector3(0, 1.4, 0)
	column.material_override = stone
	add_child(column)

	var jet := CPUParticles3D.new()
	jet.amount = 40
	jet.lifetime = 1.2
	jet.direction = Vector3(0, 1, 0)
	jet.spread = 8.0
	jet.initial_velocity_min = 2.2
	jet.initial_velocity_max = 2.8
	jet.gravity = Vector3(0, -9.0, 0)
	jet.scale_amount_min = 0.03
	jet.scale_amount_max = 0.06
	var drop := SphereMesh.new()
	drop.radius = 0.5
	drop.height = 1.0
	var drop_mat := StandardMaterial3D.new()
	drop_mat.albedo_color = Color(0.75, 0.9, 0.95, 0.7)
	drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop.material = drop_mat
	jet.mesh = drop
	jet.position = pos + Vector3(0, 2.1, 0)
	add_child(jet)
	jet.emitting = true

	_make_wall_collider(pos + Vector3(0, 0.5, 0), Vector3(3.2, 1.0, 3.2))


func _make_cone(pos: Vector3) -> void:
	var cone := MeshInstance3D.new()
	var cone_mesh := CylinderMesh.new()
	cone_mesh.top_radius = 0.03
	cone_mesh.bottom_radius = 0.18
	cone_mesh.height = 0.55
	cone.mesh = cone_mesh
	cone.position = pos + Vector3(0, 0.28, 0)
	var cone_mat := StandardMaterial3D.new()
	cone_mat.albedo_color = Color(0.95, 0.4, 0.1)
	cone.material_override = cone_mat
	add_child(cone)


func _build_bandierine() -> void:
	for zf in [0.3, 0.52, 0.78]:
		var z: float = length * zf
		var h := 9.0
		var rope := MeshInstance3D.new()
		var rope_mesh := BoxMesh.new()
		rope_mesh.size = Vector3(width, 0.03, 0.03)
		rope.mesh = rope_mesh
		rope.position = Vector3(width / 2.0, h, z)
		rope.material_override = Tex.flat(Color(0.28, 0.28, 0.28))
		add_child(rope)

		var n := int(width / 1.3)
		for i in range(n):
			var basis := Basis(Vector3.UP, randf_range(-0.25, 0.25)) * Basis(Vector3.FORWARD, PI)
			var xform := Transform3D(basis, Vector3(0.9 + i * 1.3, h - 0.24, z))
			if i % 2 == 0:
				_batch_flags_a.append(xform)
			else:
				_batch_flags_b.append(xform)


func _build_clotheslines() -> void:
	var rope_mat := Tex.flat(Color(0.75, 0.72, 0.68))
	for zf in [0.2, 0.62, 0.86]:
		var z: float = length * zf
		var h: float = 6.2
		var rope := MeshInstance3D.new()
		var rope_mesh := BoxMesh.new()
		rope_mesh.size = Vector3(width * 0.45, 0.025, 0.025)
		rope.mesh = rope_mesh
		rope.position = Vector3(width * 0.24, h, z)
		rope.material_override = rope_mat
		add_child(rope)

		for i in range(6):
			var w: float = randf_range(0.5, 0.8)
			var hh: float = randf_range(0.6, 0.95)
			var basis := Basis(Vector3.UP, randf_range(-0.15, 0.15)).scaled(Vector3(w, hh, 1.0))
			_batch_cloths.append(Transform3D(basis,
				Vector3(width * 0.05 + i * (width * 0.38 / 6.0), h - hh / 2.0, z)))
			_batch_cloth_colors.append(CLOTH_COLORS[randi() % CLOTH_COLORS.size()])


func _build_edicola_votiva(pos: Vector3) -> void:
	var inward := -1.0

	var niche := MeshInstance3D.new()
	var niche_mesh := BoxMesh.new()
	niche_mesh.size = Vector3(0.4, 1.2, 0.9)
	niche.mesh = niche_mesh
	niche.position = pos + Vector3(inward * 0.3, 2.0, 0)
	var niche_mat := StandardMaterial3D.new()
	niche_mat.albedo_color = Color(0.22, 0.18, 0.16)
	niche.material_override = niche_mat
	add_child(niche)

	var frame := MeshInstance3D.new()
	var frame_mesh := BoxMesh.new()
	frame_mesh.size = Vector3(0.08, 0.75, 0.55)
	frame.mesh = frame_mesh
	frame.position = pos + Vector3(inward * 0.55, 2.1, 0)
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.86, 0.7, 0.24)
	frame_mat.metallic = 0.9
	frame_mat.roughness = 0.22
	frame_mat.emission_enabled = true
	frame_mat.emission = Color(0.9, 0.72, 0.28)
	frame_mat.emission_energy_multiplier = 0.4
	frame.material_override = frame_mat
	add_child(frame)

	for dz in [-0.3, 0.3]:
		var candle := MeshInstance3D.new()
		var candle_mesh := CylinderMesh.new()
		candle_mesh.top_radius = 0.055
		candle_mesh.bottom_radius = 0.055
		candle_mesh.height = 0.16
		candle.mesh = candle_mesh
		candle.position = pos + Vector3(inward * 0.5, 1.52, dz)
		var candle_mat := StandardMaterial3D.new()
		candle_mat.albedo_color = Color(0.85, 0.15, 0.12)
		candle_mat.emission_enabled = true
		candle_mat.emission = Color(1.0, 0.35, 0.15)
		candle_mat.emission_energy_multiplier = 2.2
		candle.material_override = candle_mat
		add_child(candle)

	var glow := OmniLight3D.new()
	glow.position = pos + Vector3(inward * 0.8, 1.9, 0)
	glow.light_color = Color(1.0, 0.5, 0.25)
	glow.light_energy = 1.0
	glow.omni_range = 4.0
	add_child(glow)


## Le decorazioni comprate al Bazar compaiono dove le ha appoggiate il
## giocatore, una per ogni copia che possiede.
func _build_decorations() -> void:
	for i in range(GameManager.placed_decor.size()):
		_costruisci_istanza(i)
	# Metodo nominato, non lambda: vedi la nota in player_fps.gd
	GameManager.decor_placed.connect(_on_decor_placed)
	GameManager.decor_rimosso.connect(_on_decor_rimosso)
	GameManager.reinforcements_called.connect(_on_reinforcements_called)


func _on_decor_placed(indice: int, _id: String, _pos: Vector3,
		_rot: float) -> void:
	_costruisci_istanza(indice)


## Tolta una copia dalla piazza. Gli indici di quelle dopo scalano di uno,
## quindi non basta cancellare un nodo: si rifa' tutto il salotto. Sono sei
## oggetti, costa niente, ed e' l'unico modo che non lasci nodi con
## l'indice sbagliato attaccato al nome.
func _on_decor_rimosso(_indice: int, _id: String) -> void:
	for c in get_children():
		if str(c.name).begins_with("decor_"):
			c.name = str(c.name) + "_vecchio"
			c.queue_free()
	GameManager.svuota_decoro()
	for i in range(GameManager.placed_decor.size()):
		_costruisci_istanza(i)


## Dove finisce un pezzo di decorazione: dentro l'holder se ne stiamo
## costruendo uno, altrimenti direttamente nella zona.
func _decor_add(node: Node) -> void:
	if _decor_holder != null and is_instance_valid(_decor_holder):
		_decor_holder.add_child(node)
	else:
		add_child(node)


## **Il punto e' in coordinate del mondo, e va scritto come tale.**
##
## Qui stava il bug piu' fastidioso del Bazar: `holder.position = p` con `p`
## preso dal fantasma, che e' una posizione GLOBALE. Ma l'holder e' figlio
## della piazza, e la piazza sta a (14, 0, 6): ogni cosa che appoggiavi
## atterrava quattordici metri a levante e sei a mezzogiorno di dove avevi
## cliccato. Adesso si scrive `global_position`, dopo l'`add_child`.
## Quale copia si sta costruendo adesso: lo legge `_decor_usabile` per dare
## al corpo il suo indice, che serve a raccoglierla con [F].
var _indice_corrente: int = -1


func _costruisci_istanza(indice: int) -> void:
	var e: Dictionary = GameManager.decor_istanza(indice)
	if e.is_empty():
		return
	var id: String = str(e.get("id", ""))
	var a = e.get("pos", [0, 0, 0])
	var holder := Node3D.new()
	holder.name = "decor_%s_%d" % [id, indice]
	add_child(holder)
	holder.global_position = Vector3(a[0], a[1], a[2])
	holder.global_rotation.y = float(e.get("rot", 0.0))
	_decor_holder = holder
	_indice_corrente = indice
	_place_decoration_at(id, Vector3.ZERO, true)
	_indice_corrente = -1
	_decor_holder = null


## centered = piazzata a mano dal giocatore: va esattamente dove ha
## cliccato, senza gli scostamenti che servono per l'angolo di default.
func _place_decoration_at(id: String, base: Vector3, centered: bool) -> void:
	match id:
		"sedia":
			_make_sedia(base + (Vector3.ZERO if centered else Vector3(0.4, 0.0, -1.4)))
		"ombrellone":
			_make_ombrellone(base + (Vector3.ZERO if centered else Vector3(1.6, 0.0, -0.2)))
		"tavolino":
			_make_tavolino(base + (Vector3.ZERO if centered else Vector3(0.5, 0.0, 0.9)))
		"radio":
			_make_radio(base + (Vector3(0, 0.62, 0) if centered else Vector3(0.5, 0.62, 0.9)))
		"piante":
			for i in range(3):
				var off := Vector3(-1.0 + i * 1.0, 0.0, 0.0) if centered \
					else Vector3(2.6, 0.0, -2.0 + i * 1.9)
				_make_pianta(base + off)
		"luminarie":
			_make_luminarie()


# ---------------------------------------------------------------------------
# 'E mobili: prima il modello vero, e solo se manca le scatole
# ---------------------------------------------------------------------------
#
# Le sei decorazioni erano scritte a mano qui dentro, a scatole e cilindri:
# la sdraio erano sei parallelepipedi, l'ombrellone un palo con otto prismi
# in cerchio, la radio un cubo con due dischetti. Da lontano passavano; da
# vicino no — e il salotto sta in mezzo alla piazza tua, ci passi accanto
# tutto il turno.
#
# Adesso ognuna ha il suo modello in `assets/models/`, fatto in Blender.
# La geometria procedurale **resta**: se il file manca (o se un domani si
# cambia il pacchetto dei modelli) la piazza si costruisce lo stesso, e
# nessuno si trova il salotto vuoto. È la stessa regola che vale per le
# auto da quando esiste `models.gd`.
func _decor_modello(nome: String, pos: Vector3, altezza: float = 0.0,
		giro: float = 0.0) -> bool:
	var n := Models.spawn(nome, altezza)
	if n == null:
		return false
	n.position = pos
	if giro != 0.0:
		n.rotation.y = giro
	_decor_add(n)
	return true


## Il corpo invisibile con cui si usa un mobile: si aggancia con lo sguardo,
## si preme [E]. Va dentro l'holder come tutto il resto, così se il
## giocatore sposta la decorazione si sposta pure lui.
func _decor_usabile(id: String, pos: Vector3, altezza: float, raggio: float) -> void:
	var corpo := UsoDecoro.new()
	corpo.position = pos
	_decor_add(corpo)
	corpo.setup(id, altezza, raggio, _indice_corrente)
	GameManager.registra_decoro(id, corpo)


func _make_sedia(pos: Vector3) -> void:
	_decor_usabile("sedia", pos, 1.2, 0.7)
	if _decor_modello("sedia", pos, 0.90):
		return
	var stripe := StandardMaterial3D.new()
	stripe.albedo_color = Color(0.2, 0.5, 0.8)
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.75, 0.65, 0.45)

	var seat := MeshInstance3D.new()
	var seat_mesh := BoxMesh.new()
	seat_mesh.size = Vector3(0.7, 0.07, 0.85)
	seat.mesh = seat_mesh
	seat.position = pos + Vector3(0, 0.42, 0)
	seat.material_override = stripe
	_decor_add(seat)

	var back := MeshInstance3D.new()
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(0.7, 0.8, 0.07)
	back.mesh = back_mesh
	back.position = pos + Vector3(0, 0.72, 0.45)
	back.rotation.x = deg_to_rad(-28)
	back.material_override = stripe
	_decor_add(back)

	for sx in [-0.32, 0.32]:
		for sz in [-0.36, 0.36]:
			var leg := MeshInstance3D.new()
			var leg_mesh := BoxMesh.new()
			leg_mesh.size = Vector3(0.06, 0.42, 0.06)
			leg.mesh = leg_mesh
			leg.position = pos + Vector3(sx, 0.21, sz)
			leg.material_override = frame_mat
			_decor_add(leg)


## L'ombrellone ha una cosa in piu' degli altri: **il punto dell'ombra**.
## Va segnato comunque, modello o no — se no comprare l'ombrellone smette
## di nascondere dal vigile, che e' tutto quello che fa.
func _ombrellone_segno(pos: Vector3) -> void:
	var segno := Node3D.new()
	segno.name = "punto_ombrellone"
	segno.position = pos
	_decor_add(segno)
	GameManager.registra_decoro("ombrellone", segno)


func _make_ombrellone(pos: Vector3) -> void:
	if Models.spawn("ombrellone") != null:
		_ombrellone_segno(pos)
		# Il corpo serve a due cose: agganciarlo con lo sguardo per
		# raccoglierlo, e dare all'ombrellone un ingombro vero invece di
		# lasciarci camminare dentro.
		_decor_usabile("ombrellone", pos, 2.3, 0.30)
		_decor_modello("ombrellone", pos, 2.35)
		return
	# Niente corpo da premere: l'ombrellone non si usa, si sta sotto. Ma
	# serve sapere DOVE sta, e lo si segna con un nodo vuoto che segue
	# l'holder — se il giocatore lo sposta, l'ombra si sposta con lui.
	var segno := Node3D.new()
	segno.name = "punto_ombrellone"
	segno.position = pos
	_decor_add(segno)
	GameManager.registra_decoro("ombrellone", segno)

	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.045
	pole_mesh.bottom_radius = 0.045
	pole_mesh.height = 2.3
	pole.mesh = pole_mesh
	pole.position = pos + Vector3(0, 1.15, 0)
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.7, 0.6, 0.42)
	pole.material_override = pole_mat
	_decor_add(pole)

	var colors := [Color(0.9, 0.3, 0.25), Color(0.97, 0.95, 0.9)]
	for i in range(8):
		var slice := MeshInstance3D.new()
		var slice_mesh := PrismMesh.new()
		slice_mesh.size = Vector3(1.1, 0.45, 1.1)
		slice.mesh = slice_mesh
		slice.position = pos + Vector3(0, 2.2, 0)
		slice.rotation.y = TAU * i / 8.0
		var slice_mat := StandardMaterial3D.new()
		slice_mat.albedo_color = colors[i % 2]
		slice_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		slice.material_override = slice_mat
		_decor_add(slice)


func _make_tavolino(pos: Vector3) -> void:
	_decor_usabile("tavolino", pos, 0.9, 0.6)
	if _decor_modello("tavolino", pos, 0.78):
		return
	var top := MeshInstance3D.new()
	var top_mesh := CylinderMesh.new()
	top_mesh.top_radius = 0.42
	top_mesh.bottom_radius = 0.42
	top_mesh.height = 0.06
	top.mesh = top_mesh
	top.position = pos + Vector3(0, 0.6, 0)
	var top_mat := StandardMaterial3D.new()
	top_mat.albedo_color = Color(0.85, 0.83, 0.78)
	top.material_override = top_mat
	_decor_add(top)

	var leg := MeshInstance3D.new()
	var leg_mesh := CylinderMesh.new()
	leg_mesh.top_radius = 0.05
	leg_mesh.bottom_radius = 0.16
	leg_mesh.height = 0.6
	leg.mesh = leg_mesh
	leg.position = pos + Vector3(0, 0.3, 0)
	var leg_mat := StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.2, 0.2, 0.22)
	leg_mat.metallic = 0.5
	leg.material_override = leg_mat
	_decor_add(leg)


func _make_radio(pos: Vector3) -> void:
	# La radio adesso si usa: le serve il corpo con cui agganciarla.
	_decor_usabile("radio", pos, 0.40, 0.42)
	if _decor_modello("radio", pos, 0.40):
		return
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.4, 0.22, 0.16)
	body.mesh = body_mesh
	body.position = pos
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.35, 0.22, 0.12)
	body.material_override = body_mat
	_decor_add(body)

	var speaker := MeshInstance3D.new()
	var sp_mesh := CylinderMesh.new()
	sp_mesh.top_radius = 0.07
	sp_mesh.bottom_radius = 0.07
	sp_mesh.height = 0.02
	speaker.mesh = sp_mesh
	speaker.rotation.x = deg_to_rad(90)
	speaker.position = pos + Vector3(-0.09, 0, -0.09)
	var sp_mat := StandardMaterial3D.new()
	sp_mat.albedo_color = Color(0.12, 0.12, 0.12)
	speaker.material_override = sp_mat
	_decor_add(speaker)

	var antenna := MeshInstance3D.new()
	var ant_mesh := CylinderMesh.new()
	ant_mesh.top_radius = 0.008
	ant_mesh.bottom_radius = 0.012
	ant_mesh.height = 0.5
	antenna.mesh = ant_mesh
	antenna.position = pos + Vector3(0.16, 0.34, 0)
	antenna.rotation.z = deg_to_rad(-18)
	var ant_mat := StandardMaterial3D.new()
	ant_mat.albedo_color = Color(0.7, 0.7, 0.72)
	ant_mat.metallic = 0.9
	antenna.material_override = ant_mat
	_decor_add(antenna)


func _make_pianta(pos: Vector3) -> void:
	if _decor_modello("pianta", pos, 0.78, randf_range(-PI, PI)):
		_decor_usabile("piante", pos, 0.8, 0.30)
		return
	var pot := MeshInstance3D.new()
	var pot_mesh := CylinderMesh.new()
	pot_mesh.top_radius = 0.26
	pot_mesh.bottom_radius = 0.2
	pot_mesh.height = 0.42
	pot.mesh = pot_mesh
	pot.position = pos + Vector3(0, 0.21, 0)
	var pot_mat := StandardMaterial3D.new()
	pot_mat.albedo_color = Color(0.66, 0.35, 0.22)
	pot.material_override = pot_mat
	_decor_add(pot)

	var green := StandardMaterial3D.new()
	green.albedo_color = Color(0.2, 0.48 + randf() * 0.16, 0.2)
	for i in range(3):
		var leaf := MeshInstance3D.new()
		var leaf_mesh := SphereMesh.new()
		leaf_mesh.radius = 0.3 - i * 0.06
		leaf_mesh.height = leaf_mesh.radius * 2.0
		leaf.mesh = leaf_mesh
		leaf.position = pos + Vector3(randf_range(-0.12, 0.12), 0.58 + i * 0.24, randf_range(-0.12, 0.12))
		leaf.material_override = green
		_decor_add(leaf)


## Luminarie da festa patronale sospese sopra il salotto.
func _make_luminarie() -> void:
	var center := Vector3(width / 2.0, 0.0, length * 0.45)
	# **Tre campate vere invece di quarantotto pallini.**
	#
	# Le vecchie erano quarantotto sferette emissive appese per aria: il
	# cavo non c'era, e una luminaria senza il filo che fa la pancia non e'
	# una luminaria, e' una fila di puntini. Il modello ha il cavo con la
	# sua catenaria, il portalampada e il bulbo.
	if Models.spawn("luminaria") != null:
		for line in range(3):
			var z: float = center.z - 4.0 + line * 4.0
			var l := Models.spawn("luminaria")
			# La campata e' lunga 14 m: si stringe sulla larghezza vera
			# della piazza, che di solito e' meno.
			var largo: float = maxf(6.0, width - 4.0)
			l.scale = Vector3(largo / 14.0, 1.0, 1.0)
			l.position = Vector3(center.x, 6.4, z)
			_decor_add(l)
		return
	var bulb_colors := [
		Color(1.0, 0.85, 0.4), Color(1.0, 0.4, 0.35),
		Color(0.45, 0.85, 1.0), Color(0.6, 1.0, 0.5),
	]
	for line in range(3):
		var z: float = center.z - 4.0 + line * 4.0
		for i in range(16):
			var t: float = i / 15.0
			var x: float = center.x - 7.0 + t * 14.0
			var sag: float = sin(t * PI) * 0.8
			var bulb := MeshInstance3D.new()
			var mesh := SphereMesh.new()
			mesh.radius = 0.1
			mesh.height = 0.2
			bulb.mesh = mesh
			bulb.position = Vector3(x, 6.4 - sag, z)
			var mat := StandardMaterial3D.new()
			var c: Color = bulb_colors[i % bulb_colors.size()]
			mat.albedo_color = c
			mat.emission_enabled = true
			mat.emission = c
			mat.emission_energy_multiplier = 2.4
			bulb.material_override = mat
			_decor_add(bulb)


# ---------------------------------------------------------------------------
# Gameplay: posti, coda, vigili, spawner
# ---------------------------------------------------------------------------

func _build_parking_spots() -> void:
	var start_z: float = length * 0.2
	var spacing := 5.2
	for i in range(spots_right):
		var spot = ParkingSpotScene.new()
		spot.position = Vector3(width - 5.0, 0.13, start_z + i * spacing)
		spot.zona_id = "piazza"
		spot.indice = parking_spots.size()
		add_child(spot)
		parking_spots.append(spot)
	for i in range(spots_left):
		var spot = ParkingSpotScene.new()
		spot.position = Vector3(5.0, 0.13, start_z + 2.6 + i * spacing)
		spot.zona_id = "piazza"
		spot.indice = parking_spots.size()
		add_child(spot)
		parking_spots.append(spot)


func _build_queue_points() -> void:
	queue_points.append(Vector3(width * 0.3, 0.0, length * 0.86))
	queue_points.append(Vector3(width * 0.44, 0.0, length * 0.9))
	queue_points.append(Vector3(width * 0.3, 0.0, length * 0.94))


func _build_vigili() -> void:
	if vigili_count <= 1:
		var vigile = VigileScene.new()
		add_child(vigile)
		vigile.setup([
			_glob(Vector3(6.0, 0.0, 8.0)),
			_glob(Vector3(width - 6.0, 0.0, 8.0)),
			_glob(Vector3(width - 6.0, 0.0, length - 8.0)),
			_glob(Vector3(6.0, 0.0, length - 8.0)),
		])
	else:
		var v1 = VigileScene.new()
		add_child(v1)
		v1.setup([
			_glob(Vector3(6.0, 0.0, 7.0)), _glob(Vector3(width - 6.0, 0.0, 7.0)),
			_glob(Vector3(width - 6.0, 0.0, length * 0.45)),
			_glob(Vector3(6.0, 0.0, length * 0.45)),
		])
		var v2 = VigileScene.new()
		add_child(v2)
		v2.setup([
			_glob(Vector3(width - 6.0, 0.0, length - 7.0)),
			_glob(Vector3(6.0, 0.0, length - 7.0)),
			_glob(Vector3(6.0, 0.0, length * 0.55)),
			_glob(Vector3(width - 6.0, 0.0, length * 0.55)),
		])


func _build_spawner() -> void:
	_spawn_timer = Timer.new()
	# La prima auto arriva quasi subito, poi si va col passo lento.
	_spawn_timer.wait_time = 4.0
	_spawn_timer.one_shot = false
	_spawn_timer.timeout.connect(_on_spawn_timeout)
	add_child(_spawn_timer)
	_spawn_timer.start()
	call_deferred("_spawn_car")

	_cat_timer = Timer.new()
	_cat_timer.wait_time = randf_range(20.0, 40.0)
	_cat_timer.one_shot = false
	_cat_timer.timeout.connect(_spawn_cat)
	add_child(_cat_timer)
	_cat_timer.start()

	# Le signore: passano ogni tanto attraversando la piazza, e sono
	# l'attività secondaria più semplice da incontrare.
	_signora_timer = Timer.new()
	_signora_timer.wait_time = randf_range(10.0, 18.0)
	_signora_timer.one_shot = false
	_signora_timer.timeout.connect(_spawn_signora)
	add_child(_signora_timer)
	_signora_timer.start()

	_motorino_timer = Timer.new()
	_motorino_timer.wait_time = randf_range(30.0, 45.0)
	_motorino_timer.one_shot = false
	_motorino_timer.timeout.connect(_spawn_motorino)
	add_child(_motorino_timer)
	_motorino_timer.start()


func _build_events() -> void:
	_wave_timer = Timer.new()
	_wave_timer.wait_time = randf_range(105.0, 140.0)
	_wave_timer.one_shot = true
	_wave_timer.timeout.connect(_start_match_wave)
	add_child(_wave_timer)
	_wave_timer.start()


## I gabbiani girano in tondo sopra la piazza, con un filo di beccheggio.
func _animate_seagulls(delta: float) -> void:
	if _gulls_root == null:
		return
	_gull_time += delta
	var center := Vector3(width / 2.0, 0.0, length / 2.0)
	var idx := 0
	for gull in _gulls_root.get_children():
		var r: float = gull.get_meta("radius")
		var sp: float = gull.get_meta("speed")
		var ph: float = gull.get_meta("phase")
		var h: float = gull.get_meta("height")
		var flap: float = gull.get_meta("flap")
		var a: float = _gull_time * sp + ph
		gull.position = center + Vector3(cos(a) * r, h + sin(a * 1.7) * 1.6, sin(a) * r)
		# Guarda dove sta andando: la tangente della circonferenza
		var dir := Vector3(-sin(a), 0, cos(a))
		gull.rotation.y = atan2(-dir.x, -dir.z)
		gull.rotation.z = 0.22 # inclinato nella virata

		# Battito d'ali: lento, con lunghe planate (come fanno davvero)
		if idx < _gull_wings.size():
			var raw: float = sin(_gull_time * flap + ph)
			var beat: float = pow(maxf(raw, 0.0), 1.6) - 0.15
			var wings: Array = _gull_wings[idx]
			for w in wings.size():
				var side: float = -1.0 if w == 0 else 1.0
				wings[w].rotation.z = side * beat * 0.55
		idx += 1


## Quante auto DA SERVIRE possono esserci in piazza insieme, in funzione di
## quanto turno è passato. La rampa serve a non travolgere chi comincia.
##
## Attenzione a cosa conta: **le auto già parcheggiate non sono lavoro.**
## Stanno lì ferme, l'autista è sceso, non hanno bisogno di te — sono
## arredamento. Per un pezzo invece occupavano uno slot del tetto per i
## 38-55 secondi della sosta, e siccome il tetto nei primi minuti è 2 o 3,
## bastavano due auto parcheggiate per chiudere il rubinetto: si misuravano
## buchi di venti secondi buoni in cui non arrivava niente e non c'era
## niente da fare. Adesso si contano solo quelle che ti riguardano —
## in arrivo, in attesa, sotto la tua regia.
func _auto_da_servire() -> int:
	var n := 0
	for c in get_tree().get_nodes_in_group("cars"):
		# **Sulo chelle 'e casa** (0.61). Contava le auto di tutta la
		# città: con tre macchine in coda allo stadio, la piazza di casa
		# credeva di essere piena e non ne faceva arrivare più nessuna.
		if str(c.get("zona_id")) != "piazza":
			continue
		# 0 ARRIVING, 1 WAITING, 2 DIRECTING: queste vogliono te.
		if c.state <= 2:
			n += 1
	return n


## Tutte le auto della piazza di casa, parcheggiate comprese.
func _auto_d_a_piazza() -> int:
	var n := 0
	for c in get_tree().get_nodes_in_group("cars"):
		if str(c.get("zona_id")) == "piazza":
			n += 1
	return n


func _effective_max_cars() -> int:
	# La rampa iniziale non serve piu': adesso fra un'auto e l'altra
	# passano trenta secondi, quindi il tetto non lo tocca quasi mai
	# nessuno. Resta solo come freno per il caso in cui il giocatore si
	# perda in giro per il quartiere e la piazza gli si riempia.
	return max_cars


## Tetto assoluto di auto presenti, parcheggiate comprese. Non è ritmo di
## gioco, è la protezione contro il caso limite in cui uno parcheggia tutto
## e la piazza si riempie di lamiera finché il gioco non arranca.
func _tetto_assoluto() -> int:
	return max_cars + 6


func _start_match_wave() -> void:
	if _wave_fired:
		return
	_wave_fired = true
	GameManager.avvisa_strada("PARTITA ALLO STADIO! Stanno arrivando TUTTI!")
	# Il boato vero. E' l'unico momento in cui la citta' si sente tutta
	# insieme, e finora era annunciato solo da una scritta.
	SoundManager.play("folla", -2.0)
	SoundManager.play("honk", -2.0, 0.9)
	# Le auto extra arrivano scaglionate: gestite da un contatore in
	# _physics_process, non da timer con closure (che crasherebbero se la
	# scena venisse ricaricata nel frattempo).
	_wave_pending = 3
	_wave_next = 5.0




## Se hai messo un guaglione anche nella piazza di casa, le auto le smaltisce
## lui mentre tu stai in giro. E' il caso piu' utile di tutti: e' quello che
## ti permette di andartene a comprare una piazza nuova senza che quella che
## hai gia' si fermi.
## **'O rubinetto s'e' asciuto.**
##
## Qui ci stava la stessa cosa che stava in `posteggio_3d.gd`: un timer che
## dichiarava parcheggiata un'auto ferma in coda, senza spostarla e senza
## che il guaglione facesse un passo. Adesso ci sale davvero — vedi
## `guaglione_3d.gd` e `car_3d.gd::guagliuno_sale`. Resta la funzione
## vuota perche' la chiama `_physics_process`, e una riga tolta in due
## posti e' una riga che si dimentica in uno dei due.
func _guaglione_lavora(_delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	_animate_seagulls(delta)
	_check_boss()
	_guaglione_lavora(delta)

	if _wave_pending > 0:
		_wave_next -= delta
		if _wave_next <= 0.0:
			_wave_pending -= 1
			_wave_next = 7.0
			SoundManager.play("honk", -4.0, randf_range(0.85, 1.2))
			if _auto_d_a_piazza() < _tetto_assoluto():
				_spawn_car()


## Il boss di fine turno. Arriva quando mancano BOSS_APPEARS_AT secondi e
## non se ne va più finché non lo convinci (o finché non scade il tempo).
## Chiamato quando il vigile alza la radio e dice "duttò, sta n'ata vota
## ccà": Borrelli parte adesso, non a notte fonda.
func _borrelli_subito() -> void:
	if GameManager.boss_spawned or not GameManager.shift_active:
		return
	_boss_fra = 6.0
	GameManager.boss_warned = true


func _check_boss() -> void:
	if GameManager.boss_spawned or not GameManager.shift_active:
		return
	if _boss_fra < 0.0:
		return # la notte non e' ancora calata
	_boss_fra -= get_physics_process_delta_time()
	# Il preavviso: dodici secondi prima si sente che sta arrivando qualcuno.
	if not GameManager.boss_warned and _boss_fra <= 12.0:
		GameManager.boss_warned = true
		GameManager.event_started.emit(
			"Qualcuno t'ha fatto 'a spia... sta salenno p''a piazza")
		SoundManager.play("fail", -6.0, 0.6)
	if _boss_fra > 0.0:
		return
	GameManager.boss_spawned = true
	var boss = BorrelliScene.new()
	add_child(boss)
	boss.setup(_nasce_borrelli(), _glob(exit_point))


## **Addò compare** (0.63). Fino alla 0.62 nasceva sempre all'ingresso
## della piazza di casa: se lo chiamava il vigile del mercato, o se la
## notte ti trovava al Vomero, se ne stava un minuto buono a camminare per
## mezza città prima di vederti — e l'annuncio a schermo arrivava molto
## prima di lui. Adesso nasce a venti-trenta metri da te, in un punto che
## sta in strada e da cui si arriva a piedi. Se sei a casa, aspetta
## all'ingresso della piazza come prima.
const CammVia := preload("res://scripts/cammino.gd")


func _nasce_borrelli() -> Vector3:
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	if pl == null or GameManager.dentro_casa:
		return _glob(entry_point)
	var c: Vector3 = pl.global_position
	var giro0: float = randf() * TAU
	for r in [24.0, 20.0, 30.0, 16.0]:
		for k in range(12):
			var a: float = giro0 + float(k) * TAU / 12.0
			var q := Vector3(c.x + cos(a) * r, 0.0, c.z + sin(a) * r)
			if q.x < 1.0 or q.x > 189.0 or q.z < 1.0 or q.z > 171.0:
				continue
			if not CammVia.libera(q) or not CammVia.raggiungibile(q):
				continue
			q.y = Collina.alzata(q.x, q.z)
			return q
	return _glob(entry_point)


## È calata la notte: da adesso il conto alla rovescia per Borrelli.
func _on_notte_calata() -> void:
	# **Borrelli è il boss d''a primma jurnata, e ci arriva sempre.**
	#
	# Prima veniva a caso, e capitava di finire la partita senza averlo mai
	# incontrato: il pezzo scritto meglio del gioco poteva non succedere.
	# Adesso la prima sera c'è per forza, e le sere dopo torna quando c'è
	# un motivo — vedi `boss_stasera()`.
	# **E primma 'e tutto: 'o boss 'e capitolo (0.55).** Se ti sei preso
	# una piazza, stasera arriva chi la proteggeva — e non nella tua
	# piazza: **nella sua**. Vedi `GameManager.boss_capitolo_stasera()`.
	var zona_boss: String = GameManager.boss_capitolo_stasera()
	if zona_boss != "":
		GameManager.boss_capitolo_arriva.emit(zona_boss)

	if not GameManager.boss_stasera():
		_boss_fra = -1.0
		GameManager.avvisa_strada(
			"S'è fatta notte. 'A piazza cagna faccia.")
		SoundManager.play("pop", -8.0, 0.5)
		return
	_boss_fra = randf_range(GameManager.BOSS_DOPO_NOTTE_MIN,
		GameManager.BOSS_DOPO_NOTTE_MAX)
	GameManager.avvisa_strada("S'è fatta notte. 'A piazza cagna faccia.")
	SoundManager.play("pop", -8.0, 0.5)


## Una signora che attraversa la piazza. Cammina da un bordo all'altro
## passando per il centro, così ti capita davanti mentre lavori.
## Il campetto in un angolo: porta contro il muro di fondo, cassette come
## pali, e il pallone al centro dell'area.
func _build_campetto() -> void:
	# Contro i palazzi bassi del fondo, al centro: è l'unica fetta di piazza
	# larga e senza strisce, e ci si arriva camminando dritti dallo start.
	var gx: float = width * 0.5
	var gz: float = 3.2
	var goal_w: float = 3.6
	var goal_h: float = 2.1
	var post_mat := Tex.flat(Color(0.9, 0.89, 0.85), 0.85)
	var net_mat := Tex.flat(Color(0.8, 0.81, 0.83, 0.3), 0.9)
	net_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	net_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	# I pali: cassette della frutta impilate, come si è sempre fatto
	for sx in [-1.0, 1.0]:
		for k in range(3):
			var crate := MeshInstance3D.new()
			var cm := BoxMesh.new()
			cm.size = Vector3(0.42, 0.3, 0.42)
			crate.mesh = cm
			crate.position = Vector3(gx + sx * goal_w * 0.5, 0.27 + k * 0.32, gz)
			crate.rotation.y = randf_range(-0.14, 0.14)
			crate.material_override = Tex.flat(
				Color(0.72, 0.5, 0.25) if k % 2 == 0 else Color(0.3, 0.48, 0.7), 0.9)
			add_child(crate)

	# Pali veri sopra le cassette: senza, contro un muro chiaro la porta non
	# si distingueva e non si capiva dove tirare.
	for sx in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.11, goal_h - 0.9, 0.11)
		post.mesh = pm
		post.position = Vector3(gx + sx * goal_w * 0.5, 0.9 + (goal_h - 0.9) * 0.5, gz)
		post.material_override = post_mat
		add_child(post)

	# Traversa
	var bar := MeshInstance3D.new()
	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(goal_w + 0.35, 0.12, 0.12)
	bar.mesh = bar_mesh
	bar.position = Vector3(gx, goal_h, gz)
	bar.material_override = post_mat
	add_child(bar)

	# La rete: un reticolo di funi scure invece di un pannello trasparente
	# (che contro l'intonaco chiaro spariva del tutto).
	var rope := Tex.flat(Color(0.16, 0.18, 0.16), 0.95)
	for i in range(11):
		var v := MeshInstance3D.new()
		var vm := BoxMesh.new()
		vm.size = Vector3(0.025, goal_h, 0.025)
		v.mesh = vm
		v.position = Vector3(gx - goal_w * 0.5 + i * (goal_w / 10.0),
			goal_h * 0.5, gz - 0.5)
		v.material_override = rope
		add_child(v)
	for k in range(6):
		var h := MeshInstance3D.new()
		var hm := BoxMesh.new()
		hm.size = Vector3(goal_w, 0.025, 0.025)
		h.mesh = hm
		h.position = Vector3(gx, 0.12 + k * (goal_h / 6.0), gz - 0.5)
		h.material_override = rope
		add_child(h)

	# Fondo della rete, inclinato all'indietro
	var back_net := MeshInstance3D.new()
	var bnm := BoxMesh.new()
	bnm.size = Vector3(goal_w, 0.03, 1.0)
	back_net.mesh = bnm
	back_net.position = Vector3(gx, goal_h * 0.62, gz - 1.0)
	back_net.rotation.x = deg_to_rad(28)
	back_net.material_override = net_mat
	add_child(back_net)

	# Righe di gesso: l'area disegnata a mano
	var chalk := Tex.flat(Color(0.93, 0.92, 0.87), 0.95)
	for line in [
			[Vector3(gx, 0.02, gz + 4.2), Vector3(goal_w + 2.6, 0.01, 0.09)],
			[Vector3(gx - goal_w * 0.5 - 1.3, 0.02, gz + 2.1), Vector3(0.09, 0.01, 4.2)],
			[Vector3(gx + goal_w * 0.5 + 1.3, 0.02, gz + 2.1), Vector3(0.09, 0.01, 4.2)]]:
		var mark := MeshInstance3D.new()
		var mm := BoxMesh.new()
		mm.size = line[1]
		mark.mesh = mm
		mark.position = line[0]
		mark.material_override = chalk
		add_child(mark)

	# Dischetto del rigore
	var spot := MeshInstance3D.new()
	var spot_mesh := CylinderMesh.new()
	spot_mesh.top_radius = 0.14
	spot_mesh.bottom_radius = 0.14
	spot_mesh.height = 0.01
	spot.mesh = spot_mesh
	spot.position = Vector3(gx, 0.02, gz + 5.6)
	spot.material_override = chalk
	add_child(spot)

	# **'O pallone e 'a porta stevano dint'a 'nu quartiere 'e n'ato paese.**
	#
	# Qui dentro tutto è scritto in coordinate della piazza: i pali, il
	# gesso, il dischetto, tutto quanto — e va bene, perché sono `position`
	# di figli, e ci pensa Godot a metterli al posto giusto.
	#
	# `Pallone3D.setup()` invece scrive `global_position`, e `goal_center`
	# lo confronta con la posizione globale del pallone. Passandogli gx e
	# gz così com'erano, la porta finiva **alle coordinate della piazza
	# lette come coordinate del mondo**: la piazza sta a (16, 5), quindi la
	# linea di porta stava diciassette metri più in qua e due più in su di
	# dove sta disegnata. Il pallone nasceva da un'altra parte ancora.
	#
	# Ecco perché «è difficile segnare»: la porta che vedevi non era la
	# porta che contava. Non era la fisica — **era 'a mappa**.
	var ball = PalloneScene.new()
	add_child(ball)
	ball.goal_width = goal_w
	ball.goal_height = goal_h
	ball.setup(_glob(Vector3(gx, 0.0, gz + 5.6)), _glob(Vector3(gx, 0.0, gz)))


## Il vigile ha chiamato: entra la pattuglia dal fondo della piazza.
## Metodo nominato, non lambda: il segnale sta su un autoload.
func _on_reinforcements_called() -> void:
	if not get_tree().get_nodes_in_group("carabinieri").is_empty():
		return
	var pattuglia = CarabinieriScene.new()
	add_child(pattuglia)
	pattuglia.setup(_glob(entry_point + Vector3(0, 0, 3.0)))


func _spawn_signora() -> void:
	_signora_timer.wait_time = randf_range(14.0, 24.0)
	if get_tree().get_nodes_in_group("signore").size() >= 2:
		return
	var s = SignoraScene.new()
	add_child(s)
	# Metà delle volte attraversa in larghezza, metà in lunghezza.
	var from_pos: Vector3
	var to_pos: Vector3
	if randf() < 0.5:
		var z: float = randf_range(length * 0.25, length * 0.8)
		from_pos = Vector3(-2.0, 0.0, z)
		to_pos = Vector3(width + 2.0, 0.0, z + randf_range(-6.0, 6.0))
	else:
		var x: float = randf_range(width * 0.2, width * 0.8)
		from_pos = Vector3(x, 0.0, length + 2.0)
		to_pos = Vector3(x + randf_range(-6.0, 6.0), 0.0, -2.0)
	if dentro_citta:
		# Dentro alla citta' la piazza ha due sole aperture: il belvedere a
		# nord e il varco delle auto a sud. Farle attraversare da un lato
		# all'altro voleva dire farle passare attraverso i palazzi — e da
		# fuori si vedevano camminare dentro al muro.
		var belv := Vector3(width * 0.52, 0.0, -1.5)
		var varco := Vector3(entry_point.x, 0.0, length + 1.5)
		from_pos = belv
		to_pos = varco
		if randf() < 0.5:
			from_pos = varco
			to_pos = belv
	elif randf() < 0.5:
		var tmp := from_pos
		from_pos = to_pos
		to_pos = tmp
	s.setup(_glob(from_pos), _glob(to_pos))


func _spawn_cat() -> void:
	_cat_timer.wait_time = randf_range(25.0, 50.0)
	var cat = CatScene.new()
	add_child(cat)
	cat.setup(width, randf_range(length * 0.15, length * 0.9), _glob(Vector3.ZERO))


## Il motorino punta la corsia in cui si trova il player: deve passarti
## addosso, non dall'altra parte della piazza.
func _spawn_motorino() -> void:
	_motorino_timer.wait_time = randf_range(30.0, 45.0)
	var lane_z: float = length * 0.5
	var player := get_tree().get_first_node_in_group("player")
	if player:
		# La corsia e' un numero locale: la z del player e' del mondo.
		var locale: Vector3 = global_transform.affine_inverse() * player.global_position
		lane_z = clampf(locale.z + randf_range(-0.6, 0.6), 4.0, length - 4.0)
	var m = MotorinoScene.new()
	add_child(m)
	m.setup(width, lane_z, randf() < 0.5, _glob(Vector3.ZERO))


func _on_spawn_timeout() -> void:
	# Si riavvia il timer col tempo nuovo invece di limitarsi a scrivere
	# `wait_time`: un Timer ciclico riparte da solo col valore che aveva
	# PRIMA, e il primo giro dopo il cambio usciva sempre corto.
	# **La piazza curata rende.** Ogni pezzo di decoro appoggiato accorcia
	# del quattro per cento l'attesa fra un'auto e l'altra, e le luminarie
	# di notte la accorciano di un altro terzo: sei pezzi in una piazza
	# illuminata vogliono dire quasi il doppio del lavoro. Non e' un premio
	# simbolico — e' il motivo per cui centosettantuno euro di mobili si
	# ripagano in una serata.
	# **E poi c'e' che ora e'.** Il decoro cambia l'attesa del quaranta per
	# cento al massimo; l'ora la cambia di tre volte, dalle tre del
	# pomeriggio (morte) alle dieci di sera (i ristoranti si svuotano).
	# I due si moltiplicano: una piazza curata alle dieci di sera lavora
	# come tre piazze spoglie alle tre.
	# E sopra all'ora c'e' il giorno (0.52): un mercato triplica gli
	# arrivi rispetto a una processione, e i tre numeri si moltiplicano.
	_spawn_timer.wait_time = randf_range(spawn_min, spawn_max) \
		* GameManager.attesa_auto() * GameManager.attesa_ora_e_juorno()
	_spawn_timer.start()
	# **'E quatto d''a matina: nun vene cchiu' nisciuno.**
	#
	# Il cronometro a zero non chiude piu' la giornata di colpo (adesso la
	# chiude il letto), ma il quartiere si spegne lo stesso: da qui in poi
	# non arrivano macchine. Serve a due cose — che l'ultima ora non sia
	# tempo perso a guardare una piazza vuota **sperando** in un cliente, e
	# che tornare a casa sia una decisione facile invece di un sacrificio.
	if GameManager.giornata_scaduta:
		return
	# **Il rubinetto si chiude quando esci dalla piazza.**
	#
	# Non è solo per non disturbare: se le auto continuassero ad arrivare
	# mentre tu stai dall'altra parte della città, al ritorno trovavi la
	# piazza piena di clienti già arrabbiati e il gioco ti puniva per essere
	# andato a fare un giro. Adesso il lavoro sta fermo ad aspettarti.
	#
	# Una sola auto in attesa resta: serve a far vedere, quando rientri, che
	# la piazza è viva senza doverne aspettare l'arrivo.
	# **Tranne si ce sta 'o guaglione** (0.61). Era la stessa regola di
	# `posteggio_3d.gd`, ma l'eccezione ci stava solo là: nella piazza di
	# casa, col guaglione assunto e tu in giro, arrivava una macchina sola
	# e il guaglione passava la giornata ad aspettare la prossima.
	if not GameManager.in_servizio and _auto_da_servire() >= 1 \
			and not GameManager.ha_dipendente("piazza"):
		return
	if _auto_d_a_piazza() >= _tetto_assoluto():
		return
	if _auto_da_servire() < _effective_max_cars():
		_spawn_car()


## **Trasi e 'a machina arriva** (0.64): la stessa regola delle piazze
## conquistate (`posteggio_3d._su_servizio`). Se torni in piazza e non c'è
## nessuno da servire, il primo cliente arriva fra due e quattro secondi.
func _su_servizio(attivo: bool, _nome: String) -> void:
	if not attivo or GameManager.zona_corrente != "piazza":
		return
	if not GameManager.shift_active or GameManager.giornata_scaduta:
		return
	if _spawn_timer == null or _auto_da_servire() > 0:
		return
	if _spawn_timer.time_left > 4.0:
		_spawn_timer.start(randf_range(2.0, 4.0))


func _spawn_car() -> Node:
	var car = CarScene.new()
	# Questa e' la piazza dove sta il salotto: i clienti che arrivano qui
	# vedono le piante, sentono la radio e di notte trovano le luminarie.
	# Quelli delle altre piazze no — li' non c'e' niente da vedere.
	car.piazza_curata = true
	var queue_point: Vector3 = _punto_coda_libero()
	if queue_point == Vector3.INF:
		# Nessun punto buono: la coda è piena, o chi aspetta fuori tappa
		# la strada a chi dovrebbe andare dentro. Si riprova al giro dopo.
		car.free()
		return null
	add_child(car)
	car.setup(_glob(entry_point), queue_point, _glob(exit_point),
		percorso_ingresso(), percorso_uscita())
	return car


## **'A coda nun se tappa** (0.64). I tre punti d'attesa stavano due sulla
## stessa riga dell'ingresso, a quattro metri e mezzo l'uno dall'altro:
## una macchina ferma su quello di fuori chiudeva la strada a quella che
## doveva andare su quello di dentro, che si incastrava e dopo sette secondi
## se ne andava (con la sfida del Rre, a macchine veloci, se ne perdevano
## cinque al minuto). Adesso si sceglie un punto che nessuno sta già
## occupando e la cui strada dall'ingresso non passa addosso a chi aspetta;
## prima quelli di dentro, così quelli di fuori si riempiono per ultimi.
## `Vector3.INF` se non ce n'è.
func _punto_coda_libero() -> Vector3:
	var porta: Array = percorso_ingresso()
	var da: Vector3 = porta[porta.size() - 1] if not porta.is_empty() else _glob(entry_point)
	var punti: Array = []
	for q in queue_points:
		punti.append(_glob(q))
	punti.sort_custom(func(a, b): return a.distance_to(da) > b.distance_to(da))
	var ferme: Array = []
	var mete: Array = []
	for c in get_tree().get_nodes_in_group("cars"):
		if not is_instance_valid(c) or str(c.get("zona_id")) != "piazza":
			continue
		var st: int = int(c.get("state"))
		if st > 1:
			continue
		var w = c.get("waiting_point")
		if w is Vector3:
			mete.append(w)
		if st == 1:
			ferme.append((c as Node3D).global_position)
	for p in punti:
		var preso := false
		for m in mete:
			if Vector2((m as Vector3).x, (m as Vector3).z).distance_to(Vector2(p.x, p.z)) < 1.0:
				preso = true
				break
		if preso:
			continue
		var tappato := false
		for f in ferme:
			if _distanza_segmento(f, da, p) < 2.7:
				tappato = true
				break
		if not tappato:
			return p
	return Vector3.INF


static func _distanza_segmento(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := Vector2(b.x - a.x, b.z - a.z)
	var ap := Vector2(p.x - a.x, p.z - a.z)
	var l2: float = ab.length_squared()
	var t: float = 0.0 if l2 < 0.0001 else clampf(ap.dot(ab) / l2, 0.0, 1.0)
	return (ap - ab * t).length()


## Vero se stiamo girando su Forward+ (Vulkan). In GL Compatibility — cioè
## nel browser e sui telefoni — il RenderingDevice non esiste, ed è il modo
## ufficiale per accorgersene senza leggere le impostazioni di progetto (che
## dicono cosa è stato *chiesto*, non cosa è partito davvero: se la scheda
## non regge Vulkan, Godot ripiega su OpenGL da solo).
static func _is_forward_plus() -> bool:
	return RenderingServer.get_rendering_device() != null


# ---------------------------------------------------------------------------
# 'A ROBBA 'E STRADA (0.58)
# ---------------------------------------------------------------------------
#
# Il capo ha dato un pacchetto di modelli PSX e ha chiesto di usarli «per
# arricchire il gioco in generale». Questo è il posto dove si vede di più:
# **il vicolo era pulito.** Quattro lampioni, un cassonetto, due Vespe, una
# fontana, due panchine e due cestini — e poi asfalto, per cinquantaquattro
# metri. Un vicolo di Napoli non è pulito: è pieno di roba di qualcun altro.
#
# **Addò se mette, e pecché propeto llà.** Questa è la parte che conta, e
# non è estetica: è l'unica scelta che poteva rompere il gioco.
#
#   * **Nun 'n miezo â strada.** La corsia centrale è un invariante di questo
#     progetto da venti versioni: ci passano le auto in arrivo, ci fai la
#     regia a gesti, e alla 0.56 l'armiere piantato a x=142 — il centro
#     esatto di un vicolo da quattro metri — è costato una build.
#   * **E manco attaccato ô muro.** Sul marciapiede, contro le facciate, ci
#     stanno i portoni e le vetrine, e ogni vetrina ha un punto di sosta
#     dove l'autista va a fare la spesa (0.55). Un bidone davanti a un
#     portone è un autista che ci sbatte dentro per tutto il turno.
#
# Resta **il filo del marciapiede**, x fra 2,1 e 2,9 (e lo specchio
# dall'altra parte): fuori dalla corsia, fuori dai portoni. Che poi è dove
# la roba sta davvero — contro il bordo, non contro il muro.
#
# E **'a semmenta è ferma**: stesso vicolo, stessa munnezza tutte 'e vvote.
# Una piazza che si rimescola a ogni caricamento non te la ricordi, e
# ricordarsi dov'è il cassonetto è mezzo mestiere.

## 'A robba pesante, chella ca se ne sta 'nterra e nun se move.
const ROBBA_NTERRA := [
	["cascia_legno", Vector3(0.75, 0.40, 0.55)],
	["cascia_legno2", Vector3(1.12, 1.10, 1.10)],
	["cascia_legno3", Vector3(1.10, 1.10, 1.10)],
	["cascia_legno6", Vector3(0.78, 0.78, 0.78)],
	["scatolone", Vector3(0.50, 0.45, 0.45)],
	["scatolone2", Vector3(0.55, 0.50, 0.50)],
	["cascia_grossa", Vector3(0.70, 0.40, 0.46)],
	["cascia_grossa_vacante", Vector3(0.70, 0.22, 0.46)],
	["bidone2", Vector3(0.78, 1.08, 0.78)],
	["bidone3", Vector3(0.78, 1.08, 0.78)],
	["tanica", Vector3(0.36, 0.45, 0.26)],
	["blocco_cemento", Vector3(0.45, 0.24, 0.25)],
	["water", Vector3(0.50, 1.01, 0.70)],
	["batteria_auto", Vector3(0.38, 0.27, 0.25)],
	["tubo_curto", Vector3(0.30, 0.30, 1.20)],
	["vaso_chino", Vector3(0.40, 0.55, 0.40)],
	["vaso_vacante", Vector3(0.40, 0.42, 0.40)],
	["cactus", Vector3(0.28, 0.28, 0.28)],
	["cascia_legno4", Vector3(1.12, 1.10, 1.10)],
	["cascia_legno5", Vector3(1.12, 1.10, 1.10)],
	["cascia_grossa2", Vector3(0.70, 0.40, 0.46)],
	["tubo", Vector3(0.30, 0.30, 2.60)],
	["tubo_croce", Vector3(0.55, 0.55, 0.55)],
	# 'O bastone 'e tenne: dint'ô vascio, appiso ô soffitto senza tenne,
	# pareva 'na trave ca stev'a pe' cadé (s'è visto 'n fotografia).
	# Appuggiato ô muro 'e 'nu vicolo invece è 'na cosa normale.
	["bastone_tenne", Vector3(3.10, 0.10, 0.22)],
]

## 'A robba leggia: sta 'nterra pure essa ma nun ferma a nisciuno, quindi
## niente corpo solido. È chella ca fa 'o rummore 'e fondo.
const ROBBA_LEGGIA := [
	"mattone", "mattone2", "lattina", "bottiglia_vetro", "bottiglia_vetro2",
	"scatoletta_arrugginita", "cicca", "cicca2", "pacchetto_sigarette",
	"chiuove", "lisca", "spugna", "giocattolo", "libro", "libro2",
	"videocassetta", "cidi",
]

## Chello ca sta appiso ô muro: nun ferma niente e nun se pò sbattere, sta
## 'e tre metre 'n coppa.
const ROBBA_Ô_MURO := ["griglia", "griglia2", "griglia3", "tubo_angolo",
	"valvola", "lucchetto", "lucchetto2", "lucchetto3", "lucchetto4",
	"presa", "interruttore"]

## Quante pezzi se mettono, p''e tre famiglie.
const QUANTE_NTERRA: int = 19
const QUANTE_LEGGIE: int = 30
const QUANTE_Ô_MURO: int = 18
## 'O filo d''o marciapiede: fore d''a corsia, fore d''e portune.
const FILO_DA: float = 2.10
const FILO_A: float = 2.90
## Addò nun se mette niente: 'a sciuta d''a piazza e 'o salotto 'n miezo.
const LASSA_STA_SOTTO: float = 5.0
const LASSA_STA_MIEZO := Vector2(0.38, 0.54)   # 'n frazione d''a lunghezza


func _build_robba_psx() -> void:
	var rng := RandomNumberGenerator.new()
	# 'A semmenta se piglia d''a mesura d''o vicolo: due piazze 'e taglia
	# diversa teneno munnezza diversa, 'a stessa piazza sempe 'a stessa.
	rng.seed = 7719 + int(width * 100.0) + int(length * 10.0)

	var libbero: Array = _chi_nun_s_ha_da_ntuppà()
	for i in range(QUANTE_NTERRA):
		var r: Array = ROBBA_NTERRA[rng.randi() % ROBBA_NTERRA.size()]
		var mis: Vector3 = r[1]
		var giro_r: float = rng.randf_range(0.0, TAU)
		# **Quanto è grossa, no sulo addó sta** (0.59). Il rispetto si
		# contava dal centro della cosa: un bidone da quaranta centimetri e
		# un bastone da tre metri avevano lo stesso margine, e il bastone
		# arrivava con una punta a un metro dal guaglione — abbastanza per
		# mettersi in mezzo fra lui e chi lo guarda (`prova_mira`).
		var raggio: float = Vector2(mis.x, mis.z).length() * 0.5
		var p: Vector3 = Vector3.ZERO
		var truvato := false
		for giro in range(14):
			p = _punto_ncopp_ô_filo(rng)
			if _sta_libbero(p, libbero, raggio):
				truvato = true
				break
		if not truvato:
			continue
		if _prop(str(r[0]), p, giro_r) != null:
			_prop_solido(p, mis, giro_r)
			# E la prossima non ci si mette sopra: prima due casse potevano
			# nascere una dentro all'altra (`prova_ngombri`).
			libbero.append([global_position + p, raggio + 0.15])

	for i in range(QUANTE_LEGGIE):
		var nome: String = str(ROBBA_LEGGIA[rng.randi() % ROBBA_LEGGIA.size()])
		var p: Vector3 = _punto_ncopp_ô_filo(rng)
		# 'A robba leggia se spanne 'nu poco cchiù larga: 'na cicca 'n miezo
		# ô marciapiede ce sta, 'nu bidone no.
		p.x += rng.randf_range(-0.9, 0.5) * (1.0 if p.x < width * 0.5 else -1.0)
		_prop(nome, p, rng.randf_range(0.0, TAU))

	for i in range(QUANTE_Ô_MURO):
		var nome: String = str(ROBBA_Ô_MURO[rng.randi() % ROBBA_Ô_MURO.size()])
		var manca: bool = rng.randf() < 0.5
		var z: float = rng.randf_range(LASSA_STA_SOTTO, length - 3.0)
		# Mezzo metro fore d''a facciata, a 'n'altezza ca nun 'mpiccia.
		var n := _prop(nome,
			Vector3(0.42 if manca else width - 0.42,
				rng.randf_range(2.4, 3.6), z),
			(PI * 0.5) if manca else (-PI * 0.5))
		if n != null:
			n.rotation.z = rng.randf_range(-0.05, 0.05)


## 'Nu punto ncopp'ô filo 'e 'nu marciapiede o 'e chill'ato, saltanno 'a
## sciuta e 'o salotto.
func _punto_ncopp_ô_filo(rng: RandomNumberGenerator) -> Vector3:
	var z: float = 0.0
	for _giro in range(12):
		z = rng.randf_range(LASSA_STA_SOTTO, length - 2.5)
		var f: float = z / length
		if f < LASSA_STA_MIEZO.x or f > LASSA_STA_MIEZO.y:
			break
	var x: float = rng.randf_range(FILO_DA, FILO_A)
	if rng.randf() < 0.5:
		x = width - x
	# 0,12 è l'altezza d''o marciapiede.
	return Vector3(x, 0.12, z)


## **'A robba cu 'o cuorpo nun se mette 'nnanze a chi se pò tuccà.**
##
## Questa funzione è nata da una prova rossa, ed è la cosa più importante di
## tutta la versione. `prova_mira` — quella che dalla 0.44 mette il player
## davanti a ogni cosa agganciabile e chiede al gioco cosa ha agganciato —
## è passata da 0 storte a **4**: mirando al guaglione delle quattro piazze,
## il gioco agganciava tutt'altro.
##
## Il motivo è una riga di `player_fps._bersaglio_vicino()` che fa
## esattamente il suo mestiere: prima di dare per buono un bersaglio, tira
## un raggio e **controlla che in mezzo non ci sia un muro** — se no si
## parlerebbe con la gente attraverso le persiane. Un bidone con il suo
## corpo solido, piantato fra te e il guaglione, per quel controllo **è un
## muro**. Il guaglione veniva scartato, e l'aggancio finiva altrove.
##
## Non è un difetto del controllo: è il controllo che funziona. Il difetto
## era mio, che ho sparso trentanove oggetti solidi per una piazza senza
## chiedere a nessuno chi ci stava già.
##
## E la cura non è una lista di coordinate da evitare — quella invecchia il
## giorno in cui qualcuno sposta il guaglione. **Si chiede alla scena**: chi
## sta nei gruppi agganciabili, più i posti auto, si tiene un raggio di
## rispetto, e chi non trova posto in quattordici tiri non si costruisce.
## Se domani aggiungiamo un personaggio nuovo, la munnezza gli gira attorno
## da sola.
const RISPETTO: float = 2.6        # metre 'a chi se pò tuccà
const RISPETTO_POSTO: float = 3.2  # metre 'a 'nu posto auto

func _chi_nun_s_ha_da_ntuppà() -> Array:
	var fore: Array = []
	# **Sulo chi sta fermo** (0.59). Nell'elenco c'erano anche i gruppi di
	# chi cammina — i vigili di ronda, la signora, e i passanti (che stanno
	# nel gruppo `attivita` perché ci si parla) — e il loro posto al momento
	# della costruzione cambia da una partita all'altra. La munnezza della
	# piazza, che doveva essere sempre la stessa, cambiava con loro: e
	# `prova_mira` passava una volta sì e una no, secondo dove stava il
	# vigile mentre si posava il primo bidone.
	for g in [&"guagliuni", &"attivita", &"punti_cummissione", &"shop",
			&"manifesti", &"tavoli_scopa", &"porte_casa",
			&"decoro", &"garage", &"bacheche"]:
		for n in get_tree().get_nodes_in_group(g):
			if not (n is Node3D):
				continue
			if n.is_in_group(&"passanti") or n.is_in_group(&"vigili") \
					or n.is_in_group(&"signore") or n.is_in_group(&"drivers"):
				continue
			if n is Node3D:
				fore.append([(n as Node3D).global_position, RISPETTO])
	for sp in parking_spots:
		if sp is Node3D:
			fore.append([(sp as Node3D).global_position, RISPETTO_POSTO])
	return fore


func _sta_libbero(p: Vector3, chi: Array, raggio: float = 0.0) -> bool:
	var g: Vector3 = global_position + p
	for c in chi:
		var q: Vector3 = c[0]
		var r: float = float(c[1])
		if Vector2(g.x - q.x, g.z - q.z).length() < r + raggio:
			return false
	return true
