extends Node
## **'O Super Santos: se porta e se segna?** (0.56, punto 5)
##
## Il capo: *«Migliora la fisica del pallone con cui giocano i ragazzini, al
## momento è difficile controllarlo e segnare. Se non sbaglio c'è anche una
## meccanica che facendo gol si guadagnano soldi, è un easter egg carino che
## terrei.»*
##
## «Difficile controllarlo e segnare» sono due lamentele diverse e si
## provano in due modi diversi:
##
## * **controllarlo** è il calcio: quanto parte forte e quanto si alza per
##   ogni modo di toccarlo. Si misura sui numeri, che sono l'unica cosa che
##   decide se il pallone ti resta davanti o schizza via;
## * **segnare** non si misura sui numeri, si misura **tirando**. Quaranta
##   tiri dal dischetto con la stessa imprecisione che ha uno che mira col
##   corpo, e si conta quanti entrano. Se ne entrano quattro su dieci il
##   campetto è un gioco; se ne entra uno su venti è un dispetto.
##
## E poi c'è la cosa che la prova serve a non far succedere: **'e gol d''e
## guagliune nun hann' 'a pavà**. Quelli tirano ogni dieci secondi; se ogni
## loro gol desse quattro euro, il modo più redditizio di giocare a questo
## gioco sarebbe sedersi a guardare quattro ragazzini.

const Pallone := preload("res://scripts/pallone_3d.gd")
const Citta := preload("res://scripts/citta_3d.gd")

var storte: int = 0
var _rng := RandomNumberGenerator.new()
var _gol: int = 0


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 5601
	await get_tree().process_frame
	get_tree().paused = false
	for _i in range(40):
		await get_tree().process_frame

	_prova_o_tocco()
	_prova_a_mira()
	_prova_a_linea()
	await _prova_a_tirà()
	await _prova_a_paga()
	_prova_o_campetto()

	print("=== storte: %d ===" % storte)
	get_tree().quit()


# ---------------------------------------------------------------------------
# 'O tocco: quanto parte, e quanto s'aiza
# ---------------------------------------------------------------------------
#
# La formula è quella dentro a `_check_kick`, riscritta qui sopra: si prova
# la regola, non la riga. Se domani la riga cambia e la regola resta, la
# prova deve continuare a dire di sì.

func _forza(spinta: float) -> float:
	return lerpf(Pallone.TOCCO, Pallone.CALCIO, clampf(spinta / 3.4, 0.0, 1.0))


func _prova_o_tocco() -> void:
	print("=== 'O TOCCO ===")
	print("  %-22s %-8s %-8s %s" % ["comme 'o tocche", "forza", "s'aiza",
		"quanto vola"])
	var righe := [
		["fermo (0 m/s)", 0.0, false],
		["camminanno (1,7)", 1.7, false],
		["'e corsa (3,4)", 3.4, false],
		["'e vvolo", 3.4, true],
	]
	var alzo_fermo: float = 0.0
	var forza_fermo: float = 0.0
	var forza_corsa: float = 0.0
	for r in righe:
		var f: float = Pallone.CALCIO_AL_VOLO if bool(r[2]) \
			else _forza(float(r[1]))
		var q: float = Pallone.ALZO_QUOTA_AL_VOLO if bool(r[2]) \
			else Pallone.ALZO_QUOTA
		var su: float = f * q
		# Altezza massima di un tiro che parte con velocità verticale `su`:
		# v²/2g, con la gravità del progetto.
		var vola: float = su * su / (2.0 * 9.8)
		print("  %-22s %-8.2f %-8.2f %.2f m" % [str(r[0]), f, su, vola])
		if str(r[0]).begins_with("fermo"):
			alzo_fermo = vola
			forza_fermo = f
		if str(r[0]).begins_with("'e corsa"):
			forza_corsa = f

	# **Da fermo, 'o pallone ha da rullà.** Se un tocco da fermo alza il
	# pallone più di mezzo metro non lo puoi condurre: te lo ritrovi in
	# faccia. Era il difetto vero — l'alzo fisso a 2,4 faceva trenta
	# centimetri… no, faceva ventinove centimetri di volo per ogni sfiorata
	# a 6,2 di forza, e bastava per non controllarlo mai.
	if alzo_fermo > 0.15:
		male("'nu tocco 'a fermo aiza 'o pallone 'e %.2f m: nun se porta"
			% alzo_fermo)
	if forza_fermo > 3.2:
		male("'nu tocco 'a fermo parte a %.1f m/s: troppo" % forza_fermo)
	# E di corsa dev'essere un tiro vero, se no non tiri mai.
	if forza_corsa < forza_fermo * 2.0:
		male("'e corsa nun cagna niente: %.1f contro %.1f"
			% [forza_corsa, forza_fermo])
	print("  'a corsa vale %.1f vote 'o tocco" % (forza_corsa / forza_fermo))


