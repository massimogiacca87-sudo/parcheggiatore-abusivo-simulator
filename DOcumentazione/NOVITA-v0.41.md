# Novità v0.41 — 'O salvataggio, 'e guagliune e 'a forma d''o golfo

Sette cose. Due sono grosse (i salvataggi e i dipendenti), una è la
correzione di un bug che rendeva inutile metà del gioco, e una cambia
come Napoli si vede dall'alto.

---

## 1. Salvataggio vero, con quattro posti

C'era un salvataggio automatico, uno solo, e l'avevo **spento**: con una
città da girare, ritrovarsi all'avvio le piazze già comprate e la mazza in
mano toglieva la partita. Ma la risposta giusta non era spegnerlo — era
darlo in mano a te.

**Quattro slot.** Si salva quando vuoi e si carica quando vuoi.

- Dal **menu di pausa (ESC)**: `Salva 'a partita` e `Carica 'na partita`.
- Dal **menu iniziale**, `Carica 'na partita`.

Ogni posto scrive cosa contiene prima che tu ci clicchi sopra:

> `2.  €340  ·  2 piazze  ·  juorno 5  ·  03/09 18:22`

**Si salva quello che è tuo, non la giornata che stai giocando**: soldi,
piazze, affitti, guagliuni assunti, oggetti, armi, stemmi, manifesti,
decorazioni e dove le hai messe, e a che giorno sei arrivato. Sospetto,
ossa, cronometro e stelle no — quelli sono della giornata, e caricando si
ricomincia la mattina.

Una partita nuova parte sempre pulita. Quella di ieri sta ferma dov'era
finché non la richiami.

---

## 2. Le locandine si vedono intere, e il tutorial si può richiamare

Il pannello del testo partiva a metà altezza: dei due disegni se ne vedeva
la faccia e basta.

Adesso sono **tre momenti**:

1. **Le due locandine, intere**, una dopo l'altra, senza niente sopra a
   parte la barra di caricamento. E `KEEP_ASPECT_CENTERED` invece di
   `COVERED`, così su uno schermo di proporzioni diverse non se ne taglia
   nemmeno un pezzo di lato.
2. **Il tutorial**, le due pagine di testo, la prima volta che si gioca.
3. **Il menu**: *Accummenciamo · Carica 'na partita · 'O tutoriale ·
   Esci*.

Dalla seconda partita in poi si va dritti al menu, e il tutorial ci sta
dentro per chi lo vuole rileggere.

*(Una nota per me: `set_input_as_handled()` stava in cima a `_input`, prima
del controllo sulla fase. Nel menu si mangiava il click prima che
arrivasse al bottone, e il menu sembrava morto.)*

---

## 3. Napoli adesso ha la forma di Napoli

Dall'alto la città era un rettangolo con una striscia blu davanti: una
città di mare qualunque. E Napoli, su una carta, si riconosce per una cosa
sola — **sta dentro a un golfo**.

C'è un pezzo di scenografia nuovo (`golfo.gd`) fatto di tre cose:

- **La costa curva.** Una polilinea che parte da sud-ovest, sale
  disegnando il capo di ponente, scende dritta lungo la riva della città
  (quel tratto deve restare vero: è dove sta il muraglione di Mergellina),
  e risale a levante. La terra è il poligono fra la costa e un bordo
  lontano; l'acqua è la conca che resta in mezzo. Cioè un golfo.
- **La città che continua.** Milleottocento palazzi finti in un MultiMesh
  solo, sparsi lungo la costa: fitti sulla riva, radi e bassi verso
  l'interno. Servono a far finire la città *in un'altra città* invece che
  in un bordo netto.
- **Le colline e le isole.** Posillipo a ponente, il Vomero e i Camaldoli
  alle spalle, la salita di levante, e in bocca al golfo due scogli
  azzurri che tutti sanno cosa sono.

E **il Vesuvio si è spostato**: stava a nord, dritto davanti al lungomare,
in mezzo all'acqua. Da terra passava; dall'alto era la cosa che più di
tutte diceva "questa non è Napoli". Adesso sta sul braccio di levante,
attaccato alla costa.

Il mare è passato da 520×300 a 2400×1150 metri, se no dall'alto si vedeva
il bordo del piano.

Una cosa imparata piazzandole: **le colline vanno lontane**. Il primo
tentativo aveva il Vomero dove sta davvero — a filo del quartiere — e un
cono da centotrenta metri si mangiava metà dell'inquadratura d'apertura.
La regola adesso è che il piede di ogni collina stia almeno ottanta metri
fuori dal riquadro giocabile.

---

## 4. Al banco prima si guarda, poi si paga

Premere un numero comprava all'istante. Chi voleva solo sapere a che serve
l'ombrellone si ritrovava l'ombrellone e venticinque euro in meno — e la
descrizione stava nel pannello, cioè la leggeva **dopo** aver pagato.

Adesso il primo tasto **sceglie** e apre la scheda; lo stesso tasto,
premuto di nuovo, **compra**. Il pannello lo dice:

> `€25 — premi ANCORA 2 e te l'accatte.`

E il venditore te lo legge ad alta voce. Chi sa già cosa vuole preme due
volte e non se ne accorge; chi sta guardando si gira tutto il listino
senza spendere una lira. Col joypad la croce direzionale fa già il primo
tempo, quindi A compra e basta.

---

## 5. Il tempo scorre più veloce

