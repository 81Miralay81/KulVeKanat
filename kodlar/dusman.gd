class_name Dusman
extends CharacterBody3D
## İskelet düşmanlar ve boss. Basit ama canlı yapay zekâ: yaklaş, saldır, geri itil, öl.

signal oldu_sinyal(d: Dusman)

const TURLER := {
	"minyon": {"model": "Skeleton_Minion", "can": 55.0, "hiz": 3.5, "hasar": 9.0, "menzil": 1.5, "xp": 12, "silah": "Skeleton_Blade", "olcek": 1.0, "ad": "Kül İskeleti"},
	"haydut": {"model": "Skeleton_Rogue", "can": 65.0, "hiz": 5.0, "hasar": 11.0, "menzil": 1.5, "xp": 16, "silah": "Skeleton_Blade", "olcek": 0.95, "ad": "Kül Haydudu"},
	"savasci": {"model": "Skeleton_Warrior", "can": 150.0, "hiz": 2.7, "hasar": 18.0, "menzil": 1.8, "xp": 30, "silah": "Skeleton_Axe", "olcek": 1.12, "ad": "Kül Muhafızı"},
	"buyucu": {"model": "Skeleton_Mage", "can": 75.0, "hiz": 2.6, "hasar": 14.0, "menzil": 9.0, "xp": 24, "silah": "Skeleton_Staff", "olcek": 1.0, "uzak": true, "ad": "Kül Büyücüsü"},
	"garran": {"model": "Skeleton_Warrior", "can": 3200.0, "hiz": 3.1, "hasar": 34.0, "menzil": 2.8, "xp": 600, "silah": "Skeleton_Axe", "olcek": 2.3, "boss": true, "ad": "Kor Avcısı Garran"},
}
const DONGU := ["Idle", "Idle_Combat", "Walking_D_Skeletons", "Running_A", "Running_C", "Walking_A", "2H_Melee_Idle"]

var tur := "minyon"
var bilgi: Dictionary
var can := 50.0
var can_max := 50.0
var hasar := 10.0
var hiz := 3.5
var menzil := 1.5
var xp := 10
var elit := false
var boss := false
var olu := false
var yaricap := 0.5
var ad := ""

var kahraman: Node3D
var ana: Node
var model: Node3D
var anim: AnimationPlayer
var _durum := "dogus"         ## dogus, kovala, saldiri, sersem, olu
var _zaman := 0.0
var _saldiri_bekleme := 0.0
var _vurus_zamani := -1.0
var _itme := Vector3.ZERO
var _govdeler: Array[MeshInstance3D] = []
var _flas: StandardMaterial3D
var _flas_deger := 0.0
var _boss_yetenek := 6.0
var _boss_cagir := 14.0
var _etiket: Label3D


func kur(t: String, dalga: int, elit_mi := false) -> void:
	tur = t
	bilgi = TURLER[t]
	boss = bilgi.get("boss", false)
	elit = elit_mi and not boss
	var olcek_can := 1.0 + 0.16 * (dalga - 1)
	can_max = bilgi["can"] * olcek_can * (3.2 if elit else 1.0)
	can = can_max
	hasar = bilgi["hasar"] * (1.0 + 0.09 * (dalga - 1)) * (1.5 if elit else 1.0)
	hiz = bilgi["hiz"] * randf_range(0.9, 1.1) * (1.1 if elit else 1.0)
	menzil = bilgi["menzil"]
	xp = int(bilgi["xp"] * (1.0 + 0.1 * dalga) * (4.0 if elit else 1.0))
	ad = bilgi["ad"]


