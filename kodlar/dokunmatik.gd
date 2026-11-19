class_name Dokunmatik
extends Control
## Telefon kontrolleri: solda kayan joystick, sağda saldırı + yetenek düğmeleri.
## Her parmak kendi numarasıyla (index) izlenir: aynı anda yürüyüp yetenek kullanılabilir,
## bir parmağı kaldırmak diğerini etkilemez. Uygulama arka plana geçince her şey bırakılır.

const JOY_YARICAP := 75.0
const OLU_BOLGE := 0.12

var kahraman: Node      ## bekleme süreleri ve mana için
var hud: Node           ## büyük harita açıkken düğmeler çizilmez
var _parmak := {}       ## parmak numarası -> "joy" ya da eylem adı
var _joy_merkez := Vector2.ZERO
var _joy_uc := Vector2.ZERO
var _joy_aktif := false
var _dugmeler := {}     ## eylem -> {"merkez": Vector2, "r": float, "ikon": Texture2D}
var _basili := {}
var _font: Font
var _ikonlar := {}
var duraklat_cagri: Callable
var harita_cagri: Callable    ## dokunuş haritadaysa haritayı açar/kapatır (true döner)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_font = load("res://assets/font/Rajdhani-Bold.ttf")
	var harita := {"saldir": "kilic", "yetenek1": "kasirga", "yetenek2": "yarik", "yetenek3": "kanat",
			"yetenek4": "meteor", "son_vurus": "son", "iksir": "iksir"}
	for ad in harita:
		_ikonlar[ad] = load("res://assets/ikon/%s.png" % harita[ad])
	Oyun.girdiler_birakildi.connect(_hepsini_birak)
	visibility_changed.connect(func():
		if not visible:
			_hepsini_birak())
	_yerlesim()
	get_viewport().size_changed.connect(_yerlesim)


func _yerlesim() -> void:
	# Ekran boyutu değişince (döndürme, farklı telefon) düğmeleri yeniden yerleştir.
	var b := get_viewport_rect().size
	# Saldırı düğmesi sağ altta; yetenekler ve Kanat Açılımı etrafında yay şeklinde,
	# aralarında boşluk kalacak şekilde (üst üste binmez).
	var ana := Vector2(b.x - 170, b.y - 150)
	_dugmeler.clear()
	_dugmeler["saldir"] = {"merkez": ana, "r": 74.0}
	var sira := ["yetenek3", "yetenek2", "yetenek1", "yetenek4", "son_vurus"]
	var acilar := [160.0, 196.0, 232.0, 268.0, 304.0]
	for i in sira.size():
		var a := deg_to_rad(acilar[i])
		_dugmeler[sira[i]] = {"merkez": ana + Vector2(cos(a), sin(a)) * 155.0, "r": 42.0}
	_dugmeler["iksir"] = {"merkez": Vector2(b.x - 430, b.y - 58), "r": 34.0}
	_dugmeler["duraklat"] = {"merkez": Vector2(b.x - 44, 44), "r": 28.0}
	queue_redraw()


func _input(e: InputEvent) -> void:
	if not visible:
		return
	if e is InputEventScreenTouch:
		if e.pressed:
			if _parmak.has(e.index):      # bırakma olayı kaçmışsa önce bırak
				_birak(e.index)
			if _bas(e.index, e.position):
				get_viewport().set_input_as_handled()
		else:
			if _parmak.has(e.index):
				_birak(e.index)
				get_viewport().set_input_as_handled()
	elif e is InputEventScreenDrag:
		if _parmak.get(e.index, "") == "joy":
			_joy_guncelle(e.position)
			get_viewport().set_input_as_handled()


func _bas(index: int, p: Vector2) -> bool:
	# Küçük harita / açık büyük harita
	if harita_cagri.is_valid() and harita_cagri.call(p):
		return true
	# Önce düğmeler (dokunma alanı görünen daireden biraz büyük: parmakla rahat basılsın)
	var en_yakin := ""
	var en_yakin_m := INF
	for ad in _dugmeler:
		var d: Dictionary = _dugmeler[ad]
		var m := p.distance_to(d["merkez"])
		if m < d["r"] * 1.3 and m < en_yakin_m:
			en_yakin = ad
			en_yakin_m = m
	if en_yakin != "":
		if en_yakin == "duraklat":
			if duraklat_cagri.is_valid():
				duraklat_cagri.call()
			return true
		_parmak[index] = en_yakin
		_basili[en_yakin] = true
		Input.action_press(en_yakin)
		Oyun.eylem_basildi.emit(en_yakin)
		queue_redraw()
		return true
	# Ekranın sol yarısı: joystick (parmağın dokunduğu yer merkez olur)
	if p.x < get_viewport_rect().size.x * 0.5 and not _joy_aktif:
		_parmak[index] = "joy"
		_joy_aktif = true
		_joy_merkez = p
		_joy_uc = p
		Oyun.dokunmatik_yon = Vector2.ZERO
		queue_redraw()
		return true
	return false


func _joy_guncelle(p: Vector2) -> void:
	var fark := p - _joy_merkez
	# Parmak çok uzağa kayarsa merkez de peşinden gelir (yön kaybolmasın)
	if fark.length() > JOY_YARICAP * 1.6:
		_joy_merkez = p - fark.normalized() * JOY_YARICAP * 1.6
		fark = p - _joy_merkez
	_joy_uc = _joy_merkez + fark.limit_length(JOY_YARICAP)
	var v := fark / JOY_YARICAP
	if v.length() < OLU_BOLGE:
		v = Vector2.ZERO
	else:
		v = v.limit_length(1.0)
		v = v.normalized() * remap(v.length(), OLU_BOLGE, 1.0, 0.25, 1.0)
	Oyun.dokunmatik_yon = v
	queue_redraw()


