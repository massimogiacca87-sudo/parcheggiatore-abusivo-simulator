"""'E pupe, modellate 'a zero — no cchiù 'o manichino d''a Unreal vestito.

**Pecché s'è ghiettato tutto e s'è ricumminciato.**

Alla 0.48 il personaggio *era* il manichino di `UAL1_Standard.glb`: gli
ingrossavo la testa e poi gli assegnavo i materiali faccia per faccia —
questa faccia è camicia, questa è pantaloni. Due guai, tutti e due
irreparabili con quel metodo:

1. **'O manichino è 'nu culturista.** È il manichino di Unreal: pettorali
   segnati, deltoidi, polpacci, vita stretta. Nessuna vernice lo fa
   sembrare un tizio che sta al bar da trent'anni. La forma era sbagliata
   in partenza.
2. **'E vestite dipinte se veéno strappate.** Un confine fra due materiali
   corre per forza lungo i **lati dei triangoli**: a un metro di distanza
   quel bordo a zigzag si legge esattamente per quello che è, una maglietta
   stracciata. Non è un problema di soglie — l'ho spostata tre volte — è
   che un orlo dipinto non è un orlo.

Quindi: **il manichino si butta**, si tengono lo scheletro (65 ossa) e le
**quarantatré animazioni**, e il corpo si modella qui dentro, misurato
sulle ossa. Le animazioni restano valide per costruzione: sono fatte per
quello scheletro, e il corpo nuovo sta appeso a quello scheletro.

**Comme se fa 'nu pupo.** Tutto è tubi lungo una spezzata di punti, con
una sezione ellittica per punto e i pesi delle ossa scritti a mano nodo per
nodo. Niente muscoli, perché non si modellano: il braccio è un cono con un
gomito appena accennato, il petto è un barile morbido. E i **vestiti sono
geometria vera** — una camicia è un guscio più largo del corpo che finisce
con un orlo arrotondato, non una zona di colore.

    python3 tools/build_personaggi.py
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy                                    # noqa: E402
import bmesh                                  # noqa: E402
from mathutils import Vector                  # noqa: E402
import blender_comune as C                    # noqa: E402

RADICE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
USCITA = os.path.join(RADICE, "assets", "models", "pupo.glb")

FONTI = [
	"/tmp/ual/UAL1_Standard.glb",
	"/mnt/user-data/uploads/Parcheggiatore Abusivo Simulator/Animations/"
	"Universal Animation Library[Standard]/Universal Animation Library"
	"[Standard]/Unreal-Godot/UAL1_Standard.glb",
]

## Quanti spicchi ha un anello. Il busto ne vuole di più perché è largo e
## si vede da vicino; un braccio a otto spicchi a due metri è tondo.
SEG_BUSTO = 10
SEG_ARTO = 8
SEG_TESTA = 14
ANELLI_TESTA = 9

MATERIALI = [
	("pelle", (0.87, 0.69, 0.55), 0.72),
	("camicia", (0.84, 0.85, 0.87), 0.92),
	("pantaloni", (0.24, 0.26, 0.32), 0.92),
	("scarpe", (0.11, 0.10, 0.10), 0.55),
	("capelli", (0.15, 0.10, 0.07), 0.95),
	("occhio_bianco", (0.96, 0.96, 0.95), 0.35),
	("occhio_nero", (0.05, 0.05, 0.06), 0.30),
	# **'E tratte stanno 'a parte apposta.** Sopracciglia e bocca prima
	# usavano il materiale dei capelli, e il gioco al pelato dà ai capelli
	# il colore della pelle: il pelato usciva **senza faccia**.
	("tratti", (0.13, 0.09, 0.07), 0.90),
	# 'A banda rossa d''e carabiniere: sta 'a parte, e si accende solo a
	# chi la deve portare.
	("banda", (0.64, 0.09, 0.11), 0.88),
]
MAT = {n: i for i, (n, _, _) in enumerate(MATERIALI)}


# ---------------------------------------------------------------------------
# 'E misure, prese 'a ncopp'ê osse
# ---------------------------------------------------------------------------
#
# Tutte le quote qui sotto vengono dallo scheletro vero, letto una volta e
# scritto qui perché si legga assieme al corpo che ci sta appeso:
#
#   caviglia 0.104 · ginocchio 0.532 · anca 0.932 · vita 1.051
#   petto 1.315 · spalla (0.192, 0.065, 1.441) · gomito 0.466 · polso 0.739
#   collo 1.488 · testa 1.569
#
Z_CAVIGLIA = 0.1037
Z_GINOCCHIO = 0.5318
Z_ANCA = 0.9321
Z_VITA = 1.0505
Z_PETTO = 1.3148
Z_SPALLA = 1.4408
Z_COLLO = 1.4876
X_GAMBA = 0.0890
X_SPALLA = 0.1919
X_GOMITO = 0.4663
X_POLSO = 0.7389
Y_BRACCIO = 0.0660

## 'A capa. È la misura che da sola decide lo stile: il pupo è alto 1,79 e
## la testa è alta 27 cm, cioè **sei teste e mezza**. Un uomo vero ne fa
## sette e mezza; i personaggi delle immagini di riferimento stanno fra sei
## e sei e mezza. Più grossa di così diventa un giocattolo.
TESTA_C = Vector((0.0, -0.012, 1.6537))
TESTA_R = Vector((0.118, 0.128, 0.135))


def _liscio(t):
	t = min(1.0, max(0.0, t))
	return t * t * (3.0 - 2.0 * t)


def _campana(z, a, b):
	"""1 nel mezzo dell'intervallo, 0 fuori, morbido ai bordi."""
	if z <= a or z >= b:
		return 0.0
	m = (a + b) * 0.5
	h = (b - a) * 0.5
	return _liscio(1.0 - abs(z - m) / h)


