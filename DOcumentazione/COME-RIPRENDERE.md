# Come riprendere il lavoro in una nuova chat

Stato al **26 settembre 2026**, versione **v0.63 · 'O Duttore** (Borrelli
torna: due porte col dado che cresce, non si tocca, si calma con sigaretta
e caffè — vedi `NOVITA-v0.63.md`).

Questo documento è scritto per **chi apre la chat nuova** (cioè per me, senza
memoria di questa). Si legge dall'alto: la sezione 1 dice cosa fare nei
primi dieci minuti, il resto è il manuale.

**Dalla 0.62 il metodo è cambiato** (istruzioni del progetto): una cartella
sola, Git, commit a ogni lavoro finito. Niente più cartelle numerate, niente
più pacchi spezzati da consegnare. La sezione 1.1 e la 2 lo spiegano.

Documenti da leggere insieme a questo, tutti in
`C:\Users\Max\Downloads\Parcheggiatore Abusivo Simulator\DOcumentazione\` e
nei documenti del progetto (`claude/…`):

| file | cosa c'è |
|---|---|
| `RIASSUNTO-CHAT-v0.62.md` | la cronaca della chat che ha fatto la 0.62: richieste, decisioni, il passaggio a Git, cosa è rimasto aperto |
| `NOVITA-v0.62.md` | le note della versione (per il capo, in italiano, con trappole e lezione) |
| `ROADMAP.md` | cosa è fatto versione per versione, e cosa viene dopo (la 0.63 è **'E vvoce**, più i rimasti della 0.62) |
| `CHANGELOG.md` | una riga per versione, dalla 0.44 alla 0.62 |
| `PROMPT-NUOVA-CHAT.md` | il messaggio da incollare per aprire la chat nuova |
| `LEGGIMI.txt` | per il capo: com'è fatta la cartella e come si gioca |
| `CREDITI.txt` | chi ha fatto i suoni, i caratteri, le icone (la CC BY dei suoni va citata) |

---

## 1. I primi dieci minuti

### 1.1 Dove sta il gioco, e come portarlo nel contenitore

Sul computer del capo, **una cartella sola**, che è anche il repository Git:

```text
C:\Users\Max\Downloads\Parcheggiatore Abusivo Simulator\
  .git\  .gitignore  .gitattributes      il repository (remote: GitHub,
                                           massimogiacca87-sudo/parcheggiatore-abusivo-simulator)
  Progetto\parcheggiatore-abusivo\        IL PROGETTO GODOT (project.godot, scripts, assets…)
  DOcumentazione\                         note, roadmap, changelog, questo manuale
  Build\                                  le build giocabili (ignorata da Git)
  Animations\ Models\ Texture\ Audio\ UI elements\ addons\ demo\ …
                                           le librerie di asset del capo: NON SI TOCCANO
