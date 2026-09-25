extends RefCounted
class_name ScopaMotore
## Il motore della scopa. Regole vere, niente interfaccia.
##
## **Perché un motore separato.** La scopa dei vecchi che stanno ai
## tavolini (scopa_3d.gd) è arredamento: gioca da sola, non la guarda
## nessuno, e le regole possono essere approssimate. Questa invece è la
## partita che giochi tu, e ci scommetti sopra i soldi della spesa: le
## regole devono essere quelle, comprese le due che tutti sbagliano —
## **la presa per somma vale solo se non c'è la carta uguale**, e **l'ultima
## presa della partita non fa scopa**.
##
## ## Le carte
##
## Un intero da 0 a 39: `seme * 10 + (valore - 1)`. Seme 0 coppe, 1 denari,
## 2 bastoni, 3 spade — lo stesso ordine dell'atlante in `carte.gd`, così
## l'indice della carta È l'indice della figurina, senza tabelle di mezzo.
##
## ## Il punteggio
##
## Cinque punti come si è sempre fatto: carte, denari, settebello,
## primiera, più le scope. Una smazzata sola (quaranta carte) e chi fa più
## punti vince: una partita a undici durerebbe dieci minuti, e dieci minuti
## sono un terzo di giornata di lavoro.

const SETTEBELLO: int = 16   # seme 1 (denari), valore 7 -> 1*10 + 6

## Il valore per la primiera, per numero di carta.
const PRIMIERA := {7: 21, 6: 18, 1: 16, 5: 15, 4: 14, 3: 13, 2: 12,
	8: 10, 9: 10, 10: 10}

var mazzo: Array = []
var tavolo: Array = []
var mani: Array = [[], []]        # 0 = tu, 1 = 'o viecchio
var prese: Array = [[], []]
var scope: Array = [0, 0]
var turno: int = 0
var ultimo_a_prendere: int = -1
var finita: bool = false
## Le carte gia' viste da tutti (per chi conta).
var uscite: Array = []


static func valore(c: int) -> int:
	return (c % 10) + 1


static func seme(c: int) -> int:
	return int(c / 10)


static func e_denaro(c: int) -> bool:
	return seme(c) == 1


static func nome_carta(c: int) -> String:
	const V := ["asso", "due", "tre", "quattro", "cinque", "sei", "sette",
		"fante", "cavallo", "re"]
	const S := ["'e coppe", "'e denare", "'e bastone", "'e spade"]
	return "%s %s" % [V[c % 10], S[seme(c)]]


func nuova_partita(chi_comincia: int = 0) -> void:
	mazzo = []
	for i in range(40):
		mazzo.append(i)
	mazzo.shuffle()
	tavolo = []
	mani = [[], []]
	prese = [[], []]
	scope = [0, 0]
	uscite = []
	finita = false
	ultimo_a_prendere = -1
	turno = chi_comincia
	# Quattro in tavola. Se ne escono tre uguali di fila si rimescola: e'
	# la regola vera, e serve a non cominciare con tre re scoperti.
	for _i in range(4):
		tavolo.append(mazzo.pop_back())
	_distribuisci()


func _distribuisci() -> void:
	for g in range(2):
		for _i in range(3):
			if mazzo.is_empty():
				break
			mani[g].append(mazzo.pop_back())


func mano_finita() -> bool:
	return mani[0].is_empty() and mani[1].is_empty()


func carte_finite() -> bool:
	return mazzo.is_empty() and mano_finita()


# ---------------------------------------------------------------------------
# 'E prese possibili
# ---------------------------------------------------------------------------

