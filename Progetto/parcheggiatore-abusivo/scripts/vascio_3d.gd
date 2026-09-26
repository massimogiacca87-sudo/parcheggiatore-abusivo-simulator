extends Node3D
## Vascio3D — 'a casa
##
## **Perché questa è la cosa più importante della 0.44.**
##
## Fino a ieri il gioco raccontava un uomo che lavora per la famiglia e non
## faceva vedere nessuno. La frase del tutorial — *"i soldi che servono a
## sfamare la tua famiglia"* — era una didascalia: nel gioco quella famiglia
## non esisteva, e i soldi non li chiedeva mai nessuno.
##
## Adesso c'è un posto dove tornare. Un vascio vero: stanza sola, porta che
## dà sul vicolo, letto in un angolo, tavola contro il muro, e dentro una moglie
## che aspetta i soldi e due criature che giocano per terra. Non si vede
## mai il resto della città da qui — ed è giusto: 'o vascio è un dentro.
##
## ## Come è fatto, e perché così
##
## Sono **due pezzi separati**:
##
## 1. **'A porta**, che sta nel vicolo dietro alla piazza, a quarantatré
##    metri dal posto dove lavori. È una porta bassa con la tendina, il
##    numero civico e i panni stesi sopra — si riconosce da lontano.
## 2. **'O dintro**, che è una stanza costruita a trecento metri da tutto,
##    fuori dalla pianta. Entrare è un teletrasporto con una sfumata al
##    nero, non una porta che si apre: costa niente in prestazioni, non
##    buca la facciata, e soprattutto non si vede la strada dalle finestre
##    di una casa che sta dentro a un isolato pieno.
##
## Il player, mentre sta dentro, ha i controlli di sempre: si cammina, si
## guarda, si preme E. Cambia solo che il rumore della strada si sente da
## lontano (`SoundManager.ambiente(0.22)`) — ed è quel dettaglio, più delle
## pareti, a far sentire che sei dentro.

const Tex := preload("res://scripts/textures.gd")
const Human := preload("res://scripts/human_builder.gd")
const Models := preload("res://scripts/models.gd")
const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const PannelloCasa := preload("res://scripts/pannello_casa.gd")

const LAYER_WORLD := 1
const LAYER_CAR := 4   # lo stesso su cui pesca il raggio dell'interazione

## Dove sta la porta, nel vicolo dietro alla piazza. Il muro è la faccia est
## dell'isolato [13,67]→[26,74]; la porta guarda dentro al vicolo, cioè +X.
const PORTA_POS := Vector3(26.15, 0.0, 72.4)
const PORTA_ROT: float = PI * 0.5   # guarda verso +X

## Dove sta la stanza. Fuori dalla pianta, e fuori pure dal golfo: qui non
## arriva nessuno per sbaglio.
const DENTRO := Vector3(300.0, 0.0, 300.0)
const LARG: float = 6.4     # la stanza, in metri
const PROF: float = 5.2
const ALT: float = 2.62     # basso: è un vascio, non un attico


## **'A stanza sta 'a fore d''a pianta, ma nun sta 'a fore d''o munno** (0.59).
##
## Trecento metri fuori dalla città c'è ancora scenografia: i palazzi finti
## del golfo arrivano fin là, e uno ci stava **piantato in mezzo alla
## stanza** — da dentro casa si vedeva una parete grigia che tagliava il
## tavolo a metà. Chi mette roba lontana chiede qui se tocca la stanza
## (`p` è il centro sul piano, `r` quanto è largo il pezzo).
static func tocca_a_stanza(p: Vector2, r: float, margine: float = 2.0) -> bool:
	return absf(p.x - DENTRO.x) < LARG * 0.5 + margine + r \
		and absf(p.y - DENTRO.z) < PROF * 0.5 + margine + r

## **Addò stanno 'e mobile, scritto 'na vota sola** (0.58).
##
## Queste tre righe erano numeri sparsi dentro alle funzioni che
## costruiscono i mobili, e ci sono finite qui per una ragione precisa: la
## prima volta che ho appoggiato un piatto sul tavolo ho **scritto a mano**
## delle coordinate che sembravano giuste, e la fotografia ha mostrato il
## piatto mezzo metro fuori dal tavolo, a mezz'aria, e la sveglia dall'altra
## parte della stanza rispetto al comò.
##
## Non era distrazione: è che il tavolo sta a (-1,05 · 1,62) e io stavo
## ricordandomi un tavolo che non esiste. **Una posizione scritta due volte
## è una posizione che prima o poi diverge**, ed è la stessa famiglia del
## campetto della 0.56 e della porta del garage della 0.57.
##
## Adesso il tavolo sta scritto una volta, e il piatto sa dove appoggiarsi.
const TAVULA := Vector3(-1.05, 0.0, 1.62)
const TAVULA_NCOPPA: float = 0.815        # 'o piano, cu 'a tuvaglia
const COMO_PROF: float = 0.50
const COMO := Vector3(-MURO_X + COMO_PROF * 0.5, 0.0, 1.72)
const COMO_NCOPPA: float = 0.933
const TIVU := Vector3(MURO_X - 0.36, 0.0, 0.28)

var _porta: StaticBody3D
var _dentro_nodo: Node3D
var _moglie: Node3D = null
var _moglie_bolla: Node3D = null
var _criature: Array = []
var _pannello: CanvasLayer = null
var _ritorno: Vector3 = Vector3.ZERO
var _ritorno_rot: float = 0.0
var _luci: Array = []


func _ready() -> void:
	name = "Vascio"
	add_to_group("vascio")
	_costruisci_porta()
	_costruisci_dentro()
	GameManager.rientro_forzato_segnale.connect(_su_rientro_forzato)


# ---------------------------------------------------------------------------
# 'A porta ncopp''o vicolo
# ---------------------------------------------------------------------------

func _costruisci_porta() -> void:
	var p := StaticBody3D.new()
	p.name = "PortaCasa"
	p.position = PORTA_POS
	p.rotation.y = PORTA_ROT
	p.collision_layer = LAYER_CAR
	p.collision_mask = 0
	p.set_script(preload("res://scripts/porta_casa.gd"))
	p.vascio = self
	add_child(p)
	_porta = p

	# Il collider dell'interazione: una lastra davanti alla porta. Non fa
	# da muro (il muro dell'isolato c'è già): serve solo a farsi trovare
	# dal raggio.
	var col := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	# Fondo novanta centimetri e non trenta: davanti a un basso c'e'
	# sempre appoggiato qualcosa — un motorino, una cassetta — e con il
	# collider incollato al muro il raggio dell'interazione trovava prima
	# il motorino e la porta non si apriva mai.
	bx.size = Vector3(1.5, 2.3, 0.9)
	col.shape = bx
	col.position = Vector3(0, 1.15, 0.35)
	p.add_child(col)

	# Lo stipite: due montanti e l'architrave di piperno, come le porte
	# vere dei bassi.
	var piperno := Tex.flat(Color(0.30, 0.30, 0.32), 0.85)
	for s in [-1.0, 1.0]:
		_box(p, Vector3(0.16, 2.15, 0.14), Vector3(s * 0.78, 1.075, 0.0), piperno)
	_box(p, Vector3(1.72, 0.18, 0.14), Vector3(0.0, 2.24, 0.0), piperno)

	# Il vano scuro dietro, e la tendina a strisce che lo copre a metà.
	_box(p, Vector3(1.44, 2.15, 0.06), Vector3(0.0, 1.075, -0.12),
		Tex.flat(Color(0.05, 0.045, 0.05), 1.0))
	var strisce := [Color(0.86, 0.84, 0.78), Color(0.72, 0.20, 0.18),
		Color(0.86, 0.84, 0.78), Color(0.20, 0.38, 0.62),
		Color(0.86, 0.84, 0.78), Color(0.72, 0.20, 0.18)]
	for i in range(strisce.size()):
		var x: float = -0.60 + float(i) * 0.24
		# Le strisce non sono tutte lunghe uguali: una tendina vera è
		# sfilacciata, e sono i tre centimetri di differenza a farla
		# leggere come stoffa invece che come una griglia.
		var h: float = 1.34 + randf_range(-0.06, 0.05)
		_box(p, Vector3(0.22, h, 0.02), Vector3(x, 2.15 - h * 0.5, -0.08),
			Tex.flat(strisce[i], 0.95))

	# 'O numero civico, sopra all'architrave.
	var num := Label3D.new()
	num.text = "27"
	num.font_size = 96
	num.pixel_size = 0.0022
	num.modulate = Color(0.92, 0.90, 0.84)
	num.outline_size = 14
	num.outline_modulate = Color(0.10, 0.10, 0.12)
	num.position = Vector3(0.0, 2.46, 0.02)
	num.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	p.add_child(num)

	# 'E panne stise: due fili sopra la porta con i panni appesi. È il
	# dettaglio che dice "ci abita qualcuno" prima di qualunque scritta.
	_panni_stesi(p)

	# **'O nome sopra 'a porta.** I panni stesi e il numero civico dicono
	# "ci abita qualcuno"; non dicono "ci abiti TU". Serve una scritta che
	# si legga da in fondo al vicolo — perché il vicolo è lungo
	# centodieci metri e la porta è alta due.
	var targa := Label3D.new()
	targa.text = "'O VASCIO TUOIO"
	targa.font_size = 34
	targa.pixel_size = 0.0042
	targa.modulate = Color(1.0, 0.80, 0.36)
	targa.outline_size = 12
	targa.outline_modulate = Color(0.08, 0.07, 0.06)
	targa.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	targa.no_depth_test = true
	targa.position = Vector3(0.0, 3.9, 0.6)
	p.add_child(targa)

	# La luce dentro al vano, che di notte si accende: da fuori la casa si
	# capisce che c'è qualcuno sveglio che ti aspetta.
	var lum := OmniLight3D.new()
	lum.light_color = Color(1.0, 0.80, 0.52)
	lum.light_energy = 0.9
	lum.omni_range = 3.2
	lum.position = Vector3(0.0, 1.5, -0.3)
	lum.shadow_enabled = false
	p.add_child(lum)
	var ciclo := get_tree().get_first_node_in_group("ciclo_giorno")
	if ciclo != null and ciclo.has_method("aggiungi_notturno"):
		ciclo.aggiungi_notturno(lum)


