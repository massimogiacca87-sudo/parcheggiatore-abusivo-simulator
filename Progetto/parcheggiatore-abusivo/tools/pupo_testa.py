"""**'A capa d''o pupo, a piezze** (0.66).

La testa del pupo com'è in Schedule I — un uovo liscio con la faccia quasi
piatta, gli occhi a palla che sporgono, le palpebre spesse che ne coprono un
pezzo — ma con le facce di qua: il naso aquilino, il guappo ingellato, la
signora cotonata, la nonna col tuppo, i baffoni.

Il regista (`build_personaggi.py`) chiama `pezzi()` e per ogni coppia
`(nome, funzione)` fa un oggetto: `testa` (cranio, orecchie, occhi, iridi) e
poi le famiglie che il gioco accende una alla volta (`human_builder.
_scegli_pezzi`): `palpebre_*`, `sopracciglia_*`, `naso_*`, `capelli_*`,
`baffi`. Bocca, barba e rughe **non stanno qui**: le dipinge lo shader della
faccia sulla superficie `faccia` (vedi il contratto delle UV nel regista).

**Ogni pezzo s'appoggia 'ncopp'ô cranio overo, no 'ncopp'a 'na palla
'mmaginata.** Fino alla 0.65 sopracciglia e capelli si mettevano su una
sfera di conto, e il cranio vero (fatto a spicchi) stava qualche millimetro
più dentro o più fuori a seconda dello spicchio: ne uscivano capelli a
chiazze e sopracciglia che spuntavano dal profilo. Qui il cranio si fa una
volta (`cranio()`), se ne fa un albero di ricerca (`BVHTree`) e ogni pezzo
chiede **al cranio fatto a triangoli** dove sta la pelle: i capelli stanno
a spessore misurato sopra la pelle vera, le sopracciglia ci si incollano,
le palpebre ci si infilano dentro ai bordi.

Coordinate di Blender: **Z su, il pupo guarda a −Y, +X è la sua sinistra.**

    python3 tools/pupo_testa.py      # conta i triangoli e fa i controlli
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy  # noqa: E402,F401 — porta con sé mathutils
from mathutils import Vector                    # noqa: E402
from mathutils.bvhtree import BVHTree           # noqa: E402
import build_personaggi as B                    # noqa: E402

C = Vector(B.TESTA_C)
PH = {"Head": 1.0}
## Il centro da cui si guardano i capelli: un filo dietro al centro della
## testa. Da qui il cranio è "stellato": ogni raggio buca la pelle una
## volta sola, e la distanza lungo il raggio dice dove sta la pelle.
O = C + Vector((0.0, 0.004, 0.0))


def _liscio(t):
	t = min(1.0, max(0.0, t))
	return t * t * (3.0 - 2.0 * t)


def _tab(tab, x):
	"""Interpolazione a spezzata su una tabella [(x, valore), ...]."""
	if x <= tab[0][0]:
		return tab[0][1]
	for (x0, v0), (x1, v1) in zip(tab, tab[1:]):
		if x <= x1:
			return v0 + (v1 - v0) * (x - x0) / (x1 - x0)
	return tab[-1][1]


def _piega(a):
	"""Da un giro (0–360, 0 davanti, 90 la sinistra del pupo) a quanto si è
	lontani dal davanti (0–180) e da che lato (+1 sinistra, −1 destra)."""
	a = a % 360.0
	return (a, 1.0) if a <= 180.0 else (360.0 - a, -1.0)


def _dir(th, a):
	"""Direzione dal centro dei capelli: `th` gradi dalla verticale, `a`
	gradi di giro (0 davanti, 90 la sinistra del pupo)."""
	t = math.radians(th)
	b = math.radians(a)
	return Vector((math.sin(t) * math.sin(b), -math.sin(t) * math.cos(b),
		math.cos(t)))


def _giro(lato):
	"""Da mezzo giro (0…180) al giro intero, in ordine crescente."""
	return list(lato) + [360.0 - a for a in reversed(lato[1:-1])]


def _poli(g, vs, mat, fuori, liscio=True):
	"""Una faccia girata dalla parte di `fuori`: quando l'ordine dei vertici
	non si sa a memoria (orecchie, sopracciglia, naso) si dice dove deve
	guardare e lei si gira da sola."""
	n = Vector((0.0, 0.0, 0.0))
	for i in range(len(vs)):
		n += vs[i].co.cross(vs[(i + 1) % len(vs)].co)
	if n.dot(fuori) < 0.0:
		vs = list(reversed(vs))
	return g.faccia(vs, mat, liscio)


def _griglia(g, colonne, mat, chiusa, polo=None, fuori=None):
	"""Cuce una griglia di colonne (ognuna una lista di vertici dall'alto in
	basso, colonne in giro crescente). Con quest'ordine le facce guardano
	già fuori: è lo stesso verso del cranio."""
	n = len(colonne)
	fine = n if chiusa else n - 1
	for j in range(fine):
		a = colonne[j]
		b = colonne[(j + 1) % n]
		for i in range(len(a) - 1):
			q = [a[i], a[i + 1], b[i + 1], b[i]]
			if fuori is None:
				g.faccia(q, mat)
			else:
				_poli(g, q, mat, fuori(q))
		if polo is not None:
			g.faccia([polo, a[0], b[0]], mat)


# ---------------------------------------------------------------------------
# 'O cranio: n'uovo a fette
# ---------------------------------------------------------------------------
#
# Il cranio è una pila di fette orizzontali. Ogni fetta è fatta di due mezze
# superellissi: davanti con l'esponente alto (3 = quasi un rettangolo coi
# bordi tondi: **la faccia piatta** di Schedule I), dietro con l'esponente 2
# (la nuca tonda). Le misure sono relative a TESTA_C, e tre sono contratto
# con chi appende roba all'osso Head (cappelli, occhiali):
#
#   * la cima a 1,787 (contratto: 1,789 ± 1 cm);
#   * la larghezza alle orecchie ±0,118;
#   * la fronte a quota 1,70 con y = −0,132.
#
# **E 'a capa se chiude sotto, attorno ô cuollo.** Una testa di Schedule I
# è un uovo intero appoggiato sul collo, non una mascella con la nuca
# scavata: il fondo della testa è una cupola bassa che contiene la cima del
# collo (a 1,535, raggio 5 cm), così quando la testa si piega non si apre
# mai il buco fra collo e nuca.
#
#   (z, mezza larghezza, y davanti, y dietro, y della larghezza massima,
#    esponente davanti, esponente dietro)
FETTE = [
	(0.1245, 0.046, -0.046, 0.056, 0.004, 2.0, 2.0),
	(0.1060, 0.083, -0.086, 0.092, 0.004, 2.2, 2.0),
	(0.0780, 0.106, -0.108, 0.113, 0.004, 2.4, 2.0),
	(0.0460, 0.116, -0.120, 0.121, 0.004, 2.7, 2.05),
	(0.0120, 0.118, -0.122, 0.119, 0.004, 2.9, 2.1),
	(-0.0200, 0.116, -0.122, 0.110, 0.000, 3.0, 2.1),
	(-0.0520, 0.108, -0.119, 0.094, -0.004, 3.1, 2.1),
	(-0.0800, 0.097, -0.113, 0.080, -0.006, 3.0, 2.05),
	(-0.1030, 0.083, -0.104, 0.070, -0.006, 2.7, 2.0),
	(-0.1190, 0.063, -0.089, 0.061, -0.008, 2.4, 2.0),
]
POLO_SU = Vector((0.0, 0.004, 0.1335))
POLO_GIU = Vector((0.0, -0.016, -0.1285))
## Gli spicchi, in gradi di giro: più fitti davanti, dove c'è la faccia.
COLONNE = (0, 20, 40, 60, 82, 108, 135, 158, 180, 202, 225, 252, 278, 300,
	320, 340)


def _punto_fetta(f, phi):
	z, W, yF, yB, yW, nF, nB = f
	s = math.sin(math.radians(phi))
	c = -math.cos(math.radians(phi))
	if c <= 0.0:
		D, n = yW - yF, nF
	else:
		D, n = yB - yW, nB
	k = (abs(s) / W) ** n + (abs(c) / D) ** n
	r = k ** (-1.0 / n)
	return Vector((C.x + s * r, C.y + yW + c * r, C.z + z))


_CRANIO = None


def cranio():
	"""(vertici, facce, albero di ricerca) del cranio. Fatto una volta."""
	global _CRANIO
	if _CRANIO is None:
		vs = [C + POLO_SU]
		for f in FETTE:
			for phi in COLONNE:
				vs.append(_punto_fetta(f, phi))
		vs.append(C + POLO_GIU)
		n = len(COLONNE)
		facce = []
		for j in range(n):
			facce.append((0, 1 + j, 1 + (j + 1) % n))
		for i in range(len(FETTE) - 1):
			a0 = 1 + i * n
			a1 = a0 + n
			for j in range(n):
				k = (j + 1) % n
				facce.append((a0 + j, a1 + j, a1 + k, a0 + k))
		ult = 1 + (len(FETTE) - 1) * n
		giu = len(vs) - 1
		for j in range(n):
			facce.append((ult + j, giu, ult + (j + 1) % n))
		_CRANIO = (vs, facce, BVHTree.FromPolygons(vs, facce))
	return _CRANIO


def _raggio(u, da=None):
	"""Quanto dista la pelle lungo `u` partendo da `da` (di solito O)."""
	hit = cranio()[2].ray_cast(O if da is None else da, u)
	return hit[3]


def _davanti(x, z):
	"""Il punto della pelle che si vede guardando la faccia da davanti."""
	hit = cranio()[2].ray_cast(Vector((x, C.y - 0.5, z)), Vector((0, 1, 0)))
	return hit[0]


def _pelle_davanti(x, z, h=0.006):
	"""Punto e normale della faccia vista da davanti. La normale si misura
	sulla pelle a sei millimetri di qua e di là, non sulla faccetta colpita:
	così due sezioni vicine di un sopracciglio non saltano da uno spicchio
	all'altro."""
	p = _davanti(x, z)
	fx = (_davanti(x + h, z).y - _davanti(x - h, z).y) / (2.0 * h)
	fz = (_davanti(x, z + h).y - _davanti(x, z - h).y) / (2.0 * h)
	return p, Vector((fx, -1.0, fz)).normalized()


