extends Node3D
## StrisceBlu — 'o Comune ha pittato 'e strisce blu (0.64)
##
## Un nodo della città. Guarda `GameManager.strisce_blu` e ne fa cose che si
## vedono: i posti della piazza diventano blu (tranne quelli già
## ripittati), e accanto alle file di posti compaiono i parchimetri. Quando
## sono rotti tutti **e** ripittati tutti, lo dice al GameManager, e la
## piazza torna tua.
##
## **Addò se metteno 'e parchimetre.** Non a caso e non in mezzo: dove li
## metterebbe il Comune, cioè sul bordo esterno di una fila di posti, nello
## spazio fra un posto e l'altro — la macchina non ci passa sopra e chi paga
## ci arriva a piedi. Un parchimetro ogni tre posti, fra due e quattro per
## piazza. Ogni punto si prova col motore fisico prima di piantarlo: se c'è
## già qualcosa (la vetrina del bar, un bidone), si prova un po' più in là,
## o si salta.
##
## Tutto si decide coi numeri della pianta (i posti hanno un indice fisso):
## lo stesso posto dà lo stesso parchimetro tutte le mattine, e l'indice del
## parchimetro rotto ieri è ancora lui.

const ParchimetroScript := preload("res://scripts/parchimetro_3d.gd")

## zona -> [parchimetri costruiti]
var _parchimetri: Dictionary = {}
var _costruite: Dictionary = {}
## **Si chianta a mondo avviato.** Il posto di un parchimetro si prova col
## motore fisico, e prima che la fisica abbia fatto qualche passo ogni
## domanda risponde «libero» (lo stesso guaio di `posteggio_3d`): la
## mattina dopo la città si ricostruisce e il turno parte nello stesso
## fotogramma. Si aspetta mezzo secondo di gioco vero.
var _pronto: bool = false
var _attesa: float = 0.5


func _ready() -> void:
	GameManager.strisce_blu_cambiate.connect(_cambiate)
	var citta := get_parent()
	if citta != null and citta.has_signal("zona_cambiata"):
		citta.zona_cambiata.connect(_zona_cambiata)


## Chi entra in una piazza con le strisce blu lo deve sapere subito, e deve
## sapere quanto manca.
func _zona_cambiata(id: String, _nome: String, _padrone: String) -> void:
	if id == "" or not GameManager.strisce_blu_in(id):
		return
	var e: Dictionary = GameManager.strisce_blu[id]
	var blu := 0
	for s in _posti(id):
		if GameManager.posto_blu(id, int(s.get("indice"))):
			blu += 1
	GameManager.event_started.emit(
		"Ccà ce stanno 'e strisce blu: %d parchimetr%s ancora 'mpiedi, %d post%s da ripittà."
		% [GameManager.parchimetri_sani(id),
			"o" if GameManager.parchimetri_sani(id) == 1 else "e",
			blu, "o" if blu == 1 else "e"])


func _process(delta: float) -> void:
	if _pronto:
		return
	_attesa -= delta
	if _attesa <= 0.0:
		_pronto = true
		_rifai_tutto()


func _rifai_tutto() -> void:
	for z in GameManager.strisce_blu.keys():
		_cambiate(str(z))


func _cambiate(zona: String) -> void:
	if not is_inside_tree() or not _pronto:
		return
	if not GameManager.strisce_blu_in(zona):
		# Finita (o mai cominciata): i posti tornano bianchi. I parchimetri
		# rotti restano dove sono fino a domani: sono il trofeo.
		for s in _posti(zona):
			if s.has_method("metti_blu") and s.get("blu") == true:
				s.metti_blu(false)
		_costruite.erase(zona)
		return
	if not _costruite.has(zona):
		_costruisci(zona)
	for s in _posti(zona):
		var ind: int = int(s.get("indice"))
		var b: bool = GameManager.posto_blu(zona, ind)
		if (s.get("blu") == true) != b:
			s.metti_blu(b)
	_forse_fernuta(zona)


func _posti(zona: String) -> Array:
	var r: Array = []
	for s in get_tree().get_nodes_in_group("parking_spots"):
		if str(s.get("zona_id")) == zona:
			r.append(s)
	return r


## Tutti rotti e tutti ripittati? Allora è finita.
func _forse_fernuta(zona: String) -> void:
	if not GameManager.strisce_blu_in(zona):
		return
	if GameManager.parchimetri_sani(zona) > 0:
		return
	for s in _posti(zona):
		if GameManager.posto_blu(zona, int(s.get("indice"))):
			return
	GameManager.strisce_blu_fernute(zona)


# ---------------------------------------------------------------------------
# Addò se chiantano
# ---------------------------------------------------------------------------

