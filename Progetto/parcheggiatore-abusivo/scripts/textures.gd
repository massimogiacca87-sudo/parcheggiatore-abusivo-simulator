extends Node
class_name Textures
## Textures
## Fabbrica centralizzata dei materiali basati sulle texture fotografiche in
## assets/textures/. Ogni materiale è creato una volta sola e riusato
## (importante: decine di muri che condividono lo stesso materiale invece di
## crearne uno per parete).

const DIR := "res://assets/textures/%s.jpg"
const SHADER_PATH := "res://assets/shaders/intonaco.gdshader"

## Quali texture sono "terra" — cioè si bagnano quando piove. Sta qui e non
## sparso per il codice perché bagnarne solo una parte si vede più che non
## bagnarne nessuna.
const TERRE := {"asfalto": true, "basolato": true, "terra": true,
	"sanpietrini": true, "marciapiede": true}

const MURI := ["muro_ocra", "muro_terracotta", "muro_rosa", "muro_crema"]

## Quanto rilievo dare a ciascuna superficie. L'intonaco scrostato e i
## basoli ne vogliono tanto; il metallo delle serrande e la carta dei
## manifesti sono quasi lisci e con troppo bump sembrano stagnola.
const BUMP := {
	"asfalto": 1.7, "maioliche": 1.1,
	"muro_ocra": 1.9, "muro_terracotta": 1.9, "muro_rosa": 1.9,
	"muro_crema": 1.9, "serranda": 0.8, "portone": 1.3, "manifesti": 0.5,
	# 'E graffite so' vernice ncopp'a ll'intonaco: 'o rilievo è chillo d''o
	# muro 'e sotto, no d''a pittura. E 'e tetti so' coppi, e 'e coppi
	# tengono ombra assaje.
	"graffiti": 1.2, "coppi": 1.8, "coppi_x": 1.8,
	# **'O rilievo d''e pavimente steva troppo auto.** Il marciapiede a 2.0
	# e il piperno al valore di scorta (1.4) facevano un chiaroscuro così
	# marcato che il lastricato della piazza sembrava lamiera ondulata. Una
	# lastra di pietra è piatta: il rilievo sta nelle fughe, non sulla
	# faccia.
	"piperno": 0.85, "basolato": 1.15, "marciapiede": 1.25,
}

## **Quanti METRI VERI copre una copia della fotografia.**
##
## È la tabella che mancava, ed è la ragione per cui i palazzi sembravano
## costruiti da giganti. Ogni numero è misurato contando nella foto quello
## che si sa quanto è grande nella vita: un concio di tufo è largo 45 cm e
## alto 30, un basolo di lava sta sui 35, una mattonella di maiolica è 20.
## Si conta quanti ce ne stanno nella fotografia e si moltiplica.
##
## Chi non sta qui dentro prende `METRI_DEFAULT`: un intonaco liscio non ha
## niente da cui capire la scala, e tre metri è la misura di una chiazza.
const METRI_DEFAULT := Vector2(3.0, 3.0)
const METRI := {
	# Murature: si contano i corsi.
	# Conci di tufo giallo: 60 cm larghi, 41 alti. La prima misura (45x30) era
	# quella di un mattone, e a quella scala il muro diventava una reticella.
	"muro_tufo": Vector2(2.4, 2.9),
	"piperno": Vector2(3.0, 2.1),            # lastre 75 x 42 cm
	"muro_umbertino": Vector2(2.4, 2.4),     # bugnato, fasce da 40 cm
	# **L'intonaco scrustato vò 'na piastrella granne.** Nella foto c'è UNA
	# scrostatura sola, grossa: a due metri e mezzo tornava ogni due metri e
	# mezzo e il muro diventava un motivo geometrico. A quattro e mezzo la
	# chiazza ha la misura di una chiazza vera e i mattoni che si vedono
	# sotto restano larghi trenta centimetri, che è la misura loro.
	"muro_scrostato": Vector2(4.5, 4.5),
	"muro_liberty": Vector2(2.6, 2.6),
	"muro_liberty_verde": Vector2(2.6, 2.6),
	"muro_zona_nuova": Vector2(1.5, 1.5),    # rivestimento a piastrelle 20 cm
	# L'intonaco con la muffa (0.62): la foto di Poly Haven copre due metri
	# e mezzo; a tre le chiazze d'umido hanno la misura di quelle vere.
	"muro_muffa": Vector2(3.0, 3.0),
	# **'A serranda pure essa.** Era mappata sulla UV con un 1.4 fisso: su
	# una vetrina larga sei metri le costole venivano larghe venticinque
	# centimetri, cioè una saracinesca da capannone industriale. Sono otto
	# centimetri, e la fotografia ne ha una trentina.
	"serranda": Vector2(2.4, 2.4),
	# Suoli.
	"basolato": Vector2(1.8, 1.8),           # basoli di lava da 35 cm
	"marciapiede": Vector2(2.0, 2.0),        # lastre da 40 cm
	"maioliche": Vector2(1.2, 1.2),          # mattonelle da 20 cm
	"asfalto": Vector2(2.5, 2.5),
	# Coperture.
	"cotto": Vector2(2.0, 2.0),
	# 'E coppi (0.60): otto coppie coppo + canale e cinque file su 2,2 m,
	# disegnati da `tools/genera_coppi.py`. Fino alla 0.59 qui c'era
	# `tetti_italiani`, che era un collage di foto aeree di Venezia.
	"coppi": Vector2(2.2, 2.2),
	"coppi_x": Vector2(2.2, 2.2),
	# Il resto.
	"graffiti": Vector2(3.0, 3.0),
	"manifesti": Vector2(2.2, 2.2),
}

