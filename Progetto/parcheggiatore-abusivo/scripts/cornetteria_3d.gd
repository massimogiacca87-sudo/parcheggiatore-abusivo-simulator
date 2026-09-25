extends StaticBody3D
## Cornetteria
## Di giorno è una serranda abbassata e basta. Di notte alza, accende
## l'insegna, si riempie di odore di crema — e comincia ad arrivare gente.
##
## È la prima cosa del gioco che esiste solo a un'ora precisa, ed è per
## questo che è interessante: dà un motivo per essere in un posto a
## un momento invece che a un altro. La zona è di Tonino 'e Notte, quindi
## per adesso ci si può solo passare e guardare quello che ti perdi.
##
## **E ce se mangia 'o cornetto black and white (0.54).**
##
## Il capo: *"L'hp non sale da sola, bisogna mangiare un cornetto black and
## white disponibile però solo di notte alla cornetteria."*
##
## Dalla 0.54 le ossa non si rimettono da sole: quello che perdi te lo devi
## ricomprare. Il caffè e la spiga danno una spinta piccola; **il cornetto
## black and white è l'unico che ti rimette in piedi davvero** — e sta qui,
## di notte, in una zona che non è la tua.
##
## È la cosa che rende questo posto un posto invece di una vetrina: adesso
## c'è un motivo per attraversare mezza città alle due di notte, e il
## motivo è che ti hanno stesso di mazzate e non c'è nient'altro aperto.

const Tex := preload("res://scripts/textures.gd")
const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")

const SAY_APERTO := [
	"Cornetti calde! Appena sfurnate!",
	"Crema, amarena, nutella!",
	"Signò, uno o due?",
	"'A notte è fatta pe' chesto.",
]

## Quanto tempo passa fra un'auto e l'altra che si ferma qui, di notte.
const OGNI_AUTO_MIN: float = 26.0
const OGNI_AUTO_MAX: float = 34.0

var aperta: bool = false

var _ciclo: Node = null
var _serranda: Node3D
var _insegna_luce: OmniLight3D
var _insegna: Label3D
var _luci_interne: Array = []
var _bubble: Node3D
var _prossima: float = 0.0
var _detto: float = 0.0


func _ready() -> void:
	add_to_group("cornetteria")
	# **Senza stu gruppo nun succede niente.** `GRUPPI_BERSAGLIO` in
	# `player_fps.gd` è una lista chiusa: un oggetto che non ci sta dentro
	# viene trovato dal raggio e buttato via da `_bersaglio_valido()`, e
	# `[E]` non fa niente. È la stessa trappola che alla 0.44 ha fregato
	# tutte e sei le cose nuove, e sta scritta nel commento di quella lista.
	add_to_group("shop")
	collision_layer = 1
	collision_mask = 0
	_costruisci()
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 3.4, 0)
	add_child(_bubble)
	_aggiorna_apertura(false)


func collega_ciclo(c: Node) -> void:
	_ciclo = c


func _costruisci() -> void:
	# Il locale: un cubo di muratura con la vetrina davanti.
	var corpo := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(9.0, 4.6, 6.0)
	corpo.mesh = bm
	corpo.position = Vector3(0, 2.3, -3.0)
	corpo.material_override = Tex.facade(1, 9.0)
	add_child(corpo)

	var forma := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(9.0, 4.6, 6.0)
	forma.shape = box
	forma.position = Vector3(0, 2.3, -3.0)
	add_child(forma)

	# La tenda a righe sopra la vetrina.
	for i in range(7):
		var riga := MeshInstance3D.new()
		var rm := BoxMesh.new()
		rm.size = Vector3(1.15, 0.1, 2.0)
		riga.mesh = rm
		riga.position = Vector3(-3.45 + i * 1.15, 3.3, 0.6)
		riga.rotation.x = deg_to_rad(-12)
		riga.material_override = Tex.flat(
			Color(0.86, 0.72, 0.2) if i % 2 == 0 else Color(0.78, 0.25, 0.2), 0.9)
		add_child(riga)

	# La vetrina: di notte si illumina da dentro.
	var vetro := MeshInstance3D.new()
	var vm := BoxMesh.new()
	vm.size = Vector3(6.4, 2.2, 0.12)
	vetro.mesh = vm
	vetro.position = Vector3(0, 1.5, 0.05)
	vetro.material_override = Tex.flat(Color(0.95, 0.82, 0.5), 0.4, 0.0, 0.6).duplicate()
	add_child(vetro)
	_luci_interne.append(vetro)

	# I cornetti in vetrina: file di piccoli volumi dorati.
	for r in range(3):
		for c in range(9):
			var corn := MeshInstance3D.new()
			var cm := BoxMesh.new()
			cm.size = Vector3(0.34, 0.14, 0.2)
			corn.mesh = cm
			corn.position = Vector3(-2.7 + c * 0.68, 0.9 + r * 0.5, 0.2)
			corn.rotation.z = deg_to_rad(randf_range(-12, 12))
			corn.material_override = Tex.flat(Color(0.85, 0.66, 0.32), 0.85)
			add_child(corn)

	# La serranda: di giorno scende e copre tutto.
	_serranda = Node3D.new()
	add_child(_serranda)
	var sr := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(7.2, 3.0, 0.14)
	sr.mesh = sm
	sr.position = Vector3(0, 1.5, 0.24)
	sr.material_override = Tex.mondo("serranda", Color.WHITE, 0.6)
	_serranda.add_child(sr)

	# L'insegna.
	_insegna = Label3D.new()
	_insegna.text = "CORNETTERIA\n'A NUTTATA"
	_insegna.position = Vector3(0, 5.1, 0.3)
	_insegna.font_size = 64
	_insegna.pixel_size = 0.010
	_insegna.modulate = Color(1.0, 0.78, 0.35)
	_insegna.outline_size = 20
	add_child(_insegna)

	_insegna_luce = OmniLight3D.new()
	_insegna_luce.position = Vector3(0, 3.0, 1.6)
	_insegna_luce.light_color = Color(1.0, 0.82, 0.5)
	_insegna_luce.light_energy = 0.0
	_insegna_luce.omni_range = 16.0
	_insegna_luce.shadow_enabled = false
	add_child(_insegna_luce)


