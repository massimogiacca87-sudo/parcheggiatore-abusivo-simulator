# v0.49 — 'E pupe, mo' overo

> *"I modelli dei pg fanno veramente schifo. Sembrano tutti dei culturisti
> con la maglietta strappata. Falli daccapo completamente."*

Fatto: **daccapo per davvero**. Alla 0.48 avevo tenuto il manichino della
Unreal e gli avevo dipinto i vestiti addosso. Era la strada sbagliata, e le
due parole del capo dicono esattamente perché.

---

## Pecché 'e ddoje parole so' 'e ddoje diagnose giuste

**"Culturisti."** `UAL1_Standard.glb` porta un manichino da *demo tecnica*
della Unreal: pettorali segnati, deltoidi, polpacci, vita stretta. È un
atleta di ventisei anni. Nessuna vernice, nessuna testa ingrossata e nessun
ritocco alle proporzioni lo fa diventare un tizio che sta al bar da
trent'anni. **La forma era sbagliata in partenza**, e io stavo cercando di
correggere la vernice.

**"Maglietta strappata."** Questo è ancora più preciso, ed è una cosa
geometrica. Alla 0.48 la camicia non era una camicia: era un **insieme di
facce del corpo colorate di bianco**. Il confine fra due materiali corre
per forza lungo i **lati dei triangoli**, e i triangoli di un manichino
seguono i muscoli, non gli orli. Un bordo così, a un metro di distanza, si
legge per quello che è: stoffa strappata. Avevo spostato la soglia tre
volte — prima coi pesi delle ossa, poi con le quote, poi con la cintura per
nasconderla. Non era un problema di soglia. **Un orlo dipinto non è un
orlo.**

---

## Chello ca s'è fatto

Del file della libreria di animazione si tengono **solo lo scheletro (65
ossa) e le quarantatré animazioni**. Il manichino si butta. Il corpo si
modella da zero in `tools/build_personaggi.py`, misurato sulle ossa.

Le animazioni restano valide **per costruzione**: sono fatte per quello
scheletro, e il corpo nuovo sta appeso a quello scheletro. Non c'è niente
da ritargettare, quindi non c'è niente che possa venire storto.

**Comme se fa 'nu pupo.** Tutto è tubi lungo una spezzata di punti, con una
sezione ellittica per punto e i pesi delle ossa scritti a mano nodo per
nodo. Niente muscoli, perché non si modellano: il braccio è un cono che si
stringe, il petto è un barile morbido, il gomito si vede solo perché lì il
cono si stringe un po' di più.

**E 'e vestite so' rrobba, no culore.** La camicia è un guscio più largo del
corpo di un centimetro e mezzo, che finisce con un **orlo arrotondato** —
un anello più stretto, spostato in avanti di due centimetri, e poi il disco
che resta dentro al corpo e non si vede mai. Le maniche sono tubi che
partono da dentro alla camicia. I pantaloni sono un bacino e due gambe. Gli
orli sono geometria: si possono guardare da vicino.

Costano **2.406 triangoli** invece di 5.859. Quaranta persone in piazza
sono 96.000 invece di 234.000.

## Quatte corporature, no quaranta cloni

Alla 0.48 avevo scritto io stesso, in fondo alle note, che *"i personaggi
hanno tutti lo stesso corpo: cambia il colore, non la corporatura"*. Adesso
`pupo.glb` porta **quattro corpi** appesi allo stesso scheletro — normale,
panzone, magro, femmina — e il gioco accende quello che serve e butta gli
altri tre. Non è geometria diversa: è la stessa geometria tirata da quattro
tabelle di moltiplicatori, che si sovrappongono a campana in modo che un
panzone abbia la pancia che *cresce* dalla vita al petto, non un anello
grosso in mezzo a due sottili.

E la corporatura **non va scelta a mano**: mezzo gioco passa già l'opzione
`belly` da otto versioni — la passa il vecchio della scopa (`(età−60)/34`),
la passa la signora, la passa Borrelli, la passano i passanti a caso — e da
quando i personaggi hanno smesso di essere capsule **non la leggeva più
nessuno**. Adesso la pancia sceglie il corpo: sotto 0,22 magro, sopra 0,62
panzone. La città si è variata da sola.

## Pelato e cu 'e baffe, overamente

`bald` e `moustache` stavano nelle opzioni da sempre. `moustache` non ha
**mai** fatto niente. `bald` faceva una cosa peggiore del niente: siccome il
corpo era uno stampo solo, "togliere i capelli" voleva dire **tingerli color
pelle** — e visto che sopracciglia e bocca usavano lo stesso materiale, il
pelato restava pure **senza faccia**.

Adesso capelli e baffi sono **due oggetti per conto loro** (162 triangoli in
due) e si cancellano davvero, e i tratti della faccia hanno un materiale
tutto loro.

---

## 'E guaste truvate p''a via

Sette, tutti misurabili, tutti trovati guardando i render e poi contando.

**'A scarpa 'e Pippo — quaranta centimetri.** La funzione che chiude un tubo
con la cupoletta non si ferma all'ultimo anello: ci aggiunge una calotta
lunga quanto il raggio. Ce n'era una davanti *e* una dietro. Trentuno
centimetri di catena più nove di cupole: in gioco erano due pinne. Adesso il
tallone è **piatto** — che è come finisce una scarpa vera — e sono
ventotto, un quarantatré.

