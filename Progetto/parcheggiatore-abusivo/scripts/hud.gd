extends CanvasLayer
## HUD
## Interfaccia di gioco: soldi, barra del sospetto (heat), timer del turno,
## messaggi contestuali di interazione, il minigioco gestuale di parcheggio
## e il riepilogo di fine turno.

var money_label: Label
var heat_bar: ProgressBar
var timer_label: Label
var giorno_label: Label
var fascia_label: Label
var prompt_label: Control  # 0.62: riga_comandi.gd (ha `text` come una Label)
var crosshair: Control
var _segno: Control
var _segno_t: float = 0.0
var summary_panel: Panel
var summary_label: Label

var directing_panel: Panel
var directing_title_label: Label
var directing_distance_bar: ProgressBar
var directing_align_bar: ProgressBar
var directing_speed_label: Label
var directing_bump_label: Label
var directing_time_label: Label
var directing_result_label: Label

var shout_label: Label       # il gesto gridato dal parcheggiatore, grande e giallo
var driver_reply_label: Label # la risposta comica dell'autista

var pause_panel: Panel
var inventory_panel: Panel
var inventory_label: Label
var emblem_counter_label: Label
var commission_label: Label
var conto_label: Label
var conto_voci: Label
var cumm_label: Label
var event_banner: Label
var client_pointer: Label
var emblem_pointer: Label
var casa_pointer: Label
var pacco_cap: Label          # 'o pacco ca puorte 'n cuollo
var pacco_bar: ProgressBar
const Pad := preload("res://scripts/joypad.gd")
const MappaScript := preload("res://scripts/mappa.gd")
const IconeScript := preload("res://scripts/icone.gd")
const PannelloLottoS := preload("res://scripts/pannello_lotto.gd")

var _player_ref: Node3D = null
var shop_panel: Panel
var shop_label: Label
var shop_title: Label
var cig_label: Label
var health_bar: ProgressBar
var sciato_bar: ProgressBar
var sciato_caption: Label
var health_caption: Label
var hurt_flash: ColorRect
# --- Boss di fine turno ---
var boss_panel: Panel          # barra della furia, in alto al centro
var boss_furia_bar: ProgressBar
var boss_hint: Label
# --- HP del bersaglio ---
var nemico_panel: Panel
var nemico_nome: Label
var nemico_bar: ProgressBar
var _nemico_time: float = 0.0
var dialogue_panel: Panel      # le quattro risposte
var dialogue_buttons: Array = []
var _dialogue_answers: Array = []
# --- Minigioco del borseggio ---
var pick_panel: Panel
var pick_track: ColorRect          # la striscia rossa
var pick_cursor: ColorRect         # il cursore che va avanti e indietro
var pick_hint: Label
var _pick_target: Node = null      # la signora
var _pick_pos: float = 0.0         # 0..1 lungo la barra
var _pick_dir: float = 1.0
var _pick_speed: float = 0.9
var _pick_left: float = 0.0        # secondi prima che la barra si chiuda da sola
var mappa: Control = null          # 'a chiantina, tasto M
# --- 'E stelle 'e ricercato ---
var stelle_ui: Control = null
var mano_ui: HBoxContainer = null
var freccia_ui: Control = null
var _mano_etichette: Array = []
var _stelle: int = 0
var _stelle_lampo: float = 0.0
# --- 'A presa d''e carabiniere ---
var presa_panel: Panel
var presa_bar: ProgressBar
var presa_hint: Label
var _pick_zones: Array = []        # [[inizio, fine], ...] in 0..1
# --- Zaino e piazzamento decorazioni ---
var _inv_placeable: Array = []     # id delle decorazioni possedute, in ordine

## Il joypad non ha i numeri: nei listini si scorre con la croce
## direzionale e si conferma con la croce/A. `_sel` e' la riga evidenziata
## del pannello aperto in questo momento (negozio, zaino o dialogo col
## boss). Sulla tastiera i numeri continuano a funzionare come prima: la
## selezione e' un'aggiunta, non un rimpiazzo.
var _sel: int = 0
var _shop_grid: Control
var _inv_grid: Control
var _pause_first_btn: Button
var _pause_hint: Label
var _summary_first_btn: Button

var _directing_active: bool = false
var _bump_flash_time: float = 0.0
var _shout_time: float = 0.0
var _reply_time: float = 0.0
var _banner_time: float = 0.0
var _last_money: int = -1
var _result_hide_time: float = 0.0
var _hurt_flash_time: float = 0.0

# --- La macchina fotografica (manifesti) --------------------------------
var _foto_root: Control
var _foto_flash: ColorRect
var _foto_titolo: Label
var _foto_sotto: Label
var _foto_conta: Label
var _foto_time: float = 0.0


func _ready() -> void:
	layer = 10
	# L'HUD deve restare attivo anche a gioco in pausa: gestisce il menu.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_disable_mouse_capture_on_all_controls(self)
	_build_pause_menu() # DOPO il disable: i suoi bottoni devono ricevere i click
	_build_foto_ui()
	_build_summary_buttons()
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.heat_changed.connect(_on_heat_changed)
	GameManager.shift_time_changed.connect(_on_shift_time_changed)
	GameManager.shift_ended.connect(_on_shift_ended)
	GameManager.purtato_n_galera.connect(_su_galera)
	GameManager.sciato_cambiato.connect(_su_sciato)
	GameManager.directing_started.connect(_on_directing_started)
	GameManager.directing_update.connect(_on_directing_update)
	GameManager.directing_bump.connect(_on_directing_bump)
	GameManager.directing_ended.connect(_on_directing_ended)
	GameManager.directing_released.connect(_on_directing_released)
	GameManager.directing_gesture.connect(_on_directing_gesture)
	GameManager.inventory_changed.connect(_on_inventory_changed)
	GameManager.event_started.connect(_on_event_started)
	GameManager.commission_changed.connect(_refresh_commission)
	# Metodi nominati, non lambda: vedi la nota in player_fps.gd
	GameManager.upgrade_purchased.connect(_on_shop_dirty)
	GameManager.negozio_selezione.connect(_on_negozio_selezione)
	GameManager.dipendenti_cambiati.connect(_refresh_emblem_counter)
	GameManager.caffe_changed.connect(_on_caffe_changed)
	_aggancia_citta.call_deferred()
	GameManager.money_changed.connect(_on_money_dirty)
	GameManager.cigarettes_changed.connect(_on_cigarettes_changed)
	GameManager.health_changed.connect(_on_health_changed)
	GameManager.player_hurt.connect(_on_player_hurt)
	GameManager.nemico_colpito.connect(_on_nemico_colpito)
	GameManager.colpo_a_segno.connect(_on_colpo_a_segno)
	GameManager.stelle_cambiate.connect(_on_stelle_cambiate)
	GameManager.arma_cambiata.connect(_aggiorna_mano)
	GameManager.minaccia.connect(_on_minaccia)
	GameManager.presa_iniziata.connect(_on_presa_iniziata)
	GameManager.presa_finita.connect(_on_presa_finita)
	GameManager.presa_stato.connect(_on_presa_stato)
	GameManager.boss_state_changed.connect(_on_boss_state_changed)
	GameManager.boss_dialogue_opened.connect(_on_boss_dialogue_opened)
	GameManager.boss_dialogue_closed.connect(_on_boss_dialogue_closed)
	GameManager.pickpocket_started.connect(_on_pickpocket_started)
	GameManager.manifesto_fotografato.connect(_on_manifesto_fotografato)
	GameManager.collezione_completa.connect(_on_collezione_completa)
	GameManager.servizio_cambiato.connect(_on_servizio_cambiato)
	_on_health_changed(GameManager.health)
	_on_cigarettes_changed(GameManager.cigarettes)
	_refresh_emblem_counter()
	_refresh_commission()

	_on_money_changed(GameManager.money)
	_on_heat_changed(GameManager.heat)
	_on_shift_time_changed(GameManager.shift_time_left)


func _on_colpo_a_segno(danno: int) -> void:
	_segno_t = 0.18
	if _segno != null:
		_segno.modulate = Color(1.0, 0.35, 0.25) if danno >= 12 \
			else Color(1.0, 0.95, 0.85)


func _process(delta: float) -> void:
	if _segno != null:
		_segno_t = maxf(0.0, _segno_t - delta)
		_segno.modulate.a = clampf(_segno_t / 0.12, 0.0, 1.0)
	_process_galera(delta)
	_avvisa_d_o_mouse()
	_cruscotto()
	if _bump_flash_time > 0.0:
		_bump_flash_time -= delta
		if _bump_flash_time <= 0.0:
			directing_bump_label.text = ""
	if _shout_time > 0.0:
		_shout_time -= delta
		shout_label.modulate.a = clamp(_shout_time / 0.4, 0.0, 1.0)
		if _shout_time <= 0.0:
			shout_label.text = ""
	if _reply_time > 0.0:
		_reply_time -= delta
		driver_reply_label.modulate.a = clamp(_reply_time / 0.5, 0.0, 1.0)
		if _reply_time <= 0.0:
			driver_reply_label.text = ""
	if _banner_time > 0.0:
		_banner_time -= delta
		event_banner.modulate.a = clamp(_banner_time / 0.6, 0.0, 1.0)
		if _banner_time <= 0.0:
			event_banner.text = ""
	if _foto_time > 0.0:
		_foto_time -= delta
		_foto_root.modulate.a = clamp(_foto_time / 0.5, 0.0, 1.0)
		if _foto_time <= 0.0:
			_foto_root.visible = false
	# Il riquadro dell'esito si nasconde da sé con un contatore invece che
	# con un SceneTreeTimer: se la scena viene ricaricata prima dello
	# scadere, un timer con closure toccherebbe un'etichetta già liberata.
	if _result_hide_time > 0.0:
		_result_hide_time -= delta
		if _result_hide_time <= 0.0:
			directing_result_label.visible = false

	if _hurt_flash_time > 0.0:
		_hurt_flash_time -= delta
		hurt_flash.color.a = clampf(_hurt_flash_time / 0.5, 0.0, 1.0) * 0.42

	_aggiorna_conto()
	_passo_pacco(delta)

	# Chi sta giocando in questo momento: tastiera o pad. Se cambia, i
	# suggerimenti a schermo si riscrivono col tasto giusto.
	if _zona_visibile > 0.0:
		_zona_visibile -= delta
		if zona_label:
			zona_label.modulate.a = clampf(_zona_visibile, 0.0, 1.0)
			# 0.62: sta dentro alla scheda, e una riga trasparente occupa
			# posto lo stesso: finita la dissolvenza si svuota.
			if _zona_visibile <= 0.0:
				zona_label.text = ""
	Pad.aggiorna()
	var ora_pad := Pad.collegato()
	if ora_pad != _era_pad:
		_era_pad = ora_pad
		_ridisegna_suggerimenti()

	if _strada_visibile > 0.0:
		_strada_visibile -= delta
		if strada_label:
			strada_label.modulate.a = clampf(_strada_visibile / 0.8, 0.0, 1.0)
			if _strada_visibile <= 0.0:
				strada_label.text = ""

	if _servizio_visibile > 0.0:
		_servizio_visibile -= delta
		var a: float = clampf(_servizio_visibile / 0.8, 0.0, 1.0)
		servizio_banner.modulate.a = a
		servizio_sub.modulate.a = a
		if _servizio_visibile <= 0.0:
			servizio_banner.text = ""
			servizio_sub.text = ""

	if _nemico_time > 0.0:
		_nemico_time -= delta
		nemico_panel.modulate.a = clampf(_nemico_time / 0.8, 0.0, 1.0)
		if _nemico_time <= 0.0:
			nemico_panel.visible = false

	_update_pickpocket(delta)
	_spegni_vuote()
	_update_servizio()
	_update_client_pointer()
	_update_emblem_pointer()
	_update_bussola_casa()


## La targhetta fissa in alto a destra. Quando sei fuori servizio dice anche
## quanto sei lontano dalla piazza e da che parte sta: è l'unica indicazione
## di lavoro che resta accesa fuori dalla zona tua, ed è una bussola verso
## casa, non un richiamo a un cliente.
func _update_servizio() -> void:
	if servizio_label == null:
		return
	# Il pannello del lavoro si spegne a metà quando non sei in servizio.
	# Il sospetto e il cronometro del turno continuano a esistere, ma non
	# sono la cosa che stai facendo adesso, e lasciarli accesi come prima
	# dice al giocatore che è ancora "sul pezzo" quando invece no.
	var acceso: float = 1.0 if GameManager.in_servizio else 0.42
	if heat_bar:
		heat_bar.modulate.a = acceso
	if timer_label:
		timer_label.modulate.a = acceso

	if GameManager.in_servizio:
		servizio_label.text = "● IN SERVIZIO"
		servizio_label.modulate = Color(0.55, 1.0, 0.62)
		return
	servizio_label.modulate = Color(0.72, 0.74, 0.78)
	# **Dentro casa la bussola non vuol dire niente.** L'interno del vascio
	# sta a (300, 300), fuori dalla citta': la distanza dalla piazza usciva
	# "381 m" e la freccia puntava a caso. Peggio ancora, la si leggeva
	# mentre si sta in cucina a contare 'e sorde — cioe' nel momento in cui
	# del lavoro non importa niente a nessuno.
	if GameManager.dentro_casa:
		servizio_label.text = "○ dint'ô vascio"
		return
	var casa := _casa_mia()
	if casa == Vector3.INF or _player_ref == null \
			or not is_instance_valid(_player_ref):
		servizio_label.text = "○ fuori servizio"
		return
	var d: float = _player_ref.global_position.distance_to(casa)
	servizio_label.text = "○ fuori servizio — 'a piazza toia %s, %d m" % [
		_direction_hint(casa), int(round(d))]


## Il centro della piazza di cui sei padrone. Vector3.INF se non c'è città
## (non dovrebbe capitare, ma il HUD non deve morire per questo).
func _casa_mia() -> Vector3:
	var citta := get_tree().get_root().find_child("Citta", true, false)
	if citta == null or not citta.has_method("centro_piazza_mia"):
		return Vector3.INF
	return citta.centro_piazza_mia()


## Entri o esci dalla piazza tua. È il momento in cui il gioco deve dire, a
## caratteri grossi, che il lavoro si accende o si spegne — se no uno non
## capisce perché in centro non arriva nessuno da posteggiare.
func _on_servizio_cambiato(attivo: bool, nome: String) -> void:
	if servizio_banner == null:
		return
	# Entrare in casa ti porta a (300, 300), cioe' fuori da ogni piazza, e
	# il gioco te lo annunciava a caratteri cubitali in mezzo allo schermo:
	# "SI' ASCIUTO DA' 'A PIAZZA". Dentro casa non e' una notizia.
	if GameManager.dentro_casa:
		return
	if attivo:
		servizio_banner.text = "SÎ TRASUTO 'A DINTO Â PIAZZA TOIA"
		servizio_banner.modulate = Color(0.6, 1.0, 0.66)
		servizio_sub.text = "%s — ccà se posteggia. 'E machine mo' arrivano." % nome
		servizio_sub.modulate = Color(0.78, 1.0, 0.82)
		SoundManager.play("pop", -9.0, 1.25)
	else:
		servizio_banner.text = "SÎ ASCIUTO DÂ PIAZZA"
		servizio_banner.modulate = Color(1.0, 0.78, 0.34)
		servizio_sub.text = "Fuori dâ zona toia nun se fatica: va' a fa' 'nu giro."
		servizio_sub.modulate = Color(1.0, 0.88, 0.62)
		SoundManager.play("pop", -12.0, 0.7)
	servizio_banner.modulate.a = 1.0
	servizio_sub.modulate.a = 1.0
	_servizio_visibile = 4.2



## **Quanto scotta 'o pacco.**
##
## La regola e' una sola e si capisce alla prima volta: **finche' uno in
## divisa ti vede, la barra sale.** Non conta se stai correndo, non conta
## se stai facendo qualcosa di male: conta che ti stia guardando mentre
## tieni in mano una cosa che non si puo' vedere. A cento, ti fermano.
##
## Il raggio e' sedici metri e non trenta perche' i vicoli sono larghi
## quattro: a trenta metri un vigile ti vede da meta' quartiere e la
## consegna diventa impossibile invece che difficile.
func _passo_pacco(delta: float) -> void:
	var l: Dictionary = GameManager.lavoretto_in_corso()
	var attivo: bool = not l.is_empty() and str(l.get("tipo", "")) == "pacco"
	if pacco_cap != null:
		pacco_cap.visible = attivo
	if pacco_bar != null:
		pacco_bar.visible = attivo
	if not attivo or _player_ref == null or not is_instance_valid(_player_ref):
		if not attivo:
			GameManager.passo_pacco(delta, false)
		return

	var visto := false
	var p: Vector3 = _player_ref.global_position
	for gruppo in ["vigili", "carabinieri", "sbirri"]:
		for v in get_tree().get_nodes_in_group(gruppo):
			if not is_instance_valid(v) or not (v is Node3D):
				continue
			if (v as Node3D).global_position.distance_to(p) \
					> GameManager.PACCO_OCCHIO:
				continue
			# Il vigile sa dire se ti sta guardando davvero; carabinieri e
			# sbirri no, e per loro basta la distanza — chi ti insegue non
			# ha bisogno di un cono visivo per accorgersi di te.
			if v.has_method("can_see_player"):
				if v.can_see_player():
					visto = true
					break
			else:
				visto = true
				break
		if visto:
			break

	GameManager.passo_pacco(delta, visto)
	if pacco_bar != null:
		pacco_bar.value = GameManager.pacco_caldo
		UiStile.colora_barra(pacco_bar, Color(0.92, 0.28, 0.22)
			if GameManager.pacco_caldo > 55.0 else Color(0.96, 0.74, 0.28))
	if pacco_cap != null:
		pacco_cap.text = "'O pacco — %s" % ("TE STANNO GUARDANNO!" if visto
			else "portalo 'a %s" % str(l.get("nome_a", "")))
		pacco_cap.modulate = Color(1.0, 0.42, 0.34) if visto \
			else Color(1.0, 0.78, 0.42)


## **'A freccia verso casa.**
##
## Il vascio sta in un vicolo dietro alla piazza, e la prima prova sul campo
## ha detto la cosa più semplice del mondo: **non si trova**. Una porta in
## fondo a un vicolo, in una città di centonovanta metri, senza niente che
## la indichi, è una porta che non esiste.
##
## Adesso c'è una freccia — la stessa del cliente in attesa, che il
## giocatore ha già imparato a leggere — e compare quando serve davvero:
## quando sono passate le quattro (e l'unica cosa da fare è andare a
## coricarsi), oppure quando hai in tasca abbastanza per chiudere il conto
## della sera. Non sta lì sempre: sarebbe rumore.
func _update_bussola_casa() -> void:
	if casa_pointer == null or not is_instance_valid(casa_pointer):
		return
	if _player_ref == null or not is_instance_valid(_player_ref) \
			or GameManager.dentro_casa or not _dialogue_answers.is_empty():
		casa_pointer.text = ""
		return
	var dovuto: int = GameManager.spese_dovute()
	var serve: bool = GameManager.giornata_scaduta \
		or (dovuto > 0 and GameManager.money >= dovuto)
	if not serve:
		casa_pointer.text = ""
		return
	var vascio := get_tree().get_first_node_in_group("vascio")
	if vascio == null:
		casa_pointer.text = ""
		return
	var dove: Vector3 = vascio.punto_porta()
	var verso: Vector3 = dove - _player_ref.global_position
	verso.y = 0.0
	var dist: float = verso.length()
	if dist < 3.0:
		casa_pointer.text = "'A porta sta ccà — [E]"
		casa_pointer.modulate = Color(0.65, 1.0, 0.7)
		return
	var forward: Vector3 = -_player_ref.global_transform.basis.z
	var right: Vector3 = _player_ref.global_transform.basis.x
	var ahead: float = verso.normalized().dot(forward.normalized())
	var side: float = verso.dot(right)
	var arrow := "▲"
	if ahead < -0.4:
		arrow = "▼ gìrate"
	elif ahead <= 0.85:
		arrow = "▶ a destra" if side > 0.0 else "◀ a sinistra"
	var testo := "'A CASA"
	if GameManager.giornata_scaduta:
		testo = "VA' A CASA"
	casa_pointer.text = "%s  %s — %d m" % [arrow, testo, int(round(dist))]
	casa_pointer.modulate = Color(1.0, 0.72, 0.34)


