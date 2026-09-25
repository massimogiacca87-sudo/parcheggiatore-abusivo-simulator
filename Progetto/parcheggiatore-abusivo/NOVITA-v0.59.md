# v0.59 — **Ogne cosa ô posto sujo**

Il capo:

> «Ti ho aggiunto nella cartella 4 nuove cartelle di asset. Car Pack, low
> poly asset e low poly animated humans e infine animated human. Usa tutti
> questi asset (3d model, animazioni, texture ecc, tutto) per arricchire il
> gioco graficamente. Più dettaglio, oggetti migliori. Se mancava qualcosa,
> aggiungilo. Possibilmente, non sovrapporre asset già usati, piuttosto
> integrali con quelli già esistenti. Già che ci sei, risolvi parecchi
> problemi di collisioni dei personaggi con l'ambiente e di T pose di molti
> personaggi. Cerca di animarli tutti decentemente.»

Tre richieste in una: **la roba nuova**, **i corpi che si attraversano**, **la
gente in croce**. Sono venute fuori legate più di quanto sembrasse: appena la
roba nuova ha avuto un corpo solido, i personaggi hanno cominciato a
sbatterci contro; appena i personaggi hanno avuto un corpo, si è scoperto
dove camminavano davvero. E quasi ogni volta la risposta era la stessa: una
cosa che stava **nel posto sbagliato da versioni**, senza dare errore.

I numeri, prima e dopo:

| | 0.58 | 0.59 |
|---|---|---|
| modelli nel gioco (`prova_asset`) | 206 | **399**, zero mai usati |
| pezzi di Pandazole in città | — | **178 su 178** |
| corpi solidi buttati via in silenzio | **338** | **0** |
| arredo che si compenetra (`prova_ngombri`) | mai misurato | **0** |
| personaggi in posa a T (`prova_croce`) | mai misurato | **0** |
| camminate arrivate su 400 (`prova_mure`) | ~300, contando solo i palazzi | **383–386**, contando anche le cose |
| passanti piantati in due minuti (`prova_ntuppate`) | mai misurato | **0** |
| vetrine vere | 31 (11 girate verso il muro) | **30, tutte sulla strada** |
| negozio più vicino al mercato | 36 m | **9 m** |

---

## 1. I quattro pacchetti

**Come sono entrati.** Nessuno dei quattro era pronto per Godot così com'era:
FBX in centimetri, scheletri con nomi diversi dal nostro, un atlante di colori
saturo come un cartone animato. C'è un progettino di lavoro a parte
(`/home/claude/esame` durante la sessione) in cui `tools/prepara_nuovi.gd`
apre ogni file e lo salva nel formato del gioco: **una `.mesh` per pezzo**, la
base a quota zero, la scala giusta, e — la cosa che conta — **un materiale
solo per tutti i 178 pezzi di Pandazole**. Mille oggetti che dividono lo
stesso materiale finiscono in pochi MultiMesh (uno per forma) e costano
pochissime chiamate di disegno.

**L'atlante è stato spento.** I colori di Pandazole accanto alle texture
fotografiche della città sembravano giocattoli. `tools/tinge_pandazole.py`
abbassa la saturazione dell'atlante (l'originale resta in
`tools/sorgenti/PandaMat_originale.png`), e la frutta prende la sua tinta da
`robba_panda.gd` (`TINTA_FRUTTA`: arance, limoni, pummarole, friarielli…).

### Car Pack — le macchine

- **'A gazzella** dei carabinieri: la macchina della polizia del pacchetto,
  4,25 m, blu notte con la banda rossa. Fino alla 0.58 si chiedeva
  `car_lusso`, che dalla 0.46 non esisteva: la pattuglia era **una scatola
  blu senza ruote**, e nessuno se n'era accorto perché la guardi scappando.
- **'O taxi** di Peppe, bianco con la scatola gialla sul tetto (prima era
  una berlina gialla qualunque).
- **'A machina d''e vigile**: la berlina del pacchetto, con banda, scritta e
  lampeggiante sulle **sue** misure. Il suo collider era girato due volte: ci
  si sbatteva contro l'aria davanti al cofano e si passava attraverso le
  portiere.
- **Le auto in sosta**: `car_economica`, `car_berlina`, `car_lusso`,
  `car_coupe2`, `car_sportiva2` più i sette `auto_pack_*`. I primi tre nomi
  erano modelli della 0.30 spariti alla 0.46: il codice li chiamava ancora,
  `spawn` tornava `null` e **un posto in sosta su quattro in tutta la città
  restava vuoto** da tredici versioni.
- I **clienti fissi** arrivano sempre con lo stesso modello, non solo con lo
  stesso tipo e colore.

### Low Poly Assets (Pandazole) — la città

