extends Node
## Sonda della 0.60: dove sono finite le cose nuove (per puntare le foto).
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(40):
		await get_tree().process_frame
	var c = get_tree().get_first_node_in_group("citta")
	for g in ["segge_fore", "signore_assettate", "bagni_chimici", "bancarella_libri", "garage", "bar", "scommesse", "tabaccheria", "armiere"]:
		var ns := get_tree().get_nodes_in_group(g)
		print("%s: %d" % [g, ns.size()])
		for n in ns.slice(0, 6):
			var b: Basis = (n as Node3D).global_transform.basis
			print("   %s  z=%s  x=%s" % [str((n as Node3D).global_position.snapped(Vector3.ONE * 0.1)), str(b.z.snapped(Vector3.ONE * 0.01)), str(b.x.snapped(Vector3.ONE * 0.01))])
	print("vasci: %d  quadri: %d  cantieri: %d  cassonetti: %d" % [c._vasci_fore.size(), c._quadri_posti.size(), c._cantieri_info.size(), c._cassonetti.size()])
	for v in c._vasci_fore.slice(0, 8):
		print("   vascio porta %s fen %s fuori %s" % [str((v[0] as Vector3).snapped(Vector3.ONE*0.1)), str((v[1] as Vector3).snapped(Vector3.ONE*0.1)), str(v[2])])
	print("rifiuti: ", c._rifiuti)
	print("scartati: ", c._solidi_scartati.keys())
	print("=== storte: 0 ===")
	get_tree().quit()
