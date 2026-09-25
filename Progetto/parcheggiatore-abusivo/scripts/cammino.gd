extends RefCounted
## **'A strada pe' ghì 'a parte a parte** (0.59).
##
## I passanti hanno un giro fatto di venti tappe sparse per la città, e fino
## alla 0.58 da una tappa all'altra ci andavano **in linea d'aria**. Con i
## palazzi in mezzo. Non se ne accorgeva nessuno per una ragione che fa
## ridere e piangere insieme: il passante era un `CharacterBody3D` **senza
## forma di collisione** — per il motore fisico non esisteva, quindi non
## sbatteva contro niente, quindi `is_on_floor()` era sempre falso, quindi
## la gravità lo tirava giù a ventidue metri al secondo quadro. Due secondi
## dopo essere nato camminava **sotto** alla città. `prova_ntuppate` ne ha
## trovati a cinquantamila metri di profondità, e i «passanti dentro ai
## muri» erano loro, visti da sotto.
##
## Dargli un corpo vuol dire che adesso i muri li fermano — e uno che va
## in linea d'aria verso una tappa dietro a un isolato resta a spingere
## contro la facciata per sempre. Quindi serve una strada.
##
## La città è una griglia di rettangoli, e la strada si cerca su una
## griglia: celle da un metro, piene dove c'è un palazzo o una cosa
## (`ostacoli.gd`), vuote dove si cammina. `AStarGrid2D` fa il resto in
## codice nativo. Poi il percorso si **tira**: dei cento punti che A* dà su
## una traversata si tengono solo gli angoli — da ogni punto si salta al
## più lontano che si vede in linea retta — così chi cammina taglia gli
## incroci in diagonale come una persona, invece di girare a scalini.

const Citta := preload("res://scripts/citta_3d.gd")
const Ostacoli := preload("res://scripts/ostacoli.gd")

## La griglia copre la città più Mergellina, un metro per cella.
const X0: int = -1
const Z0: int = -20
const X1: int = 191
const Z1: int = 173
## **Quanto si sta lontani dai muri, e pecché 'o nummero è chisto.**
## Una cella è libera se il suo *centro* sta lontano dal muro, ma la cella
## è larga un metro: con un orlo di 0,45 il bordo di una cella libera stava
## a cinque centimetri dalla facciata, e la corda tirata fra due centri ci
## passava rasente. Il corpo (raggio 0,26) toccava lo spigolo e ci restava
## attaccato — sei passanti piantati agli angoli degli isolati in due
## minuti. Con 0,8 il punto peggiore di una cella libera sta a trenta
## centimetri dal muro, che è più del mezzo corpo; e un vicolo da quattro
## metri resta largo due celle.
const ORLO_MURI: float = 0.80
const ORLO_COSE: float = 0.55

static var _astar: AStarGrid2D = null
static var _versione: int = -1
## Le celle raggiungibili a piedi da 'O Corso: chi sta fuori da qui (dentro
## all'anello dello stadio, in un cortile chiuso) non ci arriva nessuno.
static var _raggiunte: PackedByteArray = PackedByteArray()
## Un punto che sta sicuramente in strada: 'O Corso, all'altezza del mare.
const SEME := Vector3(78.0, 0.0, 12.0)


static func _cella(p: Vector3) -> Vector2i:
	return Vector2i(clampi(floori(p.x) - X0, 0, X1 - X0 - 1),
		clampi(floori(p.z) - Z0, 0, Z1 - Z0 - 1))


static func _punto(c: Vector2i) -> Vector3:
	return Vector3(float(c.x + X0) + 0.5, 0.0, float(c.y + Z0) + 0.5)


