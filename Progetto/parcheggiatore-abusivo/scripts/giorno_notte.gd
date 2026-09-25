extends Node
class_name GiornoNotte
## GiornoNotte
## Il turno non è più un cronometro: è una giornata che finisce.
##
## Si parte col sole alto e in dieci minuti reali cala la notte — il sole
## scende, il cielo passa dall'azzurro all'arancio al blu scuro, la foschia
## si fa fredda, i lampioni si accendono da soli. Poi, fra i trenta e i
## sessanta secondi dopo che è buio, arriva Borrelli.
##
## Perché a tempo reale e non a "punti turno": così l'ora del giorno è una
## cosa che si *vede*, e il giocatore capisce quanto gli resta guardando il
## cielo invece di leggere un numero nell'angolo. E l'arrivo del boss smette
## di essere una scadenza: diventa il buio che se lo porta dietro.
##
## Il tempo scorre solo mentre il turno è attivo (in pausa no) e si ferma
## durante lo scontro finale, come già faceva il cronometro.

## Quanto ci mette a farsi notte, in secondi reali.
##
## Erano dieci minuti, poi sette, e ancora erano troppi: la notte — che e'
## il pezzo piu' bello, e adesso pure quello dove rendono le luminarie —
## arrivava quando uno stava gia' per smettere. Quattro minuti e mezzo
## fanno passare tutte e cinque le fasi del cielo dentro a una partita che
## si gioca in una sola sessione, e lasciano un pezzo di notte vera in
## fondo al turno invece di un accenno.
## **Adesso la giornata e' la giornata.** Il ciclo del cielo e il
## cronometro del turno sono lo stesso orologio: si apre gli occhi a
## mezzogiorno e si va avanti fino alle quattro del mattino, sedici ore
## di quartiere in sette minuti e mezzo di gioco. Prima erano due tempi
## diversi che andavano ognuno per conto suo, e capitava di vedere il
## tramonto con mezzo turno ancora davanti.
const Tex := preload("res://scripts/textures.gd")

const DURATA_GIORNO: float = 450.0
## Le tappe della giornata, come frazione di DURATA_GIORNO.
## Le soglie sono ricalcolate sulle sedici ore: il pomeriggio comincia
## alle 15, il tramonto alle 19:30, il crepuscolo alle 21, e dalle 22 in
## poi e' notte piena — che e' la meta' della giornata, ed e' giusto
## cosi': un parcheggiatore lavora quando esce la gente.
const T_POMERIGGIO := 0.19   # 15:00
const T_TRAMONTO := 0.47     # 19:30
const T_CREPUSCOLO := 0.56   # 21:00
const T_NOTTE := 0.63        # 22:05 — da qui in poi non cambia piu' niente

## Quando è notte, il boss arriva dopo un'attesa in questo intervallo.
const BOSS_DOPO_MIN: float = 22.0
const BOSS_DOPO_MAX: float = 42.0

signal fase_cambiata(nome: String)
signal notte_calata()

## 0 = mezzogiorno pieno, 1 = notte fonda.
var avanzamento: float = 0.0
var e_notte: bool = false

var _sole: DirectionalLight3D
var _rimbalzo: DirectionalLight3D
var _env: Environment
var _cielo: ShaderMaterial
var _lampioni: Array = []
var _fase := ""
var _luna: DirectionalLight3D

# --- I colori delle quattro tappe --------------------------------------
# [sole, energia sole, cielo alto, cielo orizzonte, ambientale, foschia,
#  energia ambientale]
const TAPPE := [
	{ # mezzogiorno
		"sole": Color(1.0, 0.96, 0.88), "energia": 1.15,
		"alto": Color(0.18, 0.42, 0.78), "orizzonte": Color(0.78, 0.82, 0.85),
		"ambiente": Color(0.88, 0.86, 0.86), "amb_energia": 0.52,
		"foschia": Color(0.88, 0.86, 0.80), "altezza_sole": -52.0,
	},
	{ # pomeriggio inoltrato
		"sole": Color(1.0, 0.90, 0.72), "energia": 1.05,
		"alto": Color(0.20, 0.44, 0.76), "orizzonte": Color(0.88, 0.80, 0.70),
		"ambiente": Color(0.92, 0.86, 0.80), "amb_energia": 0.50,
		"foschia": Color(0.92, 0.84, 0.72), "altezza_sole": -26.0,
	},
	{ # tramonto
		"sole": Color(1.0, 0.62, 0.34), "energia": 0.85,
		"alto": Color(0.22, 0.36, 0.62), "orizzonte": Color(0.98, 0.58, 0.32),
		"ambiente": Color(0.72, 0.56, 0.52), "amb_energia": 0.40,
		"foschia": Color(0.95, 0.66, 0.44), "altezza_sole": -6.0,
	},
	{ # crepuscolo
		"sole": Color(0.52, 0.44, 0.62), "energia": 0.30,
		"alto": Color(0.09, 0.13, 0.30), "orizzonte": Color(0.36, 0.28, 0.42),
		"ambiente": Color(0.30, 0.32, 0.48), "amb_energia": 0.32,
		"foschia": Color(0.34, 0.32, 0.42), "altezza_sole": 4.0,
	},
	{ # notte
		"sole": Color(0.42, 0.48, 0.72), "energia": 0.10,
		"alto": Color(0.03, 0.04, 0.11), "orizzonte": Color(0.07, 0.09, 0.20),
		"ambiente": Color(0.16, 0.19, 0.34), "amb_energia": 0.26,
		"foschia": Color(0.10, 0.12, 0.22), "altezza_sole": 14.0,
	},
]

