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
const HeatComponentScript = preload("res://scripts/combat/components/heat_component.gd")

## Automated Test Suite untuk Story 2.1:
## Heat Gauge Component & Passive Cooling Logic

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

func _approx(a: float, b: float, eps: float = 0.0001) -> bool:
	return absf(a - b) <= eps

func _ready() -> void:
	var out_path: String = ProjectSettings.globalize_path("res://test_heat_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 2.1...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_constants,
		_test_clamp_and_signal,
		_test_meltdown_hook,
		_test_passive_cooling_math,
		_test_cooling_gate,
		_test_mecha_integration,
		_test_dash_adds_heat,
		_test_no_cooling_in_other_states,
		_test_attack_adds_no_heat,
		_test_physics_process_cooling,
	]
	var passed: int = 0
	for t in tests:
		_failed = false
		_log("\n--- %s ---" % t.get_method())
		t.call()
		if _failed:
			_log(" [GAGAL]")
		else:
			_log(" [PASS]")
			passed += 1

	_log("==================================================")
	_log("[TEST RUNNER] Hasil Pengujian: %d / %d Lulus" % [passed, tests.size()])
	_log("==================================================")
	var ok: bool = passed == tests.size()
	_log(">>> SEMUA TES STORY 2.1 BERHASIL! <<<" if ok else ">>> BEBERAPA TES GAGAL! <<<")
	if log_file:
		log_file.close()
	get_tree().quit(0 if ok else 1)

# --- Helper ---

func _make_mecha(states: Array) -> BaseMecha:
	var mecha := BaseMecha.new()
	mecha.name = "HeatMecha"
	var fsm := StateMachine.new()
	fsm.name = "StateMachine"
	mecha.add_child(fsm)
	for entry in states:
		var s: Node = entry[1].new()
		s.name = entry[0]
		fsm.add_child(s)
	add_child(mecha)
	return mecha

func _full_states() -> Array:
	return [
		["Idle", IdleState], ["Walk", WalkState], ["Jump", JumpState], ["Fall", FallState],
		["Dash", DashState], ["AirDash", AirDashState], ["Attack", AttackState],
	]

# --- Tests ---

func _test_constants() -> void:
	_check(_approx(CombatConstants.MAX_HEAT, 100.0), "MAX_HEAT harus 100")
	_check(_approx(CombatConstants.DASH_HEAT_COST, 10.0), "DASH_HEAT_COST harus 10")
	_check(_approx(CombatConstants.SKILL_HEAT_MIN, 15.0), "SKILL_HEAT_MIN harus 15")
	_check(_approx(CombatConstants.SKILL_HEAT_MAX, 35.0), "SKILL_HEAT_MAX harus 35")
	_check(_approx(CombatConstants.PASSIVE_COOLING_PER_FRAME, 0.2), "Cooling per frame harus 0.2")

func _test_clamp_and_signal() -> void:
	var hc: Node = HeatComponentScript.new()
	var emitted: Array = []
	hc.heat_changed.connect(func(cur: float, mx: float): emitted.append([cur, mx]))
	hc.add_heat(30.0)
	_check(_approx(hc.current_heat, 30.0), "Heat harus 30 setelah +30")
	_check(emitted.size() == 1 and _approx(emitted[0][0], 30.0) and _approx(emitted[0][1], 100.0), "heat_changed(30,100) harus terpancar")
	hc.add_heat(500.0)
	_check(_approx(hc.current_heat, 100.0), "Heat di-clamp maksimum 100")
	hc.add_heat(-500.0)
	_check(_approx(hc.current_heat, 0.0), "Heat di-clamp minimum 0")
	hc.free()

func _test_meltdown_hook() -> void:
	var hc: Node = HeatComponentScript.new()
	var count: Array = [0]
	hc.meltdown_triggered.connect(func(): count[0] += 1)
	hc.add_heat(99.0)
	_check(count[0] == 0, "Meltdown belum terpancar di 99")
	hc.add_heat(1.0)
	_check(count[0] == 1, "meltdown_triggered terpancar di 100")
	hc.free()

