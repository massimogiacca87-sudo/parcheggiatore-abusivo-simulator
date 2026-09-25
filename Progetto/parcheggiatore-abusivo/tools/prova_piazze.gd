extends Node
## 'E quatte piazze so' quatte piazze, o so' 'a stessa quatte vote?
##
## È la domanda della roadmap 0.55, e ha una risposta numerica. Conquistare
## il mercato costa quattrocentocinquanta euro: se poi rende come la piazza
## che hai già, quei soldi hanno comprato **niente** — solo il permesso di
## fare lo stesso lavoro venti metri più in là.
##
## Quindi si misura la giornata intera, piazza per piazza: quante auto
## arrivano, quanto lasciano, quanto si porta a casa. E si chiedono tre
## cose che tirano in direzioni opposte:
##
##   1. che siano **diverse** — se la resa di tutte e quattro sta dentro al
##      venti per cento, il carattere è scritto e non si sente;
##   2. che **nessuna sia la risposta giusta** — se una rende il doppio di
##      tutte le altre a ogni ora, la scelta è finta: si compra quella;
##   3. che la cornetteria **lavori davvero solo di notte**, perché quella
##      è la riga che il capo ha scritto per nome.

var storte: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame

	_prova_tavola()
	_prova_resa()
	_prova_notte()
	_prova_vigile()

	print("=== storte: %d ===" % storte)
	get_tree().quit()


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func _prova_tavola() -> void:
	print("=== 'A TAVOLA ===")
	var Citta = load("res://scripts/citta_3d.gd")
	# Ogni zona della città deve avere il suo carattere, e viceversa: una
	# zona senza carattere ricade sul carattere della piazza e nessuno se
	# ne accorge finché non la compri.
	for z in Citta.ZONE:
		var id := str(z["id"])
		if not GameManager.CARATTERE.has(id):
			male("'a zona '%s' nun tene carattere" % id)
	for k in GameManager.CARATTERE:
		var c: Dictionary = GameManager.CARATTERE[k]
		for chiave in ["nome", "auto", "mancia", "vigili", "notte", "che"]:
			if not c.has(chiave):
				male("%s: manca '%s'" % [k, chiave])
		if float(c["auto"]) <= 0.0 or float(c["mancia"]) <= 0.0:
			male("%s tene 'nu numero a zero" % k)
		if int(c["vigili"]) < 0 or int(c["vigili"]) > 3:
			male("%s tene %d vigile" % [k, c["vigili"]])
	print("  %d caratteri, une pe' ogni zona" % GameManager.CARATTERE.size())


## Quanto rende una piazza in una giornata, contando ora per ora.
##
## Non è una formula: è la stessa catena che gira in partita — l'attesa
## della piazza per l'attesa dell'ora, e la mancia della piazza per la
## mancia dell'ora — presa a ogni fascia e sommata.
func _resa(zona: String, solo_fascia: int = -1) -> float:
	var tot := 0.0
	var prima: float = GameManager.shift_time_left
	for f in range(GameManager.FASCE.size()):
		if solo_fascia >= 0 and f != solo_fascia:
			continue
		# Ci si mette dentro alla fascia muovendo l'orologio: così si usa
		# la funzione vera invece di rifarne una copia che può divergere.
		GameManager.shift_time_left = GameManager.shift_duration \
			* (1.0 - (float(f) + 0.5) / float(GameManager.FASCE.size()))
		var attesa: float = 25.0 * GameManager.attesa_piazza(zona) \
			* GameManager.attesa_ora_e_juorno()
		var quante: float = 90.0 / maxf(1.0, attesa)
		var mancia: float = 3.0 * GameManager.mancia_piazza(zona) \
			* GameManager.mancia_fascia()
		tot += quante * mancia
	GameManager.shift_time_left = prima
	return tot


