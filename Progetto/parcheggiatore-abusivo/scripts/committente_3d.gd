extends CharacterBody3D
## **Chi t'affida 'a cummissione, e chi 'a riceve** (0.62).
##
## Il capo: *«Migliora le quest secondarie aggiungendo un personaggio che si
## avvicina e te la affida realisticamente (es. un portapizze che ti affida
## le pizze da consegnare perché a lui hanno rubato il motorino), gli
## oggetti del caso»*.
##
## Fino alla 0.61 una commissione era un disco di luce per terra: ci
## entravi, premevi E, e partiva un cronometro. Adesso dietro ogni
## commissione c'è **una persona con una storia**:
##
##   - il **committente** (`ruolo = "da"`) aspetta al suo posto con la roba
##     accanto (le pizze sul sellino del motorino che non parte, la spesa
##     sulla cassetta). Quando passi a quindici metri **ti chiama** e ti
##     viene incontro; arrivato da te ti racconta cosa gli è successo e che
##     cosa gli serve. [E] e la roba passa nelle tue mani — la vedi in prima
##     persona, e lui ti ringrazia e torna al suo posto;
##   - il **destinatario** (`ruolo = "a"`) compare quando hai la roba in
##     mano e aspetta sul punto di consegna; quando arrivi ti fa segno, [E]
##     e la roba passa a lui, con la battuta del caso.
##
## La meccanica sotto è quella di sempre (GameManager: `prendi_commissione`,
## `consegna_commissione`, il cronometro, la paga): qui c'è la faccia.

const Human := preload("res://scripts/human_builder.gd")
const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const Passo := preload("res://scripts/passo.gd")
const Robba := preload("res://scripts/robba_cummissione.gd")
const Models := preload("res://scripts/models.gd")
const Collina := preload("res://scripts/collina.gd")

const VELOCITA: float = 1.9
## Da quanto lontano ti chiama.
const CHIAMA_DA: float = 15.0
## Fin dove ti viene incontro, lontano dal suo posto.
const GUINZAGLIO: float = 11.0
## A che distanza si ferma a parlarti.
const VICINO: float = 1.7

var cid: String = ""
var ruolo: String = "da"   # "da" = committente, "a" = destinatario

var _c: Dictionary = {}
var _posto: Vector3 = Vector3.ZERO
var _visual: Node3D
var _anim: Node = null
var _bubble: Node3D
var _robba: Node3D = null        # la roba accanto a lui (o in mano)
var _appoggio: Node3D = null     # il motorino, la cassetta
var _punto_esclamativo: Label3D
var _nome: Label3D

enum Fase { ASPETTA, CHIAMA, VIENE, PARLA, TORNA, FATTO, SE_NE_VA }
var _fase: int = Fase.ASPETTA
var _t: float = 0.0
var _chiamato: bool = false
var _riga: int = 0
var _t_riga: float = 0.0
var _ciao: float = -1.0


func configura(c: Dictionary, r: String) -> void:
	_c = c
	cid = str(c["id"])
	ruolo = r


func _ready() -> void:
	add_to_group("committenti")
	collision_layer = 4
	collision_mask = 0
	var f := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.33
	cap.height = 1.7
	f.shape = cap
	f.position = Vector3(0, 0.85, 0)
	add_child(f)
	_posto = global_position
	_build_visual()
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 2.15, 0)
	add_child(_bubble)
	_punto_esclamativo = Label3D.new()
	_punto_esclamativo.text = "!" if ruolo == "da" else "?"
	_punto_esclamativo.font_size = 96
	_punto_esclamativo.pixel_size = 0.006
	_punto_esclamativo.modulate = Color(1.0, 0.82, 0.25) if ruolo == "da" \
		else Color(0.45, 0.95, 0.55)
	_punto_esclamativo.outline_size = 16
	_punto_esclamativo.outline_modulate = Color(0.08, 0.06, 0.04)
	_punto_esclamativo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_punto_esclamativo.no_depth_test = true
	_punto_esclamativo.position = Vector3(0, 2.55, 0)
	add_child(_punto_esclamativo)
	_nome = Label3D.new()
	_nome.text = _chi()
	_nome.font_size = 34
	_nome.pixel_size = 0.004
	_nome.modulate = Color(1, 0.96, 0.86)
	_nome.outline_size = 8
	_nome.outline_modulate = Color(0.06, 0.05, 0.04)
	_nome.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_nome.position = Vector3(0, 2.0, 0)
	add_child(_nome)
	_metti_robba()


