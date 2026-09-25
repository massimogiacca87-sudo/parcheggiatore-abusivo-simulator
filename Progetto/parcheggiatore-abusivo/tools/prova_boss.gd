extends Node
## 'E boss 'e capitolo: veneno, e se ne vanno 'na vota sola.
##
## Un boss che si può richiamare due volte non è un boss di capitolo: è un
## distributore di scontri. E uno che non arriva mai è una riga di roadmap
## scritta e non fatta. Qui si controlla il ciclo intero — si arma quando
## prendi la piazza, esce **la sera**, e qualunque cosa succeda dopo
## (paghi, accetti, lo stendi, ti scade il tempo) **non torna più**.
##
## E poi le tre uscite, che devono essere tre cose diverse e non tre modi
## di dire la stessa: soldi subito, una parte per tre giorni, o le mazzate.

const Boss := preload("res://scripts/boss_capitolo_3d.gd")

var storte: int = 0


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	GameManager.start_shift()

	_prova_tavola()
	_prova_quanno_esce()
	await _prova_paga()
	await _prova_parte()
	await _prova_mazzate()
	await _prova_scade()
	_prova_salvataggio()

	print("=== storte: %d ===" % storte)
	get_tree().quit()


func _pulisci() -> void:
	GameManager.boss_da_fa = []
	GameManager.boss_fatte = []
	GameManager.boss_parte_juorne = 0
	GameManager.zone_mie = ["piazza"]
	GameManager.shift_active = true


func _prova_tavola() -> void:
	print("=== 'A TAVOLA ===")
	var Citta = load("res://scripts/citta_3d.gd")
	var vuole := {}
	for k in GameManager.BOSS_CAPITOLO:
		var b: Dictionary = GameManager.BOSS_CAPITOLO[k]
		for chiave in ["nome", "che", "vuole", "quanto", "dice"]:
			if not b.has(chiave):
				male("%s: manca '%s'" % [k, chiave])
		vuole[str(b["vuole"])] = true
		# Ogni boss deve stare su una zona che esiste davvero, se no non
		# esce mai e non se ne accorge nessuno.
		var trovata := false
		for z in Citta.ZONE:
			if str(z["id"]) == k:
				trovata = true
		if not trovata:
			male("'o boss '%s' sta ncopp'a 'na zona ca nun esiste" % k)
	# **'A piazza toia nun tene boss**, e ci vuole: è casa tua da sempre.
	if GameManager.BOSS_CAPITOLO.has("piazza"):
		male("pure 'a piazza toia tene 'nu boss")
	# Tre richieste diverse: se fossero tutte "sorde" sarebbero tre nomi
	# sullo stesso personaggio.
	if vuole.size() < 3:
		male("'e boss vonno sulo %d cose deverse" % vuole.size())
	print("  %d boss, %d cose deverse ca vonno"
		% [GameManager.BOSS_CAPITOLO.size(), vuole.size()])


func _prova_quanno_esce() -> void:
	print("=== QUANNO ESCE ===")
	_pulisci()
	if GameManager.boss_capitolo_stasera() != "":
		male("esce 'nu boss senza ca t'hê pigliato niente")
	GameManager.acquisisci_zona("stadio", "Stadio", true, 30)
	if not GameManager.boss_da_fa.has("stadio"):
		male("pigliata 'a piazza, 'o boss nun s'è armato")
	if GameManager.boss_capitolo_stasera() != "stadio":
		male("nun esce 'o boss d''o stadio")
	print("  pigliato 'o stadio -> stasera vene 'o Cardinale")

	# Uno per sera: due piazze prese insieme non fanno una rissa.
	GameManager.acquisisci_zona("mercato", "Mercato", true, 30)
	var uno: String = GameManager.boss_capitolo_stasera()
	if uno == "":
		male("cu ddoje piazze nun esce nisciuno")
	print("  ddoje piazze 'nzieme -> esce uno sulo (%s)" % uno)

	# E se la piazza non è più tua, il suo boss non esce.
	GameManager.zone_mie = ["piazza"]
	if GameManager.boss_capitolo_stasera() != "":
		male("esce 'o boss 'e 'na piazza ca nun è cchiù 'a toia")
	print("  piazza perza -> 'o boss suio nun esce")


func _mette(zona: String) -> Node:
	var b = Boss.new()
	b.configura(zona, GameManager.boss_capitolo(zona))
	add_child(b)
	await get_tree().process_frame
	return b


func _prova_paga() -> void:
	print("=== 'O CARDINALE: SORDE ===")
	_pulisci()
	GameManager.acquisisci_zona("stadio", "Stadio", true, 0)
	var b = await _mette("stadio")
	var costo: int = int(GameManager.BOSS_CAPITOLO["stadio"]["quanto"])

	# Senza soldi non si chiude: non deve regalare niente.
	GameManager.money = costo - 1
	b.player_interact()
	if GameManager.boss_fatte.has("stadio"):
		male("s'è chiuso senza pavà")
	print("  senza sorde: nun se chiude")

	GameManager.money = costo + 50
	b.player_interact()
	if GameManager.money != 50:
		male("ha pigliato €%d invece 'e €%d" % [costo + 50 - GameManager.money, costo])
	if not GameManager.boss_fatte.has("stadio"):
		male("pavato, e nun s'è chiuso")
	if GameManager.boss_da_fa.has("stadio"):
		male("pavato, e sta ancora 'n lista")
	if not GameManager.zona_mia("stadio"):
		male("hê pavato e t'hê perza 'a piazza")
	print("  pavati €%d: 'a piazza resta 'a toia e nun torna cchiù" % costo)
	b.free()