## Indica dove sta il cliente in attesa più vicino: distanza e da che parte
## girarsi. Sparisce mentre stai già dirigendo un'auto.
func _update_client_pointer() -> void:
	# Fuori dalla piazza tua non ci sono clienti tuoi. La freccia sparisce
	# del tutto: era la cosa che rendeva fastidioso girare per la città.
	if not GameManager.in_servizio:
		client_pointer.text = ""
		return
	if not _dialogue_answers.is_empty():
		client_pointer.text = "" # sto parlando con Borrelli
		return
	if _player_ref == null or not is_instance_valid(_player_ref):
		client_pointer.text = ""
		return
	if _player_ref.get("directing_car") != null:
		client_pointer.text = ""
		return

	var best: Node3D = null
	var best_dist := INF
	for car in get_tree().get_nodes_in_group("cars"):
		if car.state != 1: # WAITING
			continue
		# **Sulo 'e clienti 'e sta piazza** (0.64). Con quattro piazze tue la
		# freccia puntava il cliente più vicino di tutta la città: al
		# mercato, a volte, quello che aspettava a casa.
		if GameManager.zona_corrente != "" \
				and str(car.get("zona_id")) != GameManager.zona_corrente:
			continue
		var d: float = _player_ref.global_position.distance_to(car.global_position)
		if d < best_dist:
			best_dist = d
			best = car
	if best == null:
		client_pointer.text = ""
		return

	if best_dist < 3.5:
		client_pointer.text = ""
		return

	var to_car: Vector3 = best.global_position - _player_ref.global_position
	to_car.y = 0.0
	var forward: Vector3 = -_player_ref.global_transform.basis.z
	var right: Vector3 = _player_ref.global_transform.basis.x
	var ahead: float = to_car.normalized().dot(forward.normalized())
	var side: float = to_car.dot(right)

	var arrow := ""
	if ahead > 0.85:
		arrow = "▲"
	elif ahead < -0.4:
		arrow = "▼ dietro di te"
	elif side > 0.0:
		arrow = "▶ a destra"
	else:
		arrow = "◀ a sinistra"
	client_pointer.text = "%s  cliente in attesa — %d m" % [arrow, int(round(best_dist))]


## Dove sta lo stemma più vicino da svitare. Compare solo per le auto già
## parcheggiate (prima di allora non ci arrivi comunque).
func _update_emblem_pointer() -> void:
	if emblem_pointer == null:
		return
	if not GameManager.in_servizio:
		emblem_pointer.text = ""
		return
	if not _dialogue_answers.is_empty() or _player_ref == null \
			or not is_instance_valid(_player_ref):
		emblem_pointer.text = ""
		return
	if _player_ref.get("directing_car") != null:
		emblem_pointer.text = ""
		return

	var best: Node3D = null
	var best_dist := INF
	for car in get_tree().get_nodes_in_group("cars"):
		if not car.has_emblem or car.state != 3: # 3 = PARKED
			continue
		var d: float = _player_ref.global_position.distance_to(car.global_position)
		if d < best_dist:
			best_dist = d
			best = car
	if best == null:
		emblem_pointer.text = ""
		return
	if best_dist < 4.0:
		# Da vicino lo dice già la riga dei comandi sotto al mirino, se la
		# stai guardando; se no, un promemoria corto.
		var riga_piena: bool = prompt_label != null and prompt_label.visible
		emblem_pointer.text = "" if riga_piena else \
			Pad.traduci("★  guarda 'a machina e premi [G] pe' svità 'o stemma")
		return
	emblem_pointer.text = "★  stemma da fottere %s — %d m" % [
		_direction_hint(best.global_position), int(round(best_dist))]


## "▲", "◀ a sinistra", ecc. rispetto a dove guarda il player.
func _direction_hint(target: Vector3) -> String:
	var to: Vector3 = target - _player_ref.global_position
	to.y = 0.0
	var forward: Vector3 = -_player_ref.global_transform.basis.z
	var right: Vector3 = _player_ref.global_transform.basis.x
	var ahead: float = to.normalized().dot(forward.normalized())
	if ahead > 0.85:
		return "▲ dritto"
	if ahead < -0.4:
		return "▼ dietro di te"
	return "▶ a destra" if to.dot(right) > 0.0 else "◀ a sinistra"


# ---------------------------------------------------------------------------
# Borseggio: barra rossa con tratti verdi e un cursore che rimbalza
# ---------------------------------------------------------------------------

const PICK_W := 560.0
const PICK_H := 34.0


func _build_pickpocket_ui() -> void:
	pick_panel = Panel.new()
	pick_panel.set_anchors_preset(Control.PRESET_CENTER)
	pick_panel.position = Vector2(-PICK_W / 2.0 - 20.0, -70.0)
	pick_panel.size = Vector2(PICK_W + 40.0, 132.0)
	pick_panel.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.09, 0.13, 0.96)
	style.border_color = Color(1.0, 0.83, 0.33)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 14
	pick_panel.add_theme_stylebox_override("panel", style)
	add_child(pick_panel)

	var title := Label.new()
	title.position = Vector2(20, 10)
	title.size = Vector2(PICK_W, 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(1.0, 0.83, 0.33))
	title.text = "Mano leggera…"
	pick_panel.add_child(title)

	pick_track = ColorRect.new()
	pick_track.position = Vector2(20, 46)
	pick_track.size = Vector2(PICK_W, PICK_H)
	pick_track.color = Color(0.62, 0.14, 0.13)
	pick_panel.add_child(pick_track)

	pick_cursor = ColorRect.new()
	pick_cursor.size = Vector2(6, PICK_H + 12)
	pick_cursor.color = Color(1, 1, 1)
	pick_panel.add_child(pick_cursor)

	pick_hint = Label.new()
	pick_hint.position = Vector2(20, 96)
	pick_hint.size = Vector2(PICK_W, 24)
	pick_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pick_hint.add_theme_font_size_override("font_size", 14)
	pick_hint.add_theme_color_override("font_color", Color(0.88, 0.88, 0.84))
	pick_hint.text = Pad.traduci("CLICCA quando il cursore sta sul verde")
	pick_panel.add_child(pick_hint)


func _on_pickpocket_started(target: Node) -> void:
	if pick_panel == null:
		_build_pickpocket_ui()
		_disable_mouse_capture_on_all_controls(pick_panel)
	_pick_target = target
	_pick_pos = 0.0
	_pick_dir = 1.0

	# Le zone verdi: due o tre tratti, più stretti se la borsa vale tanto.
	for child in pick_track.get_children():
		child.queue_free()
	_pick_zones.clear()
	var value: int = int(target.purse_value) if target else 5
	var band: float = clampf(0.16 - value * 0.008, 0.06, 0.16)
	var count: int = 3 if randf() < 0.5 else 2
	_pick_speed = randf_range(0.75, 1.05) + value * 0.02
	for i in count:
		# distribuite senza sovrapporsi: una per fetta della barra
		var slot_start: float = float(i) / float(count)
		var slot_end: float = float(i + 1) / float(count) - band
		var a: float = randf_range(slot_start, maxf(slot_start, slot_end))
		_pick_zones.append([a, a + band])

		var zone := ColorRect.new()
		zone.position = Vector2(a * PICK_W, 0)
		zone.size = Vector2(band * PICK_W, PICK_H)
		zone.color = Color(0.28, 0.72, 0.32)
		pick_track.add_child(zone)

	pick_hint.text = Pad.traduci("CLICCA quando il cursore sta sul verde")
	_pick_left = 12.0
	pick_panel.visible = true
	SoundManager.play("pop", -10.0, 1.3)


func _update_pickpocket(delta: float) -> void:
	if pick_panel == null or not pick_panel.visible:
		return
	if _pick_target == null or not is_instance_valid(_pick_target):
		_close_pickpocket()
		return
	# Rete di sicurezza: se per qualunque motivo il tasto non arriva, dopo
	# dodici secondi la barra si chiude da sola invece di restare li' per
	# sempre. Una finestra che non si chiude e' un gioco rotto; una che si
	# chiude da sola e' solo un tentativo andato a vuoto.
	_pick_left -= delta
	if _pick_left <= 0.0:
		pick_hint.text = Pad.traduci("Troppo tardi. Lassa sta'.")
		_rinuncia_pickpocket()
		return
	_pick_pos += _pick_dir * _pick_speed * delta
	if _pick_pos >= 1.0:
		_pick_pos = 1.0
		_pick_dir = -1.0
	elif _pick_pos <= 0.0:
		_pick_pos = 0.0
		_pick_dir = 1.0
	pick_cursor.position = Vector2(
		20.0 + _pick_pos * PICK_W - 3.0, pick_track.position.y - 6.0)


func _resolve_pickpocket() -> void:
	var hit := false
	for z in _pick_zones:
		if _pick_pos >= z[0] and _pick_pos <= z[1]:
			hit = true
			break
	var target := _pick_target
	_close_pickpocket()
	if target and is_instance_valid(target):
		target.resolve_pickpocket(hit)


## Lasciar perdere: si chiude e basta, senza esito. La differenza con
## `_resolve_pickpocket()` e' che li' un colpo mancato ti fa beccare.
func _rinuncia_pickpocket() -> void:
	var target := _pick_target
	_close_pickpocket()
	if target and is_instance_valid(target) and target.has_method("annulla_pickpocket"):
		target.annulla_pickpocket()


func _close_pickpocket() -> void:
	_pick_target = null
	_pick_zones.clear()
	if pick_panel:
		pick_panel.visible = false
	GameManager.pickpocket_closed.emit()


func _toggle_mappa() -> void:
	if mappa == null:
		return
	if mappa.visible:
		mappa.chiudi()
		return
	var citta := get_tree().get_first_node_in_group("citta")
	mappa.apri(citta, _player_ref)


## Vero mentre la barra è a schermo: il player non deve tirare pugni.
func is_pickpocket_open() -> bool:
	return pick_panel != null and pick_panel.visible


## Compare solo quando il gioco vuole il mouse preso e il browser non
## gliel'ha dato. Sul desktop questa condizione non si verifica mai.
func _avvisa_d_o_mouse() -> void:
	if mouse_hint == null or not is_instance_valid(mouse_hint):
		return
	var serve: bool = GameManager.o_mouse_s_ha_da_piglià() \
		and not GameManager.intro_active \
		and not get_tree().paused \
		and _dialogue_answers.is_empty()
	if serve and mouse_hint.text == "":
		mouse_hint.text = "Clicca cu 'o mouse pe' te 'o ripiglià"
	mouse_hint.visible = serve


## **'O cruscotto d''a machina rubata** (0.57).
##
## Velocità, quanto manca al garage, e la freccia che dice da che parte sta.
## Si accende da solo quando `GameManager.auto_guidata` non è vuoto e si
## spegne quando scendi: nessuno deve chiamarlo, nessuno deve ricordarsi di
## spegnerlo — che è la ragione per cui alla 0.49 il pannello della bacheca
## restava acceso a schermo.
##
## **'A freccia è 'nu carattere, no 'na texture.** Otto frecce Unicode e
## l'angolo fra dove guardi e dov'è il garage: costa niente, si legge a
## colpo d'occhio anche di notte, e soprattutto **non ha coordinate scritte
## a mano** — il garage si fa trovare da solo nel gruppo "garage", quindi se
## domani lo spostiamo di nuovo la freccia continua a puntarlo.
const FRECCE := ["↑", "↗", "→", "↘", "↓", "↙", "←", "↖"]

func _cruscotto() -> void:
	if cruscotto == null or not is_instance_valid(cruscotto):
		return
	var auto: Node = GameManager.auto_guidata
	var guido: bool = auto != null and is_instance_valid(auto) \
		and auto is Node3D
	cruscotto.visible = guido
	cruscotto_freccia.visible = guido
	if not guido:
		return

	var a3: Node3D = auto as Node3D
	# La velocità la sa l'auto: si legge la sua, non se ne ricalcola una
	# seconda che poi non coincide (il numero che guarda il gioco e il numero
	# che guarda la prova devono essere lo stesso — 'a lezione d''a 0.56b).
	var v: float = Vector2(a3.velocity.x, a3.velocity.z).length()
	var kmh: int = int(round(v * 3.6))

	var g: Node3D = null
	var d_min: float = 1e9
	for n in get_tree().get_nodes_in_group("garage"):
		if not (n is Node3D):
			continue
		var d: float = a3.global_position.distance_to((n as Node3D).global_position)
		if d < d_min:
			d_min = d
			g = n as Node3D
	if g == null:
		cruscotto.text = "%d km/h" % kmh
		cruscotto_freccia.text = ""
		return

	cruscotto.text = "%d km/h   ·   'o garage sta a %d metre   ·   [E] scinne" \
		% [kmh, int(round(d_min))]

	# L'angolo fra il muso della macchina e il garage. Il muso è −basis.z
	# (i fari stanno a −Z: vedi `POSTO_GUIDA` in `car_3d.gd`).
	var muso: Vector3 = -a3.global_transform.basis.z
	var verso: Vector3 = g.global_position - a3.global_position
	verso.y = 0.0
	if verso.length() < 0.01:
		cruscotto_freccia.text = "●"
		return
	var ang: float = atan2(muso.x, muso.z) - atan2(verso.normalized().x,
		verso.normalized().z)
	while ang < -PI:
		ang += TAU
	while ang > PI:
		ang -= TAU
	# Otto settori da quarantacinque gradi, con lo zero centrato sul "dritto".
	var i: int = int(round(ang / (TAU / 8.0))) % 8
	if i < 0:
		i += 8
	cruscotto_freccia.text = FRECCE[i]
	cruscotto_freccia.modulate = Color(0.55, 0.95, 0.55) if d_min < 24.0 \
		else Color(1.0, 0.72, 0.26)


