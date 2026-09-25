# v0.53 — **'E ghiornate se veneno**

Due cose: una segnalazione che era una diagnosi giusta, e la voce di
roadmap che portava questo nome.

---

## 1 · Borrelli nun tene cchiù 'nu calendario

> *"Qualcosa non va, Borrelli arriva subito. Avevamo detto di lasciare un
> 1% di possibilità che spawni Borrelli quando il vigile fa la multa o ti
> vedono che picchi qualcuno."*

Aveva ragione, e il pezzo interessante è **perché** era finito così.

Fino alla 0.43 Borrelli usciva a sorte, e capitava di finire una partita
senza averlo mai incontrato. Avevo scritto io, nel commento sopra alla
funzione: *"il pezzo scritto meglio del gioco poteva non succedere"* — e
la cura che avevo dato era **farlo succedere sempre**:

```gdscript
func boss_stasera() -> bool:
	if giornata <= 1:      return true      # 'a primma sera, sempe
	if zone_mie.size() > 1 and giornata % 2 == 0: return true
	if money - shift_start_money > 110:     return true
	return giornata % BOSS_OGNI == 0
```

Quattro strade, e la prima sera era `true` per costruzione. Il risultato
è che Borrelli arrivava **la prima sera, poi ogni due giorni, poi ogni
volta che facevi più di centodieci euro, e comunque ogni tre**. Cioè
quasi sempre.

Un boss che arriva perché è martedì non è una conseguenza: è un
appuntamento. E un appuntamento non fa paura la seconda volta.

Adesso il calendario non c'è più. Borrelli ha **due porte, e tutte e due
le apri tu**:

* il vigile che ti fa il verbale alza la radio e, **una volta su cento**,
  invece della pattuglia chiama 'O Duttore;
* qualcuno in divisa ti vede menare, e vale lo stesso uno per cento.

Una su cento è poco, ed è voluto. Non è la probabilità di incontrarlo in
una partita — chi mena e si fa multare tira quel dado decine di volte — è
la probabilità che **quella volta lì** sia quella sbagliata. È così che si
tiene la sensazione giusta: non *"stasera tocca a me"*, ma *"e mo' che
succede?"*.

La tirata è una sola e sta in un posto solo
(`GameManager.forse_chiamma_borrelli()`), perché due dadi in due file
diversi prima o poi vanno fuori sincrono. `prova_borrelli` misura
**1,00%** su centomila tirate, e controlla le tre cose che non devono
succedere: che non esca due volte, che non esca mentre ci stai già
parlando, e che non esca a giornata chiusa.

---

## 2 · 'E ghiornate se veneno (roadmap 0.53)

> *"La 0.52 ha messo i numeri delle giornate speciali. Adesso vanno viste:
> è la cosa più vistosa che manca, ed è quasi tutta grafica."*

Era anche la prima riga del "quello ca ancora nun va" della 0.52. Un
moltiplicatore che nessuno vede è un moltiplicatore di cui nessuno si
fida: uno legge sul biglietto che oggi piove, esce, e trova la stessa
piazza assolata di ieri. Da lì in poi il biglietto è una decorazione, e
con lui tutto il sistema.

Tutto sta in un nodo suo, `jurnata_vista.gd`, che si costruisce la
mattina e si butta la sera. La città non sa niente di come è fatto.

### 'A pioggia

**Il cielo si chiude.** Non è un cielo nuovo: sono le stesse cinque tappe
del ciclo giorno/notte, passate per un filtro. Il sole scende a un terzo
e si sbianca, l'ambiente vira al grigio-azzurro e **sale** (con la
pioggia la luce non viene più da una parte sola, viene da tutto il
cielo), la foschia si alza — che è come si vede la pioggia da lontano: le
case in fondo alla via si sbiadiscono. E le nuvole vanno a copertura
0,94, cioè quasi piena.

**L'acqua si disegna attorno alla testa, non sulla città.** La città è
duecento metri per centottanta: una cassa di pioggia grande quanto lei,
alla densità che serve, sarebbe un milione di gocce, e novecentonovantamila
starebbero dietro alle spalle del giocatore. La cassa è larga diciotto
metri e **segue chi guarda**: quello che si vede è identico, e le gocce
sono milleseicento. Funziona perché una goccia vale l'altra — con la
processione non si potrebbe fare.

