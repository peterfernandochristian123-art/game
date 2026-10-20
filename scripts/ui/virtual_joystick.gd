class_name FloatingVirtualJoystick
extends Control

## Dynamic Floating Virtual Joystick untuk Kontrol Layar Sentuh Mobile (Story 5.2)
## Muncul otomatis di posisi jempol pertama kali menyentuh zona kiri layar
## Menghitung vektor arah 8-arah ternormalisasi dan memetakan ke aksi move_*

signal vector_changed(vector: Vector2)
signal touch_started(position: Vector2)
signal touch_released()

@export var max_drag_radius: float = 48.0
@export var deadzone: float = 0.15
@export var auto_recenter: bool = true
@export var update_input_actions: bool = true

var output_vector: Vector2 = Vector2.ZERO
var is_active: bool = false
var active_touch_index: int = -1

var joystick_base: Control = null
var joystick_knob: Control = null
var default_base_pos: Vector2 = Vector2(80, 260)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	joystick_base = get_node_or_null("Base")
	joystick_knob = get_node_or_null("Base/Knob")

	if not joystick_base:
		_create_default_visuals()

	_reset_joystick()

func _create_default_visuals() -> void:
	# Buat elemen visual runtime jika tidak dibuat dari scene editor
	joystick_base = Control.new()
	joystick_base.name = "Base"
	joystick_base.size = Vector2(max_drag_radius * 2, max_drag_radius * 2)
	joystick_base.position = default_base_pos - joystick_base.size / 2.0
	joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(joystick_base)

	# Lingkaran base ring
	var base_ring := ColorRect.new()
	base_ring.name = "Ring"
	base_ring.size = joystick_base.size
	base_ring.color = Color(0.1, 0.2, 0.35, 0.35)
	base_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_base.add_child(base_ring)

	# Handle Knob
	joystick_knob = Control.new()
	joystick_knob.name = "Knob"
	joystick_knob.size = Vector2(32, 32)
	joystick_knob.position = (joystick_base.size - joystick_knob.size) / 2.0
	joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_base.add_child(joystick_knob)

	var knob_rect := ColorRect.new()
	knob_rect.size = joystick_knob.size
	knob_rect.color = Color(0.2, 0.85, 1.0, 0.8)
	knob_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_knob.add_child(knob_rect)

func handle_touch_down(pos: Vector2, finger_idx: int = 0) -> void:
	is_active = true
	active_touch_index = finger_idx

	# Pindahkan dasar joystick ke posisi sentuhan jempol (Dynamic Floating)
	if joystick_base:
		joystick_base.global_position = pos - joystick_base.size / 2.0
		joystick_base.modulate.a = 1.0
		_center_knob()

	touch_started.emit(pos)

func handle_touch_drag(pos: Vector2, finger_idx: int = 0) -> void:
	if not is_active or finger_idx != active_touch_index:
		return

	if not joystick_base:
		return

	var base_center: Vector2 = joystick_base.global_position + joystick_base.size / 2.0
	var offset: Vector2 = pos - base_center
	var distance: float = offset.length()

	if distance > max_drag_radius:
		offset = offset.normalized() * max_drag_radius

	# Posisikan knob relatif terhadap pusat base
	if joystick_knob:
		var knob_half: Vector2 = joystick_knob.size / 2.0
		joystick_knob.position = (joystick_base.size / 2.0) + offset - knob_half

	# Hitung output vector
	var norm_dist: float = clampf(distance / max_drag_radius, 0.0, 1.0)
	if norm_dist < deadzone:
		output_vector = Vector2.ZERO
	else:
		output_vector = offset.normalized() * norm_dist

	_update_input_system()
	vector_changed.emit(output_vector)

func handle_touch_up(finger_idx: int = 0) -> void:
	if not is_active or (active_touch_index != -1 and finger_idx != active_touch_index):
		return

	_reset_joystick()
	touch_released.emit()

func _center_knob() -> void:
	if joystick_knob and joystick_base:
		joystick_knob.position = (joystick_base.size - joystick_knob.size) / 2.0

func _reset_joystick() -> void:
	is_active = false
	active_touch_index = -1
	output_vector = Vector2.ZERO
	_center_knob()

	if auto_recenter and joystick_base:
		joystick_base.position = default_base_pos - joystick_base.size / 2.0
		joystick_base.modulate.a = 0.5 # Transparan saat idle

	_release_movement_actions()
	vector_changed.emit(Vector2.ZERO)

func _update_input_system() -> void:
	if not update_input_actions:
		return

	# Petakan sumbu horizontal
	if output_vector.x < -deadzone:
		Input.action_press("move_left", absf(output_vector.x))
		Input.action_release("move_right")
	elif output_vector.x > deadzone:
		Input.action_press("move_right", output_vector.x)
		Input.action_release("move_left")
	else:
		Input.action_release("move_left")
		Input.action_release("move_right")

	# Petakan sumbu vertikal
	if output_vector.y < -deadzone:
		Input.action_press("move_up", absf(output_vector.y))
		Input.action_release("move_down")
	elif output_vector.y > deadzone:
		Input.action_press("move_down", output_vector.y)
		Input.action_release("move_up")
	else:
		Input.action_release("move_up")
		Input.action_release("move_down")

func _release_movement_actions() -> void:
	if not update_input_actions:
		return
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_up")
	Input.action_release("move_down")

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not is_active:
			handle_touch_down(event.position, event.index)
			accept_event()
		elif not event.pressed and is_active and event.index == active_touch_index:
			handle_touch_up(event.index)
			accept_event()
	elif event is InputEventScreenDrag and is_active and event.index == active_touch_index:
		handle_touch_drag(event.position, event.index)
		accept_event()
	# Dukungan mouse drag untuk pengujian di PC
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and not is_active:
				handle_touch_down(event.position, 0)
				accept_event()
			elif not event.pressed and is_active:
				handle_touch_up(0)
				accept_event()
	elif event is InputEventMouseMotion and is_active and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		handle_touch_drag(event.position, 0)
		accept_event()