func _build_ui() -> void:
	# =====================================================================
	# **'A faccia nova d''o HUD (0.62).**
	#
	# Il capo: *«Alza un po' le scritte dei tasti da premere perché stanno
	# davanti ad altri elementi UI. Rivedi l'intera UI per farla più
	# leggibile e bella possibile»*.
	#
	# Fino alla 0.61 ogni scritta dell'HUD era una `Label` con la sua `y`
	# scritta a mano (trappola 29), senza sfondo, sopra al 3D: la riga dei
	# tasti a −90 dal fondo si sovrapponeva alla bussola di casa (−104),
	# alla barra delle armi (−76) e al segnale dello stemma (−56). Adesso
	# l'HUD è fatto di **quattro scatole** che si impilano da sole:
	#
	#   - in alto a sinistra la **scheda del parcheggiatore**: soldi, le
	#     quattro barre con la loro icona, e sotto le righe che cambiano
	#     (stemmi, sigarette, commissione);
	#   - in alto a destra la **scheda della giornata**: ora, giorno, fascia,
	#     servizio, il conto della sera, le stelle;
	#   - sotto al mirino la **riga dei comandi**, coi tasti disegnati;
	#   - in basso al centro la **pila delle bussole** (cliente, casa,
	#     stemma) sopra alla barra delle armi, e in basso a destra la
	#     **chiantina piccerella**.
	#
	# I nomi delle variabili sono quelli di prima: il resto del file non se
	# ne accorge.
	# =====================================================================
	const US := preload("res://scripts/ui_stile.gd")

	# --- In alto a sinistra: 'a scheda d''o parcheggiatore ----------------
	var scheda := PanelContainer.new()
	scheda.name = "SchedaParcheggiatore"
	scheda.add_theme_stylebox_override("panel", US.scheda())
	scheda.position = Vector2(14, 12)
	scheda.custom_minimum_size = Vector2(286, 0)
	scheda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scheda)
	_scheda_sx = scheda
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scheda.add_child(col)

	var riga_soldi := HBoxContainer.new()
	riga_soldi.add_theme_constant_override("separation", 8)
	riga_soldi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(riga_soldi)
	riga_soldi.add_child(US.figura("euro", 24, US.ORO))
	money_label = _make_label(Vector2.ZERO, "0", 26)
	money_label.add_theme_font_override("font", US.font_titolo())
	money_label.add_theme_color_override("font_color", US.ORO_CHIARO)
	riga_soldi.add_child(money_label)

	# **La scritta sta SOPRA la sua barra, non sotto** (0.5x). Adesso c'è
	# anche l'icona: l'occhio (chi ti guarda), il pacco, il cuore, il
	# fulmine. Si riconoscono senza leggere.
	var riga_sosp := _riga_barra(col, "occhio", "Sospetto vigili", US.VERDE)
	heat_bar = riga_sosp["barra"]
	_riga_sospetto = riga_sosp["riga"]
	var riga_pacco := _riga_barra(col, "pacco", "'O pacco", US.GIALLO)
	pacco_bar = riga_pacco["barra"]
	pacco_cap = riga_pacco["dida"]
	pacco_cap.modulate = Color(1.0, 0.78, 0.42)
	_riga_pacco = riga_pacco["riga"]
	_riga_pacco.visible = false
	pacco_cap.visible = false
	pacco_bar.visible = false
	var riga_hp := _riga_barra(col, "cuore", "HP", US.VERDE,
		GameManager.HEALTH_MAX)
	health_bar = riga_hp["barra"]
	health_caption = riga_hp["dida"]
	var riga_sc := _riga_barra(col, "fulmine", "SCIATO", US.AZZURRO,
		GameManager.SCIATO_MAX)
	sciato_bar = riga_sc["barra"]
	sciato_caption = riga_sc["dida"]

	# Le righe che cambiano: stemmi, commissione, sigarette, la consegna.
	# Dentro a una colonna sua, così quelle vuote non lasciano buchi.
	_righe_sx = VBoxContainer.new()
	_righe_sx.add_theme_constant_override("separation", 2)
	_righe_sx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_righe_sx)
	emblem_counter_label = _riga_testo(_righe_sx, Color(1.0, 0.85, 0.3))
	commission_label = _riga_testo(_righe_sx, Color(0.7, 0.95, 1.0))
	cig_label = _riga_testo(_righe_sx, Color(0.9, 0.85, 0.75))
	cumm_label = _riga_testo(_righe_sx, Color(0.65, 1.0, 0.72))

	# **'A versione, 'n basso a destra e piccerella** (0.56).
	var ver := Label.new()
	ver.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ver.position = Vector2(-118, -22)
	ver.size = Vector2(106, 16)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ver.add_theme_font_size_override("font_size", 11)
	ver.add_theme_color_override("font_color", Color(0.78, 0.76, 0.72, 0.62))
	ver.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	ver.add_theme_constant_override("outline_size", 4)
	ver.text = VERSIONE
	ver.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ver)

	# Velo rosso quando le prendi: sopra tutto, ma trasparente.
	hurt_flash = ColorRect.new()
	hurt_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	hurt_flash.color = Color(0.75, 0.05, 0.05, 0.0)
	hurt_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hurt_flash)

	# --- In alto a destra: 'a scheda d''a jurnata -------------------------
	var destra := PanelContainer.new()
	destra.name = "SchedaJurnata"
	destra.add_theme_stylebox_override("panel", US.scheda())
	destra.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	destra.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	destra.offset_left = -14.0 - 300.0
	destra.offset_right = -14.0
	destra.offset_top = 12.0
	destra.custom_minimum_size = Vector2(300, 0)
	destra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(destra)
	_scheda_dx = destra
	var cd := VBoxContainer.new()
	cd.add_theme_constant_override("separation", 2)
	cd.mouse_filter = Control.MOUSE_FILTER_IGNORE
	destra.add_child(cd)

	var riga_ora := HBoxContainer.new()
	riga_ora.alignment = BoxContainer.ALIGNMENT_END
	riga_ora.add_theme_constant_override("separation", 8)
	riga_ora.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cd.add_child(riga_ora)
	riga_ora.add_child(US.figura("orologio", 20, US.TESTO_2))
	timer_label = _make_label(Vector2.ZERO, "12:00", 26)
	timer_label.add_theme_font_override("font", US.font_titolo())
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	riga_ora.add_child(timer_label)

	# **'O juorno** e **'a fascia** (0.51): due righe, e il colore della
	# fascia dice da solo com'è l'ora.
	giorno_label = _riga_destra(cd, 14, Color(0.86, 0.84, 0.74))
	fascia_label = _riga_destra(cd, 14, Color(1, 1, 1))
	fascia_label.add_theme_font_override("font", US.font_grassetto())
	servizio_label = _riga_destra(cd, 15, Color(1, 1, 1))
	servizio_label.add_theme_font_override("font", US.font_grassetto())
	servizio_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	zona_label = _riga_destra(cd, 15, Color(1, 1, 1))

	# **'O conto d''a sera, sempe 'nnanze a ll'uocchie.** Un filo sopra, per
	# staccarlo dall'ora: è un'altra cosa.
	var filo := HSeparator.new()
	filo.add_theme_constant_override("separation", 6)
	filo.add_theme_stylebox_override("separator",
		US.box(Color(1, 1, 1, 0.10), Color(0, 0, 0, 0), 0, 0, 0.0, 0.0))
	filo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cd.add_child(filo)
	conto_label = _riga_destra(cd, 16, Color(1.0, 0.78, 0.42))
	conto_label.add_theme_font_override("font", US.font_grassetto())
	conto_voci = _riga_destra(cd, 12, Color(0.86, 0.80, 0.72))
	conto_voci.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# --- In cima al centro: gli annunci ------------------------------------
	# **'O cartiello ca asceva 'a fore ô schermo** (0.51): va a capo, ed è
	# largo al massimo `BANNER_MAX`; dalla 0.62 sta dentro a una pillola che
	# si stringe sul testo, e l'insegna del servizio e il cartello si
	# impilano invece di cadersi addosso.
	var alto := VBoxContainer.new()
	alto.name = "Annunci"
	alto.set_anchors_preset(Control.PRESET_TOP_WIDE)
	alto.offset_left = 330.0
	alto.offset_right = -330.0
	alto.offset_top = 118.0
	alto.add_theme_constant_override("separation", 6)
	alto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(alto)
	servizio_banner = _make_label(Vector2.ZERO, "", 28)
	servizio_banner.add_theme_font_override("font", US.font_titolo())
	servizio_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	servizio_banner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	alto.add_child(servizio_banner)
	servizio_sub = _make_label(Vector2.ZERO, "", 17)
	servizio_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	servizio_sub.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	US.a_pillola(servizio_sub)
	alto.add_child(servizio_sub)

	# Il cartello sta fuori dalla pila: è largo fino a `BANNER_MAX` e deve
	# poter essere più largo della colonna in mezzo alle due schede.
	event_banner = _make_label(Vector2(0, 0), "", 28)
	event_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	event_banner.position = Vector2(-BANNER_MAX * 0.5, 196)
	event_banner.size = Vector2(BANNER_MAX, 76)
	event_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	event_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_banner.pivot_offset = Vector2(BANNER_MAX * 0.5, 20)
	event_banner.modulate = Color(1.0, 0.6, 0.2)
	event_banner.add_theme_font_override("font", US.font_grassetto())
	US.a_pillola(event_banner, Color(1, 1, 1, 0.16), 0.78)
	add_child(event_banner)

	# **«Clicca pe' piglià 'o mouse»** (0.56b): solo sul browser.
	mouse_hint = _make_label(Vector2(0, 0), "", 20)
	mouse_hint.set_anchors_preset(Control.PRESET_CENTER)
	mouse_hint.position = Vector2(-260, 118)
	mouse_hint.size = Vector2(520, 30)
	mouse_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mouse_hint.modulate = Color(1.0, 0.88, 0.42)
	mouse_hint.visible = false
	add_child(mouse_hint)

	# **'O cruscotto** (0.57): si vede solo quando guidi una rubata.
	cruscotto = _make_label(Vector2(0, 0), "", 20)
	cruscotto.set_anchors_preset(Control.PRESET_CENTER)
	cruscotto.position = Vector2(-340, 176)
	cruscotto.size = Vector2(680, 34)
	cruscotto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cruscotto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cruscotto.modulate = Color(1.0, 0.86, 0.46)
	cruscotto.visible = false
	add_child(cruscotto)

	cruscotto_freccia = _make_label(Vector2(0, 0), "", 40)
	cruscotto_freccia.set_anchors_preset(Control.PRESET_CENTER)
	cruscotto_freccia.position = Vector2(-60, 126)
	cruscotto_freccia.size = Vector2(120, 48)
	cruscotto_freccia.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cruscotto_freccia.modulate = Color(1.0, 0.72, 0.26)
	cruscotto_freccia.visible = false
	add_child(cruscotto_freccia)

	# La targa della strada: in basso a sinistra, come le targhe di marmo
	# dei vicoli (bianca, lettere scure, cornice).
	strada_label = _make_label(Vector2(16, 0), "", 16)
	strada_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	strada_label.position = Vector2(16, -52)
	strada_label.add_theme_font_override("font", US.font_grassetto())
	strada_label.add_theme_color_override("font_color", Color(0.16, 0.13, 0.10))
	strada_label.add_theme_constant_override("outline_size", 0)
	var marmo := US.box(Color(0.96, 0.94, 0.89, 0.95),
		Color(0.36, 0.30, 0.24), 3, 4, 14.0, 5.0)
	marmo.shadow_color = Color(0, 0, 0, 0.35)
	marmo.shadow_size = 4
	strada_label.add_theme_stylebox_override("normal", marmo)
	add_child(strada_label)

	crosshair = Control.new()
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-3, -3)
	crosshair.size = Vector2(6, 6)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var anello := Panel.new()
	anello.size = Vector2(6, 6)
	anello.add_theme_stylebox_override("panel",
		US.box(Color(1, 1, 1, 0.9), Color(0, 0, 0, 0.55), 1, 3, 0.0, 0.0))
	anello.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair.add_child(anello)
	add_child(crosshair)
	# **'A crocetta** (0.61): quattro trattini obliqui attorno al mirino,
	# per un decimo di secondo, quando un colpo arriva addosso a qualcuno.
	_segno = Control.new()
	_segno.set_anchors_preset(Control.PRESET_CENTER)
	_segno.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(4):
		var tr := ColorRect.new()
		tr.size = Vector2(9, 2)
		tr.color = Color(1.0, 0.92, 0.8)
		tr.pivot_offset = Vector2(-7, 1)
		tr.position = Vector2(7, -1)
		tr.rotation = deg_to_rad(45.0 + 90.0 * i)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_segno.add_child(tr)
	_segno.modulate.a = 0.0
	add_child(_segno)

	# --- Sotto al mirino: 'a riga d''e comandi -----------------------------
	# Una colonna larga quanto lo schermo, che parte sessanta pixel sotto al
	# centro; la pillola dentro si stringe sul testo e sta in mezzo.
	var sotto_mirino := VBoxContainer.new()
	sotto_mirino.name = "SottoMirino"
	sotto_mirino.anchor_left = 0.0
	sotto_mirino.anchor_right = 1.0
	sotto_mirino.anchor_top = 0.5
	sotto_mirino.anchor_bottom = 0.5
	sotto_mirino.offset_top = 44.0
	sotto_mirino.offset_bottom = 44.0
	sotto_mirino.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sotto_mirino)
	prompt_label = preload("res://scripts/riga_comandi.gd").new()
	prompt_label.name = "RigaComandi"
	sotto_mirino.add_child(prompt_label)

	# --- In basso al centro: 'e bussole sopra a 'e mmane --------------------
	_pila_bassa = VBoxContainer.new()
	_pila_bassa.name = "PilaBassa"
	_pila_bassa.anchor_left = 0.0
	_pila_bassa.anchor_right = 1.0
	_pila_bassa.anchor_top = 1.0
	_pila_bassa.anchor_bottom = 1.0
	_pila_bassa.offset_left = 240.0
	_pila_bassa.offset_right = -240.0
	_pila_bassa.offset_top = -16.0
	_pila_bassa.offset_bottom = -16.0
	_pila_bassa.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_pila_bassa.alignment = BoxContainer.ALIGNMENT_END
	_pila_bassa.add_theme_constant_override("separation", 6)
	_pila_bassa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pila_bassa)

	# La freccia verso casa sta SOPRA quella del cliente: quando sono le
	# quattro del mattino è l'unica informazione che conta.
	casa_pointer = _pillola_bassa(18, Color(1.0, 0.72, 0.34))
	client_pointer = _pillola_bassa(17, Color(1.0, 0.9, 0.45))
	emblem_pointer = _pillola_bassa(15, Color(1.0, 0.82, 0.28))

	_build_directing_ui()
	_build_inventory_ui()
	_build_shop_ui()
	_build_boss_ui()
	_build_nemico_ui()
	_build_stelle_ui()
	_build_mano_ui()
	_build_freccia_ui()
	_build_presa_ui()
	mappa = MappaScript.new()
	mappa.name = "Mappa"
	add_child(mappa)
	# 'A chiantina piccerella, in basso a destra (0.62).
	_minimappa = preload("res://scripts/minimappa.gd").new()
	_minimappa.name = "Minimappa"
	var cornice := PanelContainer.new()
	cornice.name = "CorniceMinimappa"
	var st_c := US.box(Color(0.05, 0.055, 0.075, 0.7), Color(1, 1, 1, 0.16), 2,
		12, 4.0, 4.0)
	st_c.shadow_color = Color(0, 0, 0, 0.3)
	st_c.shadow_size = 6
	cornice.add_theme_stylebox_override("panel", st_c)
	cornice.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	cornice.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	cornice.grow_vertical = Control.GROW_DIRECTION_BEGIN
	cornice.offset_left = -14.0 - 198.0
	cornice.offset_right = -14.0
	cornice.offset_top = -30.0 - 198.0
	cornice.offset_bottom = -30.0
	cornice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cornice.add_child(_minimappa)
	add_child(cornice)
	_cornice_minimappa = cornice
	_aggancia_minimappa.call_deferred()
	_build_summary_ui()


# ---------------------------------------------------------------------------
# I pezzi dell'HUD nuovo (0.62)
# ---------------------------------------------------------------------------

## La larghezza massima del cartello degli eventi (vedi `prova_cartielle`).
const BANNER_MAX: float = 1100.0

var _scheda_sx: PanelContainer
var _scheda_dx: PanelContainer
var _righe_sx: VBoxContainer
var _riga_sospetto: Control
var _riga_pacco: Control
var _pila_bassa: VBoxContainer
var _minimappa: Control
var _cornice_minimappa: Control
var _banner_ultimo: String = ""


## Una riga con l'icona, la didascalia sopra e la barra sotto.
func _riga_barra(dove: Control, icona: String, dida: String, colore: Color,
		massimo: float = 100.0) -> Dictionary:
	const US := preload("res://scripts/ui_stile.gd")
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 8)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dove.add_child(r)
	r.add_child(US.figura(icona, 18, colore.lerp(Color(1, 1, 1), 0.25)))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_child(v)
	var l := _make_label(Vector2.ZERO, dida, 12)
	l.add_theme_font_override("font", US.font_grassetto())
	l.modulate = Color(0.86, 0.86, 0.88)
	v.add_child(l)
	var b := US.barra(colore, 9.0, massimo)
	v.add_child(b)
	return {"riga": r, "dida": l, "barra": b}


func _riga_testo(dove: Control, colore: Color) -> Label:
	var l := _make_label(Vector2.ZERO, "", 13)
	l.modulate = colore
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(262, 0)
	l.visible = false
	dove.add_child(l)
	return l


func _riga_destra(dove: Control, corpo: int, colore: Color) -> Label:
	var l := _make_label(Vector2.ZERO, "", corpo)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.modulate = colore
	l.custom_minimum_size = Vector2(276, 0)
	dove.add_child(l)
	return l


func _pillola_bassa(corpo: int, colore: Color) -> Label:
	const US := preload("res://scripts/ui_stile.gd")
	var l := _make_label(Vector2.ZERO, "", corpo)
	l.add_theme_font_override("font", US.font_grassetto())
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	l.modulate = colore
	l.add_theme_constant_override("outline_size", 0)
	US.a_pillola(l, Color(colore.r, colore.g, colore.b, 0.35), 0.74)
	l.visible = false
	_pila_bassa.add_child(l)
	return l


func _aggancia_minimappa() -> void:
	if _minimappa == null:
		return
	var citta := get_tree().get_first_node_in_group("citta")
	if citta == null:
		citta = get_tree().get_root().find_child("Citta", true, false)
	_minimappa.aggancia(citta, _player_ref)


## Le scritte che hanno uno sfondo si spengono quando sono vuote: se no
## resta la pillola vuota a schermo. Si chiama ogni frame (costa niente).
func _spegni_vuote() -> void:
	for l in [servizio_sub, casa_pointer, client_pointer, emblem_pointer,
			emblem_counter_label, commission_label, cig_label, cumm_label,
			zona_label, strada_label, servizio_banner]:
		if l != null:
			var pieno: bool = (l as Label).text != ""
			if (l as Label).visible != pieno:
				(l as Label).visible = pieno
	if event_banner != null and event_banner.text != _banner_ultimo:
		_banner_ultimo = event_banner.text
		_adatta_banner()
	if event_banner != null:
		event_banner.visible = event_banner.text != ""
	if _riga_pacco != null and pacco_bar != null:
		_riga_pacco.visible = pacco_bar.visible
	if _cornice_minimappa != null:
		# Mentre guidi una rubata, o con la chiantina grande aperta, la
		# piccola si fa da parte.
		_cornice_minimappa.visible = not ((mappa != null and mappa.visible)
			or (inventory_panel != null and inventory_panel.visible)
			or (shop_panel != null and shop_panel.visible)
			or (summary_panel != null and summary_panel.visible)
			or GameManager.auto_guidata != null)


## Il cartello si stringe sul testo (fino a `BANNER_MAX`) e resta centrato.
##
## Attenzione: a HUD già nell'albero `position` è in coordinate dello
## schermo, non l'offset dall'ancora — per restare centrato si scrivono gli
## `offset_*` (a costruzione, fuori dall'albero, le due cose coincidevano).
func _adatta_banner() -> void:
	if event_banner == null or event_banner.text == "":
		return
	var f: Font = event_banner.get_theme_font("font")
	var corpo: int = event_banner.get_theme_font_size("font_size")
	var w: float = f.get_string_size(event_banner.text, HORIZONTAL_ALIGNMENT_LEFT,
		-1, corpo).x + 44.0
	w = clampf(w, 160.0, BANNER_MAX)
	event_banner.offset_left = -w * 0.5
	event_banner.offset_right = w * 0.5
	event_banner.offset_top = 196.0
	event_banner.offset_bottom = 196.0 + 40.0
	event_banner.pivot_offset = Vector2(w * 0.5, 20)


## Il boss: barra della furia in alto e il riquadro delle risposte.
## Restano nascosti finché Borrelli non arriva.
func _build_boss_ui() -> void:
	boss_panel = Panel.new()
	boss_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_panel.position = Vector2(-190, 8)
	boss_panel.size = Vector2(380, 58)
	boss_panel.visible = false
	add_child(boss_panel)

	var title := Label.new()
	title.position = Vector2(10, 4)
	title.size = Vector2(360, 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(1.0, 0.55, 0.35))
	title.text = "BORRELLI — furia"
	boss_panel.add_child(title)

	boss_furia_bar = ProgressBar.new()
	boss_furia_bar.position = Vector2(14, 26)
	boss_furia_bar.size = Vector2(352, 14)
	boss_furia_bar.min_value = 0
	boss_furia_bar.max_value = 100
	boss_furia_bar.value = 100
	boss_furia_bar.show_percentage = false
	boss_panel.add_child(boss_furia_bar)

	boss_hint = Label.new()
	boss_hint.position = Vector2(10, 40)
	boss_hint.size = Vector2(360, 18)
	boss_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_hint.add_theme_font_size_override("font_size", 12)
	boss_hint.add_theme_color_override("font_color", Color(0.85, 0.85, 0.8))
	boss_panel.add_child(boss_hint)


## **'E stelle 'e ricercato.**
##
## Disegnate a mano con `draw_colored_polygon` e non scritte con un
## carattere: il font di ripiego di Godot le stelline ce le ha, ma non è
## detto che ce le abbia su tutte le macchine, e una stella che su un PC
## diventa un quadratino vuoto è peggio di niente. Cinque poligoni costano
## nulla e vengono uguali dappertutto.
##
## Stanno in alto a destra, sotto all'orologio, che è dove uno le cerca.
## **La barra della mano, in basso al centro.**
##
## Prima quello che tenevi in mano non stava scritto da nessuna parte: lo
## sapevi solo per un secondo, dal messaggio che compariva premendo G, e
## poi ti restava da indovinare. Con quattro armi che fanno danni da 7 a 40
## e una che spara, non sapere che cosa hai in pugno e' il genere di cosa
## che fa perdere una partita senza capire perche'.
##
## La barra mostra tre caselle: quello che avevi prima, quello che tieni
## adesso (grande, illuminato) e quello dopo. Cosi' la rotella si capisce
## da sola — si vede da che parte si sta andando.
## **La freccia rossa: da dove ti stanno menando.**
##
## In prima persona quello che sta dietro non esiste: se ti prendono alle
## spalle vedi solo lo schermo che lampeggia rosso, e la reazione naturale
## e' girarsi a caso — che di solito e' la parte sbagliata. La freccia sta
## attorno al mirino e punta verso chi ti ha colpito: dura un paio di
## secondi e si spegne da sola.
func _build_freccia_ui() -> void:
	freccia_ui = Control.new()
	freccia_ui.set_anchors_preset(Control.PRESET_CENTER)
	freccia_ui.size = Vector2(2, 2)
	freccia_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	freccia_ui.set_script(preload("res://scripts/freccia_minaccia.gd"))
	add_child(freccia_ui)


func _on_minaccia(posizione: Vector3) -> void:
	if freccia_ui == null or _player_ref == null \
			or not is_instance_valid(_player_ref):
		return
	var cam: Camera3D = _player_ref.get("camera")
	if cam == null:
		return
	# L'angolo fra dove stai guardando e dove sta la minaccia, sul piano
	# orizzontale. Zero = dritto davanti, positivo = a destra.
	var verso: Vector3 = posizione - cam.global_position
	verso.y = 0.0
	if verso.length() < 0.2:
		return
	verso = verso.normalized()
	var avanti: Vector3 = -cam.global_transform.basis.z
	avanti.y = 0.0
	if avanti.length() < 0.01:
		return
	avanti = avanti.normalized()
	var destra: Vector3 = cam.global_transform.basis.x
	destra.y = 0.0
	var ang: float = atan2(destra.normalized().dot(verso), avanti.dot(verso))
	freccia_ui.punta(ang)


