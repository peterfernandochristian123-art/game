class_name VFXAuraBurst
extends Node2D

## Efek Visual Ledakan Cahaya Aura (Light Burst / Energy Flare)
## Denyut cahaya ekspansif singkat di sekitar karakter saat skill cast, hit kuat, atau power-up.
## Memberikan kesan "cahaya" yang dramatis pada momen aksi karakter.

@export var burst_color: Color = Color(0.2, 0.95, 1.0, 1.0)
@export var flash_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var max_radius: float = 70.0
@export var duration_seconds: float = 0.3
@export var intensity: float = 1.0

var _elapsed: float = 0.0
var _active: bool = false
var _rays: Array[float] = []

func _ready() -> void:
	z_index = 52
	set_physics_process(true)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat

func trigger_burst(pos: Vector2, custom_color: Color = Color.TRANSPARENT,
		radius: float = 70.0, duration: float = 0.3, power: float = 1.0,
		custom_flash: Color = Color.TRANSPARENT) -> void:
	global_position = pos
	max_radius = radius
	duration_seconds = maxf(0.08, duration)
	intensity = clampf(power, 0.4, 3.0)
	if custom_color != Color.TRANSPARENT:
		burst_color = custom_color
	if custom_flash != Color.TRANSPARENT:
		flash_color = custom_flash
	_elapsed = 0.0
	_active = true
	_rays.clear()
	var ray_count := int(8 + intensity * 4.0)
	for i in range(ray_count):
		_rays.append(randf_range(0.6, 1.4))
	queue_redraw()

func is_active() -> bool:
	return _active

func _physics_process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	if _elapsed >= duration_seconds:
		_active = false
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	if not _active:
		return

	var progress := clampf(_elapsed / duration_seconds, 0.0, 1.0)
	var alpha := 1.0
	if progress < 0.12:
		alpha = progress / 0.12
	else:
		alpha = clampf(1.0 - (progress - 0.12) / 0.88, 0.0, 1.0)

	var ease_out := 1.0 - pow(1.0 - progress, 2.6)
	var r := max_radius * ease_out

	# 1. Bloom besar luar (cahaya ambient)
	var bloom_a := alpha * 0.18 * intensity
	draw_circle(Vector2.ZERO, r * 1.25, Color(burst_color.r, burst_color.g, burst_color.b, bloom_a))
	draw_circle(Vector2.ZERO, r * 0.85, Color(burst_color.r, burst_color.g, burst_color.b, bloom_a * 1.4))

	# 2. Cincin cahaya utama
	var ring_w := maxf(1.5, 4.0 * (1.0 - progress * 0.6) * intensity)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 36, Color(burst_color.r, burst_color.g, burst_color.b, alpha * 0.75), ring_w)
	draw_arc(Vector2.ZERO, r * 0.92, 0.0, TAU, 32, Color(flash_color.r, flash_color.g, flash_color.b, alpha * 0.55), maxf(1.0, ring_w * 0.45))

	# 3. Sinar radial cahaya (light rays)
	var ray_alpha := alpha * 0.6
	for i in range(_rays.size()):
		var ang := (TAU / float(_rays.size())) * float(i) + progress * 0.4
		var len_r := r * _rays[i] * (0.55 + 0.45 * (1.0 - progress))
		var inner_r := r * 0.15
		var p0 := Vector2(cos(ang), sin(ang)) * inner_r
		var p1 := Vector2(cos(ang), sin(ang)) * len_r
		var col := Color(burst_color.r, burst_color.g, burst_color.b, ray_alpha)
		draw_line(p0, p1, col, 2.0)
		draw_line(p0, p1 * 0.7, Color(flash_color.r, flash_color.g, flash_color.b, ray_alpha * 0.8), 1.0)

	# 4. Inti flash putih
	var core_r := max_radius * 0.22 * (1.0 - progress * 0.85)
	if core_r > 0.5:
		draw_circle(Vector2.ZERO, core_r * 1.8, Color(burst_color.r, burst_color.g, burst_color.b, alpha * 0.35))
		draw_circle(Vector2.ZERO, core_r, Color(flash_color.r, flash_color.g, flash_color.b, alpha * 0.9))
		draw_circle(Vector2.ZERO, core_r * 0.45, Color(1.0, 1.0, 1.0, alpha * 0.95))

	# 5. Cross flare (kilatan silang)
	if progress < 0.55:
		var flare_a := alpha * (1.0 - progress / 0.55) * 0.7
		var flare_len := max_radius * 0.75 * (1.0 - progress * 0.5)
		var fc := Color(flash_color.r, flash_color.g, flash_color.b, flare_a)
		draw_line(Vector2(-flare_len, 0), Vector2(flare_len, 0), fc, 2.0)
		draw_line(Vector2(0, -flare_len), Vector2(0, flare_len), fc, 2.0)
		draw_line(Vector2(-flare_len * 0.6, -flare_len * 0.6) * 0.5, Vector2(flare_len * 0.6, flare_len * 0.6) * 0.5,
			Color(burst_color.r, burst_color.g, burst_color.b, flare_a * 0.6), 1.2)
		draw_line(Vector2(flare_len * 0.6, -flare_len * 0.6) * 0.5, Vector2(-flare_len * 0.6, flare_len * 0.6) * 0.5,
			Color(burst_color.r, burst_color.g, burst_color.b, flare_a * 0.6), 1.2)
