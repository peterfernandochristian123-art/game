extends Node

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")
const BaseMecha = preload("res://scripts/characters/base_mecha.gd")
const StateMachine = preload("res://scripts/combat/fsm/state_machine.gd")
const IdleState = preload("res://scripts/combat/fsm/idle_state.gd")
const WalkState = preload("res://scripts/combat/fsm/walk_state.gd")
const AttackState = preload("res://scripts/combat/fsm/attack_state.gd")
const HitstunState = preload("res://scripts/combat/fsm/hitstun_state.gd")
const AttackData = preload("res://scripts/combat/resources/attack_data.gd")

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
	var out_path: String = ProjectSettings.globalize_path("res://test_attack_chain_scaling_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 3.1: Attack Architecture & Target Chain...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_attack_data_resource,
		_test_damage_scaling_formula,
		_test_target_chain_cancel_flow,
		_test_combo_scaling_in_take_hit,
		_test_bounce_limits_per_combo,
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

	add_child(mecha)
	return mecha

func _test_attack_data_resource() -> void:
	var light_res = load("res://resources/attacks/normal_light.tres") as AttackData
	_check(light_res != null, "normal_light.tres harus berhasil dimuat")
	_check(light_res.attack_name == &"5L", "5L name harus 5L")
	_check(light_res.chain_level == 1, "5L chain_level harus 1")
	_check(light_res.damage == 40, "5L damage harus 40")

	var heavy_res = load("res://resources/attacks/normal_heavy.tres") as AttackData
	_check(heavy_res != null, "normal_heavy.tres harus berhasil dimuat")
	_check(heavy_res.attack_name == &"5H", "5H name harus 5H")
	_check(heavy_res.chain_level == 2, "5H chain_level harus 2")
	_check(heavy_res.causes_ground_bounce == true, "5H causes_ground_bounce harus true")

	var skill_res = load("res://resources/attacks/skill_slash.tres") as AttackData
	_check(skill_res != null, "skill_slash.tres harus berhasil dimuat")
	_check(skill_res.chain_level == 3, "Skill chain_level harus 3")
	_check(is_equal_approx(skill_res.heat_cost, 25.0), "Skill heat_cost harus 25.0")
	_check(skill_res.is_energy == true, "Skill is_energy harus true")

	# Test to_dict & from_dict
	var d = skill_res.to_dict()
	_check(d.get("name") == &"Skill1" and d.get("damage") == 120, "to_dict harus menghasilkan dictionary valid")
	var reconstructed = AttackData.from_dict(d)
	_check(reconstructed.attack_name == skill_res.attack_name and reconstructed.damage == skill_res.damage, "from_dict harus merekonstruksi resource")

func _test_damage_scaling_formula() -> void:
	# Hit 1 = 100%
	_check(CombatConstants.calculate_combo_damage(100, 1) == 100, "Hit 1 scaling harus 100%")
	# Hit 2 = 85%
	_check(CombatConstants.calculate_combo_damage(100, 2) == 85, "Hit 2 scaling harus 85%")
	# Hit 3 = 70%
	_check(CombatConstants.calculate_combo_damage(100, 3) == 70, "Hit 3 scaling harus 70%")
	# Hit 4 = 60%
	_check(CombatConstants.calculate_combo_damage(100, 4) == 60, "Hit 4 scaling harus 60%")
	# Hit 5 = 50%
	_check(CombatConstants.calculate_combo_damage(100, 5) == 50, "Hit 5 scaling harus 50%")
	# Hit 6 = 40%
	_check(CombatConstants.calculate_combo_damage(100, 6) == 40, "Hit 6 scaling harus 40%")
	# Hit 7 = 30%
	_check(CombatConstants.calculate_combo_damage(100, 7) == 30, "Hit 7 scaling harus 30%")
	# Hit 8+ = minimum floor 25%
	_check(CombatConstants.calculate_combo_damage(100, 8) == 25, "Hit 8 scaling harus floor 25%")
	_check(CombatConstants.calculate_combo_damage(100, 15) == 25, "Hit 15 scaling tetap pada floor 25%")

func _test_target_chain_cancel_flow() -> void:
	var mecha = _create_test_mecha()
	var victim = _create_test_mecha()

	var light_res = load("res://resources/attacks/normal_light.tres") as AttackData
	mecha.request_attack(light_res)
	var atk_state = mecha.state_machine.get_node("Attack")

	_check(atk_state.can_chain_cancel == false, "Sebelum hit confirmed tidak bisa chain cancel")

	# Target terkena pukulan
	atk_state.register_hit_target(victim)
	_check(atk_state.can_chain_cancel == true, "Setelah hit confirmed bisa chain cancel")

	# Simulasikan cancel ke 5H (Normal 2)
	mecha.request_attack_by_name(&"5H")
	_check(atk_state.current_attack_data.get("name") == &"5H", "Berhasil chain cancel dari 5L ke 5H")
	_check(atk_state.current_attack_data.get("chain_level") == 2, "Chain level naik ke 2")

	# Simulasikan hit confirmed pada 5H dan cancel ke Skill1
	atk_state.register_hit_target(victim)
	mecha.request_attack_by_name(&"Skill1")
	_check(atk_state.current_attack_data.get("name") == &"Skill1", "Berhasil chain cancel dari 5H ke Skill1")
	_check(atk_state.current_attack_data.get("chain_level") == 3, "Chain level naik ke 3")

	mecha.queue_free()
	victim.queue_free()

func _test_combo_scaling_in_take_hit() -> void:
	var attacker = _create_test_mecha()
	var defender = _create_test_mecha()

	defender.current_hp = 1000

	# Hit 1: 100 damage (Scaling 100% -> 100 dmg)
	var hit1 = {"damage": 100, "hitstun": 14}
	defender.take_hit(attacker, hit1)
	_check(defender.combo_hit_count == 1, "Hit 1 combo_hit_count harus 1")
	_check(defender.current_hp == 900, "Hit 1 HP harus 900 (-100 dmg)")
	_check(defender.state_machine.current_state.name == &"Hitstun", "Defender masuk Hitstun")

	# Hit 2: 100 damage (Scaling 85% -> 85 dmg)
	var hit2 = {"damage": 100, "hitstun": 14}
	defender.take_hit(attacker, hit2)
	_check(defender.combo_hit_count == 2, "Hit 2 combo_hit_count harus 2")
	_check(defender.current_hp == 815, "Hit 2 HP harus 815 (-85 dmg)")

	# Hit 3: 100 damage (Scaling 70% -> 70 dmg)
	var hit3 = {"damage": 100, "hitstun": 14}
	defender.take_hit(attacker, hit3)
	_check(defender.combo_hit_count == 3, "Hit 3 combo_hit_count harus 3")
	_check(defender.current_hp == 745, "Hit 3 HP harus 745 (-70 dmg)")

	# Hit 4: 100 damage (Scaling 60% -> 60 dmg)
	var hit4 = {"damage": 100, "hitstun": 14}
	defender.take_hit(attacker, hit4)
	_check(defender.combo_hit_count == 4, "Hit 4 combo_hit_count harus 4")
	_check(defender.current_hp == 685, "Hit 4 HP harus 685 (-60 dmg)")

	# Reset combo (defender pulih ke Idle)
	defender.state_machine.change_state(&"Idle")
	defender.reset_combo_state()

	# Hit baru setelah reset -> mulai lagi dari Hit 1 (100% scaling)
	var hit_fresh = {"damage": 100, "hitstun": 14}
	defender.take_hit(attacker, hit_fresh)
	_check(defender.combo_hit_count == 1, "Kombo baru setelah reset harus mulai dari Hit 1")
	_check(defender.current_hp == 585, "Kombo baru menerima full 100 damage (-100 dmg)")

	attacker.queue_free()
	defender.queue_free()

func _test_bounce_limits_per_combo() -> void:
	var attacker = _create_test_mecha()
	var defender = _create_test_mecha()

	# Serangan dengan ground bounce
	var hit_gb = {"damage": 50, "hitstun": 14, "causes_ground_bounce": true}

	# Hit 1: Ground bounce pertama diterima
	defender.take_hit(attacker, hit_gb)
	_check(defender.ground_bounce_count == 1, "Ground bounce pertama diizinkan (count = 1)")

	# Hit 2 dalam kombo yang sama dengan ground bounce
	defender.take_hit(attacker, hit_gb)
	_check(defender.ground_bounce_count == 1, "Ground bounce kedua dalam kombo yang sama dibatasi (tetap count = 1)")

	# Reset kombo
	defender.reset_combo_state()
	_check(defender.ground_bounce_count == 0, "Reset kombo mengembalikan hitungan bounce ke 0")

	attacker.queue_free()
	defender.queue_free()
