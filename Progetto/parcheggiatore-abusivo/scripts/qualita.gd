extends Node
class_name Qualita
## Qualita
## Regola la grafica da sola, guardando quanti fotogrammi al secondo sta
## davvero facendo il computer di chi gioca.
##
## Il problema: Forward+ permette occlusione ambientale, luce indiretta a
## schermo, riflessi e nebbia volumetrica — ma tutte insieme, su una scheda
## video integrata, portano il gioco a quindici fotogrammi. E non c'è modo
## di sapere prima quanto è potente il computer di chi apre l'exe: leggere il
## nome della scheda è una lotteria (ne escono di nuove ogni mese) e chiedere
## all'utente di scegliere un livello significa chiederglielo prima che abbia
## visto una sola schermata.
##
## Quindi si misura. Si parte dal livello più alto, si guarda per qualche
## secondo come va, e se non ci si sta si scende di un gradino. Il livello a
## cui ci si ferma viene salvato: la volta dopo si riparte da lì, e la
## misurazione serve solo a confermarlo.
##
## In GL Compatibility — cioè nel browser — non c'è niente da regolare:
## quegli effetti proprio non esistono e il livello resta a BASSA.

enum Livello { BASSA = 0, MEDIA = 1, ALTA = 2 }

const NOMI := {
	Livello.BASSA: "bassa", Livello.MEDIA: "media", Livello.ALTA: "alta",
}

## Sotto questi fotogrammi al secondo si scende di un gradino.
const FPS_MINIMO := 45.0
## Quanto si osserva prima di decidere. Il primo secondo si butta: è quello
## in cui il gioco sta ancora compilando shader e caricando texture, e i
## numeri lì non dicono niente sul computer.
const RISCALDAMENTO := 1.6
const FINESTRA := 3.0

signal livello_cambiato(livello: int)

var livello: int = Livello.ALTA

var _env: Environment
var _sole: DirectionalLight3D
var _t: float = 0.0
var _campioni: int = 0
var _somma: float = 0.0
var _assestato: bool = false


func setup(env: Environment, sole: DirectionalLight3D) -> void:
	_env = env
	_sole = sole
	if not _forward_plus():
		livello = Livello.BASSA
		_assestato = true
		_applica()
		return
	livello = int(GameManager.qualita_salvata) if GameManager.qualita_salvata >= 0 \
		else Livello.ALTA
	_applica()


func _process(delta: float) -> void:
	if _assestato or _env == null:
		return
	_t += delta
	if _t < RISCALDAMENTO:
		return
	_somma += delta
	_campioni += 1
	if _t < RISCALDAMENTO + FINESTRA:
		return

	var fps: float = float(_campioni) / maxf(_somma, 0.0001)
	if fps < FPS_MINIMO and livello > Livello.BASSA:
		livello -= 1
		_applica()
		print("Qualità → ", NOMI[livello], " (%.0f fps misurati)" % fps)
		# Si rimisura da capo: magari un gradino non basta.
		_t = 0.0
		_campioni = 0
		_somma = 0.0
		return

	_assestato = true
	GameManager.qualita_salvata = livello
	GameManager.save_game()


## F5 gira fra bassa, media e alta. La misura automatica sbaglia in un caso:
## se il primo secondo di gioco capita male — l'antivirus che scansiona,
## un'altra finestra che carica — il gioco scende di livello e non risale
## più. Serve un modo per rimetterlo su senza cancellare il salvataggio.
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if (event as InputEventKey).keycode != KEY_F5:
		return
	if not _forward_plus():
		GameManager.event_started.emit(
			"Grafica: non regolabile in questa modalità")
		return
	imposta((livello + 1) % 3)
	GameManager.event_started.emit("Grafica: " + str(NOMI[livello]).to_upper())


## Forzato a mano dal menù: da qui in poi non si tocca più da solo.
func imposta(nuovo: int) -> void:
	livello = clampi(nuovo, Livello.BASSA, Livello.ALTA)
	_assestato = true
	_applica()
	GameManager.qualita_salvata = livello
	GameManager.save_game()


func _applica() -> void:
	if _env == null:
		return
	var alta := livello >= Livello.ALTA
	var media := livello >= Livello.MEDIA

	# Luce indiretta a schermo (SSIL) e riflessi (SSR) NON tornano più su a
	# nessun livello.
	#
	# Erano accesi ad ALTA, che è il livello di partenza: qualunque cosa
	# impostasse la città veniva riscritta da qui un istante dopo. Ed erano
	# la causa dello sfarfallio segnalato in gioco — due effetti che
	# ricostruiscono l'informazione campionando lo schermo in punti scelti a
	# caso, senza nessun accumulatore temporale che li tenga fermi da un
	# fotogramma all'altro. In una piazza aperta si nota poco; in un vicolo
	# da quattro metri, dove i due muri riempiono tutto lo schermo e sono
	# vicinissimi, brulica tutto.
	#
	# Restano spenti anche ad ALTA. Il posto giusto per rimetterli è quando
	# ci sarà un antialiasing temporale che li medi.
	_env.ssil_enabled = false
	_env.ssr_enabled = false
	_env.volumetric_fog_enabled = alta

	# MEDIA: resta l'occlusione ambientale, che è quella che dà peso alle
	# cose ed è la più difficile da togliere senza che si veda. Il dettaglio
	# resta basso apposta: è il parametro che, alzato, la fa granulare.
	_env.ssao_enabled = media
	_env.glow_enabled = media
	_env.ssao_detail = 0.2 if alta else 0.0

	if _sole != null:
		if alta:
			_sole.directional_shadow_mode = \
				DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			_sole.directional_shadow_max_distance = 110.0
		elif media:
			_sole.directional_shadow_mode = \
				DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
			_sole.directional_shadow_max_distance = 70.0
		else:
			_sole.directional_shadow_mode = \
				DirectionalLight3D.SHADOW_ORTHOGONAL
			_sole.directional_shadow_max_distance = 45.0

	var vp := get_viewport()
	if vp != null:
		# Quattro campioni ad ALTA e non due. La città è piena di roba
		# sottile — ringhiere, tiranti dei panni, montanti delle finestre,
		# antenne — e un bordo sottile largo meno di un pixel compare e
		# scompare a ogni passo. È l'altra metà dello sfarfallio, quella
		# geometrica, e l'unica cosa che la toglie è campionare di più.
		if alta:
			vp.msaa_3d = Viewport.MSAA_4X
		elif media:
			vp.msaa_3d = Viewport.MSAA_2X
		else:
			vp.msaa_3d = Viewport.MSAA_DISABLED
		vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if not media \
			else Viewport.SCREEN_SPACE_AA_DISABLED
	livello_cambiato.emit(livello)


static func _forward_plus() -> bool:
	return RenderingServer.get_rendering_device() != null
