class_name VFXSuperFlash
extends Node2D

## Efek Sinematik Super Flash & Screen Dimming (Fighting Game Super Freeze)
## Meredupkan arena saat Ultimate/Skill Pamungkas aktif, menampilkan spotlight caster,
## letterbox sinematik, serta ring ekspansi energi sebelum serangan dilepaskan.

@export var duration: float = 0.42
@export var dim_color: Color = Color(0.02, 0.03, 0.06, 0.65)
@export var flare_color: Color = Color(0.3, 0.95, 1.0, 1.0)

var time_elapsed: float = 0.0
var focus_pos: Vector2 = Vector2.ZERO
var ring_radius: float = 10.0
var max_ring_radius: float = 160.0
var is_active: bool = false

func _ready() -> void:
	z_index = 75
	set_physics_process(true)

func trigger_super_flash(pos: Vector2, custom_flare_color: Color = Color.TRANSPARENT, custom_duration: float = 0.42) -> void:
	focus_pos = pos
	global_position = pos
	duration = custom_duration
	if custom_flare_color != Color.TRANSPARENT:
		flare_color = custom_flare_color
	time_elapsed = 0.0
	is_active = true
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	
	time_elapsed += delta
	if time_elapsed >= duration:
		queue_free()
		return
	
	var progress: float = time_elapsed / duration
	ring_radius = lerpf(10.0, max_ring_radius, ease(progress, 0.35))
	queue_redraw()

func _draw() -> void:
	if not is_active:
		return
	
	var progress: float = time_elapsed / duration
	# Alpha memudar di akhir durasi (fade out)
	var fade_alpha: float = 1.0
	if progress > 0.65:
		fade_alpha = 1.0 - ((progress - 0.65) / 0.35)
	
	# 1. Screen Dimming Overlay (Kotak luas menutupi layar dunia)
	var screen_rect := Rect2(-1000.0, -800.0, 2000.0, 1600.0)
	var current_dim := Color(dim_color.r, dim_color.g, dim_color.b, dim_color.a * fade_alpha)
	draw_rect(screen_rect, current_dim, true)
	
	# 2. Cinematic Letterbox Bars (Atas dan Bawah layar)
	var bar_height: float = 24.0 * minf(1.0, progress * 4.0) * fade_alpha
	draw_rect(Rect2(-1000.0, -280.0, 2000.0, bar_height), Color(0.0, 0.0, 0.0, 0.95 * fade_alpha))
	draw_rect(Rect2(-1000.0, 280.0 - bar_height, 2000.0, bar_height), Color(0.0, 0.0, 0.0, 0.95 * fade_alpha))
	
	# 3. Expanding Energy Shockwave Ring di posisi caster
	var ring_col := Color(flare_color.r, flare_color.g, flare_color.b, 0.85 * fade_alpha)
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 32, ring_col, 3.0, true)
	draw_arc(Vector2.ZERO, ring_radius * 0.7, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, 0.9 * fade_alpha), 1.5, true)
	
	# 4. Cross Flare / Bintang Kilat di titik pusat mecha
	var flare_col := Color(flare_color.r, flare_color.g, flare_color.b, 0.95 * fade_alpha)
	var flare_len: float = (30.0 + 40.0 * sin(progress * PI)) * fade_alpha
	var flare_thick: float = 2.5 * fade_alpha
	var core_white := Color(1.0, 1.0, 1.0, fade_alpha)
	
	# Garis kilat horizontal & vertikal
	draw_line(Vector2(-flare_len, 0), Vector2(flare_len, 0), flare_col, flare_thick)
	draw_line(Vector2(0, -flare_len), Vector2(0, flare_len), flare_col, flare_thick)
	draw_line(Vector2(-flare_len * 0.4, 0), Vector2(flare_len * 0.4, 0), core_white, flare_thick + 1.0)
	draw_line(Vector2(0, -flare_len * 0.4), Vector2(0, flare_len * 0.4), core_white, flare_thick + 1.0)
	
	# Titik pusat pijar
	draw_circle(Vector2.ZERO, 6.0 * fade_alpha, core_white)
