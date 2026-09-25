extends CharacterBody3D
## BossCapitolo3D — chi 'a teneva primma, e vene a piglià 'a parte soia
##
## **Nun è 'nu Borrelli cu 'n'ata faccia.**
##
## Borrelli è l'inseguimento: uno che non puoi toccare e da cui devi
## scappare. Rifarlo tre volte con tre nomi avrebbe dato tre Borrelli —
## lo stesso errore delle quattro piazze tutte uguali, ma sui personaggi.
##
## Questo è il contrario, e ha senso proprio dove succede. Ti sei preso una
## piazza: stasera, **in quella piazza**, ti aspetta chi la proteggeva. Non
## corre e non scappa. Sta fermo in mezzo, ti chiama, e ti mette davanti
## una domanda che ha una sera sola di tempo.
##
## E ognuno dei tre chiede una cosa **diversa**, che è l'unico modo perché
## siano tre personaggi e non tre copie:
##
##   * **'o Cardinale** vuole soldi. Tanti, subito, e finisce lì.
##   * **Donna Carmela** non vuole soldi: vuole una parte dell'incasso del
##     mercato per tre giorni. Costa meno oggi e più dopo.
##   * **Tonino 'e Notte** non tratta: o lo stendi o si riprende la piazza.
##
## Se non chiudi la faccenda entro la nottata, la piazza torna a lui. Non è
## una punizione a sorpresa: te lo dice, e il cartello resta su.

const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const Human := preload("res://scripts/human_builder.gd")
const Tex := preload("res://scripts/textures.gd")
const KO := preload("res://scripts/knockout.gd")

## Regge molto più di un rivale qualunque (quello parte da 40): è il boss
## del capitolo, e con la mazza sono una dozzina di colpi.
const MAX_HP: int = 95
const VISTA: float = 26.0
const PASSO: float = 2.2
## Quanto tempo hai, da quando arriva, prima che si riprenda la piazza.
const PAZIENZA: float = 150.0

enum Stato { ASPETTA, PARLA, MENA, STESO, SE_NE_VA }

var zona_id: String = ""
var dati: Dictionary = {}

var hp: int = MAX_HP
var stato: int = Stato.ASPETTA
var _tempo: float = PAZIENZA
var _visual: Node3D
var _bubble: Node3D
var _anim: Node = null
var _ko: Dictionary = KO.make_state()
var _detto: bool = false
var _colpo_cd: float = 0.0
var _chiuso: bool = false


func _ready() -> void:
	add_to_group("boss_capitolo")
	# Stesso layer di rivali e vigili: è così che il raggio del player lo
	# aggancia. Senza questo non si può né parlare né menare — ed è il
	# difetto che alla 0.44 ha colpito tutte e sei le cose nuove.
	collision_layer = 4
	collision_mask = 1
	_build_collision()
	_build_visual()
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 2.35, 0)
	add_child(_bubble)


func configura(zona: String, info: Dictionary) -> void:
	zona_id = zona
	dati = info


func _build_collision() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 2.0
	shape.shape = capsule
	shape.position = Vector3(0, 1.0, 0)
	add_child(shape)


func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	# Grosso, scuro e fermo. Da lontano dev'essere chiaro che non è un
	# passante: è più alto di tutti e non cammina.
	var femmina: bool = str(dati.get("nome", "")).begins_with("Donna")
	var parts := Human.build(Color(0.11, 0.10, 0.13), Color(0.09, 0.09, 0.11),
		"", 1.72 if femmina else 1.88, {
			"corpo": "femmina" if femmina else "",
			"belly": 0.55 if femmina else 0.85,
			"hair": Color(0.80, 0.79, 0.77),
			"moustache": not femmina,
		})
	_visual.add_child(parts["root"])
	_anim = parts.get("anim", null)
	_targa()


