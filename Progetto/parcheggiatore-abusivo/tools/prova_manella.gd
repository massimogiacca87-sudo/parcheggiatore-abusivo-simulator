extends Node
## Ll'asse d''a mano: verso addò guarda 'o −Y?
##
## Tre volte in due versioni ho appeso una cosa a `hand_r` con
## `position = (0, −0.26, 0)` dando per scontato che −Y fosse "sotto". Non
## lo è: su un rig stile Unreal l'asse **lungo** dell'osso è la X, e gli
## altri due stanno dove capita. Il risultato è una cassetta degli attrezzi
## che galleggia all'altezza della spalla.
##
## Invece di provare a occhio — un giro di foto per tentativo, un minuto a
## giro — si misura: si mette in piedi un corpo, e si guarda dove finiscono
## nel mondo i tre assi locali della mano. Quello che serve è l'asse che
## punta in basso.

const Human := preload("res://scripts/human_builder.gd")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	var parts := Human.build(Color(0.5, 0.5, 0.6), Color(0.2, 0.2, 0.3),
		"", 1.78)
	add_child(parts["root"])
	var sk: Skeleton3D = parts["scheletro"]
	await get_tree().process_frame
	await get_tree().process_frame
	if sk == null:
		print("nun ce sta 'o scheletro: STORTO")
		get_tree().quit()
		return

	for nome in ["hand_r", "spine_03", "Head"]:
		var i: int = sk.find_bone(nome)
		if i < 0:
			print("  %s: nun ce sta" % nome)
			continue
		var t: Transform3D = sk.global_transform * sk.get_bone_global_pose(i)
		print("=== %s  (sta a y=%.2f) ===" % [nome, t.origin.y])
		# Ogni colonna della base è dove finisce, nel mondo, un asse locale.
		for a in [["+X", t.basis.x], ["+Y", t.basis.y], ["+Z", t.basis.z]]:
			var v: Vector3 = (a[1] as Vector3).normalized()
			print("  %s -> (%+.2f, %+.2f, %+.2f)   %s" % [a[0], v.x, v.y, v.z,
				_comme_se_chiamma(v)])
		# E la risposta secca: quale offset locale porta una cosa 26 cm
		# sotto alla mano, e quale la porta davanti al petto.
		print("  sotto  = %s" % _asse_verso(t, Vector3.DOWN))
		print("  annanze = %s" % _asse_verso(t, Vector3.FORWARD))


func _comme_se_chiamma(v: Vector3) -> String:
	var nomi := {"suso": Vector3.UP, "sotto": Vector3.DOWN,
		"annanze": Vector3.FORWARD, "arreto": Vector3.BACK,
		"a destra": Vector3.RIGHT, "a sinistra": Vector3.LEFT}
	var meglio := ""
	var punti := -2.0
	for k in nomi:
		var d: float = v.dot(nomi[k])
		if d > punti:
			punti = d
			meglio = k
	return "%s (%.2f)" % [meglio, punti]


## Quale offset LOCALE, lungo un asse solo, spinge verso `mondo`.
func _asse_verso(t: Transform3D, mondo: Vector3) -> String:
	var meglio := ""
	var punti := -2.0
	for a in [["+X", t.basis.x], ["-X", -t.basis.x], ["+Y", t.basis.y],
			["-Y", -t.basis.y], ["+Z", t.basis.z], ["-Z", -t.basis.z]]:
		var d: float = (a[1] as Vector3).normalized().dot(mondo)
		if d > punti:
			punti = d
			meglio = str(a[0])
	return "%s (%.2f)" % [meglio, punti]
