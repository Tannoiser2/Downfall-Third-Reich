extends SceneTree
func _initialize():
	var D := Dati.new()
	D.carica()
	var m := Motore.new(D)
	m.nuova(7)
	print("unita ", m.s["u"].size(), " richiesta ", m.richiesta())
	for uid in m.s["u"]:
		if m.s["u"][uid]["h"] == "francoforte":
			print(uid, " ", m.nome_unita(uid), " dest ", m.destinazioni(uid).keys())
			break
	quit()
