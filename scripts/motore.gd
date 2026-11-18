## Regole di Downfall of the Third Reich e stato della partita.
## Deterministico: a parità di seme e di decisioni dà sempre lo stesso risultato (online si scambiano solo le decisioni).
class_name Motore
extends RefCounted

signal evento(testo: String)

var D: Dati
var s := {}
var rng := RandomNumberGenerator.new()
var _cache_rif := {}
var _occ := {}   # area -> lato -> [uid], ricostruito quando serve

func _init(dati: Dati) -> void:
	D = dati

# =====================================================================================
# Stato
# =====================================================================================

func nuova(seme: int) -> void:
	s = {
		"seme": seme, "tiri": 0, "turno": 1, "lato": "asse", "fase": "operazioni", "finita": false, "esito": "",
		"ctrl": {}, "u": {}, "prossimo": 1, "log": [],
		"rif": {"asse": 5, "alleati": 2, "urss": 2},
		"cor": {"asse": 0, "alleati": 2, "urss": 0},
		"aerei": {"asse": 4, "alleati": 0, "urss": 0},
		"sub": 3,
		"svil": {"asse": {"blitzkrieg": 2, "aviazione": 2}, "alleati": {"aviazione": 2}, "urss": {"aviazione": 1}},
		"guerra": {"GER": true, "GB": true, "FRA": true, "FIN": true, "URSS": true, "BEL": false, "ITA": false, "ROM": false,
			"UNG": false, "BUL": false, "GRE": false, "JUG": false, "USA": false},
		"arresi": {}, "tot": {"asse": false, "alleati": false, "urss": false}, "tot_da": {},
		"barbarossa": 0, "attacco_ovest": 0, "afn_neutrale": false, "partigiani": false,
		"atlantico": 0, "atlantico_av": false, "pen_asse": 0, "prestito": 0,
		"attaccati_alleati": [], "ultimo_tiro": {},
	}
	for id in D.aree:
		var naz := D.nazione(id)
		var l: String = D.LATO_NAZ.get(D.patria(id), "")
		s["ctrl"][id] = l
	s["ctrl"]["carelia"] = "asse"
	for r in D.SCHIERAMENTO:
		_nuova_unita(r[1], r[2], r[0], r[3])
	rng.seed = seme
	_inizio_lato()
	_log("[b]Inverno 1940.[/b] La Germania prepara l'invasione della Francia; l'URSS ha già attaccato la Finlandia.")

func esporta() -> Dictionary:
	var c: Dictionary = s.duplicate(true)
	c["rng"] = rng.state
	return c

func importa(st: Dictionary) -> void:
	s = st.duplicate(true)
	rng.seed = int(s["seme"])
	rng.state = int(s.get("rng", rng.state))
	# JSON trasforma gli interi in float: si riportano i contatori a intero
	for k in ["turno", "prossimo", "tiri", "barbarossa", "attacco_ovest", "atlantico", "pen_asse", "prestito", "sub"]:
		if s.has(k):
			s[k] = int(s[k])
	for k in ["rif", "cor", "aerei"]:
		for l in s[k]:
			s[k][l] = int(s[k][l])
	for l in s["svil"]:
		for x in s["svil"][l]:
			s["svil"][l][x] = int(s["svil"][l][x])
	if s.has("az"):
		for k in ["usate", "max"]:
			s["az"][k] = int(s["az"][k])
		for k in s["az"]["tipi"]:
			s["az"]["tipi"][k] = int(s["az"]["tipi"][k])
	for k in ["punti", "punti_gb", "sbarchi", "sbarchi_d", "sbarchi_tr", "strat_urss", "bomb"]:
		if s.has(k):
			s[k] = int(s[k])
	invalida()

func _nuova_unita(naz: String, tipo: String, h: String, ridotta: bool) -> String:
	var id := "u%d" % int(s["prossimo"])
	s["prossimo"] = int(s["prossimo"]) + 1
	s["u"][id] = {"naz": naz, "t": tipo, "r": ridotta, "h": h, "op": "", "ent": "", "anf": false, "rif": true}
	invalida()
	return id

func _log(t: String) -> void:
	s["log"].append(t)
	if s["log"].size() > 400:
		s["log"].remove_at(0)
	evento.emit(t)

func finita() -> bool:
	return bool(s.get("finita", false))

func data_testo() -> String:
	return Dati.data(int(s["turno"]))

func anno() -> int:
	return Dati.anno(int(s["turno"]))

func lato_di(uid: String) -> String:
	return D.LATO_NAZ[s["u"][uid]["naz"]]

static func nemici(a: String, b: String) -> bool:
	return (a == "asse" and b != "asse" and b != "") or (b == "asse" and a != "asse" and a != "")

func ha(lato: String, sv: String) -> bool:
	return int(s["svil"][lato].get(sv, 0)) >= 2

func guerra_totale(lato: String) -> bool:
	return bool(s["tot"][lato])

func _occupazione() -> Dictionary:
	if _occ.is_empty():
		_occ["#"] = true
		for uid in s["u"]:
			var u: Dictionary = s["u"][uid]
			var h: String = u["h"]
			var l: String = D.LATO_NAZ[u["naz"]]
			if not _occ.has(h):
				_occ[h] = {}
			if not _occ[h].has(l):
				_occ[h][l] = []
			_occ[h][l].append(uid)
	return _occ

func invalida() -> void:
	_occ.clear()
	_cache_rif.clear()

func unita_in(area: String, lato := "") -> Array:
	var o: Dictionary = _occupazione().get(area, {})
	if lato != "":
		return (o.get(lato, []) as Array).duplicate()
	var out := []
	for l in o:
		out.append_array(o[l])
	return out

func nemici_in(area: String, lato: String) -> Array:
	var o: Dictionary = _occupazione().get(area, {})
	var out := []
	for l in o:
		if nemici(lato, l):
			out.append_array(o[l])
	return out

func conta_pedine(naz: String, tipo: String) -> int:
	var n := 0
	for uid in s["u"]:
		if s["u"][uid]["naz"] == naz and s["u"][uid]["t"] == tipo:
			n += 1
	return n

func pedine_libere(naz: String, tipo: String) -> int:
	if not D.ARMATE.has(naz) or not D.ARMATE[naz].has(tipo):
		return 0
	return int(D.ARMATE[naz][tipo][2]) - conta_pedine(naz, tipo)

func fattore_unita(uid: String) -> int:
	var u: Dictionary = s["u"][uid]
	var f := Dati.fattore(u["naz"], u["t"], u["r"], D.africa(u["h"]))
	if D.LATO_NAZ[u["naz"]] == "asse" and int(s["turno"]) == 9 and D.nazione(u["h"]) == "URSS":
		f -= 1
	return maxi(f, 1)

func nome_unita(uid: String) -> String:
	var u: Dictionary = s["u"][uid]
	var t: String = Dati.NOME_TIPO[u["t"]]
	if u["t"] == "k":
		return "Afrika Korps" + (" (ridotto)" if u["r"] else "")
	if u.get("par", false):
		return "Partigiani jugoslavi" + (" (ridotti)" if u["r"] else "")
	var a: String = Dati.AGG_NAZ.get(u["naz"], u["naz"])
	var tipo := "armata %s" % t if u["t"] != "g" else "armata della Guardia"
	if u["t"] == "f":
		tipo = "armata di fanteria"
	return "%s %s%s" % [tipo, a, " (ridotta)" if u["r"] else ""]

static func maiuscola(t: String) -> String:
	return t.substr(0, 1).to_upper() + t.substr(1) if t != "" else t

func sigla_unita(uid: String) -> String:
	var u: Dictionary = s["u"][uid]
	return str(fattore_unita(uid))

# =====================================================================================
# Richiesta: chi deve decidere e che cosa
# =====================================================================================

func richiesta() -> Dictionary:
	if finita():
		return {"k": "fine", "g": ""}
	if s.has("attesa"):
		var a: Dictionary = s["attesa"]
		return {"k": a["k"], "g": a["g"]}
	return {"k": s["fase"], "g": s["lato"]}

# =====================================================================================
# Inizio e fine del turno di un lato
# =====================================================================================

func _inizio_lato() -> void:
	var lato: String = s["lato"]
	var t := int(s["turno"])
	s["fase"] = "operazioni"
	s["attacchi"] = []
	s["ctrl_pend"] = {}
	s["combattuto"] = false
	s["punti"] = 0
	s["punti_gb"] = 0
	s["sbarchi"] = 0
	s["sbarchi_d"] = 0
	s["sbarchi_tr"] = 0
	s["strat_urss"] = 0
	s["bomb"] = 0
	s["azioni_fatte"] = []
	# guerra totale
	for l in Dati.LATI:
		if t >= 9 or (s["tot_da"].has(l) and t >= int(s["tot_da"][l])):
			if not s["tot"][l]:
				s["tot"][l] = true
				if l != "alleati" or t >= 9:
					_log("%s entra in guerra totale." % ("L'" + Dati.NOME_LATO[l] if l == "asse" else ("Gli " + Dati.NOME_LATO[l] if l == "alleati" else "L'" + Dati.NOME_LATO[l])))
	# entrata in guerra delle nazioni minori
	if t >= 2:
		_entra_in_guerra("BEL", "")
	if t >= 5 or s["tot"]["asse"]:
		for n in ["ROM", "UNG", "BUL"]:
			_entra_in_guerra(n, "")
	if t >= 5:
		_entra_in_guerra("GRE", "")
	if t >= 9:
		_entra_in_guerra("JUG", "")
		_entra_in_guerra("USA", "")
	for uid in s["u"]:
		var u: Dictionary = s["u"][uid]
		u["op"] = ""
		u["ent"] = ""
		u["anf"] = false
	invalida()
	for uid in s["u"]:
		if lato_di(uid) == lato:
			s["u"][uid]["rif"] = ha_rifornimento(uid)
	# rinforzi delle nazioni minori, non sono un'azione
	_rinforzi_minori()
	if lato == "asse" and s["guerra"]["ITA"] and not s["arresi"].has("ITA"):
		_aggiungi_rif("asse", 3)
	# azioni disponibili
	var n := 0
	var pen := []
	match lato:
		"asse":
			n = 4 if s["tot"]["asse"] else 3
			if s["tot"]["asse"]:
				for id in ["ruhr", "berlino", "breslavia", "monaco"]:
					if s["ctrl"][id] != "asse":
						n -= 1
						pen.append("%s perduta" % D.nome(id))
				if s["ctrl"]["trondheim"] == "alleati" and Dati.stagione(t) <= 1:
					n -= 1
					pen.append("Trondheim in mano alleata")
			if int(s["pen_asse"]) > 0:
				n -= 1
				pen.append("bombardamento strategico")
				s["pen_asse"] = 0
		"alleati":
			n = 5 if s["tot"]["alleati"] else 2
			var persa := false
			if s["ctrl"]["londra"] == "asse":
				persa = true
				pen.append("Londra occupata")
			elif _sottomarini_efficaci():
				persa = true
				pen.append("sottomarini nell'Atlantico")
			if persa:
				n -= 1
		"urss":
			n = 3 if s["tot"]["urss"] else 2
			if s["tot"]["urss"] and s["ctrl"]["mosca"] == "asse":
				n -= 1
				pen.append("Mosca occupata")
			if int(s["prestito"]) == t:
				n += 1
				pen.append("+1 per affitti e prestiti")
	s["az"] = {"usate": 0, "max": maxi(n, 0), "tipi": {}}
	if not pen.is_empty():
		_log("Azioni %s: %d (%s)." % [Dati.NOME_LATO_BREVE[lato], maxi(n, 0), ", ".join(pen)])

