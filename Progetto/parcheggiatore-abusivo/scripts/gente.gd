extends RefCounted
## 'A gente d''o quartiere — chi tene 'nu nomme
##
## **Pecché 'nu cliente cu 'o nomme nun è 'nu cliente cchiù ricco.**
##
## Fino alla 0.53 ogni macchina portava uno sconosciuto. Quattro
## personalità (normale, turista, tirchio, 'e pressa), quattro modi di
## comportarsi, e nessuna memoria: il cliente numero quaranta era identico
## al primo, e quello che avevi fatto al secondo non lo sapeva nessuno.
##
## Il risultato è che **le tue scelte non lasciavano traccia**. Rubare uno
## stemma costava calore e basta; trattare bene uno che aveva fretta non
## valeva niente. In un gioco sul mestiere di stare sempre nello stesso
## posto, questa è la cosa più strana che ci potesse essere: chi lavora in
## una piazza conosce chi ci parcheggia.
##
## Adesso una macchina su tre porta **uno di questi**. Hanno un nome, una
## faccia (la macchina è sempre la stessa, il colore pure), un carattere, e
## soprattutto **si ricordano**. Il rapporto va da −100 a +100:
##
##   * sopra a +40 sei uno di casa: pagano quasi sempre e lasciano di più;
##   * sotto a −40 sei quello che gli ha rigato la macchina, e lo sanno.
##
## E la memoria dura fra le giornate (sta nel salvataggio), che è tutto il
## punto: la piazza si costruisce, non si azzera ogni mattina.
##
## **Chi so'.** Sei, e sono sei mestieri diversi di stare in una piazza:
## quello che ci lavora sotto, quella che fa la spesa, quello che porta il
## figlio a scuola, il turista che torna, il tassista che ti conosce da
## sempre, e 'o dottore che non ti guarda in faccia.

# ---------------------------------------------------------------------------
# 'E CLIENTI FISSE
# ---------------------------------------------------------------------------

