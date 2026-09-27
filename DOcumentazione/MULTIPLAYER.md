# Multiplayer: cosa servirebbe davvero

*Scritto il 27 settembre 2026 sulla v0.64 ('O Rre e 'e Strisce). I numeri
vengono dal codice vero (`scripts/`, 115 file, 67.574 righe), contati con
`grep`: sono indicativi, non esatti.*

La risposta corta è **sì**. Godot 4.3 ha già quello che serve
(`MultiplayerSpawner`, `MultiplayerSynchronizer`, RPC, ENet per il desktop,
WebRTC e WebSocket per il browser), e per le lobby con gli amici c'è
GodotSteam. Anche Schedule I, il nostro metro, ha la co-op online: la
partita la ospita uno, gli altri entrano dalla lobby di Steam.

La risposta utile è **quanto costa, e in che ordine si fa**, perché il gioco
è stato scritto da cima a fondo per un giocatore solo. E il multiplayer è
l'unica feature che costa di più ogni versione che passa senza farlo.

---

## 1. Il censimento

| cosa si è contato | quante volte | in quanti file | perché conta |
|---|---:|---:|---|
| `get_first_node_in_group("player")` | 77 | 43 | ogni volta che il codice dice «**il** giocatore» |
| altri riferimenti a una variabile `player` | 182 | 34 | come sopra, ma già tenuto in una variabile |
| chiamate a `GameManager.` | 1.381 | 79 | lo stato è tutto lì, ed è di un giocatore solo |
| caso globale (`randf`, `randi`, `shuffle`, `pick_random`) | 933 | 76 | due macchine che tirano a caso ognuna per conto suo non vedono la stessa partita |
| di cui in `citta_3d.gd` | 217 | 1 | **la città viene diversa a ogni avvio** (nessun `seed()` globale) |
| RNG col seme fisso (già a posto) | 96 | 20 | Mergellina, golfo, robba PSX ed esterna, vicoli: questi sono già uguali dappertutto |
| `get_tree().paused = true` | 11 | 10 | lotto, casa, bacheca, scopa, partite, tutorial, intro, tre punti dell'HUD, `main` |
| `Engine.time_scale` (il rallentatore) | 4 | 2 | rallenta il mondo intero, non solo chi ha dato il colpo |
| `reload_current_scene()` | 2 | 2 | **ogni giornata nuova ricarica tutta la scena** (`hud.gd`, `caricamento.gd`) |
| lettura diretta di `Input` dentro le cose del mondo | — | 10 | `car_3d` (il minigioco della guida), `shop_3d`, `bar_piazza_3d`, `tabaccheria_3d`, `armiere_3d`, `bazar_3d`, `tre_carte_3d`, `sala_scommesse_3d`… |
| script con `_process` o `_physics_process` | — | 74 | tutto quello che si muove o ragiona da solo |
| segnali di `GameManager` | 73 | 1 | oggi scattano sulla macchina dove succede la cosa; in rete devono scattare dappertutto |
| codice di rete già scritto | 0 | 0 | si parte da zero |

**I file che nominano più spesso «il giocatore»** (e quindi quelli da
toccare per primi): `driver_3d` (7), `car_3d` (6), `signora_3d` (5),
`tavolo_scopa` (4), `guaglione_3d` (4), `sbirro_3d` (3), e poi con 2 a testa
`zone_vicolo_3d`, `vigile_3d`, `rivale_3d`, `carabinieri_3d`, `fermo_3d`,
`citta_3d`, `jurnata_vista`, `committente_3d`, `tre_carte_3d`,
`turista_spierzo_3d`, `nuovo_abusivo_3d`.

---

## 2. I nodi da sciogliere

### 2.1 Uno stato solo per tutti

`GameManager` ha **134 variabili** e le tratta tutte come se il giocatore
fosse uno. Vanno divise in tre mucchi (a occhio, sulla lista vera):

- **Di ogni giocatore** (circa 45): `money` (se si sceglie la tasca a
  testa), `health`, `sciato`, `stelle`, `heat`, `_crimine`, `armi`,
  `arma_in_mano`, `cigarettes`, `caffe`, `caffe_boost`, `emblems`,
  `upgrades`, `arrested`, `hospitalized`, `ncella`, `dentro_casa`,
  `auto_guidata`, `dialogo_con`, `pacco_caldo`, `zona_corrente`,
  `piazza_corrente`, `pickpockets`, `punches_thrown`…
