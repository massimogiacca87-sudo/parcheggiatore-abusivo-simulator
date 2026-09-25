extends Node
class_name Models
## Models
## Ponte fra la grafica procedurale e i modelli 3D veri.
##
## Ogni entità del gioco, prima di costruirsi con box e cilindri, chiede qui
## se esiste un modello esterno con il suo nome. Se il file c'è, viene usato
## quello; se non c'è, si ricade sulla geometria procedurale. Quindi per
## sostituire la grafica basta mettere i file in assets/models/ — nessuna
## modifica al codice.
##
## Vedi assets/models/LEGGIMI.md per i nomi attesi, le dimensioni e
## l'orientamento richiesto.

const DIR := "res://assets/models/"
## **`.scn` e `.mesh` dalla 0.59.** I modelli fino alla 0.58 erano `.glb`
## importati; il container su cui si lavorava è stato riciclato, e i `.glb`
## elaborati (rinominati, riscalati, costruiti in Blender) esistevano solo
## dentro alla build. Sono stati recuperati dal `.pck` della v0.58 come
## **scene native di Godot** — bit per bit quello che il gioco caricava,
## scala e animazioni comprese. Si cercano dopo `.glb`, così un modello
## nuovo con lo stesso nome vince su quello recuperato.
const EXTENSIONS := [".glb", ".gltf", ".tscn", ".scn", ".obj", ".mesh",
	".fbx", ".dae"]

static var _missing_logged: Dictionary = {}


## Ritorna true se per questo nome esiste un modello esterno.
static func has_model(model_name: String) -> bool:
	return _find_path(model_name) != ""


static func _find_path(model_name: String) -> String:
	for ext in EXTENSIONS:
		var path: String = DIR + model_name + str(ext)
		if ResourceLoader.exists(path):
			return path
	return ""


## Istanzia il modello esterno, se esiste; altrimenti ritorna null e chi
## chiama costruisce la propria geometria procedurale.
## scale_to_height: se > 0, il modello viene riscalato uniformemente perché
## la sua altezza corrisponda a quella indicata (in metri). Serve a montare
## modelli fatti in scale diverse senza doverli ritoccare.
static func spawn(model_name: String, scale_to_height: float = 0.0) -> Node3D:
	var path := _find_path(model_name)
	if path == "":
		return null

	var res := load(path)
	if res == null:
		return null

	var node: Node3D = null
	if res is PackedScene:
		node = res.instantiate() as Node3D
	elif res is Mesh:
		var mi := MeshInstance3D.new()
		mi.mesh = res
		node = mi
	if node == null:
		return null

	if scale_to_height > 0.0:
		var aabb := _aabb_of(node)
		if aabb.size.y > 0.001:
			var factor: float = scale_to_height / aabb.size.y
			node.scale = Vector3.ONE * factor
	return node


## Come spawn(), ma invece dell'altezza si dà la LUNGHEZZA voluta (asse Z).
## Per i veicoli è la misura giusta: due auto alte uguali possono essere
## lunghe il doppio l'una dell'altra, e scalare sull'altezza le deforma.
## Se il modello è già della misura giusta (quelli in assets/models lo sono)
## si passa 0 e non viene toccato.
static func spawn_by_length(model_name: String, target_length: float = 0.0) -> Node3D:
	var node := spawn(model_name, 0.0)
	if node == null:
		return null
	if target_length > 0.0:
		var aabb := _aabb_of(node)
		if aabb.size.z > 0.001:
			node.scale = Vector3.ONE * (target_length / aabb.size.z)
	return node


## Misure reali del modello già istanziato (larghezza, altezza, lunghezza),
## scala compresa. Serve a chi deve piazzarci sopra qualcosa.
static func size_of(node: Node3D) -> Vector3:
	var aabb := _aabb_of(node)
	return aabb.size * node.scale