func _sottomarini_efficaci() -> bool:
	var n := int(s["atlantico"])
	if n <= 0:
		return false
	if ha("alleati", "navi_av") and not bool(s["atlantico_av"]):
		return false
	if bool(s["atlantico_av"]) and not ha("alleati", "navi_av"):
		return n >= 1
	return n >= 2

func _aggiungi_rif(lato: String, n: int) -> void:
	s["rif"][lato] = clampi(int(s["rif"][lato]) + n, 0, Dati.MAX_RIF)

func _entra_in_guerra(naz: String, motivo: String) -> void:
	if s["guerra"].get(naz, false) or s["arresi"].has(naz):
		return
	s["guerra"][naz] = true
	var l: String = D.LATO_NAZ[naz]
	var testo := "%s entra in guerra con %s" % [Dati.NOME_NAZ[naz], "l'Asse" if l == "asse" else "gli Alleati"]
	_log(testo + (" (%s)." % motivo if motivo != "" else "."))

func _rinforzi_minori() -> void:
	var lato: String = s["lato"]
	var t := int(s["turno"])
	var estiva := Dati.stagione(t) == 0 or Dati.stagione(t) == 2
	for naz in ["ITA", "FRA", "FIN", "ROM", "UNG", "BUL", "BEL", "GRE", "JUG"]:
		if D.LATO_NAZ[naz] != lato or not s["guerra"][naz] or s["arresi"].has(naz):
			continue
		if naz in ["ITA", "FRA"] or estiva:
			_passo_minore(naz, D.capitale(naz))
	# partigiani jugoslavi
	if lato == "alleati" and s["arresi"].has("JUG") and t >= 11 and estiva:
		if not s["partigiani"]:
			s["partigiani"] = true
			_log("I partigiani jugoslavi tornano a combattere.")
		for k in 2:
			_passo_partigiani()

func _passo_minore(naz: String, cap: String) -> void:
	# prima si rinforza un'armata ridotta rifornita, poi se ne crea una ridotta nella capitale
	for uid in s["u"]:
		var u: Dictionary = s["u"][uid]
		if u["naz"] == naz and u["r"] and ha_rifornimento(uid):
			u["r"] = false
			return
	if cap == "" or s["ctrl"][cap] != D.LATO_NAZ[naz] or pedine_libere(naz, "f") <= 0:
		return
	if unita_in(cap, D.LATO_NAZ[naz]).size() >= 3 or not nemici_in(cap, D.LATO_NAZ[naz]).is_empty():
		return
	_nuova_unita(naz, "f", cap, true)

func _passo_partigiani() -> void:
	for uid in s["u"]:
		var u: Dictionary = s["u"][uid]
		if u.get("par", false) and u["r"]:
			u["r"] = false
			return
	if pedine_libere("JUG", "f") <= 0:
		return
	for id in ["montenegro", "zagabria", "nis", "belgrado"]:
		if nemici_in(id, "alleati").is_empty() and unita_in(id, "alleati").size() < 3:
			var uid := _nuova_unita("JUG", "f", id, true)
			s["u"][uid]["par"] = true
			s["ctrl"][id] = "alleati"
			return

## Fine del turno di un lato: controllo, rifornimento, rese, passaggio al lato successivo.
func _fine_lato() -> void:
	var lato: String = s["lato"]
	_aggiorna_controllo_occupazione(lato)
	invalida()
	# armate senza linea di rifornimento eliminate
	var via := []
	for uid in s["u"]:
		if lato_di(uid) == lato and not ha_rifornimento(uid):
			via.append(uid)
	for uid in via:
		_log("%s a %s è senza rifornimento ed è eliminata." % [maiuscola(nome_unita(uid)), D.nome(s["u"][uid]["h"])])
		s["u"].erase(uid)
	invalida()
	_controlla_rese(lato)
	if lato == "alleati":
		s["atlantico"] = 0
		s["atlantico_av"] = false
	if finita():
		return
	# lato successivo
	var ordine := ["asse", "alleati", "urss"]
	var i := ordine.find(lato)
	while true:
		i += 1
		if i >= 3:
			if int(s["turno"]) >= Dati.ULTIMO_TURNO:
				_fine_partita("asse", "La Germania non si è arresa: vince l'Asse.")
				return
			s["turno"] = int(s["turno"]) + 1
			s["attaccati_alleati"] = []
			i = 0
			_log("[b]%s.[/b]" % data_testo())
		var l: String = ordine[i]
		if l == "urss" and s["arresi"].has("URSS"):
			continue
		s["lato"] = l
		break
	_inizio_lato()

func _fine_partita(vince: String, testo: String) -> void:
	s["finita"] = true
	s["esito"] = vince
	s["esito_testo"] = testo
	_log("[b]%s[/b]" % testo)

## aree occupate da sole armate di un lato passano al suo controllo
func _aggiorna_controllo_occupazione(lato: String) -> void:
	var presenti := {}
	for uid in s["u"]:
		var u: Dictionary = s["u"][uid]
		if not presenti.has(u["h"]):
			presenti[u["h"]] = {}
		presenti[u["h"]][D.LATO_NAZ[u["naz"]]] = true
	for id in presenti:
		var p: Dictionary = presenti[id]
		if p.has(lato) and p.size() == 1 and s["ctrl"][id] != lato:
			_cambia_controllo(id, lato)

func _cambia_controllo(id: String, lato: String) -> void:
	var prima: String = s["ctrl"][id]
	if prima == lato:
		return
	s["ctrl"][id] = lato
	invalida()
	# l'Africa del Nord francese neutrale: al primo ingresso alleato Tunisi e Mareth vanno all'Asse
	if s["afn_neutrale"] and D.nazione(id) == "AFN" and lato == "alleati":
		s["afn_neutrale"] = false
		for x in ["tunisi", "mareth"]:
			if s["ctrl"][x] == "":
				s["ctrl"][x] = "asse"
		for x in D.aree_di("AFN"):
			if s["ctrl"][x] == "":
				s["ctrl"][x] = "alleati"
		_log("Gli Alleati sbarcano nell'Africa del Nord francese: Tunisi e Mareth passano all'Asse.")

func _controlla_rese(lato: String) -> void:
	var t := int(s["turno"])
	# Francia: alla fine del suo turno
	if lato == "alleati" and not s["arresi"].has("FRA") and s["arresi"].has("BEL"):
		var aree_ted := {}
		for uid in s["u"]:
			var u: Dictionary = s["u"][uid]
			if u["naz"] == "GER" and D.nazione(u["h"]) == "FRA":
				aree_ted[u["h"]] = true
		if aree_ted.size() >= 3:
			_resa("FRA", "asse")
	# Belgio e Italia: due armate nemiche nel paese
	for naz in ["BEL", "ITA"]:
		if s["arresi"].has(naz):
			continue
		var nem := 0
		var l: String = D.LATO_NAZ[naz]
		for uid in s["u"]:
			var u: Dictionary = s["u"][uid]
			if D.nazione(u["h"]) == naz and u["h"] != "albania" and nemici(l, D.LATO_NAZ[u["naz"]]):
				nem += 1
		if nem >= 2:
			_resa(naz, "asse" if l != "asse" else lato)
	# nazioni minori: capitale in mano nemica
	for naz in ["FIN", "ROM", "UNG", "BUL", "GRE", "JUG"]:
		if s["arresi"].has(naz):
			continue
		var cap := D.capitale(naz)
		var l: String = D.LATO_NAZ[naz]
		if nemici(l, s["ctrl"][cap]):
			_resa(naz, s["ctrl"][cap])
	for naz in ["NOR", "DAN"]:
		var cap := D.capitale(naz)
		if not s["arresi"].has(naz) and s["ctrl"][cap] != "":
			s["arresi"][naz] = true
			_log("%s si arrende: passa sotto il controllo %s." % [Dati.NOME_NAZ[naz], "dell'Asse" if s["ctrl"][cap] == "asse" else "degli Alleati"])
			for id in D.aree_di(naz):
				if s["ctrl"][id] == "":
					s["ctrl"][id] = s["ctrl"][cap]
	# Germania e URSS: tutte le aree di rifornimento
	if not s["arresi"].has("URSS"):
		var tutte := true
		for id in D.sedi_costruzione("URSS"):
			if s["ctrl"][id] != "asse":
				tutte = false
		if tutte:
			_resa("URSS", "asse")
	var tutte_g := true
	for id in D.sedi_costruzione("GER"):
		if s["ctrl"][id] == "asse":
			tutte_g = false
	if tutte_g:
		s["arresi"]["GER"] = true
		if t >= Dati.ULTIMO_TURNO:
			_fine_partita("pari", "La Germania si arrende nell'ultimo turno: la partita è pari.")
		else:
			_fine_partita("alleati", "La Germania si arrende: vincono gli Alleati e l'Unione Sovietica.")

