extends RefCounted
class_name Carte
## Le quaranta carte napoletane, ritagliate da un foglio unico.
##
## `tools/carte.py` prende la scansione del mazzo e ne fa un atlante 10x4:
## dieci colonne (asso ... sette, fante, cavallo, re) e quattro righe
## (coppe, denari, bastoni, spade). Qui dentro c'è solo il modo di puntare a
## una cella di quell'atlante.
##
## ## Perché un atlante e non quaranta texture
##
## Il ventaglio del gioco delle tre carte, la mano dei vecchi che giocano a
## scopa e il mazzo sul tavolino sono decine di quadretti a schermo insieme.
## Con quaranta texture separate sarebbero decine di materiali diversi, cioè
## decine di cambi di stato della GPU per disegnare dei rettangoli da mezzo
## metro. Con l'atlante il materiale è **uno**: cambia solo `uv1_offset`.
##
## L'unica cosa da sapere usandolo: i materiali sono in cache e **condivisi**.
## Se ne modifichi uno lo modifichi per tutte le carte di quel numero che
## stanno a schermo. Se ti serve cambiarne il colore (una carta evidenziata,
## una che sfuma), fattene una copia con `duplicate()`.

const ATLANTE := "res://assets/textures/carte_napoletane.jpg"
const RETRO_TINTA := Color(0.72, 0.16, 0.15)

const COLONNE: int = 10
const RIGHE: int = 4

## Le proporzioni della carta vera, in metri. Una carta napoletana è
## 6,3 x 10,2 cm; qui è leggermente più grande perché in un gioco in prima
## persona una carta a grandezza reale su un tavolino non si legge.
const LARGHEZZA: float = 0.085
const ALTEZZA: float = 0.138

const SEMI := ["coppe", "denari", "bastoni", "spade"]
const VALORI := ["asso", "due", "tre", "quattro", "cinque", "sei", "sette",
	"fante", "cavallo", "re"]

static var _cache: Dictionary = {}
static var _retro: StandardMaterial3D = null


## Il materiale della carta `i` (0..39), pronto da mettere su un QuadMesh.
## L'indice è riga * 10 + colonna, cioè seme * 10 + (valore - 1).
static func materiale(i: int) -> StandardMaterial3D:
	i = posmod(i, COLONNE * RIGHE)
	if _cache.has(i):
		return _cache[i]
	var m := StandardMaterial3D.new()
	if ResourceLoader.exists(ATLANTE):
		m.albedo_texture = load(ATLANTE)
	else:
		m.albedo_color = Color(0.94, 0.92, 0.86)
	# La finestra dell'atlante: un decimo in larghezza, un quarto in altezza.
	m.uv1_scale = Vector3(1.0 / COLONNE, 1.0 / RIGHE, 1.0)
	m.uv1_offset = Vector3(float(i % COLONNE) / COLONNE,
		float(i / COLONNE) / RIGHE, 0.0)
	# Senza questo il bordo di una cella pesca dalla cella accanto: si vede
	# una striscia della carta vicina lungo il lato.
	m.texture_repeat = false
	m.roughness = 0.82
	m.metallic = 0.0
	# Le carte si vedono anche di taglio quando uno le tiene in mano, e un
	# QuadMesh ha una faccia sola: senza il doppio lato spariscono.
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cache[i] = m
	return m


## Il dorso. Nel mazzo napoletano è a fantasia, ma quello che conta a
## distanza di gioco è che sia UNIFORME e diverso dalla faccia: se il dorso
## avesse un dettaglio riconoscibile, il gioco delle tre carte si vincerebbe
## guardando il dorso invece di seguire la mano.
static func retro() -> StandardMaterial3D:
	if _retro != null:
		return _retro
	_retro = StandardMaterial3D.new()
	_retro.albedo_color = RETRO_TINTA
	_retro.roughness = 0.84
	_retro.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _retro


static func indice(seme: int, valore: int) -> int:
	return posmod(seme, RIGHE) * COLONNE + posmod(valore - 1, COLONNE)


static func nome(i: int) -> String:
	i = posmod(i, COLONNE * RIGHE)
	return "%s 'e %s" % [VALORI[i % COLONNE], SEMI[i / COLONNE]]


## **La stessa cella dell'atlante, ma per l'interfaccia 2D.**
##
## Il tavolo della scopa vera si gioca a schermo, non nel mondo: serve una
## Texture da mettere dentro a un TextureRect, non un materiale. È lo
## stesso ritaglio — `AtlasTexture` fa in 2D quello che `uv1_offset` fa in
## 3D — e le due strade leggono lo stesso file, così le carte in mano al
## giocatore e quelle sul tavolino dei vecchi sono identiche.
static var _cache2d: Dictionary = {}


static func texture(i: int) -> Texture2D:
	i = posmod(i, COLONNE * RIGHE)
	if _cache2d.has(i):
		return _cache2d[i]
	if not ResourceLoader.exists(ATLANTE):
		return null
	var base: Texture2D = load(ATLANTE)
	var w: float = float(base.get_width()) / float(COLONNE)
	var h: float = float(base.get_height()) / float(RIGHE)
	var a := AtlasTexture.new()
	a.atlas = base
	# Mezzo pixel dentro su ogni lato: senza, il filtro pesca dalla cella
	# accanto e si vede una riga della carta vicina lungo il bordo.
	a.region = Rect2(float(i % COLONNE) * w + 0.5, float(i / COLONNE) * h + 0.5,
		w - 1.0, h - 1.0)
	_cache2d[i] = a
	return a


## Un QuadMesh già delle proporzioni giuste, da usare per ogni carta.
static func mesh(scala: float = 1.0) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(LARGHEZZA * scala, ALTEZZA * scala)
	return q


# ---------------------------------------------------------------------------
# 'E ccarte grosse (0.62)
# ---------------------------------------------------------------------------
#
# Per i pannelli a schermo (la scopa): l'atlante in alta definizione fatto
# da `tools/carte_hd.py` (celle 240x390, angoli tondi trasparenti) e il
# dorso disegnato. L'atlante piccolo resta per il 3D, dove basta e avanza.

const ATLANTE_HD := "res://assets/ui/carte_hd.png"
const RETRO_HD := "res://assets/ui/carta_retro.png"

static var _cache_hd: Dictionary = {}


static func texture_hd(i: int) -> Texture2D:
	i = posmod(i, COLONNE * RIGHE)
	if _cache_hd.has(i):
		return _cache_hd[i]
	if not ResourceLoader.exists(ATLANTE_HD):
		return texture(i)
	var base: Texture2D = load(ATLANTE_HD)
	var w: float = float(base.get_width()) / float(COLONNE)
	var h: float = float(base.get_height()) / float(RIGHE)
	var a := AtlasTexture.new()
	a.atlas = base
	a.region = Rect2(float(i % COLONNE) * w, float(i / COLONNE) * h, w, h)
	a.filter_clip = true
	_cache_hd[i] = a
	return a


static func retro_hd() -> Texture2D:
	if ResourceLoader.exists(RETRO_HD):
		return load(RETRO_HD)
	return null
