extends Node3D
## Posteggio3D — il lavoro in una piazza conquistata
##
## Quando ti prendi la piazza dello stadio, del mercato o della cornetteria,
## quella piazza deve cominciare a rendere: cioè devono arrivarci le auto.
## Questo nodo è quello che le fa arrivare.
##
## ## Perché non si riusa `ZoneVicolo`
##
## `ZoneVicolo` sa già fare tutto questo — è la piazza iniziale. Ma sa fare
## anche molto altro: costruisce facciate, marciapiedi, il salotto di
## maioliche, la fontana, il campetto, i palazzi di fondo, il Vesuvio.
## Istanziarne una seconda sopra al mercato vorrebbe dire costruire un
## secondo quartiere dentro a quello che c'è già.
##
## Qui c'è solo il rubinetto: un timer, i punti dove le auto entrano,
## aspettano ed escono, e `Car3D` — che è esattamente la stessa classe che
## usa la piazza. Il cliente è identico; cambia solo chi lo chiama.
##
## ## Da dove entrano ed escono
##
## Le zone sono rettangoli ritagliati dentro alla maglia delle strade, e le
## strade le costeggiano. Le auto entrano dal centro di un lato corto,
## aspettano su una fila di punti dentro alla zona, e se ne vanno dal lato
## opposto. Non serve un percorso: sono venti metri in linea retta dentro a
## uno spiazzo vuoto.

const CarScene := preload("res://scripts/car_3d.gd")
const VigileScene := preload("res://scripts/vigile_3d.gd")

## Ogni quanto arriva un'auto. Piu' lento della piazza iniziale: una zona in
## piu' deve aggiungere lavoro, non raddoppiarlo. Se tutte e quattro le
## piazze sfornassero auto al ritmo della prima, il giocatore passerebbe il
## turno a correre da una parte all'altra senza mai finire niente.
## Accorciati insieme alla giornata: con un giorno da quattro minuti e
## mezzo, un'auto ogni quaranta secondi voleva dire sei clienti in tutto il
## turno, e una piazza da quattrocentocinquanta euro non si ripaga con sei
## clienti al giorno.
const OGNI_MIN: float = 20.0
const OGNI_MAX: float = 30.0
## Quante auto da servire insieme, al massimo, in questa piazza.
const MAX_AUTO: int = 3

var zona_id: String = ""
var rect: Array = []

var _entrata: Vector3
var _uscita: Vector3
var _coda: Array[Vector3] = []
var _cursore: int = 0
var _timer: Timer


func configura(id: String, r: Array) -> void:
	zona_id = id
	rect = r
	var x0: float = float(r[0])
	var z0: float = float(r[1])
	var x1: float = float(r[2])
	var z1: float = float(r[3])

	# I varchi e la coda non si calcolano piu' qui: dipendono da cosa c'e'
	# COSTRUITO dentro alla piazza, e al momento in cui la citta' chiama
	# `configura()` mezza piazza non esiste ancora. Si fa in `_ready`, a
	# corpi fisici gia' in piedi. Questi sono solo un ripiego decente.
	var cz: float = (z0 + z1) / 2.0
	_entrata = Vector3(x0 - 4.0, 0.0, cz)
	_uscita = Vector3(x1 + 4.0, 0.0, cz)
	if not _vigili_fatti:
		_vigili_fatti = true
		_build_vigili()


var _vigili_fatti: bool = false


