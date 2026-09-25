extends Node3D
## Bambini
## Quattro ragazzini e un pallone, in un angolo di piazza.
##
## Non è un minigioco e non ti riguarda: giocano fra loro. Chi arriva sulla
## palla la calcia verso una porta, gli altri corrono a smarcarsi. Ogni
## tanto uno grida che era fallo.
##
## ## 'O pallone è overo (0.56)
##
## Il pallone dei guaglioni era una sfera con dentro venti righe di fisica
## scritta a mano: gravità, rimbalzo sul piano, attrito a terra, e un
## cerchio invisibile a otto metri contro cui rimbalzava. Funzionava, in un
## certo senso — **passava attraverso i muri, le macchine, i passanti e i
## guaglioni stessi**, e quando ci camminavi contro faceva una cosa sua che
## non somigliava a un calcio.
##
## Il capo, punto 5: *«Migliora la fisica del pallone con cui giocano i
## ragazzini, al momento è difficile controllarlo e segnare. Se non sbaglio
## c'è anche una meccanica che facendo gol si guadagnano soldi, è un easter
## egg carino che terrei.»* — e punto 8: *«molti png attraversano i muri…»*.
##
## Le due cose si risolvono insieme e la risposta è la stessa: **'o pallone
## bbuono ce steva già**. `scripts/pallone_3d.gd` è un corpo rigido vero,
## con la livrea del Super Santos, che rimbalza sui muri, si ferma da solo,
## torna a casa se lo perdi, e ha il calcio rifatto apposta perché si
## possa condurre. Quindi i guaglioni adesso giocano con **quello**: stesso
## pallone del campetto, stessa fisica, stessa porta che paga.
##
## Cosa cambia per chi gioca: ci puoi giocare insieme a loro. Glielo levi,
## te lo porti verso la porta, segni, e ti pagano — ma solo se **l'ultimo
## tocco è tuo** (vedi `Pallone3D._tuo`), se no bastava stare a guardare.

const Human := preload("res://scripts/human_builder.gd")
const Tex := preload("res://scripts/textures.gd")
const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const PalloneScene := preload("res://scripts/pallone_3d.gd")

const RAGGIO_CAMPO: float = 6.0
const VELOCITA: float = 3.4
const FORZA_MIN: float = 5.0
const FORZA_MAX: float = 9.0

## **'A porta è una sola**, come nei campetti veri di piazza: due zainetti e
## tutti a tirare da quella parte. Prima erano due, una per lato, e serviva
## solo a far correre i guaglioni avanti e indietro; con una sola si capisce
## dov'è la porta appena arrivi, e si capisce dove devi tirare tu.
const PORTA_LARGA: float = 2.8
const PORTA_ALTA: float = 1.15

const GRIDA := [
	"Passa! Passaaa!", "Era fallo!", "Golllll!", "Mo' tocca a me!",
	"Ma ch'è stato chillu tiro?", "Vaje 'a rrete!", "'A palla è 'a mia!",
	"Uè, fatte 'nu lato!",
]

var _ragazzi: Array = []
var _palla: Node3D
var _bubble: Node3D
var _grido: float = 0.0
var _porte: Array = []


## Quanto costa mandarli a chiamare il vigile, e per quanto lo tengono
## occupato. Dieci euro sono una mancia e mezza: si sentono, ma se stai
## per farti multare li spendi volentieri.
const PREZZO_DISTRAZIONE: int = 10
const DURATA_DISTRAZIONE: float = 40.0
const RIPOSO_DISTRAZIONE: float = 55.0
const SAY_PAGATI := ["Uè guagliù, jammo a chiammà 'o vigile!",
	"E mo' ce pensammo nuje!", "Guagliù, 'o pallone 'n copp' 'a machina soja!"]

var _cd_distrazione: float = 0.0


func _ready() -> void:
	add_to_group("bambini")
	add_to_group("attivita")
	_porte_di_zaini()
	_costruisci_palla()
	for i in range(4):
		_costruisci_ragazzo(i)
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 2.0, 0)
	add_child(_bubble)


