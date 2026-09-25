extends Node
## **'O tutoriale ca parla napulitano** (0.56, punto 4).
##
## Il capo: *«Tra le frasi dei vari png, aggiungi frasi tutorial, che aiutino
## il player a capire certe meccaniche… Se vuoi puoi anche aggiungere un
## personaggio tutorial al quale è possibile chiedere delucidazioni su
## meccaniche del gioco.»*
##
## Un tutorial lo si può scrivere bene e sbagliare lo stesso, e il modo di
## sbagliarlo è uno solo: **dirti una cosa che non ti serve**. «Accattate 'e
## sigarette» a uno che ne tiene venti non è un consiglio inutile, è
## peggio — insegna che quello che dicono i passanti non vale la pena di
## leggerlo, e da lì in poi il giocatore salta tutte le frasi, comprese
## quelle buone.
##
## Quindi la prova non guarda se le frasi ci sono: guarda **se escono
## quando servono e se stanno zitte quando non servono**. Si costruisce uno
## stato del gioco alla volta — senza sigarette, senza coppola, col fiato a
## terra — e si controlla che esca quella giusta e nessun'altra.
##
## E poi Don Gaetano: che si possa arrivare a tutte le sue risposte girando
## le pagine, e che l'ultima pagina chiuda invece di girare a vuoto.

const Chiac := preload("res://scripts/chiacchiere.gd")
const Maestro := preload("res://scripts/maestro_3d.gd")

var storte: int = 0
var _rng := RandomNumberGenerator.new()


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 4560
	await get_tree().process_frame

	_prova_e_frase()
	_prova_ê_cundizione()
	_prova_quanto_spisso()
	_prova_o_prufessore()

	print("=== storte: %d ===" % storte)
	get_tree().quit()


# ---------------------------------------------------------------------------
# 'E frase: ce stanno e songo scritte bbone?
# ---------------------------------------------------------------------------

func _prova_e_frase() -> void:
	print("=== 'E FRASE ===")
	print("  %d cunziglie" % Chiac.CUNZIGLIE.size())
	if Chiac.CUNZIGLIE.size() < 10:
		male("so' sulo %d: 'nu tutoriale 'e cinche righe nun 'mpara niente"
			% Chiac.CUNZIGLIE.size())
	var viste := {}
	for c in Chiac.CUNZIGLIE:
		var id: String = str(c["id"])
		if viste.has(id):
			male("'o cunziglio '%s' sta doje vote" % id)
		viste[id] = true
		var dice: String = str(c["dice"])
		if dice.length() < 40:
			male("'o cunziglio '%s' è troppo curto: nun spiega niente" % id)
		if dice.length() > 260:
			male("'o cunziglio '%s' è 'nu papiello (%d lettere)"
				% [id, dice.length()])
		# **E ha da essere napulitano.** È la regola del progetto e vale
		# pure qua: se una riga del tutorial è scritta in italiano si sente
		# subito che l'ha scritta un altro.
		if not _pare_napulitano(dice):
			male("'o cunziglio '%s' nun pare napulitano: «%s»" % [id, dice])
	# E i due che il capo ha chiesto per nome ci devono stare.
	for id in ["sigarette", "bacheca"]:
		if not viste.has(id):
			male("manca 'o cunziglio '%s', ca 'o capo ha chiesto pe' nomme"
				% id)
	print("  'e ddoje ca 'o capo ha chiesto ce stanno")


## Un controllo grezzo ma onesto: in napoletano scritto come lo scriviamo
## qua dentro ci sono gli apostrofi dell'elisione (`'o`, `'a`, `d''o`) o le
## parole che in italiano non esistono. Se in una riga non c'è niente di
## tutto questo, quella riga è italiano.
func _pare_napulitano(t: String) -> bool:
	for segno in ["'o ", "'a ", "'e ", "d''", "ll'", "'n", "ca ", "nun ",
			"ce ", "te ", "sî", "hê", "guagliò", "cchiù", "cu "]:
		if t.contains(segno):
			return true
	return false


# ---------------------------------------------------------------------------
# 'E cundizione: esce sulo chello ca serve
# ---------------------------------------------------------------------------

## Rimette il gioco in uno stato in cui non serve nessun consiglio: tutto
## comprato, tutto pieno, niente in tasca da vendere.
func _tutto_appost() -> void:
	var gm := GameManager
	gm.cigarettes = 12
	gm.commissioni_viste = 3
	gm.upgrades = {"coppola": true}
	gm.arma_in_mano = "mazza"
	gm.sciato = gm.SCIATO_MAX
	gm.emblems = {}
	gm.heat = 0.0
	gm.health = gm.HEALTH_MAX
	gm.money = 10
	gm.placed_decor = [{"id": "piante", "pos": [0, 0, 0], "rot": 0.0}]
	gm.shift_time_left = gm.shift_duration * 0.72  # ~16:30, primma d''e vinte
	Chiac._urdemo = ""


func _esce(id: String) -> bool:
	for c in Chiac._cunziglie_bbone():
		if str(c["id"]) == id:
			return true
	return false