func _build_mano_ui() -> void:
	mano_ui = HBoxContainer.new()
	# 0.62: ultima della pila in basso al centro, sotto alle bussole.
	mano_ui.alignment = BoxContainer.ALIGNMENT_CENTER
	mano_ui.add_theme_constant_override("separation", 8)
	mano_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _pila_bassa != null:
		_pila_bassa.add_child(mano_ui)
	else:
		add_child(mano_ui)
	for i in range(3):
		# **Le caselle si allargano sul testo, non il contrario.**
		#
		# Prima erano tre Panel di larghezza fissa con dentro un Label
		# ancorato: "'A mazza 'e fierro  2/3" non ci stava in 104 pixel, e
		# siccome un Label non taglia il testo da solo, la scritta usciva
		# dalla casella e finiva a cavallo di quella accanto — a schermo si
		# leggeva "2/'O curtiello". Con PanelContainer + MarginContainer la
		# casella prende la misura dal testo e il problema non esiste.
		var casella := PanelContainer.new()
		var sb := UiStile.box(Color(0.05, 0.055, 0.075, 0.82 if i == 1 else 0.5),
			Color(UiStile.ORO.r, UiStile.ORO.g, UiStile.ORO.b, 0.95) if i == 1
			else Color(1, 1, 1, 0.14), 2 if i == 1 else 1, 10, 14.0, 6.0)
		casella.add_theme_stylebox_override("panel", sb)
		casella.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var et := Label.new()
		et.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		et.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		et.add_theme_font_size_override("font_size", 15 if i == 1 else 12)
		if i == 1:
			et.add_theme_font_override("font", UiStile.font_grassetto())
		et.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		et.add_theme_constant_override("outline_size", 3)
		et.modulate = Color(1, 1, 1) if i == 1 else Color(0.70, 0.70, 0.74)
		et.mouse_filter = Control.MOUSE_FILTER_IGNORE
		casella.add_child(et)
		_mano_etichette.append(et)
		mano_ui.add_child(casella)
	_aggiorna_mano("")


func _aggiorna_mano(_id: String) -> void:
	if _mano_etichette.size() < 3:
		return
	var mie: Array = GameManager.roba_in_mano()
	if mie.is_empty():
		return
	var i: int = maxi(0, mie.find(GameManager.arma_in_mano))
	for k in range(3):
		var j: int = posmod(i + k - 1, mie.size())
		var id: String = str(mie[j])
		var nome: String = "'E mmane"
		if GameManager.ARMI.has(id):
			nome = str(GameManager.ARMI[id]["nome"])
		# Con una cosa sola in mano le tre caselle direbbero tutte la
		# stessa: le due laterali si svuotano.
		if mie.size() == 1 and k != 1:
			nome = "—"
		elif k == 0:
			nome = "◂  " + nome
		elif k == 2:
			nome = nome + "  ▸"
		_mano_etichette[k].text = nome
	# Il contatore va sotto, non attaccato al nome: attaccato allungava la
	# casella di mezzo di venti pixel a ogni cambio d'arma, e la fila
	# ballava.
	if mie.size() > 1:
		_mano_etichette[1].tooltip_text = "%d/%d" % [i + 1, mie.size()]


func _build_stelle_ui() -> void:
	stelle_ui = Control.new()
	# 0.62: dentro alla scheda della giornata, sotto all'ora; la scheda
	# le fa posto da sola quando compaiono.
	stelle_ui.custom_minimum_size = Vector2(160, 32)
	stelle_ui.size_flags_horizontal = Control.SIZE_SHRINK_END
	stelle_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stelle_ui.set_script(preload("res://scripts/stelle.gd"))
	stelle_ui.visible = GameManager.stelle > 0
	if _scheda_dx != null:
		(_scheda_dx.get_child(0) as VBoxContainer).add_child(stelle_ui)
		(_scheda_dx.get_child(0) as VBoxContainer).move_child(stelle_ui, 1)
	else:
		add_child(stelle_ui)


func _on_stelle_cambiate(quante: int) -> void:
	_stelle = quante
	# Cinque stelle vuote sempre a schermo sono cinque cose da guardare che
	# non dicono niente. Quando non sei ricercato, la fila non c'e'.
	if stelle_ui != null:
		stelle_ui.visible = quante > 0
	if stelle_ui != null:
		stelle_ui.quante = quante
		stelle_ui.lampeggia()
	if quante > 0:
		event_banner.text = "★ %d — 'E CARABINIERI TE CERCANO. ANNASCUÓNNETE." % quante
		event_banner.modulate = Color(1.0, 0.82, 0.25)
		_banner_time = 2.6


## La colluttazione: ti tengono, e devi menare per sciogliderti.
func _build_presa_ui() -> void:
	presa_panel = Panel.new()
	presa_panel.set_anchors_preset(Control.PRESET_CENTER)
	presa_panel.position = Vector2(-210, 60)
	presa_panel.size = Vector2(420, 74)
	presa_panel.visible = false
	presa_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(presa_panel)

	presa_hint = Label.new()
	presa_hint.position = Vector2(10, 6)
	presa_hint.size = Vector2(400, 26)
	presa_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	presa_hint.add_theme_font_size_override("font_size", 18)
	presa_hint.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	presa_panel.add_child(presa_hint)

	presa_bar = ProgressBar.new()
	presa_bar.position = Vector2(16, 38)
	presa_bar.size = Vector2(388, 20)
	presa_bar.min_value = 0
	presa_bar.max_value = 100
	presa_bar.value = 0
	presa_bar.show_percentage = false
	presa_panel.add_child(presa_bar)


func _on_presa_iniziata() -> void:
	if presa_panel == null:
		return
	presa_panel.visible = true
	# **'O terzo fermo se legge subito.** Se il pannello dicesse "clicca a
	# ripetizione" pure quando cliccare non serve, il giocatore penserebbe
	# di aver cliccato male — invece la partita l'ha persa prima.
	if GameManager.fermi_oggi >= GameManager.FERMI_PRIMMA_D_A_CELLA:
		presa_hint.text = "TERZO FERMO — NUN TE SCIUOGLIE CCHIÙ"
		presa_hint.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
	else:
		presa_hint.text = Pad.traduci("T'HANNO PIGLIATO — CLICCA A RIPETIZIONE!")
		presa_hint.remove_theme_color_override("font_color")
	presa_bar.value = 0


func _on_presa_finita() -> void:
	if presa_panel:
		presa_panel.visible = false


func _on_presa_stato(forza: float, tempo: float) -> void:
	if presa_panel == null or not presa_panel.visible:
		return
	var secca: bool = GameManager.fermi_oggi >= GameManager.FERMI_PRIMMA_D_A_CELLA
	# Nella presa secca la barra non conta la forza (che resta a zero): conta
	# il tempo che manca alle manette, e si riempie da sola.
	presa_bar.value = (1.0 - tempo if secca else forza) * 100.0
	var st := StyleBoxFlat.new()
	# Verde quando stai per farcela, rosso quando il tempo sta finendo.
	st.bg_color = Color(0.9, 0.3, 0.2) if secca \
		else Color(0.30, 0.75, 0.35).lerp(Color(0.9, 0.3, 0.2),
			clampf(1.0 - tempo, 0.0, 1.0))
	st.set_corner_radius_all(3)
	presa_bar.add_theme_stylebox_override("fill", st)


## La barra HP di chi stai menando.
##
## Compare sotto al mirino al primo colpo e resta su finché si mena; poi
## sfuma. Serve a rendere leggibile una cosa che prima era alla cieca: un
## rivale ha quaranta punti, un vigile quattordici, il furgone dei
## carabinieri sessanta, e a mani nude se ne toglievano tre per volta. Senza
## un numero davanti non si capiva se mancava un colpo o venti — ed è il
## motivo per cui "hanno troppa HP" sembrava un muro invece che un invito a
## comprare 'a mazza e fierr'.
func _build_nemico_ui() -> void:
	nemico_panel = Panel.new()
	nemico_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	nemico_panel.position = Vector2(-140, 74)
	nemico_panel.size = Vector2(280, 42)
	nemico_panel.visible = false
	nemico_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(nemico_panel)

	nemico_nome = Label.new()
	nemico_nome.position = Vector2(8, 3)
	nemico_nome.size = Vector2(264, 18)
	nemico_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nemico_nome.add_theme_font_size_override("font_size", 13)
	nemico_nome.add_theme_color_override("font_color", Color(1.0, 0.8, 0.6))
	nemico_panel.add_child(nemico_nome)

	nemico_bar = ProgressBar.new()
	nemico_bar.position = Vector2(12, 22)
	nemico_bar.size = Vector2(256, 13)
	nemico_bar.min_value = 0
	nemico_bar.max_value = 100
	nemico_bar.value = 100
	nemico_bar.show_percentage = false
	nemico_panel.add_child(nemico_bar)


func _on_nemico_colpito(nome: String, hp: int, hp_max: int) -> void:
	if nemico_panel == null:
		return
	nemico_panel.visible = true
	nemico_panel.modulate.a = 1.0
	_nemico_time = 4.5
	nemico_bar.max_value = maxi(1, hp_max)
	nemico_bar.value = hp
	var q: float = float(hp) / float(maxi(1, hp_max))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.85, 0.25, 0.22) if q > 0.0 else Color(0.4, 0.4, 0.42)
	style.set_corner_radius_all(3)
	nemico_bar.add_theme_stylebox_override("fill", style)
	if hp <= 0:
		nemico_nome.text = "%s — STISO" % nome
		_nemico_time = 1.6
	else:
		nemico_nome.text = "%s — HP %d/%d" % [nome, hp, hp_max]


## Le quattro risposte. Si sceglie coi tasti 1-4 (gli stessi del negozio,
## che mentre parli con Borrelli non serve).
func _build_dialogue_ui() -> void:
	dialogue_panel = Panel.new()
	dialogue_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dialogue_panel.position = Vector2(-330, -230)
	dialogue_panel.size = Vector2(660, 210)
	dialogue_panel.visible = false
	# Fondo pieno: col pannello traslucido di serie il prompt e la bussola
	# si leggevano attraverso le risposte.
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.09, 0.13, 0.97)
	style.border_color = Color(1.0, 0.83, 0.33)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 14
	dialogue_panel.add_theme_stylebox_override("panel", style)
	add_child(dialogue_panel)

	var title := Label.new()
	title.position = Vector2(14, 10)
	title.size = Vector2(632, 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.83, 0.33))
	title.text = "E mo' che ce dici? (premi 1, 2, 3 o 4)"
	dialogue_panel.add_child(title)

	for i in range(4):
		var l := Label.new()
		l.position = Vector2(26, 44 + i * 38)
		l.size = Vector2(608, 34)
		l.add_theme_font_size_override("font_size", 16)
		l.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88))
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		dialogue_panel.add_child(l)
		dialogue_buttons.append(l)


func _on_boss_state_changed(furia: float, active: bool) -> void:
	if boss_panel == null:
		return
	boss_panel.visible = active
	if not active:
		return
	boss_furia_bar.value = furia
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.9, 0.3, 0.2) if furia > 34.0 else Color(0.4, 0.75, 0.45)
	style.set_corner_radius_all(3)
	boss_furia_bar.add_theme_stylebox_override("fill", style)
	boss_hint.text = Pad.traduci(
		("Scappa (SHIFT) e fùmate 'na sigaretta [X] pp''o calmà"
			if GameManager.cigarettes > 0 else
			"Scappa (SHIFT)! Nun tiene sigarette: piglia nu cafè ô bar o accàttele ô tabaccaio")
		if furia > 34.0 else "S'è calmato: vai da lui e premi E")


func _on_boss_dialogue_opened(answers: Array) -> void:
	if dialogue_panel == null:
		_build_dialogue_ui()
		_disable_mouse_capture_on_all_controls(dialogue_panel)
	_dialogue_answers = answers
	_sel = 0
	_disegna_risposte()
	dialogue_panel.visible = true
	# Mentre parli non serve nient'altro a schermo.
	prompt_label.text = ""
	client_pointer.text = ""
	# Il mouse resta catturato: si risponde da tastiera, come per il negozio.


## Le quattro risposte, con la freccia sulla riga scelta col joypad.
func _disegna_risposte() -> void:
	for i in dialogue_buttons.size():
		if i < _dialogue_answers.size():
			var a: Dictionary = _dialogue_answers[i]
			var scelta := i == _sel
			dialogue_buttons[i].text = "%s %d)  %s" % [
				("\u25b6" if scelta else "  "), i + 1, str(a["text"])]
			dialogue_buttons[i].modulate = Color(1.0, 0.88, 0.4) if scelta \
				else Color(0.85, 0.85, 0.82)
			dialogue_buttons[i].visible = true
		else:
			dialogue_buttons[i].visible = false


func _on_boss_dialogue_closed() -> void:
	_dialogue_answers = []
	if dialogue_panel:
		dialogue_panel.visible = false


## Listino di 'O Zio: appare da solo quando guardi il banchetto.
## Il fondo scuro dei pannelli. Quello di serie di Godot e' semitrasparente
## e sopra alla piazza — che e' chiara e piena di roba — il testo non si
## legge: si leggeva l'asfalto attraverso le lettere.
func _stile_pannello(colore_bordo: Color) -> StyleBoxFlat:
	# 0.62: gli stessi pannelli, col passo nuovo — più scuri, angoli più
	# tondi, il filo d'oro al posto del bordo marrone.
	var st := UiStile.box(Color(0.075, 0.08, 0.105, 0.96),
		colore_bordo.lerp(UiStile.ORO, 0.55), 2, 14, 6.0, 0.0)
	st.shadow_color = Color(0, 0, 0, 0.5)
	st.shadow_size = 14
	st.shadow_offset = Vector2(0, 5)
	return st


func _build_shop_ui() -> void:
	shop_panel = Panel.new()
	# **Sotto alla scheda, non sopra** (0.62). Stava centrato a sinistra e
	# copriva mezza scheda dei soldi e delle barre; adesso parte da sotto
	# alla scheda (`_metti_negozio`) e si allunga quanto serve.
	shop_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	shop_panel.position = Vector2(16, SHOP_TOP)
	shop_panel.size = Vector2(392, 440)
	shop_panel.visible = false
	shop_panel.add_theme_stylebox_override("panel",
		_stile_pannello(Color(0.55, 0.47, 0.3)))
	add_child(shop_panel)

	shop_title = Label.new()
	shop_title.position = Vector2(12, 10)
	shop_title.size = Vector2(368, 26)
	shop_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_title.add_theme_font_override("font", UiStile.font_titolo())
	shop_title.add_theme_font_size_override("font_size", 20)
	shop_title.text = "BANCHETTO 'E 'O ZIO"
	shop_title.modulate = Color(1.0, 0.8, 0.25)
	shop_panel.add_child(shop_title)

	# La griglia delle figurine: si svuota e si ricostruisce a ogni
	# aggiornamento. Sono sei caselle, costa niente.
	_shop_grid = Control.new()
	_shop_grid.position = Vector2(14, 42)
	_shop_grid.size = Vector2(364, 250)
	_shop_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop_panel.add_child(_shop_grid)

	shop_label = Label.new()
	shop_label.position = Vector2(16, 300)
	shop_label.size = Vector2(360, 140)
	shop_label.add_theme_font_size_override("font_size", 13)
	shop_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	shop_panel.add_child(shop_label)


## Dispone le caselle su una griglia e ritorna quanto e' alta.
## `voci` = lista di {id, prezzo, posseduto, etichetta}.
func _disegna_griglia(dove: Control, voci: Array, per_riga: int,
		lato: float, scelto: int) -> float:
	for c in dove.get_children():
		c.queue_free()
	var passo := lato + 16.0
	for i in voci.size():
		var v: Dictionary = voci[i]
		var col: int = i % per_riga
		var riga: int = i / per_riga
		var casella := IconeScript.casella(str(v["id"]), lato, i == scelto,
			bool(v.get("posseduto", true)))
		casella.position = Vector2(col * passo, riga * (passo + 18.0))
		dove.add_child(casella)

		# Il numeretto in alto a sinistra: e' il tasto da premere.
		var num := Label.new()
		num.position = Vector2(col * passo + 5, riga * (passo + 18.0) + 2)
		num.size = Vector2(20, 18)
		num.text = str(i + 1)
		num.add_theme_font_size_override("font_size", 12)
		num.modulate = Color(1.0, 0.83, 0.33) if i == scelto \
			else Color(0.62, 0.58, 0.54)
		num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dove.add_child(num)

		var sotto := Label.new()
		sotto.position = Vector2(col * passo, riga * (passo + 18.0) + lato + 1)
		sotto.size = Vector2(lato, 18)
		sotto.text = str(v.get("etichetta", ""))
		sotto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sotto.add_theme_font_size_override("font_size", 12)
		sotto.modulate = Color(0.95, 0.9, 0.8) if bool(v.get("posseduto", true)) \
			else Color(0.72, 0.68, 0.62)
		sotto.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dove.add_child(sotto)
	var righe: int = int(ceil(float(voci.size()) / float(per_riga)))
	return righe * (passo + 18.0)


var _shop_kind: String = ""
## Dove comincia il negozio se la scheda di sinistra non si trova.
const SHOP_TOP: float = 170.0
const SHOP_LATO: float = 72.0


## Mette il negozio sotto alla scheda di sinistra e lo fa alto quanto il
## suo contenuto: la griglia (`alto_griglia`) più la scheda della voce.
func _metti_negozio(alto_griglia: float) -> void:
	var scheda_ok: bool = _scheda_sx != null and is_instance_valid(_scheda_sx)
	var cima: float = SHOP_TOP
	if scheda_ok and _scheda_sx.visible:
		cima = _scheda_sx.get_global_rect().end.y + 10.0
	var vista: float = get_viewport().get_visible_rect().size.y
	shop_label.position.y = 42.0 + alto_griglia + 8.0
	var righe: int = maxi(1, shop_label.get_line_count())
	var alto_testo: float = float(righe) * float(shop_label.get_line_height()) + 6.0
	shop_label.size.y = alto_testo
	var alto: float = shop_label.position.y + alto_testo + 14.0
	# Se sotto alla scheda non c'entra (la scheda s'allunga con la
	# commissione in corso), il banco sale in cima e la scheda si fa da
	# parte finché si compra: i soldi stanno scritti nel banco.
	var sale: bool = cima + alto > vista - 12.0
	if sale:
		cima = 16.0
	if scheda_ok:
		_scheda_sx.modulate.a = 0.0 if sale else 1.0
	alto = minf(alto, vista - cima - 12.0)
	shop_panel.position = Vector2(16, cima)
	shop_panel.size = Vector2(392, alto)


func set_shop_visible(kind: String) -> void:
	var era := _shop_kind
	_shop_kind = kind
	shop_panel.visible = kind != ""
	if shop_panel.visible:
		if era != kind:
			_sel = 0 # negozio nuovo: si riparte dalla prima voce
			# E si riparte pure dalla scelta vuota: se no il primo numero
			# premuto al banco nuovo comprerebbe per inerzia quello che era
			# rimasto selezionato al banco di prima.
			GameManager.azzera_scelta_negozio()
		_refresh_shop()
	elif era != "":
		GameManager.azzera_scelta_negozio()
	if kind == "" and _scheda_sx != null and is_instance_valid(_scheda_sx):
		_scheda_sx.modulate.a = 1.0


## Il banco ha cambiato voce selezionata (l'ha detto GameManager, perché il
## tasto lo intercetta il negozio, non l'interfaccia): si sposta
## l'evidenziato e si riscrive la scheda.
func _on_negozio_selezione(id: String) -> void:
	if _shop_kind == "":
		return
	var chiavi: Array = GameManager.TOOL_IDS if _shop_kind == "zio" \
		else GameManager.DECOR_IDS
	var i: int = chiavi.find(id)
	if i >= 0:
		_sel = i
	_refresh_shop()


