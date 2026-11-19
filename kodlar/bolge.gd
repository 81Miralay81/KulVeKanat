class_name Bolge
extends RefCounted
## Üç büyük bölge, her birinin ortasında bir şehir:
##   Kül Ovaları (Son Sığınak, seviye 1-20), Ayaz Dağları (Buzkale, 20-40), Kor Çölü (Kor Kalesi, 40-60).
## Şehirden uzaklaştıkça düşmanların seviyesi artar. Her bölgede seviye sınırlı üç zindan var.

const YARI := 150.0                      ## oynanabilir alan yarı genişliği (300 x 300 m)
const KOY := Vector3.ZERO
const KOY_YARICAP := 30.0                ## şehir surları (içi güvenli)
const DOGUS := Vector3(0, 0, 9)

const BOLGELER := [
	{
		"id": "kul", "ad": "Kül Ovaları", "sehir": "Son Sığınak", "min": 1, "max": 20, "tema": 0, "tohum": 7,
		"gok": [Color(0.36, 0.52, 0.76), Color(0.8, 0.79, 0.76)], "sis": Color(0.72, 0.74, 0.78), "gunes": Color(1.0, 0.94, 0.84),
		"cimen": [Color(0.28, 0.31, 0.14), Color(0.56, 0.62, 0.3)], "cimen_yogun": 1.0,
		"agac": {"yaprakli": true, "ton": Color(0.95, 1.0, 0.9), "kar": 0.0, "sayi": 520, "ph": [["island_tree_02", 2.4, 3.2], ["dead_tree_trunk", 1.2, 1.6]]}, "kaya": Color(0.85, 0.82, 0.78),
		"duvar": ["res://assets/ph/castle_brick_07_Diffuse.jpg", "res://assets/ph/castle_brick_07_nor_gl.jpg", Color(1, 1, 1)],
		"esnaf": ["Demirci Haldun", "Simyacı Nevra", "Tüccar Kerem", "Yol Bekçisi Orhun", "Muhtar Selim"],
		"dusman": ["minyon", "haydut", "savasci", "buyucu"], "renk": Color(1, 1, 1),
		"zindanlar": [
			{"id": "mahzen", "ad": "Yıkık Mahzen", "seviye": 5, "boss": "garran", "dalga": 5, "tema": 0, "aci": -0.8},
			{"id": "cukur", "ad": "Kemik Çukuru", "seviye": 12, "boss": "vezra", "dalga": 6, "tema": 1, "aci": 2.3},
			{"id": "kule", "ad": "Yanık Kule", "seviye": 18, "boss": "morvas", "dalga": 7, "tema": 2, "aci": 4.1},
		],
	},
	{
		"id": "ayaz", "ad": "Ayaz Dağları", "sehir": "Buzkale", "min": 20, "max": 40, "tema": 1, "tohum": 23,
		"gok": [Color(0.42, 0.56, 0.78), Color(0.86, 0.89, 0.93)], "sis": Color(0.83, 0.87, 0.93), "gunes": Color(0.95, 0.97, 1.0),
		"cimen": [Color(0.3, 0.3, 0.22), Color(0.62, 0.6, 0.45)], "cimen_yogun": 0.08,
		"agac": {"yaprakli": true, "ton": Color(0.55, 0.7, 0.55), "kar": 0.65, "sayi": 420, "ph": [["fir_sapling", 2.6, 3.4], ["dead_tree_trunk_02", 1.2, 1.5]]}, "kaya": Color(0.75, 0.8, 0.9),
		"duvar": ["rock023_alb_ht.png", "rock023_nrm_rgh.png", Color(0.8, 0.84, 0.9)],
		"esnaf": ["Demirci Brann", "Simyacı Ilka", "Tüccar Varo", "Yol Bekçisi Tuna", "Komutan Aysel"],
		"dusman": ["minyon", "haydut", "savasci", "buyucu"], "renk": Color(0.7, 0.85, 1.15),
		"zindanlar": [
			{"id": "magara", "ad": "Donmuş Mağara", "seviye": 25, "boss": "buzpence", "dalga": 6, "tema": 3, "aci": 0.4},
			{"id": "mezar", "ad": "Buz Mezarlığı", "seviye": 32, "boss": "kiravan", "dalga": 7, "tema": 1, "aci": 2.6},
			{"id": "taht", "ad": "Ayaz Tahtı", "seviye": 38, "boss": "ayazkral", "dalga": 8, "tema": 3, "aci": 4.6},
		],
	},
	{
		"id": "kor", "ad": "Kor Çölü", "sehir": "Kor Kalesi", "min": 40, "max": 60, "tema": 2, "tohum": 41,
		"gok": [Color(0.55, 0.5, 0.52), Color(0.92, 0.72, 0.52)], "sis": Color(0.8, 0.62, 0.48), "gunes": Color(1.0, 0.82, 0.62),
		"cimen": [Color(0.36, 0.3, 0.16), Color(0.7, 0.6, 0.36)], "cimen_yogun": 0.12,
		"agac": {"yaprakli": false, "ton": Color(1, 1, 1), "kar": 0.0, "sayi": 200, "ph": [["quiver_tree_01", 1.4, 2.0], ["dead_tree_trunk", 1.0, 1.4], ["dead_tree_trunk_02", 1.0, 1.3]]}, "kaya": Color(0.78, 0.55, 0.42),
		"duvar": ["kum.jpg", "kum_nrm.jpg", Color(0.95, 0.8, 0.62)],
		"esnaf": ["Demirci Kazım", "Simyacı Sera", "Tüccar Haris", "Yol Bekçisi Demir", "Kale Ağası Yusuf"],
		"dusman": ["minyon", "haydut", "savasci", "buyucu"], "renk": Color(1.25, 0.8, 0.6),
		"zindanlar": [
			{"id": "tapinak", "ad": "Kızıl Kum Tapınağı", "seviye": 45, "boss": "sahra", "dalga": 7, "tema": 2, "aci": 1.0},
			{"id": "ocak", "ad": "Lav Ocağı", "seviye": 52, "boss": "lavkral", "dalga": 8, "tema": 2, "aci": 3.3},
			{"id": "son", "ad": "Son Kanatlı'nın Mezarı", "seviye": 58, "boss": "korkral", "dalga": 9, "tema": 4, "aci": 5.2, "final": true},
		],
	},
]

