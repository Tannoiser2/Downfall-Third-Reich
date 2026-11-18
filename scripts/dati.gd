## Dati fissi del gioco: mappa ad aree, nazioni, armate, sviluppi, schieramento iniziale.
class_name Dati
extends RefCounted

const LATI := ["asse", "alleati", "urss"]
const NOME_LATO := {"asse": "Asse", "alleati": "Alleati", "urss": "Unione Sovietica"}
const NOME_LATO_BREVE := {"asse": "Asse", "alleati": "Alleati", "urss": "URSS"}
const STAGIONI := ["Inverno", "Primavera", "Estate", "Autunno"]
const ULTIMO_TURNO := 22

## nazione -> lato
const LATO_NAZ := {"GER": "asse", "ITA": "asse", "FIN": "asse", "ROM": "asse", "UNG": "asse", "BUL": "asse",
	"GB": "alleati", "USA": "alleati", "FRA": "alleati", "BEL": "alleati", "GRE": "alleati", "JUG": "alleati",
	"URSS": "urss"}
const NOME_NAZ := {"GER": "Germania", "ITA": "Italia", "FIN": "Finlandia", "ROM": "Romania", "UNG": "Ungheria", "BUL": "Bulgaria",
	"GB": "Gran Bretagna", "USA": "Stati Uniti", "FRA": "Francia", "BEL": "Belgio e Paesi Bassi", "GRE": "Grecia", "JUG": "Jugoslavia",
	"URSS": "Unione Sovietica", "NOR": "Norvegia", "DAN": "Danimarca", "LIB": "Libia italiana", "EGI": "Egitto", "AFN": "Africa del Nord francese"}
const AGG_NAZ := {"GER": "tedesca", "ITA": "italiana", "FIN": "finlandese", "ROM": "rumena", "UNG": "ungherese", "BUL": "bulgara",
	"GB": "britannica", "USA": "americana", "FRA": "francese", "BEL": "belga", "GRE": "greca", "JUG": "jugoslava", "URSS": "sovietica"}
## potenze maggiori: armate costruite con l'azione Rinforzi nelle loro aree di rifornimento
const MAGGIORI := ["GER", "GB", "USA", "URSS"]
## territori considerati "patria" di una nazione (per resa e restrizioni politiche)
const COLONIE := {"LIB": "ITA", "EGI": "GB", "AFN": "FRA"}

## tipi di armata: f fanteria, a corazzata, c corazzata avanzata, g guardie, k Afrika Korps
const NOME_TIPO := {"f": "fanteria", "a": "corazzata", "c": "corazzata avanzata", "g": "Guardie", "k": "Afrika Korps", "p": "partigiani"}
## [fattore pieno, fattore ridotto, numero di pedine]
const ARMATE := {
	"GER": {"f": [5, 3, 16], "a": [6, 4, 5], "k": [7, 4, 1], "c": [8, 5, 2]},
	"ITA": {"f": [3, 2, 8]}, "FIN": {"f": [4, 2, 2]}, "ROM": {"f": [4, 2, 2]}, "UNG": {"f": [4, 2, 1]}, "BUL": {"f": [3, 2, 1]},
	"GB": {"f": [4, 2, 6], "a": [5, 3, 2], "c": [6, 4, 2]}, "USA": {"f": [4, 2, 3], "c": [6, 4, 6]},
	"FRA": {"f": [3, 2, 7], "a": [5, 3, 2]}, "BEL": {"f": [3, 2, 2]}, "GRE": {"f": [3, 2, 2]}, "JUG": {"f": [3, 2, 4]},
	"URSS": {"f": [3, 2, 18], "a": [5, 3, 5], "c": [7, 4, 4], "g": [5, 3, 4]},
}
## missioni aeree e sottomarine (pedine disponibili)
const MAX_AEREI := {"asse": 6, "alleati_gb": 5, "alleati_usa": 6, "urss": 5}
const MAX_SUB := 4
const MAX_RIF := 12
const MAX_COR := 12

