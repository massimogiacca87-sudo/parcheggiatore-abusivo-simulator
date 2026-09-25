extends SceneTree
## Le tracce di una clip: per ogni osso, quanto si muove.

func _initialize() -> void:
	var lib: AnimationLibrary = load(OS.get_environment("LIB"))
	var a: Animation = lib.get_animation(OS.get_environment("CLIP"))
	print("durata %.2f  tracce %d  loop %d" % [a.length, a.get_track_count(), a.loop_mode])
	for t in a.get_track_count():
		var tipo := a.track_get_type(t)
		var n := a.track_get_key_count(t)
		var riga := "%s tipo %d chiavi %d" % [str(a.track_get_path(t)), tipo, n]
		if tipo == Animation.TYPE_POSITION_3D and n > 0:
			riga += "  pos0 %s  posM %s  posF %s" % [str(a.position_track_interpolate(t, 0.0).snapped(Vector3.ONE*0.01)), str(a.position_track_interpolate(t, a.length*0.5).snapped(Vector3.ONE*0.01)), str(a.position_track_interpolate(t, a.length).snapped(Vector3.ONE*0.01))]
		if tipo == Animation.TYPE_ROTATION_3D and n > 0:
			var q0 := a.rotation_track_interpolate(t, 0.0)
			var qm := a.rotation_track_interpolate(t, a.length*0.5)
			var qf := a.rotation_track_interpolate(t, a.length)
			riga += "  ang0-M %.0f  ang0-F %.0f" % [rad_to_deg(q0.angle_to(qm)), rad_to_deg(q0.angle_to(qf))]
		print(riga)
	quit()