# ---------------------------------------------------------------------------
# Ritocco dei materiali
# ---------------------------------------------------------------------------
# I modelli esterni arrivano con i materiali del loro autore. Qui sotto ci
# sono gli attrezzi per adattarli al gioco senza toccare i file: si lavora
# per NOME del materiale (Godot conserva quello del .mtl) e si scrive sempre
# su una copia, perché lo stesso materiale è condiviso da tutte le istanze
# dello stesso modello — modificarlo in place ricolorerebbe ogni auto della
# piazza insieme a quella presa a pugni.

## Applica una funzione a ogni superficie di ogni mesh dell'albero.
## Il callable riceve (nome_materiale, materiale_copia) e ritorna true se
## l'ha modificato (nel qual caso la copia viene installata come override).
static func _for_each_surface(node: Node, fn: Callable) -> void:
	for mi in _all_mesh_instances(node):
		var mesh: Mesh = mi.mesh
		if mesh == null:
			continue
		for i in mesh.get_surface_count():
			var base: Material = mi.get_active_material(i)
			if base == null:
				continue
			var copy: Material = base.duplicate()
			var mat_name: String = base.resource_name
			if fn.call(mat_name, copy):
				mi.set_surface_override_material(i, copy)


## Ricolora le superfici il cui nome contiene una delle parole indicate.
## Es. tint(auto, ["body", "carroz"], Color.RED) ridipinge la carrozzeria
## lasciando stare vetri, gomme e cromature.
static func tint(node: Node3D, keywords: Array, color: Color,
		metallic: float = -1.0, roughness: float = -1.0) -> void:
	_for_each_surface(node, func(mat_name: String, mat: Material) -> bool:
		if not (mat is StandardMaterial3D):
			return false
		var lower := mat_name.to_lower()
		var hit := false
		for k in keywords:
			if lower.contains(str(k)):
				hit = true
				break
		if not hit:
			return false
		mat.albedo_color = color
		if metallic >= 0.0:
			mat.metallic = metallic
		if roughness >= 0.0:
			mat.roughness = roughness
		# Vernice per auto: sotto c'è il colore, sopra c'è il trasparente.
		# È quel secondo strato — che riflette il cielo bianco anche dove la
		# carrozzeria è blu scuro — a far sembrare una macchina una macchina
		# e non un pezzo di plastica colorata.
		mat.clearcoat_enabled = true
		mat.clearcoat = 0.65
		mat.clearcoat_roughness = 0.08
		mat.rim_enabled = true
		mat.rim = 0.25
		return true)


## Scurisce TUTTE le superfici: è così che si vede che un'auto le ha prese.
static func darken(node: Node3D, amount: float) -> void:
	_for_each_surface(node, func(_mat_name: String, mat: Material) -> bool:
		if not (mat is StandardMaterial3D):
			return false
		mat.albedo_color = mat.albedo_color.darkened(amount)
		return true)


## Ritocco generico per famiglia di materiali: vetri lucidi e scuri,
## cromature metalliche, fari che brillano appena. I modelli scaricati da
## internet arrivano quasi sempre con tutto opaco e piatto.
static func polish_vehicle(node: Node3D) -> void:
	_for_each_surface(node, func(mat_name: String, mat: Material) -> bool:
		if not (mat is StandardMaterial3D):
			return false
		var n := mat_name.to_lower()
		if n.contains("glass") or n.contains("window") or n.contains("vetro"):
			mat.albedo_color = Color(0.08, 0.11, 0.15)
			mat.metallic = 0.9
			mat.roughness = 0.06
			return true
		if n.contains("chrom") or n.contains("mirror") or n.contains("wheel") \
				or n.contains("cerchi"):
			mat.metallic = 0.85
			mat.roughness = 0.25
			return true
		if n.contains("tire") or n.contains("gomm") or n.contains("rubber"):
			mat.albedo_color = Color(0.06, 0.06, 0.07)
			mat.metallic = 0.0
			mat.roughness = 0.95
			return true
		if n.contains("light") or n.contains("faro") or n.contains("lamp"):
			mat.emission_enabled = true
			mat.emission = mat.albedo_color
			mat.emission_energy_multiplier = 0.5
			return true
		return false)


