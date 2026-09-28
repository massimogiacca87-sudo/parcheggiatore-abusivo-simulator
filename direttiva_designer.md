# PIANO STRATEGICO DI CHIUSURA — *Parcheggiatore Abusivo Simulator*
### Revisione Senior Lead Game Design · stato analizzato: **v0.64 · 'O Rre e 'e Strisce** (27 settembre 2026)

**Documenti letti:** `MEMORIA_PROGETTO.md`, `ROADMAP.md` (integrale, incluse «Rimasto aperto dalla 0.61/0.62/0.64», «I boss che verranno e il finale», «Le domande ancora aperte»), `CHANGELOG.md`, `NOVITA-v0.64.md`, `RIASSUNTO-CHAT-v0.64.md`, `BRAINSTORM-direzione.md`, `COME-RIPRENDERE.md`, `LEGGIMI.txt`.

---

## PREMESSA DI DIAGNOSI (leggere prima dei tre punti)

Il progetto è tecnicamente **sanissimo e sottovalutato**: 115 script, ~67.500 righe, 58 prove automatiche a zero storte, 457 modelli con «zero mai usati», una batteria di test che *gioca davvero* il gioco (`prova_conquista`, `prova_dieci_giornate`, `prova_re_parcheggi`). Questo è un livello di igiene che la maggior parte degli studi indie non ha. **Non serve altra tecnologia. Non serve altro contenuto. Non servono altri asset.**

Ma c'è una cosa che va detta con chiarezza, perché è l'unica che separa questo progetto da un prodotto vendibile: **il `BRAINSTORM-direzione.md` del settembre 2026 elencava sei problemi di design (§2.1–2.6). Cinque sono stati risolti benissimo. Uno — il §2.1, "il ciclo non si accumula" — non è mai stato affrontato, ed è il più importante di tutti.**

Verifichiamolo con i vostri stessi numeri, che sono l'oro di questo progetto. `prova_dieci_giornate`:

| | |
|---|---|
| incasso medio/giorno | €130 |
| spese casa medie/giorno | €57 |
| margine netto | ~€73/giorno |
| dopo 10 giornate | €706 in tasca |
| multe in 10 giorni | **0** |
| fermi in 10 giorni | **0** |

Un bot *onesto, ingenuo, che non ruba, non mena, non gioca, non compra niente* attraversa dieci giornate **senza prendere una multa, senza un fermo, e con la cassa che sale sempre**. Il giorno 10 (€88) si gioca esattamente come il giorno 1 (€93). La curva di tensione è **piatta**, e la moglie passa da umore 65 a 94: anche la famiglia, che doveva essere il freno, sale.

Il gioco ha costruito un mondo magnifico attorno a un loop che **non stringe mai**. Tutto quello che segue serve a una cosa sola: far stringere il loop, e poi chiudere.

Aggiungo una seconda osservazione, altrettanto scomoda: **il gioco ha superato la soglia di "troppi sistemi"**. Cinque forme d'azzardo, furto d'auto con guida, borseggio, stemmi, pacchi, commissioni, bacheca, pallone, lotto con smorfia e ritardatarie, scopa con scala di maestri, partite virtuali, slot, tre carte, sei manifesti da collezionare, panaro, turista spierzo, Gennarino 'o Nuovo, Don Gaetano, quattro vicini, sei clienti fissi. Il rischio non è più "manca qualcosa": è che **il giocatore non trovi il gioco dentro al gioco**. La chiusura di questo progetto è un lavoro di **sottrazione e messa a fuoco**, non di addizione.

---

# 1) LE 3 MECCANICHE PRINCIPALI

Da oggi fino alla 1.0, **queste tre meccaniche sono il gioco**. Ogni ora di lavoro va su una di queste tre. Tutto il resto è condimento, e il condimento è già abbondante.

---

## MECCANICA 1 — **'A REGIA D''E MACCHINE** (il core loop momento-per-momento)
### *La cosa che nessun altro gioco al mondo ha, e che oggi è la più sotto-sfruttata del progetto.*

**Cos'è oggi.** Arriva l'auto, premi [E], la dirigi a gesti (`directing_*`), l'autista obbedisce in ritardo e col suo carattere (il turista capisce al contrario, il tirchio, quello di fretta), incassi 3-12 euro. Il `BRAINSTORM` la definiva giustamente «una meccanica vera. Non è "premi E sull'oggetto"».

**Il problema, misurato.** Il quindicesimo cliente della giornata è identico al primo. Non c'è accumulo, non c'è affanno, non c'è respiro. `prova_dieci_giornate` registra 9-18 macchine al giorno e **da 0 a 9 clienti persi**, senza che quella perdita abbia mai un picco drammatico riconoscibile. La piazza non si riempie mai al punto da metterti in crisi, e non si svuota mai al punto da farti tirare il fiato. Confronto onesto: *PowerWash Simulator* ti dà la soddisfazione del completamento, *Papers, Please* ti dà le regole che si accumulano. Voi avete la materia prima per **entrambe**, e non state usando né l'una né l'altra.

**Cosa va fatto — tre interventi, in ordine di ritorno sull'investimento:**

