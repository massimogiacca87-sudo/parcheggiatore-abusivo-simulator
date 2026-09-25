# v0.45 — 'A bacheca

Le quattordici cose della lista, una per una. E poi quello che è venuto
fuori strada facendo, che è la parte più lunga.

---

## 1 · Chi ruba lo stemma davanti al padrone se lo trova addosso

`react_to_car_crime()` non fa più una faccia storta: l'autista **ti
insegue e mena**. Passa in caccia per il 70% della durata piena, con un
colpo ogni 0,8 secondi. L'unico che non lo fa è il turista, che scappa —
è l'unico personaggio a cui il furto conviene farlo.

## 2 · 'E bug d''e personagge

Passata completa su tutte le macchine a stati dei personaggi. Dodici
guasti veri, in ordine di quanto si vedevano:

**'O dialogo 'e Borrelli era 'nu vicolo cieco.** Da `TALKING` si usciva
solo rispondendo o tirando un pugno. Chi si allontanava senza premere
1-4 restava col pannello a schermo **per sempre**, con i tasti dei numeri
mangiati (niente più acquisti in nessun negozio) e — molto peggio — con il
cronometro del turno fermo, perché la fase boss l'aveva già bloccato: la
giornata non finiva più. Adesso ha lo stesso timeout che il vigile ha da
tre versioni: venti secondi o venti metri.

**Nisciuno gesticolava, mai.** `speech_bubble._gesticola()` cercava il
nodo `Animator` *risalendo* l'albero. L'Animator sta tre piani più
**giù** (personaggio → visuale → rig → Animator). Quindi la clip "parla"
non è mai partita, dalla prima riga scritta, per nessun personaggio del
gioco. Il commento diceva il contrario ed era in buona fede: nessuno
aveva misurato.

**E appena l'ho aggiustato è venuto fuori il guasto sotto.** La clip
`parla` della libreria di cattura ha lo stesso difetto di retarget delle
spalle che aveva fatto scartare tutta la locomozione: misurata con
`tools/prova_pose.gd`, le mani finiscono a (−0.64, 1.22) e (0.73, 1.17)
— cioè **in croce**, all'altezza delle spalle. Ogni personaggio che
apriva bocca si metteva a T. Riscritta a mano, come idle e camminata:
gomiti stretti al corpo, avambracci che salgono e scendono in
controfase, polsi che girano. Le mani stanno adesso a (±0.23, 1.12), che
è dove le tiene uno che parla. A Napoli si parla davanti al petto, non a
braccia aperte.

**'O carabiniere camminava 'ncopp'ô posto.** Arrivato a destinazione
usciva senza azzerare la velocità dell'animazione: marciava fermo fino a
nove secondi in ricerca, e **da steso a terra pure** — ruotato di
ottantadue gradi, col ciclo di camminata addosso, per quattordici
secondi.

**'A pattuglia guidava dentro casa.** Era l'unico inseguitore senza il
blocco su arresto / ospedale / turno finito, e nessuno aveva il blocco su
"sta dentro casa": l'interno del vascio sta a (300, 300), fuori dalla
città, quindi il furgone guidava per ventisei secondi verso un punto a
centosessanta metri dalla mappa prima di arrendersi.

**Borrelli, dentro casa, nun se calmava cchiù.** Stesso motivo, effetto
peggiore: a quattrocento metri di distanza la furia si ferma al pavimento
(44), che sta **sopra** la soglia del dialogo (34). Non poteva più
arrivare a `WAITING_TALK`, e intanto camminava fuori dalla mappa col
cronometro fermo. Adesso entrare in casa vale come fumarsi una sigaretta:
lui si ferma e aspetta fuori.

**'O vigile distratto se purtava appriesso 'o pannello.** Se i guagliuni
del pallone lo chiamavano mentre stava parlando con te, cambiava stato
senza chiudere il dialogo: pannello a schermo per il resto del turno,
tasti 1-4 bloccati. Il pugno questa pulizia la faceva; la distrazione no.

**'E criature stevano affunnate 'n terra.** La quota del bacino per la
posa seduta (0,60) è misurata sul rig di riferimento alto 1,88, ma un
bambino alto 1,16 ha il rig scalato di 0,617. Con il numero non scalato
il bacino finiva quattro centimetri **sotto** le mattonelle e le gambe
piegate bucavano il pavimento. Stesso errore, al contrario, per il
vecchio della scopa: stava sei centimetri e mezzo dentro la seduta invece
che appoggiato sopra.

