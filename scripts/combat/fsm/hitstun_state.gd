class_name HitstunState
extends "res://scripts/combat/fsm/base_state.gd"

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")

## State Mecha saat terkena serangan (Hitstun lock)
## Mengunci aksi pemain, menerima knockback, dan memulihkan karakter ke Idle/Fall saat durasi berakhir

var hitstun_duration: int = 14
var current_stun_frame: int = 0
var knockback_velocity: Vector2 = Vector2.ZERO

func setup_hitstun(duration: int, knockback: Vector2 = Vector2.ZERO) -> void:
	hitstun_duration = duration
	knockback_velocity = knockback

func enter() -> void:
	current_stun_frame = 0
	if character:
		character.velocity = knockback_velocity

	if OS.is_debug_build() and character:
		print("[STATE][%s] Memasuki HitstunState selama %d frame." % [character.name, hitstun_duration])

func physics_update(delta: float) -> void:
	if not character:
		return

	# Redam inersia knockback horizontal secara bertahap
	character.velocity.x = move_toward(character.velocity.x, 0.0, 900.0 * delta)

	# Jika di udara, gravitasi tetap berlaku
	if not character.is_on_floor():
		character.velocity.y += CombatConstants.GRAVITY * delta

	current_stun_frame += 1

	if current_stun_frame >= hitstun_duration:
		if character and character.has_method("reset_combo_state"):
			character.reset_combo_state()

		if character.is_on_floor() or not state_machine.has_node("Fall"):
			state_machine.change_state(&"Idle")
		else:
			state_machine.change_state(&"Fall")
