# Riassunto della chat della v0.64

*26-27 settembre 2026 · versione **v0.64 · 'O Rre e 'e Strisce***

## La richiesta

Un messaggio solo, in tre tempi (testo intero in cima a `NOVITA-v0.64.md`):

1. **prima** assicurarsi che la conquista delle altre piazze funzioni, coi
   soldi e coi pugni, e che una piazza presa lavori *esattamente come la
   tua*: entri e cominciano ad arrivare macchine da posteggiare;
2. **poi** due idee della roadmap col suo twist:
   - **'O Rre d''e Parcheggi**: alla terza giornata un figuro inventato da
     zero, con un modello suo, ti sfida (*«ah e tu vulisse fà 'o
     parcheggiatore? E famme verè»*): un minuto, musichetta e tic tac;
     almeno 5 posteggiate → una piazza in omaggio, almeno 3 → un guaglione
     che lavora per te, una sola → ti insegue e ti mena (*«ma arò t'avvie
     omm' 'e sfaccimma, va' a faticà va'»*);
   - **'E Strisce Blu**: certe mattine le strisce blu coi parchimetri nella
     tua piazza o in un'altra tua; i parchimetri (modelli riconoscibili) si
     rompono tutti, e finché non ridipingi di bianco (pittura e pennello
     nuovi al bazar) i clienti non ti pagano o fanno come se li avessi messi
     fuori dalle strisce;
3. **infine** tutto quello che era rimasto in sospeso dalle versioni prima.
   Libertà piena: altre chat, altre istanze, altre IA.

La chat si è riempita due volte ed è ripartita dal riassunto («Continue
from where you left off»).

## Come è andata

1. **Il progetto dal computer**, come alla 0.62 (tre tar in `_claude_tmp`:
   `pA` senza i materiali, `pB1` e `pB2` coi materiali). Novità: prima del
   commit `base` tutti i file di testo portati a **LF**, come li tiene il Git
   del computer: da lì gli alberi del contenitore e del computer hanno lo
   stesso hash (controllo fatto a ogni consegna delle patch).
2. **La conquista, giocata da una prova nuova** (`prova_conquista`): nove
   guasti (vedi `NOVITA-v0.64.md` §1), tutti chiusi, un commit.
3. **'E Strisce Blu** e **'O Rre d''e Parcheggi**, un commit ciascuno, con la
   loro prova (`prova_strisce_blu`, `prova_re_parcheggi`) e le fotografie
   (`foto_sessantaquattro`, `foto_modello`). La musica della sfida, il tic
   tac, la campana e la pennellata sono **sintetizzati a codice**
   (`tools/genera_suoni_064.py`); l'icona della pittura disegnata a codice.
   Non è servita un'altra IA: tutto quello che si vede e si sente della 0.64
   è fatto nel progetto.
4. **Le foto da tutti i lati** del Rre (`tools/foto_modello.gd`, nuovo) hanno
   fatto venire la voglia di fotografare anche gli altri: **Borrelli aveva
   la faccia sulla nuca**, e con lui gli occhiali di chi va in motorino e
   dello Zio; le braccia del vigile al bar, della signora della borsa e di
   Borrelli col telefonino erano sbagliate (`hold_bone`). Nasce
   `animator.punta_osso`.
5. **I rimasti aperti**, uno per commit: sala scommesse col tema, plugin
   spenti, fazzoletto delle signore sedute, balcone del panaro, pozzanghere
   nel browser, vetrine e botteghe della piazza di casa, la prova delle
   dieci giornate.
6. **Un intoppo coi commit.** La prima metà del lavoro (conquista, strisce,
   Rre, facce) l'avevo fatta tutta prima di committare, e i file erano
   gli stessi. Il primo tentativo di spezzarla in commit (pezzi di diff
   senza contesto) ha messo righe nel posto sbagliato: un `emit` dopo il
   salvataggio invece che prima, un punto di coda sparito. Rifatto da capo:
   per ogni commit il file dell'indice costruito togliendo dal file finito i
   pezzi dei commit dopo, e il gioco avviato su quella versione esatta prima
   di committare (zero `SCRIPT ERROR` a ogni passo). Da lì, un commit per
   lavoro, man mano.

## Decisioni

- **La piazza in omaggio del Rre è la prima libera** fra mercato, stadio,
  cornetteria, senza affitto e **senza boss di capitolo** («l'ha sistemata
  lui con chi la teneva»); se le hai già tutte, €450. Il guaglione è Sasà 'o
  Lampo; se ce l'hai già dappertutto, €60.
