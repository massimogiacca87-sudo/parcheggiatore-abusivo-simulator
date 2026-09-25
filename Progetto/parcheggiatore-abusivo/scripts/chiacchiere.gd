extends RefCounted
class_name Chiacchiere
## Quello che la gente ti dice quando ci parli (E).
##
## Un posto solo per tutte le battute dei passanti, e una funzione che
## sceglie quale è giusta ADESSO. Serve a due cose:
##
## 1. **Le frasi stanno insieme.** Sono la voce del gioco; averle sparse in
##    quattro script vuol dire che fra sei mesi metà sono di un tono e metà
##    di un altro.
## 2. **Il contesto lo decide una funzione sola.** Chi ti parla non deve
##    sapere niente di sospetto, orario e coppola: chiede una battuta e la
##    riceve.
##
## ## Il punto: la gente non ti vuole bene
##
## Il parcheggiatore abusivo, nella vita vera, è una figura che divide. Se
## tutti ti salutassero il gioco direbbe una cosa falsa e per giunta noiosa.
## Quindi la maggioranza è **ostile o indifferente**, e diventa gentile solo
## se ti sei guadagnato qualcosa:
##
##   - **'a coppola** ti fa passare per uno del quartiere, non per uno
##     venuto da fuori a fare soldi: raddoppia le probabilità di una
##     risposta amichevole. È l'oggetto che nel gioco non serviva a niente,
##     e adesso è quello che cambia il tono di tutta la strada.
##   - **il sospetto alto** ti rende un problema: se il quartiere sa che i
##     vigili ti stanno addosso, nessuno ci vuole parlare.
##   - **essere in servizio** ti rende il parcheggiatore; fuori dalla tua
##     piazza sei uno che passeggia, e ti trattano meglio.
##
## ## La sigaretta
##
## Se ne hai in tasca, ogni tanto uno se ne fuma una con te. È l'unica
## interazione che ha un effetto meccanico: costa una sigaretta e toglie
## sospetto, perché due che fumano appoggiati al muro non stanno facendo
## niente di male. È anche il motivo per cui vale la pena comprarne più di
## quante ne servono per Borrelli.

enum Tono { OSTILE, NEUTRO, AMICO, SIGARETTA, CUNZIGLIO }

# ---------------------------------------------------------------------------
# 'E CUNZIGLIE: 'O TUTORIALE CA PARLA NAPULITANO (0.56)
# ---------------------------------------------------------------------------
#
# Il capo, punto 4: *«Tra le frasi dei vari png, aggiungi frasi tutorial, che
# aiutino il player a capire certe meccaniche. Ad esempio qualcuno gli
# consiglia di comprare le sigarette al più presto perché un vero
# parcheggiatore senza sigarette nun s'è mai visto. Qualcun altro consiglia
# di controllare la bacheca dei lavori. I dialoghi sono sempre in pieno
# stile del gioco, napoletanamente e con spirito napoletano.»*
#
# C'è un pannello del tutorial dalla 0.52, e funziona: sei pagine che
# spiegano tutto. Il difetto è che si apre col tasto T, e il tasto T lo
# preme chi già sa che c'è. Chi non lo sa gira per la piazza senza sapere
# che esiste un armiere, una bacheca, una signora che ti dà i numeri.
#
# **'A regola ca tene tutto 'nzieme**: un consiglio si dice **solo se serve
# adesso**. Ogni voce ha una condizione, e se la condizione è falsa quella
# frase non esce proprio. Dire «accattate 'e sigarette» a uno che ne tiene
# venti non è un tutorial: è rumore, e peggio ancora insegna al giocatore
# che quello che gli dicono i passanti non conta niente. Con la condizione
# invece succede il contrario — ogni frase che senti parla di una cosa che
# ti manca **mo'**, e dopo due volte impari ad ascoltarli.
#
# Per lo stesso motivo un consiglio non si ripete due volte di fila, e più
# vai avanti con le giornate meno spesso arrivano: al quinto giorno sai già
# tutto, e uno che ti rispiega il mestiere diventa una seccatura.
#
# Ognuno è scritto come lo direbbe uno del quartiere, non come lo scriverebbe
# un manuale: «'a bacheca» e non «il tabellone delle missioni».