### 1.A — **'A sciummana** (l'ondata): dare una curva alla giornata
Le cinque fasce esistono già (`GameManager`, la tabella delle fasce) e comandano *quante auto arrivano* e *quanto lasciano*. Vanno **esasperate** perché si sentano col corpo, non col foglio di calcolo:

- **Picchi veri**: in ogni giornata devono esserci **due momenti di affanno** (3-4 auto in coda contemporaneamente, tu che corri) e **due momenti morti** (30-40 secondi in cui non arriva nessuno). Oggi la distribuzione è troppo uniforme.
- **Il momento morto è progettato, non è un buco**: è il momento in cui vai a prendere il caffè da Nunzia, controlli il guaglione, sfasci un parchimetro, parli con Don Gaetano. Tutto il contenuto secondario che oggi compete col lavoro deve **abitare le pause**, non rubare tempo al lavoro.
- **Il picco è dove nasce la scelta**: tre auto in coda, il vigile che guarda, uno che ti chiama. Non puoi servirli tutti. **Chi lasci andare?** Quella domanda oggi non viene mai posta, e nel momento in cui viene posta il gioco cambia genere: da simulatore a gioco.

Manopole: la tabella delle fasce e il rubinetto delle macchine (`posteggio_3d`, `zone_vicolo_3d`). Criterio di accettazione: `prova_dieci_giornate` deve registrare, per ogni giornata, **almeno un minuto con ≥3 auto in coda simultanee** e **almeno un minuto con 0 auto**.

### 1.B — **'A mano bona** (la maestria): dare al gesto una scala di qualità
Oggi posteggiare è binario: dentro al posto / fuori dal posto (e la sfida del Rre lo conferma: «contano solo le macchine dentro a un posto»). Deve diventare **graduato**, esattamente come avete già fatto — benissimo — col **centro dorato del minigioco dello scasso** nella 0.57 («non serve a passare, serve a pagare di più: una differenza di bravura che non chiude la porta in faccia a nessuno»). Quella è la lezione di design migliore di tutto il progetto: **applicatela al core loop.**

- **Tre gradi di posteggiata**: *storta* (dentro ma male: paga base, −rispetto), *dritta* (paga piena), ***'a manovra d''o mastro*** (dentro al centimetro, o incastrata in uno spazio che sembrava troppo stretto: **+mancia, +reputazione, e una battuta dell'autista**).
- **'A strinta**: quando la piazza è piena all'80%, il gioco genera **il posto impossibile** — quello dove ci sta una Panda e non una berlina, dove serve la manovra in tre tempi. Vincerla deve essere il momento più bello della giornata, e deve avere un suono, una scritta e la mancia doppia.
- **'A cunzecutiva**: tre posteggiate dritte di fila = **'o mumento buono**, mance ×1,2 finché non ne sbagli una. Costo implementativo: venti righe. Effetto: il quindicesimo cliente smette di essere uguale al primo, perché il quindicesimo è il terzo di una striscia.

### 1.C — **'O feedback**: far sentire il colpo
`colpo_a_segno` con la crocetta sul mirino (0.61) è stata la cosa che ha reso leggibili le armi. **La stessa identica cura va data alla posteggiata**: il clack della portiera, il fumetto dell'autista che dice *«Bravo, guagliò»*, il contatore che scatta, la moneta che entra nel borsello (il modello del borsello in uscita c'è già dalla 0.62), e **la cifra che vola verso il totale della sera**. Ogni euro incassato deve visivamente andare *dentro al conto di stasera* (vedi Meccanica 2). Oggi i soldi entrano in un numero in alto a destra e lì muoiono.

---

## MECCANICA 2 — **'O CUNTO D''A SERA** (la pressione, il *perché*)
### *La struttura che la roadmap ha dichiarato come identità del gioco («'A jurnata») e che oggi non morde più.*

**Cos'è oggi.** Biglietto sulla porta la mattina, quattro voci fisse + disgrazie a sorte la sera, umore della moglie, mora col tetto. Sulla carta è perfetto. Nei fatti, dai numeri della 0.64: spese medie €57 contro €130 d'incasso, **margine positivo tutti i giorni tranne uno su dieci**, zero multe, zero fermi, umore moglie 65 → 94, €706 in cassa al giorno 10.

**La diagnosi è netta: la 0.62 ha tagliato le spese di un sesto per risolvere un problema reale (la 0.61 temeva «spese uguali all'incasso»), e nel farlo ha spento l'unico motore drammatico del gioco.** Adesso il conto è un pedaggio, non una minaccia. E un gioco in cui la cassa sale sempre è un gioco in cui nessuna decisione pesa: se ho €706 in tasca, perché dovrei rischiare una multa per un cliente da tre euro?

**Cosa va fatto — quattro interventi:**

### 2.A — **'A pressione ca cresce**: le spese devono avere un arco
Il conto della sera oggi è **stazionario con rumore casuale** (da €12 a €172, media 57). Deve diventare **crescente con eventi programmati**:

- **Tre scadenze grosse e annunciate** lungo l'arco della partita: la bolletta della luce con lo stacco, il dentista della piccola, l'arretrato d'affitto. Annunciate **tre giorni prima** («giovedì ce sta 'o dentista: 180 euro»), con il contatore visibile nell'HUD.
- **Il margine target deve scendere da €73/giorno a €15-25/giorno** per il giocatore *onesto e diligente*. Non alzando le spese quotidiane (che frustrano), ma mettendo **i tre picchi**. L'onesto puro deve **quasi** farcela: deve sudare, e ogni tanto deve dover scegliere se rubare uno stemma o far saltare la gita della figlia.
- Il salto qualitativo: **oggi il gioco ti chiede di guadagnare. Deve chiederti di arrivare a stasera.**

