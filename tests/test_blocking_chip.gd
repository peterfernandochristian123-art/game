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
const BlockstunState = preload("res://scripts/combat/fsm/blockstun_state.gd")

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
	var out_path: String = ProjectSettings.globalize_path("res://test_blocking_chip_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 2.4: Normal Blocking & Chip Damage...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_constants,
		_test_physical_attack_100_percent_mitigation,
		_test_energy_attack_20_percent_chip_damage,
		_test_block_direction_facing,
		_test_blockstun_duration_and_recovery,
		_test_block_strings,
		_test_cannot_block_during_attack_or_dash,
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

func _create_test_mecha(pos_x: float = 0.0) -> BaseMecha:
	var mecha := BaseMecha.new()
	mecha.name = "TestMecha"
	mecha.global_position = Vector2(pos_x, 0.0)

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

	var blockstun := BlockstunState.new()
	blockstun.name = "Blockstun"
	fsm.add_child(blockstun)

	var dash := DashState.new()
	dash.name = "Dash"
	fsm.add_child(dash)

	add_child(mecha)
	return mecha

func _test_constants() -> void:
	_check(is_equal_approx(CombatConstants.CHIP_DAMAGE_RATIO, 0.20), "CHIP_DAMAGE_RATIO harus 0.20 (20%%)")
	_check(CombatConstants.DEFAULT_BLOCKSTUN_FRAMES == 10, "DEFAULT_BLOCKSTUN_FRAMES harus 10")
	_check(is_equal_approx(CombatConstants.BLOCK_KNOCKBACK_MULTIPLIER, 0.60), "BLOCK_KNOCKBACK_MULTIPLIER harus 0.60")

func _test_physical_attack_100_percent_mitigation() -> void:
	# Attacker di kiri (X=100), Defender di kanan (X=300)
	var attacker = _create_test_mecha(100.0)
	var defender = _create_test_mecha(300.0)

	defender.state_machine.change_state(&"Idle")
	# Holding away dari kiri = tahan kanan (+1.0)
	defender.simulated_horizontal_input = 1.0

	var hit_data = {
		"damage": 80,
		"hitstun": 18,
		"blockstun": 14,
		"knockback": 200.0,
		"is_energy": false
	}
	defender.take_hit(attacker, hit_data)

	_check(defender.current_hp == 1000, "Serangan fisik normal yang diblok harus diredam 100%% (0 damage)")
	_check(defender.state_machine.current_state.name == &"Blockstun", "Defender harus beralih ke BlockstunState")

	var blockstun_node = defender.state_machine.get_node("Blockstun")
	_check(blockstun_node.blockstun_duration == 14, "Durasi blockstun harus 14 frame sesuai hit_data")
	_check(is_equal_approx(defender.velocity.x, 200.0 * 0.60), "Knockback block harus teredam 60%% (120 px/s)")

	attacker.queue_free()
	defender.queue_free()

func _test_energy_attack_20_percent_chip_damage() -> void:
	# Attacker di kiri (X=100), Defender di kanan (X=300)
	var attacker = _create_test_mecha(100.0)
	var defender = _create_test_mecha(300.0)

	defender.state_machine.change_state(&"Idle")
	defender.simulated_horizontal_input = 1.0 # Holding away

	var hit_data = {
		"damage": 100,
		"hitstun": 18,
		"blockstun": 12,
		"knockback": 150.0,
		"is_energy": true
	}
	defender.take_hit(attacker, hit_data)

	_check(defender.current_hp == 980, "Serangan energi 100 damage harus memberikan tepat 20 chip damage (HP sisa 980)")
	_check(defender.state_machine.current_state.name == &"Blockstun", "Defender harus beralih ke BlockstunState")

	attacker.queue_free()
	defender.queue_free()

func _test_block_direction_facing() -> void:
	# Attacker di kiri (X=100), Defender di kanan (X=300)
	var attacker = _create_test_mecha(100.0)
	var defender = _create_test_mecha(300.0)

	defender.state_machine.change_state(&"Idle")

	# Subtest A: Menahan ke arah musuh (kiri / -1.0) -> GAGAL BLOCK
	defender.simulated_horizontal_input = -1.0
	var hit_data = {
		"damage": 50,
		"hitstun": 14,
		"knockback": 100.0,
		"is_energy": false
	}
	defender.take_hit(attacker, hit_data)

	_check(defender.current_hp == 950, "Menahan ke arah musuh tidak memblokir (menerima 50 damage penuh)")
	_check(defender.state_machine.current_state.name == &"Hitstun", "Gagal blok beralih ke HitstunState")

	# Subtest B: Input netral (0.0) -> GAGAL BLOCK
	defender.state_machine.change_state(&"Idle")
	defender.simulated_horizontal_input = 0.0
	defender.take_hit(attacker, hit_data)

	_check(defender.current_hp == 900, "Input netral tanpa menahan mundur tidak memblokir (menerima damage penuh)")
	_check(defender.state_machine.current_state.name == &"Hitstun", "Netral beralih ke HitstunState")

	attacker.queue_free()
	defender.queue_free()

func _test_blockstun_duration_and_recovery() -> void:
	var mecha = _create_test_mecha()
	mecha.state_machine.change_state(&"Blockstun")

	var blockstun_node = mecha.state_machine.get_node("Blockstun")
	blockstun_node.setup_blockstun(10, Vector2(60.0, 0.0))

	# Simulasikan 9 frame: masih harus di Blockstun
	for _i in range(9):
		blockstun_node.physics_update(1.0 / 60.0)
	_check(mecha.state_machine.current_state.name == &"Blockstun", "Pada frame 9 mecha masih di Blockstun")

	# Frame ke-10: mecha harus pulih ke Idle
	blockstun_node.physics_update(1.0 / 60.0)
	_check(mecha.state_machine.current_state.name == &"Idle", "Pada frame ke-10 mecha harus pulih ke IdleState")

	mecha.queue_free()

func _test_block_strings() -> void:
	var attacker = _create_test_mecha(100.0)
	var defender = _create_test_mecha(300.0)

	defender.state_machine.change_state(&"Idle")
	defender.simulated_horizontal_input = 1.0 # Holding away

	# Hit 1
	var hit1 = {"damage": 40, "hitstun": 10, "blockstun": 10, "knockback": 80.0, "is_energy": false}
	defender.take_hit(attacker, hit1)
	_check(defender.state_machine.current_state.name == &"Blockstun", "Hit 1 membawa defender ke Blockstun")
	_check(defender.current_hp == 1000, "Hit 1 diredam 100%%")

	# Hit 2 (Block-String saat masih di Blockstun)
	var hit2 = {"damage": 50, "hitstun": 12, "blockstun": 12, "knockback": 90.0, "is_energy": false}
	defender.take_hit(attacker, hit2)
	_check(defender.state_machine.current_state.name == &"Blockstun", "Hit 2 mempertahankan status Blockstun")
	_check(defender.current_hp == 1000, "Hit 2 tetap diredam 100%% saat block-string")

	attacker.queue_free()
	defender.queue_free()

func _test_cannot_block_during_attack_or_dash() -> void:
	var attacker = _create_test_mecha(100.0)
	var defender = _create_test_mecha(300.0)

	defender.simulated_horizontal_input = 1.0 # Holding away

	# Subtest A: Saat sedang Attack
	defender.state_machine.change_state(&"Attack")
	var hit = {"damage": 70, "hitstun": 14, "blockstun": 10, "knockback": 100.0, "is_energy": false}
	defender.take_hit(attacker, hit)
	_check(defender.current_hp == 930, "Tidak dapat memblokir saat sedang melancarkan serangan (menerima damage)")
	_check(defender.state_machine.current_state.name == &"Hitstun", "Beralih ke HitstunState")

	# Subtest B: Saat sedang Dash
	defender.state_machine.change_state(&"Dash")
	defender.take_hit(attacker, hit)
	_check(defender.current_hp == 860, "Tidak dapat memblokir saat sedang Dash (menerima damage)")
	_check(defender.state_machine.current_state.name == &"Hitstun", "Beralih ke HitstunState")

	attacker.queue_free()
	defender.queue_free()
