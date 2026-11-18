## Interfaccia di Downfall of the Third Reich: menu, pannelli, selezione delle armate,
## ciclo dell'IA, salvataggi e gioco online.
extends Node

const VERSIONE := "1.0"

# colori presi dalla mappa: carta, blu del mare e del titolo, rosso sovietico, grigio tedesco, oliva alleato
const C_CARTA := Color(0.94, 0.9, 0.81)
const C_CARTA_SCURA := Color(0.86, 0.8, 0.68)
const C_INCHIOSTRO := Color(0.12, 0.13, 0.15)
const C_BLU := Color(0.17, 0.42, 0.6)
const C_BLU_SCURO := Color(0.09, 0.2, 0.3)
const C_NOTTE := Color(0.07, 0.11, 0.15, 0.93)
const C_ORO := Color(0.93, 0.78, 0.42)
const COL_LATO := {"asse": Color(0.36, 0.37, 0.39), "alleati": Color(0.45, 0.5, 0.27), "urss": Color(0.72, 0.27, 0.18)}
const COL_FRECCIA := {"asse": Color(0.15, 0.15, 0.17, 0.95), "alleati": Color(0.35, 0.65, 0.2, 0.95), "urss": Color(0.9, 0.2, 0.12, 0.95)}

var D: Dati
var m: Motore
var ia: IA
var rete: Rete
var vista: Vista3D

var F_TITOLO: Font
var F_TESTO: Font
var F_SEMI: Font
var F_GRASSETTO: Font
var F_CORSIVO: Font
var F_NUMERI: Font

var ui: CanvasLayer
var radice: Control
var barra: PanelContainer
var lab_data: Label
var lab_lato: Label
var lab_azioni: Label
var box_scorte: HBoxContainer
var sinistra: PanelContainer
var cont_sx: VBoxContainer
var destra: PanelContainer
var cont_dx: VBoxContainer
var diario: PanelContainer
var lab_diario: RichTextLabel
var popup: Control
var toast: PanelContainer
var lab_toast: Label
var dadi: PanelContainer
var menu: Control
var comandi_vista: VBoxContainer
var bottone_modelli: Button
var pannelli_visibili := true

var umani := {"asse": true, "alleati": false, "urss": false}
var livello := "normale"
var velocita := 1.0
var in_partita := false
var online := false
var codice := ""
var posto := -1
var miei_lati: Array = []
var host := false
var n_applicate := 0
var _attesa_rete := 0.0
var _invio_in_corso := false
var _sincro_in_corso := false

var sel_area := ""
var sel_unita := ""
var _pausa := 0.0
var _rifiuti_ia := 0
var _salva_timer := 0.0
var _ultimo_tiro_visto := 0
var _dadi_tempo := 0.0
var _toast_tempo := 0.0
var _contrasto_aperto := false

func _ready() -> void:
	F_TITOLO = load("res://assets/font/BebasNeue-Regular.ttf")
	F_TESTO = load("res://assets/font/BarlowCondensed-Regular.ttf")
	F_SEMI = load("res://assets/font/BarlowCondensed-SemiBold.ttf")
	F_GRASSETTO = load("res://assets/font/BarlowCondensed-Bold.ttf")
	F_CORSIVO = load("res://assets/font/BarlowCondensed-Italic.ttf")
	F_NUMERI = load("res://assets/font/Oswald.ttf")
	D = Dati.new()
	D.carica()
	rete = Rete.new()
	add_child(rete)
	vista = Vista3D.new()
	add_child(vista)
	vista.prepara(D)
	vista.area_cliccata.connect(_clic_area)
	vista.area_sopra.connect(_sopra_area)
	ui = CanvasLayer.new()
	add_child(ui)
	_costruisci_ui()
	_carica_preferenze()
	_mostra_menu()

# =====================================================================================
# Tema
# =====================================================================================