func _panni_stesi(sotto: Node3D) -> void:
	var filo := Tex.flat(Color(0.75, 0.72, 0.64), 1.0)
	var colori := [Color(0.90, 0.88, 0.84), Color(0.55, 0.68, 0.80),
		Color(0.86, 0.52, 0.44), Color(0.90, 0.88, 0.84),
		Color(0.42, 0.52, 0.40), Color(0.88, 0.78, 0.46)]
	for riga in range(2):
		var y: float = 2.95 + float(riga) * 0.62
		_box(sotto, Vector3(3.2, 0.02, 0.02), Vector3(0.0, y, -0.05 - riga * 0.3),
			filo)
		var n: int = 4 + riga
		for i in range(n):
			var x: float = -1.3 + float(i) * (2.6 / float(n - 1))
			var w: float = randf_range(0.30, 0.48)
			var h: float = randf_range(0.34, 0.66)
			var c: Color = colori[(i + riga * 3) % colori.size()]
			_box(sotto, Vector3(w, h, 0.012),
				Vector3(x, y - h * 0.5 - 0.02, -0.05 - riga * 0.3),
				Tex.flat(c, 0.98))


# ---------------------------------------------------------------------------
# 'O dintro
# ---------------------------------------------------------------------------

func _costruisci_dentro() -> void:
	var r := Node3D.new()
	r.name = "Dentro"
	r.position = DENTRO
	add_child(r)
	_dentro_nodo = r

	var mezzo_x := LARG * 0.5
	var mezzo_z := PROF * 0.5

	# Pavimento: le mattonelle di graniglia napoletane, a scacchi.
	var pav := StaticBody3D.new()
	pav.collision_layer = LAYER_WORLD
	r.add_child(pav)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(LARG, 0.3, PROF)
	cs.shape = bs
	cs.position = Vector3(0, -0.15, 0)
	pav.add_child(cs)
	_mattonelle(r)

	# Muri e soffitto. Il soffitto serve davvero: senza, la luce del sole
	# entra dall'alto e la stanza sembra un cortile.
	var muro := Tex.flat(Color(0.80, 0.76, 0.66), 0.96)
	var muro_basso := Tex.flat(Color(0.42, 0.52, 0.50), 0.92) # 'a zoccolatura
	for lato in range(4):
		var lung: float = LARG if lato < 2 else PROF
		var pos: Vector3
		var siz: Vector3
		if lato < 2:
			var s: float = -1.0 if lato == 0 else 1.0
			pos = Vector3(0, ALT * 0.5, s * mezzo_z)
			siz = Vector3(lung, ALT, 0.18)
		else:
			var s2: float = -1.0 if lato == 2 else 1.0
			pos = Vector3(s2 * mezzo_x, ALT * 0.5, 0)
			siz = Vector3(0.18, ALT, lung)
		_muro_solido(r, siz, pos, muro)
		# **'O muro se ne saglie n'atu metro, ma sulo 'o collider.**
		# Vedi la nota sul soffitto qui sotto: la scatola va chiusa anche
		# sopra la linea del soffitto, se no restano venti centimetri di
		# spiraglio fra il bordo del muro e la lastra.
		_solido(r, Vector3(siz.x, 1.2, siz.z),
			Vector3(pos.x, ALT + 0.6, pos.z))
		# La fascia dipinta in basso, alta un metro: sta in tutti i bassi,
		# e serve a non far vedere lo sporco sul muro bianco.
		var siz_b := Vector3(siz.x, 1.0, siz.z)
		if lato < 2:
			siz_b = Vector3(lung - 0.02, 1.0, 0.02)
			_box(r, siz_b, Vector3(0, 0.5, pos.z + (0.1 if lato == 0 else -0.1)),
				muro_basso)
		else:
			siz_b = Vector3(0.02, 1.0, lung - 0.02)
			_box(r, siz_b, Vector3(pos.x + (0.1 if lato == 2 else -0.1), 0.5, 0),
				muro_basso)
	# **'O soffitto mo' ferma pure.**
	#
	# Era una lastra da guardare e basta, senza collisione — e la stanza
	# era una **scatola senza coperchio**. Il conto è questo: l'armadio è
	# alto 2,06 e ha il suo collider, quindi ci si sale sopra; da lì un
	# salto arriva a quasi tre metri; il muro è alto 2,62. Si scavalca, e
	# ci si ritrova fuori dalla stanza a guardarla da fuori — che è
	# esattamente la foto che ha mandato il capo.
	#
	# Il raggio verso l'alto di `tools/prova_muri_casa.gd` lo diceva chiaro
	# la prima volta che l'ho lanciato: *"soffitto → NIENTE (si esce 'a
	# coppa)"*. Le quattro pareti erano tutte a posto: mancava il tetto.
	_box(r, Vector3(LARG, 0.16, PROF), Vector3(0, ALT + 0.08, 0),
		Tex.flat(Color(0.86, 0.84, 0.80), 0.98))
	_solido(r, Vector3(LARG, 0.16, PROF), Vector3(0, ALT + 0.08, 0))

	_arredo(r)
	_luce_dentro(r)
	_uscita(r)
	_moglie_e_criature(r)
	_letto(r)


func _mattonelle(sotto: Node3D) -> void:
	# Due materiali alternati, un MultiMesh per ognuno: 96 mattonelle e due
	# sole chiamate di disegno.
	var chiaro := Tex.flat(Color(0.78, 0.74, 0.66), 0.7)
	var scuro := Tex.flat(Color(0.44, 0.40, 0.36), 0.7)
	var lato := 0.4
	var nx := int(LARG / lato)
	var nz := int(PROF / lato)
	for parita in range(2):
		var mesh := BoxMesh.new()
		mesh.size = Vector3(lato * 0.97, 0.02, lato * 0.97)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		var punti: Array = []
		for ix in range(nx):
			for iz in range(nz):
				if (ix + iz) % 2 != parita:
					continue
				punti.append(Vector3(
					-LARG * 0.5 + lato * (float(ix) + 0.5),
					0.011,
					-PROF * 0.5 + lato * (float(iz) + 0.5)))
		mm.instance_count = punti.size()
		for i in range(punti.size()):
			mm.set_instance_transform(i, Transform3D(Basis(), punti[i]))
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = chiaro if parita == 0 else scuro
		sotto.add_child(mi)


## L'arredo d''o vascio.
##
## **Rifatto da capo alla 0.45**, dopo la segnalazione: *"c'è qualcosa in
## casa che non si capisce cos'è ed è attraversabile"*. Aprendo le foto
## dell'interno i difetti erano tre, e tutti e tre della stessa famiglia —
## roba costruita a occhio invece che misurata:
##
## 1. **Mobili appesi al niente.** Il pensile della cucina e il crocifisso
##    stavano a ventitré centimetri dal muro, sospesi in aria. Un
##    parallelepipedo marrone che galleggia a un metro e settanta, visto di
##    taglio, non è un pensile: è un affare che non si capisce, e ci si
##    cammina dentro. Adesso il muro sta a `MURO_X` / `MURO_Z` e ogni pezzo
##    si appoggia **partendo da lì**, non da un numero scritto a mano.
## 2. **'A televisione stava dentro 'o letto.** Le due posizioni erano
##    calcolate ognuna per conto suo e si sovrapponevano per mezzo metro.
##    Non si vedeva perché il letto la copriva quasi tutta.
## 3. **Niente colliders.** Sedie, pensile, piatti: tutta roba che si
##    attraversa camminando. Adesso quello che è solido ferma.
##
## E già che c'era la stanza si è riempita di cose che si riconoscono a
## colpo d'occhio — 'o frigorifero, 'o stipo, 'o quadro d''o mare, 'o
## calendario — perché una stanza con quattro mobili sembra una demo, e un
## vascio vero è pieno fino al soffitto.

## Le facce interne dei muri. Tutto quello che sta appoggiato al muro parte
## da qui: è il numero che prima non c'era, e la sua mancanza è il motivo
## per cui mezzo arredo galleggiava.
const MURO_X: float = LARG * 0.5 - 0.09    # 0.18 di spessore, metà per lato
const MURO_Z: float = PROF * 0.5 - 0.09


