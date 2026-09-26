extends SceneTree
## **'E mosse d''o pupo ncuollo a ll'ate cuorpe** (0.62).
##
## Il capo: *«Molti dei nuovi modelli che hai inserito non hanno animazioni.
## Prendi tutto quello che ti serve dalla cartella del progetto e dagli le
## animazioni»*.
##
## Gli otto omini (Low Poly Animated Men, 11 clip) e l'umano di Quaternius
## (7 clip) non sanno sedersi (l'umano), parlare, accovacciarsi, incassare
## un colpo, indicare, guidare: in tutti quei momenti restavano nella loro
## posa ferma. Il pupo (Universal Animation Library) ne ha 43.
##
## La 0.47 aveva provato a tradurre le clip da uno scheletro all'altro e
## aveva fatto un disastro: spalle storte e pose a T. Il motivo era
## tradurre le **rotazioni locali** delle ossa, che dipendono da come è
## orientato ogni osso nel suo scheletro. Qui si traduce **il movimento nel
## mondo**, osso per osso:
##
## 1. per ogni fotogramma della clip del pupo si calcola la posa globale di
##    ogni osso (risalendo la catena, come `posa_osso`);
## 2. per ogni osso si prende la rotazione **dal riposo alla posa**, nel
##    mondo (`delta = G_posa · G_riposo⁻¹`) — che non dipende dagli assi
##    dell'osso;
## 3. la si porta nel sistema del corpo di arrivo (`M`, costruito dalle
##    anche e dalla testa dei due scheletri: sinistra, su, avanti) e la si
##    applica al riposo dell'osso corrispondente;
## 4. braccia e gambe si correggono con la **direzione** dell'osso figlio
##    (la spalla punta dove punta quella del pupo), così una piccola
##    differenza fra le due pose di riposo non storce il braccio;
## 5. le rotazioni globali si riportano locali e si scrivono in una clip
##    nuova. Il bacino si sposta in proporzione all'altezza delle anche.
##
## Per gli omini c'è un pezzo in più: il piede è un osso di IK attaccato
## alla radice (`Foot.L`, padre `Bone`), non alla gamba. Si mette dove
## finisce lo stinco (`LowerLeg.L_end`).
##
## Uscita: `assets/models/omo_ual.res` e `assets/models/umano_q_ual.res`
## (AnimationLibrary). `human_builder.gd` le aggiunge al corpo col nome
## `ual`, e le tabelle `RIG` le usano come `ual/Sitting_Idle` ecc.
##
##   godot4 --headless --path . --script res://tools/retarget_ual.gd

const FPS := 30.0

## Le clip del pupo che si portano sugli altri corpi.
const CLIP := ["Idle", "Idle_Talking", "Walk", "Jog_Fwd", "Sprint",
	"Crouch_Idle", "Crouch_Fwd", "Sitting_Idle", "Sitting_Talking",
	"Sitting_Enter", "Sitting_Exit", "Driving", "Hit_Chest", "Hit_Head",
	"Interact", "PickUp_Table", "Punch_Cross", "Punch_Jab", "Sword_Attack",
	"Death01", "Push", "Dance", "Fixing_Kneeling", "Walk_Formal",
	"Pistol_Idle", "Pistol_Shoot", "Idle_Torch", "Jump"]

const CICLICHE := ["Idle", "Idle_Talking", "Walk", "Jog_Fwd", "Sprint",
	"Crouch_Idle", "Crouch_Fwd", "Sitting_Idle", "Sitting_Talking", "Driving",
	"Push", "Dance", "Fixing_Kneeling", "Walk_Formal", "Pistol_Idle",
	"Idle_Torch"]

