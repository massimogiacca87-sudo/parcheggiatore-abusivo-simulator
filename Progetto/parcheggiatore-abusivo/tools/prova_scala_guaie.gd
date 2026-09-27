extends Node
## **'A scala d''e guaie** (0.65): sette sere senza pavà, e fernesce.
##
## Il capo: *«Giorno dopo giorno, le spese non pagate si accumulano con
## conseguenze disastrose e esilaranti, fino al game over [...] quando non
## paghi per una settimana.»*
##
## La prova gioca le sere nel GameManager vero, con la città in piedi:
##   1. sette sere senza consegnare niente: un gradino a sera, ognuno col suo
##      guaio (luce, gas, suocera, porta chiusa, avvocato), e alla settima
##      la partita finisce e compare la schermata «FERNUTA»;
##   2. col quinto gradino la porta non si apre, i soldi passano sotto la
##      porta e si dorme sui cartoni; i carabinieri ti lasciano fuori;
##   3. chi paga tutto torna a terra: Nunzia riapre, la suocera se ne va;
##   4. la spesa non pagata diventa il conto del salumiere (metà, e si somma);
##   5. «Ricomincia da capo» rimette la partita al giorno uno;
##   6. chi lavora onesto (entra €110 al giorno e paga) non sale mai la scala.

var storte: int = 0
var _persa: Dictionary = {}


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(120):
		await get_tree().process_frame
	get_tree().paused = false
	var gm := GameManager
	gm.partita_persa.connect(_su_persa)
	seed(11)

	print("=== 1. SETTE SERE SENZA PAVÀ ===")
	_azzera()
	var attesi := {2: "luce", 3: "gas", 4: "suocera", 5: "cacciato", 6: "avvocato"}
	for sera in range(1, 8):
		gm.start_shift()
		gm.money = 0
		var r: Dictionary = gm.vai_a_dormire()
		await get_tree().process_frame
		print("  sera %d: debbito %d, dovuto €%d, guaie: %s" % [sera,
			gm.giorni_debbito, gm.spese_dovute(), str(r.get("conseguenze", []).size())])
		if gm.giorni_debbito != sera:
			male("sera %d senza pavà, e 'a scala dice %d" % [sera, gm.giorni_debbito])
		if attesi.has(sera):
			var cosa: String = attesi[sera]
			var ok := false
			match cosa:
				"luce": ok = gm.luce_staccata and gm._spesa_aperta_di("riallaccio")
				"gas": ok = gm.gas_staccato and gm._spesa_aperta_di("gas")
				"suocera": ok = gm.suocera_in_casa
				"cacciato": ok = gm.cacciato_e_casa
				"avvocato": ok = gm._spesa_aperta_di("avvocato")
			if not ok:
				male("sera %d: nun è succieso '%s'" % [sera, cosa])
		if sera == 5:
			await _porta_chiusa()
		if sera < 7 and gm.partita_fernuta:
			male("'a partita è fernuta 'a sera %d" % sera)
	if not gm.partita_fernuta:
		male("sette sere senza pavà e 'a partita nun è fernuta")
	if _persa.is_empty():
		male("nisciun segnale partita_persa")
	else:
		print("  finale: «%s»" % str(_persa.get("finale", "")))
	await get_tree().process_frame
	var fern := get_tree().root.find_child("Fernuta", true, false)
	if fern == null:
		male("nun compare 'a schermata FERNUTA")

	print("=== 5. RICUMINCIA DA CAPO ===")
	if fern != null:
		# Il tasto fa anche il reload della scena: qui si chiama solo la
		# parte del GameManager, e si toglie la schermata a mano.
		gm.ricomincia_da_capo()
		fern.queue_free()
		get_tree().paused = false
	if gm.giornata != 1 or gm.money != 0 or gm.giorni_debbito != 0 \
			or gm.cacciato_e_casa or gm.suocera_in_casa or gm.luce_staccata \
			or gm.gas_staccato or gm.partita_fernuta or not gm.spese_aperte.is_empty():
		male("doppo 'Ricumincia' nun è 'na partita nova: juorno %d, €%d, debbito %d" % [
			gm.giornata, gm.money, gm.giorni_debbito])

	print("=== 3. CHI PAVA TORNA A TERRA ===")
	_azzera()
	for sera in range(1, 6):
		gm.start_shift()
		gm.money = 0
		gm.vai_a_dormire()
	await get_tree().process_frame
	if not gm.cacciato_e_casa:
		male("doppo cinche sere nun t'ha cacciato")
	gm.start_shift()
	gm.money = gm.spese_dovute() + 50
	gm.consegna_a_moglie(gm.spese_dovute())
	var r2: Dictionary = gm.vai_a_dormire()
	await get_tree().process_frame
	print("  pavato tutto: debbito %d, cacciato %s, suocera %s" % [
		gm.giorni_debbito, str(gm.cacciato_e_casa), str(gm.suocera_in_casa)])
	for f in r2.get("conseguenze", []):
		print("    · %s" % str(f))
	if gm.giorni_debbito != 0 or gm.cacciato_e_casa or gm.suocera_in_casa:
		male("pavato tutto e 'a scala nun è turnata a terra")
	if gm.luce_staccata or gm.gas_staccato:
		male("pavato pure 'e riallacce e 'a luce o 'o gas stanno ancora staccate")

	print("=== 4. 'O SALUMIERE ===")
	_azzera()
	gm.giornata = 1
	gm.start_shift()
	var spesa: int = 0
	for s in gm.spese_aperte:
		if str(s.get("tipo", "")) == "spesa":
			spesa = int(s["importo"])
	gm.money = 0
	gm.vai_a_dormire()
	gm.start_shift()
	var salumiere: int = 0
	for s in gm.spese_aperte:
		if str(s.get("tipo", "")) == "salumiere":
			salumiere = int(s["importo"])
	print("  spesa 'e ieri €%d → salumiere €%d, ossa %.0f" % [spesa, salumiere, gm.health])
	# Metà della spesa, e la mora della mattina ci passa sopra (+12%).
	var meta: int = int(ceil(float(spesa) * 0.5))
	if spesa <= 0 or salumiere < meta or salumiere > int(ceil(float(meta) * 1.12)):
		male("'a spesa nun pavata nun è addiventata 'o cunto d''o salumiere (%d → %d)" % [spesa, salumiere])
	if gm.health > gm.HEALTH_MAX * 0.6:
		male("senza cena ieri, e stamatina 'e ossa so' %.0f" % gm.health)

	print("=== 6. CHI FATICA ONESTO ===")
	_azzera()
	var massimo := 0
	for sera in range(1, 31):
		gm.start_shift()
		gm.money += int(round(110.0 * randf_range(0.75, 1.25)))
		gm.consegna_a_moglie(mini(gm.money, gm.spese_dovute()))
		gm.vai_a_dormire()
		massimo = maxi(massimo, gm.giorni_debbito)
	print("  30 juorne a €110: in sacca €%d, scala massima %d" % [gm.money, massimo])
	if massimo > 0 or gm.partita_fernuta:
		male("chi fatica onesto a €110 'o juorno sale 'a scala (%d)" % massimo)
	_azzera()
	_fine()


