extends Node
## **'O furto: 'o scasso, 'a guida, 'o garage** (0.57)
##
## Il capo ha chiesto tre cose in una frase sola — il minigioco, la guida
## veloce, la consegna al garage — e questa prova le guarda tutte e tre,
## ma soprattutto guarda **'e junture**, che sono il posto in cui questo
## progetto si rompe da venti versioni.
##
## La lezione della 0.56 era *chello ca nun dà errore nun vò dì ca va
## bbuono*: il secondo sospetto è che nessuna prova stia guardando quella
## cosa. E infatti il furto d'auto **non dava errore da sei versioni** —
## `puoi_arrubba()` chiedeva un lavoro della bacheca che era stato tolto
## alla 0.50, quindi tornava sempre falso, e il gioco compilava, girava e
## non si lamentava. Quaranta prove verdi e una funzione morta.
##
## Quindi qui la prima domanda non è "funziona?" ma **"se può fare?"**: si
## mette una macchina posteggiata davanti al player, con l'autista che se
## n'è andato a fare la spesa, e si chiede al gioco se il furto si può
## cominciare. Se quella risposta è falsa, tutto il resto non conta niente.

const CarScript := preload("res://scripts/car_3d.gd")
const PannelloScassa := preload("res://scripts/pannello_scassa.gd")

var storte: int = 0


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func bbuono(msg: String) -> void:
	print("  ok: %s" % msg)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(140):
		await get_tree().process_frame

	await _prova_tabella()
	await _prova_finestra()
	await _prova_pannello()
	await _prova_prezzo()
	await _prova_guida()
	await _prova_garage()
	await _prova_a_verita()

	print("=== storte: %d ===" % storte)
	get_tree().quit()


# ---------------------------------------------------------------------------
# 1. 'A tabella d''e difficoltà
# ---------------------------------------------------------------------------
#
# «più difficile in base all'auto da rubare»: non basta che i numeri siano
# diversi, devono andare **tutti nello stesso verso**. Una tabella in cui
# 'o macchinone ha più spille ma la finestra più larga non è più difficile:
# è diversa.

func _prova_tabella() -> void:
	print("=== 'A TABELLA D''O SCASSO ===")
	var ordine := ["economica", "berlina", "lusso", "bmw"]
	var prima: Dictionary = {}
	print("  %-12s %-7s %-7s %-7s %-7s %s"
		% ["tipo", "spille", "zona", "vel", "rotte", "valore"])
	for t in ordine:
		if not GameManager.SCASSO.has(t):
			male("nun ce sta 'a voce '%s' dint'ô SCASSO" % t)
			continue
		var d: Dictionary = GameManager.SCASSO[t]
		print("  %-12s %-7d %-7.2f %-7.2f %-7d €%d" % [t, int(d["spille"]),
			float(d["zona"]), float(d["vel"]), int(d["rotte"]),
			int(d["valore"])])
		if prima.is_empty():
			prima = d
			continue
		if int(d["spille"]) < int(prima["spille"]):
			male("%s tene meno spille 'e chella 'e primma" % t)
		if int(d["rotte"]) < int(prima["rotte"]):
			male("%s tene meno spille rotte" % t)
		if int(d["valore"]) <= int(prima["valore"]):
			male("%s vale 'o stesso o meno: 'o rischio nun se paga" % t)
		# **'A manopola ca conta nun è né 'a zona né 'a velocità: è 'o
		# tiempo utile**, cioè `zona / velocità` — quanti millisecondi 'o
		# cursore resta dinto ô verde a ogni passaggio.
		#
		# La prima versione di questa prova controllava le due manopole
		# separatamente ("la finestra si stringe" e "il cursore accelera") e
		# le trovava tutte e due giuste. Erano giuste tutte e due, e insieme
		# facevano un numero sbagliato: stringere e accelerare insieme fa
		# crollare il tempo utile col prodotto, e il macchinone era uscito a
		# 68 ms — quattro fotogrammi. Una prova che guarda i pezzi e non il
		# numero che sente chi gioca non sta provando il gioco ('a lezione
		# d''a 0.56b).
		if _utile(d) >= _utile(prima):
			male("%s: 'o tiempo utile nun cala (%.0f ms contr'a %.0f)"
				% [t, _utile(d) * 1000.0, _utile(prima) * 1000.0])
		prima = d
	if storte == 0:
		bbuono("'e quatto macchine vanno tutte 'n salita")

	# **'O dado nun ha da fa' 'na cosa 'mpossibbile.** Cento tiri per tipo:
	# la finestra deve restare dentro ai limiti, se no una volta ogni tanto
	# esce una serratura che non si apre nemmeno con la fortuna.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7719
	for t in ordine:
		var min_z: float = 9.0
		var max_v: float = 0.0
		for _i in range(100):
			var s: Dictionary = GameManager.scasso_pe(t, rng)
			min_z = minf(min_z, float(s["zona"]))
			max_v = maxf(max_v, float(s["vel"]))
		print("  %-12s ncopp'a 100 tire: zona minima %.3f, vel massima %.2f"
			% [t, min_z, max_v])
		if min_z < 0.06:
			male("%s: 'na vota esce 'na finestra 'e niente (%.3f)"
				% [t, min_z])
		# **'O peggio d''e cento tire**, che è quello che decide se il
		# minigioco è giocabile: la finestra più stretta uscita insieme al
		# cursore più veloce.
		var dentro: float = min_z / max_v
		print("      ô peggio 'o cursore ce sta dinto %.0f ms (%.1f fotogramme a 60)"
			% [dentro * 1000.0, dentro * 60.0])
		# Cento millisecondi sono sei fotogrammi a sessanta e tre a trenta:
		# è il confine sotto al quale non è più tempismo, è una monetina.
		if dentro < 0.100:
			male("%s: 'o cursore ce sta dinto sulo %.0f ms: è 'nu dado"
				% [t, dentro * 1000.0])


