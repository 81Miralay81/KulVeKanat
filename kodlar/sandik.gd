class_name Sandik
extends Node3D
## Köşelerdeki altın sandıklar: yanına gelince açılır, ganimet saçar. Her 5 dalgada yeniden dolar.

var ana: Node
var acik := false
var _kapak: Node3D
var _isik: OmniLight3D
var _parilti: GPUParticles3D


func _ready() -> void:
	add_to_group("sandik")
	var m: Node3D = load("res://assets/zindan/chest_gold.glb").instantiate()
	add_child(m)
	m.scale = Vector3.ONE * 1.25
	_kapak = m.find_child("chest_gold_lid", true, false)
	_isik = OmniLight3D.new()
	_isik.visible = Efekt.isik_var()
	_isik.light_color = Color(1.0, 0.8, 0.3)
	_isik.light_energy = 1.4
	_isik.omni_range = 3.5
	_isik.position.y = 1.2
	add_child(_isik)
	var halka := MeshInstance3D.new()
	halka.mesh = Efekt.halka_mesh(0.9, 1.2)
	halka.material_override = Efekt.parlak_mat(Color(1.0, 0.8, 0.3), 1.4)
	halka.position.y = 0.05
	halka.name = "Halka"
	add_child(halka)


func _process(_dt: float) -> void:
	if acik or ana == null or ana.kahraman == null or ana.durum != "oyun":
		return
	if ana.kahraman.global_position.distance_to(global_position) < 2.0 and ana.kahraman.durum != "olu":
		ac()


func ac() -> void:
	acik = true
	Ses.cal("esya", -4.0)
	if _kapak:
		var tw := create_tween()
		tw.tween_property(_kapak, "rotation:x", deg_to_rad(-105), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_isik.light_energy = 0.0
	get_node("Halka").visible = false
	Efekt.parcacik(global_position + Vector3(0, 1.0, 0), 40, Efekt.ALTIN, 1.2, 6.0, -6.0, 0.25, 50.0)
	Efekt.isik_flas(global_position + Vector3(0, 1.5, 0), Efekt.ALTIN, 6.0, 6.0, 0.6)
	var k: Node = ana.kahraman
	ana.altin_ver(randi_range(4, 7) * (8 + ana.dalga * 3), global_position)
	if randf() < 0.45:
		ana.ganimet_birak("iksir", global_position + _rastgele())
	if randf() < 0.75:
		ana.ganimet_birak("esya", global_position + _rastgele(), 0, 1 if randf() < 0.5 else 0)
	ana.mesaj_goster("Sandık açıldı!", Efekt.ALTIN)


func doldur() -> void:
	if not acik:
		return
	acik = false
	if _kapak:
		_kapak.rotation.x = 0.0
	_isik.light_energy = 1.4
	get_node("Halka").visible = true


func _rastgele() -> Vector3:
	var a := randf() * TAU
	var r := randf_range(1.0, 2.2)
	var v := Vector3(cos(a) * r, 0, sin(a) * r)
	# sandıklar duvar dibinde: ganimet arenanın içine doğru saçılsın
	return Vector3(v.x if global_position.x < 0 and v.x > 0 or global_position.x > 0 and v.x < 0 else -v.x * 0.6,
		0, v.z if global_position.z < 0 and v.z > 0 or global_position.z > 0 and v.z < 0 else -v.z * 0.6)
