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

    python3 tools/build_personaggi.py [uscita.glb]

**Dalla 0.66 'o pupo se fa a tre mane.** Questo file è il regista: tiene
la cassetta degli attrezzi (`Pupo`: tubi, sfere, cupole, pesi), i
materiali, le corporature, le UV e l'esportazione. La testa con tutti i
suoi pezzi (capelli, palpebre, sopracciglia, nasi, baffi) sta in
`pupo_testa.py`, il corpo coi vestiti in `pupo_corpo.py`. Se uno dei due
manca si usa il pupo della 0.49 che sta qui sotto.

**E nun esce cchiù `pupo.glb`.** Il file sorgente dello scheletro
(`UAL1_Standard.glb`) sta solo sul computer del capo; lo scheletro si
ricava da `pupo.scn` con `tools/esporta_scheletro.gd`, e il corpo che esce
da qui (`_claude_tmp/grafica/pupo/pupo_nuovo.glb`, **senza animazioni**) si
rimonta sulle quarantatré clip vecchie con `tools/monta_pupo.gd`, che
scrive `assets/models/pupo.scn`.
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
LAVORO = os.path.normpath(os.path.join(RADICE, "..", "..", "_claude_tmp",
	"grafica", "pupo"))
USCITA = os.path.join(LAVORO, "pupo_nuovo.glb")

