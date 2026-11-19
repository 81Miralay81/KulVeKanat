class_name Arazi
extends RefCounted
## Gerçekçi tepeli arazi: yükseklik ızgarası, gerçek dokulu zemin, oyuncuyu izleyen çimen,
## gerçek yapraklı ağaçlar, kayalar ve kenarda dağlar. Dokular: ambientCG (CC0), Godot demo
## projeleri (MIT), Babylon.js varlıkları (CC BY 4.0).

const ALAN := 480.0            ## yükseklik ızgarasının kapsadığı alan (m)
const COZ := 241               ## ızgara çözünürlüğü (2 m)

static var _h := PackedFloat32Array()
static var _yari := 150.0
static var _sehir_r := 32.0
static var _duzlukler: Array = []   ## [Vector3 merkez, yarıçap]
static var _yollar: Array = []      ## [Vector2 a, Vector2 b]
static var hm_doku: ImageTexture    ## yükseklik (R) ve çimen yoğunluğu (G)
static var _cache := {}

const ZEMIN_SHADER := """
shader_type spatial;
uniform sampler2D a_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D a_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D k_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D k_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D t_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D y_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D hm : filter_linear;
uniform int tema = 0;
uniform vec3 a_ton : source_color = vec3(1.0);
uniform vec3 k_ton : source_color = vec3(1.0);
uniform float sehir_r = 32.0;
uniform float alan = 480.0;
varying vec3 dpos;
varying vec3 dnor;
void vertex(){ dpos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; dnor = NORMAL; }
float h(vec2 p){ return fract(sin(dot(p, vec2(127.1,311.7)))*43758.5453); }
float gr(vec2 p){ vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(h(i),h(i+vec2(1,0)),f.x), mix(h(i+vec2(0,1)),h(i+vec2(1,1)),f.x), f.y); }
void fragment(){
	vec2 uv1 = dpos.xz * 0.11;
	vec2 uv2 = dpos.xz * 0.027 + vec2(0.31, 0.77);
	vec4 c1 = texture(a_alb, uv1); vec4 c2 = texture(a_alb, uv2);
	float v = gr(dpos.xz * 0.045) * 0.6 + gr(dpos.xz * 0.21) * 0.4;
	vec3 taban = mix(c1.rgb, c2.rgb, 0.45) * a_ton * mix(0.8, 1.12, v);

	vec3 kaya = mix(texture(k_alb, dpos.xz * 0.08).rgb, texture(k_alb, vec2(dpos.x + dpos.z, dpos.y) * 0.08).rgb, 0.5) * k_ton;
	float egim = 1.0 - clamp(dnor.y, 0.0, 1.0);
	float k = smoothstep(0.2, 0.4, egim + (c1.a - 0.5) * 0.25);
	vec3 c = mix(taban, kaya, k);
	vec3 n = mix(mix(texture(a_nrm, uv1).rgb, texture(a_nrm, uv2).rgb, 0.4), texture(k_nrm, dpos.xz * 0.08).rgb, k);
	float rough = mix(tema == 1 ? 0.55 : 0.95, 0.82, k);
	// toprak yollar (yükseklik dokusunun B kanalı)
	vec4 bilgi = texture(hm, dpos.xz / alan + 0.5);
	float yol = smoothstep(0.25, 0.75, bilgi.b + (v - 0.5) * 0.35);
	vec3 toprak = texture(y_alb, dpos.xz * 0.2).rgb;
	c = mix(c, toprak, yol * (1.0 - k));
	// şehir meydanı: taş döşeme
	float d = length(dpos.xz);
	float meydan = 1.0 - smoothstep(sehir_r - 14.0, sehir_r - 11.0, d + (v - 0.5) * 3.0);
	vec3 tas = texture(t_alb, dpos.xz * 0.22).rgb;
	c = mix(c, tas, meydan);
	rough = mix(rough, 0.75, meydan);
	ALBEDO = c;
	NORMAL_MAP = n;
	NORMAL_MAP_DEPTH = 1.0 - meydan * 0.6;
	ROUGHNESS = rough;
	SPECULAR = 0.3;
}
"""

