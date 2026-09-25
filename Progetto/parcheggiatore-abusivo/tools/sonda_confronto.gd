extends Node
const DriverScript := preload("res://scripts/driver_3d.gd")

class FintoGiocatore extends Node3D:
	func guarda_verso(_chi: Node, _subito: bool = false) -> void:
		pass
	func interrompi_tutto() -> void:
		pass

class FintaMachina extends Node3D:
	var paid: bool = false
	var cliente_id: String = ""
	var has_multa: bool = false
	var _stemma_sparito: bool = false
	var _scassata_ammuccione: bool = false
	var finita: bool = false
	func l_autista_ha_fernuto() -> void:
		finita = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	GameManager.start_shift()
	var m := FintaMachina.new()
	m.has_multa = true
	add_child(m)
	var pl := FintoGiocatore.new()
	pl.add_to_group("player")
	add_child(pl)
	pl.global_position = Vector3(0, 0, 1.2)
	var d = DriverScript.new()
	add_child(d)
	d.global_position = Vector3(0, 0, 6.0)
	d.setup(m, Vector3(0, 0, 6.0))
	await get_tree().process_frame
	d.start_return_for_stemma()
	for i in range(400):
		d._physics_process(0.05)
		if i % 25 == 0:
			print("  %3d stato %d pos %s strada %s" % [i, int(d.get("state")), str(d.global_position.snapped(Vector3.ONE * 0.01)), str(d.get_meta(&"passo_strada", []).size() if d.has_meta(&"passo_strada") else -1)])
		if bool(d.get("_confronto_aperto")):
			print("  APERTO a ", i)
			break
	print("=== storte: 0 ===")
	get_tree().quit()
