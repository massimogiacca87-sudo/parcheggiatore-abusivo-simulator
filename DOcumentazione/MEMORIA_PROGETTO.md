# MEMORIA DEL PROGETTO — Parcheggiatore Abusivo Simulator

**Per il "nuovo me" che apre la chat successiva.** Aggiornato il 27 settembre
2026, alla chiusura della **v0.65 · 'A scala d''e guaie**. Tutto quello che
serve per ripartire da qui senza aver visto la chat precedente.

Ordine di lettura consigliato: questo file → `COME-RIPRENDERE.md` (manuale
operativo lungo, con le trappole) → `RIASSUNTO-CHAT-v0.65.md` (cronaca della
chat) → `ROADMAP.md` → `NOVITA-v0.65.md`. L'obiettivo del capo sta in
`VISIONE.md` (lo *Schedule I* napoletano); il suo studio multi-agente in
`STUDIO-MULTIAGENTE.md` (committa nello stesso repository: vedi
`COME-RIPRENDERE.md` 1.1c). Tutti stanno in `DOcumentazione\` sul computer del capo
e nei documenti del progetto claude.ai (`claude/…`).

---

## 0. RIPARTIRE IN CINQUE RIGHE

1. **Una cartella sola, Git** (dalla 0.62): il repository è
   `C:\Users\Max\Downloads\Parcheggiatore Abusivo Simulator\`, il progetto
   Godot è `Progetto\parcheggiatore-abusivo\`, i documenti `DOcumentazione\`,
   le build `Build\`. **Vietato creare cartelle numerate.**
2. Nel contenitore nuovo: sul computer `tar -cf _claude_tmp\progetto.tar -C
   Progetto parcheggiatore-abusivo` (Desktop Commander, PowerShell),
   `device_stage_files`, `tar -xf` in `/home/claude` → nasce
   `/home/claude/parcheggiatore-abusivo`; (dalla 0.64) a-capo portati a LF,
   poi `git init`, commit, `git tag pc_sync` (vedi `COME-RIPRENDERE.md` 1.1).
3. Godot 4.3 stabile in `/home/claude/godot4`, `xvfb-run` per le foto,
   `cp tools/sh/*.sh /tmp/ && chmod +x /tmp/*.sh`.
4. Batteria di prove, in due metà insieme: `PARTE=1 nohup /tmp/batteriac.sh &`
   e `PARTE=2 …` → `/tmp/batteriac_1.txt`, `/tmp/batteriac_2.txt` (attese
   tutte a zero storte, circa un'ora).
5. Ogni lavoro finito e provato = un commit nel contenitore → `tools/sh/sincro.sh`
   fa le patch → `device_commit_files` in `_claude_tmp\` → `git am
   --directory=Progetto/parcheggiatore-abusivo` sul computer (1.1b).

---

## 1. ARCHITETTURA

### 1.1 Il concept

Simulatore in prima persona, open world, di un **parcheggiatore abusivo a
Napoli**. Il giocatore gestisce una piazza di sosta abusiva in un quartiere
napoletano generato a codice (190 × 172 m, più Mergellina, il Vomero rialzato
e il golfo come scenografia). Tono satirico e affettuoso; **tutti i testi di
gioco sono in napoletano vero** (elisioni `d''o`, `d''a`, `ll'`). Direzione
decisa: *simulatore di carriera* (conquistare le piazze, assumere guagliuni,
battere i boss) con dentro la struttura di **'A jurnata** (il conto della
sera, la casa, la famiglia come freno).

### 1.2 Il core gameplay loop

**Una giornata = 7 minuti e mezzo reali**, da mezzogiorno alle 4:00, divisa in
**cinque fasce** (quante auto arrivano e quanto lasciano; la sera paga di più).

1. **Mattina**: si esce dal vascio (casa, con la moglie Nunzia e due figli);
   sulla porta c'è **'o biglietto** con il tipo di giornata (normale,
   partita, pioggia, mercato, processione, primo del mese).
2. **In piazza**: le auto arrivano; con [E] si **dirige** l'auto nel posto
   (minigioco di guida a gesti, `directing_*`), e si incassa. La paga dipende
   da reputazione, fascia, clienti fissi (6 con nome e memoria, uno su tre),
   oggetti comprati (gilet, occhiali, ombrellone…).
3. **L'autista scende e va a fare la spesa** in una delle 30 vetrine
   (commissione), torna, riparte. Se trova **multa, stemma rubato o
   rigatura** ti cerca (32 m, 28 s) e si apre il **confronto** (dialogo a
   risposte, o mazzate).
4. **Il vigile** guarda: sospetto per quello che fa e per quanto a lungo lo
   vede lavorare, verbali; alle 20 smonta. **Calore/stelle** → carabinieri;
   al terzo fermo si passa la notte **in galera**.
5. **Violenza**: pugni e armi (armiere), consumano **'o sciato** (fiato);
   le **ossa** si ricomprano (cornetto, solo di notte).
6. **Soldi extra**: bacheca (lavoretti, pacchi), **furto d'auto** (minigioco
   dello scasso, guida fino al garage dello sfasciacarrozze, ricettatore che
   paga −32% a ogni auto della stessa giornata), collezione dei 6 manifesti.
7. **Azzardo** (tutto sotto il 100%): scopa, tre carte, lotto con smorfia e
   Signora d''e nummere, scommesse con partite virtuali, slot.
8. **Carriera**: quattro piazze (la tua, lo stadio, il mercato, la
   cornetteria) con rivali e **boss di capitolo**; guagliuni assunti che
   crescono e se ne vanno; Borrelli (caricatura satirica) come boss fisso.
9. **Sera**: si torna al vascio, si consegna, **'o conto** (luce, spesa,
   dentista…), si dorme → giornata dopo.

### 1.3 Le tecnologie

- **Godot 4.3 stable** (`4.3.stable.official.77dcf97d8`), **solo GDScript**,
  tutto **procedurale a runtime**: una sola scena, `scenes/Main.tscn`.
- Renderer: Forward+ (Vulkan) su desktop, `gl_compatibility` per mobile/web
  (`project.godot`: `rendering_method.mobile="gl_compatibility"`); build Web
  per itch.io; su Windows c'è `AVVIA-COMPATIBILITA.bat` (`--rendering-driver opengl3`).
- **Due autoload**: `GameManager` (`scripts/autoload/game_manager.gd`, stato
  + 73 segnali + salvataggio JSON in `user://`) e `SoundManager`
  (`scripts/autoload/sound_manager.gd`). (Dalla 0.64 Dialogic e LimboAI
  hanno un `.gdignore` e l'autoload di Dialogic è tolto: i plugin
  installati e non usati non partono.)
- **115 script**, circa 67.500 righe (alla 0.64).
- Attrezzi: `tools/*.py` (mappa `pianta.py`, audio `gen_audio.py`, texture),
  `tools/blender/` (modelli), **58 prove** `tools/prova_*.gd` (autoload
  iniettato in `project.godot` da uno script, stampano `=== storte: N ===`),
  **foto** `tools/foto_*.gd` (xvfb + opengl3, PNG in `/tmp`), **sonde**
  `tools/sonda_*.gd`, script shell in `tools/sh/`, recupero da `.pck` in
  `tools/recupero/`.
- Ambiente di lavoro: contenitore Linux nel cloud (si azzera: tutto va
  consegnato); ponte col PC di Massimo (`mcp__remote-devices__*`: list, stage,
  commit; dalla 0.60 anche Desktop Commander con PowerShell, con cui le
  versioni vecchie si mandano **nel Cestino**, mai cancellate per sempre).

---

## 2. STATO ATTUALE — v0.65

### 2.0000 La 0.65 in breve (27 settembre, pomeriggio)

Due richieste del capo: 1) **le mani in prima persona che fanno i gesti
mentre dirigi un'auto** (perse alla 0.54, quando si buttarono le braccia
finte doppie); 2) **le spese non pagate che si accumulano giorno dopo
giorno** con conseguenze disastrose ed esilaranti (la moglie che se ne va
coi figli e si tiene la casa, la luce staccata) fino al **game over dopo
una settimana senza pagare** — «così si bilancia anche l'economia e il
fatto delle auto rubate».

Fatto (dettagli in `NOVITA-v0.65.md`):
- `scripts/mani_fp.gd`: mani a pezzi appese alla telecamera, solo durante
  la regia; un gesto per tasto (W, S, A/D, F), botta, park-assist, pollice
  su, palme al cielo; la paletta in mano se comprata; il fierro scende
  (`arma_fp.nascosta`). `player_fps._aggiorna_mani()` dà il gesto.
- **'A scala d''e guaie** in `game_manager.gd`: un gradino per sera con
  spese aperte — bigliettino, luce, gas, Donna Cuncetta (`suocera_3d.gd`),
  Nunzia che si tiene casa e criature (porta chiusa, cartoni, soldi sotto
  la porta: `porta_casa`, `vascio_3d.apri_fore`, `pannello_casa`),
  l'avvocato, **FERNUTA** al settimo (`fernuta.gd`, «Ricumincia da
  capo» con `GameManager.ricomincia_da_capo`). Pagare tutto riporta a
  terra. HUD: riga del debito sotto «STASERA CE VONNO».
- Economia: spese fisse +30%, 'o cunto d''o salumiere, il digiuno che non
  scattava mai.
- Prove `prova_mani_regia`, `prova_scala_guaie`; foto `foto_mani_regia`,
  `foto_guaie`.

### 2.000 La 0.64 in breve (27 settembre)

Richiesta del capo in tre tempi: 1) **provare che la conquista delle altre
piazze funziona** (coi soldi e coi pugni) e che una piazza presa lavora
come quella di casa; 2) due idee nuove col suo twist: **'O Rre d''e
Parcheggi** (dal terzo giorno un figuro inventato da zero ti sfida: un
minuto, musica e tic tac; ≥5 posteggiate → una piazza in omaggio, ≥3 → un
guaglione, 1 → ti insegue e ti mena: «ma arò t'avvie omm' 'e sfaccimma, va'
a faticà va'») e **'E Strisce Blu** (certe mattine il Comune pitta le
strisce blu con i parchimetri in una tua piazza: si sfasciano i
parchimetri e si ripittano i posti di bianco con la pittura del bazar,
se no i clienti non pagano o fanno come «fuori dalle strisce»); 3) **i
rimasti aperti** delle versioni prima.

Fatto (dettagli in `NOVITA-v0.64.md`):
- `prova_conquista` gioca la conquista nella città vera: nove guasti trovati
  e chiusi (servizio che non partiva comprando da dentro, cartello col
  vecchio padrone, primo cliente lento, mercato con 4 posti → 8 con la
  fila di fondo, arredo sopra ai posti dello stadio, posti murati spenti,
  code che s'incastravano, `zona_persa`…);
- `re_parcheggi_3d.gd` (Don Vicienzo Cuoppo: corona, mantello, sigaro,
  paletta), `sfida_hud.gd`, la tarantella della sfida; regole in
  `game_manager.gd` («'O RRE D''E PARCHEGGI»); la piazza in omaggio non
  arma il boss di capitolo;
- `parchimetro_3d.gd`, `strisce_blu.gd`, la pittura al Bazar (tasto 7);
- rimasti chiusi: la prova che gioca dieci giornate (`prova_dieci_giornate`,
  bot onesto), la sala scommesse col tema, il balcone del panaro, il
  fazzoletto delle signore sedute, le botteghe della piazza di casa come
  mete, le trenta vetrine fotografate e aggiustate, le pozzanghere nel
  browser, i plugin non usati spenti;
- trovati guardando: **Borrelli aveva la faccia sulla nuca** (e gli occhiali
  di chi va in motorino e dello Zio), braccia sbagliate col vecchio
  `hold_bone` → `animator.punta_osso`.

### 2.001 La 0.63 in breve

**'O Duttore**: Borrelli non usciva più (la sera diceva sempre di no, la
radio del vigile si scaricava dopo la prima chiamata). Adesso due porte col
dado che cresce (la sera dal secondo giorno, 5% +5% al giorno; la chiamata
del vigile ai carabinieri, 1% +10 a chiamata), il vigile mandato via tre
volte chiama; Borrelli non si tocca con le armi, si calma con sigaretta o
caffè e si convince con le criature. Prove `prova_borrelli`,
`prova_borrelli_gioca`.

### 2.00 La 0.62 in breve

Nove richieste del capo dopo una partita: 1) UI intera più leggibile e bella
(le scritte dei tasti coprivano il resto), 2) lo stemma col G non andava, 3)
scopa con carte HD, tabellone e «sfida sbloccata», 4) il vigile sparito, 5)
salto e arrampicata sempre (niente incastri), 6) lotto incomprensibile, 7)
commissioni affidate da un personaggio con la roba vera, 8) economia (auto
rubata ~€100), 9) animazioni ai corpi nuovi. Tutto fatto (dettagli in
`NOVITA-v0.62.md`). A metà versione il capo ha spostato tutto in **una
cartella sola con Git** (niente più `Claude outputs\vX`).

**Seconda metà (26 settembre, chat a parte)**: il capo ha chiesto di fare la
build della 0.62 e di **integrare gli asset esterni** che un'altra sessione
aveva messo in `assets/esterni/` (+ tre plugin in `addons/`). Entrato quello
che si vede o si sente e non fa doppione: asfalto PBR e muffa (`Tex.PBR`),
decalcomanie e arredo (`scripts/robba_esterna.gd`: tombini, olio, colature,
graffiti, Vespe/scooter al cordolo, sedie di Vienna, coni, bidoni, casse),
lo split rifatto a codice (il modello era un palazzo in miniatura), dodici
suoni (`tools/prepara_esterni.py`), filtri dello schermo e la botta
(`filtri_schermo.gd`), pozzanghere solo Forward+ (`pozzanghere.gd`), sei
corpi Quaternius (`Human.QUAT`, `quat_ual.res`), il borsello in uscita, la
pagina dei crediti. **Plugin installati ma non usati** (ProtonScatter,
Dialogic, LimboAI: il perché in `NOVITA-v0.62.md`). Tabella completa in
`assets/esterni/ASSET-ESTERNI.md`.

### 2.0 La 0.61 in breve

Richiesta del capo dopo una giornata giocata: A) i guagliuni non
funzionano, B) le armi non si vedono e non si capisce se si usano, C)
ribilanciare l'economia («un'auto rubata vale tantissimo»); poi rifinire e
arricchire. Fatto (dettagli in `NOVITA-v0.61.md`):
- guagliuni che lavorano in tutte e quattro le piazze (sette guasti trovati
  con `prova_guagliune_vere`), la sera ti aspettano al posto loro;
- `arma_fp.gd`: il fierro in prima persona con colpi, vampata, scia,
  crocetta sul mirino (`GameManager.colpo_a_segno`), `audio/sparo.wav`;
- economia su `GIORNATA_TIPO` = 80: auto rubate 36–110, tre al giorno,
  stemmi 10/7/8, `RESA_DIPENDENTE` 0,75;
- `testimoni()` sui furti; `zona_corrente` in GameManager;
- Gennarino 'o Nuovo, 'o turista spierzo, 'o panaro 'e Donna Filumena
  (`citta_3d._build_personagge_nove`), consigli e battute nuove, una pagina
  di tutoriale.

Quello che segue è lo stato scritto alla 0.60, ancora valido.


### 2.1 Dove siamo

- Versione **v0.60 · 'A città vestuta**, chiusa. `const VERSIONE :=
  "v0.60"` in `scripts/caricamento.gd` e `scripts/hud.gd` (si cambia in tutti
  e due).
- Richiesta del capo per la 0.60: un secondo giro sulle cose aperte della
  0.59 (galera dentro alla città, posa rigida dell'umano, ragazzini
  piantati, ringhiere pesanti), la pulizia delle versioni vecchie (*«Tieni
  sempre dalla v0.53 in poi e non toccare mai le librerie di asset»*), e
  *«integra più asset nuovi che puoi, rendi in generale il mondo di gioco
  più dettagliato possibile. La prossima build la dedicheremo invece a
  rifinire il gameplay.»*
- Fatto: **la galera è un isolato** (`ISOLATO_GALERA = [133,156,155,168]`,
  sud-est del Vomero, portone a nord, `GALERA_FORE = (144,3,156)`,
  `GALERA_VERSO = (0,0,−1)`); **l'umano_q fermo** ha la clip `Fermo`
  costruita col suo scheletro (la sua `Idle` è una guardia); **i ragazzini**
  non si piantano (tiro a 0,9 m, palla incastrata, palla fuori campo) e
  `prova_ntuppate` non accusa più chi va e torna; **gruppi a quadretti** di
  32 m (`QUADRETTI`, `_flush_a_quadrette`): triangoli in vista da 3,9 M a
  1,1–2,2 M, e le tazzulelle dei bar di nuovo visibili; **58 modelli PSX
  nuovi** (457 in tutto, zero mai usati): bassi, sedie fuori con signore
  sedute, materassi, divani, bagno chimico, libri usati, cicche, e dentro a
  bar, tre carte, scopa, sale, garage, armiere, vascio (`robba_psx.gd`);
  **tetti di coppi** (`tools/genera_coppi.py`, la texture vecchia era un
  collage aereo di Venezia) e tetti piani senza z-fighting.
- **Prove**: batteria completa a **zero storte** (eccezioni che non sono
  guasti: `prova_braccia` stampa `fernuto`; `prova_manella` e `prova_pose`
  hanno un'ultima riga diversa).
- **Consegnato** in `Claude outputs\v0.60\`: `PAS-v0.60-Windows.tar.xz.0*.part`,
  `PAS-v0.60-Web-itchio.zip.0*.part`, `PAS-v0.60-Progetto.tar.xz.0*.part`,
  `UNISCI.bat`, `LEGGIMI.txt` e i documenti.

### 2.2 Gli script principali

| script | righe | cosa fa |
|---|---|---|
| `scripts/main.gd` | — | radice di `Main.tscn`: crea `caricamento` (schermata di caricamento), `Citta` (`citta_3d.gd`), il giocatore (`player_fps.gd`), l'HUD (`hud.gd`), l'intro, la volata iniziale; gestisce il risveglio (dopo la galera: `GALERA_FORE + GALERA_VERSO * 2.2 + (0,0.6,0)`, davanti al portone) |
| `scripts/autoload/game_manager.gd` | 6.330 | **il cervello**: soldi, calore, reputazione, giornata e fasce, turni, conto della sera, oggetti, fermi e stelle, piazze e boss, il Rre e le strisce blu (0.64), salvataggio JSON; **73 segnali** |
| `scripts/autoload/sound_manager.gd` | — | effetti (pool di `AudioStreamPlayer`), musica con dissolvenza su due giradischi, ambiente, volumi in `user://audio.cfg` |
| `scripts/citta_3d.gd` | 8.770 | **costruisce tutta la città**: tabelle `STRADE`, `ISOLATI`, `SLARGHI`, `ZONE`, `VARCHI`, `ISOLATO_GALERA`; facciate e isolati, bassi (`_vascio_pt`), piazze (`zone_vicolo_3d.gd`), vetrine, verde, arredo, galera, collina, gruppi a quadretti; catasto delle cose `_ingombri`; `_solido`, `_sta_libero`/`_perche_nun_sta`, `_batched`/`_flush_batch` (MultiMesh) |
| `scripts/zone_vicolo_3d.gd` | 3.400 | una piazza giocabile: posti auto, rivale, munnezza, bacheca, arredo del vicolo; (0.64) il servizio quando la piazza è tua, la coda, le botteghe della piazza di casa |
| `scripts/posteggio_3d.gd` | 610 | la piazza di casa: posti, rubinetto delle macchine, (0.64) la sfida del Rre |
| `scripts/re_parcheggi_3d.gd` | 1.040 | **(0.64)** 'O Rre d''e Parcheggi |
| `scripts/parchimetro_3d.gd`, `strisce_blu.gd`, `sfida_hud.gd` | 380, 245, 160 | **(0.64)** i parchimetri, le strisce blu, il cronometro della sfida |
| `scripts/car_3d.gd` | 3.170 | le auto: arrivo, sosta, pagamento, danni, furto, guida |
| `scripts/driver_3d.gd` | 1.300 | l'autista: scende, fa la spesa, torna, cerca, confronto (stati `EXITING…CERCA`) |
| `scripts/player_fps.gd` | 2.330 | il giocatore (`CharacterBody3D`, prima persona, interazioni, `GRUPPI_BERSAGLIO`) |
| `scripts/hud.gd` | 3.720 | interfaccia (barre, soldi, orologio, pannelli, versione) |
| `scripts/vascio_3d.gd` | 1.350 | la casa: porta nel vicolo, stanza a (300,0,300) fuori pianta, famiglia, letto, consegna |
| `scripts/vigile_3d.gd` | 1.100 | il vigile: ronda, sospetto, verbali, pausa al bar, smonta alle 20 |
| `scripts/passante_3d.gd` | 770 | i passanti: corpo fisico, tappe, strada A*, recupero se piantati, mestieri |
| `scripts/human_builder.gd` | 750 | costruisce le persone (pupo/omini/umano_q), vestiti, clip fisse, la clip `Fermo` dell'umano_q (`_prepara_fermo`) |
| `scripts/animator.gd` | 590 | animazioni: tabella clip per scheletro, `set_speed` (misura la velocità vera), `action`, `sit`; (0.64) `punta_osso`/`lascia_osso` |
| `scripts/passo.gd` | 350 | `class_name Passo`: il passo di chi cammina **senza fisica** (autisti, vigili, bambini, signora, Borrelli, carabinieri): dritto → strada A* → striscia → esci, con valvola |
| `scripts/cammino.gd` | 340 | griglia A* da 1 m (`AStarGrid2D`) con palazzi, cose e Vomero; «corda tirata»; `strada`, `raggiungibile`, `vicino_raggiungibile` |
| `scripts/ostacoli.gd` | 300 | registro dei corpi solidi (censiti a città fatta e 1,5 s dopo), `dentro`, `fore` |
| `scripts/golfo.gd` | — | scenografia: costa, palazzi finti, colline, Vesuvio (non tocca il vascio: `VascioScript.tocca_a_stanza`) |
| `scripts/collina.gd` | — | `class_name Collina`: il Vomero a quota 3 m, `RECT`, `IMBOCCHI`, `alzata` |
| `scripts/models.gd` | — | `class_name Models`: carica i modelli (sezione 3) |
| `scripts/textures.gd` | 430 | `Tex`: materiali e texture (sezione 3) |
| `scripts/robba_panda.gd` | — | cassette di frutta Pandazole e tinte (`TINTA_FRUTTA`) |
| `scripts/robba_psx.gd` | 400 | **(0.60)** la roba PSX in città, messa per ultima col suo seme: sedie davanti ai bassi, signore sedute, cantieri (bagno chimico, mattoni, tanica), saracinesche dell'acqua, munnezza, bancarelle di libri, cicche; `_tinto` per ritingere un modello |
| altri | — | `bambini_3d`, `pallone_3d`, `guaglione_3d`, `rivale_3d`, `borrelli_3d`, `carabinieri_3d`, `mergellina`, `jurnata_vista` (giornate speciali), `scopa_*`, `tre_carte_3d`, `sala_scommesse_3d`, `pannello_*`, `mappa.gd`, `caccia.gd`, `giorno_notte.gd`, `posto_utile.gd`, `fermo_3d.gd`, `garage_3d.gd`, `armiere_3d.gd`, `cornetteria_3d.gd` … |

### 2.3 Come comunicano

- **Creazione**: `main.gd` istanzia gli script con `Script.new()` +
  `add_child`. `citta_3d._ready()` chiama in ordine i `_build_*` (luce,
  terreno, confini, pavimentazione, isolati, piazza, zone, panorama,
  fondale, Mergellina, vita di vicolo, vetrine, verde, vita, manifesti,
  murales, attività, armiere, maestro, vascio, scopa, commissioni, gente
  ferma, vicinato, signora, cartelli, fumo, **`_build_arredo_novo` per
  ultimo**), poi `_alza_collina`, `_build_collina`, `_flush_batch`.
- **GameManager è il centro**: chi fa qualcosa chiama un suo metodo o emette
  un suo segnale (`money_changed`, `heat_changed`, `shift_ended`,
  `event_started`, `casa_entrata`, `stelle_cambiate`,
  `rientro_forzato_segnale`, `boss_capitolo_arriva`…); HUD, musica e
  personaggi ascoltano. **Mai lambda sui segnali degli autoload** (sempre
  metodi nominati).
- **Gruppi** per trovarsi: `player`, `citta`, `cars`, `passanti`, `drivers`,
  `vigili`, `bambini`, `vascio`, `negozi`, `posti_utili`, `banco_bar`,
  `garage`, `operai`, `attivita`… (`get_first_node_in_group`,
  `get_nodes_in_group`).
- **Script statici condivisi** (preload o `class_name`): `Citta` (tabelle e
  domande sulla pianta: `dint_ô_palazzo`, `in_corsia`, `dentro_varco`,
  `uscite_d_ô_palazzo`), `Passo`, `Cammino`, `Ostacoli`, `Collina`, `Models`,
  `Tex`, `Human`.
- **Movimento**: giocatore, auto e passanti col motore fisico
  (`move_and_slide`); tutti gli altri NPC con `Passo.verso(self, meta,
  v*delta)` (che usa `Citta.ISOLATI` + `Ostacoli` + `Cammino`).
- **Convenzioni**: `forward(θ) = (−sinθ, 0, −cosθ)` (il +Z locale è
  dietro); i pezzi Pandazole guardano a +Z (`giro = atan2(fuori.x,
  fuori.z)`); le auto hanno il muso a −Z; `global_position` solo dopo
  `add_child`.

---

## 3. MAPPATURA ASSET

| cartella | contenuto | come si carica |
|---|---|---|
| `res://assets/models/` | **221 `.scn`** (auto, arredo, PSX pack, personaggi — recuperati dal `.pck` della 0.58 come scene native), **178 `.mesh`** (Pandazole, una per pezzo, materiale unico), **58 `.glb`** (PSX della 0.60, con `.import` e le loro texture; da che file vengono: `tools/esame_psx/NOMI-v0.60.md`), **287 `.png`/`.jpg`** di texture dei modelli, `pandazole.png` (atlante desaturato), `omo_mosse.res` e `umano_q_mosse.res` (librerie di animazione), `pupo.scn`, `omo_*.scn` (8 uomini = 4 vestiti × liscio), `umano_q.scn` + `umano_q_1…6.png` | `Models.spawn(nome, altezza)` / `Models.spawn_by_length(nome, lunghezza)`: cercano `res://assets/models/<nome>` con le estensioni `.glb .gltf .tscn .scn .obj .mesh .fbx .dae` (nell'ordine); se non c'è tornano `null` e chi chiama costruisce la scatola procedurale. Poi `Models.tint`, `polish_vehicle`, `stacca_ruote`. In città i pezzi Pandazole passano da `_panda(nome, pos, giro, gruppo…)` → `_batched` → MultiMesh. Le persone: `HumanBuilder.build(camicia, pantaloni, …, {"modello": "umano_q", "clip": "Working"})` carica `res://assets/models/<modello>.scn` |
| `res://assets/textures/` | 35 texture (`coppi` e `coppi_x` disegnate da `tools/genera_coppi.py`, le altre fotografiche: `asfalto`, `basolato`, `cotto`, `marciapiede`, `maioliche`, `graffiti`, `manifesti`, `murale_*`, `muro_*` dei quartieri, `serranda`, `portone`, `piperno`, `muro_tufo`, `mare_normale`, `mare_schiuma`…) | `Tex.mondo(nome, tinta, ruvidità)` (UV in metri del mondo, `Tex.metri_di`), `Tex.get_material(nome, uv_scale, ruvidità)`, `Tex.facciata(…)`, `Tex.ground(…)`, `Tex.flat(colore, …)` (senza texture); `Tex.bagna(q)` per la pioggia. Cache interna, `Tex.clear_cache()` |
| `res://assets/shaders/` | `cielo.gdshader`, `intonaco.gdshader`, `mare.gdshader` (riscritti nella 0.59: nel `.pck` non c'erano) | caricati dai rispettivi costruttori (cielo in `_build_luce`, intonaco sulle facciate, mare a Mergellina) |
| `res://assets/manifesti/` | le 6 immagini della collezione (date dal capo: marchi e volti riconoscibili, solo per build private) | `manifesto_3d.gd` |
| `res://assets/icone/` | icone degli oggetti dell'HUD (borsello, caffè, gilet, grimaldello, occhiali, ombrellone…) | `hud.gd` |
| `res://assets/splash_1.jpg`, `splash_2.jpg` | schermate | `caricamento.gd`, intro |
| `res://audio/` | **40 `.ogg`, 13 `.wav`, 5 `.mp3`** di effetti (+ `.import`) | `SoundManager.play("nome", vol, pitch)`: all'avvio carica ogni nome di `SOUND_NAMES` da `res://audio/<nome>.ogg|mp3|wav` (vince il primo che esiste); `play_uno`, `soldi`, `pugno`, `vuoto` |
| `res://audio/musica/` | brani (`base`, `boss`, `caccia`, `giorno`, `lavoro`…); la `tarantella` sta in `res://audio/tarantella.ogg` | dizionario `BRANI` in `sound_manager.gd`; `SoundManager.metti(nome, fade)`; la scelta la fa `regia_musicale.gd` |
| `res://assets/esterni/` | **(0.62)** la biblioteca libera (Poly Haven, ambientCG, Poly Pizza, Quaternius, Freesound, Kenney, godotshaders), con i `CREDITI_*.txt` per cartella e la guida `ASSET-ESTERNI.md`. **Fuori dall'esportazione** tranne quello che il gioco usa (`exclude_filter`) | i modelli con `Models.ESTERNI` (nome → percorso, guardato per primo da `_find_path`); le persone con `Human.QUAT`; texture, decalcomanie e suoni **derivati** in `assets/textures/pbr/`, `assets/textures/decal/`, `audio/` da `tools/prepara_esterni.py` (poi `--import`) |
| `tools/sorgenti/` | `PandaMat_originale.png` (atlante originale, con `.gdignore`) | non caricato: sorgente per `tools/tinge_pandazole.py` |

Note sugli asset:
- Gli originali dei pacchetti (Car Pack, Pandazole, Animated Men, Quaternius,
  PSX Mega Pack) stanno nella cartella del capo sul PC; la conversione si
  rifà con `tools/prepara_nuovi.gd` in un progettino a parte.
- Le scale dei modelli PSX stanno nei `.import` (`root_scale`), non nel codice.
- I nomi dei modelli si scrivono **per intero** (niente `"sacchetto_%d"`):
  `prova_asset` li cerca nel testo del codice.
- Un nome che non esiste più **non dà errore** (`spawn` → `null`).

---

## 4. TO-DO & BUG

### 4.1 Dove ci siamo fermati

**La 0.65 è chiusa e committata** (rimasti in `ROADMAP.md`, «Rimasto
aperto dalla 0.65»: il bilancio nuovo da giocare, le mani a scatole, Donna
Cuncetta che da lontano sembra un signore, la direttiva del designer da
discutere col capo). Dalla 0.64 restano:  (`ROADMAP.md`, «Rimasto aperto dalla 0.64»): il Rre da
provare a mano (le manopole `RE_PE_A_PIAZZA`, `RE_DURATA`, la velocità
delle macchine), la frequenza delle strisce blu (`STRISCE_BLU_PROB`), i
numeri delle dieci giornate da confrontare col capo (€130 d'incasso e €57
di spese al giorno per un onesto), la domanda «coi pugni» (a mani nude il
rivale non si stende, ed è voluto: se il capo vuole le mani, è una riga);
la traversata a piedi col panaro, il motorino con le chiavi. La prossima in roadmap è
**v0.66 'E vvoce** (voci, idle in prima persona, criature).

### 4.2 I primissimi 3 passi nella chat nuova

1. **Rimettere in piedi il progetto e verificarlo** (`COME-RIPRENDERE.md`
   1.1: `tar` della cartella `Progetto\parcheggiatore-abusivo` sul computer,
   stage, `tar -xf`, `git init` + tag `pc_sync`); Godot 4.3 in
   `/home/claude/godot4`; `cp tools/sh/*.sh /tmp/`; `nohup /tmp/batteriac.sh &`.
2. **Chiedere al capo cosa vuole nella 0.66**, se non l'ha già scritto.
3. **Un commit per ogni lavoro finito**, portato sul computer con le patch
   (`tools/sh/sincro.sh` + `git am`).

### 4.3 Regole del capo (Massimo), da non dimenticare

- Dialoghi del gioco in napoletano; **note (`NOVITA-vX.md`) e roadmap in
  italiano**, con le sezioni «Le trappole» e «La lezione».
- **Dalla 0.62: Git, una cartella sola**, vietate le cartelle numerate;
  task atomici, `git add` + `git commit` a ogni task finito e provato.
  Build in `Build\`. Quello che si cancella va **nel Cestino**; le
  librerie di asset non si toccano mai.
- Aggiornare sempre nei documenti del progetto `claude/NOVITA-vX.md`,
  `claude/ROADMAP.md`, `claude/COME-RIPRENDERE.md`.
- Preferisce file completi, pronti all'uso; poche domande, molto fare.

### 4.4 Le trappole che costano di più (le altre in `COME-RIPRENDERE.md`)

1. Un errore di sintassi in un file precaricato **non ferma il gioco**: lo
   spegne a pezzi. Dopo ogni modifica `godot4 --headless --path .
   --check-only --script res://scripts/x.gd` (lì «Identifier not found:
   GameManager» è normale) e contare gli `SCRIPT ERROR` delle prove.
2. In headless le istanze dei **MultiMesh non esistono**: prove che le
   guardano vanno con xvfb (`/tmp/provaxc.sh`).
3. Le **posizioni scritte a mano invecchiano** con la pianta: meglio
   leggerle dalla pianta (`_facciate_verso`, `_muro_dell_angolo`).
4. **Coordinate locali lette come globali** (tre volte finora).
5. **Le prove possono difendere il bug** (`prova_confronto` e
   `prova_commissione` nella 0.59): quando una prova passa per il motivo
   sbagliato, si riscrive la prova.
6. `Array.shuffle()` usa il caso globale; cambiare `MultiMesh.instance_count`
   butta le trasformazioni; una `.mesh` è un `MeshInstance3D` radice senza
   figli.
7. Il contenitore **si azzera**: consegnare sempre il progetto intero.
8. **Il nome non è la cosa** (0.60): `tetti_italiani.jpg` era Venezia,
   l'`Idle` di Quaternius è una guardia, un gruppo `strada_…` per
   `prova_quote` sta per terra. Un asset nuovo si guarda in foto prima di
   usarlo.
9. **Gli a-capo** (0.62): il repo del capo ha `core.autocrlf=true`; le
   patch si fanno con `tools/sh/sincro.sh` (copia normalizzata a LF), e chi
   riscrive un file in Python usa `newline=''`.
10. **La biblioteca esterna è esclusa dall'esportazione**: un asset di
    `assets/esterni/` usato davvero va tolto dall'`exclude_filter` dei due
    preset, se no nell'exe non c'è (e `spawn` torna `null` in silenzio).
11. **(0.64) Sull'osso della testa il davanti è +Z**: occhiali, barba,
    visiere vanno a +Z. Un personaggio si fotografa da davanti e da dietro
    (`tools/foto_modello.gd`).
12. **(0.64) `hold_bone` congela la posa di riposo**: per un braccio che
    tiene qualcosa si usa `animator.punta_osso(osso, direzione)`, e la cosa
    in mano segue la mano con un `RemoteTransform3D` senza rotazione.
13. **(0.64) I commit si fanno man mano**: spezzare a fine lavoro un diff
    grosso che tocca gli stessi file ha messo righe nel posto sbagliato; se
    tocca, ogni commit si prova avviando il gioco sui file dell'indice.
14. **(0.64) Un bot di prova deve stare dove sta un giocatore**: il primo
    bot delle dieci giornate si metteva in carreggiata e finiva
    all'ospedale.
