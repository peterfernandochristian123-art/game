extends Node

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")
const BaseMecha = preload("res://scripts/characters/base_mecha.gd")
const StateMachine = preload("res://scripts/combat/fsm/state_machine.gd")
const IdleState = preload("res://scripts/combat/fsm/idle_state.gd")
const FallState = preload("res://scripts/combat/fsm/fall_state.gd")
const AttackState = preload("res://scripts/combat/fsm/attack_state.gd")
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
	var out_path: String = ProjectSettings.globalize_path("res://test_ledge_stomp_ring_out_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 4.3: Ledge Stomp & Ring-Out...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_ledge_stomp_attack_resource,
		_test_ledge_stomp_instakill_on_cliffhanger,
		_test_fall_below_y_ring_out,
		_test_normal_attack_does_not_instakill_cliffhanger,
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

func _create_mecha(mecha_name: String) -> BaseMecha:
	var mecha := BaseMecha.new()
	mecha.name = mecha_name

	var fsm := StateMachine.new()
	fsm.name = "StateMachine"
	mecha.add_child(fsm)

	var idle := IdleState.new()
	idle.name = "Idle"
	fsm.add_child(idle)

	var fall := FallState.new()
	fall.name = "Fall"
	fsm.add_child(fall)

	var attack := AttackState.new()
	attack.name = "Attack"
	fsm.add_child(attack)

	var ch := CliffhangerState.new()
	ch.name = "Cliffhanger"
	fsm.add_child(ch)

	add_child(mecha)
	return mecha

func _test_ledge_stomp_attack_resource() -> void:
	var stomp = load("res://resources/attacks/ledge_stomp.tres")
	_check(stomp != null, "ledge_stomp.tres harus valid")
	if stomp:
		_check(stomp.startup == 15, "Ledge Stomp startup harus 15f")
		_check(stomp.active == 4, "Ledge Stomp active harus 4f")
		_check(stomp.recovery == 20, "Ledge Stomp recovery harus 20f")
		_check(stomp.damage == 120, "Ledge Stomp damage harus 120")
		_check(stomp.is_ledge_stomp == true, "Ledge Stomp flag is_ledge_stomp harus true")
		_check(stomp.is_unblockable == true, "Ledge Stomp harus unblockable")

func _test_ledge_stomp_instakill_on_cliffhanger() -> void:
	var attacker = _create_mecha("Attacker")
	var victim = _create_mecha("Victim")

	victim.trigger_cliffhanger(&"left")
	_check(victim.state_machine.current_state.name == &"Cliffhanger", "Victim harus dalam CliffhangerState")

	var ring_out_fired := [false]
	victim.ring_out_eliminated.connect(func(_m): ring_out_fired[0] = true)

	var stomp_res = load("res://resources/attacks/ledge_stomp.tres")
	victim.take_hit(attacker, stomp_res.to_dict())

	_check(victim.is_eliminated == true, "Victim harus tereliminasi (is_eliminated == true)")
	_check(victim.current_hp == 0, "HP Victim harus menjadi 0")
	_check(ring_out_fired[0] == true, "Sinyal ring_out_eliminated harus dipancarkan")

	attacker.queue_free()
	victim.queue_free()

func _test_fall_below_y_ring_out() -> void:
	var mecha = _create_mecha("FallingMecha")

	# Posisikan mecha jatuh bebas di bawah batas kill-Y (650 > 600)
	mecha.global_position = Vector2(704.0, 650.0)

	var ring_out_fired := [false]
	mecha.ring_out_eliminated.connect(func(_m): ring_out_fired[0] = true)

	mecha._physics_process(1.0 / 60.0)

	_check(mecha.is_eliminated == true, "Mecha yang jatuh di bawah Y=600 harus tereliminasi Ring-Out")
	_check(mecha.current_hp == 0, "HP Mecha jatuh harus 0")
	_check(ring_out_fired[0] == true, "Sinyal ring_out_eliminated harus terpicu")

	mecha.queue_free()

func _test_normal_attack_does_not_instakill_cliffhanger() -> void:
	var attacker = _create_mecha("Attacker2")
	var victim = _create_mecha("Victim2")

	victim.trigger_cliffhanger(&"right")
	var hp_before = victim.current_hp

	var normal_atk: Dictionary = {
		"name": &"NormalLight",
		"damage": 40,
		"is_ledge_stomp": false
	}
	victim.take_hit(attacker, normal_atk)

	_check(victim.is_eliminated == false, "Serangan biasa tidak boleh memicu instant Ring-Out pada Cliffhanger")
	_check(victim.current_hp == hp_before - 40, "Victim harus menerima damage normal tanpa langsung mati")

	attacker.queue_free()
	victim.queue_free()
