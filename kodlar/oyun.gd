extends Node
## Genel oyun durumu: sürüm, girdiler (klavye, fare, dokunmatik), kayıt.

const SURUM := "0.2.0"
const DEPO := "81Miralay81/KulVeKanat"

## Oyunun kullandığı eylemler (klavye tuşları aşağıda tanımlanır).
const EYLEMLER := ["saldir", "yetenek1", "yetenek2", "yetenek3", "yetenek4", "son_vurus", "iksir"]

signal eylem_basildi(ad: String)      ## bir düğmeye / tuşa basıldı (asla kaçmaz)
signal girdiler_birakildi              ## uygulama arka plana geçti, her şey bırakıldı
signal dokunmatik_goster_degisti(acik: bool)

var mobil := false
var dokunmatik_acik := false          ## ekrandaki dokunmatik düğmeler görünsün mü
var dokunmatik_yon := Vector2.ZERO    ## joystick yönü (uzunluk 0..1)
var son_girdi_fare := false           ## en son fare mi kullanıldı (nişan için)
var dogrudan_basla := false           ## yeniden başlatınca menüyü atla
var secili_sinif := ""                ## karakter seçiminde seçilen sınıf (boşsa son oynanan)
var kayit := {"en_iyi_dalga": 0, "en_iyi_seviye": 1, "kalite": 1, "son_sinif": ""}
var fps_goster := false

const KAYIT_YOLU := "user://kayit.cfg"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mobil = OS.has_feature("android") or OS.has_feature("ios")
	dokunmatik_acik = mobil
	if mobil:
		Engine.max_fps = 60
	_tuslari_tanimla()
	_kayit_yukle()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--sinif="):
			secili_sinif = arg.trim_prefix("--sinif=")
	if "--otomatik-test" in OS.get_cmdline_user_args():
		add_child(load("res://test/otomatik.gd").new())
	if "--boss-test" in OS.get_cmdline_user_args():
		add_child(load("res://test/boss.gd").new())


func _tuslari_tanimla() -> void:
	var tuslar := {
		"sol": [KEY_A, KEY_LEFT], "sag": [KEY_D, KEY_RIGHT],
		"yukari": [KEY_W, KEY_UP], "asagi": [KEY_S, KEY_DOWN],
		"saldir": [KEY_J], "yetenek1": [KEY_1, KEY_K], "yetenek2": [KEY_2, KEY_L],
		"yetenek3": [KEY_3, KEY_SPACE], "yetenek4": [KEY_4, KEY_F], "envanter": [KEY_I, KEY_B], "fps": [KEY_F3],
		"son_vurus": [KEY_R], "iksir": [KEY_Q], "duraklat": [KEY_ESCAPE, KEY_P], "harita": [KEY_M, KEY_TAB],
	}
	for ad in tuslar:
		if not InputMap.has_action(ad):
			InputMap.add_action(ad, 0.2)
		for k in tuslar[ad]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(ad, e)
	# oyun kolu (Xbox tipi)
	var kol := {"saldir": JOY_BUTTON_X, "yetenek1": JOY_BUTTON_Y, "yetenek2": JOY_BUTTON_B,
		"yetenek3": JOY_BUTTON_A, "yetenek4": JOY_BUTTON_RIGHT_SHOULDER,
		"son_vurus": JOY_BUTTON_LEFT_SHOULDER, "iksir": JOY_BUTTON_DPAD_UP, "duraklat": JOY_BUTTON_START, "harita": JOY_BUTTON_BACK, "envanter": JOY_BUTTON_DPAD_DOWN}
	for ad in kol:
		var j := InputEventJoypadButton.new()
		j.button_index = kol[ad]
		InputMap.action_add_event(ad, j)
	for eksen in [["sol", JOY_AXIS_LEFT_X, -1.0], ["sag", JOY_AXIS_LEFT_X, 1.0],
			["yukari", JOY_AXIS_LEFT_Y, -1.0], ["asagi", JOY_AXIS_LEFT_Y, 1.0]]:
		var m := InputEventJoypadMotion.new()
		m.axis = eksen[1]
		m.axis_value = eksen[2]
		InputMap.action_add_event(eksen[0], m)


