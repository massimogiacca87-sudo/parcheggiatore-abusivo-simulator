extends StaticBody3D
## Scopa3D — 'e viecchie ca jocano a scopa
##
## Un tavolino di plastica, quattro sedie e quattro vecchi che giocano a
## scopa. Non c'è niente da fare: è arredamento vivo. Ci si passa accanto,
## si sente la discussione, si va per i fatti propri.
##
## ## Perché è un minigioco vero anche se non ci giochi
##
## Sarebbe bastato mettere quattro carte ferme sul tavolo. Ma quattro carte
## ferme le noti una volta e poi diventano una macchia; una partita che va
## avanti la ritrovi cambiata ogni volta che ripassi, e questo cambia
## completamente come ti sembra il quartiere.
##
## Quindi qui sotto c'è una scopa che si gioca davvero: si dà un mazzo, si
## calano le carte a turno, si prende quando i numeri tornano, si conta la
## scopa, e quando il mazzo finisce si rimescola. Non lo saprà mai nessuno —
## ed è proprio per quello che funziona: le carte sul tavolo sono sempre una
## situazione *possibile*, e le battute che si sentono corrispondono a quello
## che è appena successo.
##
## Con `_MOSSA_OGNI` a due secondi e mezzo, una partita dura più o meno tre
## minuti reali: un giro della città e li ritrovi a un altro punto.

const CarteScript := preload("res://scripts/carte.gd")
const SpeechBubbleScript := preload("res://scripts/speech_bubble.gd")
const HumanBuilderScript := preload("res://scripts/human_builder.gd")

const MOSSA_OGNI: float = 2.5
const TAVOLO_H: float = 0.74
const TAVOLO_R: float = 0.56
## Quanto lontano dal centro sta ogni sedia. Con meno di questo i quattro si
## compenetrano col tavolo e sembrano appesi al bordo.
const DISTANZA_SEDIA: float = 0.95
const SEDUTA_Y: float = 0.44
const RAGGIO_UDITO: float = 14.0   # oltre, non parlano: sarebbe rumore
## Una battuta alla volta per tavolo. Con quattro bolle che si accendono
## insieme il testo si sovrappone e non si legge più niente — misurato a
## schermo, due bolle vicine bastano a coprirsi a vicenda.
const PAUSA_FRA_BATTUTE: float = 1.4

const SAY_PRESA := ["'A piglio!", "Chesta è 'a mia.", "Tie'.", "Presa."]
const SAY_SCOPA := ["SCOPAAA!", "E scopa! Conta, conta!",
	"Scopa! E mo' che dice?"]
const SAY_NIENTE := ["Passo.", "Mm... chesta.", "E vabbuo'.", "Nun tengo niente."]
const SAY_LITIGA := [
	"Ma tu ll'hê visto? Ha calato 'o sette!",
	"Aggio ditto ca 'o denaro s'accummencia!",
	"Chillo bara, 'o ssaccio io.",
	"Piano cu 'e mmane, eh!",
	"'Sta partita nun vale niente.",
	"Mo' me fumo 'na sigaretta e po' te sfaccimmo.",
]
const SAY_FINE := ["Fine 'e partita. Mischia, va'.", "E mo' 'n'ata!",
	"Cunta 'e ppunte."]

var _mazzo: Array[int] = []
var _tavolo: Array[int] = []        # indici carta scoperti al centro
var _mani: Array = []               # 4 array di indici
var _turno: int = 0
var _t: float = 0.0
var _nodi_tavolo: Array[Node3D] = []
var _giocatori: Array[Node3D] = []
var _bolle: Array = []
var _punti: Array[int] = [0, 0, 0, 0]
var _rng := RandomNumberGenerator.new()
var _zitti_fino: float = 0.0


func _ready() -> void:
	add_to_group("attivita")
	add_to_group("scopa")
	collision_layer = 1
	collision_mask = 0
	_rng.randomize()
	_build_visual()
	_build_collisione()
	_nuova_partita()
	# I quattro non partono insieme, se no sembrano quattro orologi.
	_t = _rng.randf_range(0.5, MOSSA_OGNI)


func get_interact_prompt(_da: Vector3) -> String:
	return "Stanno jucanno a scopa. Fatte 'e fatte tuoie."


# ---------------------------------------------------------------------------
# Il tavolino, le sedie, i quattro
# ---------------------------------------------------------------------------

