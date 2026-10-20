extends Node

const SettingsManagerScript = preload("res://scripts/core/settings_manager.gd")
const LocalVersusModeScene = preload("res://scenes/local_versus_mode.tscn")
const BaseMechaScript = preload("res://scripts/characters/base_mecha.gd")

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
	var out_path: String = ProjectSettings.globalize_path("res://test_local_versus_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 5.6: Local 2P & Configuration...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_settings_manager_persistence,
		_test_local_versus_scene_structure,
		_test_independent_input_routing,
		_test_player_action_isolation,
		_test_local_versus_match_flow
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

func _test_settings_manager_persistence() -> void:
	var sm: Node = SettingsManagerScript.new()
	add_child(sm)

	# 1. Tulis konfigurasi custom
	sm.set_setting("audio", "master_volume", 0.65)
	sm.set_setting("audio", "bgm_volume", 0.40)
	sm.set_setting("display", "screen_shake", false)
	var err: int = sm.save_settings()
	_check(err == OK, "SettingsManager berhasil menyimpan file konfigurasi ke user://settings.cfg.")

	# 2. Muat ulang dalam instance baru
	var sm2: Node = SettingsManagerScript.new()
	add_child(sm2)
	var load_success: bool = sm2.load_settings()
	_check(load_success, "SettingsManager baru berhasil memuat file konfigurasi yang tersimpan.")

	var master_vol: float = sm2.get_setting("audio", "master_volume", 1.0)
	var bgm_vol: float = sm2.get_setting("audio", "bgm_volume", 1.0)
	var screen_shake: bool = sm2.get_setting("display", "screen_shake", true)

	_check(is_equal_approx(master_vol, 0.65), "Nilai master_volume persisten (0.65).")
	_check(is_equal_approx(bgm_vol, 0.40), "Nilai bgm_volume persisten (0.40).")
	_check(not screen_shake, "Nilai screen_shake persisten (false).")

	# 3. Reset to defaults
	sm2.reset_to_defaults()
	var reset_master: float = sm2.get_setting("audio", "master_volume", 0.0)
	var reset_shake: bool = sm2.get_setting("display", "screen_shake", false)
	_check(is_equal_approx(reset_master, 1.0), "Reset berhasil mengembalikan master_volume ke default (1.0).")
	_check(reset_shake, "Reset berhasil mengembalikan screen_shake ke default (true).")

	sm.queue_free()
	sm2.queue_free()

func _test_local_versus_scene_structure() -> void:
	var scene = LocalVersusModeScene.instantiate()
	add_child(scene)

	_check(scene.p1 != null, "Player 1 mecha terpasang.")
	_check(scene.p2 != null, "Player 2 mecha terpasang.")
	_check(scene.p1.player_index == 1, "Player 1 memiliki player_index = 1.")
	_check(scene.p2.player_index == 2, "Player 2 memiliki player_index = 2.")
	_check(scene.match_manager != null, "MatchManager terpasang.")
	_check(scene.hud != null, "CombatHUD terpasang.")
	_check(scene.result_overlay != null, "ResultOverlay terpasang.")

	scene.queue_free()

func _test_independent_input_routing() -> void:
	var scene = LocalVersusModeScene.instantiate()
	add_child(scene)

	var p1 = scene.p1
	var p2 = scene.p2

	# Verifikasi routing aksi P1
	_check(p1.get_player_action(&"jump") == &"jump", "P1 jump mengarah ke action 'jump'.")
	_check(p1.get_player_action(&"attack_light") == &"attack_light", "P1 attack_light mengarah ke action 'attack_light'.")
	_check(p1.get_player_action(&"dash") == &"dash", "P1 dash mengarah ke action 'dash'.")

	# Verifikasi routing aksi P2
	_check(p2.get_player_action(&"jump") == &"p2_jump", "P2 jump terpisah ke action 'p2_jump'.")
	_check(p2.get_player_action(&"attack_light") == &"p2_attack_light", "P2 attack_light terpisah ke action 'p2_attack_light'.")
	_check(p2.get_player_action(&"dash") == &"p2_dash", "P2 dash terpisah ke action 'p2_dash'.")

	scene.queue_free()

func _test_player_action_isolation() -> void:
	var scene = LocalVersusModeScene.instantiate()
	add_child(scene)

	var p1 = scene.p1
	var p2 = scene.p2

	# 1. P1 trigger simulated action
	p1.trigger_simulated_action(&"attack_light")
	_check(p1.is_attack_light_requested(), "P1 mendeteksi attack_light.")
	_check(not p2.is_attack_light_requested(), "P2 terisolasi dari input attack_light P1.")

	# 2. P2 trigger simulated action
	p2.trigger_simulated_action(&"attack_heavy")
	_check(p2.is_attack_heavy_requested(), "P2 mendeteksi attack_heavy.")
	_check(not p1.is_attack_heavy_requested(), "P1 terisolasi dari input attack_heavy P2.")

	# 3. P2 trigger simulated jump
	p2.trigger_simulated_action(&"jump")
	_check(p2.is_jump_requested(), "P2 mendeteksi jump.")
	_check(not p1.is_jump_requested(), "P1 terisolasi dari input jump P2.")

	scene.queue_free()

func _test_local_versus_match_flow() -> void:
	var scene = LocalVersusModeScene.instantiate()
	add_child(scene)

	var mm = scene.match_manager
	var p1 = scene.p1
	var p2 = scene.p2

	_check(mm.current_round == 1, "Ronde 1 aktif.")
	_check(mm.player1 == p1 and mm.player2 == p2, "MatchManager terikat dengan P1 dan P2.")

	# Simulasikan eliminasi P2
	p2.set_hp(0)
	mm.check_win_conditions()

	_check(mm.p1_wins == 1, "P1 memenangkan ronde saat P2 KO.")
	_check(scene.hud.p1_win1 != null and scene.hud.p1_win2 != null, "HUD memiliki ikon ronde P1.")

	scene.queue_free()
