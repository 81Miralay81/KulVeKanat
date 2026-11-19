class_name Dunya
extends RefCounted
## 1. bölüm haritası: Kül Ovaları - Yıkık Mahzen. Zemin, duvarlar, sütunlar, meşaleler, süzülen kül.

const YARI := 20.0   ## arena yarı genişliği (40 x 40 m)
const SANDIKLAR := [[Vector3(-17.6, 0, 6), PI * 0.5], [Vector3(-16.8, 0, -16.8), PI * 0.25], [Vector3(5, 0, -17.6), 0.0], [Vector3(16.5, 0, -16.8), -PI * 0.2]]
const SUTUNLAR := [Vector3(-9, 0, -9), Vector3(9, 0, -9), Vector3(-9, 0, 9), Vector3(9, 0, 9)]

static var _sahneler := {}


static func _yukle(ad: String) -> PackedScene:
	if not _sahneler.has(ad):
		_sahneler[ad] = load("res://assets/zindan/%s.glb" % ad)
	return _sahneler[ad]


static func _koy(kok: Node3D, ad: String, konum: Vector3, aci := 0.0, olcek := 1.0) -> Node3D:
	var n: Node3D = _yukle(ad).instantiate()
	kok.add_child(n)
	n.position = konum
	n.rotation.y = aci
	n.scale = Vector3.ONE * olcek
	return n


static func _ilk_mesh(ad: String) -> Mesh:
	var n := _yukle(ad).instantiate()
	var m: MeshInstance3D = n.find_child("*", true, false) if not n is MeshInstance3D else n
	for c in n.find_children("*", "MeshInstance3D", true, false):
		m = c
		break
	var mesh := m.mesh
	n.free()
	return mesh


