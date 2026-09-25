extends RefCounted
## 'A partita virtuale — 'o campionato d''e rrione
##
## **Che d'è, e pecché è fatta accussì.**
##
## Il capo: *"alla better si può scommettere su partite virtuali che danno
## risultati immediati nel giro di pochi secondi, con una schermata stile
## Football Manager… la partita si svolge veloce in 5-10 secondi, con
## cronometro che sale verso il novantesimo e i gol segnalati insieme a
## rigori espulsioni ecc, come una vera partita."*
##
## Questo file è **solo il motore**: due squadre entrano, esce una
## cronologia di fatti minuto per minuto e un risultato. Il pannello
## (`pannello_partite.gd`) li fa scorrere sullo schermo col cronometro. La
## divisione conta perché una partita si può far girare **diecimila volte
## in una prova** senza aprire una finestra, ed è l'unico modo di sapere
## se le quote sono oneste.
##
## **'E squadre so' 'e rrione, no 'e squadre overe.** Sanità contro
## Forcella, Vommero contro Bagnoli. Non è (solo) per non mettere nomi
## veri in un gioco: è che una schedina con scritto "Quartieri Spagnoli –
## Secondigliano" fa ridere, e una con scritto Juventus–Roma no.
##
## **'E quote se ricavano d''e fforze, e 'o banco se piglia 'o sujo.**
## Prima si calcolano le probabilità vere dei tre esiti; poi si dividono
## per uno e otto per cento. Quel sette-otto per cento **è** il guadagno
## della sala: chi gioca alla lunga perde, come deve.

## Quanti minuti dura, e in quanti secondi si guarda.
const MINUTI: int = 90
## Il tetto sui gol per squadra: oltre non è più una partita, è una
## barzelletta — e col metodo di Poisson una coda lunghissima esiste.
const GOL_MAX: int = 6
## Il margine del banco. Otto per cento: è quello delle sale vere.
const CRESTA: float = 0.08

const SQUADRE := [
	{"nome": "SANITÀ", "forza": 74, "campo": "'O Campetto d''a Sanità"},
	{"nome": "FORCELLA", "forza": 71, "campo": "Campo Forcella"},
	{"nome": "QUARTIERI", "forza": 69, "campo": "'O Cortile 'e Montecalvario"},
	{"nome": "VOMMERO", "forza": 78, "campo": "Stadio Arenella"},
	{"nome": "FUORIGROTTA", "forza": 80, "campo": "'O Campo Nuovo"},
	{"nome": "BAGNULE", "forza": 66, "campo": "Campo 'e ll'Acciaieria"},
	{"nome": "MERGELLINA", "forza": 72, "campo": "'A Rutunna"},
	{"nome": "SECUNDIGLIANO", "forza": 75, "campo": "Campo 'e Chiaiano"},
	{"nome": "MATERDEI", "forza": 68, "campo": "'O Chiuovo"},
	{"nome": "PUSILLECO", "forza": 70, "campo": "'A Scesa 'e Marechiaro"},
	{"nome": "SAN GIUVANNE", "forza": 67, "campo": "Campo Taverna d''o Ferro"},
	{"nome": "PIANURA", "forza": 73, "campo": "Campo 'e ll'Ovo"},
]

const ARBITRE := ["Esposito 'e Frattamaggiore", "Cacace 'e Marano",
	"Improta 'e Casoria", "Ferrara 'e Torre 'o Grieco",
	"Sannino 'e Pumigliano", "Chiaiese 'e Miano"]

const TIEMPO := ["asciutto, 22°", "asciutto, 28°", "annuvolato, 19°",
	"ce chiove, 16°", "ventiato, 20°", "cavero assaje, 33°"]

## I nomi dei giocatori: un cognome napoletano e basta. Servono per le
## righe della cronaca — "gol di Esposito" si legge, "gol del numero 9" no.
const CUGNOMME := ["Esposito", "Russo", "Coppola", "Improta", "Borrelli",
	"Cacace", "Sannino", "Iorio", "Mazzocchi", "Chiaiese", "Aiello",
	"Ferrara", "Palumbo", "Guarino", "Aversano", "Scognamiglio", "Terracciano",
	"Marfella", "Capuozzo", "Nappi", "Cimmino", "Vitiello", "Auriemma"]


