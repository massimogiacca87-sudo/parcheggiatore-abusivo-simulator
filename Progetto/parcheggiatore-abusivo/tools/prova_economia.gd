extends Node
## Collaudo dell'economia di casa: trenta giornate simulate, per rispondere
## a una domanda sola — **se uno lavora bene, ce la fa?**
##
## Si installa come autoload temporaneo (come `_audit.gd`) e si lancia il
## gioco in headless. Non si puo' usare `--script`: li' gli autoload non
## esistono, e questo codice ha bisogno del GameManager vero — provare una
## copia dei numeri invece dei numeri veri non prova niente.

var storte: int = 0


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func _ready() -> void:
	seed(7)
	await get_tree().process_frame
	print("=== 'O CUNTO 'E CASA — 30 juorne ===")
	for reso in [55, 75, 95, 120]:
		_simula(reso, 30)
	print("")
	_prova_e_paghe()
	print("=== storte: %d ===" % storte)
	get_tree().quit()


func _simula(guadagno_medio: int, giorni: int) -> void:
	var gm := GameManager
	gm.money = 0
	gm.giornata = 1
	gm.umore_moglie = 62.0
	gm.spese_aperte = []
	var scoperti := 0
	var giorni_scoperti := 0
	var primo_gruzzolo := -1
	var speso := 0
	var picco := 0
	for g in range(giorni):
		gm.prepara_giornata()
		var dovuto: int = gm.spese_dovute()
		picco = maxi(picco, dovuto)
		speso += dovuto
		var entrata: int = int(round(float(guadagno_medio)
			* randf_range(0.72, 1.28)))
		gm.money += entrata
		gm.consegna_a_moglie(mini(gm.money, dovuto))
		var resta: int = gm.spese_dovute()
		if resta > 0:
			scoperti += resta
			giorni_scoperti += 1
		if primo_gruzzolo < 0 and gm.money >= 450:
			primo_gruzzolo = g + 1
		gm.giornata += 1
	print("€%d 'o juorno →  in sacca €%d dopo %d juorne · scuperto %d juorne (€%d) · 'a primma piazza 'o juorno %s · umore %d · cunto cchiu' auto €%d" % [
		guadagno_medio, gm.money, giorni, giorni_scoperti, scoperti,
		("%d" % primo_gruzzolo) if primo_gruzzolo > 0 else "maje",
		int(gm.umore_moglie), picco])
	print("   spese in tutto €%d, cioe' €%d 'o juorno"
		% [speso, int(round(float(speso) / float(giorni)))])


# ---------------------------------------------------------------------------
# CHE RENNE OGNE COSA CA T'ACCATTE (0.56, punto 10)
# ---------------------------------------------------------------------------
#
# Il capo: *«La maggior parte degli oggetti acquistabili ed equipaggiabili
# deve servire ad ottenere più soldi, altrimenti non servono poi a molto a
# livello di gameplay. Ri bilancia anche l'economia in base a questo.»*
#
# «Deve servire a ottenere più soldi» è una frase che si può controllare, e
# il modo di controllarla è uno solo: **in quanti giorni si ripaga?** Un
# oggetto che non si ripaga mai non è un oggetto, è un souvenir; uno che si
# ripaga in mezza giornata non è una scelta, è una tassa che hai pagato in
# ritardo.
#
# La finestra giusta sta in mezzo: **da uno a otto giorni**. Sotto il giorno
# comprarlo non è una decisione — lo compri e basta, e allora tanto valeva
# regalarlo; sopra gli otto, in un gioco dove una giornata dura sedici
# minuti, non lo vedi mai tornare indietro.
#
# I numeri della giornata tipo non sono inventati: ventidue clienti serviti
# è quello che viene fuori dalla simulazione qui sopra a settantacinque euro
# al giorno, e la mancia media è la media vera delle quattro `CAR_TYPES`.

const Car := preload("res://scripts/car_3d.gd")

