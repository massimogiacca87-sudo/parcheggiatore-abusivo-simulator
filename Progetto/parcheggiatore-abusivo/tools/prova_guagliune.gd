extends Node
## 'E guagliune crescono — e se ne vanno.
##
## La roadmap 0.55 chiedeva due cose opposte: *"uno che lavora per te da
## dieci giorni rende di più e chiede meno del 30%"* e *"uno trattato male
## se ne va da un rivale"*. Sono la carota e il bastone dello stesso
## sistema, e vanno misurate insieme — perché se la carota è troppo dolce
## nessuno licenzia più nessuno, e se il bastone è troppo duro assumere
## diventa una trappola.
##
## Quello che si guarda:
##
##   1. l'esperienza cresce e si **ferma**: un guagliuno di cent'anni non
##      deve rendere il triplo;
##   2. il vecchio rende più del nuovo **e costa meno**, ma non tanto da
##      far diventare la prima assunzione l'unica decisione della partita;
##   3. chi non vede mai i suoi soldi se ne va, e ci mette un numero
##      ragionevole di sere — non una, non venti;
##   4. chi invece lo vai a ritirare **non se ne va mai**, per quanto a
##      lungo giochi. Un dipendente che ti molla anche se lo tratti bene
##      sarebbe sfortuna travestita da meccanica.

var storte: int = 0


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame

	_prova_esperienza()
	_prova_quanto_renne()
	_prova_se_ne_va()
	_prova_chi_passa()

	print("=== storte: %d ===" % storte)
	get_tree().quit()


func _assumi(zona: String) -> void:
	GameManager.dipendenti.erase(zona)
	GameManager.zone_mie = ["piazza", "mercato", "stadio", "cornetteria"]
	GameManager.money = 9999
	if not GameManager.assumi(zona, "'O Provato"):
		male("nun s'è pigliato 'o guaglione a %s" % zona)


func _prova_esperienza() -> void:
	print("=== ESPERIENZA ===")
	GameManager.giornata = 1
	_assumi("mercato")
	print("  %-9s %-8s %-9s %-8s" % ["juorne", "esperienza", "renne", "se tene"])
	var prima_resa := 0.0
	var ultima_resa := 0.0
	for g in [0, 3, 7, 14, 30, 90]:
		GameManager.giornata = 1 + g
		var e: float = GameManager.guagliuno_esperienza("mercato")
		var r: float = GameManager.resa_guagliuno("mercato")
		var q: float = GameManager.quota_guagliuno("mercato")
		print("  %-9d %-11.2f %-9.3f %.0f%%" % [g, e, r, q * 100.0])
		if g == 0:
			prima_resa = r
		ultima_resa = r
		if e < 0.0 or e > 1.0:
			male("esperienza fore d''e limmite: %.2f" % e)
	# Si ferma: un guagliuno di novanta giornate rende come uno di
	# quattordici. Se no il gioco lungo diventa un altro gioco.
	GameManager.giornata = 15
	var a: float = GameManager.resa_guagliuno("mercato")
	GameManager.giornata = 500
	var b: float = GameManager.resa_guagliuno("mercato")
	if not is_equal_approx(a, b):
		male("doppo 'a maturità cresce ancora: %.3f -> %.3f" % [a, b])
	print("  se ferma a %.0f juorne" % GameManager.GUAGLIUNO_MATURA)
	if ultima_resa / prima_resa < 1.1:
		male("crescere nun serve a niente: %.2f vote" % (ultima_resa / prima_resa))
	if ultima_resa / prima_resa > 1.5:
		male("cresce troppo: %.2f vote" % (ultima_resa / prima_resa))


