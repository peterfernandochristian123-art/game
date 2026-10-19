class_name CliffhangerState
extends "res://scripts/combat/fsm/base_state.gd"

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")

## State Mecha saat bergelantungan di tepi jurang (Story 4.2)
## Memberikan jendela 120 frame (2.0 detik) untuk memilih aksi: Climb-Up Jump, Ledge Sweep, atau Drop Fall
## Maksimal 1 kali aktivasi per ronde untuk mencegah stalling tak terbatas

var cliffhanger_timer_frames: int = 120
var ledge_side: StringName = &"left"
var current_action: StringName = &"hanging" # &"hanging", &"climbing", &"sweeping", &"dropping"
var action_frame: int = 0
var simulated_action: StringName = &""

func setup_ledge(side: StringName) -> void:
	ledge_side = side

func enter() -> void:
	cliffhanger_timer_frames = CombatConstants.CLIFFHANGER_HANG_TIME_FRAMES
	current_action = &"hanging"
	action_frame = 0
	simulated_action = &""

	if not character:
		return

	character.velocity = Vector2.ZERO

	# Catat pemakaian jatah cliffhanger
	if "cliffhanger_grabs_used" in character:
		character.cliffhanger_grabs_used += 1

	# Posisikan mecha tepat mencengkeram bibir tebing
	if ledge_side == &"left":
		character.global_position.x = CombatConstants.ARENA_LEFT_BOUND
		if character.has_method("set_facing_direction"):
			character.set_facing_direction(1) # Menghadap ke kanan (ke arah panggung)
		else:
			character.facing_direction = 1
	else:
		character.global_position.x = CombatConstants.ARENA_RIGHT_BOUND
		if character.has_method("set_facing_direction"):
			character.set_facing_direction(-1) # Menghadap ke kiri (ke arah panggung)
		else:
			character.facing_direction = -1

	if OS.is_debug_build():
		print("[STATE][%s] Memasuki CliffhangerState di sisi: %s. Timer: %d frame." % [
			character.name, ledge_side, cliffhanger_timer_frames
		])

func physics_update(_delta: float) -> void:
	if not character:
		return

	match current_action:
		&"hanging":
			character.velocity = Vector2.ZERO
			cliffhanger_timer_frames -= 1

			# Pilihan 1: Climb-Up Jump (Tombol Lompat / Atas)
			if _is_climb_requested() or simulated_action == &"climb":
				current_action = &"climbing"
				action_frame = 0
				simulated_action = &""
				if OS.is_debug_build():
					print("[STATE][%s] Cliffhanger -> Climb-Up Jump dimulai (Startup 18f)." % character.name)
				return

			# Pilihan 2: Ledge Sweep Attack (Tombol Serang)
			if _is_sweep_requested() or simulated_action == &"sweep":
				current_action = &"sweeping"
				action_frame = 0
				simulated_action = &""
				if OS.is_debug_build():
					print("[STATE][%s] Cliffhanger -> Ledge Sweep Attack dimulai (Startup 12f)." % character.name)
				return

			# Pilihan 3: Drop Fall (Tombol Bawah atau Timer Habis)
			if _is_drop_requested() or cliffhanger_timer_frames <= 0 or simulated_action == &"drop":
				current_action = &"dropping"
				action_frame = 0
				simulated_action = &""
				if OS.is_debug_build():
					print("[STATE][%s] Cliffhanger -> Drop Fall dilepaskan (Ring Out / Fall)." % character.name)
				_execute_drop()
				return

		&"climbing":
			character.velocity = Vector2.ZERO
			action_frame += 1
			# Startup 18 frame selesai -> lompat memanjat kembali ke atas panggung
			if action_frame >= CombatConstants.CLIFFHANGER_CLIMB_STARTUP_FRAMES:
				var move_in: float = float(character.facing_direction) * 80.0
				character.global_position.x += move_in
				character.global_position.y -= 24.0
				if state_machine:
					state_machine.change_state(&"Idle")

		&"sweeping":
			character.velocity = Vector2.ZERO
			action_frame += 1

			# Jendela aktif sapuan kaki / sweep
			var startup: int = CombatConstants.CLIFFHANGER_SWEEP_STARTUP_FRAMES
			var active: int = CombatConstants.CLIFFHANGER_SWEEP_ACTIVE_FRAMES
			var recovery: int = CombatConstants.CLIFFHANGER_SWEEP_RECOVERY_FRAMES

			if action_frame == startup:
				if character.has_method("set_hitbox_active"):
					character.set_hitbox_active(true)
			elif action_frame == startup + active:
				if character.has_method("set_hitbox_active"):
					character.set_hitbox_active(false)
			elif action_frame >= startup + active + recovery:
				if character.has_method("set_hitbox_active"):
					character.set_hitbox_active(false)
				var move_in: float = float(character.facing_direction) * 60.0
				character.global_position.x += move_in
				character.global_position.y -= 20.0
				if state_machine:
					state_machine.change_state(&"Idle")

		&"dropping":
			_execute_drop()

func _execute_drop() -> void:
	if character and character.has_method("set_hitbox_active"):
		character.set_hitbox_active(false)
	if state_machine:
		if state_machine.has_node("Fall"):
			state_machine.change_state(&"Fall")
		else:
			state_machine.change_state(&"Idle")

func _is_climb_requested() -> bool:
	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("move_up"):
		return true
	if character and character.has_method("has_buffered_action"):
		return character.has_buffered_action(&"jump")
	return false

func _is_sweep_requested() -> bool:
	if Input.is_action_just_pressed("attack_light") or Input.is_action_just_pressed("attack_heavy"):
		return true
	if character and character.has_method("has_buffered_action"):
		return character.has_buffered_action(&"attack_light") or character.has_buffered_action(&"attack_heavy")
	return false

func _is_drop_requested() -> bool:
	return Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("move_down")

func exit() -> void:
	if character and character.has_method("set_hitbox_active"):
		character.set_hitbox_active(false)
