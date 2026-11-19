class_name Esya
extends RefCounted
## Eşyalar: nadirlik, sınıfa özel adlar, setler (son set yalnız son zindanda), Eliksir ile artı basma
## (+10'dan sonra yanma: +0'a düşer), mana taşı yuvaları ve gerçekçi eşya resimleri.

const NADIRLIK := [
	{"ad": "Sıradan", "renk": Color(0.8, 0.8, 0.8), "carpan": 1.0, "ozellik": 1, "sans": 52.0, "yuva": 1},
	{"ad": "Büyülü", "renk": Color(0.35, 0.62, 1.0), "carpan": 1.3, "ozellik": 2, "sans": 30.0, "yuva": 2},
	{"ad": "Nadir", "renk": Color(1.0, 0.85, 0.25), "carpan": 1.65, "ozellik": 3, "sans": 14.0, "yuva": 2},
	{"ad": "Efsanevi", "renk": Color(1.0, 0.5, 0.1), "carpan": 2.1, "ozellik": 4, "sans": 4.0, "yuva": 3},
	{"ad": "Set", "renk": Color(0.35, 1.0, 0.45), "carpan": 2.3, "ozellik": 4, "sans": 0.0, "yuva": 4},
]
const SET := 4
const YUVALAR := ["Silah", "Zırh", "Kask", "Eldiven", "Çizme", "Yüzük", "Kanat"]
const SET_YUVALARI := ["Silah", "Zırh", "Kask", "Eldiven", "Çizme"]
const ANAHTAR := {"Silah": "silah", "Zırh": "zirh", "Kask": "kask", "Eldiven": "eldiven", "Çizme": "cizme", "Yüzük": "yuzuk", "Kanat": "kanat"}

## Malzeme kademesi (seviyeye göre): 0 demir (1-15), 1 çelik (16-30), 2 ayaz (31-45), 3 kor (46-60), 4 son set
const ADLAR := {
	"muhafiz": {
		"Silah": ["Demir Kılıç", "Çelik Uzun Kılıç", "Ayaz Çeliği Kılıç", "Kor Demiri Kılıç", "Son Kanatlı Kılıcı"],
		"Zırh": ["Zincir Zırh", "Plaka Zırh", "Buz Plakası", "Kor Plakası", "Son Kanatlı Zırhı"],
		"Kask": ["Demir Miğfer", "Gladyatör Miğferi", "Ayaz Miğferi", "Kor Miğferi", "Son Kanatlı Miğferi"],
		"Eldiven": ["Deri Eldiven", "Demir Eldiven", "Ayaz Eldiveni", "Kor Eldiveni", "Son Kanatlı Eldiveni"],
		"Çizme": ["Deri Çizme", "Demir Çizme", "Ayaz Çizmesi", "Kor Çizmesi", "Son Kanatlı Çizmesi"],
	},
	"avci": {
		"Silah": ["Av Yayı", "Uzun Yay", "Kırağı Yayı", "Kor Yayı", "Son Kanatlı Yayı"],
		"Zırh": ["Deri Yelek", "Elf Zırhı", "Kürk Zırh", "Kor Derisi", "Son Kanatlı Yeleği"],
		"Kask": ["Deri Başlık", "Elf Başlığı", "Kürk Kukuleta", "Gölge Kukuleta", "Son Kanatlı Başlığı"],
		"Eldiven": ["Okçu Eldiveni", "Elf Eldiveni", "Kürk Eldiven", "Kor Eldiveni", "Son Kanatlı Eldiveni"],
		"Çizme": ["Yumuşak Çizme", "Elf Çizmesi", "Kürk Çizme", "Kor Çizmesi", "Son Kanatlı Çizmesi"],
	},
	"buyucu": {
		"Silah": ["Meşe Asa", "Kül Asası", "Buz Asası", "Kor Asası", "Son Kanatlı Asası"],
		"Zırh": ["Keten Cüppe", "Büyücü Cüppesi", "Ayaz Cüppesi", "Kor Cüppesi", "Son Kanatlı Cüppesi"],
		"Kask": ["Kumaş Başlık", "Büyücü Tacı", "Buz Diademi", "Kor Tacı", "Son Kanatlı Tacı"],
		"Eldiven": ["Kumaş Eldiven", "Rün Eldiveni", "Ayaz Eldiveni", "Kor Eldiveni", "Son Kanatlı Eldiveni"],
		"Çizme": ["Kumaş Çizme", "Rün Çizmesi", "Ayaz Çizmesi", "Kor Çizmesi", "Son Kanatlı Çizmesi"],
	},
	"ortak": {
		"Yüzük": ["Bakır Yüzük", "Gümüş Yüzük", "Safir Yüzük", "Yakut Yüzük", "Son Kanatlı Mührü"],
		"Kanat": ["Tüy Pelerin", "Kartal Kanadı", "Ayaz Kanadı", "Kor Kanadı", "Son Kanatlı Kanatları"],
	},
}
## Elde görünen 3B model (Blender'da modellenmiş gerçekçi kılıç/asa; yay kodla çizilir)
const SILAH_MODEL := {"muhafiz": ["kilic_0", "kilic_1", "kilic_2", "kilic_3", "kilic_4"],
	"avci": ["yay", "yay", "yay", "yay", "yay"], "buyucu": ["asa_0", "asa_1", "asa_2", "asa_3", "asa_4"]}

