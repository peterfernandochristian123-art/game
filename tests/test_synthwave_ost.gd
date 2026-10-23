extends Node

const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")
const MusicSynthesizerScript = preload("res://scripts/audio/music_synthesizer.gd")
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
	var out_path: String = ProjectSettings.globalize_path("res://test_synthwave_ost_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 8.1: Cyberpunk Synthwave OST System...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_title_theme_synthesis,
		_test_arena_theme_synthesis,
		_test_audio_manager_bgm_playback_and_crossfade,
		_test_bus_bgm_volume_control,
		_test_arena_skyscraper_bgm_trigger
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

func _test_title_theme_synthesis() -> void:
	var theme: AudioStreamWAV = MusicSynthesizerScript.generate_title_theme()
	_check(theme != null, "Trek Title Theme ('Neon Horizon') berhasil dihasilkan.")
	_check(theme.data.size() > 0, "Buffer audio Title Theme berisi sampel audio valid.")
	_check(theme.mix_rate == 22050, "Sample rate Title Theme adalah 22050 Hz.")
	_check(theme.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Loop mode Title Theme aktif (LOOP_FORWARD).")
	_check(theme.loop_end > 0, "Loop end point Title Theme terkonfigurasi ke panjang audio.")

func _test_arena_theme_synthesis() -> void:
	var theme: AudioStreamWAV = MusicSynthesizerScript.generate_arena_theme()
	_check(theme != null, "Trek Arena Battle Theme ('Skyscraper Meltdown') berhasil dihasilkan.")
	_check(theme.data.size() > 0, "Buffer audio Arena Theme berisi sampel audio valid.")
	_check(theme.mix_rate == 22050, "Sample rate Arena Theme adalah 22050 Hz.")
	_check(theme.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Loop mode Arena Theme aktif (LOOP_FORWARD).")
	_check(theme.loop_end > 0, "Loop end point Arena Theme terkonfigurasi ke panjang audio.")

func _test_audio_manager_bgm_playback_and_crossfade() -> void:
	var audio_mgr: Node = AudioManagerScript.new()
	add_child(audio_mgr)

	_check(audio_mgr.get_current_bgm_theme() == &"", "Tema BGM awal adalah kosong.")

	# 1. Mainkan Title Theme
	audio_mgr.play_bgm(AudioManagerScript.THEME_TITLE, 0.0)
	_check(audio_mgr.get_current_bgm_theme() == AudioManagerScript.THEME_TITLE, "Tema BGM berhasil beralih ke 'title'.")

	# 2. Mainkan Arena Theme (Crossfade)
	audio_mgr.play_bgm(AudioManagerScript.THEME_ARENA, 0.0)
	_check(audio_mgr.get_current_bgm_theme() == AudioManagerScript.THEME_ARENA, "Tema BGM berhasil beralih ke 'arena'.")

	# 3. Stop BGM
	audio_mgr.stop_bgm(0.0)
	_check(audio_mgr.get_current_bgm_theme() == &"", "Tema BGM berhasil dihentikan (kosong).")

	audio_mgr.queue_free()

func _test_bus_bgm_volume_control() -> void:
	var audio_mgr: Node = AudioManagerScript.new()
	add_child(audio_mgr)

	audio_mgr.set_bus_volume(AudioManagerScript.BUS_BGM, 0.60)
	var vol_bgm: float = audio_mgr.get_bus_volume(AudioManagerScript.BUS_BGM)
	_check(is_equal_approx(vol_bgm, 0.60), "Volume bus BGM berhasil diatur ke 0.60.")

	audio_mgr.set_bus_volume(AudioManagerScript.BUS_BGM, 0.0)
	var idx := AudioServer.get_bus_index(AudioManagerScript.BUS_BGM)
	_check(AudioServer.is_bus_mute(idx), "Bus BGM berhasil di-mute saat volume diset 0.0.")

	audio_mgr.set_bus_volume(AudioManagerScript.BUS_BGM, 1.0)
	_check(not AudioServer.is_bus_mute(idx), "Bus BGM kembali unmute saat volume dinaikkan.")

	audio_mgr.queue_free()

func _test_arena_skyscraper_bgm_trigger() -> void:
	var arena: Node2D = ArenaSkyscraperScene.instantiate()
	add_child(arena)

	var audio_node := arena.get_node_or_null("AudioManager")
	_check(audio_node != null, "AudioManager terpasang di arena skyscraper.")
	if audio_node:
		_check(audio_node.get_current_bgm_theme() == AudioManagerScript.THEME_ARENA, "Arena Skyscraper otomatis memicu Arena BGM.")

	arena.queue_free()
