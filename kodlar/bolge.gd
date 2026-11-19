class_name Bolge
extends RefCounted
## Açık bölge: Kül Ovaları. Ortada Son Sığınak köyü (NPC'ler), çevrede dolaşan düşman sürüleri,
## iki zindan girişi, kenarlarda dağlar. Zemin ve ağaçlar MultiMesh ile çizilir (telefonda hızlı).

const YARI := 68.0                       ## oynanabilir alan yarı genişliği
const KOY_YARICAP := 20.0
const KOY := Vector3(0, 0, 0)
const DOGUS := Vector3(0, 0, 6)          ## köyde başlama noktası
const OLCEK_KOY := 4.5

const ZINDANLAR := [
	{"id": "mahzen", "ad": "Yıkık Mahzen", "konum": Vector3(42, 0, -40), "seviye": 1, "boss": "garran", "dalga": 4},
	{"id": "cukur", "ad": "Kemik Çukuru", "konum": Vector3(-46, 0, 40), "seviye": 8, "boss": "vezra", "dalga": 5},
]

const ESNAFLAR := [
	{"id": "demirci", "ad": "Demirci Haldun", "model": "Barbarian", "sakla": ["2H_Axe"], "anim": "Idle", "konum": Vector3(-9.5, 0, 3.0), "renk": Color(1.0, 0.55, 0.2)},
	{"id": "simyaci", "ad": "Simyacı Nevra", "model": "Mage", "sakla": ["Spellbook_open"], "anim": "Idle", "konum": Vector3(9.0, 0, 4.0), "renk": Color(0.4, 1.0, 0.5)},
	{"id": "tuccar", "ad": "Tüccar Kerem", "model": "Rogue_Hooded", "sakla": ["Knife"], "anim": "Idle", "konum": Vector3(0.5, 0, -8.5), "renk": Color(0.8, 0.5, 1.0)},
]

static var _sahneler := {}

const ZEMIN_SHADER := """
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
uniform sampler2D gurultu : repeat_enable, filter_linear_mipmap;
uniform sampler2D gurultu2 : repeat_enable, filter_linear_mipmap;
void fragment() {
	vec2 uv = UV * 22.0;
	float n = texture(gurultu, uv * 0.12).r;
	float m = texture(gurultu2, uv).r;
	vec3 cim = mix(vec3(0.17, 0.25, 0.11), vec3(0.30, 0.36, 0.16), m);
	vec3 kul = mix(vec3(0.30, 0.28, 0.26), vec3(0.42, 0.39, 0.35), m);
	vec3 toprak = vec3(0.33, 0.25, 0.17);
	vec3 c = mix(cim, kul, smoothstep(0.52, 0.72, n));
	c = mix(c, toprak, smoothstep(0.75, 0.9, m) * 0.5);
	ALBEDO = c;
	ROUGHNESS = 0.95;
}
"""
static var suru_noktalari: Array = []    ## düşman sürülerinin doğduğu yerler


static func _yukle(ad: String) -> PackedScene:
	if not _sahneler.has(ad):
		_sahneler[ad] = load("res://assets/koy/%s.glb" % ad)
	return _sahneler[ad]


static func _koy(kok: Node3D, ad: String, konum: Vector3, aci := 0.0, olcek := OLCEK_KOY) -> Node3D:
	var n: Node3D = _yukle(ad).instantiate()
	kok.add_child(n)
	n.position = konum
	n.rotation.y = aci
	n.scale = Vector3.ONE * olcek
	return n


static func _mesh(ad: String) -> Mesh:
	var n := _yukle(ad).instantiate()
	var bulunan: Mesh = null
	for c in n.find_children("*", "MeshInstance3D", true, false):
		bulunan = c.mesh
		break
	n.free()
	return bulunan


