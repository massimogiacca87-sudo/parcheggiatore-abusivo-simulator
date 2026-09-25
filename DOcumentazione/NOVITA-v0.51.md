# v0.51 — **'O ritmo d''a jurnata**

Tre punti. I primi due erano guasti segnalati; il terzo era carta bianca —
*"dedicati in generale a migliorare il motore del gioco… fai un po' di
cose a capa tua"* — e l'ho spesa dove il gioco aveva un buco che si vedeva
solo giocandoci a lungo: **la giornata era piatta**.

E poi, dietro al "controlla i baloon", è saltato fuori il difetto grosso
di questa build. Ne parlo in fondo, perché è quello che mi porto dietro
come lezione.

---

## 1 · 'O tiempo

> *"Il tempo non funziona bene, fai in modo che orologio e ora del giorno
> coincidano e non farlo sminccchiare in caso di eventi tipo essere
> arrestati."*

**C'erano due orologi**, e nessuno dei due sapeva dell'altro.

* `GameManager.shift_time_left` — il cronometro del turno, che vive
  nell'autoload e non si ferma mai;
* `GiornoNotte.avanzamento` — il colore del cielo e l'ora scritta in alto
  a destra, che si contava per conto suo con `avanzamento += delta / 450`
  dentro alla scena della città.

Due contatori che partono insieme restano insieme **solo finché nessuno
dei due salta un colpo**. Ma la scena della città si carica dopo, si mette
in pausa quando apri un pannello, e sopra a tutto c'è l'arresto: il
cronometro del turno si fermava e il cielo continuava a girare. Bastava un
fermo dei carabinieri e da lì in poi l'orologio diceva le nove mentre il
sole stava a mezzogiorno — **per sempre**, perché niente li rimetteva
d'accordo.

La cura non è sincronizzarli meglio. È **averne uno solo**:

```gdscript
func avanzamento_giornata() -> float:
	if shift_duration <= 0.0:
		return 0.0
	return 1.0 - clampf(shift_time_left / shift_duration, 0.0, 1.0)

func ore_passate() -> float:
	return avanzamento_giornata() * ORE_DI_GIORNATA
```

`GiornoNotte` adesso non conta più niente: legge questo e specchia. E il
tempo si ferma davvero quando dev'essere fermo — `tempo_fermo`, alzata dal
rientro forzato, abbassata da `start_shift()`.

`tools/prova_orologio.gd` mette i tre numeri a confronto in nove tappe
lungo le sedici ore, rilegge l'orologio al contrario da `"HH:MM"` ai minuti
e controlla che lo scarto stia sotto il mezzo minuto di gioco. Poi arresta
il giocatore e fa girare trenta passate di `_process`: **zero storte**.

## 2 · 'E dialoghe cu ll'autiste

> *"I dialoghi con i guidatori che trovano multe o auto scassate non
> funzionano. Aggiustali."*

Non funzionavano per **tre motivi diversi**, e li ho trovati uno alla
volta perché ognuno nascondeva il successivo.

**Lo stemma.** Il dialogo si apriva e spariva *nello stesso fotogramma*.
`_confronto_stemma()` lasciava lo stato su `RETURNING`, e al giro dopo
`_do_return()` ripartiva da capo e mandava l'autista all'inseguimento. Il
fumetto faceva in tempo a comparire e basta. Adesso c'è uno stato suo,
`State.CONFRONTO`, e finché quello è acceso non si muove nient'altro.

**'A multa.** Non c'era proprio: si passava dritti alle mazzate. Adesso
l'autista che trova la multa sotto al tergicristallo torna, ti si pianta
davanti e ti chiede conto, con quattro risposte sue.

**'A machina scassata 'e nascosto.** Questo non produceva niente, mai. Se
rigavi una macchina e nessuno ti vedeva, il gioco se ne dimenticava: la
cosa più strana era che il danno c'era, il proprietario tornava, guardava
la fiancata e non diceva niente. Adesso `_scassata_ammuccione` se lo
ricorda e apre il terzo confronto.

