extends Node
## 'O selciato bagnato: 'e materiale ce arrivano overo?
##
## La foto di confronto ha dato differenza **zero virgola tre** su
## duecentocinquantacinque, cioè niente. Ma "niente" può voler dire due
## cose molto diverse, e a occhio non si distinguono:
##
##   1. i materiali del terreno non finiscono nel registro, e `bagna()`
##      non tocca niente;
##   2. li tocca, ma sotto un cielo coperto un riflesso speculare non ha
##      niente da riflettere — e allora funziona e non si vede, che per il
##      giocatore è identico a non funzionare.
##
## Qui si separano le due: si contano i materiali registrati e si legge il
## parametro dopo la chiamata. È la stessa lezione di `prova_manella`
## della 0.54 — quando non si vede, si misura invece di indovinare.

const Tex := preload("res://scripts/textures.gd")

var storte: int = 0


func male(msg: String) -> void:
	storte += 1
	print("  STORTO: %s" % msg)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	await get_tree().process_frame

	print("=== 'O REGISTRO ===")
	var quante: int = Tex._terre.size()
	print("  %d materiale 'e terra dint'ô registro" % quante)
	if quante == 0:
		male("nisciuno materiale s'è segnato: `bagna()` nun tocca niente")
		print("=== storte: %d ===" % storte)
		get_tree().quit()
		return

	print("=== 'A CHIAMMATA ===")
	Tex.bagna(0.0)
	var asciutto: Array = _leggi()
	Tex.bagna(1.0)
	var bagnato: Array = _leggi()
	print("  asciutto: rough %.2f · spec %.2f" % [asciutto[0], asciutto[1]])
	print("  bagnato:  rough %.2f · spec %.2f" % [bagnato[0], bagnato[1]])
	if is_equal_approx(asciutto[0], bagnato[0]):
		male("'a rugosità nun se move")
	if is_equal_approx(asciutto[1], bagnato[1]):
		male("'o speculare nun se move")
	if bagnato[0] >= asciutto[0]:
		male("bagnato è cchiù ruvido 'e asciutto")

	# E chi nasce dopo che ha già cominciato a piovere deve trovarla
	# bagnata come gli altri: un pezzo di strada costruito a metà giornata
	# non può restare asciutto in mezzo al resto.
	print("=== CHI NASCE DOPPO ===")
	Tex.bagna(1.0)
	var tardi: Material = Tex.ground("asfalto", Vector2(9, 9), 6.1)
	if tardi is ShaderMaterial:
		var r: float = (tardi as ShaderMaterial).get_shader_parameter("roughness_base")
		print("  'nu pezzo 'e strada fatto mo': rough %.2f" % r)
		if r > Tex.BAGNATO_ROUGH + 0.05:
			male("'o pezzo nuovo è asciutto 'n miezo â città bagnata")
	Tex.bagna(0.0)

	print("=== storte: %d ===" % storte)
	get_tree().quit()


## `get_shader_parameter` torna **null** pe' 'nu parametro ca nisciuno ha
## maje scritto ncopp'a chillu materiale: piglia 'o valore 'e scorta d''o
## shader e nun 'o scrive. Leggerlo cu `float(...)` fa schiattà tutto — e
## chesto è successo â primma prova.
func _num(v, scorta: float) -> float:
	return scorta if v == null else float(v)


func _leggi() -> Array:
	for m in Tex._terre:
		if m is ShaderMaterial:
			var sm := m as ShaderMaterial
			return [_num(sm.get_shader_parameter("roughness_base"), 0.95),
				_num(sm.get_shader_parameter("specular_amount"), 0.16)]
	return [-1.0, -1.0]
