class_name Ganimet
extends Node3D
## Yerdeki ganimet: altın, iksir ya da eşya. Üstünden geçince toplanır.

var tur := "altin"          ## altin, iksir, esya
var miktar := 0
var esya := {}
var kahraman: Node3D
var _zaman := 0.0
var _govde: Node3D
var _toplandi := false


func _ready() -> void:
	add_to_group("ganimet")
	var renk := Efekt.ALTIN
	if tur == "esya":
		renk = Esya.renk(esya)
	elif tur == "iksir":
		renk = Color(1, 0.25, 0.25)
	_govde = Node3D.new()
	add_child(_govde)
	if tur == "altin":
		var m: Node3D = load("res://assets/zindan/coin_stack_small.glb").instantiate()
		_govde.add_child(m)
		_govde.scale = Vector3.ONE * 0.9
	else:
		var m := MeshInstance3D.new()
		var p: PrimitiveMesh = PrismMesh.new() if tur == "esya" else SphereMesh.new()
		if p is PrismMesh:
			p.size = Vector3(0.45, 0.6, 0.45)
		else:
			p.radius = 0.22
			p.height = 0.44
		m.mesh = p
		m.material_override = Efekt.parlak_mat(renk, 2.5)
		_govde.add_child(m)
		_govde.position.y = 0.6
		if tur == "esya":
			var alt := MeshInstance3D.new()
			var p2 := PrismMesh.new()
			p2.size = Vector3(0.45, 0.6, 0.45)
			alt.mesh = p2
			alt.rotation.z = PI
			alt.position.y = -0.6
			alt.material_override = m.material_override
			m.add_child(alt)
	var isik := OmniLight3D.new()
	isik.light_color = renk
	isik.light_energy = 1.5
	isik.omni_range = 3.0
	isik.position.y = 0.8
	add_child(isik)
	if tur == "esya":
		var yuk: float = 2.5 + esya["nadirlik"] * 2.0
		Efekt.isik_sutunu(global_position, renk, yuk, 0.25 + esya["nadirlik"] * 0.08, -1, 1.6 + esya["nadirlik"] * 0.4).reparent(self)
		var l := Label3D.new()
		l.text = esya["ad"]
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.font_size = 52
		l.pixel_size = 0.006
		l.outline_size = 12
		l.modulate = renk
		l.position.y = 1.6
		var f = load("res://assets/font/Rajdhani-Bold.ttf")
		if f:
			l.font = f
		add_child(l)
		if esya["nadirlik"] >= 3:
			Ses.cal("esya")
	# fırlayarak düşme
	var hedef_y := position.y
	position.y += 1.2
	var tw := create_tween()
	tw.tween_property(self, "position:y", hedef_y, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _process(dt: float) -> void:
	_zaman += dt
	_govde.rotation.y += dt * 2.0
	if tur != "altin":
		_govde.position.y = 0.6 + sin(_zaman * 3.0) * 0.1
	if _toplandi or kahraman == null or not is_instance_valid(kahraman):
		return
	var m := global_position.distance_to(kahraman.global_position)
	var cekim := 1.6 if tur == "esya" else 3.0
	if m < cekim and _zaman > 0.4 and kahraman.durum != "olu":
		global_position = global_position.move_toward(kahraman.global_position, dt * 12.0)
		if m < 0.7:
			_topla()
	if _zaman > 60.0:
		queue_free()


func _topla() -> void:
	_toplandi = true
	match tur:
		"altin":
			kahraman.altin += miktar
			Ses.cal("altin", -6.0)
		"iksir":
			kahraman.iksir = mini(kahraman.iksir + 1, 5)
			Ses.cal("altin", -4.0, 0.0)
		"esya":
			kahraman.esya_al(esya)
	queue_free()
