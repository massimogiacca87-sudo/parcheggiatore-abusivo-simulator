extends Node
## 'E ghiornate speciale: 'a partita, 'a pioggia, 'o mercato, 'a
## prucessione, 'o primmo d''o mese.
##
## Una giornata speciale è una **sesta riga della tabella delle fasce**:
## due moltiplicatori che si moltiplicano a quelli dell'ora. Quindi le
## cose da dimostrare non sono "esiste il mercato", sono:
##
##   1. **'a primma jurnata è sempe normale** — al giorno uno il gioco
##      insegna come si sta in piazza, e una processione lì insegnerebbe
##      le regole sbagliate;
##   2. **'e ghiornate speciale escono, ma nun tutt''e juorne** — una su
##      tre circa: se uscissero sempre non sarebbero speciali, se non
##      uscissero mai il sistema non esisterebbe;
##   3. **'e ddoje tabelle se mutiplicano overo** — l'attesa di una
##      giornata di mercato a mezzanotte dev'essere il prodotto dei due
##      numeri, non uno dei due;
##   4. **ogni jurnata cagna 'o gioco 'n mode differente** — se due
##      giornate avessero gli stessi quattro numeri sarebbero la stessa
##      giornata con due nomi;
##   5. **'o biglietto 'a porta 'o ddice** — ogni giornata ha la sua riga,
##      e nessuna è vuota: il biglietto è tutto il motivo per cui una
##      giornata speciale è una decisione invece di una sorpresa.

