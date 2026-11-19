class_name Kahraman
extends CharacterBody3D
## Oyuncu karakteri: Kılıç Muhafızı. Hareket, saldırı, 4 yetenek, son vuruş, seviye ve eşyalar.

signal oldu
signal seviye_atladi(seviye: int)
signal esya_alindi(esya: Dictionary, takildi: bool)
signal yetenek_acildi(ad: String)

const HIZ := 6.2
const KOSU_ANIM_HIZI := 5.6    ## Running_A animasyonunun doğal hızı (ayak kaymasın diye)

var ana: Node                  ## ana sahne (kamera sarsıntısı, düşman listesi)
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
var temel := {"hasar": 28.0, "can": 320.0, "mana": 120.0, "kritik": 8.0, "hiz": 0.0, "zirh": 0.0}

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

var bekleme := {"yetenek1": 0.0, "yetenek2": 0.0, "yetenek3": 0.0, "yetenek4": 0.0, "iksir": 0.0}
const BEKLEME := {"yetenek1": 8.0, "yetenek2": 5.0, "yetenek3": 3.5, "yetenek4": 10.0, "iksir": 10.0}
const MANA := {"yetenek1": 35.0, "yetenek2": 30.0, "yetenek3": 15.0, "yetenek4": 50.0}
const ACILMA := {"yetenek1": 1, "yetenek3": 2, "yetenek2": 3, "yetenek4": 5}
const YETENEK_AD := {"yetenek1": "Kor Kasırgası", "yetenek2": "Yer Yarma", "yetenek3": "Kanat Atılımı",
	"yetenek4": "Meteor Yağmuru", "son_vurus": "Kanat Açılımı", "saldir": "Kılıç Darbesi", "iksir": "İksir"}

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

	model = load("res://assets/karakter/Knight.glb").instantiate()
	add_child(model)
	model.scale = Vector3.ONE * 1.05
	anim = model.find_child("AnimationPlayer", true, false)
	for ad in DONGU_ANIMLARI:
		if anim.has_animation(ad):
			anim.get_animation(ad).loop_mode = Animation.LOOP_LINEAR
	for ad in ["1H_Sword", "1H_Sword_Offhand", "Badge_Shield", "Rectangle_Shield", "Round_Shield", "Spike_Shield"]:
		var n := model.find_child(ad, true, false)
		if n:
			n.get_parent().remove_child(n)
			n.queue_free()
	for m in model.find_children("*", "MeshInstance3D", true, false):
		_govdeler.append(m)
	_flas_mat = StandardMaterial3D.new()
	_flas_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flas_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flas_mat.albedo_color = Color(1, 0.1, 0.05, 0.0)

	kanat = Kanat.new()
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
	anim.play("2H_Melee_Idle")


# ------------------------------------------------------------------ özellikler
func deger(k: String) -> float:
	var v: float = temel.get(k, 0.0)
	for y in esyalar:
		v += float(esyalar[y]["ozellik"].get(k, 0.0))
	return v


func _ozellikleri_hesapla() -> void:
	temel["hasar"] = 28.0 + (seviye - 1) * 5.0
	temel["can"] = 320.0 + (seviye - 1) * 42.0
	temel["mana"] = 120.0 + (seviye - 1) * 8.0


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


func esya_al(e: Dictionary) -> void:
	var y: String = e["yuva"]
	var takildi := Esya.puan(e) > Esya.puan(esyalar.get(y, {}))
	if takildi:
		var oran := can / maxf(1.0, deger("can"))
		esyalar[y] = e
		can = deger("can") * oran
	else:
		altin += 15 + e["seviye"] * 3 * (e["nadirlik"] + 1)
	esya_alindi.emit(e, takildi)


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
		_oynat("2H_Melee_Idle", 0.2)
		return
	mana = minf(deger("mana"), mana + (7.0 + seviye * 0.3) * dt)
	if _son_vurus_sure > 0:
		_son_vurus_sure -= dt
		if _son_vurus_sure <= 0:
			kanat.ac(0.35)
	_hasar_flas = maxf(0.0, _hasar_flas - dt * 4.0)
	_flas_mat.albedo_color.a = _hasar_flas * 0.55
	for m in _govdeler:
		m.material_overlay = _flas_mat if _hasar_flas > 0.01 else null

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
		_oynat("2H_Melee_Idle", 0.18, 1.0)


func _oynat(ad: String, gecis := 0.1, hiz := 1.0, bastan := false) -> void:
	if not anim.has_animation(ad):
		ad = "Idle"
	if bastan or anim.current_animation != ad:
		anim.play(ad, gecis)
		if bastan:
			anim.seek(0.0, true)
	anim.speed_scale = hiz


func _girdi_isle() -> void:
	var istek := _istek
	if istek != "":
		_istek = ""
		if istek == "yetenek1" and _yetenek_hazir("yetenek1"):
			_kasirga_baslat()
			return
		if istek == "yetenek2" and _yetenek_hazir("yetenek2"):
			_yer_yarma()
			return
		if istek == "yetenek3" and _yetenek_hazir("yetenek3"):
			_atilim()
			return
		if istek == "yetenek4" and _yetenek_hazir("yetenek4"):
			_meteor()
			return
		if istek == "son_vurus":
			if ofke >= 100.0:
				_son_vurus()
			elif ana:
				ana.mesaj_goster("Kanat Açılımı henüz dolmadı", Color(1, 0.7, 0.4))
			return
		if istek == "iksir":
			_iksir_ic()
			return
		if istek == "saldir":
			_temel_saldiri()
			return
	if Input.is_action_pressed("saldir"):
		_temel_saldiri()


func _yetenek_hazir(ad: String) -> bool:
	if not acik_mi(ad):
		if ana:
			ana.mesaj_goster("%s seviye %d'de açılır" % [YETENEK_AD[ad], ACILMA[ad]], Color(0.8, 0.8, 0.8))
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
	ofke = 0.0
	_son_vurus_sure = 10.0
	kanat.ac(1.0)
	_dokunulmaz = 1.0
	_eylem_baslat("2H_Melee_Attack_Spin", 0.9, 0.35, func():
		Efekt.kanat_tuyu_patlamasi(global_position)
		Ses.cal("patlama", 0.0)
		if ana:
			ana.kamera_sars(1.0)
			ana.vurus_duraklat(0.12)
		_alan_hasari(global_position, 8.0, 4.5, 14.0, true)
	, 1.2)
	if ana:
		ana.mesaj_goster("KANAT AÇILIMI!", Efekt.ATES_ACIK, true)


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
	if sonuc[1] and ana:
		ana.vurus_duraklat(0.035)


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
	var azalan := miktar * (1.0 - clampf(deger("zirh"), 0.0, 60.0) / 100.0)
	can -= azalan
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
	anim.play("2H_Melee_Idle", 0.2)
	kanat.ac(0.35)
