# Novità v0.42 — Blender dentro al gioco, e la prima infornata di modelli

Sì, si può fare. Ecco la prova, e il piano per il resto.

---

## Come ci sono arrivato

Il Blender del tuo computer non risponde: l'addon non è avviato e il
percorso dell'eseguibile non è impostato, quindi il ponte non parte. Ma non
serve — **ho installato Blender 4.2 dentro questa sessione**, come modulo
Python. Modello, esporto in `.glb`, importo in Godot e mi guardo il
risultato senza rimbalzi fra due macchine.

Tre cose imparate nella prima mezz'ora, tutte scritte in
`tools/blender/napoli.py`:

1. **`bpy.ops` non si può usare.** Blender come modulo non ha un contesto
   vero: `object.join`, `transform_apply`, tutto quello che agisce sulla
   "selezione" non dà errore — **crasha con un segmentation fault**. Si
   costruisce tutto con `bmesh`, che è l'API di basso livello.
2. **Gli assi.** Blender ha Z in alto, glTF (e Godot) Y. Misurato con un
   modello asimmetrico: `Blender +Y → Godot −Z`. Cioè si modella
   **guardando verso +Y**, e quello diventa l'avanti di Godot.
3. **`read_factory_settings` cancella i materiali già creati** e le
   variabili che li puntavano restano riferimenti morti. La cache dei
   materiali si svuota insieme alla scena.

C'è anche un renderer di provini (`tools/blender/anteprima.py`, Cycles su
CPU) per guardarsi un modello in venti secondi senza avviare il gioco.

---

## Cosa c'è dentro, adesso

Dodici modelli veri al posto di scatole e cilindri. Tutti sotto i
duemilaseicento triangoli, tutti con le **misure vere** — una coppola è
larga 28 cm perché una coppola è larga 28 cm.

### Il salotto (Bazar)

| | prima | adesso |
|---|---|---|
| **Sedia sdraio** | sei parallelepipedi | telaio di tubolare piegato in un pezzo solo per fianco, tela a righe **che fa la pancia** |
| **Ombrellone** | palo + otto prismi in cerchio | otto spicchi cuciti, incavati fra le stecche, stecche di legno, base di cemento |
| **Tavolino** | cilindro + cilindro | piano di marmo, gamba di ghisa a tre piedi, e la tazzulella sopra |
| **Radio** | cubo con due dischetti | cassa smussata, **griglia a fori veri**, scala parlante che si illumina, manopole cromate, manico di cuoio, antenna storta |
| **Piante** | tronco + tre sfere | vaso di terracotta con l'orlo, otto foglie di lunghezza diversa che ricadono |
| **Luminarie** | 48 pallini appesi per aria | tre campate col **cavo che fa la catenaria**, portalampada e bulbi |

### Gli attrezzi ('O Zio)

| | prima | adesso |
|---|---|---|
| **Gilet** | cinque scatole gialle | un guscio che **avvolge** il torace, aperto davanti con lo spacco, bande catarifrangenti, spalline e zip |
| **Borsello** | tre scatole | cuoio smussato con patta, fibbia d'ottone, cuciture, tracolla che sale in diagonale |
| **Paletta** | cilindro + disco | impugnatura di gomma zigrinata, asta cromata, disco bianco e rosso con corona catarifrangente |
| **Coppola** | — | calotta morbida spostata indietro, visierina, bottoncino |
| **Occhiali** | — | lenti bombate, montatura, ponte, aste piegate verso l'orecchio |
| **Fischietto** | — | corpo cromato, camera, bocchino, anellino e cordino rosso |

Ogni modello ha **l'origine nel punto in cui si attacca** — il gilet al
centro del torace, la paletta in fondo al manico dove la stringe la mano —
così chi lo monta scrive una posizione sola e non indovina scostamenti.

### E la geometria vecchia resta

