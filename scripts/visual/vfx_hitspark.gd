class_name VFXHitSpark
extends Node2D

## Efek Visual Hitspark Tempur Geometris Gaya Fighting Game (Anime / Mecha Starburst)
## Menghadirkan bintang tumbukan 4-titik / 8-titik tajam (✦), cincin syok intan,
## garis kilat arah benturan (directional hit streak), dan debu partikel foton.
## Tingkat intensitas: 0 = Light (5L), 1 = Medium (5M), 2 = Heavy (5H/Smash), 3 = Counter Hit (CH).

@export var spark_color: Color = Color(1.0, 0.9, 0.2, 1.0)
@export var intensity_level: int = 1
@export var duration_seconds: float = 0.18
@export var hit_direction: Vector2 = Vector2.RIGHT

var _elapsed: float = 0.0
var _active: bool = false
var _rotation_angle: float = 0.0
var _ray_angles: Array[float] = []
var _ray_lengths: Array[float] = []

func _ready() -> void:
	z_index = 58

func trigger_hitspark(pos: Vector2, level: int = 1, custom_color: Color = Color.TRANSPARENT, dir: Vector2 = Vector2.RIGHT) -> void:
	global_position = pos
	intensity_level = clampi(level, 0, 3)
	hit_direction = dir.normalized() if dir.length_squared() > 0.01 else Vector2.RIGHT

	if custom_color != Color.TRANSPARENT:
		spark_color = custom_color
	else:
		match intensity_level:
			0: spark_color = Color(0.3, 0.95, 1.0) # Light: Cyan
			1: spark_color = Color(1.0, 0.85, 0.2) # Medium: Gold
			2: spark_color = Color(1.0, 0.45, 0.1) # Heavy: Fiery Amber
			3: spark_color = Color(1.0, 0.15, 0.3) # Counter: Crimson

	match intensity_level:
		0: duration_seconds = 0.12
		1: duration_seconds = 0.18
		2: duration_seconds = 0.24
		3: duration_seconds = 0.32

	_elapsed = 0.0
	_active = true
	_rotation_angle = randf_range(-0.3, 0.3)

	# Buat garis-garis silang tajam / comic impact spikes
	_ray_angles.clear()
	_ray_lengths.clear()
	var ray_count := 4 if intensity_level <= 1 else (8 if intensity_level == 2 else 12)
	for i in range(ray_count):
		var base_angle := (TAU / float(ray_count)) * float(i) + randf_range(-0.15, 0.15)
		_ray_angles.append(base_angle)
		_ray_lengths.append(randf_range(0.75, 1.35))

	queue_redraw()

func _process(delta: float) -> void:
	if not _active:
		return

	_elapsed += delta
	_rotation_angle += delta * 4.0

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

	var base_scale := 16.0
	match intensity_level:
		0: base_scale = 16.0
		1: base_scale = 26.0
		2: base_scale = 42.0
		3: base_scale = 58.0

	# Skala ekspansi tajam di awal (snap pop), lalu mengecil
	var pop_scale := 1.0
	if progress < 0.25:
		pop_scale = progress / 0.25 * 1.2
	else:
		pop_scale = 1.2 - (progress - 0.25) * 0.9

	var current_size := base_scale * pop_scale

	# 1. Garis Arah Tumbukan (Directional Hit Streak)
	if intensity_level >= 1:
		var streak_len := current_size * (1.8 + float(intensity_level) * 0.4)
		var streak_end := hit_direction * streak_len
		var streak_col := Color(spark_color.r, spark_color.g, spark_color.b, alpha * 0.9)
		draw_line(Vector2.ZERO, streak_end, streak_col, 2.5 + float(intensity_level))
		draw_line(Vector2.ZERO, streak_end * 0.75, Color(1.0, 1.0, 1.0, alpha * 0.95), 1.5)

	# 2. Cincin Syok Intan / Diamond Shockwave (Level 1+)
	if intensity_level >= 1:
		var diamond_rad := current_size * (0.8 + progress * 0.8)
		var diamond_col := Color(spark_color.r, spark_color.g, spark_color.b, alpha * 0.7)
		var d_pts := PackedVector2Array([
			Vector2(0, -diamond_rad),
			Vector2(diamond_rad * 1.3, 0),
			Vector2(0, diamond_rad),
			Vector2(-diamond_rad * 1.3, 0)
		])
		# Rotasi intan sesuai arah pukulan
		var rot_d_pts := PackedVector2Array()
		var dir_angle := hit_direction.angle()
		for pt in d_pts:
			rot_d_pts.append(pt.rotated(dir_angle))
		rot_d_pts.append(rot_d_pts[0])
		draw_polyline(rot_d_pts, diamond_col, 1.8)

	# 3. Garis-garis Jarum Impak Radial (Impact Spikes)
	for i in range(_ray_angles.size()):
		var angle := _ray_angles[i] + _rotation_angle * 0.2
		var r_len := current_size * _ray_lengths[i] * (1.0 + progress * 0.4)
		var pt := Vector2(cos(angle), sin(angle)) * r_len
		var r_col := Color(spark_color.r, spark_color.g, spark_color.b, alpha * 0.85)
		draw_line(Vector2.ZERO, pt, r_col, 1.8)
		draw_line(Vector2.ZERO, pt * 0.5, Color(1.0, 1.0, 1.0, alpha * 0.95), 1.0)

	# 4. Bintang Geometris Utama (Geometric 4-Point Star ✦)
	var star_outer_col := Color(spark_color.r, spark_color.g, spark_color.b, alpha * 0.95)
	var star_core_col := Color(1.0, 1.0, 1.0, alpha * 0.98)
	_draw_star(Vector2.ZERO, current_size, current_size * 0.2, 4, _rotation_angle, star_outer_col)
	_draw_star(Vector2.ZERO, current_size * 0.55, current_size * 0.12, 4, _rotation_angle, star_core_col)

	# 5. Bintang Sekunder Berputar untuk Heavy & Counter (8-Point Starburst ✧)
	if intensity_level >= 2:
		var sec_star_col := Color(spark_color.r, spark_color.g, spark_color.b, alpha * 0.8)
		_draw_star(Vector2.ZERO, current_size * 0.7, current_size * 0.16, 4, _rotation_angle + PI * 0.25, sec_star_col)

	# 6. Inti Titik Silau Putih Pusat (Center Flash Glow)
	var core_rad := maxf(2.0, current_size * 0.22 * (1.0 - progress * 0.6))
	draw_circle(Vector2.ZERO, core_rad, Color(1.0, 1.0, 1.0, alpha * 0.95))

func _draw_star(center: Vector2, outer_rad: float, inner_rad: float, points: int, rot: float, col: Color) -> void:
	var poly := PackedVector2Array()
	var total_pts := points * 2
	var step := TAU / float(total_pts)

	for i in range(total_pts):
		var rad := outer_rad if (i % 2 == 0) else inner_rad
		var a := rot + float(i) * step
		poly.append(center + Vector2(cos(a), sin(a)) * rad)

	draw_colored_polygon(poly, col)