**L'euro ê criature se poteva dà 'na vota sola pe' partita.** Il flag era
un booleano per nodo, e le criature si costruiscono una volta sola quando
nasce il vascio: dal secondo giorno in poi il prompt restava per sempre
"sta cuntenta accussì". Adesso è il numero del giorno.

**'O viecchio d''a scopa gesticolava a vvuoto** per il resto della
partita: all'apertura del pannello passava alla posa che parla, e niente
lo rimetteva a posto alla chiusura.

**'A borsa d''a signora** restava stretta al petto per sempre una volta
che ti aveva notato: uscendo dallo stato d'allarme nessuno ripristinava
la posa da camminata.

**'A giravota dipendeva d''o frame rate.** Quattro personaggi giravano
con un peso fisso per fotogramma: a trenta fotogrammi giravano la metà
che a sessanta, e descrivevano curve larghe intorno ai punti di svolta
invece di svoltare. Adesso è legata al tempo.

## 3 · 'O combattimento

Il pugno ha un tempo di ricarica di 0,62 secondi, e soprattutto **la
catena si spegne**: colpi consecutivi sullo stesso bersaglio entro due
secondi valgono 1 → 0.62 → 0.38 → 0.24 → 0.16. Non si stun-locka più
nessuno tenendo premuto. E il player è più gracile: 72 punti di salute
invece di 100, e la rigenerazione si ferma a 48 — dopo una scazzottata
non torni mai a posto da solo.

## 4 · 'O splash doppio

`PAGINE` conteneva due elenchi diversi con lo stesso nome: i manifesti
d'apertura e gli sfondi del tutorial. Aggiungendo una pagina al tutorial
comparivano tre manifesti all'apertura. Divisi in `LOCANDINE` e `SFONDI`,
che è quello che sono sempre stati.

## 5 · Quando t'acchiappano, te gire

`guarda_verso()` e `interrompi_tutto()` sul player: la telecamera ruota
verso chi ti ha fermato, e tutto quello che stavi facendo si annulla —
molli la macchina che stavi dirigendo, il cartello che stavi piazzando,
le mani si abbassano. Vale per il vigile e per i carabinieri.

## 6 · 'O vigile chiamma 'e rinforze

Sospetto al massimo → chiama. Il 95% delle volte sono i carabinieri (due
stelle). Il 5% delle volte **è Borrelli**, e la boss fight arriva prima
del tempo.

## 7 · 'E mmacchine

Il modello bianco spaccato che si vedeva da venti build era
`car_bmw.glb`, esportato senza normali e senza materiali. Rimosso, con
altri tre `.obj` che non avevano materiali affatto. Al posto loro,
**sedici modelli verificati** distribuiti su quattro fasce, e
`tools/prova_modelli.gd` li carica tutti e controlla misure e materiali a
ogni build. Le macchine in piazza adesso sono davvero diverse l'una
dall'altra.

## 8 · 'E guagliune faticano overamente

**Prima non guidavano.** C'era un rubinetto che ogni sei-undici secondi
dichiarava "parcheggiata" un'auto ferma in coda, senza spostarla di un
centimetro e senza che il guaglione facesse un passo. Il commento diceva
che far camminare uno fino alla macchina era "mezza intelligenza
artificiale in più per una scena che il giocatore non sta guardando".
Era sbagliato: la piazza di casa è quella dove torni ogni sera, e ci
trovavi le macchine ferme in mezzo alla strada con scritto sopra che
erano a posto.

