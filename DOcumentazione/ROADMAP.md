# Roadmap — dove stiamo e dove andiamo

Aggiornata alla **v0.63 · 'O Duttore**, 26 settembre 2026.

*Da questa versione le note e la roadmap sono scritte in italiano. Il
napoletano resta dove si sente giocando: dialoghi, cartelli, scritte a
schermo.*

---

## La direzione, decisa

**Simulatore di carriera, con dentro la struttura di 'A jurnata.**

Non è un compromesso: è la combinazione che tiene. La progressione — le
piazze che si conquistano, i guagliuni che si assumono, i boss che
chiudono i capitoli — è il *cosa fai*. Il conto della sera, la casa, la
famiglia sono il *perché*, e sono anche il freno che impedisce alla
progressione di diventare un foglio di calcolo.

La storia si scrive strada facendo, e verrà fuori dai personaggi che
aggiungiamo: non c'è un copione da rispettare.

---

## Fatto — v0.44 · 'A jurnata

- [x] **'O vascio**: casa navigabile, moglie, due criature, letto
- [x] **'A jurnata**: mezzogiorno → 4:00, e si chiude andando a dormire
- [x] **'O cunto**: quattro voci fisse + disgrazie a sorte, mora col tetto
- [x] **'A moglie**: umore, spese personali se rientri tardi
- [x] **'A scopa**: motore vero, cinque vecchi in scala, scommesse
- [x] **'E cummissiune**: 2-3 al giorno, in giro per la città, sulla mappa
- [x] **Borrelli** boss fisso della prima sera
- [x] **Suoni veri**: 22 registrazioni + il tappeto di voci napoletane

## Fatto — v0.45 · 'A bacheca

- [x] **'A bacheca** in ogni piazza: il primo posto dove uno *va a
      cercarsi* il lavoro invece di aspettare che gli arrivi addosso
- [x] **'E pacche**: consegne sospette, con la barra che sale
- [x] **'E furte su cummissione** + **'o garage**, e la macchina rubata
      **la guidi tu**
- [x] **'E case**: quattro gradini fino al Vommero
- [x] **'E guagliune faticano overamente**, e si tengono il 30%
- [x] **'A chiantina rifatta**, **'e mobile 'e casa**, dodici bug

## Fatto — v0.46 · 'A vetrina

- [x] **Quarantanove modelli nuovi**, misurati in metri veri
- [x] **Ventotto macchine** su quattro fasce di prezzo
- [x] **L'arredo urbano**: cantieri, paletti, transenne, condizionatori
- [x] **Texture fotografiche**: graffiti veri, tetti italiani
- [x] **'O bar**, **l'arco d''o vicolo**, e via i crocifissi in posa a T

## Fatto — v0.47 · 'A rifattura

- [x] **'A scala d''e texture** appoggiata alle coordinate del mondo
- [x] **'E maioliche** dove hanno senso; **'o garage** dentro a un muro
- [x] **'E animazioni**: il punto della camminata stava a 2,6 m/s
- [x] **'E personagge** con misure vere; **'e vetrine** con la merce dietro

## Fatto — v0.48 · 'E pupe

- [x] **'E personagge rifatte ncopp'ô scheletro d''e animazioni**, con le
      quarantatré clip native
- [x] **Assettato ô tavulo d''a scopa nun se scappa cchiù**
- [x] **'E passante cadono e restano 'n terra**
- [x] **'E carabinieri se pigliano**; **'a bacheca vera**; ventinove auto

## Fatto — v0.49 · 'E pupe, mo' overo

- [x] **'O manichino s'è ghiettato**: del file si tengono solo lo
      scheletro e le clip; il corpo si modella da zero
- [x] **2.406 triangoli** invece di 5.859; **quatte corporature**
- [x] **'E vestite so' rrobba, no culore**; pelato e coi baffi davvero
- [x] **Sette guaste misurate** (la scarpa da 40 cm, la spallina, il bacino)
- [x] **Due trappole di collaudo**: `PROCESS_MODE_ALWAYS` e `--import`

## Fatto — v0.50 · Sidici punte

Sedici segnalazioni, e **sette erano lo stesso guasto**: codice che
sembrava funzionare e non veniva eseguito.

- [x] **'E divise** (il `return` che usciva sempre), **'e mmane manche**,
      **'a camminata ca se scancellava**
- [x] **'A scopa se chiude**; **'o tutoriale** rifatto; **'a telecamera POV**
- [x] **'O muro attraversabile 'e casa** era il soffitto
- [x] **'E fummette misurate**; **'a nomma**; **'a linea 'e vista**
- [x] **Tre musiche vere**; **'e pg reagiscono ê cazzotte**; multa al 40%

## Fatto — v0.51 · 'O ritmo d''a jurnata

- [x] **'O tiempo è uno solo.** C'erano due orologi che si contavano
      addosso: bastava un arresto e restavano separati per sempre
- [x] **'E dialoghe cu ll'autiste**, rotti per tre motivi diversi
- [x] **'E ffasce d''a jurnata**: cinque fasce che comandano quante auto
      arrivano e quanto lasciano, e i due numeri vanno in direzione opposta
- [x] **'O fummetto**: `billboard_mode` senza `billboard_keep_scale`
      buttava via la scala — il "sforano il balloon" che la 0.50 non
      aveva preso perché misurava a una distanza sola
- [x] **'O cartiello ca asceva 'a fore ô schermo** (18 messaggi su 79)
- [x] **'O napulitano riletto riga pe' riga**, dodici copioni
- [x] Via `scripts/legacy_2d/`

## Fatto — v0.52 · 'E ghiornate speciale

Cinque punti: due correzioni, una cosa che mancava, due sistemi nuovi
grossi, e la voce di roadmap che portava questo nome.

- [x] **Tre fermi e t'arrestano.** La colluttazione a tasto si vinceva
      sempre, quindi farsi prendere non costava niente e le stelle erano
      decorazione. Adesso i fermi si contano: il secondo avvisa, **il
      terzo non si scioglie**, e la nottata la passi in cella — la
      giornata si chiude da sola, senza la sera. Il conto riparte ogni
      mattina
- [x] **L'autista te cerca 'n piazza e po' se ne va.** Il confronto si
      apriva appena arrivava alla macchina, dovunque stessi tu. Adesso
      c'è uno stato `CERCA`: 32 metri, 28 secondi, e ti parla solo se ti
      arriva a due metri e mezzo. **Nascondersi funziona.** E negare è
      diventato una monetina (50%, 85% se ti aveva pagato)
- [x] **'O tutoriale dint'ô menu ESC.** Le pagine stanno in un posto solo
      (`tutoriale.gd`) e ci si arriva da due porte
- [x] **'O bar 'n ogni piazza** (ce n'era uno in tutta la città, e il
      caffè è quello che abbassa il sospetto), **tre tavoli d''e tre
      carte** e **tre sale scommesse** invece di uno e una
- [x] **'O lotto ncopp'ô tabaccaio**: dieci ruote più la Nazionale,
      novanta numeri **con la smorfia**, cinque sorti, e le quote vere
      (ambo 250, terno 4.500, cinquina sei milioni). L'estrazione è la
      sera: **la giocata di oggi si vede stasera**
- [x] **'E partite virtuale â sala**: tabellone stile Football Manager,
      novanta minuti in nove secondi. Sotto c'è un motore separato che
      gira diecimila volte in una prova, ed è così che ho trovato la
      vincita arrotondata invece che troncata: il banco pagava il 115%
- [x] **'E ghiornate speciale**: partita, pioggia, mercato, processione,
      primo del mese — **una sesta riga della tabella delle fasce**, non
      un sistema nuovo. E **'o biglietto ncopp'â porta**: che giornata è
      si sa la mattina, prima di uscire
- [x] **Quattro prove nuove**, tutte a numeri: `prova_fermi`,
      `prova_giurnate`, `prova_lotto` (120.000 giocate, ritorno 67%),
      `prova_partite` (20.000 partite, ritorno 86-91%)

## Fatto — v0.53 · 'E ghiornate se veneno

