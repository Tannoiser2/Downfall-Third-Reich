## Tavolo 3D: la mappa originale come tabellone, armate come modellini 3D (o pedine originali),
## evidenziazioni delle aree con uno shader, segnalini di controllo, frecce e telecamera orbitale.
## Comandi: mouse (sinistro trascina = sposta, destro trascina = ruota/inclina, rotella = zoom),
## trackpad (pizzico = zoom, due dita = sposta, Maiusc + due dita = ruota),
## tocco (un dito = sposta, due dita = zoom e rotazione, due dita in verticale = inclinazione).
class_name Vista3D
extends Node3D

signal area_cliccata(id: String)
signal area_sopra(id: String)

const LARGHEZZA := 40.0
const COLORE_NAZ := {
	"GER": Color(0.42, 0.44, 0.45), "ITA": Color(0.56, 0.6, 0.42), "FIN": Color(0.85, 0.87, 0.9), "ROM": Color(0.62, 0.55, 0.28),
	"UNG": Color(0.4, 0.62, 0.55), "BUL": Color(0.55, 0.36, 0.5), "GB": Color(0.62, 0.52, 0.34), "USA": Color(0.42, 0.45, 0.25),
	"FRA": Color(0.33, 0.45, 0.68), "BEL": Color(0.3, 0.34, 0.42), "GRE": Color(0.3, 0.5, 0.75), "JUG": Color(0.55, 0.38, 0.22),
	"URSS": Color(0.62, 0.22, 0.16),
}
const COLORE_LATO := {"asse": Color(0.2, 0.2, 0.22), "alleati": Color(0.35, 0.42, 0.22), "urss": Color(0.7, 0.18, 0.12), "": Color(0.6, 0.6, 0.6)}

var D: Dati
var altezza := 28.0
var cam: Camera3D
var bersaglio := Vector3.ZERO
var distanza := 30.0
var imbardata := 0.0
var beccheggio := 62.0
var modelli := true
var _piano: MeshInstance3D
var _mat_piano: ShaderMaterial
var _img_aree: Image
var _img_evid: Image
var _tex_evid: ImageTexture
var _evid := {}          # area -> Color
var _pedine := {}        # uid -> Node3D
var _segnalini := {}     # area -> Node3D
var _tex_cache := {}
var _font: Font
var _tocchi := {}
var _trascina := false
var _premuto := false
var _premuto_pos := Vector2.ZERO
var _ruota := false
var _ultimo_sopra := ""
var _frecce: Node3D = null
var tempo_anim := 0.3

func prepara(dati: Dati) -> void:
	D = dati
	altezza = LARGHEZZA * D.img.y / D.img.x
	_font = load("res://assets/font/Oswald.ttf")
	for c in get_children():
		c.queue_free()
	_pedine.clear()
	_segnalini.clear()
	_frecce = null
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.07, 0.1, 0.13)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.82, 0.84, 0.88)
	e.ambient_light_energy = 0.5
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_white = 1.5
	env.environment = e
	add_child(env)
	var sole := DirectionalLight3D.new()
	sole.rotation_degrees = Vector3(-55, -35, 0)
	sole.light_energy = 0.75
	sole.shadow_enabled = true
	sole.directional_shadow_max_distance = 60.0
	add_child(sole)
	# tavolo
	var tavolo := MeshInstance3D.new()
	var tm := PlaneMesh.new()
	tm.size = Vector2(LARGHEZZA * 2.4, altezza * 2.6)
	tavolo.mesh = tm
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.17, 0.13, 0.1)
	mt.roughness = 0.9
	tavolo.material_override = mt
	tavolo.position.y = -0.06
	add_child(tavolo)
	# bordo del tabellone
	var bordo := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(LARGHEZZA + 0.5, 0.1, altezza + 0.5)
	bordo.mesh = bm
	var mb := StandardMaterial3D.new()
	mb.albedo_color = Color(0.1, 0.12, 0.14)
	bordo.material_override = mb
	bordo.position.y = -0.055
	add_child(bordo)
	# tabellone con lo shader delle aree
	_piano = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(LARGHEZZA, altezza)
	_piano.mesh = pm
	_mat_piano = ShaderMaterial.new()
	_mat_piano.shader = load("res://scripts/mappa.gdshader")
	var tex_aree: Texture2D = load("res://assets/mappa/aree.png")
	_img_aree = tex_aree.get_image()
	if _img_aree.is_compressed():
		_img_aree.decompress()
	_mat_piano.set_shader_parameter("mappa", load("res://assets/mappa/mappa.jpg"))
	_mat_piano.set_shader_parameter("aree", tex_aree)
	_mat_piano.set_shader_parameter("passo", Vector2(1.0 / _img_aree.get_width(), 1.0 / _img_aree.get_height()))
	_img_evid = Image.create(256, 1, false, Image.FORMAT_RGBA8)
	_img_evid.fill(Color(0, 0, 0, 0))
	_tex_evid = ImageTexture.create_from_image(_img_evid)
	_mat_piano.set_shader_parameter("evid", _tex_evid)
	_piano.material_override = _mat_piano
	add_child(_piano)
	cam = Camera3D.new()
	cam.fov = 42
	cam.far = 400
	add_child(cam)
	bersaglio = Vector3(-2.0, 0, -2.5)
	_aggiorna_camera()