## Quanto spesso uno che ti parla, invece di mandarti a quel paese, ti dà un
## consiglio. Il primo giorno quasi una volta su due; dal quinto in poi una
## su sette, che è quanto basta per ricordartelo senza stufare.
const CUNZIGLIO_PRIMMO: float = 0.45
const CUNZIGLIO_DOPPO: float = 0.14
const CUNZIGLIO_JUORNE: int = 5

## L'ultimo consiglio detto, per non ripeterlo subito dopo.
static var _urdemo: String = ""

## Ogni voce: `id`, `dice` (la frase) e `quanno` (quando serve davvero).
## `quanno` è il nome di una funzione statica qua sotto: GDScript non tiene
## le lambda dentro alle costanti, e una tabella di stringhe si legge
## meglio di venti `if` in fila.
const CUNZIGLIE := [
	{"id": "sigarette", "quanno": "senza_sigarette",
	 "dice": "Guagliò, e va' a piglià 'e sigarette ô tabaccaio: 'nu parcheggiatore senza sigarette nun s'è maje visto."},
	{"id": "bacheca", "quanno": "maje_bacheca",
	 "dice": "Hê visto 'a bacheca sotto ê palazze? Ce stanno 'e lavure. Quaccuno pava bbuono."},
	{"id": "coppola", "quanno": "senza_coppola",
	 "dice": "Cu 'na coppola 'n capo te parlano n'ata manera, cride a me. Dudece euro, no cchiù."},
	{"id": "armiere", "quanno": "senza_ferro",
	 "dice": "Si te tocca menà, nun ce ghì cu 'e mmane: 'n fondo ô vico ce sta uno ca vènne. 'E mmane se stancano, 'o cric no."},
	{"id": "sciato", "quanno": "senza_sciato",
	 "dice": "Staje sciuscianno comm'a 'nu mantice. Piglia 'nu cafè ô banco, ca te rimette 'a meta' d''o sciato."},
	{"id": "vigile_sera", "quanno": "primma_d_e_vinte",
	 "dice": "'O vigile 'e vinte smonta e se ne va 'a casa. 'A sera 'a piazza è 'a toia: pienzace."},
	{"id": "stemme", "quanno": "tene_stemme",
	 "dice": "Chelli stemme ca tiene 'n sacca: 'O Zio t''e ccatta. Ma nun t''e ffà vedé mentre 'e vinne."},
	{"id": "ombrellone", "quanno": "suspetto_auto",
	 "dice": "Quanno 'o vigile te sta 'ncuollo, miettete sott'a ll'ombrellone o assettate 'nu poco. Chi sta fermo nun dà fastidio a nisciuno."},
	{"id": "cornetto", "quanno": "malamente",
	 "dice": "Staje malamente. 'A notte â cornetteria fanno 'o cornetto cu 'a crema: chillo t'arremette 'nu poco."},
	{"id": "lotto", "quanno": "sera_e_senza_lotto",
	 "dice": "Ce sta 'na signora ca dà 'e nummere. 'Na vota ncopp'a vinte 'nduvina overo — e 'na vota ncopp'a vinte basta e avanza."},
	{"id": "piazza", "quanno": "tene_sorde",
	 "dice": "Cu chilli sorde ca tiene te puó piglià n'ata piazza. Chi tene doje piazze nun fatica 'a stessa manera."},
	{"id": "pallone", "quanno": "sempe",
	 "dice": "'E guagliune cu 'o pallone: si nzerti 'nu gol dint'â porta lloro, quaccuno te dà pure 'nu poco 'e sorde. Ma nun fà 'o furbo, ca doppo quatto nun pavano cchiù."},
	{"id": "salotto", "quanno": "piazza_scarrupata",
	 "dice": "'A piazza toia pare 'nu deserto. 'Nu poco 'e piante, 'na radio, e chille ca parcheggiano te pavano meglio. 'O bazar sta llà."},
	{"id": "fischio", "quanno": "sempe",
	 "dice": "Fischia [F] quanno vide ca uno cerca 'o posto, ca chillo te sente 'a luntano. Ma fischia sulo si 'o vigile nun te guarda."},
	{"id": "regia", "quanno": "sempe",
	 "dice": "Mentre 'e faje manuvrà, statte accuorto ô vigile: chillo te vede 'e braccia a mulino e capisce tutto cosa."},
	# --- 0.61 ---
	{"id": "guagliuni_sera", "quanno": "guagliuni_cu_sorde",
	 "dice": "'O guaglione tuoio te sta aspettanno cu 'e sorde 'n mano. Si stasera nun ce passe, se ne tene 'a mità."},
	{"id": "testimoni", "quanno": "sempe",
	 "dice": "Si hê 'a fà 'na cosa storta, falla addò nun ce sta nisciuno. Cchiù gente te vede, cchiù 'o quartiere chiacchiarea."},
	{"id": "garage", "quanno": "sempe",
	 "dice": "'O ricettatore sott'ô stadio piglia tre machine 'o juorno, no una 'e cchiù. E 'e paga sempe meno: nun è 'nu mestiere, è 'na tentazione."},
	{"id": "panaro", "quanno": "sempe",
	 "dice": "Donna Filumena cala 'o panaro doje vote 'o juorno. Tienete quacche sigaretta 'n sacca, ca chella pava e te benedice."},
	{"id": "turista", "quanno": "sempe",
	 "dice": "'E turiste se perdono sempe, cu 'sta cartina aperta 'a smerza. Si ne puorte uno addò vò ì, 'a mancia è bbona."},
	{"id": "gennarino", "quanno": "tene_piazze",
	 "dice": "Ce sta 'nu guaglione c''o berretto russo ca va facenno 'o parcheggiatore dint'ê piazze 'e ll'ate. Si 'o truove dint'â toja, parlace: o 'o cacce, o 'o piglie a faticà."},
]