## La porta: due zainetti per terra, come si è sempre fatto — più due righe
## di gesso, che sono quelle che la fanno leggere come una porta e non come
## due zaini lasciati lì.
func _porte_di_zaini() -> void:
	var p := Vector3(RAGGIO_CAMPO, 0.0, 0.0)
	_porte.append(p)
	for d in [-PORTA_LARGA * 0.5, PORTA_LARGA * 0.5]:
		var zaino := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.34, 0.28, 0.24)
		zaino.mesh = bm
		zaino.position = p + Vector3(0, 0.14, d)
		zaino.material_override = Tex.flat(
			[Color(0.8, 0.25, 0.2), Color(0.2, 0.35, 0.7),
			Color(0.2, 0.5, 0.3)][randi() % 3], 0.9)
		add_child(zaino)
	var gesso := Tex.flat(Color(0.93, 0.92, 0.87), 0.95)
	for riga in [
			[p + Vector3(0.0, 0.02, 0.0), Vector3(0.08, 0.01, PORTA_LARGA)],
			[p + Vector3(-2.0, 0.02, 0.0), Vector3(0.08, 0.01, PORTA_LARGA + 2.4)],
			[p + Vector3(-1.0, 0.02, (PORTA_LARGA + 2.4) * 0.5),
				Vector3(2.0, 0.01, 0.08)],
			[p + Vector3(-1.0, 0.02, -(PORTA_LARGA + 2.4) * 0.5),
				Vector3(2.0, 0.01, 0.08)]]:
		var segno := MeshInstance3D.new()
		var mm := BoxMesh.new()
		mm.size = riga[1]
		segno.mesh = mm
		segno.position = riga[0]
		segno.material_override = gesso
		add_child(segno)


## **'O pallone**: nun è cchiù 'na palla fatta 'a mano, è chillo overo.
##
## `Pallone3D` è un `RigidBody3D` con la sfera, il materiale fisico e la
## livrea del Super Santos: rimbalza sui muri veri, sulle macchine in sosta
## e sui cassonetti, e non ci passa attraverso. La porta che gli si dà è
## quella degli zainetti, e si entra andando verso +X — che è la direzione
## in cui la porta guarda il campetto.
func _costruisci_palla() -> void:
	var b = PalloneScene.new()
	add_child(b)
	b.goal_width = PORTA_LARGA
	b.goal_height = PORTA_ALTA
	b.goal_normale = Vector3(1, 0, 0)
	_palla = b
	# **'A posizione se mette 'o frame appriesso, e ce vò.**
	#
	# Chi ci costruisce (`citta_3d._build_bambini`) fa `add_child(b)` e
	# *poi* `b.global_position = centro`: quindi qui dentro, dentro a
	# `_ready()`, il campetto sta ancora all'origine del mondo e `setup()`
	# pianterebbe pallone e porta a (0, 0, 0) — a centoventi metri da dove
	# giocano i guaglioni. Un fotogramma dopo la posizione c'è, e si fa.
	call_deferred("_pianta_o_pallone")


func _pianta_o_pallone() -> void:
	if _palla == null or not is_instance_valid(_palla):
		return
	_palla.setup(global_position, global_position + _porte[0])


func _costruisci_ragazzo(i: int) -> void:
	var maglie := [Color(0.25, 0.55, 0.85), Color(0.9, 0.85, 0.3),
		Color(0.85, 0.3, 0.28), Color(0.3, 0.7, 0.45)]
	var nodo := Node3D.new()
	add_child(nodo)
	var a: float = float(i) / 4.0 * TAU
	nodo.position = Vector3(cos(a) * 4.0, 0, sin(a) * 4.0)
	# L'altezza è quello che li fa leggere come ragazzini, molto più del resto.
	var parts := Human.build(maglie[i], Color(0.2, 0.22, 0.28), "bambino",
		randf_range(1.24, 1.42), {
			"belly": randf_range(0.0, 0.3), "bald": false,
			"moustache": false, "hair": Color(0.12, 0.09, 0.07),
		})
	nodo.add_child(parts["root"])
	_ragazzi.append({"nodo": nodo, "anim": parts.get("anim", null),
		"attesa": randf_range(0.0, 1.0)})


func get_interact_prompt(_da: Vector3) -> String:
	if _cd_distrazione > 0.0:
		return "'E guagliune stanno già facenno 'o burdello"
	if GameManager.money < PREZZO_DISTRAZIONE:
		return "'E guagliune — €%d p'annuià 'o vigile (nun 'e tiene)" % PREZZO_DISTRAZIONE
	return "'E guagliune — [E] €%d e vanno a rompere 'e cape ô vigile" % PREZZO_DISTRAZIONE


