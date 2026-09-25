extends Node
## **Chi sta dint'a chi** (0.59).
##
## `prova_ntuppate` ha trovato i ragazzini del largo piantati contro un
## tavolino della scopa. Il tavolino non ci doveva stare: il campetto è
## stato messo lì alla 0.56, sopra a un tavolo di vecchi (0.44), a una
## partita a scopa vera (0.45), a una panchina e a uno che aspetta. Cinque
## cose nello stesso punto, messe in cinque versioni diverse da cinque
## funzioni che non si parlano.
##
## Questa prova non guarda chi cammina: guarda **le cose ferme fra loro**.
## Prende tutte le impronte solide della città (le stesse di `ostacoli.gd`,
## una per forma, con il corpo a cui appartengono) e cerca le coppie che si
## compenetrano di più di un palmo. Due cose attaccate si toccano sempre un
## poco (una panchina contro il muro); una sedia dentro a un'altra sedia no.

const Citta := preload("res://scripts/citta_3d.gd")

## Quanto si devono compenetrare per contare: quindici centimetri.
const SOGLIA: float = 0.15

var _male: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(150):
		await get_tree().process_frame
	var forme: Array = []
	var citta := get_tree().get_first_node_in_group("citta")
	if citta == null:
		print("nun ce sta 'a città")
		get_tree().quit()
		return
	_raccogli(citta, forme)
	print("=== %d forme solide piccole ===" % forme.size())
	var coppie: Array = []
	for i in range(forme.size()):
		for j in range(i + 1, forme.size()):
			var a: Dictionary = forme[i]
			var b: Dictionary = forme[j]
			if a["corpo"] == b["corpo"]:
				continue
			if (a["corpo"] as Node).is_ancestor_of(b["corpo"]) \
					or (b["corpo"] as Node).is_ancestor_of(a["corpo"]):
				continue
			if Vector2(a["c"]).distance_to(Vector2(b["c"])) > float(a["r"]) + float(b["r"]):
				continue
			# Due cose che si toccano **dentro al muro** di un palazzo (la
			# cornice di una vetrina e un motorino appoggiato alla stessa
			# facciata) non si vedono e non si toccano: chi cammina lì non ci
			# arriva.
			var mezzo: Vector2 = (Vector2(a["c"]) + Vector2(b["c"])) * 0.5
			if Citta.dint_ô_palazzo(Vector3(mezzo.x, 0.0, mezzo.y), 0.0):
				continue
			# E un posto dove si fa qualcosa (il banco del bar, la panchina)
			# ha il suo corpo per il tasto E sopra al corpo della cosa: è la
			# stessa cosa con due forme, non due cose.
			if (_e_posto(a) != _e_posto(b)) \
					and Vector2(a["c"]).distance_to(Vector2(b["c"])) < 0.8:
				continue
			var p: float = _compenetra(a, b)
			if p > SOGLIA:
				coppie.append([p, a, b])
	coppie.sort_custom(func(x, y): return float(x[0]) > float(y[0]))
	for c in coppie:
		_male += 1
		if _male <= 60:
			print("  %.2f m  %s  ⟷  %s" % [float(c[0]), _nome(c[1]), _nome(c[2])])
	_ancore()
	print("=== storte: %d ===" % _male)
	get_tree().quit()


## **'E ccose ca nun so' solide.** Il campetto non ha un collider (ci si
## corre sopra), un vicino nemmeno, e un tavolino della scopa ha il corpo
## solo sotto al piano: la prova dei solidi non li vede. Qui si mettono i
## posti delle attività con il loro raggio vero — quanto occupano per
## starci, non quanto sono duri — e si cercano quelli che si mangiano.
const RAGGI := {
	"bambini": 6.6, "scopa": 1.6, "tavoli_scopa": 1.5, "tre_carte": 1.5,
	"vicine": 0.6, "gente_ferma": 0.6, "spighe": 1.3, "posti_utili": 1.0,
	"cummissiune": 0.8, "maestro": 1.0, "armiere": 1.6,
	"signora_lotto": 0.7, "bacheche": 0.6,
}


func _ancore() -> void:
	print("=== 'E POSTE D''E ATTIVITÀ ===")
	var tutte: Array = []
	for g in RAGGI:
		for n in get_tree().get_nodes_in_group(g):
			if not (n is Node3D):
				continue
			var p: Vector3 = (n as Node3D).global_position
			if p.x > 200.0 or p.z > 200.0:
				continue
			tutte.append([g, n, Vector2(p.x, p.z), float(RAGGI[g])])
	print("  %d poste" % tutte.size())
	for i in range(tutte.size()):
		for j in range(i + 1, tutte.size()):
			var a: Array = tutte[i]
			var b: Array = tutte[j]
			if a[1] == b[1]:
				continue
			var d: float = (a[2] as Vector2).distance_to(b[2])
			var serve: float = float(a[3]) + float(b[3])
			if d < serve - 0.1:
				_male += 1
				print("  %.1f m 'e troppo  %s %s  ⟷  %s %s" % [serve - d,
					str(a[0]), str((a[2] as Vector2).round()),
					str(b[0]), str((b[2] as Vector2).round())])