static func _cunziglie_bbone() -> Array:
	var fore: Array = []
	for c in CUNZIGLIE:
		if str(c["id"]) == _urdemo:
			continue
		if _serve(str(c["quanno"])):
			fore.append(c)
	return fore


## Le condizioni, una per riga. Sono tutte domande a cui il GameManager sa
## già rispondere: qui non si tiene stato, si guarda.
static func _serve(quanno: String) -> bool:
	match quanno:
		"sempe":
			return true
		"senza_sigarette":
			return GameManager.cigarettes <= 0
		"maje_bacheca":
			return GameManager.commissioni_viste == 0
		"senza_coppola":
			return not GameManager.has_upgrade("coppola") \
				and GameManager.money >= 12
		"senza_ferro":
			return GameManager.arma_in_mano == "" \
				and GameManager.money >= 22
		"senza_sciato":
			return GameManager.sciato < GameManager.SCIATO_MAX * 0.35
		"primma_d_e_vinte":
			var ora: float = GameManager.ora_d_o_juorno()
			return ora >= 16.0 and ora < 20.0
		"tene_stemme":
			return GameManager.emblem_count() > 0
		"suspetto_auto":
			return GameManager.heat > 45.0
		"malamente":
			return GameManager.health < GameManager.HEALTH_MAX * 0.5
		"sera_e_senza_lotto":
			return GameManager.ora_d_o_juorno() >= 18.0
		"tene_sorde":
			return GameManager.money >= GameManager.NEXT_ZONE_GOAL
		"guagliuni_cu_sorde":
			return GameManager.cassa_in_giro() > 0 \
				and GameManager.ora_d_o_juorno() >= 19.0
		"tene_piazze":
			return GameManager.zone_mie.size() >= 1 and GameManager.giornata >= 2
		"piazza_scarrupata":
			return GameManager.placed_decor.is_empty() \
				and GameManager.money >= 26
	return false


## Quanto spesso escono i consigli, adesso.
static func quanto_spisso() -> float:
	if GameManager.giornata <= CUNZIGLIO_JUORNE:
		return lerpf(CUNZIGLIO_PRIMMO, CUNZIGLIO_DOPPO,
			float(GameManager.giornata - 1) / float(CUNZIGLIO_JUORNE))
	return CUNZIGLIO_DOPPO


