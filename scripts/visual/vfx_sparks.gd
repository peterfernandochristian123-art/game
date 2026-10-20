class_name VFXWeldingSparks
extends CPUParticles2D

## Partikel Percikan Api Las Benturan Baja (Story 6.2)
## Menghasilkan partikel berpijar oranye-kuning berkecepatan tinggi saat kontak serangan atau parry

@export var auto_destroy: bool = true

func _ready() -> void:
	emitting = false
	one_shot = true
	explosiveness = 0.95
	amount = 16
	lifetime = 0.3
	speed_scale = 1.2
	
	spread = 60.0
	initial_velocity_min = 120.0
	initial_velocity_max = 240.0
	gravity = Vector2(0, 380)
	scale_amount_min = 1.5
	scale_amount_max = 3.0
	
	# Gradasi Warna: Putih Terang -> Kuning Pijar -> Oranye Menyala -> Abu-abu Pudar
	color = Color(1.0, 0.95, 0.6, 1.0)
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 0.9, 1.0))
	grad.add_point(0.25, Color(1.0, 0.85, 0.1, 1.0))
	grad.add_point(0.70, Color(1.0, 0.35, 0.05, 0.8))
	grad.set_color(grad.get_point_count() - 1, Color(0.3, 0.2, 0.2, 0.0))
	color_ramp = grad

func trigger_sparks(pos: Vector2, dir_degrees: float = 0.0, parry_boost: bool = false) -> void:
	global_position = pos
	rotation_degrees = dir_degrees
	
	if parry_boost:
		amount = 28
		initial_velocity_min = 180.0
		initial_velocity_max = 320.0
		scale_amount_max = 4.0
	else:
		amount = 14
		initial_velocity_min = 100.0
		initial_velocity_max = 220.0
		scale_amount_max = 2.5
		
	emitting = true
	
	if auto_destroy:
		# Bersihkan node setelah masa hidup partikel selesai
		get_tree().create_timer(lifetime + 0.1).timeout.connect(queue_free)
