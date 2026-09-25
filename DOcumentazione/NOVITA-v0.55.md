# v0.55 — **'E piazze e 'e guagliune**

Due segnalazioni e la voce di roadmap che porta questo nome. 'A guida cu
'o minigioco d''o furto e 'e chiave sta p''a 0.56, comme avimmo ditto.

---

## 1 · 'E clienti mo' vanno a fà 'e commissiune

> *"I clienti della macchina parcheggiata tornano all'infinito e tutti
> vengono dal player a chiedere conto di danni e multe."*

Era un **anello nel grafo degli stati**, e vale la pena scriverlo per
esteso perché nessuna delle ventitré prove esistenti poteva vederlo.

La macchina, finita la sosta, chiamava indietro l'autista se c'era un
danno. L'autista faceva la scenata e chiamava `multa_confronto_finita()`.
Quella rimetteva il contatore della sosta a mezzo secondo — ma il danno
stava ancora lì, e mezzo secondo dopo la macchina ne chiamava un altro.
**Per sempre**, con un cliente perso contato a ogni giro.

Nessun numero era sbagliato. Era la forma a essere sbagliata, e una forma
sbagliata si trova in un modo solo: facendo girare il giro fino in fondo e
contando quante volte passa dallo stesso punto.

E c'era una seconda metà della segnalazione, quella che il capo ha visto
in faccia: **venivano tutti**. Perché di autisti ce n'erano **due** per
macchina — uno che scendeva, camminava verso l'uscita della piazza e
spariva, e uno che nasceva dal nulla all'uscita per tornare incazzato.
Due comparse con la stessa faccia, e in mezzo una macchina lì da sola.

### Mo' ll'autista è uno sulo, e campa quanto 'a sosta

```
EXITING → SPESA (cammina fino a un negozio) → ASPETTA (ci sta dentro)
        → TORNA (rientra alla macchina) → e lì guarda:
              tutto a posto  → SAGLIE, monta, e la macchina se ne va
              multa/stemma/riga → CERCA, e parte il confronto che c'era già
```

**Nisciuno posteggia pe' posteggià.** Uno si ferma perché deve fare una
cosa, e adesso quella cosa si vede: attraversa la piazza, si ferma davanti
al fruttivendolo, e dopo un po' torna. La durata è la stessa di prima
(trenta-quaranta secondi per un cliente qualunque) e la calcola lui
togliendo la camminata — chi ha il negozio sotto casa se la prende comoda,
chi ce l'ha lontano ci sta meno.

Serve anche a una cosa pratica: **ti passa davanti due volte** invece che
una. Prima avevi cinque secondi per fermarlo.

Il giro è chiuso **per costruzione**: c'è una sola uscita di scena e passa
da `l_autista_ha_fernuto()`, che manda via la macchina e basta. Non esiste
più uno stato da cui si possa tornare indietro a rifare la stessa scenata.
`prova_commissione` fa girare la sosta intera nei cinque casi (pulita,
multa, stemma, riga, e tutti e tre insieme) e controlla che finisca sempre,
**una volta sola**, e che il cliente senza guai non ti venga mai a cercare.

### E 'e negozie

Le ventotto vetrine che c'erano — tende a righe, insegna, merce sui
ripiani — erano scenografia bellissima e inutile. Adesso sono **le mete
delle commissioni**: quarantaquattro in tutto, con sedici nuove sulle
facciate che danno sulle quattro piazze, perché con il negozio più vicino
a quarantatré metri ogni cliente attraversava mezza città per comprare il
pane.

Due difetti trovati dalla prova, e tutti e due vecchi:

* **nove vetrine avevano il punto d'attesa in mezzo alla carreggiata.**
  Finché nessuno ci andava non importava; da quando ci va qualcuno,
  quel qualcuno si pianta in mezzo alla strada. Adesso il punto si cerca
  scalando da un metro e mezzo a settanta centimetri;
