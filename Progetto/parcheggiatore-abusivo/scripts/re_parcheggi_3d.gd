extends CharacterBody3D
## 'O Rre d''e Parcheggi (0.64)
##
## **Chi è.** Don Vicienzo Cuoppo, detto 'O Rre d''e Parcheggi: trent'anni di
## piazze, dice lui, e mai una multa. Grosso, pelato, la corona d'oro in
## testa (di latta), gli occhiali neri, il sigaro, la catena con la P, il
## mantello rosso col collo d'ermellino (finto) e in mano la paletta, che
## tiene come uno scettro. Non è un boss da menare: è uno che ti misura.
##
## **Cosa fa** (il capo, alla 0.64): *«alla terza giornata viene questo
## figuro che ti sfida: "ah, e tu vulisse fà 'o parcheggiatore? E famme
## verè". Sfida a tempo, con una musichetta e il tic tac: devi posteggiare
## più macchine possibile in un minuto. Se ne posteggi almeno cinque ti dà
## una piazza in omaggio, almeno tre un guaglione che lavora per te, una
## sola ti insegue e ti picchia: "ma arò t'avvie, omm' 'e sfaccimma, va' a
## faticà va'".»*
##
## **Come va, passo per passo.**
##
##   1. Dal terzo giorno (`GameManager.re_oggi`), quando stai in servizio in
##      una piazza tua da almeno quaranta secondi, senza stelle, senza
##      Borrelli e senza una macchina in mano, arriva a piedi da venti
##      metri.
##   2. Ti dice la frase e aspetta la risposta: **[E] accietta**. Se non
##      rispondi, dopo venti secondi comincia lui. La sfida si fa solo in una
##      piazza tua: se ne esci, ti segue.
##   3. Tre, doje, una, VIA: un minuto. Le macchine le chiama lui (arrivano
##      di corsa, non si spazientiscono, non pagano e se ne vanno appena
##      posteggiate); il rubinetto normale di quella piazza si ferma. Conta
##      ogni macchina che metti **dentro a un posto** (con F, fuori dalle
##      strisce, non vale). Musica sua e tic tac.
##   4. Com'è finita lo decide `GameManager.re_esito`: cinque o più una
##      piazza (o i soldi, se le tieni tutte), tre o quattro un guaglione
##      (o i soldi), due niente, una o zero le mazzate. Chi non vince lo
##      rivede fra tre giorni.

enum Stato { NASCOSTO, ARRIVA, INVITA, CONTO, SFIDA, ESITO, MENA, STESO, SE_NE_VA }

const Human := preload("res://scripts/human_builder.gd")
const Tex := preload("res://scripts/textures.gd")
const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const KO := preload("res://scripts/knockout.gd")
const SfidaHud := preload("res://scripts/sfida_hud.gd")
const CammVia := preload("res://scripts/cammino.gd")

const NOME := "'O Rre d''e Parcheggi"
const VEL_CAMMINA: float = 3.3
## Più svelto di te che cammini (4,8), più lento di te che corri (8,2): le
## mazzate si evitano, ma costa fiato.
const VEL_MENA: float = 5.6
const ASPETTA_PRIMMA: float = 40.0
const INVITO_MAX: float = 20.0
const CONTO_DURATA: float = 3.2
const ESITO_DURATA: float = 4.5
const MENA_DURATA: float = 14.0
const MENA_DANNO: float = 12.0
const MENA_OGNI: float = 1.1
const MENA_BOTTE_MAX: int = 3
const MENA_PORTATA: float = 1.8
## Quanti punti ha se glieli dai tu mentre ti mena (se lo stendi, se ne va).
const HP_MAX: int = 46

const DETTO_ARRIVO := "Ah, e tu vulisse fà 'o parcheggiatore? E famme verè."
const DETTO_INVITO := [
	"Nu minuto. Chiù machine miette dint'ê strisce, chiù te stimo.",
	"Cinche machine e te regalo 'na piazza. Tre, e te dongo 'nu guaglione.",
	"E si ne miette una sola… so' mazzate, guagliò.",
]
const DETTO_PAURA := "Tiene paura? E io accummencio 'o stesso!"
const DETTO_FORE := "'A sfida se fa 'n piazza toja, no ccà. Jammo!"
const DETTE_CONTE := ["Una!", "Doje!", "Tre! 'O guaglione è tuojo!", "Quatto!",
	"Cinche! Mannaggia 'a miseria…", "Seje! Ma tu sî 'nu drago!",
	"Sette?! Mo' me miette paura tu a me!"]
const DETTE_SFOTTO := [
	"Chiano chiano, comme 'a nonna mia!", "E chesta sarria 'na manovra?",
	"Tic tac, guagliò!", "'O tiempo passa e tu staje llà!",
	"Io a l'età toja ne mettevo diece!", "Muovete, ca se fa notte!",
	"Uh Maronna, 'o muro! Attiento!", "Vaje, vaje, vaje!",
]
const DETTO_FORE_STRISCE := "Fore d''e strisce nun vale, guagliò!"
const DETTO_MAZZATE := "Ma arò t'avvie, omm' 'e sfaccimma?! Va' a faticà, va'!"
const DETTE_BOTTE := ["Va' a faticà!", "Omm' 'e sfaccimma!", "Arò t'avvie?!",
	"Parcheggiatore tu?!", "Tiè!"]
const DETTO_SE_NE_VA_MENA := "E mo' vattenne a faticà, va'."
const DETTO_STESO := "Uh… va buo', va buo'. Ma a faticà ce vaje 'o stesso."
const DETTO_ANNULLA := "Tiene già chi te cerca. Ce vedimmo n'ata vota, guagliò."

var stato: int = Stato.NASCOSTO
var hp: int = HP_MAX

