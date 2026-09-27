extends CanvasLayer
## 'O tutoriale — 'na pagina sola, dduje purtune
##
## **Pecché sta 'a sulo (0.52).**
##
## Il capo: *"aggiungi un tutorial schematico e semplice, sintetico e
## dritto al punto… basta premere ESC e nel menu si può accedere a questo
## tutorial scritto su sfondo leggibile"*.
##
## Il tutorial c'era già — rifatto alla 0.50, schematico, su schermo nero —
## ma **stava dentro alla schermata di caricamento**, e quella si vede una
## volta sola all'avvio. Chi si dimentica un comando a metà partita non
## poteva tornarci.
##
## La cosa giusta non era scriverne un secondo. Due tutorial sono due cose
## che divergono: si aggiunge una meccanica, si aggiorna quello del menu e
## ci si dimentica dell'altro, e da lì in poi il gioco spiega due giochi
## diversi. Quindi le pagine stanno **qui**, in un posto solo, e chi le
## vuole se le prende:
##
##   * `caricamento.gd` per la porta del menu iniziale;
##   * `hud.gd` per la porta della pausa (Esc → *Comme se joca*).
##
## Questa classe è insieme **il testo e il pannello**: si istanzia, si
## chiama `apri()`, e si chiude da sola con Esc.
##
## Sulla forma non si tocca niente di quello che la 0.50 aveva sistemato:
## fondo nero pieno (non un velo su una fotografia), una colonna sola,
## corpo grande, e ogni riga è una coppia — a sinistra il tasto o la cosa,
## a destra cosa fa. Chi legge non deve seguire un discorso: deve poter
## saltare alla riga che gli serve. In italiano, perché il napoletano sta
## nel gioco e non nelle istruzioni.

const ORO := Color(0.92, 0.74, 0.30)
const CREMA := Color(0.95, 0.93, 0.88)
const SPENTO := Color(0.72, 0.68, 0.66)