# ---------------------------------------------------------------------------
# 'A mira: aiuta chi ha mirato, no chi ha sbagliato
# ---------------------------------------------------------------------------

func _prova_a_mira() -> void:
	print("=== 'A MIRA ===")
	# Porta a (40, 0, 30), pallone sei metri davanti. Lontano dall'origine
	# apposta: `Vector3.ZERO` vuol dire «nun ce sta porta», e una prova che
	# mette la porta a zero prova il niente.
	var porta := Vector3(40.0, 0.0, 30.0)
	var da := Vector3(40.0, 0.3, 36.0)
	var verso_porta := Vector3(0, 0, -1)
	print("  %-16s %-10s %s" % ["storta", "doppo", "quanto ll'ha ragnata"])
	for gradi in [0.0, 15.0, 30.0, 45.0, 70.0, 120.0]:
		var dir: Vector3 = verso_porta.rotated(Vector3.UP, deg_to_rad(gradi))
		var doppo: Vector3 = Pallone.mira_a(dir, Pallone.CALCIO, da, porta)
		var prima_g: float = rad_to_deg(acos(clampf(dir.dot(verso_porta),
			-1.0, 1.0)))
		var doppo_g: float = rad_to_deg(acos(clampf(doppo.dot(verso_porta),
			-1.0, 1.0)))
		print("  %-16.0f %-10.1f %.1f gradi" % [prima_g, doppo_g,
			prima_g - doppo_g])
		# Fuori dal cono non si aiuta nessuno.
		if gradi > 60.0 and absf(prima_g - doppo_g) > 0.1:
			male("'a mira aiuta pure 'nu tiro 'e %.0f gradi" % gradi)
		# Dentro al cono si aiuta, ma non si spara dentro alla porta da sé.
		if gradi > 5.0 and gradi < 45.0:
			if doppo_g >= prima_g - 0.5:
				male("'nu tiro 'e %.0f gradi nun vene aiutato manco 'nu poco"
					% gradi)
			if doppo_g < prima_g * 0.3:
				male("'a mira fa troppo: 'a %.0f a %.1f gradi"
					% [prima_g, doppo_g])

	# Un tocco da fermo non si aiuta: stai conducendo, non tirando.
	var storto := Vector3(0, 0, -1).rotated(Vector3.UP, deg_to_rad(20.0))
	if Pallone.mira_a(storto, Pallone.TOCCO, da, porta) != storto:
		male("'a mira s'impiccia pure quanno staje purtanno 'o pallone")
	print("  'o tocco 'a fermo nun vene mirato")

	# E da lontano non si aiuta: la mira è un aiuto a chi tira, non un
	# telecomando da mezza città.
	var luntano := Vector3(40.0, 0.3, 30.0 + Pallone.MIRA_DISTANZA + 4.0)
	if Pallone.mira_a(storto, Pallone.CALCIO, luntano, porta) != storto:
		male("'a mira aiuta pure 'a %.0f metre" % (Pallone.MIRA_DISTANZA + 4.0))
	print("  'a cchiù 'e %.0f metre nun se mira" % Pallone.MIRA_DISTANZA)


# ---------------------------------------------------------------------------
# 'A linea: 'o tiro forte ha da valé
# ---------------------------------------------------------------------------
#
# Questa è la prova che il vecchio codice avrebbe fallito. Il pallone va a
# ventidue metri al secondo, cioè trentasette centimetri a fotogramma: la
# scatola da settanta centimetri intorno alla linea se la saltava.
#
# Si prova `Pallone.gol()` da sola, senza corpo rigido: la regola è quella,
# e una regola si prova per quello che dice.

