extends SceneTree
func _initialize():
	for f in ["res://scripts/dati.gd", "res://scripts/motore.gd", "res://scripts/ia.gd", "res://scripts/vista3d.gd", "res://scripts/rete.gd", "res://scripts/main.gd"]:
		var s = load(f)
		print(f, " ", s != null)
	quit()
