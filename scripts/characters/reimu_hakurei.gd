class_name ReimuHakurei
extends BaseMecha

## Petarung Roster: Reimu Hakurei
## Class: Shrine Maiden
## Kecepatan Jalan: 320 px/s, Dash: 760 px/s
## Total HP: 950 (Spatial Control / Divine Talismans)

var barrier_active_frames: int = 0

func _init() -> void:
	max_hp = 950
	current_hp = max_hp
	walk_speed = 320.0

func _ready() -> void:
	max_hp = 950
	current_hp = max_hp
	walk_speed = 320.0

	attack_resources = {
		&"5L": preload("res://resources/attacks/kage_slash.tres"),
		&"5L1": preload("res://resources/attacks/kage_slash.tres"),
		&"5L2": preload("res://resources/attacks/kage_kunai.tres"),
		&"5H": preload("res://resources/attacks/kage_cleave.tres"),
		&"Skill1": preload("res://resources/attacks/kage_kunai_flurry.tres"),
		&"HomingAmulet": preload("res://resources/attacks/kage_kunai_flurry.tres"),
		&"Skill2": preload("res://resources/attacks/kage_stance_shift.tres"),
		&"DimensionalRift": preload("res://resources/attacks/kage_stance_shift.tres"),
		&"Ultimate": preload("res://resources/attacks/kage_shadow_blossom.tres"),
		&"FantasySeal": preload("res://resources/attacks/kage_shadow_blossom.tres")
	}

	vfx_profile = preload("res://resources/vfx_profiles/reimu.tres")

	super._ready()

func get_dash_speed() -> float:
	return 760.0

func get_dash_duration() -> int:
	return 13

func execute_skill_1() -> void:
	# Skill 1: Homing Amulet (Tracking Ofuda Charm Barrage)
	request_attack_by_name(&"HomingAmulet")
	var bus = get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("skill_cast"):
		bus.skill_cast.emit(self, &"HomingAmulet", global_position, facing_direction)

func execute_skill_2() -> void:
	# Skill 2: Dimensional Rift (Spatial Evasion Blink)
	global_position.x += 280.0 * float(facing_direction)
	barrier_active_frames = 25
	request_attack_by_name(&"DimensionalRift")

func execute_ultimate() -> void:
	# Ultimate: Fantasy Seal (Yin-Yang Orb Cataclysm)
	if current_ultimate < CombatConstants.MAX_ULTIMATE:
		return
	drain_ultimate(CombatConstants.MAX_ULTIMATE)
	request_attack_by_name(&"FantasySeal")
	var bus = get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("skill_cast"):
		bus.skill_cast.emit(self, &"FantasySeal", global_position, facing_direction)

func _physics_process(delta: float) -> void:
	if barrier_active_frames > 0:
		barrier_active_frames -= 1
	super._physics_process(delta)

func get_archetype() -> StringName:
	return &"reimu"
