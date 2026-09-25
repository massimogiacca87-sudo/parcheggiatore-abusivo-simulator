extends RefCounted
## **'E ccose ca stanno 'n terra — e ca nun se passano** (0.59).
##
## Il capo: *«risolvi parecchi problemi di collisioni dei personaggi con
## l'ambiente»*.
##
## Chi cammina per la città senza motore fisico (autisti, vigili, ragazzini,
## la signora, Borrelli, i carabinieri) conosce i palazzi, perché i palazzi
## sono rettangoli scritti in una tabella (`Citta.ISOLATI`). Non conosce
## **nient'altro**: le auto in sosta, le panchine, i cassonetti, le
## bancarelle, la munnezza della 0.58, i tavolini. Per lui sono aria. Il
## giocatore ci sbatte contro (hanno un collider), la gente ci passa
## attraverso. `prova_ntuppate` l'ha misurato: i ragazzini della piazza
## stavano dentro a qualcosa **una volta su quindici**.
##
## Scriverlo in venti posti diversi — «quando metti una panchina, avvisa chi
## cammina» — è una promessa che prima o poi non si mantiene: la 0.58 ha
## aggiunto cento cose in strada, e nessuna avvisava. Quindi qui si fa al
## contrario: **a città finita si passano in rassegna tutti i corpi solidi
## che ci sono**, e chi è piccolo abbastanza da essere una cosa (non un
## palazzo, non il pavimento, non il muro di confine) finisce in un elenco.
## L'elenco è fatto di rettangoli ruotati sul piano — la stessa geometria
## dei palazzi, un grado più generale — e sta in una griglia di celle da
## quattro metri, così chiedere «qui c'è qualcosa?» costa quattro confronti
## e non quattrocento.

## Lato di una cella della griglia di ricerca, in metri.
const CELLA := 4.0
## **E pure 'e mure lunghe.** La prima stesura saltava tutto quello che
## aveva un'impronta sopra ai quattordici metri, «perché è un palazzo, e i
## palazzi li conosce già `Citta`». Ma i palazzi non sono gli unici muri
## lunghi: la piazza ha il suo recinto, lo stadio il suo anello, Mergellina
## il muraglione — e quelli `Citta` non li conosce. Risultato: passanti
## piantati contro il recinto della piazza, sei alla volta. Il pavimento si
## scarta lo stesso per l'altezza (è sotto ai venticinque centimetri), e un
## muro di confine in più nell'elenco non costa niente.
const IMPRONTA_MAX := 400.0
## Sotto a questa altezza ci si passa sopra (un gradino, un tombino), e un
## corpo che comincia sopra a questa quota ci si passa sotto (un balcone,
## un'insegna, una tenda).
const BASSO := 0.25
const SOPRA := 1.9

const Collina := preload("res://scripts/collina.gd")

## Ogni ostacolo: [cx, cz, hx, hz, coseno, seno, tondo]
static var _scatole: Array = []
static var _griglia: Dictionary = {}
## Cresce a ogni cambio: chi si è fatto una mappa (il percorso dei
## passanti) sa così che la deve rifare.
static var versione: int = 0


static func svuota() -> void:
	_scatole.clear()
	_griglia.clear()
	versione += 1


static func quante() -> int:
	return _scatole.size()


## Un rettangolo di mezzo-lati `hx`, `hz`, centrato in (cx, cz) e girato di
## `ang` attorno alla verticale (la stessa convenzione di `rotation.y`).
static func aggiungi(cx: float, cz: float, hx: float, hz: float,
		ang: float = 0.0, tondo: bool = false) -> void:
	var i: int = _scatole.size()
	_scatole.append([cx, cz, hx, hz, cos(ang), sin(ang), tondo])
	var r: float = sqrt(hx * hx + hz * hz)
	var c0 := Vector2i(floori((cx - r) / CELLA), floori((cz - r) / CELLA))
	var c1 := Vector2i(floori((cx + r) / CELLA), floori((cz + r) / CELLA))
	for gx in range(c0.x, c1.x + 1):
		for gz in range(c0.y, c1.y + 1):
			var k := Vector2i(gx, gz)
			if not _griglia.has(k):
				_griglia[k] = []
			(_griglia[k] as Array).append(i)
	versione += 1


## Il punto sta dentro a una cosa, allargata di `orlo`?
static func dentro(p: Vector3, orlo: float = 0.0) -> bool:
	return _chi(p, orlo) >= 0


