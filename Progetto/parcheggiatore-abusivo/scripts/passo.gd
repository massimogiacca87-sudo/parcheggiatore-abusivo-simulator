extends Object
class_name Passo
## **'O passo 'e chi cammina — e 'e mure ca nun se passano** (0.56).
##
## Il capo, punto 8: *«Occhio che molti png attraversano i muri, succede ad
## esempio ai bambini che giocano ma anche ai guidatori quando vanno via.»*
##
## Aveva ragione, e la ragione sta in una riga sola ripetuta in nove
## personaggi diversi:
##
##     global_position = global_position.move_toward(meta, VELOCITA * delta)
##
## Sembra movimento e non lo è: è un **teletrasporto a piccoli passi**. Non
## tocca il motore fisico, quindi non c'è niente che possa fermarlo — e
## infatti non lo fermava niente. Il guidatore finiva la spesa, puntava la
## macchina in linea d'aria e se ne tornava **attraverso l'isolato**.
##
## Si poteva riscrivere tutto con `CharacterBody3D.move_and_slide()`. Si
## poteva, e sarebbe stata la cosa giusta in un gioco con una mappa vera;
## qui vuol dire riscrivere nove personaggi, dare a ognuno una velocità che
## si accumula, e ritrovarseli tutti incastrati nello stesso pomeriggio
## dentro a un portone. Il rischio non valeva il premio.
##
## Quello che c'è invece è una città fatta di **rettangoli scritti in una
## tabella** (`Citta.ISOLATI`), e per chi cammina su rettangoli la
## geometria è la fisica. Qui dentro c'è un passo solo, e fa tre cose:
##
## 1. prova ad andare dritto;
## 2. se dritto finisce dentro a un palazzo, **striscia** — prova solo in X,
##    poi solo in Z, e si tiene quella che avvicina di più alla meta;
## 3. se anche strisciare non serve (sei già dentro: ti ci ha messo
##    qualcun altro, o sei nato lì), **esce dalla faccia più vicina**.
##
## Il punto 3 è quello che conta davvero. Un muro che ti ferma è mezzo
## lavoro: l'altro mezzo è che, comunque tu ci finisca dentro, non ci puoi
## restare.
##
## La quota Y non si tocca mai: chi cammina sta a terra e i palazzi sono
## pieni da cima a fondo, quindi il problema è tutto sul piano.

const Citta := preload("res://scripts/citta_3d.gd")
const Ostacoli := preload("res://scripts/ostacoli.gd")
const Cammino := preload("res://scripts/cammino.gd")

## Mezzo corpo, in metri. Un passante è largo poco più di mezzo metro.
const ORLO: float = 0.40


## Il nome del ricordo che si lascia addosso a chi cammina: da che parte
## stava girando l'ultima volta che ha trovato un muro.
const GIRA := &"passo_gira"
## E da quanti passi di fila sta contro a un muro **senza avvicinarsi
## alla meta**, più la meta stessa e quanto le è arrivato vicino.
const BLOCCO := &"passo_blocco"
const MEGLIO := &"passo_meglio"
const META := &"passo_meta"

## **'A valvola 'e sicurezza, e pecché ce vò.**
##
## Girare intorno all'ostacolo sempre dallo stesso lato porta a
## destinazione **se la destinazione è raggiungibile**. Il guaio è che non
## sempre lo è: un autista può aver parcheggiato in un posto che il
## pianificatore considera dentro a un isolato, una vetrina può avere il
## punto di sosta mezzo dentro al muro, una piazza nuova può nascere con un
## angolo murato. In tutti quei casi il muro non è un ostacolo da girare: è
## una porta chiusa, e chi ci sta davanti ci resta per sempre.
##
## E **un personaggio piantato è peggio di un personaggio che passa dentro
## a un muro**. Uno che attraversa si nota e fa ridere; uno piantato blocca
## il giro della macchina, il cliente non torna, la piazza si riempie di
## auto che non se ne vanno più — cioè rompe il gioco, non la scena. È
## esattamente il bug che la 0.55 ha passato tre giorni a togliere.
##
## Quindi: dopo dieci secondi buoni, si passa. Non è una resa, è una scelta
## — si sceglie il difetto che costa meno.
##
## **E "dieci secondi di muro" nun vò dì "dieci secondi ca sta girando".**
## Questo è il punto dove la prima versione ha sbagliato, e vale la pena
## scriverlo perché è il genere di errore che sembra giusto: contavo i passi
## in cui la strada dritta era occupata. Ma **girare intorno a un isolato
## vuol dire avere la strada dritta occupata per tutto il tempo che ci
## metti a girarlo** — venti metri di palazzo a passo d'uomo sono sette
## secondi in cui il conto sale senza che ci sia niente che non va. Il
## risultato misurato: l'undici per cento dei passi finiva dentro ai muri,
## cioè la valvola era diventata il comportamento normale.
##
## Quello che conta non è se sei contro un muro: è **se ti stai
## avvicinando**. Chi gira l'angolo, a un certo punto, alla meta ci arriva
## più vicino di prima; chi sta davanti a una porta chiusa no, mai. Quindi
## il conto riparte da zero ogni volta che batti il tuo record di
## vicinanza, e arriva in fondo solo per chi una strada non ce l'ha.
const BLOCCO_MAX: int = 600
## Di quanto ci si deve avvicinare perché conti come progresso. Mezzo
## decimetro: meno di così è il tremolio di uno che struscia sul muro.
const PASSO_AVANTI: float = 0.05


