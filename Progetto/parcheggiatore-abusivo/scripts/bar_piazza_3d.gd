extends StaticBody3D
## BarPiazza3D — 'o bar sott'ô palazzo
##
## **Pecché ce ne vò uno pe' piazza.**
##
## Il capo: *"aggiungi bar e tabacchi in tutte le piazze"*. Il tabaccaio
## c'era già in ognuna; il bar no — ce n'era **uno solo** in tutta la
## città, in un angolo, e chi comprava una piazza nuova si ritrovava senza
## caffè. Che nel gioco non è un dettaglio di colore: il caffè **abbassa
## il sospetto e rimette in forza**, cioè è la mossa che salva la giornata
## quando le stelle cominciano ad accendersi.
##
## Un mestiere che vive di attese ha bisogno di un posto dove aspettare
## senza dare nell'occhio, e in Italia quel posto è il bar. Averlo lontano
## voleva dire, in pratica, non averlo.
##
## **Che ce se fa.**
##
##   * `[E]` — 'o cafè al banco: si beve **subito**, senza passare per lo
##     zaino. È la differenza col tabaccaio, dove i caffè si comprano a
##     tre per volta e si portano appresso;
##   * `[1]` — 'a colazione, ma **solo 'a matina** (prima delle tre): un
##     cornetto e un caffè rimettono più ossa e costano di più. Un bar che
##     serve la colazione a mezzanotte non è un bar.
##
## E c'è anche il posto dove ci si appoggia: il vigile lo cerca da solo
## (gruppo `banco_bar`), quindi da adesso il vigile si prende il caffè
## nella piazza dove sta, non attraversa mezza città per andare all'unico
## bancone che c'era.

const Tex := preload("res://scripts/textures.gd")
const Models := preload("res://scripts/models.gd")
const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const PostoUtile := preload("res://scripts/posto_utile.gd")

const CAFFE_BANCO: int = 1
const COLAZIONE: int = 3
## Le ossa che rimette una colazione vera, contro le poche del caffè secco.
const COLAZIONE_OSSA: float = 22.0
## Fino a che ora si fa colazione: le tre del pomeriggio, e già è tanto.
const ORA_COLAZIONE: float = 3.0

const SAY_CAFFE := ["Nu cafè, e stàtte buono.", "Ristretto, comm''o vuo' tu.",
	"Tiè. E nun t''o scurdà 'e pagà, ah!"]
const SAY_COLAZIONE := ["Cornetto e cafè. Chesta è colazione.",
	"Cavero cavero, appena sciuto."]
const SAY_TARDE := "'A colazione â matina, guagliò. Mo' è tarde."
const SAY_SENZA := "E cu che me pave, cu 'e bottone?"

var _bubble: Node3D
var _insegna: Label3D


func _ready() -> void:
	add_to_group("shop")
	add_to_group("bar")
	collision_layer = 1
	collision_mask = 0
	_costruisci()
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 3.2, 0.9)
	add_child(_bubble)


func _say(t: String) -> void:
	if _bubble:
		_bubble.say(t)
	GameManager.directing_gesture.emit("« 'O barista »: %s" % t, true)


# ---------------------------------------------------------------------------
# 'O muorzo 'e bar
# ---------------------------------------------------------------------------
#
# Un bar napoletano sotto a un palazzo è: la tenda a strisce, il bancone
# di metallo che dà sulla strada, la macchina del caffè che si vede da
# fuori, e l'insegna. Quattro cose, e si riconosce da trenta metri — che è
# tutto quello che serve, perché il bar dev'essere una cosa che **si
# individua**, non una che si esplora.

