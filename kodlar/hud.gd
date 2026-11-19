class_name Hud
extends Control
## Oyun arayüzü: can/mana küreleri, yetenek çubuğu, tecrübe, dalga, mesajlar, boss çubuğu.

var kahraman: Kahraman
var ana: Node
var _f: Font
var _fs: Font
var _baslik: Font
var _ikonlar := {}
var _mesajlar: Array = []       ## [metin, renk, buyuk, kalan]
var _bildirimler: Array = []    ## eşya bildirimleri [metin, renk, kalan]
var _seri := 0
var _seri_sure := 0.0
var mobil_duzen := false
var buyuk_harita := false        ## büyük harita açık mı
var _canta_ikon: Texture2D

const YETENEK_SIRA := ["saldir", "yetenek1", "yetenek2", "yetenek3", "yetenek4"]
const TUS := {"saldir": "SOL", "yetenek1": "SAĞ/1", "yetenek2": "2", "yetenek3": "BOŞLUK", "yetenek4": "4", "son_vurus": "R", "iksir": "Q"}
const ALTIN_R := Color(0.84, 0.67, 0.36)
const ALTIN_K := Color(0.47, 0.35, 0.16)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_f = load("res://assets/font/Rajdhani-Bold.ttf")
	_fs = load("res://assets/font/Rajdhani-SemiBold.ttf")
	_baslik = load("res://assets/font/Cinzel-Black.ttf")
	var harita := {"saldir": "kilic", "yetenek1": "kasirga", "yetenek2": "yarik", "yetenek3": "kanat",
			"yetenek4": "meteor", "son_vurus": "son", "iksir": "iksir"}
	for ad in harita:
		_ikonlar[ad] = load("res://assets/ikon/%s.png" % harita[ad])
	_canta_ikon = load("res://assets/ikon/yuva_canta.png")


func mesaj(metin: String, renk := Color.WHITE, buyuk := false) -> void:
	for m in _mesajlar:
		if m[0] == metin:
			m[3] = 2.2
			return
	_mesajlar.append([metin, renk, buyuk, 2.4 if buyuk else 1.8])
	if _mesajlar.size() > 3:
		_mesajlar.pop_front()


func esya_bildir(e: Dictionary, sonuc: String) -> void:
	var ek := {"takildi": "  → takıldı", "canta": "  → çantaya girdi (I / çanta)", "altin": "  → çanta dolu, altına çevrildi"}
	var metin := "%s  [%s]  %s%s" % [e["ad"], Esya.NADIRLIK[e["nadirlik"]]["ad"], Esya.ozet(e), ek.get(sonuc, "")]
	_bildirimler.append([metin, Esya.renk(e), 4.5, sonuc])
	if _bildirimler.size() > 4:
		_bildirimler.pop_front()


func oldurme() -> void:
	_seri += 1
	_seri_sure = 3.0


func _process(dt: float) -> void:
	for m in _mesajlar:
		m[3] -= dt
	_mesajlar = _mesajlar.filter(func(m): return m[3] > 0)
	for b in _bildirimler:
		b[2] -= dt
	_bildirimler = _bildirimler.filter(func(b): return b[2] > 0)
	_seri_sure -= dt
	if _seri_sure <= 0:
		_seri = 0
	if not Oyun.mobil or Engine.get_process_frames() % 2 == 0:
		queue_redraw()


func _yazi(p: Vector2, metin: String, boy: int, renk: Color, hiza := HORIZONTAL_ALIGNMENT_LEFT, genislik := -1.0, font: Font = null, golge := true) -> void:
	var f := font if font else _f
	if golge:
		draw_string_outline(f, p, metin, hiza, genislik, boy, 6, Color(0, 0, 0, 0.85 * renk.a))
	draw_string(f, p, metin, hiza, genislik, boy, renk)


