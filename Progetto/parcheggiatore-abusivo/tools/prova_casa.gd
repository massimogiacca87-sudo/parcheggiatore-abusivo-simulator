extends Node
## 'A casa: se trase, se consegna, se dorme — e se **esce 'a fore 'a porta**.
##
## Era una prova che stampava e basta: leggevi le righe e decidevi tu se
## andava bene. Dalla 0.56 conta le storte, perché due cose che il capo ha
## chiesto per nome si controllano qui e non altrove:
##
## * **punto 12** — «Quando esci di casa esci sempre fuori la porta di casa,
##   non dove ti trovavi prima.» Una porta è una porta.
## * **punto 11** — «Quando sei in casa è inutile che arrivano tutti i
##   messaggi, scansa il motorino, quello che si piglia il caffè ecc.»
##   Dentro casa la strada non ti deve parlare.
##
## La seconda è la più insidiosa da provare, perché non si misura
## guardando il codice: `event_started` è **un canale solo** che portava
## due cose diverse — quello che succede **a te** (e va detto sempre, pure
## sotto le coperte) e quello che succede **'n miezo â via** (che dentro
## non ti riguarda). Qui si ascolta il segnale davvero e si contano le
## righe che arrivano.

var storte: int = 0


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


# Ascolto vero del canale: è l'unico modo onesto di provare il silenzio.
var _sentute: Array[String] = []


func _senzo(testo: String) -> void:
	_sentute.append(testo)


func _ready() -> void:
	await get_tree().process_frame
	for _i in range(90):
		await get_tree().process_frame
	var vascio := get_tree().get_first_node_in_group("vascio")
	var pl := get_tree().get_first_node_in_group("player")
	print("--- CASA ---")
	print("vascio trovato: ", vascio != null, "  player: ", pl != null)
	if vascio == null or pl == null:
		male("nun ce sta 'o vascio o nun ce sta 'o giocatore")
		print("=== storte: %d ===" % storte)
		get_tree().quit()
		return
	var porta: Node = vascio.get_node_or_null("PortaCasa")
	print("porta: ", porta != null,
		"  prompt: ", porta.get_interact_prompt(Vector3.ZERO) if porta else "-")
	var moglie := get_tree().get_first_node_in_group("moglie")
	print("moglie: ", moglie != null,
		"  prompt: ", moglie.get_interact_prompt(Vector3.ZERO) if moglie else "-")
	print("criature: ", get_tree().get_nodes_in_group("criature").size())
	print("tavoli 'e scopa: ", get_tree().get_nodes_in_group("tavoli_scopa").size())
	print("cummissiune 'e oggi: ", GameManager.commissioni.size())
	for c in GameManager.commissioni:
		print("   %s  %s → %s  €%d  (%ds)" % [str(c["nome"]),
			str(c["nome_da"]), str(c["nome_a"]), int(c["paga"]),
			int(c["tempo"])])

	# Entra, consegna, dorme.
	var prima: Vector3 = pl.global_position
	vascio.entra(pl)
	await get_tree().process_frame
	print("dentro casa: ", GameManager.dentro_casa,
		"  posizione: ", pl.global_position.round())
	if not GameManager.dentro_casa:
		male("trasenno nun se sape ca sî dinto")

	await _prova_ô_silenzio()

	GameManager.money = 400
	var conto: int = GameManager.spese_dovute()
	print("conto 'e stasera: €%d" % conto)
	var r: Dictionary = GameManager.consegna_a_moglie(conto)
	print("consegnato €%d, resta €%d, umore %d"
		% [int(r["dato"]), int(r["resta"]), int(GameManager.umore_moglie)])
	var letto: Node = null
	for n in vascio.get_node("Dentro").get_children():
		if n.name == "Letto":
			letto = n
	print("letto: ", letto != null,
		"  prompt: ", letto.get_interact_prompt(Vector3.ZERO) if letto else "-")
	var sm: Dictionary = GameManager.vai_a_dormire()
	print("giornata dopo: ", GameManager.giornata,
		"  scoperto: ", int(sm.get("scoperto", -1)),
		"  ora ritiro: ", "%.1f" % float(sm.get("orario_ritiro", -1.0)))

	_prova_a_porta(vascio, pl, prima)

	# 'A scopa: 'na partita 'ntera contro 'o primmo.
	print("--- SCOPA ---")
	print("prossimo sfidante: ", GameManager.prossimo_sfidante())
	print("=== storte: %d ===" % storte)
	get_tree().quit()