## **'E corporature.** Non è che uno solo basta: quaranta persone in piazza
## tutte con lo stesso corpo si vedono subito. Ognuna è un pugno di
## moltiplicatori sulle stesse misure — non geometria diversa, la stessa
## geometria tirata.
CORPORATURE = {
	"normale": {},
	# 'O panzone: pancia avanti, spalle un po' più larghe, braccia grosse.
	# Cresciuto ancora un po' alla 0.50: il capo lo voleva più panzuto, e
	# a vederlo in piazza accanto agli altri aveva ragione — con 1,34 si
	# leggeva come "robusto", non come panzone.
	"panzone": {"pancia": 1.44, "petto": 1.15, "spalle": 1.06,
		"fianchi": 1.18, "braccia": 1.24, "gambe": 1.18, "avanti": 0.064},
	# 'O sicco: tutto stretto, spalle comprese.
	"magro": {"pancia": 0.80, "petto": 0.87, "spalle": 0.93,
		"fianchi": 0.88, "braccia": 0.80, "gambe": 0.86},
	# 'A femmina: spalle strette, fianchi larghi, braccia sottili.
	"femmina": {"pancia": 0.88, "petto": 0.97, "spalle": 0.86,
		"fianchi": 1.14, "braccia": 0.80, "gambe": 0.95},
}


def fattore(z, corp):
	"""Quanto allargare una sezione del tronco a quota `z`.

	Le quattro fasce si sovrappongono a campana, così non c'è mai uno
	scalino fra una e l'altra: un panzone ha la pancia che *cresce* dalla
	vita al petto, non un anello grosso in mezzo a due sottili."""
	f = 1.0
	f *= 1.0 + (corp.get("fianchi", 1.0) - 1.0) * _campana(z, 0.78, 1.00)
	f *= 1.0 + (corp.get("pancia", 1.0) - 1.0) * _campana(z, 0.94, 1.27)
	f *= 1.0 + (corp.get("petto", 1.0) - 1.0) * _campana(z, 1.16, 1.40)
	f *= 1.0 + (corp.get("spalle", 1.0) - 1.0) * _campana(z, 1.33, 1.52)
	return f


def avanti(z, corp):
	"""Di quanto sporge in avanti la pancia (metri, verso −Y)."""
	return -corp.get("avanti", 0.0) * _campana(z, 0.96, 1.30)


# ---------------------------------------------------------------------------
# 'A cassetta d''e ferre: tubi, sfere, cupole
# ---------------------------------------------------------------------------

