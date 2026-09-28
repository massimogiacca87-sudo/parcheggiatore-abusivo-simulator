"""'O cuorpo d''o pupo (0.67): maglietta, cazune, braccia, mmane, scarpe — e
'e piezze napulitane da appiccià.

Il regista (`build_personaggi.py`) chiama:

* `corpo(g, corp)` — il corpo intero senza testa, una volta per corporatura;
* `extra()` — i pezzi che dipendono dalla corporatura: `colletto`,
  `cintura`, `catenina`;
* `pezzi()` — i pezzi unici: `gonna` (della femmina) e `banda_rossa`.

**Lo stile è quello di Schedule I**: corpi asciutti, arti lunghi, forme
lisce, niente muscoli, e *pochi dettagli veri* — l'orlo della maglietta, il
girocollo col bordino, la fascia dei pantaloni, la suola chiara, la
cintura con la fibbia. La stoffa (la trama) la mette la texture, non la
geometria.

**Pecché 'a maglietta mo è 'nu piezzo sulo.** Il corpo vecchio era fatto di
tubi che si infilavano l'uno nell'altro: il busto, e sopra due maniche e
due palle di stoffa per tappare il buco della spalla. In foto le palle
sembravano spalline imbottite, e quando il braccio scendeva la manica
girava *dentro* al busto e il bordo del buco si vedeva. Qui la maglietta è
una mesh sola: il busto ha **un buco per ogni braccio** (quattro facce
tolte di lato, otto vertici di bordo) e la manica *parte da quel bordo*.
Non c'è niente da tappare perché non c'è niente di aperto, e la spalla è
tonda perché i vertici del bordo sono pesati un po' sul petto e un po' sul
braccio: quando il braccio scende la stoffa si piega come una cucitura.

**E sotto nun ce sta niente.** Il busto di pelle e le gambe di pelle del
corpo vecchio non si vedevano mai, e costavano trecento triangoli; in
compenso erano la causa di tutte le "pelli che spuntano". Adesso sotto ai
vestiti non c'è carne: i vestiti sono chiusi (orli rientranti col tappo, il
girocollo che si infila nel collo, i pantaloni chiusi in vita dentro alla
maglietta). La regola vecchia resta, detta per le parti che si
sovrappongono davvero: **pantaloni < maglietta** alla vita, **braccio <
manica**, **caviglia < orlo dei pantaloni**, a ogni quota e per ogni
corporatura, **con la stessa funzione** (`_punto_tronco`).

**'E piezze 'ncopp'ê vestite se pesano cu 'e vestite.** Cintura, catenina,
colletto e banda rossa non hanno pesi scritti a mano: ogni vertice copia i
pesi della stoffa che ci sta sotto (il triangolo più vicino, in
coordinate baricentriche). Così si muovono *esattamente* come la maglietta
o i pantaloni su cui poggiano, in qualunque clip.

Coordinate di Blender: Z su, il pupo guarda verso −Y, +X è la **sua**
sinistra. Tutto il lato sinistro si scrive una volta e il destro è il suo
specchio (`Tela.v(..., lato="r")`).
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from mathutils import Vector                     # noqa: E402
from mathutils.bvhtree import BVHTree           # noqa: E402
import build_personaggi as R                    # noqa: E402

_liscio = R._liscio
_campana = R._campana


# ---------------------------------------------------------------------------
# 'E corporature
# ---------------------------------------------------------------------------
#
# Le chiavi del regista (`pancia`, `petto`, `spalle`, `fianchi`) passano per
# `R.fattore`, che allarga tutto l'anello a campana; le altre sono di questo
# modulo: `trippa`, `seno` e `sedere` spingono **solo davanti o solo
# dietro** (la pancia vera cresce in avanti, non dietro alla schiena),
# `braccia`/`gambe`/`collo` sono moltiplicatori dei raggi, `caviglia` stringe
# il polpaccio verso il basso, `piede` rimpicciolisce la scarpa.
CORPORATURE = {
	"normale": {},
	# 'O panzone: la trippa sta **sopra** alla cintura e ci ricade sopra.
	"panzone": {"pancia": 1.25, "petto": 1.12, "spalle": 1.05,
		"fianchi": 1.14, "braccia": 1.20, "gambe": 1.17, "collo": 1.22,
		"trippa": 0.105, "sedere": 0.012},
	# 'O sicco: stretto dappertutto, braccia e gambe a stecco.
	"magro": {"pancia": 0.84, "petto": 0.88, "spalle": 0.95,
		"fianchi": 0.90, "braccia": 0.80, "gambe": 0.84, "collo": 0.90},
	# 'A femmina: spalle strette, vita stretta, fianchi, un po' di seno,
	# caviglie sottili e il piede più piccolo.
	"femmina": {"pancia": 0.86, "petto": 0.90, "spalle": 0.86,
		"fianchi": 1.16, "braccia": 0.80, "gambe": 0.94, "collo": 0.86,
		"seno": 0.026, "sedere": 0.016, "caviglia": 0.74, "piede": 0.90},
}


def _trippa(z, corp):
	return corp.get("trippa", 0.0) * _campana(z, 1.00, 1.34)


def _seno(z, corp):
	return corp.get("seno", 0.0) * _campana(z, 1.20, 1.40)


def _sedere(z, corp):
	return corp.get("sedere", 0.0) * _campana(z, 0.80, 1.00)


# ---------------------------------------------------------------------------
# 'A tela: vertici, pesi e facce, prima di Blender
# ---------------------------------------------------------------------------

def _specchio_osso(n):
	if n.endswith("_l"):
		return n[:-2] + "_r"
	if n.endswith("_r"):
		return n[:-2] + "_l"
	return n


def _mix(*coppie):
	"""`_mix((pesi_a, 0.3), (pesi_b, 0.7))` → un dizionario di pesi."""
	out = {}
	for pesi, w in coppie:
		for k, v in pesi.items():
			out[k] = out.get(k, 0.0) + v * w
	return {k: v for k, v in out.items() if v > 1e-4}


class Tela:
	"""La mesh come dati: si costruisce qui, si controlla (strati, conti) e
	solo alla fine si versa nel `Pupo` del regista con `emetti`. Serve
	perché i pezzi di sopra (cintura, catenina…) devono poter *guardare*
	la stoffa del corpo senza che il corpo finisca nel loro oggetto."""

	def __init__(self):
		self.co = []
		self.pesi = []
		self.facce = []           # (indici, materiale, liscio)

	def v(self, co, pesi, lato="l"):
		co = Vector(co)
		if lato == "r":
			co = Vector((-co.x, co.y, co.z))
			pesi = {_specchio_osso(k): w for k, w in pesi.items()}
		self.co.append(co)
		self.pesi.append(dict(pesi))
		return len(self.co) - 1

	def f(self, idx, mat, lato="l", liscio=True):
		idx = list(idx)
		if lato == "r":
			idx.reverse()
		if len(set(idx)) < len(idx):
			return
		self.facce.append((tuple(idx), mat, liscio))

	def f_verso(self, idx, mat, verso, liscio=True):
		"""Una faccia girata dalla parte di `verso` (la normale attesa)."""
		p = [self.co[i] for i in idx]
		n = (p[1] - p[0]).cross(p[-1] - p[0])
		if n.dot(verso) < 0.0:
			idx = list(reversed(idx))
		self.f(idx, mat, "l", liscio)

	def cuci(self, a, b, mat, lato="l", chiuso=True, liscio=True):
		n = len(a)
		for j in range(n if chiuso else n - 1):
			k = (j + 1) % n
			self.f([a[j], a[k], b[k], b[j]], mat, lato, liscio)

	def tappo(self, anello, mat, verso=1, lato="l", liscio=False):
		vs = list(anello) if verso > 0 else list(reversed(anello))
		self.f(vs, mat, lato, liscio)

	def ventaglio(self, anello, polo, mat, verso=1, lato="l"):
		n = len(anello)
		for j in range(n):
			k = (j + 1) % n
			if verso > 0:
				self.f([anello[j], anello[k], polo], mat, lato)
			else:
				self.f([anello[k], anello[j], polo], mat, lato)

	def triangoli(self, mats=None):
		return sum(len(i) - 2 for i, m, _ in self.facce
			if mats is None or m in mats)

	def emetti(self, g):
		vs = [g.vert(c, p) for c, p in zip(self.co, self.pesi)]
		for idx, mat, liscio in self.facce:
			g.faccia([vs[i] for i in idx], mat, liscio)

	# -- guardare la stoffa ------------------------------------------------
	def albero(self, mats):
		"""Un BVH dei triangoli dei materiali `mats`, con la tabella per
		risalire dai triangoli ai vertici (per copiare i pesi)."""
		tri = []
		for idx, m, _ in self.facce:
			if m not in mats:
				continue
			for k in range(1, len(idx) - 1):
				tri.append((idx[0], idx[k], idx[k + 1]))
		return Stoffa(self, tri)


class Stoffa:
	"""La superficie di un vestito: dove sta, che normale ha, che pesi ha."""

	def __init__(self, tela, tri):
		self.tela = tela
		self.tri = tri
		self.bvh = BVHTree.FromPolygons([c.copy() for c in tela.co], tri)

	def _pesi_tri(self, i, p):
		a, b, c = (self.tela.co[k] for k in self.tri[i])
		v0, v1, v2 = b - a, c - a, p - a
		d00, d01, d11 = v0.dot(v0), v0.dot(v1), v1.dot(v1)
		d20, d21 = v2.dot(v0), v2.dot(v1)
		den = d00 * d11 - d01 * d01
		if abs(den) < 1e-14:
			u = v = 1.0 / 3.0
		else:
			v = (d11 * d20 - d01 * d21) / den
			u = (d00 * d21 - d01 * d20) / den
		w0 = max(0.0, 1.0 - u - v)
		v = max(0.0, v)
		u = max(0.0, u)
		s = w0 + u + v
		ia, ib, ic = self.tri[i]
		return _mix((self.tela.pesi[ia], w0 / s), (self.tela.pesi[ib], v / s),
			(self.tela.pesi[ic], u / s))

	def vicino(self, p):
		"""(punto, normale, pesi) della stoffa più vicina a `p`."""
		loc, nor, i, _ = self.bvh.find_nearest(Vector(p))
		return loc, nor, self._pesi_tri(i, loc)

	def raggio(self, da, verso):
		"""(punto, normale, pesi) del primo colpo lungo un raggio, o None."""
		loc, nor, i, _ = self.bvh.ray_cast(Vector(da), Vector(verso).normalized())
		if loc is None:
			return None
		return loc, nor, self._pesi_tri(i, loc)

	def pesi(self, p):
		return self.vicino(p)[2]


# ---------------------------------------------------------------------------
# 'E pesi d''o tronco
# ---------------------------------------------------------------------------
#
# **Una funzione sola per maglietta, pantaloni, cintura e gonna.** Col corpo
# vecchio la camicia a quota 1,04 era pesata a gradini (86% bacino) e i
# pantaloni alla stessa quota in un altro modo (45% bacino): quando il
# pupo si piegava, l'orlo della maglietta e la vita dei pantaloni si
# spostavano l'uno rispetto all'altra. Qui i pesi sono una funzione
# continua della posizione, e due vestiti che si toccano si muovono
# insieme per costruzione.
_TRONCO = [
	(0.860, {"pelvis": 1.0}),
	(0.950, {"pelvis": 0.92, "spine_01": 0.08}),
	(1.020, {"pelvis": 0.64, "spine_01": 0.36}),
	(1.080, {"pelvis": 0.32, "spine_01": 0.60, "spine_02": 0.08}),
	(1.150, {"pelvis": 0.08, "spine_01": 0.52, "spine_02": 0.40}),
	(1.230, {"spine_01": 0.14, "spine_02": 0.72, "spine_03": 0.14}),
	(1.310, {"spine_02": 0.40, "spine_03": 0.60}),
	(1.380, {"spine_02": 0.08, "spine_03": 0.92}),
	(1.440, {"spine_03": 1.0}),
	(1.490, {"spine_03": 0.82, "neck_01": 0.18}),
	(1.520, {"spine_03": 0.50, "neck_01": 0.50}),
	(1.560, {"neck_01": 0.45, "Head": 0.55}),
]


def _pesi_z(z):
	tav = _TRONCO
	if z <= tav[0][0]:
		return dict(tav[0][1])
	for (z0, p0), (z1, p1) in zip(tav, tav[1:]):
		if z <= z1:
			t = (z - z0) / (z1 - z0)
			return _mix((p0, 1.0 - t), (p1, t))
	return dict(tav[-1][1])


def pesi_tronco(p):
	w = _pesi_z(p.z)
	ax = abs(p.x)
	lato = "l" if p.x >= 0.0 else "r"
	altro = "r" if lato == "l" else "l"
	# Sopra al petto, di lato, la stoffa segue un po' la clavicola: quando
	# il pupo alza le spalle la maglietta sale con lui.
	k = _liscio((ax - 0.05) / 0.10) * _liscio((p.z - 1.34) / 0.10) * 0.45
	if k > 0.0:
		w = _mix((w, 1.0 - k), ({"clavicle_" + lato: 1.0}, k))
	# Sotto all'anca la stoffa passa alle cosce. Al centro (il cavallo) metà
	# e metà, di lato tutta alla coscia del suo lato.
	t = _liscio((0.975 - p.z) / 0.135)
	if t > 0.0:
		s = _liscio(ax / 0.07)
		m = 0.5 + 0.5 * s
		cosce = {"thigh_" + lato: 0.5 + 0.5 * s, "thigh_" + altro: 0.5 - 0.5 * s}
		w = _mix((w, 1.0 - t * m), (cosce, t * m))
	return w


# ---------------------------------------------------------------------------
# 'A sezione d''o tronco
# ---------------------------------------------------------------------------
#
# Un anello del tronco è una **superellisse** (un po' squadrata, come un
# busto vestito e non come un tubo), con la profondità davanti diversa da
# quella di dietro. La colonna 0 è il centro davanti (−Y), e si gira verso
# +X: antiorario visto dall'alto, così `cuci(sotto, sopra)` dà le facce
# verso fuori.
ESP = 2.2


def _curva(t):
	return math.copysign(abs(t) ** (2.0 / ESP), t)


def _punto_tronco(th, z, rx, df, db, yc, corp):
	s, c = math.sin(th), math.cos(th)
	f = R.fattore(z, corp)
	x = rx * f * _curva(s)
	if c >= 0.0:
		dav = df * f + _trippa(z, corp) * c ** 1.3 + _seno(z, corp) * c ** 0.6
		y = yc - dav * _curva(c)
	else:
		die = db * f + _sedere(z, corp) * (-c)
		y = yc - die * _curva(c)
	return Vector((x, y, z))


def _anello_tronco(n, z, rx, df, db, yc, corp):
	return [_punto_tronco(2.0 * math.pi * j / n, z, rx, df, db, yc, corp)
		for j in range(n)]


def _dentro(punti, k, dz, centro_y=0.010):
	"""Un anello rimpicciolito verso l'asse (per gli orli che rientrano)."""
	return [Vector((p.x * k, centro_y + (p.y - centro_y) * k, p.z + dz))
		for p in punti]


