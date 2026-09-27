extends Node
## GameManager
## Autoload singleton: tiene lo stato persistente della partita (denaro,
## reputazione, sospetto dei vigili, timer del turno) e lo condivide fra
## tutte le zone/scene tramite segnali.

signal money_changed(new_amount: int)
signal heat_changed(new_heat: float)
signal reputation_changed(new_reputation: int)
signal shift_time_changed(seconds_left: float)
signal shift_ended(summary: Dictionary)
signal player_caught()
signal directing_started()
signal directing_update(progress: Dictionary)
signal directing_bump(bump_count: int)
signal directing_ended(score: float, aborted: bool)
signal directing_released() # il player molla la presa volontariamente: l'auto resta ad aspettare, nessun esito da mostrare
signal directing_gesture(text: String, from_driver: bool) # urla del parcheggiatore (false) e battute di autisti/NPC (true)
signal inventory_changed(emblems: Dictionary)
signal event_started(text: String) # banner a schermo per eventi (ondata partita, commissioni...)
signal screen_shake(amount: float)
signal commission_changed()
signal upgrade_purchased(upgrade_id: String)
signal cigarettes_changed(count: int)
signal health_changed(new_health: float)
## Il boss di fine turno. furia 0..100; active=false quando se n'è andato.
signal boss_state_changed(furia: float, active: bool)
## Qualcuno ha chiamato 'O Duttore. Lo ascolta la piazza, che lo fa
## arrivare subito invece di aspettare la notte.
signal chiama_borrelli()
signal boss_dialogue_opened(answers: Array)
signal boss_dialogue_closed()
## Attività secondarie
signal pickpocket_started(target: Node)   # apre la barra del borseggio
signal pickpocket_closed()
signal goal_scored(total: int)            # pallone dentro la porta
signal decor_placed(indice: int, id: String, pos: Vector3, rot: float)
signal decor_rimosso(indice: int, id: String)
signal caffe_changed(quante: int)
signal fischio_suonato()
signal reinforcements_called()            # i carabinieri stanno arrivando
signal player_hurt(amount: float, cause: String) # per il flash rosso e lo scossone

## Hai menato qualcuno che le prende sul serio: vigile, rivale, autista,
## pattuglia. Serve al HUD per tirare su la barra HP del bersaglio.
##
## Senza, un combattimento era alla cieca: davi mazzate e non sapevi se
## mancavano due colpi o dodici. Con quaranta punti addosso a un rivale e
## tre di danno a mani nude, "sono troppo forti" era anche questo — non si
## vedeva nessun progresso.
signal nemico_colpito(nome: String, hp: int, hp_max: int)

## Le stelle di ricercato. Zero = nessuno ti sta cercando.
signal stelle_cambiate(quante: int)
## Ti hanno afferrato: il HUD apre la barra della colluttazione.
signal presa_iniziata()
signal presa_finita()
## Quanto manca a sciogliersi (0..1) e quanto tempo resta (0..1).
signal presa_stato(forza: float, tempo: float)
signal manifesto_fotografato(id: String, titolo: String, quanti: int, totale: int)
signal collezione_completa()

## Sei entrato o uscito da una piazza tua. Vedi `in_servizio`.
signal servizio_cambiato(attivo: bool, nome_piazza: String)

const HEAT_MAX: float = 100.0
## **Un parcheggiatore non è un pugile.**
##
## Con cento punti di ossa e il recupero fino a settanta, prendersi due
## sprangate era un contrattempo. Settantadue e recupero fino a
## quarantotto vogliono dire che una rissa la si comincia sapendo che si
## finisce male, ed è l'unica cosa che rende sensato scappare.
const HEALTH_MAX: float = 72.0
## Fiatone: dopo qualche secondo senza prenderle si recupera piano, ma non
## si torna mai al massimo da soli. Per rimettersi bene serve una sigaretta.
const HEALTH_REGEN_DELAY: float = 7.0
const HEALTH_REGEN_RATE: float = 2.2
const HEALTH_REGEN_CAP: float = 48.0
## A quanti secondi dalla fine del turno arriva Borrelli.
## Quando mancano questi secondi alla fine del turno, arriva Borrelli.
## Con un turno da 180 secondi vuol dire che esce dopo 1 minuto e 35 di
## gioco. Prima erano 70 (cioe' a 1'50"), ma quel minuto e mezzo era in
## buona parte vuoto — le auto arrivavano col contagocce — e l'attesa
## sembrava molto piu' lunga di quello che era davvero.
## Il boss non arriva piu' a cronometro: arriva quando e' notte. Questi
## sono i secondi di attesa dopo che e' calato il buio.
const BOSS_DOPO_NOTTE_MIN: float = 22.0
const BOSS_DOPO_NOTTE_MAX: float = 42.0
const BOSS_APPEARS_AT: float = 85.0 # non piu' usato, tenuto per i salvataggi
## Quanti secondi prima si sente arrivare. Un boss che compare e basta
## sembra un bug; uno annunciato e' una scena.
const BOSS_WARNING_AT: float = 97.0
## Quanto ti lascia in mano averlo convinto.
const BOSS_REWARD: int = 25
## Quanto paga un gol coi guaglioni.
const GOAL_REWARD: int = 4
const NEXT_ZONE_GOAL: int = 40 # € totali per sbloccare la Strada Principale
## **Il sospetto scendeva quattro punti al secondo, e cancellava tutto.**
##
## Misurato: con un'azione rischiosa ogni dieci secondi per tre minuti, il
## sospetto arrivava al massimo a 19 e stava in media a 2 — con la soglia
## per far venire il vigile a parlare che sta a 42. Cioe' il vigile non
## poteva accorgersi di te nemmeno se ci provava: qualunque cosa facessi
## evaporava in tre secondi.
##
## A 0,8 il conto torna: un'azione vista vale venti punti e nei dieci
## secondi dopo se ne perdono otto, quindi lavorare sporco sotto i suoi
## occhi ti porta alla soglia in un minuto e mezzo. E resta il modo di
## calmarlo: la sigaretta, il caffe', la sedia, e parcheggiare bene.
const AMBIENT_COOL_RATE: float = 0.8
const SEEN_HEAT_MULTIPLIER: float = 2.0 # essere colti sul fatto da un vigile pesa il doppio
# ---------------------------------------------------------------------------
# 'E stelle: quanto sei ricercato
# ---------------------------------------------------------------------------
#
# **Perche' il "sospetto" non bastava.**
#
# Il sospetto dei vigili misura una cosa sola: quanto stai lavorando male
# NELLA TUA PIAZZA. Sale quando chiedi i soldi davanti al vigile, scende da
# solo, e la punizione e' la multa. E' una meccanica da turno di lavoro.
#
# La violenza gratuita e' un'altra cosa e vuole un'altra risposta. Se meni
# tre passanti in mezzo alla strada non e' che "lavori male": e' che mezzo
# quartiere ha chiamato il 112. Da qui le stelle, che funzionano come in
# GTA e per lo stesso motivo — sono una misura che il giocatore capisce a
# colpo d'occhio, e che dice *quanti* ne stanno arrivando.
#
# La differenza col sospetto e' anche nel modo di toglierle: il sospetto
# scende col tempo e con la sigaretta, le stelle scendono solo se **non ti
# vede nessuno**. Cioe' ti devi nascondere davvero.
const STELLE_MAX: int = 5
## Quanti punti di crimine vale una stella.
const PUNTI_PER_STELLA: float = 2.0
## Quanti punti si perdono al secondo mentre nessuno ti vede.
const STELLE_CALO: float = 0.42
## Quanti secondi di invisibilita' servono prima che il calo cominci: se no
## bastava girare l'angolo per un istante.
const STELLE_ATTESA: float = 2.5

var stelle: int = 0
var _crimine: float = 0.0
var _visto_dalla_legge: bool = false
var _fuori_vista: float = 0.0

const SAVE_PATH := "user://save.json"

## La versione del salvataggio.
##
## Serve a una cosa sola, ma indispensabile: il gioco è cambiato sotto ai
## piedi di chi ci stava già giocando. La regola "si comincia senza niente"
## veniva applicata solo alla primissima partita — chi aveva un `save.json`
## in giro si ritrovava ancora i soldi e la roba della versione vecchia, e
## il tutorial economico non partiva mai. Alzando questo numero il
## portafoglio e lo zaino si azzerano una volta sola, al primo avvio dopo
## l'aggiornamento. La collezione (manifesti, figurine) non si tocca: quella
## è roba guadagnata, non comprata.
const SAVE_VER := 2

## La versione letta dal file. 1 = salvataggio precedente al numero.
var save_version: int = SAVE_VER

const EMBLEM_NAMES := ["Cavallino Sfrenato", "Tridente d'Argento", "Stella a Quattro Punte"]
const COMMISSION_CHANCE: float = 0.45
const COMMISSION_MULT: int = 3

## Le zone giocabili: stessa logica, layout e ritmo diversi.
# ---------------------------------------------------------------------------
# 'O carattere d''e piazze
# ---------------------------------------------------------------------------
#
# **Quatte piazze eguale nun so' quatte piazze: so' una cchiù grossa.**
#
# Fino alla 0.54 conquistare il mercato o lo stadio cambiava una cosa sola:
# **dove** stavi. Il rubinetto era lo stesso (`posteggio_3d.OGNI_MIN`), la
# mancia era la stessa, i vigili erano lo stesso numero. Quattrocentocinquanta
# euro per avere lo stesso lavoro venti metri più in là.
#
# La roadmap chiedeva tre cose precise — *"una rende poco ma è tranquilla,
# una rende molto ma ha due vigili, una lavora solo di notte"* — e sono
# tre modi diversi di dire la stessa parola: **scelta**. Se le piazze sono
# uguali, comprare la seconda è una somma; se sono diverse, è una
# decisione, e cambia pure come giochi la giornata (di notte si va alla
# cornetteria, la mattina al mercato).
#
# Quattro numeri per piazza, e si moltiplicano a quelli dell'ora e della
# giornata che ci sono già:
#
#   `auto`     quanto spesso arrivano (1 = come la piazza tua)
#   `mancia`   quanto lasciano
#   `vigili`   quanti ne girano
#   `notte`    quanto cambia tutto dopo il tramonto
#
# `prova_piazze` misura quanto rende ognuna in una giornata intera: devono
# essere **diverse fra loro** e nessuna deve rendere il doppio di un'altra,
# se no la scelta è finta (ce n'è una giusta e basta).
const CARATTERE := {
	"piazza": {
		"nome": "'a casa",
		"auto": 1.0, "mancia": 1.0, "vigili": 1, "notte": 1.0,
		"che": "'A piazza toia. Nè 'a cchiù ricca nè 'a cchiù facile, ma è 'a casa.",
	},
	"mercato": {
		# Tanta gente e poche lire: chi fa la spesa conta le monete. In
		# compenso il vigile al mercato non ci sale mai — c'è troppa
		# confusione, e a lui non piace.
		"nome": "poco e tranquillo",
		"auto": 1.3, "mancia": 0.68, "vigili": 0, "notte": 0.30,
		"che": "Tanta ggente, poche sorde. Ma 'o vigile ccà nun ce sale maje.",
	},
	"stadio": {
		# Il posto dove si fanno i soldi veri, e infatti è sorvegliato.
		"nome": "assaje ma pericoloso",
		"auto": 1.1, "mancia": 1.34, "vigili": 2, "notte": 1.1,
		"che": "Ccà se fanno 'e sorde overe. E ccà stanno duje vigile.",
	},
	"cornetteria": {
		# **"Lavora solo di notte" mo' se pò scrivere overo.** Di giorno è
		# un vicolo morto: un'auto ogni quattro. Dopo mezzanotte è il
		# posto dove finisce tutto il quartiere.
		"nome": "sulo 'a notte",
		# **0.64: 0,34 → 0,45 di giorno, 4,6 → 3,5 di notte.** Il capo ha
		# chiesto che una piazza presa lavori «come la tua»: con un'auto
		# ogni minuto e mezzo, chi ci entrava di giorno pensava che fosse
		# rotta. La notte resta uguale (0,45 × 3,5 ≈ 0,34 × 4,6), il giorno
		# resta il più morto delle quattro.
		"auto": 0.45, "mancia": 1.3, "vigili": 1, "notte": 3.5,
		"che": "'E juorno nun ce sta n'anema. 'A notte è n'ata cosa.",
	},
}


func carattere(zona: String) -> Dictionary:
	return CARATTERE.get(zona, CARATTERE["piazza"])


## Quanto è fitta l'ondata di auto in questa piazza: **più basso = più
## spesso**, perché è un moltiplicatore sull'attesa. Di notte il carattere
## della piazza si sente il doppio.
func attesa_piazza(zona: String) -> float:
	var c: Dictionary = carattere(zona)
	var q: float = float(c["auto"])
	if fascia_indice() >= 4:
		q *= float(c["notte"])
	return 1.0 / maxf(0.08, q)


## Quanto lascia un cliente in questa piazza.
func mancia_piazza(zona: String) -> float:
	var m: float = float(carattere(zona)["mancia"])
	# **'A parte 'e Donna Carmela.** Se hai accettato il suo patto, per tre
	# giornate il mercato rende il trenta per cento in meno: lei non
	# voleva soldi subito, voleva una parte — ed è una scelta che costa
	# poco oggi e si sente per tre giorni.
	if zona == "mercato" and boss_parte_juorne > 0:
		m *= (1.0 - BOSS_PARTE_QUOTA)
	return m


const ZONES := {
	"vicolo": {
		"name": "La Piazza", "width": 34.0, "length": 54.0,
		"spots_right": 5, "spots_left": 4, "max_cars": 5,
		# Il ritmo e' molto piu' lento di prima: la mappa adesso e' un
		# quartiere da attraversare, non una piazza sola. Fra un'auto e
		# l'altra passano venticinque-trentadue secondi, e in quel tempo
		# ci si va a fare un giro invece di stare fermi ad aspettare.
		"spawn_min": 26.0, "spawn_max": 34.0, "vigili": 1,
	},
	"strada": {
		"name": "La Strada Principale", "width": 40.0, "length": 68.0,
		"spots_right": 6, "spots_left": 6, "max_cars": 7,
		"spawn_min": 22.0, "spawn_max": 28.0, "vigili": 2,
	},
}

# ---------------------------------------------------------------------------
# Quanto vale, in numeri, ogni cosa che si compra
# ---------------------------------------------------------------------------
#
# **Il Bazar vendeva scenografia.** Sedia, ombrellone, tavolino, radio,
# piante e luminarie: centosettantuno euro di roba che veniva costruita in
# mezzo alla piazza e poi non la leggeva nessuno. Erano bei mobili in un
# gioco dove i soldi si contano.
#
# Adesso ognuna fa una cosa sola, chiara, e che si sente. Tre sono
# **fisiche** — valgono dove stanno, quindi dove le appoggi conta: la sedia
# e il tavolino si usano con [E], sotto all'ombrellone il vigile non ti
# vede. Tre sono **d'ambiente** e valgono in tutta la piazza tua: la radio
# tiene buoni i clienti, le piante fanno pagare meglio, le luminarie
# accendono la piazza quando cala la notte.
#
# In piu' ogni pezzo appoggiato fa arrivare le auto un filo piu' spesso:
# una piazza curata e' una piazza dove la gente parcheggia.

## Raggio dell'ombra dell'ombrellone. Tre metri: ci stai sotto tu, non
## mezza piazza.
const OMBRA_RAGGIO: float = 3.0
## Ogni quanto sul tavolino ricompare una tazzulella.
const TAVOLINO_ATTESA: float = 50.0
## Quanto sospetto si porta via un minuto di sedia, e quante ossa rimette.
const SEDIA_CALMA: float = 6.0    # al secondo
## Le ossa che si rimettono a posto stando seduti. Alzate da 3,2 a 7: la
## sedia costa venti euro e ti costa il tempo in cui non lavori, e in cambio
## dev'essere il posto dove ci si rimette in sesto davvero — l'ospedale dei
## poveri. Dieci secondi di sdraio valgono settanta punti di salute.
const SEDIA_OSSA: float = 7.0     # al secondo
## Quanti soldi il borsello tiene fuori dai conti di chi ti perquisisce.
const BORSELLO_SICURO: int = 60
## Quanto si accorcia l'attesa fra un'auto e l'altra per ogni pezzo di
## decoro appoggiato in piazza (sei pezzi = un quarto di tempo in meno).
const DECORO_ARRIVI: float = 0.04
## Le luminarie, di notte.
const LUMINARIE_ARRIVI: float = 0.65   # moltiplicatore dell'attesa
const LUMINARIE_MANCIA: float = 1.25

## Tutto ciò che si compra in giro per la piazza.
## - da 'O Zio (banchetto): gli upgrade "di mestiere"
## - al Bazar: le decorazioni per il proprio angolo di piazza
const UPGRADES := {
	"gilet": {"name": "Gilet Catarifrangente Fasullo", "cost": 30,
		"desc": "metà sospetto dalle azioni rischiose — e +6% ca 'o cliente paga: pare ca tiene 'o diritto", "icona": "gilet"},
	"fischietto": {"name": "Fischietto Professionale", "cost": 25,
		"desc": "gli autisti reagiscono più svelti e ti danno più tempo", "icona": "fischietto"},
	"paletta": {"name": "Paletta da Posteggiatore", "cost": 45,
		"desc": "dirigi le auto anche da lontano, come uno che comanda davvero", "icona": "paletta"},
	"occhiali": {"name": "Occhiali da Sole", "cost": 14,
		"desc": "'nu terzo 'e suspetto 'nmeno quanno te vede — e +8% 'e mancia: nun te leggeno 'nfaccia", "icona": "occhiali"},
	"borsello": {"name": "Borsello p''e Spiccioli", "cost": 16,
		"desc": "€%d stanno 'o sicuro d''a cauzione e d''e sequestre — e +6%% 'e mancia: nun se perde 'nu spicciulo" % BORSELLO_SICURO, "icona": "borsello"},
	"coppola": {"name": "Coppola", "cost": 12,
		"desc": "pare ca sî d''o quartiere: +8% ca 'o cliente paga, e 'a gente te parla meglio", "icona": "coppola"},
	# **'O ferro storto** (0.57). Fino alla 0.56 gli attrezzi servivano tutti
	# a farti pagare meglio dai clienti; questo serve all'altro mestiere. È
	# caro apposta: costa più di una giornata di posteggio, e si ripaga con
	# la prima macchina che porti al garage.
	"grimaldello": {"name": "Grimaldello", "cost": 55,
		"desc": "'a finestra d''o scasso è 'nu quinto cchiù larga e 'o cursore va cchiù chiano: 'e mmacchine toste addeventano possibbele", "icona": "grimaldello"},
	"sedia": {"name": "Sedia Sdraio", "cost": 20,
		"desc": "t'assiette (E): 'o suspetto cala, 'e ossa se rimettono — e 'a gente te lassa 'o spicciariello", "icona": "sedia"},
	"ombrellone": {"name": "Ombrellone", "cost": 25,
		"desc": "%d metre addó 'o vigile nun te vede — e ll'auto a ll'ombra lassano +14%% 'e mancia" % int(OMBRA_RAGGIO), "icona": "ombrellone"},
	"tavolino": {"name": "Tavolino", "cost": 18,
		"desc": "'na tazzulella 'e cafè aggratis ogni %d secunne (E): nun paghe cchiù 'o bar" % int(TAVOLINO_ATTESA), "icona": "tavolino"},
	"radio": {"name": "Radio a Transistor", "cost": 22,
		"desc": "'e clienti aspettano cantanno: +45% 'e pacienza dint''a piazza toja", "icona": "radio"},
	"piante": {"name": "Tre Piante in Vaso", "cost": 26,
		"desc": "'a piazza pare curata: +7% ca pavano e +12% 'e mancia", "icona": "piante"},
	"luminarie": {"name": "Luminarie da Festa", "cost": 60,
		"desc": "'a notte 'a piazza è allummata: ll'auto arrivano cchiù spisso e 'e mance songo +25%", "icona": "luminarie"},
}

## Quali voci sono decorazioni (vendute al Bazar e piazzate in zona).
const DECOR_IDS := ["sedia", "ombrellone", "tavolino", "radio", "piante", "luminarie"]
## Quali sono upgrade di mestiere (venduti da 'O Zio).
const TOOL_IDS := ["gilet", "fischietto", "paletta", "occhiali", "borsello",
	"coppola", "grimaldello"]
## Quali si vedono addosso al personaggio.
const COSMETIC_IDS := ["gilet", "occhiali", "borsello", "coppola", "paletta"]
## Quali si USANO premendo un tasto, invece di funzionare da soli.
## Il fischietto era un bonus passivo e basta: adesso e' un verbo.
const USABLE_IDS := ["fischietto"]

## **'E ffierre.**
##
## Quattro armi, e servono a una cosa sola: prendersi una zona senza
## pagarla. I parcheggiatori delle altre zone hanno quaranta punti di
## salute e menano forte — a mani nude sono quaranta pugni mentre lui te
## ne dà uno ogni secondo, e il conto non torna mai.
##
##   danno    quanti colpi per stendere un rivale da 40
##   ------   ------------------------------------------
##   mano  1  quaranta. Non si fa.
##   mazza 3  quattordici. Ci provi e finisci all'ospedale.
##   curti 6  sette. Si può fare, se lo prendi di sorpresa.
##   fierro 13 tre. Ma è un colpo a distanza, e si sente.
##   kalash 26 due. E dopo scappa, perché è mezza città che t'ha sentito.
##
## `calore` è quanto sospetto alza OGNI colpo. Il coltello fa più rumore
## sociale della mazza, e la pistola più di tutti e due: è il prezzo che
## paghi per la scorciatoia, e il motivo per cui comprare la zona resta
## un'opzione sensata anche quando hai il fierro in tasca.
## **Le armi, e i numeri che ci stanno dietro.**
##
## Un rivale ha quaranta punti di vita e te ne toglie undici a botta: nove
## colpi suoi e sei all'ospedale. Da qui si ricava tutto il resto, perche'
## la domanda a cui questi numeri rispondono e' una sola — *con che cosa in
## mano ce la posso fare?*
##
##   mani nude  2 danni → 20 colpi. Impossibile, e deve restare impossibile:
##              e' il muro che ti manda a comprare un'arma.
##   'a mazza   7 danni →  6 colpi. Si puo' fare, ma devi arretrare fra un
##              colpo e l'altro. E' il primo vero salto.
##   'o curtiello 12 →   4 colpi. Comodo.
##   'o fierro  22 danni →  2 colpi, e da sedici metri: non ti tocca proprio.
##   'o Kalash  40 danni →  1 colpo. Costa novecento euro, e si vede.
##
## Prima erano 3/6/13/26 con le mani a 1: la mazza voleva quattordici colpi
## e il curtiello sette, cioe' le due armi comprabili all'inizio non
## cambiavano niente. Era il motivo per cui i rivali sembravano invincibili
## anche dopo aver speso.
# ---------------------------------------------------------------------------
# 'O sciato
# ---------------------------------------------------------------------------
#
# **'E pugne erano 'a risposta a tuttecose, e nun costavano niente.**
#
# Il capo: *"questo overhaul dovrebbe risolvere definitivamente il problema
# dei pugni come risoluzione troppo semplice dei problemi"*. È la
# diagnosi giusta di una cosa che si trascina da sei versioni: il
# pagamento forzato, il rivale, il boss, il passante che ti sta antipatico
# — tutto si chiudeva pigiando il tasto sinistro abbastanza volte. Non
# perché fosse potente: perché era **gratis e infinito**.
#
# Le cure provate fin qui hanno alzato il prezzo *dopo* (le stelle della
# 0.52, le ossa della 0.54, il rapporto della 0.54). Nessuna ha toccato la
# cosa vera, che è **quanti pugni puoi tirare di fila**.
#
# Il fiato è un serbatoio che si svuota in fretta e si riempie piano:
#
#   * **sette-otto pugni e sei a zero**, e a zero non meni più;
#   * correre lo consuma, ma lentamente — una traversata non ti svuota;
#   * si ricarica da solo **pianissimo** (un pugno ogni venti secondi);
#   * **'o cafè ne rimette metà**, e questo è il motivo per cui il bar
#     esiste;
#   * e **dormire lo rimette tutto**, che è l'unico riposo vero.
#
# La conseguenza voluta è che le armi diventino una spesa sensata e non un
# vezzo: un colpo di mazza costa un terzo di un pugno, e il coltello ancora
# meno. Prima le armi facevano solo più danno — cioè accorciavano una cosa
# che comunque potevi fare gratis. Adesso comprano **la possibilità di
# farla**.

const SCIATO_MAX: float = 100.0
## Quanto costa 'nu pugno a mano libera. Cento diviso tredici e mezzo fa
## sette colpi e mezzo: 'e sette-otto ca ha ditto 'o capo.
const SCIATO_PUGNO: float = 13.5
## Quanto se ricarica 'a sola, ô secondo. Venti secondi per un pugno: è
## lento apposta, e il caffè serve proprio a non aspettarli.
const SCIATO_TORNA: float = 0.68
## Quanto costa correre, al secondo. Una traversata della città sono venti
## secondi di corsa: ti mangia un pugno e mezzo, non la giornata.
const SCIATO_CORSA: float = 0.9
## Quanto ne rimette 'nu cafè.
const SCIATO_CAFE: float = 50.0

signal sciato_cambiato(quanto: float)

var sciato: float = SCIATO_MAX


## Quanto fiato costa un colpo con quello che tieni in mano.
##
## **'E ffierre costano assaje 'e meno**, ed è tutto il punto: menare a
## mano nuda è faticoso, menare con la mazza è un gesto solo. Il numero
## sta nella tabella delle armi accanto al danno, perché le due cose vanno
## lette insieme — un'arma che fa il triplo del danno e costa un terzo del
## fiato vale nove volte le mani, e quello è il prezzo che giustifica i
## cinquanta euro.
func sciato_colpo() -> float:
	var a: String = arma_in_mano
	if a == "" or not ARMI.has(a):
		return SCIATO_PUGNO
	return float(ARMI[a].get("sciato", SCIATO_PUGNO * 0.35))


## Ce sta 'o sciato pe' menà?
func pò_menà() -> bool:
	return sciato >= sciato_colpo() * 0.9


func consuma_sciato(quanto: float) -> void:
	if quanto <= 0.0:
		return
	var prima: float = sciato
	sciato = clampf(sciato - quanto, 0.0, SCIATO_MAX)
	if not is_equal_approx(prima, sciato):
		sciato_cambiato.emit(sciato)
	if prima > 0.0 and sciato <= 0.0:
		event_started.emit("Nun tiene cchiù sciato. Piglia 'nu cafè, o va' a durmì.")


func rimette_sciato(quanto: float) -> void:
	if quanto <= 0.0:
		return
	var prima: float = sciato
	sciato = clampf(sciato + quanto, 0.0, SCIATO_MAX)
	if not is_equal_approx(prima, sciato):
		sciato_cambiato.emit(sciato)


const ARMI := {
	# **'O cric: 'o primmo gradino** (0.56). Ce ne volevano tre di corpo a
	# corpo e ce n'erano due, e soprattutto mancava quello che uno si può
	# permettere **subito** — cinquanta euro per la mazza sono mezza
	# giornata buona, e fino ad allora restavi a mani nude. Il cric sta
	# nel bagagliaio di chiunque, costa un quarto, e fa poco danno: ma
	# costa **un terzo del fiato** di un pugno, ed è quello che compra.
	"cric": {
		"nome": "'O cric", "costo": 22, "danno": 4,
		"portata": 2.2, "calore": 8.0, "distanza": false,
		"sciato": 4.5,
		"desc": "chillo d''e ggomme. Nun fa paura, ma nun te stanca.",
	},
	"mazza": {
		"nome": "'A mazza 'e fierro", "costo": 50, "danno": 7,
		"portata": 2.5, "calore": 12.0, "distanza": false,
		"sciato": 4.8,
		"desc": "un pezzo di tubo. Fa male e non fa domande.",
	},
	"curtiello": {
		"nome": "'O curtiello", "costo": 80, "danno": 12,
		"portata": 2.1, "calore": 20.0, "distanza": false,
		"sciato": 3.2,
		"desc": "corto e convincente. Chi lo vede si ferma da solo.",
	},
	"fierro": {
		"nome": "'O fierro", "costo": 250, "danno": 22,
		"portata": 16.0, "calore": 48.0, "distanza": true,
		# Sparare non stanca: stanca quello che succede dopo.
		"sciato": 1.0,
		"desc": "'a pistola. Da lontano, e tutt''o vico te sente.",
	},
	# Il Kalash costa milleduecento e non piu' novecento. Il motivo e'
	# economico, non estetico: a novecento costava MENO di una piazza
	# comprata, e siccome stende un rivale in due colpi la strada furba era
	# comprarlo una volta e prendersi tutta la citta' a mano armata senza
	# pagare mai niente. Adesso costa piu' della prima piazza, e prendersi
	# una zona a mazzate ti mette addosso due stelle (vedi rivale_3d).
	"kalash": {
		"nome": "'O Kalash", "costo": 1200, "danno": 40,
		"portata": 24.0, "calore": 72.0, "distanza": true,
		"sciato": 1.0,
		"desc": "chesto nun è 'nu fierro, è 'na dichiarazione 'e guerra.",
	},
}
## L'ordine in cui si scorrono con G. La stringa vuota sono le mani nude.
const ORDINE_ARMI := ["", "cric", "mazza", "curtiello", "fierro", "kalash"]

const CAFFE_COST: int = 3
const CAFFE_PER_GIRO: int = 3
## Quanto dura la spinta del caffe' e quanto sospetto si porta via.
const CAFFE_DURATA: float = 15.0
const CAFFE_CALMA: float = 32.0
const CAFFE_OSSA: float = 12.0
## Ogni quanto si puo' rifischiare. Senza, si terrebbe premuto e la piazza
## diventerebbe un raduno di clacson.
const FISCHIO_RICARICA: float = 6.0

const CIGARETTE_PACK_COST: int = 6
const CIGARETTES_PER_PACK: int = 10

# ---------------------------------------------------------------------------
# 'A collezione: i manifesti del quartiere
# ---------------------------------------------------------------------------
## Sei manifesti attaccati ai muri, ognuno in un posto dove non ci passi per
## caso. Non danno abilità e non servono al lavoro: è roba da trovare, e
## basta. Ogni tanto un gioco ha bisogno di una cosa che non serva a niente.
##
## `dove` non è la posizione: è l'indizio. Compare nel taccuino solo per
## quelli che non hai ancora preso, così la ricerca ha una direzione ma non
## una freccia.
const MANIFESTI := [
	{
		"id": "treno", "titolo": "TRENO",
		"sotto": "Franco Ricciardi — Binario 7",
		"file": "res://assets/manifesti/treno.png",
		"dove": "Abbascio 'e tutto, dint'ô vico ca sponta 'ncopp'â via 'e bbascio.",
	},
	{
		"id": "leggende", "titolo": "LE LEGGENDE DEL NAPOLI",
		"sotto": "Curva B, tutt'e ssere",
		"file": "res://assets/manifesti/leggende.png",
		"dove": "Dint'ô vico 'e levante, ll'ùrdemo 'e tutte, areto 'o stadio.",
	},
	{
		"id": "teduccio", "titolo": "SAN GIOVANNI A TEDUCCIO",
		"sotto": "'O futuro è 'o nuosto",
		"file": "res://assets/manifesti/teduccio.png",
		"dove": "'Nfunno a nu vico cieco ca sponta 'ncopp'â Via Marina, a levante d''o mercato.",
	},
	{
		"id": "maradona", "titolo": "MARADONA RE DEL TRONO",
		"sotto": "'A leggenda nun more maje",
		"file": "res://assets/manifesti/maradona.png",
		"dove": "N'atu vico stretto, ancora cchiù a levante, apprievo â cornetteria.",
	},
	{
		"id": "pino_james", "titolo": "PINO & JAMES",
		"sotto": "Breaking Naples — solo musica e coraggio",
		"file": "res://assets/manifesti/pino_james.png",
		"dove": "Mmiez'ê duje vie 'e mmiezo, dint'ô vicariello ca 'e ttaglia.",
	},
	{
		"id": "bud", "titolo": "BUD SPENCER",
		"sotto": "Io nun songo italiano, songo napulitano",
		"file": "res://assets/manifesti/bud.png",
		"dove": "Abbascio, a levante d''o Corso, dint'ô vico ca nun se vede 'a strada.",
	},
]
## Quanto ti dà una foto, e quanto la collezione finita.
const MANIFESTO_PREMIO: int = 12
const COLLEZIONE_PREMIO: int = 180

var money: int = 0
var heat: float = 0.0
var reputation: int = 0

## La giornata dura dieci minuti reali (vedi giorno_notte.gd) e finisce
## quando Borrelli se ne va o quando ti stendono. Questo cronometro resta
## come rete di sicurezza: se per qualunque motivo la notte non arrivasse,
## il turno si chiude comunque.
## **Sedici ore in sette minuti e mezzo.** Il cronometro del turno e il
## ciclo del cielo adesso sono la stessa cosa (vedi giorno_notte.gd): si
## apre gli occhi a mezzogiorno, e quando arriva a zero sono le quattro
## d''a matina e bisogna andare a coricarsi.
var shift_duration: float = 450.0
var shift_time_left: float = 0.0
## Quando è vero il cronometro non scorre: t'hanno portato a casa e la
## serata è finita lì. Vedi `rientro_forzato`.
var tempo_fermo: bool = false
var shift_active: bool = false

## **Il parcheggiatore lavora solo nella piazza sua.**
##
## Fuori dai confini della propria zona non si posteggia: non arrivano auto
## da servire, non compaiono indicatori, non parte nessun avviso. Il resto
## della città è tempo libero — ci si va a comprare le sigarette, a
## fotografare i manifesti, a giocare a pallone, a farsi i fatti propri.
##
## Prima non era così e non funzionava: la freccia «cliente in attesa — 94 m»
## restava a schermo per tutta la città, e siccome quella freccia è un
## richiamo, girare per Napoli diventava una cosa che stavi *sbagliando*.
## Adesso quando esci dalla piazza il lavoro si spegne del tutto, e quando
## rientri si riaccende con un'insegna che lo dice chiaro.
##
## Lo imposta `Citta3D` a ogni cambio di zona: è vero quando la zona in cui
## stai ha `padrone == "tu"`.
var in_servizio: bool = true
var piazza_corrente: String = ""
## **'A piazza addò staje mo'** (0.61), per id: "" fuori da tutte e quattro.
## Serve alle auto per sapere se il parcheggiatore sta **nella loro**
## piazza: `in_servizio` dice solo che stai in una piazza tua, qualunque.
var zona_corrente: String = ""