var _visual: Node3D
var _anim: Node = null
var _bubble: Node3D
var _ko: Dictionary = KO.make_state()
var _targhetta: Label3D
var _brace: MeshInstance3D = null
var _fumo_sigaro: CPUParticles3D = null

var _t: float = 0.0
var _turno_visto: float = 0.0
var _guarda_t: float = 0.0
var _zona: String = ""
var _contate: int = 0
var _hud: CanvasLayer = null
var _secondo: int = -1
var _tic: bool = true
var _sfotto_t: float = 6.0
var _rifornisci_t: float = 0.0
var _botte: int = 0
var _mena_cd: float = 0.0
var _esito: Dictionary = {}
var _tribuna := Vector3.INF
var _via := Vector3.INF
var _detto_invito: int = 0


func _ready() -> void:
	add_to_group("re_parcheggi")
	collision_layer = 0
	collision_mask = 0
	_build_visual()
	_build_collision()
	_bubble = SpeechBubbleScript.new()
	_bubble.position = Vector3(0, 2.45, 0)
	add_child(_bubble)
	_nascondi()


func _build_collision() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.95
	shape.shape = capsule
	shape.position = Vector3(0, 0.98, 0)
	add_child(shape)


func _di(testo: String, durata: float = 2.8) -> void:
	if _bubble:
		_bubble.say(testo, durata)
	GameManager.directing_gesture.emit("« 'O Rre »: " + testo, true)
	if _anim != null and _anim.has_method("parla_per"):
		_anim.parla_per(minf(durata, 2.4))


func _nascondi() -> void:
	stato = Stato.NASCOSTO
	visible = false
	collision_layer = 0
	global_position = Vector3(95.0, -40.0, 86.0)


func _mostra(dove: Vector3) -> void:
	visible = true
	collision_layer = 4
	global_position = dove
	hp = HP_MAX


# ---------------------------------------------------------------------------
# 'O modello: 'o Rre, da capo a piede
# ---------------------------------------------------------------------------

func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	# Camicia di raso cremisi, pantaloni neri, pancione, pelato coi baffi.
	var parts := Human.build(Color(0.58, 0.07, 0.13), Color(0.08, 0.08, 0.1),
		"", 1.9, {
			"corpo": "panzone", "belly": 1.0,
			"skin": Color(0.80, 0.62, 0.47), "hair": Color(0.10, 0.08, 0.07),
			"bald": true, "moustache": true,
		})
	_visual.add_child(parts["root"])
	_anim = parts.get("anim", null)
	var ossa: Dictionary = parts.get("bones", {})
	var testa: Node3D = parts.get("head", null)

	var oro := Tex.flat(Color(0.95, 0.74, 0.22), 0.28, 0.85, 0.5)
	var oro_scuro := Tex.flat(Color(0.72, 0.52, 0.12), 0.35, 0.8, 0.4)
	var rosso := Tex.flat(Color(0.66, 0.05, 0.08), 0.7, 0.0, 0.05)
	var bianco := Tex.flat(Color(0.96, 0.95, 0.92), 0.9)
	var nero := Tex.flat(Color(0.03, 0.03, 0.035), 0.25, 0.3, 0.6)

	if testa != null:
		_corona(testa, oro, oro_scuro)
		_occhiali(testa, nero, oro)
		_sigaro(testa)
	var petto: Node3D = ossa.get("chest", null)
	if petto != null:
		_catena(petto, oro)
		_mantello(petto, rosso, bianco, oro)
	var mano: Node3D = ossa.get("hand_r", null)
	if mano != null:
		_paletta(mano, oro, rosso, bianco)

	_targhetta = Label3D.new()
	_targhetta.text = "'O RRE D''E PARCHEGGI"
	_targhetta.position = Vector3(0, 2.72, 0)
	_targhetta.font_size = 46
	_targhetta.pixel_size = 0.0024
	_targhetta.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_targhetta.modulate = Color(1.0, 0.82, 0.3)
	_targhetta.outline_size = 16
	_targhetta.outline_modulate = Color(0.25, 0.05, 0.02)
	_visual.add_child(_targhetta)