const SVILUPPI := {
	"blitzkrieg": {"n": "Blitzkrieg", "lati": ["asse", "alleati", "urss"]},
	"aviazione": {"n": "Aviazione", "lati": ["asse", "alleati", "urss"]},
	"carri_av": {"n": "Carri avanzati", "lati": ["asse", "alleati", "urss"]},
	"urali": {"n": "Industria degli Urali", "lati": ["urss"]},
	"guardie": {"n": "Guardie", "lati": ["urss"]},
	"ind_carri": {"n": "Industria carri", "lati": ["asse", "alleati", "urss"]},
	"ind_aerea": {"n": "Industria aerea", "lati": ["asse", "alleati", "urss"]},
	"logistica": {"n": "Logistica", "lati": ["asse", "alleati", "urss"]},
	"sbarchi": {"n": "Sbarchi anfibi", "lati": ["alleati"]},
	"navi_av": {"n": "Navi avanzate", "lati": ["asse", "alleati"]},
	"aviazione_av": {"n": "Aviazione avanzata", "lati": ["asse", "alleati"]},
}
const SPIEGA_SVILUPPO := {
	"blitzkrieg": "Sfruttamento: dopo un attacco con +4 in pianura i corazzati attraversano l'area. Le linee di rifornimento passano per le aree con armate proprie e non sono tagliate da quelle nemiche.",
	"aviazione": "Permette l'azione Missioni aeree (2 missioni).",
	"carri_av": "Armate corazzate avanzate disponibili.",
	"urali": "Serve all'URSS per Logistica, Guardie, Industria carri e Industria aerea.",
	"guardie": "Armate della Guardia (fanteria 5-3).",
	"ind_carri": "L'azione Produzione corazzati dà 5 passi invece di 3.",
	"ind_aerea": "L'azione Missioni aeree dà 4 missioni invece di 2.",
	"logistica": "L'azione Rifornimento dà 7 unità invece di 5.",
	"sbarchi": "Fino a 3 armate sbarcano per turno (4 nel 1944), anche corazzate, più uno sbarco nelle aree D.",
	"navi_av": "Asse: basta una missione sottomarina. Alleati: annullano i sottomarini non avanzati.",
	"aviazione_av": "Missioni aeree avanzate: si contrastano solo con missioni avanzate. Bombardamento strategico.",
}
## anno minimo per completare/avviare uno sviluppo (per lato, "*" = tutti)
const ANNO_SVILUPPO := {"carri_av": {"asse": 1942}, "urali": {"urss": 1941}, "blitzkrieg": {"urss": 1942},
	"sbarchi": {"*": 1942}, "navi_av": {"*": 1943}, "aviazione_av": {"*": 1943}}
const RICHIEDE_URALI := ["logistica", "guardie", "ind_carri", "ind_aerea"]

const AZIONI := ["rifornimento", "rinforzi", "corazzati", "aerei", "sottomarini", "sviluppo", "prestito"]
const NOME_AZIONE := {"rifornimento": "Rifornimento", "rinforzi": "Rinforzi", "corazzati": "Produzione corazzati",
	"aerei": "Missioni aeree", "sottomarini": "Missioni sottomarine", "sviluppo": "Sviluppo", "prestito": "Affitti e prestiti"}

## schieramento iniziale (regolamento, punto 21): [area, nazione, tipo, ridotta]
const SCHIERAMENTO := [
	["konigsberg", "GER", "f", false], ["konigsberg", "GER", "f", false],
	["varsavia", "GER", "f", false], ["varsavia", "GER", "f", false],
	["tarnow", "GER", "f", true], ["amburgo", "GER", "f", true],
	["ruhr", "GER", "a", false], ["ruhr", "GER", "f", false], ["ruhr", "GER", "f", false],
	["francoforte", "GER", "a", false], ["francoforte", "GER", "a", false], ["francoforte", "GER", "f", false],
	["stoccarda", "GER", "f", false], ["stoccarda", "GER", "f", false], ["stoccarda", "GER", "f", false],
	["calais", "GB", "f", false], ["calais", "GB", "f", false],
	["alessandria", "GB", "a", true], ["alessandria", "GB", "f", false], ["el_alamein", "GB", "f", false], ["scozia", "GB", "f", true],
	["calais", "FRA", "f", false], ["reims", "FRA", "f", false], ["reims", "FRA", "f", false], ["reims", "FRA", "a", false],
	["nancy", "FRA", "f", false], ["nancy", "FRA", "f", false], ["parigi", "FRA", "f", false], ["parigi", "FRA", "f", false], ["parigi", "FRA", "a", false],
	["riga", "URSS", "f", false], ["riga", "URSS", "f", false], ["vilnius", "URSS", "f", false], ["vilnius", "URSS", "f", false],
	["kovel", "URSS", "f", false], ["kovel", "URSS", "f", false], ["tarnopol", "URSS", "f", false], ["tarnopol", "URSS", "f", false],
	["minsk", "URSS", "a", true], ["vinnica", "URSS", "a", true], ["odessa", "URSS", "f", false],
	["carelia", "URSS", "f", false], ["carelia", "URSS", "f", false], ["carelia", "URSS", "a", true],
	["leningrado", "URSS", "f", false], ["kiev", "URSS", "f", false], ["kiev", "URSS", "f", false], ["kiev", "URSS", "a", true],
	["charkov", "URSS", "a", true],
	["carelia", "FIN", "f", false], ["helsinki", "FIN", "f", false],
	["bruxelles", "BEL", "f", false], ["bruxelles", "BEL", "f", false],
	["milano", "ITA", "f", false], ["albania", "ITA", "f", false], ["albania", "ITA", "f", false], ["albania", "ITA", "f", false],
	["tobruch", "ITA", "f", false], ["bengasi", "ITA", "f", false], ["el_agheila", "ITA", "f", false], ["roma", "ITA", "f", false],
	["costanza", "ROM", "f", false], ["brasov", "ROM", "f", false], ["debrecen", "UNG", "f", false], ["sofia", "BUL", "f", false],
	["giannina", "GRE", "f", false], ["giannina", "GRE", "f", false],
	["belgrado", "JUG", "f", false], ["zagabria", "JUG", "f", false], ["nis", "JUG", "f", false],
]