## Le armi che possiedi (id -> true) e quella che tieni in mano ("" = mani
## nude). Si salvano col resto.
var armi: Dictionary = {}
var arma_in_mano: String = ""

## **Le piazze che sono tue.**
##
## Era una cosa scritta nella pietra: `ZONE` in `citta_3d.gd` aveva un campo
## `padrone` costante, e "tu" ce l'aveva solo la piazza iniziale. Adesso è
## uno stato che cambia in partita, e la citta' lo interroga invece di
## leggersi la costante.
var zone_mie: Array = ["piazza"]
## Quanto paghi al giorno per ognuna, id -> euro. La piazza iniziale non ha
## affitto: e' tua da prima che cominciasse il gioco.
var affitti: Dictionary = {}
## Chi lavora per te, zona -> {"nome", "paga", "cassa", "clienti"}.
## `cassa` sono i soldi che ha messo da parte e che gli devi andare a
## ritirare: finche' stanno in tasca sua, non stanno in tasca tua.
var dipendenti: Dictionary = {}

signal arma_cambiata(id: String)
signal zona_acquisita(id: String, nome: String, comprata: bool)
## La piazza torna a chi la teneva (0.64): il boss di capitolo se la riprende,
## o l'affitto non pagato. La città aggiorna il cartello e il servizio.
signal zona_persa(id: String)

# Statistiche del turno corrente, usate per il riepilogo finale
var clients_served: int = 0
var clients_lost: int = 0
var fines_paid: int = 0
var cars_damaged: int = 0
var forced_payments: int = 0
var emblems_stolen: int = 0
var emblem_earnings: int = 0
var punches_thrown: int = 0

# Inventario stemmi: nome -> {"count": int, "value": int}. Persiste tra i turni.
var emblems: Dictionary = {}

# Progressione persistente (salvata su disco)
var selected_zone: String = "vicolo"
var strada_unlocked: bool = false
var upgrades: Dictionary = {}
var cigarettes: int = 0 # sigarette rimaste nel pacchetto
var caffe: int = 0 # tazzine in corpo
var caffe_boost: float = 0.0 # secondi di spinta rimasti
var fischio_cd: float = 0.0 # ricarica del fischietto
var shift_start_money: int = 0
var active_commission: Dictionary = {} # {"name": ..., "mult": 3} se 'O Zio ha una richiesta
var arrested: bool = false # arrestato in questo turno
var bail_paid: int = 0
## Le ossa. Si consumano sotto le auto, sotto il motorino, sotto le mani
## degli autisti incazzati e del vigile. A zero si finisce all'ospedale e
## il turno è perso.
var health: float = HEALTH_MAX
var hospitalized: bool = false # finito in ospedale in questo turno
var hospital_bill: int = 0
var multe_prese: int = 0 # multe che i vigili hanno messo sulle auto tue
## Boss di fine turno (Borrelli): arriva nell'ultimo minuto.
var boss_spawned: bool = false
var boss_warned: bool = false
var notte: bool = false
## Mentre è vero il cronometro del turno è FERMO: la sfida col boss non ha
## tempo. Prima il turno scadeva mentre stavi ancora scappando e finiva di
## botto, senza che l'incontro si concludesse.
var boss_phase: bool = false
var boss_defeated: bool = false
var boss_wrong_answers: int = 0
## **Quante vote hê mannato via 'o vigile oggi** (0.63): alla terza chiama
## i carabinieri. Vedi `vigile_3d._mannato_via`.
var vigile_mannato_oggi: int = 0
const VIGILE_MANNATO_MAX: int = 3
# Attività secondarie del turno
var pickpockets: int = 0
## Decorazioni che il giocatore ha piazzato lui, in giro per la piazza:
## [{"id": "ombrellone", "pos": [x, y, z], "rot": 0.0}, ...]. Persiste.
var placed_decor: Array = []

## Livello grafico scelto (0 bassa, 1 media, 2 alta). -1 = mai deciso, e
## allora ci pensa `qualita.gd` a misurare quanto regge il computer.
var qualita_salvata: int = -1
var goals: int = 0
## Gli id dei manifesti già fotografati. Resta fra un turno e l'altro: la
## collezione è del giocatore, non della giornata.
var manifesti: Array = []
var _no_damage_time: float = 0.0
## Vero mentre la schermata iniziale è a video: gli altri nodi (HUD, player)
## sanno così di non reagire a Esc, mouse e tasti finché non si comincia.
var intro_active: bool = false
## Il tutorial completo si vede una volta sola: dalla seconda partita in poi
## resta solo una schermata breve "Premi INVIO per cominciare".
var tutorial_seen: bool = false
## Vero quando la scena si ricarica dopo un caricamento da slot: chi ha
## appena scelto una partita salvata ha già visto le locandine e la volata,
## e rivederle a ogni caricamento sarebbe una punizione.
var salta_intro: bool = false


# ---------------------------------------------------------------------------
# 'O MOUSE, E PECCHÉ NCOPP'Ô BROWSER NUN FUNZIUNAVA
# ---------------------------------------------------------------------------
#
# **'O guaio** (0.56b): caricato 'o gioco ncopp'a itch.io, 'n browser, **'o
# mouse nun se move**. A schermo si gira solo con la tastiera, e un gioco in
# prima persona senza mouse non è un gioco.
#
# La ragione non sta nel gioco, sta nel browser. Per far girare la testa col
# mouse serve il **Pointer Lock**: il cursore sparisce e la pagina riceve gli
# spostamenti relativi invece della posizione. E il Pointer Lock i browser
# **non lo danno a chi lo chiede da solo**: si concede soltanto dentro a un
# gesto dell'utente — un click, un tasto — e altrimenti la richiesta viene
# rifiutata **in silenzio**, senza errori, senza niente in console.
#
# Nel gioco la richiesta stava dentro a `player_fps._ready()`, cioè **mentre
# la scena si costruisce**: su Windows funziona (lì il "cattura il mouse" è
# una chiamata di sistema e basta), sul web viene buttata via. Da lì in poi
# nessuno riprovava mai, e `Input.get_mouse_mode()` sul web **dice la
# verità** — torna `VISIBLE` perché il lock non c'è — quindi il controllo
# dentro a `player_fps._unhandled_input` scartava ogni movimento. Tutto
# giusto, tutto coerente, e il mouse morto.
#
# **'A cura, e pecché sta ccà dinto e no dint'ô player.**
#
# Il modo del mouse lo cambiavano **ventidue punti diversi** — ogni pannello,
# ogni negozio, la pausa, la mappa, il tutorial. Con ventidue padroni non
# esiste nessun posto in cui si possa sapere *che cosa vuole il gioco adesso*,
# e senza quello non si può riprovare: riprovare a caso vorrebbe dire
# riprendersi il mouse mentre uno sta comprando le sigarette.
#
# Quindi qua dentro ci sta **'o desiderio** (`vò_o_mouse`) separato da quello
# che il browser ha concesso davvero, e tre porte sole:
#
#   * `piglia_o_mouse(true/false)` — lo dice il gioco: da adesso lo voglio
#     preso (o libero). Prova subito; se il browser dice di no, pazienza.
#   * `arripiglia_o_mouse()` — lo chiama chi riceve un **click**, che è il
#     solo momento in cui il browser dice di sì. Se il desiderio è "preso" e
#     il lock non c'è, ci riprova. Se il gioco voleva il mouse libero, non
#     fa niente: un pannello aperto resta aperto.
#   * `o_mouse_s_ha_da_piglià()` — vero quando il gioco lo vuole preso e non
#     ce l'ha: serve all'interfaccia per dirlo a chi gioca, perché uno che
#     non sa che deve cliccare resta lì a muovere il mouse per niente.
#
# Su Windows non cambia assolutamente niente: la prima richiesta va a buon
# fine e le altre due funzioni non hanno mai lavoro da fare.

## Che cosa vuole il gioco adesso — no chello ca 'o browser ha cuncesso.
var vò_o_mouse: bool = false


func piglia_o_mouse(pigliato: bool) -> void:
	vò_o_mouse = pigliato
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if pigliato
		else Input.MOUSE_MODE_VISIBLE)


## Da chiamare quando arriva un click. Torna `true` si s'è ripigliato mo'.
func arripiglia_o_mouse() -> bool:
	if not o_mouse_s_ha_da_piglià():
		return false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	return Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED


## 'O gioco 'o vò pigliato e nun ce ll'ha.
func o_mouse_s_ha_da_piglià() -> bool:
	return vò_o_mouse and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED


func _ready() -> void:
	# `upgrades` contiene SOLO quello che si possiede davvero. Prima veniva
	# riempito con dodici chiavi tutte a false, e uno zaino "vuoto" erano
	# comunque dodici voci: bastava un giro sbagliato nel salvataggio per
	# ritrovarsi tutto sbloccato. Adesso una chiave che non c'e' vuol dire
	# che l'oggetto non e' tuo, e basta.
	upgrades = {}
	# **Ogni avvio e' una giornata nuova. Non si salva piu' niente.**
	#
	# Il salvataggio c'era da quando il gioco durava tre minuti e la
	# progressione fra un turno e l'altro era tutto quello che c'era. Adesso
	# che c'e' una citta' da girare, un salvataggio che si porta dietro
	# soldi, armi, zone comprate e manifesti gia' trovati toglie proprio le
	# cose che rendono una partita: ricominci con la mazza in mano, le
	# piazze gia' tue e la collezione completa, e non c'e' piu' niente da
	# fare. Piu' ancora: chi ci rigioca dopo una modifica si porta dietro
	# uno stato vecchio e vede bug che non esistono.
	#
	# Il file che c'era gia' si cancella una volta sola, cosi' nessuno resta
	# con un salvataggio fantasma che il gioco non legge piu'.
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var had_save := false
	# **Si comincia senza niente.**
	#
	# Prima la prima partita regalava mezzo pacchetto di sigarette, con la
	# motivazione che senza non si poteva calmare Borrelli. Era vero, ma
	# risolveva il problema sbagliato: il gioco parte con zero euro e la
	# prima cosa che deve insegnare è che **tutto si compra**. Un pacchetto
	# in tasca gratis toglie la prima decisione economica della partita,
	# che è anche l'unica che a inizio turno hai davvero.
	#
	# Adesso non c'è niente: né sigarette, né caffè, né gilet, né coppola.
	# Le sigarette costano sei euro al tabaccaio e i primi sei euro te li
	# devi fare posteggiando. Borrelli arriva a fine giornata: il tempo di
	# comprarle c'è tutto.
	#
	# E vale anche per chi ci stava già giocando: un salvataggio più vecchio
	# di SAVE_VER viene azzerato una volta, così la partenza da zero è la
	# stessa per tutti. Zone, affitti e armi vanno via insieme ai soldi —
	# erano comprati con quelli.
	if not had_save or save_version < SAVE_VER:
		cigarettes = 0
		caffe = 0
		money = 0
		upgrades = {}
		armi = {}
		arma_in_mano = ""
		zone_mie = ["piazza"]
		affitti = {}
		placed_decor = []
		decor_copie = {}
		if had_save:
			save_version = SAVE_VER
			save_game()


var _slowmo_left: float = 0.0


## Slow-motion gestito qui e non dai singoli nodi: il GameManager è un
## autoload e non muore mai, quindi il time_scale torna SEMPRE a 1.0 anche
## se il nodo che ha chiesto il rallentatore viene liberato nel frattempo
## (fine turno, cambio scena, autista che scappa).
func request_slow_motion(scale: float, duration: float) -> void:
	Engine.time_scale = scale
	_slowmo_left = duration


func _process(delta: float) -> void:
	if _slowmo_left > 0.0:
		# delta è già scalato da time_scale: usiamo il tempo reale
		_slowmo_left -= delta / maxf(Engine.time_scale, 0.01)
		if _slowmo_left <= 0.0:
			Engine.time_scale = 1.0

	_passo_stelle(delta)
	_passo_cella(delta)

	if shift_active:
		# Durante lo scontro finale il cronometro si ferma: si va avanti
		# finché Borrelli non è convinto (o finché non ti stendono).
		if not boss_phase and not tempo_fermo:
			shift_time_left = max(0.0, shift_time_left - delta)
			shift_time_changed.emit(shift_time_left)
			# **Alle quattro la giornata non finisce: scade.**
			#
			# Prima il cronometro a zero chiudeva tutto di colpo, e il
			# giocatore si ritrovava il riepilogo addosso in mezzo a una
			# manovra. Adesso alle quattro smettono di arrivare le auto e
			# il gioco ti dice di andare a casa — ma **la giornata la
			# chiudi tu**, mettendoti a letto. E' la stessa differenza che
			# passa fra "chiude il negozio" e "vado a dormire".
			if shift_time_left <= 0.0:
				scade_giornata()
			_passo_fasce()
		if heat > 0.0:
			cool_down(AMBIENT_COOL_RATE * delta)
		if caffe_boost > 0.0:
			caffe_boost = maxf(0.0, caffe_boost - delta)
		# **'O sciato torna 'a sulo, ma chiano chiano** (0.56): venti
		# secondi per un pugno. Non è un rubinetto, è una rendita — e
		# serve solo perché chi non ha una lira non resti bloccato per
		# sempre a mani vuote.
		if sciato < SCIATO_MAX:
			rimette_sciato(SCIATO_TORNA * delta)
		if fischio_cd > 0.0:
			fischio_cd = maxf(0.0, fischio_cd - delta)
		_passo_commissioni(delta)
		_passo_lavoretti(delta)
		# Fiatone: si riprende fiato solo dopo qualche secondo che nessuno
		# ti tocca, e comunque mai fino a stare bene del tutto.
		_no_damage_time += delta
		# **L'osse nun se rifanno 'a sole (0.54).**
		#
		# Il capo: *"L'hp non sale da sola, bisogna mangiare un cornetto
		# black and white disponibile però solo di notte alla
		# cornetteria."*
		#
		# Qui ci stava il fiatone: dopo sette secondi senza prenderle, le
		# ossa risalivano da sole fino a quarantotto. Sembrava un aiuto
		# ragionevole e invece toglieva il peso alle mazzate — bastava
		# girare l'angolo, contare fino a dieci, e la rissa non era mai
		# successa. Adesso quello che perdi te lo devi ricomprare: 'o
		# cafè, 'a spiga, 'a colazione, 'a sedia — e di notte 'o cornetto
		# d''a cornetteria, che è l'unico che ti rimette in piedi davvero.
		#
		# Le costanti restano scritte apposta: dicono da dove veniamo, e
		# se un giorno il fiatone dovesse tornare (per esempio come
		# miglioria da comprare) il numero è già tarato.


func start_shift() -> void:
	shift_time_left = shift_duration
	tempo_fermo = false
	# **Chi dorme se sceta cu 'o sciato chino** (0.56). È l'unico riposo
	# vero: il caffè ne rimette metà, la notte tutto.
	sciato = SCIATO_MAX
	sciato_cambiato.emit(sciato)
	_fascia_detta = -1
	# **'E tre fermi so' d''a jurnata, no d''a partita.** Il conto riparte
	# ogni mattina: se no bastavano tre giornate distratte, una presa
	# ciascuna, e da lì in poi ogni fermo era una nottata in cella.
	fermi_oggi = 0
	vigile_mannato_oggi = 0
	notte_ncella = false
	# E i gol pagati ripartono da zero: quattro al giorno, tutti i giorni.
	gol_pavate = 0
	# **'O piazzale d''o sfasciacarrozze se svacanta 'a notte.** Il conto
	# delle auto vendute riparte ogni mattina, se no bastava una giornata
	# buona per chiudere il mestiere per sempre.
	auto_vennute = 0
	soldi_auto = 0
	ritirato_oggi = 0
	shift_active = true
	shift_start_money = money
	clients_served = 0
	clients_lost = 0
	fines_paid = 0
	cars_damaged = 0
	forced_payments = 0
	emblems_stolen = 0
	emblem_earnings = 0
	# 'A nomma scende ogni giorno: una brutta reputazione va rinfrescata.
	if nomma > 0.0:
		nomma = maxf(0.0, nomma - NOMMA_SCENDE_AL_JUORNO)
		nomma_cambiata.emit(nomma)
	punches_thrown = 0
	arrested = false
	bail_paid = 0
	multe_prese = 0
	boss_spawned = false
	boss_warned = false
	notte = false
	boss_phase = false
	boss_defeated = false
	boss_wrong_answers = 0
	pickpockets = 0
	goals = 0
	hospitalized = false
	hospital_bill = 0
	health = HEALTH_MAX
	_no_damage_time = 0.0
	dentro_casa = false
	prepara_giornata()
	# Chi non ha mangiato ieri sera comincia la giornata a mezze forze.
	if _senza_spesa():
		health = HEALTH_MAX * 0.55
	health_changed.emit(health)
	shift_time_changed.emit(shift_time_left)
	_roll_commission()
	crea_commissioni()
	crea_lavoretti()


## A inizio turno, 'O Zio ogni tanto commissiona uno stemma specifico:
## quello, se venduto entro il turno, vale il triplo.
func _roll_commission() -> void:
	active_commission = {}
	if randf() < COMMISSION_CHANCE:
		var target: String = EMBLEM_NAMES[randi() % EMBLEM_NAMES.size()]
		active_commission = {"name": target, "mult": COMMISSION_MULT}
		# Annuncio ritardato di qualche secondo, a partita avviata.
		get_tree().create_timer(4.0).timeout.connect(func():
			if not active_commission.is_empty():
				event_started.emit("« 'O Zio »: Puortame nu \"%s\"... t''o pavo TRIPLO!" % target)
				commission_changed.emit())


func end_shift() -> Dictionary:
	shift_active = false
	# Prima di tutto: si scende dalla macchina, se ci stavi sopra.
	scinne_d_a_machina()
	azzera_stelle()
	# **L'estrazione se fa primma d''o riepilogo.** Se no i soldi vinti
	# entrerebbero in cassa dopo che il conto della sera è già stato
	# scritto, e uno vedrebbe il terno nel riepilogo e i soldi il giorno
	# dopo. Qui invece la vincita è già in tasca quando Nunzia chiede.
	var _lotto: Dictionary = estrai_lotto()
	if money >= NEXT_ZONE_GOAL and not strada_unlocked:
		strada_unlocked = true

	# **L'affitto delle piazze conquistate.**
	#
	# Si paga a fine giornata, ed e' la parte che rende la conquista una
	# decisione invece di un regalo: una piazza comprata mille euro rende
	# solo se la lavori. Se la giornata dopo stai tutto il tempo dall'altra
	# parte della citta', quella piazza ti costa cinquanta euro e basta.
	#
	# Se non ce li hai, il debito non si accumula: si va sotto zero fino a
	# zero e i parcheggiatori se la riprendono. Un debito che cresce
	# all'infinito e' una spirale da cui non si esce, e in un gioco di tre
	# minuti a partita non e' una punizione, e' un vicolo cieco.
	var affitto := affitto_totale()
	var perse: Array = []
	if affitto > 0:
		if money >= affitto:
			money -= affitto
			money_changed.emit(money)
		else:
			for id in affitti.keys():
				perse.append(id)
			for id in perse:
				zone_mie.erase(id)
				affitti.erase(id)
				zona_persa.emit(id)
			money = 0
			money_changed.emit(money)

	# **'E guagliune che lavorano pe' te.**
	#
	# La sera si tirano le somme: quello che hanno incassato e non sei
	# andato a ritirare te lo danno lo stesso, ma se ne tengono un quarto
	# "pe' 'o disturbo" — ed e' quello che rende il giro serale una scelta
	# invece di una formalita'. Poi si paga la giornata a ognuno.
	var incassato_da_loro := 0
	var trattenuto := 0
	var paghe := 0
	var licenziati: Array = []
	for zid in dipendenti.keys():
		var d: Dictionary = dipendenti[zid]
		var cassa: int = int(d.get("cassa", 0))
		if cassa > 0:
			var loro: int = int(round(float(cassa) * QUOTA_NON_RITIRATA))
			trattenuto += loro
			incassato_da_loro += cassa - loro
			d["cassa"] = 0
			# **Nun ce sî passato manco stasera** (0.55). Il guaglione ha
			# lavorato tutto il giorno, si è tenuto i soldi in mano e tu
			# non ti sei fatto vedere. Una volta capita; una settimana di
			# fila e se ne va da un rivale — e la cassa se la porta.
			muove_umore_guagliuno(zid, -GUAGLIUNO_SCURDATO)
		paghe += int(d.get("paga", PAGA_DIPENDENTE))
	if incassato_da_loro > 0:
		money += incassato_da_loro
		money_changed.emit(money)
	if paghe > 0:
		if money >= paghe:
			money -= paghe
			money_changed.emit(money)
		else:
			# Non li puoi pagare: se ne vanno. Nessun debito che si trascina.
			licenziati = dipendenti.keys().duplicate()
			dipendenti.clear()
			money = 0
			money_changed.emit(money)

	# **Il conto di casa, prima di girare pagina.**
	#
	# Le spese restano aperte: non si pagano da sole a fine giornata, si
	# pagano consegnandole a lei. Quello che resta scoperto si porta la
	# mora e diventa il problema di domani.
	var scoperto := spese_dovute()
	var spese_elenco: Array = []
	for s in spese_aperte:
		spese_elenco.append({"nome": str(s["nome"]),
			"importo": int(s["importo"]), "grave": bool(s["grave"]),
			"ritardo": giornata - int(s["giorno"])})

	# Chi è rimasto senza vederti troppe sere se ne va stanotte, e domani
	# mattina la piazza è vuota. Si fa **dopo** l'incasso: quello che ha
	# raccolto oggi te lo lascia, è quello di domani che non arriva più.
	var partiti: Array = _guagliune_ca_se_ne_vanno()
	if boss_parte_juorne > 0:
		boss_parte_juorne -= 1
		if boss_parte_juorne == 0:
			event_started.emit("Cu Donna Carmela simmo appare. 'O mercato è tutto tuoio.")

	giornata += 1
	var fatti := _conseguenze()

	var summary := {
		"giornata": giornata - 1,
		"orario_ritiro": ora_ritiro,
		"consegnato": consegnato_oggi,
		"scoperto": scoperto,
		"spese_aperte": spese_elenco,
		"umore_moglie": umore_moglie,
		"conseguenze": fatti,
		"perso_al_gioco": perso_al_gioco,
		"vinto_al_gioco": vinto_al_gioco,
		"extra_richiesto": extra_richiesto,
		"extra_dato": extra_dato,
		"commissioni_fatte": commissioni_fatte,
		"scopa_vinte": scopa_vinte_oggi,
		"affitto_pagato": affitto if perse.is_empty() else 0,
		"zone_perse": perse,
		"dipendenti_incasso": incassato_da_loro,
		"dipendenti_ritirato": ritirato_oggi,
		"auto_vennute": auto_vennute,
		"soldi_auto": soldi_auto,
		"dipendenti_trattenuto": trattenuto,
		"dipendenti_paghe": paghe if licenziati.is_empty() else 0,
		"dipendenti_persi": licenziati,
		"dipendenti_scappati": partiti,
		"zone_mie": zone_mie.size(),
		"money": money,
		"earned": money - shift_start_money,
		"arrested": arrested,
		"bail": bail_paid,
		"clients_served": clients_served,
		"clients_lost": clients_lost,
		"fines_paid": fines_paid,
		"cars_damaged": cars_damaged,
		"forced_payments": forced_payments,
		"nomma": nomma,
		"voce": voce(),
		"emblems_stolen": emblems_stolen,
		"emblem_earnings": emblem_earnings,
		"punches_thrown": punches_thrown,
		"hospitalized": hospitalized,
		"notte_ncella": notte_ncella,
		"fermi_oggi": fermi_oggi,
		"lotto": _lotto,
		"hospital_bill": hospital_bill,
		"multe_prese": multe_prese,
		"boss_spawned": boss_spawned,
		"boss_defeated": boss_defeated,
		"boss_wrong_answers": boss_wrong_answers,
		"pickpockets": pickpockets,
		"goals": goals,
		"next_zone_goal": NEXT_ZONE_GOAL,
		"zone_unlocked": strada_unlocked,
	}
	save_game()
	shift_ended.emit(summary)
	return summary


## **'O rummore d''a strada nun trase dint'a casa** (0.56).
##
## Il capo: *"quando sei in casa è inutile che arrivano tutti i messaggi,
## scansa il motorino, quello che si piglia il caffè ecc."*
##
## Aveva ragione ed è un difetto di forma: `event_started` è un canale
## solo, e ci passano dentro due cose che non c'entrano niente fra loro —
## quello che **succede a te** (t'hanno arrestato, 'a Signora t'ha dato i
## numeri, hai perso una piazza) e quello che **succede in strada** (un
## motorino che sfreccia, uno che grida al mercato, il vigile che tossisce).
##
## Il primo va detto sempre. Il secondo è **ambiente**: serve a far
## sentire la piazza mentre ci stai dentro, e dentro a un vascio con la
## porta chiusa è rumore che racconta una città che in quel momento non
## stai guardando.
##
## Quindi un secondo canale che passa dallo stesso posto ma si tace
## quando sei in casa. Chi emette sceglie quale dei due è — ed è una
## scelta che si fa una volta, leggendo la frase.
func avvisa_strada(testo: String) -> void:
	if dentro_casa or ncella:
		return
	event_started.emit(testo)


func add_money(amount: int) -> void:
	money = max(0, money + amount)
	money_changed.emit(money)


## Paga una cifra se ci sono i soldi. Torna falso e non tocca niente se non
## bastano. Lo usano le attività secondarie — le tre carte, la slot — che
## hanno bisogno di un "o paghi o non giochi" senza costruirsi ognuna il suo
## controllo sul portafoglio.
func paga(quanto: int) -> bool:
	if quanto <= 0:
		return true
	if money < quanto:
		return false
	money -= quanto
	money_changed.emit(money)
	return true


# ---------------------------------------------------------------------------
# 'E ffierre
# ---------------------------------------------------------------------------

func compra_arma(id: String) -> bool:
	if not ARMI.has(id) or armi.has(id):
		return false
	if not paga(int(ARMI[id]["costo"])):
		return false
	armi[id] = true
	arma_in_mano = id
	arma_cambiata.emit(id)
	save_game()
	return true


## Quello che si puo' tenere in mano, in ordine, mani nude comprese.
func roba_in_mano() -> Array:
	var mie: Array = []
	for id in ORDINE_ARMI:
		if id == "" or armi.has(id):
			mie.append(id)
	return mie


## Passa all'oggetto successivo (passo 1) o al precedente (passo -1).
##
## Il passo serve alla rotella del mouse, che gira nei due sensi: scorrere
## sempre in avanti va bene per un tasto, ma con la rotella e' innaturale —
## uno si aspetta che tornando indietro con la rotella torni indietro anche
## la mano.
func cambia_arma(passo: int = 1) -> void:
	var mie: Array = roba_in_mano()
	if mie.size() <= 1:
		return
	var i: int = maxi(0, mie.find(arma_in_mano))
	arma_in_mano = str(mie[posmod(i + passo, mie.size())])
	arma_cambiata.emit(arma_in_mano)


func arma_danno() -> int:
	return int(ARMI[arma_in_mano]["danno"]) if ARMI.has(arma_in_mano) else 2


func arma_portata() -> float:
	return float(ARMI[arma_in_mano]["portata"]) if ARMI.has(arma_in_mano) else 2.0


func arma_calore() -> float:
	return float(ARMI[arma_in_mano]["calore"]) if ARMI.has(arma_in_mano) else 6.0


func arma_a_distanza() -> bool:
	return ARMI.has(arma_in_mano) and bool(ARMI[arma_in_mano]["distanza"])


func arma_nome() -> String:
	return str(ARMI[arma_in_mano]["nome"]) if ARMI.has(arma_in_mano) else "'E mmane"


# ---------------------------------------------------------------------------
# 'E ppiazze
# ---------------------------------------------------------------------------

## Quanto costa la PROSSIMA zona, e quanto d'affitto al giorno. Il prezzo
## sale col numero di piazze che tieni già: mille e cinquanta per la prima
## in più, duemila e cento per la seconda, e così via. Non è avidità dei
## rivali — è che ogni piazza che prendi te ne fa guadagnare di più, e se il
## prezzo restasse fermo la terza sarebbe regalata.
## **Il prezzo di una piazza, rifatto sui guadagni veri.**
##
## Misurato: un turno dura 560 secondi e frutta fra gli ottanta e i
## centottanta euro — mance piu' stemmi. Mille euro per la prima piazza in
## piu' volevano dire otto o nove giornate perfette messe da parte senza
## spendere una lira: nessuno ci arrivava, e la meccanica di comprare le
## piazze restava scritta e mai usata.
##
## Quattrocentocinquanta sono tre-quattro giornate. Si sentono, si devono
## mettere da parte apposta, ma sono un obiettivo che si vede. E salgono
## comunque con quante ne tieni: la seconda ne costa novecento, la terza
## milletrecentocinquanta.
func prezzo_zona() -> int:
	return 450 * maxi(1, zone_mie.size())


## L'affitto giornaliero: trenta euro a piazza, non piu' cinquanta.
## Cinquanta erano piu' di mezza giornata di lavoro solo per stare fermi, e
## chi comprava la seconda piazza si trovava a lavorare per pagarla. Trenta
## e' una tassa che si sente e che si copre lavorandoci mezz'ora.
func affitto_zona() -> int:
	return 30 * maxi(1, zone_mie.size())


func zona_mia(id: String) -> bool:
	return zone_mie.has(id)


# ---------------------------------------------------------------------------
# 'E guagliune: chi lavora 'e piazze toje
# ---------------------------------------------------------------------------
#
# **Il problema che risolvono.** Comprata la seconda piazza, il gioco ti
# chiedeva di stare in due posti insieme: le auto arrivavano al mercato
# mentre tu stavi allo stadio, e la piazza che avevi pagato
# quattrocentocinquanta euro lavorava a vuoto. Piu' piazze compravi, piu'
# il gioco diventava una corsa avanti e indietro.
#
# Il guaglione e' la risposta: gli dai la piazza, lui posteggia, e tu vai
# a fare altro. Non e' gratis — settanta euro per convincerlo e quaranta al
# giorno — e non e' bravo quanto te: prende meno mancia di quella che
# prenderesti tu, perche' un padrone che sta al posto suo si fa pagare
# meglio di un dipendente. E i soldi non ti arrivano in tasca da soli:
# stanno in tasca a lui finche' non passi a ritirarli.

## Quanto vuole per accettare il posto.
##
## Le cifre stanno tarate sulle MANCE VERE, che in questo gioco sono
## spiccioli: un'utilitaria lascia uno o due euro, una berlina due o
## quattro, una di lusso quattro o otto. Un guaglione che costasse settanta
## euro piu' quaranta al giorno non li rientrerebbe mai — ci vorrebbero
## trenta clienti al giorno solo per pagargli la giornata.
##
## Venticinque per convincerlo e dodici la sera: in una piazza di quelle
## nuove (un'auto ogni mezzo minuto scarso) rientra e avanza, nella piazza
## di casa (un'auto ogni dieci secondi) rende parecchio. Che e' giusto:
## la piazza di casa e' la migliore, e metterci uno per andartene in giro
## dev'essere una decisione vera.
const ASSUNZIONE_COSTO: int = 25
## **'A percentuale.** Quanto si tiene lui su ogni euro che incassa.
##
## Era una paga fissa la sera — dodici euro, che dovevi avere o se ne
## andava. Sbagliata per due motivi: uno che ti costa uguale se la piazza
## rende cento o rende zero non e' un socio, e' un affitto; e il capo ha
## chiesto una cosa piu' semplice e piu' vera — *"la sera ti vai a prendere
## i soldi da lui e lui si tiene il 30%"*. Cosi' e' adesso: nessuna paga
## fissa, nessun debito che si trascina, trenta su cento e ognuno per la
## strada sua.
const QUOTA_GUAGLIUNO: float = 0.30
## La paga fissa non esiste piu': resta a zero perche' i salvataggi vecchi
## se la portano dentro e `end_shift` la legge ancora.
const PAGA_DIPENDENTE: int = 0
## Se non passi a ritirare, la sera si tiene la meta' invece del trenta per
## cento. E' quello che rende il giro serale una scelta e non una formalita'.
const QUOTA_NON_RITIRATA: float = 0.50
## Quanto rende un cliente servito da lui rispetto a uno servito da te.
## Alzata dalla 0.44b (era 0,72): con la percentuale che si tiene lui, il
## conto netto per te era sceso al cinquanta per cento scarso, e a quel
## punto assumere non conveniva mai. Adesso 0,9 x 0,7 = 0,63 — meno di
## quello che faresti tu di persona, che e' il punto, ma abbastanza da
## valere i venticinque euro.
## **0.61: 0,90 → 0,75.** Quando il guaglione ha cominciato a posteggiare
## davvero (prima perdeva metà dei clienti per strada), la prova l'ha
## misurato: nella piazza di casa, da solo, faceva più di una giornata tua.
## Adesso rende sui due terzi di te — che è il senso del mestiere.
const RESA_DIPENDENTE: float = 0.75

const NOMI_GUAGLIUNI := ["Ciruzzo", "Peppe 'o Lungo", "Mimmo", "Gaetano",
	"Sasa'", "Nicola 'o Biondo", "Totore"]

signal dipendenti_cambiati()
## Un colpo che è arrivato addosso a qualcuno (0.61): l'HUD fa la crocetta.
signal colpo_a_segno(danno: int)


func ha_dipendente(zona_id: String) -> bool:
	return dipendenti.has(zona_id)


func dipendente(zona_id: String) -> Dictionary:
	return dipendenti.get(zona_id, {})


## Perche' un'assunzione si possa fare servono tre cose: la piazza dev'essere
## tua, non ci dev'essere gia' qualcuno, e i settanta euro devi averli.
func puoi_assumere(zona_id: String) -> bool:
	return zona_mia(zona_id) and not ha_dipendente(zona_id) \
		and money >= ASSUNZIONE_COSTO


func assumi(zona_id: String, nome: String = "", gratis: bool = false) -> bool:
	if gratis:
		if not zona_mia(zona_id) or ha_dipendente(zona_id):
			return false
	elif not puoi_assumere(zona_id):
		return false
	if not gratis:
		money -= ASSUNZIONE_COSTO
		money_changed.emit(money)
	dipendenti[zona_id] = {
		"nome": nome if nome != "" else NOMI_GUAGLIUNI[
			randi() % NOMI_GUAGLIUNI.size()],
		"paga": PAGA_DIPENDENTE,
		"cassa": 0,
		"clienti": 0,
		# --- 'E cose nove d''a 0.55 ---
		"dal": giornata,
		"umore": 50.0,
	}
	dipendenti_cambiati.emit()
	return true