func _prova_parte() -> void:
	print("=== DONNA CARMELA: 'A PARTE ===")
	_pulisci()
	GameManager.acquisisci_zona("mercato", "Mercato", true, 0)
	var b = await _mette("mercato")
	GameManager.money = 500
	var prima: int = GameManager.money
	var mancia_prima: float = GameManager.mancia_piazza("mercato")
	b.player_interact()
	if GameManager.money != prima:
		male("s'è pigliata 'e sorde: essa nun 'e vuleva")
	if GameManager.boss_parte_juorne <= 0:
		male("accettato, e nun tene 'a parte soia")
	var mancia_doppo: float = GameManager.mancia_piazza("mercato")
	if mancia_doppo >= mancia_prima:
		male("'a parte nun se sente ncopp'ê mance: %.2f -> %.2f"
			% [mancia_prima, mancia_doppo])
	print("  accettato: %d juorne, e 'a mancia scenne 'a %.2f a %.2f"
		% [GameManager.boss_parte_juorne, mancia_prima, mancia_doppo])
	if not GameManager.boss_fatte.has("mercato"):
		male("accettato, e nun s'è chiuso")

	# E dopo tre sere torna tutto come prima.
	for sera in range(int(GameManager.BOSS_CAPITOLO["mercato"]["quanto"])):
		GameManager.boss_parte_juorne = maxi(0, GameManager.boss_parte_juorne - 1)
	if not is_equal_approx(GameManager.mancia_piazza("mercato"), mancia_prima):
		male("doppo 'e tre juorne 'a mancia nun è turnata")
	print("  doppo %d juorne torna tutto comme a primma"
		% int(GameManager.BOSS_CAPITOLO["mercato"]["quanto"]))
	b.free()


func _prova_mazzate() -> void:
	print("=== TONINO: SULO MAZZATE ===")
	_pulisci()
	GameManager.acquisisci_zona("cornetteria", "Cornetteria", true, 0)
	var b = await _mette("cornetteria")
	GameManager.money = 9999
	# Con lui [E] non chiude niente: non tratta.
	b.player_interact()
	if GameManager.boss_fatte.has("cornetteria"):
		male("Tonino s'è chiuso cu 'na chiacchierata: isso nun tratta")
	print("  [E] nun serve a niente: nun tratta")

	var colpi := 0
	while b.stato != Boss.Stato.STESO and colpi < 200:
		b.receive_punch(5)
		colpi += 1
	print("  stiso doppo %d colpe 'a cinche" % colpi)
	if colpi < 8:
		male("se stenne cu %d colpe: è troppo poco pe' 'nu boss" % colpi)
	if colpi > 40:
		male("ce vonno %d colpe: nun 'o stenne nisciuno" % colpi)
	if not GameManager.boss_fatte.has("cornetteria"):
		male("stiso, e nun s'è chiuso")
	if not GameManager.zona_mia("cornetteria"):
		male("ll'hê stiso e t'hê perza 'a piazza")
	b.free()


func _prova_scade() -> void:
	print("=== SI NUN CE VAJE ===")
	_pulisci()
	GameManager.acquisisci_zona("stadio", "Stadio", true, 30)
	GameManager.assumi("stadio", "'O Lassato")
	var b = await _mette("stadio")
	b._se_ripiglia_a_piazza()
	if GameManager.zona_mia("stadio"):
		male("è scaduto 'o tiempo e 'a piazza è ancora 'a toia")
	if GameManager.affitti.has("stadio"):
		male("perza 'a piazza e pave ancora ll'affitto")
	if GameManager.ha_dipendente("stadio"):
		male("perza 'a piazza e 'o guaglione fatica ancora llà")
	if not GameManager.boss_fatte.has("stadio"):
		male("s'è ripigliato 'a piazza e po' torna n'ata vota")
	print("  scaduto: piazza perza, affitto e guaglione pure. E nun torna.")
	b.free()


func _prova_salvataggio() -> void:
	print("=== 'O SALVATAGGIO ===")
	_pulisci()
	GameManager.acquisisci_zona("mercato", "Mercato", true, 0)
	GameManager.boss_parte_juorne = 2
	GameManager.boss_fatte = ["stadio"]
	var testo := JSON.stringify(GameManager.stato_partita())
	var letto = JSON.parse_string(testo)
	GameManager.boss_da_fa = []
	GameManager.boss_fatte = []
	GameManager.boss_parte_juorne = 0
	GameManager.applica_stato(letto)
	if not GameManager.boss_da_fa.has("mercato"):
		male("'o boss ca t'aspetta s'è perzo cu 'o salvataggio")
	if not GameManager.boss_fatte.has("stadio"):
		male("'o boss già fatto s'è perzo: torna n'ata vota")
	if GameManager.boss_parte_juorne != 2:
		male("'e juorne 'e Donna Carmela se so' perze")
	print("  chi t'aspetta, chi s'è fatto e 'e juorne: tutto salvato")