def dentro(p, margine=0.0):
	"""`p` sta dentro al cranio (di almeno `margine`)?"""
	d = p - O
	L = d.length
	if L < 1e-6:
		return True
	r = _raggio(d / L)
	return r is not None and L < r - margine


def _rintana(p, margine=0.0015):
	"""Spinge `p` all'indietro finché non sta dentro al cranio: così i bordi
	di un guscio (palpebre) finiscono sotto la pelle e non si vedono."""
	q = p.copy()
	for _ in range(80):
		if dentro(q, margine):
			break
		q.y += 0.0006
	return q


# ---------------------------------------------------------------------------
# 'A capa: cranio, recchie, uocchie
# ---------------------------------------------------------------------------

## **'E uocchie.** Il centro è contratto (le UV dell'iride lo sanno): ±0,043
## e 1,2 cm sopra al centro della testa. La profondità è nostra: il centro
## dell'occhio sta **sulla pelle**, così la palla sporge per metà — che è
## la cosa che fa Schedule I — e la punta arriva a y = −0,156 (il limite è
## −0,160). Raggio due centimetri e mezzo: con 2,4 gli occhi erano giusti
## ma non "a palla".
R_OCCHIO = 0.025
Y_OCCHIO = -0.119
SEG_OCCHIO = 10
## L'iride sta sei decimi di millimetro sopra al bianco: il disco è il
## pezzo di sfera che visto da davanti è largo esattamente IRIDE_R, così la
## pupilla dipinta cade al centro della texture.
DELTA_IRIDE = 0.0006


def centro_occhio(sx):
	return Vector((sx * B.OCCHIO_X, C.y + Y_OCCHIO, C.z + B.OCCHIO_Z_SU))


def _occhio(g, sx):
	E = centro_occhio(sx)
	R = R_OCCHIO
	a_iride = math.degrees(math.asin(B.IRIDE_R / (R + DELTA_IRIDE)))
	# Il primo anello del bianco sta dove finisce l'iride, così l'iride è
	# la calotta del bianco gonfiata di un soffio: non lo buca da nessuna
	# parte. L'ultimo anello (120°) sta già dentro alla testa.
	anelli = [a_iride, 62.0, 90.0, 120.0]
	betas = [math.radians(90.0 + 360.0 * k / SEG_OCCHIO)
		for k in range(SEG_OCCHIO)]

	def punto(al, be, r):
		al = math.radians(al)
		return E + Vector((math.sin(al) * math.cos(be), -math.cos(al),
			math.sin(al) * math.sin(be))) * r

	polo = g.vert(E + Vector((0.0, -R, 0.0)), PH)
	righe = [[g.vert(punto(al, be, R), PH) for be in betas] for al in anelli]
	n = SEG_OCCHIO
	for k in range(n):
		k2 = (k + 1) % n
		q = [polo, righe[0][k], righe[0][k2]]
		_poli(g, q, "occhio_bianco", sum((v.co for v in q), Vector()) / 3 - E)
		for i in range(len(righe) - 1):
			q = [righe[i][k], righe[i + 1][k], righe[i + 1][k2], righe[i][k2]]
			_poli(g, q, "occhio_bianco",
				sum((v.co for v in q), Vector()) / 4 - E)
	ci = g.vert(E + Vector((0.0, -(R + DELTA_IRIDE), 0.0)), PH)
	ri = [g.vert(punto(a_iride, be, R + DELTA_IRIDE), PH) for be in betas]
	for k in range(n):
		_poli(g, [ci, ri[k], ri[(k + 1) % n]], "iride", Vector((0, -1, 0)))


## **'E recchie a C.** Sei punti di contorno (visti di lato: davanti è +f,
## su è +u), un bordo esterno, una conca spostata in avanti — ed è la conca
## aperta davanti che fa leggere la C — e un anello di base dentro al
## cranio. Il bordo di dietro si stacca dalla testa (fino a un centimetro e
## mezzo): di spalle le orecchie si vedono, come sulle teste vere. Alla
## prima prova erano alte sei centimetri e da davanti non si vedevano:
## adesso sei e mezzo, e staccate un po' di più.
ORECCHIO = [(0.0115, 0.025), (-0.006, 0.033), (-0.018, 0.016),
	(-0.017, -0.009), (-0.005, -0.030), (0.009, -0.021)]
ORECCHIO_C = (0.013, -0.004)          # (y, z) relativi a TESTA_C


def orecchio(sx):
	"""I punti di un orecchio: (bordo, conca, fondo della conca, base)."""
	base = C + Vector((0.0, ORECCHIO_C[0], ORECCHIO_C[1]))
	n = Vector((sx, 0.0, 0.0))
	K = base + n * _raggio(n, base)
	f = Vector((0.0, -1.0, 0.0))
	u = Vector((0.0, 0.0, 1.0))

	def stacco(ff):
		return 0.0025 + 0.45 * (0.012 - ff)

	def pt(ff, uu, o):
		return K + f * ff + u * uu + n * o

	cq = (0.004, 0.001)
	A = [pt(ff, uu, stacco(ff) + 0.0025) for ff, uu in ORECCHIO]
	Q = []
	for ff, uu in ORECCHIO:
		qf = cq[0] + (ff - cq[0]) * 0.5
		qu = cq[1] + (uu - cq[1]) * 0.5
		Q.append(pt(qf, qu, stacco(qf) - 0.0010))
	fondo = pt(0.006, 0.0, 0.0015)
	D = [pt(0.002 + (ff - 0.002) * 0.8, uu * 0.8, -0.004) for ff, uu in ORECCHIO]
	return A, Q, fondo, D


def _orecchio(g, sx):
	n = Vector((sx, 0.0, 0.0))
	f = Vector((0.0, -1.0, 0.0))
	u = Vector((0.0, 0.0, 1.0))
	pA, pQ, pf, pD = orecchio(sx)
	A = [g.vert(p, PH) for p in pA]
	Q = [g.vert(p, PH) for p in pQ]
	fondo = g.vert(pf, PH)
	D = [g.vert(p, PH) for p in pD]
	m = len(ORECCHIO)
	for i in range(m):
		j = (i + 1) % m
		_poli(g, [A[i], Q[i], Q[j], A[j]], "pelle", n)
		_poli(g, [Q[i], fondo, Q[j]], "pelle", n)
		ff = (ORECCHIO[i][0] + ORECCHIO[j][0]) * 0.5
		uu = (ORECCHIO[i][1] + ORECCHIO[j][1]) * 0.5
		fuori = (f * ff + u * uu).normalized() - n * 0.4
		_poli(g, [A[i], A[j], D[j], D[i]], "pelle", fuori)