const MAPPA_UMANO := {
	"pelvis": "Hips", "spine_01": "Spine", "spine_02": "Spine1",
	"spine_03": "Spine2", "neck_01": "Neck", "Head": "Head",
	"clavicle_l": "LeftShoulder", "upperarm_l": "LeftArm",
	"lowerarm_l": "LeftForeArm", "hand_l": "LeftHand",
	"clavicle_r": "RightShoulder", "upperarm_r": "RightArm",
	"lowerarm_r": "RightForeArm", "hand_r": "RightHand",
	"thigh_l": "LeftUpLeg", "calf_l": "LeftLeg", "foot_l": "LeftFoot",
	"ball_l": "LeftToeBase",
	"thigh_r": "RightUpLeg", "calf_r": "RightLeg", "foot_r": "RightFoot",
	"ball_r": "RightToeBase",
	"thumb_01_l": "LeftHandThumb2", "thumb_02_l": "LeftHandThumb3",
	"index_01_l": "LeftHandIndex1", "index_02_l": "LeftHandIndex2",
	"index_03_l": "LeftHandIndex3",
	"thumb_01_r": "RightHandThumb2", "thumb_02_r": "RightHandThumb3",
	"index_01_r": "RightHandIndex1", "index_02_r": "RightHandIndex2",
	"index_03_r": "RightHandIndex3",
}

const MAPPA_OMO := {
	"pelvis": "Body", "spine_01": "Hips", "spine_02": "Abdomen",
	"spine_03": "Torso", "neck_01": "Neck", "Head": "Head",
	"clavicle_l": "Shoulder.L", "upperarm_l": "UpperArm.L",
	"lowerarm_l": "LowerArm.L", "hand_l": "Palm.L",
	"middle_01_l": "MiddleHand.L", "middle_02_l": "Fingers.L",
	"thumb_01_l": "Thumb1.L", "thumb_02_l": "Thumb2.L",
	"clavicle_r": "Shoulder.R", "upperarm_r": "UpperArm.R",
	"lowerarm_r": "LowerArm.R", "hand_r": "Palm.R",
	"middle_01_r": "MiddleHand.R", "middle_02_r": "Fingers.R",
	"thumb_01_r": "Thumb1.R", "thumb_02_r": "Thumb2.R",
	"thigh_l": "UpperLeg.L", "calf_l": "LowerLeg.L", "foot_l": "Foot.L",
	"thigh_r": "UpperLeg.R", "calf_r": "LowerLeg.R", "foot_r": "Foot.R",
}

## (0.62) I sei corpi della biblioteca esterna (`CharacterArmature` di
## Quaternius): stessa famiglia degli omini, con un osso in più nella
## schiena (`Chest`) e il polso al posto del palmo. `Hips` resta com'è.
const MAPPA_QUAT := {
	"pelvis": "Body", "spine_01": "Abdomen", "spine_02": "Torso",
	"spine_03": "Chest", "neck_01": "Neck", "Head": "Head",
	"clavicle_l": "Shoulder.L", "upperarm_l": "UpperArm.L",
	"lowerarm_l": "LowerArm.L", "hand_l": "Wrist.L",
	"middle_01_l": "Middle1.L", "middle_02_l": "Middle2.L",
	"index_01_l": "Index1.L", "index_02_l": "Index2.L",
	"thumb_01_l": "Thumb1.L", "thumb_02_l": "Thumb2.L",
	"clavicle_r": "Shoulder.R", "upperarm_r": "UpperArm.R",
	"lowerarm_r": "LowerArm.R", "hand_r": "Wrist.R",
	"middle_01_r": "Middle1.R", "middle_02_r": "Middle2.R",
	"index_01_r": "Index1.R", "index_02_r": "Index2.R",
	"thumb_01_r": "Thumb1.R", "thumb_02_r": "Thumb2.R",
	"thigh_l": "UpperLeg.L", "calf_l": "LowerLeg.L", "foot_l": "Foot.L",
	"thigh_r": "UpperLeg.R", "calf_r": "LowerLeg.R", "foot_r": "Foot.R",
}

const Human := preload("res://scripts/human_builder.gd")