func _mesh(padre: Node3D, m: Mesh, pos: Vector3, mat: Material,
		rot: Vector3 = Vector3.ZERO, scala: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.position = pos
	mi.rotation = rot
	mi.scale = scala
	mi.material_override = mat
	padre.add_child(mi)
	return mi


## 'A corona: una fascia d'oro coi cinque punti, le pietre rosse e blu.
## Sull'osso della testa il davanti è +Z e la cima sta verso 0,24.
func _corona(testa: Node3D, oro: Material, oro_scuro: Material) -> void:
	var fascia := CylinderMesh.new()
	fascia.top_radius = 0.132
	fascia.bottom_radius = 0.124
	fascia.height = 0.075
	fascia.radial_segments = 16
	_mesh(testa, fascia, Vector3(0, 0.215, 0.0), oro)
	var orlo := TorusMesh.new()
	orlo.inner_radius = 0.118
	orlo.outer_radius = 0.136
	orlo.rings = 16
	orlo.ring_segments = 6
	_mesh(testa, orlo, Vector3(0, 0.18, 0.0), oro_scuro)
	for i in range(5):
		var a: float = TAU * float(i) / 5.0
		var punta := CylinderMesh.new()
		punta.top_radius = 0.0
		punta.bottom_radius = 0.035
		punta.height = 0.09
		punta.radial_segments = 4
		_mesh(testa, punta, Vector3(sin(a) * 0.118, 0.295, cos(a) * 0.118), oro)
		var palla := SphereMesh.new()
		palla.radius = 0.013
		palla.height = 0.026
		_mesh(testa, palla, Vector3(sin(a) * 0.118, 0.345, cos(a) * 0.118), oro)
	for g in [[0.0, Color(0.85, 0.08, 0.1)], [0.9, Color(0.1, 0.3, 0.9)],
			[-0.9, Color(0.1, 0.3, 0.9)]]:
		var pietra := SphereMesh.new()
		pietra.radius = 0.019
		pietra.height = 0.03
		var mat := Tex.flat(g[1], 0.15, 0.3, 0.8)
		mat.emission_enabled = true
		mat.emission = g[1]
		mat.emission_energy_multiplier = 0.4
		_mesh(testa, pietra, Vector3(sin(g[0]) * 0.134, 0.215, cos(g[0]) * 0.134), mat)


## Gli occhiali neri a mascherina, con la montatura d'oro, **davanti agli
## occhi**: alla prima foto stavano quattro centimetri più su, sulla fronte,
## e sembravano due sopracciglia finte. Gli occhi del pupo stanno a y 0,117
## sull'osso della testa e sporgono fino a z 0,135.
func _occhiali(testa: Node3D, nero: Material, oro: Material) -> void:
	for ex in [-0.052, 0.052]:
		var lente := BoxMesh.new()
		lente.size = Vector3(0.064, 0.04, 0.012)
		_mesh(testa, lente, Vector3(ex, 0.117, 0.146), nero, Vector3(0, 0, -ex * 1.5))
		var asta := BoxMesh.new()
		asta.size = Vector3(0.008, 0.008, 0.13)
		_mesh(testa, asta, Vector3(signf(ex) * 0.1, 0.124, 0.078), oro)
	var ponte := BoxMesh.new()
	ponte.size = Vector3(0.046, 0.01, 0.01)
	_mesh(testa, ponte, Vector3(0, 0.126, 0.151), oro)
	var sopra := BoxMesh.new()
	sopra.size = Vector3(0.172, 0.008, 0.012)
	_mesh(testa, sopra, Vector3(0, 0.139, 0.148), oro)


## 'O sigaro all'angolo della bocca, con la brace e un filo di fumo.
func _sigaro(testa: Node3D) -> void:
	var s := CylinderMesh.new()
	s.top_radius = 0.011
	s.bottom_radius = 0.013
	s.height = 0.14
	s.radial_segments = 8
	var m := _mesh(testa, s, Vector3(0.035, 0.066, 0.178), Tex.flat(Color(0.33, 0.19, 0.09), 0.8),
		Vector3(PI * 0.5 - 0.18, 0.28, 0))
	var anello := CylinderMesh.new()
	anello.top_radius = 0.0135
	anello.bottom_radius = 0.0135
	anello.height = 0.016
	_mesh(m, anello, Vector3(0, -0.035, 0), Tex.flat(Color(0.85, 0.12, 0.1), 0.4))
	var brace := SphereMesh.new()
	brace.radius = 0.012
	brace.height = 0.02
	var bm := Tex.flat(Color(1.0, 0.45, 0.1), 0.5)
	bm.emission_enabled = true
	bm.emission = Color(1.0, 0.4, 0.08)
	bm.emission_energy_multiplier = 2.5
	_brace = _mesh(m, brace, Vector3(0, 0.07, 0), bm)
	_fumo_sigaro = CPUParticles3D.new()
	_fumo_sigaro.amount = 10
	_fumo_sigaro.lifetime = 1.6
	_fumo_sigaro.direction = Vector3(0, 1, 0)
	_fumo_sigaro.spread = 12.0
	_fumo_sigaro.initial_velocity_min = 0.12
	_fumo_sigaro.initial_velocity_max = 0.22
	_fumo_sigaro.gravity = Vector3(0, 0.05, 0)
	_fumo_sigaro.scale_amount_min = 0.03
	_fumo_sigaro.scale_amount_max = 0.07
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 6
	sm.rings = 3
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.8, 0.8, 0.8, 0.35)
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.material = fm
	_fumo_sigaro.mesh = sm
	_brace.add_child(_fumo_sigaro)


## 'A catena d'oro grossa, e sotto la medaglia con la P.
func _catena(petto: Node3D, oro: Material) -> void:
	var giro := TorusMesh.new()
	giro.inner_radius = 0.125
	giro.outer_radius = 0.148
	giro.rings = 20
	giro.ring_segments = 6
	_mesh(petto, giro, Vector3(0, 0.2, 0.05), oro, Vector3(deg_to_rad(62.0), 0, 0),
		Vector3(1.0, 1.0, 1.25))
	var med := CylinderMesh.new()
	med.top_radius = 0.055
	med.bottom_radius = 0.055
	med.height = 0.014
	med.radial_segments = 18
	_mesh(petto, med, Vector3(0, 0.02, 0.205), oro, Vector3(PI * 0.5, 0, 0))
	var p := Label3D.new()
	p.text = "P"
	p.font_size = 64
	p.pixel_size = 0.0014
	p.modulate = Color(0.45, 0.28, 0.02)
	p.outline_size = 0
	p.double_sided = false
	p.position = Vector3(0, 0.02, 0.214)
	petto.add_child(p)


## 'O mantello: comme scende. Anelli dall'alto in basso, sull'osso del
## petto (dietro è −Z): altezza, mezza larghezza, mezza profondità. Stretto
## sotto al collo d'ermellino, si apre subito sopra alle spalle e poi si
## allarga piano fino alle ginocchia, così cammina senza toccare le gambe.
const MANTELLO_PROFILO := [
	[0.25, 0.21, 0.17],
	[0.15, 0.30, 0.21],
	[-0.10, 0.35, 0.25],
	[-0.45, 0.40, 0.30],
	[-0.92, 0.46, 0.36],
]
## Fin dove gira attorno ai fianchi: mezzo angolo, contato da dietro.
## Poco più di 90°: i bordi stanno di fianco, le braccia escono davanti.
const MANTELLO_GIRO: float = 1.62


