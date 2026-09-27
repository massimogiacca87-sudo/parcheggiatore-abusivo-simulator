# Novità della v0.65 · 'A scala d''e guaie

27 settembre 2026. Due richieste del capo, dopo la 0.64:

> *«Si è perso l'utilizzo delle mani in prima persona come gesti quando fai
> parcheggiare le auto. Crea di nuovo le animazioni a gesti quando muovi
> un'auto.»*

> *«Giorno dopo giorno, le spese non pagate si accumulano con conseguenze
> disastrose e esilaranti, fino al game over. Ad esempio dopo un po' tua
> moglie potrebbe lasciarti e portarsi via i bambini e tenersi la casa.
> Oppure possono staccarti la corrente a casa. Fino al definitivo game over
> quando non paghi per una settimana. In questo modo si bilancia anche
> l'economia e tutto il fatto delle auto rubate.»*

Nel progetto, accanto al gioco, c'era anche `direttiva_designer.md` (una
revisione di game design scritta da un'altra IA per il capo). Diceva la
stessa cosa con altre parole: *«il conto è un pedaggio, non una minaccia»*.
L'ho letta, e le due cose che ne ho preso sono segnate qui sotto; il resto
resta lì, per decidere insieme.

---

## 1 · 'E mmane d''a regia

### Perché non c'erano più

