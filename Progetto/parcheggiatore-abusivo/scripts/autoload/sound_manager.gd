extends Node
## SoundManager (autoload)
## Tutti i suoni del gioco, generati proceduralmente (tools/gen_audio.py) e
## riprodotti da un pool di player. La musichetta di quartiere gira in loop
## anche nel menu di pausa.

const SOUND_NAMES := ["honk", "bump", "punch", "coin", "kaching", "success",
	"fail", "whistle", "steal", "pop", "door", "rev", "meow",
	# 0.61: 'o sparo vero (prima era un pugno a meta' tono) e 'o fruscio.
	"sparo",
	# Suoni registrati veri (mp3), forniti dall'autore. Hanno la precedenza
	# su quelli procedurali con lo stesso nome, se un giorno si sovrappongono.
	"moto_pass", "horn_arrivo", "horn_impaziente", "soldi", "spiccioli",
	# --- 'A robba nova: registrazioni vere da freesound ---------------
	# I nomi sono in italiano perche' li chiama il codice del gioco, e il
	# codice del gioco parla italiano.
	"fischio_vigile", "portiera", "clacson_lungo", "clacson_corto",
	"radio_polizia", "sbadiglio", "sorso_caffe", "perso", "vinto",
	"saluto", "schiarisce", "tosse", "schiocco",
	"pugno1", "pugno2", "pugno3", "pugno4", "pugno5", "pugno6",
	"moneta1", "moneta2", "monete", "monete2", "monete_tante", "mucchio",
	# --- 'A seconda infornata --------------------------------------
	"folla", "urlo", "botta", "rutto", "ruttino", "bottiglia", "sorso",
	"woosh", "saluto2", "fiatone", "cintura", "stemma", "stemmi",
	# --- 0.62: 'e suone 'e ll'interfaccia (Universal UI Soundpack di
	# Nathan Gibson, CC BY 4.0 — vedi CREDITI.txt) ---------------------
	"ui_hover", "ui_click", "ui_ok", "ui_apri", "ui_chiudi", "ui_errore",
	"ui_notifica", "ui_carta", "ui_vittoria", "ui_sblocco", "ui_missione",
	# --- 0.62: 'a robba 'e fore (Freesound CC0, tagliati da
	# `tools/prepara_esterni.py`: vedi `assets/esterni/audio/CREDITI_freesound.txt`)
	"chiavi1", "chiavi2", "chiavi_porta", "clacson_mito1", "clacson_mito2",
	"clacson_lungo2", "spiccioli2", "monete3", "monete_mano",
	"folla_arrabbiata", "motorino_passa", "vespa_motore",
	# --- 0.64: 'o pennello, 'o tic tac d''a sfida (fatti a codice da
	# `tools/genera_suoni_064.py`) ---
	"pennellata", "tic", "tac", "gong_sfida"]

## **'E variante** (0.62). Chi chiede uno di questi suoni ne riceve uno a
## caso della sua lista: il clacson di chi arriva in piazza è a volte il
## suo e a volte quello di un'Alfa MiTo registrata a Napoli, e dopo venti
## auto non è più lo stesso "pè" ripetuto. Chi chiama non cambia niente.
const VARIANTI := {
	"horn_arrivo": ["horn_arrivo", "clacson_mito1"],
	"horn_impaziente": ["horn_impaziente", "clacson_mito2", "clacson_lungo2"],
	"clacson_lungo": ["clacson_lungo", "clacson_lungo2"],
	"clacson_corto": ["clacson_corto", "clacson_mito1"],
	"moto_pass": ["moto_pass", "motorino_passa"],
	# 'O richiamo d''o committente ("Guagliò, vien' ccà!") è 'o stesso
	# suono d''o saluto ca già varia da solo (passante_3d, jurnata_vista):
	# ccà nisciuno l'aveva mai variato, e chiammava sempe "saluto".
	"saluto": ["saluto", "saluto2"],
	# 'A manciata 'e monete che si paga a mano (l'autista che paga per lo
	# scasso, 'a puntata â scopa) chiammava sempe e sulamente "monete",
	# mentre dinto 'a soldi() 'e ttre pezze giranno già da tiempo: 'e
	# facimmo girà pure ccà.
	"monete": ["monete", "monete2", "monete3"],
}
const POOL_SIZE := 18
const MASTER_OFFSET_DB := -6.0 # tutto un po' più discreto
const MUSIC_VOLUME_DB := -19.0 # sottofondo: c'è, ma non copre il gioco

