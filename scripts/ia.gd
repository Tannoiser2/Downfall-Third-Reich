## Intelligenza artificiale per i tre schieramenti.
## A ogni chiamata sceglie una sola decisione guardando lo stato attuale (gioca "a passi", come un giocatore).
class_name IA
extends RefCounted

var D: Dati
var m: Motore
var livello := "normale"
var _rifiutate := {}      # firma decisione -> true, per non riproporre decisioni rifiutate
var _turno_chiave := ""
var _dest_cache := {}
var _versione := -1

func _init(dati: Dati, motore: Motore) -> void:
	D = dati
	m = motore

# =====================================================================================
# Punto d'ingresso
# =====================================================================================

func decidi(r: Dictionary) -> Dictionary:
	var chiave := "%d:%s:%s" % [int(m.s["turno"]), m.s["lato"], r["k"]]
	if chiave != _turno_chiave:
		_turno_chiave = chiave
		_rifiutate.clear()
	_dest_cache.clear()
	match r["k"]:
		"contrasto":
			return _contrasto(r["g"])
		"operazioni":
			return _operazioni(r["g"])
		"dopo":
			return _dopo(r["g"])
	return {"t": "fine"}

## l'interfaccia segnala che una decisione è stata rifiutata
func rifiutata(d: Dictionary) -> void:
	_rifiutate[JSON.stringify(d)] = true

func _ok(d: Dictionary) -> bool:
	if _rifiutate.has(JSON.stringify(d)):
		return false
	var t: String = d.get("t", "")
	if t in ["muovi", "attacca", "sostieni"] and m.s["u"].has(d.get("u", "")):
		var uid: String = d["u"]
		var dest: String = d.get("h", m.s["u"][uid]["h"])
		var modo: String = d.get("m", "attacco")
		var c := 2 if modo == "anfibio" else m.costo_operazione(uid, "tattico" if modo == "tattico" else ("attacco" if modo == "attacco" else modo), dest)
		if modo == "navale":
			var mn := m.mosse_navali(uid)
			c = m.costo_operazione(uid, "navale", dest, int(mn[dest]["costo"])) if mn.has(dest) else 9
		if c > int(m.s["rif"][m.lato_di(uid)]):
			return false
	return true

# =====================================================================================
# Valori delle aree e obiettivi
# =====================================================================================

func valore_area(id: String, lato: String) -> float:
	var a: Dictionary = D.aree[id]
	var v := 1.0
	if a.has("chiave"):
		v += 4.0
	if a.has("rif"):
		v += 4.0
	if a.has("cap"):
		v += 3.0
	if id in ["bucarest", "groznyj", "baku", "trondheim", "suez"]:
		v += 3.0
	v *= _peso_teatro(id, lato)
	if lato == "asse" and a.has("rif") and str(a["rif"]) == "asse" and int(m.s["turno"]) >= 12:
		v *= 1.8
	if lato == "alleati" and id == "trondheim" and m.guerra_totale("asse"):
		v += 3.0
	# a fine guerra le aree di rifornimento tedesche decidono la partita
	if lato != "asse" and a.has("rif") and str(a["rif"]) == "asse" and int(m.s["turno"]) >= 15:
		v *= 2.0
	return v

## priorità geografiche dei tre schieramenti, a seconda del momento
func _peso_teatro(id: String, lato: String) -> float:
	var naz := D.nazione(id)
	var casa := D.patria(id)
	var t := int(m.s["turno"])
	match lato:
		"asse":
			if not m.s["arresi"].has("FRA") and casa in ["FRA", "BEL"]:
				return 3.0
			if naz == "URSS":
				return 2.5 if _barbarossa_pronta() else 0.0
			if casa == "GB":
				return 0.6
			if naz in ["EGI"]:
				return 1.6
			if naz in ["GRE", "JUG"]:
				return 1.2 if m.s["guerra"][naz] else 0.0
			if naz == "AFN":
				return 0.8
			return 1.0
		"alleati":
			if casa in ["FRA", "BEL"]:
				return 2.0 if t >= 13 or not m.s["arresi"].has("FRA") else 1.2
			if casa == "GER":
				return 2.5
			if casa == "ITA":
				return 1.6
			if naz in ["LIB", "EGI", "AFN"]:
				return 1.5
			return 1.0
		"urss":
			if int(m.s["barbarossa"]) == 0 and t < 9:
				return 2.0 if naz == "URSS" and m.s["ctrl"][id] != "asse" else 0.0
			if naz == "URSS":
				return 2.0
			if casa == "GER":
				return 2.5
			return 1.2
	return 1.0

