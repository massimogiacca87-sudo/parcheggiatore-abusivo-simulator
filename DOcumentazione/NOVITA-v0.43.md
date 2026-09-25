# Novità v0.43 — Il mondo aspetta, il salotto è tuo, la radio suona

---

## 1. La partita comincia quando lo dici tu

Il bug che hai visto: la città cominciava a vivere appena finita di
costruire — cioè **mentre erano ancora a video le locandine e il menu**. Le
auto arrivavano, i clienti perdevano la pazienza, il vigile faceva la ronda
e l'orologio girava. Chi si leggeva il tutorial per intero entrava in
partita a giornata già iniziata, con la piazza piena di gente incazzata.

Adesso l'albero della scena è **in pausa** da quando compare la prima
locandina fino a quando premi *Accummenciamo* (o carichi una partita).
Restano svegli solo la schermata, l'interfaccia e il suono.

Misurato, campionando ogni due secondi durante l'intro:

| t | in pausa | auto | orologio | turno |
|---|---|---|---|---|
| 4s | sì | 1 | 15:30 | no |
| 8s | sì | 1 | 15:30 | no |
| 14s | sì | 1 | 15:30 | no |

*(Nota tecnica: le piazze comprate si misuravano i varchi in `_ready`, con
una interrogazione al motore fisico. A mondo in pausa la fisica non ha
ancora fatto un passo e ogni interrogazione tornerebbe "libero" — i varchi
si sarebbero scelti a caso. Adesso la misura si fa al primo giro utile del
timer, che per definizione arriva a partita avviata.)*

---

## 2. Le decorazioni: dove le metti, e quante ne vuoi

### Andavano quattordici metri più in là

Il punto dove cliccavi arrivava in coordinate **del mondo** e veniva
scritto come posizione **locale** dentro alla piazza. E la piazza sta a
(14, 0, 6). Quindi ogni cosa che appoggiavi atterrava quattordici metri a
levante e sei a mezzogiorno di dove l'avevi messa.

Adesso si scrive `global_position`, dopo l'`add_child`. Misurato su tre
sedie appoggiate in tre punti scelti a mano: **scarto 0,00 m** su tutte e
tre.

### Se ne possono comprare più d'una

Prima ogni decorazione era un interruttore: `sedia = true`, una sedia,
piazzata da sola in un angolo deciso dal codice. Adesso:

- al Bazar la stessa voce si ricompra, **fino a sei copie** — il listino
  scrive `×3 · €20` invece di "TUO";
- comprarne una la mette **nello zaino**, non in piazza: la piazzi tu;
- lo zaino dice quante ne hai e quante te ne restano da appoggiare;
- e gli effetti d'ambiente (radio, piante, luminarie) contano le copie
  **piazzate**, non quelle comprate: una radio nello zaino non tiene buono
  nessuno.

### E si piazzano meglio

- **Il fantasma è l'oggetto vero**, verniciato di verde trasparente: vedi
  la sdraio prima di appoggiarla, e vedi da che parte è girata.
- **La rotella lo gira**, quindici gradi per scatto. Prima prendeva la
  direzione del giocatore, quindi per girarlo dovevi girarti tu — e
  girandoti si spostava, perché il fantasma segue lo sguardo.
- **[F] lo raccoglie.** Appoggiato storto restava storto per sempre;
  adesso torna nello zaino e lo riappoggi dove vuoi, senza ricomprarlo.

---

## 3. 'A radiolina: più grande, e suona

Era l'unica decorazione con un effetto che non si **sente**: teneva buoni i
clienti e basta. Una radio che non fa musica è un soprammobile.

- **Più grande**: da 26 a 42 centimetri. È un mangianastri, non una radio
  da tasca — e adesso che ci si preme sopra dev'essere una cosa che si mira
  da tre metri. La griglia dell'altoparlante ha novantanove fori veri.
