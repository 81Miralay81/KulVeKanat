extends Node3D
## Ana sahne: açık bölge (köy + düşman sürüleri + zindan girişleri), zindanlar (dalgalar + boss),
## kamera, kahraman, arayüz ve menüler.

var mobil := false
var dunya: Node3D
var kamera: Camera3D
var kahraman: Kahraman
var hud: Hud
var dokunmatik: Dokunmatik
var boss: Dusman
var sinif := "muhafiz"
var _kayit: Dictionary = {}
var kasaba: Kasaba
var _secim_menu: Control
var dusmanlar: Array = []       ## her fizik karesinde bir kez güncellenir (hızlı erişim)
var envanter: Envanter
var _env: Environment
var _ay: DirectionalLight3D

var durum := "menu"            ## menu, oyun, olum
var mod := "bolge"             ## bolge (açık alan + köy) ya da zindan
var bolge_kok: Node3D
var zindan_kok: Node3D
var aktif_zindan: Dictionary = {}
var temizlenen: Array = []     ## bitirilen zindanlar
var etkilesim: Dictionary = {} ## yakındaki NPC / zindan kapısı / çıkış
var dalga := 0                 ## zindanda kaçıncı dalga
var _seviye_esdeg := 1         ## doğan düşmanların gücü
var _sira: Array = []          ## zindanda doğacak düşmanlar
var _dogus_sayac := 0.0
var _ara_sayac := 0.0
var _canli := 0
var _oldurulen := 0
var _sarsinti := 0.0
var _kamera_hedef := Vector3.ZERO
var _zindan_bitti := false
var _suruler: Array = []       ## bölgedeki düşman sürüleri
var _suru_sayac := 0.0
var _sandik_sayac := 0.0
var _cikis: Node3D
var _gecis: ColorRect
var _gecis_suruyor := false

var _menu_katman: CanvasLayer
var _menu: Control
var _duraklat_menu: Control
var _olum_menu: Control
var _guncelleme_kutu: Control
var _tema: Theme
var _baslik_font: Font

const KAMERA_OFSET := Vector3(11.5, 18.0, 11.5)   ## biraz daha geriden bakış


func _ready() -> void:
	mobil = Oyun.mobil
	process_mode = Node.PROCESS_MODE_ALWAYS
	dunya = Node3D.new()
	dunya.name = "Dunya"
	dunya.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(dunya)
	Efekt.kur(dunya, mobil)
	_ortam()
	bolge_kok = Node3D.new()
	bolge_kok.name = "Bolge"
	dunya.add_child(bolge_kok)
	Bolge.insa(bolge_kok, mobil)
	for e in Bolge.ESNAFLAR:
		var n := Npc.new()
		n.veri = e
		n.position = e["konum"]
		bolge_kok.add_child(n)
	seed(77)
	var sandik_sayisi := 0
	while sandik_sayisi < 8:
		var p := Vector3(randf_range(-60, 60), 0, randf_range(-60, 60))
		if Bolge.bos_mu(p, 8.0):
			var sk := Sandik.new()
			sk.ana = self
			sk.position = p
			sk.rotation.y = randf() * TAU
			bolge_kok.add_child(sk)
			sandik_sayisi += 1
	randomize()
	for q in Bolge.suru_noktalari:
		_suruler.append({"konum": q, "uyeler": [], "bekle": 0.0, "doldu": false})

	kamera = Camera3D.new()
	kamera.fov = 42.0
	kamera.far = 160.0
	add_child(kamera)

	sinif = Oyun.secili_sinif if Oyun.secili_sinif != "" else str(Oyun.kayit.get("son_sinif", ""))
	if not sinif in Sinif.LISTE:
		sinif = "muhafiz"
	kahraman = Kahraman.new()
	kahraman.ana = self
	kahraman.sinif = sinif
	dunya.add_child(kahraman)
	_kayit = Oyun.karakter_yukle(sinif)
	if not _kayit.is_empty():
		kahraman.kayit_yukle(_kayit)
		temizlenen = _kayit.get("temizlenen", [])
	kahraman.global_position = Bolge.DOGUS
	kahraman.oldu.connect(_kahraman_oldu)
	kahraman.seviye_atladi.connect(func(s):
		mesaj_goster("SEVİYE %d" % s, Color(1, 0.85, 0.4), true))
	kahraman.yetenek_acildi.connect(func(y):
		mesaj_goster("Yeni yetenek: %s" % kahraman.yetenek_ad(y), Color(1, 0.65, 0.3), false))
	kahraman.esya_alindi.connect(func(e, t): hud.esya_bildir(e, t))
	kahraman.seviye_atladi.connect(func(_s): kaydet())
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
	dokunmatik.ana = self
	dokunmatik.duraklat_cagri = _duraklat_ac_kapa
	dokunmatik.envanter_cagri = _envanter_ac
	dokunmatik.harita_cagri = func(p: Vector2) -> bool: return durum == "oyun" and not _duraklat_menu.visible and not envanter.visible and hud.harita_dokunus(p)
	dok_katman.add_child(dokunmatik)
	Oyun.dokunmatik_goster_degisti.connect(func(_a):
		hud.mobil_duzen = true
		dokunmatik.visible = durum == "oyun")

	_menuleri_kur()
	_gecis = ColorRect.new()
	_gecis.color = Color(0, 0, 0, 0)
	_gecis.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_gecis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_katman.add_child(_gecis)
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
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.85
	env.glow_strength = 1.0
	env.glow_bloom = 0.06
	env.glow_hdr_threshold = 0.95
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.set_glow_level(0, 0.0)
	env.set_glow_level(1, 1.0)
	env.set_glow_level(2, 0.8)
	env.set_glow_level(3, 0.6)
	env.set_glow_level(4, 0.4)
	env.fog_enabled = true
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.1
	if not mobil:
		env.ssao_enabled = true
		env.ssao_intensity = 1.4
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var ay := DirectionalLight3D.new()
	_ay = ay
	ay.shadow_enabled = true
	ay.directional_shadow_max_distance = 45.0
	ay.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL if mobil else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(ay)
	_ortam_ayarla()


