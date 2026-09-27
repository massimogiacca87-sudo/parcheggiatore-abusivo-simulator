# Novità della v0.64 · 'O Rre e 'e Strisce

27 settembre 2026. La richiesta del capo, in tre tempi:

> *«Assicurati innanzitutto che funziona il sistema di conquistare le altre
> piazze, con i soldi o con i pugni. Assicurati che una volta acquisite,
> funzionino esattamente come la tua, cioè entrando in piazza cominciano ad
> arrivare auto da parcheggiare.»*
>
> *«Poi implementa queste due idee, col mio twist. 'O Rre d''e Parcheggi:
> alla terza giornata viene questo figuro (inventalo da zero, con un modello
> dedicato) che ti sfida — "ah e tu vulisse fà 'o parcheggiatore? E famme
> verè" — una sfida a tempo, con una musichetta e il tic tac: devi
> posteggiare più macchine possibile in un minuto. Almeno 5: ti dà una
> piazza in omaggio. Almeno 3: vinci un guaglione che lavora per te. Una
> sola: ti insegue e ti picchia dicendo "ma arò t'avvie omm' 'e sfaccimma,
> va' a faticà va'". 'E Strisce Blu: certe mattine ti svegli e trovi le
> strisce blu nella tua piazza (o in un'altra delle tue), con i parchimetri.
> Devi rompere tutti i parchimetri (modelli 3D ben riconoscibili), e se non
> ridipingi le strisce di bianco (pittura e pennello al bazar) i clienti
> continuano a non pagarti, o fanno come se li avessi messi fuori dalle
> strisce.»*
>
> *«Infine le cose rimaste in sospeso dalle versioni precedenti: fai tutto
> quello che devi aggiustare.»*

---

## 1. Le piazze conquistate: prima si prova, poi si aggiusta

C'è una prova nuova che le **gioca**, `prova_conquista`: nella città vera
compra il mercato, prende lo stadio a mazzate (il rivale va steso davvero,
con la mazza), compra la cornetteria, e poi resta cento secondi in ognuna delle
quattro piazze a guardare se arrivano macchine, se trovano posto, se si
posteggiano e se pagano. Al primo giro ha trovato nove guasti:

1. **Entrare in una piazza appena comprata non ti metteva in servizio.** Se
   la compravi stando lì dentro, il gioco non se ne accorgeva finché non
   uscivi e rientravi: niente macchine. Adesso quando una piazza cambia
   padrone la città rifà il conto subito.
2. **Il cartello all'ingresso diceva ancora il nome del vecchio padrone.**
   Adesso cambia (e cambia di nuovo se la piazza la perdi: segnale nuovo
   `zona_persa`).
3. **Il primo cliente ci metteva un'eternità.** Nella piazza di casa arriva
   subito; nelle altre si aspettava il giro del temporizzatore, fino a
   mezzo minuto. Adesso, entrando in una piazza tua senza nessuno da
   servire, il primo arriva fra due e quattro secondi. Stessa regola in
   tutte e quattro.
4. **Il mercato aveva quattro posti.** Le file finivano sei metri prima del
   bordo, e in una piazzetta di ventun metri vuol dire due posti per fila:
   sei clienti su tredici se ne andavano senza posto. Adesso le file
   arrivano a quattro metri e mezzo dal bordo, e dove c'è spazio fra le
   due file c'è una **fila di fondo**: otto posti.
5. **Allo stadio le macchine d'arredo stavano parcheggiate sopra ai posti**
   (sei per fianco, di traverso sulle strisce). Adesso l'arredo chiede prima
   dove stanno i posti veri.
6. **I posti murati.** Un posto con dentro una bancarella o un banco è un
   posto dove la regia a gesti va a sbattere. Alla prima misura la piazza
   li spegne (non si disegnano e non si assegnano).
7. **Le macchine si incastravano entrando.** I punti dove aspettano in coda
   erano una griglia fissa, e la strada per arrivarci passava sopra ai
   posti — con una macchina posteggiata lì, chi arrivava si piantava e dopo
   sette secondi se ne andava. Adesso si entra solo dai lati aperti, la
   griglia della coda non tocca i posti, e ogni macchina sceglie un punto
   **libero e non tappato** (la sua strada non passa addosso a chi aspetta),
   prima quelli in fondo. Lo stesso nella piazza di casa.
8. **'O vico d''a cornetteria è stretto**: il palazzo a nord, il banco
   dell'armiere a sud, e l'unico modo di arrivare alla coda è di lato. Il
   posto in mezzo alla fila di ponente adesso resta vuoto: è la corsia
   d'ingresso. La cornetteria ha cinque posti invece di sei, e di giorno
   un po' più di gente (0,45 invece di 0,34: era un deserto troppo deserto).
9. **Il secondo rivale non era più duro del primo.** La forza si contava una
   volta sola, a città costruita. Adesso ogni piazza tua in più gli dà
   quindici punti, e il conto si rifà quando una piazza cambia mano.

E due piccole: nella piazza di casa la scatola del punto dove ci si
appoggia al bar tappava un posto; la freccia del cliente sull'HUD indicava
macchine di altre piazze.

Un decimo è venuto fuori rifacendo la prova alla fine: alla cornetteria
tre clienti si sono fermati a due metri e mezzo dal punto d'attesa (c'era
qualcosa sulla loro riga), e dopo sette secondi se ne sono andati. Una
macchina così è in coda lo stesso: adesso, ferma a meno di tre metri dal
suo punto, si mette ad aspettare lì, e la si guida da lì.