## **Dieci euro ai guagliuni.**
##
## Non e' un trucco: e' esattamente come funziona. Tu paghi, loro vanno a
## tirare il pallone addosso alla macchina del vigile, e per quaranta
## secondi lui sta a discutere con loro invece di guardare te. E' l'altra
## faccia della meccanica del bar — li' aspetti che si distragga da solo,
## qui paghi per farlo succedere adesso.
func player_interact() -> void:
	if _cd_distrazione > 0.0:
		return
	if GameManager.money < PREZZO_DISTRAZIONE:
		SoundManager.play("fail", -10.0, 0.9)
		return
	GameManager.money -= PREZZO_DISTRAZIONE
	GameManager.money_changed.emit(GameManager.money)
	SoundManager.play("coin", -4.0)
	_cd_distrazione = RIPOSO_DISTRAZIONE
	if _bubble:
		_bubble.say(SAY_PAGATI[randi() % SAY_PAGATI.size()], 2.6)
	var quanti := 0
	for v in get_tree().get_nodes_in_group("vigili"):
		if v.has_method("distrai") \
				and global_position.distance_to(v.global_position) < 70.0:
			v.distrai(DURATA_DISTRAZIONE)
			quanti += 1
	if quanti > 0:
		GameManager.avvisa_strada(
			"'E guagliune so' ghiuti 'a lloco. Tiene %d second' 'e pace."
			% int(DURATA_DISTRAZIONE))
	else:
		GameManager.avvisa_strada(
			"'E guagliune so' ghiuti, ma 'o vigile nun sta ccà attuorno.")


