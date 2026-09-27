# BIBBIA PSX — le regole comuni della squadra grafica

Tutti gli agenti della squadra (il direttore `grafico-psx` e i sotto-agenti
`grafica-*`) leggono questo file **all'inizio di ogni lavoro**. Se una regola
cambia, si cambia qui e basta: vale per tutti.

---

## 1. Perché lavoriamo

**Parcheggiatore Abusivo Simulator** (Godot 4.3, GDScript) deve diventare
**lo Schedule I napoletano**: stessa qualità, stessa cura, stesso successo.
Ogni scelta grafica si misura su questo: *il giocatore lo nota? rende Napoli
più vera? costa poco a schermo?*

**Massimo (il capo) è il lead designer.** Lavoro grafico, bugfix visivi e
ottimizzazioni sono autonomi. Tutto quello che cambia **come si gioca**
(controlli, meccaniche, economia, come si parcheggia) si chiede prima a lui.

---

## 2. Lo stile: PSX moderno, Napoli vera

Il gioco non è un emulatore PlayStation: è **low-poly con l'anima PSX**, come
Schedule I è low-poly con l'anima cartoon. In pratica:

- **Forme semplici e leggibili.** Si riconosce la sagoma a 20 metri. Pochi
  poligoni, ma messi dove si vedono (profili, bordi, facce).
- **Texture piccole e oneste.** Oggetti piccoli 64–128 px, oggetti medi
  128–256, muri e pavimenti fino a 384 (quelli attuali stanno lì). Meglio un
  **atlante** con un solo materiale che dieci materiali. Dimensioni a potenza
  di 2 quando si può.
- **Colore.** Tinte leggermente desaturate e calde (tufo, intonaco giallo,
  piperno grigio, maioliche), accenti saturi dove Napoli li ha davvero (panni
  stesi, edicole votive, insegne, bandiere, neon). Niente plastica lucida:
  la ruvidità alta è la norma.
- **Filtri a schermo già esistenti**: `assets/shaders/filtri/`
  (`videocassetta`, `pellicola`, `lente_sporca`, `botta`) e
  `assets/esterni/shader/`. Si riusano, non si duplicano.
- **Impostazioni del progetto da non toccare senza il permesso di Massimo**:
  filtro anisotropico 3, MSAA 3D 2x, renderer Forward+ (e `gl_compatibility`
  per la build web/mobile). Niente filtro `nearest` globale, niente vertex
  snapping globale: se si vuole provare un effetto PSX più spinto, si fa come
  **opzione** e si mostra a Massimo con le foto prima/dopo.

### Tetti di partenza (indicativi, da confermare con Massimo)

| Cosa | Triangoli | Texture |
|---|---|---|
| Oggetto da tasca / da tavolo | ≤ 300 | 64–128 px |
| Arredo urbano (sedia, cassonetto, cartello) | 100–800 | 128–256 px |
| Pezzo grande (edicola, bancarella, chiosco) | 800–2.500 | 256 px o atlante |
| Veicolo | 800–3.000 | atlante 256–512 |
| Personaggio | 1.500–3.500 | atlante 256–512 |

Se un asset sfora, si dice **perché** nel rapporto.

---

## 3. Le regole del mondo (imparate a caro prezzo)

1. **Metri veri.** Una sigaretta è 8,4 cm, una sedia ha la seduta a 46 cm,
   una porta è 2,10 m. Il PSX Mega Pack disegna gli oggetti da tasca **1,52×
   più grandi** del vero (la roba grossa invece è giusta): si misura sempre.
2. **Il nome non è la cosa.** `tetti_italiani.jpg` era Venezia, l'`Idle` di
   Quaternius è una guardia. **Ogni asset nuovo si guarda in foto** prima di
   usarlo.
3. **Il numero dice quanto è grande, solo l'occhio dice se sta bene.** Ogni
   lavoro visibile si chiude con una **fotografia dentro al gioco**, con la
   luce e i materiali del gioco.
4. **Le inquadrature si cercano, non si indovinano**: la telecamera punta a un
   nodo trovato per gruppo o per nome, da un punto fuori dai palazzi.
5. **Orientamenti**: il davanti di una persona è −Z; sull'osso della testa il
   davanti è +Z (occhiali, barba, visiere vanno a +Z). Base dei modelli a
   quota zero, origine in basso al centro.
6. **Niente dentro a niente.** Nella città si piazza solo dove c'è posto
   (`_sta_libero`, `_scatola_libera`), e ogni cosa più grande di un pacchetto
   di sigarette ha un corpo (`_solido`). Ogni pezzo sta attaccato a qualcosa
   che c'era già (la sedia al suo basso, il bagno chimico al suo cantiere).
7. **Seme fisso**: la città è la stessa a ogni partita. Chi aggiunge roba usa
   il suo `RandomNumberGenerator` con un seme suo.
8. **I nomi dei modelli si scrivono per intero**, mai costruiti con `%d`:
   `prova_asset` li cerca nel testo.
