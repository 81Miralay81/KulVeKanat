class_name Kasaba
extends Control
## Son Sığınak: kasabadaki üç esnaf. Toplanan altın burada harcanır.
##  - Demirci Haldun: takılı eşyayı +1..+10 yükseltir
##  - Simyacı Nevra: iksir ve Kanat Tüyü satar
##  - Tüccar Kerem: gizemli eşya sandıkları satar

signal kapandi

var kahraman: Kahraman
var _altin: Label
var _mesaj: Label
var _demirci_liste: VBoxContainer
var _simyaci_liste: VBoxContainer
var _tuccar_liste: VBoxContainer
var _baslik_font: Font
var _paneller := {}

const SOZLER := {
	"demirci": ["\"Kor Kral'ın demirini bile döverim. Getir şu kılıcı.\"", "\"Bir vuruş daha... işte, artık daha keskin.\""],
	"simyaci": ["\"Kül Ovaları'nda iksirsiz gezen geri dönmez.\"", "\"Tüyler mi? Kanatlıların son hatırası...\""],
	"tuccar": ["\"Sandığın içinde ne var? Açınca görürsün!\"", "\"Şans cesurlardan yanadır, Kanatlı.\""],
}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_viewport().size_changed.connect(func(): size = get_viewport_rect().size)
	_baslik_font = load("res://assets/font/Cinzel-Black.ttf")
	var arka := ColorRect.new()
	arka.color = Color(0.05, 0.03, 0.03, 0.97)
	arka.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(arka)
	var kenar := MarginContainer.new()
	kenar.set_anchors_preset(Control.PRESET_FULL_RECT)
	for k in ["left", "right"]:
		kenar.add_theme_constant_override("margin_" + k, 24)
	for k in ["top", "bottom"]:
		kenar.add_theme_constant_override("margin_" + k, 14)
	add_child(kenar)
	var dikey := VBoxContainer.new()
	dikey.add_theme_constant_override("separation", 6)
	kenar.add_child(dikey)

	var ust := HBoxContainer.new()
	dikey.add_child(ust)
	var b := _etiket("SON SIĞINAK", 40, Color(1, 0.75, 0.4))
	b.name = "Baslik"
	b.add_theme_font_override("font", _baslik_font)
	ust.add_child(b)
	var alt := _etiket("   Kanatlıların son kasabası", 20, Color(0.8, 0.72, 0.62))
	alt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ust.add_child(alt)
	var bos := Control.new()
	bos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ust.add_child(bos)
	_altin = _etiket("", 28, Color(1, 0.85, 0.4))
	ust.add_child(_altin)
	var don := Button.new()
	don.text = "GERİ"
	don.custom_minimum_size = Vector2(250, 56)
	don.pressed.connect(func():
		visible = false
		kapandi.emit())
	ust.add_child(don)
	_mesaj = _etiket("", 20, Color(1, 0.9, 0.7))
	_mesaj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dikey.add_child(_mesaj)

	var sutunlar := HBoxContainer.new()
	sutunlar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sutunlar.add_theme_constant_override("separation", 16)
	dikey.add_child(sutunlar)
	_demirci_liste = _esnaf(sutunlar, "Demirci Haldun", "Eşya yükseltme", "Barbarian", "Cheer", "demirci", Color(1.0, 0.55, 0.2), ["2H_Axe"])
	_simyaci_liste = _esnaf(sutunlar, "Simyacı Nevra", "İksir ve tüy", "Mage", "Spellcasting", "simyaci", Color(0.4, 1.0, 0.5), ["Spellbook_open"])
	_tuccar_liste = _esnaf(sutunlar, "Tüccar Kerem", "Gizemli sandıklar", "Rogue_Hooded", "Interact", "tuccar", Color(0.8, 0.5, 1.0), ["Knife"])