func _arredo(r: Node3D) -> void:
	var legno := Tex.flat(Color(0.36, 0.24, 0.16), 0.72)
	var legno_chiaro := Tex.flat(Color(0.55, 0.40, 0.26), 0.74)
	var formica := Tex.flat(Color(0.80, 0.78, 0.70), 0.5)
	var metallo := Tex.flat(Color(0.62, 0.63, 0.65), 0.35, 0.7)

	_cucina(r, legno, metallo)
	_frigorifero(r, metallo)
	_como(r, legno, metallo)
	_armadio(r, legno, legno_chiaro, metallo)
	_tavula(r, formica, metallo, legno_chiaro)
	_televisione(r, legno, metallo)
	_appise(r, legno)
	_ventilatore(r, legno_chiaro, metallo)
	_robba_d_a_casa(r)
	_robba_nova(r)


# ---------------------------------------------------------------------------
# 'A ROBBA 'E CASA (0.58)
# ---------------------------------------------------------------------------
#
# Il vascio aveva i mobili e non aveva **le cose sopra ai mobili**, ed è
# quella la differenza fra una stanza arredata e una stanza dove abita
# qualcuno. Un tavolo vuoto è un modello 3D; un tavolo con due piatti e una
# forchetta è una cena di ieri sera.
#
# Diciassette pezzi dal pacchetto PSX, e nessuno di loro fa niente: non si
# raccolgono, non si usano, non danno soldi. Stanno lì perché è casa tua, e
# perché ci entri due volte al giorno per tutta la partita.
#
# **'E coordinate songo d''a stanza**, che sta a (300, 0, 300) fuori dalla
# pianta: si scrivono relative a `r`, il nodo della stanza, e non in
# coordinate del mondo. È la trappola che alla 0.56 ha piantato la porta
# del campetto diciassette metri più in là — coordinate locali lette come
# coordinate del mondo — e qui ci si ricasca facilissimo perché la stanza è
# l'unica cosa del gioco che non sta dove si vede.
func _robba_d_a_casa(r: Node3D) -> void:
	# 'O tavulo: 1,50 × 0,95, 'o centro a TAVULA, 'o piano a TAVULA_NCOPPA.
	var t: Vector3 = TAVULA
	var y: float = TAVULA_NCOPPA
	# 'O comò: largo 1,10 ncopp'a Z, 'o piano a COMO_NCOPPA.
	var c: Vector3 = COMO
	var yc: float = COMO_NCOPPA
	for e in [
			# --- ncopp'â tavula (dint'a 0,70 × 0,42 d''o centro) ---
			["piatto", t + Vector3(-0.34, y, -0.16), Vector3(0, 12, 0)],
			["furchetta", t + Vector3(-0.09, y, -0.20), Vector3(0, 84, 0)],
			["cucchiaro", t + Vector3(-0.09, y, -0.06), Vector3(0, 96, 0)],
			["libro_apierto", t + Vector3(0.34, y, 0.14), Vector3(0, -22, 0)],
			["matita", t + Vector3(0.20, y, 0.32), Vector3(0, 40, 0)],
			# --- ncopp'ô comò (dint'a 0,18 × 0,46 d''o centro) ---
			["sveglia", c + Vector3(0.0, yc, -0.40), Vector3(0, -34, 0)],
			["abbajour", c + Vector3(0.0, yc, 0.40), Vector3(0, 20, 0)],
			["posacenere", c + Vector3(0.06, yc, -0.14), Vector3(0, 6, 0)],
			["musicassetta", c + Vector3(-0.06, yc, 0.12), Vector3(0, 62, 0)],
			["chiave2", c + Vector3(0.10, yc, -0.02), Vector3(0, 18, 0)],
			["mazzetta2", c + Vector3(-0.08, yc, 0.24), Vector3(0, -26, 0)],
			["telefonino_viecchio", c + Vector3(0.08, yc, 0.02),
				Vector3(0, 48, 0)],
			# --- attuorno â televisione (TIVU, 'o mobile è viso ê 0,36) ---
			["telecomando", TIVU + Vector3(-0.22, 0.88, -0.30),
				Vector3(0, 74, 0)],
			["libro3", TIVU + Vector3(-0.20, 0.87, 0.34), Vector3(0, -14, 0)],
			# --- appise ô muro: 'o quadro sta a MURO_Z, 'a croce a MURO_X ---
			["quadro", Vector3(-0.70, 1.58, MURO_Z - 0.06), Vector3(0, 0, 0)],
			["orologio_muro", Vector3(-MURO_X + 0.06, 1.94, 0.40),
				Vector3(0, 90, 0)],
			["croce2", Vector3(MURO_X - 0.06, 1.90, -1.30), Vector3(0, -90, 0)],
			# --- 'nterra, 'n coppa ê cantune ---
			["tappeto", Vector3(0.10, 0.02, 0.60), Vector3(0, 8, 0)],
			["scatolone", Vector3(MURO_X - 0.45, 0.0, MURO_Z - 0.55),
				Vector3(0, 28, 0)],
			["cascia_legno6", Vector3(-MURO_X + 0.55, 0.0, -MURO_Z + 0.60),
				Vector3(0, -18, 0)],
			# --- appise ô soffitto ---
			# 'O lampadario sta addó sta 'a lampadina (-0,6 · 0,9): nun s''a
			# leva, 'a veste. E chille "stutate" nun so' 'nu doppione: songo
			# 'e ddoje luce ca dint'a 'nu vascio nun se appicciano maje.
			["lampadario", Vector3(-0.60, ALT - 0.14, 0.90), Vector3(0, 0, 0)],
			["lampadario_stutato", Vector3(1.60, ALT - 0.14, 1.60),
				Vector3(0, 38, 0)],
			["abbajour_stutato", Vector3(-MURO_X + 0.30, 1.30, -1.80),
				Vector3(0, 64, 0)],
		]:
		var n := Models.spawn(str(e[0]))
		if n == null:
			continue
		n.position = e[1]
		var g: Vector3 = e[2]
		n.rotation = Vector3(deg_to_rad(g.x), deg_to_rad(g.y), deg_to_rad(g.z))
		r.add_child(n)