## Ossa lunghe: si correggono con la direzione verso il figlio (sorgente →
## figlio nella sorgente, arrivo → figlio nell'arrivo).
const LUNGHE := {
	"clavicle_l": "upperarm_l", "upperarm_l": "lowerarm_l", "lowerarm_l": "hand_l",
	"clavicle_r": "upperarm_r", "upperarm_r": "lowerarm_r", "lowerarm_r": "hand_r",
	"thigh_l": "calf_l", "calf_l": "foot_l", "thigh_r": "calf_r", "calf_r": "foot_r",
	"spine_03": "neck_01", "neck_01": "Head",
}

## Per gli omini: il figlio "vero" di un osso lungo nell'arrivo, quando il
## figlio mappato non sta nella sua catena (il piede IK).
const FIGLIO_ARRIVO_OMO := {"LowerLeg.L": "LowerLeg.L_end", "LowerLeg.R": "LowerLeg.R_end"}


func _initialize() -> void:
	var sorgente := _carica("res://assets/models/pupo.scn")
	var arrivi: Array = [["res://assets/models/umano_q.scn", MAPPA_UMANO,
			"res://assets/models/umano_q_ual.res", false],
			["res://assets/models/omo_casual.scn", MAPPA_OMO,
			"res://assets/models/omo_ual.res", true],
			# (0.62) Un modello solo basta: i sei corpi `quat` hanno lo
			# stesso scheletro.
			[str(Human.QUAT["quat_giacca"]), MAPPA_QUAT,
			"res://assets/models/quat_ual.res", true]]
	# `SOLO=quat` rifà solo la libreria dei corpi nuovi (le altre due
	# restano identiche byte per byte).
	if OS.get_environment("SOLO") != "":
		arrivi = arrivi.filter(func(a): return str(a[2]).contains(OS.get_environment("SOLO")))
	for arrivo in arrivi:
		var t := _carica(str(arrivo[0]))
		var lib := _traduci(sorgente, t, arrivo[1], bool(arrivo[3]))
		var err := ResourceSaver.save(lib, str(arrivo[2]))
		print("scritto %s (%d clip) err=%d" % [str(arrivo[2]),
			lib.get_animation_list().size(), err])
		(t["m"] as Node).free()
	(sorgente["m"] as Node).free()
	quit()


func _carica(p: String) -> Dictionary:
	var m: Node3D = (load(p) as PackedScene).instantiate()
	var sk: Skeleton3D = m.find_children("*", "Skeleton3D", true, false)[0]
	var ap: AnimationPlayer = m.find_children("*", "AnimationPlayer", true, false)[0]
	# Le clip `CharacterArmature|Walk` diventano `Walk` (serve per il
	# davanti, che si prende dalla camminata).
	Human._alias_quat(ap)
	var radice: Node = ap.get_node_or_null(ap.root_node)
	if radice == null:
		radice = ap.get_parent()
	var prefisso := str(m.get_path_to(sk))
	# Il prefisso delle tracce si legge da una clip vera.
	var clips := ap.get_animation_list()
	if clips.size() > 0:
		var a: Animation = ap.get_animation(clips[0])
		for k in a.get_track_count():
			var pth := str(a.track_get_path(k))
			if pth.contains(":"):
				prefisso = pth.split(":")[0]
				break
	# Le pose globali di riposo, in spazio scheletro.
	var riposo: Array = []
	for i in range(sk.get_bone_count()):
		riposo.append(sk.get_bone_global_rest(i))
	return {"m": m, "sk": sk, "ap": ap, "prefisso": prefisso, "riposo": riposo}


