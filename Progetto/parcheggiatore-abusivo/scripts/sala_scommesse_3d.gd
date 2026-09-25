extends StaticBody3D
## SalaScommesse3D — 'a sala scommesse cu 'a slot
##
## Un'insegna al neon, una vetrina di quelle oscurate, e dentro una slot
## machine che funziona per davvero. È il posto dove finiscono i soldi che
## il parcheggiatore si è fatto in piazza, ed è l'unica attività del gioco
## in cui puoi perdere tutto in due minuti.
##
## ## La slot
##
## Tre rulli, sei simboli, una giocata da un euro. I rulli si fermano uno
## alla volta da sinistra a destra, e questo è deliberato: il rullo che si
## ferma per ultimo è tutta l'attesa che c'è in una slot, e se si fermassero
## insieme non ci sarebbe niente da guardare.
##
## ## Il ritorno al giocatore
##
## Le probabilità sono scritte in `PESI` e i premi in `PREMI`, e la somma
## `sum(p(simbolo)^3 * premio)` più le coppie sta poco sotto la giocata:
## **88 centesimi per ogni euro** (misurato, non stimato). Non è un
## dettaglio da regolare a occhio — è la cosa che decide se questa stanza è
## un passatempo o un buco nero. Sotto l'ottanta smetti di giocarci dopo tre
## giri; sopra il cento la piazza non serve più a niente e il gioco intero
## si rompe.
##
## Quasi metà della restituzione viene dalle COPPIE, che ridanno solo la
## giocata: si vince spesso e non si guadagna niente. È la struttura di una
## slot vera, e serve a tenerti lì mentre l'euro se ne va.
##
## La terna della corona esce una volta su quattromilaseicento. Se un
## giocatore la vede, quella è la sua storia della serata.
##
## Il test è in `_stampa_ritorno()`, che non viene mai chiamato in partita:
## serve a ricontrollare il numero se qualcuno tocca i pesi.
##
## Nota sul motivo per cui le probabilità non sono uniformi: con sei simboli
## equiprobabili la terna esce una volta su trentasei, cioè quasi mai vedi
## niente. Coi pesi sbilanciati le terne facili escono spesso e valgono
## poco, e la terna del pallone d'oro non la vedi quasi mai — che è
## esattamente la forma di una slot vera.

const Tex := preload("res://scripts/textures.gd")
const Models := preload("res://scripts/models.gd")
const CarteScript := preload("res://scripts/carte.gd")
const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")

enum Stato { FERMA, GIRA, ESITO }

const GIOCATA: int = 1
const CALORE: float = 0.6

## I sei simboli, dal più comune al più raro. **Sono carte napoletane**, non
## ciliegie e campanelle.
##
## Il primo tentativo erano emoji su una Label3D, ed è stato un errore
## istruttivo: il font di Godot non ha i glifi a colori, così di sei simboli
## se ne disegnava uno e gli altri cinque erano rettangoli vuoti. A schermo
## sembrava una slot rotta.
##
## Le carte risolvono il problema e sono anche la cosa giusta: il mazzo è
## già in memoria come atlante (`carte.gd`), i sei simboli sono sei celle di
## quella stessa texture, e una slot napoletana con dentro l'asso 'e denari
## e 'o re 'e denari dice da sola dove ti trovi.
const SIMBOLI := [
	[2, 3],    # tre 'e bastoni
	[0, 5],    # cinque 'e coppe
	[3, 7],    # sette 'e spade
	[1, 1],    # asso 'e denari
	[0, 9],    # cavallo 'e coppe
	[1, 10],   # re 'e denari — 'o jackpot
]
const NOMI := ["tre 'e bastoni", "cinque 'e coppe", "sette 'e spade",
	"asso 'e denari", "cavallo", "re 'e denari"]