## I brani. Uno per momento della giornata, più quelli che scattano quando
## succede qualcosa. Chi decide quale va suonato è RegiaMusicale: qui c'è
## solo il giradischi.
## **'E tre tracce vere.** Fino alla 0.49 erano sette pezzi generati a 8 bit
## da `tools/gen_audio.py`: servivano a non lasciare il gioco muto, ma erano
## chiptune, e un gioco ambientato in un vicolo di Napoli con la chiptune
## sopra suona come un altro gioco. Adesso il capo ha dato tre brani veri e
## sono quelli a fare il fondo:
##
##   * `base.ogg`  — *Steps of the Old Quarter*, la traccia del gioco: si
##     sente mentre cammini, mentre posteggi, mentre non succede niente;
##   * `caccia.ogg` — *Terracotta Blur*, e parte **solo** con le stelle;
##   * `notte.ogg` — *Blue Hour Lullaby*, dalle undici di sera in poi.
##
## I pezzi vecchi restano nel file per il menu, per Borrelli e per la
## radiolina: quelli non li ha rimpiazzati nessuno.
const BRANI := {
	"menu": "res://audio/musica/menu.ogg",
	# Le tre chiavi del giorno puntano tutte alla stessa traccia base. Non
	# e' pigrizia: la regia ragiona per stati, e tenere gli stati separati
	# vuol dire poterli ricolorare domani senza toccarla.
	"giorno": "res://audio/musica/base.ogg",
	"lavoro": "res://audio/musica/base.ogg",
	"sera": "res://audio/musica/notte.ogg",
	"notte": "res://audio/musica/notte.ogg",
	"caccia": "res://audio/musica/caccia.ogg",
	"boss": "res://audio/musica/boss.ogg",
	# I pezzi a 8 bit di prima, per chi li vuole sulla radiolina.
	"8bit_giorno": "res://audio/musica/giorno.ogg",
	"8bit_lavoro": "res://audio/musica/lavoro.ogg",
	"8bit_sera": "res://audio/musica/sera.ogg",
	# Registrata vera, non 8 bit: e' il brano d''a festa, e si sente
	# soltanto quando succede qualcosa (la processione, 'a partita) o
	# quando lo scegli tu sulla radiolina.
	"tarantella": "res://audio/tarantella.ogg",
	# (0.64) 'A sfida d''o Rre d''e Parcheggi: 'na tarantella a 160, fatta a
	# codice (`tools/genera_suoni_064.py`), col tic tac sopra.
	"sfida": "res://audio/musica/sfida.ogg",
}

var _streams: Dictionary = {}
var _players: Array = []
## Quando ogni player d''o pool ha 'ncignato l'ultimo suono (Time.get_ticks_msec).
## Serve solo pe' sapé, si stanno tutti occupate, qual è 'o cchiù vecchio
## 'a rubbà: senza 'sta lista, 'o pool pieno faceva sparì 'o suono nuovo
## senza dì niente (audit #4, gravità media).
var _players_da: Array[int] = []
var _music: AudioStreamPlayer
## Il secondo giradischi: mentre uno sfuma, l'altro entra. Con un solo
## player il cambio era uno stacco netto, e uno stacco netto in un gioco
## dove il tempo scorre di continuo si sente come un errore.
var _music_b: AudioStreamPlayer
var _brani: Dictionary = {}
var _brano_ora: String = ""
var _volume_base: float = MUSIC_VOLUME_DB
## 'O volume d''o brano senza 'a manopola: serve pe' ricalculà quanno se
## move 'o cursore mentre 'a musica sta già sunanno.
var _volume_base_puro: float = MUSIC_VOLUME_DB
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # la musica continua in pausa
	carica_volume()
	# Un suono può essere un mp3 registrato o un wav generato da
	# tools/gen_audio.py: vince l'mp3, così basta lasciare cadere un file
	# vero in audio/ per sostituire quello sintetico.
	for sound_name in SOUND_NAMES:
		for ext in ["ogg", "mp3", "wav"]:
			var path := "res://audio/%s.%s" % [sound_name, ext]
			if ResourceLoader.exists(path):
				_streams[sound_name] = load(path)
				break
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
		_players_da.append(0)

	for nome in BRANI:
		var path: String = BRANI[nome]
		if not ResourceLoader.exists(path):
			continue
		var stream = load(path)
		# Il loop si imposta anche qui e non solo nell'import: se un giorno
		# uno dei file venisse rifatto senza il flag, il brano finirebbe e
		# resterebbe il silenzio senza che nessuno capisca perché.
		if stream is AudioStreamOggVorbis:
			stream.loop = true
		elif stream is AudioStreamMP3:
			stream.loop = true
		_brani[nome] = stream

	_music = AudioStreamPlayer.new()
	_music.volume_db = -80.0
	add_child(_music)
	_music_b = AudioStreamPlayer.new()
	_music_b.volume_db = -80.0
	add_child(_music_b)
	_avvia_ambiente()
	metti("menu", 0.0)
	# **Ogni bottone del gioco fa rumore** (0.62). Invece di ricordarsi di
	# mettere il suono in quaranta pannelli diversi, si guarda ogni nodo che
	# entra nell'albero: se è un bottone, gli si attacca il clic (e un
	# fruscio leggerissimo quando ci passi sopra col mouse).
	get_tree().node_added.connect(_su_nodo_nuovo)