def testa(g):
	"""Cranio (tutto `faccia`: le parti che non guardano avanti le UV le
	mandano da sole nell'angolo neutro), orecchie (`pelle`), occhi e iridi."""
	vs, facce, _ = cranio()
	bv = [g.vert(v, PH) for v in vs]
	for f in facce:
		g.faccia([bv[i] for i in f], "faccia")
	for sx in (1.0, -1.0):
		_orecchio(g, sx)
		_occhio(g, sx)


# ---------------------------------------------------------------------------
# 'E pparpetole
# ---------------------------------------------------------------------------
#
# **È 'a firma 'e Schedule I.** Una palpebra è un guscio poco più largo
# dell'occhio (cinque millimetri sopra, quattro sotto) che finisce con un
# bordo spesso: il bordo scende dal guscio fin quasi sul bianco, e visto da
# davanti è una riga netta che taglia l'occhio. Dove sta quella riga dice
# l'umore.
#
# Ogni palpebra si descrive con l'angolo del bordo (gradi dalla cima
# dell'occhio per quella di sopra, dal fondo per quella di sotto). Agli
# angoli dell'occhio le due palpebre si incontrano sempre a 100° dalla
# cima, e il bordo ci arriva curvando (`_bordo_su`): è la forma a mandorla.
# **Chiuse** (la forma `chiudi`) quella di sopra scende a 102° e quella di
# sotto sale a 80° dal fondo: si incontrano tre millimetri sotto al centro,
# con due gradi di sovrapposizione.
#
# **'O guscio se 'nfila dint'â faccia.** La prima riga (dietro alla cima
# dell'occhio) e le due colonne d'angolo vengono spinte sotto la pelle
# (`_rintana`), così i bordi del guscio non si vedono mai — nemmeno di
# profilo, dove la faccia scappa indietro prima dell'occhio.
#
# **E 'a forma lineare nun ha da passà pe' dint'a ll'uocchio.** Una blend
# shape sposta i vertici in linea retta, e un punto che gira attorno a una
# palla tagliando la corda passa sotto la superficie. Il guscio sta cinque
# millimetri sopra al bianco apposta: con la corsa più lunga (sveglie, da
# 58° a 102°) il punto a metà strada resta ancora fuori.
#
#   nome: (bordo di sopra, quanto scende verso il naso,
#          bordo di sotto, quanto sale verso l'esterno)
PALPEBRE = {
	"sveglie": (58.0, 0.0, 34.0, 0.0),
	"stanche": (90.0, 0.0, 40.0, 0.0),
	"arraggiate": (77.0, 15.0, 38.0, 0.0),
	"furbe": (71.0, 7.0, 62.0, 9.0),
}
ANGOLO = 100.0
SU_CHIUSA = 102.0
GIU_CHIUSA = 80.0
R_SU_FUORI = R_OCCHIO + 0.0048
R_SU_DENTRO = R_OCCHIO + 0.0012
R_GIU_FUORI = R_OCCHIO + 0.0040
R_GIU_DENTRO = R_OCCHIO + 0.0010
## Le colonne del guscio, in gradi: negativo verso il naso, positivo verso
## la tempia.
PSI_SU = (-90.0, -60.0, -30.0, 0.0, 30.0, 60.0, 90.0)
PSI_GIU = (-90.0, -45.0, 0.0, 45.0, 90.0)


def _bordo_su(psi, base, incl):
	mezzo = base - incl * psi / 90.0
	k = min(1.0, abs(psi) / 90.0) ** 2.5
	return mezzo + (ANGOLO - mezzo) * k


def _bordo_giu(psi, base, incl):
	mezzo = base + incl * psi / 90.0
	k = min(1.0, abs(psi) / 90.0) ** 2.5
	return mezzo + ((180.0 - ANGOLO) - mezzo) * k


def _dir_occhio(sx, th, psi, sotto):
	t = math.radians(th)
	p = math.radians(psi)
	z = -math.cos(t) if sotto else math.cos(t)
	return Vector((sx * math.sin(t) * math.sin(p), -math.sin(t) * math.cos(p),
		z))


def _righe_palpebra(te, sotto):
	"""Le quattro righe di una colonna: radice (sotto la pelle), metà, bordo
	di fuori, bordo di dentro (quasi sul bianco)."""
	if sotto:
		ro, ri, stacco = R_GIU_FUORI, R_GIU_DENTRO, 4.0
	else:
		ro, ri, stacco = R_SU_FUORI, R_SU_DENTRO, 5.0
	tr = -10.0
	tb = te - stacco
	return [(tr, ro), ((tr + tb) * 0.5, ro), (tb, ro + 0.0004), (te, ri)]


def _palpebra(g, sx, sotto, aperta, psis):
	E = centro_occhio(sx)
	chiusa = GIU_CHIUSA if sotto else SU_CHIUSA
	colonne = []
	chiuse = {}
	for psi in psis:
		col = []
		ra = _righe_palpebra(aperta(psi), sotto)
		rc = _righe_palpebra(max(chiusa, aperta(psi)), sotto)
		for i, ((ta, r_a), (tc, r_c)) in enumerate(zip(ra, rc)):
			# Le colonne d'angolo si allargano prima di finire sotto la pelle:
			# spinte all'indietro e basta, la corda fra loro e la colonna
			# accanto passava *dentro* alla palla, e agli angoli dell'occhio
			# chiuso restava un filo di bianco.
			k = 1.12 if abs(psi) >= 89.9 else 1.0
			pa = E + _dir_occhio(sx, ta, psi, sotto) * (r_a * k)
			pc = E + _dir_occhio(sx, tc, psi, sotto) * (r_c * k)
			if i == 0 or abs(psi) >= 89.9:
				pa = _rintana(pa)
				pc = _rintana(pc)
			v = g.vert(pa, PH)
			chiuse[v] = pc
			col.append(v)
		colonne.append(col)
	for j in range(len(colonne) - 1):
		a, b = colonne[j], colonne[j + 1]
		for i in range(len(a) - 1):
			q = [a[i], a[i + 1], b[i + 1], b[i]]
			_poli(g, q, "pelle", sum((v.co for v in q), Vector()) / 4 - E)
	g.forma("chiudi", chiuse)


def palpebre(nome):
	su, su_i, giu, giu_i = PALPEBRE[nome]

	def fai(g):
		for sx in (1.0, -1.0):
			_palpebra(g, sx, False, lambda p: _bordo_su(p, su, su_i), PSI_SU)
			_palpebra(g, sx, True, lambda p: _bordo_giu(p, giu, giu_i), PSI_GIU)
	return fai


# ---------------------------------------------------------------------------
# 'E ssopracciglia
# ---------------------------------------------------------------------------
#
# Un blocchetto che corre sulla fronte: tre (o quattro) sezioni, e ogni
# sezione ha i due spigoli di dietro **un millimetro e mezzo sotto la
# pelle** e i due davanti a spessore sopra la pelle, misurati sulla fronte
# vera (`_pelle_davanti`). Così non c'è spigolo che resti fuori dal
# cranio: la trappola della 0.49 (le schegge che spuntavano dal profilo)
# veniva da un parallelepipedo dritto appoggiato a una testa tonda.
#
# Materiale `peli`: il gioco lo tinge per conto suo (di solito come i
# capelli, ma non per chi porta il fazzoletto).
#
#   per lato: [(x, z, altezza, sporgenza), ...] dal naso verso la tempia,
#   relativi a TESTA_C. Le sopracciglia stanno attorno a z = +0,05.
def _cigli_dritte(sx):
	return [(0.015, 0.051, 0.0145, 0.0060), (0.042, 0.054, 0.0135, 0.0065),
		(0.069, 0.051, 0.0100, 0.0050)]


def _cigli_arraggiate(sx):
	return [(0.016, 0.039, 0.0150, 0.0065), (0.041, 0.050, 0.0140, 0.0065),
		(0.068, 0.061, 0.0100, 0.0050)]


def _cigli_preoccupate(sx):
	return [(0.016, 0.066, 0.0125, 0.0060), (0.041, 0.059, 0.0125, 0.0060),
		(0.068, 0.047, 0.0100, 0.0050)]


