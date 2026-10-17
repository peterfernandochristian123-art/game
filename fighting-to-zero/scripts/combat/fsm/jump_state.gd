class_name JumpState
extends "res://scripts/combat/fsm/base_state.gd"

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")

## State Mecha saat melompat (dorongan vertikal awal JUMP_VELOCITY)
## Mengatur kontrol udara horizontal dan transisi ke Fall saat kecepatan vertikal mencapai puncak

func enter() -> void:
	if not character:
		return

	# Reset coyote time dan konsumsi buffered jump jika ada
	if character.has_method("consume_coyote_jump"):
		character.consume_coyote_jump()
	if character.has_method("try_consume_buffered_action"):
		character.try_consume_buffered_action(&"jump")

	var jump_vel: float = character.jump_velocity if "jump_velocity" in character else CombatConstants.JUMP_VELOCITY
	character.velocity.y = jump_vel

func physics_update(delta: float) -> void:
	if not character:
		return

	# Cek input air dash (AC 3, AC 5)
	if _is_air_dash_pressed():
		state_machine.change_state(&"AirDash")
		return

	# Terapkan gravitasi konstan
	var grav: float = character.gravity if "gravity" in character else CombatConstants.GRAVITY
	character.velocity.y += grav * delta

	# Kontrol udara horizontal
	var input_x: float = _get_horizontal_input()
	var speed: float = character.walk_speed if "walk_speed" in character else CombatConstants.DEFAULT_WALK_SPEED
	if not is_zero_approx(input_x):
		character.velocity.x = input_x * speed
		if character.has_method("set_facing_direction"):
			character.set_facing_direction(1 if input_x > 0 else -1)
	else:
		character.velocity.x = move_toward(character.velocity.x, 0.0, 600.0 * delta)

	# Transisi ke FallState begitu mecha melewati puncak lompatan
	if character.velocity.y >= 0.0:
		state_machine.change_state(&"Fall")

func _get_horizontal_input() -> float:
	if character and character.has_method("get_horizontal_axis"):
		return character.get_horizontal_axis()
	var val: float = Input.get_axis("move_left", "move_right")
	if is_zero_approx(val):
		val = Input.get_axis("ui_left", "ui_right")
	return val

func _is_air_dash_pressed() -> bool:
	if character and "can_air_dash" in character and not character.can_air_dash:
		return false
	if character and character.has_method("can_dash") and not character.can_dash():
		return false
	if character and character.has_method("is_dash_requested"):
		return character.is_dash_requested()
	return Input.is_action_just_pressed("dash")

