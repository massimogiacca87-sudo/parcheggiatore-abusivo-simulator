extends SceneTree
## **'O lanciatore d''e fote, senza tuccà `project.godot`** (0.66).
##
## Gli strumenti di foto «dentro al gioco» (`foto_storia.gd`,
## `foto_strada.gd`…) sono nodi pensati per girare come autoload: finora si
## lanciavano aggiungendoli a `project.godot` e rimettendolo a posto dopo.
## Funziona, ma `project.godot` è un file di tutti: due prove in parallelo
## se lo sovrascrivono a vicenda. Qui invece lo strumento si appende alla
## radice da uno script di riga di comando (gli autoload veri del gioco ci
## sono lo stesso), e con `citta` si accende pure la scena principale.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x760 \
##       --script res://tools/lancia_foto.gd -- res://tools/foto_storia.gd [citta]
##
## Le foto vanno dove dice lo strumento (di solito `FOTO_DIR`).

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.is_empty():
		push_error("manca lo strumento da lanciare")
		quit(1)
		return
	if a.size() > 1 and a[1] == "citta":
		var main_path: String = str(ProjectSettings.get_setting("application/run/main_scene"))
		var main: Node = (load(main_path) as PackedScene).instantiate()
		get_root().add_child.call_deferred(main)
	var strumento: Node = (load(a[0]) as Script).new()
	strumento.name = "Foto"
	get_root().add_child.call_deferred(strumento)
