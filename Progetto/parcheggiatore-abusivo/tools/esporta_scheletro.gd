extends SceneTree
## **'O scheletro d''o pupo, tirato fore pe' Blender.**
##
## `tools/build_personaggi.py` costruisce il corpo del pupo sullo scheletro
## della Universal Animation Library. Il file originale (`UAL1_Standard.glb`)
## sta solo sul computer del capo; questo script ricava lo stesso scheletro
## da `pupo.scn`, che sta nel repository, e lo scrive come glTF. Le
## animazioni restano fuori apposta: non servono a Blender, e il corpo nuovo
## si rimonta sulle clip vecchie con `tools/monta_pupo.gd`.
##
##   godot --headless --path . --script res://tools/esporta_scheletro.gd -- \
##       ../../_claude_tmp/grafica/pupo/pupo_scheletro.glb

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var uscita: String = a[0] if a.size() > 0 \
		else ProjectSettings.globalize_path("res://../../_claude_tmp/grafica/pupo/pupo_scheletro.glb")
	DirAccess.make_dir_recursive_absolute(uscita.get_base_dir())
	var s: Node = (load("res://assets/models/pupo.scn") as PackedScene).instantiate()
	var ap := s.find_child("AnimationPlayer", true, false)
	if ap != null:
		ap.get_parent().remove_child(ap)
		ap.free()
	get_root().add_child(s)
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	var err := doc.append_from_scene(s, st)
	if err == OK:
		err = doc.write_to_filesystem(st, uscita)
	print("  scheletro → ", uscita, " (", err, ")")
	quit(0 if err == OK else 1)
