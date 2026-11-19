class_name OyuncuMermi
extends Node3D
## Oyuncunun attığı mermiler: arbalet oku, hançer, ateş topu.

var kahraman: Node
var yon := Vector3.FORWARD
var hiz := 24.0
var carpan := 1.0
var delme := 0             ## kaç düşmanı delip geçer
var menzil := 16.0
var tur := "ok"            ## ok, hancer, ates
var patlama_r := 0.0
var itme := 2.0
var renk := Color(0.8, 0.6, 1.0)
var _yol := 0.0
var _vurulan := {}


func _ready() -> void:
	var m := MeshInstance3D.new()
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if tur == "ates":
		var s := SphereMesh.new()
		s.radius = 0.3
		s.height = 0.6
		m.mesh = s
		m.material_override = Efekt.parlak_mat(Color(1.0, 0.6, 0.2), 4.0)
		var l := OmniLight3D.new()
		l.light_color = Efekt.ATES
		l.light_energy = 2.0
		l.omni_range = 4.0
		add_child(l)
		var iz := GPUParticles3D.new()
		iz.amount = 16
		iz.lifetime = 0.35
		iz.local_coords = false
		var pm := ParticleProcessMaterial.new()
		pm.spread = 180.0
		pm.initial_velocity_min = 0.3
		pm.initial_velocity_max = 1.0
		pm.gravity = Vector3(0, 1.5, 0)
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var gt := GradientTexture1D.new()
		gt.gradient = g
		pm.color_ramp = gt
		iz.process_material = pm
		var q := QuadMesh.new()
		q.size = Vector2(0.5, 0.5)
		q.material = Efekt.parca_mat(Efekt.ATES, 3.0)
		iz.draw_pass_1 = q
		add_child(iz)
	else:
		var b := BoxMesh.new()
		b.size = Vector3(0.07, 0.07, 1.1 if tur == "ok" else 0.6)
		m.mesh = b
		m.material_override = Efekt.parlak_mat(renk, 3.0)
	add_child(m)
	look_at(global_position + yon, Vector3.UP)


func _physics_process(dt: float) -> void:
	var adim := hiz * dt
	global_position += yon * adim
	_yol += adim
	var liste: Array = kahraman.ana.dusmanlar if kahraman and kahraman.ana else []
	for d in liste:
		if not is_instance_valid(d) or d.olu or _vurulan.has(d):
			continue
		var f: Vector3 = d.global_position - global_position
		f.y = 0
		if f.length() < 0.7 + d.yaricap:
			_vurulan[d] = true
			kahraman._vur(d, carpan, itme)
			if patlama_r > 0:
				_patla()
				return
			if delme <= 0:
				Efekt.vurus_kivilcim(global_position, false)
				queue_free()
				return
			delme -= 1
	if _yol > menzil or absf(global_position.x) > 20.5 or absf(global_position.z) > 20.5:
		if patlama_r > 0:
			_patla()
		else:
			queue_free()


func _patla() -> void:
	var p := global_position
	p.y = 0
	Efekt.patlama(p, patlama_r)
	kahraman._alan_hasari(p, patlama_r, carpan * 0.6, 3.0, false)
	Ses.cal("patlama", -10.0)
	queue_free()
