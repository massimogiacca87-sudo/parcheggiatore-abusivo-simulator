extends Node
class_name Icone
## Icone
## Le figurine degli oggetti, caricate una volta sola e riusate.
##
## Prima lo zaino e le vetrine erano liste di testo: righe tutte uguali in
## cui bisognava leggere per capire cosa stavi comprando. Con una figura per
## oggetto si riconosce a colpo d'occhio, che è come funzionano gli
## inventari da sempre.
##
## I file stanno in assets/icone/ e si chiamano come il campo "icona"
## dell'oggetto in GameManager.UPGRADES. Se un file manca, chi disegna
## riceve null e mette un riquadro vuoto: non si rompe niente.

const DIR := "res://assets/icone/%s.png"

static var _cache: Dictionary = {}


## La figura di un oggetto per id (es. "ombrellone"). Null se non c'è.
static func per_oggetto(id: String) -> Texture2D:
	if not GameManager.UPGRADES.has(id):
		return per_nome(id)
	return per_nome(str(GameManager.UPGRADES[id].get("icona", id)))


## La figura per nome di file, senza passare dal listino degli oggetti
## (serve per il caffè e per le sigarette, che oggetti non sono).
static func per_nome(nome: String) -> Texture2D:
	if nome == "":
		return null
	if _cache.has(nome):
		return _cache[nome]
	var path := DIR % nome
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	_cache[nome] = tex
	return tex


## Costruisce una casella: la figura dentro a un riquadro, con la sua
## cornice. `scelta` la accende, `posseduto` la spegne in grigio.
static func casella(id: String, lato: float, scelta: bool,
		posseduto: bool = true) -> Control:
	var riquadro := Panel.new()
	riquadro.custom_minimum_size = Vector2(lato, lato)
	riquadro.size = Vector2(lato, lato)
	riquadro.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var stile := StyleBoxFlat.new()
	stile.bg_color = Color(0.17, 0.15, 0.19, 0.95) if posseduto \
		else Color(0.11, 0.1, 0.12, 0.9)
	stile.border_color = Color(1.0, 0.83, 0.33) if scelta \
		else Color(0.36, 0.32, 0.28)
	stile.set_border_width_all(3 if scelta else 2)
	stile.set_corner_radius_all(10)
	riquadro.add_theme_stylebox_override("panel", stile)

	var img := TextureRect.new()
	img.texture = per_oggetto(id)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.position = Vector2(lato * 0.1, lato * 0.1)
	img.size = Vector2(lato * 0.8, lato * 0.8)
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Quello che non hai ancora comprato si vede in ombra: capisci che
	# esiste, e capisci che non è tuo.
	img.modulate = Color(1, 1, 1, 1) if posseduto else Color(0.5, 0.5, 0.55, 0.55)
	riquadro.add_child(img)
	return riquadro