func _ortam_ayarla() -> void:
	## Açık alanda gün batımı ışığı (kül ve kor tonları), zindanda karanlık.
	if mod == "bolge":
		_env.background_color = Color(0.42, 0.38, 0.4)
		_env.ambient_light_color = Color(0.52, 0.52, 0.58)
		_env.ambient_light_energy = 0.42 if not mobil else 0.6
		_env.fog_light_color = Color(0.4, 0.36, 0.38)
		_env.fog_density = 0.006
		_ay.light_color = Color(1.0, 0.9, 0.8)
		_ay.light_energy = 0.85
		_ay.rotation_degrees = Vector3(-50, -40, 0)
	else:
		_env.background_color = Color(0.02, 0.015, 0.025)
		_env.ambient_light_color = Color(0.36, 0.28, 0.27)
		_env.ambient_light_energy = 0.28 if not mobil else 0.6
		_env.fog_light_color = Color(0.12, 0.08, 0.1)
		_env.fog_density = 0.012
		_ay.light_color = Color(0.58, 0.64, 0.95)
		_ay.light_energy = 0.42
		_ay.rotation_degrees = Vector3(-55, -30, 0)


# ------------------------------------------------------------------ döngü
func _physics_process(_dt: float) -> void:
	dusmanlar = get_tree().get_nodes_in_group("dusman")


func _process(dt: float) -> void:
	_kamera_guncelle(dt)
	if durum != "oyun" or get_tree().paused:
		return
	if mod == "bolge":
		_bolge_isle(dt)
	else:
		_dalga_isle(dt)
	_etkilesim_bul()


func _unhandled_input(e: InputEvent) -> void:
	if durum != "oyun":
		return
	if e.is_action_pressed("fps"):
		Oyun.fps_goster = not Oyun.fps_goster
	if e.is_action_pressed("etkilesim") and not get_tree().paused:
		etkilesim_yap()
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("envanter") and not _duraklat_menu.visible and not hud.buyuk_harita and not envanter.visible:
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
	# Farenin küçük haritaya / çantaya / etkileşim yazısına tıklaması
	if durum == "oyun" and e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT \
			and e.device != InputEvent.DEVICE_ID_EMULATION and not _duraklat_menu.visible:
		if envanter.visible or kasaba.visible:
			return
		if hud.harita_dokunus(e.position):
			get_viewport().set_input_as_handled()
		elif not hud.mobil_duzen and not hud.buyuk_harita and hud.canta_alani().has_point(e.position):
			_envanter_ac()
			get_viewport().set_input_as_handled()
		elif not etkilesim.is_empty() and hud.etkilesim_alani().has_point(e.position):
			etkilesim_yap()
			get_viewport().set_input_as_handled()


func _kamera_guncelle(dt: float) -> void:
	if kahraman == null:
		return
	_kamera_hedef = _kamera_hedef.lerp(kahraman.global_position, minf(1.0, dt * 6.0))
	_sarsinti = maxf(0.0, _sarsinti - dt * 2.5)
	var s := Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * _sarsinti * _sarsinti * 0.5
	kamera.global_position = _kamera_hedef + KAMERA_OFSET + s
	kamera.look_at(_kamera_hedef + Vector3(0, 0.8, 0) + s * 0.5, Vector3.UP)
	var kul: Node3D = bolge_kok.get_node_or_null("Kul") if bolge_kok else null
	if kul and mod == "bolge":
		kul.global_position = kahraman.global_position + Vector3(0, 3, 0)


