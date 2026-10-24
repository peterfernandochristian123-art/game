class_name MatchManager
extends Node

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")

## Pengatur Aturan Pertandingan: Best of 3 Rounds, Round Timer 90s, Sudden Death (Story 4.4)
## Mengatur siklus pergantian ronde, penghitungan skor kemenangan, time-out, dan evaluasi pemenang pertandingan

signal round_started(round_number: int)
signal timer_updated(seconds_left: float)
signal round_ended(winner_player_id: int, reason: StringName)
signal match_ended(match_winner_player_id: int)
signal sudden_death_started()

enum MatchState {
	IDLE,
	ROUND_ACTIVE,
	ROUND_OVER,
	SUDDEN_DEATH,
	MATCH_OVER
}

var current_state: MatchState = MatchState.IDLE
var current_round: int = 1
var p1_wins: int = 0
var p2_wins: int = 0
var round_time_remaining: float = CombatConstants.ROUND_TIME_SECONDS
var is_sudden_death: bool = false

var player1: Node2D = null
var player2: Node2D = null

func setup_match(p1: Node2D, p2: Node2D) -> void:
	player1 = p1
	player2 = p2
	p1_wins = 0
	p2_wins = 0
	current_round = 1
	is_sudden_death = false
	current_state = MatchState.IDLE

	if player1 and player1.has_signal("ring_out_eliminated"):
		if not player1.ring_out_eliminated.is_connected(_on_p1_ring_out):
			player1.ring_out_eliminated.connect(_on_p1_ring_out)

	if player2 and player2.has_signal("ring_out_eliminated"):
		if not player2.ring_out_eliminated.is_connected(_on_p2_ring_out):
			player2.ring_out_eliminated.connect(_on_p2_ring_out)

func start_match() -> void:
	p1_wins = 0
	p2_wins = 0
	current_round = 1
	is_sudden_death = false
	start_round()

func start_round() -> void:
	current_state = MatchState.ROUND_ACTIVE
	round_time_remaining = CombatConstants.ROUND_TIME_SECONDS
	reset_fighters_for_round()

	round_started.emit(current_round)
	timer_updated.emit(round_time_remaining)

	if OS.is_debug_build():
		print("[MATCH] Ronde %d dimulai! Waktu: %.0fs. Skor: P1 [%d] - [%d] P2." % [
			current_round, round_time_remaining, p1_wins, p2_wins
		])

func start_sudden_death() -> void:
	is_sudden_death = true
	current_state = MatchState.SUDDEN_DEATH
	round_time_remaining = CombatConstants.SUDDEN_DEATH_SECONDS

	reset_fighters_for_round()

	# Pada Sudden Death, kedua mecha memulai ronde langsung dengan 90% Heat (Overclock)
	if player1 and player1.has_method("add_heat"):
		player1.heat_gauge = CombatConstants.SUDDEN_DEATH_STARTING_HEAT
		if player1.heat_component:
			player1.heat_component.current_heat = CombatConstants.SUDDEN_DEATH_STARTING_HEAT
	if player2 and player2.has_method("add_heat"):
		player2.heat_gauge = CombatConstants.SUDDEN_DEATH_STARTING_HEAT
		if player2.heat_component:
			player2.heat_component.current_heat = CombatConstants.SUDDEN_DEATH_STARTING_HEAT

	sudden_death_started.emit()
	timer_updated.emit(round_time_remaining)

	if OS.is_debug_build():
		print("[MATCH] SUDDEN DEATH! Waktu 30s. Heat 90%% Overclock aktif!")

func process_match(delta: float) -> void:
	if current_state != MatchState.ROUND_ACTIVE and current_state != MatchState.SUDDEN_DEATH:
		return

	# Pengurangan waktu ronde
	round_time_remaining = maxf(0.0, round_time_remaining - delta)
	timer_updated.emit(round_time_remaining)

	# Cek eliminasi HP
	check_win_conditions()

	# Cek Time-Out
	if round_time_remaining <= 0.0 and (current_state == MatchState.ROUND_ACTIVE or current_state == MatchState.SUDDEN_DEATH):
		resolve_time_out()

func check_win_conditions() -> void:
	if not player1 or not player2:
		return
	if current_state != MatchState.ROUND_ACTIVE and current_state != MatchState.SUDDEN_DEATH:
		return

	var p1_hp: int = player1.current_hp if "current_hp" in player1 else 1000
	var p2_hp: int = player2.current_hp if "current_hp" in player2 else 1000

	# Double K.O.
	if p1_hp <= 0 and p2_hp <= 0:
		resolve_round_end(0, &"double_ko")
	# P1 Kalah (K.O.) -> P2 Menang
	elif p1_hp <= 0:
		resolve_round_end(2, &"ko")
	# P2 Kalah (K.O.) -> P1 Menang
	elif p2_hp <= 0:
		resolve_round_end(1, &"ko")

