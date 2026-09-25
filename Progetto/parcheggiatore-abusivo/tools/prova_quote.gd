extends Node
## **'A roba 'n terra sta 'n terra** (0.59).
##
## Le cose raggruppate (`_batched` → MultiMesh) vengono alzate sulla
## collina del Vomero **una volta** da `_batched`. Chi le piazza passando già
## `Collina.alzata()` come quota le fa alzare due volte: sei metri invece di
## tre, cioè vasi e paletti sospesi per aria sopra al terrapieno.
## Questa prova guarda ogni istanza dei gruppi "da terra" e controlla che
## la sua base stia alla quota del suolo su cui poggia (zero in città, tre
## sulla collina), con venti centimetri di tolleranza.

const Collina := preload("res://scripts/collina.gd")

## I gruppi che stanno appoggiati per terra (prefissi dei nomi).
const DA_TERRA := ["Gruppo_vaso", "Gruppo_giara", "Gruppo_bordo_",
	"Gruppo_cant_", "Gruppo_cantiere_", "Gruppo_arco", "Gruppo_strada_", "Gruppo_munnezza_",
	"Gruppo_cartelli_", "Gruppo_lungomare_", "Gruppo_aiuole_",
	"Gruppo_slarghi_", "Gruppo_vascio_fore_", "Gruppo_cestino_mod"]
## Nel cantiere i sacchi stanno sul bancale (tredici centimetri): la
## tolleranza è di venti, quindi ci stanno pure loro.

var _male := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(90):
		await get_tree().process_frame
	var citta := get_tree().get_first_node_in_group("citta")
	var visti := 0
	var sulla_collina := 0
	for c in citta.get_children():
		if not (c is MultiMeshInstance3D):
			continue
		var nome := str(c.name)
		var da_terra := false
		for p in DA_TERRA:
			if nome.begins_with(p):
				da_terra = true
		if not da_terra:
			continue
		var mm: MultiMesh = (c as MultiMeshInstance3D).multimesh
		var gt: Transform3D = (c as Node3D).global_transform
		for i in range(mm.instance_count):
			var t: Transform3D = gt * mm.get_instance_transform(i)
			var p: Vector3 = t.origin
			visti += 1
			var suolo: float = Collina.alzata(p.x, p.z)
			if suolo > 0.0:
				sulla_collina += 1
			if absf(p.y - suolo) > 0.2 and p.y - suolo > 0.2:
				_male += 1
				if _male <= 25:
					print("  PER ARIA  %-28s a (%.1f, %.1f)  y %.2f  suolo %.2f" % [
						nome, p.x, p.z, p.y, suolo])
	print("  %d istanze da terra guardate, %d sulla collina" % [visti, sulla_collina])
	print("=== storte: %d ===" % _male)
	get_tree().quit()
