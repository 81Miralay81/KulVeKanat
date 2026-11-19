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
	for n in m.find_children("*", "MeshInstance3D", true, false):
		var ust := n.get_parent()
		if ust is BoneAttachment3D and str(ust.name).begins_with("handslot") and not n.name in veri["sakla"]:
			n.visible = false
	var ap: AnimationPlayer = m.find_child("AnimationPlayer", true, false)
	if ap and ap.has_animation(veri["anim"]):
		ap.get_animation(veri["anim"]).loop_mode = Animation.LOOP_LINEAR
		ap.play(veri["anim"])
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