# ---------------------------------------------------------------------------
# 'E guagliune crescono
# ---------------------------------------------------------------------------
#
# **Uno ca fatica pe' te 'a diece juorne nun è chillo d''o primmo juorno.**
#
# Era la riga della roadmap, ed era anche il buco più largo del sistema: un
# guagliuno assunto oggi e uno che ti lavora da tre settimane erano lo
# stesso identico numero. Ventisette euro, il trenta per cento, sempre.
# Cioè assumere era una **transazione**, non un rapporto — e in un gioco in
# cui i clienti si ricordano di te (0.54), era l'unica cosa che non si
# ricordava di niente.
#
# Adesso ognuno tiene due numeri:
#
#   `dal`    'a jurnata ca l'hê pigliato. Da lì viene l'esperienza.
#   `umore`  comme 'o tratte, 'a 0 a 100.
#
# **L'esperienza** rende: chi conosce la piazza si fa pagare meglio e
# scappa meno clienti (fino a +22% sul netto), e **chiede di meno** — la
# quota che si tiene scende dal trenta al ventuno per cento dopo due
# settimane. Un guagliuno vecchio vale quasi un terzo più di uno nuovo, ed
# è il motivo per cui a un certo punto non conviene più licenziare e
# riassumere per risparmiare i ventisette euro.
#
# **L'umore** invece è il rischio, ed è quello che il capo ha chiesto per
# nome: *"uno trattato male se ne va da un rivale"*. Sale quando passi a
# ritirare la cassa (lo stai a sentire, gli lasci la sua parte), scende
# quando lo lasci con i soldi in mano per giornate intere. Sotto trenta
# comincia a brontolare; **sotto dieci se ne va**, e si porta la cassa.

## Quante giornate ci mette a diventare esperto del tutto.
const GUAGLIUNO_MATURA: float = 14.0
## Quanto rende in più, alla fine.
const GUAGLIUNO_RESA_MAX: float = 0.22
## Quanto scende la sua quota, alla fine (0,09 = dal 30% al 21%).
const GUAGLIUNO_QUOTA_MENO: float = 0.09
## Sotto a questo se ne va da un rivale.
const GUAGLIUNO_SE_NE_VA: float = 10.0
## Sotto a questo comincia a lamentarsi.
const GUAGLIUNO_BRONTOLA: float = 30.0
## Quanto guadagna d'umore ogni volta che passi a ritirare.
##
## **Chisto adda essere cchiù gruosso 'e chillo 'e sotto**, e non di poco:
## al primo giro erano +14 contro −18, e la prova ha fatto vedere che così
## anche chi passava **una sera sì e una no** perdeva il guagliuno — meno
## quattro ogni due sere, e dopo venti sere se n'era andato. Cioè il
## giocatore normale, quello che non è preciso, veniva punito per essere
## normale. Il bastone deve colpire chi non passa **mai**, non chi passa
## quasi sempre.
const GUAGLIUNO_RITIRO_UMORE: float = 16.0
## Quanto perde ogni sera in cui l'hai lasciato con la cassa in mano.
const GUAGLIUNO_SCURDATO: float = 13.0

signal guagliuno_se_ne_va(zona: String, nome: String)


## Da 0 (appena assunto) a 1 (esperto del tutto).
func guagliuno_esperienza(zona_id: String) -> float:
	var d: Dictionary = dipendente(zona_id)
	if d.is_empty():
		return 0.0
	var juorne: float = float(giornata - int(d.get("dal", giornata)))
	return clampf(juorne / GUAGLIUNO_MATURA, 0.0, 1.0)


## Quanto rende un cliente servito da lui, esperienza compresa.
func resa_guagliuno(zona_id: String) -> float:
	return RESA_DIPENDENTE * (1.0
		+ GUAGLIUNO_RESA_MAX * guagliuno_esperienza(zona_id))


## Quanto si tiene lui quando passi a ritirare. Scende con l'esperienza.
func quota_guagliuno(zona_id: String) -> float:
	return maxf(0.05, QUOTA_GUAGLIUNO
		- GUAGLIUNO_QUOTA_MENO * guagliuno_esperienza(zona_id))


## **Chi se ferma addò 'o guaglione, paga** (0.61). Otto su dieci da nuovo,
## più di nove da esperto; il tirchio resta tirchio.
func paga_chi_guagliuno(zona_id: String, personalita: String = "") -> float:
	var p: float = 0.82 + 0.12 * guagliuno_esperienza(zona_id)
	if personalita == "tirchio":
		p -= 0.30
	elif personalita == "turista":
		p += 0.05
	return clampf(p, 0.3, 0.97)


func umore_guagliuno(zona_id: String) -> float:
	return float(dipendente(zona_id).get("umore", 50.0))


func muove_umore_guagliuno(zona_id: String, quanto: float) -> void:
	if not dipendenti.has(zona_id):
		return
	var d: Dictionary = dipendenti[zona_id]
	d["umore"] = clampf(float(d.get("umore", 50.0)) + quanto, 0.0, 100.0)
	dipendenti_cambiati.emit()


## **Se ne va, e se porta 'a cassa.**
##
## Chiamato a fine giornata. Non è una punizione a sorpresa: sotto trenta
## di umore lo dice da giorni, e basta passare a ritirare per rimetterlo a
## posto. Ma se lo ignori per una settimana, una mattina non c'è più — e
## quello che aveva in mano se l'è portato, perché nessuno lascia i soldi
## a chi non è passato a prenderseli.
func _guagliune_ca_se_ne_vanno() -> Array:
	var partiti: Array = []
	for zid in dipendenti.keys():
		var d: Dictionary = dipendenti[zid]
		if float(d.get("umore", 50.0)) > GUAGLIUNO_SE_NE_VA:
			continue
		partiti.append({"zona": zid, "nome": str(d.get("nome", "'O guaglione")),
			"cassa": int(d.get("cassa", 0))})
	for p in partiti:
		dipendenti.erase(str(p["zona"]))
		guagliuno_se_ne_va.emit(str(p["zona"]), str(p["nome"]))
		event_started.emit(
			"%s se n'è ghiuto cu 'nu rivale. E s'è purtato €%d 'e cassa."
			% [p["nome"], int(p["cassa"])])
	if not partiti.is_empty():
		dipendenti_cambiati.emit()
	return partiti


func licenzia(zona_id: String) -> void:
	if not dipendenti.has(zona_id):
		return
	# Quello che aveva in mano te lo da' comunque: e' un licenziamento, non
	# una rapina.
	var cassa: int = int(dipendenti[zona_id].get("cassa", 0))
	if cassa > 0:
		money += cassa
		money_changed.emit(money)
	dipendenti.erase(zona_id)
	dipendenti_cambiati.emit()


## Lo chiama la piazza quando il guaglione si e' fatto pagare da un cliente.
func dipendente_incassa(zona_id: String, quanto: int) -> void:
	if not dipendenti.has(zona_id) or quanto <= 0:
		return
	var d: Dictionary = dipendenti[zona_id]
	d["cassa"] = int(d.get("cassa", 0)) + quanto
	d["clienti"] = int(d.get("clienti", 0)) + 1
	dipendenti_cambiati.emit()


## Ci passi davanti e premi E: ti da' tutto quello che ha messo da parte.
func ritira_cassa(zona_id: String) -> int:
	if not dipendenti.has(zona_id):
		return 0
	var d: Dictionary = dipendenti[zona_id]
	var cassa: int = int(d.get("cassa", 0))
	if cassa <= 0:
		return 0
	# Trenta su cento se li tiene lui, ed e' giusto che sia lui a contarli:
	# tu vedi entrare in tasca la parte tua. **E scende con gli anni**
	# (0.55): uno che sta con te da due settimane si tiene il ventuno.
	var suo: int = int(round(float(cassa) * quota_guagliuno(zona_id)))
	var mio: int = maxi(0, cassa - suo)
	d["cassa"] = 0
	d["tenuto"] = int(d.get("tenuto", 0)) + suo
	# **Passà a ritirà nun è sulo 'nu fatto 'e sorde.** È l'unica volta in
	# cui ci parli: chi lo vede arrivare sta bene, chi non lo vede da una
	# settimana se ne va da un rivale. Vedi `_guagliune_ca_se_ne_vanno`.
	muove_umore_guagliuno(zona_id, GUAGLIUNO_RITIRO_UMORE)
	money += mio
	ritirato_oggi += mio
	money_changed.emit(money)
	dipendenti_cambiati.emit()
	return mio


## Quanto hai ritirato dai guagliuni oggi (0.61): va nel riepilogo.
var ritirato_oggi: int = 0


## Quanto sta in giro, in tasca ai guagliuni. Lo mostra l'interfaccia: e'
## il promemoria che c'e' un giro da fare.
func cassa_in_giro() -> int:
	var t := 0
	for zid in dipendenti:
		t += int(dipendenti[zid].get("cassa", 0))
	return t


## La piazza passa a te. `comprata` distingue i due modi, e serve solo a
## dire la frase giusta: il risultato è lo stesso.
func acquisisci_zona(id: String, nome: String, comprata: bool,
		affitto: int = 0) -> void:
	if zone_mie.has(id):
		return
	zone_mie.append(id)
	if affitto > 0:
		affitti[id] = affitto
	# **E stasera vene chi 'a teneva primma** (0.55). Comprata o presa a
	# mazzate non cambia: chi la proteggeva non ha firmato niente.
	arma_boss_capitolo(id)
	zona_acquisita.emit(id, nome, comprata)
	save_game()


## L'affitto di tutte le piazze messe insieme. Si paga a fine turno.
func affitto_totale() -> int:
	var t := 0
	for id in affitti:
		t += int(affitti[id])
	return t


## **'A multa.**
##
## Il vigile non arresta piu' nessuno: quello e' mestiere dei carabinieri,
## e arriva quando fai il violento. Il vigile fa il suo lavoro, che e'
## scrivere. Cinquanta euro — che sono una mattinata buona, quindi si
## sentono, ma non chiudono la partita.
##
## Se non li hai, si prende la roba: prima le armi (le piu' care per
## prime), poi gli stemmi. E' il modo di far male anche a chi tiene le
## tasche vuote, senza toglierti il turno.
const MULTA_COSTO: int = 50

## Chi sta parlando col giocatore adesso. Serve all'HUD per sapere a chi
## mandare la risposta: prima era scritto "borrelli" a mano, e nessun altro
## poteva aprire un dialogo.
var dialogo_con: Node = null


## Ritorna la frase da mostrare: com'e' andata a finire.
func paga_multa() -> String:
	if money >= MULTA_COSTO:
		money -= MULTA_COSTO
		money_changed.emit(money)
		return "Multa 'e €%d. Pavata." % MULTA_COSTO
	# Niente soldi: si sequestra. Prima le armi, dalla piu' cara.
	var ordine := ["kalash", "fierro", "curtiello", "mazza"]
	for id in ordine:
		if armi.has(id):
			armi.erase(id)
			if arma_in_mano == id:
				arma_in_mano = ""
				arma_cambiata.emit(arma_in_mano)
			inventory_changed.emit(emblems)
			return "Nun tiene 'e sorde: t'ha sequestrato %s." % str(ARMI[id]["nome"])
	if not emblems.is_empty():
		# **Uno stemma, non tutta la pila.**
		#
		# `emblems` e' un dizionario nome -> {count, value}: cancellare la
		# chiave voleva dire portarsi via tutti i Cavallini che avevi, non
		# uno. Chi ne aveva rubati cinque perdeva cinque stemmi per una
		# multa da cinquanta euro.
		var chiave = emblems.keys()[0]
		var voce: Dictionary = emblems[chiave]
		voce["count"] = int(voce.get("count", 1)) - 1
		if int(voce["count"]) <= 0:
			emblems.erase(chiave)
		inventory_changed.emit(emblems)
		return "Nun tiene 'e sorde: s'è pigliato 'o stemma (%s)." % str(chiave)
	# Ultima spiaggia: si prende quello che ti trova addosso. Col borsello
	# una parte resta dov'è, e non è un dettaglio: è la differenza fra
	# tornare a casa a mani vuote e tornarci con la giornata salva.
	var visibili: int = soldi_visibili()
	if visibili > 0:
		money = maxi(0, money - visibili)
		money_changed.emit(money)
		if upgrades.get("borsello", false):
			return "S'e' pigliato €%d. 'O borsello nun l'ha visto." % visibili
		return "T'ha lassato senza niente: €%d." % visibili
	return "Nun tiene niente 'a sequestrà. Stavota t'e' jut' bbona."


func add_heat(amount: float) -> void:
	var was_max: bool = heat >= HEAT_MAX
	heat = clamp(heat + amount, 0.0, HEAT_MAX)
	heat_changed.emit(heat)
	# Solo sulla TRANSIZIONE verso il massimo: altrimenti ogni azione
	# rischiosa successiva farebbe ripartire l'inseguimento da capo
	# (azzerando il timer di fuga) e il vigile diventerebbe inseminabile.
	if heat >= HEAT_MAX and not was_max:
		player_caught.emit()


func cool_down(amount: float) -> void:
	heat = clamp(heat - amount, 0.0, HEAT_MAX)
	heat_changed.emit(heat)


## Un'azione rischiosa (chiedere la mancia, inseguire per farsi pagare,
## danneggiare un'auto): il sospetto sale, il doppio se in quel momento
## un vigile ha linea di vista sul player ("colto sul fatto").
func report_risky_action(base_amount: float) -> void:
	var seen: bool = nu_vigile_te_vede() != null
	var amount := base_amount * (SEEN_HEAT_MULTIPLIER if seen else 1.0)
	if upgrades.get("gilet", false):
		amount *= 0.5 # il gilet fasullo: sembri uno che ha il diritto di stare lì
	# **Gli occhiali da sole servono quando ti VEDONO.**
	#
	# Erano l'oggetto piu' inutile del banchetto: costavano quattordici euro
	# e la descrizione prometteva "un filo di sospetto in meno" che nel
	# codice non esisteva. Adesso valgono un terzo del sovrapprezzo di
	# essere colti sul fatto — cioe' non fanno niente quando nessuno ti
	# guarda, e tolgono un pezzo del danno quando ti guardano. Che e'
	# esattamente quello che uno si aspetta da un paio di occhiali scuri.
	if seen and upgrades.get("occhiali", false):
		amount *= 0.68
	add_heat(amount)


func add_reputation(amount: int) -> void:
	reputation += amount
	reputation_changed.emit(reputation)


func register_client_served() -> void:
	clients_served += 1


func register_client_lost() -> void:
	clients_lost += 1


func register_car_damaged() -> void:
	cars_damaged += 1


# ---------------------------------------------------------------------------
# 'A NOMMA — pecché serve rompere 'na machina
# ---------------------------------------------------------------------------
#
# **'O problema, ditto d''o capo:** *"Distruggere le macchine dei clienti
# che non pagano deve avere un senso, perché per ora non ha nessun motivo
# di esistere come meccanica."*
#
# Aveva ragione, e il conto era netto: rigare una macchina costava dieci
# punti di sospetto e non dava **niente**. Zero soldi, zero conseguenze,
# zero informazione. Un tasto che si può premere e che non porta da nessuna
# parte non è una scelta: è un errore di progetto travestito da libertà.
#
# **Chello ca ce vò 'a fa'**, e che è anche l'unica cosa vera: il mestiere
# del parcheggiatore abusivo non si regge sul servizio, si regge sulla
# **paura**. Uno paga due euro non perché gli hai posteggiato la macchina,
# ma perché sa cosa succede a chi non paga. La macchina rigata **è la
# pubblicità**.
#
# Quindi: se righi la macchina di uno **che ti ha rifiutato i soldi**, e
# succede dove qualcuno lo può vedere, la voce gira. Da lì:
#
#   * i clienti dopo rifiutano di meno (fino a +22 punti percentuali);
#   * ma il quartiere ti guarda storto, e il vigile pure: la nomma
#     alimenta il sospetto di fondo, e sopra una certa soglia le signore
#     cambiano marciapiede.
#
# Non è gratis, ed è questo che la rende una scelta: stai comprando
# incassi con l'attenzione addosso. Ed è per questo che **scende da sola**
# ogni giorno — una brutta reputazione va rinfrescata, se no la gente si
# dimentica, e rinfrescarla vuol dire rischiare di nuovo.
signal nomma_cambiata(quanta: float)

## Quanto conta, al massimo, sulla probabilità che un cliente paghi.
const NOMMA_PAGAMENTO: float = 0.22
## Quanto ne sale a ogni macchina rigata a chi non ha pagato.
const NOMMA_PER_VENDETTA: float = 26.0
## Quanto ne scende ogni giornata.
const NOMMA_SCENDE_AL_JUORNO: float = 34.0

var nomma: float = 0.0


## Hê rigato 'a machina 'e chillo ca nun ha pagato.
func vendetta_fatta(visto: bool) -> void:
	var prima: float = nomma
	# Se non ti ha visto nessuno la voce gira lo stesso, ma meno: il danno
	# si vede, il colpevole no.
	nomma = clampf(nomma + NOMMA_PER_VENDETTA * (1.0 if visto else 0.45),
		0.0, 100.0)
	if not is_equal_approx(prima, nomma):
		nomma_cambiata.emit(nomma)
	if prima < 50.0 and nomma >= 50.0:
		event_started.emit(
			"'A voce sta girando: 'o parcheggiatore d''a piazza nun se sfotte.")


## Quanto la nomma aiuta a farsi pagare, da 0 a NOMMA_PAGAMENTO.
func bonus_nomma() -> float:
	return NOMMA_PAGAMENTO * clampf(nomma / 100.0, 0.0, 1.0)


func register_forced_payment() -> void:
	forced_payments += 1


# ---------------------------------------------------------------------------
# 'E rapporte cu 'a gente d''o quartiere
# ---------------------------------------------------------------------------
#
# **'A nomma è chello ca 'o quartiere penza 'e te. Chisto è chello ca penza
# 'e te Gennaro.**
#
# Sono due cose diverse e serviva la seconda. La `nomma` è un numero solo
# per tutti: sale quando righi una macchina e scende da sola, e vale uguale
# per chiunque arrivi in piazza. Va benissimo per la paura — la paura è una
# voce che gira — ma non regge il rapporto, perché un rapporto è **con
# qualcuno**, e qualcuno deve avere un nome.
#
# Qui ogni cliente fisso (vedi `scripts/gente.gd`) tiene due numeri:
#
#   * `visto` — quante volte ti ha incontrato. Serve al saluto: la prima
#     volta uno ti chiede il posto, la seconda ti dice "uè".
#   * `rap` — da −100 a +100. Sopra a +40 sei uno di casa, sotto a −40 sei
#     quello che gli ha fatto il danno.
#
# Il moltiplicatore `memoria` della tabella dice quanto in fretta si muove:
# Donna Assunta al doppio (si ricorda tutto), 'o Tedesco a metà (fra un
# anno e l'altro le facce si confondono).
#
# **Sta dint'ô salvataggio**, ed è tutto il punto: se si azzerasse ogni
# mattina sarebbe un altro sistema di punti dentro la giornata, e di quelli
# ce ne sono già. La piazza si costruisce fra le giornate, non dentro.

const Gente := preload("res://scripts/gente.gd")

## Quanto si muove il rapporto, prima del moltiplicatore del personaggio.
##
## **'Na vota sola nun basta maje.** I tre numeri qui sotto hanno un
## vincolo che non si vede leggendoli: moltiplicati per la memoria più
## alta della tabella (Donna Assunta, ×2) devono restare **sotto a 40**,
## che è la soglia del nemico. Con i valori della prima stesura
## (danno −30) una sola rigata la portava a −60: un click, e la cliente
## più memorabile del gioco era persa per sempre.
##
## Un rapporto che finisce con un gesto solo non è un rapporto, è
## un'opzione a senso unico. Ci vogliono **due** volte anche con lei —
## che resta comunque la più svelta a offendersi di tutti e sei.
## `prova_gente` lo verifica sui tre numeri e su tutta la tabella.
const RAPPORTO_PAGATO: float = 7.0
const RAPPORTO_FORZATO: float = -16.0
const RAPPORTO_DANNO: float = -18.0

## id -> {"visto": int, "rap": float}
var rapporti: Dictionary = {}
## Chi sta in piazza proprio adesso: due Gennaro nella stessa piazza no.
var _clienti_fore: Array[String] = []


func _voce_rapporto(id: String) -> Dictionary:
	if not rapporti.has(id):
		rapporti[id] = {"visto": 0, "rap": 0.0}
	return rapporti[id]


## Quante volte t'ha visto.
func visto_quante(id: String) -> int:
	return int(_voce_rapporto(id)["visto"])


## Comme te tratta, 'a −100 a +100.
func rapporto(id: String) -> float:
	return float(_voce_rapporto(id)["rap"])


func conosce(id: String) -> bool:
	return visto_quante(id) > 0


## Sta arrivanno: se segna l'incontro e nun 'o fa arrivà 'na seconda vota.
func cliente_arriva(id: String) -> void:
	if id == "":
		return
	if not _clienti_fore.has(id):
		_clienti_fore.append(id)
	var v: Dictionary = _voce_rapporto(id)
	v["visto"] = int(v["visto"]) + 1


func cliente_se_ne_va(id: String) -> void:
	_clienti_fore.erase(id)


## Piglia 'nu cliente fisso ca mo' nun sta â piazza. Torna "" si stanno
## tutte quante fore.
func cliente_libbero() -> String:
	var libbere: Array[String] = []
	for c in Gente.CLIENTI:
		var id := str(c["id"])
		if not _clienti_fore.has(id):
			libbere.append(id)
	if libbere.is_empty():
		return ""
	return libbere[randi() % libbere.size()]


# ---------------------------------------------------------------------------
# 'A voce ca gira
# ---------------------------------------------------------------------------
#
# **'O ponte ca mancava fra 'e clienti fisse e 'a piazza.**
#
# La roadmap 0.55 lo diceva chiaro: *"adesso il rapporto cambia solo quanto
# pagano. Un amico dovrebbe anche dirti le cose, e un nemico dovrebbe
# parlarne in giro"*. La prima metà l'ho scartata — dopo la 0.55 le
# informazioni che i personaggi ti dicono sono la cosa che il capo ha
# tolto, e rimetterla dalla porta di servizio sarebbe stato non aver
# capito. La seconda metà invece è esattamente giusta, e vale per tutte e
# due le direzioni.
#
# Perché il difetto vero era questo: i sei clienti con il nome erano **sei
# rapporti chiusi in sé**. Trattavi bene Gennaro e ne guadagnavi con
# Gennaro. Rigare la macchina di Donna Assunta costava Donna Assunta. Ma
# una piazza non funziona così — in una piazza **si parla**, e quello che
# fai al secondo cliente lo sa il quarantesimo.
#
# `voce` è la media di come ti tratta chi ti conosce, da −1 a +1, e tocca
# **tutti**: gli sconosciuti pagano un po' più volentieri se il quartiere
# parla bene di te, e molto meno se parla male. È anche il primo posto in
# cui si vede che i sei non sono sei minigiochi separati: sono la piazza.
#
# Non è la `nomma`, che è un'altra cosa e resta: quella è la **paura** (chi
# sa che righi le macchine discute meno), questa è la **stima**. Si possono
# avere tutte e due, e sono due modi opposti di farsi pagare.

## Quanto pesa, al massimo, sulla probabilità che uno qualunque paghi.
const VOCE_PAGAMENTO: float = 0.14
## E sulla mancia.
const VOCE_MANCIA: float = 0.16


## Da −1 (te ne parlano male) a +1 (te ne parlano bene). Zero se ancora
## nessuno ti conosce.
func voce() -> float:
	var somma := 0.0
	var quanti := 0
	for id in rapporti:
		var v: Dictionary = rapporti[id]
		if int(v.get("visto", 0)) <= 0:
			continue
		somma += clampf(float(v.get("rap", 0.0)) / 100.0, -1.0, 1.0)
		quanti += 1
	if quanti == 0:
		return 0.0
	return clampf(somma / float(quanti), -1.0, 1.0)


## Quanto la voce aiuta (o toglie) sulla probabilità di essere pagato.
##
## **'O male pesa 'o doppio d''o bene**, come per i rapporti singoli: farsi
## voler bene dal quartiere aiuta, farsi odiare costa. Uno che ha rigato
## tre macchine su sei si trova la piazza fredda anche con chi non c'era.
func bonus_voce() -> float:
	var v: float = voce()
	return VOCE_PAGAMENTO * v * (1.0 if v >= 0.0 else 2.0)


func mancia_voce() -> float:
	var v: float = voce()
	return 1.0 + VOCE_MANCIA * v * (1.0 if v >= 0.0 else 2.0)


## Muove 'o rapporto, cu 'a memoria d''o personaggio.
func muove_rapporto(id: String, quanto: float) -> void:
	if id == "":
		return
	var c: Dictionary = Gente.chi(id)
	if c.is_empty():
		return
	var v: Dictionary = _voce_rapporto(id)
	var prima: float = float(v["rap"])
	v["rap"] = clampf(prima + quanto * float(c["memoria"]), -100.0, 100.0)
	# Le due soglie sono le uniche due volte in cui vale la pena di dire
	# qualcosa: il resto è un numero che si muove piano e non è una notizia.
	var doppo: float = float(v["rap"])
	if prima < Gente.AMICO and doppo >= Gente.AMICO:
		event_started.emit("%s mo' te tratta comme a uno 'e casa." % c["nome"])
	elif prima > Gente.NEMICO and doppo <= Gente.NEMICO:
		event_started.emit("%s nun te vò vedé cchiù." % c["nome"])


# --- Inventario stemmi ---

func add_emblem(emblem_name: String, value: int) -> void:
	if emblems.has(emblem_name):
		emblems[emblem_name]["count"] += 1
	else:
		emblems[emblem_name] = {"count": 1, "value": value}
	emblems_stolen += 1
	inventory_changed.emit(emblems)


## Ridà uno stemma a chi se l'è ripreso: si molla quello che vale meno.
## Serve al confronto con il padrone dell'auto (`driver_3d.answer`).
func togli_uno_stemma() -> void:
	if emblems.is_empty():
		return
	var chiavi: Array = emblems.keys()
	chiavi.sort_custom(func(a, b): return int(emblems[a]["value"]) \
		< int(emblems[b]["value"]))
	var k = chiavi[0]
	var voce: Dictionary = emblems[k]
	voce["count"] = int(voce["count"]) - 1
	if int(voce["count"]) <= 0:
		emblems.erase(k)
	inventory_changed.emit(emblems)


func emblem_count() -> int:
	var total := 0
	for key in emblems:
		total += emblems[key]["count"]
	return total


func emblems_total_value() -> int:
	var total := 0
	for key in emblems:
		total += emblems[key]["count"] * emblems[key]["value"]
	return total


## Vende tutti gli stemmi al ricettatore; ritorna quanto ha fruttato.
## Lo stemma della commissione attiva vale il triplo (e la chiude).
func sell_all_emblems() -> int:
	var total := 0
	var commission_hit := false
	for emblem_name in emblems:
		var entry: Dictionary = emblems[emblem_name]
		var mult := 1
		if not active_commission.is_empty() and emblem_name == active_commission["name"]:
			mult = int(active_commission["mult"])
			commission_hit = true
		total += int(entry["count"]) * int(entry["value"]) * mult
	if total > 0:
		add_money(total)
		emblem_earnings += total
		emblems.clear()
		inventory_changed.emit(emblems)
		if commission_hit:
			active_commission = {}
			commission_changed.emit()
			event_started.emit("Commissione completata! 'O Zio è soddisfatto.")
	return total


## Compra un upgrade da 'O Zio. Ritorna true se l'acquisto va a buon fine.
## Il caffe' del bar: si compra alla tabaccheria, tre alla volta.
func buy_caffe() -> bool:
	if money < CAFFE_COST * CAFFE_PER_GIRO:
		return false
	money -= CAFFE_COST * CAFFE_PER_GIRO
	caffe += CAFFE_PER_GIRO
	money_changed.emit(money)
	caffe_changed.emit(caffe)
	save_game()
	return true


## Se lo scola in piedi al banco, come si deve. Toglie sospetto, rimette in
## sesto e per un quarto di minuto si corre come a vent'anni.
func bevi_caffe() -> bool:
	if caffe <= 0:
		return false
	caffe -= 1
	caffe_boost = CAFFE_DURATA
	cool_down(CAFFE_CALMA)
	health = minf(100.0, health + CAFFE_OSSA)
	health_changed.emit(health)
	rimette_sciato(SCIATO_CAFE)
	caffe_changed.emit(caffe)
	return true


## Il caffe' preso al banco del bar: non consuma la scorta, si paga li'
## sul momento. E' lo stesso effetto della tazzina di tasca — sospetto giu',
## ossa su e un quarto di minuto di gambe buone — ma senza doverne avere
## comprato uno prima. Al bar ci si va apposta.
func caffe_al_banco() -> void:
	caffe_boost = CAFFE_DURATA
	cool_down(CAFFE_CALMA)
	health = minf(100.0, health + CAFFE_OSSA)
	health_changed.emit(health)
	# **E mezzo sciato** (0.56): è la ragione per cui il bar esiste, e il
	# motivo per cui una scazzottata lunga costa un caffè.
	rimette_sciato(SCIATO_CAFE)


## Vero se il fischietto e' pronto (e se ce l'hai).
func puo_fischiare() -> bool:
	return has_upgrade("fischietto") and fischio_cd <= 0.0


func fischia() -> bool:
	if not puo_fischiare():
		return false
	fischio_cd = FISCHIO_RICARICA
	fischio_suonato.emit()
	return true


## **Gli attrezzi si comprano una volta, le decorazioni quante ne vuoi.**
##
## Un secondo gilet non serve a niente: o ce l'hai o no. Un secondo
## ombrellone invece serve — copre un altro pezzo di piazza — e tre sedie
## sono tre sedie. Quindi al Bazar il negozio non dice piu' "gia' tuo": ti
## vende la seconda, e ognuna finisce nello zaino da piazzare.
func buy_upgrade(upgrade_id: String) -> bool:
	if not UPGRADES.has(upgrade_id):
		return false
	var e_decoro: bool = upgrade_id in DECOR_IDS
	if not e_decoro and upgrades.get(upgrade_id, false):
		return false
	if e_decoro and decor_possedute(upgrade_id) >= DECOR_MAX_COPIE:
		return false
	var cost: int = UPGRADES[upgrade_id]["cost"]
	if money < cost:
		return false
	money -= cost
	money_changed.emit(money)
	upgrades[upgrade_id] = true
	if e_decoro:
		decor_copie[upgrade_id] = decor_possedute(upgrade_id) + 1
	upgrade_purchased.emit(upgrade_id)
	return true


## Quante copie della stessa decorazione si possono avere. Non e' un limite
## di gioco, e' un limite di buon senso: sei ombrelloni sono gia' tanti, e
## senza tetto uno ci mette dentro trenta sedie e la piazza non si vede piu'.
const DECOR_MAX_COPIE: int = 6


func has_upgrade(upgrade_id: String) -> bool:
	return upgrades.get(upgrade_id, false)


# ---------------------------------------------------------------------------
# Comprare in due tempi
# ---------------------------------------------------------------------------
#
# **Prima si guarda, poi si paga.** Premere un numero davanti al banco
# comprava all'istante: chi voleva solo sapere a che serve l'ombrellone si
# ritrovava l'ombrellone e venticinque euro in meno. E la descrizione stava
# nel pannello — cioe' la leggevi DOPO, quando ormai avevi pagato.
#
# Adesso il primo tasto sceglie e apre la scheda; lo stesso tasto, premuto
# di nuovo, compra. Chi sa gia' cosa vuole preme due volte e non se ne
# accorge; chi sta guardando puo' girare tutto il listino senza spendere
# una lira.

signal negozio_selezione(id: String)

## Cosa e' selezionato in questo momento al banco. Vuoto = niente.
var negozio_scelto: String = ""


## Ritorna `true` se questo e' il SECONDO tasto sullo stesso oggetto —
## cioe' se e' la conferma e si puo' incassare.
func scegli_in_negozio(id: String) -> bool:
	if negozio_scelto == id:
		return true
	negozio_scelto = id
	negozio_selezione.emit(id)
	return false


## Si lascia il banco (o si cambia negozio): la scelta decade, cosi' il
## primo tasto al banco successivo non compra per inerzia.
func azzera_scelta_negozio() -> void:
	if negozio_scelto == "":
		return
	negozio_scelto = ""
	negozio_selezione.emit("")


# --- Sigarette (tabaccheria) ---

func buy_cigarettes() -> bool:
	if money < CIGARETTE_PACK_COST:
		return false
	money -= CIGARETTE_PACK_COST
	cigarettes += CIGARETTES_PER_PACK
	money_changed.emit(money)
	cigarettes_changed.emit(cigarettes)
	save_game()
	return true


func consume_cigarette() -> bool:
	if cigarettes <= 0:
		return false
	cigarettes -= 1
	cigarettes_changed.emit(cigarettes)
	return true


# ---------------------------------------------------------------------------
# 'O salvataggio, chillo overo
# ---------------------------------------------------------------------------
#
# **Perché era stato tolto, e perché adesso torna.**
#
# C'era un salvataggio automatico, uno solo, che si riscriveva da sé. Con
# una partita da tre minuti andava bene; con una città da girare no: ti
# ritrovavi all'avvio con le piazze già comprate, la mazza in mano e la
# collezione completa, e non c'era più niente da fare. E chi rigiocava dopo
# una modifica si portava dietro uno stato vecchio e vedeva bug che non
# esistevano più. Allora l'ho spento.
#
# La risposta giusta però non era spegnerlo: era **darlo in mano al
# giocatore**. Quattro slot, si salva quando vuoi tu e si carica quando
# vuoi tu. Una partita nuova parte sempre pulita, e quella di ieri sta
# ferma dov'era finché non la richiami.
#
# Il file è JSON in `user://`, uno per slot. Se un file è di una versione
# più vecchia lo slot si vede lo stesso ma dice "vecchio": è meglio
# mostrarlo e rifiutarlo che far sparire una partita senza spiegazioni.

