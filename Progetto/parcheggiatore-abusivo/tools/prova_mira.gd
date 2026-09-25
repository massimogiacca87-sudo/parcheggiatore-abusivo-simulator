extends Node
## **Il collaudo che mancava.**
##
## La 0.44 è uscita con porta di casa, letto, moglie, criature, tavolini
## della scopa e commissioni tutti costruiti bene, tutti con il loro
## `get_interact_prompt`… e nessuno dei sei agganciabile, perché il gruppo
## non stava in `GRUPPI_BERSAGLIO`. Il collaudo di allora chiamava
## `get_interact_prompt` **a mano**, e quindi passava: provava che la
## funzione rispondeva, non che il giocatore ci arrivasse.
##
## Questo invece mette il player davanti a ogni cosa, gli fa guardare il
## bersaglio e chiede al gioco cosa ha agganciato. È l'unica prova che
## conta: se qui esce "NIENTE", col pad in mano non succede niente.

const PlayerScript := preload("res://scripts/player_fps.gd")


func _ready() -> void:
	for _i in range(120):
		await get_tree().process_frame
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null:
		print("MIRA: nun ce sta 'o player")
		get_tree().quit()
		return

	print("=== CHE SE PO' TUCCA' ===")
	var vascio := get_tree().get_first_node_in_group("vascio")
	var prove: Array = []
	if vascio != null:
		var porta: Node3D = vascio.get_node_or_null("PortaCasa")
		if porta != null:
			prove.append(["'a porta 'a fore", porta, Vector3(1.6, 0, 0)])
		var dentro: Node = vascio.get_node_or_null("Dentro")
		if dentro != null:
			for n in dentro.get_children():
				if n.name == "Uscita":
					prove.append(["'a porta 'a dintro", n, Vector3(-1.4, 0, 0)])
				elif n.name == "Letto":
					prove.append(["'o lietto", n, Vector3(-1.5, 0, 0)])
				elif n.name == "Moglie":
					prove.append(["'a mugliera", n, Vector3(1.3, 0, 0.4)])
				elif n.name.begins_with("Criatura"):
					prove.append(["'a criatura", n, Vector3(0.0, 0, 1.3)])
	for t in get_tree().get_nodes_in_group("tavoli_scopa"):
		prove.append(["'o tavulo 'e %s" % str(t.get("sfidante_id")), t,
			Vector3(0.0, 0, 2.0)])
	for c in get_tree().get_nodes_in_group("punti_cummissione"):
		prove.append(["'o segno d''a cummissione", c, Vector3(1.8, 0, 0)])
	# --- 'E ccose nove d''a 0.45: 'a bacheca e 'o garage ---
	for b in get_tree().get_nodes_in_group("bacheche"):
		var f := Vector3(-sin(b.rotation.y), 0.0, -cos(b.rotation.y))
		prove.append(["'a bacheca 'e %s" % str(b.get("zona_id")), b, f * 2.2])
	for g in get_tree().get_nodes_in_group("garage"):
		var f2 := Vector3(-sin(g.rotation.y), 0.0, -cos(g.rotation.y))
		prove.append(["'o garage 'e %s" % str(g.get("zona_id")), g, f2 * 3.0])
	for gu in get_tree().get_nodes_in_group("guagliuni"):
		prove.append(["'o guaglione 'e %s" % str(gu.get("zona_id")), gu,
			Vector3(0.0, 0, 1.6)])

	var male := 0
	for p in prove:
		var nome: String = str(p[0])
		var bersaglio: Node3D = p[1]
		var scarto: Vector3 = p[2]
		var dove: Vector3 = bersaglio.global_position + scarto
		# **Dentro casa il player va segnato come dentro casa**, se no il
		# controllo dei bordi lo riporta in piazza fra un fotogramma e
		# l'altro e la prova misura il posto sbagliato. (Ed e' anche il
		# motivo per cui la porta di dentro sembrava rotta: non lo era.)
		GameManager.dentro_casa = dove.x > 200.0
		pl.global_position = dove + Vector3(0, 0.1, 0)
		# Si guarda il bersaglio all'altezza del petto, come farebbe uno.
		var verso: Vector3 = (bersaglio.global_position
			+ Vector3(0, 1.1, 0)) - (dove + Vector3(0, 1.6, 0))
		pl.rotation.y = atan2(-verso.x, -verso.z)
		var cam: Camera3D = pl.get("camera")
		if cam != null:
			cam.rotation.x = atan2(verso.y, Vector2(verso.x, verso.z).length())
		await get_tree().physics_frame
		await get_tree().physics_frame
		var t = pl.get("current_target")
		var esito := "NIENTE"
		if t != null and is_instance_valid(t):
			if t == bersaglio:
				esito = "OK"
			else:
				esito = "sbagliato: " + str(t.name)
		if esito != "OK":
			male += 1
		if esito != "OK":
			print("      (player a %s, bersaglio a %s)"
				% [str(pl.global_position.round()),
				   str(bersaglio.global_position.round())])
		var testo := ""
		if t != null and is_instance_valid(t) \
				and t.has_method("get_interact_prompt"):
			testo = str(t.get_interact_prompt(pl.global_position))
		print("  %-34s %-22s %s" % [nome, esito, testo.left(62)])
	print("=== %d storte ncopp'a %d ===" % [male, prove.size()])
	get_tree().quit()