func _costruisci(zona: String) -> void:
	_costruite[zona] = true
	var posti: Array = _posti(zona)
	if posti.is_empty():
		GameManager.conta_parchimetri(zona, 0)
		return
	var centro := Vector3.ZERO
	for s in posti:
		centro += (s as Node3D).global_position
	centro /= float(posti.size())

	# Le file: posti con la stessa x (colonne, macchine una dietro
	# l'altra) o con la stessa z (file di fondo, una accanto all'altra).
	var colonne: Dictionary = {}
	var file: Dictionary = {}
	for s in posti:
		var p: Vector3 = (s as Node3D).global_position
		var kx: int = int(round(p.x * 2.0))
		var kz: int = int(round(p.z * 2.0))
		colonne[kx] = colonne.get(kx, []) + [p]
		file[kz] = file.get(kz, []) + [p]
	var candidati: Array = []
	for k in colonne:
		var col: Array = colonne[k]
		if col.size() < 2:
			continue
		col.sort_custom(func(a, b): return a.z < b.z)
		var fuori: float = signf(col[0].x - centro.x)
		if fuori == 0.0:
			fuori = 1.0
		for i in range(col.size() - 1):
			var zm: float = (col[i].z + col[i + 1].z) * 0.5
			# Il davanti del parchimetro (+Z locale) guarda verso la piazza.
			var giro: float = atan2(-fuori, 0.0)
			candidati.append({"prove": [
				Vector3(col[i].x + fuori * 1.65, 0.0, zm),
				Vector3(col[i].x + fuori * 1.35, 0.0, zm),
				Vector3(col[i].x, 0.0, zm)], "giro": giro})
	for k in file:
		var fi: Array = file[k]
		if fi.size() < 3:
			continue
		fi.sort_custom(func(a, b): return a.x < b.x)
		var fuori2: float = signf(fi[0].z - centro.z)
		if fuori2 == 0.0:
			fuori2 = 1.0
		for i in range(fi.size() - 1):
			var xm: float = (fi[i].x + fi[i + 1].x) * 0.5
			var giro2: float = atan2(0.0, -fuori2)
			candidati.append({"prove": [
				Vector3(xm, 0.0, fi[i].z + fuori2 * 2.75),
				Vector3(xm, 0.0, fi[i].z + fuori2 * 2.45)], "giro": giro2})
	# Quanti: uno ogni tre posti, fra due e quattro. Si provano prima i
	# candidati sparsi in modo uniforme sulle file, poi gli altri in ordine.
	var quanti: int = clampi(int(ceil(float(posti.size()) / 3.0)), 2, 4)
	var fatti: Array = []
	var ordine: Array = []
	for k in range(quanti):
		var j0: int = int(floor(float(k) * float(candidati.size()) / float(quanti)))
		if j0 < candidati.size() and not (j0 in ordine):
			ordine.append(j0)
	for j1 in range(candidati.size()):
		if not (j1 in ordine):
			ordine.append(j1)
	for j in ordine:
		if fatti.size() >= quanti:
			break
		var c: Dictionary = candidati[j]
		for prova in c["prove"]:
			if _chiantabile(prova, posti) and not _troppo_vicino(prova, fatti):
				var pm := _chianta(zona, fatti.size(), prova, float(c["giro"]))
				fatti.append(pm)
				break
	_parchimetri[zona] = fatti
	GameManager.conta_parchimetri(zona, fatti.size())
	print_verbose("StrisceBlu %s: %d parchimetri su %d posti" % [zona, fatti.size(), posti.size()])


func _troppo_vicino(p: Vector3, fatti: Array) -> bool:
	for f in fatti:
		if Vector2(p.x, p.z).distance_to(Vector2((f as Node3D).global_position.x,
				(f as Node3D).global_position.z)) < 3.0:
			return true
	return false


## Ci sta? Niente di fermo lì (strato 1), e non sopra a un posto.
func _chiantabile(p: Vector3, posti: Array) -> bool:
	for s in posti:
		var q: Vector3 = (s as Node3D).global_position
		if absf(q.x - p.x) < 1.1 + 0.3 and absf(q.z - p.z) < 2.2 + 0.25:
			return false
	var mondo := get_world_3d()
	if mondo == null:
		return true
	var y: float = Collina.alzata(p.x, p.z)
	var q2 := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.6, 1.5, 0.6)
	q2.shape = box
	q2.transform = Transform3D(Basis(), Vector3(p.x, y + 0.95, p.z))
	q2.collision_mask = 1
	for h in mondo.direct_space_state.intersect_shape(q2, 4):
		var c = h.get("collider")
		if c is CharacterBody3D:
			continue
		return false
	return true


func _chianta(zona: String, i: int, p: Vector3, giro: float) -> Node3D:
	var pm = ParchimetroScript.new()
	pm.zona_id = zona
	pm.indice = i
	pm.name = "Parchimetro_%s_%d" % [zona, i]
	pm.position = Vector3(p.x, Collina.alzata(p.x, p.z), p.z)
	pm.rotation.y = giro
	add_child(pm)
	if GameManager.parchimetro_rotto(zona, i):
		pm.metti_rotto()
	return pm


## Per le prove e le fotografie.
func parchimetri_di(zona: String) -> Array:
	return _parchimetri.get(zona, [])
