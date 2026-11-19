class_name Envanter
extends Control
## Envanter: takılı eşyalar + çanta. Eşyaya dokun/tıkla -> ayrıntı, karşılaştırma, TAK / ÇIKAR / SAT.

signal kapandi

var kahraman: Kahraman
var _secili_canta := -1
var _secili_yuva := ""
var _yuva_kutulari := {}
var _canta_izgara: GridContainer
var _ayrinti: RichTextLabel
var _ozellikler: Label
var _altin: Label
var _dugme_tak: Button
var _dugme_sat: Button
var _dugme_cikar: Button
var _ikonlar := {}

const YUVA_DOSYA := {"Silah": "silah", "Zırh": "zirh", "Kask": "kask", "Yüzük": "yuzuk", "Kanat": "kanat"}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_viewport().size_changed.connect(func(): size = get_viewport_rect().size)
	for y in YUVA_DOSYA:
		_ikonlar[y] = load("res://assets/ikon/yuva_%s.png" % YUVA_DOSYA[y])
	var arka := ColorRect.new()
	arka.color = Color(0.03, 0.02, 0.03, 0.95)
	arka.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(arka)

	var kenar := MarginContainer.new()
	kenar.set_anchors_preset(Control.PRESET_FULL_RECT)
	for k in ["left", "right", "top", "bottom"]:
		kenar.add_theme_constant_override("margin_" + k, 28 if k in ["left", "right"] else 18)
	add_child(kenar)
	var dikey := VBoxContainer.new()
	dikey.add_theme_constant_override("separation", 10)
	kenar.add_child(dikey)

	var ust := HBoxContainer.new()
	dikey.add_child(ust)
	var baslik := Label.new()
	baslik.text = "ENVANTER"
	baslik.add_theme_font_override("font", load("res://assets/font/Cinzel-Black.ttf"))
	baslik.add_theme_font_size_override("font_size", 40)
	baslik.add_theme_color_override("font_color", Color(1, 0.75, 0.4))
	ust.add_child(baslik)
	var bosluk := Control.new()
	bosluk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ust.add_child(bosluk)
	_altin = Label.new()
	_altin.add_theme_font_size_override("font_size", 26)
	_altin.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	ust.add_child(_altin)
	var kapat := Button.new()
	kapat.text = "KAPAT"
	kapat.custom_minimum_size = Vector2(170, 56)
	kapat.pressed.connect(kapat_)
	ust.add_child(kapat)

	var govde := HBoxContainer.new()
	govde.size_flags_vertical = Control.SIZE_EXPAND_FILL
	govde.add_theme_constant_override("separation", 22)
	dikey.add_child(govde)

	# Sol: takılı eşyalar + karakter özellikleri
	var sol := VBoxContainer.new()
	sol.custom_minimum_size = Vector2(330, 0)
	sol.add_theme_constant_override("separation", 8)
	govde.add_child(sol)
	sol.add_child(_etiket("KUŞANILANLAR", 22, Color(0.95, 0.8, 0.55)))
	for y in Esya.YUVALAR:
		var b := Button.new()
		b.custom_minimum_size = Vector2(330, 62)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.icon = _ikonlar[y]
		b.expand_icon = false
		b.add_theme_constant_override("icon_max_width", 44)
		b.clip_text = true
		b.pressed.connect(func(): _yuva_sec(y))
		sol.add_child(b)
		_yuva_kutulari[y] = b
	_ozellikler = _etiket("", 19, Color(0.9, 0.86, 0.78))
	_ozellikler.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	sol.add_child(_ozellikler)

	# Orta: çanta ızgarası
	var orta := VBoxContainer.new()
	orta.add_theme_constant_override("separation", 8)
	govde.add_child(orta)
	orta.add_child(_etiket("ÇANTA", 22, Color(0.95, 0.8, 0.55)))
	_canta_izgara = GridContainer.new()
	_canta_izgara.columns = 6
	_canta_izgara.add_theme_constant_override("h_separation", 8)
	_canta_izgara.add_theme_constant_override("v_separation", 8)
	orta.add_child(_canta_izgara)

	# Sağ: ayrıntı + düğmeler
	var sag := VBoxContainer.new()
	sag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sag.add_theme_constant_override("separation", 10)
	govde.add_child(sag)
	_ayrinti = RichTextLabel.new()
	_ayrinti.bbcode_enabled = true
	_ayrinti.fit_content = true
	_ayrinti.custom_minimum_size = Vector2(300, 260)
	_ayrinti.add_theme_font_size_override("normal_font_size", 20)
	_ayrinti.add_theme_font_size_override("bold_font_size", 26)
	_ayrinti.add_theme_font_override("normal_font", load("res://assets/font/Rajdhani-SemiBold.ttf"))
	_ayrinti.add_theme_font_override("bold_font", load("res://assets/font/Rajdhani-Bold.ttf"))
	sag.add_child(_ayrinti)
	var dugmeler := HBoxContainer.new()
	dugmeler.add_theme_constant_override("separation", 10)
	sag.add_child(dugmeler)
	_dugme_tak = _dugme("TAK", _tak)
	_dugme_cikar = _dugme("ÇIKAR", _cikar)
	_dugme_sat = _dugme("SAT", _sat)
	for d in [_dugme_tak, _dugme_cikar, _dugme_sat]:
		dugmeler.add_child(d)
	sag.add_child(_dugme("ÇÖPLERİ SAT (Sıradan)", _siradanlari_sat))