func _barbarossa_pronta() -> bool:
	if int(m.s["barbarossa"]) > 0:
		return true
	var t := int(m.s["turno"])
	if t >= 9:
		return true
	# consiglio dell'autore: Barbarossa richiede molte unità di rifornimento accumulate.
	# La Germania attacca nel 1941 dopo la Francia, quando ha la scorta; al più tardi nell'autunno 1941.
	if t >= 8:
		return true
	return t >= 6 and m.s["arresi"].has("FRA") and int(m.s["rif"]["asse"]) >= 9

## l'Asse sta preparando Barbarossa: risparmia rifornimenti
func _prepara_barbarossa() -> bool:
	return int(m.s["barbarossa"]) == 0 and m.s["arresi"].has("FRA") and int(m.s["turno"]) >= 4 and int(m.s["turno"]) < 9 and not _barbarossa_pronta()

## l'IA evita di entrare in paesi neutrali (che entrerebbero in guerra) salvo eccezioni
func _area_evitata(id: String, lato: String) -> bool:
	var casa := D.patria(id)
	var c: String = m.s["ctrl"][id]
	if lato == "urss" and int(m.s["barbarossa"]) == 0 and int(m.s["turno"]) < 9:
		return c == "asse"
	if lato == "asse" and D.nazione(id) == "URSS" and m.s["ctrl"][id] == "urss" and not _barbarossa_pronta():
		return true
	if casa in ["BEL", "ITA", "ROM", "UNG", "BUL", "GRE", "JUG"] and not m.s["guerra"][casa] and not m.s["arresi"].has(casa):
		if lato == "asse" and casa == "BEL":
			return false
		return true
	if c == "" and D.nazione(id) in ["NOR", "DAN"]:
		return lato != "asse" or int(m.s["turno"]) < 2
	return false

# =====================================================================================
# Combattimento: probabilità
# =====================================================================================

func _dado_minimo(uid: String, area: String) -> int:
	var u: Dictionary = m.s["u"][uid]
	if u["naz"] == "GER" and Dati.corazzata(u["t"]) and D.nazione(area) == "URSS":
		var tr := D.terreni(area)
		if not ("foresta" in tr or "palude" in tr or "montagna" in tr):
			return 3
	if D.africa(area) and (u["t"] == "k" or (u["naz"] == "GB" and Dati.corazzata(u["t"]))):
		return 3
	return 1

static func probabilita(att: int, dif: int, min_a: int, min_d: int) -> float:
	var v := 0.0
	for a in range(1, 7):
		for d in range(1, 7):
			var aa := 3 if a < min_a else a
			var dd := 3 if d < min_d else d
			if att + aa > dif + dd:
				v += 1.0
			elif att + aa == dif + dd:
				v += 0.35
	return v / 36.0

## stima dell'attacco: probabilità di vittoria
func _stima(att_uid: String, def_uid: String, area: String, da: String, anf: bool, sostegno: int, aereo: bool) -> float:
	var fa := Dati.fattore(m.s["u"][att_uid]["naz"], m.s["u"][att_uid]["t"], m.s["u"][att_uid]["r"], D.africa(area))
	var fd := m.fattore_unita(def_uid)
	var b := m.bonus_difesa(def_uid, area, da, anf)
	var att := fa + sostegno + (2 if aereo else 0)
	return probabilita(att, fd + b, _dado_minimo(att_uid, area), _dado_minimo(def_uid, area))

# =====================================================================================
# Contrasto aereo
# =====================================================================================

func _contrasto(lato: String) -> Dictionary:
	var poss: Array = m.missioni_da_contrastare(lato)
	var n := int(m.s["aerei"][lato])
	var lista := []
	# prima il bombardamento strategico, poi gli attacchi
	if -1 in poss:
		lista.append(-1)
	for i in poss:
		if i == -1:
			continue
		if lista.size() >= n:
			break
		lista.append(i)
	return {"t": "contrasta", "lista": lista, "sb": mini(n, 3)}

# =====================================================================================
# Operazioni
# =====================================================================================

