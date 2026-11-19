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
	l.light_color = Color(0.7, 0.3, 1.0)
	l.light_energy = 2.0
	l.omni_range = 3.5
	add_child(l)


func _physics_process(dt: float) -> void:
	_omur -= dt
	global_position += yon * hiz * dt
	if Engine.get_physics_frames() % 3 == 0:
		Efekt.parcacik(global_position, 3, Color(0.7, 0.3, 1.0), 0.35, 0.5, 0.0, 0.35, 180.0)
	if kahraman and is_instance_valid(kahraman):
		var k := kahraman.global_position + Vector3(0, 1.0, 0)
		if k.distance_to(global_position) < 0.9:
			kahraman.hasar_al(hasar)
			Efekt.parcacik(global_position, 14, Color(0.7, 0.3, 1.0), 0.4, 4.0, 0.0, 0.3)
			queue_free()
			return
	if _omur <= 0 or absf(global_position.x) > 21 or absf(global_position.z) > 21:
		queue_free()
