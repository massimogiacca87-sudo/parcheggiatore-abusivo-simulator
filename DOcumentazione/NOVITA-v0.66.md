# Novità della v0.66 · 'E facce nove

28 settembre 2026. La richiesta del capo:

> *«Deve migliorare i personaggi del gioco, aggiungendo dettagli e rendendoli
> più belli. Deve mantenere le animazioni esistenti se possibile o crearne di
> nuove se necessario. Il gold standard rimane Schedule I. Vorrei però che i
> nostri personaggi mantengano personalità e un minimo di napoletanità.»*

Primo lavoro della squadra grafica (`/grafico-psx`): direttore, due
modellatori, texture, shader, technical artist, revisore. Giudizio finale
del revisore: **7,5/10, APPROVATO** (primo giro 6,5 DA RIFARE, quattro
correzioni bloccanti tutte chiuse).

---

## 1 · 'O pupo nuovo

Il pupo è il corpo di quasi tutti: autisti, vigili, carabinieri, il Re,
Borrelli, le signore, i vicini, e da questa versione **tutti i passanti**.

- **La testa** (`tools/pupo_testa.py`): a uovo, occhi a palla con l'iride,
  palpebre pesanti alla Schedule I in quattro umori (sveglie, stanche,
  arraggiate, furbe), cinque sopracciglia, tre nasi (piccolo, a patata,
  aquilino), otto capigliature (corti, gellati lucidi, ricci, sfumati,
  stempiati, messa in piega, tuppo, lunghi), baffoni.
- **La faccia dipinta** (`assets/shaders/pupo_faccia.gdshader`,
  `assets/textures/pupo/`): sei bocche (dritta, cazzimma, sorriso, storta,
  preoccupata, rossetto), quattro barbe col colore dei peli (sfatta,
  pizzetto, barba, basette), quattro rughe (stanco, vecchio, vecchia,
  arraggiato).
- **Il corpo** (`tools/pupo_corpo.py`): maglietta in un pezzo con le maniche
  vere, pantaloni con fascia e tasche, mani che chiudono il pugno, scarpe con
  la suola chiara; e da accendere: colletto coi bottoni, cintura, **catenina
  d'oro col cornetto rosso**, gonna (calze nere o velate), **gilet da
  parcheggiatore**.
- **Animazione nuova**: le palpebre sbattono ogni 2–5 secondi, e chi sta a
  terra ha gli occhi chiusi (`animator.gd`, blend shape `chiudi`).
- **Le 43 animazioni di sempre sono intatte**: il corpo nuovo è trapiantato
  sullo scheletro e sulle clip originali di `pupo.scn`, senza convertirle.

## 2 · 'A faccia 'e ognuno

Ogni personaggio della storia ha la sua: il Re con la cazzimma, Borrelli
indignato, lo Zio col sorrisetto e il cornetto, Donna Filumena col tuppo, il
vigile scocciato, il carabiniere arraggiato, il magliaro delle tre carte
ingellato, la signora del lotto furba, Gennarino che sorride da novellino. I
passanti prendono la faccia dal mestiere (il guappo ingellato col cornetto, la
signora col rossetto e la gonna, il marenaro con la barba sfatta); il resto lo
pesca `HumanBuilder._scegli_faccia`. I corpi dei pacchetti restano solo per
l'operaio col casco e il marenaro col cappello di paglia.

Sistemati lungo la strada: cappelli e visiere che lasciano vedere le
sopracciglia; la faccia di Borrelli rifatta col sistema nuovo (stessi tre
tratti: occhiali, barba, capelli mossi); lo scialle della signora del lotto
(era una scatola nera) e il berretto di Gennarino (stava dentro la testa); le
bandoliere sottili; il gilet del rivale (una capsula che tagliava la maglia);
i pupi a terra che perdevano la testa.

## 3 · Come si rifà il pupo (trappole)

- `UAL1_Standard.glb` sta solo sul PC del capo: lo scheletro si tira fuori da
  `pupo.scn` (`tools/esporta_scheletro.gd`), il corpo si fa in Blender
  (`python3 tools/build_personaggi.py`, il regista che chiama i due moduli) e
  si rimonta sulle clip con `tools/monta_pupo.gd` (ricalcola i legami delle
  ossa: Blender gira le ossa a modo suo).
- Blender come modulo va in segfault all'uscita (codice 139) **dopo** aver
  scritto il glb: si controlla il file, non il codice d'uscita.
- Le UV le mette il regista per materiale (`uv_per_materiale`): la faccia è
  proiettata da davanti in una finestra di 26 cm; Blender e glTF hanno la v
  rovesciata (`_uv`).
- I nomi delle texture si scrivono per intero (`TEX_BOCCHE`…): `prova_asset`.
- Le texture del pupo vogliono le mipmap (nei `.import`), se no la barba
  sfatta sfarfalla.
- Foto dentro al gioco senza toccare `project.godot`:
  `godot --script res://tools/lancia_foto.gd -- res://tools/foto_storia.gd`;
  poi `foto_personaggi.gd`, `foto_strada.gd`; costo: `misura_pupi.gd`.

## 4 · Numeri

Corpo 1.764 triangoli; un personaggio montato 2.500–3.500. Folla di 40:
2.195 chiamate di disegno contro 1.781 del pupo vecchio (+23%); i pezzi
piccoli non fanno ombra e si spengono oltre 25 m. **Da controllare gli FPS
sul PC del capo.** Prove `prova_croce`, `prova_asset`, `prova_psx`,
`prova_arredo`: zero errori.

## 5 · Rimasto aperto

- Il berretto del carabiniere sembra un colbacco.
- La posa ferma è uguale per tutti (un po' curva, gomiti larghi): servono
  due o tre varianti.
- Borrelli: la mano col telefono schiaccia la barba.
- La borsetta sul petto delle signore senza tracolla; busta e cassetta a
  scatola.
- ~~Da decidere al capo: Borrelli e lo stencil di Maradona~~ → **deciso
  (29/09/2026): restano, anche nella build in vendita.** Il gioco è
  satira; la BIBBIA §6 è aggiornata.
