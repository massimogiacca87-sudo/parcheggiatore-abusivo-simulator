extends Node
## 'O tiempo: cammina sempe, e nun se ferma maje.
##
## Il capo: *"l'orario e lo scorrere del tempo non funzionano ancora bene e
## si bloccano se vieni arrestato o se vai a casa"*.
##
## La colpa era di una cura scritta alla 0.51 con molta convinzione:
## `rientro_forzato()` metteva `tempo_fermo = true` perché "se ti arrestano
## non puoi fare niente". Solo che non era vero — ti riportavano a casa e
## da lì potevi uscire e lavorare, con l'orologio fermo. Il difetto che
## volevo curare (tre numeri che raccontano tre serate diverse) l'avevo
## spostato, non tolto.
##
## Qui si controlla la cosa più semplice e più importante di tutte:
## **l'orologio scende sempre**, qualunque cosa succeda. E poi il giro
## nuovo della galera, che è la cosa che *consuma* il tempo al posto di
## fermarlo.

var storte: int = 0


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame

	_prova_cammina()
	_prova_nisciuno_ferma()
	_prova_galera()
	_prova_orologio_e_cielo()

	print("=== storte: %d ===" % storte)
	get_tree().quit()


## Un minuto di gioco, a passi: l'orologio deve scendere di un minuto.
func _passa(secunne: float) -> void:
	var passo := 0.1
	var quante := int(secunne / passo)
	for i in range(quante):
		GameManager._process(passo)


func _prova_cammina() -> void:
	print("=== 'O TIEMPO CAMMINA ===")
	GameManager.start_shift()
	var prima: float = GameManager.shift_time_left
	_passa(30.0)
	var doppo: float = GameManager.shift_time_left
	print("  30 seconde: %.1f -> %.1f (scinnuto %.1f)"
		% [prima, doppo, prima - doppo])
	if absf((prima - doppo) - 30.0) > 1.5:
		male("30 seconde 'e gioco nun fanno 30 seconde 'e orologio")


## **'A prova ca conta**: nessuno stato del gioco deve poter fermare
## l'orologio. Si prova ogni bandierina che prima lo bloccava o che
## potrebbe farlo domani.
func _prova_nisciuno_ferma() -> void:
	print("=== NISCIUNO 'O FERMA ===")
	for caso in [
			{"n": "dint'a casa", "f": "dentro_casa"},
			{"n": "jurnata scaduta", "f": "giornata_scaduta"},
			{"n": "arrestato", "f": "arrested"},
			{"n": "spitale", "f": "hospitalized"},
		]:
		GameManager.start_shift()
		GameManager.set(str(caso["f"]), true)
		var prima: float = GameManager.shift_time_left
		_passa(10.0)
		var sceso: float = prima - GameManager.shift_time_left
		print("  %-16s scinnuto %.1f ncopp'a 10" % [caso["n"], sceso])
		if sceso < 9.0:
			male("cu '%s' ll'orologio se ferma" % caso["n"])
		GameManager.set(str(caso["f"]), false)

	# E `rientro_forzato` — che è la funzione che lo fermava — non deve
	# più fermare niente.
	GameManager.start_shift()
	GameManager.rientro_forzato("carabinieri")
	var p2: float = GameManager.shift_time_left
	_passa(10.0)
	var s2: float = p2 - GameManager.shift_time_left
	print("  doppo 'nu rientro furzato: scinnuto %.1f ncopp'a 10" % s2)
	if s2 < 9.0:
		male("`rientro_forzato` ferma ancora ll'orologio")
	if GameManager.tempo_fermo:
		male("`tempo_fermo` sta ancora acceso: nun 'o adda mettere cchiù nisciuno")
	GameManager.giornata_scaduta = false


func _prova_galera() -> void:
	print("=== 'A GALERA ===")
	GameManager.start_shift()
	GameManager.money = 240
	GameManager.arrested = false
	GameManager.hospitalized = false
	GameManager.ncella = false
	GameManager.sveglia_n_galera = false
	var giornata: int = GameManager.giornata

	GameManager.vai_n_galera("pruvammo")
	if GameManager.money != 0:
		male("t'hanno lassato €%d: 'n questura pigliano tutto" % GameManager.money)
	if not GameManager.ncella:
		male("nun sta 'n cella")
	if GameManager.stelle != 0:
		male("'e stelle nun se so' azzerate")
	print("  pigliate tutt''e €240, e staje dinto")

	# E il tempo, anche dentro alla cella, non si ferma: è il pannello che
	# mette in pausa l'albero, non il GameManager.
	var p: float = GameManager.shift_time_left
	_passa(5.0)
	if p - GameManager.shift_time_left < 4.0:
		male("dint'â cella ll'orologio se ferma")

	GameManager.esce_d_a_galera()
	if GameManager.ncella:
		male("nun è asciuto d''a cella")
	if not GameManager.sveglia_n_galera:
		male("dimane nun se scéta fore â galera")
	if GameManager.giornata != giornata + 1:
		male("'a jurnata nun è passata: %d -> %d" % [giornata, GameManager.giornata])
	if not GameManager.notte_ncella:
		male("'o riepilogo nun sape ca ll'hê passata dinto")
	print("  asciuto: jurnata %d, e dimane te scite fore ô purtone" % GameManager.giornata)

	# Due volte non si entra: una chiamata doppia non deve raddoppiare la
	# giornata né rifare il conto.
	GameManager.start_shift()
	GameManager.money = 100
	GameManager.arrested = false
	GameManager.vai_n_galera("una")
	GameManager.vai_n_galera("e ddoje")
	if GameManager.bail_paid != 100:
		male("'a seconda chiammata ha rifatto 'o cunto")
	GameManager.esce_d_a_galera()
	var g2: int = GameManager.giornata
	GameManager.esce_d_a_galera()
	if GameManager.giornata != g2:
		male("asci' ddoje vote fa passà ddoje jurnate")
	print("  chiammarla ddoje vote nun fa danno")

	# E la galera dev'essere lontana: la camminata di ritorno è metà della
	# punizione, e se stesse dietro l'angolo non ci sarebbe punizione.
	var quanto: float = Vector2(GameManager.GALERA_FORE.x,
		GameManager.GALERA_FORE.z).distance_to(Vector2(31.0, 30.0))
	print("  sta a %.0f metre d''a piazza toia" % quanto)
	if quanto < 90.0:
		male("'a galera sta troppo vicino: %.0f m" % quanto)


func _prova_orologio_e_cielo() -> void:
	print("=== LL'OROLOGIO E 'O CIELO SO' 'A STESSA COSA ===")
	# `ore_passate()` e `avanzamento_giornata()` devono raccontare la
	# stessa serata: è il difetto della 0.51, e da allora è un invariante.
	GameManager.start_shift()
	for frazione in [0.0, 0.25, 0.5, 0.75, 1.0]:
		GameManager.shift_time_left = GameManager.shift_duration * (1.0 - frazione)
		var av: float = GameManager.avanzamento_giornata()
		var ore: float = GameManager.ore_passate()
		var attese: float = frazione * GameManager.ORE_DI_GIORNATA
		print("  %.0f%%: avanzamento %.2f · ore passate %.1f (vuleva %.1f)"
			% [frazione * 100.0, av, ore, attese])
		if absf(av - frazione) > 0.01:
			male("ll'avanzamento nun torna a %.0f%%" % (frazione * 100.0))
		if absf(ore - attese) > 0.2:
			male("ll'ore nun tornano a %.0f%%" % (frazione * 100.0))
	GameManager.start_shift()
