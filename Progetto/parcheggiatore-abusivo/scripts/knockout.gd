extends Node
class_name Knockout
## Knockout
## Il pezzo condiviso per "stendere" un personaggio a furia di cazzotti.
##
## Ogni NPC tiene i suoi punti (hp) e chiama `hit()` quando le prende. Quando
## finiscono, `lay_down()` lo fa cadere di lato: il corpo ruota, si abbassa,
## e da lì in poi non fa più niente finché non si rialza (o non si rialza
## proprio, se `get_up_after` è 0).
##
## Non è una ragdoll: è una rotazione interpolata. In un gioco così basta,
## e costa niente.
##
## Dalla v0.20 i personaggi hanno uno scheletro vero: se sotto al nodo
## grafico c'è un `Animator`, la caduta la fa lui con la clip "knock"
## (ginocchia che si piegano, braccia che si allargano) e qui resta solo il
## cronometro del rialzo. Se l'Animator non c'è — modelli 3D esterni, che
## non si animano a pezzi — si ricade sulla vecchia rotazione del busto.

## Quanto ci mette il corpo a finire per terra.
const FALL_TIME: float = 0.55
## Quanto resta steso prima di rialzarsi, per chi si rialza.
const DEFAULT_GET_UP: float = 9.0

const SAY_KO := ["…", "Ahi. Ahi. Ahi.", "Aiut'… aiut'…"]


## Stato di uno steso. Chi lo usa se lo tiene come Dictionary e lo passa a
## `tick()` ogni frame.
static func make_state() -> Dictionary:
	return {"down": false, "fall": 0.0, "get_up": 0.0, "base_y": 0.0,
		"base_rot": Vector3.ZERO, "anim": null, "searched": false}


## L'Animator del personaggio, se ce l'ha. Cercato una volta sola e messo
## da parte: `find_child` ricorsivo ogni frame sarebbe uno spreco.
static func _anim_of(state: Dictionary, visual: Node3D) -> Node:
	if not state["searched"]:
		state["searched"] = true
		if is_instance_valid(visual):
			state["anim"] = visual.find_child("Animator", true, false)
	var a = state["anim"]
	return a if is_instance_valid(a) else null


## Fa partire la caduta. `visual` è il nodo grafico del personaggio.
static func lay_down(state: Dictionary, visual: Node3D,
		get_up_after: float = DEFAULT_GET_UP) -> void:
	if state["down"]:
		return
	state["down"] = true
	state["fall"] = 0.0
	state["get_up"] = get_up_after
	state["base_y"] = visual.position.y
	state["base_rot"] = visual.rotation
	var anim := _anim_of(state, visual)
	if anim != null:
		anim.knock_down()
	SoundManager.play("botta", -3.0, 0.9)
	GameManager.screen_shake.emit(0.4)


## Da chiamare ogni frame finché state["down"] è vero. Ritorna true quando
## il personaggio si è rialzato del tutto.
static func tick(state: Dictionary, visual: Node3D, delta: float) -> bool:
	if not state["down"]:
		return false
	state["fall"] = minf(state["fall"] + delta / FALL_TIME, 1.0)
	var anim := _anim_of(state, visual)
	if anim == null:
		# Nessuno scheletro: il vecchio ribaltamento del busto.
		var t: float = state["fall"]
		var smooth: float = t * t * (3.0 - 2.0 * t)
		visual.rotation.z = state["base_rot"].z + deg_to_rad(88.0) * smooth
		visual.position.y = state["base_y"] - 0.62 * smooth

	if state["get_up"] <= 0.0:
		return false # steso e basta
	state["get_up"] -= delta
	if state["get_up"] > 0.0:
		return false

	# Si rialza: si rimette tutto com'era.
	state["down"] = false
	state["fall"] = 0.0
	if anim != null:
		anim.revive()
	else:
		visual.rotation = state["base_rot"]
		visual.position.y = state["base_y"]
	return true
