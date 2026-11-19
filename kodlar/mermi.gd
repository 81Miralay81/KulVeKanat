class_name Mermi
extends Node3D
## Kül Büyücüsü'nün mor büyü topu.

var yon := Vector3.FORWARD
var hiz := 9.0
var hasar := 10.0
var kahraman: Node3D
var _omur := 3.0


func _ready() -> void:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.28
	s.height = 0.56
	m.mesh = s
	m.material_override = Efekt.parlak_mat(Color(0.75, 0.3, 1.0), 3.0)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	var l := OmniLight3D.new()
	l.visible = Efekt.isik_var()
	l.light_color = Color(0.7, 0.3, 1.0)
	l.light_energy = 2.0
	l.omni_range = 3.5
	add_child(l)
	# tek parçacık izi (her karede yeni efekt yaratmak yerine)
	var iz := GPUParticles3D.new()
	iz.amount = 12
	iz.lifetime = 0.35
	iz.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.spread = 180.0
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.6
	pm.gravity = Vector3.ZERO
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	iz.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.35, 0.35)
	q.material = Efekt.parca_mat(Color(0.7, 0.3, 1.0), 3.0)
	iz.draw_pass_1 = q
	add_child(iz)


func _physics_process(dt: float) -> void:
	_omur -= dt
	global_position += yon * hiz * dt
	if kahraman and is_instance_valid(kahraman):
		var k := kahraman.global_position + Vector3(0, 1.0, 0)
		if k.distance_to(global_position) < 0.9:
			kahraman.hasar_al(hasar)
			Efekt.parcacik(global_position, 14, Color(0.7, 0.3, 1.0), 0.4, 4.0, 0.0, 0.3)
			queue_free()
			return
	if _omur <= 0 or absf(global_position.x) > 21 or absf(global_position.z) > 21:
		queue_free()
