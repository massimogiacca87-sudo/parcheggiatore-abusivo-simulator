extends CharacterBody3D
## **Gennarino 'o Nuovo — ll'abusivo 'e ll'abusivo** (0.61)
##
## ## Chi è
##
## Uno che ha visto come lavori e ha pensato di poterlo fare pure lui.
## Diciannove anni, magro, un berretto rosso e un pezzo di cartone con su
## scritto POSTEGGIO. Qualche giorno (poco meno di uno su due, dalla seconda
## giornata) si presenta in una delle **tue** piazze e comincia a fare
## quello che fai tu: va incontro alle macchine in coda, se le mette nelle
## strisce, e **i soldi se li mette in tasca lui**.
##
## È il personaggio che mancava a un gioco che si chiama *Parcheggiatore
## Abusivo*: l'abusivo dell'abusivo. Finora eri tu quello che arriva in una
## piazza non sua; con lui si vede dall'altra parte.
##
## ## Cosa ci fai
##
## Ci parli, e hai quattro strade:
##
##   1. **Lo cacci.** Se ne va. Se hai poca fama, più tardi torna.
##   2. **Ti fai dare la metà** di quello che ha incassato. Se ne va, e
##      qualcosa ci hai guadagnato.
##   3. **Lo assumi.** Se in quella piazza non hai già un guaglione, diventa
##      il tuo — **gratis**, e con quello che ha in tasca come prima cassa.
##      Uno che si è fatto la piazza da solo non va convinto con i soldi.
##   4. **Lo lasci fare.** Continua, e ogni macchina che mette è una
##      macchina che non hai messo tu.
##
## E se lo meni, scappa: i soldi che aveva in tasca cadono per terra — ma
## è una rissa come le altre, e il quartiere la vede.

const Human := preload("res://scripts/human_builder.gd")
const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const Tex := preload("res://scripts/textures.gd")
const Passo := preload("res://scripts/passo.gd")
const Citta := preload("res://scripts/citta_3d.gd")

const NOME := "Gennarino 'o Nuovo"
const VELOCITA: float = 1.8
const VELOCITA_CORSA: float = 3.4
const SALE_A: float = 2.6
## Quanto resta, al massimo, in una piazza (secondi di gioco).
const DURATA_MAX: float = 200.0

const ARRIVA := [
	"Bongiorno! Ccà ce sto io, mo'.",
	"Uè, ma ccà nun ce sta nisciuno? E allora faccio io.",
	"Posteggio! Posteggio! Accà, dotto', accà!",
]
const LAVORA := [
	"Venite, venite, ca ce sta 'o posto!",
	"Dotto', 'na mancia pe' 'o guaglione!",
	"Posteggio cu 'a garanzia!",
	"Chiano, chiano… stop! Perfetto!",
]
const PRIMMA := [
	"Uh… 'o padrone. Buongiorno, capo.",
	"Ah, sî tu chillo d''a piazza? Nun 'o sapevo, giuro.",
]
const CACCIATO := [
	"Va bbuò, va bbuò. Me ne vaco.",
	"Nun t'arraggià. Stongo jenno.",
]
const TORNA := [
	"Pe' mo'. Ce vedimmo cchiù tarde.",
	"'A piazza è grossa, capo. Ce sta posto pe' tutte e dduje.",
]
const PAGA := [
	"Tiè. Nun è 'na fortuna, ma è onesto.",
	"Chesta è 'a mità, cuntala pure.",
]
const ASSUNTO := [
	"Overo? Capo, nun te ne pentarrai!",
	"Mo' sì ca faticammo! Grazie, capo.",
]
const MENATO := [
	"Aiuto! Chisto è pazzo!",
	"Va bbuò, va bbuò! Me ne vaco!",
]

enum Fase { NISCIUNO, ARRIVA, FERMO, VERSO_AUTO, A_BORDO, SE_NE_VA }

var _fase: int = Fase.NISCIUNO
var _zona: Dictionary = {}
var _posto: Vector3 = Vector3.ZERO
var _uscita: Vector3 = Vector3.ZERO
var _auto: Node3D = null
var _cerca: float = 0.0
var _t: float = 0.0
var _t_fase: float = 0.0
var _parla: float = 0.0
var _tasca: int = 0
var _clienti: int = 0
var _visto_oggi: int = -1        # la giornata in cui è già venuto
var _quanno: float = -1.0        # a che ora arriva oggi
var _torna_dopo: bool = false
var _parlando: bool = false
var _conosciuto: bool = false