func _resa(naz: String, vincitore: String) -> void:
	s["arresi"][naz] = true
	s["guerra"][naz] = false
	var l: String = D.LATO_NAZ[naz]
	_log("[b]%s si arrende.[/b]" % Dati.NOME_NAZ[naz])
	var via := []
	for uid in s["u"]:
		if s["u"][uid]["naz"] == naz:
			via.append(uid)
	for uid in via:
		s["u"].erase(uid)
	var aree := D.aree_di(naz)
	if naz == "ITA":
		aree.erase("albania")
		aree.append("albania")
	for id in aree:
		if not unita_in(id, l).is_empty():
			continue
		if naz == "FRA" and false:
			pass
		s["ctrl"][id] = vincitore
	if naz == "FRA":
		# l'Africa del Nord francese diventa neutrale; l'Italia entra in guerra
		for id in D.aree_di("AFN"):
			if unita_in(id, "alleati").is_empty():
				s["ctrl"][id] = ""
		s["afn_neutrale"] = true
		_entra_in_guerra("ITA", "dopo la resa della Francia")
	if naz == "URSS":
		for id in D.aree_di("URSS"):
			s["ctrl"][id] = "asse"
	invalida()

# =====================================================================================
# Linee di rifornimento
# =====================================================================================

func _fonti(lato: String) -> Array:
	var out := []
	for id in D.aree:
		if str(D.aree[id].get("rif", "")) == lato and s["ctrl"][id] == lato:
			out.append(id)
	return out

func _attraversabile(id: String, lato: String, blitz: bool, occupate: Dictionary) -> bool:
	if s["ctrl"][id] == lato:
		return blitz or not occupate.get(id, {}).has("nem")
	return blitz and occupate.get(id, {}).has("mie")

## insieme delle aree raggiunte dalla rete di rifornimento a partire dalle fonti date
func _rete(lato: String, fonti: Array) -> Dictionary:
	var blitz := ha(lato, "blitzkrieg")
	var occ := {}
	for uid in s["u"]:
		var u: Dictionary = s["u"][uid]
		var l2: String = D.LATO_NAZ[u["naz"]]
		if not occ.has(u["h"]):
			occ[u["h"]] = {}
		if l2 == lato:
			occ[u["h"]]["mie"] = true
		elif nemici(lato, l2):
			occ[u["h"]]["nem"] = true
	var R := {}
	var coda := []
	for f in fonti:
		if s["ctrl"][f] == lato:
			R[f] = true
			coda.append(f)
	var mari_visti := {}
	while not coda.is_empty():
		var x: String = coda.pop_back()
		for y in D.aree[x]["vicini"]:
			if R.has(y) or not _attraversabile(y, lato, blitz, occ):
				continue
			R[y] = true
			coda.append(y)
		# per mare, fra aree costiere controllate
		if s["ctrl"][x] != lato or not _attraversabile(x, lato, blitz, occ):
			continue
		for m in D.aree[x]["mari"]:
			if not _mare_ok(lato, m) or mari_visti.has(m):
				continue
			for m2 in D.mari_collegati(lato, m):
				if not _mare_ok(lato, m2) or mari_visti.has(m2):
					continue
				mari_visti[m2] = true
				for y in D.aree:
					if R.has(y) or not (m2 in D.aree[y]["mari"]) or s["ctrl"][y] != lato:
						continue
					if lato == "asse" and D.nazione(y) == "EGI":
						continue
					R[y] = true
					if _attraversabile(y, lato, blitz, occ):
						coda.append(y)
	return R

func _mare_ok(lato: String, m: String) -> bool:
	if lato == "asse" and m == "Mar Nero":
		return false
	if lato == "urss" and m == "Baltico":
		return false
	return true

func _rete_lato(lato: String, naz: String) -> Dictionary:
	var k := lato + ":" + naz
	if _cache_rif.has(k):
		return _cache_rif[k]
	var fonti := _fonti(lato)
	var cap := D.capitale(naz)
	if cap != "" and s["ctrl"][cap] == lato:
		fonti.append(cap)
	var R := _rete(lato, fonti)
	_cache_rif[k] = R
	return R

func ha_rifornimento(uid: String) -> bool:
	var u: Dictionary = s["u"][uid]
	if u.get("par", false) or u.get("anf", false):
		return true
	var lato := lato_di(uid)
	var R := _rete_lato(lato, u["naz"])
	var h: String = u["h"]
	if R.has(h):
		return true
	for v in D.aree[h]["vicini"]:
		if R.has(v):
			return true
	return false

# =====================================================================================
# Movimento
# =====================================================================================

## l'armata può fare un'operazione in questo turno? Restituisce "" oppure il motivo per cui non può.
func perche_ferma(uid: String) -> String:
	if not s["u"].has(uid):
		return "armata inesistente"
	var u: Dictionary = s["u"][uid]
	var lato := lato_di(uid)
	if lato != s["lato"]:
		return "non è il tuo turno"
	if s["fase"] != "operazioni":
		return "le operazioni sono finite: dopo i combattimenti non si spendono rifornimenti"
	if u["op"] != "":
		return "ha già fatto un'operazione in questo turno"
	if not u.get("rif", true):
		return "non aveva la linea di rifornimento a inizio turno"
	if not s["guerra"].get(u["naz"], false) and not u.get("par", false):
		return "%s non è ancora in guerra" % Dati.NOME_NAZ[u["naz"]]
	if lato == "alleati" and int(s["turno"]) == 1 and int(s["attacco_ovest"]) != 1:
		return "nel primo turno gli Alleati non si muovono, se la Germania non attacca Francia o Belgio"
	return ""

func _bloccata_pre_barbarossa(uid: String) -> bool:
	if lato_di(uid) != "urss" or int(s["barbarossa"]) > 0 or int(s["turno"]) >= 9:
		return false
	var h: String = s["u"][uid]["h"]
	if h == "kiev":
		return true
	for v in D.aree[h]["vicini"]:
		if D.nazione(v) in ["GER", "ROM"] and s["ctrl"][v] == "asse":
			return true
	return false

## l'armata può entrare in quest'area per ragioni politiche (neutrali, restrizioni nazionali)?
func puo_entrare(uid: String, id: String) -> bool:
	var u: Dictionary = s["u"][uid]
	var naz: String = u["naz"]
	var lato := lato_di(uid)
	var c: String = s["ctrl"][id]
	var nid := D.nazione(id)
	var casa := D.patria(id)
	var t := int(s["turno"])
	# aree del lato amico ma diverso (Alleati / URSS) chiuse
	if c != lato and c != "" and not nemici(lato, c):
		return false
	for o in unita_in(id):
		var lo := lato_di(o)
		if lo != lato and not nemici(lato, lo):
			return false
	# paesi neutrali non ancora in guerra
	if c == "" and nid == "AFN" and lato != "alleati":
		return false
	if casa in ["BEL", "ITA", "ROM", "UNG", "BUL", "GRE", "JUG"] and not s["guerra"][casa] and not s["arresi"].has(casa):
		if D.LATO_NAZ[casa] == lato:
			return false
	if lato == "urss" and nid == "AFN":
		return false
	# restrizioni politiche
	if u.get("par", false):
		return nid == "JUG"
	match naz:
		"FIN":
			return nid == "FIN"
		"BEL", "GRE", "JUG":
			return nid == naz
		"BUL":
			return nid in ["BUL", "GRE", "JUG"]
		"ROM", "UNG":
			return nid == naz or nid == "URSS"
		"ITA":
			if casa == "ITA" or nid == "GRE" or nid in ["LIB", "EGI", "AFN"]:
				return true
			if nid == "JUG" and Dati.anno(t) >= 1941:
				return true
			if s["tot"]["asse"]:
				var n := 0
				for o in s["u"]:
					var ou: Dictionary = s["u"][o]
					if ou["naz"] == "ITA" and (D.patria(ou["h"]) == "ITA" or D.nazione(ou["h"]) in ["GRE", "JUG", "LIB", "EGI", "AFN"]):
						n += 1
				return n >= 4
			return false
		"GER":
			if Dati.anno(t) < 1941 and (nid in ["FIN", "GRE", "LIB", "EGI", "AFN"]):
				return false
			if nid == "ROM" and not s["tot"]["asse"]:
				if u["t"] != "f":
					return false
				for o in s["u"]:
					if o != uid and s["u"][o]["naz"] == "GER" and D.nazione(s["u"][o]["h"]) == "ROM":
						return false
	return true

func _limite_pila(id: String) -> int:
	return 99 if D.america(id) else 3

## aree in cui un attacco già dichiarato permette lo sfruttamento dei corazzati
func aree_sfruttamento(uid: String) -> Dictionary:
	var out := {}
	var lato := lato_di(uid)
	if not ha(lato, "blitzkrieg") or not Dati.corazzata(s["u"][uid]["t"]):
		return out
	for i in s["attacchi"].size():
		var at: Dictionary = s["attacchi"][i]
		if at["a"] == uid or uid in at["sup"]:
			continue
		var area: String = at["h"]
		if not D.africa(area) and (not D.pianura(area) or D.fortezza(area)):
			continue
		var v := valuta_attacco(i)
		if int(v["att"]) - int(v["dif"]) >= 4:
			out[area] = true
	return out

