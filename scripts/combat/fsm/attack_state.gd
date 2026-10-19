class_name AttackState
extends "res://scripts/combat/fsm/base_state.gd"

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")

## State Mecha saat mengeksekusi serangan normal (Light / Heavy)
## Mengatur siklus frame data (startup, active, recovery) dan aktivasi hitbox

var current_attack_data: Dictionary = {}
var current_attack_frame: int = 0
var hit_targets: Array[Node2D] = []
var has_super_armor: bool = false

func setup_attack(attack_data: Dictionary) -> void:
	current_attack_data = attack_data

func is_startup_super_armor_active() -> bool:
	var startup: int = current_attack_data.get("startup", 5)
	return has_super_armor and current_attack_frame < startup

func consume_super_armor() -> void:
	has_super_armor = false

func enter() -> void:
	current_attack_frame = 0
	hit_targets.clear()

	# 1-Hit Super Armor jika mecha berada di zona Overclock (Story 2.2 AC 2)
	has_super_armor = false
	if character and character.has_method("is_overclocked") and character.is_overclocked():
		has_super_armor = true

	if character and character.has_method("set_hitbox_active"):
		character.set_hitbox_active(false)

	# Pastikan mecha berhenti meluncur horizontal saat mengeksekusi serangan darat
	if character and character.is_on_floor():
		character.velocity.x = 0.0

	if OS.is_debug_build() and character:
		var atk_name: String = current_attack_data.get("name", "Normal")
		print("[STATE][%s] Mengeksekusi serangan: %s (Super Armor: %s)" % [
			character.name, atk_name, str(has_super_armor)
		])

func physics_update(_delta: float) -> void:
	if not character:
		return

	if current_attack_data.is_empty():
		state_machine.change_state(&"Idle")
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