func _refresh_shop() -> void:
	if _shop_kind == "":
		return
	var voci: Array = []
	var chiavi: Array = []
	var coda: Array = []

	match _shop_kind:
		"zio":
			shop_title.text = "BANCHETTO 'E 'O ZIO"
			shop_title.modulate = Color(1.0, 0.8, 0.25)
			chiavi = GameManager.TOOL_IDS
			var count := GameManager.emblem_count()
			if count > 0:
				coda.append("[E] Vendi %d stemm%s → €%d" % [
					count, ("o" if count == 1 else "i"),
					GameManager.emblems_total_value()])
			else:
				coda.append("Compra pure stemmi rubati (ora non ne hai).")
		"bazar":
			shop_title.text = "BAZAR — TUTTO PE' 'A CASA"
			shop_title.modulate = Color(0.6, 1.0, 0.7)
			chiavi = GameManager.DECOR_IDS
			coda.append("Finisce nello zaino: [I] per piazzarlo.")
		"tabacchi":
			shop_title.text = "TABACCHI"
			shop_title.modulate = Color(0.65, 0.8, 1.0)
			voci = [
				{"id": "sigarette", "posseduto": GameManager.cigarettes > 0,
					"etichetta": "×%d" % GameManager.cigarettes},
				{"id": "caffe", "posseduto": GameManager.caffe > 0,
					"etichetta": "×%d" % GameManager.caffe},
			]
			var hg: float = _disegna_griglia(_shop_grid, voci, 4, SHOP_LATO, -1)
			shop_label.text = Pad.traduci("\n".join([
				"'O portafoglio: €%d" % GameManager.money,
				"",
				"[E] nu pacchetto 'e ssigarette — €%d" % GameManager.CIGARETTE_PACK_COST,
				"      po' [X] pe' t''a appiccià: mentre fume",
				"      'o suspetto scenne assaje cchiù ampresso.",
				"",
				"[1] tre ccafè — €%d" % (
					GameManager.CAFFE_COST * GameManager.CAFFE_PER_GIRO),
				"      po' [R] pe' te ne sculà uno: leva suspetto,",
				"      te rimette 'nzieme e pe' quinnece secunne curre.",
			]))
			_metti_negozio(hg)
			return

	for i in chiavi.size():
		var id: String = chiavi[i]
		var info: Dictionary = GameManager.UPGRADES[id]
		var mio: bool = GameManager.has_upgrade(id)
		var quante: int = GameManager.decor_possedute(id)
		var etichetta: String = "€%d" % int(info["cost"])
		if id in GameManager.DECOR_IDS and quante > 0:
			# Le decorazioni si ricomprano: l'etichetta dice quante ne hai
			# gia' e il prezzo resta, perche' la prossima si paga uguale.
			etichetta = "×%d · €%d" % [quante, int(info["cost"])]
		elif mio:
			etichetta = "TUO"
		voci.append({
			"id": id, "posseduto": mio and not (id in GameManager.DECOR_IDS),
			"etichetta": etichetta,
		})
	# **'A pittura janca c''o pennello** (0.64): l'ultima casella del bazar.
	# Non è un oggetto che si possiede né un decoro da piazzare: è roba che
	# si consuma, una passata per posto (vedi 'E STRISCE BLU).
	if _shop_kind == "bazar":
		voci.append({"id": "pittura", "posseduto": GameManager.pittura > 0,
			"etichetta": ("×%d · €%d" % [GameManager.pittura, GameManager.PITTURA_COSTO])
				if GameManager.pittura > 0 else "€%d" % GameManager.PITTURA_COSTO})
	var alto_griglia: float = _disegna_griglia(_shop_grid, voci, 4, SHOP_LATO, _sel)

	# Sotto la griglia, la scheda della casella scelta.
	var righe: Array = ["'O portafoglio: €%d" % GameManager.money, ""]
	if _shop_kind == "bazar" and _sel == chiavi.size():
		righe.append("Pittura janca c''o pennello")
		righe.append("'nu barattolo, %d passate: una pe' ogne posto cu 'e strisce blu (fermo accanto, [E])."
			% GameManager.PITTURA_PASSATE)
		righe.append("")
		if GameManager.money < GameManager.PITTURA_COSTO:
			righe.append("€%d — non te lo puoi permettere." % GameManager.PITTURA_COSTO)
		elif GameManager.negozio_scelto == "pittura":
			righe.append("€%d — premi ANCORA %d e te l'accatte." % [
				GameManager.PITTURA_COSTO, _sel + 1])
		else:
			righe.append("€%d — premi %d per guardarlo." % [
				GameManager.PITTURA_COSTO, _sel + 1])
	elif _sel >= 0 and _sel < chiavi.size():
		var id2: String = chiavi[_sel]
		var info2: Dictionary = GameManager.UPGRADES[id2]
		righe.append(str(info2["name"]))
		righe.append(str(info2["desc"]))
		righe.append("")
		if id2 in GameManager.DECOR_IDS \
				and GameManager.decor_possedute(id2) >= GameManager.DECOR_MAX_COPIE:
			righe.append("Ne tieni già %d. Abbastanza." % GameManager.DECOR_MAX_COPIE)
		elif GameManager.has_upgrade(id2) and not (id2 in GameManager.DECOR_IDS):
			righe.append("Già tuo.")
		elif GameManager.money < int(info2["cost"]):
			righe.append("€%d — non te lo puoi permettere." % int(info2["cost"]))
		elif GameManager.negozio_scelto == id2:
			# Selezionato: il prossimo tasto è quello che paga.
			righe.append("€%d — premi ANCORA %d e te l'accatte." % [
				int(info2["cost"]), _sel + 1])
		else:
			righe.append("€%d — premi %d per guardarlo." % [
				int(info2["cost"]), _sel + 1])
	righe.append("")
	righe.append_array(coda)
	shop_label.text = Pad.traduci("\n".join(righe))
	_metti_negozio(alto_griglia)


