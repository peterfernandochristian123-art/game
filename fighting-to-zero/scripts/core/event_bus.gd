extends Node

## Central Event Dispatcher untuk Fighting to Zero
## Mengirimkan sinyal global lintas sistem (Combat, UI, Camera, Audio, Game Flow)

signal hit_confirmed(attacker: Node2D, victim: Node2D, hit_data: Variant)
signal parry_triggered(defender: Node2D, attacker: Node2D)
signal hitstop_requested(frames: int)
signal screen_shake_requested(intensity: float, duration_frames: int)
signal cliffhanger_triggered(mecha_id: int, side: StringName)
signal round_ended(winner_id: int, reason: StringName)
signal state_changed(character: Node2D, previous_state: StringName, new_state: StringName)

func _ready() -> void:
	if OS.is_debug_build():
		print("[EVENT_BUS] Global EventBus Autoload diinisialisasi.")
