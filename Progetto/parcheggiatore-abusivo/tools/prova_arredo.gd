extends Node
## **'A robba nova sta tutta 'n gioco?** (0.59)
##
## Il pacchetto Pandazole ha 177 pezzi e il capo ha chiesto di usarli
## tutti. Questa prova gira per tutto l'albero della scena (città,
## Mergellina, vascio, garage, armiere…) e raccoglie le mesh che si vedono
## davvero — nei MeshInstance3D e nei MultiMesh — poi le confronta con i
## file `.mesh` della cartella dei modelli. Stampa anche perché
## `_sta_libero` ha scartato dei posti, che è il modo per capire se un
## pezzo manca per scelta (non c'era posto) o per sbaglio.

var _male := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(90):
		await get_tree().process_frame
	var usate := {}
	var pila: Array = [get_tree().root]
	while not pila.is_empty():
		var n: Node = pila.pop_back()
		for c in n.get_children():
			pila.append(c)
		var m: Mesh = null
		var quante := 1
		if n is MeshInstance3D:
			m = (n as MeshInstance3D).mesh
		elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh != null:
			m = (n as MultiMeshInstance3D).multimesh.mesh
			quante = (n as MultiMeshInstance3D).multimesh.instance_count
		if m != null and m.resource_path != "":
			usate[m.resource_path] = int(usate.get(m.resource_path, 0)) + quante
	var d := DirAccess.open("res://assets/models")
	var tutte: Array = []
	for f in d.get_files():
		if f.ends_with(".mesh"):
			tutte.append("res://assets/models/" + f)
	tutte.sort()
	var mancano: Array = []
	var righe: Array = []
	for f in tutte:
		var k: int = int(usate.get(f, 0))
		if k == 0:
			mancano.append(str(f).get_file().get_basename())
		else:
			righe.append("%s:%d" % [str(f).get_file().get_basename(), k])
	print("=== 'E PEZZE 'N GIOCO: %d su %d ===" % [tutte.size() - mancano.size(), tutte.size()])
	print("  " + "  ".join(righe))
	if not mancano.is_empty():
		print("  MANCANO: " + ", ".join(mancano))
		_male += mancano.size()
	var citta := get_tree().get_first_node_in_group("citta")
	if citta != null:
		print("=== 'E POSTE SCARTATE ===")
		print("  " + str(citta.get("_rifiuti")))
		var sc: Dictionary = citta.get("_solidi_scartati")
		var dove: Array = sc.get("dove", [])
		sc.erase("dove")
		print("  corpi solidi buttati: " + str(sc))
		for bt in dove:
			print("    buttato %s a %s" % [str(bt[1]), str(bt[0])])
		for c in citta.get("_cassonetti"):
			var p0: Vector3 = c[0]
			var g: float = float(c[1])
			var lungo := Vector3(cos(g), 0, -sin(g))
			var riga := "  cassonetto %s giro %.0f:" % [str(p0.round()), rad_to_deg(g)]
			for verso in [-1.0, 1.0]:
				for dist in [2.25, 3.2, 4.2]:
					var q: Vector3 = p0 + lungo * (dist * verso)
					var perche: String = citta.call("_perche_nun_sta", q, 0.55)
					riga += " %+.1f:%s" % [dist * verso, perche if perche != "" else "OK"]
			print(riga)
		var porta: Vector3 = preload("res://scripts/vascio_3d.gd").PORTA_POS
		for dz in [-1.95, -2.1, -2.4, 1.2]:
			var q := Vector3(porta.x + 0.2, 0.0, porta.z + dz)
			print("  lavatrice a %s: '%s'" % [str(q), citta.call("_perche_nun_sta", q, 0.37)])
	print("=== storte: %d ===" % _male)
	get_tree().quit()