var aree := {}            # id -> dizionario dell'area
var per_indice := {}      # indice nell'immagine aree.png -> id
var mari: Array = []
var mari_adiacenti := {}  # mare -> [mari]
var linee_sbarco: Array = []
var linee_med: Array = []
var sbarchi_d := {}
var img := Vector2(4967, 3508)

func carica() -> void:
	var f := FileAccess.open("res://assets/dati/mappa.json", FileAccess.READ)
	var d: Dictionary = JSON.parse_string(f.get_as_text())
	aree = d["aree"]
	for id in aree:
		per_indice[int(aree[id]["idx"])] = id
	mari = d["mari"]
	for m in mari:
		mari_adiacenti[m] = []
	for c in d["mari_adiacenti"]:
		mari_adiacenti[c[0]].append(c[1])
		mari_adiacenti[c[1]].append(c[0])
	linee_sbarco = d["linee_sbarco"]
	linee_med = d["linee_med"]
	sbarchi_d = d["sbarchi_d"]
	img = Vector2(d["img"][0], d["img"][1])

func nome(id: String) -> String:
	return str(aree[id]["n"]) if aree.has(id) else id

func nazione(id: String) -> String:
	return str(aree[id]["naz"])

## nazione "di casa" (le colonie contano come la madrepatria solo dove serve)
func patria(id: String) -> String:
	var n := nazione(id)
	return COLONIE.get(n, n)

func africa(id: String) -> bool:
	return nazione(id) in ["LIB", "EGI", "AFN"]

func america(id: String) -> bool:
	return id == "usa" or id == "canada"

func terreni(id: String) -> Array:
	return aree[id].get("terr", [])

func pianura(id: String) -> bool:
	return terreni(id).is_empty()

func fortezza(id: String) -> bool:
	return aree[id].has("fort")

func confine(difesa: String, attacco: String) -> Dictionary:
	return aree[difesa].get("conf", {}).get(attacco, {})

func costiera(id: String) -> bool:
	return not (aree[id]["mari"] as Array).is_empty()

static func fattore(naz: String, tipo: String, ridotta: bool, area_africa := false) -> int:
	var t: Array = ARMATE[naz][tipo] if ARMATE.has(naz) and ARMATE[naz].has(tipo) else [3, 2, 0]
	if tipo == "k" and not area_africa:
		return 3 if ridotta else 5
	if tipo == "p":
		return 2 if ridotta else 3
	return int(t[1]) if ridotta else int(t[0])

static func sostegno(ridotta: bool) -> int:
	return 1 if ridotta else 2

static func corazzata(tipo: String) -> bool:
	return tipo in ["a", "c", "k"]

static func anno(turno: int) -> int:
	return 1940 + (turno - 1) / 4

static func stagione(turno: int) -> int:
	return (turno - 1) % 4

static func inverno(turno: int) -> bool:
	return stagione(turno) == 0

static func data(turno: int) -> String:
	return "%s %d" % [STAGIONI[stagione(turno)], anno(turno)]

## aree di rifornimento in cui una potenza maggiore costruisce le armate
func sedi_costruzione(naz: String) -> Array:
	var out := []
	for id in aree:
		var a: Dictionary = aree[id]
		if not a.has("rif"):
			continue
		var n := str(a["naz"])
		if naz == "GB" and (n == "GB" or id == "suez"):
			out.append(id)
		elif naz == n and id != "suez":
			out.append(id)
	return out

func capitale(naz: String) -> String:
	for id in aree:
		if str(aree[id].get("cap", "")) == naz:
			return id
	return ""

func aree_di(naz: String) -> Array:
	var out := []
	for id in aree:
		if str(aree[id]["naz"]) == naz:
			out.append(id)
	return out

## componenti dei mari percorribili per un lato (l'Asse non passa Gibilterra né il Mar Nero)
func mari_collegati(lato: String, m: String) -> Array:
	var visti := {m: true}
	var coda := [m]
	while not coda.is_empty():
		var x: String = coda.pop_back()
		for y in mari_adiacenti[x]:
			if visti.has(y):
				continue
			if lato == "asse" and ((x == "Atlantico" and y == "Mediterraneo occ.") or (y == "Atlantico" and x == "Mediterraneo occ.")):
				continue
			visti[y] = true
			coda.append(y)
	return visti.keys()