## Un consiglio che serve adesso, o stringa vuota se non ce n'è nessuno.
static func cunziglio(rng: RandomNumberGenerator) -> String:
	var bbone: Array = _cunziglie_bbone()
	if bbone.is_empty():
		return ""
	var c: Dictionary = bbone[rng.randi() % bbone.size()]
	_urdemo = str(c["id"])
	return str(c["dice"])

const OSTILI := [
	"E chi t'ha chiammato, a te?",
	"'O posto è pubblico! PUB-BLI-CO!",
	"Vuje site 'a rovina 'e chesta città.",
	"Nun te dò niente. Chiamma 'e vigile, va'.",
	"Mio cognato pava 'o bollo, 'a benzina e pure a te?",
	"Lavora, guagliò! Lavora!",
	"Ogne vota ca esco, sta uno comm'a te.",
	"E che è, 'o pizzo?",
	"'Nu juorno 'e chiste ve levano 'a miezo, a tutte quante.",
	"'A macchina 'a lasso addò me pare, e nun pavo a nisciuno.",
	"Ma 'o vigile addò sta quanno serve?",
	"Nun me guardà accussì ca nun me faje paura.",
]
const NEUTRI := [
	"Uè.",
	"Permesso...",
	"Che ora s'è fatta?",
	"Fa 'na callara oggi, eh.",
	"Scusate, 'o mercato 'a che parte sta?",
	"Mm-mm.",
	"Nun tengo tiempo, mi dispiace.",
	"'O Napule stasera comme va a fernì?",
	"Hê visto 'o turista cu 'a cartina? Gira 'a stammatina.",
	"'O panettiere ha aumentato 'o ppane n'ata vota.",
	"Chiove? Nun chiove? Boh.",
]
const AMICI := [
	"Uè bello! Tutt'appost?",
	"Statte buono, neh.",
	"Chi tene 'a coppola tene 'a capa.",
	"T'aggio visto ll'ata sera. Bravo, eh.",
	"'A famiglia? Tutti buono?",
	"Uè, 'o guaglione d''a piazza!",
	"Si te serve 'na mano, 'o ssaje addò sto.",
	"Forza Napule sempe!",
	"Uè, 'o parcheggiatore! Stamme bbuono, ca 'a machina mia 'a guarde tu.",
	"Donna Filumena parla sempe bbuono 'e te.",
	"Tu sî 'nu signore. 'E l'ati parcheggiature nun pozzo dicere 'o stesso.",
]
const SIGARETTA := [
	"Me ne daje una? ... Grazie assaje.",
	"Tiene 'na sigaretta? Che Dio t'ha manna buono.",
	"Una a te e una a me, e ce facimmo 'nu penziero.",
	"'Sta sigaretta era proprio chello ca ce vuleva.",
]
## Se non ne hai, chi te la chiede resta con niente in mano.
const NIENTE_SIGARETTE := [
	"Nun tiene manco 'na sigaretta? E che parcheggiatore sî?",
	"Niente sigarette? Mmm. Vabbuo'.",
]
## Di notte cambia tutto: chi è in giro alle undici non è la stessa gente.
const NOTTE := [
	"A chest'ora? E che vuo'?",
	"Vattenne a casa, guagliò.",
	"'A notte 'a chesta zona nun ce se sta.",
	"Tu 'a casa nun ce vaje maje?",
	"'A notte è d''e gatte e d''e mariuole. Tu che sî?",
	"Stateve accorto, ca a chest'ora gira gente strana.",
]
## Chi ti trova mentre i vigili ti stanno addosso.
const SCOTTATO := [
	"Uè, statte 'a luntano ca staje ne' guaje.",
	"Nun te cunosco. Nun t'aggio visto. Ciao.",
	"'E guardie te stanno cercanno, 'o ssaje?",
]


## Quanto sospetto toglie una sigaretta fumata insieme a uno.
const CALMA_SIGARETTA: float = 9.0