var _male: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame

	print("=== 'E GHIORNATE ===")
	print("  %-24s %-7s %-7s %-7s %-7s" % ["quale", "arrivi", "mancia",
		"gente", "multe"])
	for g in GameManager.GIURNATE:
		print("  %-24s %-7.2f %-7.2f %-7.2f %-7.2f" % [str(g["id"]),
			float(g["arrivi"]), float(g["mancia"]), float(g["gente"]),
			float(g["multe"])])
		_verifica("  %s tene 'o biglietto" % str(g["id"]),
			str(g["biglietto"]).strip_edges() != "")

	# Nessuna giornata uguale a un'altra: se due righe hanno gli stessi
	# quattro numeri, sono la stessa giornata con due nomi.
	var uguali := 0
	for i in range(GameManager.GIURNATE.size()):
		for j in range(i + 1, GameManager.GIURNATE.size()):
			var a: Dictionary = GameManager.GIURNATE[i]
			var b: Dictionary = GameManager.GIURNATE[j]
			if float(a["arrivi"]) == float(b["arrivi"]) \
					and float(a["mancia"]) == float(b["mancia"]) \
					and float(a["gente"]) == float(b["gente"]) \
					and float(a["multe"]) == float(b["multe"]):
				uguali += 1
	_verifica("nisciuna jurnata è 'a copia 'e n'ata", uguali == 0)

	# --- Chi esce, e quanto spesso --------------------------------------
	print("=== CHI ESCE ===")
	GameManager.giornata = 1
	var normali_ô_juorno_uno := 0
	for i in range(200):
		GameManager.prepara_giornata()
		if GameManager.tipo_giornata == "normale":
			normali_ô_juorno_uno += 1
	_verifica("'o juorno uno è sempe normale (%d ncopp'a 200)"
		% normali_ô_juorno_uno, normali_ô_juorno_uno == 200)

	var conta: Dictionary = {}
	var giri := 4000
	for i in range(giri):
		# **'O giro adda passà pe' 'o primmo d''o mese.** Con giorni da 2 a
		# 26 il "primmo" (che esce a giornata % 30 == 1, cioè il 31, il 61…)
		# non usciva mai, e la prova diceva che mancava una giornata: non
		# mancava, mancava il giorno giusto nel giro.
		GameManager.giornata = 2 + (i % 62)
		GameManager.prepara_giornata()
		var t: String = GameManager.tipo_giornata
		conta[t] = int(conta.get(t, 0)) + 1
	var speciali: int = giri - int(conta.get("normale", 0))
	var quota: float = float(speciali) / float(giri)
	print("  ncopp'a %d juorne: %d speciale (%.0f%%)" % [giri, speciali,
		quota * 100.0])
	for g in GameManager.GIURNATE:
		var id: String = str(g["id"])
		print("    %-14s %4d" % [id, int(conta.get(id, 0))])
	_verifica("'na jurnata ncopp'a tre è speciale",
		absf(quota - GameManager.SPECIALE_OGNI) < 0.05)
	var mancate := 0
	for g in GameManager.GIURNATE:
		if int(conta.get(str(g["id"]), 0)) == 0:
			mancate += 1
	_verifica("tutt''e cinche escono almeno 'na vota", mancate == 0)

	# --- 'E ddoje tabelle se mutiplicano ---------------------------------
	print("=== ORA × JURNATA ===")
	GameManager.giornata = 5
	GameManager.start_shift()
	var storte := 0
	for id in ["normale", "mercato", "processione", "primmo"]:
		GameManager.tipo_giornata = str(id)
		for ore in [3.0, 10.0, 14.0]:
			GameManager.shift_time_left = GameManager.shift_duration \
				* (1.0 - ore / GameManager.ORE_DI_GIORNATA)
			var atteso: float = GameManager.attesa_fascia() \
				* GameManager.attesa_giornata()
			if absf(GameManager.attesa_ora_e_juorno() - atteso) > 0.0001:
				storte += 1
	_verifica("l'attesa è 'o prodotto d''e ddoje", storte == 0)

	# Il caso concreto: il mercato a mezzanotte contro la processione alla
	# stessa ora. Se non cambia niente, i moltiplicatori non arrivano.
	GameManager.shift_time_left = GameManager.shift_duration \
		* (1.0 - 13.0 / GameManager.ORE_DI_GIORNATA)
	GameManager.tipo_giornata = "mercato"
	var merc: float = GameManager.attesa_ora_e_juorno()
	var merc_m: float = GameManager.bonus_mancia()
	GameManager.tipo_giornata = "processione"
	var proc: float = GameManager.attesa_ora_e_juorno()
	var proc_m: float = GameManager.bonus_mancia()
	print("  a mezzanotte:  mercato attesa %.2f mancia %.2f  ·  prucessione attesa %.2f mancia %.2f"
		% [merc, merc_m, proc, proc_m])
	_verifica("ô mercato arrivano cchiù machine ca â prucessione", merc < proc)
	_verifica("ma â prucessione pavano 'e cchiù", proc_m > merc_m)

	# --- 'A gente 'n copp'â via ------------------------------------------
	print("=== 'A GENTE ===")
	GameManager.tipo_giornata = "pioggia"
	var g_pioggia: int = clampi(int(round(14.0 * GameManager.gente_giornata())), 6, 30)
	GameManager.tipo_giornata = "processione"
	var g_proc: int = clampi(int(round(14.0 * GameManager.gente_giornata())), 6, 30)
	print("  passante: cu 'a pioggia %d, cu 'a prucessione %d" % [g_pioggia, g_proc])
	_verifica("cu 'a prucessione 'a via è cchiù chiena d''o doppio",
		g_proc > g_pioggia * 2)

	# --- 'E multe ---------------------------------------------------------
	GameManager.tipo_giornata = "mercato"
	var m_merc: float = GameManager.multe_giornata()
	GameManager.tipo_giornata = "partita"
	var m_part: float = GameManager.multe_giornata()
	_verifica("ô mercato 'e vigile scrivono 'e cchiù (%.2f contro %.2f)"
		% [m_merc, m_part], m_merc > m_part * 2.0)

	print("=== %d storte ===" % _male)
	get_tree().quit()


func _verifica(che: String, ok: bool) -> void:
	if not ok:
		_male += 1
	print("  %-50s %s" % [che, "OK" if ok else "STORTO"])