- [x] **Borrelli nun tene cchiù 'nu calendario.** Arrivava la prima sera
      per forza, poi ogni due giorni, poi ogni volta che facevi più di
      centodieci euro, e comunque ogni tre: cioè quasi sempre. Un boss che
      arriva perché è martedì non è una conseguenza, è un appuntamento.
      Adesso ha **due porte e le apri tu** — il verbale del vigile e la
      violenza vista — **una volta su cento** ciascuna
- [x] **'A pioggia se vede**: il cielo si chiude (copertura 0,94, sole a
      un terzo e sbiancato, foschia alzata), le gocce si disegnano in una
      cassa di diciotto metri **attorno a chi guarda** invece che sui
      venti ettari di città, e a terra ci sono gli schizzi
- [x] **'E ombrelle** sui passanti, uno su sei senza
- [x] **'O vigile se mette ô cupierto**: con la pioggia prende la pausa
      due volte più spesso, va al bar nove volte su dieci invece di una su
      due, e ci resta due volte e mezza più a lungo. Le multe scendono
      perché **non è lì a guardare**
- [x] **'O mercato**: tredici bancarelle in più, ognuna **col collider**.
      E nessuna dentro alla piazza del giocatore: le prime tre le avevo
      messe sui posti auto, cioè una macchina che non si può posteggiare
- [x] **'A prucessione**: quattordici devoti dietro a una statua con
      l'aureola accesa, che **attraversa** la piazza. Ogni corpo ha il
      collider: mezza piazza chiusa davvero
- [x] **'A partita nun se vede, se sente**: boati dal bar, il risultato
      che si costruisce, e il fischio finale dopo nove fatti
- [x] **Due prove nuove**: `prova_borrelli` (100.000 tirate, 1,00%) e
      `prova_jurnata_vista`

## Fatto — v0.54 · 'E facce d''o quartiere

Tre punti: due segnalazioni sul corpo del giocatore e sulle ossa, e la
voce di roadmap che portava questo nome.

- [x] **'E braccia so' doje, no quatte.** Il corpo del giocatore è un
      modello vero con le sue braccia, e sopra ci stavano due braccia
      finte disegnate a scatole per la prima persona. La riga che
      avrebbe dovuto nascondere quelle del corpo (`arm.visible = false`)
      non nascondeva niente: `_body_arms` sono i `BoneAttachment3D`
      delle mani, e **in una mesh skinnata il braccio non è un nodo**.
      Duecentoventi righe di braccia finte, buttate
- [x] **'E pugne d''o player.** `action("pugno")` non era una chiave
      della tabella delle clip, e `action()` su una chiave che non
      conosce **esce e basta** — nessun errore. Adesso partono
      `Punch_Cross` e `Punch_Jab` alternati sui colpi, e `Sword_Attack`
      col coltello in mano
- [x] **Ll'ossa nun se rimetteno 'a sole.** Via la rigenerazione
      automatica: c'è **'o cornetto black and white**, cinque euro, alla
      cornetteria, **solo di notte**, sessanta ossa su settantadue. Una
      scazzottata non costa più trenta secondi di attesa — costa cinque
      euro e una traversata di città a un'ora precisa
- [x] **'E clienti fisse.** Sei persone con un nome, e **una macchina su
      tre** ne porta una: stessa macchina e stesso colore sempre, che è
      come le riconosci dal fondo della piazza. Il rapporto va da −100 a
      +100 e **sta dentro al salvataggio** — la piazza si costruisce fra
      le giornate, non dentro. Si vede in una cosa sola, ed è quella
      giusta: **parlano loro per primi** quando scendono, e da come ti
      salutano capisci come sei messo. Misurato: un amico rende **1,5
      volte** uno qualunque, e la prova vieta che renda più del doppio
- [x] **'O vicinato.** Quattro persone che non passano: **stanno**,
      sempre allo stesso angolo. E come diceva la roadmap **non danno
      soldi, danno informazione** — Nunzia dice dove sta il vigile (con
      la rosa dei venti), Totore quanto ti stanno cercando, Mimmo il
      lavoretto aperto che paga di più, Rosa cala 'a frittata (26 ossa,
      una volta al giorno, meno del cornetto apposta). Chiedono un
      piacere da uno a tre euro; all'amico gratis
- [x] **'E mestiere d''e passante.** Nove passanti tutti uguali sono uno
      stampato nove volte: prima la differenza erano tre sorteggi
      (camicia, pancia, calvo). Adesso ognuno ha un mestiere che decide
      **come è vestito, cosa porta in mano, quanto va veloce e quanto si
      ferma** — le ultime due sono le più importanti e le meno vistose.
      Su nove persone in vista se ne vedono **5,4 diverse**, misurato su
      mille piazze
- [x] **'O quadernetto d''e ritardatarie** al banco del tabaccaio: i
      numeri che non escono da un pezzo, per ruota. Che sia una
      **fallacia** è tutto il punto, e resta una fallacia — la prova
      verifica su 40.000 estrazioni che giocare le ritardatarie non
      faccia vincere di più. Serve a rendere la giocata una scelta
      invece di un dado
- [x] **'O padrone 'e casa**: lasciato stare, come chiesto
- [x] **Tre difetti d''e ossa, tutte 'a stessa famiglia.** `hold_bone`
      scrive dopo l'AnimationTree, quindi **congela** l'osso vicino alla
      posa di riposo del rig (in foto: la cassetta degli attrezzi appesa
      dietro alla spalla e il braccio disteso di lato — la stessa cosa
      che in questa versione mi aveva fatto scartare le braccia in prima
      persona, rifatta il giorno dopo). Sotto la mano è **+Y** e non −Y:
      la busta della spesa saliva all'altezza della spalla **da sempre**.
      E sull'osso della testa il davanti è **+Z**: il vigile gira la
      piazza con la visiera sulla nuca **dalla 0.51**, e non si era mai
      notato perché lo vedi quasi sempre di spalle. Trovati tutti e tre
      insieme smettendo di indovinare e scrivendo `prova_manella`, che
      stampa dove punta ogni asse di ogni osso
- [x] **Tre prove nuove** — `prova_gente`, `prova_vicinato`,
      `prova_mestiere` — più la sezione ritardatarie in `prova_lotto`.
      È `prova_gente` ad aver trovato che con il danno a −30 **una
      rigata sola** rendeva nemica Donna Assunta (memoria ×2): un
      rapporto che finisce con un gesto non è un rapporto, è un
      interruttore

## Fatto — v0.55 · 'E piazze e 'e guagliune

- [x] **'E clienti mo' vanno a fà 'e commissiune.** C'era un **anello nel
      grafo degli stati**: la macchina richiamava l'autista per il danno,
      lui faceva la scenata, il contatore tornava a mezzo secondo — e il
      danno stava ancora lì. All'infinito, con un cliente perso a ogni
      giro. E di autisti ce n'erano **due** per macchina: uno che spariva
      all'uscita e uno che nasceva dal nulla per tornare incazzato.
      Adesso è **uno solo** e campa quanto la sosta: scende, va a un
      negozio, torna, e o monta o (solo se trova multa/stemma/riga) ti
      cerca. Una sola uscita di scena, e il giro è chiuso per costruzione
- [x] **Quarantaquattro vetrine so' addeventate mete vere**, sedici nuove
      attorno alle quattro piazze. Nove avevano il punto d'attesa **in
      mezzo alla carreggiata** e alcune stavano sugli incroci: adesso il
      punto si cerca scalando, e chi non trova posto non si costruisce
- [x] **'A Signora d''e nummere.** Via le notizie del vicinato — erano
      utili ma non memorabili, e per giunta dicevano cose che il giocatore
      poteva vedere da solo girando l'angolo. Al posto loro una che ti dà
      cinque numeri e **una volta su venti** sono quelli veri di stasera.
      Per farlo, l'estrazione si tira adesso **la mattina**: una profezia
      ha bisogno di un futuro già scritto
- [x] **'E nummere finte nun se mettono cchiù 'n ordine.** Era la riga che
      si mangiava tutta la meccanica: l'estrazione vera esce disordinata,
      quindi ordinati voleva dire *finti*. Un giocatore ci mette tre
      giornate a capirlo e da lì in poi sa sempre se è la volta buona
