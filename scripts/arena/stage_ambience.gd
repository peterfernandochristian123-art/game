class_name StageAmbience
extends Node2D

## Ambience latar ringan (partikel CPU) untuk arena Stage Select.
## Dipasang di belakang petarung (z_index negatif) agar tidak menutupi gameplay.

const VIEW_W := 700.0
const VIEW_H := 400.0

func setup(kind: StringName, accent: Color) -> void:
	for child in get_children():
		child.queue_free()
	var p := CPUParticles2D.new()
	p.name = "Particles"
	p.emitting = true
	p.local_coords = false
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(VIEW_W * 0.5, 8.0)
	p.position = Vector2(0.0, -VIEW_H * 0.5 - 10.0)
	p.direction = Vector2(0, 1)
	p.spread = 12.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.lifetime = 6.0
	p.amount = 40
	p.preprocess = 6.0
	p.initial_velocity_min = 10.0
	p.initial_velocity_max = 25.0
	p.gravity = Vector2.ZERO
	p.color = Color(1, 1, 1, 0.75)
	match kind:
		&"petals":
			p.color = Color(1.0, 0.72, 0.85, 0.85)
			p.direction = Vector2(-0.5, 1)
			p.spread = 25.0
			p.initial_velocity_min = 14.0
			p.initial_velocity_max = 30.0
			p.angular_velocity_min = -90.0
			p.angular_velocity_max = 90.0
			p.scale_amount_max = 3.0
			p.amount = 36
		&"rain":
			p.color = Color(0.6, 0.8, 1.0, 0.55)
			p.direction = Vector2(-0.15, 1)
			p.spread = 2.0
			p.initial_velocity_min = 260.0
			p.initial_velocity_max = 330.0
			p.lifetime = 1.6
			p.amount = 90
			p.preprocess = 2.0
			p.scale_amount_min = 1.0
			p.scale_amount_max = 1.5
		&"snow":
			p.color = Color(1, 1, 1, 0.9)
			p.direction = Vector2(-0.2, 1)
			p.spread = 30.0
			p.initial_velocity_min = 12.0
			p.initial_velocity_max = 28.0
			p.amount = 70
			p.scale_amount_max = 2.5
		&"embers":
			p.color = Color(1.0, 0.55, 0.2, 0.9)
			p.position = Vector2(0.0, VIEW_H * 0.5)
			p.direction = Vector2(0.2, -1)
			p.spread = 25.0
			p.initial_velocity_min = 18.0
			p.initial_velocity_max = 45.0
			p.amount = 45
			p.lifetime = 5.0
		&"leaves":
			p.color = Color(0.55, 0.9, 0.4, 0.8)
			p.direction = Vector2(0.3, 1)
			p.spread = 30.0
			p.angular_velocity_min = -120.0
			p.angular_velocity_max = 120.0
			p.amount = 28
			p.scale_amount_max = 3.0
		&"stars":
			p.color = Color(0.85, 0.95, 1.0, 0.9)
			p.emission_rect_extents = Vector2(VIEW_W * 0.5, VIEW_H * 0.3)
			p.position = Vector2(0.0, -VIEW_H * 0.15)
			p.initial_velocity_min = 0.0
			p.initial_velocity_max = 2.0
			p.lifetime = 3.0
			p.amount = 40
			p.scale_amount_max = 1.6
		&"clouds":
			p.color = Color(1.0, 0.85, 0.7, 0.25)
			p.emission_rect_extents = Vector2(8.0, VIEW_H * 0.2)
			p.position = Vector2(-VIEW_W * 0.5 - 20.0, -VIEW_H * 0.2)
			p.direction = Vector2(1, 0)
			p.spread = 4.0
			p.initial_velocity_min = 14.0
			p.initial_velocity_max = 22.0
			p.lifetime = 55.0
			p.amount = 6
			p.preprocess = 30.0
			p.scale_amount_min = 12.0
			p.scale_amount_max = 22.0
		&"dust":
			p.color = Color(1.0, 0.85, 0.6, 0.45)
			p.emission_rect_extents = Vector2(8.0, VIEW_H * 0.35)
			p.position = Vector2(-VIEW_W * 0.5 - 10.0, 0.0)
			p.direction = Vector2(1, -0.05)
			p.spread = 8.0
			p.initial_velocity_min = 25.0
			p.initial_velocity_max = 55.0
			p.lifetime = 14.0
			p.amount = 34
			p.preprocess = 10.0
		_:
			p.emitting = false
	if accent.a > 0.0 and kind == &"stars":
		p.color = p.color.lerp(accent, 0.2)
	add_child(p)