La goccia è una strisciolina verticale, non una pallina: a quindici metri
al secondo l'occhio vede la scia, e una sfera sembra grandine. E a terra
ci sono **gli schizzi**: senza, la pioggia attraversa il selciato e
sparisce, e sono le gocce che rimbalzano a dire che l'acqua tocca
qualcosa.

**'E ombrelle.** Una calotta scura e un bastoncino sopra la testa dei
passanti. Uno su sei non ce l'ha: è quello che è uscito senza guardare il
cielo, e senza di lui la fila di calotte nere sembrerebbe una parata
invece di un acquazzone.

**E 'o vigile se mette ô cupierto.** Questa è la parte che il capo ha
chiesto per nome, ed è quella che mi piace di più: la tabella della 0.52
diceva già che con la pioggia il vigile scrive metà delle multe, ma il
*perché* non si vedeva — camminava sotto l'acqua identico a un giorno di
sole, e uno pensava che il gioco avesse deciso di essere più buono.
Adesso la ragione sta in strada: con la pioggia prende la pausa **due
volte più spesso**, va al banco del bar **nove volte su dieci** (invece
di una su due) e ci resta **due volte e mezza** più a lungo. Le multe
scendono perché non è lì a guardare.

### 'O mercato

Tredici bancarelle in più: telo a colori, quattro pali, cassette sopra al
banco. Lungo il Corso in due file e nel largo di tramontana — il mercato
non sta dentro a un recinto, si allarga.

E ognuna **ha il collider**. È quello che il capo ha chiesto — *"la strada
stretta che cambia dove passano le macchine"* — e si ottiene con un muro,
non con un disegno.

Una cosa che ho sbagliato e corretto prima di mandarla: le prime tre le
avevo messe **dentro alla tua piazza**, a otto metri dal bordo. Cioè in
mezzo ai posti auto. Una bancarella con il collider piantata dove deve
fermarsi una berlina non è "la strada che si stringe", è una macchina che
non si può più posteggiare — il gioco che si rompe, una giornata su venti,
in un modo che nessuno collegherebbe al mercato. Adesso il mercato si
allarga sulle **strade**, non sul posto di lavoro, e la prova lo verifica:
`nisciuna bancarella dint'â piazza toia`.

### 'A prucessione

Una fila di quattordici persone vestite di scuro dietro a una statua su
barella, portata da quattro. Nasce da un lato della piazza, **attraversa**,
e sparisce dall'altro; poi dopo un minuto e mezzo ripassa, perché una
processione che passa una volta sola in sette minuti di gioco è una cosa
che quasi nessuno vede.

Mentre passa, **la fila è un muro**: ogni corpo ha il suo collider. È il
"mezza piazza davvero chiusa" — non un moltiplicatore che dice che
passano meno macchine, ma quindici persone in mezzo alla strada.

La statua ha l'aureola che emette luce, e una candela ogni tre devoti con
la sua fiammella: di notte la fila si legge da lontano, di giorno sono
puntini caldi che si muovono.

### 'A partita

**Questa non si vede: si sente.** È l'unica delle quattro in cui
disegnare sarebbe stato lo sbaglio. Una partita, per chi sta in strada, è
un boato che arriva da dietro una vetrina — e il fatto che tu **non** la
vedi è tutto il punto: stai lavorando mentre il quartiere fa un'altra
cosa.