func _mie_disponibili(lato: String) -> Array:
	var out := []
	for uid in m.s["u"]:
		if m.lato_di(uid) == lato and m.perche_ferma(uid) == "":
			out.append(uid)
	return out

func _operazioni(lato: String) -> Dictionary:
	var d: Dictionary
	# 1. azioni che servono subito
	d = _azioni_iniziali(lato)
	if not d.is_empty():
		return d
	# 2. rinforzi da spendere
	d = _spendi_punti(lato)
	if not d.is_empty():
		return d
	d = _conversioni(lato)
	if not d.is_empty():
		return d
	var riserva := 0
	if lato == "asse" and _prepara_barbarossa():
		riserva = 9
	if int(m.s["rif"][lato]) <= riserva:
		return _chiudi_operazioni(lato)
	var disp := _mie_disponibili(lato)
	# 3. sostegni e aerei sugli attacchi già dichiarati
	d = _rinforza_attacchi(lato, disp)
	if not d.is_empty():
		return d
	# 4. nuovi attacchi
	d = _nuovo_attacco(lato, disp)
	if not d.is_empty():
		return d
	# 5. sbarchi
	d = _sbarco(lato, disp)
	if not d.is_empty():
		return d
	# 6. conquiste di aree vuote
	d = _conquista(lato, disp)
	if not d.is_empty():
		return d
	# 7. schieramento verso il fronte
	d = _schiera(lato, disp)
	if not d.is_empty():
		return d
	# 8. sottomarini e bombardamento
	d = _missioni_speciali(lato)
	if not d.is_empty():
		return d
	return _chiudi_operazioni(lato)

func _chiudi_operazioni(lato: String) -> Dictionary:
	var d := _missioni_speciali(lato)
	if not d.is_empty():
		return d
	return {"t": "combatti"}

func _dopo(lato: String) -> Dictionary:
	var d := _azioni_finali(lato)
	if not d.is_empty():
		return d
	d = _spendi_punti(lato)
	if not d.is_empty():
		return d
	d = _conversioni(lato)
	if not d.is_empty():
		return d
	return {"t": "fine"}

# ---------- azioni ----------

func _prova_azione(a: String, x := "") -> Dictionary:
	var d := {"t": "azione", "a": a}
	if x != "":
		d["x"] = x
	if m.perche_no_azione(a, x) == "" and _ok(d):
		return d
	return {}

func _fatta(a: String) -> int:
	return int(m.s["az"]["tipi"].get(a, 0))

func _azioni_iniziali(lato: String) -> Dictionary:
	return _scegli_azione(lato, true)

func _azioni_finali(lato: String) -> Dictionary:
	return _scegli_azione(lato, false)

func _vale_rinforzo(lato: String) -> bool:
	var libere := 0
	for naz in Dati.MAGGIORI:
		if D.LATO_NAZ[naz] != lato or not m.s["guerra"][naz]:
			continue
		for tp in m.tipi_costruibili(naz):
			libere += m.pedine_libere(naz, tp)
	var ridotte := 0
	for uid in m.s["u"]:
		var u: Dictionary = m.s["u"][uid]
		if m.lato_di(uid) == lato and u["r"] and u["naz"] in Dati.MAGGIORI:
			ridotte += 1
	return libere > 0 or ridotte > 0

func _ridotte(lato: String) -> int:
	var n := 0
	for uid in m.s["u"]:
		var u: Dictionary = m.s["u"][uid]
		if m.lato_di(uid) == lato and u["r"] and u["naz"] in Dati.MAGGIORI:
			n += 1
	return n

