extends Node
## **Nisciuna scenografia dint' ô vascio** (0.59).
##
## La stanza di casa sta a (300, 0, 300), fuori dalla pianta, e lì attorno
## la scenografia continua: palazzi finti del golfo, colline lontane, case
## sulla collina. Questa prova riempie la stanza di punti (una griglia ogni
## trenta centimetri, dal pavimento al soffitto) e controlla che nessun
## pezzo di fondale ne contenga uno:
##   - i coni delle colline (CylinderMesh: raggio che va dal fondo alla cima);
##   - le scatole dei MultiMesh (Golfo, CaseLontane): ogni istanza è un cubo
##     unitario trasformato, quindi basta riportare il punto nel suo spazio.
## Stampa "=== storte: N ===" come le altre prove.

const VascioScript := preload("res://scripts/vascio_3d.gd")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(40):
		await get_tree().process_frame
	# Senza disegno i MultiMesh stanno vuoti (le trasformazioni le tiene il
	# RenderingServer, e quello finto non tiene niente): la prova passerebbe
	# sempre. Va fatta girare con xvfb.
	if DisplayServer.get_name() == "headless":
		print("  SENZA DISEGNO: 'e MultiMesh stanno vacante, 'a prova nun vale. Falla girare cu xvfb.")
		print("=== storte: 1 ===")
		get_tree().quit()
		return
	var punti: Array = []
	var c: Vector3 = VascioScript.DENTRO
	var x := -VascioScript.LARG * 0.5
	while x <= VascioScript.LARG * 0.5 + 0.001:
		var z := -VascioScript.PROF * 0.5
		while z <= VascioScript.PROF * 0.5 + 0.001:
			var y := 0.05
			while y <= VascioScript.ALT:
				punti.append(c + Vector3(x, y, z))
				y += 0.3
			z += 0.3
		x += 0.3
	var storte := 0
	var pila: Array = [get_tree().root]
	while not pila.is_empty():
		var n: Node = pila.pop_back()
		for k in n.get_children():
			pila.append(k)
		if n.get_parent() and str(n.get_parent().name) == "Dentro":
			continue
		if n is MeshInstance3D and (n as MeshInstance3D).mesh is CylinderMesh \
				and (n as MeshInstance3D).is_visible_in_tree():
			var mi := n as MeshInstance3D
			var cm := mi.mesh as CylinderMesh
			var inv: Transform3D = mi.global_transform.affine_inverse()
			for p in punti:
				var l: Vector3 = inv * (p as Vector3)
				var h: float = cm.height
				if l.y < -h * 0.5 or l.y > h * 0.5:
					continue
				var t: float = (l.y + h * 0.5) / h
				var r: float = lerpf(cm.bottom_radius, cm.top_radius, t)
				if Vector2(l.x, l.z).length() < r:
					storte += 1
					print("  CONO %s tocca la stanza in %s" % [str(mi.get_path()), str((p as Vector3).snapped(Vector3.ONE * 0.1))])
					break
		elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).is_visible_in_tree():
			var mmi := n as MultiMeshInstance3D
			var mm: MultiMesh = mmi.multimesh
			if mm == null or not (mm.mesh is BoxMesh):
				continue
			var mezza: Vector3 = (mm.mesh as BoxMesh).size * 0.5
			for i in mm.instance_count:
				var tr: Transform3D = mmi.global_transform * mm.get_instance_transform(i)
				# Scarto veloce: lontano più di cento metri, niente.
				if Vector2(tr.origin.x - c.x, tr.origin.z - c.z).length() > 100.0:
					continue
				var inv2: Transform3D = tr.affine_inverse()
				for p in punti:
					var l2: Vector3 = inv2 * (p as Vector3)
					if absf(l2.x) < mezza.x and absf(l2.y) < mezza.y and absf(l2.z) < mezza.z:
						storte += 1
						print("  SCATOLA %s #%d tocca la stanza in %s" % [str(mmi.get_path()), i, str((p as Vector3).snapped(Vector3.ONE * 0.1))])
						break
	print("  punti nella stanza: %d" % punti.size())
	print("=== storte: %d ===" % storte)
	get_tree().quit()
