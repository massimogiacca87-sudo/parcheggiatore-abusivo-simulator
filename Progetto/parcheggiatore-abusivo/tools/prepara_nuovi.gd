extends SceneTree
## **'A robba nova d''a 0.59: da quattro pacchetti a `assets/models/`.**
##
## Il capo ha messo in cartella quattro pacchetti: *Car Pack* (sette auto),
## *Low Poly Animated Humans* (otto uomini con undici animazioni),
## *Animated Human* di Quaternius (un corpo, nove animazioni, sei vestiti) e
## il *Pandazole Lowpoly Asset Bundle* (1867 pezzi in un file solo). Questo
## script li trasforma in quello che il gioco sa caricare, e **si rilancia**:
## se un giorno cambia una misura, si cambia qui e si rifà tutto.
##
## **Come si usa.** Non gira dentro al progetto del gioco, perché i
## sorgenti (venticinque mega di FBX) non devono finire nella build. Si
## prepara un progetto di lavoro con questa struttura:
##
##   res://sorgenti/auto/*.fbx          (Car Pack, cartella FBX)
##   res://sorgenti/omini/*.fbx         (Low Poly Animated Humans, FBX)
##   res://sorgenti/umano/animated_human.fbx
##   res://sorgenti/panda/pandazole.fbx (Pandazole_Lowpoly_Asset_Bundle.fbx)
##   res://assets/models/pandazole.png  (PandaMat.png, rinominata)
##   res://assets/models/umano_q_1..6.png (i sei Clothed*.png di Quaternius)
##
## si fa girare una volta `godot --headless --import`, poi
## `godot --headless --script res://prepara_nuovi.gd`, e si copia nel gioco
## tutto quello che è comparso in `res://assets/models/` (compresi i
## `.import` delle png: portano l'uid con cui le scene le ritrovano).
##
## **Cosa fa con ognuno.**
##
## * **Auto** — cuoce ogni trasformazione dentro ai vertici (il file è Z-su
##   e ogni pezzo ha il suo perno), trova da solo dove sta il muso (dal
##   baricentro dei fari: la regola della 0.46, «non si indovina, si
##   guarda»), gira il muso verso −Z, appoggia le gomme a terra e
##   rinomina i materiali coi nomi che `models.gd` capisce: `body` si
##   vernicia, `glass` si scurisce, le ruote si staccano e girano.
## * **Omini** — le undici clip si rinominano (`HumanArmature|Man_Walk` →
##   `Walk`) e finiscono in **una** libreria condivisa dagli otto corpi.
## * **Umano Quaternius** — lo stesso, e le sei tinte restano fuori: le
##   sceglie il gioco a ogni persona.
## * **Pandazole** — ogni pezzo scelto diventa una `.mesh` con la sua
##   trasformazione cotta dentro, la base a quota zero, la scala giusta (il
##   pacchetto mescola cinque scale diverse: un martello lungo un metro,
##   una chiave di mezzo metro) e **un solo materiale condiviso** con
##   l'atlante dei colori, così mille pezzi in città costano pochissime
##   chiamate di disegno.

const SORGENTI := "res://sorgenti/"
const USCITA := "res://assets/models/"

# ---------------------------------------------------------------------------
# 'E MACHINE
# ---------------------------------------------------------------------------

## nome nel gioco: [file, {materiale originale: nome nuovo}, lunghezza voluta]
## Lunghezza 0 = com'è nel file (sono già in metri veri).
const AUTO := {
	# Il nome `car_berlina`, `car_economica` e `car_lusso` il gioco li
	# chiamava già (auto in sosta, macchina dei vigili) e non esistevano
	# più dalla 0.46: adesso ci sono.
	"car_berlina": ["NormalCar1", {"Blue": "body"}, 0.0],
	"car_economica": ["NormalCar2", {"LightBlue": "body", "Material.007": "body_2"}, 0.0],
	"car_lusso": ["SUV", {"White": "body", "Black": "trim"}, 0.0],
	"car_sportiva2": ["SportsCar", {"Orange": "body", "DarkOrange": "body_2"}, 0.0],
	"car_coupe2": ["SportsCar2", {"White": "body"}, 0.0],
	# 'O taxi 'e Napule è bianco: 'a vernice la mette il gioco.
	"car_taxi": ["Taxi", {"Yellow": "body"}, 0.0],
	# La gazzella dei carabinieri: nera e bianca nel file, blu notte nel
	# gioco (tutte e due le tinte si chiamano `body`). È più corta delle
	# altre (3,73): si porta a 4,25, che è una berlina vera.
	"car_carabinieri": ["Cop", {"Black": "body", "White": "body_2",
		"BlueLights": "light_bar_blu", "WhiteLights": "light_bar_blu_2"}, 4.25],
}
## Nomi che valgono per tutte.
const MATERIALI_AUTO := {
	"Windows": "glass", "Headlights": "headlight", "TailLights": "taillight",
	"Grey": "chrome", "Black": "trim",
}