**Come va adesso** (`prova_conquista`, cento secondi per piazza):

| piazza | arrivate | posteggiate | pagate | incasso | senza posto |
|---|---|---|---|---|---|
| la tua | 4 (+1 già in coda) | 4 | 3 | €32 | 0 |
| mercato (comprata) | 8 | 9 | 8 | €32 | 0 |
| stadio (a mazzate) | 7 | 8 | 7 | €123 | 0 |
| cornetteria (comprata) | 3 (di giorno) | 4 | 4 | €38 | 0 |

Le piazze prese lavorano come quella di casa, ognuna col suo carattere:
il mercato tanta gente e poca mancia, lo stadio pochi e ricchi, la
cornetteria che si sveglia di notte.

**E coi pugni?** A mani nude il rivale non si stende, ed è una scelta
fatta apposta qualche versione fa: un pugno toglie due punti, il rivale ne
ha quaranta (più quindici per ogni piazza che hai già) e te ne toglie
undici a botta. È il muro che ti manda a comprarti un ferro, e alla
seconda botta a vuoto te lo dice lui: *«Cu 'e mmane?! Va' t'accatta 'nu
fierro, guaglio'.»* Con la mazza (€50 dall'armiere) sono sei-otto botte, e
la prova la prende così. Se il capo vuole che bastino le mani, è una riga:
il danno a mani nude contro i rivali (vedi la roadmap).

## 2. 'O Rre d''e Parcheggi

**Chi è.** Don Vicienzo Cuoppo, detto 'O Rre d''e Parcheggi: trent'anni di
piazze, dice lui, e mai una multa. Grosso, pelato coi baffi, camicia di raso
cremisi. In testa la **corona** d'oro (di latta) coi cinque punti e le
pietre rosse e blu; **occhiali neri** a mascherina con la montatura d'oro;
il **sigaro** con la brace che si accende e il filo di fumo; la **catena**
d'oro con la medaglia e la P; il **mantello** rosso foderato d'oro, col
collo d'ermellino a macchie nere e la P grossa sulla schiena; e in mano la
**paletta** del parcheggiatore, tenuta come uno scettro. Sopra la testa, a
lettere d'oro: 'O RRE D''E PARCHEGGI. Tutto costruito a codice sul pupo
panzone (`scripts/re_parcheggi_3d.gd`).

**Quando viene.** Dal terzo giorno, quando stai in servizio in una piazza
tua da quaranta secondi — senza stelle, senza Borrelli, senza una macchina
in mano. Arriva a piedi da una ventina di metri e ti dice la frase:
*«Ah, e tu vulisse fà 'o parcheggiatore? E famme verè.»*

**La sfida.** **[E] accietta** (se non rispondi, dopo venti secondi comincia
lui lo stesso). Tre, doje, una: un minuto, con la sua musica — una
tarantella in la minore scritta apposta, mandolino col tremolo, chitarra,
tammorra — e il tic tac, che negli ultimi dieci secondi diventa più forte.
Le macchine le chiama lui: arrivano di corsa, non perdono la pazienza, non
pagano e appena posteggiate se ne vanno a far posto alla prossima. Intanto
il flusso normale della piazza si ferma, e Borrelli aspetta. **Contano solo
le macchine messe dentro a un posto**: con F, fuori dalle strisce, non vale
(e lui te lo dice). In alto il cronometro, il conto e la barra con le
soglie 1-3-5.