La giornata era di sette minuti reali. Adesso è di **quattro e venti**, e
il turno passa da 560 a 380 secondi: tutte e cinque le fasi del cielo
dentro a una sessione sola, e un pezzo di notte vera in fondo — che
adesso conta anche per le luminarie.

Le auto delle piazze comprate arrivano di conseguenza più spesso (una ogni
20-30 secondi invece che 30-42): con la giornata accorciata, il ritmo
vecchio voleva dire sei clienti in tutto il turno, e una piazza da
quattrocentocinquanta euro non si ripaga con sei clienti.

---

## 6. Le piazze comprate non servivano un cliente. Mai.

Questo è il bug grosso, ed è di quelli che si vedono solo **dopo** aver
speso quattrocentocinquanta euro.

Compravi il mercato. Le auto nascevano davvero — l'ho misurato, il
rubinetto funzionava — e poi **si arrendevano tutte**. Nessun errore a
schermo, nessun crash: la piazza restava vuota per sempre e sembrava che
avessi buttato i soldi.

Tre cause insieme:

1. **Entrata e uscita erano scritte a mano**, due metri fuori dal lato
   ovest. Ma i vicoli che costeggiano le piazze sono larghi quattro metri:
   a meno due l'auto nasceva **sul cordolo**.
2. Spostata in mezzo alla corsia, l'auto partiva — e faceva tre metri.
   **Al mercato le bancarelle stanno in fila lungo tutto il lato ovest.**
   Ci sbatteva dentro, restava ferma due secondi e mezzo, si dichiarava
   bloccata e se ne andava.
3. E i **posti auto delle altre piazze erano dipinti**: strisce bianche
   appoggiate per terra e nient'altro. I posti veri esistevano solo nella
   piazza iniziale, quindi la prima auto che riuscivi a dirigere puntava
   un posto libero **a cento metri, dall'altra parte della città**.

Adesso non c'è più niente scritto a mano. Al primo frame utile ogni piazza
**si misura da sola**: prova i quattro versi possibili, e per ognuno
controlla col motore fisico — con la sagoma di un'auto, campionando il
percorso ogni due metri — quali posti d'attesa sono raggiungibili davvero.
Tiene il verso che ne ha di più.

| piazza | verso scelto | posti d'attesa |
|---|---|---|
| stadio | da ponente a levante | 1 |
| mercato | **da nord a sud** (le bancarelle chiudono i fianchi) | 4 |
| cornetteria | da ponente a levante | 1 |

E ogni piazza ha adesso i suoi posti auto veri, dai sei ai sedici. Il
posto assegnato a un'auto del mercato è **a dodici metri** invece che a
cento. Verificato: auto che arriva, aspetta, si lascia dirigere, si
parcheggia.

---

## 7. 'E guagliune: qualcuno che posteggia al posto tuo

Comprata la seconda piazza, il gioco ti chiedeva di stare in due posti
insieme. Più piazze compravi, più la partita diventava una corsa avanti e
indietro — e ognuna rendeva meno. **La conquista puniva chi la faceva.**

In ogni piazza (compresa la tua) c'è adesso uno in piedi con un cartello
di cartone: **CERCO FATICA**.

- **€25** per convincerlo, **€12** ogni sera.
- Posteggia lui, e le auto continuano ad arrivare anche se tu stai
  dall'altra parte della città. Ogni tanto lo senti tintinnare: è lo
  stesso suono dei rivali, e vuol dire la stessa cosa — quella piazza sta
  rendendo, e sta rendendo per te.
- **Rende meno di te**: prende il 72% di quello che prenderesti tu. Un
  padrone che sta al posto suo si fa pagare meglio di un dipendente, ed è
  il motivo per cui conviene comunque lavorarne una di persona.
- **I soldi non ti arrivano da soli.** Stanno in tasca a lui finché non
  passi a ritirarli con [E]. Quello che resta lì la sera, se lo tiene per
  un quarto — ed è quel quarto che rende il giro serale una scelta invece
  di una formalità.
- Se una sera non hai da pagarli, **se ne vanno tutti**. Nessun debito che
  si trascina.

**Sulla mappa (M) ci sono tutti**, e il colore dice cosa fare: grigio =
aspetta lavoro; giallo = fatica ma non ha ancora incassato; verde con la
cifra = tiene i soldi in mano. Il giro serale si progetta guardando la
carta, che è esattamente quello che deve fare una mappa.

In alto a sinistra, quando c'è qualcosa da ritirare, l'HUD lo dice:

> `€64 'n mano ê guagliune — [M] pe' vedé addò stanno`

**Le cifre.** Prima le avevo messe a €70 e €40 al giorno, e poi ho
guardato le mance vere: un'utilitaria lascia uno o due euro, una berlina
due o quattro, una di lusso quattro o otto. Un guaglione da quaranta euro
al giorno avrebbe avuto bisogno di trenta clienti solo per pagarsi la
giornata. Venticinque e dodici stanno dentro alla scala del gioco, come il
gilet da trenta e la coppola da dodici.

---

## Nel pacchetto

- `ParcheggiatoreAbusivo-v0.41-Windows.tar.xz`
- `ParcheggiatoreAbusivo-v0.41-Web-itchio.zip`
- `ParcheggiatoreAbusivo-v0.41-Sorgenti.zip`
- `TUTORIAL.txt` — con le sezioni nuove sulle piazze, i guagliuni e i
  salvataggi
