extends Node
## 'E clienti fisse: se ricordano overo?
##
## Il sistema dei clienti con il nome è fatto di quattro pezzi che stanno
## in tre file diversi, e ognuno può rompersi da solo senza che gli altri
## se ne accorgano:
##
##   1. **'a tavola** (`gente.gd`) — sei clienti, quattro vicini, e ogni
##      riga deve avere tutte le chiavi che il resto del codice legge;
##   2. **'o rapporto** (`GameManager`) — sale, scende, sta fra −100 e
##      +100, e si porta appresso il moltiplicatore `memoria`;
##   3. **'o salvataggio** — e questa è la parte che vale tutto: se il
##      rapporto non sopravvive al salva/ricarica, il sistema è un altro
##      contatore dentro la giornata, e di quelli ce n'è già;
##   4. **chi sta fore** — due Gennaro nella stessa piazza sarebbero un
##      difetto che si vede subito e si capisce tardi.
##
## E poi la cosa per cui questi clienti esistono: che **trattarli bene
## renda**. Si misura, non si spera: mille pagamenti a un amico contro
## mille a uno sconosciuto, e si guarda la differenza.

const Gente := preload("res://scripts/gente.gd")
const Car := preload("res://scripts/car_3d.gd")

var storte: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame

	_prova_tavola()
	_prova_saluti()
	_prova_rapporto()
	_prova_memoria()
	_prova_soglie()
	_prova_salvataggio()
	_prova_chi_sta_fore()
	_prova_machine()
	_prova_quanto_rende()
	_prova_vicine()
	prova_a_voce()

	print("=== storte: %d ===" % storte)
	get_tree().quit()


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


# ---------------------------------------------------------------------------

func _prova_tavola() -> void:
	print("=== 'A TAVOLA ===")
	if Gente.CLIENTI.size() < 5:
		male("troppo poca gente: %d" % Gente.CLIENTI.size())
	var viste: Array[String] = []
	var chiavi := ["id", "nome", "che", "machina", "colore", "personalita",
		"mancia", "memoria", "saluti"]
	for c in Gente.CLIENTI:
		for k in chiavi:
			if not c.has(k):
				male("%s: manca '%s'" % [c.get("id", "?"), k])
		var id := str(c["id"])
		if viste.has(id):
			male("id ddoje vote: %s" % id)
		viste.append(id)
		# La personalità deve essere una di quelle che car_3d sa leggere:
		# una scritta sbagliata qui non dà errore, dà un cliente che si
		# comporta come "normale" e nessuno se ne accorge mai.
		if not Car.PERSONALITIES.has(str(c["personalita"])):
			male("%s: personalità '%s' nun esiste" % [id, c["personalita"]])
		if not Car.CAR_TYPES.has(str(c["machina"])):
			male("%s: machina '%s' nun esiste" % [id, c["machina"]])
		var s: Dictionary = c["saluti"]
		for k2 in ["nuovo", "conosce", "amico", "nemico"]:
			if not s.has(k2) or str(s[k2]).strip_edges() == "":
				male("%s: saluto '%s' vacante" % [id, k2])
		if float(c["memoria"]) <= 0.0:
			male("%s: memoria a zero, nun se move maje" % id)
	print("  %d clienti, tutt''e chiave ce stanno" % Gente.CLIENTI.size())

	# I sei devono essere sei tipi diversi, se no sono uno solo con sei
	# nomi. Almeno tre personalità e almeno due classi di macchina.
	var pers := {}
	var mac := {}
	for c in Gente.CLIENTI:
		pers[str(c["personalita"])] = true
		mac[str(c["machina"])] = true
	if pers.size() < 3:
		male("solo %d personalità: so' tutte eguale" % pers.size())
	if mac.size() < 2:
		male("solo %d tipe 'e machina" % mac.size())
	print("  %d personalità, %d tipe 'e machina" % [pers.size(), mac.size()])