var _visual: Node3D
var _anim: Node = null
var _bubble: Node3D
var _targhetta: Label3D


func _ready() -> void:
	add_to_group("nuovi_abusivi")
	collision_layer = 4
	collision_mask = 1
	var f := CollisionShape3D.new()
	var c := CapsuleShape3D.new()
	c.radius = 0.32
	c.height = 1.66
	f.shape = c
	f.position = Vector3(0, 0.83, 0)
	add_child(f)
	_build_visual()
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 2.1, 0)
	add_child(_bubble)
	_sparisce()


func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	var parts := Human.build(Color(0.92, 0.55, 0.18), Color(0.16, 0.2, 0.34),
		"", 1.68, {"belly": 0.0, "moustache": false, "bald": false,
			"hair": Color(0.08, 0.06, 0.05),
			# (0.66) Gennarino: nuovo del mestiere, e si vede in faccia.
			"capelli": "corti", "palpebre": "sveglie",
			"sopracciglia": "preoccupate", "naso": "piccolo", "bocca": "sorriso",
			"barba": "", "rughe": "", "cintura": false, "colletto": false,
			"catenina": false})
	_visual.add_child(parts["root"])
	_anim = parts.get("anim", null)
	# Il berretto rosso: da lontano è la cosa che lo distingue da un
	# passante qualunque.
	var berretto := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.10
	cm.bottom_radius = 0.115
	cm.height = 0.08
	berretto.mesh = cm
	berretto.material_override = Tex.flat(Color(0.82, 0.1, 0.08), 0.8)
	berretto.position = Vector3(0, 1.66, 0.0)
	_visual.add_child(berretto)
	var visiera := MeshInstance3D.new()
	var vm := BoxMesh.new()
	vm.size = Vector3(0.16, 0.015, 0.1)
	visiera.mesh = vm
	visiera.material_override = Tex.flat(Color(0.7, 0.08, 0.06), 0.8)
	visiera.position = Vector3(0, 1.635, -0.13)
	_visual.add_child(visiera)
	# Il cartone.
	var cartone := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.5, 0.34, 0.02)
	cartone.mesh = bm
	cartone.material_override = Tex.flat(Color(0.78, 0.68, 0.48), 0.95)
	cartone.position = Vector3(0.32, 1.0, -0.2)
	cartone.rotation = Vector3(deg_to_rad(-10), deg_to_rad(20), 0)
	_visual.add_child(cartone)
	var scritta := Label3D.new()
	scritta.text = "POSTEGGIO\n1 €"
	scritta.font_size = 36
	scritta.pixel_size = 0.0024
	scritta.modulate = Color(0.15, 0.1, 0.08)
	scritta.position = Vector3(0.32, 1.0, -0.215)
	scritta.rotation = Vector3(deg_to_rad(-10), deg_to_rad(200), 0)
	_visual.add_child(scritta)

	_targhetta = Label3D.new()
	_targhetta.position = Vector3(0, 2.0, 0)
	_targhetta.font_size = 40
	_targhetta.pixel_size = 0.003
	_targhetta.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_targhetta.modulate = Color(1.0, 0.55, 0.4)
	_targhetta.outline_size = 10
	add_child(_targhetta)


# ---------------------------------------------------------------------------
# Quando vene
# ---------------------------------------------------------------------------

func _sparisce() -> void:
	_fase = Fase.NISCIUNO
	_auto = null
	visible = false
	collision_layer = 0
	global_position = Vector3(-50, -20, -50)
	if _parlando:
		_chiude_parlata()


## Ogni mattina si decide se oggi viene, e a che ora.
func _programma() -> void:
	if _visto_oggi == GameManager.giornata:
		return
	_visto_oggi = GameManager.giornata
	_torna_dopo = false
	_quanno = -1.0
	if GameManager.giornata < 2:
		return
	if randf() < 0.45:
		_quanno = randf_range(13.5, 20.0)