func _etiket(metin: String, boy: int, renk: Color) -> Label:
	var l := Label.new()
	l.text = metin
	l.add_theme_font_size_override("font_size", boy)
	l.add_theme_color_override("font_color", renk)
	return l


func _dugme(metin: String, cagri: Callable) -> Button:
	var b := Button.new()
	b.text = metin
	b.custom_minimum_size = Vector2(150, 58)
	b.pressed.connect(func():
		Ses.cal("dugme", -4.0, 0.0)
		cagri.call())
	return b


func ac() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	_secili_canta = -1
	_secili_yuva = ""
	visible = true
	yenile()


func kapat_() -> void:
	visible = false
	kapandi.emit()


func _unhandled_input(e: InputEvent) -> void:
	if visible and (e.is_action_pressed("duraklat") or e.is_action_pressed("envanter")):
		kapat_()
		get_viewport().set_input_as_handled()


func _kutu_stili(renk: Color, secili: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(renk.r * 0.22, renk.g * 0.22, renk.b * 0.22, 0.95)
	s.border_color = Color(1, 1, 1) if secili else renk
	s.set_border_width_all(4 if secili else 2)
	s.set_corner_radius_all(8)
	s.content_margin_left = 8
	s.content_margin_right = 8
	return s


func yenile() -> void:
	if kahraman == null:
		return
	_altin.text = "%d altın   " % kahraman.altin
	for y in Esya.YUVALAR:
		var b: Button = _yuva_kutulari[y]
		var e: Dictionary = kahraman.esyalar.get(y, {})
		var renk := Esya.renk(e) if not e.is_empty() else Color(0.4, 0.38, 0.36)
		b.text = ("  " + e["ad"]) if not e.is_empty() else "  %s: boş" % y
		b.add_theme_color_override("font_color", renk.lightened(0.15))
		b.add_theme_color_override("icon_normal_color", renk)
		var st := _kutu_stili(renk, _secili_yuva == y)
		for durum in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(durum, st)
	for c in _canta_izgara.get_children():
		c.queue_free()
	for i in Kahraman.CANTA_MAX:
		var b := Button.new()
		b.custom_minimum_size = Vector2(76, 76)
		b.expand_icon = true
		if i < kahraman.canta.size():
			var e: Dictionary = kahraman.canta[i]
			var renk := Esya.renk(e)
			b.icon = _ikonlar[e["yuva"]]
			b.add_theme_color_override("icon_normal_color", renk)
			b.add_theme_color_override("icon_hover_color", renk.lightened(0.3))
			b.add_theme_color_override("icon_pressed_color", renk)
			b.add_theme_color_override("icon_focus_color", renk)
			var st := _kutu_stili(renk, _secili_canta == i)
			for durum in ["normal", "hover", "pressed", "focus"]:
				b.add_theme_stylebox_override(durum, st)
			var idx := i
			b.pressed.connect(func(): _canta_sec(idx))
			if Esya.puan(e) > Esya.puan(kahraman.esyalar.get(e["yuva"], {})):
				var ok := Label.new()   # takılı olandan iyiyse yeşil ok
				ok.text = "▲"
				ok.add_theme_color_override("font_color", Color(0.3, 1, 0.4))
				ok.add_theme_font_size_override("font_size", 20)
				ok.position = Vector2(54, 2)
				b.add_child(ok)
		else:
			b.disabled = true
			var st := _kutu_stili(Color(0.3, 0.28, 0.26), false)
			b.add_theme_stylebox_override("disabled", st)
		_canta_izgara.add_child(b)
	_ozellikler.text = "\nSeviye %d\nHasar: %d\nCan: %d\nMana: %d\nKritik: %%%.1f\nHız: +%%%.1f\nZırh: %%%.1f\nKaçınma: %%%.1f\nÇanta: %d / %d" % [
		kahraman.seviye, int(kahraman.deger("hasar")), int(kahraman.deger("can")), int(kahraman.deger("mana")),
		kahraman.deger("kritik"), kahraman.deger("hiz"), kahraman.zirh_orani(), kahraman.deger("kacinma"), kahraman.canta.size(), Kahraman.CANTA_MAX]
	_ayrinti_yaz()


func _esya_metni(e: Dictionary, karsi: Dictionary) -> String:
	var r := Esya.renk(e).to_html(false)
	var t := "[b][color=#%s]%s[/color][/b]\n[color=#bbbbbb]%s · %s · Seviye %d[/color]\n\n" % [r, e["ad"], Esya.NADIRLIK[e["nadirlik"]]["ad"], e["yuva"], e["seviye"]]
	var anahtarlar: Array = e["ozellik"].keys()
	for k in karsi.get("ozellik", {}):
		if not k in anahtarlar:
			anahtarlar.append(k)
	for k in anahtarlar:
		var v: float = float(e["ozellik"].get(k, 0.0))
		var w: float = float(karsi.get("ozellik", {}).get(k, 0.0))
		var satir := "+%s %s" % [str(v), Esya.OZELLIKLER[k][0]] if v != 0 else "[color=#888888](%s yok)[/color]" % Esya.OZELLIKLER[k][0]
		if not karsi.is_empty() and absf(v - w) > 0.01:
			var renk := "#55ff66" if v > w else "#ff5544"
			satir += "   [color=%s](%s%s)[/color]" % [renk, "+" if v > w else "", str(snappedf(v - w, 0.1))]
		t += satir + "\n"
	return t


func _ayrinti_yaz() -> void:
	_dugme_tak.visible = false
	_dugme_cikar.visible = false
	_dugme_sat.visible = false
	if _secili_canta >= 0 and _secili_canta < kahraman.canta.size():
		var e: Dictionary = kahraman.canta[_secili_canta]
		var takili: Dictionary = kahraman.esyalar.get(e["yuva"], {})
		var t := _esya_metni(e, takili)
		if not takili.is_empty():
			t += "\n[color=#999999]Takılı olanla karşılaştırma (yeşil daha iyi):[/color]\n[color=#cccccc]%s[/color]" % takili["ad"]
		_ayrinti.text = t
		_dugme_tak.visible = true
		_dugme_sat.visible = true
		_dugme_sat.text = "SAT (%d)" % kahraman.satis_fiyati(e)
	elif _secili_yuva != "" and kahraman.esyalar.has(_secili_yuva):
		_ayrinti.text = _esya_metni(kahraman.esyalar[_secili_yuva], {})
		_dugme_cikar.visible = true
	else:
		_ayrinti.text = "[color=#bbbbbb]Bir eşyaya dokun ya da tıkla.\n\nYeşil ▲ işareti: takılı olandan daha iyi.\n\nEşyalar düşmanlardan düşer; üstünden geçince çantaya girer.[/color]"


func _canta_sec(i: int) -> void:
	_secili_canta = i
	_secili_yuva = ""
	Ses.cal("dugme", -6.0, 0.0)
	yenile()


func _yuva_sec(y: String) -> void:
	_secili_yuva = y
	_secili_canta = -1
	yenile()


func _tak() -> void:
	if _secili_canta >= 0:
		kahraman.tak(_secili_canta)
		_secili_canta = -1
		yenile()


func _cikar() -> void:
	if _secili_yuva != "":
		if not kahraman.cikar(_secili_yuva):
			_ayrinti.text = "[color=#ff8866]Çanta dolu, önce bir şey sat.[/color]"
			return
		_secili_yuva = ""
		yenile()


func _sat() -> void:
	if _secili_canta >= 0:
		kahraman.sat(_secili_canta)
		Ses.cal("altin", -4.0)
		_secili_canta = -1
		yenile()


func _siradanlari_sat() -> void:
	var i := kahraman.canta.size() - 1
	var sayi := 0
	while i >= 0:
		if kahraman.canta[i]["nadirlik"] == 0:
			kahraman.sat(i)
			sayi += 1
		i -= 1
	if sayi > 0:
		Ses.cal("altin", -4.0)
	_secili_canta = -1
	yenile()