func _prova_saluti() -> void:
	print("=== 'E SALUTE ===")
	var id := "gennaro"
	var casi := [
		{"visto": 0, "rap": 0.0, "vo": "nuovo"},
		{"visto": 1, "rap": 0.0, "vo": "nuovo"},
		{"visto": 4, "rap": 0.0, "vo": "conosce"},
		{"visto": 40, "rap": 55.0, "vo": "amico"},
		{"visto": 40, "rap": -70.0, "vo": "nemico"},
		# La soglia vince sulle volte: uno che ti odia dalla seconda volta
		# ti tratta male dalla seconda volta.
		{"visto": 2, "rap": -90.0, "vo": "nemico"},
	]
	var c: Dictionary = Gente.cliente(id)
	for caso in casi:
		var detto: String = Gente.saluto(id, int(caso["visto"]),
			float(caso["rap"]))
		var atteso: String = str(c["saluti"][caso["vo"]])
		if detto != atteso:
			male("visto %d rap %.0f: vuleva '%s'" % [caso["visto"],
				caso["rap"], caso["vo"]])
	if Gente.saluto("nun_esiste", 3, 0.0) != "":
		male("'nu cliente ca nun esiste torna 'nu saluto")
	print("  %d case, tutte bbone" % casi.size())


func _prova_rapporto() -> void:
	print("=== 'O RAPPORTO ===")
	GameManager.rapporti = {}
	if GameManager.conosce("peppe"):
		male("'o canosce senza averlo visto maje")
	if not is_equal_approx(GameManager.rapporto("peppe"), 0.0):
		male("nun parte 'a zero")
	GameManager.cliente_arriva("peppe")
	if GameManager.visto_quante("peppe") != 1:
		male("nun ha contato ll'incontro")
	if not GameManager.conosce("peppe"):
		male("mo' 'o ha visto e nun 'o canosce")
	GameManager.cliente_se_ne_va("peppe")

	# I limiti: cento pagamenti non fanno duecento punti.
	for i in range(100):
		GameManager.muove_rapporto("peppe", GameManager.RAPPORTO_PAGATO)
	if GameManager.rapporto("peppe") > 100.0:
		male("passa 'e cciento: %.1f" % GameManager.rapporto("peppe"))
	for i in range(100):
		GameManager.muove_rapporto("peppe", GameManager.RAPPORTO_DANNO)
	if GameManager.rapporto("peppe") < -100.0:
		male("scenne sotto a −100: %.1f" % GameManager.rapporto("peppe"))
	print("  limmite: %.0f / %.0f" % [100.0, -100.0])

	# Un id che non sta nella tabella non deve creare niente.
	GameManager.rapporti = {}
	GameManager.muove_rapporto("nisciuno", 50.0)
	if GameManager.rapporti.has("nisciuno"):
		male("ha fatto 'nu rapporto cu uno ca nun esiste")


func _prova_memoria() -> void:
	print("=== 'A MEMORIA ===")
	# Donna Assunta ricorda il doppio, 'o Tedesco la metà: dopo lo stesso
	# numero di pagamenti il rapporto deve essere diverso, e nell'ordine
	# giusto. È l'unica cosa che rende i sei diversi fra loro nel tempo.
	GameManager.rapporti = {}
	for i in range(3):
		GameManager.muove_rapporto("assunta", GameManager.RAPPORTO_PAGATO)
		GameManager.muove_rapporto("gennaro", GameManager.RAPPORTO_PAGATO)
		GameManager.muove_rapporto("hans", GameManager.RAPPORTO_PAGATO)
	var a: float = GameManager.rapporto("assunta")
	var g: float = GameManager.rapporto("gennaro")
	var h: float = GameManager.rapporto("hans")
	print("  doppo 3 pavate: Assunta %.1f · Gennaro %.1f · 'o Tedesco %.1f"
		% [a, g, h])
	if not (a > g and g > h):
		male("'a memoria nun cagna niente: %.1f %.1f %.1f" % [a, g, h])
	if not is_equal_approx(a, g * 2.0):
		male("Assunta adda essere 'o doppio 'e Gennaro")