func _draw() -> void:
	if kahraman == null:
		return
	var b := get_viewport_rect().size
	if mobil_duzen:
		_mobil_ust(b)
	else:
		_masaustu_alt(b)
	_ust_bilgi(b)
	_mesajlari_ciz(b)
	_bildirimleri_ciz(b)
	_boss_cubugu(b)
	var mh := kucuk_harita_alani()
	_harita_ciz(mh.position, mh.size.x * 0.5, false)
	if not mobil_duzen:
		var ca := canta_alani()
		draw_rect(ca, Color(0.05, 0.04, 0.05, 0.85))
		draw_rect(ca, ALTIN_K, false, 2.0)
		if _canta_ikon:
			draw_texture_rect(_canta_ikon, Rect2(ca.position + Vector2(6, 6), Vector2(36, 36)), false, Color(1, 0.85, 0.55))
		_yazi(ca.position + Vector2(48, 30), "ENVANTER (I)  %d/%d" % [kahraman.canta.size(), Kahraman.CANTA_MAX], 16, Color(0.95, 0.88, 0.75))
	if Oyun.fps_goster:
		_yazi(Vector2(12, b.y - 14 if mobil_duzen else 22), "FPS %d" % Engine.get_frames_per_second(), 18, Color(0.6, 1, 0.6))
	if buyuk_harita:
		draw_rect(Rect2(Vector2.ZERO, b), Color(0, 0, 0, 0.72))
		var r := minf(b.x, b.y) * 0.4
		var c := b * 0.5 + Vector2(0, 20)
		_yazi(Vector2(0, c.y - r - 46), "KÜL OVALARI  ·  YIKIK MAHZEN", 34, Color(1, 0.78, 0.45), HORIZONTAL_ALIGNMENT_CENTER, b.x, _baslik)
		_harita_ciz(c, r, true)
		var lx := c.x + r + 40
		var ly := c.y - 60
		if lx + 180 > b.x:
			lx = 30
		for satir in [[Color(1, 0.75, 0.3), "Sen"], [Color(0.95, 0.2, 0.15), "Düşman"], [Color(1, 0.55, 0.1), "Elit / Boss"], [Color(0.4, 0.65, 1.0), "Ganimet"], [Color(0.6, 0.55, 0.5), "Sütun"]]:
			draw_circle(Vector2(lx + 8, ly - 6), 7, satir[0])
			_yazi(Vector2(lx + 24, ly), satir[1], 20, Color(0.92, 0.88, 0.8))
			ly += 30
		_yazi(Vector2(0, b.y - 30), "Kapatmak için dokun / tıkla  ·  M", 18, Color(0.8, 0.75, 0.68), HORIZONTAL_ALIGNMENT_CENTER, b.x)


# ------------------------------------------------------------------ masaüstü
func _kure(c: Vector2, r: float, oran: float, ust: Color, alt: Color, etiket: String, deger: String) -> void:
	draw_circle(c, r + 9, Color(0.06, 0.05, 0.06))
	draw_arc(c, r + 9, 0, TAU, 64, ALTIN_K, 3.0, true)
	draw_arc(c, r + 4, 0, TAU, 64, ALTIN_R, 2.0, true)
	draw_circle(c, r, Color(0.04, 0.03, 0.05))
	oran = clampf(oran, 0.0, 1.0)
	if oran > 0.005:
		# sıvı: dairenin seviye çizgisinin altında kalan kısmı (dalgalı)
		var seviye := c.y + r - 2.0 * r * oran
		var nokta := PackedVector2Array()
		var renkler := PackedColorArray()
		var t := Time.get_ticks_msec() / 1000.0
		var adim := 40
		for i in adim + 1:
			var x := c.x - r + 2.0 * r * i / adim
			var dx := x - c.x
			var yarim := sqrt(maxf(0.0, r * r - dx * dx))
			var y := clampf(seviye + sin(i * 0.5 + t * 3.0) * 3.0, c.y - yarim, c.y + yarim)
			nokta.append(Vector2(x, y))
			renkler.append(ust)
		for i in range(adim, -1, -1):
			var x := c.x - r + 2.0 * r * i / adim
			var dx := x - c.x
			nokta.append(Vector2(x, c.y + sqrt(maxf(0.0, r * r - dx * dx))))
			renkler.append(alt)
		draw_polygon(nokta, renkler)
	draw_circle(c + Vector2(-r * 0.25, -r * 0.45), r * 0.28, Color(1, 1, 1, 0.06))
	_yazi(c + Vector2(-r, 8), deger, 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, r * 2)
	_yazi(c + Vector2(-r, -r - 16), etiket, 16, ALTIN_R, HORIZONTAL_ALIGNMENT_CENTER, r * 2, _baslik)


