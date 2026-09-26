extends Node3D
## Motorino di passaggio
## Uno scooter che sfreccia lungo una strada del quartiere, con due sopra e
## nessun casco. Arriva da un capo, passa, esce dall'altro, e torna dopo un
## po' — magari nell'altro senso.
##
## È diverso dal motorino della piazza, che punta te: questo passa e basta.
## Serve a far sentire che le strade sono strade — il rumore che si
## avvicina e si allontana fa più città di dieci palazzi. Se però ti trovi
## in mezzo alla carreggiata non frena, perché non frena nessuno.

const Models := preload("res://scripts/models.gd")
const Human := preload("res://scripts/human_builder.gd")
const Tex := preload("res://scripts/textures.gd")

const VELOCITA_MIN: float = 9.0
const VELOCITA_MAX: float = 14.0
const RAGGIO_INVESTIMENTO: float = 1.5
## Sceso da ventidue a sette: farsi mettere sotto per strada e' un
## incidente, non una punizione.
const DANNO: float = 7.0

var partenza: Vector3 = Vector3.ZERO
var arrivo: Vector3 = Vector3.ZERO

var _mezzo: Node3D
var _velocita: float = 11.0
var _t: float = 0.0
var _attesa: float = 0.0
var _suonato: bool = false
var _colpito: bool = false
var _motore: AudioStreamPlayer3D = null


func _ready() -> void:
	add_to_group("motorini_citta")
	_costruisci()
	_riparti(randf_range(0.0, 12.0))


func _costruisci() -> void:
	_mezzo = Node3D.new()
	add_child(_mezzo)
	# (0.62) Uno su tre è la Vespa della biblioteca esterna: ha l'origine a
	# mezz'altezza, e si alza di quanto sta sotto.
	var nome_mezzo: String = "vespa" if randi() % 3 == 0 and Models.has_model("vespa") \
		else "motorino"
	var vespa := Models.spawn_by_length(nome_mezzo, 1.85)
	if vespa != null and nome_mezzo == "vespa":
		vespa.position.y = -Models._aabb_of(vespa).position.y * vespa.scale.y
	if vespa != null:
		Models.tint(vespa, ["body", "scooter", "paint", "carrozzeria"],
			[Color(0.72, 0.72, 0.7), Color(0.2, 0.3, 0.5),
			Color(0.7, 0.25, 0.2), Color(0.25, 0.4, 0.28)][randi() % 4],
			0.35, 0.35)
		_mezzo.add_child(vespa)

	# **'O rummore ca passa** (0.62): il motore gira in ciclo attaccato al
	# mezzo, in 3D. Prima c'era un "passaggio" registrato suonato a tutto
	# schermo nel momento in cui il motorino partiva, anche a cento metri e
	# dietro sei palazzi.
	_motore = SoundManager.suono_3d("vespa_motore", -3.0, 5.0, 55.0)
	_motore.name = "Motore"
	_mezzo.add_child(_motore)
	_motore.position = Vector3(0, 0.5, 0)

	# Due ncopp'â Vespa, assettate overo (vedi `HumanBuilder.in_sella`):
	# prima stavano in croce, piegati a mano su ossa che non esistevano più.
	for i in range(2):
		var parts := Human.in_sella(
			[Color(0.85, 0.3, 0.25), Color(0.2, 0.35, 0.6),
			Color(0.9, 0.85, 0.4)][randi() % 3],
			Color(0.2, 0.22, 0.3), randf_range(1.62, 1.74),
			0.86 + i * 0.01, 0.12 + i * 0.30, {"bald": false})
		_mezzo.add_child(parts["root"])


func _riparti(fra: float) -> void:
	_attesa = fra
	_t = 0.0
	_suonato = false
	_colpito = false
	_velocita = randf_range(VELOCITA_MIN, VELOCITA_MAX)
	if _mezzo:
		_mezzo.visible = false
	if _motore != null:
		_motore.stop()


func _process(delta: float) -> void:
	if _attesa > 0.0:
		_attesa -= delta
		if _attesa <= 0.0 and _mezzo:
			_mezzo.visible = true
			if _motore != null and _motore.stream != null:
				_motore.volume_db = SoundManager.volume_3d(-3.0)
				_motore.pitch_scale = randf_range(0.92, 1.12) * _velocita / 11.0
				_motore.play(randf_range(0.0, 2.0))
		return

	var tratta: Vector3 = arrivo - partenza
	var lung: float = tratta.length()
	if lung < 1.0:
		return
	_t += _velocita * delta / lung
	if _t >= 1.0:
		if randf() < 0.5:
			var tmp := partenza
			partenza = arrivo
			arrivo = tmp
		_riparti(randf_range(9.0, 26.0))
		return

	var pos: Vector3 = partenza.lerp(arrivo, _t)
	_mezzo.position = pos - global_position
	var dir: Vector3 = tratta.normalized()
	# forward(θ) = (−sinθ, 0, −cosθ): θ = atan2(−dir.x, −dir.z).
	_mezzo.rotation.y = atan2(-dir.x, -dir.z)
	_mezzo.rotation.z = sin(_t * lung * 1.6) * 0.035

	var pl := get_tree().get_first_node_in_group("player")
	if pl == null or not is_instance_valid(pl) or _colpito:
		return
	var d: Vector3 = pl.global_position - pos
	d.y = 0.0
	if d.length() < 14.0 and not _suonato:
		_suonato = true
		SoundManager.play("horn_impaziente", -8.0, 1.25)
	if d.length() < RAGGIO_INVESTIMENTO:
		_colpito = true
		SoundManager.play("bump", -1.0, 0.75)
		GameManager.screen_shake.emit(0.8)
		GameManager.damage_player(DANNO,
			"T'ha pigliato 'nu motorino 'n copp''a strada", global_position)
		if pl.has_method("knock_down"):
			pl.knock_down(dir)