## Movimento tattico: destinazioni -> {"da": area precedente, "passi": n, "via": [aree attraversate], "sfr": bool}
func mosse_tattiche(uid: String, con_attacco := false) -> Dictionary:
	var u: Dictionary = s["u"][uid]
	var lato := lato_di(uid)
	var portata := (4 if Dati.corazzata(u["t"]) else 3) - (1 if con_attacco else 0)
	var start: String = u["h"]
	var ristretto := not nemici_in(start, lato).is_empty()
	var sfr := aree_sfruttamento(uid)
	var bloccata := _bloccata_pre_barbarossa(uid)
	var out := {}
	# stato: [area, passi, sfruttata] ; chiave area+flag
	var visti := {start + ":0": true}
	var prec := {}
	var coda := [[start, 0, 0]]
	var qi := 0
	while qi < coda.size():
		var cur: Array = coda[qi]
		qi += 1
		var x: String = cur[0]
		var p: int = cur[1]
		var fl: int = cur[2]   # 0 normale, 1 ha appena attraversato un'area di sfruttamento
		if p >= portata:
			continue
		for y in D.aree[x]["vicini"]:
			if not puo_entrare(uid, y):
				continue
			var nem_y := not nemici_in(y, lato).is_empty()
			if D.confine(y, x).has("a") and nem_y:
				continue
			if bloccata and s["ctrl"][y] != "asse":
				continue
			if ristretto and fl == 0 and (s["ctrl"][y] != lato or nem_y):
				continue
			if fl == 1 and s["ctrl"][y] == lato:
				continue
			var k: String = str(y) + ":" + str(fl)
			if visti.has(k):
				continue
			visti[k] = true
			prec[k] = x + ":" + str(fl)
			# destinazione possibile
			var pieno := unita_in(y, lato).size() >= _limite_pila(y)
			if not pieno and y != start and not out.has(y):
				var via := []
				var kk: String = k
				while prec.has(kk):
					var pa: String = prec[kk]
					var an: String = pa.split(":")[0]
					if an == start:
						break
					via.push_front(an)
					kk = pa
				out[y] = {"da": x, "passi": p + 1, "via": via, "sfr": fl == 1}
			# si prosegue?
			if fl == 1:
				continue
			if nem_y:
				if sfr.has(y) and not ristretto:
					coda.append([y, p + 1, 1])
				continue
			coda.append([y, p + 1, 0])
	return out

func mosse_strategiche(uid: String) -> Dictionary:
	var u: Dictionary = s["u"][uid]
	var lato := lato_di(uid)
	var start: String = u["h"]
	var out := {}
	if s["ctrl"][start] != lato or _bloccata_pre_barbarossa(uid):
		return out
	var limite_urss := lato == "asse" and int(s["strat_urss"]) >= 2
	var visti := {start: true}
	var coda := [start]
	while not coda.is_empty():
		var x: String = coda.pop_front()
		for y in D.aree[x]["vicini"]:
			if visti.has(y) or s["ctrl"][y] != lato or not puo_entrare(uid, y):
				continue
			if limite_urss and D.nazione(y) == "URSS":
				continue
			if D.confine(y, x).has("a") and not nemici_in(y, lato).is_empty():
				continue
			visti[y] = true
			coda.append(y)
			if unita_in(y, lato).size() < _limite_pila(y):
				out[y] = {"da": x}
	return out

func mosse_navali(uid: String) -> Dictionary:
	var u: Dictionary = s["u"][uid]
	var lato := lato_di(uid)
	var start: String = u["h"]
	var out := {}
	if s["ctrl"][start] != lato or not D.costiera(start) or _bloccata_pre_barbarossa(uid):
		return out
	for y in D.aree:
		if y == start or s["ctrl"][y] != lato or not D.costiera(y) or not puo_entrare(uid, y):
			continue
		if unita_in(y, lato).size() >= _limite_pila(y):
			continue
		var c := _costo_mare(lato, start, y)
		if c > 0:
			out[y] = {"costo": c}
	return out

## 1 se le due aree condividono un mare, 2 se servono più mari, 0 se non collegate
func _costo_mare(lato: String, a: String, b: String) -> int:
	var ma: Array = D.aree[a]["mari"]
	var mb: Array = D.aree[b]["mari"]
	for m in ma:
		if m in mb and _mare_ok_movimento(lato, m):
			return 1
	for m in ma:
		if not _mare_ok_movimento(lato, m):
			continue
		var coll := D.mari_collegati(lato, m)
		for m2 in mb:
			if m2 in coll and _mare_ok_movimento(lato, m2):
				return 2
	return 0

func _mare_ok_movimento(lato: String, m: String) -> bool:
	return not (lato == "asse" and m == "Mar Nero")

func mosse_anfibie(uid: String) -> Dictionary:
	var u: Dictionary = s["u"][uid]
	var lato := lato_di(uid)
	var start: String = u["h"]
	var out := {}
	if s["ctrl"][start] != lato or _bloccata_pre_barbarossa(uid):
		return out
	var sv := ha(lato, "sbarchi")
	if not sv and u["t"] != "f":
		return out
	var t := int(s["turno"])
	var inv := Dati.inverno(t)
	var max_ll := (4 if Dati.anno(t) >= 1944 else 3) if sv else 1
	for ll in D.linee_sbarco:
		if ll[0] != start:
			continue
		var y: String = ll[1]
		if inv and not ([start, y] in D.linee_med):
			continue
		if int(s["sbarchi"]) >= max_ll:
			continue
		if y == "trondheim" and int(s["sbarchi_tr"]) >= 1:
			continue
		if _destinazione_sbarco_ok(uid, y):
			out[y] = {"tipo": "ll"}
	if sv and int(s["sbarchi_d"]) < 1 and not inv:
		for y in D.sbarchi_d:
			if out.has(y):
				continue
			var prov: Array = D.sbarchi_d[y]
			var ok := false
			if "america" in prov and D.america(start):
				ok = true
			if "uk" in prov and D.nazione(start) == "GB" and not D.america(start):
				ok = true
			if start in prov:
				ok = true
			if ok and _destinazione_sbarco_ok(uid, y):
				out[y] = {"tipo": "d"}
	return out

func _destinazione_sbarco_ok(uid: String, y: String) -> bool:
	var lato := lato_di(uid)
	if s["ctrl"][y] == lato or not puo_entrare(uid, y):
		return false
	return unita_in(y, lato).size() < _limite_pila(y)

## costo in rifornimenti di un'operazione per l'armata in un'area di destinazione
func costo_operazione(uid: String, modo: String, dest: String, extra_mare := 1) -> int:
	var lato := lato_di(uid)
	var t := int(s["turno"])
	var c := 1
	if modo == "anfibio":
		c = 2
	elif modo == "navale":
		c = extra_mare
	var h: String = s["u"][uid]["h"]
	if lato == "alleati" and t <= 4 and int(s["attacco_ovest"]) == t and modo in ["tattico", "attacco"]:
		if D.nazione(dest) in ["FRA", "BEL"] or D.nazione(h) in ["FRA", "BEL"]:
			c = maxi(c, 2)
	if lato == "urss" and int(s["barbarossa"]) == t and t < 9:
		c = maxi(c, 2)
	if lato == "asse":
		if t == 9 and (D.nazione(dest) == "URSS" or D.nazione(h) == "URSS"):
			c = maxi(c, 2)
		if D.aree[dest].has("est") or D.aree[h].has("est"):
			c = maxi(c, 2)
	return c

# =====================================================================================
# Combattimento
# =====================================================================================

## punteggi dell'attacco i (senza dadi): {att, dif, dett}
func valuta_attacco(i: int) -> Dictionary:
	var at: Dictionary = s["attacchi"][i]
	var a: String = at["a"]
	var d: String = at["d"]
	if not s["u"].has(a) or not s["u"].has(d):
		return {"att": 0, "dif": 0, "dett": ""}
	var h: String = at["h"]
	var fa := fattore_unita(a)
	var sup := 0
	for x in at["sup"]:
		if s["u"].has(x):
			sup += Dati.sostegno(s["u"][x]["r"])
	var aereo := 2 if int(at.get("aereo", 0)) > 0 else 0
	var fd := fattore_unita(d)
	var bon := bonus_difesa(d, h, str(at.get("da", "")), bool(at.get("anf", false)))
	var dett := "attacco %d%s%s, difesa %d%s" % [fa, " + %d sostegno" % sup if sup > 0 else "", " + 2 aereo" if aereo > 0 else "",
		fd, " + %d terreno e confini" % bon if bon > 0 else ""]
	return {"att": fa + sup + aereo, "dif": fd + bon, "dett": dett}

func bonus_difesa(d: String, h: String, da: String, anf: bool) -> int:
	var lato_d := lato_di(d)
	var b := 0
	for t in D.terreni(h):
		b += 1
	if D.fortezza(h) and s["ctrl"][h] == lato_d:
		if D.nazione(h) != "URSS" or lato_d == "urss":
			b += 1
	if anf:
		b += 1
	elif da != "":
		var c := D.confine(h, da)
		if c.has("f"):
			b += 1
		if c.has("s"):
			b += 1
		if c.has("l"):
			b += 2
	if s["u"][d]["naz"] == "ITA":
		for o in unita_in(h, "asse"):
			if s["u"][o]["naz"] == "GER":
				b += 1
				break
	return b

func _dado(uid: String) -> int:
	var x := rng.randi_range(1, 6)
	s["tiri"] = int(s["tiri"]) + 1
	var u: Dictionary = s["u"][uid]
	var h: String = u["h"]
	if x <= 2:
		if u["naz"] == "GER" and Dati.corazzata(u["t"]) and D.nazione(h) == "URSS":
			var tr := D.terreni(h)
			if not ("foresta" in tr or "palude" in tr or "montagna" in tr):
				return 3
		if D.africa(h) and (u["t"] == "k" or (u["naz"] == "GB" and Dati.corazzata(u["t"]))):
			return 3
	return x

func _perdita(uid: String) -> String:
	if not s["u"].has(uid):
		return ""
	var u: Dictionary = s["u"][uid]
	if u["r"]:
		s["u"].erase(uid)
		invalida()
		return "eliminata"
	u["r"] = true
	return "ridotta"