## Setler: kademe -> sınıf -> ad. Parça bonusları: 2 parça hasar, 3 parça can, 5 parça kritik + hız
const SETLER := [
	{"muhafiz": "Demir Yemin", "avci": "Rüzgâr İzi", "buyucu": "Kül Çırağı", "seviye": 15, "bonus": 0.08},
	{"muhafiz": "Ayaz Bekçisi", "avci": "Kırağı Avcısı", "buyucu": "Buz Bilgesi", "seviye": 32, "bonus": 0.11},
	{"muhafiz": "Kor Lordu", "avci": "Kızıl Gölge", "buyucu": "Kor Kâhini", "seviye": 48, "bonus": 0.14},
	{"muhafiz": "Son Kanatlı", "avci": "Son Kanatlı", "buyucu": "Son Kanatlı", "seviye": 58, "bonus": 0.2},
]

## Özellik türleri: anahtar -> [Türkçe ad, temel değer, seviye başına artış]
const OZELLIKLER := {
	"hasar": ["hasar", 6.0, 1.7],
	"can": ["can", 30.0, 10.0],
	"kritik": ["% kritik", 2.0, 0.08],
	"hiz": ["% hız", 3.0, 0.05],
	"mana": ["mana", 12.0, 2.0],
	"zirh": ["% zırh", 2.0, 0.1],
}
const YUVA_ANA := {"Silah": "hasar", "Zırh": "can", "Kask": "zirh", "Eldiven": "hasar", "Çizme": "hiz", "Yüzük": "kritik", "Kanat": "can"}
const YUVA_AGIRLIK := {"Silah": 1.0, "Zırh": 1.0, "Kask": 1.0, "Eldiven": 0.45, "Çizme": 1.0, "Yüzük": 1.0, "Kanat": 0.6}

## Mana taşları: tür -> [ad, I, II, III, IV]
const TASLAR := {
	"hasar": ["Hasar Taşı", 4.0, 9.0, 15.0, 22.0],
	"can": ["Can Taşı", 25.0, 55.0, 95.0, 140.0],
	"kritik": ["Kritik Taşı", 1.0, 1.8, 2.6, 3.5],
	"hiz": ["Hız Taşı", 1.0, 1.6, 2.3, 3.0],
	"zirh": ["Zırh Taşı", 1.0, 1.6, 2.3, 3.0],
	"mana": ["Mana Taşı", 10.0, 20.0, 32.0, 45.0],
}
const ROMEN := ["I", "II", "III", "IV"]
const ARTI_MAX := 15