## 'O mantello rosso: dalle spalle alle ginocchia, col collo d'ermellino
## bianco a macchie nere, l'orlo d'oro e la P grossa dietro.
##
## (0.64, rifatto dopo la prima foto) Era 'na tavola dritta appoggiata alla
## schiena: da dietro 'nu cartellone, di lato 'na riga. Adesso è un telo
## curvo che gira attorno ai fianchi e si allarga verso il basso, in due
## strati — fuori rosso, dentro foderato d'oro, che si vede dal davanti
## nell'apertura. Tutti e due senza faccia nascosta (`CULL_DISABLED`): lo
## strato di fuori copre quello di dentro da dietro, e viceversa dal
## davanti, e il verso dei triangoli non conta.
func _mantello(petto: Node3D, rosso: Material, bianco: Material, oro: Material) -> void:
	var fuori := (rosso as StandardMaterial3D).duplicate() as StandardMaterial3D
	fuori.cull_mode = BaseMaterial3D.CULL_DISABLED
	var fodera := Tex.flat(Color(0.86, 0.62, 0.16), 0.45, 0.35, 0.3)
	fodera.cull_mode = BaseMaterial3D.CULL_DISABLED
	var bordo := (oro as StandardMaterial3D).duplicate() as StandardMaterial3D
	bordo.cull_mode = BaseMaterial3D.CULL_DISABLED
	var p: Array = MANTELLO_PROFILO
	var a: float = MANTELLO_GIRO
	_mesh(petto, _telo(p, -a, a, 0.0), Vector3.ZERO, fuori)
	_mesh(petto, _telo(p, -a, a, -0.012), Vector3.ZERO, fodera)
	# L'orlo: gli ultimi sette centimetri, un filo più in fuori.
	var giu: Array = p[p.size() - 1]
	var orlo: Array = [_anello_mantello(giu[0] + 0.07), giu]
	_mesh(petto, _telo(orlo, -a, a, 0.007, 24), Vector3.ZERO, bordo)
	# I due bordi davanti, dall'alto all'orlo.
	for s in [-1.0, 1.0]:
		var da: float = s * a
		var a2: float = s * (a - 0.075)
		_mesh(petto, _telo(p, minf(da, a2), maxf(da, a2), 0.007, 2), Vector3.ZERO, bordo)
	# 'A P grossa in mezzo alla schiena, posata sul telo: il telo lì pende
	# all'indietro, e la scritta pende con lui.
	var y_p: float = -0.34
	var su: Array = _anello_mantello(y_p + 0.05)
	var sotto: Array = _anello_mantello(y_p - 0.05)
	var r: Array = _anello_mantello(y_p)
	var pendenza: float = (float(sotto[2]) - float(su[2])) / 0.1
	var fuori_n := Vector3(0, pendenza, -1).normalized()
	var destra := Vector3(-1, 0, 0)
	var stemma := Label3D.new()
	stemma.text = "P"
	stemma.font_size = 220
	stemma.pixel_size = 0.0018
	stemma.modulate = Color(1.0, 0.8, 0.25)
	stemma.outline_size = 10
	stemma.outline_modulate = Color(0.4, 0.2, 0.0)
	stemma.double_sided = false
	stemma.transform = Transform3D(Basis(destra, fuori_n.cross(destra), fuori_n),
		Vector3(0, y_p, -(float(r[2]) + 0.014)))
	petto.add_child(stemma)
	# 'O collo d'ermellino.
	var collo := TorusMesh.new()
	collo.inner_radius = 0.13
	collo.outer_radius = 0.215
	collo.rings = 20
	collo.ring_segments = 8
	var c := _mesh(petto, collo, Vector3(0, 0.23, 0.0), bianco, Vector3(deg_to_rad(12.0), 0, 0),
		Vector3(1.15, 0.8, 1.0))
	var macchia := Tex.flat(Color(0.05, 0.05, 0.05), 0.9)
	for i in range(9):
		var am: float = TAU * float(i) / 9.0 + 0.2
		var punto := BoxMesh.new()
		punto.size = Vector3(0.02, 0.03, 0.02)
		_mesh(c, punto, Vector3(sin(am) * 0.175, 0.04, cos(am) * 0.175), macchia)


## L'anello del mantello a una certa altezza, tra quelli del profilo.
func _anello_mantello(y: float) -> Array:
	var p: Array = MANTELLO_PROFILO
	for j in range(p.size() - 1):
		var a: Array = p[j]
		var b: Array = p[j + 1]
		if y <= float(a[0]) and y >= float(b[0]):
			var k: float = (float(a[0]) - y) / maxf(0.0001, float(a[0]) - float(b[0]))
			return [y, lerpf(a[1], b[1], k), lerpf(a[2], b[2], k)]
	return (p[0] if y > float(p[0][0]) else p[p.size() - 1]).duplicate()


## Un telo curvo: per ogni coppia di anelli del profilo, una fascia di
## `seg` spicchi da `a0` ad `a1` (angolo contato da dietro, −Z). `d`
## allarga (o stringe) tutto l'anello: serve a mettere fodera e bordi un
## filo dentro o fuori dal rosso.
static func _telo(profilo: Array, a0: float, a1: float, d: float, seg: int = 20) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(profilo.size() - 1):
		var su: Array = profilo[j]
		var giu: Array = profilo[j + 1]
		for i in range(seg):
			var ta: float = lerpf(a0, a1, float(i) / float(seg))
			var tb: float = lerpf(a0, a1, float(i + 1) / float(seg))
			var p00 := _punto_telo(su, ta, d)
			var p01 := _punto_telo(su, tb, d)
			var p10 := _punto_telo(giu, ta, d)
			var p11 := _punto_telo(giu, tb, d)
			st.add_vertex(p00)
			st.add_vertex(p01)
			st.add_vertex(p11)
			st.add_vertex(p00)
			st.add_vertex(p11)
			st.add_vertex(p10)
	st.generate_normals()
	return st.commit()


