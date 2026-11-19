extends Node
## Açık bölge + köy + zindan testi.
var _t := 0.0
var _a := 0
var ana
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute("/tmp/kvk_test/")
func _foto(ad: String) -> void:
	get_viewport().get_texture().get_image().save_png("/tmp/kvk_test/" + ad + ".png")
	print("FOTO ", ad)
func _process(dt: float) -> void:
	_t += dt
	ana = get_tree().current_scene
	if ana == null or not ana.has_method("mesaj_goster"):
		return
	var k = ana.kahraman
	match _a:
		0:
			if _t > 1.5:
				_foto("d0_menu"); ana._basla()
				k.tecrube_ekle(3000); k.mana = 9999
				k.esya_al(Esya.uret(8, 3, ana.sinif))
				var e2 := Esya.uret(8, 2, ana.sinif); e2["yuva"] = "Zırh"
				if ana.sinif == "muhafiz": e2["model"] = "shield_round"
				k.esyalar["Zırh"] = e2; k.gorunum_guncelle()
				_a = 1
		1:
			if _t > 3.0:
				_foto("d1_koy"); _a = 2
				k.global_position = Bolge.ESNAFLAR[0]["konum"] + Vector3(1.5, 0, 0)
		2:
			if _t > 3.6:
				print("ETKILESIM ", ana.etkilesim)
				ana.etkilesim_yap(); _a = 3
		3:
			if _t > 4.2:
				print("KASABA ACIK ", ana.kasaba.visible)
				_foto("d2_demirci"); ana.kasaba.visible = false; ana.kasaba.kapandi.emit(); _a = 4
				var q: Vector3 = Bolge.suru_noktalari[0]
				k.global_position = q + (Vector3.ZERO - q).normalized() * 20.0
		4:
			if _t > 6.5:
				print("DUSMAN ", ana.dusmanlar.size())
				var q: Vector3 = Bolge.suru_noktalari[0]
				k.global_position = q + (Vector3.ZERO - q).normalized() * 9.0
				_a = 5
		5:
			if _t > 8.5:
				Oyun.eylem_basildi.emit("yetenek1"); _a = 6
		6:
			if _t > 9.3:
				_foto("d3_bolge"); ana.hud.harita_ac_kapa(); _a = 7
		7:
			if _t > 9.8:
				_foto("d4_harita"); ana.hud.harita_ac_kapa(); _a = 8
				k.global_position = Bolge.giris_noktasi(Bolge.ZINDANLAR[0])
		8:
			if _t > 10.5:
				print("ETKILESIM2 ", ana.etkilesim.get("ad"))
				ana.etkilesim_yap(); _a = 9
		9:
			if _t > 12.0:
				print("MOD ", ana.mod)
				_foto("d5_zindan")
				ana.dalga = int(ana.aktif_zindan["dalga"]); ana._ara_sayac = 0.1
				for d in ana.dusmanlar: d.queue_free()
				ana._canli = 0; ana._sira.clear()
				_a = 10
		10:
			if _t > 15.5:
				print("BOSS ", ana.boss)
				_foto("d6_boss")
				k._dokunulmaz = 99
				if ana.boss: ana.boss.hasar_al(999999, true, k.global_position, 0)
				_a = 11
		11:
			if _t > 17.0:
				for d in ana.dusmanlar: d.hasar_al(99999, false, k.global_position, 0)
				print("ZINDAN BITTI ", ana._zindan_bitti)
				_foto("d7_cikis")
				k.global_position = Vector3(0.5, 0, 0.5)
				_a = 12
		12:
			if _t > 17.6:
				print("ETKILESIM3 ", ana.etkilesim.get("ad"))
				ana.etkilesim_yap(); _a = 13
		13:
			if _t > 19.0:
				print("DONUS MOD ", ana.mod, " TEMIZ ", ana.temizlenen, " POZ ", k.global_position)
				_foto("d8_donus")
				get_tree().quit()
