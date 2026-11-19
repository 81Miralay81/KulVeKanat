extends Node3D
## Ana sahne: dünya, ışık, kamera, kahraman, dalgalar, arayüz ve menüler.

var mobil := false
var dunya: Node3D
var kamera: Camera3D
var kahraman: Kahraman
var hud: Hud
var dokunmatik: Dokunmatik
var boss: Dusman
var dusmanlar: Array = []       ## her fizik karesinde bir kez güncellenir (hızlı erişim)
var envanter: Envanter
var _env: Environment
var _ay: DirectionalLight3D

var durum := "menu"            ## menu, oyun, olum
var dalga := 0
var _sira: Array = []          ## doğacak düşmanlar
var _dogus_sayac := 0.0
var _ara_sayac := 0.0
var _canli := 0
var _oldurulen := 0
var _sarsinti := 0.0
var _kamera_hedef := Vector3.ZERO
var _duraklat_sure := 0.0
var _bolum_bitti := false

var _menu_katman: CanvasLayer
var _menu: Control
var _duraklat_menu: Control
var _olum_menu: Control
var _guncelleme_kutu: Control
var _tema: Theme
var _baslik_font: Font

const KAMERA_OFSET := Vector3(9.5, 15.0, 9.5)


func _ready() -> void:
	mobil = Oyun.mobil
	process_mode = Node.PROCESS_MODE_ALWAYS
	dunya = Node3D.new()
	dunya.name = "Dunya"
	dunya.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(dunya)
	Efekt.kur(dunya, mobil)
	_ortam()
	Dunya.insa(dunya, mobil)

	kamera = Camera3D.new()
	kamera.fov = 42.0
	kamera.far = 120.0
	add_child(kamera)

	kahraman = Kahraman.new()
	kahraman.ana = self
	dunya.add_child(kahraman)
	kahraman.global_position = Vector3(0, 0, 4)
	kahraman.oldu.connect(_kahraman_oldu)
	kahraman.seviye_atladi.connect(func(s):
		mesaj_goster("SEVİYE %d" % s, Color(1, 0.85, 0.4), true))
	kahraman.yetenek_acildi.connect(func(y):
		mesaj_goster("Yeni yetenek: %s" % Kahraman.YETENEK_AD[y], Color(1, 0.65, 0.3), false))
	kahraman.esya_alindi.connect(func(e, t): hud.esya_bildir(e, t))
	_kamera_hedef = kahraman.global_position
	_kamera_guncelle(1.0)

	var hud_katman := CanvasLayer.new()
	hud_katman.layer = 1
	add_child(hud_katman)
	hud = Hud.new()
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	hud.kahraman = kahraman
	hud.ana = self
	hud.mobil_duzen = Oyun.dokunmatik_acik
	hud_katman.add_child(hud)

	var dok_katman := CanvasLayer.new()
	dok_katman.layer = 2
	add_child(dok_katman)
	dokunmatik = Dokunmatik.new()
	dokunmatik.kahraman = kahraman
	dokunmatik.hud = hud
	dokunmatik.duraklat_cagri = _duraklat_ac_kapa
	dokunmatik.envanter_cagri = _envanter_ac
	dokunmatik.harita_cagri = func(p: Vector2) -> bool: return durum == "oyun" and not _duraklat_menu.visible and not envanter.visible and hud.harita_dokunus(p)
	dok_katman.add_child(dokunmatik)
	Oyun.dokunmatik_goster_degisti.connect(func(_a):
		hud.mobil_duzen = true
		dokunmatik.visible = durum == "oyun")

	_menuleri_kur()
	_kalite_uygula()
	get_tree().create_timer(0.3).timeout.connect(func(): Efekt.isinma(kahraman.global_position + Vector3(2, 0, 2)))
	var g := Guncelleme.new()
	g.sonuc.connect(_guncelleme_sonucu)
	add_child(g)

	if Oyun.get("dogrudan_basla"):
		Oyun.set("dogrudan_basla", false)
		_basla()
	else:
		_menu_goster()