Tutti e 178, ognuno attaccato a qualcosa che c'era già:

- **Il mercato**: i banchi erano casse vuote sotto al telo. Adesso sul piano
  ci stanno le cassette piene, due file da quattro, e ogni tanto il mucchio di
  meloni o di cocozze.
- **La merce fuori dalle botteghe**, che da lontano dice che bottega è prima
  dell'insegna: arance del fruttivendolo, legna e sacchi di farina della
  pizzeria, secchi e carriola del ferramenta, vasi del fioraio, giornali
  dell'edicola.
- **La strada**: quadri elettrici contro i muri, sacchetti della munnezza,
  ingombranti (il divano, il materasso, la lavatrice), le campane del vetro,
  i cartelli (la P ai varchi delle piazze, i divieti di sosta, senso vietato
  e stop agli imbocchi dei vicoli, le strisce vicino ai campetti, i dossi sul
  lungomare, la discesa pericolosa in cima alle rampe del Vomero), i
  cantieri con transenne, nastro, pala, fusti e **l'operaio inginocchiato**.
- **Il verde**: un alberello ogni sedici metri sul lato mare del lungomare,
  con l'aiuola; alberi, fioriere, siepi e cespugli negli slarghi.
- **I tetti e i balconi**: cisterne, antenne e roba sui terrazzi, comignoli
  sulle falde, piante vere sui balconi.
- **Il bar**: tre tazzulelle sul banco e il bicchiere d'acqua che a Napoli si
  dà prima del caffè.
- **'O vascio**: la culla, il comodino con l'abat-jour e il telefono, lo
  specchio, la pentola del ragù, olio e pasta, e sulla tavola pane,
  formaggio, latte, polpette e la teglia di lasagna. Per terra il trenino e la
  macchinina che il commento del codice prometteva da versioni.
- **Mergellina**: gli scogli veri al posto di centoquaranta scatole di
  piperno, e **'o piscatore** sul muraglione con canna, secchio, corda,
  binocolo e remo.
- **L'armiere**: mazza da baseball e piede di porco sulle casse.
- **Lo sfasciacarrozze**: i due limiti di velocità americani del pacchetto.
  In mezzo a una strada di Napoli sarebbero stati un errore; appoggiati al
  muro di uno sfasciacarrozze sono roba sua.

### Low Poly Animated Humans e Animated Human — la gente

Otto uomini in quattro vestiti con undici clip, e l'umano di Quaternius con
sei vestiti e sette clip. Scheletri diversi dal nostro, e la lezione della
0.47 era chiara: **non si traduce nessuna clip**. Ogni corpo usa le sue; si
traducono solo i nomi (`set_speed(1.35)` vuol dire `Walk` sul pupo e la clip
di camminata sugli altri). Le texture dell'umano sono generate a strisce di
colore (`_vesti_umano`), e le scarpe si colorano rimappando le UV.

Sei passanti su dieci adesso sono uno dei corpi nuovi, vestito secondo il
mestiere: il guappo e il prete in giacca, il pizzaiolo in camicia, il turista
in pantaloncini. Uno su due della gente ferma, i devoti della processione in
giacca e cravatta, l'operaio, il pescatore. Le donne restano il pupo: i due
pacchetti sono di soli uomini.

---

## 2. La gente in croce

`prova_croce` misura le ossa invece di leggere il codice, e ha trovato la
posa a T dove nessuno guardava:

- **I venti vecchi della scopa**: costruiti con l'animazione spenta e poi
  piegati a mano con i numeri dello scheletro della 0.47 — ossa che quello
  della 0.48 non ha. Non piegava niente, e restavano a braccia aperte,
  affondati nel selciato fino alle ginocchia. Adesso `Sitting_Idle` e
  `Sitting_Talking`.
- **Chi va in motorino**: stessa storia. Adesso la clip `Driving`, col
  bacino misurato sulla clip.
- **L'animatore che partiva dallo stato sbagliato**: chi chiedeva `sit()`
  prima di entrare nell'albero restava in piedi dentro alla sedia.
- **La processione scivolava**: quattordici devoti e quattro portatori in
  posa d'attesa per cinquanta metri. Adesso dicono alle gambe quanto vanno.
- **'E ccosce vanno cu 'e piere**: le gambe andavano alla velocità chiesta,
  non a quella vera, e chi era bloccato contro un muro **camminava sul
  posto**. Adesso l'animatore misura quanto si è spostato il corpo.

---

## 3. I corpi che si attraversano

### Il catasto delle cose

