extends Node
## 'O fummetto: 'o bianco adda essere cchiù gruosso d''e llettere.
##
## La 0.50 ha rifatto il fumetto misurando il testo invece di indovinarlo,
## e la misura è quella giusta — ma **misurare non basta se poi il Label3D
## disegna con un'altra regola**. Questa prova non si fida del conto: mette
## in scena il fumetto vero, si fa dare da Godot l'ingombro effettivo delle
## lettere (`Label3D.get_aabb()`, che è la scatola che il motore disegna
## davvero) e lo confronta con il quad bianco.
##
## Il patto è semplice: **il bianco deve stare largo attorno al nero**, con
## almeno mezzo margine per parte. Se il testo tocca il bordo, o peggio lo
## supera, qui si vede — e si vede su ogni frase, non su quella che
## capita di guardare nello screenshot.
##
## **E si misura a cinque distanze**, che è la parte che nella 0.50
## mancava. Il fumetto si rimpicciolisce con la distanza, e il guasto
## grosso stava proprio lì: la scala se la teneva il testo e non il quad
## bianco (`billboard_keep_scale`). A tre metri e venti — la distanza di
## riferimento, dove la scala vale 1 — tutto tornava, e infatti da fermo
## non si vedeva niente. Una prova a una distanza sola era una prova che
## non poteva trovarlo.

const Fummetto := preload("res://scripts/speech_bubble.gd")

## Le frasi vere del gioco, dalla più corta alla più lunga: la parola
## sola, la battuta, la frase piena, e quella che va troncata.
const FRASI := [
	"Tiè.",
	"AHIA!",
	"Uè guagliò, addò sta 'o rre?",
	"Tiè, professò… e pigliatìlle tutte quante!",
	"Aspiè… aspiè ca mo' m'arricordo addò tengo 'o puórtafoglio…",
	"Mezzanotte: poca gente, ma se pava 'o doppio.",
	"Semplice: vincecinche euro mo', pe' me fa' venì. Po' ogni machina ca metto, "
		+ "'e sorde 'e tengo io. 'A sera passe, m''e chiamme, e te dongo 'o settanta.",
	"MMMMMMM MMMMMMM MMMMMMM",
	"Antidisestablishmentarianismo",
]

## Le distanze a cui si guarda. 3,2 e' quella di riferimento (scala 1) e
## fino alla 0.50 era l'unica provata; 1,0 e' il vascio, dove si parla
## faccia a faccia; 8,0 e' mezza piazza.
const DISTANZE := [1.0, 3.2, 8.0]

var _male: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame

	# Una camera serve: `_misura()` scala il fumetto sulla distanza, e senza
	# camera esce dalla funzione senza toccare niente.
	var cam := Camera3D.new()
	add_child(cam)
	cam.current = true
	await get_tree().process_frame

	for d in DISTANZE:
		await _giro(cam, float(d))

	print("=== %d storte ===" % _male)
	get_tree().quit()


## Un giro completo di frasi a una distanza sola.
func _giro(cam: Camera3D, dist: float) -> void:
	cam.global_position = Vector3(0, 0, dist)
	cam.current = true
	await get_tree().process_frame
	var vera: Camera3D = get_viewport().get_camera_3d()
	print("=== 'O FUMMETTO A %.1f METRE ===  (camera: %s, %s)" % [dist,
		"'a mia" if vera == cam else "n'ata",
		"(%.1f, %.1f, %.1f)" % [vera.global_position.x, vera.global_position.y,
			vera.global_position.z] if vera != null else "nisciuna"])
	print("  %-13s %-13s %-6s %-6s %s" % [
		"bianco (l x a)", "nero (l x a)", "lati", "sopra", "frase"])

	for t in FRASI:
		# **'A camera s''a piglia 'a citta'.** La scena vera parte lo stesso
		# sotto a questa prova, e appena il giocatore e' in piedi la sua
		# camera diventa quella corrente: da li' in poi il fumetto misurava
		# la distanza dal giocatore, non da noi. Si riprende ogni giro.
		cam.current = true
		var b = Fummetto.new()
		add_child(b)
		b.global_position = Vector3.ZERO
		b.say(str(t), 30.0)
		await get_tree().process_frame
		await get_tree().process_frame

		var lab: Label3D = b.get("_label")
		var bg: MeshInstance3D = b.get("_bg")
		# **Quello che si confronta e' il DISEGNATO, non il dichiarato.**
		# La misura del quad e' quella di partenza; per sapere quanto grande
		# viene disegnato ci vuole la scala del nodo, che e' proprio la cosa
		# che il materiale billboard buttava via.
		var s: float = b.scale.x
		var quad: Vector2 = (bg.mesh as QuadMesh).size * s
		var aabb: AABB = lab.get_aabb()
		var nero := Vector2(aabb.size.x, aabb.size.y) * s
		# Quanto bianco avanza per parte, in centimetri.
		var lati: float = (quad.x - nero.x) * 50.0
		var sopra: float = (quad.y - nero.y) * 50.0
		var testo: String = str(lab.text).replace("\n", " ")
		var ok: bool = lati >= 1.5 and sopra >= 0.8
		if not ok:
			_male += 1
		print("  %5.2f x %5.2f %5.2f x %5.2f %-6.1f %-6.1f %s%s" % [
			quad.x, quad.y, nero.x, nero.y, lati, sopra,
			testo.substr(0, 40),
			"" if ok else "   <<< STORTO: 'o nero tocca 'o bianco"])
		b.queue_free()
		await get_tree().process_frame
