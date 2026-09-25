# v0.50 — Sidici punte

Sedici segnalazioni in una volta. Le racconto per quello che hanno tirato
fuori, non nell'ordine in cui sono arrivate: perché sette su sedici, andando
a guardare, erano **lo stesso tipo di guasto** — codice che sembrava
funzionare e non veniva eseguito, o che veniva eseguito con il segno
sbagliato. Sono i più insidiosi, perché a leggerli sembrano a posto.

---

## 'E ccose ca nun se facevano proprio

### 'E divise nun ce stevano

*"Aggiungi dei cappelli e migliora le divise di vigili e carabinieri perché
non sono molto riconoscibili ora."*

Il berretto c'era. La visiera c'era. Lo stemma, le mostrine, la bandoliera,
la paletta: tutto scritto, tutto giusto. E niente di tutto questo veniva
costruito **da due versioni**, per colpa di una riga:

```gdscript
if parts["legs"].is_empty():
    return   # modello 3D esterno: niente accessori procedurali sopra
```

Il senso era: se il personaggio è un modello comprato, non attaccarci sopra
roba fatta a mano. Ragionamento giusto. Solo che alla 0.48 le gambe hanno
smesso di essere nodi separati — le muove l'AnimationTree — e da allora
`legs` **è sempre vuoto**. Quindi la condizione era sempre vera, e la
funzione usciva sempre lì, alla riga prima del berretto.

Non era che la divisa fosse brutta: **non c'era**. Adesso il controllo è
sulle ossa (un modello esterno non ne ha), e sopra ci sono cose nuove:

- il **casco bianco** del vigile urbano, che è l'unica cosa che si vede da
  in fondo alla piazza — prima ancora della divisa, prima della paletta.
  Blu su blu non si legge; bianco su blu sì;
- le **mostrine sulle spalle** invece che **sui polsi**. `parts["arms"]`
  dalla 0.48 sono le *mani*, e il vigile girava con due gradi d'oro
  attaccati ai polsi. C'è voluto un attacco nuovo (`spalla_l`/`spalla_r`)
  perché ci fosse un posto giusto dove metterle;
- la **banda rossa sulla coscia** dei carabinieri, che è *la* cosa dei
  carabinieri. Stava in `sbirro_3d.gd` come due parallelepipedi appesi
  all'osso del **torace**, un metro più in basso: non seguivano le gambe,
  e camminando restavano ferme in mezzo alle cosce come due bastoni.
  Adesso è geometria dentro al modello, pesata sulle ossa delle gambe
  esattamente come i pantaloni che copre.

### 'E mmane erano dduje mane manche

*"Le mani del giocatore non mi piacciono e sono al contrario di come
dovrebbero stare."*

Due segni sbagliati, indipendenti.

**Le dita.** La tabella mette l'indice a +0,028 dal centro del palmo e il
mignolo a −0,028: cioè l'indice dalla parte del pollice, come è fatta una
mano. Ma quel numero veniva moltiplicato per `mano` (+1 destra, −1
sinistra), mentre il pollice — venti righe più giù — per `dentro`, che è
**l'opposto**. Pollice e indice finivano su lati opposti del palmo, con il
mignolo appiccicato al pollice: due mani sinistre montate al contrario.

**I palmi.** La posa a riposo diceva, nel commento, *"i palmi guardano verso
il corpo"*, e faceva l'opposto. L'asse Z della mano punta verso il polso,
cioè **verso la telecamera**: una rotazione positiva si vede antioraria. Per
portare il palmo (che guarda in giù, −Y) verso il centro del corpo serve
−90° a destra e +90° a sinistra. C'era −0,55 a sinistra e +0,55 a destra:
tutte e due supinavano all'infuori, coi pollici in basso. Che il segno
giusto fosse l'altro lo diceva già il codice del pugno, venti righe più su.

### 'A camminata se scancellava 'a sola

*"Quando i pg camminano non sembrano usare l'animazione di camminata."*

La usavano. La usavano **due volte, contro se stessa**.