static func _cok(kok: Node3D, ad: String, donusumler: Array, golge := false) -> void:
	if donusumler.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _mesh(ad)
	mm.instance_count = donusumler.size()
	for i in donusumler.size():
		mm.set_instance_transform(i, donusumler[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if golge else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	kok.add_child(mmi)


static func _yol_uzerinde(p: Vector3) -> bool:
	for z in ZINDANLAR:
		var a := Vector3(0, 0, 0)
		var b: Vector3 = z["konum"]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		if (a + ab * t).distance_to(p) < 4.0:
			return true
	return false


static func bos_mu(p: Vector3, pay := 3.0) -> bool:
	## Ağaç/kaya koymak için uygun mu: köy, yollar ve zindan girişleri boş kalsın
	if p.distance_to(KOY) < KOY_YARICAP + pay:
		return false
	if _yol_uzerinde(p):
		return false
	for z in ZINDANLAR:
		if p.distance_to(z["konum"]) < 9.0:
			return false
	return true


static func insa(kok: Node3D, mobil: bool) -> StaticBody3D:
	seed(2026)
	var govde := StaticBody3D.new()
	govde.collision_layer = 1
	kok.add_child(govde)

	# --- zemin: tek büyük düzlem, gürültüyle çim ve kül lekeleri (tek çizim, telefonda hızlı)
	var zemin := MeshInstance3D.new()
	var pm0 := PlaneMesh.new()
	pm0.size = Vector2(YARI * 2 + 40, YARI * 2 + 40)
	zemin.mesh = pm0
	var sh := Shader.new()
	sh.code = ZEMIN_SHADER
	var zm := ShaderMaterial.new()
	zm.shader = sh
	for i in 2:
		var nt := NoiseTexture2D.new()
		nt.seamless = true
		nt.width = 256
		nt.height = 256
		var fn := FastNoiseLite.new()
		fn.frequency = 0.012 if i == 0 else 0.05
		fn.seed = 7 + i
		nt.noise = fn
		zm.set_shader_parameter("gurultu" if i == 0 else "gurultu2", nt)
	zemin.material_override = zm
	kok.add_child(zemin)
	var zs := StaticBody3D.new()
	kok.add_child(zs)

	# --- toprak yollar (köyden zindanlara)
	var yol_mat := StandardMaterial3D.new()
	yol_mat.albedo_color = Color(0.42, 0.32, 0.22)
	yol_mat.roughness = 1.0
	for zd in ZINDANLAR:
		var b: Vector3 = zd["konum"]
		var uzunluk := b.length()
		var m := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(4.5, uzunluk)
		m.mesh = pm
		m.material_override = yol_mat
		m.position = b * 0.5 + Vector3(0, 0.03, 0)
		m.rotation.y = atan2(b.x, b.z)
		kok.add_child(m)
	var meydan := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 14.0
	cm.bottom_radius = 14.0
	cm.height = 0.05
	cm.radial_segments = 40
	meydan.mesh = cm
	meydan.material_override = yol_mat
	meydan.position = Vector3(0, 0.02, 0)
	kok.add_child(meydan)

	# --- köy: Son Sığınak
	var binalar := [
		["building_blacksmith_red", Vector3(-15, 0, 4), PI * 0.5],
		["building_tavern_red", Vector3(15, 0, 6), -PI * 0.5],
		["building_market_red", Vector3(0, 0, -15), 0.0],
		["building_church_red", Vector3(-14, 0, -12), PI * 0.25],
		["building_home_A_red", Vector3(13, 0, -11), -PI * 0.3],
		["building_home_B_red", Vector3(-12, 0, 15), PI * 0.8],
		["building_home_A_red", Vector3(10, 0, 16), PI],
		["building_windmill_red", Vector3(-24, 0, -2), PI * 0.5],
		["building_tower_A_red", Vector3(20, 0, -18), 0.0],
		["building_well_red", Vector3(0, 0, 0), 0.0],
	]
	for b in binalar:
		_koy(kok, b[0], b[1], b[2])
		var s := CollisionShape3D.new()
		var c := CylinderShape3D.new()
		c.radius = 2.6 if b[0] != "building_well_red" else 1.3
		c.height = 5.0
		s.shape = c
		s.position = b[1] + Vector3(0, 2.5, 0)
		govde.add_child(s)
	for p in [[Vector3(-11, 0, 7), 0.3], [Vector3(-12, 0, 0), 1.1], [Vector3(11, 0, 1), 0.0], [Vector3(4, 0, -11), 0.5], [Vector3(-3, 0, -11), 1.9]]:
		_koy(kok, ["barrel", "crate_A_big", "weaponrack", "sack", "wheelbarrow"][randi() % 5], p[0], p[1])
	_koy(kok, "weaponrack", Vector3(-11.5, 0, 5.5), PI * 0.5)
	_koy(kok, "resource_lumber", Vector3(-19, 0, 8), 0.4)
	_koy(kok, "tent", Vector3(4, 0, -10), 0.2)
	_koy(kok, "flag_red", Vector3(3, 0, 3), 0.0)
	# köy çiti (yollara kapı bırakarak)
	for i in 36:
		var a := TAU * i / 36.0
		var p := Vector3(cos(a), 0, sin(a)) * (KOY_YARICAP + 1.5)
		if _yol_uzerinde(p) or absf(p.x) < 4.0 and p.z > 0:
			continue
		_koy(kok, "fence_wood_straight", p, -a, OLCEK_KOY * 0.9)
	# köy ışıkları (meydanda iki fener)
	for p in [Vector3(-5, 3.5, 5), Vector3(5, 3.5, -5)]:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.65, 0.3)
		l.light_energy = 2.2
		l.omni_range = 14.0
		l.position = p
		l.visible = Efekt.isik_var()
		kok.add_child(l)

	# --- zindan girişleri
	for zd in ZINDANLAR:
		_zindan_girisi(kok, govde, zd)

	# --- dağlar (kenar) + görünmez duvar
	var daglar := []
	var dag_adlari := ["mountain_A_grass_trees", "mountain_B_grass_trees", "mountain_C_grass"]
	var dag_listesi := {0: [], 1: [], 2: []}
	for i in 64:
		var a := TAU * i / 64.0
		var r := YARI + randf_range(6.0, 12.0)
		var p := Vector3(cos(a) * r, -0.5, sin(a) * r)
		var o := randf_range(7.0, 10.0)
		dag_listesi[i % 3].append(Transform3D(Basis(Vector3.UP, randf() * TAU).scaled(Vector3(o, o, o)), p))
	for k in dag_listesi:
		_cok(kok, dag_adlari[k], dag_listesi[k])
	for kenar in [[Vector3(0, 2, -YARI - 1), Vector3(YARI * 2 + 4, 4, 2)], [Vector3(0, 2, YARI + 1), Vector3(YARI * 2 + 4, 4, 2)],
			[Vector3(-YARI - 1, 2, 0), Vector3(2, 4, YARI * 2 + 4)], [Vector3(YARI + 1, 2, 0), Vector3(2, 4, YARI * 2 + 4)]]:
		var s := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = kenar[1]
		s.shape = bx
		s.position = kenar[0]
		govde.add_child(s)

	# --- ağaçlar ve kayalar (köy, yollar ve girişler boş)
	var agac_adlari := ["trees_A_large", "trees_A_medium", "trees_B_large", "trees_B_medium", "tree_single_A", "tree_single_B"]
	var agaclar := {}
	for ad in agac_adlari:
		agaclar[ad] = []
	var sayi := 90 if mobil else 150
	var deneme := 0
	while sayi > 0 and deneme < 3000:
		deneme += 1
		var p := Vector3(randf_range(-YARI + 2, YARI - 2), 0, randf_range(-YARI + 2, YARI - 2))
		if not bos_mu(p, 7.0):
			continue
		sayi -= 1
		var ad: String = agac_adlari[randi() % agac_adlari.size()]
		var o := randf_range(2.8, 3.6) if ad.begins_with("trees") else randf_range(3.2, 4.2)
		agaclar[ad].append(Transform3D(Basis(Vector3.UP, randf() * TAU).scaled(Vector3(o, o, o)), p))
		if ad.begins_with("tree_single") or ad.ends_with("large"):
			var s := CollisionShape3D.new()
			var c := CylinderShape3D.new()
			c.radius = 0.6 if ad.begins_with("tree_single") else 1.8
			c.height = 4.0
			s.shape = c
			s.position = p + Vector3(0, 2, 0)
			govde.add_child(s)
	for ad in agaclar:
		_cok(kok, ad, agaclar[ad], not mobil)
	var kayalar := {"rock_single_A": [], "rock_single_B": [], "rock_single_C": [], "rock_single_E": [], "hills_B": []}
	for i in 120:
		var p := Vector3(randf_range(-YARI, YARI), 0, randf_range(-YARI, YARI))
		if not bos_mu(p, 2.0):
			continue
		var ad: String = kayalar.keys()[randi() % kayalar.size()]
		var o := randf_range(5.0, 9.0) if ad != "hills_B" else randf_range(4.0, 6.0)
		kayalar[ad].append(Transform3D(Basis(Vector3.UP, randf() * TAU).scaled(Vector3(o, o, o)), p))
	for ad in kayalar:
		_cok(kok, ad, kayalar[ad])

	# --- düşman sürü noktaları
	suru_noktalari.clear()
	deneme = 0
	while suru_noktalari.size() < 22 and deneme < 2000:
		deneme += 1
		var a := randf() * TAU
		var r := randf_range(KOY_YARICAP + 12.0, YARI - 6.0)
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		var uygun := true
		for q in suru_noktalari:
			if q.distance_to(p) < 14.0:
				uygun = false
		for zd in ZINDANLAR:
			if p.distance_to(zd["konum"]) < 10.0:
				uygun = false
		if uygun:
			suru_noktalari.append(p)

	# --- havada süzülen kül
	var kul := GPUParticles3D.new()
	kul.amount = 60 if mobil else 140
	kul.lifetime = 8.0
	kul.preprocess = 8.0
	var pm2 := ParticleProcessMaterial.new()
	pm2.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm2.emission_box_extents = Vector3(22, 4, 22)
	pm2.direction = Vector3(0.3, 1, 0.2)
	pm2.spread = 40
	pm2.initial_velocity_min = 0.2
	pm2.initial_velocity_max = 0.6
	pm2.gravity = Vector3(0, 0.05, 0)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.add_point(0.2, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm2.color_ramp = gt
	kul.process_material = pm2
	var q2 := QuadMesh.new()
	q2.size = Vector2(0.1, 0.1)
	q2.material = Efekt.parca_mat(Color(1.0, 0.55, 0.2), 2.5)
	kul.draw_pass_1 = q2
	kul.name = "Kul"
	kul.local_coords = false
	kul.visibility_aabb = AABB(Vector3(-25, -5, -25), Vector3(50, 12, 50))
	kok.add_child(kul)
	return govde


static func _zindan_girisi(kok: Node3D, govde: StaticBody3D, zd: Dictionary) -> void:
	var p: Vector3 = zd["konum"]
	var giris := Node3D.new()
	kok.add_child(giris)
	giris.position = p
	giris.rotation.y = atan2(-p.x, -p.z)      # kapı köye baksın
	var kapi: Node3D = load("res://assets/zindan/wall_doorway.glb").instantiate()
	giris.add_child(kapi)
	kapi.scale = Vector3.ONE * 1.4
	for x in [-4.2, 4.2]:
		var d: Node3D = load("res://assets/zindan/wall.glb").instantiate()
		giris.add_child(d)
		d.position = Vector3(x * 1.4 * 0.75, 0, 0)
		d.scale = Vector3.ONE * 1.4
	for x in [-6.0, 6.0]:
		var s := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = Vector3(5.5, 5, 1.6)
		s.shape = b
		govde.add_child(s)
		s.global_transform = giris.global_transform * Transform3D(Basis(), Vector3(x, 2.5, 0))
	# girişte parlayan kapı
	var portal := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(3.0, 3.6)
	pm.orientation = PlaneMesh.FACE_Z
	portal.mesh = pm
	portal.material_override = Efekt.parlak_mat(Color(1.0, 0.35, 0.1), 1.3)
	portal.position = Vector3(0, 1.9, 0.2)
	giris.add_child(portal)
	var halka := MeshInstance3D.new()
	halka.mesh = Efekt.halka_mesh(2.2, 3.0)
	halka.material_override = Efekt.parlak_mat(Color(1.0, 0.45, 0.1), 1.5)
	halka.position = Vector3(0, 0.06, 2.5)
	giris.add_child(halka)
	var l := Label3D.new()
	l.text = "%s\nSeviye %d+" % [zd["ad"], zd["seviye"]]
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 72
	l.pixel_size = 0.01
	l.outline_size = 16
	l.modulate = Color(1.0, 0.75, 0.4)
	l.position = Vector3(0, 6.5, 0)
	var f = load("res://assets/font/Cinzel-Black.ttf")
	if f:
		l.font = f
	giris.add_child(l)


static func giris_noktasi(zd: Dictionary) -> Vector3:
	## Zindandan çıkınca belirdiğin yer (kapının köy tarafı)
	var p: Vector3 = zd["konum"]
	return p + (-p).normalized() * 5.0