func _initialize() -> void:
	await process_frame
	var cosa: String = OS.get_environment("PREPARA")
	if cosa == "" or cosa.contains("auto"):
		_auto()
	if cosa == "" or cosa.contains("omini"):
		_omini()
	if cosa == "" or cosa.contains("umano"):
		_umano()
	if cosa == "" or cosa.contains("panda"):
		await _pandazole()
	print("=== FATTO ===")
	quit()


func _auto() -> void:
	print("=== 'E MACHINE ===")
	for nome in AUTO:
		var dati: Array = AUTO[nome]
		var ps: PackedScene = load(SORGENTI + "auto/%s.fbx" % str(dati[0]))
		if ps == null:
			print("  NUN SE CARICA ", dati[0])
			continue
		var sorgente: Node3D = ps.instantiate()
		get_root().add_child(sorgente)
		var pezzi: Array = []   # [nome_nodo, mesh, trasformazione]
		for m in sorgente.find_children("*", "MeshInstance3D", true, false):
			var mi: MeshInstance3D = m
			pezzi.append([str(mi.name), mi.mesh,
				sorgente.global_transform.affine_inverse() * mi.global_transform])
		var mappa: Dictionary = MATERIALI_AUTO.duplicate()
		mappa.merge(dati[1], true)
		var radice := _costruisci_auto(nome, pezzi, mappa, float(dati[2]))
		sorgente.free()
		if radice == null:
			continue
		_salva_scena(radice, USCITA + nome + ".scn")
		radice.free()


## Vertici di tutti i pezzi, già portati nel sistema della radice.
func _vertici(mesh: Mesh, t: Transform3D) -> PackedVector3Array:
	var fuori := PackedVector3Array()
	for s in mesh.get_surface_count():
		var arr: Array = mesh.surface_get_arrays(s)
		for v in arr[Mesh.ARRAY_VERTEX]:
			fuori.append(t * v)
	return fuori


func _baricentro(punti: PackedVector3Array) -> Vector3:
	var c := Vector3.ZERO
	for p in punti:
		c += p
	return c / maxf(1.0, float(punti.size()))


func _costruisci_auto(nome: String, pezzi: Array, mappa: Dictionary,
		lunghezza_voluta: float) -> Node3D:
	# 1. Tutti i vertici, e quelli delle ruote e dei fari a parte.
	var tutti := PackedVector3Array()
	var ruote := PackedVector3Array()
	var fari := PackedVector3Array()
	for p in pezzi:
		var mesh: Mesh = p[1]
		var t: Transform3D = p[2]
		var e_ruota: bool = str(p[0]).to_lower().contains("wheel")
		for s in mesh.get_surface_count():
			var arr: Array = mesh.surface_get_arrays(s)
			var mat: Material = mesh.surface_get_material(s)
			var mn: String = mat.resource_name if mat else ""
			for v in arr[Mesh.ARRAY_VERTEX]:
				var w: Vector3 = t * v
				tutti.append(w)
				if e_ruota:
					ruote.append(w)
				if mn == "Headlights":
					fari.append(w)
	if tutti.is_empty() or ruote.is_empty() or fari.is_empty():
		print("  %s: mancano ruote o fari, salto" % nome)
		return null
	var box := AABB(tutti[0], Vector3.ZERO)
	for v in tutti:
		box = box.expand(v)
	# 2. Gli assi. L'altezza è la misura più corta (una macchina è più larga
	# che alta), la lunghezza la più lunga.
	var s3: Vector3 = box.size
	var assi := [Vector3.RIGHT, Vector3.UP, Vector3.BACK]
	var misure := [s3.x, s3.y, s3.z]
	var i_su: int = 0
	var i_lungo: int = 0
	for i in range(3):
		if misure[i] < misure[i_su]:
			i_su = i
		if misure[i] > misure[i_lungo]:
			i_lungo = i
	var su: Vector3 = assi[i_su]
	var lungo: Vector3 = assi[i_lungo]
	# Il verso del su: le ruote stanno sotto al resto.
	var c_tutti: Vector3 = _baricentro(tutti)
	if (_baricentro(ruote) - c_tutti).dot(su) > 0.0:
		su = -su
	# Il muso: dove stanno i fari.
	var muso: Vector3 = lungo
	if (_baricentro(fari) - c_tutti).dot(lungo) < 0.0:
		muso = -lungo
	# Base nuova: y = su, z = dietro (il muso va a −Z), x = y × z.
	var ny: Vector3 = su
	var nz: Vector3 = -muso
	var nx: Vector3 = ny.cross(nz).normalized()
	var giro := Basis(nx, ny, nz).transposed()   # vecchio → nuovo
	# 3. Misure nuove, scala, e appoggio a terra.
	var box2 := AABB(giro * tutti[0], Vector3.ZERO)
	for v in tutti:
		box2 = box2.expand(giro * v)
	var scala: float = 1.0
	if lunghezza_voluta > 0.0:
		scala = lunghezza_voluta / box2.size.z
	var spost := Vector3(-box2.get_center().x, -box2.position.y,
		-box2.get_center().z) * scala
	var finale := Transform3D(giro.scaled(Vector3.ONE * scala), spost)
	print("  %-16s %.2f × %.2f × %.2f m  (scala %.2f)" % [nome,
		box2.size.x * scala, box2.size.y * scala, box2.size.z * scala, scala])
	# 4. I nodi nuovi: carrozzeria e ruote, con i materiali rinominati.
	var radice := Node3D.new()
	radice.name = nome
	for p in pezzi:
		var mesh: Mesh = p[1]
		var t: Transform3D = finale * (p[2] as Transform3D)
		var st_nome: String = str(p[0]).to_lower()
		var nodo_nome := "body"
		if st_nome.contains("wheel"):
			if st_nome.contains("back"):
				nodo_nome = "wheel_post"
			elif st_nome.contains("left"):
				nodo_nome = "wheel_ant_sx"
			else:
				nodo_nome = "wheel_ant_dx"
		var nuova := ArrayMesh.new()
		for s in mesh.get_surface_count():
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			st.append_from(mesh, s, t)
			var arr: Array = _normali_a_posto(st.commit_to_arrays())
			nuova.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			var vecchio: Material = mesh.surface_get_material(s)
			var mn: String = vecchio.resource_name if vecchio else "trim"
			var nn: String = str(mappa.get(mn, mn.to_lower()))
			if nodo_nome.begins_with("wheel"):
				nn = "wheel_rim" if mn == "Grey" else "tire"
			var mat := StandardMaterial3D.new()
			mat.resource_name = nn
			if vecchio is StandardMaterial3D:
				mat.albedo_color = (vecchio as StandardMaterial3D).albedo_color
			mat.roughness = 0.55
			nuova.surface_set_material(s, mat)
			nuova.surface_set_name(s, nn)
		var mi := MeshInstance3D.new()
		mi.name = nodo_nome
		mi.mesh = nuova
		radice.add_child(mi)
	return radice