# ------------------------------------------------------------------ ortam
func _ortam() -> void:
	var env := Environment.new()
	_env = env
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.015, 0.025)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.36, 0.28, 0.27)
	env.ambient_light_energy = 0.28
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.85
	env.glow_strength = 1.0
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.95
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.set_glow_level(0, 0.0)
	env.set_glow_level(1, 1.0)
	env.set_glow_level(2, 0.8)
	env.set_glow_level(3, 0.6)
	env.set_glow_level(4, 0.4)
	env.fog_enabled = true
	env.fog_light_color = Color(0.12, 0.08, 0.1)
	env.fog_density = 0.012
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.12
	if not mobil:
		env.ssao_enabled = true
		env.ssao_intensity = 1.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var ay := DirectionalLight3D.new()
	_ay = ay
	ay.light_color = Color(0.58, 0.64, 0.95)
	ay.light_energy = 0.42
	ay.rotation_degrees = Vector3(-55, -30, 0)
	ay.shadow_enabled = true
	ay.directional_shadow_max_distance = 40.0
	ay.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL if mobil else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(ay)


# ------------------------------------------------------------------ döngü
func _physics_process(_dt: float) -> void:
	dusmanlar = get_tree().get_nodes_in_group("dusman")


func _process(dt: float) -> void:
	_kamera_guncelle(dt)
	if durum != "oyun" or get_tree().paused:
		return
	_dalga_isle(dt)


func _unhandled_input(e: InputEvent) -> void:
	if durum != "oyun":
		return
	if e.is_action_pressed("fps"):
		Oyun.fps_goster = not Oyun.fps_goster
	if e.is_action_pressed("envanter") and not _duraklat_menu.visible and not hud.buyuk_harita and not envanter.visible:
		_envanter_ac()
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("harita") and not _duraklat_menu.visible and not envanter.visible:
		hud.harita_ac_kapa()
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("duraklat"):
		if hud.buyuk_harita:
			hud.harita_ac_kapa()
		else:
			_duraklat_ac_kapa()
		get_viewport().set_input_as_handled()


func _input(e: InputEvent) -> void:
	# Farenin küçük haritaya tıklaması (dokunmatik olanları Dokunmatik ayrıca ele alır)
	if durum == "oyun" and e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT \
			and e.device != InputEvent.DEVICE_ID_EMULATION and not _duraklat_menu.visible:
		if envanter.visible:
			return
		if hud.harita_dokunus(e.position):
			get_viewport().set_input_as_handled()
		elif not hud.mobil_duzen and not hud.buyuk_harita and hud.canta_alani().has_point(e.position):
			_envanter_ac()
			get_viewport().set_input_as_handled()


func _kamera_guncelle(dt: float) -> void:
	if kahraman == null:
		return
	_kamera_hedef = _kamera_hedef.lerp(kahraman.global_position, minf(1.0, dt * 6.0))
	_sarsinti = maxf(0.0, _sarsinti - dt * 2.5)
	var s := Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * _sarsinti * _sarsinti * 0.5
	var ofset := KAMERA_OFSET * (0.9 if Oyun.dokunmatik_acik else 1.0)
	kamera.global_position = _kamera_hedef + ofset + s
	kamera.look_at(_kamera_hedef + Vector3(0, 0.8, 0) + s * 0.5, Vector3.UP)


func kamera_sars(guc: float) -> void:
	_sarsinti = clampf(maxf(_sarsinti, guc), 0.0, 1.2)


func vurus_duraklat(sure: float) -> void:
	# Güçlü vuruşta oyun bir anlığına yavaşlar: darbe hissi
	if Engine.time_scale < 1.0:
		return
	Engine.time_scale = 0.06
	get_tree().create_timer(sure, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)


func mesaj_goster(metin: String, renk := Color.WHITE, buyuk := false) -> void:
	if hud:
		hud.mesaj(metin, renk, buyuk)


# ------------------------------------------------------------------ dalgalar
func dalga_metni() -> String:
	if durum != "oyun":
		return ""
	if _bolum_bitti and _sira.is_empty() and _canli == 0 and _ara_sayac > 0:
		return "BÖLÜM 1 TAMAMLANDI"
	if dalga == 0 or (_ara_sayac > 0 and _canli == 0 and _sira.is_empty()):
		return "DALGA %d" % (dalga + 1) if _ara_sayac > 0 else ""
	return "DALGA %d" % dalga


func alt_metin() -> String:
	if durum != "oyun":
		return ""
	if _ara_sayac > 0 and _canli == 0 and _sira.is_empty():
		return "%d saniye içinde başlıyor" % int(ceil(_ara_sayac))
	return "Kalan düşman: %d" % (_canli + _sira.size())


