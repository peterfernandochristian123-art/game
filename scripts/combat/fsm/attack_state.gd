class_name AttackState
extends "res://scripts/combat/fsm/base_state.gd"

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")

## State Mecha saat mengeksekusi serangan normal (Light / Heavy)
## Mengatur siklus frame data (startup, active, recovery) dan aktivasi hitbox

var current_attack_data: Dictionary = {}
var current_attack_frame: int = 0
var hit_targets: Array[Node2D] = []
var has_super_armor: bool = false
var can_chain_cancel: bool = false

func setup_attack(attack_data: Variant) -> void:
	if attack_data is Resource and attack_data.has_method("to_dict"):
		current_attack_data = attack_data.to_dict()
	elif attack_data is Dictionary:
		current_attack_data = attack_data
	else:
		current_attack_data = {}

func is_startup_super_armor_active() -> bool:
	var startup: int = current_attack_data.get("startup", 5)
	return has_super_armor and current_attack_frame < startup

func consume_super_armor() -> void:
	has_super_armor = false

func enter() -> void:
	current_attack_frame = 0
	hit_targets.clear()
	can_chain_cancel = false

	# 1-Hit Super Armor jika mecha berada di zona Overclock (Story 2.2 AC 2)
	has_super_armor = false
	if character and character.has_method("is_overclocked") and character.is_overclocked():
		has_super_armor = true

	# Konsumsi Heat jika serangan memiliki heat_cost (Story 3.1)
	var heat_cost: float = current_attack_data.get("heat_cost", 0.0)
	if heat_cost > 0.0 and character and character.has_method("add_heat"):
		character.add_heat(heat_cost)

	if character and character.has_method("set_hitbox_active"):
		character.set_hitbox_active(false)

	# Pastikan mecha berhenti meluncur horizontal saat mengeksekusi serangan darat
	if character and character.is_on_floor():
		character.velocity.x = 0.0

	if OS.is_debug_build() and character:
		var atk_name: String = current_attack_data.get("name", "Normal")
		print("[STATE][%s] Mengeksekusi serangan: %s (Super Armor: %s, Heat: %.1f)" % [
			character.name, atk_name, str(has_super_armor), heat_cost
		])

func physics_update(_delta: float) -> void:
	if not character:
		return

	if current_attack_data.is_empty():
		state_machine.change_state(&"Idle")
		return

	# Target Chain Cancel System (Normal 1 -> Normal 2 -> Skill) saat serangan mengenai target
	if can_chain_cancel and _check_chain_cancels():
		return

	var startup: int = current_attack_data.get("startup", 5)
	var active: int = current_attack_data.get("active", 3)
	var recovery: int = current_attack_data.get("recovery", 8)
	var total_frames: int = startup + active + recovery

	current_attack_frame += 1

	# Selesai total durasi serangan
	if current_attack_frame >= total_frames:
		if character.has_method("set_hitbox_active"):
			character.set_hitbox_active(false)

		if character.is_on_floor() or not state_machine.has_node("Fall"):
			state_machine.change_state(&"Idle")
		else:
			state_machine.change_state(&"Fall")
		return

	# Jendela aktivasi hitbox: aktif pada active frames [startup, startup + active)
	if current_attack_frame >= startup and current_attack_frame < startup + active:
		if character.has_method("set_hitbox_active"):
			character.set_hitbox_active(true)
	else:
		if character.has_method("set_hitbox_active"):
			character.set_hitbox_active(false)

func exit() -> void:
	if character and character.has_method("set_hitbox_active"):
		character.set_hitbox_active(false)
	hit_targets.clear()

func can_hit_target(target: Node2D) -> bool:
	if target in hit_targets or target == character:
		return false
	return true

func register_hit_target(target: Node2D) -> void:
	if target not in hit_targets:
		hit_targets.append(target)
		can_chain_cancel = true

func _check_chain_cancels() -> bool:
	var chain_lvl: int = current_attack_data.get("chain_level", 1)

	# Skill Cancel (Bisa dicancel dari Normal 1 / 5L atau Normal 2 / 5H)
	if chain_lvl < 3 and _is_skill_requested():
		_consume_buffered_action(&"skill1")
		if character and character.has_method("request_attack_by_name"):
			character.request_attack_by_name(&"Skill1")
			return true

	# Normal 2 (Heavy) Cancel (Bisa dicancel dari Normal 1 / 5L)
	if chain_lvl < 2 and _is_attack_heavy_pressed():
		_consume_buffered_action(&"attack_heavy")
		if character and character.has_method("request_attack_by_name"):
			character.request_attack_by_name(&"5H")
			return true
		elif character and character.has_method("request_attack"):
			character.request_attack(CombatConstants.HEAVY_ATTACK)
			return true

	return false

func _is_skill_requested() -> bool:
	if character and character.has_method("is_skill_requested"):
		return character.is_skill_requested()
	return Input.is_action_just_pressed("skill1")

func _is_attack_heavy_pressed() -> bool:
	if character and character.has_method("is_attack_heavy_requested"):
		return character.is_attack_heavy_requested()
	return Input.is_action_just_pressed("attack_heavy")

func _consume_buffered_action(action_name: StringName) -> void:
	if character and character.has_method("try_consume_buffered_action"):
		character.try_consume_buffered_action(action_name)
