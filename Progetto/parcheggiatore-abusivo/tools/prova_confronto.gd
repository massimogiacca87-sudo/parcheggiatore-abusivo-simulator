extends Node
## 'O cunfronto cu ll'autista: multa, stemma, machina scassata.
##
## Il capo: *"I dialoghi con i guidatori che trovano multe o auto scassate
## non funzionano."* Non funzionavano per tre motivi diversi, e questa
## prova li copre tutti e tre:
##
##   1. il dialogo dello stemma si apriva e **spariva nello stesso
##      fotogramma**, perché lo stato restava `RETURNING` e `_do_return()`
##      ripartiva subito mandando l'autista all'inseguimento;
##   2. per la **multa** un dialogo non c'era proprio: si passava dritti
##      alle mazzate;
##   3. per la **macchina rigata di nascosto** non succedeva niente, mai.
##
## Qui l'autista si mette su una macchina finta — bastano i quattro campi
## che legge — e si controlla che il dialogo si apra, che **resti aperto**,
## e che ogni risposta porti dove deve.
##
## **'A cerca (0.52).** Dalla 0.52 il dialogo non si apre più appena
## l'autista arriva alla macchina: prima ti cerca, e ti parla solo se ti
## arriva vicino. Quindi la prova adesso mette pure un finto giocatore in
## scena, e ne prova tre casi:
##
##   * **te trova** — il giocatore sta lì e il dialogo si apre;
##   * **nun te trova** — il giocatore è dentro la portata ma il tempo
##     scade prima che ci arrivi;
##   * **stai troppo lontano** — oltre i trentadue metri non ti viene
##     nemmeno a cercare, e se ne va.
##
## Il terzo è quello che conta: è la via d'uscita che il capo ha chiesto
## ("se ne vanno sconfitti se non ti trovano"), e se non funzionasse il
## giocatore non avrebbe modo di saperlo se non restando a farsi menare.

const DriverScript := preload("res://scripts/driver_3d.gd")

## **Addó se fa 'o cunfronto** (0.59). Fino alla 0.58 la scena stava
## all'origine del mondo: la macchina nell'angolo della mappa, l'autista
## dentro all'isolato d'angolo e il giocatore dei «quattordici metri» pure
## lui dentro a un palazzo. Passava perché l'autista, spinto fuori dal
## muro, si trovava in un corridoio largo quaranta centimetri **fuori dalla
## mappa** e ci camminava. Dalla 0.59 il passo conosce anche le cose (e il
## muro di confine è una cosa): quel corridoio non c'è più, e la prova
## difendeva una strada che non esiste. Adesso si fa in mezzo al Corso,
## sulla corsia che per regola resta sempre libera.
const ORIGINE := Vector3(78.0, 0.0, 100.0)


## 'Nu giocatore finto: basta che stia dint'ô gruppo "player" e ca tenga
## 'nu posto ncopp'â mappa. I due metodi sono quelli che il confronto
## chiama quando si apre.
class FintoGiocatore extends Node3D:
	func guarda_verso(_chi: Node, _subito: bool = false) -> void:
		pass

	func interrompi_tutto() -> void:
		pass


## Il minimo indispensabile perché un autista la riconosca come la sua auto.
class FintaMachina extends Node3D:
	var paid: bool = false
	# 'A 0.54: ogni machina se porta appriesso 'o cliente ca 'a guida, e
	# ll'autista 'o legge pe' sapé si 'o cunosce. Senza chesta riga 'a
	# prova stampava trecento errure e passava 'o stesso — cioè il tipo di
	# rumore che nasconde il prossimo errore vero.
	var cliente_id: String = ""
	var has_multa: bool = false
	var _stemma_sparito: bool = false
	var _scassata_ammuccione: bool = false
	var finita: bool = false

	# 'A 0.55: ll'uscita 'e scena è una sola, e passa 'a ccà.
	func l_autista_ha_fernuto() -> void:
		finita = true


