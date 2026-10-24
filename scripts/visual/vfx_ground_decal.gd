class_name VFXGroundDecal
extends Node2D

## Komponen Jejak Bekas Hantaman Tanah (Ground Impact Decal & Scorch Mark)
## Menampilkan retakan tanah membara, bekas hangus laser/plasma, atau pecahan es
## yang menetap sementara di lantai arena setelah hantaman serangan berat / skill.

@export var duration: float = 2.0
@export var decal_type: StringName = &"cracks" # &"cracks", &"scorch", &"frost", &"slash"
@export var decal_color: Color = Color(1.0, 0.55, 0.15, 0.85)
@export var decal_width: float = 60.0

var time_elapsed: float = 0.0
var is_active: bool = false
var crack_points: Array[Vector2] = []
var spark_particles: Array[Dictionary] = []

func _ready() -> void:
	z_index = 10 # Di atas lantai arena, di bawah karakter
	set_physics_process(true)

func trigger_decal(pos: Vector2, type: StringName = &"cracks", custom_color: Color = Color.TRANSPARENT, width: float = 60.0, custom_duration: float = 2.0) -> void:
	global_position = pos
	decal_type = type
	decal_width = width
	duration = custom_duration
	time_elapsed = 0.0
	is_active = true
	
	if custom_color != Color.TRANSPARENT:
		decal_color = custom_color
	elif decal_type == &"frost":
		decal_color = Color(0.25, 0.9, 1.0, 0.85)
	elif decal_type == &"scorch":
		decal_color = Color(0.8, 0.3, 1.0, 0.85)
	elif decal_type == &"slash":
		decal_color = Color(1.0, 0.15, 0.25, 0.85)
	else:
		decal_color = Color(1.0, 0.55, 0.15, 0.85)
	
	_generate_crack_geometry()
	queue_redraw()

func _generate_crack_geometry() -> void:
	crack_points.clear()
	spark_particles.clear()
	
	# Bentuk retakan lantai bergerigi
	var half_w: float = decal_width * 0.5
	var segments := 8
	var last_pt := Vector2(-half_w, 0.0)
	crack_points.append(last_pt)
	
	for i in range(1, segments + 1):
		var t := float(i) / float(segments)
		var x: float = lerpf(-half_w, half_w, t)
		var y: float = randf_range(-4.0, 4.0)
		var pt := Vector2(x, y)
		crack_points.append(pt)
		
		# Partikel percikan mendidih/asap kecil
		if randf() > 0.4:
			spark_particles.append({
				"pos": pt,
				"vel": Vector2(randf_range(-10.0, 10.0), randf_range(-25.0, -8.0)),
				"lifetime": randf_range(0.4, 1.0),
				"age": 0.0
			})

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	
	time_elapsed += delta
	if time_elapsed >= duration:
		queue_free()
		return
	
	# Update partikel percikan di atas retakan
	for p in spark_particles:
		p["age"] += delta
		p["pos"] += p["vel"] * delta
		p["vel"].y += 30.0 * delta # micro gravity
	
	queue_redraw()

func _draw() -> void:
	if not is_active:
		return
	
	var progress: float = time_elapsed / duration
	var fade_alpha: float = 1.0
	if progress > 0.6:
		fade_alpha = 1.0 - ((progress - 0.6) / 0.4)
	
	var main_col := Color(decal_color.r, decal_color.g, decal_color.b, decal_color.a * fade_alpha)
	var glow_col := Color(decal_color.r * 1.2, decal_color.g * 1.2, decal_color.b * 1.2, 0.9 * fade_alpha)
	var scorch_dark := Color(0.08, 0.06, 0.08, 0.7 * fade_alpha)
	
	# 1. Bayangan hangus dasar (Base scorch mark)
	draw_circle(Vector2(0, 0), decal_width * 0.45, scorch_dark)
	
	# 2. Retakan Utama & Cabang-cabang
	if decal_type == &"cracks" or decal_type == &"slash":
		for i in range(crack_points.size() - 1):
			var p_a: Vector2 = crack_points[i]
			var p_b: Vector2 = crack_points[i + 1]
			# Garis retakan membara
			draw_line(p_a, p_b, glow_col, 2.5)
			draw_line(p_a, p_b, Color(1.0, 1.0, 1.0, 0.9 * fade_alpha), 1.0)
			
			# Retakan cabang kecil ke samping
			if i % 2 == 1:
				var branch_end := p_a + Vector2(randf_range(-8.0, 8.0), randf_range(4.0, 9.0))
				draw_line(p_a, branch_end, main_col, 1.2)
	elif decal_type == &"frost":
		# Pola kristal es merambat di lantai
		for pt in crack_points:
			draw_line(pt, pt + Vector2(0, -6), glow_col, 1.5)
			draw_line(pt, pt + Vector2(4, -3), main_col, 1.0)
			draw_line(pt, pt + Vector2(-4, -3), main_col, 1.0)
	else:
		# Scorch / Hangus plasma bergradasi
		draw_arc(Vector2.ZERO, decal_width * 0.35, 0.0, TAU, 16, glow_col, 2.0, true)
		draw_arc(Vector2.ZERO, decal_width * 0.2, 0.0, TAU, 12, Color(1.0, 1.0, 1.0, 0.8 * fade_alpha), 1.5, true)
	
	# 3. Partikel percikan bara/uap yang melayang
	for p in spark_particles:
		var p_life: float = p["lifetime"]
		var p_age: float = p["age"]
		if p_age < p_life:
			var p_alpha: float = (1.0 - (p_age / p_life)) * fade_alpha
			draw_circle(p["pos"], 1.5, Color(glow_col.r, glow_col.g, glow_col.b, p_alpha))
