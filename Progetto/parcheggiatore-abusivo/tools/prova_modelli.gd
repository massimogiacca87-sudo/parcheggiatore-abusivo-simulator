extends Node
## Controlla che ogni modello di auto si carichi davvero, che sia della
## misura giusta e che abbia i materiali per essere verniciato.
##
## E' la prova che mancava: `car_bmw.glb` stava in gioco da venti versioni
## senza normali e senza materiali, e nessun collaudo se n'era accorto
## perche' nessuno guardava dentro ai file.

const Models := preload("res://scripts/models.gd")
const Car := preload("res://scripts/car_3d.gd")


func _ready() -> void:
	await get_tree().process_frame
	print("=== 'E MMACHINE ===")
	var male := 0
	var visti: Array = []
	for tipo in Car.MODELLI:
		for nome in Car.MODELLI[tipo]:
			if visti.has(nome):
				continue
			visti.append(nome)
			var n: Node3D = Models.spawn(str(nome), 0.0)
			if n == null:
				print("  %-16s NUN SE CARICA" % nome)
				male += 1
				continue
			add_child(n)
			await get_tree().process_frame
			var d: Vector3 = Models.size_of(n)
			var mats: Array = []
			for mi in n.find_children("*", "MeshInstance3D", true, false):
				var am := mi.mesh as ArrayMesh
				if am == null:
					continue
				for i in range(am.get_surface_count()):
					var m: Material = mi.get_active_material(i)
					if m != null and not mats.has(m.resource_name):
						mats.append(m.resource_name)
			var ok: bool = d.z > 2.5 and d.z < 6.5 and d.x > 1.2 and d.x < 2.8 \
				and not mats.is_empty()
			if not ok:
				male += 1
			print("  %-16s %5.2f x %5.2f x %5.2f  %s  %s" % [nome, d.x, d.y, d.z,
				str(mats).left(46), "" if ok else "  <<< STORTA"])
			n.queue_free()
	print("=== %d storte ncopp'a %d ===" % [male, visti.size()])
	get_tree().quit()