const CLIENTI := [
	{
		"id": "gennaro",
		"nome": "Gennaro 'o Cassiere",
		"che": "Fa 'o cassiere ô supermercato ccà sotto. Vene tutt''e juorne.",
		"machina": "economica",
		"colore": Color(0.72, 0.72, 0.70),
		"personalita": "normale",
		# Quanto lascia di suo, rispetto a un cliente qualunque.
		"mancia": 1.0,
		# Quanto è facile guadagnarselo e quanto è facile perderlo.
		"memoria": 1.0,
		"saluti": {
			"nuovo": "Buongiorno. Nu poste ce sta?",
			"conosce": "Uè. Comme jammo?",
			"amico": "Uè guagliò! T'aggio purtato 'o resto giusto, guarda.",
			"nemico": "…Tu. Vabbuo'. Miettela addò te pare.",
		},
	},
	{
		"id": "assunta",
		"nome": "Donna Assunta",
		"che": "Scenne p''a spesa e risale cu quatte buste. Cunosce a tuttuquante.",
		"machina": "economica",
		"colore": Color(0.86, 0.62, 0.66),
		"personalita": "normale",
		"mancia": 0.85,
		# Si ricorda tutto, in bene e in male, il doppio degli altri.
		"memoria": 2.0,
		"saluti": {
			"nuovo": "Guagliò, me 'a tiene d'uocchio 'nu poco?",
			"conosce": "Bravo 'o guaglione. Statte attiento ca ce sta 'o vigile.",
			"amico": "Tiè, e t'aggio purtato pure 'na sfugliatella. Mangia.",
			"nemico": "'A machina mia t'aggio 'a fa' guardà? A te?!",
		},
	},
	{
		"id": "peppe",
		"nome": "Peppe 'o Tassista",
		"che": "Trentacinch'anne ncopp'ê stesse strade. Nun se scanta 'e niente.",
		"machina": "berlina",
		# **'O taxi overo** (0.59): il taxi del Car Pack, bianco come i taxi
		# di Napoli, con la scatola gialla sul tetto. Era una berlina gialla
		# qualunque — il giallo era l'unico modo di dire "taxi" senza un
		# modello di taxi.
		"modello": "car_taxi",
		"colore": Color(0.93, 0.93, 0.91),
		"personalita": "fretta",
		"mancia": 1.15,
		"memoria": 1.0,
		"saluti": {
			"nuovo": "Cinche minute, nun 'e cchiù. Tengo 'a corsa.",
			"conosce": "Sempe ccà stai, eh? Bravo. Cinche minute.",
			"amico": "Guagliò, si 'na vota te serve 'nu passaggio, io stongo ccà.",
			"nemico": "A te nun te lasso manco 'e chiave d''a bicicletta.",
		},
	},
	{
		"id": "ciro",
		"nome": "Ciro 'e Pate",
		"che": "Porta 'o figlio â scola e torna 'e pressa. Se scanta 'e tutto.",
		"machina": "berlina",
		"colore": Color(0.32, 0.44, 0.66),
		"personalita": "normale",
		"mancia": 0.95,
		"memoria": 1.4,
		"saluti": {
			"nuovo": "Scusate, aggio 'o criaturo dinto. Faccio ampresso.",
			"conosce": "'O criaturo dorme. Chiano cu 'e portiere, pe' piacere.",
			"amico": "'O criaturo mo' te canosce. Dice ca sî 'o vigile bbuono.",
			"nemico": "Cu 'o criaturo dinto. Cu 'o criaturo dinto m'hê fatto chesto.",
		},
	},
	{
		"id": "hans",
		"nome": "'O Tedesco",
		"che": "Vene ogn'anno 'a vint'anne. Nun ha 'mparato manco 'na parola.",
		"machina": "lusso",
		"colore": Color(0.20, 0.22, 0.26),
		"personalita": "turista",
		# Paga sempre e paga troppo, ma se lo ricorda poco: fra un anno e
		# l'altro le facce si confondono.
		"mancia": 1.45,
		"memoria": 0.5,
		"saluti": {
			"nuovo": "Parken? Ja? Io lasciare qui, ja?",
			"conosce": "Ah! Amico! Io ricordare te!",
			"amico": "Mein Freund! Napoli! Bellissimo! Tieni, tieni!",
			"nemico": "Nein. Nein! Io chiamare polizia!",
		},
	},
	{
		"id": "dottore",
		"nome": "'O Duttore Sannino",
		"che": "Studio ô primmo piano. Nun te guarda 'n faccia, ma pava.",
		"machina": "lusso",
		"colore": Color(0.62, 0.10, 0.12),
		"personalita": "tirchio",
		"mancia": 1.25,
		# Non si affeziona e non si offende: paga e basta. Ma se lo perdi,
		# lo perdi per sempre.
		"memoria": 0.7,
		"saluti": {
			"nuovo": "Sì sì. Tènela d'uocchio.",
			"conosce": "'A solita. Nun me fa' aspettà.",
			"amico": "Bravo. Si te serve 'na ricetta, saje addò stongo.",
			"nemico": "Cu te nun ce parlo cchiù. Levate 'a nanze.",
		},
	},
]


## Le due soglie che dividono i tre modi di salutarti.
const AMICO: float = 40.0
const NEMICO: float = -40.0


static func cliente(id: String) -> Dictionary:
	for c in CLIENTI:
		if str(c["id"]) == id:
			return c
	return {}


## Come ti saluta, dato quante volte ti ha visto e come lo hai trattato.
static func saluto(id: String, visto: int, rapporto: float) -> String:
	var c: Dictionary = cliente(id)
	if c.is_empty():
		return ""
	var s: Dictionary = c["saluti"]
	if rapporto >= AMICO:
		return str(s["amico"])
	if rapporto <= NEMICO:
		return str(s["nemico"])
	if visto <= 1:
		return str(s["nuovo"])
	return str(s["conosce"])


