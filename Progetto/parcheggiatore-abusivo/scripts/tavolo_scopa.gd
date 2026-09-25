extends StaticBody3D
## TavoloScopa — 'o tavulino d''o viecchio
##
## Cinque tavolini sparsi per la città, uno per ogni vecchio del torneo.
## **Non stanno vicini apposta**: per sfidare il terzo devi prima averlo
## trovato, e trovarlo vuol dire attraversare mezzo quartiere. È una delle
## risposte alla domanda "perché dovrei uscire dalla piazza".
##
## Ogni vecchio accetta la sfida solo se hai già battuto quelli prima di
## lui. Se ci arrivi troppo presto ti manda via, e ti dice pure da chi
## devi andare: la scala si legge dentro al gioco, non su un menu.
##
## Il vecchio sta **seduto** con la clip vera della libreria universale
## (Sitting_Idle_Loop / Sitting_Talking_Loop): è la prima volta che nel
## gioco qualcuno sta seduto sul serio invece di stare in piedi dentro a
## una sedia.

const Tex := preload("res://scripts/textures.gd")
const Models := preload("res://scripts/models.gd")
const Human := preload("res://scripts/human_builder.gd")
const Anim := preload("res://scripts/animator.gd")
const Carte := preload("res://scripts/carte.gd")
const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const PannelloScopa := preload("res://scripts/pannello_scopa.gd")

const LAYER_WORLD := 1
const LAYER_CAR := 4

const TAVOLO_H: float = 0.74
const TAVOLO_R: float = 0.52
const SEDUTA_Y: float = 0.45

## Sta nella posa "parla"? Serve a rimetterlo a posto quando il pannello
## della partita si chiude.
var _gesticolava: bool = false

@export var sfidante_id: String = "ciccio"

var _parti: Dictionary = {}
var _bolla: Node3D = null
var _pannello: CanvasLayer = null
var _passo: int = 0          # 0 = ti dice chi è, 1 = si gioca
var _t: float = 0.0
var _prossima: float = 0.0


func _ready() -> void:
	add_to_group("tavoli_scopa")
	collision_layer = LAYER_CAR
	collision_mask = 0
	var cs := CollisionShape3D.new()
	var cy := CylinderShape3D.new()
	cy.radius = 1.25
	cy.height = 2.0
	cs.shape = cy
	cs.position = Vector3(0, 1.0, 0)
	add_child(cs)
	_costruisci()
	_prossima = randf_range(5.0, 15.0)


func dati() -> Dictionary:
	return GameManager.sfidante(sfidante_id)