# ---------------------------------------------------------------------------
# 'A maglietta
# ---------------------------------------------------------------------------
#
#   z      mezza larghezza · davanti · dietro · centro y
MAGLIA = [
	(1.043, 0.152, 0.103, 0.106, 0.010),   # H: l'orlo
	(1.100, 0.148, 0.102, 0.102, 0.010),   # R1: la vita
	(1.200, 0.153, 0.108, 0.103, 0.010),   # R2
	(1.290, 0.160, 0.114, 0.107, 0.012),   # R3: il petto
	(1.362, 0.161, 0.110, 0.111, 0.015),   # R4: le ascelle
	(1.425, 0.152, 0.094, 0.113, 0.018),   # R5: le spalle
	(1.468, 0.128, 0.074, 0.101, 0.020),   # R6: sopra al petto
]
N_MAGLIA = 14
BUCO = (3, 4, 5)          # le colonne del buco della manica sinistra
Y_OSSO_BRACCIO = 0.0654
Z_OSSO_BRACCIO = 1.4408


def _collo_r(corp):
	"""Raggio del collo (x, y) alla base."""
	k = corp.get("collo", 1.0)
	return 0.053 * k, 0.051 * k


def _buco(corp):
	"""Gli otto vertici del bordo del buco della manica sinistra, per
	(riga, colonna). Il buco è un anello attorno all'asse del braccio, che
	sta **dietro** al centro del busto (y = 0,065): il manichino ha le
	spalle indietro, ed è per questo che il busto a ellisse del corpo
	vecchio non arrivava a coprirle."""
	fs = corp.get("spalle", 1.0)
	kb = corp.get("braccia", 1.0)
	xj = 0.150 * (1.0 + (fs - 1.0) * 0.8)
	ya, za = 0.058, 1.420
	r = 0.062 * (1.0 + (kb - 1.0) * 0.6)
	k = 0.72
	return {
		(4, 3): Vector((xj, ya - k * r, za - k * r)),
		(4, 4): Vector((xj - 0.006, ya, za - r)),
		(4, 5): Vector((xj, ya + k * r, za - k * r)),
		(5, 3): Vector((xj, ya - r, za)),
		(5, 5): Vector((xj, ya + r, za)),
		(6, 3): Vector((xj, ya - k * r, za + k * r)),
		(6, 4): Vector((xj + 0.004, ya, za + r)),
		(6, 5): Vector((xj, ya + k * r, za + k * r)),
	}


## I pesi del bordo del buco: un po' petto, un po' clavicola, un po'
## braccio. Più braccio in cima (la spalla si arrotonda quando il braccio
## scende) e meno sotto (l'ascella resta attaccata al busto).
PESI_BUCO = {
	(4, 3): {"spine_03": 0.58, "clavicle_l": 0.12, "upperarm_l": 0.30},
	(4, 4): {"spine_03": 0.62, "clavicle_l": 0.06, "upperarm_l": 0.32},
	(4, 5): {"spine_03": 0.58, "clavicle_l": 0.12, "upperarm_l": 0.30},
	(5, 3): {"spine_03": 0.40, "clavicle_l": 0.30, "upperarm_l": 0.30},
	(5, 5): {"spine_03": 0.40, "clavicle_l": 0.30, "upperarm_l": 0.30},
	(6, 3): {"spine_03": 0.30, "clavicle_l": 0.42, "upperarm_l": 0.28},
	(6, 4): {"spine_03": 0.26, "clavicle_l": 0.44, "upperarm_l": 0.30},
	(6, 5): {"spine_03": 0.30, "clavicle_l": 0.42, "upperarm_l": 0.28},
}


def _scollo(corp):
	"""Il giro del girocollo (14 punti): più basso davanti, più alto dietro."""
	kc = corp.get("collo", 1.0)
	s = 1.0 + (kc - 1.0) * 0.7
	rx, df, db, yc = 0.074 * s, 0.066 * s, 0.060 * s, 0.008
	out = []
	for j in range(N_MAGLIA):
		th = 2.0 * math.pi * j / N_MAGLIA
		sn, c = math.sin(th), math.cos(th)
		y = yc - (df if c >= 0.0 else db) * c
		z = 1.502 - 0.021 * max(0.0, c) ** 2 + 0.008 * max(0.0, -c)
		out.append(Vector((rx * sn, y, z)))
	return out


