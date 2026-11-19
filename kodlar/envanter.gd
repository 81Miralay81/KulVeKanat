class_name Envanter
extends Control
## Envanter: takılı eşyalar + çanta, gerçekçi eşya resimleri. Üzerine gelince (telefonda dokununca)
## ayrıntı kutusu. Düğmeler: TAK / ÇIKAR, + BAS (Eliksir), MANA TAŞI TAK, SAT.

signal kapandi

var kahraman: Kahraman
var _secili_canta := -1
var _secili_yuva := ""
var _yuva_kutulari := {}
var _canta_izgara: GridContainer
var _ayrinti: RichTextLabel
var _ozellikler: Label
var _ust_bilgi: Label
var _dugme_tak: Button
var _dugme_bas: Button
var _dugme_tas: Button
var _dugme_sat: Button
var _ipucu: PanelContainer
var _ipucu_yazi: RichTextLabel
var _tas_panel: PanelContainer
var _tas_liste: VBoxContainer
var _sonuc: Label
var _yuva_ikon := {}
var _f_normal: Font
var _f_kalin: Font

const KUTU := 74.0
const YUVA_DOSYA := {"Silah": "silah", "Zırh": "zirh", "Kask": "kask", "Eldiven": "eldiven", "Çizme": "cizme", "Yüzük": "yuzuk", "Kanat": "kanat"}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_viewport().size_changed.connect(func(): size = get_viewport_rect().size)
	_f_normal = load("res://assets/font/Rajdhani-SemiBold.ttf")
	_f_kalin = load("res://assets/font/Rajdhani-Bold.ttf")
	for y in YUVA_DOSYA:
		var yol := "res://assets/ikon/yuva_%s.png" % YUVA_DOSYA[y]
		_yuva_ikon[y] = load(yol) if ResourceLoader.exists(yol) else null
	var arka := ColorRect.new()
	arka.color = Color(0.03, 0.02, 0.03, 0.96)
	arka.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(arka)

	var kenar := MarginContainer.new()
	kenar.set_anchors_preset(Control.PRESET_FULL_RECT)
	for k in ["left", "right", "top", "bottom"]:
		kenar.add_theme_constant_override("margin_" + k, 24 if k in ["left", "right"] else 12)
	add_child(kenar)
	var dikey := VBoxContainer.new()
	dikey.add_theme_constant_override("separation", 8)
	kenar.add_child(dikey)

	var ust := HBoxContainer.new()
	dikey.add_child(ust)
	var baslik := Label.new()
	baslik.text = "ENVANTER"
	baslik.add_theme_font_override("font", load("res://assets/font/Cinzel-Black.ttf"))
	baslik.add_theme_font_size_override("font_size", 36)
	baslik.add_theme_color_override("font_color", Color(1, 0.75, 0.4))
	ust.add_child(baslik)
	_ust_bilgi = _etiket("", 22, Color(1, 0.88, 0.5))
	_ust_bilgi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ust_bilgi.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ust_bilgi.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ust.add_child(_ust_bilgi)
	var kapat := Button.new()
	kapat.text = "KAPAT"
	kapat.custom_minimum_size = Vector2(150, 54)
	kapat.pressed.connect(kapat_)
	ust.add_child(kapat)

	var govde := HBoxContainer.new()
	govde.size_flags_vertical = Control.SIZE_EXPAND_FILL
	govde.add_theme_constant_override("separation", 18)
	dikey.add_child(govde)

	# Sol: takılı eşyalar (iki sütun resimli kutular) + özellikler
	var sol := VBoxContainer.new()
	sol.add_theme_constant_override("separation", 6)
	govde.add_child(sol)
	sol.add_child(_etiket("KUŞANILANLAR", 20, Color(0.95, 0.8, 0.55)))
	var yuva_izgara := GridContainer.new()
	yuva_izgara.columns = 2
	yuva_izgara.add_theme_constant_override("h_separation", 8)
	yuva_izgara.add_theme_constant_override("v_separation", 8)
	sol.add_child(yuva_izgara)
	for y in Esya.YUVALAR:
		var k := _kutu_yap(func(): _yuva_sec(y), func(): _ipucu_goster_yuva(y))
		yuva_izgara.add_child(k)
		_yuva_kutulari[y] = k
	_ozellikler = _etiket("", 17, Color(0.9, 0.86, 0.78))
	sol.add_child(_ozellikler)

	# Orta: çanta ızgarası
	var orta := VBoxContainer.new()
	orta.add_theme_constant_override("separation", 6)
	govde.add_child(orta)
	orta.add_child(_etiket("ÇANTA", 20, Color(0.95, 0.8, 0.55)))
	_canta_izgara = GridContainer.new()
	_canta_izgara.columns = 6
	_canta_izgara.add_theme_constant_override("h_separation", 6)
	_canta_izgara.add_theme_constant_override("v_separation", 6)
	orta.add_child(_canta_izgara)
	for i in Kahraman.CANTA_MAX:
		var idx := i
		_canta_izgara.add_child(_kutu_yap(func(): _canta_sec(idx), func(): _ipucu_goster_canta(idx)))

	# Sağ: ayrıntı + düğmeler
	var sag := VBoxContainer.new()
	sag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sag.add_theme_constant_override("separation", 8)
	govde.add_child(sag)
	var kaydir := ScrollContainer.new()
	kaydir.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kaydir.custom_minimum_size = Vector2(300, 200)
	kaydir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sag.add_child(kaydir)
	_ayrinti = _zengin(18)
	_ayrinti.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kaydir.add_child(_ayrinti)
	_sonuc = _etiket("", 20, Color(1, 0.85, 0.4))
	_sonuc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sag.add_child(_sonuc)
	var d1 := HBoxContainer.new()
	d1.add_theme_constant_override("separation", 8)
	sag.add_child(d1)
	_dugme_tak = _dugme("TAK", _tak_cikar)
	_dugme_bas = _dugme("+ BAS", _arti_bas)
	d1.add_child(_dugme_tak)
	d1.add_child(_dugme_bas)
	var d2 := HBoxContainer.new()
	d2.add_theme_constant_override("separation", 8)
	sag.add_child(d2)
	_dugme_tas = _dugme("MANA TAŞI", _tas_paneli_ac)
	_dugme_sat = _dugme("SAT", _sat)
	d2.add_child(_dugme_tas)
	d2.add_child(_dugme_sat)
	sag.add_child(_dugme("SIRADANLARI SAT", _siradanlari_sat))

	# Fare üstündeyken çıkan ayrıntı kutusu (masaüstü)
	_ipucu = PanelContainer.new()
	_ipucu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ipucu.visible = false
	_ipucu.add_theme_stylebox_override("panel", _stil(Color(0.06, 0.045, 0.04, 0.97), Color(0.85, 0.65, 0.35), 2))
	_ipucu_yazi = _zengin(17)
	_ipucu_yazi.custom_minimum_size = Vector2(360, 0)
	_ipucu_yazi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ipucu.add_child(_ipucu_yazi)
	add_child(_ipucu)

	# Mana taşı seçme paneli
	_tas_panel = PanelContainer.new()
	_tas_panel.visible = false
	_tas_panel.add_theme_stylebox_override("panel", _stil(Color(0.05, 0.05, 0.09, 0.98), Color(0.4, 0.65, 1.0), 2))
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 6)
	_tas_panel.add_child(tv)
	tv.add_child(_etiket("MANA TAŞI TAK (yuvaya takılan taş geri çıkmaz)", 20, Color(0.6, 0.8, 1.0)))
	var tk := ScrollContainer.new()
	tk.custom_minimum_size = Vector2(520, 330)
	tv.add_child(tk)
	_tas_liste = VBoxContainer.new()
	_tas_liste.add_theme_constant_override("separation", 6)
	tk.add_child(_tas_liste)
	tv.add_child(_dugme("VAZGEÇ", func(): _tas_panel.visible = false))
	add_child(_tas_panel)