## Il sistema del corpo: X = sinistra, Y = su, Z = avanti, dalle anche e
## dalla testa.
func _corpo(sk: Skeleton3D, riposo: Array, anca_s: String, anca_d: String,
		bacino: String, testa: String) -> Basis:
	# `riposo` può essere anche una posa (le globali di un fotogramma).
	var ps: Vector3 = (riposo[sk.find_bone(anca_s)] as Transform3D).origin
	var pd: Vector3 = (riposo[sk.find_bone(anca_d)] as Transform3D).origin
	var pb: Vector3 = (riposo[sk.find_bone(bacino)] as Transform3D).origin
	var pt: Vector3 = (riposo[sk.find_bone(testa)] as Transform3D).origin
	# Il "su" non si prende dalla testa (una testa un po' avanti inclina
	# tutto il corpo): è il su del modello, portato nello spazio scheletro.
	var t := Transform3D()
	var n: Node = sk
	while n != null and n.get_parent() != null and n.get_parent() is Node3D:
		t = (n as Node3D).transform * t
		n = n.get_parent()
	var y: Vector3 = (t.basis.orthonormalized().inverse() * Vector3.UP).normalized()
	var x := (ps - pd)
	x = (x - y * x.dot(y)).normalized()
	var z := x.cross(y).normalized()
	var _dummy := pb + pt
	return Basis(x, y, z)


func _traduci(s: Dictionary, t: Dictionary, mappa: Dictionary,
		omo: bool) -> AnimationLibrary:
	var sks: Skeleton3D = s["sk"]
	var skt: Skeleton3D = t["sk"]
	var rs: Array = s["riposo"]
	var rt: Array = t["riposo"]
	var bs := _corpo(sks, rs, "thigh_l", "thigh_r", "pelvis", "Head")
	var bt_riposo := _corpo(skt, rt, str(mappa["thigh_l"]), str(mappa["thigh_r"]),
		str(mappa["pelvis"]), str(mappa["Head"]))
	# **'O davanti se piglia d''a camminata soja, no d''o riposo.** L'umano
	# di Quaternius sta a riposo girato di quarantacinque gradi, e le sue
	# clip lo raddrizzano col bacino; gli omini pure, di una trentina. Se il
	# davanti si prende dal riposo, ogni clip tradotta esce storta di tanto
	# quanto (prima foto: tutti di tre quarti). Si prende dalla sua `Walk`
	# a t=0, e `C` gira il riposo per metterlo dritto.
	var apt: AnimationPlayer = t["ap"]
	var bt := bt_riposo
	if apt.has_animation("Walk"):
		var gw: Array = _pose_globali(skt, apt.get_animation("Walk"), 0.0,
			str(t["prefisso"]))
		bt = _corpo(skt, gw, str(mappa["thigh_l"]), str(mappa["thigh_r"]),
			str(mappa["pelvis"]), str(mappa["Head"]))
	var C: Basis = bt * bt_riposo.inverse()
	var M: Basis = bt * bs.inverse()
	print("  C=%s  bt=%s  bt_riposo=%s" % [str(C), str(bt), str(bt_riposo)])
	# La scala: altezza delle anche sopra ai piedi.
	var h_s: float = ((rs[sks.find_bone("pelvis")] as Transform3D).origin
		- (rs[sks.find_bone("foot_l")] as Transform3D).origin).dot(bs.y)
	var h_t: float = ((rt[skt.find_bone(str(mappa["pelvis"]))] as Transform3D).origin
		- (rt[skt.find_bone(str(mappa["foot_l"]))] as Transform3D).origin).dot(bt.y)
	var k_pos: float = h_t / maxf(h_s, 0.00001)
	print("  corpo: k=%.5f  M=%s" % [k_pos, str(M)])

	# Ordine delle ossa di arrivo dal padre al figlio (l'indice lo garantisce
	# già in Godot, ma lo si ricontrolla).
	var inverso: Dictionary = {}
	for k in mappa:
		inverso[str(mappa[k])] = str(k)

	var ap: AnimationPlayer = s["ap"]
	var lib := AnimationLibrary.new()
	for nome in CLIP:
		if not ap.has_animation(nome):
			print("  manca %s" % nome)
			continue
		var a: Animation = ap.get_animation(nome)
		var nuova := Animation.new()
		nuova.length = a.length
		nuova.loop_mode = Animation.LOOP_LINEAR if CICLICHE.has(nome) \
			else Animation.LOOP_NONE
		var tracce: Dictionary = {}
		for b_t in range(skt.get_bone_count()):
			var nome_t := skt.get_bone_name(b_t)
			if not inverso.has(nome_t):
				continue
			var tr := nuova.add_track(Animation.TYPE_ROTATION_3D)
			nuova.track_set_path(tr, NodePath("%s:%s" % [t["prefisso"], nome_t]))
			tracce[b_t] = tr
		# Le posizioni: il bacino, e per gli omini i due piedi (IK).
		var pos_tracce: Dictionary = {}
		var da_spostare: Array = [skt.find_bone(str(mappa["pelvis"]))]
		if omo:
			da_spostare.append(skt.find_bone("Foot.L"))
			da_spostare.append(skt.find_bone("Foot.R"))
		for b in da_spostare:
			var trp := nuova.add_track(Animation.TYPE_POSITION_3D)
			nuova.track_set_path(trp, NodePath("%s:%s" % [t["prefisso"],
				skt.get_bone_name(b)]))
			pos_tracce[b] = trp

		var passi: int = maxi(1, int(ceil(a.length * FPS)))
		for f in range(passi + 1):
			var tempo: float = minf(float(f) / FPS, a.length)
			var gs: Array = _pose_globali(sks, a, tempo, s["prefisso"])
			var gt: Array = _arrivo(sks, skt, rs, rt, gs, mappa, inverso, M,
				k_pos, omo, C)
			for b_t in tracce:
				var par: int = skt.get_bone_parent(b_t)
				var loc: Transform3D = gt[b_t] if par < 0 \
					else (gt[par] as Transform3D).affine_inverse() * (gt[b_t] as Transform3D)
				nuova.rotation_track_insert_key(tracce[b_t], tempo,
					loc.basis.get_rotation_quaternion().normalized())
			for b in pos_tracce:
				var par2: int = skt.get_bone_parent(b)
				var loc2: Transform3D = gt[b] if par2 < 0 \
					else (gt[par2] as Transform3D).affine_inverse() * (gt[b] as Transform3D)
				nuova.position_track_insert_key(pos_tracce[b], tempo, loc2.origin)
		lib.add_animation(nome, nuova)
	return lib