func _su_nodo_nuovo(n: Node) -> void:
	# "ui_connesso" è il segno che ci siamo già passati: con .bind() il
	# Callable di mouse_entered è sempre diverso, quindi is_connected() su
	# quello non è affidabile e un bottone tolto e rimesso nell'albero
	# (tutta l'UI qui è procedurale) rischiava il doppio fruscio.
	if n is BaseButton and not n.has_meta(&"ui_muto") and not n.has_meta(&"ui_connesso"):
		var b := n as BaseButton
		b.set_meta(&"ui_connesso", true)
		if not b.pressed.is_connected(_ui_clic):
			b.pressed.connect(_ui_clic)
		b.mouse_entered.connect(_ui_sopra.bind(b))


func _ui_clic() -> void:
	ui("ui_click")


var _ultimo_sopra: int = 0

func _ui_sopra(b: BaseButton) -> void:
	if not is_instance_valid(b) or b.disabled:
		return
	# Non più di un fruscio ogni sessanta millisecondi: passando il mouse
	# su una fila di carte, se no, è una mitragliatrice.
	var ora := Time.get_ticks_msec()
	if ora - _ultimo_sopra < 60:
		return
	_ultimo_sopra = ora
	ui("ui_hover")


## I suoni dell'interfaccia, ognuno al suo volume: sono file registrati
## pieni (picco a 0 dB) e vanno tenuti sotto al gioco.
const UI_VOLUME := {
	"ui_hover": -22.0, "ui_click": -13.0, "ui_ok": -11.0, "ui_apri": -14.0,
	"ui_chiudi": -14.0, "ui_errore": -12.0, "ui_notifica": -10.0,
	"ui_carta": -9.0, "ui_vittoria": -8.0, "ui_sblocco": -8.0,
	"ui_missione": -9.0,
}

func ui(nome: String, piu_db: float = 0.0) -> void:
	play(nome, float(UI_VOLUME.get(nome, -12.0)) + piu_db, 1.0, 0.03)


# ---------------------------------------------------------------------------
# Il giradischi
# ---------------------------------------------------------------------------

