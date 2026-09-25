extends StaticBody3D
## Garage3D — addò se portano 'e mmacchine ca nun so' toje
##
## Uno per piazza, come ha chiesto il capo. Una saracinesca arrugginita in
## un angolo, con la vernice scrostata e nessuna insegna: se ci arrivi
## dentro con l'auto giusta, quella sparisce e i soldi compaiono.
##
## **Perché una saracinesca e non un cerchio per terra.** Il posto dove si
## consegna una macchina rubata deve *sembrare* il posto dove si consegna
## una macchina rubata. Un marcatore astratto avrebbe funzionato uguale e
## non avrebbe detto niente.

const Tex := preload("res://scripts/textures.gd")
const Models := preload("res://scripts/models.gd")

const LAYER_WORLD := 1
const LAYER_CAR := 4

## Da quanto vicino accetta la consegna.
const RAGGIO: float = 5.5

var zona_id: String = ""
var nome_zona: String = ""

var _luce: OmniLight3D = null
var _insegna: Label3D = null


func _ready() -> void:
	add_to_group("garage")
	collision_layer = LAYER_CAR
	collision_mask = 0
	_costruisci()
	GameManager.lavoretti_cambiati.connect(_aggiorna_insegna)
	_aggiorna_insegna()
	set_process(true)


## **L'insegna ha da sapé si staje guidanno.** `lavoretti_cambiati` si
## accendeva solo quando cambiava la bacheca, e il furto d'auto della 0.57
## con la bacheca non c'entra niente: si guarda ogni tre decimi se hai una
## macchina rubata sotto, che è abbastanza spesso per non farsi aspettare e
## abbastanza raro da non costare niente.
var _guarda: float = 0.0

func _process(d: float) -> void:
	_guarda -= d
	if _guarda > 0.0:
		return
	_guarda = 0.3
	_aggiorna_insegna()


func _costruisci() -> void:
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(3.4, 2.6, 1.0)
	cs.shape = bx
	cs.position = Vector3(0, 1.3, 0.3)
	add_child(cs)

	var muro := Tex.flat(Color(0.52, 0.48, 0.44), 0.95)
	var ferro := Tex.flat(Color(0.42, 0.34, 0.28), 0.62, 0.35)
	var ruggine := Tex.flat(Color(0.48, 0.30, 0.18), 0.88)

	# 'A cornice 'e cemento e 'a saracinesca a righe.
	_box(Vector3(3.9, 3.0, 0.28), Vector3(0, 1.5, 0.12), muro)
	_box(Vector3(3.2, 2.45, 0.10), Vector3(0, 1.24, -0.02), ferro)
	for i in range(11):
		_box(Vector3(3.14, 0.03, 0.12),
			Vector3(0, 0.16 + float(i) * 0.215, -0.03), ruggine)
	# 'A maniglia e 'o lucchetto.
	_box(Vector3(0.44, 0.05, 0.05), Vector3(0, 0.30, -0.08), ruggine)
	_box(Vector3(0.10, 0.14, 0.06), Vector3(0.62, 0.24, -0.09),
		Tex.flat(Color(0.72, 0.70, 0.66), 0.4, 0.7))

	# 'A luce sopra, di quelle da cortile.
	# **'O neon** (0.60, PSX) al posto della scatolina che faceva da
	# lampada: il tubo col riflettore, girato verso la strada (il suo
	# davanti è il +Z, quello del garage il −Z).
	var neon := Models.spawn("lampada_neon")
	if neon != null:
		neon.position = Vector3(-1.05, 2.98, -0.02)
		neon.rotation.y = PI
		add_child(neon)
	else:
		_box(Vector3(0.30, 0.12, 0.22), Vector3(-1.20, 2.72, -0.02),
			Tex.flat(Color(0.24, 0.22, 0.20), 0.6))
	# Le ragnatele negli angoli alti della saracinesca, che non si alza mai
	# fino in cima, e la tanica e la latta arrugginita per terra.
	for e in [["ragnatela", Vector3(-1.62, 2.5, -0.03)],
			["ragnatela2", Vector3(1.62, 2.5, -0.03)]]:
		var r := Models.spawn(str(e[0]))
		if r != null:
			r.position = e[1]
			r.rotation.y = PI
			add_child(r)
	_luce = OmniLight3D.new()
	_luce.light_color = Color(1.0, 0.80, 0.48)
	_luce.light_energy = 1.1
	_luce.omni_range = 7.0
	_luce.shadow_enabled = false
	_luce.position = Vector3(-1.20, 2.60, -0.10)
	add_child(_luce)

	# **'A robba d''o sfasciacarrozze** (0.58). Davanti alla saracinesca
	# c'erano tre metri di asfalto vuoto. Adesso c'è quello che uno si
	# aspetta di trovare fuori da un garage che compra macchine che non
	# sono tue: un mazzo di chiavi che non aprono più niente, la mazzetta
	# di stasera, e una batteria tolta a qualcosa.
	for e in [
			["tanica_blu", Vector3(1.66, 0.0, -0.42), 200.0],
			["barattolo", Vector3(-0.92, 0.0, -0.38), 40.0],
			["chiave3", Vector3(-1.32, 0.02, -0.55), 34.0],
			["mazzetta3", Vector3(1.18, 0.02, -0.48), -18.0],
			["ricetrasmittente2", Vector3(-1.58, 0.02, -0.30), 72.0],
		]:
		var o := Models.spawn(str(e[0]))
		if o == null:
			continue
		o.position = e[1]
		o.rotation.y = deg_to_rad(float(e[2]))
		add_child(o)

	# **'E cartielle americane** (0.59). Il pacchetto Pandazole porta due
	# limiti di velocità all'americana (SPEED LIMIT 30 e 50, il riquadro
	# nero): in mezzo a una strada di Napoli sarebbero un errore, appoggiati
	# al muro di uno sfasciacarrozze sono **roba sua** — cartelli svitati
	# chissà dove, tenuti perché "so' belle". Davanti al muro, ai due lati
	# della saracinesca, un po' inclinati all'indietro. Qui il davanti del
	# garage è il −Z locale e il muro sta a +Z (vedi `GIRO_GARAGE`).
	var palo_solido := StaticBody3D.new()
	palo_solido.collision_layer = LAYER_WORLD
	palo_solido.collision_mask = 0
	add_child(palo_solido)
	for c in [["cartello_30", -2.3, 0.08], ["cartello_50", 2.35, -0.06]]:
		var cart := Models.spawn(str(c[0]))
		if cart == null:
			continue
		cart.basis = Basis(Vector3.UP, PI + float(c[2])) * Basis(Vector3.RIGHT, -0.1)
		cart.position = Vector3(float(c[1]), 0.0, 0.2)
		add_child(cart)
		var fp := CollisionShape3D.new()
		var bp := BoxShape3D.new()
		bp.size = Vector3(0.14, 2.2, 0.14)
		fp.shape = bp
		fp.position = Vector3(float(c[1]), 1.1, 0.28)
		palo_solido.add_child(fp)

	_insegna = Label3D.new()
	_insegna.font_size = 34
	_insegna.pixel_size = 0.0034
	_insegna.modulate = Color(0.86, 0.84, 0.80)
	_insegna.outline_size = 10
	_insegna.outline_modulate = Color(0.10, 0.08, 0.06)
	_insegna.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_insegna.position = Vector3(0, 3.25, 0)
	add_child(_insegna)