## `append_from` porta le normali con la trasformazione, **scala compresa**:
## una mesh rimpicciolita del quaranta per cento esce con le normali lunghe
## 0,6, e la luce ci cade sopra più scura. Si rimettono lunghe uno.
func _normali_a_posto(arr: Array) -> Array:
	var n = arr[Mesh.ARRAY_NORMAL]
	if n is PackedVector3Array:
		var nn: PackedVector3Array = n
		for i in nn.size():
			if nn[i].length_squared() > 0.0:
				nn[i] = nn[i].normalized()
		arr[Mesh.ARRAY_NORMAL] = nn
	return arr


## **Staccato dal file d'origine.** Un nodo istanziato da un `.fbx` porta
## con sé il percorso del file, e le sue mesh stanno dentro alla cache
## dell'importatore: impacchettandolo così com'è, la scena salvata sarebbe
## una scena *ereditata* dall'FBX, con le mesh prese per riferimento — e nel
## gioco, dove gli FBX non ci sono, si aprirebbe vuota. Si toglie il
## percorso a tutti i nodi e si duplicano mesh e pelli, così finisce tutto
## dentro al `.scn`.
func _stacca(n: Node) -> void:
	n.scene_file_path = ""
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh != null:
			mi.mesh = mi.mesh.duplicate(true)
		if mi.skin != null:
			mi.skin = mi.skin.duplicate(true)
	for c in n.get_children():
		_stacca(c)


# ---------------------------------------------------------------------------
# 'E PERZONE
# ---------------------------------------------------------------------------

## I file degli uomini low poly e il nome che avranno nel gioco.
const OMINI := {
	"Male_Casual": "omo_casual", "Male_LongSleeve": "omo_maniche",
	"Male_Shirt": "omo_camicia", "Male_Suit": "omo_giacca",
	"Smooth_Male_Casual": "omo_casual_liscio",
	"Smooth_Male_LongSleeve": "omo_maniche_liscio",
	"Smooth_Male_Shirt": "omo_camicia_liscio",
	"Smooth_Male_Suit": "omo_giacca_liscio",
}
## Le clip, col nome nuovo. Quelle che non stanno qui si buttano.
const CLIP_OMINI := {
	"HumanArmature|Man_Idle": "Idle", "HumanArmature|Man_Walk": "Walk",
	"HumanArmature|Man_Run": "Run", "HumanArmature|Man_Death": "Death",
	"HumanArmature|Man_Sitting": "Sitting", "HumanArmature|Man_Standing": "Standing",
	"HumanArmature|Man_Punch": "Punch", "HumanArmature|Man_SwordSlash": "SwordSlash",
	"HumanArmature|Man_Clapping": "Clapping", "HumanArmature|Man_Jump": "Jump",
	"HumanArmature|Man_RunningJump": "RunningJump",
}
const CLIP_UMANO := {
	"Human Armature|Idle": "Idle", "Human Armature|Walk": "Walk",
	"Human Armature|Run": "Run", "Human Armature|Death": "Death",
	"Human Armature|Punch": "Punch", "Human Armature|Jump": "Jump",
	"Human Armature|Working": "Working",
}
const IN_CICLO := ["Idle", "Walk", "Run", "Clapping", "Working"]