const CIMEN_SHADER := """
shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_disabled;
uniform sampler2D hm : filter_linear;
uniform vec3 merkez = vec3(0.0);
uniform float karo = 48.0;
uniform float alan = 480.0;
uniform vec3 alt_renk : source_color = vec3(0.16,0.20,0.07);
uniform vec3 ust_renk : source_color = vec3(0.52,0.56,0.28);
varying float rnd;
varying float gizle;
void vertex(){
	vec3 o = (MODEL_MATRIX * vec4(0,0,0,1)).xyz;
	vec2 kayma = merkez.xz - mod(merkez.xz, karo);
	vec2 p = o.xz + kayma;
	if (p.x - merkez.x > karo * 0.5) p.x -= karo; if (merkez.x - p.x > karo * 0.5) p.x += karo;
	if (p.y - merkez.z > karo * 0.5) p.y -= karo; if (merkez.z - p.y > karo * 0.5) p.y += karo;
	vec4 b = textureLod(hm, p / alan + 0.5, 0.0);
	rnd = fract(sin(dot(o.xz, vec2(12.9,78.2)))*43758.5);
	float uzak = length(p - merkez.xz) / (karo * 0.5);
	gizle = step(b.g, rnd) + step(0.92, uzak);
	float boy = mix(0.55, 1.15, rnd) * (1.0 - smoothstep(0.6, 0.92, uzak)) * (1.0 - b.b);
	vec3 v = VERTEX * vec3(1.0, boy, 1.0);
	float s = sin(TIME*1.6 + p.x*0.35 + p.y*0.2) * 0.12 + sin(TIME*3.1 + p.y)*0.03;
	v.x += s * UV.y * UV.y * boy;
	v = (MODEL_MATRIX * vec4(v, 0.0)).xyz;  // dönüşüm (konum hariç)
	vec3 dunya = vec3(p.x, b.r - 0.04, p.y) + v;
	if (gizle > 0.5) dunya.y -= 100.0;
	VERTEX = (inverse(MODEL_MATRIX) * vec4(dunya, 1.0)).xyz;
	NORMAL = vec3(0,1,0);
}
void fragment(){
	if (gizle > 0.5) discard;
	float x = abs(UV.x - 0.5) * 2.0;
	if (x > (1.0 - UV.y) * 0.95 + 0.05) discard;
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ALBEDO = mix(alt_renk, ust_renk * mix(0.8, 1.15, rnd), pow(clamp(UV.y, 0.0, 1.0), 0.7));
	ROUGHNESS = 0.9;
}
"""

const YAPRAK_SHADER := """
shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap;
uniform sampler2D alb : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D nrm : hint_normal, filter_linear_mipmap;
uniform vec3 ton : source_color = vec3(1.0);
uniform float kar = 0.0;
uniform float kamera_kesme = 15.0;
void vertex(){
	vec3 o = (MODEL_MATRIX * vec4(0,0,0,1)).xyz;
	float s = sin(TIME * 1.3 + o.x * 0.2 + o.z * 0.3) * 0.06 * VERTEX.y / 6.0;
	VERTEX.x += s; VERTEX.z += s * 0.6;
}
void fragment(){
	vec4 c = texture(alb, UV);
	if (c.a < 0.45) discard;
	float esik = fract(sin(dot(FRAGCOORD.xy, vec2(12.9898, 78.233))) * 43758.5453);
	if (-VERTEX.z < kamera_kesme && esik < 0.85) discard;
	vec3 r = c.rgb * ton;
	r = mix(r, vec3(0.93, 0.95, 1.0), kar * smoothstep(0.2, 0.9, NORMAL.y + 0.3));
	ALBEDO = r;
	NORMAL_MAP = texture(nrm, UV).rgb;
	ROUGHNESS = 0.8;
	BACKLIGHT = vec3(0.35, 0.4, 0.15) * (1.0 - kar);
}
"""


static func _doku(yol: String) -> Texture2D:
	if not _cache.has(yol):
		_cache[yol] = load(yol)
	return _cache[yol]


