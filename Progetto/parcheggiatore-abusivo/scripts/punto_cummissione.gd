extends StaticBody3D
## PuntoCummissione — 'o segno 'n terra addò se piglia o se lassa

var cid: String = ""
var ritiro: bool = true
## Se e' pieno, questo non e' un segno di commissione ma la consegna di un
## **pacco** preso in bacheca. Stesso disco, stessa colonna di luce, altro
## contenuto: due segni disegnati in due modi diversi per due cose che si
## fanno allo stesso modo sarebbero due cose da imparare invece di una.
var lid: String = ""


func _ready() -> void:
	add_to_group("punti_cummissione")


func get_interact_prompt(_da: Vector3) -> String:
	if not lid.is_empty():
		var l: Dictionary = GameManager.lavoretto(lid)
		if l.is_empty() or str(l["stato"]) != "in_mano":
			return ""
		var r: float = float(l.get("scade", 0.0))
		# **'A guardia nun se consegna: se fa.** Non c'è niente da premere
		# finché il cronometro non arriva a zero — e quel cronometro
		# scorre solo se stai vicino e nessuno ti guarda storto (vedi
		# `_passo_guardia` nel GameManager).
		if str(l.get("tipo", "")) == "guardia":
			var manca: float = GameManager.guardia_restano()
			if manca > 0.0:
				return "%s — statte ccà ancora %d\"" % [
					str(l["nome"]), int(ceil(manca))]
			return "%s — [E] piglia 'e sorde (€%d)" % [
				str(l["nome"]), int(l["paga"])]
		var verbo := "lassa 'o pacco"
		if str(l.get("tipo", "")) == "caffe":
			verbo = "consegna, primma ca s'arrefredda"
		return "%s — [E] %s (€%d · %d\")" % [
			str(l["nome"]), verbo, int(l["paga"]), int(maxf(r, 0.0))]
	var c: Dictionary = GameManager.commissione(cid)
	if c.is_empty():
		return ""
	if ritiro:
		var in_mano: Dictionary = GameManager.commissione_in_mano()
		if not in_mano.is_empty():
			return "Tiene già 'na cosa 'n mano — portala 'a %s" \
				% str(in_mano["nome_a"])
		return "%s — [E] pigliala (€%d · %s)" \
			% [str(c["nome"]), int(c["paga"]), str(c["nome_a"])]
	var resta: float = float(c.get("scade", 0.0))
	return "%s — [E] consegna (€%d · %d\")" \
		% [str(c["nome"]), int(c["paga"]), int(maxf(resta, 0.0))]


func player_interact() -> void:
	if not lid.is_empty():
		var lv: Dictionary = GameManager.lavoretto(lid)
		var paga: int = GameManager.finisci_lavoretto(lid)
		if paga > 0:
			var frase := "Consegnato. €%d, e nun hê visto niente." % paga
			match str(lv.get("tipo", "")):
				"caffe":
					frase = "Arrivato càvero. €%d." % paga
				"guardia":
					frase = "Guardia fatta. €%d pe' stà fermo." % paga
			GameManager.event_started.emit(frase)
		return
	var c: Dictionary = GameManager.commissione(cid)
	if c.is_empty():
		return
	if ritiro:
		if not GameManager.commissione_in_mano().is_empty():
			return
		if GameManager.prendi_commissione(cid):
			SoundManager.play("pop", -6.0)
		return
	var paga: int = GameManager.consegna_commissione(cid)
	if paga > 0:
		GameManager.event_started.emit(
			"Cummissione fatta: +€%d. Chi cammina, magna." % paga)
