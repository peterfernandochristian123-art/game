class_name VFXShadowSmoke
extends Node2D

## Efek Visual Asap Ninja & Siluet Bayangan (Phantom-9 Kage Stance Shift & Shadow Feint)
## Menampilkan ledakan kepulan asap crimson-hitam, partikel bayangan melayang, dan siluet ilusi

@export var smoke_color: Color = Color(0.95, 0.15, 0.25, 1.0)
@export var duration_seconds: float = 0.38

class SmokePuff:
	var offset: Vector2
	var vel: Vector2
	var radius: float
	var is_dark: bool

var _puffs: Array[SmokePuff] = []
var _elapsed: float = 0.0
var _active: bool = false

func _ready() -> void:
	z_index = 52

func trigger_smoke(pos: Vector2, custom_color: Color = Color.TRANSPARENT, count: int = 14, duration: float = 0.38) -> void:
	global_position = pos
	duration_seconds = duration
	if custom_color != Color.TRANSPARENT:
		smoke_color = custom_color

	_elapsed = 0.0
	_active = true

	# Hasilkan gumpalan kepulan asap menyebar radial ke atas
	_puffs.clear()
	for i in range(count):
		var p := SmokePuff.new()
		p.offset = Vector2(randf_range(-12.0, 12.0), randf_range(-18.0, 6.0))
		var angle := randf_range(-PI, 0.0) # Menyebar ke atas & samping
		var speed := randf_range(40.0, 120.0)
		p.vel = Vector2(cos(angle), sin(angle)) * speed
		p.radius = randf_range(10.0, 22.0)
		p.is_dark = (randf() > 0.45)
		_puffs.append(p)

	queue_redraw()

func _process(delta: float) -> void:
	if not _active:
		return

	_elapsed += delta
	for p in _puffs:
		p.offset += p.vel * delta
		p.vel *= 0.92 # Redaman udara

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

	# 1. Gambar kepulan asap gelap (shadow) terlebih dahulu
	for p in _puffs:
		if p.is_dark:
			var rad := p.radius * (0.8 + progress * 0.6)
			var col := Color(0.08, 0.05, 0.12, alpha * 0.7)
			draw_circle(p.offset, rad, col)

	# 2. Gambar kepulan asap crimson neon di atasnya
	for p in _puffs:
		if not p.is_dark:
			var rad := p.radius * (0.7 + progress * 0.5)
			var col := Color(smoke_color.r, smoke_color.g, smoke_color.b, alpha * 0.6)
			draw_circle(p.offset, rad, col)
			# Inti terang pada kepulan
			draw_circle(p.offset, rad * 0.4, Color(1.0, 0.8, 0.85, alpha * 0.8))

	# 3. Garis kecepatan ninja vertikal / feint speedlines
	var speedline_col := Color(smoke_color.r, smoke_color.g, smoke_color.b, alpha * 0.85)
	for i in range(4):
		var x_off := -20.0 + float(i) * 13.0
		draw_line(Vector2(x_off, -40.0 * (1.0 - progress)), Vector2(x_off, 20.0 * progress), speedline_col, 1.5)
