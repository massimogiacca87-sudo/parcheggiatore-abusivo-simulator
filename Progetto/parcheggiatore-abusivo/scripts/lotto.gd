extends RefCounted
## 'O lotto — 'e nummere, 'e rrote, 'a smorfia e 'e quote
##
## **Pecché stanno ccà e no dint'ô GameManager.**
##
## Il capo ha chiesto il lotto *"in modo completo come nella realtà"*, e la
## realtà del lotto è **una tabella di numeri**: dieci ruote, novanta
## numeri, cinque sorti e cinque quote. Roba che non cambia mai e che non
## ha niente a che fare con la giornata del giocatore. Nel GameManager
## resta quello che è **suo**: le giocate aperte e l'estrazione di stasera.
##
## **'A smorfia.** Novanta numeri con novanta significati non è decorazione:
## è il motivo per cui a Napoli si gioca. Nessuno punta sul 47, si punta
## su *'o muorto* — e se stanotte hai sognato un morto, quello giochi. Un
## pannello del lotto senza la smorfia sarebbe un foglio di calcolo.
##
## **'E quote so' chelle overe.** Ambata 11,232 · ambo 250 · terno 4.500 ·
## quaterna 120.000 · cinquina 6.000.000. Sembrano numeri da capogiro, e
## infatti il banco ci guadagna lo stesso: la probabilità di prendere un
## terno su una ruota è **una su 11.748**, e la quota ne paga 4.500. Chi
## gioca perde il 62 per cento di quello che mette, sempre, per costruzione.
## È il senso della riga nel tutorial: *il banco vince sempre, sapere
## quanto vince è l'unica difesa.*

## Le dieci ruote più la Nazionale, nell'ordine in cui stanno sui tabelloni.
const RUOTE := ["Bari", "Cagliari", "Firenze", "Genova", "Milano",
	"Napoli", "Palermo", "Roma", "Torino", "Venezia", "Nazionale"]

## Come si chiama la sorte, per quanti numeri giochi.
const SORTI := ["", "ambata", "ambo", "terno", "quaterna", "cinquina"]

## Quanto paga un euro giocato, per sorte. Sono le quote nette del lotto
## italiano: non le ho inventate e non le ho arrotondate.
const QUOTE := [0.0, 11.232, 250.0, 4500.0, 120000.0, 6000000.0]

## Quanti numeri escono per ruota, a ogni estrazione.
const ESTRATTI: int = 5
const NUMERI: int = 90

## Quanto si può puntare. Il minimo è un euro perché a un euro ci gioca
## chiunque, ed è così che il lotto ti frega.
const PUNTATA_MIN: int = 1
const PUNTATA_MAX: int = 20


## **'A smorfia napulitana.** I novanta significati classici, in napoletano.
const SMORFIA := [
	"", "ll'Italia", "'a criatura", "'a jatta", "'o puorco", "'a mano",
	"chella ca guarda 'nterra", "'a scuppetta", "'a Madonna", "'a figliata",
	"'e fasule", "'e surice", "'e surdate", "Sant'Antonio", "'o 'mbriaco",
	"'o guaglione", "'o culo", "'a disgrazia", "'o sanghe", "'a resata",
	"'a festa", "'a femmena annura", "'o pazzo", "'o scemo", "'e gguardie",
	"Natale", "Nanninella", "'o cantero", "'e zzizze", "'o pate d''e criature",
	"'e palle d''o tenente", "'o padrone 'e casa", "'a capa", "'ann' 'e Cristo",
	"'a capa 'e ll'ommo", "ll'aucielluzzo", "'a nozza", "'e ffigure", "'e mmazzate",
	"'a funa 'n cann'", "'o pesce", "'o curtiello", "'o cafè", "'a fenesta",
	"'e ccancelle", "'o vino bbuono", "'e denare", "'o muorto", "'o muorto che pparla",
	"'o piezz' 'e carne", "'o ppane", "'o ciardino", "'a vecchia", "'o patano",
	"'a mano 'e ll'ommo", "'a museca", "'a caruta", "'o scartellato", "'o pilo",
	"'e lamiente", "'o lamiento", "'o cacciatore", "'o muorto acciso", "'a sposa",
	"'a cammisa", "'o chianto", "'o munaciello", "'e zzoccole", "'a minestra",
	"sott'e 'ncoppa", "ll'ommo 'e mmerda", "'a maraviglia", "'o spitale", "'o palazzo",
	"'a rezza", "Pulecenella", "'e cesse", "'a bella figliola", "'o mariuolo",
	"'a vocca", "'e sciure", "'a tavula 'mbandita", "'a vecchia 'ncoppa 'e tetti",
	"'e maccarune", "'a chiesa", "ll'anema 'o priatorio", "'a puteca",
	"'e perucchie", "'e casecavalle", "'a vecchia", "'a paura",
]


## Un'estrazione: cinque numeri diversi da 1 a 90, per ogni ruota.
static func estrai(rng: RandomNumberGenerator) -> Dictionary:
	var fuori: Dictionary = {}
	for r in RUOTE:
		var sacco: Array = []
		for n in range(1, NUMERI + 1):
			sacco.append(n)
		var usciti: Array = []
		for i in range(ESTRATTI):
			var k: int = rng.randi_range(0, sacco.size() - 1)
			usciti.append(int(sacco[k]))
			sacco.remove_at(k)
		fuori[str(r)] = usciti
	return fuori


## Quanto paga una giocata, dati i numeri usciti su quella ruota. Si vince
## **solo con tutti i numeri**: la sorte è quanti ne hai giocati.
static func vincita(numeri: Array, puntata: int, usciti: Array) -> int:
	var quanti: int = numeri.size()
	if quanti < 1 or quanti > 5:
		return 0
	for n in numeri:
		if not usciti.has(int(n)):
			return 0
	return int(round(float(puntata) * QUOTE[quanti]))


static func sorte(quanti: int) -> String:
	if quanti < 1 or quanti >= SORTI.size():
		return "?"
	return SORTI[quanti]


static func nome_numero(n: int) -> String:
	if n < 1 or n >= SMORFIA.size():
		return "%d" % n
	return "%d %s" % [n, SMORFIA[n]]


static func smorfia(n: int) -> String:
	if n < 1 or n >= SMORFIA.size():
		return ""
	return SMORFIA[n]