func _dalga_isle(dt: float) -> void:
	if kahraman.durum == "olu":
		return
	if _sira.is_empty() and _canli == 0:
		if _ara_sayac <= 0:
			_ara_sayac = 4.0 if dalga > 0 else 2.5
		_ara_sayac -= dt
		if _ara_sayac <= 0:
			_ara_sayac = 0
			dalga += 1
			_sira = _dalga_listesi(dalga)
			mesaj_goster("DALGA %d" % dalga, Color(0.95, 0.8, 0.5), true)
			if dalga % 10 == 0:
				mesaj_goster("Kor Avcısı Garran geliyor!", Color(1, 0.4, 0.15), false)
		return
	_dogus_sayac -= dt
	var sinir := 24 if mobil else 34
	if _dogus_sayac <= 0 and not _sira.is_empty() and _canli < sinir:
		_dogus_sayac = 0.35
		var s: Array = _sira.pop_front()
		_dogur(s[0], s[1])


func _dalga_listesi(n: int) -> Array:
	var liste := []
	var sayi := 6 + n * 3
	if n % 10 == 0:
		sayi = 8
	for i in sayi:
		var r := randf()
		var t := "minyon"
		if n >= 2 and r < 0.25:
			t = "haydut"
		elif n >= 3 and r > 0.82:
			t = "savasci"
		elif n >= 4 and r > 0.66:
			t = "buyucu"
		liste.append([t, false])
	if n % 3 == 0:
		liste.append(["savasci", true])
	if n >= 5 and n % 5 == 0:
		liste.append([["haydut", "buyucu"].pick_random(), true])
	if n % 10 == 0:
		liste.insert(3, ["garran", false])
	return liste


func _dogur(tur: String, elit: bool) -> void:
	var d := Dusman.new()
	d.kur(tur, dalga, elit)
	d.kahraman = kahraman
	d.ana = self
	var p := Vector3.ZERO
	for deneme in 12:
		var a := randf() * TAU
		var r := randf_range(9.0, 15.0)
		p = kahraman.global_position + Vector3(cos(a), 0, sin(a)) * r
		if absf(p.x) < 18.0 and absf(p.z) < 18.0:
			break
	p.x = clampf(p.x, -18.0, 18.0)
	p.z = clampf(p.z, -18.0, 18.0)
	d.position = p
	dunya.add_child(d)
	_canli += 1
	d.oldu_sinyal.connect(_dusman_oldu)
	if tur == "garran":
		boss = d
		kamera_sars(0.6)


func boss_cagirisi(merkez: Vector3) -> void:
	for i in 4:
		var d := Dusman.new()
		d.kur("minyon", dalga)
		d.kahraman = kahraman
		d.ana = self
		var a := TAU * i / 4.0
		d.position = merkez + Vector3(cos(a), 0, sin(a)) * 3.0
		d.position.x = clampf(d.position.x, -18, 18)
		d.position.z = clampf(d.position.z, -18, 18)
		dunya.add_child(d)
		_canli += 1
		d.oldu_sinyal.connect(_dusman_oldu)


func _dusman_oldu(d: Dusman) -> void:
	_canli = max(0, _canli - 1)
	_oldurulen += 1
	hud.oldurme()
	kahraman.tecrube_ekle(d.xp)
	kahraman.ofke = minf(100.0, kahraman.ofke + (3.0 if not d.boss else 50.0))
	var p := d.global_position
	if d.boss:
		_bolum_bitti = true
		mesaj_goster("KOR AVCISI GARRAN YENİLDİ!", Color(1, 0.6, 0.2), true)
		for i in 4:
			_ganimet("esya", p + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2)), 0, 3 if i == 0 else 2)
		for i in 6:
			_ganimet("altin", p + Vector3(randf_range(-2.5, 2.5), 0, randf_range(-2.5, 2.5)), 20 + dalga * 4)
		kamera_sars(1.0)
		Efekt.kanat_tuyu_patlamasi(p)
		boss = null
		return
	if d.elit:
		_ganimet("esya", p, 0, 1)
	elif randf() < 0.07:
		_ganimet("esya", p, 0, 0)
	if randf() < 0.45:
		_ganimet("altin", p + Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.6, 0.6)), 3 + dalga * 2 + randi() % 4)
	if randf() < 0.04:
		_ganimet("iksir", p, 0)