func _targa() -> void:
	var l := Label3D.new()
	l.text = str(dati.get("nome", "'O Boss"))
	l.font_size = 52
	l.pixel_size = 0.0034
	l.position = Vector3(0, 2.62, 0)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(1.0, 0.82, 0.35)
	l.outline_size = 18
	l.outline_modulate = Color(0, 0, 0, 0.9)
	add_child(l)


func _say(t: String, quanto: float = 4.0) -> void:
	if _bubble:
		_bubble.say(t, quanto)


# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if stato == Stato.STESO:
		KO.tick(_ko, _visual, delta)
		return
	if stato == Stato.SE_NE_VA:
		return

	var pl := get_tree().get_first_node_in_group("player")
	if pl == null or not (pl is Node3D):
		return
	var dist: float = global_position.distance_to((pl as Node3D).global_position)
	_guarda(pl as Node3D, delta)

	# Il conto alla rovescia parte da quando arriva, non da quando lo vedi:
	# se no bastava non andarci mai.
	_tempo -= delta
	if _tempo <= 0.0:
		_se_ripiglia_a_piazza()
		return
	# A metà tempo lo ricorda, perché una scadenza che non si vede è una
	# trappola.
	if _tempo < PAZIENZA * 0.5 and not _detto:
		_detto = true
		GameManager.event_started.emit(
			"%s sta ancora aspettanno dint'â piazza. E nun aspetta pe' sempe."
			% str(dati.get("nome", "'O boss")))

	match stato:
		Stato.ASPETTA:
			if dist < VISTA:
				stato = Stato.PARLA
				_say(str(dati.get("dice", "…")), 6.0)
				GameManager.event_started.emit("%s: %s"
					% [str(dati.get("nome", "'O boss")),
						str(dati.get("dice", ""))])
		Stato.MENA:
			_addosso(pl as Node3D, dist, delta)


func _guarda(pl: Node3D, delta: float) -> void:
	var d: Vector3 = pl.global_position - global_position
	d.y = 0.0
	if d.length() > 0.3 and _visual:
		_visual.rotation.y = lerp_angle(_visual.rotation.y,
			atan2(-d.x, -d.z), 1.0 - exp(-6.0 * delta))


## Quando si mena, si mena sul serio: è l'unico che ti viene addosso invece
## di aspettare che sia tu ad avvicinarti.
func _addosso(pl: Node3D, dist: float, delta: float) -> void:
	_colpo_cd = maxf(0.0, _colpo_cd - delta)
	if dist > 2.1:
		var verso: Vector3 = pl.global_position - global_position
		verso.y = 0.0
		velocity.x = verso.normalized().x * PASSO
		velocity.z = verso.normalized().z * PASSO
		move_and_slide()
		if _anim != null:
			_anim.set_speed(PASSO)
		return
	if _anim != null:
		_anim.set_speed(0.0)
	if _colpo_cd > 0.0:
		return
	_colpo_cd = 1.3
	if _anim != null and _anim.has_method("action"):
		_anim.action("pugno")
	GameManager.damage_player(11.0, str(dati.get("nome", "'O boss")))
	GameManager.screen_shake.emit(0.5)
	SoundManager.pugno(-1.0)


# ---------------------------------------------------------------------------
# 'O scambio
# ---------------------------------------------------------------------------

func get_interact_prompt(_da: Vector3) -> String:
	if stato == Stato.STESO:
		return "%s sta 'n terra. 'A piazza è 'a toia." % str(dati.get("nome", ""))
	if stato == Stato.MENA:
		return "Nun ce sta cchiù niente 'a dicere (click 'e sinistra)"
	match str(dati.get("vuole", "")):
		"sorde":
			return "[E] pava €%d a %s  ·  [F] mannalo a fà 'n culo" % [
				int(dati.get("quanto", 0)), str(dati.get("nome", ""))]
		"parte":
			return "[E] accetta: %d juorne 'e 'ncasso a %s  ·  [F] no" % [
				int(dati.get("quanto", 3)), str(dati.get("nome", ""))]
	return "%s nun tratta. Sulo mazzate (click 'e sinistra)" \
		% str(dati.get("nome", ""))