func _stile(fondo: Color, bordo: Color, spessore := 2, raggio := 4, margine := 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fondo
	s.border_color = bordo
	s.set_border_width_all(spessore)
	s.set_corner_radius_all(raggio)
	s.content_margin_left = margine
	s.content_margin_right = margine
	s.content_margin_top = margine * 0.7
	s.content_margin_bottom = margine * 0.7
	return s

func _tema() -> Theme:
	var t := Theme.new()
	t.default_font = F_TESTO
	t.default_font_size = 21
	t.set_color("font_color", "Label", C_INCHIOSTRO)
	t.set_stylebox("normal", "Button", _stile(C_BLU, C_BLU_SCURO, 2, 3, 12))
	t.set_stylebox("hover", "Button", _stile(C_BLU.lightened(0.15), C_ORO, 2, 3, 12))
	t.set_stylebox("pressed", "Button", _stile(C_BLU_SCURO, C_ORO, 2, 3, 12))
	t.set_stylebox("disabled", "Button", _stile(Color(0.55, 0.56, 0.55), Color(0.42, 0.43, 0.42), 2, 3, 12))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", Color(0.98, 0.96, 0.9))
	t.set_color("font_hover_color", "Button", Color(1, 0.97, 0.86))
	t.set_color("font_pressed_color", "Button", Color(1, 0.95, 0.8))
	t.set_color("font_disabled_color", "Button", Color(0.85, 0.84, 0.8))
	t.set_font("font", "Button", F_SEMI)
	t.set_font_size("font_size", "Button", 21)
	t.set_color("font_color", "CheckBox", C_INCHIOSTRO)
	t.set_color("font_hover_color", "CheckBox", C_BLU)
	t.set_color("font_pressed_color", "CheckBox", C_INCHIOSTRO)
	t.set_color("font_hover_pressed_color", "CheckBox", C_BLU)
	for st in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		t.set_stylebox(st, "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("normal", "LineEdit", _stile(Color(1, 0.99, 0.95), C_BLU, 2, 3, 8))
	t.set_stylebox("focus", "LineEdit", _stile(Color(1, 0.99, 0.95), C_ORO, 2, 3, 8))
	t.set_color("font_color", "LineEdit", C_INCHIOSTRO)
	t.set_stylebox("panel", "PanelContainer", _stile(C_CARTA, C_BLU_SCURO, 3, 5, 12))
	t.set_stylebox("panel", "TooltipPanel", _stile(C_CARTA, C_BLU, 2, 3, 8))
	t.set_color("font_color", "TooltipLabel", C_INCHIOSTRO)
	t.set_font("font", "TooltipLabel", F_TESTO)
	t.set_font_size("font_size", "TooltipLabel", 19)
	t.set_color("default_color", "RichTextLabel", C_INCHIOSTRO)
	t.set_font("normal_font", "RichTextLabel", F_TESTO)
	t.set_font("bold_font", "RichTextLabel", F_GRASSETTO)
	t.set_font("italics_font", "RichTextLabel", F_CORSIVO)
	for k in ["normal_font_size", "bold_font_size", "italics_font_size"]:
		t.set_font_size(k, "RichTextLabel", 19)
	return t

func _etichetta(testo: String, dim := 20, font: Font = null, colore := C_INCHIOSTRO) -> Label:
	var l := Label.new()
	l.text = testo
	l.add_theme_font_size_override("font_size", dim)
	if font != null:
		l.add_theme_font_override("font", font)
	l.add_theme_color_override("font_color", colore)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size = Vector2(60, 0)
	return l

func titolo(testo: String, dim := 30, colore := C_BLU_SCURO) -> Label:
	var l := _etichetta(testo, dim, F_TITOLO, colore)
	return l

func _bottone(testo: String, azione: Callable, abilitato := true, suggerimento := "") -> Button:
	var b := Button.new()
	b.text = testo
	b.disabled = not abilitato
	b.pressed.connect(azione)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.tooltip_text = suggerimento
	# larghezza minima pari alla parola più lunga: il testo va a capo tra le parole, mai lettera per lettera
	var largo := 0.0
	for parola in testo.split(" ", false):
		largo = maxf(largo, F_SEMI.get_string_size(parola, HORIZONTAL_ALIGNMENT_LEFT, -1, 21).x)
	b.custom_minimum_size = Vector2(minf(largo + 34.0, 380.0), 42)
	return b

func _separatore() -> HSeparator:
	var s := HSeparator.new()
	var st := StyleBoxLine.new()
	st.color = Color(C_BLU_SCURO, 0.5)
	st.thickness = 2
	s.add_theme_stylebox_override("separator", st)
	return s

func _scroll(contenuto: Control, altezza_min := 0.0) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.custom_minimum_size = Vector2(0, altezza_min)
	contenuto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(contenuto)
	return sc

# =====================================================================================
# Costruzione dell'interfaccia
# =====================================================================================

func _costruisci_ui() -> void:
	radice = Control.new()
	radice.set_anchors_preset(Control.PRESET_FULL_RECT)
	radice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	radice.theme = _tema()
	ui.add_child(radice)
	# barra in alto
	barra = PanelContainer.new()
	barra.add_theme_stylebox_override("panel", _stile(C_NOTTE, C_BLU, 0, 0, 12))
	barra.set_anchors_preset(Control.PRESET_TOP_WIDE)
	barra.custom_minimum_size = Vector2(0, 66)
	radice.add_child(barra)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 18)
	barra.add_child(hb)
	var logo := _etichetta("DOWNFALL", 32, F_TITOLO, C_ORO)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	logo.custom_minimum_size = Vector2(110, 0)
	logo.autowrap_mode = TextServer.AUTOWRAP_OFF
	hb.add_child(logo)
	lab_data = _etichetta("", 26, F_TITOLO, Color(0.96, 0.94, 0.88))
	lab_data.custom_minimum_size = Vector2(230, 0)
	lab_data.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	lab_data.autowrap_mode = TextServer.AUTOWRAP_OFF
	hb.add_child(lab_data)
	lab_lato = _etichetta("", 24, F_TITOLO, Color(1, 1, 1))
	lab_lato.custom_minimum_size = Vector2(260, 0)
	lab_lato.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	lab_lato.autowrap_mode = TextServer.AUTOWRAP_OFF
	hb.add_child(lab_lato)
	lab_azioni = _etichetta("", 21, F_SEMI, Color(0.95, 0.93, 0.86))
	lab_azioni.custom_minimum_size = Vector2(150, 0)
	lab_azioni.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	lab_azioni.autowrap_mode = TextServer.AUTOWRAP_OFF
	hb.add_child(lab_azioni)
	box_scorte = HBoxContainer.new()
	box_scorte.add_theme_constant_override("separation", 14)
	box_scorte.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(box_scorte)
	var bm := _bottone("Menu", _apri_menu_partita)
	bm.custom_minimum_size = Vector2(110, 42)
	hb.add_child(bm)
	# comandi della vista, in colonna a destra della mappa
	comandi_vista = VBoxContainer.new()
	comandi_vista.anchor_left = 1
	comandi_vista.anchor_right = 1
	comandi_vista.offset_left = -400 - 112
	comandi_vista.offset_right = -400 - 12
	comandi_vista.offset_top = 80
	comandi_vista.add_theme_constant_override("separation", 6)
	radice.add_child(comandi_vista)
	for x in [["Zoom +", func(): vista.zoom(0.8)], ["Zoom -", func(): vista.zoom(1.25)], ["Dall'alto", func(): vista.vista_dall_alto()],
			["Inclinata", func(): vista.vista_inclinata()], ["Pedine", _cambia_modelli], ["Pannelli", _cambia_pannelli]]:
		var b := _bottone(x[0], x[1])
		b.custom_minimum_size = Vector2(100, 40)
		b.add_theme_font_size_override("font_size", 18)
		comandi_vista.add_child(b)
		if x[0] == "Pedine":
			bottone_modelli = b
	# pannello sinistro: azioni del turno
	sinistra = PanelContainer.new()
	sinistra.anchor_top = 0
	sinistra.anchor_bottom = 1
	sinistra.offset_top = 76
	sinistra.offset_bottom = -126
	sinistra.offset_left = 8
	sinistra.offset_right = 8 + 340
	radice.add_child(sinistra)
	cont_sx = VBoxContainer.new()
	cont_sx.add_theme_constant_override("separation", 8)
	sinistra.add_child(_scroll(cont_sx))
	# pannello destro: area e armate selezionate, attacchi
	destra = PanelContainer.new()
	destra.anchor_left = 1
	destra.anchor_right = 1
	destra.anchor_top = 0
	destra.anchor_bottom = 1
	destra.offset_left = -398
	destra.offset_right = -8
	destra.offset_top = 76
	destra.offset_bottom = -126
	radice.add_child(destra)
	cont_dx = VBoxContainer.new()
	cont_dx.add_theme_constant_override("separation", 8)
	destra.add_child(_scroll(cont_dx))
	# diario in basso
	diario = PanelContainer.new()
	diario.anchor_top = 1
	diario.anchor_bottom = 1
	diario.anchor_left = 0
	diario.anchor_right = 1
	diario.offset_top = -118
	diario.offset_bottom = -8
	diario.offset_left = 8
	diario.offset_right = -8
	diario.add_theme_stylebox_override("panel", _stile(Color(C_CARTA, 0.94), C_BLU_SCURO, 2, 5, 10))
	radice.add_child(diario)
	var hd := HBoxContainer.new()
	diario.add_child(hd)
	lab_diario = RichTextLabel.new()
	lab_diario.bbcode_enabled = true
	lab_diario.scroll_following = true
	lab_diario.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lab_diario.custom_minimum_size = Vector2(300, 92)
	hd.add_child(lab_diario)
	var bd := _bottone("Diario completo", _mostra_diario)
	bd.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hd.add_child(bd)
	# pannello dei dadi
	dadi = PanelContainer.new()
	dadi.anchor_left = 0.5
	dadi.anchor_right = 0.5
	dadi.offset_left = -330
	dadi.offset_right = 330
	dadi.offset_top = 80
	dadi.add_theme_stylebox_override("panel", _stile(Color(C_CARTA, 0.97), C_ORO, 3, 6, 12))
	dadi.visible = false
	dadi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	radice.add_child(dadi)
	# avviso
	toast = PanelContainer.new()
	toast.anchor_left = 0.5
	toast.anchor_right = 0.5
	toast.anchor_top = 1
	toast.anchor_bottom = 1
	toast.offset_left = -380
	toast.offset_right = 380
	toast.offset_top = -240
	toast.offset_bottom = -180
	toast.add_theme_stylebox_override("panel", _stile(C_BLU_SCURO, C_ORO, 2, 5, 10))
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lab_toast = _etichetta("", 21, F_SEMI, Color(1, 0.97, 0.9))
	lab_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_child(lab_toast)
	toast.visible = false
	radice.add_child(toast)
	# finestre
	popup = Control.new()
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.visible = false
	radice.add_child(popup)
	menu = Control.new()
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.visible = false
	radice.add_child(menu)
	_mostra_ui_partita(false)

func _mostra_ui_partita(v: bool) -> void:
	barra.visible = v
	sinistra.visible = v and pannelli_visibili
	destra.visible = v and pannelli_visibili
	diario.visible = v and pannelli_visibili
	comandi_vista.visible = v
	comandi_vista.offset_left = (-400 if pannelli_visibili else 0) - 112
	comandi_vista.offset_right = (-400 if pannelli_visibili else 0) - 12
	if not v:
		dadi.visible = false

# =====================================================================================
# Menu principale
# =====================================================================================

func _mostra_menu() -> void:
	in_partita = false
	online = false
	_mostra_ui_partita(false)
	vista.evidenzia([])
	vista.pulisci_frecce()
	for c in menu.get_children():
		c.queue_free()
	menu.visible = true
	var fondo := ColorRect.new()
	fondo.color = Color(0.03, 0.06, 0.09, 0.55)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.add_child(fondo)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.add_child(cc)
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(980, 0)
	p.add_theme_stylebox_override("panel", _stile(Color(C_CARTA, 0.97), C_BLU_SCURO, 4, 6, 26))
	cc.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	var testa := PanelContainer.new()
	testa.add_theme_stylebox_override("panel", _stile(C_BLU, C_BLU_SCURO, 0, 4, 16))
	v.add_child(testa)
	var vt := VBoxContainer.new()
	testa.add_child(vt)
	var t1 := _etichetta("DOWNFALL", 76, F_TITOLO, Color(0.98, 0.97, 0.94))
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vt.add_child(t1)
	var t2 := _etichetta("OF THE THIRD REICH", 44, F_TITOLO, Color(0.98, 0.97, 0.94))
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vt.add_child(t2)
	var t3 := _etichetta("La grande strategia della seconda guerra mondiale in Europa, 1940-1945", 22, F_SEMI, C_ORO)
	t3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vt.add_child(t3)
	# scelta dello schieramento con le carte delle fazioni
	v.add_child(titolo("NUOVA PARTITA: SCEGLI CHI GIOCARE", 30))
	var carte := HBoxContainer.new()
	carte.add_theme_constant_override("separation", 16)
	carte.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(carte)
	for x in [["asse", "carta_asse", "Asse"], ["alleati", "carta_alleati", "Alleati"], ["urss", "carta_urss", "Unione Sovietica"]]:
		var vb := VBoxContainer.new()
		vb.custom_minimum_size = Vector2(290, 0)
		carte.add_child(vb)
		var tr := TextureButton.new()
		tr.texture_normal = load("res://assets/pedine/%s.webp" % x[1])
		tr.ignore_texture_size = true
		tr.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(290, 194)
		var lato: String = x[0]
		tr.pressed.connect(func(): _nuova_partita({"asse": lato == "asse", "alleati": lato == "alleati", "urss": lato == "urss"}))
		vb.add_child(tr)
		var b := _bottone("Gioco: " + str(x[2]), func(): _nuova_partita({"asse": lato == "asse", "alleati": lato == "alleati", "urss": lato == "urss"}))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vb.add_child(b)
	var h2 := HBoxContainer.new()
	h2.add_theme_constant_override("separation", 10)
	h2.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(h2)
	h2.add_child(_bottone("In due: Alleati e URSS insieme", func(): _nuova_partita({"asse": false, "alleati": true, "urss": true})))
	h2.add_child(_bottone("Tre giocatori sullo stesso schermo", func(): _nuova_partita({"asse": true, "alleati": true, "urss": true})))
	h2.add_child(_bottone("Guarda l'IA giocare", func(): _nuova_partita({"asse": false, "alleati": false, "urss": false})))
	var h3 := HBoxContainer.new()
	h3.add_theme_constant_override("separation", 10)
	h3.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(h3)
	h3.add_child(_bottone("Continua la partita salvata", _continua))
	h3.add_child(_bottone("Gioco online", _menu_online))
	h3.add_child(_bottone("Regole", _mostra_regole))
	var bl := _bottone("IA: " + livello, func(): pass)
	bl.pressed.connect(func():
		livello = "esperto" if livello == "normale" else "normale"
		bl.text = "IA: " + livello)
	h3.add_child(bl)
	var nota := _etichetta("Versione digitale per uso personale. Gioco di Víctor Catalá, grafica di Jesús Peralta, edito da DoItGames (2022). Versione %s." % VERSIONE, 17, F_CORSIVO, Color(0.3, 0.3, 0.3))
	nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nota)

