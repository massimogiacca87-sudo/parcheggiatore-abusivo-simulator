extends RefCounted
class_name Quartieri
## Quartieri
## Sei pezzi di città che si riconoscono senza bisogno di un cartello.
##
## Il problema che risolve: la prima versione della città aveva quattro
## texture d'intonaco mescolate a caso su tutti e quarantatré gli isolati.
## Il risultato era uniforme — bello, ma uniforme: girato un angolo eri
## nello stesso posto. Un quartiere si riconosce perché *tutto* cambia
## insieme: il colore dell'intonaco, l'altezza dei palazzi, la larghezza
## delle campate, che cosa c'è al piano terra, se ci sono i panni stesi.
##
## Quindi ogni isolato appartiene a un quartiere, e il quartiere decide
## tutto. La regola pratica per aggiungerne uno: cambia almeno tre cose
## insieme, o non si nota.
##
## `rect` è [x0, z0, x1, z1]. Si guarda in ordine e vince il primo che
## contiene il punto; quello che avanza è 'O Centro.

const QUARTIERI := {
	# -----------------------------------------------------------------------
	"quartieri": {
		"nome": "'E Quartiere",
		"rect": [0.0, 0.0, 55.0, 62.0],
		# Intonaco caduto a chiazze, ocra e terracotta. Il posto dove il
		# giocatore comincia: è la Napoli da cartolina storta.
		"muri": ["muro_scrostato", "muro_ocra", "muro_terracotta", "muro_rosa"],
		"tinte": [Color(1, 1, 1), Color(1.04, 0.98, 0.92), Color(0.96, 0.94, 0.98)],
		"h": [12.0, 16.5], "campata": [6.0, 9.0],
		"zoccolo": "piperno", "zoccolo_tinta": Color(0.9, 0.88, 0.86),
		"cornicione": Color(0.60, 0.56, 0.50),
		"pt": ["serranda", "portone", "manifesti"],
		"balcone": 0.70, "stile_balcone": "ferro",
		"marcapiano": false, "tetto": "piatto",
		"panni": true, "strada": "basolato",
		"persiane": Color(0.22, 0.34, 0.24),
	},
	# -----------------------------------------------------------------------
	"sanita": {
		"nome": "'A Sanità",
		"rect": [0.0, 95.0, 55.0, 172.0],
		# Tufo giallo a vista, alto e strettissimo, mezzo sbriciolato.
		"muri": ["muro_tufo", "muro_scrostato", "muro_terracotta"],
		"tinte": [Color(1, 1, 1), Color(0.94, 0.92, 0.88)],
		"h": [13.5, 18.0], "campata": [5.0, 8.0],
		"zoccolo": "piperno", "zoccolo_tinta": Color(0.8, 0.78, 0.76),
		"cornicione": Color(0.52, 0.48, 0.42),
		"pt": ["serranda", "manifesti", "manifesti"],
		"balcone": 0.55, "stile_balcone": "ferro",
		"marcapiano": false, "tetto": "piatto",
		"panni": true, "strada": "basolato",
		"persiane": Color(0.26, 0.30, 0.22),
	},
	# -----------------------------------------------------------------------
	"chiaia": {
		"nome": "'A Riviera",
		"rect": [55.0, 0.0, 107.0, 44.0],
		# Umbertino: grigio-verde, bugnato, palazzi alti e in ordine. Vissuto
		# ma signorile: è la fascia che guarda il golfo.
		"muri": ["muro_umbertino", "muro_crema"],
		"tinte": [Color(1, 1, 1), Color(0.98, 1.0, 0.96)],
		"h": [15.0, 19.0], "campata": [8.0, 11.0],
		"zoccolo": "piperno", "zoccolo_tinta": Color(1.05, 1.05, 1.05),
		"cornicione": Color(0.78, 0.76, 0.70),
		"pt": ["portone", "vetrina", "portone"],
		"balcone": 0.80, "stile_balcone": "pietra",
		"marcapiano": true, "tetto": "piatto",
		"panni": false, "strada": "asfalto",
		"persiane": Color(0.30, 0.32, 0.28),
	},
	# -----------------------------------------------------------------------
	"fuorigrotta": {
		"nome": "'O Rione d''o Stadio",
		"rect": [107.0, 0.0, 190.0, 60.0],
		# Razionalista anni Trenta: travertino, volumi grandi, tutto uguale
		# e tutto allineato. L'ordine è il suo carattere — le altezze quasi
		# non variano, ed è proprio quello che lo fa riconoscere.
		"muri": ["muro_travertino"],
		"tinte": [Color(1, 1, 1), Color(0.99, 0.98, 0.96)],
		"h": [15.0, 16.5], "campata": [9.0, 12.0],
		"zoccolo": "muro_travertino", "zoccolo_tinta": Color(0.82, 0.80, 0.78),
		"cornicione": Color(0.86, 0.84, 0.79),
		"pt": ["portone", "vetrina"],
		"balcone": 0.30, "stile_balcone": "pietra",
		"marcapiano": true, "tetto": "piatto",
		"panni": false, "strada": "asfalto",
		"persiane": Color(0.34, 0.34, 0.32),
	},
	# -----------------------------------------------------------------------
	"petraio": {
		"nome": "'O Petraio",
		"rect": [107.0, 95.0, 156.0, 127.0],
		# La salita. È la fascia che sta SOTTO al terrapieno del Vomero, e
		# fa da cerniera fra la città bassa e la città alta: intonaco
		# povero rappezzato, palazzi che si arrampicano uno sull'altro, e
		# in fondo il muraglione di tufo con la scalinata. Non ha uno stile
		# suo — ha proprio quello di un posto che sta a metà.
		"muri": ["muro_scrostato", "muro_tufo", "muro_ocra"],
		"tinte": [Color(1, 1, 1), Color(1.02, 0.99, 0.94)],
		"h": [11.0, 17.0], "campata": [5.5, 8.5],
		"zoccolo": "piperno", "zoccolo_tinta": Color(0.84, 0.82, 0.80),
		"cornicione": Color(0.58, 0.55, 0.50),
		"pt": ["portone", "serranda", "manifesti"],
		"balcone": 0.62, "stile_balcone": "ferro",
		"marcapiano": false, "tetto": "piatto",
		"panni": true, "strada": "basolato",
		"persiane": Color(0.28, 0.30, 0.24),
	},
	# -----------------------------------------------------------------------
	"vomero": {
		"nome": "'O Vommero",
		# **Il quartiere alto.** Adesso il rettangolo coincide con il
		# terrapieno e con le quattro strade che lo delimitano: si entra nel
		# Vomero salendo una scalinata, e da lassù si vedono i tetti di
		# tutto il resto. Prima era un quartiere come gli altri, in piano,
		# e l'unica cosa che lo distingueva erano i bow-window.
		"rect": [107.0, 127.0, 156.0, 172.0],
		# Liberty: intonaco liscio chiaro, ferro battuto, bow-window, tetti a
		# falda di cotto. Qui i muri li rifanno: niente crepe, niente
		# manifesti, niente panni stesi. Un parcheggiatore abusivo qua sopra
		# si vede da un chilometro, ed è esattamente il punto.
		"muri": ["muro_liberty", "muro_liberty_verde"],
		"tinte": [Color(1, 1, 1), Color(1.0, 0.99, 0.96), Color(0.97, 1.0, 0.99)],
		"h": [14.0, 18.0], "campata": [8.0, 11.0],
		"zoccolo": "muro_travertino", "zoccolo_tinta": Color(1.0, 0.99, 0.96),
		"cornicione": Color(0.92, 0.90, 0.86),
		"pt": ["portone", "vetrina", "vetrina"],
		"balcone": 0.85, "stile_balcone": "bow",
		"marcapiano": true, "tetto": "falda",
		"panni": false, "strada": "basolato_chiaro",
		"persiane": Color(0.42, 0.36, 0.28),
	},
	# -----------------------------------------------------------------------
	"centro_antico": {
		"nome": "'O Centro Antico",
		"rect": [0.0, 62.0, 55.0, 95.0],
		# Il tufo annerito da secoli di fuliggine, rappezzato dieci volte con
		# pietre diverse. È il quartiere più stretto e più alto di tutti: qui
		# il cielo è una striscia.
		"muri": ["muro_centro_antico", "muro_tufo", "muro_scrostato"],
		"tinte": [Color(1, 1, 1), Color(0.95, 0.94, 0.92)],
		"h": [15.0, 19.0], "campata": [5.0, 7.5],
		"zoccolo": "piperno", "zoccolo_tinta": Color(0.78, 0.76, 0.75),
		"cornicione": Color(0.46, 0.43, 0.39),
		"pt": ["portone", "manifesti", "serranda"],
		"balcone": 0.50, "stile_balcone": "ferro",
		"marcapiano": false, "tetto": "piatto",
		"panni": true, "strada": "basolato",
		"persiane": Color(0.20, 0.26, 0.20),
	},
	# -----------------------------------------------------------------------
	"porto": {
		"nome": "'O Puorto",
		"rect": [55.0, 95.0, 107.0, 172.0],
		# Capannoni e lamiera arrugginita. Bassi e larghi: è l'unico posto
		# della città dove si vede il cielo camminando, e serve proprio a
		# spezzare il canyon dei vicoli.
		"muri": ["muro_porto"],
		"tinte": [Color(1, 1, 1), Color(0.94, 0.96, 0.98), Color(1.02, 0.98, 0.94)],
		"h": [8.0, 11.0], "campata": [10.0, 14.0],
		"zoccolo": "piperno", "zoccolo_tinta": Color(0.7, 0.7, 0.72),
		"cornicione": Color(0.44, 0.46, 0.48),
		"pt": ["serranda", "serranda", "portone"],
		"balcone": 0.05, "stile_balcone": "ferro",
		"marcapiano": false, "tetto": "piatto",
		"panni": false, "strada": "asfalto",
		"persiane": Color(0.30, 0.34, 0.36),
	},
	# -----------------------------------------------------------------------
	"zona_nuova": {
		"nome": "'A Zona Nova",
		"rect": [107.0, 60.0, 190.0, 95.0],
		# Palazzoni anni Settanta: piastrelline marroni che cadono a placche,
		# cemento sotto, colature nere sotto ogni marcapiano. Alti e larghi,
		# tutti uguali.
		"muri": ["muro_zona_nuova"],
		"tinte": [Color(1, 1, 1), Color(0.96, 0.95, 0.93), Color(1.0, 0.97, 0.92)],
		"h": [17.0, 21.0], "campata": [10.0, 13.0],
		"zoccolo": "muro_zona_nuova", "zoccolo_tinta": Color(0.72, 0.70, 0.68),
		"cornicione": Color(0.58, 0.56, 0.54),
		"pt": ["serranda", "portone", "vetrina"],
		"balcone": 0.90, "stile_balcone": "cemento",
		"marcapiano": true, "tetto": "piatto",
		"panni": true, "strada": "asfalto",
		"persiane": Color(0.44, 0.40, 0.34),
	},
	# -----------------------------------------------------------------------
	"posillipo": {
		"nome": "Pusilleco",
		"rect": [155.0, 95.0, 190.0, 172.0],
		# Ville basse e muri di cinta bianchi. Il quartiere più basso e più
		# rado: dopo il Vomero è un altro salto, e si vede subito perché il
		# cielo si riapre.
		"muri": ["muro_posillipo"],
		"tinte": [Color(1, 1, 1), Color(1.0, 0.99, 0.97)],
		"h": [7.5, 11.0], "campata": [9.0, 13.0],
		"zoccolo": "piperno", "zoccolo_tinta": Color(0.9, 0.89, 0.88),
		"cornicione": Color(0.94, 0.92, 0.88),
		"pt": ["portone", "portone", "vetrina"],
		"balcone": 0.55, "stile_balcone": "pietra",
		"marcapiano": false, "tetto": "falda",
		"panni": false, "strada": "basolato_chiaro",
		"persiane": Color(0.30, 0.40, 0.34),
	},
	# -----------------------------------------------------------------------
	"centro": {
		"nome": "'O Centro",
		"rect": [],  # quello che avanza
		"muri": ["muro_crema", "muro_ocra", "muro_umbertino", "muro_rosa"],
		"tinte": [Color(1, 1, 1), Color(0.97, 0.96, 0.94)],
		"h": [13.0, 17.0], "campata": [7.0, 10.0],
		"zoccolo": "piperno", "zoccolo_tinta": Color(0.95, 0.93, 0.92),
		"cornicione": Color(0.66, 0.63, 0.57),
		"pt": ["serranda", "portone", "vetrina", "manifesti"],
		"balcone": 0.62, "stile_balcone": "ferro",
		"marcapiano": true, "tetto": "piatto",
		"panni": true, "strada": "basolato",
		"persiane": Color(0.24, 0.32, 0.26),
	},
}

## L'ordine in cui si guarda. 'O Centro non c'è: è il ripiego.
const ORDINE := ["quartieri", "centro_antico", "sanita", "chiaia", "porto",
	"fuorigrotta", "zona_nuova", "petraio", "vomero", "posillipo"]


## In che quartiere cade un punto.
static func id_di(x: float, z: float) -> String:
	for k in ORDINE:
		var r: Array = QUARTIERI[k]["rect"]
		if x >= r[0] and x < r[2] and z >= r[1] and z < r[3]:
			return k
	return "centro"


static func di(x: float, z: float) -> Dictionary:
	return QUARTIERI[id_di(x, z)]


static func per_id(id: String) -> Dictionary:
	return QUARTIERI.get(id, QUARTIERI["centro"])


## Il nome da mostrare a schermo quando ci si entra.
static func nome_di(x: float, z: float) -> String:
	return str(di(x, z)["nome"])