const PESI := [30, 24, 18, 13, 9, 6]
## Premio per la terna di ogni simbolo, in euro.
const PREMI := [3, 7, 14, 26, 60, 200]
## Consolazione: due uguali qualunque.
const PREMIO_COPPIA: int = 1

const GIRO_BASE: float = 1.1        # quando si ferma il primo rullo
const GIRO_PASSO: float = 0.55      # e quanto dopo gli altri due
const DURATA_ESITO: float = 2.4

var _stato: int = Stato.FERMA
var _t: float = 0.0
var _rulli: Array[int] = [0, 0, 0]
var _fermo: Array[bool] = [false, false, false]
var _label_rulli: Array = []
var _scia: Array[float] = [0.0, 0.0, 0.0]
var _esito: String = ""
var _bubble: Node3D
var _rng := RandomNumberGenerator.new()
var _totale_peso: int = 0
var _vinto_oggi: int = 0
var _giocato_oggi: int = 0


func _ready() -> void:
	add_to_group("attivita")
	add_to_group("scommesse")
	collision_layer = 1
	collision_mask = 0
	_rng.randomize()
	for p in PESI:
		_totale_peso += p
	_build_visual()
	_build_collisione()
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 2.9, 0.7)
	add_child(_bubble)
	for i in range(3):
		_rulli[i] = _sorteggia()
	_ridisegna()


# ---------------------------------------------------------------------------
# La stanza
# ---------------------------------------------------------------------------

func _build_visual() -> void:
	# La facciata: vetrina scura e insegna. La sala è appoggiata a un muro,
	# quindi tutto quello che si costruisce guarda verso +Z.
	var vetro := MeshInstance3D.new()
	var vm := BoxMesh.new()
	vm.size = Vector3(3.6, 2.3, 0.1)
	vetro.mesh = vm
	vetro.position = Vector3(0, 1.4, -0.05)
	var mv := StandardMaterial3D.new()
	mv.albedo_color = Color(0.07, 0.09, 0.12)
	mv.metallic = 0.3
	mv.roughness = 0.15
	vetro.material_override = mv
	add_child(vetro)

	# L'insegna. Il verde acido e il rosso delle sale scommesse vere sono
	# l'unica cosa che le rende riconoscibili a colpo d'occhio in una via.
	var ins := MeshInstance3D.new()
	var im := BoxMesh.new()
	im.size = Vector3(3.8, 0.66, 0.16)
	ins.mesh = im
	ins.position = Vector3(0, 2.95, 0.06)
	var mi := StandardMaterial3D.new()
	mi.albedo_color = Color(0.06, 0.24, 0.1)
	mi.emission_enabled = true
	mi.emission = Color(0.1, 0.75, 0.28)
	mi.emission_energy_multiplier = 0.9
	ins.material_override = mi
	add_child(ins)

	var scritta := Label3D.new()
	# Il testo deve stare DENTRO l'insegna, che è larga 3,8 m. A 60 punti
	# con un pixel_size di 0,0032 una riga di ventinove caratteri usciva di
	# più di un metro per parte: si leggeva a metà sul muro.
	scritta.text = "SALA SCOMMESSE"
	scritta.font_size = 56
	scritta.pixel_size = 0.0043
	scritta.position = Vector3(0, 2.95, 0.16)
	scritta.modulate = Color(1.0, 0.96, 0.6)
	scritta.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	scritta.double_sided = false
	add_child(scritta)

	# Il neon rosso "APERTO", che è la seconda metà del linguaggio.
	var neon := OmniLight3D.new()
	neon.light_color = Color(0.3, 1.0, 0.45)
	neon.light_energy = 1.6
	neon.omni_range = 7.0
	neon.position = Vector3(0, 2.6, 1.0)
	neon.shadow_enabled = false
	add_child(neon)

	_build_slot()
	_build_totem()


