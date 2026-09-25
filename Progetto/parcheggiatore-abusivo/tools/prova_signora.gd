extends Node
## 'A Signora d''e nummere: nduvina overo una ncopp'a vinte?
##
## Questa è la prova più importante della 0.55, e non perché il codice sia
## difficile — sono trenta righe — ma perché è l'unico modo di sapere se
## la cosa **funziona**. Una promessa del tipo *"una volta su venti ti dà
## i numeri veri"* è una promessa che il giocatore non può verificare da
## solo: giocherà venti volte e non gli uscirà niente, e non saprà mai se
## è sfortuna o se è rotto. Se è rotto, non se ne accorge nessuno — ed è
## per questo che va misurato qui.
##
## Tre cose:
##
##   1. **'A quota**: una su venti, su centomila giornate. Non "circa".
##   2. **Nun se capisce quale vota è chella bbona**: i numeri sbagliati
##      devono avere la stessa forma di quelli giusti — cinque, tutti
##      diversi, ordinati, fra 1 e 90. Se si distinguessero, le altre
##      diciannove volte smetterebbero di essere attesa e diventerebbero
##      rumore.
##   3. **'O futuro sta scritto 'a matina**: i numeri di stasera esistono
##      già quando lei parla, e sono quelli che escono davvero. Senza
##      questo, la profezia sarebbe una finzione.

const Lotto := preload("res://scripts/lotto.gd")

var storte: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame

	_prova_quota()
	_prova_forma()
	_prova_futuro()
	_prova_posti()
	_prova_salvataggio()

	print("=== storte: %d ===" % storte)
	get_tree().quit()


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


# ---------------------------------------------------------------------------

func _prova_quota() -> void:
	print("=== UNA NCOPP'A VINTE ===")
	var giuste := 0
	var quante := 100000
	for i in range(quante):
		GameManager._prepara_estrazione()
		GameManager.signora_detto = {}
		GameManager.signora_data = false
		var d: Dictionary = GameManager.signora_numeri()
		if bool(d["giuste"]):
			giuste += 1
	var quota: float = float(giuste) / float(quante)
	var vuleva: float = 1.0 / float(GameManager.SIGNORA_NDUVINA)
	print("  %d ncopp'a %d = %.4f (vuleva %.4f)"
		% [giuste, quante, quota, vuleva])
	if absf(quota - vuleva) > 0.004:
		male("'a quota sta storta: %.4f invece 'e %.4f" % [quota, vuleva])

	# E in una partita da trenta giornate deve capitare una volta o due:
	# più raro e nessuno ci crede, più frequente e il lotto non è più un
	# azzardo. È il numero che giustifica il venti.
	var mai := 0
	var partite := 20000
	for p in range(partite):
		var volte := 0
		for g in range(30):
			if randi() % GameManager.SIGNORA_NDUVINA == 0:
				volte += 1
		if volte == 0:
			mai += 1
	print("  ncopp'a 30 juorne: %.0f%% d''e partite 'a veco almeno 'na vota"
		% [100.0 * (1.0 - float(mai) / float(partite))])


