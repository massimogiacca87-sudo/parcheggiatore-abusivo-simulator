# Prompt per le texture dei quartieri

Le texture che stanno nel gioco adesso sono **segnaposto generati a codice**
(`tools/texture_quartieri.py`). Funzionano, i quartieri si distinguono, ma
sono rumore procedurale e si vede. Questo documento serve a sostituirle con
immagini vere.

---

## Come si sostituisce una texture

1. Genera l'immagine col prompt qui sotto.
2. Salvala in `assets/textures/` **con lo stesso identico nome**
   (es. `muro_liberty.jpg`).
3. Riapri il progetto in Godot: la reimporta da sola.

Non c'è codice da toccare. Il nome del file è l'unico aggancio.

## Requisiti tecnici — valgono per TUTTE

| | |
|---|---|
| **Formato** | JPEG, quadrata |
| **Dimensione** | 512 × 512 (il gioco le ridimensiona a 512 comunque) |
| **Affiancabile** | **Sì, obbligatorio.** Seamless / tileable, senza cuciture |
| **Scala** | una piastrella copre circa **6 metri** di muro vero |
| **Inquadratura** | frontale, ortogonale, come una foto tecnica di materiali |

Tre cose che rovinano una texture in questo gioco, e che i generatori
sbagliano quasi sempre se non gliele dici:

- **Niente ombre dipinte dentro.** Il sole ce lo mette il motore. Se la
  texture ha già un'ombra cotta, quella ombra resta lì anche di notte.
- **Niente prospettiva, niente oggetti.** Nessuna finestra, nessun balcone,
  nessuna porta: quelli sono geometria, li costruisce il gioco. La texture è
  solo il materiale del muro.
- **La luminanza fa da rilievo.** Lo shader ricava le normali dal
  chiaroscuro dell'immagine: le fughe, le crepe e gli incavi **devono essere
  più scuri** del piano del muro, o il muro esce piatto. Al contrario, una
  macchia scura che *non* è un incavo (una colatura, una scritta) diventerà
  una finta scanalatura.

Da aggiungere in coda a ogni prompt:

> seamless tileable texture, orthographic flat-on view, even diffuse
> lighting, no cast shadows, no vignetting, no perspective, no windows or
> doors, photographic material study, 512x512

---

## I sei quartieri che ci sono

### 1. 'E Quartiere — Quartieri Spagnoli (la piazza iniziale)
*Vicoli da quattro metri, panni stesi, intonaco che se ne va a pezzi.*

**`muro_scrostato.jpg`**
> Weathered Neapolitan alley wall, warm ochre lime plaster peeling away in
> irregular patches to reveal old red-orange brickwork underneath, decades of
> layered repairs in slightly different tones, fine hairline cracks, salt
> efflorescence blooming near the base, grimy but sun-bleached

**`muro_ocra.jpg`** · **`muro_terracotta.jpg`** · **`muro_rosa.jpg`**
> Old southern Italian lime-washed render in deep ochre yellow [per
> terracotta: burnt terracotta orange / per rosa: faded dusty pink], chalky
> matte surface, uneven hand-applied trowel texture, water staining running
> down from above, small chips and patches of a previous colour showing
> through

---

### 2. 'A Sanità — il quartiere del mercato
*Tufo giallo a vista, palazzi altissimi e strettissimi, mezzo sbriciolati.*

**`muro_tufo.jpg`**
> Neapolitan yellow tuff stone block wall, large soft volcanic ashlar blocks
> in staggered courses, porous crumbly sandy-yellow stone, wide pale lime
> mortar joints, blocks eroded and rounded at the edges, dark damp streaks
> running down from the joints, some blocks patched with newer cement

---

### 3. 'A Riviera — la fascia che guarda il golfo
*Umbertino: grigio-verde, bugnato, palazzi alti e in ordine. Signorile ma
vissuto.*

**`muro_umbertino.jpg`**
> Late-19th-century Italian palazzo façade render, smooth grey-green stucco
> divided into wide horizontal ashlar bands by shallow incised grooves,
> restrained and elegant, faint soot darkening in the grooves, a few fine
> settlement cracks, no ornament

**`muro_crema.jpg`**
> Clean cream-coloured smooth lime stucco on a bourgeois Italian apartment
> block, very fine sand aggregate, subtle tonal variation from patch repairs,
> light grey grime collecting in the lower third

---

### 4. 'O Rione d''o Stadio — Fuorigrotta
*Razionalismo anni Trenta: travertino, volumi squadrati, tutto in ordine.*

**`muro_travertino.jpg`**
> Roman travertine cladding panels on a 1930s Italian rationalist building,
> large rectangular slabs in perfectly regular courses, thin tight joints,
> warm ivory stone with the characteristic horizontal porous cavities and
> banding, monumental and austere, lightly weathered

