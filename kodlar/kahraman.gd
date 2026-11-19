class_name Kahraman
extends CharacterBody3D
## Oyuncu karakteri: Kılıç Muhafızı. Hareket, saldırı, 4 yetenek, son vuruş, seviye ve eşyalar.

signal oldu
signal seviye_atladi(seviye: int)
signal esya_alindi(esya: Dictionary, sonuc: String)   ## sonuc: takildi, canta, altin
signal yetenek_acildi(ad: String)

const HIZ := 6.2
const KOSU_ANIM_HIZI := 5.6    ## Running_A animasyonunun doğal hızı (ayak kaymasın diye)

var ana: Node                  ## ana sahne (kamera sarsıntısı, düşman listesi)
var sinif := "muhafiz"         ## muhafiz, avci, buyucu (eklenmeden önce ayarlanır)
var bilgi: Dictionary
var model: Node3D
var anim: AnimationPlayer
var kanat: Kanat

# --- özellikler
var seviye := 1
var tecrube := 0
var can := 320.0
var mana := 120.0
var ofke := 0.0               ## son vuruş çubuğu (0-100)
var altin := 0
var iksir := 3
var esyalar := {}             ## yuva -> eşya
var canta: Array = []          ## çantadaki eşyalar
const CANTA_MAX := 24
var temel := {"hasar": 28.0, "can": 320.0, "mana": 120.0, "kritik": 8.0, "hiz": 0.0, "zirh": 0.0, "kacinma": 0.0}

# --- durum
var durum := "serbest"        ## serbest, eylem, kasirga, atilim, olu
var bakis := Vector3(0, 0, 1)
var eylem_sure := 0.0
var _vurus_zamani := -1.0
var _vurus_cagri: Callable
var _iptal_edilebilir_sonra := 0.0
var _kombo := 0
var _istek := ""              ## tamponlanmış düğme (eylem sırasında basılırsa sonra yapılır)
var _istek_sure := 0.0
var _kasirga_sure := 0.0
var _kasirga_tik := 0.0
var _kasirga_efekt: Node3D
var _atilim_yon := Vector3.ZERO
var _atilim_sure := 0.0
var _atilim_vurulan := {}
var _dokunulmaz := 0.0
var _son_vurus_sure := 0.0
var _hasar_flas := 0.0
var _govdeler: Array[MeshInstance3D] = []
var _flas_mat: StandardMaterial3D
var _flas_acik := false

var bekleme := {"yetenek1": 0.0, "yetenek2": 0.0, "yetenek3": 0.0, "yetenek4": 0.0, "iksir": 0.0}
const BEKLEME := {"yetenek1": 8.0, "yetenek2": 5.0, "yetenek3": 3.5, "yetenek4": 10.0, "iksir": 10.0}
const MANA := {"yetenek1": 35.0, "yetenek2": 30.0, "yetenek3": 15.0, "yetenek4": 50.0}
const ACILMA := {"yetenek1": 1, "yetenek3": 2, "yetenek2": 3, "yetenek4": 5}

const DONGU_ANIMLARI := ["Idle", "2H_Melee_Idle", "Running_A", "Running_B", "2H_Melee_Attack_Spinning", "Walking_A"]


func _ready() -> void:
	add_to_group("kahraman")
	collision_layer = 2
	collision_mask = 1
	var sekil := CollisionShape3D.new()
	var kap := CapsuleShape3D.new()
	kap.radius = 0.45
	kap.height = 1.8
	sekil.shape = kap
	sekil.position.y = 0.9
	add_child(sekil)

	bilgi = Sinif.VERI[sinif]
	model = load("res://assets/karakter/%s.glb" % bilgi["model"]).instantiate()
	add_child(model)
	model.scale = Vector3.ONE * 1.05
	anim = model.find_child("AnimationPlayer", true, false)
	for ad in DONGU_ANIMLARI + [bilgi["bekleme_anim"]]:
		if anim.has_animation(ad):
			anim.get_animation(ad).loop_mode = Animation.LOOP_LINEAR
	# elindeki silahlardan yalnızca sınıfın silahı kalsın
	for n in model.find_children("*", "MeshInstance3D", true, false):
		var ust := n.get_parent()
		if ust is BoneAttachment3D and str(ust.name).begins_with("handslot") and not n.name in bilgi["sakla"]:
			ust.remove_child(n)
			n.queue_free()
	for m in model.find_children("*", "MeshInstance3D", true, false):
		_govdeler.append(m)
	_flas_mat = StandardMaterial3D.new()
	_flas_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flas_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flas_mat.albedo_color = Color(1, 0.1, 0.05, 0.0)

	kanat = Kanat.new()
	kanat.renk = bilgi["kanat"]
	model.add_child(kanat)
	kanat.position = Vector3(0, 1.32, -0.28)

	var isik := OmniLight3D.new()       # karakterin etrafını hafif aydınlatan sıcak ışık
	isik.light_color = Color(1.0, 0.6, 0.3)
	isik.light_energy = 2.4
	isik.omni_range = 9.0
	isik.position = Vector3(0, 2.2, 0)
	add_child(isik)

	Oyun.eylem_basildi.connect(_eylem_istegi)
	Oyun.girdiler_birakildi.connect(func(): _istek = "")
	_ozellikleri_hesapla()
	can = deger("can")
	mana = deger("mana")
	anim.play(bilgi["bekleme_anim"])
	gorunum_guncelle.call_deferred()


# ------------------------------------------------------------------ özellikler
func deger(k: String) -> float:
	var v: float = temel.get(k, 0.0)
	for y in esyalar:
		v += Esya.deger(esyalar[y], k)
	return v