- **Le botte del Rre non mandano all'ospedale** (si ferma a dodici ossa): è
  un'umiliazione, non una punizione che ti fa perdere la giornata.
- **Due posteggiate** (fra l'una e le tre del capo) = niente, rivincita fra
  tre giorni, come con una sola. Durante la sfida contano solo le macchine
  dentro a un posto (con F non vale).
- **Strisce blu**: una mattina su cinque dal secondo giorno, una piazza
  sola alla volta; il Comune non ripara di notte (lo stato resta nel
  salvataggio). Col parchimetro in piedi il cliente paga la macchinetta,
  senza parchimetro è «fuori dalle strisce» (paga meno e il vigile gli può
  fare la multa). Il guaglione su un posto blu incassa zero col
  parchimetro, una volta su due senza.
- **Il bot delle dieci giornate è onesto**: niente furti, mazzate, gioco,
  acquisti; Borrelli e il Rre spenti. Misura il mestiere di tutti i giorni.
- **I plugin non usati si spengono ma non si cancellano** (autoload di
  Dialogic tolto, `.gdignore` in LimboAI e, alla fine, anche in Dialogic).

## Le verifiche

- **Batteria completa sul codice finale** (in due metà, 56 prove più
  `prova_scopa`): tutte a zero storte e zero `SCRIPT ERROR`, con le solite
  eccezioni che non sono guasti (`prova_braccia` «fernuto», `prova_manella`
  e `prova_pose` senza riga finale).
- **La prima batteria completa era passata tutta.** Poi `prova_re_parcheggi`,
  rifatta da sola per un ritocco (la piazza in omaggio senza boss), ha
  dato 2 storte — e nella batteria passava. Non l'ho lasciata lì: guardata
  secondo per secondo, sotto c'erano quattro guasti veri (la bocca della
  piazza di casa tappata da chi usciva, la macchina sul tetto di un'altra,
  la coda cieca alle macchine messe con F, il guaglione che si prendeva le
  macchine del Rre) e uno della prova (il motorino la mandava
  all'ospedale). Rifacendo `prova_conquista` è uscito il decimo guasto
  della conquista (alla cornetteria tre clienti fermi a due metri e mezzo
  dal punto d'attesa). Tutti chiusi, un commit per cosa; poi
  `prova_re_parcheggi` e `prova_conquista` rifatte più volte a zero, e la
  batteria intera di nuovo.
- **`prova_dieci_giornate`, dieci giornate** (`VELOCE=20`): zero storte;
  €130 d'incasso e €57 di spese al giorno, €706 in tasca alla fine, zero
  multe e zero fermi (la tabella sta in `NOVITA-v0.64.md`).
- **`prova_ntuppate` lunga** (`DURATA_NTUPPATE=600`, dieci minuti): zero
  piantati fra passanti, vigili, bambini, signore, rivali e guagliuni.
- **Le trenta vetrine (più la bottega di casa) fotografate tutte da
  fuori**, dopo aver sistemato l'occhio di `foto_vetrine`.
- **Le build**: exe 183 MB (era 186: Dialogic, adesso nascosto col suo
  `.gdignore`, non entra più), web 95 MB zippato (era 98). Il pacchetto
  dell'exe fatto girare senza finestra (`--main-pack`): zero `SCRIPT
  ERROR`. La build web nel Chromium del contenitore parte senza errori
  (spariti i tre «Error loading extension» di LimboAI) e dopo un minuto
  circa la pagina muore di memoria — come la 0.63 rifatta apposta per
  confronto (73 secondi): è il limite di SwiftShader, non del gioco.
- **Il computer del capo**: 18 commit portati con `git am` (l'albero
  `scripts` di là ha lo stesso hash di qua), l'exe nuovo in `Build\`, lo
  zip web in radice, i documenti in `DOcumentazione\`.

## Rimasto aperto

Vedi `ROADMAP.md`, «Rimasto aperto dalla 0.64»: il Rre e le strisce blu da
giocare a mano per le manopole (quanto tempo, quante macchine, quanto
spesso), i numeri delle dieci giornate da guardare col capo, la domanda
«coi pugni» (a mani nude il rivale non si stende, ed è voluto: se il capo
vuole le mani, è una riga), la traversata a piedi col panaro, il motorino
con le chiavi.
