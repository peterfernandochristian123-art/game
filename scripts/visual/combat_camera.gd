class_name CombatCamera
extends Camera2D

## Kamera Arena Dinamis dengan Guncangan Layar (Dynamic Screen Shake) (Story 6.1)
## Menyediakan getaran layar berbasis decay eksponensial saat pukulan/parry mendarat
## Menghormati pengaturan aksesibilitas screen_shake dari SettingsManager

const SettingsManagerScript = preload("res://scripts/core/settings_manager.gd")

@export var shake_enabled: bool = true
@export var min_clamp_x: float = 400.0
@export var max_clamp_x: float = 1000.0
@export var default_y: float = 240.0

var base_position: Vector2 = Vector2.ZERO
var current_shake_intensity: float = 0.0
var shake_frames_left: int = 0

var target_p1: Node2D = null
var target_p2: Node2D = null

func _ready() -> void:
	base_position = position
	if is_instance_valid(EventBus):
		if EventBus.has_signal("screen_shake_requested"):
			EventBus.screen_shake_requested.connect(request_shake)

func request_shake(intensity: float, duration_frames: int) -> void:
	if not shake_enabled:
		return

	# Periksa preferensi screen_shake dari SettingsManager
	var sm = get_node_or_null("/root/SettingsManager")
	if sm and sm.has_method("get_setting"):
		var allow_shake: bool = sm.get_setting("display", "screen_shake", true)
		if not allow_shake:
			return

	current_shake_intensity = maxf(current_shake_intensity, intensity)
	shake_frames_left = maxi(shake_frames_left, duration_frames)

func _process(_delta: float) -> void:
	# 1. Update posisi pelacakan petarung (jika target diset)
	_update_tracking()

	# 2. Proses Screen Shake
	if shake_frames_left > 0:
		shake_frames_left -= 1
		var shake_x: float = randf_range(-1.0, 1.0) * current_shake_intensity
		var shake_y: float = randf_range(-1.0, 1.0) * current_shake_intensity
		offset = Vector2(shake_x, shake_y)

		# Decay eksponensial halus
		current_shake_intensity = lerpf(current_shake_intensity, 0.0, 0.15)

		if shake_frames_left == 0:
			offset = Vector2.ZERO
			current_shake_intensity = 0.0
	else:
		offset = Vector2.ZERO

func _update_tracking() -> void:
	if is_instance_valid(target_p1) and is_instance_valid(target_p2):
		var mid_x: float = (target_p1.global_position.x + target_p2.global_position.x) / 2.0
		var clamped_x: float = clampf(mid_x, min_clamp_x, max_clamp_x)
		position.x = lerpf(position.x, clamped_x, 0.1)
		position.y = default_y
	else:
		position = base_position

func track_fighters(p1: Node2D, p2: Node2D) -> void:
	target_p1 = p1
	target_p2 = p2