def _cigli_scettiche(sx):
	# La sinistra del pupo s'alza ad arco — «e allora?» — l'altra resta
	# dritta e un filo bassa.
	if sx > 0:
		return [(0.016, 0.058, 0.0130, 0.0060), (0.041, 0.068, 0.0130, 0.0060),
			(0.068, 0.061, 0.0100, 0.0050)]
	return [(0.015, 0.049, 0.0140, 0.0060), (0.042, 0.051, 0.0130, 0.0060),
		(0.069, 0.048, 0.0100, 0.0050)]


def _cigli_sottili(sx):
	# Ad arco, sottili: quattro sezioni, le punte quasi a zero.
	return [(0.017, 0.053, 0.0045, 0.0032), (0.034, 0.062, 0.0060, 0.0036),
		(0.053, 0.063, 0.0050, 0.0034), (0.070, 0.054, 0.0020, 0.0025)]


SOPRACCIGLIA = {
	"dritte": _cigli_dritte,
	"arraggiate": _cigli_arraggiate,
	"preoccupate": _cigli_preoccupate,
	"scettiche": _cigli_scettiche,
	"sottili": _cigli_sottili,
}


def _ciglio(g, sx, sezioni, tappi):
	ss = []
	for x, z, h, p in sezioni:
		sb, nb = _pelle_davanti(sx * x, C.z + z - h * 0.5)
		st, nt = _pelle_davanti(sx * x, C.z + z + h * 0.5)
		ss.append([g.vert(sb - nb * 0.0015, PH), g.vert(sb + nb * p, PH),
			g.vert(st + nt * p, PH), g.vert(st - nt * 0.0015, PH)])
	for s0, s1 in zip(ss, ss[1:]):
		cen = sum((v.co for v in s0 + s1), Vector()) / 8.0
		for i in range(3):
			q = [s0[i], s0[i + 1], s1[i + 1], s1[i]]
			_poli(g, q, "peli", sum((v.co for v in q), Vector()) / 4 - cen)
	if tappi:
		for s, altro in ((ss[0], ss[1]), (ss[-1], ss[-2])):
			fuori = (sum((v.co for v in s), Vector())
				- sum((v.co for v in altro), Vector()))
			_poli(g, list(s), "peli", fuori)


def sopracciglia(nome):
	fn = SOPRACCIGLIA[nome]

	def fai(g):
		for sx in (1.0, -1.0):
			sez = fn(sx)
			_ciglio(g, sx, sez, tappi=len(sez) <= 3)
	return fai


# ---------------------------------------------------------------------------
# 'O naso
# ---------------------------------------------------------------------------
#
# Un tubo aperto dietro, appoggiato sulla faccia dalla radice (fra gli
# occhi) alla base (sopra al labbro): ogni sezione è una mezza ellisse che
# parte e finisce **tre millimetri sotto la pelle** e sporge davanti di
# quanto dice la tabella. Il profilo del naso lo fa la sporgenza sezione per
# sezione, la larghezza lo fa `w`, e `dz` sposta in su o in giù la punta
# della sezione (è così che la punta dell'aquilino scende).
#
# La punta sta a z ≈ C − 0,018 (contratto con la texture della faccia).
#
#   (z, sporgenza, mezza larghezza, dz) — relativi a TESTA_C
NASI = {
	# A bottone: corto, tondo, la punta un filo all'insù.
	"piccolo": ([(0.015, 0.003, 0.0070, 0.0), (0.003, 0.009, 0.0080, 0.0),
		(-0.008, 0.016, 0.0105, 0.0), (-0.017, 0.021, 0.0135, 0.0015),
		(-0.025, 0.016, 0.0150, 0.0030), (-0.031, 0.004, 0.0130, 0.0)], 5),
	# A patata: la punta è una palla, le ali larghe.
	"grosso": ([(0.016, 0.004, 0.0080, 0.0), (0.003, 0.012, 0.0100, 0.0),
		(-0.009, 0.024, 0.0165, 0.0), (-0.019, 0.031, 0.0215, 0.0),
		(-0.029, 0.026, 0.0235, 0.0020), (-0.037, 0.006, 0.0195, 0.0)], 7),
	# Aquilino: lungo, la gobba sul dorso, la punta che scende.
	"aquilino": ([(0.019, 0.005, 0.0070, 0.0), (0.004, 0.018, 0.0080, 0.0),
		(-0.008, 0.023, 0.0090, 0.0), (-0.020, 0.031, 0.0110, -0.0010),
		(-0.030, 0.025, 0.0130, -0.0045), (-0.036, 0.006, 0.0120, 0.0030)], 5),
}


def naso(nome):
	tabella, m = NASI[nome]

	def fai(g):
		ang = [math.radians(-90.0 + 180.0 * k / (m - 1)) for k in range(m)]
		X = Vector((1.0, 0.0, 0.0))
		sez = []
		nuclei = []
		for z, h, w, dz in tabella:
			s = _davanti(0.0, C.z + z)
			K = s + Vector((0.0, 0.003, 0.0))
			Q = s + Vector((0.0, -h, dz))
			sez.append([g.vert(K + X * (w * math.sin(a)) + (Q - K) * math.cos(a),
				PH) for a in ang])
			nuclei.append(K)
		for i in range(len(sez) - 1):
			cen = (nuclei[i] + nuclei[i + 1]) * 0.5
			for k in range(m - 1):
				q = [sez[i][k], sez[i + 1][k], sez[i + 1][k + 1], sez[i][k + 1]]
				_poli(g, q, "pelle", sum((v.co for v in q), Vector()) / 4 - cen)
		_poli(g, sez[0], "pelle", nuclei[0] - nuclei[1])
		_poli(g, sez[-1], "pelle", nuclei[-1] - nuclei[-2])
	return fai


# ---------------------------------------------------------------------------
# 'E baffe
# ---------------------------------------------------------------------------
#
# Baffoni: un cordone spesso che corre sul labbro di sopra da un angolo
# della bocca all'altro, e ai lati **scende** (spioventi). Sotto al naso sta
# a −0,040 (sotto la base del naso più grosso), e in mezzo lascia scoperta
# la bocca dipinta (−0,062): la copre solo agli angoli.
#
#   (x, z di sopra, z di sotto, sporgenza) dalla punta destra alla sinistra
BAFFI = [
	(-0.045, -0.057, -0.079, 0.0040), (-0.033, -0.043, -0.069, 0.0085),
	(-0.017, -0.0395, -0.0585, 0.0105), (0.000, -0.0415, -0.0560, 0.0095),
	(0.017, -0.0395, -0.0585, 0.0105), (0.033, -0.043, -0.069, 0.0085),
	(0.045, -0.057, -0.079, 0.0040),
]


def baffi(g):
	sez = []
	centri = []
	for x, zs, zg, p in BAFFI:
		zm = (zs + zg) * 0.5
		s1, n1 = _pelle_davanti(x, C.z + zs)
		s2, n2 = _pelle_davanti(x, C.z + zs - 0.003)
		s3, n3 = _pelle_davanti(x, C.z + zm)
		s4, n4 = _pelle_davanti(x, C.z + zg + 0.002)
		s5, n5 = _pelle_davanti(x, C.z + zg)
		sez.append([g.vert(s1 - n1 * 0.002, PH), g.vert(s2 + n2 * p * 0.75, PH),
			g.vert(s3 + n3 * p, PH), g.vert(s4 + n4 * p * 0.55, PH),
			g.vert(s5 - n5 * 0.002, PH)])
		centri.append(s3)
	for i in range(len(sez) - 1):
		cen = (centri[i] + centri[i + 1]) * 0.5
		for k in range(4):
			q = [sez[i][k], sez[i][k + 1], sez[i + 1][k + 1], sez[i + 1][k]]
			_poli(g, q, "peli", sum((v.co for v in q), Vector()) / 4 - cen)
	_poli(g, sez[0], "peli", Vector((-1.0, 0.0, -0.3)))
	_poli(g, sez[-1], "peli", Vector((1.0, 0.0, -0.3)))