func _e_posto(x: Dictionary) -> bool:
	var sc: Script = (x["corpo"] as Node).get_script()
	return sc != null and str(sc.resource_path).ends_with("posto_utile.gd")


func _raccogli(radice: Node, fore: Array) -> void:
	var pila: Array = [radice]
	while not pila.is_empty():
		var n: Node = pila.pop_back()
		for c in n.get_children():
			pila.append(c)
		if not (n is StaticBody3D):
			continue
		if ((n as StaticBody3D).collision_layer & 1) == 0:
			continue
		for f in n.get_children():
			if f is CollisionShape3D and not (f as CollisionShape3D).disabled:
				var d := _impronta(f as CollisionShape3D)
				if not d.is_empty():
					d["corpo"] = n
					fore.append(d)


## L'impronta sul piano di una forma: centro, mezzi lati, angolo, tondo.
## Si tengono solo le cose (non i palazzi, non il pavimento, non i muri).
func _impronta(f: CollisionShape3D) -> Dictionary:
	var sh: Shape3D = f.shape
	var t: Transform3D = f.global_transform
	var sc: Vector3 = t.basis.get_scale()
	var hx := 0.0
	var hz := 0.0
	var alto := 0.0
	var tondo := false
	if sh is BoxShape3D:
		var d: Vector3 = (sh as BoxShape3D).size * sc
		hx = d.x * 0.5
		hz = d.z * 0.5
		alto = d.y
		if absf(t.basis.y.normalized().y) < 0.985:
			return {}
	elif sh is CylinderShape3D:
		hx = (sh as CylinderShape3D).radius * maxf(sc.x, sc.z)
		hz = hx
		alto = (sh as CylinderShape3D).height * sc.y
		tondo = true
	elif sh is CapsuleShape3D:
		hx = (sh as CapsuleShape3D).radius * maxf(sc.x, sc.z)
		hz = hx
		alto = (sh as CapsuleShape3D).height * sc.y
		tondo = true
	else:
		return {}
	# Solo cose: né palazzi (sopra ai sei metri), né muri lunghi, né il
	# pavimento, né roba sospesa.
	if alto > 6.0 or maxf(hx, hz) > 5.0 or alto < 0.25:
		return {}
	if t.origin.y - alto * 0.5 > 1.9 or t.origin.y + alto * 0.5 < 0.25:
		return {}
	# Dentro casa (il vascio sta a trecento metri, fuori dalla pianta) le
	# cose stanno appoggiate al pavimento della stanza: non contano.
	if t.origin.x > 200.0 or t.origin.z > 200.0:
		return {}
	var ax: Vector3 = t.basis.x
	return {"c": Vector2(t.origin.x, t.origin.z), "hx": hx, "hz": hz,
		"ang": atan2(-ax.z, ax.x), "tondo": tondo,
		"r": sqrt(hx * hx + hz * hz)}


## Di quanto si compenetrano due impronte (0 se non si toccano). Per le
## scatole il teorema degli assi separatori: la sovrapposizione minima sui
## quattro assi. Il tondo si tratta come il quadrato che lo contiene, che
## per questa prova basta.
func _compenetra(a: Dictionary, b: Dictionary) -> float:
	if bool(a["tondo"]) and bool(b["tondo"]):
		var d: float = Vector2(a["c"]).distance_to(Vector2(b["c"]))
		return maxf(0.0, float(a["hx"]) + float(b["hx"]) - d)
	var assi: Array = []
	for x in [a, b]:
		var an: float = float(x["ang"])
		assi.append(Vector2(cos(an), -sin(an)))
		assi.append(Vector2(sin(an), cos(an)))
	var minimo := INF
	for asse in assi:
		var pa: Vector2 = _proietta(a, asse)
		var pb: Vector2 = _proietta(b, asse)
		var o: float = minf(pa.y, pb.y) - maxf(pa.x, pb.x)
		if o <= 0.0:
			return 0.0
		minimo = minf(minimo, o)
	return minimo


func _proietta(x: Dictionary, asse: Vector2) -> Vector2:
	var c: Vector2 = x["c"]
	var an: float = float(x["ang"])
	var ux := Vector2(cos(an), -sin(an)) * float(x["hx"])
	var uz := Vector2(sin(an), cos(an)) * float(x["hz"])
	var m: float = c.dot(asse)
	var r: float = absf(ux.dot(asse)) + absf(uz.dot(asse))
	return Vector2(m - r, m + r)


func _nome(x: Dictionary) -> String:
	var n: Node = x["corpo"]
	var desc := str(n.name)
	var p: Node = n.get_parent()
	var sc: Script = n.get_script()
	if sc == null and p != null:
		sc = p.get_script()
		desc = str(p.name) + "/" + desc
	if sc != null:
		desc += " [%s]" % str(sc.resource_path).get_file()
	var c: Vector2 = x["c"]
	return "%s (%.1f, %.1f) %.1f×%.1f" % [desc, c.x, c.y,
		float(x["hx"]) * 2.0, float(x["hz"]) * 2.0]
