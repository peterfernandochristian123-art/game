extends Node

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")
const BaseMecha = preload("res://scripts/characters/base_mecha.gd")
const TitanBulwark = preload("res://scripts/characters/titan_bulwark.gd")
const StateMachine = preload("res://scripts/combat/fsm/state_machine.gd")
const IdleState = preload("res://scripts/combat/fsm/idle_state.gd")
const WalkState = preload("res://scripts/combat/fsm/walk_state.gd")
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
	var out_path: String = ProjectSettings.globalize_path("res://test_titan_bulwark_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 3.3: Titan-V Bulwark...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_base_stats,
		_test_passive_damage_reduction,
		_test_2hit_heavy_impact_resources,
		_test_hydraulic_piledriver_command_grab,
		_test_riot_shield_super_armor,
		_test_orbital_siege_cannon_ultimate,
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

func _create_bulwark() -> TitanBulwark:
	var bulwark := TitanBulwark.new()
	bulwark.name = "TitanBulwark"

	var fsm := StateMachine.new()
	fsm.name = "StateMachine"
	bulwark.add_child(fsm)

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

	var blockstun := BlockstunState.new()
	blockstun.name = "Blockstun"
	fsm.add_child(blockstun)

	add_child(bulwark)
	return bulwark

func _test_base_stats() -> void:
	var bulwark = _create_bulwark()

	_check(bulwark.max_hp == CombatConstants.BULWARK_MAX_HP, "Max HP Bulwark harus 1200")
	_check(bulwark.current_hp == 1200, "Current HP awal harus 1200")
	_check(is_equal_approx(bulwark.walk_speed, CombatConstants.BULWARK_WALK_SPEED), "Walk speed harus 260.0 px/s")
	_check(is_equal_approx(bulwark.get_dash_speed(), CombatConstants.BULWARK_DASH_SPEED), "Dash speed harus 650.0 px/s")
	_check(bulwark.get_dash_duration() == CombatConstants.BULWARK_DASH_DURATION_FRAMES, "Dash duration harus 16 frame")
	_check(is_equal_approx(bulwark.passive_damage_reduction, CombatConstants.BULWARK_PASSIVE_ARMOR_REDUCTION), "Passive armor reduction harus 0.05 (5%)")

	bulwark.queue_free()

func _test_passive_damage_reduction() -> void:
	var bulwark = _create_bulwark()
	var starting_hp: int = bulwark.current_hp

	# Serangan dengan 100 base damage
	var test_atk: Dictionary = {
		"name": &"TestPunch",
		"damage": 100,
		"hitstun": 14,
		"knockback": 100.0
	}

	bulwark.take_hit(null, test_atk)
	# Reduksi pasif 5%: 100 * (1 - 0.05) = 95 damage masuk
	var expected_hp: int = starting_hp - 95
	_check(bulwark.current_hp == expected_hp, "HP setelah 100 damage harus %d (kena 95 damage karena pasif 5%%), aktual: %d" % [expected_hp, bulwark.current_hp])

	bulwark.queue_free()

func _test_2hit_heavy_impact_resources() -> void:
	var bulwark = _create_bulwark()

	var punch = load("res://resources/attacks/bulwark_punch.tres")
	_check(punch != null, "bulwark_punch.tres harus valid")
	if punch:
		_check(punch.startup == 7, "Normal 1 (Punch) startup harus 7f")
		_check(punch.active == 3, "Normal 1 (Punch) active harus 3f")
		_check(punch.recovery == 14, "Normal 1 (Punch) recovery harus 14f")
		_check(punch.damage == 75, "Normal 1 (Punch) damage harus 75")
		_check(punch.chain_level == 1, "Normal 1 chain_level harus 1")

	var slam = load("res://resources/attacks/bulwark_slam.tres")
	_check(slam != null, "bulwark_slam.tres harus valid")
	if slam:
		_check(slam.startup == 14, "Normal 2 (Slam) startup harus 14f")
		_check(slam.active == 4, "Normal 2 (Slam) active harus 4f")
		_check(slam.recovery == 18, "Normal 2 (Slam) recovery harus 18f")
		_check(slam.damage == 120, "Normal 2 (Slam) damage harus 120")
		_check(slam.causes_ground_bounce == true, "Normal 2 (Slam) harus memicu ground bounce")
		_check(slam.causes_wall_bounce == true, "Normal 2 (Slam) harus memicu wall bounce")
		_check(slam.chain_level == 2, "Normal 2 chain_level harus 2")

	bulwark.queue_free()

func _test_hydraulic_piledriver_command_grab() -> void:
	var bulwark = _create_bulwark()

	var grab_res = load("res://resources/attacks/bulwark_piledriver.tres")
	_check(grab_res != null, "bulwark_piledriver.tres harus valid")
	if grab_res:
		_check(grab_res.startup == 6, "Hydraulic Piledriver startup harus 6f")
		_check(grab_res.active == 2, "Hydraulic Piledriver active harus 2f")
		_check(grab_res.recovery == 22, "Hydraulic Piledriver recovery harus 22f")
		_check(grab_res.damage == 220, "Hydraulic Piledriver damage harus 220")
		_check(grab_res.heat_cost == 35.0, "Hydraulic Piledriver heat cost harus +35%")
		_check(grab_res.is_unblockable == true, "Hydraulic Piledriver harus unblockable")
		_check(grab_res.is_grab == true, "Hydraulic Piledriver harus berstatus grab")
		_check(grab_res.chain_level == 3, "Hydraulic Piledriver chain level harus 3 (Skill)")

	# Uji bahwa command grab mengabaikan normal blocking
	var target_dummy := BaseMecha.new()
	target_dummy.name = "TargetDummy"
	var dummy_fsm := StateMachine.new()
	dummy_fsm.name = "StateMachine"
	target_dummy.add_child(dummy_fsm)
	var d_idle := IdleState.new()
	d_idle.name = "Idle"
	dummy_fsm.add_child(d_idle)
	var d_hitstun := HitstunState.new()
	d_hitstun.name = "Hitstun"
	dummy_fsm.add_child(d_hitstun)
	var d_blockstun := BlockstunState.new()
	d_blockstun.name = "Blockstun"
	dummy_fsm.add_child(d_blockstun)
	add_child(target_dummy)

	target_dummy.global_position = Vector2(100.0, 0.0)
	bulwark.global_position = Vector2(50.0, 0.0)
	# Dummy menahan arah menjauh (holding block)
	target_dummy.simulated_horizontal_input = 1.0

	var grab_dict = grab_res.to_dict()
	target_dummy.take_hit(bulwark, grab_dict)

	_check(dummy_fsm.current_state.name == &"Hitstun", "Command grab harus menembus guard dan memaksa HitstunState, bukan BlockstunState")

	target_dummy.queue_free()
	bulwark.queue_free()

func _test_riot_shield_super_armor() -> void:
	var bulwark = _create_bulwark()

	var shield_res = load("res://resources/attacks/bulwark_riot_shield.tres")
	_check(shield_res != null, "bulwark_riot_shield.tres harus valid")
	if shield_res:
		_check(shield_res.startup == 4, "Riot Shield startup harus 4f")
		_check(shield_res.active == 45, "Riot Shield active harus 45f (Full Super Armor window)")
		_check(shield_res.heat_cost == 15.0, "Riot Shield heat cost harus +15%")

	bulwark.execute_riot_shield_deploy()
	_check(bulwark.has_super_armor() == true, "Super armor harus aktif setelah Riot Shield Deploy")
	_check(bulwark.super_armor_frames == CombatConstants.BULWARK_RIOT_SHIELD_DURATION_FRAMES, "Super armor frames harus 45")

	# Serangan fisik non-grab mengenai Bulwark yang sedang super armor
	var strike_hit: Dictionary = {
		"name": &"EnemyStrike",
		"damage": 50,
		"hitstun": 15,
		"is_grab": false
	}
	bulwark.take_hit(null, strike_hit)
	_check(bulwark.state_machine.current_state.name != &"Hitstun", "Super armor harus menyerap hitstun dari serangan biasa (tidak boleh masuk HitstunState)")

	# Serangan grab mengenai Bulwark yang sedang super armor
	var grab_hit: Dictionary = {
		"name": &"EnemyGrab",
		"damage": 100,
		"hitstun": 20,
		"is_grab": true
	}
	bulwark.take_hit(null, grab_hit)
	_check(bulwark.state_machine.current_state.name == &"Hitstun", "Serangan grab harus menembus super armor dan memasukkan mecha ke HitstunState")

	bulwark.queue_free()

func _test_orbital_siege_cannon_ultimate() -> void:
	var bulwark = _create_bulwark()

	var cannon_res = load("res://resources/attacks/bulwark_orbital_cannon.tres")
	_check(cannon_res != null, "bulwark_orbital_cannon.tres harus valid")
	if cannon_res:
		_check(cannon_res.startup == 24, "Orbital Siege Cannon startup harus 24f")
		_check(cannon_res.active == 12, "Orbital Siege Cannon active harus 12f")
		_check(cannon_res.recovery == 30, "Orbital Siege Cannon recovery harus 30f")
		_check(cannon_res.damage == 450, "Orbital Siege Cannon damage harus 450")
		_check(cannon_res.is_energy == true, "Orbital Siege Cannon harus berjenis energi")
		_check(cannon_res.chain_level == 4, "Orbital Siege Cannon chain level harus 4 (Ultimate)")

	# Uji aktivasi tanpa gauge penuh
	bulwark.current_ultimate = 50.0
	_check(bulwark.activate_orbital_siege_cannon() == false, "Ultimate tidak boleh aktif jika meter belum penuh (100.0)")

	# Uji aktivasi saat gauge 100.0
	bulwark.current_ultimate = 100.0
	_check(bulwark.activate_orbital_siege_cannon() == true, "Ultimate harus berhasil aktif saat gauge 100.0")
	_check(bulwark.current_ultimate == 0.0, "Ultimate meter harus terkuras habis ke 0.0 setelah aktivasi")

	bulwark.queue_free()
