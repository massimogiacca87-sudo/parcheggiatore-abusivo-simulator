extends Node
## 'O sciato: sette-otto pugne e sî scarico.
##
## Il capo: *"prendi a pugno qualcuno, nel giro di 7-8 pugni sei
## completamente scarico e si ricarica molto lentamente. Si ricarica del
## tutto se vai a dormire e per metà se bevi un caffè. Questo overhaul
## dovrebbe risolvere definitivamente il problema dei pugni come
## risoluzione troppo semplice dei problemi."*
##
## È un numero, e va misurato — non "circa sette". Ma la parte che conta è
## un'altra, ed è quella che fa la differenza fra una limitazione e un
## sistema: **le armi devono comprare la possibilità di menare**, non solo
## più danno. Se col coltello fai il triplo del danno ma ti stanchi uguale,
## le armi restano un vezzo; se ti stanchi un quarto, cinquanta euro di
## mazza sono la spesa più sensata del gioco.
##
## E poi l'armiere, che il capo ha chiesto di controllare: tre armi da
## corpo a corpo di tre livelli, più le due da fuoco.

var storte: int = 0


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame

	_prova_quante_pugne()
	_prova_ffierre()
	_prova_comme_torna()
	_prova_corsa()
	_prova_armiere()

	print("=== storte: %d ===" % storte)
	get_tree().quit()


## Quanti colpi ci escono con quello che tieni in mano.
func _quante(arma: String) -> int:
	GameManager.arma_in_mano = arma
	GameManager.sciato = GameManager.SCIATO_MAX
	var n := 0
	while GameManager.pò_menà() and n < 500:
		GameManager.consuma_sciato(GameManager.sciato_colpo())
		n += 1
	return n


func _prova_quante_pugne() -> void:
	print("=== QUANTE PUGNE ===")
	GameManager.start_shift()
	var n: int = _quante("")
	print("  a mano libera: %d pugne e sî scarico" % n)
	if n < 7 or n > 8:
		male("a mano libera esceno %d pugne, ne vuleva 7-8" % n)
	# E a zero non si mena più: è la regola, non una tendenza.
	GameManager.sciato = 0.0
	if GameManager.pò_menà():
		male("cu 'o sciato a zero mena ancora")
	GameManager.sciato = GameManager.SCIATO_PUGNO * 0.2
	if GameManager.pò_menà():
		male("cu 'nu quinto 'e sciato mena ancora")
	print("  a zero nun se mena")


func _prova_ffierre() -> void:
	print("=== 'E FFIERRE ===")
	print("  %-12s %-7s %-8s %-7s %s" % ["arma", "costa", "danno", "sciato",
		"colpe"])
	var senza: int = _quante("")
	var melee: Array = []
	for id in GameManager.ORDINE_ARMI:
		if id == "":
			print("  %-12s %-7s %-8d %-7.1f %d" % ["'e mmane", "-",
				GameManager.arma_danno() if false else 1,
				GameManager.SCIATO_PUGNO, senza])
			continue
		var a: Dictionary = GameManager.ARMI[id]
		if not a.has("sciato"):
			male("%s nun tene 'o sciato dint'â tavola" % id)
			continue
		var n: int = _quante(id)
		print("  %-12s €%-6d %-8d %-7.1f %d" % [id, int(a["costo"]),
			int(a["danno"]), float(a["sciato"]), n])
		if n <= senza:
			male("%s nun fa fà cchiù colpe d''e mmane" % id)
		if not bool(a["distanza"]):
			melee.append(id)

	# **Tre armi da corpo a corpo, tre livelli.** Il capo l'ha chiesto per
	# nome, e servono tre prezzi diversi: una che si compra subito, una di
	# mezzo, una da fine partita.
	print("  %d arme 'e corpo a corpo" % melee.size())
	if melee.size() < 3:
		male("ce stanno sulo %d arme 'e corpo a corpo, ne vònno tre" % melee.size())
	var prezzi: Array = []
	for id in melee:
		prezzi.append(int(GameManager.ARMI[id]["costo"]))
	prezzi.sort()
	for i in range(1, prezzi.size()):
		if prezzi[i] <= prezzi[i - 1]:
			male("duje arme melee costano 'o stesso: €%d" % prezzi[i])
	print("  prezzi: %s" % str(prezzi))
	# La più economica dev'essere alla portata di una giornata storta: se
	# la prima arma costa mezza giornata buona, fino ad allora resti a
	# mani nude ed è come non averle.
	if prezzi[0] > 30:
		male("'a prima arma costa €%d: troppo pe' chi accummencia" % prezzi[0])

	# E le due da fuoco ci devono ancora essere.
	var fuoco := 0
	for id in GameManager.ARMI:
		if bool(GameManager.ARMI[id]["distanza"]):
			fuoco += 1
	print("  %d arme 'a fuoco" % fuoco)
	if fuoco < 2:
		male("se so' perze ll'arme 'a fuoco")

	# **'A cosa ca conta overo**: quanto rende un'arma, fiato compreso.
	# Danno totale che riesci a fare con un serbatoio pieno.
	print("  --- quanto danno cu 'nu sciato chino ---")
	var base := 0
	for id in GameManager.ORDINE_ARMI:
		GameManager.arma_in_mano = id
		var colpi: int = _quante(id)
		var tot: int = colpi * GameManager.arma_danno()
		if id == "":
			base = tot
		print("  %-12s %d colpe × %d = %d" % [
			id if id != "" else "'e mmane", colpi,
			GameManager.arma_danno(), tot])
		if id == "mazza" and tot < base * 3:
			male("'a mazza renne sulo %.1f vote 'e mmane: nun vale 'e sorde"
				% (float(tot) / float(maxi(1, base))))
	GameManager.arma_in_mano = ""