---

### 5. 'O Vommero — il quartiere buono
*Liberty: palazzi belli, puliti, perfetti. Nessuna crepa, nessun panno
steso, tetti a falda.*

**`muro_liberty.jpg`**
> Italian Liberty-style (Art Nouveau) apartment façade render, immaculate
> pale ivory-cream smooth stucco, divided into tall smooth ashlar courses by
> crisp shallow horizontal reveals, very fine even surface, freshly restored,
> no cracks and no staining, refined and expensive

**`muro_liberty_verde.jpg`**
> Same as above but in soft sage-green stucco with an ivory tone in the
> incised reveals — Italian Liberty-style apartment façade, immaculate and
> freshly restored, crisp horizontal ashlar reveals, no cracks, no staining

**`cotto.jpg`** *(i tetti a falda, solo qui)*
> Italian terracotta roof tiles seen from directly above, rows of curved
> coppi in warm orange-red, tones varying tile to tile from new orange to
> weathered brown, patches of grey-green lichen in the channels, dark
> shadowed gaps between rows

---

### 6. 'O Centro — quello che avanza
Usa `muro_crema`, `muro_ocra`, `muro_umbertino`, `muro_rosa`: niente di
nuovo.

---

## Le pavimentazioni e il resto

**`basolato.jpg`** — i vicoli, e il pezzo che si vede di più in tutto il gioco
> Neapolitan basolato paving, large irregular slabs of dark grey vesuvian
> basalt laid in staggered rows, surfaces worn smooth and slightly polished
> by centuries of feet, wide dark joints packed with grit, subtle blue-grey
> and charcoal variation between slabs, damp patches

**`piperno.jpg`** — gli zoccoli e i portali, in quasi tutti i quartieri
> Piperno stone ashlar, the dark grey-brown Neapolitan volcanic stone, large
> smooth-tooled blocks with tight joints, characteristic scattered pale
> angular inclusions in the dark matrix, used for building bases and door
> surrounds, worn and slightly greasy at hand height

**`marciapiede.jpg`** — i marciapiedi e i lastricati
> Italian pavement of large rectangular grey stone flags, regular grid,
> shallow chips at the corners, fine grit in the joints, evenly worn

**`asfalto.jpg`** — le strade larghe
> Worn city asphalt, coarse aggregate showing through the bitumen, patched
> repairs in slightly different shades, fine cracks, oil staining

**`maioliche.jpg`** — il tappeto al centro della piazza iniziale
> Antique Neapolitan majolica floor tiles, hand-painted geometric pattern in
> cobalt blue, ochre yellow and white on a terracotta body, glaze crazed and
> worn thin at the centre of each tile, a few tiles chipped or replaced with
> mismatched ones

**`serranda.jpg`** — le saracinesche dei negozi
> Closed corrugated metal roller shutter, horizontal ribs, grey paint dented
> and scratched, rust blooming at the bottom edge, faded graffiti tags

**`portone.jpg`** — i portoni
> Old heavy Italian double door in dark green painted wood, deep rectangular
> panels, paint cracked and flaking, brass handle worn bright

**`manifesti.jpg`** — i muri tappezzati
> Wall completely covered in layers of torn overlapping fly-posted paper
> bills, half-stripped, sun-bleached to pastel, edges curling, the layers
> beneath showing through in strips

---

## Quartieri nuovi: come si aggiunge

Un quartiere sta tutto in una voce di `QUARTIERI` in
`scripts/quartieri.gd`. La regola pratica: **cambia almeno tre cose
insieme**, o non si nota. Solo il colore dell'intonaco non basta — servono
anche l'altezza dei palazzi, la larghezza delle campate, cosa c'è al piano
terra.

Se ne vuoi altri, questi sono già disegnati e servirebbero solo le texture:

**Posillipo** — ville basse, muri di cinta, bouganville
> Mediterranean villa boundary wall, warm white lime wash over rough
> rubble-stone masonry, the stones showing through as soft bulges, sun-faded,
> a dry crust of salt near the ground

**'O Porto** — magazzini, ferro, ruggine
> Industrial dockside warehouse wall, corrugated steel sheeting bolted to a
> frame, faded blue-grey paint, heavy rust streaks running down from every
> bolt and seam, patched with mismatched panels

**'A Zona Nuova** — palazzoni anni Settanta, cemento e piastrelline
> 1970s Italian apartment block façade, panels of small square ceramic
> mosaic tiles in muted brown and beige, whole patches of tiles missing to
> show grey concrete underneath, dark rain streaking below every horizontal
> edge

**'O Centro Antico** — il decumano, chiese e tufo scuro
> Ancient Neapolitan street wall, grey-brown tuff blocks blackened by
> centuries of soot, irregular masonry with many phases of repair in
> different stones and bricks, votive shrine marks, deeply weathered
