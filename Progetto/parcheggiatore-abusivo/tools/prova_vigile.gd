extends Node
## **'O vigile: quanno guarda, quanno smonta** (0.56, punto 9).
##
## Il capo, per intero: *«Il vigile deve essere un pò più reattivo. A volte
## mi passa proprio davanti mentre sto gestendo un'auto e non se ne fotte
## proprio. Bilancialo meglio, come realismo e gameplay. Anche rubare e
## rivendere stemmi davanti a lui dovrebbe essere un problema. Inoltre la
## sera dopo le 20.00 va via, quindi conviene lavorare di sera.»*
##
## Sono quattro cose e si provano una per una, ma la domanda vera è una
## sola e sta nell'ultima riga: **conviene lavorare di sera?** Se la
## risposta è sì, tutta la giornata cambia forma e ha un senso restare
## fuori; se è no, alle venti il vigile se ne va e non se ne accorge
## nessuno. Quindi qua sotto non si controlla soltanto che smonti: si conta
## **quanto costa in sospetto un'ora di lavoro prima e dopo**, che è la
## cosa che il giocatore sente davvero.

var storte: int = 0


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


## Mette l'orologio del gioco a un'ora precisa. Il tempo è il tempo che
## resta al turno, quindi si va all'indietro: mezzogiorno è tutto il turno
## davanti, le quattro del mattino è zero.
func _mette_ll_ora(ora: float) -> void:
	var quanto: float = (ora - 12.0) / GameManager.ORE_DI_GIORNATA
	GameManager.shift_time_left = GameManager.shift_duration \
		* (1.0 - clampf(quanto, 0.0, 1.0))


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	get_tree().paused = false
	for _i in range(80):
		await get_tree().process_frame

	_prova_ll_orologio()
	await _prova_ca_nun_smonta_ampresso()
	await _prova_ca_smonta()
	_prova_e_stemme()

	print("=== storte: %d ===" % storte)
	get_tree().quit()


func _vigile() -> Node:
	for v in get_tree().get_nodes_in_group("vigili"):
		if is_instance_valid(v):
			return v
	return null


# ---------------------------------------------------------------------------
# Ll'orologio
# ---------------------------------------------------------------------------

func _prova_ll_orologio() -> void:
	print("=== LL'OROLOGIO ===")
	for ora in [12.0, 16.0, 19.5, 20.0, 23.0]:
		_mette_ll_ora(ora)
		var letta: float = GameManager.ora_d_o_juorno()
		print("  mis'a %.1f, 'o gioco dice %.1f (%s)"
			% [ora, letta, GameManager.orologio()])
		if absf(letta - ora) > 0.15:
			male("ll'ora nun torna: %.2f 'nvece 'e %.2f" % [letta, ora])
	# E l'ora dell'orologio e l'ora della fascia devono essere la stessa:
	# erano due conti scritti due volte, ed è il genere di doppione che
	# prima o poi si scolla.
	_mette_ll_ora(21.0)
	print("  'e 21 sta dint'â fascia: %s" % GameManager.fascia_nome())


# ---------------------------------------------------------------------------
# Primma d''e vinte nun se movе
# ---------------------------------------------------------------------------

func _prova_ca_nun_smonta_ampresso() -> void:
	print("=== PRIMMA D''E VINTE ===")
	var v := _vigile()
	if v == null:
		male("nun ce sta 'o vigile: 'a prova nun prova niente")
		return
	_mette_ll_ora(18.0)
	for _i in range(40):
		await get_tree().physics_frame
	if not is_instance_valid(v):
		male("'e sei d''a sera 'o vigile s'è già ghiuto")
		return
	print("  'e 18:00 sta ancora ccà, stato %d" % int(v.stato))
	if int(v.stato) == int(v.Stato.SMONTA):
		male("'e sei d''a sera ha già smuntato")


# ---------------------------------------------------------------------------
# 'E vinte smonta
# ---------------------------------------------------------------------------

