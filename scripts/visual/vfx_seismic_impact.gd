class_name VFXSeismicImpact
extends Node2D

## Efek Visual Hantaman Seismik & Retakan Tanah (Bulwark Piledriver & Unit-0 Shockwave)
## Menampilkan retakan tanah bergerigi, puing bebatuan terlontar, dan gelombang debu horizontal

@export var impact_color: Color = Color(1.0, 0.55, 0.15, 1.0)
@export var fissure_length: float = 90.0
@export var duration_seconds: float = 0.45

var _elapsed: float = 0.0
var _active: bool = false
var _facing: int = 1

class Debris:
	var pos: Vector2
	var vel: Vector2
	var size: float
	var rot: float
	var rot_speed: float

var _debris_list: Array[Debris] = []
var _fissure_points: Array[PackedVector2Array] = []
var _smoke_plumes: Array[Dictionary] = []

func _ready() -> void:
	z_index = 51

func trigger_impact(pos: Vector2, facing_dir: int = 1, custom_color: Color = Color.TRANSPARENT, length: float = 90.0, duration: float = 0.45) -> void:
	global_position = pos
	_facing = facing_dir
	fissure_length = length
	duration_seconds = duration
	if custom_color != Color.TRANSPARENT:
		impact_color = custom_color

	_elapsed = 0.0
	_active = true

	# Hasilkan puing-puing batu terlontar
	_debris_list.clear()
	var debris_count := 12
	for i in range(debris_count):
		var d := Debris.new()
		d.pos = Vector2.ZERO
		var spread_x := randf_range(20.0, 160.0) * float(_facing)
		if randf() < 0.25:
			spread_x *= -0.5
		var vel_y := randf_range(-210.0, -100.0)
		d.vel = Vector2(spread_x, vel_y)
		d.size = randf_range(3.0, 7.0)
		d.rot = randf_range(0.0, TAU)
		d.rot_speed = randf_range(-8.0, 8.0)
		_debris_list.append(d)

	# Hasilkan gumpalan debu dan asap tanah
	_smoke_plumes.clear()
	for s in range(6):
		var frac := float(s) / 6.0
		_smoke_plumes.append({
			"pos": Vector2(frac * fissure_length * float(_facing), randf_range(-2.0, 4.0)),
			"vel": Vector2(randf_range(-20.0, 20.0), randf_range(-65.0, -25.0)),
			"size": randf_range(6.0, 12.0)
		})

	# Hasilkan pola retakan tanah bergerigi
	_fissure_points.clear()
	var main_branch := PackedVector2Array()
	main_branch.append(Vector2.ZERO)
	var steps := 6
	var step_dist := (fissure_length * float(_facing)) / float(steps)
	var cur := Vector2.ZERO
	for s in range(steps):
		cur.x += step_dist
		cur.y = randf_range(-3.0, 5.0)
		main_branch.append(cur)
	_fissure_points.append(main_branch)

	# Cabang retakan sekunder
	var sub_branch := PackedVector2Array()
	sub_branch.append(main_branch[2])
	var sub_cur := main_branch[2]
	for s in range(3):
		sub_cur.x += step_dist * 0.7
		sub_cur.y += randf_range(4.0, 10.0)
		sub_branch.append(sub_cur)
	_fissure_points.append(sub_branch)

	queue_redraw()

func _process(delta: float) -> void:
	if not _active:
		return

	_elapsed += delta

	# Update posisi puing dengan gravitasi
	for d in _debris_list:
		d.pos += d.vel * delta
		d.vel.y += 480.0 * delta
		d.rot += d.rot_speed * delta

	# Update gumpalan asap
	for sm in _smoke_plumes:
		sm["pos"] += sm["vel"] * delta
		sm["size"] += 9.0 * delta
		sm["vel"].y *= 0.94

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

	# 1. Gambar retakan tanah bercahaya & pendaran magma dalam
	var glow_col := Color(impact_color.r, impact_color.g * 0.7, impact_color.b * 0.2, alpha * 0.45)
	var crack_col := Color(impact_color.r, impact_color.g, impact_color.b, alpha * 0.95)
	for branch in _fissure_points:
		draw_polyline(branch, glow_col, 6.0)
		draw_polyline(branch, crack_col, 3.0)
		draw_polyline(branch, Color(1.0, 1.0, 1.0, alpha * 0.85), 1.2)

	# 2. Gelombang kejut tanah horizontal & busur riak tanah
	var shock_width := fissure_length * (0.3 + progress * 0.9)
	var shock_rect := Rect2(0, -6, shock_width * float(_facing), 12)
	var wave_col := Color(impact_color.r, impact_color.g, impact_color.b, alpha * 0.35)
	draw_rect(shock_rect, wave_col)
	draw_arc(Vector2(shock_width * float(_facing) * 0.5, 0), shock_width * 0.4, -PI * 0.6, PI * 0.6, 12, wave_col, 2.0)

	# 3. Gumpalan debu seismik mengepul ke atas
	for sm in _smoke_plumes:
		var sm_col := Color(impact_color.r * 0.4 + 0.3, impact_color.g * 0.4 + 0.3, impact_color.b * 0.4 + 0.3, alpha * 0.5)
		draw_circle(sm["pos"], sm["size"], sm_col)
		draw_circle(sm["pos"], sm["size"] * 0.5, Color(1.0, 0.95, 0.7, alpha * 0.3))

	# 4. Puing-puing batu terlontar
	for d in _debris_list:
		var deb_col := Color(impact_color.r * 0.8, impact_color.g * 0.8, impact_color.b * 0.8, alpha)
		var s := d.size * (1.0 - progress * 0.25)
		var p1 := d.pos + Vector2(-s, -s).rotated(d.rot)
		var p2 := d.pos + Vector2(s, -s).rotated(d.rot)
		var p3 := d.pos + Vector2(s, s).rotated(d.rot)
		var p4 := d.pos + Vector2(-s, s).rotated(d.rot)
		draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), deb_col)
		draw_circle(d.pos, s * 0.4, Color(1.0, 1.0, 1.0, alpha * 0.75))