func _yuva(p: Vector2, boy: float, ad: String) -> void:
	var ikon: Texture2D = kahraman.ikon(ad)
	var kilitli := ad in kahraman.ACILMA and not kahraman.acik_mi(ad)
	var renk := Color(0.35, 0.35, 0.35) if kilitli else Color.WHITE
	if ad in kahraman.MANA and kahraman.mana < kahraman.MANA[ad]:
		renk = Color(0.5, 0.55, 0.9)
	draw_rect(Rect2(p - Vector2(4, 4), Vector2(boy + 8, boy + 8)), Color(0.05, 0.04, 0.05))
	if ikon:
		draw_texture_rect(ikon, Rect2(p, Vector2(boy, boy)), false, renk)
	var oran := 0.0
	if ad in kahraman.bekleme and kahraman.BEKLEME.has(ad):
		oran = kahraman.bekleme[ad] / kahraman.BEKLEME[ad]
	if oran > 0:
		draw_rect(Rect2(p + Vector2(0, boy * (1.0 - oran)), Vector2(boy, boy * oran)), Color(0, 0, 0, 0.6))
		_yazi(p + Vector2(0, boy * 0.62), str(int(ceil(kahraman.bekleme[ad]))), 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, boy)
	if kilitli:
		_yazi(p + Vector2(0, boy * 0.6), "Sv %d" % kahraman.ACILMA[ad], 18, Color(1, 1, 1, 0.9), HORIZONTAL_ALIGNMENT_CENTER, boy)
	draw_rect(Rect2(p - Vector2(2, 2), Vector2(boy + 4, boy + 4)), ALTIN_K, false, 2.0)
	_yazi(p + Vector2(4, 16), TUS.get(ad, ""), 13, Color(1, 1, 1, 0.95))


func _masaustu_alt(b: Vector2) -> void:
	var pw := 640.0
	var ph := 118.0
	var px := (b.x - pw) * 0.5
	var py := b.y - ph - 14
	draw_rect(Rect2(px, py, pw, ph), Color(0.05, 0.04, 0.06, 0.88))
	draw_rect(Rect2(px, py, pw, ph), ALTIN_K, false, 2.0)
	# son vuruş çubuğu
	var bx := px + 90
	var bw := pw - 180
	draw_rect(Rect2(bx, py + 10, bw, 16), Color(0.02, 0.02, 0.02))
	var o := kahraman.ofke / 100.0
	draw_rect(Rect2(bx, py + 10, bw * o, 16), Color(1.0, 0.45 + 0.3 * o, 0.1))
	draw_rect(Rect2(bx, py + 10, bw, 16), ALTIN_K, false, 1.5)
	var ub := "KANAT AÇILIMI HAZIR · R" if o >= 1.0 else "KANAT AÇILIMI  %d%%" % int(o * 100)
	_yazi(Vector2(bx, py + 24), ub, 15, Color(1, 0.95, 0.85), HORIZONTAL_ALIGNMENT_CENTER, bw)
	# yetenek yuvaları
	var boy := 62.0
	var ara := 14.0
	var toplam := 7 * boy + 6 * ara
	var sx := (b.x - toplam) * 0.5
	var sira := ["saldir", "yetenek1", "yetenek2", "yetenek3", "yetenek4", "son_vurus", "iksir"]
	for i in sira.size():
		_yuva(Vector2(sx + i * (boy + ara), py + 40), boy, sira[i])
	_yazi(Vector2(sx + 6 * (boy + ara) + boy - 66, py + 40 + boy - 6), "×%d" % kahraman.iksir, 16, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, 60)
	# küreler
	_kure(Vector2(px - 92, b.y - 96), 76, kahraman.can / kahraman.deger("can"),
		Color(0.94, 0.24, 0.2), Color(0.43, 0.03, 0.04), "CAN", "%d / %d" % [int(kahraman.can), int(kahraman.deger("can"))])
	_kure(Vector2(px + pw + 92, b.y - 96), 76, kahraman.mana / kahraman.deger("mana"),
		Color(0.35, 0.63, 1.0), Color(0.06, 0.12, 0.47), "MANA", "%d / %d" % [int(kahraman.mana), int(kahraman.deger("mana"))])
	_tecrube(b, 0.0)