Fino alla 0.53 la regia a gesti si faceva con due braccia a scatole appese
alla telecamera. Alla 0.54 sono state buttate: il corpo del giocatore è un
modello vero con le braccia sue, e le braccia erano diventate quattro. Era
giusto per il corpo, ma ha lasciato la regia senza niente da vedere: le
braccia vere stanno a mezzo metro di lato, fuori dall'inquadratura
(`prova_braccia` l'aveva misurato), e la meccanica più tua del gioco si
faceva guardando una macchina e leggendo una scritta gialla.

### Com'è adesso

La stessa soluzione del fierro della 0.61 (`arma_fp.gd`): **le mani che vedi
tu non sono quelle del corpo**. Sono un modellino appeso alla telecamera
(`scripts/mani_fp.gd`), **visibile solo mentre dirigi un'auto**. Salgono
quando premi [E] sul cliente e scendono quando la manovra finisce: così le
braccia non tornano a essere quattro, perché queste esistono solo quando
servono.

Ogni mano è fatta a pezzi veri: palmo, quattro dita da due falangi, il
pollice. Un gesto è una **posa della mano**, non una scatola che si sposta.
Uno per tasto, come le grida:

| tasto | gesto |
|---|---|
| niente | «aspetta»: mani su, pronte, che respirano |
| **W** | «vieni, vieni, vieni!»: palme verso di te, le dita che chiamano (le due mani un filo sfasate: in coro sembrava un robot) |
| **S** | «FERMO!»: palme aperte spinte verso la macchina, con un tremito |
| **A / D** | il braccio da quella parte indica col dito; l'altra mano fa il volante |
| **F** | «mettila ccà»: il dito che pianta il punto per terra, due volte |
| la botta | le mani all'aria, aperte, che tremano |
| il park-assist | «piano, piano»: il dorso delle mani che batte l'aria |
| fatto | il pollice su |
| andato via | le palme al cielo, e poi giù |

**Con la paletta** (se l'hai comprata) la mano destra la tiene, e il gesto
lo fa lei: si sventola per chiamare, si pianta davanti per fermare, si
inclina per girare. Mentre le mani sono su, **il fierro scende** (una mazza
in mano e due palme aperte fanno tre mani) e torna appena finisci.

Il turista capisce i gesti al contrario: le mani fanno quello che hai
premuto tu. È lui che sbaglia.

---

## 2 · 'A scala d''e guaie

### Il problema

Fino alla 0.64 non pagare costava poco. Una sera scoperta era una riga rossa
nel riepilogo: la mora col tetto, la luce staccata una volta sola, il
padrone di casa che si prendeva quello che trovava. **Si poteva restare
indietro per sempre.** E i numeri della 0.64 (`prova_dieci_giornate`)
dicevano che un giocatore onesto chiudeva ogni sera con una settantina di
euro in più: se restare indietro non fa paura e la cassa sale sempre, una
berlina rubata da cento euro non è una tentazione, è un passatempo.

### La scala

**Ogni sera che vai a dormire con qualcosa ancora da pagare è un gradino.**
La sera che paghi tutto, si torna a terra.

| sera | cosa succede la mattina dopo |
|---|---|
| 1ª | **'O bigliettino** sul frigorifero, scritto col rossetto: *«'E SSORDE. STASERA. N.»* |
| 2ª | **'A luce staccata**: la casa al buio (la lampadina non si accende), e il riallaccio da pagare |
| 3ª | **'O gas staccato**: pasta cruda col tonno, e finché non paghi il riallaccio (€38) ti svegli a tre quarti delle forze |
| 4ª | **Donna Cuncetta**, 'a mamma 'e Nunzia, si trasferisce «pe' da' 'na mano»: sta seduta sul **tuo** letto, commenta, e ogni mattina ti prende il 12% dalla giacca «p''o lotto» |
| 5ª | **Nunzia si tiene 'a casa e 'e criature**: ha cambiato la serratura. Fuori dalla porta ci sono i cartoni e il biglietto; [E] sulla porta passa i soldi **sotto la porta**, oppure **dormi sui cartoni**. Chi dorme in strada si sveglia al 60% delle forze, e una volta su tre un mariuolo gli leva il 20% |
| 6ª | **L'avvocato Esposito**: separazione con addebito, e la parcella (€90) la paghi tu. E il vigile ha messo «mi piace» alla foto nuova di Nunzia |
| 7ª | **FERNUTA.** La partita finisce |

**Tornare a terra.** La sera che vai a dormire senza debiti, la scala torna
a zero: Nunzia riapre (*«Nun te parla, ma t'ha lassato 'o piatto dint''o
furno»*), Donna Cuncetta se ne torna a Casoria (portandosi il telecomando).
La luce e il gas tornano **solo pagando il riallaccio**, come prima.

**Si vede sempre.** Nell'HUD, sotto a «STASERA CE VONNO», c'è una riga
nuova: *«DEBBITO: 3 juorne 'e 7 — Si nun paghe stasera: vene 'a suocera»*,
che diventa più rossa a ogni gradino. Lo dice anche il biglietto sulla
porta la mattina, il riepilogo della sera, e una pagina nuova del tutoriale
(«LA SCALA DEI GUAI»). Una minaccia che non si vede non minaccia nessuno.

**I carabinieri** (e l'ospedale) quando sei stato cacciato ti lasciano
**fuori dalla porta**, non dentro.

### 'O salumiere nun se scorda

Prima la spesa non pagata spariva la mattina dopo («il pane di ieri non si
ricompra»): era il punto in cui il debito **non** si accumulava. Adesso
diventa **'o cunto d''o salumiere**, metà di quello che era, e si somma sera
dopo sera. È l'accumulo che il capo chiedeva, senza la spirale della 0.43
(metà, e una riga sola).

E ho trovato un guasto vecchio: chi non aveva cenato doveva partire a
mezze forze, ma il controllo guardava la spesa di ieri **dopo** che
`prepara_giornata` l'aveva già tolta. Non scattava mai. Adesso sì.

### L'economia

Le spese fisse salgono di tre decimi (spesa 14-23, luce 52-72, scola 31-49,
fitto 118-152): circa **sessanta euro al giorno** di fisse, settanta con le
disgrazie. Il furto d'auto non l'ho toccato: è la scala che gli ridà il
peso. Chi lavora onesto ce la fa ancora; chi gioca, si fa arrestare o
spreca comincia a salire, e la berlina da cento euro diventa la tentazione
che deve essere.

`prova_economia`, trenta giornate simulate (spese pagate con quello che si
ha):

| incasso al giorno | dopo 30 giorni | sere scoperte |
|---|---|---|
| €55 | €0 in tasca, €3.829 di debiti | 24 (è fernuta ben prima) |
| €75 | €21 | 7, sparse (la scala torna a terra) |
| €95 | €1.041, prima piazza il 12° giorno | 0 |
| €120 | €1.250, prima piazza il 10° giorno | 0 |

Il bot onesto della 0.64 faceva €130 al giorno. **Le giornate giocate col
bilancio nuovo** stanno più sotto (sezione «Le prove»).

### La fine

Al settimo gradino compare **FERNUTA.**: le righe dell'ultima mattina,
quanti giorni hai tenuto duro, le piazze, i soldi, quanto dovevi ancora, e
una riga di finale a caso — *«Nunzia s'è spusata 'o vigile. Chillo ca te
faceva 'e multe»*, il vascio affittato a un turista americano come
«authentic Neapolitan experience», Donna Cuncetta che si prende il tuo posto
in piazza. Due tasti: **Ricumincia da capo** (giorno uno, zero euro, la
famiglia intera: il GameManager si ricorda com'era appena acceso) ed **Esci
d''o gioco** (non nel browser).

---

## Le prove

- **`prova_mani_regia`** (nuova, gioca in città): una macchina vera in coda,
  [E], i tasti veri (`Input.action_press`). Prima della regia niente mani;
  ogni tasto il suo gesto; il fierro sparisce e torna; la botta; [F]. Con
  xvfb fa anche tre foto (`/tmp/regia_*.png`). **0 storte** sia headless sia
  con la finestra.
- **`foto_mani_regia`**: tutti i gesti, con e senza paletta, su un pavimento
  vuoto con una macchina finta davanti (`/tmp/mani_*.png`).
- **`prova_scala_guaie`** (nuova): sette sere senza pagare, un guaio a
  gradino, la schermata FERNUTA; la porta chiusa in città (non si entra, i
  soldi passano sotto, i carabinieri ti lasciano fuori, la notte sui
  cartoni); chi paga torna a terra; il salumiere; «Ricumincia»; e trenta
  giorni a €110 senza mai salire un gradino. **0 storte.** In sette sere
  senza pagare il debito arriva a **€729**.
- **`foto_guaie`** (`CASO=suocera|cacciato|fernuta`): Donna Cuncetta sul
  letto, la porta coi cartoni e il biglietto, l'HUD col debito, la
  schermata finale.
- `prova_economia`: 0 storte (tabella sopra).
- **Le giornate giocate dal bot onesto** (`VELOCE=20 GIORNI=7
  prova_dieci_giornate`): il contenitore si è riavviato due volte e le ha
  interrotte, la seconda alla quinta giornata. Fino a lì: incasso fra €64 e
  €124 al giorno, spese fra €18 e €77, **sempre in pari, €249 in tasca, mai
  un gradino della scala**. Il fitto del sesto giorno non si è visto: da
  rifare lunga alla prossima occasione.
- **La batteria intera** (60 prove, in due metà, ripresa dopo il riavvio):
  **tutte a zero storte**, con le eccezioni di sempre (`prova_braccia`
  stampa `fernuto`, `prova_manella` e `prova_pose` hanno un'ultima riga
  diversa) e `prova_ntuppate`, che una volta ha trovato un rivale fermo per
  undici secondi accanto a una macchina e rifatta è uscita a zero (è una
  prova a dadi, lo dice la roadmap dalla 0.62).
- **Build**: exe per Windows in `Build\` e `PAS-v0.65-Web-itchio.zip` in
  radice.

## Le trappole

1. **Ho sovrascritto un attrezzo che esisteva.** La foto delle mani l'avevo
   chiamata `tools/foto_mani.gd`, e un `foto_mani.gd` c'era già (le foto
   della telecamera della 0.54). Me ne sono accorto da `git status` (una
   **M** dove mi aspettavo un **??**) e l'ho rimesso com'era; la mia si
   chiama `foto_mani_regia.gd`. Prima di creare un file, `ls`.
2. **Il modello `paletta` ha il disco perpendicolare al manico** (misurato:
   16,6 × 29,5 × 16,6 cm, il disco sta nel piano XZ). Sul fianco del corpo
   non si nota; in mano, a trenta centimetri dall'occhio, era un piattino da
   caffè in cima a un bastone. In prima persona la paletta è fatta a pezzi.
3. **Il braccio di sopra passava davanti all'occhio.** Col gomito e la
   spalla disegnati, il tratto gomito→spalla passava a un palmo dalla
   telecamera ed era un tubo azzurro grosso mezzo schermo. Adesso la manica
   va dritta fino a fuori dall'inquadratura.
4. **Con xvfb il tempo del gioco va più piano dell'orologio.** Il disegno in
   software è lento, Godot perde passi di fisica, e in due secondi e mezzo
   veri ne passavano mezzo di gioco: la prova diceva «le mani stanno ancora
   in aria» ed era vero, perché per il gioco non era passato il tempo. Le
   prove con la finestra aspettano **il tempo del gioco** (`_mani._t`), non
   i secondi del timer.
5. **Un controllo fatto dopo la funzione che cancella quello che
   controlla.** Il digiuno (`_senza_spesa()` in `start_shift`) guardava la
   spesa di ieri dopo che `prepara_giornata` l'aveva tolta: da quando è
   stato scritto, non è mai scattato. Ora lo dice `prepara_giornata` stessa
   (`digiuno_stamatina`).
6. **Lo stato iniziale va copiato in profondità.** Per «Ricumincia da capo»
   il GameManager si fotografa alla fine di `_ready`; senza
   `duplicate(true)` la fotografia teneva gli stessi dizionari della
   partita (zaino, armi) e «ricominciare» ti ridava lo zaino pieno.

## La lezione

**Una conseguenza che si può ignorare non è una conseguenza.** Il conto
della sera c'era dalla 0.44 e diceva tutte le cose giuste; ma se non pagare
non porta da nessuna parte, il giocatore impara a non guardarlo. La scala
non aggiunge un sistema: dà a quello che c'era **una direzione e una
fine**. E la fine deve far ridere, se no uno spegne e basta.
