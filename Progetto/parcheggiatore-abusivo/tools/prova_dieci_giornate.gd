extends Node
## **Dieci giornate, giocate da sole** (0.64).
##
## La roadmap la chiedeva dalla 0.61: *«la prova che gioca dieci giornate da
## sola è l'unico modo di vedere quello che vede il capo»*. Le altre prove
## guardano un pezzo alla volta per qualche minuto; `prova_economia` fa i
## conti di trenta giornate con un guadagno **supposto**. Questa invece
## gioca: la città vera, le macchine vere, il vigile vero, la moglie vera,
## una giornata dopo l'altra (la scena si ricarica ogni mattina, come nel
## gioco), e alla fine stampa la tabella giorno per giorno.
##
## **Chi gioca.** Un parcheggiatore onesto e un po' ingenuo, sempre nella
## piazza di casa:
##
##   * sta nel salotto della piazza (il lastricato in mezzo, dove le
##     macchine non passano) e da lì fa tutto;
##   * ogni macchina che aspetta la mette al posto suo (la regia a gesti si
##     salta, come nelle altre prove: la macchina si posa sul posto);
##   * a ogni autista che scende chiede i soldi, se il sospetto è sotto al
##     sessanta per cento — sopra aspetta che scenda, come uno prudente;
##   * al vigile che gli parla risponde sempre «è pp''e ccriature»;
##   * se arrivano i carabinieri si chiude in casa finché le stelle non se
##     ne vanno;
##   * se la mattina trova le strisce blu, sfascia i parchimetri e ripitta
##     i posti (comprando la pittura quando serve);
##   * non ruba, non mena, non gioca, non compra niente;
##   * all'ora del rientro (`RIENTRO`, di default l'una meno un quarto) va a
##     casa, dà alla moglie tutto quello che serve per le spese e va a
##     dormire.
##
## Borrelli e 'o Rre d''e Parcheggi stanno spenti: sono boss con una
## meccanica loro, e qui si misura il mestiere di tutti i giorni. Lo dice la
## tabella in testa, così nessuno legge questi numeri come quelli di una
## partita vera.
##
## Si lancia col tempo accelerato (`--fixed-fps 20`: tre fotogrammi di
## fisica per fotogramma, circa 3,5 volte il vero): vedi `tools/sh/runc.sh`
## (`VELOCE=20`). Dieci giornate sono una ventina di minuti.
##
##   GIORNI=10  RIENTRO=24.75  (ore sul quadrante 12…28)
##
## Non ha soglie di «storto» sui soldi (non sappiamo ancora quanto *deve*
## rendere una giornata: è la domanda che questa prova serve a fare). È
## storto solo quello che non deve succedere mai: una giornata che non
## finisce, un turno che non riparte, uno SCRIPT ERROR.

var storte: int = 0
var giorni: int = 10
var rientro: float = 24.75
var righe: Array = []

var _pl: Node3D = null
var _chiesti: Dictionary = {}
var _messe: Dictionary = {}
var _multe_oggi: int = 0
## 'O quadernetto d''e soldi: ogni volta che i soldi scendono si scrive
## quanto e che cosa era appena successo (l'ultimo avviso a schermo), così
## la tabella dice pure **dove** se ne vanno.
var _soldi_prima: int = 0
var _ultimo_avviso: String = ""
var _uscite: Dictionary = {}
var _entrate_fore: Dictionary = {}
var _dint_ô_chiedere: bool = false

const CASA := Vector3(31, 0, 30)


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.get_environment("GIORNI") != "":
		giorni = int(OS.get_environment("GIORNI"))
	if OS.get_environment("RIENTRO") != "":
		rientro = float(OS.get_environment("RIENTRO"))
	for _i in range(60):
		await get_tree().process_frame
	# I verbali si contano dalla scritta che manda il vigile («MULTA — …»).
	GameManager.event_started.connect(func(msg: String):
		_ultimo_avviso = msg
		if msg.begins_with("MULTA"):
			_multe_oggi += 1)
	_soldi_prima = GameManager.money
	GameManager.money_changed.connect(_soldi_cagnati)
	# Partita nuova: i soldi e la casa di chi comincia.
	print("=== DIECI GIORNATE — %d juorne, rientro alle %s, Borrelli e 'o Rre spienti ===" % [
		giorni, _ora(rientro)])
	print("  si parte cu €%d, reputazione %d, umore d''a mugliera %.0f" % [
		GameManager.money, GameManager.reputation, GameManager.umore_moglie])
	for g in range(giorni):
		var ok: bool = await _una_giornata(g + 1)
		if not ok:
			break
	_tabella()
	print("=== storte: %d ===" % storte)
	get_tree().quit()


