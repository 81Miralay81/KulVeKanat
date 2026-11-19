extends Node
## Ses efektleri ve müzik. Ses.cal("vurus") ile çalınır.

var _akislar := {}
var _havuz: Array[AudioStreamPlayer] = []
var _sira := 0
var muzik: AudioStreamPlayer
var ates: AudioStreamPlayer
var _son_calma := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for ad in ["savurma", "vurus", "kritik", "patlama", "ates", "atilim", "seviye", "altin",
			"esya", "olum", "aci", "buyu", "dugme", "muzik"]:
		var yol := "res://assets/ses/%s.wav" % ad
		if ResourceLoader.exists(yol):
			_akislar[ad] = load(yol)
	for i in 12:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_havuz.append(p)
	muzik = AudioStreamPlayer.new()
	add_child(muzik)
	if _akislar.has("muzik"):
		muzik.stream = _akislar["muzik"]    # döngü ayarı içe aktarma dosyasında (loop_mode=2)
		muzik.volume_db = -12.0
	ates = AudioStreamPlayer.new()
	add_child(ates)
	if _akislar.has("ates"):
		ates.stream = _akislar["ates"]
		ates.volume_db = -6.0

func cal(ad: String, db := 0.0, perde := 0.08) -> void:
	if not _akislar.has(ad):
		return
	# Aynı sesi aynı anda çok kez çalıp kulak tırmalamasın.
	var simdi := Time.get_ticks_msec()
	if simdi - int(_son_calma.get(ad, 0)) < 45:
		return
	_son_calma[ad] = simdi
	var p := _havuz[_sira]
	_sira = (_sira + 1) % _havuz.size()
	p.stream = _akislar[ad]
	p.volume_db = db
	p.pitch_scale = randf_range(1.0 - perde, 1.0 + perde)
	p.play()


func muzik_baslat() -> void:
	if muzik.stream and not muzik.playing:
		muzik.play()


func ates_dongu(acik: bool) -> void:
	if not ates.stream:
		return
	if acik and not ates.playing:
		ates.play()
	elif not acik:
		ates.stop()