- [x] **'O vicinato fa, nun dice**: il caffè di Nunzia (sospetto giù), il
      portone di Totore (quaranta secondi in cui nessuno ti vede e le
      stelle si sciolgono), la frittata di Rosa, e Mimmo che sa dove sta
      oggi 'a Signora
- [x] **Quatte piazze cu 'o carattere.** Lo stadio rende €110 al giorno ma
      ha **due vigili**; il mercato €56 e **nessuno**; la cornetteria è un
      deserto di giorno e rende **8,5 volte** di notte. La migliore rende
      1,98 volte la peggiore: diverse, ma nessuna è la risposta giusta. E
      chi te la vende te lo dice **prima** che paghi
- [x] **'E guagliune crescono e se ne vanno.** L'esperienza matura in due
      settimane: +22% di resa e la quota che scende dal 30% al 21% (su
      cento euro te ne restano 63 il primo giorno e 87 dopo). L'umore sale
      quando passi a ritirare e scende ogni sera che lo lasci con i soldi
      in mano: **sotto dieci se ne va da un rivale, e si porta la cassa**
- [x] **'A voce ca gira**: il ponte fra i sei clienti fissi e la piazza.
      Erano sei rapporti chiusi in sé; adesso la media di come ti tratta
      chi ti conosce tocca **tutti** — tutti amici è +14% sul pagamento e
      mance ×1,16, tutti nemici −28% e ×0,68
- [x] **'E boss 'e capitolo.** Non tre Borrelli con tre facce: appena ti
      prendi una piazza, **quella sera, in quella piazza** ti aspetta chi
      la proteggeva. 'O Cardinale vuole €260; Donna Carmela vuole il 30%
      del mercato per tre giorni; Tonino 'e Notte non tratta. Se non ci
      vai entro la nottata **se la riprende**, col tuo guaglione dentro
- [x] **'E tre cose piccole rimaste**: 'o selciato luceca (i materiali del
      terreno erano quindici oggetti condivisi, non novecento), 'o mercato
      se sente (le bancarelle gridano i prezzi, col volume che scende con
      la distanza), e 'e vicine se ne vanno a durmì — resta solo Totore,
      che è il guardiano e la notte è il suo turno
- [x] **'A pioggia nun schiara cchiù 'a notte.** Trovato di rimbalzo
      guardando due fotogrammi accanto: il filtro della 0.53 alzava
      l'ambiente del 22% a tutte le ore, e alle nove di sera sotto l'acqua
      sembrava mezzogiorno nuvoloso
- [x] **Sei prove nuove**: `prova_commissione`, `prova_signora` (100.000
      tirate), `prova_piazze`, `prova_guagliune`, `prova_boss`,
      `prova_bagnato`

## Fatto — v0.56 · Chello ca nun jeva

Tredici punti, nessuna riga di roadmap: il capo ha chiesto una versione di
sola manutenzione, e **'a guida s'è spustata â 0.57**. È anche la versione
in cui sono usciti più guasti di quanti ne fossero stati segnalati, e quasi
tutti dalla stessa famiglia — **cose che non davano errore**.

- [x] **'O sciato.** Sette pugni e sei scarico, misurati; torna in
      ventidue secondi a pugno, metà col caffè, tutto con la nottata.
      Correre costa poco (una traversata di città = 1,6 pugni). E le armi
      **comprano la possibilità di menare**, non solo il danno: tre da
      corpo a corpo di tre fasce (**'o cric €22** nuovo, mazza €50,
      curtiello €120) più le due da fuoco. **Ll'armiere steva 'n miezo â
      strada** — x=142, il centro esatto del vicolo da quattro metri,
      dentro all'invariante della corsia libera: spostato al muro
- [x] **'E manopole d''o volume**, effetti e musica separate, e si
      ricordano in `user://audio.cfg`
- [x] **'O borseggio ca va male**: la vecchietta strilla e chiama la
      polizia — una stella ricercato