# ---------------------------------------------------------------------------
# 'E probabilità e 'e quote
# ---------------------------------------------------------------------------

## Quanti gol ci si aspetta, in media, da una squadra contro l'altra. La
## forza va da 60 a 85; la differenza pesa, ma non decide: una partita in
## cui il più forte vince sempre non è una scommessa.
static func gol_attesi(mia: int, soja: int, dint_a_casa: bool) -> float:
	var diff: float = float(mia - soja) / 40.0
	var base: float = 1.28 + diff
	if dint_a_casa:
		base += 0.22        # il campo, che nel calcio vero vale più o meno questo
	return clampf(base, 0.28, 3.4)


## Poisson: la probabilità che una squadra che ne fa `lam` di media ne
## faccia esattamente `k`. È il modello standard dei gol nel calcio, e non
## per moda: i gol sono eventi rari e indipendenti, che è esattamente il
## caso in cui Poisson descrive la realtà.
static func _poisson(lam: float, k: int) -> float:
	var p: float = exp(-lam)
	for i in range(1, k + 1):
		p *= lam / float(i)
	return p


## Le probabilità vere dei tre esiti: casa, pareggio, fuori.
static func probabilita(casa: Dictionary, fore: Dictionary) -> Array:
	var lc: float = gol_attesi(int(casa["forza"]), int(fore["forza"]), true)
	var lf: float = gol_attesi(int(fore["forza"]), int(casa["forza"]), false)
	var p1: float = 0.0
	var px: float = 0.0
	var p2: float = 0.0
	for a in range(0, GOL_MAX + 3):
		for b in range(0, GOL_MAX + 3):
			var p: float = _poisson(lc, a) * _poisson(lf, b)
			if a > b:
				p1 += p
			elif a == b:
				px += p
			else:
				p2 += p
	var tot: float = maxf(p1 + px + p2, 0.0001)
	return [p1 / tot, px / tot, p2 / tot]


## Le quote esposte: la probabilità capovolta, meno la cresta del banco.
## Con la cresta a 0,08 la somma dei tre inversi fa 1,08 — cioè su cento
## euro giocati la sala se ne tiene otto, sempre.
static func quote(casa: Dictionary, fore: Dictionary) -> Array:
	var p: Array = probabilita(casa, fore)
	var fuori: Array = []
	for x in p:
		var q: float = 1.0 / maxf(float(x) * (1.0 + CRESTA), 0.001)
		# Due decimali, come sui tabelloni.
		fuori.append(snappedf(q, 0.01))
	return fuori


# ---------------------------------------------------------------------------
# 'A partita
# ---------------------------------------------------------------------------

