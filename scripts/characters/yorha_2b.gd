class_name Yorha2B
extends BaseMecha

## Petarung Roster: 2B
## Class: YoRHa (Android)
## Kecepatan Jalan: 330 px/s, Dash: 790 px/s
## Total HP: 1000 (Virtuous Contract / Pod 042 Support / Counter Evade)

func _init() -> void:
	max_hp = 1000
	current_hp = max_hp
	walk_speed = 330.0

func _ready() -> void:
	max_hp = 1000
	current_hp = max_hp
	walk_speed = 330.0

	attack_resources = {
		&"5L": preload("res://resources/attacks/viper_jab.tres"),
		&"5L1": preload("res://resources/attacks/viper_jab.tres"),
		&"5L2": preload("res://resources/attacks/viper_cleave.tres"),
		&"5H": preload("res://resources/attacks/kage_cleave.tres"),
		&"Skill1": preload("res://resources/attacks/trigger_magnum.tres"),
		&"PodLaser": preload("res://resources/attacks/trigger_magnum.tres"),
		&"Skill2": preload("res://resources/attacks/trigger_roll.tres"),
		&"PerfectEvade": preload("res://resources/attacks/trigger_roll.tres"),
		&"Ultimate": preload("res://resources/attacks/trigger_bullet_hell.tres"),
		&"PodGravityHammer": preload("res://resources/attacks/trigger_bullet_hell.tres")
	}

	super._ready()

func get_dash_speed() -> float:
	return 790.0

func get_dash_duration() -> int:
	return 13

func execute_skill_1() -> void:
	# Skill 1: Pod 042 Laser Program
	request_attack_by_name(&"PodLaser")
	var bus = get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("skill_cast"):
		bus.skill_cast.emit(self, &"PodLaser", global_position, facing_direction)

func execute_skill_2() -> void:
	# Skill 2: Perfect Evade & Mirage Counter
	invulnerability_frames = 20
	request_attack_by_name(&"PerfectEvade")

func execute_ultimate() -> void:
	# Ultimate: Pod Program: Gravity Hammer & Self-Destruct Rupture
	if current_ultimate < CombatConstants.MAX_ULTIMATE:
		return
	drain_ultimate(CombatConstants.MAX_ULTIMATE)
	request_attack_by_name(&"PodGravityHammer")
	var bus = get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("skill_cast"):
		bus.skill_cast.emit(self, &"PodGravityHammer", global_position, facing_direction)

func get_archetype() -> StringName:
	return &"2b"
