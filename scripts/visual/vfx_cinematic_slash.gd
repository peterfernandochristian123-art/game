class_name VFXCinematicSlash
extends Node2D

## Efek Visual Tebasan Sinematik & Garis Kecepatan (Kage Iaido Crescent & Shadow Blossom)
## Menampilkan garis potong pedang berkecepatan tinggi, garis kecepatan manga, dan retakan sayatan

@export var slash_color: Color = Color(1.0, 0.15, 0.25, 1.0)
@export var slash_length: float = 220.0
@export var duration_seconds: float = 0.35

class SlashLine:
	var start_pt: Vector2
	var end_pt: Vector2
	var angle: float
	var thickness: float
	var speedlines: Array[PackedVector2Array] = []

var _slashes: Array[SlashLine] = []
var _elapsed: float = 0.0
var _active: bool = false

func _ready() -> void:
	z_index = 57

func trigger_cinematic_slash(pos: Vector2, slash_count: int = 1, custom_color: Color = Color.TRANSPARENT, duration: float = 0.35, length: float = 220.0) -> void:
	global_position = pos
	slash_length = length
	duration_seconds = duration
	if custom_color != Color.TRANSPARENT:
		slash_color = custom_color

	_elapsed = 0.0
	_active = true

	_slashes.clear()
	var angles: Array[float] = []
	if slash_count <= 1:
		angles = [-0.35] # Tebasan sabit diagonal tunggal (Iaido Crescent)
	else:
		# Criss-cross multi-tebasan (Shadow Blossom Ultimate)
		angles = [-0.4, 0.45, -0.15, 0.65, -0.75]

	for a in angles:
		var sl := SlashLine.new()
		sl.angle = a
		var dir := Vector2(cos(a), sin(a))
		var half_l := slash_length * 0.5 * randf_range(0.85, 1.2)
		var center_jitter := Vector2(randf_range(-25.0, 25.0), randf_range(-25.0, 25.0))
		sl.start_pt = center_jitter - dir * half_l
		sl.end_pt = center_jitter + dir * half_l
		sl.thickness = randf_range(3.0, 5.0)

		# Buat garis kecepatan paralel kecil
		var perp := dir.orthogonal()
		for sp in range(3):
			var off := perp * randf_range(-18.0, 18.0)
			var sp_start := sl.start_pt + off + dir * randf_range(20.0, 60.0)
			var sp_end := sp_start + dir * randf_range(60.0, 120.0)
			sl.speedlines.append(PackedVector2Array([sp_start, sp_end]))

		_slashes.append(sl)

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

	for sl in _slashes:
		# 1. Garis Tebasan Luar Neon
		var outer_col := Color(slash_color.r, slash_color.g, slash_color.b, alpha * 0.9)
		draw_line(sl.start_pt, sl.end_pt, outer_col, sl.thickness)

		# 2. Inti Bilah Putih Tajam
		var core_col := Color(1.0, 1.0, 1.0, alpha * 0.95)
		draw_line(sl.start_pt, sl.end_pt, core_col, maxf(1.2, sl.thickness * 0.35))

		# 3. Garis-garis Kecepatan Manga Paralel
		var sp_col := Color(slash_color.r, slash_color.g, slash_color.b, alpha * 0.65)
		for sp in sl.speedlines:
			draw_line(sp[0], sp[1], sp_col, 1.5)

		# 4. Kilatan Titik Akhir Sayatan
		draw_circle(sl.end_pt, 4.0 * (1.0 - progress), Color.WHITE)
