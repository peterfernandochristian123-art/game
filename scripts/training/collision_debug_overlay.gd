class_name CollisionDebugOverlay
extends Node2D

## Komponen Visualisasi Kotak Tumbukan untuk Training Mode (Story 5.4)
## Menampilkan bounding box: Merah = Hitbox, Hijau = Hurtbox, Biru = Pushbox / Ledge

const COLOR_HITBOX_FILL := Color(1.0, 0.15, 0.15, 0.4)
const COLOR_HITBOX_LINE := Color(1.0, 0.1, 0.1, 1.0)

const COLOR_HURTBOX_FILL := Color(0.15, 0.95, 0.3, 0.3)
const COLOR_HURTBOX_LINE := Color(0.15, 0.95, 0.3, 1.0)

const COLOR_PUSHBOX_FILL := Color(0.2, 0.6, 1.0, 0.3)
const COLOR_PUSHBOX_LINE := Color(0.2, 0.6, 1.0, 1.0)

@export var overlay_enabled: bool = false
@export var line_width: float = 1.5

var monitored_nodes: Array[Node2D] = []

func _ready() -> void:
	z_index = 100 # Pastikan selalu digambar di atas visual karakter
	visible = overlay_enabled

func _process(_delta: float) -> void:
	if overlay_enabled and visible:
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			toggle_overlay()
			get_viewport().set_input_as_handled()

func toggle_overlay() -> void:
	set_overlay_enabled(not overlay_enabled)

func set_overlay_enabled(enabled: bool) -> void:
	overlay_enabled = enabled
	visible = overlay_enabled
	if visible:
		queue_redraw()

func register_monitored_node(node: Node2D) -> void:
	if node and not monitored_nodes.has(node):
		monitored_nodes.append(node)
		if visible:
			queue_redraw()

func clear_monitored_nodes() -> void:
	monitored_nodes.clear()
	queue_redraw()

func _draw() -> void:
	if not overlay_enabled:
		return

	# Gambar collider dari node yang dipantau
	for node in monitored_nodes:
		if is_instance_valid(node):
			_draw_colliders_recursive(node)

func _draw_colliders_recursive(node: Node) -> void:
	if not is_instance_valid(node):
		return

	if node is CollisionShape2D and node.visible:
		_draw_shape_node(node as CollisionShape2D)

	for child in node.get_children():
		_draw_colliders_recursive(child)

func _draw_shape_node(col_node: CollisionShape2D) -> void:
	if not col_node.shape:
		return

	var fill_color := COLOR_PUSHBOX_FILL
	var line_color := COLOR_PUSHBOX_LINE

	# Tentukan warna berdasarkan collision layer parent
	var parent_area := col_node.get_parent()
	if parent_area is Area2D:
		var layer: int = (parent_area as Area2D).collision_layer
		# Layer 3 (StrikeHitbox) atau Layer 4 (GrabHitbox) -> MERAH
		if (layer & 4) != 0 or (layer & 8) != 0 or parent_area.name.to_lower().contains("hitbox"):
			fill_color = COLOR_HITBOX_FILL
			line_color = COLOR_HITBOX_LINE
		# Layer 2 (Hurtbox) -> HIJAU
		elif (layer & 2) != 0 or parent_area.name.to_lower().contains("hurtbox"):
			fill_color = COLOR_HURTBOX_FILL
			line_color = COLOR_HURTBOX_LINE
		# Layer 5 (LedgeSensor) -> BIRU TERANG
		elif (layer & 16) != 0 or parent_area.name.to_lower().contains("ledge"):
			fill_color = COLOR_PUSHBOX_FILL
			line_color = COLOR_PUSHBOX_LINE
	elif parent_area is CharacterBody2D or parent_area is StaticBody2D:
		# Pushbox fisik karakter & panggung arena -> BIRU
		fill_color = COLOR_PUSHBOX_FILL
		line_color = COLOR_PUSHBOX_LINE

	var shape := col_node.shape
	var xform: Transform2D = global_transform.affine_inverse() * col_node.global_transform

	if shape is RectangleShape2D:
		var rect_shape := shape as RectangleShape2D
		var half_ext := rect_shape.size / 2.0
		var points := PackedVector2Array([
			xform * Vector2(-half_ext.x, -half_ext.y),
			xform * Vector2(half_ext.x, -half_ext.y),
			xform * Vector2(half_ext.x, half_ext.y),
			xform * Vector2(-half_ext.x, half_ext.y)
		])
		draw_colored_polygon(points, fill_color)
		points.append(points[0]) # Tutup loop garis
		draw_polyline(points, line_color, line_width)
	elif shape is CircleShape2D:
		var circle_shape := shape as CircleShape2D
		var center := xform * Vector2.ZERO
		draw_circle(center, circle_shape.radius, fill_color)
		draw_arc(center, circle_shape.radius, 0.0, TAU, 32, line_color, line_width)
	elif shape is CapsuleShape2D:
		var cap := shape as CapsuleShape2D
		var center := xform * Vector2.ZERO
		draw_circle(center, cap.radius, fill_color)
		draw_arc(center, cap.radius, 0.0, TAU, 24, line_color, line_width)
