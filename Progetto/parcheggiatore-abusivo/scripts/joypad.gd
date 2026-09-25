extends Node
class_name Joypad
## Joypad
## Sa se c'e' un controller attaccato e come si chiamano i suoi tasti.
##
## PS5 e Xbox hanno la stessa identica disposizione fisica — Godot li vede
## tutti e due attraverso la mappatura standard SDL, quindi il tasto in basso
## e' sempre il numero 0 — ma li chiamano in modo diverso: quello che su Xbox
## e' "A", su PlayStation e' la crocetta. Scrivere "premi A" a un possessore
## di DualSense e' il modo piu' rapido per confonderlo.
##
## Quindi si guarda il nome del dispositivo e si sceglie il vocabolario.
## Nessuna delle due famiglie ha bisogno di driver o di configurazione: si
## attacca il cavo (o si accoppia il bluetooth) e il gioco se ne accorge.

## Nomi dei tasti nei due dialetti, nell'ordine dei numeri di Godot.
const NOMI_PS := {
	"croce": "✕", "cerchio": "◯", "quadrato": "▢", "triangolo": "△",
	"l1": "L1", "r1": "R1", "l2": "L2", "r2": "R2", "l3": "L3", "r3": "R3",
	"start": "OPTIONS", "select": "CREATE",
}
const NOMI_XBOX := {
	"croce": "A", "cerchio": "B", "quadrato": "X", "triangolo": "Y",
	"l1": "LB", "r1": "RB", "l2": "LT", "r2": "RT", "l3": "L3", "r3": "R3",
	"start": "START", "select": "VIEW",
}

## Che tasto fa cosa. La disposizione segue le abitudini degli sparatutto:
## il tasto in basso salta, quello a sinistra interagisce, i grilletti sono
## le due azioni che si tengono premute (correre) o si martellano (menare).
const AZIONI := {
	"jump": "croce", "crouch": "cerchio", "interact": "quadrato",
	"vandalize": "triangolo", "inventory": "l1", "smoke": "r1",
	"sprint": "l2", "punch": "r2", "ui_cancel": "start",
	"fischio": "l3", "caffe": "r3", "mappa": "select",
}


## I tasti che il gioco usa davvero: bastano questi per accorgersi che uno
## sta giocando di tastiera.
const TASTI_DEL_GIOCO := [
	KEY_W, KEY_A, KEY_S, KEY_D, KEY_E, KEY_F, KEY_Q, KEY_R, KEY_X, KEY_C,
	KEY_I, KEY_SPACE, KEY_SHIFT, KEY_ESCAPE,
	KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6,
	KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_ENTER,
]

## Qual e' l'ultimo aggeggio che ha toccato: "pad" oppure "tastiera".
static var _ultimo: String = "tastiera"


## Da chiamare una volta per frame. Guarda chi si sta muovendo davvero.
##
## Non si usa `_input` perche' l'ordine con cui Godot consegna gli eventi
## ai nodi dipende da dove stanno nell'albero, e i tasti che l'interfaccia
## consuma (le frecce dei menu) non arriverebbero mai qui. Interrogare lo
## stato una volta per frame e' immune a tutto questo e costa una trentina
## di confronti.
static func aggiorna() -> void:
	for dev in Input.get_connected_joypads():
		for b in range(0, 16):
			if Input.is_joy_button_pressed(dev, b):
				_ultimo = "pad"
				return
		for ax in range(0, 6):
			if absf(Input.get_joy_axis(dev, ax)) > 0.4:
				_ultimo = "pad"
				return
	if Input.get_last_mouse_velocity().length_squared() > 1600.0 \
			or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) \
			or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_ultimo = "tastiera"
		return
	for k in TASTI_DEL_GIOCO:
		if Input.is_physical_key_pressed(k):
			_ultimo = "tastiera"
			return


## Vero se in questo momento si sta giocando col controller.
##
## Prima bastava che il pad fosse ATTACCATO perche' il gioco scrivesse i
## tasti del pad dappertutto — anche a chi il pad ce l'aveva collegato ma
## stava giocando di tastiera. Adesso conta chi ha toccato per ultimo, e i
## suggerimenti cambiano da soli passando dall'uno all'altra.
static func collegato() -> bool:
	if Input.get_connected_joypads().is_empty():
		return false
	return _ultimo == "pad"