func _risolvi_attacco(i: int) -> void:
	var at: Dictionary = s["attacchi"][i]
	var a: String = at["a"]
	var d: String = at["d"]
	if not s["u"].has(a) or not s["u"].has(d):
		return
	if s["u"][d]["h"] != at["h"]:
		return
	var v := valuta_attacco(i)
	var na := nome_unita(a)
	var nd := nome_unita(d)
	var da := _dado(a)
	var dd := _dado(d)
	var pa := int(v["att"]) + da
	var pd := int(v["dif"]) + dd
	var rid_a: bool = s["u"][a]["r"]
	var rid_d: bool = s["u"][d]["r"]
	var esito := ""
	var ra := ""
	var rd := ""
	if pa > pd:
		rd = _perdita(d)
		rd = _perdita(d) if rd == "ridotta" else rd
		if not rid_d and pa < 2 * pd:
			ra = _perdita(a)
		esito = "vince l'attaccante"
	elif pd > pa:
		ra = _perdita(a)
		ra = _perdita(a) if ra == "ridotta" else ra
		if not rid_a and pd < 2 * pa:
			rd = _perdita(d)
		esito = "vince il difensore"
	else:
		ra = _perdita(a)
		rd = _perdita(d)
		esito = "pareggio"
	s["ultimo_tiro"] = {"n": int(s["tiri"]), "h": at["h"], "att": int(v["att"]), "dif": int(v["dif"]), "da": da, "dd": dd,
		"pa": pa, "pd": pd, "esito": esito, "ra": ra, "rd": rd, "na": na, "nd": nd, "lato": lato_di(a) if s["u"].has(a) else s["lato"]}
	var txt := "Combattimento a %s: %s (%d + dado %d = %d) contro %s (%d + dado %d = %d): %s." % [D.nome(at["h"]), na, int(v["att"]), da, pa,
		nd, int(v["dif"]), dd, pd, esito]
	if ra != "":
		txt += " Attaccante %s." % ra
	if rd != "":
		txt += " Difensore %s." % rd
	_log(txt)

## alla fine delle operazioni: controllo delle aree attraversate, contrasto aereo, combattimenti
func _combatti() -> Dictionary:
	if s["combattuto"]:
		return {"ok": false, "msg": "i combattimenti sono già stati risolti"}
	var lato: String = s["lato"]
	# cambi di controllo dovuti al movimento
	for id in s["ctrl_pend"]:
		if nemici_in(id, lato).is_empty():
			_cambia_controllo(id, lato)
	s["ctrl_pend"] = {}
	# contrasto aereo: si chiede ai difensori
	var da_chiedere := []
	for l in Dati.LATI:
		if not nemici(lato, l):
			continue
		if _missioni_contrastabili(l).size() > 0 and int(s["aerei"][l]) > 0:
			da_chiedere.append(l)
	if not da_chiedere.is_empty():
		s["attesa"] = {"k": "contrasto", "g": da_chiedere[0], "coda": da_chiedere.slice(1)}
		return {"ok": true, "attesa": true}
	_risolvi_combattimenti()
	return {"ok": true}

## missioni dell'attaccante che il lato l può contrastare: [indice attacco] (-1 = bombardamento)
func _missioni_contrastabili(l: String) -> Array:
	var out := []
	var lato: String = s["lato"]
	var av_att := ha(lato, "aviazione_av")
	var av_dif := ha(l, "aviazione_av")
	if av_att and not av_dif:
		return out
	for i in s["attacchi"].size():
		var at: Dictionary = s["attacchi"][i]
		if int(at.get("aereo", 0)) > 0 and s["u"].has(at["d"]) and lato_di(at["d"]) == l:
			out.append(i)
	if l == "asse" and int(s["bomb"]) > 0 and av_dif:
		out.append(-1)
	return out

func _risolvi_combattimenti() -> void:
	var lato: String = s["lato"]
	s["combattuto"] = true
	s["fase"] = "dopo"
	for i in s["attacchi"].size():
		_risolvi_attacco(i)
		var at: Dictionary = s["attacchi"][i]
		if lato == "alleati":
			s["attaccati_alleati"].append(at["d"])
	# missioni aeree usate tornano disponibili (sono già state tolte dalla scorta)
	# bombardamento strategico
	if lato == "alleati" and int(s["bomb"]) > 0:
		if int(s["bomb"]) >= 2:
			s["pen_asse"] = 1
			_log("Il bombardamento strategico riesce: l'Asse avrà un'azione in meno nel prossimo turno.")
		else:
			_log("Il bombardamento strategico non basta.")
		s["bomb"] = 0
	_aggiorna_controllo_occupazione(lato)
	invalida()

# =====================================================================================
# Applicazione delle decisioni
# =====================================================================================

func applica(d: Dictionary) -> Dictionary:
	if finita():
		return {"ok": false, "msg": "partita finita"}
	var t: String = str(d.get("t", ""))
	if s.has("attesa"):
		if t != "contrasta":
			return {"ok": false, "msg": "si attende la decisione sul contrasto aereo"}
		return _contrasta(d)
	var r: Dictionary
	match t:
		"azione":
			r = _azione(str(d.get("a", "")), str(d.get("x", "")))
		"muovi":
			r = _muovi(str(d.get("u", "")), str(d.get("h", "")), str(d.get("m", "tattico")), str(d.get("att", "")), int(d.get("sup", -1)))
		"attacca":
			r = _attacca(str(d.get("u", "")), str(d.get("d", "")))
		"sostieni":
			r = _sostieni(str(d.get("u", "")), int(d.get("i", -1)))
		"annulla_attacco":
			r = _annulla_attacco(int(d.get("i", -1)))
		"aereo":
			r = _aereo(int(d.get("i", -1)), bool(d.get("via", false)))
		"bombarda":
			r = _bombarda(int(d.get("n", 0)))
		"sub":
			r = _sottomarini(int(d.get("n", 0)))
		"costruisci":
			r = _costruisci(str(d.get("naz", "")), str(d.get("tipo", "f")), str(d.get("h", "")), bool(d.get("ridotta", false)))
		"potenzia":
			r = _potenzia(str(d.get("u", "")))
		"converti":
			r = _converti(str(d.get("u", "")), str(d.get("tipo", "a")))
		"smonta":
			r = _smonta(str(d.get("u", "")))
		"elimina":
			r = _elimina(str(d.get("u", "")))
		"combatti":
			if s["fase"] != "operazioni":
				r = {"ok": false, "msg": "combattimenti già risolti"}
			else:
				r = _combatti()
		"fine":
			if s["fase"] == "operazioni":
				r = _combatti()
				if r.get("attesa", false):
					s["fine_dopo"] = true
					return r
			_fine_lato()
			r = {"ok": true}
		_:
			r = {"ok": false, "msg": "decisione sconosciuta"}
	invalida()
	return r

func _contrasta(d: Dictionary) -> Dictionary:
	var a: Dictionary = s["attesa"]
	var l: String = a["g"]
	var possibili := _missioni_contrastabili(l)
	var lista: Array = d.get("lista", [])
	var usate := 0
	var doppie := 0
	for x in lista:
		var i := int(x)
		if not (i in possibili) or int(s["aerei"][l]) <= 0:
			continue
		if i == -1:
			var n := int(d.get("sb", 1))
			for k in n:
				if int(s["aerei"][l]) <= 0 or int(s["bomb"]) <= 0:
					break
				s["aerei"][l] = int(s["aerei"][l]) - 1
				var tolte := 2 if doppie < 2 else 1
				doppie += 1
				s["bomb"] = maxi(0, int(s["bomb"]) - tolte)
				usate += 1
			continue
		s["aerei"][l] = int(s["aerei"][l]) - 1
		s["attacchi"][i]["aereo"] = 0
		usate += 1
	if usate > 0:
		_log("%s contrasta %d missioni aeree nemiche." % [Dati.NOME_LATO[l], usate])
	var coda: Array = a.get("coda", [])
	s.erase("attesa")
	if not coda.is_empty():
		s["attesa"] = {"k": "contrasto", "g": coda[0], "coda": coda.slice(1)}
		return {"ok": true, "attesa": true}
	_risolvi_combattimenti()
	if s.get("fine_dopo", false):
		s.erase("fine_dopo")
		_fine_lato()
	return {"ok": true}

func missioni_da_contrastare(l: String) -> Array:
	return _missioni_contrastabili(l)

# ---------- azioni ----------

func azioni_rimaste() -> int:
	return int(s["az"]["max"]) - int(s["az"]["usate"])

## limite di azioni dello stesso tipo
func limite_tipo(a: String) -> int:
	var lato: String = s["lato"]
	var t := int(s["turno"])
	if lato == "alleati" and s["tot"]["alleati"] and a != "prestito":
		return 2
	if lato == "urss" and int(s["prestito"]) == t:
		if a == "sviluppo" and Dati.anno(t) == 1943:
			return 2
		if a == "rifornimento" and Dati.anno(t) == 1944:
			return 2
	return 1

## "" se l'azione si può fare, altrimenti il motivo
func perche_no_azione(a: String, x := "") -> String:
	var lato: String = s["lato"]
	var t := int(s["turno"])
	if azioni_rimaste() <= 0:
		return "nessuna azione rimasta"
	if int(s["az"]["tipi"].get(a, 0)) >= limite_tipo(a):
		return "azione già fatta in questo turno"
	match a:
		"rifornimento":
			if s["fase"] != "operazioni":
				return "dopo i combattimenti i rifornimenti non servono più"
		"rinforzi":
			pass
		"corazzati":
			pass
		"aerei":
			if not ha(lato, "aviazione"):
				return "serve lo sviluppo Aviazione"
			if int(s["aerei"][lato]) >= max_aerei(lato):
				return "tutte le pedine delle missioni sono già in gioco"
		"sottomarini":
			if lato != "asse":
				return "solo l'Asse"
			if int(s["sub"]) >= Dati.MAX_SUB:
				return "tutte le pedine sottomarine sono già in gioco"
		"sviluppo":
			if lato == "alleati" and Dati.anno(t) == 1940:
				return "gli Alleati non sviluppano nel 1940"
			if x == "":
				return "scegli lo sviluppo"
			return perche_no_sviluppo(x)
		"prestito":
			if lato != "alleati":
				return "solo gli Alleati"
			if s["arresi"].has("URSS"):
				return "l'URSS si è arresa"
			if t > 20:
				return "solo fino al 1944"
			var ok: bool = t >= 10 or (int(s["barbarossa"]) > 0 and (Dati.anno(t) >= 1942 or s["ctrl"]["carelia"] == "urss"))
			if not ok:
				return "dopo Barbarossa (nel 1941 l'URSS deve controllare la Carelia) o dalla primavera 1942"
			if int(s["prestito"]) == t:
				return "già fatto"
	return ""