## Chi lo contiene, o −1.
static func _chi(p: Vector3, orlo: float) -> int:
	var k := Vector2i(floori(p.x / CELLA), floori(p.z / CELLA))
	var lista = _griglia.get(k)
	if lista == null:
		return -1
	for i in lista:
		var s: Array = _scatole[i]
		var dx: float = p.x - float(s[0])
		var dz: float = p.z - float(s[1])
		if bool(s[6]):
			var r: float = float(s[2]) + orlo
			if dx * dx + dz * dz < r * r:
				return i
			continue
		# Nel sistema della scatola: si gira il punto al contrario.
		var c: float = float(s[4])
		var sn: float = float(s[5])
		var lx: float = dx * c - dz * sn
		var lz: float = dx * sn + dz * c
		if absf(lx) < float(s[2]) + orlo and absf(lz) < float(s[3]) + orlo:
			return i
	return -1


## Se il punto è finito dentro a una cosa lo rimette fuori dalla faccia più
## vicina. Una per volta, come `Citta.fore_d_ô_palazzo`: due cose attaccate
## si risolvono al passo dopo.
static func fore(p: Vector3, orlo: float = 0.4) -> Vector3:
	var i: int = _chi(p, orlo)
	if i < 0:
		return p
	var s: Array = _scatole[i]
	var cx: float = float(s[0])
	var cz: float = float(s[1])
	var dx: float = p.x - cx
	var dz: float = p.z - cz
	if bool(s[6]):
		var r: float = float(s[2]) + orlo + 0.01
		var d := Vector2(dx, dz)
		if d.length() < 0.001:
			d = Vector2(1, 0)
		d = d.normalized() * r
		return Vector3(cx + d.x, p.y, cz + d.y)
	var c: float = float(s[4])
	var sn: float = float(s[5])
	var lx: float = dx * c - dz * sn
	var lz: float = dx * sn + dz * c
	var ex: float = float(s[2]) + orlo + 0.01
	var ez: float = float(s[3]) + orlo + 0.01
	if ex - absf(lx) < ez - absf(lz):
		lx = ex * signf(lx if absf(lx) > 0.0001 else 1.0)
	else:
		lz = ez * signf(lz if absf(lz) > 0.0001 else 1.0)
	# E di nuovo nel mondo.
	return Vector3(cx + lx * c + lz * sn, p.y, cz - lx * sn + lz * c)


## Tutti i rettangoli, per chi si deve fare una mappa (`cammino.gd`).
static func tutte() -> Array:
	return _scatole


## **'A rassegna.** Si passano tutti i `StaticBody3D` sotto a `radice` che
## stanno sul livello del mondo, e ogni forma piccola abbastanza da essere
## una cosa finisce nell'elenco. Ritorna quante ne ha prese.
static func censisci(radice: Node, livello: int = 1) -> int:
	svuota()
	var pila: Array = [radice]
	while not pila.is_empty():
		var n: Node = pila.pop_back()
		for c in n.get_children():
			pila.append(c)
		if not (n is StaticBody3D):
			continue
		var corpo := n as StaticBody3D
		if (corpo.collision_layer & livello) == 0:
			continue
		for f in corpo.get_children():
			if f is CollisionShape3D and not (f as CollisionShape3D).disabled:
				_forma(f as CollisionShape3D)
	return _scatole.size()