Adesso ha quattro tempi e si vedono tutti: cammina fino alla macchina, ci
sale (sparisce dentro l'abitacolo), **la macchina fa la stessa strada che
farebbe se la dirigessi tu** — con la stessa manovra assistita che
raddrizza e infila negli ultimi due metri — e poi lui riappare di fianco
e se ne torna al posto suo.

**E si assume parlandoci.** Quattro risposte: due domande a cui risponde
spiegando come funziona (e il menu resta aperto), una che firma, una che
chiude. Prima erano venticinque euro che se ne andavano premendo E una
volta sola, senza sapere niente.

**'O trenta per cento.** Via la paga fissa serale: uno che ti costa
uguale se la piazza rende cento o rende zero non è un socio, è un
affitto. Adesso incassa lui, e quando passi a ritirare **si tiene il
30%**. Se non passi affatto, la sera si tiene la metà — ed è quello che
rende il giro serale una scelta.

## 9 · 'A bacheca

Un pannello di sughero in ogni piazza, coi foglietti attaccati con le
puntine. Da lontano si vede se ha qualcosa: una bacheca vuota e una piena
si distinguono senza premere niente.

**'E pacche.** Porti una busta da una parte all'altra della città. Non è
una gara di velocità, è una gara di strade: **finché uno in divisa ti
vede, una barra sale**, e a cento ti fermano, ti trovano il pacco addosso
e ti ritrovi due stelle. Il raggio è sedici metri e non trenta perché i
vicoli sono larghi quattro: a trenta metri diventerebbe impossibile
invece che difficile. Paga 34-70 euro, che è l'unico modo di fare
cinquanta euro in due minuti.

**'E furte su cummissione.** Qualcuno vuole una macchina precisa: un
tipo, un colore. Tu quelle macchine le posteggi tutto il giorno. **Non
devi cercare niente e non devi forzare niente: devi solo fare il lavoro
tuo, e poi non restituire le chiavi.** Quando il padrone se n'è andato,
[E] e ci sali sopra — e da lì **la guidi tu**, con WASD, fino al garage.
90-260 euro secondo la fascia.

**'O garage**, uno per piazza come richiesto. Una saracinesca arrugginita
con la vernice scrostata e nessuna insegna, che si accende solo quando
hai un furto in corso.

## 10 · 'E case

Quattro gradini in bacheca, e l'ultimo è 'o Vommero.

| | dove | prezzo | fitto | umore â matina | sopporta 'e guaje |
|---|---|---|---|---|---|
| 'O vascio 'e mo' | 'E Quartiere | — | x1.00 | — | x1.00 |
| 'O terraneo cu 'o curtiglio | Centro Antico | €2.600 | x1.35 | +7 | x1.15 |
| Appartamento â Sanità | 'A Sanità | €9.800 | x1.90 | +14 | x1.35 |
| **'A casa ô Vommero** | 'O Vommero | **€27.500** | x2.80 | +24 | x1.70 |

Non sono un bonus da negozio: ognuna cambia tre numeri veri. Ti svegli
più contento tutte le mattine, **e il fitto quasi triplica** — comprare
meglio è una responsabilità settimanale, non un premio. E la terza
colonna è quella che si sente giocando senza vedersi nei numeri: dentro
un vascio di una stanza un rientro alle tre è una tragedia, in un
appartamento alla Sanità è una discussione.

## 11 · 'E mobile 'e casa

Rifatti da capo. I difetti erano tre e tutti della stessa famiglia — roba
costruita a occhio invece che misurata:

- **Mobili appesi al niente.** Il pensile della cucina e il crocifisso
  stavano a ventitré centimetri dal muro, sospesi in aria. Un
  parallelepipedo marrone che galleggia a un metro e settanta, visto di
  taglio, non è un pensile: è un affare che non si capisce, e ci si
  cammina dentro. Adesso c'è una costante per la faccia interna del muro
  e ogni pezzo si appoggia partendo da lì.
- **'A televisione stava dentro 'o letto.** Le due posizioni erano
  calcolate ognuna per conto suo e si sovrapponevano per mezzo metro.
  Non si vedeva perché il letto la copriva quasi tutta.
- **Niente colliders.** Sedie, pensile, piatti: tutta roba che si
  attraversava camminando.

E la stanza si è riempita di cose che si riconoscono a colpo d'occhio —
'o frigorifero con le calamite, 'o stipo con lo specchio e la valigia
sopra, 'o quadro d''o mare, 'o calannario, l'orologio, 'o sciacquamano.
Una stanza con quattro mobili sembra una demo; un vascio vero è pieno
fino al soffitto.

## 12 · 'A chiantina, rifatta

Il giudizio era "non si capisce un cazzo", ed era giusto. La versione
vecchia disegnava *tutto insieme*: undici nomi di quartiere, quattro nomi
di strada, tre righe di testo per ognuna delle quattro zone, più un
pallino con didascalia per ogni vecchio, ogni guaglione, ogni commissione
e ogni landmark. Trenta scritte su una carta di seicento pixel, tutte
dello stesso peso, tutte una sopra all'altra.

Tre regole adesso:

1. **Le scritte non si sovrappongono mai.** Non è più una speranza: ogni
   etichetta viene *chiesta* con una priorità, e alla fine vengono
   sistemate in ordine di importanza provando otto posizioni intorno al
   segno. Quella che non trova posto **non si disegna** — meglio
   un'informazione in meno che due illeggibili.
2. **Le forme si distinguono al buio.** Prima era tutto un pallino
   colorato. Adesso ogni cosa ha una sagoma sua — la casa è una casa, il
   vecchio è una carta da gioco, il guaglione è una figura in piedi, il
   garage è una saracinesca — e **la stessa funzione disegna la
   legenda**, così il segno sulla carta e quello nella legenda non
   possono divergere.
3. **Una cosa sola comanda.** Il resto si fa da parte.

Più: pannello a destra che si porta via tutto il testo lungo (prezzi
delle piazze, legenda, dove stai), rosa dei venti, scala in metri, cono
di vista sulla freccia del giocatore.

## 13 · Addò va purtato

Quando prendi un lavoro, la mappa smette di essere una cartina e diventa
un'indicazione: riquadro grosso in cima al pannello con **quanto manca in
metri e quanto tempo resta**, cerchio che pulsa sulla destinazione, filo
tratteggiato che parte da te. Se il lavoro è un furto e la macchina non
ce l'hai ancora, la mappa dice **cosa cercare** invece di dove andare —
perché quella macchina può arrivare in qualunque piazza.

## 14 · 'A boss fight

Il suggerimento diceva C ma il tasto è X: corretto. E se non hai
sigarette adesso te lo dice, invece di suggerirti un tasto che non fa
niente. Aggiunta la quinta risposta: **se ti becca vicino a un bar puoi
offrirgli un caffè** — un euro, come al banco.

---

## Quello che è venuto fuori strada facendo

**'O fumetto se mangiava 'a stanza.** Il balloon era un rettangolo 3D
largo fino a tre metri e mezzo con una riga sola di testo. Dentro casa si
parla a un metro di distanza: copriva l'intera stanza, e le prime foto
dell'interno erano mezze grigie. Adesso il testo va a capo e **la misura
dipende dalla distanza** — un fumetto è interfaccia travestita da
oggetto, e la misura giusta è quella che occupa sempre lo stesso pezzo di
schermo.

**Dentro casa 'o gioco te diceva ca stive fore d''a piazza.** L'interno
sta a (300, 300), cioè fuori da ogni zona: entrando in casa comparivano a
caratteri cubitali "SÎ ASCIUTO DÂ PIAZZA" e la bussola che diceva "'a
piazza toia, 381 m". Mentre stai in cucina a contare i soldi.

**'A bacheca guardava 'o muro.** Al primo giro sughero, foglietti e
tettoia stavano dalla parte sbagliata: chi ci arrivava davanti vedeva la
schiena di un pannello marrone.

---

## 'E prove

- `tools/prova_mira.gd` — **24 oggetti, 0 storte.** Mette il player
  davanti a ogni cosa interattiva del gioco e chiede al gioco cosa ha
  agganciato. È l'unica prova che conta: bacheca e garage sono stati
  aggiunti alla lista bianca dei bersagli, che è la riga che alla 0.44 ha
  reso invisibili sei oggetti costruiti bene.
- `tools/prova_economia.gd` — trenta giornate simulate: a €75 al giorno
  la prima piazza arriva il diciassettesimo giorno, nessuno scoperto. A
  €55 non si arriva: è la soglia sotto la quale bisogna cambiare qualcosa.
- `tools/prova_scopa.gd` — 300 partite per coppia, integrità del mazzo a
  posto, e la scala dei vecchi tiene: 44 / 51 / 56 / 58 / **66%**.
- `tools/prova_pose.gd` — è la prova che ha smascherato la clip "parla" a
  T. Adesso dice (±0.23, 1.12), che è una persona che parla.

---

**Pacchetti:** Windows 29,78 MiB · Web 18,01 MiB · Sorgenti 8,94 MiB.
