class_name Dusman
extends CharacterBody3D
## İskelet düşmanlar ve boss. Basit ama canlı yapay zekâ: yaklaş, saldır, geri itil, öl.

signal oldu_sinyal(d: Dusman)

## can/hasar seviye 1 değerleridir; seviyeyle büyür. xp = tür çarpanı.
const TURLER := {
	"minyon": {"model": "KulOlusu", "can": 55.0, "hiz": 3.5, "hasar": 9.0, "menzil": 1.5, "xp": 1.0, "olcek": 1.0, "ad": "Kül Ölüsü"},
	"haydut": {"model": "Haydut", "can": 65.0, "hiz": 5.0, "hasar": 11.0, "menzil": 1.5, "xp": 1.2, "olcek": 1.0, "ad": "Haydut"},
	"savasci": {"model": "KaraSovalye", "can": 150.0, "hiz": 2.7, "hasar": 18.0, "menzil": 1.8, "xp": 2.2, "olcek": 1.08, "ad": "Kara Şövalye"},
	"buyucu": {"model": "Kultcu", "can": 75.0, "hiz": 2.6, "hasar": 14.0, "menzil": 9.0, "xp": 1.7, "olcek": 1.0, "uzak": true, "ad": "Kültçü"},
	"garran": {"model": "KaraSovalye", "can": 3600.0, "hiz": 3.1, "hasar": 30.0, "menzil": 2.8, "xp": 45.0, "olcek": 2.3, "boss": true, "ad": "Kor Avcısı Garran"},
	"vezra": {"model": "Kultcu", "can": 3400.0, "hiz": 2.4, "hasar": 26.0, "menzil": 11.0, "xp": 50.0, "olcek": 2.2, "boss": true, "uzak": true, "ad": "Kemik Rahibi Vezra"},
	"morvas": {"model": "KaraSovalye", "can": 4000.0, "hiz": 3.3, "hasar": 32.0, "menzil": 2.9, "xp": 55.0, "olcek": 2.5, "boss": true, "ad": "Yanık Lord Morvaş", "renk": Color(1.3, 0.75, 0.6)},
	"buzpence": {"model": "Haydut", "can": 3800.0, "hiz": 4.2, "hasar": 30.0, "menzil": 2.5, "xp": 55.0, "olcek": 2.3, "boss": true, "ad": "Buz Pençe", "renk": Color(0.7, 0.9, 1.3)},
	"kiravan": {"model": "Kultcu", "can": 3600.0, "hiz": 2.5, "hasar": 28.0, "menzil": 12.0, "xp": 58.0, "olcek": 2.3, "boss": true, "uzak": true, "ad": "Kırağı Rahibesi Kiravan", "renk": Color(0.75, 0.9, 1.3)},
	"ayazkral": {"model": "KaraSovalye", "can": 4600.0, "hiz": 3.0, "hasar": 34.0, "menzil": 3.0, "xp": 65.0, "olcek": 2.7, "boss": true, "ad": "Ayaz Kral Hirvald", "renk": Color(0.7, 0.85, 1.35)},
	"sahra": {"model": "Haydut", "can": 4200.0, "hiz": 4.4, "hasar": 32.0, "menzil": 2.6, "xp": 65.0, "olcek": 2.4, "boss": true, "ad": "Kum Hayaleti Sahra", "renk": Color(1.3, 1.0, 0.7)},
	"lavkral": {"model": "KaraSovalye", "can": 5000.0, "hiz": 2.9, "hasar": 36.0, "menzil": 3.0, "xp": 70.0, "olcek": 2.8, "boss": true, "ad": "Lav Kralı Ateşgöz", "renk": Color(1.4, 0.6, 0.4)},
	"korkral": {"model": "Kultcu", "can": 6200.0, "hiz": 2.8, "hasar": 38.0, "menzil": 12.0, "xp": 90.0, "olcek": 3.0, "boss": true, "uzak": true, "ad": "Kor Kral", "renk": Color(1.3, 0.55, 1.0)},
}
const DONGU := ["Idle", "Sword_Idle", "Walk", "Sprint", "Jog_Fwd", "Spell_Simple_Idle"]
## Eski (KayKit) hareket adı -> gerçekçi manken hareketi
const ANIM := {
	"Idle": "Idle", "Idle_Combat": "Sword_Idle", "Walking_D_Skeletons": "Walk", "Running_C": "Jog_Fwd", "Running_A": "Sprint",
	"1H_Melee_Attack_Chop": "Sword_Attack", "1H_Melee_Attack_Slice_Diagonal": "Sword_Attack", "2H_Melee_Attack_Chop": "Sword_Attack",
	"Spellcast_Shoot": "Spell_Simple_Shoot", "2H_Melee_Attack_Spin": "Sword_Attack", "Taunt": "Spell_Simple_Shoot",
	"Hit_A": "Hit_Chest", "Hit_B": "Hit_Head", "Death_A": "Death01", "Death_B": "Death01", "Spawn_Ground_Skeletons": "Idle",
}

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
var aggro := true            ## false: oyuncu yaklaşana (ya da vurana) kadar yerinde bekler
var seviye := 1
var zindanda := false
var renk_ton := Color(1, 1, 1)
var _seviye_etiket: Label3D
static var _ton_cache := {}

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
var _flas_acik := false
var _yavas := 0.0
var _boss_yetenek := 6.0
var _boss_cagir := 14.0
var _etiket: Label3D
var _cubuk: MeshInstance3D
var _cubuk_mat: ShaderMaterial
var _cubuk_gorunur := 0.0

