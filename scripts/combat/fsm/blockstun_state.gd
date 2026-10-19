class_name BlockstunState
extends "res://scripts/combat/fsm/base_state.gd"

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")

## State Mecha saat menangkis serangan (Blockstun Lock)
## Mengunci aksi pemain sementara selama durasi blockstun frame,
## menyerap knockback teredam, dan memulihkan mecha kembali ke Idle/Fall

var blockstun_duration: int = CombatConstants.DEFAULT_BLOCKSTUN_FRAMES
var current_stun_frame: int = 0
var knockback_velocity: Vector2 = Vector2.ZERO

func setup_blockstun(duration: int, knockback: Vector2 = Vector2.ZERO) -> void:
	blockstun_duration = max(1, duration)
	knockback_velocity = knockback

func enter() -> void:
	current_stun_frame = 0
	if character:
		character.velocity = knockback_velocity

	if OS.is_debug_build() and character:
		print("[STATE][%s] Memasuki BlockstunState selama %d frame." % [character.name, blockstun_duration])

func exit() -> void:
	current_stun_frame = 0

func physics_update(delta: float) -> void:
	if not character:
		return

	# Redam inersia knockback horizontal blok secara bertahap
	character.velocity.x = move_toward(character.velocity.x, 0.0, 1200.0 * delta)

	# Jika berada di udara, gravitasi tetap berlaku
	if not character.is_on_floor():
		character.velocity.y += CombatConstants.GRAVITY * delta

	current_stun_frame += 1

	if current_stun_frame >= blockstun_duration:
		if character.is_on_floor() or not state_machine.has_node("Fall"):
			state_machine.change_state(&"Idle")
		else:
			state_machine.change_state(&"Fall")