## Bölgenin yükseklik ızgarasını üretir (bölge yüklenirken bir kez).
static func hazirla(tohum: int, yari: float, sehir_r: float, duzlukler: Array, yollar: Array, cimen_yogun: float) -> void:
	_yari = yari
	_sehir_r = sehir_r
	_duzlukler = duzlukler
	_yollar = yollar
	var g := _gurultuler(tohum)
	var n1: FastNoiseLite = g[0]
	var n2: FastNoiseLite = g[1]
	var img1 := n1.get_image(COZ, COZ, false, false, false)
	var img2 := n2.get_image(COZ, COZ, false, false, false)
	_h.resize(COZ * COZ)
	var bilgi := Image.create(COZ, COZ, false, Image.FORMAT_RGBAF)
	var adim := ALAN / (COZ - 1)
	for j in COZ:
		for i in COZ:
			var x := -ALAN * 0.5 + i * adim
			var z := -ALAN * 0.5 + j * adim
			var a := img1.get_pixel(i, j).r * 2.0 - 1.0
			var b := img2.get_pixel(i, j).r * 2.0 - 1.0
			var d := Vector2(x, z).length()
			var y := a * 5.5 + b * 1.2
			y *= smoothstep(sehir_r, sehir_r + 40.0, d)
			for dz in duzlukler:
				var c: Vector3 = dz[0]
				var dd := Vector2(x - c.x, z - c.z).length()
				y = lerpf(c.y, y, smoothstep(float(dz[1]), float(dz[1]) + 14.0, dd))
			var kenar := maxf(absf(x), absf(z))
			var dag := smoothstep(yari - 12.0, yari + 40.0, kenar)
			y += dag * dag * (48.0 + (b * 0.5 + a) * 26.0)
			_h[j * COZ + i] = y
			# yol yakınlığı
			var yol := 0.0
			var p := Vector2(x, z)
			for s in yollar:
				var sa: Vector2 = s[0]
				var sb: Vector2 = s[1]
				var ab := sb - sa
				var t := clampf((p - sa).dot(ab) / maxf(ab.length_squared(), 0.01), 0.0, 1.0)
				var m := (sa + ab * t).distance_to(p)
				yol = maxf(yol, 1.0 - smoothstep(1.4, 3.2, m))
			var cim := cimen_yogun * (1.0 - smoothstep(0.0, 1.0, yol * 1.5))
			cim *= smoothstep(sehir_r - 10.0, sehir_r - 4.0, d) * (1.0 - dag)
			bilgi.set_pixel(i, j, Color(y, cim, yol, 1.0))
	# eğimli yerlerde çimen olmasın
	for j in range(1, COZ - 1):
		for i in range(1, COZ - 1):
			var e := absf(_h[j * COZ + i + 1] - _h[j * COZ + i - 1]) + absf(_h[(j + 1) * COZ + i] - _h[(j - 1) * COZ + i])
			if e > 1.6:
				var c := bilgi.get_pixel(i, j)
				c.g *= clampf(1.0 - (e - 1.6), 0.0, 1.0)
				bilgi.set_pixel(i, j, c)
	hm_doku = ImageTexture.create_from_image(bilgi)


static func _gurultuler(tohum: int) -> Array:
	var n1 := FastNoiseLite.new()
	n1.seed = tohum
	n1.frequency = 0.0075
	n1.fractal_octaves = 4
	var n2 := FastNoiseLite.new()
	n2.seed = tohum + 11
	n2.frequency = 0.02
	n2.fractal_octaves = 5
	return [n1, n2]


## Düzleştirme öncesi yükseklik (zindan girişlerinin seviyesini bulmak için)
static func ham_y(tohum: int, x: float, z: float, sehir_r: float) -> float:
	var g := _gurultuler(tohum)
	var adim := ALAN / (COZ - 1)
	var i := (x + ALAN * 0.5) / adim
	var j := (z + ALAN * 0.5) / adim
	var y := (g[0] as FastNoiseLite).get_noise_2d(i, j) * 5.5 + (g[1] as FastNoiseLite).get_noise_2d(i, j) * 1.2
	return y * smoothstep(sehir_r, sehir_r + 40.0, Vector2(x, z).length())


## Dünyanın herhangi bir noktasında zemin yüksekliği (çift doğrusal).
static func y(x: float, z: float) -> float:
	if _h.is_empty():
		return 0.0
	var adim := ALAN / (COZ - 1)
	var fx := clampf((x + ALAN * 0.5) / adim, 0.0, COZ - 1.001)
	var fz := clampf((z + ALAN * 0.5) / adim, 0.0, COZ - 1.001)
	var i := int(fx)
	var j := int(fz)
	var tx := fx - i
	var tz := fz - j
	var a := _h[j * COZ + i]
	var b := _h[j * COZ + i + 1]
	var c := _h[(j + 1) * COZ + i]
	var d := _h[(j + 1) * COZ + i + 1]
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), tz)