func _nuova_partita(u: Dictionary) -> void:
	umani = u
	m = Motore.new(D)
	m.nuova(int(Time.get_unix_time_from_system()) % 1000000 + randi() % 1000)
	online = false
	_avvia()

func _avvia() -> void:
	menu.visible = false
	_chiudi_popup()
	ia = IA.new(D, m)
	ia.livello = livello
	m.evento.connect(_al_evento)
	in_partita = true
	sel_area = ""
	sel_unita = ""
	_ultimo_tiro_visto = int(m.s.get("tiri", 0))
	_mostra_ui_partita(true)
	bottone_modelli.text = "Pedine" if vista.modelli else "Modelli 3D"
	vista.ricrea_tutte(m)
	vista.centra_su("berlino")
	lab_diario.text = ""
	for t in m.s["log"].slice(maxi(0, m.s["log"].size() - 40)):
		lab_diario.append_text(t + "\n")
	_aggiorna()

func _al_evento(t: String) -> void:
	lab_diario.append_text(t + "\n")

# =====================================================================================
# Regole e diario
# =====================================================================================

const REGOLE := """[b]Scopo.[/b] Ventidue turni di tre mesi, dall'inverno 1940 alla primavera 1945. Se la Germania si arrende prima dell'ultimo turno vincono gli Alleati e l'URSS; se si arrende nell'ultimo è pari; se non si arrende vince l'Asse. La Germania si arrende quando perde tutte le sue aree di rifornimento (Ruhr, Berlino, Breslavia, Monaco).

[b]Il turno.[/b] Gioca prima l'Asse, poi gli Alleati, poi l'URSS. Ognuno fa le sue [b]azioni[/b] e spende le sue scorte nell'ordine che preferisce: Asse 3 azioni (4 in guerra totale), Alleati 2 (5), URSS 2 (3). Dal 1942 tutti sono in guerra totale; Asse e URSS lo diventano prima, il turno dopo Barbarossa.

[b]Azioni.[/b] Rifornimento: +5 unità (massimo 12). Rinforzi: punti per costruire armate nelle aree di rifornimento (2 una piena, 1 una ridotta o riportare al completo una ridotta). Produzione corazzati: +3 passi (servono 2 passi per una corazzata piena). Missioni aeree: +2 (serve Aviazione). Missioni sottomarine (solo Asse): +3. Sviluppo: avvia una tessera, la seconda volta la completa (dal 1944 basta una volta). Affitti e prestiti (Alleati): un'azione in più all'URSS. Ogni azione una sola volta per turno (gli Alleati in guerra totale due).

[b]Operazioni.[/b] Ogni armata con linea di rifornimento a inizio turno fa una sola operazione, che costa 1 unità di rifornimento (2 per uno sbarco o per attraversare più di un mare): movimento tattico (fanteria 3 aree, corazzati 4), attacco o sostegno nella propria area, movimento tattico e attacco (un'area in meno), movimento strategico (illimitato fra aree controllate), movimento navale fra aree costiere controllate, sbarco anfibio. Da un'area con armate nemiche non si va tatticamente in aree non controllate o con nemici. Al massimo 3 armate per lato in un'area.

[b]Combattimento.[/b] Armata contro armata, risolto dopo tutti i movimenti. Attaccante: fattore + sostegni (+2 piena, +1 ridotta; solo con le armate in più rispetto ai difensori) + 2 per una missione aerea. Difensore: fattore + 1 per ogni terreno non di pianura (foresta, palude, montagna, passo) + 1 fortezza + 1 se l'attaccante attraversa fiume, stretto o costa (sbarco) + 2 linea fortificata. Si aggiunge un dado: chi fa di più vince e subisce 1 perdita, il perdente 2. Il vincitore non ha perdite se fa almeno il doppio o se il perdente era ridotto. Pari: una perdita ciascuno. I corazzati tedeschi in URSS (fuori da foreste, paludi e montagne), l'Afrika Korps e i corazzati britannici in Africa trasformano 1 e 2 in 3.

[b]Blitzkrieg.[/b] Se un attacco ha almeno +4 in pianura senza fortezza (in Africa ovunque), i corazzati che non vi partecipano attraversano l'area e possono entrare in un'area vicina non controllata. Le linee di rifornimento passano anche per le aree con armate proprie.

[b]Rifornimento.[/b] Un'armata è rifornita se raggiunge un'area di rifornimento del suo lato, o la capitale del suo paese, attraverso aree controllate (senza Blitzkrieg non attraverso aree con armate nemiche), anche via mare fra coste controllate. Le armate senza rifornimento a fine turno sono eliminate.

[b]Missioni.[/b] Una missione aerea dà +2 a un attacco; il difensore può contrastarla con una sua (si eliminano a vicenda). D'inverno solo in Africa. Due missioni sottomarine nella Battaglia dell'Atlantico tolgono un'azione agli Alleati. Con l'Aviazione avanzata gli Alleati bombardano la Germania: se restano 2 missioni l'Asse perde un'azione.

[b]Rese.[/b] La Francia si arrende a fine turno se il Belgio si è arreso e ci sono armate tedesche in 3 aree francesi; l'Africa del Nord francese diventa neutrale e l'Italia entra in guerra. Italia e Belgio si arrendono con 2 armate nemiche nel paese; le nazioni minori perdendo la capitale; URSS e Germania perdendo tutte le aree di rifornimento.

[b]Entrate in guerra.[/b] Belgio nel turno 2, Italia dopo la resa della Francia, Romania, Ungheria e Bulgaria nel 1941, Grecia nel 1941, Jugoslavia e Stati Uniti nel 1942, oppure prima se invase.

[b]Comandi.[/b] Tocca o fai clic su un'area per vederla; scegli un'armata dal pannello a destra: le aree verdi sono i movimenti tattici, le azzurre i movimenti strategici o navali, le viola gli sbarchi, le rosse gli attacchi. Mouse: trascina per spostare, tasto destro per ruotare e inclinare, rotella per lo zoom. iPad: un dito sposta, due dita pizzicano e ruotano, due dita in verticale inclinano."""

func _mostra_regole() -> void:
	_apri_popup("Regole in breve", REGOLE, [["Chiudi", _chiudi_popup]], 1100)

func _mostra_diario() -> void:
	var testo := "\n".join(m.s["log"].slice(maxi(0, m.s["log"].size() - 200)))
	_apri_popup("Diario di guerra", testo, [["Chiudi", _chiudi_popup]], 1100)

# =====================================================================================
# Salvataggi
# =====================================================================================

const FILE_LOCALE := "user://partita_downfall.json"
const FILE_PREF := "user://preferenze_downfall.cfg"

func _carica_preferenze() -> void:
	var c := ConfigFile.new()
	if c.load(FILE_PREF) == OK:
		vista.modelli = bool(c.get_value("p", "modelli", true))
		livello = str(c.get_value("p", "livello", "normale"))

func _salva_preferenze() -> void:
	var c := ConfigFile.new()
	c.set_value("p", "modelli", vista.modelli)
	c.set_value("p", "livello", livello)
	c.save(FILE_PREF)

func _cambia_pannelli() -> void:
	pannelli_visibili = not pannelli_visibili
	_mostra_ui_partita(true)