func _ozellikleri_hesapla() -> void:
	var b: Dictionary = bilgi if not bilgi.is_empty() else Sinif.VERI[sinif]
	temel["hasar"] = b["hasar"] + (seviye - 1) * b["hasar"] * 0.18
	temel["can"] = b["can"] + (seviye - 1) * b["can"] * 0.13
	temel["mana"] = b["mana"] + (seviye - 1) * 7.0
	temel["kritik"] = b["kritik"]
	temel["zirh"] = b["zirh"]
	temel["hiz"] = b["hiz"]
	temel["kacinma"] = b.get("kacinma", 0.0)


func zirh_orani() -> float:
	return clampf(deger("zirh"), 0.0, 75.0)


func yetenek_ad(eylem: String) -> String:
	return Sinif.yetenek_ad(sinif, eylem)


func ikon(eylem: String) -> Texture2D:
	return Sinif.ikon(sinif, eylem)


func kayit_verisi() -> Dictionary:
	return {"sinif": sinif, "seviye": seviye, "tecrube": tecrube, "altin": altin, "iksir": iksir,
		"esyalar": esyalar, "canta": canta}


func kayit_yukle(d: Dictionary) -> void:
	seviye = int(d.get("seviye", 1))
	tecrube = int(d.get("tecrube", 0))
	altin = int(d.get("altin", 0))
	iksir = int(d.get("iksir", 3))
	esyalar = d.get("esyalar", {})
	canta = d.get("canta", [])
	# JSON sayıları ondalık gelir: eşya alanlarını düzelt
	for e in esyalar.values() + canta:
		e["nadirlik"] = int(e["nadirlik"])
		e["seviye"] = int(e["seviye"])
		e["arti"] = int(e.get("arti", 0))
	_ozellikleri_hesapla()
	can = deger("can")
	mana = deger("mana")
	if is_inside_tree():
		gorunum_guncelle.call_deferred()


func gereken_tecrube() -> int:
	return int(70.0 * pow(seviye, 1.55))


func tecrube_ekle(x: int) -> void:
	tecrube += x
	while tecrube >= gereken_tecrube():
		tecrube -= gereken_tecrube()
		seviye += 1
		_ozellikleri_hesapla()
		can = deger("can")
		mana = deger("mana")
		Efekt.seviye_atlama(self)
		Ses.cal("seviye")
		seviye_atladi.emit(seviye)
		for y in ACILMA:
			if ACILMA[y] == seviye:
				yetenek_acildi.emit(y)


func acik_mi(eylem: String) -> bool:
	return seviye >= int(ACILMA.get(eylem, 1))


func _can_oranini_koru(islem: Callable) -> void:
	var oran := can / maxf(1.0, deger("can"))
	islem.call()
	can = minf(deger("can"), deger("can") * oran)
	mana = minf(mana, deger("mana"))


func esya_al(e: Dictionary) -> void:
	var y: String = e["yuva"]
	if not esyalar.has(y):
		_can_oranini_koru(func(): esyalar[y] = e)
		gorunum_guncelle()
		esya_alindi.emit(e, "takildi")
	elif canta.size() < CANTA_MAX:
		canta.append(e)
		esya_alindi.emit(e, "canta")
	else:
		altin += satis_fiyati(e)
		esya_alindi.emit(e, "altin")


func satis_fiyati(e: Dictionary) -> int:
	return 10 + int(e["seviye"]) * 3 * (int(e["nadirlik"]) + 1) * (int(e["nadirlik"]) + 1)


func tak(i: int) -> void:
	if i < 0 or i >= canta.size():
		return
	var e: Dictionary = canta[i]
	canta.remove_at(i)
	var y: String = e["yuva"]
	_can_oranini_koru(func():
		if esyalar.has(y):
			canta.insert(i, esyalar[y])
		esyalar[y] = e)
	gorunum_guncelle()


func cikar(y: String) -> bool:
	if not esyalar.has(y) or canta.size() >= CANTA_MAX:
		return false
	_can_oranini_koru(func():
		canta.append(esyalar[y])
		esyalar.erase(y))
	gorunum_guncelle()
	return true


func sat(i: int) -> void:
	if i < 0 or i >= canta.size():
		return
	altin += satis_fiyati(canta[i])
	canta.remove_at(i)


# ------------------------------------------------------------------ girdi
func _eylem_istegi(ad: String) -> void:
	if durum == "olu" or get_tree().paused or (ana and ana.durum != "oyun"):
		return
	_istek = ad
	_istek_sure = 0.3


func _kamera_yonu(v: Vector2) -> Vector3:
	# Kamera 45° açıyla bakıyor: ekranın yukarısı dünyada (-x, -z) yönüdür.
	var ileri := Vector3(-1, 0, -1).normalized()
	var sag := Vector3(1, 0, -1).normalized()
	var y := sag * v.x + ileri * (-v.y)
	return y.limit_length(1.0)


func nisan_yonu() -> Vector3:
	# 1) Bilgisayarda fare kullanılıyorsa farenin gösterdiği yer
	if Oyun.son_girdi_fare and not Oyun.dokunmatik_acik and ana and ana.kamera:
		var kam: Camera3D = ana.kamera
		var mp := get_viewport().get_mouse_position()
		var o := kam.project_ray_origin(mp)
		var n := kam.project_ray_normal(mp)
		if absf(n.y) > 0.001:
			var t := (0.5 - o.y) / n.y
			var nokta := o + n * t
			var d := nokta - global_position
			d.y = 0
			if d.length() > 0.2:
				return d.normalized()
	# 2) Hareket yönü varsa o yönde en yakın düşman, yoksa en yakın düşman (otomatik nişan)
	var hareket := _kamera_yonu(Oyun.hareket_vektoru())
	var en_iyi: Node3D = null
	var en_iyi_puan := INF
	for d in get_tree().get_nodes_in_group("dusman"):
		if d.olu:
			continue
		var fark: Vector3 = d.global_position - global_position
		fark.y = 0
		var mesafe := fark.length()
		if mesafe > 9.0:
			continue
		var p := mesafe
		if hareket.length() > 0.3:
			p -= fark.normalized().dot(hareket.normalized()) * 3.0
		if p < en_iyi_puan:
			en_iyi_puan = p
			en_iyi = d
	if en_iyi:
		var f := en_iyi.global_position - global_position
		f.y = 0
		return f.normalized()
	if hareket.length() > 0.2:
		return hareket.normalized()
	return bakis


