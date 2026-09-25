# Novità della v0.61 · **'O juoco, rifinito**

*24 settembre 2026*

La 0.61 non aggiunge città: rimette a posto il **giocare**. Il capo ha
giocato una giornata intera e ha portato tre cose precise, più una
richiesta generale:

> *«In questa build ti dedichi a: 1. rifinire, 2. bilanciare, 3. arricchire
> il gameplay. A — I waglioni che assumi per lavorare al posto tuo non
> funzionano: controlla che davvero fanno parcheggiare le auto e si prendono
> i soldi. Ogni sera passi e ritiri la tua parte. B — Le armi acquistate non
> si vedono bene in mano e non si capisce se si stanno usando o no. C — Ri
> bilancia l'economia (un'auto rubata vale tantissimo, ad esempio). Poi
> rifinisci un po' tutto e arricchisci con nuove attività, dialoghi,
> personaggi speciali.»*

---

## A · I guagliuni lavorano davvero

### Cosa non andava — misurato, non supposto

Si è scritta una prova nuova, `prova_guagliune_vere`: assume un guaglione
in ognuna delle quattro piazze, porta il giocatore in mezzo alla città e
guarda per quattro minuti. Il primo risultato:

| piazza | incasso in 4 minuti | clienti |
|---|---|---|
| la tua | €4 | 2 |
| stadio | €0 | 0 |
| mercato | €19 | 3 |
| cornetteria | €0 | 0 |

Il capo aveva ragione, e le cause erano **sei**, tutte silenziose:

1. **Nella piazza di casa arrivava una macchina sola.** La regola «fuori
   servizio arriva un'auto per volta» aveva l'eccezione per il guaglione in
   `posteggio_3d.gd` (le piazze comprate) ma **non** in
   `zone_vicolo_3d.gd` (la piazza di casa).
2. **La piazza di casa contava le auto di tutta la città.** Con tre macchine
   in coda allo stadio, credeva di essere piena. Adesso conta solo le sue
   (`zona_id == "piazza"`).
3. **Allo stadio non arrivava nessuno in coda, mai.** I varchi delle piazze
   comprate si cercavano in mezzo ai quattro lati; allo stadio erano tutti
   dentro ai palazzi, e il ripiego metteva la coda **dentro alla curva**.
   Le macchine nascevano, sbattevano e se ne andavano. Adesso si provano
   cinque punti per lato a quattro e otto metri, e il rivale e l'armiere
   non contano più come muri (alla cornetteria bastavano loro due).
4. **Il cliente perdeva la pazienza per colpa tua.** `in_servizio` è vero
   in *qualunque* piazza tua: stavi allo stadio e al mercato il cliente si
   spazientiva e se ne andava un passo prima che il guaglione arrivasse.
   Adesso l'orologio corre solo se stai **in quella** piazza, e mai mentre
   il guaglione gli corre incontro (`guagliuno_arriva`).
5. **Il guaglione camminava a 1,5 m/s in linea retta**, e una panchina lo
   fermava per ventidue secondi. Adesso **corre** (3,6 m/s), usa il passo
   della città (`Passo.verso`) e, se resta incastrato, fa il giro largo.
   Dopo una macchina cerca subito la prossima invece di tornare al posto.
6. **Pagavano come pagano a te.** Si usava la probabilità di pagamento del
   giocatore (regia, coppola, fama): un cliente su tre gli scappava. Adesso
   ha la sua (`paga_chi_guagliuno`: otto su dieci da nuovo, più di nove da
   esperto).

E una settima trovata strada facendo: **la capsula del guaglione, a bordo,
spingeva la macchina in aria** — un'auto posteggiata a sette metri
d'altezza. Dentro alla macchina adesso non ha corpo.

Dopo:

| piazza | incasso in 4 minuti | clienti |
|---|---|---|
| la tua | €71 | 7 |
| stadio | €31 | 6 |
| mercato | €19 | 4 (i posti sono quattro) |
| cornetteria | €14 | 2 (di giorno è morta apposta) |

Poi si è ribilanciato (vedi C): il guaglione rende **tre quarti** di un
cliente tuo invece del 90%, e senza la mancia della bella manovra.

### La sera