## **'A robba nova** (0.59): il pacchetto Pandazole dentro casa.
##
## Non sostituisce niente: i mobili fatti a mano restano (hanno i loro
## corpi, le loro misure e le prove che li controllano), e il pacchetto
## riempie **i posti vuoti** — che in un basso sono pochi, ed è giusto così.
## La culla per il piccolo contro il muro di mezzogiorno, il comodino con
## l'abat-jour e il telefono di casa accanto al letto, lo specchio sopra al
## comò, la damigiana nell'angolo della cucina, la cassetta del pronto
## soccorso appesa al muro. Sul fornello libero la pentola del ragù, sul
## piano l'olio e la pasta; sulla tavola il pane, il formaggio, il latte,
## le polpette e la teglia di lasagna della domenica. Per terra, vicino ai
## figli, il trenino e la macchinina (i "machinelle" che il commento qui
## sotto prometteva e non c'erano) e il pallone vero al posto della sfera.
##
## Coordinate della stanza, come tutto il resto qui dentro (vedi la nota
## in testa a `_robba_d_a_casa`). Il davanti dei pezzi è il loro +Z.
func _robba_nova(r: Node3D) -> void:
	if not Models.has_model("culla"):
		return
	var t: Vector3 = TAVULA
	var y: float = TAVULA_NCOPPA
	for e in [
			# --- ncopp'ô fuoco libero e ncopp'ô piano d''a cucina ---
			["pentola_2", Vector3(-MURO_X + 0.31, 0.975, -1.84), 20.0],
			["olio", Vector3(-MURO_X + 0.10, 0.93, -1.30), 0.0],
			["pasta_pacco", Vector3(-MURO_X + 0.12, 0.93, -1.62), 80.0],
			# --- ncopp'â tavula (ll'angoli liberi) ---
			["polpette", t + Vector3(-0.53, y, 0.31), 0.0],
			["lasagna", t + Vector3(0.60, y, 0.33), 12.0],
			["pane", t + Vector3(0.60, y, -0.29), 70.0],
			["formaggio", t + Vector3(-0.30, y, -0.38), -20.0],
			["latte", t + Vector3(-0.65, y, -0.34), 0.0],
			["uovo", t + Vector3(-0.52, y, -0.36), 0.0],
			# --- 'o comodino, 'a lampada e 'o telefono 'e casa ---
			["comodino", Vector3(1.07, 0.0, -MURO_Z + 0.30), 0.0],
			["lampada", Vector3(0.96, 0.56, -MURO_Z + 0.26), 0.0],
			["telefono", Vector3(1.23, 0.56, -MURO_Z + 0.43), -15.0],
			# --- appise ô muro ---
			["specchio", Vector3(-MURO_X + 0.03, 1.12, COMO.z), 90.0],
			["cassetta_soccorso", Vector3(0.25, 1.45, -MURO_Z + 0.07), 0.0],
			# --- 'nterra ---
			["culla", Vector3(1.0, 0.0, MURO_Z - 0.42), 90.0],
			["orsacchiotto", Vector3(1.78, 0.0, MURO_Z - 0.30), -30.0],
			["damigiana", Vector3(-2.22, 0.0, -MURO_Z + 0.24), 0.0],
			["pianta_casa_5", Vector3(-0.05, 0.0, -MURO_Z + 0.26), 30.0],
			# --- 'a pentola grossa ncopp'ô frigorifero, addó sta sempe ---
			["pentola_1", Vector3(-MURO_X + 0.30, 1.58, 0.30), -10.0],
			# --- 'a mensola sopra â televisione, cu 'a piantella ---
			["mensola", Vector3(MURO_X - 0.10, 1.40, TIVU.z), -90.0],
			["pianta_casa_2", Vector3(MURO_X - 0.12, 1.81, TIVU.z + 0.12), 0.0],
			["trenino", Vector3(-0.15, 0.0, -0.95), 35.0],
			["macchinina", Vector3(0.20, 0.0, -0.80), -60.0],
			# --- 'a robba d''a 0.60 (PSX) ---
			# 'O giochetto elettronico d''o grande, lassato 'nterra vicino
			# ê giocattoli d''o piccerillo.
			["giochetto", Vector3(0.45, 0.0, -1.22), 25.0],
			# 'O quaderno d''e cumpite ncopp'ô lietto, e 'o cuscino 'e
			# riserva ai piedi.
			["quaderno", Vector3(1.75, 0.675, -1.15), -12.0],
			["cuscino", Vector3(2.10, 0.675, -0.45), 90.0],
			# 'A presa sotto â televisione e 'o 'nterruttore vicino â porta.
			["presa_muro", Vector3(MURO_X - 0.005, 0.32, -0.9), -90.0],
			["interruttore2", Vector3(MURO_X - 0.005, 1.12, 0.78), -90.0],
			# 'A fotografia d''o cane ncopp'â mensola, vicino â piantella.
			["cornice_cane", Vector3(MURO_X - 0.14, 1.81, TIVU.z - 0.16), -90.0],
			# 'A ragnatela int'ô cantone 'e coppa: dint'a 'nu vascio ce sta
			# sempe.
			["ragnatela2", Vector3(-MURO_X + 0.01, ALT - 0.01, -MURO_Z + 0.01), 0.0],
		]:
		var n := Models.spawn(str(e[0]))
		if n == null:
			continue
		n.position = e[1]
		n.rotation.y = deg_to_rad(float(e[2]))
		r.add_child(n)
	# 'A padella appesa al muro sopra al fornello, col manico di lato: il
	# fondo verso la stanza (la Y della mesh va su +X), il manico lungo il
	# muro (la X della mesh va su +Z). Fra il piano (0,93) e il pensile
	# (1,40) ci stanno quarantasette centimetri: col manico in su non
	# c'entrava.
	var padella := Models.spawn("padella")
	if padella != null:
		padella.basis = Basis(Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0))
		padella.position = Vector3(-MURO_X + 0.005, 1.16, -2.05)
		r.add_child(padella)
	# La culla e il comodino si sbattono, come tutti i mobili di casa.
	_solido(r, Vector3(1.19, 0.8, 0.74), Vector3(1.0, 0.4, MURO_Z - 0.42))
	_solido(r, Vector3(0.56, 0.58, 0.58), Vector3(1.07, 0.29, -MURO_Z + 0.30))


## --- 'A cucina: fornello, lavello, bombola, pensile. Muro di ponente,
## dalla parte del nord.
func _cucina(r: Node3D, legno: Material, metallo: Material) -> void:
	var prof: float = 0.62
	var cuc := Node3D.new()
	# `-MURO_X + prof*0.5` = la schiena tocca il muro. È la riga che prima
	# era un numero a occhio.
	cuc.position = Vector3(-MURO_X + prof * 0.5, 0.0, -1.40)
	r.add_child(cuc)

	# 'O bancone.
	_box(cuc, Vector3(prof, 0.88, 1.90), Vector3(0, 0.44, 0),
		Tex.flat(Color(0.68, 0.66, 0.60), 0.8))
	_box(cuc, Vector3(prof + 0.04, 0.05, 1.94), Vector3(0, 0.905, 0), metallo)
	_solido(cuc, Vector3(prof, 0.93, 1.90), Vector3(0, 0.465, 0))
	# Due ante e due maniglie, che se no è un cubo.
	for az in [-0.46, 0.46]:
		_box(cuc, Vector3(0.02, 0.62, 0.86), Vector3(prof * 0.5, 0.48, az),
			Tex.flat(Color(0.60, 0.58, 0.52), 0.8))
		_box(cuc, Vector3(0.03, 0.03, 0.16),
			Vector3(prof * 0.5 + 0.02, 0.70, az), metallo)

	# 'O lavello, incassato nel piano.
	_box(cuc, Vector3(0.44, 0.02, 0.52), Vector3(0, 0.90, 0.52),
		Tex.flat(Color(0.52, 0.53, 0.55), 0.3, 0.8))
	_box(cuc, Vector3(0.40, 0.10, 0.48), Vector3(0, 0.855, 0.52),
		Tex.flat(Color(0.46, 0.47, 0.49), 0.3, 0.8))
	# 'O rubinetto.
	_cilindro(cuc, 0.014, 0.26, Vector3(-0.20, 1.06, 0.52), metallo)
	_box(cuc, Vector3(0.16, 0.02, 0.02), Vector3(-0.13, 1.18, 0.52), metallo)

	# 'O fornello a due fuochi e 'a cuccumella ncoppa.
	_box(cuc, Vector3(0.44, 0.03, 0.46), Vector3(0, 0.945, -0.55), metallo)
	for fz in [-0.66, -0.44]:
		_cilindro(cuc, 0.07, 0.02, Vector3(0, 0.965, fz),
			Tex.flat(Color(0.16, 0.16, 0.17), 0.6))
	_caffettiera(cuc, Vector3(0, 0.975, -0.66))

	# 'A bombola d''o gas: nel gioco è pure una voce del bilancio, quindi
	# si deve vedere che sta lì.
	_cilindro(cuc, 0.14, 0.52, Vector3(0.06, 0.26, 0.86),
		Tex.flat(Color(0.86, 0.62, 0.20), 0.55, 0.3))
	_cilindro(cuc, 0.05, 0.10, Vector3(0.06, 0.56, 0.86), metallo)
	_solido(cuc, Vector3(0.28, 0.62, 0.28), Vector3(0.06, 0.31, 0.86))

	# --- 'O pensile. **Attaccato al muro**, non sospeso a mezz'aria.
	var pens_prof: float = 0.32
	var pens := Node3D.new()
	pens.position = Vector3(-MURO_X + pens_prof * 0.5 - cuc.position.x, 0.0, -0.2)
	cuc.add_child(pens)
	_box(pens, Vector3(pens_prof, 0.64, 1.30), Vector3(0, 1.72, 0), legno)
	_solido(pens, Vector3(pens_prof, 0.64, 1.30), Vector3(0, 1.72, 0))
	for az2 in [-0.32, 0.32]:
		_box(pens, Vector3(0.02, 0.56, 0.58),
			Vector3(pens_prof * 0.5, 1.72, az2),
			Tex.flat(Color(0.44, 0.30, 0.20), 0.7))
		_box(pens, Vector3(0.03, 0.03, 0.12),
			Vector3(pens_prof * 0.5 + 0.02, 1.60, az2), metallo)

	# 'E piatte, appoggiate **sul piano** (0.93), non a otto centimetri
	# sopra come stavano prima.
	for i in range(5):
		_cilindro(cuc, 0.10, 0.014,
			Vector3(0.10, 0.945 + float(i) * 0.016, -0.05),
			Tex.flat(Color(0.90, 0.88, 0.84), 0.4))


## --- 'O frigorifero. Muro di ponente, in mezzo. È il mobile che in una
## stanza si riconosce da lontano più di tutti, e non ce n'era uno.
func _frigorifero(r: Node3D, metallo: Material) -> void:
	var prof: float = 0.60
	var f := Node3D.new()
	f.position = Vector3(-MURO_X + prof * 0.5, 0.0, 0.30)
	r.add_child(f)
	var smalto := Tex.flat(Color(0.88, 0.87, 0.83), 0.35, 0.2)
	_box(f, Vector3(prof, 1.56, 0.62), Vector3(0, 0.78, 0), smalto)
	_solido(f, Vector3(prof, 1.58, 0.62), Vector3(0, 0.79, 0))
	# Lo sportellino del congelatore sopra, e la fessura fra i due.
	_box(f, Vector3(0.02, 0.01, 0.62), Vector3(prof * 0.5, 1.16, 0),
		Tex.flat(Color(0.52, 0.51, 0.48), 0.6))
	for my in [0.62, 1.30]:
		_box(f, Vector3(0.03, 0.24, 0.03), Vector3(prof * 0.5 + 0.02, my, 0.24),
			metallo)
	# 'E calamite: due bollini colorati, e si capisce subito che è un frigo.
	for cal in [[0.42, 0.96, Color(0.86, 0.24, 0.20)],
			[-0.22, 0.72, Color(0.94, 0.78, 0.24)],
			[0.18, 1.34, Color(0.28, 0.56, 0.86)]]:
		_box(f, Vector3(0.006, 0.06, 0.05),
			Vector3(prof * 0.5 + 0.004, float(cal[1]), float(cal[0])),
			Tex.flat(cal[2], 0.7))