# ------------------------------------------------------------------ ana döngü
func _physics_process(dt: float) -> void:
	for k in bekleme:
		bekleme[k] = maxf(0.0, bekleme[k] - dt)
	_dokunulmaz = maxf(0.0, _dokunulmaz - dt)
	_istek_sure -= dt
	if _istek_sure <= 0:
		_istek = ""
	if durum == "olu":
		return
	if ana and ana.durum != "oyun":
		velocity = Vector3.ZERO
		_oynat(bilgi["bekleme_anim"], 0.2)
		return
	mana = minf(deger("mana"), mana + (7.0 + seviye * 0.3) * dt)
	if _son_vurus_sure > 0:
		_son_vurus_sure -= dt
		if _son_vurus_sure <= 0:
			kanat.ac(0.35)
	_hasar_flas = maxf(0.0, _hasar_flas - dt * 4.0)
	_flas_mat.albedo_color.a = _hasar_flas * 0.55
	var flas_acik := _hasar_flas > 0.01
	if flas_acik != _flas_acik:
		_flas_acik = flas_acik
		for m in _govdeler:
			m.material_overlay = _flas_mat if flas_acik else null

	var giris := _kamera_yonu(Oyun.hareket_vektoru())
	var hiz := HIZ * (1.0 + deger("hiz") / 100.0) * (1.25 if _son_vurus_sure > 0 else 1.0)

	match durum:
		"serbest":
			velocity = giris * hiz
			if giris.length() > 0.05:
				bakis = giris.normalized()
			_hareket_animasyonu(velocity.length(), hiz)
			_girdi_isle()
		"eylem":
			eylem_sure -= dt
			velocity = giris * hiz * 0.12
			if _vurus_zamani >= 0:
				_vurus_zamani -= dt
				if _vurus_zamani < 0:
					_vurus_cagri.call()
			_iptal_edilebilir_sonra -= dt
			# vuruş anı geçtiyse hareket ya da yeni düğme eylemi bitirir (tepki hızlı olsun)
			if _iptal_edilebilir_sonra <= 0 and _vurus_zamani < 0:
				if giris.length() > 0.3 or (_istek != "" and _istek != "saldir"):
					eylem_sure = 0
			if eylem_sure <= 0:
				durum = "serbest"
				_girdi_isle()
		"kasirga":
			_kasirga_sure -= dt
			_kasirga_tik -= dt
			velocity = giris * hiz * 0.8
			if giris.length() > 0.05:
				bakis = giris.normalized()
			if _kasirga_tik <= 0:
				_kasirga_tik = 0.22
				_alan_hasari(global_position, 3.3, 0.55, 2.5, false)
			if _kasirga_sure <= 0:
				_kasirga_bitir()
		"atilim":
			_atilim_sure -= dt
			velocity = _atilim_yon * 24.0
			for d in get_tree().get_nodes_in_group("dusman"):
				if not d.olu and not _atilim_vurulan.has(d) and d.global_position.distance_to(global_position) < 1.8:
					_atilim_vurulan[d] = true
					_vur(d, 1.3, 4.0)
			if _atilim_sure <= 0:
				durum = "serbest"
				kanat.ac(0.9 if _son_vurus_sure > 0 else 0.35)

	move_and_slide()
	global_position.y = 0.0
	# model yönünü yumuşak çevir (KayKit modelleri +Z'ye bakar)
	var hedef_aci := atan2(bakis.x, bakis.z)
	model.rotation.y = lerp_angle(model.rotation.y, hedef_aci, minf(1.0, dt * 16.0))


func _hareket_animasyonu(hiz_su_an: float, hiz_max: float) -> void:
	if hiz_su_an > 0.4:
		# animasyon hızı gerçek yürüme hızına eşitlenir: ayaklar kaymaz
		_oynat("Running_A", 0.12, clampf(hiz_su_an / KOSU_ANIM_HIZI, 0.6, 1.6))
	else:
		_oynat(bilgi["bekleme_anim"], 0.18, 1.0)


func _oynat(ad: String, gecis := 0.1, hiz := 1.0, bastan := false) -> void:
	if not anim.has_animation(ad):
		ad = "Idle"
	if bastan or anim.current_animation != ad:
		anim.play(ad, gecis)
		if bastan:
			anim.seek(0.0, true)
	anim.speed_scale = hiz


const SINIF_YETENEK := {
	"muhafiz": {"saldir": "_temel_saldiri", "yetenek1": "_kasirga_baslat", "yetenek2": "_yer_yarma", "yetenek3": "_atilim", "yetenek4": "_meteor", "son_vurus": "_son_vurus"},
	"avci": {"saldir": "_arbalet", "yetenek1": "_coklu_atis", "yetenek2": "_ok_yagmuru", "yetenek3": "_golge_adimi", "yetenek4": "_zehir_bombasi", "son_vurus": "_golge_firtinasi"},
	"buyucu": {"saldir": "_ates_topu", "yetenek1": "_alev_halkasi", "yetenek2": "_buz_firtinasi", "yetenek3": "_isinlanma", "yetenek4": "_meteor", "son_vurus": "_kul_kiyameti"},
}