func _omini() -> void:
	print("=== 'E OMMENE LOW POLY ===")
	var libreria: AnimationLibrary = null
	for file in OMINI:
		var ps: PackedScene = load(SORGENTI + "omini/%s.fbx" % file)
		if ps == null:
			print("  NUN SE CARICA ", file)
			continue
		var r: Node3D = ps.instantiate()
		r.name = str(OMINI[file])
		get_root().add_child(r)
		_stacca(r)
		var ap: AnimationPlayer = r.find_children("*", "AnimationPlayer", true, false)[0]
		if libreria == null:
			libreria = _libreria_nova(ap, CLIP_OMINI)
			ResourceSaver.save(libreria, USCITA + "omo_mosse.res")
			libreria = load(USCITA + "omo_mosse.res")
		_metti_libreria(ap, libreria)
		# La cravatta del vestito è una texture a parte (`Tie.png`, nella
		# cartella dei `.blend`): l'FBX la nomina e non la porta. Senza,
		# il petto del vestito esce di un colore solo.
		var cravatta: Texture2D = load(USCITA + "omo_cravatta.png")
		for m2 in r.find_children("*", "MeshInstance3D", true, false):
			var mi2: MeshInstance3D = m2
			for s2 in mi2.mesh.get_surface_count():
				var vecchio: Material = mi2.mesh.surface_get_material(s2)
				if vecchio != null and vecchio.resource_name == "TieTexture":
					var mt := StandardMaterial3D.new()
					mt.resource_name = "TieTexture"
					mt.albedo_texture = cravatta
					mt.roughness = 0.8
					mi2.mesh.surface_set_material(s2, mt)
		var mats: Array = []
		for m in r.find_children("*", "MeshInstance3D", true, false):
			var mi: MeshInstance3D = m
			for s in mi.mesh.get_surface_count():
				var mat: Material = mi.mesh.surface_get_material(s)
				mats.append(mat.resource_name if mat else "-")
		print("  %-22s materiali: %s" % [str(OMINI[file]), str(mats)])
		_salva_scena(r, USCITA + str(OMINI[file]) + ".scn")
		r.free()


func _umano() -> void:
	print("=== L'UMANO 'E QUATERNIUS ===")
	var ps: PackedScene = load(SORGENTI + "umano/animated_human.fbx")
	if ps == null:
		print("  NUN SE CARICA")
		return
	var r: Node3D = ps.instantiate()
	r.name = "umano_q"
	get_root().add_child(r)
	_stacca(r)
	var ap: AnimationPlayer = r.find_children("*", "AnimationPlayer", true, false)[0]
	var lib := _libreria_nova(ap, CLIP_UMANO)
	ResourceSaver.save(lib, USCITA + "umano_q_mosse.res")
	_metti_libreria(ap, load(USCITA + "umano_q_mosse.res"))
	# Il materiale del file non ha la texture (sta in una cartella a
	# parte): si mette la prima tinta, le altre le sceglie il gioco.
	var tex: Texture2D = load(USCITA + "umano_q_1.png")
	for m in r.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = m
		for s in mi.mesh.get_surface_count():
			var mat := StandardMaterial3D.new()
			mat.resource_name = "umano_q"
			mat.albedo_texture = tex
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
			mat.roughness = 0.85
			mi.mesh.surface_set_material(s, mat)
		_scarpe(r, mi)
	_salva_scena(r, USCITA + "umano_q.scn")
	r.free()


## **'E scarpe.** L'umano di Quaternius è **scalzo**: i piedi pescano il
## colore dalla stessa riga della faccia e delle mani. A Napoli in mezzo
## alla strada non cammina nessuno scalzo, e da vicino si nota. I vertici
## dei piedi (il sei per cento più basso del corpo, in posa di riposo) che
## stanno sulla riga della pelle si spostano sulla riga del nero (6-10),
## che è quella degli occhi: scarpe scure, e il resto non cambia.
func _scarpe(r: Node3D, mi: MeshInstance3D) -> void:
	var am := mi.mesh as ArrayMesh
	if am == null:
		return
	var t: Transform3D = r.global_transform.affine_inverse() * mi.global_transform
	var basso := INF
	var alto := -INF
	for s in am.get_surface_count():
		for v in am.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
			var y: float = (t * v).y
			basso = minf(basso, y)
			alto = maxf(alto, y)
	var soglia: float = basso + (alto - basso) * 0.06
	var nuova := ArrayMesh.new()
	var spostati := 0
	for s in am.get_surface_count():
		var arr: Array = am.surface_get_arrays(s)
		var vv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		for i in range(vv.size()):
			if (t * vv[i]).y < soglia and uv[i].y < 6.0 / 32.0:
				uv[i] = Vector2(uv[i].x, 8.5 / 32.0)
				spostati += 1
		arr[Mesh.ARRAY_TEX_UV] = uv
		var fmt: int = am.surface_get_format(s) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		nuova.add_surface_from_arrays(am.surface_get_primitive_type(s), arr,
			[], {}, fmt)
		nuova.surface_set_material(s, am.surface_get_material(s))
		nuova.surface_set_name(s, am.surface_get_name(s))
	mi.mesh = nuova
	print("  scarpe: %d vertici d'e piere spostate 'ncopp'ô nero (sotto a %.2f, altezza %.2f)" % [
		spostati, soglia, alto - basso])