# ---------------------------------------------------------------------------
# 2. **'A finestra d''o furto** — 'a prova ca conta
# ---------------------------------------------------------------------------
#
# Questa è la prova che sei versioni fa non c'era, ed è per questo che il
# furto è rimasto morto senza che nessuno se ne accorgesse. Non chiede "la
# funzione risponde?": chiede **"esiste un momento in cui si può rubare?"**

func _prova_finestra() -> void:
	print("=== 'A FINESTRA D''O FURTO ===")
	var c: Node = _machina_finta()
	if c == null:
		male("nun s'è riuscito a fa' 'na machina 'e prova")
		return

	# a) Posteggiata, 'o padrone luntano: s'adda puté.
	c.set("state", CarScript.State.PARKED)
	c.set("has_multa", false)
	GameManager.auto_guidata = null
	if not c.puoi_arrubba():
		male("posteggiata e senza padrone e nun se pò arrubbà: "
			+ "'o cancello è ancora nchiuso")
	else:
		bbuono("posteggiata e senza padrone: se pò scassà")

	# b) Cu 'a multa ncopp'ô vetro: no.
	c.set("has_multa", true)
	if c.puoi_arrubba():
		male("se pò arrubbà pure cu 'a multa ncopp'ô vetro")
	else:
		bbuono("cu 'a multa nun se tocca")
	c.set("has_multa", false)

	# c) Mentre ne staje guidanno n'ata: no.
	GameManager.auto_guidata = c
	if c.puoi_arrubba():
		male("se ne ponno arrubbà doje 'n coppa a n'ata")
	else:
		bbuono("'na machina a vota")
	GameManager.auto_guidata = null

	# d) Ancora 'n coda (WAITING): no.
	c.set("state", CarScript.State.WAITING)
	if c.puoi_arrubba():
		male("se pò arrubbà 'na machina ca sta ancora 'n coda")
	else:
		bbuono("'n coda nun se tocca")
	c.set("state", CarScript.State.PARKED)

	# e) 'O prompt adda dicere ch'è 'o scasso, e adda nummenà 'a difficoltà.
	var p: String = str(c.get_interact_prompt(Vector3.ZERO))
	print("  prompt: %s" % p)
	if not p.contains("scassa"):
		male("'o prompt nun dice ca se pò scassà: «%s»" % p)
	if not p.contains(GameManager.scasso_nomme(str(c.get("car_type")))):
		male("'o prompt nun dice quanto è difficile")

	# f) **'O culore nun adda fa' scuppià niente.** `colore_id()` chiamava
	#    `GameManager.COLORI_FURTO`, che nun ce sta cchiù 'a 0.50: era 'na
	#    bomba a orologeria ca nun scuppiava sulo pecché nun ce arrivava
	#    maje nisciuno.
	print("  culore: %s   ·   nomma: %s" % [str(c.colore_id()),
		str(c.nomma_machina())])

	c.queue_free()
	await get_tree().process_frame