func _cambia_modelli() -> void:
	vista.modelli = not vista.modelli
	bottone_modelli.text = "Pedine" if vista.modelli else "Modelli 3D"
	_salva_preferenze()
	vista.ricrea_tutte(m)
	_mostra_toast("Armate come %s." % ("modellini 3D" if vista.modelli else "pedine originali"))

func _salva() -> void:
	if online or m == null:
		return
	var st := m.esporta()
	st["umani"] = umani
	var f := FileAccess.open(FILE_LOCALE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(st))
		f.close()
	rete.salva_partita(st)

func _continua() -> void:
	_messaggio("Caricamento della partita salvata...")
	var st := await rete.carica_partita()
	if st.is_empty():
		var f := FileAccess.open(FILE_LOCALE, FileAccess.READ)
		if f:
			var x = JSON.parse_string(f.get_as_text())
			if x is Dictionary:
				st = x
	_chiudi_popup()
	if st.is_empty() or not st.has("ctrl"):
		_apri_popup("Nessuna partita salvata", "Non ho trovato partite salvate né online né su questo dispositivo.", [["Chiudi", _chiudi_popup]])
		return
	m = Motore.new(D)
	m.importa(st)
	umani = st.get("umani", {"asse": true, "alleati": false, "urss": false})
	online = false
	_avvia()

func _apri_menu_partita() -> void:
	var bott := [["Riprendi", _chiudi_popup]]
	if not online:
		bott.append(["Salva ora", func(): _salva(); _chiudi_popup(); _mostra_toast("Partita salvata.")])
	bott.append(["Regole", func(): _chiudi_popup(); _mostra_regole()])
	bott.append(["Velocità IA: " + ("rapida" if velocita < 1.0 else "normale"), func(): velocita = 0.3 if velocita >= 1.0 else 1.0; _chiudi_popup()])
	bott.append(["Torna al menu", func(): _salva(); _chiudi_popup(); _mostra_menu()])
	_apri_popup("Menu", "%s, turno %d di %d." % [m.data_testo(), int(m.s["turno"]), Dati.ULTIMO_TURNO], bott)

# =====================================================================================
# Finestre e avvisi
# =====================================================================================

func _apri_popup(t: String, testo: String, bottoni: Array, larghezza := 760) -> VBoxContainer:
	for c in popup.get_children():
		c.queue_free()
	popup.visible = true
	var f := ColorRect.new()
	f.color = Color(0, 0, 0, 0.45)
	f.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.add_child(f)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.add_child(cc)
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(larghezza, 0)
	cc.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	v.add_child(titolo(t.to_upper(), 32))
	if testo != "":
		var r := RichTextLabel.new()
		r.bbcode_enabled = true
		r.fit_content = true
		r.custom_minimum_size = Vector2(larghezza - 40, 0)
		r.text = testo
		if testo.length() > 900:
			r.fit_content = false
			r.custom_minimum_size = Vector2(larghezza - 40, 640)
		v.add_child(r)
	if bottoni.size() > 3:
		var g := GridContainer.new()
		g.columns = 2
		g.add_theme_constant_override("h_separation", 10)
		g.add_theme_constant_override("v_separation", 10)
		v.add_child(g)
		for b in bottoni:
			var bt := _bottone(b[0], b[1])
			bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			g.add_child(bt)
		return v
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(h)
	for b in bottoni:
		h.add_child(_bottone(b[0], b[1]))
	return v

func _messaggio(t: String) -> void:
	_apri_popup("Attendere", t, [])

func _chiudi_popup() -> void:
	popup.visible = false
	for c in popup.get_children():
		c.queue_free()

func _mostra_toast(t: String, durata := 3.5) -> void:
	lab_toast.text = t
	toast.visible = true
	_toast_tempo = durata

# =====================================================================================
# Ciclo: IA, rete, salvataggi
# =====================================================================================

func _process(delta: float) -> void:
	if _toast_tempo > 0:
		_toast_tempo -= delta
		if _toast_tempo <= 0:
			toast.visible = false
	if _dadi_tempo > 0:
		_dadi_tempo -= delta
		if _dadi_tempo <= 0:
			dadi.visible = false
	if not in_partita or m == null:
		return
	if online:
		_ciclo_online(delta)
		return
	if _salva_timer > 0:
		_salva_timer -= delta
		if _salva_timer <= 0:
			_salva()
	if popup.visible or m.finita():
		return
	if _pausa > 0:
		_pausa -= delta
		return
	var r := m.richiesta()
	if r["k"] == "fine":
		return
	if umani.get(r["g"], false):
		if r["k"] == "contrasto" and not _contrasto_aperto:
			_apri_contrasto(r["g"])
		return
	_passo_ia(r)

func _passo_ia(r: Dictionary) -> void:
	var d := ia.decidi(r)
	var prima := _prima(d)
	var res := m.applica(d)
	if not res["ok"]:
		ia.rifiutata(d)
		_rifiuti_ia += 1
		if _rifiuti_ia > 25:
			_rifiuti_ia = 0
			m.applica({"t": "combatti"})
			m.applica({"t": "fine"})
			_dopo_decisione({"t": "fine"}, {"ok": true}, {})
		return
	_rifiuti_ia = 0
	_dopo_decisione(d, res, prima)
	var t: String = d.get("t", "")
	match t:
		"muovi", "attacca", "sostieni":
			_pausa = 0.25 * velocita
		"combatti":
			_pausa = 0.6 * velocita
		"fine":
			_pausa = 0.5 * velocita
		_:
			_pausa = 0.3 * velocita
	if _dadi_tempo > 0:
		_pausa = maxf(_pausa, 1.4 * velocita)

func _prima(d: Dictionary) -> Dictionary:
	var out := {}
	if m == null:
		return out
	var uid: String = str(d.get("u", ""))
	if m.s["u"].has(uid):
		out["da"] = m.s["u"][uid]["h"]
		out["lato"] = m.lato_di(uid)
	out["lato_turno"] = m.s["lato"]
	out["turno"] = int(m.s["turno"])
	return out

func _dopo_decisione(d: Dictionary, res: Dictionary, prima: Dictionary) -> void:
	var t: String = d.get("t", "")
	# frecce: movimenti e attacchi del turno in corso
	if prima.get("lato_turno", "") != m.s["lato"] or prima.get("turno", 0) != int(m.s["turno"]):
		vista.pulisci_frecce()
	if t == "muovi" and prima.has("da"):
		var col: Color = COL_FRECCIA[prima["lato"]]
		var modo: String = d.get("m", "tattico")
		vista.freccia(prima["da"], d["h"], col, 0.8 if modo == "tattico" else 0.6, 0.0 if modo == "tattico" else 0.6)
	if t == "aereo" and m.s["attacchi"].size() > int(d.get("i", 0)):
		var h: String = m.s["attacchi"][int(d["i"])]["h"]
		vista.lampo(h, Color(1, 0.9, 0.5))
	vista.aggiorna(m)
	# combattimenti risolti: dadi
	if int(m.s.get("tiri", 0)) != _ultimo_tiro_visto:
		_ultimo_tiro_visto = int(m.s["tiri"])
		_mostra_dadi()
	if res.get("attesa", false) and umani.get(m.richiesta()["g"], false) and not online:
		pass
	_salva_timer = 1.0 if t == "fine" else _salva_timer
	if t == "fine" and not online:
		sel_unita = ""
		sel_area = ""
		var r := m.richiesta()
		if umani.get(r["g"], false) and not umani.get(prima.get("lato_turno", ""), false):
			_mostra_toast("Tocca a te: %s, %s." % [Dati.NOME_LATO[r["g"]], m.data_testo()])
		elif umani.get(r["g"], false) and umani.values().count(true) > 1:
			_mostra_toast("Turno di: %s." % Dati.NOME_LATO[r["g"]])
	if m.finita():
		_fine_partita()
	_aggiorna()

func _mostra_dadi() -> void:
	var t: Dictionary = m.s.get("ultimo_tiro", {})
	if t.is_empty():
		return
	for c in dadi.get_children():
		c.queue_free()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	dadi.add_child(v)
	v.add_child(titolo("COMBATTIMENTO A %s" % D.nome(t["h"]).to_upper(), 28))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	v.add_child(h)
	for k in 2:
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(vb)
		var nome: String = t["na"] if k == 0 else t["nd"]
		vb.add_child(_etichetta(("Attacca: " if k == 0 else "Difende: ") + nome, 19, F_SEMI))
		var hh := HBoxContainer.new()
		hh.add_theme_constant_override("separation", 10)
		vb.add_child(hh)
		var base := int(t["att"]) if k == 0 else int(t["dif"])
		var dado := int(t["da"]) if k == 0 else int(t["dd"])
		hh.add_child(_etichetta("%d +" % base, 30, F_NUMERI))
		hh.add_child(_dado_ui(dado))
		hh.add_child(_etichetta("= %d" % (int(t["pa"]) if k == 0 else int(t["pd"])), 30, F_NUMERI))
	var esito := "%s." % str(t["esito"]).capitalize()
	if str(t["ra"]) != "":
		esito += " Attaccante %s." % t["ra"]
	if str(t["rd"]) != "":
		esito += " Difensore %s." % t["rd"]
	v.add_child(_etichetta(esito, 21, F_GRASSETTO, C_BLU_SCURO))
	dadi.visible = true
	_dadi_tempo = 2.6 * velocita + 0.6
	vista.lampo(t["h"], Color(1.0, 0.55, 0.2))