Nel `BlendSpace1D` la camminata era messa a due quote — 1,35 e 3,0 — per
tenere il passo puro in tutta la fascia in mezzo. In teoria è una tecnica
giusta. In Godot è un guasto, e sta scritto nella documentazione:

> If `sync` is false, the blended animations' frame are **stopped** when the
> blend value is zero.

Quando il personaggio sta fermo, il secondo nodo `Walk` ha peso zero e **il
suo tempo si congela**. Riparte dopo, da un fotogramma qualunque. Da quel
momento le due copie girano sfasate, e a metà strada fra i due punti il
motore ne fa la media: **gamba avanti mediata con gamba indietro fa gamba
ferma**. Un personaggio rigido che scivola.

Un punto solo per clip, `sync = true`, e le velocità dei passanti scese da
1,5–2,6 a 1,05–1,60 metri al secondo — perché 2,6 m/s sono nove chilometri
all'ora, cioè una corsetta, e nel BlendSpace cadevano a metà fra camminata e
`Jog`: mezzo passo e mezza corsetta, un'andatura che non esiste.

---

## 'E ccose ca nun se putevano chiudere

### 'A scopa

*"Il tavolo ancora non si chiude alla fine della partita o quando premi
esc."*

A fine partita il tabellone dei punti si scrive in una `Label` **dentro alla
stessa colonna** delle tre file di carte. Sette righe di conteggio sono
duecento pixel in più: la colonna cresce, e siccome è centrata cresce da
tutte e due le parti — il bottone "Vabbuo'", che sta in fondo, **esce dal
bordo basso dello schermo**. E l'unica altra via d'uscita era disattivata
dalla prima riga del gestore dei tasti:

```gdscript
if not visible or _finita: return    # ESC muore proprio quando serve
```

Adesso a partita finita le file di carte si nascondono (non servono più a
niente) e resta il tabellone, che ci sta comodo. Ed **ESC chiude sempre**.

E le altre due cose che aveva chiesto:

- **l'ultima presa si vede.** Una striscia sotto al tavolo: chi ha calato,
  la carta calata, la freccia, le carte prese. Entra con mezzo secondo di
  animazione — una presa che appare e basta non si legge, e una presa lenta
  annoia;
- **la presa si sceglie cliccando.** Prima, quando una carta poteva prendere
  in più modi, comparivano dei bottoni di testo — "Sette + Quattro" — e
  dovevi leggere il nome delle carte per capire cosa stavi facendo, con le
  carte vere disegnate venti centimetri più su. Adesso si fa come sul tavolo
  vero: **clicchi la carta in mano, e le carte che puoi prendere si accendono
  di giallo. Clicchi quelle, e le pigli.** Verde quelle già scelte, e la
  presa parte da sola appena combacia.

### 'O tutoriale

*"Si sovrappongono e non si capisce niente."*

**Si sovrapponevano davvero, ed è una riga.** `queue_free()` non cancella:
mette in coda. Il nodo resta nell'albero — e quindi resta disegnato — fino
alla fine del frame. Se nello stesso frame se ne costruisce un altro, per
almeno un disegno ce ne sono **due sovrapposti**: due pagine di testo giallo
su nero, una sopra all'altra. Con il tasto premuto due volte in fretta,
sempre.

E il resto era forma: due colonne di prosa lunga in corpo 14, stampate sopra
a un'illustrazione piena di dettagli, sotto a un velo semitrasparente. Tre
cose che remano contro la lettura tutte insieme.

Adesso: **schermo nero**, una colonna sola, corpo 18, e ogni riga è una
coppia — a sinistra il tasto o la cosa, a destra cosa fa. Chi legge non deve
seguire un discorso: deve poter saltare alla riga che gli serve. Cinque
pagine in **italiano**: il mestiere, chi ti guarda, la città, la casa, i
comandi. Il napoletano sta nel gioco, non nelle istruzioni.

E durante il caricamento si vedono **solo le due locandine**, come chiesto:
il tutorial non è più una tassa d'ingresso, si apre dal menu quando si
vuole.