func _test_passive_cooling_math() -> void:
	var hc: Node = HeatComponentScript.new()
	hc.add_heat(50.0)
	for i in range(60):
		hc.process_frame(true)
	_check(_approx(hc.current_heat, 38.0, 0.001), "60 frame cooling = -12.0 (sisa 38.0), dapat %.4f" % hc.current_heat)
	for i in range(1000):
		hc.process_frame(true)
	_check(_approx(hc.current_heat, 0.0), "Heat tidak boleh < 0")
	hc.free()

func _test_cooling_gate() -> void:
	var hc: Node = HeatComponentScript.new()
	hc.add_heat(50.0)
	for i in range(60):
		hc.process_frame(false)
	_check(_approx(hc.current_heat, 50.0), "Tanpa can_cool heat tidak turun")
	hc.free()

func _test_mecha_integration() -> void:
	var mecha := _make_mecha(_full_states())
	_check(mecha.heat_component != null, "BaseMecha harus punya heat_component otomatis")
	mecha.heat_component.add_heat(40.0)
	_check(_approx(mecha.heat_gauge, 40.0), "heat_gauge harus tersinkron dari heat_changed")
	mecha.queue_free()

func _test_dash_adds_heat() -> void:
	var mecha := _make_mecha(_full_states())
	mecha.get_node("StateMachine/Dash").override_direction = Vector2.RIGHT
	mecha.state_machine.change_state(&"Dash")
	_check(_approx(mecha.heat_component.current_heat, 10.0), "Dash darat +10 heat, dapat %.2f" % mecha.heat_component.current_heat)
	mecha.state_machine.change_state(&"Idle")
	mecha.get_node("StateMachine/AirDash").override_direction = Vector2.RIGHT
	mecha.state_machine.change_state(&"AirDash")
	_check(_approx(mecha.heat_component.current_heat, 20.0), "AirDash +10 heat (total 20), dapat %.2f" % mecha.heat_component.current_heat)
	mecha.queue_free()

func _test_no_cooling_in_other_states() -> void:
	var mecha := _make_mecha(_full_states())
	mecha.heat_component.add_heat(50.0)
	# Idle & Walk mendingin 0.2 / frame
	mecha.state_machine.change_state(&"Idle")
	for i in range(10):
		mecha._update_heat_cooling()
	_check(_approx(mecha.heat_component.current_heat, 48.0, 0.001), "Idle 10 frame = -2.0, dapat %.3f" % mecha.heat_component.current_heat)
	mecha.state_machine.change_state(&"Walk")
	for i in range(10):
		mecha._update_heat_cooling()
	_check(_approx(mecha.heat_component.current_heat, 46.0, 0.001), "Walk 10 frame = -2.0, dapat %.3f" % mecha.heat_component.current_heat)
	# State lain tidak mendingin
	for state_name in [&"Jump", &"Fall", &"Dash", &"AirDash", &"Attack"]:
		var before: float = mecha.heat_component.current_heat
		mecha.state_machine.change_state(state_name)
		var after_enter: float = mecha.heat_component.current_heat
		for i in range(10):
			mecha._update_heat_cooling()
		_check(_approx(mecha.heat_component.current_heat, after_enter), "State %s tidak boleh mendinginkan" % state_name)
	mecha.queue_free()

func _test_attack_adds_no_heat() -> void:
	var mecha := _make_mecha(_full_states())
	mecha.request_attack(CombatConstants.LIGHT_ATTACK)
	_check(_approx(mecha.heat_component.current_heat, 0.0), "Normal attack tidak menambah heat")
	mecha.queue_free()

func _test_physics_process_cooling() -> void:
	var mecha := _make_mecha(_full_states())
	mecha.state_machine.change_state(&"Idle")
	mecha.heat_component.add_heat(50.0)
	mecha._physics_process(1.0 / 60.0)
	_check(mecha.heat_component.current_heat < 50.0, "_physics_process harus memanggil pendinginan di Idle, dapat %.3f" % mecha.heat_component.current_heat)
	mecha.queue_free()