## **'E ffotografie ca nun se ponno ripetere.**
##
## Due texture del lotto non sono muri: sono *oggetti* fotografati. In
## `muro_centro_antico` c'è una FINESTRA, in `muro_porto` c'è un PORTONE di
## lamiera con i cardini. Ripetute su una facciata diventano una griglia di
## finestre finte sotto alle finestre vere, e una parete fatta di portoni.
## Restano nella cartella perché servono ancora — ma come pezzo singolo, mai
## come intonaco. Chi le chiede per un muro riceve l'intonaco di scorta.
const NON_RIPETIBILI := {
	"muro_centro_antico": "muro_scrostato",
	"muro_porto": "muro_travertino",
}

## Quanto sporcare a macchie larghe, per superficie.
##
## Serve a rompere la griglia della ripetizione. Un intonaco vero è chiazzato
## e ne vuole tanto; il basolato e i coppi sono già pieni di variazione loro e
## ne vogliono poco, se no diventano una moquette macchiata.
const VARIAZIONE := {
	"muro_scrostato": 0.26, "muro_ocra": 0.22, "muro_terracotta": 0.22,
	"muro_rosa": 0.22, "muro_crema": 0.20, "muro_travertino": 0.16,
	"muro_posillipo": 0.16, "muro_tufo": 0.24, "muro_umbertino": 0.14,
	"muro_liberty": 0.12, "muro_liberty_verde": 0.12, "muro_zona_nuova": 0.14,
	"muro_muffa": 0.18,
	"piperno": 0.14, "basolato": 0.12, "marciapiede": 0.13,
	"asfalto": 0.14, "maioliche": 0.07, "coppi": 0.10, "coppi_x": 0.10,
	"serranda": 0.09,
	"cotto": 0.12, "manifesti": 0.10, "graffiti": 0.10,
}

## **'E materiale overe** (0.62, asset esterni — vedi ASSET-ESTERNI.md).
##
## Due superfici hanno la fotografia completa di Poly Haven: colore,
## normale e ruvidezza misurati, invece del rilievo ricavato dalla
## luminanza. Le copie da gioco (1024 px) le fa `tools/prepara_esterni.py`
## dagli originali 2K in `assets/esterni/materiali/`.
##
## * `asfalto` — asphalt_02: asfalto consumato con le crepe. Sostituisce la
##   foto vecchia (384 px, a chiazze nere) su tutte le strade larghe, le
##   piazze e il lungomare, perché tutti passano da `mondo("asfalto")`.
## * `muro_muffa` — concrete_wall_003: intonaco bianco-giallo mangiato
##   dall'umido. Entra fra i muri della Sanità, che è il quartiere dei
##   bassi e dell'acqua che sale dai muri.
##
## La misura resta quella di `METRI` (i metri veri che copre una copia).
const PBR := {
	"asfalto": {
		"albedo": "res://assets/textures/pbr/asfalto_albedo.jpg",
		"normale": "res://assets/textures/pbr/asfalto_normale.jpg",
		"ruvidezza": "res://assets/textures/pbr/asfalto_ruvidezza.jpg",
		"forza": 1.0,
		# La tinta da suolo: `TERRA` scurisce di due terzi, ed era fatta per
		# la foto vecchia, che aveva chiazze chiare dappertutto. Questa è
		# grigia uniforme e con `TERRA` veniva catrame fresco; l'asfalto di
		# Napoli è consumato e sbiadito (albedo vero intorno a 0,12).
		"terra": Color(0.90, 0.87, 0.82),
	},
	"muro_muffa": {
		"albedo": "res://assets/textures/pbr/muffa_albedo.jpg",
		"normale": "res://assets/textures/pbr/muffa_normale.jpg",
		"ruvidezza": "res://assets/textures/pbr/muffa_ruvidezza.jpg",
		"forza": 1.2,
	},
}