func _build_visual() -> void:
	var bianco := StandardMaterial3D.new()
	bianco.albedo_color = Color(0.88, 0.87, 0.83)
	bianco.roughness = 0.6

	var piano := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = TAVOLO_R
	pm.bottom_radius = TAVOLO_R
	pm.height = 0.04
	pm.radial_segments = 16
	piano.mesh = pm
	piano.position = Vector3(0, TAVOLO_H, 0)
	piano.material_override = bianco
	add_child(piano)

	for a in [0.7, 2.3, 3.9, 5.5]:
		var g := MeshInstance3D.new()
		var gm := CylinderMesh.new()
		gm.top_radius = 0.022
		gm.bottom_radius = 0.028
		gm.height = TAVOLO_H
		gm.radial_segments = 6
		g.mesh = gm
		g.position = Vector3(cos(a) * 0.33, TAVOLO_H * 0.5, sin(a) * 0.33)
		g.material_override = bianco
		add_child(g)

	# Quattro sedie e quattro vecchi, uno per lato.
	for i in range(4):
		var ang: float = PI * 0.5 * i
		var pos := Vector3(cos(ang) * DISTANZA_SEDIA, 0.0,
			sin(ang) * DISTANZA_SEDIA)
		_build_sedia(pos, ang, bianco)
		# Guarda verso il centro del tavolo: la direzione è -pos, e la
		# regola della rotazione qui è rotation.y = atan2(-x, -z).
		var verso: Vector3 = (-pos).normalized()
		var g := _build_vecchio(i)
		g.position = pos
		g.rotation.y = atan2(-verso.x, -verso.z)
		add_child(g)
		_giocatori.append(g)
		_carte_davanti(pos)

		var b := SpeechBubbleScript.new()
		# Le bolle stanno su quattro altezze diverse: quando due parlano a
		# poca distanza di tempo, quella dietro si legge lo stesso.
		b.position = pos + Vector3(0, 1.62 + i * 0.16, 0)
		add_child(b)
		_bolle.append(b)


func _build_sedia(pos: Vector3, ang: float, mat: StandardMaterial3D) -> void:
	var s := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.4, 0.05, 0.4)
	s.mesh = sm
	s.position = pos + Vector3(0, SEDUTA_Y, 0)
	s.material_override = mat
	add_child(s)
	var sch := MeshInstance3D.new()
	var schm := BoxMesh.new()
	schm.size = Vector3(0.4, 0.42, 0.05)
	sch.mesh = schm
	# Lo schienale sta dalla parte OPPOSTA al tavolo.
	sch.position = pos + Vector3(cos(ang) * 0.19, SEDUTA_Y + 0.22,
		sin(ang) * 0.19)
	sch.rotation.y = -ang
	sch.material_override = mat
	add_child(sch)
	# Quattro gambe, se no la sedia è una tavola che galleggia.
	for gx in [-0.16, 0.16]:
		for gz in [-0.16, 0.16]:
			var g := MeshInstance3D.new()
			var gm := BoxMesh.new()
			gm.size = Vector3(0.03, SEDUTA_Y, 0.03)
			g.mesh = gm
			g.position = pos + Vector3(gx, SEDUTA_Y * 0.5, gz)
			g.material_override = mat
			add_child(g)


## Vecchi: bassi, panzuti, pelati, coi baffi, in camicia chiara. Sono le
## quattro cose che li rendono riconoscibili come vecchi da lontano senza
## bisogno di una faccia.
##
## **Assettate overo (0.59).**
##
## Fino alla 0.58 questi quattro si costruivano con `animate: false` e poi si
## piegavano a mano: coscia a novanta gradi, ginocchio a meno novanta,
## spalle avanti. Erano i numeri dello scheletro fatto a mano della 0.47. Lo
## scheletro della 0.48 quelle ossa **non le dà** — `bones` porta testa,
## petto, mani e spalle — quindi il codice non piegava niente, e siccome
## l'animazione l'aveva spenta lui stesso, restavano **in croce**. E il
## bacino lo abbassava lo stesso all'altezza della sedia: venti vecchi a
## braccia aperte, affondati nel selciato fino alle ginocchia, a cinque
## tavolini. Li ha trovati `prova_croce`, che misura le ossa invece di
## leggere il codice.
##
## Adesso stanno seduti con le clip vere della libreria (`Sitting_Idle`, e
## `Sitting_Talking` quando tocca a loro), col bacino messo dove lo mette
## la clip: 0,3045 dell'altezza sopra ai piedi e 0,184 dietro alla radice.
const DIETRO_SEDUTO := 0.1844
const Anim := preload("res://scripts/animator.gd")