# ---------------------------------------------------------------------------
# 'E capille
# ---------------------------------------------------------------------------
#
# **Nun è 'nu casco.** Una capigliatura è una griglia di colonne che
# partono dalla cima e scendono fino all'attaccatura; ogni vertice sta
# lungo il suo raggio (da O) **a spessore misurato sopra la pelle vera**
# (`_raggio`), e l'ultima riga (il rimbocco) torna tre millimetri sotto la
# pelle: il bordo dei capelli è un gradino spesso e pulito, come nelle
# teste di Schedule I, e non un orlo di carta.
#
# **'A trappola d''e chiazze** (la stessa della 0.49, vedi `capelli()` nel
# regista): fra due vertici la faccia è una corda, e la corda affonda. Il
# conto a mano non basta: dietro, dove l'attaccatura scende fino alla nuca,
# fra una riga e l'altra ci sono venticinque gradi, e il cranio in quel
# punto fa la sua gobba. Alla prima prova i capelli corti toccavano la
# pelle proprio lì, dietro l'orecchio, in alto.
#
# Allora la griglia **se gonfia** (`_gonfia`): si tirano raggi da O in
# tutte le direzioni (uno ogni due-tre gradi, più uno per ogni vertice del
# cranio e delle orecchie) e dove una faccia dei capelli passa a meno di
# MARGINE_PELLE dalla pelle (o a meno di MARGINE_ORECCHIO da un orecchio)
# i suoi vertici si spingono fuori di quel che manca. Le facce si guardano
# con **tutte e due le diagonali**, che non si sa come le spezzerà
# l'esportatore. Lo spessore resta quello del disegno dove basta, e cresce
# di un paio di millimetri solo dove serve.
#
# `profilo(a, j)` dà, per la colonna al giro `a` (indice `j`), la lista
# delle righe dall'alto in basso: (gradi dalla verticale, spessore, spinta
# in più o None). Uno spessore negativo è un rimbocco (sotto la pelle).

RIMBOCCO = (3.0, -0.003)             # gradi oltre l'attaccatura, spessore
MARGINE_PELLE = 0.0045
MARGINE_ORECCHIO = 0.0025
## L'attaccatura di un uomo, in gradi dalla verticale per ogni giro: la
## fronte (51°: z ≈ C + 0,085, contratto), le tempie, **la basetta** davanti
## all'orecchio (fino a z ≈ C − 0,012), la tacca sopra l'orecchio, la nuca.
ATTACCATURA_UOMO = [(0, 51), (18, 52), (36, 56), (52, 62), (64, 70),
	(74, 96), (82, 96), (90, 72), (98, 71), (108, 88), (120, 110),
	(138, 123), (158, 129), (180, 131)]
## Le colonne sono messe apposta attorno all'orecchio (che sta fra 87° e
## 101° di giro): basetta a 74–82, tacca a 90–98, dietro a 108.
LATO_UOMO = [0, 18, 36, 52, 64, 74, 82, 90, 98, 108, 120, 138, 158, 180]


def _punto_capelli(th, a, T, spinta=None):
	u = _dir(th, a)
	p = O + u * (_raggio(u) + T)
	if spinta is not None:
		p = p + spinta
	return p


_OSTACOLI = None


def _ostacoli():
	"""(direzione da O, distanza sotto la quale i capelli non devono
	scendere): la pelle ogni due-tre gradi, ogni vertice del cranio e ogni
	punto esterno delle orecchie."""
	global _OSTACOLI
	if _OSTACOLI is None:
		out = []
		punti = [(v, MARGINE_PELLE) for v in cranio()[0]]
		for sx in (1.0, -1.0):
			A, Q, fondo, D = orecchio(sx)
			punti += [(p, MARGINE_ORECCHIO) for p in A + Q + [fondo]]
		for p, m in punti:
			d = p - O
			out.append((d.normalized(), d.length + m))
		for i in range(1, 90):
			for k in range(120):
				u = _dir(2.0 * i, 3.0 * k)
				r = _raggio(u)
				if r is not None:
					out.append((u, r + MARGINE_PELLE))
		_OSTACOLI = out
	return _OSTACOLI


def _gonfia(P, chiusa, polo=None):
	"""P = colonne di [posizione, rimbocco?]. Sposta le posizioni sul posto."""
	n = len(P)
	facce = []
	for j in range(n if chiusa else n - 1):
		k = (j + 1) % n
		for i in range(len(P[j]) - 1):
			q = [P[j][i], P[j][i + 1], P[k][i + 1], P[k][i]]
			if not any(c[1] for c in q):
				facce.append(q)
		if polo is not None:
			facce.append([polo, P[j][0], P[k][0]])
	# Ogni quadrilatero entra con i quattro triangoli delle due diagonali.
	tri = []
	for f, q in enumerate(facce):
		if len(q) == 3:
			tri.append((f, (0, 1, 2)))
		else:
			for t in ((0, 1, 2), (0, 2, 3), (0, 1, 3), (1, 2, 3)):
				tri.append((f, t))
	ost = _ostacoli()
	for _ in range(24):
		vs = []
		polys = []
		for f, t in tri:
			polys.append([len(vs), len(vs) + 1, len(vs) + 2])
			vs += [facce[f][i][0] for i in t]
		bvh = BVHTree.FromPolygons(vs, polys)
		spinte = {}
		for u, serve in ost:
			hit = bvh.ray_cast(O, u)
			if hit[0] is None or hit[3] >= serve:
				continue
			manca = (serve - hit[3]) * 1.05 + 0.0002
			for c in facce[tri[hit[2]][0]]:
				vecchia = spinte.get(id(c), (c, 0.0))[1]
				spinte[id(c)] = (c, max(vecchia, manca))
		if not spinte:
			break
		for c, m in spinte.values():
			c[0] = c[0] + (c[0] - O).normalized() * m


def _capelli(g, colonne_a, profilo, chiusa=True, T_polo=None, pesi=None,
		mat="capelli"):
	pesi = pesi or (lambda p: PH)
	P = [[[_punto_capelli(th, a, T, sp), T < 0.0] for th, T, sp in profilo(a, j)]
		for j, a in enumerate(colonne_a)]
	polo = None
	if T_polo is not None:
		su = Vector((0.0, 0.0, 1.0))
		polo = [O + su * (_raggio(su) + T_polo), False]
	_gonfia(P, chiusa, polo)
	colonne = [[g.vert(c[0], pesi(c[0])) for c in col] for col in P]
	pv = g.vert(polo[0], PH) if polo is not None else None
	_griglia(g, colonne, mat, chiusa, polo=pv)
	return colonne


def _calotta(g, lato, profilo, T_polo):
	return _capelli(g, _giro(lato), profilo, True, T_polo)


def _con_rimbocco(righe, te, T=None):
	return righe + [(te + RIMBOCCO[0], RIMBOCCO[1] if T is None else T, None)]


def _volume(u, centro, raggi):
	"""Da O lungo `u`, quanto c'è fino al bordo di un ellissoide (O sta
	dentro). Serve alle pettinature che hanno una forma loro — la messa in
	piega, il rullo del gellato — e non sono solo "la testa più uno
	spessore": quelle vengono a casco per forza."""
	o = Vector(((O.x - centro.x) / raggi.x, (O.y - centro.y) / raggi.y,
		(O.z - centro.z) / raggi.z))
	d = Vector((u.x / raggi.x, u.y / raggi.y, u.z / raggi.z))
	A = d.dot(d)
	Bq = 2.0 * o.dot(d)
	Cq = o.dot(o) - 1.0
	disc = Bq * Bq - 4.0 * A * Cq
	if disc < 0.0:
		return 0.0
	return (-Bq + math.sqrt(disc)) / (2.0 * A)


# -- corti: il taglio di tutti, con la riga e la frangetta a punte ----------
# Stanno entro un centimetro e due dalla pelle (ci va sopra il berretto),
# quindi la forma non la può fare il volume: la fanno **la riga** (un solco
# a sinistra, dalla fronte verso la cima), **il ciuffo** pettinato via dalla
# riga, e **la frangetta a punte** — davanti le colonne pari scendono di
# cinque gradi (e si staccano un filo dalla fronte) e le dispari salgono di
# uno e mezzo: da lontano è il bordo a zig-zag delle teste di Schedule I,
# non la tesa di un casco. (Con tre gradi, alla prima prova, non si vedeva.)
def _prof_corti(a, j):
	af, lato = _piega(a)
	te = _tab(ATTACCATURA_UOMO, af)
	punta = af < 50.0 and j % 2 == 0
	if af < 50.0:
		te += (5.0 if punta else -1.5) * (1.0 - af / 50.0)
	righe = []
	for t in (0.14, 0.28, 0.42, 0.58, 0.74, 0.87, 0.95, 1.0):
		th = t * te
		T = 0.0064 + 0.0032 * _liscio(1.0 - (th - 30.0) / 40.0)
		if lato > 0 and abs(af - 36.0) < 0.5 and t > 0.3:
			T = 0.0052
		if lato < 0 and af < 60.0:
			T += 0.0022 * _liscio((t - 0.45) / 0.45) * (1.0 - af / 60.0)
		if 70.0 <= af <= 100.0:
			T = min(T, 0.0066)
		sp = None
		if t >= 0.999 and punta:
			sp = Vector((0.0, -0.003, -0.001))
		righe.append((th, min(T, 0.0115), sp))
	return _con_rimbocco(righe, te)


