# Riassunto della chat della v0.60

Questa è la cronaca della chat in cui è nata la **v0.60 · 'A città vestuta**
(23–24 settembre 2026). Serve a chi apre la chat successiva per sapere non
solo *cosa* c'è nel gioco, ma *perché* è fatto così, cosa si è provato e
scartato, e dove ci si è fermati. Il manuale operativo è `COME-RIPRENDERE.md`;
le note per il capo sono `NOVITA-v0.60.md`.

---

## 1. Le richieste del capo

**All'apertura**, la chat è partita dal messaggio preparato nella 0.59
(`PROMPT-NUOVA-CHAT.md`): leggere `COME-RIPRENDERE.md`,
`RIASSUNTO-CHAT-v0.59.md` e `ROADMAP.md`; rimettere in piedi il progetto dai
pezzi `PAS-v0.59-Progetto.tar.xz.0*.part`; far girare la batteria. In più:

- **la pulizia della cartella**, con due vincoli precisi:

  > «Tieni sempre dalla v0.53 in poi e non toccare mai le librerie di asset
  > (Car Pack, Low Poly, Animated, Pandazole, PSX, Quaternius). Prima fammi
  > vedere la lista, poi procedi.»

  e, vista la lista: *«Sì, e anche il pezzo 0.56»* (il vecchio
  `ParcheggiatoreAbusivo-v0.56-Web-itchio.zip` sciolto nella cartella madre);

- **il secondo giro su asset, collisioni e pose** della sezione 6 di
  `COME-RIPRENDERE.md` della 0.59: la galera costruita dentro alla città,
  la posa rigida da fermo dell'umano di Quaternius, il passante (in realtà
  il ragazzino) che ogni tanto resta piantato, il peso delle ringhiere;

