# Riassunto della chat della v0.62

*25 settembre 2026 · versione **v0.62 · 'A faccia nova***

## La richiesta

Il capo, dopo una partita alla 0.61, ha mandato nove punti (in ordine):

1. alzare le scritte dei tasti che coprono il resto, e rivedere **tutta** la
   UI perché sia leggibile e bella; ha messo nella cartella dei pacchetti di
   UI e di suoni (`UI elements\`), da usare liberamente (per esempio per la
   mappa);
2. lo stemma col G non si prende;
3. scopa: carte in alta risoluzione, tabella dei punti, spiegare che
   vincendo si sblocca il maestro successivo;
4. il vigile è sparito;
5. saltare e arrampicarsi sempre, per non incastrarsi;
6. il lotto del tabaccaio non si capisce (né come ci si accede né come
   funziona);
7. commissioni affidate da un personaggio che ti viene incontro, con la
   roba (il pizzaiolo senza motorino con le pizze), anche nuove;
8. economia divertente, non frustrante: «rubando una macchina mi sembra
   giusto che si facciano 100 euro»;
9. i modelli nuovi senza animazioni: prendere tutto quello che serve dalla
   cartella (`Animations\`, Universal Animation Library) e sistemare anche
   le animazioni che non vanno.

Poi «Continua» (la chat si era riempita ed è ripartita dal riassunto), e a
metà lavoro il cambio di metodo.

## Il cambio di metodo (a metà versione)

Il capo ha riorganizzato il computer: **tutto** in
`C:\Users\Max\Downloads\Parcheggiatore Abusivo Simulator\`, con Git; le
cartelle numerate (`0.61`, `Claude outputs\vX`) le ha cancellate lui, i
documenti li ha spostati in `DOcumentazione\`. Le istruzioni del progetto
adesso dicono: **vietato creare cartelle numerate**, lavoro a piccoli task,
`git add` + `git commit` a ogni task finito, e si può usare il multi-agente
e altre IA per gli asset.

Com'era il repository quando l'ho trovato: un solo commit («Initial
lightweight commit for Claude», 47 file: un po' di texture, audio, icone),
il progetto Godot in `Progetto\parcheggiatore-abusivo\` **non tracciato**,
identico alla mia 0.61 (controllato hash per hash). Cosa ho fatto:

1. aggiunto al `.gitignore` `.godot/`, `Build/`, `_claude_tmp/`;
2. commit della base 0.61 (progetto + documentazione);
3. i miei tre commit di lavoro della 0.62 portati come patch (`git
   format-patch --binary` nel contenitore → `device_commit_files` →
   `git am --directory=Progetto/parcheggiatore-abusivo`), con i messaggi
   riscritti in italiano;
4. da lì, un commit per ogni lavoro: economia, strumento delle animazioni,
   pannelli, versione e documenti.

Non ho committato le cartelle di asset non tracciate del capo
(`Animations\Animated Human…`, `Animations\Low Poly…`, `addons\`, `demo\`,
`assets\materials\`, la foto del football manager): sono sue e pesano
centinaia di MB. Non ho fatto `git push`.

## Un'altra sessione nello stesso repository

Mentre chiudevo la 0.62, nel repository del computer del capo sono comparsi
tre commit **non miei** (25-26 settembre, autore Massimo Giacca):
`b7d80f7` e `26f2f84` «Asset esterni CC0/open…» (plugin ProtonScatter,
Dialogic, LimboAI in `Progetto\parcheggiatore-abusivo\addons\`, circa 6.800
file in `assets\esterni\` con i loro crediti e `ASSET-ESTERNI.md`, modifiche a
`project.godot` e `export_presets.cfg`, una prova
`tools/test_asset_esterni`) e `cb15020` sul `.gitignore`. Li ho lasciati
come stanno. Conseguenze:

- il mio `git am` di una patch si è fermato a metà su un documento: l'ho
  chiuso con `git am --quit` (**non** `--abort`, che avrebbe riportato
  indietro anche i commit arrivati nel frattempo) e riapplicato con
  `--exclude`;
- **la build v0.62 in `Build\` non contiene quegli asset e quei plugin**
  (è fatta dal mio contenitore, allineato ai commit della 0.62): gli
  script sono identici (stesso hash dell'albero `scripts`), ma
  `project.godot` sul computer adesso ha in più i plugin;
- la prossima chat deve prendere il progetto **dal computer** (che ha
  tutto), non da una copia vecchia.

## Cosa è stato fatto

Vedi `NOVITA-v0.62.md` per il racconto. In breve: tema unico e UI rifatta
(riga dei comandi, schede, minimappa, suoni e icone, pannelli), G per lo
stemma, scopa HD con tabellone e sfida sbloccata, vigili che nascono e non
si piantano, appigli e sbroglio, lotto spiegato, commissioni col
committente e la roba in mano (otto tipi, torta fragile), economia (berlina
€100, spese −1/6), 28 clip della libreria tradotte su omini e umani, la
parlata che finisce.

## Le verifiche

- Batteria completa (`tools/sh/batteriac.sh`, 52 prove più `prova_scopa`):
  **tutte a zero storte, zero `SCRIPT ERROR`**, con due note.
  `prova_vigile` al primo giro dava 1: aspettava 400 fotogrammi che
  sparissero *tutti* i vigili, ma dalla 0.62 ce ne sono anche nelle altre
  piazze e fanno più strada per andarsene — la prova adesso controlla che
  smontino tutti e aspetta fino a 1800 fotogrammi. `prova_guagliune_vere`
  ogni tanto dà 1 al mercato (2 clienti in quattro minuti, la soglia è 3):
  rifatta due volte sulla 0.62 (0 storte, 4 clienti) e una sulla 0.61
  (0 storte, 3 clienti) — è una prova al limite, non un guasto nuovo; in
  roadmap.
- Fotografie: HUD (`foto_hud`), pannelli (`foto_pannelli`: negozio zio,
  bazar, tabacchi, bacheca, casa, partite, scassa, tutoriale, intro,
  riepilogo), scopa in gioco e vinta (`foto_ui`), lotto (`foto_lotto`),
  commissioni pizze e torta (`foto_cummissione`), clip tradotte
  (`foto_retarget`) e animatore vero (`foto_animatore`).
- Le foto dei pannelli hanno trovato quattro guasti che le prove non
  vedevano: il negozio sopra alla scheda dei soldi, il pannello di casa che
  usciva dallo schermo, la schermata d'inizio coi comandi tagliati (altezze
  scritte a mano per il font vecchio), il riepilogo senza sfondo.

## Rimasto aperto

Vedi `ROADMAP.md`, «Rimasto aperto dalla 0.62»: la prova delle dieci
giornate, l'economia nuova da giocare, la sala scommesse fuori tema, il
panaro, la traversata a piedi, il repository che senza `.glb`/`.wav` non
basta da solo.
