class_name VFXFloatingText
extends Node2D

## Komponen Angka Damage & Teks Status Mengambang (Floating Damage Numbers & Popups)
## Menampilkan angka kerusakan tempur yang melompat ke atas dengan gravitasi halus,
## warna khusus berdasarkan tipe serangan (Normal, Heavy, Critical/Counter, Parry, Block),
## serta outline kontras tinggi agar sangat jelas terbaca di atas latar arena.

@export var duration: float = 0.65
@export var text_content: String = "45"
@export var text_color: Color = Color(1.0, 0.95, 0.3, 1.0) # Kuning cerah default
@export var font_size: int = 14
@export var is_critical: bool = false

var velocity: Vector2 = Vector2.ZERO
var gravity: float = 140.0
var time_elapsed: float = 0.0
var is_active: bool = false
var default_font: Font = null

func _ready() -> void:
	z_index = 85
	set_physics_process(true)
	default_font = ThemeDB.fallback_font

func trigger_text(pos: Vector2, text: String, color: Color = Color.TRANSPARENT, critical: bool = false, custom_duration: float = 0.65) -> void:
	global_position = pos
	text_content = text
	is_critical = critical
	duration = custom_duration
	time_elapsed = 0.0
	is_active = true
	
	if color != Color.TRANSPARENT:
		text_color = color
	elif is_critical:
		text_color = Color(1.0, 0.25, 0.15, 1.0) # Oranye/Merah menyala
	else:
		text_color = Color(1.0, 0.95, 0.4, 1.0)
	
	if is_critical:
		font_size = 18
		velocity = Vector2(randf_range(-35.0, 35.0), -120.0)
	else:
		font_size = 13
		velocity = Vector2(randf_range(-20.0, 20.0), -85.0)
	
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	
	time_elapsed += delta
	if time_elapsed >= duration:
		queue_free()
		return
	
	velocity.y += gravity * delta
	position += velocity * delta
	queue_redraw()

func _draw() -> void:
	if not is_active or text_content.is_empty():
		return
	
	var progress: float = time_elapsed / duration
	var current_alpha: float = 1.0
	if progress > 0.55:
		current_alpha = 1.0 - ((progress - 0.55) / 0.45)
	
	var font: Font = default_font if default_font else ThemeDB.fallback_font
	if not font:
		return
	
	var draw_col := Color(text_color.r, text_color.g, text_color.b, current_alpha)
	var outline_col := Color(0.04, 0.05, 0.08, 0.95 * current_alpha)
	
	var text_width: float = font.get_string_size(text_content, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
	var text_origin := Vector2(-text_width * 0.5, 0.0)
	
	# Skala denyut pop saat muncul (pop-in scale)
	if progress < 0.15:
		var pop_scale: float = lerpf(0.6, 1.25 if is_critical else 1.1, progress / 0.15)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(pop_scale, pop_scale))
	else:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	
	# 1. Gambar Outline tebal 4 arah
	var outline_offsets := [
		Vector2(-1.5, 0), Vector2(1.5, 0), Vector2(0, -1.5), Vector2(0, 1.5),
		Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)
	]
	for off in outline_offsets:
		draw_string(font, text_origin + off, text_content, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_col)
	
	# 2. Gambar Teks Utama
	draw_string(font, text_origin, text_content, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, draw_col)