func _prova_forma() -> void:
	print("=== NUN SE CAPISCE ===")
	# Mille giocate: si guarda la forma dei numeri sbagliati e di quelli
	# giusti, e devono essere indistinguibili.
	var forme := {"giuste": [], "sbagliate": []}
	for i in range(4000):
		GameManager._prepara_estrazione()
		GameManager.signora_detto = {}
		var d: Dictionary = GameManager.signora_numeri()
		var n: Array = d["numeri"]
		var chiave: String = "giuste" if bool(d["giuste"]) else "sbagliate"
		# Cinque, tutti diversi, fra 1 e 90.
		var ok: bool = n.size() == Lotto.ESTRATTI
		var visti := {}
		for k in range(n.size()):
			var v: int = int(n[k])
			if v < 1 or v > Lotto.NUMERI:
				ok = false
			if visti.has(v):
				ok = false
			visti[v] = true
		if not ok:
			male("%s: nummere storte %s" % [chiave, str(n)])
		if not Lotto.RUOTE.has(str(d["ruota"])):
			male("'a rota nun esiste: %s" % str(d["ruota"]))
		forme[chiave].append(n)
	print("  %d giuste, %d sbagliate: tutte cinche nummere puliti"
		% [forme["giuste"].size(), forme["sbagliate"].size()])

	# **'O spione ca s'aggia scanzà: ll'ordine.**
	#
	# L'estrazione vera esce **disordinata** — i numeri escono uno alla
	# volta dall'urna. Al primo giro i numeri finti li ordinavo, e quella
	# riga sola bastava a far capire al giocatore, prima di spendere un
	# euro, se era la volta buona: ordinati = finti. Qui si misura quante
	# volte capita che una cinquina venga fuori già in ordine, nei due
	# mucchi: dev'essere la stessa cosa (e pochissime — una su 120).
	var ordinate := {"giuste": 0, "sbagliate": 0}
	for k in forme:
		for n in forme[k]:
			var su := true
			for j in range(1, n.size()):
				if int(n[j - 1]) > int(n[j]):
					su = false
			if su:
				ordinate[k] += 1
	for k in forme:
		var tot: int = forme[k].size()
		if tot == 0:
			continue
		var q: float = float(ordinate[k]) / float(tot)
		print("  %-10s già 'n ordine 'o %.2f%% d''e vvote" % [k, q * 100.0])
		if q > 0.06:
			male("%s: 'o %.1f%% esce già 'n ordine — se capisce" % [k, q * 100.0])

	# **'A media.** Se i numeri veri venissero da una tiratura diversa da
	# quelli finti, la media dei due mucchi sarebbe diversa, e uno che
	# gioca cento volte se ne accorgerebbe. Devono essere la stessa cosa.
	for k in ["giuste", "sbagliate"]:
		var somma := 0.0
		var conta := 0
		for n in forme[k]:
			for v in n:
				somma += float(v)
				conta += 1
		if conta == 0:
			continue
		print("  %-10s media %.1f" % [k, somma / float(conta)])


func _prova_futuro() -> void:
	print("=== 'O FUTURO STA SCRITTO 'A MATINA ===")
	# Quando dice la verità, deve dire **davvero** i numeri che escono: si
	# tira la mattina, si fa parlare lei, e poi si apre la busta la sera.
	var pruvate := 0
	var sbagliate := 0
	for i in range(3000):
		GameManager._prepara_estrazione()
		GameManager.signora_detto = {}
		GameManager.lotto_giocate = []
		var d: Dictionary = GameManager.signora_numeri()
		if not bool(d["giuste"]):
			continue
		pruvate += 1
		var dette: Array = Array(d["numeri"]).duplicate()
		var ruota: String = str(d["ruota"])
		# 'A sera: se apre 'a busta.
		GameManager.estrai_lotto()
		var asciute: Array = Array(
			Dictionary(GameManager.lotto_ultima["numeri"]).get(ruota, []))
		dette.sort()
		asciute.sort()
		if dette != asciute:
			sbagliate += 1
			if sbagliate <= 2:
				print("    detto %s, asciuto %s" % [str(dette), str(asciute)])
	print("  %d vote ha ditto 'a verità, %d nun erano overo"
		% [pruvate, sbagliate])
	if pruvate < 50:
		male("troppo poche vote p''o sapé (%d)" % pruvate)
	if sbagliate > 0:
		male("%d vote ha ditto 'a verità e nun era 'a verità" % sbagliate)

	# E quando mente, quasi sempre **non** deve azzeccarli: cinque numeri
	# su novanta a caso sono uno su quarantaquattro milioni.
	var per_caso := 0
	for i in range(3000):
		GameManager._prepara_estrazione()
		GameManager.signora_detto = {}
		GameManager.lotto_giocate = []
		var d2: Dictionary = GameManager.signora_numeri()
		if bool(d2["giuste"]):
			continue
		var dette2: Array = Array(d2["numeri"]).duplicate()
		var ruota2: String = str(d2["ruota"])
		GameManager.estrai_lotto()
		var asciute2: Array = Array(
			Dictionary(GameManager.lotto_ultima["numeri"]).get(ruota2, []))
		dette2.sort()
		asciute2.sort()
		if dette2 == asciute2:
			per_caso += 1
	print("  e %d vote ha 'nduvinato pe' caso (ce vularria 'nu miracolo)"
		% per_caso)
	if per_caso > 1:
		male("%d cinquine 'nduvinate pe' caso: 'e nummere nun so' a sciorte"
			% per_caso)


