extends Node
## Tre fermi e t'arrestano.
##
## Il capo: *"Dopo 3 volte di seguito che i carabinieri ti bloccano, non
## puoi più liberarti e ti arrestano e basta, ti svegli il giorno dopo a
## casa tua."*
##
## Quattro cose da dimostrare:
##
##   1. **'o primmo e 'o secondo se scampano** — `registra_fermo()` torna
##      `true` e la colluttazione si può vincere;
##   2. **'o secondo avvisa** — un cartello che dice che la prossima volta
##      si va dentro. Una punizione senza preavviso è una fregatura;
##   3. **'o terzo nun se scampa** — torna `false`, e il player non ha
##      tasto che tenga;
##   4. **'o conto se azzera 'a matina** — sono tre fermi in una giornata,
##      non tre in una partita. Questo è il controllo che conta di più:
##      un contatore che non si azzera trasforma tre giornate distratte in
##      una condanna permanente.

var _male: int = 0
var _cartielle: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	GameManager.event_started.connect(func(t: String) -> void: _cartielle.append(t))

	print("=== 'E TRE FERMI ===")
	GameManager.giornata = 1
	GameManager.start_shift()
	_verifica("'a matina se parte 'a zero", GameManager.fermi_oggi == 0)

	var scampa: Array = []
	for i in range(3):
		scampa.append(GameManager.registra_fermo())
	print("  fermo 1: %s · fermo 2: %s · fermo 3: %s" % [
		"se scampa" if scampa[0] else "SECCO",
		"se scampa" if scampa[1] else "SECCO",
		"se scampa" if scampa[2] else "SECCO"])
	_verifica("'o primmo se scampa", scampa[0] == true)
	_verifica("'o secondo se scampa", scampa[1] == true)
	_verifica("'o terzo è secco", scampa[2] == false)

	var avvisato := false
	for c in _cartielle:
		if str(c).findn("prossima vota te portano") >= 0:
			avvisato = true
	_verifica("'o secondo fermo avvisa", avvisato)
	_verifica("fermi_ancora() dice zero", GameManager.fermi_ancora() == 0)

	# E dal quarto in poi resta secco, non torna a scampare.
	_verifica("'o quarto è secco pur'isso", GameManager.registra_fermo() == false)

	# --- 'A nuttata dint'â cella ----------------------------------------
	print("=== 'A NUTTATA DINT'Â CELLA ===")
	GameManager.money = 200
	var umore_primma: float = GameManager.umore_moglie
	var giorno_primma: int = GameManager.giornata
	var fine: Array = []
	GameManager.shift_ended.connect(func(s: Dictionary) -> void: fine.append(s))
	GameManager.arresto_secco()
	await get_tree().process_frame
	_verifica("t'hanno arrestato", GameManager.arrested)
	# **'A cella nun se scanza cchiù** (0.56). Prima l'arresto secco
	# chiudeva la giornata seduta stante; adesso passa dalla galera, e la
	# giornata si chiude quando esci di là — o perché salti la scena col
	# tasto, o perché passano i cinque secondi. Qui si aspettano.
	_verifica("staje dint'â cella", GameManager.ncella)
	GameManager.esce_d_a_galera()
	await get_tree().process_frame
	_verifica("'a nottata è segnata", GameManager.notte_ncella)
	_verifica("'a jurnata s'è chiusa 'a sola", fine.size() == 1)
	if fine.size() == 1:
		_verifica("'o riepilogo 'o ddice",
			bool(fine[0].get("notte_ncella", false)))
		print("  ora 'e rientro segnata: %.1f (fine giornata = %.1f)" % [
			float(fine[0].get("orario_ritiro", -1.0)),
			GameManager.ORE_DI_GIORNATA])
	_verifica("Nunzia s'è arrabbiata (%d -> %d)" % [
		int(umore_primma), int(GameManager.umore_moglie)],
		GameManager.umore_moglie < umore_primma)
	_verifica("nun se torna dduje vote", _secondo_arresto_nun_fa_niente())

	# --- 'A matina appriesso -------------------------------------------
	print("=== 'A MATINA APPRIESSO ===")
	GameManager.giornata = giorno_primma + 1
	GameManager.arrested = false
	GameManager.start_shift()
	_verifica("'o conto s'è azzerato", GameManager.fermi_oggi == 0)
	_verifica("'a cella s'è scurdata", not GameManager.notte_ncella)
	_verifica("se pò scampà n'ata vota", GameManager.registra_fermo() == true)

	print("=== %d storte ===" % _male)
	get_tree().quit()


## Un secondo `arresto_secco()` mentre sei già dentro non deve rifare
## niente: la guardia in cima alla funzione è quella di `arrest_by_carabinieri`.
func _secondo_arresto_nun_fa_niente() -> bool:
	var sorde: int = GameManager.money
	GameManager.arresto_secco()
	return GameManager.money == sorde


func _verifica(che: String, ok: bool) -> void:
	if not ok:
		_male += 1
	print("  %-46s %s" % [che, "OK" if ok else "STORTO"])