## Mette su un brano, sfumando quello di prima. Se è già quello, non fa
## niente — chi chiama può richiamarla ogni frame senza pensarci.
func metti(nome: String, fade: float = 2.5) -> void:
	if nome == _brano_ora:
		return
	if not _brani.has(nome):
		return
	# **Due stati diversi ca sonano 'o stesso pezzo nun se rilanciano.**
	# "sera" e "notte" puntano tutte e due a Blue Hour Lullaby: senza questo
	# controllo, alle undici di sera il brano riparte da capo con una
	# dissolvenza incrociata su se stesso — che si sente, ed e' un difetto
	# che nasce solo dal modo in cui e' scritta la tabella.
	if _brano_ora != "" and _brani.get(_brano_ora) == _brani[nome] \
			and _music != null and _music.playing:
		_brano_ora = nome
		return
	_brano_ora = nome

	# Si scambiano i ruoli: quello che sta suonando diventa quello che
	# sfuma, e l'altro parte da zero e sale.
	var vecchio := _music
	_music = _music_b
	_music_b = vecchio

	_music.stream = _brani[nome]
	_music.volume_db = -80.0
	_music.play()

	if _tween and _tween.is_valid():
		# 'O chain_callback ca fermava 'o player vecchio (_music_b.stop(),
		# programmato piu' sotto col chain()) sta dinto 'o tween ca stiamo
		# ammazzanno proprio mo: si nun 'o chiammammo nuje a mano, chillo
		# nun parte maje, e 'o player abbandunato resta a sunà 'o brano
		# 'e primma pe' n'ata frazione 'e secondo, sovrapponendose â
		# dissolvenza nova (emergenze ravvicinate tipo caccia -> boss).
		_tween.kill()
		_music_b.stop()
	if fade <= 0.01:
		_music.volume_db = _volume_base
		_music_b.stop()
		return
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_music, "volume_db", _volume_base, fade)
	_tween.tween_property(_music_b, "volume_db", -80.0, fade * 0.8)
	_tween.chain().tween_callback(_music_b.stop)


## Che brano sta girando adesso.
func brano() -> String:
	return _brano_ora


## Alza/abbassa la musica senza cambiare brano (il menu la vuole un po' più
## presente del gioco).
func set_music_volume(db: float) -> void:
	_volume_base_puro = db
	_volume_base = db + _db_musica()
	db = _volume_base
	if _music and _music.playing:
		if _tween and _tween.is_valid():
			# **Non la lasciamo a mezza strada.** Prima qui si faceva
			# `return` e si lasciava il tween vecchio a tirare verso il
			# volume di *prima*: chi girava la manopola durante un cambio
			# brano vedeva lo slider muoversi ma il suono no, finche' non
			# cambiava brano di nuovo. Ammazziamo il tween vecchio e ne
			# facciamo uno breve (0.2s) che porta il brano nuovo al volume
			# giusto e intanto finisce di far sparire quello vecchio,
			# senza tagliarlo di colpo.
			_tween.kill()
			_tween = create_tween()
			_tween.set_parallel(true)
			_tween.tween_property(_music, "volume_db", db, 0.2)
			_tween.tween_property(_music_b, "volume_db", -80.0, 0.2)
			_tween.chain().tween_callback(_music_b.stop)
			return
		_music.volume_db = db


func music_to_gameplay() -> void:
	set_music_volume(MUSIC_VOLUME_DB)


func music_to_menu() -> void:
	set_music_volume(MUSIC_VOLUME_DB + 6.0)
	metti("menu", 1.5)


# ---------------------------------------------------------------------------
# 'O volume
# ---------------------------------------------------------------------------
#
# **Duje manopole, e se ricordano.**
#
# Il capo: *"aggiungi delle opzioni per abbassare il volume dei suoni e
# della musica"*. Separate, perché servono a due cose diverse: la musica
# uno la spegne per ascoltare altro, gli effetti li abbassa perché il
# clacson di un motorino a tre metri è forte davvero.
#
# I due numeri stanno da 0 a 1 (che è come li pensa chi muove uno slider) e
# si convertono in decibel al momento dell'uso, perché **il volume si sente
# in decibel ma si regola in lineare**: una manopola a metà deve suonare
# "metà", e metà in decibel è −6, non −40.
#
# Zero non è "molto piano": è **muto**, e va gestito a parte — `linear_to_db(0)`
# fa meno infinito e certe piattaforme ci si offendono.
#
# E stanno in un file loro (`user://audio.cfg`), non nel salvataggio della
# partita: il volume è una preferenza di chi gioca, non un fatto del
# personaggio. Chi carica una partita vecchia non si ritrova la musica
# alzata.
const AUDIO_CFG := "user://audio.cfg"

var vol_effetti: float = 1.0
var vol_musica: float = 1.0


func _db_effetti() -> float:
	return -80.0 if vol_effetti <= 0.001 else linear_to_db(vol_effetti)


func _db_musica() -> float:
	return -80.0 if vol_musica <= 0.001 else linear_to_db(vol_musica)