def capelli_corti(g):
	_calotta(g, LATO_UOMO, _prof_corti, 0.0105)


# -- gellati: tirati 'ndreto, c''o rullo 'ncopp'â fronte --------------------
# Il guappo: lati incollati alla testa, e sopra la fronte **il rullo** —
# i capelli salgono dall'attaccatura, sporgono in avanti di mezzo
# centimetro e poi vanno indietro lisci, coi solchi del pettine. Lo
# spessore davanti si dà riga per riga; ai lati sfuma a zero.
## L'attaccatura a M: la punta in mezzo e le tempie che se ne vanno. Con
## l'attaccatura dritta, da davanti, il rullo si leggeva come la tesa di un
## berretto.
ATTACCATURA_GELLATI = [(0, 48.5), (14, 51), (30, 58), (44, 62.5), (54, 63.5),
	(64, 70)] + ATTACCATURA_UOMO[5:]
GELLATI_RULLO = [0.010, 0.017, 0.024, 0.029, 0.032, 0.030, 0.021, 0.010]


def _prof_gellati(a, j):
	af, lato = _piega(a)
	te = _tab(ATTACCATURA_GELLATI, af)
	F = math.cos(math.radians(min(af, 84.0) / 84.0 * 90.0)) ** 2
	quote = [0.20 * te, 0.40 * te, 0.58 * te, 0.74 * te, 0.86 * te,
		te - 4.0, te - 1.3, te]
	righe = []
	for i, (th, Tf) in enumerate(zip(quote, GELLATI_RULLO)):
		T = 0.0062 + max(0.0, Tf - 0.0062) * F
		if af < 118.0 and 1 <= i <= 5:
			T += 0.0022 if j % 2 == 0 else -0.0006
		sp = None
		if i == 5:
			sp = Vector((0.0, -0.004, 0.003)) * F
		elif i == 6:
			sp = Vector((0.0, -0.007, 0.001)) * F
		righe.append((th, T, sp))
	return _con_rimbocco(righe, te)


def capelli_gellati(g):
	_calotta(g, LATO_UOMO, _prof_gellati, 0.0120)


# -- ricci: 'na massa 'e riccioli a bozzi ------------------------------------
# Una scacchiera: un vertice sì e uno no esce di otto millimetri e mezzo e
# gli altri rientrano di tre. A due metri sono riccioli, e il bordo (che
# scende e sale di colonna in colonna) è quello di una testa riccia.
ATTACCATURA_RICCI = [(0, 56), (15, 57), (30, 59), (44, 63), (57, 70),
	(68, 86), (78, 90), (88, 72), (97, 71), (108, 86), (121, 108),
	(136, 119), (152, 124), (166, 126), (180, 127)]
LATO_RICCI = [0, 15, 30, 44, 57, 68, 78, 88, 97, 108, 121, 136, 152, 166, 180]


def _prof_ricci(a, j):
	af, lato = _piega(a)
	te = _tab(ATTACCATURA_RICCI, af) + (3.0 if j % 2 == 0 else -1.5)
	righe = []
	for i, t in enumerate((0.16, 0.32, 0.47, 0.61, 0.74, 0.86, 0.95, 1.0)):
		th = t * te
		T = 0.0235 - 0.0070 * _liscio((th - 70.0) / 50.0)
		if 70.0 <= af <= 100.0 and t > 0.8:
			T = max(0.013, T - 0.004)
		T += 0.0085 if (i + j) % 2 == 0 else -0.0030
		righe.append((th, T, None))
	return _con_rimbocco(righe, te)


def capelli_ricci(g):
	_calotta(g, LATO_RICCI, _prof_ricci, 0.028)


# -- sfumati: 'a sfumatura d''e guagliune ------------------------------------
# I lati rasati (il minimo che il gonfiaggio lascia) e sopra un blocco alto
# due centimetri e mezzo con **il gradino** netto dove finisce: è la linea
# della macchinetta. In mezzo una cresta, e davanti la frangetta a punte.
SFUMATI_CIMA = [(0, 49), (36, 51), (64, 55), (90, 57), (120, 53),
	(150, 47), (180, 44)]
## **'A sfumatura auta.** Sotto al gradino la fascia rasata non arriva
## all'attaccatura di tutti: si ferma sopra l'orecchio e a metà nuca, e
## sotto c'è la pelle — a zero. Alla prima prova la fascia scendeva fino
## alla nuca, era dello stesso colore del blocco, e da lontano il guaglione
## portava un casco come tutti.
ATTACCATURA_SFUMATI = [(0, 51), (18, 52), (36, 56), (52, 62), (64, 68),
	(74, 80), (82, 80), (90, 72), (98, 71), (108, 82), (120, 93),
	(138, 101), (158, 105), (180, 107)]


def _prof_sfumati(a, j):
	af, lato = _piega(a)
	te = _tab(ATTACCATURA_SFUMATI, af)
	w = 1.0 - _liscio((af - 28.0) / 30.0)       # 1 davanti, 0 ai lati
	# Davanti la frangetta corta a punte (il "french crop" dei guaglioni):
	# alla seconda prova il ciuffo era spinto in su e in avanti, e da
	# davanti sembrava la visiera di un berretto.
	punta = af < 44.0 and j % 2 == 0
	if af < 44.0:
		te += (4.0 if punta else -1.0) * (1.0 - af / 44.0)
	cresta = 0.0050 * (1.0 - _liscio(af / 30.0))
	T_su = 0.0240 + 0.003 * w + cresta
	T_lato = 0.0050
	tt = _tab(SFUMATI_CIMA, af) * (1.0 - w) + (te - 4.5) * w
	righe = [(0.5 * tt, T_su, None), (tt, T_su * (0.78 + 0.22 * w), None)]
	# Dopo il gradino: ai lati si scende rasati fino all'attaccatura, davanti
	# si resta alti fino alla fronte.
	t4 = (tt + 1.0) * (1.0 - w) + (te - 3.0) * w
	resto = [t4 + (te - t4) * k / 4.0 for k in (1, 2, 3)]
	righe.append((t4, (T_lato + 0.0006) * (1.0 - w) + T_su * w, None))
	for th in resto:
		righe.append((th, T_lato * (1.0 - w) + T_su * w, None))
	sp = Vector((0.0, -0.002, -0.001)) * w if punta else None
	righe.append((te, T_lato * (1.0 - w) + 0.011 * w, sp))
	return _con_rimbocco(righe, te)


def capelli_sfumati(g):
	_calotta(g, LATO_UOMO, _prof_sfumati, 0.0260)


# -- stempiati: pelato sopra, 'a curona attuorno -----------------------------
# Una fascia aperta davanti: dalla basetta di un lato, sopra le orecchie e
# dietro la nuca, alla basetta dell'altro. Le due colonne di punta sono
# tutte rimboccate, così la fascia finisce dentro la pelle.
STEMPIATI_CIMA = [(70, 72), (82, 68), (98, 64), (120, 61), (150, 57),
	(180, 55)]
LATO_STEMPIATI = [70, 76, 82, 90, 98, 108, 120, 138, 158, 180, 202, 222,
	240, 252, 262, 270, 278, 284, 290]


def _campana(x, a, b):
	if x <= a or x >= b:
		return 0.0
	m = (a + b) * 0.5
	return _liscio(1.0 - abs(x - m) / ((b - a) * 0.5))


def _prof_stempiati(a, j, ultimo):
	af, lato = _piega(a)
	te = _tab(ATTACCATURA_UOMO, af)
	ts = _tab(STEMPIATI_CIMA, af)
	T = 0.0082 + 0.0022 * _campana(af, 76.0, 118.0)
	if j == 0 or j == ultimo:
		T = RIMBOCCO[1]
	righe = [(ts - RIMBOCCO[0], RIMBOCCO[1], None)]
	for k in range(4):
		righe.append((ts + (te - ts) * k / 3.0, T, None))
	return righe + [(te + RIMBOCCO[0], RIMBOCCO[1], None)]


