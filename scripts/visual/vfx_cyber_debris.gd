class_name VFXCyberDebris
extends Node2D

## Efek Visual Puing Lempeng Baja Mecha (Mecha Armor Shrapnel & Cyber Debris)
## Menghasilkan pecahan poligon logam berputar tajam yang terhempas dari armor mecha
## dengan gravitasi, hambatan udara, dan jejak bara foton yang memudar.

@export var debris_color: Color = Color(0.9, 0.9, 1.0, 1.0)
@export var duration_seconds: float = 0.35

class Shard:
	var pos: Vector2
	var vel: Vector2
	var rot: float
	var rot_speed: float
	var shape: PackedVector2Array
	var is_glow: bool

var _shards: Array[Shard] = []
var _elapsed: float = 0.0
var _active: bool = false

func _ready() -> void:
	z_index = 56

func trigger_debris(pos: Vector2, blast_dir: Vector2 = Vector2.UP, count: int = 6, custom_color: Color = Color.TRANSPARENT) -> void:
	global_position = pos
	if custom_color != Color.TRANSPARENT:
		debris_color = custom_color

	_elapsed = 0.0
	_active = true
	_shards.clear()

	var norm_dir := blast_dir.normalized() if blast_dir.length_squared() > 0.01 else Vector2.UP

	for i in range(count):
		var sh := Shard.new()
		sh.pos = Vector2.ZERO

		# Sudut sebaran kerucut berlawanan arah serangan
		var spread_angle := randf_range(-PI * 0.4, PI * 0.4)
		var dir := norm_dir.rotated(spread_angle)
		var speed := randf_range(140.0, 360.0)
		sh.vel = dir * speed + Vector2(0, randf_range(-80.0, 20.0))

		sh.rot = randf_range(0.0, TAU)
		sh.rot_speed = randf_range(-14.0, 14.0)
		sh.is_glow = randf() < 0.4

		# Bentuk geometris serpihan armor (segitiga atau trapesium kecil)
		var sz := randf_range(3.0, 6.0)
		if randf() < 0.5:
			# Segitiga runcing
			sh.shape = PackedVector2Array([
				Vector2(-sz, sz * 0.6),
				Vector2(sz * 1.2, 0),
				Vector2(-sz * 0.5, -sz * 0.8)
			])
		else:
			# Segiempat pelat armor
			sh.shape = PackedVector2Array([
				Vector2(-sz, -sz * 0.6),
				Vector2(sz, -sz * 0.4),
				Vector2(sz * 0.8, sz * 0.7),
				Vector2(-sz * 0.7, sz * 0.5)
			])

		_shards.append(sh)

	queue_redraw()

func _process(delta: float) -> void:
	if not _active:
		return

	_elapsed += delta

	for sh in _shards:
		sh.pos += sh.vel * delta
		sh.vel.y += 520.0 * delta # Gravitasi realistis
		sh.vel.x *= 0.96 # Drag udara
		sh.rot += sh.rot_speed * delta

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

	for sh in _shards:
		var xform_pts := PackedVector2Array()
		for pt in sh.shape:
			xform_pts.append(sh.pos + pt.rotated(sh.rot))

		# Warna tubuh lempeng baja
		var body_col := Color(0.25, 0.3, 0.4, alpha)
		if sh.is_glow:
			body_col = Color(debris_color.r * 0.9, debris_color.g * 0.9, debris_color.b * 0.9, alpha)

		draw_colored_polygon(xform_pts, body_col)

		# Outline berpijar
		var closed := xform_pts.duplicate()
		closed.append(xform_pts[0])
		var border_col := Color(debris_color.r, debris_color.g, debris_color.b, alpha * 0.9)
		draw_polyline(closed, border_col, 1.2)

		# Titik cahaya inti bara foton
		if sh.is_glow:
			draw_circle(sh.pos, 1.5, Color(1.0, 1.0, 1.0, alpha))
