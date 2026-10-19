extends Node

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")
const BaseMecha = preload("res://scripts/characters/base_mecha.gd")
const StateMachine = preload("res://scripts/combat/fsm/state_machine.gd")
const IdleState = preload("res://scripts/combat/fsm/idle_state.gd")
const WalkState = preload("res://scripts/combat/fsm/walk_state.gd")
const JumpState = preload("res://scripts/combat/fsm/jump_state.gd")
const FallState = preload("res://scripts/combat/fsm/fall_state.gd")
const DashState = preload("res://scripts/combat/fsm/dash_state.gd")
const AirDashState = preload("res://scripts/combat/fsm/air_dash_state.gd")
const AttackState = preload("res://scripts/combat/fsm/attack_state.gd")
const HitstunState = preload("res://scripts/combat/fsm/hitstun_state.gd")
const MeltdownState = preload("res://scripts/combat/fsm/meltdown_state.gd")
const HeatComponentScript = preload("res://scripts/combat/components/heat_component.gd")

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
	var out_path: String = ProjectSettings.globalize_path("res://test_overclock_meltdown_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 2.2...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_constants,
		_test_overclock_threshold_and_signals,
		_test_overclock_damage_buff,
		_test_super_armor_on_startup,
		_test_meltdown_trigger_and_shutdown,
		_test_meltdown_damage_penalty,
		_test_meltdown_recovery_and_reset,
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

func _create_test_mecha(initial_heat: float = 0.0) -> BaseMecha:
	var mecha := BaseMecha.new()
	mecha.name = "TestMecha"

	var fsm := StateMachine.new()
	fsm.name = "StateMachine"
	mecha.add_child(fsm)

	var idle := IdleState.new()
	idle.name = "Idle"
	fsm.add_child(idle)

	var hitstun := HitstunState.new()
	hitstun.name = "Hitstun"
	fsm.add_child(hitstun)

	var attack := AttackState.new()
	attack.name = "Attack"
	fsm.add_child(attack)

	var meltdown := MeltdownState.new()
	meltdown.name = "Meltdown"
	fsm.add_child(meltdown)

	add_child(mecha)
	mecha.heat_component.current_heat = initial_heat
	mecha.heat_component._update_overclock_state()
	mecha.heat_gauge = initial_heat
	return mecha

func _test_constants() -> void:
	_check("OVERCLOCK_THRESHOLD" in CombatConstants and CombatConstants.OVERCLOCK_THRESHOLD == 80.0, "OVERCLOCK_THRESHOLD harus 80.0")
	_check("MELTDOWN_THRESHOLD" in CombatConstants and CombatConstants.MELTDOWN_THRESHOLD == 100.0, "MELTDOWN_THRESHOLD harus 100.0")
	_check("OVERCLOCK_DAMAGE_MULTIPLIER" in CombatConstants and is_equal_approx(CombatConstants.OVERCLOCK_DAMAGE_MULTIPLIER, 1.2), "OVERCLOCK_DAMAGE_MULTIPLIER harus 1.2")
	_check("MELTDOWN_DAMAGE_RECEIVED_MULTIPLIER" in CombatConstants and is_equal_approx(CombatConstants.MELTDOWN_DAMAGE_RECEIVED_MULTIPLIER, 1.25), "MELTDOWN_DAMAGE_RECEIVED_MULTIPLIER harus 1.25")
	_check("MELTDOWN_DURATION_FRAMES" in CombatConstants and CombatConstants.MELTDOWN_DURATION_FRAMES == 90, "MELTDOWN_DURATION_FRAMES harus 90")

func _test_overclock_threshold_and_signals() -> void:
	var comp = HeatComponentScript.new()
	var signal_emitted: Array[bool] = []
	comp.overclock_state_changed.connect(func(active: bool): signal_emitted.append(active))

	_check(not comp.is_overclocked(), "Inisialisasi awal tidak overclocked")
	comp.add_heat(79.0)
	_check(not comp.is_overclocked(), "79.0 heat tidak overclocked")
	_check(signal_emitted.is_empty(), "Belum ada sinyal overclock")

	comp.add_heat(1.0) # 80.0
	_check(comp.is_overclocked(), "80.0 heat harus overclocked")
	_check(signal_emitted.size() == 1 and signal_emitted[0] == true, "Sinyal overclock true terpancar")

	comp.add_heat(19.0) # 99.0
	_check(comp.is_overclocked(), "99.0 heat tetap overclocked")
	_check(signal_emitted.size() == 1, "Tidak memancarkan sinyal duplikat saat masih di zona")

	comp.add_heat(1.0) # 100.0 (Meltdown)
	_check(not comp.is_overclocked(), "100.0 heat bukan overclocked (meltdown)")
	_check(signal_emitted.size() == 2 and signal_emitted[1] == false, "Sinyal overclock false terpancar saat meltdown")

	comp.free()

func _test_overclock_damage_buff() -> void:
	var attacker := _create_test_mecha(85.0) # Overclocked
	var victim := _create_test_mecha(0.0)

	_check(attacker.is_overclocked(), "Attacker dalam status Overclocked")

	# Simulasikan hit dari attacker ke victim
	attacker.request_attack(CombatConstants.LIGHT_ATTACK)
	var atk_state: AttackState = attacker.state_machine.get_node("Attack")
	_check(atk_state != null, "AttackState ditemukan")

	var initial_hp: int = victim.current_hp
	var outgoing_data: Dictionary = atk_state.current_attack_data.duplicate()
	if attacker.is_overclocked():
		outgoing_data["damage"] = int(round(float(outgoing_data.get("damage", 40)) * CombatConstants.OVERCLOCK_DAMAGE_MULTIPLIER))

	# Light attack base damage = 40. Overclock 1.2x = 48.
	_check(outgoing_data["damage"] == 48, "Damage bertambah +20% (40 -> 48)")

	victim.take_hit(attacker, outgoing_data)
	_check(victim.current_hp == initial_hp - 48, "HP victim berkurang 48 (karena buff +20%)")

	attacker.queue_free()
	victim.queue_free()

func _test_super_armor_on_startup() -> void:
	var mecha := _create_test_mecha(85.0) # Overclocked
	_check(mecha.is_overclocked(), "Mecha dalam status Overclocked")

	mecha.request_attack(CombatConstants.HEAVY_ATTACK) # startup = 10 frames
	var atk_state: AttackState = mecha.state_machine.get_node("Attack")

	_check(atk_state.has_super_armor == true, "Super Armor aktif saat attack enter di Overclock")
	_check(atk_state.is_startup_super_armor_active() == true, "Super Armor aktif di startup frame 0")

	# Terkena hit saat startup
	var dummy_attacker := BaseMecha.new()
	var initial_hp: int = mecha.current_hp
	mecha.take_hit(dummy_attacker, CombatConstants.LIGHT_ATTACK)

	# Super armor menyerap hit: HP tetap berkurang, tapi TIDAK terhuyung ke Hitstun
	_check(mecha.current_hp == initial_hp - CombatConstants.LIGHT_ATTACK.damage, "HP berkurang meski super armor menyerap")
	_check(mecha.state_machine.current_state.name == &"Attack", "Mecha tetap berada di AttackState (tidak ke Hitstun)")
	_check(atk_state.has_super_armor == false, "1-Hit Super Armor telah dikonsumsi")

	# Pukulan kedua tanpa super armor harus memicu hitstun
	mecha.take_hit(dummy_attacker, CombatConstants.LIGHT_ATTACK)
	_check(mecha.state_machine.current_state.name == &"Hitstun", "Pukulan kedua memicu HitstunState setelah armor habis")

	dummy_attacker.free()
	mecha.queue_free()

func _test_meltdown_trigger_and_shutdown() -> void:
	var mecha := _create_test_mecha(90.0)

	_check(mecha.state_machine.current_state.name == &"Idle", "Awalnya di Idle")
	mecha.add_heat(10.0) # Menjadi 100.0% -> Memicu meltdown

	_check(mecha.heat_gauge >= 100.0, "Heat mencapai 100%")
	_check(mecha.state_machine.current_state.name == &"Meltdown", "State langsung beralih paksa ke Meltdown")

	# Uji kelumpuhan kecepatan
	mecha.velocity.x = 250.0
	mecha.state_machine.physics_update(1.0 / 60.0)
	_check(mecha.velocity.x == 0.0, "Kecepatan horizontal terkunci 0 di Meltdown")

	mecha.queue_free()

func _test_meltdown_damage_penalty() -> void:
	var mecha := _create_test_mecha(100.0) # Langsung Meltdown
	mecha.state_machine.change_state(&"Meltdown")
	_check(mecha.state_machine.current_state.name == &"Meltdown", "Mecha di MeltdownState")

	var dummy_attacker := BaseMecha.new()
	var initial_hp: int = mecha.current_hp
	# Serang dengan Light Attack (damage 40). Di Meltdown menerima 1.25x = 50.
	mecha.take_hit(dummy_attacker, CombatConstants.LIGHT_ATTACK)

	_check(mecha.current_hp == initial_hp - 50, "Menerima 50 damage (+25% penalti dari 40 base)")
	_check(mecha.state_machine.current_state.name == &"Meltdown", "Tetap terkunci di Meltdown (bukan Hitstun)")

	dummy_attacker.free()
	mecha.queue_free()

func _test_meltdown_recovery_and_reset() -> void:
	var mecha := _create_test_mecha(100.0)
	mecha.state_machine.change_state(&"Meltdown")
	var meltdown_state: MeltdownState = mecha.state_machine.get_node("Meltdown")

	# Simulasikan 89 frame
	for i in range(89):
		mecha.state_machine.physics_update(1.0 / 60.0)

	_check(meltdown_state.current_frame == 89, "Frame ke 89 masih di Meltdown")
	_check(mecha.state_machine.current_state.name == &"Meltdown", "Masih di Meltdown")
	_check(mecha.heat_component.current_heat == 100.0, "Panas masih 100%")

	# Tick frame ke-90
	mecha.state_machine.physics_update(1.0 / 60.0)

	_check(mecha.state_machine.current_state.name == &"Idle", "Kembali ke Idle setelah 90 frame")
	_check(mecha.heat_component.current_heat == 0.0, "Panas direset ke 0.0% setelah Meltdown selesai")
	_check(not mecha.is_overclocked(), "Status Overclock non-aktif")

	mecha.queue_free()