# ---------------------------------------------------------------------------
# 3. 'O pannello
# ---------------------------------------------------------------------------

func _prova_pannello() -> void:
	print("=== 'O PANNELLO D''O SCASSO ===")
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null:
		male("nun ce sta 'o player")
		return

	var pan: CanvasLayer = PannelloScassa.new()
	get_tree().root.add_child(pan)
	await get_tree().process_frame

	var pausa_primma: bool = get_tree().paused
	pan.apri("bmw", "'na bmw nera", pl)
	await get_tree().process_frame

	# **'O munno nun s'adda fermà.** È la scelta di regia di questo
	# pannello, e una scelta di regia che nessuno controlla è una scelta
	# che alla prossima versione sparisce senza che nessuno se ne accorga.
	if get_tree().paused != pausa_primma:
		male("'o pannello mette 'n pausa 'o munno: 'a tensione d''o furto se perde")
	else:
		bbuono("'o munno cammina pure mentre scasse")

	# 'O player adda sta' fermo.
	if pl.is_physics_processing():
		male("'o player cammina ancora mentre tene 'e mmane dint'â serratura")
	else:
		bbuono("'o player sta fermo")

	# 'O cursore s'adda movere.
	var dove: float = float(pan.get("_cursore"))
	for _i in range(20):
		await get_tree().process_frame
	var doppo: float = float(pan.get("_cursore"))
	if is_equal_approx(dove, doppo):
		male("'o cursore nun se move: 'o minigioco nun cammina")
	else:
		bbuono("'o cursore corre (%.3f -> %.3f)" % [dove, doppo])

	# **'A zona bbona nun adda sta' mai sotto ê spille rotte**, se no ce
	# stanno serrature ca nun s'arapono e nisciuno capisce pecché.
	var giri: int = 0
	var male_zone: int = 0
	while giri < 400:
		giri += 1
		pan.call("_nova_spilla")
		var za: float = float(pan.get("_zona_da"))
		var zb: float = float(pan.get("_zona_a"))
		if za < -0.001 or zb > 1.001 or zb <= za:
			male_zone += 1
			continue
		for r in pan.get("_rotte"):
			if float(r["a"]) > za and float(r["da"]) < zb:
				male_zone += 1
				break
	if male_zone > 0:
		male("%d zone 'n coppa a 400 stanno fore o sotto a 'na spilla rotta"
			% male_zone)
	else:
		bbuono("400 spille: 'a zona bbona sta sempe dint'â barra e sempe libbera")

	pan.chiudi(false)
	await get_tree().process_frame
	if not pl.is_physics_processing():
		male("doppo 'o scasso fallito 'o player resta congelato")
	else:
		bbuono("chiuso 'o pannello, 'o player cammina n'ata vota")
	pan.queue_free()
	await get_tree().process_frame


# ---------------------------------------------------------------------------
# 4. 'O prezzo
# ---------------------------------------------------------------------------
#
# **'A prova ca guarda si 'a 0.57 ha rutto 'o gioco.** Una berlina vale più
# di due giornate di posteggio: se il garage la pagasse sempre uguale,
# nessuno posteggerebbe più niente e questo gioco cambierebbe mestiere
# senza che nessuno l'abbia deciso.