## Fa giocare la partita e torna tutto quello che serve al pannello:
## risultato, cronologia minuto per minuto, arbitro, tempo, campo.
static func gioca(casa: Dictionary, fore: Dictionary,
		rng: RandomNumberGenerator) -> Dictionary:
	var lc: float = gol_attesi(int(casa["forza"]), int(fore["forza"]), true)
	var lf: float = gol_attesi(int(fore["forza"]), int(casa["forza"]), false)
	var gc: int = _tira_gol(lc, rng)
	var gf: int = _tira_gol(lf, rng)

	# I minuti dei gol: sparsi, ma non nei primi due e non oltre il 90.
	var fatti: Array = []
	for i in range(gc):
		fatti.append({"min": rng.randi_range(3, MINUTI), "chi": 0, "che": "gol"})
	for i in range(gf):
		fatti.append({"min": rng.randi_range(3, MINUTI), "chi": 1, "che": "gol"})

	# **'E rigore.** Un rigore è un gol che si vede arrivare: si sceglie
	# fra i gol già decisi e lo si trasforma, invece di aggiungerne uno.
	# Se ne aggiungessi uno il risultato non tornerebbe più con le quote,
	# e le quote sono la sola cosa che deve restare onesta.
	for f in fatti:
		if rng.randf() < 0.11:
			f["che"] = "rigore"

	# **'E ccarte.** Quelle sì che si aggiungono: non cambiano il
	# risultato, cambiano il racconto. Un rosso ogni cinque partite circa.
	var quante_carte: int = rng.randi_range(1, 5)
	for i in range(quante_carte):
		fatti.append({"min": rng.randi_range(8, MINUTI), "chi": rng.randi() % 2,
			"che": "giallo"})
	if rng.randf() < 0.20:
		fatti.append({"min": rng.randi_range(30, MINUTI), "chi": rng.randi() % 2,
			"che": "rosso"})
	if rng.randf() < 0.28:
		fatti.append({"min": rng.randi_range(12, MINUTI), "chi": rng.randi() % 2,
			"che": "palo"})
	if rng.randf() < 0.22:
		fatti.append({"min": rng.randi_range(20, MINUTI), "chi": rng.randi() % 2,
			"che": "parata"})

	fatti.sort_custom(func(a, b): return int(a["min"]) < int(b["min"]))

	# Il nome di chi fa la cosa, e la riga di cronaca.
	var nomi := [str(casa["nome"]), str(fore["nome"])]
	var punti := [0, 0]
	for f in fatti:
		var chi: int = int(f["chi"])
		var tizio: String = CUGNOMME[rng.randi() % CUGNOMME.size()]
		f["squadra"] = nomi[chi]
		f["chi_nomme"] = tizio
		match str(f["che"]):
			"gol":
				punti[chi] += 1
				f["testo"] = "%s!!! %s L'HA MESSA DINTO!" % [nomi[chi], tizio.to_upper()]
			"rigore":
				punti[chi] += 1
				f["testo"] = "RIGORE PE' %s — %s NUN SBAGLIA!" % [nomi[chi],
					tizio.to_upper()]
			"giallo":
				f["testo"] = "Giallo a %s (%s). L'arbitro nun 'a passa." % [tizio,
					nomi[chi]]
			"rosso":
				f["testo"] = "ROSSO A %s! %s resta 'n diece!" % [tizio.to_upper(),
					nomi[chi]]
			"palo":
				f["testo"] = "PALO! %s c'è arrivato pe' 'nu pilo." % tizio
			"parata":
				f["testo"] = "Che parata! 'O portiere 'e %s l'ha levata 'a sotto 'a traversa." \
					% nomi[chi]
		f["casa"] = punti[0]
		f["fore"] = punti[1]

	var esito := "X"
	if gc > gf:
		esito = "1"
	elif gf > gc:
		esito = "2"

	return {
		"casa": casa, "fore": fore,
		"gol_casa": gc, "gol_fore": gf, "esito": esito,
		"fatti": fatti,
		"arbitro": ARBITRE[rng.randi() % ARBITRE.size()],
		"tiempo": TIEMPO[rng.randi() % TIEMPO.size()],
		"campo": str(casa["campo"]),
		# Il possesso: un numero solo, che il pannello disegna come barra.
		# Sta fra il 32 e il 68, che è il campo di variazione vero.
		"possesso": clampi(50 + int(round((float(casa["forza"])
			- float(fore["forza"])) * 0.9)) + rng.randi_range(-7, 7), 32, 68),
	}


## Un numero di gol estratto da una Poisson, col metodo di Knuth.
static func _tira_gol(lam: float, rng: RandomNumberGenerator) -> int:
	var l: float = exp(-lam)
	var k: int = 0
	var p: float = 1.0
	while true:
		p *= rng.randf()
		if p <= l or k >= GOL_MAX:
			break
		k += 1
	return k


## Il cartellone della giornata: tre partite, sempre diverse fra loro.
static func cartellone(rng: RandomNumberGenerator, quante: int = 3) -> Array:
	var sacco: Array = []
	for i in range(SQUADRE.size()):
		sacco.append(i)
	var fuori: Array = []
	for i in range(quante):
		if sacco.size() < 2:
			break
		var a: int = int(sacco.pop_at(rng.randi_range(0, sacco.size() - 1)))
		var b: int = int(sacco.pop_at(rng.randi_range(0, sacco.size() - 1)))
		var casa: Dictionary = SQUADRE[a]
		var fore: Dictionary = SQUADRE[b]
		fuori.append({
			"casa": casa, "fore": fore, "quote": quote(casa, fore),
		})
	return fuori