## **'O totem d''e quote** (0.60, PSX): accanto alla slot, il tavolinetto
## col monitor che fa girare le quote, il computer per terra e la cassa che
## spara la telecronaca. Sta dentro al corpo della sala (3,6 × 1,5), dalla
## parte libera.
func _build_totem() -> void:
	for e in [
			["tavulinetto", Vector3(1.3, 0.0, 0.66), 0.0],
			["monitor", Vector3(1.3, 0.59, 0.72), 0.0],
			["computer", Vector3(1.66, 0.0, 0.62), -0.2],
			["cassa_stereo", Vector3(-1.3, 0.0, 0.85), 0.35],
			["cassa_stereo", Vector3(-1.55, 0.0, 0.8), -0.25],
		]:
		var o := Models.spawn(str(e[0]))
		if o == null:
			continue
		o.position = e[1]
		o.rotation.y = float(e[2])
		add_child(o)


## Il mobile della slot: cassone, cristallo dei rulli, pulsantiera, leva.
func _build_slot() -> void:
	var slot := Node3D.new()
	slot.position = Vector3(0, 0, 0.7)
	add_child(slot)

	var corpo := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(0.78, 1.85, 0.62)
	corpo.mesh = cm
	corpo.position = Vector3(0, 0.92, 0)
	var mc := StandardMaterial3D.new()
	mc.albedo_color = Color(0.62, 0.1, 0.12)
	mc.roughness = 0.42
	mc.metallic = 0.25
	corpo.material_override = mc
	slot.add_child(corpo)

	# Il cristallo dei rulli, inclinato verso chi gioca.
	var vetro := MeshInstance3D.new()
	var vm := BoxMesh.new()
	vm.size = Vector3(0.66, 0.42, 0.04)
	vetro.mesh = vm
	vetro.position = Vector3(0, 1.36, 0.3)
	var mv := StandardMaterial3D.new()
	mv.albedo_color = Color(0.03, 0.03, 0.04)
	mv.roughness = 0.1
	vetro.material_override = mv
	slot.add_child(vetro)

	# I tre rulli. Ognuno è un quad che mostra una cella dell'atlante delle
	# carte: cambiare simbolo vuol dire cambiare `material_override`, e i
	# materiali sono già tutti in cache dentro `Carte`, quindi anche a
	# sessanta cambi al secondo non si alloca niente.
	for i in range(3):
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.15, 0.245)
		q.mesh = qm
		q.position = Vector3((i - 1) * 0.185, 1.36, 0.33)
		slot.add_child(q)
		_label_rulli.append(q)

	# La pulsantiera e la leva.
	var piano := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.7, 0.06, 0.26)
	piano.mesh = pm
	piano.position = Vector3(0, 1.05, 0.34)
	piano.rotation.x = -0.22
	var mp := StandardMaterial3D.new()
	mp.albedo_color = Color(0.14, 0.14, 0.16)
	piano.material_override = mp
	slot.add_child(piano)

	var bottone := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.055
	bm.bottom_radius = 0.055
	bm.height = 0.04
	bm.radial_segments = 12
	bottone.mesh = bm
	bottone.position = Vector3(0, 1.09, 0.35)
	var mb := StandardMaterial3D.new()
	mb.albedo_color = Color(0.9, 0.75, 0.15)
	mb.emission_enabled = true
	mb.emission = Color(1.0, 0.72, 0.1)
	mb.emission_energy_multiplier = 0.6
	bottone.material_override = mb
	slot.add_child(bottone)

	var leva := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 0.02
	lm.bottom_radius = 0.02
	lm.height = 0.42
	lm.radial_segments = 8
	leva.mesh = lm
	leva.position = Vector3(0.46, 1.3, 0.05)
	leva.rotation.z = 0.22
	var ml := StandardMaterial3D.new()
	ml.albedo_color = Color(0.75, 0.75, 0.78)
	ml.metallic = 0.8
	ml.roughness = 0.25
	leva.material_override = ml
	slot.add_child(leva)

	var pomo := MeshInstance3D.new()
	var pom := SphereMesh.new()
	pom.radius = 0.05
	pom.height = 0.1
	pomo.mesh = pom
	pomo.position = Vector3(0.51, 1.51, 0.05)
	var mpo := StandardMaterial3D.new()
	mpo.albedo_color = Color(0.8, 0.1, 0.1)
	pomo.material_override = mpo
	slot.add_child(pomo)


