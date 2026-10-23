class_name DashTrailComponent
extends Node

## Komponen Pengelola Afterimage Trail saat Dash (Story 7.2)
## Memantau status StateMachine mecha dan memancarkan VFXGhostTrail di world space.

const GhostTrailScript = preload("res://scripts/visual/vfx_ghost_trail.gd")

@export var spawn_interval_frames: int = 3

var mecha: CharacterBody2D = null
var dash_timer: int = 0
var is_dashing: bool = false

func _ready() -> void:
	if get_parent() is CharacterBody2D:
		bind_mecha(get_parent() as CharacterBody2D)

func bind_mecha(target_mecha: CharacterBody2D) -> void:
	mecha = target_mecha

func _physics_process(_delta: float) -> void:
	if not mecha or not is_instance_valid(mecha):
		return

	var sm = mecha.get_node_or_null("StateMachine")
	if not sm or not sm.get("current_state"):
		return

	var state_name: StringName = StringName(sm.current_state.name)
	var now_dashing: bool = (state_name == &"Dash" or state_name == &"AirDash")

	if now_dashing:
		if not is_dashing:
			is_dashing = true
			dash_timer = 0
			_spawn_ghost()

		dash_timer += 1
		if dash_timer >= spawn_interval_frames:
			dash_timer = 0
			_spawn_ghost()
	else:
		is_dashing = false
		dash_timer = 0

func _spawn_ghost() -> void:
	if not mecha or not is_inside_tree():
		return

	var ghost := GhostTrailScript.new()
	var arch: StringName = &"viper"
	if mecha.has_method("get_archetype"):
		arch = mecha.get_archetype()
	elif "Bulwark" in mecha.name or "Titan" in mecha.name:
		arch = &"bulwark"

	var facing: int = mecha.facing_direction if "facing_direction" in mecha else 1
	ghost.setup(mecha.global_position, facing, arch)

	# Tambahkan ghost ke arena atau parent scene terluar agar tertinggal di koordinat world
	var spawn_parent: Node = mecha.get_parent()
	if not spawn_parent:
		spawn_parent = get_tree().current_scene if get_tree() else null
	if spawn_parent:
		spawn_parent.add_child(ghost)
