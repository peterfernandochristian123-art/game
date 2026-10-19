class_name AirDashState
extends "res://scripts/combat/fsm/base_state.gd"

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")

## State Mecha saat melakukan Vector Dash di udara
## Maksimal 1x per sesi melayang, kecepatan konstan 750 px/s selama 14 frame, gravitasi diabaikan

var dash_direction: Vector2 = Vector2.ZERO
var current_dash_frame: int = 0
var override_direction: Vector2 = Vector2.ZERO

func enter() -> void:
	if not character:
		return

	# Konsumsi hak air dash
	if "can_air_dash" in character:
		character.can_air_dash = false

	# Resolusi arah vektor dash
	if override_direction != Vector2.ZERO:
		dash_direction = override_direction
		override_direction = Vector2.ZERO
	elif character.has_method("get_dash_vector"):
		dash_direction = character.get_dash_vector()
	else:
		var dir_x: float = float(character.facing_direction if "facing_direction" in character else 1)
		dash_direction = Vector2(dir_x, 0.0)

	# Sinkronisasi arah hadap visual jika dash memiliki komponen horizontal
	if not is_zero_approx(dash_direction.x) and character.has_method("set_facing_direction"):
		character.set_facing_direction(1 if dash_direction.x > 0 else -1)

	# Terapkan kecepatan dash konstan dan reset frame counter
	var dash_spd: float = character.get_dash_speed() if character.has_method("get_dash_speed") else CombatConstants.DASH_SPEED
	character.velocity = dash_direction * dash_spd
	current_dash_frame = 0

	# Setiap dash menambah panas (Story 2.1)
	if character.has_method("add_heat"):
		character.add_heat(CombatConstants.DASH_HEAT_COST)

	if OS.is_debug_build():
		print("[STATE][%s] Transisi ke AirDash. Arah: %s, Kecepatan: %.1f px/s" % [
			character.name, dash_direction, dash_spd
		])

func physics_update(_delta: float) -> void:
	if not character:
		return

	current_dash_frame += 1

	# Jika menabrak lantai saat dash mengarah ke bawah, batalkan sisa durasi dan mendarat
	if character.is_on_floor() and dash_direction.y > 0.0:
		state_machine.change_state(&"Idle")
		return

	# Pertahankan kecepatan konstan dan lintasan lurus di udara (gravitasi dinonaktifkan)
	var dash_spd: float = character.get_dash_speed() if character.has_method("get_dash_speed") else CombatConstants.DASH_SPEED
	var dash_dur: int = character.get_dash_duration() if character.has_method("get_dash_duration") else CombatConstants.DASH_DURATION_FRAMES
	character.velocity = dash_direction * dash_spd

	# Periksa batas akhir durasi dash
	if current_dash_frame >= dash_dur:
		if character.is_on_floor():
			var input_x: float = character.get_horizontal_axis() if character.has_method("get_horizontal_axis") else 0.0
			if not is_zero_approx(input_x):
				state_machine.change_state(&"Walk")
			else:
				state_machine.change_state(&"Idle")
		else:
			state_machine.change_state(&"Fall")

func exit() -> void:
	# Mulai timer cooldown 18 frame pada mecha
	if character and "dash_cooldown_frames" in character:
		character.dash_cooldown_frames = CombatConstants.DASH_COOLDOWN_FRAMES