---

## 'A telecamera e 'a capa

*"La telecamera POV del player è sulla testa del personaggio e se si abbassa
gli si vede in testa."*

Il codice per nascondere il cranio c'era: `_hide_above()`, che gira l'albero
dei nodi e spegne i `MeshInstance3D` che stanno sopra a una certa quota. Su
un corpo fatto di capsule appese ai giunti funzionava. Sul corpo nuovo — che
è **una mesh skinnata unica** — non nasconde niente: la mesh è un nodo solo,
appeso allo scheletro alla quota zero, quindi il controllo `y > 1.44` è
falso e la testa resta accesa. Guardando in giù si vedevano i propri occhi.

La cura sta nel modello: **la testa adesso è un oggetto suo**, come i
capelli e i baffi, e il giocatore se la cancella. Tutto quello che c'è
dentro era già pesato al 100% sull'osso `Head`, quindi staccarla non è
costato niente. E il busto è risalito di quattordici centimetri: il calo
serviva solo a tenere il petto sotto a una telecamera che stava dentro al
collo.

---

## 'O muro ca se passava

*"C'è ancora un muro attraversabile in casa."*

Non c'era. Le quattro pareti sono tutte a posto — l'ho verificato con
`tools/prova_muri_casa.gd`, che tira novanta raggi per ognuna di sei quote e
guarda dove escono: zero fughe. Ma l'ultima riga della prova diceva:

```
soffitto -> NIENTE (si esce 'a coppa)
```

La stanza era **una scatola senza coperchio**. E il conto torna: l'armadio è
alto 2,06 e ha il suo collider, quindi ci si sale sopra; da lì un salto
arriva a quasi tre metri; il muro è alto 2,62. Si scavalca, e ci si ritrova
fuori a guardare la stanza da fuori — che è esattamente la foto che ha
mandato il capo. Adesso il soffitto ferma, e i muri hanno un metro e venti
di collider in più sopra la linea del tetto.

---

## 'E fummette

*"A volte sono enormi, a volte minuscoli, a volte sforano il balloon."*

Tre difetti, una causa: **la misura del fumetto era indovinata, non
misurata.**

```gdscript
var w := clampf(0.30 + t.length() * 0.095, 0.60, 2.26)
```

Quanto è largo dipendeva da **quante lettere ci sono**. Ma le lettere non
sono larghe uguali — `"Mmmm"` occupa il doppio di `"illi"` — e soprattutto
il testo va a capo da solo dove capitano gli **spazi**, non ogni 20,2
caratteri. Da lì tutti e tre i casi: frase corta con parole larghe → il
testo esce dal bianco; frase lunga con parole strette → il bianco è il
doppio del testo; una parola sola lunghissima → una riga contata, tre
disegnate.

Adesso il testo si misura davvero, con lo stesso font e le stesse regole di
andata a capo che userà il `Label3D`. Il fondo si taglia sul rettangolo
esatto, e non può sbagliare perché non sta più stimando niente. Più un bordo
scuro (che è quello che rende un rettangolo bianco un fumetto invece che un
cartello) e un tetto di tre righe.

---

## 'E ccose ca nun servevano a niente

### Rompere 'e mmacchine

*"Distruggere le macchine dei clienti che non pagano deve avere un senso,
perché per ora non ha nessun motivo di esistere come meccanica."*

Il conto era netto: rigare una macchina costava dieci punti di sospetto e
non dava **niente**. Un tasto che si può premere e che non porta da nessuna
parte non è libertà, è un errore di progetto travestito da libertà.

La cosa vera è che il mestiere non si regge sul servizio, si regge sulla
**paura**: uno paga due euro non perché gli hai posteggiato la macchina, ma
perché sa cosa succede a chi non paga. **La macchina rigata è la
pubblicità.**