static func egim(x: float, z: float) -> float:
	return Vector2(y(x + 1, z) - y(x - 1, z), y(x, z + 1) - y(x, z - 1)).length() * 0.5


static func temizle() -> void:
	_h = PackedFloat32Array()


## Zemin ağını parçalar halinde kurar (ekran dışı parçalar çizilmez).
static func zemin_kur(kok: Node3D, tema: int, mobil: bool) -> void:
	var sh := Shader.new()
	sh.code = ZEMIN_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	var t: Array = {
		0: ["res://assets/ph/aerial_grass_rock_Diffuse.jpg", "res://assets/ph/aerial_grass_rock_nor_gl.jpg", "rock023_alb_ht.png", "rock023_nrm_rgh.png", Color(1, 1, 1), Color(1, 1, 1)],
		1: ["res://assets/ph/snow_02_Diffuse.jpg", "res://assets/ph/snow_02_nor_gl.jpg", "rock023_alb_ht.png", "rock023_nrm_rgh.png", Color(1, 1, 1), Color(0.78, 0.84, 0.95)],
		2: ["res://assets/ph/aerial_sand_Diffuse.jpg", "res://assets/ph/aerial_sand_nor_gl.jpg", "rock023_alb_ht.png", "rock023_nrm_rgh.png", Color(1, 1, 1), Color(0.75, 0.5, 0.38)],
	}[tema]
	m.set_shader_parameter("a_alb", _doku(t[0]))
	m.set_shader_parameter("a_nrm", _doku(t[1]))
	m.set_shader_parameter("k_alb", _doku("res://assets/arazi/" + t[2]))
	m.set_shader_parameter("k_nrm", _doku("res://assets/arazi/" + t[3]))
	m.set_shader_parameter("a_ton", t[4])
	m.set_shader_parameter("k_ton", t[5])
	m.set_shader_parameter("t_alb", _doku("res://assets/ph/cobblestone_floor_08_Diffuse.jpg"))
	m.set_shader_parameter("y_alb", _doku("res://assets/ph/gravel_road_Diffuse.jpg"))
	m.set_shader_parameter("hm", hm_doku)
	m.set_shader_parameter("tema", tema)
	m.set_shader_parameter("sehir_r", _sehir_r)
	m.set_shader_parameter("alan", ALAN)
	var parca := 8
	var hucre := (COZ - 1) / parca     # 30 hücre
	var atla := 2 if mobil else 1      # telefonda 4 m çözünürlük
	var adim := ALAN / (COZ - 1)
	for pj in parca:
		for pi in parca:
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var n := hucre / atla + 1
			for j in n:
				for i in n:
					var gi := pi * hucre + i * atla
					var gj := pj * hucre + j * atla
					var x := -ALAN * 0.5 + gi * adim
					var z := -ALAN * 0.5 + gj * adim
					st.set_uv(Vector2(gi, gj) / (COZ - 1))
					st.add_vertex(Vector3(x, _h[gj * COZ + gi], z))
			for j in n - 1:
				for i in n - 1:
					var a := j * n + i
					var b := a + n
					st.add_index(a); st.add_index(a + 1); st.add_index(b)
					st.add_index(b); st.add_index(a + 1); st.add_index(b + 1)
			st.generate_normals()
			st.generate_tangents()
			var mi := MeshInstance3D.new()
			mi.mesh = st.commit()
			mi.material_override = m
			kok.add_child(mi)


## Oyuncuyu izleyen çimen (tek MultiMesh; yer ve yükseklik ekran kartında hesaplanır).
static func cimen_kur(kok: Node3D, mobil: bool, alt: Color, ust: Color) -> ShaderMaterial:
	var q := QuadMesh.new()
	q.size = Vector2(0.1, 0.42)
	q.center_offset = Vector3(0, 0.21, 0)
	var sh := Shader.new()
	sh.code = CIMEN_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	var karo := 40.0 if mobil else 56.0
	m.set_shader_parameter("hm", hm_doku)
	m.set_shader_parameter("karo", karo)
	m.set_shader_parameter("alan", ALAN)
	m.set_shader_parameter("alt_renk", alt)
	m.set_shader_parameter("ust_renk", ust)
	q.material = m
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = q
	var adet := 26000 if mobil else 70000
	mm.instance_count = adet
	var r := RandomNumberGenerator.new()
	r.seed = 5
	for i in adet:
		var p := Vector3(r.randf() * karo, 0, r.randf() * karo)
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3.ONE * r.randf_range(0.7, 1.3)), p))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.custom_aabb = AABB(Vector3(-ALAN, -50, -ALAN), Vector3(ALAN * 2, 200, ALAN * 2))
	mi.name = "Cimen"
	kok.add_child(mi)
	return m