func set_vol_effetti(v: float) -> void:
	vol_effetti = clampf(v, 0.0, 1.0)
	# Si 'o tappeto sta già sonanno, s'adda aggiornà mo: no' quanno cagna scena.
	if _ambiente != null and _ambiente.playing:
		ambiente(_ambiente_quanto, 0.15)
	salva_volume()


func set_vol_musica(v: float) -> void:
	vol_musica = clampf(v, 0.0, 1.0)
	# La musica sta già suonando: va aggiornata adesso, se no la manopola
	# sembra rotta finché non cambia brano.
	set_music_volume(_volume_base_puro)
	salva_volume()


func salva_volume() -> void:
	var f := FileAccess.open(AUDIO_CFG, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"effetti": vol_effetti, "musica": vol_musica}))


func carica_volume() -> void:
	if not FileAccess.file_exists(AUDIO_CFG):
		return
	var f := FileAccess.open(AUDIO_CFG, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return
	vol_effetti = clampf(float(d.get("effetti", 1.0)), 0.0, 1.0)
	vol_musica = clampf(float(d.get("musica", 1.0)), 0.0, 1.0)


## Riproduce un effetto. pitch_rand dà una leggera variazione naturale.
func play(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0, pitch_rand: float = 0.06) -> void:
	if VARIANTI.has(sound_name):
		var v: Array = VARIANTI[sound_name]
		var scelto: String = str(v[randi() % v.size()])
		if _streams.has(scelto):
			sound_name = scelto
	if not _streams.has(sound_name):
		return
	if vol_effetti <= 0.001:
		return # muto: nun se piglia manco 'nu canale d''o pool
	var ora := Time.get_ticks_msec()
	for i in range(_players.size()):
		var p: AudioStreamPlayer = _players[i]
		if not p.playing:
			p.stream = _streams[sound_name]
			p.volume_db = volume_db + MASTER_OFFSET_DB + _db_effetti()
			p.pitch_scale = pitch * randf_range(1.0 - pitch_rand, 1.0 + pitch_rand)
			p.play()
			_players_da[i] = ora
			return
	# **Pool pieno.** Prima qui si usciva senza suonare niente: nei momenti
	# affollati (rissa, folla, monete a raffica) un suono spariva nel
	# silenzio e sembrava un bug del gioco. Invece rubbammo 'o canale cchiù
	# vecchio — quello che sta suonando da più tempo — e ci mettiamo il
	# suono nuovo sopra: si sente sempre qualcosa, e quello che si interrompe
	# e' sempre il più "consumato".
	var i_vecchio := 0
	for i in range(1, _players_da.size()):
		if _players_da[i] < _players_da[i_vecchio]:
			i_vecchio = i
	var p: AudioStreamPlayer = _players[i_vecchio]
	p.stop()
	p.stream = _streams[sound_name]
	p.volume_db = volume_db + MASTER_OFFSET_DB + _db_effetti()
	p.pitch_scale = pitch * randf_range(1.0 - pitch_rand, 1.0 + pitch_rand)
	p.play()
	_players_da[i_vecchio] = ora


## Uno a caso fra tanti. Serve a non sentire tre volte identico lo stesso
## pugno: tre registrazioni diverse e nessuno se ne accorge piu'.
func play_uno(nomi: Array, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if nomi.is_empty():
		return
	play(str(nomi[randi() % nomi.size()]), volume_db, pitch)


## **Il suono dei soldi, scelto in base a quanti sono.**
##
## Prima ogni pagamento faceva lo stesso "cling", che a fine giornata
## diventava un tic. Adesso una mancia da due euro sono due monete, dieci
## euro sono una manciata, e l'incasso di un guaglione e' un mucchio che si
## versa. Non e' realismo: e' che **si sente quanto hai preso** senza
## guardare il numero in alto a destra.
func soldi(quanti: int, volume_db: float = 0.0) -> void:
	# (0.62) Tre registrazioni in più dalla biblioteca esterna: gli spiccioli
	# che cadono, la manciata in mano, le monete contate.
	var nome: String = ["moneta1", "moneta2", "spiccioli2"][randi() % 3]
	if quanti >= 60:
		nome = "mucchio"
	elif quanti >= 20:
		nome = "monete_tante" if randf() < 0.7 else "monete_mano"
	elif quanti >= 5:
		nome = ["monete", "monete2", "monete3"][randi() % 3]
	if not _streams.has(nome):
		nome = "coin"
	play(nome, volume_db)


## **'O suono ca sta a 'nu posto** (0.62). Un lettore 3D già pronto col
## suono chiesto, da appendere a chi fa rumore (il motorino che passa):
## si sente da dove viene, cresce quando si avvicina e cala quando se ne
## va. Il volume degli effetti vale anche per lui, letto adesso.
func suono_3d(nome: String, volume_db: float = 0.0, unita: float = 6.0,
		lontano: float = 60.0) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	if not _streams.has(nome):
		return p
	var s = _streams[nome]
	if nome == "vespa_motore":
		s = (s as AudioStream).duplicate()
		if s is AudioStreamOggVorbis:
			(s as AudioStreamOggVorbis).loop = true
	p.stream = s
	p.unit_size = unita
	p.max_distance = lontano
	p.volume_db = volume_db + MASTER_OFFSET_DB + _db_effetti()
	p.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_IDLE_STEP
	return p


## Il volume giusto per un lettore 3D già fatto (la manopola può essere
## cambiata nel frattempo).
func volume_3d(volume_db: float) -> float:
	return -80.0 if vol_effetti <= 0.001 else volume_db + MASTER_OFFSET_DB + _db_effetti()


## 'E sei registrazioni 'e pugne, una a caso. Sei bastano: sotto le
## quattro l'orecchio riconosce il giro, sopra le otto non se ne accorge
## piu' nessuno.
const PUGNI := ["pugno1", "pugno2", "pugno3", "pugno4", "pugno5", "pugno6"]


func pugno(volume_db: float = 0.0) -> void:
	play_uno(PUGNI, volume_db)


## Il pugno che non prende: solo l'aria. Serve a far sentire la differenza
## fra averlo dato e averlo tirato.
func vuoto(volume_db: float = -8.0) -> void:
	play("woosh", volume_db, randf_range(0.9, 1.15))


# ---------------------------------------------------------------------------
# 'O rummore d''a citta'
# ---------------------------------------------------------------------------
## **Napoli e' rumore, e questa e' la riga che lo dice.**
##
## Sotto a tutto gira un tappeto di voci vere registrate per strada. Non e'
## musica e non e' un effetto: e' il fondo su cui sta il resto, e quando
## manca il quartiere sembra spopolato anche se ci sono venti passanti a
## schermo.
##
## Sta a volume basso e **si abbassa ancora** quando si entra in casa o
## quando parte la musica dell'inseguimento: dentro al vascio la strada si
## sente ma da lontano, ed e' quello che fa sembrare la casa un dentro.
const AMBIENTE_DB: float = -22.0
var _ambiente: AudioStreamPlayer
var _ambiente_db: float = AMBIENTE_DB
var _amb_tween: Tween
var _ambiente_quanto: float = 0.0 # ll'urdemo "quanto" chiesto, pe' aggiornà 'o tappeto quanno cagna 'a manopola effetti


func _avvia_ambiente() -> void:
	var path := "res://audio/voci_napoli.ogg"
	if not ResourceLoader.exists(path):
		return
	var s = load(path)
	if s is AudioStreamOggVorbis:
		s.loop = true
	_ambiente = AudioStreamPlayer.new()
	_ambiente.stream = s
	_ambiente.volume_db = -80.0
	add_child(_ambiente)


## `quanto` da 0 (silenzio) a 1 (strada aperta). Mezzo e' "dentro casa".
func ambiente(quanto: float, fade: float = 1.2) -> void:
	if _ambiente == null:
		return
	quanto = clampf(quanto, 0.0, 1.0)
	_ambiente_quanto = quanto
	if not _ambiente.playing:
		_ambiente.play()
	# 'A manopola effetti conta pure ccà: si sta abbascio 'o tappeto adda
	# sta' zitto, no' sempe a tutto volume comme si nisciuno l'avesse toccata.
	var db: float = -80.0 if (quanto <= 0.01 or vol_effetti <= 0.001) \
		else AMBIENTE_DB + linear_to_db(quanto) + _db_effetti()
	if _amb_tween and _amb_tween.is_valid():
		_amb_tween.kill()
	if fade <= 0.01:
		_ambiente.volume_db = db
		return
	_amb_tween = create_tween()
	_amb_tween.tween_property(_ambiente, "volume_db", db, fade)