func kamera_sars(guc: float) -> void:
	_sarsinti = clampf(maxf(_sarsinti, guc), 0.0, 1.2)


func vurus_duraklat(sure: float) -> void:
	if Engine.time_scale < 1.0:
		return
	Engine.time_scale = 0.06
	get_tree().create_timer(sure, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)


func mesaj_goster(metin: String, renk := Color.WHITE, buyuk := false) -> void:
	if hud:
		hud.mesaj(metin, renk, buyuk)


func koyde_mi() -> bool:
	return mod == "bolge" and kahraman.global_position.distance_to(Bolge.KOY) < Bolge.KOY_YARICAP + 1.5


func sinir() -> float:
	return 18.5 if mod == "zindan" else Bolge.YARI - 1.0


# ------------------------------------------------------------------ üst yazılar
func dalga_metni() -> String:
	if durum != "oyun":
		return ""
	if mod == "bolge":
		return "SON SIĞINAK" if koyde_mi() else "KÜL OVALARI"
	if _zindan_bitti:
		return "%s TEMİZLENDİ" % str(aktif_zindan["ad"]).to_upper()
	if boss != null and is_instance_valid(boss):
		return str(aktif_zindan["ad"]).to_upper() + " · BOSS"
	return "%s · DALGA %d/%d" % [str(aktif_zindan["ad"]).to_upper(), maxi(1, dalga), int(aktif_zindan["dalga"])]


func alt_metin() -> String:
	if durum != "oyun":
		return ""
	if mod == "bolge":
		if koyde_mi():
			return "Güvendesin · esnaflarla konuş, altınını harca"
		return "Zindanlar haritada (M) · köy ortada"
	if _zindan_bitti:
		return "Ortadaki kapıdan köye dönebilirsin"
	if _ara_sayac > 0 and _canli == 0 and _sira.is_empty():
		return "%d saniye içinde başlıyor" % int(ceil(_ara_sayac))
	return "Kalan düşman: %d" % (_canli + _sira.size())


# ------------------------------------------------------------------ açık bölge: düşman sürüleri
func _bolge_isle(dt: float) -> void:
	_suru_sayac -= dt
	_sandik_sayac += dt
	if _sandik_sayac > 240.0:
		_sandik_sayac = 0.0
		for sk in get_tree().get_nodes_in_group("sandik"):
			sk.doldur()
	if _suru_sayac > 0:
		return
	_suru_sayac = 0.5
	var k := kahraman.global_position
	var en_fazla := 4 if mobil else 6
	var aktif := 0
	for s in _suruler:
		s["uyeler"] = s["uyeler"].filter(func(d): return is_instance_valid(d) and not d.olu)
		if not s["uyeler"].is_empty():
			aktif += 1
	for s in _suruler:
		s["bekle"] = maxf(0.0, s["bekle"] - 0.5)
		var m: float = k.distance_to(s["konum"])
		if s["uyeler"].is_empty():
			if s["doldu"]:
				s["doldu"] = false
				s["bekle"] = 70.0       # temizlenen sürü bir süre sonra yeniden gelir
			elif s["bekle"] <= 0 and m < 42.0 and m > 16.0 and aktif < en_fazla:
				_suru_dogur(s)
				aktif += 1
		elif m > 62.0:
			for d in s["uyeler"]:          # çok uzaktaki sürü kaybolur (telefon yorulmasın)
				d.queue_free()
			s["uyeler"].clear()
			_canli = 0


func _suru_dogur(s: Dictionary) -> void:
	var p: Vector3 = s["konum"]
	var sev := maxi(1, kahraman.seviye - 1 + int((p.length() - 25.0) / 16.0))
	var adet := randi_range(3, 4) if mobil else randi_range(3, 6)
	for i in adet:
		var r := randf()
		var t := "minyon"
		if sev >= 2 and r < 0.25:
			t = "haydut"
		elif sev >= 3 and r > 0.8:
			t = "savasci"
		elif sev >= 4 and r > 0.62:
			t = "buyucu"
		var elit := i == 0 and randf() < 0.15
		var d := Dusman.new()
		d.kur(t, sev, elit)
		d.kahraman = kahraman
		d.ana = self
		d.aggro = false
		var a := TAU * i / adet
		d.position = p + Vector3(cos(a), 0, sin(a)) * randf_range(1.5, 3.5)
		dunya.add_child(d)
		d.oldu_sinyal.connect(_dusman_oldu)
		s["uyeler"].append(d)
	s["doldu"] = true


