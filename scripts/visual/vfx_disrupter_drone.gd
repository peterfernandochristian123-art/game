class_name VFXDisrupterDrone
extends Node2D

## Efek Visual Disrupter Drone (Ray-X Pulsar Skill 2)
## Menampilkan unit drone foton mengambang, cincin gyro berputar, dan gelombang disrupsi spasial

@export var drone_color: Color = Color(0.7, 0.3, 1.0, 1.0)
@export var duration_seconds: float = 2.0

var _elapsed: float = 0.0
var _active: bool = false
var _rotation_angle: float = 0.0
var _pulse_timer: float = 0.0

func _ready() -> void:
	z_index = 53

func trigger_drone(pos: Vector2, duration: float = 2.0, custom_color: Color = Color.TRANSPARENT) -> void:
	global_position = pos
	duration_seconds = duration
	if custom_color != Color.TRANSPARENT:
		drone_color = custom_color

	_elapsed = 0.0
	_rotation_angle = 0.0
	_pulse_timer = 0.0
	_active = true
	queue_redraw()

func _process(delta: float) -> void:
	if not _active:
		return

	_elapsed += delta
	_rotation_angle += delta * 4.0
	_pulse_timer += delta

	# Sedikit efek mengambang / hovering bob
	position.y += sin(_elapsed * 5.0) * 0.4

	if _elapsed >= duration_seconds:
		_active = false
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	if not _active:
		return

	var progress := _elapsed / duration_seconds
	var alpha := 1.0
	if progress > 0.8:
		alpha = clampf((1.0 - progress) / 0.2, 0.0, 1.0)

	var core_rad := 7.0
	var ring_rad := 18.0

	# 1. Gelombang Pulsa Disrupsi Spasial
	var pulse_phase := fposmod(_pulse_timer * 2.0, 1.0)
	var wave_rad := ring_rad + (pulse_phase * 28.0)
	var wave_alpha := (1.0 - pulse_phase) * alpha * 0.6
	draw_arc(Vector2.ZERO, wave_rad, 0.0, TAU, 20, Color(drone_color.r, drone_color.g, drone_color.b, wave_alpha), 1.5)

	# 2. Cincin Gyro Holografis Berputar
	var gyro1_pts := PackedVector2Array()
	var gyro2_pts := PackedVector2Array()
	var segs := 16
	for s in range(segs):
		var a := (TAU / float(segs)) * float(s)
		# Cincin 1: Diputar rotasi X/Z
		var p1 := Vector2(cos(a) * ring_rad, sin(a) * ring_rad * 0.4).rotated(_rotation_angle)
		gyro1_pts.append(p1)
		# Cincin 2: Putar berlawanan
		var p2 := Vector2(cos(a) * ring_rad * 0.85, sin(a) * ring_rad * 0.85 * 0.4).rotated(-_rotation_angle * 1.3)
		gyro2_pts.append(p2)
	gyro1_pts.append(gyro1_pts[0])
	gyro2_pts.append(gyro2_pts[0])

	draw_polyline(gyro1_pts, Color(drone_color.r, drone_color.g, drone_color.b, alpha * 0.85), 1.8)
	draw_polyline(gyro2_pts, Color(0.9, 0.6, 1.0, alpha * 0.7), 1.2)

	# 3. Kaki/Bracket Mekanis Drone
	for i in range(3):
		var bracket_ang := (TAU / 3.0) * float(i) + _rotation_angle * 0.5
		var b_end := Vector2(cos(bracket_ang), sin(bracket_ang)) * (ring_rad * 1.1)
		draw_line(Vector2.ZERO, b_end, Color(0.3, 0.3, 0.4, alpha), 2.0)
		draw_circle(b_end, 2.5, Color(drone_color.r, drone_color.g, drone_color.b, alpha))

	# 4. Inti Energi Foton Bercahaya
	draw_circle(Vector2.ZERO, core_rad + 2.0, Color(drone_color.r, drone_color.g, drone_color.b, alpha * 0.4))
	draw_circle(Vector2.ZERO, core_rad, Color(1.0, 1.0, 1.0, alpha * 0.95))