static func kademe(seviye: int) -> int:
	return clampi((seviye - 1) / 15, 0, 3)


static func _nadirlik_sec(en_az: int) -> int:
	var toplam := 0.0
	for i in 4:
		toplam += NADIRLIK[i]["sans"]
	var zar := randf() * toplam
	var nad := 0
	for i in 4:
		zar -= NADIRLIK[i]["sans"]
		if zar <= 0:
			nad = i
			break
	return clampi(maxi(nad, en_az), 0, 3)


static func _ozellik_uret(yuva: String, seviye: int, carpan: float, adet: int) -> Dictionary:
	var ozellikler := {}
	var ana: String = YUVA_ANA[yuva]
	var anahtarlar := OZELLIKLER.keys()
	anahtarlar.erase(ana)
	anahtarlar.shuffle()
	var secilen := [ana] + anahtarlar.slice(0, adet - 1)
	for k in secilen:
		var o: Array = OZELLIKLER[k]
		var deger: float = (o[1] + o[2] * seviye) * carpan * randf_range(0.85, 1.15)
		if k == ana:
			deger *= YUVA_AGIRLIK[yuva]
		ozellikler[k] = roundf(deger * 10.0) / 10.0 if k in ["kritik", "hiz", "zirh"] else roundf(deger)
	return ozellikler


## Sıradan/büyülü/nadir/efsanevi eşya üretir (seviye = düşen düşmanın seviyesi).
static func uret(seviye: int, en_az_nadirlik := 0, sinif := "muhafiz") -> Dictionary:
	if sinif == "":
		sinif = "muhafiz"
	var nad := _nadirlik_sec(en_az_nadirlik)
	var yuva: String = YUVALAR.pick_random()
	var kd := kademe(seviye)
	var grup := "ortak" if yuva in ["Yüzük", "Kanat"] else sinif
	var ad: String = ADLAR[grup][yuva][kd]
	if nad == 3:
		ad = ["Kadim ", "Efsane ", "Yitik ", "Kutsal "].pick_random() + ad
	elif nad >= 1:
		ad = ["Keskin ", "Sağlam ", "Parlak ", "Usta İşi ", "Büyülü ", "Yanık "].pick_random() + ad
	var e := {"ad": ad, "yuva": yuva, "nadirlik": nad, "seviye": seviye, "gereken": maxi(1, seviye - 2),
		"ozellik": _ozellik_uret(yuva, seviye, NADIRLIK[nad]["carpan"], int(NADIRLIK[nad]["ozellik"])),
		"sinif": sinif if grup != "ortak" else "", "kademe": kd, "arti": 0, "set": -1,
		"yuva_sayisi": int(NADIRLIK[nad]["yuva"]) + (1 if randf() < 0.3 else 0), "taslar": []}
	e["model"] = SILAH_MODEL[sinif][kd] if yuva == "Silah" else ""
	return e


## Set parçası (kademe 0-3; 3 = Son Kanatlı, yalnız son zindanda düşer)
static func set_uret(set_kademe: int, sinif: String, yuva := "") -> Dictionary:
	if yuva == "":
		yuva = SET_YUVALARI.pick_random()
	var s: Dictionary = SETLER[set_kademe]
	var seviye: int = s["seviye"]
	var gorsel: int = [0, 2, 3, 4][set_kademe]
	var e := {"ad": "%s · %s" % [s[sinif], ADLAR[sinif][yuva][gorsel].split(" ")[-1]], "yuva": yuva, "nadirlik": SET,
		"seviye": seviye, "gereken": seviye, "ozellik": _ozellik_uret(yuva, seviye, NADIRLIK[SET]["carpan"] * (1.3 if set_kademe == 3 else 1.0), 4),
		"sinif": sinif, "kademe": gorsel, "arti": 0, "set": set_kademe, "yuva_sayisi": 4 if set_kademe < 3 else 5, "taslar": []}
	e["model"] = SILAH_MODEL[sinif][gorsel] if yuva == "Silah" else ""
	return e