## --- 'O comò cu 'a fotografia: l'angolo d''e ricorde. Muro di ponente,
## dalla parte del sud.
func _como(r: Node3D, legno: Material, metallo: Material) -> void:
	var prof: float = COMO_PROF
	var com := Node3D.new()
	com.position = COMO
	r.add_child(com)
	_box(com, Vector3(prof, 0.92, 1.10), Vector3(0, 0.46, 0), legno)
	_solido(com, Vector3(prof, 0.94, 1.10), Vector3(0, 0.47, 0))
	# Tre cassetti veri: un fronte più chiaro e la maniglia in mezzo.
	for i in range(3):
		var y: float = 0.16 + float(i) * 0.29
		_box(com, Vector3(0.02, 0.25, 1.02), Vector3(prof * 0.5, y, 0),
			Tex.flat(Color(0.44, 0.30, 0.20), 0.72))
		_box(com, Vector3(0.04, 0.03, 0.20), Vector3(prof * 0.5 + 0.02, y, 0),
			metallo)
	# 'O centrino, 'a cornice, 'o lumino: tutto **appoggiato** a 0.92.
	_box(com, Vector3(0.42, 0.006, 0.96), Vector3(0, 0.923, 0),
		Tex.flat(Color(0.94, 0.92, 0.88), 0.96))
	_cornice(com, Vector3(-0.02, 0.926, -0.32), 0.30, 0.24)
	_cornice(com, Vector3(0.02, 0.926, 0.30), 0.22, 0.18)
	var lum := Tex.flat(Color(0.86, 0.24, 0.20), 0.5)
	lum.emission_enabled = true
	lum.emission = Color(1.0, 0.42, 0.24)
	lum.emission_energy_multiplier = 1.6
	_cilindro(com, 0.035, 0.08, Vector3(0, 0.966, 0.02), lum)
	var lumino := OmniLight3D.new()
	lumino.light_color = Color(1.0, 0.52, 0.30)
	lumino.light_energy = 0.6
	lumino.omni_range = 1.6
	lumino.position = Vector3(0.0, 1.04, 0.02)
	lumino.shadow_enabled = false
	com.add_child(lumino)


## Una cornice in piedi: il piedino dietro la tiene su, se no è un
## rettangolo che sta ritto per miracolo.
func _cornice(sotto: Node3D, base: Vector3, alt: float, largo: float) -> void:
	var c := Node3D.new()
	c.position = base
	sotto.add_child(c)
	_box(c, Vector3(0.018, alt, largo),
		Vector3(0, alt * 0.5, 0), Tex.flat(Color(0.70, 0.58, 0.30), 0.5))
	_box(c, Vector3(0.008, alt - 0.06, largo - 0.05),
		Vector3(0.012, alt * 0.5, 0), Tex.flat(Color(0.62, 0.66, 0.70), 0.55))
	# 'O piedino.
	var p := _box(c, Vector3(0.012, alt * 0.7, 0.05),
		Vector3(-0.05, alt * 0.32, 0), Tex.flat(Color(0.52, 0.42, 0.24), 0.7))
	p.rotation.z = 0.34


## --- 'O stipo. Muro di tramontana. Un armadio grosso serve a due cose:
## si riconosce subito, e riempie la parete che restava vuota.
func _armadio(r: Node3D, legno: Material, legno_chiaro: Material,
		metallo: Material) -> void:
	var prof: float = 0.58
	var a := Node3D.new()
	a.position = Vector3(-1.15, 0.0, -MURO_Z + prof * 0.5)
	r.add_child(a)
	_box(a, Vector3(1.70, 2.06, prof), Vector3(0, 1.03, 0), legno)
	_solido(a, Vector3(1.70, 2.06, prof), Vector3(0, 1.03, 0))
	# Due ante, la fessura in mezzo, due maniglie, e la cornice sopra.
	for ax in [-0.42, 0.42]:
		_box(a, Vector3(0.78, 1.86, 0.02), Vector3(ax, 1.02, prof * 0.5),
			legno_chiaro)
		_box(a, Vector3(0.03, 0.20, 0.03),
			Vector3(ax + (0.30 if ax < 0.0 else -0.30), 1.06, prof * 0.5 + 0.02),
			metallo)
	_box(a, Vector3(1.78, 0.09, prof + 0.06), Vector3(0, 2.10, 0), legno_chiaro)
	# 'O specchio ncopp'a n'anta: un rettangolo chiaro, si capisce a vista.
	var vetro := Tex.flat(Color(0.70, 0.76, 0.78, 0.85), 0.12, 0.9)
	_box(a, Vector3(0.54, 1.30, 0.01), Vector3(-0.42, 1.16, prof * 0.5 + 0.012),
		vetro)
	# 'A valigia ncoppa: nei bassi sopra all'armadio ci sta sempre qualcosa.
	_box(a, Vector3(0.62, 0.20, 0.38), Vector3(0.42, 2.25, 0),
		Tex.flat(Color(0.30, 0.24, 0.20), 0.85))


## --- 'A tavula, in mezzo. È il centro della stanza e il posto dove si
## appoggiano 'e sorde.
func _tavula(r: Node3D, formica: Material, metallo: Material,
		legno_chiaro: Material) -> void:
	# **'A tavula steva mmiez'â stanza.**
	#
	# Il capo: "in mezzo alla casa c'è un oggetto in mezzo alla stanza". Era
	# questa: tavolo un metro e mezzo per uno, con quattro sedie attorno,
	# piazzato a (0.20, 0.55) — cioè **nel centro esatto** di una stanza di
	# 6,4 per 5,2, con il suo collisore. Entrando dalla porta ci sbattevi
	# contro prima di qualunque altra cosa, e la stanza non si poteva
	# attraversare in linea retta da nessuna parte.
	#
	# In un vascio vero la tavola sta **contro il muro**, e si tira fuori
	# solo per mangiare: lo spazio è quello che è. Spostata verso la parete
	# di mezzogiorno, accanto alla mugliera, con le sedie che la seguono.
	# Il centro della stanza adesso è quello che deve essere — vuoto.
	var tav := Node3D.new()
	tav.position = TAVULA
	r.add_child(tav)
	_box(tav, Vector3(1.50, 0.06, 0.95), Vector3(0, 0.76, 0), formica)
	_box(tav, Vector3(1.54, 0.04, 0.99), Vector3(0, 0.73, 0), metallo)
	for sx in [-0.66, 0.66]:
		for sz in [-0.38, 0.38]:
			_cilindro(tav, 0.022, 0.73, Vector3(sx, 0.365, sz), metallo)
	_solido(tav, Vector3(1.50, 0.79, 0.95), Vector3(0, 0.395, 0))
	# 'A tovaglia a quadretti, che sborda.
	_box(tav, Vector3(1.62, 0.012, 1.07), Vector3(0, 0.796, 0),
		Tex.flat(Color(0.80, 0.30, 0.26), 0.98))
	_box(tav, Vector3(1.30, 0.008, 0.80), Vector3(0, 0.805, 0),
		Tex.flat(Color(0.90, 0.86, 0.80), 0.98))
	# 'O piatto, 'a caraffa, 'o ppane, 'o bicchiere.
	_cilindro(tav, 0.11, 0.02, Vector3(-0.35, 0.819, 0),
		Tex.flat(Color(0.92, 0.90, 0.88), 0.4))
	_cilindro(tav, 0.07, 0.22, Vector3(0.30, 0.919, -0.16),
		Tex.flat(Color(0.72, 0.80, 0.78, 0.75), 0.2))
	_cilindro(tav, 0.035, 0.10, Vector3(0.10, 0.859, 0.24),
		Tex.flat(Color(0.78, 0.84, 0.82, 0.7), 0.2))
	_box(tav, Vector3(0.30, 0.10, 0.13), Vector3(0.24, 0.859, 0.22),
		Tex.flat(Color(0.72, 0.55, 0.30), 0.9))

	# Quattro sedie, una per lato. **Non più in cerchio**: in cerchio due
	# finivano dentro al letto e una addosso alla mugliera.
	# Tre sedie, non quattro: il quarto lato sta contro il muro.
	var posti := [
		[TAVULA + Vector3(0.0, 0.0, -0.85), 0.0],
		[TAVULA + Vector3(1.08, 0.0, 0.0), -PI * 0.5],
		[TAVULA + Vector3(-1.08, 0.0, 0.0), PI * 0.5],
	]
	for p in posti:
		_sedia(r, p[0] as Vector3, float(p[1]), legno_chiaro)