## Şehirdeki esnafların yerleri (adlar bölgeye göre değişir)
const ESNAF_YER := [
	{"id": "demirci", "konum": Vector3(-9.0, 0, 3.0), "renk": Color(1.0, 0.55, 0.2), "model": "Gladyator", "anim": "Fixing_Kneeling", "ton": Color(0.8, 0.72, 0.65)},
	{"id": "simyaci", "konum": Vector3(9.0, 0, 4.0), "renk": Color(0.4, 1.0, 0.5), "model": "InsanBuyucu", "anim": "Spell_Simple_Idle", "ton": Color(0.7, 1.0, 0.75)},
	{"id": "tuccar", "konum": Vector3(0.5, 0, -9.0), "renk": Color(0.8, 0.5, 1.0), "model": "ElfOkcu", "anim": "Idle_Talking", "ton": Color(0.9, 0.75, 1.0)},
	{"id": "yolcu", "konum": Vector3(-7.0, 0, -7.0), "renk": Color(0.4, 0.8, 1.0), "model": "Gladyator", "anim": "Idle_Torch", "ton": Color(0.7, 0.8, 1.0)},
	{"id": "gorev", "konum": Vector3(7.0, 0, -6.0), "renk": Color(1.0, 0.85, 0.3), "model": "InsanBuyucu", "anim": "Idle_Talking", "ton": Color(1.0, 0.9, 0.7)},
]

static var aktif := 0
static var veri: Dictionary = BOLGELER[0]
static var zindanlar: Array = []
static var ESNAFLAR: Array = []
static var suru_noktalari: Array = []    ## [{konum, seviye}]
static var test_kapat: Array = []
static var engeller: Array = []          ## [Vector3 merkez, yarıçap] (ağaç/bina; ışınlanma ve doğuş için)


static func dagilim(i: int) -> Dictionary:
	return BOLGELER[clampi(i, 0, BOLGELER.size() - 1)]


static func zindan_konumu(b: Dictionary, z: Dictionary) -> Vector3:
	var t := float(int(z["seviye"]) - int(b["min"])) / float(int(b["max"]) - int(b["min"]))
	var r := lerpf(55.0, YARI - 22.0, clampf(t, 0.0, 1.0))
	var a: float = z["aci"]
	return Vector3(cos(a) * r, 0, sin(a) * r)