func _prova_prezzo() -> void:
	print("=== 'O PREZZO ===")
	GameManager.auto_vennute = 0
	var prime: Array = []
	for i in range(5):
		GameManager.auto_vennute = i
		prime.append(GameManager.quanto_vale_a_machina("berlina"))
	print("  berlina, cinche 'n fila dint'a 'na jurnata: %s" % str(prime))
	# Solo fin dove il garage piglia: doppo 'o piazzale è chino e 'o prezzo
	# resta ô pavimento (`VENNUTA_MINIMO`), e va bbuono accussì.
	for i in range(1, mini(prime.size(), GameManager.GARAGE_MAX_JURNATA)):
		if int(prime[i]) >= int(prime[i - 1]):
			male("'a %da machina se paga 'o stesso o cchiù d''a primma" % (i + 1))
	if int(prime[4]) > int(prime[0]) / 2:
		male("â quinta se paga ancora cchiù d''a metà: 'o freno nun frena")
	else:
		bbuono("'a quinta vale %d ncopp'a %d d''a primma"
			% [int(prime[4]), int(prime[0])])

	# 'E botte se ponno vedé dint'ô prezzo.
	GameManager.auto_vennute = 0
	var sana: int = GameManager.quanto_vale_a_machina("lusso", 0, 0)
	var rotta: int = GameManager.quanto_vale_a_machina("lusso", 4, 0)
	var chino: int = GameManager.quanto_vale_a_machina("lusso", 0, 5)
	print("  lusso: sana €%d · cu 4 botte €%d · cu 5 spille 'n chino €%d"
		% [sana, rotta, chino])
	if rotta >= sana:
		male("'e botte nun se pavano")
	if chino <= sana:
		male("'a mano ferma nun vale niente")

	# **'O paragone ca conta**: una giornata intera di posteggio quanto fa?
	# Se la prima macchina vale più di due giornate, il mestiere è finito.
	GameManager.auto_vennute = 0
	var primma_bmw: int = GameManager.quanto_vale_a_machina("bmw")
	print("  'a primma bmw d''a jurnata: €%d" % primma_bmw)
	# **0.61**: la soglia era 600 euro, cioè sette giornate e mezza — una
	# prova che accettava il bug che il capo ha trovato giocando. Adesso si
	# misura con la giornata tipo: la macchina più cara vale al massimo una
	# giornata e mezza, l'utilitaria al massimo mezza.
	#
	# **0.62**: il capo ha chiesto che una macchina rubata valga un centinaio
	# d'euro, «abbastanza per pagare le spese per qualche giorno». Allora la
	# berlina deve stare fra 85 e 115 euro, la bmw al massimo due giornate e
	# mezza, l'utilitaria al massimo una giornata.
	var tetto: float = float(GameManager.GIORNATA_TIPO) * 2.5
	if primma_bmw > int(tetto):
		male("'a primma bmw vale €%d, cchiù 'e dduje jurnate e mmeza (€%.0f)"
			% [primma_bmw, tetto])
	var primma_eco: int = GameManager.quanto_vale_a_machina("economica")
	if primma_eco > GameManager.GIORNATA_TIPO:
		male("'n'utilitaria vale €%d: cchiù 'e 'na jurnata" % primma_eco)
	var primma_berlina: int = GameManager.quanto_vale_a_machina("berlina")
	if primma_berlina < 85 or primma_berlina > 115:
		male("'a primma berlina vale €%d: 'o capo ha ditto 'nu centinaro"
			% primma_berlina)
	else:
		bbuono("'a primma berlina vale €%d: 'nu paro 'e juorne 'e spese"
			% primma_berlina)
	# E 'o piazzale se chiude.
	GameManager.auto_vennute = GameManager.GARAGE_MAX_JURNATA
	if not GameManager.garage_chino():
		male("doppo %d machine 'o garage piglia ancora"
			% GameManager.GARAGE_MAX_JURNATA)
	# Tutta 'a jurnata 'e furti, 'o massimo: tre bmw 'n fila.
	var tutto := 0
	for i in range(GameManager.GARAGE_MAX_JURNATA):
		GameManager.auto_vennute = i
		tutto += GameManager.quanto_vale_a_machina("bmw")
	print("  'o massimo 'e 'na jurnata 'e furti: €%d (jurnata tipo €%d)"
		% [tutto, GameManager.GIORNATA_TIPO])
	if tutto > GameManager.GIORNATA_TIPO * 4:
		male("tre furti fanno €%d: cchiù 'e quatto jurnate" % tutto)
	GameManager.auto_vennute = 0

	# 'O grimaldello adda servì a quaccosa, ma nun adda regalà niente.
	var rng := RandomNumberGenerator.new()
	rng.seed = 5150
	GameManager.upgrades["grimaldello"] = false
	var senza: float = 0.0
	for _i in range(200):
		senza += float(GameManager.scasso_pe("lusso", rng)["zona"])
	GameManager.upgrades["grimaldello"] = true
	var cu: float = 0.0
	for _i in range(200):
		cu += float(GameManager.scasso_pe("lusso", rng)["zona"])
	GameManager.upgrades["grimaldello"] = false
	print("  zona media 'e 'nu lusso: senza %.3f, cu 'o grimaldello %.3f"
		% [senza / 200.0, cu / 200.0])
	if cu <= senza:
		male("'o grimaldello nun allarga niente: so' 55 euro jettate")