### 2.B — **'O cunto se vede tutto 'o juorno**
L'intervento singolo col miglior rapporto costo/effetto di tutto questo documento, ed è quasi gratis: **la cifra che manca stasera deve stare nell'HUD, sempre.** Non i soldi che hai: **quelli che ti mancano.**

> `MANCANO: € 41` · e sotto, piccolo: `'a luce`

Il `BRAINSTORM` lo aveva già scritto e nessuno l'ha implementato fino in fondo: «tre euro di mancia diventano *tre euro dei sessantotto*». Con quella riga a schermo, **tutto il gioco esistente cambia di significato senza toccare una meccanica**: la sedia sdraio diventa una scelta, l'ombrellone da €14 diventa un investimento, la multa del vigile diventa una catastrofe, lo stemma diventa disperazione invece che cleptomania. Costo: un `Label` e un aggancio a `money_changed`. Effetto: il gioco che il `BRAINSTORM` prometteva.

### 2.C — **Perdere deve costare** (§2.6 del brainstorm, ancora aperto)
Zero fermi e zero multe in dieci giornate significa che il sistema del vigile — **la cosa meglio riuscita del gioco**, per ammissione del brainstorm e a mio parere pure — **non viene mai interrogato**. Il vigile che ti vede lavorare (0.56), le stelle, i tre fermi (0.52), la galera come isolato vero (0.60): è un impianto magnifico che il bot onesto non ha mai fatto scattare nemmeno una volta.

- Alzare la pressione del vigile fino a che un giocatore normale **prenda una multa ogni due-tre giornate** e **un fermo ogni cinque-sei**. Non di più: deve essere una tassa sull'errore, non una lotteria.
- **La conseguenza deve toccare il conto**: la notte in galera non è solo una giornata persa — è **una sera in cui a casa non porti niente**, e domani mattina il biglietto sulla porta lo dice.

### 2.D — **Rispondere alle domande aperte 5 e 10 della roadmap** (le due che possono rompere il gioco)
Sono le vostre stesse domande, e vanno chiuse **prima** della 1.0 perché riguardano la *strategia dominante*:

- **Domanda 5 — le fasce sono troppo forti?** La nottata paga il doppio, il primo del mese il doppio del doppio. Se la strategia ottimale diventa «dormi fino alle sette e lavora di notte», la fascia si è mangiata la giornata.
- **Domanda 10 — il vigile smonta alle 20.** Dalle 20 in poi: nessun controllo **e** paga doppia. I due vantaggi si moltiplicano.

**La mia risposta, secca:** i due effetti insieme sono quasi certamente rotti. La correzione giusta **non è rimettere il vigile** (distruggerebbe il bellissimo sollievo delle 20, che è un beat narrativo perfetto: *la piazza è tua*). La correzione è dare **alla notte un pericolo suo**, e ce l'avete già in casa: Borrelli (0.63), i boss di capitolo (0.55), e il nuovo **Carro attrezzi** (vedi Meccanica 3). **La notte paga di più perché di notte c'è chi ti prende i soldi, non chi ti fa la multa.** E il cornetto delle ossa solo notturno (0.54) diventa così una ragione in più per essere lì, non un'anomalia.

**Verifica obbligatoria:** far girare `prova_dieci_giornate` con **due bot**, uno diurno e uno notturno. Se il notturno guadagna più del +25%, si tocca la fascia.

---

## MECCANICA 3 — **'A CARRIERA E 'O FINALE** (la ragione per riaccendere il gioco domani)
### *Il §2.3 del brainstorm — «non c'è nessun motivo per cui domani conta» — è l'ultimo problema strutturale aperto, e si chiude qui.*

**Cos'è oggi.** Quattro piazze con carattere distinto (stadio €110 ma due vigili, mercato €56 e nessuno, cornetteria deserta di giorno e ×8,5 di notte, rapporto migliore/peggiore 1,98 — **bilanciamento eccellente, complimenti**), guagliuni che crescono e se ne vanno con la cassa, tre boss di capitolo con tre meccaniche diverse ('O Cardinale vuole soldi, Donna Carmela una quota, Tonino non tratta), Borrelli che non si tocca, 'O Rre d''e Parcheggi. Economia verificata: il mercato (€450) si compra la settima sera, la cornetteria (€1.350) verso la ventesima giornata.

**Il problema.** La progressione c'è ma **non ha un traguardo**. La roadmap ha la sezione «I boss che verranno e il finale» con cinque boss proposti e due finali, tutti ancora allo stato di idea. E la domanda §8 del brainstorm — «**questo gioco finisce?**» — **non ha ancora avuto risposta scritta**. Senza quella risposta non si può chiudere il progetto, perché non si sa cosa sia "chiuso".

