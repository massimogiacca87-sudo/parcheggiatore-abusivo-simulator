# Novità v0.43b — 'O vigile mo' te vede

---

## 1. Farsi mettere sotto: fastidioso, non grave

Era la cosa più antipatica del gioco: **un secondo e mezzo** per terra con
la camera di traverso e nessun controllo, più **ventotto punti di ossa**.
In una giornata da quattro minuti erano dieci secondi buttati e mezza barra
della salute, per una cosa che ti capita mentre stai facendo tutt'altro.

Deve restare una cosa da evitare — la botta si sente, la camera cade, il
motorino ti urla dietro — ma non deve rovinare la partita.

| | prima | adesso |
|---|---|---|
| tempo per terra | 1,40 s | **0,55 s** |
| motorino della piazza | 28 ossa | **9** |
| motorino di strada | 22 | **7** |
| auto in manovra | 9 + 5·velocità | **3 + 1,6·velocità** |

E **la sedia sdraio cura di più**: da 3,2 a **7 punti di ossa al secondo**
(il sospetto continua a calare di 6). Dieci secondi di sdraio sono settanta
punti di salute — è l'ospedale dei poveri, e costa il tempo in cui non
lavori mentre le macchine arrivano lo stesso.

---

## 2. Il vigile non si accorgeva di te. Mai.

Avevi ragione, e la misura è impietosa. Ho fatto girare tre minuti di
piazza con il player fermo in mezzo che faceva **un'azione rischiosa ogni
dieci secondi** — cioè uno che lavora sporco — campionando ogni mezzo
secondo cosa faceva il vigile.

| | prima | adesso |
|---|---|---|
| tempo cieco (chiacchiere + bar) | **42,5%** | 17,9% |
| tempo in cui ti vedeva davvero | **7,8%** | 41,3% |
| sospetto massimo raggiunto | **19** | 94 |
| sospetto medio | **2** | 33 |
| è venuto a parlarti | **MAI** | sì (26% del tempo) |

La soglia perché venga a parlare è 42. **Con un'azione rischiosa ogni dieci
secondi per tre minuti, il sospetto arrivava a 19 e stava in media a 2.**
Non è che il vigile fosse indulgente: non poteva accorgersi di te nemmeno
volendo.

### Le tre cause, e cosa ho cambiato

**Il sospetto evaporava.** `AMBIENT_COOL_RATE` era **4 punti al secondo**:
qualunque cosa facessi spariva in tre secondi. Sceso a **0,8**. Adesso
un'azione vista vale venti punti e nei dieci secondi dopo se ne perdono
otto — lavorare sporco sotto i suoi occhi ti porta alla soglia in un minuto
e mezzo. E restano tutti i modi di calmarlo: la sigaretta, il caffè, la
sedia, e parcheggiare bene.

**Stava fermo quasi metà turno.** Fra una chiacchiera e un caffè la
"finestra per lavorare" non era una finestra: era la regola. Le pause
adesso arrivano ogni 30-52 secondi invece che ogni 14-26, e durano 7 e 11
secondi invece di 9 e 15. Il momento buono c'è ancora — ma bisogna
aspettarlo.

**Vedeva a quindici metri** in una piazza che è 34 per 54. Adesso venti.

**E soprattutto: sopra la soglia ti viene a cercare.** Prima doveva
*averti in vista* per decidere di venirti a parlare, e siccome ti vedeva
l'8% del tempo quel momento non arrivava. Un vigile che ha deciso che sei
un problema non aspetta di incrociarti. Restano due vie di scampo, ed è
giusto che restino: **sotto all'ombrellone non ti trova** (quei venticinque
euro adesso valgono davvero), e fuori da venticinque metri si fa i fatti
suoi.

La risposta che gli fa pietà compra **mezzo minuto** invece di
tre quarti.

---

## 3. Restyle: tre modelli nuovi, e il mondo messo insieme

### Il pezzo che vale più di tutti, di nuovo

Il **balaustrino** della v0.43 gira su **5.591 istanze** — le ho contate. È
il numero che spiega perché quel modello da centoventi triangoli, infilato
dentro al MultiMesh che c'era già, cambia la faccia di tutta la città a
costo zero.

### I tre nuovi

| | |
|---|---|
| **Sedia da bar** | vimini intrecciato su struttura d'alluminio. L'intreccio non è una texture: sono sette stecche orizzontali e sei verticali, e a due metri leggono come vimini |
| **Motorino parcheggiato** | sul cavalletto, quindi **pende di otto gradi** — è quel dettaglio a farlo leggere come parcheggiato invece che appoggiato per terra. Con specchietti, bauletto, faro e targa |
| **Cassette della frutta** | pila da tre, colori diversi, aperte sopra (quattro pareti e un fondo, non un cubo) e quella in cima piena di arance |

### E messi insieme

**Un mondo credibile non è fatto di oggetti belli sparsi a caso: è fatto di
oggetti che stanno insieme.** Un cestino da solo è un cestino; un cestino
con accanto tre cassette impilate, un motorino appoggiato al muro e un
cassonetto mezzo aperto è un angolo di Napoli. È la stessa roba, messa
vicina.

Ci sono adesso **quindici angoli di strada** composti, in tre varianti che
si ripetono con qualche grado di differenza — come si somigliano gli angoli
veri di una città senza essere identici:

1. motorino appoggiato + cassette + cestino
2. cassonetto col motorino accostato (la scena che spiega perché non si
   passa)
3. cassette + panchina + cestino, l'angolo tranquillo

Ognuno con il suo ingombro solido: non ci si cammina dentro.

**E il bar della piazza**, che è il posto che il giocatore guarda più
spesso di tutti — perché è lì che aspetta il momento buono — ha adesso tre
tavolini di marmo con la tazzulella sopra e sei sedie di vimini girate a
caso, come stanno le sedie di un bar quando nessuno le ha rimesse a posto.

Contate in città: 5.591 balaustrini, 36 lampioni, 23 cestini, 9 motorini
fermi, 9 pile di cassette, 5 cassonetti, 11 panchine, 3 tavolini e 6 sedie
al bar.

---

## Il pacchetto

Di nuovo al muro: 30,01 MiB. I manifesti sono scesi da 288 a 256 pixel —
**29,98 MiB**.

- `ParcheggiatoreAbusivo-v0.43b-Windows.tar.xz`
- `ParcheggiatoreAbusivo-v0.43b-Web-itchio.zip`
- `ParcheggiatoreAbusivo-v0.43b-Sorgenti.zip`