func _zengin(boy: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.add_theme_font_size_override("normal_font_size", boy)
	r.add_theme_font_size_override("bold_font_size", boy + 4)
	r.add_theme_font_override("normal_font", _f_normal)
	r.add_theme_font_override("bold_font", _f_kalin)
	return r


func _stil(arka: Color, kenar: Color, kalinlik: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = arka
	s.border_color = kenar
	s.set_border_width_all(kalinlik)
	s.set_corner_radius_all(8)
	s.set_content_margin_all(12)
	return s


## Resimli eşya kutusu: arka çerçeve (nadirlik rengi), resim, artı yazısı, taş noktaları
func _kutu_yap(tik: Callable, ustunde: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(KUTU, KUTU)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func():
		Ses.cal("dugme", -6.0, 0.0)
		tik.call())
	b.mouse_entered.connect(func():
		if not Oyun.dokunmatik_acik:
			ustunde.call())
	b.mouse_exited.connect(func(): _ipucu.visible = false)
	var r := TextureRect.new()
	r.name = "Resim"
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.offset_left = 5
	r.offset_top = 5
	r.offset_right = -5
	r.offset_bottom = -5
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(r)
	var a := Label.new()
	a.name = "Arti"
	a.add_theme_font_override("font", _f_kalin)
	a.add_theme_font_size_override("font_size", 20)
	a.add_theme_color_override("font_color", Color(1, 0.88, 0.45))
	a.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	a.add_theme_constant_override("outline_size", 6)
	a.position = Vector2(5, 0)
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(a)
	var t := Label.new()
	t.name = "Tas"
	t.add_theme_font_size_override("font_size", 13)
	t.add_theme_color_override("font_color", Color(0.5, 0.75, 1.0))
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	t.add_theme_constant_override("outline_size", 4)
	t.position = Vector2(5, KUTU - 22)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(t)
	return b


func _kutu_doldur(b: Button, e: Dictionary, secili: bool, bos_ikon: Texture2D) -> void:
	var renk := Esya.renk(e) if not e.is_empty() else Color(0.35, 0.33, 0.3)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(renk.r * 0.18 + 0.04, renk.g * 0.18 + 0.03, renk.b * 0.18 + 0.03, 0.97)
	st.border_color = Color(1, 1, 1) if secili else renk
	st.set_border_width_all(4 if secili else 2)
	st.set_corner_radius_all(8)
	for k in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(k, st)
	var r: TextureRect = b.get_node("Resim")
	var a: Label = b.get_node("Arti")
	var t: Label = b.get_node("Tas")
	if e.is_empty():
		r.texture = bos_ikon
		r.modulate = Color(1, 1, 1, 0.25)
		a.text = ""
		t.text = ""
		return
	var ik := Esya.ikon(e)
	r.texture = ik if ik else bos_ikon
	r.modulate = Color(1, 1, 1) if kahraman.takabilir_mi(e) else Color(1, 0.55, 0.55)
	var arti := int(e.get("arti", 0))
	a.text = "+%d" % arti if arti > 0 else ""
	var dolu: int = e.get("taslar", []).size()
	t.text = "◆".repeat(dolu) + "◇".repeat(maxi(0, int(e.get("yuva_sayisi", 1)) - dolu))


func _etiket(metin: String, boy: int, renk: Color) -> Label:
	var l := Label.new()
	l.text = metin
	l.add_theme_font_size_override("font_size", boy)
	l.add_theme_color_override("font_color", renk)
	return l


func _dugme(metin: String, cagri: Callable) -> Button:
	var b := Button.new()
	b.text = metin
	b.custom_minimum_size = Vector2(170, 54)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(func():
		Ses.cal("dugme", -4.0, 0.0)
		cagri.call())
	return b


func ac() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	_secili_canta = -1
	_secili_yuva = ""
	_sonuc.text = ""
	_tas_panel.visible = false
	visible = true
	yenile()


func kapat_() -> void:
	visible = false
	_ipucu.visible = false
	kapandi.emit()


func _unhandled_input(e: InputEvent) -> void:
	if visible and (e.is_action_pressed("duraklat") or e.is_action_pressed("envanter")):
		if _tas_panel.visible:
			_tas_panel.visible = false
		else:
			kapat_()
		get_viewport().set_input_as_handled()


func _process(_dt: float) -> void:
	if visible and _ipucu.visible:
		var m := get_viewport().get_mouse_position()
		var b := size
		var p := m + Vector2(22, 18)
		if p.x + _ipucu.size.x > b.x:
			p.x = m.x - _ipucu.size.x - 16
		if p.y + _ipucu.size.y > b.y:
			p.y = b.y - _ipucu.size.y - 8
		_ipucu.position = p


func _secili() -> Dictionary:
	if _secili_canta >= 0 and _secili_canta < kahraman.canta.size():
		return kahraman.canta[_secili_canta]
	if _secili_yuva != "" and kahraman.esyalar.has(_secili_yuva):
		return kahraman.esyalar[_secili_yuva]
	return {}


func yenile() -> void:
	for y in Esya.YUVALAR:
		_kutu_doldur(_yuva_kutulari[y], kahraman.esyalar.get(y, {}), _secili_yuva == y, _yuva_ikon.get(y))
	for i in Kahraman.CANTA_MAX:
		var e: Dictionary = kahraman.canta[i] if i < kahraman.canta.size() else {}
		_kutu_doldur(_canta_izgara.get_child(i), e, _secili_canta == i, null)
	var tas_toplam := 0
	for k in kahraman.taslar:
		tas_toplam += int(kahraman.taslar[k])
	_ust_bilgi.text = "%d altın   ·   %d Eliksir   ·   %d mana taşı   " % [kahraman.altin, kahraman.eliksir, tas_toplam]
	_ozellikler.text = "Seviye %d   (%d/%d tecrübe)\nHasar %d  ·  Can %d\nKritik %%%d  ·  Hız %%%d\nZırh %%%d  ·  Kaçınma %%%d\nÇanta %d/%d" % [
		kahraman.seviye, kahraman.tecrube, kahraman.gereken_tecrube(), int(kahraman.deger("hasar")), int(kahraman.deger("can")),
		int(kahraman.deger("kritik")), int(kahraman.deger("hiz")), int(kahraman.zirh_orani()), int(kahraman.deger("kacinma")),
		kahraman.canta.size(), Kahraman.CANTA_MAX]
	_ayrinti_yaz()


func _ayrinti_yaz() -> void:
	var e := _secili()
	var var_mi := not e.is_empty()
	_dugme_tak.disabled = not var_mi
	_dugme_bas.disabled = not var_mi or int(e.get("arti", 0)) >= Esya.ARTI_MAX
	_dugme_tas.disabled = not var_mi or e.get("taslar", []).size() >= int(e.get("yuva_sayisi", 1))
	_dugme_sat.disabled = _secili_canta < 0
	if not var_mi:
		_ayrinti.text = "[color=#aaaaaa]Bir eşyaya dokun: özellikleri, mana taşları ve set bonusu burada görünür.\n\n[b]+ BAS[/b]: Eliksir ve altınla eşyayı güçlendirir. +10'dan sonra başarısız olursa eşya yanar ve +0'a düşer.\n\n[b]MANA TAŞI[/b]: Düşmanlardan düşen taşları eşyanın boş yuvalarına tak.[/color]"
		_dugme_tak.text = "TAK"
		return
	if _secili_canta >= 0:
		_dugme_tak.text = "TAK"
		_ayrinti.text = Esya.ayrinti(e, kahraman, kahraman.esyalar.get(e["yuva"], {}))
	else:
		_dugme_tak.text = "ÇIKAR"
		_ayrinti.text = Esya.ayrinti(e, kahraman)
	if int(e.get("arti", 0)) < Esya.ARTI_MAX:
		_dugme_bas.text = "+%d BAS (%d Eliksir)" % [int(e.get("arti", 0)) + 1, Esya.eliksir_gereken(int(e.get("arti", 0)))]
	else:
		_dugme_bas.text = "EN YÜKSEK"


func _ipucu_goster_canta(i: int) -> void:
	if i >= kahraman.canta.size():
		_ipucu.visible = false
		return
	var e: Dictionary = kahraman.canta[i]
	_ipucu_yazi.text = Esya.ayrinti(e, kahraman, kahraman.esyalar.get(e["yuva"], {}))
	_ipucu.reset_size()
	_ipucu.visible = true


func _ipucu_goster_yuva(y: String) -> void:
	if not kahraman.esyalar.has(y):
		_ipucu.visible = false
		return
	_ipucu_yazi.text = Esya.ayrinti(kahraman.esyalar[y], kahraman)
	_ipucu.reset_size()
	_ipucu.visible = true


func _canta_sec(i: int) -> void:
	if i >= kahraman.canta.size():
		return
	_secili_canta = i
	_secili_yuva = ""
	_sonuc.text = ""
	yenile()


func _yuva_sec(y: String) -> void:
	if not kahraman.esyalar.has(y):
		return
	_secili_yuva = y
	_secili_canta = -1
	_sonuc.text = ""
	yenile()


func _tak_cikar() -> void:
	if _secili_canta >= 0:
		var e: Dictionary = kahraman.canta[_secili_canta]
		if not kahraman.takabilir_mi(e):
			_sonuc.text = "Bu eşya için seviye %d gerekli." % int(e.get("gereken", 1)) if kahraman.seviye < int(e.get("gereken", 1)) else "Bu eşya başka bir sınıfa ait."
			Ses.cal("dugme", -2.0, 0.0)
			return
		var y: String = e["yuva"]
		kahraman.tak(_secili_canta)
		_secili_canta = -1
		_secili_yuva = y
	elif _secili_yuva != "":
		if kahraman.cikar(_secili_yuva):
			_secili_yuva = ""
			_secili_canta = kahraman.canta.size() - 1
		else:
			_sonuc.text = "Çanta dolu."
	yenile()


func _arti_bas() -> void:
	var e := _secili()
	if e.is_empty():
		return
	var once := int(e.get("arti", 0))
	var sonuc := kahraman.arti_bas(e)
	match sonuc:
		"basari":
			_sonuc.text = "BAŞARILI! %s artık +%d" % [e["ad"], int(e["arti"])]
			_sonuc.add_theme_color_override("font_color", Color(0.45, 1.0, 0.5))
			Ses.cal("seviye", -6.0)
		"basarisiz":
			_sonuc.text = "Başarısız. Eliksir ve altın gitti, eşya +%d olarak kaldı." % once
			_sonuc.add_theme_color_override("font_color", Color(1, 0.7, 0.35))
			Ses.cal("olum", -8.0)
		"yandi":
			_sonuc.text = "EŞYA YANDI! +%d idi, şimdi +0." % once
			_sonuc.add_theme_color_override("font_color", Color(1, 0.3, 0.2))
			Ses.cal("patlama", -6.0)
		"eliksir":
			_sonuc.text = "Yeterli Eliksir yok (%d gerekli). Eliksir düşmanlardan düşer, görevlerden kazanılır." % Esya.eliksir_gereken(once)
			_sonuc.add_theme_color_override("font_color", Color(1, 0.6, 0.4))
		"altin":
			_sonuc.text = "Yeterli altın yok (%d gerekli)." % Esya.altin_gereken(e)
			_sonuc.add_theme_color_override("font_color", Color(1, 0.6, 0.4))
		"max":
			_sonuc.text = "Bu eşya zaten en yüksek seviyede."
	yenile()


func _tas_paneli_ac() -> void:
	var e := _secili()
	if e.is_empty():
		return
	for c in _tas_liste.get_children():
		c.queue_free()
	var anahtarlar := kahraman.taslar.keys()
	anahtarlar.sort()
	if anahtarlar.is_empty():
		_tas_liste.add_child(_etiket("Hiç mana taşın yok. Düşmanlardan ve boss'lardan düşer.", 19, Color(0.8, 0.8, 0.8)))
	for k in anahtarlar:
		var t := Esya.tas_coz(k)
		var b := Button.new()
		b.text = "  %s  ×%d   (%s)" % [Esya.tas_adi(t), int(kahraman.taslar[k]), Esya.tas_metni(t)]
		b.icon = Esya.tas_ikon(t)
		b.expand_icon = false
		b.add_theme_constant_override("icon_max_width", 40)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(500, 54)
		var anahtar: String = k
		b.pressed.connect(func():
			if kahraman.tas_tak(e, anahtar):
				_sonuc.text = "%s takıldı." % Esya.tas_adi(Esya.tas_coz(anahtar))
				_sonuc.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
				Ses.cal("esya", -6.0)
			_tas_panel.visible = false
			yenile())
		_tas_liste.add_child(b)
	_tas_panel.reset_size()
	_tas_panel.position = (size - _tas_panel.size) * 0.5
	_tas_panel.visible = true


func _sat() -> void:
	if _secili_canta >= 0 and _secili_canta < kahraman.canta.size():
		var fiyat := kahraman.satis_fiyati(kahraman.canta[_secili_canta])
		kahraman.sat(_secili_canta)
		_sonuc.text = "+%d altın" % fiyat
		_sonuc.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
		Ses.cal("altin", -4.0)
		_secili_canta = -1
		yenile()


func _siradanlari_sat() -> void:
	var toplam := 0
	var i := kahraman.canta.size() - 1
	while i >= 0:
		var e: Dictionary = kahraman.canta[i]
		if int(e["nadirlik"]) == 0 and int(e.get("arti", 0)) == 0 and e.get("taslar", []).is_empty():
			toplam += kahraman.satis_fiyati(e)
			kahraman.sat(i)
		i -= 1
	_secili_canta = -1
	_sonuc.text = "Sıradan eşyalar satıldı: +%d altın" % toplam if toplam > 0 else "Satılacak sıradan eşya yok."
	_sonuc.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	yenile()