# ---------------------------------------------------------------------------
# Da dove si entra, e dove si aspetta
# ---------------------------------------------------------------------------
#
# **Le piazze comprate non servivano un cliente. Mai.**
#
# Entrata e uscita erano scritte a mano: due metri fuori dal lato corto
# ovest, la coda in mezzo alla zona. Sulla carta funziona; nella citta'
# costruita no, e per un motivo diverso in ogni piazza:
#
# - al **mercato** le bancarelle stanno in fila lungo tutto il lato ovest e
#   tutto il lato est. Un'auto che entra da ovest sbatte nel primo banco,
#   resta ferma due secondi e mezzo, si dichiara bloccata e se ne va;
# - allo **stadio** il centro della zona e' occupato dall'impianto: la coda
#   finiva dentro alla curva;
# - e i vicoli che costeggiano le piazze sono larghi quattro metri, quindi
#   perfino "due metri fuori dal bordo" cade sul cordolo invece che in
#   mezzo alla corsia.
#
# Il risultato era che compravi la piazza per quattrocentocinquanta euro e
# lei restava vuota per sempre. E non si vedeva nessun errore: le auto
# nascevano davvero, semplicemente si arrendevano tutte.
#
# Adesso non c'e' piu' niente scritto a mano. Al primo frame utile si
# provano i quattro versi possibili e si tiene il primo dove entrata e
# uscita sono libere davvero — chiedendolo al motore fisico, con la sagoma
# di un'auto. Stessa cosa per i posti d'attesa: si spargono nella zona e si
# tengono solo quelli dove un'auto ci sta.
const SAGOMA := Vector3(2.4, 1.4, 4.8)


func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = randf_range(6.0, 12.0)
	_timer.one_shot = false
	_timer.timeout.connect(_on_timeout)
	add_child(_timer)
	_timer.start()
	# **'E vigile nun se costruivano cchiù** (0.62). `_build_vigili()` stava
	# qui, ma la città chiama `configura()` DOPO `add_child()`: in `_ready`
	# il rettangolo è ancora vuoto e la funzione usciva senza fare niente.
	# Il risultato: stadio, mercato e cornetteria senza un vigile, da quando
	# l'ordine è cambiato. Adesso li costruisce `configura()`.
	# **La misura si fa a mondo avviato, non in `_ready`.**
	#
	# Serviva gia' un `call_deferred` perche' la citta' sta ancora
	# costruendo; adesso serve di piu': fra le locandine e il "Accummenciamo"
	# l'albero e' in pausa, e a fisica ferma lo spazio non ha ancora fatto un
	# passo — ogni interrogazione tornerebbe "libero" e i varchi si
	# sceglierebbero a caso. Si misura al primo giro utile del timer, che per
	# definizione arriva a partita avviata.
	GameManager.servizio_cambiato.connect(_su_servizio)


## **Trasi 'n piazza e 'a machina arriva** (0.64). Il capo: *«entrando in
## piazza cominciano ad arrivare auto da parcheggiare, esattamente come
## nella tua»*. Il rubinetto aveva il suo giro fisso (venti-trenta secondi,
## e alla cornetteria di giorno più di un minuto): entrando in una piazza
## vuota si stava lì a guardare l'asfalto, e sembrava rotta. Adesso, se
## entri in questa piazza e non c'è niente da servire, il primo cliente
## arriva fra due e quattro secondi; poi si va col passo della piazza.
func _su_servizio(attivo: bool, _nome: String) -> void:
	if not attivo or GameManager.zona_corrente != zona_id:
		return
	if not GameManager.zona_mia(zona_id) or not GameManager.shift_active:
		return
	if _da_servire() > 0 or _timer == null:
		return
	if _timer.time_left > 4.0:
		_timer.start(randf_range(2.0, 4.0))


var _misurato: bool = false


## Vero se in quel punto ci sta un'auto senza toccare niente.
func _libero(p: Vector3) -> bool:
	var mondo := get_world_3d()
	if mondo == null:
		return true
	var q := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = SAGOMA
	q.shape = box
	q.transform = Transform3D(Basis(), Vector3(p.x, 0.8, p.z))
	q.collision_mask = 1 | 4 # muri e veicoli
	# **'E cristiani nun so' mure** (0.61): il rivale, l'armiere e chi
	# passa stanno sullo stesso strato delle auto, e alla cornetteria
	# bastavano loro due a far sembrare murata mezza piazza.
	for h in mondo.direct_space_state.intersect_shape(q, 8):
		var c = h.get("collider")
		if c is CharacterBody3D and not (c as Node).is_in_group("cars"):
			continue
		return false
	return true


