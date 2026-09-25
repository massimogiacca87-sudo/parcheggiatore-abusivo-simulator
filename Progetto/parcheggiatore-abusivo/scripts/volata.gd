extends Node3D
## 'A volata sopra 'a città
##
## L'inquadratura d'apertura: si parte alti sul golfo, si scende piano
## girando sopra ai tetti, e si finisce **esattamente dentro agli occhi del
## parcheggiatore**. Non c'è taglio: l'ultima posizione della camera della
## volata è la prima del gioco, quindi il passaggio non si vede.
##
## **Perché è fatta con una camera sua e non muovendo quella del player.**
## La camera del player è figlia della testa, che è figlia del corpo, che
## sta appoggiato per terra e ha la fisica addosso: muoverla in giro per il
## cielo vorrebbe dire muovere il personaggio, con tutto quello che ne
## consegue (cade, entra nei muri, il HUD si aggiorna). Qui c'è una camera
## staccata che vola per conto suo; quando ha finito, passa il testimone.
##
## Si salta con un tasto qualsiasi: chi rigioca la ventesima volta non se
## la vuole vedere tutta, e un'intro che non si salta è una punizione.

signal finita

## Quanto dura tutto, e come si spezza. La discesa è la parte lunga:
## scendere piano è quello che fa sembrare la città grande.
const DURATA: float = 11.0
const QUOTA_PARTENZA: float = 118.0
const RAGGIO_PARTENZA: float = 132.0

var _camera: Camera3D
var _t: float = 0.0
var _da: Transform3D
var _centro: Vector3
var _arrivo: Callable
var _finito: bool = false


## `centro` è il punto della città da inquadrare dall'alto; `arrivo` è una
## funzione che ritorna il Transform3D finale (gli occhi del player), letta
## ogni frame perché il player nel frattempo può assestarsi a terra.
func avvia(centro: Vector3, arrivo: Callable) -> void:
	# La volata deve girare anche a mondo fermo: e' l'unica cosa che si
	# muove fra il menu e l'inizio del turno.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_centro = centro
	_arrivo = arrivo
	_camera = Camera3D.new()
	_camera.fov = 62.0
	_camera.far = 1400.0
	_camera.current = true
	add_child(_camera)
	# Si parte da sud-est, che è la direzione da cui la città si legge
	# meglio: davanti il quartiere, dietro il golfo.
	var p0 := _centro + Vector3(RAGGIO_PARTENZA * 0.55, QUOTA_PARTENZA,
		RAGGIO_PARTENZA)
	_da = _guarda(p0, _centro + Vector3(0, 6, 0))
	_camera.global_transform = _da
	set_process(true)


## Un Transform3D che sta in `da` e guarda `verso`. `looking_at` di Godot
## fa la stessa cosa ma vuole un Node3D dentro l'albero: qui serve prima.
func _guarda(da: Vector3, verso: Vector3) -> Transform3D:
	var avanti: Vector3 = (verso - da).normalized()
	if absf(avanti.dot(Vector3.UP)) > 0.999:
		avanti = (avanti + Vector3(0.001, 0, 0.001)).normalized()
	var destra: Vector3 = Vector3.UP.cross(avanti).normalized()
	var su: Vector3 = avanti.cross(destra).normalized()
	# La base di Godot ha -Z in avanti.
	return Transform3D(Basis(destra, su, -avanti), da)


func _process(delta: float) -> void:
	if _finito or _camera == null:
		return
	_t += delta
	var k: float = clampf(_t / DURATA, 0.0, 1.0)

	# **Due curve diverse, ed è quello che la fa sembrare girata bene.**
	#
	# La rotazione attorno alla città parte subito e rallenta alla fine
	# (ease-out): l'occhio ha bisogno di movimento nei primi secondi. La
	# discesa fa il contrario, parte lenta e precipita verso la fine
	# (ease-in): così la città resta larga a lungo e l'atterraggio negli
	# occhi del personaggio arriva veloce, come una picchiata.
	var giro: float = 1.0 - pow(1.0 - k, 2.2)
	var scesa: float = pow(k, 2.6)

	var meta: Transform3D = _fine()
	var occhi: Vector3 = meta.origin

	# La posizione: si interpola in coordinate polari attorno al punto
	# d'arrivo, non in linea retta. In linea retta la camera taglierebbe
	# dritto verso il basso e si vedrebbe mezzo palazzo passare davanti.
	var da_piano := Vector2(_da.origin.x - occhi.x, _da.origin.z - occhi.z)
	var raggio: float = lerpf(da_piano.length(), 0.0, scesa)
	var ang: float = da_piano.angle() + deg_to_rad(58.0) * giro
	var quota: float = lerpf(_da.origin.y, occhi.y, scesa)
	var pos := Vector3(occhi.x + cos(ang) * raggio, quota,
		occhi.z + sin(ang) * raggio)

	# Lo sguardo: all'inizio guarda il centro della città, alla fine guarda
	# dove guarderà il player. Si mescolano i due punti, non i due angoli.
	var mira_alta: Vector3 = _centro + Vector3(0, 6, 0)
	var mira_bassa: Vector3 = occhi - meta.basis.z * 22.0
	var mira: Vector3 = mira_alta.lerp(mira_bassa, smoothstep(0.35, 1.0, k))
	_camera.global_transform = _guarda(pos, mira)
	_camera.fov = lerpf(62.0, 80.0, scesa)

	if k >= 1.0:
		_chiudi()


## L'ultimo fotogramma della volata è il primo del gioco: si legge la posa
## della camera del player adesso, non quella di dieci secondi fa.
func _fine() -> Transform3D:
	if _arrivo.is_valid():
		var t = _arrivo.call()
		if t is Transform3D:
			return t
	return Transform3D(Basis(), _centro + Vector3(0, 1.6, 0))


func salta() -> void:
	if not _finito:
		_chiudi()


func _chiudi() -> void:
	_finito = true
	set_process(false)
	finita.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if _finito:
		return
	var vale: bool = event is InputEventKey and event.pressed and not event.echo
	vale = vale or (event is InputEventMouseButton and event.pressed)
	vale = vale or (event is InputEventJoypadButton and event.pressed)
	if vale:
		get_viewport().set_input_as_handled()
		salta()