func _ganimet(tur: String, p: Vector3, miktar := 0, en_az := 0) -> void:
	var g := Ganimet.new()
	g.tur = tur
	g.miktar = miktar
	g.kahraman = kahraman
	if tur == "esya":
		g.esya = Esya.uret(kahraman.seviye + dalga / 3, en_az)
	p.x = clampf(p.x, -18.5, 18.5)
	p.z = clampf(p.z, -18.5, 18.5)
	g.position = p
	dunya.add_child(g)


func _kahraman_oldu() -> void:
	durum = "olum"
	Oyun.kayit_guncelle(dalga, kahraman.seviye)
	dokunmatik.visible = false
	Oyun.tum_girdileri_birak()
	get_tree().create_timer(1.6).timeout.connect(func():
		_olum_menu_guncelle()
		_olum_menu.visible = true)


# ------------------------------------------------------------------ menüler
func _tema_yap() -> Theme:
	var t := Theme.new()
	var f: Font = load("res://assets/font/Rajdhani-Bold.ttf")
	t.default_font = f
	t.default_font_size = 26
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.09, 0.06, 0.06, 0.92)
	normal.border_color = Color(0.6, 0.44, 0.22)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(10)
	normal.content_margin_left = 24
	normal.content_margin_right = 24
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	var ust := normal.duplicate()
	ust.bg_color = Color(0.22, 0.1, 0.05, 0.95)
	ust.border_color = Color(1.0, 0.6, 0.25)
	var bas := normal.duplicate()
	bas.bg_color = Color(0.35, 0.14, 0.04, 0.98)
	bas.border_color = Color(1.0, 0.75, 0.4)
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", ust)
	t.set_stylebox("pressed", "Button", bas)
	t.set_stylebox("focus", "Button", ust)
	t.set_color("font_color", "Button", Color(1, 0.9, 0.75))
	t.set_color("font_hover_color", "Button", Color(1, 1, 1))
	t.set_font_size("font_size", "Button", 30)
	t.set_color("font_color", "Label", Color(0.95, 0.88, 0.78))
	return t


func _kutu(ad: String) -> Control:
	var kok := Control.new()
	kok.name = ad
	kok.set_anchors_preset(Control.PRESET_FULL_RECT)
	kok.theme = _tema
	kok.visible = false
	var arka := ColorRect.new()
	arka.color = Color(0.0, 0.0, 0.0, 0.55)
	arka.set_anchors_preset(Control.PRESET_FULL_RECT)
	kok.add_child(arka)
	var merkez := CenterContainer.new()
	merkez.set_anchors_preset(Control.PRESET_FULL_RECT)
	kok.add_child(merkez)
	var v := VBoxContainer.new()
	v.name = "Liste"
	v.add_theme_constant_override("separation", 16)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	merkez.add_child(v)
	_menu_katman.add_child(kok)
	return kok


func _baslik(metin: String, boy := 64, renk := Color(1, 0.75, 0.4)) -> Label:
	var l := Label.new()
	l.text = metin
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", _baslik_font)
	l.add_theme_font_size_override("font_size", boy)
	l.add_theme_color_override("font_color", renk)
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.03, 0.0))
	l.add_theme_constant_override("outline_size", 10)
	return l


func _yazi_etiket(metin: String, boy := 22, renk := Color(0.9, 0.85, 0.75)) -> Label:
	var l := Label.new()
	l.text = metin
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", boy)
	l.add_theme_color_override("font_color", renk)
	return l


func _dugme(metin: String, cagri: Callable) -> Button:
	var b := Button.new()
	b.text = metin
	b.custom_minimum_size = Vector2(360, 66)
	b.pressed.connect(func():
		Ses.cal("dugme", -4.0, 0.0)
		cagri.call())
	return b