* **alcune stavano sugli incroci**, e lì non c'è offset che tenga: la
  bottega *stessa* è in mezzo alla strada. Quelle scorrono lungo la
  facciata di tre o sei metri, e se non basta non si costruiscono.

---

## 2 · 'A Signora d''e nummere

> *"Le informazioni che ti danno le persone sono superflue, facciamo che
> c'è una signora misteriosa che ti dice i numeri da giocare del lotto.
> Una volta su 20 ti dà tutti numeri giusti."*

La diagnosi è più profonda di quanto sembri, e vale la pena raccoglierla
per intero: quelle notizie erano **utili ma non memorabili**. Sapere dove
sta il vigile ti cambia i trenta secondi dopo e poi è finita; dopo tre
giorni è una riga di HUD con una faccia davanti. Peggio: era una cosa che
il giocatore poteva **vedere da solo** girando l'angolo, e pagare due euro
per sapere quello che stai per vedere gratis è un cattivo affare che si
capisce subito.

**'A Signora è il contrario esatto.** Quasi sempre non serve a niente: ti
dà cinque numeri e una ruota, li giochi, non esce niente. Ma **una volta
su venti** sono i numeri veri dell'estrazione di stasera, e un euro sulla
cinquina fa sei milioni. Non è un'informazione: è una lotteria dentro la
lotteria, e quello che ti lascia addosso non è il vantaggio — è il dubbio.

Sta in un posto diverso ogni giorno (sette, mai dentro alla tua piazza), e
una giornata su quattro non esce affatto. Dove sta oggi te lo dice **Mimmo
'o guaglione**: è l'unica notizia rimasta al vicinato, e resta perché
**porta da qualche parte**.

### Pe' ffà 'na prufezia, 'o futuro adda essere già scritto

L'estrazione si tirava **la sera**, dentro a `end_shift`. Funzionava
benissimo e rendeva impossibile l'unica cosa richiesta: se i numeri non
esistono quando lei parla, non c'è modo di farla indovinare davvero.

Adesso i numeri di stasera si tirano **la mattina** e restano chiusi in
`lotto_stasera`; la sera non si tira più niente, si apre la busta. E stanno
nel salvataggio, se no bastava ricaricare per rifare l'estrazione — o per
ricaricare finché non esce la volta buona.

### 'A cosa ca 'a prova ha truvato

> **'E nummere vere esceno 'n disordine. 'E miei 'e mettevo 'n ordine.**

I numeri finti li ordinavo — sembrava una gentilezza, cinque numeri in
fila si leggono meglio. Ma un'estrazione vera esce **disordinata**, perché
i numeri escono uno alla volta dall'urna. Quindi ordinati voleva dire
*finti* e disordinati voleva dire *veri*: un giocatore ci mette tre
giornate a notarlo, e da lì in poi sa sempre, **prima di spendere un
euro**, se è la volta buona. Le altre diciannove smettono di essere attesa.

Una riga. A occhio i numeri sembravano identici. `prova_signora` la conta
su quattromila tirate e adesso misura, nei due mucchi, quante cinquine
escono già in ordine per caso: 0,8% contro 0,7%, cioè indistinguibili.

La prova verifica anche la quota (5,03% su centomila), che quando dice la
verità dica **davvero** i numeri che escono (171 volte su 171), e che
quando mente non li azzecchi per caso.

### E 'o vicinato mo' fa, nun dice

* **Nunzia d''o Bar** — 'o cafè: sospetto giù e ossa su, come al banco.
* **Totore 'o Guardiano** — t'arape 'o purtone: quaranta secondi in cui il
  quartiere smette di guardarti, e le stelle si sciolgono.
* **Rosa d''o Vico** — 'a frittata: ossa, una volta al giorno.
* **Mimmo 'o Guaglione** — dove sta oggi 'a Signora.

---

## 3 · 'E piazze e 'e guagliune (roadmap 0.55)

### Quatte piazze ca nun so' 'a stessa quatte vote