## Bir noktadaki düşmanların seviyesi: şehirden uzaklaştıkça artar.
static func seviye_noktada(p: Vector3) -> int:
	var t := clampf((Vector2(p.x, p.z).length() - 38.0) / (YARI - 48.0), 0.0, 1.0)
	return clampi(int(round(lerpf(float(veri["min"]), float(veri["max"]), t))), int(veri["min"]), int(veri["max"]))


static func bos_mu(p: Vector3, pay := 3.0) -> bool:
	if Vector2(p.x, p.z).length() < KOY_YARICAP + pay + 2.0:
		return false
	for z in zindanlar:
		if Vector2(p.x - z["konum"].x, p.z - z["konum"].z).length() < 14.0 + pay:
			return false
	if absf(p.x) > YARI - 3.0 or absf(p.z) > YARI - 3.0:
		return false
	return true


static func _yol_yakin(p: Vector3, pay: float) -> bool:
	for z in zindanlar:
		var b: Vector3 = z["konum"]
		var ab := Vector2(b.x, b.z)
		var q := Vector2(p.x, p.z)
		var t := clampf(q.dot(ab) / ab.length_squared(), 0.0, 1.0)
		if (ab * t).distance_to(q) < pay:
			return true
	return false


static func insa(kok: Node3D, mobil: bool, bolge := 0) -> StaticBody3D:
	aktif = bolge
	veri = dagilim(bolge)
	seed(int(veri["tohum"]) * 13)
	zindanlar.clear()
	var duzlukler := [[Vector3.ZERO, KOY_YARICAP + 2.0]]
	var yollar := []
	for z in veri["zindanlar"]:
		var d: Dictionary = z.duplicate()
		d["konum"] = zindan_konumu(veri, z)
		zindanlar.append(d)
		yollar.append([Vector2.ZERO, Vector2(d["konum"].x, d["konum"].z)])
	ESNAFLAR.clear()
	for i in ESNAF_YER.size():
		var e: Dictionary = ESNAF_YER[i].duplicate()
		e["ad"] = veri["esnaf"][i]
		ESNAFLAR.append(e)
	for d in zindanlar:
		var p: Vector3 = d["konum"]
		p.y = Arazi.ham_y(int(veri["tohum"]), p.x, p.z, KOY_YARICAP + 2.0)
		d["konum"] = p
		duzlukler.append([p, 9.0])
	Arazi.hazirla(int(veri["tohum"]), YARI, KOY_YARICAP + 2.0, duzlukler, yollar, float(veri["cimen_yogun"]))

	var govde := StaticBody3D.new()
	govde.collision_layer = 1
	kok.add_child(govde)
	engeller.clear()

	Arazi.zemin_kur(kok, int(veri["tema"]), mobil)
	if float(veri["cimen_yogun"]) > 0.0 and not "cimen" in test_kapat:
		Arazi.cimen_kur(kok, mobil, veri["cimen"][0], veri["cimen"][1])

	_sehir(kok, govde, mobil)
	for zd in zindanlar:
		_zindan_girisi(kok, govde, zd)

	# görünmez sınır duvarları (dağların eteği)
	for kenar in [[Vector3(0, 5, -YARI - 1), Vector3(YARI * 2 + 4, 30, 2)], [Vector3(0, 5, YARI + 1), Vector3(YARI * 2 + 4, 30, 2)],
			[Vector3(-YARI - 1, 5, 0), Vector3(2, 30, YARI * 2 + 4)], [Vector3(YARI + 1, 5, 0), Vector3(2, 30, YARI * 2 + 4)]]:
		var s := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = kenar[1]
		s.shape = bx
		s.position = kenar[0]
		govde.add_child(s)

	# --- ağaçlar
	var a: Dictionary = veri["agac"]
	var turler := []      # [govde, yaprak, en_az_olcek, en_cok_olcek]
	# telefonda yapraklı taranmış ağaçlar çok ağır: yapraklı ağaç kodla çizilir, kuru gövdeler taranmış kalır
	if mobil:
		turler.append(Arazi.agac_mesh(int(veri["tohum"]) * 7, a["yaprakli"], a["ton"], a["kar"]) + [0.8, 1.35])
	for ph in a.get("ph", []):
		if mobil and not str(ph[0]).begins_with("dead_tree"):
			continue
		turler.append([Arazi.ph_mesh(str(ph[0]) + ("_mobil" if mobil else ""), true), null, ph[1], ph[2]])
	if not mobil:
		turler.append(Arazi.agac_mesh(int(veri["tohum"]) * 7, a["yaprakli"], a["ton"], a["kar"]) + [0.8, 1.35])
	var konumlar := []
	for i in turler.size():
		konumlar.append([])
	var sayi := int(a["sayi"] * (0.55 if mobil else 1.0))
	var deneme := 0
	while sayi > 0 and deneme < 8000:
		deneme += 1
		var p := Vector3(randf_range(-YARI - 30, YARI + 30), 0, randf_range(-YARI - 30, YARI + 30))
		if not bos_mu(p, 6.0) and maxf(absf(p.x), absf(p.z)) < YARI - 3.0:
			continue
		if _yol_yakin(p, 5.0) or Arazi.egim(p.x, p.z) > 0.55:
			continue
		if sin(p.x * 0.031 + 1.7) * cos(p.z * 0.027) < -0.25 and randf() < 0.8:
			continue
		p.y = Arazi.y(p.x, p.z) - 0.15
		sayi -= 1
		var r := randf()
		var ti := 0 if r < 0.7 else (randi() % turler.size())
		var tr: Array = turler[ti]
		var o := randf_range(float(tr[2]), float(tr[3]))
		konumlar[ti].append(Transform3D(Basis(Vector3.UP, randf() * TAU).scaled(Vector3.ONE * o), p))
		if maxf(absf(p.x), absf(p.z)) < YARI:
			var s := CollisionShape3D.new()
			var c := CylinderShape3D.new()
			c.radius = 0.5
			c.height = 4.0
			s.shape = c
			s.position = p + Vector3(0, 2, 0)
			govde.add_child(s)
			engeller.append([p, 0.8])
	for i in (0 if "agac" in test_kapat else turler.size()):
		Arazi.coklu(kok, turler[i][0], konumlar[i], not mobil, 0.0)
		if turler[i][1]:
			Arazi.coklu(kok, turler[i][1], konumlar[i], not mobil, 0.0)

	# --- kayalar
	var kmesh := []
	var kaya_adlari: Array = ["namaqualand_boulder_02", "rock_07", "rock_09"] if veri["id"] == "kor" else ["rock_moss_set_01_0", "rock_moss_set_01_2", "rock_moss_set_01_4", "rock_07", "rock_09"]
	for ad in kaya_adlari:
		kmesh.append(Arazi.ph_mesh(ad))
	var kk := []
	for i in kmesh.size():
		kk.append([])
	for i in (140 if mobil else 260):
		var p := Vector3(randf_range(-YARI - 20, YARI + 20), 0, randf_range(-YARI - 20, YARI + 20))
		if not bos_mu(p, 2.0) and maxf(absf(p.x), absf(p.z)) < YARI - 3.0:
			continue
		if _yol_yakin(p, 3.0):
			continue
		var ki := i % kmesh.size()
		var kucuk: bool = str(kaya_adlari[ki]).begins_with("rock_0")
		var o := (randf_range(1.5, 4.0) if kucuk else randf_range(0.25, 0.7)) if randf() < 0.85 else (randf_range(4.0, 7.0) if kucuk else randf_range(0.8, 1.4))
		p.y = Arazi.y(p.x, p.z) - 0.15 * o
		if kucuk:
			o *= 1.0
		kk[ki].append(Transform3D(Basis.from_euler(Vector3(randf() * 0.4, randf() * TAU, randf() * 0.4)).scaled(Vector3.ONE * o), p))
		if (o > 0.6 and not kucuk) or (kucuk and o > 5.0):
			var s := CollisionShape3D.new()
			var c := SphereShape3D.new()
			c.radius = (0.12 if kucuk else 1.2) * o
			s.shape = c
			s.position = p + Vector3(0, 0.5, 0)
			govde.add_child(s)
			engeller.append([p, (0.15 if kucuk else 1.4) * o])
	for i in (0 if "kaya" in test_kapat else kmesh.size()):
		Arazi.coklu(kok, kmesh[i], kk[i], not mobil)

	# --- düşman sürü noktaları (seviyeleri yerlerine göre)
	suru_noktalari.clear()
	deneme = 0
	while suru_noktalari.size() < 70 and deneme < 6000:
		deneme += 1
		var p := Vector3(randf_range(-YARI + 8, YARI - 8), 0, randf_range(-YARI + 8, YARI - 8))
		if Vector2(p.x, p.z).length() < KOY_YARICAP + 14.0 or not bos_mu(p, 2.0) or Arazi.egim(p.x, p.z) > 0.4:
			continue
		var uygun := true
		for en in engeller:
			if Vector2(p.x - en[0].x, p.z - en[0].z).length() < float(en[1]) + 4.0:
				uygun = false
				break
		for q in suru_noktalari:
			if q["konum"].distance_to(p) < 17.0:
				uygun = false
				break
		if uygun:
			p.y = Arazi.y(p.x, p.z)
			suru_noktalari.append({"konum": p, "seviye": seviye_noktada(p)})
	randomize()
	return govde