9. **Niente pose a T** (`prova_croce`). `hold_bone` congela la posa di
   riposo: per un braccio che tiene qualcosa si usa `animator.punta_osso`.
10. **La biblioteca esterna è fuori dall'esportazione**: un asset di
    `assets/esterni/` usato davvero va tolto dall'`exclude_filter` dei due
    preset di `export_presets.cfg`, se no nell'exe non c'è e `spawn` torna
    `null` in silenzio. (`export_presets.cfg` lo tocca solo il direttore.)
11. **Dopo ogni asset nuovo si reimporta** (`--import`), se no si collauda il
    modello vecchio credendo di collaudare quello nuovo. **Mai l'import
    insieme a una prova.**
12. **Tutto deve funzionare anche nella build web** (Compatibility/OpenGL):
    shader e particelle si provano anche lì.

---

## 4. Le regole del progetto

- **Una sola cartella**: `C:\Users\Max\Downloads\Parcheggiatore Abusivo
  Simulator` (con gli spazi: **sempre tra virgolette** nei comandi). Il
  progetto Godot sta in `Progetto/parcheggiatore-abusivo/`.
- **Vietato creare cartelle numerate per versione** (`/0.66` e simili).
- **Git**: lavoro a piccoli task atomici. **Commit li fa solo il direttore**,
  uno per task finito e funzionante. I sotto-agenti non fanno `git add`,
  `git commit`, `git push`, `git reset`, `git checkout` di file altrui.
  Il `push` si fa solo col permesso di Massimo.
- **A-capo**: il repo ha `core.autocrlf=true`. Chi riscrive un file in Python
  usa `newline=''` e preserva gli a-capo che trova.
- **Lingua**: commenti e testi del gioco in napoletano come il resto del
  codice; rapporti, note e documenti in **italiano**.
- **Niente documenti non richiesti.** Si fa la cosa chiesta; i documenti del
  progetto (CHANGELOG, NOVITA, ROADMAP) li aggiorna il direttore a fine lavoro.
- **Intoccabili** (nessuno li modifica, nessuno li cancella): `agenti/`,
  `crew_output/`, `studio.py`, `designer.py`, `artista.py`,
  `direttiva_designer.md`, `.gitignore`, le istruzioni degli agenti in
  `.claude/` (solo il direttore può **aggiungere** agenti nuovi, vedi §7).
- **Sorgenti originali in sola lettura**: `Models/`, `Animations/`,
  `Texture/`, `UI elements/`, `assets/` della radice, gli zip. Si copia e si
  converte, **non si modifica mai l'originale**.
- **Niente cancellazioni** di file del progetto senza il permesso del
  direttore. File di lavoro, provini e foto vanno in
  `_claude_tmp/grafica/` (è già ignorato da git).

---

## 5. Gli strumenti su questo PC (Windows 10)

La shell di Claude Code su Windows è **Git Bash**: i percorsi si scrivono
`/c/Users/Max/...` e vanno tra virgolette.

| Strumento | Dove | Note |
|---|---|---|
| **Godot 4.3** (quello giusto) | `/c/Users/Max/AppData/Local/Temp/godot43/Godot_v4.3-stable_win64_console.exe` | sta in una cartella Temp: se sparisce, dirlo al direttore |
| Godot 4.7.2 | `/c/Users/Max/Downloads/Godot_v4.7.2-stable_win64.exe/` | **NON aprirci il progetto**: lo convertirebbe alla 4.7 |
| Blender 5.2 | `/c/Program Files/Blender Foundation/Blender 5.2/blender.exe` | da riga di comando: `-b --python-exit-code 1 -P script.py -- argomenti` |
| Python 3.11 | `python` | Pillow e numpy ci sono |
| Git | `git` | remote `origin` su GitHub |

Comandi utili (dalla cartella `Progetto/parcheggiatore-abusivo`):

```bash
G="/c/Users/Max/AppData/Local/Temp/godot43/Godot_v4.3-stable_win64_console.exe"
"$G" --headless --path . --import                       # reimporta gli asset
"$G" --headless --path . --check-only --script res://scripts/x.gd   # controlla uno script
```

**Prove e fotografie**: `tools/prova_*.gd` e `tools/foto_*.gd` sono autoload
temporanei. Come si lanciano lo dicono `tools/sh/prova.sh` e
`tools/sh/foto.sh` (scritti per il contenitore Linux: vanno **adattati** ai
percorsi di qui, e le foto salvate in `_claude_tmp/grafica/` invece che in
`/tmp`). Regola d'oro: **prima si fa la copia di `project.godot`, alla fine
si rimette a posto e si cancella lo `scripts/_prova_*.gd`**, anche se la prova
va in errore. Le foto su Windows si fanno **con la finestra** (senza
`--headless`), risoluzione `1280x760`.

