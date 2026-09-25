extends Node
## Cerca 'e pertose dint'ô vascio.
##
## Il capo ha mandato uno screenshot: "c'è ancora un muro attraversabile in
## casa". Trovarlo a occhio vuol dire camminare contro sei pareti sperando
## di beccare il punto giusto. Si misura invece: dal centro della stanza si
## tirano raggi in tutte le direzioni, e si guarda **dove il raggio esce**.
##
## La stanza è 6,4 × 5,2 × 2,62 con l'origine al centro del pavimento,
## quindi da lì al muro ci sono al massimo 3,2 m in x, 2,6 in z e 2,62 in
## alto. Un raggio che va più lontano di così ha trovato un buco.

const VascioScript := preload("res://scripts/vascio_3d.gd")
const LAYER_WORLD := 1

## Quanto oltre il muro teorico si tollera prima di gridare al buco. Mezzo
## metro copre lo spessore delle pareti e gli arrotondamenti.
const MARGINE: float = 0.55


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	var v = VascioScript.new()
	add_child(v)
	await get_tree().process_frame
	await get_tree().process_frame

	var centro: Vector3 = VascioScript.DENTRO
	var spazio := get_viewport().world_3d.direct_space_state
	print("=== 'E MURE D''O VASCIO ===")
	print("stanza %.1f x %.1f x %.1f, centro %s" % [
		VascioScript.LARG, VascioScript.PROF, VascioScript.ALT, str(centro)])

	var buchi := 0
	var quote := [0.20, 0.60, 1.10, 1.60, 2.10, 2.45]
	for h in quote:
		var da: Vector3 = centro + Vector3(0, h, 0)
		var peggio := 0.0
		var dove := ""
		for g in range(0, 360, 4):
			var a: float = deg_to_rad(float(g))
			var dir := Vector3(sin(a), 0, cos(a))
			# Fin dove dovrebbe arrivare il muro in questa direzione.
			var atteso: float = _fin_dove(dir)
			var q := PhysicsRayQueryParameters3D.create(
				da, da + dir * (atteso + 6.0), LAYER_WORLD)
			var hit := spazio.intersect_ray(q)
			var d: float = INF
			if not hit.is_empty():
				d = da.distance_to(hit["position"])
			if d > atteso + MARGINE:
				buchi += 1
				if d - atteso > peggio:
					peggio = d - atteso
					dove = "%d° (atteso %.2f, arrivato %s)" % [
						g, atteso, ("NIENTE" if d == INF else "%.2f" % d)]
		if dove != "":
			print("  quota %.2f  ->  BUCO a %s" % [h, dove])
		else:
			print("  quota %.2f  ->  tutto chiuso" % h)

	# E il soffitto: un raggio in su dal centro.
	var su := PhysicsRayQueryParameters3D.create(centro + Vector3(0, 0.5, 0),
		centro + Vector3(0, 12.0, 0), LAYER_WORLD)
	var hs := spazio.intersect_ray(su)
	print("  soffitto -> %s" % ("NIENTE (si esce 'a coppa)" if hs.is_empty()
		else "%.2f m" % (hs["position"].y - centro.y)))

	print("=== %d raggi so' scappate ===" % buchi)
	get_tree().quit()


## La distanza dal centro al muro in una data direzione, per una stanza
## rettangolare: il minimo fra il muro di x e quello di z.
func _fin_dove(dir: Vector3) -> float:
	var dx: float = INF
	var dz: float = INF
	if absf(dir.x) > 0.0001:
		dx = (VascioScript.LARG * 0.5) / absf(dir.x)
	if absf(dir.z) > 0.0001:
		dz = (VascioScript.PROF * 0.5) / absf(dir.z)
	return minf(dx, dz)
