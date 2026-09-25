# v0.56 — **Chello ca nun jeva**

*Tridece punte, nisciuna riga 'e roadmap. 'A prossima se torna 'n carreggiata.*

---

Questa versione non aggiunge un sistema: ne aggiusta tredici cose. Il capo
l'ha detto chiaro — *«La prossima build sarà dedicata solo alla risoluzione
dei seguenti problemi, seguiremo la roadmap nella build successiva»* — e
'a guida, ca steva scritta ccà, se sposta 'a 0.57.

Ma è la versione in cui ho trovato più guasti veri di quanti me ne fossero
stati segnalati, e quasi tutti sono usciti dallo stesso buco: **cose che
nessuno aveva mai guardato perché non davano errore**. Un punto di sosta
dentro a un muro, una porta di calcio alle coordinate sbagliate, tre righe
dell'interfaccia stampate una sopra all'altra. Il codice girava benissimo.

---

## 1 · 'O sciato

*«Rallenta l'animazione del pugno… aggiungi una barra della stamina… nel
giro di 7-8 pugni sei completamente scarico.»*

**Sette pugni e sî fernuto**, misurati: `prova_sciato` conta i colpi che
escono da un serbatoio pieno e si arrabbia se non sono sette o otto. Poi
torna, e torna **piano**: ventidue secondi per rifare un pugno solo. 'O cafè
ne rimette la metà, 'a nuttata tutto.

Correre consuma, ma poco: una traversata di città costa **1,6 pugni**.

E soprattutto: **'e ffierre accattano 'a possibilità 'e menà**, non solo il
danno.

| arma | costa | danno | sciato a colpo | colpi |
|---|---|---|---|---|
| 'e mmane | — | 2 | 13,5 | 7 |
| **'o cric** (nuovo) | €22 | 4 | 4,5 | 22 |
| 'a mazza | €50 | 7 | 4,8 | 20 |
| 'o curtiello | €120 | 12 | 3,2 | 31 |
| 'o fierro | €450 | 22 | 1,0 | 100 |
| 'o Kalash | €900 | 40 | 1,0 | 100 |

Tre armi da corpo a corpo di tre fasce — €22, €50, €120 — come chiesto, e
la prima costa mezza giornata storta, non una buona.

**E ll'armiere**, che il capo ha chiesto di controllare, **steva 'n miezo â
strada**: a x=142, cioè il centro esatto del vicolo da quattro metri, dentro
alla corsia libera che è un invariante di tutta la città. Spostato a x=143,6,
appoggiato al muro.

## 2 · 'O volume

Due manopole nel menu di pausa — effetti e musica, separate — e si
ricordano: `user://audio.cfg`.

## 3 · 'O borseggio ca va male

Se sbagli la borsa a una vecchietta, quella **strilla e chiamma 'a polizia**:
una stella ricercato, subito.

## 4 · 'O tutoriale ca parla napulitano

Il pannello del tutorial c'è dalla 0.52, e funziona. Il difetto è che si
apre col tasto T, e il tasto T lo preme chi già sa che c'è.

Adesso il mestiere te lo insegna **la strada**, in due modi.

**'E cunziglie 'e chi passa.** Quindici frasi in mezzo alle chiacchiere, e
ognuna esce **solo se serve adesso**:

> *«Guagliò, e va' a piglià 'e sigarette ô tabaccaio: 'nu parcheggiatore
> senza sigarette nun s'è maje visto.»*
> *«Hê visto 'a bacheca sotto ê palazze? Ce stanno 'e lavure.»*

Se ne tieni venti di sigarette, quella frase **non esiste**. È tutta la
differenza fra un tutorial e il rumore: `prova_cunziglie` prende dieci
consigli, costruisce lo stato in cui servono e quello in cui non servono, e
verifica tutte e due le volte. Il primo giorno esce un consiglio quasi una
volta su due; dal quinto una su sette; con i vigili addosso mai.

**E Don Gaetano 'o Prufessore**, appoggiato al muro accanto alla bacheca
nella piazza di casa, con la coppola e la sedia di plastica: **dieci
domande** su come si campa, come non ci si fa arrestare, come si cresce. Gli
altri due parlano quando decidono loro; lui risponde quando vuoi tu.

## 5 · 'O pallone

*«È difficile controllarlo e segnare.»*

Aveva ragione tre volte, e per tre motivi diversi.

**Uno: ogni tocco era 'na cannunata.** Ci camminavi contro piano e partivano
6,2 m/s con 2,4 di alzo: il pallone schizzava in aria e finiva a dieci metri.
Adesso **'o tocco vale quanto ce miette**:

| comme 'o tuocche | forza | s'aiza | quanto vola |
|---|---|---|---|
| fermo | 2,60 | 0,44 | **1 cm** |
| camminanno | 4,60 | 0,78 | 3 cm |
| 'e corsa | 6,60 | 1,12 | 6 cm |
| 'e vvolo | 10,20 | 4,69 | 1,12 m |

Da fermo il pallone **rulla**, e te lo porti appresso.

**Due: 'a linea 'e porta se magnava 'e tire buone.** Il gol era un punto
dentro a una scatola da settanta centimetri. Un pallone a ventidue metri al
secondo fa **trentasette centimetri a fotogramma**: il tiro più bello — quello
forte — poteva saltarla in volo e finire dietro alla rete senza che nessuno
se ne accorgesse. Adesso non si guarda dove sta, si guarda **da dove a dove è
passato**.

**Tre, e chesta è 'a cchiù grossa: 'a porta nun steva addó se vedeva.** Il
pallone e la porta del campetto venivano piantati **alle coordinate locali
della piazza lette come coordinate del mondo**. La piazza sta a (16, 5),
quindi la linea di porta stava diciassette metri più in qua di dove è
disegnata. Non era la fisica: **era 'a mappa**.

E poi la mira, che piega il tiro verso la porta ma **solo se ci stavi già
puntando**: un tiro storto di 15° ne guadagna 7,5; uno storto di 70° non
guadagna niente. Misurato: **38 tiri su 40** dal dischetto.

**'E gol pavano quatto vote 'o juorno.** Dopo il rifacimento si segna quasi
sempre, e a €4 a gol col pallone che torna da solo sul dischetto erano più di
cento euro al minuto — cioè più di una giornata intera di lavoro. Aggiustare
il pallone per farlo tornare difficile sarebbe stato togliere con una mano
quello che il capo ha chiesto con l'altra: **'o banco chiude** dopo quattro.
E i gol dei guaglioni non pagano: vale l'ultimo tocco, come nel calcio vero.

**E mo' 'e guagliune jocano cu 'o pallone overo.** Avevano una sfera con
dentro venti righe di fisica scritta a mano, che passava attraverso muri,
macchine e passanti. Adesso è lo stesso Super Santos del campetto, con una
porta sola di zainetti e il gesso per terra.

## 6 · 'A versione

`v0.56` in basso a destra, piccola. Chi segnala un problema deve poter dire
quale build.

## 7 · 'E machine te stennono sulo 'e faccia

Prima qualunque sfioramento ti buttava a terra. Adesso si guarda **dove** ti
ha preso e **da che parte andava**: di muso, ti stende; di lato o da dietro,
è una strusciata — un danno piccolo, il clacson, e quello che ti urla dietro.

## 8 · 'E mure

*«Molti png attraversano i muri: i bambini che giocano, ma anche i guidatori
quando vanno via.»*

La ragione è una riga sola, ripetuta in nove personaggi:

```gdscript
global_position = global_position.move_toward(meta, VELOCITA * delta)
```

Non è movimento: è **teletrasporto a piccoli passi**. Non passa dal motore
fisico, quindi non c'è niente che possa fermarlo — e infatti non lo fermava
niente. Il `collision_mask` di quei nodi poteva pure essere giusto: non lo
guardava nessuno.

Adesso c'è `scripts/passo.gd`, che fa tre cose: va dritto; se dritto è
occupato **striscia**; e se sei già dentro, **esce dalla faccia più vicina**.
Gli isolati sono già una tabella di rettangoli, e per chi cammina su
rettangoli la geometria **è** la fisica.

Misurato su 400 camminate attraverso la città intera: **0,01% dei passi**
dentro ai muri, contro decine di passi per camminata di prima.

Ma il pezzo che conta l'ha trovato la prova, non io:

- **'O campetto d''e guagliune steva dint'ô palazzo.** Il largo che porta il
  loro nome finisce a x=40; loro stavano a x=41. Un metro fuori — con la
  porta **dentro all'isolato** e i ragazzini che ci correvano dentro tutto il
  giorno. È la cosa che il capo ha visto, e non era un problema di muri: era
  dove li avevo messi.
- **Diciotto vetrine su quarantaquattro tenevano 'o punto 'e sosta dint'ô
  muro**, a due metri di profondità. Cioè **quasi la metà degli autisti**,
  ogni volta che scendeva a fare la spesa, entrava dentro all'isolato e ci
  restava mezzo minuto. Il controllo verificava che il punto non fosse in
  carreggiata e non fosse in un varco. **Mancava quello che conta.**

## 9 · 'O vigile