## un dado disegnato (quadrato con i puntini), senza simboli di caratteri speciali
func _dado_ui(n: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(48, 48)
	c.draw.connect(func():
		c.draw_rect(Rect2(2, 2, 44, 44), Color(0.98, 0.97, 0.93))
		c.draw_rect(Rect2(2, 2, 44, 44), C_INCHIOSTRO, false, 2.0)
		var pos := {1: [[24, 24]], 2: [[14, 14], [34, 34]], 3: [[13, 13], [24, 24], [35, 35]], 4: [[14, 14], [34, 14], [14, 34], [34, 34]],
			5: [[13, 13], [35, 13], [24, 24], [13, 35], [35, 35]], 6: [[14, 12], [34, 12], [14, 24], [34, 24], [14, 36], [34, 36]]}
		for p in pos.get(n, []):
			c.draw_circle(Vector2(p[0], p[1]), 4.2, C_INCHIOSTRO))
	return c

func _fine_partita() -> void:
	if popup.visible:
		return
	var t: String = m.s.get("esito_testo", "Partita finita.")
	_apri_popup("Fine della guerra", t, [["Nuova partita", func(): _chiudi_popup(); _mostra_menu()], ["Guarda la mappa", _chiudi_popup]])
	rete.cancella_partita()

func _mio_turno() -> bool:
	if m == null or m.finita():
		return false
	var r := m.richiesta()
	if online:
		return r["g"] in miei_lati and r["k"] != "contrasto"
	return umani.get(r["g"], false) and r["k"] != "contrasto"

func _decidi(d: Dictionary) -> Dictionary:
	if online:
		return await _decidi_online(d)
	var prima := _prima(d)
	var res := m.applica(d)
	if not res["ok"]:
		_mostra_toast(str(res.get("msg", "non valido")).capitalize(), 3.0)
		return res
	_dopo_decisione(d, res, prima)
	return res

# =====================================================================================
# Clic sulla mappa
# =====================================================================================

func _sopra_area(_id: String) -> void:
	pass

func _clic_area(id: String) -> void:
	if not in_partita or popup.visible:
		return
	if sel_unita != "" and m.s["u"].has(sel_unita) and _mio_turno():
		var dest := _destinazioni_sel()
		if dest.has(id):
			_esegui_su(id, dest[id])
			return
	sel_area = id
	sel_unita = ""
	_aggiorna()

## destinazioni dell'armata scelta: area -> {"modi": [...], "att": bool}
func _destinazioni_sel() -> Dictionary:
	var out := {}
	if sel_unita == "" or not m.s["u"].has(sel_unita) or m.perche_ferma(sel_unita) != "":
		return out
	var lato := m.lato_di(sel_unita)
	var d := m.destinazioni(sel_unita, false)
	for h in d:
		out[h] = {"modo": d[h][0], "costo": d[h][1], "att": false}
	for h in m.mosse_tattiche(sel_unita, true):
		if not m.nemici_in(h, lato).is_empty():
			if not out.has(h):
				out[h] = {"modo": "tattico", "costo": m.costo_operazione(sel_unita, "tattico", h), "att": true}
			else:
				out[h]["att"] = true
	for h in m.mosse_anfibie(sel_unita):
		if not m.nemici_in(h, lato).is_empty():
			out[h] = {"modo": "anfibio", "costo": 2, "att": true}
	return out

func _esegui_su(id: String, info: Dictionary) -> void:
	var lato := m.lato_di(sel_unita)
	var nem := m.nemici_in(id, lato)
	var modo: String = info["modo"]
	if nem.is_empty():
		var res = await _decidi({"t": "muovi", "u": sel_unita, "h": id, "m": modo})
		if res.get("ok", false):
			sel_area = id
			sel_unita = ""
			_aggiorna()
		return
	# area con nemici: scelta del bersaglio o del sostegno
	var bott := []
	var uid := sel_unita
	for d in nem:
		var p := _prob_previsto(uid, d, id, modo)
		bott.append(["Attacca %s (%s) - vittoria %d%%" % [m.nome_unita(d), m.sigla_unita(d), int(round(p * 100))],
			func(): _chiudi_popup(); _attacco_scelto(uid, id, modo, d, -1)])
	for i in m.s["attacchi"].size():
		var at: Dictionary = m.s["attacchi"][i]
		if at["h"] == id and modo == "tattico" and m._perche_no_sostegno(uid, i, id, true) == "":
			bott.append(["Sostieni l'attacco di %s" % m.nome_unita(at["a"]), func(): _chiudi_popup(); _attacco_scelto(uid, id, modo, "", i)])
	if not m.unita_in(id, lato).is_empty() and not info.get("solo_att", false):
		bott.append(["Entra senza attaccare", func(): _chiudi_popup(); _attacco_scelto(uid, id, modo, "", -1)])
	bott.append(["Annulla", _chiudi_popup])
	var v := _apri_popup("Operazione a %s" % D.nome(id), "Costo: %d unità di rifornimento. Il movimento con attacco ha un'area in meno di portata." % int(info["costo"]), [], 820)
	for b in bott:
		var bt := _bottone(b[0], b[1])
		bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(bt)

func _attacco_scelto(uid: String, id: String, modo: String, d: String, sup: int) -> void:
	var dec := {"t": "muovi", "u": uid, "h": id, "m": modo}
	if d != "":
		dec["att"] = d
	if sup >= 0:
		dec["sup"] = sup
	var res = await _decidi(dec)
	if res.get("ok", false):
		sel_area = id
		sel_unita = ""
		_aggiorna()

func _prob_previsto(att: String, dif: String, area: String, modo: String) -> float:
	var da := ""
	if modo == "tattico":
		var mt := m.mosse_tattiche(att, true)
		if mt.has(area):
			da = mt[area]["da"]
	var anf := modo == "anfibio"
	var lato := m.lato_di(att)
	var aereo := int(m.s["aerei"][lato]) > 0 and ia._aereo_lecito(area, lato)
	return ia._stima(att, dif, area, da, anf, 0, false) if not aereo else ia._stima(att, dif, area, da, anf, 0, false)

# =====================================================================================
# Aggiornamento dei pannelli
# =====================================================================================

func _aggiorna() -> void:
	if m == null or not in_partita:
		return
	var r := m.richiesta()
	var lato: String = m.s["lato"]
	lab_data.text = "%s  -  turno %d di %d" % [m.data_testo().to_upper(), int(m.s["turno"]), Dati.ULTIMO_TURNO]
	lab_lato.text = "TURNO: %s" % Dati.NOME_LATO[lato].to_upper()
	lab_lato.add_theme_color_override("font_color", COL_LATO[lato].lightened(0.45))
	lab_azioni.text = "Azioni %d / %d" % [int(m.s["az"]["usate"]), int(m.s["az"]["max"])]
	for c in box_scorte.get_children():
		c.queue_free()
	for x in [["Rifornimenti", int(m.s["rif"][lato])], ["Corazzati", int(m.s["cor"][lato])], ["Aerei", int(m.s["aerei"][lato])]]:
		box_scorte.add_child(_chip(x[0], str(x[1])))
	if lato == "asse":
		box_scorte.add_child(_chip("Sottomarini", str(int(m.s["sub"]))))
	if int(m.s["punti"]) > 0:
		box_scorte.add_child(_chip("Punti rinforzo", str(int(m.s["punti"]))))
	_aggiorna_sinistra(r)
	_aggiorna_destra(r)
	_aggiorna_evidenze()

func _chip(nome: String, val: String) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	var l := _etichetta(nome, 18, F_TESTO, Color(0.8, 0.85, 0.9))
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	h.add_child(l)
	var n := _etichetta(val, 24, F_NUMERI, C_ORO)
	n.autowrap_mode = TextServer.AUTOWRAP_OFF
	n.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	h.add_child(n)
	return h

func _aggiorna_sinistra(r: Dictionary) -> void:
	for c in cont_sx.get_children():
		c.queue_free()
	var lato: String = m.s["lato"]
	var mio := _mio_turno()
	if r["k"] == "fine":
		cont_sx.add_child(titolo("PARTITA FINITA", 30))
		cont_sx.add_child(_etichetta(str(m.s.get("esito_testo", "")), 20))
		cont_sx.add_child(_bottone("Torna al menu", _mostra_menu))
		return
	if not mio:
		cont_sx.add_child(titolo("TURNO DI %s" % Dati.NOME_LATO[r["g"]].to_upper(), 30, COL_LATO[r["g"]]))
		var chi := "L'intelligenza artificiale sta giocando." if not online or not (r["g"] in miei_lati) else ""
		if online and not (r["g"] in miei_lati):
			chi = "In attesa delle mosse dell'altro giocatore."
		if r["k"] == "contrasto":
			chi = "Contrasto aereo: decide %s." % Dati.NOME_LATO[r["g"]]
		cont_sx.add_child(_etichetta(chi, 20, F_CORSIVO))
		_riquadro_stato(cont_sx)
		return
	var fase: String = m.s["fase"]
	cont_sx.add_child(titolo("AZIONI  %d / %d" % [int(m.s["az"]["usate"]), int(m.s["az"]["max"])], 30, COL_LATO[lato].darkened(0.2)))
	if fase == "operazioni":
		cont_sx.add_child(_etichetta("Fai le azioni e muovi le armate; gli attacchi si risolvono tutti insieme alla fine.", 18, F_CORSIVO))
	else:
		cont_sx.add_child(_etichetta("Combattimenti risolti: puoi ancora fare azioni e costruire, poi chiudi il turno.", 18, F_CORSIVO))
	for a in ["rifornimento", "rinforzi", "corazzati", "aerei", "sottomarini", "prestito"]:
		if a == "sottomarini" and lato != "asse":
			continue
		if a == "prestito" and lato != "alleati":
			continue
		var perche := m.perche_no_azione(a)
		var testo: String = Dati.NOME_AZIONE[a]
		var fatte := int(m.s["az"]["tipi"].get(a, 0))
		if fatte > 0:
			testo += " (fatta)" if m.limite_tipo(a) == 1 else " (%d/%d)" % [fatte, m.limite_tipo(a)]
		var az: String = a
		var b := _bottone(testo, func(): _decidi({"t": "azione", "a": az}), perche == "", perche.capitalize() if perche != "" else _spiega_azione(a, lato))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cont_sx.add_child(b)
	var bs := _bottone("Sviluppo...", _apri_sviluppi, m.azioni_rimaste() > 0 and int(m.s["az"]["tipi"].get("sviluppo", 0)) < m.limite_tipo("sviluppo"))
	bs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cont_sx.add_child(bs)
	# rinforzi da spendere
	if int(m.s["punti"]) > 0:
		cont_sx.add_child(_separatore())
		cont_sx.add_child(titolo("RINFORZI: %d PUNTI" % int(m.s["punti"]), 26))
		_pannello_costruzione(cont_sx)
	# missioni speciali
	if fase == "operazioni":
		if lato == "asse" and int(m.s["sub"]) > 0 and int(m.s["atlantico"]) == 0:
			var n := 1 if m.ha("asse", "navi_av") and not m.ha("alleati", "navi_av") else 2
			n = mini(n, int(m.s["sub"]))
			var b2 := _bottone("Sottomarini in Atlantico (%d)" % n, func(): _decidi({"t": "sub", "n": n}), true,
				"Con 2 missioni (1 se avanzate) gli Alleati perdono un'azione nel loro turno.")
			b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cont_sx.add_child(b2)
		if lato == "alleati" and m.ha("alleati", "aviazione_av") and int(m.s["aerei"]["alleati"]) > 0:
			var n2 := int(m.s["aerei"]["alleati"])
			var b3 := _bottone("Bombardamento strategico (%d missioni)" % n2, func(): _decidi({"t": "bombarda", "n": n2}), int(m.s["bomb"]) == 0)
			b3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cont_sx.add_child(b3)
	cont_sx.add_child(_separatore())
	if fase == "operazioni":
		var bc := _bottone("Risolvi i combattimenti (%d)" % m.s["attacchi"].size(), func(): _decidi({"t": "combatti"}))
		bc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cont_sx.add_child(bc)
	var bf := _bottone("Fine turno", _conferma_fine)
	bf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cont_sx.add_child(bf)
	_riquadro_stato(cont_sx)

func _conferma_fine() -> void:
	var msg := ""
	if m.azioni_rimaste() > 0:
		msg = "Hai ancora %d azioni. " % m.azioni_rimaste()
	if int(m.s["punti"]) > 0:
		msg += "Hai ancora %d punti rinforzo. " % int(m.s["punti"])
	if msg != "":
		_apri_popup("Fine turno", msg + "Chiudere comunque il turno?", [["Chiudi il turno", func(): _chiudi_popup(); _decidi({"t": "fine"})], ["Annulla", _chiudi_popup]])
	else:
		_decidi({"t": "fine"})

func _spiega_azione(a: String, lato: String) -> String:
	match a:
		"rifornimento":
			return "+%d unità di rifornimento (massimo 12)." % (7 if m.ha(lato, "logistica") else 5)
		"rinforzi":
			return "%d punti per costruire o completare armate." % m.punti_rinforzo(lato)
		"corazzati":
			return "+%d passi corazzati." % (5 if m.ha(lato, "ind_carri") else 3)
		"aerei":
			return "+%d missioni aeree." % (4 if m.ha(lato, "ind_aerea") else 2)
		"sottomarini":
			return "+3 missioni sottomarine."
		"prestito":
			return "L'URSS avrà un'azione in più in questo turno."
	return ""

func _riquadro_stato(par: VBoxContainer) -> void:
	par.add_child(_separatore())
	par.add_child(titolo("SITUAZIONE", 24))
	var righe := []
	for l in Dati.LATI:
		var n := 0
		for uid in m.s["u"]:
			if m.lato_di(uid) == l:
				n += 1
		var aree := 0
		for id in m.s["ctrl"]:
			if m.s["ctrl"][id] == l:
				aree += 1
		var tot := " (guerra totale)" if m.s["tot"][l] else ""
		righe.append("[b]%s[/b]%s: %d armate, %d aree, rif. %d, aerei %d" % [Dati.NOME_LATO[l], tot, n, aree, int(m.s["rif"][l]), int(m.s["aerei"][l])])
	var sv := []
	for l in Dati.LATI:
		var x := []
		for k in m.s["svil"][l]:
			if str(k).ends_with("_t"):
				continue
			if int(m.s["svil"][l][k]) >= 2:
				x.append(Dati.SVILUPPI[k]["n"])
			elif int(m.s["svil"][l][k]) == 1:
				x.append(Dati.SVILUPPI[k]["n"] + " (in corso)")
		sv.append("[b]Sviluppi %s:[/b] %s" % [Dati.NOME_LATO_BREVE[l], ", ".join(x) if not x.is_empty() else "nessuno"])
	var arresi := []
	for k in m.s["arresi"]:
		arresi.append(Dati.NOME_NAZ.get(k, k))
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.custom_minimum_size = Vector2(320, 0)
	r.add_theme_font_size_override("normal_font_size", 17)
	r.add_theme_font_size_override("bold_font_size", 17)
	r.text = "\n".join(righe) + "\n" + "\n".join(sv) + ("\n[b]Arresi:[/b] " + ", ".join(arresi) if not arresi.is_empty() else "")
	par.add_child(r)

func _pannello_costruzione(par: VBoxContainer) -> void:
	var lato: String = m.s["lato"]
	var righe := 0
	for naz in Dati.MAGGIORI:
		if D.LATO_NAZ[naz] != lato:
			continue
		for tp in m.tipi_costruibili(naz):
			for rid in [false, true]:
				var siti := []
				for h in D.sedi_costruzione(naz):
					if m.perche_no_costruzione(naz, tp, h, rid) == "":
						siti.append(h)
				if siti.is_empty():
					continue
				var nome := "%s %s%s" % [Dati.NOME_TIPO[tp].capitalize(), Dati.AGG_NAZ[naz], " ridotta" if rid else ""]
				par.add_child(_etichetta("%s (%d pt%s)" % [nome, 1 if rid else 2, ", %d passi corazzati" % (1 if rid else 2) if Dati.corazzata(tp) else ""], 18, F_SEMI))
				var g := HFlowContainer.new()
				g.add_theme_constant_override("h_separation", 6)
				g.add_theme_constant_override("v_separation", 6)
				par.add_child(g)
				for h in siti:
					var nz: String = naz
					var t2: String = tp
					var r2: bool = rid
					var hh: String = h
					var b := _bottone(D.nome(h), func(): _decidi({"t": "costruisci", "naz": nz, "tipo": t2, "h": hh, "ridotta": r2}))
					g.add_child(b)
				righe += 1
	if righe == 0:
		par.add_child(_etichetta("Nessuna costruzione possibile ora (aree di rifornimento piene o pedine finite). Puoi riportare al completo le armate ridotte dal pannello dell'armata.", 18, F_CORSIVO))
	else:
		par.add_child(_etichetta("Le armate ridotte si riportano al completo dal loro pannello (1 punto).", 17, F_CORSIVO))

func _apri_sviluppi() -> void:
	var lato: String = m.s["lato"]
	var v := _apri_popup("Sviluppi: %s" % Dati.NOME_LATO[lato], "Un'azione avvia lo sviluppo, una seconda azione in un turno successivo lo completa (dal 1944 basta una).", [], 1180)
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 12)
	v.add_child(g)
	for k in Dati.SVILUPPI:
		if not (lato in Dati.SVILUPPI[k]["lati"]):
			continue
		var vb := VBoxContainer.new()
		vb.custom_minimum_size = Vector2(262, 0)
		g.add_child(vb)
		var tr := TextureRect.new()
		var path := "res://assets/sviluppi/%s_%s.webp" % [lato, k]
		if ResourceLoader.exists(path):
			tr.texture = load(path)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(262, 175)
		vb.add_child(tr)
		var st := int(m.s["svil"][lato].get(k, 0))
		var perche := m.perche_no_sviluppo(k)
		var testo := "Completato" if st >= 2 else ("Completa" if st == 1 else "Avvia")
		var kk: String = k
		var ok := perche == "" and m.perche_no_azione("sviluppo", k) == ""
		var b := _bottone(testo, func(): _chiudi_popup(); _decidi({"t": "azione", "a": "sviluppo", "x": kk}), ok, perche.capitalize() if perche != "" else Dati.SPIEGA_SVILUPPO[k])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vb.add_child(b)
	v.add_child(_bottone("Chiudi", _chiudi_popup))