## Sceglie il tono giusto per questo momento. `rng` si passa da fuori così
## due passanti vicini non dicono la stessa cosa nello stesso istante.
static func scegli_tono(rng: RandomNumberGenerator, notte: bool) -> int:
	# Sopra questa soglia il quartiere sa che sei nei guai, e non c'è
	# coppola che tenga.
	if GameManager.heat > 62.0:
		return Tono.OSTILE
	if notte:
		return Tono.NEUTRO

	var p_amico := 0.18
	if GameManager.has_upgrade("coppola"):
		p_amico += 0.22
	if not GameManager.in_servizio:
		# Fuori dalla piazza tua non stai chiedendo soldi a nessuno, e si
		# vede: la gente ti tratta come uno che passeggia.
		p_amico += 0.12
	# La reputazione conta, ma poco: si costruisce in tanti turni.
	p_amico += clampf(float(GameManager.reputation) * 0.01, -0.1, 0.15)

	var r := rng.randf()
	if r < p_amico:
		# Chi è amichevole, ogni tanto, si fuma una sigaretta con te.
		return Tono.SIGARETTA if rng.randf() < 0.30 else Tono.AMICO
	# Il resto si divide fra chi ti manda a quel paese e chi tira dritto.
	# In servizio dentro alla piazza tua sei il parcheggiatore, e lì la
	# gente è molto più cattiva.
	var p_ostile := 0.55 if GameManager.in_servizio else 0.34
	return Tono.OSTILE if rng.randf() < p_ostile else Tono.NEUTRO


## La battuta vera e propria. Restituisce anche cosa è successo, perché la
## sigaretta ha un effetto e il chiamante deve saperlo per suonare il verso
## giusto.
static func battuta(rng: RandomNumberGenerator, notte: bool) -> Dictionary:
	# **'O cunziglio passa 'nnanze a tutto** — ma solo se ce n'è uno che
	# serve adesso, e solo se non sei nei guai: uno che ha i vigili alle
	# calcagna non si ferma a spiegarti il mestiere.
	if GameManager.heat <= 62.0 and rng.randf() < quanto_spisso():
		var c: String = cunziglio(rng)
		if c != "":
			return {"testo": c, "tono": Tono.CUNZIGLIO}
	if GameManager.heat > 62.0 and rng.randf() < 0.6:
		return {"testo": SCOTTATO[rng.randi() % SCOTTATO.size()],
			"tono": Tono.OSTILE}
	if notte and rng.randf() < 0.55:
		return {"testo": NOTTE[rng.randi() % NOTTE.size()],
			"tono": Tono.NEUTRO}

	var t := scegli_tono(rng, notte)
	match t:
		Tono.OSTILE:
			return {"testo": OSTILI[rng.randi() % OSTILI.size()], "tono": t}
		Tono.AMICO:
			return {"testo": AMICI[rng.randi() % AMICI.size()], "tono": t}
		Tono.SIGARETTA:
			if GameManager.cigarettes <= 0:
				return {"testo":
					NIENTE_SIGARETTE[rng.randi() % NIENTE_SIGARETTE.size()],
					"tono": Tono.NEUTRO}
			# La sigaretta si consuma davvero, e il sospetto scende: due che
			# fumano appoggiati al muro non stanno facendo niente di male, e
			# il vigile che passa vede due che chiacchierano.
			GameManager.consume_cigarette()
			GameManager.add_heat(-CALMA_SIGARETTA)
			return {"testo": SIGARETTA[rng.randi() % SIGARETTA.size()],
				"tono": t}
		_:
			return {"testo": NEUTRI[rng.randi() % NEUTRI.size()],
				"tono": Tono.NEUTRO}


## Il suono che accompagna la battuta. Non è decorazione: è quello che dice
## al giocatore com'è andata prima ancora che legga il testo.
static func suono(tono: int) -> void:
	match tono:
		Tono.OSTILE:
			SoundManager.play("fail", -14.0, 0.85)
		Tono.SIGARETTA:
			SoundManager.play("pop", -12.0, 0.7)
		Tono.AMICO:
			SoundManager.play("pop", -13.0, 1.3)
		Tono.CUNZIGLIO:
			# Un verso suo, più basso: chi ti dà un consiglio non ti sta
			# né salutando né mandando a quel paese, e si deve sentire.
			SoundManager.play("pop", -11.0, 0.92)
		_:
			SoundManager.play("pop", -18.0, 1.0)