# ------------------------------------------------------------------ şehir
static func _kutu(kok: Node3D, boyut: Vector3, konum: Vector3, aci: float, mat: Material, golge := true) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = boyut
	m.mesh = b
	m.material_override = mat
	m.position = konum
	m.rotation.y = aci
	if not golge:
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	kok.add_child(m)
	return m


static func _cati(gen: float, der: float, yuk: float) -> ArrayMesh:
	## Beşik çatı (iki eğimli yüz + iki üçgen alın)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x := gen * 0.5 + 0.45
	var z := der * 0.5 + 0.45
	var p := [Vector3(-x, 0, -z), Vector3(x, 0, -z), Vector3(x, 0, z), Vector3(-x, 0, z), Vector3(-x, yuk, 0), Vector3(x, yuk, 0)]
	for t in [[0, 4, 5], [0, 5, 1], [3, 2, 5], [3, 5, 4], [0, 3, 4], [1, 5, 2], [0, 1, 2], [0, 2, 3]]:
		for k in t:
			st.add_vertex(p[k])
	st.generate_normals()
	return st.commit()


static func _bina(kok: Node3D, govde: StaticBody3D, p: Vector3, aci: float, gen: float, der: float, yuk: float, duvar: Material, cati: Material, tahta: Material, pencere: Material) -> void:
	var n := Node3D.new()
	n.position = p
	n.rotation.y = aci
	kok.add_child(n)
	_kutu(n, Vector3(gen + 0.3, 0.6, der + 0.3), Vector3(0, 0.3, 0), 0.0, _tas(0.35, Color(0.7, 0.68, 0.65)))
	_kutu(n, Vector3(gen, yuk, der), Vector3(0, yuk * 0.5, 0), 0.0, duvar)
	# ahşap kirişler
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			_kutu(n, Vector3(0.28, yuk, 0.28), Vector3(sx * gen * 0.5, yuk * 0.5, sz * der * 0.5), 0.0, tahta, false)
	_kutu(n, Vector3(gen + 0.1, 0.25, der + 0.1), Vector3(0, yuk * 0.55, 0), 0.0, tahta, false)
	var c := MeshInstance3D.new()
	c.mesh = _cati(gen, der, minf(gen, der) * 0.55 + 0.6)
	c.material_override = cati
	c.position.y = yuk
	n.add_child(c)
	# kapı ve pencereler (cephe +Z: meydana bakar)
	_kutu(n, Vector3(1.3, 2.3, 0.12), Vector3(0, 1.15 + 0.3, der * 0.5 + 0.03), 0.0, tahta, false)
	for x in [-gen * 0.3, gen * 0.3]:
		_kutu(n, Vector3(0.8, 0.9, 0.08), Vector3(x, yuk * 0.72, der * 0.5 + 0.03), 0.0, pencere, false)
	# baca
	if gen > 6.0:
		_kutu(n, Vector3(0.8, 2.0, 0.8), Vector3(gen * 0.3, yuk + 1.6, -der * 0.15), 0.0, _tas(0.4, Color(0.55, 0.52, 0.5)))
	var s := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(gen + 0.4, 5.0, der + 0.4)
	s.shape = bx
	govde.add_child(s)
	s.transform = Transform3D(Basis(Vector3.UP, aci), p + Vector3(0, 2.5, 0))
	engeller.append([p, maxf(gen, der) * 0.6])