def maglietta(t, corp):
	"""Il busto della maglietta con i due buchi, le maniche, l'orlo e il
	girocollo. Ritorna le righe (per chi deve sapere dove sta l'orlo)."""
	n = N_MAGLIA
	buco = _buco(corp)
	righe = []
	for r, (z, rx, df, db, yc) in enumerate(MAGLIA):
		riga = []
		for j in range(n):
			jl = j if j <= n // 2 else n - j          # la colonna sinistra gemella
			sx = 1.0 if j <= n // 2 else -1.0
			if r in (4, 5, 6) and jl in BUCO:
				if (r, jl) not in buco:
					riga.append(None)                   # il centro del buco
					continue
				p = buco[(r, jl)]
				p = Vector((sx * p.x, p.y, p.z))
				pesi = PESI_BUCO[(r, jl)]
				if sx < 0.0:
					pesi = {_specchio_osso(k): w for k, w in pesi.items()}
				riga.append(t.v(p, pesi))
				continue
			p = _punto_tronco(2.0 * math.pi * j / n, z, rx, df, db, yc, corp)
			riga.append(t.v(p, pesi_tronco(p)))
		righe.append(riga)
	# Il girocollo: il giro dello scollo, il bordino che sale di un
	# centimetro, e poi la stoffa che rientra e si infila nel collo.
	sc = _scollo(corp)
	cx, cy = _collo_r(corp)
	r7 = [t.v(p, pesi_tronco(p)) for p in sc]
	r8, r9 = [], []
	for p in sc:
		d = Vector((p.x, p.y - 0.006, 0.0))
		d.normalize()
		q = Vector((p.x, p.y, p.z)) + d * 0.003 + Vector((0, 0, 0.010))
		r8.append(t.v(q, pesi_tronco(q)))
		q2 = Vector((d.x * cx * 0.98, 0.004 + d.y * cy * 0.98, p.z + 0.006))
		r9.append(t.v(q2, _mix((pesi_tronco(q2), 0.6),
			({"neck_01": 1.0}, 0.4))))
	righe += [r7, r8, r9]
	for a, b in zip(righe, righe[1:]):
		for j in range(n):
			k = (j + 1) % n
			q = [a[j], a[k], b[k], b[j]]
			if None in q:
				continue
			t.f(q, "camicia")
	# L'imbuto: il girocollo si chiude dentro al collo. Se la testa gira e
	# fra collo e bordino si apre uno spiraglio, dentro c'è stoffa, non il
	# vuoto.
	pc = Vector((0.0, 0.004, 1.470))
	fondo = t.v(pc, pesi_tronco(pc))
	t.ventaglio(r9, fondo, "camicia")
	# L'orlo di sotto: la stoffa gira in dentro di un centimetro e si chiude.
	h = [t.co[i] for i in righe[0]]
	hi = [t.v(p, pesi_tronco(p)) for p in _dentro(h, 0.93, 0.008)]
	t.cuci(hi, righe[0], "camicia")
	t.tappo(hi, "camicia", -1)
	# Le maniche.
	for lato, sx in (("l", 1.0), ("r", -1.0)):
		cols = BUCO if sx > 0 else tuple(n - c for c in BUCO)
		a, b, c = cols            # davanti, in mezzo, dietro (a sinistra)
		bordo = [righe[5][c], righe[6][c], righe[6][b], righe[6][a],
			righe[5][a], righe[4][a], righe[4][b], righe[4][c]]
		manica(t, corp, lato, bordo)
	return righe


## Le maniche: (x, raggio y, raggio z, centro y, pesi)
MANICA = [
	(0.188, 0.060, 0.060, 0.061,
		{"upperarm_l": 0.64, "clavicle_l": 0.25, "spine_03": 0.11}),
	(0.235, 0.057, 0.056, 0.064,
		{"upperarm_l": 0.86, "clavicle_l": 0.10, "spine_03": 0.04}),
	(0.290, 0.0555, 0.054, 0.0665, {"upperarm_l": 1.0}),
	(0.335, 0.0545, 0.053, 0.067, {"upperarm_l": 1.0}),
]


def _anello_x(x, yc, zc, ry, rz, seg=8, fase=0.0):
	"""Anello attorno a un asse lungo +X, nell'ordine del regista: +Y, +Z,
	−Y, −Z (antiorario guardando da +X)."""
	out = []
	for j in range(seg):
		a = fase + 2.0 * math.pi * j / seg
		out.append(Vector((x, yc + ry * math.cos(a), zc + rz * math.sin(a))))
	return out


def manica(t, corp, lato, bordo):
	kb = 1.0 + (corp.get("braccia", 1.0) - 1.0) * 0.8
	prec = bordo
	for i, (x, ry, rz, yc, pesi) in enumerate(MANICA):
		# Il primo anello sta mezzo centimetro più su: col braccio giù si
		# schiaccia (la pelle a pesi lineari accorcia le corde) e torna tondo.
		dz = 0.004 if i == 0 else 0.0
		cur = [t.v(p, pesi, lato)
			for p in _anello_x(x, yc, Z_OSSO_BRACCIO + dz, ry * kb, rz * kb)]
		t.cuci(prec, cur, "camicia", lato)
		prec = cur
	# L'orlo: gira in dentro e torna indietro di mezzo centimetro.
	x, ry, rz, yc, pesi = MANICA[-1]
	dentro = [t.v(p, pesi, lato) for p in
		_anello_x(x - 0.006, yc, Z_OSSO_BRACCIO, ry * kb * 0.92, rz * kb * 0.92)]
	t.cuci(prec, dentro, "camicia", lato)
	t.tappo(dentro, "camicia", 1, lato)


# ---------------------------------------------------------------------------
# 'E braccia e 'e mmane
# ---------------------------------------------------------------------------

## x, raggio y, raggio z, pesi. Il braccio parte **dentro alla manica** e
## arriva al polso, dove continua nella mano senza tappi in mezzo.
BRACCIO = [
	(0.262, 0.047, 0.046, {"upperarm_l": 1.0}),
	(0.400, 0.043, 0.042, {"upperarm_l": 1.0}),
	(0.445, 0.040, 0.039, {"upperarm_l": 0.70, "lowerarm_l": 0.30}),
	(0.490, 0.040, 0.037, {"upperarm_l": 0.30, "lowerarm_l": 0.70}),
	(0.600, 0.037, 0.032, {"lowerarm_l": 1.0}),
	(0.735, 0.029, 0.020, {"lowerarm_l": 0.45, "hand_l": 0.55}),
]


def _y_braccio(x):
	if x <= 0.4663:
		return 0.0654 + (0.0701 - 0.0654) * (x - 0.1919) / (0.4663 - 0.1919)
	return 0.0701 + (0.0654 - 0.0701) * (x - 0.4663) / (0.7389 - 0.4663)


def braccio(t, corp, lato, ossa):
	k = corp.get("braccia", 1.0)
	anelli = []
	for i, (x, ry, rz, pesi) in enumerate(BRACCIO):
		kk = k if i < len(BRACCIO) - 1 else 1.0 + (k - 1.0) * 0.5
		anelli.append([t.v(p, pesi, lato) for p in
			_anello_x(x, _y_braccio(x), Z_OSSO_BRACCIO, ry * kk, rz * kk)])
	for a, b in zip(anelli, anelli[1:]):
		t.cuci(a, b, "pelle", lato)
	t.tappo(anelli[0], "pelle", -1, lato)
	mano(t, corp, lato, anelli[-1], ossa)


def _cuci_diversi(t, a, b, centro, mat, lato):
	"""Cuce due anelli con un numero diverso di vertici attorno a un asse
	lungo +X (serve fra il polso a otto e le nocche a dieci)."""
	def ang(i):
		p = t.co[i]
		if lato == "r":
			p = Vector((-p.x, p.y, p.z))
		return math.atan2(p.z - centro.z, p.y - centro.y) % (2.0 * math.pi)
	aa = sorted(a, key=ang)
	bb = sorted(b, key=ang)
	i = j = 0
	na, nb = len(aa), len(bb)
	while i < na or j < nb:
		a0, a1 = aa[i % na], aa[(i + 1) % na]
		b0, b1 = bb[j % nb], bb[(j + 1) % nb]
		ta = ang(a1) + (2.0 * math.pi if i + 1 >= na else 0.0)
		tb = ang(b1) + (2.0 * math.pi if j + 1 >= nb else 0.0)
		if j >= nb or (i < na and ta <= tb):
			t.f([a0, a1, b0], mat, lato)
			i += 1
		else:
			t.f([a0, b1, b0], mat, lato)
			j += 1


## Le dita: (osso, centro y, larghezza/2, spessore/2, quanto va oltre la
## terza falange). **Non stanno sulle ossa del manichino**, che ha le dita
## aperte a ventaglio (tre centimetri fra indice e medio): stanno
## accostate, un millimetro o due l'una dall'altra, e ruotano lo stesso
## attorno alle ossa giuste (l'asse della piega corre lungo y, quindi
## spostarle di lato non cambia niente).
DITA = [("index", 0.0415, 0.0100, 0.0112, 0.004),
	("middle", 0.0625, 0.0100, 0.0116, 0.004),
	("ring", 0.0825, 0.0095, 0.0112, 0.002),
	("pinky", 0.1010, 0.0085, 0.0100, -0.004)]
## Dove si dividono le dita sulle nocche (y), e quanto sono avanti le
## nocche (x): il mignolo parte più indietro.
NOCCHE_Y = [0.0305, 0.0520, 0.0725, 0.0918, 0.1100]
NOCCHE_X = [0.855, 0.857, 0.856, 0.851, 0.843]