## Le pose globali (spazio scheletro) di tutte le ossa della sorgente.
func _pose_globali(sk: Skeleton3D, a: Animation, tempo: float,
		prefisso: String) -> Array:
	var g: Array = []
	g.resize(sk.get_bone_count())
	for i in range(sk.get_bone_count()):
		var rest: Transform3D = sk.get_bone_rest(i)
		var pos: Vector3 = rest.origin
		var rot: Quaternion = rest.basis.get_rotation_quaternion()
		var sc: Vector3 = rest.basis.get_scale()
		var pth := NodePath("%s:%s" % [prefisso, sk.get_bone_name(i)])
		var tp := a.find_track(pth, Animation.TYPE_POSITION_3D)
		var tr := a.find_track(pth, Animation.TYPE_ROTATION_3D)
		var ts := a.find_track(pth, Animation.TYPE_SCALE_3D)
		if tp >= 0:
			pos = a.position_track_interpolate(tp, tempo)
		if tr >= 0:
			rot = a.rotation_track_interpolate(tr, tempo)
		if ts >= 0:
			sc = a.scale_track_interpolate(ts, tempo)
		var loc := Transform3D(Basis(rot).scaled(sc), pos)
		var par := sk.get_bone_parent(i)
		g[i] = loc if par < 0 else (g[par] as Transform3D) * loc
	return g