- **Del mondo** (circa 50): `giornata`, `shift_time_left`, `notte`,
  `tipo_giornata`, `zone_mie`, `affitti`, `dipendenti`, `boss_*`,
  `strisce_blu`, `re_*`, `commissioni`, `lavoretti`, `rapporti` (i clienti
  fissi), `lotto_stasera`, `borrelli_*`…
- **Della casa** (una quindicina): `umore_moglie`, `spese_aperte`,
  `consegnato_oggi`, `extra_richiesto`, `luce_staccata`, `casa_id`… Qui c'è
  una scelta di gioco, non tecnica: **una famiglia sola per tutti** (la
  sera si consegna insieme, e se uno si è giocato i soldi alla scopa lo
  pagano tutti) è la più divertente ed è anche la più semplice.

La forma giusta è una risorsa `Giocatore` (una per chi è collegato) dentro
`GameManager`, e `GameManager.money` che diventa
`GameManager.io().money`. Sono 1.381 chiamate, ma **la maggior parte
riguarda cose del mondo e resta com'è**.

### 2.2 «Il giocatore» non esiste più

Le 77 chiamate a `get_first_node_in_group("player")` dicono ognuna una cosa
diversa, e ognuna va decisa una volta:

- **il più vicino** (il vigile che guarda, l'autista che ti cerca, il
  rivale che ti vede, i carabinieri);
- **quello che sta interagendo** (il negozio, la scopa, il confronto, il
  minigioco della guida);
- **quello di questa macchina** (l'HUD, la musica, la macchina da presa).

Da qui nascono tre funzioni sole, `GameManager.io()`,
`GameManager.chi_è_cchiù_vicino(pos)` e il giocatore passato come argomento
a chi interagisce, e le 77 chiamate diventano una di queste tre. Il lavoro
è meccanico, ma va fatto file per file con la sua prova.

### 2.3 Il caso

In rete **decide una macchina sola, l'host**: dove va il passante, quale
auto arriva, se il vigile ti vede. Gli altri ricevono il risultato. Quindi
le 933 chiamate al caso vanno bene così come sono, **a patto che girino solo
sull'host**. Il problema vero è la città: se la costruisce ognuno per conto
suo con `randf()`, l'arredo non coincide (e un motorino che per me c'è e per
te no è un muro invisibile). Le soluzioni sono due, e la prima costa una
riga:

1. `seed(seme_d_â_partita)` in cima a `citta_3d._ready()`, con il seme
   deciso dall'host e mandato agli altri. La città si costruisce in un colpo
   solo e in ordine fisso, quindi viene uguale.
2. Come rete di sicurezza, una prova che costruisce la città due volte con
   lo stesso seme e confronta posizione per posizione.

### 2.4 Il tempo che si ferma

Da soli va benissimo fermare il mondo mentre si gioca a scopa o si guarda la
bacheca. In due non si può: mentre io compro al bazar tu stai dirigendo una
macchina. Quindi:

- gli **11 punti con `paused = true`** chiedono prima a una funzione
  (`GameManager.si_pò_fermà()`) se si è da soli; se no si apre il pannello
  e il mondo va avanti (come in Schedule I);
- il **rallentatore** resta solo in partita da soli (oppure diventa
  un effetto sulla macchina da presa di chi ha dato il colpo);
- **la giornata nuova**: oggi si fa `reload_current_scene()`. In rete la
  sera finisce quando **tutti** sono andati a dormire (come in Schedule I),
  l'host salva, manda il seme del giorno dopo, e tutti ricaricano insieme;
- **la galera** diventa di uno solo: chi è dentro passa la notte in cella,
  gli altri possono andare a pagare la cauzione. Questo è gioco nuovo
  regalato dal multiplayer.

### 2.5 Chi muove chi

Le buone notizie stanno qua. La maggior parte degli NPC cammina con
`Passo.verso()`, senza fisica: in rete basta mandare posizione e rotazione
dieci o venti volte al secondo e far scorrere il movimento sugli altri. Le
auto parcheggiate non si muovono, quindi non costano niente. I passanti e le
auto in movimento, che usano `move_and_slide`, fanno la fisica solo
sull'host e sugli altri diventano pupazzi mossi da fuori.