*«A volte mi passa proprio davanti mentre sto gestendo un'auto e non se ne
fotte proprio… la sera dopo le 20.00 va via, quindi conviene lavorare di
sera.»*

**Te vede fatecà.** Tutto il sospetto del gioco nasceva da **eventi** — il
fischio, lo stemma, la multa stracciata. Ma il mestiere non è un istante: è
**stare lì venti secondi a far manovrare uno con le braccia**, davanti a
tutti. Quello, che è la cosa più vistosa che fai, per il vigile non esisteva.
Adesso il sospetto sale da solo finché ti vede dirigere: **5,2 secondi** per
farti chiamare, 12,5 per il verbale.

**'E stemme.** Rubarne uno sotto il suo naso è flagranza: sospetto al
massimo, e da lì il verbale. E **rivenderli** davanti a lui pesa per quanti
ne passi: uno si racconta, sei sono un mestiere.

**'E vinte smonta.** Saluta, se ne va a casa a piedi, e il sospetto si
sgonfia. Da lì in poi la piazza è tua. È la richiesta che cambia di più il
gioco fra tutte: prima le sedici ore erano tutte uguali, adesso la giornata
ha una forma.

## 10 · Ogne cosa ca s'accatta ha da renne

Dodici oggetti in vendita, e si dividevano in due mucchi: sette rendevano,
cinque no — gilet, occhiali, borsello, sedia, ombrellone servivano a **non
perdere**. E il problema non era che fossero inutili (il borsello che ti
salva mezza giornata è l'oggetto più utile del gioco): è che **'o danno ca
nun hê pigliato nun se vede 'a nisciuna parte**. Una cosa che non si vede,
nel dubbio, non si ricompra.

Adesso ognuno ha anche una faccia visibile, ed è quella che avrebbe in strada:

- **gilet** — sembri uno che ha il diritto di stare lì: +6% che ti paghino
- **occhiali** — non ti si legge in faccia: +8% di mancia
- **borsello** — gli spiccioli non si perdono: +6%
- **ombrellone** — **«t''o metto a ll'ombra»**: +14%
- **sedia** — chi ti vede seduto come un custode ti lascia 'o spicciariello

E l'economia è stata rimisurata di conseguenza. Ogni oggetto si ripaga fra
**1,2 e 6,5 giornate**:

| | costa | rende 'o juorno | se paga 'n |
|---|---|---|---|
| coppola | €12 | €9,9 | 1,2 juorne |
| tavolino | €18 | €15,0 | 1,2 |
| piante | €26 | €17,0 | 1,5 |
| occhiali | €14 | €5,4 | 2,6 |
| ombrellone | €25 | €9,1 | 2,8 |
| luminarie | €60 | €20,7 | 2,9 |
| borsello | €16 | €4,1 | 3,9 |
| gilet | €30 | €7,4 | 4,0 |
| fischietto | €25 | €5,4 | 4,6 |
| sedia | €20 | €4,2 | 4,8 |
| paletta | €45 | €8,2 | 5,5 |
| radio | €22 | €3,4 | 6,5 |

Con una regola sopra a tutte, che la prova controlla: **assettarse ha da
renne meno che fatecà** — €2,10 al minuto contro €4,25. Se no il gioco
migliore diventa non giocare.

## 11 · Dint'â casa 'a via nun parla

`event_started` era **un canale solo** che portava due cose diverse: quello
che succede **a te** (e va detto sempre) e quello che succede **'n miezo â
via** (che dentro casa non ti riguarda). Adesso la strada ha il suo canale, e
dentro casa — e in cella — **sta zitta**.

## 12 · 'A porta e 'a galera

**Se esce sempe 'a fore 'a porta.** Prima si tornava dove stavi quando sei
entrato: ti riportavano a casa i carabinieri, uscivi, e ti ritrovavi
teletrasportato dall'altra parte della città.

E la prova ha trovato subito che il punto d'uscita nuovo stava **'n miezo â
carreggiata** del vicolo, e che la riga che doveva girarti di spalle alla
porta ti girava **con la faccia dentro al muro** — la stessa convenzione che
tiene inguaiato questo progetto da sei versioni: `forward(θ) = (−sinθ, 0,
−cosθ)`, **'o +z sta areto**.

**'A galera.** Ti arrestano e non ti portano più a casa: ti portano dentro,
e **te pigliano tutto** — borsello compreso, che in questura lo aprono.
Cinque secondi di cella, skippabili, e ti svegli domani mattina **fuori dal
portone**, dall'altra parte della città, a piedi e senza una lira. La strada
di ritorno è metà della punizione.

## 13 · 'O tiempo

*«L'orario e lo scorrere del tempo non funzionano ancora bene e si bloccano
se vieni arrestato o se vai a casa.»*

Il blocco ce l'avevo messo io nella 0.51, convinto che fosse una gentilezza.
Non lo è: due orologi che si contano addosso si separano per sempre, e una
manciata di fermi allunga la giornata all'infinito. **'O tiempo nun se ferma
pe' nisciuno.** Se ti arrestano alle nove, alle nove e cinque sono le nove e
cinque — e le tre ore buone che ti sei perso sono la punizione.

---

## 'E trappole

**'A prova ca cuntava 'a cosa sbagliata.** La valvola di sicurezza dei muri
(«dopo N passi contro il muro, passa») nella prima versione contava i passi
in cui la strada dritta era occupata. Ma **girare intorno a un isolato vuol
dire avere la strada dritta occupata per tutto il tempo che ci metti a
girarlo**: venti metri di palazzo a passo d'uomo sono sette secondi in cui il
conto sale senza che ci sia niente che non va. Misurato: **l'11% dei passi**
finiva dentro ai muri, cioè la valvola era diventata il comportamento
normale. Quello che conta non è se sei contro un muro, è **se ti stai
avvicinando**.

**'A sedia sotto a uno ca sta 'n piede.** Don Gaetano l'avevo messo *seduto*
sulla sedia di plastica, che è metà del personaggio. La prima foto ha detto
subito che non andava: il rig di questo gioco sta in piedi, quindi si vedeva
un vecchio ritto in mezzo a un parallelepipedo rosso. La sedia sta accanto a
lui, vuota — che è poi come stanno le sedie di plastica davanti ai bassi.

**Ll'interfaccia stampata una ncopp'a ll'ata.** La barra del fiato nuova ha
spinto la colonna di sinistra di venti pixel, e le tre righe di testo sotto
(stemmi, commissione, sigarette) avevano la `y` scritta a mano: «Commissione
'O Zio…» stampato **dentro** alla barra verde della salute, e la parola
SCIATO sopra al pacchetto di sigarette. Nessuna prova poteva vederlo. L'ha
visto una foto.

**'A prova ca pretenneva 'o bug.** `prova_orologio` verificava che durante
l'arresto **il tempo non si muovesse** — cioè esattamente il difetto che il
capo ha segnalato al punto 13. Una prova scritta per difendere una pezza
difende la pezza, non il gioco.

**'A prova ca stampava trecento errure e passava 'o stesso.**
`prova_confronto` chiamava `cliente_id` su una macchina finta che non ce
l'aveva: trecento righe di `SCRIPT ERROR` e zero storte. È il genere di
rumore che nasconde il prossimo errore vero.

---

## 'A lezione

> **Chello ca nun dà errore nun vò dì ca va bbuono.**

Tutti i guasti grossi di questa versione giravano benissimo. Diciotto punti
di sosta dentro a un muro, una porta di calcio a diciassette metri da dove è
disegnata, un campetto un metro fuori dal largo, tre righe dell'interfaccia
una sopra all'altra, trecento errori ignorati in una prova che diceva zero.
Nessuno di questi ha mai fatto crollare niente: il gioco li eseguiva ogni
fotogramma, tranquillo.

Si sono visti tutti nello stesso pomeriggio, e per la stessa ragione:
**ho aggiunto una regola che li rendeva visibili**. I muri non hanno creato
il problema dei guidatori dentro ai palazzi — ce li avevo mandati io, con un
appuntamento sbagliato. Hanno solo smesso di lasciarglielo fare in silenzio.

Che è poi il contrario della lezione della 0.55 — *quanno 'na cosa nun se
vede, 'o primmo suspetto è 'a prova* — e la completa: il secondo sospetto è
che **non ci sia nessuna prova che guardi quella cosa lì**.

---

## 'E prove

Trentasei suite, tutte a zero storte. Sei nuove in questa versione:

- `prova_mure` — la geometria, 400 camminate attraverso la città, e la
  città vera che cammina per novanta secondi
- `prova_pallone` — il tocco, la mira, la linea di porta e quaranta tiri
- `prova_vigile` — l'orologio, le venti, gli stemmi, la regia
- `prova_cunziglie` — ogni consiglio nello stato in cui serve **e** in
  quello in cui non serve
- `prova_tiempo` e `prova_sciato` (dalla prima metà della versione)

Più le sezioni nuove dentro a quelle che c'erano già: `prova_casa` (il
silenzio dentro casa, la porta), `prova_economia` (il rientro di ogni
oggetto), `prova_fermi` e `prova_orologio` (riscritte sulla regola nuova).