func _yap(eylem: String) -> void:
	call(SINIF_YETENEK[sinif][eylem])


func _girdi_isle() -> void:
	var istek := _istek
	if istek != "":
		_istek = ""
		if istek in ["yetenek1", "yetenek2", "yetenek3", "yetenek4"]:
			if _yetenek_hazir(istek):
				_yap(istek)
			return
		if istek == "son_vurus":
			if ofke >= 100.0:
				ofke = 0.0
				_yap("son_vurus")
			elif ana:
				ana.mesaj_goster("%s henüz dolmadı" % yetenek_ad("son_vurus"), Color(1, 0.7, 0.4))
			return
		if istek == "iksir":
			_iksir_ic()
			return
		if istek == "saldir":
			_yap("saldir")
			return
	if Input.is_action_pressed("saldir"):
		_yap("saldir")


func _yetenek_hazir(ad: String) -> bool:
	if not acik_mi(ad):
		if ana:
			ana.mesaj_goster("%s seviye %d'de açılır" % [yetenek_ad(ad), ACILMA[ad]], Color(0.8, 0.8, 0.8))
		return false
	if bekleme[ad] > 0:
		return false
	if mana < MANA[ad]:
		if ana:
			ana.mesaj_goster("Yeterli mana yok", Color(0.4, 0.6, 1.0))
		return false
	mana -= MANA[ad]
	bekleme[ad] = BEKLEME[ad]
	return true


func _eylem_baslat(anim_ad: String, sure: float, vurus: float, cagri: Callable, anim_hiz := 1.0) -> void:
	durum = "eylem"
	eylem_sure = sure
	_vurus_zamani = vurus
	_vurus_cagri = cagri
	_iptal_edilebilir_sonra = vurus + 0.05
	velocity = Vector3.ZERO
	_oynat(anim_ad, 0.06, anim_hiz, true)


# ------------------------------------------------------------------ saldırılar
func _temel_saldiri() -> void:
	bakis = nisan_yonu()
	model.rotation.y = atan2(bakis.x, bakis.z)
	_kombo = (_kombo + 1) % 3
	var animler := ["2H_Melee_Attack_Slice", "2H_Melee_Attack_Chop", "2H_Melee_Attack_Slice"]
	var hizlar := [1.55, 1.6, 1.7]
	Ses.cal("savurma", -4.0)
	_eylem_baslat(animler[_kombo], 0.52, 0.2, func():
		var vurdu := _koni_hasari(2.9, 130.0, 1.0 if _kombo != 1 else 1.35, 3.0)
		_kilic_izi(_kombo == 1)
		if vurdu > 0:
			ofke = minf(100.0, ofke + 2.0 * vurdu)
	, hizlar[_kombo])


func _kilic_izi(dikey: bool) -> void:
	# kılıcın havada bıraktığı parlak yay
	var m := MeshInstance3D.new()
	m.mesh = Efekt.halka_mesh(1.9, 2.7, 24)
	var mat := Efekt.yeni_parlak_mat(Color(1.0, 0.75, 0.45), 2.2)
	m.material_override = mat
	add_child(m)
	m.position = Vector3(0, 1.0, 0)
	m.rotation.y = atan2(bakis.x, bakis.z) + PI * 0.5
	if dikey:
		m.rotation.x = deg_to_rad(70)
	m.scale = Vector3(1.0, 1.0, 0.55)
	var tw := m.create_tween()
	tw.tween_method(func(v): mat.set_shader_parameter("saydam", v), 0.9, 0.0, 0.18)
	tw.tween_callback(m.queue_free)


func _kasirga_baslat() -> void:
	durum = "kasirga"
	_kasirga_sure = 2.6
	_kasirga_tik = 0.0
	_oynat("2H_Melee_Attack_Spinning", 0.08, 1.5)
	Ses.ates_dongu(true)
	var kok := Node3D.new()
	add_child(kok)
	for i in 3:
		var s := MeshInstance3D.new()
		s.mesh = Efekt.sarmal_mesh(2.0 + i * 0.35, 1.6, 1.15, 0.45 - i * 0.08)
		s.material_override = Efekt.parlak_mat([Efekt.ATES_ACIK, Efekt.ATES, Color(1, 0.25, 0.02)][i], 2.6)
		s.rotation.y = i * TAU / 3.0
		kok.add_child(s)
	var h := MeshInstance3D.new()
	h.mesh = Efekt.halka_mesh(2.6, 3.4)
	h.material_override = Efekt.parlak_mat(Efekt.ATES, 2.4)
	h.position.y = 0.06
	kok.add_child(h)
	var d := MeshInstance3D.new()
	d.mesh = Efekt.disk_mesh(3.3)
	d.material_override = Efekt.parlak_mat(Color(1.0, 0.3, 0.05), 0.7)
	d.position.y = 0.05
	kok.add_child(d)
	var kiv := GPUParticles3D.new()
	kiv.amount = 60 if not Efekt.mobil else 28
	kiv.lifetime = 0.9
	kiv.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_radius = 2.6
	pm.emission_ring_inner_radius = 1.2
	pm.emission_ring_height = 0.2
	pm.emission_ring_axis = Vector3.UP
	pm.direction = Vector3.UP
	pm.spread = 30.0
	pm.initial_velocity_min = 1.5
	pm.initial_velocity_max = 4.0
	pm.gravity = Vector3(0, 1.0, 0)
	pm.tangential_accel_min = 6.0
	pm.tangential_accel_max = 10.0
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	kiv.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.18, 0.18)
	q.material = Efekt.parca_mat(Efekt.ATES_ACIK, 3.5)
	kiv.draw_pass_1 = q
	kok.add_child(kiv)
	var l := OmniLight3D.new()
	l.visible = Efekt.isik_var()
	l.light_color = Efekt.ATES
	l.light_energy = 4.0
	l.omni_range = 8.0
	l.position.y = 1.2
	kok.add_child(l)
	var tw := kok.create_tween().set_loops()
	tw.tween_property(kok, "rotation:y", -TAU, 0.38).as_relative()
	_kasirga_efekt = kok


