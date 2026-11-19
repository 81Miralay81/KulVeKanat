class_name Npc
extends Node3D
## Köydeki esnaf: başının üstünde adı, ayağının altında parlayan halka. Yanına gelince "KONUŞ".

var veri: Dictionary
var _etiket: Label3D


func _ready() -> void:
	add_to_group("npc")
	var m: Node3D = load("res://assets/karakter/%s.glb" % veri["model"]).instantiate()
	add_child(m)
	m.scale = Vector3.ONE * 1.1
	var ton: Color = veri.get("ton", Color(1, 1, 1))
	if ton != Color(1, 1, 1):
		for mi in m.find_children("*", "MeshInstance3D", true, false):
			for i in (mi as MeshInstance3D).mesh.get_surface_count():
				var a := (mi as MeshInstance3D).get_active_material(i)
				if a is StandardMaterial3D:
					var y: StandardMaterial3D = a.duplicate()
					y.albedo_color = a.albedo_color * ton
					(mi as MeshInstance3D).set_surface_override_material(i, y)
	for n in m.find_children("*", "MeshInstance3D", true, false):
		var ust := n.get_parent()
		if ust is BoneAttachment3D and str(ust.name).begins_with("handslot") and not n.name in veri.get("sakla", []):
			n.visible = false
	var ap: AnimationPlayer = m.find_child("AnimationPlayer", true, false)
	var anim: String = veri.get("anim", "Idle")
	if ap and not ap.has_animation(anim):
		anim = "Idle"
	if ap and ap.has_animation(anim):
		ap.get_animation(anim).loop_mode = Animation.LOOP_LINEAR
		ap.play(anim)
		ap.seek(randf() * 2.0)
	m.rotation.y = atan2(-position.x, -position.z)   # meydana baksın
	var halka := MeshInstance3D.new()
	halka.mesh = Efekt.halka_mesh(0.9, 1.25)
	halka.material_override = Efekt.parlak_mat(veri["renk"], 1.6)
	halka.position.y = 0.05
	add_child(halka)
	_etiket = Label3D.new()
	_etiket.text = veri["ad"]
	_etiket.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_etiket.no_depth_test = true
	_etiket.font_size = 60
	_etiket.pixel_size = 0.007
	_etiket.outline_size = 14
	_etiket.modulate = veri["renk"].lightened(0.25)
	_etiket.position.y = 2.9
	var f = load("res://assets/font/Rajdhani-Bold.ttf")
	if f:
		_etiket.font = f
	add_child(_etiket)
	var isaret := Label3D.new()   # başının üstünde altın ünlem: konuşulabilir
	isaret.text = "!"
	isaret.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	isaret.no_depth_test = true
	isaret.font_size = 120
	isaret.pixel_size = 0.008
	isaret.outline_size = 18
	isaret.modulate = Color(1.0, 0.82, 0.3)
	isaret.position.y = 3.5
	add_child(isaret)
	var tw := isaret.create_tween().set_loops()
	tw.tween_property(isaret, "position:y", 3.75, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(isaret, "position:y", 3.5, 0.6).set_trans(Tween.TRANS_SINE)