Tre tabelle di risposte (`RISPOSTE_STEMMA`, `RISPOSTE_MULTA`,
`RISPOSTE_SCASSO`) e sei esiti: *ridai · scusa · paga · bugia · faccia
tosta · rissa*. La regola che tiene tutto insieme è che **la faccia tosta
non funziona con chi ti ha pagato**: uno che ti ha dato i soldi per
guardargli la macchina ha il diritto di incazzarsi, e il gioco glielo
riconosce.

`tools/prova_confronto.gd` monta l'autista su una macchina finta e prova
otto casi. La verifica che conta non è che il dialogo si apra: è che
**dopo dieci fotogrammi sia ancora aperto**. È esattamente quello che
prima non succedeva. **Zero storte su otto.**

---

## 3 · 'E ffasce d''a jurnata

Qui la carta bianca. La giornata dura sedici ore ed era **piatta**: il
quindicesimo cliente identico al primo, le macchine con lo stesso passo a
mezzogiorno e alle due di notte. L'unica cosa che cambiava era il colore
del cielo.

Adesso che l'orologio è uno solo — cioè adesso che di che ora è ci si può
fidare — l'ora comanda due numeri:

| ora | fascia | attesa fra 'e mmacchine | mancia |
|---|---|---|---|
| 12–15 | 'a controra | ×1,30 | ×0,95 |
| 15–18 | 'e ttre morte | ×1,65 | ×0,90 |
| 18–21 | ll'aperitivo | ×0,62 | ×1,12 |
| 21–24 | 'e rristorante | ×0,52 | ×1,22 |
| 24–04 | 'a nuttata | ×1,45 | ×1,95 |

**I due numeri vanno in direzione opposta, ed è tutto il punto.** Le tre
del pomeriggio hanno poche macchine *e* mance magre: è l'ora in cui
conviene lasciare la piazza e andare alla bacheca. Le dieci di sera
rendono da sole, e un lavoretto in quel momento è tempo buttato. La notte
è il caso strano: tre macchine in croce, ma chi scende a quell'ora ha
bevuto e lascia il doppio.

Una piazza sola, giocata in cinque modi diversi.

E siccome un sistema che vive dentro a una tabella di numeri non esiste,
si vede in tre posti:

* **In alto a destra**, sotto al giorno, il nome della fascia col suo
  colore — arancio quando la piazza è vuota, verde quando cammina, azzurro
  di notte. Si legge senza leggerla. (Sta su una riga sua perché "'e
  rristorante" attaccato a "mercoledì · juorno 3" usciva dal bordo dello
  schermo.)
* **Sulla bacheca**, che è il posto dove la scelta si fa: *"Chest'è ll'ora
  bbona pe' 'nu lavoretto"* alle tre, *"Mo' 'a piazza pava 'o doppio"*
  a mezzanotte.
* **In faccia a chi scende dalla macchina.** Alle due di notte l'autista
  non parla come alle sei di sera: *"Tiè, professò… e pigliatìlle tutte
  quante!"*, *"Aspiè… aspiè ca mo' m'arricordo addò tengo 'o
  puórtafoglio…"*. L'ora più redditizia del gioco adesso si sente.

`tools/prova_fasce.gd` prende ventiquattro assaggi lungo le sedici ore e
controlla che la fascia combaci con l'orologio a ogni tappa, che i due
numeri vadano davvero in direzione opposta, e che **il cartello si dica una
volta sola** — il rischio vero di una cosa così è che `_process` sputi lo
stesso avviso sessanta volte al secondo. **Zero storte.**

---

## 'E ddoje guaste ca s'annascunnevano 'a dint'ê fummette

Il capo aveva scritto *"controlla i baloon"*. Li avevo già rifatti alla
0.50 — misurati col font vero invece che indovinati dal numero di lettere
— e mi aspettavo di non trovare niente. Ne sono usciti due, e il secondo è
il difetto più grosso di questa build.

### 'O bianco nun cresceva cu 'o nero

**`billboard_mode` senza `billboard_keep_scale` butta via la scala del
nodo.**