## sceglie l'azione più utile; prima dei combattimenti solo quelle che servono subito
func _scegli_azione(lato: String, prima: bool) -> Dictionary:
	if m.azioni_rimaste() <= 0:
		return {}
	var t := int(m.s["turno"])
	var rif := int(m.s["rif"][lato])
	var francia: bool = m.s["arresi"].has("FRA")
	var cand := []
	# rifornimento
	if prima:
		var soglia_r := 12 if (lato == "asse" and _prepara_barbarossa()) else 8
		cand.append(["rifornimento", "", 10.0 if rif < soglia_r else (3.0 if rif < 10 else 0.0)])
	else:
		cand.append(["rifornimento", "", 2.5 if rif < 6 else (0.5 if rif < 10 else 0.0)])
	# rinforzi
	if _vale_rinforzo(lato):
		var v := 5.0 + minf(_ridotte(lato), 4) * 0.5
		if lato == "asse" and not francia and t <= 4:
			v = 3.0 + minf(_ridotte(lato), 4) * 0.5
		if lato == "alleati" and m.guerra_totale(lato) and _fatta("rinforzi") == 1:
			v = 4.0
		cand.append(["rinforzi", "", v if prima or true else v])
	# missioni aeree: prima dei combattimenti se si possono usare in questo turno
	if m.ha(lato, "aviazione") and int(m.s["aerei"][lato]) < m.max_aerei(lato):
		var poche := int(m.s["aerei"][lato]) < 3
		var v2 := 6.0 if poche else 2.5
		if prima and Dati.inverno(t):
			v2 = 0.0
		cand.append(["aerei", "", v2])
	if lato == "asse" and t <= 18:
		var v3 := 0.0
		if int(m.s["sub"]) < 2:
			v3 = 5.5 if not m.guerra_totale("alleati") and francia else (4.5 if francia else 2.0)
		if not prima:
			cand.append(["sottomarini", "", v3])
	if lato == "alleati":
		cand.append(["prestito", "", 5.0 if m.azioni_rimaste() >= 2 else 3.0])
	if not prima:
		var sv := _sviluppo_preferito(lato)
		if sv != "":
			var v4 := 4.0 if int(m.s["svil"][lato].get(sv, 0)) == 0 else 5.0
			# gli Alleati senza Carri avanzati non possono costruire corazzati americani: è la priorità
			if lato == "alleati" and sv in ["carri_av", "sbarchi", "logistica"]:
				v4 += 2.5
			cand.append(["sviluppo", sv, v4])
		var libere_cor := 0
		for naz in Dati.MAGGIORI:
			if D.LATO_NAZ[naz] == lato:
				for tp in ["a", "c", "k"]:
					libere_cor += m.pedine_libere(naz, tp) if tp in m.tipi_costruibili(naz) else 0
		if libere_cor > 0 or _ridotte(lato) > 0:
			cand.append(["corazzati", "", 3.5 if int(m.s["cor"][lato]) < 3 else 1.0])
	cand.sort_custom(func(a, b): return a[2] > b[2])
	for c in cand:
		if float(c[2]) < (2.0 if prima else 0.4):
			continue
		var d := _prova_azione(c[0], c[1])
		if not d.is_empty():
			return d
	return {}

const ORDINE_SVILUPPI := {
	"asse": ["carri_av", "ind_carri", "logistica", "aviazione_av", "ind_aerea", "navi_av"],
	"alleati": ["carri_av", "logistica", "sbarchi", "ind_carri", "aviazione_av", "navi_av", "blitzkrieg", "ind_aerea"],
	"urss": ["aviazione", "urali", "guardie", "logistica", "ind_carri", "carri_av", "blitzkrieg", "ind_aerea"],
}

func _sviluppo_preferito(lato: String) -> String:
	# prima si completa ciò che è avviato
	for x in ORDINE_SVILUPPI[lato]:
		if int(m.s["svil"][lato].get(x, 0)) == 1 and m.perche_no_sviluppo(x) == "":
			return x
	for x in ORDINE_SVILUPPI[lato]:
		if m.perche_no_sviluppo(x) == "":
			return x
	return ""

# ---------- rinforzi ----------