**Com'è finita.**

| posteggiate | cosa succede |
|---|---|
| 5 o più | **una piazza in omaggio** (la prima libera fra mercato, stadio, cornetteria), senza affitto e **senza boss di capitolo**: l'ha sistemata lui con chi la teneva. Se le hai già tutte: €450. Non torna più. |
| 3 o 4 | **un guaglione** che lavora per te, Sasà 'o Lampo (nella piazza della sfida, o in un'altra tua senza guaglione). Se ce l'hai già dappertutto: €60. Non torna più. |
| 2 | niente: se ne va dicendo che torna. Rivincita fra tre giorni. |
| 1 o 0 | *«Ma arò t'avvie, omm' 'e sfaccimma?! Va' a faticà, va'!»* — ti corre dietro e ti mena: tre botte, dodici ossa l'una, **ma non ti manda all'ospedale** (si ferma a dodici). Rivincita fra tre giorni. |

Si può anche stenderlo mentre ti mena, e si ferma: ma è grosso, 46 punti,
e a mani nude un pugno ne toglie due — ci vuole un ferro (sette botte di
mazza). Lo stato (quando torna, com'è finita) sta nel salvataggio.

**La prova** `prova_re_parcheggi` gioca quattro sfide, una per esito: non
viene il primo e il secondo giorno né prima dei quaranta secondi; arriva in
5-14 secondi; manda 7-9 macchine al minuto; nessun cliente normale nasce
durante la sfida; 5 → il mercato in omaggio; 3 (più una messa con F, che
non conta) → Sasà 'o Lampo; 2 → niente, rivincita; 1 → tre botte, ossa da
72 a 18, niente ospedale. Zero storte.

**Poi, rifacendo tutte le prove alla fine, è andata storta.** Una volta su
tre, nella sfida delle due macchine, il minuto finiva con due macchine
arrivate in tutto e nessuna in coda. Guardata secondo per secondo (dove sta
ogni macchina, a che velocità, contro che cosa sbatte) ne sono uscite
cinque cose, quattro del gioco e una della prova:

1. **Chi entra e chi esce passano dalla stessa bocca.** Nella piazza di
   casa l'ingresso e l'uscita sono lo stesso varco: con una macchina che
   esce e una che entra ogni pochi secondi, chi usciva (a passo di cliente)
   tappava chi entrava. Adesso le macchine del Rre entrano senza sbattere
   contro le altre macchine (contro i muri sì), tornano solide appena sono
   in coda — la regia a gesti le botte le conta — ed escono di corsa senza
   che nessuno ci sbatta contro.
2. **Una macchina sul tetto di un'altra.** Chi arrivava addosso a una
   macchina ferma sul proprio punto d'attesa ci finiva sopra (1,3 metri,
   misurato) e da lassù non risultava mai «arrivata». Adesso l'arrivo si
   misura in piano.
3. **La coda non vedeva le macchine messe con F.** Una macchina lasciata
   fuori dalle strisce proprio sul punto d'attesa ci resta mezzo minuto, e
   la coda ci mandava la prossima. Adesso chi sta posteggiato con F tappa
   come chi aspetta, in tutte e quattro le piazze.
4. **Il guaglione si prendeva le macchine del Rre.** Se ce l'hai nella
   piazza della sfida, andava a posteggiarle lui: una sonda l'ha visto
   partire dal suo posto, salire e metterla dentro. La sfida è tua: adesso
   te le lascia.
5. **La prova stava ferma in mezzo alla piazza sei minuti**, e il motorino
   (che punta la corsia dove stai) la prendeva otto-nove volte: a metà
   della terza sfida finiva all'ospedale, che chiude la sfida. Adesso si
   scansa, come il bot delle dieci giornate. E guida solo le macchine del
   Rre: il primo cliente che trovava in coda, messo con F sul punto
   d'attesa, era quello che tappava tutto.