Il fumetto si rimpicciolisce con la distanza — è interfaccia travestita da
oggetto, e deve occupare sempre lo stesso pezzo di schermo. Il `Label3D`
quella scala se la teneva. I tre quad che gli stanno dietro — il bianco,
il bordo scuro, la codina — **no**: il materiale li girava verso la camera
*e li disegnava sempre alla misura base*.

A tre metri e venti la scala vale esattamente 1 e tutto combacia. A cinque
metri il testo era grosso il cinquanta per cento più del bianco che
avrebbe dovuto contenerlo, e usciva da tutti e quattro i lati. **È il
"sforano il balloon" che il capo vedeva** e che io non avevo trovato,
perché la prova della 0.50 misurava a una distanza sola — e per una
sfortuna perfetta era proprio quella in cui il guasto non esiste.

Una proprietà, `m.billboard_keep_scale = true`. E la prova adesso misura a
**tre distanze** apposta: un metro (il vascio, dove si parla faccia a
faccia), tre e venti, otto metri (mezza piazza).

### 'A parola ca nun se pò spezzà

L'altro era più piccolo ma della stessa famiglia — due conti che dovevano
dire la stessa cosa e usavano regole diverse. La misura chiedeva
`BREAK_WORD_BOUND | BREAK_MANDATORY` ("vai a capo agli spazi"), e una
parola senza spazi più larga del fumetto le restava tutta su una riga:
tre metri e venti di larghezza, una riga sola. Il `Label3D`, con
`AUTOWRAP_WORD_SMART`, quella parola la spezza a metà e ne fa due.
Risultato: il bianco tagliato largo il doppio e alto la metà.