func _libreria_nova(ap: AnimationPlayer, nomi: Dictionary) -> AnimationLibrary:
	var lib := AnimationLibrary.new()
	for vecchio in ap.get_animation_list():
		var chiave: String = str(vecchio)
		if not nomi.has(chiave):
			continue
		var a: Animation = ap.get_animation(vecchio).duplicate(true)
		var nuovo: String = str(nomi[chiave])
		a.resource_name = nuovo
		a.loop_mode = Animation.LOOP_LINEAR if IN_CICLO.has(nuovo) \
			else Animation.LOOP_NONE
		lib.add_animation(nuovo, a)
	print("  libreria: %s" % str(lib.get_animation_list()))
	return lib


func _metti_libreria(ap: AnimationPlayer, lib: AnimationLibrary) -> void:
	for n in ap.get_animation_library_list():
		ap.remove_animation_library(n)
	ap.add_animation_library("", lib)


func _salva_scena(radice: Node, percorso: String) -> void:
	_proprietario(radice, radice)
	var ps := PackedScene.new()
	var err := ps.pack(radice)
	if err != OK:
		print("  PACK FALLITO %s (%d)" % [percorso, err])
		return
	err = ResourceSaver.save(ps, percorso)
	print("  %s %s" % ["salvato" if err == OK else "NUN SALVATO", percorso])


func _proprietario(n: Node, r: Node) -> void:
	for c in n.get_children():
		c.owner = r
		_proprietario(c, r)


# ---------------------------------------------------------------------------
# 'O PANDAZOLE
# ---------------------------------------------------------------------------

