extends Node
## 'E ghiornate speciale se vedono overo?
##
## Questa è una prova strana da scrivere, perché quello che il capo ha
## chiesto è **grafica**, e la grafica si giudica guardandola
## (`tools/foto_jurnate.gd` fa quello). Ma sotto alla grafica ci sono
## quattro cose che si possono misurare, e sono quelle che si rompono in
## silenzio:
##
##   1. **ogni jurnata costruisce 'a robba soia, e sulo chella** — se la
##      pioggia si costruisse anche di mercato sarebbero particelle
##      sprecate; se non si costruisse per niente nessuno se ne
##      accorgerebbe finché non gioca un giorno di pioggia;
##   2. **'na jurnata normale nun costruisce niente** — il nodo esiste
##      sempre, e deve essere vuoto quando non serve;
##   3. **'a prucessione è 'nu muro overo** — quattordici corpi con il
##      collider, che è la differenza fra "mezza piazza chiusa" e una
##      cartolina;
##   4. **'e bancarelle stregneno 'a via** — anche loro hanno il collider,
##      se no il mercato è un disegno e le macchine ci passano dentro.

const Jurnata := preload("res://scripts/jurnata_vista.gd")
const JurnataVista := Jurnata

var _male: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	GameManager.giornata = 4
	GameManager.start_shift()

	print("=== CHE SE COSTRUISCE ===")
	print("  %-14s %-10s %-10s %-10s" % ["jurnata", "particelle", "corpi solide",
		"figure"])
	for id in ["normale", "pioggia", "mercato", "processione", "partita"]:
		GameManager.tipo_giornata = str(id)
		var j = Jurnata.new()
		add_child(j)
		await get_tree().process_frame
		# La processione non esce subito: aspetta otto secondi. Qui si
		# accorcia e la si fa uscire a mano.
		if id == "processione":
			j.set("_proc_t", 0.01)
			j._passo_prucessione(0.05)
			await get_tree().process_frame
		var part: int = _conta(j, "CPUParticles3D")
		var solidi: int = _conta(j, "StaticBody3D")
		var mesh: int = _conta(j, "MeshInstance3D")
		print("  %-14s %-10d %-10d %-10d" % [id, part, solidi, mesh])

		match id:
			"normale":
				_verifica("  'a jurnata normale nun costruisce niente",
					part == 0 and solidi == 0 and mesh == 0)
			"pioggia":
				_verifica("  chiove: ce stanno 'e ddoje casse 'e gocce",
					part == 2)
				_verifica("  ma nun ce stanno mure", solidi == 0)
			"mercato":
				_verifica("  ogne bancarella tene 'o muro sujo",
					solidi == 13)
				# **E nisciuna sta dint'â piazza toia.** Una bancarella
				# piantata sui posti auto è una macchina che non si può
				# più posteggiare: il giorno di mercato il gioco si
				# romperebbe, e si romperebbe una volta su venti.
				var dinto := 0
				for b in JurnataVista.POSTI_MERCATO:
					if float(b[0]) > 14.0 and float(b[0]) < 48.0 \
							and float(b[1]) > 6.0 and float(b[1]) < 60.0:
						dinto += 1
				_verifica("  nisciuna bancarella dint'â piazza toia", dinto == 0)
				_verifica("  e nisciuna goccia", part == 0)
			"processione":
				_verifica("  'a prucessione è 'nu muro 'e 15 piezze",
					solidi >= 15)
				_verifica("  ce sta 'a statua (aureola + barella)", mesh >= 4)
			"partita":
				_verifica("  'a partita nun se disegna: se sente",
					part == 0 and solidi == 0 and mesh == 0)

		j.queue_free()
		await get_tree().process_frame

	# --- 'A pioggia va appriesso ô giocatore -----------------------------
	print("=== 'A PIOGGIA VA APPRIESSO ===")
	GameManager.tipo_giornata = "pioggia"
	var pl := Node3D.new()
	pl.add_to_group("player")
	add_child(pl)
	pl.global_position = Vector3(70, 0, 40)
	var j2 = Jurnata.new()
	add_child(j2)
	await get_tree().process_frame
	j2._process(0.016)
	var dove: Vector3 = j2.global_position
	print("  giocatore a (70, 40) -> 'a pioggia sta a (%.0f, %.0f)" % [
		dove.x, dove.z])
	_verifica("'a pioggia se mette 'ncoppa ô giocatore",
		absf(dove.x - 70.0) < 0.1 and absf(dove.z - 40.0) < 0.1)
	# E l'altezza NON deve seguire: se no salendo su un muretto il
	# quartiere sotto resta asciutto.
	pl.global_position = Vector3(70, 9.0, 40)
	j2._process(0.016)
	_verifica("ma nun saglie cu isso", absf(j2.global_position.y) < 0.01)

	# --- 'O boato d''a partita -------------------------------------------
	print("=== 'O BOATO ===")
	GameManager.tipo_giornata = "partita"
	var j3 = Jurnata.new()
	add_child(j3)
	await get_tree().process_frame
	var cartielle: Array = []
	GameManager.event_started.connect(func(t: String): cartielle.append(t))
	# Dieci minuti di partita, a passi di mezzo secondo.
	for i in range(1200):
		j3._process(0.5)
	print("  ncopp'a diece minute: %d fatte ô bar, %d-%d" % [cartielle.size(),
		int(j3.get("_gol_casa")), int(j3.get("_gol_fore"))])
	_verifica("ô bar succede quaccosa, ma nun ogne secondo",
		cartielle.size() >= 8 and cartielle.size() <= 30)
	_verifica("'o risultato se cumbina cu 'e boate",
		int(j3.get("_gol_casa")) + int(j3.get("_gol_fore")) <= cartielle.size())

	print("=== %d storte ===" % _male)
	get_tree().quit()


## Quanti nodi di un certo tipo stanno sotto a un nodo, a qualunque piano.
func _conta(dove: Node, tipo: String) -> int:
	var n := 0
	for c in dove.get_children():
		if c.get_class() == tipo:
			n += 1
		n += _conta(c, tipo)
	return n


func _verifica(che: String, ok: bool) -> void:
	if not ok:
		_male += 1
	print("  %-52s %s" % [che, "OK" if ok else "STORTO"])