static var _cache: Dictionary = {}
static var _shader: Shader = null


## Quanti metri copre la foto di questa superficie.
static func metri_di(nome: String) -> Vector2:
	return METRI.get(nome, METRI_DEFAULT)


## Materiale con texture ripetuta. uv_scale = quante volte si ripete.
##
## Non è più un StandardMaterial3D: è lo shader `intonaco`, che si ricava il
## rilievo dalla luminanza della fotografia. Il tipo di ritorno è Material
## perché chi lo usa lo assegna e basta.
static func get_material(tex_name: String, uv_scale: Vector2 = Vector2.ONE,
		roughness: float = 0.92, tint: Color = Color.WHITE) -> Material:
	var key := "%s|%s|%.2f|%s" % [tex_name, uv_scale, roughness, tint]
	if _cache.has(key):
		return _cache[key]

	var path := DIR % tex_name
	if not ResourceLoader.exists(path):
		# Fallback: se la texture manca il gioco resta giocabile, solo più
		# spoglio (grigio pietra invece di bianco accecante).
		var plain := StandardMaterial3D.new()
		plain.albedo_color = Color(0.6, 0.55, 0.5) * tint
		plain.roughness = roughness
		_cache[key] = plain
		return plain

	if _shader == null and ResourceLoader.exists(SHADER_PATH):
		_shader = load(SHADER_PATH)
	if _shader == null:
		var plain2 := StandardMaterial3D.new()
		plain2.albedo_texture = load(path)
		plain2.uv1_scale = Vector3(uv_scale.x, uv_scale.y, 1.0)
		plain2.albedo_color = tint
		plain2.roughness = roughness
		_cache[key] = plain2
		return plain2

	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("albedo_tex", load(path))
	mat.set_shader_parameter("uv_scale", uv_scale)
	mat.set_shader_parameter("tint", tint)
	mat.set_shader_parameter("roughness_base", roughness)
	mat.set_shader_parameter("bump_strength", float(BUMP.get(tex_name, 1.4)))
	_cache[key] = mat
	return mat