func _prova_quanto_renne() -> void:
	print("=== QUANTO TE RESTA 'N SACCA ===")
	# Il conto vero: su cento euro incassati da lui, quanto ne arriva a te
	# — resa per (1 − quota). È quello che un giocatore sente.
	_assumi("stadio")
	var dal: int = GameManager.giornata
	print("  %-9s %-10s" % ["juorne", "te resta"])
	var righe := []
	for g in [0, 7, 14]:
		GameManager.giornata = dal + g
		var netto: float = 100.0 * GameManager.resa_guagliuno("stadio") \
			* (1.0 - GameManager.quota_guagliuno("stadio"))
		righe.append(netto)
		print("  %-9d €%-9.1f" % [g, netto])
	if righe[2] <= righe[0]:
		male("'o guaglione viecchio nun renne cchiù 'e chillo nuovo")
	var quanto: float = righe[2] / righe[0]
	print("  doppo dduje semmane renne %.2f vote 'e primme juorne" % quanto)
	if quanto > 1.45:
		male("renne troppo 'e cchiù: %.2f vote" % quanto)
	# E comunque meno di farlo di persona: se un guagliuno rendesse quanto
	# te, il gioco sarebbe "assumi e vattene a casa".
	if righe[2] >= 100.0:
		male("'o guaglione renne quanto a te: nun ce sta cchiù motivo 'e faticà")


func _prova_se_ne_va() -> void:
	print("=== CHI NUN SE VEDE MAJE ===")
	_assumi("cornetteria")
	var sere := 0
	while GameManager.ha_dipendente("cornetteria") and sere < 40:
		sere += 1
		GameManager.muove_umore_guagliuno("cornetteria",
			-GameManager.GUAGLIUNO_SCURDATO)
		GameManager._guagliune_ca_se_ne_vanno()
	print("  se n'è ghiuto doppo %d sere ca nun ce sî passato" % sere)
	if sere < 2:
		male("se ne va 'a primma sera: è 'na trappola")
	if sere > 8:
		male("ce mette %d sere: nun 'o nota nisciuno" % sere)
	if GameManager.ha_dipendente("cornetteria"):
		male("nun se ne va maje")


func _prova_chi_passa() -> void:
	print("=== CHI CE PASSA ===")
	# Trenta sere: una sera passi a ritirare, la sera dopo no — cioè il
	# giocatore normale, che non è preciso. Non deve perderlo mai.
	_assumi("piazza")
	for sera in range(30):
		if sera % 2 == 0:
			GameManager.muove_umore_guagliuno("piazza",
				GameManager.GUAGLIUNO_RITIRO_UMORE)
		else:
			GameManager.muove_umore_guagliuno("piazza",
				-GameManager.GUAGLIUNO_SCURDATO)
		GameManager._guagliune_ca_se_ne_vanno()
	if not GameManager.ha_dipendente("piazza"):
		male("se n'è ghiuto pure a chi ce passa 'na sera sì e una no")
	else:
		print("  'na sera sì e una no: sta ancora ccà (umore %.0f)"
			% GameManager.umore_guagliuno("piazza"))

	# E chi ci passa sempre deve stare al massimo.
	_assumi("mercato")
	for sera in range(20):
		GameManager.muove_umore_guagliuno("mercato",
			GameManager.GUAGLIUNO_RITIRO_UMORE)
		GameManager._guagliune_ca_se_ne_vanno()
	var um: float = GameManager.umore_guagliuno("mercato")
	print("  chi ce passa sempe: umore %.0f" % um)
	if um < 90.0:
		male("chi ce passa sempe nun arriva manco a 90: %.0f" % um)
	if um > 100.0:
		male("ll'umore passa 'e cciento: %.0f" % um)

	# E il salvataggio: se `dal` e `umore` non ci passano, ogni ricarica
	# rimette tutti i guagliuni a nuovi e azzera il sistema.
	GameManager.giornata = 40
	var testo := JSON.stringify(GameManager.stato_partita())
	var letto = JSON.parse_string(testo)
	var esp_prima: float = GameManager.guagliuno_esperienza("mercato")
	GameManager.applica_stato(letto)
	if not is_equal_approx(GameManager.guagliuno_esperienza("mercato"), esp_prima):
		male("ll'esperienza s'è perza cu 'o salvataggio")
	if not is_equal_approx(GameManager.umore_guagliuno("mercato"), um):
		male("ll'umore s'è perzo cu 'o salvataggio: %.0f invece 'e %.0f"
			% [GameManager.umore_guagliuno("mercato"), um])
	print("  esperienza e umore passano p''o salvataggio")