Ogni corpo solido d'arredo si segna in `_ingombri` (centro, raggio, e la
scatola girata vera). Chi mette roba **dopo** chiede prima (`_sta_libero`,
`_scatola_libera`), e `prova_ngombri` fa la stessa domanda a città finita.
Alla prima misura è uscito di tutto: vetrine con la merce **dentro**
all'auto parcheggiata davanti, quattro lampioni dentro a un cofano, un
signore che aspettava dentro a una portiera, l'ultima auto del sagrato mezza
dentro al monumento, un cestino dentro al tronco di un pino, un lampione
dentro al muro della cornetteria, cinque tavolini dentro alle panchine e ai
tavoli della scopa, un pino in mezzo al campetto.

### I trecentotrentotto fantasmi

`_solido` rifiuta i corpi che cadono sulla corsia libera di una strada (la
regola della 0.56). Il controllo prendeva la misura più lunga del corpo e la
stendeva in tutte le direzioni: un'auto lunga 4,3 contava come un disco di
due metri di raggio, e appoggiata al marciapiede «toccava» la corsia. **338
corpi buttati in silenzio** — sessantacinque auto in sosta, ventidue
vetrine, settanta motorini — cioè mezza città che si attraversava come fumo,
compresa la cosa più importante di un gioco sul parcheggio: le macchine
parcheggiate. Adesso conta la sporgenza vera del corpo girato. Scartati:
**zero**.

### I passanti camminavano sotto alla città

Il passante era un `CharacterBody3D` **senza forma di collisione**. Per il
motore fisico non esisteva: non toccava mai terra, e la gravità lo tirava giù
senza fine. Due secondi dopo essere nato camminava sotto alla città —
`prova_ntuppate` ne ha trovati a cinquanta chilometri di profondità. I
«passanti dentro ai muri» erano loro, visti da sotto.

Dargli un corpo ha voluto dire tutto il resto:

- **'A strada** (`cammino.gd`): una griglia A* da un metro con palazzi e cose,
  e la «corda tirata» che salta al punto più lontano che si vede dritto — con
  mezzo corpo di margine, se no la corda strusciava sulle panchine.
- **Chi s'è piantato nun aspetta sei secondi**: una strada nuova al primo
  secondo, un passo fuori al secondo, un'altra meta al terzo.
- **Il passo** (`passo.gd`) conosce adesso anche le cose (`ostacoli.gd`, la
  rassegna di tutti i corpi solidi a città finita), chiede la strada alla
  griglia quando il dritto è chiuso, e conta il tempo **in passi** e non in
  millisecondi. `prova_mure`, che appena le cose in strada sono diventate
  ostacoli era crollata a 118 camminate arrivate su 400, adesso ne porta a
  destinazione **383**.
- **I ragazzini** aspettano invece di spingere quando fra loro e il posto c'è
  un muro, e vanno a riprendersi la palla con le mani quando non la
  raggiungono.

### Le ultime otto, trovate in questi giorni

- **'Nnanze ô purtone nun se mette niente**: i portoni sono pezzi di
  facciata e nessun registro li conosceva. Il divieto di sosta finiva
  piantato in mezzo al portone.
- **'O vascio tagliato a metà**: trecento metri fuori dalla città c'è ancora
  scenografia, e uno dei palazzi finti del golfo stava **in mezzo alla
  stanza di casa** — da dentro si vedeva una parete grigia che tagliava il
  tavolo. Adesso la scenografia chiede al vascio se lo tocca
  (`tocca_a_stanza`), e c'è una prova che riempie la stanza di punti.
- **Sotto 'a scalinata nun se passa**: in cima alle rampe del Vomero la
  lastra sta a due metri e mezzo da terra, gradini e muretti erano solo da
  vedere, e un passante ci finiva sotto. Adesso sotto c'è il pieno.
- **'Na porta chiusa 'a tutt' 'e doje parte**: uscendo da un palazzo si
  poteva finire dentro al muro di confine, e uscendo dal muro rientrare nel
  palazzo. Adesso si provano le altre facce.
- **'A nicchia sta dint'ô muro**: le sette edicole votive stavano **al
  centro degli incroci** — la nicchia sospesa a due metri in mezzo alla
  strada, e sotto una scatola invisibile e solida di un metro e venti nel
  punto dove passano tutti. La griglia dei passanti la vedeva come un muro,
  e il cardine accanto al Vomero, chiuso da lei a nord e dalla scalinata a
  sud, era diventato un'isola. Adesso stanno sul muro dell'isolato d'angolo,
  a un metro dallo spigolo, e non addosso ai portoni.
- **'O Vommero nun se traversa 'a sotto**: per la griglia dei passanti il
  piano del terrapieno era fatto di celle libere ma irraggiungibili, e chi
  strusciava sul muraglione veniva mandato lassù a cercare una strada che
  non c'era. Adesso per chi cammina a terra il Vomero è un isolato.
