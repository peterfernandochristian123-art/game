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

# Dynamic Camera Zoom Variables
var current_zoom_factor: float = 1.0
var zoom_frames_left: int = 0
var super_zoom_target_pos: Vector2 = Vector2.ZERO
var super_zoom_frames_left: int = 0

func _ready() -> void:
	base_position = position
	zoom = Vector2.ONE
	if is_instance_valid(EventBus):
		if EventBus.has_signal("screen_shake_requested"):
			EventBus.screen_shake_requested.connect(request_shake)
		if EventBus.has_signal("hit_confirmed"):
			EventBus.hit_confirmed.connect(_on_hit_confirmed)
		if EventBus.has_signal("skill_cast"):
			EventBus.skill_cast.connect(_on_skill_cast)

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

func request_zoom_punch(punch_factor: float = 1.05, duration_frames: int = 6) -> void:
	current_zoom_factor = maxf(current_zoom_factor, punch_factor)
	zoom_frames_left = maxi(zoom_frames_left, duration_frames)

func request_super_zoom(focus_pos: Vector2, zoom_factor: float = 1.20, duration_frames: int = 22) -> void:
	super_zoom_target_pos = focus_pos
	super_zoom_frames_left = duration_frames
	current_zoom_factor = zoom_factor

func _on_hit_confirmed(_attacker: Node2D, _victim: Node2D, hit_data: Variant) -> void:
	var data_dict: Dictionary = {}
	if hit_data is Dictionary:
		data_dict = hit_data
	elif hit_data != null and hit_data.has_method("to_dict"):
		data_dict = hit_data.to_dict()

	var is_counter: bool = data_dict.get("counter", false) or data_dict.get("is_counter", false)
	var atk_name: String = str(data_dict.get("name", ""))
	var dmg: float = float(data_dict.get("damage", 40.0))

	if is_counter or dmg >= 120.0:
		request_zoom_punch(1.08, 8)
	elif atk_name.contains("H") or atk_name.contains("Skill") or atk_name.contains("Ultimate") or dmg >= 75.0:
		request_zoom_punch(1.05, 6)

func _on_skill_cast(_caster: Node2D, skill_name: StringName, pos: Vector2, _facing: int) -> void:
	var s_name := String(skill_name)
	if s_name == "Ultimate" or s_name.contains("Protocol") or s_name.contains("Cannon") or s_name.contains("Supernova") or s_name.contains("Blossom") or s_name.contains("Overload"):
		request_super_zoom(pos, 1.22, 22)

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

	# 3. Proses Dynamic Zoom Punch & Super Freeze Zoom
	if super_zoom_frames_left > 0:
		super_zoom_frames_left -= 1
		zoom = zoom.lerp(Vector2(current_zoom_factor, current_zoom_factor), 0.25)
	elif zoom_frames_left > 0:
		zoom_frames_left -= 1
		zoom = zoom.lerp(Vector2(current_zoom_factor, current_zoom_factor), 0.35)
		current_zoom_factor = lerpf(current_zoom_factor, 1.0, 0.2)
		if zoom_frames_left == 0:
			current_zoom_factor = 1.0
	else:
		zoom = zoom.lerp(Vector2.ONE, 0.15)

func _update_tracking() -> void:
	if super_zoom_frames_left > 0 and super_zoom_target_pos != Vector2.ZERO:
		var clamped_target_x: float = clampf(super_zoom_target_pos.x, min_clamp_x, max_clamp_x)
		position.x = lerpf(position.x, clamped_target_x, 0.15)
		position.y = lerpf(position.y, default_y - 15.0, 0.15)
		return

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