static func _tas(olcek: float, ton: Color) -> StandardMaterial3D:
	return Arazi.duvar_mat("rock023_alb_ht.png", "rock023_nrm_rgh.png", olcek, ton)


static func _sehir(kok: Node3D, govde: StaticBody3D, mobil: bool) -> void:
	var dv: Array = veri["duvar"]
	var duvar := Arazi.duvar_mat(dv[0], dv[1], 0.28, dv[2])
	var tahta := Arazi.duvar_mat("tahta.jpg", "", 0.5, Color(0.45, 0.33, 0.24))
	var cati := Arazi.duvar_mat("tahta.jpg", "", 0.7, Color(0.42, 0.24, 0.18) if veri["id"] != "ayaz" else Color(0.85, 0.88, 0.95))
	var pencere := StandardMaterial3D.new()
	pencere.albedo_color = Color(0.2, 0.12, 0.05)
	pencere.emission_enabled = true
	pencere.emission = Color(1.0, 0.62, 0.25)
	pencere.emission_energy_multiplier = 1.6
	var binalar := [
		[Vector3(-17, 0, 5), PI * 0.5, 8.0, 6.0, 4.2], [Vector3(17, 0, 6), -PI * 0.5, 9.0, 6.5, 4.6],
		[Vector3(0, 0, -18), 0.0, 10.0, 6.0, 5.0], [Vector3(-15, 0, -13), PI * 0.25, 7.0, 6.0, 4.0],
		[Vector3(14, 0, -13), -PI * 0.25, 7.0, 5.5, 4.0], [Vector3(-13, 0, 16), PI * 0.78, 6.5, 5.5, 3.8],
		[Vector3(12, 0, 17), -PI * 0.8, 6.5, 5.5, 3.8], [Vector3(-22, 0, -3), PI * 0.5, 6.0, 5.0, 3.6],
		[Vector3(22, 0, -4), -PI * 0.5, 6.0, 5.0, 3.6],
	]
	for b in binalar:
		_bina(kok, govde, b[0], b[1], b[2], b[3], b[4], duvar, cati, tahta, pencere)
	# meydan: anıt (sütun + mangal ateşi)
	var tas := _tas(0.45, Color(0.75, 0.72, 0.68))
	_kutu(kok, Vector3(3.2, 0.6, 3.2), Vector3(0, 0.3, 0), 0.0, tas)
	_kutu(kok, Vector3(1.1, 3.4, 1.1), Vector3(0, 2.0, 0), PI * 0.25, tas)
	var ates := MeshInstance3D.new()
	ates.mesh = Efekt.halka_mesh(0.1, 0.6)
	ates.material_override = Efekt.parlak_mat(Color(1.0, 0.5, 0.15), 2.5)
	ates.position = Vector3(0, 3.75, 0)
	kok.add_child(ates)
	var s0 := CollisionShape3D.new()
	var c0 := CylinderShape3D.new()
	c0.radius = 1.9
	c0.height = 4.0
	s0.shape = c0
	s0.position = Vector3(0, 2, 0)
	govde.add_child(s0)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.62, 0.3)
	l.light_energy = 2.5
	l.omni_range = 16.0
	l.position = Vector3(0, 4.5, 0)
	l.visible = Efekt.isik_var()
	kok.add_child(l)
	# surlar: yolların geçtiği yerlerde kapı
	var kapilar := []
	for z in zindanlar:
		kapilar.append(atan2(z["konum"].z, z["konum"].x))
	kapilar.append(PI * 0.5)    # doğuş tarafı
	var sur := _tas(0.3, Color(0.78, 0.76, 0.72) if veri["id"] != "kor" else Color(0.9, 0.72, 0.55))
	var parca := 44
	var r := KOY_YARICAP + 1.0
	for i in parca:
		var a := TAU * (i + 0.5) / parca
		var kapi := false
		for k in kapilar:
			if absf(wrapf(a - k, -PI, PI)) < 0.12:
				kapi = true
		if kapi:
			continue
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		var uz := TAU * r / parca + 0.15
		var m := _kutu(kok, Vector3(uz, 3.6, 1.0), p + Vector3(0, 1.8, 0), -a + PI * 0.5, sur)
		if i % 4 == 0:
			_kutu(kok, Vector3(1.8, 5.0, 1.8), p + Vector3(0, 2.5, 0), -a, sur)
		var s := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = Vector3(uz, 4.0, 1.2)
		s.shape = bx
		s.transform = Transform3D(Basis(Vector3.UP, -a + PI * 0.5), p + Vector3(0, 2, 0))
		govde.add_child(s)
		m.name = "Sur"
	# meşaleler
	for k in kapilar:
		for d in [-0.16, 0.16]:
			var p := Vector3(cos(k + d) * r, 0, sin(k + d) * r)
			_kutu(kok, Vector3(0.18, 2.4, 0.18), p + Vector3(0, 1.2, 0), 0.0, tahta, false)
			var f := MeshInstance3D.new()
			f.mesh = Efekt.halka_mesh(0.0, 0.25)
			f.material_override = Efekt.parlak_mat(Color(1.0, 0.55, 0.15), 2.5)
			f.position = p + Vector3(0, 2.5, 0)
			kok.add_child(f)