- **'A tappa ca nun se raggiunge cchiù**: una tappa buona alla nascita può
  finire dietro a un muro quando arriva la rassegna delle cose; invece di
  tirare dritto contro il muro, il passante ne sceglie un'altra. E la tappa
  (169, 162), che stava contro il muro di dietro della galera, si è
  spostata di tre metri e mezzo. **La galera stessa sta dentro alla città
  dalla 0.56**: è la prima cosa da sistemare nella versione dopo.
- **'E vetrine**, la più grossa: vedi sotto.

---

## 4. Le vetrine che guardavano il muro

Nella 0.55 le vetrine attorno alle piazze erano sedici righe scritte a mano.
Poi la città è stata ridisegnata e quelle coordinate sono rimaste dov'erano —
dentro ai vicoli, mezzo metro dentro ai palazzi. Il controllo del punto di
sosta le scartava **tutte e sedici, in silenzio**, e la prova contava solo
che fossero almeno venti in totale: le tenevano su quelle di Via Marina. Che
però erano **girate verso il muro** — la bottega costruita dentro al
palazzo, e l'autista che ci andava a fare la spesa guardando una facciata
vuota.

Questa versione ha aggiunto il controllo che dietro a una bottega ci sia un
palazzo: le undici di Via Marina sono cadute, il conto è sceso a quindici, e
la prova ha fatto il suo mestiere. Adesso i posti **si leggono dalla
pianta** (`_facciate_verso`): i lati degli isolati che guardano la piazza o
la strada, un posto ogni sei metri, e per ogni piazza i quattro più vicini al
centro che passano tutti i controlli. Trenta vetrine, tutte sulla strada.

---

## Le trappole

1. **La prova che difende il bug, due volte in una versione.**
   `prova_commissione` contava le vetrine e non guardava dove stavano;
   `prova_confronto` faceva cercare il giocatore in un corridoio largo
   quaranta centimetri **fuori dalla mappa**, e passava solo perché il passo
   non conosceva il muro di confine. Riscritta al centro del Corso.
2. **«`prova_mira` è a posto»**, scritto nelle note della 0.58. Passava una
   volta sì e una no: la munnezza della piazza si posava guardando anche chi
   cammina, e cambiava con la posizione del vigile al momento della
   costruzione. Adesso guarda solo chi sta fermo.
3. **Una prova senza disegno è cieca ai MultiMesh.** In headless le
   trasformazioni delle istanze non esistono: la prova del vascio passava
   con zero storte anche col palazzo in mezzo alla stanza. Adesso rifiuta di
   girare senza xvfb.
4. **Cambiare `instance_count` di un MultiMesh butta via le trasformazioni.**
   Il golfo andava bene solo perché arrivava sempre a 1800 palazzi tondi.
5. **Un nome costruito non si cerca.** `"sacchetto_%d" % k`: tredici modelli
   in città risultavano «mai usati». Adesso le liste sono scritte per intero.
6. **`shuffle()` usa il caso globale**, non il seme: i cantieri «fissi»
   cambiavano strada a ogni partita.
7. **Coordinate di un nodo lette come coordinate del mondo**, di nuovo (era
   la trappola 7 della 0.56): le ottanta cassette di tutte le vetrine stavano
   in due mucchi accanto all'origine, sul bordo del mare, **da sette
   versioni**. E la collina alzata due volte a chi passava per `_batched`.
8. **Una `.mesh` è una mesh sola**: `find_children` guarda i figli, la radice
   no, e il pezzo non nasceva senza un errore.
9. **Il tempo delle prove non è il tempo del gioco.** Il passo riprovava la
   strada dopo due secondi e mezzo *veri*; `prova_mure` fa tremila passi in
   un fotogramma, e metà delle camminate si piantavano per un difetto della
   misura.
10. **La macchina di lavoro si è azzerata a metà versione.** Il progetto è
    stato rimesso in piedi dal `.pck` della build web della 0.58
    (`tools/recupero/estrai_pck.py`, e `mux_ogg.py` per ricucire l'audio), e
    gli shader — che nel pacco non c'erano — riscritti. Da qui la regola
    nuova delle istruzioni del progetto: **ogni versione si consegna intera**,
    modelli e texture compresi.

## La lezione

**Quello che non ha un corpo non si vede sbagliare.** Le auto in sosta senza
corpo, i passanti senza forma di collisione, le vetrine che nessuno guardava
da vicino, le scene d'angolo in mezzo alla corsia: stavano tutte nel posto
sbagliato da versioni, e nessuna prova le vedeva perché nessuna prova le
toccava. È bastato dare un corpo alle cose — e poi alla gente — perché
venissero fuori una dopo l'altra. La domanda da farsi, d'ora in poi, non è
«dà errore?» ma **«se ci sbatto contro, dove sbatto?»**.