func _build_collisione() -> void:
	var f := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(3.6, 3.3, 1.5)
	f.shape = b
	f.position = Vector3(0, 1.65, 0.35)
	add_child(f)


# ---------------------------------------------------------------------------
# Giocare
# ---------------------------------------------------------------------------

func get_interact_prompt(_da: Vector3) -> String:
	if _stato == Stato.GIRA:
		return "..."
	if _stato == Stato.ESITO:
		return _esito
	return "SALA — [E] slot €%d (terna: da €%d a €%d)  ·  [1] 'e ppartite" % [
		GIOCATA, PREMI[0], PREMI[PREMI.size() - 1]]


# ---------------------------------------------------------------------------
# 'E PARTITE VIRTUALE
# ---------------------------------------------------------------------------
#
# **'A sala nun è sulo 'e slot.** Le slot durano tre secondi e non si
# raccontano; una partita dura nove secondi e ha una storia dentro — chi
# segna, chi si fa cacciare, chi prende il palo. È la differenza fra
# perdere un euro e perdere un euro *tifando*, ed è per questo che le sale
# vere hanno il tabellone del calcio in mezzo alla parete.
#
# Il pannello è uno per tutta la partita, appeso alla radice: dentro c'è
# un tabellone intero e rifarlo a ogni apertura si sentirebbe.
const PannelloPartite := preload("res://scripts/pannello_partite.gd")

static var _partite_panel: CanvasLayer = null


func apri_partite() -> void:
	if _partite_panel == null or not is_instance_valid(_partite_panel):
		_partite_panel = PannelloPartite.new()
		_partite_panel.name = "PannelloPartite"
		get_tree().root.add_child(_partite_panel)
	_di("Ccà se scommette. 'E partite so' cchelle d''e rrione.")
	_partite_panel.apri()


func compra_voce(indice: int) -> void:
	if indice == 0:
		apri_partite()


func player_interact() -> void:
	if _stato != Stato.FERMA:
		return
	if not GameManager.paga(GIOCATA):
		SoundManager.play("fail", -8.0, 0.9)
		_di("E mettece 'e sorde, prim'!")
		return
	_giocato_oggi += GIOCATA
	GameManager.add_heat(CALORE)
	SoundManager.play("coin", -6.0, 1.1)
	for i in range(3):
		_fermo[i] = false
		_scia[i] = 0.0
	_stato = Stato.GIRA
	_t = 0.0


func _physics_process(delta: float) -> void:
	var pl := get_tree().get_first_node_in_group("player")
	if pl != null and pl.get("current_target") == self \
			and Input.is_action_just_pressed("buy_1"):
		apri_partite()
	match _stato:
		Stato.GIRA:
			_gira(delta)
		Stato.ESITO:
			_t -= delta
			if _t <= 0.0:
				_stato = Stato.FERMA


func _gira(delta: float) -> void:
	_t += delta
	var fermati := 0
	for i in range(3):
		if _fermo[i]:
			fermati += 1
			continue
		if _t >= GIRO_BASE + GIRO_PASSO * i:
			_fermo[i] = true
			# Il simbolo definitivo si sorteggia SOLO adesso, quando il
			# rullo si ferma. Sorteggiarlo alla giocata e poi far finta di
			# girare sarebbe lo stesso a conti fatti, ma vorrebbe dire
			# tenersi in giro tre numeri già decisi per un secondo e mezzo,
			# e prima o poi qualcuno li legge.
			_rulli[i] = _sorteggia()
			SoundManager.play("pop", -10.0, 0.8 + i * 0.18)
		else:
			# Mentre gira, il simbolo cambia in fretta ma rallentando.
			_scia[i] -= delta
			if _scia[i] <= 0.0:
				var quanto_manca: float = (GIRO_BASE + GIRO_PASSO * i) - _t
				_scia[i] = lerpf(0.03, 0.13, clampf(1.0 - quanto_manca, 0.0, 1.0))
				_rulli[i] = (_rulli[i] + 1) % SIMBOLI.size()
	_ridisegna()
	if fermati == 3:
		_paga()


