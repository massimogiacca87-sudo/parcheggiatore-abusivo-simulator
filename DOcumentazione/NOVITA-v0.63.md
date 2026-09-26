# Novità della v0.63 · 'O Duttore

26 settembre 2026. Una richiesta sola del capo, dopo la 0.62:

> *«Il boss di fine livello (Borrelli) non esce più. Voglio che appaia
> sempre in uno dei seguenti casi: A — 5% di possibilità alla fine di ogni
> giornata, che aumenta ogni giorno del 5%. Il primo giorno non può
> apparire. B — Dopo il primo giorno, quando il vigile chiama i Carabinieri
> (quando il suo sospetto è al massimo o quando ti è venuto vicino 3 volte e
> l'hai mandato via per 3 volte) c'è l'1% che chiama Borrelli invece, che
> aumenta del 10% ogni volta. Per battere Borrelli non funzionano le armi,
> perché ti riprende col telefono e non puoi picchiarlo. Puoi solo fare
> finta di niente fumando sigarette e bevendo caffè e standogli lontano.
> Dopo che si è calmato puoi parlarci e spiegargli che è per le creature.
> Col tempo dobbiamo ideare e implementare altri boss ed un vero finale.»*

---

## Perché non usciva più

Tre cose, tutte e tre senza errori a schermo:

1. **La sera diceva sempre di no.** Dalla 0.53 `boss_stasera()` era
   scritta per tornare `false`: Borrelli era stato tolto dal calendario, e
   restavano solo le due porte all'uno per cento (verbale e violenza vista).
2. **La radio del vigile si scaricava.** In `vigile_3d.gd` c'era un
   `_chiamata_fatta` che si accendeva alla prima chiamata e **non si
   spegneva mai**: dal secondo verbale in poi quel vigile non chiamava più
   nessuno, né la pattuglia né Borrelli. Quindi la porta del verbale si
   apriva una volta per vigile per partita, all'uno per cento.
3. **«Mandato via tre volte» non esisteva.** Il capo lo ricordava come
   regola; nel codice il vigile chiamava solo a sospetto pieno (dopo il
   verbale). Adesso c'è.

## Le due porte, col dado che cresce

**A — la sera.** Quando cala la notte, dal secondo giorno: 5% il secondo
giorno, 10% il terzo, 15% il quarto… (`PROB_SERA_PASSO` = 0,05 per ogni
giorno passato senza di lui). Il primo giorno mai.

**B — la chiamata.** Dal secondo giorno, ogni volta che il vigile alza la
radio per i carabinieri: 1% la prima volta, poi +10 punti a chiamata
andata a vuoto (1, 11, 21, 31…). Le chiamate del primo giorno non contano.
In media arriva **alla quarta-quinta chiamata** (misurato: 4,59 su 5.000
partite).

**Quando arriva, i due dadi ripartono da capo.** È un'interpretazione mia:
senza ripartenza, dal ventunesimo giorno la A varrebbe il 100% e Borrelli
tornerebbe un appuntamento fisso di tutte le sere — che è esattamente quello
che la 0.53 aveva tolto. Con la ripartenza resta un «prima o poi, e più
aspetti più è vicino». Se il capo lo vuole senza ripartenza è una riga
(`borrelli_venuto()` in `game_manager.gd`).

**La violenza vista non lo chiama più**: il capo ha detto «in uno dei
seguenti casi», e lì c'erano solo la sera e la chiamata. Chi ti vede menare
chiama i carabinieri, come prima.

I due contatori (`borrelli_ultimo_juorno`, `borrelli_chiamate`) stanno nel
salvataggio.

## Il vigile mandato via tre volte

Ogni volta che il vigile ti viene a parlare e se ne torna in ronda **senza
averti fatto il verbale** — gli hai fatto pena con le criature, gli hai
risposto storto, o te ne sei andato e ha chiuso lui — l'hai mandato via. Alla
terza volta nella stessa giornata dice *«N'ata vota? E mo' abbasta.»* e alza
la radio. Il conto è della giornata (tutti i vigili insieme) e riparte ogni
mattina (`vigile_mannato_oggi`, `VIGILE_MANNATO_MAX` = 3).

La radio adesso ha solo un fermo di venti secondi contro le chiamate doppie.

## Borrelli non si tocca

Prima un pugno gli arrivava (si vedeva la reazione) e gli alzava la furia.
Adesso **non arriva proprio**: si scansa col telefonino alzato e grida
(*«STO RIPRENNENNO TUTTO!»*, *«BRAVO, FALLO N'ATA VOTA. 'A GENTE VEDE.»*),
il colpo suona a vuoto, non compare la crocetta del colpo a segno, e a
schermo esce *«Nun 'o puo' tuccà: te sta riprennenno.»*. La furia sale di
60 e il sospetto di 25. Vale per pugni, cric, mazza, coltello e pistole: tutti
passano da `receive_punch`.

## Fare finta di niente

La furia scende così:

| cosa fai | lontano (> 6 m) | vicino |
|---|---|---|
| sigaretta **o** caffè | −11 al secondo | −4,5 al secondo |
| niente | −2,8 al secondo, ma non sotto 44 | niente |

La soglia per parlargli è 34: **scappare e basta non basta mai**. Il caffè
vale per tutto il quarto di minuto della sua spinta, sia quello di tasca
(tasto del caffè) sia quello preso al banco. Dentro casa si calma come prima.

Quando è calmo si ferma: **[E] parla cu Borrelli**, e la risposta giusta resta
*«Ma nun è pe' mme… è pp''e ccriature»* (o il caffè offerto, se siete vicino
a un bar). Convinto: €25, reputazione, e la giornata finisce bene.

