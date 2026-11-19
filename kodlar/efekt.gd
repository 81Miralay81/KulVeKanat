class_name Efekt
extends RefCounted
## Görsel efektler: parlayan halkalar, kıvılcımlar, patlamalar, ışık sütunları, hasar yazıları.
## Hepsi kodla üretilir; dış dosya gerekmez.

const ATES := Color(1.0, 0.42, 0.08)
const ATES_ACIK := Color(1.0, 0.78, 0.35)
const SIMSEK := Color(0.45, 0.7, 1.0)
const ALTIN := Color(1.0, 0.82, 0.35)

static var _malzemeler := {}
static var _parca_doku: Texture2D
static var _sahne: Node3D   ## efektlerin ekleneceği dünya düğümü
static var mobil := false

const PARLAK_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 renk : source_color = vec4(1.0, 0.45, 0.1, 1.0);
uniform float guc = 2.0;
uniform float saydam = 1.0;
void fragment() {
	ALBEDO = renk.rgb * guc * COLOR.rgb;
	ALPHA = COLOR.a * saydam;
}
"""

const SUTUN_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 renk : source_color = vec4(1.0, 0.5, 0.1, 1.0);
uniform float guc = 2.0;
uniform float saydam = 1.0;
varying float h;
void vertex() { h = UV.y; }
void fragment() {
	float kenar = pow(1.0 - abs(dot(NORMAL, VIEW)), 1.5);
	float a = pow(h, 1.6) * (0.35 + kenar * 0.65);
	ALBEDO = renk.rgb * guc;
	ALPHA = a * saydam;
}
"""


static func kur(sahne: Node3D, mobil_mi: bool) -> void:
	_sahne = sahne
	mobil = mobil_mi


# ------------------------------------------------------------------ malzemeler
static func parlak_mat(renk: Color, guc := 2.0) -> ShaderMaterial:
	var anahtar := "p%s%.2f" % [renk.to_html(), guc]
	if _malzemeler.has(anahtar):
		return _malzemeler[anahtar]
	var sh := Shader.new()
	sh.code = PARLAK_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("renk", renk)
	m.set_shader_parameter("guc", guc)
	_malzemeler[anahtar] = m
	return m


static func yeni_parlak_mat(renk: Color, guc := 2.0) -> ShaderMaterial:
	## Ayrı kopya (saydamlığı tek başına sönümlemek için).
	return parlak_mat(renk, guc).duplicate()


static func sutun_mat(renk: Color, guc := 2.0) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = SUTUN_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("renk", renk)
	m.set_shader_parameter("guc", guc)
	return m


static func parca_doku() -> Texture2D:
	if _parca_doku == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.6))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(0.5, 0.0)
		t.width = 64
		t.height = 64
		_parca_doku = t
	return _parca_doku


static func parca_mat(renk: Color, guc := 3.0, katki := true) -> StandardMaterial3D:
	var anahtar := "pm%s%.1f%s" % [renk.to_html(), guc, katki]
	if _malzemeler.has(anahtar):
		return _malzemeler[anahtar]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if katki else BaseMaterial3D.BLEND_MODE_MIX
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = parca_doku()
	m.albedo_color = Color(renk.r * guc, renk.g * guc, renk.b * guc, renk.a)
	m.no_depth_test = false
	m.disable_receive_shadows = true
	_malzemeler[anahtar] = m
	return m


# ------------------------------------------------------------------ geometri
static func halka_mesh(ic: float, dis: float, parca := 64) -> ArrayMesh:
	## Yumuşak kenarlı düz halka (ortası parlak, kenarlar saydam).
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var orta := (ic + dis) * 0.5
	var r := [ic, orta, dis]
	var a := [0.0, 1.0, 0.0]
	for i in parca:
		var a0 := TAU * i / parca
		var a1 := TAU * (i + 1) / parca
		for k in 2:
			var p00 := Vector3(cos(a0) * r[k], 0, sin(a0) * r[k])
			var p01 := Vector3(cos(a0) * r[k + 1], 0, sin(a0) * r[k + 1])
			var p10 := Vector3(cos(a1) * r[k], 0, sin(a1) * r[k])
			var p11 := Vector3(cos(a1) * r[k + 1], 0, sin(a1) * r[k + 1])
			var c0 := Color(1, 1, 1, a[k])
			var c1 := Color(1, 1, 1, a[k + 1])
			st.set_color(c0); st.add_vertex(p00)
			st.set_color(c1); st.add_vertex(p01)
			st.set_color(c1); st.add_vertex(p11)
			st.set_color(c0); st.add_vertex(p00)
			st.set_color(c1); st.add_vertex(p11)
			st.set_color(c0); st.add_vertex(p10)
	return st.commit()