## Un passo verso `meta`, lungo `quanto`, che non entra dentro ai palazzi.
##
## Si usa al posto di `global_position.move_toward(meta, v * delta)`: al
## posto della posizione si passa **il nodo**, perché serve un ricordo — e
## il perché sta scritto sotto, nel pezzo sul girare sempre dallo stesso
## lato.
static func verso(chi: Node3D, meta: Vector3, quanto: float,
		orlo: float = ORLO) -> Vector3:
	# L'orologio di chi cammina: un passo per chiamata (vedi `PASSI`).
	chi.set_meta(PASSI, int(chi.get_meta(PASSI, 0)) + 1)
	var da: Vector3 = chi.global_position
	# **'A strada, quanno ce vò** (0.59): se se ne sta seguendo una, si
	# punta al prossimo angolo invece che alla meta.
	var mira: Vector3 = _mira(chi, da, meta)
	var dritto: Vector3 = da.move_toward(mira, quanto)
	if not _chiuso(dritto, orlo):
		# Strada libera: si scorda il muro di prima.
		if chi.has_meta(GIRA):
			chi.remove_meta(GIRA)
		if chi.has_meta(BLOCCO):
			chi.remove_meta(BLOCCO)
		return dritto

	# Chiuso. Prima di strisciare contro il muro si chiede una strada vera
	# (una volta per meta): vedi `_nuova_strada`.
	if _nuova_strada(chi, da, meta):
		mira = _mira(chi, da, meta)
		dritto = da.move_toward(mira, quanto)
		if not _chiuso(dritto, orlo):
			return dritto

	# **'A valvola.** Il conto sale solo se non ci si avvicina: vedi
	# `BLOCCO_MAX` per il perché — è la differenza fra uno che gira
	# l'angolo e uno che sta davanti a una porta chiusa.
	var quanto_manca: float = Vector2(da.x - meta.x, da.z - meta.z).length()
	var vecchia_meta: Vector3 = chi.get_meta(META, Vector3.INF)
	var meglio: float = float(chi.get_meta(MEGLIO, INF))
	if vecchia_meta == Vector3.INF or vecchia_meta.distance_to(meta) > 1.0:
		# Meta nuova: il conto di prima non vale più niente.
		chi.set_meta(META, meta)
		chi.set_meta(MEGLIO, quanto_manca)
		chi.set_meta(BLOCCO, 0)
	elif quanto_manca < meglio - PASSO_AVANTI:
		chi.set_meta(MEGLIO, quanto_manca)
		chi.set_meta(BLOCCO, 0)
	else:
		var bloccato: int = int(chi.get_meta(BLOCCO, 0)) + 1
		chi.set_meta(BLOCCO, bloccato)
		if bloccato > BLOCCO_MAX:
			return dritto

	# **Se striscia.** Il muro è una faccia, e una faccia ha una direzione
	# libera: quella parallela. Le candidate sono quattro: le due
	# componenti del passo prese da sole, e le due perpendicolari alla
	# direzione di marcia.
	#
	# Le perpendicolari servono più di quanto sembri. Se la meta sta
	# esattamente dritta davanti — stessa X, solo Z da percorrere — la
	# componente X del passo **è zero**: «striscia in X» vuol dire non
	# muoversi affatto. Senza le perpendicolari, chi ha un palazzo dritto
	# davanti resta lì fermo per sempre, che è un modo diverso ma non
	# migliore di rompere il gioco.
	var d := Vector3(mira.x - da.x, 0.0, mira.z - da.z)
	if d.length() < 0.001:
		return da
	d = d.normalized()
	var perp := Vector3(-d.z, 0.0, d.x)
	var strade := [
		Vector3(dritto.x, da.y, da.z),          # 0: sulo X
		Vector3(da.x, da.y, dritto.z),          # 1: sulo Z
		da + perp * quanto,                     # 2: 'e llato a manca
		da - perp * quanto,                     # 3: 'e llato a destra
	]

	# **E se gira sempe d''a stessa parte.**
	#
	# Questo è il pezzo che ha fatto la differenza. Scegliendo ogni
	# fotogramma «quella che avvicina di più alla meta», su uno spigolo si
	# va a destra, il fotogramma dopo a sinistra, e poi di nuovo: chi
	# cammina resta a tremare contro l'angolo del palazzo finché non
	# cambia idea la meta. È il modo classico di incastrarsi, e la cura è
	# vecchia quanto i robot: **quando trovi un muro, giragli intorno
	# sempre dalla stessa parte**, e non cambiare finché non hai la strada
	# libera. Il ricordo di che parte era sta appiccicato al nodo, e si
	# cancella da solo appena il dritto torna buono.
	var prima: int = int(chi.get_meta(GIRA, -1))
	var ordine := [0, 1, 2, 3]
	if prima >= 0:
		ordine = [prima]
		for i in [0, 1, 2, 3]:
			if i != prima:
				ordine.append(i)

	var miglio: int = -1
	var miglio_d: float = INF
	for i in ordine:
		var p: Vector3 = strade[i]
		if Vector2(p.x - da.x, p.z - da.z).length() < quanto * 0.05:
			continue  # non si muove: non è una strada
		if _chiuso(p, orlo):
			continue
		# Se era già quella di prima ed è ancora buona, si tiene: è il
		# punto di tutta la faccenda.
		if i == prima:
			return p
		var dist: float = Vector2(p.x - mira.x, p.z - mira.z).length()
		if dist < miglio_d:
			miglio_d = dist
			miglio = i
	if miglio >= 0:
		chi.set_meta(GIRA, miglio)
		return strade[miglio]

	# Né dritto né di lato: o sei già dentro, o sei in un angolo. In
	# tutt'e due i casi la risposta è la stessa — **fore**.
	if chi.has_meta(GIRA):
		chi.remove_meta(GIRA)
	return fore(da, orlo)