## Set bonusları: takılı parçalara göre ek oranlar
static func set_bonuslari(esyalar: Dictionary) -> Dictionary:
	var sayac := {}
	for y in esyalar:
		var s := int(esyalar[y].get("set", -1))
		if s >= 0:
			sayac[s] = int(sayac.get(s, 0)) + 1
	var b := {"hasar": 0.0, "can": 0.0, "kritik": 0.0, "hiz": 0.0}
	for s in sayac:
		var o: float = SETLER[s]["bonus"]
		if sayac[s] >= 2:
			b["hasar"] += o
		if sayac[s] >= 3:
			b["can"] += o * 1.2
		if sayac[s] >= 5:
			b["kritik"] += o * 40.0
			b["hiz"] += o * 50.0
	return b


static func set_sayisi(esyalar: Dictionary, s: int) -> int:
	var n := 0
	for y in esyalar:
		if int(esyalar[y].get("set", -1)) == s:
			n += 1
	return n


## Yerde ve elde görünen 3B model (yay kodla çizilir)
static func model_olustur(model: String) -> Node3D:
	if model == "":
		return null
	if model == "yay":
		return yay_modeli()
	var yol := "res://assets/silah/%s.glb" % model
	if not ResourceLoader.exists(yol):
		return null
	return load(yol).instantiate()


static func yay_modeli() -> Node3D:
	var kok := Node3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 16
	var kalinlik := 0.05
	for i in n:
		var a0 := lerpf(-1.1, 1.1, float(i) / n)
		var a1 := lerpf(-1.1, 1.1, float(i + 1) / n)
		var p0 := Vector3(-(1.0 - cos(a0)) * 0.55, sin(a0) * 0.7, 0)
		var p1 := Vector3(-(1.0 - cos(a1)) * 0.55, sin(a1) * 0.7, 0)
		var w0 := kalinlik * (1.0 - absf(a0) * 0.4)
		var w1 := kalinlik * (1.0 - absf(a1) * 0.4)
		for k in 4:
			var o0 := Vector3(cos(k * PI * 0.5), 0, sin(k * PI * 0.5))
			var o1 := Vector3(cos((k + 1) * PI * 0.5), 0, sin((k + 1) * PI * 0.5))
			st.add_vertex(p0 + o0 * w0); st.add_vertex(p1 + o0 * w1); st.add_vertex(p1 + o1 * w1)
			st.add_vertex(p0 + o0 * w0); st.add_vertex(p1 + o1 * w1); st.add_vertex(p0 + o1 * w0)
	st.generate_normals()
	var govde := MeshInstance3D.new()
	govde.mesh = st.commit()
	var tahta := StandardMaterial3D.new()
	tahta.albedo_color = Color(0.45, 0.28, 0.14)
	tahta.roughness = 0.7
	govde.material_override = tahta
	kok.add_child(govde)
	var ip := MeshInstance3D.new()
	var b := BoxMesh.new()
	var uc := Vector3(-(1.0 - cos(1.1)) * 0.55, sin(1.1) * 0.7, 0)
	b.size = Vector3(0.012, uc.y * 2.0, 0.012)
	ip.mesh = b
	ip.position = Vector3(uc.x, 0, 0)
	var ipm := StandardMaterial3D.new()
	ipm.albedo_color = Color(0.92, 0.9, 0.85)
	ip.material_override = ipm
	kok.add_child(ip)
	kok.position.y = 0.15
	return kok


static func puan(e: Dictionary) -> float:
	if e.is_empty():
		return 0.0
	var p := 0.0
	var agirlik := {"hasar": 3.0, "can": 0.5, "kritik": 4.0, "hiz": 3.0, "mana": 0.6, "zirh": 4.0}
	for k in OZELLIKLER:
		p += deger(e, k) * agirlik.get(k, 1.0)
	return p