const NOMI_FASE := ["Miezojuorno", "Doppopranzo", "Tramonto", "Ammesurata", "Notte"]


func setup(sole: DirectionalLight3D, rimbalzo: DirectionalLight3D,
		env: Environment, cielo: ShaderMaterial) -> void:
	_sole = sole
	_rimbalzo = rimbalzo
	_env = env
	_cielo = cielo
	# La luna: una seconda luce fredda che si accende solo di notte, così il
	# buio non è nero pesto e le sagome restano leggibili.
	_luna = DirectionalLight3D.new()
	_luna.rotation_degrees = Vector3(-58.0, 62.0, 0.0)
	_luna.light_color = Color(0.62, 0.72, 1.0)
	_luna.light_energy = 0.0
	_luna.shadow_enabled = false
	add_child(_luna)
	_applica(0.0)


## Roba che esiste solo di notte: le finestre accese delle case lontane,
## le insegne. Non e' un lampione — non ha una luce, ha solo una sagoma che
## di giorno non ci deve stare. Registrarla come lampione non bastava:
## il materiale del fondale e' senza illuminazione, quindi l'emissione non
## lo tocca e le finestre restavano gialle anche a mezzogiorno.
var _notturni: Array = []


## Il fondale lontano: colline, case, isole, navi. Sono materiali senza
## illuminazione — a quattrocento metri la luce diretta non conta e la
## foschia fa tutto — ma proprio per questo di notte restavano accesi come
## a mezzogiorno: una collina verde brillante sotto un cielo stellato.
##
## Qui si tiene il colore di giorno di ognuno e lo si spegne a mano quando
## cala il buio, virando verso il blu della notte.
var _fondali: Array = []


func aggiungi_fondale(mat: StandardMaterial3D) -> void:
	_fondali.append({"mat": mat, "giorno": mat.albedo_color})


func aggiungi_notturno(nodo: Node3D) -> void:
	_notturni.append(nodo)
	nodo.visible = false


## I lampioni si registrano da soli: di giorno spenti, di notte accesi.
func aggiungi_lampione(luce: Light3D, lampada: GeometryInstance3D) -> void:
	_lampioni.append({"luce": luce, "lampada": lampada,
		"energia": luce.light_energy})


## **'O cielo nun conta cchiù 'o tiempo: 'o legge.**
##
## Qui c'era `avanzamento += delta / DURATA_GIORNO`, cioè un secondo
## orologio che girava in parallelo a quello del turno. Due orologi che
## misurano la stessa cosa senza parlarsi si separano al primo intoppo, e
## una volta separati non tornano più in pari da soli: il cielo diceva
## un'ora e il numero nell'angolo un'altra.
##
## Adesso c'è una sorgente sola — `GameManager.avanzamento_giornata()` — e
## questo nodo la **specchia**. Non può più sbagliare, perché non sta più
## contando niente: se il turno si ferma si ferma il cielo, se il turno
## salta avanti salta avanti il cielo, e l'orologio dell'interfaccia legge
## lo stesso numero.
##
## `DURATA_GIORNO` resta scritta qui sopra come promemoria di quanto dura
## una giornata, ma non la usa più nessuno per contare: chi decide è
## `GameManager.shift_duration`.
func _process(_delta: float) -> void:
	var t: float = GameManager.avanzamento_giornata()
	# Un centesimo di tolleranza: rifare il cielo a ogni fotogramma per una
	# differenza invisibile costa e non serve.
	if absf(t - avanzamento) < 0.0004 and avanzamento > 0.0:
		return
	avanzamento = t
	_applica(avanzamento)
	if avanzamento >= T_NOTTE and not e_notte:
		e_notte = true
		GameManager.notte = true
		notte_calata.emit()
	elif avanzamento < T_NOTTE and e_notte:
		# Serve al giorno dopo: la giornata riparte da mezzogiorno e la
		# notte va disinnescata, se no resta notte per sempre.
		e_notte = false
		GameManager.notte = false


