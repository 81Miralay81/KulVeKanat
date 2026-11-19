extends Node3D
## Bölge önizlemesi (ekran görüntüsü için): --bolge=0/1/2 --kamera=sehir/alan/zindan/genis --mobil

var cam: Camera3D

func _ready() -> void:
	var b := 0
	var mod := "alan"
	var mobil := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--bolge="):
			b = int(a.substr(8))
		elif a.begins_with("--kamera="):
			mod = a.substr(9)
		elif a == "--mobil":
			mobil = true
		elif a.begins_with("--kapat="):
			Bolge.test_kapat = a.substr(8).split(",")
	Efekt.kur(self, mobil)
	var t0 := Time.get_ticks_msec()
	var kok := Node3D.new()
	add_child(kok)
	Bolge.insa(kok, mobil, b)
	print("bolge insa ms: ", Time.get_ticks_msec() - t0)
	var v: Dictionary = Bolge.veri
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = v["gok"][0]
	sm.sky_horizon_color = v["gok"][1]
	sm.ground_horizon_color = v["gok"][1]
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.fog_enabled = true
	env.fog_light_color = v["sis"]
	env.fog_density = 0.004
	env.fog_aerial_perspective = 0.5
	env.ssao_enabled = not mobil
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var gunes := DirectionalLight3D.new()
	gunes.rotation_degrees = Vector3(-40, -35, 0)
	gunes.light_energy = 1.3
	gunes.light_color = v["gunes"]
	gunes.shadow_enabled = true
	gunes.directional_shadow_max_distance = 80
	add_child(gunes)
	var k: Node3D = load("res://assets/karakter/Gladyator.glb").instantiate()
	k.scale = Vector3.ONE * 1.12
	add_child(k)
	cam = Camera3D.new()
	cam.fov = 42
	cam.far = 600
	add_child(cam)
	var hedef := Vector3(0, 0, 9)
	if mod == "alan":
		hedef = Bolge.suru_noktalari[3]["konum"]
	elif mod == "zindan":
		hedef = Bolge.giris_noktasi(Bolge.zindanlar[0])
	hedef.y = Arazi.y(hedef.x, hedef.z)
	k.position = hedef
	var cimen := kok.find_child("Cimen", true, false) as MultiMeshInstance3D
	if cimen:
		(cimen.multimesh.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("merkez", hedef)
	if mod == "genis":
		cam.position = Vector3(-70, 55, 95)
		cam.look_at(Vector3(0, 0, 0))
	else:
		cam.position = hedef + Vector3(11.5, 18, 11.5)
		cam.look_at(hedef + Vector3(0, 1, 0))
	await get_tree().create_timer(3.0).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/bolge_%d_%s.png" % [b, mod])
	get_tree().quit()
