extends Node
## **Chello ca ce hanno dato e nun avimmo maje usato** (0.57).
##
## Il capo: *«controlla se hai usato tutti gli asset 3d e audio che ti ho
## dato e se non l'hai fatto, usali tutti per dare maggiore varietà»*.
##
## Questa prova fa due cose, e la seconda è quella che serve davvero.
##
## **Uno: 'o cunto.** Legge la cartella dei modelli, dei suoni e delle
## texture, e la incrocia col codice del gioco — non con `tools/`, che è
## dove i modelli *nascono* e dove il nome compare comunque. Un file
## nominato solo dallo script che l'ha generato è un file che nessuno ha
## mai messo in strada.
##
## **Due: 'a mesura.** Di ogni modello stampa l'ingombro vero, e questo è il
## pezzo che vale: in questo progetto la regola è **misurare, non
## indovinare** (vedi `prova_manella` e i tre difetti delle ossa della
## 0.54). Montare un lampione senza sapere dove sta la lampada vuol dire
## appendere la luce a mezz'aria, e in fotografia si vede.

const Models := preload("res://scripts/models.gd")

var storte: int = 0


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame

	var codice: String = _tutto_o_codice()
	_conta("MODELLI", "res://assets/models", [".glb", ".gltf", ".obj", ".fbx",
		".scn", ".mesh"],
		codice)
	_conta("SUONE", "res://audio", [".ogg", ".wav", ".mp3"], codice)
	_conta("TEXTURE", "res://assets/textures", [".png", ".jpg", ".jpeg"],
		codice)
	_percorsi_scritti(codice)
	_mesura()

	print("=== storte: %d ===" % storte)
	get_tree().quit()


## **Tre: ogni percorso scritto nel codice esiste?** (0.59)
##
## Il recupero della 0.59 ha rimesso a posto modelli, texture e suoni
## camminando sui file `.import` del pacchetto — e i tre shader (`cielo`,
## `mare`, `intonaco`) un `.import` non ce l'hanno, quindi sono rimasti
## fuori. Questa prova contava i file *dentro alle cartelle* e li incrociava
## col codice: una cartella che non c'è più non ha file da contare, e la
## prova diceva zero storte. Se n'è accorta per caso `prova_bagnato`.
##
## Adesso si va al contrario: si prende **ogni `res://` scritto fra
## virgolette negli script** e si guarda se esiste. Un percorso costruito
## a pezzi (`DIR + nome + ext`) non si vede, e va bene: quelli li conta il
## giro di sopra.
func _percorsi_scritti(codice: String) -> void:
	print("=== PERCORSI SCRITTI NEL CODICE ===")
	var re := RegEx.new()
	re.compile("\"(res://[^\"%]+\\.[A-Za-z0-9]+)\"")
	var visti := {}
	for m in re.search_all(codice):
		var p: String = m.get_string(1)
		if visti.has(p):
			continue
		visti[p] = true
		if not (ResourceLoader.exists(p) or FileAccess.file_exists(p)):
			male("il codice nomina %s e non esiste" % p)
	print("  %d percorsi controllati" % visti.size())


func _tutto_o_codice() -> String:
	var tutto := ""
	for f in _file_sotto("res://scripts", [".gd"]):
		tutto += FileAccess.get_file_as_string(f)
	return tutto


func _file_sotto(cartella: String, estensioni: Array) -> Array:
	var fore: Array = []
	var d := DirAccess.open(cartella)
	if d == null:
		return fore
	d.list_dir_begin()
	var n: String = d.get_next()
	while n != "":
		if d.current_is_dir():
			if not n.begins_with("."):
				fore.append_array(_file_sotto(cartella + "/" + n, estensioni))
		else:
			for e in estensioni:
				if n.ends_with(str(e)) and not n.begins_with("_"):
					fore.append(cartella + "/" + n)
					break
		n = d.get_next()
	d.list_dir_end()
	return fore


func _conta(che: String, cartella: String, estensioni: Array,
		codice: String) -> void:
	print("=== %s ===" % che)
	var tutte: Array = _file_sotto(cartella, estensioni)
	var mai: Array = []
	for f in tutte:
		var base: String = f.get_file()
		var stelo: String = base.get_basename()
		if codice.contains(base) or codice.contains('"%s"' % stelo) \
				or codice.contains(f):
			continue
		mai.append(f)
	print("  %d 'n tutto, %d mai nummenate dint'ô gioco"
		% [tutte.size(), mai.size()])
	for f in mai:
		print("    MAI: %s" % f)
	if tutte.is_empty():
		male("nun s'è truvato niente dint'a %s: 'a prova nun sta guardanno"
			% cartella)
	# **Zero è l'unico numero che va bene.** Un asset che il capo ha dato e
	# che non sta in strada non è una scelta di regia: è roba dimenticata.
	if not mai.is_empty():
		male("%d %s nun stanno 'n gioco" % [mai.size(), che.to_lower()])


## L'ingombro vero di ogni modello, in metri. Serve a chi lo monta.
func _mesura() -> void:
	print("=== 'E MESURE ===")
	var quale := ["lampione", "giara", "delimitatore", "new_jersey",
		"barriera_lunga"]
	print("  %-18s %-24s %s" % ["modello", "ngombro (x, y, z)", "'o centro"])
	for m in quale:
		var n := Models.spawn(m)
		if n == null:
			print("  %-18s nun ce sta" % m)
			continue
		add_child(n)
		var a: AABB = _ngombro(n)
		print("  %-18s %-24s %s" % [m,
			"%.2f × %.2f × %.2f" % [a.size.x, a.size.y, a.size.z],
			"(%.2f, %.2f, %.2f)" % [a.position.x + a.size.x * 0.5,
				a.position.y + a.size.y * 0.5,
				a.position.z + a.size.z * 0.5]])
		n.queue_free()


func _ngombro(n: Node) -> AABB:
	var a := AABB()
	var primmo := true
	for c in _tutte_e_mesh(n):
		var m: MeshInstance3D = c
		if m.mesh == null:
			continue
		var b: AABB = m.mesh.get_aabb()
		b = m.transform * b
		if primmo:
			a = b
			primmo = false
		else:
			a = a.merge(b)
	return a


func _tutte_e_mesh(n: Node) -> Array:
	var fore: Array = []
	if n is MeshInstance3D:
		fore.append(n)
	for c in n.get_children():
		fore.append_array(_tutte_e_mesh(c))
	return fore