# ------------------------------------------------------------------ etkileşim (NPC, zindan kapısı, çıkış)
func _etkilesim_bul() -> void:
	etkilesim = {}
	if kahraman.durum == "olu":
		return
	var k := kahraman.global_position
	if mod == "bolge":
		for n in get_tree().get_nodes_in_group("npc"):
			if n.global_position.distance_to(k) < 3.2:
				etkilesim = {"tur": "npc", "ad": "%s ile konuş" % n.veri["ad"], "veri": n.veri["id"]}
				return
		for zd in Bolge.ZINDANLAR:
			if Bolge.giris_noktasi(zd).distance_to(k) < 4.5:
				var bitti := " (temizlendi)" if zd["id"] in temizlenen else ""
				etkilesim = {"tur": "zindan", "ad": "%s'e gir · Seviye %d+%s" % [zd["ad"], zd["seviye"], bitti], "veri": zd}
				return
	elif _cikis and is_instance_valid(_cikis) and _cikis.global_position.distance_to(k) < 3.0:
		etkilesim = {"tur": "cikis", "ad": "Köye dön", "veri": null}


func etkilesim_yap() -> void:
	if etkilesim.is_empty() or _gecis_suruyor:
		return
	match etkilesim["tur"]:
		"npc":
			_kasaba_ac(etkilesim["veri"])
		"zindan":
			var zd: Dictionary = etkilesim["veri"]
			_gecis_yap(func(): _zindana_gir(zd))
		"cikis":
			_gecis_yap(func(): _zindandan_cik(false))


func _gecis_yap(islem: Callable) -> void:
	_gecis_suruyor = true
	Oyun.tum_girdileri_birak()
	var tw := create_tween()
	tw.tween_property(_gecis, "color:a", 1.0, 0.3)
	tw.tween_callback(islem)
	tw.tween_interval(0.15)
	tw.tween_property(_gecis, "color:a", 0.0, 0.4)
	tw.tween_callback(func(): _gecis_suruyor = false)


func _yerdekileri_topla() -> void:
	for g in get_tree().get_nodes_in_group("ganimet"):
		if g.tur == "esya":
			kahraman.esya_al(g.esya)
		g.queue_free()


func _zindana_gir(zd: Dictionary) -> void:
	for d in get_tree().get_nodes_in_group("dusman"):
		d.queue_free()
	for s in _suruler:
		s["uyeler"].clear()
		s["doldu"] = false
	_yerdekileri_topla()
	dunya.remove_child(bolge_kok)
	zindan_kok = Node3D.new()
	zindan_kok.name = "Zindan"
	dunya.add_child(zindan_kok)
	Dunya.insa(zindan_kok, mobil)
	for sd in Dunya.SANDIKLAR:
		var sk := Sandik.new()
		sk.ana = self
		sk.position = sd[0]
		sk.rotation.y = sd[1]
		zindan_kok.add_child(sk)
	mod = "zindan"
	aktif_zindan = zd
	_ortam_ayarla()
	dalga = 0
	_sira.clear()
	_canli = 0
	_zindan_bitti = false
	_ara_sayac = 2.5
	boss = null
	kahraman.global_position = Vector3(0, 0, 4)
	_kamera_hedef = kahraman.global_position
	mesaj_goster(zd["ad"], Color(1, 0.75, 0.4), true)
	kaydet()


func _zindandan_cik(koye: bool) -> void:
	for d in get_tree().get_nodes_in_group("dusman"):
		d.queue_free()
	_yerdekileri_topla()
	if zindan_kok:
		zindan_kok.queue_free()
		zindan_kok = null
	_cikis = null
	boss = null
	_sira.clear()
	_canli = 0
	if bolge_kok.get_parent() == null:
		dunya.add_child(bolge_kok)
	var zd := aktif_zindan
	mod = "bolge"
	_ortam_ayarla()
	kahraman.global_position = Bolge.DOGUS if koye or zd.is_empty() else Bolge.giris_noktasi(zd)
	_kamera_hedef = kahraman.global_position
	for sk in get_tree().get_nodes_in_group("sandik"):
		sk.doldur()
	aktif_zindan = {}
	mesaj_goster("Kül Ovaları", Color(0.95, 0.8, 0.55), true)
	kaydet()


func koye_don() -> void:
	if mod == "zindan":
		_gecis_yap(func(): _zindandan_cik(true))
	else:
		_gecis_yap(func():
			kahraman.global_position = Bolge.DOGUS
			_kamera_hedef = kahraman.global_position)