# ===========================================================================
# 'A FAMIGLIA E 'O CUNTO
# ===========================================================================
#
# **Il problema che risolve, in una riga: niente ti toglieva i soldi.**
#
# Fino alla 0.43 il portafoglio saliva e basta. Il gioco raccontava un uomo
# che non arriva a fine mese, e meccanicamente raccontava un uomo che
# accumula capitale senza spese. Vinceva la meccanica, e la storia non si
# sentiva.
#
# Adesso ogni mattina ci sta un conto. Non e' un obiettivo — e' un **debito
# gia' contratto**, che qualcuno ha deciso per te prima che tu ti
# svegliassi. E cambia il significato di tutto quello che c'era gia':
#
#   - tre euro di mancia diventano *tre dei sessantotto*;
#   - la multa da cinquanta diventa una catastrofe invece di un numero;
#   - la sedia sdraio diventa una scelta (dieci secondi che non lavori);
#   - il gilet da trenta euro smette di essere shopping e diventa una cosa
#     che devi decidere se ti puoi permettere.
#
# E soprattutto: **la sera acquista un significato**. Prima il turno finiva
# e basta. Adesso la sera si torna a casa, si consegna, e si scopre com'e'
# andata.

## Le voci fisse del bilancio di casa.
##
## `ogni` e' ogni quanti giorni ricompare. Le medie: 'a spesa 18 al giorno,
## 'a luce 55 ogni quattro (13,8), 'a scola 31 ogni cinque (6,2), 'o fitto
## 120 ogni sette (17,1). Fanno **cinquantacinque euro al giorno**, che
## contro una giornata onesta da settanta-novanta lascia da parte qualcosa
## ma non regala niente. E' la cifra che decide tutto il gioco: piu' alta e
## non si respira, piu' bassa e si torna alla 0.43.
##
## **0.62**: tutto giù di un sesto (spesa 11-18, luce 40-56, fitto 92-118:
## circa **quarantasette euro al giorno** di fisse, sessanta con le
## disgrazie). Con 55-66 al giorno contro una giornata onesta da settanta
## i primi tre giorni erano un'apnea, e il capo ha chiesto un gioco
## *«divertente, non frustrante»*: adesso una giornata fatta bene lascia
## da parte una ventina d'euro, una fatta male non ti affoga.
const SPESE_FISSE := {
	"spesa": {
		"nome": "'A spesa", "min": 11, "max": 18, "ogni": 1, "primo": 1,
		"grave": false,
		"desc": "'O ppane, 'a pasta, quacche ccosa p''e criature.",
	},
	"luce": {
		"nome": "'A luce", "min": 40, "max": 56, "ogni": 4, "primo": 3,
		"grave": true,
		"desc": "Se nun 'a pave, 'a stacca. E po' so' cchiù guaie.",
	},
	"scola": {
		"nome": "'A scola d''e criature", "min": 24, "max": 38, "ogni": 5,
		"primo": 4, "grave": false,
		"desc": "Libbre, 'o grembiule, 'a gita ca vanno tutte quante.",
	},
	"fitto": {
		"nome": "'O fitto d''a casa", "min": 92, "max": 118, "ogni": 7,
		"primo": 6, "grave": true,
		"desc": "'O padrone 'e casa nun tene pacienza. Mai tenuta.",
	},
}

## Le disgrazie: escono a sorte, una ogni tanto, e sono quelle che fanno
## saltare la giornata buona. Senza queste il bilancio diventa un
## abbonamento — sempre lo stesso numero, e dopo tre giorni non lo guardi
## piu'.
const SPESE_A_SORTE := [
	{"nome": "'O dentista 'e Nunzia", "min": 40, "max": 70,
		"desc": "Tene nu dente ca 'a fa chiagnere 'a tre juorne."},
	{"nome": "'E scarpe nove", "min": 28, "max": 45,
		"desc": "Chille 'e ttiene 'a ll'anno passato. 'O piede cresce."},
	{"nome": "'O rialo p''a cummara", "min": 22, "max": 40,
		"desc": "Se sposa 'a figlia. Nun ce può i' cu 'e mmane vacante."},
	{"nome": "'O pallone nuovo", "min": 12, "max": 22,
		"desc": "S'e' rutto ncopp''o muro 'e don Ciro. Chiagne 'a ddoje ore."},
	{"nome": "'A bombola d''o gas", "min": 32, "max": 48,
		"desc": "Fernuta a miezo 'a cucina. Comme sempe."},
	{"nome": "'O bullettino d''o motorino", "min": 35, "max": 55,
		"desc": "'A multa 'e ll'anno passato. S''a so' arricurdata mo'."},
]
const SORTE_PROB: float = 0.28

## Quanto cresce una spesa non pagata, ogni giorno che passa.
const MORA: float = 0.12
## Oltre questi giorni di ritardo su una spesa "grave" succede il fatto.
const GIORNI_PRIMA_D_O_FATTO: int = 3

## L'umore della moglie: da 0 a 100. Sotto ai venticinque comincia a
## prendersi i soldi da sola; sopra ai settantacinque ti lascia stare e
## ogni tanto ti mette qualcosa 'a parte.
var umore_moglie: float = 62.0
## Le spese ancora da pagare: [{id, nome, importo, giorno, desc, grave}].
var spese_aperte: Array = []
## Quanto le hai consegnato **oggi**.
var consegnato_oggi: int = 0
## Quanto hai perso (e vinto) al gioco oggi: lei lo viene a sapere.
var perso_al_gioco: int = 0
var vinto_al_gioco: int = 0
## L'ora in cui sei rientrato, in ore dopo mezzogiorno (0 = miezojuorno,
## 16 = 'e quatto d''a matina). -1 = ancora fuori.
var ora_ritiro: float = -1.0
## Vero quando il cronometro e' arrivato alle quattro: da li' in poi non
## arriva piu' nessuno e il gioco ti dice di andare a dormire.
var giornata_scaduta: bool = false
## Vero quando il player sta dentro al vascio.
var dentro_casa: bool = false
## Quello che la moglie ti ha chiesto in piu' stasera (le "spese
## personali"), e se gliel'hai dato.
var extra_richiesto: int = 0
var extra_dato: bool = false
## Quante sere di fila sei rientrato dopo l'una.
var sere_tardi: int = 0

signal famiglia_cambiata()
signal moglie_parla(testo: String, tono: String)
signal casa_entrata(dentro: bool)
signal giornata_scaduta_segnale()


## Le frasi. Sono la cosa piu' importante di tutto questo capitolo: il
## sistema economico si capisce in due giorni, la voce di lei te la ricordi.
const MOGLIE_TARDI := [
	"Tu t'arritire a chest'ora?! E i' m'aggia i' a fa' 'e capille! Puosa 'e sorde!",
	"Ma vide a che ora s'arritira 'o signurino! E chi t''e ttene 'e criature, 'a Madonna?",
	"A chest'ora?! E mo' me servono pure 'e sorde p''o parrucchiere, ca damane ce sta 'a cummunione!",
	"Bravo. 'E criature so' ghiute a durmi' senza vedé 'o pate. Damme 'e sorde e nun parla'.",
	"E addo' stive? Nun m''o ddicere, tanto nun ce credo. Puosa 'e sorde ncopp''a tavula.",
	"'A cummara m'ha ditto ca t'ha visto 'o bar. Bravo. Mo' me servono trenta euro p''e mieje.",
]
const MOGLIE_POCO := [
	"E cu chesto che ce faccio? Ce faccio 'o brodo cu ll'acqua?",
	"Chist'è tutto? Vabbuo'. Damane 'e criature magnano ll'arie.",
	"Dieci euro. Dieci. E i' te faccio 'a fatica 'e stà ccà ddintro.",
	"Nun m'abbasta manco p''o ppane. Va' a faticà cchiù assaje, va'.",
]
const MOGLIE_BENE := [
	"Bravo. Mettete assettato ca t'aggio miso 'a past'e patane.",
	"Vabbuo'. Almeno 'na vota.",
	"Chesto e' n'ommo. Va', lavate 'e mmane.",
	"Aggio pigliato pure 'o ccafe' pe' damane matina.",
]
const MOGLIE_MATTINA := [
	"Susete, ca s'è fatto miezojuorno. 'E criature so' già a scola.",
	"Ma quanto duorme? 'A jurnata se n'è ghiuta miezza.",
	"Aggio miso 'o ccafe'. Piglia 'e sorde e vide che ce sta 'a pavà.",
	"Damme retta: oggi nun fa' 'o strunzo cu 'o vigile.",
]
const MOGLIE_GIOCO := [
	"Me l'hanno ditto ca stive cu 'e ccarte. Bravo assaje.",
	"'E sorde ce 'e joche, eh? E 'a spesa 'a faccio cu 'e ffiglie.",
	"Tu t''e joche e i' conto 'e ccentesime. Bella vita 'a toia.",
]


# ---------------------------------------------------------------------------
# 'E GHIORNATE SPECIALE
# ---------------------------------------------------------------------------
#
# **'Na jurnata speciale è 'na sesta riga d''a tabella d''e ffasce.**
#
# La 0.51 ha dato una forma alle ore. Questa dà la stessa forma ai giorni,
# e la cosa importante è che **non è un sistema nuovo**: è un secondo
# moltiplicatore che si moltiplica al primo. Le fasce dicono com'è questa
# ora; la giornata dice com'è oggi. Due numeri, e la piazza cambia faccia
# senza che nessuno abbia scritto un caso particolare.
#
# Cinque giornate, e ognuna cambia il gioco in un modo diverso:
#
#   * **'A partita** — la città si svuota per novanta minuti e poi esplode:
#     poche auto ma mance grosse, e il vigile guarda la partita al bar;
#   * **'A pioggia** — meno gente in giro, ma chi esce paga meglio, e il
#     vigile sta al coperto (meno multe);
#   * **'O mercato** — traffico il doppio, mance magre, e i vigili in giro
#     sul serio: la giornata in cui si lavora tanto per poco;
#   * **'A processione** — mezza piazza è chiusa: pochissime auto, ma la
#     gente in strada è il triplo (borse, distrazione, occasioni);
#   * **'O primmo d''o mese** — la gente ha appena preso i soldi: mance
#     alte e tutti al banco delle scommesse.
#
# **'O tipo 'e jurnata se sape 'a matina**, dal biglietto sulla porta:
# `biglietto()` è la riga che il giocatore legge prima di uscire, ed è
# quella che rende la giornata una decisione invece di una sorpresa.
const GIURNATE := [
	{"id": "normale", "nome": "'na jurnata comme a ll'ate",
	 "arrivi": 1.0, "mancia": 1.0, "gente": 1.0, "multe": 1.0,
	 "biglietto": "Niente 'e speciale, oggi. Se fatica e se torna.",
	 "cunziglio": ""},
	{"id": "partita", "nome": "'o juorno d''a partita",
	 "arrivi": 1.30, "mancia": 1.45, "gente": 0.7, "multe": 0.55,
	 "biglietto": "Oggi joca 'o Napule. 'A gente esce tarde e torna tutta 'nzieme.",
	 "cunziglio": "Poche machine, ma chi vene lassa 'o doppio. E 'o vigile sta ô bar."},
	{"id": "pioggia", "nome": "'na jurnata 'e chiuvete",
	 "arrivi": 1.35, "mancia": 1.30, "gente": 0.55, "multe": 0.5,
	 "biglietto": "Chiove. Piglia 'o gilet ca t'abbagne.",
	 "cunziglio": "Meno gente, ma chi scenne cu 'a pioggia pava e nun discute."},
	{"id": "mercato", "nome": "'o juorno d''o mercato",
	 "arrivi": 0.60, "mancia": 0.80, "gente": 1.6, "multe": 1.45,
	 "biglietto": "Oggi ce sta 'o mercato. 'A via è chiena 'e bancarelle.",
	 "cunziglio": "Machine assaje ma pavano poco — e 'e vigile stanno 'n giro overo."},
	{"id": "processione", "nome": "'o juorno d''a prucessione",
	 "arrivi": 1.70, "mancia": 1.15, "gente": 2.0, "multe": 0.7,
	 "biglietto": "Esce 'a prucessione. Mezza piazza è chiusa.",
	 "cunziglio": "Machine quase nisciuna, ma 'a via è chiena 'e gente distratta."},
	{"id": "primmo", "nome": "'o primmo d''o mese",
	 "arrivi": 0.78, "mancia": 1.35, "gente": 1.25, "multe": 1.0,
	 "biglietto": "È 'o primmo d''o mese: 'a gente ha pigliato 'e sorde.",
	 "cunziglio": "Mance grosse, e â sala scummesse ce sta 'a fila."},
]

signal giornata_speciale(id: String)

## Che giornata è oggi. Si decide la mattina, in `prepara_giornata()`.
var tipo_giornata: String = "normale"


func giornata_di_oggi() -> Dictionary:
	for g in GIURNATE:
		if str(g["id"]) == tipo_giornata:
			return g
	return GIURNATE[0]


func giornata_nome() -> String:
	return str(giornata_di_oggi()["nome"])


func biglietto() -> String:
	return str(giornata_di_oggi()["biglietto"])


func cunziglio_d_a_jurnata() -> String:
	return str(giornata_di_oggi()["cunziglio"])


func e_speciale() -> bool:
	return tipo_giornata != "normale"


## I due numeri che si moltiplicano a quelli della fascia.
func attesa_giornata() -> float:
	return float(giornata_di_oggi()["arrivi"])


func mancia_giornata() -> float:
	return float(giornata_di_oggi()["mancia"])


## Quanta gente cammina per strada, rispetto al solito.
func gente_giornata() -> float:
	return float(giornata_di_oggi()["gente"])


## Quanto è probabile che il vigile scriva la multa, rispetto al solito.
func multe_giornata() -> float:
	return float(giornata_di_oggi()["multe"])


## **'A prima jurnata è sempe normale.** Il primo giorno il gioco insegna
## come si sta in piazza; una processione al giorno uno vorrebbe dire
## imparare le regole sbagliate. Dal secondo in poi, una volta su tre.
const SPECIALE_OGNI: float = 0.34


func _scegli_giornata() -> void:
	tipo_giornata = "normale"
	if giornata <= 1:
		return
	if randf() >= SPECIALE_OGNI:
		return
	# Il primo del mese è il primo del mese: ogni trenta giorni, e vince
	# sulle altre. Le altre quattro a sorte.
	if giornata % 30 == 1:
		tipo_giornata = "primmo"
	else:
		tipo_giornata = str(GIURNATE[1 + (randi() % 4)]["id"])
	giornata_speciale.emit(tipo_giornata)


## Prepara le spese di oggi. Si chiama a inizio giornata.
func prepara_giornata() -> void:
	_scegli_giornata()
	# **'E nummere 'e stasera se tirano mo'.** Vedi `_prepara_estrazione`:
	# senza questa riga 'a Signora nun po' nduvinà niente, pecché 'o
	# futuro nun sta ancora scritto.
	_prepara_estrazione()
	_scegli_a_signora()
	giornata_scaduta = false
	ora_ritiro = -1.0
	consegnato_oggi = 0
	perso_al_gioco = 0
	vinto_al_gioco = 0
	extra_richiesto = 0
	extra_dato = false

	# **'A spesa nun se cumula.** Se ieri sera non c'erano i soldi per il
	# pane, oggi non compri il pane di ieri: si e' digiunato e basta (e si
	# comincia la giornata a mezze forze — vedi `start_shift`). Sommare
	# ogni giorno una spesa non pagata a quella nuova voleva dire che due
	# giornate storte ti mettevano addosso un debito da cui non si usciva
	# piu'.
	var digiuno := false
	for s in spese_aperte.duplicate():
		if str(s.get("tipo", "")) == "spesa" and int(s["giorno"]) < giornata:
			spese_aperte.erase(s)
			digiuno = true
	if digiuno:
		umore_giu(5.0)

	# **Chi dorme buono se scéta buono.** Il gradino di casa vale un pezzo di
	# umore ogni mattina: e' il modo in cui una spesa da ventisettemila euro
	# si sente tutti i giorni invece di essere una riga nel salvataggio.
	var su: float = float(casa_mia().get("umore", 0.0))
	if su > 0.0:
		umore_moglie = minf(100.0, umore_moglie + su * 0.35)

	# **La mora, col tetto.**
	#
	# Un debito che cresce e' la cosa che fa sentire il ritardo. Un debito
	# che cresce SENZA FINE e' un vicolo cieco: la simulazione su trenta
	# giornate lo ha mostrato senza pieta' — con il dodici per cento
	# composto e nessun tetto, chi restava indietro arrivava a bollette da
	# duemilacinquecento euro e non poteva piu' rientrare in nessun modo.
	#
	# Adesso una voce non supera mai una volta e tre quarti quello che era.
	# Quello che ti punisce davvero, se non paghi, non e' il numero: sono
	# le conseguenze (vedi `_conseguenze`).
	const TETTO_MORA: float = 1.75
	for s in spese_aperte:
		var base: int = int(s.get("base", s["importo"]))
		s["importo"] = mini(int(ceil(float(s["importo"]) * (1.0 + MORA))),
			int(round(float(base) * TETTO_MORA)))

	# Le voci fisse che scadono oggi.
	# **'O primmo juorno nun se scadono tutte 'nzieme.**
	#
	# Il primo tentativo faceva scadere le quattro voci fisse tutte il
	# giorno uno: duecentosedici euro di conto prima ancora di aver
	# imparato dove sta la piazza. Adesso ogni voce ha il suo primo
	# giorno — 'a spesa subito, 'a luce 'o terzo, 'a scola 'o quarto, 'o
	# fitto 'o sesto — e la settimana entra a regime da sola.
	for id in SPESE_FISSE:
		var d: Dictionary = SPESE_FISSE[id]
		var primo: int = int(d.get("primo", 1))
		if giornata < primo or (giornata - primo) % int(d["ogni"]) != 0:
			continue
		# **Mai due bollette dello stesso tipo aperte insieme.** Se 'a luce
		# di quattro giorni fa e' ancora li', oggi non ne arriva un'altra:
		# arriva il tecnico che stacca il contatore. E' la differenza fra
		# una punizione che si accumula e una che succede.
		if _spesa_aperta_di(id):
			continue
		var quanto: int = randi_range(int(d["min"]), int(d["max"]))
		# **'A casa cchiu' bbona costa cchiu' assaje.** E' quello che rende
		# il salto al Vomero una decisione invece di un premio: ventisettemila
		# euro una volta, e poi ogni settimana un fitto quasi triplo. Chi
		# compra e poi non regge la rata la casa se la vede tornare indietro
		# come tutte le altre bollette gravi.
		if id == "fitto":
			quanto = int(round(float(quanto) * float(casa_mia().get("fitto", 1.0))))
		spese_aperte.append({
			"id": "%s_%d" % [id, giornata], "tipo": id,
			"nome": str(d["nome"]), "importo": quanto, "base": quanto,
			"giorno": giornata, "desc": str(d["desc"]),
			"grave": bool(d["grave"]),
		})

	# E la disgrazia del giorno, se tocca. Mai il primo giorno: il primo
	# giorno si impara come funziona, non si viene puniti.
	if giornata > 1 and not _spesa_aperta_di("sorte") \
			and randf() < SORTE_PROB:
		var s: Dictionary = SPESE_A_SORTE[randi() % SPESE_A_SORTE.size()]
		var q: int = randi_range(int(s["min"]), int(s["max"]))
		spese_aperte.append({
			"id": "sorte_%d" % giornata, "tipo": "sorte",
			"nome": str(s["nome"]), "importo": q, "base": q,
			"giorno": giornata, "desc": str(s["desc"]), "grave": false,
		})

	famiglia_cambiata.emit()


func _spesa_aperta_di(tipo: String) -> bool:
	for s in spese_aperte:
		if str(s.get("tipo", "")) == tipo:
			return true
	return false


## Quanto serve, in tutto, per essere in pari stasera.
func spese_dovute() -> int:
	var t := 0
	for s in spese_aperte:
		t += int(s["importo"])
	return t


## Le spese in ritardo (di ieri o prima).
func spese_arretrate() -> Array:
	var fuori: Array = []
	for s in spese_aperte:
		if int(s["giorno"]) < giornata:
			fuori.append(s)
	return fuori


## La voce piu' urgente: prima le gravi, poi le piu' vecchie.
func _ordine_spese() -> Array:
	var lista: Array = spese_aperte.duplicate()
	lista.sort_custom(func(a, b):
		if bool(a["grave"]) != bool(b["grave"]):
			return bool(a["grave"])
		return int(a["giorno"]) < int(b["giorno"]))
	return lista


## **Consegna 'e sorde.** Il gesto centrale della sera.
##
## Non si sceglie che bolletta pagare: si danno i soldi a lei e ci pensa
## lei, nell'ordine che conta (prima quelle che fanno male). Ritorna un
## resoconto per la schermata.
func consegna_a_moglie(quanto: int) -> Dictionary:
	quanto = clampi(quanto, 0, money)
	if quanto <= 0:
		return {"dato": 0, "pagate": [], "resta": spese_dovute()}
	money -= quanto
	money_changed.emit(money)
	consegnato_oggi += quanto

	var rimasto := quanto
	var pagate: Array = []
	for s in _ordine_spese():
		if rimasto <= 0:
			break
		var costo: int = int(s["importo"])
		if rimasto >= costo:
			rimasto -= costo
			pagate.append({"nome": str(s["nome"]), "importo": costo,
				"intera": true})
			spese_aperte.erase(s)
		else:
			s["importo"] = costo - rimasto
			pagate.append({"nome": str(s["nome"]), "importo": rimasto,
				"intera": false})
			rimasto = 0

	# Pagato il riallaccio, la luce torna: la casa si riaccende domani.
	if luce_staccata and not _spesa_aperta_di("riallaccio"):
		luce_staccata = false

	# Quello che avanza dopo aver pagato tutto lo mette da parte lei, e
	# l'umore sale: e' l'unico modo di guadagnare umore in fretta.
	var avanzo := rimasto
	if avanzo > 0:
		umore_moglie = minf(100.0, umore_moglie + float(avanzo) * 0.22)
	var resta := spese_dovute()
	if resta == 0:
		umore_moglie = minf(100.0, umore_moglie + 9.0)
	elif quanto < resta:
		umore_giu(4.0)
	SoundManager.soldi(quanto)
	famiglia_cambiata.emit()
	return {"dato": quanto, "pagate": pagate, "resta": resta,
		"avanzo": avanzo}


## Che tono ha stasera. Serve alla frase e alla faccia.
func tono_moglie() -> String:
	if ora_ritiro >= 0.0 and ora_ritiro > 12.0:      # dopo mezzanotte
		return "tardi"
	if perso_al_gioco >= 25:
		return "gioco"
	if spese_dovute() > 0:
		return "poco"
	return "bene"


func frase_moglie(tono: String = "") -> String:
	if tono == "":
		tono = tono_moglie()
	match tono:
		"tardi": return str(MOGLIE_TARDI[randi() % MOGLIE_TARDI.size()])
		"gioco": return str(MOGLIE_GIOCO[randi() % MOGLIE_GIOCO.size()])
		"poco": return str(MOGLIE_POCO[randi() % MOGLIE_POCO.size()])
		"mattina": return str(MOGLIE_MATTINA[randi() % MOGLIE_MATTINA.size()])
	return str(MOGLIE_BENE[randi() % MOGLIE_BENE.size()])


## **'E spese personali.** Se rientri dopo l'una, lei vuole qualcosa in
## piu', e se lo inventa ogni volta. Non e' una tassa: e' il prezzo di una
## giornata tirata fino a tardi, e si puo' pure dire di no — ma dire di no
## costa umore, e l'umore poi te lo prende lei dalle tasche.
const EXTRA_SCUSE := [
	"m'aggia i' a fa' 'e capille",
	"aggia accatta' 'o rialo p''a cummunione",
	"me servono 'e ccalze nove",
	"aggia i' 'a pettenessa cu mammà",
	"aggia paga' 'o bar d''a festa d''e criature",
	"m'aggia piglià 'e ccose mie, e nun t''e ddico",
]


func chiedi_extra() -> Dictionary:
	if ora_ritiro < 0.0 or ora_ritiro <= 12.0:
		return {}
	# Piu' tardi rientri, piu' vuole. All'una otto euro, alle quattro
	# venticinque.
	var tardi: float = clampf((ora_ritiro - 12.0) / 4.0, 0.0, 1.0)
	extra_richiesto = int(round(lerpf(8.0, 25.0, tardi)))
	return {"quanto": extra_richiesto,
		"scusa": str(EXTRA_SCUSE[randi() % EXTRA_SCUSE.size()]),
		"frase": frase_moglie("tardi")}


func paga_extra() -> bool:
	if extra_richiesto <= 0 or money < extra_richiesto:
		umore_giu(7.0)
		return false
	money -= extra_richiesto
	money_changed.emit(money)
	extra_dato = true
	umore_moglie = minf(100.0, umore_moglie + 5.0)
	SoundManager.soldi(extra_richiesto)
	famiglia_cambiata.emit()
	return true


func rifiuta_extra() -> void:
	umore_giu(12.0)
	famiglia_cambiata.emit()


## Registra una perdita (o una vincita) al gioco. Lo sa sempre.
func gioco_azzardo(delta: int) -> void:
	if delta < 0:
		perso_al_gioco += -delta
		umore_giu(float(-delta) * 0.09)
	else:
		vinto_al_gioco += delta
	famiglia_cambiata.emit()


## L'ora del gioco in ore dopo mezzogiorno, ricavata dal cronometro.
## **'O sulo orologio d''o gioco.**
##
## Da 0 (miezojuorno) a 1 (le quattro d''a matina). Ci si appendono il
## cielo, l'orologio dell'interfaccia, l'ora di rientro, la musica e le
## fasi della giornata: **tutto quello che nel gioco ha a che fare col
## tempo deve leggere questo numero e nessun altro.**
##
## Prima non era così, ed è il motivo per cui l'ora "non funzionava bene".
## C'erano **due orologi**: questo, e `GiornoNotte.avanzamento`, che si
## integrava per conto suo con `avanzamento += delta / 450`. Partivano
## insieme e misuravano la stessa cosa, quindi finché tutto filava liscio
## dicevano lo stesso numero — ma bastava un momento in cui uno dei due
## girava e l'altro no per farli separare **per sempre**, perché nessuno
## dei due sapeva dell'altro e non c'era niente che li rimettesse in pari.
##
## E i momenti c'erano: `GiornoNotte` è un nodo dentro alla città, questo è
## un autoload. Chi vive dentro alla scena si ferma quando la scena si
## ferma; l'autoload no. Un arresto, un caricamento, un pannello che mette
## in pausa in un modo diverso — e da lì in poi il cielo diceva le nove e
## l'orologio diceva mezzanotte.
##
## La cura non è sincronizzarli meglio: è **averne uno solo**. Adesso
## `GiornoNotte` non conta più niente, legge questo e basta.
func avanzamento_giornata() -> float:
	if shift_duration <= 0.0:
		return 0.0
	return 1.0 - clampf(shift_time_left / shift_duration, 0.0, 1.0)


func ore_passate() -> float:
	return avanzamento_giornata() * ORE_DI_GIORNATA


## Che ore sono, sul quadrante di ventiquattro: da 12,0 (mezzogiorno, che è
## quando si comincia) a 28,0 (le quattro del mattino dopo). È lo stesso
## conto che facevano `orologio()` e `fascia_indice()` ognuna per conto suo;
## adesso lo fa uno solo, così quando qualcuno chiede «che ora è» — il
## vigile che smonta alle venti, per dire — la risposta è una.
func ora_d_o_juorno() -> float:
	return ore_passate() + 12.0


## C'è un vigile che ti sta guardando adesso? Gli serve a `report_risky_action`
## e a chiunque debba sapere se una cosa l'hai fatta di nascosto o no.
func nu_vigile_te_vede() -> Node:
	for v in get_tree().get_nodes_in_group("vigili"):
		if v.has_method("can_see_player") and v.can_see_player():
			return v
	return null


## Da 12.0 (miezojuorno) a 28.0 (le quattro del giorno dopo).
const ORE_DI_GIORNATA: float = 16.0


func orologio() -> String:
	var ore := ora_d_o_juorno()
	var h := int(ore) % 24
	var m := int((ore - floor(ore)) * 60.0)
	return "%02d:%02d" % [h, m]


# ---------------------------------------------------------------------------
# 'E FFASCE D''A JURNATA
# ---------------------------------------------------------------------------
#
# **Sedici ore tutte uguali non sono una giornata: sono un cronometro.**
#
# Fino alla 0.50 il quindicesimo cliente era identico al primo. La piazza
# non sapeva che ora era: le macchine arrivavano con lo stesso passo a
# mezzogiorno e alle due di notte, e l'unica cosa che cambiava era il
# colore del cielo. Adesso l'orologio — che dalla 0.51 è **uno solo** e
# non se ne va più per i fatti suoi — comanda due numeri:
#
#   * **`attesa`** — quanto si aspetta fra un'auto e l'altra. Sopra 1 si
#     aspetta di più, sotto 1 di meno;
#   * **`mancia`** — quanto lascia chi paga.
#
# I due numeri vanno **in direzione opposta**, ed è tutto il punto. Le ore
# morte hanno poche macchine e mance magre: sono le ore in cui conviene
# lasciare la piazza e andarsi a prendere un lavoretto alla bacheca. Le
# ore piene rendono da sole, e la bacheca in quel momento è tempo buttato.
# La notte è il caso strano: tre macchine in croce, ma chi scende a
# quell'ora ha bevuto e paga il doppio — è l'ora in cui una piazza sola
# vale una serata intera, se reggi la stanchezza.
#
# Cinque fasce, e si giocano in cinque modi diversi. La piazza è sempre
# quella.
const FASCE: Array = [
	{"da": 12.0, "nome": "'a controra", "attesa": 1.30, "mancia": 0.95,
	 "detto": "Miezojuorno: 'a gente mangia, 'a piazza dorme."},
	{"da": 15.0, "nome": "'e ttre morte", "attesa": 1.65, "mancia": 0.90,
	 "detto": "'E ttre: nun se move manco n'aria. Vide 'a bacheca."},
	{"da": 18.0, "nome": "ll'aperitivo", "attesa": 0.62, "mancia": 1.12,
	 "detto": "'E ssei: mo' scenne 'a gente p''o spritz."},
	{"da": 21.0, "nome": "'e rristorante", "attesa": 0.52, "mancia": 1.22,
	 "detto": "Nove 'e sera: chest'è ll'ora bbona. Nun te movere."},
	{"da": 24.0, "nome": "'a nuttata", "attesa": 1.45, "mancia": 1.95,
	 "detto": "Mezzanotte: poca gente, ma se pava 'o doppio."},
]

## Quale fascia sta correndo, per indice. Si conta all'indietro: la prima
## fascia il cui `da` è già passato è quella buona.
func fascia_indice() -> int:
	var ora: float = ora_d_o_juorno()
	var i: int = 0
	for k in range(FASCE.size()):
		if ora >= float(FASCE[k]["da"]):
			i = k
	return i


func fascia() -> Dictionary:
	return FASCE[fascia_indice()]


func fascia_nome() -> String:
	return str(fascia()["nome"])


## Moltiplicatore dell'attesa fra un'auto e l'altra dovuto all'ora.
## Durante lo scontro finale non si muove niente: si resta com'era.
func attesa_fascia() -> float:
	return float(fascia()["attesa"])


## Ora e giornata insieme: e' questo che guarda la piazza per decidere
## ogni quanto arriva una macchina.
func attesa_ora_e_juorno() -> float:
	return attesa_fascia() * attesa_giornata()


func mancia_fascia() -> float:
	return float(fascia()["mancia"])


## L'ultima fascia annunciata. A -1 così la prima passata di `_process`
## dice sempre che ora è, appena comincia il turno.
var _fascia_detta: int = -1
signal fascia_cambiata(indice: int)


func _passo_fasce() -> void:
	var i: int = fascia_indice()
	if i == _fascia_detta:
		return
	var primma: int = _fascia_detta
	_fascia_detta = i
	fascia_cambiata.emit(i)
	# La prima fascia della giornata non si annuncia: il giocatore ha
	# appena letto il riepilogo della mattina, non gli serve un cartello
	# che gli dica che è mezzogiorno.
	if primma < 0:
		return
	event_started.emit(str(FASCE[i]["detto"]))
	# **'O giro d''a sera** (0.61). Dalle nove in poi, se qualcuno dei tuoi
	# guagliuni tiene soldi in mano, te lo si ricorda: è il momento di
	# passare a ritirare, e chi non passa lascia a loro la metà.
	if i >= 3 and cassa_in_giro() > 0:
		var chi: Array = []
		for zid in dipendenti:
			var c: int = int(dipendenti[zid].get("cassa", 0))
			if c > 0:
				chi.append("%s €%d" % [str(dipendenti[zid].get("nome", "?")), c])
		event_started.emit("'E guagliune t'aspettano p''a parte toja: %s. Si nun passe, stanotte se teneno 'a mità."
			% ", ".join(chi))


# ---------------------------------------------------------------------------
# 'E BOSS D''E JURNATE
# ---------------------------------------------------------------------------
#
# **Un boss non è un nemico più grosso: è la fine di un capitolo.**
#
# Borrelli è scritto meglio di qualunque altra cosa nel gioco: è quello che
# ti guarda in faccia e ti chiede perché dovrebbe pagarti.
#
# **E pecché mo' nun vene cchiù ogne sera (0.53).**
#
# Il capo: *"Borrelli arriva subito. Avevamo detto di lasciare un 1% di
# possibilità che spawni quando il vigile fa la multa o ti vedono che
# picchi qualcuno."*
#
# Aveva ragione, e la diagnosi è più interessante della correzione. Fino
# alla 0.52 Borrelli arrivava **col calendario**: la prima sera per forza,
# poi ogni due giorni se avevi più piazze, ogni volta che facevi più di
# centodieci euro, e comunque ogni tre giorni. Il ragionamento scritto qui
# sotto era *"il pezzo scritto meglio del gioco poteva non succedere"* — e
# la cura è stata farlo succedere sempre. Che è il modo più sicuro di
# rovinarlo: un boss che arriva perché è martedì non è una conseguenza, è
# un appuntamento. E un appuntamento non fa paura la seconda volta.
#
# **E mo' 'e porte songo doje, ma cu 'o dado ca cresce (0.63).**
#
# Il capo: *"Il boss di fine livello non esce più."* Con l'uno per cento
# fisso e la sera che rispondeva sempre di no, era vero: si poteva giocare
# una settimana intera senza vederlo. Adesso le porte sono queste due, e
# tutte e due hanno un dado che **cresce finché lui non arriva**:
#
#   * **A — 'a sera.** Quando cala la notte, dal secondo giorno in poi:
#     cinque per cento il secondo giorno, dieci il terzo, quindici il
#     quarto... (`PROB_SERA_PASSO` per ogni giorno passato senza di lui).
#     Il primo giorno non viene mai: è il giorno in cui si impara il
#     mestiere.
#   * **B — 'a chiamata.** Dal secondo giorno, ogni volta che il vigile
#     chiama i carabinieri (sospetto al massimo, o la terza volta che l'hai
#     mandato via): uno per cento la prima volta, poi più dieci ogni
#     chiamata (1, 11, 21, 31...).
#
# Quando arriva, tutti e due i dadi ripartono da capo: è un «prima o poi»,
# non un appuntamento. La violenza vista non lo chiama più: per quella ci
# sono i carabinieri.
const PROB_SERA_PASSO: float = 0.05
const PROB_CHIAMATA_BASE: float = 0.01
const PROB_CHIAMATA_PASSO: float = 0.10
## Tenuto per le prove e i salvataggi vecchi: è la B alla prima chiamata.
const PROB_BORRELLI: float = PROB_CHIAMATA_BASE

