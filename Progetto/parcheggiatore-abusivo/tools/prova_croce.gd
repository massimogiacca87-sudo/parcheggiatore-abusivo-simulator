extends Node
## **Chi sta ancora 'n croce?** (0.59)
##
## Il capo: *«risolvi i problemi di T pose di molti personaggi. Cerca di
## animarli tutti decentemente.»*
##
## Una posa a T non si trova guardando il codice: si trova guardando le
## ossa. Il codice può dire `animate: true` e il personaggio stare lo stesso
## a braccia aperte (una clip che non c'è, un albero spento, un'osa girata a
## mano dopo l'animazione), e può dire `animate: false` e il personaggio
## essere messo in posa da qualcun altro. Quindi questa prova non legge
## niente: accende la città, apre la giornata, aspetta, e poi misura **ogni
## scheletro che esiste**.
##
## **Come si riconosce una croce.** Il braccio (spalla → gomito) di uno a
## braccia lungo il corpo punta in giù; in croce punta **di lato**, lungo la
## linea delle spalle. Quindi per ogni braccio si fa il prodotto scalare fra
## la sua direzione e la linea spalla-spalla: sopra a 0,80 il braccio è
## steso di lato all'altezza della spalla. Se lo sono **tutti e due**, è
## una croce. Chi indica, chi tira un pugno, chi guida ha le braccia
## **avanti**, e il prodotto con la linea delle spalle resta basso.
##
## E si misura più volte: una croce che dura un fotogramma è un passaggio
## fra due clip, una che dura trenta secondi è un personaggio rotto.

## Le ossa del braccio, per ognuno dei tre scheletri che il gioco usa.
const BRACCIA := [
	# 'o pupo (Universal Animation Library)
	["upperarm_l", "lowerarm_l", "upperarm_r", "lowerarm_r"],
	# 'e guagliune low poly (Quaternius, "Animated Men")
	["UpperArm.L", "LowerArm.L", "UpperArm.R", "LowerArm.R"],
	# l'Animated Human (Quaternius, scheletro alla Mixamo)
	["LeftArm", "LeftForeArm", "RightArm", "RightForeArm"],
]

## I piedi, per vedere chi **scivola**: si sposta per la città ma le gambe
## non si muovono. È la seconda metà di «animarli tutti decentemente»: un
## personaggio che pattina in posa ferma non è in croce, ma è rotto uguale.
const PIEDI := [["foot_l", "foot_r"], ["Foot.L", "Foot.R"],
	["LeftFoot", "RightFoot"]]
## Chi va su un mezzo si muove senza camminare, ed è giusto così.
const SU_UN_MEZZO := ["car_3d.gd", "motorino_3d.gd", "motorino_citta.gd",
	"carabinieri_3d.gd", "jurnata_vista.gd"]

var _croci: Dictionary = {}      # percorso → quante volte in croce
var _viste: Dictionary = {}      # percorso → quante volte misurato
var _chi: Dictionary = {}        # percorso → descrizione
var _scivola: Dictionary = {}    # percorso → quante volte pattina
var _in_moto: Dictionary = {}    # percorso → quante volte si muoveva


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(90):
		await get_tree().process_frame
	GameManager.start_shift()
	# **Chi passa di rado si chiama apposta.** Il motorino arriva ogni
	# mezzo minuto, Borrelli solo di notte, i carabinieri solo se il vigile
	# li chiama: in settanta secondi di prova qualcuno non si vedrebbe mai,
	# e un personaggio che la prova non vede non è un personaggio a posto.
	_chiama_i_rari()
	# I momenti in cui si guarda: subito, e poi quando la piazza si è
	# riempita, le macchine sono arrivate e i motorini sono partiti.
	var tempi := [2.0, 8.0, 20.0, 40.0, 70.0]
	var passato := 0.0
	for t in tempi:
		await get_tree().create_timer(float(t) - passato).timeout
		passato = float(t)
		var z := _zona()
		if z != null and z.has_method("_spawn_motorino"):
			z.call("_spawn_motorino")
		await get_tree().create_timer(1.0).timeout
		_misura()
		await _pattina()
	print("=== 'E SCHELETRE MISURATE: %d ===" % _viste.size())
	var male := 0
	var chiavi: Array = _croci.keys()
	chiavi.sort()
	for k in chiavi:
		var n: int = int(_croci[k])
		var su: int = int(_viste.get(k, 1))
		# Una croce è rotta se si vede in più di metà delle misure.
		if n * 2 > su:
			male += 1
			print("  CROCE  %d/%d  %s" % [n, su, str(_chi.get(k, k))])
	print("=== CHI PATTINA (si sposta cu 'e piere fermi): %d misurate in movimento ===" % _in_moto.size())
	var ks: Array = _scivola.keys()
	ks.sort()
	for k2 in ks:
		var n2: int = int(_scivola[k2])
		var mossi: int = int(_in_moto.get(k2, 1))
		var desc: String = str(_chi.get(k2, k2))
		var mezzo := false
		for m in SU_UN_MEZZO:
			if desc.contains(m):
				mezzo = true
		if mezzo:
			continue
		if n2 * 2 >= mossi and n2 >= 2:
			male += 1
			print("  PATTINA  %d/%d  %s" % [n2, mossi, desc])
	print("=== storte: %d ===" % male)
	get_tree().quit()