Quindi c'è **'a nomma**: righi la macchina di uno che ti ha rifiutato i
soldi, e se qualcuno lo vede la voce gira. I clienti dopo discutono di meno
(fino a +22 punti percentuali sulla probabilità che paghino). Ma scende di
34 punti ogni giornata: una brutta reputazione va rinfrescata, e
rinfrescarla vuol dire rischiare di nuovo. Rigare la macchina di uno che
**ha** pagato non è vendetta, è vandalismo, e non porta niente — giustamente.

### 'O furto d'auto

*"Non riesco a fare le quest secondarie di rubare le auto. Cancellala per il
momento."*

Cancellata, e il motivo per cui non si riusciva è strutturale: la macchina
giusta (tipo **e** colore, venti combinazioni) doveva **arrivare da sola**
in piazza mentre avevi il lavoro in mano, e le auto arrivano una ogni
venticinque secondi. Con un lavoro che dura due-tre minuti la probabilità è
bassa; e se passava dovevi anche essere libero, e guidarla fino al garage
senza farti vedere. Un lavoro che dipende dal caso in quel modo non è una
sfida: è un'attesa.

Al posto suo **tre lavori nuovi**, che dipendono solo da quello che fa il
giocatore e che riusano roba già nel gioco:

- **'o cafè** — una consegna a tempo strettissimo. Nessuno ti cerca: l'unico
  nemico è l'orologio, perché un caffè freddo non lo vuole nessuno;
- **'e stemme** — qualcuno ne vuole due, tre o quattro. Gli stemmi si
  staccano dalle macchine da otto versioni e finora servivano solo a essere
  venduti a peso: adesso c'è chi te li ordina, e si portano **al garage**;
- **'a guardia** — resta vicino a una cosa per un minuto senza farti notare.
  È l'unico lavoro del gioco che si vince **stando fermi**, ed è per questo
  che vale la pena averlo: tutto il resto chiede di correre. Il sospetto
  alto non lo fa fallire — **ferma il cronometro**, che è peggio.

### 'O garage

Stava al 68% della lunghezza della piazza, e la scelta era scritta chiara
nel commento: *"è il punto più lontano dal varco d'ingresso"*. Ragionamento
giusto per una macchina rubata da nascondere, sbagliato per un giocatore: è
il posto dove **si consegna**, cioè la fine di ogni lavoro che parte dalla
bacheca. Adesso sta sul filo dalla parte del varco: entri in piazza e ce
l'hai a sinistra.

---

## 'O riesto

- **'E tre musiche vere.** *Steps of the Old Quarter* è la traccia del
  gioco: cammini, posteggi, non succede niente. *Terracotta Blur* parte
  **solo con le stelle** e si ferma quando spariscono — prima la caccia
  partiva col *sospetto*, che è un numero che il giocatore non vede, e si
  spegneva a una soglia più bassa: partiva quando non stava succedendo
  niente e continuava dopo che erano andati via. *Blue Hour Lullaby* dalle
  undici di sera. I sette pezzi a 8 bit restano sulla radiolina.
- **'E pg reagiscono ê cazzotte, senza restà 'nchiuvate.** La clip del colpo
  sta sul livello `OneShot` **sopra** alla locomozione: il busto incassa
  mentre le gambe continuano a scappare. Non è uno stato, quindi non toglie
  un fotogramma di controllo — che è la differenza fra reagire e lo
  stun-lock. Un tempo di ricarica di tre decimi, non per la logica ma per
  l'occhio: una clip riavviata ogni decimo resta ferma sul primo fotogramma.
- **'A multa nun è cchiù sicura: è quaranta ncopp'a cient'.** Prima il conto
  era solo sulla distanza — a tre metri dal vigile, 85% **ogni tre
  secondi**, cioè certezza. Una cosa che succede sempre non è un rischio, è
  una tassa. Adesso la moneta si lancia una volta sola per auto: il 40% è
  multabile, il resto no, e non lo sarà mai. La distanza decide **quando**,
  non **se**.
- **Cchiù panzune.** La pancia si tirava a sorte uniforme e ne usciva un
  panzone ogni tre. Adesso quasi metà della gente è panzuta, e il corpo
  panzone è cresciuto: con i numeri di prima si leggeva come "robusto".
