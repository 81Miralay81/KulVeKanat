class_name Guncelleme
extends Node
## Açılışta GitHub'daki son sürümü kontrol eder. Yeniyse indirme bağlantısını verir.

signal sonuc(yeni_var: bool, surum: String, adres: String)

var _http: HTTPRequest


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 8.0
	add_child(_http)
	_http.request_completed.connect(_geldi)
	var hata := _http.request("https://api.github.com/repos/%s/releases/latest" % Oyun.DEPO,
		["User-Agent: KulVeKanat", "Accept: application/vnd.github+json"])
	if hata != OK:
		sonuc.emit(false, "", "")


func _geldi(result: int, kod: int, _basliklar: PackedStringArray, govde: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or kod != 200:
		print("Güncelleme kontrolü yapılamadı: ", result, " ", kod)
		sonuc.emit(false, "", "")
		return
	var veri = JSON.parse_string(govde.get_string_from_utf8())
	if typeof(veri) != TYPE_DICTIONARY:
		sonuc.emit(false, "", "")
		return
	var etiket: String = str(veri.get("tag_name", "")).trim_prefix("v")
	var aranan := "KulVeKanat.apk" if Oyun.mobil else "KulVeKanat.exe"
	var adres: String = str(veri.get("html_url", ""))
	for a in veri.get("assets", []):
		if str(a.get("name", "")) == aranan:
			adres = str(a.get("browser_download_url", adres))
	var yeni := _daha_yeni(etiket, Oyun.SURUM)
	print("Güncelleme kontrolü: ", "yeni sürüm " + etiket if yeni else "güncel (" + Oyun.SURUM + ")")
	sonuc.emit(yeni, etiket, adres)


static func _daha_yeni(a: String, b: String) -> bool:
	var x := a.split(".")
	var y := b.split(".")
	for i in max(x.size(), y.size()):
		var p := int(x[i]) if i < x.size() else 0
		var q := int(y[i]) if i < y.size() else 0
		if p != q:
			return p > q
	return false
