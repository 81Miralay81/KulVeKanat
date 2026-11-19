class_name Portre
extends RefCounted
## Menülerde dönen 3B karakter portresi (kendi küçük dünyasında çizilir).


static func yap(model: String, anim: String, boyut: Vector2i, sakla: Array = [], isik_renk := Color(1.0, 0.75, 0.5), olcek := 1.0) -> SubViewportContainer:
	var kap := SubViewportContainer.new()
	kap.stretch = true
	kap.custom_minimum_size = Vector2(boyut)
	kap.process_mode = Node.PROCESS_MODE_ALWAYS
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.size = boyut
	vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	vp.msaa_3d = Viewport.MSAA_2X
	kap.add_child(vp)
	var kok := Node3D.new()
	kok.process_mode = Node.PROCESS_MODE_ALWAYS
	vp.add_child(kok)
	var m: Node3D = load("res://assets/karakter/%s.glb" % model).instantiate()
	m.scale = Vector3.ONE * olcek
	kok.add_child(m)
	if sakla.size() > 0:
		for n in m.find_children("*", "MeshInstance3D", true, false):
			var ust := n.get_parent()
			if ust is BoneAttachment3D and ust.name.begins_with("handslot") and not n.name in sakla:
				n.visible = false
	if "__yay__" in sakla:
		var el := m.find_child("handslot_r", true, false)
		if el:
			el.add_child(Esya.yay_modeli())
	var ap: AnimationPlayer = m.find_child("AnimationPlayer", true, false)
	if ap and ap.has_animation(anim):
		ap.get_animation(anim).loop_mode = Animation.LOOP_LINEAR
		ap.play(anim)
	var kam := Camera3D.new()
	kam.position = Vector3(0, 1.35 * olcek, 3.6 * olcek)
	kam.fov = 34
	kok.add_child(kam)
	kam.look_at(Vector3(0, 1.0 * olcek, 0))
	var l := DirectionalLight3D.new()
	l.rotation_degrees = Vector3(-35, 30, 0)
	l.light_energy = 1.3
	kok.add_child(l)
	var arka := OmniLight3D.new()
	arka.position = Vector3(-1.2, 2.0, -1.5)
	arka.light_color = isik_renk
	arka.light_energy = 3.0
	arka.omni_range = 5.0
	kok.add_child(arka)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.45, 0.5)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	we.environment = env
	kok.add_child(we)
	kok.tree_entered.connect(func():
		var tw := kok.create_tween().set_loops()
		tw.tween_property(m, "rotation:y", 0.5, 2.5).from(-0.5).set_trans(Tween.TRANS_SINE)
		tw.tween_property(m, "rotation:y", -0.5, 2.5).set_trans(Tween.TRANS_SINE), CONNECT_ONE_SHOT)
	return kap
