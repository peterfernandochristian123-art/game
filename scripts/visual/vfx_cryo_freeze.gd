class_name VFXCryoFreeze
extends Node2D

## Efek Visual Pembekuan Kriogenik & Kristal Es (Viper Blink Slash & Absolute Zero)
## Menggambar pecahan kristal es heksagonal, kabut dingin, dan gelombang beku cyan neon

@export var freeze_color: Color = Color(0.2, 0.95, 1.0, 1.0)
@export var radius: float = 48.0
@export var duration_seconds: float = 0.35

var _elapsed: float = 0.0
var _active: bool = false
var _crystals: Array[Vector2] = []
var _crystal_sizes: Array[float] = []

func _ready() -> void:
	z_index = 55

func trigger_freeze(pos: Vector2, burst_radius: float = 48.0, custom_color: Color = Color.TRANSPARENT) -> void:
	global_position = pos
	radius = burst_radius
	if custom_color != Color.TRANSPARENT:
		freeze_color = custom_color
	_elapsed = 0.0
	_active = true

	# Hasilkan titik-titik kristal es menyebar
	_crystals.clear()
	_crystal_sizes.clear()
	var count := 12
	for i in range(count):
		var angle := randf_range(0.0, TAU)
		var dist := randf_range(burst_radius * 0.2, burst_radius)
		_crystals.append(Vector2(cos(angle), sin(angle)) * dist)
		_crystal_sizes.append(randf_range(4.0, 10.0))

	queue_redraw()

func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	if _elapsed >= duration_seconds:
		_active = false
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	if not _active:
		return

	var progress := _elapsed / duration_seconds
	var alpha := clampf(1.0 - progress, 0.0, 1.0)
	var cur_radius := radius * (0.3 + progress * 0.7)

	# 1. Cincin gelombang beku luar
	var ring_col := Color(freeze_color.r, freeze_color.g, freeze_color.b, alpha * 0.7)
	draw_arc(Vector2.ZERO, cur_radius, 0.0, TAU, 16, ring_col, 2.5)

	# 2. Gelombang dalam putih cerah
	var inner_col := Color(1.0, 1.0, 1.0, alpha * 0.9)
	draw_arc(Vector2.ZERO, cur_radius * 0.6, 0.0, TAU, 12, inner_col, 1.5)

	# 3. Pecahan kristal es heksagonal
	for i in range(_crystals.size()):
		var base_pos: Vector2 = _crystals[i] * (0.6 + progress * 0.5)
		var sz: float = _crystal_sizes[i] * (1.0 - progress * 0.4)
		var c_col := Color(freeze_color.r, freeze_color.g, freeze_color.b, alpha * 0.85)

		# Bentuk belah ketupat kristal
		var poly := PackedVector2Array([
			base_pos + Vector2(0, -sz),
			base_pos + Vector2(sz * 0.6, 0),
			base_pos + Vector2(0, sz),
			base_pos + Vector2(-sz * 0.6, 0)
		])
		draw_colored_polygon(poly, c_col)
		draw_polyline(poly, Color(1.0, 1.0, 1.0, alpha), 1.0)