func _kasirga_bitir() -> void:
	durum = "serbest"
	Ses.ates_dongu(false)
	if is_instance_valid(_kasirga_efekt):
		var k := _kasirga_efekt
		_kasirga_efekt = null
		var tw := k.create_tween()
		tw.tween_property(k, "scale", Vector3(1.3, 0.2, 1.3), 0.2)
		tw.tween_callback(k.queue_free)


func _yer_yarma() -> void:
	bakis = nisan_yonu()
	model.rotation.y = atan2(bakis.x, bakis.z)
	_eylem_baslat("2H_Melee_Attack_Chop", 0.75, 0.32, func():
		var yon := bakis
		var bas := global_position
		Ses.cal("patlama", -3.0)
		if ana:
			ana.kamera_sars(0.5)
		for i in 6:
			var nokta := bas + yon * (1.4 + i * 1.15)
			get_tree().create_timer(i * 0.05, false).timeout.connect(func():
				Efekt.parcacik(nokta + Vector3(0, 0.2, 0), 18, Efekt.ATES, 0.6, 7.0, -8.0, 0.45, 25.0)
				Efekt.parcacik(nokta, 8, Color(0.3, 0.25, 0.2, 0.8), 0.9, 3.0, -6.0, 0.6, 40.0, true, false, Vector3.ZERO, 1.0)
				Efekt.halka_dalga(nokta, Efekt.ATES, 0.2, 1.6, 0.35, 0.5, 3.0)
				Efekt.isik_flas(nokta + Vector3(0, 1, 0), Efekt.ATES, 4.0, 5.0, 0.3))
		# koni şeklinde hasar + geri itme
		for d in get_tree().get_nodes_in_group("dusman"):
			if d.olu:
				continue
			var f: Vector3 = d.global_position - bas
			f.y = 0
			var ileri := f.dot(yon)
			var yan := (f - yon * ileri).length()
			if ileri > 0 and ileri < 8.5 and yan < 1.4 + ileri * 0.2:
				_vur(d, 2.4, 9.0)
	, 1.25)


func _atilim() -> void:
	var g := _kamera_yonu(Oyun.hareket_vektoru())
	_atilim_yon = g.normalized() if g.length() > 0.2 else bakis
	bakis = _atilim_yon
	model.rotation.y = atan2(bakis.x, bakis.z)
	durum = "atilim"
	_atilim_sure = 0.3
	_atilim_vurulan.clear()
	_dokunulmaz = 0.45
	kanat.ac(1.0)
	_oynat("Dodge_Forward", 0.05, 1.8, true)
	Ses.cal("atilim")
	Efekt.parcacik(global_position + Vector3(0, 1.0, 0), 30, Efekt.ATES, 0.6, 3.0, 0.0, 0.5, 180.0, true, true, Vector3(0.4, 0.6, 0.4))
	Efekt.halka_dalga(global_position, Efekt.ATES_ACIK, 0.3, 2.5, 0.3, 0.4, 3.0)
	# yol boyunca iz
	for i in 5:
		get_tree().create_timer(i * 0.055, false).timeout.connect(func():
			if is_inside_tree():
				Efekt.parcacik(global_position + Vector3(0, 1.1, 0), 14, Efekt.ATES_ACIK, 0.5, 1.0, 0.5, 0.6, 180.0, true, true, Vector3(0.3, 0.5, 0.3)))


func _meteor() -> void:
	var yon := nisan_yonu()
	bakis = yon
	model.rotation.y = atan2(bakis.x, bakis.z)
	_eylem_baslat("Spellcast_Raise", 0.6, 0.25, func():
		var merkez := global_position + yon * 5.0
		for i in 6:
			var a := randf() * TAU
			var r := randf_range(0.0, 3.0) if i > 0 else 0.0
			var hedef := merkez + Vector3(cos(a) * r, 0, sin(a) * r)
			Efekt.meteor(hedef, 0.25 + i * 0.22, func(p: Vector3):
				Ses.cal("patlama", -2.0)
				if ana:
					ana.kamera_sars(0.35)
				_alan_hasari(p, 2.6, 2.0, 7.0, true))
	, 1.0)


func _son_vurus() -> void:
	_son_vurus_sure = 10.0
	kanat.ac(1.0)
	_dokunulmaz = 1.0
	_eylem_baslat("2H_Melee_Attack_Spin", 0.9, 0.35, func():
		Efekt.kanat_tuyu_patlamasi(global_position)
		Ses.cal("patlama", 0.0)
		if ana:
			ana.kamera_sars(1.0)
			ana.vurus_duraklat(0.07)
		_alan_hasari(global_position, 8.0, 4.5, 14.0, true)
	, 1.2)
	if ana:
		ana.mesaj_goster(yetenek_ad("son_vurus").to_upper() + "!", bilgi["kanat"].lightened(0.3), true)


func _iksir_ic() -> void:
	if iksir <= 0:
		if ana:
			ana.mesaj_goster("İksir kalmadı", Color(1, 0.4, 0.4))
		return
	if bekleme["iksir"] > 0:
		return
	iksir -= 1
	bekleme["iksir"] = BEKLEME["iksir"]
	can = minf(deger("can"), can + deger("can") * 0.45)
	Efekt.parcacik(global_position + Vector3(0, 0.5, 0), 30, Color(1, 0.25, 0.25), 1.0, 3.0, 2.0, 0.3, 30.0, true, true, Vector3(0.5, 0.2, 0.5))
	Ses.cal("seviye", -8.0, 0.0)