Rifatta quattro volte dopo le correzioni (le ultime due sul codice finale,
una dentro alla batteria): zero storte, e sette-nove macchine del Rre nel
minuto quando si posteggia di continuo.

## 3. 'E Strisce Blu

**Quando.** Dal secondo giorno, una mattina su cinque (misurato: 20,8% su
4.000 mattine), il Comune pitta le strisce blu in **una** delle tue piazze
(mai due insieme). Lo dice il biglietto sulla porta di casa, e lo ripete
la piazza quando ci entri: quanti parchimetri stanno ancora in piedi e
quanti posti restano da ripittare.

**Il parchimetro** (`scripts/parchimetro_3d.gd`) è quello di tutte le
strade d'Italia: palo blu, corpo grigio col tetto tondo blu, display verde
con la tariffa, la tastiera, la fessura delle monete, lo scontrino che esce,
e sopra il cartello blu con la P bianca, che si legge da in fondo alla
piazza. Uno ogni tre posti, fra due e quattro per piazza, sul bordo della
fila dei posti (dove li metterebbe il Comune), provati col motore fisico
prima di piantarli. **Si sfascia** a pugni o col
ferro (quattro pugni a mani nude, due botte di cric o di mazza; col fiato
che finisce a sette pugni, tre parchimetri di fila vogliono un caffè in
mezzo): si piega, il display
si spegne, lo sportello si apre, e cadono le monete (fra due e sette
euro).

**Tre stati per ogni posto.**

1. **Blu, con un parchimetro ancora in piedi**: il cliente va alla
   macchinetta a pagare (lo si vede andare) e a te dice di no — *«Uè, ccà ce
   sta 'o parchimetro. Tu che vuò?»*. Solo a cazzotti.
2. **Blu, coi parchimetri tutti rotti**: per lui è come se l'avessi messo
   fuori dalle strisce — paga meno e il vigile gli può fare la multa
   (*«'O parchimetro è rutto... e si me fanno 'a multa 'a pave tu?»*).
3. **Ripittato di bianco**: torna un posto tuo.

**La pittura** si compra al Bazar (tasto 7): *pittura janca c''o pennello*,
€12, sei passate. Fermo accanto a un posto blu, [E]: due secondi e mezzo
di pennello (col suono della pennellata e le strisce che si schiariscono
man mano). Quando i parchimetri sono tutti a terra **e** i posti tutti
bianchi, *«'a piazza è turnata 'a toia!»*. Lo stato sta nel salvataggio:
il Comune non ripara di notte, e il lavoro di ieri resta fatto.

Vale anche per il guaglione: su una striscia blu col parchimetro in piedi
non incassa niente, senza parchimetro una volta su due.

**La prova** `prova_strisce_blu`, sette parti nella piazza di casa: il
Comune pitta (i posti blu, i parchimetri fuori dai posti e fuori dai muri),
chi posteggia sul blu va alla macchinetta (in 7,5 secondi), i parchimetri
si sfasciano (€11 di monete), il blu senza macchinetta è «fuori dalle
strisce», la pittura (tutto ripittato in dieci passate), il salvataggio,
il dado della mattina. Zero storte.

## 4. Le cose rimaste aperte

- **La prova che gioca dieci giornate da sola** (chiesta dalla roadmap dalla
  0.61): `prova_dieci_giornate`, vedi sotto.
- **La sala scommesse** era l'unico pannello fuori dal tema della 0.62 (blu
  elettrico, spigoli vivi): adesso ha i colori, gli angoli, i bordi d'oro e
  i caratteri di tutti gli altri, con la stessa disposizione del tabellone.
- **Il balcone di Donna Filumena** era una soletta chiara e una lastra nera
  su una facciata già piena. Adesso è un balcone della città: mensola di
  pietra, ringhiera di ferro battuto coi balaustrini, i vasi; il panaro
  tirato su sta fuori dalla ringhiera e la corda scende dal corrimano.
- **Le signore sedute** davanti ai bassi sembravano vecchi (capello grigio
  corto): adesso hanno il **fazzoletto in testa**, cinque colori scuri, col
  nodo sotto al mento e la punta sulla nuca.
- **Il negozio più vicino alla tua piazza stava a 37 metri.** Perché: la
  piazza di casa ha i palazzi suoi, che la città non conosce, e le facciate
  che trova dietro danno sui vicoli da quattro metri (il punto dove si
  ferma chi guarda la vetrina cade in carreggiata: scartate tutte). Adesso
  le serrande aperte con la merce fuori sono mete vere: il più vicino sta a
  18 metri.
