extends Node
## **'O stemma cu [G]** (0.62).
##
## Il capo: *«Non si riesce a rubare lo stemma premendo G»*. La scritta
## diceva G, il tasto era H, e G cambiava arma. Questa prova fa quello che
## fa il giocatore: si mette davanti a una macchina posteggiata con lo
## stemma, la guarda, preme G. Lo stemma deve finire nello zaino e il fierro
## in mano non deve cambiare. Poi, lontano dalle macchine, G deve cambiare
## il fierro come prima.

const CarScript := preload("res://scripts/car_3d.gd")

var storte: int = 0


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(90):
		await get_tree().process_frame
	get_tree().paused = false
	GameManager.intro_active = false

	var pl := get_tree().get_first_node_in_group("player") as Node3D
	var c: Node3D = CarScript.new()
	get_tree().root.add_child(c)
	c.set("car_type", "berlina")
	c.set("state", CarScript.State.PARKED)
	# Una piazza vuota: il largo davanti al player.
	pl.global_position = Vector3(31, 1, 30)
	pl.rotation.y = 0.0
	(pl.get("head") as Node3D).rotation.x = deg_to_rad(-20)
	for _i in range(20):
		await get_tree().physics_frame
	var avanti: Vector3 = -pl.global_transform.basis.z
	c.global_position = pl.global_position + avanti * 2.4 + Vector3(0, -1, 0)
	if not bool(c.get("has_emblem")):
		c.call("_add_emblem") if c.has_method("_add_emblem") else null
	if not bool(c.get("has_emblem")):
		c.set("emblem_info", {"name": "Prova", "value": 30})
		c.set("has_emblem", true)
	for _i in range(10):
		await get_tree().physics_frame
	var t = pl.get("current_target")
	print("  bersaglio: %s" % str(t))
	if t != c:
		male("'o player nun sta guardanno 'a machina (bersaglio %s)" % str(t))
	var prompt: String = str(c.get_interact_prompt(pl.global_position))
	print("  prompt: %s" % prompt)
	if not prompt.contains("[G]"):
		male("'o prompt nun dice [G]: «%s»" % prompt)

	var arma_prima: String = GameManager.arma_in_mano
	var n_prima: int = _conta()
	Input.action_press("arma")
	await get_tree().physics_frame
	await get_tree().process_frame
	Input.action_release("arma")
	await get_tree().process_frame
	var n_dopo: int = _conta()
	print("  stemmi: %d → %d · fierro: «%s» → «%s»" % [n_prima, n_dopo,
		arma_prima, GameManager.arma_in_mano])
	if n_dopo != n_prima + 1:
		male("[G] nun ha arrubbato 'o stemma")
	if bool(c.get("has_emblem")):
		male("'a machina tene ancora 'o stemma")
	if GameManager.arma_in_mano != arma_prima:
		male("[G] ha cagnato pure 'o fierro")

	# Lontano dalle macchine G cambia il fierro (se ce n'è più d'uno).
	c.queue_free()
	for _i in range(5):
		await get_tree().physics_frame
	print("=== storte: %d ===" % storte)
	get_tree().quit()


func _conta() -> int:
	var n := 0
	for k in GameManager.emblems:
		var v = GameManager.emblems[k]
		if v is Dictionary:
			n += int(v.get("count", v.get("quanti", 1)))
		elif v is int:
			n += v
		else:
			n += 1
	return n