func _costruisci() -> void:
	var metallo := Tex.flat(Color(0.62, 0.63, 0.65), 0.4, 0.6)
	var plastica := Tex.flat(Color(0.86, 0.84, 0.78), 0.6)

	# 'O tavulino 'e plastica, quello bianco di tutti i bar.
	var t := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = TAVOLO_R
	cm.bottom_radius = TAVOLO_R
	cm.height = 0.04
	t.mesh = cm
	t.material_override = plastica
	t.position = Vector3(0, TAVOLO_H, 0)
	add_child(t)
	var gamba := MeshInstance3D.new()
	var gm := CylinderMesh.new()
	gm.top_radius = 0.05
	gm.bottom_radius = 0.20
	gm.height = TAVOLO_H
	gamba.mesh = gm
	gamba.material_override = plastica
	gamba.position = Vector3(0, TAVOLO_H * 0.5, 0)
	add_child(gamba)
	# Il collider del tavolo, per non camminarci dentro.
	var solido := StaticBody3D.new()
	solido.collision_layer = LAYER_WORLD
	add_child(solido)
	var sc := CollisionShape3D.new()
	var sy := CylinderShape3D.new()
	sy.radius = TAVOLO_R
	sy.height = TAVOLO_H
	sc.shape = sy
	sc.position = Vector3(0, TAVOLO_H * 0.5, 0)
	solido.add_child(sc)

	# Quattro carte sul tavolo e il mazzo di fianco: la partita che stanno
	# facendo comunque, con o senza di te.
	for i in range(4):
		var ang: float = TAU * float(i) / 4.0 + 0.6
		_carta(Vector3(cos(ang) * 0.24, TAVOLO_H + 0.023, sin(ang) * 0.24),
			randi() % 40, ang)
	for i in range(5):
		_carta(Vector3(-0.34, TAVOLO_H + 0.024 + float(i) * 0.002, 0.28),
			-1, 0.3)
	# 'E spicce d''a posta (0.60, PSX): la scopa al bar si gioca a
	# cinquanta centesimi, e le monete stanno sul tavolo accanto al mazzo.
	for e in [["moneta", Vector3(0.30, 0.0, -0.22)], ["moneta", Vector3(0.33, 0.0, -0.18)],
			["moneta", Vector3(0.27, 0.0, -0.17)], ["banconota", Vector3(0.18, 0.0, -0.30)]]:
		var o := Models.spawn(str(e[0]))
		if o != null:
			o.position = (e[1] as Vector3) + Vector3(0, TAVOLO_H + 0.021, 0)
			o.rotation.y = randf_range(-PI, PI)
			add_child(o)

	# 'A sedia e 'o viecchio assettato.
	var d := dati()
	var eta: int = int(d.get("eta", 72))
	_sedia(Vector3(0, 0, 0.92), PI)
	var vecchio := Node3D.new()
	vecchio.name = "Viecchio"
	# Seduto: il rig sta con il bacino alla quota della seduta (ci pensa
	# la clip), quindi la radice va abbassata di quello che manca.
	#
	# **'A scala d''o rig conta.** `QUOTA_BACINO["seduto"] = 0.60` e' misurata
	# sul rig di riferimento alto 1,88; questo vecchio e' alto 1,68, quindi il
	# suo bacino scende di 0.60 x (1.68/1.88) = 0,536, non di 0,60. Con il
	# numero non scalato stava sei centimetri e mezzo **dentro** alla seduta
	# invece che appoggiato sopra.
	# **'A quota d''o bacino assettato mo 'a dice l'animazione.**
	# Prima era 0,60 misurato sul rig fatto a mano; adesso il vecchio è il
	# manichino della libreria e la sua clip `Sitting_Idle` gli tiene il
	# bacino a 0,3045 dell'altezza. Con il numero vecchio stava sette
	# centimetri dentro alla seduta.
	vecchio.position = Vector3(0, SEDUTA_Y - Anim.BACINO_SEDUTO * 1.68, 0.80)
	# Guarda 'o tavulo, no 'o muro. Con `rotation.y = PI` la convenzione
	# del gioco (forward = −sin θ, 0, −cos θ) lo girava dall'altra parte:
	# stava assettato a 'o cuntrario, e si vedeva subito.
	vecchio.rotation.y = 0.0
	add_child(vecchio)
	var canizie: Color = Color(0.86, 0.86, 0.84) if eta > 80 \
		else Color(0.62, 0.60, 0.56)
	_parti = Human.build(
		Color(0.42, 0.40, 0.38), Color(0.22, 0.22, 0.26), "", 1.68,
		{"hair": canizie, "belly": clampf(float(eta - 60) / 34.0, 0.2, 0.9),
		 "bald": eta > 82, "moustache": true,
		 "skin": Color(0.80, 0.66, 0.52)})
	vecchio.add_child(_parti["root"])
	var a = _parti.get("anim", null)
	if a != null and a.has_method("sit"):
		a.sit(false)

	_bolla = SpeechBubbleScript.new()
	_bolla.position = Vector3(0, 1.75, 0.78)
	add_child(_bolla)

	# 'O cartello cu 'o nome: da lontano si legge chi è, e serve a sapere
	# dove tornare quando l'avrai sbloccato.
	var l := Label3D.new()
	l.text = str(d.get("nome", "'O viecchio"))
	l.font_size = 44
	l.pixel_size = 0.0032
	l.modulate = Color(0.96, 0.92, 0.72)
	l.outline_size = 10
	l.outline_modulate = Color(0.08, 0.08, 0.10)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = Vector3(0, 2.15, 0.78)
	l.no_depth_test = false
	add_child(l)


