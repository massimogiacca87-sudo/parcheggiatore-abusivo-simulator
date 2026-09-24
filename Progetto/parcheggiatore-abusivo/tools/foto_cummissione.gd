extends Node
## Fote d''e cummissiune cu 'e perzone (0.62). TIPO=pizze (default).
## DEBUG_SIM=1 /tmp/foto.sh foto_cummissione 200 → /tmp/cumm_*.png

var _pl: Node3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(60):
		await get_tree().process_frame
	get_tree().paused = false
	GameManager.intro_active = false
	GameManager.start_shift()
	_pl = get_tree().get_first_node_in_group("player") as Node3D
	var tipo: String = OS.get_environment("TIPO") if OS.get_environment("TIPO") != "" else "pizze"
	# Una commissione sola, del tipo voluto, che parte dalla piazza.
	var t: Dictionary = {}
	for x in GameManager.CUMM_TIPI:
		if str(x["tipo"]) == tipo:
			t = x
	GameManager.commissioni.clear()
	var c := {"id": "foto_1", "tipo": tipo, "nome": str(t["nome"]),
		"testo": str(t["testo"]) % "'o mercato", "da": Vector3(31, 0, 30),
		"a": Vector3(31, 0, 111), "nome_da": "'a piazza", "nome_a": "'o mercato",
		"paga": 22, "tempo": 200.0, "stato": "aperta", "integrita": 1.0}
	for k in t:
		if not c.has(k) and not k in ["paga_min", "paga_max", "minuti"]:
			c[k] = t[k]
	GameManager.commissioni.append(c)
	GameManager.commissioni_cambiate.emit()
	# Il player a tredici metri: lui lo vede, lo chiama, gli viene incontro.
	_pl.global_position = Vector3(31, 0.3, 44)
	_pl.rotation.y = 0.0
	(_pl.get("head") as Node3D).rotation.x = deg_to_rad(-8)
	await get_tree().create_timer(1.5).timeout
	await _scatta("chiama")
	await get_tree().create_timer(5.0).timeout
	var chi := _perzona("da")
	print("  committente a ", chi.global_position if chi else "NULL", " fase ", chi.get("_fase") if chi else -1)
	_guarda(chi)
	await get_tree().create_timer(3.0).timeout
	await _scatta("storia")
	if chi != null:
		chi.player_interact()
	await get_tree().create_timer(1.2).timeout
	print("  in mano: ", GameManager.commissione_in_mano().get("robba", "niente"))
	(_pl.get("head") as Node3D).rotation.x = deg_to_rad(-25)
	await get_tree().create_timer(0.5).timeout
	await _scatta("in_mano")
	# Si va al mercato.
	_pl.global_position = Vector3(31, 0.3, 104)
	await get_tree().create_timer(2.5).timeout
	var chi_a := _perzona("a")
	_guarda(chi_a)
	await get_tree().create_timer(1.0).timeout
	await _scatta("destinatario")
	var soldi: int = GameManager.money
	if chi_a != null:
		chi_a.player_interact()
	await get_tree().create_timer(1.0).timeout
	await _scatta("consegnato")
	print("  soldi %d → %d" % [soldi, GameManager.money])
	get_tree().quit()


func _perzona(ruolo: String) -> Node3D:
	for n in get_tree().get_nodes_in_group("committenti"):
		if str(n.get("ruolo")) == ruolo and is_instance_valid(n):
			return n
	return null


func _guarda(n: Node3D) -> void:
	if n == null:
		return
	var d: Vector3 = n.global_position - _pl.global_position
	d.y = 0
	if d.length() > 2.6:
		_pl.global_position = n.global_position - d.normalized() * 2.4 + Vector3(0, 0.3, 0)
		d = n.global_position - _pl.global_position
		d.y = 0
	_pl.rotation.y = atan2(-d.x, -d.z)
	(_pl.get("head") as Node3D).rotation.x = deg_to_rad(-6)


func _scatta(nome: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/cumm_%s.png" % nome)
	print("  foto: /tmp/cumm_%s.png" % nome)
