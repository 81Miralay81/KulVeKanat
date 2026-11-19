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


static func uret(seviye: int, en_az_nadirlik := 0) -> Dictionary:
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
	var ad: String
	if nad == 3:
		ad = EFSANEVI_ADLAR.pick_random()
	else:
		ad = "%s %s" % [ONEKLER.pick_random(), ISIMLER[yuva].pick_random()]
	return {"ad": ad, "yuva": yuva, "nadirlik": nad, "ozellik": ozellikler, "seviye": seviye}


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