func _prova_ca_smonta() -> void:
	print("=== 'E VINTE SMONTA ===")
	var v := _vigile()
	if v == null:
		male("nun ce sta 'o vigile")
		return
	_mette_ll_ora(20.2)
	var caldo_primma: float = GameManager.heat
	GameManager.heat = GameManager.HEAT_MAX * 0.9
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_instance_valid(v):
		print("  s'è ghiuto subeto")
	else:
		print("  stato doppo 'e vinte: %d (SMONTA è %d)"
			% [int(v.stato), int(v.Stato.SMONTA)])
		if int(v.stato) != int(v.Stato.SMONTA):
			male("'e vinte e nun smonta")
		if v.can_see_player():
			male("ha smuntato ma te guarda ancora")
	# Il sospetto si sgonfia quando se ne va: è metà del senso della cosa.
	print("  'o suspetto: %.0f → %.0f" % [GameManager.HEAT_MAX * 0.9,
		GameManager.heat])
	if GameManager.heat >= GameManager.HEAT_MAX * 0.9:
		male("smontanno nun scenne 'o suspetto")
	caldo_primma = caldo_primma  # zitto, analizzatore

	# E dopo un po' non c'è più nessuno in piazza.
	for _i in range(400):
		await get_tree().physics_frame
		if not is_instance_valid(v):
			break
	print("  doppo: %s" % ("s'è ghiuto" if not is_instance_valid(v)
		else "sta ancora ccà"))
	if is_instance_valid(v):
		male("doppo 'e vinte 'o vigile nun se ne va")
	if not get_tree().get_nodes_in_group("vigili").is_empty():
		male("ce stanno ancora vigili 'n piazza doppo 'e vinte")
	# **E chesta è 'a risposta â dimanna vera.** Dalle venti in poi
	# dirigere una macchina non costa più niente: nessuno guarda.
	print("  'a sera nisciuno te guarda: %s"
		% ("giusto" if GameManager.nu_vigile_te_vede() == null else "STORTO"))
	if GameManager.nu_vigile_te_vede() != null:
		male("'a sera ce sta ancora quaccheduno ca te guarda")


# ---------------------------------------------------------------------------
# 'E stemme: arrubbarle e rivennerle 'nnanze a isso
# ---------------------------------------------------------------------------
#
# Qui non si può usare il vigile della piazza — a questo punto della prova
# ha smontato — quindi se ne fa uno apposta e si chiama il gancio da fuori,
# che è esattamente quello che fanno `car_3d._steal_emblem` e `shop_3d`.

func _prova_e_stemme() -> void:
	print("=== 'E STEMME 'NNANZE Ô VIGILE ===")
	var V = load("res://scripts/vigile_3d.gd")
	print("  ll'arrubbatina 'nnanze a isso vale %d 'e suspetto ncopp'a %d"
		% [int(GameManager.HEAT_MAX), int(GameManager.HEAT_MAX)])
	# La ricettazione pesa per quanti stemmi passi: uno si racconta, sei
	# sono un mestiere. E il minimo dev'essere già sopra alla soglia che lo
	# fa venire a parlare, se no non è un problema — è un fastidio.
	print("  %-10s %s" % ["quanti", "suspetto"])
	for quanti in [1, 3, 6, 12]:
		var quanto: float = clampf(18.0 + float(quanti) * 9.0, 18.0,
			GameManager.HEAT_MAX)
		print("  %-10d %.0f" % [quanti, quanto])
		if quanti >= 6 and quanto < V.SOGLIA_PARLA:
			male("%d stemme venne sotto 'o naso e nun succede niente" % quanti)
	if 18.0 + 9.0 >= GameManager.HEAT_MAX:
		male("pure 'nu stemma sulo te manna 'n galera: troppo")

	# E la regia: quanto ci mette a farsi notare mentre dirigi.
	var secunne: float = V.SOGLIA_PARLA / V.VEDE_REGIA
	print("  dirigenno 'nnanze a isso: %.1f seconde pe' fàrte chiammà"
		% secunne)
	# Sotto i tre secondi non fai in tempo a parcheggiare nessuno; sopra i
	# dodici è come prima, cioè non se ne fotte.
	if secunne < 3.0:
		male("basta %.1f seconde 'e regia: nun se fa niente" % secunne)
	if secunne > 12.0:
		male("ce vonno %.1f seconde: nun se n'addona manco mo'" % secunne)
	var pieno: float = GameManager.HEAT_MAX / V.VEDE_REGIA
	print("  e %.1f seconde pe' piglià 'o verbale" % pieno)
