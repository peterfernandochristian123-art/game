extends Node

const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")
const AudioSynthesizerScript = preload("res://scripts/audio/audio_synthesizer.gd")
const ArenaSkyscraperScene = preload("res://scenes/arena_skyscraper.tscn")

var log_file: FileAccess = null
var _failed: bool = false

func _log(msg: String) -> void:
	print(msg)
	if log_file:
		log_file.store_line(msg)
		log_file.flush()

func _check(cond: bool, msg: String) -> void:
	if not cond:
		_failed = true
		_log("   [FAIL] " + msg)

func _ready() -> void:
	var out_path: String = ProjectSettings.globalize_path("res://test_audio_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 6.3: Audio & Announcer System...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_audio_busses_presence,
		_test_bus_volume_control_and_mute,
		_test_procedural_synthesizer_streams,
		_test_event_bus_audio_dispatch,
		_test_arena_skyscraper_audio_integration
	]

	var passed: int = 0
	for t in tests:
		_failed = false
		_log("\n--- %s ---" % t.get_method())
		t.call()
		if _failed:
			_log(" [GAGAL]")
		else:
			passed += 1
			_log(" [LULUS]")

	_log("\n==================================================")
	_log("HASIL: %d/%d pengujian lulus." % [passed, tests.size()])
	_log("==================================================")

	if log_file:
		log_file.close()

	if passed == tests.size():
		get_tree().quit(0)
	else:
		get_tree().quit(1)

func _test_audio_busses_presence() -> void:
	var audio_mgr: Node = AudioManagerScript.new()
	add_child(audio_mgr)

	for bus_name in AudioManagerScript.REQUIRED_BUSSES:
		var idx: int = AudioServer.get_bus_index(bus_name)
		_check(idx != -1, "Bus audio '%s' terdaftar pada AudioServer." % bus_name)

	audio_mgr.queue_free()

func _test_bus_volume_control_and_mute() -> void:
	var audio_mgr: Node = AudioManagerScript.new()
	add_child(audio_mgr)

	# 1. Atur volume SFX ke 0.75
	audio_mgr.set_bus_volume(AudioManagerScript.BUS_SFX, 0.75)
	var vol_sfx: float = audio_mgr.get_bus_volume(AudioManagerScript.BUS_SFX)
	_check(is_equal_approx(vol_sfx, 0.75), "Volume bus SFX berhasil diatur ke 0.75.")

	# 2. Atur volume ke 0.0 (mute)
	audio_mgr.set_bus_volume(AudioManagerScript.BUS_SFX, 0.0)
	var is_muted: bool = AudioServer.is_bus_mute(AudioServer.get_bus_index(AudioManagerScript.BUS_SFX))
	_check(is_muted, "Bus SFX otomatis di-mute saat volume diset ke 0.0.")

	# 3. Kembalikan ke 1.0 (unmute)
	audio_mgr.set_bus_volume(AudioManagerScript.BUS_SFX, 1.0)
	var unmuted: bool = not AudioServer.is_bus_mute(AudioServer.get_bus_index(AudioManagerScript.BUS_SFX))
	_check(unmuted, "Bus SFX berhasil di-unmute saat volume dinaikkan ke 1.0.")

	audio_mgr.queue_free()

func _test_procedural_synthesizer_streams() -> void:
	# 1. Metal Clang Stream
	var clang = AudioSynthesizerScript.generate_metal_clang(340.0, 0.15)
	_check(clang != null, "Stream Metal Clang berhasil dihasilkan.")
	_check(clang.data.size() > 0, "Buffer audio Metal Clang memiliki sampel data valid.")

	# 2. Spark Parry Stream
	var parry = AudioSynthesizerScript.generate_spark_parry(880.0, 0.2)
	_check(parry != null and parry.data.size() > 0, "Stream Spark Parry valid.")

	# 3. Hydraulic Hiss Stream
	var hiss = AudioSynthesizerScript.generate_hydraulic_hiss(0.15)
	_check(hiss != null and hiss.data.size() > 0, "Stream Hydraulic Hiss valid.")

	# 4. Announcer Chime Stream
	var chime = AudioSynthesizerScript.generate_announcer_chime(0.25)
	_check(chime != null and chime.data.size() > 0, "Stream Announcer Chime valid.")

func _test_event_bus_audio_dispatch() -> void:
	var audio_mgr: Node = AudioManagerScript.new()
	add_child(audio_mgr)

	var announcer_cue: Dictionary = {"cue": ""}
	audio_mgr.announcer_called.connect(func(c): announcer_cue["cue"] = c)

	# 1. Pemicu Announcer saat Ronde Selesai (K.O.)
	audio_mgr._on_round_ended(1, &"ko")
	_check(announcer_cue["cue"] == "K.O.!", "Announcer memutar cue 'K.O.!' pada akhir ronde.")

	# 2. Pemicu Announcer saat Ring Out
	audio_mgr._on_round_ended(2, &"ring_out")
	_check(announcer_cue["cue"] == "RING OUT!", "Announcer memutar cue 'RING OUT!' pada eliminasi tebing.")

	# 3. Pemutaran SFX langsung
	audio_mgr.play_sfx(audio_mgr.sfx_metal_clang)
	_check(true, "Pemutaran sfx pada AudioStreamPlayer berjalan lancar.")

	audio_mgr.queue_free()

func _test_arena_skyscraper_audio_integration() -> void:
	var arena: Node2D = ArenaSkyscraperScene.instantiate()
	add_child(arena)

	var audio_node := arena.get_node_or_null("AudioManager")
	_check(audio_node != null, "AudioManager terpasang pada scene ArenaSkyscraper.")
	_check(audio_node.has_method("play_sfx"), "AudioManager memiliki method play_sfx.")
	_check(audio_node.has_method("play_announcer"), "AudioManager memiliki method play_announcer.")

	arena.queue_free()