static func disk_mesh(yaricap: float, parca := 48) -> ArrayMesh:
	## Ortası dolu, kenara doğru sönen disk.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in parca:
		var a0 := TAU * i / parca
		var a1 := TAU * (i + 1) / parca
		st.set_color(Color(1, 1, 1, 0.9)); st.add_vertex(Vector3.ZERO)
		st.set_color(Color(1, 1, 1, 0)); st.add_vertex(Vector3(cos(a0), 0, sin(a0)) * yaricap)
		st.set_color(Color(1, 1, 1, 0)); st.add_vertex(Vector3(cos(a1), 0, sin(a1)) * yaricap)
	return st.commit()


static func sarmal_mesh(yaricap: float, yukseklik: float, tur := 1.2, genislik := 0.35, parca := 60) -> ArrayMesh:
	## Karakterin etrafında dönen alev şeridi.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var onceki: Array = []
	for i in parca + 1:
		var u := float(i) / parca
		var a := u * TAU * tur
		var r := yaricap * (0.85 + 0.15 * sin(u * 6.0))
		var y := 0.25 + u * yukseklik
		var merkez := Vector3(cos(a) * r, y, sin(a) * r)
		var w := genislik * sin(PI * u)
		var alt := merkez - Vector3(0, w * 0.5, 0)
		var ust := merkez + Vector3(0, w * 0.5, 0)
		var alfa := sin(PI * u)
		if onceki.size() > 0:
			var c0 := Color(1, 1, 1, onceki[2])
			var c1 := Color(1, 1, 1, alfa)
			st.set_color(c0); st.add_vertex(onceki[0])
			st.set_color(c0); st.add_vertex(onceki[1])
			st.set_color(c1); st.add_vertex(ust)
			st.set_color(c0); st.add_vertex(onceki[0])
			st.set_color(c1); st.add_vertex(ust)
			st.set_color(c1); st.add_vertex(alt)
		onceki = [alt, ust, alfa]
	return st.commit()


# ------------------------------------------------------------------ yardımcılar
static func _ekle(n: Node3D, konum: Vector3) -> Node3D:
	if _sahne == null or not is_instance_valid(_sahne):
		return n
	_sahne.add_child(n)
	n.global_position = konum
	return n


static func _sil_sonra(n: Node, sure: float) -> void:
	if n.is_inside_tree():
		n.get_tree().create_timer(sure, false).timeout.connect(n.queue_free)


static var _pm_onbellek := {}
static var _quad_onbellek := {}
static var _aktif_parcacik := 0
static var sinir := 70          ## aynı anda en fazla bu kadar parçacık efekti (takılmayı önler)
static var kalite := 1.0        ## 0.5 düşük, 1.0 orta/yüksek


static func _surec_malzemesi(omur: float, hiz: float, yercekimi: float, yayilma: float, yukari: bool, kutu: Vector3) -> ParticleProcessMaterial:
	var anahtar := "%.2f|%.1f|%.1f|%.0f|%s|%s" % [omur, hiz, yercekimi, yayilma, yukari, kutu]
	if _pm_onbellek.has(anahtar):
		return _pm_onbellek[anahtar]
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP if yukari else Vector3.FORWARD
	pm.spread = yayilma
	pm.initial_velocity_min = hiz * 0.4
	pm.initial_velocity_max = hiz
	pm.gravity = Vector3(0, yercekimi, 0)
	pm.damping_min = 1.0
	pm.damping_max = 3.0
	pm.scale_min = 0.5
	pm.scale_max = 1.2
	if kutu != Vector3.ZERO:
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = kutu
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	var sc := Curve.new()
	sc.add_point(Vector2(0, 1))
	sc.add_point(Vector2(1, 0.2))
	var sct := CurveTexture.new()
	sct.curve = sc
	pm.scale_curve = sct
	_pm_onbellek[anahtar] = pm
	return pm