func _zona_pe_oggi() -> Dictionary:
	# Una delle tue piazze, preferendo **quella dove stai tu**: è lì che
	# lo devi vedere, se no è una notizia e non un incontro.
	var mie: Array = []
	for z in Citta.ZONE:
		if GameManager.zona_mia(str(z["id"])):
			mie.append(z)
	if mie.is_empty():
		return {}
	for z in mie:
		if str(z["id"]) == GameManager.zona_corrente:
			return z
	return mie[randi() % mie.size()]


func _arriva() -> void:
	_zona = _zona_pe_oggi()
	if _zona.is_empty():
		return
	var r: Array = _zona["rect"]
	# Il posto suo: il lato opposto al guaglione (che sta a un quinto da
	# un angolo), così si vedono tutti e due.
	_posto = Passo.fore(Vector3(lerpf(float(r[0]), float(r[2]), 0.72), 0.0,
		lerpf(float(r[1]), float(r[3]), 0.62)))
	# Entra dal bordo della piazza, **da dentro**: la piazza di casa ha i
	# muri invisibili del giocatore, e chi nasceva due metri fuori ci
	# restava appiccicato (misurato: venticinque secondi fermo sul bordo).
	_uscita = Passo.fore(Vector3(float(r[2]) - 2.5, 0.0,
		lerpf(float(r[1]), float(r[3]), 0.62)))
	global_position = _uscita + Vector3(0, 0.3, 0)
	visible = true
	collision_layer = 4
	_fase = Fase.ARRIVA
	_t = 0.0
	_t_fase = 0.0
	_tasca = 0
	_clienti = 0
	_aggiorna_targhetta()
	GameManager.event_started.emit(
		"Uno c''o berretto russo s'è miso a posteggià a %s. 'E sorde s''e piglia isso."
		% str(_zona["nome"]))


func _aggiorna_targhetta() -> void:
	if _targhetta:
		_targhetta.text = "%s · €%d" % [NOME, _tasca] if _tasca > 0 else NOME


# ---------------------------------------------------------------------------
# 'O juorno suio
# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if not GameManager.shift_active:
		if _fase != Fase.NISCIUNO:
			_sparisce()
		return
	_programma()
	if _fase == Fase.NISCIUNO:
		if _quanno > 0.0 and GameManager.ora_d_o_juorno() >= _quanno \
				and not GameManager.giornata_scaduta:
			_quanno = -1.0
			_arriva()
		return

	if not is_on_floor():
		velocity.y -= 22.0 * delta
	else:
		velocity.y = 0.0
	velocity.x = 0.0
	velocity.z = 0.0
	_t += delta
	_t_fase += delta
	_parla -= delta
	if _parlando:
		_chiude_se_luntano()

	# Se ne va quando è finita la giornata o quando ha fatto abbastanza.
	if _fase != Fase.SE_NE_VA and _fase != Fase.A_BORDO \
			and (_t > DURATA_MAX or GameManager.giornata_scaduta):
		_vattenne()

	match _fase:
		Fase.ARRIVA:
			if _cammina(_posto, delta, VELOCITA * 1.2) or _t_fase > 25.0:
				_fase = Fase.FERMO
				_t_fase = 0.0
				_di(ARRIVA[randi() % ARRIVA.size()])
		Fase.FERMO:
			_ferma_anim()
			_cerca -= delta
			if _parla <= 0.0:
				_parla = randf_range(9.0, 16.0)
				if randf() < 0.6:
					_di(LAVORA[randi() % LAVORA.size()])
			if _cerca <= 0.0:
				_cerca = 1.5
				var c := _machina()
				if c != null:
					_auto = c
					_fase = Fase.VERSO_AUTO
					_t_fase = 0.0
		Fase.VERSO_AUTO:
			if _auto == null or not is_instance_valid(_auto) \
					or int(_auto.get("state")) != 1 or _t_fase > 20.0:
				_auto = null
				_fase = Fase.FERMO
			else:
				if _auto.has_method("guagliuno_arriva"):
					_auto.call("guagliuno_arriva")
				var m: Vector3 = _auto.global_position
				if Vector2(global_position.x - m.x, global_position.z - m.z).length() < SALE_A:
					if _auto.call("guagliuno_sale", str(_zona["id"]), self):
						_visual.visible = false
						_targhetta.visible = false
						collision_layer = 0   # vedi guaglione_3d: dint'â machina nun se tocca
						_fase = Fase.A_BORDO
						_t_fase = 0.0
					else:
						_auto = null
						_fase = Fase.FERMO
				else:
					_cammina(m, delta, VELOCITA_CORSA)
		Fase.A_BORDO:
			if _auto != null and is_instance_valid(_auto) \
					and int(_auto.get("state")) == 2 and _t_fase < 25.0:
				global_position = _auto.global_position
			else:
				if _auto != null and is_instance_valid(_auto):
					global_position = Passo.fore(_auto.global_position
						+ _auto.global_transform.basis.x * 1.5) + Vector3(0, 0.2, 0)
				_auto = null
				collision_layer = 4
				_visual.visible = true
				_targhetta.visible = true
				_fase = Fase.FERMO
				_cerca = 0.5
		Fase.SE_NE_VA:
			if _cammina(_uscita, delta, VELOCITA * 1.4) or _t_fase > 30.0:
				_sparisce()
				if _torna_dopo and not GameManager.giornata_scaduta:
					_torna_dopo = false
					_quanno = minf(GameManager.ora_d_o_juorno() + 2.0, 23.5)
	move_and_slide()