# ------------------------------------------------------------------ zindan: dalgalar ve boss
func _dalga_isle(dt: float) -> void:
	if kahraman.durum == "olu" or _zindan_bitti:
		return
	if _sira.is_empty() and _canli == 0:
		if _ara_sayac <= 0:
			_ara_sayac = 3.5 if dalga > 0 else 2.5
		_ara_sayac -= dt
		if _ara_sayac <= 0:
			_ara_sayac = 0
			dalga += 1
			_seviye_esdeg = maxi(int(aktif_zindan["seviye"]), kahraman.seviye) + dalga - 1
			_sira = _dalga_listesi(dalga)
			if dalga > int(aktif_zindan["dalga"]):
				mesaj_goster("%s geliyor!" % Dusman.TURLER[aktif_zindan["boss"]]["ad"], Color(1, 0.4, 0.15), true)
			else:
				mesaj_goster("DALGA %d/%d" % [dalga, int(aktif_zindan["dalga"])], Color(0.95, 0.8, 0.5), true)
		return
	_dogus_sayac -= dt
	var sinir_s := 16 if mobil else 30
	if _dogus_sayac <= 0 and not _sira.is_empty() and _canli < sinir_s:
		_dogus_sayac = 0.35
		var s: Array = _sira.pop_front()
		_dogur(s[0], s[1])


func _dalga_listesi(n: int) -> Array:
	var liste := []
	var son := n > int(aktif_zindan["dalga"])
	var sayi := mini(6 + n * 3, 24) if not son else 6
	var sev := _seviye_esdeg
	for i in sayi:
		var r := randf()
		var t := "minyon"
		if sev >= 2 and r < 0.25:
			t = "haydut"
		elif sev >= 3 and r > 0.82:
			t = "savasci"
		elif (sev >= 4 or aktif_zindan["boss"] == "vezra") and r > 0.66:
			t = "buyucu"
		liste.append([t, false])
	if n % 2 == 0:
		liste.append(["savasci", true])
	if son:
		liste.insert(2, [aktif_zindan["boss"], false])
	return liste


func _dogur(tur: String, elit: bool) -> void:
	var d := Dusman.new()
	d.kur(tur, _seviye_esdeg, elit)
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
	if Dusman.TURLER[tur].get("boss", false):
		boss = d
		kamera_sars(0.6)


func boss_cagirisi(merkez: Vector3) -> void:
	for i in 4:
		var d := Dusman.new()
		d.kur("minyon", _seviye_esdeg)
		d.kahraman = kahraman
		d.ana = self
		var a := TAU * i / 4.0
		d.position = merkez + Vector3(cos(a), 0, sin(a)) * 3.0
		var lim := sinir() - 0.5
		d.position.x = clampf(d.position.x, -lim, lim)
		d.position.z = clampf(d.position.z, -lim, lim)
		dunya.add_child(d)
		_canli += 1
		d.oldu_sinyal.connect(_dusman_oldu)


func _zindan_tamam(p: Vector3) -> void:
	_zindan_bitti = true
	if not aktif_zindan["id"] in temizlenen:
		temizlenen.append(aktif_zindan["id"])
	mesaj_goster("%s TEMİZLENDİ!" % str(aktif_zindan["ad"]).to_upper(), Color(1, 0.6, 0.2), true)
	# ortada çıkış kapısı
	_cikis = Node3D.new()
	dunya.add_child(_cikis)
	_cikis.global_position = Vector3(0, 0, 0)
	var h := MeshInstance3D.new()
	h.mesh = Efekt.halka_mesh(1.6, 2.4)
	h.material_override = Efekt.parlak_mat(Color(0.4, 0.8, 1.0), 2.5)
	h.position.y = 0.06
	_cikis.add_child(h)
	_cikis.add_child(Efekt.isik_sutunu(Vector3.ZERO, Color(0.4, 0.8, 1.0), 6.0, 1.4, -1, 1.6))
	var l := Label3D.new()
	l.text = "KÖYE DÖNÜŞ KAPISI"
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 56
	l.pixel_size = 0.008
	l.outline_size = 14
	l.modulate = Color(0.6, 0.9, 1.0)
	l.position.y = 3.2
	_cikis.add_child(l)
	kaydet()


func _dusman_oldu(d: Dusman) -> void:
	if mod == "zindan":
		_canli = max(0, _canli - 1)
	_oldurulen += 1
	hud.oldurme()
	kahraman.tecrube_ekle(d.xp)
	kahraman.ofke = minf(100.0, kahraman.ofke + (3.0 if not d.boss else 50.0))
	var p := d.global_position
	if d.boss:
		mesaj_goster("%s YENİLDİ!" % d.ad.to_upper(), Color(1, 0.6, 0.2), true)
		for i in 4:
			_ganimet("esya", p + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2)), 0, 3 if i == 0 else 2)
		altin_ver(6 * (20 + _seviye_esdeg * 4), p)
		kamera_sars(1.0)
		Efekt.kanat_tuyu_patlamasi(p)
		boss = null
		if mod == "zindan":
			_zindan_tamam(p)
		return
	var sev := d.xp / 12
	if d.elit:
		_ganimet("esya", p, 0, 1)
	elif randf() < 0.08:
		_ganimet("esya", p, 0, 0)
	if randf() < 0.5:
		altin_ver(3 + sev * 2 + randi() % 4, p)
	if randf() < 0.04:
		_ganimet("iksir", p, 0)