static func _punto_telo(anello: Array, t: float, d: float) -> Vector3:
	return Vector3(sin(t) * (float(anello[1]) + d), float(anello[0]),
		-cos(t) * (float(anello[2]) + d))


## 'A paletta, tenuta come 'nu scettro: manico d'oro, disco rosso e bianco.
##
## (0.64, dopo la foto) Il manico va **in su e un poco avanti**, fuori dal
## braccio. Sulla mano del pupo "giù" è +Y, ma −Y non è "su": a riposo va
## su e *indietro*, lungo l'avambraccio — e la paletta spuntava dietro la
## spalla, attraverso il mantello. Il verso giusto si calcola dagli assi
## misurati della mano nella posa di riposo (`POSA_PUPO`, modello grezzo
## con +Z davanti e la destra del pupo a −X), e il disco guarda avanti.
func _paletta(mano: Node3D, oro: Material, rosso: Material, bianco: Material) -> void:
	var ax: Array = Human.POSA_PUPO["hand_r"]
	var su_m := Vector3(-0.10, 0.93, 0.35).normalized()
	var av_m := Vector3(0, 0, 1)
	var su_l := Vector3(su_m.dot(ax[0]), su_m.dot(ax[1]), su_m.dot(ax[2]))
	var av_l := Vector3(av_m.dot(ax[0]), av_m.dot(ax[1]), av_m.dot(ax[2]))
	var y_b: Vector3 = -su_l.normalized()
	var z_b: Vector3 = (av_l - y_b * av_l.dot(y_b)).normalized()
	var r := Node3D.new()
	r.transform = Transform3D(Basis(y_b.cross(z_b), y_b, z_b), Vector3(0, 0.07, 0.02))
	mano.add_child(r)
	var manico := CylinderMesh.new()
	manico.top_radius = 0.016
	manico.bottom_radius = 0.016
	manico.height = 0.3
	_mesh(r, manico, Vector3(0, -0.12, 0), oro)
	var disco := CylinderMesh.new()
	disco.top_radius = 0.105
	disco.bottom_radius = 0.105
	disco.height = 0.016
	disco.radial_segments = 20
	var d := _mesh(r, disco, Vector3(0, -0.37, 0), rosso, Vector3(PI * 0.5, 0, 0))
	var anello := TorusMesh.new()
	anello.inner_radius = 0.085
	anello.outer_radius = 0.108
	anello.rings = 20
	anello.ring_segments = 6
	_mesh(d, anello, Vector3.ZERO, bianco)
	var mezzo := CylinderMesh.new()
	mezzo.top_radius = 0.045
	mezzo.bottom_radius = 0.045
	mezzo.height = 0.02
	_mesh(d, mezzo, Vector3.ZERO, bianco)


# ---------------------------------------------------------------------------
# Quanno vene
# ---------------------------------------------------------------------------

func _giocatore() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D


## Vero se il giocatore sta dentro a una piazza sua, adesso.
func _in_piazza_soja() -> bool:
	var z: String = GameManager.zona_corrente
	return z != "" and GameManager.zona_mia(z) and GameManager.in_servizio \
		and not GameManager.dentro_casa


func _pronto_a_venire() -> bool:
	if not GameManager.shift_active or GameManager.giornata_scaduta:
		return false
	if not GameManager.re_oggi() or GameManager.re_sfida_attiva:
		return false
	if GameManager.boss_phase or GameManager.boss_spawned or GameManager.stelle > 0:
		return false
	if GameManager.arrested or GameManager.hospitalized or GameManager.intro_active:
		return false
	if _turno_visto < ASPETTA_PRIMMA or not _in_piazza_soja():
		return false
	var pl := _giocatore()
	if pl == null or pl.get("directing_car") != null or GameManager.auto_guidata != null:
		return false
	return true


## Nasce a una ventina di metri da te, in strada, dove si arriva a piedi
## (la stessa regola di Borrelli, `zone_vicolo_3d._nasce_borrelli`).
func _dove_nasce() -> Vector3:
	var pl := _giocatore()
	var c: Vector3 = pl.global_position if pl else Vector3(31, 0, 33)
	var giro0: float = randf() * TAU
	for r in [22.0, 18.0, 26.0, 14.0]:
		for k in range(12):
			var a: float = giro0 + float(k) * TAU / 12.0
			var q := Vector3(c.x + cos(a) * r, 0.0, c.z + sin(a) * r)
			if q.x < 1.0 or q.x > 189.0 or q.z < 1.0 or q.z > 171.0:
				continue
			if not CammVia.libera(q) or not CammVia.raggiungibile(q):
				continue
			q.y = Collina.alzata(q.x, q.z)
			return q
	return Vector3(c.x + 6.0, c.y, c.z)


## Si presenta. Lo chiama `_physics_process` (e le prove).
func arriva() -> void:
	_mostra(_dove_nasce())
	stato = Stato.ARRIVA
	_t = 30.0
	SoundManager.play("clacson_lungo", -6.0, 0.8)
	GameManager.avvisa_strada("Sta arrivanno 'O RRE D''E PARCHEGGI. Te vò parlà.")
	_di("Addò sta chisto ca se chiamma parcheggiatore?", 2.5)


func _physics_process(delta: float) -> void:
	if GameManager.shift_active and not GameManager.intro_active:
		_turno_visto += delta
	if _brace != null and visible:
		_brace.scale = Vector3.ONE * (1.0 + 0.25 * sin(Time.get_ticks_msec() * 0.006))
	match stato:
		Stato.NASCOSTO:
			_guarda_t -= delta
			if _guarda_t <= 0.0:
				_guarda_t = 0.5
				if _pronto_a_venire():
					arriva()
		Stato.ARRIVA:
			_fai_arriva(delta)
		Stato.INVITA:
			_fai_invita(delta)
		Stato.CONTO:
			_fai_conto(delta)
		Stato.SFIDA:
			_fai_sfida(delta)
		Stato.ESITO:
			_fai_esito(delta)
		Stato.MENA:
			_fai_mena(delta)
		Stato.STESO:
			if KO.tick(_ko, _visual, delta):
				_se_ne_va()
		Stato.SE_NE_VA:
			_fai_se_ne_va(delta)