func _tecrube(b: Vector2, y_ust: float) -> void:
	var oran := float(kahraman.tecrube) / kahraman.gereken_tecrube()
	if y_ust > 0:
		return
	draw_rect(Rect2(0, b.y - 7, b.x, 7), Color(0.04, 0.04, 0.05))
	draw_rect(Rect2(0, b.y - 6, b.x * oran, 5), Color(0.9, 0.7, 0.27))
	for i in range(1, 10):
		draw_line(Vector2(b.x * i / 10.0, b.y - 7), Vector2(b.x * i / 10.0, b.y), Color(0, 0, 0), 2.0)


# ------------------------------------------------------------------ telefon
func _mobil_ust(b: Vector2) -> void:
	var x := 16.0
	var y := 14.0
	draw_rect(Rect2(x, y, 330, 86), Color(0.05, 0.04, 0.06, 0.78))
	draw_rect(Rect2(x, y, 330, 86), ALTIN_K, false, 2.0)
	draw_circle(Vector2(x + 40, y + 43), 30, Color(0.1, 0.07, 0.06))
	draw_arc(Vector2(x + 40, y + 43), 30, 0, TAU, 40, Color(1, 0.55, 0.15), 3.0, true)
	_yazi(Vector2(x + 10, y + 52), str(kahraman.seviye), 28, Color(1, 0.88, 0.6), HORIZONTAL_ALIGNMENT_CENTER, 60)
	var cx := x + 82
	var w := 236.0
	var co := clampf(kahraman.can / kahraman.deger("can"), 0, 1)
	draw_rect(Rect2(cx, y + 12, w, 18), Color(0.2, 0.03, 0.03))
	draw_rect(Rect2(cx, y + 12, w * co, 18), Color(0.85, 0.15, 0.12))
	_yazi(Vector2(cx, y + 27), "%d / %d" % [int(kahraman.can), int(kahraman.deger("can"))], 16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, w)
	var mo := clampf(kahraman.mana / kahraman.deger("mana"), 0, 1)
	draw_rect(Rect2(cx, y + 36, w, 12), Color(0.03, 0.05, 0.15))
	draw_rect(Rect2(cx, y + 36, w * mo, 12), Color(0.3, 0.55, 1.0))
	var to := float(kahraman.tecrube) / kahraman.gereken_tecrube()
	draw_rect(Rect2(cx, y + 56, w, 8), Color(0.08, 0.07, 0.04))
	draw_rect(Rect2(cx, y + 56, w * to, 8), Color(0.9, 0.7, 0.27))
	_yazi(Vector2(cx, y + 82), "Seviye %d  ·  %d altın" % [kahraman.seviye, kahraman.altin], 16, Color(0.9, 0.85, 0.75))


# ------------------------------------------------------------------ ortak
func _ust_bilgi(b: Vector2) -> void:
	if ana == null:
		return
	var metin: String = ana.dalga_metni()
	_yazi(Vector2(0, 38), metin, 30, Color(0.95, 0.82, 0.55), HORIZONTAL_ALIGNMENT_CENTER, b.x, _baslik)
	_yazi(Vector2(0, 62), ana.alt_metin(), 17, Color(0.85, 0.8, 0.72), HORIZONTAL_ALIGNMENT_CENTER, b.x)
	if not mobil_duzen:
		_yazi(Vector2(b.x - 324, 34), "%d altın" % kahraman.altin, 22, Color(1, 0.85, 0.4), HORIZONTAL_ALIGNMENT_RIGHT, 300)
		_yazi(Vector2(b.x - 324, 58), "Seviye %d" % kahraman.seviye, 20, Color(0.95, 0.9, 0.8), HORIZONTAL_ALIGNMENT_RIGHT, 300)
	if _seri >= 5:
		var a := clampf(_seri_sure, 0, 1)
		var y := 350.0 if mobil_duzen else b.y * 0.42
		_yazi(Vector2(b.x - 330, y), "×%d" % _seri, 56, Color(1, 0.77, 0.35, a), HORIZONTAL_ALIGNMENT_RIGHT, 300, _baslik)
		_yazi(Vector2(b.x - 330, y + 30), "KATLİAM SERİSİ", 20, Color(1, 0.9, 0.75, a), HORIZONTAL_ALIGNMENT_RIGHT, 300)