static func insa(kok: Node3D, mobil: bool) -> void:
	seed(81)
	# --- zemin: çok sayıda karo tek çizimle (MultiMesh, telefonda hızlı)
	for cesit in [["floor_tile_large", 0.8], ["floor_tile_large_rocks", 0.2]]:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _ilk_mesh(cesit[0])
		var konumlar := []
		var x := -YARI + 2.0
		while x < YARI:
			var z := -YARI + 2.0
			while z < YARI:
				var r := hash(Vector2(x, z)) % 100 / 100.0
				if (cesit[0] == "floor_tile_large" and r < 0.8) or (cesit[0] != "floor_tile_large" and r >= 0.8):
					konumlar.append(Vector3(x, 0, z))
				z += 4.0
			x += 4.0
		mm.instance_count = konumlar.size()
		for i in konumlar.size():
			var t := Transform3D(Basis(Vector3.UP, (hash(konumlar[i]) % 4) * PI * 0.5), konumlar[i])
			mm.set_instance_transform(i, t)
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		kok.add_child(mmi)

	# --- arka duvarlar (kameranın karşısı: -x ve -z kenarları)
	var duvarlar := ["wall", "wall", "wall_cracked", "wall", "wall_arched", "wall", "wall_broken", "wall", "wall_cracked", "wall"]
	for i in 10:
		var x := -YARI + 2.0 + i * 4.0
		_koy(kok, duvarlar[i], Vector3(x, 0, -YARI - 0.5), 0.0)
		_koy(kok, duvarlar[(i + 3) % 10], Vector3(-YARI - 0.5, 0, x), PI * 0.5)
	_koy(kok, "wall_corner", Vector3(-YARI - 0.5, 0, -YARI - 0.5), 0.0)
	# meşaleler + ışıklar
	var mesale_sayisi := 3 if mobil else 4
	for i in mesale_sayisi:
		var p: float = -YARI + 6.0 + i * (32.0 / maxi(1, mesale_sayisi - 1))
		_koy(kok, "torch_mounted", Vector3(p, 2.0, -YARI + 0.05), 0.0)
		_isik(kok, Vector3(p, 2.7, -YARI + 1.0))
		_koy(kok, "torch_mounted", Vector3(-YARI + 0.05, 2.0, p), PI * 0.5)
		_isik(kok, Vector3(-YARI + 1.0, 2.7, p))
	_koy(kok, "banner_patternA_red", Vector3(-8, 1.6, -YARI + 0.1), 0.0)
	_koy(kok, "banner_patternA_red", Vector3(8, 1.6, -YARI + 0.1), 0.0)
	_koy(kok, "banner_patternA_red", Vector3(-YARI + 0.1, 1.6, 0), PI * 0.5)

	# --- ön kenarlar (kameraya yakın): görüşü kapatmayan alçak molozlar
	for i in 9:
		var p := -YARI + 3.0 + i * 4.5
		_koy(kok, ["rubble_half", "rubble_large", "barrel_large", "rubble_half"][i % 4], Vector3(YARI + 0.8, 0, p), i * 1.3)
		_koy(kok, ["rubble_large", "rubble_half", "crates_stacked", "rubble_half"][i % 4], Vector3(p, 0, YARI + 0.8), i * 0.7)

	# --- sütunlar (çarpışmalı)
	var govde := StaticBody3D.new()
	govde.collision_layer = 1
	kok.add_child(govde)
	for p in SUTUNLAR:
		_koy(kok, "pillar_decorated", p)
		var s := CollisionShape3D.new()
		var c := CylinderShape3D.new()
		c.radius = 0.9
		c.height = 4.0
		s.shape = c
		s.position = p + Vector3(0, 2, 0)
		govde.add_child(s)
	_koy(kok, "barrel_small_stack", Vector3(-17, 0, -17.5), 0.4)
	_koy(kok, "crates_stacked", Vector3(-17.5, 0, -14), 1.0)
	_koy(kok, "barrel_large", Vector3(-14.5, 0, -17.8), 0.0)

	# --- görünmez sınır duvarları
	for kenar in [[Vector3(0, 1.5, -YARI - 0.5), Vector3(YARI * 2 + 2, 3, 1)], [Vector3(0, 1.5, YARI + 0.5), Vector3(YARI * 2 + 2, 3, 1)],
			[Vector3(-YARI - 0.5, 1.5, 0), Vector3(1, 3, YARI * 2 + 2)], [Vector3(YARI + 0.5, 1.5, 0), Vector3(1, 3, YARI * 2 + 2)]]:
		var s := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = kenar[1]
		s.shape = b
		s.position = kenar[0]
		govde.add_child(s)

	# --- yerde parlayan kor çatlakları (süs)
	for i in 10:
		var p := Vector3(randf_range(-17, 17), 0.03, randf_range(-17, 17))
		var d := MeshInstance3D.new()
		d.mesh = Efekt.disk_mesh(randf_range(0.8, 1.8))
		d.material_override = Efekt.parlak_mat(Color(1.0, 0.28, 0.04), 0.9)
		d.position = p
		kok.add_child(d)

	# --- havada süzülen kül ve kor parçaları
	var kul := GPUParticles3D.new()
	kul.amount = 120 if not mobil else 50
	kul.lifetime = 8.0
	kul.preprocess = 8.0
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(YARI, 3, YARI)
	pm.direction = Vector3(0.3, 1, 0.2)
	pm.spread = 40
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.6
	pm.gravity = Vector3(0, 0.05, 0)
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
	q.material = Efekt.parca_mat(Color(1.0, 0.5, 0.15), 2.5)
	kul.draw_pass_1 = q
	kul.position = Vector3(0, 3, 0)
	kul.visibility_aabb = AABB(Vector3(-YARI, -4, -YARI), Vector3(YARI * 2, 10, YARI * 2))
	kok.add_child(kul)


static func _isik(kok: Node3D, p: Vector3) -> void:
	var l := OmniLight3D.new()
	l.visible = Efekt.isik_var()
	l.light_color = Color(1.0, 0.55, 0.22)
	l.light_energy = 2.2
	l.omni_range = 9.0
	l.omni_attenuation = 1.4
	l.position = p
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
	q.material = Efekt.parca_mat(Color(1.0, 0.5, 0.12), 3.0)
	alev.draw_pass_1 = q
	alev.position = p + Vector3(0, -0.15, 0)
	kok.add_child(alev)
