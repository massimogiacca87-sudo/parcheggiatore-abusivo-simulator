# Come riprendere il lavoro in una nuova chat

Stato al **24 settembre 2026**, versione **v0.61 · 'O juoco, rifinito**.

> **Aggiornamento 26/09/2026 — asset esterni pronti da implementare.**
> Nel progetto ci sono ora 3 plugin attivi (`res://addons/`: ProtonScatter, Dialogic, LimboAI, versioni per 4.3)
> e ~440 MB di asset CC0/open in `res://assets/esterni/` (modelli .glb, NPC animati, texture PBR, HDRI,
> decal, shader, audio, UI Kenney), già importati e collaudati ma **non ancora usati dal gioco**.
> Prima di toccarli leggere `res://assets/esterni/ASSET-ESTERNI.md` (cosa c'è, come si monta, 4 trappole:
> export escluso, versione Godot, LimboAI sul web, pozzanghere solo su PC). Elenco file per file:
> `res://assets/esterni/ELENCO-FILE-ESTERNI.txt`. Collaudo: `res://tools/test_asset_esterni/`.

Questo documento è scritto per **chi apre la chat nuova** (cioè per me, senza
memoria di questa). Si legge dall'alto: la sezione 1 dice cosa fare nei
primi dieci minuti, il resto è il manuale.

Documenti da leggere insieme a questo, tutti nella cartella del progetto:

| file | cosa c'è |
|---|---|
| `RIASSUNTO-CHAT-v0.61.md` | la cronaca della chat che ha fatto la 0.61: richieste, decisioni, pulizia delle versioni vecchie, cosa è rimasto aperto |
| `NOVITA-v0.61.md` | le note della versione (per il capo, in italiano, con trappole e lezione) |
| `ROADMAP.md` | cosa è fatto versione per versione, e cosa viene dopo (la 0.62 è **'E vvoce**, più i rimasti della 0.61) |
| `CHANGELOG.md` | una riga per versione, dalla 0.44 alla 0.61 |
| `PROMPT-NUOVA-CHAT.md` | il messaggio da incollare per aprire la chat nuova |
| `LEGGIMI.txt` | per il capo: cosa c'è nella cartella della versione e come si usa |

---

## 1. I primi dieci minuti

### 1.1 Il contenitore della chat nuova è vuoto

Il codice e gli asset **non stanno nei documenti del progetto** (sono troppo
grossi): stanno nel pacco completo della versione, sul computer del capo, in
`C:\Users\Max\Downloads\Parcheggiatore Abusivo Simulator\Claude outputs\v0.61\`:

- `PAS-v0.61-Progetto.tar.xz.00.part`, `.01.part`, … — **il progetto Godot
  intero**: `scripts/`, `scenes/`, `tools/`, `assets/` (tutti i modelli, le
  texture, gli shader), `audio/`, `project.godot`, `export_presets.cfg`, i
  documenti, e la cache `.godot/imported` (così non serve reimportare).
- `UNISCI.bat` — su Windows rimette insieme i pezzi e li scompatta.
- Le build giocabili: `PAS-v0.61-Windows.tar.xz.0*.part` e
  `PAS-v0.61-Web-itchio.zip.0*.part`.

**Per portarlo nel contenitore**, con il ponte del desktop acceso:

```text
device_list_dir  C:\Users\Max\Downloads\Parcheggiatore Abusivo Simulator\Claude outputs\v0.61
device_stage_files  (tutti i .part del Progetto; finiscono in /mnt/user-data/uploads/…)
```

Poi nel contenitore:

```bash
cd /home/claude
cat /mnt/user-data/uploads/*/PAS-v0.61-Progetto.tar.xz.*.part > /tmp/progetto.tar.xz
tar -xJf /tmp/progetto.tar.xz          # crea /home/claude/parcheggiatore-abusivo
```

Se il ponte è spento: chiedere al capo di allegare i pezzi alla chat (vanno
in `/mnt/user-data/uploads/`), stessa procedura. **Il percorso conta**: tutti
gli script di prova hanno scritto `/home/claude/parcheggiatore-abusivo` e
`/home/claude/godot4`.

Se il pacco completo non si trova, l'ultima spiaggia è quella usata nella
0.59: estrarre il `index.pck` della build web con
`tools/recupero/estrai_pck.py` (e `mux_ogg.py` per l'audio). Gli shader nel
`.pck` non ci sono e vanno riscritti — sono tre, in `assets/shaders/`.

### 1.2 Godot e gli attrezzi

```bash
# Godot 4.3 stabile (binario ufficiale Linux, ~110 MB)
cd /tmp && curl -L -o godot.zip \
  https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip
unzip -o godot.zip && mv Godot_v4.3-stable_linux.x86_64 /home/claude/godot4 && chmod +x /home/claude/godot4
/home/claude/godot4 --version      # 4.3.stable.official.77dcf97d8

# I modelli di esportazione servono SOLO per le build (~1 GB, scaricano in
# una ventina di secondi)
curl -L -o tpl.tpz \
  https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_export_templates.tpz
mkdir -p ~/.local/share/godot/export_templates/4.3.stable
unzip -o tpl.tpz -d /tmp/tpl && mv /tmp/tpl/templates/* ~/.local/share/godot/export_templates/4.3.stable/

# Per le fotografie (xvfb + opengl3) e per gli script python
which xvfb-run || apt-get install -y xvfb
python3 -c "import PIL, numpy" || pip install pillow numpy --break-system-packages

# Gli script di prova vivono in tools/sh/ e si usano da /tmp
cp /home/claude/parcheggiatore-abusivo/tools/sh/*.sh /tmp/ && chmod +x /tmp/*.sh
```

Se la cache `.godot/imported` non c'è (o si aggiungono asset nuovi):

```bash
cd /home/claude/parcheggiatore-abusivo && /home/claude/godot4 --headless --path . --import
```

**Mai insieme a una prova** (trappola 14).

### 1.3 Controllare che tutto sia come l'ho lasciato

```bash
nohup /tmp/batteriac.sh > /tmp/batteriac.log 2>&1 &     # ~45 minuti
cat /tmp/batteriac.txt                                   # una riga per prova
```

Risultato atteso alla chiusura della 0.61 (50 prove): **tutte a zero storte**, con tre
eccezioni che non sono guasti:

- `prova_braccia` stampa `=== fernuto ===` (è una misura, non un collaudo);
- `prova_manella` e `prova_pose` escono «nisciun risultato» perché la loro
  ultima riga ha un formato diverso (`prova_pose` finisce con `=== 0 clip
  mancante ncopp'a 20 ===`, che è il suo zero).

Le due prove nuove della 0.61 **giocano**: `prova_guagliune_vere` assume un
guaglione in ogni piazza e guarda quattro minuti (clienti, cassa, quanto
resta incastrato); `prova_perzone_nove` fa arrivare Gennarino, il turista e
il panaro e controlla che i soldi arrivino, più i cinque fierri.

`prova_ntuppate` guarda la città per due minuti con passanti che scelgono le
tappe a caso. Dalla 0.60 non confonde più chi va e torna con chi è piantato
(vedi `NOVITA-v0.60.md`, trappola 9): se esce 1, è un piantato vero — si
legge la riga `PIANTATO … vicino: …` e si guarda quel punto. Per i
ragazzini c'è `sonda_guagliune`, che stampa tutta la finestra di tre
secondi e lo stato del passo.

---

## 2. Le regole del capo (Massimo)

Valgono sempre, senza che le ripeta:

1. **Si parla napoletano nel gioco**: dialoghi, cartelli, scritte a schermo
   in napoletano vero (elisioni `d''o`, `d''a`, `ll'`). **Le note di
   versione e la roadmap sono in italiano** (dalla 0.58). I commenti nel
   codice sono in italiano, coi titoletti in napoletano.
2. **Ogni versione vuole**: `NOVITA-vX.md` (scritta raccontando anche gli
   sbagli: una sezione «Le trappole» e una «La lezione»), la `ROADMAP.md`
   aggiornata con la sezione «Fatto», e questo documento aggiornato. Tutti e
   tre **nei documenti del progetto** (`claude/…` con `project_write`) **e
   dentro al pacco**.
3. **Ogni versione si consegna intera** (istruzioni del progetto): una
   cartella con il progetto completo — modelli, texture, asset, tutto — più
   leggimi, changelog e i documenti per ripartire.
4. **Le versioni vecchie le cancello io** (istruzioni del progetto, dalla
   0.60): se ne tengono **almeno sei-sette**, e le più vecchie si tolgono man
   mano. Sempre **nel Cestino di Windows, mai definitivo**. E il capo: *«non
   toccare mai le librerie di asset (Car Pack, Low Poly, Animated,
   Pandazole, PSX, Quaternius)»*. Come si fa sta nella sezione 4.5.
5. **Consegna doppia**: i file con `SendUserFile` **e** scritti sul suo
   computer con `device_commit_files` in
   `C:\Users\Max\Downloads\Parcheggiatore Abusivo Simulator\Claude outputs\vX\`.
6. **I pacchi grossi si spezzano in pezzi da 19 MB** (`split -b 19000000`),
   con un `UNISCI.bat` accanto **con gli a capo CRLF**, se no Windows non lo
   esegue. `SendUserFile` regge 30 MB a file, il ponte 20 MB a file e 100 MB
   a chiamata.
7. Il capo **preferisce file completi**, pronti da incollare, ai pezzetti.

---

## 3. Com'è fatto

- **Godot 4.3**, tutto procedurale in GDScript. Una scena sola,
  `scenes/Main.tscn`. Due autoload: `GameManager` (stato, segnali,
  salvataggio JSON) e `SoundManager`. 103 script, circa 59.900 righe.
- La città è un rettangolo di 190 × 172 m: `STRADE`, `ISOLATI`, `SLARGHI`,
  `ZONE` (le quattro piazze) e `VARCHI` sono tabelle in cima a
  `scripts/citta_3d.gd`. Gli isolati li calcola `tools/pianta.py`.
- **Il Vomero** è un terrapieno alto 3 m (`_alza_collina`, rettangolo
  x 107–155, z 128–168). **La galera** è l'isolato `ISOLATO_GALERA`
  ([133, 156, 155, 168]) nel suo angolo di sud-est, col portone a nord;
  `GameManager.GALERA_FORE` = (144, 3, 156), `GALERA_VERSO` = (0, 0, −1).
- Il mondo fuori dalla pianta è scenografia: `golfo.gd` (costa, palazzi
  finti, colline, Vesuvio), e in `citta_3d.gd` il `_build_fondale`.
- **La casa (`vascio_3d.gd`) sta a (300, 0, 300)**, fuori dalla pianta: si
  entra e si esce teletrasportando il giocatore. Tutto quello che si mette
  lontano deve chiedere `VascioScript.tocca_a_stanza()`.

### I file grossi

| file | righe | cosa fa |
|---|---|---|
| `scripts/citta_3d.gd` | 8.450 | costruisce la città, l'arredo, le vetrine, i bassi, la galera, il catasto delle cose |
| `scripts/autoload/game_manager.gd` | 5.670 | tutto lo stato del gioco, soldi, giornate, salvataggio |
| `scripts/hud.gd` | 3.460 | interfaccia |
| `scripts/zone_vicolo_3d.gd` | 3.230 | una piazza: posti auto, rivali, munnezza, bacheca |
| `scripts/car_3d.gd` | 2.950 | le auto: arrivo, sosta, pagamento, furto, guida |
| `scripts/player_fps.gd` | 2.020 | il giocatore |
| `scripts/vascio_3d.gd` | 1.370 | la casa |
| `scripts/driver_3d.gd` | 1.300 | l'autista: scende, fa la spesa, torna, ti cerca |
| `scripts/passante_3d.gd` | 780 | i passanti (hanno un corpo fisico dalla 0.59) |
| `scripts/human_builder.gd` | 750 | costruisce le persone: pupo, omini, umano_q (con la clip `Fermo`) |
| `scripts/animator.gd` | 480 | le animazioni, con una tabella di clip per scheletro |
| `scripts/robba_psx.gd` | 400 | **(0.60)** la roba PSX in città: sedie dei bassi, signore sedute, cantieri, volantini, munnezza, libri, cicche |
| `scripts/passo.gd` | 345 | il passo di chi cammina senza fisica: muri, cose, strada |
| `scripts/cammino.gd` | 310 | la griglia A* da un metro e la «corda tirata» |
| `scripts/ostacoli.gd` | 295 | la rassegna di tutti i corpi solidi a città finita |
| `scripts/bambini_3d.gd` | 430 | i ragazzini del largo e il pallone |
| `scripts/arma_fp.gd` | 535 | **(0.61)** il fierro in prima persona: modellino, colpi, vampata, scia |
| `scripts/nuovo_abusivo_3d.gd` | 535 | **(0.61)** Gennarino 'o Nuovo, l'abusivo dell'abusivo |
| `scripts/turista_spierzo_3d.gd` | 417 | **(0.61)** il turista da accompagnare alla colonna gialla |
| `scripts/panaro_3d.gd` | 225 | **(0.61)** il panaro di Donna Filumena (+ `panaro_corpo.gd`) |

### I tre scheletri delle persone

- **'o pupo** (Universal Animation Library): lo scheletro di sempre, 43 clip,
  tabella `CLIP` in `animator.gd`. Tutte le donne sono pupi.
- **'e omini** (Low Poly Animated Men): otto uomini, quattro vestiti, undici
  clip in `assets/models/omo_mosse.res`.
- **l'umano_q** (Quaternius Animated Human): un corpo, sei vestiti, sette
  clip più `Fermo` (0.60), che si costruisce la prima volta in
  `_prepara_fermo`: la sua `Idle` è una guardia da pugile e non va usata
  per chi sta fermo.

`Human.build(camicia, pantaloni, …, {"modello": "umano_q", "clip":
"Working"})` restituisce sempre lo stesso dizionario (`root`, `anim`,
`bones`). **Nessuna clip si traduce da uno scheletro all'altro** (è quello
che rovinò la 0.47): si traducono i nomi.

### Come si mette la roba in città (0.59, con le aggiunte della 0.60)

1. Ogni corpo solido passa da `_solido(centro, dim, angolo)`, che lo rifiuta
   se sporge nella corsia libera (`in_corsia_girato`, con l'eccezione degli
   slarghi) e altrimenti lo segna in `_ingombri`. Si guarda
   `_solidi_scartati`: deve restare vuoto.
2. Prima di mettere qualcosa si chiede `_sta_libero(p, r)` (palazzi, varchi,
   corsia, **portoni**, piazze, catasto, gente ferma, vicini, attività) o
   `_scatola_libera(centro, dim, angolo)` per le cose lunghe. `_rifiuti` conta
   i perché. **Dalla 0.60** chi mette roba davanti alle facciate chiede
   anche se il punto sta dentro alla pianta (`RobbaPsx._dint_a_mappa`): le
   facciate del bordo guardano il muro di confine.
3. I pezzi ripetuti vanno in `_batched(tipo, mi)` (o `_pezzo`,
   `_pezzo_modello`, `_panda`, `_panda_t`, `_panda_c`): diventano MultiMesh.
   **Le coordinate passate sono del mondo, con y = 0**: la collina la
   aggiunge lui. Dalla 0.60:
   - i gruppi con un raggio in `_batch_vista` e quelli coi prefissi di
     `QUADRETTI` (`balaustrino_`, `split_`, `balcone_`, `bottega_`,
     `vaso_`, `giara_`) **si tagliano in quadretti di 32 m**
     (`_flush_a_quadrette`); per balaustrini e split oltre la distanza il
     pezzo diventa una scatola;
   - **il nome del gruppo conta**: `prova_quote` considera «da terra» i
     gruppi che cominciano con `Gruppo_strada_`. Roba appesa al muro non va
     chiamata `strada_…`;
   - `_panda_c` mette un modello **per il centro del suo ingombro** (molti
     modelli PSX hanno l'origine fuori centro);
   - `RobbaPsx._tinto` fa una copia ritinta di un modello (il bagno chimico
     blu).
4. I nomi dei modelli si scrivono per intero (`const SACCHETTI := [...]`),
   mai costruiti con `%d`: `prova_asset` li cerca nel testo.
5. **Il caso della città è uno solo** (il seme): una cosa nuova che pesca un
   numero dove prima non si pescava sposta tutto quello che viene dopo.
   Le scelte nuove si fanno col numero della campata o della posizione
   (`(indice + i) % 3`, `int(p.x * 7) + int(p.z * 13)`), o con un `rng`
   suo (come `RobbaPsx`, che gira per ultimo col suo seme).

---

## 4. Le trappole in cui sono già cascato

**Geometria e ossa**

1. **Rotazione**: `forward(θ) = (−sinθ, 0, −cosθ)`, cioè **+z è dietro**. Per
   guardare verso `dir`: `rotation.y = atan2(-dir.x, -dir.z)`. Per un nodo
   qualunque il davanti è il +Z locale: la stessa rotazione che gira una
   porta verso la strada gira un personaggio verso il muro. **I pezzi di
   Pandazole e del PSX hanno il davanti a +Z**: `giro = atan2(fuori.x,
   fuori.z)`. Le auto hanno il muso a −Z.
2. **Gli assi delle ossa si misurano** (`prova_manella`): `hand_r` sotto è
   +Y; `spine_03` e `Head` davanti è +Z.
3. **`hold_bone()` congela l'osso** vicino alla posa di riposo.
4. **In una mesh skinnata un arto non è un nodo.**
5. **`global_position` va messa DOPO `add_child()`**; dentro al tuo `_ready()`
   sei ancora all'origine.
6. **`Label3D` + billboard** vuole `billboard_keep_scale` sul materiale.
7. **Coordinate di un nodo lette come coordinate del mondo.** Tre volte: la
   porta del campetto (0.56), le cassette delle vetrine ammucchiate
   all'origine (0.59), la collina alzata due volte (0.59).
8. **`Basis(...).scaled()` scala sugli assi del mondo**, non su quelli del
   pezzo: per una lastra girata si usa `giro * Basis.from_scale(...)`.

**Godot in generale**

9. **Mai lambda sui segnali degli autoload.**
10. **`queue_free()` è differito**: in una foto serve `free()`.
11. **`add_child` sul genitore durante il `_ready` di un figlio** è rifiutato.
12. **Due track di posizione sullo stesso osso si sommano.**
13. **Niente apostrofi negli identificatori** (le lettere accentate sì).
14. **Gli asset nuovi non esistono finché non si importano**, e mai import
    insieme a una prova. Vale anche per un `class_name` nuovo.
15. **Una funzione con `await` è una coroutine**: senza `await` la prova
    stampa prima di aver provato.
16. **`pkill -f godot4` uccide la propria bash**: `pkill -x`, o `kill` col
    numero. E **non si cancella la copia su cui gira una prova**: il suo
    script, alla fine, rimette `project.godot` nella copia nuova.
17. **Un `CharacterBody3D` senza `CollisionShape3D` non esiste per la
    fisica**: non tocca terra e cade per sempre (i passanti fino alla 0.58).
18. **Cambiare `MultiMesh.instance_count` rialloca e butta le
    trasformazioni.** Si raccoglie tutto e si scrive una volta alla fine.
19. **In headless le istanze dei MultiMesh non esistono**: una prova che le
    guarda va fatta con xvfb (`prova_vascio_fondale` si rifiuta di girare
    senza; `provac.sh` e `batteriac.sh` la lanciano con xvfb).
20. **`Array.shuffle()` usa il caso globale**, non il tuo `rng`.
21. **Una `.mesh` caricata è un `MeshInstance3D` radice senza figli**:
    `find_children` non la vede.

**Del gioco**

22. **`get_shader_parameter` torna `null`** per un parametro mai scritto.
23. **Un parametro con lo stesso nome di un campo lo nasconde.**
24. **`GRUPPI_BERSAGLIO` in `player_fps.gd` è una lista chiusa.**
25. **`Animator.action()` su una chiave che non conosce esce in silenzio.**
26. **Il gioco parte in pausa**: le prove vogliono `PROCESS_MODE_ALWAYS` e
    `get_tree().paused = false`.
27. **I posti auto vanno sempre liberati** (`_release_spot()` anche in
    `_exit_tree()`).
28. **Chi cammina senza fisica usa `Passo.verso(self, meta, v * delta)`**:
    conosce palazzi e cose, chiede la strada alla griglia, ha una valvola
    (dieci secondi senza avvicinarsi → passa) e conta il tempo **in passi**,
    non in millisecondi.
29. **La colonna sinistra dell'HUD ha le `y` scritte a mano.**
30. **Le posizioni scritte a mano invecchiano con la pianta.** Meglio
    **leggerle dalla pianta** (`_facciate_verso`) o **cercarle a partire da
    un punto** (`_posto_pe_scena`). Vale anche per l'occhio delle
    fotografie: metterlo in una strada vera, non «a occhio».
31. **Il nome di un modello che non esiste più non dà errore**: `spawn`
    torna `null` e il posto resta vuoto.
32. **Un errore di sintassi in un file precaricato non ferma il gioco: lo
    spegne a pezzi.** Dopo ogni modifica:
    `godot4 --headless --path . --check-only --script res://scripts/x.gd`
    su ogni file toccato — lì «Identifier not found: GameManager» e
    «Compilation failed» sono normali (gli autoload non ci sono), i `Parse
    Error` no. E nella riga di `minic.txt` il conto degli `SCRIPT ERROR`
    deve essere zero.
33. **Scenografia dentro alla pianta.** La galera (dalla 0.56 alla 0.59) e i
    palazzi finti del golfo (fino alla 0.59, dentro al vascio) stavano sopra
    a roba vera. Chi costruisce deve far parte della pianta, o chiedere dove
    costruisce.

**Aggiunte nella 0.60**

34. **Il nome non è la cosa.** `tetti_italiani.jpg` era un collage aereo di
    Venezia; l'`Idle` di Quaternius è una guardia. Un asset nuovo **si
    guarda** (una foto da vicino) prima di usarlo.
35. **Il raggio di vista di un gruppo si misura dal suo baricentro**: per
    un gruppo sparso per la città è sbagliato (le tazzulelle erano
    invisibili). Oggi è risolto a quadretti; se si aggiunge un altro modo
    di disegnare gruppi, il problema torna.
36. **Due facce alla stessa quota** si mangiano a vicenda (le strisce dei
    tetti piani): tre centimetri di distacco.
37. **Una prova che guarda solo gli estremi** di una finestra accusa chi va
    e torna (`prova_ntuppate` fino alla 0.59).
38. **I nomi dei gruppi decidono cosa pensano le prove** (`Gruppo_strada_`
    = da terra, per `prova_quote`).

**Aggiunte nella 0.61**

39. **Una prova che guarda i numeri non guarda il gioco.** `prova_guagliune`
    era verde e il guaglione non funzionava. Per ogni meccanica che rende
    soldi ci vuole una prova che la **gioca** in città.
40. **Due copie della stessa regola** (`posteggio_3d` e `zone_vicolo_3d`
    hanno ognuna il suo rubinetto): una modifica va fatta in tutti e due.
41. **`in_servizio` vale in qualunque piazza tua.** Per sapere se il
    giocatore sta *in quella* piazza c'è `GameManager.zona_corrente` (0.61).
42. **Lo strato 4 è di auto E personaggi.** Chi chiede «ci sta una
    macchina?» deve scartare i `CharacterBody3D` che non sono `cars`.
43. **Chi viaggia dentro a un'auto non deve avere corpo** (`collision_layer
    = 0` a bordo): la capsula la solleva.
44. **La piazza di casa ha muri invisibili** (layer 1) attorno: chi nasce
    fuori e ci cammina dentro con `move_and_slide` resta appiccicato. Si
    nasce dentro.
45. **In prima persona si ruota attorno alla spalla**, non al pugno, e le
    pose si controllano **dove cadono sullo schermo** (`foto_armi`).
46. **Chi rifà il programma della giornata** (panaro, Gennarino, turista:
    `_programma()`) azzera quello che una prova gli ha dato prima: nella
    prova si scrive prima la giornata (`_giornata`/`_visto_oggi`).

### Come si prova

Quarantotto `tools/prova_*.gd`. Ognuna è un autoload temporaneo che stampa
`=== N storte ===` e chiude; lo script la infila in `project.godot`, la fa
girare e rimette a posto.

```bash
/tmp/prova.sh  prova_gente 150    # nel progetto, headless → /tmp/out_prova_gente.txt
/tmp/minic.sh  prova_a prova_b    # su una copia (/home/claude/copia) → /tmp/minic.txt
/tmp/provaxc.sh prova_x 260       # sulla copia, con xvfb + opengl3 (per i MultiMesh)
/tmp/batteriac.sh                 # tutte, su /home/claude/copia2 → /tmp/batteriac.txt
/tmp/foto.sh   foto_sessanta 420  # fotografie: xvfb, 1280×760, PNG in /tmp
```

Le copie servono a poter fare fotografie nel progetto mentre le prove girano.
Se una prova va in timeout nel progetto, `project.godot` resta con l'autoload
dentro: `cp /tmp/pg.bak project.godot` e togliere `scripts/_prova_*.gd` e
`scripts/_foto_*.gd`. **I comandi lunghi si lanciano con `nohup … &`**: la
bash dello strumento muore dopo due minuti, e con lei il Godot che ci gira
dentro (lasciando `project.godot` sporco).

`prova_scopa` è `extends SceneTree` e va con `--script`. Nell'output headless
ci sono migliaia di `Parameter "m" is null`: è il renderer finto, si
filtrano. **Gli altri `SCRIPT ERROR` no.**

Le prove da far girare dopo ogni ritocco alla città: `prova_arredo`,
`prova_asset` (457 modelli, zero mai usati), `prova_psx` (le misure dei 172
modelli PSX), `prova_ngombri` (niente dentro a niente), `prova_ntuppate`
(nessuno piantato; `DURATA_NTUPPATE=600` per guardare dieci minuti),
`prova_mure`, `prova_croce` (nessuno in posa a T), `prova_quote` (la roba a
terra sta a terra), `prova_conti` (istanze e triangoli, anche dentro al
raggio di vista), `prova_mira`, `prova_commissione`, `prova_confronto`,
`prova_vascio_fondale` (xvfb).

Le fotografie della 0.61: `foto_armi` (i cinque fierri fermi e a metà
colpo, `/tmp/arma_*.png`) e `foto_sessantuno` (Gennarino, il turista e il
panaro nella città vera, `/tmp/61_*.png`).

Le fotografie: `tools/foto_sessanta.gd` fa il giro della roba della 0.60
(galera da sei punti, sedie, signora, bancarelle, bagno chimico, garage,
bar, scommesse, armiere, ringhiere, tetti, vascio da fuori): `SOLO=galera,
segge` per farne solo alcune, `NOTTE=1` per la notte. `foto_umano_fermo`
fotografa l'umano fermo di fronte e di fianco; `foto_nove` e `foto_vascio`
sono quelle della 0.59. Le sonde (`sonda_sessanta` conta sedie, signore,
bancarelle, bassi e cantieri e stampa i rifiuti; `sonda_largo` le scatole
attorno al campetto; `sonda_guagliune` perché un ragazzino si pianta)
rispondono a domande singole.

**Che cosa deve provare una prova**: non che il codice giri — che il numero
sia giusto. E attenzione alle prove che difendono il bug (0.59) e a quelle
che accusano l'innocente (0.60).

### Build e consegna

```bash
cd /home/claude/parcheggiatore-abusivo
mkdir -p build/windows build/web
/home/claude/godot4 --headless --path . --export-release "Windows Desktop" build/windows/ParcheggiatoreAbusivoSimulator.exe
/home/claude/godot4 --headless --path . --export-release "Web" build/web/index.html
```

La build Windows va con `AVVIA-COMPATIBILITA.bat` accanto (lancia l'exe con
`--rendering-driver opengl3`, per le schede video senza Vulkan); il pacco
web per itch.io è lo zip del contenuto di `build/web/`.

La versione si cambia in **due posti**: `const VERSIONE` in
`scripts/caricamento.gd` e in `scripts/hud.gd`.

Il pacco del progetto si fa dalla cartella madre, **senza** `build/`, senza
`scripts/_prova_*.gd` / `scripts/_foto_*.gd` dimenticati, e con
`project.godot` pulito (controllare che non ci sia una riga `Prova=` o
`Foto=`).

### 4.5 La pulizia delle versioni vecchie

Dalla 0.60 le cancello io. Nel ponte ci sono gli strumenti di Desktop
Commander (`start_process` con PowerShell sul computer del capo): si manda
tutto **nel Cestino**, mai `Remove-Item`:

```powershell
Add-Type -AssemblyName Microsoft.VisualBasic
[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($f, 'OnlyErrorDialogs', 'SendToRecycleBin')
[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($d, 'OnlyErrorDialogs', 'SendToRecycleBin')
```

Si tengono almeno sei-sette versioni intere; **le cartelle delle librerie
di asset (Car Pack, Low Poly, Animated, Pandazole, PSX, Quaternius) non si
toccano mai**; prima si fa la lista, si scrive un registro
(`Claude outputs\pulizia-log.txt`) e si dice al capo cosa è andato nel
Cestino. Nella 0.60 il capo aveva chiesto di vedere la lista prima; per le
pulizie successive le istruzioni del progetto dicono di farlo da me.

---

## 5. Dove siamo col gioco

**La giornata** dura sette minuti e mezzo, ha cinque fasce che comandano
quante auto arrivano e quanto lasciano, e si chiude andando a dormire a
casa. La mattina, sulla porta, c'è 'o biglietto che dice che giornata è
(normale, partita, pioggia, mercato, processione, primo del mese). Alle venti
il vigile smonta.

**Il quartiere**: quattro piazze (la tua, lo stadio, il mercato, la
cornetteria) ognuna col suo carattere e il suo boss di capitolo, tre rivali,
bar e tabaccaio in ogni piazza, tavoli delle tre carte, sale scommesse, la
cornetteria di notte, l'armiere in fondo al vicolo cieco, il garage dello
sfasciacarrozze, la galera in cima al Vomero, il vascio con la famiglia.

**I soldi** si fanno posteggiando, con le commissioni della bacheca, i
guagliuni assunti (dalla 0.61 lavorano davvero in tutte e quattro le
piazze, e la sera si passa a ritirare), il turista da accompagnare, il
panaro di Donna Filumena, e rubando le auto (minigioco dello scasso, guida
fino al garage; dalla 0.61 da mezza a una giornata e mezza, tre al giorno).
Tutto si misura con **la giornata tipo**, `GIORNATA_TIPO` = €80. Si perdono
in cinque giochi d'azzardo, tutti sotto il 100%. Ogni oggetto che si compra
si ripaga fra 1,2 e 6,5 giornate. Le spese di casa sono sui 68 euro al
giorno (`prova_economia`): il margine lo danno i guagliuni.

**Le facce nove (0.61)**: Gennarino 'o Nuovo (l'abusivo dell'abusivo, nelle
tue piazze), il turista spierzo, il panaro. Tutti e tre si costruiscono in
`citta_3d._build_personagge_nove()` e decidono da soli quando comparire.

**Le armi** (0.61) si vedono in prima persona (`arma_fp.gd`) e si vede il
colpo; i furti pesano di più se c'è gente (`GameManager.testimoni`).

**La violenza** costa sciato (fiato), ossa che si ricomprano solo di notte,
fermi (al terzo si passa la notte in cella, e ci si risveglia davanti alla
galera sul Vomero), stelle che chiamano i carabinieri, e Borrelli.

**La città**, dalla 0.60, è vestita: 457 modelli, i bassi con la porta di
legno e le sedie fuori, le signore sedute, i materassi contro il muro, i
cantieri col bagno chimico, due bancarelle di libri, i tetti di coppi; e
disegna la metà dei triangoli di prima grazie ai gruppi a quadretti.

---

## 6. Cosa c'è da fare, in ordine

### Subito (se la chat nuova trova qualcosa aperto)

La 0.61 è stata chiusa e consegnata. Rimasti (vedi `ROADMAP.md`, «Rimasto
aperto dalla 0.61»):

1. **Chiedere al capo come va la 0.61 giocata**: i guagliuni, le armi,
   l'economia nuova. Le spese di casa (68 al giorno) contro una giornata
   tipo di 68-80: se è troppo stretto, la manopola è `RESA_DIPENDENTE` o le
   spese, non il furto.
2. **La prova che gioca dieci giornate da sola**: dopo la 0.61 è chiaro che
   è l'unico modo di vedere quello che vede il capo.
3. **Il balcone del panaro** è fatto di scatole: uno del pacchetto sarebbe
   meglio.
4. Dalla 0.60: le trenta vetrine da guardare in fotografia, il negozio più
   vicino alla tua piazza a 37 m, le signore sedute che sembrano vecchi.

### La 0.62 — **'E vvoce**

Voci registrate, clip di idle in prima persona, le criature con una
corporatura loro; e, se il capo lo vuole, la traversata a piedi (il
motorino con le chiavi). Come per la 0.61, **chiedere a lui** prima di
cominciare, con la lista della roadmap in mano.

---

## 7. Due cose da tenere a mente

**Borrelli** è una **caricatura satirica** di un personaggio pubblico reale
noto per la campagna contro i parcheggiatori abusivi: tratti riconoscibili
sul corpo low-poly, non un ritratto.

**I sei manifesti** della collezione sono immagini fornite dal capo, con volti
e marchi riconoscibili: vanno bene per una build privata, e sono la prima
cosa da sostituire se un giorno si distribuisce il gioco.

**Gli asset dei pacchetti** (PSX Mega Pack della 0.58 e 0.60, Car Pack,
Pandazole, Animated Men, Quaternius Animated Human della 0.59) sono stati
dati dal capo; gli originali stanno nella sua cartella sul computer (e non
si toccano). Quelli convertiti stanno in `assets/models/` e bastano per
lavorare. I 58 modelli PSX della 0.60 sono `.glb` con il loro `.import`
(dove serve, `root_scale` è già scritto dentro: il pacchetto è 1,52× il
vero, vedi `prova_psx`); per convertirne altri c'era il progettino di lavoro
`/home/claude/esame_psx`, che non sta nel pacco — si rifà copiando i `.glb`
dal pacchetto del capo in `assets/models/` e importando.