## --- 'A televisione, quella vecchia col tubo, ncopp'a nu carrellino.
##
## **Spostata.** Prima stava a (2.70, −1.30), cioè mezzo metro dentro al
## letto — due mobili nello stesso posto, e non si vedeva perché il letto
## la copriva. Adesso sta a sud del letto, che finisce a z = −0.20.
func _televisione(r: Node3D, legno: Material, metallo: Material) -> void:
	var tv := Node3D.new()
	tv.position = TIVU
	tv.rotation.y = -PI * 0.5
	r.add_child(tv)
	_box(tv, Vector3(0.70, 0.04, 0.46), Vector3(0, 0.62, 0), legno)
	_box(tv, Vector3(0.66, 0.03, 0.42), Vector3(0, 0.20, 0), legno)
	for sx in [-0.30, 0.30]:
		for sz in [-0.18, 0.18]:
			_cilindro(tv, 0.014, 0.62, Vector3(sx, 0.31, sz), metallo)
	for sx2 in [-0.30, 0.30]:
		_cilindro(tv, 0.035, 0.03, Vector3(sx2, 0.02, 0.18), metallo)
	# 'O mobile d''a tv: davanti stretto, dietro largo, come i tubi catodici.
	_box(tv, Vector3(0.62, 0.50, 0.42), Vector3(0, 0.89, -0.02),
		Tex.flat(Color(0.24, 0.22, 0.20), 0.65))
	_box(tv, Vector3(0.44, 0.34, 0.14), Vector3(0, 0.89, -0.26),
		Tex.flat(Color(0.20, 0.18, 0.17), 0.7))
	var schermo := Tex.flat(Color(0.30, 0.42, 0.46), 0.25)
	schermo.emission_enabled = true
	schermo.emission = Color(0.22, 0.36, 0.48)
	schermo.emission_energy_multiplier = 0.9
	_box(tv, Vector3(0.50, 0.38, 0.02), Vector3(0, 0.90, 0.20), schermo)
	# 'E manopole.
	for my in [0.70, 0.62]:
		_cilindro(tv, 0.018, 0.02, Vector3(0.24, my, 0.205), metallo)
	# 'E ccorna: due antenne a V che partono **dal mobile**, non dall'aria.
	for s in [-1.0, 1.0]:
		var a := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.004
		cm.bottom_radius = 0.007
		cm.height = 0.46
		a.mesh = cm
		a.material_override = metallo
		a.position = Vector3(s * 0.09, 1.34, -0.12)
		a.rotation.z = s * 0.42
		tv.add_child(a)
	_cilindro(tv, 0.035, 0.03, Vector3(0, 1.15, -0.12), metallo)
	_solido(tv, Vector3(0.70, 1.12, 0.46), Vector3(0, 0.56, 0))


## --- Chello ca sta appiso ê mmure.
##
## Tutto quanto sta **incollato alla parete**: `x = ±MURO_X` meno mezzo
## spessore. È la regola che prima non c'era, e per cui il crocifisso
## galleggiava a un metro e sessanta in mezzo alla stanza.
func _appise(r: Node3D, legno: Material) -> void:
	var scuro := Tex.flat(Color(0.32, 0.20, 0.12), 0.7)

	# 'O crocifisso, ncopp'ô comò, **appoggiato al muro di ponente**.
	var cr := Node3D.new()
	cr.position = Vector3(-MURO_X + 0.02, 1.62, 1.72)
	r.add_child(cr)
	_box(cr, Vector3(0.03, 0.34, 0.045), Vector3.ZERO, scuro)
	_box(cr, Vector3(0.03, 0.045, 0.20), Vector3(0, 0.07, 0), scuro)

	# 'O quadro d''o mare: il muro di mezzogiorno era completamente vuoto.
	var q := Node3D.new()
	q.position = Vector3(0.60, 1.58, MURO_Z - 0.02)
	r.add_child(q)
	_box(q, Vector3(0.86, 0.62, 0.03), Vector3.ZERO,
		Tex.flat(Color(0.58, 0.44, 0.24), 0.6))
	_box(q, Vector3(0.76, 0.52, 0.02), Vector3(0, 0, -0.012),
		Tex.flat(Color(0.36, 0.56, 0.68), 0.55))
	_box(q, Vector3(0.76, 0.18, 0.01), Vector3(0, -0.17, -0.018),
		Tex.flat(Color(0.24, 0.42, 0.56), 0.6))
	_box(q, Vector3(0.22, 0.16, 0.01), Vector3(0.20, 0.14, -0.018),
		Tex.flat(Color(0.42, 0.36, 0.32), 0.8))

	# 'O calannario d''o macellaio e l'orologio: due cose che si trovano
	# in ogni cucina e che dicono subito "questa è una casa".
	var cal := Node3D.new()
	cal.position = Vector3(-MURO_X + 0.02, 1.46, -0.60)
	r.add_child(cal)
	_box(cal, Vector3(0.02, 0.42, 0.30), Vector3.ZERO,
		Tex.flat(Color(0.94, 0.92, 0.86), 0.9))
	_box(cal, Vector3(0.014, 0.10, 0.30), Vector3(0.004, 0.16, 0),
		Tex.flat(Color(0.74, 0.20, 0.16), 0.85))

	var oro := Node3D.new()
	oro.position = Vector3(-0.30, 1.94, -MURO_Z + 0.02)
	r.add_child(oro)
	_cilindro(oro, 0.13, 0.04, Vector3.ZERO, legno).rotation.x = PI * 0.5
	var quadr := _cilindro(oro, 0.11, 0.02, Vector3(0, 0, -0.02),
		Tex.flat(Color(0.94, 0.92, 0.86), 0.8))
	quadr.rotation.x = PI * 0.5
	_box(oro, Vector3(0.012, 0.08, 0.012), Vector3(0, 0.035, -0.032),
		Tex.flat(Color(0.16, 0.14, 0.12), 0.8))
	_box(oro, Vector3(0.06, 0.012, 0.012), Vector3(0.026, 0, -0.032),
		Tex.flat(Color(0.16, 0.14, 0.12), 0.8))

	# 'O sciacquamano cu 'o specchietto, a fianco d''a porta: l'angolo che
	# restava vuoto fra l'uscita e 'a tavula.
	var lav := Node3D.new()
	lav.position = Vector3(MURO_X - 0.16, 0.0, 2.10)
	r.add_child(lav)
	_box(lav, Vector3(0.30, 0.14, 0.44), Vector3(0, 0.84, 0),
		Tex.flat(Color(0.92, 0.91, 0.88), 0.35))
	_cilindro(lav, 0.05, 0.84, Vector3(0, 0.42, 0),
		Tex.flat(Color(0.90, 0.89, 0.86), 0.4))
	_solido(lav, Vector3(0.30, 0.92, 0.44), Vector3(0, 0.46, 0))
	_box(lav, Vector3(0.02, 0.40, 0.32), Vector3(0.15, 1.42, 0),
		Tex.flat(Color(0.72, 0.78, 0.80, 0.9), 0.12, 0.9))


## --- 'O ventilatore appeso, che gira. Un vascio d'estate senza
## ventilatore non è un vascio. **'O tubo arriva ô soffitto**: prima si
## fermava tredici centimetri prima e la pala restava per aria.
func _ventilatore(r: Node3D, legno_chiaro: Material, metallo: Material) -> void:
	# **Uno sulo.** Alla prima passata avevo appeso il modello PSX al
	# soffitto dalla lista della roba di casa, e il ventilatore procedurale
	# stava già lì, alla stessa identica coordinata: nella fotografia si
	# vedevano **due ventilatori compenetrati** che giravano a velocità
	# diverse. Chi costruisce una cosa dev'essere uno solo — è la stessa
	# regola per cui il mouse della 0.56b ha una porta sola.
	var vero := Models.spawn("ventilatore")
	if vero != null:
		vero.position = Vector3(0.20, ALT - 0.12, -0.30)
		r.add_child(vero)
		return
	var giu: float = 0.30                # quanto scende dal soffitto
	var vent := Node3D.new()
	vent.name = "Ventilatore"
	vent.position = Vector3(0.20, ALT - giu, -0.30)
	r.add_child(vent)
	_cilindro(vent, 0.022, giu, Vector3(0, giu * 0.5, 0), metallo)
	_cilindro(vent, 0.09, 0.05, Vector3(0, 0.09, 0), metallo)
	_cilindro(vent, 0.075, 0.10, Vector3(0, 0.0, 0), metallo)
	for i in range(4):
		var pala := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.62, 0.012, 0.14)
		pala.mesh = bm
		pala.material_override = legno_chiaro
		pala.position = Vector3(0.38, -0.02, 0)
		pala.rotation.x = 0.16
		var piv := Node3D.new()
		piv.rotation.y = TAU * float(i) / 4.0
		piv.add_child(pala)
		vent.add_child(piv)


func _sedia(sotto: Node3D, pos: Vector3, rot: float, legno: Material) -> void:
	var s := Node3D.new()
	s.position = pos
	s.rotation.y = rot
	sotto.add_child(s)
	var paglia := Tex.flat(Color(0.78, 0.66, 0.36), 0.94)
	_box(s, Vector3(0.40, 0.03, 0.40), Vector3(0, 0.45, 0), paglia)
	for sx in [-0.17, 0.17]:
		for sz in [-0.17, 0.17]:
			_box(s, Vector3(0.035, 0.45, 0.035), Vector3(sx, 0.225, sz), legno)
	_box(s, Vector3(0.40, 0.50, 0.035), Vector3(0, 0.70, -0.18), legno)
	for i in range(3):
		_box(s, Vector3(0.34, 0.035, 0.03),
			Vector3(0, 0.56 + float(i) * 0.13, -0.18), legno)
	# **'O collider.** Prima le sedie si attraversavano: quattro sagome di
	# legno in mezzo alla stanza e ci si passava dentro camminando.
	_solido(s, Vector3(0.42, 0.48, 0.42), Vector3(0, 0.24, 0))