func _build_inventory_ui() -> void:
	inventory_panel = Panel.new()
	inventory_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	inventory_panel.position = Vector2(-404, -252)
	inventory_panel.size = Vector2(384, 504)
	inventory_panel.visible = false
	inventory_panel.add_theme_stylebox_override("panel",
		_stile_pannello(Color(0.55, 0.47, 0.3)))
	add_child(inventory_panel)

	var title := Label.new()
	title.position = Vector2(12, 8)
	title.size = Vector2(360, 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_font_override("font", UiStile.font_titolo())
	title.text = "ZAINO  [I]"
	title.modulate = UiStile.ORO_CHIARO
	inventory_panel.add_child(title)

	_inv_grid = Control.new()
	_inv_grid.position = Vector2(16, 40)
	_inv_grid.size = Vector2(352, 300)
	_inv_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_panel.add_child(_inv_grid)

	inventory_label = Label.new()
	inventory_label.position = Vector2(16, 344)
	inventory_label.size = Vector2(352, 152)
	inventory_label.add_theme_font_size_override("font_size", 13)
	inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	inventory_panel.add_child(inventory_label)


# ---------------------------------------------------------------------------
# La macchina fotografica
# ---------------------------------------------------------------------------

## Il mirino che compare quando fotografi un manifesto.
##
## Non è una modalità foto vera e non deve esserlo: sarebbe un secondo gioco
## dentro al gioco, con la sua mira e i suoi comandi, per una cosa che
## succede sei volte in tutta la partita. Quello che serve è che lo scatto
## *si senta*: quattro angoli che si stringono, un lampo bianco, il clic, e
## il titolo che resta lì un momento come sul display di un telefono.
func _build_foto_ui() -> void:
	_foto_root = Control.new()
	_foto_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_foto_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_foto_root.visible = false
	add_child(_foto_root)

	_foto_flash = ColorRect.new()
	_foto_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_foto_flash.color = Color(1, 1, 1, 0)
	_foto_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_foto_root.add_child(_foto_flash)

	# Gli angoli del mirino: otto barrette, due per angolo.
	const LUNGO := 54.0
	const SPESSO := 5.0
	const MARGINE := 96.0
	var bianco := Color(1.0, 0.96, 0.86, 0.92)
	for ax in [0, 1]:
		for az in [0, 1]:
			for orizzontale in [true, false]:
				var b := ColorRect.new()
				b.color = bianco
				b.mouse_filter = Control.MOUSE_FILTER_IGNORE
				if orizzontale:
					b.size = Vector2(LUNGO, SPESSO)
				else:
					b.size = Vector2(SPESSO, LUNGO)
				# Ancorato all'angolo giusto, così segue la risoluzione.
				b.anchor_left = float(ax)
				b.anchor_right = float(ax)
				b.anchor_top = float(az)
				b.anchor_bottom = float(az)
				var ox: float = MARGINE if ax == 0 else -MARGINE - b.size.x
				var oy: float = MARGINE if az == 0 else -MARGINE - b.size.y
				b.offset_left = ox
				b.offset_top = oy
				b.offset_right = ox + b.size.x
				b.offset_bottom = oy + b.size.y
				_foto_root.add_child(b)

	_foto_titolo = Label.new()
	_foto_titolo.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_foto_titolo.offset_left = -400
	_foto_titolo.offset_right = 400
	_foto_titolo.offset_top = -196
	_foto_titolo.offset_bottom = -158
	_foto_titolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_foto_titolo.add_theme_font_size_override("font_size", 30)
	_foto_titolo.modulate = Color(1.0, 0.88, 0.42)
	_foto_titolo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_foto_root.add_child(_foto_titolo)

	_foto_sotto = Label.new()
	_foto_sotto.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_foto_sotto.offset_left = -400
	_foto_sotto.offset_right = 400
	_foto_sotto.offset_top = -160
	_foto_sotto.offset_bottom = -136
	_foto_sotto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_foto_sotto.add_theme_font_size_override("font_size", 16)
	_foto_sotto.modulate = Color(0.92, 0.90, 0.86)
	_foto_sotto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_foto_root.add_child(_foto_sotto)

	_foto_conta = Label.new()
	_foto_conta.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_foto_conta.offset_left = -400
	_foto_conta.offset_right = 400
	_foto_conta.offset_top = -132
	_foto_conta.offset_bottom = -108
	_foto_conta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_foto_conta.add_theme_font_size_override("font_size", 18)
	_foto_conta.modulate = Color(0.65, 0.86, 0.62)
	_foto_conta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_foto_root.add_child(_foto_conta)


func _on_manifesto_fotografato(id: String, titolo: String,
		quanti: int, totale: int) -> void:
	var dati: Dictionary = GameManager.manifesto_dati(id)
	_foto_titolo.text = titolo
	_foto_sotto.text = str(dati.get("sotto", ""))
	_foto_conta.text = "Manifesti d''o quartiere:  %d / %d" % [quanti, totale]
	_foto_root.visible = true
	_foto_root.modulate.a = 1.0
	_foto_time = 3.0

	SoundManager.play("pop", -1.0, 1.7, 0.02)
	SoundManager.play("coin", -6.0, 1.2)
	_foto_flash.color = Color(1, 1, 1, 0.78)
	var t := create_tween()
	t.tween_property(_foto_flash, "color", Color(1, 1, 1, 0.0), 0.32)
	# Gli angoli si stringono: è quello che fa leggere il gesto come uno
	# scatto e non come un popup.
	_foto_root.scale = Vector2(1.12, 1.12)
	_foto_root.pivot_offset = Vector2(get_viewport().get_visible_rect().size) / 2.0
	var t2 := create_tween()
	t2.tween_property(_foto_root, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if inventory_panel and inventory_panel.visible:
		_refresh_inventory()


func _on_collezione_completa() -> void:
	_on_event_started("TUTT'E SSEJE! 'A collezione è cumpleta — €%d" %
		GameManager.COLLEZIONE_PREMIO)
	SoundManager.play("success", 0.0, 1.0)


## Menu di pausa: costruito DOPO il giro di MOUSE_FILTER_IGNORE, perché i
## suoi bottoni devono continuare a ricevere i click del mouse.
const TutorialeScript := preload("res://scripts/tutoriale.gd")

## Il numero di versione, in piccolo, dentro al menu di pausa. Serve a chi
## segnala un problema: "non mi funziona" senza la versione non si può
## nemmeno cercare. Stava inchiodato alla 0.43b da nove versioni.
const VERSIONE := "v0.64"

var _tutoriale: CanvasLayer = null


## Apre il tutorial sopra al menu di pausa. Quando si chiude, il menu
## torna a farsi vedere: se no uno esce dal tutorial e si ritrova in
## partita col gioco ancora fermo.
func _apri_tutoriale() -> void:
	if _tutoriale != null and is_instance_valid(_tutoriale):
		return
	if pause_panel != null:
		pause_panel.visible = false
	_tutoriale = TutorialeScript.new()
	get_tree().root.add_child(_tutoriale)
	_tutoriale.apri(func():
		_tutoriale = null
		if pause_panel != null:
			pause_panel.visible = true
			get_tree().paused = true
			GameManager.piglia_o_mouse(false))


func _build_pause_menu() -> void:
	pause_panel = Panel.new()
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	# Alzato a 440 per far posto alle due manopole del volume (0.56): con
	# 364 i cursori finivano oltre il bordo del pannello e si vedevano
	# per metà.
	# 0.62: più largo e più alto, bottoni da 44, la versione in fondo
	# (prima stava a 336 — sotto a "Esci dal gioco").
	# 0.62: ancora più alto, per il bottone del filtro dello schermo.
	pause_panel.position = Vector2(-200, -288)
	pause_panel.size = Vector2(400, 576)
	pause_panel.visible = false
	pause_panel.add_theme_stylebox_override("panel",
		_stile_pannello(Color(0.6, 0.52, 0.34)))
	add_child(pause_panel)

	var title := Label.new()
	title.position = Vector2(10, 16)
	title.size = Vector2(380, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_font_override("font", UiStile.font_titolo())
	title.add_theme_color_override("font_color", UiStile.ORO_CHIARO)
	title.text = "PAUSA"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_panel.add_child(title)

	_pause_first_btn = Button.new()
	var resume_btn := _pause_first_btn
	resume_btn.position = Vector2(60, 76)
	resume_btn.size = Vector2(280, 44)
	resume_btn.text = "Riprendi"
	resume_btn.pressed.connect(_resume_game)
	pause_panel.add_child(resume_btn)

	var save_btn := Button.new()
	save_btn.position = Vector2(60, 128)
	save_btn.size = Vector2(280, 44)
	save_btn.text = "Salva 'a partita"
	save_btn.pressed.connect(func(): _apri_slot("salva"))
	pause_panel.add_child(save_btn)

	var load_btn := Button.new()
	load_btn.position = Vector2(60, 180)
	load_btn.size = Vector2(280, 44)
	load_btn.text = "Carica 'na partita"
	load_btn.pressed.connect(func(): _apri_slot("carica"))
	pause_panel.add_child(load_btn)

	# **'O tutoriale sta ccà 'ncoppa (0.52).**
	#
	# Il capo: *"basta premere ESC e nel menu si può accedere a questo
	# tutorial"*. Prima era raggiungibile solo dal menu iniziale, cioè
	# solo prima di cominciare: chi si dimenticava un comando a metà
	# partita non aveva dove guardarlo. Le pagine sono le stesse del menu
	# — stanno in `tutoriale.gd`, in un posto solo.
	var tut_btn := Button.new()
	tut_btn.position = Vector2(60, 232)
	tut_btn.size = Vector2(280, 44)
	tut_btn.text = "Comme se joca"
	tut_btn.pressed.connect(_apri_tutoriale)
	pause_panel.add_child(tut_btn)

	# **'E ddoje manopole d''o volume** (0.56). Separate apposta: la musica
	# uno la spegne per ascoltare altro, gli effetti li abbassa perché il
	# clacson a tre metri è forte davvero. Si ricordano fra una partita e
	# l'altra (`user://audio.cfg`).
	_slider_volume("Suone", 318, SoundManager.vol_effetti,
		func(v): SoundManager.set_vol_effetti(v))
	_slider_volume("Musica", 362, SoundManager.vol_musica,
		func(v): SoundManager.set_vol_musica(v))

	# **'O filtro d''o schermo** (0.62, asset esterni): Nisciuno, Pellicola,
	# Videocassetta, Lente sporca. Un bottone che gira, come F5 per la
	# grafica; si ricorda da solo (`filtri_schermo.gd`).
	var filtro_btn := Button.new()
	filtro_btn.position = Vector2(60, 400)
	filtro_btn.size = Vector2(280, 44)
	filtro_btn.text = "Filtro: " + _nome_filtro()
	filtro_btn.pressed.connect(_gira_filtro.bind(filtro_btn))
	pause_panel.add_child(filtro_btn)

	var quit_btn := Button.new()
	quit_btn.position = Vector2(60, 452)
	quit_btn.size = Vector2(280, 44)
	quit_btn.text = "Esci dal gioco"
	quit_btn.pressed.connect(func(): get_tree().quit())
	pause_panel.add_child(quit_btn)

	var hint := Label.new()
	hint.position = Vector2(10, 504)
	hint.size = Vector2(380, 22)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.text = "Esc per riprendere"
	_pause_hint = hint
	hint.modulate = Color(0.7, 0.7, 0.7)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_panel.add_child(hint)

	# Il numero di versione, in piccolo. Serve a chi segnala un problema:
	# "non mi funziona" senza la versione non si puo' nemmeno cercare.
	var ver := Label.new()
	ver.position = Vector2(10, 532)
	ver.size = Vector2(380, 18)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_font_size_override("font_size", 10)
	ver.text = "Parcheggiatore Abusivo Simulator  ·  %s" % VERSIONE
	ver.modulate = Color(0.5, 0.48, 0.44)
	ver.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_panel.add_child(ver)

	_build_slot_panel()


func _nome_filtro() -> String:
	var f := get_tree().get_first_node_in_group("filtri_schermo")
	return str(f.nome()) if f != null else "Nisciuno"


func _gira_filtro(b: Button) -> void:
	var f := get_tree().get_first_node_in_group("filtri_schermo")
	if f == null:
		return
	b.text = "Filtro: " + str(f.prossimo())


# ---------------------------------------------------------------------------
# 'E quattro slot
# ---------------------------------------------------------------------------
#
# Lo stesso pannello serve per salvare e per caricare: cambia il titolo,
# cosa fa il click e cosa succede a uno slot vuoto (in salvataggio ci si
# scrive, in caricamento non si può toccare). Fare due pannelli identici
# sarebbe stato lo stesso codice due volte, con il rischio classico che
# uno dei due si aggiorni e l'altro no.

var slot_panel: Panel
var slot_title: Label
var _slot_btns: Array = []
var _slot_del_btns: Array = []
var _slot_modo: String = "" # "salva" | "carica"
var _slot_hint: Label


func _build_slot_panel() -> void:
	slot_panel = Panel.new()
	slot_panel.set_anchors_preset(Control.PRESET_CENTER)
	slot_panel.position = Vector2(-260, -190)
	slot_panel.size = Vector2(520, 380)
	slot_panel.visible = false
	slot_panel.add_theme_stylebox_override("panel",
		_stile_pannello(Color(0.6, 0.52, 0.34)))
	add_child(slot_panel)

	slot_title = Label.new()
	slot_title.position = Vector2(12, 14)
	slot_title.size = Vector2(496, 32)
	slot_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_title.add_theme_font_size_override("font_size", 22)
	slot_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_panel.add_child(slot_title)

	for i in range(GameManager.SLOT_MAX):
		var b := Button.new()
		b.position = Vector2(20, 58 + i * 56)
		b.size = Vector2(410, 46)
		b.add_theme_font_size_override("font_size", 14)
		b.pressed.connect(_on_slot_premuto.bind(i))
		slot_panel.add_child(b)
		_slot_btns.append(b)

		var d := Button.new()
		d.position = Vector2(438, 58 + i * 56)
		d.size = Vector2(62, 46)
		d.text = "Cancella"
		d.add_theme_font_size_override("font_size", 11)
		d.pressed.connect(_on_slot_cancella.bind(i))
		slot_panel.add_child(d)
		_slot_del_btns.append(d)

	_slot_hint = Label.new()
	_slot_hint.position = Vector2(12, 292)
	_slot_hint.size = Vector2(496, 40)
	_slot_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slot_hint.add_theme_font_size_override("font_size", 12)
	_slot_hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	_slot_hint.modulate = Color(0.72, 0.7, 0.66)
	_slot_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_panel.add_child(_slot_hint)

	var back := Button.new()
	back.position = Vector2(180, 330)
	back.size = Vector2(160, 36)
	back.text = "Torna arreto"
	back.pressed.connect(_chiudi_slot)
	slot_panel.add_child(back)


func _apri_slot(modo: String) -> void:
	_slot_modo = modo
	pause_panel.visible = false
	slot_panel.visible = true
	_aggiorna_slot()
	if not _slot_btns.is_empty():
		(_slot_btns[0] as Button).grab_focus()


func _chiudi_slot() -> void:
	slot_panel.visible = false
	pause_panel.visible = true
	if _pause_first_btn and is_instance_valid(_pause_first_btn):
		_pause_first_btn.grab_focus()


func _aggiorna_slot() -> void:
	slot_title.text = "SALVA — scegli 'o posto" if _slot_modo == "salva" \
		else "CARICA — scegli 'a partita"
	for i in range(GameManager.SLOT_MAX):
		var b: Button = _slot_btns[i]
		var pieno: bool = GameManager.slot_pieno(i)
		b.text = "%d.  %s" % [i + 1, GameManager.descrizione_slot(i)]
		# In caricamento uno slot vuoto non si può premere; in salvataggio
		# sì, ed è anzi quello che si preme per primo.
		b.disabled = (_slot_modo == "carica" and not pieno)
		(_slot_del_btns[i] as Button).visible = pieno
	if _slot_modo == "salva":
		_slot_hint.text = "Salvare sopra a 'na partita già scritta se la piglia. Chello che se salva è 'a roba toja: sorde, piazze, guagliuni, oggetti e manifesti — no 'o turno 'e mo'."
	else:
		_slot_hint.text = "Caricanno, 'a giornata 'e mo' se perde e se ricomincia 'a matina cu 'a roba d''o salvataggio."


func _on_slot_premuto(i: int) -> void:
	if _slot_modo == "salva":
		if GameManager.salva_su_slot(i):
			SoundManager.play("coin", -6.0, 1.1)
			_aggiorna_slot()
			_slot_hint.text = "Salvato dint'ô posto %d." % (i + 1)
		else:
			SoundManager.play("fail", -8.0, 0.9)
			_slot_hint.text = "Nun se po' scrivere. Contrulla 'o disco."
		return
	if not GameManager.carica_da_slot(i):
		SoundManager.play("fail", -8.0, 0.9)
		return
	# Si riparte dalla piazza tua con lo stato caricato. La scena si
	# ricostruisce da capo: il GameManager è un autoload e non muore, quindi
	# quello che abbiamo appena letto sopravvive al reload.
	SoundManager.play("kaching", -4.0, 1.0)
	slot_panel.visible = false
	GameManager.salta_intro = true
	_restart_in_zone("piazza")


func _on_slot_cancella(i: int) -> void:
	if GameManager.cancella_slot(i):
		SoundManager.play("pop", -10.0, 0.8)
	_aggiorna_slot()


func _input(event: InputEvent) -> void:
	# **'A cella se scanza cu qualunque tasto**, e sta in cima a tutto:
	# mentre sei dentro non c'è nient'altro da fare, e ogni altro ramo
	# dell'input mangerebbe il tasto prima.
	if _galera_panel != null and _galera_panel.visible:
		if event is InputEventKey and event.pressed:
			get_viewport().set_input_as_handled()
			_chiude_galera()
		elif event is InputEventMouseButton and event.pressed:
			get_viewport().set_input_as_handled()
			_chiude_galera()
		return

	# Mentre la schermata iniziale è a video nessun tasto dell'HUD risponde:
	# il primo tasto serve solo a far partire il turno.
	if GameManager.intro_active:
		return

	# **Il borseggio.**
	#
	# Questo ramo non c'era proprio. La barra si apriva, il cursore
	# andava avanti e indietro, e poi... niente: nessuno chiamava
	# `_resolve_pickpocket()`, e nessuno chiudeva il pannello. Si restava
	# incastrati davanti a una finestra che non rispondeva a niente,
	# perche' il click veniva mangiato dal player (che pero' sa di non
	# dover menare mentre la barra e' su) e non arrivava mai qui.
	#
	# Sta in cima a tutto: mentre borseggi, il click e' PER il borseggio, e
	# non deve finire ne' al negozio ne' allo zaino.
	if is_pickpocket_open():
		if event.is_action_pressed("punch") or event.is_action_pressed("menu_ok") \
				or event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled()
			_resolve_pickpocket()
			return
		# Ci si puo' tirare indietro: ESC o C (che e' il tasto con cui ti sei
		# accovacciato per avvicinarti). Non e' un fallimento — e' non aver
		# provato, e la signora non se ne accorge nemmeno.
		if event.is_action_pressed("ui_cancel") \
				or event.is_action_pressed("crouch"):
			get_viewport().set_input_as_handled()
			_rinuncia_pickpocket()
			return
		return

	# --- Joypad: croce direzionale per scorrere, croce/A per confermare ---
	# Vale per il negozio, per lo zaino e per le risposte a Borrelli: e' la
	# stessa lista, cambia solo chi la gestisce.
	if menu_open():
		if event.is_action_pressed("menu_giu"):
			get_viewport().set_input_as_handled()
			_scorri_menu(1)
			return
		if event.is_action_pressed("menu_su"):
			get_viewport().set_input_as_handled()
			_scorri_menu(-1)
			return
		if event.is_action_pressed("menu_ok"):
			get_viewport().set_input_as_handled()
			_conferma_menu()
			return

	# Dialogo con Borrelli: i tasti 1-4 scelgono la risposta e NON arrivano
	# al negozio (che userebbe gli stessi tasti per comprare).
	if not _dialogue_answers.is_empty():
		for i in range(4):
			if event.is_action_pressed("buy_%d" % (i + 1)):
				get_viewport().set_input_as_handled()
				# A chi risponde? A chi ha aperto il dialogo. Prima era
				# scritto "borrelli" a mano, e infatti nessun altro poteva
				# aprirne uno — il vigile ci ha messo tre versioni ad
				# arrivare a parlare.
				var chi = GameManager.dialogo_con
				if chi == null or not is_instance_valid(chi):
					chi = get_tree().get_first_node_in_group("borrelli")
				if chi and chi.has_method("answer"):
					chi.answer(i)
				return

	# **'A chiantina.** M la apre e la chiude; ESC pure, che e' il tasto con
	# cui uno chiude qualunque cosa. Mentre e' aperta il resto del gioco
	# continua a girare: non e' una pausa, e' una carta che tiri fuori
	# dalla tasca — se ti stanno inseguendo, guardarla ti costa.
	if event.is_action_pressed("mappa"):
		get_viewport().set_input_as_handled()
		_toggle_mappa()
		return
	if mappa != null and mappa.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		mappa.chiudi()
		return

	# ESC durante il piazzamento annulla, non mette in pausa.
	if event.is_action_pressed("ui_cancel") and _player_ref \
			and _player_ref.has_method("is_placing") and _player_ref.is_placing():
		get_viewport().set_input_as_handled()
		_player_ref.cancel_placing()
		return

	if event.is_action_pressed("ui_cancel"):
		# Esc dentro agli slot torna al menu, non alla partita: se no chi
		# apre "Carica" per sbaglio deve rifare tutto il giro.
		if slot_panel and slot_panel.visible:
			get_viewport().set_input_as_handled()
			_chiudi_slot()
			return
		if get_tree().paused:
			_resume_game()
		else:
			_pause_game()
	# Zaino aperto: i numeri prendono in mano una decorazione da piazzare.
	if inventory_panel and inventory_panel.visible and not _inv_placeable.is_empty():
		for i in range(mini(6, _inv_placeable.size())):
			if event.is_action_pressed("buy_%d" % (i + 1)):
				get_viewport().set_input_as_handled()
				_sel = i
				if GameManager.decor_libere(str(_inv_placeable[i])) <= 0:
					SoundManager.play("fail", -12.0, 0.9)
					_refresh_inventory()
					return
				inventory_panel.visible = false
				if _player_ref and _player_ref.has_method("start_placing"):
					_player_ref.start_placing(str(_inv_placeable[i]))
				return

	# NON elif: prima era attaccato al ramo dei numeri qui sopra, e quando lo
	# zaino aveva qualcosa dentro il tasto I non lo chiudeva piu'.
	if event.is_action_pressed("inventory") and not get_tree().paused:
		if _player_ref and _player_ref.has_method("is_placing") \
				and _player_ref.is_placing():
			_player_ref.cancel_placing() # I con l'oggetto in mano = lascia stare
			get_viewport().set_input_as_handled()
			return
		inventory_panel.visible = not inventory_panel.visible
		if inventory_panel.visible:
			_sel = 0
			_refresh_inventory()


## Il pannello che in questo momento si comanda con la croce direzionale, e
## quante voci ha. Ritorna "" se non c'e' niente di selezionabile aperto.
func _lista_attiva() -> Array:
	if not _dialogue_answers.is_empty():
		return ["dialogo", _dialogue_answers.size()]
	if inventory_panel and inventory_panel.visible:
		return ["zaino", _inv_placeable.size()]
	if shop_panel and shop_panel.visible:
		match _shop_kind:
			"zio": return ["negozio", GameManager.TOOL_IDS.size()]
			"bazar": return ["negozio", GameManager.DECOR_IDS.size() + 1]
	return ["", 0]


## Vero se c'e' un pannello aperto che si comanda col joypad. Il giocatore
## lo interroga per non saltare mentre preme A per comprare: sul joypad la
## croce e' sia "salta" sia "conferma", e senza questo controllo ogni
## acquisto veniva accompagnato da un saltello.
func menu_open() -> bool:
	return _lista_attiva()[0] != ""


func _scorri_menu(passo: int) -> void:
	var info := _lista_attiva()
	var n: int = info[1]
	if n <= 0:
		return
	_sel = posmod(_sel + passo, n)
	# Col joypad la croce direzionale FA GIA' il primo tempo dell'acquisto:
	# muoverla apre la scheda. Quindi il tasto A dev'essere la conferma, non
	# una seconda selezione — se no comprare vorrebbe dire premere A due
	# volte dopo aver gia' scelto, e sembrerebbe rotto.
	if str(info[0]) == "negozio":
		var chiavi: Array = GameManager.TOOL_IDS if _shop_kind == "zio" \
			else GameManager.DECOR_IDS
		if _sel < chiavi.size():
			GameManager.negozio_scelto = str(chiavi[_sel])
		elif _shop_kind == "bazar":
			GameManager.negozio_scelto = "pittura"
	SoundManager.play("pop", -14.0, 1.3)
	_ridisegna_pannello(str(info[0]))


func _conferma_menu() -> void:
	var info := _lista_attiva()
	var quale: String = str(info[0])
	var n: int = info[1]
	if n <= 0:
		return
	var i: int = clampi(_sel, 0, n - 1)
	match quale:
		"dialogo":
			var boss := get_tree().get_first_node_in_group("borrelli")
			if boss and boss.has_method("answer"):
				boss.answer(i)
		"zaino":
			if GameManager.decor_libere(str(_inv_placeable[i])) <= 0:
				SoundManager.play("fail", -12.0, 0.9)
				return
			inventory_panel.visible = false
			if _player_ref and _player_ref.has_method("start_placing"):
				_player_ref.start_placing(str(_inv_placeable[i]))
		"negozio":
			var bottega = _player_ref.get("current_target") if _player_ref else null
			if bottega and is_instance_valid(bottega) \
					and bottega.has_method("compra_voce"):
				bottega.compra_voce(i)


func _ridisegna_pannello(quale: String) -> void:
	match quale:
		"dialogo": _disegna_risposte()
		"zaino": _refresh_inventory()
		"negozio": _refresh_shop()


## Riscrive tutto quello che a schermo nomina un tasto. Si chiama quando si
## passa dalla tastiera al pad (o viceversa) in mezzo alla partita.
func _ridisegna_suggerimenti() -> void:
	if shop_panel and shop_panel.visible:
		_refresh_shop()
	if inventory_panel and inventory_panel.visible:
		_refresh_inventory()
	_refresh_emblem_counter()
	_on_cigarettes_changed(GameManager.cigarettes)
	if _player_ref and is_instance_valid(_player_ref) \
			and _player_ref.get("current_target") != null:
		var t = _player_ref.get("current_target")
		if t and t.has_method("get_interact_prompt"):
			prompt_label.text = Pad.traduci(
				t.get_interact_prompt(_player_ref.global_position))
	if _pause_hint:
		_pause_hint.text = "%s per riprendere" % (
			Pad.tasto("ui_cancel") if Pad.collegato() else "Esc")


## L'insegna della zona: compare quando si passa da un quartiere all'altro
## e dice di chi e'. E' l'unico modo di far capire che il quartiere ha dei
## confini senza disegnarli per terra.
func _aggancia_citta() -> void:
	var citta := get_tree().get_root().find_child("Citta", true, false)
	if citta and citta.has_signal("zona_cambiata"):
		citta.zona_cambiata.connect(_on_zona_cambiata)
	if citta and citta.has_signal("strada_cambiata"):
		citta.strada_cambiata.connect(_on_strada_cambiata)


func _on_zona_cambiata(id: String, nome: String, padrone: String) -> void:
	if zona_label == null:
		return
	if id == "":
		zona_label.text = ""
		return
	if padrone == "tu":
		zona_label.text = "%s — 'a zona toia" % nome
		zona_label.modulate = Color(0.65, 1.0, 0.7)
	else:
		zona_label.text = "%s — 'e %s" % [nome, padrone]
		zona_label.modulate = Color(1.0, 0.62, 0.4)
	_zona_visibile = 5.0


## La targa della strada. Compare in basso a sinistra quando si imbocca una
## via che ha un nome, e sparisce da sé. È il modo più economico che c'è di
## far capire che la città è un posto e non una mappa: uno legge
## "Spaccanapoli" e sa dove sta, anche se la strada la vedeva già.
func _on_strada_cambiata(nome: String) -> void:
	if strada_label == null:
		return
	if nome == "":
		_strada_visibile = minf(_strada_visibile, 0.6)
		return
	strada_label.text = "· %s ·" % nome
	strada_label.modulate = Color(0.94, 0.90, 0.78)
	_strada_visibile = 3.6


func _pause_game() -> void:
	get_tree().paused = true
	pause_panel.visible = true
	GameManager.piglia_o_mouse(false)
	# Col joypad non c'e' un puntatore: se nessun bottone ha il fuoco, la
	# croce direzionale non ha niente da spostare e il menu e' morto.
	if _pause_first_btn and is_instance_valid(_pause_first_btn):
		_pause_first_btn.grab_focus()
	if _pause_hint:
		_pause_hint.text = "%s per riprendere" % (
			Pad.tasto("ui_cancel") if Pad.collegato() else "Esc")


func _resume_game() -> void:
	get_tree().paused = false
	pause_panel.visible = false
	if slot_panel:
		slot_panel.visible = false
	if not summary_panel.visible:
		GameManager.piglia_o_mouse(true)


func _build_directing_ui() -> void:
	directing_panel = Panel.new()
	directing_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	directing_panel.position = Vector2(-160, 40)
	directing_panel.size = Vector2(320, 128)
	directing_panel.visible = false
	add_child(directing_panel)

	directing_title_label = Label.new()
	directing_title_label.position = Vector2(10, 6)
	directing_title_label.size = Vector2(300, 26)
	directing_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	directing_title_label.add_theme_font_size_override("font_size", 16)
	directing_title_label.text = "W vai · S aspetta · A/D gira · F: mettila ccà"
	directing_panel.add_child(directing_title_label)

	directing_time_label = Label.new()
	directing_time_label.position = Vector2(10, 6)
	directing_time_label.size = Vector2(300, 20)
	directing_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	directing_time_label.add_theme_font_size_override("font_size", 12)
	directing_panel.add_child(directing_time_label)

	var dist_caption := Label.new()
	dist_caption.position = Vector2(10, 34)
	dist_caption.size = Vector2(120, 16)
	dist_caption.add_theme_font_size_override("font_size", 11)
	dist_caption.text = "Posizione"
	directing_panel.add_child(dist_caption)

	directing_distance_bar = ProgressBar.new()
	directing_distance_bar.position = Vector2(10, 50)
	directing_distance_bar.size = Vector2(300, 14)
	directing_distance_bar.min_value = 0.0
	directing_distance_bar.max_value = 1.0
	directing_distance_bar.show_percentage = false
	directing_panel.add_child(directing_distance_bar)

	var align_caption := Label.new()
	align_caption.position = Vector2(10, 68)
	align_caption.size = Vector2(120, 16)
	align_caption.add_theme_font_size_override("font_size", 11)
	align_caption.text = "Allineamento"
	directing_panel.add_child(align_caption)

	directing_align_bar = ProgressBar.new()
	directing_align_bar.position = Vector2(10, 84)
	directing_align_bar.size = Vector2(300, 14)
	directing_align_bar.min_value = 0.0
	directing_align_bar.max_value = 1.0
	directing_align_bar.show_percentage = false
	directing_panel.add_child(directing_align_bar)

	directing_speed_label = Label.new()
	directing_speed_label.position = Vector2(10, 102)
	directing_speed_label.size = Vector2(150, 20)
	directing_speed_label.add_theme_font_size_override("font_size", 12)
	directing_panel.add_child(directing_speed_label)

	directing_bump_label = Label.new()
	directing_bump_label.position = Vector2(160, 102)
	directing_bump_label.size = Vector2(150, 20)
	directing_bump_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	directing_bump_label.add_theme_font_size_override("font_size", 12)
	directing_bump_label.modulate = Color(1.0, 0.4, 0.3)
	directing_panel.add_child(directing_bump_label)

	directing_result_label = _make_label(Vector2(0, 0), "", 26)
	directing_result_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	directing_result_label.position = Vector2(-200, 40)
	directing_result_label.size = Vector2(400, 40)
	directing_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	directing_result_label.visible = false
	add_child(directing_result_label)

	# Il gesto gridato dal parcheggiatore: grande, giallo, al centro dello schermo.
	shout_label = _make_label(Vector2(0, 0), "", 38)
	shout_label.set_anchors_preset(Control.PRESET_CENTER)
	shout_label.position = Vector2(-300, -140)
	shout_label.size = Vector2(600, 50)
	shout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shout_label.modulate = Color(1.0, 0.85, 0.2)
	add_child(shout_label)

	# La risposta dell'autista, più piccola, sotto.
	driver_reply_label = _make_label(Vector2(0, 0), "", 20)
	driver_reply_label.set_anchors_preset(Control.PRESET_CENTER)
	driver_reply_label.position = Vector2(-300, -88)
	driver_reply_label.size = Vector2(600, 30)
	driver_reply_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	driver_reply_label.modulate = Color(0.8, 0.9, 1.0)
	add_child(driver_reply_label)


var summary_replay_btn: Button
var summary_strada_btn: Button


func _build_summary_ui() -> void:
	summary_panel = Panel.new()
	summary_panel.set_anchors_preset(Control.PRESET_CENTER)
	summary_panel.position = Vector2(-290, -250)
	summary_panel.size = Vector2(580, 500)
	summary_panel.visible = false
	add_child(summary_panel)
	# **'O scuro dereto** (0.62): il riepilogo si apriva sopra alla piazza
	# con le schede dell'HUD accese attorno, e le barre ci passavano sotto.
	# Un velo scuro, figlio del pannello e disegnato dietro di lui: si
	# accende e si spegne insieme al pannello senza doverlo ricordare.
	var velo := ColorRect.new()
	velo.name = "Velo"
	velo.color = Color(0.02, 0.02, 0.04, 0.72)
	velo.position = Vector2(-3000, -3000)
	velo.size = Vector2(6000, 6000)
	velo.show_behind_parent = true
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	summary_panel.add_child(velo)

	summary_label = Label.new()
	summary_label.position = Vector2(20, 14)
	summary_label.size = Vector2(540, 414)
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	summary_panel.add_child(summary_label)


## I pulsanti del riepilogo: costruiti DOPO il giro di MOUSE_FILTER_IGNORE
## (come il menu di pausa), perché devono ricevere i click.
func _build_summary_buttons() -> void:
	summary_replay_btn = Button.new()
	_summary_first_btn = summary_replay_btn
	summary_replay_btn.position = Vector2(180, 440)
	summary_replay_btn.size = Vector2(220, 46)
	summary_replay_btn.text = "Damane matina →"
	summary_replay_btn.pressed.connect(func(): _restart_in_zone("vicolo"))
	summary_panel.add_child(summary_replay_btn)

	summary_strada_btn = Button.new()
	summary_strada_btn.position = Vector2(420, 440)
	summary_strada_btn.size = Vector2(140, 46)
	summary_strada_btn.text = "La Strada Principale"
	summary_strada_btn.visible = false
	summary_strada_btn.pressed.connect(func(): _restart_in_zone("strada"))
	summary_panel.add_child(summary_strada_btn)


func _restart_in_zone(zone_id: String) -> void:
	GameManager.selected_zone = zone_id
	# Il giorno dopo non si ricomincia dalle locandine: si apre gli occhi e
	# si sta gia' in piazza. Le splash screen sono l'inizio della PARTITA,
	# non l'inizio di ogni giornata.
	GameManager.salta_intro = true
	GameManager.dentro_casa = false
	get_tree().paused = false
	GameManager.piglia_o_mouse(true)
	get_tree().reload_current_scene()


func _disable_mouse_capture_on_all_controls(node: Node) -> void:
	# L'HUD è solo un overlay: nessun suo elemento deve intercettare il
	# mouse, altrimenti il look della camera in prima persona smette di
	# funzionare (il cursore "catturato" resta intrappolato dalla GUI).
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_disable_mouse_capture_on_all_controls(child)


## Ogni scritta del HUD ha il suo contorno scuro.
##
## Senza, il testo chiaro spariva ogni volta che dietro capitava un muro
## chiaro — al Vomero, dove l'intonaco è bianco, "Sospetto vigili" non si
## leggeva proprio. Un'interfaccia che si vede solo su certi sfondi non è
## un'interfaccia. Il contorno costa niente e funziona su qualunque cosa
## ci finisca dietro.
func _make_label(pos: Vector2, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.72))
	label.add_theme_constant_override("outline_size", maxi(3, font_size / 4))
	return label


func set_player(player: Node) -> void:
	_player_ref = player
	if player.has_signal("prompt_changed"):
		player.prompt_changed.connect(_on_prompt_changed)
	if player.has_signal("shop_focus_changed"):
		player.shop_focus_changed.connect(set_shop_visible)


func _on_prompt_changed(text: String) -> void:
	if not _dialogue_answers.is_empty():
		return # il dialogo col boss ha la precedenza su tutto
	prompt_label.text = Pad.traduci(text)


func _on_money_changed(amount: int) -> void:
	# Popup fluttuante quando i soldi cambiano. (0.62) Anche quando se ne
	# vanno: prima si vedeva solo il guadagno, e una multa, la spesa o la
	# scommessa persa toglievano soldi in silenzio.
	if _last_money >= 0 and amount != _last_money:
		_spawn_money_popup(amount - _last_money)
	_last_money = amount
	# L'euro ce lo mette l'icona accanto (0.62).
	money_label.text = "%d" % amount


## Il numero che sale accanto ai soldi, col borsello che si riempie o che
## si svuota (icone di Kenney, CC0, dalla biblioteca esterna).
func _spawn_money_popup(delta_money: int) -> void:
	var entra: bool = delta_money > 0
	var colore: Color = Color(0.4, 1.0, 0.5) if entra else Color(1.0, 0.42, 0.36)
	var riga := HBoxContainer.new()
	riga.mouse_filter = Control.MOUSE_FILTER_IGNORE
	riga.add_theme_constant_override("separation", 4)
	riga.add_child(UiStile.figura("borsa_entra" if entra else "borsa_esce", 24.0, colore))
	var popup := _make_label(Vector2(0, 0),
		("+€%d" % delta_money) if entra else ("−€%d" % absi(delta_money)), 22)
	popup.add_theme_font_override("font", UiStile.font_titolo())
	popup.add_theme_color_override("font_color", colore)
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	riga.add_child(popup)
	riga.position = money_label.global_position + Vector2(
		money_label.size.x + randf_range(14, 40), -4)
	add_child(riga)
	# Chi entra sale, chi esce scivola via di lato: scendendo sarebbe finito
	# sopra alla scritta del sospetto.
	var tween := create_tween()
	if entra:
		tween.tween_property(riga, "position:y", riga.position.y - 40.0, 1.0)
	else:
		tween.tween_property(riga, "position:x", riga.position.x + 60.0, 1.2)
	tween.parallel().tween_property(riga, "modulate:a", 0.0, 1.2 if not entra else 1.0)
	tween.tween_callback(riga.queue_free)


## Il corpo del cartello a scaletta: le frasi corte restano grosse (sono
## quelle urlate — "T'HANNO PIGLIATO"), le lunghe si stringono un poco
## invece di andare a capo per forza. Sopra alle ottanta lettere si va a
## capo lo stesso, e ci sta: la riga è alta due righe.
func _corpo_cartiello(n: int) -> int:
	if n <= 46:
		return 28
	if n <= 74:
		return 24
	return 21


func _on_event_started(text: String) -> void:
	event_banner.text = text
	event_banner.add_theme_font_size_override("font_size",
		_corpo_cartiello(text.length()))
	event_banner.modulate.a = 1.0
	_banner_time = 4.0
	event_banner.scale = Vector2(0.6, 0.6)
	var tween := create_tween()
	tween.tween_property(event_banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_shop_dirty(_id: String) -> void:
	if shop_panel and shop_panel.visible:
		_refresh_shop()
	# Appena compri qualcosa il promemoria in basso deve dirti che ora c'e'
	# roba nello zaino: e' l'unico posto in cui uno lo viene a sapere.
	_refresh_emblem_counter()
	if inventory_panel and inventory_panel.visible:
		_refresh_inventory()


func _on_money_dirty(_amount: int) -> void:
	if shop_panel and shop_panel.visible:
		_refresh_shop()


func _on_caffe_changed(_quante: int) -> void:
	_on_cigarettes_changed(GameManager.cigarettes)
	if shop_panel and shop_panel.visible:
		_refresh_shop()
	if inventory_panel and inventory_panel.visible:
		_refresh_inventory()


func _on_cigarettes_changed(count: int) -> void:
	if shop_panel and shop_panel.visible:
		_refresh_shop()
	var pezzi: Array = []
	if count > 0:
		pezzi.append("Sigarette: %d  [X] fuma" % count)
	if GameManager.caffe > 0:
		pezzi.append("Caffè: %d  [R] bevi" % GameManager.caffe)
	cig_label.text = Pad.traduci(" · ".join(pezzi))


func _refresh_commission() -> void:
	if GameManager.active_commission.is_empty():
		commission_label.text = ""
	else:
		commission_label.text = "Commissione 'O Zio: %s ×%d!" % [
			GameManager.active_commission["name"], GameManager.active_commission["mult"]]


## Gli HP che restano. Da verde a rosso: sotto un terzo lampeggia.
func _on_health_changed(value: float) -> void:
	if health_bar == null:
		return
	health_bar.value = value
	var ratio: float = value / GameManager.HEALTH_MAX
	var col: Color
	if ratio > 0.6:
		col = Color(0.35, 0.75, 0.4)
	elif ratio > 0.3:
		col = Color(0.9, 0.72, 0.25)
	else:
		col = Color(0.9, 0.25, 0.22)
	UiStile.colora_barra(health_bar, col)
	health_caption.text = "HP" if ratio > 0.3 else "HP — STAI MALE"
	health_caption.modulate = Color.WHITE if ratio > 0.3 else Color(1.0, 0.45, 0.4)


func _on_player_hurt(_amount: float, cause: String) -> void:
	_hurt_flash_time = 0.5
	if cause != "":
		event_banner.text = cause
		event_banner.modulate = Color(1.0, 0.35, 0.3)
		_banner_time = 2.0


func _on_heat_changed(heat: float) -> void:
	heat_bar.value = heat
	# 0.62: si tinge il pieno, non tutta la barra (prima col `modulate`
	# diventava verde anche il vuoto, e una barra vuota sembrava piena).
	if heat > 70.0:
		UiStile.colora_barra(heat_bar, Color(1.0, 0.36, 0.3))
	elif heat > 35.0:
		UiStile.colora_barra(heat_bar, Color(1.0, 0.78, 0.25))
	else:
		UiStile.colora_barra(heat_bar, Color(0.4, 0.86, 0.5))


## L'orologio non e' piu' un conto alla rovescia: e' l'ora del giorno.
##
## Il turno adesso finisce quando cala la notte e arriva Borrelli, non allo
## scadere di un cronometro — quindi il numero utile e' che ora si e' fatta,
## perche' e' quello che dice quanto manca al buio. E il cielo lo conferma
## a occhio, che e' meglio ancora.
func _on_shift_time_changed(_seconds_left: float) -> void:
	if GameManager.boss_phase:
		timer_label.text = "SCONTRO FINALE"
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.3))
		return
	var ciclo := _trova_ciclo()
	if ciclo == null:
		timer_label.text = ""
		return
	timer_label.text = ciclo.orario()
	# Alle quattro l'orologio smette di essere un cronometro e diventa un
	# ordine: da lì in poi non arriva più nessuno e l'unica cosa da fare è
	# tornare a casa.
	if GameManager.giornata_scaduta:
		timer_label.text = "04:00 · VA' A CASA"
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.42))
	elif GameManager.notte:
		timer_label.add_theme_color_override("font_color", Color(0.72, 0.78, 1.0))
	else:
		timer_label.remove_theme_color_override("font_color")
	_scrivi_giorno()