## Traduce l'avanzamento in luci, cielo e foschia interpolando fra le tappe.
func _applica(t: float) -> void:
	var soglie := [0.0, T_POMERIGGIO, T_TRAMONTO, T_CREPUSCOLO, T_NOTTE]
	var i := 0
	while i < soglie.size() - 2 and t > soglie[i + 1]:
		i += 1
	var da: Dictionary = TAPPE[i]
	var a: Dictionary = TAPPE[i + 1]
	var span: float = maxf(soglie[i + 1] - soglie[i], 0.0001)
	var k: float = clampf((t - soglie[i]) / span, 0.0, 1.0)
	# Curva morbida: le transizioni non partono e non finiscono di scatto.
	k = k * k * (3.0 - 2.0 * k)

	# **'O cielo 'e chiuvete (0.53).**
	#
	# La giornata di pioggia cambiava quattro moltiplicatori e non un
	# pixel: uno leggeva il biglietto, usciva, e trovava il sole. Adesso
	# il ciclo del cielo passa da un filtro: il sole si spegne a un terzo
	# e si sbianca, l'ambiente diventa grigio-azzurro, la foschia si
	# alza. Non è un cielo nuovo — sono le stesse cinque tappe, tirate
	# verso il grigio — e per questo funziona a tutte le ore, tramonto
	# compreso.
	# Quanto è notte, da 0 (giorno pieno) a 1 (buio fatto). Si contava
	# dentro al blocco del cielo; adesso serve anche alla pioggia, che
	# **non deve schiarire la notte** (vedi sotto).
	var buio: float = clampf((t - T_TRAMONTO)
		/ maxf(1.0 - T_TRAMONTO, 0.0001), 0.0, 1.0)
	var chiove: bool = GameManager.tipo_giornata == "pioggia"

	# **E 'o selciato se bagna** (0.55). Era la prima riga del "quello ca
	# ancora nun va" da due versioni, e stava lì perché sembrava un lavoro
	# grosso — i materiali del terreno li assegnano nove chiamate sparse in
	# quattro file. Ma passano **tutte** da `Tex.mondo()`, che li mette in
	# cache: sono cinque oggetti condivisi, non novecento. Da qui si
	# toccano tutti insieme, e non costa niente.
	Tex.bagna(1.0 if chiove else 0.0)

	if _sole:
		_sole.light_color = Color(da["sole"]).lerp(a["sole"], k)
		_sole.light_energy = lerpf(da["energia"], a["energia"], k)
		if chiove:
			_sole.light_color = _sole.light_color.lerp(
				Color(0.72, 0.76, 0.84), 0.7)
			_sole.light_energy *= 0.34
		_sole.rotation_degrees.x = lerpf(
			da["altezza_sole"], a["altezza_sole"], k)
		# Sotto l'orizzonte il sole non illumina più niente.
		if _sole.rotation_degrees.x > 0.0:
			_sole.light_energy *= maxf(0.0, 1.0 - _sole.rotation_degrees.x / 12.0)
		_sole.visible = _sole.light_energy > 0.01
	if _luna:
		# La luna sale mentre il sole scende.
		_luna.light_energy = lerpf(0.0, 0.30, clampf((t - T_TRAMONTO) /
			maxf(1.0 - T_TRAMONTO, 0.0001), 0.0, 1.0))
		_luna.visible = _luna.light_energy > 0.01
	if _rimbalzo:
		_rimbalzo.light_energy = lerpf(0.28, 0.05,
			clampf(t / T_CREPUSCOLO, 0.0, 1.0))

	if _cielo:
		var alto := Color(da["alto"]).lerp(a["alto"], k)
		var orizz := Color(da["orizzonte"]).lerp(a["orizzonte"], k)
		_cielo.set_shader_parameter("col_zenit", alto)
		# La tinta di mezzo non sta nelle tappe: e' la media pesata delle
		# altre due, spostata verso l'alto. Tenerla come terzo colore da
		# interpolare avrebbe voluto dire riscrivere tutte e cinque le
		# tappe per una cosa che si ricava.
		_cielo.set_shader_parameter("col_cielo", alto.lerp(orizz, 0.45))
		_cielo.set_shader_parameter("col_orizzonte", orizz)
		# Non "il cielo scurito": la caligine dell'orizzonte spenta e
		# desaturata. Sotto la linea dell'orizzonte ci va la distanza, non
		# un prato.
		_cielo.set_shader_parameter("col_terra",
			orizz.lerp(Color(0.44, 0.46, 0.48), 0.55).darkened(0.12))
		# Quanto e' notte: da qui il cielo accende le stelle e spegne le
		# nuvole da solo. (Si conta piu' sopra: serve anche alla pioggia.)
		_cielo.set_shader_parameter("notte", buio)
		# Al tramonto le nuvole si diradano e si marcano: poche, ma
		# infuocate. E' il cielo che fa piu' Napoli di tutti.
		# Con la pioggia il cielo si chiude: copertura quasi piena e nuvole
		# fitte. E' la stessa manopola di sempre, girata fino in fondo.
		_cielo.set_shader_parameter("nuvole_copertura",
			lerpf(0.94, 0.80, buio) if chiove else lerpf(0.42, 0.26, buio))
		_cielo.set_shader_parameter("nuvole_densita",
			2.1 if chiove else lerpf(1.0, 1.35, buio))
	if _env:
		_env.ambient_light_color = Color(da["ambiente"]).lerp(a["ambiente"], k)
		_env.ambient_light_energy = lerpf(
			da["amb_energia"], a["amb_energia"], k)
		_env.fog_light_color = Color(da["foschia"]).lerp(a["foschia"], k)
		if chiove:
			# L'ambiente vira al grigio-azzurro e sale: con la pioggia la
			# luce non viene piu' da una parte sola, viene da tutto il
			# cielo. E la foschia si alza, che e' come si vede la pioggia
			# da lontano — le case in fondo alla via si sbiadiscono.
			# **E 'e notte se scura, nun se schiara.**
			#
			# Questo blocco valeva uguale a tutte le ore: il grigio-azzurro
			# al 62% e l'energia per 1,22. Di giorno è giusto — con la
			# pioggia la luce viene da tutto il cielo invece che da una
			# parte sola. Di notte è il contrario esatto: una notte di
			# pioggia è **più scura** di una notte serena, perché le nuvole
			# tolgono pure la luna. In foto si vedeva benissimo — alle
			# nove di sera sotto l'acqua sembrava mezzogiorno nuvoloso,
			# mentre la stessa ora asciutta era notte fatta.
			#
			# Ci è voluta una foto di confronto per accorgersene: dentro al
			# gioco si vede una scena sola per volta, e "oggi è chiaro"
			# non sembra un difetto — sembra il tempo.
			var giorno: float = 1.0 - buio
			_env.ambient_light_color = _env.ambient_light_color.lerp(
				Color(0.60, 0.66, 0.74), 0.62 * giorno)
			_env.ambient_light_energy *= lerpf(0.62, 1.22, giorno)
			_env.fog_light_color = _env.fog_light_color.lerp(
				Color(0.58, 0.62, 0.68), 0.68)
			if "fog_density" in _env:
				_env.fog_density = maxf(_env.fog_density, 0.016)
		# Di notte il bagliore delle insegne conta di più.
		_env.glow_intensity = lerpf(0.30, 0.62, clampf(
			(t - T_TRAMONTO) / maxf(1.0 - T_TRAMONTO, 0.0001), 0.0, 1.0))

	# I lampioni si accendono un po' prima del buio pieno, come in strada.
	var acceso: float = clampf((t - T_TRAMONTO + 0.06) /
		maxf(T_CREPUSCOLO - T_TRAMONTO, 0.0001), 0.0, 1.0)
	for l in _lampioni:
		if not is_instance_valid(l["luce"]):
			continue
		l["luce"].light_energy = l["energia"] * acceso
		l["luce"].visible = acceso > 0.02
		if is_instance_valid(l["lampada"]):
			var mat = l["lampada"].get("material_override")
			if mat is StandardMaterial3D:
				mat.emission_energy_multiplier = 0.2 + acceso * 2.6

	for n in _notturni:
		if is_instance_valid(n):
			n.visible = acceso > 0.15
	# Il fondale si spegne insieme ai lampioni, ma non a zero: un profilo
	# nero su cielo nero non e' una notte, e' un buco. Resta un sedici per
	# cento virato al blu, che e' quanto si vede davvero di una collina al
	# buio.
	var notturno := Color(0.10, 0.13, 0.24)
	for f in _fondali:
		var m: StandardMaterial3D = f["mat"]
		if m == null:
			continue
		m.albedo_color = Color(f["giorno"]).lerp(notturno, acceso * 0.86)

	var nome: String = NOMI_FASE[mini(i + (1 if k > 0.5 else 0),
		NOMI_FASE.size() - 1)]
	if nome != _fase:
		_fase = nome
		fase_cambiata.emit(nome)


## Che ora è, per l'orologio dell'interfaccia. Il turno comincia alle 15:30
## e finisce a notte fatta.
func orario() -> String:
	# Le stesse sedici ore che conta il GameManager: si legge da lì, così
	# l'orologio non può dire un'ora diversa da quella del turno nemmeno
	# per un fotogramma.
	var minuti_totali: float = 12.0 * 60.0 \
		+ GameManager.avanzamento_giornata() * GameManager.ORE_DI_GIORNATA * 60.0
	var ore := int(minuti_totali / 60.0) % 24
	var minuti := int(minuti_totali) % 60
	return "%02d:%02d" % [ore, minuti]