func _spendi_punti(lato: String) -> Dictionary:
	if int(m.s["punti"]) <= 0:
		return {}
	# armate ridotte al fronte
	var migliore := ""
	var mv := -1.0
	for uid in m.s["u"]:
		if m.lato_di(uid) != lato or not m.s["u"][uid]["r"]:
			continue
		if m.perche_no_potenzia(uid) != "":
			continue
		var v := 1.0 + _minaccia(m.s["u"][uid]["h"], lato) * 0.2 + (1.0 if Dati.corazzata(m.s["u"][uid]["t"]) else 0.0)
		if v > mv:
			mv = v
			migliore = uid
	if migliore != "":
		var d := {"t": "potenzia", "u": migliore}
		if _ok(d):
			return d
	# nuove armate
	var naz_l := []
	for naz in Dati.MAGGIORI:
		if D.LATO_NAZ[naz] == lato and m.s["guerra"][naz] and not m.s["arresi"].has(naz):
			naz_l.append(naz)
	var opzioni := []
	for naz in naz_l:
		var tipi := m.tipi_costruibili(naz)
		# preferenze: corazzate se ci sono passi, poi fanteria
		var ordine := []
		if int(m.s["cor"][lato]) >= 2:
			for tp in ["c", "a", "k"]:
				if tp in tipi:
					ordine.append(tp)
		if "g" in tipi:
			ordine.append("g")
		ordine.append("f")
		for tp in ordine:
			if m.pedine_libere(naz, tp) <= 0:
				continue
			for h in D.sedi_costruzione(naz):
				for rid in [false, true]:
					if m.perche_no_costruzione(naz, tp, h, rid) == "":
						if _distanza_fronte(h, lato) > 4.0 and naz != "USA":
							continue
						var v := _valore_sede(h, lato) + (2.0 if Dati.corazzata(tp) else 0.0) + (0.5 if tp == "g" else 0.0) - (1.5 if rid else 0.0)
						if naz == "USA":
							v += 0.5
						opzioni.append([v, {"t": "costruisci", "naz": naz, "tipo": tp, "h": h, "ridotta": rid}])
			break
	opzioni.sort_custom(func(a, b): return a[0] > b[0])
	for o in opzioni:
		if _ok(o[1]):
			return o[1]
	return {}

func _valore_sede(h: String, lato: String) -> float:
	# più vicina al fronte = meglio, ma non dentro aree minacciate troppo
	var dist := _distanza_fronte(h, lato)
	return 6.0 - minf(dist, 6.0) + _minaccia(h, lato) * 0.1

func _conversioni(lato: String) -> Dictionary:
	if int(m.s["cor"][lato]) < 2:
		return {}
	for uid in m.s["u"]:
		if m.lato_di(uid) != lato:
			continue
		for tp in ["c", "a"]:
			if m.perche_no_converti(uid, tp) == "":
				var d := {"t": "converti", "u": uid, "tipo": tp}
				if _ok(d):
					return d
	return {}

# ---------- fronte e minacce ----------

var _cache_dist := {}

func _distanza_fronte(h: String, lato: String) -> float:
	var k := h + lato + str(m.s["turno"])
	if _cache_dist.has(k):
		return _cache_dist[k]
	if _cache_dist.size() > 5000:
		_cache_dist.clear()
	var visti := {h: 0}
	var coda := [h]
	var res := 20.0
	while not coda.is_empty():
		var x: String = coda.pop_front()
		var dx: int = visti[x]
		if _area_ostile(x, lato):
			res = float(dx)
			break
		if dx >= 12:
			continue
		for y in D.aree[x]["vicini"]:
			if not visti.has(y):
				visti[y] = dx + 1
				coda.append(y)
	_cache_dist[k] = res
	return res

func _area_ostile(x: String, lato: String) -> bool:
	if not m.nemici_in(x, lato).is_empty() and _peso_teatro(x, lato) > 0.0:
		return true
	var c: String = m.s["ctrl"][x]
	if Motore.nemici(lato, c) and _peso_teatro(x, lato) > 0.0:
		return true
	return false

## somma dei fattori nemici entro un passo
func _minaccia(h: String, lato: String) -> float:
	var t := 0.0
	for uid in m.nemici_in(h, lato):
		t += m.fattore_unita(uid) * _peso_nemico(uid, lato)
	for v in D.aree[h]["vicini"]:
		for uid in m.nemici_in(v, lato):
			if D.confine(h, v).has("a"):
				continue
			t += m.fattore_unita(uid) * 0.8 * _peso_nemico(uid, lato)
	return t

## prima di Barbarossa l'Asse e l'URSS non si temono molto
func _peso_nemico(uid: String, lato: String) -> float:
	if int(m.s["barbarossa"]) == 0 and int(m.s["turno"]) < 9:
		var l2 := m.lato_di(uid)
		if lato == "asse" and l2 == "urss":
			return 0.2 if not _barbarossa_pronta() else 0.6
		if lato == "urss" and l2 == "asse":
			return 0.7
	return 1.0

# ---------- attacchi ----------

func _destinazioni(uid: String, con_att: bool) -> Dictionary:
	var k := uid + (":a" if con_att else ":m")
	if not _dest_cache.has(k):
		_dest_cache[k] = m.mosse_tattiche(uid, con_att)
	return _dest_cache[k]