# ------------------------------------------------------------------ hasar
func hasar_hesapla(carpan: float) -> Array:
	var h := deger("hasar") * carpan * randf_range(0.9, 1.1)
	if _son_vurus_sure > 0:
		h *= 1.5
	var kritik := randf() * 100.0 < deger("kritik")
	if kritik:
		h *= 2.0
	return [h, kritik]


func _vur(d: Node, carpan: float, itme: float) -> void:
	var sonuc := hasar_hesapla(carpan)
	d.hasar_al(sonuc[0], sonuc[1], global_position, itme)


func _koni_hasari(menzil: float, aci: float, carpan: float, itme: float) -> int:
	var sayi := 0
	var esik := cos(deg_to_rad(aci * 0.5))
	for d in get_tree().get_nodes_in_group("dusman"):
		if d.olu:
			continue
		var f: Vector3 = d.global_position - global_position
		f.y = 0
		var m := f.length()
		if m < menzil + d.yaricap and (m < 0.6 or f.normalized().dot(bakis) > esik):
			_vur(d, carpan, itme)
			sayi += 1
	if sayi > 0:
		Ses.cal("vurus", -2.0)
		if ana:
			ana.kamera_sars(0.12)
	return sayi


func _alan_hasari(merkez: Vector3, yaricap: float, carpan: float, itme: float, ses: bool) -> int:
	var sayi := 0
	for d in get_tree().get_nodes_in_group("dusman"):
		if d.olu:
			continue
		var f: Vector3 = d.global_position - merkez
		f.y = 0
		if f.length() < yaricap + d.yaricap:
			_vur(d, carpan, itme)
			sayi += 1
	if sayi > 0:
		ofke = minf(100.0, ofke + sayi * 1.2)
		if ses:
			Ses.cal("vurus", -3.0)
	return sayi


func hasar_al(miktar: float) -> void:
	if durum == "olu" or _dokunulmaz > 0:
		return
	if randf() * 100.0 < minf(deger("kacinma"), 50.0):
		Efekt.hasar_yazisi(global_position + Vector3(0, 2.4, 0), "KAÇTI", Color(0.6, 0.9, 1.0))
		return
	var azalan := miktar * (1.0 - zirh_orani() / 100.0)
	can -= azalan
	Efekt.hasar_yazisi(global_position + Vector3(0, 2.3, 0), "-%d" % int(azalan), Color(1.0, 0.3, 0.25))
	_hasar_flas = 1.0
	Ses.cal("aci", -6.0)
	if ana:
		ana.kamera_sars(0.18)
	if can <= 0:
		can = 0
		_ol()


func _ol() -> void:
	durum = "olu"
	velocity = Vector3.ZERO
	Ses.ates_dongu(false)
	if is_instance_valid(_kasirga_efekt):
		_kasirga_efekt.queue_free()
	kanat.ac(0.0)
	anim.play("Death_A", 0.1)
	oldu.emit()


func dirilt() -> void:
	durum = "serbest"
	can = deger("can")
	mana = deger("mana")
	_dokunulmaz = 2.0
	anim.play(bilgi["bekleme_anim"], 0.2)
	kanat.ac(0.35)



# ================================================================== GÖLGE AVCI
func _mermi(yon: Vector3, tur: String, carpan: float, hiz := 26.0, delme := 0, patlama := 0.0, renk := Color(0.85, 0.65, 1.0)) -> void:
	var m := OyuncuMermi.new()
	m.kahraman = self
	m.yon = yon
	m.tur = tur
	m.carpan = carpan
	m.hiz = hiz
	m.delme = delme
	m.patlama_r = patlama
	m.renk = renk
	get_parent().add_child(m)
	m.global_position = global_position + Vector3(0, 1.15, 0) + yon * 0.7


func _arbalet() -> void:
	bakis = nisan_yonu()
	model.rotation.y = atan2(bakis.x, bakis.z)
	_eylem_baslat("2H_Ranged_Shoot", 0.42, 0.14, func():
		Ses.cal("savurma", -6.0, 0.15)
		_mermi(bakis, "ok", 1.0, 30.0, 1)
	, 1.7)


func _coklu_atis() -> void:
	bakis = nisan_yonu()
	model.rotation.y = atan2(bakis.x, bakis.z)
	_eylem_baslat("2H_Ranged_Shoot", 0.5, 0.16, func():
		Ses.cal("savurma", -2.0)
		for i in 9:
			var aci := deg_to_rad(-40.0 + i * 10.0)
			_mermi(bakis.rotated(Vector3.UP, aci), "ok", 1.1, 28.0, 2)
		Efekt.halka_dalga(global_position, Color(0.75, 0.4, 1.0), 0.3, 2.5, 0.3, 0.4, 3.0)
	, 1.5)


func _ok_yagmuru() -> void:
	var yon := nisan_yonu()
	bakis = yon
	model.rotation.y = atan2(bakis.x, bakis.z)
	_eylem_baslat("2H_Ranged_Shoot", 0.55, 0.2, func():
		var merkez := global_position + yon * 6.0
		Efekt.yer_isareti(merkez, 3.5, 0.5, Color(0.6, 0.35, 1.0))
		for i in 18:
			get_tree().create_timer(0.35 + i * 0.07, false).timeout.connect(func():
				var a := randf() * TAU
				var p := merkez + Vector3(cos(a), 0, sin(a)) * randf_range(0.0, 3.4)
				_dusen_ok(p))
	, 1.4)