func _scegli_varchi() -> void:
	if rect.size() < 4:
		return
	var x0: float = float(rect[0])
	var z0: float = float(rect[1])
	var x1: float = float(rect[2])
	var z1: float = float(rect[3])
	var cx: float = (x0 + x1) / 2.0
	var cz: float = (z0 + z1) / 2.0

	# **Nun sulo 'o miezo d''o lato** (0.61). Fino alla 0.60 si provavano
	# quattro varchi, uno in mezzo a ogni lato, e se nessuno andava bene si
	# ripiegava sul centro della zona. Allo stadio il centro del lato ovest
	# sta dentro a un palazzo e la linea verso il centro passa per la curva:
	# **nessuna** macchina arrivava mai in coda (la prova della 0.61 le ha
	# contate: quattro nate, zero servite, in quattro minuti). Adesso si
	# provano cinque punti per lato, a quattro e a otto metri dal bordo.
	# **Nun se trase d''a parte d''a fila 'e fondo** (0.64). Il mercato ha
	# una fila di posti lungo il bordo sud, e il varco che «raggiunge più
	# code» era proprio lì: chi entrava doveva passare in mezzo alle
	# macchine appena posteggiate, si incastrava e se ne andava
	# (`prova_conquista`: tre clienti persi in cento secondi). Un lato con
	# dei posti a meno di quattro metri dal bordo non è un ingresso.
	var chiuso := {"ovest": false, "est": false, "nord": false, "sud": false}
	for s in get_tree().get_nodes_in_group("parking_spots"):
		if str(s.get("zona_id")) != zona_id:
			continue
		var q: Vector3 = (s as Node3D).global_position
		if q.z > z1 - 4.0:
			chiuso["sud"] = true
		if q.z < z0 + 4.0:
			chiuso["nord"] = true
		if q.x < x0 + 3.0:
			chiuso["ovest"] = true
		if q.x > x1 - 3.0:
			chiuso["est"] = true
	var varchi: Array = []
	for fuori in [4.0, 8.0]:
		for t in [0.5, 0.3, 0.7, 0.15, 0.85]:
			if not chiuso["ovest"]:
				varchi.append(Vector3(x0 - fuori, 0, lerpf(z0, z1, t)))
			if not chiuso["est"]:
				varchi.append(Vector3(x1 + fuori, 0, lerpf(z0, z1, t)))
			if not chiuso["nord"]:
				varchi.append(Vector3(lerpf(x0, x1, t), 0, z0 - fuori))
			if not chiuso["sud"]:
				varchi.append(Vector3(lerpf(x0, x1, t), 0, z1 + fuori))
	var liberi: Array = []
	for v in varchi:
		if _libero(v):
			liberi.append(v)

	var posti: Array = []
	# (0.64) Quattro file invece di tre, e fino a tre metri e mezzo dal
	# bordo: alla cornetteria l'unico posto buono per aspettare è la
	# striscia di fondo, fra le due file di posti e dietro al banco
	# dell'armiere.
	for ix in range(5):
		for iz in range(4):
			var p := Vector3(
				lerpf(x0 + 6.0, x1 - 6.0, (float(ix) + 0.5) / 5.0), 0.0,
				lerpf(z0 + 5.0, z1 - 2.8, (float(iz) + 0.5) / 4.0))
			# (0.64) Chi aspetta non aspetta ncopp'ê strisce: con la fila di
			# fondo, una macchina in coda davanti ai posti li tappava tutti.
			if _libero(p) and not _ncopp_a_nu_posto(p):
				posti.append(p)

	# Per ogni varco, i posti che si raggiungono in linea retta.
	# **E senza passà ncopp'ê strisce** (0.64). Allo stadio si entrava da
	# ovest e la strada per la coda attraversava la fila dei posti del
	# fianco: con due macchine posteggiate era un muro, e i clienti nuovi
	# si incastravano e se ne andavano (`prova_conquista`, quattro su dieci).
	# Se nessun varco ci riesce, si torna alla regola di prima.
	var sp_zona: Array = []
	for s in get_tree().get_nodes_in_group("parking_spots"):
		if str(s.get("zona_id")) == zona_id:
			sp_zona.append((s as Node3D).global_position)
	var da_varco: Array = []
	var qualcuno := false
	for v2 in liberi:
		var r: Array = []
		for p3 in posti:
			if _via_libera(v2, p3) and not _passa_pe_nu_posto(v2, p3, sp_zona):
				r.append(p3)
		if not r.is_empty():
			qualcuno = true
		da_varco.append(r)
	if not qualcuno:
		da_varco.clear()
		for v2 in liberi:
			var r2: Array = []
			for p3 in posti:
				if _via_libera(v2, p3):
					r2.append(p3)
			da_varco.append(r2)
	var meglio_i: int = -1
	for i in range(liberi.size()):
		if meglio_i < 0 or (da_varco[i] as Array).size() > (da_varco[meglio_i] as Array).size():
			meglio_i = i
	var meglio_punti: Array = []
	if meglio_i >= 0 and not (da_varco[meglio_i] as Array).is_empty():
		_entrata = liberi[meglio_i]
		meglio_punti = da_varco[meglio_i]
		# L'uscita: il varco che raggiunge più posti fra quelli della
		# coda, preferendo un altro lato; se non c'è, si esce da dove si
		# è entrati (in retromarcia di manovra: nessuno se ne accorge).
		_uscita = _entrata
		var conta_u: int = 0
		for j in range(liberi.size()):
			if j == meglio_i:
				continue
			var n: int = 0
			for p4 in meglio_punti:
				if (da_varco[j] as Array).has(p4):
					n += 1
			if n > conta_u:
				conta_u = n
				_uscita = liberi[j]
	# **Nisciun varco libbero** (0.64): alla cornetteria, stretta fra vicoli
	# da quattro metri, la sagoma di prova non ci sta mai e l'ingresso resta
	# quello di ripiego (quattro metri fuori dal lato di ponente). Prima la
	# coda diventava il centro della piazza, un punto solo per tre macchine
	# una sopra all'altra: chi arrivava sbatteva contro chi aspettava e se
	# ne andava. Adesso anche col ripiego la coda si sceglie fra i punti
	# buoni che dall'ingresso si raggiungono senza passare sulle strisce.
	if meglio_punti.is_empty():
		for p5 in posti:
			if not _passa_pe_nu_posto(_entrata, p5, sp_zona):
				meglio_punti.append(p5)
	meglio_punti.sort_custom(func(a, b):
		return a.distance_to(_entrata) < b.distance_to(_entrata))
	_coda.clear()
	for p2 in meglio_punti:
		# Due che aspettano non stanno uno dentro all'altro: di fianco o in
		# fila, con la sagoma d'aria.
		var addosso := false
		for q2 in _coda:
			if absf((q2 as Vector3).x - p2.x) < 2.7 and absf((q2 as Vector3).z - p2.z) < 5.0:
				addosso = true
				break
		if addosso:
			continue
		_coda.append(p2)
		if _coda.size() >= 4:
			break
	if _coda.is_empty():
		_coda.append(Vector3(cx, 0.0, cz))
	print_verbose("Posteggio %s: entrata %s uscita %s coda %s" % [zona_id,
		str(_entrata), str(_uscita), str(_coda)])