## L'ultimo giorno in cui è venuto (0 = mai). Da qui si conta la A.
var borrelli_ultimo_juorno: int = 0
## Le chiamate ai carabinieri dal secondo giorno, da quando è venuto
## l'ultima volta. Da qui si conta la B.
var borrelli_chiamate: int = 0


## La probabilità della A stasera.
func prob_borrelli_sera() -> float:
	if giornata < 2:
		return 0.0
	var dall_ultima: int = giornata - maxi(1, borrelli_ultimo_juorno)
	return clampf(PROB_SERA_PASSO * float(dall_ultima), 0.0, 1.0)


## La probabilità della B alla prossima chiamata.
func prob_borrelli_chiamata() -> float:
	if giornata < 2:
		return 0.0
	return clampf(PROB_CHIAMATA_BASE + PROB_CHIAMATA_PASSO * float(borrelli_chiamate),
		0.0, 1.0)


## È venuto: i due dadi ripartono.
func borrelli_venuto() -> void:
	borrelli_ultimo_juorno = giornata
	borrelli_chiamate = 0


## **'A porta B.** La chiama il vigile quando alza la radio per i
## carabinieri. Torna `true` se al posto della pattuglia arriva lui, così
## il vigile sa che non deve fare l'altra cosa.
func forse_chiamma_borrelli(pecche: String) -> bool:
	if boss_spawned or boss_phase or not shift_active:
		return false
	if giornata < 2:
		return false
	var p: float = prob_borrelli_chiamata()
	if randf() >= p:
		borrelli_chiamate += 1
		return false
	borrelli_venuto()
	event_started.emit(pecche)
	chiama_borrelli.emit()
	return true


## **'A porta A.** La chiede la piazza quando cala la notte.
func boss_stasera() -> bool:
	if boss_spawned or not shift_active:
		return false
	if randf() >= prob_borrelli_sera():
		return false
	borrelli_venuto()
	return true


# ---------------------------------------------------------------------------
# 'E boss 'e capitolo
# ---------------------------------------------------------------------------
#
# **'A piazza nun è 'a toia pecché ll'hê pagata. È 'a toia quanno t''a sî
# tenuta.**
#
# La roadmap 0.55 chiedeva *"boss di capitolo legati alle conquiste, sul
# modello di Borrelli"*. Il modello di Borrelli però è **l'inseguimento**:
# uno che non puoi toccare e da cui devi scappare. Rifarlo tre volte con
# tre facce diverse avrebbe dato tre Borrelli, che è lo stesso errore delle
# quattro piazze uguali.
#
# Quindi il contrario, e ha più senso lì dove succede: appena ti prendi una
# piazza, **quella sera** arriva chi la proteggeva. Non ti insegue: ti
# aspetta in mezzo alla piazza nuova e vuole la sua parte. È il momento in
# cui la conquista smette di essere una compera e diventa una storia — e
# c'è una sola sera per chiuderla.
#
# Ognuno chiede una cosa diversa, e nessuna delle tre è la stessa scelta:
#
#   * **'o Cardinale** (stadio) vuole soldi, tanti, e se paghi finisce lì;
#   * **Donna Carmela** (mercato) non vuole soldi: vuole che per tre giorni
#     il mercato lavori anche per lei — cioè una parte dell'incasso;
#   * **Tonino 'e Notte** (cornetteria) non tratta proprio: o lo stendi o
#     ti riprende la piazza.
const BOSS_CAPITOLO := {
	"stadio": {
		"nome": "'O Cardinale",
		"che": "Chillo ca teneva 'o stadio primma 'e Gennaro. Nun ce sta maje, ma tene 'e mmane 'a tutte parte.",
		"vuole": "sorde", "quanto": 260,
		"dice": "Bravo 'o guaglione. T'hê pigliato 'o stadio. Mo' me daje chello ch'è 'o mio.",
	},
	"mercato": {
		"nome": "Donna Carmela",
		"che": "Tene 'e bancarelle 'a trent'anne. Nun alza 'a voce, e nun serve.",
		"vuole": "parte", "quanto": 3,
		"dice": "'E sorde mieje nun me serveno. Pe' tre juorne 'o mercato fatica pure pe' me.",
	},
	"cornetteria": {
		"nome": "Tonino 'e Notte",
		"che": "'O padrone 'e primma, ca nun s'è rassignato. Sta sempe sveglio.",
		"vuole": "mazzate", "quanto": 0,
		"dice": "Nun tengo niente 'a tratta' cu te. 'A cornetteria è 'a mia.",
	},
}

## Zone che aspettano ancora il loro boss. Sta nel salvataggio: se te la
## prendi e vai a dormire, lui ti aspetta la sera dopo.
var boss_da_fa: Array = []
## Zone il cui boss è stato chiuso, in un modo o nell'altro. Non tornano.
var boss_fatte: Array = []

signal boss_capitolo_arriva(zona: String)


## Chiamata quando una piazza cambia padrone: da stasera c'è qualcuno che
## la rivuole. La piazza iniziale non ha boss — è casa tua da sempre.
func arma_boss_capitolo(zona: String) -> void:
	if zona == "piazza" or not BOSS_CAPITOLO.has(zona):
		return
	if boss_fatte.has(zona) or boss_da_fa.has(zona):
		return
	boss_da_fa.append(zona)


## La piazza chiama questa quando cala la notte: se c'è un boss in attesa,
## esce adesso. Uno per sera, che due insieme sarebbero una rissa.
func boss_capitolo_stasera() -> String:
	if boss_da_fa.is_empty() or not shift_active:
		return ""
	for zona in boss_da_fa:
		if zona_mia(str(zona)):
			return str(zona)
	return ""


## Quante giornate ancora il mercato lavora anche per Donna Carmela.
## Scende di uno ogni sera; finché è sopra zero, quella piazza rende meno.
var boss_parte_juorne: int = 0
## Quanto si tiene lei.
const BOSS_PARTE_QUOTA: float = 0.30


## Chi ti ha ripreso la piazza se la riprende davvero: esce dalle tue e
## smette di pagare l'affitto.
func perde_zona(id: String) -> void:
	if not zone_mie.has(id):
		return
	zone_mie.erase(id)
	affitti.erase(id)
	# E chi ci lavorava per te resta senza posto.
	if dipendenti.has(id):
		dipendenti.erase(id)
		dipendenti_cambiati.emit()
	zona_persa.emit(id)
	save_game()


func boss_capitolo(zona: String) -> Dictionary:
	return BOSS_CAPITOLO.get(zona, {})


## Chiuso: pagato, servito o steso. In tutti e tre i casi non torna più.
func boss_capitolo_fernuto(zona: String) -> void:
	boss_da_fa.erase(zona)
	if not boss_fatte.has(zona):
		boss_fatte.append(zona)


## **Ti riportano a casa.**
##
## Ospedale, carabinieri, verbale del vigile: prima chiudevano la giornata
## di colpo, e la giornata finiva **per te** mentre il gioco continuava per
## conto suo. Adesso ti riportano a casa e basta: il conto della sera resta
## quello che era, la moglie aspetta lo stesso, e sei tu che devi
## consegnare quello che ti e' rimasto e andarti a coricare.
##
## E' peggio, non meglio: perche' adesso il costo dell'arresto non e' la
## cauzione — e' il fatto che alle undici di sera devi ancora trovare
## sessanta euro e non hai piu' la piazza per farli.
signal rientro_forzato_segnale(causa: String)


## **Quanno t'hanno purtato 'a casa, 'o tiempo se ferma.**
##
## Il capo: *"non farlo sminchiare in caso di eventi tipo essere
## arrestati"*. Il guaio era che dopo un arresto il cronometro continuava
## a scorrere mentre tu stavi chiuso dentro al vascio senza poter fare
## niente: l'ora avanzava, il cielo si faceva notte, e l'ora di rientro —
## che è quella che conta per il conto e per la moglie — era già stata
## registrata **prima**. Cioè tre numeri che raccontavano tre serate
## diverse.
##
## **E 'a 0.56 nun se ferma cchiù.**
##
## Il capo: *"l'orario e lo scorrere del tempo non funzionano ancora bene e
## si bloccano se vieni arrestato o se vai a casa"*. Aveva ragione, e la
## colpa è di questa funzione — cioè della cura che avevo scritto io alla
## 0.51 e che qui sopra spiegavo con tanta convinzione.
##
## Il ragionamento era: se ti arrestano non puoi fare niente, quindi
## fermiamo l'orologio. Ma "non puoi fare niente" **non era vero**: ti
## riportavano a casa e da lì potevi uscire, girare, lavorare — con
## l'orologio fermo. Cioè il difetto che volevo curare (tre numeri che
## raccontano tre serate diverse) l'ho spostato, non tolto: adesso erano
## l'orologio e il mondo a non essere d'accordo.
##
## La cura vera non è fermare il tempo: è **far succedere qualcosa che
## consuma il tempo**. Se ti arrestano finisci in galera, la nottata se ne
## va, e ti risvegli domani mattina. L'orologio non si ferma mai — e
## `tempo_fermo` non lo tocca più nessuno.
##
## È la lezione della 0.53 (*una cura scritta bene può essere la malattia
## della versione dopo*) che si ripresenta sulla stessa funzione due
## versioni più tardi.
func rientro_forzato(causa: String) -> void:
	scinne_d_a_machina()
	if ora_ritiro < 0.0:
		ora_ritiro = ore_passate()
	giornata_scaduta = true
	rientro_forzato_segnale.emit(causa)


## Il cronometro e' arrivato in fondo: sono le quattro.
func scade_giornata() -> void:
	if giornata_scaduta:
		return
	scinne_d_a_machina()
	giornata_scaduta = true
	giornata_scaduta_segnale.emit()
	event_started.emit("So' 'e quatto d''a matina. Va' a durmi', va'.")


## **Va' a durmi'.** Chiude la giornata: e' l'unico modo di passare al
## giorno dopo, e la ragione per cui la sera esiste.
func vai_a_dormire() -> Dictionary:
	if ora_ritiro < 0.0:
		ora_ritiro = ore_passate()
	if ora_ritiro > 12.0:
		sere_tardi += 1
		umore_moglie = maxf(0.0, umore_moglie - 6.0)
	elif ora_ritiro < 9.0:
		sere_tardi = 0
		umore_moglie = minf(100.0, umore_moglie + 4.0)
	return end_shift()


## Le conseguenze del non aver pagato. Si applicano la mattina dopo, ed e'
## il pezzo che fa la differenza fra "hai perso" e "e' successo qualcosa".
func _conseguenze() -> Array:
	var fatti: Array = []
	# **La conseguenza CHIUDE la voce e ne apre un'altra.**
	#
	# Se la bolletta della luce restasse aperta per sempre, il tecnico
	# verrebbe a staccare il contatore tutte le sante mattine e nessuna
	# bolletta nuova potrebbe piu' arrivare. Invece succede una volta: te
	# la staccano, quella voce sparisce, e al posto suo resta il
	# **riallaccio** — che costa meno ma va pagato per forza, perche'
	# finche' non lo paghi la casa sta al buio.
	for s in spese_aperte.duplicate():
		var ritardo: int = giornata - int(s["giorno"])
		if not bool(s["grave"]) or ritardo < GIORNI_PRIMA_D_O_FATTO:
			continue
		match str(s.get("tipo", "")):
			"luce":
				fatti.append("Hanno staccato 'a luce. 'A casa sta 'o scuro.")
				luce_staccata = true
				spese_aperte.erase(s)
				var r: int = maxi(30, int(round(float(s["base"]) * 0.55)))
				spese_aperte.append({
					"id": "riallaccio_%d" % giornata, "tipo": "riallaccio",
					"nome": "'O riallaccio d''a luce", "importo": r,
					"base": r, "giorno": giornata,
					"desc": "Finche' nun 'o pave, 'a casa resta scura.",
					"grave": false})
			"fitto":
				fatti.append("'O padrone 'e casa s'è pigliato 'e sorde 'e mano toia.")
				padrone_arrabbiato = true
				# Si prende quello che trova, e la pigione riparte da capo.
				var presi: int = mini(money, int(s["importo"]))
				if presi > 0:
					money -= presi
					money_changed.emit(money)
					s["importo"] = int(s["importo"]) - presi
					fatti.append("   T'ha levato €%d 'a dint''a sacca." % presi)
				if int(s["importo"]) <= 0:
					spese_aperte.erase(s)
	# Se l'umore e' a terra si prende i soldi da sola. E ha ragione lei.
	if umore_moglie < 25.0 and money > 20:
		var presi: int = mini(money, int(round(float(money) * 0.30)))
		if presi > 0:
			money -= presi
			money_changed.emit(money)
			fatti.append("Se s'è pigliata €%d 'a dint''a sacca. \"Tanto tu 'e sculezzave.\"" % presi)
	# Non hai mangiato: si comincia la giornata con meno ossa.
	if _senza_spesa():
		fatti.append("Nun s'è mangiato. Se parte cu 'e ffuorze a mmetà.")
	return fatti


func _senza_spesa() -> bool:
	for s in spese_aperte:
		if str(s.get("tipo", "")) == "spesa" and int(s["giorno"]) < giornata:
			return true
	return false


var luce_staccata: bool = false
var padrone_arrabbiato: bool = false


# ===========================================================================
# 'E CUMMISSIUNE — 'e mutive pe' ghi' 'n giro
# ===========================================================================
#
# **Il problema:** centonovanta metri per centosettantadue di Napoli, e il
# gioco ti dice attivamente di stare fermo in piazza, perche' e' li' che si
# lavora. La citta' piu' bella che abbiamo fatto era anche quella che il
# giocatore aveva meno motivo di attraversare.
#
# Le commissioni non sono "un altro modo di fare soldi": sono un motivo per
# essere **da un'altra parte**. Si prende una cosa in un punto della citta'
# e si porta in un altro, con un tempo. Quello che rendono vale piu' o meno
# quanto sei minuti di piazza — ma nei sei minuti in cui la fai vedi tre
# quartieri, ed e' quello il punto.

# **Chi t'a dà, e pecché** (0.62). Il capo: *«Migliora le quest
# secondarie aggiungendo un personaggio che si avvicina e te la affida
# realisticamente (es. un portapizze che ti affida le pizze da consegnare
# perché a lui hanno rubato il motorino), gli oggetti del caso»*. Ogni
# tipo adesso ha: chi te la dà (`chi`, `look_da`), cosa ti grida per
# chiamarti, la sua storia (tre frasi, `%s` = dove va portata), la roba
# (`robba`, vedi `robba_cummissione.gd`), chi la riceve (`a_chi`,
# `look_a`) e cosa dice. `fragile` = si rovina correndo e saltando (la
# torta): la paga scende con quello che ne resta.
const CUMM_TIPI := [
	{
		"tipo": "pizze", "robba": "pizze", "nome": "'E ppizze 'e Totore",
		"testo": "Càvere. Si arrivano fredde nun te paga nisciuno. 'A %s.",
		"paga_min": 16, "paga_max": 24, "minuti": 1.4,
		"chi": "Totore 'o pizzaiuolo",
		"look_da": {"camicia": Color(0.96, 0.96, 0.94), "pantaloni": Color(0.92, 0.92, 0.9),
			"cappello": "pizzaiuolo", "opts": {"moustache": true, "belly": 0.7}},
		"chiama": "Guagliò! Guagliò, fermate 'nu mumento, pe' carità!",
		"storia": ["M'hanno arrubbato 'o motorino mo' mo', mentre pigliavo 'e pizze!",
			"Tengo doje margherite ca s'arrefreddano: vanno 'a %s.",
			"Me le puorte tu? Te pavo io, e currenno, ca 'e pizze fredde nun 'e vo' nisciuno!"],
		"grazie": "Sî 'n angelo! Curre, curre, ca s'arrefreddano!",
		"a_chi": "'A famiglia Esposito",
		"look_a": {"camicia": Color(0.3, 0.42, 0.6), "pantaloni": Color(0.25, 0.25, 0.3)},
		"aspetta": "Uè! Sî tu cu 'e pizze? Stammo murenno 'e famma!",
		"ricevuto": "Finalmente! Ancora càvere, bravo. Tiè, e statte buono.",
		"coda": "'E pizze so' arrivate càvere.",
	},
	{
		"tipo": "spesa", "robba": "spesa", "nome": "'A spesa 'e Donna Carmela",
		"testo": "'A signora nun po' scennere. Portale 'a spesa 'a %s.",
		"paga_min": 12, "paga_max": 18, "minuti": 2.6,
		"chi": "Donna Carmela",
		"look_da": {"camicia": Color(0.32, 0.28, 0.36), "pantaloni": Color(0.26, 0.22, 0.28),
			"alta": 1.6, "opts": {"corpo": "femmina", "hair": Color(0.8, 0.8, 0.78),
			"bald": false, "moustache": false, "belly": 0.8}},
		"chiama": "Figlio mio! Scusa, figlio mio, tieni 'nu minuto?",
		"storia": ["Aggio fatto 'a spesa, ma 'e gamme nun me reggeno cchiù.",
			"È pe' mia figlia, sta 'a %s cu 'e criature e nun po' scennere.",
			"Nce 'a puorte tu? 'A Madonna t'accumpagna, e quaccosa te dongo."],
		"grazie": "Dio t'o renne, guagliò. Chiano cu 'e ova!",
		"a_chi": "'A figlia 'e Donna Carmela",
		"look_a": {"camicia": Color(0.72, 0.36, 0.42), "pantaloni": Color(0.3, 0.26, 0.3),
			"alta": 1.64, "opts": {"corpo": "femmina", "bald": false, "moustache": false}},
		"aspetta": "Uh, 'a spesa 'e mammà! Sî tu? Grazie a Dio!",
		"ricevuto": "Mammà t'ha mannato? Sî proprio 'nu bravo guaglione. Tiè.",
		"coda": "Donna Carmela te benedice.",
	},
	{
		"tipo": "pacco", "robba": "pacco", "nome": "'O pacco 'e Zi' 'Ntuono",
		"testo": "Portalo 'a %s. Nun 'o guarda' dinto.",
		"paga_min": 18, "paga_max": 28, "minuti": 2.2,
		"chi": "Zi' 'Ntuono",
		"look_da": {"camicia": Color(0.36, 0.3, 0.24), "pantaloni": Color(0.22, 0.2, 0.18),
			"opts": {"moustache": true, "bald": true, "belly": 0.6}},
		"chiama": "Tu! Sì, proprio tu. Viene ccà.",
		"storia": ["Chisto è pe' nipotemo, sta 'a %s.",
			"Io cu 'sta schiena nun ce arrivo, e 'o curriere nun se fida 'e venì ccà.",
			"Nun 'o guardà dinto e nun 'o fa' cadé. Pe' 'o resto, fatte 'e fatte tuoje."],
		"grazie": "Bravo. E ricuordate: nun l'hê maje visto.",
		"a_chi": "'O nipote 'e Zi' 'Ntuono",
		"look_a": {"camicia": Color(0.2, 0.2, 0.22), "pantaloni": Color(0.18, 0.2, 0.3),
			"opts": {"modello": "umano_q"}},
		"aspetta": "Uè. 'O pacco d''o zio? Dammillo ccà, ambresso.",
		"ricevuto": "Tutto a posto. Zi' 'Ntuono sape chi paga. Tiè.",
		"coda": "Nun hê visto niente.",
	},
	{
		"tipo": "busta", "robba": "busta", "nome": "'Na busta, e nun se dice niente",
		"testo": "Chesta va 'a %s. Nun 'a fa' vede' a nisciuno.",
		"paga_min": 26, "paga_max": 38, "minuti": 1.8,
		"chi": "'O signore cu 'e lente scure",
		"look_da": {"camicia": Color(0.12, 0.12, 0.14), "pantaloni": Color(0.1, 0.1, 0.12),
			"opts": {"modello": "omo_giacca", "hair": Color(0.1, 0.1, 0.1)}},
		"chiama": "Pssst. Guagliò. Ccà, ccà.",
		"storia": ["Tu nun m'hê maje visto, e io nun t'aggio maje parlato.",
			"Chesta busta va 'a %s. Nce sta uno ca aspetta.",
			"Si 'nu vigile te guarda, tu staje passianno. Chiaro?"],
		"grazie": "Iamme. E nun currere, ca chi corre se fa guardà.",
		"a_chi": "Chillo ca aspetta",
		"look_a": {"camicia": Color(0.3, 0.3, 0.3), "pantaloni": Color(0.15, 0.15, 0.17),
			"opts": {"modello": "omo_giacca_liscio"}},
		"aspetta": "…Sî tu? Nun fa' vede', dammella comme si niente fosse.",
		"ricevuto": "Perfetto. Tiè, e scurdate 'a faccia mia.",
		"coda": "E nun se dice niente.",
	},
	{
		"tipo": "chiave", "robba": "chiave", "nome": "'E cchiave d''o garage",
		"testo": "Chille sta aspettanno 'a n'ora. Curre 'a %s.",
		"paga_min": 15, "paga_max": 22, "minuti": 1.7,
		"chi": "Pascale d''o garage",
		"look_da": {"camicia": Color(0.22, 0.3, 0.46), "pantaloni": Color(0.22, 0.3, 0.46),
			"opts": {"modello": "umano_q", "hair": Color(0.2, 0.15, 0.1)}},
		"chiama": "Ueh! Tu ca cammini! Me faje 'nu piacere grosso?",
		"storia": ["Aggio dato 'a machina a 'nu cliente e m'aggio scurdato 'e cchiave 'e casa soja dinto!",
			"Isso sta aspettanno 'a %s, e io nun pozzo lassà 'o garage.",
			"Curre, ca chillo sta 'a 'n'ora fore â porta!"],
		"grazie": "Grazie, fratè! Curre, curre!",
		"a_chi": "'O cliente d''o garage",
		"look_a": {"camicia": Color(0.62, 0.62, 0.66), "pantaloni": Color(0.2, 0.2, 0.26),
			"opts": {"modello": "omo_camicia"}},
		"aspetta": "Finalmente! 'E cchiave meje? Stongo 'a 'n'ora ccà fora!",
		"ricevuto": "Meno male! Tiè, pe' 'o disturbo.",
		"coda": "Chillo mo' se ne trase 'a casa.",
	},
	{
		"tipo": "torta", "robba": "torta", "nome": "'A torta d''o battesimo", "fragile": true,
		"testo": "Chiano chiano: si corre o si zompa, 'a torta se sfascia. 'A %s.",
		"paga_min": 20, "paga_max": 30, "minuti": 2.6,
		"chi": "'O pasticciere Gennaro",
		"look_da": {"camicia": Color(0.96, 0.95, 0.92), "pantaloni": Color(0.3, 0.3, 0.34),
			"opts": {"moustache": true, "belly": 0.9, "bald": true}},
		"chiama": "Guagliò! Tieni 'e mmane ferme? Me serveno doje mane ferme!",
		"storia": ["'O guaglione mio ca fa 'e consegne s'è ammalato proprio oggi.",
			"Chesta torta è p''o battesimo 'a %s: è 'na torta a tre piane, delicatissima.",
			"Nun correre e nun zumpà, pe' carità: si arriva sana te pavo buono."],
		"grazie": "Chiano! Chiano, comme si purtasse 'nu criaturo!",
		"a_chi": "'A mamma d''o battezzato",
		"look_a": {"camicia": Color(0.86, 0.72, 0.8), "pantaloni": Color(0.3, 0.26, 0.32),
			"alta": 1.64, "opts": {"corpo": "femmina", "bald": false, "moustache": false}},
		"aspetta": "'A torta! 'A torta è arrivata! Fammi vedé comme sta…",
		"ricevuto": "Uh, comm'è bella! Grazie, guagliò, tiè, e viene ô rinfresco!",
		"coda": "'O battesimo è salvo.",
	},
	{
		"tipo": "sciure", "robba": "sciure", "nome": "'E sciure p''a nnammurata",
		"testo": "Portale 'e sciure 'a %s, e dille ca so' d''o nnammurato.",
		"paga_min": 12, "paga_max": 20, "minuti": 2.0,
		"chi": "Ciruzzo 'o nnammurato",
		"look_da": {"camicia": Color(0.8, 0.3, 0.3), "pantaloni": Color(0.2, 0.24, 0.36),
			"opts": {"modello": "omo_camicia_liscio", "hair": Color(0.1, 0.07, 0.05)}},
		"chiama": "Ehi, frate! Tu tiene 'a faccia 'e uno ca sape parlà cu 'e femmene!",
		"storia": ["Ll'aggio fatta arraggià, e mo' nun me risponne cchiù.",
			"Sta 'a %s. Portale 'sti sciure e dille ca Ciruzzo le vo' bene.",
			"Io nun tengo 'o curaggio 'e ce ghì. Te pavo io, parola."],
		"grazie": "Dille ca so' 'nu scemo, ma 'nu scemo ca le vo' bene!",
		"a_chi": "Carmelina",
		"look_a": {"camicia": Color(0.95, 0.8, 0.3), "pantaloni": Color(0.25, 0.28, 0.4),
			"alta": 1.63, "opts": {"corpo": "femmina", "bald": false, "moustache": false,
			"hair": Color(0.18, 0.1, 0.06)}},
		"aspetta": "E tu chi sî? Ah… 'sti sciure… so' 'e Ciruzzo?",
		"ricevuto": "Uh… so' belle. Dincello ca stasera 'o perdono. Tiè, pe' te.",
		"ricevuto_alt": "Dincello ca se po' ghì a cuccà! …Però 'e sciure m''e tengo. Tiè.",
		"coda": "L'ammore è 'na cosa complicata.",
	},
	{
		"tipo": "medicina", "robba": "medicina", "nome": "'A medicina d''o nonno",
		"testo": "'O nonno ha dda piglià 'a medicina. Currenno, 'a %s.",
		"paga_min": 14, "paga_max": 22, "minuti": 1.6,
		"chi": "'O farmacista",
		"look_da": {"camicia": Color(0.95, 0.96, 0.96), "pantaloni": Color(0.3, 0.3, 0.34),
			"cappello": "farmacista", "opts": {"hair": Color(0.6, 0.6, 0.6)}},
		"chiama": "Scusate! Giovanotto! 'Nu favore, è urgente!",
		"storia": ["Nu nonno aspetta 'sta medicina, e 'o nipote nun è venuto a pigliarla.",
			"Sta 'a %s: 'a ha dda piglià primma d''e otto, se no so' guaie.",
			"Io nun pozzo chiudere 'a farmacia. V'a sentite 'e ce ghì vuje?"],
		"grazie": "Grazie assaje. Ricurdateve: primma d''e otto!",
		"a_chi": "Nonno Vicienzo",
		"look_a": {"camicia": Color(0.42, 0.38, 0.32), "pantaloni": Color(0.28, 0.26, 0.24),
			"alta": 1.7, "opts": {"hair": Color(0.85, 0.85, 0.85), "bald": true,
			"moustache": true, "belly": 0.5}},
		"aspetta": "Uè, giuvinò… è 'a medicina mia chella?",
		"ricevuto": "Grazie, figlio mio. Tiè, pigliate 'nu cafè 'a parte mia.",
		"coda": "'O nonno sta buono.",
	},
]

## Le commissioni di oggi: [{id, tipo, nome, testo, da, a, nome_da, nome_a,
## paga, tempo, stato}] con stato = "aperta" | "in_mano" | "fatta" | "persa".
var commissioni: Array = []
var commissioni_fatte: int = 0

signal commissioni_cambiate()
signal cummissione_presa(c: Dictionary)
signal cummissione_finita(c: Dictionary, riuscita: bool)


## I posti dove nascono e finiscono. Sono punti veri sulla pianta, scelti
## uno per quartiere: cosi' una commissione e' sempre una traversata.
const CUMM_POSTI := [
	{"nome": "'a piazza", "p": Vector3(31.0, 0.0, 30.0)},
	{"nome": "'o mercato", "p": Vector3(31.0, 0.0, 111.0)},
	{"nome": "'o stadio", "p": Vector3(144.0, 0.0, 52.0)},
	{"nome": "'a cornetteria", "p": Vector3(144.0, 0.0, 111.0)},
	{"nome": "'a fontana", "p": Vector3(65.0, 0.0, 79.0)},
	{"nome": "Mergellina", "p": Vector3(95.0, 0.0, 2.5)},
	{"nome": "'o largo d''e guagliune", "p": Vector3(28.0, 0.0, 139.0)},
	{"nome": "'o Vommero", "p": Vector3(168.0, 0.0, 140.0)},
	{"nome": "Spaccanapule", "p": Vector3(96.0, 0.0, 76.0)},
]


func crea_commissioni() -> void:
	commissioni.clear()
	commissioni_fatte = 0
	# Il primo giorno una sola, e facile: si sta imparando.
	var quante: int = 1 if giornata <= 1 else randi_range(2, 3)
	var usati: Array = []
	for i in range(quante):
		var t: Dictionary = CUMM_TIPI[randi() % CUMM_TIPI.size()]
		var a_idx := randi() % CUMM_POSTI.size()
		var b_idx := randi() % CUMM_POSTI.size()
		var giri := 0
		while (b_idx == a_idx or usati.has(a_idx)) and giri < 20:
			a_idx = randi() % CUMM_POSTI.size()
			b_idx = randi() % CUMM_POSTI.size()
			giri += 1
		usati.append(a_idx)
		var da: Dictionary = CUMM_POSTI[a_idx]
		var a: Dictionary = CUMM_POSTI[b_idx]
		var dist: float = Vector3(da["p"]).distance_to(a["p"])
		# La paga sale con la distanza: una traversata da centocinquanta
		# metri non puo' valere quanto una da venti.
		var base: int = randi_range(int(t["paga_min"]), int(t["paga_max"]))
		var c := {
			"id": "c%d_%d" % [giornata, i], "tipo": str(t["tipo"]),
			"nome": str(t["nome"]),
			"testo": str(t["testo"]) % str(a["nome"]),
			"da": Vector3(da["p"]), "a": Vector3(a["p"]),
			"nome_da": str(da["nome"]), "nome_a": str(a["nome"]),
			"paga": base + int(dist * 0.12),
			"tempo": float(t["minuti"]) * 60.0 * (0.6 + dist / 190.0),
			"stato": "aperta", "integrita": 1.0,
		}
		# La faccia (0.62): chi te la dà, chi la riceve, la roba, le frasi.
		for k in ["robba", "chi", "look_da", "chiama", "storia", "grazie",
				"a_chi", "look_a", "aspetta", "ricevuto", "ricevuto_alt",
				"coda", "fragile"]:
			if t.has(k):
				c[k] = t[k]
		commissioni.append(c)
	commissioni_cambiate.emit()


func commissione(id: String) -> Dictionary:
	for c in commissioni:
		if str(c["id"]) == id:
			return c
	return {}


func prendi_commissione(id: String) -> bool:
	var c := commissione(id)
	if c.is_empty() or str(c["stato"]) != "aperta":
		return false
	c["stato"] = "in_mano"
	c["scade"] = float(c["tempo"])
	cummissione_presa.emit(c)
	commissioni_cambiate.emit()
	event_started.emit("%s — %s" % [str(c["nome"]), str(c["testo"])])
	return true


func consegna_commissione(id: String) -> int:
	var c := commissione(id)
	if c.is_empty() or str(c["stato"]) != "in_mano":
		return 0
	c["stato"] = "fatta"
	commissioni_fatte += 1
	# 'A torta sfasciata se paga pe' chello ca ne resta (mai sotto al 30%).
	var paga: int = int(round(float(c["paga"]) * clampf(float(c.get("integrita", 1.0)), 0.3, 1.0)))
	add_money(paga)
	add_reputation(2)
	SoundManager.soldi(paga)
	cummissione_finita.emit(c, true)
	commissioni_cambiate.emit()
	return paga


func _passo_commissioni(delta: float) -> void:
	for c in commissioni:
		if str(c["stato"]) != "in_mano":
			continue
		c["scade"] = float(c.get("scade", 0.0)) - delta
		if float(c["scade"]) <= 0.0:
			c["stato"] = "persa"
			cummissione_finita.emit(c, false)
			commissioni_cambiate.emit()
			event_started.emit("'A cummissione s'è fatta tarde. Niente sorde.")


## Quella che sto portando adesso, se ce n'è una.
func commissione_in_mano() -> Dictionary:
	for c in commissioni:
		if str(c["stato"]) == "in_mano":
			return c
	return {}


## **'A roba fragile** (0.62): la torta si rovina correndo, zompando,
## arrampicandosi e facendo a botte. `quanto` è la frazione persa.
func commissione_urto(quanto: float) -> void:
	var c: Dictionary = commissione_in_mano()
	if c.is_empty() or not bool(c.get("fragile", false)):
		return
	var prima: float = float(c.get("integrita", 1.0))
	c["integrita"] = clampf(prima - quanto, 0.0, 1.0)
	# Si avvisa a scatti (ogni quarto perso), non a ogni passo di corsa.
	if int(prima * 4.0) != int(float(c["integrita"]) * 4.0):
		event_started.emit("Chiano! %s se sta sfasciando (%d%%)." % [
			str(c.get("nome", "'A roba")), int(float(c["integrita"]) * 100.0)])


# ===========================================================================
# 'A BACHECA — 'e llavorielle e 'e ccase
# ===========================================================================
#
# **Perche'.** Fino alla 0.44b tutto quello che si poteva fare in citta'
# nasceva addosso a te: le auto arrivavano, le commissioni comparivano, i
# vecchi stavano seduti. Non c'era un posto dove uno *va a cercarsi* il
# lavoro. La bacheca e' quel posto — un pannello di sughero appeso in
# piazza, con sopra i foglietti — e ha due colonne:
#
#   LAVORIELLE  cose da fare oggi, che scadono stasera
#   CASE        dove porti la famiglia, che si comprano in settimane
#
# Le due colonne dicono la stessa cosa a due velocita' diverse: la prima e'
# come si campa, la seconda e' perche'. Il capo l'ha detto meglio: *"una
# casa o Vommero e' il sogno di molti napoletani"*.

