class_name VFXSupernova
extends Node2D

## Efek Visual Singularitas Kosmik & Korona Foton (Ray Pulsar Supernova Horizon & Boss Overload)
## Menampilkan pusaran piringan akresi singularitas (accretion vortex), cincin foton gravitasi,
## semburan jet relativistik kutub (polar gamma-ray jets), dan suar plasma berputar kosmik.

@export var supernova_color: Color = Color(0.8, 0.25, 1.0, 1.0)
@export var max_radius: float = 190.0
@export var duration_seconds: float = 0.55

var _elapsed: float = 0.0
var _active: bool = false
var _flare_angles: Array[float] = []
var _flare_lengths: Array[float] = []
var _spiral_arms: int = 4

func _ready() -> void:
	z_index = 56

func trigger_supernova(pos: Vector2, radius: float = 190.0, custom_color: Color = Color.TRANSPARENT, duration: float = 0.55) -> void:
	global_position = pos
	max_radius = radius
	duration_seconds = duration
	if custom_color != Color.TRANSPARENT:
		supernova_color = custom_color

	_elapsed = 0.0
	_active = true

	# Hasilkan suar radiasi surya yang menyembur keluar (kompatibel test)
	_flare_angles.clear()
	_flare_lengths.clear()
	var flare_count := 18
	for i in range(flare_count):
		_flare_angles.append((TAU / float(flare_count)) * float(i) + randf_range(-0.15, 0.15))
		_flare_lengths.append(randf_range(0.7, 1.3))

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
	var current_rad := max_radius * (0.2 + progress * 0.8)
	var vortex_rot := _elapsed * 6.0

	# 1. Lengan Spiral Piringan Akresi Kosmik (Accretion Vortex Arms)
	for arm in range(_spiral_arms):
		var arm_base_angle := (TAU / float(_spiral_arms)) * float(arm) + vortex_rot
		var arm_pts := PackedVector2Array()
		var segs := 10
		for s in range(segs + 1):
			var t := float(s) / float(segs)
			var r := current_rad * t
			var a := arm_base_angle + t * PI * 0.8 # Kurva spiral
			arm_pts.append(Vector2(cos(a), sin(a)) * r)
		var arm_col := Color(supernova_color.r, supernova_color.g, supernova_color.b, alpha * 0.65)
		draw_polyline(arm_pts, arm_col, 2.5)
		draw_polyline(arm_pts, Color(1.0, 1.0, 1.0, alpha * 0.85), 1.0)

	# 2. Suar Radiasi Kosmik Tajam (Relativistic Flares)
	for i in range(_flare_angles.size()):
		var angle := _flare_angles[i] + vortex_rot * 0.2
		var l := current_rad * _flare_lengths[i]
		var end_pt := Vector2(cos(angle), sin(angle)) * l
		var ray_col := Color(supernova_color.r, supernova_color.g, supernova_color.b, alpha * 0.75)
		draw_line(Vector2.ZERO, end_pt, ray_col, 2.5)
		draw_line(Vector2.ZERO, end_pt * 0.7, Color(1.0, 1.0, 1.0, alpha * 0.9), 1.2)

	# 3. Semburan Jet Relativistik Kutub (Polar Relativistic Jets Vertikal & Horizontal)
	var jet_len := current_rad * 1.3
	var jet_col := Color(1.0, 1.0, 1.0, alpha * 0.9)
	draw_line(Vector2(0, -jet_len), Vector2(0, jet_len), jet_col, 2.0)
	draw_line(Vector2(-jet_len * 0.7, 0), Vector2(jet_len * 0.7, 0), Color(supernova_color.r, supernova_color.g, supernova_color.b, alpha * 0.8), 1.5)

	# 4. Cincin Gelombang Lensa Gravitasi Luar (Gravitational Lensing Ring)
	var outer_ring_col := Color(supernova_color.r, supernova_color.g, supernova_color.b, alpha * 0.85)
	draw_arc(Vector2.ZERO, current_rad, 0.0, TAU, 28, outer_ring_col, 3.5)
	draw_arc(Vector2.ZERO, current_rad * 0.85, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, alpha * 0.5), 1.2)

	# 5. Lapisan Transparan Korona Dalam
	var corona_fill := Color(supernova_color.r, supernova_color.g, supernova_color.b, alpha * 0.22)
	draw_circle(Vector2.ZERO, current_rad * 0.75, corona_fill)

	# 6. Inti Foton Sphere Terang Menyilaukan & Lubang Hitam Event Horizon
	var core_rad := (max_radius * 0.35) * (1.0 - progress * 0.6)
	draw_circle(Vector2.ZERO, core_rad * 1.3, Color(supernova_color.r * 1.2, supernova_color.g * 1.2, supernova_color.b * 1.2, alpha * 0.9))
	draw_circle(Vector2.ZERO, core_rad, Color(1.0, 1.0, 1.0, alpha * 0.98))
	# Lubang Hitam Singularitas di pusat terdalam
	var void_rad := core_rad * 0.45 * (1.0 - progress * 0.4)
	draw_circle(Vector2.ZERO, void_rad, Color(0.04, 0.02, 0.08, alpha * 0.95))
	draw_arc(Vector2.ZERO, void_rad, 0.0, TAU, 16, Color(1.0, 1.0, 1.0, alpha * 0.9), 1.2)