## **'E posti murati** (0.64). La città disegna i posti prima di mettere
## bancarelle, banchi e auto d'arredo; il catasto le tiene lontane, ma una
## cosa costruita dopo e senza chiedere può sempre finirci sopra. Alla prima
## misura, a mondo avviato, si guarda ogni posto di questa piazza con la
## sagoma di una macchina un po' stretta: se ci sta un muro (strato 1, cioè
## roba ferma — non le auto e non la gente), il posto si spegne. Meglio un
## posto in meno che una macchina mandata a sbattere per mezzo minuto.
func _spegni_posti_murati() -> int:
	var mondo := get_world_3d()
	if mondo == null:
		return 0
	var spenti := 0
	for s in get_tree().get_nodes_in_group("parking_spots"):
		if str(s.get("zona_id")) != zona_id:
			continue
		var p: Vector3 = (s as Node3D).global_position
		var q := PhysicsShapeQueryParameters3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.9, 1.0, 4.0)
		q.shape = box
		q.transform = Transform3D(Basis(), Vector3(p.x, p.y + 0.75, p.z))
		q.collision_mask = 1
		var murato := false
		for h in mondo.direct_space_state.intersect_shape(q, 4):
			var c = h.get("collider")
			if c is CharacterBody3D:
				continue
			murato = true
			break
		if murato and s.has_method("spegni"):
			s.spegni()
			spenti += 1
	if spenti > 0:
		print_verbose("Posteggio %s: %d posti murati spenti" % [zona_id, spenti])
	return spenti


