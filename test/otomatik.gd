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
				_foto("01_menu"); _adim += 1
				ana._basla()
		1:
			if _t > 2.0:
				k.tecrube_ekle(4000)   # yetenekler açılsın
				k.mana = 9999
				_adim += 1
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
			if _t > 17.5:
				print("SEVIYE ", k.seviye, " CAN ", int(k.can), " DALGA ", ana.dalga, " OLDURULEN ", ana._oldurulen)
				get_tree().quit()