func _process(delta: float) -> void:
	var notte: bool = GameManager.notte
	if _ciclo != null and _ciclo.get("avanzamento") != null:
		# Alza un po' prima del buio pieno: quando il cielo è già viola.
		notte = float(_ciclo.avanzamento) > 0.86
	if notte != aperta:
		_aggiorna_apertura(notte)
	if not aperta:
		return
	_detto = maxf(0.0, _detto - delta)
	if _detto <= 0.0 and randf() < delta * 0.12:
		_detto = 6.0
		if _bubble:
			_bubble.say(SAY_APERTO[randi() % SAY_APERTO.size()], 2.6)
	_prossima -= delta
	if _prossima <= 0.0:
		_prossima = randf_range(OGNI_AUTO_MIN, OGNI_AUTO_MAX)
		_chiama_gente()


func _aggiorna_apertura(apri: bool) -> void:
	aperta = apri
	if _serranda:
		_serranda.visible = not apri
	if _insegna_luce:
		_insegna_luce.light_energy = 2.4 if apri else 0.0
	if _insegna:
		_insegna.modulate = Color(1.0, 0.82, 0.4) if apri \
			else Color(0.42, 0.38, 0.32)
	for v in _luci_interne:
		if is_instance_valid(v) and v.material_override is StandardMaterial3D:
			v.material_override.emission_energy_multiplier = 0.85 if apri else 0.0
	if apri:
		GameManager.event_started.emit(
			"'A cornetteria ha aperto. Mo' se sceta 'o vico.")
		SoundManager.play("pop", -8.0, 1.2)


## Di notte la cornetteria tira macchine. Per ora arrivano, si fermano
## davanti e se ne vanno: è la zona di Tonino, non tua — ed è esattamente
## quello che deve far venire voglia di prendergliela.
func _chiama_gente() -> void:
	var citta := get_tree().get_first_node_in_group("citta")
	if citta == null:
		return
	GameManager.event_started.emit(
		"N'ata machina s'è fermata 'a cornetteria… e nun è zona toia.")


# ---------------------------------------------------------------------------
# 'O CORNETTO BLACK AND WHITE
# ---------------------------------------------------------------------------

## Quanto costa e quanto rimette. Sessanta punti su cento: non è un morso,
## è una cena. E cinque euro sono cari per un cornetto, ma alle due di
## notte, mezzo morto, non stai a contrattare.
const CORNETTO_COSTA: int = 5
const CORNETTO_OSSA: float = 60.0

const SAY_CORNETTO := [
	"Black and white, cavero cavero. Mangia.",
	"Crema e cioccolata. Chesto te rimette 'n piedi.",
	"Tiè. E nun te fa' vedé 'a mugliera cu 'a bocca sporca.",
]
const SAY_SENZA := "Cinche euro, guagliò. Nun faccio credito 'a chest'ora."
const SAY_CHIENO := "E addò 'o miette? Staje già buono."


func _say(t: String) -> void:
	if _bubble:
		_bubble.say(t)
	GameManager.directing_gesture.emit("« 'O cornettaro »: %s" % t, true)


func get_interact_prompt(_da: Vector3) -> String:
	if not aperta:
		return "CORNETTERIA 'A NUTTATA — chiusa. Torna quanno se fa notte."
	if GameManager.health >= GameManager.HEALTH_MAX - 0.5:
		return "CORNETTERIA 'A NUTTATA — 'o cornetto black and white €%d (ma staje buono)" \
			% CORNETTO_COSTA
	return "CORNETTERIA 'A NUTTATA — [E] 'o cornetto black and white €%d  (+%d 'e ossa)" \
		% [CORNETTO_COSTA, int(CORNETTO_OSSA)]


func player_interact() -> void:
	if not aperta:
		_say("Chiuso. Torna quanno se fa notte.")
		return
	if GameManager.health >= GameManager.HEALTH_MAX - 0.5:
		SoundManager.play("fail", -12.0, 1.1)
		_say(SAY_CHIENO)
		return
	if not GameManager.paga(CORNETTO_COSTA):
		SoundManager.play("fail", -8.0, 0.9)
		_say(SAY_SENZA)
		return
	GameManager.heal_player(CORNETTO_OSSA)
	SoundManager.play("coin", -5.0, 1.0)
	SoundManager.play("sorso", -8.0, 0.9)
	_say(SAY_CORNETTO[randi() % SAY_CORNETTO.size()])
	GameManager.event_started.emit(
		"'O cornetto black and white. Mo' se pò ricummincià.")