- **Si accende con [E]**, e la manopola scorre i brani che il gioco ha già:
  *Miezojuorno · 'A fatica · 'A sera · 'A notte · 'O tema*. L'ultimo scatto
  la spegne e la musica torna a farla la regia, secondo l'ora.
- **Tranne quando c'è da scappare.** Con i carabinieri addosso o Borrelli
  in piazza comanda di nuovo la situazione: quella musica lì non è un
  accompagnamento, è un avviso.

---

## 4. Restyle: i palazzi, e l'arredo

Sei modelli nuovi, e uno di questi cambia la faccia di tutta la città.

### Il balaustrino — il pezzo che vale più di tutti

Un ferro di ringhiera napoletana: dritto sopra e sotto, con **la pancia**
in mezzo e due collarini. Centoventi triangoli.

Ma la città ne disegna qualche **migliaio** — uno ogni sedici centimetri,
su ogni balcone, su ogni palazzo. E il trucco è che il gioco li
raggruppava già tutti in un MultiMesh solo, con dentro un cubo scalato: la
mesh di un MultiMesh può essere qualunque mesh, quindi al posto del cubo
c'è questa.

**Stesse istanze, stesso numero di draw call, stesso costo** — e le
facciate cambiano faccia.

### E gli altri cinque

| | prima | adesso |
|---|---|---|
| **Lampione** | cilindro + sfera | plinto a due gradini, fusto rastremato con l'anello di giunzione, **braccio ricurvo**, cappello e globo |
| **Panchina** | due scatole | fianchi di ghisa a voluta, cinque doghe di legno per la seduta e quattro per lo schienale |
| **Cestino** | non c'era | gabbia di dodici stecche appesa al palo, col coperchietto — ce ne sono adesso venti in giro per la città |
| **Cassonetto** | scatola | cassa svasata, coperchio che non chiude, maniglie, quattro ruote |
| **Fontanella** | colonna liscia | vasca, fusto scanalato, mascherone, cannello d'ottone e il getto che non si chiude mai |

*(Una cosa imparata: la panchina è uscita **bianca**. `_flush_batch`
scriveva sempre un `material_override` sul MultiMesh, e per i modelli fatti
in Blender — che si portano i materiali dentro la mesh, uno per superficie
— quell'override nullo li spegneva tutti. Adesso l'override si mette solo
se c'è.)*

Cassonetto e fontanella sono nel pacchetto ma non ancora innestati: quelli
che ci sono in gioco hanno misure diverse e vanno sostituiti con attenzione.

---

## 5. Piccole cose

- **Il numero di versione nel menu di pausa.** Chi segnala un problema deve
  poterlo dire: "non mi funziona" senza la versione non si può nemmeno
  cercare.
- Il prompt di piazzamento dice i comandi veri:
  `Guarda addo' 'a vuo' · ROTELLA gira · CLICK appoggia · ESC lassa sta'`.
- Le panchine non hanno più il giro a caso: una panchina messa di traverso
  si nota subito.
- `TUTORIAL.txt` aggiornato su copie multiple, raccolta con [F] e radio.

---

## Il pacchetto, di nuovo al limite

Con sei modelli in più Windows è arrivato a 30,15 MiB — trenta è il muro.
Stavolta però il grasso non c'era: gli asset importati sono tredici
megabyte in tutto, il resto è il binario di Godot. Ho controllato anche la
musica, e **è già ottimizzata** (mono, 32 kHz, 34 kbps: un tentativo di
ricomprimerla l'ha fatta *crescere* del doppio, ed è stato istruttivo).

Sono scesi: locandine a 1024 px, texture a qualità 0,42 con tetto a 384 px,
carte napoletane a metà risoluzione, manifesti a 288 px. **29,92 MiB.**

---

## Nel pacchetto

- `ParcheggiatoreAbusivo-v0.43-Windows.tar.xz`
- `ParcheggiatoreAbusivo-v0.43-Web-itchio.zip`
- `ParcheggiatoreAbusivo-v0.43-Sorgenti.zip` — con dentro `tools/blender/`,
  gli script che generano i modelli