## Vero se la strada dritta da `a` a `b` passa sopra a uno dei posti `sp`
## (con la mezza larghezza di una macchina d'aria).
func _passa_pe_nu_posto(a: Vector3, b: Vector3, sp: Array) -> bool:
	var passi: int = maxi(2, int(ceil(a.distance_to(b) / 0.8)))
	for i in range(passi + 1):
		var p: Vector3 = a.lerp(b, float(i) / float(passi))
		for q in sp:
			if absf((q as Vector3).x - p.x) < 1.1 + 1.3 \
					and absf((q as Vector3).z - p.z) < 2.2 + 1.3:
				return true
	return false


## Vero se una macchina ferma in `p` (col muso lungo z, come chi aspetta)
## starebbe sopra a un posto di questa piazza o davanti alla sua bocca.
func _ncopp_a_nu_posto(p: Vector3) -> bool:
	for s in get_tree().get_nodes_in_group("parking_spots"):
		if str(s.get("zona_id")) != zona_id:
			continue
		var q: Vector3 = (s as Node3D).global_position
		if absf(q.x - p.x) < 1.1 + 1.2 + 0.8 and absf(q.z - p.z) < 2.2 + 2.4 + 1.2:
			return true
	return false


func _via_libera(a: Vector3, b: Vector3) -> bool:
	var d: float = a.distance_to(b)
	if d < 0.1:
		return true
	var passi: int = maxi(2, int(ceil(d / 2.0)))
	for i in range(passi + 1):
		if not _libero(a.lerp(b, float(i) / float(passi))):
			return false
	return true


func _on_timeout() -> void:
	# **E ogni piazza tene 'o passo suio (0.55).** Il mercato sforna auto,
	# la cornetteria di giorno è un deserto e di notte è una fiera. Vedi
	# `GameManager.CARATTERE`: è la riga che rende la conquista una scelta
	# invece di una somma.
	_timer.wait_time = randf_range(OGNI_MIN, OGNI_MAX) \
		* GameManager.attesa_piazza(zona_id) * GameManager.attesa_ora_e_juorno()
	_timer.start()
	if GameManager.shift_active and not _misurato:
		_misurato = true
		_spegni_posti_murati()
		_scegli_varchi()
	if GameManager.giornata_scaduta:
		return
	# (0.64) Durante 'a sfida d''o Rre, in questa piazza 'e machine 'e manna lui.
	if GameManager.re_sfida_attiva and GameManager.re_zona_sfida == zona_id:
		return
	if not GameManager.zona_mia(zona_id) or not GameManager.shift_active:
		# Appena comprata, la piazza deve mettersi a rendere SUBITO. Se il
		# giro a vuoto ricaricasse i trenta secondi pieni, chi ha appena
		# speso quattrocentocinquanta euro resterebbe mezzo minuto in una
		# piazza vuota a chiedersi se ha buttato i soldi.
		_timer.wait_time = randf_range(3.0, 6.0)
		_timer.start()
		return
	# Stessa regola della piazza: fuori servizio il rubinetto si chiude.
	# Qui vale con una differenza — "in servizio" e' vero in QUALUNQUE
	# piazza tua, quindi mentre lavori al mercato le auto continuano ad
	# arrivare anche allo stadio. E' voluto: e' il senso di avere due
	# piazze, e il motivo per cui a un certo punto servira' qualcuno che ci
	# stia per te.
	if _da_servire() >= MAX_AUTO:
		return
	# **Col guaglione il rubinetto resta aperto anche se non ci sei.**
	#
	# La regola "fuori servizio arriva una macchina sola" serve a non
	# punire chi va a fare un giro: al ritorno non deve trovare la piazza
	# piena di clienti gia' incazzati. Ma se in quella piazza ci sta uno
	# che lavora per te, andare a fare un giro e' esattamente quello che
	# devi poter fare — e la piazza deve continuare a rendere mentre lo
	# fai, se no i settanta euro non li hai spesi per niente.
	if not GameManager.in_servizio and not GameManager.ha_dipendente(zona_id) \
			and _da_servire() >= 1:
		return
	_spawn()


