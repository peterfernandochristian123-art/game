class_name VFXImpactBurst
extends Node2D

## Tekken 2-Style Impact Burst — Tekken 2 Combat Register
## Flash tebal + ledakan terarah (directional burst) + cincin syok,
## digambar prosedural dengan palet VfxProfile penyerang.
## Satu burst kuat per tumbukan — bukan spam partikel. Self-freeing.

const Style = VfxProfile.ImpactStyle

@export var primary_color: Color = Color(0.85, 0.88, 0.95, 1.0)
@export var secondary_color: Color = Color(0.45, 0.48, 0.58, 1.0)
@export var spark_color: Color = Color.WHITE
@export var flash_color: Color = Color.WHITE
@export var impact_style: int = Style.STARBURST
@export var intensity_level: int = 1 ## 0=Light, 1=Medium, 2=Heavy, 3=Counter
@export var duration_seconds: float = 0.32
@export var hit_direction: Vector2 = Vector2.RIGHT

var _elapsed: float = 0.0
var _active: bool = false
var _ray_angles: Array[float] = []
var _ray_lengths: Array[float] = []

func _ready() -> void:
	z_index = 59

func trigger_impact(pos: Vector2, level: int = 1, profile: VfxProfile = null, dir: Vector2 = Vector2.RIGHT) -> void:
	global_position = pos
	intensity_level = clampi(level, 0, 3)
	hit_direction = dir.normalized() if dir.length_squared() > 0.01 else Vector2.RIGHT

	if profile != null:
		primary_color = profile.primary_color
		secondary_color = profile.secondary_color
		spark_color = profile.spark_color
		flash_color = profile.flash_color
		impact_style = int(profile.impact_style)

	match intensity_level:
		0: duration_seconds = 0.2
		1: duration_seconds = 0.26
		2: duration_seconds = 0.32
		3: duration_seconds = 0.4

	_elapsed = 0.0
	_active = true

	# Ulin cone/rays deterministik-acak untuk ledakan radial
	_ray_angles.clear()
	_ray_lengths.clear()
	var ray_count := 6 + intensity_level * 3
	for i in range(ray_count):
		var base_angle := (TAU / float(ray_count)) * float(i) + randf_range(-0.18, 0.18)
		_ray_angles.append(base_angle)
		_ray_lengths.append(randf_range(0.7, 1.35))

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

func is_active() -> bool:
	return _active

func _base_radius() -> float:
	match intensity_level:
		0: return 22.0
		1: return 34.0
		2: return 48.0
		3: return 64.0
	return 34.0

func _draw() -> void:
	if not _active:
		return

	var progress := clampf(_elapsed / duration_seconds, 0.0, 1.0)
	var alpha := clampf(1.0 - progress, 0.0, 1.0)
	var base_r := _base_radius()

	# Pop cepat di awal (Tekken 2 "snap"), lalu melambat & memudar
	var pop := 1.0
	if progress < 0.22:
		pop = progress / 0.22 * 1.25
	else:
		pop = 1.25 - (progress - 0.22) * 0.95
	var radius := base_r * pop

	var dir_angle := hit_direction.angle()

	# 1. FLASH PUTIH INTI + BLOOM CAHAYA — selalu ada, tebal, snap-in
	var core_rad := maxf(2.0, radius * (0.55 - progress * 0.3))
	# Bloom luar besar (efek cahaya menyebar)
	draw_circle(Vector2.ZERO, core_rad * 3.2, Color(primary_color.r, primary_color.g, primary_color.b, alpha * 0.12))
	draw_circle(Vector2.ZERO, core_rad * 2.4, Color(flash_color.r, flash_color.g, flash_color.b, alpha * 0.22))
	draw_circle(Vector2.ZERO, core_rad * 1.6, Color(flash_color.r, flash_color.g, flash_color.b, alpha * 0.55))
	draw_circle(Vector2.ZERO, core_rad, Color(1.0, 1.0, 1.0, alpha * 0.95))

	# 2. Bentuk ledakan per impact_style
	match impact_style:
		Style.STARBURST:
			_draw_starburst(radius, progress, alpha)
		Style.RING:
			_draw_ring_burst(radius, progress, alpha)
		Style.CLEAVE:
			_draw_cleave(radius, progress, alpha, dir_angle)
		Style.LANCE:
			_draw_lance(radius, progress, alpha, dir_angle)
		Style.NOVA:
			_draw_nova(radius, progress, alpha)
		Style.SPIKE:
			_draw_spike(radius, progress, alpha)
		_:
			_draw_starburst(radius, progress, alpha)

	# 3. Directional burst chevrons — garis momentum searah pukulan
	if intensity_level >= 1:
		var chev_alpha := alpha * 0.9
		for i in range(3):
			var offset := radius * (0.9 + float(i) * 0.55) * (0.6 + progress * 0.8)
			var size := radius * (0.5 - float(i) * 0.12)
			var center := hit_direction * offset
			var perp := Vector2(-hit_direction.y, hit_direction.x)
			var tip := center + hit_direction * size
			var a := center + perp * size * 0.7
			var b := center - perp * size * 0.7
			var col := Color(spark_color.r, spark_color.g, spark_color.b, chev_alpha * (1.0 - float(i) * 0.3))
			draw_line(a, tip, col, 2.2 + float(intensity_level))
			draw_line(b, tip, col, 2.2 + float(intensity_level))

	# 4. Cincin syok luar (semua style) — sell the weight + glow
	var ring_rad := radius * (1.0 + progress * 1.3)
	var ring_col := Color(primary_color.r, primary_color.g, primary_color.b, alpha * 0.75)
	draw_arc(Vector2.ZERO, ring_rad, 0.0, TAU, 40, ring_col, 2.0 + float(intensity_level) * 1.2)
	draw_arc(Vector2.ZERO, ring_rad, 0.0, TAU, 40, Color(flash_color.r, flash_color.g, flash_color.b, alpha * 0.28), 5.0 + float(intensity_level) * 1.5)
	# Bloom halo tambahan di puncak tumbukan
	if progress < 0.5:
		var halo_a := alpha * (1.0 - progress / 0.5) * 0.18
		draw_circle(Vector2.ZERO, ring_rad * 0.75, Color(primary_color.r, primary_color.g, primary_color.b, halo_a))

