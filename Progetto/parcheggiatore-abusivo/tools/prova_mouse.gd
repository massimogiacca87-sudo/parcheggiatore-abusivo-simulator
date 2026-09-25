extends Node
## **'O mouse ncopp'ô browser** (0.56b).
##
## Il capo, dopo aver caricato la build su itch.io: *«quando carico il gioco
## su itch.io ed è giocabile da browser, non funziona il mouse»*.
##
## Il guasto non è nel gioco, è nel patto col browser: per girare la testa
## col mouse serve il **Pointer Lock**, e il Pointer Lock si concede
## **soltanto dentro a un gesto dell'utente**. La richiesta stava dentro a
## `player_fps._ready()`, cioè mentre la scena si costruisce: su Windows
## funziona, sul web viene rifiutata **in silenzio** — nessun errore, niente
## in console — e nessuno riprovava mai più.
##
## ## Che cosa si può provare davvero, e che cosa no
##
## Questa è la prova più scomoda del banco, e vale la pena dire perché:
## **il browser qui non c'è**. Girando headless non esiste nessun Pointer
## Lock da concedere o da rifiutare, quindi «il mouse funziona su itch.io»
## non è una cosa che questa prova possa dire. Sarebbe disonesto far finta
## di sì.
##
## Quello che si può provare è **la struttura che rende la cura possibile**,
## e sono tre cose, tutte e tre necessarie:
##
## 1. **Ce sta 'na porta sola.** Il modo del mouse lo cambiavano ventidue
##    punti diversi. Con ventidue padroni non esiste un posto in cui sapere
##    *che cosa vuole il gioco adesso*, e senza quello non si può riprovare
##    senza rubare il mouse a chi sta comprando le sigarette. Qui si legge
##    il sorgente e si verifica che **nessuno scavalchi** `piglia_o_mouse`.
##    È il controllo che fa più lavoro di tutti, perché è quello che tiene
##    la cura in piedi il mese prossimo.
## 2. **'O desiderio è separato d''a cuncessione.** `vò_o_mouse` dice cosa
##    vuole il gioco; `Input.get_mouse_mode()` dice cosa c'è davvero.
##    Confonderli è tutto il bug.
## 3. **'A primma presa sta dint'a 'nu gesto.** Il click su «Accummenciamo»
##    e il tasto che chiude la schermata iniziale: sono i due soli momenti
##    in cui il browser dice di sì, e devono essere loro a chiedere.

var storte: int = 0


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame

	_prova_a_porta()
	_prova_o_desiderio()
	_prova_o_gesto()

	print("=== storte: %d ===" % storte)
	get_tree().quit()


# ---------------------------------------------------------------------------
# 1. 'A porta sola
# ---------------------------------------------------------------------------

## I due modi di scrivere la stessa cosa in GDScript. Tutti e due vanno
## cercati: cambiare solo il primo lascia in giro il secondo, ed è
## esattamente così che questi ventidue punti erano diventati ventidue.
const SCAVALCA := ["Input.set_mouse_mode(", "Input.mouse_mode ="]
## L'unico file a cui è permesso: è lui la porta.
const PADRONE := "res://scripts/autoload/game_manager.gd"


func _prova_a_porta() -> void:
	print("=== 'A PORTA SOLA ===")
	var file: Array = _tutte_e_scritte("res://scripts")
	print("  %d file 'e codice" % file.size())
	if file.size() < 40:
		male("s'hanno truvato sulo %d file: 'a prova nun sta guardanno niente"
			% file.size())
	var fore := 0
	var quante := 0
	for f in file:
		var t := FileAccess.get_file_as_string(f)
		if t == "":
			continue
		for riga_n in t.split("\n").size():
			var riga: String = t.split("\n")[riga_n]
			# I commenti non contano: questa prova legge il codice, e nelle
			# note di questa versione la riga vecchia sta scritta apposta
			# per spiegare che cos'era.
			var pulita: String = riga.strip_edges()
			if pulita.begins_with("#"):
				continue
			for s in SCAVALCA:
				if not riga.contains(s):
					continue
				quante += 1
				if f == PADRONE:
					continue
				fore += 1
				male("%s scavalca 'a porta: «%s»" % [f, pulita])
	print("  %d chiammate, %d fore d''a porta" % [quante, fore])
	if quante == 0:
		male("nun s'è truvata manco 'na chiammata: 'a prova s'è scurdata comme se scrive")

	# E la porta dev'esserci davvero.
	for nomme in ["piglia_o_mouse", "arripiglia_o_mouse",
			"o_mouse_s_ha_da_piglià"]:
		if not GameManager.has_method(nomme):
			male("'o GameManager nun tene 'o metodo %s()" % nomme)
	print("  'e tre porte ce stanno")


func _tutte_e_scritte(cartella: String) -> Array:
	var fore: Array = []
	var d := DirAccess.open(cartella)
	if d == null:
		return fore
	d.list_dir_begin()
	var n: String = d.get_next()
	while n != "":
		if d.current_is_dir():
			if not n.begins_with("."):
				fore.append_array(_tutte_e_scritte(cartella + "/" + n))
		elif n.ends_with(".gd") and not n.begins_with("_"):
			# **'E copie d''o banco 'e prova nun so' gioco.** `/tmp/prova.sh`
			# copia questa stessa prova dentro a `scripts/_prova_mouse.gd`
			# per farla girare come autoload: senza questa riga la prova si
			# trova addosso le proprie parole e si denuncia da sola.
			fore.append(cartella + "/" + n)
		n = d.get_next()
	d.list_dir_end()
	return fore


