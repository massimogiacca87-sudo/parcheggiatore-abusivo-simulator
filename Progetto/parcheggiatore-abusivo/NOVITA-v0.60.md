# v0.60 — **'A città vestuta**

Il capo, riaprendo il lavoro dalla 0.59:

> «Tieni sempre dalla v0.53 in poi e non toccare mai le librerie di asset
> (Car Pack, Low Poly, Animated, Pandazole, PSX, Quaternius). Prima fammi
> vedere la lista, poi procedi.»

e poi, dopo il secondo giro sulle cose rimaste aperte dalla 0.59 (la galera
costruita dentro alla città, la posa rigida dell'umano di Quaternius, il
ragazzino che ogni tanto resta piantato, il peso delle ringhiere dei
balconi):

> «Infine, integra più asset nuovi che puoi, rendi in generale il mondo di
> gioco più dettagliato possibile. La prossima build la dedicheremo invece
> a rifinire il gameplay.»

Quindi due metà. La prima sono le **quattro cose rimaste storte** alla
chiusura della 0.59, e tutte e quattro si sono rivelate un po' diverse da
come erano state scritte. La seconda è **la città vestita**: cinquantotto
modelli nuovi del pacchetto PSX, messi ognuno accanto a qualcosa che c'era
già, più i tetti rifatti da capo — perché quelli che c'erano, visti dall'alto,
erano Venezia.

I numeri, prima e dopo:

| | 0.59 | 0.60 |
|---|---|---|
| modelli nel gioco (`prova_asset`) | 399 | **457**, zero mai usati |
| modelli del PSX Mega Pack usati | 116 su 592 | **172** |
| triangoli in tutti i MultiMesh della città | 3,93 M | 4,18 M |
| triangoli **dentro al raggio di vista**, dai cinque punti di `prova_conti` | 3,85–3,93 M (sempre tutto) | **1,14–2,23 M** |
| gruppi MultiMesh | 345 | 912 (i gruppi sparsi tagliati a quadretti) |
| la galera | sopra a due isolati e tre strade | **un isolato suo**, in cima al Vomero |
| texture dei tetti a falda | un collage di foto aeree di Venezia | **coppi disegnati** (`tools/genera_coppi.py`) |
| ragazzini «piantati» in `prova_ntuppate` | 1 ogni tanto | 0 (vedi la trappola 9) |

---

## 1. 'A galera torna dint'â pianta

Nella 0.59 era scritto così: il blocco della galera (26 × 11 × 16 m) si
costruiva nove metri dietro a `GALERA_FORE` = (178, 0, 163), cioè centrato a
(178, 154), e copriva due isolati interi, la strada z 152–156, il cardine
d''o Vommero e il vicolo di levante. **Era lì dalla 0.56.** Nessuno se n'era
accorto per tre versioni, perché la galera non aveva niente che la legasse
alla pianta: era un cubo messo lì a mano. L'ha trovata la griglia dei
passanti, quando una tappa è finita contro il suo muro di dietro.

**Adesso è un isolato della pianta** (`ISOLATO_GALERA = [133, 156, 155,
168]`): l'angolo di sud-est del Vomero, 22 × 12 m, in cima al terrapieno.
Essendo un isolato, tutto quello che cammina lo conosce già — i passi, la
griglia A*, il catasto delle cose — e sopra non ci si può più costruire
niente. Le funzioni che vestono gli isolati (facciate, spigoli, vetrine,
panni stesi) la saltano: al posto dei palazzi ci sta lei.

Com'è fatta, da fuori (è l'unico edificio del gioco fatto per essere visto
solo da fuori: non ci si entra, ci si finisce):

- travertino, zoccolo di piperno, fascia a metà e cornicione: le tre righe
  orizzontali che fanno di un muro cieco un edificio pubblico;
- **due file di finestrelle con le sbarre** (PSX) su tutti e quattro i lati,
  perché da sotto — dalla via bassa e dal cardine di levante — si vedono
  anche le facce di dietro, e un muro nudo sembrava un fondale;