## Gerçek kabuk ve yaprak dokulu ağaç ağı (gövde + dallar + yaprak kartları).
static func agac_mesh(tohum: int, yaprakli: bool, ton: Color, kar: float) -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = tohum
	var kabuk := StandardMaterial3D.new()
	kabuk.albedo_texture = _doku("res://assets/arazi/kabuk.jpg")
	kabuk.normal_enabled = true
	kabuk.normal_texture = _doku("res://assets/arazi/kabuk_nrm.png")
	kabuk.roughness = 0.9
	kabuk.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
	kabuk.distance_fade_min_distance = 13.0
	kabuk.distance_fade_max_distance = 16.0
	kabuk.albedo_color = Color(0.85, 0.82, 0.8) if yaprakli else Color(0.45, 0.42, 0.4)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var boy := r.randf_range(6.5, 9.0)
	var dallar: Array = []   # [baş, son, yarıçap]
	dallar.append([Vector3.ZERO, Vector3(r.randf_range(-0.4, 0.4), boy, r.randf_range(-0.4, 0.4)), 0.32])
	var uclar: Array = []
	for i in 7:
		var h := boy * r.randf_range(0.4, 0.85)
		var a := r.randf() * TAU
		var bas: Vector3 = dallar[0][1] * (h / boy)
		var uz := r.randf_range(2.0, 3.6)
		var son := bas + Vector3(cos(a) * uz, r.randf_range(0.9, 2.2), sin(a) * uz)
		dallar.append([bas, son, 0.11])
		uclar.append(son)
		for k in 2:
			var a2 := a + r.randf_range(-0.9, 0.9)
			var bas2 := bas.lerp(son, r.randf_range(0.5, 0.8))
			var son2 := bas2 + Vector3(cos(a2), r.randf_range(0.3, 1.0), sin(a2)) * r.randf_range(1.0, 1.8)
			dallar.append([bas2, son2, 0.05])
			uclar.append(son2)
	uclar.append(dallar[0][1])
	for d in dallar:
		_silindir(st, d[0], d[1], d[2], d[2] * 0.45, 7 if d[2] > 0.2 else 5)
	st.generate_normals()
	st.generate_tangents()
	var govde := st.commit()
	govde.surface_set_material(0, kabuk)
	if not yaprakli:
		return [govde, null]
	var sh := Shader.new()
	sh.code = YAPRAK_SHADER
	var ym := ShaderMaterial.new()
	ym.shader = sh
	ym.set_shader_parameter("alb", _doku("res://assets/arazi/yaprak.png"))
	ym.set_shader_parameter("nrm", _doku("res://assets/arazi/yaprak_nrm.png"))
	ym.set_shader_parameter("ton", ton)
	ym.set_shader_parameter("kar", kar)
	var sy := SurfaceTool.new()
	sy.begin(Mesh.PRIMITIVE_TRIANGLES)
	for u in uclar:
		for k in 3:
			var merkez: Vector3 = u + Vector3(r.randf_range(-0.8, 0.8), r.randf_range(-0.6, 0.6), r.randf_range(-0.8, 0.8))
			var boyut := r.randf_range(2.2, 3.2)
			var aci := r.randf() * TAU
			var egik := r.randf_range(-0.5, 0.5)
			var b := Basis(Vector3.UP, aci) * Basis(Vector3.RIGHT, egik)
			_kart(sy, merkez, b, boyut, k == 2)
	sy.generate_normals()
	sy.generate_tangents()
	var yap := sy.commit()
	yap.surface_set_material(0, ym)
	return [govde, yap]