## Bounding box complessivo di un albero di mesh (per la scalatura).
static func _aabb_of(node: Node) -> AABB:
	var result := AABB()
	var first := true
	for child in _all_mesh_instances(node):
		var box: AABB = child.get_aabb()
		box = child.transform * box
		if first:
			result = box
			first = false
		else:
			result = result.merge(box)
	return result


static func _all_mesh_instances(node: Node) -> Array:
	var out: Array = []
	if node is MeshInstance3D:
		out.append(node)
	for child in node.get_children():
		out.append_array(_all_mesh_instances(child))
	return out


# ---------------------------------------------------------------------------
# Le ruote che girano
# ---------------------------------------------------------------------------

## **Perché le ruote vanno staccate a colpi di forbice.**
##
## Un'auto scaricata da internet non ha quattro nodi "ruota". E non ha
## nemmeno un nodo "ruota" e basta: ha **una superficie per materiale**,
## tutte dentro alla stessa mesh. Misurato sui modelli di questo progetto:
##
##   car_berlina  → 8 superfici: Body, Black, Window, Bumpers, Lights,
##                  Bottom, **Tires**, **Wheels**
##   car_economica→ 7 superfici: car body, glass, headlight, … **wheels**
##   auto_pack_1  → 4 nodi separati: body_1, glass_1, **wheel_1**, **tire_1**
##
## Il primo tentativo filtrava sul NOME DEL NODO. Sui `.glb` del pack
## funzionava; sui tre `.obj` — cioè le auto dei clienti, quelle che si
## muovono davvero — il nodo si chiama `@MeshInstance3D@9041` e non c'era
## niente da filtrare: zero perni, ruote ferme. Adesso si guarda il nome
## della SUPERFICIE (che Godot prende dal materiale), e si prende anche il
## nome del nodo come rete di sicurezza.
##
## Poi, comunque sia messa, la geometria delle ruote va tagliata in
## quattro: tutti e quattro i cerchi stanno in un pezzo solo con l'origine
## al centro dell'auto, e farla girare non fa girare le ruote — fa
## **orbitare quattro ruote attorno al centro dell'auto**. Ogni triangolo
## va nel quadrante deciso dal segno del suo baricentro in X e in Z
## (davanti/dietro, destra/sinistra), ogni quadrante diventa una mesh sua
## ricentrata sul proprio mozzo, appesa a un perno.
##
## La mesh visibile viene ricostruita senza le superfici delle ruote: se
## restassero, si vedrebbero due volte — ferme al posto loro e giranti sui
## perni.
##
## Funziona anche con l'Ape, che di ruote ne ha tre: i quadranti vuoti si
## saltano da soli.
##
## Ritorna la lista dei perni, con dentro il raggio misurato e la posa di
## riposo: chi la usa deve solo ruotarli di `spazio / raggio`.
const PAROLE_RUOTA := ["wheel", "tire", "tyre", "ruota", "gomm", "rim",
	"cerchi", "wheels", "tires"]


static func _e_ruota(testo: String) -> bool:
	var t := testo.to_lower()
	for w in PAROLE_RUOTA:
		if t.contains(w):
			return true
	return false