func _zona() -> Node:
	return get_tree().root.find_child("ZoneVicolo", true, false)


func _chiama_i_rari() -> void:
	var z := _zona()
	if z == null:
		print("  (nun trovo ZoneVicolo: 'e rare nun se chiammano)")
		return
	for f in ["_spawn_signora", "_on_reinforcements_called"]:
		if z.has_method(f):
			z.call(f)
	var boss = load("res://scripts/borrelli_3d.gd").new()
	z.add_child(boss)
	boss.setup(z.call("_glob", z.get("entry_point")),
		z.call("_glob", z.get("exit_point")))
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	var sb = load("res://scripts/sbirro_3d.gd").new()
	z.get_parent().add_child(sb)
	if pl != null:
		sb.global_position = pl.global_position + Vector3(6.0, 0.0, 6.0)


func _misura() -> void:
	var tutte := get_tree().root.find_children("*", "Skeleton3D", true, false)
	for s in tutte:
		var sk: Skeleton3D = s
		if not sk.is_inside_tree():
			continue
		var k := str(sk.get_path())
		_viste[k] = int(_viste.get(k, 0)) + 1
		if not _chi.has(k):
			_chi[k] = _descrivi(sk)
		if _in_croce(sk):
			_croci[k] = int(_croci.get(k, 0)) + 1


## Due fotografie a un quarto di secondo: quanto si è spostato il corpo nel
## mondo, e quanto si sono mossi i piedi rispetto al corpo.
func _pattina() -> void:
	var prima := {}
	for s in get_tree().root.find_children("*", "Skeleton3D", true, false):
		var sk: Skeleton3D = s
		if not sk.is_inside_tree() or not sk.is_visible_in_tree():
			continue
		var pp := _piedi(sk)
		if pp.is_empty():
			continue
		prima[sk] = [sk.global_position, pp]
	await get_tree().create_timer(0.25).timeout
	for sk in prima:
		if not is_instance_valid(sk) or not sk.is_inside_tree():
			continue
		var d: Vector3 = sk.global_position - prima[sk][0]
		d.y = 0.0
		var v: float = d.length() / 0.25
		if v < 0.7 or v > 12.0:
			continue
		var k := str(sk.get_path())
		if not _chi.has(k):
			_chi[k] = _descrivi(sk)
		_in_moto[k] = int(_in_moto.get(k, 0)) + 1
		var dopo := _piedi(sk)
		var mosso := 0.0
		for i in range(mini(dopo.size(), prima[sk][1].size())):
			mosso = maxf(mosso, (dopo[i] - prima[sk][1][i]).length())
		if mosso < 0.02:
			_scivola[k] = int(_scivola.get(k, 0)) + 1


func _piedi(sk: Skeleton3D) -> Array:
	for coppia in PIEDI:
		var a: int = sk.find_bone(str(coppia[0]))
		var b: int = sk.find_bone(str(coppia[1]))
		if a >= 0 and b >= 0:
			var sc: float = sk.global_transform.basis.get_scale().x
			return [sk.get_bone_global_pose(a).origin * sc,
				sk.get_bone_global_pose(b).origin * sc]
	return []


## Vero se tutte e due le braccia stanno stese di lato.
func _in_croce(sk: Skeleton3D) -> bool:
	for ossa in BRACCIA:
		var a_l: int = sk.find_bone(str(ossa[0]))
		var g_l: int = sk.find_bone(str(ossa[1]))
		var a_r: int = sk.find_bone(str(ossa[2]))
		var g_r: int = sk.find_bone(str(ossa[3]))
		if a_l < 0 or g_l < 0 or a_r < 0 or g_r < 0:
			continue
		var b: Basis = sk.global_transform.basis
		var sl: Vector3 = b * sk.get_bone_global_pose(a_l).origin
		var el: Vector3 = b * sk.get_bone_global_pose(g_l).origin
		var sr: Vector3 = b * sk.get_bone_global_pose(a_r).origin
		var er: Vector3 = b * sk.get_bone_global_pose(g_r).origin
		var spalle: Vector3 = sr - sl
		if spalle.length() < 0.0001:
			return false
		spalle = spalle.normalized()
		var bl: Vector3 = el - sl
		var br: Vector3 = er - sr
		if bl.length() < 0.0001 or br.length() < 0.0001:
			return false
		var lato_l: float = absf(bl.normalized().dot(spalle))
		var lato_r: float = absf(br.normalized().dot(spalle))
		return lato_l > 0.80 and lato_r > 0.80
	return false


## Chi è: il primo antenato con uno script, il gruppo, e dove sta.
func _descrivi(sk: Skeleton3D) -> String:
	var n: Node = sk
	var chi := ""
	while n != null and n != get_tree().root:
		var sc: Script = n.get_script()
		if sc != null and not str(sc.resource_path).ends_with("animator.gd"):
			chi = "%s (%s)" % [str(n.name), str(sc.resource_path).get_file()]
			break
		n = n.get_parent()
	var p: Vector3 = sk.global_position
	return "%s  a (%.1f, %.1f, %.1f)  %s" % [chi, p.x, p.y, p.z,
		"" if sk.is_visible_in_tree() else "[ammucciato]"]