- le bocche di lupo nello zoccolo, il **portone di ferro** a due battenti
  (PSX) nella cornice di piperno, la targa «CASA CIRCONDARIALE», la
  bandiera, **le due lampade a muro** (PSX) accese di notte;
- il **cancello carraio** (PSX) sul fianco di levante;
- in cima il **filo spinato** sui bracci inclinati verso fuori e la garitta
  sull'angolo: le due cose che contro il cielo fanno leggere «carcere»
  prima ancora della targa.

Il portone guarda a nord, sulla trasversale del Vomero; `GALERA_FORE` è
diventato (144, 3, 156) e chi esce la mattina si ritrova davanti al
portone, sulla collina, con la città sotto. Il posto dove stava prima è
tornato com'era: due isolati e tre strade.

## 2. L'umano ca steva 'n guardia

La «posa rigida» dell'umano di Quaternius, guardata da vicino, era un'altra
cosa: **la clip che si chiama `Idle` è una guardia da pugile**. Ginocchia
piegate, un piede avanti e uno dietro, busto di tre quarti, braccia
staccate dai fianchi. La gente ferma agli angoli sembrava pronta a menare.

Una clip di riposo vera nel pacchetto non c'è, e tradurre l'`Idle` del pupo
su questo scheletro è proprio l'errore che rovinò la 0.47. Quindi la posa
si **costruisce con le clip di questo corpo** (`_prepara_fermo` in
`human_builder.gd`):

- la base è la **camminata ferma in un fotogramma**: a 0,567 s i due piedi
  stanno sotto al corpo, le punte a meno di un centimetro, tutte e due a
  terra — un uomo dritto con le braccia giù;
- sopra ci va **la vita dell'`Idle`**, non la sua posa: per ogni osso la
  differenza fra l'`Idle` al tempo *t* e l'`Idle` al tempo zero, pesata
  (`FERMO_PESI`). La testa si guarda intorno, il busto respira, le braccia
  dondolano appena; le gambe restano ferme, perché un piede che scivola si
  vede più di tutto il resto.

La clip nuova si chiama `Fermo`, si costruisce una volta e si aggiunge alla
libreria del modello (condivisa da tutte le istanze). Tutte le richieste di
riposo dell'umano (`idle`, `parla`, …) ora vanno lì, e l'adattatore la usa
come riferimento al posto della guardia.

## 3. 'E guagliune e 'o pallone

Il «passante che ogni tanto resta piantato» di `prova_ntuppate` era sempre
**un ragazzino del largo d''e guagliune**, al bordo est del campetto. Le
cause erano tre, e una non era un difetto del gioco:

1. **Chi tene 'a palla sotto ê piere nun cammina: tira.** Il calcio parte
   da 1,05 m, ma le gambe si fermavano a 0,70. Con la palla schiacciata
   contro qualcosa il guagliuno restava a 0,78 m a camminare sul posto e a
   tirare calci che non la spostavano. Adesso chi è a tiro si ferma e tira
   (`arriva` 0,9 m per chi ha la palla).