func _process(delta: float) -> void:
	_cd_distrazione = maxf(0.0, _cd_distrazione - delta)
	_grido = maxf(0.0, _grido - delta)
	if _palla == null or not is_instance_valid(_palla):
		return
	# 'A palla mo' se move 'a sola: 'o motore fa 'a fisica, ccà se guarda
	# sulo addó sta.
	var palla: Vector3 = _palla.position
	# **'A palla ca esce d''o campo** (0.60). I ragazzini non escono dal
	# cerchio del campetto (`RAGGIO_CAMPO` + 3, vedi sotto): è quello che li
	# tiene nel largo invece che in mezzo alla strada. Ma il pallone esce, e
	# chi gli stava più vicino ci camminava dietro **contro il bordo del
	# cerchio**, sul posto, finché dopo tre secondi `_se_a_palla_nun_se_piglia`
	# non lo rimetteva in mezzo. È il ragazzino «piantato» che `prova_ntuppate`
	# trovava una volta ogni tanto al bordo est del largo, da due versioni.
	# Adesso quando la palla esce tutti si fermano a guardarla, e dopo un
	# secondo e mezzo uno la va a prendere e la rimette in gioco.
	var fore_campo: bool = Vector2(palla.x, palla.z).length() > RAGGIO_CAMPO + 2.5
	if fore_campo:
		_palla_fore += delta
		if _palla_fore > PALLA_FORE_DOPO:
			_palla_fore = 0.0
			_palla.position = Vector3(randf_range(-1.0, 1.0), 0.35, randf_range(-1.0, 1.0))
			if _palla is RigidBody3D:
				(_palla as RigidBody3D).linear_velocity = Vector3.ZERO
				(_palla as RigidBody3D).angular_velocity = Vector3.ZERO
			if _bubble:
				_bubble.say("Jammo, 'o pallone! Chi l'ha menato for'?", 1.6)
			palla = _palla.position
			fore_campo = false
	else:
		_palla_fore = 0.0

	var vicino: int = -1
	var min_d: float = INF
	for i in _ragazzi.size():
		var d: float = _ragazzi[i]["nodo"].position.distance_to(palla)
		if d < min_d:
			min_d = d
			vicino = i

	for i in _ragazzi.size():
		var r: Dictionary = _ragazzi[i]
		var nodo: Node3D = r["nodo"]
		var meta: Vector3 = palla
		var aspetta := fore_campo
		if i != vicino and not fore_campo:
			# Chi non ha la palla si smarca girandole intorno.
			var a: float = float(i) * 1.9 + float(Time.get_ticks_msec()) * 0.00008
			meta = palla + Vector3(cos(a), 0, sin(a)) * 3.6
			# **E si 'o posto sta dint'ô muro, aspetta** (0.59). Il giro
			# intorno alla palla non guarda dove cade: con la palla vicino
			# a un palazzo metà dei posti sono dentro al palazzo, e il
			# guagliuno ci camminava contro sul posto.
			if Passo._chiuso(to_global(Vector3(meta.x, 0.0, meta.z)), 0.34):
				aspetta = true
			# **E si 'nmiezo ce sta 'nu muro, aspetta pure** (0.59). Il posto
			# può stare fuori dal palazzo e il palazzo stare **in mezzo**:
			# la palla da un lato del muro, il posto intorno a lei dall'altro.
			# Il ragazzino ci camminava contro sul posto (`prova_ntuppate`,
			# uno ogni due minuti accanto al vicolo).
			elif _muro_in_mezzo(r, nodo.position, meta, delta):
				aspetta = true
		meta.y = 0.0
		var dir: Vector3 = meta - nodo.position
		dir.y = 0.0
		var dist: float = dir.length()
		var v: float = 0.0
		# **Chi tene 'a palla sotto ê piere nun cammina: tira** (0.60). Il
		# calcio parte da 1,05 m, ma le gambe si fermavano solo a 0,70: con
		# la palla schiacciata contro qualcosa il guagliuno restava a
		# 0,78 m a «camminare» sul posto e a tirare calci che non la
		# spostavano (`prova_ntuppate`, una volta ogni tanto, al bordo est
		# del largo). Adesso chi è a tiro si ferma e tira.
		var arriva: float = 0.9 if i == vicino else 0.7
		if dist > arriva and not aspetta:
			v = VELOCITA
			# **E 'e mure ce stanno pure pe' lloro** (0.56, punto 8). Il
			# campetto è in mezzo alla città, e quando la palla finiva contro
			# un palazzo il guagliuno ci andava appresso **dentro al muro**.
			# `Passo.verso` lavora in coordinate globali, quindi si passa di
			# là e si torna: il nodo del ragazzino è figlio del campetto.
			var mira_g: Vector3 = to_global(nodo.position
				+ dir.normalized() * v * delta)
			nodo.global_position = Passo.verso(nodo, mira_g, v * delta, 0.34)
			nodo.rotation.y = lerp_angle(nodo.rotation.y,
				atan2(-dir.x, -dir.z),
				1.0 - exp(-10.8 * delta))
		elif aspetta:
			# Chi aspetta guarda la palla, non il muro.
			var verso_palla: Vector3 = palla - nodo.position
			if Vector2(verso_palla.x, verso_palla.z).length() > 0.1:
				nodo.rotation.y = lerp_angle(nodo.rotation.y,
					atan2(-verso_palla.x, -verso_palla.z), 1.0 - exp(-6.0 * delta))
		var piano := Vector3(nodo.position.x, 0, nodo.position.z)
		if piano.length() > RAGGIO_CAMPO + 3.0:
			nodo.position = piano.normalized() * (RAGGIO_CAMPO + 3.0)
		if r["anim"] != null:
			r["anim"].set_speed(v)
		if i == vicino:
			_se_a_palla_nun_se_piglia(r, dist, delta)
			_se_a_palla_nun_se_move(r, dist, palla, delta)
		if i == vicino and dist < 1.05:
			r["attesa"] -= delta
			if r["attesa"] <= 0.0:
				r["attesa"] = randf_range(0.5, 1.4)
				_tira(nodo)
				if r["anim"] != null:
					r["anim"].action("punch")


## **'A palla ca nun se piglia** (0.59).
##
## Quando la palla finisce contro un palazzo o dietro a una panchina, chi le
## sta più vicino non la raggiunge: il passo lo tiene fuori dal muro, e lui
## resta lì a spingere. `prova_ntuppate` ne contava una quindicina ogni due
## minuti. Un ragazzino vero a quel punto la va a prendere con le mani e la
## rimette in mezzo al campo — ed è esattamente quello che si fa qui, dopo
## tre secondi senza avvicinarsi di un palmo.
const PALLA_PERSA_DOPO: float = 3.0
## Quanto si aspetta prima di andare a prendere la palla uscita dal campo.
const PALLA_FORE_DOPO: float = 1.5
var _palla_fore: float = 0.0