func _ha_linea_dopo(uid: String, dest: String) -> bool:
	var lato := m.lato_di(uid)
	var R: Dictionary = m._rete_lato(lato, m.s["u"][uid]["naz"])
	if R.has(dest):
		return true
	for v in D.aree[dest]["vicini"]:
		if R.has(v):
			return true
	return false

func _soglia(lato: String) -> float:
	var s := 0.58
	if lato == "asse" and not m.s["arresi"].has("FRA"):
		s = 0.5
	if livello == "esperto":
		s += 0.02
	return s

func _nuovo_attacco(lato: String, disp: Array) -> Dictionary:
	var migliore := {}
	var mv := 0.0
	# aree con nemici raggiungibili
	var bersagli := {}
	for uid in disp:
		var h: String = m.s["u"][uid]["h"]
		if not m.nemici_in(h, lato).is_empty():
			bersagli[h] = true
		for y in _destinazioni(uid, true):
			if not m.nemici_in(y, lato).is_empty():
				bersagli[y] = true
	for area in bersagli:
		if _area_evitata(area, lato):
			continue
		var peso := _peso_teatro(area, lato)
		if peso <= 0.0:
			continue
		var nem := m.nemici_in(area, lato)
		var mie_qui := m.unita_in(area, lato)
		# armate che possono arrivare
		var arrivi := []
		for uid in disp:
			if m.s["u"][uid]["h"] == area:
				arrivi.append([uid, area, ""])
			elif _destinazioni(uid, true).has(area):
				var info: Dictionary = _destinazioni(uid, true)[area]
				if _ha_linea_dopo(uid, area):
					arrivi.append([uid, info["da"], "m"])
		if arrivi.is_empty():
			continue
		for d in nem:
			if m._perche_no_attacco(arrivi[0][0], d, area) != "" and arrivi.size() == 1:
				continue
			# attaccante: il più forte
			arrivi.sort_custom(func(a, b): return _forza(a[0], area) > _forza(b[0], area))
			var att: Array = arrivi[0]
			if m._perche_no_attacco(att[0], d, area) != "":
				continue
			var posti := 3 - mie_qui.size() - (1 if att[2] == "m" else 0)
			var sost := 0
			var conta := 0
			var proprie := mie_qui.size() + (1 if att[2] == "m" else 0)
			for k in range(1, arrivi.size()):
				var o: Array = arrivi[k]
				if o[2] == "m":
					if posti <= 0:
						continue
					posti -= 1
					proprie += 1
				if proprie - nem.size() > conta:
					sost += Dati.sostegno(m.s["u"][o[0]]["r"])
					conta += 1
			var da: String = att[1] if att[2] == "m" else ""
			var aereo := int(m.s["aerei"][lato]) > 0 and _aereo_lecito(area, lato)
			var p := _stima(att[0], d, area, da, false, sost, aereo)
			var p0 := _stima(att[0], d, area, da, false, sost, false)
			if p < _soglia(lato):
				continue
			var v := valore_area(area, lato) * p + m.fattore_unita(d) * 0.7 - (1.0 - p) * _forza(att[0], area) * 0.6
			if p0 >= _soglia(lato):
				v += 0.5
			if v > mv:
				mv = v
				if att[2] == "m":
					migliore = {"t": "muovi", "u": att[0], "h": area, "m": "tattico", "att": d}
				else:
					migliore = {"t": "attacca", "u": att[0], "d": d}
	if not migliore.is_empty() and _ok(migliore):
		return migliore
	return {}

func _aereo_lecito(area: String, lato: String) -> bool:
	var t := int(m.s["turno"])
	if Dati.inverno(t) and not D.africa(area) and not (lato == "alleati" and Dati.anno(t) >= 1945):
		return false
	if lato == "asse" and Dati.anno(t) < 1941 and D.nazione(area) in ["FIN", "GRE", "LIB", "EGI", "AFN"]:
		return false
	return true

func _forza(uid: String, area: String) -> float:
	var u: Dictionary = m.s["u"][uid]
	return float(Dati.fattore(u["naz"], u["t"], u["r"], D.africa(area)))

