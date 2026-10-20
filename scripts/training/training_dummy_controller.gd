class_name TrainingDummyController
extends Node

## Pengendali Perilaku Target Dummy untuk Training Mode (Story 5.4)
## Mengatur mode Stand, Crouch, Block All, Random Parry, dan Reset Cepat (F3)

signal dummy_mode_changed(mode: DummyMode)
signal training_reset_executed()

enum DummyMode {
	STAND,
	CROUCH,
	BLOCK_ALL,
	RANDOM_PARRY
}

@export var current_mode: DummyMode = DummyMode.STAND
@export var random_parry_chance: float = 0.5

var p1_fighter: Node2D = null
var dummy_fighter: Node2D = null

# Default spawn positions pada platform arena skyscraper (Center stage X=704)
const DEFAULT_P1_SPAWN := Vector2(500, 288)
const DEFAULT_P2_SPAWN := Vector2(900, 288)

func setup(p1: Node2D, dummy: Node2D) -> void:
	p1_fighter = p1
	dummy_fighter = dummy
	set_dummy_mode(DummyMode.STAND)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(dummy_fighter) or not is_instance_valid(p1_fighter):
		return

	_process_dummy_behavior()

func _process_dummy_behavior() -> void:
	match current_mode:
		DummyMode.STAND:
			dummy_fighter.set("simulated_horizontal_input", 0.0)
		DummyMode.BLOCK_ALL:
			# Auto-block: selalu menahan arah mundur dari posisi P1
			var dir_away: float = 1.0 if p1_fighter.global_position.x < dummy_fighter.global_position.x else -1.0
			dummy_fighter.set("simulated_horizontal_input", dir_away)
		DummyMode.RANDOM_PARRY:
			dummy_fighter.set("simulated_horizontal_input", 0.0)
			# Cek jika P1 sedang dalam AttackState dan startup
			if _is_p1_attacking():
				if randf() <= random_parry_chance:
					_trigger_dummy_parry()
		DummyMode.CROUCH:
			dummy_fighter.set("simulated_horizontal_input", 0.0)

func _is_p1_attacking() -> bool:
	if not p1_fighter or not ("state_machine" in p1_fighter):
		return false
	var sm = p1_fighter.get("state_machine")
	if sm and sm.get("current_state"):
		var sname: StringName = sm.current_state.name
		return sname == &"Attack"
	return false

func _trigger_dummy_parry() -> void:
	if not dummy_fighter or not ("state_machine" in dummy_fighter):
		return
	var sm = dummy_fighter.get("state_machine")
	if sm and sm.get("current_state") and sm.current_state.name == &"Idle":
		sm.change_state(&"Parry")

func set_dummy_mode(mode: DummyMode) -> void:
	current_mode = mode
	dummy_mode_changed.emit(current_mode)

func cycle_dummy_mode() -> void:
	var total := DummyMode.values().size()
	var next_idx := (int(current_mode) + 1) % total
	set_dummy_mode(next_idx as DummyMode)

func reset_positions() -> void:
	if is_instance_valid(p1_fighter):
		p1_fighter.global_position = DEFAULT_P1_SPAWN
		p1_fighter.velocity = Vector2.ZERO
		if p1_fighter.has_method("set_hp"):
			p1_fighter.set_hp(p1_fighter.max_hp)
		if p1_fighter.get("heat_component"):
			p1_fighter.heat_component.reset()
		if p1_fighter.has_method("reset_cliffhanger"):
			p1_fighter.reset_cliffhanger()
		p1_fighter.set("combo_hit_count", 0)
		p1_fighter.set("is_eliminated", false)
		if p1_fighter.get("state_machine"):
			p1_fighter.state_machine.change_state(&"Idle")

	if is_instance_valid(dummy_fighter):
		dummy_fighter.global_position = DEFAULT_P2_SPAWN
		dummy_fighter.velocity = Vector2.ZERO
		if dummy_fighter.has_method("set_hp"):
			dummy_fighter.set_hp(dummy_fighter.max_hp)
		if dummy_fighter.get("heat_component"):
			dummy_fighter.heat_component.reset()
		if dummy_fighter.has_method("reset_cliffhanger"):
			dummy_fighter.reset_cliffhanger()
		dummy_fighter.set("combo_hit_count", 0)
		dummy_fighter.set("is_eliminated", false)
		if dummy_fighter.get("state_machine"):
			dummy_fighter.state_machine.change_state(&"Idle")

	training_reset_executed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	if event.keycode == KEY_F2:
		cycle_dummy_mode()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F3:
		reset_positions()
		get_viewport().set_input_as_handled()
