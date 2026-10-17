extends CharacterBody2D

# Konstanta Gerakan
const WALK_SPEED: float = 240.0
const JUMP_VELOCITY: float = -420.0
const DASH_SPEED: float = 600.0
const DASH_DURATION: float = 0.15 # 9 frame

# Sistem Panas (Thermal Engine)
var heat: float = 0.0
var max_heat: float = 100.0
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var can_air_dash: bool = true

# Gravitasi dari Project Settings
var gravity: float = 980.0

@onready var sprite: ColorRect = $MechaVisual
@onready var heat_bar: ProgressBar = $"../UI/HUD/HeatBar"
@onready var heat_label: Label = $"../UI/HUD/HeatLabel"
@onready var status_label: Label = $"../UI/HUD/StatusLabel"

func _ready() -> void:
	_setup_inputs()

func _setup_inputs() -> void:
	_bind_key("ui_left", KEY_A)
	_bind_key("ui_right", KEY_D)
	_bind_key("ui_up", KEY_W)
	_bind_key("ui_down", KEY_S)

func _bind_key(action: StringName, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and (event.physical_keycode == key or event.keycode == key):
			return
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	ev.keycode = key
	InputMap.action_add_event(action, ev)

func _physics_process(delta: float) -> void:
	# Pendinginan pasif saat tidak dash (-12% per detik)
	if not is_dashing:
		heat = max(0.0, heat - 12.0 * delta)
	
	# Update Dash Timer
	if is_dashing:
		dash_timer -= delta
		velocity = dash_direction * DASH_SPEED
		if dash_timer <= 0.0:
			is_dashing = false
	else:
		# Tambahkan gravitasi jika di udara
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			can_air_dash = true

		# Input Gerakan Horizontal (A/D atau Panah Kiri/Kanan)
		var input_x: float = Input.get_axis("ui_left", "ui_right")
		if Input.is_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_A):
			input_x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_D):
			input_x += 1.0
		input_x = clampf(input_x, -1.0, 1.0)

		if input_x != 0.0:
			velocity.x = input_x * WALK_SPEED
			# Arah visual mecha
			if sprite:
				sprite.scale.x = 1.0 if input_x > 0 else -1.0
		else:
			velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED)

		# Input Lompat (Space, W, atau Panah Atas)
		var jump_pressed: bool = (
			Input.is_action_just_pressed("ui_accept")
			or Input.is_action_just_pressed("ui_up")
			or Input.is_action_just_pressed("jump")
		)
		if jump_pressed and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Input Dash (Tombol Shift, Key X, atau Action Dash)
		var dash_pressed: bool = (
			Input.is_key_pressed(KEY_SHIFT)
			or Input.is_key_pressed(KEY_X)
			or Input.is_action_just_pressed("dash")
			or Input.is_action_just_pressed("ui_focus_next")
		)
		if dash_pressed and not is_dashing and (is_on_floor() or can_air_dash):
			start_dash(input_x)

	move_and_slide()
	update_ui()

func start_dash(input_x: float) -> void:
	var dir_x: float = input_x if input_x != 0.0 else (1.0 if sprite.scale.x >= 0 else -1.0)
	var dir_y: float = 0.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_W):
		dir_y = -0.7
	elif (Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_S)) and not is_on_floor():
		dir_y = 0.7

	dash_direction = Vector2(dir_x, dir_y).normalized()
	is_dashing = true
	dash_timer = DASH_DURATION
	if not is_on_floor():
		can_air_dash = false
	
	# Menambah Panas (+15%)
	heat = min(max_heat, heat + 15.0)

func update_ui() -> void:
	if heat_bar:
		heat_bar.value = heat
	if heat_label:
		heat_label.text = "HEAT: %d%%" % int(heat)
	if status_label:
		if heat >= 80.0:
			status_label.text = "STATUS: [ OVERCLOCK ACTIVE (+20% DMG / SUPER ARMOR) ]"
			status_label.modulate = Color(1.0, 0.4, 0.0)
		else:
			status_label.text = "STATUS: NOMINAL"
			status_label.modulate = Color(0.2, 0.9, 1.0)
