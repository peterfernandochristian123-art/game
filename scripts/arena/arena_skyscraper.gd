class_name ArenaSkyscraper
extends Node2D

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")

## Arena Pencakar Langit: Zero-G Skyscraper Platform (Story 4.1)
## Panggung terbuka selebar 1280 piksel melayang tinggi di atas New Babel-01 tanpa dinding pengaman
## Memantau batas tepi kiri (X < 64) dan kanan (X > 1344) untuk memicu Cliffhanger System

signal ledge_reached(mecha: Node2D, side: StringName)

@export var platform_width: float = CombatConstants.ARENA_PLATFORM_WIDTH
@export var left_bound: float = CombatConstants.ARENA_LEFT_BOUND
@export var right_bound: float = CombatConstants.ARENA_RIGHT_BOUND

@onready var platform_body: StaticBody2D = $Platform
@onready var left_ledge_sensor: Area2D = $LeftLedgeSensor
@onready var right_ledge_sensor: Area2D = $RightLedgeSensor

var registered_fighters: Array[Node2D] = []

func _ready() -> void:
	_setup_boundaries_and_sensors()
	_find_fighters_in_tree()

func register_fighter(fighter: Node2D) -> void:
	if fighter and fighter not in registered_fighters:
		registered_fighters.append(fighter)

func unregister_fighter(fighter: Node2D) -> void:
	registered_fighters.erase(fighter)

func _setup_boundaries_and_sensors() -> void:
	# Konfigurasi mask sensor pada Layer 1 & 2
	if left_ledge_sensor:
		left_ledge_sensor.collision_layer = 1 << (CombatConstants.LAYER_LEDGE_SENSOR - 1)
		left_ledge_sensor.collision_mask = 1 | (1 << (CombatConstants.LAYER_HURTBOX - 1))
		if not left_ledge_sensor.body_entered.is_connected(_on_left_sensor_body_entered):
			left_ledge_sensor.body_entered.connect(_on_left_sensor_body_entered)

	if right_ledge_sensor:
		right_ledge_sensor.collision_layer = 1 << (CombatConstants.LAYER_LEDGE_SENSOR - 1)
		right_ledge_sensor.collision_mask = 1 | (1 << (CombatConstants.LAYER_HURTBOX - 1))
		if not right_ledge_sensor.body_entered.is_connected(_on_right_sensor_body_entered):
			right_ledge_sensor.body_entered.connect(_on_right_sensor_body_entered)

func _find_fighters_in_tree() -> void:
	for child in get_children():
		if child is CharacterBody2D and child.has_method("take_hit"):
			register_fighter(child)

func is_within_platform(x_pos: float) -> bool:
	return x_pos >= left_bound and x_pos <= right_bound

func get_platform_top_y() -> float:
	if platform_body:
		return platform_body.global_position.y - 12.0
	return 280.0

func _physics_process(_delta: float) -> void:
	# Pengecekan posisi fisika deterministic untuk setiap petarung
	for fighter in registered_fighters:
		if not is_instance_valid(fighter):
			continue
		var f_pos: Vector2 = fighter.global_position
		var on_ground: bool = fighter.is_on_floor() if fighter.has_method("is_on_floor") else false

		# Melewati batas tepi di udara
		if not on_ground:
			if f_pos.x < left_bound:
				notify_ledge_cross(fighter, &"left")
			elif f_pos.x > right_bound:
				notify_ledge_cross(fighter, &"right")

func notify_ledge_cross(fighter: Node2D, side: StringName) -> void:
	ledge_reached.emit(fighter, side)
	if fighter.has_method("trigger_cliffhanger"):
		fighter.trigger_cliffhanger(side)
	var bus = get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("cliffhanger_triggered"):
		bus.cliffhanger_triggered.emit(fighter.get_instance_id(), side)

func _on_left_sensor_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("take_hit"):
		notify_ledge_cross(body, &"left")

func _on_right_sensor_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("take_hit"):
		notify_ledge_cross(body, &"right")