# -------------------------------------------------------------------------------------
# Coordinate
# -------------------------------------------------------------------------------------

func mondo(id: String) -> Vector3:
	if not D.aree.has(id):
		return Vector3.ZERO
	var a: Dictionary = D.aree[id]
	return Vector3((float(a["x"]) - 0.5) * LARGHEZZA, 0.0, (float(a["y"]) - 0.5) * altezza)

func area_a(pos: Vector2) -> String:
	var p = _punto_terra(pos)
	if p == null:
		return ""
	var pt: Vector3 = p
	var u := pt.x / LARGHEZZA + 0.5
	var v := pt.z / altezza + 0.5
	if u < 0 or u >= 1 or v < 0 or v >= 1:
		return ""
	var px := int(u * _img_aree.get_width())
	var py := int(v * _img_aree.get_height())
	var idx := int(round(_img_aree.get_pixel(px, py).r * 255.0))
	return D.per_indice.get(idx, "")

func _punto_terra(pos: Vector2) -> Variant:
	var o := cam.project_ray_origin(pos)
	var dir := cam.project_ray_normal(pos)
	if absf(dir.y) < 0.0001:
		return null
	var t := -o.y / dir.y
	if t < 0:
		return null
	return o + dir * t

# -------------------------------------------------------------------------------------
# Evidenziazioni (shader)
# -------------------------------------------------------------------------------------

## gruppi: nome -> [aree, colore]; ridisegna tutte le evidenziazioni
func evidenzia(gruppi: Array) -> void:
	_img_evid.fill(Color(0, 0, 0, 0))
	for g in gruppi:
		var col: Color = g[1]
		for id in g[0]:
			if D.aree.has(id):
				_img_evid.set_pixel(int(D.aree[id]["idx"]), 0, col)
	_tex_evid.update(_img_evid)

func imposta_bordo(id: String) -> void:
	_mat_piano.set_shader_parameter("sel", float(D.aree[id]["idx"]) if D.aree.has(id) else -1.0)

func imposta_sopra(id: String) -> void:
	_mat_piano.set_shader_parameter("sopra", float(D.aree[id]["idx"]) if D.aree.has(id) else -1.0)

# -------------------------------------------------------------------------------------
# Modellini e pedine
# -------------------------------------------------------------------------------------

func _texture(nome: String) -> Texture2D:
	if _tex_cache.has(nome):
		return _tex_cache[nome]
	var path := "res://assets/pedine/%s.webp" % nome
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path)
	_tex_cache[nome] = t
	return t

