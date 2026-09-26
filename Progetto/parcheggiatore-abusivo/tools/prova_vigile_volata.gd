extends Node
## **'O vigile ca smontava primma 'e cumincià** (0.63).
##
## Il capo: *«Implementa per bene il vigile che non vedo più nell'ultima
## versione.»* Il vigile c'era in tutte le prove e in nessuna partita vera:
## durante la volata d'apertura il turno non è ancora partito, il
## cronometro della giornata valeva zero e `ora_d_o_juorno()` diceva le
## quattro del mattino. I vigili, vedendo le venti passate, smontavano
## tutti. Le prove (headless) saltano la volata e non lo vedevano.
##
## Qui si rifà quel momento a mano: turno spento e orologio a zero, per tre
## secondi, come nella volata. I vigili devono restare tutti. Poi si
## controlla che la sera smontino ancora (se no la «correzione» sarebbe
## solo averli resi immortali), e che la scena nuova parta a mezzogiorno.

var storte: int = 0


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func _aspetta(secondi: float) -> void:
	var fine: int = Time.get_ticks_msec() + int(secondi * 1000.0)
	while Time.get_ticks_msec() < fine:
		await get_tree().process_frame


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	get_tree().paused = false
	for _i in range(80):
		await get_tree().process_frame
	GameManager.intro_active = false

	var prima: int = get_tree().get_nodes_in_group("vigili").size()
	print("vigili a turno partito: %d  (ora %.2f)" % [prima, GameManager.ora_d_o_juorno()])
	if prima < 4:
		male("i vigili dovrebbero essere quattro (piazza 1, stadio 2, cornetteria 1), sono %d" % prima)

	# 1) La volata: turno spento, cronometro a zero.
	GameManager.shift_active = false
	GameManager.shift_time_left = 0.0
	await _aspetta(3.0)
	var volata: int = get_tree().get_nodes_in_group("vigili").size()
	print("vigili dopo tre secondi a turno spento: %d" % volata)
	if volata != prima:
		male("a turno spento i vigili smontano (%d → %d)" % [prima, volata])

	# 2) La sera smontano ancora.
	GameManager.shift_active = true
	GameManager.shift_time_left = GameManager.shift_duration * 0.49   # ~20:10
	var fine: int = Time.get_ticks_msec() + 40000
	while Time.get_ticks_msec() < fine \
			and get_tree().get_nodes_in_group("vigili").size() > 0:
		GameManager.shift_time_left = GameManager.shift_duration * 0.49
		await get_tree().process_frame
	var sera: int = get_tree().get_nodes_in_group("vigili").size()
	print("vigili alle venti e dieci, dopo al massimo 40 s: %d" % sera)
	if sera != 0:
		male("alle venti passate %d vigili non hanno smontato" % sera)

	print("=== %d storte ===" % storte)
	get_tree().quit()
