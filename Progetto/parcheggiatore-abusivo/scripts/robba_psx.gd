extends RefCounted
## **'A robba 'e cchiù** (0.60) — il secondo giro del pacchetto PSX.
##
## Il capo alla chiusura della 0.59: *«integra più asset nuovi che puoi,
## rendi in generale il mondo di gioco più dettagliato possibile»*. Del
## PSX Mega Pack la 0.58 ne aveva preso 116 su 592, e quasi tutti da tasca
## o da tavolo. Qui entra la roba che fa **città**: le sedie davanti ai
## bassi, i materassi e i divani buttati, il bagno chimico dei cantieri, la
## bancarella dei libri usati, la saracinesca dell'acqua accanto ai quadri
## elettrici, i cartoni e le lattine accanto ai cassonetti, le cicche per
## terra davanti ai bar.
##
## **Le regole sono quelle della 0.59, e valgono tutte.** Si mette per
## ultimo (dopo le auto in sosta e l'arredo nuovo), col suo seme (così
## la città è la stessa a ogni partita), **solo dove c'è posto** — la domanda
## è sempre `_sta_libero` / `_scatola_libera` della città — e ogni cosa più
## grande di un pacchetto di sigarette ha un corpo (`_solido`), perché da
## `prova_ntuppate` in poi la gente ci cammina intorno e non attraverso.
## Ogni pezzo sta attaccato a qualcosa che c'era già: la sedia al suo
## basso, il bagno chimico al suo cantiere, la valvola al suo quadro.
##
## I nomi dei modelli si scrivono per intero, mai costruiti con `%d`:
## `prova_asset` li cerca nel testo (trappola 31).

const Models := preload("res://scripts/models.gd")
const Human := preload("res://scripts/human_builder.gd")
const Anim := preload("res://scripts/animator.gd")
const Tex := preload("res://scripts/textures.gd")

const SEGGE := ["seggia_paglia", "seggia_legno", "seggia_vecchia"]
const SEGGIA_DIM := Vector3(0.5, 1.0, 0.52)
## La seduta delle tre sedie PSX: quarantasei centimetri, come quella
## fatta a mano del tavolino della scopa (`SEDUTA_Y`).
const SEDUTA: float = 0.46
const LIBBRE := ["libro_a", "libro_b", "libro_c", "libro_d", "libro_e",
	"libro_f"]
const CICCHE := ["cicca_terra", "cicca_terra2"]
const MUNNEZZA_CCHIU := ["scatolone3", "cascia_scura", "barattolo"]
const MATTUNE := ["mattone_rosso", "mattone_grigio"]


static func metti(c: Node3D) -> void:
	if not Models.has_model("seggia_paglia"):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 60001
	_segge_fore(c, rng)
	_cantieri(c, rng)
	_volantini(c, rng)
	_munnezza_cchiu(c, rng)
	_bancarelle_libbre(c, rng)
	_cicche(c, rng)


# ---------------------------------------------------------------------------
# 'E segge fore 'o vascio
# ---------------------------------------------------------------------------

## Il punto sta dentro alla pianta, a un metro dal bordo?
static func _dint_a_mappa(c: Node3D, p: Vector3) -> bool:
	return p.x > 1.0 and p.x < float(c.LARGHEZZA) - 1.0 \
		and p.z > 1.0 and p.z < float(c.PROFONDITA) - 1.0


## **Un modello ritinto** (0.60): una copia delle sue mesh coi materiali
## moltiplicati per `tinta`, messa nella cache della città sotto un altro
## nome. `_panda`, `_panda_c` e i MultiMesh la trovano come un modello
## qualunque. Il bagno chimico del pacchetto è di legno scuro, e quelli dei
## cantieri italiani sono di plastica blu: la forma è giusta, il colore no.
static func _tinto(c: Node3D, nome: String, nuovo: String, tinta: Color) -> void:
	if c._mesh_cache.has(nuovo):
		return
	var fuori: Array = []
	for pz in c._pezzi_modello(nome):
		var m: Mesh = (pz["mesh"] as Mesh).duplicate()
		for i in m.get_surface_count():
			var mat: Material = m.surface_get_material(i)
			if mat is StandardMaterial3D:
				var nova: StandardMaterial3D = (mat as StandardMaterial3D).duplicate()
				nova.albedo_color = nova.albedo_color * tinta
				m.surface_set_material(i, nova)
		fuori.append({"mesh": m, "trasf": pz["trasf"]})
	c._mesh_cache[nuovo] = fuori