## Il solo controllo di sicurezza, da chiamare dopo che qualcun altro ti ha
## spostato (uno spawn, una spinta, un `global_position =` secco).
##
## Prima fuori dal palazzo, poi fuori dalla cosa. Ma se uscire dalla cosa
## rimette dentro al palazzo (una cassa appoggiata alla facciata: la sua
## faccia più vicina è quella contro il muro), si resta dove si è: meglio
## un piede dentro a una cassa che il corpo intero dentro a un muro.
static func fore(p: Vector3, orlo: float = ORLO) -> Vector3:
	var q: Vector3 = Citta.fore_d_ô_palazzo(p, orlo)
	var r: Vector3 = Ostacoli.fore(q, orlo * ORLO_COSE)
	if not Citta.dint_ô_palazzo(r, orlo * 0.5):
		return r
	# **'Na porta chiusa 'a tutt' 'e doje parte** (0.59). Uscendo dal
	# palazzo dalla faccia più vicina si può finire dentro a una cosa — il
	# muro di confine della mappa, una cassa appoggiata alla facciata — e
	# uscendo dalla cosa si rientra nel palazzo. Prima ci si restava, e da
	# lì nessun passo era più buono: `prova_confronto` ha trovato l'autista
	# piantato per sempre fra l'isolato d'angolo e il confine. Adesso si
	# provano le altre facce del palazzo, dalla più vicina, e si esce dalla
	# prima che dà su un posto libero da tutt'e due.
	for u in Citta.uscite_d_ô_palazzo(p, orlo):
		if not Ostacoli.dentro(u, orlo * ORLO_COSE):
			return u
	return q


# ---------------------------------------------------------------------------
# 'A strada (0.59)
# ---------------------------------------------------------------------------
#
# **Strisciare sui muri va bene per girare un angolo, no pe' traversà 'a
# città.** Il passo della 0.56 è un algoritmo «a formica»: va dritto, e se
# sbatte gira intorno all'ostacolo tenendo sempre la stessa mano sul muro.
# Con i soli palazzi (rettangoli pieni, con la strada sempre intorno)
# funzionava. Con le cose in strada (`ostacoli.gd`) e i recinti delle piazze
# no: fra un'auto in sosta e un cassonetto la formica si infila in una sacca
# e ci gira dentro fino alla valvola. `prova_mure` è scesa da trecento
# camminate su quattrocento arrivate a centodiciotto.
#
# Quindi: quando il dritto è chiuso, prima di strisciare si chiede la
# strada a `cammino.gd` — la stessa griglia dei passanti — e si seguono i
# suoi angoli. Una volta sola per meta (e non più spesso di una volta ogni
# settecento millisecondi, per chi insegue una meta che si muove: il
# pallone, il giocatore). Se la strada non c'è, si torna alla formica.