static func _quad(boyut: float, renk: Color, guc: float, katki: bool) -> QuadMesh:
	var anahtar := "%.2f|%s|%.1f|%s" % [boyut, renk.to_html(), guc, katki]
	if _quad_onbellek.has(anahtar):
		return _quad_onbellek[anahtar]
	var q := QuadMesh.new()
	q.size = Vector2(boyut, boyut)
	q.material = parca_mat(renk, guc, katki)
	_quad_onbellek[anahtar] = q
	return q


static func parcacik(konum: Vector3, adet: int, renk: Color, omur := 0.8, hiz := 5.0,
		yercekimi := -4.0, boyut := 0.25, yayilma := 180.0, yukari := true, katki := true,
		kutu := Vector3.ZERO, guc := 3.0) -> GPUParticles3D:
	if _sahne == null or not is_instance_valid(_sahne):
		return null
	if _aktif_parcacik >= sinir:
		return null
	var p := GPUParticles3D.new()
	adet = maxi(3, int(adet * kalite * (0.6 if mobil else 1.0)))
	p.amount = adet
	p.lifetime = omur
	p.one_shot = true
	p.explosiveness = 0.92
	p.local_coords = false
	p.process_material = _surec_malzemesi(omur, hiz, yercekimi, yayilma, yukari, kutu)
	p.draw_pass_1 = _quad(boyut, renk, guc, katki)
	p.visibility_aabb = AABB(Vector3(-8, -2, -8), Vector3(16, 12, 16))
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ekle(p, konum)
	p.emitting = true
	_aktif_parcacik += 1
	p.tree_exited.connect(func(): _aktif_parcacik -= 1)
	_sil_sonra(p, omur + 0.6)
	return p


static func isinma(konum: Vector3) -> void:
	## Açılışta her efekt türünü bir kez çalıştırır: gölgelendiriciler önceden derlenir,
	## oyunda ilk kullanımda takılma olmaz.
	vurus_kivilcim(konum)
	vurus_kivilcim(konum, true)
	olum_kulu(konum)
	patlama(konum, 2.0)
	halka_dalga(konum, ATES)
	yer_isareti(konum, 2.0, 0.3)
	isik_sutunu(konum, ALTIN, 3.0, 0.5, 0.4)
	hasar_yazisi(konum, "0", Color.WHITE)
	parcacik(konum, 4, Color(0.7, 0.3, 1.0), 0.35, 0.5, 0.0, 0.35, 180.0)
	parcacik(konum, 4, Color(1, 0.25, 0.25), 1.0, 3.0, 2.0, 0.3, 30.0, true, true, Vector3(0.5, 0.2, 0.5))


static func isik_flas(konum: Vector3, renk: Color, enerji := 6.0, menzil := 7.0, sure := 0.35) -> void:
	var l := OmniLight3D.new()
	l.light_color = renk
	l.light_energy = enerji
	l.omni_range = menzil
	l.shadow_enabled = false
	_ekle(l, konum)
	if l.is_inside_tree():
		var tw := l.create_tween()
		tw.tween_property(l, "light_energy", 0.0, sure)
		tw.tween_callback(l.queue_free)


static func halka_dalga(konum: Vector3, renk: Color, bas_r := 0.5, son_r := 4.0, sure := 0.45, kalinlik := 0.5, guc := 3.0) -> void:
	var m := MeshInstance3D.new()
	m.mesh = halka_mesh(1.0 - kalinlik * 0.5, 1.0 + kalinlik * 0.5)
	var mat := yeni_parlak_mat(renk, guc)
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ekle(m, konum + Vector3(0, 0.06, 0))
	m.scale = Vector3.ONE * bas_r
	if m.is_inside_tree():
		var tw := m.create_tween().set_parallel(true)
		tw.tween_property(m, "scale", Vector3.ONE * son_r, sure).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_method(func(v): mat.set_shader_parameter("saydam", v), 1.0, 0.0, sure)
		tw.chain().tween_callback(m.queue_free)


