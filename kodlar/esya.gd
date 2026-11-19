class_name Esya
extends RefCounted
## Rastgele özellikli eşyalar.

const NADIRLIK := [
	{"ad": "Sıradan", "renk": Color(0.78, 0.78, 0.78), "carpan": 1.0, "ozellik": 1, "sans": 50.0},
	{"ad": "Büyülü", "renk": Color(0.35, 0.6, 1.0), "carpan": 1.35, "ozellik": 2, "sans": 30.0},
	{"ad": "Nadir", "renk": Color(1.0, 0.85, 0.25), "carpan": 1.8, "ozellik": 3, "sans": 14.0},
	{"ad": "Efsanevi", "renk": Color(1.0, 0.5, 0.1), "carpan": 2.6, "ozellik": 4, "sans": 5.0},
]
const YUVALAR := ["Silah", "Zırh", "Kask", "Yüzük", "Kanat"]
const ISIMLER := {
	"Silah": ["Kılıç", "Pala", "Balta", "Kor Kılıcı", "Yarıcı"],
	"Zırh": ["Zırh", "Göğüslük", "Kül Zırhı", "Plaka Zırh"],
	"Kask": ["Miğfer", "Kask", "Taç", "Başlık"],
	"Yüzük": ["Yüzük", "Mühür", "Halka"],
	"Kanat": ["Kanat", "Tüy Pelerin", "Kor Kanadı"],
}
## Sınıfa göre eşya adları ve yerde/elinde görünen modeller (KayKit, CC0)
const SINIF_ESYA := {
	"muhafiz": {
		"Silah": [["Kılıç", "sword_2handed"], ["Savaş Baltası", "axe_2handed"], ["Kor Kılıcı", "sword_2handed_color"], ["Gladyatör Kılıcı", "sword_2handed"]],
		"Zırh": [["Yuvarlak Kalkan", "shield_round"], ["Kule Kalkanı", "shield_square"], ["Dikenli Kalkan", "shield_spikes"], ["Arma Kalkanı", "shield_badge"]],
		"Kask": [["Miğfer", ""], ["Gladyatör Miğferi", ""], ["Savaş Kaskı", ""]],
	},
	"avci": {
		"Silah": [["Av Yayı", "yay"], ["Uzun Yay", "yay"], ["Elf Yayı", "yay"], ["Gölge Yayı", "yay"]],
		"Zırh": [["Deri Zırh", ""], ["Elf Pelerini", ""], ["Gölge Yeleği", ""]],
		"Kask": [["Başlık", ""], ["Elf Başlığı", ""], ["Avcı Kukuletası", ""]],
	},
	"buyucu": {
		"Silah": [["Asa", "staff"], ["Kül Asası", "staff"], ["Değnek", "wand"], ["Kor Değneği", "wand"]],
		"Zırh": [["Cüppe", ""], ["Kül Cüppesi", ""], ["Büyücü Pelerini", ""]],
		"Kask": [["Taç", ""], ["Büyücü Tacı", ""], ["Kor Diademi", ""]],
	},
}
const ONEKLER := ["Küllü", "Yanık", "Kızıl", "Kor", "Alevli", "Kadim", "Gölge", "Fırtına", "Demir"]
const EFSANEVI_ADLAR := ["Kor Kalbi", "Son Kanatlı'nın Yemini", "Morvaş'ın Laneti", "Garran'ın Pençesi", "Yarık Bekçisi"]

## Özellik türleri: anahtar -> [Türkçe ad, temel değer, seviye başına artış]
const OZELLIKLER := {
	"hasar": ["hasar", 6.0, 1.6],
	"can": ["can", 30.0, 9.0],
	"kritik": ["% kritik", 2.0, 0.08],
	"hiz": ["% hız", 3.0, 0.05],
	"mana": ["mana", 12.0, 2.0],
	"zirh": ["% zırh", 2.0, 0.1],
}
const YUVA_ANA := {"Silah": "hasar", "Zırh": "can", "Kask": "zirh", "Yüzük": "kritik", "Kanat": "hiz"}


static func uret(seviye: int, en_az_nadirlik := 0, sinif := "") -> Dictionary:
	var toplam := 0.0
	for n in NADIRLIK:
		toplam += n["sans"]
	var zar := randf() * toplam
	var nad := 0
	for i in NADIRLIK.size():
		zar -= NADIRLIK[i]["sans"]
		if zar <= 0:
			nad = i
			break
	nad = max(nad, en_az_nadirlik)
	var bilgi: Dictionary = NADIRLIK[nad]
	var yuva: String = YUVALAR.pick_random()
	var ozellikler := {}
	var ana: String = YUVA_ANA[yuva]
	var anahtarlar := OZELLIKLER.keys()
	anahtarlar.erase(ana)
	anahtarlar.shuffle()
	var secilen := [ana] + anahtarlar.slice(0, int(bilgi["ozellik"]) - 1)
	for k in secilen:
		var o: Array = OZELLIKLER[k]
		var deger: float = (o[1] + o[2] * seviye) * bilgi["carpan"] * randf_range(0.8, 1.2)
		ozellikler[k] = roundf(deger * 10.0) / 10.0 if k in ["kritik", "hiz", "zirh"] else roundf(deger)
	var temel_ad: String = ISIMLER[yuva].pick_random()
	var model := ""
	if sinif != "" and SINIF_ESYA.has(sinif) and SINIF_ESYA[sinif].has(yuva):
		var secim: Array = SINIF_ESYA[sinif][yuva].pick_random()
		temel_ad = secim[0]
		model = secim[1]
	var ad: String
	if nad == 3:
		ad = "%s (%s)" % [EFSANEVI_ADLAR.pick_random(), temel_ad]
	else:
		ad = "%s %s" % [ONEKLER.pick_random(), temel_ad]
	return {"ad": ad, "yuva": yuva, "nadirlik": nad, "ozellik": ozellikler, "seviye": seviye, "model": model, "sinif": sinif}


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
		var p0 := Vector3(sin(a0) * 0.0 - (1.0 - cos(a0)) * 0.55, sin(a0) * 0.7, 0)
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
	for k in e["ozellik"]:
		p += deger(e, k) * agirlik.get(k, 1.0)
	return p


static func ozet(e: Dictionary) -> String:
	var parca := []
	for k in e["ozellik"]:
		var v := snappedf(deger(e, k), 0.1)
		parca.append("+%s %s" % [str(v), OZELLIKLER[k][0]])
	return ", ".join(parca)


static func renk(e: Dictionary) -> Color:
	return NADIRLIK[e["nadirlik"]]["renk"]


## Demirci yükseltmesi: her +1 tüm özellikleri %12 artırır.
static func deger(e: Dictionary, k: String) -> float:
	return float(e["ozellik"].get(k, 0.0)) * (1.0 + 0.12 * int(e.get("arti", 0)))


static func tam_ad(e: Dictionary) -> String:
	var a := int(e.get("arti", 0))
	return ("+%d " % a if a > 0 else "") + str(e["ad"])
