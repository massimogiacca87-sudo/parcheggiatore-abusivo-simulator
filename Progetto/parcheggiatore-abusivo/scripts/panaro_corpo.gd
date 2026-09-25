extends StaticBody3D
## Il corpo agganciabile del panaro (0.61): gira tutto a `panaro_3d.gd`.
## Sta separato perché il raggio dell'interazione aggancia **collider**, e
## chiede a loro `get_interact_prompt` e `player_interact`.


func _panaro() -> Node:
	return get_meta("panaro") if has_meta("panaro") else null


func get_interact_prompt(_da: Vector3) -> String:
	var p := _panaro()
	return p.call("prompt") if p != null else ""


func player_interact() -> void:
	var p := _panaro()
	if p != null:
		p.call("interagisci")