func _prova_a_linea() -> void:
	print("=== 'A LINEA ===")
	var c := Vector3(40.0, 0.0, 30.0)
	var n := Vector3(0, 0, -1)
	var largh := 3.2
	var alt := 2.0
	var casi := [
		["'nu tiro chiano dint'â porta", Vector3(40, 0.4, 30.3),
			Vector3(40, 0.4, 29.9), true],
		["'na cannunata (75 cm 'a frame)", Vector3(40.2, 1.1, 30.4),
			Vector3(40.2, 1.1, 29.65), true],
		["ncopp'ô palo, ma dinto", Vector3(41.5, 0.4, 30.3),
			Vector3(41.5, 0.4, 29.9), true],
		["'nu tiro 'a fore d''e pale", Vector3(43.0, 0.4, 30.3),
			Vector3(43.0, 0.4, 29.9), false],
		["'nu tiro ncopp'â traversa", Vector3(40, 3.4, 30.3),
			Vector3(40, 3.4, 29.9), false],
		["'o pallone ca torna 'a rete", Vector3(40, 0.4, 29.6),
			Vector3(40, 0.4, 30.3), false],
		["'nu pallone ca passa 'e llato", Vector3(45, 0.4, 30.3),
			Vector3(46, 0.4, 29.9), false],
	]
	for caso in casi:
		var fatto: bool = Pallone.gol(caso[1], caso[2], c, n, largh, alt)
		var voluto: bool = bool(caso[3])
		print("  %-34s %s" % [str(caso[0]), "GOL" if fatto else "niente"])
		if fatto != voluto:
			male("%s: %s, ma nn'aveva 'a essere %s"
				% [str(caso[0]), "gol" if fatto else "niente",
				"gol" if voluto else "niente"])

	# **'A porta d''e guagliune sta girata**: si entra verso +X. Se la
	# regola sapesse fare solo le porte lungo Z, di là non si segnerebbe
	# mai e nessuno capirebbe perché.
	var cg := Vector3(36.0, 0.0, 139.0)
	var ng := Vector3(1, 0, 0)
	if not Pallone.gol(Vector3(35.6, 0.4, 139.0), Vector3(36.3, 0.4, 139.0),
			cg, ng, 2.8, 1.15):
		male("dint'â porta d''e guagliune nun se po' segnà")
	else:
		print("  'a porta d''e guagliune (girata verso +X) conta")

	# E i gol dei guaglioni non pagano: quello lo decide `_tuo`, e si prova
	# col pallone vero più sotto.


# ---------------------------------------------------------------------------
# 'E quaranta tire: se segna overo?
# ---------------------------------------------------------------------------

func _prova_a_tirà() -> void:
	print("=== 'E QUARANTA TIRE ===")
	var palloni: Array = get_tree().get_nodes_in_group("palloni")
	print("  %d palloni dint'â città" % palloni.size())
	if palloni.is_empty():
		male("nun ce sta manco 'nu pallone")
		return
	# Si sceglie quello del campetto: è quello con la porta più larga.
	var b = palloni[0]
	for p in palloni:
		if p.goal_width > b.goal_width:
			b = p
	var porta: Vector3 = b.goal_center
	print("  'a porta sta a %s, larga %.1f, auta %.1f"
		% [str(porta.round()), b.goal_width, b.goal_height])

	var dentro := 0
	var prove := 40
	for _n in range(prove):
		var da: Vector3 = b.home
		b.global_position = da
		b.linear_velocity = Vector3.ZERO
		b.angular_velocity = Vector3.ZERO
		# Il corpo rigido si sposta davvero solo quando il motore fisico
		# gira: senza aspettare un fotogramma, il pallone sta ancora dove
		# l'ha lasciato il tiro di prima e il segmento fra le due
		# posizioni taglia mezza piazza.
		await get_tree().physics_frame
		b.global_position = da
		b._prima = da
		b._tuo = true
		# Il banco chiude dopo quattro gol al giorno: qui si sta provando la
		# mira, non l'economia, quindi si riapre a ogni tiro.
		GameManager.gol_pavate = 0
		var prima_sorde: int = GameManager.money
		# La mira di uno che punta col corpo: quindici gradi di sbaglio,
		# che è tanto — a sei metri sono un metro e mezzo di scarto, cioè
		# il palo.
		var dir: Vector3 = (porta - da)
		dir.y = 0.0
		dir = dir.normalized().rotated(Vector3.UP,
			deg_to_rad(_rng.randf_range(-15.0, 15.0)))
		dir = b._mira(dir, Pallone.CALCIO)
		b.linear_velocity = dir * Pallone.CALCIO \
			+ Vector3.UP * (Pallone.CALCIO * Pallone.ALZO_QUOTA)
		for _i in range(140):
			await get_tree().physics_frame
			if GameManager.money > prima_sorde:
				dentro += 1
				break
	var quota: float = float(dentro) / float(prove)
	print("  %d/%d dint'â porta = %.0f%%" % [dentro, prove, quota * 100.0])
	# **Ccà se segna, e s'ha dda segnà.** Dal dischetto, mirando storto di
	# quindici gradi, uno deve prenderla quasi sempre: è un pallone di
	# gomma a sei metri, non una punizione dal limite. Quello che NON deve
	# succedere è che diventi uno stipendio, e quello non si aggiusta
	# rendendo il pallone scomodo — si aggiusta chiudendo il banco dopo
	# quattro gol al giorno (vedi `GameManager.GOL_PAVATE_Ô_JUORNO`), che è
	# la cosa che si prova qua sotto.
	if quota < 0.55:
		male("se segna sulo 'o %.0f%% d''e vote: troppo poco" % (quota * 100.0))