func _mesajlari_ciz(b: Vector2) -> void:
	var y := b.y * 0.30
	for m in _mesajlar:
		var a := clampf(m[3] * 2.0, 0.0, 1.0)
		var renk: Color = m[1]
		renk.a = a
		var boy := 46 if m[2] else 26
		_yazi(Vector2(0, y), m[0], boy, renk, HORIZONTAL_ALIGNMENT_CENTER, b.x, _baslik if m[2] else _f)
		y += boy + 12


func _bildirimleri_ciz(b: Vector2) -> void:
	var y := b.y * 0.62 if not mobil_duzen else 130.0
	for n in _bildirimler:
		var a := clampf(n[2], 0.0, 1.0)
		var renk: Color = n[1]
		renk.a = a
		_yazi(Vector2(22, y), n[0], 18, renk, HORIZONTAL_ALIGNMENT_LEFT, b.x * 0.6)
		y += 24


func _boss_cubugu(b: Vector2) -> void:
	if ana == null or ana.boss == null or not is_instance_valid(ana.boss) or ana.boss.olu:
		return
	var w := minf(620.0, b.x * 0.5)
	var x := (b.x - w) * 0.5
	var y := 84.0
	var o: float = ana.boss.can / ana.boss.can_max
	draw_rect(Rect2(x - 3, y - 3, w + 6, 22), Color(0, 0, 0, 0.8))
	draw_rect(Rect2(x, y, w * o, 16), Color(0.8, 0.12, 0.05))
	draw_rect(Rect2(x - 3, y - 3, w + 6, 22), Color(1, 0.5, 0.15), false, 2.0)
	_yazi(Vector2(x, y + 36), ana.boss.ad, 22, Color(1, 0.6, 0.25), HORIZONTAL_ALIGNMENT_CENTER, w, _baslik)


# ------------------------------------------------------------------ harita
func kucuk_harita_alani() -> Rect2:
	## Küçük haritanın merkezi (position) ve çapı (size.x).
	var b := get_viewport_rect().size
	var r := 78.0
	var c := Vector2(b.x - r - 26, 178.0) if mobil_duzen else Vector2(b.x - r - 26, 168.0)
	return Rect2(c, Vector2(r * 2, r * 2))


func harita_dokunus(p: Vector2) -> bool:
	## Dokunuş/tık küçük haritadaysa büyük haritayı açar; büyük harita açıksa her dokunuş kapatır.
	if not visible:
		return false
	if buyuk_harita:
		harita_ac_kapa()
		return true
	var mh := kucuk_harita_alani()
	if p.distance_to(mh.position) <= mh.size.x * 0.5 + 10:
		harita_ac_kapa()
		return true
	return false


func harita_ac_kapa() -> void:
	buyuk_harita = not buyuk_harita
	get_tree().paused = buyuk_harita
	Oyun.tum_girdileri_birak()
	Ses.cal("dugme", -6.0, 0.0)


func _harita_nokta(w: Vector3, c: Vector2, olcek: float) -> Vector2:
	# Kamera 45° döndüğü için harita da aynı açıyla çizilir: ekranda yukarı = haritada yukarı.
	var sag := Vector3(1, 0, -1).normalized()
	var ileri := Vector3(-1, 0, -1).normalized()
	return c + Vector2(w.dot(sag), -w.dot(ileri)) * olcek