func _cammina(meta: Vector3, v: float, delta: float) -> void:
	var t := meta
	t.y = global_position.y
	var prima := global_position
	global_position = Passo.verso(self, t, v * delta)
	var y_giusta: float = Collina.alzata(global_position.x, global_position.z)
	global_position.y = move_toward(global_position.y, y_giusta, 6.0 * delta)
	_guarda(t)
	if _anim != null:
		_anim.set_speed(global_position.distance_to(prima) / maxf(delta, 0.0001))


func _fermo() -> void:
	if _anim != null:
		_anim.set_speed(0.0)


func _guarda(p: Vector3) -> void:
	var dir: Vector3 = p - global_position
	dir.y = 0.0
	if dir.length() > 0.05 and _visual:
		_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(-dir.x, -dir.z),
			1.0 - exp(-8.0 * get_physics_process_delta_time()))


## Qualcosa di grosso si mette in mezzo (Borrelli, la galera, la notte):
## ci si rivede.
func _annulla_se_serve() -> bool:
	if not GameManager.shift_active or GameManager.arrested or GameManager.hospitalized \
			or GameManager.boss_spawned or GameManager.boss_phase:
		if stato in [Stato.ARRIVA, Stato.INVITA]:
			_di(DETTO_ANNULLA)
			GameManager.re_prossimo_juorno = GameManager.giornata + 1
			_se_ne_va()
			return true
	return false


func _fai_arriva(delta: float) -> void:
	if _annulla_se_serve():
		return
	var pl := _giocatore()
	if pl == null:
		return
	_t -= delta
	var d: float = global_position.distance_to(pl.global_position)
	if d > 3.0 and _t > 0.0:
		_cammina(pl.global_position, VEL_CAMMINA if d < 14.0 else VEL_CAMMINA * 1.5, delta)
		return
	if d > 3.0:
		# Non ci arriva a piedi (un muro, un vicolo cieco): compare accanto.
		var q: Vector3 = pl.global_position - pl.global_transform.basis.z * 2.8
		global_position = Vector3(q.x, Collina.alzata(q.x, q.z), q.z)
	_fermo()
	_guarda(pl.global_position)
	stato = Stato.INVITA
	_t = INVITO_MAX
	_detto_invito = 0
	_di(DETTO_ARRIVO, 3.4)
	SoundManager.play("schiarisce", -4.0)


func _fai_invita(delta: float) -> void:
	if _annulla_se_serve():
		return
	var pl := _giocatore()
	if pl == null:
		return
	var d: float = global_position.distance_to(pl.global_position)
	if d > 5.5:
		_cammina(pl.global_position, VEL_CAMMINA * 1.4, delta)
	else:
		_fermo()
		_guarda(pl.global_position)
	_t -= delta
	# Le regole le dice lui, una alla volta.
	var passato: float = INVITO_MAX - _t
	if _detto_invito < DETTO_INVITO.size() and passato > 3.6 + 3.2 * float(_detto_invito):
		_di(DETTO_INVITO[_detto_invito], 3.0)
		_detto_invito += 1
	if _t <= 0.0:
		if _in_piazza_soja():
			_di(DETTO_PAURA)
			_comincia()
		else:
			_t = 8.0
			_di(DETTO_FORE)


func get_interact_prompt(_da: Vector3) -> String:
	match stato:
		Stato.INVITA:
			if _in_piazza_soja():
				return "%s — [E] accietta 'a sfida (un minuto, cchiù machine dint'ê strisce)" % NOME
			return "%s — 'a sfida se fa 'n piazza toja: portalo llà" % NOME
		Stato.CONTO, Stato.SFIDA:
			return "%s te sta guardanno" % NOME
	return ""


func player_interact() -> void:
	if stato == Stato.INVITA and _in_piazza_soja():
		_di("Accussì me piace. Jammo!", 1.6)
		_comincia()


func receive_punch(danno: int = 1) -> void:
	if _anim != null and _anim.has_method("reagisci_colpo"):
		_anim.reagisci_colpo(randf() < 0.4)
	SoundManager.pugno(-2.0)
	match stato:
		Stato.INVITA, Stato.ARRIVA:
			# Chi mena invece di faticare ha perso prima di cominciare.
			GameManager.re_prossimo_juorno = GameManager.giornata + GameManager.RE_RIVINCITA_DOPPO
			_di("Ah, cu 'e mmane? E allora so' mazzate pure pe' te!", 2.4)
			_comincia_mena()
		Stato.CONTO, Stato.SFIDA:
			_di("Ccà se fatica, no se mena! Fatica!", 1.8)
		Stato.MENA:
			hp -= maxi(1, danno)
			GameManager.nemico_colpito.emit(NOME, maxi(0, hp), HP_MAX)
			if hp <= 0:
				stato = Stato.STESO
				KO.lay_down(_ko, _visual, 6.0)
				_di(DETTO_STESO, 3.0)


# ---------------------------------------------------------------------------
# 'A sfida
# ---------------------------------------------------------------------------

func _comincia() -> void:
	_zona = GameManager.zona_corrente
	stato = Stato.CONTO
	_t = CONTO_DURATA
	_secondo = -1
	_contate = 0
	GameManager.re_zona_sfida = _zona
	GameManager.re_sfida_attiva = true
	GameManager.re_sfida_cambiata.emit(true)
	if not GameManager.auto_posteggiata.is_connected(_auto_posteggiata):
		GameManager.auto_posteggiata.connect(_auto_posteggiata)
	_hud = SfidaHud.new()
	_hud.name = "SfidaHud"
	get_tree().root.add_child(_hud)
	_hud.tempo(GameManager.RE_DURATA)
	_hud.conta(0)
	# Le prime due macchine partono adesso: mentre si conta, arrivano.
	_rifornisci(true)
	_tribuna = _punto_tribuna()