func _menuleri_kur() -> void:
	_tema = _tema_yap()
	_baslik_font = load("res://assets/font/Cinzel-Black.ttf")
	_menu_katman = CanvasLayer.new()
	_menu_katman.layer = 5
	_menu_katman.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_menu_katman)

	# Ana menü
	_menu = _kutu("AnaMenu")
	var v: VBoxContainer = _menu.find_child("Liste", true, false)
	var logo := TextureRect.new()
	logo.texture = load("res://assets/logo_mark.png")
	logo.custom_minimum_size = Vector2(150, 150)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(logo)
	v.add_child(_baslik("KÜL VE KANAT", 76))
	v.add_child(_yazi_etiket("Kanatix  ·  1. Bölüm: Kül Ovaları", 22, Color(0.85, 0.75, 0.6)))
	v.add_child(_dugme("BAŞLA", _basla))
	v.add_child(_kalite_dugmesi())
	v.add_child(_dugme("KONTROLLER", func():
		var y: Label = _menu.find_child("Yardim", true, false)
		y.visible = not y.visible))
	if not mobil:
		v.add_child(_dugme("ÇIKIŞ", func(): get_tree().quit()))
	var yardim := _yazi_etiket("", 19, Color(0.9, 0.85, 0.75))
	yardim.name = "Yardim"
	yardim.visible = false
	if mobil:
		yardim.text = "Sol yarı: parmağını koyduğun yerden yürü (joystick)\nBüyük düğme: basılı tut, sürekli saldır\nEtraftaki 4 düğme: yetenekler  ·  Üstteki kanat: Kanat Açılımı\nKırmızı şişe: iksir  ·  Sağ üst: duraklat"
	else:
		yardim.text = "W A S D: yürü  ·  Sol tık / J: saldır (basılı tut)\nSağ tık / 1: Kor Kasırgası  ·  2: Yer Yarma  ·  Boşluk / 3: Kanat Atılımı\n4: Meteor Yağmuru  ·  R: Kanat Açılımı  ·  Q: İksir  ·  ESC: duraklat\nOyun kolu da çalışır"
	v.add_child(yardim)
	var rekor := _yazi_etiket("En iyi: Dalga %d  ·  Seviye %d" % [int(Oyun.kayit["en_iyi_dalga"]), int(Oyun.kayit["en_iyi_seviye"])], 18, Color(0.75, 0.7, 0.6))
	v.add_child(rekor)
	_guncelleme_kutu = VBoxContainer.new()
	_guncelleme_kutu.visible = false
	v.add_child(_guncelleme_kutu)
	var surum := _yazi_etiket("Sürüm %s" % Oyun.SURUM, 16, Color(0.6, 0.55, 0.5))
	surum.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	surum.position = Vector2(-160, -36)
	surum.size = Vector2(150, 30)
	_menu.add_child(surum)

	# Envanter
	envanter = Envanter.new()
	envanter.theme = _tema
	envanter.visible = false
	envanter.kahraman = kahraman
	envanter.kapandi.connect(func():
		get_tree().paused = false
		hud.visible = true
		dokunmatik.visible = Oyun.dokunmatik_acik and durum == "oyun"
		Oyun.tum_girdileri_birak())
	_menu_katman.add_child(envanter)

	# Duraklatma
	_duraklat_menu = _kutu("Duraklat")
	v = _duraklat_menu.find_child("Liste", true, false)
	v.add_child(_baslik("DURAKLATILDI", 54))
	var esyalar := _yazi_etiket("", 18)
	esyalar.name = "Esyalar"
	v.add_child(esyalar)
	v.add_child(_dugme("DEVAM", _duraklat_ac_kapa))
	v.add_child(_dugme("ENVANTER", func():
		_duraklat_ac_kapa()
		_envanter_ac()))
	v.add_child(_kalite_dugmesi())
	v.add_child(_dugme("YENİDEN BAŞLA", func(): _yeniden(true)))
	v.add_child(_dugme("ANA MENÜ", func(): _yeniden(false)))

	# Ölüm
	_olum_menu = _kutu("Olum")
	v = _olum_menu.find_child("Liste", true, false)
	v.add_child(_baslik("KÜLE DÖNDÜN", 60, Color(1, 0.4, 0.2)))
	var ozet := _yazi_etiket("", 24)
	ozet.name = "Ozet"
	v.add_child(ozet)
	v.add_child(_dugme("TEKRAR DENE", func(): _yeniden(true)))
	v.add_child(_dugme("ANA MENÜ", func(): _yeniden(false)))


func _menu_goster() -> void:
	durum = "menu"
	_menu.visible = true
	hud.visible = false
	dokunmatik.visible = false


func _basla() -> void:
	_menu.visible = false
	durum = "oyun"
	hud.visible = true
	hud.mobil_duzen = Oyun.dokunmatik_acik
	dokunmatik.visible = Oyun.dokunmatik_acik
	Ses.muzik_baslat()
	dalga = 0
	_ara_sayac = 2.5
	mesaj_goster("Kül Ovaları · Yıkık Mahzen", Color(0.95, 0.8, 0.55), true)


