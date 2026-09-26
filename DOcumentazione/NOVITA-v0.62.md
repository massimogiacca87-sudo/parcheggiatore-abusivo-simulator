# v0.62 — 'A faccia nova

*Parcheggiatore Abusivo Simulator · 25 settembre 2026*

Nove richieste del capo dopo una partita, e un cambio di metodo a metà
strada. Questa è la versione in cui il gioco si è rifatto la faccia —
l'interfaccia intera, le carte, il lotto, le commissioni — e in cui le
cose che "c'erano" ma non funzionavano (il vigile, lo stemma col tasto G,
le animazioni dei corpi nuovi) hanno ricominciato a funzionare.

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

## La lezione

**Guardare, non leggere.** Quasi tutto quello che il capo ha trovato in
questa versione — la scritta che copre, il tasto che non va, il vigile che
non c'è, il lotto che non si capisce — passava tutte le prove. Le prove
leggono i numeri; il capo guarda lo schermo. Da questa versione ogni
pannello ha la sua fotografia (`foto_hud`, `foto_pannelli`, `foto_lotto`,
`foto_ui`, `foto_cummissione`, `foto_animatore`), e la regola è: **se non
l'ho visto in una foto, non è fatto.**
