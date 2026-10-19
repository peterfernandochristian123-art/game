class_name IdleState
extends "res://scripts/combat/fsm/base_state.gd"

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")

## State Mecha saat diam di tanah
## Menangani degradasi inersia horizontal dan transisi ke Walk, Jump, atau Fall

func enter() -> void:
	if character:
		character.velocity.x = 0.0
		if character.has_method("reset_combo_state"):
			character.reset_combo_state()

	# Langsung eksekusi aksi buffer pada frame pertama actionable (AC 1)
	if _is_parry_pressed():
		_consume_buffered_action(&"parry")
		state_machine.change_state(&"Parry")
		return
	if _is_skill_pressed():
		_consume_buffered_action(&"skill1")
		if character and character.has_method("request_attack_by_name"):
			character.request_attack_by_name(&"Skill1")
		return
	if _is_attack_heavy_pressed():
		_consume_buffered_action(&"attack_heavy")
		if character and character.has_method("request_attack_by_name"):
			character.request_attack_by_name(&"5H")
		elif character and character.has_method("request_attack"):
			character.request_attack(CombatConstants.HEAVY_ATTACK)
		return
	if _is_attack_light_pressed():
		_consume_buffered_action(&"attack_light")
		if character and character.has_method("request_attack_by_name"):
			character.request_attack_by_name(&"5L")
		elif character and character.has_method("request_attack"):
			character.request_attack(CombatConstants.LIGHT_ATTACK)
		return
	if _is_dash_pressed():
		_consume_buffered_action(&"dash")
		state_machine.change_state(&"Dash")
		return
	if _is_jump_pressed():
		_consume_buffered_action(&"jump")
		state_machine.change_state(&"Jump")
		return

func physics_update(delta: float) -> void:
	if not character:
		return

	# Cek apakah mecha kehilangan pijakan tanah
	if not character.is_on_floor():
		state_machine.change_state(&"Fall")
		return

	# Cek input parry (Story 2.3)
	if _is_parry_pressed():
		_consume_buffered_action(&"parry")
		state_machine.change_state(&"Parry")
		return

	# Cek input skill (Story 3.1)
	if _is_skill_pressed():
		_consume_buffered_action(&"skill1")
		if character and character.has_method("request_attack_by_name"):
			character.request_attack_by_name(&"Skill1")
		return

	# Cek input serangan (Heavy / Light)
	if _is_attack_heavy_pressed():
		_consume_buffered_action(&"attack_heavy")
		if character and character.has_method("request_attack_by_name"):
			character.request_attack_by_name(&"5H")
		elif character and character.has_method("request_attack"):
			character.request_attack(CombatConstants.HEAVY_ATTACK)
		return
	if _is_attack_light_pressed():
		_consume_buffered_action(&"attack_light")
		if character and character.has_method("request_attack_by_name"):
			character.request_attack_by_name(&"5L")
		elif character and character.has_method("request_attack"):
			character.request_attack(CombatConstants.LIGHT_ATTACK)
		return

	# Cek input dash (langsung maupun dari buffer 5-frame)
	if _is_dash_pressed():
		_consume_buffered_action(&"dash")
		state_machine.change_state(&"Dash")
		return

	# Cek input lompat (langsung maupun dari buffer 5-frame)
	if _is_jump_pressed():
		_consume_buffered_action(&"jump")
		state_machine.change_state(&"Jump")
		return

	# Cek input pergerakan horizontal
	var input_x: float = _get_horizontal_input()
	if absf(input_x) > 0.05:
		state_machine.change_state(&"Walk")
		return

	# Hentikan inersia horizontal
	character.velocity.x = move_toward(character.velocity.x, 0.0, 1800.0 * delta)

func _get_horizontal_input() -> float:
	if character and character.has_method("get_horizontal_axis"):
		return character.get_horizontal_axis()
	var val: float = Input.get_axis("move_left", "move_right")
	if is_zero_approx(val):
		val = Input.get_axis("ui_left", "ui_right")
	return val

func _is_jump_pressed() -> bool:
	if character and character.has_method("is_jump_requested"):
		return character.is_jump_requested()
	return (
		Input.is_action_just_pressed("jump")
		or Input.is_action_just_pressed("ui_up")
		or Input.is_action_just_pressed("ui_accept")
	)

func _is_dash_pressed() -> bool:
	if character and character.has_method("can_dash") and not character.can_dash():
		return false
	if character and character.has_method("is_dash_requested"):
		return character.is_dash_requested()
	return Input.is_action_just_pressed("dash")

func _is_attack_heavy_pressed() -> bool:
	if character and character.has_method("is_attack_heavy_requested"):
		return character.is_attack_heavy_requested()
	return Input.is_action_just_pressed("attack_heavy")

func _is_attack_light_pressed() -> bool:
	if character and character.has_method("is_attack_light_requested"):
		return character.is_attack_light_requested()
	return Input.is_action_just_pressed("attack_light")

func _is_parry_pressed() -> bool:
	if character and character.has_method("is_parry_requested"):
		return character.is_parry_requested()
	return Input.is_action_just_pressed("parry")

func _is_skill_pressed() -> bool:
	if character and character.has_method("is_skill_requested"):
		return character.is_skill_requested()
	return Input.is_action_just_pressed("skill1")

func _consume_buffered_action(action_name: StringName) -> void:
	if character and character.has_method("try_consume_buffered_action"):
		character.try_consume_buffered_action(action_name)