# ---------------------------------------------------------------------------
# 'O VICINATO
# ---------------------------------------------------------------------------
#
# **'O vicinato dà 'na mano, no 'na nutizia (0.55).**
#
# Alla 0.54 questi quattro dicevano dove stava il vigile, quante stelle
# avevi addosso e qual era il lavoretto che pagava di più. Il capo:
# *"le informazioni che ti danno le persone sono superflue"*. Aveva
# ragione, e il motivo è più profondo di quanto sembri: quelle notizie
# erano **utili ma non memorabili**. Ti cambiavano i trenta secondi dopo e
# poi sparivano, e dopo tre giorni erano una riga di HUD con una faccia
# davanti — per giunta una riga che il giocatore poteva ricavarsi da solo
# girando l'angolo e guardando.
#
# Adesso ognuno **fa una cosa**, e sono tre cose che in questo gioco
# scarseggiano davvero: il caffè (sospetto giù), un portone in cui
# infilarsi quando ti cercano, e da mangiare. La quarta è l'unica notizia
# rimasta, e resta perché **porta da qualche parte**: Mimmo sa dove sta
# oggi 'a Signora d''e nummere.

const VICINE := [
	{
		"id": "nunzia_bar",
		"nome": "Nunzia d''o Bar",
		"che": "Sta sempe fore â porta d''o bar, cu 'o strofinaccio 'n mano.",
		"chiede": "'nu cafè",
		"costo": 2,
		"dice": "cafe",
		"memoria": 1.2,
		"colore": Color(0.82, 0.36, 0.42),
		"battute": {
			"saluto": "Pigliate 'nu cafè, ca tiene 'na faccia. Doje euro.",
			"pagato": "%s Tiè, e statte 'nu poco cchiù calmo.",
			"senza": "E pigliatillo 'nu cafè, no? Doje euro so'.",
			"amico": "Pe' te 'o cafè nun se paga. %s Tiè.",
		},
	},
	{
		"id": "totore",
		"nome": "Totore 'o Guardiano",
		"che": "Guarda 'o palazzo 'a quarant'anne. Vede tutto e nun dice niente. Quase.",
		"chiede": "'na sigaretta",
		"costo": 1,
		"dice": "ammuccia",
		"memoria": 0.9,
		"colore": Color(0.34, 0.38, 0.46),
		"battute": {
			"saluto": "Damme 'na sigaretta e t'arapo 'o purtone, si te serve.",
			"pagato": "%s Trase, va'. E nun fà rummore.",
			"senza": "Senza sigarette nun s'arape niente, guagliò.",
			"amico": "'O purtone pe' te sta sempe apierto. %s",
		},
	},
	{
		"id": "rosa",
		"nome": "Rosa d''o Vico",
		"che": "Cala 'o panaro d''o secondo piano. Si le fai 'nu piacere, 'o cala chino.",
		"chiede": "'o ppane",
		"costo": 3,
		"dice": "ossa",
		"memoria": 1.5,
		"colore": Color(0.72, 0.60, 0.30),
		"battute": {
			"saluto": "Guagliò! Me piglie 'o ppane? Tre euro, e nun me fa' scennere.",
			"pagato": "Bravo. %s",
			"senza": "Tre euro, guagliò. Nun songo 'na banca manco io.",
			"amico": "'O panaro sta già calanno. %s",
		},
	},
	{
		"id": "mimmo",
		"nome": "Mimmo 'o Guaglione",
		"che": "Tene diece anne e sape tutto chello ca succede dint'ô vico.",
		"chiede": "'nu gelato",
		"costo": 2,
		"dice": "signora",
		"memoria": 1.0,
		"colore": Color(0.30, 0.58, 0.72),
		"battute": {
			"saluto": "Uè! Me pigli 'nu gelato? Po' te dico 'na cosa 'e valore!",
			"pagato": "%s L'aggio vista io, overo!",
			"senza": "E allora nun te dico niente. Tiè.",
			"amico": "Nun me serve 'o gelato. Sient': %s",
		},
	},
]


static func vicino(id: String) -> Dictionary:
	for v in VICINE:
		if str(v["id"]) == id:
			return v
	return {}


## Chiunque tenga 'nu nomme: cliente o vicino ca sia. Serve â memoria d''o
## GameManager, ca nun ha 'a sapé si uno guida o sta ô balcone.
static func chi(id: String) -> Dictionary:
	var c: Dictionary = cliente(id)
	if not c.is_empty():
		return c
	return vicino(id)