## I posti dove nascono e finiscono i lavoretti. Sono gli stessi delle
## commissioni: punti veri sulla pianta, uno per quartiere.
signal lavoretti_cambiati()
signal casa_cambiata(id: String)

## **Quante vote hê guardato 'a bacheca.**
##
## Serve a una cosa sola e si vede da lontano: finché è zero, uno dei
## consigli che ti danno per strada è «hê visto 'a bacheca?» (vedi
## `Chiacchiere.CUNZIGLIE`). Appena ci metti gli occhi la prima volta, quel
## consiglio smette di uscire per sempre — perché il tutorial che ti
## ripete una cosa che hai già fatto è la ragione per cui i tutorial si
## saltano.
var commissioni_viste: int = 0

## I lavoretti appesi in bacheca oggi.
##
## [{id, tipo, nome, testo, paga, stato, ...}] con
## stato = "offerto" | "in_mano" | "fatta" | "persa".
var lavoretti: Array = []
var lavoretti_fatti: int = 0

## --- 'E PACCHE ---
##
## Porti una busta da una parte all'altra della citta' senza farti vedere
## da chi porta la divisa. Non e' una gara di velocita': e' una gara di
## strade. La paga e' alta apposta — e' l'unico modo di fare cinquanta euro
## in due minuti — e il rischio e' che se ti fermano ti trovano il pacco.
const PACCHE := [
	{"nome": "'A busta 'e Zi' 'Ntuono", "roba": "'na busta 'e carta",
		"testo": "Nun 'a apri' e nun t''a fa' vede'. Basta chesto."},
	{"nome": "'O pacchetto d''o dutture", "roba": "nu pacchetto piccerillo",
		"testo": "Pesa niente e vale assaje. Nun 'o fa' cadere."},
	{"nome": "'A scatola 'e Ciruzzo", "roba": "'na scatola 'e scarpe",
		"testo": "Dinto nun ce stanno scarpe. Cammina e nun te vutà."},
	{"nome": "'O rilorgio 'e Mimmo", "roba": "nu pacchetto cu 'a carta d'oro",
		"testo": "Chisto se cerca. Fatte 'e vvicule, no 'o Corso."},
]

## Quanto scotta un pacco addosso: sale mentre un vigile o un carabiniere
## ti vede, scende quando nun te vede nisciuno. A cento, t'hanno pigliato.
const PACCO_SALE: float = 26.0        # al secondo, mentre ti guardano
const PACCO_SCENNE: float = 11.0      # al secondo, quando sei al sicuro
const PACCO_OCCHIO: float = 16.0      # da quanto lontano ti vedono

var pacco_caldo: float = 0.0
signal pacco_caldo_cambiato(quanto: float)

## --- 'E LAVURE D''A BACHECA ---
##
## **'O furto 'e machine s'è levato ê 0.50.** C'era un lavoro che chiedeva
## una macchina di un tipo e di un colore preciso — "'na berlina nera" — e
## si completava portandola al garage. Sulla carta è il furto più logico
## che questo gioco potesse avere: non devi forzare niente, devi solo fare
## il lavoro tuo e poi non restituire le chiavi.
##
## Nella pratica non si riusciva a fare, e il capo l'ha detto chiaro: *"non
## riesco a fare le quest secondarie di rubare le auto"*. Il motivo è
## strutturale: la macchina giusta deve **arrivare da sola** in piazza
## mentre hai il lavoro in mano, e le auto arrivano una ogni venticinque
## secondi con tipo e colore a sorte su venti combinazioni. Con un lavoro
## che dura due-tre minuti, la probabilità che passi proprio quella è
## bassa; e se passa devi anche essere libero, e riuscire a guidarla fino
## al garage senza che ti vedano. Un lavoro che dipende dal caso in quel
## modo non è una sfida: è un'attesa.
##
## Al suo posto tre lavori che dipendono solo da quello che **fa** il
## giocatore, e che riusano tutti roba che nel gioco c'è già:
##
##   * **'O cafè** — una consegna a tempo strettissimo. Stessa forma del
##     pacco, ma nessuno ti cerca: qui l'unico nemico è l'orologio, perché
##     un caffè freddo non lo vuole nessuno.
##   * **'E stemme** — qualcuno vuole N stemmi. Gli stemmi si staccano
##     dalle macchine da otto versioni e finora servivano solo a essere
##     venduti a peso: adesso c'è chi te li ordina.
##   * **'A guardia** — resta fermo vicino a una cosa per un po', senza
##     farti notare. È l'unico lavoro del gioco che si vince **stando
##     fermi**, ed è per questo che vale la pena averlo: tutto il resto
##     chiede di correre.
const CAFFE := [
	{"nome": "'O cafè 'e Donna Rosa", "roba": "nu cafè cu 'a tazzulella",
		"testo": "Curre. 'O cafè freddo se jetta, e chella se ne addona."},
	{"nome": "'A sfugliatella 'e Peppino", "roba": "'na sfugliatella riccia",
		"testo": "Càvera ha da arrivà. Si s'ammoscia nun 'a vò cchiù."},
	{"nome": "'E ddoje paste d''a duméneca", "roba": "nu vassoio piccerillo",
		"testo": "Nun 'o girà e nun currere cu 'e mmane storte."},
]

const STEMME_QUANTI := [2, 3, 4]
const STEMME_CHI := ["'O Zio", "Mario 'o Sfasciacarrozze",
	"'O Cinese 'e Gianturco", "Gennaro 'o Ferraro"]

const GUARDIA := [
	{"nome": "'A guardia ô muturino", "cosa": "nu muturino appuggiato ô muro",
		"testo": "Statte llà vicino e nun te fa' nutà. Si 'o sospetto saglie, chillo s''a piglia."},
	{"nome": "'A guardia ô bancone", "cosa": "'na cascia 'e frutta",
		"testo": "Nun ce sta niente 'a fa': sta' llà e vide chi passa."},
	{"nome": "'A guardia â saracinesca", "cosa": "'na saracinesca mezza aperta",
		"testo": "Si vene quaccheduno, tu nun l'hê visto. Basta ca ce stai."},
]

## Quanto vicino devi stare, e per quanto, quando fai 'a guardia.
const GUARDIA_RAGGIO: float = 7.5
const GUARDIA_HEAT: float = 62.0


func crea_lavoretti() -> void:
	lavoretti.clear()
	lavoretti_fatti = 0
	pacco_caldo = 0.0
	# Il primo giorno la bacheca sta vuota: 'a jurnata 'e primma se 'mpara
	# a posteggiare, non si fanno consegne sospette.
	if giornata <= 1:
		lavoretti_cambiati.emit()
		return
	var quanti: int = 2 if giornata < 4 else 3
	# **Mai due volte 'o stesso foglietto.** Alla prima prova la bacheca ha
	# tirato fuori due volte "'O pacchetto d''o dutture" con due paghe
	# diverse: sembra un errore del gioco anche quando non lo e'.
	var visti: Array = []
	for i in range(quanti):
		var l: Dictionary = {}
		for tentativo in range(8):
			# Il primo foglietto è sempre un pacco: è il lavoro che insegna
			# come funziona la bacheca, ed è quello che paga meglio.
			if i == 0:
				l = _nuovo_pacco(i)
			else:
				match randi() % 4:
					0: l = _nuovo_pacco(i)
					1: l = _nuovo_caffe(i)
					2: l = _nuove_stemme(i)
					_: l = _nuova_guardia(i)
			if not visti.has(str(l["nome"])):
				break
		visti.append(str(l["nome"]))
		lavoretti.append(l)
	lavoretti_cambiati.emit()


func _nuovo_pacco(i: int) -> Dictionary:
	var p: Dictionary = PACCHE[randi() % PACCHE.size()]
	var a_idx: int = randi() % CUMM_POSTI.size()
	var b_idx: int = randi() % CUMM_POSTI.size()
	var giri: int = 0
	while b_idx == a_idx and giri < 12:
		b_idx = randi() % CUMM_POSTI.size()
		giri += 1
	var da: Dictionary = CUMM_POSTI[a_idx]
	var a: Dictionary = CUMM_POSTI[b_idx]
	var dist: float = Vector3(da["p"]).distance_to(a["p"])
	return {
		"id": "l%d_%d" % [giornata, i], "tipo": "pacco",
		"nome": str(p["nome"]), "roba": str(p["roba"]),
		"testo": str(p["testo"]),
		"da": Vector3(da["p"]), "a": Vector3(a["p"]),
		"nome_da": str(da["nome"]), "nome_a": str(a["nome"]),
		"paga": 34 + int(dist * 0.26),
		"tempo": 150.0 + dist * 1.1,
		"stato": "offerto",
	}


## Due posti a sorte, diversi fra loro. Torna (da, a).
func _due_posti() -> Array:
	var a_idx: int = randi() % CUMM_POSTI.size()
	var b_idx: int = randi() % CUMM_POSTI.size()
	var giri: int = 0
	while b_idx == a_idx and giri < 12:
		b_idx = randi() % CUMM_POSTI.size()
		giri += 1
	return [CUMM_POSTI[a_idx], CUMM_POSTI[b_idx]]


## **'O cafè.** Un pacco che non scotta e che corre.
func _nuovo_caffe(i: int) -> Dictionary:
	var c: Dictionary = CAFFE[randi() % CAFFE.size()]
	var posti: Array = _due_posti()
	var da: Dictionary = posti[0]
	var a: Dictionary = posti[1]
	var dist: float = Vector3(da["p"]).distance_to(Vector3(a["p"]))
	return {
		"id": "l%d_%d" % [giornata, i], "tipo": "caffe",
		"nome": str(c["nome"]), "roba": str(c["roba"]),
		"testo": str(c["testo"]),
		"da": Vector3(da["p"]), "a": Vector3(a["p"]),
		"nome_da": str(da["nome"]), "nome_a": str(a["nome"]),
		# Paga meno di un pacco — non è roba illegale — ma il tempo è la
		# metà: è tutto lì il lavoro.
		"paga": 18 + int(dist * 0.13),
		"tempo": 62.0 + dist * 0.52,
		"stato": "offerto",
	}


## **'E stemme.** Non c'è un posto dove ritirare: gli stemmi li stacchi tu
## dalle macchine, come sempre. C'è solo un posto dove portarli.
func _nuove_stemme(i: int) -> Dictionary:
	var quanti: int = STEMME_QUANTI[randi() % STEMME_QUANTI.size()]
	var a: Dictionary = CUMM_POSTI[randi() % CUMM_POSTI.size()]
	var chi: String = STEMME_CHI[randi() % STEMME_CHI.size()]
	return {
		"id": "l%d_%d" % [giornata, i], "tipo": "stemme",
		"nome": "%s vo' %d stemme" % [chi, quanti],
		"roba": "%d stemme 'e machina" % quanti,
		"testo": "Stàccale 'a addò vuo' tu. Quanno 'e tiene, portammelle 'a %s."
			% str(a["nome"]),
		"quanti": quanti,
		"a": Vector3(a["p"]), "nome_a": str(a["nome"]),
		"da": Vector3(a["p"]), "nome_da": str(a["nome"]),
		# Ventotto l'uno: più di quanto valgono a peso da 'O Zio, che è il
		# motivo per cui vale la pena accettare invece di venderli e basta.
		"paga": 16 * quanti,   # 0.61: era 28 (vedi gli stemmi in car_3d)
		"tempo": 300.0 + 60.0 * float(quanti),
		"stato": "offerto",
	}


## **'A guardia.** Stai vicino e non farti notare.
func _nuova_guardia(i: int) -> Dictionary:
	var g: Dictionary = GUARDIA[randi() % GUARDIA.size()]
	var a: Dictionary = CUMM_POSTI[randi() % CUMM_POSTI.size()]
	var secondi: float = float(randi_range(45, 80))
	return {
		"id": "l%d_%d" % [giornata, i], "tipo": "guardia",
		"nome": str(g["nome"]), "roba": str(g["cosa"]),
		"testo": str(g["testo"]),
		"a": Vector3(a["p"]), "nome_a": str(a["nome"]),
		"da": Vector3(a["p"]), "nome_da": str(a["nome"]),
		"secondi": secondi, "restano": secondi,
		"paga": 22 + int(secondi * 0.55),
		# Il tempo per farla è largo: la difficoltà non è arrivare, è
		# restare.
		"tempo": secondi * 3.4 + 90.0,
		"stato": "offerto",
	}


func lavoretto(id: String) -> Dictionary:
	for l in lavoretti:
		if str(l["id"]) == id:
			return l
	return {}


## Quello che sto facendo adesso, se ce n'è uno. Uno solo alla volta: due
## pacchi in mano non sono un gioco, sono una lista della spesa.
func lavoretto_in_corso() -> Dictionary:
	for l in lavoretti:
		if str(l["stato"]) == "in_mano":
			return l
	return {}


func accetta_lavoretto(id: String) -> bool:
	if not lavoretto_in_corso().is_empty():
		return false
	var l := lavoretto(id)
	if l.is_empty() or str(l["stato"]) != "offerto":
		return false
	l["stato"] = "in_mano"
	l["scade"] = float(l.get("tempo", 240.0))
	pacco_caldo = 0.0
	lavoretti_cambiati.emit()
	event_started.emit("%s — %s" % [str(l["nome"]), str(l["testo"])])
	return true


func molla_lavoretto() -> void:
	var l := lavoretto_in_corso()
	if l.is_empty():
		return
	l["stato"] = "persa"
	pacco_caldo = 0.0
	lavoretti_cambiati.emit()
	event_started.emit("Hê lassato 'o lavoro a mmiezo. Niente sorde.")


## Vero se il lavoro si può chiudere adesso: alcuni chiedono qualcosa in
## più che l'essere arrivati sul posto.
func lavoretto_pronto(l: Dictionary) -> bool:
	match str(l.get("tipo", "")):
		"stemme":
			return emblem_count() >= int(l.get("quanti", 1))
		"guardia":
			return float(l.get("restano", 1.0)) <= 0.0
	return true


## Toglie dall'inventario gli stemmi che stai consegnando. Si prendono a
## partire da quelli che valgono meno: chi ordina stemmi a numero non
## guarda la marca, e il pezzo buono conviene venderlo a parte.
func _consegna_stemme(quanti: int) -> void:
	var restano: int = quanti
	var chiavi: Array = emblems.keys()
	chiavi.sort_custom(func(a, b): return int(emblems[a]["value"]) \
		< int(emblems[b]["value"]))
	for k in chiavi:
		if restano <= 0:
			break
		var voce: Dictionary = emblems[k]
		var quanti_qui: int = mini(restano, int(voce["count"]))
		voce["count"] = int(voce["count"]) - quanti_qui
		restano -= quanti_qui
		if int(voce["count"]) <= 0:
			emblems.erase(k)
	inventory_changed.emit(emblems)


func finisci_lavoretto(id: String) -> int:
	var l := lavoretto(id)
	if l.is_empty() or str(l["stato"]) != "in_mano":
		return 0
	if not lavoretto_pronto(l):
		return 0
	if str(l.get("tipo", "")) == "stemme":
		_consegna_stemme(int(l.get("quanti", 1)))
	l["stato"] = "fatta"
	lavoretti_fatti += 1
	pacco_caldo = 0.0
	var paga: int = int(l["paga"])
	add_money(paga)
	add_reputation(3)
	SoundManager.soldi(paga)
	lavoretti_cambiati.emit()
	return paga


## Ti hanno beccato col pacco addosso: niente paga, due stelle e la busta
## se la piglia chi ti ha fermato.
func pacco_scupierto() -> void:
	var l := lavoretto_in_corso()
	if l.is_empty() or str(l["tipo"]) != "pacco":
		return
	l["stato"] = "persa"
	pacco_caldo = 0.0
	crimine(PUNTI_PER_STELLA * 2.0)
	lavoretti_cambiati.emit()
	event_started.emit("T'hanno truvato 'o pacco 'n cuollo. Mo' so' guaie.")
	SoundManager.play("fail", -4.0)


## Lo chiama l'HUD ogni fotogramma mentre porti un pacco.
func passo_pacco(delta: float, visto: bool) -> void:
	var l := lavoretto_in_corso()
	if l.is_empty() or str(l["tipo"]) != "pacco":
		if pacco_caldo != 0.0:
			pacco_caldo = 0.0
			pacco_caldo_cambiato.emit(0.0)
		return
	var prima: float = pacco_caldo
	if visto:
		pacco_caldo = minf(100.0, pacco_caldo + PACCO_SALE * delta)
	else:
		pacco_caldo = maxf(0.0, pacco_caldo - PACCO_SCENNE * delta)
	if not is_equal_approx(prima, pacco_caldo):
		pacco_caldo_cambiato.emit(pacco_caldo)
	if pacco_caldo >= 100.0:
		pacco_scupierto()


## Quanto manca alla guardia, in secondi. −1 se non ne stai facendo una.
func guardia_restano() -> float:
	var l := lavoretto_in_corso()
	if l.is_empty() or str(l.get("tipo", "")) != "guardia":
		return -1.0
	return maxf(0.0, float(l.get("restano", 0.0)))


func _passo_guardia(l: Dictionary, delta: float) -> void:
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null or not is_instance_valid(pl):
		return
	var d: float = Vector3(pl.global_position).distance_to(Vector3(l["a"]))
	if d > GUARDIA_RAGGIO:
		return
	# **'O sospetto ferma 'o cronometro.** Non lo fa fallire: lo ferma. Una
	# guardia che si perde perché è passato un vigile sarebbe una moneta
	# lanciata; una guardia che si allunga è una ragione per stare buoni.
	if heat >= GUARDIA_HEAT:
		return
	var prima: float = float(l["restano"])
	l["restano"] = maxf(0.0, prima - delta)
	if prima > 0.0 and float(l["restano"]) <= 0.0:
		event_started.emit("'A guardia è fatta. Va' a piglià 'e sorde.")
		lavoretti_cambiati.emit()


func _passo_lavoretti(delta: float) -> void:
	for l in lavoretti:
		if str(l["stato"]) != "in_mano":
			continue
		if str(l.get("tipo", "")) == "guardia":
			_passo_guardia(l, delta)
		if not l.has("scade"):
			continue
		l["scade"] = float(l["scade"]) - delta
		if float(l["scade"]) <= 0.0:
			l["stato"] = "persa"
			pacco_caldo = 0.0
			lavoretti_cambiati.emit()
			event_started.emit("'O lavoro s'è fatto tarde. Chillo nun aspetta.")


# ---------------------------------------------------------------------------
# 'E ccase
# ---------------------------------------------------------------------------
#
# Quattro gradini, e l'ultimo e' 'o Vommero. Non sono un bonus da negozio:
# ognuna cambia tre numeri veri — quanto ti svegli contento, quanto costa
# 'o fitto, e quanto la famiglia sopporta una giornata storta. Comprare
# meglio ti costa di piu' ogni settimana: e' il modo in cui una casa e' una
# responsabilita' e non un premio.

const CASE := [
	{
		"id": "vascio", "nome": "'O vascio 'e mo'", "dove": "'E Quartiere",
		"prezzo": 0, "fitto": 1.0, "umore": 0.0, "sopporta": 1.0,
		"desc": " 'Na stanza, 'a porta ncopp'â strada, 'o bagno fore. Chello ca tiene.",
	},
	{
		"id": "terraneo", "nome": "'O terraneo cu 'o curtiglio",
		"dove": "'O Centro Antico", "prezzo": 2600, "fitto": 1.35,
		"umore": 7.0, "sopporta": 1.15,
		"desc": "Nu poco cchiù luce e nu curtiglio addo' 'e criature ponno scennere. Nunzia 'o dice 'a nu anno.",
	},
	{
		"id": "appartamento", "nome": "Appartamento â Sanità",
		"dove": "'A Sanità", "prezzo": 9800, "fitto": 1.9,
		"umore": 14.0, "sopporta": 1.35,
		"desc": "Duje cammere, 'o balcone, 'o bagno dinto. 'A ggente t'accummencia a chiammà 'signò'.",
	},
	{
		"id": "vommero", "nome": "'A casa ô Vommero",
		"dove": "'O Vommero", "prezzo": 27500, "fitto": 2.8,
		"umore": 24.0, "sopporta": 1.7,
		"desc": "'O suonno. 'A funicolare sotto casa, l'aria ca se rispira, e nisciuno ca sape che ffaje 'a matina.",
	},
]

var casa_id: String = "vascio"

## **'A machina ca staje guidanno**, se ne staje guidanno una.
##
## Sta qui e non dentro al player perche' chi la deve sapere sono in tre e
## non si conoscono fra loro: l'auto (che guida), il player (che mentre
## guida non cammina e non interagisce) e l'interfaccia (che deve dire
## "[E] pe' scennere" invece del prompt normale).
var auto_guidata: Node = null


## **Quanto se sopporta 'na jurnata storta.**
##
## Ogni calo d'umore passa da qui, e la casa lo divide: dentro a un vascio
## di una stanza un rientro alle tre e' una tragedia, in un appartamento
## alla Sanita' e' una discussione. E' il terzo effetto della scala delle
## case, quello che non si vede nei numeri ma si sente giocando.
func umore_giu(quanto: float) -> void:
	var s: float = maxf(0.5, float(casa_mia().get("sopporta", 1.0)))
	umore_moglie = maxf(0.0, umore_moglie - quanto / s)


func casa_mia() -> Dictionary:
	for c in CASE:
		if str(c["id"]) == casa_id:
			return c
	return CASE[0]


## La prossima della scala, vuota se sto già in cima.
func casa_prossima() -> Dictionary:
	for i in range(CASE.size()):
		if str(CASE[i]["id"]) == casa_id and i + 1 < CASE.size():
			return CASE[i + 1]
	return {}


func puoi_accattà_casa(id: String) -> bool:
	var p := casa_prossima()
	return not p.is_empty() and str(p["id"]) == id and money >= int(p["prezzo"])


func accatta_casa(id: String) -> bool:
	if not puoi_accattà_casa(id):
		return false
	var c := casa_prossima()
	money -= int(c["prezzo"])
	money_changed.emit(money)
	casa_id = id
	# Traslocare rende contenta chiunque. È l'unico momento del gioco in cui
	# l'umore fa un salto invece di un passo.
	umore_moglie = minf(100.0, umore_moglie + 28.0)
	casa_cambiata.emit(id)
	famiglia_cambiata.emit()
	event_started.emit("Ce ne simmo juti 'a %s. Nunzia chiagne, ma d''e ccontente." % str(c["nome"]))
	SoundManager.play("kaching", -2.0)
	return true


# ===========================================================================
# 'A SCOPA — 'o turneo d''e viecchie
# ===========================================================================
#
# Cinque vecchi, uno piu' forte dell'altro, e per arrivare all'ultimo devi
# aver battuto tutti quelli prima. Non e' un albero delle abilita': e' una
# scala di gente, e ognuno ha un modo suo di fregarti.
#
# La difficolta' non e' un numero che sale: **e' un'idea in piu' per ognuno**.
# Il primo cala a caso. Il secondo prende sempre la presa piu' grossa. Il
# terzo guarda anche cosa ti lascia in mano. Il quarto conta le carte
# uscite. E il Nonno bara — ma si vede, e se lo becchi paga.

const SFIDANTI := [
	{
		"id": "ciccio", "nome": "Ciccio 'o Guappo", "eta": 68,
		"livello": 0, "puntata": 5, "premio": 0,
		"dice": "Assettate, guagliò. Ma tanto perde tu.",
		"vinto": "Uh Maronna. Vabbuo', t''e mierete.",
	},
	{
		"id": "professore", "nome": "'O Professore", "eta": 74,
		"livello": 1, "puntata": 10, "premio": 0,
		"dice": "'A scopa è matematica, giuvinò. E tu 'a matematica nun 'a saje.",
		"vinto": "Interessante. Statisticamente nun se puteva.",
	},
	{
		"id": "zipeppe", "nome": "Zi' Peppe", "eta": 79,
		"livello": 2, "puntata": 15, "premio": 0,
		"dice": "I' ce joco 'a sissant'anne. Tu 'a quanto?",
		"vinto": "E mo' me tocca pavà. Che jurnata.",
	},
	{
		"id": "nicola", "nome": "Nicola 'e ll'Uocchie", "eta": 85,
		"livello": 3, "puntata": 25, "premio": 0,
		"dice": "I' 'e ccarte ll'aggio contate primma ca tu 'e ppigliave.",
		"vinto": "Aggio sbagliato 'e cconte. 'A primma vota 'a trent'anne.",
	},
	{
		"id": "nonno", "nome": "Don Gennaro 'o Viecchio", "eta": 91,
		"livello": 4, "puntata": 40, "premio": 150,
		"dice": "Assettate. E tiene ll'uocchie apierte, ca i' so' viecchio ma nun so' fesso.",
		"vinto": "…Bravo. Piglia 'o mazzo mio. Mo' 'e ccarte so' 'e ttoie.",
	},
]

## Chi ho gia' battuto, in ordine.
var scopa_battuti: Array = []
var scopa_vinte_oggi: int = 0
var scopa_perse_oggi: int = 0
## Il mazzo del Nonno: si vince battendo tutti e cinque. Fa vedere una
## carta dell'avversario a ogni mano. Non e' barare: e' che adesso il mazzo
## e' tuo.
var mazzo_del_nonno: bool = false

signal scopa_cambiata()


func sfidante(id: String) -> Dictionary:
	for s in SFIDANTI:
		if str(s["id"]) == id:
			return s
	return {}


## Il prossimo che si puo' sfidare. Gli altri stanno seduti ma non giocano
## con te: "Primma ha 'a vencere a chillo llà."
func prossimo_sfidante() -> String:
	for s in SFIDANTI:
		if not scopa_battuti.has(str(s["id"])):
			return str(s["id"])
	return ""


func scopa_sbloccato(id: String) -> bool:
	return prossimo_sfidante() == id or scopa_battuti.has(id)


func scopa_esito(id: String, vinto: bool, puntata: int) -> void:
	if vinto:
		scopa_vinte_oggi += 1
		add_money(puntata * 2)
		gioco_azzardo(puntata)
		if not scopa_battuti.has(id):
			scopa_battuti.append(id)
			var s := sfidante(id)
			var premio: int = int(s.get("premio", 0))
			if premio > 0:
				add_money(premio)
			add_reputation(6)
			if prossimo_sfidante() == "":
				mazzo_del_nonno = true
				event_started.emit("'O mazzo 'e Don Gennaro è 'o tuoio. Nisciuno cchiù te po' fa' fesso.")
	else:
		scopa_perse_oggi += 1
		gioco_azzardo(-puntata)
	scopa_cambiata.emit()


# ---------------------------------------------------------------------------
# 'O LOTTO
# ---------------------------------------------------------------------------
#
# **'A giocata 'e oggi se vede dimane.**
#
# Il capo ha chiesto il lotto *"in modo completo come nella realtà, con
# estrazioni giornaliere"*, e la parte che fa la differenza è proprio
# quella: **non si vince subito.** Le slot e le tre carte danno il
# risultato in tre secondi; il lotto no. Giochi il pomeriggio, e la sera,
# quando la giornata si chiude, l'estrazione ti dice come è andata.
#
# Che è poi il motivo per cui il lotto ha fregato Napoli per tre secoli:
# fra la giocata e l'estrazione ci sono ore di speranza, e la speranza si
# ricompra il giorno dopo.
#
# Le regole vere stanno in `lotto.gd` (ruote, smorfia, quote); qui ci sta
# solo quello che riguarda la giornata di questo giocatore.
const Lotto := preload("res://scripts/lotto.gd")

signal lotto_cagnato()

## Le giocate aperte, in attesa dell'estrazione di stasera.
var lotto_giocate: Array = []
## L'ultima estrazione: {"giornata": n, "numeri": {ruota: [5 nummere]}}.
var lotto_ultima: Dictionary = {}
## Com'è andata l'ultima volta, riga per riga, da mostrare al tabaccaio.
var lotto_esiti: Array = []
## Quanto hai messo e quanto hai preso, da quando giochi. È il numero che
## nessun giocatore vero tiene, ed è per questo che si continua a giocare.
var lotto_giocato_tutto: int = 0
var lotto_vinto_tutto: int = 0

var _lotto_rng := RandomNumberGenerator.new()

# ---------------------------------------------------------------------------
# 'O quadernetto d''e ritardatarie
# ---------------------------------------------------------------------------
#
# **'A cosa cchiù napulitana ca se pò mettere ncopp'ô banco d''o tabaccaro.**
#
# Un giocatore vero non gioca i numeri a caso: gioca **quelli che non
# escono da un pezzo**, e tiene il conto. Il ritardo di un numero su una
# ruota è quante estrazioni sono passate dall'ultima volta che è uscito, e
# nei bar di Napoli sta scritto a mano su un foglio appeso.
#
# Che sia una **fallacia** — la ruota non ha memoria, un numero in ritardo
# di ottanta ha esattamente la stessa probabilità di uno uscito ieri — è
# tutto il punto, e il gioco non lo corregge: qui il quadernetto non
# cambia nemmeno di un millesimo la probabilità. Serve a dare al giocatore
# quello che i giocatori veri si danno da soli, cioè **una ragione per
# scegliere questo numero invece di quell'altro**. Con novanta numeri
# uguali uno tira a caso e la giocata non è una decisione.
#
# Il conto sta per ruota, e si tiene con un solo intero per numero:
# `ritardi[ruota][n-1]` = da quante estrazioni manca. A ogni estrazione
# tutti salgono di uno e i cinque usciti tornano a zero.

## ruota -> Array[int] di 90 ritardi.
var lotto_ritardi: Dictionary = {}


func _prepara_ritardi() -> void:
	if not lotto_ritardi.is_empty():
		return
	for r in Lotto.RUOTE:
		var v: Array = []
		v.resize(Lotto.NUMERI)
		v.fill(0)
		lotto_ritardi[r] = v


## I numeri più in ritardo su una ruota, dal più assente in giù.
func lotto_ritardatarie(ruota: String, quante: int = 6) -> Array:
	_prepara_ritardi()
	if not lotto_ritardi.has(ruota):
		return []
	var v: Array = lotto_ritardi[ruota]
	var righe: Array = []
	for i in range(v.size()):
		righe.append({"n": i + 1, "ritardo": int(v[i])})
	righe.sort_custom(func(a, b): return int(a["ritardo"]) > int(b["ritardo"]))
	return righe.slice(0, quante)


func _passo_ritardi(numeri: Dictionary) -> void:
	_prepara_ritardi()
	for r in lotto_ritardi:
		var v: Array = lotto_ritardi[r]
		for i in range(v.size()):
			v[i] = int(v[i]) + 1
		for n in numeri.get(r, []):
			var k: int = int(n) - 1
			if k >= 0 and k < v.size():
				v[k] = 0


## Registra una giocata. Torna un dizionario con `ok` e il perché di no.
func gioca_lotto(ruota: String, numeri: Array, puntata: int) -> Dictionary:
	if not Lotto.RUOTE.has(ruota):
		return {"ok": false, "pecche": "'A rota nun esiste."}
	var puliti: Array = []
	for n in numeri:
		var v: int = int(n)
		if v < 1 or v > Lotto.NUMERI or puliti.has(v):
			continue
		puliti.append(v)
	puliti.sort()
	if puliti.is_empty():
		return {"ok": false, "pecche": "Nun hê scigliuto nisciun nummero."}
	if puliti.size() > 5:
		return {"ok": false, "pecche": "Cchiù 'e cinche nummere nun se ponno."}
	var p: int = clampi(puntata, Lotto.PUNTATA_MIN, Lotto.PUNTATA_MAX)
	if money < p:
		return {"ok": false, "pecche": "Nun tiene manco 'a puntata."}
	money -= p
	money_changed.emit(money)
	lotto_giocato_tutto += p
	lotto_giocate.append({
		"ruota": ruota, "numeri": puliti, "puntata": p, "giornata": giornata,
	})
	lotto_cagnato.emit()
	return {"ok": true, "sorte": Lotto.sorte(puliti.size()),
		"quanto": int(round(float(p) * Lotto.QUOTE[puliti.size()]))}


## Quanto pagherebbe, se uscissero tutti.
func lotto_sogno(numeri: Array, puntata: int) -> int:
	var q: int = numeri.size()
	if q < 1 or q > 5:
		return 0
	return int(round(float(puntata) * Lotto.QUOTE[q]))


## **L'estrazione d''a sera.** La chiama `end_shift()`: si estraggono le
## ruote, si pagano le giocate aperte, e gli esiti restano da leggere
## (nel riepilogo e al banco del tabaccaio).
# ---------------------------------------------------------------------------
# 'E nummere 'e stasera se sanno 'a stammatina
# ---------------------------------------------------------------------------
#
# **Pe' ffà 'na prufezia, 'o futuro adda essere già scritto.**
#
# Fino alla 0.54 l'estrazione si tirava a sorte **la sera**, dentro a
# `end_shift`. Funzionava benissimo e rendeva impossibile la sola cosa che
# il capo ha chiesto per la 0.55: una che ti dice i numeri giusti. Se i
# numeri non esistono ancora quando lei parla, non c'è modo di farla
# indovinare davvero — si potrebbe solo barare al contrario, cioè
# *decidere dopo* che aveva ragione, e sarebbe una finzione che il
# giocatore non può verificare.
#
# Adesso i numeri di stasera **si tirano la mattina** (`prepara_giornata`)
# e restano chiusi in `lotto_stasera`. La sera non si tira più niente: si
# apre la busta. Il giocatore non ha modo di leggerli — tranne quando 'a
# Signora glieli dice.
#
# E stanno nel salvataggio, se no bastava ricaricare per rifare l'estrazione.

## ruota -> Array[int] già tirati per stasera.
var lotto_stasera: Dictionary = {}


func _prepara_estrazione() -> void:
	_lotto_rng.randomize()
	lotto_stasera = Lotto.estrai(_lotto_rng)


