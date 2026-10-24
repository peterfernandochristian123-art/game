extends Node

const MainMenu = preload("res://scripts/ui/main_menu.gd")
const MenuAudio = preload("res://scripts/ui/menu_audio.gd")

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
	var out_path: String = ProjectSettings.globalize_path("res://test_main_menu_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 5.1: Main Menu & Navigation Flow...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_scene_structure,
		_test_initial_focus,
		_test_navigation_cycle_and_wraparound,
		_test_mouse_touch_direct_selection,
		_test_event_bus_emission_on_select,
		_test_transition_timing_under_three_seconds,
		_test_procedural_menu_audio,
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

func _instantiate_menu() -> MainMenu:
	var scene: PackedScene = load("res://scenes/main_menu.tscn")
	var menu: MainMenu = scene.instantiate() as MainMenu
	add_child(menu)
	return menu

func _test_scene_structure() -> void:
	var menu := _instantiate_menu()
	_check(menu != null, "Scene main_menu.tscn berhasil diinstansiasi.")
	_check(menu.button_nodes.size() == 7, "Main Menu memiliki 7 tombol navigasi (Ditemukan: %d)." % menu.button_nodes.size())

	var expected_ids := [&"arcade", &"versus_ai", &"training", &"local_2p", &"stage_select", &"settings", &"exit"]
	for i in range(expected_ids.size()):
		_check(MainMenu.MENU_DATA[i]["id"] == expected_ids[i], "ID opsi index %d cocok: %s" % [i, expected_ids[i]])

	menu.queue_free()

func _test_initial_focus() -> void:
	var menu := _instantiate_menu()
	_check(menu.current_focus_index == 0, "Fokus awal berada pada index 0 (ARCADE LADDER).")
	var btn0: Button = menu.button_nodes[0]
	_check(btn0.text.begins_with("> [") and btn0.text.ends_with("] <"), "Tombol index 0 mendapatkan format visual fokus '> [ ARCADE LADDER ] <' (Teks: '%s')." % btn0.text)
	_check(menu.subtext_label != null and menu.subtext_label.text.contains("GAUNTLET"), "Subtext label menampilkan deskripsi mode index 0.")
	menu.queue_free()

func _test_navigation_cycle_and_wraparound() -> void:
	var menu := _instantiate_menu()
	var stats := {"nav": 0, "bus": 0}

	menu.focus_changed.connect(func(_idx): stats["nav"] += 1)
	EventBus.menu_navigated.connect(func(): stats["bus"] += 1)

	# 0 -> Down -> 1
	menu._move_focus(1)
	_check(menu.current_focus_index == 1, "Pergerakan ke bawah memindahkan fokus ke index 1.")
	_check(menu.button_nodes[1].text.begins_with("> ["), "Tombol index 1 memiliki highlight kursor aktif.")

	# 1 -> Down -> 2
	menu._move_focus(1)
	_check(menu.current_focus_index == 2, "Pergerakan ke bawah memindahkan fokus ke index 2 (TRAINING MODE).")

	# Pindah langsung ke index EXIT (6)
	var exit_idx := MainMenu.MENU_DATA.size() - 1
	menu.set_focus_index(exit_idx, false)
	_check(menu.current_focus_index == exit_idx, "Fokus berpindah ke index EXIT (%d)." % exit_idx)

	# Exit -> Down -> Wrap-around ke 0
	menu._move_focus(1)
	_check(menu.current_focus_index == 0, "Wrap-around ke bawah dari index EXIT berhasil kembali ke index 0.")

	# 0 -> Up -> Wrap-around ke Exit
	menu._move_focus(-1)
	_check(menu.current_focus_index == exit_idx, "Wrap-around ke atas dari index 0 berhasil menuju index EXIT.")

	_check(stats["nav"] >= 4, "Sinyal focus_changed terpancar pada setiap perpindahan fokus (%dx)." % stats["nav"])
	_check(stats["bus"] >= 4, "EventBus.menu_navigated terpancar global (%dx)." % stats["bus"])

	menu.queue_free()

func _test_mouse_touch_direct_selection() -> void:
	var menu := _instantiate_menu()
	var sel := {"idx": -1, "id": &""}
	menu.option_selected.connect(func(idx, id):
		sel["idx"] = idx
		sel["id"] = id
	)

	# Simulasi hover / sentuhan langsung pada index 3 (LOCAL 2P)
	menu.set_focus_index(3, false)
	_check(menu.current_focus_index == 3, "Fokus berpindah ke index 3.")

	# Simulasi klik tombol
	menu.button_nodes[3].pressed.emit()
	_check(sel["idx"] == 3, "Klik tombol index 3 memicu option_selected dengan index 3 (Hasil: %d)." % sel["idx"])
	_check(sel["id"] == &"local_2p", "Klik tombol index 3 memicu ID 'local_2p' (Hasil: %s)." % sel["id"])
	_check(menu.is_transitioning == true, "State is_transitioning aktif setelah pemilihan.")
	_check(menu.can_navigate == false, "Input terkunci saat transisi berlangsung untuk mencegah input berulang.")

	menu.queue_free()

func _test_event_bus_emission_on_select() -> void:
	var menu := _instantiate_menu()
	var ev := {"mode": &""}
	EventBus.game_mode_selected.connect(func(mode): ev["mode"] = mode)

	menu.set_focus_index(2, false)
	menu._select_current()
	_check(ev["mode"] == &"training", "EventBus.game_mode_selected memancarkan mode 'training' dengan tepat (Hasil: %s)." % ev["mode"])

	menu.queue_free()

func _test_transition_timing_under_three_seconds() -> void:
	var menu := _instantiate_menu()
	_check(menu.transition_duration < 3.0, "Durasi transisi terkonfigurasi %.2fs (< ambang batas NFR 3.0 detik)." % menu.transition_duration)
	_check(menu.fade_rect != null, "Overlay transisi layar FadeOverlay tersedia di scene.")
	_check(menu.fade_rect.mouse_filter == Control.MOUSE_FILTER_IGNORE, "FadeOverlay mengabaikan input mouse (MOUSE_FILTER_IGNORE) agar tidak memblokir tombol.")
	menu.queue_free()

func _test_procedural_menu_audio() -> void:
	var stream: AudioStreamWAV = MenuAudio.create_tone_stream(880.0, 0.05, 0.25)
	_check(stream != null, "MenuAudio berhasil membuat AudioStreamWAV.")
	_check(stream.format == AudioStreamWAV.FORMAT_16_BITS, "Format audio 16-bit PCM valid.")
	_check(stream.data.size() > 0, "Data byte audio terisi (Ukuran: %d bytes)." % stream.data.size())