func _ganimet(tur: String, p: Vector3, miktar := 0, en_az := 0) -> void:
	if tur == "altin":
		altin_ver(miktar, p)
		return
	var yerdekiler := get_tree().get_nodes_in_group("ganimet")
	if yerdekiler.size() >= 15:
		var eski: Node = yerdekiler[0]
		if eski.tur == "esya":
			kahraman.esya_al(eski.esya)
		eski.queue_free()
	var g := Ganimet.new()
	g.tur = tur
	g.miktar = miktar
	g.kahraman = kahraman
	if tur == "esya":
		g.esya = Esya.uret(maxi(kahraman.seviye, _seviye_esdeg), en_az, sinif)
	var lim := sinir()
	p.x = clampf(p.x, -lim, lim)
	p.z = clampf(p.z, -lim, lim)
	g.position = p
	dunya.add_child(g)


func _kahraman_oldu() -> void:
	durum = "olum"
	Oyun.kayit_guncelle(dalga, kahraman.seviye)
	kahraman.altin = int(kahraman.altin * 0.9)
	kaydet()
	dokunmatik.visible = false
	Oyun.tum_girdileri_birak()
	get_tree().create_timer(1.6).timeout.connect(func():
		_olum_menu_guncelle()
		_olum_menu.visible = true)


func _koyde_diril() -> void:
	_olum_menu.visible = false
	_gecis_yap(func():
		if mod == "zindan":
			_zindandan_cik(true)
		else:
			for d in get_tree().get_nodes_in_group("dusman"):
				d.aggro = false
			kahraman.global_position = Bolge.DOGUS
			_kamera_hedef = kahraman.global_position
		kahraman.dirilt()
		durum = "oyun"
		hud.visible = true
		dokunmatik.visible = Oyun.dokunmatik_acik)


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

	# Ana menü: tek ekranda üç karakter kartı (seç ve oyna) + alt düğmeler
	_menu = _kutu("AnaMenu")
	var v: VBoxContainer = _menu.find_child("Liste", true, false)
	v.add_theme_constant_override("separation", 8)
	v.add_child(_baslik("KÜL VE KANAT", 58))
	v.add_child(_yazi_etiket("Kanatix  ·  1. Bölüm: Kül Ovaları  ·  Karakterine dokun ve oyna", 18, Color(0.85, 0.75, 0.6)))
	var kartlar := HBoxContainer.new()
	kartlar.add_theme_constant_override("separation", 16)
	kartlar.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(kartlar)
	for snf in Sinif.LISTE:
		kartlar.add_child(_sinif_karti(snf))
	var alt_sira := HBoxContainer.new()
	alt_sira.alignment = BoxContainer.ALIGNMENT_CENTER
	alt_sira.add_theme_constant_override("separation", 12)
	v.add_child(alt_sira)
	var kd := _kalite_dugmesi()
	kd.custom_minimum_size = Vector2(250, 54)
	alt_sira.add_child(kd)
	var kontrol := _dugme("KONTROLLER", func():
		var y: Label = _menu.find_child("Yardim", true, false)
		y.visible = not y.visible)
	kontrol.custom_minimum_size = Vector2(250, 54)
	alt_sira.add_child(kontrol)
	if not mobil:
		var cikis := _dugme("ÇIKIŞ", func(): get_tree().quit())
		cikis.custom_minimum_size = Vector2(200, 54)
		alt_sira.add_child(cikis)
	var yardim := _yazi_etiket("", 17, Color(0.9, 0.85, 0.75))
	yardim.name = "Yardim"
	yardim.visible = false
	if mobil:
		yardim.text = "Sol yarı: parmağını koyduğun yerden yürü  ·  Büyük düğme: basılı tut, saldır\nEtraftaki düğmeler: yetenekler  ·  Altın kanat: son vuruş  ·  Sağ üst: çanta, duraklat, harita"
	else:
		yardim.text = "W A S D: yürü  ·  Sol tık / J: saldır  ·  Sağ tık / 1, 2, Boşluk / 3, 4: yetenekler\nR: son vuruş  ·  Q: iksir  ·  I: envanter  ·  M: harita  ·  ESC: duraklat  ·  Oyun kolu da çalışır"
	v.add_child(yardim)
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

	kasaba = Kasaba.new()
	kasaba.theme = _tema
	kasaba.visible = false
	kasaba.kahraman = kahraman
	kasaba.kapandi.connect(func():
		get_tree().paused = false
		hud.visible = true
		dokunmatik.visible = Oyun.dokunmatik_acik and durum == "oyun"
		Oyun.tum_girdileri_birak()
		kaydet())
	_menu_katman.add_child(kasaba)
	_secim_kur()

	# Duraklatma: iki sütunlu düğmeler, telefon ekranına sığar
	_duraklat_menu = _kutu("Duraklat")
	v = _duraklat_menu.find_child("Liste", true, false)
	v.add_theme_constant_override("separation", 10)
	v.add_child(_baslik("DURAKLATILDI", 44))
	var esyalar := _yazi_etiket("", 16)
	esyalar.name = "Esyalar"
	v.add_child(esyalar)
	var izgara := GridContainer.new()
	izgara.columns = 2
	izgara.add_theme_constant_override("h_separation", 14)
	izgara.add_theme_constant_override("v_separation", 10)
	v.add_child(izgara)
	var dugmeler := [
		_dugme("DEVAM", _duraklat_ac_kapa),
		_dugme("ENVANTER", func():
			_duraklat_ac_kapa()
			_envanter_ac()),
		_dugme("KÖYE DÖN", func():
			_duraklat_ac_kapa()
			koye_don()),
		_kalite_dugmesi(),
		_dugme("KARAKTER DEĞİŞTİR", func(): _yeniden(false)),
		_dugme("ANA MENÜ", func(): _yeniden(false)),
	]
	for d in dugmeler:
		d.custom_minimum_size = Vector2(330, 60)
		izgara.add_child(d)

	# Ölüm
	_olum_menu = _kutu("Olum")
	v = _olum_menu.find_child("Liste", true, false)
	v.add_child(_baslik("KÜLE DÖNDÜN", 60, Color(1, 0.4, 0.2)))
	var ozet := _yazi_etiket("", 24)
	ozet.name = "Ozet"
	v.add_child(ozet)
	v.add_child(_dugme("KÖYDE DİRİL", _koyde_diril))
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
	mesaj_goster("Son Sığınak", Color(0.95, 0.8, 0.55), true)
	mesaj_goster("Esnaflarla konuş, sonra zindanlara git (harita: M / sağ üst)", Color(1, 0.85, 0.5))
	kaydet()


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
		var satirlar := ["%s  ·  Seviye %d  ·  %d altın  ·  Zindan: %d/%d  ·  FPS %d" % [Sinif.VERI[sinif]["ad"], kahraman.seviye, kahraman.altin, temizlenen.size(), Bolge.ZINDANLAR.size(), Engine.get_frames_per_second()],
			"Hasar %d  ·  Can %d  ·  Kritik %%%d  ·  Zırh %%%d  ·  Kaçınma %%%d" % [int(kahraman.deger("hasar")), int(kahraman.deger("can")), int(kahraman.deger("kritik")), int(kahraman.zirh_orani()), int(kahraman.deger("kacinma"))]]
		l.text = "\n".join(satirlar)