func _machina() -> Node3D:
	var r: Array = _zona["rect"]
	var meglio: Node3D = null
	var d_min: float = 1e9
	for c in get_tree().get_nodes_in_group("cars"):
		if not is_instance_valid(c) or int(c.get("state")) != 1:
			continue
		if c.has_method("_any_free_spot") and not bool(c.call("_any_free_spot")):
			continue
		var p: Vector3 = (c as Node3D).global_position
		if p.x < float(r[0]) or p.x > float(r[2]) or p.z < float(r[1]) \
				or p.z > float(r[3]):
			continue
		var d: float = global_position.distance_to(p)
		if d < d_min:
			d_min = d
			meglio = c as Node3D
	return meglio


## Un passo verso `meta`. Vero quando è arrivato.
func _cammina(meta: Vector3, delta: float, v: float) -> bool:
	var a: Vector2 = Vector2(global_position.x, global_position.z)
	if a.distance_to(Vector2(meta.x, meta.z)) < 1.0:
		_ferma_anim()
		return true
	var prima := global_position
	var nuova: Vector3 = Passo.verso(self, meta, v * delta)
	nuova.y = global_position.y
	global_position = nuova
	var dir: Vector3 = nuova - prima
	dir.y = 0.0
	if dir.length() > 0.001:
		dir = dir.normalized()
		_visual.rotation.y = lerp_angle(_visual.rotation.y,
			atan2(-dir.x, -dir.z), 1.0 - exp(-10.0 * delta))
	if _anim != null and _anim.has_method("set_speed"):
		_anim.call("set_speed", v)
	return false


func _ferma_anim() -> void:
	if _anim != null and _anim.has_method("set_speed"):
		_anim.call("set_speed", 0.0)


func _vattenne() -> void:
	if _fase == Fase.NISCIUNO or _fase == Fase.SE_NE_VA:
		return
	_fase = Fase.SE_NE_VA
	_t_fase = 0.0
	_auto = null
	_visual.visible = true
	_targhetta.visible = true


func _di(t: String, durata: float = 3.2) -> void:
	if _bubble:
		_bubble.say(t, durata)


## Lo chiama la macchina quando il cliente ha pagato.
func incassa(quanto: int) -> void:
	_tasca += quanto
	_clienti += 1
	_aggiorna_targhetta()
	var pl := get_tree().get_first_node_in_group("player")
	if pl != null and pl is Node3D \
			and global_position.distance_to((pl as Node3D).global_position) < 35.0:
		SoundManager.play("moneta1", -12.0, 1.1)
		if _clienti == 1:
			GameManager.event_started.emit(
				"%s s'è pigliato €%d 'a 'nu cliente tuoio." % [NOME, quanto])


# ---------------------------------------------------------------------------
# 'O parlato
# ---------------------------------------------------------------------------