func _rinforza_attacchi(lato: String, disp: Array) -> Dictionary:
	for i in m.s["attacchi"].size():
		var at: Dictionary = m.s["attacchi"][i]
		if not m.s["u"].has(at["a"]) or not m.s["u"].has(at["d"]):
			continue
		var v := m.valuta_attacco(i)
		var p := probabilita(int(v["att"]), int(v["dif"]), _dado_minimo(at["a"], at["h"]), _dado_minimo(at["d"], at["h"]))
		if p >= 0.9:
			continue
		var riserva := 1 if lato != "asse" else 0
		if int(m.s["aerei"][lato]) > riserva and m.perche_no_aereo(i) == "" and p < 0.85:
			var d3 := {"t": "aereo", "i": i}
			if _ok(d3):
				return d3
		if p >= 0.72:
			continue
		# sostegno
		for uid in disp:
			if m.s["u"][uid]["h"] == at["h"]:
				var d := {"t": "sostieni", "u": uid, "i": i}
				if m._perche_no_sostegno(uid, i, at["h"], false) == "" and _ok(d):
					return d
		for uid in disp:
			if m.s["u"][uid]["h"] != at["h"] and _destinazioni(uid, true).has(at["h"]):
				if m._perche_no_sostegno(uid, i, at["h"], true) == "" and _ha_linea_dopo(uid, at["h"]):
					# non sguarnire aree minacciate per un sostegno
					var h0: String = m.s["u"][uid]["h"]
					if _lascia_scoperta(uid, h0, lato):
						continue
					var d2 := {"t": "muovi", "u": uid, "h": at["h"], "m": "tattico", "sup": i}
					if _ok(d2):
						return d2
	return {}

func _lascia_scoperta(uid: String, h0: String, lato: String) -> bool:
	var restano := m.unita_in(h0, lato).size() - 1
	if restano >= 1:
		return false
	if _minaccia(h0, lato) <= 0.0:
		return false
	return valore_area(h0, lato) >= 4.0 or D.aree[h0].has("rif") or D.aree[h0].has("cap")

# ---------- sbarchi ----------

func _sbarco(lato: String, disp: Array) -> Dictionary:
	if lato == "urss":
		return {}
	for uid in disp:
		var ma := m.mosse_anfibie(uid)
		for y in ma:
			if _area_evitata(y, lato):
				continue
			if _peso_teatro(y, lato) <= 0.0:
				continue
			var nem := m.nemici_in(y, lato)
			if lato == "asse" and not (y in ["copenaghen", "oslo", "bergen", "trondheim"]):
				continue
			if nem.is_empty():
				# sbarco in un'area vuota: solo se vale qualcosa e non è circondata da nemici forti
				if _minaccia(y, lato) > 9.0 and lato == "alleati":
					continue
				var d := {"t": "muovi", "u": uid, "h": y, "m": "anfibio"}
				if _ok(d) and int(m.s["rif"][lato]) >= 2:
					return d
			elif nem.size() == 1:
				var p := _stima(uid, nem[0], y, "", true, 0, int(m.s["aerei"][lato]) > 0 and _aereo_lecito(y, lato))
				if p >= 0.68:
					var d2 := {"t": "muovi", "u": uid, "h": y, "m": "anfibio", "att": nem[0]}
					if _ok(d2) and int(m.s["rif"][lato]) >= 2:
						return d2
	return {}

# ---------- conquiste ----------

func _conquista(lato: String, disp: Array) -> Dictionary:
	var migliore := {}
	var mv := 0.6
	for uid in disp:
		var h0: String = m.s["u"][uid]["h"]
		if _lascia_scoperta(uid, h0, lato):
			continue
		var dest := _destinazioni(uid, false)
		for y in dest:
			if m.s["ctrl"][y] == lato or not m.nemici_in(y, lato).is_empty():
				continue
			if _area_evitata(y, lato):
				continue
			var peso := _peso_teatro(y, lato)
			if peso <= 0.0:
				continue
			if not _ha_linea_dopo(uid, y):
				continue
			var v := valore_area(y, lato)
			if lato == "asse" and D.nazione(y) == "FRA" and not m.s["arresi"].has("FRA"):
				v += 3.0
			# rischio: forze nemiche vicine
			var minac := _minaccia(y, lato)
			v -= minac * 0.15
			# le aree attraversate contano anche loro
			for x in dest[y]["via"]:
				if m.s["ctrl"][x] != lato and m.nemici_in(x, lato).is_empty():
					v += valore_area(x, lato) * 0.5
			if v > mv:
				mv = v
				migliore = {"t": "muovi", "u": uid, "h": y, "m": "tattico"}
	if not migliore.is_empty() and _ok(migliore):
		return migliore
	return {}