## Fra il ragazzino e il posto dove vuole andare c'è un muro? Si guarda a
## passi di quaranta centimetri, quattro volte al secondo (non a ogni
## fotogramma: il muro non si sposta).
func _muro_in_mezzo(r: Dictionary, da: Vector3, a: Vector3, delta: float) -> bool:
	r["guarda_muro"] = float(r.get("guarda_muro", 0.0)) - delta
	if float(r["guarda_muro"]) > 0.0:
		return bool(r.get("muro", false))
	r["guarda_muro"] = 0.25
	var g_da: Vector3 = to_global(Vector3(da.x, 0.0, da.z))
	var g_a: Vector3 = to_global(Vector3(a.x, 0.0, a.z))
	var passi: int = int(ceil(g_da.distance_to(g_a) / 0.4))
	var muro := false
	for k in range(1, passi + 1):
		if Passo._chiuso(g_da.lerp(g_a, float(k) / float(passi)), 0.34):
			muro = true
			break
	r["muro"] = muro
	return muro


func _se_a_palla_nun_se_piglia(r: Dictionary, dist: float, delta: float) -> void:
	if dist < 1.05:
		r["meglio"] = dist
		r["senza"] = 0.0
		return
	var meglio: float = float(r.get("meglio", INF))
	if dist < meglio - 0.2:
		r["meglio"] = dist
		r["senza"] = 0.0
		return
	r["senza"] = float(r.get("senza", 0.0)) + delta
	if float(r["senza"]) < PALLA_PERSA_DOPO:
		return
	r["senza"] = 0.0
	r["meglio"] = INF
	_palla.position = Vector3(randf_range(-1.0, 1.0), 0.35, randf_range(-1.0, 1.0))
	if _palla is RigidBody3D:
		(_palla as RigidBody3D).linear_velocity = Vector3.ZERO
		(_palla as RigidBody3D).angular_velocity = Vector3.ZERO
	if _bubble:
		_bubble.say("'A piglio io! 'A piglio io!", 1.6)


## **'A palla ca nun se move** (0.60).
##
## L'altra metà di `_se_a_palla_nun_se_piglia`: il ragazzino la palla l'ha
## raggiunta, la calcia, e lei non si muove — incastrata fra un palo e il
## muro, o contro lo spigolo del marciapiede. Tre secondi a tiro senza che
## la palla faccia mezzo metro, e il guagliuno la raccoglie e la rimette in
## mezzo, come si fa.
const PALLA_FERMA_DOPO: float = 3.0


func _se_a_palla_nun_se_move(r: Dictionary, dist: float, palla: Vector3,
		delta: float) -> void:
	if dist >= 1.05:
		r["a_tiro"] = 0.0
		r.erase("palla_da")
		return
	if not r.has("palla_da") or (r["palla_da"] as Vector3).distance_to(palla) > 0.5:
		r["palla_da"] = palla
		r["a_tiro"] = 0.0
		return
	r["a_tiro"] = float(r.get("a_tiro", 0.0)) + delta
	if float(r["a_tiro"]) < PALLA_FERMA_DOPO:
		return
	r["a_tiro"] = 0.0
	r.erase("palla_da")
	_palla.position = Vector3(randf_range(-1.0, 1.0), 0.35, randf_range(-1.0, 1.0))
	if _palla is RigidBody3D:
		(_palla as RigidBody3D).linear_velocity = Vector3.ZERO
		(_palla as RigidBody3D).angular_velocity = Vector3.ZERO
	if _bubble:
		_bubble.say("S'è 'ncastrata! Aspè, 'a piglio io.", 1.6)


## Il guagliuno tira verso la porta. La forza e la storta sono le stesse di
## prima; a muoverlo però adesso è il corpo rigido, non venti righe di
## fisica scritta a mano.
func _tira(da: Node3D) -> void:
	var verso: Vector3 = _porte[0] - _palla.position
	verso.y = 0.0
	if verso.length() < 0.1:
		verso = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	# Storto quanto basta: sono ragazzini, non professionisti.
	verso = verso.normalized().rotated(Vector3.UP, randf_range(-0.5, 0.5))
	_palla.calcia_guagliuno(verso, randf_range(FORZA_MIN, FORZA_MAX))
	if _grido <= 0.0:
		_grido = randf_range(3.0, 8.0)
		if _bubble:
			_bubble.position = da.position + Vector3(0, 1.7, 0)
			_bubble.say(GRIDA[randi() % GRIDA.size()], 1.8)