# ---------------------------------------------------------------------------
# 'E gol d''e guagliune nun pavano
# ---------------------------------------------------------------------------
#
# È la regola che tiene in piedi l'easter egg. I guaglioni tirano ogni dieci
# secondi e la porta la pigliano spesso: se ogni loro gol desse i quattro
# euro, il mestiere più redditizio del gioco sarebbe **stare a guardare**.
# Vale l'ultimo tocco, come nel calcio vero.

func _prova_a_paga() -> void:
	print("=== CHI PAVA E CHI NO ===")
	var b = Pallone.new()
	add_child(b)
	b.goal_width = 3.2
	b.goal_height = 2.0
	b.goal_center = Vector3(40.0, 0.0, 30.0)
	b.goal_normale = Vector3(0, 0, -1)
	b.home = Vector3(40.0, 0.27, 35.6)
	await get_tree().physics_frame

	for tuo in [true, false]:
		b._tuo = tuo
		# Il banco chiude dopo quattro gol al giorno: qui si sta provando la
		# mira, non l'economia, quindi si riapre a ogni tiro.
		GameManager.gol_pavate = 0
		var prima_sorde: int = GameManager.money
		var prima_gol: int = GameManager.goals
		b._score()
		var pavato: int = GameManager.money - prima_sorde
		print("  gol %s: +€%d, %d gol segnate"
			% ["tuojo" if tuo else "d''e guagliune", pavato,
			GameManager.goals - prima_gol])
		if tuo and pavato != GameManager.GOAL_REWARD:
			male("'nu gol tuojo t'ha dato €%d 'nvece 'e €%d"
				% [pavato, GameManager.GOAL_REWARD])
		if not tuo and pavato != 0:
			male("'nu gol d''e guagliune t'ha dato €%d" % pavato)

	# E dopo un gol tuo il pallone non è più tuo: se no il secondo gol di
	# un guagliuno ti pagherebbe lo stesso.
	GameManager.gol_pavate = 0
	b._tuo = true
	b._score()
	if b._tuo:
		male("doppo 'o gol 'o pallone resta tuojo: 'o prossimo pava 'o stesso")
	else:
		print("  doppo 'o gol 'o pallone nun è cchiù tuojo")

	# **'O banco chiude.** Quattro gol al giorno si pagano; dal quinto in
	# poi si grida e basta. È quello che tiene l'easter egg un easter egg.
	GameManager.gol_pavate = 0
	var guadagnato := 0
	for i in range(10):
		var prima: int = GameManager.money
		b._tuo = true
		b._score()
		guadagnato += GameManager.money - prima
	print("  diece gol 'e fila hanno rennuto €%d (ne vuleva %d)"
		% [guadagnato, GameManager.GOL_PAVATE_Ô_JUORNO * GameManager.GOAL_REWARD])
	if guadagnato != GameManager.GOL_PAVATE_Ô_JUORNO * GameManager.GOAL_REWARD:
		male("diece gol hanno dato €%d: 'o banco nun chiude" % guadagnato)
	# E la mattina dopo riapre.
	GameManager.start_shift()
	if GameManager.gol_pavate != 0:
		male("doppo ca hê durmuto 'o banco resta chiuso")
	else:
		print("  'a matina appriesso 'o banco riapre")
	b.queue_free()


# ---------------------------------------------------------------------------
# 'O campetto d''e guagliune
# ---------------------------------------------------------------------------

func _prova_o_campetto() -> void:
	print("=== 'O CAMPETTO D''E GUAGLIUNE ===")
	var campi: Array = get_tree().get_nodes_in_group("bambini")
	print("  %d campette" % campi.size())
	if campi.is_empty():
		male("nun ce stanno cchiù 'e guagliune")
		return
	for c in campi:
		var centro: Vector3 = c.global_position
		var porta: Vector3 = centro + Vector3(c.RAGGIO_CAMPO, 0, 0)
		var dinto_c: bool = Citta.dint_ô_palazzo(centro, 0.3)
		var dinto_p: bool = Citta.dint_ô_palazzo(porta, 0.3)
		print("  campo a %s  → porta a %s   %s"
			% [str(centro.round()), str(porta.round()),
			"STORTO" if (dinto_c or dinto_p) else "a posto"])
		if dinto_c:
			male("'o campetto a %s sta dint'a 'nu palazzo" % str(centro.round()))
		if dinto_p:
			male("'a porta d''o campetto a %s sta dint'a 'nu palazzo"
				% str(centro.round()))
		# E il pallone vero ci dev'essere.
		var trovato := false
		for n in c.get_children():
			if n is RigidBody3D:
				trovato = true
		if not trovato:
			male("'o campetto a %s nun tene 'o pallone overo"
				% str(centro.round()))
	print("  tutte 'e campette teneno 'o Super Santos")