## I giorni della settimana ci sono perché "giovedì 12" si ricorda e
## "giornata 12" no — e perché sabato e domenica in una piazza napoletana
## non sono giorni come gli altri, e prima o poi il gioco dovrà dirlo.
const GIURNE := ["lunedì", "martedì", "mercoledì", "giovedì", "venerdì",
	"sabato", "duméneca"]


func _scrivi_giorno() -> void:
	if giorno_label == null:
		return
	var g: int = maxi(1, GameManager.giornata)
	giorno_label.text = "%s · juorno %d" % [str(GIURNE[(g - 1) % 7]), g]
	_scrivi_fascia()


## I colori delle fasce: arancio le ore vuote, verde quelle che rendono,
## azzurro la notte. L'indice è lo stesso di `GameManager.FASCE`.
const COLORI_FASCIA := [
	Color(0.94, 0.78, 0.44),   # 'a controra — piano
	Color(0.96, 0.64, 0.38),   # 'e ttre morte — vuota
	Color(0.74, 0.94, 0.66),   # ll'aperitivo — se lavora
	Color(0.58, 0.96, 0.60),   # 'e rristorante — ora bbona
	Color(0.68, 0.78, 1.00),   # 'a nuttata — poca gente, mance grosse
]


func _scrivi_fascia() -> void:
	if fascia_label == null:
		return
	# Con Borrelli davanti, o dopo le quattro, la fascia non vuol dire
	# più niente: la piazza è chiusa e la riga sparisce invece di dare
	# un consiglio che non si può seguire.
	if not GameManager.shift_active or GameManager.giornata_scaduta \
			or GameManager.boss_phase:
		fascia_label.text = ""
		return
	var i: int = GameManager.fascia_indice()
	# **E si 'a jurnata è speciale, chella se vede primma (0.52).** Il tipo
	# di giornata pesa più della fascia — un mercato cambia il gioco più di
	# un'ora — quindi quando c'è si prende la riga, e la fascia le va
	# accanto in piccolo.
	if GameManager.e_speciale():
		fascia_label.text = "%s · %s" % [GameManager.giornata_nome(),
			GameManager.fascia_nome()]
		fascia_label.modulate = Color(1.0, 0.72, 0.86)
		return
	fascia_label.text = GameManager.fascia_nome()
	fascia_label.modulate = COLORI_FASCIA[clampi(i, 0, COLORI_FASCIA.size() - 1)]


var zona_label: Label
var _zona_visibile: float = 0.0
var strada_label: Label
## 'A riga ca dice 'e cliccà pe' ripiglià 'o mouse (0.56b, sulo ncopp'ô web).
var mouse_hint: Label
var cruscotto: Label
var cruscotto_freccia: Label
var _strada_visibile: float = 0.0
var servizio_label: Label
var servizio_banner: Label
var servizio_sub: Label
var _servizio_visibile: float = 0.0
var _era_pad: bool = false
var _ciclo_ref: Node = null

func _trova_ciclo() -> Node:
	if is_instance_valid(_ciclo_ref):
		return _ciclo_ref
	# Il ciclo del giorno adesso sta nella citta'. Si cerca ovunque, cosi'
	# funziona sia con la citta' sia con la vecchia piazza da sola.
	_ciclo_ref = get_tree().get_root().find_child("GiornoNotte", true, false)
	return _ciclo_ref


func _on_directing_started() -> void:
	_directing_active = true
	directing_panel.visible = true
	directing_result_label.visible = false
	directing_bump_label.text = ""
	directing_distance_bar.value = 0.0
	directing_align_bar.value = 0.0
	directing_speed_label.text = ""


func _on_directing_update(progress: Dictionary) -> void:
	if not _directing_active:
		return
	directing_distance_bar.value = progress.get("distance_ratio", 0.0)
	directing_distance_bar.modulate = _bar_color(progress.get("distance_ok", false), progress.get("distance_ratio", 0.0))
	directing_align_bar.value = progress.get("align_ratio", 0.0)
	directing_align_bar.modulate = _bar_color(progress.get("align_ok", false), progress.get("align_ratio", 0.0))
	directing_speed_label.text = "Lento, bene!" if progress.get("speed_ok", false) else "Piano, piano..."
	directing_speed_label.modulate = Color(0.4, 1.0, 0.5) if progress.get("speed_ok", false) else Color(0.9, 0.9, 0.9)
	if progress.has("time_left"):
		directing_time_label.text = "%ds" % int(ceil(progress["time_left"]))
		directing_time_label.modulate = Color(1.0, 0.4, 0.3) if progress["time_left"] < 10.0 else Color(0.8, 0.8, 0.8)


func _bar_color(is_ok: bool, ratio: float) -> Color:
	if is_ok:
		return Color(0.3, 0.9, 0.4)
	elif ratio > 0.5:
		return Color(1.0, 0.8, 0.2)
	else:
		return Color(0.9, 0.9, 0.9)


func _on_directing_bump(bump_count: int) -> void:
	directing_bump_label.text = "SBAM! (%d)" % bump_count
	_bump_flash_time = 0.8


func _on_directing_gesture(text: String, from_driver: bool) -> void:
	if from_driver:
		driver_reply_label.text = "« %s »" % text
		driver_reply_label.modulate.a = 1.0
		_reply_time = 1.8
	else:
		shout_label.text = text
		shout_label.modulate.a = 1.0
		_shout_time = 1.0


func _on_directing_ended(score: float, aborted: bool) -> void:
	_directing_active = false
	directing_panel.visible = false
	directing_result_label.visible = true
	if aborted:
		directing_result_label.text = "Se n'è andato spazientito!"
		directing_result_label.modulate = Color(1.0, 0.5, 0.4)
	else:
		directing_result_label.text = "Parcheggiato! (%d%%)" % int(round(score * 100))
		directing_result_label.modulate = Color(0.5, 1.0, 0.6)
	_result_hide_time = 1.3


func _on_inventory_changed(_emblems: Dictionary) -> void:
	_refresh_emblem_counter()
	if inventory_panel.visible:
		_refresh_inventory()


func _refresh_emblem_counter() -> void:
	var count := GameManager.emblem_count()
	var roba := 0
	for id in GameManager.DECOR_IDS:
		if GameManager.has_upgrade(id):
			roba += 1
	# **I soldi che stanno in giro.** Se hai gente che lavora per te, quello
	# che hanno incassato non e' ancora tuo: sta in tasca a loro, e la sera
	# se ne tengono un quarto di quello che non sei passato a prendere.
	# Questa riga e' il promemoria che c'e' un giro da fare — senza, uno se
	# ne dimentica e non capisce perche' guadagna meno del previsto.
	var in_giro: int = GameManager.cassa_in_giro()
	if in_giro > 0:
		emblem_counter_label.text = Pad.traduci(
			"€%d 'n mano ê guagliune — [M] pe' vedé addò stanno" % in_giro)
		return
	# Il promemoria del tasto I usciva solo se avevi degli stemmi: chi
	# comprava soltanto l'ombrellone non scopriva mai che lo zaino esisteva.
	if count > 0 and roba > 0:
		emblem_counter_label.text = Pad.traduci("Stemmi: %d (€%d) · %d cos%s da piazzare — [I] zaino" % [
			count, GameManager.emblems_total_value(), roba,
			("a" if roba == 1 else "e")])
	elif count > 0:
		emblem_counter_label.text = Pad.traduci("Stemmi: %d (€%d) — [I] zaino" % [
			count, GameManager.emblems_total_value()])
	elif roba > 0:
		emblem_counter_label.text = Pad.traduci("%d cos%s da piazzare — [I] zaino" % [
			roba, ("a" if roba == 1 else "e")])
	else:
		emblem_counter_label.text = ""