func _sorteggia() -> int:
	var r := _rng.randi_range(0, _totale_peso - 1)
	var acc := 0
	for i in range(PESI.size()):
		acc += PESI[i]
		if r < acc:
			return i
	return PESI.size() - 1


func _paga() -> void:
	var vincita := 0
	var titolo := ""
	if _rulli[0] == _rulli[1] and _rulli[1] == _rulli[2]:
		vincita = PREMI[_rulli[0]]
		titolo = "TERNA 'E %s!" % NOMI[_rulli[0]].to_upper()
	elif _rulli[0] == _rulli[1] or _rulli[1] == _rulli[2] \
			or _rulli[0] == _rulli[2]:
		vincita = PREMIO_COPPIA
		titolo = "Doie uguale: te ripiglie 'a giocata."

	if vincita > 0:
		_vinto_oggi += vincita
		GameManager.add_money(vincita)
		_esito = "%s  +€%d" % [titolo, vincita]
		if vincita >= PREMI[3]:
			SoundManager.play("kaching", -1.0, 1.0)
			GameManager.screen_shake.emit(0.3)
			GameManager.event_started.emit("'A SLOT HA PAVATO! +€%d" % vincita)
			_di("Uè!! E chisto è 'nu miracolo!")
		else:
			SoundManager.play("coin", -3.0, 1.25)
	else:
		_esito = "Niente. [E] n'ata vota"
		SoundManager.play("fail", -12.0, 1.1)
		if _giocato_oggi - _vinto_oggi >= 12:
			# Dopo una dozzina di euro bruciati, la macchina ti prende pure
			# in giro. È l'unico avvertimento che il gioco dà.
			_di("Staje perdenno assaje, guagliò. Torna 'n piazza.")
	_stato = Stato.ESITO
	_t = DURATA_ESITO
	_ridisegna()


func _ridisegna() -> void:
	for i in range(3):
		if i >= _label_rulli.size():
			continue
		var q: MeshInstance3D = _label_rulli[i]
		var s: Array = SIMBOLI[_rulli[i]]
		q.material_override = CarteScript.materiale(
			CarteScript.indice(int(s[0]), int(s[1])))


func _di(t: String) -> void:
	if _bubble:
		_bubble.say(t, 2.6)


## Il ritorno al giocatore, in euro per euro giocato. Non serve in partita:
## si chiama a mano dopo aver toccato PESI o PREMI, e il numero deve restare
## fra 0.80 e 0.95. Sopra, la sala scommesse diventa più redditizia della
## piazza e il gioco perde il suo centro.
func _stampa_ritorno() -> void:
	var tot := 0
	for p in PESI:
		tot += p
	var atteso := 0.0
	for i in range(PESI.size()):
		var p: float = float(PESI[i]) / float(tot)
		atteso += pow(p, 3.0) * float(PREMI[i])
	# Le coppie: una qualunque di tre posizioni uguali a due a due, e la
	# terza diversa.
	var coppia := 0.0
	for i in range(PESI.size()):
		var p: float = float(PESI[i]) / float(tot)
		coppia += 3.0 * p * p * (1.0 - p)
	atteso += coppia * float(PREMIO_COPPIA)
	print("slot: ritorno = %.3f euro per euro giocato" % (atteso / float(GIOCATA)))
