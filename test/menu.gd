extends Node
## Menü düzeni testi (telefon oranı): ana menü ve duraklatma menüsü ekran görüntüsü.
var _t := 0.0
var _a := 0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute("/tmp/kvk_test/")
func _foto(ad: String) -> void:
	get_viewport().get_texture().get_image().save_png("/tmp/kvk_test/" + ad + ".png")
func _process(dt: float) -> void:
	_t += dt
	var ana = get_tree().current_scene
	if ana == null or not ana.has_method("mesaj_goster"):
		return
	if _a == 0 and _t > 1.5:
		_foto("m1_ana_menu"); _a = 1
		Oyun.dokunmatik_acik = true
		ana._basla()
	elif _a == 1 and _t > 3.0:
		ana._duraklat_ac_kapa(); _a = 2
	elif _a == 2 and _t > 3.5:
		_foto("m2_duraklat"); _a = 3
		print("GORUNEN ", ana.get_viewport().get_visible_rect().size)
		get_tree().quit()
