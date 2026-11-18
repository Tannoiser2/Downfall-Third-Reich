extends SceneTree
## Prova online automatica: due istanze (TR_ROLE=host|guest) giocano con l'IA scambiandosi le decisioni
## attraverso il finto Firebase (tests/firebase_mock.py). L'host gioca l'Asse e fa giocare l'IA per l'URSS
## (lato libero), l'ospite gioca gli Alleati. Alla fine confrontano lo stato.
var rete: Rete
func _initialize():
	rete = Rete.new()
	root.add_child(rete)
	_run.call_deferred()
func _run():
	var ruolo := OS.get_environment("TR_ROLE")
	var file := OS.get_environment("TR_CODEFILE")
	var codice := ""
	var miei := []
	var g := {}
	if ruolo == "host":
		codice = await rete.create_room("Host", {"lato_host": "asse", "seme": 4242})
		var f := FileAccess.open(file, FileAccess.WRITE); f.store_string(codice); f.close()
		while true:
			var st := await rete.room(codice)
			if Rete._as_dict(st.get("seats", {})).has("1"):
				break
			await create_timer(0.5).timeout
		g = {"seme": 4242, "lati": {"0": "asse", "1": "alleati"}}
		await rete.start_room(codice, g)
		miei = ["asse", "urss"]
	else:
		while not FileAccess.file_exists(file) or FileAccess.get_file_as_string(file).length() != 4:
			await create_timer(0.3).timeout
		codice = FileAccess.get_file_as_string(file)
		var p := await rete.join_room(codice, "Ospite", 3)
		print("TR ospite al posto ", p)
		while true:
			var st := await rete.room(codice)
			if st.get("status", "") == "playing":
				g = JSON.parse_string(str(st["game"]))
				break
			await create_timer(0.5).timeout
		miei = ["alleati"]
	var D := Dati.new()
	D.carica()
	var m := Motore.new(D)
	m.nuova(int(g["seme"]))
	var ia := IA.new(D, m)
	var n := 0
	var limite := int(OS.get_environment("TR_LIMITE")) if OS.get_environment("TR_LIMITE") != "" else 300
	while n < limite and not m.finita():
		var r := m.richiesta()
		if r["g"] in miei:
			var d := ia.decidi(r)
			var prova := Motore.new(D)
			prova.importa(m.esporta())
			if not prova.applica(d)["ok"]:
				ia.rifiutata(d)
				continue
			var ok := await rete.post_decision(codice, n, d)
			if not ok:
				print("TR invio fallito ", rete.last_error)
				break
			m.applica(d)
			n += 1
		else:
			var nuove := await rete.get_decisions(codice, n)
			var k := nuove.keys()
			k.sort()
			for x in k:
				if int(x) != n:
					break
				m.applica(nuove[x])
				n += 1
			if nuove.is_empty():
				await create_timer(0.05).timeout
	var h := JSON.stringify(m.s["u"]).hash() ^ JSON.stringify(m.s["ctrl"]).hash()
	print("TR %s fine: decisioni %d, %s, firma %d" % [ruolo, n, m.data_testo(), h])
	quit()
