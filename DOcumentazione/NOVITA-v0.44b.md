# Novità v0.44b — 'e ttre ccose ca nun jevano

Tre segnalazioni, e due di quelle avevano la stessa causa. La terza mi ha
fatto scoprire un difetto più vecchio di questa versione.

---

## 1. La scopa, la casa e la porta: **era una riga sola**

> *Non riesco a giocare a scopa con i vecchi. Non trovo la casa e non
> riesco a entrarci, quando un vigile mi porta in casa non riesco a
> uscire.*

Tutt'e tre le cose erano lo stesso difetto, e sta in `player_fps.gd`:

```gdscript
const GRUPPI_BERSAGLIO := ["cars", "drivers", "shop", "vigili", ...]
```

Il raggio dell'interazione trova qualunque cosa gli sta davanti, ma poi
scarta tutto quello che non appartiene a uno di quei gruppi. È giusto che
funzioni così — se no si "interagirebbe" con i muri — ma vuol dire che
**una cosa nuova con cui si può parlare non funziona finché il suo gruppo
non sta scritto lì dentro. E non dà nessun errore: semplicemente non
succede niente quando premi E.**

Nella 0.44 ci sono cascato in pieno. Porta di casa, letto, moglie,
criature, i cinque tavolini della scopa e i segni delle commissioni erano
tutti costruiti bene, rispondevano tutti correttamente quando gli si
chiedeva cosa scrivere a schermo — e nessuno dei sei era agganciabile.

### Perché il collaudo non l'aveva preso

Perché chiamava le funzioni **a mano**:

```gdscript
print(porta.get_interact_prompt(Vector3.ZERO))   # → "'A casa toia — [E] trase"
```

Provava che la funzione rispondeva, non che il giocatore ci arrivasse. È
la differenza fra collaudare il codice e collaudare il gioco.

Adesso c'è `tools/prova_mira.gd`, che fa la cosa vera: **mette il player
davanti a ogni oggetto, gli fa guardare il bersaglio, e chiede al gioco
cosa ha agganciato.**

```
=== CHE SE PO' TUCCA' ===
  'a porta 'a fore       OK   'A casa toia — [E] trase · ce vonno ancora €22
  'a porta 'a dintro     OK   'A porta — [E] esce fore
  'a mugliera            OK   Nunzia — [E] consegna 'e sorde (ce vonno €22)
  'a criatura            OK   Rusella — nun tiene manco n'euro
  'o lietto              OK   'O lietto — [E] va' a durmi'
  'o tavulo 'e ciccio    OK   Ciccio 'o Guappo — ce vonno €5 p''a puntata
  'o tavulo 'e professore OK  "Primma va' a vencere a Ciccio 'o Guappo."
  'o tavulo 'e zipeppe   OK   "Primma va' a vencere a Ciccio 'o Guappo."
  'o tavulo 'e nicola    OK   "Primma va' a vencere a Ciccio 'o Guappo."
  'o tavulo 'e nonno     OK   "Primma va' a vencere a Ciccio 'o Guappo."
  'o segno d''a cummissione OK  Doje pizze 'a purtà — [E] pigliala (€29)
```

Il collaudo resta nel progetto: la prossima cosa interattiva che dimentico
di registrare la becca lui.

---

## 2. E poi c'erano altre tre cose vere

Sistemata quella riga, la prova ha trovato altro.

**Il tavolino di Nicola stava sotto terra.** Sta al Vommero, che è un
terrapieno alto tre metri. La funzione che alza gli oggetti sulla collina
guarda la posizione del primo collider, che per un `StaticBody3D` è
**locale** — (0, 1, 0) — e quindi non risultava mai dentro. Adesso la
quota se la chiede il tavolo da solo, in due righe, senza dipendere
dall'ordine in cui si costruiscono le cose.

**Il primo sfidante stava dall'altra parte della città.** I cinque
tavolini erano piazzati a caso, e il più vicino alla piazza era quello del
**boss** — che però non ti fa giocare finché non hai battuto gli altri
quattro. Chi provava a giocare a scopa trovava un vecchio che lo mandava
via. Adesso la scala si sale allontanandosi da casa:

| | dove | quanto lontano |
|---|---|---|
| **Ciccio 'o Guappo** | 'o belvedere, davanti al mare | 25 m |
| **'O Professore** | 'a piazzetta d''a fontana | 60 m |
| **Zi' Peppe** | 'o largo d''e guagliune | 110 m |
| **Nicola 'e ll'Uocchie** | 'o largo 'e levante | 150 m |
| **Don Gennaro** | 'o Vommero | 200 m |

**Le criature stavano appiccicate al letto.** Il letto ha un ingombro di
un metro e mezzo per due; una criatura seduta è alta un metro. Messe
accanto, il raggio agganciava sempre il letto. Spostate, e col collider
un po' più generoso.

---

## 3. Trovare la casa

> *Non trovo la casa.*

Una porta in fondo a un vicolo, in una città di centonovanta metri, senza
niente che la indichi, è una porta che non esiste. Tre cose:

- **'A freccia.** La stessa del cliente in attesa — che hai già imparato a
  leggere — ma verso casa, con la distanza. Compare quando serve davvero:
  quando sono passate le quattro, o quando hai in tasca abbastanza per
  chiudere il conto della sera. Non sta lì sempre: sarebbe rumore.
- **Il cartello sopra la porta**, «'O VASCIO TUOIO», che si legge da in
  fondo al vicolo.