## Dove si mette a guardare: sul bordo della piazza, fuori dalla corsia.
func _punto_tribuna() -> Vector3:
	var citta := get_tree().get_first_node_in_group("citta")
	if citta == null or not citta.has_method("zona_per_id"):
		return global_position
	var z: Dictionary = citta.zona_per_id(_zona)
	if z.is_empty():
		return global_position
	var r: Array = z["rect"]
	var pl := _giocatore()
	var lx: float = float(r[0]) + 2.0
	var rx: float = float(r[2]) - 2.0
	var cz: float = (float(r[1]) + float(r[3])) * 0.5
	var da: Vector3 = pl.global_position if pl else global_position
	var q := Vector3(lx if absf(da.x - lx) > absf(da.x - rx) else rx, 0.0, cz)
	if CammVia.libera(q):
		return q
	return CammVia.vicino_libero(q)


func _spawner() -> Node:
	var citta := get_tree().get_first_node_in_group("citta")
	if citta == null:
		return null
	if _zona == "piazza":
		return citta.get_node_or_null("ZoneVicolo")
	return citta.get_node_or_null("Posteggio_" + _zona)


## Tiene due macchine della sfida in arrivo o in attesa (al più tre).
func _rifornisci(subito: bool = false) -> void:
	var sp := _spawner()
	if sp == null or not sp.has_method("sfida_manna_machina"):
		return
	var in_giro := 0
	for c in get_tree().get_nodes_in_group("cars"):
		if is_instance_valid(c) and c.get("sfida") == true \
				and str(c.get("zona_id")) == _zona and int(c.get("state")) <= 2:
			in_giro += 1
	var voglio: int = 2
	var n := 0
	while in_giro < voglio and n < (2 if subito else 1):
		var car = sp.sfida_manna_machina()
		if car == null:
			break
		in_giro += 1
		n += 1


func _fai_conto(delta: float) -> void:
	var pl := _giocatore()
	if pl:
		_guarda(pl.global_position)
	_fermo()
	_t -= delta
	var s: int = int(ceil(_t))
	if s != _secondo and _t > 0.0:
		_secondo = s
		if s <= 3 and s >= 1:
			_hud.grande(str(s), UiStile.ORO_CHIARO, 0.9)
			SoundManager.play("tic" if s % 2 == 1 else "tac", -2.0, 0.9)
	if _t <= 0.0:
		_hud.grande("VIA!", UiStile.VERDE, 1.0)
		SoundManager.play("fischio_vigile", -2.0, 1.05)
		_di("VIA!", 1.2)
		stato = Stato.SFIDA
		_t = GameManager.RE_DURATA
		_secondo = int(ceil(_t))
		_sfotto_t = 7.0
		_rifornisci_t = 0.5


func _fai_sfida(delta: float) -> void:
	var pl := _giocatore()
	# Va a mettersi sul bordo, e da lì guarda e sfotte.
	if _tribuna != Vector3.INF and global_position.distance_to(_tribuna) > 1.2:
		_cammina(_tribuna, VEL_CAMMINA, delta)
	else:
		_fermo()
		if pl:
			_guarda(pl.global_position)
	_t -= delta
	_hud.tempo(_t)
	var s: int = int(ceil(_t))
	if s != _secondo:
		_secondo = s
		_tic = not _tic
		var forte: bool = _t <= 10.0
		SoundManager.play("tic" if _tic else "tac", -1.0 if forte else -5.0,
			1.12 if forte else 1.0)
		_hud.battito(_t)
	_sfotto_t -= delta
	if _sfotto_t <= 0.0:
		_sfotto_t = randf_range(7.0, 10.0)
		_di(DETTE_SFOTTO[randi() % DETTE_SFOTTO.size()], 2.2)
	_rifornisci_t -= delta
	if _rifornisci_t <= 0.0:
		_rifornisci_t = 0.5
		_rifornisci()
	# Se il giocatore finisce dentro (arresto, ospedale, casa), la sfida
	# si chiude lì: si conta quello che ha fatto.
	if _t <= 0.0 or not GameManager.shift_active or GameManager.arrested \
			or GameManager.hospitalized:
		_fine_sfida()


func _auto_posteggiata(car: Node, dint_e_strisce: bool) -> void:
	if stato != Stato.SFIDA or car == null or not is_instance_valid(car):
		return
	if str(car.get("zona_id")) != _zona:
		return
	if not dint_e_strisce:
		_di(DETTO_FORE_STRISCE, 1.8)
		SoundManager.play("fail", -8.0, 1.1)
		return
	_contate += 1
	_hud.conta(_contate)
	SoundManager.play("success", -4.0, 1.0 + 0.05 * float(_contate))
	_di(DETTE_CONTE[mini(_contate, DETTE_CONTE.size()) - 1], 1.6)


func conta_sfida() -> int:
	return _contate