const CUBUK_SHADER := """
shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled, shadows_disabled;
uniform float doluluk = 1.0;
uniform vec4 renk : source_color = vec4(0.9, 0.15, 0.1, 1.0);
uniform float gorunur = 1.0;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	float kenar = step(UV.x, 0.015) + step(0.985, UV.x) + step(UV.y, 0.14) + step(0.86, UV.y);
	vec3 c = UV.x < doluluk ? renk.rgb : vec3(0.1, 0.03, 0.03);
	if (kenar > 0.0) { c = vec3(0.0); }
	ALBEDO = c;
	ALPHA = 0.92 * gorunur;
}
"""
static var _cubuk_shader: Shader


## seviye: düşmanın sabit seviyesi (1-60). zindan: zindan düşmanları daha güçlü.
func kur(t: String, sev: int, elit_mi := false, zindan := false) -> void:
	tur = t
	bilgi = TURLER[t]
	seviye = clampi(sev, 1, 63)
	zindanda = zindan
	boss = bilgi.get("boss", false)
	elit = elit_mi and not boss
	var L := float(seviye - 1)
	can_max = bilgi["can"] * (1.0 + 0.28 * L) * (1.4 if zindan else 1.0) * (3.2 if elit else 1.0)
	can = can_max
	hasar = bilgi["hasar"] * (1.0 + 0.13 * L) * (1.25 if zindan else 1.0) * (1.5 if elit else 1.0)
	hiz = bilgi["hiz"] * randf_range(0.9, 1.1) * (1.1 if elit else 1.0)
	menzil = bilgi["menzil"]
	xp = int(round(14.0 * pow(float(seviye), 0.85) * float(bilgi["xp"]) * (4.0 if elit else 1.0) * (1.3 if zindan else 1.0)))
	ad = bilgi["ad"]
	if bilgi.has("renk"):
		renk_ton = bilgi["renk"]


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
	model.scale = Vector3.ONE * olcek * 1.08
	anim = model.find_child("AnimationPlayer", true, false)
	for a in DONGU:
		if _var(a):
			anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
	for m in model.find_children("*", "MeshInstance3D", true, false):
		_govdeler.append(m)
		if renk_ton != Color(1, 1, 1):
			_tonla(m)
	_flas = StandardMaterial3D.new()
	_flas.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flas.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flas.albedo_color = Color(1, 1, 1, 0)
	if elit or boss:
		var renk := Color(1.0, 0.35, 0.05) if boss else Color(1.0, 0.75, 0.2)
		var isik := OmniLight3D.new()
		isik.visible = Efekt.isik_var()
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
	# Can çubuğu (başının üstünde; normal düşmanlarda ilk vuruştan sonra, elit ve boss'ta hep görünür)
	if _cubuk_shader == null:
		_cubuk_shader = Shader.new()
		_cubuk_shader.code = CUBUK_SHADER
	_cubuk = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.9, 0.2) if boss else (Vector2(1.3, 0.16) if elit else Vector2(0.95, 0.13))
	_cubuk.mesh = q
	_cubuk_mat = ShaderMaterial.new()
	_cubuk_mat.shader = _cubuk_shader
	_cubuk_mat.render_priority = 20
	_cubuk_mat.set_shader_parameter("renk", Color(1.0, 0.45, 0.05) if boss else (Color(1.0, 0.7, 0.15) if elit else Color(0.9, 0.15, 0.1)))
	_cubuk.material_override = _cubuk_mat
	_cubuk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cubuk.position.y = 2.2 * olcek + 0.25
	add_child(_cubuk)
	_cubuk_gorunur = 1.0
	_cubuk_mat.set_shader_parameter("gorunur", _cubuk_gorunur)
	_seviye_etiket = Label3D.new()
	_seviye_etiket.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_seviye_etiket.no_depth_test = true
	_seviye_etiket.render_priority = 21
	_seviye_etiket.font_size = 44
	_seviye_etiket.pixel_size = 0.0055
	_seviye_etiket.outline_size = 12
	_seviye_etiket.text = ("Sv.%d" % seviye) if not boss else ("Sv.%d · %s" % [seviye, ad])
	_seviye_etiket.position.y = _cubuk.position.y + 0.24
	var f2 = load("res://assets/font/Rajdhani-Bold.ttf")
	if f2:
		_seviye_etiket.font = f2
	add_child(_seviye_etiket)
	seviye_rengi_guncelle()
	if _etiket:
		_etiket.position.y = _cubuk.position.y + 0.5
	# Yerden çıkış
	_durum = "dogus"
	_cal("Idle")
	anim.speed_scale = 1.0
	model.position.y = -1.9 * model.scale.y
	var tw0 := create_tween()
	tw0.tween_property(model, "position:y", 0.0, 0.9 if not boss else 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_zaman = 1.1 if not boss else 1.6
	Efekt.parcacik(global_position + Vector3(0, 0.2, 0), 14, Color(0.35, 0.3, 0.27, 0.8), 1.0, 2.5, -3.0, 0.7, 50.0, true, false, Vector3(0.5, 0.1, 0.5), 1.0)
	_saldiri_bekleme = randf_range(0.3, 1.0)


## Seviye yazısının rengi: gri = senden 6+ seviye düşük (tecrübe/eşya yok), kırmızı = çok güçlü
func seviye_rengi_guncelle() -> void:
	if _seviye_etiket == null or kahraman == null:
		return
	var fark: int = int(kahraman.seviye) - seviye
	var r := Color(0.95, 0.92, 0.85)
	if fark >= 6:
		r = Color(0.55, 0.55, 0.55)
	elif fark <= -5:
		r = Color(1.0, 0.25, 0.2)
	elif fark <= -2:
		r = Color(1.0, 0.6, 0.25)
	_seviye_etiket.modulate = r


func _tonla(m: MeshInstance3D) -> void:
	if m.mesh == null:
		return
	for i in m.mesh.get_surface_count():
		var asil := m.get_active_material(i)
		if asil is StandardMaterial3D:
			var anahtar := "%d_%s" % [asil.get_instance_id(), renk_ton.to_html()]
			if not _ton_cache.has(anahtar):
				var yeni: StandardMaterial3D = asil.duplicate()
				yeni.albedo_color = asil.albedo_color * renk_ton
				_ton_cache[anahtar] = yeni
			m.set_surface_override_material(i, _ton_cache[anahtar])


func _physics_process(dt: float) -> void:
	if olu:
		return
	_flas_deger = maxf(0.0, _flas_deger - dt * 6.0)
	_flas.albedo_color.a = _flas_deger * 0.8
	var flas_acik := _flas_deger > 0.01
	if flas_acik != _flas_acik:
		_flas_acik = flas_acik
		for m in _govdeler:
			m.material_overlay = _flas if flas_acik else null
	_saldiri_bekleme -= dt
	_yavas = maxf(0.0, _yavas - dt)
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

	# açık bölgede: yaklaşınca saldırır, köye giren oyuncunun peşini bırakır
	if ana and ana.mod == "bolge":
		if ana.koyde_mi():
			aggro = false
		elif not aggro and mesafe < (20.0 if boss else 13.0):
			aggro = true
	match _durum:
		"kovala":
			var istenen := Vector3.ZERO
			if kahraman_olu or not aggro:
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
			velocity = istenen.limit_length(1.0) * hiz * (0.4 if _yavas > 0 else 1.0) + _itme
			if istenen.length() > 0.1:
				_don(istenen)
				_oynat("Running_C" if (tur == "haydut" or elit) and _var("Running_C") else "Walking_D_Skeletons", clampf(velocity.length() / 3.0, 0.7, 1.7))
			else:
				_don(yon)
				_oynat("Idle_Combat" if _var("Idle_Combat") else "Idle", 1.0)
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
	global_position.y = ana.zemin_y(global_position.x, global_position.z) if ana else 0.0


func _don(y: Vector3) -> void:
	if y.length() < 0.01:
		return
	var hedef := atan2(y.x, y.z)
	model.rotation.y = lerp_angle(model.rotation.y, hedef, 0.2)


func _oynat(a: String, h := 1.0) -> void:
	var g: String = ANIM.get(a, a)
	if not anim.has_animation(g):
		g = "Idle"
	if anim.current_animation != g:
		anim.play(g, 0.15)
	anim.speed_scale = h


func _var(a: String) -> bool:
	return anim.has_animation(ANIM.get(a, a))


func _cal(a: String, gecis := -1.0) -> void:
	var g: String = ANIM.get(a, a)
	if anim.has_animation(g):
		anim.play(g, gecis)


func _ayrisma() -> Vector3:
	# Düşmanlar üst üste binmesin
	var itis := Vector3.ZERO
	var liste: Array = ana.dusmanlar if ana else get_tree().get_nodes_in_group("dusman")
	for d in liste:
		if d == self or not is_instance_valid(d) or d.olu:
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
	_cal(a, 0.08)
	anim.speed_scale = 1.0 if not boss else 0.8
	_zaman = 1.05 if not boss else 1.4
	_vurus_zamani = 0.5 if not boss else 0.8
	_saldiri_bekleme = randf_range(1.2, 1.9) if not boss else 1.6
	if boss:
		Efekt.yer_isareti(global_position + model.global_transform.basis.z * 2.0, 2.4, 0.75)


func _buyu_saldirisi(yon: Vector3) -> void:
	_durum = "saldiri"
	_cal("Spellcast_Shoot", 0.08)
	anim.speed_scale = 1.0
	_zaman = 0.9
	_vurus_zamani = -1
	_saldiri_bekleme = randf_range(2.2, 3.2)
	get_tree().create_timer(0.45, false).timeout.connect(func():
		if not olu and is_inside_tree():
			if boss:
				for i in 5:
					_mermi_at(deg_to_rad(-30.0 + i * 15.0))
			else:
				_mermi_at())


func _mermi_at(aci := 0.0) -> void:
	var m := Mermi.new()
	m.hasar = hasar
	m.kahraman = kahraman
	get_parent().add_child(m)
	m.global_position = global_position + Vector3(0, 1.4, 0) + model.global_transform.basis.z * 0.6
	var hedef := kahraman.global_position + Vector3(0, 1.0, 0)
	m.yon = (hedef - m.global_position).normalized().rotated(Vector3.UP, aci)
	Ses.cal("buyu", -8.0)


func _boss_dusun(dt: float, mesafe: float) -> void:
	_boss_yetenek -= dt
	_boss_cagir -= dt
	if _boss_yetenek <= 0 and _durum == "kovala":
		_boss_yetenek = randf_range(7.0, 9.0)
		# alev halkası: etrafında uyarı, sonra patlama
		_durum = "saldiri"
		_cal("2H_Melee_Attack_Spin" if _var("2H_Melee_Attack_Spin") else "Taunt", 0.1)
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
	aggro = true
	_flas_deger = 1.0
	_cubuk_gorunur = 1.0
	_cubuk_mat.set_shader_parameter("gorunur", 1.0)
	_cubuk_mat.set_shader_parameter("doluluk", clampf(can / can_max, 0.0, 1.0))
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
		_cal("Hit_A" if randf() < 0.5 else "Hit_B", 0.05)
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
	_cal("Death_A" if randf() < 0.5 else "Death_B", 0.05)
	anim.speed_scale = 1.3
	Efekt.olum_kulu(global_position)
	Ses.cal("olum", -4.0)
	oldu_sinyal.emit(self)
	if _cubuk:
		_cubuk.queue_free()
	if _etiket:
		_etiket.queue_free()
	var tw := create_tween()
	tw.tween_interval(1.3)
	tw.tween_property(self, "position:y", -1.6, 1.0)
	tw.tween_callback(queue_free)



func yavaslat(sure: float) -> void:
	_yavas = maxf(_yavas, sure)