# ---------------------------------------------------------------------------
# 5. 'A guida
# ---------------------------------------------------------------------------

func _prova_guida() -> void:
	print("=== 'A GUIDA ===")
	# «un sistema di guida semplice che permetta di spostarsi velocemente in
	# città»: veloce vuol dire **più veloce che a piedi**, e di parecchio.
	# Se no la macchina è solo merce da spingere fino al garage.
	var PlayerScript := load("res://scripts/player_fps.gd")
	var a_pere: float = float(PlayerScript.SPRINT_SPEED)
	print("  a pere 'e corsa: %.1f m/s   ·   'n machina: %.1f m/s (sgasanno %.1f)"
		% [a_pere, CarScript.RUBATA_VEL, CarScript.RUBATA_VEL_SGASO])
	if CarScript.RUBATA_VEL <= a_pere:
		male("'a machina va comm'a uno ca corre: nun serve a niente")
	elif CarScript.RUBATA_VEL_SGASO < a_pere * 2.0:
		male("manco 'o doppio d''a corsa: nun è 'nu mezzo, è 'na cammenata assettata")
	else:
		bbuono("'n machina se va %.1f vote cchiù 'e 'na corsa"
			% (CarScript.RUBATA_VEL_SGASO / a_pere))

	# Quanto ci metti ad attraversare la città con la macchina e a piedi.
	var Citta := load("res://scripts/citta_3d.gd")
	var garage: Vector3 = Citta.POSTO_GARAGE
	var casa := Vector3(28.0, 0.0, 60.0)
	var strada: float = casa.distance_to(garage)
	print("  'a piazza ô garage: %.0f metre" % strada)
	print("  a pere %.0fs   ·   'n machina %.0fs"
		% [strada / a_pere, strada / CarScript.RUBATA_VEL_SGASO])
	if strada < 60.0:
		male("'o garage sta a %.0f metre: nun è 'na traversata, è 'nu passo"
			% strada)

	# 'O posto 'e guida adda sta' annanze e a sinistra, no dint'ô mutore.
	var pg: Vector3 = CarScript.POSTO_GUIDA
	print("  posto 'e guida: (%.2f, %.2f, %.2f)" % [pg.x, pg.y, pg.z])
	if pg.z > 0.0:
		male("'a capa sta arreto ô centro: 'e fare stanno a −Z, 'o muso pure")
	if pg.x > 0.0:
		male("'o posto 'e guida sta a destra: ccà se guida a sinistra")
	if pg.y < 0.8:
		male("'a capa sta a %.2f m: se vede 'o cofano e basta" % pg.y)


# ---------------------------------------------------------------------------
# 6. 'O garage
# ---------------------------------------------------------------------------

