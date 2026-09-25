extends Control
## 'E stelle 'e ricercato, disegnate a mano.
##
## Cinque poligoni a cinque punte. Quelle "accese" sono piene e dorate,
## quelle spente sono un contorno scuro appena visibile: si legge quante ne
## hai anche con la coda dell'occhio, che è tutto quello che serve mentre
## stai scappando.

const RAGGIO: float = 13.0
const PASSO: float = 32.0

var quante: int = 0
var _lampo: float = 0.0


func _process(delta: float) -> void:
	if _lampo > 0.0:
		_lampo = maxf(0.0, _lampo - delta * 2.2)
		queue_redraw()


## Un guizzo quando il numero cambia: se no una stella in più fra le altre
## non si nota, e la stella in più è proprio l'informazione.
func lampeggia() -> void:
	_lampo = 1.0
	queue_redraw()


func _punti(c: Vector2, r: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in range(10):
		var raggio: float = r if i % 2 == 0 else r * 0.44
		var a: float = -PI / 2.0 + PI * float(i) / 5.0
		p.append(c + Vector2(cos(a), sin(a)) * raggio)
	return p


func _draw() -> void:
	for i in range(GameManager.STELLE_MAX):
		var c := Vector2(float(i) * PASSO + RAGGIO + 2.0, RAGGIO + 4.0)
		var accesa: bool = i < quante
		var r: float = RAGGIO
		if accesa and i == quante - 1:
			r += RAGGIO * 0.28 * _lampo
		var pt := _punti(c, r)
		if accesa:
			draw_colored_polygon(pt, Color(1.0, 0.82, 0.22))
			draw_polyline(pt + PackedVector2Array([pt[0]]),
				Color(0.25, 0.15, 0.02), 2.0)
		else:
			draw_polyline(pt + PackedVector2Array([pt[0]]),
				Color(0.55, 0.52, 0.48, 0.45), 1.5)
