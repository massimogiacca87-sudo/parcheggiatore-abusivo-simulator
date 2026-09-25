extends Node
## Sonda: le scatole solide attorno al campetto del largo d''e guagliune.
const Ostacoli := preload("res://scripts/ostacoli.gd")
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(120):
		await get_tree().process_frame
	for s in Ostacoli.tutte():
		var a: Array = s
		if absf(float(a[0]) - 36.0) < 7.0 and absf(float(a[1]) - 138.0) < 9.0:
			print("  scatola ", a)
	var b = get_tree().get_first_node_in_group("bambini")
	if b:
		print("campetto a ", b.global_position, " porta ", b._porte)
	print("=== storte: 0 ===")
	get_tree().quit()