func estrai_lotto() -> Dictionary:
	if lotto_stasera.is_empty():
		_prepara_estrazione()
	var numeri: Dictionary = lotto_stasera.duplicate(true)
	lotto_stasera = {}
	lotto_ultima = {"giornata": giornata, "numeri": numeri}
	_passo_ritardi(numeri)
	lotto_esiti = []
	var preso: int = 0
	for g in lotto_giocate:
		var usciti: Array = numeri.get(str(g["ruota"]), [])
		var v: int = Lotto.vincita(g["numeri"], int(g["puntata"]), usciti)
		preso += v
		lotto_esiti.append({
			"ruota": str(g["ruota"]), "numeri": g["numeri"],
			"puntata": int(g["puntata"]), "vinto": v, "usciti": usciti,
		})
	lotto_giocate = []
	if preso > 0:
		money += preso
		lotto_vinto_tutto += preso
		money_changed.emit(money)
	lotto_cagnato.emit()
	return {"vinto": preso, "quante": lotto_esiti.size()}


## Le giocate ancora aperte, per il pannello e per il riepilogo.
func lotto_quante_aperte() -> int:
	return lotto_giocate.size()


# ---------------------------------------------------------------------------
# 'A Signora
# ---------------------------------------------------------------------------
#
# **Una ncopp'a vinte tene ragione, e chella vota se cagna 'a vita.**
#
# Il capo, sui vicini della 0.54: *"le informazioni che ti danno le persone
# sono superflue"*. Aveva ragione, ed è una diagnosi più profonda di quanto
# sembri. Sapere dove sta il vigile è **utile** ma non è **memorabile**:
# cambia i trenta secondi dopo e poi è finita, e dopo tre giorni non ci
# fai più caso — è una riga di HUD con una faccia davanti.
#
# 'A Signora è il contrario esatto. Quasi sempre non serve a niente: ti dà
# cinque numeri, li giochi, non esce niente, e va bene così. Ma **una volta
# su venti** sono i numeri veri dell'estrazione di stasera, e allora un
# euro sulla cinquina fa sei milioni. Non è un'informazione: è una
# **lotteria dentro la lotteria**, e quello che ti lascia addosso non è il
# vantaggio, è il dubbio — *stavolta ci sarà?*
#
# Il numero venti è scelto: più raro e diventa una leggenda che non capita
# mai (e un giocatore non crede a quello che non ha visto); più frequente
# e il lotto smette di essere un azzardo. Una su venti vuol dire che in una
# partita da trenta giornate **succede una o due volte**, ed è esattamente
# quanto basta perché te lo ricordi.
#
# Le altre diciannove volte i numeri sono a caso — ma pescati con la stessa
# faccia, con lo stesso tono e con la stessa ruota: **non si deve poter
# capire** quale volta è quella giusta. Se si capisse, le altre diciannove
# sarebbero rumore invece che attesa.

## Una su quante volte i numeri sono davvero quelli di stasera.
const SIGNORA_NDUVINA: int = 20

## Dove può capitare di incontrarla, e come si chiama quel posto (è quello
## che ti dice Mimmo). Posti di passaggio, mai dentro alla tua piazza: se
## stesse sempre sotto casa non ci sarebbe niente da cercare.
const SIGNORA_POSTI := [
	{"nome": "sotto ê Tribunale, ncopp'a Spaccanapule", "p": Vector3(96.0, 0.0, 76.0)},
	{"nome": "â funtanella d''a piazzetta", "p": Vector3(67.5, 0.0, 79.5)},
	{"nome": "ô largo d''e guagliune", "p": Vector3(29.0, 0.0, 142.0)},
	{"nome": "fore ô mercato, addò se vennono 'e panne", "p": Vector3(60.0, 0.0, 108.0)},
	{"nome": "ncopp'â Marina, verso 'o mare", "p": Vector3(88.0, 0.0, 88.0)},
	{"nome": "sotto ô stadio, addò stanno 'e bancarelle", "p": Vector3(128.0, 0.0, 70.0)},
	{"nome": "dint'ô vico appriesso â cornetteria", "p": Vector3(146.0, 0.0, 104.0)},
]

## Quale posto oggi. −1 = oggi nun se vede proprio.
var signora_posto: int = -1
## Già parlato oggi: i numeri li dà una volta sola.
var signora_data: bool = false
## Quello che ti ha detto oggi: {"ruota": ..., "numeri": [...]}.
var signora_detto: Dictionary = {}

## Quante giornate su quante non esce affatto. Se stesse tutti i giorni
## diventerebbe un distributore; se uscisse una volta a settimana non la
## troveresti mai.
const SIGNORA_NUN_ESCE: float = 0.25


func _scegli_a_signora() -> void:
	signora_data = false
	signora_detto = {}
	if randf() < SIGNORA_NUN_ESCE:
		signora_posto = -1
		return
	signora_posto = randi() % SIGNORA_POSTI.size()


## Dove sta oggi, per Mimmo e per chi la costruisce. Vuoto = oggi niente.
func signora_dove() -> Dictionary:
	if signora_posto < 0 or signora_posto >= SIGNORA_POSTI.size():
		return {}
	return SIGNORA_POSTI[signora_posto]


## I numeri che ti dà. Una volta su venti sono quelli veri di stasera.
##
## Torna sempre la stessa cosa se lo richiami nella stessa giornata: i
## numeri che ti ha detto te li ha detti, e non cambiano se riapri il
## dialogo.
func signora_numeri() -> Dictionary:
	if not signora_detto.is_empty():
		return signora_detto
	if lotto_stasera.is_empty():
		_prepara_estrazione()
	var ruote: Array = lotto_stasera.keys()
	if ruote.is_empty():
		return {}
	var ruota: String = str(ruote[randi() % ruote.size()])
	var giuste: bool = randi() % SIGNORA_NDUVINA == 0
	var numeri: Array = []
	if giuste:
		numeri = Array(lotto_stasera[ruota]).duplicate()
	else:
		# **E nun se mettono 'n ordine.**
		#
		# Qui c'era `numeri.sort()`, e sembrava una gentilezza: cinque
		# numeri in fila si leggono meglio. Era invece il buco che si
		# mangiava tutta la meccanica — **l'estrazione vera esce
		# disordinata** (i numeri escono uno alla volta dall'urna, non in
		# fila), quindi ordinati voleva dire *finti* e disordinati voleva
		# dire *veri*. Un giocatore ci mette tre giornate a notarlo e da
		# lì in poi sa sempre, prima di spendere un euro, se è la volta
		# buona: e le altre diciannove volte smettono di essere attesa.
		#
		# L'ha trovato `prova_signora` al primo giro, su quattromila
		# tirate. A occhio non si vedeva: i numeri *sembravano* uguali.
		while numeri.size() < Lotto.ESTRATTI:
			var n: int = randi_range(1, Lotto.NUMERI)
			if not numeri.has(n):
				numeri.append(n)
	signora_detto = {"ruota": ruota, "numeri": numeri, "giuste": giuste}
	signora_data = true
	return signora_detto


func lotto_messo_aperto() -> int:
	var t: int = 0
	for g in lotto_giocate:
		t += int(g["puntata"])
	return t


const SLOT_MAX: int = 4
const SLOT_PATH := "user://partita_%d.json"

## Quale slot si sta usando in questo momento (-1 = partita non salvata).
var slot_corrente: int = -1
## Quante giornate ha già fatto questo personaggio. Serve a distinguere gli
## slot fra loro: "€340 · 2 piazze · giorno 5" dice più di una data.
var giornata: int = 1

signal partita_caricata()


## Tutto quello che sopravvive alla fine di una giornata. Quello che vale
## solo per il turno in corso (sospetto, ossa, cronometro, stelle) NON sta
## qui: si ricomincia sempre la mattina.
func stato_partita() -> Dictionary:
	return {
		"v": SAVE_VER,
		"quando": int(Time.get_unix_time_from_system()),
		"giornata": giornata,
		"money": money,
		"reputation": reputation,
		"emblems": emblems,
		"upgrades": upgrades,
		"strada_unlocked": strada_unlocked,
		"cigarettes": cigarettes,
		"caffe": caffe,
		"tutorial_seen": tutorial_seen,
		"armi": armi,
		"arma_in_mano": arma_in_mano,
		"zone_mie": zone_mie,
		"affitti": affitti,
		"dipendenti": dipendenti,
		"placed_decor": placed_decor,
		"decor_copie": decor_copie,
		"manifesti": manifesti,
		"qualita": qualita_salvata,
		"clients_served": clients_served,
		"fines_paid": fines_paid,
		"goals": goals,
		# --- 'A famiglia -------------------------------------------------
		"umore_moglie": umore_moglie,
		"spese_aperte": spese_aperte,
		"sere_tardi": sere_tardi,
		"luce_staccata": luce_staccata,
		"padrone_arrabbiato": padrone_arrabbiato,
		# --- 'A scopa ----------------------------------------------------
		"scopa_battuti": scopa_battuti,
		"casa_id": casa_id,
		"lavoretti_fatti": lavoretti_fatti,
		"mazzo_del_nonno": mazzo_del_nonno,
		"nomma": nomma,
		# --- 'O lotto ----------------------------------------------------
		"lotto_giocate": lotto_giocate,
		"lotto_ultima": lotto_ultima,
		"lotto_giocato_tutto": lotto_giocato_tutto,
		"lotto_vinto_tutto": lotto_vinto_tutto,
		"tipo_giornata": tipo_giornata,
		"lotto_ritardi": lotto_ritardi,
		# 'E nummere 'e stasera: senza 'e chisto, ricaricà rifà ll'estrazione
		# e 'a prufezia d''a Signora nun vale cchiù niente.
		"lotto_stasera": lotto_stasera,
		"boss_da_fa": boss_da_fa,
		"boss_fatte": boss_fatte,
		"boss_parte_juorne": boss_parte_juorne,
		"borrelli_ultimo_juorno": borrelli_ultimo_juorno,
		"borrelli_chiamate": borrelli_chiamate,
		"sveglia_n_galera": sveglia_n_galera,
		"signora_posto": signora_posto,
		"signora_data": signora_data,
		"signora_detto": signora_detto,
		# --- 'A gente d''a piazza ----------------------------------------
		"rapporti": rapporti,
	}


## Rimette in piedi una partita letta da file. Volutamente tollerante: una
## chiave che manca (perché il file è di una versione più vecchia, o perché
## una meccanica è nata dopo) lascia il valore di partenza invece di far
## saltare tutto il caricamento.
func applica_stato(d: Dictionary) -> void:
	giornata = int(d.get("giornata", 1))
	money = int(d.get("money", 0))
	reputation = int(d.get("reputation", 0))
	emblems = d.get("emblems", {}).duplicate(true)
	upgrades = d.get("upgrades", {}).duplicate(true)
	strada_unlocked = bool(d.get("strada_unlocked", false))
	cigarettes = int(d.get("cigarettes", 0))
	caffe = int(d.get("caffe", 0))
	tutorial_seen = bool(d.get("tutorial_seen", false))
	armi = d.get("armi", {}).duplicate(true)
	arma_in_mano = str(d.get("arma_in_mano", ""))
	zone_mie = d.get("zone_mie", ["piazza"]).duplicate()
	affitti = d.get("affitti", {}).duplicate(true)
	dipendenti = d.get("dipendenti", {}).duplicate(true)
	placed_decor = d.get("placed_decor", []).duplicate(true)
	decor_copie = d.get("decor_copie", {}).duplicate(true)
	manifesti = d.get("manifesti", []).duplicate()
	qualita_salvata = int(d.get("qualita", -1))
	clients_served = int(d.get("clients_served", 0))
	fines_paid = int(d.get("fines_paid", 0))
	goals = int(d.get("goals", 0))
	umore_moglie = float(d.get("umore_moglie", 62.0))
	# Le spese vengono da JSON: i Vector3 non ci stanno, ma i numeri sì, e
	# quello che serve è che `giorno` resti un intero.
	spese_aperte = []
	for s in d.get("spese_aperte", []):
		if typeof(s) != TYPE_DICTIONARY:
			continue
		spese_aperte.append({
			"id": str(s.get("id", "")), "tipo": str(s.get("tipo", "")),
			"nome": str(s.get("nome", "'Na spesa")),
			"importo": int(s.get("importo", 0)),
			"giorno": int(s.get("giorno", 1)),
			"desc": str(s.get("desc", "")),
			"grave": bool(s.get("grave", false)),
		})
	sere_tardi = int(d.get("sere_tardi", 0))
	luce_staccata = bool(d.get("luce_staccata", false))
	padrone_arrabbiato = bool(d.get("padrone_arrabbiato", false))
	casa_id = str(d.get("casa_id", "vascio"))
	lavoretti_fatti = int(d.get("lavoretti_fatti", 0))
	nomma = clampf(float(d.get("nomma", 0.0)), 0.0, 100.0)
	nomma_cambiata.emit(nomma)
	scopa_battuti = []
	for x in d.get("scopa_battuti", []):
		scopa_battuti.append(str(x))
	mazzo_del_nonno = bool(d.get("mazzo_del_nonno", false))
	# 'O lotto: 'e giocate aperte se portano appriesso 'o salvataggio, se no
	# uno salva 'a matina, ricarica, e 'a schedina se ne va.
	lotto_giocate = []
	for g in d.get("lotto_giocate", []):
		if typeof(g) == TYPE_DICTIONARY:
			lotto_giocate.append(g)
	lotto_ultima = d.get("lotto_ultima", {})
	lotto_stasera = {}
	for r in d.get("lotto_stasera", {}):
		var v: Array = []
		for x in d["lotto_stasera"][r]:
			v.append(int(x))
		if v.size() == Lotto.ESTRATTI:
			lotto_stasera[str(r)] = v
	boss_parte_juorne = int(d.get("boss_parte_juorne", 0))
	borrelli_ultimo_juorno = int(d.get("borrelli_ultimo_juorno", 0))
	borrelli_chiamate = int(d.get("borrelli_chiamate", 0))
	sveglia_n_galera = bool(d.get("sveglia_n_galera", false))
	boss_da_fa = []
	for z in d.get("boss_da_fa", []):
		boss_da_fa.append(str(z))
	boss_fatte = []
	for z in d.get("boss_fatte", []):
		boss_fatte.append(str(z))
	signora_posto = int(d.get("signora_posto", -1))
	signora_data = bool(d.get("signora_data", false))
	# **'O JSON nun sape ca so' nummere interi.** Tornano `43.0` invece
	# di `43`, e 'a Signora se mette a dicere "quarantatré virgola zero".
	# Peggio: 'o cunfronto cu ll'estrazione nun torna cchiù, e 'a vota
	# bbona diventa 'na vota sbagliata.
	signora_detto = {}
	var sd = d.get("signora_detto", {})
	if typeof(sd) == TYPE_DICTIONARY and sd.has("numeri"):
		var nn: Array = []
		for x in sd["numeri"]:
			nn.append(int(x))
		signora_detto = {
			"ruota": str(sd.get("ruota", "")),
			"numeri": nn,
			"giuste": bool(sd.get("giuste", false)),
		}
	# 'E ritardi: 'o JSON 'e torna cu 'a virgola, e ccà ce vònno interi.
	lotto_ritardi = {}
	for r in d.get("lotto_ritardi", {}):
		var riga: Array = []
		for x in d["lotto_ritardi"][r]:
			riga.append(int(x))
		if riga.size() == Lotto.NUMERI:
			lotto_ritardi[str(r)] = riga
	_prepara_ritardi()
	tipo_giornata = str(d.get("tipo_giornata", "normale"))
	# 'E rapporte: 'o JSON torna tutto comme a numere 'e virgola mobile, e
	# `visto` adda restà 'nu numero sano.
	rapporti = {}
	_clienti_fore.clear()
	for k in d.get("rapporti", {}):
		var v = d["rapporti"][k]
		if typeof(v) != TYPE_DICTIONARY:
			continue
		rapporti[str(k)] = {
			"visto": int(v.get("visto", 0)),
			"rap": clampf(float(v.get("rap", 0.0)), -100.0, 100.0),
		}
	lotto_giocato_tutto = int(d.get("lotto_giocato_tutto", 0))
	lotto_vinto_tutto = int(d.get("lotto_vinto_tutto", 0))
	lotto_esiti = []
	lotto_cagnato.emit()
	save_version = int(d.get("v", SAVE_VER))


func salva_su_slot(n: int) -> bool:
	if n < 0 or n >= SLOT_MAX:
		return false
	var f := FileAccess.open(SLOT_PATH % n, FileAccess.WRITE)
	if f == null:
		push_warning("Nun se po' scrivere 'o slot %d" % n)
		return false
	f.store_string(JSON.stringify(stato_partita(), "\t"))
	f.close()
	slot_corrente = n
	return true


## Legge il file di uno slot. `{}` se non c'è o se è illeggibile.
func leggi_slot(n: int) -> Dictionary:
	if n < 0 or n >= SLOT_MAX:
		return {}
	var percorso: String = SLOT_PATH % n
	if not FileAccess.file_exists(percorso):
		return {}
	var f := FileAccess.open(percorso, FileAccess.READ)
	if f == null:
		return {}
	var testo := f.get_as_text()
	f.close()
	var d = JSON.parse_string(testo)
	if typeof(d) != TYPE_DICTIONARY:
		return {}
	return d


## La riga che il menu scrive accanto al numero dello slot.
func descrizione_slot(n: int) -> String:
	var d := leggi_slot(n)
	if d.is_empty():
		return "— vuoto —"
	var zone: int = int(d.get("zone_mie", []).size())
	var quando: String = ""
	var t: int = int(d.get("quando", 0))
	if t > 0:
		var dt := Time.get_datetime_dict_from_unix_time(t)
		quando = "  ·  %02d/%02d %02d:%02d" % [
			int(dt["day"]), int(dt["month"]), int(dt["hour"]), int(dt["minute"])]
	return "€%d  ·  %d piazz%s  ·  juorno %d%s" % [
		int(d.get("money", 0)), zone, ("a" if zone == 1 else "e"),
		int(d.get("giornata", 1)), quando]


func slot_pieno(n: int) -> bool:
	return not leggi_slot(n).is_empty()


func cancella_slot(n: int) -> bool:
	if n < 0 or n >= SLOT_MAX:
		return false
	var percorso: String = SLOT_PATH % n
	if not FileAccess.file_exists(percorso):
		return false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(percorso))
	if slot_corrente == n:
		slot_corrente = -1
	return true


## Carica lo slot dentro al GameManager. NON ricarica la scena: quello lo
## fa chi ha chiesto il caricamento (l'HUD o il menu iniziale), perché è
## l'unico che sa se siamo in partita o davanti alla schermata iniziale.
func carica_da_slot(n: int) -> bool:
	var d := leggi_slot(n)
	if d.is_empty():
		return false
	applica_stato(d)
	slot_corrente = n
	partita_caricata.emit()
	return true


# --- Salvataggio automatico (spento) ---

func save_game() -> void:
	var data := {
		"v": SAVE_VER,
		"money": money,
		"reputation": reputation,
		"emblems": emblems,
		"upgrades": upgrades,
		"strada_unlocked": strada_unlocked,
		"cigarettes": cigarettes,
		"tutorial_seen": tutorial_seen,
		"armi": armi,
		"arma_in_mano": arma_in_mano,
		"zone_mie": zone_mie,
		"affitti": affitti,
		"placed_decor": placed_decor,
		"decor_copie": decor_copie,
		"qualita": qualita_salvata,
		"caffe": caffe,
		"manifesti": manifesti,
	}
	# Non si scrive piu' su disco: vedi il commento in `_ready`. La
	# funzione resta perche' la chiamano in una dozzina di posti, e perche'
	# `data` documenta cosa sarebbe da salvare se un domani si rimettesse
	# un salvataggio vero (con degli slot, non uno automatico).
	if data.is_empty():
		return


## Non carica piu' niente: si comincia sempre da zero (vedi `_ready`).
func load_game() -> void:
	# Non si carica piu' niente: ogni avvio e' una giornata nuova (vedi
	# `_ready`). Il corpo vecchio — settanta righe che leggevano il JSON —
	# stava ancora qui sotto, irraggiungibile: codice morto che al primo
	# che ci mette mano sembra vivo. Via.
	return

## **La violenza fa stelle solo se qualcuno la vede — o se esageri.**
##
## Prima ogni pugno aggiungeva punti di crimine, sempre, anche in fondo a
## un vicolo senza nessuno: il gioco si comportava come se ci fosse una
## telecamera sopra la città. È l'esatto contrario di come dovrebbe
## funzionare uno che fa il parcheggiatore abusivo.
##
## Adesso ci sono due strade, e sono quelle vere:
##
##   1. **ti vedono.** Un pugno sotto gli occhi di un vigile è una stella
##      subito, senza sconti. Uno in un vicolo deserto non lo sa nessuno.
##   2. **esageri.** Anche senza testimoni, tre pestaggi in un minuto in
##      un quartiere dove tutti si conoscono qualcuno lo racconta: alla
##      terza scatta la stella, e da lì in poi ogni due botte ne arriva
##      un'altra.
const VIOLENZE_FINESTRA: float = 60.0
const VIOLENZE_PER_STELLA: int = 3
const VIOLENZE_DOPO: int = 2

var _violenze: Array = []
var _violenze_contate: int = 0


func violenza(peso: float = 1.0) -> void:
	if not shift_active or arrested or hospitalized:
		return
	var ora: float = Time.get_ticks_msec() / 1000.0
	_violenze.append(ora)
	# Si tiene solo quello che sta dentro alla finestra.
	var vive: Array = []
	for t in _violenze:
		if ora - float(t) <= VIOLENZE_FINESTRA:
			vive.append(t)
	_violenze = vive
	if _violenze.size() <= 1:
		_violenze_contate = 0

	if _qualcuno_ti_vede():
		crimine(PUNTI_PER_STELLA * peso)
		# (Fino alla 0.62 qui c'era 'a seconda porta 'e Borrelli: dalla 0.63
		# la violenza vista chiama solo i carabinieri.)
		event_started.emit("T'hanno visto. 'E carabinieri stanno venenno.")
		return

	# Nessuno ha visto: conta solo se ne stai facendo troppe di fila.
	var soglia: int = VIOLENZE_PER_STELLA + _violenze_contate * VIOLENZE_DOPO
	if _violenze.size() >= soglia:
		_violenze_contate += 1
		crimine(PUNTI_PER_STELLA)
		event_started.emit("Se n'è parlato 'n giro. Mo' te cercano.")


## Chi puo' testimoniare: i vigili col cono visivo addosso, e i carabinieri
## che ti stanno gia' guardando.
func _qualcuno_ti_vede() -> bool:
	for v in get_tree().get_nodes_in_group("vigili"):
		if v.has_method("can_see_player") and v.can_see_player():
			return true
	return _visto_dalla_legge


## **La freccia rossa.** Chi ti sta colpendo (o afferrando) lo dice qui, e
## l'HUD disegna la direzione: senza, una botta alle spalle e' solo lo
## schermo che diventa rosso e non si capisce da dove scappare.
signal minaccia(posizione: Vector3)


func segnala_minaccia(posizione: Vector3) -> void:
	minaccia.emit(posizione)


# ---------------------------------------------------------------------------
# Chi te 'o vede fà (0.61)
# ---------------------------------------------------------------------------
#
# Era nella roadmap dalla 0.57: *«rubare davanti a venti persone deve
# costare più che in un vicolo vuoto; adesso il prezzo lo fa solo il
# vigile»*. Adesso contano pure gli altri: chi passa, gli autisti, le
# signore, i vicini, i guagliuni col pallone. Un furto in un vicolo vuoto
# costa **meno** di prima (sei decimi), uno in mezzo alla folla fino al
# doppio. È una scelta che si fa guardandosi intorno, ed è quello che fa
# un ladro vero.

const TESTIMONE_RAGGIO: float = 14.0
const GRUPPI_TESTIMONI := ["passanti", "drivers", "signore", "vicine",
	"bambini", "operai"]


## Quanta gente ti vede in quel punto.
func testimoni(p: Vector3) -> int:
	var n := 0
	var albero := get_tree()
	if albero == null:
		return 0
	for g in GRUPPI_TESTIMONI:
		for c in albero.get_nodes_in_group(g):
			if c is Node3D and (c as Node3D).is_visible_in_tree() \
					and (c as Node3D).global_position.distance_to(p) < TESTIMONE_RAGGIO:
				n += 1
	return n


## Il moltiplicatore del prezzo di un furto. 0 testimoni: 0,6. Sette o più:
## il doppio.
func peso_testimoni(n: int) -> float:
	return clampf(0.6 + 0.2 * float(n), 0.6, 2.0)


## Lo dice a schermo, così la regola si impara giocando.
func di_testimoni(n: int) -> void:
	if n >= 5:
		event_started.emit("T'hanno visto in %d. Mo' 'o sape tutto 'o quartiere." % n)
	elif n >= 2:
		event_started.emit("T'hanno visto in %d." % n)
	elif n == 0:
		event_started.emit("Nisciuno t'ha visto.")


func crimine(peso: float) -> void:
	if not shift_active or arrested or hospitalized:
		return
	if upgrades.get("gilet", false):
		peso *= 0.75 # col gilet sembri uno che ha il diritto di stare li'
	_crimine = clampf(_crimine + peso, 0.0,
		float(STELLE_MAX) * PUNTI_PER_STELLA)
	_fuori_vista = 0.0
	_aggiorna_stelle()


## Lo dicono i carabinieri, una volta per frame: "in questo momento ti sto
## vedendo". Finche' e' vero le stelle non scendono.
func segnala_vista(vista: bool) -> void:
	_visto_dalla_legge = vista


func _aggiorna_stelle() -> void:
	var n: int = clampi(int(ceil(_crimine / PUNTI_PER_STELLA)), 0, STELLE_MAX)
	if n != stelle:
		stelle = n
		stelle_cambiate.emit(stelle)


func _passo_stelle(delta: float) -> void:
	if _crimine <= 0.0:
		return
	if _visto_dalla_legge:
		_fuori_vista = 0.0
		return
	_fuori_vista += delta
	if _fuori_vista < STELLE_ATTESA:
		return
	_crimine = maxf(0.0, _crimine - STELLE_CALO * delta)
	_aggiorna_stelle()


## Toglie un po' di calore alla caccia senza azzerarla. Lo chiama il segno
## della croce davanti all'edicola votiva: non ti toglie i carabinieri di
## dosso, ma un po' di strada verso la stella in meno la fa.
func calma_le_stelle(quanto: float) -> void:
	if _crimine <= 0.0:
		return
	_crimine = maxf(0.0, _crimine - quanto)
	_aggiorna_stelle()


## Azzera la caccia: lo chiama la fine del turno e l'arresto.
func azzera_stelle() -> void:
	_crimine = 0.0
	_visto_dalla_legge = false
	_aggiorna_stelle()


func register_punch() -> void:
	punches_thrown += 1


func apply_fine(amount: int) -> void:
	money = max(0, money - amount)
	fines_paid += 1
	heat = 0.0
	money_changed.emit(money)
	heat_changed.emit(heat)


## ARRESTATO: il vigile ti ha preso. Paghi la cauzione (una fetta del
## portafoglio) e il turno finisce lì, con tanto di disonore nel riepilogo.
## Una botta presa: dal motorino, da un'auto, dai pugni di un autista
## incazzato o del vigile. A zero ossa si finisce in ospedale.
func damage_player(amount: float, cause: String = "",
		da: Vector3 = Vector3.INF) -> void:
	if not shift_active or hospitalized or arrested or amount <= 0.0:
		return
	# Chi le piglia cu 'a torta 'n mano, 'a torta 'a sfascia (0.62).
	commissione_urto(0.18)
	# Chi mena dice anche DA DOVE: l'HUD ci disegna la freccia. Una botta
	# alle spalle, senza, e' solo lo schermo che diventa rosso — e non si
	# capisce da che parte scappare.
	if da.x < INF:
		segnala_minaccia(da)
	var prima: float = health
	health = maxf(0.0, health - amount)
	_no_damage_time = 0.0
	health_changed.emit(health)
	player_hurt.emit(amount, cause)
	# **'O fiatone.** Sotto al trenta per cento si comincia a sentire il
	# respiro. E' l'unico modo che ha un gioco in prima persona di far
	# capire che stai messo male senza scriverlo a schermo: la barra la
	# guardi se ci pensi, il respiro lo senti e basta.
	if prima > HEALTH_MAX * 0.30 and health <= HEALTH_MAX * 0.30 \
			and health > 0.0:
		SoundManager.play("fiatone", -6.0)
	if health <= 0.0:
		hospitalize(cause)


## Una tirata di sigaretta rimette in sesto: non è medicina, ma nel
## quartiere funziona così.
func heal_player(amount: float) -> void:
	if health >= HEALTH_MAX:
		return
	health = minf(HEALTH_MAX, health + amount)
	health_changed.emit(health)


## OSPEDALE: turno finito, e pure pagando. Il conto del pronto soccorso si
## porta via una fetta di quello che avevi in tasca.
func hospitalize(cause: String = "") -> void:
	if hospitalized or arrested:
		return
	hospitalized = true
	hospital_bill = maxi(8, int(money * 0.25))
	money = max(0, money - hospital_bill)
	health = 0.0
	heat = 0.0
	money_changed.emit(money)
	heat_changed.emit(heat)
	health_changed.emit(health)
	event_started.emit("OSPEDALE! " + (cause if cause != "" else "T'hanno pigliato"))
	rientro_forzato("ospedale")


## Un vigile ha messo una multa su un'auto che hai piazzato abusivamente.
func register_multa() -> void:
	multe_prese += 1


## Il verbale strappato prima che l'autista lo vedesse: nel riepilogo di
## fine turno quella multa non c'e' mai stata.
func annulla_multa() -> void:
	multe_prese = maxi(0, multe_prese - 1)


## Borrelli convinto: il turno finisce subito, e finisce BENE. È l'unico
## modo di chiudere un turno vincendo invece che per scadenza del tempo.
## Chiamato da Borrelli appena entra in scena: da qui in poi il tempo non
## scorre più, comanda lui.
func start_boss_phase() -> void:
	boss_phase = true
	shift_time_changed.emit(shift_time_left)


func defeat_boss() -> void:
	if boss_defeated or not shift_active:
		return
	boss_defeated = true
	boss_phase = false
	# Il premio: la piazza è tua per stasera.
	add_money(BOSS_REWARD)
	add_reputation(3)
	end_shift()


func register_boss_wrong_answer() -> void:
	boss_wrong_answers += 1


func register_pickpocket() -> void:
	pickpockets += 1


# ---------------------------------------------------------------------------
# 'A roba d''o Bazar: quante ne tieni, e addo' stanno
# ---------------------------------------------------------------------------
#
# **Prima ogni decorazione era un interruttore.** `upgrades["sedia"] = true`,
# e basta: una sedia, piazzata da sola in un angolo deciso dal codice, e se
# la volevi spostare la spostavi — non ne potevi avere due. Chi voleva un
# salotto con tre sedie e due ombrelloni non poteva.
#
# E dove la piazzavi non era dove finiva: il punto arrivava in coordinate
# **del mondo** e veniva scritto come posizione **locale** dentro alla
# piazza, che sta a (14, 0, 6). Ogni oggetto atterrava quattordici metri a
# levante e sei a mezzogiorno di dove avevi cliccato.
#
# Adesso:
#   - `decor_copie[id]` dice quante ne hai comprate;
#   - `placed_decor` e' una LISTA di istanze, ognuna con la sua posizione,
#     e lo stesso id ci puo' stare quante volte vuoi;
#   - comprarne una la mette nello zaino, non in piazza: la piazzi tu.

## Quante copie di ogni decorazione possiedi. id -> numero.
var decor_copie: Dictionary = {}


func decor_possedute(id: String) -> int:
	return int(decor_copie.get(id, 0))


func decor_piazzate(id: String) -> int:
	var n := 0
	for e in placed_decor:
		if e.get("id", "") == id:
			n += 1
	return n


## Quante ne hai ancora da appoggiare.
func decor_libere(id: String) -> int:
	return maxi(0, decor_possedute(id) - decor_piazzate(id))


## Il giocatore appoggia una copia dove vuole lui. Ne appende sempre una
## nuova: spostare e' un'altra cosa, e si fa con `sposta_decor`.
func place_decor(id: String, pos: Vector3, rot: float) -> void:
	if decor_libere(id) <= 0:
		return
	placed_decor.append({"id": id, "pos": [pos.x, pos.y, pos.z], "rot": rot})
	decor_placed.emit(placed_decor.size() - 1, id, pos, rot)


## Toglie dalla piazza la copia numero `indice` e la rimette nello zaino.
func togli_decor(indice: int) -> String:
	if indice < 0 or indice >= placed_decor.size():
		return ""
	var id: String = str(placed_decor[indice].get("id", ""))
	placed_decor.remove_at(indice)
	decor_rimosso.emit(indice, id)
	return id


func decor_istanza(indice: int) -> Dictionary:
	if indice < 0 or indice >= placed_decor.size():
		return {}
	return placed_decor[indice]


func is_decor_placed(id: String) -> bool:
	return decor_piazzate(id) > 0


# ---------------------------------------------------------------------------
# Cosa fa, davvero, la roba comprata al Bazar
# ---------------------------------------------------------------------------
#
# Qui non si costruisce niente: la zona costruisce i mobili e poi registra
# **il nodo** di quelli che contano per posizione. Si tiene il nodo e non
# le coordinate perché una decorazione si può spostare (`place_decor`) e in
# quel caso la zona la ricostruisce altrove: col nodo la posizione è sempre
# quella vera, senza doverla aggiornare da due parti.

## id -> lista di nodi. Una lista e non un nodo solo perche' adesso di
## ombrelloni se ne possono avere tre, e devono valere tutti e tre.
var _decoro_nodi: Dictionary = {}


func registra_decoro(id: String, nodo: Node3D) -> void:
	if not _decoro_nodi.has(id):
		_decoro_nodi[id] = []
	_decoro_nodi[id].append(nodo)


## La zona rifa' il salotto da capo: si butta via l'elenco vecchio, se no
## resta pieno di nodi liberati.
func svuota_decoro() -> void:
	_decoro_nodi.clear()


## I nodi vivi di quel tipo.
func decoro_nodi(id: String) -> Array:
	var vivi: Array = []
	for n in _decoro_nodi.get(id, []):
		if n != null and is_instance_valid(n) and n is Node3D:
			vivi.append(n)
	return vivi


## Il primo che c'e', per chi ne vuole uno solo.
func decoro_nodo(id: String) -> Node3D:
	var v := decoro_nodi(id)
	return v[0] if not v.is_empty() else null


## Il pezzo di quel tipo piu' vicino al punto, e quanto dista. `null` se
## non ce n'e' nessuno.
func decoro_vicino(id: String, punto: Vector3) -> Node3D:
	var meglio: Node3D = null
	var d_min := INF
	for n in decoro_nodi(id):
		var d: Vector3 = (n as Node3D).global_position - punto
		d.y = 0.0
		if d.length() < d_min:
			d_min = d.length()
			meglio = n
	return meglio


