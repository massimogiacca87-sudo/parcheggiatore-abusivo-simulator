extends Node
## Addò va a fernì 'a mano, si giro 'a spalla accussì?
##
## Le braccia in prima persona vanno portate dentro all'inquadratura, e per
## farlo bisogna ruotare due ossa. Ma **su che asse?** Lo scheletro è quello
## della libreria (stile Unreal: `upperarm_l`, `lowerarm_l`), e su quei rig
## l'asse lungo dell'osso di solito è la X — cioè ruotare attorno alla X è
## una **torsione**, non un'alzata. Provare a occhio vuol dire un giro di
## foto ogni tentativo, e ogni giro di foto costa un minuto.
##
## Quindi si misura: si mette in piedi un corpo, si prova ogni asse a ogni
## angolo, e si guarda **dove finisce l'osso della mano** rispetto alla
## testa. Quello che serve è una mano che stia davanti (z negativa, che è
## avanti) e un po' più in basso degli occhi.

const Human := preload("res://scripts/human_builder.gd")

## Dove sta l'occhio rispetto ai piedi: serve a leggere i numeri come li
## vedrebbe la telecamera.
const OCCHIO_Y: float = 1.62


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame

	var parts := Human.build(Color(0.46, 0.53, 0.61), Color(0.22, 0.24, 0.3),
		"", 1.78, {"senza_testa": true})
	add_child(parts["root"])
	var anim = parts["anim"]
	var scheletro: Skeleton3D = parts["scheletro"]
	await get_tree().process_frame
	await get_tree().process_frame

	if scheletro == null:
		print("nun ce sta 'o scheletro: STORTO")
		get_tree().quit()
		return

	var i_mano: int = scheletro.find_bone("hand_r")
	print("=== 'A MANO A RIPOSO ===")
	var riposo: Vector3 = _dove_sta(scheletro, i_mano)
	print("  hand_r:  avanti %+.2f · alto %+.2f · lato %+.2f" % [
		-riposo.z, riposo.y - OCCHIO_Y, riposo.x])

	print("=== PRUVANNO ll'ASSE ===")
	print("  %-10s %-6s %-8s %-8s %-8s" % ["asse", "gradi", "avanti",
		"alto", "lato"])
	for asse in ["x", "y", "z"]:
		for gradi in [-60.0, -30.0, 30.0, 60.0]:
			var e := Vector3.ZERO
			match asse:
				"x": e.x = gradi
				"y": e.y = gradi
				"z": e.z = gradi
			anim.hold_bone("shoulder_r", e)
			await get_tree().process_frame
			await get_tree().process_frame
			var d: Vector3 = _dove_sta(scheletro, i_mano)
			print("  %-10s %-6.0f %+-8.2f %+-8.2f %+-8.2f" % [asse, gradi,
				-d.z, d.y - OCCHIO_Y, d.x])
			anim.release_bone("shoulder_r")

	# **'A cerca vera.** Due parametri (spalla e gomito sull'asse Z, che
	# dalla tabella sopra e' l'unico che porta la mano avanti) e si stampa
	# solo quello che serve: mano davanti, sotto agli occhi ma non ai
	# piedi, e non larga piu' di mezzo metro.
	print("=== 'A CERCA ===")
	print("  %-8s %-8s %-8s %-8s %-8s %s" % ["spalla", "gomito", "avanti",
		"alto", "lato", "bbona?"])
	var meglio := {"punti": -999.0}
	for sp in [40.0, 55.0, 70.0, 85.0, 100.0]:
		for go in [0.0, 30.0, 60.0, 90.0]:
			anim.hold_bone("shoulder_r", Vector3(0, 0, sp))
			anim.hold_bone("elbow_r", Vector3(0, 0, go))
			await get_tree().process_frame
			await get_tree().process_frame
			var d3: Vector3 = _dove_sta(scheletro, i_mano)
			var avanti: float = -d3.z
			var alto: float = d3.y - OCCHIO_Y
			var lato: float = absf(d3.x)
			# Una mano buona sta davanti almeno venti centimetri, fra
			# quaranta e dieci sotto gli occhi, e non piu' larga di 45.
			var bbona: bool = avanti > 0.20 and alto > -0.45 and alto < -0.05 \
				and lato < 0.45
			# Il punteggio serve a scegliere la migliore fra le buone.
			var punti: float = avanti - lato * 0.5 - absf(alto + 0.25)
			if bbona and punti > float(meglio["punti"]):
				meglio = {"punti": punti, "sp": sp, "go": go,
					"avanti": avanti, "alto": alto, "lato": lato}
			print("  %-8.0f %-8.0f %+-8.2f %+-8.2f %-8.2f %s" % [sp, go,
				avanti, alto, lato, "SI" if bbona else ""])
			anim.release_bone("shoulder_r")
			anim.release_bone("elbow_r")
	if meglio.has("sp"):
		print("  --> 'a meglio: spalla z=%.0f gomito z=%.0f (avanti %.2f, alto %.2f, lato %.2f)"
			% [meglio["sp"], meglio["go"], meglio["avanti"], meglio["alto"],
				meglio["lato"]])
	else:
		print("  --> nisciuna posa bbona: 'e braccia restano addò stanno")

	# **'A seconda cerca: aizà 'a mano.** Con la spalla a z=85 la mano sta
	# davanti ma trentasei centimetri sotto l'occhio, e con un campo visivo
	# da settantacinque gradi a trenta centimetri di distanza se ne vedono
	# ventidue: resta fuori dal quadro. Il gomito sull'asse Z non la alza
	# (e' una rotazione orizzontale), quindi si provano gli altri due assi.
	print("=== AIZANNO 'A MANO ===")
	print("  %-10s %-8s %-8s %-8s" % ["gomito", "avanti", "alto", "lato"])
	for asse in ["x", "y"]:
		for g in [-90.0, -60.0, -30.0, 30.0, 60.0, 90.0]:
			var e2 := Vector3.ZERO
			if asse == "x":
				e2.x = g
			else:
				e2.y = g
			anim.hold_bone("shoulder_r", Vector3(0, 0, 85))
			anim.hold_bone("elbow_r", e2)
			await get_tree().process_frame
			await get_tree().process_frame
			var d4: Vector3 = _dove_sta(scheletro, i_mano)
			print("  %-10s %+-8.2f %+-8.2f %-8.2f" % [
				"%s%+.0f" % [asse, g], -d4.z, d4.y - OCCHIO_Y, absf(d4.x)])
			anim.release_bone("shoulder_r")
			anim.release_bone("elbow_r")

	# **'A terza cerca: tutt''e tre 'e ggrade 'nzieme.**
	# La mano sta troppo larga (mezzo metro) e troppo bassa. Portarla
	# dentro vuol dire chiudere la spalla verso il corpo, e questo e' un
	# terzo asse: si prova la griglia intera e si stampa solo il meglio.
	print("=== 'A GRIGLIA ===")
	var top: Array = []
	for sx in [-40.0, -20.0, 0.0, 20.0, 40.0]:
		for sy in [-40.0, -20.0, 0.0, 20.0, 40.0]:
			for gx in [30.0, 60.0, 90.0]:
				anim.hold_bone("shoulder_r", Vector3(sx, sy, 85.0))
				anim.hold_bone("elbow_r", Vector3(gx, 0, 0))
				await get_tree().process_frame
				await get_tree().process_frame
				var d5: Vector3 = _dove_sta(scheletro, i_mano)
				var av: float = -d5.z
				var al: float = d5.y - OCCHIO_Y
				var la: float = absf(d5.x)
				anim.release_bone("shoulder_r")
				anim.release_bone("elbow_r")
				if av < 0.18 or al < -0.34 or al > -0.02 or la > 0.34:
					continue
				top.append({"p": Vector3(sx, sy, 85.0), "g": gx,
					"av": av, "al": al, "la": la,
					"pt": av - la * 0.8 - absf(al + 0.18)})
	top.sort_custom(func(a, b): return float(a["pt"]) > float(b["pt"]))
	print("  %-22s %-6s %-8s %-8s %-8s" % ["spalla", "gomito", "avanti",
		"alto", "lato"])
	for k in range(mini(6, top.size())):
		var t: Dictionary = top[k]
		print("  %-22s %-6.0f %+-8.2f %+-8.2f %-8.2f" % [str(t["p"]),
			float(t["g"]), float(t["av"]), float(t["al"]), float(t["la"])])
	if top.is_empty():
		print("  nisciuna posa dint'ê limmite")

	# E adesso la coppia: spalla + gomito sull'asse che è venuto meglio.
	print("=== SPALLA + GOMITO ===")
	print("  %-16s %-8s %-8s %-8s" % ["posa", "avanti", "alto", "lato"])
	for prova in [
			{"n": "sp y-60 go y-60", "sp": Vector3(0, -60, 0), "go": Vector3(0, -60, 0)},
			{"n": "sp y+60 go y+60", "sp": Vector3(0, 60, 0), "go": Vector3(0, 60, 0)},
			{"n": "sp z-60 go z-60", "sp": Vector3(0, 0, -60), "go": Vector3(0, 0, -60)},
			{"n": "sp z+60 go z+60", "sp": Vector3(0, 0, 60), "go": Vector3(0, 0, 60)},
			{"n": "sp y-45 go z-80", "sp": Vector3(0, -45, 0), "go": Vector3(0, 0, -80)},
			{"n": "sp z-45 go y-80", "sp": Vector3(0, 0, -45), "go": Vector3(0, -80, 0)},
		]:
		anim.hold_bone("shoulder_r", prova["sp"])
		anim.hold_bone("elbow_r", prova["go"])
		await get_tree().process_frame
		await get_tree().process_frame
		var d2: Vector3 = _dove_sta(scheletro, i_mano)
		print("  %-16s %+-8.2f %+-8.2f %+-8.2f" % [str(prova["n"]),
			-d2.z, d2.y - OCCHIO_Y, d2.x])
		anim.release_bone("shoulder_r")
		anim.release_bone("elbow_r")

	print("=== fernuto ===")
	get_tree().quit()


## Dove sta un osso, in metri, nel sistema del personaggio.
func _dove_sta(sk: Skeleton3D, i: int) -> Vector3:
	if i < 0:
		return Vector3.ZERO
	return (sk.global_transform * sk.get_bone_global_pose(i)).origin
