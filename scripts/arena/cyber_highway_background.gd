class_name CyberHighwayBackground
extends Node2D

## Komponen Visual Latar Belakang Jalan Tol Cyberpunk & Hujan Neon (Rainy Overpass)
## Menggambar hujan pixel dinamis dengan cipratan halus di aspal, papan reklame kanji neon
## raksasa magenta & sian, serta lalu lintas mobil melayang (hover-traffic) berkecepatan tinggi.

var tick: int = 0
var rain_drops: Array[Vector2] = []
var rain_speed: float = 480.0 # px per second
var rain_angle_x: float = -120.0 # miring ke kiri karena angin

var traffic_cars: Array[Dictionary] = []

func _ready() -> void:
	set_physics_process(true)
	_generate_rain()
	_generate_traffic()

func _generate_rain() -> void:
	rain_drops.clear()
	# 140 rintik hujan deterministik di langit kota New Babel
	for i in range(140):
		var x: float = fmod(float(i * 101 + 37), 1440.0)
		var y: float = fmod(float(i * 73 + 19), 320.0)
		rain_drops.append(Vector2(x, y))

func _generate_traffic() -> void:
	traffic_cars.clear()
	# 4 mobil melayang di bawah jalan layang pada kedalaman berbeda
	traffic_cars.append({"pos": Vector2(-50.0, 345.0), "speed": 160.0, "col": Color(1.0, 0.25, 0.35), "is_tail": true})
	traffic_cars.append({"pos": Vector2(400.0, 345.0), "speed": 190.0, "col": Color(1.0, 0.25, 0.35), "is_tail": true})
	traffic_cars.append({"pos": Vector2(1480.0, 355.0), "speed": -180.0, "col": Color(1.0, 0.95, 0.6), "is_tail": false})
	traffic_cars.append({"pos": Vector2(900.0, 355.0), "speed": -210.0, "col": Color(1.0, 0.95, 0.6), "is_tail": false})

func _physics_process(delta: float) -> void:
	tick = (tick + 1) % 360

	# 1. Update Rintik Hujan
	for i in range(rain_drops.size()):
		var pt: Vector2 = rain_drops[i]
		pt.y += rain_speed * delta
		pt.x += rain_angle_x * delta
		if pt.y > 310.0 or pt.x < -40.0:
			pt.y = randf_range(-40.0, 0.0)
			pt.x = randf_range(0.0, 1480.0)
		rain_drops[i] = pt

	# 2. Update Traffic Mobil Melayang
	for car in traffic_cars:
		car["pos"].x += car["speed"] * delta
		if car["speed"] > 0 and car["pos"].x > 1520.0:
			car["pos"].x = -80.0
		elif car["speed"] < 0 and car["pos"].x < -80.0:
			car["pos"].x = 1520.0

	queue_redraw()

func _draw() -> void:
	# 1. Menara Gedung Megacity Gelap di Latar Belakang
	_draw_city_skyline()

	# 2. Papan Reklame Holografis Neon Raksasa (Cyberpunk Billboards)
	_draw_hologram_billboards()

	# 3. Jalur Mobil Melayang di Bawah Jalan Tol (Speed Streaks)
	_draw_hover_traffic()

	# 4. Garis-garis Rintik Hujan Pixel (Pixel Rain Streaks)
	var rain_color := Color(0.65, 0.85, 1.0, 0.55)
	for pt in rain_drops:
		draw_line(pt, pt + Vector2(-3.0, 12.0), rain_color, 1.0)
		# Cipratan air jika dekat platform
		if pt.y >= 290.0 and pt.y <= 305.0:
			draw_circle(pt + Vector2(-3, 12), 1.2, Color(0.7, 0.9, 1.0, 0.45))

func _draw_city_skyline() -> void:
	# Gedung-gedung siluet gelap
	draw_rect(Rect2(60, 90, 160, 240), Color(0.05, 0.06, 0.1, 1.0))
	draw_rect(Rect2(320, 60, 180, 270), Color(0.04, 0.05, 0.08, 1.0))
	draw_rect(Rect2(600, 40, 220, 290), Color(0.06, 0.07, 0.11, 1.0))
	draw_rect(Rect2(920, 70, 170, 260), Color(0.05, 0.06, 0.09, 1.0))
	draw_rect(Rect2(1170, 100, 180, 230), Color(0.04, 0.05, 0.08, 1.0))

func _draw_hologram_billboards() -> void:
	# Billboard 1: Magenta / Pink Neon "NEO TOKYO" (Kiri)
	var b1_pulse: float = 0.8 + 0.2 * sin(float(tick) * 0.1)
	var pink_col := Color(1.0, 0.15, 0.6, b1_pulse)
	draw_rect(Rect2(80, 120, 120, 45), Color(0.1, 0.02, 0.08, 0.85), true)
	draw_rect(Rect2(80, 120, 120, 45), pink_col, false, 2.0)
	draw_rect(Rect2(90, 135, 100, 14), Color(1.0, 0.3, 0.7, b1_pulse * 0.9), true)
	# Teks siluet kanji / retro bar
	draw_line(Vector2(95, 142), Vector2(185, 142), Color(1, 1, 1, b1_pulse), 2.0)

	# Billboard 2: Cyan Neon "ZERO CORP" (Tengah)
	var b2_pulse: float = 0.85 + 0.15 * cos(float(tick) * 0.12)
	var cyan_col := Color(0.2, 0.95, 1.0, b2_pulse)
	draw_rect(Rect2(640, 80, 140, 50), Color(0.02, 0.08, 0.12, 0.85), true)
	draw_rect(Rect2(640, 80, 140, 50), cyan_col, false, 2.0)
	draw_circle(Vector2(710, 105), 14.0, Color(0.2, 0.95, 1.0, b2_pulse * 0.4))
	draw_circle(Vector2(710, 105), 6.0, Color(1, 1, 1, b2_pulse))

	# Billboard 3: Amber Neon "HIGHWAY 09" (Kanan)
	var b3_pulse: float = 0.8 + 0.2 * sin(float(tick) * 0.09 + 1.0)
	var gold_col := Color(1.0, 0.75, 0.2, b3_pulse)
	draw_rect(Rect2(1200, 130, 110, 40), Color(0.1, 0.08, 0.02, 0.85), true)
	draw_rect(Rect2(1200, 130, 110, 40), gold_col, false, 2.0)
	draw_line(Vector2(1215, 150), Vector2(1295, 150), gold_col, 3.0)

func _draw_hover_traffic() -> void:
	for car in traffic_cars:
		var p: Vector2 = car["pos"]
		var col: Color = car["col"]
		var is_tail: bool = car["is_tail"]
		
		# Bodi mobil siluet
		draw_rect(Rect2(p.x, p.y, 22, 6), Color(0.06, 0.08, 0.12, 0.9))
		
		# Jejak cahaya kecepatan (Speed Streaks)
		if is_tail:
			draw_line(p + Vector2(20, 3), p + Vector2(4, 3), col, 2.0)
			draw_line(p + Vector2(4, 3), p + Vector2(-35, 3), Color(col.r, col.g, col.b, 0.4), 1.5)
		else:
			draw_line(p + Vector2(2, 3), p + Vector2(18, 3), col, 2.0)
			draw_line(p + Vector2(18, 3), p + Vector2(55, 3), Color(col.r, col.g, col.b, 0.4), 1.5)
