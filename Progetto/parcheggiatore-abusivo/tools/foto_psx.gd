extends Node
## Fote d''a robba PSX (0.58).
##
## `prova_psx` ha misurato tutti e centosedici i modelli e dice che stanno a
## misura. **Non basta, e in questo progetto si sa perché:** alla 0.57 il
## lampione era misurato giusto e aveva la luce appesa dalla parte sbagliata
## del braccio, e le tre righe dell'HUD della 0.56 erano tutte dentro allo
## schermo e stampate una sopra all'altra. Il numero dice quanto è grande;
## solo l'occhio dice se sta bene.
##
## Quattro scatti, e ognuno guarda una cosa diversa:
##
##   1. **'o banco 'e ll'armiere** — le armi sono l'unica cosa che il
##      giocatore guarda da trenta centimetri;
##   2. **'o vicolo** — la munnezza nuova, e soprattutto **se sta fora d''a
##      corsia**: è l'unico modo di vedere con gli occhi quello che
##      `prova_mure` dice a numeri;
##   3. **'a vetrina** — la merce dietro al vetro;
##   4. **'o vascio** — la roba sopra ai mobili.
##
## **E ll'inquadrature se cercano.** Regola della 0.57, imparata due volte:
## ogni soggetto si fa trovare nella scena (per gruppo o per nome), e la
## telecamera si piazza in un punto che è stato verificato essere fuori dai
## palazzi. Puntare a coordinate scelte a occhio vuol dire fotografare un
## muro, e l'ho già fatto.

const CarScript := preload("res://scripts/car_3d.gd")

var _t := 0.0
var _n := 0
var _pronto := false
var _cam: Camera3D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(d: float) -> void:
	if not _pronto:
		_pronto = true
		# 'A schermata 'e caricamento sta ô layer 220 e cummoglia tutto: se
		# stuta (nun se clicca — 'o motore schiatta, vedi `foto_furto`).
		for n in _tutte(get_tree().root):
			if n is CanvasLayer and n.has_method("_on_menu_gioca"):
				(n as CanvasLayer).visible = false
				break
		get_tree().paused = false
		GameManager.giornata = 3
		GameManager.start_shift()
		GameManager.tipo_giornata = "normale"
		GameManager.intro_active = false
		GameManager.shift_time_left = GameManager.shift_duration * 0.88
		_cam = Camera3D.new()
		get_tree().root.add_child(_cam)
		_cam.current = true
		return
	_t += d
	if _t < 0.9:
		return
	_t = 0.0
	_n += 1
	match _n:
		1: print("  se aspetta ca 'a città s'apara")
		2: _guarda_ô_banco()
		3: await _scatta("armiere")
		4: _guarda_ô_vicolo()
		5: await _scatta("vicolo")
		6: _guarda_â_vetrina()
		7: await _scatta("vetrina")
		8: _guarda_dint_ô_vascio()
		9: await _scatta("vascio")
		_: get_tree().quit()


# ---------------------------------------------------------------------------

func _guarda_ô_banco() -> void:
	var a := _truova_pe_nomme("Armiere")
	if a == null:
		print("  NUN CE STA LL'ARMIERE")
		return
	print("  armiere truvato a %s" % str(a.global_position.round()))
	# Dal davanti del banco, all'altezza di chi guarda la merce.
	_mira(a.global_position + a.global_transform.basis.z * 2.3
		+ Vector3(0, 1.55, 0), a.global_position + Vector3(0, 1.45, 0))


func _guarda_ô_vicolo() -> void:
	var z := _truova_zona()
	if z == null:
		print("  NUN CE STANNO VICULE")
		return
	var w: float = float(z.get("width"))
	var l: float = float(z.get("length"))
	print("  vicolo %s, largo %.0f luongo %.0f"
		% [str(z.global_position.round()), w, l])
	# **'A veduta d''a corsia.** In mezzo alla carreggiata, bassi, a guardare
	# lungo il vicolo: se la roba nuova fosse finita in strada, si vedrebbe
	# esattamente da qui — ed è per questo che l'inquadratura è questa e non
	# una più bella.
	# 'A primma inquadratura steva 'n miezo â carreggiata a guardà 'o fondo
	# d''o vicolo: 'a corsia s'è vista libbera (ch'è 'a cosa ca cchiù
	# conta) ma 'a munnezza asceva grossa comm'a 'nu chicco 'e riso. Mo' se
	# guarda 'o marciapiede 'e ponente 'a vicino, ch'è addó 'a robba sta.
	_mira(z.global_position + Vector3(w * 0.46, 1.62, l * 0.30),
		z.global_position + Vector3(2.4, 0.70, l * 0.52))


