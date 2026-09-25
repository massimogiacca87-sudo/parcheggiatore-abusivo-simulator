extends Node
## 'A caccia — chi manda i carabinieri, e quanti
##
## Un nodo solo, appeso alla città, che guarda le stelle e tiene in piedi il
## numero giusto di carabinieri a piedi. Sta separato dallo `Sbirro3D` per
## la stessa ragione per cui il rubinetto delle auto sta separato dall'auto:
## chi nasce e chi muore lo deve decidere qualcuno che non nasce e non muore.
##
## **La regola.** Una stella = un carabiniere, fino a quattro; alla quinta
## ne arrivano cinque insieme. Nascono FUORI dal campo visivo, a una
## trentina di metri, e arrivano camminando: uno che compare davanti agli
## occhi è un bug, uno che spunta in fondo alla strada è una scena.
##
## Quando le stelle tornano a zero se ne vanno tutti da soli — non li
## cancella questo nodo, se ne accorgono loro (`Stato.CERCA` con zero
## stelle) e si defilano dicendo la loro. Cancellarli di colpo li farebbe
## sparire davanti al giocatore.

const SbirroScript := preload("res://scripts/sbirro_3d.gd")

## Ogni quanto ricontrolla. Non serve farlo a ogni frame: è una decisione
## che cambia una volta ogni parecchi secondi.
const CONTROLLO_OGNI: float = 1.6
## Quanto lontano nascono.
const DISTANZA_ARRIVO: float = 34.0
## Ritardo fra un arrivo e l'altro, così non spuntano in fila indiana.
const RITARDO_FRA_ARRIVI: float = 2.6

var _t: float = 0.0
var _prossimo: float = 0.0
var _citta: Node = null


func _ready() -> void:
	name = "Caccia"
	_citta = get_parent()


func _quanti_servono() -> int:
	var s: int = GameManager.stelle
	if s <= 0:
		return 0
	return mini(s, 5)


func _process(delta: float) -> void:
	_prossimo = maxf(0.0, _prossimo - delta)
	_t -= delta
	if _t > 0.0:
		return
	_t = CONTROLLO_OGNI

	# Nessuno ti vede se non c'è nessuno: la segnalazione di "vista" la
	# rimettono a false qui e la rialzano i carabinieri nel loro processo.
	# Senza questo azzeramento, il primo che ti vede una volta la lascerebbe
	# accesa per sempre e le stelle non scenderebbero più.
	GameManager.segnala_vista(false)

	if not GameManager.shift_active or GameManager.arrested \
			or GameManager.hospitalized:
		return
	var vivi := get_tree().get_nodes_in_group("sbirri").size()
	var servono := _quanti_servono()
	# **Fedina pulita: la centrale li richiama tutti.**
	#
	# Non basta smettere di mandarne di nuovi: quelli che stanno gia' per
	# strada devono tornare indietro. Se no, con tre pattuglie in giro, il
	# giocatore che si e' nascosto bene per venti secondi se le ritrova
	# comunque addosso, e non capisce a che sia servito nascondersi.
	if servono == 0 and vivi > 0:
		for s2 in get_tree().get_nodes_in_group("sbirri"):
			if s2.has_method("_vattene"):
				s2.call("_vattene")
		return
	if vivi >= servono or _prossimo > 0.0:
		return
	_manda_uno()
	_prossimo = RITARDO_FRA_ARRIVI


func _manda_uno() -> void:
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null or not is_instance_valid(pl):
		return
	var dove := _punto_di_arrivo(pl.global_position)
	var s := SbirroScript.new()
	s.name = "Sbirro"
	_citta.add_child(s)
	s.global_position = dove
	GameManager.event_started.emit("'E CARABINIERI TE STANNO CERCANNO!")


## Dove nasce: su una strada, a una trentina di metri, dietro alle spalle se
## si può. Si provano otto direzioni e si tiene la prima che cade dentro
## alla mappa e in mezzo a una strada — se nessuna va bene si ripiega sul
## bordo più vicino, che è sempre percorribile.
func _punto_di_arrivo(da: Vector3) -> Vector3:
	var w: float = _citta.LARGHEZZA
	var l: float = _citta.PROFONDITA
	var partenza: float = randf() * TAU
	for i in range(8):
		var a: float = partenza + TAU * float(i) / 8.0
		var p := da + Vector3(cos(a), 0.0, sin(a)) * DISTANZA_ARRIVO
		if p.x < 4.0 or p.x > w - 4.0 or p.z < 2.0 or p.z > l - 2.0:
			continue
		if str(_citta.strada_di(p)) == "":
			continue
		return Vector3(p.x, 0.4, p.z)
	# Ripiego: l'imbocco del Corso, che è la strada più larga che c'è.
	return Vector3(78.0, 0.4, clampf(da.z + 30.0, 6.0, l - 6.0))