func _chi() -> String:
	if ruolo == "da":
		return str(_c.get("chi", "Nu signore"))
	return str(_c.get("a_chi", "Chi aspetta"))


# ---------------------------------------------------------------------------
# 'A faccia
# ---------------------------------------------------------------------------

func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	var look: Dictionary = _c.get("look_da" if ruolo == "da" else "look_a", {})
	var camicia: Color = look.get("camicia", Color(0.5, 0.5, 0.52))
	var pantaloni: Color = look.get("pantaloni", Color(0.2, 0.2, 0.24))
	var opts: Dictionary = look.get("opts", {}).duplicate()
	var alta: float = float(look.get("alta", 1.76))
	var parti := Human.build(camicia, pantaloni, "", alta, opts)
	_visual.add_child(parti["root"])
	_anim = parti.get("anim", null)
	# Il cappello del mestiere, se c'è (il pizzaiuolo, il farmacista).
	var cappello: String = str(look.get("cappello", ""))
	if cappello != "":
		var m := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.12 if cappello == "pizzaiuolo" else 0.10
		cm.bottom_radius = 0.10
		cm.height = 0.16 if cappello == "pizzaiuolo" else 0.06
		m.mesh = cm
		m.material_override = preload("res://scripts/textures.gd").flat(
			Color(0.97, 0.97, 0.95) if cappello == "pizzaiuolo" else Color(0.2, 0.5, 0.3), 0.8)
		m.position = Vector3(0, alta - 0.02, 0.02)
		_visual.add_child(m)


## La roba sta **accanto** a lui, appoggiata: sul sellino del motorino che
## non parte, su una cassetta, sulla sedia. In mano sarebbe stata sospesa in
## aria davanti a braccia che penzolano — e si vede.
func _metti_robba() -> void:
	if ruolo != "da":
		return
	if str(_c.get("stato", "")) != "aperta":
		return
	var tipo: String = str(_c.get("robba", "pacco"))
	var fianco := Vector3(0.85, 0, 0.1)
	var alto: float = 0.46
	if tipo == "pizze":
		# 'O motorino arrubbato… no: chillo ca l'hanno lassato. Uno fermo,
		# col cavalletto, e le pizze ncopp'ô sellino.
		_appoggio = Models.spawn("motorino_fermo")
		if _appoggio != null:
			add_child(_appoggio)
			_appoggio.position = Vector3(1.1, 0, 0.2)
			_appoggio.rotation.y = PI * 0.5
			fianco = Vector3(1.1, 0, 0.2)
			alto = maxf(0.6, Models.size_of(_appoggio).y * 0.62)
	if _appoggio == null:
		_appoggio = Models.spawn("cascia_legno")
		if _appoggio != null:
			add_child(_appoggio)
			_appoggio.position = fianco
			alto = maxf(0.3, Models.size_of(_appoggio).y)
	_robba = Robba.costruisci(tipo)
	add_child(_robba)
	_robba.position = fianco + Vector3(0, alto + 0.01, 0)


# ---------------------------------------------------------------------------
# 'O passo
# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_t += delta
	_c = GameManager.commissione(cid)
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	if _c.is_empty():
		_vattenne(delta)
		return
	var stato: String = str(_c.get("stato", ""))
	if ruolo == "da":
		_passo_committente(delta, pl, stato)
	else:
		_passo_destinatario(delta, pl, stato)
	# Il punto esclamativo saltella: si vede di lontano che vuole qualcosa.
	if _punto_esclamativo.visible:
		_punto_esclamativo.position.y = 2.55 + absf(sin(_t * 3.2)) * 0.12