- **La casetta sulla mappa** (M), che diventa rossa quando è ora di
  rientrare.

E il collider della porta è passato da trenta a novanta centimetri di
profondità: davanti a un basso c'è sempre appoggiato qualcosa — un
motorino, una cassetta — e con il collider incollato al muro il raggio
trovava prima il motorino.

**Uscire di casa** adesso ha il suo cartello dentro: «FORE ▸», sopra la
porta. In una stanza sola senza finestre, una porta è un rettangolo
marrone in mezzo ad altri rettangoli marroni.

E quando ti ci portano di forza, il gioco te lo dice:

> *'E carabiniere t'hanno lassato sotto 'a casa toia. Parla cu Nunzia [E],
> po' vatte a corca' ncopp''o lietto [E]. 'A porta pe' asci' fore sta
> arreto 'e te.*

---

## 4. Più suoni: **da ventidue a trentacinque**

> *Usa più suoni e animazioni di quelle che ti ho dato.*

Tredici registrazioni nuove, e tutte fanno qualcosa di preciso:

| | dove si sente |
|---|---|
| **'A folla** | il boato quando comincia la partita allo stadio. Prima era annunciato solo da una scritta |
| **'O sciuscio** | il pugno **che non prende**. Sembra un dettaglio da niente ed è informazione: senza, non capisci se hai mancato o se il click non è arrivato |
| **'O schiocco 'e lengua** | il tirchio che dice no. È il "no" napoletano, e si sente prima di leggere la battuta |
| **'A tosse** | il vigile che si schiarisce la voce **prima** di venirti a parlare. Mezzo secondo che ti dice che sta arrivando il momento |
| **'O fiatone** | sotto al trenta per cento di salute. La barra la guardi se ci pensi, il respiro lo senti e basta |
| **'O saluto** (due voci) | i passanti che ti salutano quando gli passi accanto |
| **'O rutto** | uno su dieci, invece del saluto |
| **'A botta** | quando qualcuno cade per terra |
| **'O surzo, 'a buttiglia** | la fontanella e la bancarella, ognuna col suo |
| **'E stemme** | rubarne uno e venderli non fanno più lo stesso rumore |
| **'E ppugne** | da tre registrazioni a **sei**. Sotto le quattro l'orecchio riconosce il giro |
| **'E ssorde** | due monete diverse e due manciate diverse, tirate a sorte |

**E chi parla, gesticola.** Sta in un posto solo — dentro al fumetto — e
vale per **ogni personaggio del gioco che apre bocca**: il vigile,
l'autista, 'O Zio, i vecchi della scopa, la moglie, i bambini. Nessuno di
loro ha dovuto essere toccato. A Napoli uno che parla senza mani non sta
dicendo niente.

---

## 5. Le animazioni: **ci ho provato, e l'ho misurato che non andava**

Questa è la parte in cui devo dire una cosa che non mi fa piacere.

Ho ritargettato dalla libreria universale otto clip nuove, fra cui **fermo,
cammina e corri**, per sostituire le tre andature scritte a mano — quelle
che mettono i keyframe con un `sin()` sulle anche. Sarebbe stato il
cambiamento più visibile di tutti: l'andatura di *ogni* personaggio del
gioco.

Prima di spedirle ho scritto `tools/prova_pose.gd`, che mette un rig in
piedi, gli fa fare le tre andature e stampa **dove finiscono le mani**:

```
riferimento: 'e mmane 'a nu ommo fermo stanno a circa (0.28, 0.75)

  riposo             mano sx (-0.74, 1.23)   dx (0.76, 1.22)
  locomozione 2.6    mano sx (-0.77, 1.20)   dx (0.76, 1.31)
  locomozione 7.0    mano sx (-0.60, 0.92)   dx (0.71, 0.91)
```

Le mani restavano a **(0.75, 1.23)**: cioè in croce, dove il rig le tiene
a riposo. Le clip della libreria non producono la rotazione che abbassa le
braccia, e il personaggio camminava come uno spaventapasseri.

Il difetto sta nel **ritarget delle spalle**, non nelle clip: le catture di
Mixamo, che passano per lo stesso identico codice, le braccia le muovono
eccome — `pugno` porta le mani a (0.57, 1.06) e (-0.54, 1.27), cioè
incrociate davanti, che è esattamente quello che deve fare un pugno.

**Quindi ho annullato la sostituzione e ho tolto le clip inutilizzate dal
pacchetto.** Le andature restano quelle di prima: saranno pure disegnate a
mano, ma le braccia le tengono giù. Il gancio nel codice resta, con dentro
scritto il perché e i numeri; quando avrò capito il ritarget delle spalle
si riempie una riga e basta.

Quello che **resta**, e funziona: **stare seduti**. I cinque vecchi della
scopa e le criature per terra stanno seduti sul serio, con la clip vera,
non in piedi dentro a una sedia. E il vecchio adesso guarda il tavolo —
nella 0.44 stava seduto al contrario, girato verso il muro, per un segno
sbagliato nella convenzione delle rotazioni.

---

## Il pacchetto

**29,90 MiB.** Per starci: i muri da 352 a 340 pixel, e tolte le otto clip
che non si usano più.

- `ParcheggiatoreAbusivo-v0.44b-Windows.tar.xz`
- `ParcheggiatoreAbusivo-v0.44b-Web-itchio.zip`
- `ParcheggiatoreAbusivo-v0.44b-Sorgenti.zip`
