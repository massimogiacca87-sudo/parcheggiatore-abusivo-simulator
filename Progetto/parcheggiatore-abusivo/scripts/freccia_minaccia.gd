extends Control
## 'A freccia d''a minaccia
##
## Un cuneo rosso che gira attorno al mirino e dice da che parte ti stanno
## menando. Serve perché in prima persona quello che hai dietro non esiste:
## una botta alle spalle è solo un lampo rosso a schermo, e uno si gira a
## caso — di solito dalla parte sbagliata.
##
## Sta a centoventi pixel dal centro, quindi non copre il mirino e non
## copre nemmeno il bersaglio che stai guardando. Sfuma da sola in un paio
## di secondi: se la minaccia è ancora lì, arriva un'altra botta e la
## freccia si riaccende.

## Quanto dura, e quanto sta lontana dal centro dello schermo.
const DURATA: float = 2.2
const RAGGIO: float = 120.0

var _angolo: float = 0.0
var _vita: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


## `angolo` in radianti: 0 = davanti, +π/2 = a destra, π = alle spalle.
func punta(angolo: float) -> void:
	_angolo = angolo
	_vita = DURATA
	queue_redraw()


func _process(delta: float) -> void:
	if _vita <= 0.0:
		return
	_vita -= delta
	queue_redraw()


func _draw() -> void:
	if _vita <= 0.0:
		return
	# Trasparenza: piena per il primo terzo, poi svanisce. Una freccia che
	# comincia già a sparire non si fa in tempo a leggerla.
	var a: float = clampf(_vita / (DURATA * 0.4), 0.0, 1.0)
	var centro := Vector2(RAGGIO, 0.0).rotated(_angolo - PI / 2.0)
	# Il cuneo: punta verso l'esterno, cioè verso la minaccia.
	var fuori: Vector2 = centro.normalized()
	var lato := Vector2(-fuori.y, fuori.x)
	var punte := PackedVector2Array([
		centro + fuori * 26.0,
		centro - fuori * 8.0 + lato * 19.0,
		centro - fuori * 8.0 - lato * 19.0,
	])
	# Prima il bordo nero, poi il rosso: sopra a un muro chiaro o al cielo
	# una freccia rossa piena si perde.
	var bordo := PackedVector2Array()
	for p in punte:
		bordo.append(centro + (p - centro) * 1.28)
	draw_colored_polygon(bordo, Color(0, 0, 0, 0.55 * a))
	draw_colored_polygon(punte, Color(0.92, 0.14, 0.12, 0.92 * a))