func max_aerei(lato: String) -> int:
	if lato == "alleati":
		return Dati.MAX_AEREI["alleati_gb"] + (Dati.MAX_AEREI["alleati_usa"] if s["guerra"]["USA"] else 0)
	return Dati.MAX_AEREI[lato]

func perche_no_sviluppo(x: String) -> String:
	var lato: String = s["lato"]
	if not Dati.SVILUPPI.has(x) or not (lato in Dati.SVILUPPI[x]["lati"]):
		return "sviluppo non disponibile"
	var st := int(s["svil"][lato].get(x, 0))
	if st >= 2:
		return "già sviluppato"
	if st == 1 and int(s["svil"][lato].get(x + "_t", 0)) == int(s["turno"]):
		return "avviato in questo turno: si completa in un turno successivo"
	var anni: Dictionary = Dati.ANNO_SVILUPPO.get(x, {})
	var minimo := int(anni.get(lato, anni.get("*", 0)))
	if anno() < minimo:
		return "non prima del %d" % minimo
	if lato == "urss" and x in Dati.RICHIEDE_URALI and not ha("urss", "urali"):
		return "serve prima l'Industria degli Urali"
	return ""

func _azione(a: String, x: String) -> Dictionary:
	var lato: String = s["lato"]
	var perche := perche_no_azione(a, x)
	if perche != "":
		return {"ok": false, "msg": perche}
	s["az"]["usate"] = int(s["az"]["usate"]) + 1
	s["az"]["tipi"][a] = int(s["az"]["tipi"].get(a, 0)) + 1
	s["azioni_fatte"].append(a if a != "sviluppo" else "sviluppo:" + x)
	var nl: String = Dati.NOME_LATO[lato]
	match a:
		"rifornimento":
			var n := 7 if ha(lato, "logistica") else 5
			var extra := ""
			if lato == "asse":
				if nemici("asse", s["ctrl"]["bucarest"]):
					n -= 2
					extra = ", Bucarest perduta"
				if s["ctrl"]["groznyj"] == "asse":
					n += 2
					extra += ", petrolio di Groznyj"
			elif lato == "urss" and s["ctrl"]["baku"] == "asse":
				n -= 2
				extra = ", Baku perduta"
			elif lato == "alleati" and s["ctrl"]["suez"] == "asse" and anno() <= 1943:
				n -= 2
				extra = ", Suez perduta"
			var prima := int(s["rif"][lato])
			_aggiungi_rif(lato, n)
			_log("%s: Rifornimento, +%d%s (ora %d)." % [nl, int(s["rif"][lato]) - prima, extra, int(s["rif"][lato])])
		"rinforzi":
			var p := punti_rinforzo(lato)
			s["punti"] = int(s["punti"]) + p
			_log("%s: Rinforzi, %d punti da spendere in questo turno." % [nl, p])
		"corazzati":
			var n := 5 if ha(lato, "ind_carri") else 3
			s["cor"][lato] = mini(int(s["cor"][lato]) + n, Dati.MAX_COR)
			_log("%s: Produzione corazzati, %d passi (ora %d)." % [nl, n, int(s["cor"][lato])])
		"aerei":
			var n := 4 if ha(lato, "ind_aerea") else 2
			s["aerei"][lato] = mini(int(s["aerei"][lato]) + n, max_aerei(lato))
			_log("%s: Missioni aeree (ora %d)." % [nl, int(s["aerei"][lato])])
		"sottomarini":
			s["sub"] = mini(int(s["sub"]) + 3, Dati.MAX_SUB)
			_log("Asse: Missioni sottomarine (ora %d)." % int(s["sub"]))
		"sviluppo":
			var st := int(s["svil"][lato].get(x, 0))
			if st == 1 or anno() >= 1944:
				s["svil"][lato][x] = 2
				_log("%s completa lo sviluppo %s." % [nl, Dati.SVILUPPI[x]["n"]])
				if x == "aviazione_av":
					_log("Le missioni aeree %s sono ora avanzate." % ("dell'Asse" if lato == "asse" else ("degli Alleati" if lato == "alleati" else "sovietiche")))
			else:
				s["svil"][lato][x] = 1
				s["svil"][lato][x + "_t"] = int(s["turno"])
				_log("%s avvia lo sviluppo %s." % [nl, Dati.SVILUPPI[x]["n"]])
		"prestito":
			s["prestito"] = int(s["turno"])
			_log("Alleati: affitti e prestiti all'URSS, che avrà un'azione in più in questo turno.")
	return {"ok": true}

func punti_rinforzo(lato: String) -> int:
	var t := int(s["turno"])
	match lato:
		"asse":
			return int(ceil(4.0 - 0.5 * _chiave_perse("GER")))
		"alleati":
			return 4 if s["tot"]["alleati"] else 2
		"urss":
			if not s["tot"]["urss"]:
				return 4
			if Dati.anno(t) <= 1943:
				return int(ceil(8.0 - 0.5 * _chiave_perse("URSS")))
			return 4
	return 0

func _chiave_perse(naz: String) -> int:
	var n := 0
	for id in D.aree:
		if str(D.aree[id].get("chiave", "")) == naz and s["ctrl"][id] != D.LATO_NAZ[naz]:
			n += 1
	return n

# ---------- rinforzi delle potenze maggiori ----------

## tipi costruibili da una nazione: [[tipo, nome]]
func tipi_costruibili(naz: String) -> Array:
	var lato: String = D.LATO_NAZ[naz]
	var out := []
	for tp in D.ARMATE.get(naz, {}):
		if tp == "c" and not ha(lato, "carri_av"):
			continue
		if tp == "g" and not ha(lato, "guardie"):
			continue
		out.append(tp)
	return out

func perche_no_costruzione(naz: String, tipo: String, h: String, ridotta: bool) -> String:
	var lato: String = s["lato"]
	if not (naz in Dati.MAGGIORI) or D.LATO_NAZ[naz] != lato:
		return "nazione non valida"
	if not s["guerra"][naz] or s["arresi"].has(naz):
		return "%s non è in guerra" % Dati.NOME_NAZ[naz]
	if not (tipo in tipi_costruibili(naz)):
		return "tipo di armata non disponibile"
	if pedine_libere(naz, tipo) <= 0:
		return "nessuna pedina disponibile"
	var costo := 1 if ridotta else 2
	if int(s["punti"]) < costo:
		return "punti rinforzo insufficienti (servono %d)" % costo
	if naz == "GB" and lato == "alleati" and s["tot"]["alleati"] and int(s["punti_gb"]) + costo > 2:
		return "al massimo 2 punti per turno alla Gran Bretagna"
	if naz == "USA" and not s["tot"]["alleati"]:
		return "gli Stati Uniti non sono ancora in guerra"
	if Dati.corazzata(tipo) and int(s["cor"][lato]) < costo:
		return "passi corazzati insufficienti (servono %d)" % costo
	if not (h in D.sedi_costruzione(naz)):
		return "si costruisce solo nelle aree di rifornimento della nazione"
	if s["ctrl"][h] != lato or not nemici_in(h, lato).is_empty():
		return "area non controllata o con armate nemiche"
	if unita_in(h, lato).size() >= _limite_pila(h):
		return "area già piena (3 armate)"
	return ""

func _costruisci(naz: String, tipo: String, h: String, ridotta: bool) -> Dictionary:
	var p := perche_no_costruzione(naz, tipo, h, ridotta)
	if p != "":
		return {"ok": false, "msg": p}
	var lato: String = s["lato"]
	var costo := 1 if ridotta else 2
	s["punti"] = int(s["punti"]) - costo
	if naz == "GB":
		s["punti_gb"] = int(s["punti_gb"]) + costo
	if Dati.corazzata(tipo):
		s["cor"][lato] = int(s["cor"][lato]) - costo
	var uid := _nuova_unita(naz, tipo, h, ridotta)
	s["u"][uid]["op"] = "nuova"
	_log("Nuova %s a %s." % [nome_unita(uid), D.nome(h)])
	return {"ok": true, "u": uid}

func perche_no_potenzia(uid: String) -> String:
	if not s["u"].has(uid):
		return "armata inesistente"
	var u: Dictionary = s["u"][uid]
	var lato := lato_di(uid)
	if lato != s["lato"]:
		return "non è il tuo turno"
	if not u["r"]:
		return "l'armata è già al completo"
	if not (u["naz"] in Dati.MAGGIORI):
		return "le armate delle nazioni minori si rinforzano da sole"
	if int(s["punti"]) < 1:
		return "serve un punto rinforzo (fai l'azione Rinforzi)"
	if u["naz"] == "GB" and s["tot"]["alleati"] and int(s["punti_gb"]) >= 2:
		return "al massimo 2 punti per turno alla Gran Bretagna"
	if Dati.corazzata(u["t"]) and int(s["cor"][lato]) < 1:
		return "serve anche un passo corazzato"
	if not ha_rifornimento(uid):
		return "senza linea di rifornimento"
	return ""

func _potenzia(uid: String) -> Dictionary:
	var p := perche_no_potenzia(uid)
	if p != "":
		return {"ok": false, "msg": p}
	var u: Dictionary = s["u"][uid]
	s["punti"] = int(s["punti"]) - 1
	if u["naz"] == "GB":
		s["punti_gb"] = int(s["punti_gb"]) + 1
	if Dati.corazzata(u["t"]):
		s["cor"][lato_di(uid)] = int(s["cor"][lato_di(uid)]) - 1
	u["r"] = false
	_log("%s a %s torna al completo." % [maiuscola(nome_unita(uid)), D.nome(u["h"])])
	return {"ok": true}

