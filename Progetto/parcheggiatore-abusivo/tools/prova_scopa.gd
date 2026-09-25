extends SceneTree
## Collaudo del motore della scopa. Si lancia con:
##     godot4 --headless --path . --script tools/prova_scopa.gd
##
## Verifica due cose che non si possono controllare a occhio:
##   1. le quaranta carte tornano sempre tutte (niente carte perse o doppie);
##   2. i livelli sono davvero in scala — il più bravo deve vincere di più.

const Motore := preload("res://scripts/scopa_motore.gd")


func _init() -> void:
	seed(12345)
	_prova_integrita()
	_prova_scala()
	quit()


func _una_partita(liv_a: int, liv_b: int) -> Array:
	var m: ScopaMotore = Motore.new()
	m.nuova_partita(0)
	var giri := 0
	while not m.finita and giri < 200:
		giri += 1
		var g: int = m.turno
		var mano: Array = m.mani[g]
		if mano.is_empty():
			break
		var mossa: Dictionary
		if g == 1:
			mossa = m.mossa_ia(liv_b)
		else:
			# Il giocatore 0 lo facciamo giocare con la stessa testa,
			# scambiando le mani: e' l'unico modo di misurare la scala.
			var scambio: ScopaMotore = Motore.new()
			scambio.mazzo = m.mazzo.duplicate()
			scambio.tavolo = m.tavolo.duplicate()
			scambio.mani = [m.mani[1].duplicate(), m.mani[0].duplicate()]
			scambio.prese = [m.prese[1].duplicate(), m.prese[0].duplicate()]
			scambio.uscite = m.uscite.duplicate()
			mossa = scambio.mossa_ia(liv_a)
		if mossa.is_empty():
			break
		m.gioca(g, int(mossa["carta"]), mossa["presa"])
	var p: Dictionary = m.punteggio()
	var tot: int = m.prese[0].size() + m.prese[1].size() + m.tavolo.size() \
		+ m.mani[0].size() + m.mani[1].size() + m.mazzo.size()
	return [int(p["punti"][0]), int(p["punti"][1]), tot, giri]


func _prova_integrita() -> void:
	var male := 0
	for i in range(300):
		var r: Array = _una_partita(2, 2)
		if int(r[2]) != 40:
			male += 1
		if int(r[3]) >= 200:
			male += 1
	print("integrita': %d partite storte su 300" % male)


func _prova_scala() -> void:
	print("--- 'a scala d''e viecchie (300 partite pe' coppia) ---")
	for liv in range(5):
		var vinte := 0
		var pari := 0
		for i in range(300):
			var r: Array = _una_partita(0, liv)   # 0 = 'o fesso, contro liv
			if int(r[1]) > int(r[0]):
				vinte += 1
			elif int(r[1]) == int(r[0]):
				pari += 1
		print("  livello %d contro 'o livello 0: vince 'o %d%% (%d pari)"
			% [liv, int(round(float(vinte) * 100.0 / 300.0)), pari])
	print("--- e uno contro ll'atu (300 partite) ---")
	for coppia in [[1, 2], [2, 3], [3, 4], [1, 4]]:
		var vinte2 := 0
		var pari2 := 0
		for i in range(300):
			var r2: Array = _una_partita(int(coppia[0]), int(coppia[1]))
			if int(r2[1]) > int(r2[0]):
				vinte2 += 1
			elif int(r2[1]) == int(r2[0]):
				pari2 += 1
		print("  %d contro %d: 'o cchiu' auto vince 'o %d%% (%d pari)"
			% [coppia[0], coppia[1], int(round(float(vinte2) * 100.0 / 300.0)), pari2])