## Le pagine. Chiunque le voglia disegnare a modo suo se le legge da qui.
const PAGINE := [
	{
		"titolo": "IL MESTIERE",
		"sopra": "Sei un parcheggiatore abusivo. Nessuno ti ha dato quel posto: te lo sei preso.",
		"righe": [
			["E", "Ferma l'auto che arriva e comincia a dirigerla."],
			["W · A · D", "Mentre dirigi: avanti, gira a sinistra, gira a destra."],
			["S", "Fermati lì."],
			["E", "Quando l'autista scende, avvicinati e chiedi i soldi."],
			["Dentro le strisce", "paga di più e non fa arrabbiare nessuno."],
			["Fuori dalle strisce", "è più veloce, ma arriva la multa e il cliente se la prende con te."],
		],
		"chiusa": "Ogni auto sono 3–12 euro. La sera te ne servono molti di più.",
	},
	{
		"titolo": "LE ORE DEL GIORNO",
		"sopra": "La giornata va da mezzogiorno alle quattro di notte, e non è tutta uguale. L'ora sta in alto a destra, sotto l'orologio.",
		"righe": [
			["La controra (12–15)", "La gente mangia. Arriva poca roba."],
			["Le tre morte (15–18)", "Non passa nessuno e le mance sono magre. È l'ora della bacheca."],
			["L'aperitivo (18–21)", "Scende tutti insieme. Stai in piazza."],
			["I ristoranti (21–24)", "L'ora buona: tante auto e mance alte. Non muoverti."],
			["La nottata (00–04)", "Poche auto, ma chi scende ha bevuto e lascia il doppio."],
			["Il biglietto", "Ogni mattina, sulla porta di casa: dice che giornata sarà."],
		],
		"chiusa": "Quando la piazza è vuota conviene fare i lavoretti. Quando rende, conviene restare.",
	},
	{
		"titolo": "CHI TI GUARDA",
		"sopra": "Due autorità diverse, e non vanno confuse.",
		"righe": [
			["IL VIGILE", "Fa il suo turno. Guarda le auto, non te — finché non esageri."],
			["Sospetto", "La barra in alto a sinistra. Sale se rubi, se strattoni, se litighi."],
			["Barra a metà", "Ti viene a parlare. Rispondi \"non è per me, è per i figli\": ti lascia stare."],
			["Barra piena", "Verbale: 50 euro. Se non li hai, si prende la roba."],
			["I CARABINIERI", "Arrivano solo per la violenza. Due o tre pestaggi in un minuto e ti cercano."],
			["Le stelle", "In alto a destra. Finché ci sono, ti stanno addosso. Scappa nei vicoli."],
			["Se ti afferrano", "Clicca a ripetizione per scioglierti. Ma al TERZO fermo della giornata non ti sciogli più: la notte la passi dentro."],
			["LE OSSA", "Non si rimettono da sole. Quello che perdi te lo devi ricomprare."],
			["Il cornetto", "Alla cornetteria, SOLO di notte: 5 euro e torni in piedi davvero."],
		],
		"chiusa": "Il caffè al bar e la sigaretta abbassano il sospetto. Anche stare fermi.",
	},
	{
		"titolo": "QUANDO TORNANO A PRENDERE L'AUTO",
		"sopra": "Se trovano una multa, lo stemma sparito o una riga sulla fiancata, ti vengono a cercare.",
		"righe": [
			["Ti cerca", "Gira per la piazza chiamandoti. Non ti insegue per la città: sta lì e poco fuori."],
			["Se non ti trova", "Dopo mezzo minuto se ne va, e la cosa finisce lì."],
			["Se ti trova", "Si apre il dialogo, e hai quattro risposte."],
			["Pagare i danni", "Costa 5 o 10 euro, ma il quartiere se lo ricorda in bene."],
			["Negare", "Metà delle volte se la beve, metà si arrabbia e si mena."],
			["Se ti aveva pagato", "Negare quasi non funziona: gli avevi detto che stavi guardando."],
		],
		"chiusa": "Nascondersi funziona. Ma mentre ti nascondi la piazza lavora senza di te.",
	},
	{
		"titolo": "LA GENTE CHE TI CONOSCE",
		"sopra": "Una macchina su tre porta uno del quartiere, con nome e faccia. E si ricorda.",
		"righe": [
			["Il nome", "Te lo dice il prompt sopra la E, e ti saluta lui per primo."],
			["Come ti tratta", "Dipende da come l'hai trattato tu, e resta così anche domani."],
			["Se lo tratti bene", "Paga quasi sempre e lascia di più. Diventa uno di casa."],
			["Se gli fai il danno", "Riga o stemma: due volte e non ti dà più niente."],
			["Farsi pagare a pugni", "Funziona una volta. Tre e quello ti odia per sempre."],
			["Il quartiere parla", "Quello che fai a uno lo sanno tutti: le mance salgono o scendono per chiunque."],
			["IL VICINATO", "Quattro persone ferme sempre allo stesso angolo. Non parlano: FANNO."],
			["Cosa vogliono", "Un caffè, una sigaretta, il pane, un gelato. Poca roba, una volta al giorno."],
			["Nunzia", "Il caffè: sospetto giù e ossa su, come al banco del bar."],
			["Totore", "Ti apre il portone: quaranta secondi in cui nessuno ti vede, e le stelle si sciolgono."],
			["Rosa", "La frittata nel panaro. L'unica cosa che cura di giorno, una volta al giorno."],
			["Mimmo", "Sa dove sta oggi 'A SIGNORA. Ed è l'unica notizia che vale."],
			["'A SIGNORA", "Cambia posto ogni giorno. Ti dà cinque numeri del lotto e se ne sta zitta."],
			["Una volta su venti", "Sono quelli veri dell'estrazione di stasera. Non si capisce quale volta."],
		],
		"chiusa": "Al vicino che ti vuole bene non paghi niente. La notte dormono: resta solo Totore.",
	},
	{
		"titolo": "LE PIAZZE E I GUAGLIUNI",
		"sopra": "Le quattro piazze non sono la stessa piazza quattro volte.",
		"righe": [
			["La tua", "Né la più ricca né la più facile. Un vigile."],
			["Il mercato", "Rende poco: chi fa la spesa conta le monete. Ma NON ci sale mai un vigile."],
			["Lo stadio", "Ci si fanno i soldi veri. E ci girano DUE vigili."],
			["La cornetteria", "Di giorno è un deserto. Di notte è il posto migliore della città."],
			["Chi te la vende", "Te lo dice, prima che paghi. Ascoltalo."],
			["IL BOSS", "Appena prendi una piazza, quella sera ti aspetta là chi la teneva prima."],
			["Ha fretta", "Se non ci vai entro la nottata, se la riprende. Con dentro il tuo guaglione."],
			["I guagliuni", "Uno che sta con te da due settimane rende di più e si tiene il 21% invece del 30%."],
			["Passaci", "Ritirare la cassa è l'unica volta in cui ci parli. Chi non ti vede mai se ne va da un rivale."],
		],
		"chiusa": "Una piazza è tua quando te la sei tenuta, non quando l'hai pagata.",
	},
	{
		"titolo": "LA CITTÀ",
		"sopra": "Fuori dalla tua piazza c'è il resto del quartiere, e serve.",
		"righe": [
			["La bacheca", "In ogni piazza. È lì che si prendono i lavoretti della giornata."],
			["Il garage", "Sul lato della piazza. È dove si consegna quello che hai preso in bacheca."],
			["Il guaglione", "25 euro e posteggia lui al posto tuo. La sera passi a ritirare."],
			["Le altre piazze", "Si comprano dal parcheggiatore che c'è, oppure si prendono a mani nude."],
			["I negozi", "Il Bazar e 'o Zio vendono roba che serve, non souvenir."],
			["M", "La mappa. Ci sono sopra i lavori, i vecchi della scopa e i tuoi guagliuni."],
		],
		"chiusa": "Ci sono anche sei manifesti nascosti. Stanno sempre dietro a qualcosa.",
	},
	{
		"titolo": "FACCE NOVE E REGOLE NOVE",
		"sopra": "Dalla 0.61 il quartiere ti viene incontro. E ti guarda.",
		"righe": [
			["Gennarino 'o Nuovo", "Berretto rosso: posteggia nelle TUE piazze e si tiene i soldi. Parlaci."],
			["Con lui", "Lo cacci, ti fai dare la metà, oppure lo assumi gratis come guaglione."],
			["Il turista", "Cartina al contrario. Portalo alla colonna gialla entro tre minuti: mancia vera."],
			["Il panaro", "Donna Filumena lo cala due volte al giorno: vuole sigarette o un caffè."],
			["Chi ti vede", "Rubare in mezzo alla gente costa fino al doppio. In un vicolo vuoto, meno."],
			["Il garage", "Tre macchine al giorno, e sempre meno pagate. Il posteggio resta il mestiere."],
			["La sera", "Alle nove ti si ricorda chi dei tuoi guagliuni ha soldi in mano."],
		],
		"chiusa": "Col fierro in mano lo vedi, e vedi il colpo: la crocetta dice che hai preso.",
	},
	{
		"titolo": "IL RE E LE STRISCE BLU",
		"sopra": "Dalla 0.64: uno che ti mette alla prova, e il Comune che ti ruba la piazza.",
		"righe": [
			["'O Rre d''e Parcheggi", "Dal terzo giorno, in una piazza tua: corona, mantello rosso, paletta. Ti sfida."],
			["[E] accetti", "Un minuto, le macchine le chiama lui e arrivano di corsa. Contano solo quelle DENTRO a un posto."],
			["5 o più", "Ti regala una piazza (o 450 euro, se le hai già tutte)."],
			["3 o 4", "Ti dà un guaglione che lavora per te (o 60 euro)."],
			["1 o nessuna", "Ti corre dietro e ti mena. Non ti manda all'ospedale, ma fa male."],
			["Le strisce blu", "Certe mattine il Comune le pitta in una piazza tua, coi parchimetri."],
			["Finché c'è un parchimetro", "Il cliente paga la macchinetta e a te niente. Sfasciali: pugni o ferro."],
			["Le strisce restano blu", "Il cliente fa come se l'avessi messo fuori dalle strisce. Pittura e pennello al Bazar, [E] accanto al posto."],
		],
		"chiusa": "La piazza torna tua quando i parchimetri sono tutti a terra e le strisce tutte bianche.",
	},
	{
		"titolo": "DOVE SI PERDONO I SOLDI",
		"sopra": "Ogni piazza ha il bar e il tabaccaio. In giro ci sono le sale e i tavolini.",
		"righe": [
			["Il bar", "Caffè: toglie sospetto e rimette in forza. La mattina anche la colazione."],
			["La cornetteria", "Solo di notte. Il cornetto black and white è l'unica cosa che ti rimette in piedi."],
			["Il tabaccaio", "Sigarette, e il LOTTO: dieci ruote, si gioca da 1 a 5 numeri."],
			["L'estrazione", "Una al giorno, la sera. La giocata di oggi si vede domani."],
			["La sala scommesse", "Slot, e le partite virtuali: 90 minuti in dieci secondi."],
			["Le tre carte", "Il tavolino con la cassetta. Non si vince, ma provaci."],
			["La scopa", "Cinque vecchi in giro per la città, uno più forte dell'altro."],
		],
		"chiusa": "Il banco vince sempre. Sapere quanto vince è l'unica difesa.",
	},
	{
		"titolo": "LA CASA",
		"sopra": "Alle quattro si smette. Poi si torna a casa, e lì comincia il conto.",
		"righe": [
			["Il vascio", "Nel vicolo dietro la piazza, numero 27, quello con i panni stesi."],
			["Il conto", "Ogni sera c'è una cifra da consegnare. Sta scritta in alto a destra."],
			["Se non paghi", "Il debito cresce del 12% al giorno, e prima o poi succede qualcosa."],
			["Se torni tardi", "Dopo l'una tua moglie vuole qualcosa per sé, e la scusa la trova."],
			["Il letto", "È l'unico modo di arrivare a domani."],
			["Il biglietto", "Sulla porta, ogni mattina: che giornata è, e cosa conviene fare."],
		],
		"chiusa": "Chi cammina, mangia.",
	},
	{
		"titolo": "I COMANDI",
		"sopra": "",
		"righe": [
			["W A S D", "Cammina"],
			["Mouse", "Guarda"],
			["Shift", "Corri"],
			["Spazio", "Salta e ti arrampichi"],
			["C", "Ti accovacci"],
			["E", "Interagisci: dirigi, ti fai pagare, parli, apri"],
			["F", "Ferma l'auto · danneggia · accusa chi bara"],
			["Clic sinistro", "Pugno"],
			["Rotella", "Cambia quello che hai in mano"],
			["I", "Zaino    ·    M  Mappa    ·    X  Sigaretta    ·    R  Caffè"],
			["Esc", "Pausa, salva, carica — e questo tutorial"],
		],
		"chiusa": "",
	},
	# **'E credite** (0.62). Le Vespe della biblioteca esterna, il graffito
	# e i suoni dell'interfaccia hanno licenze CC BY: vanno citati dentro al
	# gioco, non solo in un file accanto. L'elenco intero sta in CREDITI.txt.
	{
		"titolo": "CHI HA FATTO 'O JOCO",
		"sopra": "Ideato da Massimo Giacca, costruito con Claude (Anthropic) in Godot 4.3.",
		"righe": [
			["Vespa", "Jasmine Roberts — CC BY 3.0 (poly.pizza)"],
			["Scooter", "Poly by Google — CC BY 3.0 (poly.pizza)"],
			["Low poly scooter", "Thomas Saint Pierre (s1pierro) — CC BY 3.0 (poly.pizza)"],
			["Graffiti", "karlwirbelwind — CC BY 4.0 (zenodo.org)"],
			["Suoni dell'interfaccia", "Universal UI Soundpack, Nathan Gibson — CC BY 4.0"],
			["Persone, arredo, auto", "Quaternius e autori di Poly Pizza — CC0"],
			["Asfalto, intonaco, decalcomanie", "Poly Haven, ambientCG — CC0"],
			["Suoni di strada", "Freesound — CC0 · icone Kenney — CC0"],
			["Filtri dello schermo", "godotshaders.com: Ructoon, mujtaba-io, hailyn, blblblblb, shadecore_dev — CC0"],
		],
		"chiusa": "Caratteri: Poppins (SIL OFL) e DejaVu Sans. Tutto l'elenco sta in CREDITI.txt.",
	},
]


