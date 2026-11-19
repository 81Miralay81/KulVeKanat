class_name Kanat
extends Node3D
## Kahramanın sırtındaki ışık kanatları. parlaklik 0..1 arası; atılım ve son vuruşta tam açılır.

var _sol: Node3D
var _sag: Node3D
var _mat_ic: ShaderMaterial
var _mat_dis: ShaderMaterial
var _mat_koyu: ShaderMaterial
var parlaklik := 0.35
var _hedef := 0.35
var _zaman := 0.0


func _ready() -> void:
	_mat_ic = Efekt.yeni_parlak_mat(Color(1.0, 0.32, 0.04), 2.2)
	_mat_dis = Efekt.yeni_parlak_mat(Color(1.0, 0.55, 0.12), 2.4)
	_mat_koyu = Efekt.yeni_parlak_mat(Color(0.9, 0.18, 0.02), 1.6)
	_sol = _kanat_yap(-1)
	_sag = _kanat_yap(1)
	add_child(_sol)
	add_child(_sag)
	_uygula()


func _tuy(st: SurfaceTool, bas: Vector3, yon: Vector3, boy: float, en: float) -> void:
	var ileri := Vector3(0, 0, 1)
	var genis := yon.cross(ileri).normalized()
	var n := 10
	var onceki: Array = []
	for k in n + 1:
		var u := float(k) / n
		var c := bas + yon * boy * u + Vector3(0, -0.18 * u * u, 0)
		var w := en * pow(sin(PI * min(1.0, 0.08 + u * 0.97)), 0.75) * (1.0 - 0.25 * u)
		var a := c - genis * w * 0.35
		var b := c + genis * w * 0.65
		var alfa := clampf(1.2 - u * 0.6, 0.0, 1.0)
		if onceki.size() > 0:
			var c0 := Color(1, 1, 1, onceki[2])
			var c1 := Color(1, 1, 1, alfa)
			st.set_color(c0); st.add_vertex(onceki[0])
			st.set_color(c0); st.add_vertex(onceki[1])
			st.set_color(c1); st.add_vertex(b)
			st.set_color(c0); st.add_vertex(onceki[0])
			st.set_color(c1); st.add_vertex(b)
			st.set_color(c1); st.add_vertex(a)
		onceki = [a, b, alfa]


func _kanat_yap(isaret: int) -> Node3D:
	var kok := Node3D.new()
	var mesh_list := []
	for katman in 3:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		if katman < 2:
			for i in range(katman, 10, 2):
				var t := i / 9.0
				var aci := deg_to_rad(28.0 + t * 92.0)
				var boy := 1.9 - t * 1.1
				var yon := (Vector3(isaret * sin(aci), cos(aci), -0.25)).normalized()
				_tuy(st, Vector3(isaret * (0.08 + 0.04 * t), 0, 0), yon, boy, 0.30)
		else:
			for i in 8:
				var t := i / 7.0
				var aci := deg_to_rad(32.0 + t * 80.0)
				var yon := (Vector3(isaret * sin(aci), cos(aci), -0.3)).normalized()
				_tuy(st, Vector3(isaret * 0.06, 0, 0.02), yon, 0.8 - t * 0.25, 0.26)
		var m := MeshInstance3D.new()
		m.mesh = st.commit()
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.material_override = [_mat_ic, _mat_dis, _mat_koyu][katman]
		kok.add_child(m)
	return kok


func ac(deger: float) -> void:
	_hedef = deger


func _process(dt: float) -> void:
	_zaman += dt
	parlaklik = lerpf(parlaklik, _hedef, minf(1.0, dt * 6.0))
	_uygula()
	var cirpma := sin(_zaman * (2.0 + parlaklik * 4.0)) * (0.08 + parlaklik * 0.12)
	_sol.rotation = Vector3(0, -cirpma, cirpma * 0.6)
	_sag.rotation = Vector3(0, cirpma, -cirpma * 0.6)


func _uygula() -> void:
	var s := 0.55 + parlaklik * 0.55
	scale = Vector3.ONE * s
	_mat_ic.set_shader_parameter("saydam", 0.25 + parlaklik * 0.75)
	_mat_dis.set_shader_parameter("saydam", 0.25 + parlaklik * 0.75)
	_mat_koyu.set_shader_parameter("saydam", 0.2 + parlaklik * 0.6)
	_mat_ic.set_shader_parameter("guc", 1.4 + parlaklik * 2.0)
	_mat_dis.set_shader_parameter("guc", 1.6 + parlaklik * 2.2)
