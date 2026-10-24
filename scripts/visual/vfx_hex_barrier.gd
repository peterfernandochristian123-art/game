class_name VFXHexBarrier
extends Node2D

## Efek Visual Barrier Heksagonal / Perisai Energi (Viper Deflection & Bulwark Riot Shield)
## Menampilkan grid heksagonal neon berdenyut, bracket sudut pelindung, dan partikel defleksi

@export var barrier_color: Color = Color(0.2, 0.95, 1.0, 1.0)
@export var radius: float = 52.0
@export var duration_seconds: float = 0.5

var _elapsed: float = 0.0
var _active: bool = false
var _target_node: Node2D = null
var _pulse_speed: float = 12.0

func _ready() -> void:
	z_index = 52

func trigger_barrier(target: Node2D = null, at_pos: Vector2 = Vector2.ZERO, duration: float = 0.5, color_tint: Color = Color.TRANSPARENT, barrier_radius: float = 52.0) -> void:
	_target_node = target
	if is_instance_valid(target):
		global_position = target.global_position
	else:
		global_position = at_pos

	duration_seconds = duration
	radius = barrier_radius
	if color_tint != Color.TRANSPARENT:
		barrier_color = color_tint

	_elapsed = 0.0
	_active = true
	queue_redraw()

func _process(delta: float) -> void:
	if not _active:
		return

	if is_instance_valid(_target_node):
		global_position = _target_node.global_position

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
	var pulse := 1.0 + 0.08 * sin(_elapsed * _pulse_speed)
	var r := radius * pulse

	# 1. Fill Heksagon Semi-Transparan
	var hex_points := PackedVector2Array()
	for i in range(6):
		var angle := deg_to_rad(60.0 * i - 30.0)
		hex_points.append(Vector2(cos(angle), sin(angle)) * r)

	var fill_col := Color(barrier_color.r, barrier_color.g, barrier_color.b, alpha * 0.18)
	draw_colored_polygon(hex_points, fill_col)

	# 2. Garis Batas Luar Heksagon
	var border_col := Color(barrier_color.r, barrier_color.g, barrier_color.b, alpha * 0.9)
	var closed_points := hex_points.duplicate()
	closed_points.append(hex_points[0])
	draw_polyline(closed_points, border_col, 2.5)

	# 3. Garis Batas Dalam Tipis
	var inner_points := PackedVector2Array()
	for i in range(6):
		var angle := deg_to_rad(60.0 * i - 30.0)
		inner_points.append(Vector2(cos(angle), sin(angle)) * (r * 0.72))
	var inner_closed := inner_points.duplicate()
	inner_closed.append(inner_points[0])
	draw_polyline(inner_closed, Color(1.0, 1.0, 1.0, alpha * 0.6), 1.2)

	# 4. Bracket sudut heksagon dan aksen digital
	for i in range(6):
		var pt := hex_points[i]
		var bracket_pt := pt * 1.15
		draw_line(pt, bracket_pt, Color(1.0, 1.0, 1.0, alpha * 0.8), 2.0)
		draw_circle(bracket_pt, 2.0, border_col)