func _ready() -> void:
	add_to_group("dusman")
	collision_layer = 4
	collision_mask = 1
	var olcek: float = bilgi["olcek"] * (1.35 if elit else 1.0)
	yaricap = 0.45 * olcek
	var sekil := CollisionShape3D.new()
	var kap := CapsuleShape3D.new()
	kap.radius = yaricap
	kap.height = 1.7 * olcek
	sekil.shape = kap
	sekil.position.y = 0.85 * olcek
	add_child(sekil)

	model = load("res://assets/karakter/%s.glb" % bilgi["model"]).instantiate()
	add_child(model)
	model.scale = Vector3.ONE * olcek
	anim = model.find_child("AnimationPlayer", true, false)
	for a in DONGU:
		if anim.has_animation(a):
			anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
	var iskelet: Skeleton3D = model.find_child("Skeleton3D", true, false)
	if iskelet and bilgi.has("silah"):
		var el := BoneAttachment3D.new()
		el.bone_name = "handslot.r"
		iskelet.add_child(el)
		var s: Node3D = load("res://assets/silah/%s.glb" % bilgi["silah"]).instantiate()
		el.add_child(s)
	for m in model.find_children("*", "MeshInstance3D", true, false):
		_govdeler.append(m)
	_flas = StandardMaterial3D.new()
	_flas.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flas.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flas.albedo_color = Color(1, 1, 1, 0)
	if elit or boss:
		var renk := Color(1.0, 0.35, 0.05) if boss else Color(1.0, 0.75, 0.2)
		var isik := OmniLight3D.new()
		isik.light_color = renk
		isik.light_energy = 2.0 if boss else 1.0
		isik.omni_range = 5.0 if boss else 3.0
		isik.position = Vector3(0, 1.5 * olcek, 0)
		add_child(isik)
		var aura := MeshInstance3D.new()
		aura.mesh = Efekt.halka_mesh(0.8, 1.2)
		aura.material_override = Efekt.parlak_mat(renk, 1.8)
		aura.scale = Vector3.ONE * olcek
		aura.position.y = 0.05
		add_child(aura)
	if elit:
		_etiket = Label3D.new()
		_etiket.text = ad + " · Elit"
		_etiket.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_etiket.no_depth_test = true
		_etiket.font_size = 56
		_etiket.pixel_size = 0.006
		_etiket.outline_size = 14
		_etiket.modulate = Color(1.0, 0.82, 0.3)
		_etiket.position.y = 2.6 * olcek
		var f = load("res://assets/font/Rajdhani-Bold.ttf")
		if f:
			_etiket.font = f
		add_child(_etiket)
	# Yerden çıkış
	_durum = "dogus"
	var dogus_anim := "Spawn_Ground_Skeletons" if anim.has_animation("Spawn_Ground_Skeletons") else "Idle"
	anim.play(dogus_anim)
	anim.speed_scale = 1.4
	_zaman = 1.1 if not boss else 1.6
	Efekt.parcacik(global_position + Vector3(0, 0.2, 0), 14, Color(0.35, 0.3, 0.27, 0.8), 1.0, 2.5, -3.0, 0.7, 50.0, true, false, Vector3(0.5, 0.1, 0.5), 1.0)
	_saldiri_bekleme = randf_range(0.3, 1.0)


func _physics_process(dt: float) -> void:
	if olu:
		return
	_flas_deger = maxf(0.0, _flas_deger - dt * 6.0)
	_flas.albedo_color.a = _flas_deger * 0.8
	var flas_acik := _flas_deger > 0.01
	for m in _govdeler:
		m.material_overlay = _flas if flas_acik else null
	_saldiri_bekleme -= dt
	_itme = _itme.move_toward(Vector3.ZERO, dt * 30.0)

	if _durum == "dogus":
		_zaman -= dt
		if _zaman <= 0:
			_durum = "kovala"
			anim.speed_scale = 1.0
		return

	if kahraman == null or not is_instance_valid(kahraman):
		return
	var fark := kahraman.global_position - global_position
	fark.y = 0
	var mesafe := fark.length()
	var yon := fark.normalized() if mesafe > 0.01 else Vector3.FORWARD
	var kahraman_olu: bool = kahraman.durum == "olu"

	match _durum:
		"kovala":
			var istenen := Vector3.ZERO
			if kahraman_olu:
				istenen = Vector3.ZERO
			elif bilgi.get("uzak", false):
				if mesafe > 7.5:
					istenen = yon
				elif mesafe < 5.0:
					istenen = -yon
				if mesafe < menzil and _saldiri_bekleme <= 0:
					_buyu_saldirisi(yon)
			else:
				if mesafe > menzil * 0.85:
					istenen = yon
				elif _saldiri_bekleme <= 0:
					_yakin_saldiri()
			istenen += _ayrisma() * 1.4
			if boss:
				_boss_dusun(dt, mesafe)
			velocity = istenen.limit_length(1.0) * hiz + _itme
			if istenen.length() > 0.1:
				_don(istenen)
				_oynat("Running_C" if (tur == "haydut" or elit) and anim.has_animation("Running_C") else "Walking_D_Skeletons", clampf(velocity.length() / 3.0, 0.7, 1.7))
			else:
				_don(yon)
				_oynat("Idle_Combat" if anim.has_animation("Idle_Combat") else "Idle", 1.0)
		"saldiri":
			velocity = _itme
			_don(yon)
			_zaman -= dt
			if _vurus_zamani >= 0:
				_vurus_zamani -= dt
				if _vurus_zamani < 0:
					if not bilgi.get("uzak", false) and mesafe < menzil + 0.9 and not kahraman_olu:
						kahraman.hasar_al(hasar)
						if boss and ana:
							ana.kamera_sars(0.4)
			if _zaman <= 0:
				_durum = "kovala"
		"sersem":
			velocity = _itme
			_zaman -= dt
			if _zaman <= 0:
				_durum = "kovala"
	move_and_slide()
	global_position.y = 0.0


func _don(y: Vector3) -> void:
	if y.length() < 0.01:
		return
	var hedef := atan2(y.x, y.z)
	model.rotation.y = lerp_angle(model.rotation.y, hedef, 0.2)


func _oynat(a: String, h := 1.0) -> void:
	if not anim.has_animation(a):
		a = "Idle"
	if anim.current_animation != a:
		anim.play(a, 0.15)
	anim.speed_scale = h


