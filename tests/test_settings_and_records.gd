extends Node

## Test Suite: Epic 14 - Settings Modal, In-Match Pause & Battle Records Persistence

const SettingsManagerScript = preload("res://scripts/core/settings_manager.gd")
const SettingsPanelScript = preload("res://scripts/ui/settings_panel.gd")
const RecordsManagerScript = preload("res://scripts/core/records_manager.gd")
const RecordsPanelScript = preload("res://scripts/ui/records_panel.gd")
const PauseMenuScript = preload("res://scripts/ui/pause_menu.gd")

const SettingsPanelScene = preload("res://scenes/settings_panel.tscn")
const RecordsPanelScene = preload("res://scenes/records_panel.tscn")
const PauseMenuScene = preload("res://scenes/pause_menu.tscn")

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
	var out_path: String = ProjectSettings.globalize_path("res://test_settings_and_records_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Epic 14: Settings & Battle Records...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_settings_manager_lifecycle,
		_test_settings_panel_ui_binding,
		_test_records_manager_recording,
		_test_records_panel_ui_sync,
		_test_pause_menu_state_machine
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
	get_tree().quit(0 if passed == tests.size() else 1)

func _test_settings_manager_lifecycle() -> void:
	var mgr := SettingsManager.get_instance()
	_check(mgr != null, "SettingsManager singleton berhasil diinisialisasi.")

	# Test set & get setting
	mgr.set_setting("audio", "master_volume", 0.75)
	var val: float = float(mgr.get_setting("audio", "master_volume"))
	_check(is_equal_approx(val, 0.75), "Master volume setting berhasil diubah ke 0.75.")

	mgr.set_setting("display", "fullscreen", true)
	var is_fs: bool = bool(mgr.get_setting("display", "fullscreen"))
	_check(is_fs == true, "Fullscreen setting berhasil diubah ke true.")

	# Test save & reload
	var err := mgr.save_settings()
	_check(err == OK, "File settings.cfg berhasil disimpan tanpa error.")

	# Reset ke default
	mgr.reset_to_defaults()
	var def_vol: float = float(mgr.get_setting("audio", "master_volume"))
	_check(is_equal_approx(def_vol, 1.0), "Reset to defaults mengembalikan master volume ke 1.0.")

func _test_settings_panel_ui_binding() -> void:
	var panel = SettingsPanelScene.instantiate() as SettingsPanel
	add_child(panel)

	_check(panel != null, "SettingsPanel scene berhasil diinstansiasi.")
	_check(panel.master_slider != null, "Master slider ditemukan di hierarki.")
	_check(panel.bgm_slider != null, "BGM slider ditemukan di hierarki.")
	_check(panel.sfx_slider != null, "SFX slider ditemukan di hierarki.")
	_check(panel.fullscreen_check != null, "Fullscreen checkbox ditemukan.")
	_check(panel.btn_records != null, "BtnRecords ditemukan di hierarki.")

	# Test slider change
	panel.master_slider.value = 50.0
	panel._on_master_slider_changed(50.0)
	var mgr := SettingsManager.get_instance()
	var cur_val: float = float(mgr.get_setting("audio", "master_volume"))
	_check(is_equal_approx(cur_val, 0.5), "Slider 50% berhasil mengupdate SettingsManager ke 0.5.")

	panel.queue_free()

func _test_records_manager_recording() -> void:
	var rec := RecordsManager.get_instance()
	_check(rec != null, "RecordsManager singleton berhasil diinisialisasi.")

	rec.reset_records()
	_check(rec.get_stat("total_matches", 0) == 0, "Reset records mengosongkan total_matches.")
	_check(is_equal_approx(rec.get_win_rate(), 0.0), "Win rate awal adalah 0.0%.")

	# Catat 1 kemenangan Viper
	rec.record_match(true, &"viper", &"bulwark", false, 3, 0)
	_check(rec.get_stat("total_matches", 0) == 1, "Total match tercatat 1.")
	_check(rec.get_stat("wins", 0) == 1, "Wins tercatat 1.")
	_check(rec.get_stat("parries_executed", 0) == 3, "Parries tercatat 3.")
	_check(is_equal_approx(rec.get_win_rate(), 100.0), "Win rate 100.0% setelah 1 kemenangan.")

	# Catat 1 kekalahan dengan Kage
	rec.record_match(false, &"kage", &"pulsar", true, 1, 1)
	_check(rec.get_stat("total_matches", 0) == 2, "Total match tercatat 2.")
	_check(rec.get_stat("losses", 0) == 1, "Losses tercatat 1.")
	_check(rec.get_stat("ring_outs", 0) == 1, "Ring out tercatat 1.")
	_check(is_equal_approx(rec.get_win_rate(), 50.0), "Win rate 50.0% setelah 1 win 1 loss.")

func _test_records_panel_ui_sync() -> void:
	var rec_panel = RecordsPanelScene.instantiate() as RecordsPanel
	add_child(rec_panel)

	_check(rec_panel != null, "RecordsPanel scene berhasil diinstansiasi.")
	_check(rec_panel.matches_label != null, "Matches label ditemukan.")
	_check(rec_panel.winrate_label != null, "Winrate label ditemukan.")

	rec_panel._sync_display()
	_check(rec_panel.matches_label.text == "2", "Matches label menampilkan '2'.")
	_check(rec_panel.winrate_label.text == "50.0%", "Winrate label menampilkan '50.0%'.")

	rec_panel.queue_free()

func _test_pause_menu_state_machine() -> void:
	var pause_menu = PauseMenuScene.instantiate() as PauseMenu
	add_child(pause_menu)

	_check(pause_menu != null, "PauseMenu scene berhasil diinstansiasi.")
	_check(pause_menu.process_mode == Node.PROCESS_MODE_ALWAYS, "PauseMenu berjalan dengan PROCESS_MODE_ALWAYS.")
	_check(pause_menu.visible == false, "PauseMenu awalnya tersembunyi.")

	# Test pause
	pause_menu.pause()
	_check(get_tree().paused == true, "get_tree().paused bernilai true setelah pause().")
	_check(pause_menu.visible == true, "PauseMenu terlihat saat dijeda.")

	# Test resume
	pause_menu.resume()
	_check(get_tree().paused == false, "get_tree().paused bernilai false setelah resume().")
	_check(pause_menu.visible == false, "PauseMenu tersembunyi kembali setelah resume().")

	pause_menu.queue_free()