func _carta(pos: Vector3, indice: int, rot: float) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = Carte.mesh(1.0)
	mi.material_override = Carte.retro() if indice < 0 \
		else Carte.materiale(indice)
	mi.position = pos
	mi.rotation = Vector3(-PI * 0.5, rot, 0)
	add_child(mi)


func _sedia(pos: Vector3, rot: float) -> void:
	# **'A seggia 'e paglia** (0.60, PSX): la sedia vera al posto delle
	# sei scatole. La seduta sta a quarantasei centimetri, cioè dove il
	# vecchio già si sedeva (`SEDUTA_Y`), e il suo davanti è il +Z come
	# quello della sedia fatta a mano: si mette con lo stesso giro.
	var vera := Models.spawn("seggia_paglia")
	if vera != null:
		vera.position = pos
		vera.rotation.y = rot
		add_child(vera)
		return
	var legno := Tex.flat(Color(0.55, 0.40, 0.26), 0.74)
	var s := Node3D.new()
	s.position = pos
	s.rotation.y = rot
	add_child(s)
	var seduta := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.42, 0.04, 0.42)
	seduta.mesh = bm
	seduta.material_override = legno
	seduta.position = Vector3(0, SEDUTA_Y, 0)
	s.add_child(seduta)
	for sx in [-0.18, 0.18]:
		for sz in [-0.18, 0.18]:
			var g := MeshInstance3D.new()
			var gb := BoxMesh.new()
			gb.size = Vector3(0.035, SEDUTA_Y, 0.035)
			g.mesh = gb
			g.material_override = legno
			g.position = Vector3(sx, SEDUTA_Y * 0.5, sz)
			s.add_child(g)
	var sp := MeshInstance3D.new()
	var sb := BoxMesh.new()
	sb.size = Vector3(0.42, 0.48, 0.035)
	sp.mesh = sb
	sp.material_override = legno
	sp.position = Vector3(0, SEDUTA_Y + 0.24, -0.19)
	s.add_child(sp)


# ---------------------------------------------------------------------------
# 'A sfida
# ---------------------------------------------------------------------------

func get_interact_prompt(_da: Vector3) -> String:
	var d := dati()
	var nome: String = str(d.get("nome", ""))
	if GameManager.scopa_battuti.has(sfidante_id):
		return "%s — l'hê già battuto. [E] n'ata partita (€%d)" \
			% [nome, int(d.get("puntata", 5))]
	if not GameManager.scopa_sbloccato(sfidante_id):
		var pross: String = GameManager.prossimo_sfidante()
		var pd: Dictionary = GameManager.sfidante(pross)
		return "%s — \"Primma va' a vencere a %s.\"" \
			% [nome, str(pd.get("nome", "n'atu"))]
	var puntata: int = int(d.get("puntata", 5))
	if GameManager.money < puntata:
		return "%s — ce vonno €%d p''a puntata" % [nome, puntata]
	if _passo == 0:
		return "%s, %d anne — [E] siente che dice" % [nome, int(d.get("eta", 70))]
	return "%s — [E] assèttate e joca €%d" % [nome, puntata]


func player_interact() -> void:
	var d := dati()
	if d.is_empty():
		return
	if not GameManager.scopa_sbloccato(sfidante_id):
		var pross: String = GameManager.prossimo_sfidante()
		var pd: Dictionary = GameManager.sfidante(pross)
		dici("Cu tte nun ce joco. Primma va' a vencere a %s."
			% str(pd.get("nome", "chill'ato")))
		return
	var puntata: int = int(d.get("puntata", 5))
	if GameManager.money < puntata:
		dici("E cu che ce joche? Cu 'e bottone?")
		return
	if _passo == 0:
		_passo = 1
		dici(str(d.get("dice", "Assettate.")), 4.5)
		return
	_passo = 0
	# La puntata si mette sul tavolo PRIMA di giocare: vincere ti ridà il
	# doppio, perdere te la lascia lì.
	GameManager.money -= puntata
	GameManager.money_changed.emit(GameManager.money)
	SoundManager.play("monete", -4.0)
	_apri(d, puntata)