func _etiket(metin: String, boy: int, renk: Color) -> Label:
	var l := Label.new()
	l.text = metin
	l.add_theme_font_size_override("font_size", boy)
	l.add_theme_color_override("font_color", renk)
	return l


func _esnaf(kok: Container, ad: String, is_ad: String, model: String, anim: String, anahtar: String, renk: Color, sakla: Array) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.09, 0.06, 0.06, 0.95)
	st.border_color = renk.darkened(0.3)
	st.set_border_width_all(2)
	st.set_corner_radius_all(12)
	st.content_margin_left = 12
	st.content_margin_right = 12
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", st)
	kok.add_child(panel)
	_paneller[anahtar] = panel
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	var ust := HBoxContainer.new()
	v.add_child(ust)
	ust.add_child(Portre.yap(model, anim, Vector2i(120, 150), sakla, renk))
	var yazi := VBoxContainer.new()
	yazi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ust.add_child(yazi)
	var a := _etiket(ad, 24, renk.lightened(0.2))
	a.add_theme_font_override("font", _baslik_font)
	yazi.add_child(a)
	yazi.add_child(_etiket(is_ad, 18, Color(0.85, 0.8, 0.72)))
	var soz := _etiket(SOZLER[anahtar].pick_random(), 16, Color(0.75, 0.7, 0.65))
	soz.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	soz.custom_minimum_size = Vector2(150, 0)
	yazi.add_child(soz)
	var kaydir := ScrollContainer.new()
	kaydir.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kaydir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(kaydir)
	var liste := VBoxContainer.new()
	liste.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	liste.add_theme_constant_override("separation", 6)
	kaydir.add_child(liste)
	return liste


func ac(esnaf := "") -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	for k in _paneller:
		_paneller[k].visible = esnaf == "" or k == esnaf
	visible = true
	_mesaj.text = "Altınını burada harca. Eşyalarını demirciye yükselt, iksirini tamamla."
	yenile()


func _satir(liste: VBoxContainer, metin: String, renk: Color, dugme: String, aktif: bool, cagri: Callable) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	liste.add_child(h)
	var l := _etiket(metin, 18, renk)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size = Vector2(120, 0)
	h.add_child(l)
	var b := Button.new()
	b.text = dugme
	b.custom_minimum_size = Vector2(150, 52)
	b.add_theme_font_size_override("font_size", 20)
	b.disabled = not aktif
	b.pressed.connect(func():
		cagri.call()
		yenile())
	h.add_child(b)