**La risposta che raccomando, e che vi chiedo di ratificare oggi: SÌ. Il gioco finisce. Trenta giornate.**

Motivi: 1) trenta giornate da 7'30" = **3 ore e mezza**, che è esattamente la durata giusta per un gioco a €9,99-14,99 con un'idea originale e un'ambientazione forte; 2) è la struttura che il brainstorm indicava come "A", quella che rende **più importante** tutto ciò che avete già costruito; 3) un simulatore senza fine vi obbliga a un motore economico da 50 ore che non avete tempo di bilanciare; 4) **un gioco che finisce si può recensire, si può raccontare, e si può finire di fare.**

**Cosa va fatto — tre interventi:**

### 3.A — **L'arco delle trenta giornate, in tre atti**
Non serve scrivere una trama: serve **ritmare quello che esiste già**.

- **Atto I — giornate 1-8 · *Se campa*.** La piazza di casa, il vigile, il conto. Pressione bassa. Si impara. Culmina con **la prima piazza comprata** (il mercato, settima sera secondo i vostri numeri: perfetto) e **il primo boss di capitolo**.
- **Atto II — giornate 9-20 · *Se cresce*.** Guagliuni, seconda e terza piazza, 'O Rre, 'E Strisce Blu, Borrelli che si fa vivo. Le spese salgono (le tre scadenze grosse). Entra **'O Carro attrezzi** (l'unico boss nuovo che raccomando, vedi 3.B).
- **Atto III — giornate 21-30 · *O tutto o niente*.** Pressione massima: un debito con la persona sbagliata, i rivali che premono. **La Finanza** come evento di penultima sera. E l'ultima notte.

Costo reale: è quasi tutto **ri-orchestrazione di sistemi esistenti** su una timeline. Il `GameManager` ha già il contatore dei giorni, 73 segnali e il salvataggio.

### 3.B — **Un solo boss nuovo: 'O Carro attrezzi**
La roadmap ne propone cinque. **Fatene uno.** La regola della 0.55 («ogni boss è una meccanica diversa») è giusta, ma con cinque boss nuovi non chiudete mai.

**'O Carro attrezzi** è il migliore dei cinque e non è vicino: è una **gara di tempo contro il tuo stesso lavoro**, usa la piazza piena che avete appena imparato a costruire (Meccanica 1.A), e ogni macchina portata via è **un cliente fisso perso per sempre** — cioè colpisce l'unico sistema di memoria a lungo termine che avete (i sei clienti fissi con rapporto da −100 a +100 nel salvataggio). Ti mette davanti a tre risposte tutte cattive: svegli i clienti e gli fai spostare l'auto (tempo), ti metti davanti al carro (sospetto), o guardi. **È il boss che fa male senza toccarti.**

Gli altri quattro: **'A Finanza** diventa un **evento unico di Atto III** (non un boss ricorrente: una sera sola, i soldi da nascondere in casa/dai guagliuni/nel panaro — e usa il quartiere che hai costruito, che è bellissimo come climax). **'O Cugino d''o Sindaco si taglia** (vedi Punto 3). I due già fatti restano.

### 3.C — **I due finali, che sono quasi gratis**
La roadmap li ha già scritti bene, e sono **due epiloghi diversi sullo stesso ultimo giorno**, non due rami di codice:

- **'O garage 'e famiglia** (finale onesto): hai pagato tutto, ti compri un garage in regola. Borrelli viene un'ultima volta e **lo inviti al taglio del nastro**.
- **'O Re d''a città** (finale di potere): quattro piazze, tutti i boss battuti, i guagliuni lavorano e tu non posteggi più. L'ultima riga è la domanda della moglie: ***«E mo'? Ch'è cagnato?»***

**Quella domanda è il vostro finale, ed è ottima. Va protetta.** Il giocatore non deve dichiarare quale finale vuole: lo decide con quello che fa nelle ultime cinque giornate (soldi messi da parte vs. piazze possedute). Costo: un contatore, due schermate di riepilogo e venti righe di napoletano. **È il pezzo di lavoro con il più alto ritorno emotivo di tutto il progetto.**

---

# 2) SUGGERIMENTI PER L'ESPERIENZA

Dodici interventi, in ordine di priorità. **P0 = senza questo non si chiude. P1 = fa la differenza fra "carino" e "bello". P2 = se avanza tempo.**

### **P0-1 · Giocare. Il capo deve giocare trenta giornate di fila, adesso.**
È il primo punto e non è una battuta. La roadmap ripete la frase «**da guardare alla prima partita lunga**» in **nove punti diversi** (domande aperte 4, 5, 7, 8, 10; economia 0.61 e 0.62; il Rre; le strisce blu). Nove decisioni di bilanciamento sono in attesa dello stesso identico dato, e quel dato costa **tre ore e mezza di una persona**. Finché non esiste, ogni altra scelta è congettura. Il bot onesto è un attrezzo splendido ma non sa annoiarsi, non sa dimenticare e non sa scegliere male: **il divertimento non è misurabile a zero storte.**
> Consegna: una tabella di trenta righe compilata a mano, con una colonna sola in più rispetto a `prova_dieci_giornate`: **«mi sono divertito? s/n»**.