## Dove compare

Nasceva sempre all'ingresso della piazza di casa: se la notte ti trovava al
Vomero, camminava un minuto per mezza città. Adesso nasce **a 20-30 metri da
te**, in un punto di strada da cui si arriva a piedi (`_nasce_borrelli` in
`zone_vicolo_3d.gd`). Se sei in casa, aspetta all'ingresso della piazza. E
cammina sulla collina del Vomero invece di attraversarla.

## Le prove

- **`prova_borrelli`** (riscritta): i dadi. A giorno per giorno, tirata vera
  al giorno 3 (9,82% su 20.000 sere), B chiamata per chiamata, 100.000 prime
  chiamate (0,99%), la media delle chiamate che servono, nessuna doppia,
  niente fuori turno, la violenza che non lo chiama più, il salvataggio.
  **0 storte.**
- **`prova_borrelli_gioca`** (nuova): nella città vera. Il vigile mandato via
  tre volte chiama; la radio chiama ancora dopo la prima volta; la porta B
  porta Borrelli **a 23,5 m** dal giocatore; il pugno vero del giocatore non
  va a segno; 12 secondi lontano a mani vuote lo lasciano a 66 di furia;
  col caffè e lontano si calma in 3 secondi; la risposta delle criature lo
  manda via. **0 storte, 0 SCRIPT ERROR.**
- Ripassate: `prova_vigile`, `prova_vigile_volata`, `prova_boss`: 0 storte.

## Le trappole

1. **Una bandierina che si accende e non si spegne mai** (`_chiamata_fatta`)
   è un «una volta per partita» travestito da «una volta per chiamata». Non
   dà errori: la seconda chiamata semplicemente non parte.
2. **Una regola che il capo ricorda può non esserci.** «Tre volte mandato
   via» stava nella sua testa e non nel codice. Si controlla prima di
   «ricordarla».
3. **`sincro.sh` e `sincro_lf.py` sul PC hanno gli a-capo di Windows**: nel
   contenitore non partono (`set: -: invalid option`). Si lanciano da una
   copia portata a LF (`sed 's/\r$//'`), come descritto in
   `COME-RIPRENDERE.md`.
4. **Il progetto non entra più in un pacco solo**: con la biblioteca esterna
   sono 560 MB senza `.godot` (il ponte ne regge 400 a file). Tre tar: tutto
   tranne `assets/esterni/materiali`, poi `materiali/decals`, poi il resto
   dei materiali. Attenzione al `-C`: i due tar dei materiali vanno creati
   da dentro a `materiali`, se no si portano dietro tutto il percorso.

## La lezione

**Un boss che non esce non è un boss raro: è un boss che non c'è.** La 0.53
aveva ragione a togliere il calendario, ma una probabilità fissa bassa su
una porta che si chiude da sola dopo il primo giro dà zero. Il dado che
cresce tiene insieme le due cose: non sai quando, ma sai che succede.

## Cosa viene dopo

Il capo: *«Col tempo dobbiamo ideare e implementare altri boss ed un vero
finale del gioco.»* Le proposte stanno nella `ROADMAP.md`, sezione «I boss
che verranno e il finale», da scegliere insieme prima di scriverne una riga.