- **'E maioliche attuorno â fontana d''a piazza.** Alla 0.47 erano uscite dal
  pavimento, dove non ci sono mai state. Ma il posto giusto esiste, ed è
  questo: un anello per terra attorno alla vasca e una fascia sul bordo.
  Piccolo, guardato da vicino, fatto apposta perché si guardi. E la pietra
  non è più un grigio piatto: è piperno.
- **'O juorno dint'â UI.** L'orologio diceva che ora era ma non che giorno
  era, e il gioco è tutto costruito sui giorni. *"martedì · juorno 9"*.
- **'A linea 'e vista pe' 'e stemme.** Vedi sotto: è la cosa più grossa che
  è entrata stavolta.

---

## 'O stemma, 'a linea 'e vista e 'o cunfronto

*"I proprietari delle auto hanno linea di vista, non possono reagire se rubi
lo stemma alle loro spalle. Possono però venire a chiederti conto se quando
tornano non trovano più lo stemma, soprattutto se ti hanno pagato. Crea un
sistema di dialoghi per sfuggire da questa situazione."*

Prima `react_to_car_crime()` scattava **sempre**: staccavi lo stemma alle
spalle del padrone, a otto metri, mentre guardava dall'altra parte, e quello
si girava di scatto e ti veniva addosso.

Adesso servono due condizioni insieme: deve essere **girato verso di te**
(cono di 100°, portata 22 metri) e non ci deve stare un muro in mezzo. Se
sei fuori dal cono o dietro a qualcosa, sul momento non succede niente.

Ma la roba manca lo stesso. Quando torna a prendersi la macchina se ne
accorge — e **viene da te**. Non ti mena: ti chiede conto, ed è una cosa
diversa, perché a una domanda si può rispondere. Quattro risposte, che non
sono quattro modi di dire la stessa cosa:

| Risposta | Cosa succede |
|---|---|
| *"L'aggio visto io: 'nu guaglione cu 'o muturino"* | Gli dai un colpevole. Funziona — ma è una bugia che gira, e costa reputazione. |
| *"Tècchete, s'era allentato e t''o tenevo io"* | Glielo ridai. Perdi lo stemma e basta. È l'unica che funziona **sempre**. |
| *"E che ne saccio? Io guardo 'e mmacchine"* | La faccia tosta. Se **ti aveva pagato** non se la beve: gli hai già detto che stavi guardando. Finisce male. |
| *"E chi t''o dice ca stev' ccà?"* | Finisce a mazzate. Sempre. |

---

## 'E prove

- `tools/prova_pose.gd` — 0 clip mancanti su 17, mani diverse fra fermo,
  camminata e corsa.
- `tools/prova_mira.gd` — 24 oggetti, 0 storte (**col garage spostato**).
- `tools/prova_modelli.gd` — 29 modelli d'auto, 0 storte.
- `tools/prova_casa.gd`, `prova_scopa.gd`, `prova_economia.gd` — a posto.
- `tools/prova_muri_casa.gd` — **nuova**: novanta raggi per sei quote dentro
  al vascio. È quella che ha trovato il soffitto aperto.
- `tools/foto_mani.gd`, `tools/foto_ui.gd`, `tools/foto_divise.gd` —
  **nuove**: le mani in prima persona, il pannello della scopa e il
  tutorial, le divise da vicino e da lontano. Sono le prove che hanno
  trovato le due mani sinistre, le pagine sovrapposte e le divise che non
  c'erano.

## Quello ca ancora nun va

- Le facciate restano spoglie: mancano insegne, fili, tende, tapparelle.
- Il Castel dell'Ovo in fondo è ancora un blocco marrone.
- **'E criature so' aduldi piccerille**: un bambino di 1,34 è il corpo
  dell'adulto scalato, e un bambino vero ha la testa molto più grossa in
  proporzione. Ci vuole un quinto corpo, non un moltiplicatore.
- Le mani in prima persona hanno le dita ancora un po' aperte a ventaglio.