func _prova_soglie() -> void:
	print("=== 'E DDOJE SOGLIE ===")
	if Gente.AMICO <= 0.0 or Gente.NEMICO >= 0.0:
		male("'e soglie stanno storte")
	# Quanti pagamenti servono per diventare amico, e quanti danni per
	# diventare nemico. Se il primo numero è enorme il sistema non lo vede
	# nessuno; se il secondo è uno, ogni sbaglio è definitivo.
	for id in ["gennaro", "assunta", "hans"]:
		GameManager.rapporti = {}
		var n := 0
		while GameManager.rapporto(id) < Gente.AMICO and n < 200:
			GameManager.muove_rapporto(id, GameManager.RAPPORTO_PAGATO)
			n += 1
		GameManager.rapporti = {}
		var m := 0
		while GameManager.rapporto(id) > Gente.NEMICO and m < 200:
			GameManager.muove_rapporto(id, GameManager.RAPPORTO_DANNO)
			m += 1
		print("  %-9s amico doppo %d pavate · nemico doppo %d guaje"
			% [id, n, m])
		if n < 2 or n > 20:
			male("%s: %d pavate pe' addeventà amico" % [id, n])
		if m < 2 or m > 12:
			male("%s: %d guaje pe' addeventà nemico" % [id, m])

	# **'A regola ca vale pe' tuttuquante: 'na vota sola nun basta.**
	#
	# Non è una soglia scelta a occhio, è la differenza fra un rapporto e
	# un interruttore. Vale su tutti e tre i modi di sbagliare e su tutta
	# la tabella, memoria compresa — ed è esattamente il difetto che questa
	# prova ha trovato la prima volta che è girata (Donna Assunta,
	# ×2 memoria, diventava nemica con una rigata sola).
	print("  --- 'na vota sola ---")
	for c in Gente.CLIENTI:
		var id2 := str(c["id"])
		for danno in [GameManager.RAPPORTO_FORZATO, GameManager.RAPPORTO_DANNO,
				GameManager.RAPPORTO_DANNO * 0.6]:
			GameManager.rapporti = {}
			GameManager.muove_rapporto(id2, danno)
			if GameManager.rapporto(id2) <= Gente.NEMICO:
				male("%s addeventa nemico cu 'nu guaio sulo (%.0f × %.1f)"
					% [id2, danno, c["memoria"]])
	var peggio: float = 0.0
	for c2 in Gente.CLIENTI:
		peggio = maxf(peggio, float(c2["memoria"]))
	print("  'o peggio caso: %.0f × %.1f = %.0f, 'a soglia sta a %.0f"
		% [GameManager.RAPPORTO_DANNO, peggio,
			absf(GameManager.RAPPORTO_DANNO * peggio), absf(Gente.NEMICO)])