Conquistare il mercato cambiava **una cosa sola: dove stavi**. Stesso
rubinetto, stessa mancia, stessi vigili. Quattrocentocinquanta euro per il
permesso di fare lo stesso lavoro venti metri più in là.

| piazza | rende (giornata) | vigili | com'è |
|---|---|---|---|
| **'o stadio** | €110 | **2** | Ccà se fanno 'e sorde overe |
| **'a piazza toia** | €73 | 1 | Nè ricca nè facile, ma è 'a casa |
| **'o mercato** | €56 | **0** | Tanta ggente, poche sorde, e 'o vigile nun ce sale maje |
| **'a cornetteria** | €55 | 1 | 'E juorno 'nu deserto; 'a notte è n'ata cosa |

E *"lavora solo di notte"* adesso si può scrivere davvero: la cornetteria
rende **8,5 volte** di notte quello che rende di giorno (€3 contro €30 a
fascia). Il mercato è il contrario — di notte scende a 0,6.

`prova_piazze` misura la giornata intera di ognuna e chiede due cose
opposte: che siano **diverse** (la migliore rende 1,98 volte la peggiore) e
che **nessuna sia la risposta giusta** — se una rendesse il doppio di tutte
a ogni ora, la scelta sarebbe finta. E controlla che la più ricca sia anche
quella che costa qualcosa: due vigili.

Chi te la vende **te lo dice**, prima che paghi. Un carattere che scopri
dopo aver pagato non è un carattere, è una fregatura.

### 'E guagliune crescono — e se ne vanno

Un guagliuno assunto oggi e uno che ti lavora da tre settimane erano lo
stesso identico numero. In un gioco in cui i clienti si ricordano di te,
era l'unica cosa che non si ricordava di niente.

**L'esperienza** matura in quattordici giornate: rende fino al 22% in più e
la quota che si tiene scende **dal 30% al 21%**. Su cento euro incassati da
lui te ne restano 63 il primo giorno e 87 dopo due settimane — 1,38 volte,
e comunque meno di farlo di persona, se no il gioco diventerebbe "assumi e
vattene a casa".

**L'umore** è il bastone, ed è la riga che il capo aveva scritto per nome:
*"uno trattato male se ne va da un rivale"*. Sale quando passi a ritirare
la cassa — che è l'unica volta in cui ci parli — e scende ogni sera in cui
l'hai lasciato con i soldi in mano. **Sotto dieci se ne va, e si porta la
cassa.**

Qui la prova ha bocciato il primo bilanciamento, e aveva ragione: con +14
contro −18, anche chi passava **una sera sì e una no** lo perdeva —
meno quattro ogni due sere. Cioè il giocatore normale, quello che non è
preciso, veniva punito per essere normale. Adesso sono +16 e −13: chi non
passa **mai** lo perde in quattro sere, chi passa a sere alterne sta a 87 e
non lo perde più.

### 'A voce ca gira

Il ponte fra i sei clienti fissi e il resto della piazza. Erano **sei
rapporti chiusi in sé**: trattavi male Donna Assunta e ne pagavi con Donna
Assunta. Ma in una piazza si parla, e quello che fai al secondo cliente lo
sa il quarantesimo.

`voce` è la media di come ti tratta chi ti conosce, e tocca **tutti**:
tutti amici vuol dire +14% sul pagamento e mance ×1,16; tutti nemici −28%
e ×0,68. Il male pesa il doppio del bene, come per i rapporti singoli.

Non è la `nomma`, che resta e che è un'altra cosa: quella è la **paura**
(chi sa che righi le macchine discute meno), questa è la **stima**. Si
possono avere tutte e due, e sono due modi opposti di farsi pagare.

### 'E boss 'e capitolo

La roadmap diceva *"sul modello di Borrelli"*, e il modello di Borrelli è
**l'inseguimento**: uno che non puoi toccare e da cui devi scappare.
Rifarlo tre volte con tre facce avrebbe dato tre Borrelli — lo stesso
errore delle quattro piazze uguali, ma sui personaggi.

