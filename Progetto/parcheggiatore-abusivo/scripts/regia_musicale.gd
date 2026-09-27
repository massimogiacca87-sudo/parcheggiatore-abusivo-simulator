extends Node
class_name RegiaMusicale
## RegiaMusicale
## Decide che musica va, momento per momento.
##
## Prima girava una tarantella sola, in loop, dal primo secondo all'ultimo:
## dopo tre minuti non la sentivi più, dopo dieci ti dava fastidio. Il
## problema non era il pezzo — era che la musica non diceva niente. Suonava
## uguale mentre parcheggiavi un'auto, mentre scappavi dai carabinieri e
## mentre arrivava Borrelli.
##
## Adesso ci sono sette brani e questo nodo sceglie. La regola è che la
## musica deve rispondere a due domande: *che ora è* e *che sta succedendo*.
## L'ora fa da fondo (giorno → sera → notte); quello che succede la
## interrompe (i carabinieri addosso, il boss).
##
## Due accorgimenti che contano più della lista delle regole:
##
##   1. **Isteresi.** Le condizioni entrano a una soglia ed escono a una più
##      bassa. Senza, con l'attenzione dei vigili che oscilla intorno al
##      valore critico, la musica cambierebbe ogni due secondi.
##   2. **Permanenza minima.** Un brano di sottofondo, una volta messo,
##      resta almeno dodici secondi. Le emergenze (caccia, boss) no: quelle
##      devono entrare subito, altrimenti arrivano quando è già finita.

## Ogni quanto si riguarda la situazione. Quattro volte al secondo bastano e
## costano niente.
const OGNI: float = 0.25

## Attenzione dei vigili. Non decide più la caccia (quella la decidono le
## stelle) ma serve ancora a `_emergenza()`, cioè a stabilire quando la
## radiolina del giocatore va zittita.
const HEAT_ENTRA: float = 72.0
const HEAT_ESCE: float = 48.0

## Auto in attesa: da quante in su la giornata diventa "lavoro".
const AUTO_ENTRA: int = 3
const AUTO_ESCE: int = 1

## Da che punto della giornata il sottofondo passa da "giorno" a "lavoro".
## Prima era solo il numero di auto in coda a decidere, ma con un'auto ogni
## venticinque-trenta secondi tre insieme non capitano quasi mai: il brano
## piu' vivo del mazzo non si sentiva praticamente mai.
const MEZZOGIORNO: float = 0.30

## Quanto deve restare almeno un brano di sottofondo.
const PERMANENZA: float = 12.0

## Con quanto tempo sfuma un cambio normale e uno d'emergenza.
const FADE_CALMO: float = 3.0
const FADE_SUBITO: float = 0.9

var _ciclo: Node = null
var _t: float = 0.0
var _in_caccia: bool = false
var _in_lavoro: bool = false
var _messo_da: float = 0.0
var _ultimo: String = ""


func setup(ciclo: Node) -> void:
	_ciclo = ciclo


func _ready() -> void:
	# La regia continua a ragionare anche a gioco in pausa: se metti in
	# pausa durante l'inseguimento e riprendi, la musica dev'essere ancora
	# quella dell'inseguimento.
	process_mode = Node.PROCESS_MODE_ALWAYS
	SoundManager.music_to_gameplay()
	# La permanenza minima parte gia' scaduta: la primissima scelta deve
	# poter scattare subito, altrimenti all'inizio della partita resterebbe
	# su per dodici secondi la musica del menu.
	_messo_da = PERMANENZA


func _process(delta: float) -> void:
	_messo_da += delta
	_t -= delta
	if _t > 0.0:
		return
	_t = OGNI
	_decidi()


func _decidi() -> void:
	var scelta := _quale()
	if scelta == _ultimo:
		return
	var emergenza: bool = scelta in ["boss", "caccia", "sfida"] \
		or _ultimo in ["boss", "caccia", "sfida"]
	if not emergenza and _messo_da < PERMANENZA:
		return
	_ultimo = scelta
	_messo_da = 0.0
	SoundManager.metti(scelta, FADE_SUBITO if emergenza else FADE_CALMO)