static func ozet(e: Dictionary) -> String:
	var parca := []
	for k in e["ozellik"]:
		var v := snappedf(deger(e, k), 0.1)
		parca.append("+%s %s" % [str(v), OZELLIKLER[k][0]])
	return ", ".join(parca)


static func renk(e: Dictionary) -> Color:
	return NADIRLIK[int(e["nadirlik"])]["renk"]


static func arti_carpani(arti: int) -> float:
	## +1..+10: her biri %10, +11..+15: her biri %15
	return 1.0 + 0.1 * mini(arti, 10) + 0.15 * maxi(0, arti - 10)


## Özellik değeri: temel × artı çarpanı + takılı mana taşları
static func deger(e: Dictionary, k: String) -> float:
	var v := float(e["ozellik"].get(k, 0.0)) * arti_carpani(int(e.get("arti", 0)))
	for t in e.get("taslar", []):
		if t["tur"] == k:
			v += tas_degeri(t)
	return v


static func tam_ad(e: Dictionary) -> String:
	var a := int(e.get("arti", 0))
	return ("+%d " % a if a > 0 else "") + str(e["ad"])


# ------------------------------------------------------------------ artı basma (Eliksir)
static func eliksir_gereken(arti: int) -> int:
	return 1 if arti < 5 else (2 if arti < 10 else 3)


static func altin_gereken(e: Dictionary) -> int:
	var a := int(e.get("arti", 0))
	return int((30 + int(e["seviye"]) * 5) * (a + 1) * (1.0 + int(e["nadirlik"]) * 0.4))


static func basari_sansi(arti: int) -> float:
	## şu anki artıdan bir üstüne çıkma şansı
	var tablo := [1.0, 0.95, 0.9, 0.85, 0.8, 0.72, 0.64, 0.56, 0.48, 0.4, 0.35, 0.3, 0.25, 0.2, 0.15]
	return tablo[clampi(arti, 0, tablo.size() - 1)]


static func yanma_riski(arti: int) -> bool:
	return arti >= 10


## Dönüş: "basari", "basarisiz" (malzeme gider), "yandi" (+0'a düşer)
static func arti_bas(e: Dictionary) -> String:
	var a := int(e.get("arti", 0))
	if randf() < basari_sansi(a):
		e["arti"] = a + 1
		return "basari"
	if yanma_riski(a):
		e["arti"] = 0
		return "yandi"
	return "basarisiz"


# ------------------------------------------------------------------ mana taşları
static func tas_uret(seviye: int) -> Dictionary:
	return {"tur": TASLAR.keys().pick_random(), "kademe": kademe(seviye)}


static func tas_anahtar(t: Dictionary) -> String:
	return "%s_%d" % [t["tur"], int(t["kademe"])]


static func tas_coz(anahtar: String) -> Dictionary:
	var p := anahtar.rsplit("_", true, 1)
	return {"tur": p[0], "kademe": int(p[1])}


static func tas_degeri(t: Dictionary) -> float:
	return float(TASLAR[t["tur"]][int(t["kademe"]) + 1])


static func tas_adi(t: Dictionary) -> String:
	return "%s %s" % [TASLAR[t["tur"]][0], ROMEN[int(t["kademe"])]]


static func tas_metni(t: Dictionary) -> String:
	return "+%s %s" % [str(snappedf(tas_degeri(t), 0.1)), OZELLIKLER[t["tur"]][0]]


# ------------------------------------------------------------------ resimler
static var _ikonlar := {}


static func ikon(e: Dictionary) -> Texture2D:
	var grup: String = e.get("sinif", "") if e.get("sinif", "") != "" else "ortak"
	var yol := "res://assets/esya_ikon/%s_%s_%d.png" % [grup, ANAHTAR.get(e["yuva"], "silah"), int(e.get("kademe", 0))]
	return _ikon_yukle(yol)


static func tas_ikon(t: Dictionary) -> Texture2D:
	return _ikon_yukle("res://assets/esya_ikon/tas_%s.png" % t["tur"])