Provini di modelli fuori dal gioco: `tools/blender/anteprima.py` (Cycles su
CPU; leggerlo prima, i percorsi d'uscita sono del contenitore).

Le prove da far girare dopo ogni ritocco alla città: `prova_arredo`,
`prova_asset`, `prova_psx`, `prova_ngombri`, `prova_ntuppate`, `prova_mure`,
`prova_croce`, `prova_quote`, `prova_conti`. **Una prova che passa per il
motivo sbagliato si riscrive.**

Le API del gioco da conoscere (leggerle nel codice prima di usarle):
`scripts/models.gd` (`Models.ESTERNI`, `has_model`, `tint`),
`scripts/textures.gd` (`Tex.mondo`, `Tex.get_material`, `Tex.flat`,
`Tex.facciata`), `scripts/human_builder.gd`, `scripts/animator.gd`,
`scripts/citta_3d.gd` (`_panda`, `_panda_c`, `_batched`, `_solido`,
`_lontananza`), `scripts/robba_psx.gd` (esempio completo di come si arreda).

La memoria lunga del progetto sta in `DOcumentazione/` e nei documenti del
progetto claude.ai (`COME-RIPRENDERE.md` con le trappole numerate,
`MEMORIA_PROGETTO.md`). **Prima di un lavoro grosso si leggono le trappole.**

---

## 6. Licenze

- ✅ **CC0 / pubblico dominio**: libero (si cita lo stesso, per gentilezza).
- ✅ **CC BY**: sì, **con il credito obbligatorio** in
  `DOcumentazione/CREDITI.txt` e `Build/CREDITI.txt`, e nel `CREDITI_*.txt`
  della cartella dove sta l'asset.
- ✅ Asset già comprati/forniti da Massimo (Car Pack, Pandazole, PSX Mega Pack,
  Low Poly Animated Men, Quaternius…): sì.
- ✅ Immagini generate con IA (Gemini ecc.): sì per texture e decal, annotate
  nei crediti come generate.
- ❌ **NC** (non commerciale), **ND** (non modificabile), licenze "editorial",
  "personal use", GPL per asset grafici, licenza non trovata: **no**. Il gioco
  si venderà.
- ❌ Roba estratta da giochi commerciali, marchi e volti riconoscibili: **no**
  (i manifesti della collezione valgono solo per le build private).
- La guida della biblioteca esterna è
  `Progetto/parcheggiatore-abusivo/assets/esterni/ASSET-ESTERNI.md`: ogni
  asset scaricato ci va registrato (fonte, autore, licenza, link).

---

## 7. La squadra

| Agente | Specialità | Può modificare file? |
|---|---|---|
| `grafico-psx` (skill, `/grafico-psx`) | Direttore artistico: divide, affida, controlla, integra, committa | sì |
| `grafica-modellatore` | Modelli da zero in Blender, riduzione poligoni, UV | sì |
| `grafica-texture` | Texture, palette, pixel art, atlanti, decal, foto → stile PSX | sì |
| `grafica-animatore` | Scheletri, animazioni, riuso Universal Animation Library | sì |
| `grafica-luci` | Luci, nebbia, giorno/notte, luce dipinta sui vertici | sì |
| `grafica-shader-vfx` | Shader PSX, filtri a schermo, particelle | sì |
| `grafica-ui` | HUD, menu, icone, font | sì |
| `grafica-cercatore-asset` | Cerca e scarica asset gratuiti, controlla la licenza | sì (solo `assets/esterni/` e `_claude_tmp/`) |
| `grafica-tech-artist` | Porta gli asset in Godot e li ottimizza | sì |
| `grafica-scenografo` | Compone vicoli e piazze e li arreda | sì |
| `grafica-revisore` | Critica con voto e verdetto | **no** (solo lettura) |

**Agenti nuovi**: solo il direttore li crea, con lo schema di
`.claude/skills/grafico-psx/SKILL.md`, e li aggiunge a questa tabella.

---

## 8. Regole per i sotto-agenti

1. Lavori **solo sui file che il direttore ti ha assegnato**. Se ti serve
   toccarne un altro (soprattutto `citta_3d.gd`, `project.godot`,
   `export_presets.cfg`), **fermati e chiedilo nel rapporto**: altri agenti
   possono lavorare in parallelo e i file condivisi si rompono.
2. Non lanci altri agenti, non modifichi le tue istruzioni né quelle dei
   colleghi, non committi, non pushi.
3. Se qualcosa non torna (un'API che non esiste, un file che non c'è, una
   regola che si contraddice), **non inventare**: scrivilo nel rapporto.
4. Chiudi **sempre** con questo rapporto:

```
## RAPPORTO — <agente> — <titolo del lavoro>
Fatto: <cosa, in 2-5 righe>
File creati/modificati: <elenco con percorsi>
Verifica: <prove lanciate e risultato, foto in _claude_tmp/grafica/...>
Numeri: <triangoli, dimensioni texture, peso file, dove serve>
Licenze: <fonte e licenza di ogni asset esterno, o "nessun asset esterno">
Dubbi e rischi: <cosa non sono riuscito a verificare>
Serve dal direttore: <file condivisi da toccare, permessi, prossimi passi>
```