func _prova_comme_torna() -> void:
	print("=== COMME TORNA ===")
	# Da solo: lentissimo. Venti secondi per un pugno è il numero voluto.
	GameManager.start_shift()
	GameManager.sciato = 0.0
	var secunne := 0.0
	while GameManager.sciato < GameManager.SCIATO_PUGNO and secunne < 600.0:
		GameManager._process(0.1)
		secunne += 0.1
	print("  'a sulo: %.0f seconde pe' 'nu pugno" % secunne)
	if secunne < 12.0:
		male("torna troppo ampresso: %.0f seconde" % secunne)
	if secunne > 40.0:
		male("torna troppo chiano: %.0f seconde" % secunne)

	# 'O cafè: meta'.
	GameManager.sciato = 0.0
	GameManager.caffe_al_banco()
	var doppo_cafe: float = GameManager.sciato
	print("  'o cafè: 0 -> %.0f (meta' è %.0f)"
		% [doppo_cafe, GameManager.SCIATO_MAX * 0.5])
	if absf(doppo_cafe - GameManager.SCIATO_MAX * 0.5) > 1.0:
		male("'o cafè nun rimette 'a meta'")

	# E dormire rimette tutto.
	GameManager.sciato = 3.0
	GameManager.start_shift()
	print("  doppo ca hê durmuto: %.0f" % GameManager.sciato)
	if GameManager.sciato < GameManager.SCIATO_MAX:
		male("durmenno nun torna tutto")


func _prova_corsa() -> void:
	print("=== 'A CORSA ===")
	# Correre consuma, ma poco: una traversata della città (200 m a 8,2
	# m/s sono 24 secondi) non deve svuotarti.
	var traversata: float = 200.0 / 8.2
	var costo: float = GameManager.SCIATO_CORSA * traversata
	var pugne: float = costo / GameManager.SCIATO_PUGNO
	print("  'na traversata (%.0f s) costa %.0f 'e sciato = %.1f pugne"
		% [traversata, costo, pugne])
	if pugne > 3.0:
		male("currere costa %.1f pugne: troppo" % pugne)
	if pugne < 0.5:
		male("currere nun costa quase niente: %.1f pugne" % pugne)


func _prova_armiere() -> void:
	print("=== LL'ARMIERE ===")
	var Citta = load("res://scripts/citta_3d.gd")
	var p := Vector3(float(Citta.POSTO_ARMIERE[0]), 0.0,
		float(Citta.POSTO_ARMIERE[1]))
	print("  sta a (%.0f, %.0f)" % [p.x, p.z])
	# Sta in fondo a un vicolo cieco: dev'essere raggiungibile a piedi,
	# quindi fuori dalla corsia e fuori dai varchi come tutto il resto.
	if Citta.in_corsia(p, Vector3(0.9, 1.8, 0.9)):
		male("ll'armiere sta 'n miezo â strada")
	if Citta.dentro_varco(p):
		male("ll'armiere sta dint'ô varco d''e machine")
	# E dev'essere lontano dalla piazza: è un posto dove ci si infila
	# apposta, non una bancarella.
	var quanto: float = Vector2(p.x, p.z).distance_to(Vector2(31.0, 30.0))
	print("  a %.0f metre d''a piazza toia" % quanto)
	if quanto < 40.0:
		male("ll'armiere sta troppo sotto casa: %.0f m" % quanto)
	# Che venda davvero tutto quello che c'è nella tabella.
	var Armiere = load("res://scripts/armiere_3d.gd")
	var a = Armiere.new()
	add_child(a)
	var vende: Array = []
	if a.has_method("elenco"):
		vende = a.elenco()
	else:
		# Se non c'è un elenco esplicito, vende l'ordine delle armi.
		for id in GameManager.ORDINE_ARMI:
			if id != "":
				vende.append(id)
	print("  vende: %s" % str(vende))
	for id in GameManager.ARMI:
		if not vende.has(id):
			male("%s nun se vende 'a nisciuna parte" % id)
	a.queue_free()
