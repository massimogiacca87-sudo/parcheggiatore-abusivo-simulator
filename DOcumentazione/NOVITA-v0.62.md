# v0.62 — 'A faccia nova

*Parcheggiatore Abusivo Simulator · 25–26 settembre 2026*

Nove richieste del capo dopo una partita, e un cambio di metodo a metà
strada. Questa è la versione in cui il gioco si è rifatto la faccia —
l'interfaccia intera, le carte, il lotto, le commissioni — e in cui le
cose che "c'erano" ma non funzionavano (il vigile, lo stemma col tasto G,
le animazioni dei corpi nuovi) hanno ricominciato a funzionare.

Poi, prima della build, una seconda metà: **la biblioteca di asset liberi
preparata da un'altra sessione è entrata nel gioco** — asfalto vero, muffa,
tombini e macchie, Vespe parcheggiate, suoni di strada, filtri dello
schermo, pozzanghere, sei facce nuove, i crediti. Sta nella sezione «La
seconda metà», più in basso.

---

## Le nove richieste, una per una

### 1. L'interfaccia, rifatta da capo

> *«Alza un po' le scritte dei tasti da premere (es. premi G per rubare lo
> stemma) perché stanno davanti ad altri elementi UI. Rivedi l'intera UI per
> farla più leggibile e bella possibile.»*

- **Un tema unico per tutto il gioco** (`assets/ui/tema.tres`, generato da
  `tools/genera_tema.gd`): font Poppins per i testi e i titoli, DejaVu per
  i simboli, pannelli scuri col bordo oro, bottoni, barre, schede e
  separatori tutti dallo stesso posto. Prima ogni pannello si disegnava il
  suo stile a mano, e si vedeva.
- **La riga dei comandi** (`riga_comandi.gd`) è una pillola sua, **alzata
  sopra** alla pila in basso (commissione, obiettivo, mano): non copre più
  niente. Ogni tasto è un tastino disegnato (`[E]`, `[G]`, `[F]`); se le
  azioni sono tante va su due righe, misurate con la larghezza vera del
  testo, e le parentesi non si spezzano più a metà («berlina · seria»).
- **L'HUD a schede**: a sinistra soldi (numero grande con l'icona),
  sospetto, HP e sciato con le barre colorate; a destra ora, giorno,
  servizio e il conto della sera; sotto, la pila dei cartelli. Il banner
  degli eventi è una pillola che si allarga col testo e resta nello
  schermo. Il puntatore dello stemma sparisce quando la scritta dei comandi
  c'è già.
- **La minimappa** (`minimappa.gd`), nuova: in basso a destra, col nord,
  le zone, i servizi, i clienti, le divise entro 40 metri e una freccia sul
  bordo verso l'obiettivo. La mappa grande (M) usa il font nuovo e ti
  disegna sopra alle etichette.
- **I suoni dell'interfaccia** (il pacchetto UI di Nathan Gibson, CC BY
  4.0 — vedi `CREDITI.txt`): ogni bottone del gioco fa click e passaggio da
  solo (`SoundManager._su_nodo_nuovo`), più apri, chiudi, errore, ok,
  sblocco, vittoria, notifica, carta, missione.
- **Le icone** del pacchetto (`assets/ui/icone/`): euro, orologio, occhio,
  cuore, fulmine, pizza, pacco, stella…
- **Il menu di pausa** rifatto, e tutti gli altri pannelli fotografati uno
  per uno (`tools/foto_pannelli.gd`) e sistemati: il negozio non copre più
  la scheda dei soldi, il pannello di casa sta sempre in mezzo allo
  schermo, la schermata d'inizio si misura col font nuovo, il riepilogo
  della giornata ha il velo scuro dietro.

### 2. Lo stemma col tasto G

> *«Non si riesce a rubare lo stemma premendo G.»*

Il cartello diceva G, ma G cambiava arma: lo stemma stava su un altro tasto.
Adesso **G fa la cosa che c'è da fare**: se guardi una macchina con lo
stemma (`car_3d.puo_stemma()`), te lo prendi; se no cambia arma come prima.
Il cartello sulla macchina dice `[G] arruobbe 'o stemma "…"` e il joypad
traduce G nel suo tasto. Prova: `tools/prova_stemma.gd`.

### 3. La scopa

> *«Migliora il minigioco di scopa con carte a miglior risoluzione, tabella
> punteggi. Spiega al giocatore che vincendo ha sbloccato la sfida col
> prossimo maestro di scopa.»*