var _male: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	GameManager.start_shift()
	print("=== 'O CUNFRONTO CU LL'AUTISTA ===")

	await _caso("multa", false, 0, "scusa —> pace")
	await _caso("multa", true, 0, "scusa cu chi t'ha pagato —> mazzate")
	await _caso("multa", false, 3, "mannalo a fa' —> mazzate")
	await _caso("stemma", false, 1, "ce 'o ridà —> pace")
	await _caso("scasso", false, 0, "'e guagliune —> pace")
	# Pagare i danni: con i soldi in tasca fa pace, senza fa a mazzate.
	GameManager.money = 60
	await _caso("scasso", false, 2, "ce paga 'e diece euro —> pace")
	GameManager.money = 0
	await _caso("scasso", false, 2, "vò pagà ma nun tene niente —> mazzate")

	await _prova_cerca()
	await _prova_negà()

	print("=== %d storte ===" % _male)
	get_tree().quit()


# ---------------------------------------------------------------------------
# 'A cerca
# ---------------------------------------------------------------------------

const DriverState := DriverScript.State


## Tre modi in cui può finire la cerca. Il giocatore si mette a una
## distanza, si lascia girare la macchina a stati per un po', e si guarda
## dove è arrivato.
func _prova_cerca() -> void:
	print("=== 'A CERCA ===")
	await _cerca_caso(1.5, -1.0, "te sta 'nfaccia", "confronto")
	await _cerca_caso(14.0, -1.0, "te trova a quattuordece metre", "confronto")
	await _cerca_caso(28.0, 1.0, "nun ce 'a fa 'nnanze ca scade 'o tiempo", "se ne va")
	await _cerca_caso(60.0, -1.0, "staje troppo luntano: nun te vene manco a cercà",
		"se ne va")


## `accorcia` > 0 taglia il cronometro della cerca appena parte: e' il modo
## di provare il ramo del tempo scaduto senza far girare ventotto secondi
## di fotogrammi.
func _cerca_caso(distanza: float, accorcia: float, che: String,
		atteso: String) -> void:
	var m := FintaMachina.new()
	m.has_multa = true
	add_child(m)
	m.global_position = ORIGINE

	var pl := FintoGiocatore.new()
	pl.add_to_group("player")
	add_child(pl)
	pl.global_position = ORIGINE + Vector3(0, 0, distanza)

	var d = DriverScript.new()
	add_child(d)
	d.global_position = ORIGINE + Vector3(0, 0, 6.0)
	d.setup(m, ORIGINE + Vector3(0, 0, 6.0))
	await get_tree().process_frame
	d.start_return_for_multa()

	# Prima cammina fino alla macchina, poi comincia a cercare.
	var giri := 0
	var passo := 0.05
	var tagliato := false
	while giri < 1400:
		d._physics_process(passo)
		if accorcia > 0.0 and not tagliato \
				and int(d.get("state")) == DriverState.CERCA:
			d.set("_cerca_t", accorcia)
			tagliato = true
		if bool(d.get("_confronto_aperto")):
			break
		if int(d.get("state")) == DriverState.CALMING:
			break
		giri += 1

	var stato := int(d.get("state"))
	var visto := "?"
	if bool(d.get("_confronto_aperto")):
		visto = "confronto"
	elif stato == DriverState.CALMING:
		visto = "se ne va"
	elif stato == DriverState.CERCA:
		visto = "sta ancora cercanno"
	else:
		visto = "stato %d" % stato
	var ok: bool = visto == atteso
	if not ok:
		_male += 1
	print("  %-46s -> %-14s %s" % [che, visto, "OK" if ok else
		"STORTO: aspettavo '%s'" % atteso])

	if bool(d.get("_confronto_aperto")):
		d._chiudi_dialogo()
	GameManager.dialogo_con = null
	d.queue_free()
	m.queue_free()
	pl.queue_free()
	await get_tree().process_frame


# ---------------------------------------------------------------------------
# Negà è 'na monetina
# ---------------------------------------------------------------------------