func _draw_starburst(radius: float, progress: float, alpha: float) -> void:
	# Sinar radial tajam + bintang 4-titik utama (✦)
	for i in range(_ray_angles.size()):
		var angle := _ray_angles[i]
		var r_len := radius * _ray_lengths[i] * (1.0 + progress * 0.5)
		var pt := Vector2(cos(angle), sin(angle)) * r_len
		var ray_col := Color(primary_color.r, primary_color.g, primary_color.b, alpha * 0.9)
		draw_line(Vector2.ZERO, pt, ray_col, 2.2)
		draw_line(Vector2.ZERO, pt * 0.55, Color(flash_color.r, flash_color.g, flash_color.b, alpha), 1.2)
	_draw_star(Vector2.ZERO, radius * 0.85, radius * 0.22, 4, progress * 0.6, Color(primary_color.r, primary_color.g, primary_color.b, alpha * 0.95))
	_draw_star(Vector2.ZERO, radius * 0.5, radius * 0.14, 4, -progress * 0.4, Color(1.0, 1.0, 1.0, alpha * 0.9))

func _draw_ring_burst(radius: float, progress: float, alpha: float) -> void:
	# Dua cincin konsentris + rune ticks (segel / barrier)
	for i in range(2):
		var rr := radius * (0.55 + float(i) * 0.45 + progress * 0.6)
		var a := alpha * (0.9 - float(i) * 0.35)
		var col := Color(primary_color.r, primary_color.g, primary_color.b, a) if i == 0 else Color(spark_color.r, spark_color.g, spark_color.b, a)
		draw_arc(Vector2.ZERO, rr, 0.0, TAU, 44, col, 3.5 - float(i) * 1.5)
	for i in range(8):
		var ang := (TAU / 8.0) * float(i) + progress * 1.5
		var inner := Vector2(cos(ang), sin(ang)) * radius * 0.75
		var outer := Vector2(cos(ang), sin(ang)) * radius * 1.15
		draw_line(inner, outer, Color(flash_color.r, flash_color.g, flash_color.b, alpha * 0.8), 2.0)

func _draw_cleave(radius: float, progress: float, alpha: float, dir_angle: float) -> void:
	# Busur tebasan lebar searah pukulan (crescent arc)
	var arc_col := Color(primary_color.r, primary_color.g, primary_color.b, alpha * 0.95)
	var arc_col2 := Color(flash_color.r, flash_color.g, flash_color.b, alpha * 0.85)
	var spread := deg_to_rad(95.0)
	var sweep := spread * (1.0 - progress * 0.45)
	var arc_r := radius * (0.8 + progress * 0.5)
	draw_arc(Vector2.ZERO, arc_r, dir_angle - sweep, dir_angle + sweep, 28, arc_col, 4.5 + float(intensity_level))
	draw_arc(Vector2.ZERO, arc_r * 0.62, dir_angle - sweep * 0.8, dir_angle + sweep * 0.8, 24, arc_col2, 2.2)
	# Sparks di ujung tebasan
	for i in range(_ray_angles.size()):
		var ang := dir_angle + (_ray_angles[i] - PI) * 0.35
		var pt := Vector2(cos(ang), sin(ang)) * radius * _ray_lengths[i]
		draw_line(Vector2.ZERO, pt, Color(spark_color.r, spark_color.g, spark_color.b, alpha * 0.7), 1.6)