## L'insegna si accende solo quando c'è un furto in corso. Un garage che
## lampeggia sempre è arredamento; uno che si accende quando serve è una
## destinazione.
func _aggiorna_insegna() -> void:
	var l: Dictionary = GameManager.lavoretto_in_corso()
	# **'O garage mo' serve p''e stemme.** Fino alla 0.49 era il posto dove
	# si consegnavano le macchine rubate; quel lavoro è stato tolto perché
	# non si riusciva a completare (vedi `game_manager.gd`, 'E LAVURE D''A
	# BACHECA). Un garage che non serve più a niente però è arredamento:
	# adesso è qui che si portano gli stemmi staccati dalle macchine.
	var acceso: bool = not l.is_empty() \
		and str(l.get("tipo", "")) == "stemme"
	# **E s'allumma pure quanno staje guidanno 'na rubata** (0.57). È
	# l'unica insegna della città, sta a centoquarantotto metri da casa, e
	# tu ci arrivi guidando una macchina che non è tua con due stelle
	# accese: dev'essere la cosa più visibile del quartiere.
	var guidi: bool = GameManager.auto_guidata != null \
		and is_instance_valid(GameManager.auto_guidata)
	if _insegna != null:
		if guidi:
			var tipo: String = str(GameManager.auto_guidata.get("car_type"))
			if GameManager.garage_chino():
				_insegna.text = "GARAGE — 'o piazzale è chino, torna dimane"
				_insegna.modulate = Color(0.9, 0.4, 0.3)
			else:
				_insegna.text = "GARAGE ▾  trasela ccà (€%d · %d/%d oggi)" % [
					GameManager.quanto_vale_a_machina(tipo),
					GameManager.auto_vennute, GameManager.GARAGE_MAX_JURNATA]
				_insegna.modulate = Color(1.0, 0.72, 0.24)
		else:
			_insegna.text = "GARAGE ▾  portale ccà" if acceso else "GARAGE"
			_insegna.modulate = Color(1.0, 0.80, 0.32) if acceso \
				else Color(0.72, 0.70, 0.66)
	if _luce != null:
		_luce.light_energy = 3.0 if guidi else (2.2 if acceso else 0.9)


func _box(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi


# ---------------------------------------------------------------------------
# 'A consegna
# ---------------------------------------------------------------------------

func get_interact_prompt(_da: Vector3) -> String:
	var l: Dictionary = GameManager.lavoretto_in_corso()
	if l.is_empty() or str(l.get("tipo", "")) != "stemme":
		return "'O garage sta chiuso. Nun tiene niente 'a purtà."
	var vonno: int = int(l.get("quanti", 1))
	var tiene: int = GameManager.emblem_count()
	if tiene < vonno:
		return "'O garage — te ne mancano ancora %d (%d ncopp'a %d)" \
			% [vonno - tiene, tiene, vonno]
	return "'O garage — [E] lassa 'e %d stemme (€%d)" \
		% [vonno, int(l.get("paga", 0))]


func player_interact() -> void:
	var l: Dictionary = GameManager.lavoretto_in_corso()
	if l.is_empty() or str(l.get("tipo", "")) != "stemme":
		return
	var paga: int = GameManager.finisci_lavoretto(str(l["id"]))
	if paga > 0:
		SoundManager.play("pop", -5.0)
		GameManager.event_started.emit(
			"Stemme consegnate. €%d, e nun 'e cercà cchiù." % paga)