## **'O guaglione fatica ncoppa ê ppiede suoje.**
##
## Fino alla 0.44b qui ci stava un rubinetto: ogni sei-undici secondi
## prendeva un'auto in coda dentro alla piazza e la dichiarava
## "parcheggiata" senza spostarla di un centimetro, mentre il guaglione
## continuava a girare per conto suo. Il commento diceva che far camminare
## uno fino alla macchina era "mezza intelligenza artificiale in piu' per
## una scena che il giocatore non sta guardando".
##
## Era sbagliato per due motivi. Il primo e' che il giocatore **la guarda**:
## la piazza di casa e' quella dove torna ogni sera, e ci trovava le
## macchine ferme in mezzo alla strada con scritto sopra che erano a posto.
## Il secondo e' che il giudizio e' arrivato lo stesso — *"deve davvero
## guidare le auto"* — e a quel punto la mezza intelligenza si e' dovuta
## scrivere comunque, solo con venti build di ritardo.
##
## Adesso sta tutta dentro a `guaglione_3d.gd` (chi ci sale) e a
## `car_3d.gd::guagliuno_sale` (chi manovra). Qui non resta niente.


func _da_servire() -> int:
	var n := 0
	for c in get_tree().get_nodes_in_group("cars"):
		if not is_instance_valid(c):
			continue
		# Solo quelle di QUESTA piazza: le auto sono tutte nello stesso
		# gruppo, e senza il controllo sulla posizione il mercato conterebbe
		# anche la coda della piazza iniziale e non spawnerebbe mai.
		if not _dentro(c.global_position):
			continue
		if c.state <= 2:
			n += 1
	return n


func _dentro(p: Vector3) -> bool:
	if rect.size() < 4:
		return false
	return p.x >= float(rect[0]) - 6.0 and p.x <= float(rect[2]) + 6.0 \
		and p.z >= float(rect[1]) - 6.0 and p.z <= float(rect[3]) + 6.0


func _spawn() -> Node:
	if _coda.is_empty():
		return null
	# **Ogni posto 'e coda a uno sulo** (0.64). Il giro a turno mandava la
	# quarta macchina sul punto della prima, che stava ancora lì: sbatteva,
	# si fermava e se ne andava. Adesso si sceglie un punto che nessuno sta
	# già occupando; se sono tutti presi, si aspetta il giro dopo.
	# E la strada dall'ingresso non deve passare addosso a chi aspetta: si
	# riempiono prima i punti più lontani (vedi `zone_vicolo_3d._punto_coda_libero`).
	var ordine: Array = _coda.duplicate()
	ordine.sort_custom(func(a, b): return a.distance_to(_entrata) > b.distance_to(_entrata))
	var ferme: Array = []
	for c in get_tree().get_nodes_in_group("cars"):
		if is_instance_valid(c) and str(c.get("zona_id")) == zona_id and int(c.get("state")) == 1:
			ferme.append((c as Node3D).global_position)
	var posto := Vector3.INF
	for cand in ordine:
		if _punto_preso(cand):
			continue
		var tappato := false
		for f in ferme:
			if _vicino_a_segmento(f, _entrata, cand) < 2.7:
				tappato = true
				break
		if not tappato:
			posto = cand
			break
	if posto == Vector3.INF:
		return null
	var car = CarScene.new()
	car.zona_id = zona_id
	if GameManager.re_sfida_attiva and GameManager.re_zona_sfida == zona_id:
		car.sfida = true
		car.forced_personality = "normale"
	add_child(car)
	car.setup(_entrata, posto, _uscita, [], [])
	return car