func _duraklat_ac_kapa() -> void:
	if durum != "oyun":
		return
	if hud.buyuk_harita:
		hud.harita_ac_kapa()
		return
	var p := not get_tree().paused
	get_tree().paused = p
	_duraklat_menu.visible = p
	dokunmatik.visible = not p and Oyun.dokunmatik_acik
	Oyun.tum_girdileri_birak()
	if p:
		var l: Label = _duraklat_menu.find_child("Esyalar", true, false)
		var satirlar := ["Seviye %d  ·  Dalga %d  ·  %d altın  ·  %d düşman  ·  FPS %d" % [kahraman.seviye, dalga, kahraman.altin, _oldurulen, Engine.get_frames_per_second()], ""]
		for y in Esya.YUVALAR:
			if kahraman.esyalar.has(y):
				var e: Dictionary = kahraman.esyalar[y]
				satirlar.append("%s: %s (%s)  %s" % [y, e["ad"], Esya.NADIRLIK[e["nadirlik"]]["ad"], Esya.ozet(e)])
			else:
				satirlar.append("%s: boş" % y)
		l.text = "\n".join(satirlar)


func _olum_menu_guncelle() -> void:
	var l: Label = _olum_menu.find_child("Ozet", true, false)
	l.text = "Dalga %d  ·  Seviye %d  ·  %d düşman  ·  %d altın" % [dalga, kahraman.seviye, _oldurulen, kahraman.altin]


func _yeniden(hemen: bool) -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	Oyun.tum_girdileri_birak()
	Ses.ates_dongu(false)
	Oyun.set("dogrudan_basla", hemen)
	get_tree().reload_current_scene()


func _guncelleme_sonucu(yeni: bool, surum: String, adres: String) -> void:
	if not yeni:
		return
	_guncelleme_kutu.visible = true
	_guncelleme_kutu.add_child(_yazi_etiket("Yeni sürüm var: %s" % surum, 22, Color(1, 0.7, 0.3)))
	_guncelleme_kutu.add_child(_dugme("YENİ SÜRÜMÜ İNDİR", func(): OS.shell_open(adres)))



# ------------------------------------------------------------------ envanter ve grafik kalitesi
func _envanter_ac() -> void:
	if durum != "oyun" or _duraklat_menu.visible or hud.buyuk_harita:
		return
	Oyun.tum_girdileri_birak()
	get_tree().paused = true
	dokunmatik.visible = false
	hud.visible = false
	envanter.ac()


const KALITE_AD := ["DÜŞÜK", "ORTA", "YÜKSEK"]


func _kalite_dugmesi() -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(360, 66)
	b.text = "GRAFİK: %s" % KALITE_AD[int(Oyun.kayit["kalite"])]
	b.pressed.connect(func():
		Oyun.kayit["kalite"] = (int(Oyun.kayit["kalite"]) + 1) % 3
		Oyun.kaydet()
		_kalite_uygula()
		for k in get_tree().get_nodes_in_group("kalite_dugmesi"):
			k.text = "GRAFİK: %s" % KALITE_AD[int(Oyun.kayit["kalite"])]
		Ses.cal("dugme", -4.0, 0.0))
	b.add_to_group("kalite_dugmesi")
	return b


func _kalite_uygula() -> void:
	var k := int(Oyun.kayit["kalite"])
	var vp := get_viewport()
	match k:
		0:
			_env.ssao_enabled = false
			_env.fog_enabled = false
			_ay.shadow_enabled = false
			vp.msaa_3d = Viewport.MSAA_DISABLED
			vp.scaling_3d_scale = 0.75
			Efekt.kalite = 0.5
			Efekt.sinir = 40
		1:
			_env.ssao_enabled = false
			_env.fog_enabled = true
			_ay.shadow_enabled = true
			_ay.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
			vp.msaa_3d = Viewport.MSAA_2X if not mobil else Viewport.MSAA_DISABLED
			vp.scaling_3d_scale = 1.0
			Efekt.kalite = 0.8
			Efekt.sinir = 60
		2:
			_env.ssao_enabled = not mobil
			_env.fog_enabled = true
			_ay.shadow_enabled = true
			_ay.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
			vp.msaa_3d = Viewport.MSAA_4X if not mobil else Viewport.MSAA_2X
			vp.scaling_3d_scale = 1.0
			Efekt.kalite = 1.0
			Efekt.sinir = 90