func _prova_garage() -> void:
	print("=== 'O GARAGE ===")
	var gg: Array = get_tree().get_nodes_in_group("garage")
	print("  garage 'n città: %d" % gg.size())
	if gg.is_empty():
		male("nun ce sta manco 'nu garage: 'e mmacchine nun se ponno cunzegnà")
		return
	if gg.size() > 1:
		male("ce stanno %d garage: 'o capo ne ha chiesto uno, luntano"
			% gg.size())
	var g: Node3D = gg[0]
	print("  sta a %s, raggio %.1f" % [str(g.global_position.round()),
		float(g.get("RAGGIO"))])

	# **Se ce s'adda puté trasì cu 'na machina.** Una saracinesca in fondo a
	# un vicolo di quattro metri è una saracinesca che non si imbocca, e il
	# gioco nuovo morirebbe lì senza dare un solo errore.
	var Citta := load("res://scripts/citta_3d.gd")
	var citta := get_tree().root.find_child("Citta", true, false)
	if citta == null:
		male("nun s'è truvata 'a città")
		return
	var largo: int = 0
	var passi: int = 0
	for i in range(24):
		var a: float = TAU * float(i) / 24.0
		var p: Vector3 = g.global_position + Vector3(sin(a), 0, cos(a)) * 6.0
		passi += 1
		if not Citta.dint_ô_palazzo(p, 0.0):
			largo += 1
	print("  attuorno ô garage: %d punte libbere 'n coppa a %d" % [largo, passi])
	if largo < 10:
		male("'o garage sta 'nchiuso: cu 'na machina nun ce se trase")
	else:
		bbuono("attuorno ce sta spazio p''a manovra")

	# 'A consegna: se simula l'arrivo e se guarda ca 'e sorde arrivano.
	var sorde: int = GameManager.money
	GameManager.auto_vennute = 0
	var paga: int = GameManager.vinni_machina("berlina", 0, 2)
	print("  cunzegnata 'na berlina cu 2 spille 'n chino: €%d" % paga)
	if paga <= 0:
		male("'a consegna nun paga niente")
	if GameManager.money != sorde + paga:
		male("'e sorde nun songo trasute 'n cascia")
	if GameManager.auto_vennute != 1:
		male("'o cunto d''e mmacchine vennute nun saglie")
	GameManager.auto_vennute = 0


# ---------------------------------------------------------------------------
# 'A machina 'e prova
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# 7. **'A PROVA D''A VERITÀ**
# ---------------------------------------------------------------------------
#
# Tutte le prove di sopra lavorano su una macchina che mi sono fabbricato io,
# messa nello stato che dico io. Sono utili e **non bastano**, e questo
# progetto ne ha la dimostrazione scritta: dalla 0.50 alla 0.56 il furto
# d'auto aveva un cancello che non si apriva mai, e nessuna prova se n'è
# accorta perché nessuna prova ha mai lasciato girare la città e chiesto
# *«mo', in questo momento, c'è una macchina che si può rubare?»*.
#
# Questa fa quello e basta: lascia correre la piazza vera, guarda tutte le
# macchine vere a ogni fotogramma, e conta **quante volte nel giro di una
# giornata si apre una finestra per rubare**. Se la risposta è zero, tutto
# il lavoro della 0.57 è arredamento.
const VERITA_SECUNNE: float = 150.0