static func immagine_unita(u: Dictionary) -> String:
	var naz: String = u["naz"]
	var t: String = u["t"]
	var r: bool = u["r"]
	if t == "k":
		return "DAK_ar_4" if r else "DAK_a_7"
	var tab := {
		"GER": {"f": ["GER_f_5", "GER_fr_3"], "a": ["GER_a_6", "GER_ar_4"], "c": ["GER_c_8", "GER_cr_5"]},
		"GB": {"f": ["GB_f_4", "GB_fr_2"], "a": ["GB_a_5", "GB_ar_3"], "c": ["GB_c_6", "GB_cr_4"]},
		"USA": {"f": ["USA_f_4", "USA_fr_2"], "c": ["USA_c_6", "USA_cr_4"]},
		"FRA": {"f": ["FRA_f_3", "FRA_fr_2"], "a": ["FRA_a_5", "FRA_ar_3"]},
		"URSS": {"f": ["URSS_f_3", "URSS_fr_2"], "a": ["URSS_a_5", "URSS_ar_3"], "c": ["URSS_c_7", "URSS_cr_4"], "g": ["URSS_g_5", "URSS_gr_3"]},
		"ITA": {"f": ["ITA_f_3", "ITA_fr_2"]}, "FIN": {"f": ["FIN_f_4", "FIN_fr_2"]}, "ROM": {"f": ["ROM_f_4", "ROM_fr_2"]},
		"UNG": {"f": ["UNG_f_4", "UNG_fr_2"]}, "BUL": {"f": ["BUL_f_3", "BUL_fr_2"]}, "BEL": {"f": ["BEL_f_3", "BEL_r_2"]},
		"GRE": {"f": ["GRE_f_3", "GRE_fr_2"]}, "JUG": {"f": ["JUG_f_3", "JUG_fr_2"]},
	}
	var n: Array = tab.get(naz, {}).get(t, tab.get(naz, {}).get("f", ["GER_f_5", "GER_fr_3"]))
	return n[1] if r else n[0]

func lato_pedina() -> float:
	return 0.62