## Vero se un controller e' fisicamente collegato, comunque si stia giocando.
static func presente() -> bool:
	return not Input.get_connected_joypads().is_empty()


## "ps" oppure "xbox". Nel dubbio, Xbox: e' la mappatura che Windows dà
## per default a quasi tutti i controller generici.
static func stile() -> String:
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		return "xbox"
	var nome := Input.get_joy_name(pads[0]).to_lower()
	for spia in ["playstation", "dualsense", "dualshock", "sony", "ps3",
			"ps4", "ps5", "wireless controller"]:
		if nome.contains(spia):
			return "ps"
	return "xbox"


## Il nome del tasto per un'azione, nel dialetto del controller attaccato.
## Ritorna "" se quell'azione sul joypad non c'e'.
static func tasto(azione: String) -> String:
	if not AZIONI.has(azione):
		return ""
	var dizionario: Dictionary = NOMI_PS if stile() == "ps" else NOMI_XBOX
	return str(dizionario.get(AZIONI[azione], ""))


## Il nome da mostrare a schermo: il tasto del joypad se ce n'e' uno
## attaccato, altrimenti quello della tastiera passato come ripiego.
static func etichetta(azione: String, tastiera: String) -> String:
	if not collegato():
		return tastiera
	var t := tasto(azione)
	return t if t != "" else tastiera


## Traduce un messaggio scritto per la tastiera nel dialetto del joypad.
##
## I suggerimenti a schermo nascono sparsi in dieci file diversi ("Premi E
## per...", "CLICCA quando il cursore...", "Scappa (SHIFT)"). Riscriverli
## tutti col tasto giusto voleva dire toccare dieci file e ricordarsi di
## rifarlo a ogni frase nuova. Invece si traduce alla fine, in un posto
## solo: le frasi restano scritte in italiano-tastiera e qui si sostituisce
## quello che cambia.
##
## Le sostituzioni sono su forme delimitate — "[E]", "(E)", "premi E" — e
## mai sulla lettera nuda, altrimenti si sfascerebbe mezza frase.
static func traduci(testo: String) -> String:
	if testo == "" or not collegato():
		return testo
	return traduci_con(NOMI_PS if stile() == "ps" else NOMI_XBOX, testo)


## Il cuore della traduzione, separato dal controllo "c'e' un pad attaccato?"
## cosi' si puo' collaudare senza avere un controller sotto mano.
static func traduci_con(d: Dictionary, testo: String) -> String:
	var t := testo

	# Il pannello della regia: con lo stick i quattro tasti non esistono piu'.
	t = t.replace("W vai · S aspetta · A/D gira",
		"Stick: avanti = vai, indietro = aspetta, lati = gira")

	var coppie := [
		["premi E", "premi " + d["quadrato"]],
		["Premi E", "Premi " + d["quadrato"]],
		["[E]", "[" + d["quadrato"] + "]"],
		["(E)", "(" + d["quadrato"] + ")"],
		["E lassa sta'", d["quadrato"] + " lassa sta'"],
		["[I]", "[" + d["l1"] + "]"],
		["[X] fuma", "[" + d["r1"] + "] fuma"],
		["[R] bevi", "[" + d["r3"] + "] bevi"],
		["[Q] fischia", "[" + d["l3"] + "] fischia"],
		["[R] pe' te ne sculà", "[" + d["r3"] + "] pe' te ne sculà"],
		["[X] per accendertene", "[" + d["r1"] + "] per accendertene"],
		["[1] tre caffè", "[croce dir.] tre caffè"],
		["Accovacciati (C)", "Accovacciati (" + d["cerchio"] + ")"],
		["(C)", "(" + d["r1"] + ")"],  # nel testo del boss "(C)" e' la sigaretta
		["F o SPAZIO", d["triangolo"]],
		["CLICCA", d["r2"]],
		["Clicca", d["r2"]],
		["clicca", d["r2"]],
		["Click sinistro", d["r2"]],
		["Click sx", d["r2"]],
		["(SHIFT)", "(" + d["l2"] + ")"],
		["SHIFT", d["l2"]],
		["SPAZIO", d["croce"]],
		["ESC", d["start"]],
		["1-6", "croce dir."],
		["1 – 6", "croce dir."],
		["premi il numero", "scegli con la croce direzionale"],
	]
	for c in coppie:
		t = t.replace(str(c[0]), str(c[1]))
	return t