func _prova_a_verita() -> void:
	print("=== 'A PROVA D''A VERITÀ: se pò arrubbà overo? ===")
	GameManager.auto_guidata = null
	# **'A piazza nun cammina si nun se apre 'a jurnata.** Il banco di prova
	# headless parte sulla schermata di caricamento: `shift_active` è falso,
	# e `posteggio_3d` non fa arrivare nemmeno una macchina. La prima volta
	# che ho fatto girare questa sezione il conto era zero su zero, e il
	# guasto stava qui e non nel gioco — è il rovescio esatto della lezione
	# della 0.55 (*quanno 'na cosa nun se vede, 'o primmo suspetto è 'a
	# prova*), e per una volta il sospetto era giusto.
	get_tree().paused = false
	GameManager.giornata = 3
	GameManager.start_shift()
	GameManager.tipo_giornata = "normale"
	GameManager.intro_active = false
	await get_tree().process_frame
	var viste: Dictionary = {}       # rid -> secondi in cui era rubabile
	var mai_posteggiate: Dictionary = {}
	var tempo: float = 0.0
	var quante_max: int = 0
	var viste_mai: Dictionary = {}
	var stati: Dictionary = {}

	# **'O munno se fa correre tre vote cchiù ampresso.** Centocinquanta
	# secondi di piazza vera sono centocinquanta secondi di attesa anche in
	# headless, e una prova che si fa aspettare tre minuti è una prova che
	# a un certo punto qualcuno smette di far girare. Il tempo *dentro* al
	# gioco resta quello vero: `delta` cresce insieme alla scala, quindi i
	# secondi che conto sono i secondi che sentirebbe chi gioca.
	Engine.time_scale = 3.0
	while tempo < VERITA_SECUNNE:
		await get_tree().process_frame
		var d: float = get_process_delta_time()
		tempo += d
		var mo: int = 0
		for c in get_tree().get_nodes_in_group("cars"):
			if not is_instance_valid(c) or not c.has_method("puoi_arrubba"):
				continue
			var rid: int = c.get_instance_id()
			viste_mai[rid] = true
			var st: int = int(c.get("state"))
			stati[st] = float(stati.get(st, 0.0)) + d
			# **'O guaglione posteggia p'te.** Senza di lui le macchine
			# restano in coda per sempre, perché è il giocatore che le
			# dirige e qui il giocatore non c'è. Questa non è una scorciatoia
			# inventata per la prova: è la strada che fa il gioco quando
			# assumi qualcuno, ed è l'unica che produce una macchina
			# posteggiata **con l'autista che poi se ne va a fare la spesa**,
			# cioè esattamente lo stato che il furto deve trovare.
			if st == CarScript.State.WAITING and c.has_method(
					"parcheggiata_dal_guaglione"):
				c.parcheggiata_dal_guaglione("")
			if st == CarScript.State.PARKED:
				mai_posteggiate[rid] = true
			if c.puoi_arrubba():
				mo += 1
				viste[rid] = float(viste.get(rid, 0.0)) + d
		quante_max = maxi(quante_max, mo)
	Engine.time_scale = 1.0

	print("  %.0f secunne 'e piazza vera" % tempo)
	var nomme_stato := ["ARRIVA", "ASPETTA", "REGIA", "POSTEGGIATA", "SE NE VA",
		"RUBATA"]
	var righe: Array = []
	for k in stati:
		var i: int = int(k)
		righe.append("%s %.0fs" % [nomme_stato[i] if i < nomme_stato.size()
			else str(i), float(stati[k])])
	print("  machine viste 'n tutto:                %d" % viste_mai.size())
	print("  tiempo passato p''e stati:            %s" % "   ".join(righe))
	print("  machine ca so' state posteggiate:     %d" % mai_posteggiate.size())
	print("  machine ca s'hann' potute arrubbà:    %d" % viste.size())
	print("  'o massimo tutte 'nzieme:             %d" % quante_max)
	var totale: float = 0.0
	var cchiu_longa: float = 0.0
	for k in viste:
		totale += float(viste[k])
		cchiu_longa = maxf(cchiu_longa, float(viste[k]))
	if not viste.is_empty():
		print("  finestra media %.1fs, 'a cchiù longa %.1fs"
			% [totale / float(viste.size()), cchiu_longa])

	if mai_posteggiate.is_empty():
		male("dint'a %.0f secunne nun s'è posteggiata manco 'na machina: "
			% tempo + "'a prova nun sta guardanno 'a piazza")
		return
	# **Zero è 'a risposta ca ha fatto campà 'o bug pe' sei versione.**
	if viste.is_empty():
		male("dint'a %.0f secunne nun s'è potuta arrubbà manco 'na machina: "
			% tempo + "'o furto sta scritto ma nun se pò fa'")
		return
	if float(viste.size()) < float(mai_posteggiate.size()) * 0.25:
		male("sulo %d machine ncopp'a %d se so' potute arrubbà: 'a finestra è troppo stretta"
			% [viste.size(), mai_posteggiate.size()])
	elif cchiu_longa < 8.0:
		male("'a finestra cchiù longa è %.1fs: nun ce sta 'o tiempo 'e scassà"
			% cchiu_longa)
	else:
		bbuono("%d machine ncopp'a %d se so' potute arrubbà, 'a finestra cchiù longa %.1fs"
			% [viste.size(), mai_posteggiate.size(), cchiu_longa])


## Quanti secondi il cursore resta dentro alla finestra a ogni passaggio.
## È il solo numero che sente chi gioca.
func _utile(d: Dictionary) -> float:
	return float(d["zona"]) / float(d["vel"])


func _machina_finta() -> Node:
	var c: Node = CarScript.new()
	get_tree().root.add_child(c)
	# **Doppo `add_child`, no primma**: `_ready()` si pesca un tipo a sorte,
	# e scrivendolo prima me lo cancellava — la prima prova diceva "berlina"
	# e il prompt rispondeva "economica". È la stessa famiglia del
	# `global_position` da scrivere dopo l'`add_child`.
	c.set("car_type", "berlina")
	c.set("state", CarScript.State.PARKED)
	return c
