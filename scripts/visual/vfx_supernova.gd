class_name VFXSupernova
extends Node2D

## Efek Visual Ledakan Supernova / Korona Surya (Pulsar Supernova & Unit-0 Overload)
## Menampilkan ledakan 360 derajat korona plasma kosmik, sinar suar surya, dan gelombang kejut radial

@export var supernova_color: Color = Color(0.8, 0.25, 1.0, 1.0)
@export var max_radius: float = 190.0
@export var duration_seconds: float = 0.55

var _elapsed: float = 0.0
var _active: bool = false
var _flare_angles: Array[float] = []
var _flare_lengths: Array[float] = []

func _ready() -> void:
	z_index = 56

func trigger_supernova(pos: Vector2, radius: float = 190.0, custom_color: Color = Color.TRANSPARENT, duration: float = 0.55) -> void:
	global_position = pos
	max_radius = radius
	duration_seconds = duration
	if custom_color != Color.TRANSPARENT:
		supernova_color = custom_color

	_elapsed = 0.0
	_active = true

	# Hasilkan suar radiasi surya yang menyembur keluar
	_flare_angles.clear()
	_flare_lengths.clear()
	var flare_count := 18
	for i in range(flare_count):
		_flare_angles.append((TAU / float(flare_count)) * float(i) + randf_range(-0.15, 0.15))
		_flare_lengths.append(randf_range(0.7, 1.3))

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
	var current_rad := max_radius * (0.2 + progress * 0.8)

	# 1. Suar Radiasi Plasma (Rays)
	for i in range(_flare_angles.size()):
		var angle := _flare_angles[i]
		var l := current_rad * _flare_lengths[i]
		var end_pt := Vector2(cos(angle), sin(angle)) * l
		var ray_col := Color(supernova_color.r, supernova_color.g, supernova_color.b, alpha * 0.75)
		draw_line(Vector2.ZERO, end_pt, ray_col, 2.5)
		draw_line(Vector2.ZERO, end_pt * 0.7, Color(1.0, 1.0, 1.0, alpha * 0.9), 1.2)

	# 2. Cincin Gelombang Kejut Luar
	var outer_ring_col := Color(supernova_color.r, supernova_color.g, supernova_color.b, alpha * 0.85)
	draw_arc(Vector2.ZERO, current_rad, 0.0, TAU, 28, outer_ring_col, 3.5)

	# 3. Lapisan Transparan Korona Dalam
	var corona_fill := Color(supernova_color.r, supernova_color.g, supernova_color.b, alpha * 0.22)
	draw_circle(Vector2.ZERO, current_rad * 0.75, corona_fill)

	# 4. Inti Putih Terang Menyilaukan
	var core_rad := (max_radius * 0.35) * (1.0 - progress * 0.6)
	draw_circle(Vector2.ZERO, core_rad, Color(1.0, 1.0, 1.0, alpha * 0.95))