class Pupo:
	"""Una mesh in costruzione, con i pesi delle ossa."""

	def __init__(self, nome, arm):
		self.me = bpy.data.meshes.new(nome)
		self.ob = bpy.data.objects.new(nome, self.me)
		bpy.context.collection.objects.link(self.ob)
		for b in arm.data.bones:
			self.ob.vertex_groups.new(name=b.name)
		self.gi = {vg.name: vg.index for vg in self.ob.vertex_groups}
		self.bm = bmesh.new()
		self.dl = self.bm.verts.layers.deform.verify()
		self.arm = arm

	# -- vertici e pesi ----------------------------------------------------
	def vert(self, co, pesi):
		v = self.bm.verts.new(co)
		tot = sum(pesi.values())
		if tot <= 0.0:
			tot = 1.0
		for osso, w in pesi.items():
			if w <= 0.0:
				continue
			v[self.dl][self.gi[osso]] = w / tot
		return v

	def faccia(self, verts, mat, liscio=True):
		try:
			f = self.bm.faces.new(verts)
		except ValueError:
			return None            # faccia doppia: capita ai poli, s'ignora
		f.material_index = MAT[mat]
		f.smooth = liscio
		return f

	# -- anelli ------------------------------------------------------------
	def _telaio(self, direzione):
		"""Il sistema di riferimento di un anello: due assi nel piano della
		sezione, perpendicolari alla spezzata."""
		d = direzione.normalized()
		rif = Vector((0.0, 1.0, 0.0)) if abs(d.z) > 0.9 else Vector((0.0, 0.0, 1.0))
		lato = rif.cross(d)
		if lato.length < 1e-5:
			lato = Vector((1.0, 0.0, 0.0))
		lato.normalize()
		su = d.cross(lato)
		return lato, su

	def anello(self, punto, direzione, ra, rb, pesi, seg, pesi_fn=None):
		lato, su = self._telaio(direzione)
		out = []
		for j in range(seg):
			a = 2.0 * math.pi * j / seg
			p = punto + lato * (ra * math.cos(a)) + su * (rb * math.sin(a))
			out.append(self.vert(p, pesi_fn(p) if pesi_fn else pesi))
		return out

	def cuci(self, a, b, mat, liscio=True):
		n = len(a)
		for j in range(n):
			k = (j + 1) % n
			self.faccia([a[j], a[k], b[k], b[j]], mat, liscio)

	def tappo(self, anello, mat, verso=1, liscio=False):
		vs = list(anello) if verso > 0 else list(reversed(anello))
		self.faccia(vs, mat, liscio)

	def punta(self, anello, punto, direzione, ra, rb, pesi, mat, seg,
			verso=1):
		"""Chiude un tubo con una cupoletta invece che con un disco piatto.
		Due anelli che si stringono e un polo: costa otto triangoli e
		toglie lo spigolo netto che si vede da lontano."""
		d = direzione.normalized()
		prec = anello
		for k, (avanza, stretta) in enumerate(((0.40, 0.80), (0.76, 0.50))):
			pr = punto + d * (max(ra, rb) * avanza)
			nuovo = self.anello(pr, d, ra * stretta, rb * stretta, pesi, seg)
			if verso > 0:
				self.cuci(prec, nuovo, mat)
			else:
				self.cuci(nuovo, prec, mat)
			prec = nuovo
		polo = self.vert(punto + d * (max(ra, rb) * 1.0), pesi)
		for j in range(seg):
			k = (j + 1) % seg
			if verso > 0:
				self.faccia([prec[j], prec[k], polo], mat)
			else:
				self.faccia([prec[k], prec[j], polo], mat)

	def orlo(self, anello, punto, direzione, ra, rb, pesi, mat, seg,
			spessore=0.020):
		"""**L'orlo d''a rrobba.** Un guscio di stoffa che finisce di netto
		mostra il taglio del poligono; un orlo vero si arrotonda e rientra.
		Un anello più stretto, spostato in avanti di due centimetri, e poi
		il disco — che resta dentro al corpo e non si vede mai."""
		d = direzione.normalized()
		pr = punto + d * spessore
		giu = self.anello(pr, d, ra * 0.90, rb * 0.90, pesi, seg)
		self.cuci(anello, giu, mat)
		self.tappo(giu, mat, 1)

	def tubo(self, nodi, mat, seg=8, testa=None, coda=None, liscio=True):
		"""`nodi` = lista di dizionari {p, ra, rb, pesi, [pesi_fn]}.

		`testa`/`coda`: None = niente, "tappo" = disco piatto, "punta" =
		cupoletta, "orlo" = orlo di stoffa."""
		anelli = []
		for i, n in enumerate(nodi):
			if i == 0:
				d = nodi[1]["p"] - n["p"]
			elif i == len(nodi) - 1:
				d = n["p"] - nodi[i - 1]["p"]
			else:
				d = nodi[i + 1]["p"] - nodi[i - 1]["p"]
			anelli.append(self.anello(n["p"], d, n["ra"], n["rb"], n["pesi"],
				seg, n.get("pesi_fn")))
		for i in range(len(anelli) - 1):
			self.cuci(anelli[i], anelli[i + 1], mat, liscio)
		n0, nN = nodi[0], nodi[-1]
		d0 = (n0["p"] - nodi[1]["p"])
		dN = (nN["p"] - nodi[-2]["p"])
		if testa == "tappo":
			self.tappo(anelli[0], mat, -1)
		elif testa == "punta":
			self.punta(anelli[0], n0["p"], d0, n0["ra"], n0["rb"],
				n0["pesi"], mat, seg, verso=-1)
		elif testa == "orlo":
			self.orlo(list(reversed(anelli[0])), n0["p"], d0, n0["ra"],
				n0["rb"], n0["pesi"], mat, seg)
		if coda == "tappo":
			self.tappo(anelli[-1], mat, 1)
		elif coda == "punta":
			self.punta(anelli[-1], nN["p"], dN, nN["ra"], nN["rb"],
				nN["pesi"], mat, seg, verso=1)
		elif coda == "orlo":
			self.orlo(anelli[-1], nN["p"], dN, nN["ra"], nN["rb"],
				nN["pesi"], mat, seg)
		return anelli

	def sfera(self, centro, raggi, pesi, mat, seg=10, anelli=6, liscio=True):
		righe = []
		for i in range(1, anelli):
			phi = math.pi * i / anelli
			r = math.sin(phi)
			z = math.cos(phi)
			riga = []
			for j in range(seg):
				a = 2.0 * math.pi * j / seg
				p = centro + Vector((raggi.x * r * math.cos(a),
					raggi.y * r * math.sin(a), raggi.z * z))
				riga.append(self.vert(p, pesi))
			righe.append(riga)
		su = self.vert(centro + Vector((0, 0, raggi.z)), pesi)
		giu = self.vert(centro - Vector((0, 0, raggi.z)), pesi)
		for j in range(seg):
			k = (j + 1) % seg
			self.faccia([righe[0][k], righe[0][j], su], mat, liscio)
			self.faccia([righe[-1][j], righe[-1][k], giu], mat, liscio)
		for i in range(len(righe) - 1):
			self.cuci(righe[i + 1], righe[i], mat, liscio)
		return righe

	def cupola(self, centro, raggi, pesi, mat, theta_fn, seg=12, anelli=4):
		"""Una calotta con il bordo **che sale e scende**: davanti si ferma
		alta (l'attaccatura dei capelli sulla fronte), dietro scende sulla
		nuca. È quello che distingue una capigliatura da un casco."""
		righe = []
		for i in range(1, anelli + 1):
			t = i / float(anelli)
			riga = []
			for j in range(seg):
				a = 2.0 * math.pi * j / seg
				phi = theta_fn(a) * t
				r = math.sin(phi)
				z = math.cos(phi)
				p = centro + Vector((raggi.x * r * math.cos(a),
					raggi.y * r * math.sin(a), raggi.z * z))
				riga.append(self.vert(p, pesi))
			righe.append(riga)
		polo = self.vert(centro + Vector((0, 0, raggi.z)), pesi)
		for j in range(seg):
			k = (j + 1) % seg
			self.faccia([righe[0][k], righe[0][j], polo], mat)
		for i in range(len(righe) - 1):
			self.cuci(righe[i + 1], righe[i], mat)
		self.tappo(righe[-1], mat, -1)

	def scatola(self, centro, misura, pesi, mat, giro_x=0.0):
		vs = []
		for sz in (-1, 1):
			for sy in (-1, 1):
				for sx in (-1, 1):
					p = Vector((sx * misura[0] * 0.5, sy * misura[1] * 0.5,
						sz * misura[2] * 0.5))
					if abs(giro_x) > 1e-6:
						y, z = p.y, p.z
						p.y = y * math.cos(giro_x) - z * math.sin(giro_x)
						p.z = y * math.sin(giro_x) + z * math.cos(giro_x)
					vs.append(self.vert(centro + p, pesi))
		# 0:(-x-y-z) 1:(+x-y-z) 2:(-x+y-z) 3:(+x+y-z)
		# 4:(-x-y+z) 5:(+x-y+z) 6:(-x+y+z) 7:(+x+y+z)
		for quad in ((0, 2, 3, 1), (4, 5, 7, 6), (0, 1, 5, 4),
				(2, 6, 7, 3), (0, 4, 6, 2), (1, 3, 7, 5)):
			self.faccia([vs[i] for i in quad], mat, False)

	# -- chiusura ----------------------------------------------------------
	def chiudi(self):
		for nome, colore, ruvido in MATERIALI:
			self.me.materials.append(bpy.data.materials[nome])
		self.bm.normal_update()
		self.bm.to_mesh(self.me)
		self.bm.free()
		self.me.update()
		self.ob.parent = self.arm
		m = self.ob.modifiers.new("Armature", 'ARMATURE')
		m.object = self.arm
		return self.ob


# ---------------------------------------------------------------------------
# 'O corpo
# ---------------------------------------------------------------------------

def _spalle(p):
	"""Sopra la quota delle spalle il peso passa piano dalla spina alla
	clavicola del lato giusto: senza, la spalla resta incollata al petto e
	quando il braccio si alza si vede il tubo che gira dentro alla maglia."""
	k = _liscio((abs(p.x) - 0.055) / 0.105) * 0.55
	lato = "clavicle_l" if p.x > 0.0 else "clavicle_r"
	return {"spine_03": 1.0 - k, lato: k}