Il limite da misurare è **quanta roba si muove insieme**. Già oggi i
gruppi a quadretti e le cose che dormono lontano dal giocatore tengono
basso il numero. In rete il criterio diventa «lontano da **tutti** i
giocatori».

### 2.6 I tasti letti dalle cose sbagliate

In 10 script sono le cose del mondo (l'auto, il negozio, il bar) a leggere
direttamente i tasti. In rete il tasto lo preme una persona sulla sua
macchina, che manda all'host un messaggio del tipo «Massimo vuole comprare
la pittura». Quindi i tasti si leggono solo in `player_fps.gd` e nei
pannelli, e diventano richieste. Il minigioco della guida (`car_3d`,
`_process_directing`) è il caso più delicato, perché lì conta il tempismo:
si gioca sulla macchina di chi dirige e all'host si manda solo l'esito.

### 2.7 Il salvataggio

Oggi è JSON in `user://` (`SAVE_VER` 2, funzioni a `game_manager.gd:4803`
e seguenti). In rete **la partita è dell'host**, come in Schedule I. Chi
entra porta con sé al massimo il nome e la faccia. Poi serve un
`SAVE_VER` 3 con dentro la lista dei `Giocatore` (e la migrazione dal 2, se
no chi ha già giocato perde tutto).

### 2.8 La versione per il browser

ENet nel browser non c'è, e un browser non può fare da host. Si può fare
con WebRTC e un piccolo server di appuntamento, ma **non conviene**: la
versione itch.io resta per giocare da soli, e il multiplayer va sul desktop
(Steam). Il gioco da soli **non cambia di una virgola**: il multiplayer è
un modo di gioco in più, non un gioco diverso.

---

## 3. Che multiplayer

| modo | cos'è | costo | resa |
|---|---|---|---|
| **Asincrono** | classifiche della giornata, la sfida del Rre coi tempi degli amici, «Dario ha fatto €340 ieri» | basso | poca, ma subito |
| **Co-op da 2 a 4** («'E cumpagne») | stessa città, stessa piazza, stessa famiglia; uno dirige, uno fa il palo al vigile, uno va a rubare gli stemmi | alto | **è il cuore di Schedule I** |
| **Rivali veri** (uno contro uno) | due parcheggiatori che si contendono la stessa piazza; le contromosse di `OPEN-WORLD.md` (arrivare prima, menare, sputtanare, fare l'accordo) giocate da persone | medio, **se c'è già la co-op** | altissima per video e streamer |
| Server pubblici, MMO | — | enorme | no |

**Scelta consigliata:** la co-op, e i rivali veri come secondo passo, che
con la co-op fatta costano poco.

Cosa si guadagna in gioco, gratis o quasi:

- **ruoli spontanei**: chi dirige e chi guarda il vigile. Il sospetto del
  vigile diventa di ogni giocatore, quindi uno può distrarlo mentre l'altro
  lavora;
- **la cauzione**: uno in galera, gli altri a cercare i soldi;
- **la cassa della sera**: il conto è di tutti, ma i soldi in tasca sono
  di ognuno. Chi si è giocato tutto al lotto se lo sente dire da Nunzia
  davanti agli amici;
- **le piazze**: ognuno ne tiene una. La mappa diventa un tabellone di
  squadra.

---

## 4. Le fasi, e quanto costano

L'unità di misura è la **versione** (una 0.6x normale). Le stime sono
larghe, come ogni stima di lavoro sul multiplayer.

### Fase 0: pronti per la rete (da subito, dentro le versioni normali)

Costo: **quasi zero**, qualche ora per versione. Sono regole di scrittura
più tre lavoretti:

1. **Il seme della città**: `seed()` in `citta_3d._ready()` e la prova
   `prova_seme_citta` (due costruzioni, stesso seme, stesse cose). Mezza
   giornata.
2. **`GameManager.io()`**: la funzione esiste da subito e restituisce il
   giocatore di oggi. Ogni file che si tocca per altri motivi passa da
   `get_first_node_in_group("player")` a `io()`. Nessun rifacimento
   apposta: le 77 chiamate calano da sole.
3. **`GameManager.si_pò_fermà()`**: oggi risponde sempre sì. Gli 11 punti
   di pausa la chiamano.

Più le regole per il codice nuovo: niente «il giocatore», niente `Input`
fuori da `player_fps` e dai pannelli, niente stato del singolo giocatore
buttato nel mucchio del mondo.

### Fase 1: il prototipo, «Duje 'int'â piazza»

Costo: **una versione dedicata**. Solo la piazza di casa, due giocatori,
IP diretto in rete di casa (ENet, niente Steam).

- l'host apre la partita, l'altro entra: due corpi visibili, con le
  animazioni (`HumanBuilder` + `animator`);
- le auto le crea l'host (`MultiplayerSpawner`) e arrivano uguali per
  tutti e due;
- chi preme E su un'auto la dirige, e i soldi entrano nella cassa comune;
- vigile, passanti e rivali solo sull'host, visti dall'altro come pupazzi.

**Si prova tutto qui dentro, senza di te**: due Godot headless nello stesso
contenitore, uno host e uno ospite su `127.0.0.1`, e una
`prova_rete_piazza` che controlla che alla fine i due mondi coincidano
(stesse auto, stessi soldi, stesse posizioni con mezzo metro di margine).
Poi una partita vera fra te e Dario.

**Lo scopo non è finire, è capire**: se due in piazza fanno ridere, si va
avanti. Se no, abbiamo speso una versione e non dieci.

### Fase 2: la città intera in co-op

Costo: **tre o quattro versioni**, ed è qui che sta quasi tutto il lavoro.

- la divisione di `GameManager` (2.1) con `SAVE_VER` 3 e la migrazione;
- le 77 chiamate a «il giocatore» risolte tutte, file per file (2.2);
- tutti gli NPC decisi dall'host e sincronizzati (2.5), iniziando da
  quelli che danno gioco (vigile, autisti, rivali, carabinieri) e lasciando
  per ultimi quelli di contorno (ragazzini, signore sedute, panaro);
- i pannelli che non fermano il mondo, la sera tutti a dormire, la galera
  di uno solo (2.4);
- i tasti trasformati in richieste all'host (2.6);
- HUD, musica e macchina da presa di ognuno;
- una batteria di prove di rete accanto alla batteria di sempre.

### Fase 3: Steam

Costo: **mezza versione, una al massimo**. Lobby e inviti dagli amici con
GodotSteam (serve la pagina Steam del gioco, che comunque serve per
vendere). Da lì ci si collega senza aprire porte al router. Il gioco
continua a funzionare anche senza Steam, da soli.

### Fase 4 (se piace): i rivali veri

Costo: **una versione**. Due squadre, o due persone, nella stessa città
con le piazze contese.

### In totale

Dalla Fase 1 alla Fase 3 sono **cinque o sei versioni** dedicate, con la
Fase 0 fatta per bene prima. Senza la Fase 0 aumentano, e aumentano un po'
a ogni versione che passa.

---

## 5. Le trappole

1. **Il caso sulla macchina sbagliata.** Un `randf()` che gira
   sull'ospite invece che sull'host basta a far divergere i due mondi,
   pian piano, senza nessun errore a schermo. La regola: sull'ospite gli NPC
   non decidono niente.
2. **I segnali dell'autoload.** I 73 segnali di `GameManager` oggi
   scattano solo dove succede la cosa. In rete l'host li emette e li manda,
   e gli ospiti li riemettono in locale. Se se ne dimentica uno, l'HUD
   dell'ospite resta indietro.
3. **Mandare troppo.** Posizioni a ogni fotogramma per cento NPC
   intasano la connessione di casa. Dieci o venti volte al secondo, con lo
   scorrimento sull'altra macchina, e solo per chi è vicino a qualcuno.
4. **Le prove che difendono il bug** (lo sappiamo dalla 0.59): una prova
   di rete che passa perché host e ospite girano sulla stessa macchina con
   lo stesso caso non prova niente. Gli ospiti vanno avviati con un caso
   diverso apposta.
5. **Il single player che si rompe.** Ogni passo della Fase 2 si chiude
   con la batteria di prove di sempre a zero storte, **giocando da soli**.

## 6. La lezione

Il multiplayer non si aggiunge alla fine, si prepara dall'inizio, e da noi
l'inizio è adesso: con la Fase 0 costa qualche ora a versione. Poi si
fa un prototipo piccolo per capire se è divertente, prima di spendere il
grosso. È lo stesso ragionamento del rivale e della città in
`OPEN-WORLD.md`: prima la cosa che dà gioco, poi la struttura che la
moltiplica.

## In una riga

Si può fare, costa circa cinque o sei versioni, e da domani ogni riga di
codice nuova può già costarne un po' meno.