### **P0-2 · La riga «MANCANO € XX» nell'HUD.**
Vedi Meccanica 2.B. È il singolo intervento che cambia più cose al minor prezzo di tutto il documento. Fatelo la settimana prossima, prima di qualsiasi altra cosa.

### **P0-3 · Le manopole ferme dalla 0.64, tarate a mano.**
Sono esplicitamente elencate come «Rimasto aperto dalla 0.64» e sono tutte a una riga di distanza dall'essere chiuse:
- `RE_PE_A_PIAZZA` (5) e `RE_DURATA` (60 s) — *in un minuto, a gesti, cinque sono tante?* Il bot le mette di colpo, un umano no. **Sospetto forte che vada abbassata a 4, o `RE_DURATA` a 75 s.** Una sfida in cui si perde sempre non è un boss, è un dazio.
- `STRISCE_BLU_PROB` — una mattina su cinque. Nelle dieci giornate sono uscite **tre volte su nove**: troppe. **Raccomando una su otto**, perché è un evento che *ruba tempo al core loop* e il suo valore è la sorpresa, non la frequenza.
- **«Con i soldi o con i pugni»** — a mani nude il rivale non si stende. La scelta è difendibile ed è ben comunicata (*«Cu 'e mmane?! Va' t'accatta 'nu fierro, guaglio'.»*): **mantenetela**, ma assicuratevi che l'armiere sia raggiungibile e affordabile *prima* che il giocatore voglia la seconda piazza (la mazza è €50, il mercato €450: il rapporto è corretto).

### **P0-4 · La domanda §8: il boss di capitolo deve durare due sere, non una.**
«Se ti prendi una piazza alle tre di notte hai venti minuti, e se sei in mezzo a un'altra cosa la perdi senza averlo nemmeno visto.» Questo non è tensione, è una trappola di scheduling: **perdere un boss senza averlo visto è il peggior tipo di fallimento possibile** perché il giocatore non impara niente. Portate la scadenza a «**la sera dopo**», e mettete un avviso nell'HUD la mattina. È una riga, e salva il contenuto migliore del gioco dall'essere saltato.

### **P1-5 · Le voci (la 0.65 in roadmap): sì, ma mirate.**
Il brainstorm aveva ragione al 100% («il gioco è pieno di gente che parla e nessuno fa un suono»), ma non serve doppiare tutto. **Serve doppiare cinque cose**:
1. l'introduzione parlata (è il primo minuto: decide la recensione);
2. il **saluto dei sei clienti fissi** (è lì che si vede il rapporto: è il vostro sistema di memoria);
3. le **tre frasi di Borrelli** e la **frase d'ingaggio del Rre** (*«Ah, e tu vulisse fà 'o parcheggiatore? E famme verè»* — questa merita un attore);
4. la frase del vigile e **la vostra risposta** (*«Nun è pe' me, è pp''e ccriature»*: il brainstorm la definisce il momento migliore del gioco, e ha ragione — deve essere **detta con la voce**, non letta);
5. **i versi**: «oh!», il fischio, la risata, «guagliò». Costano niente e riempiono tutto.
Tutto il resto resta testo. Un doppiaggio integrale vi costa sei mesi e non aggiunge niente rispetto a questi cinque.

### **P1-6 · Il tappeto sonoro di Napoli.**
Ancora dal brainstorm, e ancora vero: «Napoli è **rumore**». Avete 40 .ogg + 13 .wav + 5 .mp3 e dodici suoni esterni integrati (0.62). Manca lo **strato ambientale continuo e posizionale**: motorini lontani, una voce dal balcone, una serranda, i gabbiani verso Mergellina, il traffico del lungomare. Un buon tappeto fa più di cinquanta modelli. **Attenzione**: deve cambiare con la fascia oraria — il silenzio delle tre di notte è un asset narrativo, non un bug.

### **P1-7 · L'idle in prima persona (mani visibili camminando).**
È già in roadmap 0.65, ed è più importante di quanto sembri: in un gioco in prima persona **le mani sono il corpo del giocatore**. La 0.54 ha giustamente buttato 220 righe di braccia finte; adesso serve la clip vera sullo scheletro. Con `arma_fp.gd` (0.61) avete già dimostrato di saperlo fare bene.

### **P1-8 · Il primo quarto d'ora (onboarding).**
Avete tre porte per insegnare: il pannello ESC (0.52), i quindici consigli contestuali per strada (0.56 — **ottima soluzione**, «ognuno esce solo se serve adesso») e Don Gaetano 'o Prufessore con le dieci domande. È tanto, ed è ben fatto. Manca **la sceneggiatura dei primi quindici minuti**: la prima giornata deve essere *scriptata*, non casuale. Primo cliente facile e generoso, il vigile che passa ma non guarda, il biglietto sulla porta con una cifra bassa ma non zero, e **una posteggiata difficile a fine giornata** che ti fa capire che c'è un mestiere da imparare. Oggi la giornata 1 è una giornata come le altre: con 14 macchine, 5 che non pagano e 7 perse (dai vostri numeri), **il tutorial insegna al giocatore che si perde la metà dei clienti**. Pessimo primo messaggio.

### **P1-9 · La leggibilità della piazza a colpo d'occhio.**
Con l'affanno della Meccanica 1.A il giocatore deve capire in mezzo secondo: quali posti sono liberi, chi aspetta da più tempo, chi sta per perdere la pazienza, dov'è il vigile. Avete già la minimappa con la freccia (0.62) e le strisce blu vi hanno costretti a gestire i tre stati del posto. **Servono tre affordance visive**: posto libero (leggero bagliore a terra quando c'è una coda), pazienza del cliente (una barra sottile sopra l'auto, visibile solo quando scende sotto il 50%), e **il colpo d'occhio sulla coda** (quante auto aspettano, in HUD). Senza questi, l'affanno diventa confusione — e la confusione non è divertente.

### **P1-10 · La sera a casa: renderla un momento, non una tabella.**
Il brainstorm lo chiedeva («il riepilogo della sera riscritto come una cosa che dici a casa invece che una tabella di statistiche») e resta il punto in cui il gioco può diventare **memorabile a costo quasi zero**. Il vascio c'è, Nunzia c'è, le due criature ci sono, l'umore c'è. Serve che la consegna dei soldi sia **una scena**: lei conta, lei dice una frase diversa a seconda della cifra e dell'umore, e le criature dicono una cosa loro. Trenta righe di napoletano e un paio di clip. **È la vostra frase finale (*«E mo'? Ch'è cagnato?»*) provata trenta volte prima del finale.**

### **P2-11 · Il pacchetto e la vetrina commerciale.**
- **La build web è 95 MB zippati e muore di memoria dopo un minuto in SwiftShader.** Avete già diagnosticato che è il limite dell'emulazione, non del gioco — ma **su itch.io la gente gioca dentro al browser**, e un gioco che crasha dopo un minuto è un gioco bocciato. La roadmap propone già la soluzione (§9: «un pacchetto separato con le texture a 288 — costa mezz'ora»). **Fatelo, e fate una demo web da una giornata sola**, non il gioco intero.
- **La demo giusta è la giornata 1 + la giornata 2.** Quindici minuti, si chiude col primo conto della sera non pagato. È il gancio.
- **Il nome, l'ambientazione e la lingua sono il vostro marketing.** Un trailer di 45 secondi con la voce napoletana e il tic tac della sfida del Rre vale più di qualunque screenshot. E la sfida del Rre — corona, mantello, sigaro, tarantella, un minuto — **è il vostro momento da trailer**: mettetela in apertura.
- **Sulla questione Borrelli**: «caricatura satirica» di una persona reale identificabile, e i sei manifesti con «marchi e volti riconoscibili, solo per build private». Prima di qualsiasi distribuzione pubblica, **quei contenuti vanno sostituiti** con equivalenti di fantasia. Non è un parere di design, è igiene: sarebbe idiota bruciare tre anni di lavoro su questo. Il personaggio funziona benissimo anche con un nome inventato — la meccanica ('o duttore che ti riprende col telefonino e non si può toccare) è divertente di suo.

### **P2-12 · Congelare gli asset. Adesso.**
457 modelli, «zero mai usati», 34 texture, 66 suoni, la biblioteca esterna integrata, i coppi ridisegnati, le decalcomanie, le pozzanghere in due versioni. **Il mondo è finito.** Ogni ora spesa a integrare un nuovo modello da oggi in poi è un'ora sottratta alle tre meccaniche. Dichiarate un **asset freeze** e difendetelo: la 0.60 chiudeva già con *«la prossima build la dedicheremo invece a rifinire il gameplay»*, ed è una promessa che va finalmente mantenuta.

---

# 3) ELEMENTI SUPERFLUI DA TAGLIARE

La regola con cui ho fatto questa lista è quella che il vostro stesso brainstorm aveva scritto e che poi non è stata applicata: *«un'attività secondaria deve dare qualcosa che il ciclo principale non dà. Un minigioco che è solo "un altro modo di fare soldi" è contenuto morto.»*

**Nota importante**: "tagliare" quasi mai significa cancellare codice funzionante e testato. Significa **declassare, nascondere, ridurre di frequenza, o smettere di svilupparlo**. Un sistema che esiste e non viene ampliato costa zero; un sistema che compete col core loop costa il gioco.

### ✂ TAGLIO 1 — **L'azzardo: da cinque forme a due.**
Scopa (con motore vero, carte HD, tabellone, scala di maestri), tre carte, lotto (dieci ruote + Nazionale, novanta numeri, smorfia, cinque sorti, quote vere, quadernetto delle ritardatarie), scommesse con partite virtuali simulate (motore separato, novanta minuti in nove secondi, tabellone stile Football Manager), slot. **Cinque.** I ritorni sono tutti sotto il 100% e verificati su centinaia di migliaia di tirate — tecnicamente ineccepibile — ma la vostra stessa domanda §6 lo dice: «cinque modi di perdere soldi in un gioco su un mestiere povero sono tanti».

Peggio: sono **cinque modi di non giocare al gioco**. E costano manutenzione, UI, tutorial, bilanciamento e attenzione del giocatore a ogni versione.

- **TENERE: 'o lotto.** È il più napoletano di tutti, ha la smorfia, ha le ritardatarie (una fallacia progettata *come* fallacia: design sopraffino), e soprattutto ha **'a Signora d''e nummere** con la profezia una volta su venti e l'estrazione tirata la mattina. È *cultura*, non azzardo. E la giocata di oggi si scopre stasera: **si aggancia perfettamente al conto della sera.**
- **TENERE: 'a scopa.** È il rito del bar, ha i cinque vecchi, la scala dei maestri, la «sfida sbloccata». È un luogo, non un minigioco.
- **DECLASSARE a scenografia: 'e tre carte.** Il tavolo resta in strada, i personaggi restano, ma **non è più giocabile dal giocatore**: è una truffa che *vedi fare agli altri* (e magari uno dei tuoi clienti fissi ci perde i soldi e poi non ti paga: ecco che diventa narrazione invece che minigioco).
- **RIMUOVERE dal menu: 'e slot.** Non dà niente che il lotto non dia, non ha carattere, non ha luogo. Le macchine restano come arredo del bar.
- **RIMUOVERE dal menu: 'e partite virtuali/sala scommesse.** So che fa male — è un motore di simulazione calcistica vero, verificato su 20.000 partite, appena rivestito col tema nella 0.64. Ma è **un gioco dentro al gioco che non parla di parcheggiatori**, e il suo contenuto migliore lo avete già estratto altrove e meglio: *«'a partita nun se vede, se sente»* (0.53), coi boati dal bar e il risultato che si costruisce. **Quella è la versione giusta della partita.** Le tre sale restano in città come luoghi, con il boato che esce dalla porta.

> Risparmio: due sistemi da mantenere, due voci di tutorial, due pannelli UI, e — più importante — **due strade che portavano il giocatore via dalla piazza per guadagnare senza lavorare**.

### ✂ TAGLIO 2 — **Tre dei cinque boss proposti.**
La sezione «I boss che verranno» ne propone cinque. Con cinque non chiudete mai.
- **FARE: 'O Carro attrezzi** (l'unico nuovo — vedi Meccanica 3.B).
- **DECLASSARE a evento unico di Atto III: 'A Finanza.** Idea bellissima, ma come boss ricorrente costa un sistema intero (nascondere i soldi in N posti, con stati e salvataggio). Come **singola sera memorabile prima del finale** costa un decimo e rende il doppio.
- **TAGLIARE: 'O Cugino d''o Sindaco.** Si sovrappone ai clienti fissi (rapporto −100/+100, memoria, dialoghi) e al boss di capitolo 'O Cardinale (che vuole soldi). Non porta una meccanica nuova: porta una scelta binaria ripetuta, che dopo tre volte è un pedaggio.
- I due già fatti ('O Rre, 'E Strisce Blu) restano e **vanno tarati**, non estesi.