## **'O materiale d''e superficie granne: mure, suole, tetti.**
##
## La misura non dipende più dalla mesh: la fotografia si appoggia alle
## coordinate del mondo e copre sempre gli stessi metri veri. Un muro largo
## sei metri e uno largo venti hanno i conci della stessa misura, ed è la
## cosa che prima non era vera.
##
## Chi chiama non passa più nessuna "quante volte ripetere": quel numero era
## la fonte di tutti gli errori di scala, perché per saperlo bisognava sapere
## com'è fatta la UV della mesh — e per le scatole di Godot non è come
## sembra (ogni faccia ne piglia un terzo, non tutto).
static func mondo(tex_name: String, tint: Color = Color.WHITE,
		roughness: float = 0.95, fattore: float = 1.0) -> Material:
	var nome: String = str(NON_RIPETIBILI.get(tex_name, tex_name))
	var m: Vector2 = metri_di(nome) * maxf(0.05, fattore)
	var key := "mondo|%s|%.2f|%s|%s" % [nome, roughness, tint, m]
	if _cache.has(key):
		return _cache[key]
	var path := DIR % nome
	var pbr: Dictionary = PBR.get(nome, {})
	if not pbr.is_empty() and ResourceLoader.exists(str(pbr["albedo"])):
		path = str(pbr["albedo"])
	else:
		pbr = {}
	if not ResourceLoader.exists(path):
		var plain := StandardMaterial3D.new()
		plain.albedo_color = Color(0.6, 0.55, 0.5) * tint
		plain.roughness = roughness
		_cache[key] = plain
		return plain
	if _shader == null and ResourceLoader.exists(SHADER_PATH):
		_shader = load(SHADER_PATH)
	if _shader == null:
		return get_material(nome, Vector2.ONE, roughness, tint)
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("albedo_tex", load(path))
	mat.set_shader_parameter("mappa_mondo", true)
	mat.set_shader_parameter("metri", m)
	mat.set_shader_parameter("tint", tint)
	mat.set_shader_parameter("roughness_base", roughness)
	mat.set_shader_parameter("bump_strength", float(BUMP.get(nome, 1.4)))
	mat.set_shader_parameter("variazione", float(VARIAZIONE.get(nome, 0.16)))
	if not pbr.is_empty():
		mat.set_shader_parameter("mappe_vere", true)
		mat.set_shader_parameter("normal_tex", load(str(pbr["normale"])))
		mat.set_shader_parameter("rough_tex", load(str(pbr["ruvidezza"])))
		mat.set_shader_parameter("normale_forza", float(pbr["forza"]))
	_cache[key] = mat
	# **E si è 'nu selciato, trase dint'ô registro.** Il basolato dei
	# vicoli non passa da `ground()` ma da qui: senza questa riga, con la
	# pioggia luccicava l'asfalto e i vicoli restavano asciutti — che si
	# vede molto più di tutto asciutto.
	if TERRE.has(nome):
		_segna_terra(mat)
	return mat


## Materiale a tinta unita condiviso. Serve a NON creare un materiale nuovo
## per ogni singola finestra, persiana, bandierina o panno steso: la piazza
## ha oltre mille mesh e un materiale ciascuno significa migliaia di risorse
## e altrettante draw call — su GPU integrate e soprattutto nel browser è la
## strada più breve per esaurire la memoria e far chiudere il gioco.
static func flat(color: Color, roughness: float = 0.9, metallic: float = 0.0,
		emission: float = 0.0) -> StandardMaterial3D:
	var key := "flat|%s|%.2f|%.2f|%.2f" % [color, roughness, metallic, emission]
	if _cache.has(key):
		return _cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	if emission > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission
	_cache[key] = mat
	return mat


## Svuota la cache: da chiamare quando si cambia scena, così i materiali
## della zona precedente non restano in memoria per sempre.
static func clear_cache() -> void:
	_cache.clear()


## Il materiale di un palazzo: la texture copre l'intera facciata una sola
## volta in altezza (così la fascia di umidità resta in basso, dov'è giusta)
## e si ripete in orizzontale in base alla larghezza.
static func facade(index: int, width_m: float, tint: Color = Color.WHITE) -> Material:
	var _l := width_m       # non serve più: la scala viene dal mondo
	return mondo(MURI[index % MURI.size()], tint, 0.95)


## Come `facade`, ma la texture si ripete anche in ALTEZZA.
##
## `facade` faceva coprire tutta la facciata da una piastrella sola in
## verticale: con i palazzi da undici metri della vecchia piazza reggeva,
## coi sedici-venti metri dei vicoli nuovi la fotografia dell'intonaco si
## spalmava in strisce verticali e il muro sembrava sfocato. Qui una
## piastrella copre circa sei metri per cinque e mezzo, che e' piu' o meno
## la scala vera di un intonaco.
static func facciata(tex_name: String, width_m: float, height_m: float,
		tint: Color = Color.WHITE) -> Material:
	# **'A misura mo vene d''o munno, no d''a mesh.**
	#
	# Quello che c'era scritto qui sotto — 2,6 metri per piastrella — era
	# giusto come intenzione e sbagliato come risultato, perché la UV di una
	# `BoxMesh` non va da 0 a 1 per faccia: le sei facce stanno in un
	# atlante e ognuna ne piglia un terzo in larghezza e la metà in altezza.
	# Il numero 2,6 diventava quindi 7,8 metri in orizzontale e 5,2 in
	# verticale, e un concio di tufo usciva largo quasi due metri. Era
	# esattamente il "mattoni grandi quanto un'auto".
	#
	# Adesso la fotografia si appoggia alle coordinate del mondo e i due
	# parametri di misura non servono più. Restano nella firma perché li
	# passano quaranta chiamate e toglierli non aggiungerebbe niente.
	var _w := width_m
	var _h := height_m
	return mondo(tex_name, tint, 0.95)