func _aggiorna_destra(r: Dictionary) -> void:
	for c in cont_dx.get_children():
		c.queue_free()
	var lato: String = m.s["lato"]
	var mio := _mio_turno()
	if sel_area == "":
		cont_dx.add_child(titolo("MAPPA", 30))
		cont_dx.add_child(_etichetta("Tocca un'area per vederne le armate. Nel tuo turno scegli un'armata per vedere dove può andare.", 19, F_CORSIVO))
	else:
		var t := RichTextLabel.new()
		t.bbcode_enabled = true
		t.fit_content = true
		t.custom_minimum_size = Vector2(380, 0)
		t.text = m.testo_area(sel_area)
		cont_dx.add_child(t)
		var lista := m.unita_in(sel_area)
		if lista.is_empty():
			cont_dx.add_child(_etichetta("Nessuna armata.", 19, F_CORSIVO))
		for uid in lista:
			cont_dx.add_child(_riga_unita(uid, mio and m.lato_di(uid) == lato))
	# attacchi dichiarati
	if not m.s["attacchi"].is_empty() and m.s["fase"] == "operazioni":
		cont_dx.add_child(_separatore())
		cont_dx.add_child(titolo("ATTACCHI DICHIARATI", 26))
		for i in m.s["attacchi"].size():
			var at: Dictionary = m.s["attacchi"][i]
			if not m.s["u"].has(at["a"]) or not m.s["u"].has(at["d"]):
				continue
			var v := m.valuta_attacco(i)
			var p := IA.probabilita(int(v["att"]), int(v["dif"]), ia._dado_minimo(at["a"], at["h"]), ia._dado_minimo(at["d"], at["h"]))
			var box := VBoxContainer.new()
			cont_dx.add_child(box)
			box.add_child(_etichetta("%s: %s contro %s" % [D.nome(at["h"]), m.nome_unita(at["a"]), m.nome_unita(at["d"])], 18, F_SEMI))
			box.add_child(_etichetta("%s. Vittoria %d%%%s." % [str(v["dett"]).capitalize(), int(round(p * 100)), ", con missione aerea" if int(at.get("aereo", 0)) > 0 else ""], 17))
			if mio and m.perche_no_aereo(i) == "":
				var ii: int = i
				box.add_child(_bottone("Aggiungi missione aerea (+2)", func(): _decidi({"t": "aereo", "i": ii})))

