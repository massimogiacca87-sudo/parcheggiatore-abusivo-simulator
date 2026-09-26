extends Node3D
## Citta
## Il quartiere intero: quattro zone collegate da strade, invece della sola
## piazza.
##
## Il mondo è 190 × 172 metri — venti volte l'area della vecchia piazza —
## ma quello che conta non è la superficie: è che adesso ci sono POSTI, e
## ognuno appartiene a qualcuno. La Piazza è tua dall'inizio. Le altre tre
## le tiene un altro parcheggiatore, e se ci metti piede te ne accorgi.
##
## Come sta insieme:
##   - la Piazza è il vecchio `zone_vicolo_3d`, montato qui dentro come
##     figlio con un offset. Non è stato riscritto: gli si dice soltanto
##     `dentro_citta = true` e lui rinuncia a luce, panorama e muri di
##     confine, che in una città devono essere unici;
##   - le altre zone sono più semplici — pavimentazione, palazzi intorno,
##     posti auto, un paio di cose caratteristiche a testa — perché per ora
##     lì non ci lavori: ci vai a vedere che c'è, e trovi il padrone;
##   - le strade tengono insieme il tutto e sono anche il posto dove il
##     mondo respira: lampioni, auto in sosta, cassonetti.
##
## Il mare e il Vesuvio stanno oltre il lato z negativo, che è dove la
## Piazza ha sempre avuto il suo belvedere.

const Tex := preload("res://scripts/textures.gd")
const CicloScript := preload("res://scripts/giorno_notte.gd")
const PiazzaScript := preload("res://scripts/zone_vicolo_3d.gd")
const RivaleScript := preload("res://scripts/rivale_3d.gd")
const CornetteriaScript := preload("res://scripts/cornetteria_3d.gd")
const SpigheScript := preload("res://scripts/spighe_3d.gd")
const PostoUtileScript := preload("res://scripts/posto_utile.gd")
const MonumentoScript := preload("res://scripts/monumento.gd")
const PassanteScript := preload("res://scripts/passante_3d.gd")
const Ostacoli := preload("res://scripts/ostacoli.gd")
const BambiniScript := preload("res://scripts/bambini_3d.gd")
const MotorinoScript := preload("res://scripts/motorino_citta.gd")
const Models := preload("res://scripts/models.gd")
const Human := preload("res://scripts/human_builder.gd")
const AutoVarieScript := preload("res://scripts/auto_varie.gd")
const ManifestoScript := preload("res://scripts/manifesto_3d.gd")
const RegiaScript := preload("res://scripts/regia_musicale.gd")
const ScopaScript := preload("res://scripts/scopa_3d.gd")
const TreCarteScript := preload("res://scripts/tre_carte_3d.gd")
const SalaScommesseScript := preload("res://scripts/sala_scommesse_3d.gd")
const MergellinaScript := preload("res://scripts/mergellina.gd")
const PosteggioScript := preload("res://scripts/posteggio_3d.gd")
const GuaglioneScript := preload("res://scripts/guaglione_3d.gd")
const BachecaScript := preload("res://scripts/bacheca_3d.gd")
const MaestroScript := preload("res://scripts/maestro_3d.gd")
const GarageScript := preload("res://scripts/garage_3d.gd")
const PostoScript := preload("res://scripts/parking_spot_3d.gd")
const GolfoScript := preload("res://scripts/golfo.gd")
const ArmiereScript := preload("res://scripts/armiere_3d.gd")
const FermoScript := preload("res://scripts/fermo_3d.gd")
const VicinoScript := preload("res://scripts/vicino_3d.gd")
const SignoraLottoScript := preload("res://scripts/signora_lotto_3d.gd")
const BossCapitoloScript := preload("res://scripts/boss_capitolo_3d.gd")
const VascioScript := preload("res://scripts/vascio_3d.gd")
const TavoloScopaScript := preload("res://scripts/tavolo_scopa.gd")
const CummissioneScript := preload("res://scripts/cummissione_3d.gd")

const LAYER_WORLD := 1

## Il mondo, in metri.
## Fin dove si puo' camminare verso il mare.
##
## La citta' finisce a z = 0, ma di la' c'e' Mergellina: carreggiata,
## passeggiata e muraglione. Il giocatore veniva ricacciato indietro a
## z = -1,5 da `_keep_in_bounds()` del player, che non sapeva niente del
## lungomare — non c'era nessun muro, c'era il limite della mappa. Adesso
## il limite arriva al filo della passeggiata; oltre c'e' il muraglione,
## che e' un muro vero e si vede.
const LIMITE_NORD: float = -19.4

const LARGHEZZA: float = 190.0
const PROFONDITA: float = 172.0

## Le zone. `rect` è [x0, z0, x1, z1].
## `padrone` è "tu" oppure il nome del parcheggiatore che ce l'ha.
const ZONE := [
	{
		"id": "piazza", "nome": "Piazza 'e Sant'Anna",
		"rect": [14.0, 6.0, 48.0, 60.0], "padrone": "tu",
		"desc": "'A zona toia. Ccà cummanne tu.",
	},
	{
		"id": "stadio", "nome": "Piazzale d''o Stadio",
		"rect": [110.0, 6.0, 178.0, 58.0], "padrone": "Gennaro 'o Capitano",
		"desc": "Quanno ce sta 'a partita, ccà se fa 'o Natale.",
		# Il centro di questa piazza e' occupato dall'impianto: il
		# parcheggiatore e il cartello vanno sul sagrato, davanti.
		"posto": Vector3(144.0, 0.0, 52.0), "ingresso_sud": true,
		"ronda": [112.0, 46.0, 176.0, 57.0],
	},
	{
		"id": "mercato", "nome": "'A Via d''e Spighe",
		"rect": [15.0, 101.0, 48.0, 122.0], "padrone": "Rafele 'o Sicco",
		"desc": "Bancarelle 'a nu lato e 'a ll'ato, e sempe ggente.",
	},
	{
		"id": "cornetteria", "nome": "Vico d''a Cornetteria",
		"rect": [134.0, 101.0, 154.0, 122.0], "padrone": "Tonino 'e Notte",
		"desc": "'E juorno nun ce sta nisciuno. 'A notte è n'ata cosa.",
	},
]

## Le strade: [x0, z0, x1, z1].
##
## La larghezza è la misura che decide tutto. Quattro metri con i palazzi a
## sedici vuol dire camminare in fondo a un canyon, e quella è la sensazione
## che fa dire "questa è Napoli". Sopra i dieci metri non è più un vicolo:
## è una circonvallazione, e infatti la versione di prima — con la "via"
## da ventidue metri e il "corso" da ventisei — sembrava una città nuova di
## provincia, non un quartiere.
##
## Perciò qui dentro c'è una sola strada da otto metri ('O Corso), due da
## sette (le vie trasversali), e tutto il resto sono vicoli da quattro.
const STRADE := [
	# =====================================================================
	# 'E DECUMANE — le tre strade lunghe che tagliano la citta' da un capo
	# all'altro.
	#
	# E' la cosa che rende Napoli riconoscibile su una pianta prima ancora
	# che dal vero: il centro antico e' ancora la griglia greca, tre strade
	# dritte parallele est-ovest (i decumani) tagliate a pettine da tante
	# traverse strettissime (i cardini). Non e' una maglia regolare come
	# quella americana — e' una maglia SBILANCIATA: pochissime strade
	# lunghe, e moltissime corte e strette.
	#
	# Prima la mappa aveva sette strade nord-sud e sei est-ovest, tutte piu'
	# o meno alla stessa distanza. Era una scacchiera. Adesso le lunghe
	# est-ovest restano tre e i cardini raddoppiano: la differenza si vede
	# camminando, perche' una strada lunga la percorri e le traverse le
	# attraversi.
	# =====================================================================
	[0.0, 60.0, 190.0, 67.0],       # 'o Decumano Maggiore — Via 'e sotto, 7 m
	[0.0, 92.0, 190.0, 99.0],       # Via Marina, la strada bassa
	# **Spaccanapoli.** Quattro metri per centonovanta, perfettamente
	# dritta, da un bordo all'altro della mappa senza un solo scarto. E' la
	# strada piu' famosa di Napoli e la si riconosce da una cosa sola: ci
	# entri e ne vedi il fondo. Qui e' l'unica via che attraversa tutto,
	# ed e' anche la piu' stretta delle tre. Non e' un errore: e' proprio
	# quello il punto.
	# Sta a z 74-78 e non piu' vicino a Via Marina: fra le due ci vogliono
	# almeno dodici metri, se no la striscia di isolati in mezzo scende
	# sotto ai cinque metri, il pianificatore la butta via, e le due strade
	# si fondono in un unico piazzale largo quindici metri. Che e'
	# esattamente il contrario di Spaccanapoli.
	[0.0, 74.0, 190.0, 78.0],

	# --- le altre trasversali, corte ---
	[0.0, 0.0, 190.0, 5.0],         # la fascia a mare
	[0.0, 124.0, 190.0, 128.0],
	[0.0, 152.0, 190.0, 156.0],
	[0.0, 168.0, 190.0, 172.0],     # via bassa
	[51.0, 22.0, 110.0, 26.0],      # traversa alta, fra piazza e piazzale
	[51.0, 40.0, 110.0, 44.0],      # traversa bassa
	[0.0, 30.0, 13.0, 34.0],        # traversina di ponente

	# =====================================================================
	# 'E CARDINE — le traverse strette, a pettine sui decumani.
	#
	# Sono passate da sette a dodici, e stanno molto piu' vicine fra loro:
	# nella fascia centrale il passo scende da venticinque metri a dodici.
	# Dodici metri di passo con vicoli da quattro vuol dire isolati da otto
	# metri di fronte — cioe' palazzi stretti e alti, che e' esattamente la
	# proporzione dei Quartieri e del centro antico.
	# =====================================================================
	[9.0, 5.0, 13.0, 172.0],        # vicolo di ponente
	[26.0, 62.0, 30.0, 172.0],      # cardine dietro 'a piazza (solo a sud)
	[51.0, 5.0, 55.0, 172.0],       # vicolo dietro la piazza
	[63.0, 5.0, 67.0, 172.0],       # cardine 'e mieze
	[74.0, 0.0, 82.0, 172.0],       # 'O Corso: la piu' larga, e resta 8 m
	[90.0, 5.0, 94.0, 172.0],       # cardine d''o cuorpo 'e Napule
	[103.0, 5.0, 107.0, 172.0],
	[116.0, 56.0, 120.0, 172.0],    # cardine 'e levante
	[129.0, 56.0, 133.0, 172.0],    # sotto al piazzale la maglia continua
	[155.0, 56.0, 159.0, 172.0],
	[166.0, 67.0, 170.0, 172.0],    # cardine d''o Vommero
	[179.0, 5.0, 183.0, 172.0],     # vicolo di levante

	# --- vicoli ciechi ---
	#
	# Sono rimasti due. Prima erano cinque, ma tre di quelli sono diventati
	# cardini veri: una citta' con cinque vicoli ciechi su dodici traverse
	# non e' Napoli, e' un labirinto. A Napoli i vicoli ciechi ci sono, ma
	# sono l'eccezione — la regola e' che si passa sempre.
	#
	# Finiscono DUE METRI prima dell'isolato successivo, cosi' il
	# rettangolo dell'isolato si richiude sopra e in fondo al vicolo c'e'
	# una facciata vera invece di un muro invisibile.
	[140.0, 100.0, 144.0, 116.0],   # 'o vico d''o ferraro
	[20.0, 158.0, 24.0, 166.0],
]

## Gli slarghi: spazi liberi che non sono zone di gioco ma tengono insieme la
## maglia. Senza, un quartiere di soli vicoli diventa un labirinto in cui non
## si capisce più dove si sta.
const SLARGHI := [
	[16.0, 0.0, 48.0, 6.0],       # 'o belvedere: qui non si costruisce mai
	[57.0, 70.0, 73.0, 89.0],     # 'a piazzetta d''a fontana
	[16.0, 130.0, 40.0, 148.0],   # 'o largo d''e guagliune
	[109.0, 130.0, 128.0, 148.0],
	[160.0, 157.0, 178.0, 167.0],
]

## Gli isolati: tutto quello che NON è strada, piazza o slargo.
##
## Non sono scritti a mano: li calcola `tools/pianta.py`, che rasterizza la
## mappa, ne ricava i rettangoli massimali, verifica col flood fill che ogni
## metro calpestabile sia raggiungibile dalla piazza, e disegna la pianta in
## PNG. Se si tocca STRADE o le piazze, si rilancia quello e si ricopia qui
## sotto quello che stampa — a mano non si sta dietro, e una pianta con un
## vicolo murato non si scopre finché non ci finisci dentro.
const ISOLATI := [
	[0, 5, 9, 30],
	[0, 34, 9, 60],
	[0, 67, 9, 74],
	[0, 78, 9, 92],
	[0, 99, 9, 124],
	[0, 128, 9, 152],
	[0, 156, 9, 168],
	[13, 67, 26, 74],
	[13, 78, 26, 92],
	[13, 158, 20, 168],
	[30, 67, 51, 74],
	[30, 78, 51, 92],
	[30, 156, 51, 168],
	[41, 129, 51, 149],
	[55, 5, 63, 22],
	[55, 26, 63, 40],
	[55, 44, 63, 60],
	[55, 99, 63, 124],
	[55, 128, 63, 152],
	[55, 156, 63, 168],
	[67, 5, 74, 22],
	[67, 26, 74, 40],
	[67, 44, 74, 60],
	[67, 99, 74, 124],
	[67, 128, 74, 152],
	[67, 156, 74, 168],
	[82, 5, 90, 22],
	[82, 26, 90, 40],
	[82, 44, 90, 60],
	[82, 67, 90, 74],
	[82, 78, 90, 92],
	[82, 99, 90, 124],
	[82, 128, 90, 152],
	[82, 156, 90, 168],
	[94, 5, 103, 22],
	[94, 26, 103, 40],
	[94, 44, 103, 60],
	[94, 67, 103, 74],
	[94, 78, 103, 92],
	[94, 99, 103, 124],
	[94, 128, 103, 152],
	[94, 156, 103, 168],
	[107, 67, 116, 74],
	[107, 78, 116, 92],
	[107, 99, 116, 124],
	[107, 156, 116, 168],
	[120, 67, 129, 74],
	[120, 78, 129, 92],
	[120, 99, 129, 124],
	[120, 156, 129, 168],
	[133, 67, 155, 74],
	[133, 78, 155, 92],
	[133, 128, 155, 152],
	[133, 156, 155, 168],
	[159, 67, 166, 74],
	[159, 78, 166, 92],
	[159, 99, 166, 124],
	[159, 128, 166, 152],
	[170, 67, 179, 74],
	[170, 78, 179, 92],
	[170, 99, 179, 124],
	[170, 128, 179, 152],
	[183, 5, 190, 60],
	[183, 67, 190, 74],
	[183, 78, 190, 92],
	[183, 99, 190, 124],
	[183, 128, 190, 152],
	[183, 156, 190, 168],
]

## **L'isolato della galera** (0.60). Dalla 0.56 alla 0.59 la galera era un
## blocco piantato a mano nove metri dietro a `GALERA_FORE`, e stava sopra a
## due isolati e attraverso tre strade (vedi `_build_galera`). Adesso è un
## isolato della pianta come gli altri — pieno, solido, conosciuto da chi
## cammina e dalla griglia — solo che al posto dei palazzi ci sta lei.
const ISOLATO_GALERA := [133, 156, 155, 168]


static func e_galera(b: Array) -> bool:
	return int(b[0]) == ISOLATO_GALERA[0] and int(b[1]) == ISOLATO_GALERA[1] \
		and int(b[2]) == ISOLATO_GALERA[2] and int(b[3]) == ISOLATO_GALERA[3]


## Il punto sta sul muro della galera (o a `orlo` metri da lì)?
static func ncopp_a_galera(p: Vector3, orlo: float = 0.6) -> bool:
	return p.x > float(ISOLATO_GALERA[0]) - orlo and p.x < float(ISOLATO_GALERA[2]) + orlo \
		and p.z > float(ISOLATO_GALERA[1]) - orlo and p.z < float(ISOLATO_GALERA[3]) + orlo


var _ciclo: Node = null
var _piazza: Node3D = null
var _zona_corrente: String = ""
var _strada_corrente: String = ""
var _batch: Dictionary = {}

signal zona_cambiata(id: String, nome: String, padrone: String)
## Sei entrato in una strada che ha un nome.
signal strada_cambiata(nome: String)


## **'E nomme d''e strade.**
##
## Una città si riconosce dai nomi delle sue strade prima ancora che dalla
## sua forma: "Spaccanapoli" dice più di qualunque descrizione di una via
## lunga e stretta. Finché le strade erano rettangoli anonimi, la mappa
## poteva essere di qualunque città del sud; con i nomi diventa questa.
##
## Non sono tutte: sono le sette che vale la pena riconoscere. Le altre
## restano vicoli senza nome, che a Napoli è la norma — i vicoli il nome ce
## l'hanno sulla targa e non lo usa nessuno.
##
##   x0, z0, x1, z1, nome
const NOMI_STRADE := [
	[0.0, 74.0, 190.0, 78.0, "Spaccanapoli"],
	[0.0, 60.0, 190.0, 67.0, "'O Decumano Maggiore"],
	[0.0, 92.0, 190.0, 99.0, "Via Marina"],
	[74.0, 0.0, 82.0, 172.0, "'O Corso"],
	[0.0, 0.0, 190.0, 5.0, "Via Caracciolo"],
	[9.0, 5.0, 13.0, 172.0, "Vico 'e Ponente"],
	[179.0, 5.0, 183.0, 172.0, "Vico 'e Levante"],
	[63.0, 5.0, 67.0, 172.0, "Cardine 'e Mieze"],
	[140.0, 100.0, 144.0, 116.0, "Vico d''o Ferraro"],
]


## Come si chiama la strada in cui sta questo punto, stringa vuota se non ha
## nome. Le zone di gioco vincono sulle strade: se stai in piazza, stai in
## piazza, anche se un decumano ci passa a fianco.
func strada_di(p: Vector3) -> String:
	for z in ZONE:
		var r: Array = z["rect"]
		if p.x >= r[0] and p.x <= r[2] and p.z >= r[1] and p.z <= r[3]:
			return ""
	for n in NOMI_STRADE:
		if p.x >= float(n[0]) and p.x <= float(n[2]) \
				and p.z >= float(n[1]) and p.z <= float(n[3]):
			return str(n[4])
	return ""


func _ready() -> void:
	add_to_group("citta")
	_build_luce()
	_build_terreno()
	_build_confini()
	_build_pavimentazione()
	_build_isolati()
	_build_piazza()
	_build_zone()
	_build_panorama()
	_build_fondale()
	_build_mergellina()
	_build_vita_di_vicolo()
	_build_vetrine()
	_build_verde()
	_build_vita()
	_build_manifesti()
	_build_murales()
	_build_attivita()
	_build_armiere()
	_build_maestro()
	_build_vascio()
	_build_tavule_scopa()
	_build_cummissiune()
	_build_gente_ferma()
	_build_vicinato()
	_build_signora()
	GameManager.boss_capitolo_arriva.connect(_arriva_o_boss)
	_build_cartelli()
	_build_fumo()
	_build_arredo_novo()
	# Il regista della caccia: guarda le stelle e manda i carabinieri.
	# Sta qui e non nel GameManager perche' deve poter guardare la pianta
	# per decidere dove farli nascere.
	var caccia := preload("res://scripts/caccia.gd").new()
	add_child(caccia)
	_alza_collina()
	_build_collina()
	_flush_batch()
	# Le finestre accese sono un gruppo solo: dopo il raggruppamento lo si
	# consegna al ciclo, che lo tira fuori al tramonto e lo nasconde
	# all'alba. Non si poteva fare prima perche' prima del flush il gruppo
	# non esiste ancora — sono istanze in una lista.
	var luci_finestre := get_node_or_null("Gruppo_vetro_luce")
	if luci_finestre != null and _ciclo:
		_ciclo.aggiungi_notturno(luci_finestre)
	# **'A rassegna d''e ccose ca nun se passano** (0.59, vedi
	# `ostacoli.gd`). A città fatta si contano tutti i corpi solidi, così chi
	# cammina senza motore fisico sa dove stanno le auto in sosta, le
	# panchine e la munnezza. Due volte: adesso, e fra un secondo e mezzo,
	# quando pure la roba che la piazza mette "a fine fotogramma" sta al
	# posto suo.
	Ostacoli.censisci(self)
	get_tree().create_timer(1.5).timeout.connect(_ricensisci)
	# Le macchie d'olio nei posti auto (0.62): un secondo dopo, quando le
	# piazze hanno messo tutti i posti.
	get_tree().create_timer(1.0).timeout.connect(_macchie_dint_ê_posti)


func _ricensisci() -> void:
	if is_inside_tree():
		Ostacoli.censisci(self)


func _macchie_dint_ê_posti() -> void:
	if is_inside_tree():
		RobbaEsterna.macchie_posti(self)


# ---------------------------------------------------------------------------
# Luce e cielo: unici per tutta la città
# ---------------------------------------------------------------------------

func _build_luce() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sole"
	sun.rotation_degrees = Vector3(-42, -128, 0)
	sun.light_energy = 1.15
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	sun.shadow_blur = 0.55
	sun.shadow_bias = 0.05
	sun.light_specular = 0.5
	if _forward_plus():
		sun.directional_shadow_mode = \
			DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		sun.directional_shadow_split_1 = 0.05
		sun.directional_shadow_split_2 = 0.15
		sun.directional_shadow_split_3 = 0.4
		sun.directional_shadow_blend_splits = true
		sun.directional_shadow_max_distance = 130.0
		# La penombra morbida costava cara in stabilita': con 0.6 il bordo
		# dell'ombra viene ricalcolato con un campionamento casuale a ogni
		# fotogramma, e in un vicolo — dove l'ombra e' quasi tutto — quel
		# bordo brulica appena ti muovi. 0.15 e' ancora una penombra, ma sta
		# ferma.
		sun.light_angular_distance = 0.15
	add_child(sun)

	var bounce := DirectionalLight3D.new()
	bounce.rotation_degrees = Vector3(38, 52, 0)
	# La luce di rimbalzo era azzurrina, come se venisse dal cielo. In una
	# piazza aperta andava bene; in un vicolo da quattro metri il cielo si
	# vede a malapena e quasi tutta la luce indiretta e' quella che rimbalza
	# sull'intonaco giallo del muro di fronte. Con l'azzurro i vicoli
	# venivano fuori blu e gelidi, che e' l'ultima cosa che sembra Napoli.
	bounce.light_energy = 0.36
	bounce.light_color = Color(0.98, 0.88, 0.74)
	bounce.shadow_enabled = false
	add_child(bounce)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	# **Il cielo non e' piu' una sfumatura.**
	#
	# Il ProceduralSkyMaterial di Godot sa fare una cosa sola: due colori
	# uno sopra l'altro. Va benissimo finche' il cielo e' un fondale, e
	# smette di bastare appena diventa mezza inquadratura — che in una
	# citta' di vicoli, dove si cammina guardando in su, e' quasi sempre.
	# `assets/shaders/cielo.gdshader` aggiunge la terza tinta a meta'
	# altezza, le nuvole che si muovono davvero, l'alone del sole e le
	# stelle. Il ciclo giorno/notte continua a pilotarlo dagli stessi
	# colori di prima, solo che adesso li passa come uniform.
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = load("res://assets/shaders/cielo.gdshader")
	sky_mat.set_shader_parameter("col_zenit", Color(0.10, 0.32, 0.72))
	sky_mat.set_shader_parameter("col_cielo", Color(0.35, 0.58, 0.85))
	sky_mat.set_shader_parameter("col_orizzonte", Color(0.82, 0.86, 0.88))
	sky_mat.set_shader_parameter("col_terra", Color(0.30, 0.29, 0.27))
	sky_mat.set_shader_parameter("nuvole_copertura", 0.40)
	sky_mat.set_shader_parameter("nuvole_densita", 1.0)
	sky.sky_material = sky_mat
	# **Il cielo si ridisegna a ogni fotogramma, e non e' uno spreco.**
	#
	# La prima versione usava PROCESS_MODE_INCREMENTAL per risparmiare: il
	# cielo aggiorna una faccia del cubo per volta. Il problema e' che da
	# quella mappa esce anche la luce ambientale di tutta la citta', e
	# aggiornandola a rate ridotto restava indietro rispetto all'ora del
	# giorno — a notte fonda i palazzi erano ancora illuminati come a
	# mezzogiorno, gialli sotto un cielo stellato.
	#
	# Il costo vero e' basso: il cielo qui non campiona nessuna texture, e
	# con la mappa a 128 pixel per faccia si sta largo anche sul web.
	sky.process_mode = Sky.PROCESS_MODE_REALTIME
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.45
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_white = 2.4
	e.tonemap_exposure = 0.92
	e.glow_enabled = true
	e.glow_intensity = 0.28
	e.glow_bloom = 0.02
	e.glow_hdr_threshold = 1.1
	e.fog_enabled = true
	e.fog_light_color = Color(0.88, 0.86, 0.80)
	e.fog_light_energy = 0.9
	e.fog_density = 0.0009
	e.fog_sky_affect = 0.0
	e.fog_aerial_perspective = 0.14
	e.adjustment_enabled = true
	e.adjustment_saturation = 1.08
	e.adjustment_contrast = 1.05
	if _forward_plus():
		# --- Occlusione e luce indiretta in spazio schermo ---------------
		#
		# Questi tre effetti sono la causa piu' probabile dello sfarfallio
		# segnalato in gioco, e sono anche l'unica cosa che il mio banco di
		# prova NON puo' vedere: qui posso far girare solo OpenGL, dove non
		# esistono, mentre la build vera parte in Vulkan, dove ci sono tutti
		# e tre accesi.
		#
		# Perche' brulicano: SSAO, SSIL e SSR ricostruiscono l'informazione
		# campionando lo SCHERMO in punti scelti a caso. Senza un
		# accumulatore temporale (che Godot 4.3 non ha, non essendoci il
		# TAA) quei punti cambiano a ogni fotogramma, e il risultato balla —
		# soprattutto su superfici molto ravvicinate come i due muri di un
		# vicolo da quattro metri, che e' esattamente il caso peggiore.
		#
		# Quindi: SSIL e SSR spenti (sono i due piu' rumorosi e i due che
		# qui servono meno — l'intonaco non riflette), SSAO tenuta ma con
		# raggio e intensita' dimezzati, che e' il regime in cui e' stabile.
		e.ssao_enabled = true
		e.ssao_radius = 0.9
		e.ssao_intensity = 1.3
		e.ssao_power = 1.4
		e.ssao_detail = 0.2
		e.ssil_enabled = false
		e.ssil_radius = 3.0
		e.ssil_intensity = 0.8
		e.ssr_enabled = false
		# La nebbia volumetrica usa la riproiezione temporale, cioe' riusa il
		# fotogramma prima spostandolo: nei vicoli stretti, dove la
		# geometria copre e scopre in fretta, quella riproiezione lascia
		# scie. Resta accesa ma tenue e senza riproiezione.
		e.volumetric_fog_enabled = true
		e.volumetric_fog_density = 0.008
		e.volumetric_fog_albedo = Color(0.92, 0.88, 0.8)
		e.volumetric_fog_length = 60.0
		e.volumetric_fog_temporal_reprojection_enabled = false
	env.environment = e
	add_child(env)

	_ciclo = CicloScript.new()
	_ciclo.name = "GiornoNotte"
	_ciclo.add_to_group("ciclo_giorno")
	add_child(_ciclo)
	_ciclo.setup(sun, bounce, e, sky_mat)

	var q: Node = load("res://scripts/qualita.gd").new()
	q.name = "Qualita"
	add_child(q)
	q.setup(e, sun)

	# La regia della musica: sta qui perche' le serve il ciclo giorno/notte,
	# ed e' l'unico posto in cui il ciclo esiste.
	var regia := RegiaScript.new()
	regia.name = "RegiaMusicale"
	regia.setup(_ciclo)
	add_child(regia)


static func _forward_plus() -> bool:
	return RenderingServer.get_rendering_device() != null


func ciclo() -> Node:
	return _ciclo


# ---------------------------------------------------------------------------
# Terreno, strade, confini
# ---------------------------------------------------------------------------

func _build_terreno() -> void:
	# Un unico piano d'asfalto sotto a tutto: le zone e le strade ci
	# appoggiano sopra la loro pavimentazione.
	var suolo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(LARGHEZZA + 60.0, PROFONDITA + 60.0)
	suolo.mesh = pm
	suolo.position = Vector3(LARGHEZZA / 2.0, -0.08, PROFONDITA / 2.0)
	suolo.material_override = Tex.ground("asfalto",
		Vector2(LARGHEZZA + 60.0, PROFONDITA + 60.0), 7.0)
	add_child(suolo)

	var corpo := StaticBody3D.new()
	corpo.collision_layer = LAYER_WORLD
	corpo.collision_mask = 0
	var forma := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(LARGHEZZA + 60.0, 1.0, PROFONDITA + 60.0)
	forma.shape = box
	forma.position = Vector3(LARGHEZZA / 2.0, -0.52, PROFONDITA / 2.0)
	corpo.add_child(forma)
	add_child(corpo)


## Muro invisibile tutto intorno alla città.
func _build_confini() -> void:
	const SPESSORE := 3.0
	const ALTEZZA := 30.0
	var cx: float = LARGHEZZA / 2.0
	var cz: float = PROFONDITA / 2.0
	var muri := [
		# I due lati lunghi scendono di venticinque metri verso il mare per
		# chiudere anche la striscia del lungomare: se restassero fermi a
		# z = 0 si uscirebbe dalla mappa camminando lungo la passeggiata.
		[Vector3(-SPESSORE / 2.0, ALTEZZA / 2.0, cz - 13.0),
			Vector3(SPESSORE, ALTEZZA, PROFONDITA + SPESSORE * 2.0 + 26.0)],
		[Vector3(LARGHEZZA + SPESSORE / 2.0, ALTEZZA / 2.0, cz - 13.0),
			Vector3(SPESSORE, ALTEZZA, PROFONDITA + SPESSORE * 2.0 + 26.0)],
		# Il lato NORD non ha piu' il suo muro qui: di la' comincia
		# Mergellina, e la citta' deve poterci uscire. Il confine vero da
		# quella parte e' il muraglione sul mare, che Mergellina si
		# costruisce da se' — ed e' un muro che si VEDE, che e' meglio.
		[Vector3(cx, ALTEZZA / 2.0, PROFONDITA + SPESSORE / 2.0),
			Vector3(LARGHEZZA + SPESSORE * 2.0, ALTEZZA, SPESSORE)],
	]
	for m in muri:
		var b := StaticBody3D.new()
		b.collision_layer = LAYER_WORLD
		b.collision_mask = 0
		var f := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = m[1]
		f.shape = bx
		f.position = m[0]
		b.add_child(f)
		add_child(b)


## Pavimenta strade e slarghi.
##
## Un vicolo napoletano non ha marciapiedi e non ha la riga bianca in mezzo:
## è basolato da un muro all'altro, e basta. I marciapiedi e la segnaletica
## se li meritano solo le strade dai sette metri in su — cioè 'O Corso e le
## due trasversali.
# ---------------------------------------------------------------------------
# Il catasto della pavimentazione
# ---------------------------------------------------------------------------
#
# Ogni strada, ogni slargo e ogni piazza appoggiava per terra il suo bel
# rettangolo di manto, tutti alla stessa quota. Agli incroci finivano quindi
# due piani complanari nello stesso punto: la scheda video non ha modo di
# decidere quale sta sopra e li alterna a ogni fotogramma. Da terra si vedeva
# il basolato che sfarfallava sull'asfalto.
#
# La soluzione non e' alzare uno dei due di un millimetro (si sposta il
# problema piu' in la', a distanza il buffer di profondita' torna a non
# distinguerli): e' non sovrapporli proprio. Ogni superficie, prima di
# posarsi, chiede al catasto quali pezzi di se' sono ancora liberi, e
# pavimenta solo quelli. L'incrocio se lo prende chi arriva per primo — e
# l'ordine e' scelto apposta: prima le strade larghe, poi i vicoli, poi le
# piazze e gli slarghi. Cosi' all'incrocio fra un vicolo e un decumano
# continua l'asfalto del decumano, che e' quello che succede dal vero.
var _catasto: Array[Rect2] = []


## a meno b: fino a quattro rettangoli, nessuno dei quali tocca b.
static func _sottrai_rect(a: Rect2, b: Rect2) -> Array[Rect2]:
	var fuori: Array[Rect2] = []
	var i: Rect2 = a.intersection(b)
	if i.size.x <= 0.001 or i.size.y <= 0.001:
		fuori.append(a)
		return fuori
	var ax1: float = a.position.x + a.size.x
	var az1: float = a.position.y + a.size.y
	var iz1: float = i.position.y + i.size.y
	var ix1: float = i.position.x + i.size.x
	if i.position.y - a.position.y > 0.001:
		fuori.append(Rect2(a.position.x, a.position.y,
			a.size.x, i.position.y - a.position.y))
	if az1 - iz1 > 0.001:
		fuori.append(Rect2(a.position.x, iz1, a.size.x, az1 - iz1))
	if i.position.x - a.position.x > 0.001:
		fuori.append(Rect2(a.position.x, i.position.y,
			i.position.x - a.position.x, i.size.y))
	if ax1 - ix1 > 0.001:
		fuori.append(Rect2(ix1, i.position.y, ax1 - ix1, i.size.y))
	return fuori


## I pezzi ancora liberi del rettangolo dato. Registra l'intero rettangolo:
## chi viene dopo si taglia su tutta la fascia, non solo su quello che e'
## stato davvero disegnato.
## Spezza i pezzi sul bordo del terrapieno, cosi' nessun lastrone sta meta'
## in collina e meta' in citta'. Serve perche' la quota si applica a nodo
## intero: un vicolo che dal Vomero scende fino al mare e' UN piano solo, e
## senza taglio o resta tutto in basso (e sulla collina manca il selciato)
## o sale tutto (e in citta' fluttua a tre metri).
func _spezza_collina(pezzi: Array[Rect2]) -> Array[Rect2]:
	var coll := Rect2(Collina.RECT[0], Collina.RECT[1],
		Collina.RECT[2] - Collina.RECT[0], Collina.RECT[3] - Collina.RECT[1])
	var fuori: Array[Rect2] = []
	for p in pezzi:
		var dentro: Rect2 = p.intersection(coll)
		if dentro.size.x > 0.05 and dentro.size.y > 0.05:
			fuori.append(dentro)
			fuori.append_array(_sottrai_rect(p, coll))
		else:
			fuori.append(p)
	return fuori


func _liberi(x0: float, z0: float, x1: float, z1: float) -> Array[Rect2]:
	var pezzi: Array[Rect2] = [Rect2(x0, z0, x1 - x0, z1 - z0)]
	for preso in _catasto:
		var resto: Array[Rect2] = []
		for p in pezzi:
			resto.append_array(_sottrai_rect(p, preso))
		pezzi = resto
		if pezzi.is_empty():
			break
	_catasto.append(Rect2(x0, z0, x1 - x0, z1 - z0))
	return _spezza_collina(pezzi)


func _build_pavimentazione() -> void:
	var larghe: Array = []
	var strette: Array = []
	for s in STRADE:
		if minf(float(s[2]) - float(s[0]), float(s[3]) - float(s[1])) <= 5.5:
			strette.append(s)
		else:
			larghe.append(s)
	for s in larghe:
		_una_strada(s[0], s[1], s[2], s[3])
	for s in strette:
		_una_strada(s[0], s[1], s[2], s[3])
	for s in SLARGHI:
		_pavimenta(s[0], s[1], s[2], s[3], "slargo")


func _una_strada(x0: float, z0: float, x1: float, z1: float) -> void:
	var w: float = x1 - x0
	var l: float = z1 - z0
	var stretta: bool = minf(w, l) <= 5.5
	var pezzi: Array[Rect2] = _liberi(x0, z0, x1, z1)
	if pezzi.is_empty():
		return
	# La pavimentazione la decide il quartiere in cui passa la strada: basoli
	# scuri nei Quartieri e alla Sanita', basoli chiari e tenuti bene al
	# Vomero, asfalto sulle strade larghe.
	var q: Dictionary = Quartieri.di(x0 + w / 2.0, z0 + l / 2.0)
	var lungo_z: bool = l > w
	var chiaro: bool = str(q["strada"]) == "basolato_chiaro"

	for pz in pezzi:
		var pw: float = pz.size.x
		var pl: float = pz.size.y
		var cx: float = pz.position.x + pw / 2.0
		var cz: float = pz.position.y + pl / 2.0
		var manto := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(pw, pl)
		manto.mesh = pm
		manto.position = Vector3(cx, 0.01, cz)
		if stretta:
			# Il basolato: lastroni di pietra lavica. È la cosa che distingue
			# a colpo d'occhio un vicolo da una strada.
			# Il chiaro del Vomero era 1,35: un moltiplicatore che su una
			# fotografia gia' chiara e fredda dava pietra bianca. Adesso
			# schiarisce appena e vira al caldo, che e' come si distingue
			# davvero il basolato tenuto bene da quello nero dei Quartieri.
			manto.material_override = Tex.mondo("basolato",
				Color(0.86, 0.80, 0.70) if chiaro else Tex.TERRA, 0.86)
		else:
			manto.material_override = Tex.ground("asfalto", Vector2(pw, pl), 6.0)
		add_child(manto)

		if stretta:
			# Nel vicolo, al posto della riga bianca c'è la canaletta di
			# scolo in mezzo, che è dove finisce l'acqua quando piove.
			var scolo := MeshInstance3D.new()
			var sm := BoxMesh.new()
			if lungo_z:
				sm.size = Vector3(0.4, 0.03, pl)
			else:
				sm.size = Vector3(pw, 0.03, 0.4)
			scolo.mesh = sm
			# La canaletta resta sull'asse della strada, non su quello del
			# pezzo: un vicolo tagliato di lato avrebbe lo scolo storto.
			scolo.position = Vector3(
				cx if lungo_z == false else x0 + w / 2.0, 0.025,
				cz if lungo_z else z0 + l / 2.0)
			scolo.material_override = Tex.flat(Color(0.34, 0.33, 0.33), 0.85)
			add_child(scolo)
			continue

		# La riga bianca al centro, tratteggiata, nel senso lungo.
		var bianco := Tex.flat(Color(0.86, 0.85, 0.8), 0.9)
		var passo := 5.0
		var n := int((pl if lungo_z else pw) / passo)
		for i in range(n):
			if i % 2 == 1:
				continue
			var seg := MeshInstance3D.new()
			var bm := BoxMesh.new()
			if lungo_z:
				bm.size = Vector3(0.16, 0.02, passo * 0.55)
				seg.position = Vector3(x0 + w / 2.0, 0.03,
					pz.position.y + i * passo + passo / 2.0)
			else:
				bm.size = Vector3(passo * 0.55, 0.02, 0.16)
				seg.position = Vector3(pz.position.x + i * passo + passo / 2.0,
					0.03, z0 + l / 2.0)
			seg.mesh = bm
			seg.material_override = bianco
			_batched("riga", seg)

		# I marciapiedi sui due lati lunghi. Si fermano all'incrocio insieme
		# al manto: due cordoli che si accavallano fanno lo stesso
		# sfarfallio del selciato.
		var mat_marc := Tex.mondo("marciapiede", Tex.TERRA, 0.9)
		for lato in [0, 1]:
			var cord := MeshInstance3D.new()
			var cm := BoxMesh.new()
			if lungo_z:
				var bx: float = x0 + 0.7 + (w - 1.4) * lato
				if bx < pz.position.x - 0.05 or bx > pz.position.x + pw + 0.05:
					continue
				cm.size = Vector3(1.4, 0.16, pl)
				cord.position = Vector3(bx, 0.08, cz)
			else:
				var bz: float = z0 + 0.7 + (l - 1.4) * lato
				if bz < pz.position.y - 0.05 or bz > pz.position.y + pl + 0.05:
					continue
				cm.size = Vector3(pw, 0.16, 1.4)
				cord.position = Vector3(cx, 0.08, bz)
			cord.mesh = cm
			cord.material_override = mat_marc
			add_child(cord)


# ---------------------------------------------------------------------------
# Gli isolati
# ---------------------------------------------------------------------------

## Il cubo unitario condiviso da tutte le mesh dei palazzi.
##
## Serve al raggruppamento: un MultiMesh vuole che tutte le istanze abbiano
## LA STESSA mesh, e cinquecento palazzi con cinquecento BoxMesh diverse non
## si potrebbero raggruppare. Con un cubo solo e la scala nella trasformata
## si raggruppa tutto per materiale — cinque chiamate di disegno invece di
## cinquecento.
var _cubo: BoxMesh


func _build_isolati() -> void:
	_cubo = BoxMesh.new()
	_cubo.size = Vector3.ONE
	var seme := 0
	for b in ISOLATI:
		# L'isolato della galera non ha palazzi: ce l'ha lei (0.60). Il seme
		# però si conta lo stesso, così gli altri isolati restano uguali.
		if not e_galera(b):
			_isolato(float(b[0]), float(b[1]), float(b[2]), float(b[3]), seme)
		seme += 1


## Un isolato: un blocco pieno di palazzi attaccati, come sono davvero.
##
## Non si costruisce palazzo per palazzo con lo spazio in mezzo: si riempie
## il rettangolo con un nucleo basso e poi si veste ogni lato con una fila
## di facciate di altezza diversa. Il nucleo serve a non lasciare buchi
## visibili dall'alto; le facciate a dare lo skyline seghettato, che è
## quello che si vede alzando gli occhi in un vicolo.
##
## Che faccia abbiano quelle facciate — colore, altezza, larghezza delle
## campate, che c'è al piano terra, se hanno il tetto a falda — non lo
## decide più il caso: lo decide il QUARTIERE in cui cade l'isolato. Vedi
## `scripts/quartieri.gd`.
##
## Le facciate NON sporgono verso la strada: sporgono verso l'interno. In un
## vicolo da quattro metri trenta centimetri di aggetto sono il dieci per
## cento della larghezza, e ci sbatteresti contro senza capire perché.
## Sporgono solo balconi e bow-window, che stanno da quattro metri in su.
## La griglia dei piani. **Tutta la geometria di un palazzo nasce da qui.**
##
## Prima ogni pezzo aveva la sua altezza scritta a mano: le finestre
## partivano da 3,9 e salivano di 3,1; i marcapiani partivano da 3,6 e
## salivano di 3,1; i balconi stavano a 4,8 e a 11,2 fissi. Tre griglie
## diverse sullo stesso muro. Il risultato era che un balcone non stava mai
## davanti a una finestra — sporgeva da un pezzo di muro cieco — e il
## marcapiano tagliava le finestre a mezza altezza.
##
## Adesso c'e' una regola sola: piano terra alto PIANO_TERRA, poi N piani
## alti PIANO, e in cima la fascia del cornicione. Ogni cosa si aggancia a
## questa griglia, e le altezze dei palazzi sono solo quelle che la griglia
## puo' produrre.
const PIANO_TERRA: float = 3.8
const PIANO: float = 3.1
const CORNICIONE: float = 0.55

## Quanto e' alto un palazzo di `n` piani sopra il piano terra.
static func _alt_piani(n: int) -> float:
	return PIANO_TERRA + float(n) * PIANO + CORNICIONE


## Quanti piani servono per avvicinarsi a un'altezza in metri.
static func _piani_per(h: float) -> int:
	return maxi(1, int(round((h - PIANO_TERRA - CORNICIONE) / PIANO)))


func _isolato(x0: float, z0: float, x1: float, z1: float, seme: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 + seme * 104729
	var w: float = x1 - x0
	var l: float = z1 - z0
	var cx: float = (x0 + x1) / 2.0
	var cz: float = (z0 + z1) / 2.0
	var q: Dictionary = Quartieri.di(cx, cz)

	# Un collider solo per tutto l'isolato. È pieno: non ci si entra, e non
	# c'è niente da collidere là dentro.
	var corpo := StaticBody3D.new()
	corpo.collision_layer = LAYER_WORLD
	corpo.collision_mask = 0
	var f := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(w, 30.0, l)
	f.shape = bx
	f.position = Vector3(cx, 15.0, cz)
	corpo.add_child(f)
	add_child(corpo)

	# **Quanti piani ha questo isolato.**
	#
	# Uno solo, per tutto l'isolato, piu' una variazione di un piano in su o
	# in giu' su qualche palazzo. Prima ogni campata pescava un'altezza a
	# caso in un intervallo di quattro metri e mezzo, e il risultato era una
	# fila di denti: fra due campate vicine ci potevano essere quattro metri
	# di dislivello, e la campata alta restava una lastra isolata con le
	# finestre sospese sopra il tetto della vicina.
	#
	# Un isolato napoletano vero ha una linea di gronda quasi continua. È
	# proprio quella continuità che lo fa leggere come un ISOLATO invece che
	# come dieci case messe vicine. La varietà sta fra un isolato e l'altro.
	var alt: Array = q["h"]
	var pmin: int = _piani_per(float(alt[0]))
	var pmax: int = _piani_per(float(alt[1]))
	var piani_base: int = rng.randi_range(pmin, maxi(pmin, pmax - 1))

	# Il nucleo arriva all'altezza piu' bassa che una campata puo' avere, e
	# ha il suo tetto sopra. Prima stava due metri e mezzo SOTTO qualunque
	# facciata: l'interno dell'isolato era un pozzo, e affacciandosi da un
	# balcone o guardando da un incrocio si vedeva il retro delle facciate
	# in piedi da sole, con le finestre a mezz'aria.
	var h_nucleo: float = _alt_piani(maxi(1, piani_base - 1))
	var rient: float = minf(0.5, minf(w, l) * 0.2)
	_muro_semplice(Vector3(cx, h_nucleo / 2.0, cz),
		Vector3(w - rient * 2.0, h_nucleo, l - rient * 2.0), q, 0)
	_tetto_piano(Vector3(cx, h_nucleo, cz),
		Vector2(w - rient * 2.0, l - rient * 2.0), q)

	# Le facciate, una fila per lato.
	for lato in range(4):
		_facciata(x0, z0, x1, z1, lato, rng, q, piani_base)

	# Roba sui tetti: antenne, parabole, comignoli. Stanno sul tetto del
	# nucleo, che adesso e' una superficie vera — prima finivano in fondo al
	# pozzo, dove non li vedeva nessuno.
	var quanta: float = 260.0 if bool(q["panni"]) else 620.0
	var margine: float = PROF_FACCIATA + 1.0
	if w > margine * 2.0 + 2.0 and l > margine * 2.0 + 2.0:
		for i in range(int(maxf(1.0, (w * l) / quanta))):
			var px: float = rng.randf_range(x0 + margine, x1 - margine)
			var pz: float = rng.randf_range(z0 + margine, z1 - margine)
			_roba_sul_tetto(Vector3(px, h_nucleo, pz), rng,
				Rect2(x0 + margine, z0 + margine, w - margine * 2.0,
					l - margine * 2.0))


## Quanto la facciata entra dentro all'isolato.
const PROF_FACCIATA: float = 3.2


## Una fila di facciate lungo un lato dell'isolato.
## lato: 0 = z0 (nord), 1 = x1 (est), 2 = z1 (sud), 3 = x0 (ovest).
func _facciata(x0: float, z0: float, x1: float, z1: float, lato: int,
		rng: RandomNumberGenerator, q: Dictionary, piani_base: int) -> void:
	const PROF := PROF_FACCIATA
	var orizzontale: bool = lato == 0 or lato == 2
	# I lati lunghi (nord e sud) coprono tutto il fronte; quelli corti si
	# fermano prima, lasciando gli angoli ai primi.
	#
	# Anche questo serve contro lo sfarfallio: se tutti e quattro i lati
	# arrivassero fino in fondo, la testata del lato est finirebbe nello
	# stesso piano della faccia del lato nord, e quei tre metri d'angolo
	# sfarfallerebbero come faceva prima tutto il muro.
	var inizio: float = 0.0 if orizzontale else PROF
	var lunghezza: float = (x1 - x0) if orizzontale else (z1 - z0 - PROF * 2.0)
	if lunghezza < 4.0:
		return
	# La normale che punta verso la strada.
	var fuori: Vector3 = [Vector3(0, 0, -1), Vector3(1, 0, 0),
		Vector3(0, 0, 1), Vector3(-1, 0, 0)][lato]

	var campata: Array = q["campata"]
	var muri: Array = q["muri"]
	var t: float = 0.0
	var indice: int = rng.randi()
	while t < lunghezza - 1.0:
		var largo: float = minf(
			rng.randf_range(float(campata[0]), float(campata[1])), lunghezza - t)
		if lunghezza - t - largo < 4.0:
			largo = lunghezza - t   # l'ultimo si prende quello che resta

		# Un piano in piu' o in meno ogni tanto, non un'altezza a caso: la
		# linea di gronda resta leggibile e le finestre restano dentro al
		# loro palazzo.
		var d_piani: int = [0, 0, 0, 0, 1, -1][rng.randi() % 6]
		# La variazione non puo' scendere sotto il minimo del quartiere: nei
		# Quartieri un palazzo di un piano solo e' alto sette metri e mezzo,
		# e in mezzo a vicini di tredici sembra un capannone caduto li'.
		var piani: int = maxi(_piani_per(float(q["h"][0])),
			piani_base + d_piani)
		var h: float = _alt_piani(piani)
		var centro_lungo: float = t + largo / 2.0
		var c: Vector3
		var dim: Vector3
		if orizzontale:
			var zf: float = (z0 + PROF / 2.0) if lato == 0 else (z1 - PROF / 2.0)
			c = Vector3(x0 + inizio + centro_lungo, h / 2.0, zf)
			dim = Vector3(largo, h, PROF)
		else:
			var xf: float = (x1 - PROF / 2.0) if lato == 1 else (x0 + PROF / 2.0)
			c = Vector3(xf, h / 2.0, z0 + inizio + centro_lungo)
			dim = Vector3(PROF, h, largo)

		_muro_semplice(c, dim, q, indice)
		var faccia: Vector3 = c + fuori * (PROF / 2.0)
		faccia.y = 0.0

		# Il cornicione in cima: la riga d'ombra che stacca il palazzo dal
		# cielo. È anche il pezzo che cambia di più fra un quartiere e
		# l'altro: sottile e scuro nei Quartieri, grosso e chiaro al Vomero.
		# Il cornicione e' una FASCIA sotto il bordo del tetto, non un
		# cappello sopra tutto il palazzo. Prima era profondo quanto tutta
		# la facciata piu' mezzo metro (3,64 m) e centrato sul volume: ne
		# sporgeva 42 cm sulla strada e i restanti tre metri finivano sopra
		# al tetto, che da un punto di vista alto si vedeva come una lastra
		# bianca appoggiata sul terrazzo.
		var grosso: bool = bool(q["marcapiano"])
		var sporgenza := 0.35
		var prof_corn := 1.0
		_pezzo(faccia + Vector3(0, h - CORNICIONE / 2.0, 0)
			+ fuori * (sporgenza - prof_corn / 2.0),
			_spessa(fuori, largo,
				CORNICIONE if grosso else CORNICIONE * 0.75, prof_corn),
			Tex.flat(Color(q["cornicione"]), 0.94), "cornicione")

		# **Il tetto.** Prima non c'era: la campata finiva col cornicione e
		# sopra restava il cielo, cioe' una scatola aperta vista da un
		# balcone o da una salita.
		if str(q["tetto"]) == "falda":
			_tetto_a_falda(faccia, fuori, largo, h)
			_comignolo_falda(faccia, fuori, largo, h, rng)
		else:
			# `c` e' il CENTRO del volume del muro, quindi la sua y vale
			# gia' h/2: sommarci h metteva il tetto a un'altezza e mezza
			# del palazzo, sospeso nel cielo. Il tetto va in cima, cioe' a
			# y = h assoluti.
			_tetto_piano(Vector3(c.x, h, c.z), Vector2(dim.x, dim.z), q)
			_roba_sul_tetto_campata(Vector3(c.x, h, c.z),
				Vector2(dim.x, dim.z), fuori, rng)

		_piano_terra(faccia, fuori, largo, q, indice, rng)
		_finestre(faccia, fuori, largo, piani, q, rng)
		if bool(q["marcapiano"]):
			_marcapiani(faccia, fuori, largo, piani, q)

		# **I balconi stanno davanti alle finestre**, non dove capita.
		# L'altezza e' quella del davanzale del piano scelto: prima erano
		# inchiodati a 4,8 e a 11,2 metri, che non corrispondono a nessuna
		# riga di finestre, e infatti sporgevano da muri ciechi.
		for pi in range(piani):
			if rng.randf() >= float(q["balcone"]):
				continue
			var y_bal: float = _y_davanzale(pi) + 0.62
			# Il bow-window del Vomero e' alto quasi due metri sopra il suo
			# davanzale: sull'ultimo piano sbucava sopra la linea di gronda
			# e si vedeva come una scatola sospesa contro il cielo, appena
			# la campata accanto era piu' bassa di un piano.
			var sopra: float = 1.95 if str(q["stile_balcone"]) == "bow" else 0.55
			if y_bal + sopra > h - CORNICIONE:
				continue
			_balcone(faccia, fuori, largo, y_bal, q)

		t += largo
		indice += 1 + (rng.randi() % maxi(1, muri.size()))


## L'altezza del davanzale del piano `pi` (0 = primo piano sopra il terra).
static func _y_davanzale(pi: int) -> float:
	return PIANO_TERRA + float(pi) * PIANO + 0.62


## Il tetto piano: una lastra di guaina con la scossalina intorno. Non è
## decorazione — è il pezzo che chiude il palazzo. Senza, dall'alto la città
## era una scatola di scarpe senza coperchio.
func _tetto_piano(centro: Vector3, dim: Vector2, q: Dictionary) -> void:
	if dim.x < 0.4 or dim.y < 0.4:
		return
	var guaina := Tex.mondo("asfalto", Color(0.62, 0.60, 0.58), 0.97)
	# **Tre centimetri sopra, no a filo** (0.60). La lastra stava con la
	# faccia di sopra esattamente alla quota del tetto del volume, cioè
	# nello stesso piano della faccia di sopra del muro: le due facce si
	# contendevano ogni pixel, e dall'alto i tetti piani venivano a strisce
	# del colore dell'intonaco (le «terrazze gialle a righe nere» delle
	# foto dal Vomero). Alzata di tre centimetri, vince sempre lei.
	_pezzo(centro + Vector3(0, -0.03, 0), Vector3(dim.x, 0.12, dim.y),
		guaina, "tetto_piano")
	# Il cordolo perimetrale: due centimetri di rilievo che al sole fanno la
	# riga d'ombra, ed e' quella che fa capire che il tetto e' un piano
	# calpestabile e non una tampa dipinta.
	var cordolo := Tex.flat(Color(q["cornicione"]).darkened(0.1), 0.95)
	for s in [[dim.x, 0.3, 0.0, dim.y / 2.0], [dim.x, 0.3, 0.0, -dim.y / 2.0],
			[0.3, dim.y, dim.x / 2.0, 0.0], [0.3, dim.y, -dim.x / 2.0, 0.0]]:
		_pezzo(centro + Vector3(float(s[2]), 0.12, float(s[3])),
			Vector3(float(s[0]), 0.24, float(s[1])), cordolo, "cordolo_tetto")


# ---------------------------------------------------------------------------
# I mattoni di base
# ---------------------------------------------------------------------------

## Un volume di muro col materiale del quartiere.
##
## Larghezza fissa e altezza arrotondata a scalini di quattro metri: così i
## palazzi si raggruppano in una manciata di materiali per quartiere invece
## che in uno per palazzo (un MultiMesh vuole lo stesso materiale per tutte
## le istanze), e la texture resta alla scala giusta comunque.
func _muro_semplice(centro: Vector3, dim: Vector3, q: Dictionary,
		indice: int) -> void:
	var muri: Array = q["muri"]
	var tinte: Array = q["tinte"]
	var nome: String = str(muri[abs(indice) % muri.size()])
	var i_tinta: int = abs(indice / 3) % tinte.size()
	var tinta: Color = tinte[i_tinta]
	# **'A chiave d''o gruppo mo è cchiù corta, e chesto è 'nu guadagno.**
	#
	# Prima il materiale dipendeva dalla misura del muro, quindi la chiave
	# doveva contenerla: `muro_tufo_2_4x6` e `muro_tufo_2_5x6` erano due
	# gruppi diversi con la stessa faccia, e la città si ritrovava con
	# centinaia di MultiMesh da poche istanze l'uno. Adesso la fotografia si
	# appoggia al mondo e il materiale non sa più quanto è grande il muro:
	# tutte le campate con lo stesso intonaco e la stessa tinta finiscono in
	# un gruppo solo.
	var mat := Tex.facciata(nome, maxf(dim.x, dim.z), dim.y, tinta)
	_pezzo(centro, dim, mat, "muro_%s_%d" % [nome, i_tinta])


## Un pezzo di geometria: cubo unitario scalato, raggruppato per tipo.
func _pezzo(centro: Vector3, dim: Vector3, mat: Material, tipo: String,
		rot_z: float = 0.0) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _cubo
	mi.position = centro
	mi.scale = dim
	if absf(rot_z) > 0.0001:
		mi.rotation.z = rot_z
	mi.material_override = mat
	_batched(tipo, mi)


## La scala di un vettore lungo la facciata: `l` in orizzontale, `h` in
## altezza, `p` in profondità. Serve perché una facciata può guardare lungo
## x o lungo z e le tre misure vanno assegnate agli assi giusti.
func _spessa(fuori: Vector3, l: float, h: float, p: float) -> Vector3:
	if absf(fuori.z) > 0.5:
		return Vector3(l, h, p)
	return Vector3(p, h, l)


# ---------------------------------------------------------------------------
# I pezzi della facciata
# ---------------------------------------------------------------------------

## Il piano terra: serranda, portone, muro di manifesti o vetrina buona.
## Sopra ci va lo zoccolo, che è la fascia bassa di pietra o d'intonaco
## rovinato — ed è quella che, da sola, dice in che quartiere stai.
func _piano_terra(faccia: Vector3, fuori: Vector3, largo: float,
		q: Dictionary, indice: int, rng: RandomNumberGenerator) -> void:
	var lungo := Vector3(fuori.z, 0.0, -fuori.x)
	var alto_zoc: float = 3.4 if bool(q["marcapiano"]) else 2.6
	var zoc := Tex.mondo(str(q["zoccolo"]), Color(q["zoccolo_tinta"]), 0.93)
	_pezzo(faccia + Vector3(0, alto_zoc / 2.0, 0) - fuori * 0.04,
		_spessa(fuori, largo, alto_zoc, 0.18), zoc, "zoccolo_" + str(q["zoccolo"]))

	var elenco: Array = q["pt"]
	var quanti := int(maxf(1.0, floorf(largo / 3.4)))
	for i in range(quanti):
		var off: float = -largo / 2.0 + largo * (float(i) + 0.5) / float(quanti)
		var p: Vector3 = faccia + lungo * off
		var che: String = str(elenco[(indice + i) % elenco.size()])
		match che:
			"serranda":
				_pezzo(p + Vector3(0, 1.15, 0) + fuori * 0.06,
					_spessa(fuori, 2.2, 2.3, 0.12),
					Tex.mondo("serranda", Color.WHITE, 0.7),
					"pt_serranda")
				if rng.randf() < 0.5:
					_insegnetta(p, fuori, rng)
				# **'A grata d''a cantina** (0.60): una serranda su tre ha
				# accanto la bocca di lupo del magazzino di sotto, a trenta
				# centimetri da terra. Si sceglie col numero della campata e
				# non col caso, così il resto della città non si sposta.
				if (indice + i) % 3 == 1:
					_pezzo_modello("griglia_bassa", p + lungo * 1.42
						+ Vector3(0, 0.32, 0) + fuori * 0.07, "pt_griglia",
						atan2(fuori.x, fuori.z))
			"portone":
				_portone(p, fuori, q)
			"vetrina":
				_vetrina_buona(p, fuori, q, indice + i)
			_:
				# **'O vascio** (0.60): metà dei muri di manifesti diventano
				# un basso — la porta di legno, la finestrella con la grata
				# e i vasi sulla soglia. Il piano terra di Napoli è fatto di
				# case, non solo di botteghe e portoni.
				if (indice + i) % 2 == 0 and Models.has_model("porta_vascio"):
					_vascio_pt(p, fuori, q, indice + i)
				else:
					_pezzo(p + Vector3(0, 1.0, 0) + fuori * 0.05,
						_spessa(fuori, 2.6, 2.0, 0.1),
						Tex.mondo("manifesti", Color.WHITE, 0.95),
						"pt_manifesti")


## Il portone: due battenti scuri dentro a una cornice di pietra. La cornice
## è quello che lo fa sembrare un ingresso e non un buco.
func _portone(p: Vector3, fuori: Vector3, q: Dictionary) -> void:
	var pietra := Tex.mondo(str(q["zoccolo"]), Color(q["zoccolo_tinta"]).lightened(0.12), 0.9)
	_pezzo(p + Vector3(0, 1.55, 0) + fuori * 0.10,
		_spessa(fuori, 2.3, 3.1, 0.16), pietra, "portale")
	_pezzo(p + Vector3(0, 1.4, 0) + fuori * 0.16,
		_spessa(fuori, 1.6, 2.7, 0.1),
		Tex.get_material("portone", Vector2(1.0, 1.0), 0.85), "pt_portone")
	# L'architrave, che sporge un dito.
	_pezzo(p + Vector3(0, 3.2, 0) + fuori * 0.18,
		_spessa(fuori, 2.6, 0.26, 0.2), pietra, "architrave")
	_segna_portone(p, fuori)
	# **'A lampadina d''o purtone** (0.60): un portone su quattro ha sopra la
	# plafoniera a tartaruga (PSX), quella con la grata. Chi sceglie è la
	# posizione, non il caso.
	if absi(int(p.x * 7.0) + int(p.z * 13.0)) % 4 == 0:
		_pezzo_modello("lampada_muro", p + Vector3(0, 3.62, 0) + fuori * 0.2,
			"portone_lampada", atan2(fuori.x, fuori.z))


## **'O vascio** (0.60): la casa a piano terra, con la porta sulla strada.
##
## La porta di legno (PSX, due modelli), la finestrella accanto con la grata
## di ferro davanti (PSX) e il davanzale, e sulla soglia i vasi. Chi sta da
## che parte lo decide il numero della campata `k`. La porta si segna nel
## registro dei portoni, così davanti non ci si mette niente; e il posto si
## tiene in `_vasci_fore`, dove più tardi `RobbaPsx` va a mettere le sedie.
func _vascio_pt(p: Vector3, fuori: Vector3, q: Dictionary, k: int) -> void:
	var lungo := Vector3(fuori.z, 0.0, -fuori.x)
	var giro: float = atan2(fuori.x, fuori.z)
	var verso: float = 1.0 if k % 4 < 2 else -1.0
	var porta_c: Vector3 = p + lungo * (-0.8 * verso)
	var fen_c: Vector3 = p + lungo * (0.75 * verso)
	var pietra := Tex.mondo(str(q["zoccolo"]), Color(q["zoccolo_tinta"]).lightened(0.12), 0.9)
	var buio := Tex.flat(Color(0.05, 0.05, 0.06), 0.95)
	# Il vano, gli stipiti e l'architrave; poi il battente (il modello ha il
	# cardine all'origine e si apre verso −X: il centro sta mezzo metro più in
	# là lungo la facciata).
	_pezzo(porta_c + Vector3(0, 1.1, 0) + fuori * 0.055,
		_spessa(fuori, 1.1, 2.2, 0.04), buio, "vascio_vano")
	for d in [-0.62, 0.62]:
		_pezzo(porta_c + lungo * d + Vector3(0, 1.15, 0) + fuori * 0.1,
			_spessa(fuori, 0.16, 2.3, 0.1), pietra, "vascio_stipite")
	_pezzo(porta_c + Vector3(0, 2.33, 0) + fuori * 0.11,
		_spessa(fuori, 1.44, 0.18, 0.12), pietra, "vascio_architrave")
	var porta: String = "porta_vascio" if k % 3 != 0 else "porta_vascio2"
	_pezzo_modello(porta, porta_c + lungo * 0.5 + fuori * 0.12,
		"vascio_" + porta, giro)
	# La finestrella: il vetro scuro, il davanzale di pietra e la grata.
	_pezzo(fen_c + Vector3(0, 1.75, 0) + fuori * 0.07,
		_spessa(fuori, 0.95, 1.25, 0.04),
		Tex.flat(Color(0.10, 0.12, 0.14), 0.3, 0.3), "vascio_vetro")
	_pezzo(fen_c + Vector3(0, 1.09, 0) + fuori * 0.14,
		_spessa(fuori, 1.2, 0.07, 0.26), pietra, "vascio_davanzale")
	_pezzo_modello("sbarre_fenestra", fen_c + Vector3(0, 0.05, 0) + fuori * 0.04,
		"vascio_sbarre", giro)
	_segna_portone(porta_c, fuori)
	_vasci_fore.append([porta_c, fen_c, fuori])
	# I vasi sulla soglia, dal lato della finestra: uno, due o nessuno.
	var quanti: int = k % 3
	for i in quanti:
		var vq: Vector3 = porta_c + lungo * (verso * (0.86 + 0.34 * float(i))) \
			+ fuori * 0.3
		_pezzo_modello("vasetto" if (k + i) % 2 == 0 else "vasetto_vacante", vq,
			"vascio_vasi", giro + float(i) * 0.7)


## Le case a piano terra, per chi ci mette davanti le sedie (0.60):
## `[centro della porta, centro della finestra, verso la strada]`.
var _vasci_fore: Array = []


## **Annanz' ô purtone nun se mette niente.** I portoni sono pezzi di
## facciata, non attività: nessun registro li conosceva, e il divieto di
## sosta finiva piantato in mezzo al portone, il cassonetto pure. Adesso
## ogni portone si segna in una griglia a celle di quattro metri e
## `_perche_nun_sta` scarta tutto quello che tocca il rettangolo davanti
## (un metro per lato, un metro e dieci verso la strada).
var _portoni: Dictionary = {}   # Vector2i cella -> Array di [centro, fuori]
const CELLA_PORTONI := 4.0


func _segna_portone(p: Vector3, fuori: Vector3) -> void:
	var cella := Vector2i(floori(p.x / CELLA_PORTONI), floori(p.z / CELLA_PORTONI))
	if not _portoni.has(cella):
		_portoni[cella] = []
	(_portoni[cella] as Array).append([Vector2(p.x, p.z),
		Vector2(fuori.x, fuori.z).normalized()])


func _davanti_ô_portone(p: Vector3, r: float) -> bool:
	var p2 := Vector2(p.x, p.z)
	var c0 := Vector2i(floori(p.x / CELLA_PORTONI), floori(p.z / CELLA_PORTONI))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var lista = _portoni.get(c0 + Vector2i(dx, dz))
			if lista == null:
				continue
			for d in lista:
				var rel: Vector2 = p2 - (d[0] as Vector2)
				var f: Vector2 = d[1]
				var avanti: float = rel.dot(f)
				var lato: float = absf(rel.dot(Vector2(f.y, -f.x)))
				if avanti > -0.3 - r and avanti < 1.1 + r and lato < 1.0 + r:
					return true
	return false


## La vetrina dei quartieri buoni: vetro grande, montanti scuri, insegna
## discreta. Niente tende a righe: quelle stanno nei Quartieri.
## **Perche' l'insegna e' colorata e non piu' color legno.**
##
## La fascia sopra alla vetrina era dello stesso marrone scurissimo dei
## montanti (0,20 0,17 0,14). Presa da sola andava bene; ma il piano terra
## mette una vetrina ogni 3,4 metri e la fascia e' larga 3,1, quindi su una
## facciata da quindici metri se ne allineavano quattro **attaccate**. Il
## risultato era una barra nera continua sopra a tutte le botteghe, in
## ombra sotto al palazzo: da lontano sembrava una fessura nel muro, e
## nelle foto era la prima cosa che si notava.
##
## Adesso ogni bottega tiene la sua insegna di un colore suo, presa da una
## fila fissa in base a dov'e': le quattro affiancate non si fondono piu' —
## si leggono come quattro negozi, che e' quello che sono.
const INSEGNE := [
	Color(0.62, 0.16, 0.14), Color(0.16, 0.30, 0.46),
	Color(0.18, 0.38, 0.24), Color(0.66, 0.50, 0.14),
	Color(0.44, 0.20, 0.38), Color(0.14, 0.36, 0.40),
]

func _vetrina_buona(p: Vector3, fuori: Vector3, q: Dictionary,
		seme: int = 0) -> void:
	var lungo := Vector3(fuori.z, 0.0, -fuori.x)
	_pezzo(p + Vector3(0, 1.45, 0) + fuori * 0.08,
		_spessa(fuori, 2.7, 2.5, 0.1),
		Tex.flat(Color(0.12, 0.14, 0.17), 0.35, 0.3), "vetrina_vetro")
	var legno := Tex.flat(Color(0.24, 0.20, 0.17), 0.7, 0.2)
	for d in [-1.4, 1.4]:
		_pezzo(p + lungo * d + Vector3(0, 1.5, 0) + fuori * 0.12,
			_spessa(fuori, 0.28, 2.7, 0.16), legno, "vetrina_montante")
	var tinta: Color = INSEGNE[abs(seme) % INSEGNE.size()]
	# Larga 2,9 e non 3,1: due insegne di fila lasciano mezzo metro di muro
	# in mezzo, e si vede che sono due.
	_pezzo(p + Vector3(0, 2.86, 0) + fuori * 0.14,
		_spessa(fuori, 2.9, 0.36, 0.2),
		Tex.flat(tinta, 0.72), "vetrina_fascia_%d" % (abs(seme) % INSEGNE.size()))
	# Il bordo chiaro sotto all'insegna: e' il filo di luce che stacca
	# l'insegna dal buio della vetrina.
	_pezzo(p + Vector3(0, 2.66, 0) + fuori * 0.16,
		_spessa(fuori, 2.9, 0.06, 0.22),
		Tex.flat(Color(q["cornicione"]).lightened(0.18), 0.8), "vetrina_filo")
	# L'ottone della soglia.
	_pezzo(p + Vector3(0, 0.06, 0) + fuori * 0.2,
		_spessa(fuori, 3.0, 0.12, 0.34),
		Tex.flat(Color(q["cornicione"]).lightened(0.1), 0.6), "soglia")


func _insegnetta(p: Vector3, fuori: Vector3, rng: RandomNumberGenerator) -> void:
	_pezzo(p + Vector3(0, 2.65, 0) + fuori * 0.16,
		_spessa(fuori, 1.9, 0.42, 0.14),
		Tex.flat([Color(0.72, 0.20, 0.18), Color(0.18, 0.36, 0.55),
			Color(0.20, 0.44, 0.26), Color(0.75, 0.58, 0.16),
		][rng.randi() % 4], 0.9), "insegnetta")


## Le finestre dei piani alti: vetro, cornice di pietra intorno, davanzale
## sotto e le persiane ai lati.
##
## La cornice è il pezzo che rende: senza, una finestra è un rettangolo
## nero incollato sul muro; con, diventa un buco in una parete spessa.
func _finestre(faccia: Vector3, fuori: Vector3, largo: float, piani: int,
		q: Dictionary, rng: RandomNumberGenerator) -> void:
	var lungo := Vector3(fuori.z, 0.0, -fuori.x)
	var colonne := int(maxf(1.0, floorf(largo / 2.7)))

	# **Il vetro riflette il cielo.**
	#
	# Era quasi nero e quasi opaco (rugosita' 0.5) per una ragione buona:
	# con lo specchio pieno le duemilatrecento finestre della citta'
	# diventavano altrettanti punti che scintillavano a ogni passo. Ma il
	# rimedio era peggio del male — un buco nero in ogni facciata, e da
	# lontano i palazzi sembravano crivellati.
	#
	# La via di mezzo e' un vetro dielettrico: rugosita' 0.14, METALLICITA'
	# ZERO. Cosi' riflette la volta del cielo — che e' quello che si vede
	# davvero guardando una finestra dalla strada — ma non fa il lampo del
	# sole, perche' senza metallo il riflesso speculare resta debole e
	# largo. Il colore sotto resta scuro: dentro casa e' buio.
	var vetro := Tex.flat(Color(0.055, 0.075, 0.105), 0.14, 0.0)
	var persiana := Tex.flat(Color(q["persiane"]), 0.92)
	# La cornice della finestra va piu' SCURA del muro, non piu' chiara: e'
	# pietra dentro a un'apertura, quindi sta in ombra. Schiarendola, nei
	# quartieri chiari le finestre diventavano barre luminose.
	var pietra := Tex.flat(Color(q["cornicione"]).darkened(0.22), 0.92)
	# Il fondo dell'apertura: quasi nero, e sta piu' indietro di tutto. E'
	# quello che si vede fra il vetro e il muro quando ci passi accanto di
	# sbieco, ed e' la ragione per cui adesso una finestra ha uno spessore.
	var buio := Tex.flat(Color(0.03, 0.03, 0.04), 1.0)
	var traversa := Tex.flat(Color(q["cornicione"]).lightened(0.28), 0.75)

	for pi in range(piani):
		# Il centro della finestra sta al centro del suo piano: davanzale a
		# 62 cm dal pavimento, finestra alta 1,86, e restano 62 cm fino al
		# soffitto. E' la griglia di _alt_piani, quindi l'ultima riga di
		# finestre finisce sempre sotto al cornicione, per costruzione e non
		# per fortuna.
		var y: float = _y_davanzale(pi) + 0.93
		for i in range(colonne):
			var off: float = -largo / 2.0 + largo * (float(i) + 0.5) / float(colonne)
			var base: Vector3 = faccia + lungo * off + Vector3(0, y, 0)

			# **La finestra e' un buco, non un adesivo.**
			#
			# Prima erano tre piastre appiccicate una sopra l'altra e —
			# errore vero — il vetro stava PIU' AVANTI della cornice, cioe'
			# fuori dal muro. Adesso la sequenza e' quella di un muro
			# spesso: il fondo scuro a dodici centimetri dentro, il vetro a
			# sei dentro, la mazzetta di pietra a filo e il davanzale che
			# sporge. E la cornice non e' piu' una lastra ma quattro
			# listelli, se no coprirebbe il vetro che sta dietro.
			_pezzo(base - fuori * 0.12, _spessa(fuori, 1.30, 1.74, 0.04),
				buio, "vano_fin")
			_pezzo(base - fuori * 0.06, _spessa(fuori, 1.22, 1.66, 0.03),
				vetro, "vetro")
			# La traversa e il montante: due listelli sottili che dividono
			# il vetro in quattro. E' il dettaglio che, da solo, fa leggere
			# "finestra" invece di "rettangolo".
			_pezzo(base - fuori * 0.05, _spessa(fuori, 1.22, 0.05, 0.04),
				traversa, "traversa")
			_pezzo(base - fuori * 0.05, _spessa(fuori, 0.05, 1.66, 0.04),
				traversa, "traversa")

			# I quattro listelli della mazzetta.
			for lato in range(4):
				var pz: Vector3
				var dim: Vector3
				match lato:
					0: # sopra
						pz = base + Vector3(0, 0.90, 0)
						dim = _spessa(fuori, 1.46, 0.14, 0.12)
					1: # sotto
						pz = base + Vector3(0, -0.90, 0)
						dim = _spessa(fuori, 1.46, 0.14, 0.12)
					2: # sinistra
						pz = base + lungo * -0.66
						dim = _spessa(fuori, 0.14, 1.94, 0.12)
					_: # destra
						pz = base + lungo * 0.66
						dim = _spessa(fuori, 0.14, 1.94, 0.12)
				_pezzo(pz + fuori * 0.02, dim, pietra, "cornice_fin")

			# il davanzale
			_pezzo(base + Vector3(0, -0.99, 0) + fuori * 0.10,
				_spessa(fuori, 1.66, 0.12, 0.28), pietra, "davanzale")

			# **Le finestre accese.** Una su sei ha la luce dentro, e si
			# vede solo di notte: il gruppo intero compare al tramonto. E'
			# la cosa che cambia di piu' il quartiere al buio — senza,
			# calava la notte e la citta' diventava un cimitero.
			if rng.randf() < 0.17:
				_pezzo(base - fuori * 0.055,
					_spessa(fuori, 1.20, 1.62, 0.02),
					_mat_finestra_accesa(rng), "vetro_luce")

			var quante := 2 if rng.randf() < 0.7 else 1
			for k in range(quante):
				var d: float = (-0.86 if k == 0 else 0.86)
				_pezzo(base + lungo * d + fuori * 0.13,
					_spessa(fuori, 0.5, 1.75, 0.07), persiana, "persiana")

			# **'O condizionatore appiso 'a fore.** Uno su tre, di fianco
			# alla finestra e un po' più in basso — che è dove li mettono
			# davvero, perché il tubo deve scendere. È il dettaglio che
			# data un palazzo italiano agli anni Duemila, e senza si vede
			# che manca qualcosa anche senza sapere cosa.
			_condizionatore(base + lungo * 1.35 + Vector3(0, -0.55, 0),
				fuori, rng)


## Il giallo di una stanza accesa vista da fuori. Tre tonalita' appena
## diverse: una citta' in cui tutte le finestre hanno la stessa lampadina
## sembra un plastico.
func _mat_finestra_accesa(rng: RandomNumberGenerator) -> StandardMaterial3D:
	var tinte := [Color(1.0, 0.78, 0.42), Color(1.0, 0.86, 0.58),
		Color(0.92, 0.88, 0.72)]
	return Tex.flat(tinte[rng.randi() % tinte.size()], 0.6, 0.0, 1.8)


## I marcapiani: la fascia orizzontale che divide un piano dall'altro. È il
## segno che distingue un palazzo costruito da un muratore con l'architetto
## da uno tirato su come veniva.
##
## Sta esattamente sul SOLAIO, cioè al confine fra due piani della griglia.
## Prima partiva da 3,6 e saliva di 3,1 per conto suo, e finiva a tagliare
## le finestre a mezza altezza invece di passarci sotto.
func _marcapiani(faccia: Vector3, fuori: Vector3, largo: float, piani: int,
		q: Dictionary) -> void:
	var mat := Tex.flat(Color(q["cornicione"]).lightened(0.1), 0.93)
	for pi in range(piani):
		var y: float = PIANO_TERRA + float(pi) * PIANO
		_pezzo(faccia + Vector3(0, y, 0) + fuori * 0.09,
			_spessa(fuori, largo, 0.22, 0.24), mat, "marcapiano")


## Il balcone. Tre stili, e si riconoscono da lontano:
##  - "ferro": mensola sottile e ringhiera nera. I Quartieri, la Sanità.
##  - "pietra": balaustra piena di pietra chiara. La Riviera, il Rione.
##  - "bow": il bow-window vetrato che sporge. Solo il Vomero.
func _balcone(faccia: Vector3, fuori: Vector3, largo: float, y: float,
		q: Dictionary) -> void:
	var lungo := Vector3(fuori.z, 0.0, -fuori.x)
	var w: float = minf(largo * 0.6, 4.2)
	var stile := str(q["stile_balcone"])

	if stile == "bow":
		# Il bow-window: un volume vetrato che sporge, col suo tettuccio.
		var vetro := Tex.flat(Color(0.13, 0.16, 0.19), 0.4, 0.3)
		var telaio := Tex.flat(Color(q["cornicione"]).darkened(0.25), 0.7)
		_pezzo(faccia + Vector3(0, y + 0.45, 0) + fuori * 0.62,
			_spessa(fuori, w * 0.8, 2.5, 1.2), vetro, "bow_vetro")
		for d in [-0.5, 0.5]:
			_pezzo(faccia + lungo * (w * 0.8 * d) + Vector3(0, y + 0.45, 0)
				+ fuori * 0.62, _spessa(fuori, 0.16, 2.6, 1.3), telaio,
				"bow_telaio")
		_pezzo(faccia + Vector3(0, y + 1.78, 0) + fuori * 0.66,
			_spessa(fuori, w * 0.9, 0.2, 1.5), telaio, "bow_tetto")
		_pezzo(faccia + Vector3(0, y - 0.86, 0) + fuori * 0.66,
			_spessa(fuori, w * 0.9, 0.24, 1.5), telaio, "bow_base")
		return

	var pietra := Tex.flat(Color(q["cornicione"]).lightened(0.15), 0.94)
	_pezzo(faccia + Vector3(0, y - 0.6, 0) + fuori * 0.45,
		_spessa(fuori, w, 0.18, 0.95), pietra, "mensola")

	if stile == "pietra":
		# Balaustra piena: un parapetto di pietra con i pilastrini.
		_pezzo(faccia + Vector3(0, y - 0.06, 0) + fuori * 0.86,
			_spessa(fuori, w, 0.92, 0.16), pietra, "balaustra")
		var n := int(w / 0.55)
		for i in range(n):
			var d: float = -w / 2.0 + w * (float(i) + 0.5) / float(n)
			_pezzo(faccia + lungo * d + Vector3(0, y - 0.1, 0) + fuori * 0.72,
				_spessa(fuori, 0.16, 0.7, 0.16), pietra, "pilastrino")
		_pezzo(faccia + Vector3(0, y + 0.42, 0) + fuori * 0.86,
			_spessa(fuori, w + 0.16, 0.14, 0.3), pietra, "corrimano")
		_piante_balcone(faccia, fuori, lungo, w, y - 0.51, 0.45)
		return

	if stile == "cemento":
		# Il parapetto pieno di cemento, largo e tozzo: il balcone dei
		# palazzoni anni Settanta. Non ha ringhiera, ha una lastra — e
		# siccome corre per tutta la campata, da lontano il palazzo si legge
		# a fasce orizzontali invece che a buchi. È quello che li distingue.
		var cemento := Tex.flat(Color(0.72, 0.70, 0.67), 0.95)
		var largo_bal: float = largo * 0.92
		_pezzo(faccia + Vector3(0, y - 0.6, 0) + fuori * 0.62,
			_spessa(fuori, largo_bal, 0.2, 1.3), cemento, "soletta")
		_pezzo(faccia + Vector3(0, y - 0.02, 0) + fuori * 1.2,
			_spessa(fuori, largo_bal, 1.0, 0.14), cemento, "parapetto")
		# La colatura nera sotto la soletta: è il dettaglio che invecchia
		# questi palazzi più di qualunque crepa.
		_pezzo(faccia + Vector3(0, y - 0.78, 0) + fuori * 0.06,
			_spessa(fuori, largo_bal, 0.5, 0.04),
			Tex.flat(Color(0.34, 0.32, 0.30), 0.98), "colatura")
		_piante_balcone(faccia, fuori, lungo, largo_bal * 0.8, y - 0.5, 0.75)
		return

	# **"ferro": la ringhiera, e questa volta con i ferri.**
	#
	# Era una lastra piena: un parallelepipedo largo fino a quattro metri e
	# due, alto novanta, di colore 0,14 — cioe' quasi nero. Da solo poteva
	# anche passare; ma le campate di un palazzo ne mettono una accanto
	# all'altra su tutto il fronte, e il risultato nelle foto era una
	# **barra nera continua** sopra alle botteghe, che sembrava una fessura
	# nella facciata. Era la cosa piu' brutta di tutta la citta'.
	#
	# Una ringhiera vera e' fatta per il novanta per cento d'aria. Adesso
	# c'e' il corrimano, il ferro basso e i balaustrini verticali ogni
	# sedici centimetri: dietro ci passa la luce, si vede il muro, e da
	# lontano il balcone si legge come un balcone. Costa qualche scatolina
	# in piu' per campata, ma finiscono tutte nello stesso MultiMesh —
	# stesso materiale, stessa mesh, una draw call sola per tutta la citta'.
	var ferro := Tex.flat(Color(0.14, 0.15, 0.16), 0.62, 0.3)
	# Corrimano e traversa bassa: sono i due orizzontali che tengono su i
	# ferri, e sono anche quelli che danno il segno del balcone da lontano.
	_pezzo(faccia + Vector3(0, y + 0.36, 0) + fuori * 0.88,
		_spessa(fuori, w + 0.08, 0.07, 0.09), ferro, "corrimano_ferro")
	_pezzo(faccia + Vector3(0, y - 0.46, 0) + fuori * 0.88,
		_spessa(fuori, w, 0.05, 0.06), ferro, "traversa_ferro")
	var quanti_ferri: int = clampi(int(round(w / 0.16)), 4, 30)
	# **I ferri adesso sono ferri battuti, non stecchini.**
	# Il modello ha l'origine alla base e sta in piedi da solo: il punto
	# d'appoggio e' il centro meno mezza altezza. Se il file manca si torna
	# alla scatolina di prima, che funzionava.
	var giro_ferro: float = atan2(-lungo.x, -lungo.z)
	for i in range(quanti_ferri + 1):
		var t: float = float(i) / float(quanti_ferri)
		var centro_ferro: Vector3 = faccia + lungo * (w * (t - 0.5)) \
			+ Vector3(0, y - 0.06, 0) + fuori * 0.88
		if _pezzo_modello("balaustrino", centro_ferro - Vector3(0, 0.43, 0),
				"balaustrino", giro_ferro):
			continue
		_pezzo(centro_ferro, _spessa(fuori, 0.035, 0.86, 0.035), ferro,
			"balaustrino")
	# I due montanti d'angolo, che chiudono la ringhiera sui fianchi. Anche
	# questi erano lastre piene (0,9 per 0,9): adesso sono due tubi.
	for d in [-0.5, 0.5]:
		var ang: Vector3 = faccia + lungo * (w * d) + Vector3(0, y - 0.06, 0)
		_pezzo(ang + fuori * 0.88, _spessa(fuori, 0.06, 0.92, 0.06), ferro,
			"montante_ferro")
		_pezzo(ang + fuori * 0.45, _spessa(fuori, 0.06, 0.92, 0.06), ferro,
			"montante_ferro")
		_pezzo(ang + Vector3(0, 0.36, 0) + fuori * 0.66,
			_spessa(fuori, 0.06, 0.07, 0.9), ferro, "corrimano_lat")
	# Le piante: vasi veri (0.59, vedi `_piante_balcone`). La scatola
	# verde di prima resta solo se i modelli non ci sono.
	if Models.has_model("fiori_1"):
		_piante_balcone(faccia, fuori, lungo, w, y - 0.51, 0.6)
	else:
		_pezzo(faccia + lungo * (w * 0.32) + Vector3(0, y - 0.18, 0) + fuori * 0.6,
			Vector3(0.34, 0.7, 0.34),
			Tex.flat(Color(0.24, 0.40, 0.22), 0.95), "pianta_balcone")
	_sciarpa_ncopp_ô_balcone(faccia, fuori, lungo, w, y)


## **'A sciarpa d''o Napule stesa 'ncopp'â ringhiera** (0.57).
##
## `sciarpa_napoli.jpg` era l'unica texture della cartella che non stava in
## nessun posto del gioco. Il capo ha chiesto di usarle tutte, e questa
## aveva già il suo posto scritto in faccia: **'e ringhiere attuorno ô
## stadio**.
##
## Perché sui balconi e non su un muro: una sciarpa appesa a un muro è un
## poster, una sciarpa **stesa sulla ringhiera** è una persona che abita lì
## e domenica guarda la partita. E soprattutto si mette da sola al posto
## giusto — viene appesa al balcone che è appena stato costruito, quindi
## non c'è nessun elenco di coordinate da tenere allineato a mano, che è il
## modo in cui in questo progetto le cose finiscono dentro ai muri.
##
## **E la quantità dice dove stai.** Attorno allo stadio una ringhiera su
## tre; nel resto della città una su venticinque — abbastanza da incontrarne
## una ogni tanto e capire che il quartiere è quello, non abbastanza da
## sembrare una fiera.
const SCIARPA_STADIO := Rect2(104.0, 0.0, 84.0, 66.0)
const SCIARPA_VICINO: float = 0.34
const SCIARPA_LUNTANO: float = 0.04


func _sciarpa_ncopp_ô_balcone(faccia: Vector3, fuori: Vector3,
		lungo: Vector3, w: float, y: float) -> void:
	if _sciarpa_mat == null:
		var percorso := "res://assets/textures/sciarpa_napoli.jpg"
		if not ResourceLoader.exists(percorso):
			return
		_sciarpa_mat = StandardMaterial3D.new()
		_sciarpa_mat.albedo_texture = load(percorso)
		_sciarpa_mat.roughness = 0.97
		_sciarpa_mat.metallic = 0.0
		_sciarpa_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		# Una sciarpa si vede da tutt'e due i lati: senza questo, girandoci
		# intorno sparisce.
		_sciarpa_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var vicino: bool = SCIARPA_STADIO.has_point(Vector2(faccia.x, faccia.z))
	var quanto: float = SCIARPA_VICINO if vicino else SCIARPA_LUNTANO
	if _sciarpa_rng.randf() >= quanto:
		return
	# Stesa fuori dalla ringhiera, spostata di lato a caso: in mezzo esatto
	# sembrerebbe messa col righello.
	var dove: Vector3 = faccia \
		+ lungo * (w * _sciarpa_rng.randf_range(-0.34, 0.34)) \
		+ Vector3(0, y - 0.52, 0) + fuori * 0.94
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.32, 1.30)
	mi.mesh = q
	mi.material_override = _sciarpa_mat
	# Il quad guarda +Z: si gira perché guardi fuori dalla facciata.
	mi.rotation.y = atan2(fuori.x, fuori.z)
	mi.position = dove
	add_child(mi)


var _sciarpa_mat: StandardMaterial3D = null
## Seme fisso: le sciarpe stanno sempre agli stessi balconi. Un quartiere
## che cambia decorazione a ogni partita non è un quartiere.
var _sciarpa_rng: RandomNumberGenerator = _sciarpa_semente()


static func _sciarpa_semente() -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = 5719
	return r


## Il tetto a falda di coppi. Due spioventi e il colmo: cambia la sagoma
## contro il cielo, che è il modo più veloce per far capire da lontano che
## sei in un altro quartiere.
func _tetto_a_falda(faccia: Vector3, fuori: Vector3, largo: float,
		h: float) -> void:
	# **'E ccoppi.** Fino alla 0.45 la falda usava la texture del cotto — che
	# è la stessa dei pavimenti, e infatti da una salita i tetti sembravano
	# piastrellati. Dalla 0.46 alla 0.59 usava `tetti_italiani.jpg`, che
	# prometteva «coppi veri presi dall'alto» ed era **un collage di foto
	# aeree di Venezia**: canali, barche e palazzi rimpiccioliti, ogni due
	# metri e venti. Dal Vomero i tetti sembravano coriandoli, e nessuno
	# aveva mai aperto il file per guardarlo.
	#
	# **Dalla 0.60 i coppi si disegnano** (`tools/genera_coppi.py`): file di
	# coppi e canali che scendono lungo la falda. Il gioco proietta la
	# texture dall'alto, quindi le colonne devono correre nel verso della
	# pendenza: `coppi` per le falde che scendono lungo z, `coppi_x` (la
	# stessa girata) per quelle che scendono lungo x.
	var coppi := Tex.mondo("coppi" if absf(fuori.z) > 0.5 else "coppi_x",
		Color.WHITE, 0.94)
	const PROF := 3.2
	const PEND := 1.5   # quanto è alta la falda
	for d in [-1.0, 1.0]:
		var mi := MeshInstance3D.new()
		mi.mesh = _cubo
		mi.position = faccia + Vector3(0, h + PEND / 2.0 - 0.1, 0) \
			- fuori * (PROF / 4.0) * d
		mi.scale = _spessa(fuori, largo + 0.5, 0.24, PROF / 2.0 + 0.5)
		# la falda si inclina intorno all'asse della facciata
		if absf(fuori.z) > 0.5:
			mi.rotation.x = atan2(PEND, PROF / 2.0) * d * signf(fuori.z)
		else:
			mi.rotation.z = -atan2(PEND, PROF / 2.0) * d * signf(fuori.x)
		mi.material_override = coppi
		_batched("falda", mi)
	_pezzo(faccia + Vector3(0, h + PEND, 0) - fuori * (PROF / 2.0),
		_spessa(fuori, largo + 0.3, 0.24, 0.5), coppi, "colmo")


## Antenne, parabole e comignoli.
##
## **Dalla 0.59 sono quelli di Pandazole** (vedi `ROBA_TETTO`): prima erano
## tre scatole — un bastone grigio, un cubo di mattoni, un parallelepipedo
## bianco — e da un balcone del Vomero si capiva che erano scatole. Le
## scatole restano come ripiego, se un giorno i modelli mancassero. Un
## tetto vero non ha mai una cosa sola: metà delle volte, accanto, ce n'è
## un'altra.
func _roba_sul_tetto(pos: Vector3, rng: RandomNumberGenerator,
		dentro: Rect2 = Rect2()) -> void:
	var nome: String = _a_sorte(ROBA_TETTO, rng)
	var giro: float = float(rng.randi_range(0, 3)) * PI * 0.5 \
		+ rng.randf_range(-0.1, 0.1)
	if _panda(nome, pos, giro, "tetto"):
		if rng.randf() < 0.5:
			var p2: Vector3 = pos + Vector3(rng.randf_range(1.6, 2.8) \
				* (1.0 if rng.randf() < 0.5 else -1.0), 0.0,
				rng.randf_range(-1.6, 1.6))
			if dentro.size == Vector2.ZERO or dentro.has_point(Vector2(p2.x, p2.z)):
				_panda(_a_sorte(ROBA_TETTO, rng), p2,
					float(rng.randi_range(0, 3)) * PI * 0.5, "tetto")
		return
	var che := rng.randi() % 3
	match che:
		0:
			_pezzo(pos + Vector3(0, 0.9, 0), Vector3(0.12, 1.8, 0.12),
				Tex.flat(Color(0.5, 0.5, 0.52), 0.6, 0.25), "antenna")
		1:
			_pezzo(pos + Vector3(0, 0.55, 0), Vector3(0.7, 1.1, 0.7),
				Tex.flat(Color(0.58, 0.54, 0.48), 0.95), "comignolo")
		_:
			_pezzo(pos + Vector3(0, 0.5, 0), Vector3(0.8, 0.9, 0.55),
				Tex.flat(Color(0.82, 0.82, 0.8), 0.8), "serbatoio")


# ---------------------------------------------------------------------------
# La vita del vicolo
# ---------------------------------------------------------------------------

## Quello che rende un vicolo un vicolo, e che nessuna geometria da sola può
## dare: i panni stesi da un muro all'altro, le lanterne appese alle facciate
## invece dei lampioni (in quattro metri un palo non ci sta), le edicole
## votive agli incroci, i motorini appoggiati al muro.
##
## Di tutte queste, i panni stesi sono quella che conta di più. Sono anche
## l'unica cosa che si vede alzando gli occhi, ed è alzando gli occhi che si
## capisce quanto è stretto un posto.
func _build_vita_di_vicolo() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260826
	for s in STRADE:
		var w: float = s[2] - s[0]
		var l: float = s[3] - s[1]
		var lungo_z: bool = l > w
		var luce: float = w if lungo_z else l      # la luce fra i due muri
		var corsa: float = l if lungo_z else w
		if luce > 5.5:
			# Strada larga: lampioni normali sui due bordi.
			var passo_l := 24.0
			var n_l := int(corsa / passo_l)
			for i in range(1, n_l):
				var t: float = s[1] + i * passo_l if lungo_z else s[0] + i * passo_l
				if lungo_z:
					_lampione(Vector3(s[0] + 1.0, 0.0, t))
					_lampione(Vector3(s[2] - 1.0, 0.0, t))
				else:
					_lampione(Vector3(t, 0.0, s[1] + 1.0))
					_lampione(Vector3(t, 0.0, s[3] - 1.0))
			continue
		if corsa < 14.0:
			continue

		# Vicolo. Panni ogni sedici metri, saltandone un terzo.
		var passo := 16.0
		var n := int(corsa / passo)
		for i in range(1, n + 1):
			if rng.randf() < 0.34:
				continue
			var t2: float = (s[1] if lungo_z else s[0]) + i * passo \
				- passo * 0.5
			var a: Vector3
			var b: Vector3
			if lungo_z:
				a = Vector3(s[0] + 0.1, 0, t2)
				b = Vector3(s[2] - 0.1, 0, t2)
			else:
				a = Vector3(t2, 0, s[1] + 0.1)
				b = Vector3(t2, 0, s[3] - 0.1)
			# **'E panne se stennono sulo dint'ê vicule stritte.**
			#
			# Il capo vede "oggetti volanti ovunque", e sono questi: una
			# corda tesa fra due palazzi di una strada larga venti metri
			# è **spessa otto centimetri**, cioè meno di un pixel a
			# quaranta metri di distanza. La corda sparisce e restano i
			# lenzuoli, sospesi in mezzo al cielo.
			#
			# La cura non è ingrossare la corda — è non tenderla dove non
			# la si tenderebbe. Nessuno stende i panni attraverso un
			# corso: si stende da finestra a finestra dentro a un vicolo,
			# e un vicolo è largo quattro o cinque metri.
			# E ai muri della galera i panni non si stendono (0.60).
			if a.distance_to(b) <= LUCE_MAX_PANNI \
					and not ncopp_a_galera(a) and not ncopp_a_galera(b):
				_panni(a, b, rng.randf_range(6.4, 9.2), rng)

		# Lanterne a muro, alternate da un lato e dall'altro.
		var passo_lan := 32.0
		var n_lan := int(corsa / passo_lan)
		for i in range(n_lan + 1):
			var t3: float = (s[1] if lungo_z else s[0]) + 12.0 + i * passo_lan
			if t3 > (s[3] if lungo_z else s[2]) - 4.0:
				break
			var muro: float = 0.25
			if lungo_z:
				var x: float = (s[0] + muro) if i % 2 == 0 else (s[2] - muro)
				_lanterna(Vector3(x, 0, t3),
					Vector3(1, 0, 0) if i % 2 == 0 else Vector3(-1, 0, 0))
			else:
				var z2: float = (s[1] + muro) if i % 2 == 0 else (s[3] - muro)
				_lanterna(Vector3(t3, 0, z2),
					Vector3(0, 0, 1) if i % 2 == 0 else Vector3(0, 0, -1))

		# Motorini appoggiati al muro: in un vicolo l'auto non ci passa, il
		# motorino sì, e infatti è pieno.
		var passo_mot := 21.0
		var n_mot := int(corsa / passo_mot)
		for i in range(n_mot):
			if rng.randf() < 0.4:
				continue
			var t4: float = (s[1] if lungo_z else s[0]) + 8.0 + i * passo_mot
			var p: Vector3
			var ang: float
			# A quarantaquattro centimetri dal muro (0.59), non a novanta: il
			# motorino è largo settantacinque, e a novanta metà manubrio stava
			# nella corsia libera del vicolo — e senza corpo. E storto di tre
			# gradi al massimo, non di otto: storto di otto, la ruota davanti
			# rientrava nella corsia.
			if lungo_z:
				p = Vector3(s[0] + 0.44 if i % 2 == 0 else s[2] - 0.44, 0, t4)
				ang = 0.0
			else:
				p = Vector3(t4, 0, s[1] + 0.44 if i % 2 == 0 else s[3] - 0.44)
				ang = 90.0
			# Né dentro a un vaso o a una giara messi prima, né dove non
			# potrebbe avere il corpo (0.59).
			var giro_m: float = deg_to_rad(ang + rng.randf_range(-3.0, 3.0))
			if not _scatola_libera(p, Vector3(0.75, 1.1, 1.85), giro_m, 0.05) \
					or not _puo_avere_corpo(p, Vector3(0.75, 1.1, 1.85), giro_m):
				continue
			# Né davanti ai manifesti della collezione, che si mettono dopo
			# e hanno il loro riparo (il cassonetto, le casse).
			var sul_manifesto := false
			for mf in POSTI_MANIFESTI:
				if Vector2(float(mf[1]), float(mf[2])).distance_to(Vector2(p.x, p.z)) < 3.0:
					sul_manifesto = true
			if sul_manifesto:
				continue
			# Né davanti al vascio: lì fuori ci stanno la lavatrice e la
			# bombola (vedi `_fore_ô_vascio`).
			if Vector2(p.x - VascioScript.PORTA_POS.x,
					p.z - VascioScript.PORTA_POS.z).length() < 3.6:
				continue
			var mot := Models.spawn_by_length("motorino", 1.85)
			if mot == null:
				continue
			mot.position = p
			mot.rotation.y = giro_m
			add_child(mot)
			_solido(p + Vector3(0, 0.55, 0), Vector3(0.75, 1.1, 1.85),
				mot.rotation.y)
			_lontananza(mot, 45.0)

	# Le edicole votive: agli incroci, dove uno si ferma un attimo.
	for p2 in [Vector3(11.0, 0, 62.5), Vector3(53.0, 0, 95.5),
			Vector3(105.0, 0, 62.5), Vector3(131.0, 0, 126.0),
			Vector3(53.0, 0, 154.0), Vector3(181.0, 0, 95.5),
			Vector3(105.0, 0, 126.0)]:
		_edicola_votiva(p2)


## Una corda da un muro all'altro con i panni appesi.
func _panni(a: Vector3, b: Vector3, h: float, rng: RandomNumberGenerator) -> void:
	var mezzo: Vector3 = (a + b) * 0.5 + Vector3(0, h, 0)
	var dir: Vector3 = b - a
	var luce: float = dir.length()
	if luce < 1.0:
		return
	var lungo_x: bool = absf(dir.x) > absf(dir.z)

	var corda := MeshInstance3D.new()
	corda.mesh = _cubo
	corda.position = mezzo
	# **La corda si deve VEDERE.**
	#
	# Era spessa tre centimetri e mezzo e di un beige chiaro: a dieci metri
	# spariva contro il cielo, e i lenzuoli restavano soli, appesi al
	# niente. E' questa la ragione principale per cui la citta' sembrava
	# piena di oggetti volanti — non erano oggetti sbagliati, era il filo
	# che non si vedeva. Otto centimetri e un colore scuro bastano: adesso
	# la corda si legge prima dei panni, e i panni ci stanno appesi.
	corda.scale = Vector3(luce, 0.08, 0.08) if lungo_x \
		else Vector3(0.08, 0.08, luce)
	corda.material_override = Tex.flat(Color(0.24, 0.22, 0.19), 0.95)
	_batched("corda", corda)

	var colori := [
		Color(0.94, 0.93, 0.90), Color(0.90, 0.92, 0.95),
		Color(0.86, 0.44, 0.40), Color(0.42, 0.55, 0.72),
		Color(0.95, 0.88, 0.58), Color(0.60, 0.72, 0.56),
		Color(0.92, 0.86, 0.82),
	]
	var quanti := rng.randi_range(4, 7)
	for i in range(quanti):
		var t: float = (float(i) + 0.5) / float(quanti)
		var lw: float = rng.randf_range(0.5, 0.95)
		var lh: float = rng.randf_range(0.7, 1.5)
		# Il bordo alto del panno sta SOPRA all'asse della corda, non cinque
		# centimetri sotto: cosi' i due si compenetrano e non resta mai la
		# fessura di luce che faceva sembrare il lenzuolo staccato.
		var pos: Vector3 = a.lerp(b, t) + Vector3(0, h - lh / 2.0 + 0.05, 0)
		var panno := MeshInstance3D.new()
		panno.mesh = _cubo
		panno.position = pos
		# Appena storto e appena spesso: un lenzuolo perfettamente piatto e
		# perfettamente verticale sembra un cartello.
		panno.rotation.z = rng.randf_range(-0.07, 0.07)
		panno.scale = Vector3(lw, lh, 0.03) if lungo_x \
			else Vector3(0.03, lh, lw)
		var m: StandardMaterial3D = Tex.flat(
			colori[rng.randi() % colori.size()], 0.96).duplicate()
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		panno.material_override = m
		# **'E mutande** (0.60): il secondo panno di una corda su due è un
		# paio di mutande (PSX), appese per l'elastico. Il caso si è già
		# tirato tutto, quindi il resto della città resta com'era.
		if i == 1 and int(luce * 10.0) % 2 == 0 and Models.has_model("mutanne"):
			panno.queue_free()
			var giro_p: float = 0.0 if lungo_x else PI * 0.5
			for j in [-0.2, 0.25]:
				var pm: Vector3 = a.lerp(b, t) + (dir.normalized() * j) \
					+ Vector3(0, h - 0.13, 0)
				_panda_t("mutanne", Transform3D(Basis(Vector3.UP, giro_p)
					* Basis(Vector3.RIGHT, PI * 0.5), pm), "panni")
			continue
		_batched("panno%d" % (i % colori.size()), panno)


## La lanterna appesa al muro: in un vicolo da quattro metri un palo della
## luce non ci starebbe, e infatti a Napoli sono attaccate alle facciate.
func _lanterna(pos: Vector3, fuori: Vector3) -> void:
	var braccio := MeshInstance3D.new()
	braccio.mesh = _cubo
	braccio.position = pos + Vector3(0, 5.0, 0) + fuori * 0.32
	braccio.scale = Vector3(0.7, 0.07, 0.07) if absf(fuori.x) > 0.5 \
		else Vector3(0.07, 0.07, 0.7)
	braccio.material_override = Tex.flat(Color(0.12, 0.13, 0.15), 0.5, 0.5)
	_batched("braccio", braccio)

	var lampada := MeshInstance3D.new()
	var gm := SphereMesh.new()
	gm.radius = 0.19
	gm.height = 0.38
	gm.radial_segments = 8
	gm.rings = 5
	lampada.mesh = gm
	lampada.position = pos + Vector3(0, 4.86, 0) + fuori * 0.62
	lampada.material_override = Tex.flat(
		Color(1.0, 0.93, 0.72), 0.9, 0.0, 1.7).duplicate()
	add_child(lampada)

	var luce := OmniLight3D.new()
	luce.position = lampada.position + Vector3(0, -0.2, 0)
	luce.light_color = Color(1.0, 0.84, 0.58)
	luce.light_energy = 1.6
	luce.omni_range = 10.0
	luce.shadow_enabled = false
	# In un vicolo non si vede lontano: la lanterna si può spegnere presto.
	luce.distance_fade_enabled = true
	luce.distance_fade_begin = 30.0
	luce.distance_fade_length = 10.0
	add_child(luce)
	if _ciclo:
		_ciclo.aggiungi_lampione(luce, lampada)


## Il muro buono per appoggiarci qualcosa vicino a un incrocio: la faccia
## dell'isolato più vicino che guarda verso il punto, a un metro dallo
## spigolo. Restituisce `[punto sul muro, normale verso la strada]`, o vuoto
## se non c'è un isolato vicino.
static func _muro_dell_angolo(pos: Vector3) -> Array:
	var meglio := INF
	var fuori: Array = []
	for b in ISOLATI:
		if e_galera(b):
			continue
		var x0: float = float(b[0])
		var z0: float = float(b[1])
		var x1: float = float(b[2])
		var z1: float = float(b[3])
		var cx: float = clampf(pos.x, x0, x1)
		var cz: float = clampf(pos.z, z0, z1)
		var d := Vector2(pos.x - cx, pos.z - cz)
		var dist: float = d.length()
		if dist < 0.01 or dist >= meglio or dist > 8.0:
			continue
		meglio = dist
		var n := Vector2(signf(d.x), 0.0) if absf(d.x) >= absf(d.y) \
			else Vector2(0.0, signf(d.y))
		var p := Vector2.ZERO
		if n.x != 0.0:
			p = Vector2(x0 if n.x < 0.0 else x1, clampf(pos.z, z0 + 1.0, z1 - 1.0))
		else:
			p = Vector2(clampf(pos.x, x0 + 1.0, x1 - 1.0), z0 if n.y < 0.0 else z1)
		fuori = [Vector3(p.x, 0.0, p.y), Vector3(n.x, 0.0, n.y)]
	return fuori


## L'edicola votiva: la nicchia col santo, la cornice dorata e i lumini.
## Non serve a niente, e sta lì apposta.
##
## **'A nicchia sta dint'ô muro** (0.59). Le sette edicole avevano come
## posto **il centro dell'incrocio**: la nicchia sospesa a due metri in
## mezzo alla strada, senza muro dietro, e sotto il corpo con cui ci si
## parla — una scatola invisibile di un metro e venti, solida, piantata nel
## punto dove passano tutti. Il giocatore ci sbatteva contro senza capire
## contro cosa; la griglia dei passanti la vedeva come un muro in mezzo al
## crocevia, e il cardine accanto al Vomero, chiuso da lei a nord e dalla
## scalinata a sud, era diventato un'isola dove i passanti restavano
## piantati (`prova_ntuppate`). Adesso il punto scritto è solo l'incrocio
## vicino a cui cercare: l'edicola va sul muro dell'isolato d'angolo più
## vicino, a un metro dallo spigolo, girata verso la strada.
func _edicola_votiva(incrocio: Vector3) -> void:
	var pos: Vector3 = incrocio
	var fuori := Vector3(0, 0, 1)
	var muro: Array = _muro_dell_angolo(incrocio)
	if not muro.is_empty():
		pos = muro[0]
		fuori = muro[1]
		# E non addosso a un portone: si scorre lungo il muro finché il
		# posto è libero, restando sulla stessa facciata.
		var lungo := Vector3(-fuori.z, 0.0, fuori.x)
		for passo in [0.0, 1.4, -1.4, 2.8, -2.8, 4.2, -4.2]:
			var q: Vector3 = pos + lungo * float(passo)
			if dint_ô_palazzo(q - fuori * 0.3, 0.0) \
					and not dint_ô_palazzo(q + fuori * 0.4, 0.0) \
					and not _davanti_ô_portone(q + fuori * 0.3, 0.7):
				pos = q
				break
	var giro: float = atan2(fuori.x, fuori.z)
	var root := Node3D.new()
	root.position = pos + fuori * 0.16 + Vector3(0, 2.1, 0)
	root.rotation.y = giro
	add_child(root)
	_lontananza(root, 40.0)

	# Il corpo con cui ci si parla. Sta piu' in basso della nicchia, a
	# altezza d'uomo: si mira a dove uno guarderebbe davvero. Appoggiato al
	# muro, sessanta centimetri di spessore: fuori dalla corsia libera.
	var utile := PostoUtileScript.new()
	utile.tipo = "edicola"
	utile.position = pos + fuori * 0.35
	utile.rotation.y = giro
	add_child(utile)
	var fu := CollisionShape3D.new()
	var bu := BoxShape3D.new()
	bu.size = Vector3(1.2, 2.6, 0.6)
	fu.shape = bu
	fu.position = Vector3(0, 1.6, 0)
	utile.add_child(fu)

	var nicchia := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.9, 1.2, 0.28)
	nicchia.mesh = bm
	nicchia.material_override = Tex.flat(Color(0.16, 0.14, 0.22), 0.9)
	root.add_child(nicchia)

	var cornice := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(1.06, 1.36, 0.2)
	cornice.mesh = cm
	cornice.position = Vector3(0, 0, -0.06)
	cornice.material_override = Tex.flat(Color(0.78, 0.62, 0.22), 0.35, 0.8)
	root.add_child(cornice)

	var santo := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.34, 0.7, 0.12)
	santo.mesh = sm
	santo.position = Vector3(0, -0.05, 0.14)
	santo.material_override = Tex.flat(Color(0.72, 0.68, 0.62), 0.9)
	root.add_child(santo)

	for d in [-0.3, 0.3]:
		var lume := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.11, 0.16, 0.11)
		lume.mesh = lm
		lume.position = Vector3(d, -0.5, 0.18)
		lume.material_override = Tex.flat(
			Color(0.95, 0.25, 0.18), 0.6, 0.0, 2.4).duplicate()
		root.add_child(lume)

	var luce := OmniLight3D.new()
	luce.position = Vector3(0, -0.3, 0.5)
	luce.light_color = Color(1.0, 0.42, 0.28)
	luce.light_energy = 0.9
	luce.omni_range = 3.4
	luce.shadow_enabled = false
	luce.distance_fade_enabled = true
	luce.distance_fade_begin = 20.0
	luce.distance_fade_length = 8.0
	root.add_child(luce)


## **'E lampiuncielle nun so' tutte eguale.**
##
## Sei modelli veri al posto di uno solo: ghisa a due bracci, globo triplo,
## globo singolo, stradale, doppio, ad arco. Il punto di averne sei non è
## la varietà per la varietà — è che una strada dove i lampioni sono tutti
## identici, alla stessa distanza, si legge come un rendering e non come un
## posto. A Napoli i lampioni li hanno cambiati tre volte in cinquant'anni
## e su una strada sola ne trovi due o tre epoche.
##
## Per ognuno serve sapere **dove sta la lampada**, perché il globo che si
## accende e la luce sono nodi veri (il MultiMesh non si può spegnere
## all'alba) e vanno messi nel punto giusto del modello.
const LAMPIONI := [
	{"m": "lamp_ghisa",    "luce": Vector3(0.0, 3.30, 0.40), "r": 0.15},
	{"m": "lamp_globo3",   "luce": Vector3(0.0, 3.20, 0.0),  "r": 0.20},
	{"m": "lamp_globo1",   "luce": Vector3(0.0, 3.02, 0.0),  "r": 0.17},
	{"m": "lamp_stradale", "luce": Vector3(0.0, 4.02, -0.52), "r": 0.14},
	{"m": "lamp_doppio",   "luce": Vector3(0.0, 4.15, 0.0),  "r": 0.16},
	{"m": "lamp_arco",     "luce": Vector3(0.0, 3.82, -0.14), "r": 0.15},
	# **'O lampione alto** (0.57). Era in cartella dalla prima consegna dei
	# modelli e non l'aveva mai montato nessuno: quattro metri e sessantacinque
	# contro i tre e mezzo degli altri, col braccio che sporge verso −Z.
	# L'altezza della lampada non è indovinata — è misurata con
	# `tools/prova_asset.gd`, che di ogni modello stampa l'ingombro vero.
	# Appenderla a occhio vuol dire luce a mezz'aria, e in fotografia si vede.
	{"m": "lampione",      "luce": Vector3(0.0, 4.38, 0.0),  "r": 0.16},
]


## Quale stile tocca a questa strada. Non è a caso: si sceglie dal
## quartiere, così una strada intera ha lampioni coerenti e cambiano
## passando da un quartiere all'altro — che è esattamente come funziona
## in una città vera.
func _stile_lampione(pos: Vector3) -> Dictionary:
	var q: String = Quartieri.id_di(pos.x, pos.z)
	var h: int = absi(hash(q)) % LAMPIONI.size()
	# Un lampione su sei è di un altro tipo: sono quelli sostituiti dopo
	# che una macchina ne ha buttato giù uno.
	if int(absi(hash(Vector2i(int(pos.x), int(pos.z)))) % 6) == 0:
		h = (h + 3) % LAMPIONI.size()
	return LAMPIONI[h]


func _lampione(pos: Vector3) -> void:
	# **Nun dint'â cornetteria** (0.59). La cornetteria è un fabbricato di
	# nove metri per sei appoggiato al fondo della sua piazzetta, e dietro
	# sporge per due metri e mezzo dentro a Via Marina: il lampione di Via
	# Marina a (144, 98) le stava **dentro al muro**. Non lo vedeva nessuna
	# prova perché il lampione non aveva un corpo; appena gliel'ho dato,
	# `prova_ngombri` l'ha trovato.
	if _dint_â_cornetteria(pos, 0.4):
		return
	# Né in mezzo a un incrocio (0.59): il lampione del bordo del Corso a
	# z 96 cadeva in mezzo a Via Marina, sulla sua corsia.
	if not _puo_avere_corpo(pos, Vector3(0.3, 3.0, 0.3)):
		return
	# E si al posto suo ce sta già qualcosa (un vaso, una giara), si prova
	# un metro e mezzo più in là, da una parte o dall'altra (0.59).
	if not _scatola_libera(pos, Vector3(0.3, 3.0, 0.3), 0.0, 0.1):
		var trovato := false
		for d in [Vector3(1.5, 0, 0), Vector3(-1.5, 0, 0), Vector3(0, 0, 1.5),
				Vector3(0, 0, -1.5), Vector3(3.0, 0, 0), Vector3(-3.0, 0, 0),
				Vector3(0, 0, 3.0), Vector3(0, 0, -3.0)]:
			var q: Vector3 = pos + d
			if not dint_ô_palazzo(q, 0.2) and not in_corsia(q, Vector3(0.3, 1, 0.3)) \
					and _scatola_libera(q, Vector3(0.3, 3.0, 0.3), 0.0, 0.1):
				pos = q
				trovato = true
				break
		if not trovato:
			return
	# **La struttura sta nel MultiMesh, la luce no.**
	#
	# Il palo, il braccio e il vetro del globo sono geometria e basta: vanno
	# raggruppati come tutto il resto. Ma il globo che si ACCENDE e la luce
	# sono nodi veri, perche' il ciclo giorno/notte deve poterli spegnere
	# all'alba — e dentro a un MultiMesh non ci si arriva.
	#
	# Quindi: il modello si batcha, e sopra ci si mette il globo luminoso
	# nel punto dove il modello ha il suo. Il braccio e' ricurvo, quindi il
	# globo non sta sull'asse del palo: sta a sessanta centimetri di lato,
	# e se il palo e' girato si gira pure lo scostamento.
	var giro: float = randf_range(-PI, PI)
	var stile := _stile_lampione(pos)
	var raggio_globo: float = float(stile["r"])
	var scostamento: Vector3 = (stile["luce"] as Vector3).rotated(
		Vector3.UP, giro)
	if not _pezzo_modello(str(stile["m"]), pos, "lamp_" + str(stile["m"]),
			giro):
		# Nessun modello: si ripiega sul palo procedurale di sempre. Non
		# dovrebbe succedere, ma un modello che manca non deve lasciare
		# una lampada che galleggia sopra al niente.
		var palo := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.07
		pm.bottom_radius = 0.1
		pm.height = 5.0
		palo.mesh = pm
		palo.position = pos + Vector3(0, 2.5, 0)
		palo.material_override = Tex.flat(Color(0.13, 0.14, 0.16), 0.45, 0.6)
		_batched("palo", palo)
		scostamento = Vector3(0, 5.15, 0)
		raggio_globo = 0.17

	# **'O palo se sbatte** (0.59). Il lampione era solo disegnato: ci si
	# passava in mezzo, e i passanti — che adesso girano intorno alle cose
	# solide — ci tiravano dritti attraverso. Un palo di ghisa di ventisei
	# centimetri per tre metri basta a fermare chi ci cammina contro.
	_solido(pos + Vector3(0, 1.5, 0), Vector3(0.26, 3.0, 0.26))

	var globo := MeshInstance3D.new()
	var gm := SphereMesh.new()
	gm.radius = raggio_globo
	gm.height = raggio_globo * 2.0
	globo.mesh = gm
	globo.position = pos + scostamento
	globo.material_override = Tex.flat(
		Color(1.0, 0.94, 0.75), 0.9, 0.0, 1.7).duplicate()
	add_child(globo)

	var luce := OmniLight3D.new()
	luce.position = pos + scostamento + Vector3(0, -0.2, 0)
	luce.light_color = Color(1.0, 0.86, 0.6)
	luce.light_energy = 1.8
	luce.omni_range = 13.0
	luce.shadow_enabled = false
	# Le luci lontane si spengono: in GL Compatibility ogni oggetto ne
	# regge poche, e sessanta lampioni accesi tutti insieme di notte
	# metterebbero in ginocchio le schede integrate.
	luce.distance_fade_enabled = true
	luce.distance_fade_begin = 55.0
	luce.distance_fade_length = 15.0
	add_child(luce)
	if _ciclo:
		_ciclo.aggiungi_lampione(luce, globo)


# ---------------------------------------------------------------------------
# L'arredo urbano — 'e ccose ca fanno 'a strada
# ---------------------------------------------------------------------------
#
# **Perché sta roba conta più di dieci palazzi in più.** La città era
# costruita bene e **pulita**. Una strada di Napoli non è pulita: ci sta il
# cantiere di tre anni fa che nessuno ha più chiuso, la transenna
# dimenticata, il cono spostato di lato per far passare le macchine, i
# condizionatori appesi storti alle facciate, le piante sui balconi.
#
# Non è sporcizia per il gusto di sporcare: è **traccia di gente che ci
# vive**. Un posto dove nessuno ha mai lasciato niente in mezzo alla strada
# è un posto dove non abita nessuno.

## Quanti cantieri aperti per la città. Cinque: abbastanza da incontrarne
## uno girando, pochi da non sembrare una zona di guerra.
## Fin dove si può tendere una corda per i panni. Oltre questa luce la
## corda non si vede più e i lenzuoli sembrano volare.
const LUCE_MAX_PANNI: float = 9.5

const CANTIERI := 5


## **'E cantiere.** Un gruppetto di coni, una transenna e un bidone, messi
## su un pezzo di strada larga. Il seme è fisso: i cantieri stanno sempre
## negli stessi posti, perché una città dove le transenne si spostano ogni
## partita non è una città, è un generatore.
##
## **Dalla 0.59 dentro ci sta chi lavora, e non ci si passa attraverso.**
##
## Tre cose, e l'ultima è la più importante.
##
## 1. **'A robba d''o cantiere**: la carriola, il bancale coi sacchi di
##    cemento, il secchio, il piccone buttato per terra, il fusto, la pala
##    appoggiata al muro — tutti del pacchetto Pandazole, e tutti **dietro
##    alla transenna**, fra lei e il muro, che è dove stanno in un cantiere
##    vero. Davanti alla transenna non si aggiunge niente.
## 2. **L'operaio**: in due cantieri su cinque c'è uno inginocchiato che
##    lavora (la clip `Working` dell'umano di Quaternius, in ciclo), con la
##    maglietta arancione. È la prima volta che il pacchetto dei corpi nuovi
##    serve a qualcosa che il pupo non sapeva fare: il pupo non ha una clip
##    di lavoro.
## 3. **'O recinto è solido.** Le transenne, i coni e il bidone erano solo
##    disegnati: ci si camminava attraverso, e così i passanti — che dalla
##    0.59 sanno dove sono le cose solide e le girano intorno — ci
##    tiravano dritti in mezzo. Adesso tutto il recinto, dal fronte della
##    transenna al muro, è un corpo solo. Per poterlo fare senza chiudere
##    le strade il fronte del cantiere **non entra più nella corsia
##    libera** (l'invariante che tiene la città attraversabile), e se il
##    recinto toccasse un varco di una piazza resta senza corpo, come prima:
##    un cantiere attraversabile è brutto, un varco chiuso è rotto.
func _build_cantieri() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 90546
	# Solo strade larghe: in un vicolo da quattro metri un cantiere
	# murerebbe il passaggio, e il giocatore ci resterebbe incastrato.
	var buone: Array = []
	for s in STRADE:
		var w: float = s[2] - s[0]
		var l: float = s[3] - s[1]
		if minf(w, l) >= 6.0 and maxf(w, l) >= 18.0:
			buone.append(s)
	if buone.is_empty():
		return
	# **'O seme fisso nun era fisso** (0.59). Qui c'era `buone.shuffle()`,
	# che mescola col caso **globale** e non con `rng`: il commento sopra
	# promette che i cantieri stanno sempre negli stessi posti, e invece a
	# ogni partita cambiavano strada. Adesso si mescola col seme.
	for k in range(buone.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, k)
		var tmp = buone[k]
		buone[k] = buone[j]
		buone[j] = tmp
	var operai := 0
	for i in range(mini(CANTIERI, buone.size())):
		var s: Array = buone[i]
		var lungo_z: bool = (s[3] - s[1]) > (s[2] - s[0])
		# Il cantiere sta su un lato solo della carreggiata: dall'altro
		# lato si passa. È la differenza fra un ostacolo e un muro.
		# E il suo fronte (la transenna più quaranta centimetri) resta
		# fuori dalla corsia libera, con un palmo di margine.
		var cx: float = 0.0
		var cz: float = 0.0
		var lungo := Vector3(1, 0, 0)
		var muro := Vector3(0, 0, -1)
		var dal_muro: float = 0.0
		if lungo_z:
			var fino: float = minf(s[0] + (s[2] - s[0]) * 0.45,
				(s[0] + s[2]) * 0.5 - CORSIA - 0.55)
			cx = rng.randf_range(s[0] + 1.4, maxf(s[0] + 1.4, fino))
			cz = rng.randf_range(s[1] + 4.0, s[3] - 4.0)
			lungo = Vector3(0, 0, 1)
			muro = Vector3(-1, 0, 0)
			dal_muro = cx - float(s[0])
		else:
			var fino_z: float = minf(s[1] + (s[3] - s[1]) * 0.45,
				(s[1] + s[3]) * 0.5 - CORSIA - 0.55)
			cx = rng.randf_range(s[0] + 4.0, s[2] - 4.0)
			cz = rng.randf_range(s[1] + 1.4, maxf(s[1] + 1.4, fino_z))
			dal_muro = cz - float(s[1])
		var centro := Vector3(cx, 0.0, cz)
		# Due transenne in fila e i coni che ne segnano l'ingombro. La quota
		# è quella del suolo di città: sulla collina ci pensa `_batched`
		# (passargli già `Collina.alzata` la contava due volte).
		var t: String = "transenna"
		if rng.randf() >= 0.5:
			t = "transenna2"
		var giro_t: float = 0.0
		if not lungo_z:
			giro_t = PI * 0.5
		for k in range(2):
			var p: Vector3 = centro + lungo * (float(k) * 1.7 - 0.85)
			_pezzo_modello(t, p, "cant_transenna", giro_t)
		for k2 in range(4):
			var scarto := Vector3(rng.randf_range(-0.3, 0.3), 0.0,
				rng.randf_range(-0.3, 0.3))
			var q: Vector3 = centro + lungo * (float(k2) * 1.3 - 2.6) + scarto
			var quale_cono: String = "cono"
			if k2 % 2 == 1:
				quale_cono = "cono2"
			_pezzo_modello(quale_cono, q, "cant_cono", rng.randf_range(-PI, PI))
		var b: Vector3 = centro + lungo * 3.4
		_pezzo_modello("bidone_cantiere", b, "cant_bidone",
			rng.randf_range(-PI, PI))

		# **E 'nu cantiere ncopp'a tre è 'nu cantiere overo** (0.57).
		#
		# `new_jersey` e `barriera_lunga` stavano in cartella dalla prima
		# consegna e non li aveva montati nessuno. Messi qui cambiano il
		# senso della cosa: cinque cantieri fatti tutti di due transenne e
		# quattro coni sono lo stesso cantiere copiato cinque volte, e dopo
		# il secondo il giocatore smette di guardarli. Con i blocchi di
		# cemento uno dei cinque diventa **un lavoro vero**, di quelli che
		# stanno lì da tre anni — e gli altri quattro, per contrasto,
		# tornano a sembrare quello che sono: una transenna dimenticata.
		#
		# Sono ingombri seri (un metro e dieci di altezza, misurati) e
		# stanno in fila lungo il cantiere, cioè **dalla parte in cui la
		# strada è già chiusa**: non aggiungono ostacolo, danno peso a
		# quello che c'era.
		if rng.randf() < 0.34:
			for k3 in range(3):
				var j: Vector3 = centro + lungo * (float(k3) * 1.15 - 1.15)
				_pezzo_modello("new_jersey", j, "cant_jersey", giro_t)
		elif rng.randf() < 0.5:
			var bl: Vector3 = centro + lungo * 1.2
			_pezzo_modello("barriera_lunga", bl, "cant_barriera", giro_t)
		# E un paletto storto, che sta sempre.
		var pl: Vector3 = centro - lungo * 3.2
		_pezzo_modello("paletto", pl, "cant_paletto", rng.randf_range(-PI, PI))

		_dint_ô_cantiere(centro, lungo, muro, dal_muro, rng)
		_cantieri_info.append([centro, lungo, muro, dal_muro])
		if operai < 2 and rng.randf() < 0.5:
			operai += 1
			_operaio(centro + lungo * -0.8 + muro * clampf(dal_muro * 0.55,
				0.55, dal_muro - 0.45), muro)
		_recinto_cantiere(centro, lungo, muro, dal_muro)
		# Il cartello giallo dei lavori in testa al cantiere, verso chi
		# arriva: i due rombi gialli del pacchetto (vedi `_cartelli_stradali`).
		var q_c: Vector3 = centro - lungo * 4.3
		if Models.has_model("cartello_strettoia") and _sta_libero(q_c, 0.45):
			_cartello("cartello_strettoia" if i % 2 == 0 else "cartello_incrocio",
				q_c, atan2(-lungo.x, -lungo.z))


## La roba di chi lavora, fra la transenna e il muro. `a` è quanto sta
## dietro alla transenna (verso il muro), `lungo` è il verso del cantiere.
func _dint_ô_cantiere(centro: Vector3, lungo: Vector3, muro: Vector3,
		dal_muro: float, rng: RandomNumberGenerator) -> void:
	if not Models.has_model("carriola"):
		return
	# Il verso "lungo il cantiere" per i pezzi lunghi (carriola, bancale):
	# la X della mesh si mette lungo `lungo`.
	var giro_l: float = atan2(-lungo.z, lungo.x)
	var dietro := func(al: float, a: float) -> Vector3:
		return centro + lungo * al + muro * clampf(a, 0.4, dal_muro - 0.3)
	const G := "cantiere"
	_panda("carriola", dietro.call(-2.3, dal_muro * 0.55),
		giro_l + rng.randf_range(-0.15, 0.15), G)
	# Il bancale coi sacchi di cemento sopra.
	var pb: Vector3 = dietro.call(0.6, dal_muro * 0.55)
	_panda(["bancale_1", "bancale_2"][rng.randi() % 2], pb, giro_l, G)
	for k in range(rng.randi_range(2, 3)):
		_panda(["sacco_1", "sacco_2", "sacco_3"][rng.randi() % 3],
			pb + lungo * (float(k) - 1.0) * 0.36 + Vector3(0, 0.13, 0),
			giro_l + PI * 0.5 + rng.randf_range(-0.2, 0.2), G)
	_panda(["secchio_1", "secchio_2"][rng.randi() % 2],
		dietro.call(1.35, dal_muro * 0.4), rng.randf_range(-PI, PI), G)
	_panda("piccone", dietro.call(2.0, dal_muro * 0.65),
		rng.randf_range(-PI, PI), G)
	_panda(FUSTI[_cantieri_fatti % FUSTI.size()],
		dietro.call(2.9, dal_muro * 0.55), rng.randf_range(-PI, PI), G)
	_cantieri_fatti += 1
	# Gli attrezzi piccoli buttati accanto al secchio, e un cono in più.
	_panda("martello", dietro.call(1.72, 0.45), rng.randf_range(-PI, PI), G)
	_panda("chiave_inglese", dietro.call(1.05, 0.42), rng.randf_range(-PI, PI), G)
	_panda("nastro", dietro.call(1.85, 0.62), rng.randf_range(-PI, PI), G)
	_panda("cono_3", centro + lungo * 2.35, rng.randf_range(-PI, PI), G)
	# 'A pala appujata ô muro.
	var piede: Vector3 = centro + lungo * -1.4 + muro * (dal_muro - 0.36)
	var verso_muro: float = atan2(muro.x, muro.z)
	var b := Basis(Vector3.UP, verso_muro + PI) * Basis(Vector3.RIGHT, -0.22)
	_panda_t("pala", Transform3D(b, piede), G)


var _cantieri_fatti: int = 0
## I cantieri fatti, per chi ci aggiunge roba dopo (0.60, `RobbaPsx`):
## `[centro, lungo, verso il muro, distanza dal muro]`.
var _cantieri_info: Array = []


## L'operaio inginocchiato che lavora, girato verso il muro.
func _operaio(p: Vector3, muro: Vector3) -> void:
	var parti: Dictionary = Human.build(Color(0.95, 0.48, 0.10),
		Color(0.16, 0.22, 0.40), "", randf_range(1.70, 1.80),
		{"modello": "umano_q", "clip": "Working"})
	var n: Node3D = parti.get("root")
	if n == null:
		return
	n.name = "Operaio"
	n.position = p
	# forward(θ) = (−sinθ, 0, −cosθ): per guardare il muro θ = atan2(−mx, −mz).
	n.rotation.y = atan2(-muro.x, -muro.z)
	n.add_to_group("operai")
	add_child(n)
	_lontananza(n, 70.0)


## Il corpo solido del recinto: dal fronte della transenna (quaranta
## centimetri verso la strada) fino al muro, per tutta la lunghezza del
## cantiere (dal paletto al bidone). Senza corpo se tocca un varco.
func _recinto_cantiere(centro: Vector3, lungo: Vector3, muro: Vector3,
		dal_muro: float) -> void:
	var da_l: float = -3.35
	var a_l: float = 3.75
	var fronte: float = -0.4          # verso la strada
	var fondo: float = dal_muro       # fino al muro
	var mezzo: Vector3 = centro + lungo * ((da_l + a_l) * 0.5) \
		+ muro * ((fronte + fondo) * 0.5)
	var lungo_x: bool = absf(lungo.x) > 0.5
	var dim := Vector3(a_l - da_l, 1.2, fondo - fronte)
	if not lungo_x:
		dim = Vector3(fondo - fronte, 1.2, a_l - da_l)
	var rect := Rect2(mezzo.x - dim.x * 0.5, mezzo.z - dim.z * 0.5, dim.x, dim.z)
	for v in VARCHI:
		var rv := Rect2(float(v[0]) - 2.0, float(v[1]) - 2.0,
			float(v[2]) - float(v[0]) + 4.0, float(v[3]) - float(v[1]) + 4.0)
		if rv.intersects(rect):
			return
	_solido(mezzo + Vector3(0, 0.6, 0), dim)


## **'E paletti d''e marciapiede.** Quelli che a Napoli mettono per non far
## salire le macchine sul marciapiede, e che le macchine salgono lo stesso.
## Uno ogni sei metri lungo i bordi delle piazze.
func _build_paletti() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4477
	for z in ZONE:
		var r: Array = z["rect"]
		var passo := 6.0
		var x: float = float(r[0]) + 2.0
		while x < float(r[2]) - 2.0:
			for zz in [float(r[1]) + 0.6, float(r[3]) - 0.6]:
				if rng.randf() < 0.22:
					x += passo
					continue
				# **Uno ogni cinque è 'nu delimitatore** (0.57). Il
				# `delimitatore` stava in cartella e non l'aveva montato
				# nessuno: è più alto e più grosso del paletto (un metro
				# contro mezzo), e alternato ogni tanto toglie al bordo
				# della piazza quell'aria di fila di birilli tutti uguali.
				# Uno su cinque e non uno su due: la variazione si nota
				# quando è un'eccezione, non quando è metà.
				var quale: String = "paletto"
				if rng.randf() < 0.2:
					quale = "delimitatore"
				_pezzo_modello(quale, Vector3(x, 0.0, zz),
					"bordo_" + quale, rng.randf_range(-0.25, 0.25))
			x += passo


## **'E vvarche d''e vicule.**
##
## Un arco di pietra sopra a un vicolo è il segno più forte che si possa
## mettere per dire "qui comincia il quartiere vecchio": lo si vede da
## cento metri e non ha bisogno di nessuna scritta. È uno scan vero di un
## arco del Duecento, alleggerito da un milione e duecentomila triangoli a
## quattromila.
##
## Tre, e non di più. Un arco è un evento; quattro archi sono un motivo
## decorativo, e a quel punto smettono di dire qualcosa.
const ARCHI := [
	# Ingresso del vicolo che scende dalla piazza verso il Centro Antico.
	[54.0, 62.0, 0.0],
	# Sopra Spaccanapoli, all'altezza della fontana.
	[52.0, 76.0, 0.0],
	# All'imbocco della Sanità, dalla parte del mercato.
	[12.0, 100.0, 1.5708],
]


func _build_archi() -> void:
	for a in ARCHI:
		var x: float = float(a[0])
		var z: float = float(a[1])
		_pezzo_modello("arco_vicolo", Vector3(x, 0.0, z), "arco",
			float(a[2]))


## **'E vase 'e chiante.** Contro i muri, dove c'è il marciapiede.
##
## Gli alberi non stanno qui: ce li mette già `_build_verde()`, che è più
## vecchio di questa funzione e sa dove vanno (solo negli slarghi — in un
## vicolo da quattro metri una chioma da sei non ci sta). Qui c'è solo la
## roba piccola, quella che uno mette fuori dalla porta di casa.
func _build_vase() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260906
	for s2 in STRADE:
		var w2: float = s2[2] - s2[0]
		var l2: float = s2[3] - s2[1]
		var lungo_z: bool = l2 > w2
		var corsa: float = l2 if lungo_z else w2
		if corsa < 12.0:
			continue
		var n := int(corsa / 11.0)
		for i2 in range(n):
			if rng.randf() < 0.45:
				continue
			var base: float = s2[0]
			if lungo_z:
				base = s2[1]
			var t: float = base + (float(i2) + 0.6) * 11.0
			# Contro un muro o contro l'altro: `dentro` è quanto ci si
			# scosta dal bordo della strada verso il centro. Quarantacinque
			# centimetri e non settantacinque (0.59): a settantacinque, in un
			# vicolo di quattro metri, il vaso entrava nella corsia libera, e
			# `_solido` giustamente non gli dava il corpo. Centonovanta vasi e
			# giare su duecentoventi si attraversavano.
			var dentro: float = 0.45
			var da_capo: bool = rng.randf() < 0.5
			var p := Vector3.ZERO
			if lungo_z:
				var px: float = s2[0] + dentro
				if not da_capo:
					px = s2[2] - dentro
				p = Vector3(px, 0.0, t)
			else:
				var pz: float = s2[1] + dentro
				if not da_capo:
					pz = s2[3] - dentro
				p = Vector3(t, 0.0, pz)
			var scala_v: float = rng.randf_range(0.8, 1.15)
			var giro_v: float = rng.randf_range(-PI, PI)
			# Un vaso che non può avere corpo (nella corsia, in un varco:
			# succede agli incroci) non si mette proprio (0.59). E dietro ci
			# dev'essere un muro vero: all'incrocio col Corso il "bordo" della
			# traversa è in mezzo al Corso, e il vaso ci restava piantato.
			var dietro: Vector3 = p
			if lungo_z:
				dietro.x += -0.7 if da_capo else 0.7
			else:
				dietro.z += -0.7 if da_capo else 0.7
			if not dint_ô_palazzo(dietro, 0.0) \
					or not _puo_avere_corpo(p, Vector3(0.62, 1.0, 0.62) * scala_v) \
					or not _scatola_libera(p, Vector3(0.62, 1.0, 0.62) * scala_v, 0.0, 0.05):
				continue
			if _pezzo_modello("vaso_pianta", p, "vaso", giro_v, scala_v):
				_solido(p + Vector3(0, 0.5, 0),
					Vector3(0.62, 1.0, 0.62) * scala_v)
			# **'A giara appriesso ô vaso** (0.57). Terracotta senza niente
			# dentro, mezzo metro scarso, appoggiata al muro accanto alla
			# pianta: è l'oggetto più napoletano della cartella e non
			# l'aveva montato nessuno. Non sta da sola in mezzo alla strada
			# — sta **accanto a qualcosa**, come stanno le giare vere, che
			# nessuno le mette apposta: restano dove le hanno scaricate.
			if rng.randf() < 0.45:
				var lato: float = 0.55 if rng.randf() < 0.5 else -0.55
				var g := Vector3(p.x, 0.0, p.z + lato)
				if not lungo_z:
					g = Vector3(p.x + lato, 0.0, p.z)
				var scala_g: float = rng.randf_range(0.85, 1.25)
				var giro_g: float = rng.randf_range(-PI, PI)
				if not _puo_avere_corpo(g, Vector3(0.36, 0.5, 0.36) * scala_g) \
						or not _scatola_libera(g, Vector3(0.36, 0.5, 0.36) * scala_g, 0.0, 0.05):
					continue
				if _pezzo_modello("giara", g, "giara", giro_g, scala_g):
					_solido(g + Vector3(0, 0.25, 0),
						Vector3(0.36, 0.5, 0.36) * scala_g)


## **'E condizionature.** Appesi alle facciate, storti, uno per finestra
## quando capita. È la cosa più anni Duemila che ci sia su un palazzo
## italiano, e senza si vede che manca qualcosa anche se non sai cosa.
##
## Vanno appesi al **muro giusto**: `faccia` è la normale che esce dalla
## facciata, quindi lo split sta un pelo fuori dal muro e guarda in fuori.
##
## **'O condizionatore ca era 'nu palazzo** (0.62). Fino alla 0.61 qui si
## appendevano i modelli `condizionatore` e `condizionatore2`, ricavati da
## `tools/build_arredo_urbano.py` da un pacchetto di pezzi di città: lo
## script aveva preso il nodo giusto (`Split_Ac`, `Window_AC`) **col palazzo
## in miniatura di cui faceva parte** — muri di mattoni, finestre, piante e
## cartelloni, 182 e 235 superfici. In città si vedevano come casette con i
## manifesti della pizza appese ai muri (le ha trovate la foto delle
## colature), e ogni superficie era una chiamata di disegno in più per ogni
## quadretto: migliaia. Adesso lo split si costruisce qui: la scatola
## bianca, la griglia della ventola, le due staffe. Quattro pezzi, gli
## stessi colori per tutta la città, quattro gruppi.
const SPLIT_GRANDE := Vector3(0.80, 0.56, 0.30)   # largo, alto, profondo
const SPLIT_PICCOLO := Vector3(0.62, 0.46, 0.26)


func _condizionatore(punto: Vector3, faccia: Vector3,
		rng: RandomNumberGenerator) -> void:
	if rng.randf() > 0.34:
		return
	var grande: bool = rng.randf() < 0.6
	# Il terzo numero del caso resta pescato come prima (era lo storto dello
	# split), così la sequenza della città non si sposta di una virgola.
	var _storto: float = rng.randf_range(-0.08, 0.08)
	# **'O split appiso a ll'aria** (0.62). Dove dietro non c'è muro
	# (l'ultima finestra di una facciata corta, a un metro dallo spigolo)
	# non si mette.
	if not dint_ô_palazzo(punto - faccia * 0.12, 0.0):
		return
	var dim: Vector3 = SPLIT_GRANDE if grande else SPLIT_PICCOLO
	var lungo := Vector3(faccia.z, 0.0, -faccia.x)
	var c: Vector3 = punto + faccia * (0.08 + dim.z * 0.5) + Vector3(0, dim.y * 0.5, 0)
	_pezzo(c, _spessa(faccia, dim.x, dim.y, dim.z),
		Tex.flat(Color(0.85, 0.85, 0.82), 0.55), "split_corpo")
	# La griglia della ventola, sul davanti e spostata di lato.
	var g: float = dim.y * 0.78
	_pezzo(c + faccia * (dim.z * 0.5 + 0.006) + lungo * (dim.x * 0.18),
		_spessa(faccia, g, g, 0.012), Tex.flat(Color(0.20, 0.21, 0.22), 0.7),
		"split_grata")
	# Le due staffe di ferro, dal muro a sotto la scatola.
	for k in [-1.0, 1.0]:
		_pezzo(punto + faccia * (0.08 + dim.z * 0.5) + lungo * (dim.x * 0.36 * k)
			+ Vector3(0, -0.02, 0), _spessa(faccia, 0.04, 0.04, dim.z + 0.16),
			Tex.flat(Color(0.16, 0.16, 0.17), 0.6, 0.4), "split_staffa")
	# (0.62) Dove sta lo split, per la colatura d'acqua sotto
	# (`RobbaEsterna`). La quota è quella del muro, senza la collina: la
	# aggiunge `_batched`, come a tutto l'arredo.
	_split_posti.append([punto, faccia])


## Gli split appesi: `[punto sul muro, normale verso fuori]`.
var _split_posti: Array = []


# ---------------------------------------------------------------------------
# Le zone
# ---------------------------------------------------------------------------

func _build_piazza() -> void:
	var r: Array = ZONE[0]["rect"]
	_piazza = PiazzaScript.new()
	_piazza.name = "ZoneVicolo"
	_piazza.dentro_citta = true
	_piazza.configure(GameManager.ZONES["vicolo"])
	_piazza.position = Vector3(r[0], 0.0, r[1])
	add_child(_piazza)
	# Il segnale della notte lo emette il ciclo, che adesso sta qui e non
	# piu' dentro alla piazza: senza questo collegamento Borrelli non
	# sapeva mai che era calato il buio e non arrivava proprio.
	if _ciclo and _piazza.has_method("_on_notte_calata"):
		_ciclo.notte_calata.connect(_piazza._on_notte_calata)


func get_player_start() -> Vector3:
	var r: Array = ZONE[0]["rect"]
	return Vector3(r[0], 0.0, r[1]) + Vector3(17.0, 0.0, 22.0)


var player_start_rotation_y: float = 0.0


func _build_zone() -> void:
	for i in range(1, ZONE.size()):
		var z: Dictionary = ZONE[i]
		var r: Array = z["rect"]
		# I palazzi intorno non si costruiscono più qui: adesso le zone sono
		# ritagliate dentro alla maglia degli isolati, e sono gli isolati a
		# fare da quinta su tutti e quattro i lati.
		_pavimenta(r[0], r[1], r[2], r[3], str(z["id"]))
		_posti_auto(r[0], r[1], r[2], r[3])
		_cartello_zona(z)
		var riv := RivaleScript.new()
		riv.name = "Rivale_" + str(z["id"])
		add_child(riv)
		var dove: Vector3 = z.get("posto",
			Vector3((r[0] + r[2]) / 2.0, 0.0, (r[1] + r[3]) / 2.0))
		riv.global_position = Vector3(dove.x, 0.4, dove.z)
		# Il giro di ronda: di norma e' tutta la zona, ma il piazzale dello
		# stadio ha l'impianto in mezzo, e un parcheggiatore che gira
		# intorno al centro della piazza finirebbe a passeggiare dentro
		# alla conca. La sua ronda e' quella del sagrato, davanti.
		var ronda: Array = z.get("ronda", r)
		riv.configura(str(z["id"]), str(z["padrone"]),
			Vector3(ronda[0], 0, ronda[1]), Vector3(ronda[2], 0, ronda[3]),
			str(z["nome"]))

		# Il rubinetto delle auto di questa piazza. Esiste sempre, ma serve
		# solo quando la piazza diventa tua: fa il controllo da solo a ogni
		# giro di timer, cosi' non serve costruirlo e distruggerlo quando
		# la zona cambia padrone.
		var post := PosteggioScript.new()
		post.name = "Posteggio_" + str(z["id"])
		add_child(post)
		post.configura(str(z["id"]), r)

	_build_cestini()
	_build_guagliuni()
	_build_bacheche()
	_build_garage()
	_build_cantieri()
	_build_paletti()
	_build_vase()
	_build_archi()
	_build_stadio()
	_build_piazzale()
	_build_cornetteria()
	_build_galera()
	_build_spighe()
	_build_bancarelle()


# ---------------------------------------------------------------------------
# Gli angoli di strada
# ---------------------------------------------------------------------------
#
# **Un mondo credibile non e' fatto di oggetti belli sparsi a caso: e'
# fatto di oggetti che stanno INSIEME.**
#
# Un cestino da solo e' un cestino. Un cestino con accanto tre cassette
# della frutta impilate, un motorino appoggiato al muro e un cassonetto
# mezzo aperto e' un angolo di Napoli. E' la stessa roba, messa vicina.
#
# Ogni "scena" qui sotto e' una composizione fissa con qualche variazione a
# caso: cosi' gli angoli si somigliano — come si somigliano gli angoli veri
# di una citta' — senza essere identici.
const ANGOLI := [
	# [x, z, verso in gradi, che scena]
	[27.0, 62.0, 0.0, 0], [52.0, 70.0, 90.0, 1], [69.0, 62.0, 180.0, 2],
	[13.0, 88.0, 90.0, 1], [58.0, 96.0, 0.0, 0], [96.0, 70.0, 270.0, 2],
	[110.0, 92.0, 0.0, 1], [77.0, 126.0, 180.0, 0], [30.0, 126.0, 90.0, 2],
	[135.0, 62.0, 0.0, 0], [163.0, 96.0, 270.0, 1], [45.0, 150.0, 180.0, 2],
	[104.0, 150.0, 0.0, 0], [140.0, 128.0, 90.0, 1], [92.0, 40.0, 270.0, 2],
]


## **'E scene stevano 'mmiezo â strada** (0.59). I quindici punti qui
## sopra erano scritti a mano, e dieci su quindici cadevano **dentro alla
## corsia libera** della strada (uno dentro a un palazzo). Il motorino, il
## cassonetto, le cassette stavano in mezzo al vicolo — e siccome `_solido`
## non mette corpi nella corsia, ci stavano **senza corpo**: ci si passava
## attraverso, persone e macchine. Non lo vedeva nessuna prova perché
## nessuna prova guardava l'arredo senza corpo; l'ha trovato
## `prova_arredo`, cercando posto ai sacchetti accanto ai cassonetti e non
## trovandolo mai.
##
## Adesso il punto scritto è solo **dove si comincia a cercare**: la scena
## si appoggia al muro più vicino di una strada che ce l'ha (ogni pezzo con
## la schiena al muro, alla sua profondità), scorrendo lungo il muro finché
## tutti i pezzi stanno fuori dalla corsia, dai varchi, dalle piazze, dai
## posti dove si fa qualcosa e da quello che c'è già. Si fa per ultimo,
## insieme all'arredo nuovo, così conosce tutto il resto della città.
##
## I pezzi di ogni scena: `[nome, di quanto sta lungo il muro, mezza
## lunghezza, mezza profondità, giro in più, ingombro]`.
const SCENE_ANGOLO := {
	0: [["motorino_fermo", 0.0, 0.95, 0.45, PI * 0.5, Vector3(0.9, 1.1, 1.9)],
		["cassette", 1.5, 0.3, 0.23, 0.0, Vector3(0.6, 0.8, 0.45)],
		["cestino", -1.4, 0.21, 0.21, 0.0, Vector3(0.42, 0.9, 0.42)]],
	1: [["cassonetto", 0.0, 0.7, 0.6, 0.0, Vector3(1.4, 1.3, 1.2)],
		["motorino_fermo", 2.0, 0.95, 0.45, PI * 0.5, Vector3(0.9, 1.1, 1.9)]],
	2: [["cassette", 0.0, 0.3, 0.23, 0.0, Vector3(0.6, 0.8, 0.45)],
		["panchina", 2.2, 0.95, 0.35, 0.0, Vector3(1.9, 0.9, 0.7)],
		["cestino", 3.6, 0.21, 0.21, 0.0, Vector3(0.42, 0.9, 0.42)]],
}


func _build_angoli() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260905
	for a in ANGOLI:
		var p := Vector3(float(a[0]), 0.0, float(a[1]))
		var quale: int = int(a[3])
		var posto: Dictionary = _posto_pe_scena(p, SCENE_ANGOLO[quale])
		if posto.is_empty():
			continue
		_scena_angolo(posto["muro"], float(posto["giro"]), quale, rng)


## Il muro buono più vicino a `p` per la scena `quale`: il punto sul muro e
## il giro (il +Z dei pezzi guarda la strada, il loro X corre lungo il muro).
func _posto_pe_scena(p: Vector3, pezzi: Array) -> Dictionary:
	var meglio := {}
	var meglio_d := INF
	for st in STRADE:
		var x0: float = float(st[0])
		var z0: float = float(st[1])
		var x1: float = float(st[2])
		var z1: float = float(st[3])
		# Solo le strade vicine al punto scritto.
		var dx: float = maxf(maxf(x0 - p.x, 0.0), p.x - x1)
		var dz: float = maxf(maxf(z0 - p.z, 0.0), p.z - z1)
		if Vector2(dx, dz).length() > 7.0:
			continue
		var lungo_z: bool = (z1 - z0) > (x1 - x0)
		for lato in [0, 1]:
			var fuori: Vector3
			var t_da: float
			var t_a: float
			var t_p: float
			if lungo_z:
				fuori = Vector3(1, 0, 0) if lato == 0 else Vector3(-1, 0, 0)
				t_da = z0 + 2.0
				t_a = z1 - 2.0
				t_p = clampf(p.z, t_da, t_a)
			else:
				fuori = Vector3(0, 0, 1) if lato == 0 else Vector3(0, 0, -1)
				t_da = x0 + 2.0
				t_a = x1 - 2.0
				t_p = clampf(p.x, t_da, t_a)
			var giro: float = atan2(fuori.x, fuori.z)
			for k in range(0, 21):
				var dt: float = float((k + 1) / 2) * 1.5 * (1.0 if k % 2 == 0 else -1.0)
				var t: float = t_p + dt
				if t < t_da or t > t_a:
					continue
				var muro := Vector3(x0 if lato == 0 else x1, 0.0, t) if lungo_z \
					else Vector3(t, 0.0, z0 if lato == 0 else z1)
				var d: float = muro.distance_to(p)
				if d >= meglio_d:
					continue
				if _scena_sta(muro, giro, fuori, pezzi):
					meglio_d = d
					meglio = {"muro": muro, "giro": giro}
	return meglio


## Tutti i pezzi della scena stanno al muro, fuori dalla corsia e dal resto?
func _scena_sta(muro: Vector3, giro: float, fuori: Vector3, pezzi: Array) -> bool:
	var lungo := Vector3(cos(giro), 0, -sin(giro))
	for pz in pezzi:
		var off: float = float(pz[1])
		var ml: float = float(pz[2])
		var mp: float = float(pz[3])
		var c: Vector3 = muro + lungo * off + fuori * (mp + 0.03)
		# Il muro dietro ci deve essere davvero, per tutta la lunghezza del
		# pezzo: agli incroci il bordo della strada non è un muro.
		for e in [-ml, 0.0, ml]:
			if not dint_ô_palazzo(muro + lungo * (off + float(e)) - fuori * 0.3, 0.0):
				return false
		if _perche_nun_sta(c, maxf(ml, mp), mp) != "":
			return false
	return true


## Mette a terra un gruppetto. `muro` è il punto sul muro, `giro` il verso
## dei pezzi: il loro +Z guarda la strada, il loro X corre lungo il muro, e
## ognuno sta con la schiena al muro alla sua profondità.
func _scena_angolo(muro: Vector3, giro: float, quale: int,
		rng: RandomNumberGenerator) -> void:
	var lungo := Vector3(cos(giro), 0, -sin(giro))
	var fuori := Vector3(sin(giro), 0, cos(giro))
	for pz in SCENE_ANGOLO[quale]:
		var nome: String = str(pz[0])
		var c: Vector3 = muro + lungo * float(pz[1]) + fuori * (float(pz[3]) + 0.03)
		var g: float = giro + float(pz[4])
		if nome == "cassette":
			g += rng.randf_range(-0.3, 0.3)
		_arredo(nome, c, g, pz[5])
		if nome == "cassonetto":
			_cassonetti.append([c, giro])


## Un pezzo d'arredo: il modello nel MultiMesh, e — se `ingombro` non e'
## zero — un corpo solido perche' non ci si cammini dentro.
func _arredo(nome: String, p: Vector3, giro: float, ingombro: Vector3) -> void:
	if not _pezzo_modello(nome, p, nome + "_ang", giro):
		return
	if ingombro != Vector3.ZERO:
		_solido(p + Vector3(0, ingombro.y * 0.5, 0), ingombro, giro)


## **'E cestini.**
##
## Ce n'erano zero: la lista dei modelli "ancora da fare" li dava fra i
## primi, e in una piazza italiana un cestino appeso al palo sta a ogni
## angolo. Uno per ogni ingresso di zona e uno accanto a ogni panchina della
## piazzetta: sono venti nodi in un MultiMesh solo, e riempiono gli angoli
## che restavano vuoti.
func _build_cestini() -> void:
	var punti: Array = []
	for z in ZONE:
		var r: Array = z["rect"]
		punti.append(Vector3(float(r[0]) + 2.0, 0.0, float(r[1]) + 2.0))
		punti.append(Vector3(float(r[2]) - 2.0, 0.0, float(r[3]) - 2.0))
	# (61,3 · 74,4) e no (60 · 74): lì ci sta il pino della piazzetta, e
	# il cestino gli stava dentro al tronco (0.59, `prova_ngombri`, appena
	# il cestino ha avuto un corpo).
	# **E 'e cestine nun stanno 'mmiezo â strada** (0.59). Quattro di questi
	# stavano sulla riga di mezzo del Decumano e di Via Marina (63,5 e
	# 95,5), uno nel varco della piazza tua: senza corpo e in mezzo alle
	# macchine. Adesso stanno sul bordo, a quarantacinque centimetri dal muro.
	for p in [Vector3(61.3, 0, 74.4), Vector3(70.0, 0, 86.0),
			Vector3(33.5, 0, 66.55), Vector3(72.8, 0, 66.55),
			Vector3(120.0, 0, 98.55), Vector3(46.0, 0, 98.55)]:
		punti.append(p)
	for p2 in punti:
		if not _puo_avere_corpo(p2, Vector3(0.42, 0.9, 0.42)):
			continue
		if _pezzo_modello("cestino", p2, "cestino_mod",
				randf_range(-PI, PI)):
			# Pure il cestino ferma (0.59): era l'unico arredo della piazza
			# senza corpo, e ci si passava attraverso.
			_solido(p2 + Vector3(0, 0.45, 0), Vector3(0.42, 0.9, 0.42))


## **Uno che cerca fatica in ogni piazza — compresa la tua.**
##
## Sta in un angolo col cartello di cartone e non fa niente finché non lo
## assumi. Ce n'è uno anche nella Piazza: e' quello che serve per andarsene
## in giro per la citta' senza che la piazza di casa si fermi, ed e' la
## prima volta che uno capisce a che serve tutto il meccanismo.
##
## Il posto: un quinto dentro alla zona da un angolo, cosi' non finisce in
## mezzo alla coda delle auto ne' addosso al parcheggiatore rivale, che sta
## al centro.
func _build_guagliuni() -> void:
	for z in ZONE:
		var r: Array = z["rect"]
		var p := Vector3(
			lerpf(float(r[0]), float(r[2]), 0.20), 0.5,
			lerpf(float(r[1]), float(r[3]), 0.16))
		var g := GuaglioneScript.new()
		g.name = "Guaglione_" + str(z["id"])
		add_child(g)
		g.global_position = p
		g.configura(str(z["id"]), str(z["nome"]),
			Vector3(r[0], 0, r[1]), Vector3(r[2], 0, r[3]))


## **'A bacheca.** Una per piazza, nell'angolo opposto al guaglione: lui sta
## a un quinto dal lato di tramontana, questa a un quinto da quello di
## mezzogiorno, e cosi' non si coprono a vicenda ne' finiscono in mezzo alla
## coda delle auto.
##
## Guarda verso il centro della piazza — una bacheca girata verso il muro
## non la legge nessuno.
func _build_bacheche() -> void:
	for z in ZONE:
		var r: Array = z["rect"]
		# **Appoggiata ô muro 'e levante, no chiantata mmiez'â piazza.**
		# Stava all'82% della larghezza: cioè in mezzo all'aperto, con la
		# gente che ci passava dietro. Una bacheca sta contro qualcosa —
		# è l'unico modo in cui una si legge senza che qualcuno te la
		# nasconda passandoci davanti.
		var p := Vector3(float(r[2]) - 0.75, 0.0,
			lerpf(float(r[1]), float(r[3]), 0.72))
		var b := BachecaScript.new()
		b.name = "Bacheca_" + str(z["id"])
		b.zona_id = str(z["id"])
		b.nome_zona = str(z["nome"])
		add_child(b)
		b.global_position = Vector3(p.x, Collina.alzata(p.x, p.z), p.z)
		# Guarda dentro alla piazza, cioè verso −x: forward(θ) = (−sinθ, 0,
		# −cosθ), quindi per (−1, 0, 0) serve θ = +π/2.
		b.rotation.y = PI * 0.5


## **'O garage.** Uno per piazza.
##
## **Comm'era mmiso primma, e pecché era sbagliato.** Il commento diceva
## "sta sul bordo, addossato al muro" e il codice metteva la saracinesca al
## **10% della larghezza della piazza**, cioè un paio di metri *dentro*, in
## mezzo all'aperto. Una saracinesca è un buco in un muro: sospesa in mezzo
## al selciato, con l'aria che le passa dietro, è un fondale da teatro visto
## di fianco. E girava pure verso il centro invece che verso la strada.
##
## Adesso: **filo del bordo**, e dietro le si costruisce il suo pezzo di
## muro — largo sette metri e alto cinque, con l'intonaco del quartiere.
## Così la saracinesca è quello che deve essere, un'apertura dentro a una
## parete, anche dove il palazzo più vicino sta a qualche metro.
## **'O GARAGE 'E SOTT'Ô STADIO** (0.57)
##
## Il capo: *«Implementa il sistema di rubare le auto e portarle al garage,
## che adesso è in una zona diversa della città e bisogna portare le auto in
## quella zona appositamente.»*
##
## Prima ce n'era **uno per piazza**, sul filo di ponente, a venti metri da
## dove lavori. Era comodo e per questo non contava niente: rubavi una
## macchina, facevi dieci secondi di manovra e avevi finito. Un furto che si
## chiude prima che qualcuno se ne accorga non è un furto, è un bottone.
##
## Adesso è **uno solo**, a (176, 61) — cioè **centoquarantotto metri** dalla
## piazza di casa, dall'altra parte della città, sul Corso che corre sotto lo
## stadio. E quei centoquarantotto metri sono tutto il gioco nuovo: è il
## tempo in cui la macchina rubata è addosso a te, con due stelle accese e i
## carabinieri che sanno che colore è.
##
## Il posto non è scelto a occhio: è il più lontano fra quelli che stanno
## **fuori da tutte e quattro le piazze**, fuori dagli isolati, e **a tre
## metri da una strada larga** — perché una saracinesca in fondo a un
## vicolo da quattro metri non la imbocchi con una macchina, e il gioco
## nuovo sarebbe morto lì.
const POSTO_GARAGE := Vector3(176.0, 0.0, 60.4)
## Guarda la strada, cioè verso +Z: forward(θ) = (−sinθ, 0, −cosθ), quindi
## per (0, 0, +1) serve θ = π.
const GIRO_GARAGE: float = PI


func _build_garage() -> void:
	var p: Vector3 = POSTO_GARAGE
	var y: float = Collina.alzata(p.x, p.z)
	var qz: Dictionary = Quartieri.di(p.x, p.z)

	# Il muro dietro: un pezzo di facciata cieca, con lo zoccolo di pietra
	# come tutti gli altri piani terra della città. Sta **dietro** alla
	# saracinesca rispetto alla strada — cioè a −Z — con mezzo metro di
	# stacco: se le due superfici sono complanari il raggio
	# dell'interazione prende il muro e il garage non si apre più (è
	# successo, e l'ha trovato `prova_mira`).
	var muri: Array = qz["muri"]
	var tinte: Array = qz["tinte"]
	var zm: float = p.z - 1.05
	_pezzo(Vector3(p.x, y + 2.5, zm), Vector3(7.0, 5.0, 1.1),
		Tex.facciata(str(muri[0]), 7.0, 5.0, Color(tinte[0])),
		"garage_muro")
	_pezzo(Vector3(p.x, y + 1.3, zm - 0.03), Vector3(7.1, 2.6, 1.05),
		Tex.mondo(str(qz["zoccolo"]), Color(qz["zoccolo_tinta"]), 0.93),
		"garage_zoccolo")
	_solido(Vector3(p.x, y + 2.5, zm), Vector3(7.0, 5.0, 1.1))

	var g := GarageScript.new()
	g.name = "Garage"
	g.zona_id = "garage"
	g.nome_zona = "'O garage 'e sott'ô stadio"
	add_child(g)
	g.global_position = Vector3(p.x, y, p.z)
	g.rotation.y = GIRO_GARAGE


## Il selciato della zona: ogni posto ha la sua faccia.
func _pavimenta(x0: float, z0: float, x1: float, z1: float, id: String) -> void:
	var qs: Dictionary = Quartieri.di((x0 + x1) / 2.0, (z0 + z1) / 2.0)
	# Anche qui si passa dal catasto: la piazza del mercato e uno degli
	# slarghi si accavallano con un cardine, e senza taglio sfarfallano.
	for pz in _liberi(x0, z0, x1, z1):
		var w: float = pz.size.x
		var l: float = pz.size.y
		var mi := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(w, l)
		mi.mesh = pm
		mi.position = Vector3(pz.position.x + w / 2.0, 0.015,
			pz.position.y + l / 2.0)
		match id:
			"stadio":
				mi.material_override = Tex.ground("asfalto", Vector2(w, l), 8.0)
			"slargo":
				# Gli slarghi hanno il basolato del vicolo, non il lastricato
				# buono: sono allargamenti della strada, non piazze vere.
				var chiaro_sl: bool = str(qs["strada"]) == "basolato_chiaro"
				mi.material_override = Tex.mondo("basolato",
					Color(0.86, 0.80, 0.70) if chiaro_sl
					else Color(0.66, 0.62, 0.55), 0.88)
			"mercato":
				mi.material_override = Tex.ground("marciapiede", Vector2(w, l), 4.0)
			_:
				mi.material_override = Tex.ground("marciapiede", Vector2(w, l), 3.0)
		add_child(mi)


## Posti auto disegnati per terra: per ora sono scenografia (ci lavora il
## rivale), ma il segno c'è, così si capisce che è una zona da parcheggio.
## **I posti auto delle altre piazze erano dipinti, non veri.**
##
## Qui c'erano solo strisce bianche appoggiate per terra: belle da vedere e
## basta. I posti VERI — quelli che un'auto può occupare — esistevano
## soltanto nella piazza iniziale, ed è un bug che si vedeva solo dopo aver
## speso quattrocentocinquanta euro: compravi il mercato, dirigevi la prima
## auto, e quella puntava un posto libero **dall'altra parte della città**,
## perché `_start_parking` cerca il posto libero più vicino e i più vicini
## erano comunque a cento metri.
##
## Adesso ogni piazza ha i suoi posti veri, su tutte e due le fascie
## laterali: dai sei ai sedici a piazza, che per tre auto alla volta sono
## abbondanti e lasciano margine quando una resta ferma a lungo.
func _posti_auto(x0: float, z0: float, x1: float, z1: float) -> void:
	var z: float = z0 + 6.0
	while z < z1 - 6.0:
		for lato in [x0 + 4.5, x1 - 4.5]:
			var spot = PostoScript.new()
			spot.position = Vector3(lato, 0.13, z)
			add_child(spot)
		z += 5.2


## Il cartello all'ingresso della zona: dice dove sei e di chi è.
func _cartello_zona(z: Dictionary) -> void:
	var r: Array = z["rect"]
	var palo := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.06
	pm.bottom_radius = 0.06
	pm.height = 2.6
	palo.mesh = pm
	var pos := Vector3((r[0] + r[2]) / 2.0, 1.3,
		(r[3] + 2.5) if bool(z.get("ingresso_sud", false)) else (r[1] - 2.5))
	palo.position = pos
	palo.material_override = Tex.flat(Color(0.2, 0.2, 0.22), 0.5, 0.5)
	add_child(palo)

	var targa := Label3D.new()
	targa.text = str(z["nome"]) + "\n" + str(z["padrone"])
	targa.position = pos + Vector3(0, 1.6, 0)
	targa.font_size = 46
	targa.pixel_size = 0.0032
	targa.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	targa.modulate = Color(1.0, 0.86, 0.5)
	targa.outline_size = 18
	add_child(targa)


# ---------------------------------------------------------------------------
# Le cose caratteristiche
# ---------------------------------------------------------------------------

## Lo stadio: il modello che mi hai dato, ridotto da due milioni di
## triangoli a ventisettemila (per un fondale a settanta metri è più che
## abbastanza) e tinto per quota, che non aveva nessun colore suo.
## **Dove sta lo stadio.**
##
## Ha girato mezza mappa prima di trovare posto. Era a (136, 0, -46), fuori
## dal bordo nord: funzionava da fondale finche' li' fuori non c'era niente.
## Poi e' arrivata Mergellina e lo stadio si e' ritrovato dentro al mare, col
## campo verde a galla a venti metri dalla riva. L'ho spostato piu' al largo,
## su un promontorio — e la cosa e' peggiorata: dal lungomare lo stadio si
## vedeva spuntare DIETRO al Castel dell'Ovo, cioe' due monumenti di Napoli
## uno dentro all'altro, in mezzo all'acqua.
##
## Il posto giusto era l'unico che non avevo provato: dentro alla citta'.
## Fuorigrotta esiste gia' come quartiere (x 107-190, z 0-60) ed e' nato per
## questo; adesso l'impianto ci sta in mezzo per davvero, con la sua piazza
## intorno. Ci si gira attorno a piedi, lo si vede spuntare in fondo alle
## traverse, e il piazzale dove si posteggia e' il sagrato davanti — che e'
## esattamente il rapporto che c'e' fra lo stadio e piazzale Tecchio.
##
## Costo: l'impianto e' in scala ridotta rispetto al vero (quarantacinque
## metri di fronte invece di duecento). Ma tutta la citta' e' in scala
## ridotta — i vicoli sono larghi quattro metri e i palazzi alti sedici —
## e uno stadio a misura vera qui dentro sarebbe stato grande come tre
## quartieri.
const STADIO_CENTRO := Vector3(144.0, 0.0, 26.0)
const STADIO_LUNGO := 46.0
## Quanto si allunga in altezza rispetto alla scala in pianta. Il modello e'
## un impianto vero, cioe' basso e larghissimo: riportato a quarantacinque
## metri di fronte sarebbe uscito alto otto, meno dei palazzi intorno. Con
## due volte e mezzo arriva a venti e torna a essere la cosa piu' grossa del
## quartiere, che e' il punto.
const STADIO_ALTO: float = 2.5


func _build_stadio() -> void:
	var path := "res://assets/models/stadio.scn"
	if not ResourceLoader.exists(path):
		return
	var scena: PackedScene = load(path)
	if scena == null:
		return
	var st: Node3D = scena.instantiate()
	# Il modello è lungo un'unità: si scala alla misura dell'impianto.
	st.scale = Vector3(STADIO_LUNGO, STADIO_LUNGO * STADIO_ALTO, STADIO_LUNGO)
	# L'origine del modello sta a mezza altezza: alzandolo di quanto scende
	# la conca, il bordo inferiore appoggia sul piazzale invece di restare
	# mezzo sepolto.
	st.position = STADIO_CENTRO + Vector3(0.0, STADIO_LUNGO * STADIO_ALTO * 0.083, 0.0)
	add_child(st)
	for c in _tutte_le_mesh(st):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		# I colori dei vertici li ho scritti io guardando un monitor, quindi
		# sono in sRGB. Senza dirlo a Godot li tratta come lineari e lo
		# stadio esce quasi nero: una sagoma piatta senza gradinate.
		m.vertex_color_is_srgb = true
		# **La schiaritura, e perche' adesso va tolta.**
		#
		# Quando lo stadio era un fondale in controluce a duecento metri, la
		# sua faccia visibile stava sempre in ombra e usciva una sagoma
		# nera: l'albedo veniva moltiplicato per 1,22 e ci si aggiungeva
		# emissione, che a quella distanza funzionava.
		#
		# Adesso ci si cammina intorno, e quello stesso trucco spegneva
		# tutto: da tre metri il muro era una superficie grigia piatta,
		# senza gradinate e senza ombre. Con l'albedo a uno le pieghe della
		# copertura e gli anelli tornano a leggersi, perche' e' la luce vera
		# a disegnarli.
		m.albedo_color = Color(1.12, 1.12, 1.15)
		m.roughness = 0.9
		m.metallic = 0.0
		c.material_override = m

	# Il campo: si intravede dentro all'anello.
	var campo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(24.0, 16.0)
	campo.mesh = pm
	campo.position = STADIO_CENTRO + Vector3(0, 1.2, 0)
	campo.material_override = Tex.flat(Color(0.16, 0.36, 0.14), 0.95)
	add_child(campo)

	# La conca e' cava: senza collisioni ci si camminava dentro come in un
	# fantasma: ci si camminava dentro, e il parcheggiatore della zona ci
	# nasceva in mezzo.
	#
	# Il muro esterno e' fatto di ventiquattro lastroni disposti lungo
	# l'ellisse. Il primo tentativo ne aveva sedici e li girava di `-a`:
	# sbagliato di novanta gradi, cioe' ognuno stava di TAGLIO invece che di
	# piatto, e fra l'uno e l'altro restavano trenta metri di buchi da cui
	# si entrava comodamente. Con `-a - PI/2` il lato lungo e' tangente
	# all'ellisse, e a ventiquattro pezzi da nove metri il giro si chiude
	# con abbondanza.
	for i in range(24):
		var a: float = TAU * float(i) / 24.0
		var px: float = cos(a) * 21.0
		var pz: float = sin(a) * 17.5
		_solido(STADIO_CENTRO + Vector3(px, 9.5, pz),
			Vector3(9.0, 19.0, 3.4), -a - PI / 2.0)

	# Le torri faro, che di notte si accendono.
	for d in [Vector3(-21, 0, -15), Vector3(21, 0, -15),
			Vector3(-21, 0, 15), Vector3(21, 0, 15)]:
		var torre := MeshInstance3D.new()
		var tm := BoxMesh.new()
		tm.size = Vector3(1.0, 26.0, 1.0)
		torre.mesh = tm
		torre.position = STADIO_CENTRO + Vector3(0, 13.0, 0) + d
		torre.material_override = Tex.flat(Color(0.3, 0.31, 0.34), 0.7, 0.4)
		add_child(torre)
		var faro := MeshInstance3D.new()
		var fm := BoxMesh.new()
		fm.size = Vector3(4.0, 2.2, 0.6)
		faro.mesh = fm
		faro.position = STADIO_CENTRO + Vector3(0, 26.5, 0) + d
		faro.material_override = Tex.flat(
			Color(1.0, 0.97, 0.85), 0.4, 0.0, 2.2).duplicate()
		add_child(faro)
		var luce := OmniLight3D.new()
		luce.position = faro.position + Vector3(0, -2.0, 0)
		luce.light_color = Color(0.92, 0.95, 1.0)
		luce.light_energy = 3.0
		luce.omni_range = 60.0
		luce.shadow_enabled = false
		add_child(luce)
		if _ciclo:
			_ciclo.aggiungi_lampione(luce, faro)

	# L'insegna sul piazzale, sopra all'ingresso, rivolta al sagrato.
	var insegna := Label3D.new()
	insegna.text = "STADIO"
	insegna.position = STADIO_CENTRO + Vector3(0.0, 12.5, 19.5)
	insegna.font_size = 130
	insegna.pixel_size = 0.006
	insegna.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	insegna.double_sided = false
	insegna.modulate = Color(0.95, 0.95, 1.0)
	insegna.outline_size = 24
	add_child(insegna)


## Le macchine parcheggiate che fanno da arredo. Non sono clienti: sono
## lamiera ferma, e servono a far capire che il quartiere e' vissuto anche
## dove non stai lavorando tu.
## I modelli di auto ferma, e quanto sono lunghi in metri. Le sette del
## pack sono gia' in scala vera nel file, ma si passa lo stesso da
## `spawn_by_length`: e' l'unico modo di essere sicuri che una macchina non
## esca larga tre metri e mezzo perche' il file era in pollici.
## **`auto_pack_3` non c'e' piu', ed e' voluto.**
##
## Fotografato dall'alto e di fianco insieme agli altri nove, quel modello
## e' un guscio liscio: niente parabrezza, niente finestrini, niente fari,
## niente cofano. Duemila triangoli spesi per una capsula. Da terra si vede
## attraverso i pezzi che gli mancano, e sembra un'auto mezza trasparente —
## che e' esattamente come l'aveva descritta Massimo. Non e' un problema di
## materiale ne' di scala: e' il file che e' venuto male. Fuori.
##
## **I primi tre nomi non c'erano più** (0.59). `car_economica`,
## `car_berlina` e `car_lusso` erano i tre modelli della 0.30, spariti
## alla 0.46 quando il parco macchine è stato rifatto: il codice li
## chiamava ancora, `spawn` tornava null e il posto restava **vuoto**: sei
## posti su sedici del giro, cioè un posto in sosta su quattro in tutta la
## città, e nessuno li aveva mai contati. Adesso con
## quei nomi ci sono tre macchine del Car Pack, e con loro la coupé e la
## sportiva. Sono in scala vera (lunghezza 0 = com'è nel file): le misure
## vecchie, 2,66 per la piccola, la riducevano all'ottanta per cento.
const NOMI_SOSTA := ["car_economica", "car_berlina", "car_lusso",
	"auto_pack_1", "auto_pack_2", "auto_pack_4",
	"auto_pack_5", "auto_pack_6", "auto_pack_7", "car_coupe2",
	"car_sportiva2"]
const LUNGHE_SOSTA := [0.0, 0.0, 0.0, 4.5, 4.5, 4.4, 4.3, 4.5, 4.3, 0.0, 0.0]
## Un ordine mescolato a mano: preso in sequenza, nessuna coppia vicina si
## ripete e i modelli restano sparsi invece che ammucchiati.
const MODELLI_SOSTA := [3, 0, 7, 9, 1, 5, 2, 10, 8, 4, 0, 6, 1, 3, 9, 2, 7,
	5, 10, 4]


## L'ingombro del fabbricato della cornetteria (vedi `cornetteria_3d.gd`:
## nove per sei, col davanti sul bordo nord della sua zona più un metro e
## mezzo, e il corpo che va indietro verso −Z).
static func _dint_â_cornetteria(p: Vector3, orlo: float = 0.0) -> bool:
	var r: Array = ZONE[3]["rect"]
	var cx: float = (float(r[0]) + float(r[2])) * 0.5
	var fronte: float = float(r[1]) + 1.5
	return absf(p.x - cx) < 4.5 + orlo and p.z > fronte - 6.0 - orlo \
		and p.z < fronte + orlo


## Dove sta il monumento del piazzale dello stadio: in fondo al sagrato,
## sulla destra. Scritto una volta sola perché serve pure alle auto in sosta.
static func _posto_monumento() -> Vector3:
	var r: Array = ZONE[1]["rect"]
	return Vector3(float(r[2]) - 12.0, 0.0, float(r[3]) - 2.0 - 3.0)


func _auto_in_sosta() -> void:
	var tinte := [
		Color(0.62, 0.16, 0.14), Color(0.14, 0.2, 0.36), Color(0.72, 0.7, 0.66),
		Color(0.2, 0.32, 0.22), Color(0.5, 0.46, 0.14), Color(0.15, 0.15, 0.17),
		Color(0.55, 0.3, 0.12),
	]
	var punti: Array = []
	# Solo sulle strade larghe: in un vicolo da quattro metri un'auto in
	# doppia fila lo tapperebbe, e il giocatore non passerebbe più.
	# Lungo 'O Corso, appoggiate ai due marciapiedi.
	for z in range(10, int(PROFONDITA) - 10, 11):
		punti.append([Vector3(75.6, 0, float(z)), 0.0])
		punti.append([Vector3(80.4, 0, float(z)), 180.0])
	# Lungo Via Marina e Via 'e sotto.
	# A un metro e cinque dal bordo (0.59), non a un metro e sei: a 61,6 la
	# fiancata entrava di diciotto centimetri nella corsia del Decumano, e
	# la macchina restava senza corpo.
	for x in range(14, int(LARGHEZZA) - 14, 13):
		if absf(float(x) - 78.0) < 9.0:
			continue
		punti.append([Vector3(float(x), 0, 93.05), 90.0])
		punti.append([Vector3(float(x), 0, 97.95), -90.0])
		punti.append([Vector3(float(x), 0, 61.05), 90.0])
	# Sul piazzale dello stadio: in fila lungo i due fianchi dell'impianto
	# e sul fondo del sagrato. In mezzo non ci si mette piu' niente — in
	# mezzo adesso c'e' lo stadio.
	for i in range(7):
		punti.append([Vector3(113.0, 0, 12.0 + i * 5.5), 90.0])
		punti.append([Vector3(175.0, 0, 12.0 + i * 5.5), -90.0])
	for i in range(8):
		punti.append([Vector3(116.0 + i * 7.0, 0, 55.0), 0.0])
	# Le attività secondarie hanno la precedenza sulle auto in sosta. La
	# prima volta che ho messo la sala scommesse su 'O Corso, una berlina
	# parcheggiata ci finiva davanti e copriva mezza slot machine: da fuori
	# sembrava un bug della vetrina. Le auto sono scenografia, la slot no.
	var puliti: Array = []
	for p in punti:
		if _occupato_da_attivita(p[0], 4.2):
			continue
		# E soprattutto: mai davanti al varco di una zona. Un'auto ferma li'
		# non e' arredo, e' un tappo — e il cliente che non riesce a entrare
		# non ti dice perche' non entra, resta fermo in mezzo alla strada.
		if dentro_varco(p[0]):
			continue
		# Né sopra alla macchina dei vigili (0.59): sul sagrato dello stadio
		# la fila delle auto in sosta passava per lo stesso posto, e le due
		# macchine stavano una dentro all'altra, di traverso.
		var sui_vigili := false
		for zi in range(1, ZONE.size()):
			if Vector2(p[0].x, p[0].z).distance_to(Vector2(
					_angolo_vigili(ZONE[zi]).x, _angolo_vigili(ZONE[zi]).z)) < 5.5:
				sui_vigili = true
		if sui_vigili:
			continue
		# Né dentro al monumento (0.59). L'ultima auto della fila del sagrato
		# (165, 55) ci stava mezza dentro: finché al suo posto usciva uno dei
		# tre modelli che non c'erano più, il posto restava vuoto e non se
		# ne accorgeva nessuno; col parco macchine completo è venuta fuori.
		if Vector2(p[0].x, p[0].z).distance_to(Vector2(_posto_monumento().x,
				_posto_monumento().z)) < 4.6:
			continue
		# Né addosso a quello che c'è già: vetrine, lampioni, vasi, gente
		# ferma, posti dove si fa qualcosa (0.59).
		# Con tre quarti di metro d'aria intorno: fra un'auto e una vetrina
		# a un metro l'una dall'altra ci si infila un passante e non ne
		# esce più (una sacca che la griglia vede chiusa).
		if not _scatola_libera(p[0], Vector3(2.0, 1.7, 4.4),
				deg_to_rad(float(p[1])), 0.75):
			continue
		# E solo dove il corpo ce l'avrebbe: un'auto disegnata in mezzo a
		# un incrocio, senza corpo, è un fantasma (0.59).
		if not _puo_avere_corpo(p[0], Vector3(2.0, 1.7, 4.4),
				deg_to_rad(float(p[1]) + 2.5)):
			continue
		var addosso := false
		for g in GENTE_FERMA:
			if Vector2(float(g[0]), float(g[1])).distance_to(
					Vector2(p[0].x, p[0].z)) < 3.0:
				addosso = true
		for v in POSTI_VICINE:
			if Vector2(float(v[1]), float(v[2])).distance_to(
					Vector2(p[0].x, p[0].z)) < 3.2:
				addosso = true
		if addosso:
			continue
		puliti.append(p)
	punti = puliti

	var n := 0
	for p in punti:
		n += 1
		# Una su tre non e' un'automobile normale: e' il furgone in doppia
		# fila, l'Ape del fruttivendolo, il taxi. Senza, la strada sembra
		# un concessionario.
		var auto: Node3D
		if n % 3 == 0:
			auto = AutoVarieScript.a_caso()
			auto.position = p[0]
			auto.rotation.y = deg_to_rad(float(p[1]) + randf_range(-2.0, 2.0))
			add_child(auto)
			_solido(p[0] + Vector3(0, 0.85, 0), Vector3(2.0, 1.7, 4.4),
				auto.rotation.y)
			_lontananza(auto, 110.0)
			continue
		# **Il parco macchine in sosta.**
		#
		# Erano tre modelli in rotazione fissa, e su duecento auto ferme si
		# vedeva: ogni terza macchina della fila era identica alla terza
		# prima. Adesso ce ne sono dieci — i tre di sempre piu' le sette del
		# pack — e la scelta non e' piu' `n % 3` ma un rimescolamento, cosi'
		# nemmeno il PASSO si ripete.
		var i_mod: int = MODELLI_SOSTA[(n * 7 + (n / 3)) % MODELLI_SOSTA.size()]
		var nome: String = str(NOMI_SOSTA[i_mod])
		auto = Models.spawn_by_length(nome, float(LUNGHE_SOSTA[i_mod]))
		if auto == null:
			continue
		auto.position = p[0]
		auto.rotation.y = deg_to_rad(float(p[1]) + randf_range(-2.0, 2.0))
		Models.tint(auto, ["body", "car", "paint", "carrozzeria"],
			tinte[n % tinte.size()], 0.35, 0.35)
		Models.polish_vehicle(auto)
		add_child(auto)
		_solido(p[0] + Vector3(0, 0.8, 0), Vector3(1.95, 1.6, 4.3),
			auto.rotation.y)
		_lontananza(auto, 110.0)


# ---------------------------------------------------------------------------
# Negozi, verde, arredo
# ---------------------------------------------------------------------------

## I negozi. Non ci si compra niente (per quello ci sono 'O Zio, il Bazar e
## il tabaccaio): servono a far sembrare le strade delle strade. Un vicolo
## di Napoli senza una pizzeria, un fruttivendolo e un'edicola non è un
## vicolo, è un corridoio.
const NEGOZI := [
	["PIZZERIA", Color(0.82, 0.24, 0.2), Color(0.95, 0.86, 0.5)],
	["BAR", Color(0.2, 0.42, 0.62), Color(0.9, 0.9, 0.86)],
	["FRUTTA E VERDURA", Color(0.24, 0.5, 0.28), Color(0.95, 0.8, 0.3)],
	["FERRAMENTA", Color(0.45, 0.42, 0.38), Color(0.9, 0.88, 0.82)],
	["PARRUCCHIERE", Color(0.58, 0.3, 0.5), Color(0.96, 0.9, 0.94)],
	["EDICOLA", Color(0.3, 0.34, 0.4), Color(0.92, 0.9, 0.85)],
	["PANE E DOLCI", Color(0.74, 0.52, 0.22), Color(0.96, 0.88, 0.66)],
	["PESCHERIA", Color(0.22, 0.46, 0.56), Color(0.88, 0.94, 0.96)],
	["FIORI", Color(0.6, 0.28, 0.42), Color(0.98, 0.9, 0.92)],
	["LAVANDERIA", Color(0.35, 0.45, 0.55), Color(0.94, 0.94, 0.92)],
]


## **'E vetrine attuorno ê piazze (0.55, rifatte nella 0.59).**
##
## Le ventotto di prima stavano tutte sul Corso e su Via Marina, cioè
## lontano da dove si lavora. Finché erano scenografia non importava; da
## quando sono la **meta delle commissioni** degli autisti, importa
## moltissimo: se il negozio più vicino alla tua piazza sta a quarantatré
## metri, ogni cliente che scende attraversa mezza città e torna, e la
## sosta diventa lunga il doppio del previsto.
##
## **Com'erano e perché non c'erano più.** Nella 0.55 erano sedici righe
## scritte a mano (`x, z, verso`). Poi la città è stata ridisegnata (i
## decumani, i cardini, la 0.56) e quelle coordinate sono rimaste dov'erano:
## dentro ai vicoli, mezzo metro dentro ai palazzi. Il controllo del punto
## di sosta le scartava tutte e sedici, **in silenzio**, e la prova contava
## solo che le vetrine in totale fossero almeno venti — cosa che le tenevano
## su quelle di Via Marina. Che però erano girate **verso il muro**: la
## bottega costruita dentro al palazzo, e l'autista che andava a guardare
## una facciata vuota. La 0.59 ha aggiunto il controllo che dietro alla
## vetrina ci sia un palazzo, quelle sono cadute, e il conto è sceso a
## quindici: così si è visto tutto il resto.
##
## Adesso i posti non si scrivono più: si **leggono dalla pianta**. Per ogni
## isolato, i lati che guardano la piazza (o la strada) da meno di dieci
## metri; su quei lati un posto ogni sei metri; e per ogni piazza si
## tengono i quattro più vicini al centro che passano tutti i controlli.


## Le facciate che guardano un rettangolo: per ogni isolato, i lati che gli
## girano la faccia da non più di `entro` metri. Restituisce `[x, z, verso]`
## a venti centimetri dal muro, ogni `passo` metri; il verso è quello dove
## la vetrina guarda, cioè (sin verso, 0, cos verso).
static func _facciate_verso(rect: Rect2, entro: float, passo: float) -> Array:
	var fore: Array = []
	for b in ISOLATI:
		if e_galera(b):
			continue
		var x0: float = float(b[0])
		var z0: float = float(b[1])
		var x1: float = float(b[2])
		var z1: float = float(b[3])
		# [inizio, lungo la faccia, normale verso fuori, lunghezza, verso]
		var facce := [
			[Vector2(x0, z0), Vector2(1, 0), Vector2(0, -1), x1 - x0, 180.0],
			[Vector2(x0, z1), Vector2(1, 0), Vector2(0, 1), x1 - x0, 0.0],
			[Vector2(x0, z0), Vector2(0, 1), Vector2(-1, 0), z1 - z0, -90.0],
			[Vector2(x1, z0), Vector2(0, 1), Vector2(1, 0), z1 - z0, 90.0],
		]
		for f in facce:
			var lung: float = float(f[3])
			if lung < 6.0:
				continue
			var n: int = maxi(1, int(floorf(lung / passo)))
			for k in n:
				var t: float = lung * (float(k) + 0.5) / float(n)
				var su_muro: Vector2 = (f[0] as Vector2) + (f[1] as Vector2) * t
				var la_guarda := false
				var d := 2.0
				while d <= entro + 0.001:
					if rect.has_point(su_muro + (f[2] as Vector2) * d):
						la_guarda = true
						break
					d += 1.0
				if not la_guarda:
					continue
				var p: Vector2 = su_muro + (f[2] as Vector2) * 0.2
				fore.append([p.x, p.y, float(f[4])])
	return fore


func _build_vetrine() -> void:
	# Attaccati alle facciate degli isolati che danno su 'O Corso, su Via
	# Marina e sulle quattro piazze. Nei vicoli non ce ne sono di veri: lì
	# il piano terra è già serrande e portoni, che li fa il costruttore
	# degli isolati.
	#
	# `ang` è dove GUARDA la vetrina: il negozio è costruito verso il +z
	# locale, quindi guarda in (sin ang, 0, cos ang).
	var posti := []
	# Lato di ponente d''o Corso (facciata a x=74, guarda verso +x)
	for i in range(5):
		posti.append([Vector3(74.2, 0, 9.0 + i * 12.0), 90.0])
	for i in range(4):
		posti.append([Vector3(74.2, 0, 102.0 + i * 12.0), 90.0])
	# Lato di levante (facciata a x=82, guarda verso -x)
	for i in range(5):
		posti.append([Vector3(81.8, 0, 8.0 + i * 12.0), -90.0])
	for i in range(3):
		posti.append([Vector3(81.8, 0, 70.0 + i * 12.0), -90.0])
	var n := 0
	var messe: Array = []
	for p in posti:
		n = _prova_vetrina(p[0], float(p[1]), n, messe)
	# Via Marina: le facciate che la guardano davvero, dai due lati. Erano
	# scritte a mano girate verso il muro (vedi sopra).
	var marina := 0
	for c in _facciate_verso(Rect2(0.0, 93.0, 190.0, 5.0), 3.5, 11.0):
		if marina >= 8:
			break
		var prima := n
		n = _prova_vetrina(Vector3(float(c[0]), 0.0, float(c[1])), float(c[2]), n, messe)
		if n > prima:
			marina += 1
	# Le piazze: i quattro posti buoni più vicini al centro di ognuna.
	for z in ZONE:
		var r: Array = z["rect"]
		var rect := Rect2(float(r[0]), float(r[1]), float(r[2]) - float(r[0]),
			float(r[3]) - float(r[1])).grow(1.0)
		var centro: Vector2 = rect.get_center()
		var cand: Array = _facciate_verso(rect, 10.0, 6.0)
		cand.sort_custom(func(a, b): return Vector2(float(a[0]), float(a[1])).distance_to(centro) \
			< Vector2(float(b[0]), float(b[1])).distance_to(centro))
		var qui := 0
		for c in cand:
			if qui >= 4:
				break
			var prima := n
			n = _prova_vetrina(Vector3(float(c[0]), 0.0, float(c[1])), float(c[2]), n, messe)
			if n > prima:
				qui += 1


## Prova a mettere una vetrina: i controlli di `_posto_pe_vetrina`, più la
## distanza dalle altre vetrine (sette metri: una bottega è larga quattro e
## mezzo), dai muri dei manifesti, dallo sfasciacarrozze, dalla gente ferma
## e dai vicini affacciati. Restituisce il conto aggiornato.
func _prova_vetrina(pos: Vector3, ang: float, n: int, messe: Array) -> int:
	var dove: Dictionary = _posto_pe_vetrina(pos, ang)
	if not dove["ok"]:
		return n
	var p: Vector3 = dove["pos"]
	var p2 := Vector2(p.x, p.z)
	for m in messe:
		if (m as Vector2).distance_to(p2) < 7.0:
			return n
	for mf in POSTI_MANIFESTI:
		if Vector2(float(mf[1]), float(mf[2])).distance_to(p2) < 4.0:
			return n
	if Vector2(POSTO_GARAGE.x, POSTO_GARAGE.z).distance_to(p2) < 7.5:
		return n
	var r := deg_to_rad(ang)
	var merce := p2 + Vector2(sin(r), cos(r)) * 1.2
	for g in GENTE_FERMA:
		if Vector2(float(g[0]), float(g[1])).distance_to(merce) < 2.6:
			return n
	for v in POSTI_VICINE:
		if Vector2(float(v[1]), float(v[2])).distance_to(merce) < 2.6:
			return n
	_una_vetrina(p, ang, n)
	messe.append(p2)
	return n + 1


## **Addò se ferma uno ca guarda 'na vetrina.**
##
## Un metro e mezzo davanti al vetro, che è la distanza giusta. Ma non
## sempre: su una via stretta un metro e mezzo di marciapiede non c'è, e
## quel punto cade **in mezzo alla carreggiata**. Finché le vetrine erano
## scenografia non importava a nessuno; da quando ci va davvero qualcuno
## (le commissioni degli autisti, 0.55) importa, perché quel qualcuno si
## pianta in mezzo alla strada a guardare le scarpe.
##
## La prova ne ha trovate **nove così**, e stavano lì da nove versioni.
##
## Quindi il punto non è un numero fisso: si prova a scalare — un metro e
## mezzo, poi un metro e un quarto, poi novanta centimetri — e si tiene il
## primo che sta fuori dalla corsia libera e fuori dai varchi delle auto.
## Se non ne passa nessuno, ci si mette proprio sotto al vetro: appiccicato
## alla vetrina è brutto, in mezzo alla strada è rotto.
const NEGOZIO_DISTANZE := [1.6, 1.25, 0.95, 0.7]


func _punto_bbuono(p: Vector3) -> bool:
	# **E ha da stà pure fore d''o palazzo** (0.56).
	#
	# Questa riga in meno è costata cara, e vale la pena raccontarla. Il
	# punto dove l'autista si ferma a guardare la vetrina veniva
	# controllato per due cose — che non fosse in mezzo alla carreggiata e
	# che non fosse dentro a un varco — e per nessun'altra. **Mancava
	# quella che conta**: che non fosse dentro al palazzo.
	#
	# Misurato: **diciotto vetrine su quarantaquattro** avevano il punto di
	# sosta dentro al muro, a due metri di profondità. Cioè quasi la metà
	# degli autisti, ogni volta che scendeva a fare la spesa, entrava
	# **dentro all'isolato** e ci restava mezzo minuto.
	#
	# Ed è **esattamente la cosa che il capo ha visto** (punto 8: *«molti
	# png attraversano i muri… anche i guidatori quando vanno via»*). Non
	# era un problema di collisioni: era che gli avevo dato appuntamento
	# dentro a un palazzo. Il codice dei muri l'ha scoperto, non causato —
	# prima ci camminavano dentro e nessuno se ne accorgeva.
	return not in_corsia(p, Vector3(0.7, 1.8, 0.7)) and not dentro_varco(p) \
		and not dint_ô_palazzo(p, 0.45)


func _addo_se_ferma(pos: Vector3, ang: float) -> Vector3:
	var davanti := Vector3(sin(ang), 0.0, cos(ang))
	# **E si 'a vetrina sta girata a ll'incontrario, se prova 'a ll'ata
	# parte.** Qualche facciata nasce con l'angolo di novanta gradi
	# sbagliato: davanti al vetro c'è il muro e dietro c'è la strada. Prima
	# non se ne accorgeva nessuno perché il punto lo prendeva lo stesso;
	# adesso che il punto dev'essere all'aperto, tanto vale guardare pure
	# dall'altro lato invece di buttare la bottega.
	for verso in [1.0, -1.0]:
		for d in NEGOZIO_DISTANZE:
			var p: Vector3 = pos + davanti * (verso * float(d))
			if _punto_bbuono(p):
				return p
	return pos + davanti * float(NEGOZIO_DISTANZE[-1])


## **'E vetrine ncopp'ô crocevia nun ce ponno stà.**
##
## Scalare la distanza dal vetro risolve la via stretta, non l'incrocio:
## se la bottega capita dove il Corso taglia una traversa, **lei stessa**
## sta in mezzo alla carreggiata, e non c'è offset che la salvi — davanti
## al vetro è strada in tutti i casi. Ed è giusto così: su un incrocio non
## c'è facciata, c'è l'angolo.
##
## Allora si prova a **scorrere lungo la facciata** di tre e di sei metri,
## in tutte e due le direzioni: quasi sempre bastano, perché l'incrocio è
## largo quanto la traversa. Se non basta, il negozio non si costruisce
## proprio — una vetrina in meno non la nota nessuno, una vetrina in mezzo
## alla strada sì.
const NEGOZIO_SCORRE := [0.0, 3.2, -3.2, 6.4, -6.4, 9.6, -9.6]


## **'A puteca ha da stà appujata a 'nu muro** (0.59). Dieci vetrine su
## quaranta stavano sugli incroci — fra due palazzi, davanti a niente — e
## la loro merce in mezzo alla strada che passava di traverso. Dietro alla
## bottega, per tutta la sua larghezza, ci dev'essere un palazzo.
static func _facciata_dereto(p: Vector3, avanti: Vector3, lato: Vector3) -> bool:
	for d in [-2.0, 0.0, 2.0]:
		if not dint_ô_palazzo(p - avanti * 0.6 + lato * float(d), 0.0):
			return false
	return true


func _posto_pe_vetrina(pos: Vector3, ang: float) -> Dictionary:
	var r := deg_to_rad(ang)
	# Lungo la facciata: perpendicolare a dove guarda la vetrina.
	var lato := Vector3(cos(r), 0.0, -sin(r))
	var avanti := Vector3(sin(r), 0.0, cos(r))
	var ragioni: Array = []
	for s in NEGOZIO_SCORRE:
		var p: Vector3 = pos + lato * float(s)
		var punto: Vector3 = _addo_se_ferma(p, r)
		# E davanti al vetro, dove sta la merce, non ci ha da stà già
		# niente (0.59): un lampione, un vaso, un motorino appoggiato.
		var perche := ""
		if not _punto_bbuono(punto):
			perche = "punto"
		elif _occupato_da_attivita(p, 5.0):
			perche = "attivita"
		elif not _facciata_dereto(p, avanti, lato):
			perche = "facciata"
		elif not _scatola_libera(p + avanti * 0.9, Vector3(4.6, 0.8, 1.4), r, 0.05):
			perche = "merce"
		elif not _puo_avere_corpo(p + avanti * 0.9, Vector3(4.6, 0.8, 1.4), r):
			perche = "corpo"
		if perche == "":
			return {"ok": true, "pos": p}
		ragioni.append("%+.1f:%s" % [float(s), perche])
	_vetrine_scartate.append([pos, ang, ragioni])
	return {"ok": false}


## Le vetrine che non hanno trovato posto, e perché (per ogni scorrimento
## lungo la facciata): la legge `prova_commissione` quando ne mancano.
var _vetrine_scartate: Array = []


## Una vetrina: tenda a righe, insegna, vetro con dentro qualcosa, e una
## luce che di notte si accende insieme ai lampioni.
func _una_vetrina(pos: Vector3, ang: float, i: int) -> void:
	var dati: Array = NEGOZI[i % NEGOZI.size()]
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = deg_to_rad(ang)
	add_child(root)

	# **'E vetrine mo' so' 'e mete d''e commissiune (0.55).**
	#
	# Erano scenografia e basta: bellissime e inutili. Adesso ognuna è un
	# posto **dove qualcuno va** — l'autista che scende dalla macchina si
	# sceglie la più vicina e ci cammina davanti (vedi
	# `driver_3d._parte_p_a_spesa`). Non c'è niente da comprare e non si
	# preme nessun tasto: serve che la gente abbia un motivo per
	# attraversare la piazza, e questo è il motivo.
	#
	# `punto` è dove si sta fermi: un metro e mezzo davanti al vetro, che
	# è la distanza a cui uno guarda una vetrina senza appoggiarcisi.
	root.add_to_group("negozi")
	root.set_meta("punto", _addo_se_ferma(pos, root.rotation.y))
	root.set_meta("nome", str(dati[0]))

	# **'A vetrina nun teneva niente 'a dinto.**
	#
	# Era un parallelepipedo di colore piatto schiarito a metà: da fuori
	# un rettangolo **grigio** alto due metri e quaranta, largo quattro, e
	# basta. Nelle foto di collaudo della 0.46 è la cosa che salta
	# all'occhio per prima, perché una vetrina vuota non sembra un negozio
	# chiuso — sembra un pezzo di gioco non finito.
	#
	# Adesso sono tre cose invece di una: il **fondo** scuro della bottega
	# (che è pure quello che si accende la sera), **tre ripiani con la
	# merce** sopra, e davanti il **vetro vero** — trasparente, liscio,
	# che di giorno riflette il cielo e di sera lascia vedere la luce
	# dentro. Il vetro è un piano e non una scatola: una scatola
	# trasparente mostra pure le sue facce di dietro, e si vedono.
	var vetro := MeshInstance3D.new()
	var vm := BoxMesh.new()
	vm.size = Vector3(4.2, 2.4, 0.08)
	vetro.mesh = vm
	vetro.position = Vector3(0, 1.4, -0.42)
	var mv := Tex.flat(Color(dati[2]) * 0.22, 0.72, 0.0, 0.35).duplicate()
	vetro.material_override = mv
	root.add_child(vetro)

	# 'A merce ncopp'ê ripiane. Il seme è il numero del negozio: la
	# bottega davanti a casa tua ha sempre la stessa roba in vetrina.
	var rngv := RandomNumberGenerator.new()
	rngv.seed = 7000 + i * 31
	var legno := Tex.flat(Color(0.34, 0.24, 0.16), 0.88)
	for r in range(3):
		var y_r: float = 0.62 + float(r) * 0.72
		var ripiano := MeshInstance3D.new()
		var rpm := BoxMesh.new()
		rpm.size = Vector3(3.7, 0.06, 0.42)
		ripiano.mesh = rpm
		ripiano.position = Vector3(0, y_r, -0.18)
		ripiano.material_override = legno
		root.add_child(ripiano)
		for k in range(4):
			var scatola := MeshInstance3D.new()
			var sbm := BoxMesh.new()
			var alt: float = rngv.randf_range(0.16, 0.38)
			sbm.size = Vector3(rngv.randf_range(0.22, 0.6), alt,
				rngv.randf_range(0.16, 0.3))
			scatola.mesh = sbm
			scatola.position = Vector3(-1.5 + float(k) * 1.0
				+ rngv.randf_range(-0.14, 0.14), y_r + alt * 0.5 + 0.03,
				-0.18 + rngv.randf_range(-0.05, 0.05))
			scatola.rotation.y = rngv.randf_range(-0.25, 0.25)
			# **'E scatole nun ponno essere tutte d''o stesso culore.**
			# Al primo giro le tingevo mescolando i due colori
			# dell'insegna: in una vetrina viola veniva fuori una fila di
			# mattoncini lilla tutti uguali, che è peggio del grigio di
			# prima perché sembra fatto apposta. Metà prendono il colore
			# della bottega, metà un colore di scatola qualunque — cartone,
			# rosso, verde, blu, giallo — che è quello che c'è davvero su
			# un ripiano.
			var col_sc: Color
			if rngv.randf() < 0.45:
				col_sc = Color(dati[1]).lerp(Color(dati[2]),
					rngv.randf_range(0.1, 0.75))
			else:
				col_sc = [Color(0.72, 0.58, 0.38), Color(0.74, 0.24, 0.20),
					Color(0.22, 0.46, 0.30), Color(0.20, 0.34, 0.58),
					Color(0.86, 0.72, 0.24), Color(0.88, 0.86, 0.80)][
						rngv.randi() % 6]
			scatola.material_override = Tex.flat(col_sc, 0.75)
			root.add_child(scatola)

	var lastra := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(4.2, 2.4)
	lastra.mesh = qm
	lastra.position = Vector3(0, 1.4, 0.1)
	var mq := StandardMaterial3D.new()
	mq.albedo_color = Color(0.62, 0.70, 0.76, 0.26)
	mq.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mq.metallic = 0.55
	mq.roughness = 0.07
	mq.cull_mode = BaseMaterial3D.CULL_BACK
	lastra.material_override = mq
	root.add_child(lastra)

	# La cornice del negozio.
	for d in [-2.3, 2.3]:
		var mont := MeshInstance3D.new()
		var mm := BoxMesh.new()
		mm.size = Vector3(0.35, 2.9, 0.4)
		mont.mesh = mm
		mont.position = Vector3(d, 1.45, 0.14)
		mont.material_override = Tex.flat(Color(dati[1]).darkened(0.35), 0.9)
		root.add_child(mont)

	# La tenda a righe.
	for k in range(9):
		var riga := MeshInstance3D.new()
		var rm := BoxMesh.new()
		rm.size = Vector3(0.53, 0.09, 1.5)
		riga.mesh = rm
		riga.position = Vector3(-2.12 + k * 0.53, 3.1, 0.75)
		riga.rotation.x = deg_to_rad(-14)
		riga.material_override = Tex.flat(
			Color(dati[1]) if k % 2 == 0 else Color(0.94, 0.92, 0.88), 0.92)
		root.add_child(riga)

	var insegna := Label3D.new()
	insegna.text = str(dati[0])
	insegna.position = Vector3(0, 3.55, 0.3)
	insegna.font_size = 44
	insegna.pixel_size = 0.0075
	insegna.modulate = Color(dati[2])
	insegna.outline_size = 16
	# **Mai leggibile d''a dereto.** `Label3D` nasce a due facce, e da
	# dietro il testo si vede **specchiato**: girando per Via Marina si
	# leggeva "ЭЯЭIHOOUЯЯAꟼ" sulla schiena delle botteghe del lato
	# opposto. Un'insegna si legge da davanti e da dietro non esiste.
	insegna.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	insegna.double_sided = false
	root.add_child(insegna)

	var luce := OmniLight3D.new()
	luce.position = Vector3(0, 2.6, 1.4)
	luce.light_color = Color(dati[2])
	luce.light_energy = 0.0
	luce.omni_range = 9.0
	luce.shadow_enabled = false
	luce.distance_fade_enabled = true
	luce.distance_fade_begin = 40.0
	luce.distance_fade_length = 12.0
	root.add_child(luce)
	if _ciclo:
		_ciclo.aggiungi_lampione(luce, vetro)
	# La luce delle vetrine di notte è più bassa dei lampioni.
	luce.set_meta("energia_notte", 1.1)

	# Due cassette di merce davanti, che è quello che si vede da lontano.
	_lontananza(root, 95.0)
	# La cornice del negozio e le cassette davanti: si sporgono sul
	# marciapiede e vanno aggirate.
	var avanti := Vector3(sin(root.rotation.y), 0.0, cos(root.rotation.y))
	_solido(pos + avanti * 0.9 + Vector3(0, 0.4, 0), Vector3(4.6, 0.8, 1.4),
		root.rotation.y)
	#
	# **'E cassette stevano tutte a Mergellina** (0.59). Le due cassette si
	# costruivano con la posizione **della bottega** (±1,3 di lato, 1,1 in
	# avanti) e si davano a `_batched`, che però legge la posizione come
	# posizione **del mondo**: non erano figlie della bottega, erano figlie
	# di nessuno. Risultato: le ottanta cassette di tutte le quaranta
	# vetrine stavano una dentro all'altra in due mucchi accanto all'origine
	# della città, sul bordo del mare, e davanti alle botteghe non c'era
	# niente — da sette versioni. Adesso davanti a ogni bottega c'è la sua
	# merce vera (vedi `_merce_davanti`), e le scatole di ripiego, se i
	# modelli mancassero, si mettono dove vanno.
	if not _merce_davanti(pos, root.rotation.y, str(dati[0]), i):
		for d2 in [-1.3, 1.3]:
			var cassa := MeshInstance3D.new()
			var cm := BoxMesh.new()
			cm.size = Vector3(0.9, 0.5, 0.6)
			cassa.mesh = cm
			cassa.position = _in_locale(pos, root.rotation.y, d2, 0.25, 1.1)
			cassa.rotation.y = root.rotation.y
			cassa.material_override = Tex.flat(Color(0.5, 0.36, 0.24), 0.9)
			_batched("cassa", cassa)


## **'A merce fore â puteca** (0.59). Ogni bottega mette fuori quello che
## vende, ed è la cosa che da lontano dice che bottega è prima
## dell'insegna: le cassette d'arance del fruttivendolo, la legna della
## pizzeria, i secchi e la carriola del ferramenta, i vasi del fioraio, le
## pile di giornali dell'edicola. Sta tutto dentro all'ingombro che la
## bottega aveva già (il corpo solido di 4,6 × 1,4 davanti al vetro), quindi
## non si aggiunge niente da scansare.
##
## `x` lungo la facciata, `z` in avanti: il vetro sta a z = 0, il bordo del
## corpo solido a z = 1,6.
func _merce_davanti(pos: Vector3, giro: float, nome: String, i: int) -> bool:
	if not Models.has_model("cascetta_2"):
		return false
	var rng := RandomNumberGenerator.new()
	rng.seed = 5100 + i * 17
	const G := "bottega"
	var dritto: float = giro
	match nome:
		"FRUTTA E VERDURA":
			var frutta: Array = ["arancia", "mela", "limone", "pummarola",
				"mandarino", "pera", "peperone", "mulignana", "patana",
				"cepolla", "carota", "friariello"]
			for k in range(4):
				var x: float = -1.75 + float(k) * 1.17
				var f: String = str(frutta[rng.randi() % frutta.size()])
				var alto: bool = k == 0 or k == 3
				if alto:
					_panda("cassa_grossa_legno", _in_locale(pos, giro, x, 0.0, 1.05),
						dritto, G)
				_cascetta_chiena(f, _in_locale(pos, giro, x,
					0.6 if alto else 0.0, 1.05), dritto + rng.randf_range(-0.06, 0.06),
					rng, G, 0.0)
		"PIZZERIA":
			# 'A legna p''o furno: due cataste a piramide, i ciocchi lungo
			# la facciata. E i sacchi della farina dall'altra parte.
			for catasta in [1.22, 1.72]:
				var strati := [4, 3, 2, 1]
				for st in range(strati.size()):
					var n: int = strati[st]
					for c in range(n):
						var zc: float = 1.05 + (float(c) - float(n - 1) * 0.5) * 0.125
						_panda(["legna_1", "legna_2", "legna_3"][rng.randi() % 3],
							_in_locale(pos, giro, catasta, float(st) * 0.11, zc),
							dritto + rng.randf_range(-0.12, 0.12), G)
			_panda("sacco_1", _in_locale(pos, giro, -1.55, 0.0, 1.0),
				dritto + rng.randf_range(-0.4, 0.4), G)
			_panda("sacco_2", _in_locale(pos, giro, -1.0, 0.0, 1.1),
				dritto + rng.randf_range(-0.4, 0.4), G)
			# E in mezzo la cassa con la pizza a portafoglio appena
			# sfornata, il tagliere col mattarello e la rotella.
			_panda("cassa_grossa_legno", _in_locale(pos, giro, 0.1, 0.0, 1.05),
				dritto, G)
			_panda("pizza", _in_locale(pos, giro, -0.02, 0.6, 1.0),
				rng.randf_range(-PI, PI), G)
			_panda("tagliere", _in_locale(pos, giro, 0.27, 0.6, 1.1),
				dritto + 0.2, G)
			_panda("mattarello", _in_locale(pos, giro, 0.27, 0.612, 1.1),
				dritto + PI * 0.5 + 0.2, G)
			_panda("rotella_pizza", _in_locale(pos, giro, -0.05, 0.604, 1.26),
				dritto + 1.2, G)
		"BAR":
			# 'A cascetta d''e buttiglie d''acqua, appena scaricata.
			var cb: Vector3 = _in_locale(pos, giro, -1.45, 0.0, 1.05)
			_panda("cascetta_3", cb, dritto, G)
			for r in range(2):
				for c in range(3):
					_panda("bottiglia_acqua", _in_locale(pos, giro,
						-1.45 + (float(c) - 1.0) * 0.16, 0.02,
						1.05 + (float(r) - 0.5) * 0.14), rng.randf_range(-PI, PI), G)
			_panda("pianta_casa_4", _in_locale(pos, giro, 1.7, 0.0, 0.9),
				rng.randf_range(-PI, PI), G)
		"FERRAMENTA":
			_panda("carriola", _in_locale(pos, giro, -1.45, 0.0, 1.0),
				dritto + rng.randf_range(-0.1, 0.1), G)
			_panda("secchio_1", _in_locale(pos, giro, 0.95, 0.0, 1.15),
				rng.randf_range(-PI, PI), G)
			_panda("secchio_2", _in_locale(pos, giro, 1.3, 0.0, 1.2),
				rng.randf_range(-PI, PI), G)
			_panda("annaffiatoio", _in_locale(pos, giro, 1.1, 0.0, 0.8),
				dritto + rng.randf_range(-0.6, 0.6), G)
			# 'A pala e 'o rastiello appujate ô muro, storte comme stanno.
			for att in [["pala", 1.62], ["rastrello", 1.86], ["zappa", 2.1]]:
				var base_t: Vector3 = _in_locale(pos, giro, float(att[1]), 0.0, 0.52)
				var b := Basis(Vector3.UP, dritto) * Basis(Vector3.RIGHT, -0.2)
				_panda_t(str(att[0]), Transform3D(b, base_t), G)
		"PARRUCCHIERE":
			_panda("pianta_casa_6", _in_locale(pos, giro, -1.8, 0.0, 0.8),
				rng.randf_range(-PI, PI), G)
			_panda("pianta_casa_3", _in_locale(pos, giro, 1.8, 0.0, 0.8),
				rng.randf_range(-PI, PI), G)
		"EDICOLA":
			for x in [-1.3, 1.3]:
				_panda("cassa_grossa_legno", _in_locale(pos, giro, x, 0.0, 1.05),
					dritto, G)
				for dx in [-0.15, 0.15]:
					for k in range(rng.randi_range(3, 6)):
						_panda("giornali", _in_locale(pos, giro, x + dx
							+ rng.randf_range(-0.02, 0.02), 0.6 + float(k) * 0.021,
							1.05 + rng.randf_range(-0.03, 0.03)),
							dritto + PI * 0.5 + rng.randf_range(-0.15, 0.15), G)
		"PANE E DOLCI":
			for x in [-1.3, 1.3]:
				_panda("cassa_grossa_legno", _in_locale(pos, giro, x, 0.0, 1.05),
					dritto, G)
				_cascetta_chiena("pane", _in_locale(pos, giro, x, 0.6, 1.05),
					dritto, rng, G, 0.0)
		"PESCHERIA":
			# Il pesce non c'è nel pacchetto: c'è il ghiaccio (il letto
			# chiaro) e i limoni, che al banco del pesce non mancano mai.
			for x in [-1.3, 1.3]:
				_panda("cassa_grossa_legno", _in_locale(pos, giro, x, 0.0, 1.05),
					dritto, G)
				_cascetta_chiena("limone", _in_locale(pos, giro, x, 0.6, 1.05),
					dritto, rng, G, 0.0, Color(0.84, 0.9, 0.94))
		"FIORI":
			var vasi: Array = ["fiori_1", "fiori_3", "fiori_4", "fiori_5",
				"fiori_6", "fiori_2", "pianta_casa_3", "pianta_casa_4",
				"pianta_casa_6", "pianta_grassa_1", "pianta_grassa_2"]
			for x in [-1.95, -1.45, -0.95, 0.95, 1.45, 1.95]:
				_panda(str(vasi[rng.randi() % vasi.size()]),
					_in_locale(pos, giro, x, 0.0, 1.2 + rng.randf_range(-0.08, 0.08)),
					rng.randf_range(-PI, PI), G)
			for x2 in [-1.7, 1.7]:
				_panda(str(vasi[rng.randi() % vasi.size()]),
					_in_locale(pos, giro, x2, 0.0, 0.7), rng.randf_range(-PI, PI), G)
		"LAVANDERIA":
			_panda("sacco_3", _in_locale(pos, giro, -1.6, 0.0, 1.0),
				rng.randf_range(-PI, PI), G)
			_panda("sacco_4", _in_locale(pos, giro, -1.15, 0.0, 1.1),
				rng.randf_range(-PI, PI), G)
		_:
			return false
	return true


## Alberi, siepi, panchine, cestini: il verde e l'arredo che riempiono i
## vuoti fra una cosa e l'altra.
## I sei manifesti della collezione.
##
## Le posizioni non sono a caso e non sono nemmeno "in un angolo": sono
## tutte FUORI dalle quattro zone e fuori dalle strade principali, nelle
## fasce di asfalto che restano ai bordi della citta' e in mezzo agli
## isolati. Sono posti dove il gioco non ti porta mai — ci vai solo se ti
## metti a girare — ed e' esattamente il requisito di un easter egg.
##
## `ang` e' dove GUARDA il manifesto. Il riparo nasce sempre davanti alla
## faccia scritta, quindi arrivando dalla direzione naturale si vede il
## cassonetto (o il furgone, o il ponteggio) e basta: il foglio si scopre
## solo girandoci intorno.
const POSTI_MANIFESTI := [
	# id            x       z      guarda   riparo
	["treno",      23.8,  163.0,   270.0,  "casse"],
	["leggende",  182.8,   40.0,   270.0,  "cassonetto"],
	["teduccio",   65.0,  117.4,   180.0,  "casse"],
	["maradona",  169.9,  117.0,   270.0,  "cassonetto"],
	["pino_james",143.0,   77.9,   180.0,  "casse"],
	["bud",        91.8,  140.0,   270.0,  "cassonetto"],
]


func _build_manifesti() -> void:
	for p in POSTI_MANIFESTI:
		var dati: Dictionary = GameManager.manifesto_dati(str(p[0]))
		if dati.is_empty():
			continue
		var m := ManifestoScript.new()
		m.name = "Manifesto_" + str(p[0])
		m.configura(dati, str(p[4]))
		m.position = Vector3(float(p[1]), 0.0, float(p[2]))
		m.rotation.y = deg_to_rad(float(p[3]))
		add_child(m)


# ---------------------------------------------------------------------------
# Napoli sui muri: murales, stencil, bandierine
# ---------------------------------------------------------------------------

## I due murales dipinti, quelli grossi. Sono foto vere di murales di
## Napoli, e valgono per quello che sono: due punti della città che si
## riconoscono da lontano e servono a orientarsi meglio di qualunque cartello.
##
##   x, z, angolo di dove guarda, base, larghezza, altezza, texture
const MURALES := [
	# Il dieci di spalle col cuore rosso, nel vicolo di ponente.
	[9.1, 46.0, 90.0, 1.15, 2.4, 3.2, "murale_maradona"],
	# Pulcinella coi tag intorno, su 'O Corso.
	[74.1, 52.0, 90.0, 1.4, 3.2, 2.4, "murale_pulcinella"],
	# Un secondo Maradona verso il mercato: il quartiere del mercato è
	# quello dove la gente ci passa di più a piedi.
	[54.9, 109.0, 270.0, 1.15, 2.1, 2.8, "murale_maradona"],
	# --- 'E graffite d''a 0.46 ---
	#
	# Non è un murale disegnato: è la **foto di un muro vero** pieno di
	# tag sovrapposti, presa a Perugia. La differenza si vede: un murale
	# è una cosa che qualcuno ha voluto fare, i tag sono quello che
	# succede a un muro lasciato lì per vent'anni. Servono tutt'e due, e
	# i tag molto più spesso.
	[9.1, 96.0, 90.0, 1.30, 3.0, 2.6, "graffiti"],
	[119.9, 84.0, 270.0, 1.35, 3.2, 2.4, "graffiti"],
	[45.9, 128.0, 270.0, 1.25, 2.6, 2.2, "graffiti"],
	[74.1, 143.0, 90.0, 1.30, 2.8, 2.4, "graffiti"],
]

## Gli stencil: la faccia di Maradona con la bomboletta, piccola, ripetuta.
## Uno stencil non è un murale — è una cosa che si fa in tre secondi e si
## trova ovunque, e infatti qui ce ne sono sette sparsi.
## Le coordinate NON sono a occhio: ogni riga è un punto verificato che sta
## a filo di un isolato vero e ha davanti a sé due metri di spazio
## calpestabile. Uno stencil piazzato a mano finisce dentro a un muro o in
## mezzo alla strada, e non te ne accorgi finché non ci passi davanti.
const STENCIL := [
	[54.9, 30.0, 270.0, 1.70],    # uscendo dalla piazza, verso levante
	[81.9, 100.0, 270.0, 1.90],   # 'O Corso, all'incrocio con Via Marina
	[29.9, 90.0, 270.0, 1.60],    # sopra 'o mercato
	[139.0, 127.9, 180.0, 2.00],  # 'o Vommero, dove i muri sono puliti
	[40.9, 139.0, 270.0, 1.75],   # 'o largo d''e guagliune
	[119.9, 69.0, 270.0, 1.80],   # sotto 'o stadio
	[158.9, 111.0, 270.0, 1.65],  # verso Posillipo
]

## Le bandierine azzurre tese da un lato all'altro del vicolo. Due punti e
## quante bandierine: si appendono a una catenaria fra i due.
const BANDIERINE := [
	[9.5, 40.0, 12.5, 40.0, 9],       # vicolo di ponente
	[51.5, 88.0, 54.5, 88.0, 9],
	[74.5, 30.0, 81.5, 30.0, 15],     # 'O Corso, tesa lunga
	[103.5, 145.0, 106.5, 145.0, 9],
	[129.5, 110.0, 132.5, 110.0, 9],
	[16.5, 141.0, 39.5, 141.0, 26],   # 'o largo d''e guagliune, da parte a parte
	[179.5, 78.0, 182.5, 78.0, 9],
]


func _build_murales() -> void:
	for m in MURALES:
		_pannello_muro(Vector3(float(m[0]), float(m[3]), float(m[1])),
			deg_to_rad(float(m[2])), float(m[4]), float(m[5]), str(m[6]),
			false)
	for s in STENCIL:
		# 1,05 x 1,3: la misura vera di uno stencil da bomboletta, quello
		# che uno si porta arrotolato sotto il giubbotto.
		_pannello_muro(Vector3(float(s[0]), float(s[3]), float(s[1])),
			deg_to_rad(float(s[2])), 1.05, 1.3, "stencil_maradona", true)
	for b in BANDIERINE:
		_bandierine(Vector3(float(b[0]), 5.6, float(b[1])),
			Vector3(float(b[2]), 5.6, float(b[3])), int(b[4]))


## Un rettangolo dipinto appoggiato a un muro. `alfa` è per lo stencil, che
## è un PNG con la trasparenza: senza, lo sfondo bianco del file coprirebbe
## l'intonaco e si vedrebbe un francobollo attaccato al palazzo.
##
## Il quad sta **due centimetri** davanti al piano del muro. Non è un numero
## a caso: a filo del muro le due superfici sono complanari e la GPU non sa
## quale disegnare davanti, e si vede quello sfarfallio a scacchiera che
## abbiamo già passato con le facciate.
func _pannello_muro(pos: Vector3, ang: float, w: float, h: float,
		tex: String, alfa: bool) -> void:
	var percorso := "res://assets/textures/%s.%s" % [tex, "png" if alfa else "jpg"]
	if not ResourceLoader.exists(percorso):
		return
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(w, h)
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(percorso)
	m.roughness = 0.94
	m.metallic = 0.0
	# Un murale è pittura su intonaco: non riflette niente, e con lo
	# specular acceso sotto il sole di mezzogiorno diventa un pannello
	# lucido appeso al muro.
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	if alfa:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.35
	mi.material_override = m
	# La normale del quad è +Z, quindi ruotarlo di `ang` lo fa guardare
	# esattamente dove serve, con la solita convenzione della città.
	mi.rotation.y = ang
	var avanti := Vector3(sin(ang), 0.0, cos(ang))
	mi.position = pos + avanti * 0.02 + Vector3(0, h * 0.5, 0)
	add_child(mi)


## La fila di gagliardetti azzurri tesa da un muro all'altro. La corda non è
## dritta: cala nel mezzo come una corda vera, e le bandierine più in basso
## sono quelle centrali. Con la corda dritta sembrano una decalcomania.
func _bandierine(a: Vector3, b: Vector3, quante: int) -> void:
	if not ResourceLoader.exists("res://assets/textures/bandiera_napoli.png"):
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load("res://assets/textures/bandiera_napoli.png")
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.4
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.9
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED

	var luce: float = a.distance_to(b)
	# La corda cala di circa un ventesimo della campata: di più sembra
	# smollata, di meno sembra un filo di ferro.
	var calo: float = luce * 0.055

	# La corda vera e propria, un cilindro sottile per segmento.
	var corda_mat := StandardMaterial3D.new()
	corda_mat.albedo_color = Color(0.2, 0.19, 0.18)
	corda_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED

	var punto := func(u: float) -> Vector3:
		var p: Vector3 = a.lerp(b, u)
		# Parabola: zero agli estremi, massima nel mezzo.
		p.y -= calo * 4.0 * u * (1.0 - u)
		return p

	var segmenti: int = maxi(6, quante)
	for i in range(segmenti):
		var p0: Vector3 = punto.call(float(i) / segmenti)
		var p1: Vector3 = punto.call(float(i + 1) / segmenti)
		var c := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.012
		cm.bottom_radius = 0.012
		cm.height = p0.distance_to(p1)
		cm.radial_segments = 4
		c.mesh = cm
		c.material_override = corda_mat
		c.position = (p0 + p1) * 0.5
		# Il cilindro nasce lungo Y: lo si punta lungo il segmento.
		var d: Vector3 = (p1 - p0).normalized()
		if absf(d.dot(Vector3.UP)) < 0.999:
			c.look_at_from_position(c.position, c.position + d, Vector3.UP)
			c.rotate_object_local(Vector3.RIGHT, PI / 2.0)
		add_child(c)

	for i in range(quante):
		var u: float = (float(i) + 0.5) / float(quante)
		var p: Vector3 = punto.call(u)
		var f := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.2, 0.24)
		f.mesh = q
		f.material_override = mat
		f.position = p - Vector3(0, 0.13, 0)
		# Ogni gagliardetto è girato un po' diverso: sono di plastica
		# leggera e stanno come gli pare.
		f.rotation.y = randf_range(-0.5, 0.5)
		f.rotation.z = randf_range(-0.12, 0.12)
		add_child(f)


# ---------------------------------------------------------------------------
# Le attività secondarie: le tre carte, la scopa, la sala scommesse
# ---------------------------------------------------------------------------

## Dove stanno i tavolini della scopa. Tutti in slarghi o ai bordi delle
## piazze: un tavolo con quattro sedie non ci sta in un vicolo da quattro
## metri, e infatti a Napoli i vecchi giocano negli slarghi.
##
## **Cinche cose dint'ô stesso punto** (0.59). Quattro di questi cinque
## tavolini stavano esattamente dove, qualche versione dopo, sono arrivati i
## tavoli della scopa vera (`TAVULE_SCOPA`, 0.45), le panchine e — nel largo
## d''e guagliune — il campetto (0.56): vecchi seduti dentro ad altri vecchi,
## panchine dentro ai tavolini, un tavolo in mezzo alla porta del campetto.
## E tre su cinque stavano sulla corsia libera del cardine che attraversa lo
## slargo. Li ha trovati `prova_ngombri`; adesso ogni slargo è diviso in due
## dalla sua corsia, e le cose stanno ai lati.
const POSTI_SCOPA := [
	[34.0, 2.6, 0.4],       # 'o belvedere, sopra 'a piazza
	[20.8, 139.0, 1.1],     # 'o largo d''e guagliune, 'o lato 'e ponente
	[123.5, 138.0, -0.6],   # lo slargo di levante, 'o lato 'e levante
	[163.0, 164.5, 2.2],    # 'o Vommero, a ponente d''a corsia
	[60.5, 83.8, 0.3],      # 'a piazzetta d''a fontana, a ponente
]

## 'O gioco d''e tre carte. La rotazione conta: il banco guarda verso il +Z
## locale, cioè da lì arriva il giocatore.
##
## **Erano uno, mo' so' tre (0.52).** Alla 0.51 ce n'era uno solo, e la
## nota diceva *"ne serve uno e basta — se ce ne fossero tre non sarebbe
## più una truffa, sarebbe un servizio pubblico"*. Era una buona battuta e
## una diagnosi sbagliata: il problema di un tavolo solo non è che la
## truffa si banalizzi, è che **se stai dall'altra parte della città non
## esiste**. Tre tavoli in tre punti lontani sono la stessa truffa incontrata
## tre volte, che è esattamente come funziona per strada — e il compare che
## te la rifà in un altro vicolo è più credibile di quello che ti aspetta
## sempre nello stesso posto.
const POSTI_TRE_CARTE := [
	[69.5, 80.0, 0.0],        # 'a piazzetta d''a fontana (0.59: fore d''a corsia)
	[24.5, 143.0, 1.6],       # 'o largo d''e guagliune, spalle ô muro
	[150.0, 96.0, -1.2],      # 'nu vico 'e levante
]

## 'E ssale scommesse. Quella del Corso c'era già; le altre due stanno dove
## sta la gente che ha appena preso i soldi — vicino al mercato e sotto lo
## stadio.
const POSTI_SCOMMESSE := [
	[81.8, 78.0, 270.0],      # 'o Corso, 'o lato 'e levante
	[112.0, 141.0, 180.0],    # 'o slargo d''o mercato
	[171.0, 155.0, 90.0],     # sotto 'o campo
]


## Vero se il punto cade dentro `raggio` metri da una delle attività
## secondarie. Serve a tenere libero lo spazio davanti a un tavolo o a una
## vetrina prima che ci finisca sopra dell'arredo urbano.
## **I varchi: le corsie da cui entrano ed escono le auto dei clienti.**
##
## Ogni zona giocabile ha un ingresso e un'uscita su una strada, e le auto
## ci passano guidate da una manciata di punti fissi. Il problema e' che
## tutto quello che riempie la citta' — auto in sosta, motorini appoggiati,
## panchine, alberi — viene piazzato da regole geometriche che di quei
## punti non sanno niente: una berlina parcheggiata a mezzo metro dall'asse
## del varco della piazza iniziale tappava l'ingresso, e i clienti si
## fermavano fuori senza che si capisse perche'.
##
## Qui dentro ci sono i rettangoli da tenere sgombri. Sono corsie, non
## piazze: larghe una decina di metri e lunghe quanto basta a fare la
## manovra d'ingresso.
const VARCHI := [
	[18.0, 56.0, 31.0, 69.0],      # 'o varco d''a piazza toia
	[104.0, 26.0, 122.0, 38.0],    # piazzale d''o stadio, da ponente
	[166.0, 26.0, 186.0, 38.0],    # e l'uscita a levante
	[7.0, 106.0, 15.0, 117.0],     # 'o mercato
	[48.0, 106.0, 58.0, 117.0],
	[126.0, 106.0, 140.0, 117.0],  # 'a cornetteria
	[150.0, 106.0, 164.0, 117.0],
]


## **'A corsia libera: il mezzo di ogni strada resta sgombro.**
##
## L'audit di percorribilita' ha misurato che il quattordici per cento del
## suolo calpestabile era ostruito e che il sette per cento non era
## raggiungibile affatto: pezzi di strada tagliati fuori perche' l'arredo,
## messo da venti funzioni diverse che non si parlano fra loro, aveva
## chiuso il passaggio.
##
## Controllare ogni oggetto uno per uno non e' una soluzione: basta
## aggiungere una funzione domani e il problema torna. La regola invece
## vale per sempre — **in mezzo a ogni strada corrono due metri e venti in
## cui non si piazza niente di solido**. In un vicolo da quattro restano
## novanta centimetri per lato, che bastano a un motorino appoggiato al
## muro; su una strada larga resta tutto lo spazio delle auto in sosta.
##
## E siccome il pianificatore garantisce gia' che il grafo delle strade e'
## connesso, una corsia libera per ogni strada garantisce che la citta' sia
## attraversabile. Non e' una pezza: e' un invariante.
const CORSIA: float = 1.10


static func in_corsia(pos: Vector3, dim: Vector3) -> bool:
	var mx: float = maxf(dim.x, dim.z) * 0.5
	for s in STRADE:
		var x0: float = float(s[0])
		var z0: float = float(s[1])
		var x1: float = float(s[2])
		var z1: float = float(s[3])
		var w: float = x1 - x0
		var l: float = z1 - z0
		if l > w:
			# Strada che corre lungo Z: la corsia e' una striscia verticale.
			if pos.z + mx < z0 or pos.z - mx > z1:
				continue
			var cx: float = (x0 + x1) / 2.0
			if absf(pos.x - cx) < CORSIA + mx:
				return true
		else:
			if pos.x + mx < x0 or pos.x - mx > x1:
				continue
			var cz: float = (z0 + z1) / 2.0
			if absf(pos.z - cz) < CORSIA + mx:
				return true
	return false


## **Dint'a 'nu slargo 'a corsia nun è 'nu muro** (0.59). La corsia libera
## serve a garantire che ogni strada si possa attraversare; ma quando una
## strada passa in mezzo a uno slargo largo sedici metri, una fontana o un
## pino sulla sua riga di mezzo si girano intorno senza pensarci. Lì una
## cosa piccola (fino a due metri e mezzo) può avere il suo corpo anche
## sulla corsia: la fontana della piazzetta, i due pini del belvedere.
static func _in_slargo_piccolo(pos: Vector3, dim: Vector3) -> bool:
	if maxf(dim.x, dim.z) > 2.5:
		return false
	for sl in SLARGHI:
		if pos.x > float(sl[0]) + 2.0 and pos.x < float(sl[2]) - 2.0 \
				and pos.z > float(sl[1]) + 1.0 and pos.z < float(sl[3]) - 1.0:
			return true
	return false


## Vicino al muraglione del Vomero (che si costruisce per ultimo, e quindi
## chi mette l'arredo prima non lo trova nel catasto): il muraglione sta a
## cavallo del bordo del terrapieno e sporge quarantacinque centimetri nelle
## strade intorno.
static func _vicino_â_collina(p: Vector3, orlo: float) -> bool:
	var x0: float = Collina.RECT[0]
	var z0: float = Collina.RECT[1]
	var x1: float = Collina.RECT[2]
	var z1: float = Collina.RECT[3]
	if p.x < x0 - orlo or p.x > x1 + orlo or p.z < z0 - orlo or p.z > z1 + orlo:
		return false
	return minf(minf(absf(p.x - x0), absf(p.x - x1)),
		minf(absf(p.z - z0), absf(p.z - z1))) < orlo


## Se un corpo così, lì, lo avrebbe davvero (vedi `_solido`): chi mette una
## cosa che si deve sbattere lo chiede **prima** di disegnarla, così non
## resta disegnata una cosa che si attraversa.
func _puo_avere_corpo(pos: Vector3, dim: Vector3, ang: float = 0.0) -> bool:
	if maxf(dim.x, maxf(dim.y, dim.z)) > 5.0:
		return true
	if dentro_varco(pos):
		return false
	if _vicino_â_collina(pos, 0.5 + maxf(dim.x, dim.z) * 0.5):
		return false
	return not in_corsia_girato(pos, dim, ang) or _in_slargo_piccolo(pos, dim)


## Come `in_corsia`, ma col corpo girato: quanto sporge davvero lungo X e
## lungo Z una scatola larga `dim.x`, profonda `dim.z` e girata di `ang`.
static func in_corsia_girato(pos: Vector3, dim: Vector3, ang: float) -> bool:
	var c: float = absf(cos(ang))
	var sn: float = absf(sin(ang))
	var ex: float = c * dim.x * 0.5 + sn * dim.z * 0.5
	var ez: float = sn * dim.x * 0.5 + c * dim.z * 0.5
	for s in STRADE:
		var x0: float = float(s[0])
		var z0: float = float(s[1])
		var x1: float = float(s[2])
		var z1: float = float(s[3])
		if (z1 - z0) > (x1 - x0):
			if pos.z + ez < z0 or pos.z - ez > z1:
				continue
			if absf(pos.x - (x0 + x1) * 0.5) < CORSIA + ex:
				return true
		else:
			if pos.x + ex < x0 or pos.x - ex > x1:
				continue
			if absf(pos.z - (z0 + z1) * 0.5) < CORSIA + ez:
				return true
	return false


static func dentro_varco(p: Vector3) -> bool:
	for v in VARCHI:
		if p.x >= float(v[0]) and p.x <= float(v[2]) \
				and p.z >= float(v[1]) and p.z <= float(v[3]):
			return true
	return false


# ---------------------------------------------------------------------------
# 'E MURE: ADDÓ NUN SE PASSA
# ---------------------------------------------------------------------------
#
# **'O guaio** (0.56, punto 8 d''o capo): *«Occhio che molti png attraversano
# i muri, succede ad esempio ai bambini che giocano ma anche ai guidatori
# quando vanno via.»*
#
# La ragione è una sola e sta scritta in tutti i personaggi:
#
#     global_position = global_position.move_toward(meta, passo)
#
# Non è movimento: è **teletrasporto a piccoli passi**. Non passa dal motore
# fisico, quindi non gli importa niente che in mezzo ci sia un palazzo — il
# `collision_mask` di quei nodi poteva pure essere giusto, non lo guardava
# nessuno. Mettere `move_and_slide()` dappertutto avrebbe voluto dire
# riscrivere nove personaggi e rischiare che si incastrassero tutti nello
# stesso pomeriggio.
#
# **'A soluzione**: gli isolati sono già scritti qua sopra, e sono
# rettangoli. Un punto dentro a un rettangolo si riconosce con quattro
# confronti, e si spinge fuori dalla faccia più vicina con altri quattro.
# Non è la fisica, ma per gente che cammina su una città fatta di scatole è
# esattamente la stessa cosa — e costa nulla, e si può provare a testa
# ferma senza far girare il motore.
#
# Il passo vero sta in `scripts/passo.gd`, che chiama queste due.

## Il punto sta dentro a un palazzo? `orlo` allarga l'isolato di quanto è
## largo mezzo corpo, così non ci si appiccica col naso al muro.
static func dint_ô_palazzo(p: Vector3, orlo: float = 0.0) -> bool:
	for b in ISOLATI:
		if p.x > float(b[0]) - orlo and p.x < float(b[2]) + orlo \
				and p.z > float(b[1]) - orlo and p.z < float(b[3]) + orlo:
			return true
	return false


## Le quattro uscite dal palazzo che si sta toccando (anche solo di
## striscio: `orlo` più cinque centimetri), dalla più vicina alla più
## lontana. Ogni uscita sta fuori da una faccia, e lungo la faccia è
## tenuta a `orlo` dagli spigoli: uscire dal lato corto di un isolato
## d'angolo non deve rimettere nel muro di confine (vedi `Passo.fore`).
static func uscite_d_ô_palazzo(p: Vector3, orlo: float = 0.40) -> Array:
	var fore: Array = []
	for b in ISOLATI:
		var x0: float = float(b[0])
		var z0: float = float(b[1])
		var x1: float = float(b[2])
		var z1: float = float(b[3])
		var g: float = orlo + 0.05
		if p.x < x0 - g or p.x > x1 + g or p.z < z0 - g or p.z > z1 + g:
			continue
		var fuori: float = orlo + 0.02
		var lx: float = clampf(p.x, x0 + orlo, x1 - orlo)
		var lz: float = clampf(p.z, z0 + orlo, z1 - orlo)
		fore.append(Vector3(x0 - fuori, p.y, lz))
		fore.append(Vector3(x1 + fuori, p.y, lz))
		fore.append(Vector3(lx, p.y, z0 - fuori))
		fore.append(Vector3(lx, p.y, z1 + fuori))
	fore.sort_custom(func(a, b): return (a as Vector3).distance_squared_to(p) \
		< (b as Vector3).distance_squared_to(p))
	return fore


## Se il punto è finito dentro a un palazzo lo rimette fuori, dalla faccia
## più vicina. Se non ci è finito lo restituisce com'era.
##
## Si esce sempre dal lato più corto: è quello da cui sei entrato, salvo
## che tu non abbia attraversato l'isolato intero — e in quel caso ti
## conviene comunque uscire da dove sei arrivato.
static func fore_d_ô_palazzo(p: Vector3, orlo: float = 0.40) -> Vector3:
	for b in ISOLATI:
		var x0: float = float(b[0]) - orlo
		var z0: float = float(b[1]) - orlo
		var x1: float = float(b[2]) + orlo
		var z1: float = float(b[3]) + orlo
		if p.x <= x0 or p.x >= x1 or p.z <= z0 or p.z >= z1:
			continue
		var d_ovest: float = p.x - x0
		var d_est: float = x1 - p.x
		var d_sud: float = p.z - z0
		var d_nord: float = z1 - p.z
		var minima: float = minf(minf(d_ovest, d_est), minf(d_sud, d_nord))
		var fore: Vector3 = p
		if minima == d_ovest:
			fore.x = x0
		elif minima == d_est:
			fore.x = x1
		elif minima == d_sud:
			fore.z = z0
		else:
			fore.z = z1
		# Uno solo per volta: due isolati attaccati (e ce ne sono) si
		# risolvono al passo dopo, che è quello che farebbe pure uno che
		# cammina.
		return fore
	return p


func _occupato_da_attivita(p: Vector3, raggio: float) -> bool:
	var r2: float = raggio * raggio
	for s in POSTI_SCOPA:
		if Vector2(p.x - float(s[0]), p.z - float(s[1])).length_squared() < r2:
			return true
	for t in POSTI_TRE_CARTE:
		if Vector2(p.x - float(t[0]), p.z - float(t[1])).length_squared() < r2:
			return true
	for b in POSTI_SCOMMESSE:
		if Vector2(p.x - float(b[0]), p.z - float(b[1])).length_squared() < r2:
			return true
	return false


## La gente ferma: quelli appoggiati al muro davanti al bar, quelli che
## aspettano qualcuno all'angolo, quello fuori alla sala scommesse.
##
## ## Perché NON usiamo più i modelli comprati
##
## Fino alla 0.45 questa gente era `passante_a` e `passante_b`, due modelli
## comprati "molto meglio delle figure a scatole che costruisce il rig" —
## così diceva questo commento, e non era vero.
##
## Sono modelli rigidi, senza scheletro che il gioco sappia muovere, e la
## loro posa di riposo è la **posa a T**: braccia aperte all'altezza delle
## spalle, come un manichino da sartoria. Fermi in mezzo alla strada non
## erano "arredamento umano", erano dodici crocifissi in giacca e cravatta
## sparsi per la città. Nella foto davanti alla fontana si vede benissimo,
## e si vedeva da otto versioni.
##
## Il rig del gioco è più povero di poligoni ma **sta in piedi come una
## persona**: respira, sposta il peso, muove la testa. Fra un modello bello
## in posa sbagliata e uno semplice in posa giusta vince sempre il secondo,
## e questa è la stessa lezione delle animazioni scartate alla 0.45 —
## misurare la posa, non fidarsi di come è fatto il file.
##
##   x, z, verso in gradi, quale modello
const GENTE_FERMA := [
	[80.6, 62.0, 250.0, "passante_a"],    # fuori al bar su 'O Corso
	[75.4, 88.0, 100.0, "passante_b"],
	[52.6, 46.0, 275.0, "passante_a"],    # all'angolo uscendo dalla piazza
	[11.6, 100.0, 85.0, "passante_b"],    # verso 'o mercato
	[80.0, 80.5, 200.0, "passante_b"],    # 'o palo della sala scommesse
	[67.3, 78.3, 232.0, "passante_a"],    # a guardare 'e tre carte
	[24.8, 134.8, 270.0, "passante_b"],   # al largo, a guardà 'a partita
	[105.4, 130.0, 95.0, "passante_a"],
	[130.6, 118.0, 260.0, "passante_b"],
	[157.4, 140.0, 80.0, "passante_a"],
	[36.0, 4.0, 170.0, "passante_b"],     # 'o belvedere
	[121.0, 63.5, 190.0, "passante_a"],   # sotto 'o stadio
]


## **'O vicinato: quatte perzone ca stanno sempe llà (0.54).**
##
## Non passano: **stanno**. È l'unica differenza che conta rispetto ai
## passanti, e vale più di qualsiasi personalità scritta nella tabella —
## uno che ritrovi allo stesso angolo ogni giorno, dopo tre giorni, non è
## un modello 3D: è il tuo vicino. Le facce che si muovono sono già dodici,
## quello che mancava era qualcuno che non si muovesse mai.
##
## I quattro posti sono scelti su un criterio solo: **sulla strada che fai
## comunque**. Nunzia sta all'angolo fuori dalla tua piazza, Totore al
## portone del palazzo sul Corso, Rosa affacciata al vico stretto, Mimmo al
## largo dove stanno i guagliuni. Nessuno dei quattro obbliga a una
## deviazione, e nessuno sta dentro a un varco o in mezzo a una corsia
## (`prova_vicinato` lo verifica).
##
## I quattro punti **non sono scelti a occhio**. La prima stesura li aveva
## a (52,49) e (78,68), che sembravano due angoli e invece stavano dentro
## alla corsia libera del Decumano: due corpi con il collider piantati in
## mezzo alla strada, per sempre. `prova_vicinato` li ha bocciati subito, e
## quelli qui sotto vengono da una scansione che cerca il punto libero più
## vicino a quello voluto **con tre metri e mezzo di ingombro** — cioè con
## un metro abbondante di margine, non appena appena fuori.
##
##   id, x, z, verso in gradi
const POSTI_VICINE := [
	["nunzia_bar", 50.0, 49.0, 250.0],     # ll'angolo asciuto d''a piazza
	["totore", 80.9, 68.0, 265.0],         # 'o purtone ncopp'ô Corso
	["rosa", 62.0, 104.5, 95.0],           # affacciata dint'ô vico
	["mimmo", 25.3, 139.2, 270.0],         # 'o largo, a bordo campo
]


## **'A Signora sta 'n coppa a 'nu posto sulo, e cagna ogni juorno.**
##
## Dove, lo decide `GameManager._scegli_a_signora()` la mattina; una
## giornata su quattro non esce affatto. Qui si costruisce e basta: se il
## GameManager dice che oggi non c'e', non si mette niente — e non si mette
## nemmeno un nodo invisibile, se no il raggio del player lo trova lo
## stesso e ci parli con una che non si vede.
## **'O boss 'e capitolo esce dint'â piazza soia, no dint'â toia** (0.55).
##
## È la differenza che lo separa da Borrelli: Borrelli ti viene a cercare
## dove stai, questo ti aspetta **dove gli hai tolto il posto**. Devi
## andarci tu, e quello è metà del senso della cosa — la piazza nuova
## smette di essere un rubinetto e torna a essere un posto con qualcuno
## dentro.
func _arriva_o_boss(zona: String) -> void:
	var info: Dictionary = GameManager.boss_capitolo(zona)
	if info.is_empty():
		return
	var dove := Vector3.ZERO
	for z in ZONE:
		if str(z["id"]) != zona:
			continue
		var r: Array = z["rect"]
		dove = Vector3((float(r[0]) + float(r[2])) * 0.5, 0.0,
			(float(r[1]) + float(r[3])) * 0.5)
	if dove == Vector3.ZERO:
		return
	var b = BossCapitoloScript.new()
	b.configura(zona, info)
	add_child(b)
	b.global_position = dove
	GameManager.event_started.emit(
		"%s t'aspetta dint'â piazza ca t'hê pigliato. Va' a vedé."
		% str(info["nome"]))


func _build_signora() -> void:
	var dove: Dictionary = GameManager.signora_dove()
	if dove.is_empty():
		return
	var s = SignoraLottoScript.new()
	add_child(s)
	s.global_position = Vector3(dove["p"])


func _build_vicinato() -> void:
	for v in POSTI_VICINE:
		var n = VicinoScript.new()
		n.setup(str(v[0]), Vector3(float(v[1]), 0.0, float(v[2])))
		n.rotation.y = deg_to_rad(float(v[3]))
		add_child(n)


var _lontananza_id: int = 0


func _build_gente_ferma() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 771903
	# Vestiti da gente di quartiere, non da comparse: camicie chiare,
	# giacche scure, qualche colore acceso e basta.
	var camicie := [Color(0.86, 0.86, 0.82), Color(0.36, 0.42, 0.52),
		Color(0.62, 0.24, 0.22), Color(0.30, 0.34, 0.30),
		Color(0.82, 0.74, 0.52), Color(0.20, 0.22, 0.28)]
	var pantaloni := [Color(0.22, 0.24, 0.30), Color(0.30, 0.28, 0.24),
		Color(0.16, 0.17, 0.20), Color(0.44, 0.42, 0.38)]
	for g in GENTE_FERMA:
		var alt: float = 1.78 if str(g[3]) == "passante_b" else 1.82
		var opts := {"belly": rng.randf_range(0.15, 0.75),
			"bald": rng.randf() < 0.28,
			"moustache": rng.randf() < 0.35}
		# **E pure chi sta fermo tene 'na faccia soja** (0.59): uno su due
		# è uno degli otto uomini del pacchetto nuovo, uno su cinque
		# l'umano di Quaternius, gli altri il pupo di sempre.
		var dado: float = rng.randf()
		if dado < 0.45:
			opts["modello"] = str(Human.OMINI[rng.randi() % Human.OMINI.size()])
		elif dado < 0.65:
			opts["modello"] = "umano_q"
		var parti: Dictionary = Human.build(
			camicie[rng.randi() % camicie.size()],
			pantaloni[rng.randi() % pantaloni.size()], "",
			alt + rng.randf_range(-0.06, 0.06), opts)
		var n: Node3D = parti["root"]
		# Fermo vuol dire fermo: velocità zero, che è la posa d'attesa —
		# braccia lungo il corpo, peso che si sposta piano da un piede
		# all'altro. Misurata, le mani stanno a (±0,23, 0,90).
		var a = parti.get("anim", null)
		if a != null and a.has_method("set_speed"):
			a.set_speed(0.0)
		if n == null:
			continue
		# Il modello va dentro a un Fermo3D, che porta il collider, la bolla
		# e il tasto E. Prima erano modello + collider messi lì dalla città:
		# geometria senza nessuno dentro, e infatti non ci si poteva parlare.
		var f := FermoScript.new()
		f.name = "Fermo_%d" % _lontananza_id
		_lontananza_id += 1
		f.position = Vector3(float(g[0]), 0.0, float(g[1]))
		f.rotation.y = deg_to_rad(float(g[2]))
		add_child(f)
		f.add_child(n)
		_lontananza(n, 60.0)


## **'O ferraro sta in fondo a un vicolo cieco.**
##
## Col disegno nuovo i vicoli ciechi sono rimasti DUE: gli altri tre sono
## diventati cardini veri, perché una città con cinque vicoli ciechi su
## dodici traverse non è Napoli, è un labirinto. Il ferraro sta in quello a
## (140, 100)-(144, 116), che si imbocca da Via Marina e finisce contro
## l'isolato.
##
## Il vicolo si imbocca da z = 100, venendo da Via Marina, e il fondo cieco
## è a z = 116. Il banco sta contro il fondo e guarda INDIETRO, verso
## l'imbocco: chi si infila se lo trova in faccia. Il nodo è costruito col
## davanti verso il +Z locale, quindi per guardare verso -Z del mondo si
## gira di mezzo giro.
## **E sta 'e lato, no 'n miezo** (0.56).
##
## Era a x = 142, cioè il centro esatto del vicolo — dentro alla corsia
## libera, che è l'invariante che tiene la città attraversabile. In fondo
## a un vicolo cieco non passa nessuno, quindi non rompeva niente: ma il
## capo ha chiesto di controllare che l'armiere stesse a posto, e a posto
## non stava. E un banco abusivo si mette **contro il muro**, non in mezzo
## alla strada — è pure più vero.
const POSTO_ARMIERE := [143.6, 114.5, 180.0]


## **'O vascio.** La porta sta nel vicolo dietro alla piazza, sulla faccia
## est dell'isolato [13,67]→[26,74]: quarantatré metri da dove si lavora,
## che a piedi sono venti secondi. Abbastanza da dover **smettere di
## lavorare** per andarci, non tanto da diventare una camminata.
func _build_vascio() -> void:
	var v := VascioScript.new()
	add_child(v)


## **'E tavule d''a scopa.** Tre, sparse per la città, e a ognuna sta
## seduto uno dei vecchi del torneo. Non stanno tutti insieme apposta: per
## sfidare il terzo devi averlo trovato, e trovarlo vuol dire attraversare
## il quartiere.
## **La scala si sale allontanandosi da casa.**
##
## Il primo tentativo li aveva messi a caso, e il risultato era che il
## tavolino piu' vicino alla piazza era quello del **boss** — che pero' non
## ti fa giocare finche' non hai battuto gli altri quattro. Chi provava a
## giocare a scopa trovava un vecchio che lo mandava via e non sapeva dove
## andare: la meccanica c'era e non si poteva toccare.
##
## Adesso il primo sta a venticinque metri dal posto dove lavori e l'ultimo
## sta al Vommero, dall'altra parte della citta'. Tutti e cinque negli
## slarghi, che sono spazi liberi per costruzione: nessun rischio di
## piazzare un tavolo dentro a un muro.
const TAVULE_SCOPA := [
	{"id": "ciccio", "p": Vector3(24.5, 0.0, 2.6), "rot": 0.3},
	{"id": "professore", "p": Vector3(62.0, 0.0, 80.5), "rot": 1.1},
	{"id": "zipeppe", "p": Vector3(19.5, 0.0, 145.3), "rot": -1.4},
	{"id": "nicola", "p": Vector3(124.5, 0.0, 133.0), "rot": 2.4},
	{"id": "nonno", "p": Vector3(175.0, 0.0, 164.8), "rot": -0.8},
]


func _build_tavule_scopa() -> void:
	var Collina := preload("res://scripts/collina.gd")
	for t in TAVULE_SCOPA:
		var n := TavoloScopaScript.new()
		n.sfidante_id = str(t["id"])
		var p: Vector3 = Vector3(t["p"])
		# **'A quota d''a collina, a mano.**
		#
		# `_alza_collina()` alza tutti i figli che stanno sul terrapieno,
		# ma per uno StaticBody3D guarda la posizione del PRIMO collider —
		# che qui e' locale, (0, 1, 0), e quindi non risulta mai dentro. Il
		# tavolo di Nicola finiva tre metri sotto la terra e non lo trovava
		# nessuno. Chiedere la quota qui e' due righe e non dipende
		# dall'ordine in cui si costruiscono le cose.
		p.y = Collina.alzata(p.x, p.z)
		n.position = p
		n.rotation.y = float(t["rot"])
		add_child(n)


func _build_cummissiune() -> void:
	var n := CummissioneScript.new()
	n.name = "Cummissiune"
	add_child(n)


## **Don Gaetano 'o Prufessore**, appoggiato ô muro vicino â bacheca (0.56).
##
## Il posto non è scelto a caso ed è metà del personaggio. Sta:
##
## * **dint'â piazza toia**, quella dove cominci — un maestro che devi
##   andare a cercare in un altro quartiere non lo trova nessuno;
## * **a tre metri d''a bacheca**, che è l'altra cosa che il capo ha chiesto
##   di far scoprire (punto 4). Chi si avvicina per leggere i foglietti se
##   lo trova accanto, e uno dei consigli per strada dice di andare alla
##   bacheca: le due cose si portano a vicenda;
## * **appuiato ô muro 'e levante**, come la bacheca, e non in mezzo
##   all'aperto: un vecchio seduto in mezzo alla piazza è un ostacolo, un
##   vecchio seduto contro il muro è un vecchio seduto contro il muro.
func _build_maestro() -> void:
	var r: Array = ZONE[0]["rect"]
	var p := Vector3(float(r[2]) - 1.35, 0.0,
		lerpf(float(r[1]), float(r[3]), 0.72) + 3.1)
	var m = MaestroScript.new()
	m.name = "DonGaetano"
	add_child(m)
	m.global_position = Vector3(p.x, Collina.alzata(p.x, p.z), p.z)
	# Guarda dentro alla piazza: forward(θ) = (−sinθ, 0, −cosθ), quindi per
	# (−1, 0, 0) serve θ = +π/2. La stessa riga della bacheca, e per la
	# stessa ragione.
	m.rotation.y = PI * 0.5


func _build_armiere() -> void:
	var a := ArmiereScript.new()
	a.name = "Armiere"
	a.position = Vector3(float(POSTO_ARMIERE[0]), 0.0, float(POSTO_ARMIERE[1]))
	a.rotation.y = deg_to_rad(float(POSTO_ARMIERE[2]))
	add_child(a)


func _build_attivita() -> void:
	for p in POSTI_SCOPA:
		var t := ScopaScript.new()
		t.position = Vector3(float(p[0]), 0.0, float(p[1]))
		t.rotation.y = float(p[2])
		add_child(t)

	for p in POSTI_TRE_CARTE:
		var m := TreCarteScript.new()
		m.position = Vector3(float(p[0]), 0.0, float(p[1]))
		m.rotation.y = float(p[2])
		add_child(m)

	for p in POSTI_SCOMMESSE:
		var s := SalaScommesseScript.new()
		s.position = Vector3(float(p[0]), 0.0, float(p[1]))
		s.rotation.y = deg_to_rad(float(p[2]))
		add_child(s)


## **'A funtanella.** Nella piazzetta che porta il suo nome non c'era
## nessuna fontana: era una piazzetta chiamata "d''a fontana" e basta. Adesso
## c'e' davvero, ed e' anche il posto dove si beve gratis — che in un gioco
## in cui tutto si compra vale piu' di quanto sembri.
func _funtanella(pos: Vector3) -> void:
	var vasca := MeshInstance3D.new()
	var vm := CylinderMesh.new()
	vm.top_radius = 0.85
	vm.bottom_radius = 0.95
	vm.height = 0.62
	vm.radial_segments = 14
	vasca.mesh = vm
	vasca.position = pos + Vector3(0, 0.31, 0)
	vasca.material_override = Tex.mondo("piperno", Color(0.92, 0.90, 0.88), 0.9)

	# **'A fascia 'e maioliche.** Le maioliche sono state tolte dal pavimento
	# della piazza, dove non ci sono mai state: a Napoli stanno sui chiostri,
	# sulle cupole, sull'alzata di uno scalino e — proprio qui — sul giro di
	# una fontanella pubblica. Quaranta centimetri di fascia attorno alla
	# vasca valgono più di un tappeto largo dieci metri, perché si guardano
	# da vicino ed è per quello che sono fatte.
	var fascia := MeshInstance3D.new()
	var fm := CylinderMesh.new()
	fm.top_radius = 0.97
	fm.bottom_radius = 0.99
	fm.height = 0.30
	fm.radial_segments = 14
	fascia.mesh = fm
	fascia.position = pos + Vector3(0, 0.44, 0)
	fascia.material_override = Tex.mondo("maioliche",
		Color(0.90, 0.90, 0.88), 0.55)
	add_child(fascia)
	add_child(vasca)

	var colonna := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.16
	cm.bottom_radius = 0.22
	cm.height = 1.25
	cm.radial_segments = 10
	colonna.mesh = cm
	colonna.position = pos + Vector3(0, 1.15, 0)
	colonna.material_override = Tex.mondo("piperno", Color(0.88, 0.86, 0.84), 0.9)
	add_child(colonna)

	var cannella := MeshInstance3D.new()
	var km := CylinderMesh.new()
	km.top_radius = 0.045
	km.bottom_radius = 0.045
	km.height = 0.34
	km.radial_segments = 8
	cannella.mesh = km
	cannella.position = pos + Vector3(0, 1.62, -0.22)
	cannella.rotation.x = deg_to_rad(72.0)
	cannella.material_override = Tex.flat(Color(0.52, 0.38, 0.16), 0.4, 0.85)
	add_child(cannella)

	var getto := MeshInstance3D.new()
	var gm := CylinderMesh.new()
	gm.top_radius = 0.022
	gm.bottom_radius = 0.014
	gm.height = 1.0
	gm.radial_segments = 6
	getto.mesh = gm
	getto.position = pos + Vector3(0, 1.05, -0.34)
	var acqua := Tex.flat(Color(0.78, 0.92, 0.98), 0.15, 0.0).duplicate()
	acqua.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	acqua.albedo_color.a = 0.55
	getto.material_override = acqua
	add_child(getto)

	_solido(pos + Vector3(0, 0.5, 0), Vector3(1.9, 1.0, 1.9))

	var pu := PostoUtileScript.new()
	pu.tipo = "fontanella"
	pu.riposo = 14.0
	pu.position = pos
	add_child(pu)
	var f := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(2.1, 2.4, 2.1)
	f.shape = b
	f.position = Vector3(0, 1.2, 0)
	pu.add_child(f)


## **'O bar d''a piazza.**
##
## Non e' arredo: e' un pezzo di meccanica. Il vigile ci va a prendersi il
## caffe' due o tre volte a turno, e mentre sta li' col gomito sul banco
## non guarda niente e nessuno — sono i secondi in cui si lavora
## tranquilli. Il giocatore ci puo' andare pure lui: un euro, e per un
## quarto di minuto cammina come a vent'anni.
##
## Sta in un angolo della piazza, lontano dall'imbocco delle auto: un
## banco con la tenda, tre tavolini e l'insegna. Il punto dove si ferma il
## vigile e' un nodo a parte, nel gruppo "banco_bar", cosi' lo trova senza
## che nessuno gli scriva le coordinate.
const POSTO_BAR := Vector3(20.0, 0.0, 14.0)

func _build_bar() -> void:
	var pos := POSTO_BAR
	var root := Node3D.new()
	root.position = pos
	add_child(root)

	var legno := Tex.flat(Color(0.36, 0.22, 0.14), 0.85)
	var zinco := Tex.flat(Color(0.62, 0.63, 0.66), 0.35, 0.55)
	var rosso := Tex.flat(Color(0.62, 0.13, 0.12), 0.8)
	var crema := Tex.flat(Color(0.90, 0.86, 0.76), 0.85)

	# Il banco: una cassa di legno col piano di zinco, come quelli veri.
	var cassa := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(3.2, 1.05, 0.72)
	cassa.mesh = cm
	cassa.position = Vector3(0, 0.52, 0)
	cassa.material_override = legno
	root.add_child(cassa)

	var piano := MeshInstance3D.new()
	var pm2 := BoxMesh.new()
	pm2.size = Vector3(3.4, 0.07, 0.86)
	piano.mesh = pm2
	piano.position = Vector3(0, 1.08, 0)
	piano.material_override = zinco
	root.add_child(piano)

	# La macchina del caffe' sul banco: due gruppi e la vaschetta.
	var macchina := MeshInstance3D.new()
	var mm3 := BoxMesh.new()
	mm3.size = Vector3(0.86, 0.46, 0.5)
	macchina.mesh = mm3
	macchina.position = Vector3(-0.9, 1.34, -0.05)
	macchina.material_override = zinco
	root.add_child(macchina)
	for dx in [-0.22, 0.22]:
		var gruppo := MeshInstance3D.new()
		var gm := CylinderMesh.new()
		gm.top_radius = 0.05
		gm.bottom_radius = 0.05
		gm.height = 0.16
		gruppo.mesh = gm
		gruppo.position = Vector3(-0.9 + dx, 1.12, 0.22)
		gruppo.material_override = Tex.flat(Color(0.1, 0.1, 0.12), 0.4, 0.6)
		root.add_child(gruppo)

	# La tenda a righe sopra al banco, e i due pali che la reggono.
	for i in range(9):
		var striscia := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(0.42, 0.04, 1.5)
		striscia.mesh = sm
		striscia.position = Vector3(-1.7 + i * 0.42 + 0.21, 2.5, 0.55)
		striscia.rotation.x = deg_to_rad(-9.0)
		striscia.material_override = rosso if i % 2 == 0 else crema
		root.add_child(striscia)
	for sx in [-1.7, 1.7]:
		var palo := MeshInstance3D.new()
		var pm3 := CylinderMesh.new()
		pm3.top_radius = 0.045
		pm3.bottom_radius = 0.045
		pm3.height = 2.5
		palo.mesh = pm3
		palo.position = Vector3(sx, 1.25, 1.2)
		palo.material_override = Tex.flat(Color(0.28, 0.28, 0.3), 0.6, 0.3)
		root.add_child(palo)

	var insegna := Label3D.new()
	insegna.text = "BAR MEZZANOTTE"
	insegna.position = Vector3(0, 2.86, 0.5)
	insegna.font_size = 60
	insegna.pixel_size = 0.0052
	insegna.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	insegna.double_sided = false
	insegna.modulate = Color(1.0, 0.9, 0.55)
	insegna.outline_size = 16
	root.add_child(insegna)

	# **Tre tavolini col marmo e le sedie di vimini.**
	#
	# Erano due cilindri l'uno: un disco crema su un tubo grigio. Da lontano
	# dicevano "bar", da vicino no — e il bar e' il posto dove il vigile va
	# a pigliarsi 'o cafe', cioe' quello che il giocatore guarda piu' spesso
	# di tutta la piazza, perche' e' li' che aspetta il momento buono.
	#
	# Il tavolino e' lo stesso modello del Bazar (marmo, ghisa a tre piedi e
	# la tazzulella sopra) e le sedie sono quelle di vimini: due per tavolo,
	# girate a caso, come stanno le sedie di un bar quando nessuno le ha
	# ancora rimesse a posto.
	var rng_bar := RandomNumberGenerator.new()
	rng_bar.seed = 4820
	for t in range(3):
		var cx: float = -1.6 + t * 1.7
		var centro := pos + Vector3(cx, 0.0, 2.3)
		if not _pezzo_modello("tavolino", centro, "tav_bar",
				rng_bar.randf_range(-PI, PI)):
			var tav := MeshInstance3D.new()
			var tm := CylinderMesh.new()
			tm.top_radius = 0.34
			tm.bottom_radius = 0.32
			tm.height = 0.06
			tav.mesh = tm
			tav.position = Vector3(cx, 0.74, 2.3)
			tav.material_override = crema
			root.add_child(tav)
			var gamba := MeshInstance3D.new()
			var gm2 := CylinderMesh.new()
			gm2.top_radius = 0.035
			gm2.bottom_radius = 0.05
			gm2.height = 0.74
			gamba.mesh = gm2
			gamba.position = Vector3(cx, 0.37, 2.3)
			gamba.material_override = Tex.flat(Color(0.3, 0.3, 0.32), 0.6, 0.3)
			root.add_child(gamba)
			continue
		for k in range(2):
			var ang: float = rng_bar.randf_range(-PI, PI)
			var off := Vector3(cos(ang), 0, sin(ang)) * 0.62
			_pezzo_modello("sedia_bar", centro + off,
				"sedia_bar_mod", ang + PI + rng_bar.randf_range(-0.5, 0.5))
		# **'A culazione ncopp'ô tavulino.** Un tavolo con sopra qualcosa è
		# un tavolo occupato; un tavolo vuoto è arredamento. Su due dei tre
		# ci sta il cappuccino col cornetto, sul terzo niente — perché un
		# bar dove tutti i tavoli sono serviti insieme non esiste.
		if t < 2:
			_pezzo_modello("colazione", centro + Vector3(0, 0.80, 0),
				"colazione_bar", rng_bar.randf_range(-PI, PI))

	# **'A machinetta d''o cafè ncopp'ô bancone.** È l'oggetto che dice
	# "bar" più dell'insegna: una macchina da caffè cromata si riconosce
	# da venti metri, e sta esattamente dove uno se l'aspetta.
	_pezzo_modello("macchina_caffe", pos + Vector3(-0.85, 1.12, 0.10),
		"macchinetta", PI)
	_pezzo_modello("panino", pos + Vector3(0.55, 1.12, 0.06), "panino_bar",
		rng_bar.randf_range(-PI, PI))
	# **'E tazzulelle ncopp'ô banco** (0.59). Tre caffè appena fatti, e
	# accanto a due il bicchiere d'acqua che a Napoli si dà prima del
	# caffè, per pulire la bocca. Stanno dove sta chi beve: sul bordo del
	# banco verso la strada.
	for k in range(3):
		var x_t: float = -0.25 + float(k) * 0.22
		_panda("tazzulella", pos + Vector3(x_t, 1.115, 0.27),
			rng_bar.randf_range(-PI, PI), "bar", 40.0)
		if k < 2:
			_panda("bicchiere_acqua", pos + Vector3(x_t + 0.09, 1.115, 0.3),
				0.0, "bar", 40.0)

	_solido(pos + Vector3(0, 0.55, 0), Vector3(3.4, 1.1, 0.86))

	var pu := PostoUtileScript.new()
	pu.tipo = "bar"
	pu.riposo = 10.0
	pu.position = pos + Vector3(0, 0, 0.6)
	add_child(pu)
	var f := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(3.4, 2.2, 1.4)
	f.shape = b
	f.position = Vector3(0, 1.1, 0)
	pu.add_child(f)

	# Il posto dove si mette il vigile quando va a pigliarsi 'o cafe'.
	var banco := Node3D.new()
	banco.name = "BancoBar"
	banco.position = pos + Vector3(0.9, 0, 1.5)
	banco.add_to_group("banco_bar")
	add_child(banco)


## **Le altre piazze devono sembrare piazze che lavorano.**
##
## Prima nelle tre zone dei rivali c'era il rivale e basta: un uomo solo
## che camminava in tondo dentro a un quadrato vuoto. Il messaggio che
## arrivava era "qui non c'e' niente da fare", mentre e' l'opposto — quelle
## piazze sono l'obiettivo di tutta la partita.
##
## Adesso in ognuna c'e' la stessa scena che c'e' nella tua: la macchina
## dei vigili in sosta, un vigile appoggiato che si piglia 'o cafe', e il
## parcheggiatore che ogni tanto incassa — col tintinnio degli spiccioli,
## che a venti metri si sente. Non e' scenografia: e' il modo di far
## vedere quanto rende una piazza prima di comprarla.
const AutoVigiliTinta := Color(0.90, 0.90, 0.88)

func _build_altre_piazze() -> void:
	for i in range(1, ZONE.size()):
		var z: Dictionary = ZONE[i]
		var r: Array = z["rect"]
		var centro := Vector3((r[0] + r[2]) / 2.0, 0.0, (r[1] + r[3]) / 2.0)
		var angolo := _angolo_vigili(z)
		_auto_dei_vigili(angolo)
		_vigile_ar_cafe(angolo + Vector3(3.4, 0.0, 1.2), centro)


## Dove sta la macchina dei vigili di una piazza. L'angolo di nord-ovest,
## tre metri dentro: lontano dal posto del rivale (che sta al centro) e dai
## varchi. Allo stadio il centro è occupato dall'impianto: si sta sul
## sagrato, accanto al parcheggiatore.
##
## **Nun cchiù 'int'all'angolo** (0.59). L'angolo di nord-ovest era il posto
## peggiore che ci fosse: al mercato è il primo banco della fila (la
## macchina ci stava parcheggiata sopra, cassette e telo compresi), e alla
## cornetteria è dove sta il guaglione col cartello — un metro e mezzo dalla
## portiera, e fra lui e chi lo voleva assumere c'era la macchina
## (`prova_ngombri`, `prova_mira`). Adesso sta al centro della fascia di
## tramontana della piazza: lì non ci sono posti auto (cominciano sei metri
## più giù), non ci sono varchi (stanno sui lati corti) e il guaglione sta
## a un quinto dall'angolo, lontano.
##
## **E fore d''a corsia** (0.59): alla cornetteria il mezzo della fascia di
## tramontana cade sulla corsia del Vico d''o Ferraro, che entra nella
## piazzetta proprio lì — la macchina ci stava in mezzo e senza corpo. Si
## scorre di tre metri e mezzo alla volta finché non ne è fuori.
static func _angolo_vigili(z: Dictionary) -> Vector3:
	var r: Array = z["rect"]
	var base := Vector3((float(r[0]) + float(r[2])) * 0.5, 0.0, float(r[1]) + 2.6)
	if z.has("posto"):
		base = Vector3(z["posto"]) + Vector3(-7.0, 0.0, 2.0)
	for dx in [0.0, 3.5, -3.5, 7.0, -7.0]:
		var q: Vector3 = base + Vector3(float(dx), 0.0, 0.0)
		if not in_corsia_girato(q, Vector3(4.3, 1.6, 1.95), 0.0):
			return q
	return base


##
## **'A machina 'e vigile ce sta overo** (0.59). Chiedeva `car_berlina`, che
## dalla 0.46 non c'era: si ripiegava sulla station wagon a scatole. Adesso
## è la berlina del Car Pack, e banda, scritta e lampeggiante stanno sulle
## **sue** misure — fiancata a 0,83 dal centro, tetto a 1,15 — invece che
## su quelle della station (il lampeggiante sarebbe rimasto a 1,52, per
## aria sopra al tetto). La scritta prima stava girata come la macchina, e
## una scritta girata di novanta gradi su una fiancata si guarda di taglio:
## adesso ce n'è una per lato, ognuna verso fuori.
func _auto_dei_vigili(pos: Vector3) -> void:
	var auto := Models.spawn_by_length("car_berlina", 4.1)
	var fianco: float = 0.92
	var y_banda: float = 0.78
	var tetto: float = 1.46
	if auto == null:
		auto = AutoVarieScript.costruisci(AutoVarieScript.Tipo.STATION,
			AutoVigiliTinta)
	else:
		Models.tint(auto, ["body", "carroz", "scocca", "paint"],
			AutoVigiliTinta, 0.25, 0.2)
		Models.polish_vehicle(auto)
		var dim: Vector3 = Models.size_of(auto)
		fianco = 0.85 * dim.x / 1.81
		y_banda = 0.52 * dim.y / 1.18
		tetto = dim.y
	auto.position = pos
	auto.rotation.y = deg_to_rad(90.0)
	add_child(auto)

	var azzurro := Tex.flat(Color(0.14, 0.42, 0.78), 0.55)
	for sx in [-1.0, 1.0]:
		var banda := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(3.0, 0.14, 0.04)
		banda.mesh = bm
		banda.position = pos + Vector3(0, y_banda, sx * fianco)
		banda.material_override = azzurro
		add_child(banda)
		var scritta := Label3D.new()
		scritta.text = "MUNICIPALE"
		scritta.position = pos + Vector3(0, y_banda + 0.17, sx * (fianco + 0.025))
		scritta.font_size = 40
		scritta.pixel_size = 0.0032
		scritta.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		scritta.double_sided = false
		scritta.rotation.y = 0.0 if sx > 0.0 else PI
		scritta.modulate = Color(0.12, 0.3, 0.6)
		add_child(scritta)
	var lampeggiante := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(0.2, 0.13, 0.7)
	lampeggiante.mesh = lm
	lampeggiante.position = pos + Vector3(0, tetto + 0.06, 0)
	lampeggiante.material_override = Tex.flat(Color(0.2, 0.5, 0.95), 0.4, 0.0, 1.4)
	add_child(lampeggiante)
	# **'O collider pe' 'o verso d''a machina** (0.59). La macchina è girata
	# di novanta gradi, quindi è lunga lungo X (le bande azzurre stanno a
	# z ±0,92); il collider era una scatola lunga 4,3 in X **e poi girata
	# anche lei** di novanta gradi: lunga in Z, di traverso alla macchina.
	# Ci si sbatteva contro l'aria davanti al cofano e si passava attraverso
	# le portiere.
	_solido(pos + Vector3(0, 0.8, 0), Vector3(4.3, 1.6, 1.95))
	_lontananza(auto, 120.0)


## Il vigile della zona: sta appoggiato con la tazzina in mano. Non fa la
## ronda — non e' la tua piazza, non e' un problema tuo. Serve a far capire
## che ogni piazza il suo vigile ce l'ha, e che comprandola te lo pigli.
func _vigile_ar_cafe(pos: Vector3, guarda: Vector3) -> void:
	var parts := Human.build(Color(0.22, 0.25, 0.34), Color(0.16, 0.18, 0.26),
		"vigile", 1.80, {"belly": 0.55, "moustache": true})
	var root: Node3D = parts["root"]
	var nodo := Node3D.new()
	nodo.position = pos
	var dir: Vector3 = guarda - pos
	dir.y = 0.0
	if dir.length() > 0.1:
		nodo.rotation.y = atan2(-dir.x, -dir.z)
	nodo.add_child(root)
	add_child(nodo)

	var bones: Dictionary = parts.get("bones", {})
	# Il berretto, la bandoliera bianca e la tazzina: tre pezzi e si capisce
	# chi e' e cosa sta facendo.
	if bones.has("head"):
		var berretto := MeshInstance3D.new()
		var bm := CylinderMesh.new()
		bm.top_radius = 0.115
		bm.bottom_radius = 0.125
		bm.height = 0.10
		berretto.mesh = bm
		berretto.position = Vector3(0, 0.13, 0)
		berretto.material_override = Tex.flat(Color(0.12, 0.14, 0.22), 0.7)
		bones["head"].add_child(berretto)
	if bones.has("chest"):
		var banda := MeshInstance3D.new()
		var bm2 := BoxMesh.new()
		# La banda bianca del vigile: era profonda trenta centimetri, cioè
		# nove in più del torace nuovo, e le spuntava davanti e dietro.
		bm2.size = Vector3(0.085, 0.40, 0.225)
		banda.mesh = bm2
		banda.rotation.z = deg_to_rad(18.0)
		banda.material_override = Tex.flat(Color(0.94, 0.94, 0.92), 0.6)
		bones["chest"].add_child(banda)
	if bones.has("hand_r"):
		var tazzina := MeshInstance3D.new()
		var tm := CylinderMesh.new()
		tm.top_radius = 0.032
		tm.bottom_radius = 0.024
		tm.height = 0.05
		tazzina.mesh = tm
		tazzina.position = Vector3(0, -0.09, 0)
		tazzina.material_override = Tex.flat(Color(0.95, 0.95, 0.93), 0.35)
		bones["hand_r"].add_child(tazzina)
	# Il braccio destro piegato, con la tazzina all'altezza del petto.
	var anim = parts.get("anim", null)
	if anim != null and anim.has_method("hold_bone"):
		anim.hold_bone("shoulder_r", Vector3(-64.0, 0.0, -18.0), 1.0)
		anim.hold_bone("elbow_r", Vector3(-96.0, 0.0, 0.0), 1.0)
	_lontananza(nodo, 90.0)


## **Chello ca se vede d''a jurnata (0.53).** La pioggia, le bancarelle in
## più, la processione, il boato del bar: tutto quello che rende visibile
## una giornata speciale sta in un nodo suo, e vive un giorno.
const JurnataVista := preload("res://scripts/jurnata_vista.gd")


func _build_jurnata() -> void:
	if not GameManager.e_speciale():
		return
	var j := JurnataVista.new()
	j.name = "JurnataVista"
	# La processione attraversa la piazza del giocatore: le serve il centro.
	if ZONE.size() > 0:
		var r: Array = ZONE[0]["rect"]
		j.centro_piazza = Vector3((r[0] + r[2]) * 0.5, 0.0, (r[1] + r[3]) * 0.5)
	add_child(j)


func _build_verde() -> void:
	_build_jurnata()
	_build_bar()
	_build_altre_piazze()
	_funtanella(Vector3(65.0, 0.0, 81.0))
	# Un pino ha una chioma di sei metri: in un vicolo da quattro non ci
	# sta, e infatti a Napoli gli alberi stanno solo negli slarghi. Ci sono
	# tutti e soli lì.
	# **E ognuno ô posto suo** (0.59, `prova_ngombri`): due panchine stavano
	# sulla corsia libera del cardine e una dentro al tavolino della scopa;
	# un pino stava in mezzo al campetto dei guagliuni.
	var pini := [
		Vector3(60.0, 0, 74.0), Vector3(71.5, 0, 87.5), Vector3(58.5, 0, 87.5),
		Vector3(20.0, 0, 134.0), Vector3(38.8, 0, 146.8),
		Vector3(113.0, 0, 134.0), Vector3(124.0, 0, 144.0),
		Vector3(164.0, 0, 161.0), Vector3(174.0, 0, 161.0),
		Vector3(19.0, 0, 3.0), Vector3(45.0, 0, 3.0),
	]
	for p in pini:
		_pino(p)
	# Ogni panchina guarda qualcosa: la fontana, il campetto, lo slargo.
	for pg in [
			[Vector3(68.5, 0, 84.0), Vector3(65.0, 0, 81.0)],
			[Vector3(22.0, 0, 131.2), Vector3(28.0, 0, 139.0)],
			[Vector3(121.5, 0, 146.3), Vector3(118.0, 0, 139.0)],
			[Vector3(171.5, 0, 158.4), Vector3(169.0, 0, 162.0)],
			[Vector3(70.5, 0, 72.5), Vector3(65.0, 0, 81.0)],
			[Vector3(31.5, 0, 131.2), Vector3(34.0, 0, 139.0)]]:
		_panchina(pg[0], pg[1])


## Il pino marittimo: tronco storto e chioma a ombrello, che è la sagoma
## che si riconosce anche a duecento metri.
func _pino(pos: Vector3) -> void:
	# **'A chiazza mo' tene ll'arbere overe.** Fino alla 0.45 un albero era
	# un cilindro marrone con sopra quattro sfere verdi: da lontano
	# funzionava, da vicino era una scultura astratta. Adesso ci sono tre
	# modelli veri, e il cilindro con le sfere resta solo come ripiego —
	# se un giorno i modelli non ci fossero, la piazza non resta pelata.
	var quale: String = "albero"
	var r: float = randf()
	if r > 0.62:
		quale = "alberello"
	elif r > 0.30:
		quale = "alberello2"
	if _pezzo_modello(quale, pos, "arbero_" + quale,
			randf_range(-PI, PI), randf_range(0.85, 1.25)):
		# Il tronco ferma: senza collider ci si cammina dentro, ed è la
		# stessa cosa che il capo aveva segnalato per i mobili di casa.
		_solido(pos + Vector3(0, 1.5, 0), Vector3(0.7, 3.0, 0.7))
		return

	var h: float = randf_range(6.5, 9.5)
	var tronco := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.18
	cm.bottom_radius = 0.34
	cm.height = h
	cm.radial_segments = 8
	tronco.mesh = cm
	tronco.position = pos + Vector3(0, h / 2.0, 0)
	tronco.rotation.z = randf_range(-0.06, 0.06)
	tronco.material_override = Tex.flat(Color(0.34, 0.27, 0.2), 0.95)
	add_child(tronco)
	_solido(pos + Vector3(0, 1.5, 0), Vector3(0.7, 3.0, 0.7))
	_lontananza(tronco, 130.0)
	var verde := Tex.flat(Color(0.16, 0.29, 0.16), 0.95)
	for i in range(4):
		var chioma := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = randf_range(2.0, 3.2)
		sm.height = sm.radius * 0.85
		sm.radial_segments = 10
		sm.rings = 5
		chioma.mesh = sm
		chioma.position = pos + Vector3(randf_range(-1.6, 1.6),
			h + randf_range(-0.4, 0.9), randf_range(-1.6, 1.6))
		chioma.material_override = verde
		add_child(chioma)
		_lontananza(chioma, 130.0)


func _panchina(pos: Vector3, guarda: Vector3 = Vector3.INF) -> void:
	# Niente giro a caso: una panchina guarda quello che c'è da guardare (la
	# fontana, il campetto), e chi ci si siede lo guarda pure lui. Il davanti
	# della panchina è il suo +Z locale (lo schienale sta a −Z).
	var giro: float = 0.0
	if guarda != Vector3.INF:
		var d: Vector3 = guarda - pos
		giro = atan2(d.x, d.z)
	# **'A panchina 'e modello nun se perdeva cchiù 'o sedile** (0.59). Con
	# il modello vero questa funzione usciva subito dopo averlo messo, e
	# tutto quello che stava sotto — il collider e il posto dove sedersi —
	# non nasceva mai: le panchine si attraversavano e non ci si sedeva più.
	# Adesso il modello sostituisce solo le scatole, non il resto.
	if not _pezzo_modello("panchina", pos, "panchina_mod", giro):
		_panchina_a_scatole(pos, giro)
	var pu2 := PostoUtileScript.new()
	pu2.tipo = "panchina"
	pu2.riposo = 40.0
	pu2.position = pos
	pu2.rotation.y = giro
	add_child(pu2)
	var fp := CollisionShape3D.new()
	var bp := BoxShape3D.new()
	bp.size = Vector3(1.9, 1.1, 0.7)
	fp.shape = bp
	fp.position = Vector3(0, 0.55, 0)
	pu2.add_child(fp)


func _panchina_a_scatole(pos: Vector3, giro: float) -> void:
	var b := Basis(Vector3.UP, giro)
	var legno := Tex.flat(Color(0.46, 0.32, 0.2), 0.92)
	var ferro := Tex.flat(Color(0.16, 0.17, 0.18), 0.6, 0.4)
	var seduta := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(1.9, 0.1, 0.55)
	seduta.mesh = sm
	seduta.transform = Transform3D(b, pos + b * Vector3(0, 0.46, 0))
	seduta.material_override = legno
	_batched("panca", seduta)
	var spall := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(1.9, 0.5, 0.09)
	spall.mesh = pm
	spall.transform = Transform3D(b, pos + b * Vector3(0, 0.75, -0.25))
	spall.material_override = legno
	_batched("panca_sp", spall)
	for d in [-0.85, 0.85]:
		var gamba := MeshInstance3D.new()
		var gm := BoxMesh.new()
		gm.size = Vector3(0.09, 0.46, 0.5)
		gamba.mesh = gm
		gamba.transform = Transform3D(b, pos + b * Vector3(d, 0.23, 0))
		gamba.material_override = ferro
		_batched("panca_g", gamba)


# ---------------------------------------------------------------------------
# La vita: passanti, ragazzini, motorini
# ---------------------------------------------------------------------------

func _build_vita() -> void:
	# I punti in cui la gente va e viene: le piazze, gli incroci, i negozi.
	# Le tappe stanno tutte in mezzo alla strada o negli slarghi: un
	# passante che punta a un metro dentro a un palazzo ci sbatte contro e
	# resta lì a spingere il muro per tutta la partita.
	# **(140, 30) sta dint'ô stadio** (0.59). Era una tappa da quando il
	# piazzale era un piazzale; poi al centro ci è nato lo stadio, e la tappa
	# è rimasta dentro all'anello. Finché i passanti camminavano sotto alla
	# città nessuno se n'è accorto; con un corpo vero ci restavano attaccati.
	# Adesso sta sul sagrato, davanti ai cancelli.
	# (169, 162) stava contro il muro di dietro della galera (0.56), che
	# arriva a z = 162: irraggiungibile, e chi ci andava ci spingeva
	# contro (`prova_ntuppate`, 0.59). Tre metri e mezzo più in là.
	var tappe := [
		Vector3(31, 0, 30), Vector3(40, 0, 14), Vector3(78, 0, 20),
		Vector3(78, 0, 63), Vector3(65, 0, 79), Vector3(144, 0, 50),
		Vector3(11, 0, 45), Vector3(53, 0, 63), Vector3(105, 0, 63),
		Vector3(30, 0, 95), Vector3(78, 0, 95), Vector3(140, 0, 95),
		Vector3(30, 0, 111), Vector3(144, 0, 111), Vector3(22.5, 0, 141.8),
		Vector3(105, 0, 139), Vector3(78, 0, 154), Vector3(169, 0, 165.5),
		Vector3(181, 0, 95), Vector3(11, 0, 126),
	]
	# **Quanta gente cammina 'a via dipende d''a jurnata (0.52).**
	#
	# Quattordici passanti erano quattordici sempre: col mercato, con la
	# processione e sotto la pioggia. Adesso il numero si moltiplica per
	# `gente_giornata()` — il giorno della processione la strada è piena
	# (ventotto), quello di pioggia è vuota (otto) — ed è la cosa che si
	# vede per prima uscendo di casa, prima ancora di guardare l'orologio.
	var quanti: int = clampi(int(round(14.0 * GameManager.gente_giornata())),
		6, 30)
	for i in range(quanti):
		var p := PassanteScript.new()
		p.tappe = tappe
		add_child(p)
		p.global_position = tappe[i % tappe.size()] + Vector3(
			randf_range(-3, 3), 0.4, randf_range(-3, 3))

	# **I ragazzini stanno lontani da dove entrano le macchine.**
	#
	# Stavano a (34, 50), cioe' col campetto addosso al varco della piazza
	# — quello da cui entrano i clienti. Fra un pallone che rimbalza e una
	# berlina in manovra prima o poi ne investivi uno, e non e' il tipo di
	# scena che questo gioco vuole. Adesso stanno nell'angolo opposto, e il
	# campetto e' anche piu' piccolo (sei metri invece di nove).
	# **'O campetto steva 'ncastrato dint'ô palazzo** (0.56).
	#
	# Il secondo campetto stava a (41, 139) e il largo dei guaglioni — che
	# è nato per loro, si chiama così e sta scritto dentro a `SLARGHI` —
	# finisce a x 40. Un metro fuori: il campetto era mezzo dentro
	# all'isolato [41,129]→[51,149], la porta cadeva **dentro al palazzo**,
	# e i ragazzini ci correvano dentro tutto il giorno. È il caso che il
	# capo ha visto e ha chiamato *«i bambini che giocano»*, e non era un
	# problema di muri: era un problema di dove li avevo messi.
	#
	# Adesso sta a (30, 139), dentro al largo e fuori dalla corsia.
	# **E 'o campetto sta a levante d''o largo** (0.59): a (30, 139) aveva
	# dentro un tavolino della scopa, una partita vera, una panchina, un
	# pino e due persone. Adesso il largo è diviso dalla corsia del cardine:
	# a levante si gioca a pallone, a ponente si gioca a carte.
	for centro in [Vector3(42.0, 0, 15.0), Vector3(34.0, 0, 139.0)]:
		var b := BambiniScript.new()
		add_child(b)
		b.global_position = centro

	# I motorini: uno per strada, avanti e indietro.
	# I motorini corrono solo sulle strade larghe: nel vicolo passerebbero
	# dentro ai muri, e comunque uno che sfreccia in quattro metri di luce
	# non sfreccia, si ferma.
	var tratte := [
		[Vector3(78, 0, -4), Vector3(78, 0, 176)],
		[Vector3(-4, 0, 95.5), Vector3(194, 0, 95.5)],
		[Vector3(194, 0, 63.5), Vector3(-4, 0, 63.5)],
		[Vector3(78, 0, 176), Vector3(78, 0, -4)],
	]
	for t in tratte:
		var m := MotorinoScript.new()
		add_child(m)
		m.global_position = Vector3.ZERO
		m.partenza = t[0]
		m.arrivo = t[1]


## Spegne un pezzo di arredo oltre una certa distanza.
##
## Il quartiere e' arrivato a tremila oggetti disegnati: su una scheda
## video seria non e' un problema, su un portatile lo diventa. Godot sa
## smettere di disegnare una cosa oltre un raggio, e per vetrine, alberi,
## panchine e auto in sosta e' gratis: a novanta metri quelle cose sono
## quattro pixel, e nessuno si accorge che sono sparite. Il dissolvimento
## di dieci metri evita che compaiano di colpo.

## Una scatola solida attorno a un pezzo di arredo.
##
## Serve perché quasi tutto quello che riempie la città — auto in sosta,
## vetrine, panchine, pini, bancarelle, motorini appoggiati — era fatto di
## sole mesh, senza collider. Ci si camminava attraverso: le auto
## parcheggiate erano fantasmi, e in un gioco che parla di parcheggio è la
## cosa peggiore che potesse succedere.
##
## Un solo box per oggetto: la forma esatta non serve, serve che ci si
## sbatta contro.
func _solido(pos: Vector3, dim: Vector3, ang: float = 0.0) -> void:
	# Rete di sicurezza sui varchi. Vale solo per l'arredo — roba piccola,
	# sotto ai cinque metri: motorini, panchine, alberi, cassonetti. I muri,
	# il terrapieno e l'anello dello stadio sono tutti piu' grossi di cosi'
	# e non vengono mai toccati. Serve perche' l'arredo lo piazzano venti
	# funzioni diverse, e ricordarsi di controllare il varco in ognuna e'
	# una promessa che prima o poi non si mantiene.
	if maxf(dim.x, maxf(dim.y, dim.z)) <= 5.0 and dentro_varco(pos):
		_solidi_scartati["varco"] = int(_solidi_scartati.get("varco", 0)) + 1
		return
	# E mai in mezzo alla carreggiata. Vale solo per l'arredo piccolo: i
	# muri, il terrapieno e l'anello dello stadio sono tutti piu' grossi di
	# cinque metri e non passano mai di qui.
	#
	# **Quanto sporge davvero** (0.59). Il controllo prendeva la misura più
	# lunga del corpo e la stendeva in tutte le direzioni: un'auto in sosta
	# lunga 4,3 contava come un disco di due metri e quindici di raggio, e
	# appoggiata al marciapiede del Corso "toccava" la corsia anche se ne
	# stava a trenta centimetri. Risultato: **trecentotrentotto corpi
	# buttati** — sessantacinque auto in sosta, ventidue vetrine, settanta
	# motorini appoggiati nei vicoli, le panchine delle scene d'angolo — cioè
	# mezza città che si attraversava come fumo, compresa la cosa più
	# importante di un gioco sul parcheggio: le macchine parcheggiate. Adesso
	# conta la sporgenza vera del corpo girato, lungo e di traverso.
	if maxf(dim.x, maxf(dim.y, dim.z)) <= 5.0 and in_corsia_girato(pos, dim, ang) \
			and not _in_slargo_piccolo(pos, dim):
		_solidi_scartati["corsia"] = int(_solidi_scartati.get("corsia", 0)) + 1
		var k: String = str(dim.snapped(Vector3.ONE * 0.1))
		_solidi_scartati[k] = int(_solidi_scartati.get(k, 0)) + 1
		if not _solidi_scartati.has("dove"):
			_solidi_scartati["dove"] = []
		(_solidi_scartati["dove"] as Array).append([pos.snapped(Vector3.ONE * 0.1), k])
		return
	var b := StaticBody3D.new()
	b.collision_layer = LAYER_WORLD
	b.collision_mask = 0
	var f := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = dim
	f.shape = bx
	f.position = pos
	f.rotation.y = ang
	b.add_child(f)
	add_child(b)
	if maxf(dim.x, dim.z) <= 8.0:
		_ingombri.append([Vector2(pos.x, pos.z),
			0.5 * Vector2(dim.x, dim.z).length(), dim.x * 0.5, dim.z * 0.5, ang])


## **'O catasto d''e ccose** (0.59). Ogni corpo solido d'arredo che la città
## mette (auto in sosta, vetrine, pini, motorini, cantieri, lampioni…) si
## segna qui come un cerchio: centro e raggio. Serve a chi mette l'arredo
## nuovo **dopo** — i quadri elettrici, i cartelli, i sacchetti — per non
## piantarlo dentro a una cosa che c'era già. È la stessa domanda che fa
## `prova_ngombri` a città finita, fatta prima invece che dopo.
var _ingombri: Array = []
## Quanti corpi `_solido` ha buttato, e perché (lo legge `prova_arredo`).
var _solidi_scartati: Dictionary = {}


## **'A scatola è libbera?** La domanda di `prova_ngombri` fatta prima di
## mettere una cosa invece che dopo: la scatola `dim` girata di `ang` si
## compenetra con uno dei corpi già segnati? Assi separatori, come la prova.
func _scatola_libera(pos: Vector3, dim: Vector3, ang: float,
		margine: float = 0.05) -> bool:
	var c := Vector2(pos.x, pos.z)
	var hx: float = dim.x * 0.5 + margine
	var hz: float = dim.z * 0.5 + margine
	var r: float = Vector2(hx, hz).length()
	for e in _ingombri:
		if (e[0] as Vector2).distance_to(c) > r + float(e[1]):
			continue
		if _si_toccano(c, hx, hz, ang, e[0], float(e[2]), float(e[3]), float(e[4])):
			return false
	return true


static func _si_toccano(ca: Vector2, ahx: float, ahz: float, aang: float,
		cb: Vector2, bhx: float, bhz: float, bang: float) -> bool:
	var assi: Array = [Vector2(cos(aang), -sin(aang)), Vector2(sin(aang), cos(aang)),
		Vector2(cos(bang), -sin(bang)), Vector2(sin(bang), cos(bang))]
	for asse in assi:
		var ra: float = absf((Vector2(cos(aang), -sin(aang)) * ahx).dot(asse)) \
			+ absf((Vector2(sin(aang), cos(aang)) * ahz).dot(asse))
		var rb: float = absf((Vector2(cos(bang), -sin(bang)) * bhx).dot(asse)) \
			+ absf((Vector2(sin(bang), cos(bang)) * bhz).dot(asse))
		if absf((cb - ca).dot(asse)) >= ra + rb:
			return false
	return true


## Un posto è buono per un pezzo d'arredo di raggio `r` se: non sta dentro
## a un palazzo, a un varco o alla corsia libera; non sta dentro a una
## piazza (lì ci sono posti auto, rivali e guaglioni, con le loro regole);
## non tocca un corpo già segnato; e non sta addosso alla gente ferma, ai
## vicini e ai posti dove si gioca.
func _sta_libero(p: Vector3, r: float, r_corsia: float = -1.0) -> bool:
	var perche: String = _perche_nun_sta(p, r, r_corsia)
	if perche != "":
		_rifiuti[perche] = int(_rifiuti.get(perche, 0)) + 1
		return false
	return true


## Quante volte un posto è stato scartato, e perché: lo legge
## `prova_arredo` per capire se un pezzo manca per scelta o per sbaglio.
var _rifiuti: Dictionary = {}


func _perche_nun_sta(p: Vector3, r: float, r_corsia: float = -1.0) -> String:
	if dint_ô_palazzo(p, 0.0):
		return "palazzo"
	if dentro_varco(p):
		return "varco"
	# Per la corsia conta quanto il pezzo sporge verso il mezzo della
	# strada, non quanto è lungo: una panchina contro il muro è lunga due
	# metri ma ne sporge settanta centimetri.
	var rc: float = r if r_corsia < 0.0 else r_corsia
	if in_corsia(p, Vector3(rc * 2.0, 1.0, rc * 2.0)):
		return "corsia"
	if _davanti_ô_portone(p, r):
		return "portone"
	for z in ZONE:
		var q: Array = z["rect"]
		if p.x > float(q[0]) - r and p.x < float(q[2]) + r \
				and p.z > float(q[1]) - r and p.z < float(q[3]) + r:
			return "piazza"
	var p2 := Vector2(p.x, p.z)
	for e in _ingombri:
		if (e[0] as Vector2).distance_to(p2) < r + float(e[1]) + 0.15:
			return "ingombro"
	for g in GENTE_FERMA:
		if Vector2(float(g[0]), float(g[1])).distance_to(p2) < r + 1.0:
			return "gente"
	for v in POSTI_VICINE:
		if Vector2(float(v[1]), float(v[2])).distance_to(p2) < r + 1.2:
			return "vicine"
	for a in _posti_attivita:
		if (a[0] as Vector2).distance_to(p2) < r + float(a[1]):
			return "attivita"
	if _occupato_da_attivita(p, r + 1.8):
		return "scopa_carte"
	return ""


## I posti dove si fa qualcosa, col raggio che serve per starci: gli stessi
## gruppi e gli stessi raggi con cui `prova_ngombri` controlla che due
## attività non si mangino. Si raccolgono una volta, a città quasi fatta.
const RAGGI_ATTIVITA := {
	"bambini": 7.0, "scopa": 1.8, "tavoli_scopa": 1.8, "tre_carte": 1.8,
	"vicine": 1.0, "gente_ferma": 1.0, "spighe": 1.6, "posti_utili": 1.2,
	"cummissiune": 1.0, "maestro": 1.3, "armiere": 2.2,
	"signora_lotto": 1.0, "bacheche": 0.9, "negozi": 2.8, "banco_bar": 1.2,
	"operai": 1.0, "porte_casa": 1.6, "shop": 3.0, "tabaccheria": 2.6,
	"scommesse": 2.6, "bazar": 3.0, "bar": 3.0, "cornetteria": 3.0,
	"garage": 4.2, "vascio": 2.6, "punti_cummissione": 1.2,
	"attivita": 1.5, "manifesti": 2.5, "guagliuni": 1.2, "decoro": 1.0,
}
var _posti_attivita: Array = []


func _raccogli_posti_attivita() -> void:
	_posti_attivita.clear()
	for g in RAGGI_ATTIVITA:
		for n in get_tree().get_nodes_in_group(g):
			if n is Node3D and (n as Node3D).is_inside_tree():
				var q: Vector3 = (n as Node3D).global_position
				_posti_attivita.append([Vector2(q.x, q.z), float(RAGGI_ATTIVITA[g])])
	# Chi non sta in nessun gruppo ma ha un posto fisso.
	for t in TAVULE_SCOPA:
		var tp: Vector3 = t["p"]
		_posti_attivita.append([Vector2(tp.x, tp.z), 1.8])
	for m in POSTI_MANIFESTI:
		_posti_attivita.append([Vector2(float(m[1]), float(m[2])), 2.5])
	_posti_attivita.append([Vector2(POSTO_BAR.x, POSTO_BAR.z + 1.2), 3.2])
	_posti_attivita.append([Vector2(POSTO_GARAGE.x, POSTO_GARAGE.z), 4.2])


func _lontananza(n: Node, metri: float) -> void:
	var pila := [n]
	while not pila.is_empty():
		var x = pila.pop_back()
		if x is GeometryInstance3D:
			(x as GeometryInstance3D).visibility_range_end = metri
			(x as GeometryInstance3D).visibility_range_end_margin = 10.0
		for k in x.get_children():
			pila.append(k)


func _tutte_le_mesh(n: Node) -> Array:
	var fuori: Array = []
	if n is MeshInstance3D:
		fuori.append(n)
	for c in n.get_children():
		fuori.append_array(_tutte_le_mesh(c))
	return fuori


## Il Piazzale, rifatto sulla fotografia di Piazzale Tecchio.
##
## Quello che lo fa riconoscere non è lo stadio — quello sta dietro e si
## vede da mezzo quartiere — sono tre cose in primo piano: il lastricato a
## pietre irregolari grandi, la scultura a spirale sulla destra, e le
## gradinate basse davanti allo stadio con i pini a fare da quinta.
func _build_piazzale() -> void:
	var r: Array = ZONE[1]["rect"]
	var cx: float = (r[0] + r[2]) / 2.0

	# Il lastricato: sopra alla pavimentazione, una griglia di lastre
	# grandi e storte. Sono tutte lo stesso rettangolo ruotato a caso, e
	# finiscono in un MultiMesh: cinquecento lastre costano una draw call.
	var lastra := BoxMesh.new()
	lastra.size = Vector3(2.5, 0.03, 2.5)
	var mat_lastra := Tex.mondo("marciapiede", Color(0.88, 0.79, 0.72), 0.94)
	var rng := RandomNumberGenerator.new()
	rng.seed = 771
	var x: float = r[0] + 2.0
	while x < r[2] - 2.0:
		var z: float = r[1] + 2.0
		while z < r[3] - 2.0:
			# Sotto all'impianto non si lastrica: sono duecento pezzi che
			# nessuno vedra' mai.
			if absf(x - STADIO_CENTRO.x) < 22.0 and absf(z - STADIO_CENTRO.z) < 18.0:
				z += 2.7
				continue
			var l := MeshInstance3D.new()
			l.mesh = lastra
			l.position = Vector3(x + rng.randf_range(-0.3, 0.3), 0.03,
				z + rng.randf_range(-0.3, 0.3))
			l.rotation.y = rng.randf_range(-0.09, 0.09)
			l.scale = Vector3(rng.randf_range(0.85, 1.15), 1.0,
				rng.randf_range(0.85, 1.15))
			l.material_override = mat_lastra
			_batched("lastra", l)
			z += 2.7
		x += 2.7

	# **Il sagrato.**
	#
	# Tutto l'arredo del piazzale stava contro il bordo NORD, perche' fino
	# a ieri lo stadio si guardava di la', in fondo al mare. Adesso
	# l'impianto sta in mezzo alla piazza e lo si guarda dal davanti, cioe'
	# da sud: gradinate, monumento, pennoni e dissuasori si sono girati di
	# conseguenza. Un piazzale con le panchine rivolte al muro si nota
	# subito, anche senza sapere perche'.
	var fronte: float = STADIO_CENTRO.z + 19.0   # il filo dell'impianto
	var sagrato: float = r[3] - 2.0              # il fondo della piazza

	# Le gradinate: si sale dal sagrato verso l'ingresso.
	for i in range(5):
		var grad := MeshInstance3D.new()
		var gm := BoxMesh.new()
		gm.size = Vector3(26.0, 0.42, 1.5)
		grad.mesh = gm
		grad.position = Vector3(cx, 0.21 + i * 0.42, fronte + 5.0 + i * 1.5)
		grad.material_override = Tex.mondo("marciapiede", Tex.TERRA, 0.94)
		add_child(grad)

	# Il monumento, in fondo al sagrato sulla destra.
	var mon := MonumentoScript.new()
	mon.name = "Monumento"
	add_child(mon)
	mon.global_position = _posto_monumento()
	mon.rotation.y = deg_to_rad(160.0)

	# I pennoni con le bandiere, sul lato sinistro del sagrato.
	for i in range(3):
		_pennone(Vector3(r[0] + 6.0, 0, sagrato - 4.0 - i * 5.0), i)

	# Le siepi basse che bordano il sagrato sul fondo.
	for i in range(10):
		var siepe := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(3.2, 0.9, 1.1)
		siepe.mesh = sm
		siepe.position = Vector3(cx - 16.0 + i * 3.4, 0.45, sagrato)
		siepe.material_override = Tex.flat(Color(0.19, 0.32, 0.18), 0.95)
		_batched("siepe", siepe)

	# I dissuasori: i paletti che impediscono di parcheggiare davanti
	# all'ingresso — che poi è esattamente il problema di cui vive questo
	# gioco.
	for i in range(12):
		var palo := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.09
		pm.bottom_radius = 0.11
		pm.height = 0.85
		pm.radial_segments = 8
		palo.mesh = pm
		palo.position = Vector3(cx - 25.0 + i * 4.6, 0.42, fronte + 2.0)
		palo.material_override = Tex.flat(Color(0.2, 0.21, 0.23), 0.6, 0.4)
		_batched("dissuasore", palo)


func _pennone(pos: Vector3, i: int) -> void:
	var asta := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.05
	cm.bottom_radius = 0.08
	cm.height = 7.5
	cm.radial_segments = 8
	asta.mesh = cm
	asta.position = pos + Vector3(0, 3.75, 0)
	asta.material_override = Tex.flat(Color(0.78, 0.78, 0.8), 0.4, 0.6)
	add_child(asta)
	var bandiera := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.06, 0.9, 1.4)
	bandiera.mesh = bm
	bandiera.position = pos + Vector3(0, 6.6, 0.75)
	bandiera.material_override = Tex.flat(
		[Color(0.2, 0.55, 0.85), Color(0.9, 0.9, 0.88),
		Color(0.2, 0.55, 0.3)][i % 3], 0.92)
	add_child(bandiera)


func _build_cornetteria() -> void:
	var c := CornetteriaScript.new()
	c.name = "Cornetteria"
	add_child(c)
	var r: Array = ZONE[3]["rect"]
	# Appoggiata al lato nord della sua piazzetta: in mezzo ci finiva sopra
	# la ronda del parcheggiatore, che ci camminava dentro.
	c.global_position = Vector3((r[0] + r[2]) / 2.0, 0.0, r[1] + 1.5)
	if _ciclo:
		c.collega_ciclo(_ciclo)
	# Il fabbricato si segna nel catasto delle cose (0.59): un'auto in sosta
	# di Via Marina ci stava parcheggiata dentro.
	_ingombri.append([Vector2(c.global_position.x, c.global_position.z - 3.0),
		Vector2(4.5, 3.0).length(), 4.5, 3.0, 0.0])


## **'A galera** (0.56, rifatta nella 0.60).
##
## È l'unico edificio del gioco costruito perché il giocatore lo veda **da
## fuori**: non ci si entra camminando — ci si finisce, e la mattina dopo ci
## si risveglia davanti (vedi `main.gd`). Il punto non è l'edificio, è la
## **distanza**: svegliarsi qui vuol dire una traversata a piedi fino alla
## piazza, all'inizio della giornata, senza una lira in tasca.
##
## **Dove stava, e perché era sbagliato.** Fino alla 0.59 il blocco (26 × 11
## × 16 m) si costruiva nove metri dietro a `GALERA_FORE` = (178, 0, 163),
## cioè centrato a (178, 154): copriva due isolati interi, attraversava la
## strada z 152-156, il cardine d''o Vommero e il vicolo di levante. Nessuno
## se n'era accorto per tre versioni, perché la galera non aveva niente che
## la collegasse alla pianta — era un cubo messo lì. L'ha trovata la griglia
## dei passanti (0.59), quando una tappa è finita contro il suo muro.
##
## **Adesso è un isolato** (`ISOLATO_GALERA`): l'angolo di sud-est del
## Vomero, 22 × 12 m, in cima al terrapieno. Siccome è un isolato della
## pianta, tutto quello che cammina lo conosce già — i passi, la griglia,
## il catasto — e non si può più costruirci sopra niente. Da sotto, dalla
## via bassa, si vede il muraglione di tufo e sopra il muro cieco: una
## fortezza, che è come stanno le carceri vere nelle città vecchie.
##
## Il portone guarda a nord, sulla trasversale che sta sulla collina.
func _build_galera() -> void:
	var fuori: Vector3 = GameManager.GALERA_VERSO
	var giro: float = atan2(fuori.x, fuori.z)
	var base := Vector3(GameManager.GALERA_FORE.x, 0.0, GameManager.GALERA_FORE.z)
	var b: Array = ISOLATO_GALERA
	var largo: float = float(b[2] - b[0])      # 22, lungo la facciata
	var fondo: float = float(b[3] - b[1])      # 12, verso dentro
	var alto: float = 10.6
	var root := Node3D.new()
	root.name = "Galera"
	add_child(root)
	# Sta sulla collina: `_alza_collina` alza i figli della città che ci
	# stanno sopra, e questo nodo lo alza lui. Qui si scrive a quota zero.
	root.position = base
	root.rotation.y = giro

	# Il corpo pieno. Il collider è quello di un isolato qualunque (alto
	# trenta, come in `_isolato`), così nessuno ci sale e nessuno ci passa.
	var corpo := StaticBody3D.new()
	corpo.collision_layer = LAYER_WORLD
	corpo.collision_mask = 0
	root.add_child(corpo)
	var forma := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(largo, 30.0, fondo)
	forma.shape = box
	forma.position = Vector3(0, 15.0, -fondo / 2.0)
	corpo.add_child(forma)

	var travertino := Tex.mondo("muro_travertino", Color(0.66, 0.64, 0.60), 0.95)
	var piperno := Tex.mondo("piperno", Color(0.62, 0.62, 0.64), 0.93)
	var scuro := Tex.flat(Color(0.07, 0.07, 0.08), 0.9)
	_galera_box(root, Vector3(largo, alto, fondo), Vector3(0, alto / 2.0, -fondo / 2.0),
		travertino)
	# Lo zoccolo di piperno, la fascia a metà e il cornicione in cima: le
	# tre righe orizzontali che fanno di un muro cieco un edificio pubblico.
	_galera_box(root, Vector3(largo + 0.06, 1.4, fondo + 0.06),
		Vector3(0, 0.7, -fondo / 2.0), piperno)
	_galera_box(root, Vector3(largo + 0.05, 0.28, fondo + 0.05),
		Vector3(0, 4.1, -fondo / 2.0), piperno)
	_galera_box(root, Vector3(largo + 0.3, 0.55, fondo + 0.3),
		Vector3(0, alto - 0.2, -fondo / 2.0), piperno)
	_galera_box(root, Vector3(largo - 0.4, 0.05, fondo - 0.4),
		Vector3(0, alto + 0.08, -fondo / 2.0), Tex.flat(Color(0.30, 0.29, 0.28), 0.95))

	# 'E fenestelle cu 'e sbarre (PSX): due file, sopra alla fascia. Su tutti
	# e quattro i lati, perché da sotto — dalla via bassa e dal cardine di
	# levante — si vedono le altre due facce, e un muro senza niente da
	# quella parte sembrava un fondale.
	for lato in range(4):
		var n_x: Vector3 = [Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, -1),
			Vector3(-1, 0, 0)][lato]
		var lungh: float = largo if lato % 2 == 0 else fondo
		var centro_faccia: Vector3 = [Vector3(0, 0, 0), Vector3(largo / 2.0, 0, -fondo / 2.0),
			Vector3(0, 0, -fondo), Vector3(-largo / 2.0, 0, -fondo / 2.0)][lato]
		var lungo_f := Vector3(n_x.z, 0, -n_x.x)
		var quante: int = 6 if lato % 2 == 0 else 3
		for i in quante:
			var t: float = -lungh / 2.0 + lungh * (float(i) + 0.5) / float(quante)
			for yf in [5.6, 8.4]:
				var c: Vector3 = centro_faccia + lungo_f * t
				_galera_box(root, Vector3(1.0, 1.35, 0.08) if lato % 2 == 0
					else Vector3(0.08, 1.35, 1.0), c + Vector3(0, yf, 0) + n_x * 0.02, scuro)
				_galera_pezzo(root, "sbarre_fenestra", c + n_x * 0.03
					+ Vector3(0, yf - 1.7, 0), atan2(n_x.x, n_x.z), "galera_sbarre")
			# Le bocche di lupo nello zoccolo: le cantine hanno le grate
			# anche loro, a trenta centimetri da terra.
			if i % 2 == 0:
				_galera_pezzo(root, "griglia_bassa", centro_faccia + lungo_f * t
					+ n_x * 0.04 + Vector3(0, 0.45, 0), atan2(n_x.x, n_x.z),
					"galera_griglie")

	# 'O purtone: due battenti di ferro (PSX) dentro a una cornice di
	# piperno. Il modello ha il cardine all'origine e il battente verso −X:
	# quello di destra si mette dritto, quello di sinistra specchiato.
	var k_porta: float = 1.25
	for lato_p in [-1.0, 1.0]:
		var porta := Models.spawn("porta_ferro")
		if porta == null:
			break
		root.add_child(porta)
		porta.position = Vector3(1.25 * lato_p, 0.0, 0.03)
		porta.scale = Vector3(k_porta * lato_p, k_porta, k_porta)
	_galera_box(root, Vector3(0.45, 3.1, 0.22), Vector3(-1.5, 1.55, 0.08), piperno)
	_galera_box(root, Vector3(0.45, 3.1, 0.22), Vector3(1.5, 1.55, 0.08), piperno)
	_galera_box(root, Vector3(3.5, 0.5, 0.26), Vector3(0, 3.0, 0.1), piperno)
	_galera_box(root, Vector3(2.5, 0.35, 0.04), Vector3(0, 2.8, 0.015), scuro)
	# La targa sopra al portone, su una lastra chiara.
	_galera_box(root, Vector3(5.6, 0.7, 0.06), Vector3(0, 3.62, 0.04),
		Tex.flat(Color(0.86, 0.84, 0.78), 0.9))
	var targa := Label3D.new()
	targa.text = "CASA CIRCONDARIALE"
	targa.font_size = 46
	targa.pixel_size = 0.009
	targa.position = Vector3(0, 3.62, 0.08)
	targa.modulate = Color(0.14, 0.13, 0.12)
	targa.outline_size = 0
	targa.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	targa.double_sided = false
	root.add_child(targa)
	# Le due lampade a muro (PSX) ai lati, accese di notte.
	for lx in [-2.4, 2.4]:
		var lam := Models.spawn("lampada_muro")
		if lam != null:
			root.add_child(lam)
			lam.position = Vector3(lx, 2.75, 0.02)
		var luce := OmniLight3D.new()
		luce.position = Vector3(lx, 2.55, 0.5)
		luce.light_color = Color(1.0, 0.86, 0.62)
		luce.light_energy = 1.3
		luce.omni_range = 7.0
		luce.shadow_enabled = false
		luce.distance_fade_enabled = true
		luce.distance_fade_begin = 35.0
		luce.distance_fade_length = 10.0
		root.add_child(luce)
		if _ciclo and lam is GeometryInstance3D:
			_ciclo.aggiungi_lampione(luce, lam)
		elif _ciclo:
			var faro := MeshInstance3D.new()
			root.add_child(faro)
			_ciclo.aggiungi_lampione(luce, faro)
	# La bandiera sopra alla targa: l'asta esce dal muro e pende in avanti.
	var asta := MeshInstance3D.new()
	var am := CylinderMesh.new()
	am.top_radius = 0.025
	am.bottom_radius = 0.025
	am.height = 1.8
	am.radial_segments = 6
	asta.mesh = am
	asta.material_override = Tex.flat(Color(0.62, 0.62, 0.60), 0.4, 0.7)
	asta.position = Vector3(0, 5.0, 0.62)
	asta.rotation.x = deg_to_rad(45.0)
	root.add_child(asta)
	var colori := [Color(0.0, 0.55, 0.27), Color(0.95, 0.95, 0.93), Color(0.80, 0.12, 0.15)]
	for i in 3:
		var tela := MeshInstance3D.new()
		var tm := BoxMesh.new()
		tm.size = Vector3(0.28, 0.7, 0.01)
		tela.mesh = tm
		tela.material_override = Tex.flat(colori[i], 0.95)
		# Pende dall'asta: in cima all'asta, spostata di lato.
		tela.position = Vector3(-0.14 + float(i) * 0.28 - 0.28, 5.25, 1.18)
		root.add_child(tela)

	# 'O cancello carraio sul fianco di levante, dove entrano i furgoni: la
	# cancellata (PSX) davanti a un vano buio.
	var n_e := Vector3(1, 0, 0)
	var c_e := Vector3(largo / 2.0, 0, -fondo / 2.0)
	_galera_box(root, Vector3(0.08, 2.6, 3.0), c_e + Vector3(0.02, 1.3, 0), scuro)
	_galera_pezzo(root, "cancello_ferro", c_e + n_e * 0.05, atan2(n_e.x, n_e.z),
		"galera_cancello", 1.15)

	# In cima: il filo spinato sui bracci inclinati verso fuori, e la
	# garitta sull'angolo di nord-est. Sono le due cose che da lontano, contro
	# il cielo, fanno leggere «carcere» prima ancora della targa.
	var ferro := Tex.flat(Color(0.22, 0.22, 0.23), 0.6, 0.5)
	for lato in range(4):
		var n_x: Vector3 = [Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, -1),
			Vector3(-1, 0, 0)][lato]
		var lungh: float = largo if lato % 2 == 0 else fondo
		var centro_faccia: Vector3 = [Vector3(0, 0, 0), Vector3(largo / 2.0, 0, -fondo / 2.0),
			Vector3(0, 0, -fondo), Vector3(-largo / 2.0, 0, -fondo / 2.0)][lato]
		var lungo_f := Vector3(n_x.z, 0, -n_x.x)
		var bracci: int = int(lungh / 2.0)
		for i in range(bracci + 1):
			var t: float = -lungh / 2.0 + lungh * float(i) / float(bracci)
			var piede: Vector3 = centro_faccia + lungo_f * t - n_x * 0.15 \
				+ Vector3(0, alto + 0.05, 0)
			var br := MeshInstance3D.new()
			br.mesh = _cubo
			br.scale = Vector3(0.04, 0.75, 0.04)
			br.position = piede + Vector3(0, 0.33, 0) + n_x * 0.14
			# Girato attorno all'asse del muro: la cima va verso fuori.
			br.basis = Basis(lungo_f, deg_to_rad(25.0)) * Basis.from_scale(br.scale)
			br.material_override = ferro
			root.add_child(br)
		for fila in 3:
			var fl := MeshInstance3D.new()
			fl.mesh = _cubo
			var yy: float = alto + 0.25 + float(fila) * 0.22
			fl.position = centro_faccia - n_x * 0.15 + n_x * (0.08 + float(fila) * 0.1) \
				+ Vector3(0, yy, 0)
			fl.scale = Vector3(lungh, 0.015, 0.015) if lato % 2 == 0 \
				else Vector3(0.015, 0.015, lungh)
			fl.material_override = ferro
			root.add_child(fl)
	var garitta := Vector3(largo / 2.0 - 1.1, alto, -1.1)
	_galera_box(root, Vector3(1.6, 2.2, 1.6), garitta + Vector3(0, 1.1, 0), travertino)
	_galera_box(root, Vector3(1.64, 0.5, 1.64), garitta + Vector3(0, 1.55, 0), scuro)
	_galera_box(root, Vector3(1.9, 0.14, 1.9), garitta + Vector3(0, 2.27, 0), piperno)

	# Chi esce di galera la mattina se lo trova alle spalle: davanti al
	# portone non si mette niente (il registro dei portoni lo sa).
	_segna_portone(base, fuori)


## Un cubo della galera, in coordinate del suo nodo.
func _galera_box(root: Node3D, dim: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _cubo
	mi.position = pos
	mi.scale = dim
	mi.material_override = mat
	root.add_child(mi)


## Un pezzo ripetuto della galera: le coordinate sono del suo nodo, ma
## finisce in un MultiMesh con le coordinate del mondo. La quota della
## collina la mette `_batched` per chi sta sopra al terrapieno; chi sporge
## oltre il bordo (le facce di sud e di levante stanno sul ciglio) la
## prende qui, se no le grate resterebbero tre metri più giù della galera.
func _galera_pezzo(root: Node3D, nome: String, pos: Vector3, giro_l: float,
		tipo: String, scala: float = 1.0) -> void:
	var t := Transform3D(Basis(Vector3.UP, root.rotation.y), root.position)
	var w: Vector3 = t * pos
	w.y = pos.y + Collina.QUOTA - Collina.alzata(w.x, w.z)
	_pezzo_modello(nome, w, tipo, root.rotation.y + giro_l, scala)


func _build_spighe() -> void:
	var s := SpigheScript.new()
	s.name = "Spighe"
	add_child(s)
	var r: Array = ZONE[2]["rect"]
	# Sei metri e trenta dal bordo, no cinque (0.59): a cinque il carretto
	# delle pannocchie stava settanta centimetri dentro al primo banco della
	# fila di ponente (`prova_ngombri`).
	s.global_position = Vector3(r[0] + 6.3, 0.0, (r[1] + r[3]) / 2.0)


## Le bancarelle del mercato: telo, cassette, un po' di merce. Servono a far
## sembrare il mercato un mercato senza costare molto.
func _build_bancarelle() -> void:
	var r: Array = ZONE[2]["rect"]
	var teli := [Color(0.75, 0.25, 0.22), Color(0.22, 0.42, 0.6),
		Color(0.85, 0.7, 0.25), Color(0.3, 0.5, 0.32)]
	var i := 0
	var z: float = r[1] + 4.0
	while z < r[3] - 3.0:
		for x in [r[0] + 3.0, r[2] - 3.0]:
			var base := Vector3(x, 0.0, z)
			var banco := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(3.0, 0.8, 1.6)
			banco.mesh = bm
			banco.position = base + Vector3(0, 0.4, 0)
			banco.material_override = Tex.flat(Color(0.45, 0.32, 0.2), 0.9)
			_batched("banco", banco)
			_banco_chino(base, i)

			# Dal banco si compra: tre euro di frutta valgono tredici punti.
			# E' la cosa piu' economica che rimette in sesto, ed e' giusto
			# che sia al mercato.
			var pu := PostoUtileScript.new()
			pu.tipo = "bancarella"
			pu.position = base
			add_child(pu)
			var fb := CollisionShape3D.new()
			var bb := BoxShape3D.new()
			bb.size = Vector3(3.0, 1.1, 1.7)
			fb.shape = bb
			fb.position = Vector3(0, 0.55, 0)
			pu.add_child(fb)

			var telo := MeshInstance3D.new()
			var tm := BoxMesh.new()
			tm.size = Vector3(3.4, 0.12, 2.0)
			telo.mesh = tm
			telo.position = base + Vector3(0, 2.3, 0)
			telo.material_override = Tex.flat(teli[i % teli.size()], 0.9)
			add_child(telo)
			for dx in [-1.5, 1.5]:
				for dz in [-0.9, 0.9]:
					var palo := MeshInstance3D.new()
					var pm := BoxMesh.new()
					pm.size = Vector3(0.08, 2.3, 0.08)
					palo.mesh = pm
					palo.position = base + Vector3(dx, 1.15, dz)
					palo.material_override = Tex.flat(Color(0.3, 0.3, 0.32), 0.6)
					_batched("palo_banco", palo)
			i += 1
		z += 7.0


## **'O banco chino** (0.59). I banchi del mercato erano casse di legno
## vuote sotto al telo: si vendeva la frutta (il tasto E lo diceva) e di
## frutta non se ne vedeva. Adesso sul piano ci stanno le cassette piene,
## due file da quattro, e ogni tanto al posto di due cassette il mucchio di
## meloni o di cocozze che si vende a pezzi. Tutto sul piano del banco
## (0,8), dentro al corpo che il banco aveva già: niente in terra, niente
## da scansare.
const MERCATO_FRUTTA := ["arancia", "mela", "limone", "pummarola",
	"peperone", "mulignana", "patana", "cepolla", "mandarino", "pera",
	"carota", "friariello", "banana", "uva", "cetriolo", "ravanello",
	"peperoncino", "aglio"]
## Da quanti metri si vede la frutta del mercato. Il mercato è largo una
## trentina di metri e il gruppo si misura dal suo centro.
const MERCATO_VISTA: float = 62.0


func _banco_chino(base: Vector3, i: int) -> void:
	if not Models.has_model("cascetta_2"):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 30500 + i * 101
	var piano: float = 0.8
	var col_mellone: int = rng.randi_range(0, 3) if rng.randf() < 0.5 else -1
	for r in range(2):
		for c in range(4):
			var x: float = -1.08 + float(c) * 0.72
			var z: float = -0.4 + float(r) * 0.8
			if c == col_mellone:
				# Il mucchio: due o tre meloni (o cocozze) appoggiati.
				var grosso: String = "mellone" if rng.randf() < 0.6 else "cucozza"
				for k in range(rng.randi_range(2, 3)):
					_panda(grosso, base + Vector3(x + rng.randf_range(-0.14, 0.14),
						piano, z + rng.randf_range(-0.14, 0.14)),
						rng.randf_range(-PI, PI), "mercato", MERCATO_VISTA)
				continue
			# In giro sulla lista e non a sorte: così ogni frutto c'è almeno
			# una volta (a sorte l'arancia, proprio lei, non usciva mai).
			var f: String = str(MERCATO_FRUTTA[(i * 8 + r * 4 + c) % MERCATO_FRUTTA.size()])
			_cascetta_chiena(f, base + Vector3(x, piano, z),
				PI * 0.5 + rng.randf_range(-0.05, 0.05), rng, "mercato",
				MERCATO_VISTA)


## Il lungomare sta in un nodo suo: e' un pezzo di mondo con regole diverse
## da quelle della citta' (non ha isolati, non ha quartieri, ha il mare) e
## tenerlo qui dentro avrebbe voluto dire mescolarlo a tutto il resto.
func _build_mergellina() -> void:
	var m := MergellinaScript.new()
	m.LARGHEZZA_CITTA = LARGHEZZA
	add_child(m)


## I lampioni del lungomare passano di qui per finire nel ciclo
## giorno/notte, come quelli della citta'.
func registra_lampione(luce: Light3D, lampada: GeometryInstance3D) -> void:
	if _ciclo:
		_ciclo.aggiungi_lampione(luce, lampada)


func _build_panorama() -> void:
	# Il mare non si costruisce piu' qui.
	#
	# C'era un piano azzurro piatto a y = 0,6 grande novecento metri per
	# quattrocento, che partiva da trenta metri oltre il bordo e serviva
	# solo a riempire l'orizzonte dal belvedere. Adesso il mare e' quello
	# vero di Mergellina, animato, e comincia a ventun metri dal
	# muraglione. Tenerli tutti e due voleva dire il piano vecchio SOPRA
	# quello nuovo (0,6 contro 0,18), cioe' l'acqua buona coperta da quella
	# finta proprio dove si vede meglio.
	#
	# Resta solo la lontananza: oltre il mare disegnato c'e' la foschia, e
	# oltre la foschia il Vesuvio.
	if _piazza and _piazza.has_method("_build_vesuvio"):
		# Il Vesuvio lo sa già costruire la piazza: si riusa quello, ma
		# piazzato rispetto alla città e non rispetto al quartiere.
		pass
	# **'O golfo.** La costa curva, la città che continua oltre il bordo,
	# le colline e le isole: tutto quello che serve perché dall'alto si
	# riconosca Napoli e non "una città di mare qualunque". Va prima del
	# Vesuvio perché è lui a dire dove il Vesuvio deve stare.
	var g := GolfoScript.new()
	add_child(g)
	_vesuvio()


## **Il Vesuvio adesso sta dove sta.**
##
## Era piantato a nord, dritto davanti al lungomare, in mezzo all'acqua: da
## terra passava (è una sagoma azzurra in fondo al mare), dall'alto no —
## un vulcano che spunta dal centro del golfo è la cosa che più di tutte
## dice "questa non è Napoli". Adesso sta sul braccio di levante, attaccato
## alla costa, che è la sua posizione vera rispetto alla città.
func _vesuvio() -> void:
	var root := Node3D.new()
	root.name = "Vesuvio"
	root.position = GolfoScript.VESUVIO_POS
	root.scale = Vector3.ONE * 2.6
	add_child(root)
	var alta := _tinta(Color(0.38, 0.45, 0.60))
	var media := _tinta(Color(0.30, 0.37, 0.53))
	var bassa := _tinta(Color(0.23, 0.29, 0.45))
	var fette := [[96.0, 74.0, 16.0, 0.0], [74.0, 54.0, 18.0, 16.0],
		[54.0, 36.0, 18.0, 34.0], [36.0, 24.0, 14.0, 52.0]]
	for i in fette.size():
		var f: Array = fette[i]
		var m := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.bottom_radius = f[0]
		cm.top_radius = f[1]
		cm.height = f[2]
		cm.radial_segments = 22
		m.mesh = cm
		m.position = Vector3(0, f[3] + f[2] / 2.0, 0)
		m.material_override = bassa if i == 0 else (media if i < 3 else alta)
		root.add_child(m)
	var orlo := MeshInstance3D.new()
	var om := CylinderMesh.new()
	om.bottom_radius = 24.0
	om.top_radius = 21.0
	om.height = 5.0
	om.radial_segments = 22
	orlo.mesh = om
	orlo.position = Vector3(0, 68.0, 0)
	orlo.material_override = alta
	root.add_child(orlo)
	var somma := Node3D.new()
	somma.position = Vector3(-62.0, 0.0, 10.0)
	root.add_child(somma)
	for c in [[72.0, 40.0, 30.0, 0.0, 0.0], [46.0, 26.0, 14.0, 30.0, -8.0],
			[30.0, 14.0, 10.0, 44.0, 16.0]]:
		var m2 := MeshInstance3D.new()
		var cm2 := CylinderMesh.new()
		cm2.bottom_radius = c[0]
		cm2.top_radius = c[1]
		cm2.height = c[2]
		cm2.radial_segments = 16
		m2.mesh = cm2
		m2.position = Vector3(c[4], c[3] + c[2] / 2.0, 0)
		m2.material_override = media if c[3] < 40.0 else alta
		somma.add_child(m2)


func _tinta(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


# ---------------------------------------------------------------------------
# In che zona sto
# ---------------------------------------------------------------------------

func _process(_delta: float) -> void:
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null or not is_instance_valid(pl):
		return
	var via := strada_di(pl.global_position)
	if via != _strada_corrente:
		_strada_corrente = via
		strada_cambiata.emit(via)

	var id := zona_di(pl.global_position)
	if id != _zona_corrente:
		_zona_corrente = id
		GameManager.zona_corrente = id
		var z := zona_per_id(id)
		if z.is_empty():
			zona_cambiata.emit("", "In giro p''a città", "")
		else:
			zona_cambiata.emit(id, str(z["nome"]),
				"tu" if GameManager.zona_mia(id) else str(z["padrone"]))
		_aggiorna_servizio(z)


## Accende o spegne il lavoro. È vero solo dentro una piazza che è TUA: in
## tutto il resto della città il parcheggiatore è un cittadino qualunque.
##
## Il segnale parte solo quando lo stato cambia davvero, non a ogni cambio di
## zona: passare dal mercato di Rafele al piazzale di Gennaro non è entrare
## in servizio, e non deve far comparire niente.
func _aggiorna_servizio(z: Dictionary) -> void:
	# Il padrone non si legge piu' dalla costante: le piazze si comprano e
	# si prendono, quindi chi comanda dove e' uno STATO, non un dato di
	# fatto scritto nel file.
	var mio: bool = (not z.is_empty()) \
		and GameManager.zona_mia(str(z.get("id", "")))
	var nome: String = str(z.get("nome", "")) if mio else ""
	if mio == GameManager.in_servizio and nome == GameManager.piazza_corrente:
		return
	GameManager.in_servizio = mio
	GameManager.piazza_corrente = nome
	GameManager.servizio_cambiato.emit(mio, nome)


func zona_di(p: Vector3) -> String:
	for z in ZONE:
		var r: Array = z["rect"]
		if p.x >= r[0] and p.x <= r[2] and p.z >= r[1] and p.z <= r[3]:
			return str(z["id"])
	return ""


func zona_per_id(id: String) -> Dictionary:
	for z in ZONE:
		if str(z["id"]) == id:
			return z
	return {}


func zona_corrente() -> String:
	return _zona_corrente


## Il centro della piazza di cui il giocatore è padrone: serve al HUD per
## dire da che parte tornare quando sei fuori servizio. Vector3.INF se non
## ce n'è nessuna (non capita, ma è meglio di uno zero che punta all'angolo
## della mappa).
## Il centro della piazza tua PIU' VICINA. Con una piazza sola era la
## piazza; adesso che se ne possono avere tre, la bussola deve puntare a
## quella dove conviene tornare, non alla prima dell'elenco.
func centro_piazza_mia() -> Vector3:
	var pl := get_tree().get_first_node_in_group("player")
	var da: Vector3 = pl.global_position if pl else Vector3.ZERO
	var best := Vector3.INF
	var best_d := INF
	for z in ZONE:
		if not GameManager.zona_mia(str(z.get("id", ""))):
			continue
		var rr: Array = z["rect"]
		var c := Vector3((rr[0] + rr[2]) * 0.5, 0.0, (rr[1] + rr[3]) * 0.5)
		var d: float = c.distance_to(da)
		if d < best_d:
			best_d = d
			best = c
	return best


func _centro_piazza_mia_vecchio() -> Vector3:
	for z in ZONE:
		if str(z.get("padrone", "")) != "tu":
			continue
		var r: Array = z["rect"]
		return Vector3((r[0] + r[2]) * 0.5, 0.0, (r[1] + r[3]) * 0.5)
	return Vector3.INF


# ---------------------------------------------------------------------------
# Raggruppamento delle mesh ripetute
# ---------------------------------------------------------------------------

## Le cose che si ripetono a centinaia — finestre, righe per terra, pali —
## non vanno messe come nodi separati: una città ne ha migliaia e il gioco
## si siederebbe. Si raccolgono per tipo e alla fine diventano un MultiMesh
## solo, cioè una chiamata di disegno sola.
# ---------------------------------------------------------------------------
# Modelli dentro ai MultiMesh
# ---------------------------------------------------------------------------
#
# **Il modo piu' economico che esista di rifare una citta' intera.**
#
# Il balaustrino di un balcone e' uno, ma la citta' ne disegna qualche
# migliaio: uno ogni sedici centimetri, su ogni balcone, su ogni palazzo.
# Istanziarne uno per uno un nodo sarebbe follia — e infatti il gioco li
# raggruppa gia' tutti in un MultiMesh solo, con dentro un cubo scalato.
#
# Ma la mesh di un MultiMesh puo' essere QUALUNQUE mesh. Quindi al posto del
# cubo ci si mette quella del modello fatto in Blender: **stesse istanze,
# stesso numero di draw call, stesso costo** — e al posto di uno stecchino
# quadrato c'e' un ferro battuto con la pancia e i collarini.
#
# La mesh si carica una volta sola e si tiene in cache: `Models.spawn` apre
# la scena e la istanzia, e farlo tremila volte costerebbe piu' del disegno.
var _mesh_cache: Dictionary = {}


## La mesh di un modello di `assets/models/`, o `null` se non c'e'.
func _mesh_modello(nome: String) -> Mesh:
	var pezzi := _pezzi_modello(nome)
	return pezzi[0]["mesh"] if not pezzi.is_empty() else null


## **Tutti i pezzi di un modello, non solo il primo.**
##
## `_mesh_modello` tornava la prima MeshInstance3D e buttava le altre. Con
## i modelli vecchi non si notava — panchina, cestino, lampione sono una
## mesh sola. Ma la roba nuova della 0.46 è fatta a pezzi: un lampione di
## ghisa ha il palo, il braccio e il vetro come oggetti separati perché
## hanno tre materiali diversi, e prendendo solo il primo veniva fuori un
## palo senza lampada. Qui si tengono tutti, ognuno con la trasformazione
## sua rispetto alla radice del modello.
func _pezzi_modello(nome: String) -> Array:
	if _mesh_cache.has(nome):
		return _mesh_cache[nome]
	var fuori: Array = []
	var n := Models.spawn(nome)
	# **'E `.mesh` so' 'na mesh sola** (0.59). I pezzi di Pandazole non sono
	# scene: `Models.spawn` li rende come un `MeshInstance3D` **radice**,
	# senza figli, e `find_children` guarda solo i figli. Senza questa riga
	# tornava una lista vuota e il pezzo non nasceva, senza un errore.
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		fuori.append({"mesh": (n as MeshInstance3D).mesh,
			"trasf": Transform3D.IDENTITY})
		n.queue_free()
		_mesh_cache[nome] = fuori
		return fuori
	if n != null:
		for c in n.find_children("*", "MeshInstance3D", true, false):
			var mi := c as MeshInstance3D
			if mi.mesh == null:
				continue
			# La trasformazione locale rispetto alla radice: l'importatore
			# glTF appende i nodi dentro a una gerarchia, e senza questa
			# il braccio del lampione finiva all'origine.
			var t := Transform3D.IDENTITY
			var nodo: Node3D = mi
			while nodo != null and nodo != n:
				t = nodo.transform * t
				nodo = nodo.get_parent() as Node3D
			fuori.append({"mesh": mi.mesh, "trasf": t})
		n.queue_free()
	_mesh_cache[nome] = fuori
	return fuori


## Come `_pezzo`, ma con dentro un modello invece di un cubo. L'origine del
## modello sta alla base, non al centro: chi chiama passa il punto d'appoggio.
func _pezzo_modello(nome: String, appoggio: Vector3, tipo: String,
		giro_y: float = 0.0, scala: float = 1.0) -> bool:
	var pezzi := _pezzi_modello(nome)
	if pezzi.is_empty():
		return false
	var base := Transform3D(Basis(), appoggio)
	if absf(giro_y) > 0.0001:
		base.basis = Basis(Vector3.UP, giro_y)
	if absf(scala - 1.0) > 0.0001:
		base.basis = base.basis.scaled(Vector3.ONE * scala)
	for i in pezzi.size():
		var mi := MeshInstance3D.new()
		mi.mesh = pezzi[i]["mesh"]
		mi.transform = base * (pezzi[i]["trasf"] as Transform3D)
		# Ogni pezzo va nel gruppo suo: un MultiMesh regge una mesh sola, e
		# mescolare palo e lampada nello stesso gruppo disegnerebbe pali
		# dove vanno le lampade.
		_batched("%s_%d" % [tipo, i], mi)
	return true


func _batched(tipo: String, mi: MeshInstance3D) -> void:
	if not _batch.has(tipo):
		_batch[tipo] = []
	# Le istanze raggruppate non sono nodi: `_alza_collina()` non le vede,
	# perche' quando gira stanno ancora in questa lista. Quindi si alzano
	# qui, una per una, al momento in cui vengono registrate.
	var p: Vector3 = mi.position
	if _collina_attiva:
		p.y += Collina.alzata(p.x, p.z)
	_batch[tipo].append({"mesh": mi.mesh, "mat": mi.material_override,
		"trasf": Transform3D(mi.transform.basis, p)})
	mi.queue_free()


## **Fin dove si vede un gruppo** (0.59). La roba piccola — la frutta sui
## banchi, le tazzine sul bancone, i giornali — sta in gruppi che vivono in
## un posto solo (il mercato, il bar), quindi il loro ingombro è piccolo e
## il raggio di vista di Godot funziona: a cinquanta metri un'arancia è
## mezzo pixel, e mille triangoli per mezzo pixel non si spendono.
## `tipo → metri`; chi non c'è si vede sempre, come prima.
var _batch_vista: Dictionary = {}


## **'E gruppe a quadrette** (0.60).
##
## `_batch_vista` funziona per la roba che sta in un posto solo. Per quella
## sparsa su tutta la città no: il gruppo dei balaustrini è **uno** (5.893
## ferri battuti da 312 triangoli, 1,84 milioni in tutto), il suo ingombro è
## la città intera, e Godot lo disegna sempre tutto — anche i balconi alle
## spalle, anche quelli a centocinquanta metri dietro a sei isolati. Da solo
## era quasi metà dei triangoli della città, e gli split dei condizionatori
## un altro quinto (`prova_conti`, chiusura della 0.59).
##
## Qui questi gruppi si tagliano in quadretti di `LATO_QUADRETTO` metri:
## ogni quadretto è un MultiMesh suo, che Godot può scartare quando sta
## fuori dall'inquadratura e che si spegne oltre la sua distanza. E per chi
## da lontano si deve ancora vedere — una ringhiera che sparisce lascia il
## balcone senza parapetto, e si nota — c'è il **cambio**: oltre la distanza
## ogni pezzo diventa la scatola del suo ingombro, dodici triangoli, dello
## stesso colore. A cinquanta metri un ferro battuto e un bastoncino nero
## sono lo stesso pixel.
##
## `prefisso → [metri, colore della scatola da lontano o null]`: con `null`
## da lontano il pezzo semplicemente non c'è (le piantine dei balconi, la
## merce davanti alle botteghe).
const QUADRETTI := {
	"balaustrino_": [45.0, Color(0.14, 0.15, 0.16)],
	"split_": [60.0, Color(0.80, 0.80, 0.78)],
	"balcone_": [50.0, null],
	"bottega_": [55.0, null],
	"vaso_": [55.0, null],
	"giara_": [55.0, null],
	# 'E decalcomanie (0.62): tombini, macchie, colature, graffiti. Piatte,
	# senza ombra e oltre i sessanta metri non si vedono più.
	"decal_": [60.0, null],
}
const LATO_QUADRETTO: float = 32.0


## Il prefisso di `QUADRETTI` che vale per questo gruppo, o "".
##
## **E chi tiene 'na vista soja va a quadrette pure lui** (0.60). Il raggio
## di `_batch_vista` si misura dal baricentro del gruppo: funziona per la
## frutta del mercato, che sta tutta lì, e non per chi è sparso per la città.
## Le tazzulelle della 0.59 stanno sui banconi di quattro bar diversi, il
## baricentro cade in mezzo alla città e a quaranta metri da lì non si
## vedevano più — su nessun bancone. Le sedie della 0.60 hanno fatto vedere
## il guaio: la signora seduta davanti al basso c'era, la sedia no. Adesso
## ogni gruppo con un raggio si taglia in quadretti, e il raggio vale per
## ogni quadretto.
func _quadretto_di(tipo: String) -> String:
	if _batch_vista.has(tipo):
		return "@vista"
	for pref in QUADRETTI:
		if tipo.begins_with(str(pref)):
			if pref == "bottega_" and tipo.begins_with("bottega_letto"):
				return ""
			return str(pref)
	return ""


## Un MultiMesh con le trasformazioni date, messo nel loro baricentro.
func _gruppo_mm(nome: String, mesh: Mesh, trasf: Array, mat: Material,
		da: float, fino: float) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = trasf.size()
	var centro := Vector3.ZERO
	for t in trasf:
		centro += (t as Transform3D).origin
	centro /= float(maxi(1, trasf.size()))
	for i in trasf.size():
		var t: Transform3D = trasf[i]
		t.origin -= centro
		mm.set_instance_transform(i, t)
	var nodo := MultiMeshInstance3D.new()
	nodo.name = nome
	nodo.multimesh = mm
	nodo.position = centro
	# Una decalcomania è un foglio a due centimetri dalla superficie: se
	# facesse ombra, la farebbe sulla superficie stessa (0.62).
	if nome.begins_with("Gruppo_decal_"):
		nodo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if da > 0.0:
		nodo.visibility_range_begin = da
		nodo.visibility_range_begin_margin = 4.0
	if fino > 0.0:
		nodo.visibility_range_end = fino
		nodo.visibility_range_end_margin = 4.0
	nodo.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	if mat != null:
		nodo.material_override = mat
	add_child(nodo)
	return nodo


func _flush_a_quadrette(tipo: String, lista: Array, pref: String) -> void:
	var regola: Array = QUADRETTI[pref] if pref != "@vista" \
		else [float(_batch_vista[tipo]), null]
	var fino: float = float(regola[0])
	var mesh: Mesh = lista[0]["mesh"]
	var scatola: Material = null
	var giusta := Transform3D.IDENTITY
	if regola[1] != null:
		scatola = Tex.flat(Color(regola[1]), 0.8)
		var aabb: AABB = mesh.get_aabb()
		giusta = Transform3D(Basis.from_scale(aabb.size.max(Vector3.ONE * 0.02)),
			aabb.get_center())
	var quadrette: Dictionary = {}
	for v in lista:
		var t: Transform3D = v["trasf"]
		var chiave := Vector2i(int(floorf(t.origin.x / LATO_QUADRETTO)),
			int(floorf(t.origin.z / LATO_QUADRETTO)))
		if not quadrette.has(chiave):
			quadrette[chiave] = []
		quadrette[chiave].append(t)
	for chiave in quadrette:
		var q: Array = quadrette[chiave]
		var suffisso := "_q%d_%d" % [chiave.x, chiave.y]
		_gruppo_mm("Gruppo_" + tipo + suffisso, mesh, q, lista[0]["mat"], 0.0, fino)
		if scatola != null:
			var lontane: Array = []
			for t in q:
				lontane.append((t as Transform3D) * giusta)
			_gruppo_mm("Gruppo_" + tipo + "_lontano" + suffisso, _cubo, lontane,
				scatola, fino, 0.0)


func _flush_batch() -> void:
	for tipo in _batch:
		var lista: Array = _batch[tipo]
		if lista.is_empty():
			continue
		var pref := _quadretto_di(str(tipo))
		if pref != "":
			_flush_a_quadrette(str(tipo), lista, pref)
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = lista[0]["mesh"]
		mm.instance_count = lista.size()
		# Un gruppo che si spegne da lontano sta **nel suo baricentro**, non
		# nell'origine del mondo: così la distanza si misura da dove sta la
		# roba, comunque Godot la misuri (dall'origine del nodo o dal centro
		# del suo ingombro).
		var centro := Vector3.ZERO
		if _batch_vista.has(tipo):
			for v in lista:
				centro += (v["trasf"] as Transform3D).origin
			centro /= float(lista.size())
		for i in lista.size():
			var t: Transform3D = lista[i]["trasf"]
			t.origin -= centro
			mm.set_instance_transform(i, t)
		var nodo := MultiMeshInstance3D.new()
		nodo.name = "Gruppo_" + tipo
		nodo.multimesh = mm
		nodo.position = centro
		if _batch_vista.has(tipo):
			nodo.visibility_range_end = float(_batch_vista[tipo])
			nodo.visibility_range_end_margin = 6.0
			nodo.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		# **`material_override` solo se ce n'e' uno.**
		#
		# I pezzi procedurali sono cubi grigi che prendono il colore dal
		# materiale di sovrascrittura. I modelli fatti in Blender invece si
		# portano i materiali DENTRO la mesh, uno per superficie — e
		# scriverci sopra un override nullo li spegneva tutti: la panchina
		# di legno e ghisa usciva bianca, e cosi' il lampione.
		if lista[0]["mat"] != null:
			nodo.material_override = lista[0]["mat"]
		add_child(nodo)
	_batch.clear()


# ---------------------------------------------------------------------------
# 'A ROBBA 'E PANDAZOLE (0.59)
# ---------------------------------------------------------------------------
#
# Il capo ha portato un pacchetto di **centosettantasette oggetti low poly**
# (Pandazole: casa, cucina, mercato, attrezzi, strada, tetti, natura) e ha
# chiesto di usarli per dare dettaglio alla città **senza sovrapporli** a
# quello che c'era già. Sono stati preparati da `tools/prepara_nuovi.gd`:
# una `.mesh` per pezzo, la base a quota zero, la scala giusta, e **un solo
# materiale per tutti** — l'atlante dei colori del pacchetto. Questo conta:
# mille pezzi che dividono lo stesso materiale finiscono in pochi MultiMesh
# (uno per forma) e costano pochissime chiamate di disegno.
#
# La regola per metterli è la stessa che vale per tutto il resto dell'arredo
# da quando esistono `prova_ngombri` e `prova_ntuppate`: **ogni pezzo sta
# attaccato a qualcosa che c'era già** — sul banco del mercato, davanti alla
# vetrina della sua bottega, sul tetto del suo palazzo, sulla ringhiera del
# suo balcone, dentro al recinto del suo cantiere. Niente sparso a caso in
# mezzo alla strada, che è il modo in cui in questo progetto le cose sono
# sempre finite nella corsia di qualcuno.

## Il colore del letto delle cassette e quanto sono alte stanno in
## `robba_panda.gd`, che li divide con le bancarelle del giorno di mercato.
const RobbaPanda := preload("res://scripts/robba_panda.gd")
const RobbaPsx := preload("res://scripts/robba_psx.gd")
const RobbaEsterna := preload("res://scripts/robba_esterna.gd")


## Un pezzo di Pandazole nel suo gruppo. `vista` > 0 spegne il gruppo oltre
## quei metri (vedi `_batch_vista`): si usa solo per i gruppi che stanno in
## un posto solo, perché il raggio si misura dal centro del gruppo.
func _panda(nome: String, pos: Vector3, giro: float, gruppo: String,
		vista: float = 0.0, scala: float = 1.0) -> bool:
	var tipo: String = gruppo + "_" + nome
	if vista > 0.0:
		_batch_vista[tipo + "_0"] = vista
	return _pezzo_modello(nome, pos, tipo, giro, scala)


## Come `_panda`, ma con una trasformazione intera: serve a chi non sta
## dritto (la pala appoggiata al muro, il giornale buttato storto).
func _panda_t(nome: String, t: Transform3D, gruppo: String,
		vista: float = 0.0) -> bool:
	var pezzi := _pezzi_modello(nome)
	if pezzi.is_empty():
		return false
	var tipo: String = gruppo + "_" + nome
	for i in pezzi.size():
		if vista > 0.0:
			_batch_vista["%s_%d" % [tipo, i]] = vista
		var mi := MeshInstance3D.new()
		mi.mesh = pezzi[i]["mesh"]
		mi.transform = t * (pezzi[i]["trasf"] as Transform3D)
		_batched("%s_%d" % [tipo, i], mi)
	return true


## **Come `_panda`, ma col modello centrato sul punto** (0.60). I pezzi di
## Pandazole hanno l'origine al centro della base; quelli del pacchetto PSX
## no — il divano ce l'ha sullo schienale, la porta sul cardine, il bagno
## chimico su uno spigolo. Qui si misura l'ingombro del modello e lo si
## sposta, così `centro` è davvero il centro della sua impronta a terra.
func _panda_c(nome: String, centro: Vector3, giro: float, gruppo: String,
		vista: float = 0.0, scala: float = 1.0) -> bool:
	var c: Vector3 = _centro_modello(nome) * scala
	var spostato: Vector3 = centro - Basis(Vector3.UP, giro) * Vector3(c.x, 0.0, c.z)
	return _panda(nome, spostato, giro, gruppo, vista, scala)


var _centri_modello: Dictionary = {}


## Il centro dell'ingombro di un modello, nelle sue coordinate.
func _centro_modello(nome: String) -> Vector3:
	if _centri_modello.has(nome):
		return _centri_modello[nome]
	var tot := AABB()
	var primo := true
	for pz in _pezzi_modello(nome):
		var a: AABB = (pz["trasf"] as Transform3D) * (pz["mesh"] as Mesh).get_aabb()
		if primo:
			tot = a
			primo = false
		else:
			tot = tot.merge(a)
	var c: Vector3 = tot.get_center() if not primo else Vector3.ZERO
	_centri_modello[nome] = c
	return c


## Un punto nel sistema di una bottega (o di un banco): `x` lungo la
## facciata, `z` in avanti verso la strada, `y` in su.
static func _in_locale(pos: Vector3, giro: float, x: float, y: float,
		z: float) -> Vector3:
	return pos + Basis(Vector3.UP, giro) * Vector3(x, y, z)


## Uno a sorte da una lista di `[nome, peso]`.
static func _a_sorte(lista: Array, rng: RandomNumberGenerator) -> String:
	var tot := 0
	for v in lista:
		tot += int(v[1])
	var x: int = rng.randi_range(1, maxi(1, tot))
	for v in lista:
		x -= int(v[1])
		if x <= 0:
			return str(v[0])
	return str(lista[0][0])


## **'Na cascetta chiena** (vedi `RobbaPanda.cascetta_chiena`): i pezzi
## vanno nei gruppi della città, il letto colorato in un gruppo per colore.
func _cascetta_chiena(frutto: String, pos: Vector3, giro: float,
		rng: RandomNumberGenerator, gruppo: String, vista: float,
		tinta_letto: Color = Color(0, 0, 0, 0)) -> void:
	for pz in RobbaPanda.cascetta_chiena(frutto, pos, giro, rng, tinta_letto):
		if pz.has("letto"):
			var tinta: Color = pz["letto"]
			var letto := MeshInstance3D.new()
			letto.mesh = _cubo
			letto.transform = pz["t"]
			letto.material_override = Tex.flat(tinta, 0.8)
			var tipo_letto: String = gruppo + "_letto_" + tinta.to_html(false)
			if vista > 0.0:
				_batch_vista[tipo_letto] = vista
			_batched(tipo_letto, letto)
		else:
			_panda_t(str(pz["nome"]), pz["t"], gruppo, vista)


# --- 'A strada ---------------------------------------------------------------

## I cassonetti delle scene d'angolo, segnati mentre si mettono: accanto ci
## vanno i sacchetti e la campana del vetro.
var _cassonetti: Array = []


## **L'arredo nuovo d''a strada** (0.59). Si mette per ultimo, quando tutto
## il resto è già al suo posto e segnato nel catasto (`_ingombri`): ogni
## pezzo chiede `_sta_libero` prima di nascere, e se il posto non va bene
## prova il prossimo o rinuncia. Il seme è fisso: stessa città ogni
## partita.
## **'E nomme scritte pe' disteso** (0.59). Stavano costruiti al volo
## (`"sacchetto_%d" % k`), e `prova_asset`, che cerca i nomi dei modelli nel
## codice, ne contava tredici «mai usati» che invece in città ci stanno
## tutti. Un nome che non si può cercare è un nome che prima o poi si perde:
## adesso stanno scritti qui, per intero.
const FUSTI := ["fusto_1", "fusto_2", "fusto_3"]
const QUADRI_ELETTRICI := ["quadro_elettrico_1", "quadro_elettrico_2",
	"quadro_elettrico_3"]
const SACCHETTI := ["sacchetto_1", "sacchetto_2", "sacchetto_3"]
const CAMPANE := ["bidone_strada_1", "bidone_strada_2"]
const ALBERI_VIALE := ["albero_viale_1", "albero_viale_2", "albero_viale_3",
	"albero_viale_4"]


func _build_arredo_novo() -> void:
	_raccogli_posti_attivita()
	# **L'auto in sosta si mette pe' ultima** (0.59): prima stava in mezzo
	# alla costruzione delle piazze, e tutto quello che nasceva dopo — le
	# vetrine, i lampioni, la gente ferma — non sapeva che lì c'era
	# parcheggiata una macchina. Otto vetrine del Corso avevano la merce
	# **dentro** alla macchina davanti, quattro lampioni stavano dentro a
	# un cofano, un signore aspettava dentro a una portiera. Non lo vedeva
	# nessuno perché le auto, sul Corso, un corpo non l'avevano (vedi
	# `in_corsia_girato`). Adesso le auto vengono dopo, e si mettono solo
	# dove c'è posto: sono scenografia, e la scenografia cede il passo.
	_auto_in_sosta()
	_build_angoli()
	if not Models.has_model("quadro_elettrico_1"):
		_build_personagge_nove()
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 59001
	_quadri_elettrici(rng)
	_munnezza_attuorno(rng)
	_cartelli_stradali(rng)
	_arbere_d_o_lungomare(rng)
	_verde_d_e_slarghi(rng)
	# **'A robba 'e cchiù** (0.60): il secondo giro del pacchetto PSX. Si
	# mette per ultima, col suo seme, dove c'è posto (vedi `robba_psx.gd`).
	RobbaPsx.metti(self)
	# **'A robba 'e fore** (0.62): gli asset esterni che il gioco non aveva
	# già — decalcomanie, motorini, sedie, coni… Per ultima, col suo seme
	# (vedi `robba_esterna.gd`).
	RobbaEsterna.metti(self)
	_build_personagge_nove()


# ---------------------------------------------------------------------------
# 'E perzone nove d''a 0.61
# ---------------------------------------------------------------------------

const NuovoAbusivoScript := preload("res://scripts/nuovo_abusivo_3d.gd")
const TuristaScript := preload("res://scripts/turista_spierzo_3d.gd")
const PanaroScript := preload("res://scripts/panaro_3d.gd")


## Gennarino 'o Nuovo, 'o turista spierzo e 'o panaro 'e Donna Filumena.
## I primi due si muovono da soli (compaiono quando vogliono loro); il
## panaro sta appeso a un muro della tua piazza, e si cerca per ultimo,
## quando la città sa già dove sta tutto il resto. **Nessun numero a
## caso**: il caso della città è uno solo (vedi COME-RIPRENDERE, 3.5).
func _build_personagge_nove() -> void:
	var g := NuovoAbusivoScript.new()
	g.name = "GennarinoONuovo"
	add_child(g)
	var t := TuristaScript.new()
	t.name = "TuristaSpierzo"
	add_child(t)
	var casa: Dictionary = zona_per_id("piazza")
	if casa.is_empty():
		return
	var r: Array = casa["rect"]
	var rett := Rect2(float(r[0]), float(r[1]), float(r[2]) - float(r[0]),
		float(r[3]) - float(r[1]))
	var centro := Vector3(rett.get_center().x, 0.0, rett.get_center().y)
	var meglio: Array = []
	var d_min: float = 1e9
	for c in _facciate_verso(rett, 8.0, 3.0):
		var a: float = deg_to_rad(float(c[2]))
		var fuori := Vector3(sin(a), 0.0, cos(a))
		var terra := Vector3(float(c[0]), 0.0, float(c[1])) + fuori * 0.75
		if not _sta_libero(terra, 0.5):
			continue
		# Un metro e mezzo per parte lungo il muro, per il balcone.
		var lungo := Vector3(fuori.z, 0.0, -fuori.x)
		if _dint_pe_panaro(terra + lungo * 1.0) or _dint_pe_panaro(terra - lungo * 1.0):
			continue
		var d: float = terra.distance_to(centro)
		if d < d_min:
			d_min = d
			meglio = [Vector3(float(c[0]), 0.0, float(c[1])), fuori]
	if meglio.is_empty():
		push_warning("'O panaro nun ha truvato 'nu muro libero")
		return
	var pan := PanaroScript.new()
	pan.name = "Panaro"
	add_child(pan)
	pan.global_position = meglio[0]
	pan.configura(meglio[1])


func _dint_pe_panaro(p: Vector3) -> bool:
	return dint_ô_palazzo(p, 0.2)


## Dove stanno i quadri elettrici (0.60): `[punto, verso la strada, largo]`.
var _quadri_posti: Array = []


## I quadri elettrici dell'Enel contro i muri: grigi, con la saetta gialla,
## uno ogni tanto. Da vicino sono il pezzo più "vero" che c'è, perché
## nessuno li metterebbe apposta in un gioco. Davanti è il +Z del modello.
func _quadri_elettrici(rng: RandomNumberGenerator) -> void:
	var messi := 0
	for st in STRADE:
		if messi >= 16:
			break
		var w: float = float(st[2]) - float(st[0])
		var l: float = float(st[3]) - float(st[1])
		var lungo_z: bool = l > w
		var corsa: float = l if lungo_z else w
		if corsa < 12.0 or rng.randf() > 0.55:
			continue
		var quale: String = QUADRI_ELETTRICI[messi % QUADRI_ELETTRICI.size()]
		var largo_q: float = 1.5 if quale == "quadro_elettrico_3" else 0.64
		for _prova in range(8):
			var t: float = rng.randf_range(3.0, corsa - 3.0)
			var lato: int = rng.randi() % 2
			var p: Vector3
			var fuori: Vector3
			if lungo_z:
				fuori = Vector3(1, 0, 0) if lato == 0 else Vector3(-1, 0, 0)
				p = Vector3((float(st[0]) + 0.28) if lato == 0 else (float(st[2]) - 0.28),
					0.0, float(st[1]) + t)
			else:
				fuori = Vector3(0, 0, 1) if lato == 0 else Vector3(0, 0, -1)
				p = Vector3(float(st[0]) + t, 0.0,
					(float(st[1]) + 0.28) if lato == 0 else (float(st[3]) - 0.28))
			# Sporge cinquantadue centimetri dal muro, quanto è largo non conta
			# per la corsia; e il muro dietro ci dev'essere (non un incrocio).
			if not _sta_libero(p, largo_q * 0.5 + 0.1, 0.3) \
					or not dint_ô_palazzo(p - fuori * 0.6, 0.0):
				continue
			var giro: float = atan2(fuori.x, fuori.z)
			_panda(quale, p, giro, "strada")
			_solido(p + Vector3(0, 0.65, 0), Vector3(largo_q, 1.3, 0.52), giro)
			_quadri_posti.append([p, fuori, largo_q])
			messi += 1
			break


## **'A munnezza attuorno ô cassonetto.** A Napoli il cassonetto non sta
## mai da solo: accanto ci sono i sacchetti di chi è passato quando era
## pieno, e più in là la campana blu del vetro. Due-quattro sacchetti a
## mucchio da un lato, la campana dall'altro — se c'è posto.
func _munnezza_attuorno(rng: RandomNumberGenerator) -> void:
	for c in _cassonetti:
		var p: Vector3 = c[0]
		var giro: float = float(c[1])
		var lungo := Vector3(cos(giro), 0, -sin(giro))
		# Si cammina lungo il muro, dai due lati del cassonetto, e si mette
		# la roba dove c'è posto: prima i sacchetti (a un metro e settanta,
		# fuori dall'ingombro del cassonetto), poi l'ingombrante, poi la
		# campana. Il motorino dell'angolo sta da una parte sola, quindi di
		# solito si lavora dall'altra.
		var da_mettere: Array = ["sacchetti", "ingombrante", "campana"]
		for verso in [-1.0, 1.0]:
			var d: float = 1.7
			var tentativi := 0
			while not da_mettere.is_empty() and tentativi < 4:
				tentativi += 1
				var cosa: String = str(da_mettere[0])
				var r_cosa: float = 0.55
				var ing: Array = []
				if cosa == "ingombrante":
					ing = INGOMBRANTI[_ingombranti_messi % INGOMBRANTI.size()]
					var dm: Vector3 = ing[1]
					r_cosa = maxf(dm.x, dm.z) * 0.5 + 0.05
				elif cosa == "campana":
					r_cosa = 0.5
				var q: Vector3 = p + lungo * ((d + r_cosa) * verso)
				if not _sta_libero(q, r_cosa):
					d += 0.8
					continue
				match cosa:
					"sacchetti":
						for k in range(rng.randi_range(3, 5)):
							var off := Vector3(rng.randf_range(-0.32, 0.32), 0.0,
								rng.randf_range(-0.32, 0.32))
							_panda(SACCHETTI[k % SACCHETTI.size()], q + off,
								rng.randf_range(-PI, PI), "munnezza", 0.0,
								rng.randf_range(0.8, 1.05))
						_solido(q + Vector3(0, 0.3, 0), Vector3(1.0, 0.6, 1.0), giro)
					"ingombrante":
						var dim: Vector3 = ing[1]
						_panda_c(str(ing[0]), q, giro + rng.randf_range(-0.15, 0.15),
							"munnezza")
						_solido(q + Vector3(0, dim.y * 0.5, 0), dim, giro)
						_ingombranti_messi += 1
					"campana":
						_panda(CAMPANE[_campane_messe % CAMPANE.size()], q, giro,
							"munnezza")
						_solido(q + Vector3(0, 0.65, 0), Vector3(0.85, 1.3, 0.85), giro)
						_campane_messe += 1
				d += r_cosa * 2.0 + 0.2
				da_mettere.pop_front()
	_ingombranti_spierti()
	_fore_ô_vascio()


## Gli ingombranti che accanto ai cassonetti non ci sono entrati si
## lasciano contro un muro qualunque, vicino a una delle scene d'angolo:
## il divano buttato in fondo al vicolo, il mobile della cucina vecchia
## accanto a un portone.
func _ingombranti_spierti() -> void:
	# E le campane del vetro che accanto ai cassonetti non ci sono entrate:
	# almeno una per forma, contro un muro vicino a una scena d'angolo.
	var k0 := 0
	while _campane_messe < 2 and k0 < ANGOLI.size():
		var a0: Array = ANGOLI[(k0 * 7 + 1) % ANGOLI.size()]
		k0 += 1
		var dim_c := Vector3(0.85, 1.3, 0.85)
		var pz_c := [["campana", 0.0, 0.43, 0.43, 0.0, dim_c]]
		var posto_c: Dictionary = _posto_pe_scena(Vector3(float(a0[0]), 0.0,
			float(a0[1]) - 5.0), pz_c)
		if posto_c.is_empty():
			continue
		var g_c: float = float(posto_c["giro"])
		var c_c: Vector3 = (posto_c["muro"] as Vector3) \
			+ Vector3(sin(g_c), 0, cos(g_c)) * 0.46
		_panda(CAMPANE[_campane_messe % CAMPANE.size()], c_c, g_c, "munnezza")
		_solido(c_c + Vector3(0, 0.65, 0), dim_c, g_c)
		_campane_messe += 1
	var k := 0
	while _ingombranti_messi < INGOMBRANTI.size() and k < ANGOLI.size():
		var ing: Array = INGOMBRANTI[_ingombranti_messi]
		var dim: Vector3 = ing[1]
		var a: Array = ANGOLI[(k * 5 + 3) % ANGOLI.size()]
		k += 1
		var pezzi := [[str(ing[0]), 0.0, dim.x * 0.5, dim.z * 0.5, 0.0, dim]]
		var posto: Dictionary = _posto_pe_scena(Vector3(float(a[0]), 0.0,
			float(a[1]) + 6.0), pezzi)
		if posto.is_empty():
			continue
		var giro: float = float(posto["giro"])
		var fuori := Vector3(sin(giro), 0, cos(giro))
		var c: Vector3 = (posto["muro"] as Vector3) + fuori * (dim.z * 0.5 + 0.03)
		_panda_c(str(ing[0]), c, giro, "munnezza")
		_solido(c + Vector3(0, dim.y * 0.5, 0), dim, giro)
		_ingombranti_messi += 1
	_materazze()


## I materassi in piedi contro il muro (0.60), vicino alle scene d'angolo
## che non ne hanno già uno: il posto lo trova `_posto_pe_scena`, come per
## gli altri ingombranti spersi.
func _materazze() -> void:
	if not Models.has_model("materasso"):
		return
	var messi := 0
	var k := 0
	while messi < MATERAZZE.size() and k < ANGOLI.size():
		var a: Array = ANGOLI[(k * 3 + 2) % ANGOLI.size()]
		k += 1
		var dim: Vector3 = MATERAZZO_DIM
		var pezzi := [["materasso", 0.0, dim.x * 0.5, dim.z * 0.5, 0.0, dim]]
		var posto: Dictionary = _posto_pe_scena(Vector3(float(a[0]), 0.0,
			float(a[1]) - 3.0), pezzi)
		if posto.is_empty():
			continue
		var giro: float = float(posto["giro"])
		var fuori := Vector3(sin(giro), 0, cos(giro))
		var lungo := Vector3(cos(giro), 0, -sin(giro))
		var muro: Vector3 = posto["muro"]
		# Il modello è sdraiato: X lungo 1,96, Y lo spessore, Z largo 1,01, con
		# l'origine al centro della base. In piedi: la X va in su (appena
		# inclinata verso il muro), la Y guarda la strada, la Z corre lungo
		# il muro.
		var inclina: float = deg_to_rad(12.0)
		var su: Vector3 = Vector3.UP * cos(inclina) - fuori * sin(inclina)
		var davanti: Vector3 = fuori * cos(inclina) + Vector3.UP * sin(inclina)
		var b := Basis(su, davanti, lungo)
		var piede: Vector3 = muro + fuori * (0.2 + 1.96 * sin(inclina))
		_panda_t(str(MATERAZZE[messi]), Transform3D(b, piede + su * 0.98),
			"munnezza")
		_solido(muro + fuori * (dim.z * 0.5 + 0.03) + Vector3(0, dim.y * 0.5, 0),
			dim, giro)
		messi += 1


var _ingombranti_messi: int = 0
var _campane_messe: int = 0


## Gli ingombranti buttati accanto ai cassonetti, con la loro impronta
## (larghezza, altezza, profondità del modello).
##
## **E 'a robba vecchia d''o pacchetto PSX** (0.60): il divano sfondato, la
## poltrona, il televisore a tubo col baffo dell'antenna, il comò della
## nonna, l'armadio. Stanno in fila con quelli di prima: accanto ai
## cassonetti vanno a turno, e quelli che non ci entrano finiscono contro
## un muro vicino a una scena d'angolo (`_ingombranti_spierti`). Le misure
## sono quelle vere, scalate (vedi `prova_psx`).
const INGOMBRANTI := [
	["divano", Vector3(1.59, 0.9, 0.76)],
	["frigorifero", Vector3(1.14, 1.68, 0.65)],
	["armadio", Vector3(1.0, 1.9, 0.54)],
	["cucina_gas", Vector3(0.86, 0.98, 0.55)],
	["mobile_cucina", Vector3(0.43, 0.98, 0.55)],
	["lavandino", Vector3(1.44, 0.91, 0.61)],
	["divano_vecchio", Vector3(1.91, 0.88, 0.84)],
	["tv_vecchia", Vector3(0.51, 0.79, 0.42)],
	["poltrona_vecchia", Vector3(1.01, 0.86, 0.79)],
	["comodino_vecchio", Vector3(0.56, 0.64, 0.52)],
	["divano_vecchio2", Vector3(1.98, 0.93, 0.84)],
	["armadio_vecchio", Vector3(1.34, 2.10, 0.64)],
]

## **'E materazze appujate ô muro** (0.60). Non si mettono per terra come
## gli altri ingombranti: a Napoli il materasso vecchio si lascia in piedi
## contro il muro, accanto al portone, finché qualcuno non se lo porta. Il
## corpo solido è l'impronta del materasso inclinato.
const MATERAZZE := ["materasso", "materasso_macchiato", "materasso"]
const MATERAZZO_DIM := Vector3(1.05, 1.95, 0.62)


## **'A lavatrice fore â porta.** Nei bassi la lavatrice sta fuori, contro
## il muro accanto alla porta, perché dentro non ci entra: e sopra ci sono
## già i panni stesi (vedi `vascio_3d._panni_stesi`). Accanto la bombola
## del gas di riserva. Sulla striscia di novanta centimetri fra il muro e
## la corsia del vicolo, un metro e mezzo più giù della porta, così chi
## esce di casa non ci sbatte.
func _fore_ô_vascio() -> void:
	var porta: Vector3 = VascioScript.PORTA_POS
	var q := Vector3(porta.x + 0.2, 0.0, porta.z - 2.15)
	if _sta_libero(q, 0.37):
		_panda("lavatrice", q, PI * 0.5, "vascio_fore")
		_solido(q + Vector3(0, 0.43, 0), Vector3(0.65, 0.86, 0.71))
		var b: Vector3 = q + Vector3(0.0, 0.0, -0.95)
		if _sta_libero(b, 0.3):
			_panda("bombola", b, PI * 0.5, "vascio_fore")
			_solido(b + Vector3(0, 0.38, 0), Vector3(0.6, 0.76, 0.3))


## **'E cartielle.** La segnaletica che una strada di Napoli ha davvero, e
## che nessuno rispetta: il divieto di sosta (in un gioco sul parcheggio
## abusivo è il cartello più importante di tutti), la P davanti alle
## piazze, il senso vietato e lo stop agli imbocchi dei vicoli, le strisce
## vicino ai guaglioni, il dosso sul lungomare e la discesa pericolosa in
## cima alle rampe del Vomero. La faccia del cartello è il +Z del modello.
##
## I quattro cartelli **americani** del pacchetto (il limite di velocità
## col riquadro nero e i due rombi gialli) in una strada di Napoli non ci
## stanno. I rombi gialli però somigliano ai cartelli provvisori dei lavori
## (in Italia quelli dei cantieri sono gialli): uno per cantiere, in testa
## alla transenna. I limiti di velocità stanno appoggiati al muro dello
## sfasciacarrozze, che li colleziona (vedi `garage_3d.gd`).
func _cartelli_stradali(rng: RandomNumberGenerator) -> void:
	# La P davanti a ogni varco, sul primo spigolo libero, girata verso
	# fuori (verso chi arriva).
	for v in VARCHI:
		var c := Vector3((float(v[0]) + float(v[2])) * 0.5, 0.0,
			(float(v[1]) + float(v[3])) * 0.5)
		for spigolo in [Vector2(float(v[0]) - 0.7, float(v[1]) - 0.7),
				Vector2(float(v[2]) + 0.7, float(v[1]) - 0.7),
				Vector2(float(v[0]) - 0.7, float(v[3]) + 0.7),
				Vector2(float(v[2]) + 0.7, float(v[3]) + 0.7)]:
			var q := Vector3(spigolo.x, 0.0, spigolo.y)
			if not _sta_libero(q, 0.45):
				continue
			var d: Vector3 = (q - c).normalized()
			_cartello("cartello_parcheggio", q, atan2(d.x, d.z))
			break
	# Divieti di sosta e sensi vietati lungo le strade.
	var divieti := 0
	var vicoli := 0
	for st in STRADE:
		var w: float = float(st[2]) - float(st[0])
		var l: float = float(st[3]) - float(st[1])
		var lungo_z: bool = l > w
		var luce: float = w if lungo_z else l
		var corsa: float = l if lungo_z else w
		if corsa < 14.0:
			continue
		if luce > 5.5 and divieti < 10 and rng.randf() < 0.5:
			# Il divieto sta sul bordo, a sessanta centimetri dal muro, e
			# guarda lungo la strada.
			for _prova in range(3):
				var t: float = rng.randf_range(4.0, corsa - 4.0)
				var q: Vector3
				if lungo_z:
					q = Vector3(float(st[0]) + 0.6 if rng.randf() < 0.5 else float(st[2]) - 0.6,
						0.0, float(st[1]) + t)
				else:
					q = Vector3(float(st[0]) + t, 0.0,
						float(st[1]) + 0.6 if rng.randf() < 0.5 else float(st[3]) - 0.6)
				if not _sta_libero(q, 0.45):
					continue
				var giro_d: float = (0.0 if rng.randf() < 0.5 else PI) \
					+ (0.0 if lungo_z else PI * 0.5)
				_cartello("cartello_divieto_sosta", q, giro_d)
				divieti += 1
				break
		elif luce <= 5.5 and vicoli < 7 and rng.randf() < 0.45:
			# All'imbocco del vicolo: il senso vietato su un muro e lo stop
			# sull'altro, tutti e due verso fuori.
			var qa: Vector3
			var qb: Vector3
			var giro_v: float
			if lungo_z:
				qa = Vector3(float(st[0]) + 0.35, 0.0, float(st[1]) + 0.9)
				qb = Vector3(float(st[2]) - 0.35, 0.0, float(st[1]) + 0.9)
				giro_v = PI
			else:
				qa = Vector3(float(st[0]) + 0.9, 0.0, float(st[1]) + 0.35)
				qb = Vector3(float(st[0]) + 0.9, 0.0, float(st[3]) - 0.35)
				giro_v = -PI * 0.5
			if _sta_libero(qa, 0.35):
				_cartello("cartello_senso_vietato", qa, giro_v)
				vicoli += 1
			if _sta_libero(qb, 0.35):
				_cartello("cartello_stop", qb, giro_v)
	# Le strisce pedonali vicino ai due campetti dei guaglioni.
	for centro in [Vector3(42.0, 0, 15.0), Vector3(34.0, 0, 139.0)]:
		var messo := false
		for raggio in [7.5, 9.0, 10.5]:
			if messo:
				break
			for k in range(12):
				var a: float = float(k) / 12.0 * TAU
				var q: Vector3 = centro + Vector3(cos(a), 0.0, sin(a)) * float(raggio)
				if _sta_libero(q, 0.45):
					var d: Vector3 = (q - centro).normalized()
					_cartello("cartello_pedoni", q, atan2(d.x, d.z))
					messo = true
					break
	# Il dosso sul lungomare, uno per verso (si scorre finché c'è posto:
	# lì ci stanno anche gli alberelli nuovi).
	for dosso in [[Vector3(62.0, 0.0, 0.55), -PI * 0.5],
			[Vector3(150.0, 0.0, 0.55), PI * 0.5]]:
		for dx in [0.0, 2.0, -2.0, 4.0, -4.0, 6.0, -6.0]:
			var qd: Vector3 = (dosso[0] as Vector3) + Vector3(float(dx), 0.0, 0.0)
			if _sta_libero(qd, 0.45):
				_cartello("cartello_dosso", qd, float(dosso[1]))
				break
	# 'A discesa pericolosa in cima alle rampe del Vomero: sul terrapieno,
	# a lato della rampa, verso chi sta per scendere.
	for im in Collina.IMBOCCHI:
		var lato: String = str(im[0])
		var c2: float = float(im[1])
		var mezzo_l: float = float(im[2]) * 0.5
		var q2 := Vector3.ZERO
		var giro_c: float = 0.0
		match lato:
			"n":
				q2 = Vector3(c2 + mezzo_l - 0.4, 0.0, Collina.RECT[1] + 0.9)
				giro_c = 0.0
			"s":
				q2 = Vector3(c2 + mezzo_l - 0.4, 0.0, Collina.RECT[3] - 0.9)
				giro_c = PI
			"o":
				q2 = Vector3(Collina.RECT[0] + 0.9, 0.0, c2 + mezzo_l - 0.4)
				giro_c = PI * 0.5
			"e":
				q2 = Vector3(Collina.RECT[2] - 0.9, 0.0, c2 + mezzo_l - 0.4)
				giro_c = -PI * 0.5
		if _sta_libero(q2, 0.3):
			_cartello("cartello_discesa", q2, giro_c)


## Un cartello col suo palo solido (dodici centimetri: ci si sbatte, non ci
## si incastra).
func _cartello(nome: String, q: Vector3, giro: float) -> void:
	if _panda(nome, q, giro, "cartelli"):
		_solido(q + Vector3(0, 1.1, 0), Vector3(0.12, 2.2, 0.12))


## **Ll'arbere d''o lungomare.** Il lato mare della strada di sopra (z = 0,
## dove comincia Mergellina) era una fila di niente: i pini stanno solo al
## belvedere, le palme stanno giù sulla passeggiata. Adesso ci sta un
## alberello ogni sedici metri, con l'erba e i fiori sotto, e il tronco che
## ferma. Il belvedere resta libero: è lì che si guarda il mare.
func _arbere_d_o_lungomare(rng: RandomNumberGenerator) -> void:
	var x: float = 6.0
	while x < LARGHEZZA - 5.0:
		if x > 12.0 and x < 52.0:
			x += 16.0
			continue
		var q := Vector3(x + rng.randf_range(-1.5, 1.5), 0.0, 0.6)
		if _sta_libero(q, 0.45):
			var quale: String = ALBERI_VIALE[_arbere_messe % ALBERI_VIALE.size()]
			_arbere_messe += 1
			_panda(quale, q, rng.randf_range(-PI, PI), "lungomare", 0.0,
				rng.randf_range(0.9, 1.1))
			_solido(q + Vector3(0, 1.2, 0), Vector3(0.32, 2.4, 0.32))
			_aiuola(q, rng)
			# Uno ogni tre, un cespuglio basso accanto al tronco.
			var qc: Vector3 = q + Vector3(1.3, 0.0, 0.1)
			if _arbere_messe % 3 == 1 and _sta_libero(qc, 0.5):
				_panda("cespuglio_6", qc, rng.randf_range(-PI, PI), "lungomare")
				_solido(qc + Vector3(0, 0.4, 0), Vector3(0.9, 0.8, 0.9))
		x += 16.0


var _arbere_messe: int = 0


## L'erba e i fiori ai piedi di un albero: tre-quattro ciuffi bassi.
func _aiuola(q: Vector3, rng: RandomNumberGenerator) -> void:
	for k in range(rng.randi_range(3, 4)):
		var a: float = rng.randf_range(0.0, TAU)
		var r: float = rng.randf_range(0.32, 0.55)
		var quale: String = ["erba_1", "erba_2", "erba_4", "erba_5", "erba_6",
			"fiori_1", "fiori_3", "fiori_6", "erba_3"][rng.randi() % 9]
		_panda(quale, q + Vector3(cos(a) * r, 0.0, sin(a) * r),
			rng.randf_range(-PI, PI), "aiuole", 0.0, rng.randf_range(0.7, 1.0))


## In giro sulla lista: i pezzi più rari in testa, così ci stanno tutti
## anche quando gli slarghi hanno poco posto.
const CESPUGLI := ["fioriera_3", "siepe_2", "cespuglio_5", "fioriera_2",
	"cespuglio_2", "siepe_1", "cespuglio_4", "cespuglio_1", "cespuglio_3",
	"cespuglio_6"]
const ALBERI_SLARGO := ["albero_1", "albero_3", "albero_2", "albero_4",
	"albero_5"]
var _cespugli_messi: int = 0
var _alberi_messi: int = 0


## **'O verde d''e slarghi.** Le fioriere lunghe contro i muri, i
## cespugli e le siepi negli angoli, e qualche albero vero (non pino) dove
## c'è posto per la chioma. Sempre contro il bordo dello slargo, mai in
## mezzo: il mezzo è di chi ci passa e dei guaglioni.
func _verde_d_e_slarghi(rng: RandomNumberGenerator) -> void:
	var fioriere := 0
	for sl in SLARGHI:
		var x0: float = float(sl[0])
		var z0: float = float(sl[1])
		var x1: float = float(sl[2])
		var z1: float = float(sl[3])
		# I quattro lati, un po' dentro.
		var lati := [
			[Vector3(x0, 0, z0 + 0.45), Vector3(1, 0, 0), x1 - x0, 0.0],
			[Vector3(x0, 0, z1 - 0.45), Vector3(1, 0, 0), x1 - x0, PI],
			[Vector3(x0 + 0.45, 0, z0), Vector3(0, 0, 1), z1 - z0, PI * 0.5],
			[Vector3(x1 - 0.45, 0, z0), Vector3(0, 0, 1), z1 - z0, -PI * 0.5],
		]
		for lt in lati:
			var da: Vector3 = lt[0]
			var dir: Vector3 = lt[1]
			var lung: float = float(lt[2])
			var t: float = 3.0
			while t < lung - 3.0:
				var q: Vector3 = da + dir * t
				var dado: float = rng.randf()
				if dado < 0.3 and fioriere < 12 and _sta_libero(q, 1.35):
					# La fioriera lunga: la X del modello lungo il lato.
					var giro_f: float = atan2(-dir.z, dir.x)
					_panda("fioriera_1", q, giro_f, "slarghi")
					_solido(q + Vector3(0, 0.55, 0), Vector3(2.5, 1.1, 0.72), giro_f)
					fioriere += 1
					t += 5.0
					continue
				if dado < 0.5 and _sta_libero(q, 0.75):
					var cesp: String = str(CESPUGLI[_cespugli_messi % CESPUGLI.size()])
					_cespugli_messi += 1
					_panda(cesp, q, rng.randf_range(-PI, PI), "slarghi")
					_solido(q + Vector3(0, 0.5, 0), Vector3(1.0, 1.0, 1.0))
					t += 4.0
					continue
				t += 3.5
		# Due alberi veri per slargo, dove c'è posto. Non negli angoli fissi:
		# gli slarghi sono tagliati dalle corsie delle strade che ci passano
		# in mezzo, e gli angoli cadono quasi sempre lì dentro. Si prova una
		# griglia di punti ogni metro e mezzo, e fra quelli liberi si prende
		# il più vicino a un bordo (l'albero sta a lato, non in mezzo); il
		# secondo almeno a sei metri dal primo. I due grossi (la quercia
		# larga sei metri e l'albero tondo) si riducono a due terzi, che la
		# chioma non entri nelle facciate.
		var messi: Array = []
		for _k in range(2):
			var albero: String = str(ALBERI_SLARGO[_alberi_messi % ALBERI_SLARGO.size()])
			var grosso: bool = albero == "albero_1" or albero == "albero_2"
			var margine: float = 2.6 if grosso else 1.4
			var migliore := Vector3.INF
			var bordo_min := INF
			var gx: float = x0 + margine
			while gx <= x1 - margine:
				var gz: float = z0 + margine
				while gz <= z1 - margine:
					var q := Vector3(gx, 0.0, gz)
					var lontano := true
					for m in messi:
						if (m as Vector3).distance_to(q) < 6.0:
							lontano = false
					var bordo: float = minf(minf(gx - x0, x1 - gx), minf(gz - z0, z1 - gz))
					if lontano and bordo < bordo_min and _perche_nun_sta(q, 1.1) == "":
						bordo_min = bordo
						migliore = q
					gz += 1.5
				gx += 1.5
			if migliore == Vector3.INF:
				break
			_panda(albero, migliore, rng.randf_range(-PI, PI), "slarghi", 0.0,
				rng.randf_range(0.62, 0.72) if grosso else rng.randf_range(0.85, 1.05))
			_solido(migliore + Vector3(0, 1.2, 0), Vector3(0.45, 2.4, 0.45))
			_aiuola(migliore, rng)
			_alberi_messi += 1
			messi.append(migliore)


# --- 'E tetti ---------------------------------------------------------------

## Quello che sta sui tetti di Napoli: le antenne, i comignoli, le cisterne
## dell'acqua (che al Sud stanno su tutti i terrazzi, perché l'acqua
## d'estate manca), gli sfiati e i motori dei condizionatori, i lucernari.
## Il peso è quanto ne capita.
const ROBA_TETTO := [
	["antenna_1", 5], ["antenna_2", 2], ["comignolo_1", 3],
	["comignolo_2", 3], ["comignolo_3", 2], ["cisterna_1", 3],
	["cisterna_2", 1], ["cisterna_3", 3], ["macchina_tetto", 4],
	["sfiato_1", 1], ["sfiato_2", 2], ["sfiato_3", 1], ["sfiato_4", 1],
	["sfiato_5", 2], ["sfiato_6", 1], ["lucernario_1", 1],
	["lucernario_2", 1],
]
## Sul tetto di una campata (tre metri e venti di profondità) ci stanno solo
## le cose strette: niente lucernari, niente cisterna grossa.
const ROBA_TETTO_STRETTO := [
	["antenna_1", 6], ["antenna_2", 2], ["comignolo_1", 4],
	["comignolo_2", 3], ["comignolo_3", 3], ["cisterna_1", 3],
	["cisterna_3", 3], ["macchina_tetto", 4], ["sfiato_1", 1],
	["sfiato_2", 2], ["sfiato_3", 1], ["sfiato_4", 1], ["sfiato_5", 2],
	["sfiato_6", 1], ["lucernario_1", 1], ["lucernario_2", 1],
]
## Sulla falda di coppi solo i comignoli: sul colmo, dove stanno davvero.
const ROBA_FALDA := [["comignolo_1", 3], ["comignolo_2", 2],
	["comignolo_3", 3]]


## La roba sul tetto di una campata, verso il retro: da giù si vede spuntare
## sopra al cornicione, che è l'unico modo in cui un tetto si vede dalla
## strada. `c` è il centro del tetto (quota compresa), `dim` le sue misure.
func _roba_sul_tetto_campata(c: Vector3, dim: Vector2, fuori: Vector3,
		rng: RandomNumberGenerator) -> void:
	if rng.randf() > 0.34:
		return
	var lungo := Vector3(fuori.z, 0.0, -fuori.x)
	var largo_l: float = dim.x if absf(fuori.z) > 0.5 else dim.y
	if largo_l < 2.4:
		return
	var nome: String = _a_sorte(ROBA_TETTO_STRETTO, rng)
	var p: Vector3 = c + lungo * rng.randf_range(-largo_l * 0.5 + 1.0,
		largo_l * 0.5 - 1.0) - fuori * 0.55
	var giro: float = atan2(fuori.x, fuori.z) + float(rng.randi_range(0, 3)) * PI * 0.5
	_panda(nome, p, giro, "tetto")


## Un comignolo sul colmo della falda.
func _comignolo_falda(faccia: Vector3, fuori: Vector3, largo: float,
		h: float, rng: RandomNumberGenerator) -> void:
	if rng.randf() > 0.3 or largo < 3.0:
		return
	var lungo := Vector3(fuori.z, 0.0, -fuori.x)
	var p: Vector3 = faccia + Vector3(0, h + 1.36, 0) - fuori * 1.6 \
		+ lungo * rng.randf_range(-largo * 0.5 + 0.8, largo * 0.5 - 0.8)
	_panda(_a_sorte(ROBA_FALDA, rng), p, atan2(fuori.x, fuori.z), "tetto")


# --- 'E balcune -------------------------------------------------------------

## Le piante dei balconi: vasi di fiori, piante di casa, grasse. Il balcone
## di ferro aveva **una** scatola verde di trentaquattro centimetri, sempre
## nello stesso punto: adesso ci stanno uno o due vasi veri, e ogni tanto
## nessuno (non tutti tengono le piante).
##
## **E i vasi pesanti ce vanno poco.** Sono più di cinquecento balconi, e
## ogni vaso sta in un gruppo che si disegna sempre tutto (la città è un
## MultiMesh per forma, non ha pezzi da spegnere). La prima prova ne ha
## messi 563 per 254 mila triangoli: la palma di casa (`pianta_casa_5`)
## da sola ne ha 2152, e da sotto un balcone al quarto piano è un ciuffo
## verde come un altro. Fuori; e le altre tre più care una volta su trenta.
## Media scesa a circa trecentotrenta triangoli per vaso.
const PIANTE_BALCONE := [
	["fiori_1", 3], ["fiori_2", 1], ["fiori_3", 3], ["fiori_4", 3],
	["fiori_5", 3], ["fiori_6", 3], ["pianta_casa_1", 1],
	["pianta_casa_2", 1], ["pianta_casa_3", 2], ["pianta_casa_4", 2],
	["pianta_casa_6", 2], ["pianta_grassa_1", 2],
	["pianta_grassa_2", 2], ["pianta_grassa_3", 1],
]


## I vasi su un balcone. `pavimento` è la quota del piano del balcone,
## `dentro` quanto sta avanti dal muro (il balcone è profondo un metro).
## Il dado viene dalla posizione: `_balcone` non ha un generatore suo, e
## lo stesso balcone deve avere sempre gli stessi vasi.
func _piante_balcone(faccia: Vector3, fuori: Vector3, lungo: Vector3,
		w: float, pavimento: float, dentro: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(faccia * 10.0 + Vector3(0, pavimento * 10.0, 0)))
	if rng.randf() < 0.25:
		return
	var quanti: int = 1 if rng.randf() < 0.55 else 2
	for k in range(quanti):
		var lato: float = (0.32 if k == 0 else -0.3) * w \
			+ rng.randf_range(-0.12, 0.12)
		var p: Vector3 = faccia + lungo * lato + fuori * dentro \
			+ Vector3(0, pavimento, 0)
		_panda(_a_sorte(PIANTE_BALCONE, rng), p, rng.randf_range(-PI, PI),
			"balcone")


# ---------------------------------------------------------------------------
# 'A collina d''o Vommero
# ---------------------------------------------------------------------------

## Finché è true, tutto quello che nasce sopra al terrapieno viene alzato.
## Si spegne mentre si costruisce il terrapieno stesso: le sue scalinate
## partono da terra e ci devono restare.
var _collina_attiva: bool = true


## Alza di cinque metri tutto quello che è già stato costruito dentro al
## rettangolo del terrapieno.
##
## È una passata sola sui figli diretti della città, e funziona perché
## quasi tutto qui dentro è un nodo piazzato in coordinate del mondo: mesh,
## alberi, panni, vetrine, murales, la gente ferma. Le scatole di collisione
## sono l'eccezione — `_solido()` mette il corpo all'origine e sposta la
## FORMA, quindi per quelle si guarda dove sta la forma, non il corpo.
##
## La alternativa sarebbe stata passare una quota a ognuna delle sessanta
## funzioni che costruiscono qualcosa. Questa è una funzione sola, e se
## domani il terrapieno si sposta non c'è niente da rincorrere.
func _alza_collina() -> void:
	for c in get_children():
		if not (c is Node3D):
			continue
		var n := c as Node3D
		var p: Vector3 = n.position
		if n is StaticBody3D or n is Area3D:
			var trovata := false
			for f in n.get_children():
				if f is CollisionShape3D:
					p = (f as CollisionShape3D).position
					trovata = true
					break
			if not trovata:
				continue
		if Collina.dentro(p.x, p.z):
			n.position.y += Collina.QUOTA


## Il terrapieno vero e proprio: il corpo di terra, i muraglioni di tufo che
## lo trattengono, il parapetto in cima e le scalinate agli imbocchi.
func _build_collina() -> void:
	_collina_attiva = false
	var x0: float = Collina.RECT[0]
	var z0: float = Collina.RECT[1]
	var x1: float = Collina.RECT[2]
	var z1: float = Collina.RECT[3]
	var w: float = x1 - x0
	var l: float = z1 - z0
	var q: float = Collina.QUOTA

	# Il corpo. La faccia superiore sta otto centimetri sotto alla quota, come
	# il piano d'asfalto della città sta sotto allo zero: così il selciato
	# alzato ci appoggia sopra invece di sfarfallarci contro.
	var terra := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(w, q + 2.0, l)
	terra.mesh = tm
	terra.position = Vector3(x0 + w / 2.0, q - 0.08 - (q + 2.0) / 2.0,
		z0 + l / 2.0)
	terra.material_override = Tex.mondo("muro_tufo", Color(0.86, 0.80, 0.68), 0.96)
	add_child(terra)

	# La faccia in cima: il tufo va bene per i fianchi tagliati, non per
	# camminarci sopra. Qui sta il lastricato chiaro del Vomero.
	var sopra := MeshInstance3D.new()
	var spm := PlaneMesh.new()
	spm.size = Vector2(w, l)
	sopra.mesh = spm
	sopra.position = Vector3(x0 + w / 2.0, q - 0.07, z0 + l / 2.0)
	sopra.material_override = Tex.mondo("basolato", Color(0.84, 0.78, 0.68), 0.9)
	add_child(sopra)

	var corpo := StaticBody3D.new()
	corpo.collision_layer = LAYER_WORLD
	corpo.collision_mask = 0
	var forma := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(w, q + 2.0, l)
	forma.shape = box
	forma.position = Vector3(x0 + w / 2.0, q - 0.02 - (q + 2.0) / 2.0,
		z0 + l / 2.0)
	corpo.add_child(forma)
	add_child(corpo)

	# I muraglioni di contenimento, uno per lato, spezzati dove ci sono le
	# scalinate. Il tufo giallo a vista è la cosa che a Napoli dice "qui si
	# sale": ogni salita del Vomero ne ha uno alto così.
	var mat_muro := Tex.mondo("muro_tufo", Color(0.92, 0.84, 0.68), 0.95)
	for lato in ["n", "s", "o", "e"]:
		var orizzontale: bool = lato == "n" or lato == "s"
		var da: float = x0 if orizzontale else z0
		var a: float = x1 if orizzontale else z1
		# Gli imbocchi di questo lato, in ordine.
		var tagli: Array = []
		for im in Collina.IMBOCCHI:
			if str(im[0]) == lato:
				tagli.append([float(im[1]) - float(im[2]) / 2.0,
					float(im[1]) + float(im[2]) / 2.0])
		tagli.sort_custom(func(p, s): return p[0] < s[0])
		var cur: float = da
		for t in tagli:
			if t[0] > cur:
				_pezzo_muraglione(lato, cur, t[0], mat_muro)
			cur = maxf(cur, t[1])
		if cur < a:
			_pezzo_muraglione(lato, cur, a, mat_muro)

	# Le scalinate. Sei rampe, una per imbocco: si scende dal terrapieno alla
	# strada di sotto in dodici gradini.
	for im in Collina.IMBOCCHI:
		_scalinata(str(im[0]), float(im[1]), float(im[2]))
	_collina_attiva = true


## Un tratto di muraglione lungo un lato, con il parapetto in cima.
func _pezzo_muraglione(lato: String, da: float, a: float,
		mat: Material) -> void:
	var q: float = Collina.QUOTA
	var lungo: float = a - da
	if lungo < 0.4:
		return
	var x0: float = Collina.RECT[0]
	var z0: float = Collina.RECT[1]
	var x1: float = Collina.RECT[2]
	var z1: float = Collina.RECT[3]
	var orizzontale: bool = lato == "n" or lato == "s"
	var centro: Vector3
	var dim: Vector3
	if orizzontale:
		var zl: float = z0 if lato == "n" else z1
		centro = Vector3(da + lungo / 2.0, q / 2.0, zl)
		dim = Vector3(lungo, q, 0.9)
	else:
		var xl: float = x0 if lato == "o" else x1
		centro = Vector3(xl, q / 2.0, da + lungo / 2.0)
		dim = Vector3(0.9, q, lungo)

	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = dim
	m.mesh = bm
	m.position = centro
	m.material_override = mat
	add_child(m)

	# Il parapetto: un cordolo di piperno alto un metro sul filo del
	# terrapieno. Serve a non caderci di sotto e a farlo leggere da lontano
	# come un belvedere invece che come un muro qualsiasi.
	var par := MeshInstance3D.new()
	var pbm := BoxMesh.new()
	pbm.size = Vector3(dim.x, 1.0, dim.z) if orizzontale \
		else Vector3(dim.x, 1.0, dim.z)
	par.mesh = pbm
	par.position = centro + Vector3(0, q / 2.0 + 0.5, 0)
	par.material_override = Tex.mondo("piperno", Color(0.86, 0.84, 0.82), 0.9)
	add_child(par)

	_solido(centro, dim)
	_solido(centro + Vector3(0, q / 2.0 + 0.5, 0),
		Vector3(dim.x, 1.0, dim.z))


## La scalinata di un imbocco.
##
## I gradini sono veri — sedici blocchi di piperno uno sull'altro — ma NON
## sono loro a reggere il personaggio. Sopra ci passa una rampa liscia
## invisibile, ed e' quella il pavimento.
##
## Il motivo e' che un CharacterBody3D di Godot non sale gli scalini: non
## esiste lo "step-up" automatico, e un'alzata di diciannove centimetri e'
## un muro verticale come un altro. Con i soli gradini solidi si restava
## incastrati al primo. Con la rampa sotto, la salita e' un piano inclinato
## a trentasette gradi (dentro ai quarantacinque che Godot considera
## camminabili) e l'occhio vede comunque i gradini, perche' la rampa ci
## passa dentro. E' il trucco piu' vecchio che c'e', e funziona sempre.
func _scalinata(lato: String, centro: float, largo: float) -> void:
	var q: float = Collina.QUOTA
	var lung: float = Collina.RAMPA
	const N := 16
	var alz: float = q / float(N)
	var ped: float = lung / float(N)
	var x0: float = Collina.RECT[0]
	var z0: float = Collina.RECT[1]
	var x1: float = Collina.RECT[2]
	var z1: float = Collina.RECT[3]
	var mat := Tex.mondo("piperno", Color(1.06, 1.04, 1.0), 0.9)

	# In alto la scalinata tocca il bordo del terrapieno; in basso arriva
	# alla strada, RAMPA metri piu' in la'.
	var alto: Vector3
	var basso: Vector3
	var lungo_z: bool = lato == "n" or lato == "s"
	match lato:
		"n":
			alto = Vector3(centro, q, z0)
			basso = Vector3(centro, 0.0, z0 - lung)
		"s":
			alto = Vector3(centro, q, z1)
			basso = Vector3(centro, 0.0, z1 + lung)
		"o":
			alto = Vector3(x0, q, centro)
			basso = Vector3(x0 - lung, 0.0, centro)
		_:
			alto = Vector3(x1, q, centro)
			basso = Vector3(x1 + lung, 0.0, centro)

	# I gradini, visibili. Ognuno e' un blocco pieno che parte da terra:
	# cosi' sotto non c'e' il vuoto e di fianco si legge il profilo.
	var passo: Vector3 = (basso - alto) / float(N)
	for i in range(N):
		var h: float = alz * float(N - i)
		var c: Vector3 = alto + passo * (float(i) + 0.5)
		var g := MeshInstance3D.new()
		var bm := BoxMesh.new()
		if lungo_z:
			bm.size = Vector3(largo, h, ped)
		else:
			bm.size = Vector3(ped, h, largo)
		g.mesh = bm
		g.position = Vector3(c.x, h / 2.0, c.z)
		g.material_override = mat
		add_child(g)

	# La rampa invisibile: un lastrone inclinato che passa dentro ai
	# gradini e sporge un poco da tutti e due i capi, cosi' non c'e' uno
	# scalino ne' in cima ne' in fondo.
	var avanti: Vector3 = (alto - basso).normalized()
	var fianco: Vector3 = Vector3(1, 0, 0) if lungo_z else Vector3(0, 0, 1)
	var su: Vector3 = avanti.cross(fianco).normalized()
	if su.y < 0.0:
		su = -su
		fianco = -fianco
	# **Sporge sulo sotto** (0.59). Prima sporgeva quaranta centimetri da
	# tutti e due i capi: in fondo finiva sotto all'asfalto, e andava bene;
	# in cima invece la lastra continuava a salire **oltre** il bordo del
	# terrapieno, e lasciava sul piano del Vomero un gradino di venticinque
	# centimetri. Chi saliva non se ne accorgeva (ci arrivava da sopra); chi
	# scendeva ci sbatteva contro come contro un muro. I passanti, adesso
	# che hanno un corpo, restavano lassù a spingere. In cima la lastra
	# finisce esattamente sul bordo, due centimetri sopra al piano.
	var lunghezza: float = (alto - basso).length() + 0.4
	var spessore := 0.6
	var mezzo: Vector3 = (alto + basso) / 2.0 - avanti * 0.2 \
		- su * (spessore / 2.0)

	var b := StaticBody3D.new()
	b.collision_layer = LAYER_WORLD
	b.collision_mask = 0
	var f := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(largo, spessore, lunghezza)
	f.shape = bx
	f.transform = Transform3D(Basis(fianco, su, avanti), mezzo)
	b.add_child(f)
	add_child(b)

	# **Sotto 'a scalinata nun se passa** (0.59). I gradini e i muretti
	# erano solo da vedere: il corpo ce l'aveva la lastra inclinata, e
	# basta. In cima, dove la lastra sta a due metri e mezzo da terra, sotto
	# ci passava un cristiano intero — e un passante che tagliava la
	# traversa ci finiva sotto, contro il muraglione, e ci restava
	# (`prova_ntuppate`). Adesso sotto alla lastra c'è il pieno: gradoni
	# solidi larghi quanto la scalinata coi suoi muretti, ognuno alto quanto
	# la lastra nel suo punto più basso meno quindici centimetri, così non
	# spuntano mai sopra al piano su cui si cammina. Il primo metro resta
	# libero: lì la lastra è bassa, e ci si sale anche di traverso.
	const GRADONI := 4
	for k in range(1, GRADONI):
		var s0: float = lung * float(k) / float(GRADONI)
		var s1: float = lung * float(k + 1) / float(GRADONI)
		var h_g: float = q * s0 / lung - 0.15
		if h_g <= 0.3:
			continue
		var cen: Vector3 = basso + (alto - basso) * ((s0 + s1) * 0.5 / lung)
		cen.y = h_g * 0.5
		var tratto: float = lung / float(GRADONI)
		# L'ultimo gradone tocca il bordo del terrapieno: lì ai lati ci sono
		# già i muraglioni, e largo quanto l'imbocco ci entra senza
		# compenetrarli (`prova_ngombri`).
		var largo_g: float = largo if k == GRADONI - 1 else largo + 0.9
		var dim_g := Vector3(largo_g, h_g, tratto) if lungo_z \
			else Vector3(tratto, h_g, largo_g)
		var sb := StaticBody3D.new()
		sb.collision_layer = LAYER_WORLD
		sb.collision_mask = 0
		var sf := CollisionShape3D.new()
		var sbx := BoxShape3D.new()
		sbx.size = dim_g
		sf.shape = sbx
		sf.position = cen
		sb.add_child(sf)
		add_child(sb)

	# I due muretti laterali, che tengono la scalinata e la fanno leggere
	# come una salita e non come una crepa nel muraglione.
	for s2 in [-1.0, 1.0]:
		var mu := MeshInstance3D.new()
		var mm := BoxMesh.new()
		var lm: float = (alto - basso).length() + 0.4
		mm.size = Vector3(0.45, q * 0.72, lm)
		mu.mesh = mm
		mu.material_override = Tex.mondo("muro_tufo", Color(0.92, 0.84, 0.68), 0.95)
		var centro_muro: Vector3 = (alto + basso) / 2.0 \
			+ fianco * s2 * (largo / 2.0 + 0.22) + su * (q * 0.36)
		mu.transform = Transform3D(Basis(fianco, su, avanti), centro_muro)
		add_child(mu)


# ---------------------------------------------------------------------------
# I cartelli
# ---------------------------------------------------------------------------

## **'E cartielle: le frecce agli incroci.**
##
## La mappa (M) dice dove sta tutto, ma una mappa la apri solo se ti sei
## gia' perso. Il cartello lavora prima: cammini, arrivi a un incrocio, e da
## come stanno girate le frecce capisci che di la' si va allo stadio senza
## fermarti a pensarci. E' il modo in cui ci si orienta in una citta' vera —
## per accumulo, camminando — e non costa un tasto.
##
## Stanno solo sugli incroci delle strade lunghe: agli incroci dei vicoli
## sarebbero rumore, e a Napoli i vicoli non hanno nemmeno il cartello col
## nome.
##
## [x, z, angolo_del_palo, [[testo, gradi_della_freccia], ...]]
## L'angolo della freccia e' quello del `rotation.y` del cartello, cioe'
## punta lungo il suo -Z: 0 = verso nord (il mare), 180 = verso sud.
const CARTELLI := [
	# **'E pale stevano 'mmiezo â strada** (0.59). Quattro di questi sei
	# pali stavano sulla riga di mezzo della strada (il Decumano a 63,5, Via
	# Marina a 95,5, la traversa del Vomero a 126): nella corsia libera, cioè
	# senza corpo, e ci si passava attraverso. Adesso stanno sul bordo, a un
	# metro dal muro, dove un palo con le frecce si pianta davvero.
	# Sul Decumano, all'incrocio con 'O Corso: e' il quadrivio centrale.
	[71.0, 66.05, 0.0, [
		["'A PIAZZA TOIA", 270.0], ["'O STADIO", 90.0],
		["MERGELLINA", 0.0], ["'O VOMMERO", 180.0]]],
	# Via Marina, all'incrocio col Corso.
	[71.0, 98.05, 0.0, [
		["'O MERCATO", 270.0], ["'A CORNETTERIA", 90.0],
		["'O VOMMERO", 180.0]]],
	# Fuori alla piazza tua, sul Decumano: da qui si torna a casa.
	[50.0, 66.05, 0.0, [["'A PIAZZA TOIA", 0.0], ["'O STADIO", 90.0]]],
	# Sul Corso, appena sotto al lungomare.
	[83.0, 20.0, 0.0, [
		["MERGELLINA", 0.0], ["'O STADIO", 90.0], ["'E QUARTIERE", 270.0]]],
	# Ai piedi della salita del Vomero.
	[108.5, 127.45, 0.0, [
		["'O VOMMERO ↑", 180.0], ["'O FERRARO", 90.0], ["VIA MARINA", 0.0]]],
	# Sul piazzale dello stadio, guardando fuori.
	[112.0, 56.0, 0.0, [
		["'A PIAZZA TOIA", 270.0], ["'O VOMMERO", 180.0]]],
]


func _build_cartelli() -> void:
	for c in CARTELLI:
		_un_cartello(Vector3(float(c[0]), 0.0, float(c[1])), c[3])


func _un_cartello(pos: Vector3, frecce: Array) -> void:
	var palo := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.055
	cm.bottom_radius = 0.075
	cm.height = 3.4
	cm.radial_segments = 8
	palo.mesh = cm
	palo.position = pos + Vector3(0, 1.7, 0)
	palo.material_override = Tex.flat(Color(0.30, 0.31, 0.33), 0.5, 0.45)
	add_child(palo)
	_solido(pos + Vector3(0, 1.2, 0), Vector3(0.22, 2.4, 0.22))
	_lontananza(palo, 90.0)

	# Le targhe: una sopra l'altra, verdi come quelle vere, ognuna girata
	# verso dove porta. La punta e' fatta ruotando un secondo pezzo: sono
	# due scatole, ma da tre metri leggi una freccia.
	var verde := Tex.flat(Color(0.10, 0.34, 0.22), 0.6)
	var y: float = 2.9
	for f in frecce:
		var testo: String = str(f[0])
		var ang: float = deg_to_rad(float(f[1]))
		var largo: float = 0.30 + float(testo.length()) * 0.115

		var targa := Node3D.new()
		targa.position = pos + Vector3(0, y, 0)
		targa.rotation.y = ang
		add_child(targa)

		var piastra := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.06, 0.30, largo)
		piastra.mesh = bm
		# La targa parte dal palo e si allunga in avanti, verso dove indica.
		piastra.position = Vector3(0, 0, -largo / 2.0 - 0.08)
		piastra.material_override = verde
		targa.add_child(piastra)

		var punta := MeshInstance3D.new()
		var pm2 := BoxMesh.new()
		pm2.size = Vector3(0.06, 0.212, 0.212)
		punta.mesh = pm2
		punta.position = Vector3(0, 0, -largo - 0.08)
		punta.rotation.x = deg_to_rad(45.0)
		punta.material_override = verde
		targa.add_child(punta)

		# La scritta, sui due lati: un cartello leggibile da una parte sola
		# e' meta' cartello.
		for lato in [-1.0, 1.0]:
			var lb := Label3D.new()
			lb.text = testo
			lb.font_size = 44
			lb.pixel_size = 0.0042
			lb.modulate = Color(0.96, 0.96, 0.92)
			lb.outline_size = 10
			lb.outline_modulate = Color(0.05, 0.14, 0.09)
			lb.position = Vector3(0.04 * lato, 0.0, -largo / 2.0 - 0.08)
			lb.rotation.y = deg_to_rad(90.0 * lato)
			lb.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			lb.double_sided = false
			targa.add_child(lb)

		_lontananza(targa, 90.0)
		y -= 0.40


# ---------------------------------------------------------------------------
# 'O fondale: quello che si vede fuori dalla mappa
# ---------------------------------------------------------------------------

## **Perche' serviva.**
##
## La citta' finisce a centonovanta metri per centosettantadue, e fino a ieri
## finiva davvero: dal belvedere, dal terrapieno del Vomero e da ogni strada
## che punta al bordo, oltre l'ultima fila di palazzi c'era il cielo che
## toccava terra. Una citta' che finisce si vede subito, e toglie il senso
## di essere dentro a un posto grande.
##
## Il fondale non e' geometria da esplorare: e' un anello di colline, di
## case lontane e di isole che sta fra i duecento e i seicento metri, non ha
## collisioni, non ha ombre e non si aggiorna mai. Costa quasi niente e
## chiude l'orizzonte da tutte le parti.
##
## La regola di tutto quello che c'e' qui dentro: **nessun dettaglio sotto
## al metro**. A trecento metri un metro e' due pixel, e mettercene di piu'
## vuol dire solo triangoli sprecati.

## Il centro da cui si misura tutto: il mezzo della citta'.
func _centro_mondo() -> Vector3:
	return Vector3(LARGHEZZA / 2.0, 0.0, PROFONDITA / 2.0)


func _build_fondale() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 90210
	_colline_lontane(rng)
	_citta_lontana(rng)
	_isole(rng)
	_navi(rng)
	_gabbiani(rng)


## Materiale da fondale: piatto, non riceve ombre, non ne fa, e non si
## illumina. A quella distanza la luce non conta — conta la foschia, e
## quella la mette l'ambiente.
func _mat_lontano(c: Color, emis: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	m.metallic = 0.0
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if emis > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emis
	elif _ciclo:
		# Tutto il fondale opaco si spegne al tramonto. Le finestre accese
		# (quelle con emissione) no: quelle sono l'unica cosa che di notte
		# ci deve stare.
		_ciclo.aggiungi_fondale(m)
	return m


## L'anello di colline. Sui tre lati di terra (levante, mezzogiorno,
## ponente) e non a settentrione, che di la' c'e' il golfo.
##
## Ogni collina e' un prisma a sei lati schiacciato — un cono con pochi
## segmenti — perche' una collina vera vista da lontano e' esattamente
## questo: una gobba con due spalle. Le sfere e i coni tondi da lontano
## sembrano palloni.
func _colline_lontane(rng: RandomNumberGenerator) -> void:
	var c := _centro_mondo()

	# **La piana.** Fra il bordo della citta' e la prima fila di colline ci
	# sono un centinaio di metri di niente, e dall'alto quel niente si vede:
	# una striscia di cielo dove dovrebbe esserci terra. Un disco grande
	# quattordici ettari, del colore della foschia, chiude il buco. Non si
	# nota mai — che e' esattamente il suo mestiere.
	var piana := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 700.0
	pm.bottom_radius = 700.0
	pm.height = 2.0
	pm.radial_segments = 24
	pm.rings = 1
	piana.mesh = pm
	piana.position = c + Vector3(0, -1.4, 0)
	piana.material_override = _mat_lontano(Color(0.50, 0.53, 0.47))
	piana.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(piana)
	var root := Node3D.new()
	root.name = "ColineLontane"
	add_child(root)
	# Tre fasce di distanza: piu' sono lontane, piu' sono chiare e azzurre.
	# E' la prospettiva aerea, ed e' l'unica cosa che da' profondita' a un
	# fondale piatto.
	# **Le tre fasce si accavallano di proposito.**
	#
	# Alla prima prova la piu' vicina era a 235 metri ed era alta come le
	# altre: da una terrazza faceva da muro e nascondeva tutto il resto. Il
	# profilo di una costa vera e' l'opposto — le gobbe vicine sono BASSE e
	# quelle lontane spuntano sopra. Cosi' si legge la profondita' anche
	# senza nebbia.
	var fasce := [
		{"r": 300.0, "h": [16.0, 30.0], "col": Color(0.42, 0.47, 0.44), "n": 30},
		{"r": 410.0, "h": [34.0, 62.0], "col": Color(0.48, 0.55, 0.60), "n": 24},
		{"r": 580.0, "h": [62.0, 118.0], "col": Color(0.58, 0.65, 0.74), "n": 18},
	]
	for f in fasce:
		var mat := _mat_lontano(Color(f["col"]))
		var n: int = int(f["n"])
		for i in range(n):
			# Solo il semicerchio di terra: da 20 a 340 gradi passando per
			# il sud. Il settore che guarda il mare resta vuoto.
			var a: float = deg_to_rad(lerpf(18.0, 342.0,
				(float(i) + rng.randf_range(0.15, 0.85)) / float(n)))
			var raggio: float = float(f["r"]) * rng.randf_range(0.86, 1.16)
			var alt: float = rng.randf_range(f["h"][0], f["h"][1])
			var largo: float = alt * rng.randf_range(2.2, 4.0)
			var m := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = largo * rng.randf_range(0.04, 0.22)
			cm.bottom_radius = largo
			cm.height = alt * 2.0
			cm.radial_segments = 7
			cm.rings = 1
			m.mesh = cm
			# Mezza sotto terra: quello che si vede e' la cima, e il
			# profilo non e' una circonferenza perfetta.
			m.position = c + Vector3(cos(a), -alt * 0.62, sin(a)) * 1.0 \
				* Vector3(raggio, 1.0, raggio)
			m.position.y = -alt * 0.55
			m.rotation.y = rng.randf_range(0.0, TAU)
			m.scale = Vector3(1.0, 1.0, rng.randf_range(0.55, 0.9))
			m.material_override = mat
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(m)


## Le case sulla collina. A Napoli il paesaggio non e' verde: e' costruito
## fin sopra, e di notte la collina si accende. Sono scatoline in MultiMesh
## — un migliaio costa una chiamata di disegno — piu' un secondo MultiMesh
## di finestre accese che il ciclo giorno/notte fa comparire al buio.
func _citta_lontana(rng: RandomNumberGenerator) -> void:
	var c := _centro_mondo()
	var cubo := BoxMesh.new()
	cubo.size = Vector3.ONE

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cubo
	var luci := MultiMesh.new()
	luci.transform_format = MultiMesh.TRANSFORM_3D
	luci.mesh = cubo

	var case: Array = []
	var finestre: Array = []
	for i in range(900):
		var a: float = deg_to_rad(rng.randf_range(16.0, 344.0))
		var raggio: float = rng.randf_range(205.0, 292.0)
		var alt: float = rng.randf_range(5.0, 14.0)
		# Piu' sei lontano dal bordo, piu' sei in alto sulla collina: e'
		# quello che fa leggere il pendio.
		var quota: float = (raggio - 205.0) * 0.12 + rng.randf_range(-2.0, 4.0)
		var p := c + Vector3(cos(a) * raggio, quota + alt / 2.0, sin(a) * raggio)
		var t := Transform3D(Basis(), p)
		t = t.rotated_local(Vector3.UP, rng.randf_range(0.0, 1.4))
		t = t.scaled_local(Vector3(rng.randf_range(5.0, 10.0), alt,
			rng.randf_range(5.0, 10.0)))
		case.append(t)
		# Una casa su tre ha una finestra accesa: un pannellino sottile
		# appiccicato alla faccia che guarda la citta'.
		if rng.randf() < 0.34:
			var verso := (c - p).normalized()
			var f := Transform3D(Basis(), p + verso * 3.6
				+ Vector3(0, rng.randf_range(-2.0, 2.0), 0))
			f = f.scaled_local(Vector3(rng.randf_range(2.5, 5.0),
				rng.randf_range(1.2, 2.6), 0.4))
			finestre.append(f)

	mm.instance_count = case.size()
	for i in case.size():
		mm.set_instance_transform(i, case[i])
	luci.instance_count = finestre.size()
	for i in finestre.size():
		luci.set_instance_transform(i, finestre[i])

	var nodo := MultiMeshInstance3D.new()
	nodo.name = "CaseLontane"
	nodo.multimesh = mm
	# Un filo piu' chiare della collina su cui stanno, come l'intonaco al
	# sole contro il verde.
	nodo.material_override = _mat_lontano(Color(0.68, 0.65, 0.61))
	nodo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(nodo)

	var nodo_luci := MultiMeshInstance3D.new()
	nodo_luci.name = "LuciLontane"
	nodo_luci.multimesh = luci
	var mat_luci := _mat_lontano(Color(1.0, 0.86, 0.55), 1.6)
	nodo_luci.material_override = mat_luci
	nodo_luci.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(nodo_luci)
	# Di giorno le finestre accese non ci sono proprio: il materiale del
	# fondale e' senza illuminazione, quindi spegnerne l'emissione non
	# servirebbe a niente — resterebbero gialle. Si nasconde il gruppo
	# intero e lo si tira fuori al tramonto.
	if _ciclo:
		_ciclo.aggiungi_notturno(nodo_luci)


## Le isole del golfo. Non sono Capri e Ischia con la forma giusta — sono
## due profili azzurri all'orizzonte, che e' esattamente quello che si vede
## da Napoli in una giornata normale.
func _isole(rng: RandomNumberGenerator) -> void:
	var c := _centro_mondo()
	var mat := _mat_lontano(Color(0.50, 0.58, 0.70))
	var profili := [
		{"pos": Vector3(-330.0, 0.0, -430.0), "n": 5, "h": 48.0, "w": 150.0},
		{"pos": Vector3(360.0, 0.0, -500.0), "n": 4, "h": 34.0, "w": 110.0},
		{"pos": Vector3(80.0, 0.0, -620.0), "n": 3, "h": 22.0, "w": 90.0},
	]
	for pr in profili:
		var base: Vector3 = c + Vector3(pr["pos"])
		for i in range(int(pr["n"])):
			var m := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			var h: float = float(pr["h"]) * rng.randf_range(0.45, 1.0)
			cm.bottom_radius = float(pr["w"]) * rng.randf_range(0.22, 0.42)
			cm.top_radius = cm.bottom_radius * rng.randf_range(0.05, 0.3)
			cm.height = h * 2.0
			cm.radial_segments = 6
			cm.rings = 1
			m.mesh = cm
			m.position = base + Vector3(
				rng.randf_range(-1.0, 1.0) * float(pr["w"]) * 0.5,
				-h * 0.52, rng.randf_range(-24.0, 24.0))
			m.rotation.y = rng.randf_range(0.0, TAU)
			m.scale = Vector3(1.0, 1.0, 0.6)
			m.material_override = mat
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(m)


## Due navi all'orizzonte. Non si muovono: a quattrocento metri il
## movimento non si vedrebbe comunque, e una nave ferma nel golfo e' la
## cosa piu' normale del mondo.
func _navi(rng: RandomNumberGenerator) -> void:
	var c := _centro_mondo()
	var mat := _mat_lontano(Color(0.72, 0.74, 0.78))
	var scuro := _mat_lontano(Color(0.40, 0.42, 0.46))
	for p in [Vector3(-150.0, 0.0, -300.0), Vector3(220.0, 0.0, -370.0)]:
		var base: Vector3 = c + p
		var scafo := MeshInstance3D.new()
		var bm := BoxMesh.new()
		var lung: float = rng.randf_range(38.0, 62.0)
		bm.size = Vector3(lung, 6.0, 9.0)
		scafo.mesh = bm
		scafo.position = base + Vector3(0, 2.0, 0)
		scafo.rotation.y = rng.randf_range(-0.5, 0.5)
		scafo.material_override = scuro
		scafo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(scafo)
		var casotto := MeshInstance3D.new()
		var cbm := BoxMesh.new()
		cbm.size = Vector3(lung * 0.3, 7.0, 7.5)
		casotto.mesh = cbm
		casotto.position = scafo.position + Vector3(0, 6.0, 0)
		casotto.rotation.y = scafo.rotation.y
		casotto.material_override = mat
		casotto.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(casotto)


## I gabbiani. Girano in tondo, alti, sopra al golfo e sopra ai tetti. Sono
## la cosa che costa meno di tutte e che fa piu' differenza: un cielo con
## qualcosa che si muove dentro non e' piu' un fondale.
func _gabbiani(rng: RandomNumberGenerator) -> void:
	var stormo := preload("res://scripts/gabbiani.gd").new()
	stormo.name = "Gabbiani"
	add_child(stormo)
	stormo.popola(_centro_mondo(), rng)


## **'O fumo d''e cammine.**
##
## Sei pennacchi di fumo sui tetti, uno per quartiere. Costano sei nodi in
## tutto e fanno una cosa che nient'altro fa: mettono qualcosa che si muove
## PIANO in cima all'inquadratura. I gabbiani danno movimento veloce, i
## panni stesi non si muovono affatto, e in mezzo mancava tutto — una città
## in cui l'unica cosa che si muove sei tu non sembra abitata.
func _build_fumo() -> void:
	var posti := [
		Vector3(31.0, 17.0, 24.0), Vector3(78.0, 19.0, 84.0),
		Vector3(20.0, 18.0, 118.0), Vector3(120.0, 20.0, 70.0),
		Vector3(124.0, 20.0, 140.0), Vector3(168.0, 15.0, 30.0),
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 4477
	for p in posti:
		var comignolo := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.55, 1.1, 0.55)
		comignolo.mesh = bm
		comignolo.position = p + Vector3(0, 0.55, 0)
		comignolo.material_override = Tex.mondo("muro_scrostato", Color(0.86, 0.80, 0.74), 0.95)
		add_child(comignolo)

		var f := CPUParticles3D.new()
		f.position = p + Vector3(0, 1.2, 0)
		f.amount = 14
		f.lifetime = 7.0
		f.speed_scale = 0.55
		f.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		f.emission_sphere_radius = 0.16
		f.direction = Vector3(0.35, 1.0, 0.15)
		f.spread = 12.0
		f.initial_velocity_min = 0.5
		f.initial_velocity_max = 1.1
		f.gravity = Vector3(0.25, 0.12, 0.1)
		f.scale_amount_min = 0.5
		f.scale_amount_max = 1.4
		# Si allarga salendo: il fumo che resta della stessa misura sembra
		# una fila di palline.
		var curva := Curve.new()
		curva.add_point(Vector2(0.0, 0.25))
		curva.add_point(Vector2(1.0, 2.6))
		f.scale_amount_curve = curva
		var grad := Gradient.new()
		grad.set_color(0, Color(0.72, 0.70, 0.68, 0.42))
		grad.set_color(1, Color(0.80, 0.80, 0.80, 0.0))
		f.color_ramp = grad
		var pm := SphereMesh.new()
		pm.radius = 0.5
		pm.height = 1.0
		pm.radial_segments = 6
		pm.rings = 3
		f.mesh = pm
		var mm := StandardMaterial3D.new()
		mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mm.vertex_color_use_as_albedo = true
		mm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		f.material_override = mm
		f.draw_order = CPUParticles3D.DRAW_ORDER_VIEW_DEPTH
		add_child(f)
		_lontananza(f, 150.0)