## Il capo ha chiesto il cinquanta per cento. Un dado non si prova con una
## tirata: se ne tirano duecento e si guarda dove cade la media.
func _prova_negà() -> void:
	print("=== NEGÀ ===")
	for pagato in [false, true]:
		var mazzate := 0
		var giri := 160
		for i in range(giri):
			var m := FintaMachina.new()
			m.paid = pagato
			m.has_multa = true
			add_child(m)
			var d = DriverScript.new()
			add_child(d)
			d.setup(m, Vector3.ZERO)
			d.set("_confronto_aperto", true)
			d.set("_confronto_motivo", "multa")
			d.answer(2)   # "T'aggio ditto io 'e nun 'a mettere llà" = faccia tosta
			if int(d.get("state")) == DriverState.HUNTING:
				mazzate += 1
			d.queue_free()
			m.queue_free()
			# **`queue_free()` è differito.** Centosessanta autisti con
			# scheletro e AnimationTree costruiti nello stesso fotogramma
			# riempiono la coda dei messaggi e Godot muore: ogni dieci si
			# lascia passare un fotogramma e la coda si svuota.
			if i % 10 == 9:
				await get_tree().process_frame
		var quota: float = float(mazzate) / float(giri)
		var atteso: float = DriverScript.PROBABILITA_S_INCAZZA
		if pagato:
			atteso += DriverScript.PAGATO_S_INCAZZA_CCHIU
		var ok: bool = absf(quota - atteso) < 0.10
		if not ok:
			_male += 1
		print("  %-24s s'incazza 'o %d%% (aspettato 'o %d%%)  %s" % [
			"t'aveva pagato" if pagato else "nun t'aveva pagato",
			int(quota * 100.0), int(atteso * 100.0),
			"OK" if ok else "STORTO"])


func _caso(motivo: String, pagato: bool, risposta: int, che: String) -> void:
	var m := FintaMachina.new()
	m.paid = pagato
	m.position = ORIGINE
	add_child(m)
	match motivo:
		"multa": m.has_multa = true
		"stemma": m._stemma_sparito = true
		"scasso": m._scassata_ammuccione = true

	# **'O giocatore ce vò.** Dalla 0.52 l'autista, arrivato alla macchina,
	# si mette a cercare: senza nessuno da trovare non aprirebbe mai il
	# dialogo, e questa prova misurerebbe la cerca invece del confronto.
	# Sta appiccicato alla macchina apposta: qui si prova il dialogo.
	var pl := FintoGiocatore.new()
	pl.add_to_group("player")
	add_child(pl)
	pl.global_position = ORIGINE + Vector3(0, 0, 1.2)

	var d = DriverScript.new()
	add_child(d)
	d.global_position = ORIGINE + Vector3(0, 0, 6.0)
	d.setup(m, ORIGINE + Vector3(0, 0, 6.0))
	await get_tree().process_frame
	d.start_return_for_stemma()

	# Lo si fa camminare fino alla macchina.
	var giri := 0
	while giri < 400 and not bool(d.get("_confronto_aperto")):
		d._physics_process(0.05)
		giri += 1
	var aperto: bool = bool(d.get("_confronto_aperto"))
	var giusto: bool = str(d.get("_confronto_motivo")) == motivo
	var in_mano: bool = GameManager.dialogo_con == d

	# **'A prova ca conta**: dopo dieci fotogrammi il dialogo dev'essere
	# ANCORA aperto. È esattamente quello che prima non succedeva.
	for i in range(10):
		d._physics_process(0.05)
	var resta: bool = bool(d.get("_confronto_aperto"))

	d.answer(risposta)
	var stato := int(d.get("state"))
	var nome_stato := "?"
	match stato:
		DriverScript.State.HUNTING: nome_stato = "mazzate"
		DriverScript.State.CALMING: nome_stato = "pace"
		DriverScript.State.CONFRONTO: nome_stato = "ancora fermo"
		_: nome_stato = "stato %d" % stato
	var chiuso: bool = not bool(d.get("_confronto_aperto"))

	var ok: bool = aperto and giusto and in_mano and resta and chiuso
	if not ok:
		_male += 1
	print("  %-9s pagato=%-5s risp.%d  ->  %-9s | apre %s · motivo %s · resta %s · chiude %s   (%s)" % [
		motivo, str(pagato), risposta, nome_stato,
		"OK" if aperto else "NO", "OK" if giusto else "NO",
		"OK" if resta else "NO", "OK" if chiuso else "NO", che])

	GameManager.dialogo_con = null
	d.queue_free()
	m.queue_free()
	pl.queue_free()
	await get_tree().process_frame