## Tutte le prese che una carta può fare sul tavolo dato.
##
## Se c'è la carta dello stesso valore, quella è **l'unica** presa
## ammessa — è la regola che distingue chi la scopa la sa giocare da chi
## crede di saperla.
static func prese_possibili(carta: int, banco: Array) -> Array:
	var v: int = valore(carta)
	var uguali: Array = []
	for c in banco:
		if valore(c) == v:
			uguali.append([c])
	if not uguali.is_empty():
		return uguali
	# Somme. Il tavolo non supera mai le dieci-dodici carte, quindi la
	# forza bruta sui sottoinsiemi va benissimo (2^12 = 4096 nel caso
	# peggiore, e succede una volta a partita).
	var fuori: Array = []
	var n: int = banco.size()
	for m in range(1, 1 << n):
		var somma := 0
		var gruppo: Array = []
		for i in range(n):
			if m & (1 << i):
				somma += valore(banco[i])
				gruppo.append(banco[i])
		if somma == v and gruppo.size() > 1:
			fuori.append(gruppo)
	return fuori


## Gioca `carta` dalla mano di `g`, prendendo `presa` (un array di carte
## del tavolo, vuoto = la carta resta). Ritorna un resoconto per l'interfaccia.
func gioca(g: int, carta: int, presa: Array = []) -> Dictionary:
	if finita or not mani[g].has(carta):
		return {}
	mani[g].erase(carta)
	uscite.append(carta)
	var esito := {"chi": g, "carta": carta, "presa": presa.duplicate(),
		"scopa": false}
	if presa.is_empty():
		tavolo.append(carta)
	else:
		for c in presa:
			tavolo.erase(c)
			uscite.append(c)
		prese[g].append(carta)
		for c in presa:
			prese[g].append(c)
		ultimo_a_prendere = g
		# **La scopa non vale sull'ultima carta della partita.** E' la
		# regola che ci si dimentica sempre, ed e' quella che decide le
		# partite in parita'.
		if tavolo.is_empty() and not carte_finite():
			scope[g] += 1
			esito["scopa"] = true

	turno = 1 - g
	if mano_finita():
		if mazzo.is_empty():
			_chiudi()
		else:
			_distribuisci()
	return esito


func _chiudi() -> void:
	finita = true
	# Le carte rimaste in tavola vanno all'ultimo che ha preso.
	if ultimo_a_prendere >= 0:
		for c in tavolo:
			prese[ultimo_a_prendere].append(c)
	tavolo = []


# ---------------------------------------------------------------------------
# 'E ppunte
# ---------------------------------------------------------------------------

func primiera(g: int) -> int:
	var meglio := [0, 0, 0, 0]
	for c in prese[g]:
		var p: int = int(PRIMIERA.get(valore(c), 0))
		var s: int = seme(c)
		if p > meglio[s]:
			meglio[s] = p
	return meglio[0] + meglio[1] + meglio[2] + meglio[3]


func denari(g: int) -> int:
	var n := 0
	for c in prese[g]:
		if e_denaro(c):
			n += 1
	return n


## Il conto finale, voce per voce: serve alla schermata, non solo al totale.
func punteggio() -> Dictionary:
	var out := {"punti": [scope[0], scope[1]], "voci": []}
	var c0: int = prese[0].size()
	var c1: int = prese[1].size()
	_voce(out, "Carte", c0, c1)
	var d0: int = denari(0)
	var d1: int = denari(1)
	_voce(out, "Denare", d0, d1)
	var s0: bool = prese[0].has(SETTEBELLO)
	var s1: bool = prese[1].has(SETTEBELLO)
	if s0 or s1:
		out["voci"].append({"nome": "Settebello",
			"a": 1 if s0 else 0, "b": 1 if s1 else 0,
			"chi": 0 if s0 else 1})
		out["punti"][0 if s0 else 1] += 1
	var p0: int = primiera(0)
	var p1: int = primiera(1)
	_voce(out, "Primera", p0, p1)
	if scope[0] > 0 or scope[1] > 0:
		out["voci"].append({"nome": "Scope", "a": scope[0], "b": scope[1],
			"chi": -1})
	return out


func _voce(out: Dictionary, nome: String, a: int, b: int) -> void:
	var chi := -1
	if a > b:
		chi = 0
		out["punti"][0] += 1
	elif b > a:
		chi = 1
		out["punti"][1] += 1
	out["voci"].append({"nome": nome, "a": a, "b": b, "chi": chi})


