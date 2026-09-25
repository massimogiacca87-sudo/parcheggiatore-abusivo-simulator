extends SceneTree
## Il colore medio (pesato per area) di alcune mesh di Pandazole, letto
## dall'atlante: serve a dare il colore giusto al "letto" di frutta nelle
## cassette.

func _initialize() -> void:
	var img: Image = (load("res://assets/models/pandazole.png") as Texture2D).get_image()
	if img.is_compressed():
		img.decompress()
	var w := img.get_width()
	var h := img.get_height()
	for nome in OS.get_environment("SONDA").split(","):
		var m: Mesh = load("res://assets/models/%s.mesh" % nome)
		var somma := Color(0, 0, 0, 0)
		var peso := 0.0
		for s in m.get_surface_count():
			var arr: Array = m.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
			var idx = arr[Mesh.ARRAY_INDEX]
			var n: int = (idx.size() if idx != null else v.size()) / 3
			for t in range(n):
				var i0: int = idx[t * 3] if idx != null else t * 3
				var i1: int = idx[t * 3 + 1] if idx != null else t * 3 + 1
				var i2: int = idx[t * 3 + 2] if idx != null else t * 3 + 2
				var area: float = (v[i1] - v[i0]).cross(v[i2] - v[i0]).length() * 0.5
				var c: Vector2 = (uv[i0] + uv[i1] + uv[i2]) / 3.0
				var px := clampi(int(fposmod(c.x, 1.0) * w), 0, w - 1)
				var py := clampi(int(fposmod(c.y, 1.0) * h), 0, h - 1)
				var col := img.get_pixel(px, py)
				somma += col * area
				peso += area
		var media: Color = somma / maxf(peso, 0.000001)
		print('\t"%s": Color(%.2f, %.2f, %.2f),' % [nome, media.r, media.g, media.b])
	quit()