func _birak(index: int) -> void:
	var ad: String = _parmak.get(index, "")
	_parmak.erase(index)
	if ad == "joy":
		_joy_aktif = false
		Oyun.dokunmatik_yon = Vector2.ZERO
	elif ad != "":
		_basili.erase(ad)
		# aynı eyleme başka parmak basmıyorsa bırak
		if not ad in _parmak.values():
			Input.action_release(ad)
	queue_redraw()


func _hepsini_birak() -> void:
	for i in _parmak.keys():
		_birak(i)
	_parmak.clear()
	_basili.clear()
	_joy_aktif = false
	Oyun.dokunmatik_yon = Vector2.ZERO
	for ad in Oyun.EYLEMLER:
		Input.action_release(ad)
	queue_redraw()


var _son_boyut := Vector2.ZERO


func _process(_dt: float) -> void:
	var b := get_viewport_rect().size
	if b != _son_boyut:
		_son_boyut = b
		_yerlesim()
	queue_redraw()   # bekleme süreleri her karede güncellensin


func _draw() -> void:
	if hud and hud.buyuk_harita:
		return
	# joystick
	if _joy_aktif:
		draw_circle(_joy_merkez, JOY_YARICAP + 8, Color(0, 0, 0, 0.28))
		draw_arc(_joy_merkez, JOY_YARICAP + 8, 0, TAU, 48, Color(1, 0.75, 0.45, 0.55), 3.0, true)
		draw_circle(_joy_uc, 34, Color(1, 0.6, 0.25, 0.75))
		draw_arc(_joy_uc, 34, 0, TAU, 32, Color(1, 0.9, 0.7, 0.9), 2.5, true)
	else:
		var b := get_viewport_rect().size
		var ipucu := Vector2(170, b.y - 150)
		draw_arc(ipucu, JOY_YARICAP, 0, TAU, 48, Color(1, 1, 1, 0.12), 2.0, true)
		draw_circle(ipucu, 26, Color(1, 1, 1, 0.08))
	# düğmeler
	for ad in _dugmeler:
		var d: Dictionary = _dugmeler[ad]
		var c: Vector2 = d["merkez"]
		var r: float = d["r"]
		var basili: bool = _basili.has(ad)
		if ad == "duraklat":
			draw_circle(c, r, Color(0, 0, 0, 0.4))
			draw_arc(c, r, 0, TAU, 32, Color(1, 0.8, 0.5, 0.6), 2.0, true)
			draw_rect(Rect2(c + Vector2(-9, -11), Vector2(6, 22)), Color(1, 1, 1, 0.85))
			draw_rect(Rect2(c + Vector2(3, -11), Vector2(6, 22)), Color(1, 1, 1, 0.85))
			continue
		var rr := r * (0.92 if basili else 1.0)
		draw_circle(c, rr + 5, Color(0, 0, 0, 0.45))
		var ikon: Texture2D = _ikonlar.get(ad)
		var hazir := true
		var oran := 0.0
		var kilitli := false
		if kahraman:
			if ad in kahraman.bekleme and kahraman.BEKLEME.has(ad):
				oran = kahraman.bekleme[ad] / kahraman.BEKLEME[ad]
			if ad in kahraman.ACILMA:
				kilitli = not kahraman.acik_mi(ad)
			if ad == "son_vurus":
				hazir = kahraman.ofke >= 100.0
			if ad in kahraman.MANA and kahraman.mana < kahraman.MANA[ad]:
				hazir = false
		var renk := Color(1, 1, 1, 0.95 if not basili else 1.0)
		if kilitli:
			renk = Color(0.35, 0.35, 0.35, 0.7)
		elif not hazir or oran > 0:
			renk = Color(0.55, 0.55, 0.6, 0.85)
		if ikon:
			draw_texture_rect(ikon, Rect2(c - Vector2(rr, rr), Vector2(rr, rr) * 2), false, renk)
		if oran > 0:
			# bekleme süresi: saat yönünde azalan karanlık dilim
			var noktalar := PackedVector2Array([c])
			var bas := -PI * 0.5
			var adim := 24
			for i in adim + 1:
				var a := bas + TAU * oran * i / adim
				noktalar.append(c + Vector2(cos(a), sin(a)) * rr)
			if noktalar.size() >= 3:
				draw_colored_polygon(noktalar, Color(0, 0, 0, 0.55))
			var kalan: float = kahraman.bekleme[ad]
			draw_string(_font, c + Vector2(-30, 10), str(int(ceil(kalan))), HORIZONTAL_ALIGNMENT_CENTER, 60, 28, Color.WHITE)
		var kenar := Color(1, 0.55, 0.15, 0.95) if (ad == "son_vurus" and hazir) else Color(0.85, 0.66, 0.36, 0.8)
		draw_arc(c, rr + 2, 0, TAU, 40, kenar, 3.0 if not basili else 5.0, true)
		if kilitli and kahraman:
			draw_string(_font, c + Vector2(-30, 8), "Sv %d" % kahraman.ACILMA[ad], HORIZONTAL_ALIGNMENT_CENTER, 60, 20, Color(1, 1, 1, 0.9))
		if ad == "son_vurus" and kahraman and not hazir:
			var o: float = kahraman.ofke / 100.0
			draw_arc(c, rr + 6, -PI * 0.5, -PI * 0.5 + TAU * o, 40, Color(1, 0.6, 0.2, 0.95), 4.0, true)
		if ad == "iksir" and kahraman:
			draw_string(_font, c + Vector2(8, rr + 2), str(kahraman.iksir), HORIZONTAL_ALIGNMENT_LEFT, 40, 22, Color.WHITE)
