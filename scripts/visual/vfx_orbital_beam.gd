class_name VFXOrbitalBeam
extends Node2D

## Efek Visual Laser Partikel & Berkas Energi (Bulwark Orbital Cannon & Pulsar Photon Railgun)
## Menampilkan pilar/berkas sinar laser partikel, cincin resonansi foton, dan kilatan listrik

@export var beam_color: Color = Color(1.0, 0.6, 0.15, 1.0)
@export var beam_length: float = 700.0
@export var beam_width: float = 48.0
@export var duration_seconds: float = 0.45

var _elapsed: float = 0.0
var _active: bool = false
var _direction: Vector2 = Vector2.DOWN
var _sparks: Array[Vector2] = []

func _ready() -> void:
	z_index = 54

func trigger_beam(origin: Vector2, dir: Vector2 = Vector2.DOWN, length: float = 700.0, width: float = 48.0, custom_color: Color = Color.TRANSPARENT, duration: float = 0.45) -> void:
	global_position = origin
	_direction = dir.normalized()
	beam_length = length
	beam_width = width
	duration_seconds = duration
	if custom_color != Color.TRANSPARENT:
		beam_color = custom_color

	_elapsed = 0.0
	_active = true

	# Hasilkan offset percikan listrik di sepanjang berkas
	_sparks.clear()
	var spark_count := 8
	for i in range(spark_count):
		var frac := float(i) / float(spark_count)
		var perp := _direction.orthogonal()
		_sparks.append(perp * randf_range(-width * 0.6, width * 0.6))

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
	var end_pt := _direction * beam_length
	var perp := _direction.orthogonal()

	# Efek kemunculan cepat (flash) lalu meluruh
	var width_scale := 1.0
	if progress < 0.15:
		width_scale = progress / 0.15
	else:
		width_scale = 1.0 - (progress - 0.15) * 0.8
	var current_w := beam_width * width_scale

	# 1. Berkas Luar / Glow Luas
	var outer_col := Color(beam_color.r, beam_color.g, beam_color.b, alpha * 0.35)
	var p1 := -perp * (current_w * 0.5)
	var p2 := perp * (current_w * 0.5)
	var p3 := end_pt + perp * (current_w * 0.5)
	var p4 := end_pt - perp * (current_w * 0.5)
	draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), outer_col)

	# 2. Berkas Menengah
	var mid_col := Color(beam_color.r, beam_color.g, beam_color.b, alpha * 0.75)
	var m1 := -perp * (current_w * 0.25)
	var m2 := perp * (current_w * 0.25)
	var m3 := end_pt + perp * (current_w * 0.25)
	var m4 := end_pt - perp * (current_w * 0.25)
	draw_colored_polygon(PackedVector2Array([m1, m2, m3, m4]), mid_col)

	# 3. Inti Sinar Putih Terang
	var core_col := Color(1.0, 1.0, 1.0, alpha * 0.95)
	draw_line(Vector2.ZERO, end_pt, core_col, maxf(2.0, current_w * 0.18))

	# 4. Pilinan Heliks Plasma Mengitari Sinar (Helical Ion Spiral Strands)
	var helix_pts_a := PackedVector2Array()
	var helix_pts_b := PackedVector2Array()
	var helix_segs := 24
	for h in range(helix_segs + 1):
		var frac := float(h) / float(helix_segs)
		var center_pt := _direction * (beam_length * frac)
		var phase := frac * TAU * 3.0 + progress * 8.0
		var r_helix := current_w * 0.45 * sin(frac * PI)
		helix_pts_a.append(center_pt + perp * sin(phase) * r_helix)
		helix_pts_b.append(center_pt - perp * sin(phase) * r_helix)
	var helix_col := Color(beam_color.r, beam_color.g, beam_color.b, alpha * 0.7)
	draw_polyline(helix_pts_a, helix_col, 1.6)
	draw_polyline(helix_pts_b, Color(1.0, 1.0, 1.0, alpha * 0.6), 1.2)

	# 5. Cincin Resonansi Foton Bergerak
	var ring_count := 4
	for r in range(ring_count):
		var ring_frac := fposmod(float(r) / float(ring_count) + progress * 2.0, 1.0)
		var ring_center := _direction * (beam_length * ring_frac)
		var ring_rad := current_w * 0.6 * (1.0 + ring_frac * 0.4)
		var ring_col := Color(beam_color.r, beam_color.g, beam_color.b, alpha * 0.8)
		var ring_pts := PackedVector2Array()
		var segs := 12
		for s in range(segs):
			var a := (TAU / float(segs)) * float(s)
			var pt := ring_center + (perp * cos(a) * ring_rad) + (_direction * sin(a) * (ring_rad * 0.3))
			ring_pts.append(pt)
		ring_pts.append(ring_pts[0])
		draw_polyline(ring_pts, ring_col, 2.0)

	# 6. Kilatan Busur Listrik Flank
	for i in range(_sparks.size()):
		var frac := float(i) / float(_sparks.size())
		var pt_on_beam := _direction * (beam_length * frac) + _sparks[i]
		var jitter := Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
		draw_line(pt_on_beam, pt_on_beam + jitter, Color(1.0, 1.0, 1.0, alpha * 0.85), 1.5)

	# 7. Ledakan Korona Impak di Ujung Sinar (Terminal Impact Corona)
	var blast_rad := current_w * 1.5 * (0.8 + progress * 0.6)
	draw_circle(end_pt, blast_rad * 0.5, Color(1.0, 1.0, 1.0, alpha * 0.95))
	draw_arc(end_pt, blast_rad, 0.0, TAU, 20, Color(beam_color.r, beam_color.g, beam_color.b, alpha * 0.8), 2.5)