static func _forma(f: CollisionShape3D) -> void:
	var sh: Shape3D = f.shape
	if sh == null or not f.is_inside_tree():
		return
	var t: Transform3D = f.global_transform
	var sc: Vector3 = t.basis.get_scale()
	var alto: float = 0.0
	var hx: float = 0.0
	var hz: float = 0.0
	var tondo := false
	if sh is BoxShape3D:
		var d: Vector3 = (sh as BoxShape3D).size * sc
		hx = d.x * 0.5
		hz = d.z * 0.5
		alto = d.y
		# **'E rampe se camminano.** Le scalinate del Vomero sono gradini
		# finti sopra a una rampa liscia invisibile — una scatola sottile
		# inclinata a trentasette gradi (vedi `_scalinata`). Presa per il suo
		# ingombro, la rampa diventava un muro alto due metri e mezzo messo
		# di traverso sulla strada, e chi doveva salire restava sotto.
		var n_su: float = absf(t.basis.y.normalized().y)
		if n_su > 0.6 and n_su < 0.985 and d.y < minf(d.x, d.z):
			# Ma una rampa si prende **dai capi**, no di fianco: il suo
			# fianco è un muro che sale da zero a tre metri (ci stanno i
			# muretti di tufo). Si mettono due strisce sottili lungo i lati
			# lunghi, e i due capi restano aperti.
			var fianco := Vector3(t.basis.x.x, 0.0, t.basis.x.z)
			var lungo := Vector3(t.basis.z.x, 0.0, t.basis.z.z)
			if fianco.length() > 0.01 and lungo.length() > 0.01:
				var mezza_l: float = d.z * 0.5 * lungo.length() / t.basis.z.length()
				fianco = fianco.normalized()
				# Verso la cima (l'asse Z della rampa sale: vedi `_scalinata`).
				var su_h: Vector3 = lungo.normalized()
				if t.basis.z.y < 0.0:
					su_h = -su_h
				var ang_f: float = atan2(-fianco.z, fianco.x)
				# **'O piede d''a rampa resta apierto.** Il primo metro
				# della rampa è alto un palmo: da lì si scende di lato come da
				# un marciapiede. Chiudendolo, lo spiazzo fra due rampe e il
				# muraglione diventava una tasca murata da quattro lati, e chi
				# ci cadeva dentro (scivolando giù dal bordo della rampa) non
				# ne usciva più: cinque passanti piantati lì in due minuti.
				var corto: float = 0.9
				for lato in [-1.0, 1.0]:
					var c: Vector3 = t.origin + fianco * (d.x * 0.5 + 0.22) * lato \
						+ su_h * (corto * 0.5)
					aggiungi(c.x, c.z, 0.22, maxf(0.2, mezza_l - corto * 0.5),
						ang_f, false)
			return
	elif sh is CylinderShape3D:
		var cy := sh as CylinderShape3D
		hx = cy.radius * maxf(sc.x, sc.z)
		hz = hx
		alto = cy.height * sc.y
		tondo = true
	elif sh is CapsuleShape3D:
		var ca := sh as CapsuleShape3D
		hx = ca.radius * maxf(sc.x, sc.z)
		hz = hx
		alto = ca.height * sc.y
		tondo = true
	elif sh is SphereShape3D:
		hx = (sh as SphereShape3D).radius * maxf(sc.x, sc.z)
		hz = hx
		alto = hx * 2.0
		tondo = true
	else:
		# Poligoni e maglie: si prende l'ingombro della forma di debug, che
		# Godot sa fare per tutte.
		var dm: ArrayMesh = sh.get_debug_mesh()
		if dm == null:
			return
		var bb: AABB = dm.get_aabb()
		var box2: AABB = Transform3D(t.basis, Vector3.ZERO) * bb
		hx = box2.size.x * 0.5
		hz = box2.size.z * 0.5
		alto = box2.size.y
		t = Transform3D(Basis(), t.origin + box2.get_center())
		if maxf(hx, hz) * 2.0 > IMPRONTA_MAX:
			return
		var b2: float = t.origin.y - alto * 0.5
		if alto < BASSO or t.origin.y + alto * 0.5 < BASSO or b2 > SOPRA:
			return
		aggiungi(t.origin.x, t.origin.z, hx, hz, 0.0, false)
		return
	# Una forma coricata (un cilindro girato su un fianco, un tubo per
	# terra) non ha l'asse verticale: la si prende per il suo ingombro.
	var su: Vector3 = t.basis.y.normalized()
	if absf(su.y) < 0.9:
		var aabb := AABB(Vector3(-hx, -alto * 0.5, -hz), Vector3(hx * 2.0, alto, hz * 2.0))
		var box: AABB = Transform3D(t.basis, Vector3.ZERO) * aabb
		hx = box.size.x * 0.5
		hz = box.size.z * 0.5
		alto = box.size.y
		tondo = false
		t = Transform3D(Basis(), t.origin)
	if maxf(hx, hz) * 2.0 > IMPRONTA_MAX:
		return
	# **'A terra nun è sempe a zero.** Sul terrapieno del Vomero si cammina
	# tre metri più su: una panchina lassù comincia a quota tre, e contata
	# da zero sembrava un balcone. Solo per chi sta *dentro* al terrapieno
	# (un metro dentro al bordo): i muraglioni stanno sul filo, e quelli
	# partono da terra.
	var terra: float = 0.0
	if Collina.dentro(t.origin.x - 1.0, t.origin.z - 1.0) \
			and Collina.dentro(t.origin.x + 1.0, t.origin.z + 1.0):
		terra = Collina.QUOTA
	var basso: float = t.origin.y - alto * 0.5 - terra
	var cima: float = t.origin.y + alto * 0.5 - terra
	if alto < BASSO or cima < BASSO:
		return
	if basso > SOPRA:
		return
	# **E 'a terra stessa nun è 'na cosa.** Il corpo del terrapieno è una
	# scatola di quarantotto metri per quaranta con la faccia di sopra a
	# quota tre: ci si cammina sopra, non contro. Una scatola larga (più di
	# sei metri per lato) e bassa (sotto ai sei metri e mezzo) è terreno.
	if minf(hx, hz) * 2.0 >= 6.0 and t.origin.y + alto * 0.5 <= 6.5 \
			and t.origin.y - alto * 0.5 < 0.0:
		return
	# L'angolo attorno alla verticale: da dove va a finire l'asse X locale.
	var ax: Vector3 = t.basis.x
	var ang: float = atan2(-ax.z, ax.x)
	aggiungi(t.origin.x, t.origin.z, hx, hz, ang, tondo)