func _quale() -> String:
	if GameManager.intro_active:
		return "menu"
	# 0. **'A sfida d''o Rre** (0.64): un minuto, 'a tarantella e 'o tic tac.
	# Vince su tutto, pure sulla radiolina: è un cronometro, non un sottofondo.
	if GameManager.re_sfida_attiva:
		return "sfida"
	# **La radiolina comanda, tranne quando c'e' da scappare.**
	# Se il giocatore ha scelto un brano con la manopola, quello resta —
	# ma l'inseguimento e il boss se lo riprendono, perche' quella musica
	# li' non e' un accompagnamento, e' un avviso.
	if GameManager.radio_traccia != "" and not _emergenza():
		return GameManager.radio_traccia

	# 1. Borrelli. Quando c'è lui non c'è nient'altro.
	if GameManager.boss_phase and not GameManager.boss_defeated:
		return "boss"

	# 2. **'E stelle comandano 'a caccia, e basta lloro.**
	#
	# Prima la musica dell'inseguimento partiva col *sospetto* — un numero
	# che il giocatore non vede — e si spegneva a una soglia più bassa.
	# Risultato: partiva quando non stava succedendo niente di visibile, e
	# continuava dopo che erano già andati via. La regola del capo è secca:
	# **la musica va finché ci stanno le stelline, e si ferma quando
	# spariscono.** Le stelle sono anche l'unica cosa che il giocatore
	# legge davvero, quindi musica e schermo dicono la stessa cosa.
	#
	# L'isteresi qui non serve più: le stelle non oscillano, salgono di
	# botto e scendono a scaglioni.
	var pattuglia := not get_tree().get_nodes_in_group("carabinieri").is_empty()
	_in_caccia = GameManager.stelle > 0 or pattuglia
	if _in_caccia:
		return "caccia"

	# 3. L'ora del giorno fa da fondo. Le soglie sono le stesse del cielo,
	#    cosi' il pezzo cambia mentre cambia la luce e non dieci secondi
	#    dopo.
	var avanti: float = 0.0
	if _ciclo != null and is_instance_valid(_ciclo):
		avanti = float(_ciclo.avanzamento)
	# Le undici di sera in poi è *Blue Hour Lullaby*. "sera" e "notte" sono
	# due stati distinti che suonano lo stesso pezzo — vedi la tabella in
	# SoundManager: il giradischi sa che non deve rilanciarlo.
	if GameManager.notte or avanti >= 0.86:
		return "notte"
	if avanti >= 0.68:
		return "sera"
	# Il pezzo "lavoro" va col lavoro, e il lavoro si fa in piazza. Se stai
	# girando per la città il pomeriggio, quel pezzo suona sbagliato:
	# incalza per qualcosa che non sta succedendo. Fuori dalla zona tua
	# resta "giorno", che è la musica di uno che cammina.
	if avanti >= MEZZOGIORNO:
		return "lavoro" if GameManager.in_servizio else "giorno"

	# 4. Prima mattinata: musica tranquilla, a meno che la piazza non si
	#    riempia. Se arrivano tre auto insieme il pezzo tira su il ritmo
	#    anche se sono le quattro del pomeriggio — e questo e' l'unico
	#    pezzo di regia che risponde a quello che FA il giocatore invece
	#    che all'orologio.
	var quante := _auto_in_attesa() if GameManager.in_servizio else 0
	if quante >= AUTO_ENTRA:
		_in_lavoro = true
	elif quante <= AUTO_ESCE:
		_in_lavoro = false
	return "lavoro" if _in_lavoro else "giorno"


## Quante auto stanno aspettando qualcuno che le sistemi. Si contano solo
## quelle ancora da servire: le parcheggiate stanno lì ferme e non fanno
## ritmo.
## Vero quando la situazione comanda sulla musica: carabinieri addosso o
## Borrelli in piazza.
func _emergenza() -> bool:
	if GameManager.boss_phase or GameManager.boss_spawned:
		return true
	return GameManager.heat >= HEAT_ENTRA or GameManager.stelle > 0


func _auto_in_attesa() -> int:
	var n := 0
	for a in get_tree().get_nodes_in_group("cars"):
		if not is_instance_valid(a):
			continue
		var s = a.get("state")
		if s != null and int(s) <= 2:
			n += 1
	return n
