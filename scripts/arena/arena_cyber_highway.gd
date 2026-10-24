class_name ArenaCyberHighway
extends Node2D

## Arena Jalan Tol Cyber: Neo-Shibuya Highway (Rainy Overpass)
## Panggung jalan tol layang beraspal basah selebar 1280 piksel di tengah badai hujan megacity
## Dikelilingi tembok pembatas baja kokoh di sisi kiri (X=64) dan kanan (X=1344) untuk Wall-Bounce combo.

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")
const CyberHighwayBackgroundScript = preload("res://scripts/arena/cyber_highway_background.gd")

@export var platform_width: float = 1280.0
@export var left_bound: float = 64.0
@export var right_bound: float = 1344.0

@onready var platform_body: StaticBody2D = $Platform
@onready var left_wall: StaticBody2D = $LeftWall
@onready var right_wall: StaticBody2D = $RightWall

var registered_fighters: Array[Node2D] = []

func _ready() -> void:
	_setup_background()
	_setup_audio()
	_find_fighters_in_tree()

func _setup_audio() -> void:
	var audio_mgr := get_node_or_null("AudioManager")
	if audio_mgr and audio_mgr.has_method("play_bgm"):
		audio_mgr.play_bgm(&"arena")

func _setup_background() -> void:
	var bg = get_node_or_null("Background")
	if bg and not bg.has_node("HighwayBackgroundLayer"):
		var layer = CyberHighwayBackgroundScript.new()
		layer.name = "HighwayBackgroundLayer"
		bg.add_child(layer)

func register_fighter(fighter: Node2D) -> void:
	if fighter and fighter not in registered_fighters:
		registered_fighters.append(fighter)

func unregister_fighter(fighter: Node2D) -> void:
	registered_fighters.erase(fighter)

func _find_fighters_in_tree() -> void:
	var parent_node := get_parent()
	if parent_node:
		var fighters_container := parent_node.get_node_or_null("Fighters")
		if fighters_container:
			for child in fighters_container.get_children():
				if child is CharacterBody2D:
					register_fighter(child)
	for child in get_children():
		if child is CharacterBody2D and child.has_method("take_hit"):
			register_fighter(child)

func is_within_platform(x_pos: float) -> bool:
	return x_pos >= left_bound and x_pos <= right_bound

func get_platform_top_y() -> float:
	if platform_body:
		return platform_body.global_position.y - 12.0
	return 280.0