func player_interact() -> void:
	if stato == Stato.STESO or stato == Stato.SE_NE_VA:
		return
	match str(dati.get("vuole", "")):
		"sorde":
			var costo: int = int(dati.get("quanto", 0))
			if not GameManager.paga(costo):
				_say("E cu che me pave? Turnatenne quanno 'e tiene.")
				SoundManager.play("fail", -8.0, 0.85)
				return
			_say("Accussì se fa. 'A piazza è 'a toia, guagliò.", 5.0)
			SoundManager.play("kaching", -3.0, 0.92)
			_chiude("Hê pavato %s. 'O stadio mo' è 'o tuoio overo."
				% str(dati.get("nome", "")))
		"parte":
			GameManager.boss_parte_juorne = int(dati.get("quanto", 3))
			_say("Brava gente. Tre juorne, e po' nun ce verimmo cchiù.", 5.0)
			_chiude("Pe' %d juorne 'o mercato fatica pure pe' %s."
				% [int(dati.get("quanto", 3)), str(dati.get("nome", ""))])
		_:
			_say("Aggio ditto ca nun tratto.")


## [F]: 'o manne a fà 'n culo. Da qui in poi si mena e basta.
func player_vandalize() -> void:
	_accummencia_a_menà()


func _accummencia_a_menà() -> void:
	if stato == Stato.MENA or stato == Stato.STESO:
		return
	stato = Stato.MENA
	_say("Ah sì? E allora vien'a ccà.", 4.0)
	GameManager.event_started.emit("%s s'è 'ncazzato. Mo' se mena."
		% str(dati.get("nome", "'O boss")))
	SoundManager.play("fail", -4.0, 0.7)


func receive_punch(danno: int = 1) -> void:
	if stato == Stato.STESO:
		return
	# Colpirlo mentre tratta vale come mandarlo a quel paese.
	if stato != Stato.MENA:
		_accummencia_a_menà()
	hp -= maxi(1, danno)
	GameManager.nemico_colpito.emit(str(dati.get("nome", "'O boss")),
		maxi(0, hp), MAX_HP)
	GameManager.violenza(1.4)
	SoundManager.pugno(0.0)
	if _anim != null and _anim.has_method("reagisci_colpo"):
		_anim.reagisci_colpo(randf() < 0.4)
	if hp <= 0:
		_va_n_terra()


func _va_n_terra() -> void:
	stato = Stato.STESO
	KO.lay_down(_ko, _visual, 0.0)
	_say("…", 3.0)
	SoundManager.play("bump", -2.0, 0.7)
	_chiude("Hê stiso a %s. 'A piazza è 'a toia, e mo' 'o ssanno tutte."
		% str(dati.get("nome", "'O boss")))


func _chiude(messaggio: String) -> void:
	if _chiuso:
		return
	_chiuso = true
	GameManager.boss_capitolo_fernuto(zona_id)
	GameManager.event_started.emit(messaggio)
	GameManager.add_reputation(4)


## Scaduto il tempo: se la riprende. È l'unica delle quattro uscite che
## costa qualcosa, ed è anche l'unica che il giocatore può evitare
## semplicemente andandoci.
func _se_ripiglia_a_piazza() -> void:
	if _chiuso:
		stato = Stato.SE_NE_VA
		return
	_chiuso = true
	stato = Stato.SE_NE_VA
	GameManager.perde_zona(zona_id)
	GameManager.boss_capitolo_fernuto(zona_id)
	GameManager.event_started.emit(
		"%s s'è ripigliato 'a piazza. Nun ce sî ghiuto, e chillo nun aspetta."
		% str(dati.get("nome", "'O boss")))
	SoundManager.play("fail", -4.0, 0.6)