var _anim_giocatori: Array = []


func _build_vecchio(i: int) -> Node3D:
	var camicie := [Color(0.86, 0.84, 0.78), Color(0.74, 0.78, 0.82),
		Color(0.82, 0.78, 0.7), Color(0.7, 0.72, 0.7)]
	var altezza: float = _rng.randf_range(1.62, 1.7)
	var p := HumanBuilderScript.build(camicie[i], Color(0.28, 0.28, 0.3),
		"", altezza,
		{"belly": _rng.randf_range(0.6, 1.0), "bald": i != 1,
		"moustache": i != 2, "hair": Color(0.72, 0.71, 0.68)})
	var root: Node3D = p["root"]
	# Il bacino sopra al centro della sedia, un palmo sopra alla seduta
	# (la seduta è un'asse, il sedere ha uno spessore).
	root.position = Vector3(0.0, SEDUTA_Y + 0.10 - Anim.BACINO_SEDUTO * altezza,
		-DIETRO_SEDUTO * altezza)
	var a = p.get("anim", null)
	if a != null:
		a.sit(false)
	_anim_giocatori.append(a)
	var w := Node3D.new()
	w.add_child(root)
	return w


## Tre carte coperte davanti a ognuno, sul piano: la mano che aspetta il
## turno. Prima era un ventaglio sospeso davanti al petto — senza mani che
## lo tenessero, perché le braccia erano stese di lato.
func _carte_davanti(pos: Vector3) -> void:
	var dir: Vector3 = pos.normalized()
	for k in range(3):
		var c := MeshInstance3D.new()
		c.mesh = CarteScript.mesh(1.0)
		c.material_override = CarteScript.retro()
		c.rotation.x = -PI / 2.0
		c.rotation.y = atan2(dir.x, dir.z) + (k - 1) * 0.18
		c.position = dir * 0.42 + Vector3(0, TAVOLO_H + 0.022 + k * 0.002, 0)
		add_child(c)


func _build_collisione() -> void:
	var f := CollisionShape3D.new()
	var c := CylinderShape3D.new()
	c.radius = 1.15
	c.height = 1.7
	f.shape = c
	f.position = Vector3(0, 0.85, 0)
	add_child(f)


# ---------------------------------------------------------------------------
# La partita
# ---------------------------------------------------------------------------

