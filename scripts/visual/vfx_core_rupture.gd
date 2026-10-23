class_name VFXCoreRupture
extends Node2D

## Efek Sinematik Ledakan Reaktor Mecha (K.O. Core Rupture - Story 7.2)
## Memicu flash build-up, 18-frame hitstop freeze, dan partikel las radial 360 derajat saat ronde berakhir via K.O.

var frames_alive: int = 0
var max_frames: int = 35
var sparks_particles: CPUParticles2D = null
var flash_alpha: float = 0.95

func _ready() -> void:
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
	sparks_particles.explosiveness = 0.9
	sparks_particles.amount = 32
	sparks_particles.lifetime = 0.5
	sparks_particles.direction = Vector2(0, -1)
	sparks_particles.spread = 180.0 # 360 derajat radial
	sparks_particles.gravity = Vector2(0, 150)
	sparks_particles.initial_velocity_min = 90.0
	sparks_particles.initial_velocity_max = 220.0
	sparks_particles.scale_amount_min = 2.0
	sparks_particles.scale_amount_max = 4.5
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

	if frames_alive <= 6:
		flash_alpha = 0.95 * (1.0 - (float(frames_alive) / 6.0))
	else:
		flash_alpha = 0.0

	queue_redraw()

func _draw() -> void:
	# 1. Energy Build-Up Flash (lingkaran ekspansi putih/oranye)
	if flash_alpha > 0.05:
		var radius: float = 12.0 + (frames_alive * 6.0)
		draw_circle(Vector2.ZERO, radius, Color(1.0, 1.0, 1.0, flash_alpha))
		draw_circle(Vector2.ZERO, radius * 0.7, Color(1.0, 0.6, 0.1, flash_alpha * 0.8))

	# 2. Expanding Pixel Shockwave Ring
	if frames_alive >= 3 and frames_alive <= 20:
		var ring_r: float = float(frames_alive) * 4.5
		var ring_a: float = 1.0 - (float(frames_alive - 3) / 17.0)
		draw_arc(Vector2.ZERO, ring_r, 0, TAU, 32, Color(1.0, 0.9, 0.3, ring_a), 2.0)