static func _kart(st: SurfaceTool, m: Vector3, b: Basis, s: float, ust: bool) -> void:
	# Atlasın üst yarısı yandan dal, alt yarısı üstten dal görünümü
	var v0 := 0.5 if ust else 0.0
	var sag := b.x * s * 0.5
	var yuk := (b.z if ust else b.y) * s * 0.5
	var n := (b.y if ust else b.z)
	var k := [m - sag - yuk, m + sag - yuk, m + sag + yuk, m - sag + yuk]
	var uv := [Vector2(0.05, v0 + 0.5), Vector2(0.95, v0 + 0.5), Vector2(0.95, v0), Vector2(0.05, v0)]
	for i in [0, 1, 2, 0, 2, 3]:
		st.set_normal(n)
		st.set_uv(uv[i])
		st.add_vertex(k[i])


static func _silindir(st: SurfaceTool, a: Vector3, b: Vector3, r0: float, r1: float, n: int) -> void:
	var ek := (b - a).normalized()
	var yan := ek.cross(Vector3.FORWARD if absf(ek.y) > 0.9 else Vector3.UP).normalized()
	var yan2 := ek.cross(yan)
	var uz := a.distance_to(b)
	for i in n:
		var t0 := TAU * i / n
		var t1 := TAU * (i + 1) / n
		var d0 := yan * cos(t0) + yan2 * sin(t0)
		var d1 := yan * cos(t1) + yan2 * sin(t1)
		var p := [a + d0 * r0, a + d1 * r0, b + d1 * r1, b + d0 * r1]
		var u0 := float(i) / n
		var u1 := float(i + 1) / n
		var uv := [Vector2(u0, uz * 0.25), Vector2(u1, uz * 0.25), Vector2(u1, 0), Vector2(u0, 0)]
		for k in [0, 2, 1, 0, 3, 2]:
			st.set_uv(uv[k])
			st.add_vertex(p[k])


static func coklu(kok: Node3D, mesh: Mesh, donusumler: Array, golge: bool, gorus := 0.0) -> void:
	if donusumler.is_empty() or mesh == null:
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = donusumler.size()
	for i in donusumler.size():
		mm.set_instance_transform(i, donusumler[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if golge else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if gorus > 0:
		mi.visibility_range_end = gorus
	kok.add_child(mi)


static func kaya_mat(ton: Color) -> StandardMaterial3D:
	var k := StandardMaterial3D.new()
	k.albedo_texture = _doku("res://assets/arazi/rock023_alb_ht.png")
	k.normal_enabled = true
	k.normal_texture = _doku("res://assets/arazi/rock023_nrm_rgh.png")
	k.uv1_triplanar = true
	k.uv1_world_triplanar = true
	k.uv1_scale = Vector3.ONE * 0.12
	k.roughness = 0.85
	k.albedo_color = ton
	return k


static func duvar_mat(doku: String, nrm: String, olcek: float, ton := Color.WHITE) -> StandardMaterial3D:
	var k := StandardMaterial3D.new()
	k.albedo_texture = _doku(doku if doku.begins_with("res://") else "res://assets/arazi/" + doku)
	if nrm != "":
		k.normal_enabled = true
		k.normal_texture = _doku(nrm if nrm.begins_with("res://") else "res://assets/arazi/" + nrm)
	k.uv1_triplanar = true
	k.uv1_world_triplanar = true
	k.uv1_scale = Vector3.ONE * olcek
	k.roughness = 0.88
	k.albedo_color = ton
	return k


## Poly Haven taranmış modeller (CC0): glb içindeki ilk ağ, malzemeleriyle
static func ph_mesh(ad: String, kamera_soldur := false) -> Mesh:
	var anahtar := "ph_" + ad + str(kamera_soldur)
	if _cache.has(anahtar):
		return _cache[anahtar]
	var n: Node3D = load("res://assets/ph/%s.glb" % ad).instantiate()
	var bulunan: Mesh = null
	for c in n.find_children("*", "MeshInstance3D", true, false):
		bulunan = (c as MeshInstance3D).mesh.duplicate()
		break
	n.free()
	if bulunan and kamera_soldur:
		for i in bulunan.get_surface_count():
			var m := bulunan.surface_get_material(i)
			if m is StandardMaterial3D:
				var y: StandardMaterial3D = m.duplicate()
				y.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
				y.distance_fade_min_distance = 13.0
				y.distance_fade_max_distance = 16.0
				bulunan.surface_set_material(i, y)
	_cache[anahtar] = bulunan
	return bulunan
