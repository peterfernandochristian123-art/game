class_name VFXEnergySlash
extends Node2D

## Efek Visual Busur Tebasan Energi Laser 32-Bit (Story 6.2)
## Menggambar lengkungan tebasan neon tajam yang memudar cepat dalam 6-8 frame

@export var slash_color: Color = Color(0.2, 0.95, 1.0, 1.0)
@export var arc_radius: float = 32.0
@export var duration_seconds: float = 0.12

var _elapsed: float = 0.0
var _active: bool = false
var _facing: int = 1

func _ready() -> void:
	z_index = 50

func trigger_slash(pos: Vector2, facing_dir: int = 1, color_tint: Color = Color.TRANSPARENT) -> void:
	global_position = pos
	_facing = facing_dir
	if color_tint != Color.TRANSPARENT:
		slash_color = color_tint
	_elapsed = 0.0
	_active = true
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

	var progress: float = _elapsed / duration_seconds
	var alpha: float = clampf(1.0 - progress, 0.0, 1.0)
	var cur_radius: float = arc_radius * (0.8 + progress * 0.4)

	# Busur tebasan: titik awal hingga akhir membentuk bulan sabit (crescent)
	var points := PackedVector2Array()
	var num_segments := 8
	var start_angle: float = -PI * 0.4
	var end_angle: float = PI * 0.4

	# Sisi luar busur
	for i in range(num_segments + 1):
		var t: float = float(i) / float(num_segments)
		var angle: float = lerpf(start_angle, end_angle, t)
		var pt := Vector2(cos(angle), sin(angle)) * cur_radius
		pt.x *= float(_facing)
		points.append(pt)

	# Sisi dalam busur (lebih tipis di ujung, tebal di tengah)
	for i in range(num_segments, -1, -1):
		var t: float = float(i) / float(num_segments)
		var angle: float = lerpf(start_angle, end_angle, t)
		var thickness: float = sin(t * PI) * 10.0 * (1.0 - progress * 0.5)
		var pt := Vector2(cos(angle), sin(angle)) * maxf(4.0, cur_radius - thickness)
		pt.x *= float(_facing)
		points.append(pt)

	var draw_col := Color(slash_color.r, slash_color.g, slash_color.b, alpha)
	draw_colored_polygon(points, draw_col)

	# Garis outline putih tajam di tepi luar
	var core_points := PackedVector2Array()
	for i in range(num_segments + 1):
		core_points.append(points[i])
	var core_col := Color(1.0, 1.0, 1.0, alpha * 0.9)
	draw_polyline(core_points, core_col, 2.0)