func _on_p1_ring_out(_fighter: Node2D) -> void:
	if current_state == MatchState.ROUND_ACTIVE or current_state == MatchState.SUDDEN_DEATH:
		resolve_round_end(2, &"ring_out")

func _on_p2_ring_out(_fighter: Node2D) -> void:
	if current_state == MatchState.ROUND_ACTIVE or current_state == MatchState.SUDDEN_DEATH:
		resolve_round_end(1, &"ring_out")

func resolve_time_out() -> void:
	var p1_pct: float = float(player1.current_hp) / float(max(1, player1.max_hp)) if player1 else 0.0
	var p2_pct: float = float(player2.current_hp) / float(max(1, player2.max_hp)) if player2 else 0.0

	if is_equal_approx(p1_pct, p2_pct):
		# Seri -> Sudden Death
		resolve_round_end(0, &"time_out_draw")
	elif p1_pct > p2_pct:
		resolve_round_end(1, &"time_out")
	else:
		resolve_round_end(2, &"time_out")

func resolve_round_end(winner_id: int, reason: StringName) -> void:
	current_state = MatchState.ROUND_OVER
	round_ended.emit(winner_id, reason)

	var bus = get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("round_ended"):
		bus.round_ended.emit(winner_id, reason)

	# Dramatic Finish Slow-Motion & Screen Shake saat K.O.
	if reason == &"ko" or reason == &"double_ko":
		if bus and bus.has_signal("dramatic_finish_triggered"):
			bus.dramatic_finish_triggered.emit(winner_id, reason)
		if bus and bus.has_signal("screen_shake_requested"):
			bus.screen_shake_requested.emit(18.0, 24)
		Engine.time_scale = 0.22
		var tree := get_tree()
		if tree:
			var tw := tree.create_tween()
			tw.tween_interval(0.12)
			tw.tween_property(Engine, "time_scale", 1.0, 0.4)

	# Skor seri memicu Sudden Death jika bukan sudah dalam Sudden Death
	if winner_id == 0:
		if not is_sudden_death:
			start_sudden_death()
			return
		else:
			# Jika Sudden Death berakhir seri lagi, tentukan pemenang default P1
			winner_id = 1

	if winner_id == 1:
		p1_wins += 1
	elif winner_id == 2:
		p2_wins += 1

	if OS.is_debug_build():
		print("[MATCH] Ronde berakhir! Pemenang: Player %d (%s). Skor: [%d] - [%d]." % [
			winner_id, reason, p1_wins, p2_wins
		])

	# Cek apakah ada pemain yang sudah memenangkan 2 ronde
	if p1_wins >= CombatConstants.ROUNDS_TO_WIN:
		current_state = MatchState.MATCH_OVER
		match_ended.emit(1)
		if OS.is_debug_build():
			print("[MATCH] MATCH WINNER: PLAYER 1!")
	elif p2_wins >= CombatConstants.ROUNDS_TO_WIN:
		current_state = MatchState.MATCH_OVER
		match_ended.emit(2)
		if OS.is_debug_build():
			print("[MATCH] MATCH WINNER: PLAYER 2!")
	else:
		# Lanjut ke ronde berikutnya
		current_round += 1

func reset_fighters_for_round() -> void:
	if player1:
		player1.current_hp = player1.max_hp
		player1.is_eliminated = false
		if "cliffhanger_grabs_used" in player1:
			player1.cliffhanger_grabs_used = 0
		if player1.has_method("reset_combo_state"):
			player1.reset_combo_state()
		if player1.state_machine:
			player1.state_machine.change_state(&"Idle")
		player1.global_position = _get_spawn_points()[0]
		if player1.has_method("set_facing_direction"):
			player1.set_facing_direction(1)

	if player2:
		player2.current_hp = player2.max_hp
		player2.is_eliminated = false
		if "cliffhanger_grabs_used" in player2:
			player2.cliffhanger_grabs_used = 0
		if player2.has_method("reset_combo_state"):
			player2.reset_combo_state()
		if player2.state_machine:
			player2.state_machine.change_state(&"Idle")
		player2.global_position = _get_spawn_points()[1]
		if player2.has_method("set_facing_direction"):
			player2.set_facing_direction(-1)

## Titik spawn: diambil dari arena yang menyediakan get_spawn_points() (mis. ArenaStage), jika tidak default lama.
func _get_spawn_points() -> Array[Vector2]:
	var result: Array[Vector2] = [Vector2(350.0, 280.0), Vector2(1050.0, 280.0)]
	var scene_root: Node = get_parent()
	if scene_root:
		for child in scene_root.get_children():
			if child.has_method("get_spawn_points"):
				var pts = child.get_spawn_points()
				if pts is Array and pts.size() >= 2:
					result = [pts[0], pts[1]]
				break
	return result

func _physics_process(delta: float) -> void:
	process_match(delta)
