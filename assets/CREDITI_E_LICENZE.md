# Crediti e licenze — asset esterni (scaricati il 25/09/2026)

Tutto è CC0 (pubblico dominio) o open source, **tranne i file segnati CC-BY**: quelli sono liberi
anche per uso commerciale ma vanno citati nei crediti del gioco (autore + link).
Il dettaglio file per file è nei `CREDITI_*.txt` di ogni cartella.

| Cartella | Fonte | Licenza |
|---|---|---|
| `../addons/proton_scatter` | ProtonScatter (HungryProton), commit f0ed713 — ultimo compatibile Godot 4.3 | MIT |
| `../addons/dialogic` | Dialogic 2.0-alpha-18 — ultima release che supporta Godot 4.3 (dalla alpha-19 serve 4.4) | MIT |
| `../addons/limboai` | LimboAI v1.3.1 GDExtension per Godot 4.3 (le versioni ≥1.4 richiedono 4.4+) | MIT |
| `models/polypizza/*` (oggetti urbani) | Poly Pizza | CC0 |
| `models/polypizza/scooter/low_poly_scooter…, Scooter…, Vespa…` | Poly Pizza | **CC-BY 3.0** |
| `models/polypizza/npc_animati` (sostituto di Mixamo) | Poly Pizza / Quaternius e altri | CC0 |
| `materials/{asfalto,basolato,cemento,intonaco}`, `materials/hdri` | Poly Haven | CC0 |
| `materials/decals/*` (crepe, macchie/perdite, gomme, tombini, strisce, chewing gum) | ambientCG (sostituto di Textures.com) | CC0 |
| `materials/decals/graffiti` | karlwirbelwind (Zenodo/Sketchfab) | **CC-BY 4.0** (titolo dice CC0, metadati CC-BY: citiamo) |
| `shaders/*` | GodotShaders (autori in `CREDITI_shader.txt`) + `dirty_lens` scritto per il progetto | CC0 |
| `audio/*` | Freesound, filtro CC0 (anteprime HQ OGG) | CC0 |
| `ui/kenney_*` | Kenney: UI Pack + Game Icons + Board Game Icons | CC0 |

## Sostituzioni rispetto alla richiesta
- **Mixamo** → non scaricabile: richiede login Adobe, esporta solo FBX e la licenza non è CC0/open source.
  Al suo posto: personaggi CC0 animati in `.glb` con Idle, Walk, Run, **Wave** (dirigere il traffico),
  **Interact / PickUp** (passare i soldi), Punch/Idle_Gun_Pointing (litigare). In più, in `Animations/`
  c'è già la Universal Animation Library di Quaternius (CC0, `.glb`) da retargettare.
- **Textures.com** → licenza proprietaria (non CC0) e download solo con account: sostituito da ambientCG (CC0).
  Manifesti: non ho trovato decal CC0 adatti; in `Progetto/.../assets/manifesti` ce ne sono già.
- **Freesound**: l'originale non compresso richiede login; ho preso l'anteprima HQ ufficiale in OGG (~192 kbps).
- **GodotShaders**: non esiste uno shader "dirty lens" dedicato → `shaders/lente_sporca/dirty_lens.gdshader` è originale.
  Le normal map DirectX dei decal sono state rimosse: Godot usa le `NormalGL`.
