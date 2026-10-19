extends Node

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")
const BaseMecha = preload("res://scripts/characters/base_mecha.gd")
const ApexViper = preload("res://scripts/characters/apex_viper.gd")
const StateMachine = preload("res://scripts/combat/fsm/state_machine.gd")
const IdleState = preload("res://scripts/combat/fsm/idle_state.gd")
const WalkState = preload("res://scripts/combat/fsm/walk_state.gd")
const AttackState = preload("res://scripts/combat/fsm/attack_state.gd")
const HitstunState = preload("res://scripts/combat/fsm/hitstun_state.gd")

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
	var out_path: String = ProjectSettings.globalize_path("res://test_apex_viper_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 3.2: Apex-0 Viper...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_base_stats,
		_test_rapier_combo_resources,
		_test_blink_slash,
		_test_deflection_matrix,
		_test_absolute_zero_protocol,
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

func _create_viper() -> ApexViper:
	var viper := ApexViper.new()
	viper.name = "ApexViper"

	var fsm := StateMachine.new()
	fsm.name = "StateMachine"
	viper.add_child(fsm)

	var idle := IdleState.new()
	idle.name = "Idle"
	fsm.add_child(idle)

	var walk := WalkState.new()
	walk.name = "Walk"
	fsm.add_child(walk)

	var attack := AttackState.new()
	attack.name = "Attack"
	fsm.add_child(attack)

	var hitstun := HitstunState.new()
	hitstun.name = "Hitstun"
	fsm.add_child(hitstun)

	add_child(viper)
	return viper

func _test_base_stats() -> void:
	var viper = _create_viper()

	_check(viper.max_hp == CombatConstants.VIPER_MAX_HP, "Max HP Viper harus 900")
	_check(viper.current_hp == 900, "Current HP awal harus 900")
	_check(is_equal_approx(viper.walk_speed, CombatConstants.VIPER_WALK_SPEED), "Walk speed harus 350.0 px/s")
	_check(is_equal_approx(viper.get_dash_speed(), CombatConstants.VIPER_DASH_SPEED), "Dash speed normal harus 820.0 px/s")
	_check(viper.get_dash_duration() == CombatConstants.VIPER_DASH_DURATION_FRAMES, "Dash duration harus 12 frame")

	viper.queue_free()

func _test_rapier_combo_resources() -> void:
	var viper = _create_viper()

	var jab = load("res://resources/attacks/viper_jab.tres")
	_check(jab != null and jab.startup == 3 and jab.chain_level == 1, "5L1 Jab: Startup 3f, Chain 1")

	var thrust = load("res://resources/attacks/viper_thrust.tres")
	_check(thrust != null and thrust.startup == 6 and thrust.chain_level == 2, "5L2 Thrust: Startup 6f, Chain 2")

	var cleave = load("res://resources/attacks/viper_cleave.tres")
	_check(cleave != null and cleave.startup == 11 and cleave.chain_level == 3, "5H Cleave: Startup 11f, Chain 3")

	# Uji request 3-hit string
	viper.request_attack_by_name(&"5L1")
	var atk_state = viper.state_machine.get_node("Attack")
	_check(atk_state.current_attack_data.get("name") == &"5L1", "Attack state masuk ke 5L1")

	# Simulasikan hit connect dan chain cancel ke 5L2
	var dummy = BaseMecha.new()
	add_child(dummy)
	atk_state.register_hit_target(dummy)
	viper.request_attack_by_name(&"5L2")
	_check(atk_state.current_attack_data.get("name") == &"5L2", "Chain cancel ke 5L2 berhasil")

	# Simulasikan hit connect dan chain cancel ke 5H
	atk_state.register_hit_target(dummy)
	viper.request_attack_by_name(&"5H")
	_check(atk_state.current_attack_data.get("name") == &"5H", "Chain cancel ke 5H berhasil")

	dummy.queue_free()
	viper.queue_free()

func _test_blink_slash() -> void:
	var viper = _create_viper()
	viper.global_position = Vector2(100.0, 0.0)
	viper.facing_direction = 1

	var opponent = BaseMecha.new()
	opponent.global_position = Vector2(300.0, 0.0)
	add_child(opponent)

	_check(viper.heat_component.current_heat == 0.0, "Heat awal adalah 0%")

	viper.execute_blink_slash(opponent)

	# Viper harus teleport ke belakang opponent (X > 300) dan berbalik arah (facing = -1)
	_check(viper.global_position.x > 300.0, "Viper teleport ke belakang opponent (X=%.1f > 300)" % viper.global_position.x)
	_check(viper.facing_direction == -1, "Viper berbalik arah hadap ke lawan (-1)")
	_check(is_equal_approx(viper.heat_component.current_heat, 25.0), "Blink slash menambah +25% Heat (25.0%)")

	opponent.queue_free()
	viper.queue_free()

func _test_deflection_matrix() -> void:
	var viper = _create_viper()

	_check(viper.deflection_matrix_frames == 0, "Deflection matrix awal 0")
	viper.execute_deflection_matrix()

	_check(viper.deflection_matrix_frames == CombatConstants.VIPER_DEFLECTION_DURATION_FRAMES, "Matrix aktif 30 frame")
	_check(is_equal_approx(viper.heat_component.current_heat, 20.0), "Deflection matrix menambah +20% Heat")

	viper.queue_free()

func _test_absolute_zero_protocol() -> void:
	var viper = _create_viper()

	# Coba aktivasi tanpa ultimate penuh -> harus gagal
	viper.current_ultimate = 50.0
	_check(not viper.activate_absolute_zero_protocol(), "Tidak bisa aktivasi tanpa 100% Ultimate")

	# Beri 100% ultimate dan sedikit heat
	viper.current_ultimate = 100.0
	viper.heat_component.current_heat = 60.0

	var ok = viper.activate_absolute_zero_protocol()
	_check(ok, "Aktivasi Absolute Zero Protocol berhasil")
	_check(viper.is_cryogenic_active(), "Mode kriogenik aktif")
	_check(viper.cryogenic_frames_left == 480, "Durasi cryogenic 480 frame (8 detik)")
	_check(viper.heat_component.current_heat == 0.0, "Suhu seketika direset ke 0.0%")
	_check(is_equal_approx(viper.get_dash_speed(), 820.0 * 1.30), "Kecepatan dash meningkat +30% (1066.0 px/s)")

	# Uji penambahan heat selama mode cryogenic -> harus tetap 0%
	viper.add_heat(30.0)
	_check(viper.heat_component.current_heat == 0.0, "Panas terkunci pada 0% selama Absolute Zero")

	# Uji unlimited air dash
	viper.can_air_dash = false
	viper._physics_process(1.0 / 60.0)
	_check(viper.can_air_dash == true, "Air dash otomatis direset/tak terbatas selama mode cryogenic")

	# Simulasikan habisnya durasi
	viper.cryogenic_frames_left = 1
	viper._physics_process(1.0 / 60.0)
	_check(not viper.is_cryogenic_active(), "Mode cryogenic berakhir setelah durasi frame habis")
	_check(is_equal_approx(viper.get_dash_speed(), 820.0), "Kecepatan dash kembali normal (820 px/s)")

	viper.queue_free()