- **Le trenta vetrine, fotografate per la prima volta tutte**
  (`foto_vetrine`, i provini con `foto_provino.py`): mezza bottega aveva **un
  portone verde o un muro di manifesti dentro al vetro**. Il fondo della
  vetrina stava ventidue centimetri dentro al muro, e il piano terra del
  palazzo gli sporgeva davanti. Adesso il fondo copre il piano terra, i
  ripiani gli stanno davanti e il vetro davanti ai ripiani. (Tre foto del
  Decumano, sotto alla piazza di casa, uscivano coi muri: era l'occhio di
  `foto_vetrine` dentro ai palazzi della piazza, che la città non conosce.
  Adesso chiede al motore fisico, e le trentuno mete si vedono tutte da
  fuori.)
- **Le pozzanghere nel browser.** Quelle della 0.62 sono uno shader che la
  build web non può usare: lì pioveva su un selciato asciutto. Adesso, solo
  nel browser, ci sono chiazze d'acqua scure con l'orlo sfumato, in
  carreggiata e nella piazza di casa.
- **I plugin che il gioco non usa non partono più**: tolto l'autoload di
  Dialogic (partiva a ogni avvio per niente) e nascosta LimboAI con un
  `.gdignore` (erano le tre righe «Error loading extension» all'avvio).
  Alla fine, facendo le build, anche Dialogic ha avuto il suo `.gdignore`:
  77 classi globali su 107 erano sue, entrava nell'exe (4-5 MB) e a ogni
  esportazione dava una quarantina di errori. I file restano: si
  riaccendono in un minuto (vedi COME-RIPRENDERE).

## 5. Quello che è venuto fuori guardando: facce e braccia

Per fotografare il Rre da tutti i lati ho scritto `tools/foto_modello.gd`
(una persona, da davanti, di tre quarti, di fianco, da dietro, la faccia, e
mentre cammina). La prima cosa che ha fotografato dopo il Rre è stato
Borrelli — e **Borrelli girava con gli occhiali e la barba sulla nuca**:
davanti la faccia liscia del pupo, dietro un secondo viso. Sull'osso della
testa il davanti è +Z, e la sua faccia era scritta a −Z, come sul vecchio
scheletro fatto a mano: con ogni probabilità da quando i personaggi sono
passati sullo scheletro delle animazioni (0.48-0.49). È la stessa trappola
della visiera del vigile trovata alla 0.54 — e nessuno l'aveva visto
perché Borrelli lo si guarda quasi sempre mentre ti corre incontro, di
fretta, di notte. Sistemati con lui, perché avevano lo
stesso errore: gli occhiali da sole di chi va in motorino e quelli dello
Zio.

E poi le braccia. `hold_bone`, che la 0.54 aveva già segnalato come
pericoloso («congela l'osso vicino alla posa di riposo»), era usato ancora
in tre posti, e in foto:

- il **vigile al bar** teneva la mano dietro la spalla, e la tazzina non si
  vedeva;
- la **signora della borsa** aveva il braccio piegato all'indietro e la
  borsa che galleggiava dietro di lei;
- **Borrelli teneva il telefonino contro la coscia** — l'oggetto che è tutta
  la sua meccanica.

Adesso c'è `animator.punta_osso`: invece di dire all'osso *che rotazione
avere*, gli si dice **dove puntare** (avanti, su, a destra, nel verso del
personaggio), e ogni fotogramma lo si gira quanto basta partendo dalla posa
animata. Il vigile tiene la tazzina col piattino all'altezza del petto; la
signora ha il braccio avanti e la borsa che pende, e quando ti vede se la
stringe al petto; Borrelli ha il telefono alzato davanti alla faccia, con la
lucetta rossa del REC che lampeggia verso di te. E la giacca di lino di
Borrelli non è più un cassone di scatole largo il doppio del busto: è il
busto stesso, con lo spacco della camicia, i revers e le maniche lunghe.

## 6. Dieci giornate, giocate da sole

`prova_dieci_giornate` gioca la città vera una giornata dopo l'altra, come
nel gioco (la scena si ricarica ogni mattina), con un parcheggiatore
**onesto e un po' ingenuo**: sta nel salotto della piazza di casa,
posteggia ogni macchina, chiede i soldi a ogni autista (se il sospetto è
sotto al 60%, se no aspetta), risponde al vigile «è pp''e ccriature», si
chiude in casa se arrivano i carabinieri, si scansa dal motorino, sistema
le strisce blu se le trova, e a mezzanotte e tre quarti torna a casa, dà
alla moglie le spese e va a dormire. Non ruba, non mena, non gioca, non
compra niente. Borrelli e il Rre sono spenti (hanno meccaniche loro: qui si
misura il mestiere di tutti i giorni).

**Com'è andata** (`GIORNI=10 VELOCE=20`, rientro all'una meno un quarto;
zero storte):

| giorno | tipo | incasso | macchine | non hanno pagato | perse | spese di casa | in tasca la notte | strisce blu |
|---|---|---|---|---|---|---|---|---|
| 1 | normale | €93 | 14 | 5 | 7 | €18 | €75 | |
| 2 | normale | €145 | 18 | 3 | 3 | €17 | €203 | |
| 3 | processione | €132 | 9 | 1 | 3 | €104 | €219 | sì |
| 4 | normale | €121 | 14 | 2 | 4 | €51 | €289 | sì |
| 5 | pioggia | €189 | 14 | 0 | 0 | €12 | €466 | |
| 6 | partita | €105 | 10 | 1 | 6 | €172 | €391 | sì |
| 7 | normale | €135 | 17 | 1 | 2 | €70 | €456 | |
| 8 | processione | €156 | 12 | 2 | 2 | €17 | €595 | |
| 9 | normale | €133 | 11 | 2 | 9 | €80 | €648 | |
| 10 | normale | €88 | 15 | 3 | 4 | €30 | €706 | |

In media al giorno: **€130 d'incasso e €57 di spese di casa**; dopo dieci
giornate in tasca ci sono **€706**. Zero multe, zero fermi. L'umore della
moglie sale da 65 a 94 (100 il giorno della partita).

Quello che dicono i numeri:

- **Il mestiere onesto, da solo, lascia una settantina d'euro al giorno.**
  Il mercato (€450) si compra la settima sera; la cornetteria (€1.350),
  allo stesso passo, verso la ventesima giornata — senza guagliuni, senza
  furti e senza le altre piazze che lavorano per te. La
  roadmap dalla 0.61 temeva spese uguali all'incasso (sui 68 euro l'uno):
  con le spese tagliate di un sesto nella 0.62, per chi lavora bene non è
  più così.
