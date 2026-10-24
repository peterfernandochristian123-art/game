class_name VFXLightningArc
extends Node2D

## Efek Visual Sambaran Listrik & Busur Plasma Realistis (Realistic Arc Lightning)
## Menghasilkan rantai petir bergerigi bercabang banyak dengan inti putih panas
## dan pendaran plasma neon di sekelilingnya.

@export var arc_color: Color = Color(0.3, 0.95, 1.0, 1.0)
@export var duration_seconds: float = 0.22

var _elapsed: float = 0.0
var _active: bool = false
var _branches: Array[PackedVector2Array] = []

func _ready() -> void:
	z_index = 59

func trigger_arc(start_pos: Vector2, end_pos: Vector2, custom_color: Color = Color.TRANSPARENT, duration: float = 0.22, fork_count: int = 3) -> void:
	global_position = start_pos
	duration_seconds = duration
	if custom_color != Color.TRANSPARENT:
		arc_color = custom_color

	_elapsed = 0.0
	_active = true
	_generate_branches(end_pos - start_pos, fork_count)
	queue_redraw()

func _generate_branches(target_offset: Vector2, fork_count: int) -> void:
	_branches.clear()
	var main_branch := _create_jagged_line(Vector2.ZERO, target_offset, 6, 22.0)
	_branches.append(main_branch)

	for f in range(fork_count):
		if main_branch.size() > 3:
			var rand_idx := randi_range(1, main_branch.size() - 2)
			var fork_origin := main_branch[rand_idx]
			var fork_dir := (target_offset.normalized() + Vector2(randf_range(-0.8, 0.8), randf_range(-0.8, 0.8))).normalized()
			var fork_end := fork_origin + fork_dir * randf_range(25.0, 65.0)
			_branches.append(_create_jagged_line(fork_origin, fork_end, 3, 14.0))

func _create_jagged_line(from: Vector2, to: Vector2, segments: int, jitter: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(from)
	var delta := to - from
	var perp := delta.orthogonal().normalized()
	for i in range(1, segments):
		var frac := float(i) / float(segments)
		var center := from + delta * frac
		var off := perp * randf_range(-jitter, jitter)
		pts.append(center + off)
	pts.append(to)
	return pts

func _process(delta: float) -> void:
	if not _active:
		return

	_elapsed += delta
	if _elapsed >= duration_seconds:
		_active = false
		queue_free()
	else:
		# Acak ulang sedikit koordinat setiap frame untuk efek flickering petir hidup
		if randf() < 0.4 and _branches.size() > 0:
			for i in range(1, _branches[0].size() - 1):
				_branches[0][i] += Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
		queue_redraw()

func _draw() -> void:
	if not _active:
		return

	var progress := _elapsed / duration_seconds
	var alpha := clampf(1.0 - progress, 0.0, 1.0)
	# Efek kedip intens
	var flicker := randf_range(0.7, 1.0)

	for b_idx in range(_branches.size()):
		var branch := _branches[b_idx]
		var is_main: bool = (b_idx == 0)
		var base_w: float = 3.2 if is_main else 1.8

		# 1. Aura Cahaya Luar
		var glow_col := Color(arc_color.r, arc_color.g, arc_color.b, alpha * flicker * 0.45)
		draw_polyline(branch, glow_col, base_w * 2.2)

		# 2. Batang Petir Berwarna
		var mid_col := Color(arc_color.r, arc_color.g, arc_color.b, alpha * flicker * 0.9)
		draw_polyline(branch, mid_col, base_w)

		# 3. Inti Listrik Putih Menyengat
		var core_col := Color(1.0, 1.0, 1.0, alpha * flicker * 0.98)
		draw_polyline(branch, core_col, maxf(1.0, base_w * 0.35))