## Rifà la griglia se le cose in strada sono cambiate da l'ultima volta.
static func _prepara() -> void:
	if _astar != null and _versione == Ostacoli.versione:
		return
	_versione = Ostacoli.versione
	var a := AStarGrid2D.new()
	a.region = Rect2i(0, 0, X1 - X0, Z1 - Z0)
	a.cell_size = Vector2(1, 1)
	a.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	a.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	a.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	a.update()
	# Oltre la passeggiata c'è il mare.
	var nord: int = int(ceil(Citta.LIMITE_NORD)) - Z0
	if nord > 0:
		a.fill_solid_region(Rect2i(0, 0, X1 - X0, nord), true)
	# I palazzi: una cella è piena se il suo centro sta dentro all'isolato
	# allargato di mezzo corpo.
	for b in Citta.ISOLATI:
		var x0: int = int(ceil(float(b[0]) - ORLO_MURI - 0.5)) - X0
		var z0: int = int(ceil(float(b[1]) - ORLO_MURI - 0.5)) - Z0
		var x1: int = int(floor(float(b[2]) + ORLO_MURI - 0.5)) - X0
		var z1: int = int(floor(float(b[3]) + ORLO_MURI - 0.5)) - Z0
		a.fill_solid_region(Rect2i(x0, z0, x1 - x0 + 1, z1 - z0 + 1), true)
	# **'O Vommero nun se traversa 'a sotto** (0.59). Il terrapieno sta tre
	# metri più su: per chi cammina a terra è un isolato, e le sei rampe sono
	# già ostacoli. Senza queste righe le celle di sopra risultavano libere
	# ma irraggiungibili, e `vicino_libero` ci mandava chi strusciava sul
	# muraglione: da lassù nessuna strada, e il passante tirava dritto contro
	# il muro (`prova_ntuppate`, accanto al cardine di ponente).
	var cr: Array = Collina.RECT
	var vx0: int = int(ceil(float(cr[0]) - ORLO_MURI - 0.5)) - X0
	var vz0: int = int(ceil(float(cr[1]) - ORLO_MURI - 0.5)) - Z0
	var vx1: int = int(floor(float(cr[2]) + ORLO_MURI - 0.5)) - X0
	var vz1: int = int(floor(float(cr[3]) + ORLO_MURI - 0.5)) - Z0
	a.fill_solid_region(Rect2i(vx0, vz0, vx1 - vx0 + 1, vz1 - vz0 + 1), true)
	# Le cose: ogni cella il cui centro cade dentro al rettangolo girato.
	# Quelle dritte (quasi tutte: muri, recinti, auto in fila) si riempiono
	# in un colpo col metodo nativo; le altre cella per cella, ma solo
	# dentro al loro ingombro.
	for s in Ostacoli.tutte():
		var cx0: float = float(s[0])
		var cz0: float = float(s[1])
		var hx: float = float(s[2])
		var hz: float = float(s[3])
		var co: float = absf(float(s[4]))
		var si: float = absf(float(s[5]))
		var dritto: bool = not bool(s[6]) and (si < 0.02 or co < 0.02)
		if dritto:
			var ex: float = (hx if si < 0.02 else hz) + ORLO_COSE
			var ez: float = (hz if si < 0.02 else hx) + ORLO_COSE
			var i0: int = int(ceil(cx0 - ex - 0.5)) - X0
			var j0: int = int(ceil(cz0 - ez - 0.5)) - Z0
			var i1: int = int(floor(cx0 + ex - 0.5)) - X0
			var j1: int = int(floor(cz0 + ez - 0.5)) - Z0
			if i1 >= i0 and j1 >= j0:
				a.fill_solid_region(Rect2i(i0, j0, i1 - i0 + 1, j1 - j0 + 1), true)
			continue
		var ax: float = hx * co + hz * si + ORLO_COSE
		var az: float = hx * si + hz * co + ORLO_COSE
		var c0 := _cella(Vector3(cx0 - ax, 0, cz0 - az))
		var c1 := _cella(Vector3(cx0 + ax, 0, cz0 + az))
		for cx in range(c0.x, c1.x + 1):
			for cz in range(c0.y, c1.y + 1):
				var q := _punto(Vector2i(cx, cz))
				if Ostacoli.dentro(q, ORLO_COSE):
					a.set_point_solid(Vector2i(cx, cz), true)
	_astar = a
	_allaga()


## **Chi se po' raggiungere.** Un allagamento dalla strada principale: tutte
## le celle libere collegate a 'O Corso. Costa un giro sulla griglia (trenta
## e passa mila celle) una volta sola per versione degli ostacoli.
static func _allaga() -> void:
	var w: int = X1 - X0
	var h: int = Z1 - Z0
	_raggiunte = PackedByteArray()
	_raggiunte.resize(w * h)
	var s := _cella(SEME)
	if _astar.is_point_solid(s):
		return
	var coda: Array = [s]
	_raggiunte[s.y * w + s.x] = 1
	var i := 0
	while i < coda.size():
		var c: Vector2i = coda[i]
		i += 1
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h:
				continue
			var k: int = n.y * w + n.x
			if _raggiunte[k] == 1 or _astar.is_point_solid(n):
				continue
			_raggiunte[k] = 1
			coda.append(n)


## Ci si arriva a piedi dalla strada?
static func raggiungibile(p: Vector3) -> bool:
	_prepara()
	var c := _cella(vicino_libero(p))
	var k: int = c.y * (X1 - X0) + c.x
	return k >= 0 and k < _raggiunte.size() and _raggiunte[k] == 1


static func libera(p: Vector3) -> bool:
	_prepara()
	var c := _cella(p)
	return not _astar.is_point_solid(c)


