# ASSET ESTERNI — cosa c'è, dove sta, a cosa serve

Preparati il 25/09/2026 da una sessione a parte; **agganciati al gioco il 26/09/2026** (v0.62,
seconda metà). La tabella qui sotto dice cosa è entrato; il resto del documento è la guida
originale alla biblioteca, com'era.

## Stato alla v0.62 — cosa usa il gioco

| Cosa | File della biblioteca | Dove nel gioco |
|---|---|---|
| Asfalto delle strade larghe | `materiali/asfalto/asphalt_02` | `assets/textures/pbr/asfalto_*.jpg` (derivate da `tools/prepara_esterni.py`), `Tex.PBR` in `scripts/textures.gd` |
| Muro con la muffa (Sanità) | `materiali/intonaco/concrete_wall_003` | `assets/textures/pbr/muffa_*.jpg`, shader `intonaco.gdshader` (`mappe_vere`) |
| Tombini, rattoppi, gomme, olio, colature, umido | decals `ManholeCover001/005`, `AsphaltDamage001`, `ChewingGum001`, `Leaking003/006/008` | `assets/textures/decal/*.png`, `scripts/robba_esterna.gd` |
| Graffiti a tag (**CC BY 4.0**) | `decals/graffiti/graffiti_00.png` | `assets/textures/decal/graffito_tag.png` |
| Vespa, due scooter (**CC BY 3.0**) | `modelli/scooter/Vespa_*`, `Scooter_*`, `low_poly_scooter_*` | `Models.ESTERNI` (`vespa`, `scooter_bianco`, `scooter_blu`): al cordolo e il motorino che passa |
| Sedia di Vienna, sedia d'ufficio | `plastic_chair/Chair_kLViSk9EhX`, `Office_Chair_*` | fuori dai bassi / buttate |
| Coni, cassa, cassetta della frutta, bidone | `traffic_cone/*` (tre), `crate/Crate_3V*`, `crate/Fruit_Crate_*`, `trash_can/Trashcan_vlVx*` | cantieri, cassonetti, tavolino delle sedie, marciapiedi |
| Sei persone animate | `npc_animati/Business_Man`, `Casual_Character`, `Worker`, `Farmer`, `Animated_Woman` ×2 | `Human.QUAT` in `scripts/human_builder.gd`, mosse del pupo tradotte in `assets/models/quat_ual.res` |
| Dodici suoni | `audio/chiavi`, `clacson_traffico`, `monete`, `folla_voci_arrabbiate`, `scooter` | `audio/*.ogg` (tagliati e normalizzati da `prepara_esterni.py`), `SoundManager` |
| Filtri dello schermo e la botta | `shader/vhs_grunge/*`, `shader/lente_sporca` | `assets/shaders/filtri/`, `scripts/filtri_schermo.gd` |
| Pozzanghere (solo Forward+) | `shader/pozzanghere` | `assets/shaders/pozzanghere.gdshader`, `scripts/pozzanghere.gd` |
| Borsello che si riempie / svuota | Kenney `board_game_icons/pouch_add`, `pouch_remove` | `assets/ui/icone/borsa_entra.png`, `borsa_esce.png` |

