class_name ArenaUndergroundReactor
extends Node2D

## Arena Reaktor Bawah Tanah: Underground Reactor / Magma Forge (Story 12.1)
## Panggung tertutup bertebing baja kokoh di sisi kiri (X=64) dan kanan (X=1344)
## Dilengkapi dua ventilasi semburan uap termal aktif (SteamVentHazard)
## Menghilangkan mekanik Cliffhanger dan memfokuskan duel pada Wall-Bounce corner pressure.

signal hazard_triggered(hazard_name: StringName, fighter: Node2D)

const CombatConstants = preload("res://scripts/combat/combat_constants.gd")
const SteamVentHazardScript = preload("res://scripts/hazards/steam_vent_hazard.gd")

@export var platform_width: float = 1280.0
@export var left_bound: float = 64.0
@export var right_bound: float = 1344.0

@onready var platform_body: StaticBody2D = $Platform
@onready var left_wall: StaticBody2D = $LeftWall
@onready var right_wall: StaticBody2D = $RightWall
@onready var vent_left: Area2D = $VentLeft
@onready var vent_right: Area2D = $VentRight

var registered_fighters: Array[Node2D] = []

func _ready() -> void:
	_setup_audio()
	_setup_hazard_listeners()
	_find_fighters_in_tree()

func _setup_audio() -> void:
	var audio_mgr := get_node_or_null("AudioManager")
	if audio_mgr and audio_mgr.has_method("play_bgm"):
		audio_mgr.play_bgm(&"arena")

func _setup_hazard_listeners() -> void:
	if vent_left:
		vent_left.fighter_scorched.connect(func(f): _on_vent_scorched(&"VentLeft", f))
	if vent_right:
		vent_right.fighter_scorched.connect(func(f): _on_vent_scorched(&"VentRight", f))

func _on_vent_scorched(vent_id: StringName, fighter: Node2D) -> void:
	hazard_triggered.emit(vent_id, fighter)

func register_fighter(fighter: Node2D) -> void:
	if fighter and fighter not in registered_fighters:
		registered_fighters.append(fighter)

func unregister_fighter(fighter: Node2D) -> void:
	registered_fighters.erase(fighter)

func _find_fighters_in_tree() -> void:
	var parent_node := get_parent()
	if not parent_node:
		return
	var fighters_container := parent_node.get_node_or_null("Fighters")
	if fighters_container:
		for child in fighters_container.get_children():
			if child is CharacterBody2D:
				register_fighter(child)
