class_name SasukeUchiha
extends BaseMecha

## Petarung Roster: Sasuke Uchiha
## Class: Ninja
## Kecepatan Jalan: 340 px/s, Dash: 810 px/s
## Total HP: 940 (Kenjutsu / Chidori Piercer / Susanoo)

func _init() -> void:
	max_hp = 940
	current_hp = max_hp
	walk_speed = 340.0

func _ready() -> void:
	max_hp = 940
	current_hp = max_hp
	walk_speed = 340.0

	attack_resources = {
		&"5L": preload("res://resources/attacks/kage_slash.tres"),
		&"5L1": preload("res://resources/attacks/kage_slash.tres"),
		&"5L2": preload("res://resources/attacks/kage_cleave.tres"),
		&"5H": preload("res://resources/attacks/kage_iaido_strike.tres"),
		&"Skill1": preload("res://resources/attacks/viper_blink_slash.tres"),
		&"ChidoriCurrent": preload("res://resources/attacks/viper_blink_slash.tres"),
		&"Skill2": preload("res://resources/attacks/kage_shuriken_storm.tres"),
		&"FireballJutsu": preload("res://resources/attacks/kage_shuriken_storm.tres"),
		&"Ultimate": preload("res://resources/attacks/kage_shadow_blossom.tres"),
		&"KirinDragon": preload("res://resources/attacks/kage_shadow_blossom.tres")
	}

	super._ready()

func get_dash_speed() -> float:
	return 810.0

func get_dash_duration() -> int:
	return 12

func execute_skill_1() -> void:
	# Skill 1: Chidori Current (Lightning Piercing Thrust)
	var thrust_dist = 360.0 * float(facing_direction)
	global_position.x += thrust_dist
	request_attack_by_name(&"ChidoriCurrent")
	var bus = get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("skill_cast"):
		bus.skill_cast.emit(self, &"ChidoriCurrent", global_position, facing_direction)

func execute_skill_2() -> void:
	# Skill 2: Fire Style: Fireball Jutsu (Inferno Burst)
	request_attack_by_name(&"FireballJutsu")
	var bus = get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("skill_cast"):
		bus.skill_cast.emit(self, &"FireballJutsu", global_position, facing_direction)

func execute_ultimate() -> void:
	# Ultimate: Kirin / Susanoo Arrow (Lightning Dragon)
	if current_ultimate < CombatConstants.MAX_ULTIMATE:
		return
	drain_ultimate(CombatConstants.MAX_ULTIMATE)
	request_attack_by_name(&"KirinDragon")
	var bus = get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("skill_cast"):
		bus.skill_cast.emit(self, &"KirinDragon", global_position, facing_direction)

func get_archetype() -> StringName:
	return &"sasuke"