## **'E segge fore 'a porta.** Chi abita in un basso d'estate sta fuori:
## la sedia sotto alla finestra, a volte due girate l'una verso l'altra
## col tavolinetto in mezzo, e ogni tanto la signora seduta che guarda chi
## passa. I bassi li ha segnati la città mentre costruiva il piano terra
## (`_vasci_fore`); qui se ne prende uno su tre, dove c'è posto.
static func _segge_fore(c: Node3D, rng: RandomNumberGenerator) -> void:
	var messe := 0
	var assettate := 0
	for v in c._vasci_fore:
		if messe >= 26:
			break
		if rng.randf() > 0.4:
			continue
		var porta: Vector3 = v[0]
		var fen: Vector3 = v[1]
		var fuori: Vector3 = v[2]
		var lungo: Vector3 = (fen - porta).normalized()
		var giro: float = atan2(fuori.x, fuori.z)
		var p1: Vector3 = fen + fuori * 0.52
		# I bassi delle facciate che guardano fuori dalla pianta (il bordo di
		# ponente, il fondo) ci sono, ma lì non passa nessuno: le sedie
		# fuori dalla mappa non si mettono (la prima sonda ne ha trovate
		# tre a x = −0,5).
		if not _dint_a_mappa(c, p1):
			continue
		if not c._sta_libero(p1, 0.36, 0.3) or not c._scatola_libera(p1,
				SEGGIA_DIM, giro):
			continue
		var g1: float = giro + rng.randf_range(-0.35, 0.35)
		var quale: String = SEGGE[rng.randi() % SEGGE.size()]
		c._panda_c(quale, p1, g1, "segge", 45.0)
		c._solido(p1 + Vector3(0, SEGGIA_DIM.y * 0.5, 0), SEGGIA_DIM, g1)
		var segno := Node3D.new()
		segno.name = "SeggeFore"
		segno.add_to_group("segge_fore")
		c.add_child(segno)
		segno.position = p1
		segno.rotation.y = giro
		messe += 1
		# La seconda sedia, girata verso la prima, col tavolinetto in mezzo.
		if rng.randf() < 0.45:
			var p2: Vector3 = p1 + lungo * 1.05
			var tav: Vector3 = p1 + lungo * 0.52 + fuori * 0.15
			if c._sta_libero(p2, 0.36, 0.3) and c._scatola_libera(p2,
					SEGGIA_DIM, giro):
				# Girata verso la prima: guarda la strada e un po' la vicina.
				var verso2: Vector3 = (fuori - lungo * 0.6).normalized()
				var g2: float = atan2(verso2.x, verso2.z) + rng.randf_range(-0.2, 0.2)
				c._panda_c(SEGGE[(SEGGE.find(quale) + 1) % SEGGE.size()], p2, g2,
					"segge", 45.0)
				c._solido(p2 + Vector3(0, SEGGIA_DIM.y * 0.5, 0), SEGGIA_DIM, g2)
				if rng.randf() < 0.6:
					c._panda_c("tavulinetto", tav, giro, "segge", 45.0)
					c._panda("posacenere", tav + Vector3(0.05, 0.59, 0.0),
						rng.randf_range(-PI, PI), "segge_sopra", 30.0)
					if Models.has_model("tazzulella"):
						c._panda("tazzulella", tav + Vector3(-0.1, 0.59, 0.06),
							rng.randf_range(-PI, PI), "segge_sopra", 30.0)
		# E la signora assettata, su cinque sedie in tutta la città.
		if assettate < 5 and rng.randf() < 0.3:
			_signora_assettata(c, p1, g1, rng)
			assettate += 1