Ogni `_make_*` prova prima il modello e, se il file non c'è, costruisce le
scatole come sempre. È la stessa regola che vale per le auto da quando
esiste `models.gd`: nessuno deve ritrovarsi il salotto vuoto perché manca
un `.glb`.

---

## Quello che ho corretto guardandolo in gioco

Tre giri di prova, tre correzioni misurate:

- **La sdraio era smontata.** Il primo telaio erano quattro cilindretti per
  fianco messi agli angoli giusti: da vicino aveva un buco in ogni piega.
  Ho aggiunto a `napoli.py` un `tubo()` che segue una spezzata nello
  spazio, e adesso ogni fianco è **un tubo solo**. È l'attrezzo che userò
  per tutti i telai, le ringhiere e i corrimano.
- **Il gilet stava al collo.** Montato a 1,16 m arrivava sopra le spalle e
  sembrava un collare. E era largo 38 cm — giusto per un uomo, sbagliato
  per il manichino del gioco, che è più stretto. Sceso a 1,02 e stretto a
  30 cm.
- **La pianta sembrava un ragno.** Vaso schiacciato (24 cm d'altezza per 26
  di bocca) e otto foglie tutte uguali a ventaglio perfetto. Vaso alto
  quanto largo, foglie di otto lunghezze diverse ad angoli irregolari.

---

## Il pacchetto stava per sforare (ancora)

Con i modelli dentro, Windows è passato a 30,29 MiB — trenta è il limite
oltre il quale non te lo posso mandare. I modelli però pesano **359 KB in
tutto**: il grasso stava altrove, nelle texture importate a qualità 0,78.
Portate a 0,55, e i sei manifesti a 0,40 (sono 384×384 e a schermo stanno
su un muro): 29,97 MiB.

---

## Il piano per il resto

Questa è la prima infornata. Le altre due sono più grosse e vanno fatte in
ordine, perché la seconda dipende da una decisione della prima:

**2. I personaggi.** Qui c'è un nodo da sciogliere prima di modellare. I
personaggi del gioco non sono modelli: sono **assemblati da un rig**
(`rig.gd` + `human_builder.gd`) con ossa vere, e sopra ci girano le
animazioni di Mixamo che abbiamo montato nella 0.38. Se metto un modello
`.glb` al posto del manichino, il rig sparisce e con lui camminata, pugni e
knockout. Le strade sono due:

- rifare i **pezzi** (testa, mani, busto, scarpe) come modelli agganciati
  alle ossa esistenti — l'animazione resta, e si migliora quello che si
  guarda da vicino;
- fare modelli **con lo scheletro dentro**, con gli stessi nomi d'osso, e
  cambiare il rig perché li usi — risultato migliore, lavoro molto maggiore
  e rischio di rompere le animazioni.

Comincerei dalla prima: teste, mani e scarpe si vedono a mezzo metro, il
resto no.

**3. I palazzi.** La città è procedurale — facciate, balconi, persiane e
panni stesi li scrive il codice. Non li sostituirei in blocco: farei un
**kit di pezzi** (balcone col ferro battuto, persiana, portone, cornicione,
edicola votiva, insegna) che il codice pesca e piazza dove piazza già le
scatole. La città resta generata, ma di pezzi veri.

**4. La scenografia di piazza** — cassonetto, cestino, panchina, lampione,
fontanella, bancarella, la vespa parcheggiata. È la lista che sta ancora
scritta come "da fare" in `assets/models/LEGGIMI.md`, ed è la più facile
delle tre.

Dimmi da dove vuoi che parta.

---

## Nel pacchetto

- `ParcheggiatoreAbusivo-v0.42-Windows.tar.xz`
- `ParcheggiatoreAbusivo-v0.42-Web-itchio.zip`
- `ParcheggiatoreAbusivo-v0.42-Sorgenti.zip` — dentro c'è
  `tools/blender/`, cioè gli script che generano i modelli: si rilanciano
  e i `.glb` si rifanno da capo