func _olum_menu_guncelle() -> void:
	var l: Label = _olum_menu.find_child("Ozet", true, false)
	l.text = "Seviye %d  ·  %d düşman  ·  %d altın\nSeviyen ve eşyaların korundu (altının %%10'u düştü). Köyde dirileceksin." % [kahraman.seviye, _oldurulen, kahraman.altin]


func _yeniden(hemen: bool) -> void:
	if durum == "oyun":
		kaydet()
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
			vp.scaling_3d_scale = 0.6 if mobil else 0.75
			Efekt.kalite = 0.5
			Efekt.sinir = 30
			Efekt.ek_isik = false
		1:
			_env.ssao_enabled = false
			_env.fog_enabled = true
			_ay.shadow_enabled = not mobil
			_ay.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
			vp.msaa_3d = Viewport.MSAA_2X if not mobil else Viewport.MSAA_DISABLED
			vp.scaling_3d_scale = 0.75 if mobil else 1.0
			Efekt.kalite = 0.8
			Efekt.sinir = 45 if mobil else 60
			Efekt.ek_isik = true
		2:
			_env.ssao_enabled = not mobil
			_env.fog_enabled = true
			_ay.shadow_enabled = true
			_ay.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
			vp.msaa_3d = Viewport.MSAA_4X if not mobil else Viewport.MSAA_DISABLED
			vp.scaling_3d_scale = 0.9 if mobil else 1.0
			Efekt.kalite = 1.0
			Efekt.sinir = 60 if mobil else 90
			Efekt.ek_isik = true



# ------------------------------------------------------------------ kayıt
func kaydet(_eski := -1) -> void:
	if kahraman == null:
		return
	var v := kahraman.kayit_verisi()
	v["temizlenen"] = temizlenen
	v["surum"] = Oyun.SURUM
	Oyun.karakter_kaydet(v)
	_kayit = v


func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		if durum == "oyun":
			kaydet()


static func _kontrol_noktasi(d: int) -> int:
	## Ölünce dönülen dalga: 1, 6, 11, 16...
	return maxi(1, d - (d - 1) % 5)



