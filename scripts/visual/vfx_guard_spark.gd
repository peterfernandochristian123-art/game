class_name VFXGuardSpark
extends Node2D

## Efek Visual Guard Spark Matriks Heksagonal (Blocked Attack FX)
## Menggambar riak perisai energi heksagonal vertikal (holographic honeycomb grid)
## di depan pertahanan mecha saat menangkis serangan, dilengkapi percikan pantulan kinetik 45 derajat.

@export var guard_color: Color = Color(0.2, 0.85, 1.0, 1.0)
@export var duration_seconds: float = 0.22
@export var facing_dir: int = 1

var _elapsed: float = 0.0
var _active: bool = false
var _hex_offsets: Array[Vector2] = []
var _ricochet_sparks: Array[Vector2] = []
var _spark_vels: Array[Vector2] = []

func _ready() -> void:
	z_index = 57

func trigger_guard(pos: Vector2, facing: int = 1, custom_color: Color = Color.TRANSPARENT) -> void:
	global_position = pos
	facing_dir = facing
	if custom_color != Color.TRANSPARENT:
		guard_color = custom_color

	_elapsed = 0.0
	_active = true

	# Susunan sel-sel heksagonal vertikal membentuk kurva pelindung (honeycomb arc)
	_hex_offsets.clear()
	var hex_r := 12.0
	_hex_offsets.append(Vector2(0, 0)) # Sel pusat
	_hex_offsets.append(Vector2(-facing_dir * 3.0, -hex_r * 1.6)) # Atas
	_hex_offsets.append(Vector2(-facing_dir * 3.0, hex_r * 1.6))  # Bawah
	_hex_offsets.append(Vector2(-facing_dir * 12.0, -hex_r * 0.8)) # Belakang atas
	_hex_offsets.append(Vector2(-facing_dir * 12.0, hex_r * 0.8))  # Belakang bawah

	# Hasilkan percikan defleksi pantulan (ricochet sparks)
	_ricochet_sparks.clear()
	_spark_vels.clear()
	var spark_count := 8
	for i in range(spark_count):
		_ricochet_sparks.append(Vector2.ZERO)
		var angle := randf_range(-PI * 0.35, PI * 0.35)
		var speed := randf_range(160.0, 320.0)
		var vel := Vector2(float(-facing_dir) * cos(angle), sin(angle)) * speed
		_spark_vels.append(vel)

	queue_redraw()

func _process(delta: float) -> void:
	if not _active:
		return

	_elapsed += delta

	for i in range(_ricochet_sparks.size()):
		_ricochet_sparks[i] += _spark_vels[i] * delta
		_spark_vels[i] *= 0.92

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
	var hex_size := 14.0 * (0.85 + progress * 0.35)

	# 1. Garis Busur Kurva Medan Energi Depan
	var arc_col := Color(guard_color.r, guard_color.g, guard_color.b, alpha * 0.9)
	var arc_pts := PackedVector2Array()
	var arc_h := 38.0
	var arc_segs := 8
	for i in range(arc_segs + 1):
		var t := float(i) / float(arc_segs)
		var y := lerpf(-arc_h, arc_h, t)
		var x := (1.0 - (y / arc_h) * (y / arc_h)) * 6.0 * float(facing_dir)
		arc_pts.append(Vector2(x, y))
	draw_polyline(arc_pts, arc_col, 2.5)
	draw_polyline(arc_pts, Color(1.0, 1.0, 1.0, alpha * 0.95), 1.2)

	# 2. Gambar Honeycomb Hex Cells
	for off in _hex_offsets:
		_draw_hex_cell(off, hex_size, alpha)

	# 3. Percikan Pantulan Ricochet
	for i in range(_ricochet_sparks.size()):
		var sp := _ricochet_sparks[i]
		var sp_col := Color(guard_color.r, guard_color.g, guard_color.b, alpha * 0.85)
		draw_circle(sp, maxf(1.0, 2.5 * (1.0 - progress)), sp_col)
		# Garis jejak kilat pendek
		var tail := sp - _spark_vels[i] * 0.02
		draw_line(sp, tail, Color(1.0, 1.0, 1.0, alpha * 0.9), 1.5)

func _draw_hex_cell(center: Vector2, size: float, alpha: float) -> void:
	var pts := PackedVector2Array()
	for i in range(6):
		var a := deg_to_rad(60.0 * i - 30.0)
		pts.append(center + Vector2(cos(a), sin(a)) * size)

	# Fill pudar
	var fill_c := Color(guard_color.r, guard_color.g, guard_color.b, alpha * 0.16)
	draw_colored_polygon(pts, fill_c)

	# Outline grid tajam
	var closed := pts.duplicate()
	closed.append(pts[0])
	var border_c := Color(guard_color.r, guard_color.g, guard_color.b, alpha * 0.85)
	draw_polyline(closed, border_c, 1.5)
	draw_polyline(closed, Color(1.0, 1.0, 1.0, alpha * 0.4), 0.8)