func _nuova_partita() -> void:
	_mazzo.clear()
	for i in range(40):
		_mazzo.append(i)
	# Mescolata con un RNG mio: se usassi randi() globale, i quattro tavoli
	# della città farebbero tutti la stessa partita.
	for i in range(_mazzo.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var t := _mazzo[i]
		_mazzo[i] = _mazzo[j]
		_mazzo[j] = t
	_mani = [[], [], [], []]
	_tavolo.clear()
	_punti = [0, 0, 0, 0]
	# Quattro sul tavolo, tre per uno in mano: è la scopa.
	for _k in range(4):
		_tavolo.append(_mazzo.pop_back())
	_distribuisci()
	_ridisegna_tavolo()


func _distribuisci() -> void:
	for g in range(4):
		while _mani[g].size() < 3 and not _mazzo.is_empty():
			_mani[g].append(_mazzo.pop_back())


## Il valore della carta, da 1 (asso) a 10 (re). L'atlante è ordinato per
## valore lungo le colonne, quindi è la colonna più uno.
func _valore(i: int) -> int:
	return (i % CarteScript.COLONNE) + 1


func _physics_process(delta: float) -> void:
	if _zitti_fino > 0.0:
		_zitti_fino -= delta
	_t -= delta
	if _t > 0.0:
		return
	_t = MOSSA_OGNI * _rng.randf_range(0.75, 1.3)
	_mossa()


func _mossa() -> void:
	if _mani[_turno].is_empty():
		_distribuisci()
		if _mani[_turno].is_empty():
			_dici(_turno, SAY_FINE[_rng.randi_range(0, SAY_FINE.size() - 1)])
			_nuova_partita()
			return

	var carta: int = _mani[_turno].pop_back()
	var v := _valore(carta)
	# Chi cala alza le mani sul tavolo (`Sitting_Talking`), chi ha appena
	# calato se le rimette in grembo. È l'unico gesto che serve per capire,
	# da dieci metri, che la partita va avanti.
	_gesto(_turno, true)
	_gesto((_turno + 3) % 4, false)

	# La presa: prima si prova la carta uguale (è la regola: se c'è una
	# carta uguale si prende quella e solo quella), poi le somme.
	var presa: Array[int] = []
	for c in _tavolo:
		if _valore(c) == v:
			presa = [c]
			break
	if presa.is_empty():
		presa = _somma(v)

	if presa.is_empty():
		_tavolo.append(carta)
		if _rng.randf() < 0.35:
			_dici(_turno, SAY_NIENTE[_rng.randi_range(0, SAY_NIENTE.size() - 1)])
	else:
		for c in presa:
			_tavolo.erase(c)
		_punti[_turno] += presa.size() + 1
		if _tavolo.is_empty() and not _mazzo.is_empty():
			# Scopa: hai svuotato il tavolo. È l'unico momento in cui uno
			# di questi quattro alza la voce.
			_dici(_turno, SAY_SCOPA[_rng.randi_range(0, SAY_SCOPA.size() - 1)])
			_punti[_turno] += 3
		else:
			_dici(_turno, SAY_PRESA[_rng.randi_range(0, SAY_PRESA.size() - 1)])

	# Ogni tanto litigano, che è il vero motivo per cui si gioca a carte.
	if _rng.randf() < 0.12:
		var altro := (_turno + 1 + _rng.randi_range(0, 2)) % 4
		_dici(altro, SAY_LITIGA[_rng.randi_range(0, SAY_LITIGA.size() - 1)])

	_ridisegna_tavolo()
	_turno = (_turno + 1) % 4


func _gesto(chi: int, su: bool) -> void:
	if chi < 0 or chi >= _anim_giocatori.size():
		return
	var a = _anim_giocatori[chi]
	if a != null and is_instance_valid(a):
		a.sit(su)


## Il sottoinsieme del tavolo che somma a `v`. Cerca prima le coppie, poi le
## terne: nella scopa vera si prende il gruppo più piccolo che si può, e
## comunque sul tavolo non ci sono quasi mai più di sei carte.
func _somma(v: int) -> Array[int]:
	var n := _tavolo.size()
	for a in range(n):
		for b in range(a + 1, n):
			if _valore(_tavolo[a]) + _valore(_tavolo[b]) == v:
				return [_tavolo[a], _tavolo[b]]
	for a in range(n):
		for b in range(a + 1, n):
			for c in range(b + 1, n):
				if _valore(_tavolo[a]) + _valore(_tavolo[b]) \
						+ _valore(_tavolo[c]) == v:
					return [_tavolo[a], _tavolo[b], _tavolo[c]]
	var vuoto: Array[int] = []
	return vuoto


## Le carte scoperte, sparse sul piano. Sono nodi ricreati a ogni mossa: sono
## al massimo una decina di quad, e ricrearli costa meno che tenere un pool
## sincronizzato con un array che cambia di continuo.
func _ridisegna_tavolo() -> void:
	for n in _nodi_tavolo:
		if is_instance_valid(n):
			n.queue_free()
	_nodi_tavolo.clear()
	for i in range(_tavolo.size()):
		var c := MeshInstance3D.new()
		c.mesh = CarteScript.mesh(1.0)
		c.material_override = CarteScript.materiale(_tavolo[i])
		c.rotation.x = -PI / 2.0
		# Sparse ma dentro al piano, e ognuna girata un po' per conto suo:
		# una griglia ordinata sembrerebbe un solitario, non una partita.
		var ang: float = TAU * i / maxf(1.0, float(_tavolo.size())) + 0.4
		var r: float = 0.13 + (i % 3) * 0.075
		c.position = Vector3(cos(ang) * r, TAVOLO_H + 0.023 + i * 0.0012,
			sin(ang) * r)
		c.rotation.y = ang * 0.6
		add_child(c)
		_nodi_tavolo.append(c)


## Le battute escono solo se c'è qualcuno che le può sentire: quattro tavoli
## che chiacchierano in una città vuota sono quattro sorgenti audio sprecate
## e quattro bolle di testo che si aggiornano per nessuno.
func _dici(chi: int, testo: String) -> void:
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null or not is_instance_valid(pl):
		return
	if global_position.distance_to(pl.global_position) > RAGGIO_UDITO:
		return
	# Uno alla volta: due bolle accese insieme su un tavolo da un metro si
	# coprono a vicenda e non si legge nessuna delle due.
	if _zitti_fino > 0.0:
		return
	if chi < _bolle.size() and is_instance_valid(_bolle[chi]):
		_bolle[chi].say(testo, 2.2)
		_zitti_fino = PAUSA_FRA_BATTUTE