func perche_no_converti(uid: String, tipo: String) -> String:
	if not s["u"].has(uid):
		return "armata inesistente"
	var u: Dictionary = s["u"][uid]
	var lato := lato_di(uid)
	if lato != s["lato"] or s["fase"] == "fine":
		return "non è il tuo turno"
	if u["t"] != "f" or not (u["naz"] in Dati.MAGGIORI):
		return "solo la fanteria delle potenze maggiori"
	if not (u["h"] in D.sedi_costruzione(u["naz"])) or s["ctrl"][u["h"]] != lato:
		return "si converte solo nelle aree di rifornimento della propria nazione"
	if not Dati.corazzata(tipo) or not (tipo in tipi_costruibili(u["naz"])):
		return "tipo non disponibile"
	if pedine_libere(u["naz"], tipo) <= 0:
		return "nessuna pedina corazzata libera"
	var costo := 1 if u["r"] else 2
	if int(s["cor"][lato]) < costo:
		return "passi corazzati insufficienti (servono %d)" % costo
	return ""

func _converti(uid: String, tipo: String) -> Dictionary:
	var p := perche_no_converti(uid, tipo)
	if p != "":
		return {"ok": false, "msg": p}
	var u: Dictionary = s["u"][uid]
	s["cor"][lato_di(uid)] = int(s["cor"][lato_di(uid)]) - (1 if u["r"] else 2)
	u["t"] = tipo
	_log("Fanteria convertita in %s a %s." % [nome_unita(uid), D.nome(u["h"])])
	return {"ok": true}

func _smonta(uid: String) -> Dictionary:
	if not s["u"].has(uid) or lato_di(uid) != s["lato"]:
		return {"ok": false, "msg": "armata non valida"}
	var u: Dictionary = s["u"][uid]
	if not Dati.corazzata(u["t"]) or u["op"] != "" or s["fase"] != "operazioni":
		return {"ok": false, "msg": "solo corazzate che non hanno ancora operato"}
	if pedine_libere(u["naz"], "f") <= 0:
		return {"ok": false, "msg": "nessuna pedina di fanteria libera"}
	u["t"] = "f"
	_log("Corazzata convertita in fanteria a %s." % D.nome(u["h"]))
	return {"ok": true}

func _elimina(uid: String) -> Dictionary:
	if not s["u"].has(uid) or lato_di(uid) != s["lato"]:
		return {"ok": false, "msg": "armata non valida"}
	if s["u"][uid]["op"] != "" or s["fase"] != "operazioni":
		return {"ok": false, "msg": "si eliminano solo armate che non hanno operato"}
	_log("%s a %s viene sciolta." % [maiuscola(nome_unita(uid)), D.nome(s["u"][uid]["h"])])
	s["u"].erase(uid)
	return {"ok": true}

# ---------- operazioni ----------

func _spendi(lato: String, n: int) -> bool:
	if int(s["rif"][lato]) < n:
		return false
	s["rif"][lato] = int(s["rif"][lato]) - n
	return true

## invasioni: entrare in un'area di un paese neutrale o della Francia/Belgio, dell'URSS, ecc.
func _effetti_ingresso(uid: String, id: String) -> void:
	var lato := lato_di(uid)
	var casa := D.patria(id)
	var t := int(s["turno"])
	if lato == "asse":
		if casa in ["FRA", "BEL"] and int(s["attacco_ovest"]) == 0:
			s["attacco_ovest"] = t
			_log("La Germania attacca a ovest.")
		if casa == "URSS" and s["ctrl"][id] == "urss":
			_barbarossa()
	if casa in ["BEL", "ITA", "ROM", "UNG", "BUL", "GRE", "JUG"] and not s["guerra"][casa] and not s["arresi"].has(casa):
		if nemici(lato, D.LATO_NAZ[casa]):
			_entra_in_guerra(casa, "invasa %s" % ("dall'Asse" if lato == "asse" else ("dagli Alleati" if lato == "alleati" else "dall'URSS")))
	if lato == "urss" and casa in ["GER", "ROM", "UNG"] and not s["tot"]["asse"] and not s["tot_da"].has("asse"):
		s["tot_da"]["asse"] = t + 1
		_log("L'URSS invade %s: l'Asse entrerà in guerra totale." % Dati.NOME_NAZ[casa])

func _barbarossa() -> void:
	if int(s["barbarossa"]) > 0:
		return
	var t := int(s["turno"])
	s["barbarossa"] = t
	for l in ["asse", "urss"]:
		if not s["tot_da"].has(l):
			s["tot_da"][l] = t + 1
	_log("[b]Operazione Barbarossa: l'Asse invade l'Unione Sovietica![/b]")

func _muovi(uid: String, h: String, modo: String, att: String, sup: int) -> Dictionary:
	var p := perche_ferma(uid)
	if p != "":
		return {"ok": false, "msg": p}
	var u: Dictionary = s["u"][uid]
	var lato := lato_di(uid)
	var con_att := att != "" or sup >= 0
	var info := {}
	var costo := 1
	match modo:
		"tattico":
			var mm := mosse_tattiche(uid, con_att)
			if not mm.has(h):
				return {"ok": false, "msg": "area non raggiungibile con un movimento tattico" + (" seguito da attacco" if con_att else "")}
			info = mm[h]
			costo = costo_operazione(uid, "tattico", h)
		"strategico":
			if con_att:
				return {"ok": false, "msg": "dopo un movimento strategico non si attacca"}
			var ms := mosse_strategiche(uid)
			if not ms.has(h):
				return {"ok": false, "msg": "il movimento strategico passa solo per aree controllate"}
			costo = costo_operazione(uid, "strategico", h)
		"navale":
			if con_att:
				return {"ok": false, "msg": "dopo un movimento navale non si attacca"}
			var mn := mosse_navali(uid)
			if not mn.has(h):
				return {"ok": false, "msg": "il movimento navale va fra aree costiere controllate"}
			costo = costo_operazione(uid, "navale", h, int(mn[h]["costo"]))
		"anfibio":
			if sup >= 0:
				return {"ok": false, "msg": "le armate che sbarcano non sostengono attacchi"}
			var ma := mosse_anfibie(uid)
			if not ma.has(h):
				return {"ok": false, "msg": "sbarco non possibile qui"}
			info = ma[h]
			costo = costo_operazione(uid, "anfibio", h)
		_:
			return {"ok": false, "msg": "modo sconosciuto"}
	# entrare dove ci sono solo nemici obbliga ad attaccare
	var nem := nemici_in(h, lato)
	if not nem.is_empty() and unita_in(h, lato).is_empty() and att == "" and modo in ["tattico", "anfibio"]:
		var gia := false
		for at in s["attacchi"]:
			if at["h"] == h:
				gia = true
		if not gia:
			return {"ok": false, "msg": "entrando in un'area con sole armate nemiche bisogna attaccare"}
	if att != "":
		if not (att in nem):
			return {"ok": false, "msg": "bersaglio non valido"}
		var pa := _perche_no_attacco(uid, att, h)
		if pa != "":
			return {"ok": false, "msg": pa}
	if sup >= 0:
		var ps := _perche_no_sostegno(uid, sup, h, true)
		if ps != "":
			return {"ok": false, "msg": ps}
	if not _spendi(lato, costo):
		return {"ok": false, "msg": "rifornimenti insufficienti (servono %d)" % costo}
	var da: String = u["h"]
	# aree attraversate: controllo a fine operazioni
	if modo == "tattico":
		for x in info.get("via", []):
			if nemici_in(x, lato).is_empty() and s["ctrl"][x] != lato:
				s["ctrl_pend"][x] = true
				_effetti_ingresso(uid, x)
		u["ent"] = info.get("da", da)
	if modo == "strategico" and lato == "asse":
		var passa := D.nazione(h) == "URSS" or D.nazione(da) == "URSS"
		if passa:
			s["strat_urss"] = int(s["strat_urss"]) + 1
	if modo == "anfibio":
		u["anf"] = true
		u["ent"] = ""
		s["sbarchi"] = int(s["sbarchi"]) + (1 if info.get("tipo", "ll") == "ll" else 0)
		if info.get("tipo", "ll") == "d":
			s["sbarchi_d"] = int(s["sbarchi_d"]) + 1
		if h == "trondheim":
			s["sbarchi_tr"] = int(s["sbarchi_tr"]) + 1
	if modo == "navale":
		u["ent"] = ""
	u["h"] = h
	invalida()
	u["op"] = "mov" if not con_att else ("att" if att != "" else "sup")
	u["modo"] = modo
	if s["ctrl"][h] != lato and nemici_in(h, lato).is_empty():
		s["ctrl_pend"][h] = true
	_effetti_ingresso(uid, h)
	var modi := {"tattico": "", "strategico": " (movimento strategico)", "navale": " (via mare)", "anfibio": " (sbarco)"}
	_log("%s: %s da %s a %s%s." % [Dati.NOME_LATO_BREVE[lato], nome_unita(uid), D.nome(da), D.nome(h), modi[modo]])
	if att != "":
		_dichiara(uid, att, h)
	elif sup >= 0:
		s["attacchi"][sup]["sup"].append(uid)
	invalida()
	return {"ok": true}

