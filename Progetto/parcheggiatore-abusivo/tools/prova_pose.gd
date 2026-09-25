extends Node
## Dove finiscono le mani, clip per clip.
##
## **Cagnata ê 0.48.** Prima misurava le clip ritargettate sullo scheletro
## fatto a mano, e serviva a scoprire quali venivano storte — la posa a T
## di "parla" l'ha trovata questa. Adesso le clip sono quelle native del
## manichino e non c'è più niente da ritargettare, quindi la prova cambia
## mestiere: non cerca più le clip rotte, **controlla che le clip esistano
## e che il personaggio si muova davvero**.
##
## Riferimento: a braccia lungo il corpo la mano sta a circa (±0.20, 0.75)
## rispetto ai piedi. In croce (posa a T) sta a (±0.70, 1.40).

const Human := preload("res://scripts/human_builder.gd")
const Anim := preload("res://scripts/animator.gd")


func _ready() -> void:
	await get_tree().process_frame
	var parti: Dictionary = Human.build(Color.WHITE, Color.BLACK, "", 1.80, {})
	var root: Node3D = parti["root"]
	add_child(root)
	var pl: AnimationPlayer = parti.get("player")
	var sk: Skeleton3D = parti.get("scheletro")
	var a = parti.get("anim")
	print("=== 'E CLIP D''O PUPO ===")
	if pl == null or sk == null:
		print("  !! niente scheletro o niente player")
		get_tree().quit()
		return
	var male := 0
	for chiave in Anim.CLIP:
		var nome: String = str(Anim.CLIP[chiave])
		var c: bool = pl.has_animation(nome)
		if not c:
			male += 1
		print("  %-14s %-18s %s" % [chiave, nome, "OK" if c else "NUN CE STA"])
	print("=== %d clip mancante ncopp'a %d ===" % [male, Anim.CLIP.size()])

	print("=== 'E MMANE ===")
	for prova in [["idle", 0.0], ["walk", 1.5], ["run", 6.0]]:
		a.set_speed(float(prova[1]))
		await get_tree().create_timer(0.45).timeout
		var sx: int = sk.find_bone("hand_l")
		var dx: int = sk.find_bone("hand_r")
		var ps: Vector3 = sk.get_bone_global_pose(sx).origin
		var pd: Vector3 = sk.get_bone_global_pose(dx).origin
		print("  %-6s  mano sx (%.2f, %.2f)  dx (%.2f, %.2f)" % [
			str(prova[0]), ps.x, ps.y, pd.x, pd.y])
	get_tree().quit()
