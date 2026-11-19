extends Node
## Boss ve uzun oyun testi: 10. dalgaya atlar, kahraman ölümsüz, sürekli saldırır.
var _t := 0.0
var _foto_alindi := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(dt: float) -> void:
	_t += dt
	var ana = get_tree().current_scene
	if ana == null or not ana.has_method("mesaj_goster"):
		return
	var k = ana.kahraman
	if _t > 1.0 and ana.durum == "menu":
		ana._basla()
		ana.dalga = 9
		k.tecrube_ekle(20000)
	if ana.durum == "oyun":
		k._dokunulmaz = 99.0
		k.mana = 9999
		Input.action_press("saldir")
		if int(_t * 2) % 7 == 0:
			Oyun.eylem_basildi.emit(["yetenek1", "yetenek2", "yetenek4", "yetenek3"][int(_t) % 4])
		if fmod(_t, 9.0) < dt:
			k.ofke = 100
			Oyun.eylem_basildi.emit("son_vurus")
	if ana.boss != null and is_instance_valid(ana.boss) and _foto_alindi == 0 and _t > 9.0:
		get_viewport().get_texture().get_image().save_png("/tmp/kvk_test/09_boss.png")
		_foto_alindi = 1
		print("BOSS GORULDU can=", int(ana.boss.can))
	if _t > 40.0:
		print("SON: dalga=", ana.dalga, " seviye=", k.seviye, " olduruldu=", ana._oldurulen, " boss=", ana.boss, " canli=", ana._canli, " fps=", Engine.get_frames_per_second())
		get_tree().quit()