FONTI = [
	os.path.join(LAVORO, "pupo_scheletro.glb"),
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
	# (0.66) La pelle della faccia: ha le UV della faccia, e in gioco ci
	# disegna sopra bocca, barba e rughe lo shader `pupo_faccia`.
	("faccia", (0.87, 0.69, 0.55), 0.72),
	# L'iride (con la pupilla dipinta): il colore lo mette il gioco.
	("iride", (0.22, 0.14, 0.08), 0.30),
	("gonna", (0.24, 0.26, 0.32), 0.92),
	# Questi il gioco non li tinge: restano del colore del file.
	("suola", (0.52, 0.48, 0.44), 0.80),
	("cuoio", (0.20, 0.12, 0.08), 0.60),
	("metallo", (0.72, 0.72, 0.74), 0.35),
	("oro", (0.86, 0.66, 0.24), 0.30),
	("corallo", (0.80, 0.08, 0.07), 0.40),
	("bottoni", (0.90, 0.88, 0.82), 0.45),
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
# 'E UV, materiale per materiale (0.66)
# ---------------------------------------------------------------------------
#
# Il pupo della 0.49 non aveva UV: era tutto a colore pieno. Adesso tre
# cose portano una texture, e le coordinate le mette qui il regista, dopo,
# guardando il materiale di ogni faccia — così chi modella non ci deve
# pensare, e le texture si possono disegnare prima ancora del modello.
# **Questo è il contratto con chi fa le texture: non si cambia senza
# cambiare anche loro.**
#
# * `faccia` — proiezione piatta da davanti. Una finestra di FACCIA_L
#   metri centrata sul centro della testa: u = 0,5 + x/L (x positivo è la
#   **sinistra del pupo**, cioè la destra di chi lo guarda), v = 0,5 −
#   (z − TESTA_C.z)/L. Le facce che non guardano avanti (normale·(−Y) <
#   0,15) vanno tutte nell'angolo neutro (0,015, 0,015), che nelle texture
#   è sempre bianco (o nero, per la barba): così la bocca non si stampa
#   anche sulla nuca.
# * `camicia`, `pantaloni`, `gonna` — la trama della stoffa, che si ripete:
#   proiezione a scatola, un'unità di UV = TRAMA_M metri.
# * `capelli` — le ciocche: coordinate sferiche attorno al centro della
#   testa, u lungo il giro e v dalla cima in giù, in metri/TRAMA_M. Le
#   righe della texture (che corrono lungo v) diventano capelli pettinati
#   dalla fronte alla nuca.
# * `iride` — proiezione piatta da davanti sull'occhio più vicino: il
#   disco dell'iride (raggio IRIDE_R) riempie il quadrato [0,1]², con la
#   pupilla al centro.
FACCIA_L = 0.26
TRAMA_M = 0.25
OCCHIO_X = 0.043           # dove stanno gli occhi: ±x…
OCCHIO_Z_SU = 0.012        # …e quanto sopra al centro della testa
IRIDE_R = 0.0125


def uv_per_materiale(bm):
	uv = bm.loops.layers.uv.verify()
	per_nome = {i: n for i, (n, _, _) in enumerate(MATERIALI)}
	c = TESTA_C
	for f in bm.faces:
		nome = per_nome.get(f.material_index, "")
		if nome == "faccia":
			davanti = -f.normal.y
			for l in f.loops:
				p = l.vert.co
				if davanti < 0.15:
					l[uv].uv = (0.015, 0.015)
				else:
					l[uv].uv = (0.5 + p.x / FACCIA_L,
						0.5 - (p.z - c.z) / FACCIA_L)
		elif nome in ("camicia", "pantaloni", "gonna"):
			n = f.normal
			ax = max(range(3), key=lambda i: abs(n[i]))
			for l in f.loops:
				p = l.vert.co
				if ax == 0:
					a, b = p.y, p.z
				elif ax == 1:
					a, b = p.x, p.z
				else:
					a, b = p.x, p.y
				l[uv].uv = (a / TRAMA_M, -b / TRAMA_M)
		elif nome == "capelli":
			for l in f.loops:
				d = l.vert.co - c
				r = max(0.05, d.length)
				giro = math.atan2(d.x, -d.y)
				polo = math.acos(max(-1.0, min(1.0, d.z / r)))
				l[uv].uv = (giro * 0.12 / TRAMA_M, polo * 0.12 / TRAMA_M)
		elif nome == "iride":
			for l in f.loops:
				p = l.vert.co
				ox = OCCHIO_X if p.x > 0.0 else -OCCHIO_X
				oz = c.z + OCCHIO_Z_SU
				l[uv].uv = (0.5 + (p.x - ox) / (2.0 * IRIDE_R),
					0.5 - (p.z - oz) / (2.0 * IRIDE_R))
		else:
			for l in f.loops:
				l[uv].uv = (0.5, 0.5)


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
		# (0.66) Le forme (blend shape): nome → {BMVert: posizione}.
		self.forme = {}

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

	# -- forme -------------------------------------------------------------
	def forma(self, nome, spostati):
		"""**'E forme** (0.66): una blend shape. `spostati` = {BMVert:
		Vector} con la posizione dei vertici che si muovono; gli altri
		restano dove sono. Le palpebre ne hanno una, `chiudi`, e il gioco
		la usa per sbattere gli occhi."""
		self.forme.setdefault(nome, {}).update(spostati)

	# -- chiusura ----------------------------------------------------------
	def chiudi(self):
		for nome, colore, ruvido in MATERIALI:
			self.me.materials.append(bpy.data.materials[nome])
		self.bm.normal_update()
		uv_per_materiale(self.bm)
		self.bm.verts.index_update()
		forme = {n: {v.index: co.copy() for v, co in d.items()}
			for n, d in self.forme.items()}
		self.bm.to_mesh(self.me)
		self.bm.free()
		self.me.update()
		if forme:
			self.ob.shape_key_add(name="Basis", from_mix=False)
			for n, d in forme.items():
				k = self.ob.shape_key_add(name=n, from_mix=False)
				for i, co in d.items():
					k.data[i].co = co
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
		export_morph=True,
		export_morph_normal=False,
		export_materials='EXPORT',
	)
	tri = sum(sum(max(1, len(p.vertices) - 2) for p in o.data.polygons)
		for o in corpi)
	print("  → %s  %.2f MB · %d corpi · %d triangoli l'uno" % (
		os.path.basename(USCITA), os.path.getsize(USCITA) / 1048576.0,
		len(corpi), tri // max(1, len(corpi))))


def _tri(o):
	return sum(max(1, len(p.vertices) - 2) for p in o.data.polygons)


def main():
	global USCITA
	argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
	if argv:
		USCITA = os.path.abspath(argv[0])
	os.makedirs(os.path.dirname(USCITA), exist_ok=True)
	arm = carica()
	print("  scheletro: %d osse · %d animazioni" % (
		len(arm.data.bones), len(bpy.data.actions)))
	for nome, colore, ruvido in MATERIALI:
		_mat(nome, colore, ruvido)

	# **'A capa e 'o cuorpo, ognuno 'a casa soja** (0.66). Se i due moduli
	# ci sono, i pezzi li fanno loro; se no, il pupo della 0.49. Con
	# `PUPO_VECCHIO=testa` (o `corpo`) nell'ambiente uno dei due si salta:
	# serve a provare un modulo mentre l'altro è ancora in cantiere.
	vecchi = os.environ.get("PUPO_VECCHIO", "").split(",")
	T = K = None
	if "testa" not in vecchi:
		try:
			import pupo_testa as T
		except ImportError:
			T = None
	if "corpo" not in vecchi:
		try:
			import pupo_corpo as K
		except ImportError:
			K = None

	# **Capille e baffe stanno 'a parte.** Il gioco chiede da sempre
	# `bald` e `moustache`, e finché tutto stava in una mesh sola l'unico
	# modo di "togliere" i capelli era **tingerli color pelle** — cioè un
	# pelato con una calotta di carne in testa, e le sopracciglia sparite
	# assieme. Due oggetti in più e il gioco li cancella davvero.
	if T is not None:
		fatti_testa = T.pezzi()
	else:
		fatti_testa = [("testa", lambda gg: testa(gg, {})),
			("capelli", capelli), ("baffi", baffi)]
	if K is not None:
		fatti_soli = K.pezzi()
	else:
		fatti_soli = [("banda_rossa", banda_rossa)]
	pezzi = []
	for nome, fn in list(fatti_testa) + list(fatti_soli):
		g = Pupo(nome, arm)
		fn(g)
		pezzi.append(g.chiudi())

	corporature = getattr(K, "CORPORATURE", CORPORATURE) if K else CORPORATURE
	corpi = []
	for nome, corp in corporature.items():
		if K is not None:
			g = Pupo("corpo_" + nome, arm)
			K.corpo(g, corp)
			ob = g.chiudi()
			for famiglia, fn in K.extra():
				gx = Pupo("%s_%s" % (famiglia, nome), arm)
				fn(gx, corp)
				pezzi.append(gx.chiudi())
		else:
			ob = costruisci(arm, "corpo_" + nome, corp)
		corpi.append(ob)
		lo = min(v.co.z for v in ob.data.vertices)
		hi = max(v.co.z for v in ob.data.vertices)
		lar = max(abs(v.co.x) for v in ob.data.vertices) * 2.0
		print("    %-10s %5d tri · alto %.3f (%.3f→%.3f) · spalle %.3f" % (
			nome, _tri(ob), hi - lo, lo, hi, lar))
	for o in sorted(pezzi, key=lambda o: o.name):
		print("    %-26s %5d tri" % (o.name, _tri(o)))
	esporta(corpi)


if __name__ == "__main__":
	main()