func yenile() -> void:
	if kahraman == null:
		return
	_altin.text = "%d altın   " % kahraman.altin
	for liste in [_demirci_liste, _simyaci_liste, _tuccar_liste]:
		for c in liste.get_children():
			c.queue_free()
	# --- Demirci
	var bos := true
	for y in Esya.YUVALAR:
		if not kahraman.esyalar.has(y):
			continue
		bos = false
		var e: Dictionary = kahraman.esyalar[y]
		var arti := int(e.get("arti", 0))
		if arti >= 10:
			_satir(_demirci_liste, "%s\n(en yüksek)" % Esya.tam_ad(e), Esya.renk(e), "TAMAM", false, func(): pass)
			continue
		var fiyat := yukseltme_fiyati(e)
		var sans := basari_sansi(arti)
		_satir(_demirci_liste, "%s\n+%d → +%d  ·  başarı %%%d" % [Esya.tam_ad(e), arti, arti + 1, int(sans * 100)], Esya.renk(e),
			"%d altın" % fiyat, kahraman.altin >= fiyat, func(): _yukselt(e))
	if bos:
		_demirci_liste.add_child(_etiket("Takılı eşyan yok. Önce envanterden bir şey tak.", 17, Color(0.75, 0.7, 0.65)))
	# --- Simyacı
	_satir(_simyaci_liste, "Can İksiri  (%d / 5)\nCanının %%45'ini doldurur" % kahraman.iksir, Color(1, 0.5, 0.5), "30 altın",
		kahraman.altin >= 30 and kahraman.iksir < 5, func():
			kahraman.altin -= 30
			kahraman.iksir += 1
			_bilgi("İksir alındı.", "altin"))
	_satir(_simyaci_liste, "Kanat Tüyü\n%s çubuğunu hemen doldurur" % kahraman.yetenek_ad("son_vurus"), Color(1, 0.75, 0.4), "120 altın",
		kahraman.altin >= 120 and kahraman.ofke < 100, func():
			kahraman.altin -= 120
			kahraman.ofke = 100.0
			_bilgi("Kanat Tüyü kullanıldı: son vuruş hazır!", "seviye"))
	_satir(_simyaci_liste, "Tam İyileşme\nCan ve mana tamamen dolar", Color(0.6, 0.85, 1.0), "40 altın",
		kahraman.altin >= 40, func():
			kahraman.altin -= 40
			kahraman.can = kahraman.deger("can")
			kahraman.mana = kahraman.deger("mana")
			_bilgi("Can ve mana doldu.", "seviye"))
	# --- Tüccar
	var sv := kahraman.seviye
	for t in [["Gizemli Sandık", "Rastgele eşya, en az Büyülü", 120 + sv * 10, 1],
			["Nadir Sandık", "En az Nadir eşya", 450 + sv * 30, 2],
			["Efsanevi Sandık", "Garanti Efsanevi eşya", 1500 + sv * 80, 3]]:
		var fiyat: int = t[2]
		var en_az: int = t[3]
		_satir(_tuccar_liste, "%s\n%s" % [t[0], t[1]], Esya.NADIRLIK[en_az]["renk"], "%d altın" % fiyat,
			kahraman.altin >= fiyat and kahraman.canta.size() < Kahraman.CANTA_MAX, func():
				kahraman.altin -= fiyat
				var e := Esya.uret(kahraman.seviye, en_az)
				kahraman.canta.append(e)
				_bilgi("Sandıktan çıktı: %s [%s] → çantaya" % [e["ad"], Esya.NADIRLIK[e["nadirlik"]]["ad"]], "esya"))
	var siradan := 0
	for e in kahraman.canta:
		if e["nadirlik"] == 0:
			siradan += kahraman.satis_fiyati(e)
	_satir(_tuccar_liste, "Çantadaki Sıradan eşyaları sat", Color(0.8, 0.8, 0.8), "+%d altın" % siradan, siradan > 0, func():
		var i := kahraman.canta.size() - 1
		while i >= 0:
			if kahraman.canta[i]["nadirlik"] == 0:
				kahraman.sat(i)
			i -= 1
		_bilgi("Sıradan eşyalar satıldı.", "altin"))


static func yukseltme_fiyati(e: Dictionary) -> int:
	var arti := int(e.get("arti", 0))
	return int((40 + int(e["seviye"]) * 6) * (arti + 1) * (1.0 + int(e["nadirlik"]) * 0.5))


static func basari_sansi(arti: int) -> float:
	return 1.0 if arti < 5 else maxf(0.35, 1.0 - (arti - 4) * 0.12)


func _yukselt(e: Dictionary) -> void:
	var fiyat := yukseltme_fiyati(e)
	if kahraman.altin < fiyat:
		return
	kahraman.altin -= fiyat
	var arti := int(e.get("arti", 0))
	if randf() <= basari_sansi(arti):
		var oran := kahraman.can / maxf(1.0, kahraman.deger("can"))
		e["arti"] = arti + 1
		kahraman.can = kahraman.deger("can") * oran
		_bilgi("Başarılı! %s artık +%d" % [e["ad"], arti + 1], "seviye")
	else:
		_bilgi("Örs çatladı... yükseltme başarısız (eşya zarar görmedi).", "aci")


func _bilgi(metin: String, ses: String) -> void:
	_mesaj.text = metin
	Ses.cal(ses, -4.0, 0.0)