### ✂ TAGLIO 3 — **Il ramo "guida e veicoli": chiuso qui.**
La roadmap ha ancora aperti: **'e motorini rubabili**, **'e chiavi** (rimandati dalla 0.58 alla 0.59 alla 0.60 alla 0.61, e ancora fermi), e sotto «Più in là»: *«spostare la macchina di un cliente, farsi inseguire in auto, un trasporto vero»*.

**Chiudete il ramo.** Il furto d'auto è già fatto benissimo (minigioco dello scasso col centro dorato, il mondo che non si ferma, il garage a 148 metri, il ricettatore a −32%): è **completo**. I motorini e le chiavi aggiungono una seconda versione della stessa cosa. L'inseguimento in auto è il vestibolo di "GTA 'e Puortece", che il vostro brainstorm ha correttamente identificato come **la trappola** («butta via l'unica cosa che questo gioco ha e nessun altro»).

Un fatto che vale la pena ricordare: il furto d'auto era **scritto, commentato, documentato e irraggiungibile per sei versioni** (`puoi_arrubba()` sempre falso dalla 0.50 alla 0.56) e nessuno se n'era accorto giocando. È la prova sul campo che quel ramo **non è il gioco**.

### ✂ TAGLIO 4 — **Le micro-quest dimenticate.**
- **'O panaro con la traversata a piedi** (Donna Filumena): il balcone bellissimo è stato fatto nella 0.64. **La quest resta com'è.** Non aggiungete la traversata.
- **'O Castel dell'Ovo** («in fondo al golfo è ancora un blocco»): è **scenografia a 300 metri**. Resta un blocco. Nessuno lo guarderà mai da vicino.
- **'O tressette 'o bar**: no. Vedi Taglio 1.
- **I motorini davanti ai bassi** (tolti perché tappavano i vicoli da 4 m): restano tolti. La soluzione proposta («nei vicoli larghi o di sbieco») costa tempo per zero gameplay.
- **I sei manifesti da collezionare**: teneteli, ma **non estendeteli** — e sostituite le immagini con marchi/volti di fantasia (vedi P2-11).

### ✂ TAGLIO 5 — **I tre plugin, e il debito d'ambiente.**
Dialogic e LimboAI sono già stati spenti con `.gdignore` nella 0.64 (e Dialogic pesava 4-5 MB nell'exe e generava una quarantina di errori a ogni esportazione, per **zero** utilizzo). **Cancellateli** — nel Cestino, come da regola del capo. ProtonScatter «vive nell'editor»: se non serve a produrre asset nuovi (e non serve, perché c'è l'asset freeze), via anche quello. Un plugin installato e non usato è debito puro: costa tempo di import, righe di errore e confusione a chiunque riapra il progetto fra sei mesi.

Stessa logica per **Git LFS**: la roadmap si chiede se serva un repo completo. **No.** Il progetto si prende dalla cartella, il metodo funziona da tre versioni, e LFS è mezza giornata di configurazione per un problema che non avete.

### ✂ TAGLIO 6 — **La quinta corporatura per le criature.**
In roadmap 0.65. Mimmo 'o guaglione oggi è «un adulto scalato a 1,32». Nessun giocatore lo noterà mai, e voi avete già dimostrato (0.49) che rifare un corpo da zero è un lavoro di giorni. **Rimandate a dopo la 1.0**, se mai.

### ✂ TAGLIO 7 — **La caccia al bug estetico a rendimento decrescente.**
Questa è la più delicata, e la dico con rispetto perché nasce da una qualità vera. Il progetto ha una cultura del dettaglio straordinaria: la faccia di Borrelli sulla nuca, i coppi di Venezia, le trenta vetrine fotografate una per una, `hold_bone` inseguito per tre versioni, le pozzanghere sotto alla strada. **È questa cura che rende il gioco bello.**

Ma da qui alla 1.0 il criterio deve cambiare: **si aggiusta solo ciò che il giocatore vede mentre gioca.** Borrelli con la faccia sulla nuca era invisibile *perché lo si guarda di corsa, di notte* — ed è stato trovato con una macchina fotografica dedicata. Ha fatto bene a essere corretto (era un mostro), ma **la prossima cosa così va messa in una lista "dopo la 1.0"**. Il tempo residuo va sulla curva della giornata, sul conto della sera e sul finale. Un gioco con un finale e un modello leggermente storto si vende; un gioco perfetto senza finale, no.

---

## RIEPILOGO OPERATIVO — LA STRADA PER LA 1.0

| versione | nome proposto | contenuto | criterio di "fatto" |
|---|---|---|---|
| **subito** | *(nessuna versione)* | **Il capo gioca 30 giornate.** P0-1. | Tabella di 30 righe, colonna «mi sono divertito» |
| **v0.65** | **'A jurnata ca strigne** | Meccanica 1 (ondata, mano bona, feedback) + Meccanica 2 (riga «MANCANO», spese ad arco, vigile che morde) + le manopole ferme dalla 0.64 (P0-3) + boss di capitolo a due sere (P0-4) | `prova_dieci_giornate`: margine €15-25/giorno, ≥1 multa ogni 3 giorni, picchi e vuoti misurati |
| **v0.66** | **'E vvoce** | Le cinque voci mirate (P1-5), il tappeto sonoro (P1-6), l'idle FP (P1-7), la sera a casa come scena (P1-10) | Il primo minuto di gioco fa venire voglia del secondo |
| **v0.67** | **'O Carro e 'a Finanza** | L'arco in tre atti (3.A), 'O Carro attrezzi (3.B), 'A Finanza come sera unica | Trenta giornate con una curva di pressione crescente e leggibile |
| **v0.68** | **«E mo'? Ch'è cagnato?»** | I due finali (3.C), l'onboarding scriptato della giornata 1 (P1-8), la leggibilità della piazza (P1-9) | **Il gioco finisce.** Due epiloghi, entrambi provati |
| **v0.69** | **'A vetrina** | Tagli 1-6 eseguiti, demo web leggera, trailer, sostituzione contenuti a rischio (P2-11), asset freeze (P2-12) | Un pacchetto che si può mandare a un giornalista |
| **v1.0** | **'O Parcheggiatore** | Bilanciamento finale sui dati della partita completa, batteria a zero storte, build Windows + Web | Si spedisce |

---

## L'ULTIMA COSA, CHE È LA PIÙ IMPORTANTE

Avete in mano un gioco che **nessun altro ha fatto e nessun altro farà**: un parcheggiatore abusivo che non è una macchietta e non è un eroe, in napoletano vero, in una Napoli costruita riga per riga, con un vigile a cui **menti invece di sparargli** e una frase — *«Nun è pe' me, è pp''e ccriature»* — che funziona una volta sola perché lui sa che stai mentendo e ti lascia stare lo stesso.

Quella frase vale più di 457 modelli, di 67.500 righe e di 58 prove a zero storte. Il lavoro che resta non è aggiungere: è **togliere tutto quello che sta fra il giocatore e quella frase**, stringere il cappio del conto della sera finché quella frase diventa necessaria, e poi **finire il gioco** — perché una storia che non finisce non la racconta nessuno.

Tre meccaniche. Trenta giornate. Un finale che chiede *«E mo'? Ch'è cagnato?»*

Chiudetelo. È pronto per esserlo.