func _passo_committente(delta: float, pl: Node3D, stato: String) -> void:
	var libero: bool = GameManager.commissione_in_mano().is_empty()
	_punto_esclamativo.visible = stato == "aperta" and libero
	if stato != "aperta":
		# Data la roba: torna al posto suo, poi se ne va.
		if _fase != Fase.TORNA and _fase != Fase.SE_NE_VA:
			_fase = Fase.TORNA
			_t_riga = 0.0
		_passo_verso(_posto, delta)
		if _fase == Fase.TORNA and global_position.distance_to(_posto) < 0.8:
			_fase = Fase.SE_NE_VA
			_ciao = 30.0
		if _fase == Fase.SE_NE_VA:
			_ciao -= delta
			if _ciao <= 0.0 and (pl == null or pl.global_position.distance_to(global_position) > 25.0):
				queue_free()
		return
	if pl == null:
		return
	var d: float = pl.global_position.distance_to(global_position)
	var dal_posto: float = pl.global_position.distance_to(_posto)
	if not libero:
		# Hai già 'na cosa 'n mano: aspetta, e se passi te lo dice.
		_fase = Fase.ASPETTA
		_passo_verso(_posto, delta)
		if d < 4.0 and _t_riga <= 0.0:
			_dici("Primma porta chella ca tiene 'n mano, po' passa 'a ccà.", 3.0)
			_t_riga = 8.0
		_t_riga -= delta
		return
	match _fase:
		Fase.ASPETTA, Fase.TORNA:
			_passo_verso(_posto, delta)
			_guarda(pl.global_position)
			if d < CHIAMA_DA:
				_fase = Fase.CHIAMA
				_t_riga = 0.0
		Fase.CHIAMA:
			if not _chiamato:
				_chiamato = true
				_dici(str(_c.get("chiama", "Guagliò! Guagliò, vien' ccà!")), 3.0)
				if _anim != null:
					_anim.action("point")
				SoundManager.play("saluto", -6.0)
			_fase = Fase.VIENE
		Fase.VIENE:
			if d > CHIAMA_DA + 6.0:
				_fase = Fase.ASPETTA
				_chiamato = false
				return
			if d <= VICINO + 0.6:
				_fase = Fase.PARLA
				_riga = 0
				_t_riga = 0.0
				return
			# Ti viene incontro, ma non oltre il guinzaglio dal suo posto
			# (la roba sta lì, non la lascia).
			var meta: Vector3 = pl.global_position
			var dal: Vector3 = meta - _posto
			if dal.length() > GUINZAGLIO:
				meta = _posto + dal.normalized() * GUINZAGLIO
			var verso: Vector3 = meta - global_position
			verso.y = 0.0
			if verso.length() > VICINO:
				_passo_verso(meta - verso.normalized() * VICINO, delta)
			else:
				_guarda(pl.global_position)
				_anima(0.0)
		Fase.PARLA:
			_anima(0.0)
			_guarda(pl.global_position)
			if d > 7.0:
				_fase = Fase.VIENE
				return
			# La storia, una frase ogni tre secondi, e poi da capo.
			_t_riga -= delta
			if _t_riga <= 0.0:
				var storia: Array = _c.get("storia", [])
				if not storia.is_empty():
					_dici(str(storia[_riga % storia.size()]).replace("%s",
						str(_c.get("nome_a", ""))), 3.6)
					_riga += 1
				_t_riga = 3.8
			if dal_posto > GUINZAGLIO + 8.0:
				_fase = Fase.ASPETTA


func _passo_destinatario(delta: float, pl: Node3D, stato: String) -> void:
	if stato == "fatta" or stato == "persa":
		if _ciao < 0.0:
			_ciao = 6.0
		_ciao -= delta
		_punto_esclamativo.visible = false
		_anima(0.0)
		if _ciao <= 0.0:
			# Si gira e se ne entra: si allontana di qualche metro e sparisce.
			_fase = Fase.SE_NE_VA
			var via: Vector3 = _posto + Vector3(0, 0, 6.0).rotated(Vector3.UP, rotation.y)
			_passo_verso(via, delta)
			if _ciao < -4.0:
				queue_free()
		return
	_punto_esclamativo.visible = stato == "in_mano"
	_passo_verso(_posto, delta)
	if pl == null:
		return
	var d: float = pl.global_position.distance_to(global_position)
	if d < 14.0:
		_guarda(pl.global_position)
		if not _chiamato and stato == "in_mano":
			_chiamato = true
			_dici(str(_c.get("aspetta", "Uè! Sî tu? T'aspettavo!")), 3.0)
			if _anim != null:
				_anim.action("point")


func _vattenne(delta: float) -> void:
	_punto_esclamativo.visible = false
	_ciao = (_ciao if _ciao > 0.0 else 3.0) - delta
	if _ciao <= 0.0:
		queue_free()