def mano(t, corp, lato, polso, ossa):
	"""**'A mano: 'nu guanto cu 'e ddete.** Un palmo solo dal polso alle
	nocche, quattro dita grosse e accostate che partono insieme dalle nocche
	e si staccano appena (un millimetro alla radice, tre in punta), e il
	pollice per conto suo. Ogni dito ha un anello alla seconda falange e
	uno in punta, pesati sulle ossa delle dita, e la punta tonda: nelle clip
	col pugno chiuso la mano si chiude davvero. Centodiciotto triangoli.

	**'E ddete 'e ll'artiglio.** Alla prima prova le dita stavano sulle
	ossa del manichino: larghe due centimetri, distanti tre, lunghe dieci.
	Nella posa di riposo (che le tiene piegate) sembravano gli artigli di
	un rapace."""
	zc = Z_OSSO_BRACCIO
	su, giu = zc + 0.0130, zc - 0.0145
	nomi = [d[0] for d in DITA]
	top, bot = [], []
	for k, (y, x) in enumerate(zip(NOCCHE_Y, NOCCHE_X)):
		vicini = []
		if k > 0:
			vicini.append(nomi[k - 1])
		if k < 4:
			vicini.append(nomi[k])
		pesi = {"hand_l": 0.5}
		for nm in vicini:
			pesi[nm + "_01_l"] = 0.5 / len(vicini)
		alto = su + (0.0025 if k in (1, 2, 3) else 0.0)
		top.append(t.v((x, y, alto), pesi, lato))
		bot.append(t.v((x - 0.005, y, giu), pesi, lato))
	nocche = list(reversed(top)) + bot       # +Y in alto → −Y → palmo → +Y
	_cuci_diversi(t, polso, nocche, Vector((0.8, 0.069, zc)), "pelle", lato)
	for k, (nome, yk, w, h, oltre) in enumerate(DITA):
		o2 = ossa[nome + "_02_l"]
		o3 = ossa[nome + "_03_l"]
		base = [top[k + 1], top[k], bot[k], bot[k + 1]]
		zk = o2.z
		p12 = {nome + "_01_l": 0.5, nome + "_02_l": 0.5}
		mezzo = [t.v(p, p12, lato) for p in (
			(o2.x, yk + w, zk + h), (o2.x, yk - w, zk + h),
			(o2.x - 0.003, yk - w, zk - h), (o2.x - 0.003, yk + w, zk - h))]
		xp = o3.x + oltre
		w2, h2 = w * 0.92, h * 0.86
		zp = o3.z - 0.002
		p3 = {nome + "_03_l": 0.7, nome + "_02_l": 0.3}
		punta = [t.v(p, p3, lato) for p in (
			(xp, yk + w2, zp + h2), (xp, yk - w2, zp + h2),
			(xp - 0.004, yk - w2, zp - h2), (xp - 0.004, yk + w2, zp - h2))]
		t.cuci(base, mezzo, "pelle", lato)
		t.cuci(mezzo, punta, "pelle", lato)
		apice = t.v((xp + 0.0055, yk, zp - 0.002), {nome + "_03_l": 1.0}, lato)
		t.ventaglio(punta, apice, "pelle", 1, lato)
	# 'O pollice: parte da dentro al palmo, dal lato davanti e di sotto
	# (la base sta dentro al palmo, niente tappo).
	p1 = Vector((0.774, 0.042, 1.425))
	p2, p3 = ossa["thumb_02_l"], ossa["thumb_03_l"]
	d = (p3 - p2).normalized()
	p4 = p3 + d * 0.004
	nodi = [(p1, 0.0178, {"hand_l": 0.6, "thumb_01_l": 0.4}),
		(p2, 0.0152, {"thumb_01_l": 0.5, "thumb_02_l": 0.5}),
		(p4, 0.0128, {"thumb_03_l": 0.7, "thumb_02_l": 0.3})]
	anelli = []
	for i, (p, r, pesi) in enumerate(nodi):
		if i == 0:
			dd = nodi[1][0] - p
		elif i == len(nodi) - 1:
			dd = p - nodi[i - 1][0]
		else:
			dd = nodi[i + 1][0] - nodi[i - 1][0]
		anelli.append([t.v(q, pesi, lato) for q in _anello_dir(p, dd, r, r * 0.88, 4,
			math.pi / 4.0)])
	for a, b in zip(anelli, anelli[1:]):
		t.cuci(a, b, "pelle", lato)
	apice = t.v(p4 + d * 0.0075, {"thumb_03_l": 1.0}, lato)
	t.ventaglio(anelli[-1], apice, "pelle", 1, lato)


def _telaio(d):
	d = d.normalized()
	rif = Vector((0.0, 1.0, 0.0)) if abs(d.z) > 0.9 else Vector((0.0, 0.0, 1.0))
	lato = rif.cross(d)
	if lato.length < 1e-5:
		lato = Vector((1.0, 0.0, 0.0))
	lato.normalize()
	return lato, d.cross(lato)


def _anello_dir(p, d, ra, rb, seg, fase=0.0):
	"""Come `Pupo.anello` del regista (stesso verso), ma solo le posizioni."""
	lato, su = _telaio(d)
	return [p + lato * (ra * math.cos(fase + 2.0 * math.pi * j / seg))
		+ su * (rb * math.sin(fase + 2.0 * math.pi * j / seg)) for j in range(seg)]


# ---------------------------------------------------------------------------
# 'O cuollo
# ---------------------------------------------------------------------------

def collo(t, corp):
	"""Dal petto (dentro alla maglietta) fino a dentro alla testa."""
	cx, cy = _collo_r(corp)
	nodi = [(1.425, 0.006, 0.95, {"spine_03": 0.75, "neck_01": 0.25}),
		(1.500, 0.004, 1.00, {"spine_03": 0.30, "neck_01": 0.70}),
		(1.560, -0.004, 0.93, {"neck_01": 0.35, "Head": 0.65})]
	anelli = []
	for z, yc, k, pesi in nodi:
		anelli.append([t.v((cx * k * math.cos(2 * math.pi * j / 8),
			yc + cy * k * math.sin(2 * math.pi * j / 8), z), pesi) for j in range(8)])
	for a, b in zip(anelli, anelli[1:]):
		t.cuci(a, b, "pelle")
	t.tappo(anelli[0], "pelle", -1)
	t.tappo(anelli[-1], "pelle", 1)


# ---------------------------------------------------------------------------
# 'E cazune
# ---------------------------------------------------------------------------

N_CAZUNE = 16
#   z      mezza larghezza · davanti · dietro · centro y
CAZUNE = [
	(1.050, 0.142, 0.094, 0.097, 0.010),   # W1: la fascia, sopra
	(1.002, 0.146, 0.096, 0.100, 0.010),   # W2: la fascia, sotto
	(0.930, 0.163, 0.100, 0.118, 0.012),   # W4: i fianchi
	(0.845, 0.166, 0.092, 0.112, 0.010),   # W5: il cavallo
]
## La gamba: z, raggio, pesi (sulla coscia/polpaccio del lato).
GAMBA = [
	(0.745, 0.083, {"thigh_l": 1.0}),
	(0.625, 0.074, {"thigh_l": 1.0}),
	(0.555, 0.068, {"thigh_l": 0.72, "calf_l": 0.28}),
	(0.505, 0.066, {"thigh_l": 0.28, "calf_l": 0.72}),
	(0.400, 0.065, {"calf_l": 1.0}),
	(0.250, 0.061, {"calf_l": 1.0}),
]
ORLO_GAMBA = (0.063, {"calf_l": 0.85, "foot_l": 0.15})
X_GAMBA = 0.0890


def _y_gamba(z):
	if z >= 0.5318:
		return -0.0014 + 0.0028 * (0.9321 - z) / (0.9321 - 0.5318)
	return 0.0014 + (0.0358 - 0.0014) * (0.5318 - z) / (0.5318 - 0.1037)


def _r_gamba(z, r, corp):
	k = corp.get("gambe", 1.0)
	cav = corp.get("caviglia", 1.0)
	t = _liscio((0.52 - z) / 0.40)
	return r * k * (1.0 + (cav - 1.0) * t)


def _fianchi(corp):
	"""Le righe del bacino (16 punti l'una), dalla fascia al cavallo."""
	righe = []
	for z, rx, df, db, yc in CAZUNE:
		righe.append(_anello_tronco(N_CAZUNE, z, rx, df, db, yc, corp))
		if z == 1.002:
			# La cucitura sotto alla fascia: mezzo centimetro più stretta.
			righe.append(_anello_tronco(N_CAZUNE, 0.997, rx - 0.0035,
				df - 0.0035, db - 0.0035, yc, corp))
	return righe