# ---------- schieramento ----------

func _bisogno(h: String, lato: String) -> float:
	var minac := _minaccia(h, lato)
	if minac <= 0.0 and _distanza_fronte(h, lato) > 1.0:
		return 0.0
	var mie := 0.0
	for uid in m.unita_in(h, lato):
		mie += m.fattore_unita(uid)
	var voluto := minac * 0.75 + valore_area(h, lato) * 0.8 + 2.0
	return voluto - mie

func _schiera(lato: String, disp: Array) -> Dictionary:
	# aree del fronte con bisogno di truppe
	var bisogni := {}
	for id in D.aree:
		if m.s["ctrl"][id] != lato:
			continue
		if m.unita_in(id, lato).size() >= 3:
			continue
		var b := _bisogno(id, lato)
		if b > 0.5:
			bisogni[id] = b
	if bisogni.is_empty():
		return {}
	var migliore := {}
	var mv := 0.4
	for uid in disp:
		var h0: String = m.s["u"][uid]["h"]
		# chi è già al fronte con bisogno resta
		if bisogni.has(h0) and float(bisogni[h0]) > 0.0:
			continue
		if _minaccia(h0, lato) > 0.0 and m.unita_in(h0, lato).size() <= 1:
			continue
		var b0 := _bisogno(h0, lato)
		var dest := _destinazioni(uid, false)
		var strat := m.mosse_strategiche(uid)
		var nav := {}
		if lato == "alleati":
			nav = m.mosse_navali(uid)
		for y in bisogni:
			var modo := ""
			if dest.has(y) and m.nemici_in(y, lato).is_empty():
				modo = "tattico"
			elif strat.has(y):
				modo = "strategico"
			elif nav.has(y):
				modo = "navale"
			if modo == "":
				continue
			var v := float(bisogni[y]) - maxf(b0, 0.0) * 1.2
			if modo == "navale" and int(nav[y]["costo"]) > 1:
				v -= 0.5
			if v > mv:
				mv = v
				migliore = {"t": "muovi", "u": uid, "h": y, "m": modo}
	if not migliore.is_empty() and _ok(migliore):
		return migliore
	# armate lontane dal fronte: si avvicinano
	return _avvicina(lato, disp)

func _avvicina(lato: String, disp: Array) -> Dictionary:
	var migliore := {}
	var mv := 0.9
	for uid in disp:
		var h0: String = m.s["u"][uid]["h"]
		var d0 := _distanza_fronte(h0, lato)
		if d0 <= 1.0:
			continue
		if _lascia_scoperta(uid, h0, lato):
			continue
		var cand := {}
		for y in _destinazioni(uid, false):
			if m.nemici_in(y, lato).is_empty() and m.s["ctrl"][y] == lato:
				cand[y] = "tattico"
		for y in m.mosse_strategiche(uid):
			if not cand.has(y):
				cand[y] = "strategico"
		if lato == "alleati" and D.america(h0):
			for y in m.mosse_navali(uid):
				cand[y] = "navale"
		for y in cand:
			var dy := _distanza_fronte(y, lato)
			var v := d0 - dy
			if dy < 1.0:
				continue
			if cand[y] == "navale":
				v += 2.0
			if v > mv:
				mv = v
				migliore = {"t": "muovi", "u": uid, "h": y, "m": cand[y]}
	if not migliore.is_empty() and _ok(migliore):
		return migliore
	return {}

# ---------- missioni speciali ----------

func _missioni_speciali(lato: String) -> Dictionary:
	if lato == "asse" and int(m.s["atlantico"]) == 0 and int(m.s["sub"]) >= (1 if m.ha("asse", "navi_av") and not m.ha("alleati", "navi_av") else 2):
		var n := 1 if m.ha("asse", "navi_av") and not m.ha("alleati", "navi_av") else 2
		if not (m.ha("alleati", "navi_av") and not m.ha("asse", "navi_av")):
			var d := {"t": "sub", "n": n}
			if _ok(d):
				return d
	if lato == "alleati" and m.ha("alleati", "aviazione_av") and int(m.s["bomb"]) == 0 and int(m.s["aerei"]["alleati"]) >= 3:
		var d2 := {"t": "bombarda", "n": mini(int(m.s["aerei"]["alleati"]) - 1, 4)}
		if _ok(d2) and m.s["fase"] == "operazioni":
			return d2
	return {}
