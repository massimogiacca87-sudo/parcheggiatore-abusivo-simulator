extends Node
## **'E mesure d''o pacchetto PSX** (0.58)
##
## Il capo ha dato un pacchetto da quattrocento megabyte di modelli PSX e ha
## chiesto di usarne cinquanta-cento per arricchire il gioco. Ne sono entrati
## **centoventuno**, e questa prova esiste per una ragione sola: in questo
## progetto **le misure non si indovinano**.
##
## Costa poco dirlo e tanto impararlo. La 0.54 ha perso una giornata su tre
## difetti delle ossa nati tutti dall'aver dato per scontato dove puntasse un
## asse; la 0.57 ha montato il lampione con la luce appesa a mezz'aria finché
## `prova_asset` non ne ha stampato l'ingombro vero. Un modello preso da un
## pacchetto esterno è **peggio**: non l'ho fatto io, non so in che unità sta,
## e "coltello" può uscire lungo un metro e mezzo.
##
## Quindi qui si carica ogni modello nuovo, se ne misura l'ingombro, e lo si
## confronta con **quanto dovrebbe essere grande quella cosa nella vita
## vera**. Chi sfora si becca uno STORTO col fattore di scala da applicare.

const Models := preload("res://scripts/models.gd")

var storte: int = 0


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