## La signora seduta davanti al basso. È un pupo con la clip `Sitting_Idle`,
## come i vecchi della scopa: la radice si abbassa di quanto la clip tiene
## il bacino sopra ai piedi, e il sedere cade sulla seduta della sedia.
## Guarda la strada (il davanti della sedia è il suo +Z; il davanti di una
## persona è il −Z, da qui il mezzo giro).
static func _signora_assettata(c: Node3D, seggia: Vector3, giro: float,
		rng: RandomNumberGenerator) -> void:
	var alta: float = rng.randf_range(1.52, 1.64)
	var vesti := [Color(0.18, 0.18, 0.22), Color(0.36, 0.20, 0.24),
		Color(0.22, 0.30, 0.40), Color(0.40, 0.36, 0.30)]
	var veste: Color = vesti[rng.randi() % vesti.size()]
	# (0.64) I capelli sono il fazzoletto: vedi `_fazzoletto`.
	var stoffa: Color = FAZZOLETTI[rng.randi() % FAZZOLETTI.size()]
	var parti: Dictionary = Human.build(veste, veste.darkened(0.3), "", alta, {
		"corpo": "femmina", "hair": stoffa,
		"belly": rng.randf_range(0.45, 0.85), "bald": false,
		"moustache": false})
	var chi := Node3D.new()
	chi.name = "SignoraAssettata"
	c.add_child(chi)
	var davanti := Vector3(sin(giro), 0, cos(giro))
	chi.position = seggia + davanti * 0.1 \
		+ Vector3(0, SEDUTA - Anim.BACINO_SEDUTO * alta
			+ Collina.alzata(seggia.x, seggia.z), 0)
	chi.rotation.y = giro + PI
	chi.add_to_group("signore_assettate")
	var root: Node3D = parti.get("root")
	if root != null:
		chi.add_child(root)
	var testa = parti.get("head", null)
	if testa != null:
		_fazzoletto(testa as Node3D, stoffa)
	var a = parti.get("anim", null)
	if a != null and a.has_method("sit"):
		a.sit(false)
	c._lontananza(chi, 60.0)


## **'O fazzoletto 'n capa** (0.64). Col capello grigio e corto, da lontano
## le signore sedute sembravano vecchi (lo diceva la roadmap dalla 0.60):
## il fazzoletto scuro annodato sotto al mento le fa leggere subito.
##
## Il fazzoletto è **i capelli stessi del pupo**, tinti del colore della
## stoffa (vedi `_signora_assettata`): una calotta messa sopra alla testa
## del pupo, che è alta e tonda da cartone animato, veniva fuori una cuffia
## a punta, e sotto spuntava la frangia bianca. Qui sopra si aggiungono solo
## le due cose che dicono "fazzoletto" e non "capelli": il nodo sotto al
## mento, coi due lembi che ci scendono, e la punta del triangolo sulla
## nuca. (Le due fasce lungo le guance, provate, dalla tempia al mento
## passavano dentro alla faccia e spuntavano come una barba rossa.)
## Sull'osso della testa il davanti è +Z (vedi `maestro_3d.gd`).
const FAZZOLETTI := [Color(0.20, 0.16, 0.28), Color(0.44, 0.12, 0.16),
	Color(0.14, 0.14, 0.15), Color(0.34, 0.24, 0.14), Color(0.18, 0.28, 0.42)]


static func _fazzoletto(testa: Node3D, colore: Color) -> void:
	var mat := Tex.flat(colore, 0.92)
	# 'O nodo, sotto al mento.
	var nm := SphereMesh.new()
	nm.radius = 0.024
	nm.height = 0.046
	nm.radial_segments = 10
	nm.rings = 5
	var nodo := MeshInstance3D.new()
	nodo.mesh = nm
	nodo.material_override = mat
	nodo.position = Vector3(0, -0.002, 0.07)
	nodo.scale = Vector3(1.35, 0.85, 1.0)
	testa.add_child(nodo)
	# 'E doje cocche d''o nodo, che pendono.
	for sx in [-1.0, 1.0]:
		var cm := BoxMesh.new()
		cm.size = Vector3(0.026, 0.05, 0.01)
		var cocca := MeshInstance3D.new()
		cocca.mesh = cm
		cocca.material_override = mat
		cocca.position = Vector3(sx * 0.016, -0.03, 0.074)
		cocca.rotation.z = sx * 0.35
		testa.add_child(cocca)
	# 'A punta d''o triangolo, 'ncopp'â noce d''o cuollo.
	var pm := CylinderMesh.new()
	pm.top_radius = 0.07
	pm.bottom_radius = 0.0
	pm.height = 0.09
	pm.radial_segments = 3
	pm.rings = 1
	var punta := MeshInstance3D.new()
	punta.mesh = pm
	punta.material_override = mat
	punta.position = Vector3(0, 0.02, -0.085)
	punta.rotation.x = -0.25
	punta.scale = Vector3(1.0, 1.0, 0.18)
	testa.add_child(punta)