2. **'A palla ca nun se move.** La palla incastrata fra un palo e il muro:
   tre secondi a tiro senza che si sposti di mezzo metro, e il ragazzino la
   raccoglie e la rimette in mezzo («S'è 'ncastrata! Aspè, 'a piglio io.»).
3. **'A palla ca esce d''o campo.** I ragazzini non escono dal cerchio del
   campetto (è quello che li tiene nel largo e non in mezzo alla strada), ma
   il pallone sì: chi gli stava più vicino ci camminava dietro contro il
   bordo del cerchio, sul posto. Adesso quando la palla esce si fermano a
   guardarla, e dopo un secondo e mezzo torna in gioco («Jammo, 'o pallone!
   Chi l'ha menato for'?»).

Dopo queste tre, `prova_ntuppate` segnava ancora un ragazzino piantato ogni
tanto. La sonda nuova (`sonda_guagliune`) stampa tutta la finestra dei tre
secondi invece dei soli estremi, e ha fatto vedere che **erano corse di
andata e ritorno**: tre metri verso la palla, la palla rimessa in mezzo, tre
metri indietro, e in tre secondi il ragazzino era dove era partito. La prova
guardava solo il primo e l'ultimo campione. Adesso è piantato chi resta per
tutta la finestra entro trenta centimetri, o chi torna al punto di partenza
senza essersene mai allontanato più di un metro (il tremolio contro uno
spigolo, che è il caso che la prova deve prendere).

## 4. 'E ringhiere pesante, e chi nun se vedeva cchiù

Alla chiusura della 0.59 la città metteva quasi quattro milioni di
triangoli nei MultiMesh, e **li disegnava tutti da qualunque punto**: i
balaustrini dei balconi da soli erano 1,84 milioni (5.893 ferri battuti da
312 triangoli), gli split dei condizionatori altri 0,85. Il gruppo dei
balaustrini era **uno**, il suo ingombro era la città intera, e Godot non
poteva scartarne nemmeno un pezzo.

**'E gruppe a quadrette** (`QUADRETTI`, `_flush_a_quadrette`): i gruppi
sparsi per la città si tagliano in quadretti di 32 metri, ognuno un
MultiMesh suo che si scarta quando è fuori dall'inquadratura e si spegne
oltre la sua distanza. Per chi da lontano si deve ancora vedere c'è il
**cambio**: oltre i 45 metri ogni balaustrino diventa la scatola del suo
ingombro, dodici triangoli dello stesso colore — a cinquanta metri un ferro
battuto e un bastoncino nero sono lo stesso pixel. Gli split fanno lo stesso
a 60 metri; le piantine dei balconi, la merce delle botteghe e i vasi
semplicemente spariscono oltre i 50–55.

Risultato, dai cinque punti di `prova_conti`: **da 3,85–3,93 milioni di
triangoli a 1,14–2,23**, con quasi seimila istanze in più in città.

E qui è venuto fuori un guaio che c'era dalla 0.59. Il raggio di vista dei
gruppi (`_batch_vista`) si misurava **dal baricentro del gruppo**. Per la
frutta del mercato, che sta tutta lì, va bene. Per chi è sparso no: **le
tazzulelle della 0.59 stanno sui banconi di quattro bar diversi**, il
baricentro cadeva in mezzo alla città, e a quaranta metri da lì non si
vedevano più — su nessun bancone. L'ha fatto vedere una foto della 0.60:
la signora seduta davanti al basso c'era, **la sua sedia no**. Adesso ogni
gruppo con un raggio si taglia in quadretti anche lui, e il raggio vale per
ogni quadretto.

## 5. 'A robba nova — cinquantotto modelli PSX

Del PSX Mega Pack la 0.58 ne aveva presi 116 su 592, quasi tutti roba da
tasca o da tavolo. Qui entra la roba che fa **città**. Le regole della 0.59
valgono tutte: si mette per ultimo, col suo seme (la città è la stessa a
ogni partita), solo dove `_sta_libero` / `_scatola_libera` dicono che c'è
posto, e ogni cosa più grande di un pacchetto di sigarette ha un corpo
(`_solido`). Il grosso sta in un file nuovo, `scripts/robba_psx.gd`.

**'E vasce.** Il piano terra di Napoli è fatto di case, non solo di botteghe
e portoni: metà dei muri di manifesti diventano un **basso** — la porta di
legno (due modelli), la finestrella con la grata di ferro e il davanzale, e
sulla soglia i vasi (pieni o vuoti). La porta si segna nel registro dei
portoni, così davanti non si mette niente. Trentacinque bassi in città.

**'E segge fore 'a porta.** Chi abita in un basso d'estate sta fuori: la
sedia sotto alla finestra (paglia, legno o sgangherata), a volte due girate
l'una verso l'altra col tavolinetto in mezzo, e **ogni tanto la signora
seduta** che guarda chi passa (un pupo con `Sitting_Idle`, il sedere
misurato sulla seduta come i vecchi della scopa). Dieci bassi con le sedie,
tre signore.

**'A strada.** Il **materasso in piedi contro il muro**, inclinato, accanto
alle scene d'angolo (fino a tre, uno macchiato); gli ingombranti vecchi accanto ai
cassonetti — **il divano sfondato, la poltrona, il televisore a tubo, il
comò della nonna, l'armadio**; i cartoni della bottega, la cassetta rotta e
la lattina arrugginita accanto ai cassonetti che hanno posto; la
**saracinesca dell'acqua** (il volantino rosso) accanto a un quadro
elettrico su due; **le cicche per terra** davanti ai bar e alle sale (si
spengono oltre i 25 metri); **le mutande** fra i panni stesi; la
**plafoniera a tartaruga** sopra un portone su quattro; la **bocca di lupo
della cantina** accanto a una serranda su tre.

**'E cantiere.** Un cantiere che sta lì da mesi ha il **bagno chimico** in
testa (il modello del pacchetto è di legno scuro; quelli italiani sono di
plastica blu, e `_tinto` lo ritinge), la pila di mattoni rossi e grigi
contro il muro e la tanica per il generatore.

**'E libbre usate.** Due banchi come a Port'Alba, uno su Spaccanapoli e uno
sulla strada della piazzetta: il banco con la schiena al muro, sei libri
diversi sdraiati e a pile, lo sgabello, il cartello scritto a mano
(«LIBBRE USATE — € 1 'o piezzo») e il libraio in piedi.

**Dentro ai posti che c'erano già:**

- **'O bar**: l'orologio a muro e le casse di birra impilate (con il corpo);
- **'E tre carte**: le banconote, le monete, il mazzetto e i soldi piegati
  sul tavolino;
- **'A scopa**: la sedia di paglia vera al posto delle sei scatole su cui
  si sedevano i vecchi (la seduta sta dove stava), e i soldi sul tavolo;
- **'A sala scommesse**: il totem delle quote accanto alla slot — il
  tavolinetto col monitor, il computer per terra, la cassa che spara la
  telecronaca;
- **'O sfasciacarrozze**: il neon, le ragnatele, la tanica blu, il barattolo;
- **L'armiere**: il neon sotto al telo;
- **'O vascio toio**: il cuscino, la cornice col cane, la presa e
  l'interruttore, il giochetto, il quaderno, una ragnatela in un angolo.

## 6. 'E tetti

Fino alla 0.59 le falde usavano `tetti_italiani.jpg`, che doveva essere una
foto di coppi presa dall'alto. **Era un collage di fotografie aeree di
Venezia** — palazzi, canali, barche, tutto rimpicciolito e ripetuto ogni due
metri e venti. Dalla strada quasi non si vedeva; dal Vomero, e in ogni foto
dall'alto, i tetti della città sembravano coriandoli.

Adesso i coppi si disegnano (`tools/genera_coppi.py`): file di coppi
convessi al sole alternate ai canali in ombra, che scendono lungo la falda;
ogni fila finisce con l'ombra di quella di sopra; ogni coppo ha il suo
colore di cotto, qualcuno bruciato, qualcuno col lichene. La texture si
ripete senza cuciture, e ce ne sono due (`coppi.jpg` e `coppi_x.jpg`, girata
di novanta gradi) perché il gioco la proietta dall'alto e le file devono
correre lungo la pendenza, qualunque sia il verso della falda.

E i **tetti piani** erano a strisce: la guaina e la lastra sotto stavano
alla stessa quota, e la scheda video non sapeva quale disegnare davanti (lo
*z-fighting*). La guaina adesso sta tre centimetri più su.

---

## Le trappole

1. **Un cubo messo a mano non sa dove sta.** La galera è rimasta sopra a
   due isolati per tre versioni perché non aveva niente in comune con la
   pianta: nessuna prova la conosceva, nessuno ci camminava vicino. Appena
   è diventata un isolato, tutto il resto l'ha vista da solo.
2. **Il nome del file non è quello che c'è dentro.** `tetti_italiani.jpg`
   era Venezia vista dall'aereo, e l'`Idle` di Quaternius era una guardia
   da pugile. In tutti e due i casi il codice era giusto; era sbagliato
   quello che gli davo da mangiare, e l'ha detto solo una foto da vicino.
3. **Il raggio di un gruppo non è il raggio delle sue cose.** Misurare la
   distanza dal baricentro va bene finché il gruppo sta in un posto solo.
   Le tazzulelle dei quattro bar erano invisibili dalla 0.59, e nessuna
   prova se n'è accorta perché le prove contano le istanze, non guardano se
   si vedono. L'ha trovata una sedia che mancava sotto a una signora.
4. **Due facce alla stessa quota si mangiano a vicenda.** Le strisce sui
   tetti piani non erano la texture: erano la guaina e la lastra alla
   stessa altezza.
5. **Il caso si consuma anche quando non lo usi.** Aggiungendo le mutande ai
   panni stesi, la prima stesura pescava un numero dal generatore a ogni
   filo, anche dove poi non metteva niente: tutti i numeri dopo sarebbero
   scivolati di uno, e **mezza città si sarebbe spostata** (panni, vasi,
   motorini, tutto quello che viene dopo nel seme). Rimesso com'era: si
   pesca solo dove si pescava prima.
6. **Una facciata che guarda fuori dalla mappa.** Le prime sedie dei bassi
   sono finite a x = −0,5, davanti ai palazzi del bordo che guardano verso
   il muro di confine. Adesso ogni cosa chiede prima se sta dentro alla
   pianta (`_dint_a_mappa`).
7. **Il nome di un gruppo decide cosa ne pensa una prova.** Le saracinesche
   dell'acqua stanno appese al muro a sessanta centimetri da terra; le avevo
   messe nel gruppo `strada_psx`, e `prova_quote` — che considera «da terra»
   tutto quello che comincia con `Gruppo_strada_` — ne ha contate sei
   sospese per aria. Rinominate `appise_psx` (appese).
8. **Lo script di prova non sapeva che una prova vuole lo schermo.**
   `prova_vascio_fondale` rifiuta di girare senza disegno (trappola 19 della
   0.59) e nella batteria completa andava con xvfb; `minic.sh` invece la
   faceva girare senza, e lei rispondeva «storte: 1». Il guaio era nello
   script, non nel gioco: ora anche `provac.sh` la fa girare con xvfb.
9. **La prova che conta gli estremi.** `prova_ntuppate` confrontava il
   primo e l'ultimo campione di tre secondi: chi va e torna risultava
   piantato. È la stessa famiglia della «prova che difende il bug» della
   0.59, girata al contrario — una prova che accusa l'innocente fa perdere
   tempo quanto una che assolve il colpevole, e ti fa correggere cose che
   non sono rotte.
10. **Le fotografie scattate da dentro ai palazzi.** Alcune delle prime
    inquadrature della galera e dei vicoli avevano l'occhio dentro a un
    muro: coordinate scritte a mano guardando la pianta a memoria. Si
    ricalcolano partendo da una strada vera.
11. **Il segno di un angolo.** I bracci del filo spinato, girati attorno
    all'asse del muro, alla prima prova puntavano verso dentro al cortile
    invece che verso fuori.

## La lezione

**Il nome non è la cosa.** `tetti_italiani` era Venezia, `Idle` era una
guardia, `strada_psx` era roba appesa al muro, il raggio del gruppo non era
il raggio delle tazzulelle, e il ragazzino «piantato» correva. Ogni volta il
codice faceva esattamente quello che il nome prometteva, e ogni volta il
nome mentiva. Le prove leggono i nomi; le fotografie no. Per questo la 0.60
ha più foto che prove nuove, e per questo d'ora in poi un modello, una clip
o una texture nuova **si guarda prima di usarla**, non dopo.
