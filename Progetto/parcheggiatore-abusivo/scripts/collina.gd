extends RefCounted
class_name Collina
## La collina d''o Vommero
##
## **Perché non c'è altimetria vera in questo gioco.**
##
## Tutto poggia sull'assunzione che il suolo stia a quota zero: le auto
## camminano con `move_and_slide` su un piano, i collider delle zone sono
## scatole appoggiate allo zero, i clienti si generano a `y = 0.4` e i
## passanti puntano a un `Vector3` con la y a zero. Inclinare il terreno
## vorrebbe dire riscrivere tutto quello, e romperebbe il gioco molto prima
## di migliorare la grafica.
##
## Ma il Vomero *è* la collina — è la prima cosa che un napoletano dice se
## gli chiedi che quartiere è. Quindi si fa la cosa che dà il novanta per
## cento dell'effetto con il dieci per cento del rischio: un **terrapieno**.
## Un pezzo di città rettangolare, delimitato da quattro strade, che sta
## cinque metri più in alto di tutto il resto, con i muraglioni di tufo
## intorno e le scalinate agli imbocchi. Ci si sale a piedi, si vedono i
## tetti degli altri quartieri da sopra, e sotto la piazza il piano di
## lavoro resta piatto esattamente com'era.
##
## Il terrapieno non contiene nessuna zona di gioco e nessun percorso di
## veicoli: né le auto dei clienti né i motorini ci passano. È di proposito.

## Il rettangolo del terrapieno, [x0, z0, x1, z1].
##
## I quattro bordi combaciano con quattro strade che restano a quota zero:
## a nord la trasversale z 124-128, a sud quella z 168-172, a ponente il
## cardine x 103-107, a levante il cardine x 155-159. Così il muraglione ha
## sempre una strada davanti da cui guardarlo, che è mezzo effetto.
const RECT := [107.0, 128.0, 155.0, 168.0]

## Quanto sta in alto.
##
## Tre metri, cioe' un piano pieno: si sale sedici gradini e si vede sopra
## ai tetti delle strade di sotto. Non e' un numero scelto a occhio — e' il
## massimo che ci sta. La scalinata deve stare tutta dentro alla strada che
## costeggia il terrapieno, che e' larga quattro metri: tre metri di salita
## in quattro di corsa fanno una rampa a 37 gradi, che si cammina. Con
## cinque metri (la prima versione) la rampa saliva a 51 gradi, cioe' un
## muro: il personaggio ci sbatteva contro e restava di sotto.
const QUOTA: float = 3.0

## Quanto sporge la scalinata dal bordo, in orizzontale. Quattro metri:
## esattamente la larghezza della strada che ha davanti.
const RAMPA: float = 4.0

## Gli imbocchi: dove il muraglione si apre e c'è la scalinata.
## [lato, centro, larghezza] — lato: "n", "s", "o", "e".
const IMBOCCHI := [
	["n", 118.0, 4.0],   # cardine 'e levante, da sopra
	["n", 131.0, 4.0],   # il cardine accanto
	["s", 118.0, 4.0],
	["s", 131.0, 4.0],
	["o", 154.0, 4.0],   # la trasversale z 152-156, a ponente
	["e", 154.0, 4.0],   # e a levante
]


static func dentro(x: float, z: float) -> bool:
	return x >= RECT[0] and x <= RECT[2] and z >= RECT[1] and z <= RECT[3]


## Di quanto va alzato un punto. Zero fuori dal terrapieno.
static func alzata(x: float, z: float) -> float:
	return QUOTA if dentro(x, z) else 0.0
