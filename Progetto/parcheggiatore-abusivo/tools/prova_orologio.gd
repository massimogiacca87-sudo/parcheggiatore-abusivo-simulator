extends Node
## Controlla ca 'o tiempo dice sempe 'a stessa cosa.
##
## Tre numeri che devono raccontare la stessa giornata:
##
##   * `shift_time_left`  — quanto manca alle quattro;
##   * `ore_passate()`    — che ora è, per il conto e per la moglie;
##   * `GiornoNotte.orario()` / `avanzamento` — che ora è per l'orologio in
##     alto a destra e per il colore del cielo.
##
## Fino alla 0.50 il terzo si contava per conto suo (`avanzamento += delta /
## 450`) e bastava un momento in cui girava uno e non l'altro per separarli
## per sempre. Questa prova li mette a confronto tappa per tappa, e prova
## anche l'arresto — che è il caso che il capo ha segnalato.

const Ciclo := preload("res://scripts/giorno_notte.gd")

## Quanto scarto si tollera fra i due orologi, in minuti di gioco.
const TOLLERANZA: float = 0.5


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	print("=== 'O TIEMPO ===")

	var c = Ciclo.new()
	add_child(c)

	GameManager.giornata = 1
	GameManager.start_shift()
	var male := 0

	print("  %-8s %-8s %-8s %-8s %s" % ["resta", "ore", "avanz.", "orologio",
		"esito"])
	for passo in range(9):
		# Si fa scorrere il cronometro a mano, come farebbe `_process`.
		GameManager.shift_time_left = maxf(0.0,
			GameManager.shift_duration * (1.0 - float(passo) / 8.0))
		var av: float = GameManager.avanzamento_giornata()
		var ore: float = GameManager.ore_passate()
		var testo: String = c.orario()
		# L'orologio riletto al contrario: da "HH:MM" ai minuti dalle 12.
		var pezzi: PackedStringArray = testo.split(":")
		var min_orol: float = float(pezzi[0]) * 60.0 + float(pezzi[1])
		if min_orol < 12.0 * 60.0:
			min_orol += 24.0 * 60.0      # dopo mezzanotte
		min_orol -= 12.0 * 60.0
		var min_att: float = ore * 60.0
		var scarto: float = absf(min_orol - min_att)
		var ok: bool = scarto <= TOLLERANZA
		if not ok:
			male += 1
		print("  %-8.1f %-8.2f %-8.3f %-8s %s" % [
			GameManager.shift_time_left, ore, av, testo,
			"OK" if ok else "STORTO (%.1f minute 'e scarto)" % scarto])

	# E il cielo? `avanzamento` deve specchiare il GameManager senza contare.
	GameManager.shift_time_left = GameManager.shift_duration * 0.35
	c._process(0.016)
	var atteso: float = GameManager.avanzamento_giornata()
	var visto: float = float(c.avanzamento)
	var ok_cielo: bool = absf(atteso - visto) < 0.002
	if not ok_cielo:
		male += 1
	print("  cielo: atteso %.3f, letto %.3f  ->  %s" % [
		atteso, visto, "OK" if ok_cielo else "STORTO"])

	# --- L'arresto ------------------------------------------------------
	print("=== 'O ARRESTO ===")
	# **E ccà 'a regola s'è girata sottencoppa** (0.56, punto 13).
	#
	# Fino alla 0.55 questa prova pretendeva il contrario di quello che
	# pretende adesso: *durante l'arresto il tempo NON si deve muovere*. Ce
	# l'avevo messo io nella 0.51, convinto che fosse una gentilezza — se ti
	# fermano non è giusto che intanto ti scappi la serata.
	#
	# Era una pezza, ed era la pezza che il capo ha segnalato due versioni
	# dopo: *«L'orario e lo scorrere del tempo non funzionano ancora bene e
	# si bloccano se vieni arrestato o se vai a casa.»* Fermare l'orologio
	# vuol dire che l'orologio in alto e il cielo raccontano due giornate
	# diverse, e che una manciata di fermi allunga la giornata all'infinito.
	#
	# La regola nuova è quella vera: **'o tiempo nun se ferma pe' nisciuno**.
	# Se ti arrestano alle nove, alle nove e cinque sono le nove e cinque —
	# e le tre ore buone che ti sei perso sono la punizione, che è
	# esattamente quello che deve essere.
	#
	# È la lezione della 0.53, un'altra volta: *'na cura scritta bbona po'
	# essere 'a malatia d''a versione appriesso*.
	GameManager.shift_time_left = GameManager.shift_duration * 0.40
	var prima: float = GameManager.ore_passate()
	GameManager.arrest_by_carabinieri()
	print("  ora d''o fermo: %.2f  ·  ora_ritiro registrata: %.2f" % [
		prima, GameManager.ora_ritiro])
	# **Quattro secondi, no quinnece**, e il motivo è una cosa nuova della
	# 0.56: la cella dura cinque secondi e poi la giornata si chiude da
	# sola (`GameManager._passo_cella`). Contando quindici secondi si
	# misurerebbe mezzo arresto e mezza giornata finita, e il numero non
	# vorrebbe dire niente. Qui interessa una cosa sola: **mentre staje
	# dint'â cella, ll'orologio cammina?**
	for i in range(8):
		GameManager._process(0.5)
	var dopo: float = GameManager.ore_passate()
	var quanto_aveva_a_fà: float = 4.0 / GameManager.shift_duration \
		* GameManager.ORE_DI_GIORNATA
	var cammina: bool = absf((dopo - prima) - quanto_aveva_a_fà) < 0.02
	if not cammina:
		male += 1
	print("  quatto secunne appriesso: %.2f (n'aveva 'a fà %.2f)  ->  %s" % [
		dopo, prima + quanto_aveva_a_fà, "OK, cammina" if cammina
		else "STORTO, s'è fermato"])

	# E dalla galera si esce con la giornata chiusa, non con l'orologio
	# fermo: `esce_d_a_galera` segna il rientro a notte fonda.
	if GameManager.ncella:
		GameManager.esce_d_a_galera()
	var tardi: bool = GameManager.ora_ritiro >= GameManager.ORE_DI_GIORNATA - 0.01
	if not tardi:
		male += 1
	print("  'o rientro segnato: %.2f (n'aveva 'a essere %.2f)  ->  %s" % [
		GameManager.ora_ritiro, GameManager.ORE_DI_GIORNATA,
		"OK" if tardi else "STORTO"])

	print("=== %d storte ===" % male)
	get_tree().quit()