## nome nel gioco: [pezzi del file, scala]. La scala porta il pezzo a misura
## vera; `prova_pandazole` la ricontrolla contro le misure attese.
const PANDA := {
	# --- ncopp'ê tetti ---
	"cisterna_1": [["CTP_Prop_RoofWaterStore_01"], 0.85],
	"cisterna_2": [["CTP_Prop_RoofWaterStore_02"], 0.80],
	"cisterna_3": [["CTP_Prop_RoofWaterStore_03"], 0.75],
	"comignolo_1": [["CTP_Prop_Chimney_01"], 1.0],
	"comignolo_2": [["CTP_Prop_Chimney_02"], 1.0],
	"comignolo_3": [["CTP_Prop_Chimney_03"], 1.0],
	"sfiato_1": [["CTP_Prop_RoofVent_01"], 1.0],
	"sfiato_2": [["CTP_Prop_RoofVent_02"], 1.0],
	"sfiato_3": [["CTP_Prop_RoofVent_04"], 1.0],
	"sfiato_4": [["CTP_Prop_RoofVent_06"], 1.0],
	"sfiato_5": [["CTP_Prop_RoofVent_07"], 1.0],
	"sfiato_6": [["CTP_Prop_RoofVent_09"], 1.0],
	"lucernario_1": [["CTP_Prop_RoofWindow_01"], 1.0],
	"lucernario_2": [["CTP_Prop_RoofWindow_07"], 1.0],
	"macchina_tetto": [["CTP_Prop_ACVent_Stright"], 1.0],
	"antenna_1": [["CTP_Prop_Intel_02"], 1.0],
	"antenna_2": [["CTP_Prop_Intel_04"], 0.8],
	# --- 'mmiez'â via ---
	"quadro_elettrico_1": [["CTP_Prop_ElectracityCabinet_01"], 1.0],
	"quadro_elettrico_2": [["CTP_Prop_ElectracityCabinet_02"], 1.0],
	"quadro_elettrico_3": [["CTP_Prop_ElectracityCabinet_03"], 1.0],
	"sacchetto_1": [["CTP_Prop_TrashBag_01"], 1.0],
	"sacchetto_2": [["CTP_Prop_TrashBag_02"], 1.0],
	"sacchetto_3": [["CTP_Prop_TrashBag_03"], 1.0],
	"bidone_strada_1": [["CTP_Prop_CTPTrashCan_01"], 1.0],
	"bidone_strada_2": [["CTP_Prop_CTPTrashCan_02"], 1.0],
	"fioriera_1": [["CTP_Prop_Plant_01"], 1.0],
	"fioriera_2": [["CTP_Prop_Plant_02"], 1.0],
	"fioriera_3": [["CTP_Prop_Plant_03"], 1.0],
	"siepe_1": [["CTP_Prop_Bush_01"], 1.0],
	"siepe_2": [["CTP_Prop_Bush_02"], 1.0],
	"albero_viale_1": [["CTP_Prop_Tree_01"], 1.0],
	"albero_viale_2": [["CTP_Prop_Tree_03"], 1.0],
	"albero_viale_3": [["CTP_Prop_Tree_05"], 1.0],
	"albero_viale_4": [["CTP_Prop_Tree_08"], 1.0],
	"cartello_divieto_sosta": [["CTP_Prop_StreetSign_NoParking"], 0.62],
	"cartello_parcheggio": [["CTP_Prop_StreetSign_Parking"], 0.62],
	"cartello_senso_vietato": [["CTP_Prop_StreetSign_NoEntery"], 0.62],
	"cartello_stop": [["CTP_Prop_StreetSign_Stop"], 0.62],
	"cartello_30": [["CTP_Prop_StreetSign_Speed_30"], 0.62],
	"cartello_50": [["CTP_Prop_StreetSign_Speed_50"], 0.62],
	"cartello_strettoia": [["CTP_Prop_StreetSign_RoadNarrows"], 0.62],
	"cartello_pedoni": [["CTP_Prop_StreetSign_Footpath_01"], 0.62],
	"cartello_dosso": [["CTP_Prop_StreetSign_Bump"], 0.62],
	"cartello_discesa": [["CTP_Prop_StreetSign_Slope"], 0.62],
	"cartello_incrocio": [["CTP_Prop_StreetSign_Cross"], 0.62],
	"cono_3": [["CTP_Prop_RoadCone_03"], 0.8],
	"fusto_1": [["CTP_Prop_OilBerrel_01"], 0.68],
	"fusto_2": [["FRP_Prop_MetalBerrel_01"], 0.60],
	"fusto_3": [["SCP_OilBarrel_02"], 0.58],
	"giornali": [["CTP_Prop_Magazine"], 0.45],
	# --- 'o mercato ---
	"mela": [["FRP_Food_Apple"], 0.6],
	"arancia": [["FRP_Food_Orange"], 0.45],
	"limone": [["FRP_Food_Lemon"], 0.55],
	"pummarola": [["FRP_Food_Tomato"], 0.45],
	"peperone": [["FRP_Food_Pepper"], 0.9],
	"mulignana": [["FRP_Food_Eggplant"], 0.45],
	"uva": [["FRP_Food_Grape"], 0.45],
	"mellone": [["FRP_Food_Watermelon"], 0.6],
	"banana": [["FRP_Food_Banana"], 0.8],
	"patana": [["FRP_Food_Potato"], 0.45],
	"cepolla": [["FRP_Food_Onion"], 0.45],
	"aglio": [["FRP_Food_Garlic"], 0.4],
	"cucozza": [["FRP_Food_Pumpkin"], 0.6],
	"peperoncino": [["FRP_Food_RedChili"], 0.5],
	"carota": [["FRP_Food_Carrot"], 0.5],
	"friariello": [["FRP_Food_Broccoli"], 0.6],
	"pera": [["FRP_Food_Pear"], 0.5],
	"mandarino": [["FRP_Food_Tangerine"], 0.4],
	"cetriolo": [["FRP_Food_Cucumber"], 0.6],
	"ravanello": [["FRP_Food_Radish"], 0.5],
	"cascetta_1": [["FRP_Prop_WoodenCrates_01"], 0.48],
	"cascetta_2": [["FRP_Prop_WoodenCrates_02"], 0.42],
	"cascetta_3": [["FRP_Prop_WoodenCrates_03"], 0.45],
	"cascetta_4": [["FRP_Prop_WoodenCrates_04"], 0.42],
	"sacco_1": [["FRP_Prop_FoodSack_01"], 0.6],
	"sacco_2": [["FRP_Prop_FoodSack_02"], 0.55],
	"sacco_3": [["FRP_Prop_FoodSack_03"], 0.6],
	"sacco_4": [["FRP_Prop_FoodSack_04"], 0.6],
	"bancale_1": [["FRP_Prop_Pallete_01"], 0.5],
	"bancale_2": [["FRP_Prop_Pallete_02"], 0.5],
	"carriola": [["FRP_Prop_Wheelbarrow"], 0.45],
	"secchio_1": [["FRP_Prop_Bucket_03"], 0.6],
	"secchio_2": [["FRP_Prop_Bucket_04"], 0.6],
	"annaffiatoio": [["FRP_Prop_WateringCan_01"], 0.5],
	"pala": [["FRP_Prop_BigFarmingTool_01"], 0.75],
	"rastrello": [["FRP_Prop_BigFarmingTool_02"], 0.75],
	"zappa": [["FRP_Prop_BigFarmingTool_03"], 0.75],
	"cassa_grossa_legno": [["FRP_Prop_WoodenBox_01"], 0.5],
	# --- cucina, bar, pizzeria ---
	"pizza": [["KFP_Food_Pizza"], 1.0],
	"tazzulella": [["KFP_Prop_Cup_01"], 0.6],
	"bicchiere_acqua": [["KFP_Food_Water Cup"], 0.45],
	"pane": [["KFP_Food_Bread"], 1.0],
	"formaggio": [["KFP_Food_Cheese"], 0.8],
	"latte": [["KFP_Food_Milk Bottle"], 0.9],
	"olio": [["KFP_Food_Oil"], 0.8],
	"pasta_pacco": [["KFP_Food_Pasta"], 0.9],
	"uovo": [["KFP_Food_Egg"], 0.5],
	"lasagna": [["KFP_Food_Lasagna"], 1.0],
	"polpette": [["KFP_Food_Meatballs"], 1.0],
	"pentola_1": [["KFP_Prop_Pot_06"], 1.0],
	"pentola_2": [["KFP_Prop_Pot_05"], 1.0],
	"padella": [["KFP_Prop_Pan_01"], 0.9],
	"tagliere": [["KFP_Prop_CuttingPlate"], 1.0],
	"mattarello": [["KFP_Prop_RollingPin"], 1.0],
	"rotella_pizza": [["KFP_Prop_PizzaCutter"], 1.0],
	"cucina_gas": [["KFP_Prop_Stove_p01", "KFP_Prop_Stove_p02",
		"KFP_Prop_Stove_p03", "KFP_Prop_Stove_p04", "KFP_Prop_Stove_p05",
		"KFP_Prop_Stove_p06", "KFP_Prop_Stove_p07"], 0.72],
	"lavandino": [["KFP_Prop_Sink_01_001"], 0.8],
	"mobile_cucina": [["KFP_Prop_KitchenCabinet_03"], 0.72],
	# --- 'o vascio ---
	"frigorifero": [["Prop_Refrigerator_02"], 0.95],
	"lavatrice": [["Prop_Washer_01"], 0.85],
	"divano": [["Prop_Sofa_06_C"], 1.0],
	"armadio": [["Prop_Wardrobe_02", "Prop_Wardrobe_02_Door_1",
		"Prop_Wardrobe_02_Door_2"], 0.95],
	"culla": [["Prop_BabyBed_01"], 1.0],
	"specchio": [["Prop_Mirror_01"], 1.0],
	"lampada": [["Prop_HomeLamp_02"], 1.0],
	"comodino": [["Prop_Nightstand_02"], 0.9],
	"mensola": [["Prop_WallShelf_03"], 1.0],
	"damigiana": [["Prop_WaterGallon"], 0.8],
	"telefono": [["Prop_Telephone"], 0.8],
	"orsacchiotto": [["Prop_TeddyBear_01"], 0.6],
	"trenino": [["Prop_ToyTrain_01"], 0.8],
	"macchinina": [["Prop_ToyCar_01"], 0.7],
	"pallone_casa": [["Prop_Ball_01"], 0.5],
	"pianta_casa_1": [["Prop_Homeplant_01"], 1.0],
	"pianta_casa_2": [["Prop_Homeplant_02"], 1.0],
	"pianta_casa_3": [["Prop_Homeplant_05"], 1.0],
	"pianta_casa_4": [["Prop_Homeplant_07"], 1.0],
	"pianta_casa_5": [["Prop_Homeplant_08"], 1.0],
	"pianta_casa_6": [["Prop_Homeplant_11"], 1.0],
	# --- attrezzi (il pacchetto "survival" è in scala da cartone animato:
	#     un martello lungo un metro, una chiave di mezzo metro) ---
	"martello": [["SCP_Hammer_01"], 0.33],
	"chiave_inglese": [["SCP_Wrench_02"], 0.6],
	"piccone": [["SCP_Pickaxe"], 0.8],
	"piede_di_porco": [["SCP_PryBar"], 0.5],
	"bombola": [["SCP_GasTank"], 0.75],
	"corda": [["SCP_Rope"], 0.6],
	"nastro": [["SCP_Tape_01"], 0.4],
	"binocolo": [["SCP_Binoculars"], 0.35],
	"mazza_baseball": [["SCP_BaseballBat_01"], 0.62],
	"bottiglia_acqua": [["SCP_WaterBottle_02"], 0.45],
	"cassetta_soccorso": [["SCP_MidKit_01"], 0.4],
	"legna_1": [["SCP_WoodLog_01"], 0.8],
	"legna_2": [["SCP_WoodLog_02"], 0.8],
	"legna_3": [["SCP_WoodLog_03"], 0.8],
	"remo": [["SCP_Paddle_02"], 0.6],
	# --- natura ---
	"scoglio_1": [["NEP_HardRock_01"], 1.4],
	"scoglio_2": [["NEP_HardRock_02"], 1.4],
	"scoglio_3": [["NEP_HardRock_03"], 1.4],
	"scoglio_4": [["NEP_HardRock_04"], 1.6],
	"scoglio_5": [["NEP_HardRock_05"], 1.4],
	"sasso_1": [["NEP_SoftRock_01"], 1.0],
	"sasso_2": [["NEP_SoftRock_03"], 1.0],
	"cespuglio_1": [["NEP_Bush_01"], 1.0],
	"cespuglio_2": [["NEP_Bush_03"], 1.0],
	"cespuglio_3": [["NEP_Bush_08"], 1.0],
	"cespuglio_4": [["NEP_Bush_10"], 1.0],
	"cespuglio_5": [["NEP_Bush_12"], 1.0],
	"cespuglio_6": [["NEP_Bush_15"], 1.0],
	"fiori_1": [["NEP_Flower_15"], 1.0],
	"fiori_2": [["NEP_Flower_16"], 1.0],
	"fiori_3": [["NEP_Flower_18"], 1.0],
	"fiori_4": [["NEP_Flower_19"], 1.0],
	"fiori_5": [["NEP_Flower_21"], 1.0],
	"fiori_6": [["NEP_Flower_23"], 1.0],
	"erba_1": [["NEP_Grass_02"], 1.0],
	"erba_2": [["NEP_Grass_03"], 1.0],
	"erba_3": [["NEP_Grass_05"], 1.0],
	"erba_4": [["NEP_Grass_09"], 1.0],
	"erba_5": [["NEP_Grass_11"], 1.0],
	"erba_6": [["NEP_Grass_13"], 1.0],
	"pianta_grassa_1": [["NEP_Cactus_01_A"], 0.7],
	"pianta_grassa_2": [["NEP_Cactus_02_A"], 0.7],
	"pianta_grassa_3": [["NEP_Cactus_39_A"], 0.7],
	"albero_1": [["NEP_Tree_05_p1_Spring", "NEP_Tree_05_p2_Spring"], 1.3],
	"albero_2": [["NEP_Tree_08_p1_Spring", "NEP_Tree_08_p2_Spring"], 1.3],
	"albero_3": [["NEP_Tree_33_Spring"], 1.3],
	"albero_4": [["NEP_Tree_36_Spring"], 1.3],
	"albero_5": [["NEP_Tree_37_Spring"], 1.2],
}