La regola giusta non si indovina, sta scritta in `label_3d.cpp`:
`BREAK_WORD_BOUND | BREAK_ADAPTIVE | BREAK_MANDATORY`, più
`BREAK_TRIM_EDGE_SPACES` che Godot aggiunge sempre. (Non è
`BREAK_GRAPHEME_BOUND`: quello è `AUTOWRAP_ARBITRARY`, e a provarlo il
fumetto veniva *più largo* del disegnato, perché riempie le righe fino
all'orlo.)

`tools/prova_fummetto.gd` mette in scena nove frasi vere del gioco a tre
distanze e confronta il quad bianco con l'ingombro che Godot dichiara per
il testo (`Label3D.get_aabb()`). Adesso il margine è **11,0 cm per lato a
tre metri e venti, 4,6 a un metro, 18,7 a otto** — cioè sempre lo stesso,
in proporzione. **Zero storte su ventisette.**

## 'O cartiello ca asceva 'a fore

Stessa famiglia, trovato tirando il filo. La riga arancione che compare a
mezzo schermo era un `Label` largo 800 pixel a corpo 28 **senza andare a
capo**: fanno una sessantina di lettere, e **diciotto messaggi del gioco**
ne hanno di più. Il più lungo era *"%s mo' fatica pe' te a %s. 'A sera
passa a piglià 'e sorde: se tene 'o 30%%"*, settantasei lettere: la coda
finiva fuori dal bordo e non la leggeva nessuno.

Non si vedeva provando, perché i cartelli corti — che sono la maggioranza
— stavano dentro.

Adesso la riga è larga 1100, va a capo, e il corpo si stringe a scaletta
(28 / 24 / 21) quando la frase è lunga, così le urlate restano grosse.
`tools/prova_cartielle.gd` **si legge i sorgenti da solo**, tira fuori
tutte le stringhe passate a `event_started.emit()`, ci sostituisce un nome
proprio ai `%s` e un numero a tre cifre ai `%d`, e le misura col font
vero: **79 frasi, zero fuori**, la più larga a 989 pixel su 1100. Una
frase nuova entra nella prova da sola — che è il solo modo perché una
prova così resti vera.

## 'O napulitano

Rilettura riga per riga di tutte le parlate, dodici copioni. Le correzioni
sono quasi tutte della stessa specie: **l'articolo attaccato alla
preposizione**, che in napoletano si scrive `p''o` / `p''a` / `pp''e` e
non `pe' 'o` / `pe' 'a` / `pe' 'e`; la `c` doppia di `cchiù`; l'accento
vero al posto dell'apostrofo (`cafè` non `cafe'`, `s'è` non `s'e'`).

E i comandi che erano rimasti in italiano dentro a un gioco napoletano —
*"Premi E per parlare con Borrelli"* → *"[E] parla cu Borrelli"*,
*"Mettiti DIETRO e accovacciati (C) per provarci"* → *"Miéttete 'a rieto e
accuóvate [C] pe' ce pruvà"*. Una quarantina di righe in tutto.

Il tutoriale resta in italiano: è una scelta della 0.50, e sta in piedi —
dev'essere comprensibile a chiunque.

## 'A robba vecchia

Cinquecentocinquantacinque righe di `scripts/legacy_2d/`: il gioco in due
dimensioni di prima della 0.30, che non veniva caricato da nessuno e
teneva pure un `preload` rotto. Via.

---

## 'E prove

| prova | esito |
|---|---|
| `prova_orologio` | 0 storte (9 tappe + arresto) |
| `prova_confronto` | 0 storte su 8 casi |
| `prova_fasce` | 0 storte (24 tappe + 7 controlli) |
| `prova_fummetto` | 0 storte su 27 (9 frasi × 3 distanze) |
| `prova_cartielle` | 0 storte (79 frasi misurate) |
| `prova_muri_casa` | 0 raggi scappati |
| `prova_mira` | 0 storte su 24 |
| `prova_modelli` | 0 storte su 29 |
| `prova_pose` | 0 clip mancanti su 17 |
| `prova_scopa` | 0 partite storte su 300, mazzo integro |
| `prova_economia` | 30 giornate su quattro livelli di guadagno |
| `prova_casa` | vascio, moglie, conto, letto, giorno dopo |

## 'O pacco

| | |
|---|---|
| Windows | 54,7 MiB (era 67,6) |
| Web | 46,5 MiB |
| Sorgenti | 0,5 MiB |

Windows è sceso di tredici mega: l'export precedente si portava dietro
roba che non serviva più.

---

## Quello ca ancora nun va

Scritto per non fare finta.

* **'E ccriature so' pupe piccirille.** I bambini sono adulti scalati:
  proporzioni da grande, testa piccola. Ci vuole una quinta corporatura in
  `build_personaggi.py`, non un moltiplicatore.
* **'O Castel dell'Ovo è ancora 'nu blocco marrone** in fondo al golfo.
* **'E ddete d''e mmane** in prima persona si aprono ancora un poco più
  del dovuto quando la mano sta ferma.
* **'E ffasce nun cagnano chi sta 'n piazza.** Alle tre del pomeriggio
  arrivano meno macchine, ma la gente che passa è la stessa e fa le stesse
  cose. Il passo successivo è che alle tre le saracinesche siano abbassate
  e a mezzanotte in giro ci sia solo chi esce dai ristoranti.
* **'E ghiornate speciali** — 'a partita, 'a pioggia, 'o mercato, 'o
  primmo d''o mese — restano da fare. Adesso però il posto dove
  attaccarle c'è: sono una sesta riga della tabella delle fasce, non un
  sistema nuovo.

---

## 'A lezione 'e sta build

La 0.50 aveva chiuso con: *sette guasti su sedici erano lo stesso tipo —
codice che sembrava funzionare e non veniva eseguito.*

Questa ne ha uno nuovo, e fa più male: **una prova che misura a un punto
solo dimostra qualcosa solo a quel punto.** Il fumetto della 0.50 era
misurato bene, con il font giusto, con le regole giuste — e la prova
passava. Passava perché guardava il fumetto a tre metri e venti, cioè
esattamente alla distanza in cui la scala vale 1 e il guasto sparisce.

Il capo lo vedeva e io no, e non era distrazione: era che stavo misurando
il caso in cui il difetto non esiste. Da qui in poi, ogni prova su una
cosa che ha un parametro (distanza, ora, corporatura, velocità) lo prova
**agli estremi**, non al centro.