func _apri(d: Dictionary, puntata: int) -> void:
	if _pannello == null or not is_instance_valid(_pannello):
		_pannello = PannelloScopa.new()
		_pannello.name = "PannelloScopa"
		get_tree().root.add_child(_pannello)
		# **S'aspetta 'o segnale, nun se guarda 'o pannello.** Prima
		# l'alzata dalla sedia dipendeva da `_process`, che pero' non gira
		# a gioco in pausa: finche' il pannello stava aperto il tavolo era
		# fermo, e si rialzava solo al primo fotogramma dopo. Funzionava,
		# ma solo per caso. Con il segnale si chiude quando si chiude.
		_pannello.chiusa.connect(_partita_chiusa)
	_pannello.avvia(d, puntata)
	var a = _parti.get("anim", null)
	if a != null and a.has_method("sit"):
		a.sit(true)
	_gesticolava = true
	# **'O giocatore s'assetta pure isso.** Il pannello prendeva il mouse
	# ma non le gambe: si poteva girare mezza città con la partita aperta.
	# La sedia sta di fronte a quella del vecchio, dall'altra parte del
	# tavolo, e ci si resta finché la partita non finisce.
	var pl := get_tree().get_first_node_in_group("player")
	if pl != null and pl.has_method("siediti"):
		var posto: Vector3 = to_global(Vector3(0, 1.05, -1.05))
		pl.siediti(posto, global_position + Vector3(0, 1.0, 0))
		if pl.has_method("interrompi_tutto"):
			pl.interrompi_tutto()


## Il pannello si e' chiuso, comunque sia andata: il vecchio smette di
## gesticolare e il giocatore si stacca dalla sedia.
func _partita_chiusa(_vinto: bool) -> void:
	_gesticolava = false
	var a = _parti.get("anim", null)
	if a != null and a.has_method("sit"):
		a.sit(false)
	var pl := get_tree().get_first_node_in_group("player")
	if pl != null and pl.has_method("alzati"):
		pl.alzati()


func dici(testo: String, durata: float = 3.2) -> void:
	if _bolla != null and is_instance_valid(_bolla) and _bolla.has_method("say"):
		_bolla.say(testo, durata)


const OZIO := [
	"Chi joca sulo perde sempe.",
	"Aggio visto passa' 'a guerra e 'e ccarte so' rimaste 'e stesse.",
	"'E denare vanno cuntate primma, no doppo.",
	"'A scopa nun è fortuna. È memoria.",
	"Mm.",
]


func _process(delta: float) -> void:
	if _pannello != null and is_instance_valid(_pannello) and _pannello.visible:
		return
	# **Finita 'a partita, se stà zitto.** All'apertura del pannello il
	# vecchio passa alla posa "seduto_parla"; niente lo rimetteva a
	# "seduto" alla chiusura, e quello restava a gesticolare a vuoto per il
	# resto della partita. Si vedeva benissimo passandoci davanti.
	if _gesticolava:
		_gesticolava = false
		var a0 = _parti.get("anim", null)
		if a0 != null and a0.has_method("sit"):
			a0.sit(false)
		# E il giocatore si rialza dalla sedia.
		var pl0 := get_tree().get_first_node_in_group("player")
		if pl0 != null and pl0.has_method("alzati"):
			pl0.alzati()
	_t += delta
	_prossima -= delta
	if _prossima <= 0.0:
		_prossima = randf_range(16.0, 34.0)
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and pl.global_position.distance_to(global_position) < 14.0:
			dici(str(OZIO[randi() % OZIO.size()]))
			var a = _parti.get("anim", null)
			if a != null and a.has_method("sit"):
				a.sit(true)
				get_tree().create_timer(3.4).timeout.connect(func():
					if is_instance_valid(self) and a != null:
						a.sit(false))