# ---------------------------------------------------------------------------
# 'E cantiere
# ---------------------------------------------------------------------------

## **'O bagno chimico, 'e mattune, 'a tanica.** Un cantiere che sta lì da
## mesi ha il gabbiotto blu in testa, la pila di mattoni contro il muro e la
## tanica della benzina per il generatore. Il bagno chimico sta **fuori**
## dal recinto, dalla parte del bidone, con la schiena al muro: il recinto è
## già un corpo solido, e il bagno chimico ha il suo.
static func _cantieri(c: Node3D, rng: RandomNumberGenerator) -> void:
	var i := 0
	for info in c._cantieri_info:
		var centro: Vector3 = info[0]
		var lungo: Vector3 = info[1]
		var muro: Vector3 = info[2]
		var dal_muro: float = float(info[3])
		var giro_strada: float = atan2(-muro.x, -muro.z)
		# I mattoni, dentro al recinto, contro il muro: tre file incrociate.
		var base: Vector3 = centro + lungo * -0.9 + muro * maxf(0.4, dal_muro - 0.45)
		var giro_l: float = atan2(-lungo.z, lungo.x)
		for fila in 3:
			for k in 3:
				var dx: float = (float(k) - 1.0) * 0.14
				var off: Vector3 = (lungo * dx if fila % 2 == 0
					else muro * dx) + Vector3(0, float(fila) * 0.08, 0)
				c._panda(MATTUNE[(fila + k) % 2], base + off,
					giro_l + (0.0 if fila % 2 == 0 else PI * 0.5)
					+ rng.randf_range(-0.08, 0.08), "cantiere_psx", 55.0)
		c._panda("tanica_blu", centro + lungo * -3.0 + muro * maxf(0.35, dal_muro - 0.35),
			giro_strada + rng.randf_range(-0.4, 0.4), "cantiere_psx", 55.0)
		# Il bagno chimico, in tre cantieri su cinque. Blu.
		_tinto(c, "bagno_chimico", "bagno_chimico_blu", Color(0.55, 0.85, 2.3))
		if i % 2 == 0:
			var dim := Vector3(1.52, 2.38, 1.56)
			for al in [4.75, 5.4, -4.9]:
				var q: Vector3 = centro + lungo * float(al) + muro * (dal_muro - 0.82)
				var ang: float = giro_strada
				if not c._sta_libero(q, 0.8, 0.8) or not c._scatola_libera(q, dim, ang):
					continue
				if not c.dint_ô_palazzo(q + muro * 1.2, 0.0):
					continue
				c._panda_c("bagno_chimico_blu", q, ang, "cantiere_psx")
				c._solido(q + Vector3(0, dim.y * 0.5, 0), dim, ang)
				var segno := Node3D.new()
				segno.name = "BagnoChimico"
				segno.add_to_group("bagni_chimici")
				c.add_child(segno)
				segno.position = q
				segno.rotation.y = ang
				break
		i += 1


# ---------------------------------------------------------------------------
# 'E saracinesche 'e ll'acqua
# ---------------------------------------------------------------------------

## Il volantino rosso della saracinesca dell'acqua, accanto a un quadro
## elettrico su due: sta al muro, a sessanta centimetri da terra, e sporge
## diciotto centimetri (niente corpo: è meno di un gradino).
static func _volantini(c: Node3D, rng: RandomNumberGenerator) -> void:
	for q in c._quadri_posti:
		if rng.randf() > 0.55:
			continue
		var p: Vector3 = q[0]
		var fuori: Vector3 = q[1]
		var largo: float = float(q[2])
		var lungo := Vector3(fuori.z, 0, -fuori.x)
		var lato: float = 1.0 if rng.randf() < 0.5 else -1.0
		var muro: Vector3 = p - fuori * 0.26
		var v: Vector3 = muro + lungo * (lato * (largo * 0.5 + 0.35)) \
			+ Vector3(0, 0.62, 0)
		if not c.dint_ô_palazzo(v - fuori * 0.3, 0.0):
			continue
		c._panda("volantino_acqua", v, atan2(fuori.x, fuori.z), "appise_psx", 40.0)


