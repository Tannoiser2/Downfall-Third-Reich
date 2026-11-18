extends SceneTree
## Screenshot dell'interfaccia: xvfb-run godot --path . -s res://tests/foto.gd -- <modo> [passi]
var main
func _initialize():
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()
func shot(nome: String):
	for i in 25: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/shot_%s.png" % nome)
	print("shot ", nome)
func _run():
	var args := OS.get_cmdline_user_args()
	var modo: String = args[0] if args.size() > 0 else "menu"
	await shot("menu")
	if modo == "menu":
		quit(); return
	main._nuova_partita({"asse": true, "alleati": false, "urss": false})
	main.vista.distanza = 30
	await shot("inizio")
	if modo == "sel":
		main._clic_area("francoforte")
		await shot("area")
		for uid in main.m.unita_in("francoforte", "asse"):
			main.sel_unita = uid
			break
		main._aggiorna()
		main.vista.centra_su("francoforte")
		main.vista.distanza = 14
		await shot("unita")
		main._apri_sviluppi()
		await shot("sviluppi")
		main._chiudi_popup()
		main._mostra_regole()
		await shot("regole")
	if modo == "avanti":
		var passi := int(args[1]) if args.size() > 1 else 200
		main.umani = {"asse": false, "alleati": false, "urss": false}
		main.velocita = 0.0
		var k := 0
		while k < passi and not main.m.finita():
			main._passo_ia(main.m.richiesta())
			k += 1
		main.umani = {"asse": true, "alleati": false, "urss": false}
		main.vista.aggiorna(main.m, false)
		main._aggiorna()
		if args.size() > 2:
			main.vista.centra_su(args[2])
			main.vista.distanza = 9
			main.vista.beccheggio = 50
		await shot("avanti")
	quit()