# ===========================================================================
# 'E CCAPE D''E VIECCHIE — l'intelligenza, un'idea in più per ognuno
# ===========================================================================
#
# La difficoltà non è un numero che sale. È che ognuno **sa una cosa in
# più** di quello prima, e la cosa in più si vede giocando:
#
#   0  Ciccio 'o Guappo   cala a caso. Ride e perde.
#   1  'O Professore      piglia sempre 'a presa cchiu' grossa.
#   2  Zi' Peppe          guarda pure che te lascia 'n tavola.
#   3  Nicola 'e ll'Uocchie conta 'e ccarte asciute.
#   4  Don Gennaro        conta, e quanno serve **bara**.

## **Quanto vale una carta — e quanto ne capisce chi la guarda.**
##
## Qui sta la differenza vera fra 'O Professore e Zi' Peppe, e non e' un
## numero di difficolta': e' che uno le carte le CONTA e l'altro le PESA.
## Al livello 1 valgono tutte uno — che e' esattamente la descrizione del
## Professore, "piglia sempe 'a presa cchiu' grossa": lui guarda quante ne
## fa, non quali. Dal livello 2 in su cominciano a contare i denari, il
## settebello e i sette della primiera, ed e' li' che il gioco diventa
## difficile.
static func peso(c: int, livello: int = 9) -> float:
	if livello <= 1:
		return 1.0
	var p := 1.0
	if c == SETTEBELLO:
		p += 9.0
	elif e_denaro(c):
		p += 2.6
	if valore(c) == 7:
		p += 1.4          # 'e ssette, p''a primera
	elif valore(c) == 6:
		p += 0.7
	elif valore(c) == 1:
		p += 0.5
	return p


static func peso_gruppo(g: Array, livello: int = 9) -> float:
	var t := 0.0
	for c in g:
		t += peso(c, livello)
	return t


## Tutte le mosse legali per il giocatore `g` sul tavolo `banco`.
static func opzioni_di(mano: Array, banco: Array) -> Array:
	var fuori: Array = []
	for c in mano:
		var prese_c: Array = prese_possibili(c, banco)
		if prese_c.is_empty():
			fuori.append({"carta": c, "presa": []})
		else:
			for p in prese_c:
				fuori.append({"carta": c, "presa": p})
	return fuori


## Com'è il tavolo dopo una mossa.
static func tavolo_dopo(banco: Array, o: Dictionary) -> Array:
	var dopo: Array = banco.duplicate()
	for c in o["presa"]:
		dopo.erase(c)
	if o["presa"].is_empty():
		dopo.append(int(o["carta"]))
	return dopo


## La mossa scelta dalla macchina. Ritorna {"carta": int, "presa": Array}.
func mossa_ia(livello: int) -> Dictionary:
	var mano: Array = mani[1]
	if mano.is_empty():
		return {}
	var opzioni: Array = opzioni_di(mano, tavolo)

	if livello <= 0:
		# Ciccio piglia se se n'accorge, se no cala 'a cchiu' bassa.
		var con_presa: Array = opzioni.filter(
			func(o): return not o["presa"].is_empty())
		if not con_presa.is_empty() and randf() < 0.72:
			return con_presa[randi() % con_presa.size()]
		return opzioni[randi() % opzioni.size()]

	# 'O Professore ogni tanto se distrae: una mossa su venti la sbaglia.
	if livello == 1 and randf() < 0.06:
		return opzioni[randi() % opzioni.size()]

	var migliore: Dictionary = opzioni[0]
	var punto_migliore: float = -INF
	for o in opzioni:
		var v: float = _valuta(o, livello)
		if livello >= 4:
			# **Don Gennaro guarda una mossa più avanti.** Simula il tavolo
			# dopo la propria giocata e ci mette sopra la risposta migliore
			# che potrebbe darti uno che gioca bene, con le carte che sa
			# essere ancora fuori. Non è un minimax vero — è quello che fa
			# un vecchio che gioca da settant'anni: "e chillo che me fa?".
			v -= _risposta_peggiore(tavolo_dopo(tavolo, o)) * 0.62
		if v > punto_migliore:
			punto_migliore = v
			migliore = o
	return migliore