static func stacca_ruote(node: Node3D) -> Array:
	var perni: Array = []
	for mi in _all_mesh_instances(node):
		var am := mi.mesh as ArrayMesh
		if am == null or am.get_surface_count() == 0:
			continue
		var padre: Node = mi.get_parent()
		if padre == null:
			continue
		var nodo_e_ruota: bool = _e_ruota(String(mi.name))

		var tenute: Array = []   # superfici da tenere sulla carrozzeria
		var ruote: Array = []    # superfici da trasformare in perni
		for i in range(am.get_surface_count()):
			var arr: Array = am.surface_get_arrays(i)
			if arr.is_empty() or arr[Mesh.ARRAY_VERTEX] == null:
				continue
			var mat: Material = mi.get_active_material(i)
			var etichetta := am.surface_get_name(i)
			if mat != null:
				etichetta += " " + mat.resource_name
			var voce := {"arr": arr, "mat": mat, "nome": am.surface_get_name(i)}
			if nodo_e_ruota or _e_ruota(etichetta):
				ruote.append(voce)
			else:
				tenute.append(voce)
		if ruote.is_empty():
			continue

		# I perni, uno per quadrante di ogni superficie-ruota.
		for r in ruote:
			for g in _quadranti(r["arr"]):
				var perno := Node3D.new()
				perno.name = "perno_ruota"
				perno.transform = mi.transform.translated_local(g["centro"])
				padre.add_child(perno)
				var nuovo := MeshInstance3D.new()
				nuovo.mesh = g["mesh"]
				if r["mat"] != null:
					nuovo.set_surface_override_material(0, r["mat"])
				perno.add_child(nuovo)
				perni.append({"perno": perno,
					"raggio": maxf(0.12, float(g["raggio"])),
					"riposo": perno.basis})

		# La carrozzeria, ricostruita senza le ruote. Se non resta niente
		# (il caso dei `.glb`, dove la ruota è un nodo per conto suo) il
		# nodo si spegne e basta.
		if tenute.is_empty():
			mi.visible = false
			continue
		var resto := ArrayMesh.new()
		for k in range(tenute.size()):
			var t: Dictionary = tenute[k]
			resto.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, t["arr"])
			resto.surface_set_name(k, str(t["nome"]))
		mi.mesh = resto
		# I materiali si riattaccano ai NUOVI indici: `polish_vehicle` e
		# `tint` hanno già girato prima di qui e avevano messo gli override
		# sugli indici vecchi, che adesso sono sfalsati.
		for k in range(tenute.size()):
			mi.set_surface_override_material(k, tenute[k]["mat"])
	return perni


## Divide la geometria di una superficie in quadranti per segno di X e Z del
## baricentro del triangolo. Ritorna, per ogni quadrante non vuoto, la mesh
## ricentrata, il centro del mozzo e il raggio.
static func _quadranti(arr: Array) -> Array:
	var vert: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var norm = arr[Mesh.ARRAY_NORMAL]
	var idx = arr[Mesh.ARRAY_INDEX]
	var secchi: Dictionary = {}
	var n_tri: int = (idx.size() if idx != null else vert.size()) / 3
	for t in range(n_tri):
		var i0: int
		var i1: int
		var i2: int
		if idx != null:
			i0 = idx[t * 3]; i1 = idx[t * 3 + 1]; i2 = idx[t * 3 + 2]
		else:
			i0 = t * 3; i1 = t * 3 + 1; i2 = t * 3 + 2
		var c: Vector3 = (vert[i0] + vert[i1] + vert[i2]) / 3.0
		var k := Vector2i(1 if c.x >= 0.0 else -1, 1 if c.z >= 0.0 else -1)
		if not secchi.has(k):
			secchi[k] = {"v": PackedVector3Array(), "n": PackedVector3Array()}
		var b: Dictionary = secchi[k]
		for i in [i0, i1, i2]:
			b["v"].append(vert[i])
			if norm != null and i < norm.size():
				b["n"].append(norm[i])
	var out: Array = []
	for k in secchi:
		var b: Dictionary = secchi[k]
		var v: PackedVector3Array = b["v"]
		if v.size() < 12:
			continue # scheggia: non è una ruota
		var box := AABB(v[0], Vector3.ZERO)
		for p in v:
			box = box.expand(p)
		var centro: Vector3 = box.get_center()
		var ricentrati := PackedVector3Array()
		for p in v:
			ricentrati.append(p - centro)
		var arr2 := []
		arr2.resize(Mesh.ARRAY_MAX)
		arr2[Mesh.ARRAY_VERTEX] = ricentrati
		var nn: PackedVector3Array = b["n"]
		if nn.size() == v.size():
			arr2[Mesh.ARRAY_NORMAL] = nn
		var am2 := ArrayMesh.new()
		am2.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr2)
		out.append({"mesh": am2, "centro": centro,
			"raggio": maxf(box.size.y, box.size.z) * 0.5})
	return out