var _pagina: int = 0
var _radice: Control
var _quando_chiude: Callable = Callable()


func _ready() -> void:
	# Sopra a tutto quello che c'è in giro (l'HUD sta più in basso) e vivo
	# anche a gioco in pausa: si apre proprio dal menu di pausa.
	layer = 240
	process_mode = Node.PROCESS_MODE_ALWAYS
	_costruisci()
	visible = false


func _costruisci() -> void:
	_radice = Control.new()
	_radice.set_anchors_preset(Control.PRESET_FULL_RECT)
	# **'O fondo è nìvero chino, no 'nu velo.** È la lezione della 0.50: il
	# testo sopra a un'immagine non si legge, e un velo semitrasparente
	# lascia passare abbastanza da rovinare tutto lo stesso.
	var fondo := ColorRect.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.04, 0.035, 0.04, 0.985)
	_radice.add_child(fondo)
	add_child(_radice)


## `chiudendo` è quello che si chiama quando il tutorial si chiude: serve
## al menu di pausa per tornare a farsi vedere.
func apri(chiudendo: Callable = Callable()) -> void:
	_quando_chiude = chiudendo
	_pagina = 0
	visible = true
	get_tree().paused = true
	GameManager.piglia_o_mouse(false)
	_disegna()


func chiudi() -> void:
	visible = false
	if _quando_chiude.is_valid():
		_quando_chiude.call()
	else:
		get_tree().paused = false
		GameManager.piglia_o_mouse(true)
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		chiudi()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_vai(1)
	elif event.is_action_pressed("ui_left"):
		get_viewport().set_input_as_handled()
		_vai(-1)