func _dusen_ok(p: Vector3) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.06, 1.6, 0.06)
	m.mesh = b
	m.material_override = Efekt.parlak_mat(Color(0.8, 0.6, 1.0), 3.0)
	get_parent().add_child(m)
	m.global_position = p + Vector3(-1.0, 9.0, -1.0)
	m.look_at(p, Vector3.UP)
	m.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	var tw := m.create_tween()
	tw.tween_property(m, "global_position", p + Vector3(0, 0.5, 0), 0.22)
	tw.tween_callback(func():
		Efekt.parcacik(p + Vector3(0, 0.2, 0), 6, Color(0.75, 0.5, 1.0), 0.35, 4.0, -8.0, 0.2, 60.0)
		_alan_hasari(p, 1.6, 0.65, 1.5, false)
		m.queue_free())


func _golge_adimi() -> void:
	_atilim()
	Efekt.parcacik(global_position + Vector3(0, 1.0, 0), 30, Color(0.55, 0.25, 0.9), 0.8, 2.0, 0.5, 0.7, 180.0, true, false, Vector3(0.4, 0.7, 0.4), 1.5)


func _zehir_bombasi() -> void:
	var yon := nisan_yonu()
	bakis = yon
	model.rotation.y = atan2(bakis.x, bakis.z)
	_eylem_baslat("Throw", 0.6, 0.3, func():
		var hedef := global_position + yon * 6.5
		hedef.x = clampf(hedef.x, -19, 19)
		hedef.z = clampf(hedef.z, -19, 19)
		var b := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.22
		s.height = 0.44
		b.mesh = s
		b.material_override = Efekt.parlak_mat(Color(0.4, 1.0, 0.3), 3.0)
		get_parent().add_child(b)
		var bas := global_position + Vector3(0, 1.4, 0)
		b.global_position = bas
		var tw := b.create_tween()
		tw.tween_method(func(u: float): b.global_position = bas.lerp(hedef, u) + Vector3(0, sin(u * PI) * 3.0, 0), 0.0, 1.0, 0.45)
		tw.tween_callback(func():
			b.queue_free()
			_zehir_bulutu(hedef))
	, 1.3)


func _zehir_bulutu(p: Vector3) -> void:
	Ses.cal("patlama", -6.0)
	var kok := Node3D.new()
	get_parent().add_child(kok)
	kok.global_position = p
	var d := MeshInstance3D.new()
	d.mesh = Efekt.disk_mesh(3.2)
	d.material_override = Efekt.parlak_mat(Color(0.3, 0.9, 0.2), 1.2)
	d.position.y = 0.06
	kok.add_child(d)
	for i in 9:
		get_tree().create_timer(i * 0.5, false).timeout.connect(func():
			if not is_instance_valid(kok):
				return
			Efekt.parcacik(p + Vector3(0, 0.4, 0), 16, Color(0.35, 0.95, 0.25, 0.8), 1.2, 1.2, 0.8, 0.9, 180.0, true, true, Vector3(2.2, 0.3, 2.2), 1.6)
			_alan_hasari(p, 3.2, 0.45, 0.0, false))
	get_tree().create_timer(4.6, false).timeout.connect(kok.queue_free)


func _golge_firtinasi() -> void:
	_son_vurus_sure = 10.0
	kanat.ac(1.0)
	_dokunulmaz = 1.0
	_eylem_baslat("2H_Melee_Attack_Spin", 0.7, 0.25, func():
		for i in 32:
			_mermi(Vector3.FORWARD.rotated(Vector3.UP, TAU * i / 32.0), "hancer", 2.2, 22.0, 3, 0.0, Color(0.85, 0.5, 1.0))
		Efekt.halka_dalga(global_position, Color(0.8, 0.45, 1.0), 0.5, 9.0, 0.6, 0.3, 4.0)
		Efekt.parcacik(global_position + Vector3(0, 1.2, 0), 50, Color(0.7, 0.35, 1.0), 1.2, 10.0, -2.0, 0.4, 180.0)
		Ses.cal("patlama")
		if ana:
			ana.kamera_sars(0.8)
	, 1.2)
	if ana:
		ana.mesaj_goster("GÖLGE FIRTINASI!", Color(0.85, 0.6, 1.0), true)


# ================================================================== KÜL BÜYÜCÜ
func _ates_topu() -> void:
	bakis = nisan_yonu()
	model.rotation.y = atan2(bakis.x, bakis.z)
	_eylem_baslat("Spellcast_Shoot", 0.5, 0.2, func():
		Ses.cal("buyu", -6.0)
		_mermi(bakis, "ates", 1.0, 18.0, 0, 1.6)
	, 1.6)


func _alev_halkasi() -> void:
	_eylem_baslat("Spellcast_Raise", 0.6, 0.28, func():
		Ses.cal("patlama", -2.0)
		Efekt.halka_dalga(global_position, Efekt.ATES_ACIK, 0.5, 6.5, 0.45, 0.35, 5.0)
		Efekt.halka_dalga(global_position, Efekt.ATES, 0.5, 5.5, 0.6, 0.6, 3.0)
		for i in 12:
			var a := TAU * i / 12.0
			Efekt.parcacik(global_position + Vector3(cos(a), 0.3, sin(a)) * 3.0, 10, Efekt.ATES, 0.6, 5.0, -4.0, 0.5, 30.0)
		Efekt.isik_flas(global_position + Vector3(0, 1.5, 0), Efekt.ATES, 10.0, 12.0, 0.5)
		_alan_hasari(global_position, 5.5, 1.9, 9.0, true)
		if ana:
			ana.kamera_sars(0.5)
	, 1.3)