```

Il `.gitignore` del capo esclude `*.glb`, `*.wav`, `*.mp3`, `*.zip`,
`Models/`; io ci ho aggiunto `.godot/`, `Build/` e `_claude_tmp/`. Quindi
**il repository da solo non basta** a ricostruire il gioco (mancano i modelli
.glb e i suoni .wav): **il progetto si prende dalla cartella**, non da GitHub.

**Per portarlo nel contenitore** (il ponte del desktop dev'essere acceso; i
comandi sul computer del capo si danno con Desktop Commander,
`start_process`, PowerShell):

```powershell
cd "C:\Users\Max\Downloads\Parcheggiatore Abusivo Simulator"
New-Item -ItemType Directory -Force _claude_tmp | Out-Null
tar -cf _claude_tmp\progetto.tar -C Progetto parcheggiatore-abusivo   # ~130 MB con .godot
```

**Dalla 0.63 non basta più un tar solo**: con la biblioteca esterna il
progetto senza `.godot` è 560 MB, e il ponte ne regge 400 a file (e ~50
secondi a trasferimento). Si fanno tre tar (circa 190, 205, 140 MB):

```powershell
tar -cf _claude_tmp\pA.tar --exclude=.godot --exclude=parcheggiatore-abusivo/assets/esterni/materiali -C Progetto parcheggiatore-abusivo
tar -cf _claude_tmp\pB1.tar -C Progetto\parcheggiatore-abusivo\assets\esterni\materiali decals
tar -cf _claude_tmp\pB2.tar --exclude=decals -C Progetto\parcheggiatore-abusivo\assets\esterni\materiali .
```

e nel contenitore `tar -xf pA.tar`, poi i due `pB` dentro a
`parcheggiatore-abusivo/assets/esterni/materiali/`. (Attenzione al `-C`:
se si passa il percorso intero come argomento, il tar se lo porta dietro e
i materiali finiscono in una cartella annidata.) Poi `--import` in
background (qualche minuto).

poi `device_stage_files` di `…\_claude_tmp\progetto.tar` (arriva in
`/mnt/user-data/uploads/…`), e nel contenitore:

```bash
cd /home/claude && tar -xf /mnt/user-data/uploads/*/_claude_tmp/progetto.tar
cd parcheggiatore-abusivo && git init -q && git add -A && git commit -qm base && git tag pc_sync
```

(il `.tar` sul computer del capo poi va nel Cestino, vedi 4.5). Il
repository **del contenitore** serve solo a fare le patch: quello vero è
sul computer del capo.

### 1.1b Come si salva il lavoro: una patch per commit

Si lavora nel contenitore (Godot, prove, fotografie), si fa **un commit per
ogni lavoro finito e provato**, poi lo si porta sul computer del capo:

```bash
# nel contenitore: le patch dei commit nuovi (dal tag pc_sync), senza .godot,
# con gli a-capo come li tiene il repo del PC (vedi sotto)
/home/claude/parcheggiatore-abusivo/tools/sh/sincro.sh
```

**Dalla 0.63**: `sincro.sh` e `sincro_lf.py` arrivano dal PC con gli a-capo
di Windows e così non partono (`set: -: invalid option`). Si lanciano da
una copia pulita:

```bash
sed 's/\r$//' tools/sh/sincro.sh > /tmp/sincro.sh
sed 's/\r$//' tools/sh/sincro_lf.py > /tmp/sincro_lf.py
sed -i 's#\$SRC/tools/sh/sincro_lf.py#/tmp/sincro_lf.py#' /tmp/sincro.sh
bash /tmp/sincro.sh
```

Stessa cosa per gli altri `tools/sh/*.sh` se danno errori strani. E per
riattaccare i pezzi delle build sul PC con .NET si usano **percorsi
assoluti**: `[IO.File]::Create` parte da `C:\Windows\System32`, non dalla
cartella di PowerShell.

**Gli a-capo** (scoperto alla 0.62). Il repo del capo ha
`core.autocrlf=true`: dentro a Git i file stanno con gli a-capo Unix (LF),
nella cartella alcuni `.gd` hanno quelli di Windows (CRLF). Il contenitore
parte dal tar della cartella, quindi qui quei file hanno CRLF — e gli hash
degli alberi (`HEAD:scripts`) **non** sono gli stessi del PC anche a codice
identico. `sincro.sh` fa le patch su una copia in cui, in tutti i commit
(base compresa), i file di testo toccati sono portati a LF, e stampa
l'hash dell'albero `scripts` normalizzato: **quello** va confrontato con
`git rev-parse HEAD:Progetto/parcheggiatore-abusivo/scripts` sul PC. Chi
riscrive un file con Python lo apre con `newline=''` (o in binario), se no
gli a-capo cambiano tutti e la patch diventa il file intero.

`sincro.sh` lascia fuori anche i file che sul PC **non sono tracciati**
(`ESCLUSI` in cima allo script): alla 0.62 i vecchi
`assets/models/condizionatore*`, che il `.gitignore` del capo (`Models/`,
e Windows non distingue le maiuscole) tiene fuori da Git. Quelli si
sistemano a mano sul PC (nel Cestino).

`device_commit_files` di ogni patch in
`…\Parcheggiatore Abusivo Simulator\_claude_tmp\000N.patch`, e sul computer:

```powershell
cd "C:\Users\Max\Downloads\Parcheggiatore Abusivo Simulator"
$ps = Get-ChildItem _claude_tmp\*.patch | Sort-Object Name
foreach($p in $ps){ git am --directory=Progetto/parcheggiatore-abusivo $p.FullName }
$ps | Move-Item -Destination $env:TEMP -Force
git log --oneline -3
```

e nel contenitore `git tag -f pc_sync HEAD`. **Attenzione**: PowerShell non
espande `_claude_tmp/*.patch` dentro a un argomento di `git am` (serve il
`Get-ChildItem`), e `git am` è lento sulle patch grosse — il ponte può
rispondere «did not respond within 60s» mentre il commit va in porto: si
controlla con `git log` prima di rilanciare.

I **documenti** (`DOcumentazione\`) stanno fuori dal progetto Godot: si
scrivono nel contenitore, si portano con `device_commit_files` direttamente
in `DOcumentazione\` e si committano sul computer con `git add
DOcumentazione; git commit`.

Per controllare che il contenitore e il computer abbiano lo stesso codice:
l'hash che stampa `sincro.sh` alla fine («albero scripts (LF)») deve essere
lo stesso di `git rev-parse HEAD:Progetto/parcheggiatore-abusivo/scripts`
sul computer, dopo il `git am`.

**Nello stesso repository può lavorare un'altra sessione** (nella 0.62 una
ha aggiunto `assets/esterni/` e i plugin in `addons/`). Quindi: `git log
--oneline -5` prima di applicare le patch; se una patch non entra, **`git am
--quit`** (mai `--abort`: riporta indietro anche i commit degli altri) e si
riapplica con `--exclude=<file>`; e prima di cominciare una versione nuova
si riprende il progetto dal computer, non dalla copia vecchia del
contenitore.

**Non si fa `git push`** se il capo non lo chiede: le istruzioni dicono
`git add` e `git commit`. **Non si committano** le cartelle di asset che il
capo ha lasciato fuori (`Animations/…`, `addons/`, `demo/`,
`assets/materials/` in radice): sono sue.

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

**Mai insieme a una prova** (trappola 14). Dalla 0.62 l'import di Blender è
spento (`[filesystem] import/blender/enabled=false` in `project.godot`): le
demo di ProtonScatter hanno un `.blend` e senza finestra Godot restava
fermo lì per sempre. E dopo `tools/prepara_esterni.py` (che rigenera le
texture e i suoni presi dalla biblioteca esterna) **si reimporta sempre**.

Per le fotografie col renderer vero dell'exe (Forward+, serve per le
pozzanghere) c'è `tools/sh/foto_vk.sh`: Vulkan in software, con
`apt-get install -y mesa-vulkan-drivers`.

### 1.3 Controllare che tutto sia come l'ho lasciato

```bash
nohup /tmp/batteriac.sh > /tmp/batteriac.log 2>&1 &     # ~45 minuti
cat /tmp/batteriac.txt                                   # una riga per prova
```

Risultato atteso alla chiusura della 0.62 (53 prove): **tutte a zero storte**, con tre
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
   aggiornata con la sezione «Fatto», il `CHANGELOG.md`, il
   `RIASSUNTO-CHAT-vX.md`, il `LEGGIMI.txt` e questo documento aggiornato.
   Tutti **in `DOcumentazione\`** (committati) **e nei documenti del
   progetto** (`claude/…` con `project_write`).
3. **Git, una cartella sola** (istruzioni del progetto dalla 0.62): *«Ti è
   ASSOLUTAMENTE VIETATO creare nuove cartelle numerate per le versioni
   future.»* Si lavora **per piccoli task atomici**; quando un task è
   finito e funziona senza errori, **`git add` e `git commit -m 'breve
   descrizione'`** (messaggi in italiano, `v0.XX: …`). Vedi 1.1b.
4. **Le versioni vecchie le cancello io**, adesso sono i file vecchi rimasti
   in giro (cartelle `Claude outputs\vX` se ricompaiono, pacchi `.part`,
   le patch in `_claude_tmp`). Sempre **nel Cestino di Windows, mai
   definitivo**. E il capo: *«non toccare mai le librerie di asset (Car
   Pack, Low Poly, Animated, Pandazole, PSX, Quaternius)»*. Come si fa sta
   nella sezione 4.5.
5. **Le build** vanno in `Build\` (l'exe col suo `.pck`, e
   `AVVIA-COMPATIBILITA.bat`), e il pacco web per itch.io in radice come
   `PAS-v0.XX-Web-itchio.zip` (lo `.zip` è ignorato da Git). I file grossi
   si portano sul computer a pezzi da 19 MB (`split -b 19000000`) e si
   riattaccano sul computer con PowerShell/`cmd copy /b`: il ponte regge
   20 MB a file e 100 MB a chiamata.
6. **Multi-agente**: le istruzioni dicono che si possono aprire altre
   istanze o sotto-agenti per dividere il lavoro, e usare altre IA (per
   esempio Gemini) per generare asset.
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
| `scripts/robba_esterna.gd` | 615 | **(0.62)** la biblioteca esterna in città: decalcomanie (tombini, rattoppi, olio, gomme, colature, umido, graffiti) e arredo (motorini al cordolo, sedie di Vienna, coni, bidoni, casse, sedie d'ufficio); seme suo, `rifiuti` conta i perché |
| `scripts/filtri_schermo.gd` | 130 | **(0.62)** i filtri a schermo intero del menu di pausa e la botta |
| `scripts/pozzanghere.gd` | 60 | **(0.62)** le pozzanghere quando piove (solo Forward+) |

### I tre scheletri delle persone

- **'o pupo** (Universal Animation Library): lo scheletro di sempre, 43 clip,
  tabella `CLIP` in `animator.gd`. Tutte le donne sono pupi.
- **'e omini** (Low Poly Animated Men): otto uomini, quattro vestiti, undici
  clip in `assets/models/omo_mosse.res`.
- **l'umano_q** (Quaternius Animated Human): un corpo, sei vestiti, sette
  clip più `Fermo` (0.60), che si costruisce la prima volta in
  `_prepara_fermo`: la sua `Idle` è una guardia da pugile e non va usata
  per chi sta fermo.

- **'e quat** (0.62, dalla biblioteca esterna: Quaternius, rig
  «CharacterArmature»): sei corpi in `Human.QUAT` (`quat_giacca`,
  `quat_maglietta`, `quat_operaio`, `quat_cafone`, due donne in
  `QUAT_DONNE`), con le loro 24 clip più le 28 del pupo tradotte in
  `assets/models/quat_ual.res` (`tools/retarget_ual.gd`, tabella
  `MAPPA_QUAT`); `RIG["quat"]` in `human_builder.gd`. I file stanno in
  `assets/esterni/modelli/npc_animati/`: se si cambia quali si usano, va
  cambiato anche l'`exclude_filter` dei due preset d'esportazione.

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

**Aggiunte nella 0.62 (la biblioteca esterna)**

47. **Un `.blend` in un plugin blocca l'import senza finestra.** Import di
    Blender spento in `project.godot`.
48. **Texture rigenerate = reimportare.** Se no Godot usa quelle vecchie
    (la colatura invisibile).
49. **Un modello si conta, non si guarda da lontano.** Il condizionatore
    era un palazzo in miniatura da 182 superfici.
50. **Gli a-capo** (vedi 1.1b): `newline=''` in Python, patch da
    `sincro.sh`.
51. **Una cosa lunga contro il muro di un vicolo da quattro metri è un
    tappo** per chi cammina rasente: i motorini davanti ai bassi sono
    usciti per questo.
52. **Un posto dove un personaggio «si appoggia»** (il banco del bar)
    può stare dove non si arriva: ogni meta ha bisogno di un «fermo da
    due secondi = sono arrivato», e la prova dei piantati guarda a tre.
53. **La biblioteca esterna è fuori dall'esportazione per default**
    (`exclude_filter`, tutti e due i preset): un asset di `assets/esterni/`
    usato dal gioco va tolto dal filtro, se no nell'exe non c'è e il gioco
    non dà errore (`spawn` torna `null`).

**Aggiunte nella 0.63**

55. **Una bandierina che si accende e non si spegne più** è un «una volta
    per partita» travestito. `_chiamata_fatta` del vigile spegneva la radio
    per sempre dopo la prima chiamata, e con lei Borrelli.
56. **Una regola che il capo ricorda può non esserci nel codice** («il
    vigile mandato via tre volte chiama»): si controlla prima di
    ricordarla, e se manca si fa.

**Aggiunte nella 0.62.1**

54. **Le prove saltano la volata, il giocatore no.** Fra la costruzione
    della città e `start_shift()` il cronometro della giornata valeva zero
    e `ora_d_o_juorno()` diceva le 28: tutto quello che guarda l'ora (i
    vigili che smontano alle venti) agiva durante la volata. Ora `main.gd`
    mette `shift_time_left = shift_duration` all'avvio se il turno non è
    attivo, e il vigile non smonta a turno spento. Per guardare il gioco
    vero, volata compresa: `foto_vigile_citta` (xvfb, chiama il «Gioca»
    del menu da solo) — conta i vigili fotogramma per fotogramma.

### Come si prova

Cinquantadue `tools/prova_*.gd` (una, `prova_scopa`, va a parte). Ognuna è un autoload temporaneo che stampa
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

Le fotografie e le sonde della 0.62 (biblioteca esterna):
`foto_esterni_citta` (asfalto, muffa, facciate, tombino, olio, colature,
umido, split, graffito, gomme, motorini, sedie, coni, cassette,
ingombranti, bidone, scooter, cassa; `SOLO=a,b`, `NOTTE=1`, `PIOGGIA=1`,
`PREFISSO=x`, `QUALE=n` per l'n-esima istanza → `/tmp/est_*.png`),
`foto_esterni` (i modelli uno per uno), `foto_filtri` (i filtri, la botta,
i soldi, la pausa → `/tmp/filtro_*.png`), `foto_tutoriale` (tutte le
pagine, crediti compresi); `sonda_esterni` (quanta roba è entrata e i
rifiuti, headless), `sonda_decal`, `sonda_punto` (`PX=… PZ=… R=…`: che
c'è attorno a un punto, corpi solidi e istanze dei gruppi — con xvfb).

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
web per itch.io è lo zip del contenuto di `build/web/`. **Controllare prima
che i modelli di esportazione ci siano** (`ls
~/.local/share/godot/export_templates/4.3.stable/`): nella 0.62 la cartella
risultava vuota dopo un riavvio del contenitore anche se il log diceva
«FATTO».

**Dalla biblioteca esterna (0.62)**: `addons/limboai/*` è **fuori
dall'esportazione** (tutti e due i preset). Con la sua libreria dentro, la
build web **non partiva nemmeno**: il caricatore di Godot si ferma con
«GDExtension libraries are not supported by this engine version» perché il
modello d'esportazione normale non è «dlink». L'ho visto solo aprendo la
build in un browser vero (`tools/web/serve_build.py` +
`node tools/web/prova_build_web.js`: Chromium senza finestra, la console
riga per riga, fotografie in `/tmp/web_*.png`). Senza la libreria, all'avvio
restano tre righe d'errore («Error loading extension») e il gioco parte.
Nel contenitore Chromium usa SwiftShader: la pagina muore di memoria dopo
circa due minuti di città, **anche con la build della prima metà della
0.62** (provato) — è un limite della prova, non del gioco. E serve
`build/.gdignore`, se no Godot importa i PNG della build web come risorse
del progetto e li mette nel pacchetto successivo.
Ogni export sporca `addons/proton_scatter/.../compute_relax.glsl.import`
(«Cannot import custom .glsl shaders when running in headless mode»):
dopo, `git checkout` di quel file.

La consegna, dalla 0.62: l'exe e il `.pck` in `Build\` sul computer del capo
(a pezzi da 19 MB se serve, riattaccati là), lo zip web in radice. **Non
più** cartelle `Claude outputs\vX` né pacchi del progetto: il progetto è la
cartella stessa.

La versione si cambia in **due posti**: `const VERSIONE` in
`scripts/caricamento.gd` e in `scripts/hud.gd`.

Prima di ogni commit: niente `scripts/_prova_*.gd` / `scripts/_foto_*.gd`
dimenticati, e `project.godot` pulito (nessuna riga `Prova=` o `Foto=`: se
una prova va in timeout, `/tmp/prova.sh` non fa in tempo a rimetterlo a
posto — si ricopia `/tmp/pg.bak`).

### 4.5 La pulizia

Nel ponte ci sono gli strumenti di Desktop Commander (`start_process` con
PowerShell sul computer del capo): si manda tutto **nel Cestino**, mai
`Remove-Item`:

```powershell
Add-Type -AssemblyName Microsoft.VisualBasic
[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($f, 'OnlyErrorDialogs', 'SendToRecycleBin')
[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($d, 'OnlyErrorDialogs', 'SendToRecycleBin')
```

Dalla 0.62 le cartelle numerate le ha tolte il capo stesso; restano da
pulire le cose di passaggio (le patch spostate in `%TEMP%`, il `.tar` del
progetto in `_claude_tmp`, vecchi `PAS-v0.XX-Web-itchio.zip` quando c'è il
nuovo). **Le cartelle delle librerie di asset non si toccano mai**; si
scrive il registro in `DOcumentazione\pulizia-log.txt` e si dice al capo cosa
è andato nel Cestino.

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
fino al garage; dalla 0.62 una berlina vale €100, la seconda della giornata la metà, tre al giorno).
Tutto si misura con **la giornata tipo**, `GIORNATA_TIPO` = €80. Si perdono
in cinque giochi d'azzardo, tutti sotto il 100%. Ogni oggetto che si compra
si ripaga fra 1,2 e 6,5 giornate. Le spese di casa dalla 0.62 sono sui 55-60
euro al giorno (`prova_economia`), contro i 68-80 di una giornata onesta.

**Le facce nove (0.61)**: Gennarino 'o Nuovo (l'abusivo dell'abusivo, nelle
tue piazze), il turista spierzo, il panaro. Tutti e tre si costruiscono in
`citta_3d._build_personagge_nove()` e decidono da soli quando comparire.

**Le armi** (0.61) si vedono in prima persona (`arma_fp.gd`) e si vede il
colpo; i furti pesano di più se c'è gente (`GameManager.testimoni`).

**Le commissioni (0.62)** te le affida una persona (`committente_3d.gd`) che
ti viene incontro con la roba (`robba_cummissione.gd`): la porti in mano in
prima persona fino a chi la riceve. Otto tipi in `GameManager.CUMM_TIPI`.

**L'interfaccia (0.62)** passa tutta dal tema (`assets/ui/tema.tres`, si
rigenera con `tools/genera_tema.gd`) e da `ui_stile.gd`; la riga dei
comandi è `riga_comandi.gd`, la minimappa `minimappa.gd`. Ogni pannello ha
una fotografia: `foto_hud`, `foto_pannelli`, `foto_ui` (scopa), `foto_lotto`.

**Le animazioni (0.62)**: i corpi omo e umano_q hanno la libreria del pupo
tradotta (`assets/models/omo_ual.res`, `umano_q_ual.res`, rifatte da
`tools/retarget_ual.gd`); la tabella è `RIG` in `human_builder.gd`.

**La biblioteca esterna (0.62, seconda metà)**: asfalto vero sulle strade
larghe e muffa alla Sanità, tombini e macchie a terra, colature sotto agli
split (rifatti a codice), Vespe e scooter al cordolo, sedie di Vienna,
coni, bidoni, casse, dodici suoni di strada, tre filtri dello schermo nel
menu di pausa e la botta quando ti colpiscono, le pozzanghere quando piove
(solo exe), sei persone nuove di Quaternius, il borsello che si svuota, la
pagina dei crediti. Cosa è entrato e cosa no: `assets/esterni/ASSET-ESTERNI.md`
(la tabella in cima) e `NOVITA-v0.62.md`. I tre plugin (ProtonScatter,
Dialogic, LimboAI) sono installati ma **non usati**.

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

La 0.62 è stata chiusa e committata. Rimasti (vedi `ROADMAP.md`, «Rimasto
aperto dalla 0.62»):

1. **Chiedere al capo come va la 0.62 giocata**: la UI nuova, le
   commissioni col committente, l'economia (berlina a €100).
2. **La prova che gioca dieci giornate da sola.**
3. La sala scommesse è l'unico pannello col suo stile a parte.
4. Il balcone del panaro, la traversata a piedi, il motorino con le chiavi.

### Borrelli e gli altri boss (0.63)

Le regole di Borrelli stanno in `game_manager.gd` («'E BOSS D''E
JURNATE»): `prob_borrelli_sera`, `prob_borrelli_chiamata`,
`borrelli_venuto` (la ripartenza dei dadi: scelta mia, da confermare col
capo). Le prove: `prova_borrelli` (i dadi) e `prova_borrelli_gioca` (in
città). Il capo vuole **altri boss e un finale**: le proposte stanno nella
`ROADMAP.md`, «I boss che verranno e il finale» — si sceglie con lui prima
di scrivere codice.

### La 0.64 — **'E vvoce**

Voci registrate, clip di idle in prima persona, le criature con una
corporatura loro. Come sempre, **chiedere a lui** prima di cominciare, con
la lista della roadmap in mano.

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