- **Le spese di casa ballano** da €12 a €172 (il conto della sera ha le sue
  sorprese): il giorno della partita l'incasso non le ha coperte e la
  notte c'erano 75 euro meno della mattina.
- **La pioggia paga** (€189, nessun cliente perso), la partita no (€105:
  meno macchine in piazza di casa, e le spese più alte).
- **Le strisce blu sono uscite tre mattine su nove** possibili (la terza,
  la quarta e la sesta): più del solito uno su cinque, ed è il dado. Al bot
  costano un barattolo di pittura e il tempo di sfasciare e ripittare.
- **I clienti persi** (da zero a nove al giorno) se ne vanno prima di
  essere serviti. Il bot ogni tanto è occupato (si scansa dal motorino,
  aspetta che il sospetto scenda, sistema le strisce blu), ma non li ho
  guardati uno per uno: è la prima cosa da guardare se al capo sembrano
  tanti.

Sono i numeri di un giocatore diligente e onesto: il capo, giocando, dirà
se gli tornano.

## Le trappole

1. **Una faccia montata sulla nuca non dà errore, e non si vede finché non
   si gira il personaggio.** Borrelli (probabilmente dalla 0.48-0.49), gli
   occhiali di chi va in motorino e dello Zio. La regola ora è scritta in testa a `foto_modello.gd`: una cosa
   attaccata a un osso si fotografa da davanti **e** da dietro.
2. **`hold_bone` era ancora in giro** tre versioni dopo la nota che diceva di
   non usarlo. Una nota in un documento non ferma nessuno: adesso c'è
   l'alternativa (`punta_osso`), che è il modo di fermarlo.
