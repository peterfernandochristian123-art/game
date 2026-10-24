class_name OrbitalStationBackground
extends Node2D

## Komponen Visual Latar Belakang Orbital Station & Horizon Bumi (Zero-G Spaceport)
## Menggambar hamparan ratusan bintang kosmik berkelip, lengkungan atmosfer bumi (Earth Horizon),
## satelit array surya yang mengorbit, dan debu partikel mikrometeorit kosmik.

var tick: int = 0
var stars: Array[Dictionary] = []
var satellite_pos: Vector2 = Vector2(-120.0, 70.0)
var satellite_speed: float = 38.0

func _ready() -> void:
	set_physics_process(true)
	_generate_starfield()

func _generate_starfield() -> void:
	stars.clear()
	# Buat 160 bintang deterministik di seluruh kanvas langit dunia (1408 x 480)
	for i in range(160):
		var x: float = fmod(float(i * 137 + 41), 1400.0)
		var y: float = fmod(float(i * 89 + 17), 280.0)
		var size: float = 1.0 if (i % 3 != 0) else (2.0 if (i % 7 != 0) else 3.0)
		var is_tinted: bool = (i % 5 == 0)
		var col: Color = Color(0.7, 0.85, 1.0) if is_tinted else (Color(1.0, 0.9, 0.6) if (i % 4 == 0) else Color(1.0, 1.0, 1.0))
		stars.append({
			"pos": Vector2(x, y),
			"size": size,
			"color": col,
			"phase": float(i) * 0.15
		})

func _physics_process(delta: float) -> void:
	tick = (tick + 1) % 360

	# Gerak melintas satelit komunikasi di latar belakang
	satellite_pos.x += satellite_speed * delta
	if satellite_pos.x > 1500.0:
		satellite_pos.x = -120.0
		satellite_pos.y = 50.0 + float((tick * 11) % 80)

	queue_redraw()

func _draw() -> void:
	# 1. Hamparan Bintang Kosmik Berkelip (Twinkling Stars)
	for s in stars:
		var flicker: float = 0.6 + 0.4 * sin(float(tick) * 0.08 + s["phase"])
		var c: Color = s["color"]
		var draw_col := Color(c.r, c.g, c.b, flicker)
		if s["size"] <= 1.5:
			draw_rect(Rect2(s["pos"].x, s["pos"].y, s["size"], s["size"]), draw_col)
		else:
			# Bintang besar berpendar salib mini
			var p: Vector2 = s["pos"]
			draw_circle(p, s["size"] * 0.75, draw_col)
			draw_line(p - Vector2(2, 0), p + Vector2(2, 0), Color(1, 1, 1, flicker * 0.8), 1.0)
			draw_line(p - Vector2(0, 2), p + Vector2(0, 2), Color(1, 1, 1, flicker * 0.8), 1.0)

	# 2. Lengkungan Atmosfer Bumi Megah (Earth Horizon Limb)
	var earth_center := Vector2(704.0, 920.0)
	var earth_radius := 680.0
	
	# Lapisan atmosfer luar (Cyan Glow)
	draw_arc(earth_center, earth_radius + 18.0, -PI * 0.82, -PI * 0.18, 64, Color(0.1, 0.5, 0.9, 0.15), 18.0, true)
	draw_arc(earth_center, earth_radius + 8.0, -PI * 0.84, -PI * 0.16, 64, Color(0.2, 0.85, 1.0, 0.35), 8.0, true)
	draw_arc(earth_center, earth_radius + 2.0, -PI * 0.85, -PI * 0.15, 64, Color(0.6, 0.95, 1.0, 0.85), 3.0, true)
	# Badan daratan dan samudera bumi
	draw_arc(earth_center, earth_radius - 10.0, -PI * 0.86, -PI * 0.14, 64, Color(0.04, 0.12, 0.28, 0.95), 24.0, true)

	# 3. Satelit Pengorbit Array Foton (Solar Satellite Array)
	_draw_solar_satellite()

func _draw_solar_satellite() -> void:
	var sx: float = satellite_pos.x
	var sy: float = satellite_pos.y

	# Badan satelit utama
	draw_rect(Rect2(sx - 6, sy - 5, 12, 10), Color(0.85, 0.9, 0.95, 1.0))
	draw_rect(Rect2(sx - 4, sy - 3, 8, 6), Color(0.2, 0.25, 0.35, 1.0))

	# Panel Surya Emas Kiri & Kanan
	draw_rect(Rect2(sx - 36, sy - 8, 26, 16), Color(0.15, 0.35, 0.65, 0.95))
	draw_rect(Rect2(sx + 10, sy - 8, 26, 16), Color(0.15, 0.35, 0.65, 0.95))
	
	# Kisi foton emas panel
	draw_line(Vector2(sx - 23, sy - 8), Vector2(sx - 23, sy + 8), Color(1.0, 0.8, 0.2, 0.8), 1.0)
	draw_line(Vector2(sx - 36, sy), Vector2(sx - 10, sy), Color(1.0, 0.8, 0.2, 0.8), 1.0)
	draw_line(Vector2(sx + 23, sy - 8), Vector2(sx + 23, sy + 8), Color(1.0, 0.8, 0.2, 0.8), 1.0)
	draw_line(Vector2(sx + 10, sy), Vector2(sx + 36, sy), Color(1.0, 0.8, 0.2, 0.8), 1.0)

	# Lampu suar berkedip merah & hijau
	var beacon: bool = (tick % 40 < 20)
	if beacon:
		draw_circle(Vector2(sx - 36, sy), 2.0, Color(1.0, 0.2, 0.2, 1.0))
		draw_circle(Vector2(sx + 36, sy), 2.0, Color(0.2, 1.0, 0.4, 1.0))