func _prova_salvataggio() -> void:
	print("=== 'O SALVATAGGIO ===")
	GameManager.rapporti = {}
	GameManager.cliente_arriva("ciro")
	GameManager.cliente_arriva("ciro")
	GameManager.muove_rapporto("ciro", 30.0)
	GameManager.muove_rapporto("dottore", -50.0)
	var prima_ciro: float = GameManager.rapporto("ciro")
	var prima_dott: float = GameManager.rapporto("dottore")

	# Non basta copiare il dizionario: deve passare **per il JSON**, che è
	# quello che succede davvero al salvataggio. È lì che gli interi
	# diventano virgola mobile e le chiavi diventano stringhe.
	var testo := JSON.stringify(GameManager.stato_partita())
	var letto = JSON.parse_string(testo)
	if letto == null:
		male("'o salvataggio nun se legge")
		return
	GameManager.rapporti = {}
	GameManager.applica_stato(letto)

	if not is_equal_approx(GameManager.rapporto("ciro"), prima_ciro):
		male("Ciro s'è perzo: %.1f invece 'e %.1f"
			% [GameManager.rapporto("ciro"), prima_ciro])
	if not is_equal_approx(GameManager.rapporto("dottore"), prima_dott):
		male("'o duttore s'è perzo")
	if GameManager.visto_quante("ciro") != 2:
		male("'e vvote viste nun se so' salvate: %d"
			% GameManager.visto_quante("ciro"))
	if typeof(GameManager.rapporti["ciro"]["visto"]) != TYPE_INT:
		male("'e vvote viste so' turnate 'nu numero cu 'a virgola")
	print("  Ciro %.1f (visto %d) · 'o duttore %.1f — passate p''o JSON"
		% [GameManager.rapporto("ciro"), GameManager.visto_quante("ciro"),
			GameManager.rapporto("dottore")])

	# E un salvataggio vecchio, senza la chiave, non deve far saltare
	# niente: chi ha una partita della 0.53 la deve poter riaprire.
	var vecchio: Dictionary = JSON.parse_string(testo)
	vecchio.erase("rapporti")
	GameManager.applica_stato(vecchio)
	if not GameManager.rapporti.is_empty():
		male("'nu salvataggio viecchio s'è purtato appriesso 'e rapporte")
	print("  'nu salvataggio d''a 0.53 s'arape ancora")


func _prova_chi_sta_fore() -> void:
	print("=== CHI STA FORE ===")
	GameManager.rapporti = {}
	GameManager._clienti_fore.clear()
	var pigliate: Array[String] = []
	for i in range(Gente.CLIENTI.size()):
		var id: String = GameManager.cliente_libbero()
		if id == "":
			male("s'è fernuta 'a gente troppo ampresso (a %d)" % i)
			break
		if pigliate.has(id):
			male("%s sta fore ddoje vote" % id)
		pigliate.append(id)
		GameManager.cliente_arriva(id)
	if GameManager.cliente_libbero() != "":
		male("stanno tutte fore e ne torna n'ato")
	print("  %d fore 'nzieme, e po' cchiù nisciuno" % pigliate.size())
	# E appena uno se ne va, torna disponibile.
	GameManager.cliente_se_ne_va(pigliate[0])
	if GameManager.cliente_libbero() != pigliate[0]:
		male("se n'è ghiuto e nun torna")
	GameManager._clienti_fore.clear()
	print("  se ne va uno e nn'esce n'ato")


func _prova_machine() -> void:
	print("=== 'A MACHINA È 'A FACCIA ===")
	# La stessa persona deve tornare con la stessa macchina e lo stesso
	# colore: è così che la riconosci da lontano.
	GameManager.rapporti = {}
	GameManager._clienti_fore.clear()
	var viste := {}
	var quante := 0
	for i in range(400):
		var auto = Car.new()
		auto.cliente_id = ""
		# Si chiama solo la scelta, senza costruire la macchina intera:
		# quattrocento modelli 3D in una prova sarebbero un minuto buono.
		var pigliato: bool = auto._piglia_cliente_fisso()
		if pigliato:
			quante += 1
			var id: String = auto.cliente_id
			var firma := "%s|%s" % [auto.car_type, auto.colore]
			if viste.has(id) and str(viste[id]) != firma:
				male("%s è turnato cu 'n'ata machina" % id)
			viste[id] = firma
			GameManager.cliente_se_ne_va(id)
		auto.free()
	var quota: float = float(quante) / 400.0
	print("  %d ncopp'a 400 (%.0f%%), %d facce viste"
		% [quante, quota * 100.0, viste.size()])
	# Un terzo, con il margine che ci vuole su quattrocento tirate.
	if quota < 0.24 or quota > 0.44:
		male("'a quota è %.2f, vuleva stà attuorno a 0,34" % quota)
	if viste.size() < Gente.CLIENTI.size():
		male("ncopp'a 400 machine nun se so' viste tutte quante")