*«Ogni sera passi e ritiri la tua parte»*: adesso è la forma del giro.

- Quando non ha niente da fare il guaglione **sta al posto suo** (prima
  faceva la ronda dei quattro angoli e la sera bisognava cercarlo), e
  quando gli passi vicino con soldi in mano ti chiama lui.
- Alle **quattro** (fine giornata) smette, torna al posto e ti aspetta.
- Alle **nove di sera** un cartello ti dice chi ha soldi e quanti.
- Nel riepilogo della mattina c'è quanto hai ritirato e quanto si sono
  tenuti per la metà quelli dove non sei passato.

## B · Il fierro si vede, e si vede il colpo

L'arma stava appesa all'osso della mano del corpo, che in prima persona sta
**sotto all'inquadratura**. Adesso c'è `arma_fp.gd`: un modellino appeso
alla telecamera, in basso a destra, con il pugno e la manica.

- **Si vede in mano** (cric = chiave a croce, mazza = tubo col nastro,
  curtiello, pistola del pacchetto PSX, kalash fatto a pezzi).
- **Si vede il colpo**: fendente da destra a sinistra (cric e mazza),
  stoccata (curtiello), rinculo con vampata, luce e **scia** fino a dove
  arriva il proiettile (pistola e kalash), con le scintille dove colpisce.
- **Si vede il cambio**: con [G] l'arma scende e risale.
- **Si vede se hai preso**: una crocetta attorno al mirino per un decimo
  di secondo (rossa se il colpo è forte).
- **Si sente**: lo sparo è un suono vero (prima era un pugno a metà tono),
  e i colpi a vuoto con un'arma fanno il fruscio.
- Il modello sul corpo getta solo l'ombra.

Le pose del fendente non sono state scritte a occhio: si è cercato dove
finiscono mano e punta sullo schermo (vedi «Le trappole»).

## C · L'economia

La misura nuova è **la giornata tipo** (`GameManager.GIORNATA_TIPO` = €80:
ventidue clienti serviti bene, senza niente addosso). Ogni entrata si
confronta con quella.

