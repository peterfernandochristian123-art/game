class_name CyberCityBackground
extends Node2D

## Komponen Visual Latar Belakang Kota New Babel-01 Dinamis (Story 7.2)
## Menggambar jendela gedung pixel cyberpunk berkedip, lampu navigasi antena,
## dan hovercraft futuristik yang melintas di kejauhan pada kanvas 640x360.

var tick: int = 0
var hovercraft_pos: Vector2 = Vector2(-80.0, 110.0)
var hovercraft_speed: float = 65.0 # px per second

# Pola koordinat jendela tetap di Tower1 (X: 120-220), Tower2 (X: 640-760), Tower3 (X: 1180-1290)
var window_grid: Array[Vector2] = []

func _ready() -> void:
	set_physics_process(true)
	_generate_window_grid()

func _generate_window_grid() -> void:
	window_grid.clear()
	# Tower 1 windows
	for y in range(95, 260, 16):
		for x in range(130, 210, 14):
			if (x + y) % 5 != 0:
				window_grid.append(Vector2(x, y))

	# Tower 2 windows (Menara pusat tertinggi)
	for y in range(55, 260, 18):
		for x in range(652, 750, 16):
			if (x * 3 + y) % 7 != 0:
				window_grid.append(Vector2(x, y))

	# Tower 3 windows
	for y in range(105, 260, 16):
		for x in range(1192, 1280, 14):
			if (x + y * 2) % 6 != 0:
				window_grid.append(Vector2(x, y))

func _physics_process(delta: float) -> void:
	tick = (tick + 1) % 240

	# Gerakan hovercraft melintas horizontal di langit kota
	hovercraft_pos.x += hovercraft_speed * delta
	if hovercraft_pos.x > 1460.0:
		hovercraft_pos.x = -80.0
		hovercraft_pos.y = 80.0 + float((tick * 13) % 70)

	queue_redraw()

func _draw() -> void:
	# 1. Jendela pixel gedung bertingkat (Amber & Cyan neon)
	for i in range(window_grid.size()):
		var win_pos = window_grid[i]
		# Modulasi kedipan halus
		var flicker = sin(float(tick + i * 17) * 0.08)
		if flicker > -0.6:
			var is_cyan = (i % 4 == 0)
			var base_col = Color(0.3, 0.85, 1.0) if is_cyan else Color(0.95, 0.75, 0.35)
			var alpha = clampf(0.35 + flicker * 0.35, 0.15, 0.85)
			draw_rect(Rect2(win_pos.x, win_pos.y, 4, 6), Color(base_col.r, base_col.g, base_col.b, alpha))

	# 2. Lampu navigasi antena di puncak gedung
	var beacon_flash: bool = (tick % 60 < 30)
	if beacon_flash:
		# Puncak Tower 1
		draw_rect(Rect2(170, 75, 3, 3), Color(1.0, 0.2, 0.2, 0.95))
		# Puncak Tower 2 (Tower tertinggi)
		draw_rect(Rect2(700, 35, 3, 3), Color(0.2, 1.0, 0.4, 0.95))
		# Puncak Tower 3
		draw_rect(Rect2(1235, 85, 3, 3), Color(1.0, 0.2, 0.2, 0.95))

	# 3. Kendaraan Hovercraft Melintas di Latar Belakang
	_draw_hovercraft()

func _draw_hovercraft() -> void:
	var hx = hovercraft_pos.x
	var hy = hovercraft_pos.y

	# Badan kendaraan siluet gelap
	draw_rect(Rect2(hx, hy, 16, 4), Color(0.08, 0.1, 0.16, 0.9))
	# Lampu depan cyan
	draw_rect(Rect2(hx + 14, hy + 1, 2, 2), Color(0.3, 0.9, 1.0, 0.9))
	# Jejak ekor lampu merah memudar ke belakang
	draw_rect(Rect2(hx - 8, hy + 1, 8, 2), Color(1.0, 0.2, 0.15, 0.6))
	draw_rect(Rect2(hx - 16, hy + 1, 8, 1), Color(1.0, 0.2, 0.15, 0.3))
