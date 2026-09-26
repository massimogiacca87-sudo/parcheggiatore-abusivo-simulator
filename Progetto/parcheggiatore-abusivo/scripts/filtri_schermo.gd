extends CanvasLayer

## **'E filtre d''o schermo** (0.62, asset esterni).
##
## Gli shader "a schermo intero" della biblioteca esterna (VHS, grana da
## film, aberrazione cromatica, lente sporca — tutti CC0 da godotshaders,
## più la lente sporca scritta apposta) entrano in gioco in due modi:
##
## * **un filtro a scelta** nel menu di pausa (Nisciuno, Pellicola,
##   Videocassetta, Lente sporca), che si ricorda fra una partita e l'altra
##   in `user://filtro.cfg` — è una preferenza di chi gioca, come il volume;
## * **'a botta**: quando il giocatore prende un colpo, per mezzo secondo i
##   colori si separano verso i bordi e il margine si arrossa. Sta sempre
##   accesa (è un segnale, non un gusto), e dura poco.
##
## Sta sul livello 5: sotto all'HUD (10) e a tutti i pannelli, quindi
## sporca il mondo e non le scritte. Le copie da gioco degli shader stanno
## in `assets/shaders/filtri/` (quelle originali, fuori dall'esportazione,
## in `assets/esterni/shader/`).

const FILTRI := ["nisciuno", "pellicola", "videocassetta", "lente_sporca"]
const NOMI := {
	"nisciuno": "Nisciuno", "pellicola": "Pellicola",
	"videocassetta": "Videocassetta", "lente_sporca": "Lente sporca",
}
const SHADER := {
	"pellicola": "res://assets/shaders/filtri/pellicola.gdshader",
	"videocassetta": "res://assets/shaders/filtri/videocassetta.gdshader",
	"lente_sporca": "res://assets/shaders/filtri/lente_sporca.gdshader",
}
const SHADER_BOTTA := "res://assets/shaders/filtri/botta.gdshader"
const CFG := "user://filtro.cfg"
## Quanto dura la botta (secondi per scendere da 1 a 0).
const BOTTA_DURATA: float = 0.55

var scelto: String = "nisciuno"
var _rect: ColorRect = null
var _botta: ColorRect = null
var _botta_mat: ShaderMaterial = null
var _forza: float = 0.0


func _ready() -> void:
	layer = 5
	add_to_group("filtri_schermo")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = _schermo()
	add_child(_rect)
	_botta = _schermo()
	if ResourceLoader.exists(SHADER_BOTTA):
		_botta_mat = ShaderMaterial.new()
		_botta_mat.shader = load(SHADER_BOTTA)
		_botta.material = _botta_mat
	_botta.visible = false
	add_child(_botta)
	carica()
	applica()
	if not GameManager.player_hurt.is_connected(_su_botta):
		GameManager.player_hurt.connect(_su_botta)


func _schermo() -> ColorRect:
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.color = Color(1, 1, 1, 1)
	return r


## Mette il filtro scelto (o lo toglie).
func applica() -> void:
	if _rect == null:
		return
	if not SHADER.has(scelto) or not ResourceLoader.exists(str(SHADER[scelto])):
		_rect.visible = false
		_rect.material = null
		return
	var m := ShaderMaterial.new()
	m.shader = load(str(SHADER[scelto]))
	_rect.material = m
	_rect.visible = true


## Il filtro dopo (lo chiama il bottone del menu di pausa). Torna il nome
## da scrivere sul bottone.
func prossimo() -> String:
	var i: int = FILTRI.find(scelto)
	scelto = str(FILTRI[(i + 1) % FILTRI.size()])
	applica()
	salva()
	return nome()


func nome() -> String:
	return str(NOMI.get(scelto, "Nisciuno"))


func salva() -> void:
	var f := FileAccess.open(CFG, FileAccess.WRITE)
	if f != null:
		f.store_string(scelto)


func carica() -> void:
	if not FileAccess.file_exists(CFG):
		return
	var f := FileAccess.open(CFG, FileAccess.READ)
	if f == null:
		return
	var s: String = f.get_as_text().strip_edges()
	if FILTRI.has(s):
		scelto = s


## Un colpo preso: più forte è il colpo, più si vede (ma sempre poco).
func _su_botta(quanto: float, _causa: String = "") -> void:
	_forza = clampf(maxf(_forza, 0.45 + quanto / 25.0), 0.0, 1.0)


func _process(delta: float) -> void:
	if _botta_mat == null:
		return
	if _forza <= 0.0:
		if _botta.visible:
			_botta.visible = false
		return
	_forza = maxf(0.0, _forza - delta / BOTTA_DURATA)
	_botta.visible = _forza > 0.0
	_botta_mat.set_shader_parameter("forza", _forza)