func _fine_sfida() -> void:
	GameManager.re_sfida_attiva = false
	GameManager.re_zona_sfida = ""
	GameManager.re_sfida_cambiata.emit(false)
	if GameManager.auto_posteggiata.is_connected(_auto_posteggiata):
		GameManager.auto_posteggiata.disconnect(_auto_posteggiata)
	SoundManager.play("gong_sfida", -2.0)
	for c in get_tree().get_nodes_in_group("cars"):
		if is_instance_valid(c) and c.get("sfida") == true and c.has_method("sfida_se_ne_va"):
			c.sfida_se_ne_va()
	_esito = GameManager.re_esito(_contate, _zona)
	stato = Stato.ESITO
	_t = ESITO_DURATA
	if _hud:
		_hud.tempo(0.0)
	var premio: String = str(_esito.get("premio", ""))
	var nome_z: String = str(GameManager.NOMI_PIAZZE.get(str(_esito.get("zona", "")), ""))
	var testo := ""
	var grande := ""
	var colore: Color = UiStile.ORO_CHIARO
	if _contate >= GameManager.RE_PE_A_PIAZZA:
		if premio == "piazza":
			testo = "Guagliò… tu sî 'nu rre overo. Tiene: %s mo' è 'a toia. T''a regalo io." % nome_z
			grande = "%d! 'NA PIAZZA 'N OMAGGIO!" % _contate
		else:
			testo = "Tutte 'e piazze 'e tiene già? E allora piglia chisti €%d." % int(_esito.get("soldi", 0))
			grande = "%d! €%d D''O RRE!" % [_contate, int(_esito.get("soldi", 0))]
		SoundManager.play("ui_vittoria", -2.0)
	elif _contate >= GameManager.RE_PE_O_GUAGLIONE:
		if premio == "guaglione":
			testo = "Nun c'è male, nun c'è male. Te lasso a Sasà 'o Lampo: fatica pe' te a %s." % nome_z
			grande = "%d! 'NU GUAGLIONE PE' TE!" % _contate
		else:
			testo = "Nun c'è male. Piglia chisti €%d, e statte buono." % int(_esito.get("soldi", 0))
			grande = "%d! €%d D''O RRE!" % [_contate, int(_esito.get("soldi", 0))]
		colore = UiStile.GIALLO
		SoundManager.play("ui_sblocco", -3.0)
	elif _contate == 2:
		testo = "Doje? Né carne né pesce. Torno n'ata vota, e vedimmo."
		grande = "2… NÉ CARNE NÉ PESCE"
		colore = UiStile.TESTO
		SoundManager.play("perso", -6.0)
	else:
		testo = DETTO_MAZZATE
		grande = "%d… MO' SO' MAZZATE!" % _contate
		colore = UiStile.ROSSO
		SoundManager.play("perso", -3.0)
	_di(testo, ESITO_DURATA)
	GameManager.event_started.emit("'O Rre: " + testo)
	if _hud:
		_hud.grande(grande, colore, ESITO_DURATA)


func _fai_esito(delta: float) -> void:
	var pl := _giocatore()
	if pl:
		_guarda(pl.global_position)
	_fermo()
	_t -= delta
	if _t <= 0.0:
		_butta_hud()
		if bool(_esito.get("mena", false)):
			_comincia_mena()
		else:
			_se_ne_va()


func _butta_hud() -> void:
	if _hud != null and is_instance_valid(_hud):
		_hud.queue_free()
	_hud = null


# ---------------------------------------------------------------------------
# 'E mazzate
# ---------------------------------------------------------------------------

func _comincia_mena() -> void:
	_butta_hud()
	stato = Stato.MENA
	_t = MENA_DURATA
	_botte = 0
	_mena_cd = 0.6
	hp = HP_MAX
	SoundManager.play("folla_arrabbiata", -8.0)


func _fai_mena(delta: float) -> void:
	var pl := _giocatore()
	if pl == null or GameManager.dentro_casa:
		_se_ne_va()
		return
	_t -= delta
	_mena_cd = maxf(0.0, _mena_cd - delta)
	var d: float = global_position.distance_to(pl.global_position)
	if d > MENA_PORTATA:
		_cammina(pl.global_position, VEL_MENA, delta)
	else:
		_fermo()
		_guarda(pl.global_position)
		if _mena_cd <= 0.0:
			_mena_cd = MENA_OGNI
			_botte += 1
			# Ti fa male, ma all'ospedale non ti ci manda: è 'na lezione.
			var danno: float = minf(MENA_DANNO, maxf(0.0, GameManager.health - 12.0))
			if danno > 0.0:
				GameManager.damage_player(danno, "T'ha menato %s" % NOME, global_position)
			SoundManager.pugno(-1.0)
			GameManager.screen_shake.emit(0.5)
			if _anim != null:
				_anim.action("punch" if _botte % 2 == 1 else "jab")
			_di(DETTE_BOTTE[randi() % DETTE_BOTTE.size()], 1.1)
	if _botte >= MENA_BOTTE_MAX or _t <= 0.0:
		_di(DETTO_SE_NE_VA_MENA, 2.6)
		_se_ne_va()


# ---------------------------------------------------------------------------
# Se ne va
# ---------------------------------------------------------------------------

func _se_ne_va() -> void:
	_butta_hud()
	if GameManager.re_sfida_attiva:
		GameManager.re_sfida_attiva = false
		GameManager.re_zona_sfida = ""
		GameManager.re_sfida_cambiata.emit(false)
	stato = Stato.SE_NE_VA
	_t = 14.0
	var pl := _giocatore()
	var da: Vector3 = pl.global_position if pl else global_position
	var via: Vector3 = global_position + (global_position - da).normalized() * 30.0
	_via = CammVia.vicino_raggiungibile(Vector3(clampf(via.x, 2.0, 188.0), 0.0,
		clampf(via.z, 2.0, 170.0)))


func _fai_se_ne_va(delta: float) -> void:
	_t -= delta
	_cammina(_via, VEL_CAMMINA * 1.2, delta)
	var pl := _giocatore()
	var lontano: bool = pl == null or global_position.distance_to(pl.global_position) > 30.0
	if _t <= 0.0 or lontano or global_position.distance_to(_via) < 1.5:
		_nascondi()


func _exit_tree() -> void:
	# Chi apre la sfida la deve chiudere: se la scena se ne va a metà (la
	# giornata finisce, si carica una partita), il rubinetto riparte.
	if stato in [Stato.CONTO, Stato.SFIDA]:
		GameManager.re_sfida_attiva = false
		GameManager.re_zona_sfida = ""
	_butta_hud()