Quindi il contrario. Ti prendi una piazza: **quella sera, in quella
piazza**, ti aspetta chi la proteggeva. Non corre e non scappa. E ognuno
chiede una cosa diversa, che è l'unico modo perché siano tre persone:

* **'O Cardinale** (stadio) vuole **soldi**: €260, subito, e finisce lì.
* **Donna Carmela** (mercato) non vuole soldi: vuole che per **tre giorni**
  il mercato lavori anche per lei — il 30% delle mance. Costa poco oggi e
  si sente per tre giorni.
* **Tonino 'e Notte** (cornetteria) **non tratta**: o lo stendi (una
  ventina di colpi di mazza) o si riprende la piazza.

Se non ci vai entro la nottata **se la riprende davvero**, con dentro il
tuo guaglione e l'affitto che smetti di pagare. Non è una sorpresa: te lo
dice quando arriva e te lo ricorda a metà tempo.

### E 'e tre cose piccole rimaste

**'O selciato luceca.** Era la prima riga del "quello ca ancora nun va" da
due versioni, e ci stava perché sembrava un lavoro grosso — i materiali del
terreno li assegnano nove chiamate sparse in quattro file. Ma passano
**tutte** da `Tex.mondo()`, che li mette in cache: sono **quindici oggetti
condivisi**, non novecento. Da un posto solo si toccano tutti insieme.

**'O mercato se sente.** Tredici bancarelle e attorno il silenzio: un
mercato fotografato, non un mercato. Adesso le bancarelle gridano i prezzi
a turno, con il verso della folla sotto, a un volume che scende con la
distanza — da venti metri è un brusio, da tre è uno che ti urla che le
zucchine sono a un euro. E un mercato è una cosa che **si sente prima di
vederla**.

**'E vicine se ne vanno a durmì.** Stavano fermi allo stesso metro
ventiquattr'ore su ventiquattro: Mimmo, che tiene dieci anni, in mezzo al
largo all'una di notte. La differenza fra una persona e un cartonato è che
la persona a un certo punto se ne va. Resta solo Totore, che è il guardiano
del palazzo e la notte è il suo turno.

---

## 'E trappole 'e stavota

**'O selciato "nun funzionava", e invece funzionava.** La foto di confronto
dava differenza **0,4 su 255**, cioè zero, e stavo per concludere che il
sistema non toccava niente. Erano **tre difetti sovrapposti**, e nessuno
dei tre era quello che pensavo:

1. `bagna()` usciva subito se il valore non cambiava, e siccome partiva a
   zero **la prima chiamata non applicava mai niente**;
2. la prova confrontava *sereno* contro *pioggia*, cioè cambiava anche il
   cielo, la luce e la foschia: due immagini che non dicono niente su
   quello che volevo guardare. Un confronto vale solo se cambia **una cosa
   sola**;
3. e il ciclo giorno/notte richiamava `bagna(1)` a ogni fotogramma, quindi
   la foto "asciutta" era bagnata come l'altra.

Con i tre sistemati la differenza è **21 su 255**, e si vede a occhio nudo.
La morale: quando una cosa "non si vede", il primo sospettato è la prova.

**'A pioggia schiariva 'a notte.** Trovato di rimbalzo, mentre facevo
quelle foto: il filtro della pioggia della 0.53 alzava l'ambiente del 22% e
lo virava verso un grigio chiaro **a tutte le ore**. Di giorno è giusto —
con la pioggia la luce viene da tutto il cielo. Di notte è il contrario
esatto: le nuvole tolgono anche la luna. Alle nove di sera sotto l'acqua
sembrava mezzogiorno nuvoloso. Dentro al gioco non sembra un difetto,
sembra il tempo: si vede solo mettendo due fotogrammi uno accanto all'altro.