## La vecchia, tenuta per riferimento di quanto valeva il conto a mano.
static func _facciata_vecchia(tex_name: String, width_m: float,
		height_m: float, tint: Color = Color.WHITE) -> Material:
	# **Una piastrella copre 2,6 m di muro vero.**
	#
	# Prima ne copriva 4,5, ed era la ragione per cui i palazzi sembravano
	# costruiti da giganti: le texture di muratura hanno dentro dei corsi di
	# pietra, e a 4,5 m per piastrella ogni corso veniva alto quasi un
	# metro. Un concio di tufo vero e' alto 40-50 cm, un bugnato umbertino
	# anche meno. A 2,6 m i corsi tornano alla misura giusta e il palazzo
	# torna alto quanto dice di essere.
	#
	# Ripetere di piu' non si vede: sono texture affiancabili, e il prezzo
	# e' solo qualche pixel per metro in piu' (384/2,6 = 148 px/m).
	const METRI_PER_PIASTRELLA := 2.6
	# Il numero di ripetizioni si arrotonda a un intero, se no la piastrella
	# si taglia a meta' sul bordo della campata. E si limita: la chiave del
	# materiale contiene rx e ry, e senza tetto ogni palazzo si porterebbe
	# dietro un materiale suo, con cui il MultiMesh non puo' raggruppare
	# piu' niente.
	var rx: float = clampf(roundf(width_m / METRI_PER_PIASTRELLA), 1.0, 6.0)
	var ry: float = clampf(roundf(height_m / METRI_PER_PIASTRELLA), 1.0, 8.0)
	return get_material(tex_name, Vector2(rx, ry), 0.95, tint)


## **Perché il suolo è tinto molto più scuro e più caldo della sua foto.**
##
## Il basolato di Napoli è pietra lavica: quasi nera, appena azzurrina dove
## il passo l'ha lucidata. La fotografia in `basolato.jpg` ha invece una
## luminanza media di 0,41 e misura più blu che rosso, perché è stata scattata
## sotto un cielo aperto. Messa in gioco a tinta piena, sotto un sole a 1,15
## di energia e con l'ambiente preso dal cielo (che è azzurro), usciva grigio
## chiaro tendente al celeste: le strade sembravano ghiacciate e le ombre
## erano blu di neve.
##
## Due correzioni in una costante sola:
##
##   * **si scurisce di due terzi** — 0,68 in sRGB è 0,42 in lineare, e la
##     foto per quello fa un albedo intorno a 0,17, che è la pietra vera;
##   * **si sposta verso il caldo** — il rapporto rosso/blu qui è 1,21.
##
## Attenzione al secondo: l'uniform `tint` dello shader è dichiarato
## `source_color`, quindi Godot la converte da sRGB a lineare prima di
## passarla al fragment, cioè la eleva a circa 2,2. Il rapporto 1,21
## diventa 1,49 di fatto — ed è quanto serve per annullare insieme la
## dominante fredda della fotografia e il riverbero azzurro del cielo. (È
## anche il motivo per cui il vecchio moltiplicatore 1,35 valeva in realtà
## 1,9: da lì veniva il bianco.)
const TERRA := Color(0.68, 0.63, 0.56)


static func ground(tex_name: String, size_m: Vector2, meters_per_tile: float) -> Material:
	# Come `facciata`: la misura viene dal mondo. `meters_per_tile` resta
	# come **fattore**, così chi voleva basoli più grandi o più piccoli del
	# normale può ancora dirlo — ma parte dalla misura vera, non da zero.
	var _s := size_m
	var f: float = meters_per_tile / maxf(0.05, metri_di(tex_name).x)
	var tinta: Color = TERRA
	if PBR.has(tex_name) and (PBR[tex_name] as Dictionary).has("terra"):
		tinta = PBR[tex_name]["terra"]
	var m: Material = mondo(tex_name, tinta, 0.95, clampf(f, 0.5, 2.0))
	_segna_terra(m)
	return m