## I pesi del tronco, quota per quota. Un nodo, un dizionario.
def _p_busto(z):
	tavola = [
		(0.800, {"pelvis": 1.0}),
		(0.932, {"pelvis": 0.86, "spine_01": 0.14}),
		(1.051, {"pelvis": 0.28, "spine_01": 0.72}),
		(1.174, {"spine_01": 0.30, "spine_02": 0.70}),
		(1.245, {"spine_02": 0.86, "spine_03": 0.14}),
		(1.315, {"spine_02": 0.34, "spine_03": 0.66}),
		(1.390, {"spine_03": 1.0}),
		(1.441, {"spine_03": 1.0}),
		(1.488, {"spine_03": 0.42, "neck_01": 0.58}),
	]
	migliore = tavola[0][1]
	for zz, pp in tavola:
		if z >= zz - 0.001:
			migliore = pp
	return migliore


def busto(g, corp, quote, mat, gonfio, seg, testa_c="tappo", coda_c="tappo"):
	"""Il tronco (o la camicia che ci sta sopra): stessi anelli, raggi
	diversi. `gonfio` è quanto la stoffa sta staccata dalla pelle.

	**E se chiude 'a sotto e 'a coppa.** Un tubo aperto in Godot si vede
	dentro: da sotto in su la camicia era una campana vuota."""
	nodi = []
	for z, ra, rb in quote:
		f = fattore(z, corp)
		dy = avanti(z, corp)
		pesi = _p_busto(z)
		n = {"p": Vector((0.0, dy, z)), "ra": ra * f + gonfio,
			"rb": rb * f + gonfio, "pesi": pesi}
		if z > 1.36:
			n["pesi_fn"] = _spalle
		nodi.append(n)
	return g.tubo(nodi, mat, seg=seg, testa=testa_c, coda=coda_c)


## **'O busto nun ha da scennere sotto ê cazune.** Alla prima prova la
## pelle arrivava a 0,82 e i pantaloni si fermavano a 0,84: in mezzo alle
## gambe restavano due centimetri di **carne che spuntava dal cavallo**.
QUOTE_BUSTO = [
	(0.890, 0.104, 0.092),
	(0.9321, 0.130, 0.106),
	(1.0505, 0.127, 0.105),
	(1.1736, 0.136, 0.110),
	(1.2450, 0.145, 0.112),
	(1.3148, 0.152, 0.112),
	(1.3900, 0.158, 0.106),
	(1.4408, 0.150, 0.096),
]

## La camicia parte più in basso del petto e finisce al collo: gli anelli
## del busto sotto l'orlo non le servono.
##
## **'O colletto se stregne 'e brutto, e ce vò.** Alla prima prova la
## camicia finiva a un anello largo dodici centimetri e il busto di pelle ne
## teneva undici e mezzo alla stessa quota: la pelle spuntava **fuori dal
## collo della maglia** come un colletto di carne. Adesso la camicia si
## chiude attorno al collo e il busto sotto finisce prima.
QUOTE_CAMICIA = [
	(1.0400, 0.128, 0.106),
	(1.0900, 0.130, 0.107),
	(1.1736, 0.136, 0.110),
	(1.2450, 0.145, 0.112),
	(1.3148, 0.152, 0.112),
	(1.3900, 0.158, 0.107),
	(1.4408, 0.162, 0.108),
	(1.4700, 0.145, 0.098),
	(1.4880, 0.062, 0.058),
]


def _p_braccio(t, lato):
	"""t = quanto si è andati avanti lungo il braccio, da 0 (spalla) a 1
	(polso)."""
	L = lato
	if t <= 0.06:
		return {"spine_03": 0.50, "clavicle_" + L: 0.28, "upperarm_" + L: 0.22}
	if t <= 0.35:
		return {"upperarm_" + L: 1.0}
	if t <= 0.55:
		return {"upperarm_" + L: 0.5, "lowerarm_" + L: 0.5}
	if t <= 0.95:
		return {"lowerarm_" + L: 1.0}
	return {"lowerarm_" + L: 0.55, "hand_" + L: 0.45}


def braccio(g, corp, lato, sx):
	"""Un braccio: cono dalla spalla al polso, **senza bicipite**. Il gomito
	si vede solo perché lì il cono si stringe un po' di più."""
	k = corp.get("braccia", 1.0)
	x0, x1 = X_SPALLA, X_POLSO
	# **'O braccio steva troppo gruosso.** Sette centimetri di raggio alla
	# spalla vogliono dire un braccio di quattordici di diametro: è il
	# braccio del manichino da cui siamo scappati. Sei, e cala liscio fino
	# a tre e otto al polso.
	quote = [
		(0.150, 0.060), (0.300, 0.054), (X_GOMITO, 0.048),
		(0.580, 0.045), (0.680, 0.042), (X_POLSO, 0.038),
	]
	nodi = []
	for x, r in quote:
		t = (x - x0) / (x1 - x0)
		nodi.append({"p": Vector((sx * x, Y_BRACCIO, Z_SPALLA)),
			"ra": r * k, "rb": r * k, "pesi": _p_braccio(t, lato)})
	g.tubo(nodi, "pelle", seg=SEG_ARTO, testa="tappo", coda="tappo")

	# **'A mano è 'na mappina.** Le dita del manichino erano quattromila
	# triangoli che a due metri diventano un pugno chiuso lo stesso. Qui è
	# una manopola schiacciata con il pollice: si legge meglio e costa
	# quaranta triangoli.
	pm = {"hand_" + lato: 1.0}
	mano = [
		(0.7480, 0.042, 0.034), (0.8000, 0.053, 0.032),
		(0.8700, 0.051, 0.029), (0.9080, 0.038, 0.024),
	]
	nodi = [{"p": Vector((sx * x, Y_BRACCIO, Z_SPALLA)), "ra": ra * k,
		"rb": rb * k, "pesi": pm} for x, ra, rb in mano]
	g.tubo(nodi, "pelle", seg=SEG_ARTO, testa="tappo", coda="punta")
	g.sfera(Vector((sx * 0.8050, 0.0180, Z_SPALLA - 0.030)),
		Vector((0.036, 0.020, 0.024)), pm, "pelle", 6, 4)