func _ora(h: float) -> String:
	var hh := int(h) % 24
	var mm := int((h - floor(h)) * 60.0)
	return "%02d:%02d" % [hh, mm]


func _aspetta(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


# ---------------------------------------------------------------------------
# 'A jurnata
# ---------------------------------------------------------------------------

func _una_giornata(n: int) -> bool:
	# La scena nuova parte da sola (headless: niente locandine).
	var t := 0.0
	while not GameManager.shift_active and t < 60.0:
		await _aspetta(0.25)
		t += 0.25
	if not GameManager.shift_active:
		male("giorno %d: 'o turno nun è partito" % n)
		return false
	for _i in range(30):
		await get_tree().process_frame
	_pl = get_tree().get_first_node_in_group("player") as Node3D
	get_tree().paused = false
	_chiesti.clear()
	_messe.clear()
	var r := {"giorno": GameManager.giornata, "tipo": GameManager.tipo_giornata,
		"soldi_mattina": GameManager.money, "chiesti": 0, "pavato": 0,
		"rifiuti": 0, "messe": 0, "multe": 0, "fermi": 0, "casa_nascosto": 0,
		"blu": "", "pittura": 0, "vigile": 0}
	_spegni_boss()
	_metti(CASA)
	await _aspetta(1.0)
	# Le strisce blu della mattina, se ci stanno.
	if GameManager.strisce_blu_in("piazza"):
		r["blu"] = "sì"
		r["pittura"] = await _sistema_strisce_blu()
	_multe_oggi = 0
	_uscite.clear()
	_entrate_fore.clear()
	_soldi_prima = GameManager.money
	# Si fatica fino all'ora del rientro (o fino alle quattro).
	var guardia := 0.0
	while GameManager.shift_active and not GameManager.giornata_scaduta \
			and GameManager.ora_d_o_juorno() < rientro:
		await _aspetta(0.2)
		guardia += 0.2
		if guardia > 900.0:
			male("giorno %d: 'a jurnata nun fernesce (%s)" % [n, GameManager.orologio()])
			break
		_spegni_boss()
		if GameManager.ncella or get_tree().paused:
			# In galera (o un pannello che ferma tutto): si aspetta che passi.
			continue
		if GameManager.stelle > 0:
			if not GameManager.dentro_casa:
				r["casa_nascosto"] += 1
				_entra_in_casa()
			continue
		if GameManager.dentro_casa:
			_esci_d_a_casa()
			_metti(CASA)
			continue
		_rispunne_ô_vigile(r)
		_posteggia(r)
		_chiede_e_sorde(r)
		_torna_in_piazza()
		_scansa_motorino()
	r["multe"] = _multe_oggi * GameManager.MULTA_COSTO
	r["fermi"] = GameManager.fermi_oggi
	r["servite"] = GameManager.clients_served
	r["perse"] = GameManager.clients_lost
	r["ora_rientro"] = GameManager.orologio()
	r["soldi_sera"] = GameManager.money
	# A casa: si danno i soldi delle spese, poi a dormire.
	if not GameManager.dentro_casa and not GameManager.ncella:
		_entra_in_casa()
		await _aspetta(0.5)
	var dovute: int = GameManager.spese_dovute()
	r["dovute"] = dovute
	_ultimo_avviso = "(le spese di casa, date alla moglie)"
	var dato: Dictionary = GameManager.consegna_a_moglie(mini(dovute, GameManager.money))
	r["consegnato"] = int(dato.get("dato", 0))
	r["scoperto"] = int(dato.get("resta", 0))
	var riep: Dictionary = GameManager.vai_a_dormire() if not GameManager.ncella else {}
	if GameManager.ncella:
		GameManager.esce_d_a_galera()
	r["umore"] = GameManager.umore_moglie
	r["soldi_notte"] = GameManager.money
	r["conseguenze"] = (riep.get("conseguenze", []) as Array).size()
	r["uscite"] = _uscite.duplicate()
	r["entrate_fore"] = _entrate_fore.duplicate()
	righe.append(r)
	print("  juorno %d (%s): €%d → €%d, messe %d, pavate %d/%d, perse %d, multe €%d, spese €%d (scoperto €%d), umore %.0f" % [
		r["giorno"], r["tipo"], r["soldi_mattina"], r["soldi_notte"], r["messe"],
		r["pavato"], r["chiesti"], r["perse"], r["multe"], r["consegnato"], r["scoperto"],
		r["umore"]])
	for k in _uscite:
		print("      − €%d  dopo «%s»" % [int(_uscite[k]), k])
	for k in _entrate_fore:
		print("      + €%d  dopo «%s»" % [int(_entrate_fore[k]), k])
	# 'A matina appriesso: si ricarica la scena, come fa il bottone del
	# riepilogo.
	if n < giorni:
		GameManager.selected_zone = "vicolo"
		GameManager.salta_intro = true
		GameManager.dentro_casa = false
		get_tree().paused = false
		get_tree().reload_current_scene()
		for _i in range(10):
			await get_tree().process_frame
	return true


func _soldi_cagnati(ora: int) -> void:
	var d: int = ora - _soldi_prima
	_soldi_prima = ora
	if d == 0:
		return
	var chi: String = _ultimo_avviso.substr(0, 46) if _ultimo_avviso != "" else "(senza avviso)"
	if d < 0:
		_uscite[chi] = int(_uscite.get(chi, 0)) - d
	elif not _dint_ô_chiedere:
		_entrate_fore[chi] = int(_entrate_fore.get(chi, 0)) + d


func _spegni_boss() -> void:
	GameManager.borrelli_ultimo_juorno = GameManager.giornata
	GameManager.borrelli_chiamate = -1
	GameManager.re_prossimo_juorno = 9999


# ---------------------------------------------------------------------------
# Il mestiere
# ---------------------------------------------------------------------------

func _metti(p: Vector3) -> void:
	if _pl == null or not is_instance_valid(_pl):
		_pl = get_tree().get_first_node_in_group("player") as Node3D
	if _pl == null:
		return
	p.y = Collina.alzata(p.x, p.z) + 0.2
	_pl.global_position = p
	if _pl is CharacterBody3D:
		(_pl as CharacterBody3D).velocity = Vector3.ZERO


func _torna_in_piazza() -> void:
	if _pl == null or not is_instance_valid(_pl):
		return
	if _pl.global_position.distance_to(CASA) > 5.0 and _torna_quanno_passa():
		_metti(CASA)


## **'O motorino se scansa.** Attraversa la piazza dritto, su una corsia
## sola, suonando: chi gioca lo sente e fa un passo di lato. La prima prova
## non lo faceva, e il motorino la prendeva in pieno due-tre volte al giorno
## (nove ossa a botta): la sera stava all'ospedale.
func _scansa_motorino() -> void:
	if _pl == null or not is_instance_valid(_pl):
		return
	for m in get_tree().get_nodes_in_group("motorini"):
		if not is_instance_valid(m):
			continue
		var mp: Vector3 = (m as Node3D).global_position
		var pp: Vector3 = _pl.global_position
		if absf(mp.z - pp.z) > 2.6 or absf(mp.x - pp.x) > 30.0:
			continue
		var verso: float = 1.0 if pp.z >= mp.z else -1.0
		_metti(Vector3(CASA.x, 0.0, mp.z + verso * 4.5))
		return


func _torna_quanno_passa() -> bool:
	for m in get_tree().get_nodes_in_group("motorini"):
		if is_instance_valid(m) and absf((m as Node3D).global_position.z - CASA.z) < 3.0:
			return false
	return true


func _posteggia(r: Dictionary) -> void:
	for c in get_tree().get_nodes_in_group("cars"):
		if not is_instance_valid(c) or str(c.get("zona_id")) != "piazza":
			continue
		if int(c.get("state")) != 1:
			continue
		var id: int = c.get_instance_id()
		if _messe.has(id):
			continue
		# **Si dirige dal salotto.** La prima prova metteva il giocatore
		# accanto alla macchina, cioè in carreggiata: il primo giorno l'ha
		# preso in pieno una macchina, ospedale e a casa. Dal salotto (il
		# lastricato in mezzo, dove le macchine non passano) il vigile lo
		# vede dirigere lo stesso: è lì che si sta, giocando.
		var cp: Vector3 = (c as Node3D).global_position
		c.player_interact()
		var spot = c.get("assigned_spot")
		if spot == null or not is_instance_valid(spot):
			continue
		_messe[id] = true
		var sp: Vector3 = (spot as Node3D).global_position
		(c as Node3D).global_position = Vector3(sp.x, cp.y, sp.z)
		(c as Node3D).rotation.y = 0.0
		r["messe"] += 1
		return   # una alla volta, come si fa


func _chiede_e_sorde(r: Dictionary) -> void:
	if GameManager.heat >= GameManager.HEAT_MAX * 0.6:
		return
	for d in get_tree().get_nodes_in_group("drivers"):
		if not is_instance_valid(d) or _chiesti.has(d.get_instance_id()):
			continue
		var auto = d.get("car")
		if auto == null or not is_instance_valid(auto) or str(auto.get("zona_id")) != "piazza":
			continue
		var prompt: String = str(d.get_interact_prompt(Vector3.ZERO))
		if not prompt.begins_with("[E] chiure"):
			continue
		_chiesti[d.get_instance_id()] = true
		var prima: int = GameManager.money
		_dint_ô_chiedere = true
		d.player_interact()
		_dint_ô_chiedere = false
		r["chiesti"] += 1
		if GameManager.money > prima:
			r["pavato"] += GameManager.money - prima
		else:
			r["rifiuti"] += 1
		return


func _rispunne_ô_vigile(r: Dictionary) -> void:
	var v = GameManager.get("dialogo_con")
	if v == null or not is_instance_valid(v):
		return
	if v.has_method("answer") and v.is_in_group("vigili"):
		v.answer(0)
		r["vigile"] += 1


func _entra_in_casa() -> void:
	for p in get_tree().get_nodes_in_group("porte_casa"):
		if p.get("verso_dentro") == true:
			p.player_interact()
			return


func _esci_d_a_casa() -> void:
	for v in get_tree().get_nodes_in_group("vascio"):
		if v.has_method("esci"):
			v.esci(_pl)
			return


## 'E strisce blu d''a matina: si sfasciano tutti i parchimetri (a
## cazzotti, quattro botte da due), si accatta 'a pittura e si ripittano
## tutti i posti blu, fermi accanto per il tempo che ci vuole.
func _sistema_strisce_blu() -> int:
	var speso := 0
	for pm in get_tree().get_nodes_in_group("parchimetri"):
		if not is_instance_valid(pm) or pm.get("zona_id") != "piazza":
			continue
		_metti((pm as Node3D).global_position + Vector3(1.2, 0, 1.2))
		for _k in range(5):
			if pm.get("rotto") == true:
				break
			pm.receive_punch(2)
			await _aspetta(0.3)
	for sp in get_tree().get_nodes_in_group("strisce_blu"):
		if not is_instance_valid(sp) or str(sp.get("zona_id")) != "piazza":
			continue
		if GameManager.pittura <= 0:
			var m0: int = GameManager.money
			if not GameManager.accatta_pittura():
				break
			speso += m0 - GameManager.money
		_metti((sp as Node3D).global_position + Vector3(1.6, 0, 0))
		sp.player_interact()
		await _aspetta(GameManager.PITTURA_TEMPO + 0.4)
	return speso


# ---------------------------------------------------------------------------
# 'A tabella
# ---------------------------------------------------------------------------

func _tabella() -> void:
	print("")
	print("=== 'A TABELLA ===")
	print("  gg  tipo          mattina  sera  notte | messe pavate chiesti rifiuti perse | multe fermi nascosto | spese  scoperto umore | blu")
	var tot_pavato := 0
	var tot_spese := 0
	var tot_multe := 0
	for r in righe:
		print("  %2d  %-12s  %6d %6d %6d | %5d %6d %7d %7d %5d | %5d %5d %8d | %5d %8d %5.0f | %s" % [
			int(r["giorno"]), str(r["tipo"]), int(r["soldi_mattina"]), int(r["soldi_sera"]),
			int(r["soldi_notte"]), int(r["messe"]), int(r["pavato"]), int(r["chiesti"]),
			int(r["rifiuti"]), int(r.get("perse", 0)), int(r["multe"]), int(r["fermi"]),
			int(r["casa_nascosto"]), int(r["consegnato"]), int(r["scoperto"]),
			float(r["umore"]), str(r["blu"])])
		tot_pavato += int(r["pavato"])
		tot_spese += int(r["consegnato"])
		tot_multe += int(r["multe"])
	if righe.is_empty():
		return
	var n: float = float(righe.size())
	print("  in media al giorno: incasso €%.0f, spese €%.0f, multe €%.0f; in tasca alla fine €%d" % [
		float(tot_pavato) / n, float(tot_spese) / n, float(tot_multe) / n,
		int(righe[righe.size() - 1]["soldi_notte"])])