func _ayrisma() -> Vector3:
	# Düşmanlar üst üste binmesin
	var itis := Vector3.ZERO
	for d in get_tree().get_nodes_in_group("dusman"):
		if d == self or d.olu:
			continue
		var f: Vector3 = global_position - d.global_position
		f.y = 0
		var m := f.length()
		var sinir: float = yaricap + d.yaricap + 0.25
		if m < sinir and m > 0.001:
			itis += f / m * (sinir - m) / sinir
	return itis


func _yakin_saldiri() -> void:
	_durum = "saldiri"
	var a := "1H_Melee_Attack_Chop" if randf() < 0.6 else "1H_Melee_Attack_Slice_Diagonal"
	if boss:
		a = "2H_Melee_Attack_Chop"
	anim.play(a, 0.08)
	anim.speed_scale = 1.0 if not boss else 0.8
	_zaman = 1.05 if not boss else 1.4
	_vurus_zamani = 0.5 if not boss else 0.8
	_saldiri_bekleme = randf_range(1.2, 1.9) if not boss else 1.6
	if boss:
		Efekt.yer_isareti(global_position + model.global_transform.basis.z * 2.0, 2.4, 0.75)


func _buyu_saldirisi(yon: Vector3) -> void:
	_durum = "saldiri"
	anim.play("Spellcast_Shoot", 0.08)
	anim.speed_scale = 1.0
	_zaman = 0.9
	_vurus_zamani = -1
	_saldiri_bekleme = randf_range(2.2, 3.2)
	get_tree().create_timer(0.45, false).timeout.connect(func():
		if not olu and is_inside_tree():
			_mermi_at())


func _mermi_at() -> void:
	var m := Mermi.new()
	m.hasar = hasar
	m.kahraman = kahraman
	get_parent().add_child(m)
	m.global_position = global_position + Vector3(0, 1.4, 0) + model.global_transform.basis.z * 0.6
	var hedef := kahraman.global_position + Vector3(0, 1.0, 0)
	m.yon = (hedef - m.global_position).normalized()
	Ses.cal("buyu", -8.0)


func _boss_dusun(dt: float, mesafe: float) -> void:
	_boss_yetenek -= dt
	_boss_cagir -= dt
	if _boss_yetenek <= 0 and _durum == "kovala":
		_boss_yetenek = randf_range(7.0, 9.0)
		# alev halkası: etrafında uyarı, sonra patlama
		_durum = "saldiri"
		anim.play("2H_Melee_Attack_Spin" if anim.has_animation("2H_Melee_Attack_Spin") else "Taunt", 0.1)
		anim.speed_scale = 0.7
		_zaman = 1.6
		_vurus_zamani = -1
		var merkez := global_position
		Efekt.yer_isareti(merkez, 5.5, 1.1)
		get_tree().create_timer(1.1, false).timeout.connect(func():
			if olu or not is_inside_tree():
				return
			Efekt.patlama(merkez, 5.0, Color(1.0, 0.3, 0.05))
			Ses.cal("patlama")
			if ana:
				ana.kamera_sars(0.8)
			if kahraman.global_position.distance_to(merkez) < 5.5:
				kahraman.hasar_al(hasar * 1.6))
	if _boss_cagir <= 0:
		_boss_cagir = 16.0
		if ana:
			ana.boss_cagirisi(global_position)


func hasar_al(miktar: float, kritik: bool, kaynak: Vector3, itme: float) -> void:
	if olu or _durum == "dogus":
		return
	can -= miktar
	_flas_deger = 1.0
	var renk := Color(1.0, 0.82, 0.2) if kritik else Color(1, 1, 1)
	Efekt.hasar_yazisi(global_position + Vector3(0, 2.2 * model.scale.y / 1.0 * 0.8 + 0.4, 0), str(int(miktar)) + ("!" if kritik else ""), renk, kritik)
	Efekt.vurus_kivilcim(global_position + Vector3(0, 1.0, 0), kritik)
	if kritik:
		Ses.cal("kritik", -3.0)
	var f := global_position - kaynak
	f.y = 0
	var direnc := 0.15 if boss else (0.5 if elit else 1.0)
	if f.length() > 0.01:
		_itme = f.normalized() * itme * direnc
	if can <= 0:
		_ol()
		return
	if not boss and _durum != "saldiri" and itme >= 2.5:
		_durum = "sersem"
		_zaman = 0.28
		anim.play("Hit_A" if randf() < 0.5 else "Hit_B", 0.05)
		anim.speed_scale = 1.6


func _ol() -> void:
	olu = true
	_durum = "olu"
	remove_from_group("dusman")
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO
	for m in _govdeler:
		m.material_overlay = null
	anim.play("Death_A" if randf() < 0.5 else "Death_B", 0.05)
	anim.speed_scale = 1.3
	Efekt.olum_kulu(global_position)
	Ses.cal("olum", -4.0)
	oldu_sinyal.emit(self)
	if _etiket:
		_etiket.queue_free()
	var tw := create_tween()
	tw.tween_interval(1.3)
	tw.tween_property(self, "position:y", -1.6, 1.0)
	tw.tween_callback(queue_free)