def gamba(g, corp, lato, sx):
	k = corp.get("gambe", 1.0)
	# Sotto ai pantaloni non si vede niente: la gamba di pelle serve solo a
	# non lasciare il vuoto e a fare la caviglia. Quindi **sempre più
	# stretta della stoffa**, se no spunta.
	quote = [
		(0.930, 0.0000, 0.068), (0.800, 0.0020, 0.070),
		(Z_GINOCCHIO, 0.0050, 0.062), (0.360, 0.0150, 0.060),
		(0.200, 0.0270, 0.052), (0.060, 0.0330, 0.044),
	]
	pesi = [
		{"pelvis": 0.45, "thigh_" + lato: 0.55},
		{"thigh_" + lato: 1.0},
		{"thigh_" + lato: 0.5, "calf_" + lato: 0.5},
		{"calf_" + lato: 1.0},
		{"calf_" + lato: 1.0},
		{"calf_" + lato: 0.62, "foot_" + lato: 0.38},
	]
	nodi = [{"p": Vector((sx * X_GAMBA, y, z)), "ra": r * k, "rb": r * k,
		"pesi": p} for (z, y, r), p in zip(quote, pesi)]
	g.tubo(nodi, "pelle", seg=SEG_ARTO, testa="tappo", coda="tappo")


def scarpa(g, corp, lato, sx):
	"""Lo scarpone: un tubo che corre in avanti, non un cubo. Il tallone è
	alto e tondo, la punta si abbassa e si stringe."""
	pf = {"foot_" + lato: 1.0}
	pb = {"foot_" + lato: 0.35, "ball_" + lato: 0.65}
	# **'A scarpa steva troppo vascia.** Alla prima prova il collo del piede
	# arrivava a nove centimetri e l'orlo dei pantaloni stava a quattordici:
	# in mezzo restavano cinque centimetri di caviglia nuda, e da lontano la
	# scarpa sembrava **staccata dalla gamba**, appoggiata per terra da
	# sola. Adesso la scarpa sale e l'orlo scende: un centimetro e mezzo di
	# calzino, che è quello che si vede addosso a una persona vera.
	#
	# **'A scarpa 'e Pippo.** La prima misurava **quaranta centimetri**,
	# perché `punta` non si ferma all'ultimo anello: ci aggiunge una
	# cupoletta lunga quanto il raggio, e ce n'era una davanti *e* una
	# dietro. Trentuno di catena più nove di cupole. In gioco erano due
	# pinne. Adesso il tallone è **piatto** — che è come finisce una
	# scarpa vera — e la catena è più corta: ventotto centimetri in tutto,
	# un quarantatré.
	quote = [
		(0.0700, 0.046, 0.050, pf), (0.0150, 0.058, 0.052, pf),
		(-0.0750, 0.059, 0.046, pf), (-0.1450, 0.052, 0.034, pb),
		(-0.1750, 0.038, 0.025, pb),
	]
	zc = [0.052, 0.052, 0.046, 0.038, 0.032]
	nodi = [{"p": Vector((sx * X_GAMBA, y, z)), "ra": ra, "rb": rb,
		"pesi": p} for (y, ra, rb, p), z in zip(quote, zc)]
	g.tubo(nodi, "scarpe", seg=SEG_ARTO, testa="tappo", coda="punta")


def pantaloni(g, corp, lato_ok=True):
	"""**'E cazune, geometria vera.** Il bacino è un guscio solo, poi si
	spacca in due tubi che scendono alla caviglia e finiscono con l'orlo.
	I due tubi si sovrappongono al cavallo di tre centimetri, così a gambe
	larghe non si apre il buco.

	**'O pannolino.** Alla prima prova il bacino era un cilindro largo
	trenta centimetri e **profondo ventiquattro**, che finiva di netto al
	cavallo con un disco piatto; le due gambe erano più larghe di lui e
	uscivano di lato con lo spigolo vivo. Da davanti si leggeva per quello
	che era: un pannolone col bordo dritto e due tubi appesi sotto.

	La cura è la stessa che usa un sarto: il fianco è il punto più largo,
	poi **la stoffa si stringe e soprattutto si assottiglia** scendendo
	verso il cavallo, finché è profonda quanto la coscia — e a quel punto
	la coscia continua senza che si veda dove finisce l'una e comincia
	l'altra. Il disco del cavallo resta, ma sta **dentro** alle gambe."""
	quote = [
		(1.0650, 0.140, 0.112, {"spine_01": 0.55, "pelvis": 0.45}),
		(1.0100, 0.152, 0.118, {"pelvis": 0.75, "spine_01": 0.25}),
		(0.9500, 0.166, 0.122, {"pelvis": 1.0}),
		(0.9000, 0.164, 0.113, {"pelvis": 1.0}),
		(0.8400, 0.152, 0.096, {"pelvis": 1.0}),
	]
	# **'A stessa curva d''o busto, se no 'a pelle esce ê ffianche.**
	# Alla prima prova i pantaloni avevano una campana loro (0,98–1,30) e
	# il busto un'altra (0,94–1,27): sul panzone, alla quota della cintura,
	# la pelle cresceva del 25% e la stoffa solo del 13%, e restavano
	# **due millimetri** di margine. Cioè: una striscia di pancia che
	# spuntava fuori dai pantaloni tutt'intorno alla vita.
	#
	# La regola vale per tutto il pupo e va detta una volta:
	# **pelle < pantaloni < camicia**, sempre, a ogni quota, per ogni
	# corporatura. Il modo di garantirla è che tutti e tre crescano con la
	# stessa funzione.
	nodi = []
	for z, ra, rb, p in quote:
		f = fattore(z, corp)
		nodi.append({"p": Vector((0.0, avanti(z, corp), z)), "ra": ra * f,
			"rb": rb * f, "pesi": p})
	g.tubo(nodi, "pantaloni", seg=SEG_BUSTO, testa="tappo", coda="tappo")

	k = corp.get("gambe", 1.0)
	for lato, sx in (("l", 1.0), ("r", -1.0)):
		quote = [
			(0.9500, 0.0000, 0.086, {"pelvis": 0.40, "thigh_" + lato: 0.60}),
			(0.8600, 0.0020, 0.090, {"thigh_" + lato: 0.94, "pelvis": 0.06}),
			(0.7600, 0.0035, 0.089, {"thigh_" + lato: 1.0}),
			(Z_GINOCCHIO, 0.0050, 0.080, {"thigh_" + lato: 0.5,
				"calf_" + lato: 0.5}),
			(0.3600, 0.0150, 0.077, {"calf_" + lato: 1.0}),
			(0.1180, 0.0310, 0.067, {"calf_" + lato: 0.86,
				"foot_" + lato: 0.14}),
		]
		nodi = [{"p": Vector((sx * X_GAMBA, y, z)), "ra": r * k, "rb": r * k,
			"pesi": p} for z, y, r, p in quote]
		g.tubo(nodi, "pantaloni", seg=SEG_ARTO, testa="tappo", coda="orlo")