3. **Una variabile ripetuta (`a`) in una funzione ha spento il Rre intero**:
   «There is already a variable named "a"», e a cascata «Could not preload»
   in tutti gli script che lo nominano — la città partiva senza di lui.
   `--check-only` su ogni file toccato, sempre.
4. **Il `.gdignore` di LimboAI e la cache di Godot.** Con la cartella
   nascosta, `.godot/extension_list.cfg` la nomina ancora: il primo import
   nel contenitore è crollato una volta (segmentation fault), il secondo è
   andato. Sul PC quel file l'ho mandato nel Cestino alla consegna: Godot
   lo rifà alla prima apertura.
5. **Le pozzanghere sotto alla strada.** Il corpo del suolo sta due
   centimetri sotto allo zero, il manto delle strade un centimetro sopra, e
   i marciapiedi e il salotto dodici centimetri sopra **senza corpo**: il
   raggio non li vede. Prima prova: 340 chiazze, zero a schermo. Seconda:
   un'acqua che riflette il cielo bianco della pioggia è dello stesso
   colore della strada nella foschia. Terza: scura e poco lucida, e si vede.
6. **Il bot all'ospedale.** Il primo giorno della prova delle dieci
   giornate il parcheggiatore finto andava accanto alle macchine per
   dirigerle — cioè in carreggiata — e il motorino lo prendeva in pieno due
   o tre volte al giorno: la sera stava all'ospedale e i conti erano quelli
   di un disgraziato. Un bot deve stare dove sta un giocatore.
7. **Spezzare un lavoro grosso in commit piccoli, dopo.** Le modifiche della
   conquista, delle strisce blu e del Rre stavano negli stessi file. Il
   primo tentativo (pezzi di diff senza contesto applicati all'indice) ha
   messo una riga nel posto sbagliato e un commit che non partiva. Il modo
   che funziona: per ogni commit si costruisce il file dell'indice
   **togliendo** dal file di lavoro i pezzi che appartengono ai commit dopo,
   e prima di committare si avvia il gioco su quella versione esatta
   (`prova_commit.sh`, nel contenitore). Meglio ancora: committare man mano.
8. **Una prova deve seguire le decisioni.** `prova_conquista` voleva almeno
   sei posti per piazza; la cornetteria ne ha cinque apposta (corsia
   d'ingresso). Se la prova non lo sa, resta rossa e insegna a ignorarla.
9. **Una prova che va storta una volta su tre non è sfortuna.** La
   tentazione era rifarla finché passava (e alla seconda passava). Sotto
   c'erano quattro cose vere del gioco — la bocca della piazza tappata, le
   macchine sul tetto, la coda cieca alle F, il guaglione che rubava la
   sfida — e una della prova. Si trovano solo guardando la prova mentre
   gira, non il risultato.
10. **Una prova ferma in mezzo alla piazza è un bersaglio.** Il motorino
    punta la corsia di chi sta in piazza: è voluto, e una prova che non si
    scansa misura l'ospedale invece di quello che deve misurare. Il bot
    delle dieci giornate l'aveva già imparato; la prova del Rre no.

## La lezione

**Le cose si guardano da tutti i lati, anche quelle vecchie.** Questa
versione doveva aggiungere un personaggio e un sistema, e le due cose
nuove sono venute bene perché sono state fotografate da tutte le parti
prima di dirle finite. Ma la stessa abitudine, girata sulle cose vecchie,
ha trovato una faccia sulla nuca da una quindicina di versioni, portoni
dentro alle vetrine da quando le vetrine hanno i ripiani, braccia che non
reggevano niente. Nessuna prova le
avrebbe trovate: i numeri erano giusti. **La conquista, invece, l'ha
trovata una prova che gioca**: nove guasti al primo giro (e un decimo
rifacendola) che nessuna foto avrebbe mostrato, perché una piazza ferma
sembra uguale a una piazza che lavora. Ci
vogliono tutte e due le cose — guardare e giocare — e nessuna delle due
basta da sola.

E una coda, venuta fuori all'ultimo: **anche una prova si guarda mentre
gira.** Il risultato di `prova_re_parcheggi` diceva solo «due storte», e
alla volta dopo diceva zero. Quattro guasti veri del gioco stavano nei
secondi in mezzo, e si sono visti solo stampando ogni tre secondi dove
stava ogni macchina e contro che cosa sbatteva.