## Il quinto gradino, in città: la porta, i cartoni, i carabinieri.
func _porta_chiusa() -> void:
	print("=== 2. 'A PORTA CHIUSA ===")
	var gm := GameManager
	var v := get_tree().get_first_node_in_group("vascio")
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	if v == null or pl == null:
		male("nun ce sta 'o vascio o 'o giocatore")
		return
	gm.start_shift()
	v.call("entra", pl)
	if gm.dentro_casa:
		male("cacciato 'e casa, e 'a porta s'arape")
		v.call("esci", pl)
	var porta = v.get("_porta")
	var prompt: String = str(porta.call("get_interact_prompt", Vector3.ZERO))
	print("  porta: «%s»" % prompt)
	if prompt.find("chiusa") < 0:
		male("'a porta nun dice ca è chiusa")
	# I carabinieri ti lasciano fuori, non dentro.
	gm.rientro_forzato("carabinieri")
	await get_tree().process_frame
	if gm.dentro_casa:
		male("'e carabiniere t'hanno miso dint''a casa, ma Nunzia t'ha cacciato")
	# 'E sorde sotto 'a porta, e 'a notte ncopp''e cartune.
	porta.call("player_interact")
	await get_tree().process_frame
	var pan = v.call("pannello")
	if pan == null or not pan.call("aperto"):
		male("[E] ncopp''a porta chiusa nun arape niente")
	else:
		pan.call("chiudi")
	gm.money = 30
	var prima: int = gm.spese_dovute()
	gm.consegna_a_moglie(20)
	if gm.spese_dovute() != prima - 20:
		male("'e sorde sotto 'a porta nun pavano (€%d → €%d)" % [prima, gm.spese_dovute()])
	gm.money = 100
	gm.dorme_fore()
	await get_tree().process_frame
	gm.start_shift()
	print("  doppo 'a notte ncopp''e cartune: ossa %.0f, sacca €%d" % [gm.health, gm.money])
	if gm.health > gm.HEALTH_MAX * 0.61:
		male("doppo 'a notte ncopp''e cartune 'e ossa so' sane (%.0f)" % gm.health)
	# La sera del sesto gradino l'ha già contata `dorme_fore`: si torna
	# indietro di uno, perché il giro principale la conta da sé.
	gm.giorni_debbito -= 1
	gm.gradino_fatto = gm.giorni_debbito


func _azzera() -> void:
	var gm := GameManager
	gm.ricomincia_da_capo()
	gm.giornata = 2
	_persa = {}


func _su_persa(fine: Dictionary) -> void:
	_persa = fine


func _fine() -> void:
	print("=== %d storte ===" % storte)
	get_tree().quit()