func _costruisci() -> void:
	var metallo := Tex.flat(Color(0.62, 0.63, 0.66), 0.35, 0.7)
	var scuro := Tex.flat(Color(0.16, 0.15, 0.17), 0.8)

	# Il bancone verso la strada.
	var banco := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.7, 1.06, 3.0)
	banco.mesh = bm
	banco.position = Vector3(0.35, 0.53, 0)
	banco.material_override = metallo
	add_child(banco)

	# Il piano, un filo più largo: è il gesto che fa "bancone".
	var piano := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.92, 0.07, 3.2)
	piano.mesh = pm
	piano.position = Vector3(0.42, 1.09, 0)
	piano.material_override = Tex.flat(Color(0.24, 0.22, 0.24), 0.25, 0.9)
	add_child(piano)

	# Il muro dietro, con la vetrina.
	var muro := MeshInstance3D.new()
	var mm := BoxMesh.new()
	mm.size = Vector3(0.3, 3.0, 3.4)
	muro.mesh = mm
	muro.position = Vector3(-0.5, 1.5, 0)
	muro.material_override = scuro
	add_child(muro)

	# La macchina del caffè: due cilindri e una piastra. Da lontano è
	# solo un luccichio sul bancone, ed è esattamente quello che serve.
	for z in [-0.55, 0.55]:
		var testa := MeshInstance3D.new()
		var tm := CylinderMesh.new()
		tm.top_radius = 0.09
		tm.bottom_radius = 0.09
		tm.height = 0.42
		testa.mesh = tm
		testa.position = Vector3(0.05, 1.34, z)
		testa.material_override = Tex.flat(Color(0.78, 0.76, 0.72), 0.2, 0.95)
		add_child(testa)
	var corpo := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(0.5, 0.5, 1.5)
	corpo.mesh = cm
	corpo.position = Vector3(-0.12, 1.38, 0)
	corpo.material_override = Tex.flat(Color(0.55, 0.14, 0.12), 0.3, 0.8)
	add_child(corpo)

	# La tenda a strisce.
	for i in range(8):
		var t := MeshInstance3D.new()
		var tm2 := BoxMesh.new()
		tm2.size = Vector3(1.5, 0.04, 0.42)
		t.mesh = tm2
		t.position = Vector3(0.75, 2.62, -1.6 + i * 0.44)
		t.rotation.z = deg_to_rad(-9.0)
		t.material_override = Tex.flat(
			Color(0.78, 0.20, 0.18) if i % 2 == 0 else Color(0.92, 0.90, 0.86),
			0.85)
		add_child(t)

	_insegna = Label3D.new()
	_insegna.text = "BAR"
	_insegna.font_size = 64
	_insegna.pixel_size = 0.006
	_insegna.position = Vector3(0.55, 2.95, 0)
	_insegna.rotation.y = deg_to_rad(-90.0)
	_insegna.modulate = Color(0.98, 0.86, 0.40)
	_insegna.outline_size = 8
	_insegna.outline_modulate = Color(0.12, 0.10, 0.10)
	add_child(_insegna)
	# 0.62: sotto a BAR, il cartellino blu del LOTTO — qui se joca.
	var lotto := Label3D.new()
	lotto.text = "LOTTO"
	lotto.font_size = 44
	lotto.pixel_size = 0.005
	lotto.position = Vector3(0.55, 2.55, 0)
	lotto.rotation.y = deg_to_rad(-90.0)
	lotto.modulate = Color(1, 1, 1)
	lotto.outline_size = 12
	lotto.outline_modulate = Color(0.13, 0.36, 0.72)
	add_child(lotto)

	# **'O rilorgio e 'e cascette d''e birre** (0.60, PSX). L'orologio a
	# muro sopra alla macchina del caffè (quello che il barista guarda quando
	# gli chiedi "ch'ora è?") e due cassette di vuoti impilate a fianco del
	# muro, dalla parte chiusa: il bar vero tiene i vuoti fuori, e li ritira
	# il fornitore la mattina.
	var orologio := Models.spawn("orologio_bar")
	if orologio != null:
		orologio.position = Vector3(-0.32, 2.3, 1.05)
		orologio.rotation.y = PI * 0.5
		add_child(orologio)
	for k in 2:
		var vuoti := Models.spawn("cascia_birre" if k == 0 else "cascia_birre2")
		if vuoti == null:
			break
		vuoti.position = Vector3(-0.25, 0.37 * float(k), -2.03)
		vuoti.rotation.y = PI * 0.5 + (0.12 if k == 1 else 0.0)
		add_child(vuoti)
	if Models.has_model("cascia_birre"):
		var fv := CollisionShape3D.new()
		var bv := BoxShape3D.new()
		bv.size = Vector3(0.5, 0.8, 0.72)
		fv.shape = bv
		fv.position = Vector3(-0.25, 0.4, -2.03)
		add_child(fv)

	# Il collider: il bancone e il muro, non la tenda.
	var forma := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.5, 3.0, 3.4)
	forma.shape = box
	forma.position = Vector3(-0.15, 1.5, 0)
	add_child(forma)

	# **'O posto addò s'appoggia 'o vigile.** Sta nel gruppo che il vigile
	# cerca da solo: da adesso ogni piazza ha il suo, e il vigile non
	# attraversa più la città per un caffè.
	var banco_v := Node3D.new()
	banco_v.name = "BancoBar"
	banco_v.position = Vector3(1.5, 0, 1.1)
	banco_v.add_to_group("banco_bar")
	add_child(banco_v)

	# E il posto dove ci si appoggia tu: stare fermi al bar abbassa il
	# sospetto, ed è la cosa più napoletana che questo gioco possa fare.
	var pu = PostoUtile.new()
	pu.tipo = "appoggio"
	pu.riposo = 8.0
	pu.position = Vector3(1.6, 0, -1.2)
	add_child(pu)
	# **Nun è 'nu muro** (0.64): la scatola serve a guardarlo, non a
	# fermare chi passa. Nella piazza di casa stava un metro e mezzo dentro
	# al posto auto accanto al bar, e chi ci posteggiava sbatteva contro
	# l'aria (`prova_conquista`, «posto murato»). Il mirino lo trova lo
	# stesso: sta nel gruppo delle attività.
	pu.collision_layer = 0
	var f := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(1.6, 2.0, 1.6)
	f.shape = b
	f.position = Vector3(0, 1.0, 0)
	pu.add_child(f)