## Lo zaino: la roba comprata, con la sua figura, divisa in due scomparti —
## quella che si piazza in piazza e quella che si porta addosso. Sotto, gli
## stemmi rubati (che non hanno una figura loro: sono tutti diversi).
##
## `_inv_placeable` e' la lista che i tasti 1-6 usano per sapere quale
## oggetto prendere in mano.
func _refresh_inventory() -> void:
	_inv_placeable = []
	for id in GameManager.DECOR_IDS:
		if GameManager.has_upgrade(id):
			_inv_placeable.append(id)

	# **L'etichetta dice quante ne hai in mano, non "in piazza".**
	# Adesso che se ne possono avere piu' d'una, quello che serve sapere
	# guardando lo zaino e' quante te ne restano da appoggiare.
	var voci: Array = []
	for i in _inv_placeable.size():
		var id2: String = _inv_placeable[i]
		var libere: int = GameManager.decor_libere(id2)
		var tot: int = GameManager.decor_possedute(id2)
		voci.append({
			"id": id2, "posseduto": libere > 0,
			"etichetta": ("×%d" % libere) if libere > 0 else "tutte 'n piazza",
		})
	var alto := _disegna_griglia(_inv_grid, voci, 4, 74.0, _sel)

	var righe: Array = []
	if _inv_placeable.is_empty():
		righe.append("Lo zaino è vuoto.")
		righe.append("")
		righe.append("Al BAZAR (tendone verde) si comprano sedia,")
		righe.append("ombrellone, tavolino, radio, piante e luminarie.")
		righe.append("Da 'O ZIO gli attrezzi del mestiere.")
	else:
		if _sel >= 0 and _sel < _inv_placeable.size():
			var id3: String = _inv_placeable[_sel]
			righe.append(str(GameManager.UPGRADES[id3]["name"]))
			# A che serve: nello zaino serve più che al Bazar, perché è
			# lì che uno torna a chiedersi perché l'aveva comprato.
			righe.append(str(GameManager.UPGRADES[id3]["desc"]))
			var lib: int = GameManager.decor_libere(id3)
			var tut: int = GameManager.decor_possedute(id3)
			righe.append("Ne tieni %d: %d 'n piazza, %d 'a piazzà." % [
				tut, tut - lib, lib])
			if lib > 0:
				righe.append("Schiaccia %d: 'o pigli 'n mano, po' CLICCA addò 'o vuò."
					% (_sel + 1))
			else:
				righe.append("Stanno tutte 'n piazza. Al BAZAR se ne accatta n'ata.")
		righe.append("")

	# Quello che porti addosso: non si piazza, si vede sul personaggio.
	var addosso: Array = []
	for id4 in GameManager.TOOL_IDS:
		if GameManager.has_upgrade(id4):
			addosso.append(str(GameManager.UPGRADES[id4]["name"]))
	if addosso.is_empty():
		righe.append("ADDOSSO: niente ancora.")
	else:
		righe.append("ADDOSSO: " + ", ".join(addosso))
	if GameManager.has_upgrade("fischietto"):
		righe.append("   [Q] fischia e le auto vengono da te")
	if GameManager.caffe > 0 or GameManager.cigarettes > 0:
		righe.append("IN TASCA: %d caffè [R] · %d sigarette [X]" % [
			GameManager.caffe, GameManager.cigarettes])
	if GameManager.pittura > 0:
		righe.append("PITTURA JANCA: %d passat%s (sulle strisce blu, [E])" % [
			GameManager.pittura, "a" if GameManager.pittura == 1 else "e"])
	# (0.64) 'E strisce blu: addò stanno e quanto manca.
	for zb in GameManager.strisce_blu:
		var e: Dictionary = GameManager.strisce_blu[zb]
		righe.append("STRISCE BLU a %s: parchimetre %d/%d sfasciate, %d poste ripittate" % [
			str(GameManager.NOMI_PIAZZE.get(zb, zb)),
			(e.get("rotti", []) as Array).size(), int(e.get("parchimetri", 0)),
			(e.get("pittati", []) as Array).size()])
	righe.append("")

	var emblems: Dictionary = GameManager.emblems
	if emblems.is_empty():
		righe.append("STEMMI: nessuno. Stanno sul cofano delle auto di")
		righe.append("lusso: aspetta che l'autista si allontani e premi G.")
	else:
		var pezzi: Array = []
		for name in emblems:
			pezzi.append("%s ×%d" % [name, emblems[name]["count"]])
		righe.append("STEMMI: " + ", ".join(pezzi))
		righe.append("Valore €%d — vendili da 'O Zio." %
			GameManager.emblems_total_value())

	righe.append("")
	var presi: int = GameManager.manifesti_presi()
	var quanti_tot: int = GameManager.MANIFESTI.size()
	righe.append("MANIFESTI: %d/%d" % [presi, quanti_tot])
	if presi >= quanti_tot:
		righe.append("Trovati tutti. Sî 'o rre d''e mure.")
	else:
		var manca: Array = GameManager.manifesti_mancanti()
		righe.append("Uno sta ccà → " + str(manca[0]["dove"]))

	inventory_label.position.y = 48.0 + maxf(alto, 40.0)
	inventory_label.size.y = 496.0 - inventory_label.position.y
	inventory_label.text = Pad.traduci("\n".join(righe))


func _on_directing_released() -> void:
	_directing_active = false
	directing_panel.visible = false
	directing_result_label.visible = false
	shout_label.text = ""
	_shout_time = 0.0


func _on_shift_ended(summary: Dictionary) -> void:
	summary_label.text = _riepilogo_giornata(summary)
	summary_strada_btn.visible = false
	summary_panel.visible = true
	if _summary_first_btn and is_instance_valid(_summary_first_btn):
		_summary_first_btn.grab_focus()
	GameManager.piglia_o_mouse(false)


## **'O riepilogo d''a jurnata.**
##
## Prima era una tabella di statistiche: clienti serviti, pugni sferrati,
## auto danneggiate. Numeri veri, ma numeri di un turno — e un turno non e'
## una giornata. Adesso e' il resoconto di una sera: a che ora sei
## rientrato, quanto hai consegnato, che cosa resta da pagare, e che faccia
## ha fatto lei. Le statistiche ci stanno ancora, ma **sotto**, dove vanno.
## Il conto della sera, l'orologio e la commissione in mano: la riga che
## trasforma ogni mancia in "una parte di quello che manca".
func _aggiorna_conto() -> void:
	if conto_label == null or not is_instance_valid(conto_label):
		return
	var dovuto: int = GameManager.spese_dovute()
	if dovuto <= 0:
		conto_label.text = "'O conto: PAVATO"
		conto_label.modulate = Color(0.62, 1.0, 0.66)
		conto_voci.text = ""
	else:
		conto_label.text = "STASERA CE VONNO  €%d" % dovuto
		# Da arancione a rosso man mano che la giornata se ne va: alle
		# undici di sera con settanta euro scoperti il colore lo dice
		# prima del numero.
		var quanto_manca: float = clampf(
			float(dovuto) / maxf(float(dovuto + GameManager.money), 1.0),
			0.0, 1.0)
		var tardi: float = clampf(GameManager.ore_passate() / 16.0, 0.0, 1.0)
		conto_label.modulate = Color(1.0, 0.82, 0.46).lerp(
			Color(1.0, 0.44, 0.38), maxf(quanto_manca * 0.6, tardi * 0.8))
		var righe: Array = []
		for v in GameManager._ordine_spese():
			if righe.size() >= 4:
				break
			var rit: int = GameManager.giornata - int(v["giorno"])
			righe.append("%s €%d%s" % [str(v["nome"]), int(v["importo"]),
				("  (+%dg)" % rit) if rit > 0 else ""])
		conto_voci.text = "\n".join(righe)

	if cumm_label != null and is_instance_valid(cumm_label):
		var c: Dictionary = GameManager.commissione_in_mano()
		if c.is_empty():
			cumm_label.text = ""
		else:
			var sana := ""
			if bool(c.get("fragile", false)):
				sana = "  · sana %d%%" % int(float(c.get("integrita", 1.0)) * 100.0)
			cumm_label.text = "%s → %s   (%d\")%s" % [str(c["nome"]),
				str(c["nome_a"]), int(maxf(float(c.get("scade", 0.0)), 0.0)), sana]


func _riepilogo_giornata(s: Dictionary) -> String:
	var r: Array = []
	var giorno: int = int(s.get("giornata", 1))
	var ora: float = float(s.get("orario_ritiro", -1.0))
	var testo_ora := "—"
	if ora >= 0.0:
		var h := int(12.0 + ora) % 24
		var m := int((ora - floor(ora)) * 60.0)
		testo_ora = "%02d:%02d" % [h, m]

	if s.get("hospitalized", false):
		r.append("GIORNO %d — T'HANNO PURTATO 'O SPITALE" % giorno)
		summary_label.modulate = Color(1.0, 0.55, 0.5)
	elif s.get("notte_ncella", false):
		# Il terzo fermo della giornata: la sera non c'e' stata proprio.
		r.append("GIORNO %d — 'A NUTTATA T'HÊ FATTA DINT'Â CELLA" % giorno)
		summary_label.modulate = Color(1.0, 0.5, 0.45)
	elif s.get("arrested", false):
		r.append("GIORNO %d — T'HANNO PIGLIATO" % giorno)
		summary_label.modulate = Color(1.0, 0.6, 0.55)
	else:
		r.append("GIORNO %d — se va a durmi'" % giorno)
		summary_label.modulate = Color(1, 1, 1)
	r.append("Rientrato 'e %s." % testo_ora)
	r.append("")

	# --- 'O cunto 'e casa: la parte che conta -------------------------
	r.append("── 'O CUNTO ───────────────────────")
	r.append("Guadagnato oggi: €%d" % int(s.get("earned", 0)))
	r.append("Consegnato 'a Nunzia: €%d" % int(s.get("consegnato", 0)))
	if int(s.get("extra_richiesto", 0)) > 0:
		if s.get("extra_dato", false):
			r.append("  ...cchiù €%d 'e spese soie." % int(s["extra_richiesto"]))
		else:
			r.append("  ...t'ha chiesto €%d e nun ce l'hê date." % int(s["extra_richiesto"]))
	var scoperto: int = int(s.get("scoperto", 0))
	if scoperto <= 0:
		r.append("Tutto pavato. Nun resta niente 'a fa'.")
	else:
		r.append("RESTA 'A PAVÀ: €%d" % scoperto)
		for v in s.get("spese_aperte", []):
			var rit: int = int(v.get("ritardo", 0))
			var coda := ""
			if rit > 0:
				coda = "  (%d juorne 'e ritardo)" % rit
			r.append("   · %s €%d%s" % [str(v.get("nome", "")),
				int(v.get("importo", 0)), coda])
	r.append("In sacca: €%d" % int(s.get("money", 0)))
	var umore: float = float(s.get("umore_moglie", 60.0))
	r.append("Nunzia: %s" % _faccia_moglie(umore))
	for f in s.get("conseguenze", []):
		r.append("!! " + str(f))
	r.append("")

	# --- 'A jurnata: quello che hai fatto ------------------------------
	r.append("── 'A JURNATA ─────────────────────")
	r.append("Clienti serviti: %d   ·   perse: %d"
		% [int(s.get("clients_served", 0)), int(s.get("clients_lost", 0))])
	if int(s.get("commissioni_fatte", 0)) > 0:
		r.append("Cummissiune purtate: %d" % int(s["commissioni_fatte"]))
	if int(s.get("scopa_vinte", 0)) > 0:
		r.append("Partite 'e scopa vinte: %d" % int(s["scopa_vinte"]))
	if int(s.get("perso_al_gioco", 0)) > 0:
		r.append("Perzo cu 'e ccarte: €%d" % int(s["perso_al_gioco"]))
	if int(s.get("fines_paid", 0)) > 0:
		r.append("Multe: %d" % int(s["fines_paid"]))
	if int(s.get("forced_payments", 0)) > 0:
		r.append("Pagamenti pigliate 'e forza: %d" % int(s["forced_payments"]))
	if int(s.get("emblems_stolen", 0)) > 0:
		r.append("Stemme: %d (€%d 'a 'O Zio)"
			% [int(s["emblems_stolen"]), int(s.get("emblem_earnings", 0))])
	if int(s.get("dipendenti_ritirato", 0)) > 0:
		r.append("Ritirato 'a mano d''e guagliune: €%d" % int(s["dipendenti_ritirato"]))
	if int(s.get("auto_vennute", 0)) > 0:
		r.append("Machine purtate ô garage: %d (€%d)"
			% [int(s["auto_vennute"]), int(s.get("soldi_auto", 0))])
	if int(s.get("dipendenti_incasso", 0)) > 0 or int(s.get("dipendenti_paghe", 0)) > 0:
		r.append("Guagliune, 'a mità ca nun hê ritirato: €%d (pavate €%d)"
			% [int(s.get("dipendenti_incasso", 0)), int(s.get("dipendenti_paghe", 0))])
	for g in s.get("dipendenti_scappati", []):
		r.append("!! %s se n'è ghiuto cu 'nu rivale (s'è purtato €%d)"
			% [str(g.get("nome", "'O guaglione")), int(g.get("cassa", 0))])
	# **'A voce.** Si vede solo quando è successo qualcosa: a zero non c'è
	# niente da dire, e una riga che dice "neutro" tutte le sere è rumore.
	var voce: float = float(s.get("voce", 0.0))
	if voce >= 0.25:
		r.append("'O quartiere parla bbuono 'e te: 'e clienti pavano cchiù vulentiere.")
	elif voce <= -0.25:
		r.append("!! 'O quartiere parla male 'e te. Se vede ncopp'ê mance.")
	if int(s.get("affitto_pagato", 0)) > 0:
		r.append("Affitto d''e piazze: €%d" % int(s["affitto_pagato"]))
	if not s.get("zone_perse", []).is_empty():
		r.append("!! Nun hê pavato ll'affitto: 'e piazze s''e so' ripigliate.")
	# **'O lotto 'e stasera** (0.62): l'estrazione si fa proprio adesso, e
	# prima nessuno ti diceva com'era andata.
	if not GameManager.lotto_esiti.is_empty() \
			and int(GameManager.lotto_ultima.get("giornata", -1)) == giorno:
		r.append("")
		r.append("── 'O LOTTO ───────────────────────")
		for riga in PannelloLottoS.esiti_testo(true).split("\n"):
			r.append(riga)
	if s.get("boss_defeated", false):
		r.append("Borrelli cunvinto. (+€%d)" % GameManager.BOSS_REWARD)
	elif s.get("boss_spawned", false):
		r.append("Borrelli è venuto e nun ll'hê cunvinto.")
	return "\n".join(r)


func _faccia_moglie(umore: float) -> String:
	if umore >= 80.0:
		return "cuntenta assaje  (%d)" % int(umore)
	if umore >= 60.0:
		return "sta bbona  (%d)" % int(umore)
	if umore >= 40.0:
		return "nun parla  (%d)" % int(umore)
	if umore >= 22.0:
		return "è nnervosa  (%d)" % int(umore)
	return "NUN NE PO' CCHIU'  (%d)" % int(umore)


# ---------------------------------------------------------------------------
# 'A cella
# ---------------------------------------------------------------------------
#
# **Cinche secunne, e se scanzano.**
#
# Il capo l'ha chiesta così, e il "skippabili" è la parte importante: una
# punizione deve costare, non annoiare. Quello che ti punisce davvero non
# sono i cinque secondi — sono i soldi che non hai più, la serata che non
# hai fatto, e la camminata di ritorno da fuori città domani mattina.
#
# Lo schermo è nero pieno con due righe sopra. Niente sbarre disegnate:
# una cella fatta a scatole in un gioco che non ha nessun'altra stanza
# sarebbe la cosa più brutta della build, e per cinque secondi non vale.

const GALERA_FONDO := Color(0.03, 0.03, 0.04, 1.0)

var _galera_panel: ColorRect = null
var _galera_testo: Label = null
var _galera_sotto: Label = null
var _galera_left: float = 0.0


func _su_galera(pigliato: int) -> void:
	if _galera_panel == null or not is_instance_valid(_galera_panel):
		_costruisci_galera()
	_galera_testo.text = "DINT'Ô CARCERE"
	var righe: Array = ["T'hanno pigliato tutto chello ca tenive 'n sacca."]
	if pigliato > 0:
		righe.append("€%d." % pigliato)
	righe.append("")
	righe.append("Dimane matina t'arapono 'o purtone.")
	_galera_sotto.text = "\n".join(righe)
	_galera_panel.visible = true
	_galera_left = GameManager.GALERA_SECUNNE
	get_tree().paused = true
	GameManager.piglia_o_mouse(false)
	SoundManager.play("fail", -3.0, 0.55)


func _costruisci_galera() -> void:
	_galera_panel = ColorRect.new()
	_galera_panel.color = GALERA_FONDO
	_galera_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_galera_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_galera_panel.visible = false
	add_child(_galera_panel)

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.position = Vector2(-320, -110)
	col.custom_minimum_size = Vector2(640, 0)
	col.add_theme_constant_override("separation", 16)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	_galera_panel.add_child(col)

	_galera_testo = Label.new()
	_galera_testo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_galera_testo.add_theme_font_size_override("font_size", 42)
	_galera_testo.add_theme_color_override("font_color", Color(0.90, 0.74, 0.30))
	col.add_child(_galera_testo)

	_galera_sotto = Label.new()
	_galera_sotto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_galera_sotto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_galera_sotto.add_theme_font_size_override("font_size", 20)
	_galera_sotto.add_theme_color_override("font_color", Color(0.86, 0.84, 0.80))
	col.add_child(_galera_sotto)

	var pie := Label.new()
	pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pie.add_theme_font_size_override("font_size", 15)
	pie.add_theme_color_override("font_color", Color(0.58, 0.56, 0.54))
	pie.text = "prieme 'nu tasto qualunque pe' scanzà"
	col.add_child(pie)


## Il pannello sta su un albero in pausa, quindi il conto alla rovescia non
## può stare in `_process`: `PROCESS_MODE_ALWAYS` sull'HUD lo farebbe
## girare ma si porterebbe appresso tutto il resto. Si conta qui, dove il
## tempo passa davvero.
func _process_galera(delta: float) -> void:
	if _galera_panel == null or not _galera_panel.visible:
		return
	_galera_left -= delta
	if _galera_left <= 0.0:
		_chiude_galera()


func _chiude_galera() -> void:
	if _galera_panel == null or not _galera_panel.visible:
		return
	_galera_panel.visible = false
	GameManager.esce_d_a_galera()


## 'A barra d''o sciato. 'O culore dice tre cose: verde staje buono,
## arancione staje asciuenno, rosso nun mine cchiù.
func _su_sciato(quanto: float) -> void:
	if sciato_bar == null or not is_instance_valid(sciato_bar):
		return
	sciato_bar.value = quanto
	var q: float = quanto / maxf(GameManager.SCIATO_MAX, 1.0)
	var c := Color(0.55, 0.82, 0.52)
	if q < 0.16:
		c = Color(0.92, 0.36, 0.32)
	elif q < 0.42:
		c = Color(0.94, 0.72, 0.32)
	UiStile.colora_barra(sciato_bar, c)
	if sciato_caption != null and is_instance_valid(sciato_caption):
		sciato_caption.modulate = c.lerp(Color(0.9, 0.9, 0.9), 0.45)


## 'Na manopola d''o volume: 'a scritta, 'o cursore e 'o nummero 'n
## percentuale. 'O nummero serve: senza, uno nun sape si sta a zero o a 'nu
## filo, e cu 'o gioco muto penza ca s'è rutto quaccosa.
func _slider_volume(nome: String, y: float, valore: float,
		quanno_cagna: Callable) -> void:
	var lab := Label.new()
	lab.position = Vector2(60, y - 22)
	lab.size = Vector2(160, 20)
	lab.add_theme_font_size_override("font_size", 13)
	lab.modulate = Color(0.86, 0.84, 0.80)
	lab.text = nome
	pause_panel.add_child(lab)

	var num := Label.new()
	num.position = Vector2(270, y - 22)
	num.size = Vector2(70, 20)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	num.add_theme_font_size_override("font_size", 13)
	num.modulate = Color(0.72, 0.70, 0.66)
	num.text = "%d%%" % int(round(valore * 100.0))
	pause_panel.add_child(num)

	var s := HSlider.new()
	s.position = Vector2(60, y)
	s.size = Vector2(280, 20)
	s.custom_minimum_size = Vector2(280, 20)
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = valore
	s.value_changed.connect(func(v: float):
		num.text = "%d%%" % int(round(v * 100.0))
		quanno_cagna.call(v))
	pause_panel.add_child(s)