func _prova_resa() -> void:
	print("=== QUANTO RENNE 'NA JURNATA ===")
	GameManager.tipo_giornata = "normale"
	var rese := {}
	for z in GameManager.CARATTERE:
		rese[z] = _resa(z)
	var chiavi: Array = rese.keys()
	chiavi.sort_custom(func(a, b): return float(rese[a]) > float(rese[b]))
	for k in chiavi:
		var c: Dictionary = GameManager.CARATTERE[k]
		print("  %-13s €%6.0f   (%s · %d vigile)"
			% [k, rese[k], c["nome"], int(c["vigili"])])

	var meglio: float = float(rese[chiavi[0]])
	var peggio: float = float(rese[chiavi[-1]])
	# 1. Devono essere diverse.
	if meglio / maxf(1.0, peggio) < 1.2:
		male("tutt''e piazze renneno 'o stesso: %.2f vote" % (meglio / peggio))
	# 2. Ma nessuna deve essere la risposta a tutto.
	if meglio / maxf(1.0, peggio) > 2.6:
		male("'a meglio renne %.2f vote 'a peggio: nun ce sta cchiù scelta"
			% (meglio / peggio))
	print("  'a meglio renne %.2f vote 'a peggio" % (meglio / peggio))

	# E quella che rende di più dev'essere anche quella che costa
	# qualcosa: qui è il numero dei vigili. Una piazza che rende il
	# massimo E non ha vigili sarebbe una scelta a senso unico.
	var ricca: String = str(chiavi[0])
	if int(GameManager.CARATTERE[ricca]["vigili"]) < 1:
		male("'a piazza cchiù ricca (%s) nun tene manco 'nu vigile" % ricca)


func _prova_notte() -> void:
	print("=== 'A CORNETTERIA LAVORA 'A NOTTE ===")
	GameManager.tipo_giornata = "normale"
	# Fascia 0 = 'o primmo pomeriggio, 4 = 'a nuttata.
	var ultima: int = GameManager.FASCE.size() - 1
	for z in ["piazza", "mercato", "stadio", "cornetteria"]:
		var juorno: float = _resa(z, 0)
		var notte: float = _resa(z, ultima)
		print("  %-13s juorno €%5.0f   notte €%5.0f   (%.1f vote)"
			% [z, juorno, notte, notte / maxf(0.01, juorno)])
		if z == "cornetteria":
			# La riga della roadmap, in numeri: di notte dev'essere un
			# altro mestiere, non un po' meglio.
			if notte / maxf(0.01, juorno) < 3.0:
				male("'a cornetteria 'a notte renne sulo %.1f vote 'e juorno"
					% (notte / juorno))
			# E di giorno dev'essere davvero morta, se no "solo di notte"
			# è un modo di dire.
			if juorno > _resa("piazza", 0) * 0.6:
				male("'a cornetteria 'e juorno renne troppo: nun è 'nu deserto")
		if z == "mercato":
			# Il mercato è il contrario: campa di giorno.
			if notte > juorno:
				male("'o mercato 'a notte renne cchiù 'e juorno")


func _prova_vigile() -> void:
	print("=== 'E VIGILE ===")
	# Il numero dei vigili è la parte del carattere che si **vede**, ed è
	# anche l'unica che costa: due vigili sono il prezzo dello stadio.
	var tot := 0
	for k in GameManager.CARATTERE:
		tot += int(GameManager.CARATTERE[k]["vigili"])
	print("  %d vigile 'n tutta 'a città" % tot)
	if tot < 3:
		male("troppo poche vigile: %d" % tot)
	# Una piazza senza vigili ci vuole (è il "tranquilla" della roadmap) e
	# una con due pure (è il "pericolosa").
	var senza := 0
	var duje := 0
	for k in GameManager.CARATTERE:
		var n: int = int(GameManager.CARATTERE[k]["vigili"])
		if n == 0:
			senza += 1
		if n >= 2:
			duje += 1
	if senza < 1:
		male("nisciuna piazza tranquilla: 'a roadmap ne vuleva una")
	if duje < 1:
		male("nisciuna piazza cu duje vigile: 'a roadmap ne vuleva una")
	print("  %d senza vigile, %d cu duje o cchiù" % [senza, duje])