# ---------------------------------------------------------------------------
# 'O banco
# ---------------------------------------------------------------------------

func _e_matina() -> bool:
	return GameManager.ore_passate() < ORA_COLAZIONE


func get_interact_prompt(_da: Vector3) -> String:
	# 0.62: in ogni bar si gioca pure 'o lotto ([2]), come ai bar-tabacchi
	# veri. Prima stava solo al tabaccaio della piazza di casa.
	if _e_matina():
		return "[E] 'nu cafè €%d · [1] 'a colazione €%d · [2] 'o LOTTO" % [
			CAFFE_BANCO, COLAZIONE]
	return "[E] 'nu cafè ô banco €%d · [2] gioca 'o LOTTO" % CAFFE_BANCO


func player_interact() -> void:
	if not GameManager.paga(CAFFE_BANCO):
		SoundManager.play("fail", -8.0, 0.9)
		_say(SAY_SENZA)
		return
	GameManager.caffe_al_banco()
	SoundManager.play("coin", -6.0, 1.15)
	_say(SAY_CAFFE[randi() % SAY_CAFFE.size()])


func compra_voce(indice: int) -> void:
	if indice != 0:
		return
	if not _e_matina():
		SoundManager.play("fail", -10.0, 1.0)
		_say(SAY_TARDE)
		return
	if not GameManager.paga(COLAZIONE):
		SoundManager.play("fail", -8.0, 0.9)
		_say(SAY_SENZA)
		return
	GameManager.caffe_al_banco()
	GameManager.heal_player(COLAZIONE_OSSA)
	SoundManager.play("coin", -5.0, 1.05)
	_say(SAY_COLAZIONE[randi() % SAY_COLAZIONE.size()])


func _physics_process(_delta: float) -> void:
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null or pl.get("current_target") != self:
		return
	if Input.is_action_just_pressed("buy_1"):
		compra_voce(0)
	elif Input.is_action_just_pressed("buy_2"):
		_say("'O lotto? Tiè, 'a schedina.")
		preload("res://scripts/pannello_lotto.gd").apri_da(self)