**'A spallina 'e pelle.** Fra il busto della camicia e il tubo della manica
restava un buco, e non per sbaglio: il busto è un'**ellisse nel piano
orizzontale**, quindi vicino alla spalla si assottiglia in profondità fino a
sparire, mentre il braccio sta a sei centimetri e mezzo *dietro* all'asse.
Nel triangolo fra i due non c'era stoffa, e da quel buco si vedeva il tappo
del busto: una spallina di carne sopra a ogni spalla — di nuovo, esattamente
una maglietta strappata sulla cucitura. Ci va una palla di stoffa sul perno
della spalla, che è anche la forma giusta: una spalla vestita è tonda.

**'A manica saglieva ncopp'â spalla.** Con 92 mm di raggio attorno a un osso
che sta a quota 1,441, il tubo della manica arriva a **1,533** — quattro
centimetri e mezzo sopra all'attacco del collo. Una gobba sopra ogni spalla,
e dove bucava la maglietta una tacca nera. Settantadue millimetri.

**'O pannolino.** Il bacino dei pantaloni era un cilindro largo trenta
centimetri e profondo ventiquattro che finiva di netto al cavallo con un
disco piatto, e le due gambe erano **più larghe di lui** e uscivano di lato
con lo spigolo vivo. La cura è quella del sarto: il fianco è il punto più
largo, poi la stoffa si stringe e soprattutto **si assottiglia** scendendo,
finché è profonda quanto la coscia.

**'A pelle ca sponta.** Tre punti, una causa sola. Serve una regola, e vale
per tutto il pupo: **pelle < pantaloni < camicia**, a ogni quota, per ogni
corporatura. Si garantisce solo se tutti e tre crescono con la **stessa
funzione** — e invece i pantaloni avevano una campana loro (0,98–1,30) e il
busto un'altra (0,94–1,27): sul panzone, alla cintura, la pelle cresceva del
25% e la stoffa del 13%, e restavano **due millimetri** di margine.

**'A capa a chiazze.** La calotta dei capelli stava il 2,5% più larga del
cranio: su una testa di dodici centimetri di raggio sono **tre millimetri**.
Ma fra due spicchi di una calotta a dodici lati la corda affonda verso il
centro di `r·(1−cos 15°)` = **quattro millimetri**, cioè più del margine.
Metà dei triangoli finiva *dentro* al cranio. Calotta al 6% e quattordici
spicchi.

**'E ssopracciglia 'a dereto.** Un parallelepipedo largo cinque centimetri e
mezzo appoggiato a una testa **tonda** la tocca solo nel mezzo: gli spigoli
esterni restano fuori dal cranio, e girando il personaggio spuntavano dal
profilo come due schegge.

---

## 'E ddoje trappole d''a prova

Le foto in gioco non venivano, e per due motivi che vale la pena scrivere
perché li ripescherò.

**'O gioco parte 'nzerrato.** C'è la schermata di caricamento, che mette
`get_tree().paused = true`. Un autoload che eredita il modo di elaborazione
si ferma con lui: `_process` non veniva chiamato **mai** e la prova restava
lì a guardare. Ci vuole `PROCESS_MODE_ALWAYS`.

**Godot nun se rilegge 'o file 'a sulo.** Le prime foto in gioco mostravano
i personaggi **della 0.48** — muscoli e maniche strappate — mentre in
Blender lo stesso file era già quello nuovo. L'importazione è in cache
(`.godot/imported/`) e il gioco non la rifà da solo: la rifà l'editor. Dopo
ogni `build_personaggi.py` ci vuole `godot4 --headless --path . --import`,
se no si collauda il modello vecchio credendo di collaudare quello nuovo.

---

## 'E prove

- `tools/prova_pose.gd` — **0 clip mancanti su 17**, e le mani si muovono
  davvero fra fermo, camminata e corsa.
- `tools/prova_mira.gd` — 24 oggetti, 0 storte.
- `tools/prova_modelli.gd` — 29 modelli d'auto, 0 storte.
- `tools/prova_casa.gd` — il giro completo di casa, conto e letto.
- `tools/prova_scopa.gd` — 300 partite per coppia, mazzo integro.
- `tools/prova_economia.gd` — a €75 al giorno nessuno scoperto.
- `tools/prova_pupo.py` — **nuova**: rende il pupo da tre lati in Blender.
- `tools/foto_pupi.gd` — **nuova**: cinque corporature dentro al gioco,
  ferme, che camminano, che corrono, stese e in primo piano. È l'unica
  prova che conta davvero, perché usa la luce e i materiali del gioco.

---

## Quello ca ancora nun va

- Le facciate restano spoglie: mancano insegne, fili, tende, tapparelle.
- Il Castel dell'Ovo in fondo è ancora un blocco marrone.
- Il fumetto delle parlate si mangia un quarto dello schermo da vicino.
- **'E criature so' aduldi piccerille.** Un bambino di 1,34 m è il corpo
  dell'adulto scalato: un bambino vero ha la testa molto più grossa in
  proporzione. Ci vuole un quinto corpo, non un moltiplicatore.
- Le mani sono manopole senza dita. A due metri va bene; quando il
  giocatore si guarda le proprie mani, meno.
