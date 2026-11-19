class_name Dunya
extends RefCounted
## Zindan arenası: gerçek dokulu taş zemin ve duvarlar. Her zindanın kendi teması (taş, kemik, kor,
## buz, son) ve kendi sütun düzeni var; aynı yere girmiş gibi hissettirmesin.

const YARI := 20.0   ## arena yarı genişliği (40 x 40 m)
const SANDIKLAR := [[Vector3(-17.6, 0, 6), PI * 0.5], [Vector3(-16.8, 0, -16.8), PI * 0.25], [Vector3(5, 0, -17.6), 0.0], [Vector3(16.5, 0, -16.8), -PI * 0.2]]
static var SUTUNLAR: Array = []

## tema -> [zemin tonu, duvar tonu, ışık rengi, çatlak rengi, pürüz]
const TEMALAR := [
	[Color(0.62, 0.6, 0.58), Color(0.7, 0.68, 0.65), Color(1.0, 0.58, 0.25), Color(1.0, 0.32, 0.05), 0.85],   # taş mahzen
	[Color(0.55, 0.5, 0.42), Color(0.62, 0.56, 0.48), Color(0.65, 1.0, 0.55), Color(0.4, 1.0, 0.3), 0.9],     # kemik çukuru
	[Color(0.32, 0.26, 0.24), Color(0.42, 0.33, 0.3), Color(1.0, 0.42, 0.15), Color(1.0, 0.3, 0.03), 0.8],    # kor
	[Color(0.7, 0.8, 0.92), Color(0.72, 0.82, 0.95), Color(0.5, 0.75, 1.0), Color(0.4, 0.8, 1.0), 0.35],      # buz
	[Color(0.25, 0.22, 0.3), Color(0.32, 0.28, 0.4), Color(0.75, 0.4, 1.0), Color(0.8, 0.3, 1.0), 0.6],       # son mezar
]
const DUZENLER := [
	[Vector3(-9, 0, -9), Vector3(9, 0, -9), Vector3(-9, 0, 9), Vector3(9, 0, 9)],
	[Vector3(0, 0, -10), Vector3(8.7, 0, -5), Vector3(8.7, 0, 5), Vector3(0, 0, 10), Vector3(-8.7, 0, 5), Vector3(-8.7, 0, -5)],
	[Vector3(-11, 0, -4), Vector3(-11, 0, 6), Vector3(11, 0, -4), Vector3(11, 0, 6), Vector3(0, 0, -11)],
	[Vector3(-6, 0, -12), Vector3(6, 0, -12), Vector3(-13, 0, 0), Vector3(13, 0, 0), Vector3(-6, 0, 12), Vector3(6, 0, 12)],
]