func _pandazole() -> void:
	print("=== 'O PANDAZOLE ===")
	var ps: PackedScene = load(SORGENTI + "panda/pandazole.fbx")
	if ps == null:
		print("  NUN SE CARICA")
		return
	var r: Node3D = ps.instantiate()
	get_root().add_child(r)
	await process_frame
	# Il materiale condiviso: l'atlante dei colori, filtrato "al più vicino"
	# (ogni colore è un quadratino di trentadue pixel: filtrandolo lineare,
	# da lontano i colori vicini si mescolano e una mela diventa marrone).
	var mat := StandardMaterial3D.new()
	mat.resource_name = "pandazole"
	mat.albedo_texture = load(USCITA + "pandazole.png")
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	mat.roughness = 0.82
	ResourceSaver.save(mat, USCITA + "pandazole_mat.tres")
	mat = load(USCITA + "pandazole_mat.tres")
	# Si cercano i pezzi per nome, una volta sola.
	var per_nome := {}
	for m in r.find_children("*", "MeshInstance3D", true, false):
		var k := str(m.name)
		if not per_nome.has(k):
			per_nome[k] = m
	var fatti := 0
	for nome in PANDA:
		var dati: Array = PANDA[nome]
		var pezzi: Array = dati[0]
		var scala: float = float(dati[1])
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var box := AABB()
		var primo := true
		var trovati := 0
		# Primo giro: l'ingombro, per sapere dove sta la base.
		for pz in pezzi:
			if not per_nome.has(str(pz)):
				print("  %s: manca il pezzo '%s'" % [nome, pz])
				continue
			var mi: MeshInstance3D = per_nome[str(pz)]
			var b: AABB = mi.global_transform * mi.get_aabb()
			if primo:
				box = b
				primo = false
			else:
				box = box.merge(b)
			trovati += 1
		if trovati == 0:
			continue
		var base := Vector3(box.get_center().x, box.position.y, box.get_center().z)
		var giu := Transform3D(Basis().scaled(Vector3.ONE * scala), -base * scala)
		for pz in pezzi:
			if not per_nome.has(str(pz)):
				continue
			var mi: MeshInstance3D = per_nome[str(pz)]
			for s in mi.mesh.get_surface_count():
				st.append_from(mi.mesh, s, giu * mi.global_transform)
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,
			_normali_a_posto(st.commit_to_arrays()))
		mesh.surface_set_material(0, mat)
		mesh.resource_name = nome
		var err := ResourceSaver.save(mesh, USCITA + nome + ".mesh")
		if err == OK:
			fatti += 1
		var a: AABB = mesh.get_aabb()
		print("  %-24s %.2f × %.2f × %.2f  %s" % [nome, a.size.x, a.size.y,
			a.size.z, "" if err == OK else "NUN SALVATO"])
	print("  pezzi salvati: %d ncopp'a %d" % [fatti, PANDA.size()])
	r.free()
