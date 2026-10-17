class_name StateMachine
extends Node

const BaseState = preload("res://scripts/combat/fsm/base_state.gd")

## Pengelola Hierarchical Finite State Machine (HSM) untuk Mecha
## Menjamin transisi deterministik pada _physics_process dan safe fallback saat anomali

@export var initial_state: BaseState = null

var states: Dictionary = {}
var current_state: BaseState = null
var previous_state: BaseState = null
var character: CharacterBody2D = null

func _ready() -> void:
	# Hubungkan referensi CharacterBody2D dari owner atau parent
	if owner is CharacterBody2D:
		character = owner as CharacterBody2D
	elif get_parent() is CharacterBody2D:
		character = get_parent() as CharacterBody2D

	# Daftarkan seluruh child node yang merupakan BaseState
	for child in get_children():
		if child is BaseState:
			states[child.name] = child
			child.setup(character, self)

	# Inisialisasi initial state
	if initial_state and states.has(initial_state.name):
		current_state = initial_state
	elif states.has(&"Idle"):
		current_state = states[&"Idle"]
	elif not states.is_empty():
		current_state = states.values()[0]

	if current_state:
		current_state.enter()
		if OS.is_debug_build() and character:
			print("[STATE][%s] Inisialisasi awal ke state: %s" % [character.name, current_state.name])

func physics_update(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func handle_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

func change_state(target_state_name: StringName) -> void:
	if not states.has(target_state_name):
		push_error("[FSM] State tidak terdaftar: %s pada %s. Fallback ke Idle." % [
			target_state_name, 
			character.name if character else name
		])
		if states.has(&"Idle"):
			target_state_name = &"Idle"
		else:
			return

	if current_state and current_state.name == target_state_name:
		return

	var old_state_name: StringName = current_state.name if current_state else &"None"
	
	if current_state:
		current_state.exit()

	previous_state = current_state
	current_state = states[target_state_name]

	if OS.is_debug_build():
		print("[STATE][%s] Transisi dari %s ke %s" % [
			character.name if character else "Mecha", 
			old_state_name, 
			current_state.name
		])

	# Pancarkan event global jika EventBus autoload tersedia
	if is_instance_valid(EventBus):
		EventBus.state_changed.emit(character, old_state_name, current_state.name)

	current_state.enter()
