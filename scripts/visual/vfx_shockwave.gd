class_name VFXShockwave
extends Node2D

## Efek Visual Gelombang Kejut & Cincin Distorsi Realistis (Realistic High-Impact Shockwave)
## Menampilkan cincin kompresi plasma berkecepatan tinggi, cincin refraksi sekunder,
## suar ledakan radial, dan hembusan debu di permukaan lantai.

@export var wave_color: Color = Color(0.2, 0.95, 1.0, 1.0)
@export var max_radius: float = 120.0
@export var duration_seconds: float = 0.35
@export var ring_width: float = 4.0

var _elapsed: float = 0.0
var _active: bool = false
var _floor_y: float = 295.0
var _dust_particles: Array[Dictionary] = []

func _ready() -> void:
	z_index = 55

func trigger_shockwave(pos: Vector2, radius: float = 120.0, custom_color: Color = Color.TRANSPARENT, duration: float = 0.35, width: float = 4.0) -> void:
	global_position = pos
	max_radius = radius
	duration_seconds = duration
	ring_width = width
	if custom_color != Color.TRANSPARENT:
		wave_color = custom_color

	_elapsed = 0.0
	_active = true

	# Hasilkan percikan debu jika dekat dengan lantai
	_dust_particles.clear()
	var dist_to_floor: float = abs(_floor_y - pos.y)
	if dist_to_floor < radius * 1.2:
		for i in range(8):
			var dir_x: float = -1.0 if (i % 2 == 0) else 1.0
			_dust_particles.append({
				"pos": Vector2(dir_x * randf_range(10.0, 30.0), _floor_y - pos.y),
				"vel": Vector2(dir_x * randf_range(60.0, 180.0), randf_range(-40.0, -10.0)),
				"size": randf_range(3.0, 7.0),
				"rot": randf_range(0.0, TAU),
				"rot_v": randf_range(-4.0, 4.0)
			})

	queue_redraw()

func _process(delta: float) -> void:
	if not _active:
		return

	_elapsed += delta

	# Update debu tanah
	for p in _dust_particles:
		p["pos"] += p["vel"] * delta
		p["vel"].x *= 0.92
		p["vel"].y += 120.0 * delta # gravitasi ringan
		p["rot"] += p["rot_v"] * delta

	if _elapsed >= duration_seconds:
		_active = false
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	if not _active:
		return

	var progress := _elapsed / duration_seconds
	# Ekspansi eksplosif tajam di awal (akar kuadrat)
	var ease_expand := sqrt(progress)
	var current_rad := max_radius * ease_expand
	var alpha := clampf(1.0 - progress, 0.0, 1.0)
	var current_w := maxf(1.0, ring_width * (1.0 - progress * 0.7))

	# 1. Cincin Refraksi Luar (Outer Bloom Halo)
	var halo_col := Color(wave_color.r, wave_color.g, wave_color.b, alpha * 0.4)
	draw_arc(Vector2.ZERO, current_rad, 0.0, TAU, 32, halo_col, current_w * 2.2)

	# 2. Cincin Kompresi Utama (Main Shock Ring)
	var main_col := Color(wave_color.r, wave_color.g, wave_color.b, alpha * 0.85)
	draw_arc(Vector2.ZERO, current_rad, 0.0, TAU, 32, main_col, current_w)

	# 3. Inti Plasma Putih Terang
	var core_col := Color(1.0, 1.0, 1.0, alpha * 0.95)
	draw_arc(Vector2.ZERO, current_rad, 0.0, TAU, 32, core_col, maxf(1.0, current_w * 0.4))

	# 4. Cincin Riak Sekunder Mengikuti di Belakang (Secondary Echo Ripple)
	if current_rad > 15.0:
		var echo_rad := current_rad * 0.75
		var echo_col := Color(wave_color.r, wave_color.g, wave_color.b, alpha * 0.35)
		draw_arc(Vector2.ZERO, echo_rad, 0.0, TAU, 24, echo_col, current_w * 0.7)

	# 5. Suar Jarum Radial (Concussive Needle Rays)
	var ray_count := 8
	var ray_len := current_rad * 1.2
	for i in range(ray_count):
		var a := (TAU / float(ray_count)) * float(i) + (progress * 0.4)
		var p_start := Vector2(cos(a), sin(a)) * (current_rad * 0.8)
		var p_end := Vector2(cos(a), sin(a)) * ray_len
		draw_line(p_start, p_end, Color(wave_color.r, wave_color.g, wave_color.b, alpha * 0.5), 1.5)

	# 6. Gumpalan Debu Hembusan Lantai
	for p in _dust_particles:
		var d_col := Color(wave_color.r * 0.6 + 0.3, wave_color.g * 0.6 + 0.3, wave_color.b * 0.6 + 0.3, alpha * 0.65)
		var s: float = p["size"] * (1.0 - progress * 0.5)
		draw_circle(p["pos"], s, d_col)
		draw_circle(p["pos"], s * 0.5, Color(1.0, 1.0, 1.0, alpha * 0.4))