# ---------------------------------------------------------------------------
# 2. 'O desiderio, separato d''a cuncessione
# ---------------------------------------------------------------------------

func _prova_o_desiderio() -> void:
	print("=== 'O DESIDERIO ===")
	GameManager.piglia_o_mouse(true)
	if not GameManager.vò_o_mouse:
		male("doppo ca ll'hê chiesto, 'o gioco nun se ricorda ca 'o vò")
	GameManager.piglia_o_mouse(false)
	if GameManager.vò_o_mouse:
		male("doppo ca ll'hê lassato, 'o gioco penza ancora ca 'o vò")
	print("  'o desiderio se ricorda")

	# **Si 'o gioco 'o vò libbero, 'nu click nun s'ha da piglià niente.** È
	# la metà della cura che nessuno guarda e che rompe tutto: senza questo,
	# il primo click dentro al negozio si riprende il mouse e il listino
	# diventa impossibile da usare.
	GameManager.piglia_o_mouse(false)
	if GameManager.o_mouse_s_ha_da_piglià():
		male("cu 'o mouse libbero 'o gioco 'o vò ancora pigliato")
	if GameManager.arripiglia_o_mouse():
		male("'nu click s'è pigliato 'o mouse mentre 'nu pannello steva apierto")
	print("  cu 'o pannello apierto 'o click nun se piglia niente")

	# E quando il gioco lo vuole e ce l'ha, non c'è niente da riprendere.
	GameManager.piglia_o_mouse(true)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if GameManager.o_mouse_s_ha_da_piglià():
			male("'o tene e dice ca ll'ha da piglià")
		if GameManager.arripiglia_o_mouse():
			male("s'è ripigliato 'nu mouse ca teneva già")
		print("  quanno 'o tene, nun 'o ripiglia")
	else:
		# Headless non ha un mouse da prendere: qui la condizione «lo vuole
		# e non ce l'ha» è vera, ed è giusto che lo sia — è la stessa
		# situazione del browser che ha detto di no.
		if not GameManager.o_mouse_s_ha_da_piglià():
			male("nun ce sta 'o mouse ma 'o gioco dice ca sta appost'accussì")
		print("  ccà nun ce sta 'nu mouse overo (headless): 'a cundizione"
			+ " «'o vò e nun ce ll'ha» è vera, comm'â jastemma d''o browser")
	GameManager.piglia_o_mouse(false)


# ---------------------------------------------------------------------------
# 3. 'A primma presa sta dint'a 'nu gesto
# ---------------------------------------------------------------------------
#
# Questo si legge nel sorgente e non si può fare altrimenti: «dentro a un
# gesto dell'utente» è una proprietà di *dove sta scritta* la chiamata, non
# di che cosa fa. Un `piglia_o_mouse(true)` dentro a `_ready()` e uno dentro
# all'handler di un bottone sono la stessa riga e due cose opposte.

func _prova_o_gesto() -> void:
	print("=== 'O GESTO ===")
	var casi := [
		["res://scripts/caricamento.gd", "_on_menu_gioca",
			"'o click ncopp'a «Accummenciamo»"],
		["res://scripts/intro_screen.gd", "_close",
			"'o tasto ca chiude 'a schermata"],
	]
	for c in casi:
		var t := FileAccess.get_file_as_string(str(c[0]))
		var i: int = t.find("func %s(" % str(c[1]))
		if i < 0:
			male("nun trovo %s() dint'a %s" % [str(c[1]), str(c[0])])
			continue
		# Dalla firma alla prossima funzione: il corpo.
		var j: int = t.find("\nfunc ", i + 1)
		var corpo: String = t.substr(i, (j - i) if j > i else -1)
		var ce_sta: bool = corpo.contains("piglia_o_mouse(true)")
		print("  %-34s %s" % [str(c[2]), "chiede 'o mouse" if ce_sta
			else "NUN 'O CHIEDE"])
		if not ce_sta:
			male("%s nun se piglia 'o mouse: ncopp'ô browser resta muorto"
				% str(c[2]))

	# E il giocatore, se il mouse se lo perde, dev'essere avvisato: un
	# rimedio che nessuno sa di avere non è un rimedio.
	var hud := FileAccess.get_file_as_string("res://scripts/hud.gd")
	if not hud.contains("o_mouse_s_ha_da_piglià()"):
		male("ll'interfaccia nun dice maje ca 'o mouse s'è perzo")
	else:
		print("  ll'interfaccia 'o ddice a chi joca")
	# E il click che lo riprende dev'essere agganciato da qualche parte.
	var pl := FileAccess.get_file_as_string("res://scripts/player_fps.gd")
	if not pl.contains("arripiglia_o_mouse()"):
		male("nisciuno ripiglia 'o mouse ncopp'ô click")
	else:
		print("  'o click 'o ripiglia")