## Una giornata di lavoro fatta bene.
const CLIENTI: int = 22
## Quante volte paga uno, senza niente addosso.
const PAGA_BASE: float = 0.55


func _mancia_media() -> float:
	var t := 0.0
	var n := 0
	for k in Car.CAR_TYPES:
		var c: Dictionary = Car.CAR_TYPES[k]
		t += (float(c["tip_min"]) + float(c["tip_max"])) * 0.5
		n += 1
	return t / float(maxi(1, n))


## Quanto rende una giornata con questi due numeri.
func _jurnata(paga: float, mancia: float) -> float:
	return float(CLIENTI) * clampf(paga, 0.1, 0.95) * mancia


func _prova_e_paghe() -> void:
	var gm := GameManager
	var mancia: float = _mancia_media()
	var base: float = _jurnata(PAGA_BASE, mancia)
	print("=== CHE RENNE CHELLO CA T'ACCATTE ===")
	print("  'na jurnata bbona: %d cliente, paga 'o %.0f%%, mancia media €%.1f"
		% [CLIENTI, PAGA_BASE * 100.0, mancia])
	print("  senza niente: €%.0f 'o juorno" % base)
	print("")
	print("  %-12s %-6s %-9s %-8s %s" % ["che cosa", "costa", "'o juorno",
		"se paga", "che fa"])

	# Ogni voce dice quanto muove la probabilità di pagamento e quanto
	# moltiplica la mancia. I numeri vengono dal gioco vero: si accende
	# l'oggetto, si chiede al GameManager, si spegne.
	var righe: Array = []
	for id in ["gilet", "occhiali", "borsello", "coppola"]:
		gm.upgrades = {}
		gm.placed_decor = []
		var p0: float = PAGA_BASE + gm.bonus_arnese()
		var m0: float = mancia * gm.mancia_arnese()
		gm.upgrades = {id: true}
		var paga: float = PAGA_BASE + gm.bonus_arnese()
		if id == "coppola":
			paga += 0.08   # sta dint'â machina, no dint'ô GameManager
		var man: float = mancia * gm.mancia_arnese()
		righe.append([id, int(gm.UPGRADES[id]["cost"]),
			_jurnata(paga, man) - _jurnata(p0, m0)])
	for id in ["piante", "ombrellone", "radio"]:
		gm.upgrades = {}
		gm.placed_decor = []
		var p0b: float = PAGA_BASE + gm.bonus_pagamento()
		var m0b: float = mancia * gm.bonus_mancia()
		gm.placed_decor = [{"id": id, "pos": [0, 0, 0], "rot": 0.0}]
		var pagab: float = PAGA_BASE + gm.bonus_pagamento()
		var manb: float = mancia * gm.bonus_mancia()
		var guadagno: float = _jurnata(pagab, manb) - _jurnata(p0b, m0b)
		if id == "radio":
			# La radio non tocca né paga né mancia: tiene il cliente in
			# piazza il 45% più a lungo, cioè non te lo fa perdere. Un
			# cliente perso ogni dieci è il conto onesto, e il 45% di
			# pazienza in più ne recupera più o meno la metà.
			guadagno = float(CLIENTI) * 0.05 * PAGA_BASE * mancia
		righe.append([id, int(gm.UPGRADES[id]["cost"]), guadagno])
	gm.upgrades = {}
	gm.placed_decor = []
	# La sedia non paga sui clienti: paga a stare seduto. Dieci minuti di
	# pausa in una giornata sono seicento secondi, ma seduto ci stai molto
	# meno: due minuti buoni, che è quanto ci vuole per far passare il
	# vigile.
	righe.append(["sedia", int(gm.UPGRADES["sedia"]["cost"]),
		gm.SEDIA_SPICCIO * 120.0])
	# E la regola che tiene in piedi la sedia: **assettarse ha da renne
	# meno che fatecà**. Se no il gioco migliore è non giocare.
	var ô_minuto_fatecanno: float = base / 16.0
	var ô_minuto_assettato: float = gm.SEDIA_SPICCIO * 60.0
	print("  (fatecanno €%.2f ô minuto, assettato €%.2f)"
		% [ô_minuto_fatecanno, ô_minuto_assettato])
	if ô_minuto_assettato >= ô_minuto_fatecanno * 0.7:
		male("assettato piglie €%.2f ô minuto e fatecanno €%.2f: cummene sta' fermo"
			% [ô_minuto_assettato, ô_minuto_fatecanno])
	# **'E luminarie fanno due cose 'nzieme**, ed è il motivo per cui
	# costano il doppio di tutto il resto: di notte le auto arrivano più
	# spesso (`LUMINARIE_ARRIVI` è un moltiplicatore dell'attesa, quindi i
	# clienti si moltiplicano per il suo inverso) **e** lasciano un quarto
	# in più. I due numeri si moltiplicano fra loro, non si sommano —
	# contarne uno solo faceva sembrare le luminarie un affare storto.
	var notte: float = (1.0 / gm.LUMINARIE_ARRIVI) * gm.LUMINARIE_MANCIA
	righe.append(["luminarie", int(gm.UPGRADES["luminarie"]["cost"]),
		float(CLIENTI) * 0.33 * PAGA_BASE * mancia * (notte - 1.0)])

	# **'E ttre ca nun toccano né 'a paga né 'a mancia**, e che quindi
	# vanno contate a mano: non rendono di più per cliente, ti fanno fare
	# **più clienti** (o ti risparmiano una spesa). Il conto è grossolano
	# apposta — meglio un numero onesto e approssimato che nessun numero.
	#
	# 'O fischietto: gli autisti reagiscono più svelti, quindi la manovra
	# finisce prima e il cliente dopo entra prima. Un cliente in più ogni
	# dodici è la stima buona.
	righe.append(["fischietto", int(gm.UPGRADES["fischietto"]["cost"]),
		float(CLIENTI) * 0.08 * PAGA_BASE * mancia])
	# 'A paletta: si dirige da nove metri invece che da tre, cioè non devi
	# più correre dietro a ogni macchina. Vale come il fischietto, un po'
	# di più — ma costa quarantacinque euro, e deve restare l'acquisto che
	# si fa quando la giornata gira già.
	righe.append(["paletta", int(gm.UPGRADES["paletta"]["cost"]),
		float(CLIENTI) * 0.12 * PAGA_BASE * mancia])
	# 'O tavolino non fa guadagnare: fa **non spendere**. Un caffè ogni
	# cinquanta secondi, gratis, e il caffè al bar costa quello che costa.
	# In sedici minuti di giornata sono diciannove caffè, ma di caffè uno
	# se ne beve quattro o cinque: si contano quelli.
	righe.append(["tavolino", int(gm.UPGRADES["tavolino"]["cost"]),
		5.0 * float(gm.CAFFE_COST)])

	for r in righe:
		var costo: float = float(r[1])
		var reso: float = float(r[2])
		var juorne: float = 9999.0 if reso <= 0.01 else costo / reso
		print("  %-12s €%-5d €%-8.1f %-8s %s" % [str(r[0]), int(costo), reso,
			("maje" if juorne > 900.0 else "%.1f juorne" % juorne),
			str(GameManager.UPGRADES[str(r[0])]["name"])])
		if reso <= 0.01:
			male("%s nun renne 'nu centesimo: è 'nu soprammobile" % str(r[0]))
		elif juorne > 8.0:
			male("%s se paga 'n %.0f juorne: nun 'o vede maje tornà"
				% [str(r[0]), juorne])
		elif juorne < 1.0:
			male("%s se paga 'n mezza jurnata: nun è 'na scelta, è 'nu regalo"
				% str(r[0]))
	gm.upgrades = {}
	gm.placed_decor = []
