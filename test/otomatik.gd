extends Node
## Otomatik test: oyunu başlatır, girdileri taklit eder, ekran görüntüsü alır.
## Çalıştırma: godot --path . -- --otomatik-test

var _t := 0.0
var _adim := 0
var ana: Node
var kayit_yolu := "/tmp/kvk_test/"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(kayit_yolu)

func _foto(ad: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(kayit_yolu + ad + ".png")
	print("FOTO ", ad)

func _dokun(index: int, p: Vector2, basili: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.position = p
	e.pressed = basili
	Input.parse_input_event(e)

func _surukle(index: int, p: Vector2, rel: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = index
	e.position = p
	e.relative = rel
	Input.parse_input_event(e)

func _process(dt: float) -> void:
	_t += dt
	ana = get_tree().current_scene
	if ana == null or not ana.has_method("mesaj_goster"):
		return
	var k = ana.kahraman
	match _adim:
		0:
			if _t > 1.0:
				_foto("01_menu")
				ana._secim_ac()
				_adim += 1
		100:
			pass
		1:
			if _t > 1.8:
				_foto("00_secim")
				ana._secim_menu.visible = false
				ana._basla()
				_adim = 101
		101:
			if _t > 2.0:
				k.tecrube_ekle(4000)   # yetenekler açılsın
				k.mana = 9999
				_adim = 2
		2:
			if _t > 5.5:
				_foto("02_dalga"); _adim += 1
				Oyun.eylem_basildi.emit("yetenek1")
		3:
			if _t > 6.6:
				_foto("03_kasirga"); _adim += 1
		4:
			if _t > 9.0:
				k.mana = 9999
				Oyun.eylem_basildi.emit("yetenek4"); _adim += 1
		5:
			if _t > 10.1:
				_foto("04_meteor"); _adim += 1
		6:
			if _t > 11.5:
				k.mana = 9999
				Oyun.eylem_basildi.emit("yetenek2"); _adim += 1
		7:
			if _t > 11.95:
				_foto("05_yer_yarma"); _adim += 1
		8:
			if _t > 13.0:
				k.ofke = 100.0
				Oyun.eylem_basildi.emit("son_vurus"); _adim += 1
		9:
			if _t > 13.45:
				_foto("06_son_vurus"); _adim += 1
		10:
			# --- dokunmatik testi (pencere 1600x900, oyun 1280x720 tabanlı)
			if _t > 15.0:
				Oyun.dokunmatik_acik = true
				ana.dokunmatik.visible = true
				ana.hud.mobil_duzen = true
				var ws := DisplayServer.window_get_size()
				var vs := ana.get_viewport().get_visible_rect().size
				print("PENCERE ", ws, " GORUNEN ", vs)
				var olcek := float(ws.x) / vs.x
				# joystick: sol yarıda parmak 0 bas, sağa sürükle
				_dokun(0, Vector2(300, 600) * olcek, true)
				_surukle(0, Vector2(380, 600) * olcek, Vector2(80, 0) * olcek)
				_adim += 1
		11:
			if _t > 15.3:
				print("JOY YON ", Oyun.dokunmatik_yon)
				# ikinci parmak saldırı düğmesine (viewport koordinatında)
				var b: Vector2 = ana.dokunmatik._dugmeler["saldir"]["merkez"]
				var ws := DisplayServer.window_get_size()
				var vs := ana.get_viewport().get_visible_rect().size
				_dokun(1, b * (float(ws.x) / vs.x), true)
				_adim += 1
		12:
			if _t > 15.6:
				print("SALDIR BASILI ", Input.is_action_pressed("saldir"), " JOY HALA ", Oyun.dokunmatik_yon)
				_foto("07_dokunmatik")
				_dokun(0, Vector2.ZERO, false)   # joystick parmağı kalktı
				_adim += 1
		13:
			if _t > 15.8:
				print("JOY BIRAKILDI ", Oyun.dokunmatik_yon, " SALDIR HALA ", Input.is_action_pressed("saldir"))
				_dokun(1, Vector2.ZERO, false)
				_adim += 1
		14:
			if _t > 16.0:
				print("HEPSI BIRAKILDI saldir=", Input.is_action_pressed("saldir"), " yon=", Oyun.dokunmatik_yon)
				# bırakma olayı kaybolursa: arka plana geçiş
				var ws := DisplayServer.window_get_size()
				_dokun(2, Vector2(200, 500), true)
				_surukle(2, Vector2(260, 450), Vector2(60, -50))
				Oyun.tum_girdileri_birak()
				print("ARKA PLAN SONRASI yon=", Oyun.dokunmatik_yon, " parmak=", ana.dokunmatik._parmak)
				_adim += 1
		15:
			if _t > 16.5:
				var ws := DisplayServer.window_get_size()
				var vs := ana.get_viewport().get_visible_rect().size
				var mh: Rect2 = ana.hud.kucuk_harita_alani()
				_dokun(3, mh.position * (float(ws.x) / vs.x), true)
				_adim += 1
		16:
			if _t > 16.8:
				_dokun(3, Vector2.ZERO, false)
				print("HARITA ACIK ", ana.hud.buyuk_harita, " DURAKLADI ", get_tree().paused)
				_foto("08_harita")
				_dokun(4, Vector2(500, 300), true)
				_adim += 1
		17:
			if _t > 17.1:
				_dokun(4, Vector2(500, 300), false)
				print("HARITA KAPANDI ", not ana.hud.buyuk_harita, " DEVAM ", not get_tree().paused)
				_adim += 1
		18:
			if _t > 17.4:
				for i in 9:
					k.esya_al(Esya.uret(8, i % 4))
				var ws := DisplayServer.window_get_size()
				var vs := ana.get_viewport().get_visible_rect().size
				var cb: Vector2 = ana.dokunmatik._dugmeler["canta"]["merkez"]
				_dokun(5, cb * (float(ws.x) / vs.x), true)
				_adim += 1
		19:
			if _t > 17.7:
				_dokun(5, Vector2.ZERO, false)
				print("ENVANTER ACIK ", ana.envanter.visible, " CANTA ", k.canta.size(), " TAKILI ", k.esyalar.keys())
				ana.envanter._canta_sec(0)
				_adim += 1
		20:
			if _t > 18.0:
				_foto("09_envanter")
				var once: int = k.canta.size()
				ana.envanter._tak()
				print("TAKILDI canta ", once, " -> ", k.canta.size())
				ana.envanter.kapat_()
				print("ENVANTER KAPANDI ", not ana.envanter.visible, " DEVAM ", not get_tree().paused)
				_adim += 1
		21:
			if _t > 18.4:
				k.altin = 5000
				ana._kasaba_ac()
				_adim += 1
		22:
			if _t > 19.0:
				_foto("10_kasaba")
				ana.kasaba.visible = false
				ana.kasaba.kapandi.emit()
				var s0 = get_tree().get_nodes_in_group("sandik")[0]
				k.global_position = s0.global_position + Vector3(1.2, 0, 0)
				_adim += 1
		23:
			if _t > 19.8:
				print("SANDIK ACIK ", get_tree().get_nodes_in_group("sandik")[0].acik, " GANIMET ", get_tree().get_nodes_in_group("ganimet").size())
				_foto("11_sandik")
				ana._yeniden(false)
				_adim += 1
		24:
			if _t > 20.6:
				print("KAYIT ", Oyun.karakter_yukle(Oyun.secili_sinif if Oyun.secili_sinif != "" else "muhafiz").get("seviye"), " MENU DEVAM ", get_tree().current_scene._kayit.get("dalga"))
				_foto("12_menu_devam")
				_adim += 1
		25:
			if _t > 21.0:
				print("SEVIYE ", k.seviye, " CAN ", int(k.can), " DALGA ", ana.dalga, " OLDURULEN ", ana._oldurulen)
				get_tree().quit()
