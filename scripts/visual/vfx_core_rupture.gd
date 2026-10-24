class_name VFXCoreRupture
extends Node2D

## Efek Sinematik K.O. Finisher & Ruptur Reaktor Mecha (Anime Core Overload Rupture)
## Memicu flash build-up menyilaukan, berkas sinar laser salib horizontal & vertikal (✦),
## matriks heksagonal peringatan overload digital, partikel serpihan las radial, dan 18-frame hitstop freeze.

var frames_alive: int = 0
var max_frames: int = 35
var sparks_particles: CPUParticles2D = null
var flash_alpha: float = 0.95

func _ready() -> void:
	z_index = 60
	set_physics_process(true)
	_setup_sparks()

	# Emit hitstop freeze 18 frame via EventBus
	var bus = get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("hitstop_requested"):
		bus.hitstop_requested.emit(18)

func _setup_sparks() -> void:
	sparks_particles = CPUParticles2D.new()
	sparks_particles.emitting = true
	sparks_particles.one_shot = true
	sparks_particles.explosiveness = 0.92
	sparks_particles.amount = 32
	sparks_particles.lifetime = 0.55
	sparks_particles.direction = Vector2(0, -1)
	sparks_particles.spread = 180.0 # 360 derajat radial
	sparks_particles.gravity = Vector2(0, 160)
	sparks_particles.initial_velocity_min = 120.0
	sparks_particles.initial_velocity_max = 260.0
	sparks_particles.scale_amount_min = 2.0
	sparks_particles.scale_amount_max = 5.0
	sparks_particles.color = Color(1.0, 0.85, 0.2, 1.0) # Golden welding sparks
	add_child(sparks_particles)

func trigger_at(pos: Vector2) -> void:
	global_position = pos
	frames_alive = 0
	queue_redraw()

func _physics_process(_delta: float) -> void:
	frames_alive += 1
	if frames_alive >= max_frames:
		queue_free()
		return

	if frames_alive <= 8:
		flash_alpha = 0.95 * (1.0 - (float(frames_alive) / 8.0))
	else:
		flash_alpha = 0.0

	queue_redraw()

func _draw() -> void:
	var progress := float(frames_alive) / float(max_frames)
	var alpha := 1.0 - progress

	# 1. Energy Build-Up Flash (lingkaran ekspansi putih/oranye)
	if flash_alpha > 0.05:
		var radius: float = 14.0 + (frames_alive * 7.0)
		draw_circle(Vector2.ZERO, radius, Color(1.0, 1.0, 1.0, flash_alpha))
		draw_circle(Vector2.ZERO, radius * 0.7, Color(1.0, 0.6, 0.1, flash_alpha * 0.8))

	# 2. Berkas Sinar Salib Laser Inti Mecha (Piercing Core Cross Beams ✦)
	if frames_alive >= 2 and frames_alive <= 24:
		var beam_len := 480.0 * (1.0 - absf(float(frames_alive - 12) / 12.0))
		var beam_w := 6.0 * (1.0 - float(frames_alive) / 24.0)
		var beam_c := Color(1.0, 0.9, 0.3, alpha * 0.9)
		# Horizontal
		draw_line(Vector2(-beam_len, 0), Vector2(beam_len, 0), beam_c, beam_w)
		draw_line(Vector2(-beam_len, 0), Vector2(beam_len, 0), Color.WHITE, beam_w * 0.4)
		# Vertikal
		draw_line(Vector2(0, -beam_len * 0.7), Vector2(0, beam_len * 0.7), beam_c, beam_w)
		draw_line(Vector2(0, -beam_len * 0.7), Vector2(0, beam_len * 0.7), Color.WHITE, beam_w * 0.4)

	# 3. Expanding Pixel Shockwave Ring Ganda
	if frames_alive >= 3 and frames_alive <= 22:
		var ring_r: float = float(frames_alive) * 5.5
		var ring_a: float = 1.0 - (float(frames_alive - 3) / 19.0)
		draw_arc(Vector2.ZERO, ring_r, 0, TAU, 32, Color(1.0, 0.9, 0.3, ring_a), 2.5)
		draw_arc(Vector2.ZERO, ring_r * 0.75, 0, TAU, 24, Color(1.0, 0.4, 0.1, ring_a * 0.8), 1.8)

	# 4. Poligon Pecahan Inti Terdistorsi (Overload Hexagon Shards)
	if frames_alive >= 4 and frames_alive <= 20:
		var hex_r := 28.0 + float(frames_alive) * 2.0
		for h in range(6):
			var a := deg_to_rad(60.0 * h + float(frames_alive) * 3.0)
			var h_pos := Vector2(cos(a), sin(a)) * hex_r
			draw_circle(h_pos, maxf(1.0, 3.0 * (1.0 - float(frames_alive) / 20.0)), Color(1.0, 0.5, 0.1, alpha))