# ---------------------------------------------------------------------------
# 'O selciato ca luceca
# ---------------------------------------------------------------------------
#
# **Chesta steva 'n sospeso 'a duje versione, e 'o mutivo è 'nteressante.**
#
# Alla 0.53 la pioggia si vede: il cielo si chiude, le gocce cadono, gli
# schizzi rimbalzano. Ma l'asfalto resta opaco identico a un giorno di
# sole, e nelle note ho scritto due volte *"va fatto su tutti i pezzi di
# strada insieme, e sono materiali sparsi in quattro file"*.
#
# Sparsi lo erano nelle **chiamate** — `citta_3d` ne fa sei, `zone_vicolo`
# due, la fontana una — ma non nei materiali: passano tutte da `mondo()`,
# che tiene una cache. Cioè i materiali del terreno in tutta la città sono
# **una manciata di oggetti condivisi**, e per bagnarli tutti basta tenerne
# la lista e toccare due parametri.
#
# Il lavoro vero era accorgersene, e mi è costato due versioni di rimando
# per una cosa da venti righe. La morale sta nelle note della build.
#
# Cosa cambia: la rugosità scende (un selciato bagnato riflette) e lo
# speculare sale. Non si aggiunge nessuna mesh, nessuna trasparenza e
# nessun costo — sono due `set_shader_parameter` su cinque materiali.

## Quanto diventa liscio il terreno con l'acqua. Zero e' lo specchio.
const BAGNATO_ROUGH: float = 0.34
## E quanto riflette.
const BAGNATO_SPEC: float = 0.62

## **E 'o culore, ca è 'a cosa ca se vede overo.**
##
## Il primo giro toccava solo rugosità e speculare, ed era giusto in
## teoria: un selciato bagnato è liscio e riflette. In pratica la foto di
## confronto ha dato **differenza zero virgola cinque su
## duecentocinquantacinque**, cioè niente — perché sotto un cielo coperto
## un riflesso speculare non ha niente da riflettere: la luce non viene da
## un punto, viene da tutto il cielo, e non c'è nessun lobo che torna
## verso l'occhio.
##
## La cosa che si vede sempre, con qualsiasi luce, è che **l'asfalto
## bagnato è più scuro**. L'acqua riempie i pori e la superficie smette di
## diffondere: è la ragione per cui una strada bagnata si riconosce da
## lontano in una fotografia in bianco e nero.
##
## Quindi tutte e tre: più scuro (si vede sempre), più liscio e più
## speculare (si vedono quando la luce è di taglio, e allora luccica
## davvero).
const BAGNATO_SCURO: float = 0.30

static var _terre: Array = []
## Il colore che il materiale aveva da asciutto: serve per tornarci.
static var _tinte: Dictionary = {}
static var _bagnato: float = -1.0


static func _segna_terra(m: Material) -> void:
	if m == null or _terre.has(m):
		return
	_terre.append(m)
	if m is ShaderMaterial:
		var t = (m as ShaderMaterial).get_shader_parameter("tint")
		_tinte[m] = Color(t) if t != null else Color.WHITE
	# Chi nasce a giornata gia' cominciata deve trovarla come gli altri:
	# se no il pezzo di strada costruito dopo l'inizio della pioggia resta
	# asciutto in mezzo a tutto il resto bagnato.
	if _bagnato > 0.0:
		_applica_acqua(m, _bagnato)


static func _applica_acqua(m: Material, quanto: float) -> void:
	if not (m is ShaderMaterial):
		return
	var sm := m as ShaderMaterial
	var asciutto: float = 0.95
	sm.set_shader_parameter("roughness_base",
		lerpf(asciutto, BAGNATO_ROUGH, quanto))
	sm.set_shader_parameter("specular_amount", lerpf(0.16, BAGNATO_SPEC, quanto))
	var base: Color = _tinte.get(m, Color.WHITE)
	sm.set_shader_parameter("tint", base.darkened(BAGNATO_SCURO * quanto))


## **Bagna tutto 'o selciato d''a città 'nzieme.** `quanto` va da 0
## (asciutto) a 1 (fradicio). La chiama il ciclo giorno/notte.
static func bagna(quanto: float) -> void:
	quanto = clampf(quanto, 0.0, 1.0)
	if is_equal_approx(quanto, _bagnato):
		return
	_bagnato = quanto
	for m in _terre:
		_applica_acqua(m, quanto)
