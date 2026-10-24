class_name VFXEnergySlash
extends Node2D

## Efek Visual Busur Tebasan Energi Laser 32-Bit (Enhanced Fighting Game Blade Slash)
## Menggambar lengkungan tebasan neon bergradasi ganda, inti bilah putih tajam,
## pita jejak kecepatan (motion blur ribbons), dan percikan kilat di ujung sayatan.

@export var slash_color: Color = Color(0.2, 0.95, 1.0, 1.0)
@export var arc_radius: float = 34.0
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
	var cur_radius: float = arc_radius * (0.85 + progress * 0.45)

	# Busur tebasan: bulan sabit dinamis (crescent curve)
	var points := PackedVector2Array()
	var trail_points := PackedVector2Array()
	var num_segments := 10
	var start_angle: float = -PI * 0.42
	var end_angle: float = PI * 0.42

	# 1. Sisi luar busur bilah
	for i in range(num_segments + 1):
		var t: float = float(i) / float(num_segments)
		var angle: float = lerpf(start_angle, end_angle, t)
		var pt := Vector2(cos(angle), sin(angle)) * cur_radius
		pt.x *= float(_facing)
		points.append(pt)

	# 2. Sisi dalam busur bilah (tebal di tengah, runcing di ujung)
	for i in range(num_segments, -1, -1):
		var t: float = float(i) / float(num_segments)
		var angle: float = lerpf(start_angle, end_angle, t)
		var thickness: float = sin(t * PI) * 12.0 * (1.0 - progress * 0.4)
		var pt := Vector2(cos(angle), sin(angle)) * maxf(4.0, cur_radius - thickness)
		pt.x *= float(_facing)
		points.append(pt)

	# 3. Pita jejak gerak memudar (trailing motion ribbon) di belakang sayatan
	var trail_offset := -Vector2(float(_facing) * 8.0, 0.0) * (1.0 - progress)
	for i in range(num_segments + 1):
		var t: float = float(i) / float(num_segments)
		var angle: float = lerpf(start_angle, end_angle, t)
		var pt := Vector2(cos(angle), sin(angle)) * (cur_radius - 6.0) + trail_offset
		pt.x *= float(_facing)
		trail_points.append(pt)

	# Gambar pita jejak gerak
	if trail_points.size() > 2:
		var trail_col := Color(slash_color.r, slash_color.g, slash_color.b, alpha * 0.35)
		draw_polyline(trail_points, trail_col, 3.0)

	# 4. Gambar badan bilah energi neon
	var draw_col := Color(slash_color.r, slash_color.g, slash_color.b, alpha * 0.88)
	draw_colored_polygon(points, draw_col)

	# 5. Garis inti putih bilah tajam di tepi luar (Razor Core Polyline)
	var core_points := PackedVector2Array()
	for i in range(num_segments + 1):
		core_points.append(points[i])
	var core_col := Color(1.0, 1.0, 1.0, alpha * 0.96)
	draw_polyline(core_points, core_col, 2.2)

	# 6. Percikan energi foton di kedua ujung bilah (Tip Sparkles)
	if points.size() > 0:
		var tip1 := points[0]
		var tip2 := points[num_segments]
		var spark_rad := maxf(1.0, 3.5 * (1.0 - progress))
		draw_circle(tip1, spark_rad, Color.WHITE)
		draw_circle(tip2, spark_rad, Color.WHITE)
