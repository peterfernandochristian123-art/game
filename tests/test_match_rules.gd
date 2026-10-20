extends Node

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")
const BaseMecha = preload("res://scripts/characters/base_mecha.gd")
const MatchManager = preload("res://scripts/core/match_manager.gd")
const StateMachine = preload("res://scripts/combat/fsm/state_machine.gd")
const IdleState = preload("res://scripts/combat/fsm/idle_state.gd")

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
	var out_path: String = ProjectSettings.globalize_path("res://test_match_rules_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 4.4: Match Rules & Win Conditions...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_match_initialization,
		_test_round_ko_victory,
		_test_ring_out_victory,
		_test_match_winner_declaration,
		_test_time_out_resolution,
		_test_sudden_death_trigger,
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

func _create_fighter(f_name: String) -> BaseMecha:
	var mecha := BaseMecha.new()
	mecha.name = f_name

	var fsm := StateMachine.new()
	fsm.name = "StateMachine"
	mecha.add_child(fsm)

	var idle := IdleState.new()
	idle.name = "Idle"
	fsm.add_child(idle)

	add_child(mecha)
	return mecha

func _test_match_initialization() -> void:
	var p1 = _create_fighter("P1")
	var p2 = _create_fighter("P2")

	var mm := MatchManager.new()
	add_child(mm)
	mm.setup_match(p1, p2)
	mm.start_match()

	_check(mm.current_round == 1, "Ronde awal harus 1")
	_check(mm.p1_wins == 0 and mm.p2_wins == 0, "Skor awal harus 0 - 0")
	_check(is_equal_approx(mm.round_time_remaining, CombatConstants.ROUND_TIME_SECONDS), "Timer ronde awal harus 90 detik")
	_check(mm.current_state == MatchManager.MatchState.ROUND_ACTIVE, "State awal harus ROUND_ACTIVE")

	mm.queue_free()
	p1.queue_free()
	p2.queue_free()

func _test_round_ko_victory() -> void:
	var p1 = _create_fighter("P1")
	var p2 = _create_fighter("P2")

	var mm := MatchManager.new()
	add_child(mm)
	mm.setup_match(p1, p2)
	mm.start_match()

	# P2 HP berkurang ke 0
	p2.current_hp = 0
	mm.check_win_conditions()

	_check(mm.p1_wins == 1, "P1 harus mendapatkan 1 kemenangan ronde karena K.O.")
	_check(mm.current_round == 2, "Setelah ronde 1 selesai, ronde harus berganti ke ronde 2")

	mm.queue_free()
	p1.queue_free()
	p2.queue_free()

func _test_ring_out_victory() -> void:
	var p1 = _create_fighter("P1")
	var p2 = _create_fighter("P2")

	var mm := MatchManager.new()
	add_child(mm)
	mm.setup_match(p1, p2)
	mm.start_match()

	# P1 terkena Ring Out
	p1.eliminate_by_ring_out()

	_check(mm.p2_wins == 1, "P2 harus mendapatkan kemenangan ronde saat P1 tereliminasi Ring-Out")

	mm.queue_free()
	p1.queue_free()
	p2.queue_free()

func _test_match_winner_declaration() -> void:
	var p1 = _create_fighter("P1")
	var p2 = _create_fighter("P2")

	var mm := MatchManager.new()
	add_child(mm)
	mm.setup_match(p1, p2)
	mm.start_match()

	var winner_box := {"id": 0}
	mm.match_ended.connect(func(w_id): winner_box["id"] = w_id)

	# Kemenangan 1 untuk P1
	p2.current_hp = 0
	mm.check_win_conditions()

	# Kemenangan 2 untuk P1 (Best of 3 terpenuhi: 2 kemenangan)
	mm.start_round()
	p2.current_hp = 0
	mm.check_win_conditions()

	_check(mm.p1_wins == 2, "P1 harus memiliki 2 kemenangan")
	_check(mm.current_state == MatchManager.MatchState.MATCH_OVER, "State harus berubah menjadi MATCH_OVER")
	_check(winner_box["id"] == 1, "Pemenang pertandingan harus dinyatakan Player 1")

	mm.queue_free()
	p1.queue_free()
	p2.queue_free()

func _test_time_out_resolution() -> void:
	var p1 = _create_fighter("P1")
	var p2 = _create_fighter("P2")

	var mm := MatchManager.new()
	add_child(mm)
	mm.setup_match(p1, p2)
	mm.start_match()

	# P1 800/1000 HP (80%), P2 500/1000 HP (50%)
	p1.current_hp = 800
	p2.current_hp = 500
	mm.round_time_remaining = 0.0
	mm.resolve_time_out()

	_check(mm.p1_wins == 1, "P1 harus memenangkan ronde via Time-Out karena sisa HP lebih tinggi (80% vs 50%)")

	mm.queue_free()
	p1.queue_free()
	p2.queue_free()

func _test_sudden_death_trigger() -> void:
	var p1 = _create_fighter("P1")
	var p2 = _create_fighter("P2")

	var mm := MatchManager.new()
	add_child(mm)
	mm.setup_match(p1, p2)
	mm.start_match()

	var sd_box := {"fired": false}
	mm.sudden_death_started.connect(func(): sd_box["fired"] = true)

	# Double K.O. memicu Sudden Death
	p1.current_hp = 0
	p2.current_hp = 0
	mm.check_win_conditions()

	_check(mm.is_sudden_death == true, "Harus mengaktifkan mode Sudden Death")
	_check(sd_box["fired"] == true, "Sinyal sudden_death_started harus dipancarkan")
	_check(is_equal_approx(mm.round_time_remaining, CombatConstants.SUDDEN_DEATH_SECONDS), "Timer Sudden Death harus 30 detik")
	_check(is_equal_approx(p1.heat_gauge, CombatConstants.SUDDEN_DEATH_STARTING_HEAT), "P1 harus mulai dengan 90% Heat pada Sudden Death")
	_check(is_equal_approx(p2.heat_gauge, CombatConstants.SUDDEN_DEATH_STARTING_HEAT), "P2 harus mulai dengan 90% Heat pada Sudden Death")

	mm.queue_free()
	p1.queue_free()
	p2.queue_free()