func _riga_unita(uid: String, mia: bool) -> Control:
	var u: Dictionary = m.s["u"][uid]
	var box := PanelContainer.new()
	var sel := uid == sel_unita
	box.add_theme_stylebox_override("panel", _stile(C_CARTA_SCURA if not sel else Color(0.98, 0.9, 0.62), COL_LATO[m.lato_di(uid)], 2, 4, 8))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	box.add_child(h)
	var tr := TextureRect.new()
	tr.texture = load("res://assets/pedine/%s.webp" % Vista3D.immagine_unita(u))
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.custom_minimum_size = Vector2(64, 64)
	tr.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(tr)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(_etichetta(Motore.maiuscola(m.nome_unita(uid)), 19, F_SEMI))
	var stato := "fattore %s" % m.sigla_unita(uid)
	if u["op"] != "" and m.lato_di(uid) == m.s["lato"]:
		stato += ", ha già operato"
	elif mia:
		var p := m.perche_ferma(uid)
		if p != "":
			stato += ", " + p
	v.add_child(_etichetta(stato, 17, F_TESTO, Color(0.25, 0.25, 0.25)))
	if not mia:
		return box
	var g := HFlowContainer.new()
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	v.add_child(g)
	if m.perche_ferma(uid) == "":
		g.add_child(_bottone("Muovi o attacca" if not sel else "Annulla scelta", func():
			sel_unita = "" if sel_unita == uid else uid
			_aggiorna()))
		for d in m.nemici_in(u["h"], m.lato_di(uid)):
			if m._perche_no_attacco(uid, d, u["h"]) == "":
				var dd: String = d
				var p := ia._stima(uid, d, u["h"], "", false, 0, false)
				g.add_child(_bottone("Attacca %s (%d%%)" % [m.sigla_unita(d), int(round(p * 100))], func(): _decidi({"t": "attacca", "u": uid, "d": dd})))
		for i in m.s["attacchi"].size():
			if m.s["attacchi"][i]["h"] == u["h"] and m._perche_no_sostegno(uid, i, u["h"], false) == "":
				var ii: int = i
				g.add_child(_bottone("Sostieni attacco", func(): _decidi({"t": "sostieni", "u": uid, "i": ii})))
		if Dati.corazzata(u["t"]) and m.pedine_libere(u["naz"], "f") > 0:
			g.add_child(_bottone("Diventa fanteria", func(): _decidi({"t": "smonta", "u": uid}), true, "Converte la corazzata in fanteria (gratis, prima di operare)."))
		g.add_child(_bottone("Sciogli", func(): _decidi({"t": "elimina", "u": uid}), true, "Elimina l'armata (torna disponibile per essere ricostruita)."))
	if u["r"] and m.perche_no_potenzia(uid) == "":
		g.add_child(_bottone("Al completo (1 pt)", func(): _decidi({"t": "potenzia", "u": uid})))
	for tp in ["a", "c", "k"]:
		if m.perche_no_converti(uid, tp) == "":
			var t2: String = tp
			g.add_child(_bottone("Converti in %s" % Dati.NOME_TIPO[tp], func(): _decidi({"t": "converti", "u": uid, "tipo": t2})))
	return box

func _aggiorna_evidenze() -> void:
	var gruppi := []
	if sel_unita != "" and m.s["u"].has(sel_unita):
		var dest := _destinazioni_sel()
		var verdi := []
		var blu := []
		var viola := []
		var rossi := []
		for h in dest:
			if dest[h]["att"]:
				rossi.append(h)
			elif dest[h]["modo"] == "tattico":
				verdi.append(h)
			elif dest[h]["modo"] == "anfibio":
				viola.append(h)
			else:
				blu.append(h)
		gruppi.append([verdi, Color(0.25, 0.85, 0.3, 0.9)])
		gruppi.append([blu, Color(0.25, 0.6, 1.0, 0.9)])
		gruppi.append([viola, Color(0.7, 0.35, 0.95, 0.9)])
		gruppi.append([rossi, Color(0.95, 0.15, 0.1, 0.95)])
	else:
		# aree con attacchi dichiarati
		var att := []
		for at in m.s["attacchi"]:
			att.append(at["h"])
		gruppi.append([att, Color(0.95, 0.35, 0.1, 0.8)])
	if sel_area != "":
		gruppi.append([[sel_area], Color(1.0, 0.85, 0.2, 0.55)])
	vista.evidenzia(gruppi)
	vista.imposta_bordo(sel_area)

# =====================================================================================
# Contrasto aereo (difensore umano)
# =====================================================================================