## La cella libera più vicina a `p`: per chi nasce, o si ritrova, dentro a
## qualcosa. Si cerca ad anelli fino a dieci metri.
static func vicino_libero(p: Vector3) -> Vector3:
	_prepara()
	var c := _cella(p)
	if not _astar.is_point_solid(c):
		return p
	for r in range(1, 11):
		var meglio := Vector2i(-1, -1)
		var md: float = INF
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				if absi(dx) != r and absi(dz) != r:
					continue
				var k := Vector2i(c.x + dx, c.y + dz)
				if not _astar.is_in_boundsv(k) or _astar.is_point_solid(k):
					continue
				var d: float = Vector2(dx, dz).length()
				if d < md:
					md = d
					meglio = k
		if meglio.x >= 0:
			var q := _punto(meglio)
			q.y = p.y
			return q
	return p


## La cella libera **e raggiungibile** più vicina: chi è finito in una
## sacca chiusa (fra un'auto e una vetrina, dietro a un vaso) deve uscire
## da quella parte da cui poi si va da qualche parte, non nella cella
## libera accanto, che magari sta nella stessa sacca.
static func vicino_raggiungibile(p: Vector3) -> Vector3:
	_prepara()
	var w: int = X1 - X0
	var c := _cella(p)
	var k0: int = c.y * w + c.x
	if not _astar.is_point_solid(c) and k0 >= 0 and k0 < _raggiunte.size() \
			and _raggiunte[k0] == 1:
		return p
	for r in range(1, 11):
		var meglio := Vector2i(-1, -1)
		var md: float = INF
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				if absi(dx) != r and absi(dz) != r:
					continue
				var k := Vector2i(c.x + dx, c.y + dz)
				if not _astar.is_in_boundsv(k) or _astar.is_point_solid(k):
					continue
				var kk: int = k.y * w + k.x
				if kk < 0 or kk >= _raggiunte.size() or _raggiunte[kk] != 1:
					continue
				var d: float = Vector2(dx, dz).length()
				if d < md:
					md = d
					meglio = k
		if meglio.x >= 0:
			var q := _punto(meglio)
			q.y = p.y
			return q
	return vicino_libero(p)


## La strada da `da` ad `a`, già tirata: solo i punti dove si gira, e
## l'ultimo è `a` stesso. Vuota se non c'è strada.
static func strada(da: Vector3, a: Vector3) -> PackedVector3Array:
	_prepara()
	var fuori := PackedVector3Array()
	var c0 := _cella(vicino_libero(da))
	var c1 := _cella(vicino_libero(a))
	if c0 == c1:
		fuori.append(a)
		return fuori
	var grezza: PackedVector2Array = _astar.get_point_path(c0, c1)
	if grezza.is_empty():
		return fuori
	var punti: Array = []
	for v in grezza:
		punti.append(Vector3(v.x + float(X0) + 0.5, 0.0, v.y + float(Z0) + 0.5))
	# **'A corda tirata.** Da dove si sta si salta al punto più lontano che
	# si vede dritto; da lì si ricomincia.
	var i := 0
	var ultimo: Vector3 = da
	while i < punti.size() - 1:
		var j: int = punti.size() - 1
		while j > i + 1 and not _si_vede(ultimo, punti[j]):
			j -= 1
		fuori.append(punti[j])
		ultimo = punti[j]
		i = j
	if fuori.is_empty() or fuori[fuori.size() - 1].distance_to(a) > 0.01:
		# L'ultimo punto è la meta vera, non il centro della sua cella.
		if not fuori.is_empty() and _si_vede(fuori[fuori.size() - 1], a):
			fuori[fuori.size() - 1] = a
		else:
			fuori.append(a)
	return fuori


## Dritto da `p` a `q` non si tocca niente? Si campiona ogni quarto di
## metro sulla griglia: a mezzo metro la linea tagliava lo spigolo di una
## cella piena senza che nessun campione ci cadesse dentro.
##
## **E 'a corda nun ha da strusciare** (0.59). Le celle sono di un metro:
## una linea può passare a trenta centimetri da una panchina con tutti i
## campioni in celle libere (il centro della cella sta lontano, lo spigolo
## no). Il passante, che è largo sessanta, ci restava attaccato di fianco —
## `prova_ntuppate` ne ha trovati due, uno contro la panchina del largo e
## uno contro un vaso. Adesso ogni campione guarda pure la cosa vera, con
## mezzo corpo di margine.
const MEZZO_CORPO: float = 0.34


## Per chi segue una strada: da qui quel punto si vede dritto?
static func si_vede_da(p: Vector3, q: Vector3) -> bool:
	_prepara()
	return _si_vede(p, q)


static func _si_vede(p: Vector3, q: Vector3) -> bool:
	var d := Vector2(q.x - p.x, q.z - p.z)
	var n: int = maxi(1, int(ceil(d.length() / 0.25)))
	for k in range(1, n + 1):
		var t: float = float(k) / float(n)
		var campione := Vector3(p.x + d.x * t, 0.0, p.z + d.y * t)
		var c := _cella(campione)
		if _astar.is_point_solid(c):
			return false
		if Ostacoli.dentro(campione, MEZZO_CORPO):
			return false
	return true
