extends RefCounted
## RobbaPanda — 'e pezze 'e Pandazole ca servono a cchiù 'e 'nu posto (0.59)
##
## La cassetta di frutta piena sta sui banchi del mercato di tutti i giorni
## (`citta_3d.gd`), davanti al fruttivendolo e sulle bancarelle in più del
## giorno di mercato (`jurnata_vista.gd`). Scritta una volta sola: la
## seconda volta che una cosa si scrive a mano, prima o poi le due copie
## non si somigliano più.

## Il colore del **letto** di una cassetta di frutta: la media dell'atlante
## sotto a quel frutto, pesata sull'area (misurata con
## `tools/sonda_tinte_panda.gd` sull'atlante già stemperato da
## `tools/tinge_pandazole.py`: se si cambia l'atlante, si rimisura). Una cassetta vera ha cinquanta arance, e
## cinquanta modelli per cassetta non si possono spendere: sotto ai sei o
## sette frutti veri ci sta una lastra dello stesso colore, e da due metri
## la cassetta sembra piena.
const TINTA_FRUTTA := {
	"mela": Color(0.65, 0.16, 0.16), "arancia": Color(0.95, 0.56, 0.23),
	"limone": Color(0.95, 0.73, 0.25), "pummarola": Color(0.95, 0.23, 0.23),
	"peperone": Color(0.31, 0.53, 0.25), "mulignana": Color(0.16, 0.10, 0.16),
	"uva": Color(0.24, 0.22, 0.33), "banana": Color(0.89, 0.69, 0.24),
	"patana": Color(0.69, 0.51, 0.34), "cepolla": Color(0.95, 0.79, 0.54),
	"aglio": Color(0.83, 0.85, 0.82), "peperoncino": Color(0.77, 0.28, 0.22),
	"carota": Color(0.80, 0.53, 0.23), "friariello": Color(0.23, 0.39, 0.19),
	"pera": Color(0.76, 0.69, 0.36), "mandarino": Color(0.95, 0.56, 0.23),
	"cetriolo": Color(0.23, 0.39, 0.13), "ravanello": Color(0.68, 0.33, 0.23),
	"pane": Color(0.91, 0.54, 0.35),
}
## Quanto sono alte dentro le quattro cassette di legno (il letto sta un dito
## sotto al bordo).
const CASSETTA_ALTA := {"cascetta_1": 0.43, "cascetta_2": 0.30,
	"cascetta_3": 0.19, "cascetta_4": 0.20}


## **'Na cascetta chiena**, come lista di pezzi da mettere: la cassetta
## vera, il letto colorato un dito sotto al bordo (un cubo unitario da
## scalare, `"letto": colore`) e sopra cinque-otto frutti veri a mucchio.
## `pos` è il centro della base, `giro` il verso della cassetta.
##
## Il letto si scala **nel verso della cassetta** (`Basis * from_scale`), non
## in quello del mondo: la prima stesura faceva `Basis(...).scaled(...)`,
## che scala sugli assi del mondo, e sui banchi del mercato — dove le
## cassette stanno girate di novanta gradi — il letto veniva di traverso,
## largo mezzo metro fuori dai bordi.
static func cascetta_chiena(frutto: String, pos: Vector3, giro: float,
		rng: RandomNumberGenerator, tinta_letto: Color = Color(0, 0, 0, 0)) -> Array:
	var fuori: Array = []
	var cass: String = ["cascetta_1", "cascetta_2", "cascetta_3",
		"cascetta_4"][rng.randi() % 4]
	var giro_b := Basis(Vector3.UP, giro)
	fuori.append({"nome": cass, "t": Transform3D(giro_b, pos)})
	var alto: float = float(CASSETTA_ALTA[cass])
	var tinta: Color = TINTA_FRUTTA.get(frutto, Color(0.5, 0.4, 0.3))
	var quanti_min: int = 5
	if tinta_letto.a > 0.0:
		tinta = tinta_letto
		quanti_min = 3
	fuori.append({"letto": tinta, "t": Transform3D(
		giro_b * Basis.from_scale(Vector3(0.52, 0.04, 0.31)),
		pos + Vector3(0, alto - 0.05, 0))})
	var lungo := Vector3(cos(giro), 0.0, -sin(giro))
	var largo := Vector3(sin(giro), 0.0, cos(giro))
	for _k in range(rng.randi_range(quanti_min, quanti_min + 3)):
		var p: Vector3 = pos + lungo * rng.randf_range(-0.19, 0.19) \
			+ largo * rng.randf_range(-0.1, 0.1) + Vector3(0, alto - 0.03, 0)
		fuori.append({"nome": frutto, "t": Transform3D(
			Basis(Vector3.UP, rng.randf_range(-PI, PI)), p)})
	return fuori