Ogni venti-cinquanta secondi succede qualcosa: un gol (*"GOOOL! 'O bar è
asciuto pazzo. Se sente 'a ccà."*), un palo, un rigore contro. Il
risultato si costruisce mentre la giornata va avanti, e dopo nove fatti
l'arbitro fischia: *"Fernuta 'a partita: 2-1, hanno vinto. Mo' scenne
tutto 'o quartiere 'nzieme."*

Senza quel fischio si arrivava a **undici a due**, che non è una partita,
è una barzelletta — e soprattutto il boato non finiva mai, e un boato che
non finisce smette di essere un boato.

---

## 'E ddoje trappole 'e stavota

Tutte e due trovate scattando le foto, e tutte e due dello stesso tipo:
**codice giusto che gira nel momento sbagliato.**

**`add_child()` primma, 'a posizione appriesso.** `global_position` su un
nodo che non sta ancora nell'albero non vuol dire niente: Godot stampa
`!is_inside_tree()` e la scrive nel vuoto. La processione partiva
dall'origine del mondo invece che dal bordo della piazza — e siccome
l'origine è lontana, non si vedeva proprio.

**'O gioco parte 'n pausa.** La prima foto di pioggia è uscita col sole:
il ciclo giorno/notte non è `PROCESS_MODE_ALWAYS`, quindi durante la
schermata di caricamento `_process()` non gira e il cielo resta quello di
mezzogiorno. Non è un difetto del gioco (in partita la pausa non c'è) ma
lo era della prova, ed è lo stesso inciampo della 0.49 con
`PROCESS_MODE_ALWAYS`: **il gioco parte fermo, e le prove non se lo
ricordano mai.**

---

## 'E prove

| prova | esito |
|---|---|
| `prova_borrelli` | 0 storte — 60 sere, 100.000 tirate, 1,00% |
| `prova_jurnata_vista` | 0 storte — che si costruisce per ogni giornata |
| `prova_giurnate` | 0 storte — 4.000 giornate |
| `prova_fermi` · `prova_fasce` · `prova_orologio` | 0 storte |
| `prova_lotto` | 0 storte — 120.000 giocate, ritorno 67% |
| `prova_partite` | 0 storte — 20.000 partite |
| `prova_confronto` | 0 storte — dialoghi, cerca, 400 tirate |
| `prova_cartielle` · `prova_fummetto` | 0 storte |
| `prova_muri_casa` · `prova_mira` · `prova_modelli` · `prova_pose` | 0 storte |
| `prova_scopa` | 0 partite storte su 300 |
| `prova_economia` · `prova_casa` | passate |

## 'O pacco

| | |
|---|---|
| Windows | 54,8 MiB |
| Web | 46,6 MiB |
| Sorgenti | 0,5 MiB |

---

## Quello ca ancora nun va

* **'O selciato nun luceca.** Il capo aveva chiesto anche *"il selciato che
  luccica"*: la pioggia c'è, gli schizzi ci sono, ma l'asfalto ha la
  stessa opacità di un giorno di sole. Va cambiato il materiale del
  terreno quando piove (roughness giù, un filo di riflesso), e va fatto su
  tutti i pezzi di strada insieme — che è il motivo per cui non l'ho fatto
  adesso: sono materiali sparsi in quattro file e vanno raccolti prima.
* **'E divote camminano senza animazione.** La processione scivola: sono
  corpi costruiti con `Human.build` senza `Animator`. Adesso guardano
  almeno dove vanno.
* **'O mercato nun se sente.** Ci sono le bancarelle, non c'è il vociare.
* **'E ccriature so' pupe piccirille** e **'o Castel dell'Ovo è ancora 'nu
  blocco marrone**: fermi dalla 0.51.

## 'A lezione 'e sta build

La 0.51 diceva: *una prova che misura a un punto solo dimostra qualcosa
solo a quel punto.* La 0.52: *quando aggiungi un gioco d'azzardo, la prova
non è che funzioni — è quanto si tiene il banco.*

Questa aggiunge la più scomoda delle tre, e riguarda me:
**una cura scritta bene può essere la malattia della versione dopo.**

Borrelli usciva troppo perché nella 0.43 usciva troppo poco, e io avevo
scritto nel codice un commento convinto che spiegava perché farlo uscire
sempre fosse giusto. Quel commento è rimasto lì nove versioni, e a
rileggerlo sembrava ragionevole ogni volta. Il difetto non era nascosto:
era **documentato**, e la documentazione lo faceva sembrare una scelta.

Da qui in poi, quando una nota nel codice spiega perché una cosa succede
*sempre*, quella è la prima riga da rileggere quando qualcosa "arriva
subito".
