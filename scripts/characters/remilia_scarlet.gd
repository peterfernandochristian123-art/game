class_name RemiliaScarlet
extends BaseMecha

## Petarung Roster: Remilia Scarlet
## Class: Vampire
## Kecepatan Jalan: 340 px/s, Dash: 800 px/s
## Total HP: 1050 (Vampire Claws / Gungnir Piercer / High Aggro)

func _init() -> void:
	max_hp = 1050
	current_hp = max_hp
	walk_speed = 340.0
	passive_damage_reduction = 0.05

func _ready() -> void:
	max_hp = 1050
	current_hp = max_hp
	walk_speed = 340.0
	passive_damage_reduction = 0.05

	attack_resources = {
		&"5L": preload("res://resources/attacks/bulwark_punch.tres"),
		&"5L1": preload("res://resources/attacks/bulwark_punch.tres"),
		&"5L2": preload("res://resources/attacks/bulwark_slam.tres"),
		&"5H": preload("res://resources/attacks/bulwark_slam.tres"),
		&"Skill1": preload("res://resources/attacks/bulwark_piledriver.tres"),
		&"DemonKingCradle": preload("res://resources/attacks/bulwark_piledriver.tres"),
		&"Skill2": preload("res://resources/attacks/bulwark_riot_shield.tres"),
		&"ScarletNetherMist": preload("res://resources/attacks/bulwark_riot_shield.tres"),
		&"Ultimate": preload("res://resources/attacks/bulwark_orbital_cannon.tres"),
		&"SpearTheGungnir": preload("res://resources/attacks/bulwark_orbital_cannon.tres")
	}

	super._ready()

func get_dash_speed() -> float:
	return 800.0

func get_dash_duration() -> int:
	return 13

func execute_skill_1() -> void:
	# Skill 1: Demon King Cradle (Aerial Bat Dive Grab)
	super_armor_frames = 15
	request_attack_by_name(&"DemonKingCradle")

func execute_skill_2() -> void:
	# Skill 2: Scarlet Nether Mist (Blood Shield & Counter)
	super_armor_frames = 30
	invulnerability_frames = 10
	request_attack_by_name(&"ScarletNetherMist")

func execute_ultimate() -> void:
	# Ultimate: Spear the Gungnir (Cosmic Red Piercing Spear)
	if current_ultimate < CombatConstants.MAX_ULTIMATE:
		return
	drain_ultimate(CombatConstants.MAX_ULTIMATE)
	request_attack_by_name(&"SpearTheGungnir")
	var bus = get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("skill_cast"):
		bus.skill_cast.emit(self, &"SpearTheGungnir", global_position, facing_direction)

func get_archetype() -> StringName:
	return &"remilia"