# ---------------------------------------------------------------------------
# 'A munnezza 'e cchiù
# ---------------------------------------------------------------------------

## I cartoni della bottega, la cassetta rotta e la lattina arrugginita,
## accanto ai cassonetti che hanno ancora posto: la munnezza di Napoli non
## sta mai tutta nel cassonetto.
static func _munnezza_cchiu(c: Node3D, rng: RandomNumberGenerator) -> void:
	var k := 0
	for cs in c._cassonetti:
		var p: Vector3 = cs[0]
		var giro: float = float(cs[1])
		var lungo := Vector3(cos(giro), 0, -sin(giro))
		var quale: String = MUNNEZZA_CCHIU[k % MUNNEZZA_CCHIU.size()]
		k += 1
		var r: float = 0.18 if quale == "barattolo" else 0.36
		for d in [-3.1, 3.1, -3.9, 3.9, -4.7, 4.7]:
			var q: Vector3 = p + lungo * float(d)
			if not c._sta_libero(q, r, r):
				continue
			var g: float = giro + rng.randf_range(-0.6, 0.6)
			c._panda_c(quale, q, g, "munnezza_psx", 55.0)
			if quale != "barattolo":
				var dim := Vector3(0.6, 0.62, 0.6)
				c._solido(q + Vector3(0, dim.y * 0.5, 0), dim, g)
			break


# ---------------------------------------------------------------------------
# 'A bancarella d''e libbre
# ---------------------------------------------------------------------------

## **'E libbre usate.** A Port'Alba i libri si vendono sul banco in mezzo
## alla strada, a un euro, e il libraio sta in piedi accanto col giornale
## sotto al braccio. Qui due banchi, uno su Spaccanapoli e uno sulla strada
## della piazzetta: il banco con la schiena al muro, i libri sopra (sdraiati
## e a pile), lo sgabello, il cartello scritto a mano e il libraio.
const POSTI_LIBBRE := [Vector3(86.0, 0.0, 76.5), Vector3(58.0, 0.0, 91.0)]