## **'O silenzio 'e dinto** (punto 11).
##
## Si resta dentro e si fa parlare la strada: pioggia, motorino, mercato.
## Non deve arrivare niente. Poi si fa succedere una cosa **a te** — un
## avviso vero — e quella deve arrivare lo stesso, se no la cura è peggio
## del male: un gioco che ti nasconde che ti stanno cercando.
func _prova_ô_silenzio() -> void:
	print("--- 'O SILENZIO 'E DINTO ---")
	GameManager.event_started.connect(_senzo)
	_sentute.clear()

	GameManager.avvisa_strada("MOTORINO!! SCANSATI!")
	GameManager.avvisa_strada("Ha accummenciato a chiòvere.")
	GameManager.avvisa_strada("S'è fatta notte. 'A piazza cagna faccia.")
	await get_tree().process_frame
	print("  'a via ha ditto %d cose (nn'aveva 'a dicere nisciuna)"
		% _sentute.size())
	if not _sentute.is_empty():
		male("dint'â casa arriva ancora 'a via: %s" % str(_sentute))

	# E mo' 'na cosa ca riguarda a te.
	_sentute.clear()
	GameManager.event_started.emit("'E CARABINIERI TE STANNO CERCANNO!")
	await get_tree().process_frame
	print("  ll'avvisi ca so' pe' te: %d (nn'aveva 'a passà 1)" % _sentute.size())
	if _sentute.size() != 1:
		male("ll'avvisi ca te riguardano nun passano cchiù manco a te")

	# E 'a fore, 'a via parla n'ata vota.
	GameManager.dentro_casa = false
	_sentute.clear()
	GameManager.avvisa_strada("MOTORINO!! SCANSATI!")
	await get_tree().process_frame
	print("  'a fore 'a via parla: %d" % _sentute.size())
	if _sentute.size() != 1:
		male("'a fore 'a via nun parla cchiù: %d" % _sentute.size())
	GameManager.dentro_casa = true

	# 'A cella è 'a stessa cosa: si sî 'nchiuso, 'a piazza nun t'arriva.
	GameManager.dentro_casa = false
	GameManager.ncella = true
	_sentute.clear()
	GameManager.avvisa_strada("MERCATO!")
	await get_tree().process_frame
	if not _sentute.is_empty():
		male("dint'â cella arriva ancora 'a via")
	GameManager.ncella = false
	GameManager.dentro_casa = true
	print("  dint'â cella: zitto pure lloco")

	GameManager.event_started.disconnect(_senzo)


## **'A porta** (punto 12): si esce da dove si esce, non da dove stavi.
func _prova_a_porta(vascio: Node, pl: Node3D, prima: Vector3) -> void:
	print("--- 'A PORTA ---")
	vascio.esci(pl)
	var fore: Vector3 = pl.global_position
	var dâ_porta: float = Vector2(fore.x, fore.z).distance_to(
		Vector2(vascio.punto_porta().x, vascio.punto_porta().z))
	print("fore: ", not GameManager.dentro_casa,
		"  a ", fore.round(), " (steva a ", prima.round(), ")")
	print("  distanza d''a porta: %.2f m" % dâ_porta)
	if GameManager.dentro_casa:
		male("doppo ca sî asciuto 'o gioco penza ancora ca staje dinto")
	if dâ_porta > 1.0:
		male("nun esce 'a fore 'a porta: sta a %.1f m" % dâ_porta)
	# E non deve tornare dove stavi: è proprio la cosa che è stata levata.
	if prima.distance_to(fore) < 0.05 and prima.distance_to(
			vascio.punto_porta()) > 2.0:
		male("torna ancora addó stive primma")
	# **Fore d''a carreggiata.** Il vicolo è largo quattro metri e le
	# macchine ci salgono: se ti sputa fuori nel mezzo, la prima che passa
	# ti piglia di muso — e dalla 0.56 di muso ti stende davvero.
	# Si misura col corpo vero del giocatore (raggio 0,35), non con la
	# scatola da 0,9 usata per gli arredi: in un vicolo di quattro metri
	# quella non ci starebbe comunque, e la prova direbbe sempre di no.
	var Citta = load("res://scripts/citta_3d.gd")
	if Citta.in_corsia(fore, Vector3(0.7, 1.8, 0.7)):
		male("esce 'n miezo â carreggiata")

	# **E nun 'ncopp'ô muro.** `forward(θ) = (−sinθ, 0, −cosθ)`: se esce
	# guardando −X sta col naso dint'â parete 'e casa soia.
	var guarda: Vector3 = Vector3(-sin(pl.rotation.y), 0.0, -cos(pl.rotation.y))
	print("  guarda verso %s" % str(guarda.round()))
	if guarda.x < -0.5:
		male("esce cu 'a faccia 'ncopp'ô muro")