static func _zindan_girisi(kok: Node3D, govde: StaticBody3D, zd: Dictionary) -> void:
	var p: Vector3 = zd["konum"]
	var giris := Node3D.new()
	kok.add_child(giris)
	giris.position = p
	giris.rotation.y = atan2(-p.x, -p.z)      # kapı şehre baksın
	var tas := Arazi.kaya_mat(veri["kaya"] * 0.85)
	tas.uv1_scale = Vector3.ONE * 0.25
	for x in [-2.4, 2.4]:
		_kutu(giris, Vector3(1.4, 5.2, 1.6), Vector3(x, 2.6, 0), 0.0, tas)
		_kutu(giris, Vector3(1.8, 0.6, 2.0), Vector3(x, 0.3, 0), 0.0, tas)
	_kutu(giris, Vector3(6.4, 1.2, 1.9), Vector3(0, 5.6, 0), 0.0, tas)
	# arkasında kaya kütlesi
	var kaya: Node3D = load("res://assets/arazi/RockB.glb").instantiate()
	for c in kaya.find_children("*", "MeshInstance3D", true, false):
		(c as MeshInstance3D).material_override = tas
	kaya.position = Vector3(0, -2.0, -8.0)
	kaya.scale = Vector3(2.4, 2.0, 1.8)
	giris.add_child(kaya)
	for x in [-6.0, 6.0]:
		var s := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = Vector3(7.5, 6, 3.0)
		s.shape = b
		govde.add_child(s)
		s.global_transform = Transform3D(Basis(Vector3.UP, giris.rotation.y), p) * Transform3D(Basis(), Vector3(x * 0.7, 3, -0.5))
	var portal := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(3.4, 5.0)
	pm.orientation = PlaneMesh.FACE_Z
	portal.mesh = pm
	var renk := Color(1.0, 0.35, 0.1) if not zd.get("final", false) else Color(0.7, 0.3, 1.0)
	portal.material_override = Efekt.parlak_mat(renk, 1.1)
	portal.position = Vector3(0, 2.5, 0.1)
	giris.add_child(portal)
	var halka := MeshInstance3D.new()
	halka.mesh = Efekt.halka_mesh(2.2, 3.0)
	halka.material_override = Efekt.parlak_mat(renk, 1.5)
	halka.position = Vector3(0, 0.08, 3.0)
	giris.add_child(halka)
	var l := Label3D.new()
	l.text = "%s\nSeviye %d+" % [zd["ad"], zd["seviye"]]
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 72
	l.pixel_size = 0.011
	l.outline_size = 16
	l.modulate = Color(1.0, 0.75, 0.4)
	l.position = Vector3(0, 7.8, 0)
	var f = load("res://assets/font/Cinzel-Black.ttf")
	if f:
		l.font = f
	giris.add_child(l)


static func giris_noktasi(zd: Dictionary) -> Vector3:
	## Zindandan çıkınca belirdiğin yer (kapının şehir tarafı)
	var p: Vector3 = zd["konum"]
	var q := p + Vector3(-p.x, 0, -p.z).normalized() * 5.0
	q.y = Arazi.y(q.x, q.z)
	return q


static func dogus() -> Vector3:
	return DOGUS