def maniche(g, corp):
	"""**'E mmaneche.** Un tubo che parte da dentro alla camicia e finisce a
	metà del braccio con l'orlo arrotondato. L'anello di partenza è pesato
	quasi tutto sul petto: sta nascosto dentro alla maglia, e se lo pesassi
	sul braccio uscirebbe fuori ogni volta che il braccio si alza."""
	k = corp.get("braccia", 1.0)
	fs = corp.get("spalle", 1.0)
	for lato, sx in (("l", 1.0), ("r", -1.0)):
		# **'A manica saglieva ncoppa 'a spalla.** Con novantadue millimetri
		# di raggio attorno a un osso che sta a 1,441, il tubo della manica
		# arriva a **1,533** — quattro centimetri e mezzo sopra all'attacco
		# del collo. Ne usciva una gobba sopra ogni spalla, e nel punto in
		# cui bucava la maglietta si apriva una tacca nera che sembrava
		# — di nuovo — uno strappo. Settantadue, e la spalla torna sotto
		# alla linea del collo.
		quote = [
			(0.115, 0.072, {"spine_03": 0.52, "clavicle_" + lato: 0.30,
				"upperarm_" + lato: 0.18}),
			(0.205, 0.072, {"upperarm_" + lato: 0.72,
				"clavicle_" + lato: 0.20, "spine_03": 0.08}),
			(0.300, 0.065, {"upperarm_" + lato: 1.0}),
			(0.335, 0.062, {"upperarm_" + lato: 1.0}),
		]
		nodi = [{"p": Vector((sx * x, Y_BRACCIO, Z_SPALLA)),
			"ra": r * k * (fs if x < 0.22 else 1.0),
			"rb": r * k * (fs if x < 0.22 else 1.0), "pesi": p}
			for x, r, p in quote]
		g.tubo(nodi, "camicia", seg=SEG_ARTO, testa="tappo", coda="orlo")

		# **'A spallina 'e pelle.** Fra il busto della camicia e il tubo
		# della manica restava un buco, e non per sbaglio: il busto è una
		# **ellisse nel piano orizzontale**, quindi vicino alla spalla si
		# assottiglia in profondità fino a sparire, mentre il braccio sta
		# a sei centimetri e mezzo *dietro* all'asse. Nel triangolo fra i
		# due non c'era stoffa, e attraverso quel buco si vedeva il tappo
		# del busto — cioè una **spallina di carne** sopra a ogni spalla,
		# tale e quale a una maglietta strappata sulla cucitura.
		#
		# Una palla di stoffa sul perno della spalla riempie il giunto in
		# tutte le direzioni e non lascia niente da indovinare. È anche la
		# forma giusta: una spalla vestita è tonda.
		g.sfera(Vector((sx * 0.150, Y_BRACCIO - 0.010, Z_SPALLA - 0.009)),
			Vector((0.086 * fs, 0.092, 0.086)),
			{"upperarm_" + lato: 0.50, "clavicle_" + lato: 0.28,
				"spine_03": 0.22}, "camicia", 8, 5)


def collo(g, corp):
	nodi = [
		{"p": Vector((0.0, -0.004, 1.4300)), "ra": 0.058, "rb": 0.055,
			"pesi": {"spine_03": 0.55, "neck_01": 0.45}},
		{"p": Vector((0.0, -0.006, 1.5350)), "ra": 0.052, "rb": 0.050,
			"pesi": {"neck_01": 0.35, "Head": 0.65}},
	]
	g.tubo(nodi, "pelle", seg=SEG_ARTO, testa="tappo", coda="tappo")