func _perche_no_attacco(uid: String, d: String, h: String) -> String:
	var lato := lato_di(uid)
	if not s["u"].has(d) or s["u"][d]["h"] != h or not nemici(lato, lato_di(d)):
		return "bersaglio non valido"
	var u: Dictionary = s["u"][uid]
	if u["naz"] == "FIN" and h == "carelia" and s["ctrl"]["carelia"] == "urss":
		return "i finlandesi non attaccano in Carelia se è controllata dall'URSS (possono sostenere)"
	if lato == "urss" and d in s["attaccati_alleati"]:
		return "Alleati e URSS non attaccano la stessa armata nello stesso turno"
	if h == "calais" and s["u"][d]["naz"] == "GB":
		var francesi := false
		for o in unita_in(h, "alleati"):
			if s["u"][o]["naz"] == "FRA":
				francesi = true
		if francesi:
			var gia := false
			for at in s["attacchi"]:
				if at["h"] == h and s["u"].has(at["d"]) and s["u"][at["d"]]["naz"] == "FRA":
					gia = true
			if not gia:
				return "a Calais si attaccano i britannici solo attaccando anche i francesi"
	return ""

func _dichiara(uid: String, d: String, h: String) -> void:
	var u: Dictionary = s["u"][uid]
	var lato := lato_di(uid)
	s["attacchi"].append({"a": uid, "d": d, "h": h, "sup": [], "aereo": 0, "da": u.get("ent", ""), "anf": u.get("anf", false)})
	if lato == "asse" and lato_di(d) == "urss":
		_barbarossa()
	if lato == "asse" and h == "carelia" and u["naz"] == "GER":
		_barbarossa()
	if lato == "asse" and D.patria(h) in ["FRA", "BEL"] and int(s["attacco_ovest"]) == 0:
		s["attacco_ovest"] = int(s["turno"])
	_log("Attacco dichiarato a %s: %s contro %s." % [D.nome(h), nome_unita(uid), nome_unita(d)])

func _attacca(uid: String, d: String) -> Dictionary:
	var p := perche_ferma(uid)
	if p != "":
		return {"ok": false, "msg": p}
	var u: Dictionary = s["u"][uid]
	var h: String = u["h"]
	if _bloccata_pre_barbarossa(uid) and s["ctrl"][h] != "asse":
		return {"ok": false, "msg": "prima di Barbarossa questa armata sovietica non agisce"}
	var pa := _perche_no_attacco(uid, d, h)
	if pa != "":
		return {"ok": false, "msg": pa}
	var lato := lato_di(uid)
	var costo := costo_operazione(uid, "attacco", h)
	if not _spendi(lato, costo):
		return {"ok": false, "msg": "rifornimenti insufficienti (servono %d)" % costo}
	u["op"] = "att"
	u["ent"] = ""
	_effetti_ingresso(uid, h)
	_dichiara(uid, d, h)
	return {"ok": true}

func _perche_no_sostegno(uid: String, i: int, h: String, in_arrivo: bool) -> String:
	if i < 0 or i >= s["attacchi"].size():
		return "attacco non valido"
	var at: Dictionary = s["attacchi"][i]
	if at["h"] != h:
		return "si sostiene solo un attacco nella stessa area"
	var lato := lato_di(uid)
	var mie := unita_in(h, lato).size() + (1 if in_arrivo else 0)
	var nem := nemici_in(h, lato).size()
	var gia := 0
	for a2 in s["attacchi"]:
		if a2["h"] == h:
			gia += (a2["sup"] as Array).size()
	if mie - nem <= gia:
		return "si sostiene solo con le armate in più rispetto ai difensori"
	if s["u"][uid].get("anf", false):
		return "le armate che sbarcano non sostengono"
	return ""

func _sostieni(uid: String, i: int) -> Dictionary:
	var p := perche_ferma(uid)
	if p != "":
		return {"ok": false, "msg": p}
	var u: Dictionary = s["u"][uid]
	var ps := _perche_no_sostegno(uid, i, u["h"], false)
	if ps != "":
		return {"ok": false, "msg": ps}
	var lato := lato_di(uid)
	var costo := costo_operazione(uid, "attacco", u["h"])
	if not _spendi(lato, costo):
		return {"ok": false, "msg": "rifornimenti insufficienti (servono %d)" % costo}
	u["op"] = "sup"
	s["attacchi"][i]["sup"].append(uid)
	_log("%s sostiene l'attacco a %s." % [maiuscola(nome_unita(uid)), D.nome(u["h"])])
	return {"ok": true}

func _annulla_attacco(_i: int) -> Dictionary:
	return {"ok": false, "msg": "gli attacchi dichiarati non si ritirano"}

func perche_no_aereo(i: int) -> String:
	if i < 0 or i >= s["attacchi"].size():
		return "attacco non valido"
	var lato: String = s["lato"]
	var at: Dictionary = s["attacchi"][i]
	if s["fase"] != "operazioni":
		return "le operazioni sono finite"
	if int(at.get("aereo", 0)) > 0:
		return "già una missione su questo attacco"
	if int(s["aerei"][lato]) <= 0:
		return "nessuna missione aerea disponibile"
	var h: String = at["h"]
	var t := int(s["turno"])
	if Dati.inverno(t) and not D.africa(h) and not (lato == "alleati" and Dati.anno(t) >= 1945):
		return "d'inverno le missioni aeree si usano solo in Africa"
	if lato == "asse" and Dati.anno(t) < 1941 and D.nazione(h) in ["FIN", "GRE", "LIB", "EGI", "AFN"]:
		return "fino al 1941 niente aerei tedeschi in Finlandia, Grecia e Africa"
	return ""

func _aereo(i: int, via: bool) -> Dictionary:
	if via:
		return {"ok": false, "msg": "le missioni assegnate non si ritirano"}
	var p := perche_no_aereo(i)
	if p != "":
		return {"ok": false, "msg": p}
	var lato: String = s["lato"]
	s["aerei"][lato] = int(s["aerei"][lato]) - 1
	s["attacchi"][i]["aereo"] = 1
	_log("Missione aerea sull'attacco a %s." % D.nome(s["attacchi"][i]["h"]))
	return {"ok": true}

func _bombarda(n: int) -> Dictionary:
	var lato: String = s["lato"]
	if lato != "alleati" or s["fase"] != "operazioni":
		return {"ok": false, "msg": "solo gli Alleati, durante le operazioni"}
	if s["ctrl"]["londra"] != "alleati":
		return {"ok": false, "msg": "serve il controllo di Londra"}
	if not ha("alleati", "aviazione_av"):
		return {"ok": false, "msg": "servono le missioni aeree avanzate"}
	if Dati.inverno(int(s["turno"])) and anno() < 1945:
		return {"ok": false, "msg": "d'inverno niente missioni aeree fuori dall'Africa"}
	n = mini(n, int(s["aerei"]["alleati"]))
	if n <= 0:
		return {"ok": false, "msg": "nessuna missione disponibile"}
	s["aerei"]["alleati"] = int(s["aerei"]["alleati"]) - n
	s["bomb"] = int(s["bomb"]) + n
	_log("Alleati: %d missioni di bombardamento strategico sulla Germania." % n)
	return {"ok": true}

func _sottomarini(n: int) -> Dictionary:
	if s["lato"] != "asse":
		return {"ok": false, "msg": "solo l'Asse"}
	if int(s["atlantico"]) > 0:
		return {"ok": false, "msg": "missioni già piazzate in questo turno"}
	n = mini(n, int(s["sub"]))
	if n <= 0:
		return {"ok": false, "msg": "nessuna missione sottomarina"}
	s["sub"] = int(s["sub"]) - n
	s["atlantico"] = n
	s["atlantico_av"] = ha("asse", "navi_av")
	_log("Asse: %d missioni sottomarine nella Battaglia dell'Atlantico." % n)
	return {"ok": true}

# =====================================================================================
# Domande utili all'interfaccia e all'IA
# =====================================================================================

## tutte le destinazioni di un'armata: area -> [modo, costo]
func destinazioni(uid: String, con_attacco := false) -> Dictionary:
	var out := {}
	if perche_ferma(uid) != "":
		return out
	for h in mosse_tattiche(uid, con_attacco):
		out[h] = ["tattico", costo_operazione(uid, "tattico", h)]
	if not con_attacco:
		for h in mosse_strategiche(uid):
			if not out.has(h):
				out[h] = ["strategico", costo_operazione(uid, "strategico", h)]
		var mn := mosse_navali(uid)
		for h in mn:
			if not out.has(h):
				out[h] = ["navale", costo_operazione(uid, "navale", h, int(mn[h]["costo"]))]
	for h in mosse_anfibie(uid):
		if not out.has(h):
			out[h] = ["anfibio", 2]
	return out

## probabilità che vinca l'attaccante (pareggio a metà) con i due dadi
static func prob_vittoria(att: int, dif: int, min_a := 1, min_d := 1) -> float:
	var v := 0.0
	for a in range(1, 7):
		for d in range(1, 7):
			var aa := maxi(a, min_a) if a <= 2 and min_a == 3 else a
			var dd := maxi(d, min_d) if d <= 2 and min_d == 3 else d
			if att + aa > dif + dd:
				v += 1.0
			elif att + aa == dif + dd:
				v += 0.3
	return v / 36.0

func testo_area(id: String) -> String:
	var a: Dictionary = D.aree[id]
	var parti := []
	var c: String = s["ctrl"][id]
	parti.append("[b]%s[/b] (%s)" % [D.nome(id), Dati.NOME_NAZ.get(a["naz"], a["naz"])])
	parti.append("Controllo: %s" % (Dati.NOME_LATO[c] if c != "" else "neutrale"))
	var tr := []
	for t in D.terreni(id):
		tr.append({"foresta": "foresta", "palude": "palude", "montagna": "montagna", "passo": "passo stretto"}[t])
	if D.fortezza(id):
		tr.append("fortezza")
	parti.append("Terreno: %s" % (", ".join(tr) if not tr.is_empty() else "pianura"))
	var spec := []
	if a.has("rif"):
		spec.append("area di rifornimento")
	if a.has("chiave"):
		spec.append("area chiave")
	if a.has("cap"):
		spec.append("capitale")
	if a.has("est"):
		spec.append("oltre la Linea orientale")
	if id == "bucarest" or id == "groznyj" or id == "baku":
		spec.append("petrolio")
	if id == "trondheim":
		spec.append("ferro")
	if not spec.is_empty():
		parti.append(maiuscola(", ".join(spec)))
	return "\n".join(parti)
