extends Node
## Açık bölge + şehir + görev + zindan + yolculuk testi.
var _t := 0.0
var _a := 0
var _bekle := 0.0
var ana
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute("/tmp/kvk_test/")
func _foto(ad: String) -> void:
	get_viewport().get_texture().get_image().save_png("/tmp/kvk_test/" + ad + ".png")
	print("FOTO ", ad)
func _diyalog_kapat() -> void:
	if ana._diyalog_kutu and is_instance_valid(ana._diyalog_kutu):
		var dugmeler: Array = ana._diyalog_kutu.find_children("*", "Button", true, false)
		dugmeler[-1].pressed.emit()
func _adim(sure: float) -> bool:
	if _t < _bekle:
		return false
	_bekle = _t + sure
	_a += 1
	return true
func _process(dt: float) -> void:
	_t += dt
	ana = get_tree().current_scene
	if ana == null or not ana.has_method("mesaj_goster"):
		return
	var k = ana.kahraman
	if _t < 1.5:
		return
	match _a:
		0:
			if _adim(1.5):
				_foto("d0_menu"); ana._basla()
				print("BOLGE ", ana.bolge_no, " GOREV ", ana.gorev_metni())
				k.mana = 9999
		1:
			if _adim(0.6):
				_foto("d1_sehir")
				for e in Bolge.ESNAFLAR:
					if e["id"] == "gorev":
						k.global_position = e["konum"] + Vector3(1.2, 0, 0)
		2:
			if _adim(0.8):
				print("ETKILESIM ", ana.etkilesim.get("ad")); ana.etkilesim_yap()
		3:
			if _adim(0.5):
				_foto("d2_gorev"); _diyalog_kapat()
				for e in Bolge.ESNAFLAR:
					if e["id"] == "yolcu":
						k.global_position = e["konum"] + Vector3(1.2, 0, 0)
		4:
			if _adim(0.8):
				ana.etkilesim_yap()
		5:
			if _adim(0.5):
				_foto("d3_yolcu"); _diyalog_kapat()
				var q: Vector3 = Bolge.suru_noktalari[0]["konum"]
				print("SURU0 seviye ", Bolge.suru_noktalari[0]["seviye"], " konum ", q)
				k.global_position = q + (Vector3.ZERO - q).normalized() * 22.0
		6:
			if _adim(2.0):
				pass
		7:
			if _adim(1.5):
				var q: Vector3 = Bolge.suru_noktalari[0]["konum"]
				k.global_position = q + (Vector3.ZERO - q).normalized() * 6.0
				var sv := []
				for d in ana.dusmanlar:
					sv.append(d.seviye)
				print("DUSMAN ", ana.dusmanlar.size(), " seviyeler ", sv, " kahraman y ", k.global_position.y)
		8:
			if _adim(1.5):
				_foto("d4_alan")
				var once: int = k.tecrube
				for d in ana.dusmanlar:
					d.hasar_al(999999, false, k.global_position, 0)
				print("XP ", once, " -> ", k.tecrube, " GOREV ", ana.gorev_metni())
		9:
			if _adim(0.8):
				ana.hud.harita_ac_kapa()
		10:
			if _adim(0.5):
				_foto("d5_harita"); ana.hud.harita_ac_kapa()
				# düşük seviye düşman: tecrübe yok
				k.seviye = 30
				var d := Dusman.new(); d.kur("minyon", 5); d.kahraman = k; d.ana = ana
				d.position = k.global_position + Vector3(2, 0, 0); ana.dunya.add_child(d)
				d.oldu_sinyal.connect(ana._dusman_oldu)
		11:
			if _adim(2.0):
				var once: int = k.tecrube
				for d in ana.dusmanlar:
					d.hasar_al(999999, false, k.global_position, 0)
				print("DUSUK DUSMAN XP ", once, " -> ", k.tecrube)
				k.global_position = Bolge.giris_noktasi(Bolge.zindanlar[0])
		12:
			if _adim(0.8):
				print("ETKILESIM2 ", ana.etkilesim.get("ad")); ana.etkilesim_yap()
		13:
			if _adim(0.6):
				print("UYARI DIYALOG ", ana._diyalog_kutu != null and is_instance_valid(ana._diyalog_kutu))
				_foto("d6_uyari"); _diyalog_kapat()
				k.seviye = 6
				ana.etkilesim_yap()
		14:
			if _adim(1.5):
				print("MOD ", ana.mod, " zindan ", ana.aktif_zindan.get("ad"))
				_foto("d7_zindan")
				ana.dalga = int(ana.aktif_zindan["dalga"]); ana._ara_sayac = 0.1
				for d in ana.dusmanlar: d.queue_free()
				ana._canli = 0; ana._sira.clear()
		15:
			if _adim(3.5):
				print("BOSS ", ana.boss, " sv ", ana.boss.seviye if ana.boss else -1)
				_foto("d8_boss")
				k._dokunulmaz = 99
				if ana.boss: ana.boss.hasar_al(999999, true, k.global_position, 0)
		16:
			if _adim(1.5):
				for d in ana.dusmanlar: d.hasar_al(99999, false, k.global_position, 0)
				print("ZINDAN BITTI ", ana._zindan_bitti, " ganimet ", get_tree().get_nodes_in_group("ganimet").size())
				_foto("d9_ganimet")
		17:
			if _adim(2.5):
				k.global_position = Vector3(0.5, 0, 0.5)
		18:
			if _adim(0.6):
				print("ETKILESIM3 ", ana.etkilesim.get("ad")); ana.etkilesim_yap()
		19:
			if _adim(1.5):
				print("DONUS MOD ", ana.mod, " TEMIZ ", ana.temizlenen, " GOREV ", ana.gorev_metni(), " ELIKSIR ", k.eliksir, " TAS ", k.taslar)
				# envanter: eşyalar, artı basma, mana taşı
				k.eliksir = 60; k.altin = 999999
				var e := Esya.set_uret(0, ana.sinif, "Silah"); k.seviye = 16
				k.canta.clear(); k.canta.append(e); k.canta.append(Esya.uret(14, 3, ana.sinif)); k.canta.append(Esya.uret(14, 1, ana.sinif))
				k.tak(0)
				var sonuc := []
				for i in 14:
					sonuc.append(k.arti_bas(k.esyalar["Silah"]))
				print("ARTI ", sonuc, " son +", k.esyalar["Silah"]["arti"])
				k.tas_ekle({"tur": "hasar", "kademe": 1}, 2)
				print("TAS TAK ", k.tas_tak(k.esyalar["Silah"], "hasar_1"))
				ana._envanter_ac()
				ana.envanter._yuva_sec("Silah")
		20:
			if _adim(0.8):
				_foto("e1_envanter"); ana.envanter.kapat_()
				k.seviye = 25
				ana._bolge_degistir(1)
		21:
			if _adim(3.0):
				_foto("e2_ayaz"); print("BOLGE ", Bolge.veri["ad"], " suru ", Bolge.suru_noktalari.size())
				ana._bolge_degistir(2)
		22:
			if _adim(3.0):
				_foto("e3_kor")
				var q: Vector3 = Bolge.suru_noktalari[5]["konum"]
				k.global_position = q + (Vector3.ZERO - q).normalized() * 8.0
		23:
			if _adim(3.0):
				_foto("e4_kor_alan")
				ana.kaydet()
				print("KAYIT bolge ", Oyun.karakter_yukle(ana.sinif).get("bolge"))
				get_tree().quit()
