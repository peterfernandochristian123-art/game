extends Node

const TrainingDummyControllerScript = preload("res://scripts/training/training_dummy_controller.gd")
const CollisionDebugOverlayScript = preload("res://scripts/training/collision_debug_overlay.gd")
const FrameInspectorScript = preload("res://scripts/training/frame_inspector.gd")

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
	var out_path: String = ProjectSettings.globalize_path("res://test_training_mode_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 5.4: Training Mode Suite...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_training_scene_structure,
		_test_collision_overlay_toggle,
		_test_frame_inspector_recording,
		_test_dummy_mode_cycling,
		_test_training_reset_shortcut,
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

func _instantiate_training_scene() -> Node:
	var scene: PackedScene = load("res://scenes/training_mode.tscn")
	var t_mode = scene.instantiate()
	add_child(t_mode)
	return t_mode

func _test_training_scene_structure() -> void:
	var tm := _instantiate_training_scene()
	_check(tm != null, "Scene training_mode.tscn berhasil diinstansiasi.")
	_check(tm.p1 != null and tm.dummy != null, "Petarung P1 dan Dummy tersedia.")
	_check(tm.collision_overlay != null, "CollisionDebugOverlay tersedia.")
	_check(tm.frame_inspector != null, "FrameInspector tersedia.")
	_check(tm.dummy_controller != null, "TrainingDummyController tersedia.")
	_check(tm.hud != null, "CombatHUD tersedia.")
	tm.queue_free()

func _test_collision_overlay_toggle() -> void:
	var tm := _instantiate_training_scene()
	var overlay = tm.collision_overlay

	_check(overlay.overlay_enabled == false, "Overlay collision default dalam status non-aktif.")

	# Toggle On (F1)
	overlay.toggle_overlay()
	_check(overlay.overlay_enabled == true, "Toggle F1 mengaktifkan overlay_enabled.")
	_check(overlay.visible == true, "Overlay visual visible == true.")

	# Toggle Off (F1)
	overlay.toggle_overlay()
	_check(overlay.overlay_enabled == false, "Toggle F1 kedua menonaktifkan overlay_enabled.")
	_check(overlay.visible == false, "Overlay visual visible == false.")

	tm.queue_free()

func _test_frame_inspector_recording() -> void:
	var tm := _instantiate_training_scene()
	var fi = tm.frame_inspector

	var emitted := {"recorded": false}
	fi.frame_data_recorded.connect(func(_m, _s, _a, _r, _h, _b): emitted["recorded"] = true)

	fi.record_manual_data("Viper Blink Slash", 6, 4, 12, 5, -2, 75, 25.0)

	_check(emitted["recorded"] == true, "Sinyal frame_data_recorded terpancar saat merekam jurus.")
	_check(fi.last_move_name == "Viper Blink Slash", "Move name tercatat dengan benar.")
	_check(fi.last_startup == 6 and fi.last_active == 4 and fi.last_recovery == 12, "Startup, active, recovery tercatat tepat.")
	_check(fi.last_advantage_on_hit == 5, "Advantage on hit tercatat +5f.")
	_check(fi.last_advantage_on_block == -2, "Advantage on block tercatat -2f.")
	_check(fi.advantage_label.text.contains("+5f") and fi.advantage_label.text.contains("-2f"), "Label Advantage terformat dengan tepat.")

	tm.queue_free()

func _test_dummy_mode_cycling() -> void:
	var tm := _instantiate_training_scene()
	var dc = tm.dummy_controller

	_check(dc.current_mode == TrainingDummyControllerScript.DummyMode.STAND, "Mode dummy awal adalah STAND.")

	# Cycle 1 -> CROUCH
	dc.cycle_dummy_mode()
	_check(dc.current_mode == TrainingDummyControllerScript.DummyMode.CROUCH, "Cycle 1 mengubah mode ke CROUCH.")

	# Cycle 2 -> BLOCK_ALL
	dc.cycle_dummy_mode()
	_check(dc.current_mode == TrainingDummyControllerScript.DummyMode.BLOCK_ALL, "Cycle 2 mengubah mode ke BLOCK_ALL.")

	# Verifikasi behavior auto-block mundur
	dc._process_dummy_behavior()
	var expected_dir: float = 1.0 if tm.p1.global_position.x < tm.dummy.global_position.x else -1.0
	_check(tm.dummy.simulated_horizontal_input == expected_dir, "Dalam mode BLOCK_ALL, dummy menahan arah mundur.")

	# Cycle 3 -> RANDOM_PARRY
	dc.cycle_dummy_mode()
	_check(dc.current_mode == TrainingDummyControllerScript.DummyMode.RANDOM_PARRY, "Cycle 3 mengubah mode ke RANDOM_PARRY.")

	# Cycle 4 -> Wrap around kembali ke STAND
	dc.cycle_dummy_mode()
	_check(dc.current_mode == TrainingDummyControllerScript.DummyMode.STAND, "Cycle 4 wrap around kembali ke STAND.")

	tm.queue_free()

func _test_training_reset_shortcut() -> void:
	var tm := _instantiate_training_scene()
	var dc = tm.dummy_controller

	# Ubah posisi dan status mecha
	tm.p1.global_position = Vector2(200, 300)
	tm.p1.set_hp(350)
	tm.p1.add_heat(70.0)

	tm.dummy.global_position = Vector2(1100, 300)
	tm.dummy.set_hp(400)
	tm.dummy.add_heat(80.0)

	# Eksekusi Quick Reset (F3)
	dc.reset_positions()

	_check(tm.p1.global_position == TrainingDummyControllerScript.DEFAULT_P1_SPAWN, "P1 posisi ter-reset ke titik spawn default (500, 288).")
	_check(tm.dummy.global_position == TrainingDummyControllerScript.DEFAULT_P2_SPAWN, "Dummy posisi ter-reset ke titik spawn default (900, 288).")
	_check(tm.p1.current_hp == tm.p1.max_hp, "HP P1 pulih 100% penuh.")
	_check(tm.dummy.current_hp == tm.dummy.max_hp, "HP Dummy pulih 100% penuh.")
	_check(is_zero_approx(tm.p1.heat_gauge), "Heat P1 ter-reset ke 0%.")
	_check(is_zero_approx(tm.dummy.heat_gauge), "Heat Dummy ter-reset ke 0%.")

	tm.queue_free()