func _harita_ciz(c: Vector2, r: float, buyuk: bool) -> void:
	var olcek := r / (Dunya.YARI * 1.48)
	if not buyuk:
		draw_circle(c, r + 6, Color(0.05, 0.04, 0.05, 0.85))
		draw_arc(c, r + 6, 0, TAU, 56, ALTIN_K, 3.0, true)
		draw_arc(c, r + 2, 0, TAU, 56, ALTIN_R, 1.5, true)
	var Y := Dunya.YARI
	var koseler := PackedVector2Array([
		_harita_nokta(Vector3(-Y, 0, -Y), c, olcek), _harita_nokta(Vector3(Y, 0, -Y), c, olcek),
		_harita_nokta(Vector3(Y, 0, Y), c, olcek), _harita_nokta(Vector3(-Y, 0, Y), c, olcek)])
	draw_colored_polygon(koseler, Color(0.28, 0.22, 0.2, 0.9))
	# arka duvarlar (kalın), ön kenar (ince)
	draw_line(koseler[0], koseler[1], Color(0.75, 0.62, 0.45), 4.0 if buyuk else 2.5)
	draw_line(koseler[0], koseler[3], Color(0.75, 0.62, 0.45), 4.0 if buyuk else 2.5)
	draw_line(koseler[1], koseler[2], Color(0.5, 0.42, 0.35), 1.5)
	draw_line(koseler[2], koseler[3], Color(0.5, 0.42, 0.35), 1.5)
	var nb := 1.6 if buyuk else 1.0
	for s in Dunya.SUTUNLAR:
		draw_circle(_harita_nokta(s, c, olcek), 4.0 * nb, Color(0.6, 0.55, 0.5))
	for sd in get_tree().get_nodes_in_group("sandik"):
		if not sd.acik:
			var sp := _harita_nokta(sd.global_position, c, olcek)
			draw_rect(Rect2(sp - Vector2(3.5, 3.5) * nb, Vector2(7, 7) * nb), Color(1, 0.8, 0.25))
	for g in get_tree().get_nodes_in_group("ganimet"):
		var renk := Color(1, 0.82, 0.35)
		if g.tur == "esya":
			renk = Esya.renk(g.esya)
		elif g.tur == "iksir":
			renk = Color(1, 0.3, 0.3)
		draw_circle(_harita_nokta(g.global_position, c, olcek), 2.5 * nb, renk)
	for d in get_tree().get_nodes_in_group("dusman"):
		if d.olu:
			continue
		var p := _harita_nokta(d.global_position, c, olcek)
		if d.boss:
			draw_circle(p, 6.0 * nb, Color(1, 0.45, 0.05))
			draw_arc(p, 8.0 * nb, 0, TAU, 20, Color(1, 0.8, 0.4), 1.5, true)
		elif d.elit:
			draw_circle(p, 4.0 * nb, Color(1, 0.55, 0.1))
		else:
			draw_circle(p, 2.6 * nb, Color(0.95, 0.2, 0.15))
	# oyuncu: baktığı yönü gösteren ok
	if kahraman:
		var p := _harita_nokta(kahraman.global_position, c, olcek)
		var sag := Vector3(1, 0, -1).normalized()
		var ileri := Vector3(-1, 0, -1).normalized()
		var yon := Vector2(kahraman.bakis.dot(sag), -kahraman.bakis.dot(ileri)).normalized()
		var dik := Vector2(-yon.y, yon.x)
		var boy := 9.0 * nb
		var ok := PackedVector2Array([p + yon * boy, p - yon * boy * 0.6 + dik * boy * 0.65, p - yon * boy * 0.3, p - yon * boy * 0.6 - dik * boy * 0.65])
		draw_circle(p, boy * 1.2, Color(1, 0.6, 0.2, 0.25))
		draw_colored_polygon(ok, Color(1, 0.85, 0.45))
		draw_polyline(PackedVector2Array([ok[0], ok[1], ok[2], ok[3], ok[0]]), Color(0.3, 0.12, 0.0), 1.5, true)
	if not buyuk:
		_yazi(Vector2(c.x - r, c.y + r + 24), "HARİTA (M)" if not mobil_duzen else "HARİTA", 14, Color(0.85, 0.78, 0.65), HORIZONTAL_ALIGNMENT_CENTER, r * 2)


func canta_alani() -> Rect2:
	var mh := kucuk_harita_alani()
	return Rect2(mh.position + Vector2(-mh.size.x * 0.5 - 40, mh.size.y * 0.5 + 34), Vector2(mh.size.x + 40, 48))