**`float(null)`.** `get_shader_parameter` torna **null** per un parametro
che nessuno ha mai scritto su quel materiale — prende il valore di scorta
dello shader e non lo scrive. Leggerlo con `float(...)` fa saltare tutto.

**'O parametro ca annascunneva 'o campo.** `parcheggiata_dal_guaglione`
prendeva un parametro chiamato `zona_id`, e alla 0.55 `zona_id` è diventato
un campo dell'auto. Nessun errore, e l'incasso sarebbe finito nella piazza
sbagliata solo quando i due valori non coincidono — cioè raramente, e in
modo incomprensibile.

---

## 'E prove

Ventisei suite, tutte a zero storte. Le sei nuove:

| prova | esito |
|---|---|
| `prova_commissione` | 0 storte — 5 giri interi, 44 vetrine, nessun anello |
| `prova_signora` | 0 storte — 100.000 tirate (5,03%), 171 profezie su 171 |
| `prova_piazze` | 0 storte — resa giornaliera delle quattro, notte compresa |
| `prova_guagliune` | 0 storte — esperienza, umore, 30 sere simulate |
| `prova_boss` | 0 storte — le tre uscite, la scadenza, il salvataggio |
| `prova_bagnato` | 0 storte — 15 materiali, i parametri, chi nasce dopo |

E le venti di prima: `prova_gente`, `prova_vicinato`, `prova_mestiere`,
`prova_ossa`, `prova_manella`, `prova_lotto` (160.000 giocate),
`prova_borrelli` (100.000 tirate), `prova_partite` (20.000 partite),
`prova_giurnate`, `prova_fermi`, `prova_fasce`, `prova_orologio`,
`prova_confronto`, `prova_cartielle`, `prova_fummetto`,
`prova_jurnata_vista`, `prova_muri_casa`, `prova_mira`, `prova_modelli`,
`prova_pose`, `prova_scopa`, `prova_economia`, `prova_casa`.

## 'O pacco

| | |
|---|---|
| Windows | 54,8 MiB |
| Web | 46,6 MiB |
| Sorgenti | 0,6 MiB |

---

## Quello ca ancora nun va

* **'O boss 'e capitolo nun cammina.** Ti aspetta fermo in mezzo alla
  piazza e ti viene addosso solo quando si mena. Dovrebbe girare per la
  sua piazza mentre aspetta.
* **'O riflesso d''o selciato se vede sulo cu 'a luce 'e taglio.**
  L'ambiente riflesso è un colore piatto, non il cielo: per un riflesso
  vero ci vorrebbe una ReflectionProbe, e vanno misurate prima.
* **'E braccia nun se vedono cammenanno**: serve una clip di idle in prima
  persona fatta in Blender. Ferma dalla 0.54, ed è misurata.
* **'E ccriature so' pupe piccirille** e **'o Castel dell'Ovo è ancora 'nu
  blocco marrone**.

## 'A lezione 'e sta build

La 0.51: *una prova che misura a un punto solo dimostra qualcosa solo a
quel punto.* La 0.52: *quanto si tiene il banco.* La 0.53: *una cura
scritta bene può essere la malattia della versione dopo.* La 0.54: *la
stessa trappola nella stessa settimana non conta come imparata.*

Questa è la loro sorella maggiore:
**quanno 'na cosa nun se vede, 'o primmo suspetto è 'a prova.**

Il selciato bagnato funzionava dalla prima stesura. Ci ho messo quattro
giri di foto e tre correzioni a capire che tutte e tre stavano **nel
banco di prova** e non nel gioco: una chiamata che usciva subito, un
confronto che cambiava due cose invece di una, e un ciclo che riscriveva
quello che avevo appena scritto.

Il rovescio è la parte che conta davvero, ed è successo nella stessa
giornata: siccome quelle foto le stavo guardando sul serio, è saltato
fuori che **la pioggia schiariva la notte** — un difetto vero, vecchio di
due versioni, che nessuno avrebbe mai segnalato perché dentro al gioco non
sembra un difetto: sembra il tempo.
