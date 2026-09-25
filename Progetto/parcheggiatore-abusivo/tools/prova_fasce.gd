extends Node
## 'E ffasce d''a jurnata: mezzogiorno, 'e ttre, ll'aperitivo, 'e
## rristorante, 'a nuttata.
##
## Tre cose da dimostrare, e la terza è quella che conta:
##
##   1. la fascia **combacia con l'orologio** — se il quadrante dice 21:30
##      la fascia dev'essere quella dei ristoranti, non un'altra;
##   2. i due numeri (attesa e mancia) **vanno in direzione opposta**, che
##      è il motivo per cui le fasce esistono: ore morte = poche macchine
##      e mance magre, notte = poche macchine e mance grasse;
##   3. la fascia **si annuncia una volta sola** quando cambia. Il rischio
##      vero di un sistema così è che `_process` sputi lo stesso cartello
##      sessanta volte al secondo.

var _male: int = 0
var _annunci: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	GameManager.event_started.connect(func(t: String) -> void: _annunci.append(t))
	GameManager.giornata = 1
	GameManager.start_shift()

	print("=== 'E FFASCE D''A JURNATA ===")
	print("  %-8s %-16s %-8s %-8s" % ["orologio", "fascia", "attesa", "mancia"])

	# Ventiquattro assaggi lungo le sedici ore: uno ogni quaranta minuti.
	var attesi := {
		12: "'a controra", 13: "'a controra", 14: "'a controra",
		15: "'e ttre morte", 16: "'e ttre morte", 17: "'e ttre morte",
		18: "ll'aperitivo", 19: "ll'aperitivo", 20: "ll'aperitivo",
		21: "'e rristorante", 22: "'e rristorante", 23: "'e rristorante",
		24: "'a nuttata", 25: "'a nuttata", 26: "'a nuttata", 27: "'a nuttata",
	}
	for passo in range(24):
		var ore: float = float(passo) * (16.0 / 24.0)
		GameManager.shift_time_left = GameManager.shift_duration \
			* (1.0 - ore / GameManager.ORE_DI_GIORNATA)
		var nome: String = GameManager.fascia_nome()
		var vera: String = str(attesi[int(floor(ore + 12.0))])
		var ok: bool = nome == vera
		if not ok:
			_male += 1
		print("  %-8s %-16s %-8.2f %-8.2f %s" % [
			GameManager.orologio(), nome,
			GameManager.attesa_fascia(), GameManager.mancia_fascia(),
			"" if ok else "STORTO: aspettavo %s" % vera])

	# --- 'E ddoje direzione ---------------------------------------------
	# Le ore morte devono essere peggio di quelle piene su TUTT'E DUE i
	# numeri; la notte peggio sugli arrivi e molto meglio sulle mance.
	var morte: Dictionary = GameManager.FASCE[1]
	var piene: Dictionary = GameManager.FASCE[3]
	var notte: Dictionary = GameManager.FASCE[4]
	_verifica("'e ttre so' cchiù vacante d''e nnove",
		float(morte["attesa"]) > float(piene["attesa"]))
	_verifica("'e ttre pavano 'e meno d''e nnove",
		float(morte["mancia"]) < float(piene["mancia"]))
	_verifica("'a notte vene poca gente",
		float(notte["attesa"]) > float(piene["attesa"]))
	_verifica("ma chi vene 'a notte pava assaje",
		float(notte["mancia"]) > float(piene["mancia"]) * 1.4)

	# --- 'O cartello nun s'adda ripetere --------------------------------
	print("=== 'O CARTIELLO ===")
	_annunci.clear()
	GameManager._fascia_detta = -1
	GameManager.shift_time_left = GameManager.shift_duration
	# Duecento passate dentro la stessa fascia: il primo giro non annuncia
	# niente (è l'inizio del turno), gli altri centonovantanove nemmeno.
	for i in range(200):
		GameManager._passo_fasce()
	_verifica("'a primma fascia nun se strilla (%d cartielle)" % _annunci.size(),
		_annunci.size() == 0)

	# Adesso si passa alle tre: un cartello, e uno solo.
	GameManager.shift_time_left = GameManager.shift_duration \
		* (1.0 - 3.5 / GameManager.ORE_DI_GIORNATA)
	for i in range(200):
		GameManager._passo_fasce()
	_verifica("'o cagno se dice 'na vota sola (%d cartielle)" % _annunci.size(),
		_annunci.size() == 1)
	if _annunci.size() > 0:
		print("    -> %s" % str(_annunci[0]))

	# --- 'A mancia se piglia 'a fascia ----------------------------------
	# Il numero deve arrivare davvero fino a chi paga, non restare in una
	# funzione che nessuno chiama.
	print("=== 'A MANCIA ===")
	GameManager.shift_time_left = GameManager.shift_duration \
		* (1.0 - 4.0 / GameManager.ORE_DI_GIORNATA)      # 'e ttre morte
	var a_ttre: float = GameManager.bonus_mancia()
	GameManager.shift_time_left = GameManager.shift_duration \
		* (1.0 - 14.0 / GameManager.ORE_DI_GIORNATA)     # 'e ddoje 'e notte
	var a_notte: float = GameManager.bonus_mancia()
	print("  bonus_mancia() ê ttre: %.2f  ·  ê ddoje 'e notte: %.2f" % [
		a_ttre, a_notte])
	_verifica("'a notte 'a mancia è cchiù grossa 'e 'na vota e mmeza",
		a_notte > a_ttre * 1.5)

	print("=== %d storte ===" % _male)
	get_tree().quit()


func _verifica(che: String, ok: bool) -> void:
	if not ok:
		_male += 1
	print("  %-52s %s" % [che, "OK" if ok else "STORTO"])