static func yer_isareti(konum: Vector3, yaricap: float, sure: float, renk := Color(1, 0.15, 0.05)) -> void:
	## Tehlike uyarısı: yerde kırmızı daire (boss saldırıları, meteorlar).
	var kok := Node3D.new()
	_ekle(kok, konum + Vector3(0, 0.05, 0))
	var dis := MeshInstance3D.new()
	dis.mesh = halka_mesh(yaricap - 0.12, yaricap + 0.05)
	dis.material_override = parlak_mat(renk, 2.0)
	kok.add_child(dis)
	var ic := MeshInstance3D.new()
	ic.mesh = disk_mesh(yaricap)
	var mat := yeni_parlak_mat(renk, 0.8)
	ic.material_override = mat
	kok.add_child(ic)
	ic.scale = Vector3(0.05, 1, 0.05)
	if kok.is_inside_tree():
		var tw := kok.create_tween()
		tw.tween_property(ic, "scale", Vector3.ONE, sure)
		tw.tween_callback(kok.queue_free)


static func hasar_yazisi(konum: Vector3, metin: String, renk: Color, buyuk := false) -> void:
	var l := Label3D.new()
	l.text = metin
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = false
	l.font_size = 120 if buyuk else 80
	l.pixel_size = 0.006
	l.outline_size = 22
	l.modulate = renk
	l.outline_modulate = Color(0.08, 0.03, 0.0, 1)
	l.render_priority = 10
	l.outline_render_priority = 9
	var f = load("res://assets/font/Rajdhani-Bold.ttf")
	if f:
		l.font = f
	var kayma := Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5))
	_ekle(l, konum + kayma)
	if l.is_inside_tree():
		l.scale = Vector3.ONE * (0.4 if buyuk else 0.6)
		var tw := l.create_tween().set_parallel(true)
		tw.tween_property(l, "scale", Vector3.ONE * (1.25 if buyuk else 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(l, "position:y", l.position.y + 1.6, 0.9).set_ease(Tween.EASE_OUT)
		tw.tween_property(l, "modulate:a", 0.0, 0.35).set_delay(0.55)
		tw.tween_property(l, "outline_modulate:a", 0.0, 0.35).set_delay(0.55)
		tw.chain().tween_callback(l.queue_free)


# ------------------------------------------------------------------ hazır efektler
static func vurus_kivilcim(konum: Vector3, kritik := false) -> void:
	parcacik(konum, 14 if kritik else 8, ATES_ACIK if kritik else Color(1, 0.9, 0.7), 0.35, 7.0, -10.0, 0.18, 70.0)


static func olum_kulu(konum: Vector3) -> void:
	parcacik(konum + Vector3(0, 0.8, 0), 22, Color(0.45, 0.42, 0.4, 0.9), 1.2, 3.0, 1.0, 0.55, 180.0, true, false, Vector3(0.4, 0.6, 0.4), 1.0)
	parcacik(konum + Vector3(0, 0.8, 0), 12, ATES, 0.9, 4.0, 2.0, 0.15, 180.0)


static func patlama(konum: Vector3, yaricap := 2.5, renk := ATES) -> void:
	parcacik(konum + Vector3(0, 0.4, 0), 40, renk, 0.7, yaricap * 4.0, -6.0, 0.6, 85.0)
	parcacik(konum + Vector3(0, 0.3, 0), 30, ATES_ACIK, 0.45, yaricap * 6.0, -14.0, 0.22, 80.0)
	parcacik(konum + Vector3(0, 0.6, 0), 14, Color(0.18, 0.14, 0.12, 0.8), 1.4, 2.5, 1.5, 1.4, 60.0, true, false, Vector3(0.5, 0.3, 0.5), 1.0)
	halka_dalga(konum, renk, 0.3, yaricap * 1.3, 0.4, 0.35, 4.0)
	isik_flas(konum + Vector3(0, 1.2, 0), renk, 9.0, yaricap * 4.0, 0.45)
	var d := MeshInstance3D.new()
	d.mesh = disk_mesh(yaricap * 0.9)
	var mat := yeni_parlak_mat(renk, 2.5)
	d.material_override = mat
	_ekle(d, konum + Vector3(0, 0.07, 0))
	if d.is_inside_tree():
		var tw := d.create_tween()
		tw.tween_method(func(v): mat.set_shader_parameter("saydam", v), 1.0, 0.0, 0.6)
		tw.tween_callback(d.queue_free)


static func isik_sutunu(konum: Vector3, renk: Color, yukseklik := 8.0, yaricap := 0.5, sure := -1.0, guc := 2.2) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = yaricap * 0.6
	c.bottom_radius = yaricap
	c.height = yukseklik
	c.cap_top = false
	c.cap_bottom = false
	c.radial_segments = 24
	m.mesh = c
	var mat := sutun_mat(renk, guc)
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ekle(m, konum + Vector3(0, yukseklik * 0.5, 0))
	if sure > 0 and m.is_inside_tree():
		var tw := m.create_tween()
		tw.tween_interval(sure * 0.5)
		tw.tween_method(func(v): mat.set_shader_parameter("saydam", v), 1.0, 0.0, sure * 0.5)
		tw.tween_callback(m.queue_free)
	return m


static func seviye_atlama(hedef: Node3D) -> void:
	var p := hedef.global_position
	isik_sutunu(p, ALTIN, 9.0, 1.1, 1.6, 2.5)
	halka_dalga(p, ALTIN, 0.5, 5.0, 0.7, 0.4, 3.0)
	parcacik(p + Vector3(0, 0.3, 0), 50, ALTIN, 1.6, 6.0, 1.5, 0.2, 25.0, true, true, Vector3(0.8, 0.1, 0.8))
	isik_flas(p + Vector3(0, 2, 0), ALTIN, 8.0, 10.0, 1.2)


static func meteor(hedef: Vector3, gecikme: float, bitince: Callable) -> void:
	## Gökten düşen alev topu: önce yerde uyarı, sonra çarpma ve patlama.
	if _sahne == null:
		return
	yer_isareti(hedef, 2.4, gecikme + 0.35, Color(1, 0.35, 0.05))
	var top := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.55
	s.height = 1.1
	top.mesh = s
	top.material_override = parlak_mat(ATES_ACIK, 4.0)
	top.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var bas := hedef + Vector3(-4.0, 14.0, -4.0)
	_ekle(top, bas)
	top.visible = false
	var iz := GPUParticles3D.new()
	iz.amount = 24 if not mobil else 12
	iz.lifetime = 0.45
	iz.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.spread = 25.0
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 1.5
	pm.gravity = Vector3.ZERO
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	iz.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.9, 0.9)
	q.material = parca_mat(ATES, 3.0)
	iz.draw_pass_1 = q
	top.add_child(iz)
	var isik := OmniLight3D.new()
	isik.light_color = ATES
	isik.light_energy = 5.0
	isik.omni_range = 6.0
	top.add_child(isik)
	if not top.is_inside_tree():
		return
	var tw := top.create_tween()
	tw.tween_interval(gecikme)
	tw.tween_callback(func(): top.visible = true)
	tw.tween_property(top, "global_position", hedef + Vector3(0, 0.4, 0), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		patlama(hedef, 2.4)
		bitince.call(hedef)
		top.queue_free())


static func kanat_tuyu_patlamasi(konum: Vector3) -> void:
	parcacik(konum + Vector3(0, 1.4, 0), 60, ATES, 1.4, 12.0, -2.0, 0.5, 180.0)
	parcacik(konum + Vector3(0, 1.0, 0), 40, ATES_ACIK, 0.9, 16.0, -6.0, 0.25, 180.0)
	halka_dalga(konum, ATES_ACIK, 0.5, 9.0, 0.6, 0.25, 5.0)
	halka_dalga(konum, ATES, 0.5, 7.0, 0.8, 0.5, 3.0)
	isik_flas(konum + Vector3(0, 2, 0), ATES, 14.0, 16.0, 0.9)


static func ganimet_isigi(renk: Color) -> Color:
	return renk
