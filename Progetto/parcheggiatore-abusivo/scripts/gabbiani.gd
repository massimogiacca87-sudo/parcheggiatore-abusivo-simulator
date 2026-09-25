extends Node3D
## 'E gabbiane
##
## Uno stormo che gira in tondo sopra al golfo e sopra ai tetti. È la cosa
## che costa meno di tutte e che cambia di più: un cielo fermo è un fondale,
## un cielo con qualcosa che si muove dentro è un posto.
##
## **Come sono fatti.** Ogni gabbiano è due quadrilateri incernierati al
## centro — le ali — e un fuso in mezzo. Tre pezzi. Da quaranta metri in su
## (che è dove stanno sempre) non serve altro: quello che si legge di un
## gabbiano a quella distanza è la V delle ali che si apre e si chiude, e
## quella c'è.
##
## **Perché non hanno collisioni e non fanno ombra.** Stanno fra i venti e i
## sessanta metri di quota: un'ombra di gabbiano proiettata su una piazza è
## un puntino che nessuno vede e un calcolo che tutti pagano.

const Tex := preload("res://scripts/textures.gd")

## Quanti. Sopra i venti si comincia a notare che seguono tutti la stessa
## regola, e uno stormo troppo ordinato sembra un salvaschermo.
## **Quante ne so'.** Erano sedici sparse su tutta la città, e a quota
## alta: da terra si leggevano come macchie bianche appese al cielo, non
## come gabbiani. Sette bastano a far capire che sta il mare vicino, e
## stanno tutte dalla parte del porto — dove un gabbiano ci sta davvero.
const QUANTI: int = 7

var _uccelli: Array = []
var _t: float = 0.0


func popola(centro: Vector3, rng: RandomNumberGenerator) -> void:
	var corpo := Tex.flat(Color(0.94, 0.94, 0.92), 0.85)
	var ala := Tex.flat(Color(0.90, 0.91, 0.93), 0.9).duplicate()
	ala.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in range(QUANTI):
		var g := Node3D.new()
		add_child(g)

		var tronco := MeshInstance3D.new()
		var tm := CapsuleMesh.new()
		tm.radius = 0.11
		tm.height = 0.62
		tm.radial_segments = 5
		tm.rings = 2
		tronco.mesh = tm
		tronco.rotation.x = deg_to_rad(90.0)
		tronco.material_override = corpo
		tronco.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.add_child(tronco)

		var ali: Array = []
		for lato in [-1.0, 1.0]:
			var perno := Node3D.new()
			g.add_child(perno)
			var a := MeshInstance3D.new()
			var am := BoxMesh.new()
			# Lunghe e sottili: un'apertura alare di un metro e mezzo, che
			# per un gabbiano reale è giusta.
			am.size = Vector3(0.78, 0.02, 0.26)
			a.mesh = am
			a.position = Vector3(0.39 * lato, 0.0, 0.02)
			a.material_override = ala
			a.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			perno.add_child(a)
			ali.append({"perno": perno, "lato": lato})

		# Ognuno ha il suo cerchio, la sua quota e la sua velocità: se
		# girassero insieme si vedrebbe la circonferenza.
		_uccelli.append({
			"nodo": g,
			# Verso il mare, non sopra ai vicoli.
			"centro": centro + Vector3(rng.randf_range(-40.0, 130.0), 0.0,
				rng.randf_range(-210.0, -70.0)),
			"raggio": rng.randf_range(26.0, 90.0),
			# **'E gabbiane stevano troppo aute.** Da 22 a 62 metri: a quella quota,
			# sopra a palazzi di quindici, un gabbiano è un puntino bianco in
			# mezzo al niente — cioè uno degli "oggetti volanti" che il capo
			# vede dappertutto. I gabbiani di Napoli volano **sui tetti**, non
			# sopra le nuvole: da dodici a ventisei metri stanno appena sopra
			# alla linea di gronda e si leggono per quello che sono.
			"quota": rng.randf_range(12.0, 26.0),
			"vel": rng.randf_range(0.055, 0.16) * (1.0 if rng.randf() < 0.5 else -1.0),
			"fase": rng.randf_range(0.0, TAU),
			"ali": ali,
			"battito": rng.randf_range(2.2, 3.8),
			"planata": rng.randf_range(0.0, TAU),
		})


func _process(delta: float) -> void:
	_t += delta
	for u in _uccelli:
		var a: float = float(u["fase"]) + _t * float(u["vel"])
		var r: float = float(u["raggio"])
		var c: Vector3 = u["centro"]
		var p := Vector3(c.x + cos(a) * r,
			float(u["quota"]) + sin(_t * 0.35 + float(u["fase"])) * 3.0,
			c.z + sin(a) * r)
		var n: Node3D = u["nodo"]
		n.position = p
		# Guarda dove sta andando: la tangente al cerchio.
		var avanti := Vector3(-sin(a), 0.0, cos(a)) * signf(float(u["vel"]))
		# forward(θ) = (−sinθ, 0, −cosθ): θ = atan2(−dir.x, −dir.z).
		n.rotation.y = atan2(-avanti.x, -avanti.z)
		# Inclinato in curva, come chi vira davvero.
		n.rotation.z = deg_to_rad(-18.0) * signf(float(u["vel"]))

		# Il battito non è costante: un gabbiano batte qualche colpo e poi
		# plana. La planata dura più del battito, ed è quello che lo fa
		# sembrare un uccello invece di un giocattolo a molla.
		var ciclo: float = fmod(_t * 0.42 + float(u["planata"]), TAU)
		var batte: float = 1.0 if ciclo < 2.4 else 0.06
		var ang: float = sin(_t * float(u["battito"]) + float(u["fase"])) \
			* 0.62 * batte + 0.12
		for al in u["ali"]:
			al["perno"].rotation.z = ang * float(al["lato"])
