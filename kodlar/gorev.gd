class_name Gorev
extends RefCounted
## Görev zinciri: her şehrin muhtarı bölgeye özel görevler verir. Görev bitince ödül hemen verilir
## (tecrübe, altın, Eliksir). Türler: oldur (her tür ya da belirli tür), elit, zindan, seviye.

## Bölge şablonu: [tür, hedef, adet, seviye_kayması (en az düşman seviyesi), ödül çarpanı, eliksir]
const SABLON := [
	["oldur", "", 10, 0, 0.35, 2],
	["oldur", "minyon", 15, 0, 0.35, 2],
	["seviye", "", 5, 0, 0.3, 2],
	["zindan", 0, 1, 0, 0.5, 3],
	["oldur", "haydut", 15, 3, 0.35, 2],
	["elit", "", 3, 0, 0.4, 3],
	["seviye", "", 10, 0, 0.3, 2],
	["zindan", 1, 1, 0, 0.5, 4],
	["oldur", "", 40, 13, 0.45, 3],
	["elit", "", 6, 10, 0.45, 4],
	["seviye", "", 16, 0, 0.3, 3],
	["zindan", 2, 1, 0, 0.6, 5],
	["seviye", "", 20, 0, 0.4, 5],
]
const TUR_ADI := {"minyon": "iskelet", "haydut": "haydut", "savasci": "muhafız", "buyucu": "büyücü"}


## Tüm zincir (3 bölge × 13 görev)
static func liste() -> Array:
	var l := []
	for b in Bolge.BOLGELER.size():
		var bv: Dictionary = Bolge.BOLGELER[b]
		var taban: int = int(bv["min"]) - 1 if b > 0 else 0
		for s in SABLON:
			var g := {"bolge": b, "tur": s[0], "adet": s[2], "carpan": s[4], "eliksir": int(s[5]) * (b + 1)}
			match s[0]:
				"oldur":
					g["hedef"] = s[1]
					g["min_sv"] = taban + int(s[3]) if int(s[3]) > 0 else 0
					g["adet"] = int(s[2]) + b * 10
					var ne: String = TUR_ADI.get(s[1], "düşman")
					g["metin"] = "%s bölgesinde %d %s öldür" % [bv["ad"], g["adet"], ne] + (" (seviye %d+)" % g["min_sv"] if g["min_sv"] > 0 else "")
				"elit":
					g["min_sv"] = taban + int(s[3]) if int(s[3]) > 0 else 0
					g["adet"] = int(s[2]) + b * 2
					g["metin"] = "%d elit düşman öldür" % g["adet"] + (" (seviye %d+)" % g["min_sv"] if g["min_sv"] > 0 else "")
				"zindan":
					var z: Dictionary = bv["zindanlar"][int(s[1])]
					g["hedef"] = z["id"]
					g["metin"] = "%s zindanını temizle (seviye %d+)" % [z["ad"], z["seviye"]]
				"seviye":
					g["adet"] = taban + int(s[2]) if b > 0 else int(s[2])
					if b > 0 and int(s[2]) == 20:
						g["adet"] = int(bv["max"])
					g["metin"] = "Seviye %d'e ulaş" % g["adet"]
			l.append(g)
	return l


static var _liste: Array = []


static func al(no: int) -> Dictionary:
	if _liste.is_empty():
		_liste = liste()
	return _liste[no] if no >= 0 and no < _liste.size() else {}


static func toplam() -> int:
	if _liste.is_empty():
		_liste = liste()
	return _liste.size()


## Görev olayına göre ilerleme artışı (0 ya da 1)
static func ilerler_mi(g: Dictionary, olay: String, veri: Variant, bolge: int) -> bool:
	if g.is_empty() or int(g["bolge"]) != bolge:
		return false
	match g["tur"]:
		"oldur":
			if olay != "oldur":
				return false
			var d: Dusman = veri
			return (g["hedef"] == "" or d.tur == g["hedef"]) and d.seviye >= int(g["min_sv"])
		"elit":
			if olay != "oldur":
				return false
			var d2: Dusman = veri
			return d2.elit and d2.seviye >= int(g["min_sv"])
		"zindan":
			return olay == "zindan" and veri == g["hedef"]
	return false
