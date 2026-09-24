extends SceneTree
## Stampa le ossa e le clip dei tre corpi (pupo, omo, umano_q): nome, padre,
## posizione globale a riposo. Serve a scrivere la tabella del retarget.

func _initialize() -> void:
	for p in ["res://assets/models/pupo.scn", "res://assets/models/omo_casual.scn",
			"res://assets/models/umano_q.scn"]:
		var ps: PackedScene = load(p)
		var m: Node3D = ps.instantiate()
		var sk: Skeleton3D = m.find_children("*", "Skeleton3D", true, false)[0]
		var ap: AnimationPlayer = m.find_children("*", "AnimationPlayer", true, false)[0]
		print("=== %s  ossa=%d  sk=%s  ap_root=%s" % [p, sk.get_bone_count(),
			str(m.get_path_to(sk)), str(ap.root_node)])
		for i in range(sk.get_bone_count()):
			var g: Transform3D = sk.get_bone_global_rest(i)
			var par := sk.get_bone_parent(i)
			print("  %2d %-22s padre=%-20s pos=(%.3f, %.3f, %.3f)" % [i, sk.get_bone_name(i),
				sk.get_bone_name(par) if par >= 0 else "-", g.origin.x, g.origin.y, g.origin.z])
		var clips := ap.get_animation_list()
		print("  clip (%d): %s" % [clips.size(), ", ".join(clips)])
		if clips.size() > 0:
			var a: Animation = ap.get_animation(clips[0])
			print("  traccia 0: %s" % str(a.track_get_path(0)))
		# La trasformazione dello scheletro dentro al modello.
		var t := Transform3D()
		var n: Node = sk
		while n != null and n != m:
			t = (n as Node3D).transform * t
			n = n.get_parent()
		print("  sk_in_modello: %s" % str(t))
		m.free()
	quit()