func _prova_quanto_rende() -> void:
	print("=== QUANTO RENNE ESSERE AMICO ===")
	# La domanda vera: **conviene?** Se un amico paga come uno qualunque,
	# tutto questo è una decorazione. Si misurano le due cose che contano,
	# la probabilità di essere pagati e quanto lasciano, con lo stesso
	# cliente a tre rapporti diversi.
	GameManager.rapporti = {}
	GameManager._clienti_fore.clear()
	var righe := []
	for caso in [{"n": "nemico", "r": -80.0}, {"n": "'nzisto", "r": 0.0},
			{"n": "amico", "r": 80.0}]:
		var auto = Car.new()
		auto.cliente_id = "gennaro"
		auto.car_type = "economica"
		auto.personality = "normale"
		auto.minigame_score = 0.5
		GameManager.rapporti = {"gennaro": {"visto": 9, "rap": caso["r"]}}
		var ch: float = auto.payment_chance()
		var somma := 0
		for i in range(2000):
			somma += auto.payment_amount()
		var media: float = float(somma) / 2000.0
		righe.append({"n": caso["n"], "ch": ch, "media": media,
			"resa": ch * media})
		print("  %-8s paga 'o %.0f%% d''e vvote, lassa €%.2f — resa €%.2f"
			% [caso["n"], ch * 100.0, media, ch * media])
		auto.free()
	if righe[2]["resa"] <= righe[1]["resa"]:
		male("essere amico nun renne niente")
	if righe[0]["resa"] >= righe[1]["resa"]:
		male("essere nemico nun costa niente")
	# Il rapporto deve pesare, ma non deve **essere** il gioco: un amico
	# non può rendere il triplo di uno qualunque.
	var volte: float = float(righe[2]["resa"]) / float(righe[1]["resa"])
	print("  ll'amico renne %.2f vote 'o normale" % volte)
	if volte > 2.2:
		male("ll'amico renne troppo: %.2f vote" % volte)
	GameManager.rapporti = {}


func _prova_vicine() -> void:
	print("=== 'O VICINATO ===")
	if Gente.VICINE.size() < 3:
		male("troppo poca gente dint'ô vico")
	var viste: Array[String] = []
	var dicono := {}
	for v in Gente.VICINE:
		for k in ["id", "nome", "che", "chiede", "costo", "dice", "battute"]:
			if not v.has(k):
				male("%s: manca '%s'" % [v.get("id", "?"), k])
		var id := str(v["id"])
		if viste.has(id):
			male("vicino ddoje vote: %s" % id)
		viste.append(id)
		if int(v["costo"]) <= 0:
			male("%s nun chiede niente: nun è 'nu scambio" % id)
		if int(v["costo"]) > 5:
			male("%s chiede troppo: €%d" % [id, v["costo"]])
		dicono[str(v["dice"])] = true
		var b: Dictionary = v["battute"]
		for k2 in ["saluto", "pagato", "senza", "amico"]:
			if not b.has(k2) or str(b[k2]).strip_edges() == "":
				male("%s: battuta '%s' vacante" % [id, k2])
	# Quattro vicini che dicono tutti la stessa cosa sono un vicino solo.
	if dicono.size() < 3:
		male("'o vicinato dice sulo %d cose deverse" % dicono.size())
	print("  %d vicine, %d nutizie deverse" % [Gente.VICINE.size(),
		dicono.size()])
	if not Gente.vicino("nun_esiste").is_empty():
		male("'nu vicino ca nun esiste torna quaccosa")