## Le pose globali dell'arrivo, dalle globali della sorgente.
func _arrivo(sks: Skeleton3D, skt: Skeleton3D, rs: Array, rt: Array,
		gs: Array, mappa: Dictionary, inverso: Dictionary, M: Basis,
		k_pos: float, omo: bool, C: Basis = Basis()) -> Array:
	var gt: Array = []
	gt.resize(skt.get_bone_count())
	var Minv: Basis = M.inverse()
	for b_t in range(skt.get_bone_count()):
		var nome_t := skt.get_bone_name(b_t)
		var par: int = skt.get_bone_parent(b_t)
		var rest_loc: Transform3D = skt.get_bone_rest(b_t)
		# Senza corrispondenza: resta al riposo rispetto al padre.
		var glob: Transform3D = rest_loc if par < 0 \
			else (gt[par] as Transform3D) * rest_loc
		if inverso.has(nome_t):
			var nome_s: String = inverso[nome_t]
			var b_s: int = sks.find_bone(nome_s)
			var Rs: Basis = (rs[b_s] as Transform3D).basis.orthonormalized()
			var Ps: Basis = (gs[b_s] as Transform3D).basis.orthonormalized()
			var delta: Basis = Ps * Rs.inverse()
			var delta_t: Basis = M * delta * Minv
			var Rt: Transform3D = rt[b_t]
			var Rt_b: Basis = (C * Rt.basis.orthonormalized()).orthonormalized()
			var sc_t: Vector3 = glob.basis.get_scale()
			var nuova_b: Basis = (delta_t * Rt_b).orthonormalized()
			# La direzione: l'osso lungo punta dove punta quello del pupo.
			if LUNGHE.has(nome_s):
				var figlio_s: int = sks.find_bone(str(LUNGHE[nome_s]))
				var figlio_nome_t: String = str(mappa.get(LUNGHE[nome_s], ""))
				if omo and FIGLIO_ARRIVO_OMO.has(nome_t):
					figlio_nome_t = str(FIGLIO_ARRIVO_OMO[nome_t])
				var figlio_t: int = skt.find_bone(figlio_nome_t)
				if figlio_s >= 0 and figlio_t >= 0:
					var d_s: Vector3 = (M * ((gs[figlio_s] as Transform3D).origin
						- (gs[b_s] as Transform3D).origin)).normalized()
					var d_rest_t: Vector3 = C * ((rt[figlio_t] as Transform3D).origin \
						- Rt.origin)
					var d_loc: Vector3 = Rt_b.inverse() * d_rest_t
					var d_ora: Vector3 = (nuova_b * d_loc).normalized()
					if d_ora.length() > 0.5 and d_s.length() > 0.5:
						var q := _arco(d_ora, d_s)
						nuova_b = (Basis(q) * nuova_b).orthonormalized()
			glob = Transform3D(nuova_b.scaled(sc_t), glob.origin)
			# Il bacino si sposta come quello del pupo, in proporzione.
			if nome_s == "pelvis":
				var sp: Vector3 = (gs[b_s] as Transform3D).origin \
					- (rs[b_s] as Transform3D).origin
				glob.origin = Rt.origin + M * sp * k_pos
		gt[b_t] = glob
		# 'O pede 'e ll'omo: sta addò fernesce 'o stinco.
		if omo and (nome_t == "LowerLeg.L_end" or nome_t == "LowerLeg.R_end"):
			pass
	if omo:
		for lato in ["L", "R"]:
			var fine: int = skt.find_bone("LowerLeg.%s_end" % lato)
			var piede: int = skt.find_bone("Foot.%s" % lato)
			if fine >= 0 and piede >= 0:
				var g: Transform3D = gt[piede]
				gt[piede] = Transform3D(g.basis, (gt[fine] as Transform3D).origin)
	return gt


func _arco(a: Vector3, b: Vector3) -> Quaternion:
	a = a.normalized()
	b = b.normalized()
	var c := a.cross(b)
	var d := a.dot(b)
	if d < -0.9999:
		var asse := Vector3.UP.cross(a)
		if asse.length() < 0.01:
			asse = Vector3.RIGHT.cross(a)
		return Quaternion(asse.normalized(), PI)
	return Quaternion(c.x, c.y, c.z, 1.0 + d).normalized()
