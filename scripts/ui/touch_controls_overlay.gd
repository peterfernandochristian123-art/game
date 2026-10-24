class_name TouchControlsOverlay
extends Control

const FloatingVirtualJoystick = preload("res://scripts/ui/virtual_joystick.gd")

## Pengendali Overlay Kontrol Layar Sentuh & Autodeteksi Gamepad (Story 5.2)
## Mengintegrasikan Dynamic Floating Joystick di sisi kiri dan 6 tombol aksi ergonomis di sisi kanan

signal input_mode_changed(mode: StringName)
signal action_button_pressed(action_name: StringName)
signal action_button_released(action_name: StringName)

enum InputMode {
	TOUCH,
	GAMEPAD,
	KEYBOARD
}

const ACTION_BUTTONS := [
	{"name": "BtnNormal", "action": &"attack_light", "label": "ATK [J/Z]", "color": Color(0.2, 0.9, 1.0, 0.85)},
	{"name": "BtnDash", "action": &"dash", "label": "DASH [X]", "color": Color(0.3, 1.0, 0.5, 0.85)},
	{"name": "BtnSkill1", "action": &"skill1", "label": "SKILL 1 [U]", "color": Color(1.0, 0.8, 0.2, 0.85)},
	{"name": "BtnSkill2", "action": &"skill2", "label": "SKILL 2 [I]", "color": Color(1.0, 0.5, 0.2, 0.85)},
	{"name": "BtnParry", "action": &"parry", "label": "PARRY [L]", "color": Color(0.9, 0.3, 1.0, 0.85)},
	{"name": "BtnUltimate", "action": &"ultimate", "label": "ULTI [O]", "color": Color(1.0, 0.2, 0.35, 0.85)}
]

@export var auto_hide_on_controller: bool = true
@export var touch_opacity: float = 0.85

var current_mode: InputMode = InputMode.TOUCH
var action_button_nodes: Dictionary = {} # action_name -> Control/Button
var joystick: FloatingVirtualJoystick = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	joystick = get_node_or_null("LeftTouchZone/VirtualJoystick") as FloatingVirtualJoystick
	_setup_action_buttons()

	# Cek apakah kontroler gamepad sudah terhubung saat awal
	if Input.get_connected_joypads().size() > 0 and not OS.has_feature("mobile"):
		set_input_mode(InputMode.GAMEPAD)
	else:
		set_input_mode(InputMode.TOUCH)

	Input.joy_connection_changed.connect(_on_joy_connection_changed)

func _setup_action_buttons() -> void:
	action_button_nodes.clear()
	var right_container := get_node_or_null("RightActionZone")
	if not right_container:
		return

	for def in ACTION_BUTTONS:
		var btn := right_container.get_node_or_null(def["name"]) as Button
		if not btn:
			btn = Button.new()
			btn.name = def["name"]
			btn.text = def["label"]
			btn.focus_mode = Control.FOCUS_NONE
			right_container.add_child(btn)

		var act_name: StringName = def["action"]
		action_button_nodes[act_name] = btn

		btn.button_down.connect(func(): _on_action_pressed(act_name, btn))
		btn.button_up.connect(func(): _on_action_released(act_name, btn))

func _input(event: InputEvent) -> void:
	if not is_inside_tree():
		return

	# Deteksi input gamepad
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.3):
		if current_mode != InputMode.GAMEPAD:
			set_input_mode(InputMode.GAMEPAD)
	# Deteksi input layar sentuh
	elif event is InputEventScreenTouch and event.pressed:
		if current_mode != InputMode.TOUCH:
			set_input_mode(InputMode.TOUCH)
	# Deteksi keyboard di PC
	elif event is InputEventKey and event.pressed:
		if current_mode != InputMode.KEYBOARD and not OS.has_feature("mobile"):
			set_input_mode(InputMode.KEYBOARD)

func _on_joy_connection_changed(_device: int, connected: bool) -> void:
	if connected and not OS.has_feature("mobile"):
		set_input_mode(InputMode.GAMEPAD)
	elif not connected and Input.get_connected_joypads().is_empty():
		set_input_mode(InputMode.TOUCH if OS.has_feature("mobile") else InputMode.KEYBOARD)

func set_input_mode(new_mode: InputMode) -> void:
	current_mode = new_mode
	var mode_name: StringName = &"touch"
	match current_mode:
		InputMode.TOUCH:
			mode_name = &"touch"
			visible = true
		InputMode.GAMEPAD:
			mode_name = &"gamepad"
			if auto_hide_on_controller and not OS.has_feature("mobile"):
				visible = false
		InputMode.KEYBOARD:
			mode_name = &"keyboard"
			if auto_hide_on_controller and not OS.has_feature("mobile"):
				visible = false

	input_mode_changed.emit(mode_name)

func _on_action_pressed(act: StringName, btn_node: Control) -> void:
	Input.action_press(act)
	if btn_node:
		var tw := create_tween()
		tw.tween_property(btn_node, "scale", Vector2(0.92, 0.92), 0.05)
		btn_node.modulate = Color(1.3, 1.3, 1.3, 1.0) # Flash brightness

	action_button_pressed.emit(act)

func _on_action_released(act: StringName, btn_node: Control) -> void:
	Input.action_release(act)
	if btn_node:
		var tw := create_tween()
		tw.tween_property(btn_node, "scale", Vector2(1.0, 1.0), 0.05)
		btn_node.modulate = Color(1.0, 1.0, 1.0, 1.0)

	action_button_released.emit(act)

func is_action_mapped(act: StringName) -> bool:
	return action_button_nodes.has(act)

func get_button_for_action(act: StringName) -> Button:
	return action_button_nodes.get(act, null)