func _caffettiera(sotto: Node3D, pos: Vector3) -> void:
	var m := Tex.flat(Color(0.72, 0.72, 0.74), 0.35, 0.75)
	var c := Node3D.new()
	c.position = pos
	sotto.add_child(c)
	_cilindro(c, 0.045, 0.09, Vector3(0, 0.045, 0), m)
	_cilindro(c, 0.038, 0.09, Vector3(0, 0.135, 0), m)
	_box(c, Vector3(0.012, 0.09, 0.05), Vector3(0.055, 0.11, 0),
		Tex.flat(Color(0.14, 0.14, 0.15), 0.8))
	_cilindro(c, 0.012, 0.05, Vector3(-0.05, 0.14, 0), m)


func _luce_dentro(r: Node3D) -> void:
	# **La lampadina a filo.** Una sola, in mezzo, calda e bassa: è così che
	# è illuminato un basso, e la penombra agli angoli fa metà del lavoro.
	var filo := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.004
	cm.bottom_radius = 0.004
	cm.height = 0.5
	filo.mesh = cm
	filo.material_override = Tex.flat(Color(0.12, 0.12, 0.12), 0.9)
	filo.position = Vector3(-0.6, ALT - 0.25, 0.9)
	r.add_child(filo)
	var bulbo := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.055
	sm.height = 0.11
	bulbo.mesh = sm
	var mb := Tex.flat(Color(1.0, 0.92, 0.72), 0.2)
	mb.emission_enabled = true
	mb.emission = Color(1.0, 0.86, 0.60)
	mb.emission_energy_multiplier = 2.4
	bulbo.material_override = mb
	bulbo.position = Vector3(-0.6, ALT - 0.52, 0.9)
	r.add_child(bulbo)

	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.84, 0.62)
	l.light_energy = 2.6
	l.omni_range = 7.0
	l.omni_attenuation = 1.4
	l.shadow_enabled = true
	l.position = Vector3(-0.6, ALT - 0.55, 0.9)
	r.add_child(l)
	_luci.append(l)
	# **Se non hai pagato 'a luce, la casa sta al buio.** È l'unica
	# conseguenza che si *vede* invece di leggersi in una riga di
	# riepilogo, ed è per questo che vale più delle altre: entri, e la
	# lampadina non si accende.
	if GameManager.luce_staccata:
		l.light_energy = 0.0
		var mb2: StandardMaterial3D = bulbo.material_override
		if mb2 != null:
			mb2.emission_energy_multiplier = 0.0

	# Una seconda luce, fredda e debolissima, dalla parte della porta: è la
	# strada che entra. Serve a non avere un angolo completamente nero.
	var l2 := OmniLight3D.new()
	l2.light_color = Color(0.62, 0.70, 0.88)
	l2.light_energy = 0.7
	l2.omni_range = 4.0
	l2.shadow_enabled = false
	l2.position = Vector3(LARG * 0.5 - 0.6, 1.9, PROF * 0.5 - 0.6)
	r.add_child(l2)
	_luci.append(l2)


func _uscita(r: Node3D) -> void:
	var u := StaticBody3D.new()
	u.name = "Uscita"
	u.position = Vector3(LARG * 0.5 - 0.25, 0.0, PROF * 0.5 - 0.9)
	u.collision_layer = LAYER_CAR
	u.collision_mask = 0
	u.set_script(preload("res://scripts/porta_casa.gd"))
	u.vascio = self
	u.verso_dentro = false
	r.add_child(u)
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	# Larga e profonda: dentro a un basso ci si gira addosso, e una porta
	# con un collider sottile la si manca guardandola di sbieco. La prima
	# prova sul campo l'ha detta chiara — "quando un vigile mi porta in
	# casa non riesco a uscire".
	bx.size = Vector3(1.0, 2.3, 1.7)
	cs.shape = bx
	cs.position = Vector3(-0.25, 1.15, 0)
	u.add_child(cs)
	_box(u, Vector3(0.06, 2.05, 1.05), Vector3(0.14, 1.02, 0),
		Tex.flat(Color(0.30, 0.20, 0.14), 0.8))
	_cilindro(u, 0.03, 0.08, Vector3(0.08, 1.05, -0.36),
		Tex.flat(Color(0.72, 0.62, 0.32), 0.4, 0.6))
	# **'O cartello.** Dentro a una stanza sola, senza finestre, la porta è
	# un rettangolo marrone in mezzo ad altri rettangoli marroni. Con la
	# scritta sopra la trovi girandoti, e basta.
	var seg := Label3D.new()
	seg.text = "FORE ▸"
	seg.font_size = 40
	seg.pixel_size = 0.0032
	seg.modulate = Color(1.0, 0.86, 0.42)
	seg.outline_size = 10
	seg.outline_modulate = Color(0.10, 0.08, 0.06)
	seg.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	seg.no_depth_test = true
	seg.position = Vector3(-0.1, 2.16, 0)
	u.add_child(seg)


func _letto(r: Node3D) -> void:
	var b := StaticBody3D.new()
	b.name = "Letto"
	b.position = Vector3(LARG * 0.5 - 1.1, 0.0, -PROF * 0.5 + 1.35)
	b.collision_layer = LAYER_CAR
	b.collision_mask = 0
	b.set_script(preload("res://scripts/letto.gd"))
	b.vascio = self
	r.add_child(b)
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(1.5, 1.0, 2.1)
	cs.shape = bx
	cs.position = Vector3(0, 0.5, 0)
	b.add_child(cs)

	var legno := Tex.flat(Color(0.34, 0.22, 0.15), 0.72)
	var lenzuolo := Tex.flat(Color(0.86, 0.84, 0.78), 0.96)
	var coperta := Tex.flat(Color(0.52, 0.24, 0.22), 0.98)
	_box(b, Vector3(1.42, 0.26, 2.0), Vector3(0, 0.30, 0), legno)
	_box(b, Vector3(1.38, 0.18, 1.96), Vector3(0, 0.52, 0), lenzuolo)
	_box(b, Vector3(1.40, 0.10, 1.30), Vector3(0, 0.62, 0.30), coperta)
	for sz in [-0.95, 0.95]:
		_box(b, Vector3(1.44, 0.6 if sz < 0 else 0.36, 0.06),
			Vector3(0, 0.3 + (0.3 if sz < 0 else 0.18), sz), legno)
	# Due cuscini.
	for sx in [-0.32, 0.32]:
		_box(b, Vector3(0.56, 0.12, 0.34), Vector3(sx, 0.66, -0.74), lenzuolo)
	# Il collider solido: non ci si cammina sopra.
	_solido(b, Vector3(1.42, 0.62, 2.0), Vector3(0, 0.31, 0))


# ---------------------------------------------------------------------------
# Chi ce sta dintro
# ---------------------------------------------------------------------------

func _moglie_e_criature(r: Node3D) -> void:
	# --- 'A mugliera. Sta in piedi vicino alla tavola, e quando entri si
	# gira. Non ha un modello comprato: è lo stesso rig di tutti, con la
	# vestaglia e i capelli raccolti.
	var m := StaticBody3D.new()
	m.name = "Moglie"
	# Spostata alla 0.45: a (-0.9, 0.55) stava esattamente dove adesso c'e'
	# la sedia di ponente. Da qui guarda 'a tavula, ed e' libera davanti.
	m.position = Vector3(-2.30, 0.0, 0.35)
	m.rotation.y = -1.32
	m.collision_layer = LAYER_CAR
	m.collision_mask = 0
	m.set_script(preload("res://scripts/moglie_3d.gd"))
	m.vascio = self
	r.add_child(m)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.34
	cap.height = 1.66
	cs.shape = cap
	cs.position = Vector3(0, 0.85, 0)
	m.add_child(cs)

	var parti: Dictionary = Human.build(
		Color(0.58, 0.24, 0.30), Color(0.30, 0.28, 0.34), "", 1.63,
		{"skin": Color(0.86, 0.70, 0.56), "hair": Color(0.14, 0.11, 0.09),
		 "corpo": "femmina", "belly": 0.45, "bald": false,
		 "moustache": false})
	m.add_child(parti["root"])
	m.parti = parti
	_moglie = m

	var bolla := SpeechBubbleScript.new()
	bolla.position = Vector3(0, 1.95, 0)
	m.add_child(bolla)
	m.bolla = bolla
	_moglie_bolla = bolla

	# --- 'E criature. Due, per terra, che giocano. Non parlano quasi mai —
	# e quando parlano chiedono qualcosa, che è quello che fanno i bambini.
	# Lontano dal letto: il letto ha un ingombro di un metro e mezzo per
	# due, e una criatura seduta e' alta un metro. Messe accanto, il raggio
	# dell'interazione agganciava sempre il letto — misurato.
	var posti := [Vector3(0.15, 0.0, -1.55), Vector3(0.75, 0.0, -1.1)]
	for i in range(2):
		var c := StaticBody3D.new()
		c.name = "Criatura%d" % i
		c.position = posti[i]
		c.rotation.y = randf_range(-PI, PI)
		c.collision_layer = LAYER_CAR
		c.collision_mask = 0
		c.set_script(preload("res://scripts/criatura_3d.gd"))
		c.vascio = self
		c.indice = i
		r.add_child(c)
		var cc := CollisionShape3D.new()
		var cap2 := CapsuleShape3D.new()
		cap2.radius = 0.32
		cap2.height = 1.3
		cc.shape = cap2
		cc.position = Vector3(0, 0.66, 0)
		c.add_child(cc)
		var pc: Dictionary = Human.build(
			Color(0.90, 0.82, 0.42) if i == 0 else Color(0.36, 0.58, 0.80),
			Color(0.24, 0.30, 0.44), "", 1.16,
			{"belly": 0.2, "bald": false, "moustache": false})
		c.add_child(pc["root"])
		c.parti = pc
		var b2 := SpeechBubbleScript.new()
		b2.position = Vector3(0, 1.42, 0)
		c.add_child(b2)
		c.bolla = b2
		_criature.append(c)

	# 'O pallone e 'e machinelle per terra: quello con cui giocano. Il
	# pallone è quello vero del pacchetto (0.59); la sfera bianca resta se
	# il modello manca. Le machinelle stanno in `_robba_nova`.
	var vero := Models.spawn("pallone_casa")
	if vero != null:
		vero.position = Vector3(0.9, 0.0, -1.42)
		r.add_child(vero)
		return
	var pall := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.11
	sm.height = 0.22
	pall.mesh = sm
	pall.material_override = Tex.flat(Color(0.92, 0.90, 0.86), 0.7)
	pall.position = Vector3(0.9, 0.11, -1.42)
	r.add_child(pall)