static func _vicino_a_segmento(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := Vector2(b.x - a.x, b.z - a.z)
	var ap := Vector2(p.x - a.x, p.z - a.z)
	var l2: float = ab.length_squared()
	var t: float = 0.0 if l2 < 0.0001 else clampf(ap.dot(ab) / l2, 0.0, 1.0)
	return (ap - ab * t).length()


## Vero se una macchina di questa piazza sta andando lì o ci sta aspettando.
func _punto_preso(p: Vector3) -> bool:
	for c in get_tree().get_nodes_in_group("cars"):
		if not is_instance_valid(c) or str(c.get("zona_id")) != zona_id:
			continue
		if int(c.get("state")) > 1:
			continue
		var w = c.get("waiting_point")
		if w is Vector3 and Vector2((w as Vector3).x, (w as Vector3).z).distance_to(
				Vector2(p.x, p.z)) < 1.0:
			return true
	return false


## **'A sfida d''o Rre** (0.64): lui chiama le macchine, e arrivano di corsa.
## Torna la macchina, o null se la coda è piena.
func sfida_manna_machina() -> Node:
	if not _misurato:
		_misurato = true
		_spegni_posti_murati()
		_scegli_varchi()
	var car = _spawn()
	if car != null:
		car.veloce = 2.0
	return car


# ---------------------------------------------------------------------------
# 'E vigile d''a piazza
# ---------------------------------------------------------------------------
#
# **'O stadio ne tene duje, 'o mercato nisciuno** (0.55).
#
# Fino alla 0.54 i vigili stavano **solo** nella piazza iniziale: le altre
# tre si compravano e si lavoravano senza che passasse mai nessuno in
# divisa. Era la ragione per cui conquistare non cambiava niente — il
# rischio restava a casa tua.
#
# Adesso ogni piazza si porta i suoi, e il numero viene da
# `GameManager.CARATTERE`. Ci sono **da subito**, anche prima che la
# piazza sia tua, ed è voluto: così uno può andare a vedersi lo stadio
# prima di spendere quattrocentocinquanta euro e accorgersi da solo che ci
# girano in due. Un carattere che scopri dopo aver pagato non è un
# carattere, è una fregatura.
func _build_vigili() -> void:
	var quanti: int = int(GameManager.carattere(zona_id)["vigili"])
	if quanti <= 0 or rect.size() < 4:
		return
	var x0: float = float(rect[0])
	var z0: float = float(rect[1])
	var x1: float = float(rect[2])
	var z1: float = float(rect[3])
	# Il giro sta dentro al rettangolo, con tre metri di margine: un
	# vigile che cammina sul bordo esce dalla piazza e finisce nel muro.
	var m := 3.0
	for i in range(quanti):
		# Due vigili non fanno lo stesso giro al contrario — si
		# incontrerebbero sempre nello stesso punto e mezza piazza
		# resterebbe scoperta per sempre. Il secondo gira sulla metà
		# opposta.
		var za: float = z0 + m
		var zb: float = z1 - m
		if quanti > 1:
			var meta: float = (z0 + z1) * 0.5
			if i == 0:
				zb = meta
			else:
				za = meta
		var v = VigileScene.new()
		add_child(v)
		v.setup([
			Vector3(x0 + m, 0.0, za), Vector3(x1 - m, 0.0, za),
			Vector3(x1 - m, 0.0, zb), Vector3(x0 + m, 0.0, zb),
		])