func _prova_posti() -> void:
	print("=== ADDÒ STA ===")
	if GameManager.SIGNORA_POSTI.size() < 5:
		male("troppo poche poste: %d" % GameManager.SIGNORA_POSTI.size())
	var nomi := {}
	for p in GameManager.SIGNORA_POSTI:
		if not p.has("nome") or str(p["nome"]).strip_edges() == "":
			male("'nu posto senza nomme")
		if not p.has("p"):
			male("'nu posto senza cuordinate")
			continue
		nomi[str(p["nome"])] = true
		var v: Vector3 = p["p"]
		if v.x < 2.0 or v.x > 188.0 or v.z < 2.0 or v.z > 170.0:
			male("'o posto '%s' sta fore d''a città (%.0f, %.0f)"
				% [p["nome"], v.x, v.z])
		# Mai dentro alla piazza del giocatore: se stesse sotto casa non
		# ci sarebbe niente da cercare, ed è metà della cosa.
		if v.x > 14.0 and v.x < 48.0 and v.z > 6.0 and v.z < 60.0:
			male("'o posto '%s' sta dint'â piazza toia" % p["nome"])
	if nomi.size() != GameManager.SIGNORA_POSTI.size():
		male("ce stanno duje poste cu 'o stesso nomme")
	print("  %d poste, tutte fore d''a piazza toia"
		% GameManager.SIGNORA_POSTI.size())

	# Una giornata su quattro non esce: si misura, se no è una frase.
	var mai := 0
	for i in range(20000):
		GameManager._scegli_a_signora()
		if GameManager.signora_posto < 0:
			mai += 1
	var quota: float = float(mai) / 20000.0
	print("  nun esce 'o %.1f%% d''e ghiurnate (vuleva 'o %.0f%%)"
		% [quota * 100.0, GameManager.SIGNORA_NUN_ESCE * 100.0])
	if absf(quota - GameManager.SIGNORA_NUN_ESCE) > 0.02:
		male("'a quota 'e chi nun esce sta storta")


func _prova_salvataggio() -> void:
	print("=== 'O SALVATAGGIO ===")
	# **Senza chesto se pò barà.** Se i numeri di stasera non stanno nel
	# salvataggio, uno salva la mattina, si fa dire i numeri, li gioca, e
	# se non escono ricarica: l'estrazione si rifà, e la profezia non vale
	# più niente. Peggio: si potrebbe ricaricare finché non esce la volta
	# buona.
	GameManager._prepara_estrazione()
	GameManager._scegli_a_signora()
	GameManager.signora_detto = {}
	var d: Dictionary = GameManager.signora_numeri()
	var prima: Dictionary = GameManager.lotto_stasera.duplicate(true)
	var posto: int = GameManager.signora_posto

	var testo := JSON.stringify(GameManager.stato_partita())
	var letto = JSON.parse_string(testo)
	if letto == null:
		male("'o salvataggio nun se legge")
		return
	GameManager.lotto_stasera = {}
	GameManager.signora_detto = {}
	GameManager.applica_stato(letto)

	if GameManager.lotto_stasera.size() != prima.size():
		male("'e nummere 'e stasera nun se so' salvate")
	for r in prima:
		if Array(GameManager.lotto_stasera.get(r, [])) != Array(prima[r]):
			male("'a rota %s s'è cagnata cu 'o salvataggio" % r)
			break
	if GameManager.signora_posto != posto:
		male("'o posto d''a Signora s'è perzo")
	if not GameManager.signora_data:
		male("s'è scurdata ca t'aveva già parlato: se pò richiedere")
	if Array(GameManager.signora_detto.get("numeri", [])) != Array(d["numeri"]):
		male("'e nummere ca t'ha ditto se so' cagnate")
	print("  nummere, posto e chello ca t'ha ditto: tutto salvato")