func _prova_ê_cundizione() -> void:
	print("=== QUANNO ESCENO ===")
	# Ogni riga: che si tocca, che deve uscire.
	var casi := [
		["sigarette", func(): GameManager.cigarettes = 0],
		["bacheca", func(): GameManager.commissioni_viste = 0],
		["coppola", func():
			GameManager.upgrades = {}
			GameManager.money = 50],
		["armiere", func():
			GameManager.arma_in_mano = ""
			GameManager.money = 50],
		["sciato", func(): GameManager.sciato = 10.0],
		["stemme", func():
			GameManager.emblems = {"Stemma": {"count": 1, "value": 8}}],
		["ombrellone", func(): GameManager.heat = 70.0],
		["cornetto", func():
			GameManager.health = GameManager.HEALTH_MAX * 0.2],
		["piazza", func():
			GameManager.money = GameManager.NEXT_ZONE_GOAL + 10],
		["salotto", func():
			GameManager.placed_decor = []
			GameManager.money = 100],
	]
	print("  %-12s %-10s %s" % ["cunziglio", "quanno serve", "quanno no"])
	for caso in casi:
		var id: String = str(caso[0])
		# Prima: niente da consigliare su questo argomento.
		_tutto_appost()
		var senza: bool = _esce(id)
		# Poi: la cosa manca davvero.
		_tutto_appost()
		caso[1].call()
		var cu: bool = _esce(id)
		print("  %-12s %-10s %s" % [id, "sì" if cu else "NO",
			"zitto" if not senza else "PARLA"])
		if not cu:
			male("'o cunziglio '%s' nun esce manco quanno serve" % id)
		if senza:
			male("'o cunziglio '%s' esce pure quanno nun serve a niente" % id)

	# E la regola che tiene su tutto: **due volte di fila mai**.
	_tutto_appost()
	GameManager.cigarettes = 0
	Chiac._urdemo = "sigarette"
	if _esce("sigarette"):
		male("'o stesso cunziglio se ripete doje vote 'e fila")
	else:
		print("  nun se ripete maje doje vote 'e fila")

	# E a suspetto alto nessuno ti spiega niente: hai altro a cui pensare.
	_tutto_appost()
	GameManager.cigarettes = 0
	GameManager.heat = 85.0
	var quante := 0
	for _i in range(200):
		var b: Dictionary = Chiac.battuta(_rng, false)
		if int(b["tono"]) == Chiac.Tono.CUNZIGLIO:
			quante += 1
	print("  cu 'o suspetto a 85: %d cunziglie ncopp'a 200" % quante)
	if quante > 0:
		male("cu 'e vigile 'ncuollo se mettono pure a spiegà 'o mestiere")
	_tutto_appost()


# ---------------------------------------------------------------------------
# Quanto spisso: assaje 'o primmo juorno, poco doppo
# ---------------------------------------------------------------------------

func _prova_quanto_spisso() -> void:
	print("=== QUANTO SPISSO ===")
	for g in [1, 3, 5, 12]:
		GameManager.giornata = g
		var q: float = Chiac.quanto_spisso()
		print("  juorno %-3d %.0f%% d''e vote" % [g, q * 100.0])
		if q <= 0.0 or q > 0.6:
			male("ô juorno %d 'e cunziglie escono 'o %.0f%%: nun va bbuono"
				% [g, q * 100.0])
	GameManager.giornata = 1
	if Chiac.quanto_spisso() <= Chiac.CUNZIGLIO_DOPPO:
		male("'o primmo juorno 'e cunziglie nun so' cchiù spisse")
	GameManager.giornata = 20
	if absf(Chiac.quanto_spisso() - Chiac.CUNZIGLIO_DOPPO) > 0.001:
		male("doppo vinte juorne nun s'è assettato ô minimo")
	GameManager.giornata = 1


# ---------------------------------------------------------------------------
# Don Gaetano
# ---------------------------------------------------------------------------

func _prova_o_prufessore() -> void:
	print("=== DON GAETANO ===")
	print("  %d dimanne" % Maestro.LEZIONE.size())
	if Maestro.LEZIONE.size() < 8:
		male("sulo %d dimanne: nun è 'nu maestro, è 'nu cartello"
			% Maestro.LEZIONE.size())
	for v in Maestro.LEZIONE:
		if not _pare_napulitano(str(v["dice"])):
			male("Don Gaetano parla taliano: «%s»" % str(v["dice"]))
		if str(v["dimanna"]).length() > 40:
			male("'a dimanna «%s» nun trase dint'ô pannello"
				% str(v["dimanna"]))

	# **Se ce se arriva a tutte quante?** Il pannello ne tiene quattro per
	# volta e la quarta riga gira pagina: girando si deve poter leggere
	# ogni domanda, e l'ultima pagina deve chiudere invece di girare a
	# vuoto. È il modo classico di perdere le ultime tre voci di un menu.
	var m = Maestro.new()
	add_child(m)
	var viste := {}
	var pagine := 0
	m._pagina = 0
	while pagine < 20:
		pagine += 1
		var r: Array = m._risposte()
		if r.size() > 4:
			male("'a pagina %d tene %d righe: 'o pannello ne piglia 4"
				% [pagine, r.size()])
		for voce in r:
			viste[str(voce["text"])] = true
		var ultima: String = str(r[r.size() - 1]["text"])
		if ultima.begins_with("Basta"):
			break
		m._pagina += 1
	print("  %d pagine, %d righe viste" % [pagine, viste.size()])
	if pagine >= 20:
		male("'e pagine nun fernesceno maje")
	for v in Maestro.LEZIONE:
		if not viste.has(str(v["dimanna"])):
			male("«%s» nun se po' chiedere a nisciuna pagina"
				% str(v["dimanna"]))
	print("  tutt' 'e dimanne se ponno fà")
	m.queue_free()