- [x] **'O tutoriale ca parla napulitano.** Il pannello (tasto T) c'è
      dalla 0.52 e lo preme chi già sa che c'è. Adesso il mestiere te lo
      insegna la strada: **quindici consigli** in mezzo alle chiacchiere,
      e ognuno esce **solo se serve adesso** (se tieni venti sigarette,
      «accattate 'e sigarette» non esiste). Più **Don Gaetano 'o
      Prufessore**, accanto alla bacheca, con dieci domande: gli altri
      parlano quando decidono loro, lui risponde quando vuoi tu
- [x] **'O pallone**, rotto in tre modi diversi. Ogni tocco era una
      cannonata (6,2 m/s e 2,4 di alzo per una sfiorata): adesso **'o
      tocco vale quanto ce miette** e da fermo il pallone rulla. La linea
      di porta era un punto dentro a una scatola da 70 cm, e un pallone a
      22 m/s fa **37 cm a fotogramma**: il tiro più bello era il più
      facile da perdere. E soprattutto **'a porta nun steva addó se
      vedeva** — pallone e linea piantati alle coordinate *locali* della
      piazza lette come coordinate del mondo, diciassette metri più in
      qua. Non era la fisica, era 'a mappa. Con la mira che aiuta solo
      chi ha mirato: **38 tiri su 40** dal dischetto, e **'o banco chiude
      dopo quattro gol al giorno**, se no erano cento euro al minuto. E
      **'e guagliune mo' jocano cu 'o pallone overo**, quello del
      campetto, invece di una sfera con venti righe di fisica a mano
- [x] **'A versione 'n basso a destra**, piccola
- [x] **'E machine te stennono sulo 'e faccia**: conta dove ti prendono e
      da che parte vanno; di lato o da dietro è una strusciata
- [x] **'E mure.** Nove personaggi si spostavano con
      `global_position.move_toward()`, che non è movimento ma
      **teletrasporto a piccoli passi**: non passa dal motore fisico,
      quindi niente poteva fermarlo. Adesso c'è `scripts/passo.gd` —
      dritto, striscia, esci — e gli isolati erano già una tabella di
      rettangoli. Misurato: **0,01% dei passi** dentro ai muri. Ma i due
      guasti veri li ha trovati la prova: **'o campetto d''e guagliune
      steva 'nu metro fore d''o largo**, con la porta dentro all'isolato,
      e **diciotto vetrine su quarantaquattro tenevano 'o punto 'e sosta
      dint'ô muro** — cioè quasi metà degli autisti entrava dentro
      all'isolato a fare la spesa. È esattamente quello che il capo aveva
      visto
- [x] **'O vigile.** Tutto il sospetto nasceva da **eventi**, mai da
      durate: e il mestiere è stare venti secondi a far manovrare uno
      davanti a tutti. Adesso **te vede fatecà** (5,2 s per farti
      chiamare, 12,5 per il verbale); rubare uno stemma sotto il suo naso
      è flagranza e **rivenderlo** pesa per quanti ne passi; e **'e vinte
      smonta e se ne va 'a casa**, il sospetto si sgonfia e la piazza è
      tua. È la richiesta che cambia di più la forma della giornata
- [x] **Ogne cosa ca s'accatta ha da renne.** Cinque oggetti su dodici
      servivano solo a **non perdere**, e il danno che non prendi non si
      vede da nessuna parte. Adesso ognuno ha anche la faccia che avrebbe
      in strada: gilet +6% che ti paghino, occhiali +8% di mancia,
      borsello +6%, **ombrellone +14% («t''o metto a ll'ombra»)**, sedia
      'o spicciariello. Economia rimisurata: **ogni oggetto si ripaga fra
      1,2 e 6,5 giornate**, e assettarse rende la metà di fatecà
- [x] **Dint'â casa 'a via nun parla.** `event_started` era un canale
      solo per due cose diverse: quello che succede **a te** e quello che
      succede **'n miezo â via**. Adesso la strada ha il suo, e dentro
      casa (e in cella) sta zitta
- [x] **'A porta e 'a galera.** Si esce sempre **fuori dalla porta di
      casa**, non dove stavi quando sei entrato. E chi ti arresta non ti
      riporta più a casa: **te porta dinto e te piglia tutto**, borsello
      compreso. Cinque secondi di cella skippabili, e ti svegli domani
      mattina fuori dal portone, dall'altra parte della città, a piedi
- [x] **'O tiempo nun se ferma pe' nisciuno.** Il blocco durante l'arresto
      ce l'avevo messo io nella 0.51 credendo di fare una gentilezza: due
      orologi che si contano addosso si separano per sempre, e una
      manciata di fermi allunga la giornata all'infinito
- [x] **Sei prove nuove** — `prova_mure`, `prova_pallone`, `prova_vigile`,
      `prova_cunziglie`, `prova_tiempo`, `prova_sciato` — più le sezioni
      nuove in `prova_casa` (il silenzio, la porta) e `prova_economia` (il
      rientro di ogni oggetto). E **due prove riscritte perché
      difendevano il bug**: `prova_orologio` pretendeva che il tempo si
      fermasse durante l'arresto, e `prova_confronto` stampava trecento
      `SCRIPT ERROR` dichiarando zero storte


## Fatto — v0.56b · 'O mouse ncopp'ô browser

Una correzione sola, dopo che la 0.56 è finita su itch.io.

- [x] **Ncopp'ô browser 'o mouse nun se muveva.** Per girare la testa serve
      il **Pointer Lock**, e i browser lo concedono **soltanto dentro a un
      gesto dell'utente**: la richiesta stava dentro a `player_fps._ready()`,
      cioè mentre la scena si costruisce, e veniva rifiutata **in silenzio**
      — nessun errore, niente in console. Su Windows funzionava, perché lì è
      una chiamata di sistema e basta. Adesso il modo del mouse passa da una
      **porta sola** (`GameManager.piglia_o_mouse`), che tiene il desiderio
      separato dalla concessione; la prima presa sta dentro al click di
      «Accummenciamo»; **'o click 'o ripiglia** ogni volta che Esc lo fa
      perdere; e una riga a schermo lo dice a chi gioca — ma solo quando
      serve, quindi su Windows mai
- [x] **E s'è pruvato ô browser overo.** Headless non ha un Pointer Lock da
      concedere, quindi nessuna prova GDScript poteva dire «su itch.io il
      mouse funziona». C'è un progettino Godot di quattro righe
      (`tools/web/`) che fa le due cose che faceva il gioco, aperto con
      Chromium vero: `doppo _ready(): mouse_mode = 0` · `doppo 'o click:
      mouse_mode = 2`. **'O bug e 'a cura, uno sotto a ll'ato.** Più
      `tools/prova_mouse.gd`, che tiene in piedi la porta: se domani
      qualcuno rimette un `Input.set_mouse_mode` in giro, se ne accorge

## Fatto — v0.57 · La guida

Quattro cose chieste in una frase sola, e una scoperta che non era
nell'elenco: **il furto d'auto era scritto, commentato, documentato, e non
si poteva fare da sei versioni.**

- [x] **Tutti gli asset in strada.** Prima di toccare la guida, il conto:
      `tools/prova_asset.gd` incrocia le cartelle dei modelli, dei suoni e
      delle texture col codice del gioco — non con `tools/`, che è dove i
      modelli nascono e dove il nome compare comunque. Ne erano rimasti
      fuori sei: **il lampione** (4,65 m, con la luce appesa dove sta
      davvero la lampada), **i delimitatori** stradali, **i New Jersey** in
      fila da tre nei cantieri, **le barriere lunghe**, **le giare** accanto
      ai vasi dei portoni, e **le sciarpe della squadra** stese ai balconi —
      fitte attorno allo stadio (una su tre), rade altrove (una su
      venticinque). Conto finale: **90 modelli, 66 suoni, 34 texture, zero
      mai usati**
- [x] **Il garage se n'è andato dall'altra parte della città.** Ce n'era uno
      per piazza, a venti metri da dove lavori: comodo, e per questo inutile
      — un furto che si chiude prima che qualcuno se ne accorga non è un
      furto, è un bottone. Adesso è **uno solo**, a **centoquarantotto
      metri** dalla piazza di casa, sul corso sotto lo stadio. Il posto non
      è scelto a occhio: è il più lontano fra quelli fuori da tutte e
      quattro le piazze, fuori dagli isolati, e **a tre metri da una strada
      larga** — perché una saracinesca in fondo a un vicolo da quattro metri
      con la macchina non la imbocchi, e il gioco nuovo sarebbe morto lì
      senza dare un solo errore
- [x] **Il minigioco dello scasso.** Una barra, un cursore che va avanti e
      indietro, una finestra verde: premi e il cursore si ferma. Tre-sei
      spille secondo la macchina, due errori e la serratura si blocca. Tre
      aggiunte lo rendono un gioco e non un dado — **il centro dorato** (non
      serve a passare, serve a pagare di più: una differenza di bravura che
      non chiude la porta in faccia a nessuno), **le tacche rosse** (se ci
      fermi sopra hai finito, e da sole tolgono la possibilità di aspettare
      il giro comodo) e **i sei secondi a spillo**. La difficoltà viene dal
      mezzo: 3→6 spille, 0→2 tacche, **€130 → €490**, e il tempo utile che
      scende da 316 a 142 ms
- [x] **Il mondo non si ferma mentre scassi.** Va contro a tutti gli altri
      pannelli del gioco, e apposta: se il mondo si fermasse, il vigile si
      fermerebbe con lui, e la tensione del furto sarebbe finta. Fermo resta
      solo il giocatore. Il vigile che ti guarda fa fallire il colpo dopo
      **1,2 secondi**, con la riga rossa che avvisa in tempo per mollare
- [x] **Il grimaldello, €55 dal Zio.** Il primo attrezzo del banchetto che
      non serve a farsi pagare meglio dai clienti ma all'altro mestiere:
      finestra +20%, cursore −10%. Si ripaga con la prima macchina
- [x] **La guida.** Da 8,5 m/s a **14, e 19,5 con lo Shift**; Ctrl è il
      freno a mano; **lo sterzo si chiude con la velocità** (unico pezzo di
      fisica di tutta la guida, e serve a far costare qualcosa l'andare
      forte); le botte rallentano, si sentono e **tolgono dal prezzo**; la
      testa sta al posto di guida e non dentro al motore. Il conto: la
      traversata fino al garage sono **18 secondi a piedi in linea d'aria
      contro 8 in macchina**. È un mezzo, non una camminata seduti
- [x] **Il cruscotto**: velocità, metri che mancano, e la freccia verso il
      garage — che **si fa trovare da solo** nel gruppo `garage`, quindi se
      domani lo spostiamo ancora la freccia continua a puntarlo. Una mappa
      no: se apri la mappa mentre guidi dentro a un vicolo, sei già dentro a
      un muro
- [x] **La consegna, e il freno che tiene in piedi il gioco.** Una berlina
      vale €220 e una giornata intera di posteggio ne fa ottanta: se il
      garage pagasse sempre €220, dalla 0.57 in poi nessuno posteggerebbe
      più niente e il gioco cambierebbe mestiere senza che nessuno l'abbia
      deciso. Quindi **−32% a ogni macchina della stessa giornata** (220 ·
      150 · 102 · 69 · 55), **−11% a botta**, **+6% per ogni spillo preso in
      pieno centro**. E se la macchina era di un cliente andato a fare la
      spesa, quello torna, non la trova e **ti viene a cercare urlando**:
      −4 di reputazione
- [x] **Il cancello che non si apriva mai — e che ho richiuso io mentre lo
      aprivo.** `puoi_arrubba()` chiedeva un lavoro della bacheca di tipo
      "furto", e quei lavori **sono stati tolti alla 0.50**: dalla 0.50 alla
      0.56 la funzione tornava **sempre falso**. Poi l'ho riaperto con
      «posteggiata **e** padrone sparito» — che **non succede mai**, perché
      `l_autista_ha_fernuto()` azzera l'autista e la riga dopo manda via la
      macchina. Ho ricreato lo stesso identico bug sei versioni dopo, mentre
      stavo aggiustando quello. La finestra vera il gioco ce l'aveva da otto
      versioni: **quando il padrone se ne va a fare la spesa** — una persona
      che si allontana e che tu vedi allontanarsi
- [x] **Due prove nuove.** `prova_furto` in sette sezioni, e la settima è
      quella che alla 0.50 mancava: **la prova della verità** — centocinquanta
      secondi di piazza vera, orologio a tripla velocità, a contare quante
      macchine si possono davvero rubare (**3 posteggiate, 3 rubabili,
      finestra più lunga 140 s**). È anche la prova che ha bocciato la mia
      prima tabella della difficoltà, misurando che sul macchinone il cursore
      restava dentro alla finestra **68 millisecondi**, cioè quattro
      fotogrammi: non abilità, una monetina. Più `foto_furto`, quattro
      fotografie — ed è una fotografia, non un numero, ad aver trovato che il
      controllo del vigile sbatteva la porta in faccia nel fotogramma dopo
      l'apertura

## Fatto — v0.58 · 'A robba

Il capo ha dato un pacchetto di modelli PSX da 405 MB e ha chiesto di
usarne «50-100 o anche più» per arricchire il gioco, senza sostituire
niente di quello che aveva già dato. Ne sono entrati **116**, e non hanno
preso il posto dei suoi modelli: hanno preso il posto **delle scatole che
avevo fatto io**.

- [x] **'O pacchetto nun sta 'n metre.** `prova_psx` ha misurato tutti e
      centoventuno i modelli entrati e ne ha bocciati **quaranta**. I
      fattori di correzione però si assomigliavano tutti, e il conto su
      trentatré modelli di misura indiscutibile (una sigaretta è 8,4 cm,
      una carta di credito 8,56, un mattone 25) ha dato **mediana 1,52×,
      28 su 33 dentro al ±25%**: il pacchetto è disegnato una volta e mezza
      più grande del vero. **Ma solo la roba da tasca** — fusto 1,08,
      distributore 2,00, manganello 0,64 sono giusti così, e un fattore
      globale avrebbe rimpicciolito il distributore automatico a un metro e
      trenta. Ventuno `root_scale` scritti nei file di importazione, uno per
      modello, calcolati dalla misura. Secondo giro: **zero fuori misura**
- [x] **'E ffierre songo fierre.** Il banco dell'armiere aveva cinque armi
      di scatole; adesso il coltello è un coltello e la pistola è una
      pistola. **'O kalash resta 'e scatole**, apposta: nel pacchetto un
      fucile d'assalto non c'è, ed è l'arma più cara del gioco. E il banco
      si è vestito — cartucce, munizioni, caricatore, silenziatore,
      cacciavite, grimaldello, chiodi, sega, sciabola
- [x] **'O fierro se vede 'n mano.** Dalla 0.56 si comprano cinque armi,
      cambiano danno, fiato e animazione del pugno — e in mano non si
      vedeva niente. Adesso tre su cinque si vedono, cric compreso (un
      gomito di tubo, ch'è proprio 'a forma 'e 'nu ferro 'a rote)
- [x] **'O vicolo nun è cchiù pulito.** Era quattro lampioni, un
      cassonetto, due Vespe e poi asfalto per cinquantaquattro metri. Per
      piazza adesso: **19 pezzi pesanti** col corpo solido, **30 leggeri**
      per terra, **18 appesi ai muri**, un distributore automatico, e la
      merce fuori dai negozi su due casse — una serranda su tre
- [x] **'O vascio addó abita quaccheduno.** Aveva i mobili e non aveva le
      cose sopra ai mobili. Ventitré pezzi: piatto e posate sul tavolo,
      sveglia e cornice sul comò, tappeto, lampadario, ventilatore
- [x] **'O vigile porta 'o blocchetto, 'a penna e 'a ricetrasmittente** —
      i tre attrezzi con cui dalla 0.56 ti fa il verbale e chiama la
      pattuglia, e che addosso a lui non si vedevano
- [x] **`prova_mira` è passata 'a 0 storte a 4, e chesta è 'a cosa 'e
      chiù importante.** Mirando al guaglione, in tutte e quattro le
      piazze, il gioco agganciava tutt'altro: un fusto col suo corpo
      solido, piantato fra te e lui, per il controllo anti-persiana di
      `_bersaglio_vicino()` **è un muro**. Non era un difetto del
      controllo — era il controllo che funziona; il difetto era mio, che
      avevo sparso trentanove oggetti solidi senza chiedere chi ci stava
      già. Adesso prima di piantare qualcosa **si chiede alla scena**: 2,6
      m di rispetto da tutto quello che si può agganciare, 3,2 dai posti
      auto, e chi non trova posto in quattordici tiri non si costruisce.
      La munnezza si costruisce un fotogramma dopo la piazza, perché
      mentre `_build_props()` gira metà di quella gente non esiste ancora
- [x] **Quatte trappole truvate 'a 'na fotografia e no 'a 'nu numero**: le
      casse nuove che coprivano tutto il bancone (il modello vero è il
      doppio della scatola che sostituiva), gli assi del bancone scritti a
      memoria al contrario, **due ventilatori compenetrati** al soffitto
      del vascio, e «la merce dietro al vetro» quando queste vetrine sono
      **serrande di lamiera** e un vetro non ce l'hanno. Più l'armiere che
      stava **in posa a T** da chissà quando, e che nessuno aveva mai
      fotografato da davanti
- [x] **'E posizione d''e mobile songo addeventate costante** (`TAVULA`,
      `COMO`, `TIVU`): scritte una volta sola, così il piatto si appoggia
      al tavolo e non a un numero che mi ricordavo
- [x] **Cinche modelle so' asciute doppo essere trasute** — siringa,
      maschera, lingotti, tastierino, calamita. Li avevo presi perché
      c'erano; sparpagliarli a forza per Napoli per far quadrare il conto
      di `prova_asset` sarebbe stato peggio che non prenderli
- [x] **Due prove nove**: `prova_psx` (misura e stampa il fattore di scala
      da applicare) e `foto_psx` (quattro scatti, ogni soggetto si fa
      trovare nella scena). Conto finale: **206 modelli, 66 suoni, 34
      texture, zero mai usati**

---

## Fatto — v0.59 · Ogne cosa ô posto sujo

Il capo ha portato quattro pacchetti (Car Pack, Low Poly Assets di
Pandazole, Low Poly Animated Men, l'Animated Human di Quaternius) e ha
chiesto di usarli tutti, senza sovrapporli a quello che c'era, e già che
c'ero di togliere le collisioni rotte e le pose a T. Le tre cose sono venute
fuori legate: appena le cose hanno avuto un corpo, la gente ci ha sbattuto
contro; appena la gente ha avuto un corpo, si è visto dove camminava.

- [x] **Tutti e quattro i pacchetti dentro**: 178 pezzi di Pandazole su 178
      in città (mercato pieno, merce fuori dalle botteghe, munnezza, quadri
      elettrici, cartelli, cantieri con l'operaio, verde, tetti, balconi,
      bar, vascio, scogli e pescatore a Mergellina), un materiale solo e
      l'atlante desaturato; le macchine del Car Pack (gazzella, taxi, berlina
      dei vigili, dodici modelli in sosta); due scheletri nuovi di persone
      accanto al pupo. **399 modelli, zero mai usati**
- [x] **Nessuno in croce** (`prova_croce`): i vecchi della scopa e chi va in
      motorino erano piegati a mano su ossa che non esistono più; ora clip
      vere. Le gambe vanno alla velocità misurata, la processione cammina
- [x] **Il catasto delle cose** (`_ingombri`, `prova_ngombri`): niente sta
      più dentro a niente. **338 corpi solidi buttati in silenzio → 0**
      (`in_corsia_girato`)
- [x] **I passanti camminavano sotto alla città** (nessuna forma di
      collisione): ora hanno un corpo, una strada A* (`cammino.gd`) e un
      recupero in tre tempi. `prova_ntuppate`: nessuno piantato
- [x] **Il passo conosce le cose** (`ostacoli.gd`), chiede la strada alla
      griglia e conta il tempo in passi: `prova_mure` 383–386 su 400
- [x] **Le vetrine lette dalla pianta**: le 16 delle piazze erano scartate
      dalla 0.56 e le 11 di Via Marina guardavano il muro. Ora 30, tutte
      sulla strada; il mercato ha un negozio a 9 metri
- [x] **Portoni liberi, vascio senza palazzi finti in mezzo, scalinata del
      Vomero piena sotto, uscita dai palazzi da un'altra faccia, edicole
      votive sul muro invece che sospese in mezzo agli incroci**
- [x] **Consegna intera**: il progetto completo con gli asset, gli script
      di prova in `tools/sh/`, gli attrezzi di recupero in `tools/recupero/`,
      e i documenti per ripartire (`COME-RIPRENDERE.md`,
      `RIASSUNTO-CHAT-v0.59.md`)
- [x] **Prove nuove**: `prova_arredo`, `prova_croce`, `prova_ngombri`,
      `prova_ntuppate`, `prova_quote`, `prova_conti`,
      `prova_vascio_fondale` (con xvfb), `foto_nove`, `foto_vascio`, sonde

---

## Fatto — v0.60 · 'A città vestuta

Il capo ha chiesto un secondo giro su quello che la 0.59 aveva lasciato
aperto (galera, posa dell'umano, ragazzini piantati, ringhiere), e poi:
*«integra più asset nuovi che puoi, rendi in generale il mondo di gioco più
dettagliato possibile. La prossima build la dedicheremo invece a rifinire il
gameplay.»*

- [x] **'A galera dint'â pianta**: era un blocco messo a mano sopra a due
      isolati e tre strade dalla 0.56. Ora è un isolato suo
      (`ISOLATO_GALERA`, angolo di sud-est del Vomero), con finestrelle a
      sbarre, portone di ferro, cancello carraio, filo spinato e garitta;
      `GALERA_FORE` (144, 3, 156)
- [x] **L'umano fermo**: l'`Idle` di Quaternius era una guardia da pugile.
      Clip nuova `Fermo` costruita col suo scheletro (camminata ferma a
      0,567 s + il movimento dell'`Idle`)
- [x] **'E guagliune**: si fermano e tirano quando sono a tiro, raccolgono la
      palla incastrata, rimettono in gioco quella uscita dal campo.
      `prova_ntuppate` non confonde più chi va e torna con chi è piantato
- [x] **'E ringhiere a quadrette**: i gruppi sparsi tagliati in quadretti di
      32 m, con la scatola al posto del ferro battuto oltre i 45 m.
      Triangoli dentro al raggio di vista **da 3,85–3,93 M a 1,14–2,23 M**
- [x] **Chi nun se vedeva cchiù**: i gruppi con un raggio di vista lo
      misuravano dal baricentro; le tazzulelle dei bar erano invisibili
      dalla 0.59. Ora anche loro a quadrette
- [x] **58 modelli PSX nuovi** (116 → 172 del pacchetto; **457 modelli**,
      zero mai usati): i bassi con porta, grata e vasi (35), le sedie fuori
      con le signore sedute, materassi in piedi, divani e televisori
      buttati, bagno chimico blu nei cantieri, mattoni, saracinesche
      dell'acqua, cartoni e lattine, cicche, mutande fra i panni,
      plafoniere sui portoni, bocche di lupo, due bancarelle di libri usati;
      e dentro a bar, tre carte, scopa, sala scommesse, sfasciacarrozze,
      armiere e vascio. Il grosso in `scripts/robba_psx.gd`
- [x] **'E tetti**: la texture delle falde era un collage aereo di Venezia;
      ora coppi disegnati (`tools/genera_coppi.py`). Tetti piani senza più
      strisce (z-fighting della guaina)
- [x] **Prove e attrezzi**: `foto_sessanta`, `foto_umano_fermo`,
      `sonda_sessanta`, `sonda_largo`, `sonda_guagliune`; `prova_psx` con le
      misure dei modelli nuovi, `prova_conti` che conta anche quello che sta
      dentro al raggio di vista, `prova_ntuppate` con `DURATA_NTUPPATE`;
      `provac.sh` fa girare `prova_vascio_fondale` con xvfb;
      `tools/esame_psx/` è il banco per guardare, misurare e orientare i
      modelli PSX, con la tabella dei nomi (`NOMI-v0.60.md`)

---

## Cose piccole rimaste dalla 0.60

- Guardare in fotografia le trenta vetrine della 0.59 (le prove dicono che
  non toccano niente, ma nessuno le ha ancora viste tutte).
- Il negozio più vicino alla **tua** piazza sta a 37 m: capire perché le
  facciate oltre il Decumano non passano (`sonda_vetrine`).
- Le **tre signore sedute** davanti ai bassi sono pupi femmina con i
  capelli grigi e corti: da lontano sembrano vecchi. Un fazzoletto in
  testa o i capelli raccolti le farebbe leggere subito.

---

## Fatto — v0.62 · 'A faccia nova

Nove richieste del capo dopo una partita (UI, stemma col G, scopa, vigile,
salto e arrampicata, lotto, commissioni, economia, animazioni). Racconto
completo in `NOVITA-v0.62.md`. Da questa versione si lavora su **Git, in una
cartella sola** (vedi `COME-RIPRENDERE.md`).

- [x] **Tema unico** (`assets/ui/tema.tres` da `tools/genera_tema.gd`,
      `ui_stile.gd`): Poppins + DejaVu, pannelli scuri col bordo oro,
      icone e suoni UI (Nathan Gibson, CC BY 4.0 → `CREDITI.txt`).
- [x] **Riga dei comandi** (`riga_comandi.gd`) alzata sopra alla pila in
      basso, tastini veri, due righe se serve; **HUD a schede**;
      **minimappa** (`minimappa.gd`) con freccia sull'obiettivo; pausa e
      pannelli rifatti e fotografati (`foto_hud`, `foto_pannelli`).
- [x] **Stemma con G** (G contestuale: stemma se c'è, se no cambia arma).
- [x] **Scopa**: carte HD (`carte_hd.py`), tabellone, scala dei maestri,
      «SFIDA SBLOCCATA».
- [x] **Vigile**: nasce in `configura()`, giro con arrivo a 60 cm e
      scavalco dei punti irraggiungibili.
- [x] **Salto e arrampicata** fino a 2,2 m, sbroglio da incastrato,
      capsule delle auto all'altezza vera (`prova_ncastro`).
- [x] **Lotto**: insegne, `[2]` al tabaccaio e al bar, pannello nuovo con
      istruzioni, vincite, probabilità vere e smorfia; esito nel
      riepilogo.
- [x] **Commissioni con committente** (`committente_3d.gd`) e roba vera
      (`robba_cummissione.gd`), in mano in prima persona; otto tipi, la
      torta fragile.
- [x] **Economia**: auto 60/100/135/170, calo 0,5, spese −1/6.
- [x] **Animazioni**: 28 clip del pupo tradotte su omini e umani
      (`tools/retarget_ual.gd` → `omo_ual.res`, `umano_q_ual.res`); la
      parlata che finisce (`parla_per`).
- [x] **La biblioteca esterna dentro al gioco** (seconda metà, 26
      settembre; `ASSET-ESTERNI.md` dice cosa c'era, `NOVITA-v0.62.md` cosa
      è entrato e perché il resto no):
      - asfalto PBR sulle strade larghe e muffa alla Sanità
        (`Tex.PBR`, shader `intonaco` con normale e ruvidezza vere);
      - decalcomanie (`robba_esterna.gd`): 154 tombini, rattoppi, macchie
        d'olio nei posti auto, gomme, colature sotto agli split, umido,
        graffiti a tag;
      - lo split rifatto a codice (il modello era un palazzo in miniatura:
        70 file nel Cestino);
      - arredo: Vespe e scooter al cordolo, sedie di Vienna con la
        cassetta, coni, bidoni di ferro, casse, sedie d'ufficio;
      - dodici suoni (`tools/prepara_esterni.py`), varianti automatiche in
        `SoundManager`, motorino in 3D;
      - filtri dello schermo nel menu di pausa e la botta
        (`filtri_schermo.gd`); pozzanghere con la pioggia, solo Forward+
        (`pozzanghere.gd`);
      - sei corpi Quaternius (`Human.QUAT`, `quat_ual.res`) nei mestieri dei
        passanti e nei cantieri;
      - soldi in uscita col borsello; pagina dei crediti nel tutoriale;
      - il vigile che non trema davanti al banco del bar.

### Rimasto aperto dalla 0.62

- **La prova che gioca dieci giornate da sola** resta da scrivere (era già
  nella lista della 0.61).
- **L'economia nuova va giocata**: sulla carta una giornata onesta lascia
  una ventina d'euro e una berlina ne vale cento. Alla prima partita lunga
  guardare se il furto torna a mangiarsi il posteggio (la manopola è
  `VENNUTA_CALO`).
- **`prova_guagliune_vere` al mercato è al limite**: ogni tanto il
  guaglione fa 2 clienti in quattro minuti contro una soglia di 3 (anche
  sulla 0.61). Al mercato arrivano quattro auto in quattro minuti: o si
  allunga la prova, o si guarda perché il mercato ne riceve così poche.
- **La sala scommesse** ha ancora il suo stile a parte (blu e rosso, da
  «football manager»): voluto, ma è l'unico pannello fuori dal tema.
- **Il panaro**, la traversata a piedi e 'o motorino con le chiavi: fermi.
- **I tre plugin della biblioteca** (ProtonScatter, Dialogic, LimboAI)
  sono installati ma il gioco non li usa (il perché in `NOVITA-v0.62.md`).
  Se si decide di non usarli mai, si possono togliere: l'autoload di
  Dialogic parte a ogni avvio per niente, e LimboAI (già fuori
  dall'esportazione: bloccava la build web) lascia tre righe d'errore
  all'avvio.
- **Le pozzanghere nella build web**: lì non ci sono (niente profondità
  negli shader del renderer Compatibility). Un ripiego possibile: una
  decalcomania di pozzanghera e l'asfalto più lucido quando piove.
- **I motorini davanti ai bassi**: tolti perché tappavano i vicoli da
  quattro metri. Se si vogliono, vanno nei vicoli larghi o di sbieco.
- **`prova_ntuppate` è una prova a caso** (passanti e pause dei vigili
  pescano col dado): alla 0.62 ha trovato due piantati veri, uno per giro.
  Prima di dire «zero», farla girare lunga (`DURATA_NTUPPATE=600`).
- **Il repository e i file grossi**: il `.gitignore` del capo esclude
  `*.glb`, `*.wav`, `*.mp3`, quindi il repo su GitHub da solo non basta a
  ricostruire il gioco (servono i file della cartella). Se si vuole un
  repo completo, Git LFS.

---

## Fatto — v0.61 · 'O juoco, rifinito

Il capo, dopo una giornata intera: A) i guagliuni non funzionano, B) le armi
non si vedono e non si capisce se si usano, C) l'economia (un'auto rubata
vale tantissimo); poi rifinire e arricchire. Racconto completo in
`NOVITA-v0.61.md`.

- [x] **I guagliuni lavorano davvero**, misurato in città con
      `prova_guagliune_vere` (quattro piazze, quattro minuti): piazza di
      casa ferma a un'auto quando eri via, conteggio delle auto di tutta la
      città, coda dello stadio dentro alla curva (varchi nuovi in
      `posteggio_3d`), pazienza che correva per colpa tua, guaglione lento
      e senza passo, paga del giocatore invece della sua, capsula che
      sollevava la macchina. **La sera**: ti aspetta al posto suo, ti
      chiama, alle nove un cartello, nel riepilogo quanto hai ritirato.
- [x] **'O fierro 'n primma perzona** (`arma_fp.gd`): modellino sulla
      telecamera con pugno e manica, fendente/stoccata/rinculo attorno alla
      spalla, vampata, luce, scia e scintille, cambio arma che scende e
      risale, crocetta sul mirino (`colpo_a_segno`), `sparo.wav`.
- [x] **Economia sulla giornata tipo** (`GIORNATA_TIPO` = 80): auto rubate
      36/55/80/110, −38% a macchina, tre al giorno (`GARAGE_MAX_JURNATA`),
      stemmi 10/7/8, lavoretto stemmi 16 a pezzo, guaglione 0,75.
- [x] **Chi te 'o vede fà**: `testimoni()` e `peso_testimoni()` sui furti
      d'auto, sugli stemmi e sul borseggio sbagliato.
- [x] **Gennarino 'o Nuovo** (l'abusivo dell'abusivo), **'o turista
      spierzo** (accompagnarlo alla colonna gialla), **'o panaro 'e Donna
      Filumena** (sigarette o caffè nel cesto).
- [x] Sei consigli nuovi, una decina di battute, una pagina di tutoriale.
- [x] Prove nuove: `prova_guagliune_vere`, `prova_perzone_nove`;
      fotografie: `foto_armi`, `foto_sessantuno`; sonde: `sonda_armi`,
      `sonda_posteggi`.

### Rimasto aperto dalla 0.61

- **I soldi di tutti i giorni sono stretti.** `prova_economia` dice che le
  spese di casa sono sui 68 euro al giorno e la giornata tipo ne fa 68-80:
  finché il furto pagava sei giornate non si sentiva. Adesso i guagliuni
  funzionano e danno il margine — ma va guardato alla prima partita lunga
  (la manopola è `RESA_DIPENDENTE`, non il furto).
- **La prova che gioca dieci giornate da sola** resta da scrivere: la
  0.61 ha mostrato che è l'unico modo di vedere quello che vede il capo.
- **Il panaro** si appende a un muro davanti alla tua piazza: in
  fotografia il balcone è una soletta chiara su una facciata già piena.
  Un balcone del pacchetto al posto delle scatole sarebbe meglio.
- La traversata a piedi e 'o motorino con le chiavi: ancora fermi.

---

## Fatto — v0.63 · 'O Duttore

Una richiesta sola: *«Borrelli non esce più.»* Racconto completo in
`NOVITA-v0.63.md`.

- [x] **Due porte col dado che cresce.** A: la sera, dal secondo giorno,
      5% +5% per ogni giorno senza di lui. B: dal secondo giorno, quando il
      vigile chiama i carabinieri, 1% +10 punti a chiamata. Quando arriva,
      i dadi ripartono. La violenza vista non lo chiama più
- [x] **La radio del vigile non si scarica più** (`_chiamata_fatta` restava
      acceso per sempre dopo la prima chiamata)
- [x] **Il vigile mandato via tre volte** in una giornata chiama i
      carabinieri
- [x] **Borrelli non si tocca**: pugni, ferri e pistole non vanno a segno,
      alzano furia e sospetto
- [x] **Fare finta di niente**: sigaretta o caffè, e lontano; vicino la
      furia scende a meno della metà, a mani vuote non scende sotto 44
- [x] **Nasce a 20-30 m dal giocatore**, in strada, e cammina sulla collina
- [x] Prove: `prova_borrelli` (riscritta), `prova_borrelli_gioca` (nuova)

---

## v0.64 — **'E vvoce**

- **Le voci registrate**: l'introduzione parlata, e qualche riga dei
  personaggi principali. Il gioco è pieno di gente che parla e nessuno fa
  un suono. Adesso che sei clienti e quattro vicini hanno un nome, sono
  loro i primi a meritarsela.
- **Altre animazioni**: la 0.62 ha tradotto 28 clip della libreria sugli
  altri due scheletri (`tools/retarget_ual.gd`); resta **una clip di idle in prima
  persona**, che è l'unico modo di vedersi le braccia camminando (la posa
  a mano non funziona, ed è misurato in `prova_braccia`).
- **'E ccriature**: una quinta corporatura in `build_personaggi.py`.
  Mimmo 'o guaglione, per adesso, è un adulto scalato a 1,32.

## Il disegno del furto, com'era stato deciso

*Tenuto qui perché è il metro con cui giudicare quello che è uscito.* Il
capo, alla domanda «saresti capace?»: *«Puoi tentare di rubare tutte le auto
e i motorini con un minigioco che è più difficile in base al mezzo e al
caso. Per guidare ufficialmente un mezzo devi avere le chiavi.»*

- [x] **Il furto col minigioco**, difficoltà dal mezzo **e dal dado** —
      fatto per le auto nella 0.57
- [x] **Fallire fa rumore** — sospetto, una stella, e la serratura bloccata
- [ ] **I motorini** e **le chiavi** → spostati alla 0.58, poi alla 0.59, poi alla 0.60;
      ora candidati della 0.61 (rifinire il gameplay)
- [ ] **Chi te lo vede fare**: adesso il prezzo lo fa solo il vigile, la
      folla non conta ancora → candidato della 0.61

---

## I boss che verranno e il finale

Il capo, alla 0.63: *«Col tempo dobbiamo ideare e implementare altri boss ed
un vero finale del gioco.»* Qui le proposte, da scegliere insieme prima di
scrivere una riga. La regola resta quella della 0.55: **ogni boss è una
meccanica diversa**, non un Borrelli con un'altra faccia.

Oggi ci sono: **Borrelli** (non si tocca: si fa finta di niente e si
spiega), e i tre **boss di capitolo** ('O Cardinale vuole soldi, Donna
Carmela vuole una quota, Tonino 'e Notte non tratta).

### Boss possibili

1. **'O Carro attrezzi** — un ausiliario del traffico col carro che si
   porta via le macchine dei tuoi clienti una dopo l'altra. Non si mena
   e non si convince: è una **gara di tempo**. Svegli i clienti, gli fai
   spostare la macchina, o ti metti davanti al carro (e lo paghi in
   sospetto). Ogni macchina portata via è un cliente perso per sempre.
2. **'A Finanza** — un accertamento: sanno quanto guadagni. Per una sera
   i soldi in tasca sono un problema: vanno **nascosti** (a casa dalla
   moglie, dai guagliuni, nel panaro di Donna Filumena) prima che ti
   fermino. Quello che trovano addosso te lo tolgono. Il boss che rende
   utile tutto il quartiere che hai costruito.
3. **'O Re d''e Strisce** — l'abusivo più grosso della città vuole la tua
   piazza. **Sfida di mestiere**: tre minuti, chi posteggia più macchine e
   incassa di più. Si vince lavorando meglio, non menando.
4. **'E Strisce Blu** — il Comune dipinge le strisce blu nella tua piazza
   e mette il parchimetro: per una settimana le macchine pagano la
   macchinetta e non te. Un boss lungo, a giornate: si vince facendo
   rompere il parchimetro, convincendo i clienti fissi, o cambiando
   piazza.
5. **'O Cugino d''o Sindaco** — arriva col macchinone e vuole il posto
   migliore gratis, ogni giorno. Dirgli di no costa, dirgli di sì pure: un
   boss **di scelta**, che cambia i rapporti con i clienti fissi.

### Il finale

Due strade, che la roadmap già chiamava «l'arco lungo»:

- **'O garage 'e famiglia (il finale onesto).** Metti da parte i soldi e
  ti compri un garage vero, in regola, con la famiglia. Ultima sera:
  Borrelli viene un'ultima volta — e stavolta non scappi, lo inviti al
  taglio del nastro. Il gioco finisce con il riepilogo di una vita.
- **'O Re d''a città (il finale di potere).** Tutte e quattro le piazze,
  tutti i boss di capitolo battuti, i guagliuni che lavorano per te e tu
  che non posteggi più. Ultimo boss: tutti quelli che hai incontrato,
  insieme, la stessa sera. Il gioco finisce con la domanda della moglie:
  *«E mo'? Ch'è cagnato?»*

Le due strade possono convivere: il giocatore sceglie quale diventa senza
dichiararlo, con quello che fa nelle ultime giornate.

---

## Più in là

- **L'arco lungo.** Venti-trenta giornate con la pressione che cresce, e
  due modi di uscirne: paghi tutto e chiudi, oppure diventi quello che
  compra le piazze e non posteggia più.
- **Il tressette al bar**, adesso che il motore delle carte c'è già — e
  adesso che un bar ce l'ha ogni piazza.
- **Guidare, in generale.** Se la sensazione del volante regge: spostare
  la macchina di un cliente, farsi inseguire in auto, un trasporto vero.
- **'O Castel dell'Ovo**, che in fondo al golfo è ancora un blocco.

---

## Le domande ancora aperte

1. **Quanto deve durare una partita?** Con le giornate da sette minuti e
   mezzo, trenta giorni sono tre ore e mezza di gioco.
2. **Il finale è uno o due?** Il gioco finisce quando hai pagato tutto, o
   quando hai preso tutta la città?
3. **Quanto vogliamo che la violenza resti un'opzione?** I tre fermi
   della 0.52 hanno alzato il prezzo di farsi prendere, e la 0.54 ha
   alzato quello di prenderle (le ossa si ricomprano, e solo di notte).
   Resta da vedere se bastano a rendere il pugno una scelta invece che la
   strada breve.
4. **Il furto rischia di mangiarsi il gioco?** ~~Un furto su commissione
   paga fino a 260 euro contro i 3-12 di una macchina posteggiata.~~
   **Risposta data nella 0.57, e il rischio era reale**: una berlina vale
   €220 contro gli 80 di una giornata intera di posteggio. Il freno è il
   ricettatore che paga **−32% a ogni macchina della stessa giornata**, con
   un pavimento a un quarto: la quinta vale €55. Rubare resta la cosa che
   paga di più **una volta al giorno**. Resta da guardare alla prima partita
   lunga se una macchina al giorno tutti i giorni sia ancora troppo — in
   quel caso la manopola è il pavimento, non la prima paga.
   **Risposta del capo, 0.61**: *«un'auto rubata vale tantissimo»*. Era
   troppo: adesso vale da mezza a una giornata e mezza, tre al giorno.
5. **'E ffasce so' troppo forte?** La nottata paga il doppio, e una
   nottata del primo del mese paga il doppio del doppio. Se il modo
   migliore di giocare diventa "resta sveglio fino alle quattro", la
   fascia si è mangiata la giornata. E adesso c'è una ragione in più per
   stare in giro di notte: il cornetto.
6. **'O gioco d'azzardo se vede troppo?** Slot, tre carte, scopa, lotto e
   scommesse. I ritorni sono tutti sotto il 100% e misurati, quindi
   nessuno è un exploit — ma cinque modi di perdere soldi in un gioco su
   un mestiere povero sono tanti.
7. **'E sei clienti fisse bastano?** Una macchina su tre ne porta una, e
   in un turno ne passano due o tre. Su trenta giornate le sei facce si
   vedono parecchie volte: il rischio è che il quartiere sembri un paese
   di sei abitanti. Da guardare alla prima partita lunga — se succede, la
   risposta non è aggiungerne venti, è **abbassare la quota** sotto a un
   terzo.
8. **'O boss 'e capitolo basta 'na sera?** Se ti prendi una piazza la
   mattina, hai una nottata per andarci. Se te la prendi alle tre di notte
   ne hai venti minuti, e se sei in mezzo a un'altra cosa la perdi senza
   averlo nemmeno visto. Da guardare alla prima partita lunga: forse la
   scadenza deve essere "la sera dopo" invece che "stasera".
9. **'O pacchetto**: Windows 54,9 MiB, web 46,7. Se la versione web serve
   per far provare il gioco, si può fare un pacchetto separato con le
   texture a 288 — costa mezz'ora.
10. **Quanto ha da renne 'a sera, mo' ca 'o vigile smonta?** Dalle venti in
    poi non c'è più nessuno che guarda, e le fasce orarie della sera già
    pagavano quasi il doppio. Sulla carta i due vantaggi si moltiplicano, e
    il modo migliore di giocare rischia di diventare «dormi fino alle
    sette». Da guardare alla prima partita lunga: se succede, la risposta
    non è rimettere il vigile — è far scendere le mance della sera, o dare
    alla notte un pericolo suo (Borrelli e i boss di capitolo ci stanno
    già, e forse basta alzare loro).