# ---------------------------------------------------------------------------
# Trase e jesce
# ---------------------------------------------------------------------------

## **Addó se sta, 'a fore 'a porta.**
##
## Il vicolo è largo quattro metri e le macchine ci passano nel mezzo: la
## corsia libera va da x 26,9 a x 29,1, e quello che resta su questo lato è
## una striscia di novanta centimetri fra il muro e le ruote. Il giocatore
## è largo settanta (raggio 0,35), quindi il posto dove ci sta è uno solo:
## **appoggiato ô muro**, come si sta davanti a un basso.
##
## Il numero non è a occhio. Muro a x 26, porta a 26,15, mezzo corpo 0,35 →
## il centro non può stare prima di 26,35; la corsia comincia a 26,9 e
## mezzo corpo se ne prende altri 0,35 → non può stare dopo 26,55. In mezzo
## a quella fessura ci sono venti centimetri, e si sta nel mezzo.
##
## Prima erano 1,4 metri, cioè **'n miezo â carreggiata**: uscivi di casa e
## la prima macchina che saliva il vicolo ti pigliava di muso (0.56).
const PORTA_FORE: float = 0.30


func punto_porta() -> Vector3:
	return PORTA_POS + Vector3(PORTA_FORE, 0.0, 0.0)


## Entra in casa. Il player viene spostato dentro; da dove era si torna
## uscendo dalla porta.
func entra(player: Node3D) -> void:
	if GameManager.dentro_casa or player == null:
		return
	_ritorno = player.global_position
	_ritorno_rot = player.rotation.y
	GameManager.dentro_casa = true
	GameManager.casa_entrata.emit(true)
	# Le chiavi e la porta di casa (0.62, Freesound): si entra con le
	# chiavi, si esce tirandosi la porta.
	SoundManager.play("chiavi_porta", -6.0)
	SoundManager.ambiente(0.22)
	player.global_position = _dentro_nodo.global_position \
		+ Vector3(LARG * 0.5 - 1.0, 0.55, PROF * 0.5 - 1.0)
	player.rotation.y = PI * 0.75
	if player.has_method("azzera_moto"):
		player.azzera_moto()
	if GameManager.ora_ritiro < 0.0:
		GameManager.ora_ritiro = GameManager.ore_passate()
	if _moglie != null and _moglie.has_method("saluta"):
		_moglie.saluta()


func esci(player: Node3D) -> void:
	if not GameManager.dentro_casa or player == null:
		return
	GameManager.dentro_casa = false
	GameManager.casa_entrata.emit(false)
	SoundManager.play("door")
	SoundManager.ambiente(1.0)
	# **Se esce sempe 'a fore 'a porta** (0.56).
	#
	# Prima si tornava **dove stavi quando sei entrato** (`_ritorno`), e
	# sulla carta era comodo: entri dalla piazza, esci in piazza. In
	# pratica era la cosa più strana del gioco — ti riportavano a casa i
	# carabinieri, uscivi, e ti ritrovavi teletrasportato dall'altra parte
	# della città, nel punto in cui ti avevano preso. E dopo una notte in
	# cella non aveva nemmeno un significato.
	#
	# Una porta è una porta: da una porta si esce **fuori da quella
	# porta**. Se poi la piazza sta lontana, ci si va a piedi — che è
	# esattamente il gioco.
	player.global_position = punto_porta() + Vector3(0, 0.4, 0)
	# E girato **p''o vicolo, verso 'a piazza**.
	#
	# Ci avevo messo `PI * 0.5` con scritto accanto «se no esci guardando il
	# muro di casa», e faceva esattamente quello: la porta ruotata di
	# novanta gradi guarda a +X perché è il suo asse **+Z locale** a
	# indicare il davanti; il giocatore invece guarda lungo **−Z**, e con lo
	# stesso angolo si voltava dall'altra parte — con la faccia dentro al
	# muro. È la stessa convenzione che tiene inguaiato questo progetto da
	# sei versioni: `forward(θ) = (−sinθ, 0, −cosθ)`, **'o +z sta areto**.
	#
	# A zero si guarda verso −Z, cioè giù per il vicolo, dalla parte dove
	# sta la piazza: esci di casa e tieni già davanti il posto di lavoro.
	player.rotation.y = 0.0
	if player.has_method("azzera_moto"):
		player.azzera_moto()
	# Uscire dopo essere rientrato non ti ridà la sera: l'ora del rientro
	# resta quella della prima volta che hai messo piede dentro.


## Se i carabinieri (o l'ospedale) ti riportano a casa, ci finisci davvero.
##
## E quando ti ci ritrovi dentro senza averci camminato, il gioco te lo deve
## **dire**: uno che si risveglia in una stanza che non ha mai visto non sa
## né che è casa sua né come si esce. Il banner dice tutt'e due le cose.
func _su_rientro_forzato(causa: String) -> void:
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null:
		return
	if not GameManager.dentro_casa:
		entra(pl)
	var testo := "T'hanno purtato 'a casa."
	match causa:
		"carabinieri":
			testo = "'E carabiniere t'hanno lassato sotto 'a casa toia."
		"ospedale":
			testo = "T'hanno dimesso. Sî turnato 'a casa cu 'e ppezze."
		"vigile":
			testo = "'O vigile t'ha fatto 'o verbale e t'ha mannato 'a casa."
	GameManager.event_started.emit(
		"%s  Parla cu Nunzia [E], po' vatte a corca' ncopp''o lietto [E]. "
		% testo + "'A porta pe' asci' fore sta arreto 'e te.")
	if _moglie != null and _moglie.has_method("dici"):
		_moglie.dici("E che t'è success'?! Mamma mia... viene ccà.", 5.0)


# ---------------------------------------------------------------------------
# 'O pannello: consegna, riepilogo, chiacchiere
# ---------------------------------------------------------------------------

func pannello() -> CanvasLayer:
	if _pannello == null or not is_instance_valid(_pannello):
		_pannello = PannelloCasa.new()
		_pannello.name = "PannelloCasa"
		get_tree().root.add_child(_pannello)
	return _pannello


func apri_consegna() -> void:
	pannello().apri_consegna()


# ---------------------------------------------------------------------------
# Aiutini di costruzione
# ---------------------------------------------------------------------------

func _box(sotto: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	if mat != null:
		mi.material_override = mat
	mi.position = pos
	sotto.add_child(mi)
	return mi


func _cilindro(sotto: Node3D, raggio: float, alt: float, pos: Vector3,
		mat: Material) -> MeshInstance3D:
	if alt <= 0.0:
		return null
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = raggio
	cm.bottom_radius = raggio
	cm.height = alt
	mi.mesh = cm
	if mat != null:
		mi.material_override = mat
	mi.position = pos
	sotto.add_child(mi)
	return mi


## Un muro che si vede e che ferma.
func _muro_solido(sotto: Node3D, size: Vector3, pos: Vector3,
		mat: Material) -> void:
	_box(sotto, size, pos, mat)
	_solido(sotto, size, pos)


## Solo il collider, senza niente da vedere.
func _solido(sotto: Node3D, size: Vector3, pos: Vector3) -> void:
	var sb := StaticBody3D.new()
	sb.collision_layer = LAYER_WORLD
	sb.position = pos
	sotto.add_child(sb)
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = size
	cs.shape = bx
	sb.add_child(cs)


func _process(delta: float) -> void:
	var v := _dentro_nodo.get_node_or_null("Ventilatore") if _dentro_nodo else null
	if v != null:
		v.rotation.y += delta * 2.6