func _unhandled_input(e: InputEvent) -> void:
	# Klavye / oyun kolu: eylem olaylarını sinyale çevir (kısa basışlar kaçmaz).
	if e is InputEventKey or e is InputEventJoypadButton:
		if e is InputEventKey and e.echo:
			return
		for ad in EYLEMLER:
			if e.is_action_pressed(ad):
				son_girdi_fare = false
				eylem_basildi.emit(ad)
	# Fare: dokunmatikten taklit edilen fare olaylarını YOK SAY (telefonda çift tetiklemeyi önler).
	elif e is InputEventMouseButton and e.device != InputEvent.DEVICE_ID_EMULATION:
		var hedef := ""
		if e.button_index == MOUSE_BUTTON_LEFT:
			hedef = "saldir"
		elif e.button_index == MOUSE_BUTTON_RIGHT:
			hedef = "yetenek1"
		if hedef != "":
			son_girdi_fare = true
			if e.pressed:
				Input.action_press(hedef)
				eylem_basildi.emit(hedef)
			else:
				Input.action_release(hedef)
	elif e is InputEventMouseMotion and e.device != InputEvent.DEVICE_ID_EMULATION:
		son_girdi_fare = true
	elif e is InputEventScreenTouch and not dokunmatik_acik:
		# Dokunmatik ekranlı bilgisayarda ilk dokunuşta düğmeleri göster.
		dokunmatik_acik = true
		dokunmatik_goster_degisti.emit(true)


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED,
			NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		tum_girdileri_birak()


## Takılı kalan düğme / sürekli yürüme olmasın diye her şeyi sıfırla.
func tum_girdileri_birak() -> void:
	dokunmatik_yon = Vector2.ZERO
	for ad in EYLEMLER:
		Input.action_release(ad)
	girdiler_birakildi.emit()


## Klavye/kol ile dokunmatik joystick'ten hangisi daha güçlüyse onu döndürür.
func hareket_vektoru() -> Vector2:
	var k := Input.get_vector("sol", "sag", "yukari", "asagi", 0.2)
	if dokunmatik_yon.length() > k.length():
		return dokunmatik_yon
	return k


func _kayit_yukle() -> void:
	var c := ConfigFile.new()
	if c.load(KAYIT_YOLU) == OK:
		for k in kayit:
			kayit[k] = c.get_value("oyun", k, kayit[k])


func kayit_guncelle(dalga: int, seviye: int) -> void:
	kayit["en_iyi_dalga"] = max(int(kayit["en_iyi_dalga"]), dalga)
	kayit["en_iyi_seviye"] = max(int(kayit["en_iyi_seviye"]), seviye)
	kaydet()


func kaydet() -> void:
	var c := ConfigFile.new()
	for k in kayit:
		c.set_value("oyun", k, kayit[k])
	c.save(KAYIT_YOLU)



# ------------------------------------------------------------------ karakter kayıtları (her sınıfa bir kayıt)
func _karakter_yolu(sinif: String) -> String:
	return "user://karakter_%s.json" % sinif


func karakter_kaydet(veri: Dictionary) -> void:
	var f := FileAccess.open(_karakter_yolu(veri["sinif"]), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(veri))
		f.close()
	kayit["son_sinif"] = veri["sinif"]
	kaydet()


func karakter_yukle(sinif: String) -> Dictionary:
	if sinif == "" or not FileAccess.file_exists(_karakter_yolu(sinif)):
		return {}
	var f := FileAccess.open(_karakter_yolu(sinif), FileAccess.READ)
	if f == null:
		return {}
	var v = JSON.parse_string(f.get_as_text())
	return v if typeof(v) == TYPE_DICTIONARY else {}


func karakter_sil(sinif: String) -> void:
	if FileAccess.file_exists(_karakter_yolu(sinif)):
		DirAccess.remove_absolute(_karakter_yolu(sinif))
	if kayit["son_sinif"] == sinif:
		kayit["son_sinif"] = ""
		kaydet()
