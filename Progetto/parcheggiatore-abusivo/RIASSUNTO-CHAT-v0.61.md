# Riassunto della chat della v0.61 · 'O juoco, rifinito

*24 settembre 2026. Per chi apre la chat dopo: cosa è stato chiesto, cosa è
stato deciso, dove ci siamo fermati.*

## La richiesta

Il capo ha aperto la chat con la richiesta già scritta (quindi niente
domande preliminari, come invece prevedeva `COME-RIPRENDERE` per la 0.61):

> *«In questa prossima build 0.61 ti dedichi a: 1 rifinire, 2 bilanciare,
> 3 arricchire il gameplay. Tra le cose che ho notato giocando una giornata
> intera: A — I waglioni che assumi per lavorare al posto tuo non
> funzionano, controlla che davvero fanno parcheggiare le auto e si prendono
> i soldi. Ogni sera passi e ritiri la tua parte. B — Le armi acquistate non
> si vedono bene in mano e non si capisce se si stanno usando o no. C — Ri
> bilancia l'economia (un auto rubata vale tantissimo ad esempio). Dedicati
> poi a rifinire il gameplay migliorando un po' tutto e infine arricchisci
> il gameplay con nuove attività, dialoghi, personaggi speciali ecc.»*

A metà lavoro ha scritto solo *«Continua»*.

## Come è andata

1. **Ripartenza.** Pezzi del Progetto v0.60 presi dal suo computer col
   ponte, rimessi insieme in `/home/claude/parcheggiatore-abusivo`, Godot
   4.3 e modelli di esportazione scaricati. Tutto come descritto in
   `COME-RIPRENDERE`, sezione 1.
2. **A, misurato prima di toccare.** Scritta `prova_guagliune_vere`
   (quattro guagliuni, quattro minuti, giocatore lontano). Risultato:
   €4 / €0 / €19 / €0. Poi sette guasti trovati uno dopo l'altro (vedi
   `NOVITA-v0.61.md`), fino a €71 / €31 / €19 / €14. Il punto più grosso:
   **allo stadio nessuna macchina arrivava mai in coda** (la coda ripiegava
   dentro alla curva), e questo valeva anche per il giocatore, non solo
   per il guaglione. La sera: il guaglione aspetta al posto suo e chiama,
   cartello alle nove, riepilogo della mattina.
3. **B.** `arma_fp.gd`, il modellino sulla telecamera. Tre giri di
   fotografie (`foto_armi`): il cric del pacchetto era un raccordo
   idraulico gigante, la manica si alzava come una sbarra, il fendente
   usciva sotto all'inquadratura. Le pose finali sono state cercate con un
   conto su dove cadono mano e punta sullo schermo.
4. **C.** Tutto misurato sulla giornata tipo (€80). Auto rubate ridotte a
   circa un quarto, tre al giorno, stemmi a un terzo, guaglione al 75%.
   `prova_furto` aveva la soglia a 600 euro: accettava il bug.
5. **Rifinire e arricchire.** Testimoni sui furti, Gennarino 'o Nuovo, il
   turista spierzo, il panaro di Donna Filumena, consigli e battute nuove,
   pagina di tutoriale, riepilogo più ricco. `prova_perzone_nove` e
   `foto_sessantuno` per guardarli.
6. **Verifica, build, consegna, pulizia** (vedi sotto).

## Decisioni prese da me (da confermare col capo giocando)

- **La giornata tipo è €80** ed è il metro di tutte le entrate.
- **Il furto vale da mezza a una giornata e mezza**, tre al giorno.
- **Il guaglione rende il 75%** di un cliente tuo, senza la mancia della
  bella manovra: nella piazza di casa, da solo, fa sui due terzi di una
  giornata tua.
- **Gennarino si assume gratis**: chi si è fatto la piazza da solo non va
  convinto coi soldi.
- **Niente violenza su bambini**: Gennarino ha diciannove anni.

## Dove ci siamo fermati

La 0.61 è chiusa e consegnata. Rimasti (in `ROADMAP.md`, «Rimasto aperto
dalla 0.61»): i soldi di tutti i giorni sono stretti (spese 68/giorno) e
vanno guardati alla prima partita lunga; la prova che gioca dieci giornate;
il balcone del panaro fatto di scatole. Poi la 0.62 'E vvoce.
