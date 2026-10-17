class_name StatesGround
extends RefCounted

## Script referensi untuk status darat (Ground States)
## Menghubungkan IdleState dan WalkState

const IDLE = preload("res://scripts/combat/fsm/idle_state.gd")
const WALK = preload("res://scripts/combat/fsm/walk_state.gd")