# ------------------------------------------------------------------ kasaba
func _kasaba_ac(esnaf := "") -> void:
	if durum != "oyun":
		return
	Oyun.tum_girdileri_birak()
	get_tree().paused = true
	dokunmatik.visible = false
	hud.visible = false
	kasaba.ac(esnaf)


# ------------------------------------------------------------------ karakter seçimi
func _secim_ac() -> void:
	_menu.visible = false
	_secim_menu.visible = true


func _secim_kur() -> void:
	_secim_menu = Control.new()
	_secim_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_secim_menu.theme = _tema
	_secim_menu.visible = false
	_menu_katman.add_child(_secim_menu)
	var arka := ColorRect.new()
	arka.color = Color(0.03, 0.02, 0.03, 0.9)
	arka.set_anchors_preset(Control.PRESET_FULL_RECT)
	_secim_menu.add_child(arka)
	var merkez := CenterContainer.new()
	merkez.set_anchors_preset(Control.PRESET_FULL_RECT)
	_secim_menu.add_child(merkez)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	merkez.add_child(v)
	v.add_child(_baslik("KARAKTERİNİ SEÇ", 46))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(h)
	for s in Sinif.LISTE:
		h.add_child(_sinif_karti(s))
	var geri := _dugme("GERİ", func():
		_secim_menu.visible = false
		_menu.visible = true)
	geri.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(geri)


func _sinif_karti(s: String) -> Control:
	var b: Dictionary = Sinif.VERI[s]
	var panel := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.05, 0.05, 0.96)
	st.border_color = b["kanat"]
	st.set_border_width_all(2)
	st.set_corner_radius_all(14)
	st.content_margin_left = 14
	st.content_margin_right = 14
	st.content_margin_top = 8
	st.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", st)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	panel.custom_minimum_size = Vector2(290, 0)
	var portre := Portre.yap(b["model"], b["bekleme_anim"], Vector2i(220, 170), b["sakla"], b["kanat"])
	portre.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(portre)
	var ad := _baslik(b["ad"], 26, b["kanat"].lightened(0.3))
	v.add_child(ad)
	v.add_child(_yazi_etiket(b["rol"], 18, Color(0.9, 0.85, 0.75)))
	var ac := _yazi_etiket(str(b["aciklama"]).replace("\n", " "), 14, Color(0.75, 0.7, 0.65))
	ac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ac.custom_minimum_size = Vector2(260, 0)
	v.add_child(ac)
	var puan := GridContainer.new()
	puan.columns = 2
	puan.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	puan.add_theme_constant_override("h_separation", 16)
	for i in 4:
		puan.add_child(_yazi_etiket("%s %s" % [["Güç", "Hız", "Büyü", "Savunma"][i], "●".repeat(b["puan"][i]) + "○".repeat(5 - b["puan"][i])], 14, Color(0.95, 0.8, 0.55)))
	v.add_child(puan)
	var k := Oyun.karakter_yukle(s)
	var bilgi := "Kayıt yok: yeni karakter" if k.is_empty() else "Kayıt: Seviye %d  ·  Zindan %d/%d" % [int(k.get("seviye", 1)), k.get("temizlenen", []).size(), Bolge.ZINDANLAR.size()]
	v.add_child(_yazi_etiket(bilgi, 17, Color(1, 0.85, 0.5) if not k.is_empty() else Color(0.7, 0.68, 0.62)))
	var oyna := _dugme("DEVAM ET" if not k.is_empty() else "OYNA", func():
		if s == sinif:
			_secim_menu.visible = false
			_basla()
			return
		Oyun.secili_sinif = s
		Oyun.dogrudan_basla = true
		get_tree().reload_current_scene())
	oyna.custom_minimum_size = Vector2(260, 56)
	v.add_child(oyna)
	if not k.is_empty():
		var sil := Button.new()
		sil.text = "SIFIRLA"
		sil.custom_minimum_size = Vector2(260, 38)
		sil.add_theme_font_size_override("font_size", 20)
		var onay := [false]
		sil.pressed.connect(func():
			if not onay[0]:
				onay[0] = true
				sil.text = "EMİN MİSİN? TEKRAR BAS"
				return
			Oyun.karakter_sil(s)
			Oyun.secili_sinif = s
			get_tree().reload_current_scene())
		v.add_child(sil)
	return panel


func ganimet_birak(tur: String, p: Vector3, miktar := 0, en_az := 0) -> void:
	_ganimet(tur, p, miktar, en_az)



func altin_ver(miktar: int, p: Vector3) -> void:
	## Altın yere düşmez, doğrudan kahramana geçer (telefonda yüzlerce yığın donma yapıyordu).
	kahraman.altin += miktar
	Efekt.hasar_yazisi(p + Vector3(0, 1.6, 0), "+%d" % miktar, Efekt.ALTIN)
	Ses.cal("altin", -10.0)