| cosa | prima | adesso |
|---|---|---|
| utilitaria rubata (la prima del giorno) | €130 | €36 |
| berlina | €220 | €55 |
| lusso | €350 | €80 |
| bmw | €490 (sei giornate) | €110 |
| calo del ricettatore a macchina | −32% | −38% |
| pavimento | un quarto | un quinto |
| macchine al giorno | senza limite | **tre** («'o piazzale è chino») |
| stemmi (Cavallino / Tridente / Stella) | 25 / 18 / 20 | 10 / 7 / 8 |
| lavoretto degli stemmi, a stemma | 28 | 16 |
| resa del guaglione | 0,90 | 0,75 |

Il massimo che si fa in un giorno di furti adesso è tre bmw di fila: €220,
meno di tre giornate. `prova_furto` guardava che la bmw non superasse
**seicento euro** — cioè accettava il bug che il capo ha trovato giocando.
Adesso la guarda contro la giornata tipo.

## Rifinire

- **Chi te 'o vede fà**: rubare un'auto, staccare uno stemma o sbagliare
  un borseggio costa in base a quanta gente c'è entro 14 metri. In un
  vicolo vuoto sei decimi, con sette persone il doppio. Il gioco ti dice
  quanti ti hanno visto.
- Il **garage** scrive sull'insegna quanto paga e quante macchine ha già
  preso oggi.
- Il **riepilogo** della mattina dice quanto hai ritirato dai guagliuni e
  quanto hai fatto al garage.
- Il guaglione non corre più verso una macchina se nella piazza non c'è un
  posto libero (al mercato faceva avanti e indietro sessanta volte).
- Le macchine incastrate in una piazza dove non ci sei vengono messe in
  coda invece di andarsene (nessuno le vede; era un cliente perso per
  niente).
- Una pagina nuova nel tutoriale (T): «Facce nove e regole nove».

## Arricchire

- **Gennarino 'o Nuovo** — l'abusivo dell'abusivo. Berretto rosso e
  cartone con scritto POSTEGGIO. Qualche giorno si presenta in una delle
  tue piazze e posteggia i tuoi clienti mettendosi in tasca i soldi. Ci
  parli: lo cacci (se hai poca fama torna), ti fai dare la metà, **lo
  assumi gratis** (se lì non hai già un guaglione, e quello che ha in tasca
  diventa la prima cassa), o lo lasci fare. Se lo meni scappa e i soldi
  cadono.
- **'O turista spierzo** — camicia gialla, cartina al contrario, zaino
  davanti. Ti chiama per strada e vuole andare in un'altra piazza. Lo
  accompagni (sopra alla meta si accende una colonna gialla, tre minuti di
  tempo, mancia da €12 a €27 e la voce che gira bene), gli spieghi la
  strada a gesti (€2), gli dici di tenere il portafoglio in tasca (€1 e un
  po' di reputazione) o fai finta di non capire.
- **'O panaro 'e Donna Filumena** — un balcone sopra alla tua piazza. Due
  volte al giorno cala il cesto con la corda e chiama: vuole cinque
  sigarette o un caffè. Glieli metti nel panaro e ti cala i soldi.
- **Battute nuove**: sei consigli per strada nuovi (il giro della sera, i
  testimoni, il garage, il panaro, il turista, Gennarino) e una decina di
  frasi fra ostili, neutre, amiche e di notte.

---

## Le trappole

1. **La prova che difendeva il bug.** `prova_guagliune` era verde da cinque
   versioni: guardava esperienza, umore e salvataggio — i numeri — e
   nessuno aveva mai guardato **la piazza**. Il guaglione non funzionava e
   la prova non poteva saperlo.
2. **Due copie della stessa regola.** L'eccezione «col guaglione le auto
   continuano ad arrivare» era scritta in `posteggio_3d.gd` e mancava in
   `zone_vicolo_3d.gd`. Il commento di `_guaglione_lavora` lo diceva pure:
   *«una riga tolta in due posti è una riga che si dimentica in uno dei
   due»*. Stavolta è successo con una riga aggiunta.
3. **Il ripiego che sembra funzionare.** Quando `_scegli_varchi` non
   trovava niente, ripiegava sul centro della piazza, senza dire niente.
   Allo stadio il centro è la curva. Adesso la sonda (`sonda_posteggi`)
   stampa perché un punto è scartato, e la coda si sceglie fra venti varchi.
4. **I cristiani contati come muri.** Il controllo «ci sta una macchina?»
   guardava anche lo strato dei personaggi: alla cornetteria il rivale e
   l'armiere murano mezza piazza.
5. **Il corpo di chi sta dentro alla macchina.** Il guaglione a bordo
   segue la macchina con la sua capsula: il motore fisico la risolve
   spingendo l'auto in su. Sette metri.
6. **I muri invisibili.** Gennarino nasceva due metri fuori dalla piazza di
   casa e restava appiccicato al muro invisibile che tiene dentro il
   giocatore: `move_and_slide` lo rimetteva fuori a ogni fotogramma.
7. **L'arma ruotata attorno al pugno.** Il primo fendente ruotava tutto
   attorno alla mano: la manica si alzava di traverso sullo schermo come
   una sbarra. Poi, ruotando attorno alla spalla, il colpo usciva tutto
   **sotto** all'inquadratura. Le pose giuste sono uscite cercando, con
   un conto, dove finiscono mano e punta sullo schermo.
8. **Il modello che si chiama come la cosa.** Nel pacchetto PSX il «cric»
   era un gomito di tubo idraulico e la «mazza» un manganello col manico
   laterale. Sul corpo, da lontano, passano; a trenta centimetri
   dall'occhio no. In prima persona sono fatti a mano.
9. **Il programma della giornata che azzera la prova.** Il panaro rifà il
   suo programma quando cambia la giornata; la prova cambiava la giornata
   dopo avergli dato la richiesta, e lui la cancellava.

## La lezione

**Una prova che guarda i numeri non guarda il gioco.** Il capo ha trovato
in una partita quello che quaranta prove non vedevano, perché nessuna
guardava la cosa che vede lui: una piazza, un guaglione, delle macchine, i
soldi che arrivano o no. La prova nuova (`prova_guagliune_vere`) fa
esattamente quello — e ha trovato sette guasti in un pomeriggio. Da qui in
avanti, per ogni meccanica che rende soldi, una prova che la **gioca**.