**Non usati, e perché** (racconto completo in `DOcumentazione\NOVITA-v0.62.md`): i tre plugin
(la città è costruita a codice, il gioco ha già i suoi dialoghi in napoletano e i suoi stati
degli NPC, e LimboAI romperebbe la build web); le auto (doppioni del Car Pack), i quattro
personaggi doppioni degli omini e dell'umano di Quaternius già in gioco, la moto viola, la
sedia di plastica e i cestini piccoli e grandi; basolato, cemento, intonaci e HDRI (i quartieri
hanno le loro texture e il cielo cambia con l'ora); il resto delle icone e del pacchetto UI
(il tema della 0.62 c'era già). Quello che non si usa resta **fuori dall'esportazione**
(`exclude_filter` di `export_presets.cfg`, in tutti e due i preset).

Una trappola da sapere: le demo di ProtonScatter contengono un `.blend`, e Godot senza
finestra resta fermo a importarlo. Nel `project.godot` c'è `import/blender/enabled=false`.

- Elenco completo file per file (con peso): `res://assets/esterni/ELENCO-FILE-ESTERNI.txt`
- Collaudo automatico: `res://tools/test_asset_esterni/test_asset_esterni.tscn` (carica tutto, compila gli shader, stampa un rapporto)
- Crediti dettagliati: i `CREDITI_*.txt` in ogni sottocartella

## ⚠️ Tre cose da sapere prima di iniziare
1. **Export**: in `export_presets.cfg` (Windows e Web) ho aggiunto `assets/esterni/*` all'exclude_filter,
   perché il preset è "all_resources" e ~450 MB di roba non usata avrebbero gonfiato la build web.
   **Quando un asset viene usato davvero**, togli l'esclusione (o spostalo fuori da `esterni/`,
   o restringi il filtro alla sola sottocartella inutilizzata). Altrimenti in gioco esportato non c'è.
2. **Versione Godot**: i plugin sono le versioni per **Godot 4.3** (quella del progetto e della pipeline cloud).
   Sul PC di Massimo c'è anche Godot 4.7.2: se si apre il progetto con quello, Dialogic alpha-18 e Scatter
   potrebbero dare errori → in quel caso vanno aggiornati (Dialogic 2.0-alpha-20, Scatter ramo main, LimboAI 1.8.x).
3. **LimboAI + build Web**: LimboAI qui è una GDExtension. Il suo `.gdextension` include le librerie web,
   ma il Web export le carica solo con i template "dlink" (opzione *Extensions Support* nel preset Web,
   richiede cross-origin isolation su itch). Se non si attiva, nel gioco web le classi BT* non esistono.
   Alternativa: behavior tree scritti in GDScript puro. Decidere prima di scrivere la logica NPC.
4. **Pozzanghere solo su PC**: lo shader SSR delle pozzanghere usa `hint_depth_texture`, che il renderer
   Compatibility di Godot 4.3 (quello della build **web**) non supporta. `fullscreen_mesh.gd` se ne accorge
   e si spegne da solo sul web (warning in console, nessun errore). Per il web servirà un ripiego
   (decal di pozzanghera + roughness bassa sull'asfalto).

## Collaudo fatto (25-26/09/2026, Godot 4.3.stable ufficiale, RTX 5070 Ti)
- Import completo nell'editor: 0 errori (solo warning "invalid UID" di Dialogic, innocui su 4.3).
- `test_asset_esterni.tscn` in **Forward+** e in **Compatibility**: 0 errori. Risultati: LimboAI (BTPlayer,
  BehaviorTree, LimboHSM, BTAction) ok · autoload Dialogic ok · ProtonScatter ok · 35 modelli .glb caricati,
  11 con animazioni · 120 texture/HDRI · 25 audio .ogg · 2502 file UI · tutti gli shader compilano.
- Gioco principale (`Main.tscn`) avviato 400 frame con i plugin attivi: nessun errore nuovo.
- Nota: Godot per importare va lanciato **con finestra**: `--headless --import` su Windows con questo
  progetto si pianta (provato 3 volte). Nel cloud Linux la pipeline headless solita va verificata.

## 1. Plugin — `res://addons/` (attivi)
| Plugin | Versione | Stato | A cosa serve qui |
|---|---|---|---|
| `proton_scatter/` | ProtonScatter 4.x, commit f0ed713 (ultimo per Godot 4.3) — MIT | attivo in `[editor_plugins]` | spargere a mano/proceduralmente spazzatura, coni, casse, bidoni lungo marciapiedi e vicoli (nodo `ProtonScatter` + `ScatterItem` + `ScatterShape`) |
| `dialogic/` | Dialogic 2.0-alpha-18 (Godot 4.3+) — MIT | attivo + autoload `Dialogic` | contrattazione della mancia: timeline con scelte, variabili (prezzo, pazienza), segnali verso `GameManager` |
| `limboai/` | LimboAI 1.3.1 GDExtension per 4.3 — MIT | caricato automaticamente (non è un editor plugin) | behavior tree degli NPC automobilisti: cerca posto → segue i gesti → paga/non paga/litiga (`BTPlayer`, `BehaviorTree`, `LimboHSM`) |

## 2. Modelli 3D — `res://assets/esterni/modelli/` (tutti `.glb`, low-poly)
| Cartella | File | Licenza |
|---|---|---|
| `plastic_chair/` | Chair_Rlyhe93NNe, Chair_kLViSk9EhX, Office_Chair_UfKvrZBK6C | CC0 |
| `traffic_cone/` | Traffic_Cone_lAx8JytxGD, Traffic_Cone_aDIrUbMbW3, Road_Cone_ZPhinXAGtY | CC0 |
| `crate/` | Crate_3VGWnZPXmG, Cube_Crate_YAghI6GBls, Fruit_Crate_aXulVWHOeV (cassetta della frutta!) | CC0 |
| `trash_can/` | Trashcan_vlVx279xut, Trashcan_Small_i7HDuYDLkx, Trashcan_Large_eYNKnGlhon | CC0 |
| `scooter/` | Cartoony_Purple_Motorcycle_j20srJUjpB (CC0); **Vespa_blGLclvvdEM, Scooter_fPLXByG4Vx5, low_poly_scooter_awXCP7LUcz6 (CC-BY 3.0 → crediti obbligatori)** | misto |
| `utility_car/` | Car_unqqkULtRU, Stationwagon_vTTTjDoxhV, VIP_Susanne_s_car_KIfFi9Vh0O (utilitarie), SUV_xsMtZhBkxL, Sports_Car ×2, **Police_Car_BwwnUrWGmV** (vigili!) — auto con ruote come nodi separati | CC0 |
| `npc_animati/` | 11 personaggi riggati con animazioni, vedi sotto | CC0 |

### NPC animati (sostituto di Mixamo)
| File | Animazioni utili |
|---|---|
| Business_Man, Casual_Character, Worker, Farmer, Animated_Woman ×2 (stesso rig "CharacterArmature", 24 clip) | Idle, Idle_Neutral, Walk, Run (+Back/Left/Right), **Wave** (= dirigere il traffico / chiamare), **Interact** (= passare i soldi), **Idle_Gun_Pointing** (= indicare il posto), Punch_Left/Right, Kick, HitRecieve, Death, Roll |
| Man, Man_in_Suit (rig "HumanArmature", 11 clip) | Man_Idle, Man_Walk, Man_Run, Man_Standing, Man_Sitting, **Man_Clapping**, Man_Punch, Man_Death, Man_Jump |
| Woman_Casual (11 clip) | Female_Idle, Female_Walk, Female_Run, Female_Sitting, Female_Clapping, Female_Punch… |
| Character_Animated (12 clip, in Godot compaiono doppie: con e senza prefisso "CharacterArmature\|") | Idle, Walk, Run, **PickUp** (= prendere i soldi), Punch, RecieveHit, Death |
| Animated_Human (8 clip) | Idle, Walk, Run, **Working**, Punch, Jump, Death |

Mappa gesti → clip: *idle* = Idle/Idle_Neutral · *litigare* = Punch_Left/Right, HitRecieve, Man_Punch · *dirigere il traffico* = Wave, Idle_Gun_Pointing · *passare soldi* = Interact, PickUp.
Per animazioni più ricche c'è già la Universal Animation Library (CC0) in `Animations/` nella root, già retargettata in v0.62.

## 3. Materiali PBR — `res://assets/esterni/materiali/` (Poly Haven, CC0, 2K)
Ogni cartella ha: `*_diff_2k.jpg` (albedo), `*_nor_gl_2k.jpg` (normal, formato OpenGL = giusto per Godot),
`*_rough_2k.jpg`, `*_ao_2k.jpg` (se presente), `*_disp_2k.jpg` (height, per parallax/heightmap).
Per uno `StandardMaterial3D`: albedo_texture=diff, normal_enabled+normal_texture=nor_gl, roughness_texture=rough, ao_enabled+ao_texture=ao; `uv1_triplanar` per le facciate.

| Cartella | Materiali | Uso previsto |
|---|---|---|
| `asfalto/` | asphalt_02 (crepato), asphalt_04 (rovinato, scolorito) | carreggiate |
| `basolato/` | rock_tile_floor (lastre grigie), cobblestone_floor_08 (sanpietrini) | basolato dei vicoli / centro storico |
| `cemento/` | concrete_floor_worn_001, pavement_02 (marciapiede) | marciapiedi, parcheggi |
| `intonaco/` | painted_plaster_wall, plastered_wall (graffiato), concrete_wall_003 (giallo scrostato) | facciate dei palazzi |
| `hdri/` | urban_street_01_2k.hdr, urban_street_01_4k.hdr, urban_courtyard_02_2k.hdr | cielo coperto/grigio: `Environment` → Sky → `PanoramaSkyMaterial.panorama` |

## 4. Decal — `res://assets/esterni/materiali/decals/`
Da ambientCG (CC0), PNG 2K con canale **Opacity** separato: per un nodo `Decal` usare
`texture_albedo` = Color (con alpha preso da Opacity: unirli una volta in un PNG RGBA, oppure usare
`Decal.texture_albedo` + `modulate` e la Opacity come maschera in uno shader), `texture_normal` = NormalGL, `texture_orm` opzionale.
| Cartella | Asset |
|---|---|
| `crepe_asfalto/` | AsphaltDamage001 |
| `macchie_olio_perdite/` | Leaking003, 006, 008, 010A, 012A (colature/macchie su muri e asfalto) |
| `segni_pneumatici/` | TireTracks001 |
| `tombini/` | ManholeCover001, ManholeCover005 |
| `strisce_stradali/` | RoadLines001, 007, 013 (strisce e stalli) |
| `chewing_gum/` | ChewingGum001 |
| `graffiti/` | graffiti_00.png (1024², sfondo scuro) + il .glb originale — **CC-BY 4.0, karlwirbelwind: crediti obbligatori** |
Manifesti: nessun decal CC0 adatto → usare quelli già in `res://assets/manifesti/`.

## 5. Shader — `res://assets/esterni/shader/` (CC0)
| File | Tipo | Come si monta |
|---|---|---|
| `pozzanghere/rain_puddles_ripples_ssr.gdshader` + `fullscreen_mesh.gd` | spatial, post-process | MeshInstance3D figlio della Camera3D con script `fullscreen_mesh.gd` → Material Override = ShaderMaterial. Pozzanghere con increspature della pioggia e riflessi SSR su tutte le superfici orizzontali. **Solo Forward+ (PC)**, sul web si spegne da sola. Adattato a 4.3 (uniform `compatibility_renderer` al posto della macro CURRENT_RENDERER) |
| `vhs_grunge/vhs_scanline_glitch.gdshader` | canvas_item | CanvasLayer → ColorRect Full Rect, mouse_filter Ignore |
| `vhs_grunge/vhs_tape_effect.gdshader` | canvas_item | idem (scanline + rumore + vignetta) |
| `vhs_grunge/chromatic_aberration_vignette.gdshader` | canvas_item | idem |
| `vhs_grunge/film_grain.gdshader` | canvas_item | idem |
| `lente_sporca/dirty_lens.gdshader` | canvas_item | idem; sporco procedurale che si accende sulle luci forti (fari, lampioni) — scritto per il progetto |
Idea: un solo ColorRect alla volta, attivabile da opzioni ("Filtro VHS", "Lente sporca") o in momenti di gioco (sbronza, botte, notte).

## 6. Audio — `res://assets/esterni/audio/` (Freesound CC0, OGG ~192 kbps)
| Cartella | File |
|---|---|
| `scooter/` | 3185_PassingMoped01, 448129_Vespa, 448131_Vespa, 450702_scooters_pass, 484486_Motorbike_Passing_By, 509522_Scooter_drive, 828204_Small_Motorbike_Passing_By |
| `clacson_traffico/` | 182474_car_horn, 457425_alfa_romeo_MiTo_honking, 553150_Car_Horn_Honk_Single_Distant, 706221_very_long_car_horn_in_NYC, 853102_Tram_bell_and_car_horn |
| `monete/` | 327517_Throwing_coins_in_hand, 444257_Coins, 558991_coins_falling, 567478_coindrop_sample, 710831_Glass_of_coins |
| `chiavi/` | 266441_keys_jingling_and_door_opening, 618539_Jingling_of_Keys, 827500_jingling_keys |
| `folla_voci_arrabbiate/` | 130328_Angry_Crowd, 537989_Argument, 727591_Cartoon_Small_Angry_Male_Crowd, 402907_Vietnamese_group_of_women (vociare), 221670_Ich_koennt_kotzen (imprecazione, tedesco) |
Suoni 3D (scooter, clacson) → `AudioStreamPlayer3D`; per i loop di passaggio attivare `loop` nell'Import.
Da collegare a `SoundManager` (autoload già esistente).

## 7. UI — `res://assets/esterni/ui/` (Kenney, CC0)
| Cartella | Contenuto | Utile per |
|---|---|---|
| `kenney_ui_pack/` | PNG e SVG di bottoni, pannelli, barre, slider, checkbox in 5 colori (Blue, Green, Grey, Red, Yellow) + cartella Extra + font `Kenney Future.ttf` / `Kenney Future Narrow.ttf` + 6 suoni click/switch/tap | pannelli HUD, barra "allerta polizia" (barre rosse/gialle), bottoni della contrattazione |
| `kenney_game_icons/` | ~100 icone bianche/nere (PNG 1x/2x + SVG): `warning.png`, `exclamation.png`, `star.png`, `locked/unlocked`… | icona allerta vigili, notifiche |
| `kenney_board_game_icons/` | icone 64/128 px + SVG: **`dollar.png`, `pouch.png`, `pouch_add.png`, `pouch_remove.png`** | contatore soldi, guadagno/perdita |

## 8. Crediti da mettere nella schermata crediti del gioco (CC-BY)
- "Vespa" — Jasmine Roberts, CC-BY 3.0 (poly.pizza/m/blGLclvvdEM)
- "Scooter" — Poly by Google, CC-BY 3.0 (poly.pizza/m/fPLXByG4Vx5)
- "low poly scooter" — Thomas Saint Pierre (s1pierro), CC-BY 3.0 (poly.pizza/m/awXCP7LUcz6)
- "Decal - Graffiti Textures" — karlwirbelwind, CC-BY 4.0 (zenodo.org/records/10234475)
Tutto il resto è CC0 (nessun obbligo, ma è gentile citare Poly Haven, ambientCG, Kenney, Quaternius, Freesound).
