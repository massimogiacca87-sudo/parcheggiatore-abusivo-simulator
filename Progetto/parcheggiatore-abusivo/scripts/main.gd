extends Node3D
## Main
## Compone la scena di gioco 3D: zona attiva, player FPS e HUD. In questo
## prototipo la zona attiva è sempre "Il Vicolo"; le zone successive della
## roadmap potranno essere selezionate qui in base ai progressi salvati.

const CittaScript := preload("res://scripts/citta_3d.gd")
const PlayerScript := preload("res://scripts/player_fps.gd")
const HudScript := preload("res://scripts/hud.gd")
const FiltriScript := preload("res://scripts/filtri_schermo.gd")
const PozzangheraScript := preload("res://scripts/pozzanghere.gd")
const IntroScript := preload("res://scripts/intro_screen.gd")
const CaricamentoScript := preload("res://scripts/caricamento.gd")
const VolataScript := preload("res://scripts/volata.gd")

var _player: Node3D = null
var _citta: Node = null


func _ready() -> void:
	# Ripristina lo stato globale: se il turno precedente è finito durante
	# uno slow-motion o col gioco in pausa, senza questo reset la partita
	# nuova ripartirebbe al rallentatore o congelata.
	Engine.time_scale = 1.0
	get_tree().paused = false
	# **L'orologio parte a mezzogiorno, no a miezanotte passata** (0.63).
	# Fino a `start_shift()` il cronometro della giornata valeva zero, cioè
	# «giornata finita»: per tutta la volata d'apertura (il mondo gira, il
	# turno non ancora) `ora_d_o_juorno()` diceva le quattro del mattino.
	# I vigili guardavano l'ora, vedevano che erano passate le venti e
	# smontavano tutti prima che il giocatore toccasse terra: nel gioco
	# vero non se ne vedeva più nessuno (nelle prove, che saltano la
	# volata, c'erano). Adesso la giornata nuova comincia a mezzogiorno
	# già mentre si carica.
	if not GameManager.shift_active:
		GameManager.shift_time_left = GameManager.shift_duration

	if OS.get_environment("DEBUG_ZONE") != "":
		GameManager.selected_zone = OS.get_environment("DEBUG_ZONE")

	# Zona sconosciuta (salvataggio vecchio o corrotto): torna alla Piazza
	# invece di crashare sull'indice mancante.
	if not GameManager.ZONES.has(GameManager.selected_zone):
		GameManager.selected_zone = "vicolo"

	# **La schermata di caricamento sta davanti a tutto, e viene prima.**
	#
	# Costruire il quartiere costa qualche secondo, e prima quei secondi
	# erano uno schermo nero: non si capiva se il gioco fosse partito o
	# morto. Adesso c'e' la barra, e siccome uno la deve guardare comunque,
	# ci stanno scritti sopra i comandi.
	#
	# I passi della barra sono veri: uno per la citta', uno per il player e
	# l'interfaccia, uno per i fotogrammi di assestamento. Non e'
	# un'animazione finta che va avanti da sola.
	var caricamento: CanvasLayer = null
	# Chi arriva qui da un caricamento (slot scelto nel menu o in pausa) ha
	# già visto locandine, tutorial e volata: si va dritti in piazza.
	var da_salvataggio: bool = GameManager.salta_intro
	GameManager.salta_intro = false
	var mostra := DisplayServer.get_name() != "headless" \
		and not da_salvataggio \
		and OS.get_environment("DEBUG_SIM") == "" \
		and OS.get_environment("DEBUG_STRESS") == ""
	if mostra:
		caricamento = CaricamentoScript.new()
		caricamento.name = "Caricamento"
		add_child(caricamento)
		# **Il mondo sta fermo finche' non lo dici tu.**
		#
		# Prima la citta' cominciava a vivere appena finita di costruire,
		# cioe' mentre stavano ancora a video le locandine e il menu: le
		# auto arrivavano, i clienti perdevano la pazienza, il vigile
		# faceva la ronda e l'orologio girava. Chi si leggeva il tutorial
		# per intero entrava in partita a giornata iniziata, con la piazza
		# gia' piena di gente incazzata.
		#
		# `paused` ferma tutto tranne chi ha PROCESS_MODE_ALWAYS — cioe'
		# questa schermata, l'interfaccia e il suono. Si riparte solo dopo
		# che il giocatore ha premuto "Accummenciamo".
		get_tree().paused = true
		# Due fotogrammi perche' la schermata faccia in tempo a comparire
		# prima che la costruzione blocchi il thread.
		await get_tree().process_frame
		await get_tree().process_frame
		caricamento.passo(0.12, "Se sta apparecchiann''a città…")
		await get_tree().process_frame

	# Non piu' una piazza sola: il quartiere intero. La Piazza ci sta
	# dentro come primo quartiere (e per ora l'unico che sia tuo).
	var citta := CittaScript.new()
	citta.name = "Citta"
	add_child(citta)
	_citta = citta

	if caricamento != null:
		caricamento.passo(0.66, "Se stanno chiammann''e machine…")
		await get_tree().process_frame

	var player := PlayerScript.new()
	player.name = "Player"
	add_child(player)
	# **Chi s'è scetato 'n galera se scéta fore â galera** (0.56).
	#
	# La giornata nuova ricarica la scena, quindi "dove ti svegli" si
	# decide qui e da nessun'altra parte. Se la nottata l'hai passata
	# dentro, la mattina ti aprono il portone e ti trovi dall'altra parte
	# della città, a piedi e senza una lira: **la strada di ritorno è
	# metà della punizione**, ed è l'unico pezzo che si sente davvero.
	if GameManager.sveglia_n_galera:
		GameManager.sveglia_n_galera = false
		# Due metri fuori dal portone, girato verso ponente, cioè verso
		# casa (0.60: la galera sta in cima al Vomero e guarda a nord).
		player.global_position = GameManager.GALERA_FORE \
			+ GameManager.GALERA_VERSO * 2.2 + Vector3(0, 0.6, 0)
		player.rotation.y = PI * 0.5
		GameManager.event_started.emit(
			"T'hanno araputo 'o purtone. Mo' te ne turne a pede, e senza 'na lira.")
	else:
		player.global_position = citta.get_player_start()
		player.rotation.y = citta.player_start_rotation_y
	_player = player

	var hud := HudScript.new()
	hud.name = "HUD"
	add_child(hud)
	hud.set_player(player)

	# 'E filtre d''o schermo (0.62): quello scelto nel menu di pausa e la
	# botta quando ti colpiscono (vedi `filtri_schermo.gd`).
	var filtri := FiltriScript.new()
	filtri.name = "FiltriSchermo"
	add_child(filtri)
	# 'E pozzanghere quanno chiove (0.62): solo in Forward+ (l'exe), appese
	# alla telecamera del giocatore. Nella build web non si costruiscono.
	if PozzangheraScript.si_puo() and player.get("camera") != null:
		player.camera.add_child(PozzangheraScript.new())

	# **'O rummore d''a citta'.** Voci vere registrate per strada, sotto a
	# tutto. Non e' musica e non e' un effetto: e' il fondo su cui sta il
	# resto, e senza il quartiere sembra spopolato anche con venti passanti
	# a schermo. Si abbassa da sola quando si entra dentro casa.
	SoundManager.ambiente(1.0, 4.0)
	# E la musica torna "fuori": ricominciare la giornata o la partita
	# ricarica la scena senza passare da `vascio_3d.esci()`.
	SoundManager.musica_dentro(false, 0.0)

	if caricamento != null:
		caricamento.passo(0.9, "Ancora nu momento…")
		for _i in range(8):
			await get_tree().process_frame
		caricamento.pronto()
		GameManager.intro_active = true
		await caricamento.comincia
		# Da qui in poi il mondo puo' muoversi: la volata ci vola sopra e
		# subito dopo comincia il turno.
		get_tree().paused = false
		# L'interfaccia sparisce durante la volata. Con i soldi, le barre e
		# la freccia del cliente addosso, un'inquadratura panoramica sembra
		# un bug della telecamera invece di un'apertura.
		hud.visible = false
		await _volata(citta, player)
		hud.visible = true
		GameManager.intro_active = false
		GameManager.start_shift()
		return

	# I soldi NON si azzerano più: il portafoglio persiste tra i turni
	# (e viene salvato su disco). Si azzera solo il sospetto.
	GameManager.heat = 0.0

	# Il turno non parte finché la schermata iniziale è a video: altrimenti
	# il timer scorrerebbe mentre il giocatore sta ancora leggendo.
	# In headless (test automatici) la schermata si salta.
	var skip_intro := DisplayServer.get_name() == "headless" \
		or da_salvataggio \
		or OS.get_environment("DEBUG_SIM") != "" \
		or OS.get_environment("DEBUG_STRESS") != ""
	if OS.get_environment("DEBUG_INTRO") != "": # per collaudare la schermata
		skip_intro = false
	if skip_intro:
		GameManager.intro_active = false
		GameManager.start_shift()
		return

	var intro := IntroScript.new()
	intro.name = "IntroScreen"
	intro.dismissed.connect(_on_intro_dismissed)
	add_child(intro)


func _on_intro_dismissed() -> void:
	GameManager.start_shift()


## **La volata d'apertura.**
##
## Si parte alti sul quartiere, si scende girando, e si finisce dentro agli
## occhi del parcheggiatore senza uno stacco. Il turno comincia soltanto
## dopo: guardare la città non deve costare secondi di lavoro.
func _volata(citta: Node, player: Node3D) -> void:
	var v: Node3D = VolataScript.new()
	v.name = "Volata"
	add_child(v)
	var centro: Vector3 = player.global_position
	if citta.has_method("get_player_start"):
		centro = citta.get_player_start()
	v.avvia(centro + Vector3(28.0, 0, 40.0), func() -> Transform3D:
		var cam = player.get("camera")
		if cam != null and is_instance_valid(cam):
			return (cam as Camera3D).global_transform
		return Transform3D(Basis(), player.global_position + Vector3(0, 1.6, 0)))
	await v.finita
	var cam2 = player.get("camera")
	if cam2 != null and is_instance_valid(cam2):
		(cam2 as Camera3D).current = true