def testa(g, corp):
	"""**'A capa e 'a faccia** — e sta 'a parte apposta.

	La testa è un oggetto suo, staccato dal corpo, e non è una scelta di
	comodo: **in prima persona il giocatore la deve poter buttare.**

	Finché il personaggio era una mesh sola, `player_fps.gd` provava a
	nascondere il cranio con `_hide_above()`, che gira l'albero dei nodi e
	spegne i `MeshInstance3D` che stanno sopra a una certa quota. Su un
	corpo fatto di capsule appese ai giunti funzionava. Su una **mesh
	skinnata unica** non nasconde niente: la mesh è un nodo solo, appeso
	allo scheletro alla quota zero, quindi il controllo `y > 1.44` è falso
	e la testa resta accesa. È per questo che al giocatore si vedeva la
	propria testa in mezzo allo schermo.

	Adesso è un oggetto: chi non la vuole se la cancella, come i capelli e
	i baffi. Tutto quello che c'è dentro è già pesato al 100% sull'osso
	`Head`, quindi staccarla non costa niente.

	La faccia non si scolpisce: a due metri una faccia scolpita non si
	legge, due occhi grandi sì. Quindi occhi tondi con la pupilla, naso
	corto, sopracciglia spesse, la riga della bocca, e le orecchie —
	che costano ventiquattro triangoli e cambiano il profilo."""
	ph = {"Head": 1.0}
	g.sfera(TESTA_C, TESTA_R, ph, "pelle", SEG_TESTA, ANELLI_TESTA)

	# 'E ricchie. Otto centimetri e mezzo di orecchio uscivano come due
	# pinne: un orecchio vero ne fa sei.
	for sx in (1.0, -1.0):
		g.sfera(TESTA_C + Vector((sx * 0.108, 0.004, 0.002)),
			Vector((0.014, 0.023, 0.031)), ph, "pelle", 6, 4)

	# 'E llocchie. Stanno dentro alla testa per metà: sporgendo per intero
	# sembravano due biglie appiccicate sopra.
	r_occhio = 0.030
	dx = 0.045
	z_occhio = TESTA_C.z + 0.014
	sup = TESTA_C.y - TESTA_R.y * math.sqrt(max(0.0,
		1.0 - (dx / TESTA_R.x) ** 2 - ((z_occhio - TESTA_C.z) / TESTA_R.z) ** 2))
	y_occhio = sup + r_occhio * 0.55
	for sx in (1.0, -1.0):
		g.sfera(Vector((sx * dx, y_occhio, z_occhio)),
			Vector((r_occhio, r_occhio, r_occhio * 1.06)), ph,
			"occhio_bianco", 8, 5)
		g.sfera(Vector((sx * dx, y_occhio - 0.020, z_occhio)),
			Vector((0.014, 0.014, 0.014)), ph, "occhio_nero", 7, 4)

	# 'O naso: corto e tondo, serve solo a dire da che parte guarda.
	z_naso = TESTA_C.z - 0.018
	y_naso = TESTA_C.y - TESTA_R.y * math.sqrt(max(0.0,
		1.0 - ((z_naso - TESTA_C.z) / TESTA_R.z) ** 2))
	g.sfera(Vector((0.0, y_naso - 0.006, z_naso)),
		Vector((0.020, 0.024, 0.020)), ph, "pelle", 7, 4)

	# 'E ssopracciglia, spesse. Stanno DAVANTI, non attorno alla testa:
	# girando fino alle tempie da tre quarti sembravano orecchie di legno.
	#
	# **E se veéno pure 'a dereto.** Un parallelepipedo largo cinque
	# centimetri e mezzo appoggiato a una testa **tonda** tocca la
	# superficie solo nel mezzo: gli spigoli esterni restano fuori dal
	# cranio, e girando il personaggio spuntavano dal profilo come due
	# schegge. Più stretto, e affondato di un millimetro invece che
	# sollevato.
	z_sopra = z_occhio + 0.042
	y_sopra = TESTA_C.y - TESTA_R.y * math.sqrt(max(0.0,
		1.0 - (dx / TESTA_R.x) ** 2 - ((z_sopra - TESTA_C.z) / TESTA_R.z) ** 2))
	for sx in (1.0, -1.0):
		g.scatola(Vector((sx * dx, y_sopra + 0.002, z_sopra)),
			(0.042, 0.020, 0.014), ph, "tratti",
			giro_x=math.radians(-8.0 * sx))

	# 'A vocca: una riga sola, corta. `y_bocca` si calcola dalla superficie
	# della testa e si sposta di **meno** (cioè più avanti): sommare un
	# numero positivo vorrebbe dire andare dentro al cranio.
	z_bocca = TESTA_C.z - 0.062
	y_bocca = TESTA_C.y - TESTA_R.y * math.sqrt(max(0.0,
		1.0 - ((z_bocca - TESTA_C.z) / TESTA_R.z) ** 2))
	g.scatola(Vector((0.0, y_bocca - 0.002, z_bocca)),
		(0.046, 0.018, 0.012), ph, "tratti")


def capelli(g):
	"""'E capille: calotta con l'attaccatura alta sulla fronte e bassa sulla
	nuca. `a` = 0 è il fianco sinistro, +π/2 è dietro, −π/2 è davanti.

	**Pecché 'a capa asceva a chiazze.** La calotta stava solo il 2,5% più
	larga del cranio: su una testa di dodici centimetri di raggio sono
	**tre millimetri**. Ma fra due spicchi di una calotta a dodici lati la
	corda affonda verso il centro di `r·(1−cos15°)` = **quattro
	millimetri** — cioè più dei tre di margine. Metà dei triangoli finiva
	*dentro* al cranio e ne usciva una testa a macchie, come una pelata a
	chiazze.

	Due cure, tutte e due necessarie: la calotta va più larga (sei per
	cento, sette millimetri) e ha più spicchi (quattordici, corda tre
	millimetri). E l'attaccatura varia meno fra fronte e nuca, che era
	l'altra cosa che faceva ballare gli anelli."""
	def theta(a):
		davanti = -math.sin(a)          # 1 davanti, −1 dietro
		return math.radians(95.0 - 20.0 * davanti)
	g.cupola(TESTA_C + Vector((0.0, 0.006, 0.0)), TESTA_R * 1.060,
		{"Head": 1.0}, "capelli", theta, 14, 5)


def banda_rossa(g):
	"""**'A banda rossa 'ncopp'â coscia.**

	È *la* cosa dei carabinieri: da cinquanta metri non si vede la divisa,
	si vede la riga rossa che scende lungo la gamba.

	Stava dentro a `sbirro_3d.gd` come due parallelepipedi appesi
	all'**osso del torace**, un metro più in basso. Il che vuol dire che
	non seguivano le gambe: il carabiniere camminava e le due righe
	restavano ferme in mezzo alle cosce, come due bastoni. Qui invece è
	geometria pesata sulle ossa delle gambe esattamente come i pantaloni
	che copre, quindi si piega col ginocchio e basta.

	È un oggetto suo, come i capelli e i baffi: chi non è in divisa se lo
	cancella."""
	# **'E raggie so' chille d''a gamba, no chille d''o bacino.**
	#
	# Alla prima prova avevo copiato i raggi dal guscio del bacino (0,13 –
	# 0,15) e li avevo usati attorno all'**asse della gamba**, dove la
	# stoffa sta a 0,09. La banda finiva sei centimetri fuori dai
	# pantaloni: in gioco si vedeva una riga rossa sottile che galleggiava
	# accanto alla coscia, staccata da tutto.
	#
	# Qui i numeri sono quelli veri dei pantaloni (vedi `pantaloni()`) più
	# cinque millimetri, che è quanto sporge una banda cucita sopra.
	for lato, sx in (("l", 1.0), ("r", -1.0)):
		quote = [
			(0.9700, 0.091, {"pelvis": 0.40, "thigh_" + lato: 0.60}),
			(0.8600, 0.095, {"thigh_" + lato: 0.94, "pelvis": 0.06}),
			(0.7600, 0.094, {"thigh_" + lato: 1.0}),
			(Z_GINOCCHIO, 0.085, {"thigh_" + lato: 0.5,
				"calf_" + lato: 0.5}),
			(0.3600, 0.082, {"calf_" + lato: 1.0}),
			(0.1350, 0.072, {"calf_" + lato: 0.86, "foot_" + lato: 0.14}),
		]
		# Uno spicchio di anello largo una sessantina di gradi sul fianco
		# esterno: cinque-sei centimetri di banda, che è la misura vera.
		prec = None
		for z, r, pesi in quote:
			riga = []
			for j in range(5):
				a = math.radians(-30.0 + 15.0 * j) * (1.0 if sx > 0 else -1.0)
				riga.append(g.vert(Vector((sx * X_GAMBA + math.cos(a) * r * sx,
					math.sin(a) * r, z)), pesi))
			if prec is not None:
				for j in range(4):
					if sx > 0:
						g.faccia([prec[j], prec[j + 1], riga[j + 1], riga[j]],
							"banda")
					else:
						g.faccia([riga[j], riga[j + 1], prec[j + 1], prec[j]],
							"banda")
			prec = riga


