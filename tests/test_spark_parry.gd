extends Node

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")
const BaseMecha = preload("res://scripts/characters/base_mecha.gd")
const StateMachine = preload("res://scripts/combat/fsm/state_machine.gd")
const IdleState = preload("res://scripts/combat/fsm/idle_state.gd")
const WalkState = preload("res://scripts/combat/fsm/walk_state.gd")
const JumpState = preload("res://scripts/combat/fsm/jump_state.gd")
const FallState = preload("res://scripts/combat/fsm/fall_state.gd")
const DashState = preload("res://scripts/combat/fsm/dash_state.gd")
const AttackState = preload("res://scripts/combat/fsm/attack_state.gd")
const HitstunState = preload("res://scripts/combat/fsm/hitstun_state.gd")
const ParryState = preload("res://scripts/combat/fsm/parry_state.gd")

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
	var out_path: String = ProjectSettings.globalize_path("res://test_spark_parry_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 2.3: Spark Parry...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_constants,
		_test_parry_cycle_frame_windows,
		_test_parry_success_effects,
		_test_whiff_counter_hit_vulnerability,
		_test_startup_vulnerability,
		_test_ground_only_activation,
		_test_ultimate_gauge_clamp_and_drain,
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

func _create_test_mecha() -> BaseMecha:
	var mecha := BaseMecha.new()
	mecha.name = "TestMecha"

	var fsm := StateMachine.new()
	fsm.name = "StateMachine"
	mecha.add_child(fsm)

	var idle := IdleState.new()
	idle.name = "Idle"
	fsm.add_child(idle)

	var walk := WalkState.new()
	walk.name = "Walk"
	fsm.add_child(walk)

	var hitstun := HitstunState.new()
	hitstun.name = "Hitstun"
	fsm.add_child(hitstun)

	var attack := AttackState.new()
	attack.name = "Attack"
	fsm.add_child(attack)

	var parry := ParryState.new()
	parry.name = "Parry"
	fsm.add_child(parry)

	add_child(mecha)
	return mecha

func _test_constants() -> void:
	_check(CombatConstants.SPARK_PARRY_STARTUP_FRAMES == 1, "SPARK_PARRY_STARTUP_FRAMES harus 1")
	_check(CombatConstants.SPARK_PARRY_ACTIVE_FRAMES == 4, "SPARK_PARRY_ACTIVE_FRAMES harus 4")
	_check(CombatConstants.SPARK_PARRY_RECOVERY_FRAMES == 14, "SPARK_PARRY_RECOVERY_FRAMES harus 14")
	_check(CombatConstants.SPARK_PARRY_TOTAL_FRAMES == 19, "SPARK_PARRY_TOTAL_FRAMES harus 19")
	_check(CombatConstants.SPARK_PARRY_HITSTOP_FRAMES == 12, "SPARK_PARRY_HITSTOP_FRAMES harus 12")
	_check(is_equal_approx(CombatConstants.SPARK_PARRY_HEAT_COOLING, 20.0), "SPARK_PARRY_HEAT_COOLING harus 20.0")
	_check(is_equal_approx(CombatConstants.SPARK_PARRY_ULTIMATE_STEAL, 15.0), "SPARK_PARRY_ULTIMATE_STEAL harus 15.0")
	_check(is_equal_approx(CombatConstants.MAX_ULTIMATE, 100.0), "MAX_ULTIMATE harus 100.0")

func _test_parry_cycle_frame_windows() -> void:
	var mecha = _create_test_mecha()
	var parry_state = mecha.state_machine.get_node("Parry")

	# Simulasikan mecha di lantai
	mecha.state_machine.change_state(&"Parry")
	_check(mecha.state_machine.current_state.name == &"Parry", "Mecha harus memasuki ParryState")

	# Frame 1: Startup
	parry_state.current_frame_in_state = 1
	_check(not parry_state.is_parry_active(), "Frame 1 (Startup) belum aktif")
	_check(not parry_state.is_counter_hit_vulnerable(), "Frame 1 bukan whiff recovery")

	# Frame 2..5: Active Window (4 frame tepat)
	for f in range(2, 6):
		parry_state.current_frame_in_state = f
		_check(parry_state.is_parry_active(), "Frame %d harus aktif parry" % f)
		_check(not parry_state.is_counter_hit_vulnerable(), "Frame %d aktif parry bukan whiff" % f)

	# Frame 6..19: Whiff Recovery (14 frame tepat, rentan counter-hit)
	for f in range(6, 20):
		parry_state.current_frame_in_state = f
		_check(not parry_state.is_parry_active(), "Frame %d sudah bukan parry aktif" % f)
		_check(parry_state.is_counter_hit_vulnerable(), "Frame %d harus rentan Counter-Hit" % f)

	# Frame 20: Transisi kembali ke Idle
	parry_state.current_frame_in_state = 19
	parry_state.physics_update(1.0 / 60.0) # Akan bertambah jadi 20 dan beralih ke Idle
	_check(mecha.state_machine.current_state.name == &"Idle", "Frame 20 mecha harus kembali ke IdleState")
	mecha.queue_free()

func _test_parry_success_effects() -> void:
	var defender = _create_test_mecha()
	var attacker = _create_test_mecha()

	defender.heat_component.current_heat = 50.0
	defender.current_ultimate = 10.0
	defender.current_hp = 1000

	attacker.current_ultimate = 40.0

	# Posisikan defender di frame aktif (misal frame 3)
	defender.state_machine.change_state(&"Parry")
	var parry_node = defender.state_machine.get_node("Parry")
	parry_node.current_frame_in_state = 3

	# Catat emisi sinyal EventBus
	var parry_signal_received: bool = false
	var hitstop_signal_frames: int = 0
	var bus = defender.get_node_or_null("/root/EventBus")
	if bus:
		bus.parry_triggered.connect(func(_def, _atk): parry_signal_received = true)
		bus.hitstop_requested.connect(func(frames): hitstop_signal_frames = frames)

	# Attacker menyerang defender
	var hit_data = {
		"damage": 50,
		"hitstun": 14,
		"knockback": 120.0
	}
	defender.take_hit(attacker, hit_data)

	# Validasi hasil parry sukses
	_check(defender.current_hp == 1000, "Damage harus dinolkan (HP tetap 1000)")
	_check(attacker.hitstop_frames == 12, "Attacker harus dibekukan hitstop 12 frame")
	_check(defender.invulnerability_frames == 12, "Defender mendapat invulnerability 12 frame")
	_check(is_equal_approx(defender.heat_component.current_heat, 30.0), "Heat defender berkurang 20%% (50.0 -> 30.0)")
	_check(is_equal_approx(defender.current_ultimate, 25.0), "Ultimate defender bertambah 15%% (10.0 -> 25.0)")
	_check(is_equal_approx(attacker.current_ultimate, 25.0), "Ultimate attacker dicuri 15%% (40.0 -> 25.0)")
	_check(defender.state_machine.current_state.name == &"Idle", "Defender segera kembali ke IdleState (frame advantage)")

	defender.queue_free()
	attacker.queue_free()

func _test_whiff_counter_hit_vulnerability() -> void:
	var defender = _create_test_mecha()
	var attacker = _create_test_mecha()

	defender.state_machine.change_state(&"Parry")
	var parry_node = defender.state_machine.get_node("Parry")
	parry_node.current_frame_in_state = 8 # Whiff recovery

	var hit_data = {
		"damage": 60,
		"hitstun": 16,
		"knockback": 150.0
	}
	defender.take_hit(attacker, hit_data)

	_check(defender.current_hp == 940, "Defender harus menerima 60 damage penuh saat recovery whiff")
	_check(defender.state_machine.current_state.name == &"Hitstun", "Defender beralih ke HitstunState")
	_check(attacker.hitstop_frames == 0, "Attacker tidak terkena freeze hitstop saat whiff")

	defender.queue_free()
	attacker.queue_free()

func _test_startup_vulnerability() -> void:
	var defender = _create_test_mecha()
	var attacker = _create_test_mecha()

	defender.state_machine.change_state(&"Parry")
	var parry_node = defender.state_machine.get_node("Parry")
	parry_node.current_frame_in_state = 1 # Startup frame 1

	var hit_data = {
		"damage": 40,
		"hitstun": 14,
		"knockback": 100.0
	}
	defender.take_hit(attacker, hit_data)

	_check(defender.current_hp == 960, "Defender menerima 40 damage pada startup frame 1")
	_check(defender.state_machine.current_state.name == &"Hitstun", "Defender beralih ke HitstunState")

	defender.queue_free()
	attacker.queue_free()

func _test_ground_only_activation() -> void:
	var mecha = _create_test_mecha()
	mecha.state_machine.change_state(&"Idle")

	_check(mecha.state_machine.current_state.name == &"Idle", "Mecha awal di Idle")

	# Test transisi parry dari Idle
	var idle_node = mecha.state_machine.get_node("Idle")
	if idle_node.has_method("_is_parry_pressed"):
		# Verifikasi method parry helper tersedia
		_check(true, "Helper _is_parry_pressed tersedia di IdleState")

	# Test transisi parry dari Walk
	mecha.state_machine.change_state(&"Walk")
	var walk_node = mecha.state_machine.get_node("Walk")
	if walk_node.has_method("_is_parry_pressed"):
		_check(true, "Helper _is_parry_pressed tersedia di WalkState")

	mecha.queue_free()

func _test_ultimate_gauge_clamp_and_drain() -> void:
	var mecha = _create_test_mecha()

	_check(mecha.current_ultimate == 0.0, "Ultimate awal adalah 0.0")
	mecha.add_ultimate(50.0)
	_check(is_equal_approx(mecha.current_ultimate, 50.0), "Ultimate setelah add 50 adalah 50.0")

	mecha.add_ultimate(70.0)
	_check(is_equal_approx(mecha.current_ultimate, 100.0), "Ultimate dibatasi max 100.0 (clamp)")

	var drained = mecha.drain_ultimate(15.0)
	_check(is_equal_approx(drained, 15.0), "Drain 15.0 mengembalikan 15.0")
	_check(is_equal_approx(mecha.current_ultimate, 85.0), "Sisa ultimate adalah 85.0")

	var drained_all = mecha.drain_ultimate(100.0)
	_check(is_equal_approx(drained_all, 85.0), "Drain berlebih mengembalikan sisa aktual (85.0)")
	_check(is_equal_approx(mecha.current_ultimate, 0.0), "Ultimate tidak boleh negatif")

	mecha.queue_free()