func _buz_firtinasi() -> void:
	var yon := nisan_yonu()
	bakis = yon
	model.rotation.y = atan2(bakis.x, bakis.z)
	_eylem_baslat("Spellcast_Long", 0.6, 0.25, func():
		var p := global_position + yon * 5.5
		var kok := Node3D.new()
		get_parent().add_child(kok)
		kok.global_position = p
		var d := MeshInstance3D.new()
		d.mesh = Efekt.disk_mesh(3.8)
		d.material_override = Efekt.parlak_mat(Color(0.45, 0.8, 1.0), 1.3)
		d.position.y = 0.06
		kok.add_child(d)
		var h := MeshInstance3D.new()
		h.mesh = Efekt.halka_mesh(3.5, 3.9)
		h.material_override = Efekt.parlak_mat(Color(0.6, 0.9, 1.0), 2.0)
		h.position.y = 0.07
		kok.add_child(h)
		var l := OmniLight3D.new()
		l.visible = Efekt.isik_var()
		l.light_color = Color(0.5, 0.8, 1.0)
		l.light_energy = 3.0
		l.omni_range = 7.0
		l.position.y = 2.0
		kok.add_child(l)
		for i in 8:
			get_tree().create_timer(i * 0.4, false).timeout.connect(func():
				if not is_instance_valid(kok):
					return
				Efekt.parcacik(p + Vector3(0, 4.0, 0), 22, Color(0.75, 0.92, 1.0), 1.0, 2.0, -9.0, 0.25, 30.0, false, true, Vector3(3.2, 0.3, 3.2), 2.5)
				for dd in (ana.dusmanlar if ana else []):
					if is_instance_valid(dd) and not dd.olu and dd.global_position.distance_to(p) < 3.9:
						dd.yavaslat(1.0)
				_alan_hasari(p, 3.8, 0.5, 0.0, false))
		get_tree().create_timer(3.4, false).timeout.connect(kok.queue_free)
	, 1.2)


func _isinlanma() -> void:
	var g := _kamera_yonu(Oyun.hareket_vektoru())
	var yon := g.normalized() if g.length() > 0.2 else bakis
	var bas := global_position
	var hedef := bas + yon * 7.5
	hedef.x = clampf(hedef.x, -18.8, 18.8)
	hedef.z = clampf(hedef.z, -18.8, 18.8)
	for s in Dunya.SUTUNLAR:
		var f: Vector3 = hedef - s
		f.y = 0
		if f.length() < 1.3:
			hedef = s + f.normalized() * 1.4
	Efekt.parcacik(bas + Vector3(0, 1.0, 0), 30, Color(0.5, 0.75, 1.0), 0.7, 4.0, 0.0, 0.3, 180.0, true, true, Vector3(0.3, 0.8, 0.3))
	global_position = hedef
	bakis = yon
	_dokunulmaz = 0.4
	kanat.ac(1.0)
	get_tree().create_timer(0.35, false).timeout.connect(func(): kanat.ac(0.9 if _son_vurus_sure > 0 else 0.35))
	Efekt.parcacik(hedef + Vector3(0, 1.0, 0), 30, Color(0.6, 0.85, 1.0), 0.7, 4.0, 0.0, 0.3, 180.0, true, true, Vector3(0.3, 0.8, 0.3))
	Efekt.halka_dalga(hedef, Color(0.6, 0.85, 1.0), 0.3, 3.0, 0.35, 0.4, 3.0)
	Ses.cal("atilim")


func _kul_kiyameti() -> void:
	_son_vurus_sure = 10.0
	kanat.ac(1.0)
	_dokunulmaz = 1.0
	_eylem_baslat("Spellcast_Raise", 0.8, 0.3, func():
		for i in 16:
			var a := randf() * TAU
			var r := randf_range(1.5, 8.0)
			var hedef := global_position + Vector3(cos(a) * r, 0, sin(a) * r)
			hedef.x = clampf(hedef.x, -19, 19)
			hedef.z = clampf(hedef.z, -19, 19)
			Efekt.meteor(hedef, 0.2 + i * 0.13, func(p: Vector3):
				Ses.cal("patlama", -3.0)
				if ana:
					ana.kamera_sars(0.3)
				_alan_hasari(p, 2.6, 2.4, 7.0, true))
	, 1.0)
	if ana:
		ana.mesaj_goster("KÜL KIYAMETİ!", Efekt.ATES_ACIK, true)



# ================================================================== elde görünen silah ve kalkan
var _el_sag: Node3D
var _el_sol: Node3D


func gorunum_guncelle() -> void:
	## Takılı silah elinde, (Muhafız için) kalkan sol kolunda görünür.
	var iskelet: Skeleton3D = model.find_child("Skeleton3D", true, false)
	if iskelet == null:
		return
	var sag := iskelet.find_child("handslot_r", false, false)
	var sol := iskelet.find_child("handslot_l", false, false)
	if is_instance_valid(_el_sag):
		_el_sag.queue_free()
	if is_instance_valid(_el_sol):
		_el_sol.queue_free()
	var silah: Dictionary = esyalar.get("Silah", {})
	var yeni := Esya.model_olustur(str(silah.get("model", ""))) if silah.get("sinif", "") == sinif else null
	if yeni == null and bilgi.has("varsayilan"):
		yeni = Esya.model_olustur(bilgi["varsayilan"])
	if sag:
		for c in sag.get_children():
			if c is MeshInstance3D:
				c.visible = yeni == null
		if yeni:
			sag.add_child(yeni)
			_el_sag = yeni
	var kalkan: Dictionary = esyalar.get("Zırh", {})
	var km := str(kalkan.get("model", ""))
	if sol and km.begins_with("shield") and kalkan.get("sinif", "") == sinif:
		var k := Esya.model_olustur(km)
		if k:
			sol.add_child(k)
			_el_sol = k
