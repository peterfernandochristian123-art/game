extends Node

const CombatHUDScript = preload("res://scripts/ui/combat_hud.gd")

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
	var out_path: String = ProjectSettings.globalize_path("res://test_combat_hud_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 5.3: Combat HUD & Visual Meters...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_hud_initial_layout,
		_test_hp_updates_realtime,
		_test_heat_zone_colors_and_tags,
		_test_ultimate_gauge_updates,
		_test_timer_and_round_wins_sync,
		_test_fighter_binding_with_signals,
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

func _instantiate_hud() -> Control:
	var scene: PackedScene = load("res://scenes/combat_hud.tscn")
	var hud = scene.instantiate()
	add_child(hud)
	return hud

func _test_hud_initial_layout() -> void:
	var hud := _instantiate_hud()
	_check(hud != null, "Scene combat_hud.tscn berhasil diinstansiasi.")
	_check(hud.p1_hp_bar != null and hud.p2_hp_bar != null, "HP Bar P1 dan P2 tersedia.")
	_check(hud.p1_heat_bar != null and hud.p2_heat_bar != null, "Heat Bar P1 dan P2 tersedia.")
	_check(hud.p1_ultimate_bar != null and hud.p2_ultimate_bar != null, "Ultimate Bar P1 dan P2 tersedia.")
	_check(hud.timer_label != null and hud.round_label != null, "Timer dan Round label tersedia.")
	_check(hud.p1_win1 != null and hud.p2_win1 != null, "Round win indicators tersedia.")
	hud.queue_free()

func _test_hp_updates_realtime() -> void:
	var hud := _instantiate_hud()

	# Update P1 HP
	hud.update_p1_hp(750, 1000)
	_check(int(hud.p1_hp_bar.value) == 750, "P1 HP bar terupdate ke 750.")
	_check(hud.p1_hp_text.text.contains("750 / 1000"), "P1 HP teks menampilkan '750 / 1000'.")

	# Update P2 HP
	hud.update_p2_hp(400, 1200)
	_check(int(hud.p2_hp_bar.value) == 400, "P2 HP bar terupdate ke 400.")
	_check(hud.p2_hp_text.text.contains("400 / 1200"), "P2 HP teks menampilkan '400 / 1200'.")

	hud.queue_free()

func _test_heat_zone_colors_and_tags() -> void:
	var hud := _instantiate_hud()

	# 1. Zona Nominal (0–79%)
	hud.update_p1_heat(45.0, 100.0)
	_check(hud.p1_heat_bar.modulate == CombatHUDScript.COLOR_HEAT_NOMINAL, "Zona Nominal (45%): Warna Cyan.")
	_check(not hud.p1_heat_text.text.contains("OVERCLOCK"), "Zona Nominal tidak memuat tag OVERCLOCK.")

	# 2. Zona Overclock (80–99%)
	hud.update_p1_heat(88.0, 100.0)
	_check(hud.p1_heat_bar.modulate == CombatHUDScript.COLOR_HEAT_OVERCLOCK, "Zona Overclock (88%): Warna Merah Menyala.")
	_check(hud.p1_heat_text.text.contains("[OVERCLOCK]"), "Zona Overclock memuat tag [OVERCLOCK].")

	# 3. Zona Meltdown Core Shutdown (100%)
	hud.update_p1_heat(100.0, 100.0)
	_check(hud.p1_heat_bar.modulate == CombatHUDScript.COLOR_HEAT_MELTDOWN, "Zona Meltdown (100%): Warna Ungu Pudar.")
	_check(hud.p1_heat_text.text.contains("[MELTDOWN]"), "Zona Meltdown memuat tag [MELTDOWN].")

	hud.queue_free()

func _test_ultimate_gauge_updates() -> void:
	var hud := _instantiate_hud()

	# Ultimate terisi 50%
	hud.update_p1_ultimate(50.0, 100.0)
	_check(int(hud.p1_ultimate_bar.value) == 50, "Ultimate bar terisi 50%.")
	_check(hud.p1_ultimate_bar.modulate == CombatHUDScript.COLOR_ULTIMATE_CHARGING, "Warna charging adalah Gold Amber.")

	# Ultimate penuh 100%
	hud.update_p1_ultimate(100.0, 100.0)
	_check(int(hud.p1_ultimate_bar.value) == 100, "Ultimate bar terisi penuh 100%.")
	_check(hud.p1_ultimate_text.text.contains("PROTOCOL READY"), "Teks menampilkan 'PROTOCOL READY' saat bar penuh.")
	_check(hud.p1_ultimate_bar.modulate == CombatHUDScript.COLOR_ULTIMATE_MAX, "Warna flash MAX saat bar penuh.")

	hud.queue_free()

func _test_timer_and_round_wins_sync() -> void:
	var hud := _instantiate_hud()

	# Timer countdown
	hud.update_timer(89.4)
	_check(hud.timer_label.text == "90", "Timer 89.4s dibulatkan ke atas menjadi '90'.")

	hud.update_timer(12.0)
	_check(hud.timer_label.text == "12", "Timer menampilkan '12'.")
	_check(hud.timer_label.modulate.r > 0.9 and hud.timer_label.modulate.g < 0.5, "Timer berkedip merah saat sisa waktu <= 15s.")

	# Round win counters
	hud.update_round_wins(1, 0)
	_check(hud.p1_win1.color.a > 0.9, "P1 Win 1 menyala saat P1 meraih 1 kemenangan.")
	_check(hud.p1_win2.color.a < 0.6, "P1 Win 2 tetap kosong.")
	_check(hud.p2_win1.color.a < 0.6, "P2 Win 1 tetap kosong.")

	hud.update_round_wins(2, 1)
	_check(hud.p1_win1.color.a > 0.9 and hud.p1_win2.color.a > 0.9, "P1 Win 1 dan Win 2 menyala penuh saat meraih 2 kemenangan.")
	_check(hud.p2_win1.color.a > 0.9, "P2 Win 1 menyala saat P2 meraih 1 kemenangan.")
	_check(hud.p2_win2.color.a < 0.6, "P2 Win 2 tetap kosong.")

	hud.queue_free()

# Mock fighter untuk pengujian binding
class MockFighter extends Node2D:
	signal hp_changed(current: int, max_val: int)
	signal heat_changed(current: float, max_val: float)
	signal ultimate_changed(current: float, max_val: float)

	var max_hp: int = 1000
	var current_hp: int = 1000
	var heat_gauge: float = 0.0
	var current_ultimate: float = 0.0

func _test_fighter_binding_with_signals() -> void:
	var hud := _instantiate_hud()
	var mock_p1 := MockFighter.new()
	mock_p1.name = "ApexViper"
	add_child(mock_p1)

	var mock_p2 := MockFighter.new()
	mock_p2.name = "TitanBulwark"
	mock_p2.max_hp = 1200
	mock_p2.current_hp = 1200
	add_child(mock_p2)

	hud.bind_fighters(mock_p1, mock_p2)

	# Verifikasi inisialisasi awal dari mock
	_check(hud.p1_name_label.text.contains("APEXVIPER"), "Nama P1 terinisialisasi.")
	_check(hud.p2_name_label.text.contains("TITANBULWARK"), "Nama P2 terinisialisasi.")

	# Emit hp_changed dari P1
	mock_p1.hp_changed.emit(650, 1000)
	_check(int(hud.p1_hp_bar.value) == 650, "Binding sinyal: HP P1 terupdate otomatis via sinyal hp_changed.")

	# Emit heat_changed dari P2 ke zona Overclock
	mock_p2.heat_changed.emit(92.0, 100.0)
	_check(hud.p2_heat_bar.modulate == CombatHUDScript.COLOR_HEAT_OVERCLOCK, "Binding sinyal: Heat P2 terupdate otomatis ke Overclock via sinyal heat_changed.")

	# Emit ultimate_changed dari P1
	mock_p1.ultimate_changed.emit(100.0, 100.0)
	_check(hud.p1_ultimate_text.text.contains("PROTOCOL READY"), "Binding sinyal: Ultimate P1 terupdate otomatis ke PROTOCOL READY via sinyal ultimate_changed.")

	hud.queue_free()
	mock_p1.queue_free()
	mock_p2.queue_free()