## ---------------------------------------------------------------------
## 'A voce ca gira (0.55)
## ---------------------------------------------------------------------
##
## Il ponte fra i sei clienti fissi e tutto il resto della piazza. Fino
## alla 0.54 trattare male Donna Assunta costava **Donna Assunta** e basta:
## sei rapporti chiusi in sé, sei minigiochi separati. Ma in una piazza si
## parla, e quello che fai al secondo cliente lo sa il quarantesimo.
##
## Qui si controlla che la media funzioni, che il male pesi il doppio del
## bene (come per i rapporti singoli), e soprattutto che **non si mangi il
## gioco**: la voce deve spostare le cose di qualche punto, non deciderle.
func prova_a_voce() -> void:
	print("=== 'A VOCE CA GIRA ===")
	GameManager.rapporti = {}
	if not is_equal_approx(GameManager.voce(), 0.0):
		male("senza cliente 'a voce nun è zero")
	if not is_equal_approx(GameManager.bonus_voce(), 0.0):
		male("senza cliente 'o bonus nun è zero")

	# Chi non ti ha mai visto non conta: un rapporto a zero visite non
	# deve diluire la media di chi ti conosce davvero.
	GameManager.rapporti = {
		"gennaro": {"visto": 5, "rap": 80.0},
		"assunta": {"visto": 0, "rap": -100.0},
	}
	if GameManager.voce() < 0.7:
		male("uno ca nun t'ha visto maje se conta lo stesso: %.2f"
			% GameManager.voce())
	print("  chi nun t'ha visto nun conta: voce %.2f" % GameManager.voce())

	# Tutti amici / tutti nemici: i due estremi.
	var tutte_bbone := {}
	var tutte_male := {}
	for c in Gente.CLIENTI:
		tutte_bbone[str(c["id"])] = {"visto": 4, "rap": 100.0}
		tutte_male[str(c["id"])] = {"visto": 4, "rap": -100.0}
	GameManager.rapporti = tutte_bbone
	var su: float = GameManager.voce()
	var b_su: float = GameManager.bonus_voce()
	var m_su: float = GameManager.mancia_voce()
	GameManager.rapporti = tutte_male
	var giu: float = GameManager.voce()
	var b_giu: float = GameManager.bonus_voce()
	var m_giu: float = GameManager.mancia_voce()
	print("  tutte amice:  voce %+.2f · paga %+.0f%% · mancia ×%.2f"
		% [su, b_su * 100.0, m_su])
	print("  tutte nemice: voce %+.2f · paga %+.0f%% · mancia ×%.2f"
		% [giu, b_giu * 100.0, m_giu])
	if su < 0.99 or giu > -0.99:
		male("'e limmite nun arrivano a ±1: %.2f / %.2f" % [su, giu])
	# Il male pesa il doppio: è la stessa asimmetria dei rapporti singoli.
	if not is_equal_approx(absf(b_giu), absf(b_su) * 2.0):
		male("'o male nun pesa 'o doppio: %.3f contra %.3f" % [b_giu, b_su])
	# E non deve decidere la partita: al massimo un settimo in più.
	if b_su > 0.18:
		male("'a voce sposta troppo 'a probabilità: %+.0f%%" % (b_su * 100.0))
	if m_su > 1.25:
		male("'a voce sposta troppo 'a mancia: ×%.2f" % m_su)

	# **E 'a metà d''e ccase.** Tre amici e tre nemici devono fare zero:
	# se non lo facessero, la media sarebbe scritta male e basterebbe
	# avere un cliente in più per far pendere tutto.
	var meta := {}
	var i := 0
	for c in Gente.CLIENTI:
		meta[str(c["id"])] = {"visto": 4, "rap": 100.0 if i % 2 == 0 else -100.0}
		i += 1
	GameManager.rapporti = meta
	if absf(GameManager.voce()) > 0.01:
		male("mità e mità nun fa zero: %.3f" % GameManager.voce())
	print("  mità amice e mità nemice: voce %.2f" % GameManager.voce())
	GameManager.rapporti = {}