func _vai(passo: int) -> void:
	var n: int = _pagina + passo
	if n < 0:
		return
	if n >= PAGINE.size():
		chiudi()
		return
	_pagina = n
	_disegna()


func _disegna() -> void:
	# **`queue_free()` è differito**: il nodo resta disegnato fino alla fine
	# del fotogramma. Con due pagine di testo sovrapposte non si legge
	# niente — è il difetto che la 0.50 ha trovato nel tutorial vecchio, e
	# non c'è motivo di rifarlo qui.
	for c in _radice.get_children():
		if c.name == "Pagina":
			_radice.remove_child(c)
			c.queue_free()

	var dati: Dictionary = PAGINE[_pagina]
	var pagina := Control.new()
	pagina.name = "Pagina"
	pagina.set_anchors_preset(Control.PRESET_FULL_RECT)
	_radice.add_child(pagina)

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 80
	col.offset_right = -80
	col.offset_top = 44
	col.offset_bottom = -70
	col.add_theme_constant_override("separation", 11)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pagina.add_child(col)

	col.add_child(_scritta("%d / %d   ·   %s" % [_pagina + 1, PAGINE.size(),
		str(dati["titolo"])], 26, ORO))

	var sopra := str(dati.get("sopra", ""))
	if sopra != "":
		var sl := _scritta(sopra, 16, CREMA)
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sl.custom_minimum_size = Vector2(0, 22)
		sl.modulate.a = 0.82
		col.add_child(sl)

	# Due colonne allineate, non due colonne di prosa: si scorre con
	# l'occhio e si salta alla riga che serve.
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 26)
	g.add_theme_constant_override("v_separation", 10)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(g)
	for r in dati["righe"]:
		var k := _scritta(str(r[0]), 17, ORO, HORIZONTAL_ALIGNMENT_RIGHT)
		k.custom_minimum_size = Vector2(240, 0)
		g.add_child(k)
		# **'A colonna 'e destra va allineata a manca.** Centrata, ogni riga
		# comincia in un punto diverso e l'occhio deve ricominciare da capo
		# ogni volta: e' proprio la fatica che un tutorial schematico deve
		# togliere.
		var d := _scritta(str(r[1]), 17, CREMA, HORIZONTAL_ALIGNMENT_LEFT)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(d)

	var chiusa := str(dati.get("chiusa", ""))
	if chiusa != "":
		var cl := _scritta(chiusa, 16, ORO)
		cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cl.modulate.a = 0.88
		col.add_child(cl)

	# In fondo: dove sto, come si gira, come si esce.
	var pie := _scritta(
		"◀ ▶  pe' girà 'e ppagine        ·        [Esc] pe' chiudere",
		14, SPENTO)
	pie.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	pie.offset_top = -46
	pie.offset_bottom = -22
	pagina.add_child(pie)

	# I due bottoni veri, per chi sta col mouse in mano: il menu di pausa
	# si usa col mouse, e uno che arriva da lì cerca un bottone.
	if _pagina > 0:
		_bottone(pagina, "◀ arreto", -220.0, func(): _vai(-1))
	_bottone(pagina, ("avanti ▶" if _pagina < PAGINE.size() - 1 else "chiude"),
		120.0, func(): _vai(1))


func _bottone(dove: Control, testo: String, x: float, che: Callable) -> void:
	var b := Button.new()
	b.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	b.position = Vector2(x, -92)
	b.size = Vector2(100, 30)
	b.text = testo
	b.pressed.connect(che)
	dove.add_child(b)


func _scritta(testo: String, corpo: int, colore: Color,
		allinea: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = testo
	l.horizontal_alignment = allinea
	l.add_theme_font_size_override("font_size", corpo)
	l.add_theme_color_override("font_color", colore)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