func _mat(c: Color, rough := 0.75, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m

func _box(sz: Vector3, pos: Vector3, mat: Material, par: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = sz
	mi.mesh = b
	mi.material_override = mat
	mi.position = pos
	par.add_child(mi)
	return mi

func _cil(r1: float, r2: float, h: float, pos: Vector3, mat: Material, par: Node3D, seg := 12) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = r1
	c.bottom_radius = r2
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	mi.mesh = c
	mi.material_override = mat
	mi.position = pos
	par.add_child(mi)
	return mi

func _sfera(r: float, pos: Vector3, mat: Material, par: Node3D, mezza := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * (1.0 if mezza else 2.0)
	s.is_hemisphere = mezza
	s.radial_segments = 12
	s.rings = 6
	mi.mesh = s
	mi.material_override = mat
	mi.position = pos
	par.add_child(mi)
	return mi

## modellino 3D: carro armato o soldato sulla basetta col colore della nazione
func _crea_modello(u: Dictionary) -> Node3D:
	var nodo := Node3D.new()
	var naz: String = u["naz"]
	var col: Color = COLORE_NAZ.get(naz, Color.GRAY)
	if u["t"] == "k":
		col = Color(0.76, 0.66, 0.42)
	var rid: bool = u["r"]
	var lp := lato_pedina()
	# basetta: anello del colore del lato, piatto della nazione
	var lato: String = D.LATO_NAZ.get(naz, "")
	_cil(lp * 0.5, lp * 0.52, 0.05, Vector3(0, 0.025, 0), _mat(COLORE_LATO[lato].darkened(0.1), 0.6), nodo, 20)
	var piatto := _cil(lp * 0.44, lp * 0.44, 0.012, Vector3(0, 0.056, 0), _mat(col.lightened(0.15), 0.8), nodo, 20)
	piatto.name = "Piatto"
	var corpo := Node3D.new()
	corpo.name = "Corpo"
	nodo.add_child(corpo)
	var sc := 0.82 if rid else 1.0
	corpo.scale = Vector3(sc, sc, sc)
	corpo.position.y = 0.06
	var mcol := _mat(col, 0.7)
	var scuro := _mat(col.darkened(0.45), 0.85)
	if Dati.corazzata(u["t"]):
		var grande: bool = u["t"] == "c"
		var L := 0.42 if grande else 0.36
		# cingoli
		_box(Vector3(L, 0.07, 0.07), Vector3(0, 0.035, 0.1), scuro, corpo)
		_box(Vector3(L, 0.07, 0.07), Vector3(0, 0.035, -0.1), scuro, corpo)
		# scafo
		_box(Vector3(L * 0.92, 0.07, 0.19), Vector3(0, 0.095, 0), mcol, corpo)
		# torretta
		var tor := _cil(0.07 if grande else 0.06, 0.085 if grande else 0.075, 0.06, Vector3(-0.02, 0.16, 0), mcol, corpo, 10)
		tor.scale = Vector3(1.25, 1, 1)
		# cannone
		var can := _cil(0.012, 0.014, 0.24 if grande else 0.19, Vector3(0.12 if grande else 0.1, 0.165, 0), scuro, corpo, 6)
		can.rotation_degrees = Vector3(0, 0, 90)
		if naz == "URSS" or naz == "GER":
			# stella o croce: piccolo quadrato chiaro sulla torretta
			_box(Vector3(0.03, 0.002, 0.03), Vector3(-0.02, 0.192, 0), _mat(Color(0.95, 0.95, 0.9) if naz == "GER" else Color(0.9, 0.15, 0.1)), corpo)
	else:
		# soldato stilizzato con fucile; due figure se l'armata è piena
		var pelle := _mat(Color(0.86, 0.7, 0.58), 0.8)
		var figure := 1 if rid else 2
		for k in figure:
			var ox := 0.0 if figure == 1 else (-0.08 + 0.16 * k)
			var oz := 0.0 if figure == 1 else (0.04 - 0.08 * k)
			_cil(0.035, 0.045, 0.1, Vector3(ox - 0.012, 0.05, oz + 0.02), scuro, corpo, 8)
			_cil(0.035, 0.045, 0.1, Vector3(ox + 0.012, 0.05, oz - 0.02), scuro, corpo, 8)
			_cil(0.05, 0.06, 0.13, Vector3(ox, 0.165, oz), mcol, corpo, 10)
			_sfera(0.035, Vector3(ox, 0.26, oz), pelle, corpo)
			var elmo_col := col.darkened(0.25)
			if u["t"] == "g":
				elmo_col = Color(0.75, 0.12, 0.1)
			_sfera(0.044, Vector3(ox, 0.27, oz), _mat(elmo_col, 0.5, 0.2), corpo, true)
			var fucile := _box(Vector3(0.012, 0.2, 0.012), Vector3(ox + 0.05, 0.19, oz + 0.02), _mat(Color(0.3, 0.2, 0.12)), corpo)
			fucile.rotation_degrees = Vector3(0, 0, -12)
		if u.get("par", false):
			_box(Vector3(0.004, 0.16, 0.004), Vector3(0.12, 0.2, -0.08), scuro, corpo)
			_box(Vector3(0.002, 0.06, 0.09), Vector3(0.12, 0.25, -0.04), _mat(Color(0.8, 0.1, 0.1)), corpo)
	# cartellino col fattore di combattimento
	var l := Label3D.new()
	l.font = _font
	l.font_size = 48
	l.pixel_size = 0.0042
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = false
	l.outline_size = 10
	l.outline_modulate = Color(0.05, 0.05, 0.05)
	l.modulate = Color(1, 0.97, 0.88)
	l.position = Vector3(0, 0.42, 0)
	l.name = "Numero"
	nodo.add_child(l)
	nodo.set_meta("spess", 0.06)
	return nodo

## pedina originale di cartone
func _crea_pedina(u: Dictionary) -> Node3D:
	var nodo := Node3D.new()
	var lp := lato_pedina() * 0.92
	var spess := 0.07
	var corpo := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(lp, spess, lp)
	corpo.mesh = bm
	corpo.material_override = _mat(Color(0.86, 0.82, 0.72), 0.8)
	corpo.position.y = spess / 2
	nodo.add_child(corpo)
	var faccia := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(lp * 0.99, lp * 0.99)
	faccia.mesh = qm
	faccia.rotation_degrees = Vector3(-90, 0, 0)
	faccia.position.y = spess + 0.002
	var mf := StandardMaterial3D.new()
	mf.albedo_texture = _texture(immagine_unita(u))
	mf.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mf.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	faccia.material_override = mf
	faccia.name = "Faccia"
	nodo.add_child(faccia)
	nodo.set_meta("spess", spess)
	return nodo

func _crea(u: Dictionary) -> Node3D:
	var n := _crea_modello(u) if modelli else _crea_pedina(u)
	n.set_meta("firma", _firma(u))
	return n

func _firma(u: Dictionary) -> String:
	return "%s%s%s%s" % [u["naz"], u["t"], u["r"], modelli]

## posizioni degli slot attorno al centro dell'area: armate del lato a sinistra, nemici a destra
func _slot(i: int, n: int, gruppo: int, gruppi: int) -> Vector3:
	var passo := lato_pedina() * 1.02
	var x := (float(i) - float(n - 1) / 2.0) * passo
	var z := 0.0
	if gruppi > 1:
		z = (float(gruppo) - float(gruppi - 1) / 2.0) * passo * 1.05
	return Vector3(x, 0, z)

func aggiorna(m: Motore, anima := true) -> void:
	var st: Dictionary = m.s
	var viste := {}
	var per_area := {}
	for uid in st["u"]:
		var u: Dictionary = st["u"][uid]
		var h: String = u["h"]
		if not per_area.has(h):
			per_area[h] = {}
		var l: String = D.LATO_NAZ[u["naz"]]
		if not per_area[h].has(l):
			per_area[h][l] = []
		per_area[h][l].append(uid)
	for h in per_area:
		var lati: Array = per_area[h].keys()
		lati.sort_custom(func(a, b): return Dati.LATI.find(a) < Dati.LATI.find(b))
		var base := mondo(h)
		for g in lati.size():
			var lista: Array = per_area[h][lati[g]]
			lista.sort_custom(func(a, b): return _ordine(st["u"][a]) < _ordine(st["u"][b]))
			for i in lista.size():
				var uid: String = lista[i]
				var u: Dictionary = st["u"][uid]
				viste[uid] = true
				var nodo: Node3D = _pedine.get(uid)
				if nodo != null and nodo.get_meta("firma") != _firma(u):
					nodo.queue_free()
					nodo = null
				if nodo == null:
					nodo = _crea(u)
					add_child(nodo)
					_pedine[uid] = nodo
					nodo.position = base + _slot(i, lista.size(), g, lati.size()) + Vector3(0, 0.8, 0)
					if lati[g] == "asse":
						nodo.rotation_degrees.y = 180
				var lab: Label3D = nodo.get_node_or_null("Numero")
				if lab != null:
					lab.text = m.sigla_unita(uid)
				_imposta_usata(nodo, str(u.get("op", "")) != "" and D.LATO_NAZ[u["naz"]] == st["lato"])
				var dest := base + _slot(i, lista.size(), g, lati.size())
				var dest_prec: Vector3 = nodo.get_meta("dest", nodo.position)
				var area_prec: String = nodo.get_meta("area", h)
				nodo.set_meta("dest", dest)
				nodo.set_meta("area", h)
				if dest_prec.distance_to(dest) < 0.01:
					continue
				if nodo.has_meta("tw"):
					var tp = nodo.get_meta("tw")
					if tp is Tween and (tp as Tween).is_valid():
						(tp as Tween).kill()
				if anima:
					var tw := create_tween()
					nodo.set_meta("tw", tw)
					if area_prec != h:
						var su := (nodo.position + dest) / 2 + Vector3(0, 1.0, 0)
						tw.tween_property(nodo, "position", su, tempo_anim * 0.5)
						tw.tween_property(nodo, "position", dest, tempo_anim * 0.5)
					else:
						tw.tween_property(nodo, "position", dest, tempo_anim * 0.4)
				else:
					nodo.position = dest
	for uid in _pedine.keys():
		if not viste.has(uid):
			var n: Node3D = _pedine[uid]
			_pedine.erase(uid)
			if anima:
				var tw := create_tween()
				tw.tween_property(n, "scale", Vector3(0.05, 0.05, 0.05), 0.35)
				tw.tween_callback(n.queue_free)
			else:
				n.queue_free()
	_aggiorna_controllo(m)

func _ordine(u: Dictionary) -> int:
	return {"f": 0, "g": 1, "a": 2, "k": 3, "c": 4}.get(u["t"], 0) + (0 if u["r"] else 10)

func _imposta_usata(nodo: Node3D, usata: bool) -> void:
	var f: MeshInstance3D = nodo.get_node_or_null("Faccia")
	if f != null:
		(f.material_override as StandardMaterial3D).albedo_color = Color(0.62, 0.62, 0.62) if usata else Color(1, 1, 1)
	var p: MeshInstance3D = nodo.get_node_or_null("Piatto")
	if p != null:
		var m := p.material_override as StandardMaterial3D
		if not nodo.has_meta("col_piatto"):
			nodo.set_meta("col_piatto", m.albedo_color)
		var c0: Color = nodo.get_meta("col_piatto")
		m.albedo_color = c0.darkened(0.55) if usata else c0

## segnalini di controllo sulle aree passate di mano
func _aggiorna_controllo(m: Motore) -> void:
	var visti := {}
	for id in m.s["ctrl"]:
		var c: String = m.s["ctrl"][id]
		var atteso: String = D.LATO_NAZ.get(D.patria(id), "")
		if id == "carelia":
			atteso = "asse"
		if c == atteso or c == "":
			continue
		visti[id] = true
		var nodo: Node3D = _segnalini.get(id)
		if nodo != null and nodo.get_meta("c") == c:
			continue
		if nodo != null:
			nodo.queue_free()
		nodo = Node3D.new()
		var r := 0.2
		_cil(r, r, 0.04, Vector3(0, 0.02, 0), _mat(Color(0.8, 0.78, 0.72), 0.8), nodo, 18)
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(r * 2.0, r * 2.0)
		q.mesh = qm
		var mq := StandardMaterial3D.new()
		mq.albedo_texture = _texture("ctl_" + c)
		mq.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mq.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		mq.alpha_scissor_threshold = 0.5
		q.material_override = mq
		q.rotation_degrees = Vector3(-90, 0, 0)
		q.position.y = 0.042
		nodo.add_child(q)
		nodo.position = mondo(id) + Vector3(-0.85, 0.0, -0.55)
		nodo.set_meta("c", c)
		add_child(nodo)
		_segnalini[id] = nodo
	for id in _segnalini.keys():
		if not visti.has(id):
			_segnalini[id].queue_free()
			_segnalini.erase(id)

func ricrea_tutte(m: Motore) -> void:
	for uid in _pedine:
		_pedine[uid].queue_free()
	_pedine.clear()
	aggiorna(m, false)

func posizione_unita(uid: String) -> Vector3:
	var n: Node3D = _pedine.get(uid)
	return n.position if n != null else Vector3.ZERO

# -------------------------------------------------------------------------------------
# Frecce
# -------------------------------------------------------------------------------------

func pulisci_frecce() -> void:
	if _frecce != null:
		for c in _frecce.get_children():
			c.queue_free()

func freccia(da: String, a: String, colore: Color, spessore := 1.0, arco := 0.0) -> void:
	if da == "" or a == "" or da == a:
		return
	freccia_punti(mondo(da), mondo(a), colore, spessore, arco)

func freccia_punti(p0: Vector3, p2: Vector3, colore: Color, spessore := 1.0, arco := 0.0) -> void:
	if _frecce == null:
		_frecce = Node3D.new()
		add_child(_frecce)
	var dir := p2 - p0
	dir.y = 0
	var lung := dir.length()
	if lung < 0.05:
		return
	var n := dir / lung
	p0 = p0 + n * 0.3
	p2 = p2 - n * 0.45
	var punti := []
	var passi := 20
	for i in passi + 1:
		var t := float(i) / float(passi)
		var q := p0.lerp(p2, t)
		q.y = 0.55 + arco * lung * 0.35 * 4.0 * t * (1.0 - t)
		punti.append(q)
	var w := 0.13 * spessore
	var testa := minf(0.36 * spessore, lung * 0.4)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = true
	mat.render_priority = 120
	mat.albedo_color = colore
	var mb := mat.duplicate() as StandardMaterial3D
	mb.albedo_color = Color(0.03, 0.03, 0.03, colore.a * 0.8)
	mb.render_priority = 119
	for k in 2:
		var mi := MeshInstance3D.new()
		mi.mesh = _mesh_freccia(punti, w * (1.6 if k == 0 else 1.0), testa * (1.25 if k == 0 else 1.0))
		mi.material_override = mb if k == 0 else mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_frecce.add_child(mi)

func _mesh_freccia(punti: Array, w: float, testa: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lung_tot := 0.0
	for i in punti.size() - 1:
		lung_tot += (punti[i + 1] - punti[i]).length()
	var percorso := 0.0
	for i in punti.size() - 1:
		var a0: Vector3 = punti[i]
		var a1: Vector3 = punti[i + 1]
		var seg := (a1 - a0).length()
		if percorso + seg > lung_tot - testa * 0.9:
			break
		percorso += seg
		var d2 := a1 - a0
		d2.y = 0
		if d2.length() < 0.0001:
			continue
		d2 = d2.normalized()
		var l2 := Vector3(-d2.z, 0, d2.x) * w * 0.5
		st.add_vertex(a0 - l2)
		st.add_vertex(a0 + l2)
		st.add_vertex(a1 + l2)
		st.add_vertex(a0 - l2)
		st.add_vertex(a1 + l2)
		st.add_vertex(a1 - l2)
	var fine: Vector3 = punti[punti.size() - 1]
	var prima: Vector3 = punti[punti.size() - 3]
	var dt := fine - prima
	dt.y = 0
	dt = dt.normalized()
	var lt := Vector3(-dt.z, 0, dt.x)
	var bp := fine - dt * testa
	bp.y = fine.y
	st.add_vertex(bp - lt * testa * 0.6)
	st.add_vertex(bp + lt * testa * 0.6)
	st.add_vertex(fine + dt * testa * 0.1)
	return st.commit()

## lampo luminoso sopra un'area (combattimento)
func lampo(id: String, colore: Color) -> void:
	var p := mondo(id)
	var luce := OmniLight3D.new()
	luce.light_color = colore
	luce.light_energy = 0.0
	luce.omni_range = 3.5
	luce.position = p + Vector3(0, 1.2, 0)
	add_child(luce)
	var tw := create_tween()
	tw.tween_property(luce, "light_energy", 6.0, 0.12)
	tw.tween_property(luce, "light_energy", 0.0, 0.6)
	tw.tween_callback(luce.queue_free)

func centra_su(id: String) -> void:
	var p := mondo(id)
	var tw := create_tween()
	tw.tween_property(self, "bersaglio", Vector3(p.x, 0, p.z), 0.4)

# -------------------------------------------------------------------------------------
# Telecamera e comandi
# -------------------------------------------------------------------------------------

func _process(_d: float) -> void:
	_aggiorna_camera()

func _aggiorna_camera() -> void:
	if cam == null:
		return
	beccheggio = clampf(beccheggio, 18.0, 89.0)
	distanza = clampf(distanza, 2.5, 55.0)
	bersaglio.x = clampf(bersaglio.x, -LARGHEZZA * 0.55, LARGHEZZA * 0.55)
	bersaglio.z = clampf(bersaglio.z, -altezza * 0.55, altezza * 0.55)
	var b := deg_to_rad(beccheggio)
	var y := deg_to_rad(imbardata)
	var off := Vector3(sin(y) * cos(b), sin(b), cos(y) * cos(b)) * distanza
	cam.position = bersaglio + off
	cam.look_at(bersaglio, Vector3.UP)

func vista_dall_alto() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "beccheggio", 89.0, 0.4)
	tw.tween_property(self, "imbardata", 0.0, 0.4)

func vista_inclinata() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "beccheggio", 55.0, 0.4)

func zoom(f: float) -> void:
	distanza *= f

func _unhandled_input(ev: InputEvent) -> void:
	if cam == null:
		return
	if ev is InputEventScreenTouch:
		var t: InputEventScreenTouch = ev
		if t.pressed:
			_tocchi[t.index] = t.position
			if _tocchi.size() == 1:
				_premuto = true
				_premuto_pos = t.position
				_trascina = false
		else:
			if _tocchi.size() == 1 and _premuto and not _trascina:
				var id := area_a(t.position)
				if id != "":
					area_cliccata.emit(id)
			_tocchi.erase(t.index)
			if _tocchi.is_empty():
				_premuto = false
		get_viewport().set_input_as_handled()
		return
	if ev is InputEventScreenDrag:
		var d: InputEventScreenDrag = ev
		if not _tocchi.has(d.index):
			_tocchi[d.index] = d.position
		var prima: Vector2 = _tocchi[d.index]
		_tocchi[d.index] = d.position
		if _tocchi.size() == 1:
			if d.position.distance_to(_premuto_pos) > 10:
				_trascina = true
			if _trascina:
				_sposta_schermo(d.position - prima)
		elif _tocchi.size() >= 2:
			_trascina = true
			var keys := _tocchi.keys()
			var altro: int = keys[0] if keys[0] != d.index else keys[1]
			var a: Vector2 = _tocchi[altro]
			var v_prima := prima - a
			var v_dopo := d.position - a
			if v_prima.length() > 4 and v_dopo.length() > 4:
				distanza *= v_prima.length() / v_dopo.length()
				imbardata -= rad_to_deg(v_dopo.angle() - v_prima.angle())
			beccheggio += (d.position.y - prima.y) * 0.08
		get_viewport().set_input_as_handled()
		return
	# i clic simulati dal tocco (servono ai pulsanti dell'interfaccia) qui si ignorano: il tocco è già gestito sopra
	if ev is InputEventMouse and (ev as InputEventMouse).device == InputEvent.DEVICE_ID_EMULATION:
		return
	if ev is InputEventMagnifyGesture:
		distanza /= (ev as InputEventMagnifyGesture).factor
		get_viewport().set_input_as_handled()
		return
	if ev is InputEventPanGesture:
		var pg: InputEventPanGesture = ev
		if pg.shift_pressed:
			imbardata += pg.delta.x * 2.0
			beccheggio -= pg.delta.y * 2.0
		else:
			_sposta_schermo(-pg.delta * 12.0)
		get_viewport().set_input_as_handled()
		return
	if ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			distanza *= 0.9
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			distanza *= 1.1
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_premuto = true
				_premuto_pos = mb.position
				_trascina = false
			else:
				if _premuto and not _trascina:
					var id := area_a(mb.position)
					if id != "":
						area_cliccata.emit(id)
				_premuto = false
		elif mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			_ruota = mb.pressed
		get_viewport().set_input_as_handled()
		return
	if ev is InputEventMouseMotion:
		var mm: InputEventMouseMotion = ev
		if _premuto and _tocchi.is_empty():
			if mm.position.distance_to(_premuto_pos) > 6:
				_trascina = true
			if _trascina:
				_sposta_schermo(mm.relative)
		elif _ruota:
			imbardata -= mm.relative.x * 0.3
			beccheggio += mm.relative.y * 0.25
		else:
			var id := area_a(mm.position)
			if id != _ultimo_sopra:
				_ultimo_sopra = id
				imposta_sopra(id)
				area_sopra.emit(id)

func _sposta_schermo(delta: Vector2) -> void:
	var vp := get_viewport().get_visible_rect().size
	var scala := distanza * 2.0 * tan(deg_to_rad(cam.fov / 2.0)) / maxf(1.0, vp.y)
	var y := deg_to_rad(imbardata)
	var destra := Vector3(cos(y), 0, -sin(y))
	var avanti := Vector3(-sin(y), 0, -cos(y))
	var corr := 1.0 / maxf(0.35, sin(deg_to_rad(beccheggio)))
	bersaglio -= destra * delta.x * scala
	bersaglio += avanti * delta.y * scala * corr