def capelli_stempiati(g):
	ult = len(LATO_STEMPIATI) - 1
	_capelli(g, [float(a) for a in LATO_STEMPIATI],
		lambda a, j: _prof_stempiati(a, j, ult), chiusa=False)


# -- signora: 'a messa 'n piega cotonata -------------------------------------
# **Nun è 'a capa cchiù 'nu spessore.** La prima messa in piega era la testa
# gonfiata di tre centimetri, ed era un casco; la seconda era più grossa ma
# con l'orlo dritto sopra le sopracciglia, ed era un fungo. La signora del
# terzo piano uscita dal parrucchiere ha **la fronte scoperta**, una nuvola
# di bigodini sopra (l'esterno lo dà un uovo suo, `SIGNORA_VOLUME`, più alto
# della testa di tre centimetri e mezzo e gonfio di dietro), la riga a
# sinistra e l'onda a destra, le ali ai lati che coprono le orecchie, e
# l'orlo che si gira in fuori. I bozzi sono grossi (sei millimetri): quelli
# da tre, a due metri, non si vedevano.
ATTACCATURA_SIGNORA = [(0, 53), (14, 54), (28, 57), (42, 64), (56, 80),
	(68, 96), (80, 104), (92, 107), (104, 109), (118, 111), (134, 114),
	(150, 116), (165, 117), (180, 117)]
LATO_SIGNORA = [0, 14, 28, 42, 56, 68, 80, 92, 104, 118, 134, 150, 165, 180]
SIGNORA_VOLUME = (C + Vector((0.0, 0.016, 0.034)), Vector((0.150, 0.150, 0.140)))


def _prof_signora(a, j):
	af, lato = _piega(a)
	te = _tab(ATTACCATURA_SIGNORA, af) + (2.0 if j % 2 == 0 else -1.0)
	righe = []
	for i, t in enumerate((0.18, 0.36, 0.52, 0.66, 0.78, 0.88, 0.95, 1.0)):
		th = t * te
		u = _dir(th, a)
		T = max(0.011, _volume(u, *SIGNORA_VOLUME) - _raggio(u))
		if lato < 0 and af < 50.0 and t > 0.55:
			T += 0.006 * (1.0 - af / 50.0)       # l'onda a destra
		if lato > 0 and abs(af - 28.0) < 0.5 and 0.3 < t < 0.97:
			T -= 0.007                          # la riga a sinistra
		elif 0.1 < t < 0.93:
			T += 0.0055 if (i + j) % 2 == 0 else -0.0020
		sp = None
		if t >= 0.999 and af > 55.0:
			# La piega: l'orlo si gira in fuori e un filo in su.
			h = Vector((u.x, u.y, 0.0)).normalized()
			sp = h * 0.009 + Vector((0.0, 0.0, 0.004))
		righe.append((th, T, sp))
	return _con_rimbocco(righe, te)


def capelli_signora(g):
	su = Vector((0.0, 0.0, 1.0))
	_calotta(g, LATO_SIGNORA, _prof_signora,
		_volume(su, *SIGNORA_VOLUME) - _raggio(su))


# -- tuppo: tirati 'ndreto c''a crocchia -------------------------------------
ATTACCATURA_NONNA = [(0, 50), (18, 51.5), (36, 55.5), (52, 62), (64, 71),
	(74, 84), (82, 86), (90, 72), (98, 71), (108, 88), (120, 110),
	(138, 122), (158, 126), (180, 127)]


def _prof_tuppo(a, j):
	af, lato = _piega(a)
	te = _tab(ATTACCATURA_NONNA, af)
	righe = []
	for t in (0.22, 0.44, 0.64, 0.80, 0.92, 1.0):
		th = t * te
		T = 0.0066 + 0.0016 * _liscio(1.0 - (th - 30.0) / 40.0)
		if af < 0.5 and t > 0.12:
			T = 0.0052                   # la riga in mezzo
		elif af < 120.0 and t > 0.2:
			T += 0.0020 if j % 2 == 0 else -0.0005
		if t >= 0.999:
			T = min(T, 0.0058)           # tirati: il bordo è sottile
		righe.append((th, T, None))
	return _con_rimbocco(righe, te)


def capelli_tuppo(g):
	_calotta(g, LATO_UOMO, _prof_tuppo, 0.0082)
	# 'A crocchia: dietro e in alto, grossa quanto un pugno piccolo — da
	# davanti ne spunta la cima sopra la testa, che è come si riconosce
	# una nonna a cinquanta metri.
	u = _dir(72.0, 180.0)
	cen = O + u * (_raggio(u) + 0.022)
	g.sfera(cen, Vector((0.037, 0.029, 0.033)), PH, "capelli", 8, 5)


# -- lunghi: fino alle spalle ------------------------------------------------
# Una calotta con la riga in mezzo, e sotto una **tenda** spessa nove
# millimetri che scende dai lati e da dietro. La tenda cade dritta dal
# punto più largo della testa (non segue la mascella in dentro, come i
# capelli veri) e finisce a quote diverse: più corta sopra le spalle (a
# 1,53, che la palla della spalla arriva a 1,52), più lunga davanti e
# dietro, a V sulla schiena. In basso pesa sul collo e sulla schiena,
# così quando la testa gira le punte non entrano nelle spalle.
#
# **E nun è 'na tendina.** Alla prima prova la tenda era un pannello
# liscio col taglio dritto: da dietro sembrava una tovaglia. Adesso le
# colonne escono e rientrano (le ciocche) e le punte sono scalate: una
# colonna sì e una no scende un centimetro di più (ma non sopra le spalle).
ATTACCATURA_LUNGHI = [(0, 51), (18, 53), (36, 58), (52, 66), (60, 76),
	(70, 90), (90, 93), (120, 96), (150, 99), (180, 100)]
LATO_LUNGHI = [0, 20, 40, 56, 68, 80, 92, 106, 124, 150, 180]
TENDA = [62, 80, 98, 116, 136, 158, 180, 202, 224, 244, 262, 280, 298]
TENDA_FONDO = [(62, -0.158), (90, -0.150), (104, -0.128), (125, -0.126),
	(145, -0.172), (180, -0.196)]
TENDA_SPESSORE = 0.009


def _T_lunghi(af, th):
	T = 0.0125 + 0.0105 * _liscio((th - 55.0) / 30.0)
	return T


def _prof_lunghi(a, j):
	af, lato = _piega(a)
	te = _tab(ATTACCATURA_LUNGHI, af)
	righe = []
	for t in (0.22, 0.44, 0.64, 0.80, 0.92, 1.0):
		th = t * te
		T = _T_lunghi(af, th)
		if af < 0.5 and t > 0.12:
			T = 0.0075                   # la riga in mezzo
		righe.append((th, T, None))
	# Davanti il bordo si rimbocca sotto la pelle; ai lati e dietro finisce
	# dentro allo spessore della tenda, che non si deve tagliare, se no il
	# rimbocco passerebbe dentro alle orecchie.
	return _con_rimbocco(righe, te,
		-0.003 + 0.019 * _liscio((af - 60.0) / 10.0))


def _pesi_tenda(p):
	z = p.z
	if z >= 1.62:
		return {"Head": 1.0}
	if z >= 1.565:
		k = (1.62 - z) / 0.055
		return {"Head": 1.0 - 0.3 * k, "neck_01": 0.3 * k}
	if z >= 1.52:
		k = (1.565 - z) / 0.045
		return {"Head": 0.7 - 0.25 * k, "neck_01": 0.3 + 0.25 * k}
	k = min(1.0, (1.52 - z) / 0.04)
	return {"Head": 0.45 - 0.2 * k, "neck_01": 0.55, "spine_03": 0.2 * k}


def _sopra_orecchie(a, z):
	"""Quanto deve stare larga la tenda, al giro `a` e alla quota `z`,
	per passare sopra alle orecchie (con mezzo centimetro d'aria)."""
	r = 0.0
	for sx in (1.0, -1.0):
		A, Q, fondo, D = orecchio(sx)
		for p in A + Q:
			d = Vector((p.x, p.y - O.y, 0.0))
			ap = math.degrees(math.atan2(d.x, -d.y)) % 360.0
			if abs((ap - a + 180.0) % 360.0 - 180.0) < 22.0 and abs(p.z - z) < 0.035:
				r = max(r, d.length + 0.005)
	return r


