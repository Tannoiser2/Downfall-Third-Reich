extends SceneTree
## Partita completa IA contro IA: godot --headless -s res://tests/sim.gd -- <seme> [verboso]
func _initialize():
	var args := OS.get_cmdline_user_args()
	var seme := int(args[0]) if args.size() > 0 else 1
	var verboso := args.size() > 1
	var D := Dati.new()
	D.carica()
	var m := Motore.new(D)
	m.nuova(seme)
	var ia := IA.new(D, m)
	if verboso:
		m.evento.connect(func(t): print("  ", t))
	var t0 := Time.get_ticks_msec()
	var n := 0
	var rifiuti := 0
	var ultimo_turno := 0
	while not m.finita() and n < 60000:
		var r := m.richiesta()
		var d := ia.decidi(r)
		var res := m.applica(d)
		n += 1
		if not res["ok"]:
			ia.rifiutata(d)
			rifiuti += 1
			if verboso:
				print("RIFIUTO ", d, " ", res.get("msg", ""))
			if rifiuti > 30:
				m.applica({"t": "combatti"})
				m.applica({"t": "fine"})
				rifiuti = 0
			continue
		rifiuti = 0
		if int(m.s["turno"]) != ultimo_turno:
			ultimo_turno = int(m.s["turno"])
			var c := {"asse": 0, "alleati": 0, "urss": 0}
			for uid in m.s["u"]:
				c[m.lato_di(uid)] += 1
			var ctrl := {"asse": 0, "alleati": 0, "urss": 0, "": 0}
			for id in m.s["ctrl"]:
				ctrl[m.s["ctrl"][id]] += 1
			if OS.get_environment("POSIZIONI") == str(ultimo_turno):
				var per := {}
				for uid in m.s["u"]:
					var h: String = m.s["u"][uid]["h"]
					per[h] = per.get(h, "") + " " + m.s["u"][uid]["naz"] + m.s["u"][uid]["t"] + ("r" if m.s["u"][uid]["r"] else "")
				for h in per:
					print("    ", h, " [", m.s["ctrl"][h], "]", per[h])
			print("%s armate %s aree %s rif %s arresi %s (%d ms)" % [m.data_testo(), c, ctrl, m.s["rif"], m.s["arresi"].keys(), Time.get_ticks_msec() - t0])
	print("FINE ", m.s.get("esito", ""), " ", m.s.get("esito_testo", ""), " decisioni ", n, " tempo ", Time.get_ticks_msec() - t0)
	quit()
