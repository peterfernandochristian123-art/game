class_name VFXGhostTrail
extends Node2D

## Komponen Visual Siluet Bayangan Dash (Ghost Trail Afterimage - Story 7.2)
## Muncul di posisi dunia saat mecha melakukan Vector Dash dan memudar bertahap.

@export var archetype: StringName = &"viper"
@export var trail_color: Color = Color(0.2, 0.9, 1.0, 0.70)
@export var max_lifetime_frames: int = 10
@export var facing_direction: int = 1

var frames_alive: int = 0
var initial_alpha: float = 0.70

func _ready() -> void:
	set_physics_process(true)
	scale.x = absf(scale.x) * (1 if facing_direction >= 0 else -1)
	if archetype == &"bulwark":
		trail_color = Color(1.0, 0.6, 0.15, initial_alpha)
	else:
		trail_color = Color(0.2, 0.9, 1.0, initial_alpha)

func setup(pos: Vector2, facing: int, arch: StringName, custom_color: Color = Color.TRANSPARENT) -> void:
	global_position = pos
	facing_direction = facing
	archetype = arch
	scale.x = absf(scale.x) * (1 if facing >= 0 else -1)
	if custom_color != Color.TRANSPARENT:
		trail_color = custom_color
	elif archetype == &"bulwark":
		trail_color = Color(1.0, 0.6, 0.15, initial_alpha)
	else:
		trail_color = Color(0.2, 0.9, 1.0, initial_alpha)
	queue_redraw()

func _physics_process(_delta: float) -> void:
	frames_alive += 1
	if frames_alive >= max_lifetime_frames:
		queue_free()
		return
	
	var progress: float = float(frames_alive) / float(max_lifetime_frames)
	var current_alpha: float = initial_alpha * (1.0 - progress)
	trail_color.a = current_alpha
	queue_redraw()

func _draw() -> void:
	if trail_color.a <= 0.01:
		return

	# Menggambar siluet mecha 32-bit pixel art transparan
	if archetype == &"bulwark":
		_draw_bulwark_silhouette()
	else:
		_draw_viper_silhouette()

func _draw_viper_silhouette() -> void:
	# Sasis & Badan
	draw_rect(Rect2(-8, -10, 16, 15), trail_color)
	# Kepala & Visor
	draw_rect(Rect2(-5, -18, 10, 8), trail_color)
	# Kaki
	draw_rect(Rect2(-7, 5, 5, 14), trail_color)
	draw_rect(Rect2(2, 5, 5, 14), trail_color)
	# Thruster flare bayangan
	draw_rect(Rect2(-12, -7, 4, 6), Color(trail_color.r, trail_color.g, trail_color.b, trail_color.a * 0.7))

func _draw_bulwark_silhouette() -> void:
	# Bodi Baja Berat
	draw_rect(Rect2(-10, -11, 20, 17), trail_color)
	# Shoulder Armor
	draw_rect(Rect2(-13, -12, 4, 7), trail_color)
	draw_rect(Rect2(9, -12, 4, 7), trail_color)
	# Kepala
	draw_rect(Rect2(-6, -18, 12, 7), trail_color)
	# Kaki Piston
	draw_rect(Rect2(-9, 6, 7, 13), trail_color)
	draw_rect(Rect2(2, 6, 7, 13), trail_color)
	# Thruster flare bayangan
	draw_rect(Rect2(-14, -5, 4, 7), Color(trail_color.r, trail_color.g, trail_color.b, trail_color.a * 0.7))