def capelli_lunghi(g):
	_calotta(g, LATO_LUNGHI, _prof_lunghi, 0.0135)
	# **'A tenda sta sotto â calotta.** Le due righe di sopra della tenda
	# stanno sotto la calotta e ci devono restare: alla prima prova la
	# ciocca le spingeva fuori di un millimetro, e da dietro si vedeva una
	# tacca scura dove la tenda bucava la calotta sopra l'orecchio.
	calotta = BVHTree.FromBMesh(g.bm)
	fuori, dentro_ = [], []
	for j, a in enumerate(TENDA):
		af, lato = _piega(a)
		zb = _tab(TENDA_FONDO, af)
		if not 95.0 < af < 135.0:
			zb += -0.016 if j % 2 == 0 else 0.004
		ciocca = 0.0050 if j % 2 == 0 else -0.0012
		# Le righe: una sotto la calotta, una appena sopra al suo bordo
		# (ancora coperta), una appena sotto, e tre fino alle punte. Così
		# la tenda esce da sotto la calotta proprio al bordo, e la riga
		# dove si incontrano è il bordo della calotta, pulito — non
		# l'incrocio a zig-zag di due superfici.
		ue = _dir(_tab(ATTACCATURA_LUNGHI, af), a)
		zc = (O + ue * _raggio(ue)).z - C.z
		quote = [0.050, zc + 0.006, zc - 0.012]
		quote += [quote[2] + (zb - quote[2]) * k / 3.0 for k in (1, 2, 3)]
		h = Vector((math.sin(math.radians(a)), -math.cos(math.radians(a)), 0.0))
		r_giu = 0.0
		cf, cd = [], []
		for i, z in enumerate(quote):
			asse = Vector((0.0, O.y, C.z + z))
			r = _raggio(h, asse)
			T = _T_lunghi(af, 90.0) - (0.004 if i == 0 else 0.0)
			if r is not None and r > 0.02:
				r_giu = max(r_giu * 0.985, r + T)
			else:
				r_giu += 0.003
			if i >= 2:
				r_giu = max(r_giu, _sopra_orecchie(a, asse.z))
				rf = r_giu + (ciocca if i >= 3 else 0.0)
			else:
				hit = calotta.ray_cast(asse, h)
				rf = r_giu if hit[0] is None else min(r_giu, hit[3] - 0.003)
			pf = asse + h * rf
			pd = asse + h * (r - 0.003 if i == 0 else rf - TENDA_SPESSORE)
			cf.append(g.vert(pf, _pesi_tenda(pf)))
			cd.append(g.vert(pd, _pesi_tenda(pd)))
		fuori.append(cf)
		dentro_.append(cd)

	def verso_fuori(q):
		c = sum((v.co for v in q), Vector()) / 4.0
		return c - Vector((0.0, O.y, c.z))
	_griglia(g, fuori, "capelli", chiusa=False, fuori=verso_fuori)
	_griglia(g, dentro_, "capelli", chiusa=False,
		fuori=lambda q: -verso_fuori(q))
	# L'orlo di sotto e i due bordi di fianco.
	for j in range(len(TENDA) - 1):
		_poli(g, [fuori[j][-1], fuori[j + 1][-1], dentro_[j + 1][-1],
			dentro_[j][-1]], "capelli", Vector((0.0, 0.0, -1.0)))
	for j, k in ((0, 1), (len(TENDA) - 1, len(TENDA) - 2)):
		via = fuori[j][2].co - fuori[k][2].co
		for i in range(len(fuori[j]) - 1):
			_poli(g, [fuori[j][i], fuori[j][i + 1], dentro_[j][i + 1],
				dentro_[j][i]], "capelli", via)


CAPELLI = {
	"corti": capelli_corti,
	"gellati": capelli_gellati,
	"ricci": capelli_ricci,
	"sfumati": capelli_sfumati,
	"stempiati": capelli_stempiati,
	"signora": capelli_signora,
	"tuppo": capelli_tuppo,
	"lunghi": capelli_lunghi,
}


# ---------------------------------------------------------------------------
# 'O cuntratto c''o regista
# ---------------------------------------------------------------------------

def pezzi():
	out = [("testa", testa)]
	for n in PALPEBRE:
		out.append(("palpebre_" + n, palpebre(n)))
	for n in SOPRACCIGLIA:
		out.append(("sopracciglia_" + n, sopracciglia(n)))
	for n in NASI:
		out.append(("naso_" + n, naso(n)))
	for n, fn in CAPELLI.items():
		out.append(("capelli_" + n, fn))
	out.append(("baffi", baffi))
	return out


# ---------------------------------------------------------------------------
# 'E cuntrolle (python3 tools/pupo_testa.py)
# ---------------------------------------------------------------------------

## I tetti di triangoli dell'incarico (0.66).
TETTI = {"testa": 550, "palpebre": 130, "sopracciglia": 40, "naso": 70,
	"capelli": 450, "baffi": 70}
TETTI_GROSSI = ("capelli_ricci", "capelli_signora", "capelli_lunghi")


def verifica():
	"""Costruisce ogni pezzo (senza scheletro vero) e misura: triangoli
	contro i tetti, le misure del contratto, quanto stanno lontani i capelli
	dalla pelle (la trappola delle chiazze), se un orecchio buca i capelli e
	se le palpebre chiuse lasciano scoperto un pezzo di bianco."""
	class _Osso:
		def __init__(self, n):
			self.name = n

	class _Arm:
		class data:
			bones = [_Osso(n) for n in ("Head", "neck_01", "spine_03")]

	ok = True
	vs = cranio()[0]
	print("cima %.4f (1,789) · larga %.4f (0,236) · fronte a 1,70: y %.4f "
		"(−0,132) · punta dell'occhio y %.4f (≥ −0,160)" % (
		max(v.z for v in vs), 2 * max(v.x for v in vs), _davanti(0.0, 1.70).y,
		centro_occhio(1.0).y - R_OCCHIO))
	orecchie = []
	for sx in (1.0, -1.0):
		A, Q, fondo, D = orecchio(sx)
		orecchie += A + Q
	for nome, fn in pezzi():
		g = B.Pupo(nome, _Arm())
		fn(g)
		g.bm.normal_update()
		tri = sum(len(f.verts) - 2 for f in g.bm.faces)
		tetto = 650 if nome in TETTI_GROSSI else TETTI[nome.split("_")[0]]
		nota = ""
		if nome.startswith("capelli"):
			rimb = {f.index for f in g.bm.faces
				if any(dentro(v.co, 0.0005) for v in f.verts)}
			tr = BVHTree.FromBMesh(g.bm)
			vicino = 1.0
			for i in range(0, 180, 2):
				for k in range(0, 360, 3):
					u = _dir(float(i), float(k))
					hit = tr.ray_cast(O, u)
					if hit[0] is not None and hit[2] not in rimb:
						vicino = min(vicino, hit[3] - _raggio(u))
			bucano = 0
			for p in orecchie:
				d = p - O
				o = O.copy()
				ultimo = None
				for _ in range(6):
					hit = tr.ray_cast(o, d.normalized())
					if hit[0] is None:
						break
					ultimo = hit
					o = hit[0] + d.normalized() * 0.0001
				if ultimo is not None and ultimo[2] not in rimb and \
						(ultimo[0] - O).length < d.length:
					bucano += 1
			nota = "pelle a ≥ %.1f mm · orecchie che bucano: %d" % (
				vicino * 1000.0, bucano)
			ok = ok and vicino > 0.003 and bucano == 0
		elif nome.startswith("palpebre"):
			for v, co in g.forme["chiudi"].items():
				v.co = co
			tr = BVHTree.FromBMesh(g.bm)
			scoperti = 0
			for sx in (1.0, -1.0):
				E = centro_occhio(sx)
				for i in range(0, 91, 3):
					for k in range(0, 360, 6):
						a, b = math.radians(i), math.radians(k)
						d = Vector((math.sin(a) * math.cos(b), -math.cos(a),
							math.sin(a) * math.sin(b)))
						if dentro(E + d * R_OCCHIO, 0.0003):
							continue
						if tr.ray_cast(E + d * (R_OCCHIO + 0.0002), d)[0] is None:
							scoperti += 1
			nota = "chiuse: bianco scoperto in %d direzioni" % scoperti
			ok = ok and scoperti == 0
		ok = ok and tri <= tetto
		print("  %-26s %4d tri (tetto %d)  %s" % (nome, tri, tetto, nota))
		g.bm.free()
		g.bm = None
	print("tutto a posto" if ok else "QUALCOSA NUN VA")
	return ok


if __name__ == "__main__":
	sys.exit(0 if verifica() else 1)