def baffi(g):
	"""**'E baffe.** Il gioco li chiede da otto versioni — `moustache` sta
	nelle opzioni di mezzo paese — e non li ha mai avuti, perché il corpo
	era uno stampo solo e non si poteva togliere un pezzo. Adesso sono un
	oggetto per conto loro: chi non li vuole se lo cancella."""
	z_naso = TESTA_C.z - 0.018
	z_bocca = TESTA_C.z - 0.062
	z = (z_naso + z_bocca) * 0.5 - 0.006
	y = TESTA_C.y - TESTA_R.y * math.sqrt(max(0.0,
		1.0 - ((z - TESTA_C.z) / TESTA_R.z) ** 2))
	for sx in (1.0, -1.0):
		g.scatola(Vector((sx * 0.017, y - 0.008, z)),
			(0.036, 0.026, 0.016), {"Head": 1.0}, "capelli",
			giro_x=math.radians(-6.0 * sx))


def costruisci(arm, nome, corp):
	g = Pupo(nome, arm)
	busto(g, corp, QUOTE_BUSTO, "pelle", 0.0, SEG_BUSTO)
	collo(g, corp)
	for lato, sx in (("l", 1.0), ("r", -1.0)):
		braccio(g, corp, lato, sx)
		gamba(g, corp, lato, sx)
		scarpa(g, corp, lato, sx)
	busto(g, corp, QUOTE_CAMICIA, "camicia", 0.015, SEG_BUSTO,
		testa_c="orlo")
	maniche(g, corp)
	pantaloni(g, corp)
	ob = g.chiudi()
	return ob


# ---------------------------------------------------------------------------
# Aprire, chiudere
# ---------------------------------------------------------------------------

def _mat(nome, colore, ruvido):
	m = bpy.data.materials.get(nome)
	if m is None:
		m = bpy.data.materials.new(nome)
	m.use_nodes = True
	b = m.node_tree.nodes.get("Principled BSDF")
	if b is not None:
		b.inputs["Base Color"].default_value = (*colore, 1.0)
		if "Roughness" in b.inputs:
			b.inputs["Roughness"].default_value = ruvido
		if "Metallic" in b.inputs:
			b.inputs["Metallic"].default_value = 0.0
	return m


def carica():
	fonte = next((f for f in FONTI if os.path.exists(f)), None)
	if fonte is None:
		raise RuntimeError("UAL1_Standard.glb nun se trova")
	C.pulisci()
	bpy.ops.import_scene.gltf(filepath=fonte)
	arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
	# **'O manichino se jetta.** È tutto quello che serviva sapere: di
	# quel file si tengono le ossa e le quarantatré animazioni, il corpo
	# lo facciamo noi.
	for o in list(bpy.data.objects):
		if o.type == 'MESH':
			bpy.data.objects.remove(o, do_unlink=True)
	return arm


def esporta(corpi):
	for o in bpy.context.scene.objects:
		o.select_set(True)
	bpy.ops.export_scene.gltf(
		filepath=USCITA,
		export_format='GLB',
		use_selection=False,
		export_apply=False,
		export_animations=True,
		export_animation_mode='ACTIONS',
		export_yup=True,
		export_skins=True,
		export_morph=False,
		export_materials='EXPORT',
	)
	tri = sum(sum(max(1, len(p.vertices) - 2) for p in o.data.polygons)
		for o in corpi)
	print("  → %s  %.2f MB · %d corpi · %d triangoli l'uno" % (
		os.path.basename(USCITA), os.path.getsize(USCITA) / 1048576.0,
		len(corpi), tri // max(1, len(corpi))))


def main():
	arm = carica()
	print("  scheletro: %d osse · %d animazioni" % (
		len(arm.data.bones), len(bpy.data.actions)))
	for nome, colore, ruvido in MATERIALI:
		_mat(nome, colore, ruvido)

	# **Capille e baffe stanno 'a parte.** Il gioco chiede da sempre
	# `bald` e `moustache`, e finché tutto stava in una mesh sola l'unico
	# modo di "togliere" i capelli era **tingerli color pelle** — cioè un
	# pelato con una calotta di carne in testa, e le sopracciglia sparite
	# assieme. Due oggetti in più e il gioco li cancella davvero.
	pezzi = []
	for nome, fn in (("testa", lambda gg: testa(gg, {})),
			("capelli", capelli), ("baffi", baffi),
			("banda_rossa", banda_rossa)):
		g = Pupo(nome, arm)
		fn(g)
		pezzi.append(g.chiudi())

	corpi = []
	for nome, corp in CORPORATURE.items():
		ob = costruisci(arm, "corpo_" + nome, corp)
		corpi.append(ob)
		lo = min(v.co.z for v in ob.data.vertices)
		hi = max(v.co.z for v in ob.data.vertices)
		lar = max(abs(v.co.x) for v in ob.data.vertices) * 2.0
		print("    %-10s %5d tri · alto %.3f (%.3f→%.3f) · spalle %.3f" % (
			nome, sum(max(1, len(p.vertices) - 2) for p in ob.data.polygons),
			hi - lo, lo, hi, lar))
	extra = sum(sum(max(1, len(p.vertices) - 2) for p in o.data.polygons)
		for o in pezzi)
	print("    testa+capelli+baffi+banda %d tri" % extra)
	esporta(corpi)


if __name__ == "__main__":
	main()