func get_interact_prompt(_da: Vector3) -> String:
	if _fase == Fase.NISCIUNO or _fase == Fase.SE_NE_VA:
		return ""
	return "[E] Parla cu %s (tene €%d 'e cliente tuoie)" % [NOME, _tasca]


func player_interact() -> void:
	if _fase == Fase.NISCIUNO or _fase == Fase.SE_NE_VA or _parlando:
		return
	if not _conosciuto:
		_conosciuto = true
		_di(PRIMMA[randi() % PRIMMA.size()])
	_parlando = true
	GameManager.dialogo_con = self
	GameManager.boss_dialogue_opened.emit(_risposte())


func _risposte() -> Array:
	var zid: String = str(_zona.get("id", ""))
	var assume := "Tiene 'o talento. Vuò faticà pe' me? (gratis)"
	if GameManager.ha_dipendente(zid):
		assume = "(Ccà tengo già 'nu guaglione: nun 'o pozzo piglià)"
	return [
		{"text": "Uè, chesta è 'a piazza mia. Sparisce!"},
		{"text": "Damme 'a mità 'e chello ca hê fatto (€%d), e vattenne." % (_tasca / 2)},
		{"text": assume},
		{"text": "Fa' chello ca vuò."},
	]


func answer(index: int) -> void:
	if not _parlando:
		return
	var zid: String = str(_zona.get("id", ""))
	match index:
		0:
			_chiude_parlata()
			# Con la fama alta non torna; con la fama bassa ci riprova.
			_torna_dopo = GameManager.nomma < 40.0 and randf() < 0.6
			_di((TORNA if _torna_dopo else CACCIATO)[randi() % 2])
			_vattenne()
		1:
			_chiude_parlata()
			var mia: int = maxi(0, _tasca / 2)
			if mia > 0:
				GameManager.add_money(mia)
				SoundManager.play("coin", -4.0, 1.0)
				GameManager.event_started.emit(
					"%s t'ha dato €%d. 'O riesto s''o tene, e se ne va." % [NOME, mia])
			_tasca = 0
			_di(PAGA[randi() % PAGA.size()])
			_vattenne()
		2:
			if GameManager.ha_dipendente(zid):
				_di("E allora che me cunte, capo?")
				GameManager.boss_dialogue_opened.emit(_risposte())
				return
			_chiude_parlata()
			if GameManager.assumi(zid, NOME, true):
				var d: Dictionary = GameManager.dipendente(zid)
				d["cassa"] = int(d.get("cassa", 0)) + _tasca
				GameManager.dipendenti_cambiati.emit()
				SoundManager.play("kaching", -4.0, 1.05)
				_di(ASSUNTO[randi() % ASSUNTO.size()])
				GameManager.event_started.emit(
					"%s mo' fatica pe' te a %s. Chello ca teneva 'n sacca (€%d) sta dint'â cassa soja."
					% [NOME, str(_zona["nome"]), _tasca])
				_tasca = 0
				# Il suo posto lo prende il guaglione della piazza, che da
				# adesso è lui: questo se ne va a cambiarsi.
				_vattenne()
		_:
			_chiude_parlata()
			_di("Grazie, capo. Tu sî 'nu signore.")


func _chiude_se_luntano() -> void:
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null or not (pl is Node3D) \
			or global_position.distance_to((pl as Node3D).global_position) > 6.0:
		_chiude_parlata()


func _chiude_parlata() -> void:
	_parlando = false
	if GameManager.dialogo_con == self:
		GameManager.dialogo_con = null
	GameManager.boss_dialogue_closed.emit()


## Se lo meni scappa, e i soldi cadono.
func receive_punch(_danno: int = 1) -> void:
	if _fase == Fase.NISCIUNO or _fase == Fase.SE_NE_VA:
		return
	GameManager.register_punch()
	GameManager.report_risky_action(14.0)
	if _tasca > 0:
		GameManager.add_money(_tasca)
		GameManager.event_started.emit(
			"%s è scappato. 'E sorde so' caduti: +€%d." % [NOME, _tasca])
		_tasca = 0
	_di(MENATO[randi() % MENATO.size()])
	SoundManager.pugno(-2.0)
	_torna_dopo = false
	_vattenne()
