class_name VFXShurikenStorm
extends Node2D

## Efek Visual Badai Shuriken Foton (Phantom-9 Kage Skill 2 Ranged & Unit-0)
## Menampilkan 3 proyektil shuriken berputar cepat menyebar dalam sudut kipas dengan jejak cahaya neon

@export var shuriken_color: Color = Color(1.0, 0.2, 0.3, 1.0)
@export var speed: float = 650.0
@export var duration_seconds: float = 0.35

class Shuriken:
	var pos: Vector2
	var dir: Vector2
	var rot: float
	var trail: Array[Vector2] = []

var _shurikens: Array[Shuriken] = []
var _elapsed: float = 0.0
var _active: bool = false
var _facing: int = 1

func _ready() -> void:
	z_index = 53

func trigger_shurikens(pos: Vector2, facing_dir: int = 1, custom_color: Color = Color.TRANSPARENT, duration: float = 0.35) -> void:
	global_position = pos
	_facing = facing_dir
	duration_seconds = duration
	if custom_color != Color.TRANSPARENT:
		shuriken_color = custom_color

	_elapsed = 0.0
	_active = true

	# 3 Shuriken menyebar -15°, 0°, +15°
	_shurikens.clear()
	var angles := [-0.26, 0.0, 0.26] # Dalam radian (~15 derajat)
	for a in angles:
		var s := Shuriken.new()
		s.pos = Vector2.ZERO
		var base_dir := Vector2(float(_facing), 0.0)
		s.dir = base_dir.rotated(a)
		s.rot = randf_range(0.0, TAU)
		_shurikens.append(s)

	queue_redraw()

func _process(delta: float) -> void:
	if not _active:
		return

	_elapsed += delta
	for s in _shurikens:
		s.trail.append(s.pos)
		if s.trail.size() > 6:
			s.trail.pop_front()
		s.pos += s.dir * (speed * delta)
		s.rot += delta * 28.0 # Putaran sangat cepat

	if _elapsed >= duration_seconds:
		_active = false
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	if not _active:
		return

	var progress := _elapsed / duration_seconds
	var alpha := clampf(1.0 - progress * 0.5, 0.0, 1.0)

	for s in _shurikens:
		# 1. Jejak Cahaya Neon (Trail)
		if s.trail.size() >= 2:
			for t in range(s.trail.size() - 1):
				var t_frac := float(t) / float(s.trail.size())
				var t_col := Color(shuriken_color.r, shuriken_color.g, shuriken_color.b, t_frac * alpha * 0.7)
				draw_line(s.trail[t], s.trail[t + 1], t_col, 2.0 * t_frac + 0.5)

		# 2. Gambar 4-Point Shuriken Berputar
		var blade_len := 9.0
		var inner_rad := 2.5
		var pts := PackedVector2Array()
		for i in range(4):
			var tip_ang := s.rot + (TAU / 4.0) * float(i)
			var indent_ang := tip_ang + (TAU / 8.0)
			pts.append(s.pos + Vector2(cos(tip_ang), sin(tip_ang)) * blade_len)
			pts.append(s.pos + Vector2(cos(indent_ang), sin(indent_ang)) * inner_rad)

		var fill_col := Color(shuriken_color.r, shuriken_color.g, shuriken_color.b, alpha * 0.95)
		draw_colored_polygon(pts, fill_col)
		# Garis batas tajam putih
		var closed_pts := pts.duplicate()
		closed_pts.append(pts[0])
		draw_polyline(closed_pts, Color(1.0, 1.0, 1.0, alpha), 1.0)
		# Inti tengah
		draw_circle(s.pos, 1.5, Color.WHITE)