- da consegnare come **v0.60**, cartella intera in `Claude outputs\v0.60\`,
  con leggimi, changelog e documenti per ripartire; e in chiusura:

  > «Infine, integra più asset nuovi che puoi, rendi in generale il mondo di
  > gioco più dettagliato possibile. La prossima build la dedicheremo invece
  > a rifinire il gameplay.»

**Durante il lavoro**: più volte «Continua» (la chat ha superato il limite
del contesto una volta ed è ripartita da un riassunto automatico).

**Le istruzioni del progetto**, aggiornate dal capo in questa chat, dicono
ora anche: *«occupati tu stesso di cancellare man mano le versioni più
vecchie che non ti servono più»* (tenendone sempre almeno sei-sette).

---

## 2. Com'è andata, in ordine

### 2.1 La ripartenza

Il pacco della 0.59 si è rimesso insieme senza sorprese: i cinque pezzi dal
computer del capo col ponte, `cat` + `tar`, Godot 4.3 scaricato, script di
prova in `/tmp`. La batteria di partenza (`/tmp/batteria_059_base.txt`) era
tutta a zero tranne `prova_ntuppate` a 1: il ragazzino del largo, come
annunciato nelle note della 0.59.

### 2.2 La pulizia

Prima la lista, poi — col sì del capo — uno script PowerShell
(`pulizia-v0.60.ps1`) che manda **nel Cestino** (mai cancellazione
definitiva) e scrive un registro. Risultato in
`Claude outputs\pulizia-log.txt`: **72 voci nel Cestino, 0 mancanti, 0
errori** — gli zip e i tar delle versioni dalla 0.13 alla 0.51 nella
cartella madre e in `Claude outputs`, le cartelle `v0.46`, `v0.47`,
`PAS-v0.49-*-parti`, `PAS-v0.50-*-parti`, e il pezzo 0.56 che il capo ha
aggiunto. Le librerie di asset non sono state toccate. Alla consegna della
0.60 c'è stato un secondo giro (vedi 2.9).

### 2.3 La galera

Il blocco della galera stava dalla 0.56 sopra a due isolati e tre strade.
Il vincolo lasciato dalla 0.59: chi esce deve poter tornare a piedi in
città, quindi la galera resta dentro ai muri di confine. Scelta: **farne un
isolato della pianta**, l'angolo di sud-est del
Vomero ([133, 156, 155, 168]), così tutto quello che cammina la conosce da
sola. Il vestito (finestrelle a sbarre, portone di ferro, cancello, filo
spinato, garitta, targa, bandiera, lampade) è venuto con i modelli PSX.
Le fotografie (`foto_sessanta`, sei scatti della galera più la notte) hanno
fatto correggere il verso dei bracci del filo spinato e qualche
inquadratura con l'occhio dentro a un muro.

### 2.4 L'umano fermo

La foto da vicino ha fatto vedere che la «posa rigida» era una guardia da
pugile: la clip `Idle` del pacchetto è fatta così. Niente clip tradotte (la
lezione della 0.47): `_prepara_fermo` costruisce `Fermo` dalla camminata
ferma a 0,567 s più il movimento dell'`Idle` pesato osso per osso.
`tools/foto_umano_fermo.gd` fotografa prima e dopo.

### 2.5 I ragazzini

Tre cause vere (il calcio che parte da 1,05 m e le gambe che si fermavano a
0,70; la palla incastrata; la palla fuori dal cerchio del campetto) e una
falsa: dopo le prime tre, `prova_ntuppate` continuava a trovarne uno ogni
tanto. `sonda_guagliune` ha stampato tutta la finestra di tre secondi: erano
corse di andata e ritorno. La prova è stata corretta (piantato = fermo per
tutta la finestra, o tremolio entro un metro), e tre giri di fila più uno di
dieci minuti sono usciti puliti.

### 2.6 Le ringhiere

`prova_conti` diceva 3,9 milioni di triangoli **sempre disegnati**. I gruppi
sparsi si sono tagliati in quadretti di 32 m, con la scatola al posto del
ferro battuto oltre i 45 m. Facendolo è venuto fuori che `_batch_vista`
misurava la distanza dal baricentro del gruppo: le tazzulelle dei bar della
0.59 non si erano mai viste. Risolto mettendo a quadretti anche i gruppi con
un raggio. `prova_conti` ora stampa anche i triangoli dentro al raggio di
vista da cinque punti della città: 1,14–2,23 milioni.

### 2.7 La roba nuova

Un progettino a parte (`/home/claude/esame_psx`, ora in `tools/esame_psx/`)
per guardare i modelli del PSX Mega Pack prima di usarli: il foglio dei
provini, le misure (il pacchetto è 1,52× il vero), il verso del davanti.
Scelti e copiati **58 modelli** (tabella dei nomi in
`tools/esame_psx/NOMI-v0.60.md`), messi in città da `scripts/robba_psx.gd`
e dentro ai posti che c'erano già (bar, tre carte, scopa, sala scommesse,
garage, armiere, vascio), più i bassi del piano terra in `citta_3d.gd`.
Tolti cinque modelli importati e poi non usati (tastiera, mouse, plafoniera,
due scaffali): `prova_asset` vuole zero modelli mai nominati.

Quello che le fotografie hanno fatto correggere: le sedie davanti alle
facciate che guardano fuori dalla mappa; il bagno chimico di legno scuro
(ritinto blu); la signora seduta senza sedia (il bug del baricentro, sopra);
le saracinesche dell'acqua che `prova_quote` credeva sospese perché stavano
in un gruppo `strada_psx` (ora `appise_psx`).

### 2.8 I tetti

La foto dall'alto della galera ha mostrato tetti «a coriandoli»: la texture
`tetti_italiani.jpg` era un collage di foto aeree di Venezia. Rifatta a
codice (`tools/genera_coppi.py`, due versioni girate per le falde nei due
versi) e tolta la vecchia. Nella stessa foto i tetti piani erano a strisce:
guaina e lastra alla stessa quota; la guaina è salita di tre centimetri.

### 2.9 La chiusura

Versione a `v0.60` nei due posti, `--check-only` su tutti i file toccati
(solo gli errori normali degli autoload), batteria completa, build Windows e
Web, documenti, pacco del progetto in pezzi da 19 MB con `UNISCI.bat`,
consegna in chat e in `Claude outputs\v0.60\`. Poi il secondo giro di
pulizia: i pezzi `.part` delle versioni già riunite dal capo (0.53, 0.54,
0.55, 0.56: il file intero accanto c'è, i pezzi erano doppioni), la 0.52
rimasta in `Audio\Music\musica-8bit\Claude outputs`, e i due script della
prima pulizia — tutto nel Cestino, registrato in `pulizia-log.txt`.

---

## 3. Lo stato delle prove alla chiusura

Vedi `COME-RIPRENDERE.md`, sezione 1.3: tutte a zero storte con le tre
eccezioni note (`prova_braccia`, `prova_manella`, `prova_pose`), zero
`SCRIPT ERROR`. In più, in questa chat: `prova_ntuppate` quattro giri puliti
dopo la correzione (tre da due minuti, uno da dieci), `prova_vascio_fondale`
pulita anche da `minic.sh`, `prova_quote` a zero dopo il cambio di nome del
gruppo.

---

## 4. Cose decise (e perché)

- **La galera è un isolato**, non un edificio messo a mano: così le regole
  della pianta valgono anche per lei.
- **Le pose si costruiscono con le clip dello stesso scheletro**, mai
  tradotte da un altro.
- **Una prova si corregge quando accusa l'innocente**, non solo quando
  assolve il colpevole — ma solo dopo averlo dimostrato con una sonda che
  guarda tutto (qui `sonda_guagliune`).
- **La roba nuova va per ultima e col suo seme** (`RobbaPsx`), e le scelte
  nuove dentro a `citta_3d.gd` si fanno col numero della campata, non col
  caso della città: se no mezza città si sposta.
- **Le texture si guardano**: una texture che si chiama «tetti italiani»
  può essere Venezia.
- **Le versioni vecchie le tolgo io**, sempre nel Cestino, dalla v0.53 in
  poi si tiene tutto.

---

## 5. Dove ci siamo fermati — il prossimo passo

La 0.60 è chiusa e consegnata. La **0.61** l'ha già decisa il capo:
**rifinire il gameplay**. Cosa voglia dire di preciso va chiesto a lui
all'apertura; la lista da cui partire sta nella `ROADMAP.md` (v0.61), e il
primo attrezzo utile sarebbe una prova che gioca da sola dieci giornate e
stampa i conti giorno per giorno. Le tre cose piccole rimaste (negozio a
37 m dalla tua piazza, foto delle vetrine, signore sedute che sembrano
vecchi) sono in `COME-RIPRENDERE.md`, sezione 6.