## Il player e' a portata di uno QUALUNQUE dei pezzi di quel tipo? Serve
## all'ombrellone (che nasconde) e ai due mobili che si usano.
func vicino_a_decoro(id: String, punto: Vector3, raggio: float) -> bool:
	for n in decoro_nodi(id):
		var d: Vector3 = (n as Node3D).global_position - punto
		d.y = 0.0
		if d.length() <= raggio:
			return true
	return false


# ---------------------------------------------------------------------------
# 'A radiolina
# ---------------------------------------------------------------------------
#
# La radio era l'unica decorazione con un effetto che non si SENTE: teneva
# buoni i clienti, e basta. Una radio che non fa musica e' un soprammobile.
#
# Adesso si accende con [E] e scorre i brani che il gioco ha gia' — quelli
# che la regia musicale mette da sola secondo l'ora e la situazione. Accesa,
# comanda lei; spenta, torna a comandare la regia. Le due emergenze
# (l'inseguimento e il boss) restano fuori dal suo controllo: quando ti
# stanno addosso, la musica deve dirtelo, e non e' il momento di scegliere.

## I brani che la radiolina passa, nell'ordine in cui li scorre.
##
## Dalla 0.50 i pezzi veri sono tre e i sette generati a 8 bit sono passati
## in seconda fila: sulla manopola restano perché la radiolina è l'unico
## posto del gioco dove si sceglie la musica, e buttarli via toglieva scelte
## senza aggiungere niente.
const RADIO_TRACCE := ["giorno", "notte", "caccia", "tarantella", "menu",
	"8bit_giorno", "8bit_lavoro", "8bit_sera"]
const RADIO_NOMI := {
	"giorno": "'O vico",
	"notte": "'A notte",
	"caccia": "Terracotta",
	"tarantella": "'A tarantella",
	"menu": "'O tema",
	"8bit_giorno": "Miezojuorno (8 bit)",
	"8bit_lavoro": "'A fatica (8 bit)",
	"8bit_sera": "'A sera (8 bit)",
}

## Che brano sta passando la radio. Vuoto = spenta.
var radio_traccia: String = ""

signal radio_cambiata(traccia: String)


## Un giro di manopola: spenta → primo brano → … → ultimo → spenta.
func radio_avanti() -> String:
	var i: int = RADIO_TRACCE.find(radio_traccia)
	if i < 0:
		radio_traccia = str(RADIO_TRACCE[0])
	elif i >= RADIO_TRACCE.size() - 1:
		radio_traccia = ""
	else:
		radio_traccia = str(RADIO_TRACCE[i + 1])
	radio_cambiata.emit(radio_traccia)
	return radio_traccia


func radio_nome() -> String:
	if radio_traccia == "":
		return "spenta"
	return str(RADIO_NOMI.get(radio_traccia, radio_traccia))


## Sei all'ombra? Lo chiede il vigile prima di dire che ti vede.
func sotto_ombrellone(punto: Vector3) -> bool:
	return vicino_a_decoro("ombrellone", punto, OMBRA_RAGGIO)


## Quanti TIPI diversi di decoro stanno in piazza. Conta i tipi e non le
## copie: il "decoro" della piazza e' varieta', e dieci ombrelloni in fila
## non la rendono piu' curata di uno.
func decoro_quanti() -> int:
	var n := 0
	for id in DECOR_IDS:
		if decor_piazzate(id) > 0:
			n += 1
	return n


## Moltiplicatore dell'attesa fra un'auto e l'altra nella piazza tua.
## Sempre <= 1: piu' curata e' la piazza, meno si aspetta. Le luminarie
## contano solo col buio, ed e' li' che valgono i sessanta euro.
func attesa_auto() -> float:
	var m: float = 1.0 - DECORO_ARRIVI * float(decoro_quanti())
	if decor_piazzate("luminarie") > 0 and e_notte():
		m *= LUMINARIE_ARRIVI
	return maxf(0.4, m)


## Quanto piu' a lungo aspetta un cliente nella piazza tua: la radio gli
## tiene compagnia e non se ne va.
func pazienza_cliente() -> float:
	return 1.45 if decor_piazzate("radio") > 0 else 1.0


# ---------------------------------------------------------------------------
# OGNE COSA CA S'ACCATTA HA DA RENNE
# ---------------------------------------------------------------------------
#
# **'O guaio** (0.56, punto 10 d''o capo): *«La maggior parte degli oggetti
# acquistabili ed equipaggiabili deve servire ad ottenere più soldi,
# altrimenti non servono poi a molto a livello di gameplay. Ri bilancia
# anche l'economia in base a questo.»*
#
# Faccio il conto di com'era. Dodici oggetti in vendita, e si dividevano in
# due mucchi:
#
#   * **sette rennevano**: coppola, piante, luminarie, radio, fischietto,
#     paletta, tavolino. Chi li comprava vedeva la giornata salire.
#   * **cinque nun rennevano niente**: gilet, occhiali, borsello, sedia,
#     ombrellone. Servivano a **non perdere** — meno sospetto, meno
#     sequestri, un posto dove non ti vedono.
#
# E il secondo mucchio era il problema, ma non per la ragione che sembra.
# Non è che non servissero: il borsello che ti salva mezza giornata a un
# fermo è l'oggetto più utile del gioco. È che **non si sentivano**. Il
# danno che non hai preso non si vede da nessuna parte — non c'è un numero
# che sale, non c'è una moneta che tintinna — e dopo tre giornate il
# giocatore non sa dire se quei trenta euro di gilet abbiano fatto
# qualcosa. Una cosa che non si vede, nel dubbio, non si ricompra.
#
# Quindi non gli ho tolto il mestiere: gli ho **aggiunto una faccia
# visibile**, e ognuna è quella che quell'oggetto avrebbe in strada.
#
#   gilet      sembri uno che ha il diritto di stare lì → ti pagano di più
#   occhiali   non ti si legge in faccia → la mancia non si contratta
#   borsello   gli spiccioli non si perdono per terra
#   ombrellone **«t''o metto a ll'ombra»** — l'auto parcheggiata sotto
#              l'ombra vale di più, ed è la frase che si sente davvero
#   sedia      chi ti vede seduto come un custode ti lascia 'o spicciariello
#
# Restano tutti oggetti di sicurezza, e la sicurezza resta il grosso di
# quello che pagano. Ma adesso ogni cosa che compri, comprandola, si vede.

## Quanto pesa ogni pezzo sulla probabilità che l'autista paghi.
const GILET_PAGA: float = 0.06
## Moltiplicatori di mancia dei pezzi che prima non rendevano niente.
const OCCHIALI_MANCIA: float = 1.08
const BORSELLO_MANCIA: float = 1.06
const OMBRELLONE_MANCIA: float = 1.14

## **'O spicciariello d''a sedia.**
##
## Mentre stai seduto come un custode qualunque, ogni tanto passa uno e ti
## lascia una monetina. Deve essere **meno di quanto rendi lavorando**, se
## no la mossa migliore del gioco diventa sedersi e aspettare — e un gioco
## dove conviene non giocare è rotto, per quanto sia comodo.
##
## Il conto: una giornata buona fa sessantotto euro in sedici minuti, cioè
## quattro euro e venticinque al minuto. Tre centesimi e mezzo al secondo
## sono due euro e dieci al minuto: **la metà esatta**. Ti ripaga la sedia
## in cinque giornate (se ci passi due minuti buoni per volta, che è quanto
## ci vuole a far passare il vigile) e non ti ci fa campare.
const SEDIA_SPICCIO: float = 0.035


## Punti percentuali in piu' sulla probabilita' che l'autista paghi, per una
## piazza che sembra tenuta bene.
func bonus_pagamento() -> float:
	return 0.07 if decor_piazzate("piante") > 0 else 0.0


## **Chello ca te puorte 'ncuollo**, e che quindi vale dappertutto.
##
## È la differenza che conta e che teneva separati i due mucchi: le piante e
## le luminarie stanno **in un posto**, e fuori da quel posto non esistono;
## il gilet e gli occhiali te li porti addosso, e valgono in tutte e quattro
## le piazze. Tenerli nella stessa funzione avrebbe voluto dire che il gilet
## funzionava solo sotto casa — cioè un gilet che ti togli attraversando la
## strada.
func bonus_arnese() -> float:
	# Il gilet catarifrangente: due euro di plastica gialla che in strada
	# valgono quanto un tesserino. Chi scende dalla macchina non guarda se
	# sei autorizzato, guarda se **sembri** autorizzato.
	return GILET_PAGA if upgrades.get("gilet", false) else 0.0


## Lo stesso, ma sulla mancia.
func mancia_arnese() -> float:
	var m: float = 1.0
	# Gli occhiali: non è che ci vedi meglio, è che non ti si vede. Uno che
	# non sa dove stai guardando non contratta, ti dà i due euro e se ne va.
	if upgrades.get("occhiali", false):
		m *= OCCHIALI_MANCIA
	# Il borsello: gli spiccioli stanno dentro, non sciolti in tasca. Non
	# se ne perde nessuno per terra, e non se ne "dimentica" nessuno.
	if upgrades.get("borsello", false):
		m *= BORSELLO_MANCIA
	return m


## Moltiplicatore della mancia nella piazza tua.
func bonus_mancia() -> float:
	var m: float = 1.0
	if decor_piazzate("piante") > 0:
		m *= 1.12
	if decor_piazzate("luminarie") > 0 and e_notte():
		m *= LUMINARIE_MANCIA
	# **«T''o metto a ll'ombra.»** È la frase più vera del mestiere, ed è
	# sempre stata nel gioco come un nascondiglio per te: adesso è anche
	# quello che è in strada, cioè un servizio che si fa pagare.
	if decor_piazzate("ombrellone") > 0:
		m *= OMBRELLONE_MANCIA
	# E poi c'e' l'ora, che pesa piu' di tutto il resto: alle tre del
	# pomeriggio si lascia il resto, alle due di notte si lascia il doppio.
	# E sopra all'ora c'e' il giorno: i due numeri si moltiplicano, e una
	# nottata del primo del mese vale piu' del doppio di una controra
	# qualunque.
	return m * mancia_fascia() * mancia_giornata()


## E' calata la notte? Lo sa il ciclo giorno/notte, che vive dentro la
## scena; qui si tiene solo il riferimento, cercato una volta sola.
var _ciclo: Node = null


func e_notte() -> bool:
	if _ciclo == null or not is_instance_valid(_ciclo):
		var albero := get_tree()
		if albero == null or albero.get_root() == null:
			return false
		_ciclo = albero.get_root().find_child("GiornoNotte", true, false)
	if _ciclo == null:
		return false
	return bool(_ciclo.get("e_notte"))


## **'O borsello.** Gli spiccioli stanno chiusi, non sciolti in tasca: chi
## ti perquisisce — il vigile che sequestra, i carabinieri che ti mettono la
## cauzione — quei soldi lì non li trova. Sedici euro che si ripagano al
## primo fermo, ed è l'unico oggetto che ti protegge da una cosa che nel
## gioco succede spesso e fa male: perdere in un colpo mezza giornata.
func soldi_visibili() -> int:
	if not upgrades.get("borsello", false):
		return money
	return maxi(0, money - BORSELLO_SICURO)


# ---------------------------------------------------------------------------
# 'A collezione
# ---------------------------------------------------------------------------

func manifesto_preso(id: String) -> bool:
	return manifesti.has(id)


func manifesti_presi() -> int:
	return manifesti.size()


## I dati di un manifesto, per id. Vuoto se non esiste.
func manifesto_dati(id: String) -> Dictionary:
	for m in MANIFESTI:
		if m["id"] == id:
			return m
	return {}


## Quelli che mancano ancora, con l'indizio. Serve al taccuino.
func manifesti_mancanti() -> Array:
	var fuori: Array = []
	for m in MANIFESTI:
		if not manifesti.has(m["id"]):
			fuori.append(m)
	return fuori


## Scatta la foto. Ritorna false se era già presa o l'id non esiste: chi
## chiama non deve stare a controllare due volte.
func fotografa_manifesto(id: String) -> bool:
	var dati := manifesto_dati(id)
	if dati.is_empty() or manifesti.has(id):
		return false
	manifesti.append(id)
	add_money(MANIFESTO_PREMIO)
	add_reputation(1)
	manifesto_fotografato.emit(id, str(dati["titolo"]),
		manifesti.size(), MANIFESTI.size())
	if manifesti.size() >= MANIFESTI.size():
		add_money(COLLEZIONE_PREMIO)
		add_reputation(6)
		collezione_completa.emit()
	save_game()
	return true


## **Quanti gol se pavano 'a jurnata** (0.56).
##
## Col pallone rifatto — tocco morbido, mira che aiuta, linea di porta che
## non perde più i tiri forti — segnare è diventato facile: **trentanove
## tiri su quaranta dal dischetto**, misurati. E quattro euro a gol, con il
## pallone che dopo ogni gol torna da solo sul dischetto, fanno più di cento
## euro al minuto: cioè più di quanto renda una giornata intera di lavoro.
##
## Aggiustare il pallone per farlo tornare difficile sarebbe stato togliere
## con una mano quello che il capo ha chiesto con l'altra. La cosa giusta è
## un'altra, ed è come funziona qualunque scommessa in questo gioco: **'o
## banco chiude**. I primi quattro gol della giornata te li pagano, dopo
## quelli i guaglioni ti dicono bravo e basta. Resta un easter egg che
## rende (sedici euro, una mancia buona), non un bancomat.
const GOL_PAVATE_Ô_JUORNO: int = 4
var gol_pavate: int = 0


## Gol nella porta del vicoletto: pochi soldi, ma la piazza ti applaude.
## Torna quanto ha pagato — zero quando il banco ha già chiuso.
func register_goal() -> int:
	goals += 1
	add_reputation(1)
	SoundManager.play("urlo", -6.0)
	goal_scored.emit(goals)
	if gol_pavate >= GOL_PAVATE_Ô_JUORNO:
		return 0
	gol_pavate += 1
	add_money(GOAL_REWARD)
	return GOAL_REWARD


# ---------------------------------------------------------------------------
# 'E TRE FERMI
# ---------------------------------------------------------------------------
#
# **'A terza vota nun te sciuoglie cchiù.**
#
# La colluttazione a tasto (`player_fps._presa_t`) era una prova d'abilità
# che si vinceva sempre: sette colpi in due secondi e mezzo li fa
# chiunque, e siccome si poteva rifare all'infinito i carabinieri
# smettevano di far paura dopo la prima volta. Uno imparava che farsi
# prendere non costa niente, e da lì in poi le stelle erano decorazione.
#
# Adesso i fermi si contano. Il primo e il secondo si scampano — e al
# secondo il gioco ti avvisa, perché una punizione che arriva senza
# preavviso è una fregatura. **Al terzo non c'è colluttazione**: ti
# ammanettano e basta, e la nottata la passi dentro.
#
# Il conto si azzera la mattina, quando comincia il turno nuovo: sono tre
# fermi **in una giornata**, non tre in una partita.
const FERMI_PRIMMA_D_A_CELLA: int = 3

## Quanti fermi hai già preso oggi.
var fermi_oggi: int = 0
## L'ultimo arresto è stato quello secco, con la notte dentro?
var notte_ncella: bool = false


## La chiama il player quando gli mettono le mani addosso. Torna `true` se
## da questa presa ci si può ancora sciogliere.
func registra_fermo() -> bool:
	fermi_oggi += 1
	if fermi_oggi >= FERMI_PRIMMA_D_A_CELLA:
		return false
	if fermi_oggi == FERMI_PRIMMA_D_A_CELLA - 1:
		# L'avviso. Serve a rendere il terzo fermo una scelta ("mo' me ne
		# vaco 'a casa") invece di una sorpresa.
		event_started.emit("Sciògliete: 'a prossima vota te portano dinto.")
	return true


func fermi_ancora() -> int:
	return maxi(0, FERMI_PRIMMA_D_A_CELLA - fermi_oggi)


## **'A nuttata dint'â cella.** Non è l'arresto normale: quello ti lascia
## sotto casa e la serata te la giochi lo stesso — parli con Nunzia, fai
## il conto, ti metti a letto quando vuoi. Questo no: la giornata si
## chiude **da sola**, senza il giro di casa, e il giorno dopo ti svegli
## nel vascio. È la differenza fra pagare una cauzione e perdere una sera.
func arresto_secco() -> void:
	if arrested or hospitalized:
		return
	# **E pure 'o terzo fermo mo' fernisce 'n galera** (0.56). Prima
	# chiudeva la giornata da solo, seduta stante: adesso passa dalla
	# stessa porta di tutti gli arresti, così la cella si vede una volta
	# sola e il conto si fa in un posto solo.
	vai_n_galera("Tre fermi. 'A nuttata t''a passe dinto.")


# ---------------------------------------------------------------------------
# 'A galera
# ---------------------------------------------------------------------------
#
# **T'arrestano e nun te purtano cchiù 'a casa: te portano dinto.**
#
# Il capo: *"aggiungi una prigione in cui vieni portato e ti tolgono tutti
# i soldi quando ti arrestano. In prigione resti tipo 5 secondi skippabili
# e poi ti ritrovi fuori la prigione la mattina dopo."*
#
# Fino alla 0.55 i carabinieri ti lasciavano **sotto casa tua**, con una
# cauzione che ti pigliava metà di quello che avevi addosso, e l'orologio
# si fermava. Tre cose sbagliate in una:
#
#   * non si vedeva niente — l'arresto era un banner e un numero;
#   * costava poco, perché il borsello ti nascondeva una parte;
#   * e il tempo fermo rompeva tutto il resto (vedi `rientro_forzato`).
#
# Adesso la galera è un posto, ci finisci davvero, e **ti pigliano tutto**
# — borsello compreso, che in questura lo aprono. Cinque secondi di cella
# (skippabili, perché una punizione non dev'essere anche una noia), e poi
# la giornata è finita: ti risvegli domani mattina fuori dal portone.
#
# Il costo vero non è la cauzione: è **la serata**. Ti arrestano alle nove
# e le tre ore buone non le fai più, e stasera il conto di casa lo devi
# pagare lo stesso.

## Dove sta 'a galera. Fore 'a città, verso levante — e ce se torna a
## pede, ca è meta' d''a punizione.
##
## **'A galera s'è trasferita** (0.60). Stava a (178, 0, 163) e il blocco si
## costruiva nove metri dietro: sopra a due isolati, attraverso una strada,
## il cardine d''o Vommero e il vicolo di levante. Adesso **è un isolato**:
## quello in cima al Vomero, [133, 156, 155, 168], l'angolo di sud-est del
## terrapieno. Il portone guarda a nord, sulla trasversale z 152-156, che
## sta sulla collina: per questo la quota è tre metri. Chi esce si fa la
## scalinata e tutta la città a piedi (169 m in linea d'aria dalla piazza).
const GALERA_FORE := Vector3(144.0, 3.0, 156.0)
## Da che parte guarda il portone: chi esce se lo trova alle spalle.
const GALERA_VERSO := Vector3(0.0, 0.0, -1.0)
## Quanto dura 'a scena d''a cella, si nun 'a scanze.
const GALERA_SECUNNE: float = 5.0

signal purtato_n_galera(quanto_hanno_pigliato: int)

var ncella: bool = false
## Vero si stanotte ll'hê passata dinto: dimane matina te scite fore ô
## purtone d''a galera, no dint'â piazza toia. Passa p''o salvataggio
## pecché 'a jurnata nova se ricarica 'a scena.
var sveglia_n_galera: bool = false


## T'arrestano: 'a galera, 'e sorde, e 'a jurnata fernuta.
func vai_n_galera(pecche: String) -> void:
	if arrested or hospitalized:
		return
	arrested = true
	ncella = true
	azzera_stelle()
	# **Tutto, no 'na parte.** `soldi_visibili()` toglie quello che sta nel
	# borsello, ed è giusto quando ti perquisiscono per strada. In
	# questura il borsello te lo fanno togliere: qui si conta `money`.
	bail_paid = money
	money = 0
	fines_paid += 1
	heat = 0.0
	money_changed.emit(money)
	heat_changed.emit(heat)
	event_started.emit(pecche)
	purtato_n_galera.emit(bail_paid)


## **Chi tene 'a chiave d''a cella.**
##
## I cinque secondi li conta anche l'HUD, che disegna il pannello e lascia
## saltare la scena con un tasto. Ma **il conto vero sta qua**, e non è un
## doppione: se la porta la aprisse solo il pannello, basterebbe che l'HUD
## non ci fosse — una prova headless, una partita caricata storta, un
## pannello che non si costruisce — e il giocatore resterebbe in cella **per
## sempre**, con la giornata che non finisce e il gioco piantato.
##
## La regola: chi chiude una porta deve possedere anche il modo di
## riaprirla. Il pannello è il modo di vederla e di saltarla; questo è il
## modo di uscirne comunque.
var _cella_t: float = 0.0


func _passo_cella(delta: float) -> void:
	if not ncella:
		_cella_t = 0.0
		return
	_cella_t += delta
	# Un filo più dei cinque secondi del pannello: se l'HUD c'è, apre lui.
	if _cella_t > GALERA_SECUNNE + 1.5:
		esce_d_a_galera()


## 'A cella è fernuta (5 secondi o 'nu tasto): se chiude 'a jurnata.
func esce_d_a_galera() -> void:
	if not ncella:
		return
	ncella = false
	if ora_ritiro < 0.0:
		ora_ritiro = ore_passate()
	# La nottata in cella conta come rientro tardissimo: a casa non sanno
	# nemmeno dove stai.
	ora_ritiro = maxf(ora_ritiro, ORE_DI_GIORNATA)
	umore_moglie = maxf(0.0, umore_moglie - 10.0)
	sere_tardi += 1
	notte_ncella = true
	sveglia_n_galera = true
	end_shift()


## Arrestato dalla pattuglia chiamata dal vigile che hai preso a pugni.
func arrest_by_carabinieri() -> void:
	vai_n_galera("CARABINIERI! È FERNUTA 'A CUMMEDIA.")


func arrest_player() -> void:
	if arrested:
		return
	arrested = true
	bail_paid = mini(money, maxi(10, int(soldi_visibili() * 0.3)))
	money = max(0, money - bail_paid)
	fines_paid += 1
	heat = 0.0
	money_changed.emit(money)
	heat_changed.emit(heat)
	rientro_forzato("vigile")


# ===========================================================================
# 'O SCASSO — quanto è difficile 'na machina, e quanto vale (0.57)
# ===========================================================================
#
# Il capo: *«Si rubano le auto con un minigioco di tempismo e abilità che è
# più difficile in base all'auto da rubare»*.
#
# **'A difficoltà nun è 'nu numero sulo.** Sarebbe stato più comodo tenere
# una "durezza" da 1 a 4 e moltiplicarci sopra tutto, ma una serratura che
# diventa solo *più veloce* è la stessa serratura suonata a un altro tempo:
# la impari una volta e poi le sai tutte. Qui cambiano **quattro cose
# diverse**, e ognuna chiede una cosa diversa a chi gioca:
#
#   * **'e spille** — quante volte di fila devi azzeccare. Non è difficoltà,
#     è **tenuta**: alla quinta il polso trema anche se le prime quattro
#     erano facili.
#   * **'a zona** — quanto è larga la finestra buona. Questa è **la mira**.
#   * **'a velocità** — quanto corre 'o cursore. Questo è **'o tiempo**.
#   * **'e spille rotte** — le due tacche rosse che se le pigli hai finito
#     subito. Questa è **'a paura**, ed è l'unica che cambia *come* si
#     gioca invece di quanto è stretto: con una tacca rossa in mezzo alla
#     barra non puoi più aspettare il passaggio comodo.
#
# L'utilitaria non ne ha nessuna di rossa e ha la finestra larga un terzo
# della barra: si apre al primo colpo e serve a insegnare il gioco. 'O
# macchinone d''o guappo ne ha due, sei spille e il cursore che fa quasi due
# corse al secondo — e vale quattro volte tanto.
## **'E numere so' stati rifatte doppo 'a primma prova, e chesta è 'a parte
## cchiù mportante 'e tutta 'a versione.**
##
## La prima tabella che avevo scritto andava «tutta in salita» e sembrava
## giusta: finestra più stretta *e* cursore più veloce a ogni gradino.
## `prova_furto` ha fatto il conto che io non avevo fatto — **quanti
## millisecondi il cursore resta davvero dentro alla finestra**, che è
## `zona / velocità` — e ha risposto: 316 ms sull'utilitaria, **68 sul
## macchinone**. Sessantotto millisecondi sono **quattro fotogrammi a
## sessanta**, e tre a trenta. Quello non è un minigioco di abilità: è un
## dado, e un dado truccato contro chi gioca.
##
## Il conto ha anche fatto vedere **perché** era successo: se stringi la
## finestra e insieme acceleri il cursore, il tempo utile scende con il
## *prodotto* delle due cose, cioè crolla. Due manopole che sembrano due
## sono una sola moltiplicata per sé stessa.
##
## Quindi la difficoltà sale sulle altre due — **'e spille** (tre → sei) e
## **'e spille rotte** (zero → due) — e su una discesa molto più gentile del
## tempo utile: 316 → 237 → 181 → **142 ms**, che a sessanta fotogrammi sono
## ancora otto, e a trenta ancora quattro. Stretto, ma è una mano, non una
## monetina.
##
## `prova_furto` adesso misura quel numero e boccia sotto ai 100 ms.
const SCASSO := {
	# **'E valure d''a 0.61.** Erano 130, 220, 350 e 490 euro: la prima bmw
	# della giornata valeva **sei giornate** di posteggio, e il capo l'ha
	# visto alla prima partita lunga — *«un'auto rubata vale tantissimo»*.
	# Adesso la misura è la giornata tipo (`GIORNATA_TIPO`): un'utilitaria
	# ne vale mezza, una bmw poco più di una. Rubare resta il colpo grosso
	# della giornata, ma non la giornata.
	#
	# **'E valure d''a 0.62.** Il capo, dopo averci giocato: *«rubando una
	# macchina mi sembra giusto che si facciano 100 euro, abbastanza per
	# pagare le spese per qualche giorno»*. Aveva ragione lui: a 55 euro una
	# berlina rubata — con le stelle addosso, la corsa fino al garage e il
	# rischio di perderla per strada — rendeva meno di una mattinata seduto
	# sulla sedia, e il colpo grosso non sembrava un colpo grosso. Adesso
	# la berlina vale cento (due giorni di spese), l'utilitaria sessanta, la
	# bmw centosettanta. Il freno non sta più nel prezzo della prima, sta
	# nel ricettatore che la seconda la paga la metà (`VENNUTA_CALO`) e alla
	# quarta chiude il piazzale.
	"economica": {"spille": 3, "zona": 0.300, "vel": 0.95, "oro": 0.34,
		"rotte": 0, "valore": 60, "nomme": "facile"},
	"berlina": {"spille": 4, "zona": 0.265, "vel": 1.12, "oro": 0.30,
		"rotte": 1, "valore": 100, "nomme": "seria"},
	"lusso": {"spille": 5, "zona": 0.235, "vel": 1.30, "oro": 0.27,
		"rotte": 2, "valore": 135, "nomme": "tosta"},
	"bmw": {"spille": 6, "zona": 0.210, "vel": 1.48, "oro": 0.24,
		"rotte": 2, "valore": 170, "nomme": "'a cchiù tosta"},
}

## Quanti secondi hai per ogni spillo prima che la mano ti tremi.
const SCASSO_SECUNNE: float = 6.0
## Quanti errori ti passa prima che la serratura si blocchi.
const SCASSO_ERRORE_MAX: int = 2
## Il grimaldello allarga la finestra buona di un quinto e rallenta il
## cursore di un decimo: non ti regala il furto, te lo rende una cosa che
## si può imparare.
const GRIMALDELLO_ZONA: float = 1.20
const GRIMALDELLO_VEL: float = 0.90

## **'O dado d''o tentativo.** Stessa macchina, due prove diverse: la zona
## si sposta di un po' e il cursore cambia passo. Senza questo, chi impara
## la berlina ha imparato *tutte* le berline per sempre, e il minigioco
## diventa una formalità da tre secondi.
func scasso_pe(tipo: String, rng: RandomNumberGenerator = null) -> Dictionary:
	var base: Dictionary = SCASSO.get(tipo, SCASSO["berlina"])
	var r := rng
	if r == null:
		r = RandomNumberGenerator.new()
		r.randomize()
	# Lo scarto è stretto apposta (±10-14%): deve bastare a far sentire che
	# due serrature non sono la stessa serratura, non a far diventare un
	# tentativo impossibile e il successivo regalato.
	var zona: float = float(base["zona"]) * r.randf_range(0.90, 1.14)
	var vel: float = float(base["vel"]) * r.randf_range(0.92, 1.14)
	if upgrades.get("grimaldello", false):
		zona *= GRIMALDELLO_ZONA
		vel *= GRIMALDELLO_VEL
	return {
		"spille": int(base["spille"]),
		"zona": clampf(zona, 0.07, 0.46),
		"vel": maxf(0.5, vel),
		"oro": float(base["oro"]),
		"rotte": int(base["rotte"]),
		"valore": int(base["valore"]),
		"nomme": str(base["nomme"]),
		"errore_max": SCASSO_ERRORE_MAX,
		"secunne": SCASSO_SECUNNE,
	}


## Il nome della difficoltà, per il prompt sull'auto.
func scasso_nomme(tipo: String) -> String:
	return str(SCASSO.get(tipo, SCASSO["berlina"])["nomme"])


# ---------------------------------------------------------------------------
# 'O sfasciacarrozze
# ---------------------------------------------------------------------------
#
# **'A paga cala 'e juorno 'n juorno... anze, 'e machina 'n machina.**
#
# Questo è il freno, e senza di lui la 0.57 sarebbe la versione che ha
# rotto il gioco. Fate il conto: una berlina vale duecentoventi euro, e una
# giornata intera di posteggio ne fa ottanta. Se il garage pagasse sempre
# duecentoventi, dalla 0.57 in poi nessuno poseggerebbe più una macchina in
# vita sua — e il gioco si chiama *Parcheggiatore Abusivo*, non
# *Sfasciacarrozze Simulator*.
#
# Quindi il ricettatore fa quello che farebbe un ricettatore vero: la prima
# della giornata gliela paghi bene, la seconda meno, e alla quarta ti dice
# che il piazzale è pieno. Trentadue per cento in meno ogni volta, con un
# pavimento a un quarto: la prima macchina è una giornata di lavoro, la
# quinta è una mancia. Rubare resta la cosa che paga di più **una volta al
# giorno**, che è esattamente quanto dev'essere.
## **0.62**: da 0.62 a 0.5 — la prima vale di più (vedi `SCASSO`), la
## seconda la metà, la terza un quarto. Tre bmw in una giornata fanno
## meno di trecento euro, non mezzo migliaio.
const VENNUTA_CALO: float = 0.5
const VENNUTA_MINIMO: float = 0.20
## **'O piazzale è chino** (0.61). Tre macchine al giorno, e basta: la
## quarta il ricettatore non la vuole vedere. Prima la pagava un quarto,
## e un quarto di tanto era ancora tanto.
const GARAGE_MAX_JURNATA: int = 3
## **'A jurnata tipo** (0.61): quanto fa una giornata di posteggio fatta
## bene, senza niente addosso (22 clienti, vedi `prova_economia`). È il
## metro con cui si misurano tutte le altre entrate: una cosa che rende
## più di una giornata in cinque minuti rompe il mestiere.
const GIORNATA_TIPO: int = 80
## Quanto toglie ogni botta presa per strada. Una macchina ammaccata la
## paga meno anche chi non fa domande.
const VENNUTA_DANNO: float = 0.11
## Quanto aggiunge ogni spillo preso in pieno centro: il premio della mano
## ferma, che si vede nel prezzo e non solo in una scritta.
const VENNUTA_ORO: float = 0.06

var auto_vennute: int = 0
var soldi_auto: int = 0


## Quanto ti darebbero adesso per una di quel tipo, senza venderla.
func quanto_vale_a_machina(tipo: String, danni: int = 0,
		ori: int = 0) -> int:
	var d: Dictionary = SCASSO.get(tipo, SCASSO["berlina"])
	var q: float = float(d["valore"])
	q *= maxf(VENNUTA_MINIMO, pow(VENNUTA_CALO, float(auto_vennute)))
	q *= maxf(0.35, 1.0 - float(danni) * VENNUTA_DANNO)
	q *= 1.0 + float(ori) * VENNUTA_ORO
	return maxi(12, int(round(q)))


func garage_chino() -> bool:
	return auto_vennute >= GARAGE_MAX_JURNATA


## Consegnata. Torna quanto t'hanno dato.
func vinni_machina(tipo: String, danni: int = 0, ori: int = 0) -> int:
	var paga: int = quanto_vale_a_machina(tipo, danni, ori)
	auto_vennute += 1
	soldi_auto += paga
	add_money(paga)
	# **Nisciuna reputazione.** Il ricettatore paga in contanti e non scrive
	# niente a nome tuo: la macchina venduta non ti rende un posteggiatore
	# migliore. Il guadagno è il guadagno, e basta — se desse anche fama
	# sarebbe meglio del mestiere sotto ogni aspetto, e il mestiere è il
	# gioco.
	SoundManager.soldi(paga)
	return paga


## **Scinne d''a machina, pure si nun 'o vuò.**
##
## Il player che guida ha `set_physics_process(false)`: non cammina, non
## cade, non interagisce. Se la giornata finisce mentre sta al volante —
## l'orologio arriva alle quattro, il vigile chiama la pattuglia, la moglie
## chiama e si va a casa — quel `false` non lo rimette a posto nessuno, e il
## giorno dopo ti risvegli congelato in mezzo alla piazza.
##
## È esattamente la forma della cella della 0.56: **chi chiude una porta
## deve possedere anche il modo di riaprirla.** Qui la porta la chiude
## `car_3d.arrubba()`, e questa è la chiave che tiene 'o GameManager, che è
## l'unico che sa quando una giornata finisce.
func scinne_d_a_machina() -> void:
	var a: Node = auto_guidata
	if a != null and is_instance_valid(a) and a.has_method("scinne_forzato"):
		a.scinne_forzato()
	auto_guidata = null


## T'hanno sentito: 'a serratura s'è bloccata e 'o quartiere s'è scetato.
func scasso_fallito(quanto: float = 1.0) -> void:
	crimine(PUNTI_PER_STELLA * quanto)
	report_risky_action(18.0 * quanto)
	SoundManager.play("fail", -3.0, 0.82)