def pantaloni(t, corp):
	"""**'E cazune, 'nu piezzo sulo.** La fascia in vita (che si legge
	perché sotto c'è la cucitura, mezzo centimetro più stretta), i fianchi,
	e al cavallo l'anello si **spacca** nelle due gambe: ogni gamba prende
	metà anello (nove vertici, dal centro davanti al centro dietro) più un
	vertice in mezzo alle cosce. Niente pannolino e niente tubi infilati:
	la stoffa è continua, e a gambe larghe non si apre niente.

	In fondo cuce le due tasche di dietro. Ritorna gli anelli delle due
	gambe."""
	n = N_CAZUNE
	righe = []
	for pts in _fianchi(corp):
		righe.append([t.v(p, pesi_tronco(p)) for p in pts])
	for a, b in zip(righe[1:], righe):
		t.cuci(a, b, "pantaloni")
	# Sopra, la stoffa gira in dentro e si chiude (sta sotto alla maglietta).
	w1 = [t.co[i] for i in righe[0]]
	w0 = [t.v(p, pesi_tronco(p)) for p in _dentro(w1, 0.90, 0.004)]
	t.cuci(righe[0], w0, "pantaloni")
	t.tappo(w0, "pantaloni", 1)
	cav = righe[-1]
	pc = Vector((0.0, 0.006, 0.822))
	c = t.v(pc, {"pelvis": 0.5, "thigh_l": 0.25, "thigh_r": 0.25})
	sin = [cav[j] for j in range(0, n // 2 + 1)] + [c]
	# La destra si scrive come la sinistra specchiata: stesso ordine di
	# colonne (le gemelle), e `lato="r"` gira le facce.
	des = [cav[(n - j) % n] for j in range(0, n // 2 + 1)] + [c]
	gambe = gamba(t, corp, "l", sin), gamba(t, corp, "r", des)
	tasche(t)
	return gambe


## La tasca di dietro dei jeans: (x, z) del contorno, a cinque lati.
TASCA = [(0.024, 0.978), (0.077, 0.980), (0.130, 0.978), (0.126, 0.884),
	(0.077, 0.866), (0.028, 0.884)]


def tasche(t):
	"""**'E sacche 'e reto.** Due tasche a cinque lati sul sedere, cucite
	sopra la stoffa (tre millimetri e mezzo di spessore): da dietro sono il
	dettaglio che fa "jeans" in Schedule I, e la trama da sola non le può
	fare perché si ripete. Ogni vertice sta sulla stoffa vera (un raggio
	da dietro) e ne copia i pesi. Trentadue triangoli tutte e due."""
	stoffa = t.albero({"pantaloni"})
	for sx in (1.0, -1.0):
		fuori, dentro = [], []
		for x, z in TASCA:
			colpo = stoffa.raggio((sx * x, 0.5, z), (0.0, -1.0, 0.0))
			loc, nor, pesi = colpo
			fuori.append(t.v(loc + nor * 0.0035, pesi))
			dentro.append(t.v(loc - nor * 0.0010, pesi))
		dietro = Vector((0.0, 1.0, 0.0))
		# davanti alla tasca (verso +Y): due quadrilateri
		t.f_verso([fuori[0], fuori[1], fuori[4], fuori[5]], "pantaloni", dietro,
			liscio=False)
		t.f_verso([fuori[1], fuori[2], fuori[3], fuori[4]], "pantaloni", dietro,
			liscio=False)
		# i bordi, girati verso fuori dal contorno
		cen = sum((t.co[i] for i in fuori), Vector()) / len(fuori)
		m = len(fuori)
		for j in range(m):
			k = (j + 1) % m
			mezzo = (t.co[fuori[j]] + t.co[fuori[k]]) * 0.5
			t.f_verso([fuori[j], fuori[k], dentro[k], dentro[j]], "pantaloni",
				mezzo - cen, liscio=False)


def gamba(t, corp, lato, cavallo):
	"""Una gamba dei pantaloni, dal cavallo all'orlo sopra la scarpa."""
	cx = X_GAMBA
	p0 = [t.co[i] for i in cavallo]
	if lato == "r":
		p0 = [Vector((-p.x, p.y, p.z)) for p in p0]
	yc0 = _y_gamba(0.80)
	ang = [math.atan2(p.x - cx, -(p.y - yc0)) for p in p0]
	for i in range(1, len(ang)):
		while ang[i] < ang[i - 1]:
			ang[i] += 2.0 * math.pi
	m = len(ang)
	uni = [ang[0] + 2.0 * math.pi * i / m for i in range(m)]
	sh = sum(a - u for a, u in zip(ang, uni)) / m
	uni = [u + sh for u in uni]
	anelli = [cavallo]
	quote = [(z, r, p) for z, r, p in GAMBA]
	for k, (z, r, pesi) in enumerate(quote):
		s = min(1.0, 0.45 + 0.25 * k)
		rr = _r_gamba(z, r, corp)
		yc = _y_gamba(z)
		ring = []
		for a, u in zip(ang, uni):
			aa = a * (1.0 - s) + u * s
			ring.append(t.v((cx + rr * math.sin(aa), yc - rr * math.cos(aa), z),
				pesi, lato))
		anelli.append(ring)
	# L'orlo: più basso dietro, dove la stoffa cade sul tallone.
	r_orlo, pesi = ORLO_GAMBA
	rr = _r_gamba(0.09, r_orlo, corp)
	yc = _y_gamba(0.09)
	orlo, dentro = [], []
	for u in uni:
		zz = 0.081 + 0.019 * math.cos(u)
		orlo.append(t.v((cx + rr * math.sin(u), yc - rr * math.cos(u), zz),
			pesi, lato))
		dentro.append(t.v((cx + rr * 0.88 * math.sin(u), yc - rr * 0.88 * math.cos(u),
			zz + 0.008), pesi, lato))
	anelli.append(orlo)
	for a, b in zip(anelli, anelli[1:]):
		t.cuci(b, a, "pantaloni", lato)
	t.cuci(dentro, orlo, "pantaloni", lato)
	t.tappo(dentro, "pantaloni", -1, lato)
	return anelli


# ---------------------------------------------------------------------------
# 'E scarpe
# ---------------------------------------------------------------------------

## (y, mezza larghezza, altezza della tomaia) dal tallone alla punta.
SCARPA = [
	(0.074, 0.031, 0.078),
	(0.032, 0.040, 0.104),
	(-0.075, 0.046, 0.086),
	(-0.130, 0.047, 0.071),
	(-0.168, 0.041, 0.064),
	(-0.189, 0.027, 0.055),
]
## La punta tonda: il polo sta basso e appena avanti all'ultimo anello.
PUNTA = (-0.199, 0.040)
## Il contorno della suola (x rispetto al piede, y), antiorario da dietro.
SUOLA = [(0.0, 0.080), (-0.034, 0.068), (-0.044, 0.020), (-0.051, -0.070),
	(-0.051, -0.136), (-0.033, -0.188), (0.0, -0.205), (0.033, -0.188),
	(0.051, -0.136), (0.051, -0.070), (0.044, 0.020), (0.034, 0.068)]
Z_SUOLA = 0.022
Y_CAVIGLIA = 0.0358


def _pesi_piede(y):
	t = _liscio((-0.085 - y) / 0.06)
	return _mix(({"foot_l": 1.0}, 1.0 - t), ({"ball_l": 1.0}, t))


def scarpa(t, corp, lato):
	"""**'A scarpa, cu 'a sola chiara.** Una tomaia che corre dal tallone
	alla punta (sezione a D, piatta sotto) appoggiata su una suola che
	sporge di tre-cinque millimetri tutt'intorno: è la riga chiara che in
	Schedule I fa sembrare vere le scarpe. Ventotto centimetri, un
	quarantatré (la regola della scarpa 'e Pippo). E un colletto che sale
	dentro ai pantaloni: se l'orlo si alza camminando, sotto c'è scarpa,
	non caviglia nuda."""
	kp = corp.get("piede", 1.0)
	cx = X_GAMBA

	def P(x, y, z):
		return (cx + x * kp, Y_CAVIGLIA + (y - Y_CAVIGLIA) * kp, z)

	zs = Z_SUOLA * (0.8 if kp < 1.0 else 1.0)
	zb = zs - 0.002
	anelli = []
	for y, w, top in SCARPA:
		if kp < 1.0:
			top = zb + (top - zb) * 0.85
		zm = zb + 0.45 * (top - zb)
		pts = [(w, zm), (0.72 * w, zm + 0.78 * (top - zm)), (0.0, top),
			(-0.72 * w, zm + 0.78 * (top - zm)), (-w, zm), (-0.92 * w, zb),
			(0.0, zb), (0.92 * w, zb)]
		pesi = _pesi_piede(y)
		anelli.append([t.v(P(x, y, z), pesi, lato) for x, z in pts])
	for a, b in zip(anelli, anelli[1:]):
		t.cuci(a, b, "scarpe", lato)
	t.tappo(anelli[0], "scarpe", -1, lato)
	yp, zp = PUNTA
	polo = t.v(P(0.0, yp, zp), _pesi_piede(yp), lato)
	t.ventaglio(anelli[-1], polo, "scarpe", 1, lato)
	# La suola: sotto e sopra (il bordo che sporge si vede dall'alto).
	giu = [t.v(P(x, y, 0.0), _pesi_piede(y), lato) for x, y in SUOLA]
	su = [t.v(P(x, y, zs), _pesi_piede(y), lato) for x, y in SUOLA]
	t.cuci(giu, su, "suola", lato)
	t.tappo(giu, "suola", -1, lato)
	t.tappo(su, "suola", 1, lato)
	# Il colletto della scarpa, che sale dentro all'orlo dei pantaloni.
	kc = corp.get("caviglia", 1.0)
	r = 0.042 * (1.0 + (kc - 1.0) * 0.6)
	ya = 0.030
	a0 = [t.v((cx + r * math.cos(2 * math.pi * j / 8), ya + r * 1.08 * math.sin(
		2 * math.pi * j / 8), 0.070), {"foot_l": 1.0}, lato) for j in range(8)]
	a1 = [t.v((cx + r * 0.95 * math.cos(2 * math.pi * j / 8), ya - 0.004 + r * 1.02
		* math.sin(2 * math.pi * j / 8), 0.165), {"calf_l": 0.7, "foot_l": 0.3}, lato)
		for j in range(8)]
	t.cuci(a0, a1, "scarpe", lato)


# ---------------------------------------------------------------------------
# 'O cuorpo sano
# ---------------------------------------------------------------------------

def _ossa(g):
	mw = g.arm.matrix_world
	return {b.name: mw @ b.head_local for b in g.arm.data.bones}


def tela_corpo(g, corp):
	t = Tela()
	ossa = _ossa(g)
	maglietta(t, corp)
	pantaloni(t, corp)
	collo(t, corp)
	for lato in ("l", "r"):
		braccio(t, corp, lato, ossa)
		scarpa(t, corp, lato)
	return t


def corpo(g, corp):
	tela_corpo(g, corp).emetti(g)


# ---------------------------------------------------------------------------
# 'E piezze 'e coppa: colletto, cintura, catenina
# ---------------------------------------------------------------------------

def _su_stoffa(stoffa, p, stacco):
	"""Il punto della stoffa più vicino a `p`, spostato di `stacco` lungo la
	normale, coi pesi della stoffa."""
	loc, nor, pesi = stoffa.vicino(p)
	return loc + nor * stacco, nor, pesi


def cintura(g, corp):
	"""**'A cintura 'e cuoio.** Sta sulla fascia dei pantaloni di *quella*
	corporatura (la stessa funzione che fa la fascia, spostata fuori di
	quattro millimetri e mezzo lungo la normale), quindi al panzone passa
	sotto alla trippa senza entrarci. La fibbia davanti."""
	t = Tela()
	corpo_t = tela_corpo(g, corp)
	stoffa = corpo_t.albero({"pantaloni"})
	n = N_CAZUNE
	za, zb = 1.039, 1.006
	anelli = {}
	for nome, z in (("a", za), ("b", zb)):
		# La fascia a quota z: fra W1 (1,050) e W2 (1,002).
		z1, rx1, df1, db1, yc1 = CAZUNE[0]
		z2, rx2, df2, db2, yc2 = CAZUNE[1]
		u = (z - z2) / (z1 - z2)
		pts = _anello_tronco(n, z, rx2 + (rx1 - rx2) * u, df2 + (df1 - df2) * u,
			db2 + (db1 - db2) * u, yc2, corp)
		fuori, dentro = [], []
		for j, p in enumerate(pts):
			q = pts[(j + 1) % n] - pts[(j - 1) % n]
			nor = Vector((q.y, -q.x, 0.0)).normalized()
			pesi = stoffa.pesi(p)
			fuori.append(t.v(p + nor * 0.0045, pesi))
			dentro.append(t.v(p - nor * 0.0015, pesi))
		anelli[nome] = (fuori, dentro)
	fa, da = anelli["a"]
	fb, db_ = anelli["b"]
	t.cuci(fb, fa, "cuoio")
	t.cuci(fa, da, "cuoio")
	t.cuci(db_, fb, "cuoio")
	# La fibbia: un rettangolo di metallo, e dentro il cuoio che ci passa.
	a0, b0 = t.co[fa[0]], t.co[fb[0]]
	centro = (a0 + b0) * 0.5
	su = (a0 - b0).normalized()
	avanti_ = Vector((0.0, -1.0, 0.0))
	avanti_ = (avanti_ - su * avanti_.dot(su)).normalized()
	lato_ = su.cross(avanti_).normalized()
	pesi = stoffa.pesi(Vector((0.0, centro.y + 0.01, centro.z)))
	_scatola(t, centro, lato_, su, avanti_, 0.050, 0.038, 0.000, 0.0055, pesi,
		"metallo")
	_scatola(t, centro, lato_, su, avanti_, 0.030, 0.022, 0.0055, 0.0070, pesi,
		"cuoio")
	t.emetti(g)


def _scatola(t, centro, ax, ay, az, lx, ly, z0, z1, pesi, mat):
	"""Una scatola appoggiata: larga `lx` lungo `ax`, alta `ly` lungo `ay`,
	da `z0` a `z1` lungo `az` (la normale). Senza la faccia di dietro."""
	vs = {}
	for sx in (-1, 1):
		for sy in (-1, 1):
			for sz, zz in ((0, z0), (1, z1)):
				p = centro + ax * (sx * lx * 0.5) + ay * (sy * ly * 0.5) + az * zz
				vs[(sx, sy, sz)] = t.v(p, pesi)
	# davanti (verso az)
	t.f([vs[(-1, -1, 1)], vs[(1, -1, 1)], vs[(1, 1, 1)], vs[(-1, 1, 1)]], mat,
		liscio=False)
	t.f([vs[(-1, -1, 0)], vs[(1, -1, 0)], vs[(1, -1, 1)], vs[(-1, -1, 1)]], mat,
		liscio=False)
	t.f([vs[(1, 1, 0)], vs[(-1, 1, 0)], vs[(-1, 1, 1)], vs[(1, 1, 1)]], mat,
		liscio=False)
	t.f([vs[(-1, 1, 0)], vs[(-1, -1, 0)], vs[(-1, -1, 1)], vs[(-1, 1, 1)]], mat,
		liscio=False)
	t.f([vs[(1, -1, 0)], vs[(1, 1, 0)], vs[(1, 1, 1)], vs[(1, -1, 1)]], mat,
		liscio=False)
	# Se ax × ay non punta verso az, le facce sono girate: si rigirano.
	if ax.cross(ay).dot(az) < 0.0:
		for i in range(5):
			idx, m, l = t.facce[-1 - i]
			t.facce[-1 - i] = (tuple(reversed(idx)), m, l)


def colletto(g, corp):
	"""**'O culletto d''a polo.** Il girocollo resta sotto; sopra ci va un
	colletto vero, che si alza attorno al collo e ricade sulle spalle, aperto
	davanti con le due punte, e sotto una breve abbottonatura con tre
	bottoni. È il colletto del guappo, dello zio, dell'autista."""
	t = Tela()
	corpo_t = tela_corpo(g, corp)
	stoffa = corpo_t.albero({"camicia"})
	sc = _scollo(corp)
	n = N_MAGLIA
	sezioni = []
	cols = list(range(1, n))           # da davanti-sinistra a davanti-destra
	for idx, j in enumerate(cols):
		p = sc[j]
		d = Vector((p.x, p.y - 0.006, 0.0)).normalized()
		base = p + d * 0.003 + Vector((0.0, 0.0, 0.010))    # cima del bordino
		punta = idx in (0, len(cols) - 1)
		giu = 0.020 if punta else 0.0
		fuori = 0.030 + (0.012 if punta else 0.0)
		q = [base + d * 0.001 - Vector((0, 0, 0.012)),
			base - d * 0.007 + Vector((0, 0, 0.022)),
			base + d * fuori - Vector((0, 0, 0.008 + giu)),
			base + d * (fuori - 0.006) - Vector((0, 0, 0.002 + giu * 0.8))]
		if punta:
			# Le punte del colletto cadono in avanti, verso il centro.
			verso = Vector((0.0, -1.0, 0.0))
			q[2] = q[2] + verso * 0.010
			q[3] = q[3] + verso * 0.008
		sezioni.append([t.v(v, stoffa.pesi(v)) for v in q])
	for a, b in zip(sezioni, sezioni[1:]):
		t.cuci(a, b, "camicia")
	t.tappo(sezioni[0], "camicia", -1, liscio=True)
	t.tappo(sezioni[-1], "camicia", 1, liscio=True)
	# L'abbottonatura: una striscia rialzata sul centro del petto.
	zs = (sc[0].z - 0.004, 1.435, 1.385)
	righe = []
	for z in zs:
		riga = []
		for x in (0.0145, -0.0145):
			colpo = stoffa.raggio((x, -0.4, z), (0.0, 1.0, 0.0))
			loc, nor, pesi = colpo
			riga.append((loc, nor, pesi))
		righe.append(riga)
	fuori = [[t.v(loc + nor * 0.0028, pesi) for loc, nor, pesi in r] for r in righe]
	dentro = [[t.v(loc - nor * 0.0010, pesi) for loc, nor, pesi in r] for r in righe]
	for i in range(len(righe) - 1):
		# davanti (x va da + a −: guardando da davanti, da sinistra a destra)
		t.f([fuori[i][0], fuori[i][1], fuori[i + 1][1], fuori[i + 1][0]], "camicia")
		t.f([dentro[i][0], fuori[i][0], fuori[i + 1][0], dentro[i + 1][0]], "camicia")
		t.f([fuori[i][1], dentro[i][1], dentro[i + 1][1], fuori[i + 1][1]], "camicia")
	t.f([fuori[-1][0], fuori[-1][1], dentro[-1][1], dentro[-1][0]], "camicia",
		liscio=False)
	# I bottoni.
	for z in (1.458, 1.422, 1.388):
		loc, nor, pesi = stoffa.raggio((0.0, -0.4, z), (0.0, 1.0, 0.0))
		az = nor
		ax = Vector((1.0, 0.0, 0.0))
		ay = az.cross(ax).normalized()
		ax = ay.cross(az).normalized()
		_scatola(t, loc, ax, ay, az, 0.011, 0.011, 0.0022, 0.0050, pesi, "bottoni")
	t.emetti(g)


def catenina(g, corp):
	"""**'A catenella cu 'o curniciello.** Una catenina d'oro sottile che
	gira attorno al collo appoggiata sul girocollo, scende a V sul petto, e
	lì porta il cornetto rosso portafortuna: un corno di corallo ricurvo di
	quattro centimetri e mezzo con il cappuccio d'oro. È la cosa più
	napoletana che si possa mettere addosso a un pupo."""
	t = Tela()
	corpo_t = tela_corpo(g, corp)
	stoffa = corpo_t.albero({"camicia"})
	sc = _scollo(corp)
	n = 12
	cx, cy = _collo_r(corp)
	z_giu = 1.448 - 0.3 * _trippa(1.30, corp)
	punti = []
	for j in range(n):
		a = 2.0 * math.pi * j / n
		s, c = math.sin(a), math.cos(a)
		# Il giro attorno al collo, appena fuori dal bordino…
		p = Vector(((cx + 0.024) * s, 0.008 - (cy + 0.024) * c, 1.506 + 0.004 * max(0, -c)))
		# …e davanti scende sul petto.
		av = max(0.0, c) ** 2.2
		p.z = p.z * (1.0 - av) + z_giu * av
		p.y -= 0.02 * av
		q, nor, pesi = _su_stoffa(stoffa, p, 0.0035)
		punti.append((q, nor, pesi))
	anelli = []
	for j, (q, nor, pesi) in enumerate(punti):
		dd = punti[(j + 1) % n][0] - punti[(j - 1) % n][0]
		anelli.append([t.v(v, pesi) for v in _anello_dir(q, dd, 0.0024, 0.0024, 3)])
	for j in range(n):
		t.cuci(anelli[j], anelli[(j + 1) % n], "oro")
	# 'O curniciello: pende dal punto più basso, poggiato sul petto, e si
	# piega di lato come un corno vero.
	q0, nor0, pesi0 = punti[0]
	giu = Vector((0.0, 0.0, -1.0))
	giu = (giu - nor0 * giu.dot(nor0)).normalized()
	lato_ = nor0.cross(giu).normalized()
	cen = [(0.000, 0.0, 0.0055, "oro"), (0.006, 0.0, 0.0064, "oro"),
		(0.020, 0.002, 0.0056, "corallo"), (0.036, 0.008, 0.0034, "corallo")]
	anelli = []
	for s, dx, r, _ in cen:
		p = q0 + giu * (s + 0.004) + lato_ * dx
		p, nor, pesi = _su_stoffa(stoffa, p, 0.0075 + r * 0.9)
		anelli.append((p, r, pesi))
	punta = anelli[-1][0] + giu * 0.011 + lato_ * 0.007 + nor0 * 0.003
	vv = []
	for i, (p, r, pesi) in enumerate(anelli):
		dd = (anelli[min(i + 1, len(anelli) - 1)][0] - anelli[max(i - 1, 0)][0])
		vv.append([t.v(q, pesi) for q in _anello_dir(p, dd, r, r, 5)])
	mats = [c[3] for c in cen]
	for i in range(len(vv) - 1):
		t.cuci(vv[i], vv[i + 1], mats[i + 1] if i > 0 else "oro")
	t.tappo(vv[0], "oro", -1, liscio=True)
	polo = t.v(punta, anelli[-1][2])
	t.ventaglio(vv[-1], polo, "corallo")
	t.emetti(g)


## Il gilet: gli spicchi di un fianco (gradi dal centro davanti; l'altro è
## lo specchio), le righe piene (quota, materiale della fascia che sale da
## lì) e le righe di sopra, dove ci sono solo i due pannelli.
GILET_ANGOLI = [15.0, 38.0, 62.0, 90.0, 125.0, 150.0, 180.0]
GILET_RIGHE = [(0.985, "gilet"), (1.055, "metallo"), (1.095, "gilet"),
	(1.185, "metallo"), (1.225, "gilet"), (1.310, "gilet")]
GILET_SOPRA = [1.380, 1.450]
GILET_DAVANTI = (15.0, 38.0, 62.0)
GILET_DIETRO = (125.0, 150.0, 180.0)


def gilet(g, corp):
	"""**'O gilet d''o parcheggiatore.** Arancione ad alta visibilità, senza
	maniche, aperto davanti a V con le due falde, giromanica larghi, e due
	strisce catarifrangenti grigie attorno alla vita e al petto — quelle
	vere, che la sera si vedono da lontano. Finisce poco sotto la vita,
	sopra alla cintura.

	È un guscio staccato dalla maglietta (1,2 cm; 1,7 sotto 1,05, dove
	passano la fascia, la cintura e la fibbia): ogni vertice nasce da un
	raggio che va verso l'asse del corpo e si ferma sulla stoffa vera, e ne
	copia i pesi. Così si muove con la maglietta in ogni clip. Le spalline
	passano sopra le spalle, fra il collo (dove sta la catenina) e il
	giromanica.

	Le strisce sono fasce del guscio stesso col materiale `metallo` (grigio
	chiaro, un po' lucido, non lo tinge il gioco): costano zero triangoli
	in più."""
	t = Tela()
	corpo_t = tela_corpo(g, corp)
	stoffa = corpo_t.albero({"camicia", "pantaloni"})

	def colpo(ang, z):
		th = math.radians(ang)
		d = Vector((math.sin(th), -math.cos(th), 0.0))
		o = Vector((0.0, 0.015, z))
		r = stoffa.raggio(o + d * 0.6, -d)
		loc, nor, pesi = r
		stacco = 0.017 if z < 1.05 else 0.012
		return loc + nor * stacco, nor, pesi

	def v_colpo(ang, z):
		p, nor, pesi = colpo(ang, z)
		i = t.v(p, pesi)
		return i, nor

	# gli spicchi di tutto il giro, aperto davanti: da +15° per il fianco
	# sinistro fino a dietro, e giù per il destro fino a −15°
	giro = list(GILET_ANGOLI) + [-a for a in reversed(GILET_ANGOLI[:-1])]
	righe = []
	for z, mat in GILET_RIGHE:
		righe.append(([v_colpo(a, z) for a in giro], mat))
	# sopra: solo i pannelli
	pannelli = [a for a in giro if abs(a) in GILET_DAVANTI or abs(a) in GILET_DIETRO]
	for z in GILET_SOPRA:
		riga = {}
		for a in pannelli:
			riga[a] = v_colpo(a, z)
		righe.append((riga, "gilet"))

	def quad(vs, mat):
		nor = sum((n for _, n in vs), Vector()).normalized()
		t.f_verso([i for i, _ in vs], mat, nor)

	# le fasce piene
	for (r0, mat), (r1, _) in zip(righe[:len(GILET_RIGHE)], righe[1:len(GILET_RIGHE)]):
		for k in range(len(giro) - 1):
			quad([r0[k], r0[k + 1], r1[k + 1], r1[k]], mat)
	# dalla riga piena più alta ai pannelli, e fra i pannelli
	ultima = dict(zip(giro, righe[len(GILET_RIGHE) - 1][0]))
	prec = ultima
	for riga, _ in righe[len(GILET_RIGHE):]:
		for a0, a1 in zip(pannelli, pannelli[1:]):
			vicini = abs(giro.index(a1) - giro.index(a0)) == 1
			if not vicini:
				continue
			quad([prec[a0], prec[a1], riga[a1], riga[a0]], "gilet")
		prec = riga
	# le spalline: dal bordo alto davanti (38°, 62°) a quello dietro
	# (150°, 125°), passando sopra la spalla
	alto = prec
	for sx in (1.0, -1.0):
		dentro = [alto[sx * 38.0]]
		fuori = [alto[sx * 62.0]]
		pd = t.co[alto[sx * 38.0][0]]
		pf = t.co[alto[sx * 62.0][0]]
		qd = t.co[alto[sx * 150.0][0]]
		qf = t.co[alto[sx * 125.0][0]]
		for u in (1.0 / 3.0, 2.0 / 3.0):
			for lista, a, b in ((dentro, pd, qd), (fuori, pf, qf)):
				m = a.lerp(b, u)
				r = stoffa.raggio((m.x, m.y, 1.8), (0.0, 0.0, -1.0))
				loc, nor, pesi = r
				lista.append((t.v(loc + nor * 0.012, pesi), nor))
		dentro.append(alto[sx * 150.0])
		fuori.append(alto[sx * 125.0])
		for k in range(3):
			quad([dentro[k], fuori[k], fuori[k + 1], dentro[k + 1]], "gilet")
	t.emetti(g)


def extra():
	return [("colletto", colletto), ("cintura", cintura), ("catenina", catenina),
		("gilet", gilet)]


# ---------------------------------------------------------------------------
# 'A gonna e 'a banda rossa
# ---------------------------------------------------------------------------

## In vita 16 spicchi, gli stessi dei pantaloni (la gonna sta a 2,5 mm dalla
## fascia e la cintura a 4,5: con spicchi diversi le corde si
## incrocerebbero); dall'anca in giù 18, che al centro davanti e dietro la
## stoffa sia abbastanza fitta da stare dietro a due cosce che vanno in
## direzioni opposte.
N_GONNA = 16
N_GONNA_GIU = 18
## La gonna, riga per riga: (quota, forma, a, b, c).
##   "fascia": sulla fascia dei pantaloni, staccata di `a`;
##   "sedere": sui fianchi, staccata di `a` davanti e `b` dietro;
##   "anca":   sui fianchi dei pantaloni (W4), staccata di `a`;
##   "apri":   l'anca allargata di `a` di lato, `b` davanti, `c` dietro.
GONNA = [
	(1.040, "fascia", 0.0025, 0.0, 0.0),
	(1.002, "fascia", 0.0025, 0.0, 0.0),
	(0.965, "sedere", 0.012, 0.020, 0.0),
	(0.915, "anca", 0.035, 0.0, 0.0),
	(0.800, "apri", 1.14, 1.26, 1.20),
	(0.660, "apri", 1.18, 1.30, 1.30),
	(0.420, "apri", 1.24, 1.34, 1.40),
]
## Quanto netta è la divisione fra coscia sinistra e destra al centro.
GONNA_SPARTI = 0.05
## Quanto si addensano gli spicchi al centro davanti e dietro (0 = uguali).
GONNA_STRINGI = 0.7
## Quanto la striscia al centro davanti, in basso, pende dal bacino invece
## di seguire le cosce (l'amaca fra le ginocchia della signora seduta).
GONNA_AMACA = 0.3
## Quanto il pannello di dietro, sotto a metà coscia, segue le cosce (1 =
## tutto, come i pantaloni; meno = pende).
GONNA_DIETRO = 1.0


def pesi_gonna(p):
	"""**'A gonna se pesa comme 'e cazune.** Alla quota `z` segue le cosce
	quanto le seguono i pantaloni che ci stanno sotto (la stessa rampa di
	`pesi_tronco`: niente sopra l'anca, tutto da metà coscia in giù), e da
	ogni lato segue la coscia del suo lato; solo la striscia al centro,
	davanti e dietro, sta a metà fra le due. Così la stoffa e la gamba si
	muovono insieme e la gamba non la può passare.

	**Pecché nun se faceva a campana.** La prima gonna aveva pesi suoi
	(davanti 45% di coscia all'anca, 78% a metà coscia): in città le passanti
	camminano anche di corsa (il gioco mescola Walk, Jog_Fwd e Sprint), la
	coscia sale di 50–90 gradi e il pezzo di coscia sotto l'anca veniva
	avanti più svelto della stoffa. Si vedevano triangoli di calza in mezzo
	alla gonna. E la riga dell'anca pesata sulla coscia non aiuta: un punto
	davanti al giunto, ruotando, sale verso la pancia invece di andare avanti."""
	w = pesi_tronco(Vector((p.x, p.y, max(p.z, 0.99))))
	q = _liscio((0.975 - p.z) / 0.135)
	if q <= 0.0:
		return w
	if p.y < 0.012:
		# **L'amaca.** Seduta, le due cosce vanno avanti insieme e una gonna
		# che le segue del tutto diventa un tubo con la bocca verso chi
		# guarda. La stoffa vera fra le ginocchia pende: la striscia al
		# centro davanti, dal ginocchio in giù, resta un po' sul bacino.
		q *= 1.0 - GONNA_AMACA * _liscio((0.76 - p.z) / 0.20) * (
			1.0 - _liscio(abs(p.x) / 0.03))
	if p.y > 0.012 and GONNA_DIETRO < 1.0:
		r = math.hypot(p.x, p.y - 0.012)
		q *= 1.0 - (1.0 - GONNA_DIETRO) * _liscio((0.75 - p.z) / 0.25) * (
			(p.y - 0.012) / max(r, 1e-6)) ** 1.5
	ax = abs(p.x)
	lato = "l" if p.x >= 0 else "r"
	altro = "r" if lato == "l" else "l"
	s = _liscio(ax / GONNA_SPARTI)
	cosce = {"thigh_" + lato: 0.5 + 0.5 * s, "thigh_" + altro: 0.5 - 0.5 * s}
	return _mix((w, 1.0 - q), (cosce, q))


def gonna(g):
	"""**'A gonna ad A** d''a signora: dalla vita a un palmo sotto al
	ginocchio. In cima sta sulla fascia dei pantaloni (sotto all'orlo della
	maglietta e sotto alla cintura, se c'è); sui fianchi sta **larga**, tre
	centimetri e mezzo fuori dai pantaloni, perché quando la coscia sale
	(corsa, seduta) la stoffa ha lo spazio per venirle dietro; scendendo si
	apre, più dietro e di lato che davanti. Di sotto l'orlo gira in dentro
	e la fodera risale fino a metà coscia: da sotto, o seduta, dentro c'è
	stoffa e non il vuoto.

	Le forme e i pesi sono stati misurati sulle clip vere (Walk, Jog_Fwd,
	Sprint, metà Walk/Jog, Sitting_Idle, Crouch_Idle): per ogni posa si
	contano i punti di coscia che finiscono fuori dalla gonna e si vedono da
	due metri, davanti e di tre quarti."""
	corp = CORPORATURE["femmina"]
	t = Tela()
	n = N_GONNA

	def ring_su(pts, off):
		out = []
		for j, p in enumerate(pts):
			q = pts[(j + 1) % n] - pts[(j - 1) % n]
			nor = Vector((q.y, -q.x, 0.0)).normalized()
			out.append(p + nor * off)
		return out

	def fascia(z):
		z1, rx1, df1, db1, yc1 = CAZUNE[0]
		z2, rx2, df2, db2, yc2 = CAZUNE[1]
		u = (z - z2) / (z1 - z2)
		return _anello_tronco(n, z, rx2 + (rx1 - rx2) * u, df2 + (df1 - df2) * u,
			db2 + (db1 - db2) * u, yc2, corp)

	m = N_GONNA_GIU
	za, rxa, dfa, dba, yca = CAZUNE[2]
	# **'E spicche fitte 'o miezo.** Nel passo lungo una coscia va avanti e
	# l'altra indietro: la colonna proprio al centro sta a metà fra le due,
	# e fra lei e la prima vicina (che segue la coscia avanti) la stoffa
	# resta indietro e si ripiega — le facce girate non si disegnano e si
	# apriva uno spacco con la coscia dentro. Gli spicchi si addensano al
	# centro davanti e dietro (la prima vicina sta a tre centimetri invece
	# che a sette) e si diradano sui fianchi, dove non serve.
	angoli = [2.0 * math.pi * j / m - GONNA_STRINGI * math.sin(4.0 * math.pi * j / m) / 2.0
		for j in range(m)]
	anca0 = [_punto_tronco(a, za, rxa, dfa, dba, yca, corp) for a in angoli]

	def ring_su_m(pts, off):
		out = []
		for j, p in enumerate(pts):
			q = pts[(j + 1) % m] - pts[(j - 1) % m]
			nor = Vector((q.y, -q.x, 0.0)).normalized()
			out.append(p + nor * off)
		return out

	anca = anca0
	righe = []
	for z, forma, a, b, c in GONNA:
		if forma == "fascia":
			pts = ring_su(fascia(z), a)
		elif forma == "anca":
			anca = ring_su_m(anca0, a)
			pts = [Vector((p.x, p.y, z)) for p in anca]
		elif forma == "sedere":
			# **'O culo nun ha da scassà 'a gonna.** Dritta dalla fascia
			# all'anca, la stoffa tagliava la curva del sedere (e le tasche
			# di dietro) a mezzo centimetro: appena la coscia saliva, da
			# dietro spuntava il sedere. Un anello in mezzo, un po' più
			# staccato dietro, e la corda gira attorno.
			pts = []
			for j, p in enumerate(anca0):
				q = anca0[(j + 1) % m] - anca0[(j - 1) % m]
				nor = Vector((q.y, -q.x, 0.0)).normalized()
				die = max(0.0, (p.y - 0.012) / max(0.05, abs(p.y - 0.012) + abs(p.x)))
				pts.append(Vector((p.x, p.y, z)) + nor * (a + (b - a) * _liscio(die * 1.4)))
		else:
			pts = [Vector((p.x * a, 0.012 + (p.y - 0.012) * (b if p.y < 0.012 else c), z))
				for p in anca]
		righe.append(pts)
	vv = [[t.v(p, pesi_gonna(p)) for p in pts] for pts in righe]
	for a, b in zip(vv[1:], vv):
		if len(a) == len(b):
			t.cuci(a, b, "gonna")
		else:
			_cuci_giro(t, a, b, "gonna")
	# La fodera: dall'orlo la stoffa gira in dentro e risale fino alla riga
	# di sopra, con le facce girate verso l'interno. Da sotto, o seduta,
	# dentro c'è stoffa e non il vuoto.
	k = 0.96
	fodera = [t.v(Vector((p.x * k, 0.012 + (p.y - 0.012) * k, p.z)),
		pesi_gonna(p)) for p in righe[-2]]
	t.cuci(fodera, vv[-1], "gonna")
	t.emetti(g)


def _cuci_giro(t, sotto, sopra, mat):
	"""Cuce due anelli orizzontali con un numero diverso di vertici (per
	angolo attorno all'asse del corpo): `sotto` più in basso di `sopra`,
	le facce verso fuori."""
	def ang(i):
		p = t.co[i]
		return math.atan2(p.x, -(p.y - 0.012)) % (2.0 * math.pi)
	aa = sorted(sotto, key=ang)
	bb = sorted(sopra, key=ang)
	i = j = 0
	na, nb = len(aa), len(bb)
	while i < na or j < nb:
		a0, a1 = aa[i % na], aa[(i + 1) % na]
		b0, b1 = bb[j % nb], bb[(j + 1) % nb]
		ta = ang(a1) + (2.0 * math.pi if i + 1 >= na else 0.0)
		tb = ang(b1) + (2.0 * math.pi if j + 1 >= nb else 0.0)
		if j >= nb or (i < na and ta <= tb):
			t.f([a0, a1, b0], mat)
			i += 1
		else:
			t.f([a0, b1, b0], mat)
			j += 1


def banda_rossa(g):
	"""**'A banda rossa d''e carabiniere**, cucita sul fianco dei pantaloni
	nuovi: tre vertici di larghezza (cinque centimetri), cinque millimetri
	fuori dalla stoffa, pesata come la stoffa che copre. È fatta sulla
	corporatura `normale`, che è quella dei carabinieri del gioco."""
	corp = CORPORATURE["normale"]
	t = Tela()
	t_c = Tela()
	pantaloni(t_c, corp)
	stoffa = t_c.albero({"pantaloni"})
	quote = [0.990, 0.930, 0.845, 0.745, 0.625, 0.555, 0.505, 0.400, 0.250, 0.140]
	for lato, sx in (("l", 1.0), ("r", -1.0)):
		prec = None
		for z in quote:
			yc = _y_gamba(z) if z < 0.85 else 0.010
			riga = []
			for dy in (-0.025, 0.0, 0.025):
				colpo = stoffa.raggio((sx * 0.6, yc + dy, z), (-sx, 0.0, 0.0))
				loc, nor, pesi = colpo
				riga.append(t.v(loc + nor * 0.005, pesi))
			if prec is not None:
				for j in range(2):
					if sx > 0:
						t.f([riga[j], riga[j + 1], prec[j + 1], prec[j]], "banda")
					else:
						t.f([prec[j], prec[j + 1], riga[j + 1], riga[j]], "banda")
			prec = riga
	t.emetti(g)


def pezzi():
	return [("gonna", gonna), ("banda_rossa", banda_rossa)]