func _guarda_â_vetrina() -> void:
	var z := _truova_zona()
	if z == null:
		return
	var w: float = float(z.get("width"))
	var l: float = float(z.get("length"))
	# **'A bancarella se cerca, nun se 'nduveena.** Solo una serranda su tre
	# ha la roba davanti, quindi puntare a una z scelta a caso vuol dire
	# fotografare una saracinesca chiusa — ed è esattamente quello che è
	# successo al primo giro. Si scorre la zona, si trova una cassa di
	# legno appoggiata al muro, e ci si mette davanti.
	var cascia: Node3D = null
	for n2 in _tutte(z):
		if n2 is Node3D and str(n2.name).begins_with("bancarella"):
			cascia = n2
			break
	if cascia == null:
		print("  NUN S'È TRUVATA 'NA BANCARELLA")
		_mira(z.global_position + Vector3(2.6, 1.45, l * 0.52),
			z.global_position + Vector3(0.4, 1.25, l * 0.52))
		return
	var q: Vector3 = cascia.global_position
	print("  bancarella truvata a %s" % str(q.round()))
	# **'A strada sta d''a parte d''o centro d''o vicolo.** Le bancarelle
	# stanno appoggiate a tutt'e due le facciate, e mettere la telecamera
	# sempre a +X vuol dire finire dentro al palazzo una volta su due —
	# **l'ho fatto tre volte in questa versione**, e tre volte la
	# fotografia era un muro. Qui il verso non si sceglie: si calcola.
	# Il centro del vicolo sta a `width / 2` in locale; da che parte cade
	# la cassa lo dice la sua x locale.
	var verso: float = 1.0 if cascia.position.x < w * 0.5 else -1.0
	_mira(q + Vector3(2.4 * verso, 1.30, 0.9), q + Vector3(0.0, 0.50, 0.0))


func _guarda_dint_ô_vascio() -> void:
	var v := get_tree().get_first_node_in_group("vascio")
	if v == null:
		print("  NUN CE STA 'O VASCIO")
		return
	var d: Node = v.get_node_or_null("Dentro")
	if d == null:
		print("  'O VASCIO NUN TENE 'O DINTO")
		return
	var p: Vector3 = (d as Node3D).global_position
	print("  vascio truvato a %s" % str(p.round()))
	# **Dint'â stanza, no dint'ô muro.** 'A primma inquadratura steva a
	# (-2,7 · 2,1) e mezza fotografia asceva marrone: 'a telecamera steva
	# appiccicata ô muro 'e ponente (MURO_X = 3,11) e 'o campo visivo se
	# pigliava 'o muro stesso. Mo' sta 'n miezo â stanza e guarda 'a tavula.
	_mira(p + Vector3(1.55, 1.78, -1.30), p + Vector3(-1.05, 0.88, 1.62))


# ---------------------------------------------------------------------------

func _truova_pe_nomme(nome: String) -> Node3D:
	for n in _tutte(get_tree().root):
		if n is Node3D and str(n.name).begins_with(nome):
			return n
	return null


## **'O vicolo se chiamma "ZoneVicolo", no "Zona".** 'A primma vota avevo
## cercato "zona" pecché 'o file se chiamma `zone_vicolo_3d.gd` — e 'a prova
## ha stampato NUN CE STANNO VICULE e ha scattato 'a stessa fotografia 'e
## primma senza lamentarse. 'O nomme s'è ghiuto a liggere addó se scrive
## (`citta_3d.gd`: `_piazza.name = "ZoneVicolo"`), no a mmemoria.
func _truova_zona() -> Node3D:
	for n in _tutte(get_tree().root):
		if n is Node3D and n.get("width") != null and n.get("length") != null:
			return n
	return null


func _tutte(n: Node) -> Array:
	var fore: Array = [n]
	for c in n.get_children():
		fore.append_array(_tutte(c))
	return fore


func _mira(occhio: Vector3, meta: Vector3) -> void:
	_cam.look_at_from_position(occhio, meta, Vector3.UP)
	_cam.current = true


func _scatta(nome: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/58_%s.png" % nome)
	print("  foto: /tmp/58_%s.png" % nome)
