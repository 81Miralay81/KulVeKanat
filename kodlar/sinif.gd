class_name Sinif
extends RefCounted
## Oynanabilir sınıflar: model, temel özellikler, yetenek adları ve simgeleri.

const LISTE := ["muhafiz", "avci", "buyucu"]

const VERI := {
	"muhafiz": {
		"ad": "Kılıç Muhafızı", "model": "Knight", "sakla": ["2H_Sword"], "bekleme_anim": "2H_Melee_Idle",
		"rol": "Yakın dövüş · çok dayanıklı (zırh %32)",
		"aciklama": "İki elli kılıçla sürüleri biçer.\nKor Kasırgası ile etrafını yakar,\nYer Yarma ile önünü temizler.",
		"can": 420.0, "mana": 110.0, "hasar": 28.0, "kritik": 8.0, "zirh": 32.0, "hiz": 0.0, "kacinma": 0.0,
		"kanat": Color(1.0, 0.42, 0.08), "puan": [5, 2, 1, 5],
		"yetenekler": {"saldir": ["Kılıç Darbesi", "kilic"], "yetenek1": ["Kor Kasırgası", "kasirga"],
			"yetenek2": ["Yer Yarma", "yarik"], "yetenek3": ["Kanat Atılımı", "kanat"],
			"yetenek4": ["Meteor Yağmuru", "meteor"], "son_vurus": ["Kanat Açılımı", "son"], "iksir": ["İksir", "iksir"]},
	},
	"avci": {
		"ad": "Gölge Avcı", "model": "Rogue_Hooded", "sakla": ["__yay__"], "varsayilan": "yay", "bekleme_anim": "Idle",
		"rol": "Uzaktan · hızlı · %18 kaçınma",
		"aciklama": "Elf okçu: yayıyla uzaktan vurur.\nÇoklu Atış ve Ok Yağmuru ile kalabalığı,\nZehir Bombası ile elitleri eritir.",
		"can": 290.0, "mana": 120.0, "hasar": 24.0, "kritik": 16.0, "zirh": 12.0, "hiz": 10.0, "kacinma": 18.0,
		"kanat": Color(0.7, 0.3, 1.0), "puan": [3, 5, 2, 3],
		"yetenekler": {"saldir": ["Ok Atışı", "yay"], "yetenek1": ["Çoklu Atış", "coklu"],
			"yetenek2": ["Ok Yağmuru", "okyagmuru"], "yetenek3": ["Gölge Adımı", "golge"],
			"yetenek4": ["Zehir Bombası", "zehir"], "son_vurus": ["Gölge Fırtınası", "golgefirtina"], "iksir": ["İksir", "iksir"]},
	},
	"buyucu": {
		"ad": "Kül Büyücü", "model": "Mage", "sakla": ["2H_Staff"], "bekleme_anim": "Idle",
		"rol": "Alan hasarı · kırılgan",
		"aciklama": "Ateş topları atar, düşmanları dondurur.\nAlev Halkası ve Kül Kıyameti ile\nekranı ateşe verir.",
		"can": 220.0, "mana": 170.0, "hasar": 32.0, "kritik": 10.0, "zirh": 3.0, "hiz": 4.0, "kacinma": 6.0,
		"kanat": Color(0.35, 0.7, 1.0), "puan": [2, 3, 5, 1],
		"yetenekler": {"saldir": ["Ateş Topu", "atestopu"], "yetenek1": ["Alev Halkası", "alevhalkasi"],
			"yetenek2": ["Buz Fırtınası", "buz"], "yetenek3": ["Işınlanma", "isinlanma"],
			"yetenek4": ["Meteor Yağmuru", "meteor"], "son_vurus": ["Kül Kıyameti", "kiyamet"], "iksir": ["İksir", "iksir"]},
	},
}

static var _ikon_onbellek := {}


static func ikon(sinif: String, eylem: String) -> Texture2D:
	var ad: String = VERI[sinif]["yetenekler"].get(eylem, ["", "kilic"])[1]
	if not _ikon_onbellek.has(ad):
		_ikon_onbellek[ad] = load("res://assets/ikon/%s.png" % ad)
	return _ikon_onbellek[ad]


static func yetenek_ad(sinif: String, eylem: String) -> String:
	return VERI[sinif]["yetenekler"].get(eylem, [eylem])[0]