## Quanto è grande davvero, in metri: [minimo, massimo] dell'ingombro più
## lungo. Sono misure di buonsenso, non di precisione: servono a beccare il
## coltello da un metro e il bidone da otto centimetri.
const ATTESO := {
	# --- 'e ffierre: se teneno 'n mano ---
	"curtiello": [0.18, 0.42], "curtiello_piccolo": [0.14, 0.34],
	"manganello": [0.40, 0.80], "fierro": [0.14, 0.32],
	"caricatore": [0.06, 0.20], "silenziatore": [0.10, 0.26],
	"cartucce": [0.04, 0.22], "cascia_munizioni": [0.10, 0.45],
	"sega": [0.30, 0.70], "sciabola": [0.60, 1.20],
	"grimaldello": [0.14, 0.36], "cacciavite": [0.14, 0.36],
	# --- robba 'e sacca ---
	"pacchetto_sigarette": [0.05, 0.14], "sigaretta": [0.05, 0.12],
	"cicca": [0.02, 0.10], "cicca2": [0.02, 0.10],
	"accendino": [0.04, 0.12], "fiammifere": [0.03, 0.12],
	"mazzetta": [0.08, 0.22], "mazzetta2": [0.08, 0.22],
	"mazzetta3": [0.08, 0.22], "spicciulo": [0.01, 0.05],
	"chiave": [0.03, 0.12], "chiave2": [0.03, 0.12], "chiave3": [0.03, 0.12],
	"tessera": [0.05, 0.12], "ricetrasmittente": [0.10, 0.40],
	"ricetrasmittente2": [0.10, 0.40], "telefonino": [0.08, 0.20],
	"telefonino_viecchio": [0.08, 0.22], "torcia": [0.10, 0.40],
	"bottiglia_vetro": [0.15, 0.40], "bottiglia_vetro2": [0.15, 0.40],
	"documento": [0.05, 0.14], "musicassetta": [0.06, 0.14],
	"cidi": [0.08, 0.16], "medicine": [0.05, 0.16], "benda": [0.04, 0.16],
	"scatoletta": [0.05, 0.16], "scatoletta2": [0.05, 0.16],
	"scatoletta_arrugginita": [0.05, 0.16], "carne": [0.10, 0.40],
	"chiuove": [0.02, 0.30], "lecca_lecca": [0.06, 0.18],
	"svapo": [0.06, 0.18],
	# --- robba 'e tavulo e 'e casa ---
	"posacenere": [0.08, 0.26], "blocchetto_multe": [0.10, 0.32],
	"libro_apierto": [0.15, 0.45], "libro": [0.12, 0.34],
	"libro2": [0.12, 0.34], "libro3": [0.12, 0.34],
	"penna": [0.08, 0.20], "matita": [0.08, 0.24],
	"piatto": [0.14, 0.34], "furchetta": [0.10, 0.28],
	"cucchiaro": [0.10, 0.28], "telecomando": [0.10, 0.28],
	"videocassetta": [0.12, 0.26],
	"spugna": [0.06, 0.22],
	"giocattolo": [0.02, 0.14], "cornice": [0.10, 0.36],
	"quadro": [0.20, 1.20], "orologio_muro": [0.15, 0.60],
	"sveglia": [0.08, 0.30], "croce": [0.10, 0.70], "croce2": [0.10, 0.70],
	"lisca": [0.08, 0.55], "batteria_auto": [0.15, 0.40],
	"lattina": [0.06, 0.20], "monitor": [0.25, 0.65],
	"televisore": [0.35, 1.20],
	# --- robba 'e strada ---
	"bidone": [0.70, 1.30], "bidone2": [0.70, 1.30],
	"bidone3": [0.70, 1.30], "bidone4": [0.70, 1.30],
	"cascia_legno": [0.30, 1.30], "cascia_legno2": [0.30, 1.30],
	"cascia_legno3": [0.30, 1.30], "cascia_legno4": [0.30, 1.30],
	"cascia_legno5": [0.30, 1.30], "cascia_legno6": [0.20, 1.30],
	"scatolone": [0.25, 0.90], "scatolone2": [0.25, 0.90],
	"cascia_grossa": [0.50, 1.60], "cascia_grossa_vacante": [0.50, 1.60],
	"cascia_grossa2": [0.50, 1.60],
	"tubo": [0.80, 5.00], "tubo_angolo": [0.30, 3.00],
	"tubo_croce": [0.30, 3.00], "tubo_curto": [0.30, 2.20],
	"valvola": [0.20, 1.20], "tanica": [0.25, 0.70],
	"mattone": [0.15, 0.35], "mattone2": [0.15, 0.35],
	"blocco_cemento": [0.25, 0.70], "water": [0.40, 1.10],
	"distributore": [1.20, 2.30],
	"vaso_vacante": [0.15, 0.60], "vaso_chino": [0.15, 0.80],
	"cactus": [0.20, 0.90], "tappeto": [0.80, 3.50],
	"bastone_tenne": [0.80, 3.20],
	"griglia": [0.15, 0.85], "griglia2": [0.15, 0.85],
	"griglia3": [0.15, 0.85], "presa": [0.05, 0.25],
	"interruttore": [0.05, 0.25],
	"lucchetto": [0.04, 0.16], "lucchetto2": [0.04, 0.16],
	"lucchetto3": [0.04, 0.16], "lucchetto4": [0.04, 0.16],
	"ventilatore": [0.60, 1.60], "lampadario": [0.15, 1.30],
	"lampadario_stutato": [0.15, 1.30],
	"abbajour": [0.15, 1.30], "abbajour_stutato": [0.15, 1.30],
	# --- 'a robba d''a 0.60: galera, facciate, segge, ingombrante ---
	"sbarre_fenestra": [0.9, 1.9], "cancello_ferro": [1.8, 3.2],
	"porta_ferro": [1.9, 2.4], "lampada_muro": [0.2, 0.5],
	"griglia_bassa": [0.2, 0.6], "vasetto": [0.2, 0.45],
	"vasetto_vacante": [0.2, 0.45], "volantino_acqua": [0.15, 0.45],
	"seggia_paglia": [0.8, 1.15], "seggia_legno": [0.8, 1.15],
	"seggia_vecchia": [0.8, 1.15], "sgabello": [0.4, 0.8],
	"tavulinetto": [0.4, 0.8], "materasso": [1.7, 2.2],
	"materasso_macchiato": [1.7, 2.2], "divano_vecchio": [1.6, 2.4],
	"divano_vecchio2": [1.6, 2.4], "poltrona_vecchia": [0.8, 1.2],
	"armadio_vecchio": [1.6, 2.3], "tv_vecchia": [0.4, 0.9],
	"comodino_vecchio": [0.4, 0.8], "bagno_chimico": [2.0, 2.7],
	"mattone_rosso": [0.18, 0.32], "mattone_grigio": [0.18, 0.32],
	"tanica_blu": [0.3, 0.7], "scatolone3": [0.4, 0.9],
	"cascia_scura": [0.4, 0.9], "barattolo": [0.1, 0.35],
	"cascia_birre": [0.4, 0.8], "cascia_birre2": [0.4, 0.8],
	"orologio_bar": [0.25, 0.6], "cicca_terra": [0.03, 0.12],
	"cicca_terra2": [0.03, 0.12], "banconota": [0.10, 0.18],
	"mazzetto": [0.05, 0.18], "soldi_piegati": [0.10, 0.18],
	"moneta": [0.015, 0.035], "computer": [0.35, 0.7],
	"cassa_stereo": [0.15, 0.35], "lampada_neon": [0.6, 1.5],
	"ragnatela": [0.5, 1.6],
	"ragnatela2": [0.5, 1.6], "banco_libri": [1.2, 2.0],
	"libro_a": [0.15, 0.30], "libro_b": [0.15, 0.30], "libro_c": [0.15, 0.30],
	"libro_d": [0.15, 0.30], "libro_e": [0.15, 0.30], "libro_f": [0.15, 0.30],
	"presa_muro": [0.05, 0.2], "interruttore2": [0.05, 0.2],
	"cornice_cane": [0.15, 0.4], "giochetto": [0.10, 0.30],
	"quaderno": [0.15, 0.35], "cuscino": [0.4, 0.9],
	"mutanne": [0.25, 0.6],
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame

	print("=== 'E MESURE D''E MODELLE PSX ===")
	print("  %-24s %-22s %-9s %s"
		% ["nomme", "ngombro (x × y × z)", "'o cchiù", "che ce vò"])
	var quante: int = 0
	var fore: Array = []
	var chiavi: Array = ATTESO.keys()
	chiavi.sort()
	for nome in chiavi:
		var n := Models.spawn(str(nome))
		if n == null:
			male("%s: nun se carreca" % nome)
			continue
		add_child(n)
		var a: AABB = _ngombro(n)
		var lungo: float = maxf(a.size.x, maxf(a.size.y, a.size.z))
		var lim: Array = ATTESO[nome]
		var ok: bool = lungo >= float(lim[0]) and lungo <= float(lim[1])
		quante += 1
		if not ok:
			fore.append([str(nome), lungo, float(lim[0]), float(lim[1])])
		print("  %-24s %-22s %6.3f m  %s"
			% [nome, "%.2f × %.2f × %.2f" % [a.size.x, a.size.y, a.size.z],
				lungo,
				"ok" if ok else ">>> FORE (ce vò %.2f-%.2f)" % [
					float(lim[0]), float(lim[1])]])
		n.queue_free()

	print("=== %d modelle mesurate ===" % quante)
	if not fore.is_empty():
		print("=== CHI STA FORE MESURA, E 'O FATTORE 'E SCALA ===")
		for f in fore:
			var lungo: float = float(f[1])
			var meta: float = (float(f[2]) + float(f[3])) * 0.5
			print("  %-24s %6.3f m  ->  scala × %.3f pe' arrivà a %.2f m"
				% [str(f[0]), lungo, meta / maxf(lungo, 0.0001), meta])
		male("%d modelle stanno fore mesura" % fore.size())

	print("=== storte: %d ===" % storte)
	get_tree().quit()


func _ngombro(n: Node) -> AABB:
	var a := AABB()
	var primmo := true
	for c in _tutte_e_mesh(n):
		var m: MeshInstance3D = c
		if m.mesh == null:
			continue
		var b: AABB = m.mesh.get_aabb()
		b = m.transform * b
		if primmo:
			a = b
			primmo = false
		else:
			a = a.merge(b)
	return a


func _tutte_e_mesh(n: Node) -> Array:
	var fore: Array = []
	if n is MeshInstance3D:
		fore.append(n)
	for c in n.get_children():
		fore.append_array(_tutte_e_mesh(c))
	return fore
