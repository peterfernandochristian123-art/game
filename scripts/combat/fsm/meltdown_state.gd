class_name MeltdownState
extends "res://scripts/combat/fsm/base_state.gd"

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")

## State Kelumpuhan Mecha saat mencapai batas panas maksimal (Emergency Meltdown Shutdown)
## Lumpuh total selama tepat 90 frame fisika (1.5s pada 60 FPS deterministik).
## Tidak dapat menerima input, kecepatan horizontal terkunci 0, dan setelah selesai suhu direset ke 0%.

var current_frame: int = 0

func enter() -> void:
	current_frame = 0

	if character:
		character.velocity.x = 0.0
		if character.has_method("set_hitbox_active"):
			character.set_hitbox_active(false)

	if OS.is_debug_build() and character:
		print("[STATE][%s] Memasuki MeltdownState (Core Shutdown %d frames)" % [
			character.name, CombatConstants.MELTDOWN_DURATION_FRAMES
		])

func physics_update(_delta: float) -> void:
	if not character:
		return

	# Mecha lumpuh total di darat
	character.velocity.x = 0.0

	current_frame += 1

	if current_frame >= CombatConstants.MELTDOWN_DURATION_FRAMES:
		# Reset panas mecha ke 0.0% setelah selesai meltdown
		if character.heat_component:
			character.heat_component.reset()

		if OS.is_debug_build():
			print("[STATE][%s] MeltdownState selesai. Suhu direset ke 0. Kembali ke netral." % character.name)

		if character.is_on_floor() or not state_machine.has_node("Fall"):
			state_machine.change_state(&"Idle")
		else:
			state_machine.change_state(&"Fall")

func handle_input(_event: InputEvent) -> void:
	# Mengabaikan semua input aksi saat mecha dalam kondisi shutdown
	pass

func exit() -> void:
	current_frame = 0