static func eliksir_ikon() -> Texture2D:
	return _ikon_yukle("res://assets/esya_ikon/eliksir.png")


static func _ikon_yukle(yol: String) -> Texture2D:
	if not _ikonlar.has(yol):
		_ikonlar[yol] = load(yol) if ResourceLoader.exists(yol) else null
	return _ikonlar[yol]


## Eşya ayrıntısı (envanter ve demircide üzerine gelince / dokununca)
static func ayrinti(e: Dictionary, kahraman: Node, karsi := {}) -> String:
	var r := renk(e).to_html(false)
	var t := "[font_size=24][b][color=#%s]%s[/color][/b][/font_size]\n" % [r, tam_ad(e)]
	var tur: String = NADIRLIK[int(e["nadirlik"])]["ad"]
	if int(e.get("set", -1)) >= 0:
		tur = "Set eşyası"
	t += "[color=#bbbbbb]%s · %s · Eşya seviyesi %d[/color]\n" % [tur, e["yuva"], int(e["seviye"])]
	var gereken := int(e.get("gereken", 1))
	var yetersiz := kahraman != null and int(kahraman.seviye) < gereken
	t += "[color=#%s]Gereken seviye %d[/color]\n\n" % ["ff5544" if yetersiz else "999999", gereken]
	for k in OZELLIKLER:
		var v := snappedf(float(e["ozellik"].get(k, 0.0)) * arti_carpani(int(e.get("arti", 0))), 0.1)
		if v == 0:
			continue
		var satir := "+%s %s" % [str(v), OZELLIKLER[k][0]]
		if not karsi.is_empty():
			var fark := snappedf(deger(e, k) - deger(karsi, k), 0.1)
			if fark > 0:
				satir += "  [color=#66ff66](▲%s)[/color]" % str(fark)
			elif fark < 0:
				satir += "  [color=#ff6655](▼%s)[/color]" % str(-fark)
		t += satir + "\n"
	var arti := int(e.get("arti", 0))
	if arti > 0:
		t += "[color=#ffcc55]Artı +%d: özellikler ×%s[/color]\n" % [arti, str(snappedf(arti_carpani(arti), 0.01))]
	# mana taşı yuvaları
	var taslar: Array = e.get("taslar", [])
	t += "\n[color=#88ccff]Mana taşları (%d/%d)[/color]\n" % [taslar.size(), int(e.get("yuva_sayisi", 1))]
	for i in int(e.get("yuva_sayisi", 1)):
		if i < taslar.size():
			t += "  ◆ %s: %s\n" % [tas_adi(taslar[i]), tas_metni(taslar[i])]
		else:
			t += "  [color=#666666]◇ boş yuva[/color]\n"
	var s := int(e.get("set", -1))
	if s >= 0 and kahraman != null:
		var adet := set_sayisi(kahraman.esyalar, s)
		var o: float = SETLER[s]["bonus"]
		var snf: String = e.get("sinif", "muhafiz")
		t += "\n[color=#66ff77]%s seti (%d/5)[/color]\n" % [SETLER[s][snf], adet]
		for satir in [[2, "+%%%d hasar" % int(o * 100)], [3, "+%%%d can" % int(o * 120)], [5, "+%%%d kritik, +%%%d hız" % [int(o * 40), int(o * 50)]]]:
			var renk_s := "66ff77" if adet >= satir[0] else "666666"
			t += "[color=#%s]  %d parça: %s[/color]\n" % [renk_s, satir[0], satir[1]]
	if arti < ARTI_MAX:
		var sans := int(basari_sansi(arti) * 100)
		t += "\n[color=#cccccc]+%d için: %d Eliksir · %d altın · başarı %%%d[/color]" % [arti + 1, eliksir_gereken(arti), altin_gereken(e), sans]
		if yanma_riski(arti):
			t += "\n[color=#ff5544]Dikkat: başarısız olursa eşya yanar ve +0'a düşer![/color]"
	return t
