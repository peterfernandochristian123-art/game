extends Node

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")
const BaseMecha = preload("res://scripts/characters/base_mecha.gd")
const StateMachine = preload("res://scripts/combat/fsm/state_machine.gd")
const IdleState = preload("res://scripts/combat/fsm/idle_state.gd")
const FallState = preload("res://scripts/combat/fsm/fall_state.gd")
const CliffhangerState = preload("res://scripts/combat/fsm/cliffhanger_state.gd")

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
	var out_path: String = ProjectSettings.globalize_path("res://test_cliffhanger_system_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 4.2: Cliffhanger Struggle System...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_cliffhanger_entry_and_positioning,
		_test_max_one_activation_per_round,
		_test_climb_up_jump_action,
		_test_ledge_sweep_attack_action,
		_test_drop_fall_manual_and_timeout,
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

func _create_mecha_with_cliffhanger() -> BaseMecha:
	var mecha := BaseMecha.new()
	mecha.name = "MechaCliff"

	var fsm := StateMachine.new()
	fsm.name = "StateMachine"
	mecha.add_child(fsm)

	var idle := IdleState.new()
	idle.name = "Idle"
	fsm.add_child(idle)

	var fall := FallState.new()
	fall.name = "Fall"
	fsm.add_child(fall)

	var ch := CliffhangerState.new()
	ch.name = "Cliffhanger"
	fsm.add_child(ch)

	add_child(mecha)
	return mecha

func _test_cliffhanger_entry_and_positioning() -> void:
	var mecha = _create_mecha_with_cliffhanger()

	var success = mecha.trigger_cliffhanger(&"left")
	_check(success == true, "Trigger cliffhanger kiri harus berhasil")
	_check(mecha.state_machine.current_state.name == &"Cliffhanger", "State aktif harus Cliffhanger")
	_check(is_equal_approx(mecha.global_position.x, CombatConstants.ARENA_LEFT_BOUND), "Mecha harus disnap ke X = 64 (bibir kiri)")
	_check(mecha.facing_direction == 1, "Mecha di tebing kiri harus menghadap kanan (arah panggung)")
	_check(mecha.cliffhanger_grabs_used == 1, "Penggunaan cliffhanger harus bertambah menjadi 1")

	var ch_state = mecha.state_machine.current_state as CliffhangerState
	_check(ch_state.cliffhanger_timer_frames == 120, "Timer gantung harus 120 frame (2.0 detik)")

	mecha.queue_free()

func _test_max_one_activation_per_round() -> void:
	var mecha = _create_mecha_with_cliffhanger()

	# Aktivasi ke-1
	_check(mecha.trigger_cliffhanger(&"right") == true, "Aktivasi ke-1 harus berhasil")
	mecha.state_machine.change_state(&"Idle")

	# Aktivasi ke-2 pada ronde yang sama (tanpa reset)
	_check(mecha.can_cliffhanger() == false, "can_cliffhanger() harus false setelah 1 kali pemakaian")
	_check(mecha.trigger_cliffhanger(&"right") == false, "Aktivasi ke-2 harus ditolak (maksimal 1 kali per ronde)")

	# Reset ronde
	mecha.reset_cliffhanger()
	_check(mecha.can_cliffhanger() == true, "Setelah reset ronde, can_cliffhanger() harus kembali true")
	_check(mecha.trigger_cliffhanger(&"right") == true, "Setelah reset ronde, trigger_cliffhanger harus kembali berhasil")

	mecha.queue_free()

func _test_climb_up_jump_action() -> void:
	var mecha = _create_mecha_with_cliffhanger()
	mecha.trigger_cliffhanger(&"left")
	var ch_state = mecha.state_machine.current_state as CliffhangerState

	# Input: Climb-Up Jump
	ch_state.simulated_action = &"climb"
	ch_state.physics_update(1.0 / 60.0)
	_check(ch_state.current_action == &"climbing", "Aksi harus berganti ke 'climbing'")

	# Simulasikan 18 frame startup memanjat
	for i in range(18):
		ch_state.physics_update(1.0 / 60.0)

	_check(mecha.state_machine.current_state.name == &"Idle", "Setelah 18 frame memanjat, harus kembali ke IdleState di panggung")
	_check(mecha.global_position.x > CombatConstants.ARENA_LEFT_BOUND, "Posisi mecha harus berpindah masuk ke dalam platform (X > 64)")

	mecha.queue_free()

func _test_ledge_sweep_attack_action() -> void:
	var mecha = _create_mecha_with_cliffhanger()
	mecha.trigger_cliffhanger(&"left")
	var ch_state = mecha.state_machine.current_state as CliffhangerState

	# Input: Ledge Sweep Attack
	ch_state.simulated_action = &"sweep"
	ch_state.physics_update(1.0 / 60.0)
	_check(ch_state.current_action == &"sweeping", "Aksi harus berganti ke 'sweeping'")

	# Simulasikan startup 12 frame
	for i in range(12):
		ch_state.physics_update(1.0 / 60.0)
	_check(mecha.is_hitbox_active(), "Pada frame 12 (active start), hitbox sweep harus aktif")

	# Simulasikan sisa active dan recovery (4 + 16 = 20 frame)
	for i in range(20):
		ch_state.physics_update(1.0 / 60.0)

	_check(mecha.state_machine.current_state.name == &"Idle", "Setelah recovery sweep selesai, mecha harus masuk ke IdleState di atas panggung")

	mecha.queue_free()

func _test_drop_fall_manual_and_timeout() -> void:
	var mecha = _create_mecha_with_cliffhanger()

	# Uji 1: Drop Manual
	mecha.trigger_cliffhanger(&"right")
	var ch_state = mecha.state_machine.current_state as CliffhangerState
	ch_state.simulated_action = &"drop"
	ch_state.physics_update(1.0 / 60.0)
	_check(mecha.state_machine.current_state.name == &"Fall", "Manual drop harus mengalihkan mecha ke FallState")

	# Uji 2: Drop karena Timer Habis (120 frame habis)
	mecha.reset_cliffhanger()
	mecha.trigger_cliffhanger(&"right")
	ch_state = mecha.state_machine.current_state as CliffhangerState
	ch_state.cliffhanger_timer_frames = 1
	ch_state.physics_update(1.0 / 60.0)
	_check(mecha.state_machine.current_state.name == &"Fall", "Timeout (120f habis) harus otomatis mengeksekusi drop dan masuk ke FallState")

	mecha.queue_free()