func _draw_lance(radius: float, progress: float, alpha: float, dir_angle: float) -> void:
	# Tusukan lancip memanjang searah pukulan (beam thrust)
	var len_fwd := radius * (1.6 + progress * 1.2)
	var len_back := radius * 0.55
	var width := radius * (0.42 - progress * 0.18)
	var fwd := Vector2(cos(dir_angle), sin(dir_angle))
	var perp := Vector2(-fwd.y, fwd.x)
	# Main lance body (segitiga memanjang)
	var tip := fwd * len_fwd
	var base_a := perp * width
	var base_b := perp * -width - fwd * len_back
	var body := PackedVector2Array([tip, base_a, Vector2(0, 0), base_b])
	draw_colored_polygon(body, Color(primary_color.r, primary_color.g, primary_color.b, alpha * 0.85))
	var tip2 := fwd * len_fwd * 0.75
	var inner := PackedVector2Array([tip2, perp * width * 0.45, Vector2.ZERO, perp * -width * 0.45])
	draw_colored_polygon(inner, Color(flash_color.r, flash_color.g, flash_color.b, alpha * 0.9))
	# Sparks di sisi
	for i in range(_ray_angles.size()):
		var pt := Vector2(cos(_ray_angles[i]), sin(_ray_angles[i])) * radius * 0.9
		draw_line(Vector2.ZERO, pt, Color(spark_color.r, spark_color.g, spark_color.b, alpha * 0.6), 1.4)

func _draw_nova(radius: float, progress: float, alpha: float) -> void:
	# Korona 360 derajat — cincin api + sinar panjang (supernova)
	var corona := radius * (0.7 + progress * 0.75)
	draw_circle(Vector2.ZERO, corona, Color(primary_color.r, primary_color.g, primary_color.b, alpha * 0.35))
	draw_arc(Vector2.ZERO, corona, 0.0, TAU, 44, Color(primary_color.r, primary_color.g, primary_color.b, alpha * 0.9), 4.0)
	draw_arc(Vector2.ZERO, corona * 0.7, 0.0, TAU, 36, Color(flash_color.r, flash_color.g, flash_color.b, alpha * 0.8), 2.0)
	for i in range(_ray_angles.size()):
		var ang := _ray_angles[i]
		var pt := Vector2(cos(ang), sin(ang)) * radius * _ray_lengths[i] * 1.35
		draw_line(Vector2.ZERO, pt, Color(spark_color.r, spark_color.g, spark_color.b, alpha * 0.8), 2.0)

func _draw_spike(radius: float, progress: float, alpha: float) -> void:
	# Paku/tanah memantul ke atas-luar (seismic)
	var spike_col := Color(primary_color.r, primary_color.g, primary_color.b, alpha * 0.9)
	var inner_col := Color(secondary_color.r, secondary_color.g, secondary_color.b, alpha * 0.85)
	for i in range(_ray_angles.size()):
		var ang := _ray_angles[i]
		# Condong ke atas agar terasa "tanah terbelah"
		var biased := Vector2(cos(ang), sin(ang) - 0.55).normalized()
		var len_spike := radius * _ray_lengths[i] * (0.75 + progress * 0.5)
		var pt := biased * len_spike
		var perp := Vector2(-biased.y, biased.x) * radius * 0.09
		var tri := PackedVector2Array([pt + biased * radius * 0.22, perp, -perp])
		draw_colored_polygon(tri, spike_col)
		draw_line(Vector2.ZERO, pt, inner_col, 2.0)

func _draw_star(center: Vector2, outer_rad: float, inner_rad: float, points: int, rot: float, col: Color) -> void:
	var poly := PackedVector2Array()
	var total_pts := points * 2
	var step := TAU / float(total_pts)
	for i in range(total_pts):
		var rad := outer_rad if (i % 2 == 0) else inner_rad
		var a := rot + float(i) * step
		poly.append(center + Vector2(cos(a), sin(a)) * rad)
	draw_colored_polygon(poly, col)