func _apri_contrasto(lato: String) -> void:
	_contrasto_aperto = true
	var poss: Array = m.missioni_da_contrastare(lato)
	var scelte := {}
	var v := _apri_popup("Contrasto aereo: %s" % Dati.NOME_LATO[lato],
		"Il nemico usa missioni aeree. Hai %d missioni: ognuna ne elimina una nemica (le avanzate si contrastano solo con avanzate)." % int(m.s["aerei"][lato]), [], 820)
	for i in poss:
		var testo := ""
		if int(i) == -1:
			testo = "Bombardamento strategico (%d missioni)" % int(m.s["bomb"])
		else:
			var at: Dictionary = m.s["attacchi"][int(i)]
			testo = "Attacco a %s contro %s" % [D.nome(at["h"]), m.nome_unita(at["d"])]
		var cb := CheckBox.new()
		cb.text = testo
		cb.add_theme_font_size_override("font_size", 20)
		var ii: int = int(i)
		cb.toggled.connect(func(on): scelte[ii] = on)
		v.add_child(cb)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_END
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	h.add_child(_bottone("Contrasta i selezionati", func():
		var lista := []
		for k in scelte:
			if scelte[k]:
				lista.append(k)
		_chiudi_popup()
		_contrasto_aperto = false
		_decidi({"t": "contrasta", "lista": lista, "sb": int(m.s["aerei"][lato])})))
	h.add_child(_bottone("Nessun contrasto", func():
		_chiudi_popup()
		_contrasto_aperto = false
		_decidi({"t": "contrasta", "lista": []})))

# =====================================================================================
# Gioco online (fino a tre giocatori; i lati liberi li gioca l'IA del dispositivo che ha creato la stanza)
# =====================================================================================

func _menu_online() -> void:
	var v := _apri_popup("Gioco online", "Fino a tre giocatori. Chi crea la stanza sceglie il suo schieramento; gli altri entrano con il codice di 4 lettere e ricevono, in ordine, gli schieramenti rimasti. Si può avviare senza aspettare tutti: i lati liberi li gioca l'IA.", [], 760)
	var nome := LineEdit.new()
	nome.placeholder_text = "Il tuo nome"
	nome.text = str(rete.load_session().get("nome", ""))
	v.add_child(nome)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	for l in Dati.LATI:
		var ll: String = l
		h.add_child(_bottone("Crea: %s" % Dati.NOME_LATO_BREVE[l], func(): _crea_stanza(nome.text, ll)))
	var h2 := HBoxContainer.new()
	h2.add_theme_constant_override("separation", 10)
	v.add_child(h2)
	var cod := LineEdit.new()
	cod.placeholder_text = "Codice"
	cod.custom_minimum_size = Vector2(170, 0)
	h2.add_child(cod)
	h2.add_child(_bottone("Entra nella stanza", func(): _entra_stanza(nome.text, cod.text.strip_edges().to_upper())))
	var sess := rete.load_session()
	if str(sess.get("room", "")) != "":
		v.add_child(_bottone("Rientra nella stanza %s" % sess["room"], func(): _entra_stanza(nome.text if nome.text != "" else "Giocatore", str(sess["room"]))))
	v.add_child(_bottone("Chiudi", _chiudi_popup))

func _crea_stanza(nome: String, lato: String) -> void:
	if nome.strip_edges() == "":
		nome = "Giocatore"
	rete._save({"nome": nome})
	_messaggio("Creo la stanza...")
	var seme := int(Time.get_unix_time_from_system()) % 1000000 + randi() % 1000
	var c := await rete.create_room(nome, {"lato_host": lato, "seme": seme})
	if c == "":
		_apri_popup("Errore", "Impossibile creare la stanza: %s" % rete.last_error, [["Chiudi", _chiudi_popup]])
		return
	codice = c
	posto = 0
	rete.remember_room(codice, 0)
	_attendi_ospiti(lato, seme)

func _assegna_lati(lato_host: String, n_posti: int) -> Dictionary:
	var out := {"0": lato_host}
	var liberi := []
	for l in Dati.LATI:
		if l != lato_host:
			liberi.append(l)
	for k in range(1, n_posti):
		if k - 1 < liberi.size():
			out[str(k)] = liberi[k - 1]
	return out

func _attendi_ospiti(lato: String, seme: int) -> void:
	var avvia := false
	var v := _apri_popup("Stanza %s" % codice, "Comunica il codice [b]%s[/b] agli altri giocatori. Avvia quando sono entrati: i lati liberi li gioca l'IA." % codice, [], 760)
	var stato := _etichetta("Giocatori nella stanza: 1", 20, F_SEMI)
	v.add_child(stato)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(h)
	h.add_child(_bottone("Avvia la partita", func(): avvia = true))
	h.add_child(_bottone("Annulla", func(): rete.close_room(codice); _chiudi_popup()))
	var n := 1
	while popup.visible:
		await get_tree().create_timer(2.0).timeout
		var st := await rete.room(codice)
		var seats: Dictionary = Rete._as_dict(st.get("seats", {}))
		n = seats.size()
		var nomi := []
		for k in seats:
			nomi.append(str(seats[k].get("name", "?")))
		if is_instance_valid(stato):
			stato.text = "Giocatori nella stanza: %d (%s)" % [n, ", ".join(nomi)]
		if avvia or n >= 3:
			var lati := _assegna_lati(lato, n)
			await rete.start_room(codice, {"seme": seme, "lati": lati})
			_chiudi_popup()
			_avvia_online(lati, seme, true)
			return

func _entra_stanza(nome: String, c: String) -> void:
	if c.length() != 4:
		_mostra_toast("Il codice ha 4 lettere.")
		return
	if nome.strip_edges() == "":
		nome = "Giocatore"
	rete._save({"nome": nome})
	_messaggio("Entro nella stanza %s..." % c)
	var p := await rete.join_room(c, nome, 3)
	if p < 0:
		_apri_popup("Errore", "Stanza non trovata o già piena. %s" % rete.last_error, [["Chiudi", _chiudi_popup]])
		return
	codice = c
	posto = p
	rete.remember_room(codice, posto)
	_apri_popup("Stanza %s" % c, "Sei nella stanza. Attendi che chi l'ha creata avvii la partita.", [])
	for i in 300:
		var st := await rete.room(codice)
		if st.get("status", "") == "playing" and st.has("game"):
			var g = JSON.parse_string(str(st["game"]))
			_chiudi_popup()
			_avvia_online(g["lati"], int(g["seme"]), posto == 0)
			return
		await get_tree().create_timer(2.0).timeout
	_chiudi_popup()

func _avvia_online(lati: Dictionary, seme: int, sono_host: bool) -> void:
	online = true
	host = sono_host
	miei_lati = []
	if lati.has(str(posto)):
		miei_lati.append(str(lati[str(posto)]))
	umani = {"asse": false, "alleati": false, "urss": false}
	for k in lati:
		umani[str(lati[k])] = true
	m = Motore.new(D)
	m.nuova(seme)
	n_applicate = 0
	_avvia()
	_mostra_toast("Partita online: giochi %s." % (Dati.NOME_LATO[miei_lati[0]] if not miei_lati.is_empty() else "come spettatore"))

func _decidi_online(d: Dictionary) -> Dictionary:
	var prova := Motore.new(D)
	prova.importa(m.esporta())
	var r := prova.applica(d)
	if not r["ok"]:
		_mostra_toast(str(r.get("msg", "non valido")).capitalize(), 2.5)
		return r
	_invio_in_corso = true
	var ok := await rete.post_decision(codice, n_applicate, d)
	_invio_in_corso = false
	if not ok:
		_mostra_toast("Invio non riuscito, riprova. %s" % rete.last_error, 3.0)
		return {"ok": false}
	var prima := _prima(d)
	var res := m.applica(d)
	n_applicate += 1
	_dopo_decisione(d, res, prima)
	return res

func _ciclo_online(delta: float) -> void:
	if _pausa > 0:
		_pausa -= delta
		return
	_attesa_rete -= delta
	if _attesa_rete > 0 or _invio_in_corso or _sincro_in_corso:
		return
	_attesa_rete = 1.2
	var r := m.richiesta()
	# il dispositivo che ha creato la stanza fa giocare l'IA per i lati liberi
	if host and r["k"] != "fine" and not umani.get(r["g"], false):
		var d := ia.decidi(r)
		var prova := Motore.new(D)
		prova.importa(m.esporta())
		if not prova.applica(d)["ok"]:
			ia.rifiutata(d)
			_attesa_rete = 0.0
			return
		await _decidi_online(d)
		_pausa = 0.3 * velocita
		return
	if r["k"] == "contrasto" and r["g"] in miei_lati and not _contrasto_aperto:
		_apri_contrasto(r["g"])
	_sincronizza()

func _sincronizza() -> void:
	if _sincro_in_corso:
		return
	_sincro_in_corso = true
	var nuove := await rete.get_decisions(codice, n_applicate)
	var chiavi := nuove.keys()
	chiavi.sort()
	for k in chiavi:
		if int(k) != n_applicate:
			break
		var d: Dictionary = nuove[k]
		var prima := _prima(d)
		var res := m.applica(d)
		n_applicate += 1
		_dopo_decisione(d, res, prima)
	_sincro_in_corso = false