func _passo_verso(meta: Vector3, delta: float) -> void:
	var da: Vector3 = global_position
	var v: Vector3 = meta - da
	v.y = 0.0
	if v.length() < 0.25:
		_anima(0.0)
		return
	var nuova: Vector3 = Passo.verso(self, Vector3(meta.x, da.y, meta.z), VELOCITA * delta)
	nuova.y = Collina.alzata(nuova.x, nuova.z)
	global_position = nuova
	_guarda(meta)
	_anima(VELOCITA)


func _guarda(p: Vector3) -> void:
	var d: Vector3 = p - global_position
	d.y = 0.0
	if d.length() < 0.05:
		return
	var voluto: float = atan2(-d.x, -d.z)
	rotation.y = lerp_angle(rotation.y, voluto, 0.15)


func _anima(v: float) -> void:
	if _anim != null and _anim.has_method("set_speed"):
		_anim.set_speed(v)


func _dici(t: String, durata: float = 3.0) -> void:
	if _bubble != null:
		_bubble.say(t, durata)


# ---------------------------------------------------------------------------
# [E]
# ---------------------------------------------------------------------------

func get_interact_prompt(_da: Vector3) -> String:
	_c = GameManager.commissione(cid)
	if _c.is_empty():
		return ""
	var stato: String = str(_c.get("stato", ""))
	if ruolo == "da":
		if stato != "aperta":
			return "%s — \"Grazie 'e core!\"" % _chi()
		var in_mano: Dictionary = GameManager.commissione_in_mano()
		if not in_mano.is_empty():
			return "%s — primma porta %s 'a %s" % [_chi(),
				str(Robba.NOMI.get(str(in_mano.get("robba", "")), "chella roba")),
				str(in_mano["nome_a"])]
		return "[E] \"Va bbuo', damme %s\" — €%d · 'a %s" % [
			str(Robba.NOMI.get(str(_c.get("robba", "")), "'a roba")),
			int(_c["paga"]), str(_c["nome_a"])]
	if stato != "in_mano":
		return _chi()
	var resta: float = float(_c.get("scade", 0.0))
	return "[E] dalle %s — €%d · %d\"" % [
		str(Robba.NOMI.get(str(_c.get("robba", "")), "'a roba")),
		int(round(float(_c["paga"]) * float(_c.get("integrita", 1.0)))),
		int(maxf(resta, 0.0))]


func player_interact() -> void:
	_c = GameManager.commissione(cid)
	if _c.is_empty():
		return
	var stato: String = str(_c.get("stato", ""))
	if ruolo == "da":
		if stato != "aperta" or not GameManager.commissione_in_mano().is_empty():
			return
		if GameManager.prendi_commissione(cid):
			_dici(str(_c.get("grazie", "Grazie, guagliò! Curre!")), 3.2)
			SoundManager.ui("ui_missione")
			_passa_robba_al_player()
		return
	if stato != "in_mano":
		return
	var paga: int = GameManager.consegna_commissione(cid)
	if paga > 0:
		var frase: String = str(_c.get("ricevuto", "Grazie! Tiè, chesti so' pe' te."))
		if str(_c.get("robba", "")) == "sciure":
			frase = str(_c.get("ricevuto_alt", frase)) if randf() < 0.5 else frase
		_dici(frase, 4.0)
		GameManager.event_started.emit("Cummissione fatta: +€%d. %s" % [paga,
			str(_c.get("coda", "Chi cammina, magna."))])
		SoundManager.ui("ui_ok")
		# La roba passa a lui: gliela si vede in mano.
		_robba = Robba.costruisci(str(_c.get("robba", "pacco")))
		add_child(_robba)
		_robba.position = Vector3(0, 1.0, -0.34)
		if _anim != null:
			_anim.action("shrug")


## La roba vola dalle sue mani (dal sellino) alle tue: mezzo secondo, poi
## sparisce e compare in prima persona (ci pensa il player, che guarda la
## commissione in mano).
func _passa_robba_al_player() -> void:
	if _robba == null or not is_instance_valid(_robba):
		return
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	if pl == null:
		_robba.queue_free()
		return
	var r := _robba
	_robba = null
	var da: Vector3 = r.global_position
	r.top_level = true
	r.global_position = da
	var a: Vector3 = pl.global_position + Vector3(0, 1.2, 0)
	var tw := create_tween()
	tw.tween_property(r, "global_position", a, 0.45).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(r.queue_free)
