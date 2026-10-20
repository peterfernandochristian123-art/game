class_name TrainingManager
extends Node2D

## Pengendali Utama Training Mode Suite (Story 5.4)
## Merakit Arena, Fighter P1, Dummy P2, Combat HUD, Frame Inspector, dan Collision Overlay

const CombatHUDScript = preload("res://scripts/ui/combat_hud.gd")
const CollisionDebugOverlayScript = preload("res://scripts/training/collision_debug_overlay.gd")
const FrameInspectorScript = preload("res://scripts/training/frame_inspector.gd")
const TrainingDummyControllerScript = preload("res://scripts/training/training_dummy_controller.gd")

@onready var p1: Node2D = $Fighters/P1
@onready var dummy: Node2D = $Fighters/Dummy
@onready var hud: Node = $UI/CombatHUD
@onready var collision_overlay: Node2D = $CollisionOverlay
@onready var frame_inspector: Control = $UI/FrameInspector
@onready var dummy_controller: Node = $DummyController

@onready var dummy_status_label: Label = $UI/TrainingToolbar/DummyStatus
@onready var btn_hitbox_toggle: Button = $UI/TrainingToolbar/BtnToggleHitbox
@onready var btn_dummy_mode: Button = $UI/TrainingToolbar/BtnDummyMode
@onready var btn_reset: Button = $UI/TrainingToolbar/BtnReset

func _ready() -> void:
	if not p1 or not dummy:
		return

	# 1. Setup HUD & Bindings
	if hud:
		hud.bind_fighters(p1, dummy)
		if hud.round_label:
			hud.round_label.text = "TRAINING LAB"
		if hud.timer_label:
			hud.timer_label.text = "∞"

	# 2. Setup Collision Debug Overlay
	if collision_overlay:
		collision_overlay.register_monitored_node(p1)
		collision_overlay.register_monitored_node(dummy)
		var platform := get_node_or_null("ArenaSkyscraper/Platform") as Node2D
		if platform:
			collision_overlay.register_monitored_node(platform)

	# 3. Setup Dummy Controller
	if dummy_controller:
		dummy_controller.setup(p1, dummy)
		dummy_controller.dummy_mode_changed.connect(_on_dummy_mode_changed)
		_on_dummy_mode_changed(dummy_controller.current_mode)

	# 4. Hubungkan UI Toolbar Sentuh
	if btn_hitbox_toggle:
		btn_hitbox_toggle.pressed.connect(func():
			if collision_overlay:
				collision_overlay.toggle_overlay()
		)
	if btn_dummy_mode:
		btn_dummy_mode.pressed.connect(func():
			if dummy_controller:
				dummy_controller.cycle_dummy_mode()
		)
	if btn_reset:
		btn_reset.pressed.connect(func():
			if dummy_controller:
				dummy_controller.reset_positions()
		)

	# 5. Hubungkan EventBus untuk mendeteksi serangan & Frame Inspector
	if is_instance_valid(EventBus):
		EventBus.hit_confirmed.connect(_on_hit_confirmed)

	# Hook P1 attack state untuk mencatat frame data
	if p1.get("state_machine"):
		var atk_state = p1.state_machine.get_node_or_null("Attack")
		if atk_state and atk_state.has_signal("attack_started"):
			atk_state.attack_started.connect(_on_p1_attack_started)

func _on_p1_attack_started(attack_data: Resource) -> void:
	if frame_inspector and attack_data:
		frame_inspector.record_attack(attack_data)

func _on_hit_confirmed(attacker: Node2D, victim: Node2D, hit_data: Variant) -> void:
	if attacker == p1 and frame_inspector and hit_data is Dictionary:
		var blocked: bool = hit_data.get("blocked", false)
		var dmg: int = hit_data.get("damage", 40)
		var m_name: String = hit_data.get("attack_name", frame_inspector.last_move_name)
		var adv_hit: int = frame_inspector.last_advantage_on_hit
		var adv_block: int = frame_inspector.last_advantage_on_block
		frame_inspector.record_manual_data(
			m_name,
			frame_inspector.last_startup,
			frame_inspector.last_active,
			frame_inspector.last_recovery,
			adv_hit,
			adv_block,
			dmg,
			frame_inspector.last_heat
		)

func _on_dummy_mode_changed(mode: TrainingDummyControllerScript.DummyMode) -> void:
	if not dummy_status_label:
		return
	var mode_name: String = "STAND"
	match mode:
		TrainingDummyControllerScript.DummyMode.STAND:
			mode_name = "STAND (IDLE)"
		TrainingDummyControllerScript.DummyMode.CROUCH:
			mode_name = "CROUCH"
		TrainingDummyControllerScript.DummyMode.BLOCK_ALL:
			mode_name = "BLOCK ALL"
		TrainingDummyControllerScript.DummyMode.RANDOM_PARRY:
			mode_name = "RANDOM PARRY"

	dummy_status_label.text = "DUMMY: " + mode_name

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
			get_viewport().set_input_as_handled()