static func _bancarelle_libbre(c: Node3D, rng: RandomNumberGenerator) -> void:
	var dim_b := Vector3(1.6, 0.91, 0.69)
	var dim_l := Vector3(0.5, 1.75, 0.5)
	for punto in POSTI_LIBBRE:
		var pezzi := [["banco_libri", 0.0, dim_b.x * 0.5, dim_b.z * 0.5, 0.0, dim_b],
			["libraio", 1.25, 0.3, 0.3, 0.0, dim_l]]
		var posto: Dictionary = c._posto_pe_scena(punto, pezzi)
		if posto.is_empty():
			continue
		var giro: float = float(posto["giro"])
		var fuori := Vector3(sin(giro), 0, cos(giro))
		var lungo := Vector3(cos(giro), 0, -sin(giro))
		var muro: Vector3 = posto["muro"]
		var banco: Vector3 = muro + fuori * (dim_b.z * 0.5 + 0.03)
		c._panda_c("banco_libri", banco, giro, "libbre")
		c._solido(banco + Vector3(0, dim_b.y * 0.5, 0), dim_b, giro)
		# I libri: due file sdraiati, e tre pile.
		var sopra: float = dim_b.y
		for fila in 2:
			for k in 5:
				var at: Vector3 = banco + lungo * (-0.6 + float(k) * 0.3) \
					+ fuori * (-0.14 + float(fila) * 0.26) + Vector3(0, sopra, 0)
				if k == 2 and fila == 0:
					for h in rng.randi_range(2, 4):
						c._panda(LIBBRE[(k + h) % LIBBRE.size()],
							at + Vector3(0, float(h) * 0.04, 0),
							giro + rng.randf_range(-0.25, 0.25), "libbre", 40.0)
					continue
				c._panda(LIBBRE[(fila * 5 + k) % LIBBRE.size()], at,
					giro + rng.randf_range(-0.3, 0.3), "libbre", 40.0)
		if Models.has_model("libro_apierto"):
			c._panda("libro_apierto", banco + lungo * 0.62 + fuori * 0.14
				+ Vector3(0, sopra, 0), giro + 0.2, "libbre", 40.0)
		# Il cartello scritto a mano, appoggiato davanti al banco.
		var cartello := Label3D.new()
		cartello.text = "LIBBRE USATE\n€ 1 'o piezzo"
		cartello.font_size = 34
		cartello.pixel_size = 0.004
		cartello.modulate = Color(0.12, 0.10, 0.10)
		cartello.outline_size = 0
		cartello.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		cartello.double_sided = false
		c.add_child(cartello)
		cartello.position = banco + fuori * (dim_b.z * 0.5 + 0.02) \
			+ Vector3(0, 0.62, 0) + Vector3(0, Collina.alzata(banco.x, banco.z), 0)
		cartello.rotation.y = giro
		var cartone := MeshInstance3D.new()
		cartone.mesh = BoxMesh.new()
		(cartone.mesh as BoxMesh).size = Vector3(0.62, 0.34, 0.01)
		cartone.material_override = Tex.flat(Color(0.78, 0.66, 0.46), 0.95)
		c.add_child(cartone)
		cartone.position = cartello.position - fuori * 0.008
		cartone.rotation.y = giro
		# Lo sgabello del libraio, e il libraio in piedi accanto al banco.
		var sg: Vector3 = banco + lungo * -1.15 + fuori * 0.05
		if c._sta_libero(sg, 0.3, 0.3):
			c._panda_c("sgabello", sg, giro + rng.randf_range(-0.5, 0.5), "libbre")
			c._solido(sg + Vector3(0, 0.3, 0), Vector3(0.46, 0.6, 0.46), giro)
		var lp: Vector3 = muro + lungo * 1.25 + fuori * 0.33
		var parti: Dictionary = Human.build(Color(0.34, 0.32, 0.30),
			Color(0.20, 0.20, 0.24), "", rng.randf_range(1.70, 1.78),
			{"modello": "umano_q", "hair": Color(0.72, 0.70, 0.68)})
		var chi := Node3D.new()
		chi.name = "Libraio"
		chi.add_to_group("bancarella_libri")
		c.add_child(chi)
		chi.position = lp + Vector3(0, Collina.alzata(lp.x, lp.z), 0)
		# Guarda la strada, un po' di sbieco verso il banco.
		chi.rotation.y = giro + PI - 0.35
		var root: Node3D = parti.get("root")
		if root != null:
			chi.add_child(root)
		c._solido(lp + Vector3(0, dim_l.y * 0.5, 0), dim_l, giro)
		c._lontananza(chi, 70.0)


# ---------------------------------------------------------------------------
# 'E cicche
# ---------------------------------------------------------------------------

## Le cicche per terra davanti ai bar e alle sale: una decina, sparse a due
## metri e mezzo dal bancone. Sono otto centimetri: si vedono solo da
## vicino, e si spengono oltre i venticinque metri.
static func _cicche(c: Node3D, rng: RandomNumberGenerator) -> void:
	for g in ["bar", "scommesse", "tabaccheria"]:
		for n in c.get_tree().get_nodes_in_group(g):
			if not (n is Node3D):
				continue
			var b: Node3D = n
			var p: Vector3 = b.global_position
			# Tutt'attorno: il davanti di un chiosco del bar è il suo +X, quello
			# della sala il +Z, e alle cicche non importa.
			for k in rng.randi_range(6, 11):
				var ang: float = rng.randf_range(-PI, PI)
				var q: Vector3 = p + Vector3(cos(ang), 0, sin(ang)) \
					* rng.randf_range(1.2, 3.2)
				q.y = 0.0
				if c.dint_ô_palazzo(q, 0.05):
					continue
				c._panda(CICCHE[k % CICCHE.size()], q, rng.randf_range(-PI, PI),
					"cicche", 25.0)
