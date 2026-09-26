extends Node
## Sonda (0.62): quanta roba degli asset esterni è entrata in città, e
## perché il resto è stato scartato (`RobbaEsterna.rifiuti`). Headless.
const RobbaEsterna := preload("res://scripts/robba_esterna.gd")
var _t := 0.0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _process(d: float) -> void:
	_t += d
	if _t < 3.0:
		return
	set_process(false)
	var c = get_tree().get_first_node_in_group("citta")
	for k in ["tombini_messi", "macchie_posti", "colature_split", "colature_muro",
			"graffiti_tag", "motorini_strada", "coni_cantieri",
			"segge_vienna", "bidoni_ferro", "casse_legno", "segge_ufficio"]:
		print("  ESTERNI %-16s %s" % [k, str(c.get_meta(k, "-"))])
	print("  ESTERNI cassonetti %d  vasci %d" % [c._cassonetti.size(), c._vasci_fore.size()])
	print("  ESTERNI rifiuti %s" % str(RobbaEsterna.rifiuti))
	get_tree().quit()