static func _kutu(kok: Node3D, boyut: Vector3, konum: Vector3, aci: float, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = boyut
	m.mesh = b
	m.material_override = mat
	m.position = konum
	m.rotation.y = aci
	kok.add_child(m)
	return m


static func insa(kok: Node3D, mobil: bool, tema := 0, tohum := 0) -> void:
	seed(tohum)
	var t: Array = TEMALAR[clampi(tema, 0, TEMALAR.size() - 1)]
	SUTUNLAR = DUZENLER[absi(tohum) % DUZENLER.size()].duplicate()
	# --- zemin: taş döşeme (gerçek doku) + kor/buz çatlakları
	var zemin := MeshInstance3D.new()
	var pm0 := PlaneMesh.new()
	pm0.size = Vector2(YARI * 2 + 6, YARI * 2 + 6)
	zemin.mesh = pm0
	var zm := Arazi.duvar_mat("tugla.jpg", "tugla_nrm.jpg", 0.22, t[0])
	zm.roughness = t[4]
	zemin.material_override = zm
	kok.add_child(zemin)
	var kaya := Arazi.kaya_mat(t[1])
	kaya.uv1_scale = Vector3.ONE * 0.22
	# --- arka duvarlar (kameranın karşısı: -x ve -z) ve payandalar
	for kenar in [[Vector3(0, 3.0, -YARI - 0.8), Vector3(YARI * 2 + 3, 6.0, 1.6), 0.0], [Vector3(-YARI - 0.8, 3.0, 0), Vector3(YARI * 2 + 3, 6.0, 1.6), PI * 0.5]]:
		_kutu(kok, kenar[1], kenar[0], kenar[2], kaya)
		for i in 6:
			var u := -YARI + 3.0 + i * 7.0
			var p: Vector3 = Vector3(u, 3.4, -YARI + 0.1) if kenar[2] == 0.0 else Vector3(-YARI + 0.1, 3.4, u)
			_kutu(kok, Vector3(1.3, 6.8, 1.2), p, kenar[2], kaya)
	# meşaleler + ışıklar
	var mesale_sayisi := 3 if mobil else 4
	for i in mesale_sayisi:
		var p: float = -YARI + 6.0 + i * (32.0 / maxi(1, mesale_sayisi - 1))
		_isik(kok, Vector3(p, 2.7, -YARI + 0.9), t[2])
		_isik(kok, Vector3(-YARI + 0.9, 2.7, p), t[2])
	# --- ön kenarlar (kameraya yakın): görüşü kapatmayan alçak kayalar
	var kmesh := []
	for ad in ["RockA", "RockB", "RockC"]:
		var n: Node3D = load("res://assets/arazi/%s.glb" % ad).instantiate()
		for c in n.find_children("*", "MeshInstance3D", true, false):
			kmesh.append((c as MeshInstance3D).mesh)
			break
		n.free()
	var kenar_kayalar := [[], [], []]
	for i in 16:
		var p := -YARI + 1.0 + i * 2.6
		for q in [Vector3(YARI + 1.2, -0.3, p), Vector3(p, -0.3, YARI + 1.2)]:
			kenar_kayalar[i % 3].append(Transform3D(Basis.from_euler(Vector3(0, randf() * TAU, 0)).scaled(Vector3(randf_range(0.35, 0.6), randf_range(0.2, 0.4), randf_range(0.35, 0.6))), q))
	for i in 3:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		var m: Mesh = kmesh[i].duplicate()
		for si in m.get_surface_count():
			m.surface_set_material(si, kaya)
		mm.mesh = m
		mm.instance_count = kenar_kayalar[i].size()
		for k in kenar_kayalar[i].size():
			mm.set_instance_transform(k, kenar_kayalar[i][k])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		kok.add_child(mmi)

	# --- sütunlar (çarpışmalı)
	var govde := StaticBody3D.new()
	govde.collision_layer = 1
	kok.add_child(govde)
	for p in SUTUNLAR:
		_kutu(kok, Vector3(2.0, 0.6, 2.0), p + Vector3(0, 0.3, 0), 0.0, kaya)
		var sut := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.65
		cm.bottom_radius = 0.75
		cm.height = 5.5
		cm.radial_segments = 12
		sut.mesh = cm
		sut.material_override = kaya
		sut.position = p + Vector3(0, 3.3, 0)
		kok.add_child(sut)
		_kutu(kok, Vector3(1.8, 0.5, 1.8), p + Vector3(0, 6.1, 0), 0.0, kaya)
		var s := CollisionShape3D.new()
		var c := CylinderShape3D.new()
		c.radius = 0.95
		c.height = 4.0
		s.shape = c
		s.position = p + Vector3(0, 2, 0)
		govde.add_child(s)

	# --- görünmez sınır duvarları
	for kenar in [[Vector3(0, 1.5, -YARI - 0.5), Vector3(YARI * 2 + 2, 3, 1)], [Vector3(0, 1.5, YARI + 0.5), Vector3(YARI * 2 + 2, 3, 1)],
			[Vector3(-YARI - 0.5, 1.5, 0), Vector3(1, 3, YARI * 2 + 2)], [Vector3(YARI + 0.5, 1.5, 0), Vector3(1, 3, YARI * 2 + 2)]]:
		var s := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = kenar[1]
		s.shape = b
		s.position = kenar[0]
		govde.add_child(s)

	# --- yerde parlayan çatlaklar (süs)
	for i in 6:
		var p := Vector3(randf_range(-17, 17), 0.03, randf_range(-17, 17))
		var d := MeshInstance3D.new()
		d.mesh = Efekt.disk_mesh(randf_range(0.5, 1.1))
		d.material_override = Efekt.parlak_mat(t[3], 0.35)
		d.position = p
		kok.add_child(d)

	# --- havada süzülen kül / kar / kor parçaları
	var kul := GPUParticles3D.new()
	kul.amount = 120 if not mobil else 50
	kul.lifetime = 8.0
	kul.preprocess = 8.0
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(YARI, 3, YARI)
	pm.direction = Vector3(0.3, 1, 0.2) if tema != 3 else Vector3(0.2, -1, 0.1)
	pm.spread = 40
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.6
	pm.gravity = Vector3(0, 0.05, 0) if tema != 3 else Vector3(0, -0.3, 0)
	pm.turbulence_enabled = not mobil
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.add_point(0.2, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	kul.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	q.material = Efekt.parca_mat(t[3] if tema != 3 else Color(0.9, 0.95, 1.0), 2.0)
	kul.draw_pass_1 = q
	kul.position = Vector3(0, 3, 0)
	kul.visibility_aabb = AABB(Vector3(-YARI, -4, -YARI), Vector3(YARI * 2, 10, YARI * 2))
	kok.add_child(kul)


static func _isik(kok: Node3D, p: Vector3, renk: Color) -> void:
	var tut := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.18, 0.7, 0.18)
	tut.mesh = b
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.2, 0.15, 0.1)
	tut.material_override = m
	tut.position = p + Vector3(0, -0.5, 0)
	kok.add_child(tut)
	var l := OmniLight3D.new()
	l.visible = Efekt.isik_var()
	l.light_color = renk
	l.light_energy = 2.4
	l.omni_range = 10.0
	l.omni_attenuation = 1.4
	l.position = p + Vector3(0, 0.3, 0)
	kok.add_child(l)
	var alev := GPUParticles3D.new()
	alev.amount = 10
	alev.lifetime = 0.6
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 12
	pm.initial_velocity_min = 0.6
	pm.initial_velocity_max = 1.2
	pm.gravity = Vector3(0, 1.0, 0)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	alev.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.35, 0.35)
	q.material = Efekt.parca_mat(renk, 3.0)
	alev.draw_pass_1 = q
	alev.position = p
	kok.add_child(alev)