- **Carte in alta risoluzione**, ritagliate dalla scansione intera del
  mazzo napoletano (`tools/carte_hd.py` → `carte.gd texture_hd()`), col
  retro in HD.
- **Il tavolo rifatto** (`pannello_scopa.gd`): le carte grandi e leggibili,
  il **tabellone** dei punti (carte, denari, settebello, primiera, scope)
  sempre visibile, la **scala dei maestri** a destra con le puntate.
- **Quando vinci**, un riquadro lo dice chiaro: *SFIDA SBLOCCATA* col nome
  del prossimo maestro (per esempio *'O Professore*) e dove trovarlo.

### 4. Il vigile

> *«Il vigile è sparito, vedi che fine ha fatto.»*

Due guasti, uno sopra all'altro. Il primo: i vigili delle piazze si
costruivano **prima** che la piazza sapesse chi era (`_build_vigili` stava
in `_ready`, la configurazione arriva dopo), e nelle piazze non di casa non
nasceva nessuno. Adesso nascono in `configura()`, una volta sola. Il
secondo: quello di casa c'era, ma **fermo per sempre** davanti a un punto
del giro finito dentro a un ostacolo: non ci arrivava mai, e non passava al
successivo. Adesso il giro si accontenta di 60 cm, e dopo sei secondi senza
avanzare il punto si sposta dove sta lui e si va avanti. Sonda:
`tools/sonda_vigile.gd`.

### 5. Saltare e arrampicarsi, sempre

> *«Fai in modo che il giocatore sempre e comunque possa saltare e
> arrampicarsi su ostacoli, per evitare che si blocchi o si incastri.»*

- **Gli appigli**: saltando contro qualcosa fino a 2,2 metri, il giocatore
  ci sale sopra (cofani, tetti delle macchine, muretti, bancarelle, casse).
- **Lo sbroglio**: se sei incastrato fra due macchine o fra una macchina e
  un muro e non ti muovi da un po', il gioco cerca il posto libero più
  vicino e ti ci mette; se salti da incastrato, prima ti libera.
- **Le macchine hanno l'altezza vera**: la loro capsula era alta 2,2 metri
  per tutte, e non ci si poteva salire sopra. Adesso è l'altezza della
  carrozzeria (1,3–2,2 m).
- Prova: `tools/prova_ncastro.gd`.

### 6. Il lotto

> *«Migliora il gioco del lotto al tabaccaio, non si capisce niente, non si
> capisce come vi si accede né come funziona.»*

- **Si vede dove si gioca**: un'insegna **LOTTO** sul tabaccaio e sotto al
  BAR di ogni piazza, e il cartello dei comandi dice `[2] gioca 'o LOTTO`.
- **Il pannello rifatto** (`pannello_lotto.gd`): in alto come funziona in
  tre righe (scegli da uno a cinque numeri, scegli la ruota e la puntata,
  l'estrazione è la sera), la schedina con i numeri da cliccare, la
  **tabella delle vincite** (quanto paga un ambo, un terno…) con le
  probabilità vere, e la smorfia del numero che hai sotto al mouse.
- **La sera**, il riepilogo della giornata dice cosa è uscito e quanto hai
  preso.

### 7. Le commissioni, affidate da una persona

> *«Migliora le quest secondarie aggiungendo un personaggio che si avvicina
> e te la affida realisticamente (es. un portapizze che ti affida le pizze
> perché a lui hanno rubato il motorino), gli oggetti del caso.»*

Ogni commissione adesso ha **chi te la dà** (`committente_3d.gd`) e **la
roba** (`robba_cummissione.gd`):

- Il committente aspetta vicino alla sua roba; quando passi a 15 metri
  alza la mano, ha il **"!"** sopra la testa e ti viene incontro. Ti
  racconta cosa gli è successo (Totore il pizzaiolo col motorino rubato,
  il pasticciere col garzone malato…), tu accetti con E e lui **ti passa
  la roba**, che vedi **in mano in prima persona** (e l'arma si mette via).
- Chi la riceve sta alla meta, ha il **"?"**, la prende dalle tue mani e ti
  paga.
- **Otto commissioni**: 'e ppizze 'e Totore (i cartoni sul motorino
  fermo), 'a spesa 'e Donna Carmela, 'o pacco 'e Zi' 'Ntuono, 'na busta e
  nun se dice niente, 'e cchiave d''o garage, **'a torta d''o battesimo**,
  'e sciure p''a nnammurata, 'a medicina.
- **La torta è fragile**: correre, saltare, arrampicarsi e prendere botte
  la rovinano (lo vedi scritto, «sana 72%»), e la paga scende con lei.

### 8. L'economia

> *«Rubando una macchina mi sembra giusto che si facciano 100 euro,
> abbastanza per pagare le spese per qualche giorno.»*

- **Le auto rubate**: utilitaria 60, **berlina 100**, lusso 135, bmw 170
  (erano 36/55/80/110). Il ricettatore la seconda della giornata la paga
  la metà, la terza un quarto, e alla quarta chiude.
- **Le spese di casa giù di un sesto**: la spesa 11–18, la luce 40–56, il
  fitto 92–118. Fanno circa **47 euro al giorno di fisse**, una sessantina
  con le disgrazie, contro i 55–66 di prima: una giornata fatta bene lascia
  da parte una ventina d'euro, una fatta male non ti affoga.
- `prova_furto` adesso controlla proprio la richiesta del capo: la prima
  berlina deve valere fra 85 e 115 euro.

### 9. Le animazioni dei corpi nuovi

> *«Molti dei nuovi modelli non hanno animazioni. Prendi tutto quello che ti
> serve dalla cartella del progetto e dagli le animazioni.»*

- **La libreria del pupo tradotta sugli altri due scheletri**
  (`tools/retarget_ual.gd`): 28 clip (parlare, parlare da seduti,
  accovacciarsi, incassare in faccia e nel petto, indicare, raccogliere,
  guidare, jab, coltellata, lavorare in ginocchio…) cotte in
  `assets/models/omo_ual.res` e `umano_q_ual.res`. Gli omini e gli umani
  di Quaternius ora fanno tutto quello che fa il pupo.
- **La tabella `RIG`** in `human_builder.gd` usa le clip tradotte dove il
  pacchetto non aveva niente; l'umano da fermo usa l'Idle vero invece
  della posa "Fermo".
- **Chi parla smette di parlare**: prima un personaggio che diceva una
  battuta restava nello stato "parla" per sempre. Adesso la parlata dura
  quanto il fumetto (`parla_per`), con i gesti.
- Fotografie: `tools/foto_retarget.gd` (la clip suonata a mano) e
  `tools/foto_animatore.gd` (la stessa passata dall'animatore vero del
  gioco).

---

## Il metodo nuovo: Git, una cartella sola

A metà versione il capo ha riorganizzato il lavoro: **niente più cartelle
numerate**. Il progetto sta in
`C:\Users\Max\Downloads\Parcheggiatore Abusivo Simulator\`, con Git:

- il progetto Godot in `Progetto\parcheggiatore-abusivo\`;
- i documenti in `DOcumentazione\`;
- le build in `Build\`;
- ogni lavoro finito e provato è **un commit**.

I commit della 0.62 sul computer del capo: la base 0.61, la UI/vigile/
stemma/salto, scopa/lotto/animazioni, le commissioni, l'economia, lo
strumento delle animazioni, i pannelli, e i documenti. Come si lavora
così è spiegato in `COME-RIPRENDERE.md`, sezione 1.

---

## La seconda metà: la biblioteca esterna dentro al gioco

> *«Costruisci la build 0.62, basandoti sugli ultimi file che hai creato
> nell'ultima chat. Inoltre, integra anche i nuovi asset che tu stesso hai
> caricato in un'altra chat ancora.»*

Mentre si chiudeva la prima metà della 0.62, un'altra sessione aveva messo
nel progetto una biblioteca di roba libera (`assets/esterni/`, guida in
`ASSET-ESTERNI.md`): materiali di Poly Haven, decalcomanie di ambientCG,
modelli di Poly Pizza e Quaternius, suoni di Freesound, icone di Kenney,
shader di godotshaders, e tre plugin (ProtonScatter, Dialogic, LimboAI).
Niente di tutto questo era usato dal gioco. La regola che mi sono dato: **entra
solo quello che si vede o si sente giocando, e che non fa il doppione di
quello che c'era già.** Ogni pezzo è stato guardato in fotografia prima di
entrare (trappola 34 della 0.60: il nome non è la cosa).

### Il terreno e i muri

- **L'asfalto delle strade larghe è vero** (Poly Haven `asphalt_02`, con la
  mappa delle normali e della ruvidezza): prima era una foto piatta con le
  chiazze chiare. Tinto più chiaro del resto del suolo, perché l'asfalto di
  Napoli è consumato, non catrame fresco.
- **La muffa alla Sanità**: un intonaco in quattro con la macchia d'umido
  che sale dal basso (`concrete_wall_003`). Si sceglie **per posizione** e
  non col dado della città (vedi le trappole).
- **Lo shader dell'intonaco** usa adesso normale e ruvidezza vere dove ci
  sono (`mappe_vere`), e resta com'era dove non ci sono.

### Le decalcomanie (`scripts/robba_esterna.gd`)

Macchie appoggiate sul terreno e sui muri, senza corpo e senza ombra:
**154 tombini** di ghisa e a grata nelle strade larghe, i **rattoppi**
d'asfalto, le **macchie d'olio anche dentro ai posti auto** (27, dove le
macchine stanno ferme davvero), le **gomme da masticare** sui marciapiedi,
la **colatura d'acqua sotto a ogni condizionatore** (366), l'**umido** in
basso sui muri, e **quattordici graffiti a tag** (karlwirbelwind, CC BY 4.0).

### 'O condizionatore era 'nu palazzo

Il modello del condizionatore che usavamo dalla 0.46 (`condizionatore*.scn`)
dentro era **un palazzo in miniatura**: 182 superfici, 235 nella versione
due, con le finestre e il tetto, rimpicciolito fino a sembrare una scatola
sul muro. Nessuno se n'era accorto perché da lontano è una scatola grigia.
Adesso lo split è fatto a codice (corpo, grata, staffe, in due misure) e
costa una frazione. I settanta file vecchi sono andati nel Cestino.

### L'arredo

Dove c'era posto, e solo lì (`_ce_sta`: palazzi, portoni, corsia, catasto
delle cose, attività): **tredici fra Vespe e scooter** in fila contro il
cordolo delle strade larghe (metà sono la Vespa di Jasmine Roberts, CC BY
3.0), **le sedie di Vienna** fuori dai bassi con la cassetta della
frutta per tavolino, **i coni** ai cantieri, **i bidoni di ferro** sui
marciapiedi, **le casse di legno** accanto ai cassonetti, **le sedie
d'ufficio** buttate. Il motorino che passa per la città è una Vespa una
volta su tre, e si sente arrivare.

### I suoni

Dodici suoni nuovi da Freesound (CC0), tagliati e portati allo stesso
volume da `tools/prepara_esterni.py`: **le chiavi** (la porta del vascio, la
commissione delle chiavi del garage), **il clacson della MiTo** e un
clacson lungo in più (il gioco sceglie da solo fra le varianti dello stesso
nome), **le monete** (tre modi di pagare), **la folla arrabbiata** quando un
autista parte a mazzate, e **il motore del motorino** che si sente in 3D e
si allontana con lui.

### Il menu di pausa ha i filtri, e le botte si sentono negli occhi

Tre filtri a schermo intero dagli shader esterni, a scelta nel menu di
pausa (**Nisciuno**, **Pellicola**, **Videocassetta**, **Lente sporca**), che
si ricordano fra una partita e l'altra. E **'a botta**: quando prendi un
colpo, per mezzo secondo i colori si separano verso i bordi e il margine
si arrossa. Stanno sotto all'HUD: sporcano il mondo, non le scritte.

### Le pozzanghere quando piove

Nella giornata di pioggia, sull'exe (Forward+), a terra si formano chiazze
d'acqua che riflettono quello che c'è intorno, con i cerchi delle gocce.
**Nella build web non ci sono**: il renderer del browser non dà agli shader
la profondità, e lo shader non si compila nemmeno. Il nodo lì non si
costruisce proprio, e sulla qualità BASSA si spegne.

### Gente nuova

**Sei corpi nuovi** dai personaggi animati della biblioteca (Quaternius,
CC0): l'uomo in giacca, quello in maglietta, l'operaio col casco giallo e
il gilet, il contadino, e **due donne**. Hanno uno scheletro loro, e come
per gli omini e gli umani della prima metà **le 28 mosse del pupo sono
state tradotte anche su di loro** (`quat_ual.res`, `tools/retarget_ual.gd`):
parlano, indicano, raccolgono, si inginocchiano. Entrano nei mestieri dei
passanti (il guappo in giacca, il marinaio contadino, l'operaio…) e più di
un terzo delle passanti sono le due donne nuove — fino a qui le donne
erano tutte pupi. **Un operaio su due nei cantieri** è quello col casco,
inginocchiato ad aggiustare.

### I soldi che se ne vanno

Il numerino accanto ai soldi usciva solo quando guadagnavi: una multa, la
spesa o una scommessa persa toglievano soldi in silenzio. Adesso esce
anche quando perdi (rosso, e scivola di lato), col **borsello che si
riempie o si svuota** (icone di Kenney).

### Chi ha fatto 'o joco

L'ultima pagina del tutoriale (tasto T o dal menu di pausa) dice chi ha
fatto cosa: le quattro licenze CC BY che **chiedono** di essere citate (la
Vespa, i due scooter, i graffiti, i suoni dell'interfaccia) e le fonti CC0.
L'elenco completo sta in `CREDITI.txt`.

### Quello che non è entrato, e perché

- **I tre plugin restano installati ma il gioco non li usa.** *ProtonScatter*
  serve a spargere roba a mano nell'editor, e la città di questo gioco è
  costruita a codice a ogni avvio: tutto quello che poteva spargere lo
  sparge già `robba_esterna.gd`, col catasto delle cose. *Dialogic* è un
  sistema di dialoghi, ma il gioco ne ha già uno suo, in napoletano, con le
  scelte e la memoria dei clienti: rifarlo con un altro strumento avrebbe
  voluto dire riscrivere tutte le battute per avere lo stesso risultato
  (resta il suo autoload, innocuo). *LimboAI* è una libreria compilata
  (GDExtension): nella build web funziona solo coi modelli d'esportazione
  «dlink» e l'isolamento cross-origin, e gli NPC del gioco hanno già i
  loro stati — non valeva un gioco web che si rompe.
- **Doppioni**: le sette macchine della biblioteca (il Car Pack del capo ne
  ha già ventotto, con la guida e il furto costruiti sopra), i quattro
  personaggi che rifacevano l'umano di Quaternius e gli omini che c'erano
  già, la sedia di plastica e i cestini piccoli (ci sono quelli del PSX).
- **Fuori tono**: la moto viola da cartone animato.
- **Materiali**: basolato, cemento e intonaco di Poly Haven non sono
  entrati: i quartieri hanno già le loro texture fotografiche, ognuno la
  sua, ed è quello che li fa riconoscere. Il cielo HDRI nemmeno: il cielo
  del gioco cambia con l'ora, e una foto ferma no.
- Tutto quello che non è usato è **fuori dall'esportazione**
  (`exclude_filter` in `export_presets.cfg`), così le build non pesano per
  roba che non si vede.

---

## Le trappole

- **Il tasto scritto e il tasto vero erano due tasti diversi.** Lo stemma
  diceva G e stava altrove. Nessuna prova lo vedeva, perché le prove
  chiamavano la funzione, non premevano il tasto. `prova_stemma` adesso
  preme G.
- **`position` sui Control ancorati.** Una volta dentro all'albero, per un
  Control con le ancore non a zero `position` e `offset_*` non sono la
  stessa cosa: il banner degli eventi finiva fuori schermo. Si usano gli
  offset.
- **Il vigile nato troppo presto.** Una cosa costruita in `_ready` non sa
  ancora cosa le dirà `configura()`: le piazze non di casa restavano senza
  vigile. Chi dipende dalla configurazione nasce nella configurazione.
- **Un punto del giro dentro a un ostacolo** ferma una guardia per sempre.
  Ogni giro ha bisogno di un "non ci arrivo, passo oltre".
- **La capsula alta 2,2 metri per tutte le macchine**: non ci si poteva
  salire sopra, ed era proprio lì che ci si incastrava.
- **Il retarget e la faccia.** L'umano di Quaternius a riposo guarda 46°
  di lato rispetto alla sua camminata: tradotta senza correzione, ogni
  clip lo girava. La direzione si prende dalla sua `Walk`, non dalla testa
  (che è inclinata).
- **Lo stato "parla" senza uscita.** Un'azione che diventa uno stato deve
  sapere quando finisce.
- **Il committente leggeva la sua posizione prima di averla.** La posizione
  si mette prima di `add_child` quando `_ready` la legge.
- **Le altezze scritte a mano.** La schermata d'inizio contava 18 pixel a
  riga: col font nuovo erano di più, e i comandi finivano sotto al bordo.
  Adesso si misura il font.

### Le trappole della seconda metà (gli asset esterni)

- **Un `.blend` dentro ai plugin blocca l'import.** Le demo di ProtonScatter
  si portano dietro un file di Blender: Godot, senza finestra, prova ad
  aprirlo con Blender e resta lì per sempre. È anche il motivo per cui
  l'altra sessione, su Windows, vedeva `--headless --import` piantarsi.
  Adesso in `project.godot` c'è `import/blender/enabled=false`.
- **Una texture rigenerata non esiste finché non si reimporta.** La colatura
  sotto agli split era invisibile: `prepara_esterni.py` aveva riscritto il
  PNG, Godot usava ancora quello vecchio. Dopo lo script, sempre `--import`.
- **Il dado della città è uno solo.** Aggiungere la muffa come quarto muro
  della Sanità ha spostato tutti i numeri pescati dopo, e `prova_arredo` ha
  perso una cisterna dall'altra parte della città. La muffa si sceglie
  dalla posizione del muro; l'arredo nuovo ha un seme suo.
- **Il condizionatore era un palazzo.** Un modello si apre e si contano le
  superfici, non si guarda da lontano.
- **Senza finestra, i MultiMesh mentono.** La sonda delle decalcomanie
  diceva che stavano tutte all'origine: in headless le trasformazioni delle
  istanze sono l'identità. Si misura con xvfb.
- **Un motorino contro il muro di un vicolo da quattro metri è un tappo.**
  `prova_ntuppate` ha trovato un passante piantato a Spaccanapoli contro una
  Vespa davanti a un basso: i bassi stanno nei vicoli, quindi i motorini
  «davanti al basso» sono usciti tutti.
- **Il vigile che tremava davanti al banco del bar.** Il posto dove prende
  il caffè sta fra il bancone e i tavolini: se non ci arrivava, spingeva lì
  davanti fino al tetto di quaranta secondi. È saltato fuori solo adesso
  perché ci va una volta su due e la prova guarda due minuti. Ora, fermo
  due secondi, si appoggia dove sta; e lo stesso vale per il giro.
- **Gli a-capo.** Il repository del capo ha `core.autocrlf=true`: in Git i
  file stanno con gli a-capo Unix, nella cartella alcuni con quelli di
  Windows. Il contenitore parte dalla cartella, quindi certi `.gd` qui
  avevano gli a-capo di Windows, e uno script Python che li riscriveva li
  cambiava tutti: la patch diventava «tolto e rimesso tutto il file». Le
  patch adesso si fanno su una copia normalizzata (`tools/sh/sincro.sh`),
  e chi riscrive un file lo apre con `newline=''`.
- **La build web che non partiva.** La libreria di LimboAI, anche non
  usata, finiva nell'esportazione: nel browser il caricatore di Godot si
  fermava prima ancora di cominciare («GDExtension libraries are not
  supported»). Nessuna prova in GDScript lo poteva vedere; l'ha visto
  Chromium, aprendo la build come farebbe itch.io. LimboAI adesso è fuori
  dall'esportazione (anche dall'exe, dove avrebbe voluto una DLL accanto).
- **Le casse che non entravano mai.** Accanto ai quattro cassonetti della
  città il posto era già preso da sacchetti, campane e roba PSX: la sonda
  (`sonda_esterni`) contava zero casse. Ora si cercano fino a sei metri e
  mezzo.

## La lezione

**Guardare, non leggere.** Quasi tutto quello che il capo ha trovato in
questa versione — la scritta che copre, il tasto che non va, il vigile che
non c'è, il lotto che non si capisce — passava tutte le prove. Le prove
leggono i numeri; il capo guarda lo schermo. Da questa versione ogni
pannello ha la sua fotografia (`foto_hud`, `foto_pannelli`, `foto_lotto`,
`foto_ui`, `foto_cummissione`, `foto_animatore`), e la regola è: **se non
l'ho visto in una foto, non è fatto.**

E dalla seconda metà una lezione sorella: **una biblioteca non è una lista
della spesa.** Degli asset esterni ne è entrato forse un quarto. Il resto
faceva il doppione di cose che il gioco aveva già e che funzionavano, o
chiedeva di rifare un sistema (i dialoghi, i comportamenti) per ottenere
lo stesso risultato con uno strumento diverso. Il criterio è stato uno
solo: si vede o si sente giocando? Se sì, e se non rompe niente di quello
che c'era (le prove della città, la build web), entra.