## Quanto guadagnerebbe l'avversario, al meglio, sul tavolo che gli lascio.
## Le carte che potrebbe avere sono quelle che non ho ancora visto.
func _risposta_peggiore(banco: Array) -> float:
	var candidate: Array = _non_viste()
	if candidate.is_empty() or banco.is_empty():
		return 0.0
	var peggio := 0.0
	for c in candidate:
		var prese_c: Array = prese_possibili(c, banco)
		for p in prese_c:
			var v: float = peso_gruppo(p) + peso(c)
			if p.size() == banco.size():
				v += 12.0
			if v > peggio:
				peggio = v
	# Ne tiene tre in mano su tutte quelle che restano: la mossa peggiore
	# non è certa, è probabile.
	var quota: float = clampf(3.0 / maxf(float(candidate.size()), 1.0),
		0.0, 1.0)
	return peggio * quota


## Le carte che chi conta sa di non aver ancora visto.
func _non_viste() -> Array:
	var viste: Dictionary = {}
	for c in uscite:
		viste[c] = true
	for c in tavolo:
		viste[c] = true
	for c in mani[1]:
		viste[c] = true
	for c in prese[1]:
		viste[c] = true
	var fuori: Array = []
	for i in range(40):
		if not viste.has(i):
			fuori.append(i)
	return fuori


func _valuta(o: Dictionary, livello: int) -> float:
	var presa: Array = o["presa"]
	var carta: int = int(o["carta"])
	var v: float = 0.0
	if not presa.is_empty():
		# Prendendo, finiscono nel mucchio sia le carte del tavolo sia
		# quella che hai calato.
		v += peso_gruppo(presa, livello) + peso(carta, livello)
		if tavolo.size() == presa.size():
			v += 12.0     # scopa
	else:
		# Calare vuol dire regalare: quanto pesa quello che lasci.
		v -= peso(carta, livello) * 0.55

	if livello >= 2:
		# **Che gli lascio 'n tavola.**
		#
		# Il primo tentativo penalizzava a occhio ("se resta poco, brutto")
		# con un numero fisso, e più alto per i livelli alti. Risultato
		# misurato: i livelli 3 e 4 giocavano PEGGIO del 2, perché quella
		# penalità colpiva soprattutto le prese buone (dopo una presa il
		# tavolo resta per forza piccolo) e finivano per non prendere mai.
		#
		# Adesso è una probabilità: quante carte capaci di fare quella
		# scopa sono ancora fuori, diviso quante ne restano in giro. Chi
		# conta (livello 3+) lo sa davvero; chi non conta usa una stima.
		var dopo: Array = tavolo_dopo(tavolo, o)
		if not dopo.is_empty():
			var somma := 0
			for c in dopo:
				somma += valore(c)
			if somma <= 10:
				var p: float = 0.30
				if livello >= 3:
					var restano := 0
					for c in _non_viste():
						if valore(c) == somma:
							restano += 1
					var quante: int = maxi(_non_viste().size(), 1)
					p = clampf(3.0 * float(restano) / float(quante), 0.0, 1.0)
				v -= 13.0 * p
			# Lasciare il settebello o i denari in tavola costa comunque.
			for c in dopo:
				if c == SETTEBELLO:
					v -= 5.0
				elif e_denaro(c):
					v -= 0.9

	if livello >= 3:
		# Se il settebello è ancora fuori, il sette in mano serve a
		# pigliarlo: non si cala per niente.
		if not uscite.has(SETTEBELLO) and valore(carta) == 7 \
				and presa.is_empty():
			v -= 2.2
		# Alla fine del mazzo l'ultima presa vale il mucchio che resta.
		if mazzo.size() <= 6 and not presa.is_empty():
			v += 2.5
	return v