const STRADA := &"passo_strada"
const STRADA_I := &"passo_strada_i"
const STRADA_PER := &"passo_strada_per"
const STRADA_QUANNO := &"passo_strada_quanno"

## **L'orologio d''e passe, no chillo d''o muro** (0.59). I tempi fra una
## strada e l'altra si contavano in millisecondi veri: due secondi e mezzo
## per riprovare la stessa meta. Nel gioco un passo è un fotogramma e i
## conti tornavano; in `prova_mure`, che fa tremila passi dentro a un
## fotogramma solo, i due secondi e mezzo non passavano mai — la prima
## strada finita era anche l'ultima, e da lì in poi solo la formica. Metà
## delle camminate si piantavano per un difetto della misura, non del passo.
## Adesso si contano i passi di chi cammina: 150 passi sono due secondi e
## mezzo a sessanta fotogrammi, e in una prova veloce restano 150 passi.
const PASSI := &"passo_passi"
const RIPROVA_STESSA: int = 150
const RIPROVA_NOVA: int = 42


static func _nuova_strada(chi: Node3D, da: Vector3, meta: Vector3) -> bool:
	var ora: int = int(chi.get_meta(PASSI, 0))
	var quanno: int = int(chi.get_meta(STRADA_QUANNO, -100000))
	var per: Vector3 = chi.get_meta(STRADA_PER, Vector3.INF)
	# Stessa meta: se ne riprova una solo quando quella di prima è finita e
	# sono passati due secondi e mezzo (qualcosa di nuovo in mezzo: un'auto
	# appena parcheggiata, un altro che cammina).
	if per != Vector3.INF and per.distance_to(meta) < 1.0:
		if chi.has_meta(STRADA) or ora - quanno < RIPROVA_STESSA:
			return false
	elif ora - quanno < RIPROVA_NOVA:
		return false
	chi.set_meta(STRADA_QUANNO, ora)
	chi.set_meta(STRADA_PER, meta)
	var s: PackedVector3Array = Cammino.strada(da, meta)
	if s.size() < 2:
		_scorda_strada(chi)
		return false
	chi.set_meta(STRADA, s)
	chi.set_meta(STRADA_I, 0)
	return true


static func _mira(chi: Node3D, da: Vector3, meta: Vector3) -> Vector3:
	if not chi.has_meta(STRADA):
		return meta
	var per: Vector3 = chi.get_meta(STRADA_PER, Vector3.INF)
	if per == Vector3.INF or per.distance_to(meta) > 1.5:
		# La meta si è spostata: la strada vecchia non vale più.
		_scorda_strada(chi)
		return meta
	var s: PackedVector3Array = chi.get_meta(STRADA)
	var i: int = int(chi.get_meta(STRADA_I, 0))
	while i < s.size() and Vector2(s[i].x - da.x, s[i].z - da.z).length() < 0.6:
		i += 1
	if i >= s.size() - 1:
		# L'ultimo punto è la meta stessa: da qui in poi si punta a lei.
		chi.remove_meta(STRADA)
		return meta
	chi.set_meta(STRADA_I, i)
	return Vector3(s[i].x, da.y, s[i].z)


static func _scorda_strada(chi: Node3D) -> void:
	if chi.has_meta(STRADA):
		chi.remove_meta(STRADA)
	if chi.has_meta(STRADA_I):
		chi.remove_meta(STRADA_I)


## **'E ccose, no sulo 'e palazze** (0.59). Fino alla 0.58 qui dentro si
## guardavano soltanto i palazzi: un'auto in sosta, una panchina, un
## cassonetto per chi cammina erano aria (vedi `ostacoli.gd`). Adesso il
## passo li conosce tutti.
##
## Con un orlo un po' più stretto di quello dei muri: fra due macchine in
## sosta ci sono sessanta centimetri, e una persona ci passa di sbieco. Con
## lo stesso orlo dei palazzi il varco risultava chiuso, e l'autista che
## tornava alla sua macchina girava intorno a tutta la fila.
const ORLO_COSE: float = 0.7


static func _chiuso(p: Vector3, orlo: float) -> bool:
	return Citta.dint_ô_palazzo(p, orlo) or Ostacoli.dentro(p, orlo * ORLO_COSE)
